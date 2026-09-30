#!/usr/bin/env python3
"""Combine tools/paint_bake.gd's raw projections into his painted textures, in squares.

    python3 tools/paint/finish.py [assets/people/paint]

For every shape of him (skin, head, coat, hat...): each painted view's projection, weighted by how
squarely that view saw each texel and by VIEW_WEIGHT (the painting's own view is the master; the
others fill what it can't see), sharpened so the best view wins, averaged; texels no view saw take
the colour of those next to them. Then the squares, the same rule for every man: each shape cut
into squares of a set size on him (SQUARES_PER_M, measured on the painting: ~80 a metre on cloth,
~190 on the face, ~150 on the hands), each square the dominant colour of what's under it (two
colours found in the square, the commoner kept: crisp edges, not the blur of an average), and all
of him cut to one small palette (COLOURS) so he reads as one painted man. Writes
assets/people/<id>_paint_<shape>.png (one texel per square: the game draws them nearest, and
body_skin lights each square as one) and assets/people/<id>_paint.json ({shape: {uv_rect, size}}),
which PeopleBodies loads.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "blender"))
import faces  # noqa: E402  (its _despeckle; faces imports bpy only if it's there)

VIEW_WEIGHT = {"shot": 6.0, "shot_model": 1.5, "front": 1.0, "three_quarter": 1.0, "side": 0.8, "side_left": 0.8, "back": 1.0}
# How hard the best view wins: each view's weight (VIEW_WEIGHT x how squarely it saw the texel) is
# raised to this power before averaging.
SHARPEN = 4.0
# Squares a metre on him, per shape (the rest: SQUARES_PER_M_CLOTH). Measured on the painting at
# its man's size: the coat's blocks ~12 px of 1672, the face ~27 blocks across, the hands finer.
SQUARES_PER_M = {"head": 190.0, "skin": 150.0, "cravat": 110.0, "hat_band": 110.0}
SQUARES_PER_M_CLOTH = 80.0
# The raw bakes' texels a metre: paint_bake.gd bakes at 256/m, except the head, whose face layout
# runs round the head (~0.57 m) in u and over BodyMesh's HEAD_BOTTOM..HEAD_TOP (0.25 m) in v.
RAW_PER_M = {"head": (256 / 0.57, 172 / 0.25)}
RAW_PER_M_DEFAULT = (256.0, 256.0)
# One palette for all of him.
COLOURS = 40
# Samples a square looks at (per side) to find its dominant colour.
SAMPLES = 4
# Texels no view saw take their neighbours' colour, spreading this many texels; past that, the
# shape's average.
FILL_STEPS = 64


def _load(path):
    return np.asarray(Image.open(path).convert("RGBA"), dtype=float) / 255.0


def _fill(rgb, known, steps=FILL_STEPS):
    rgb, known = rgb.copy(), known.copy()
    for _ in range(steps):
        todo = ~known
        if not todo.any():
            break
        acc = np.zeros_like(rgb)
        n = np.zeros(known.shape)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            k = np.roll(known, (dy, dx), axis=(0, 1))
            acc += np.roll(rgb, (dy, dx), axis=(0, 1)) * k[:, :, None]
            n += k
        grow = todo & (n > 0)
        rgb[grow] = acc[grow] / n[grow][:, None]
        known = known | grow
    if (~known).any() and known.any():
        rgb[~known] = rgb[known].mean(axis=0)
    return rgb


def dominant(rgb, size):
    """Shrink rgb (h, w, 3) to size (w, h): each output square the commoner of the two colours
    found among SAMPLES x SAMPLES points under it (2-means, from its darkest and lightest)."""
    w, h = size
    n = SAMPLES
    img = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8))
    pts = np.asarray(img.resize((w * n, h * n), Image.NEAREST), dtype=float) / 255.0
    pts = pts.reshape(h, n, w, n, 3).transpose(0, 2, 1, 3, 4).reshape(h, w, n * n, 3)
    lum = pts @ np.array([0.2126, 0.7152, 0.0722])
    rows = np.arange(h)[:, None]
    cols = np.arange(w)[None, :]
    c1 = pts[rows, cols, lum.argmin(-1)]
    c2 = pts[rows, cols, lum.argmax(-1)]
    for _ in range(6):
        near1 = ((pts - c1[:, :, None]) ** 2).sum(-1) <= ((pts - c2[:, :, None]) ** 2).sum(-1)
        n1 = near1.sum(-1)
        n2 = n * n - n1
        m1 = (pts * near1[..., None]).sum(2) / np.maximum(n1, 1)[..., None]
        m2 = (pts * ~near1[..., None]).sum(2) / np.maximum(n2, 1)[..., None]
        c1 = np.where((n1 > 0)[..., None], m1, c1)
        c2 = np.where((n2 > 0)[..., None], m2, c2)
    return np.where((n1 >= n2)[..., None], c1, c2)


def finish(src):
    raw = os.path.join(src, "raw")
    with open(os.path.join(raw, "shapes.json")) as f:
        info = json.load(f)
    person = info["person"]
    out_dir = os.path.dirname(os.path.normpath(src))
    report = {}
    squares = {}
    for shape, s in info["shapes"].items():
        w, h = s["size"]
        acc = np.zeros((h, w, 3))
        wsum = np.zeros((h, w))
        for view in info["views"]:
            cp = os.path.join(raw, "%s_%s_col.png" % (shape, view))
            wp = os.path.join(raw, "%s_%s_w.png" % (shape, view))
            if not (os.path.exists(cp) and os.path.exists(wp)):
                continue
            col, wt = _load(cp), _load(wp)
            # Sharpened, so where a view sees a texel far better than the others (the painting
            # itself, from your seat) it wins outright rather than being averaged with guesses.
            k = ((wt[..., 0] * VIEW_WEIGHT.get(view, 1.0)) ** SHARPEN) * (col[..., 3] > 0.5)
            acc += col[..., :3] * k[..., None]
            wsum += k
        known = wsum > 1e-4
        if not known.any():
            continue
        rgb = np.where(known[..., None], acc / np.maximum(wsum, 1e-9)[..., None], 0.0)
        rgb = _fill(rgb, known)
        per_m = SQUARES_PER_M.get(shape, SQUARES_PER_M_CLOTH)
        raw_x, raw_y = RAW_PER_M.get(shape, RAW_PER_M_DEFAULT)
        size = (max(2, round(w * per_m / raw_x)), max(2, round(h * per_m / raw_y)))
        squares[shape] = dominant(rgb, size)
        report[shape] = {"uv_rect": s["uv_rect"], "size": list(size), "squares_per_m": per_m,
                "seen": round(float(known.mean()), 3)}
    # One palette for all of him, every shape counted about equally (the coat would drown the face).
    most = max(q.shape[0] * q.shape[1] for q in squares.values())
    sample = np.concatenate([np.tile(q.reshape(-1, 3), (max(1, most // (4 * q.shape[0] * q.shape[1])), 1))
            for q in squares.values()])
    side = int(np.ceil(np.sqrt(len(sample))))
    sample = np.concatenate([sample, np.repeat(sample[:1], side * side - len(sample), 0)])
    pal_img = Image.fromarray((np.clip(sample.reshape(side, side, 3), 0, 1) * 255).astype(np.uint8)).quantize(
            colors=COLOURS, method=Image.Quantize.MEDIANCUT)
    pal = np.array(pal_img.getpalette()[:COLOURS * 3], dtype=np.uint8).reshape(-1, 3)
    for shape, q in squares.items():
        im = Image.fromarray((np.clip(q, 0, 1) * 255).astype(np.uint8)).quantize(palette=pal_img, dither=Image.Dither.NONE)
        idx = np.asarray(im)
        # Lone stray squares tidied on cloth only (a face's eye is one square).
        if shape != "head":
            idx = faces._despeckle(idx, np.ones(idx.shape, dtype=bool), passes=1)
        name = "%s_paint_%s.png" % (person, shape)
        Image.fromarray(pal[idx], "RGB").save(os.path.join(out_dir, name))
        print(name, idx.shape[1], idx.shape[0], "(%d a metre)" % report[shape]["squares_per_m"],
                "seen %.0f%%" % (100 * report[shape]["seen"]))
    with open(os.path.join(out_dir, "%s_paint.json" % person), "w") as f:
        json.dump({"views": info["views"], "colours": COLOURS, "shapes": report}, f, indent=1)


if __name__ == "__main__":
    finish(sys.argv[1] if len(sys.argv) > 1 else "assets/people/paint")
