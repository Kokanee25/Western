#!/usr/bin/env python3
"""Combine tools/paint_bake.gd's raw projections into his painted textures, in squares.

    python3 tools/paint/finish.py [assets/people/paint]

For every shape of him (skin, head, coat, hat...): each painted view's projection, weighted by how
squarely that view saw each texel and by VIEW_WEIGHT (the painting's own view is the master; the
others fill what it can't see), sharpened so the best view wins, averaged; texels no view saw take
the colour of those next to them. Then the squares, the same rule for every man: each shape cut
into squares of a set size on him (SQUARES_PER_M, measured on the painting: ~80 a metre on cloth,
~190 on the face, ~150 on the hands), the fine detail under them smoothed away first (SMOOTH),
each square the dominant colour of what's under it (two colours found in the square, the commoner
kept: crisp edges, not the blur of an average), and each shape cut to a few colours of its own
(SHAPE_COLOURS: a coat of twelve browns), so the squares form clean ramps, not noise. Writes
assets/people/<id>_paint_<shape>.png (one texel per square: the game draws them nearest, and
body_skin lights each square as one) and assets/people/<id>_paint.json ({shape: {uv_rect, size}}),
which PeopleBodies loads.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "blender"))
import faces  # noqa: E402  (its _despeckle; faces imports bpy only if it's there)

VIEW_WEIGHT = {"shot": 0.5, "shot_model": 6.0, "front": 1.0, "three_quarter": 1.0, "side": 0.8, "side_left": 0.8, "back": 1.0}
# The close head views (paint_views.py --head-sheet) see his head at ~3x the detail: on the shapes of
# his head they outweigh everything; elsewhere (the collar and coat they catch) they barely count.
HEAD_VIEW_WEIGHT = 10.0
# The view from your seat is the one that matters most: on his face it outweighs the other close views.
HEAD_VIEW_BOOST = {"head_shot": 1.6}
# A painting that didn't follow our model (its outline overlaps the guide's less than this after
# fitting, tools/paint/align.py's <id>_aligned.json) is left out: an image model sometimes paints a
# view from the wrong side (a front face where his profile should be), which would put the wrong
# face on him.
MIN_OVERLAP = 0.8
# The close head views fill their frame, so a wrong one still overlaps well: they must fit closer.
MIN_OVERLAP_HEAD = 0.88
HEAD_VIEW_ELSEWHERE = 0.2
HEAD_SHAPES = {"head", "hair", "hat", "hat_band", "hat_brim", "cravat"}
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
# Clean squares: first the fine detail under them is smoothed away (a median over this many raw
# texels, ~2 cm; less on the face, whose eyes and moustache are small), then each shape gets a
# palette of its own: enough shades for the light to step across it (the painting's face runs
# through ~20), few enough that neighbouring squares share them.
SMOOTH = {"head": 3}
SMOOTH_DEFAULT = 5
SHAPE_COLOURS = {"head": 24, "coat": 12, "vest": 10, "shirt": 6, "trousers": 8, "hat": 8, "hat_band": 8,
        "hat_brim": 8, "cravat": 5, "skin": 10, "boots": 6, "belt": 5, "gun_belt": 6, "holster": 5}
SHAPE_COLOURS_DEFAULT = 6
# Garments drawn in their own colour, as the painting draws them (a clean white shirt, a black tie):
# the painted light and shade are kept, the colour is set, so the collar and tie read at a glance
# instead of taking the muddy browns round them. Colours as the painting shows them in lamplight.
SHAPE_TONE = {"shirt": (0.95, 0.8, 0.52), "cravat": (0.07, 0.05, 0.04)}
# The face's features bolder (unsharp mask: radius in raw texels, strength in %), like the
# painting's dark eyes, brows and moustache.
FACE_SHARPEN = (2, 90)
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


def palette(q, n):
    """The n colours that best cover q (h, w, 3; median cut, then k-means), and each square's."""
    px = q.reshape(-1, 3)
    im = Image.fromarray((np.clip(q, 0, 1) * 255).astype(np.uint8)).quantize(colors=n, method=Image.Quantize.MEDIANCUT)
    pal = np.array(im.getpalette()[:n * 3], dtype=float).reshape(-1, 3)[:len(set(np.asarray(im).ravel()))] / 255.0
    for _ in range(10):
        near = ((px[:, None, :] - pal[None]) ** 2).sum(-1).argmin(1)
        for c in range(len(pal)):
            if (near == c).any():
                pal[c] = px[near == c].mean(0)
    near = ((px[:, None, :] - pal[None]) ** 2).sum(-1).argmin(1)
    return near.reshape(q.shape[:2]), (np.clip(pal, 0, 1) * 255).astype(np.uint8)


def finish(src):
    raw = os.path.join(src, "raw")
    with open(os.path.join(raw, "shapes.json")) as f:
        info = json.load(f)
    person = info["person"]
    out_dir = os.path.dirname(os.path.normpath(src))
    report = {}
    squares = {}
    dropped = set()
    fits = os.path.join(src, "%s_aligned.json" % person)
    if os.path.exists(fits):
        with open(fits) as f:
            for view, r in json.load(f).items():
                need = MIN_OVERLAP_HEAD if view.startswith("head_") else MIN_OVERLAP
                if isinstance(r, dict) and r.get("overlap", 1.0) < need:
                    # align.py names the model's painting of your seat's view "shot"; in the bake
                    # it's "shot_model" ("shot" there is the painting's own pixels, never left out).
                    dropped.add("shot_model" if view == "shot" else view)
    if dropped:
        print("left out (didn't follow his outline):", ", ".join(sorted(dropped)))
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
            if view in dropped:
                continue
            vw = VIEW_WEIGHT.get(view, 1.0)
            if view.startswith("head_"):
                vw = HEAD_VIEW_WEIGHT * HEAD_VIEW_BOOST.get(view, 1.0) if shape in HEAD_SHAPES else HEAD_VIEW_ELSEWHERE
            elif shape == "hair":
                vw *= 0.1  # the body views were painted before he had hair
            k = ((wt[..., 0] * vw) ** SHARPEN) * (col[..., 3] > 0.5)
            acc += col[..., :3] * k[..., None]
            wsum += k
        known = wsum > 1e-4
        if not known.any():
            continue
        rgb = np.where(known[..., None], acc / np.maximum(wsum, 1e-9)[..., None], 0.0)
        rgb = _fill(rgb, known)
        if shape in SHAPE_TONE:
            lum = rgb @ np.array([0.2126, 0.7152, 0.0722])
            lo, hi = np.percentile(lum[known], [5, 95]) if known.any() else (0.0, 1.0)
            t = np.clip((lum - lo) / max(hi - lo, 1e-3), 0, 1)[..., None]
            rgb = np.array(SHAPE_TONE[shape]) * (0.55 + 0.45 * t)
        if shape == "head":
            img = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8))
            img = img.filter(ImageFilter.UnsharpMask(radius=FACE_SHARPEN[0], percent=FACE_SHARPEN[1], threshold=2))
            rgb = np.asarray(img, dtype=float) / 255.0
        k = SMOOTH.get(shape, SMOOTH_DEFAULT)
        if k > 1:
            img = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(k))
            rgb = np.asarray(img, dtype=float) / 255.0
        per_m = SQUARES_PER_M.get(shape, SQUARES_PER_M_CLOTH)
        raw_x, raw_y = RAW_PER_M.get(shape, RAW_PER_M_DEFAULT)
        size = (max(2, round(w * per_m / raw_x)), max(2, round(h * per_m / raw_y)))
        squares[shape] = dominant(rgb, size)
        report[shape] = {"uv_rect": s["uv_rect"], "size": list(size), "squares_per_m": per_m,
                "seen": round(float(known.mean()), 3)}
    for shape, q in squares.items():
        idx, pal = palette(q, SHAPE_COLOURS.get(shape, SHAPE_COLOURS_DEFAULT))
        # Lone stray squares tidied (not on the face: an eye is one square).
        if shape != "head":
            idx = faces._despeckle(idx, np.ones(idx.shape, dtype=bool), passes=2)
        name = "%s_paint_%s.png" % (person, shape)
        Image.fromarray(pal[idx], "RGB").save(os.path.join(out_dir, name))
        report[shape]["colours"] = int(len(pal))
        print(name, idx.shape[1], idx.shape[0], "(%d a metre, %d colours)" % (report[shape]["squares_per_m"], len(pal)),
                "seen %.0f%%" % (100 * report[shape]["seen"]))
    with open(os.path.join(out_dir, "%s_paint.json" % person), "w") as f:
        json.dump({"views": [v for v in info["views"] if v not in dropped], "left_out": sorted(dropped),
                "shapes": report}, f, indent=1)


if __name__ == "__main__":
    finish(sys.argv[1] if len(sys.argv) > 1 else "assets/people/paint")
