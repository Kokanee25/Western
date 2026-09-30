#!/usr/bin/env python3
"""Combine tools/paint_bake.gd's raw projections into his painted textures.

    python3 tools/paint/finish.py [assets/people/paint]

For every shape of him (skin, head, coat, hat...): each painted view's projection, weighted by how
squarely that view saw each texel and by VIEW_WEIGHT (the painting's own view is the master; the
others fill what it can't see), sharpened so the best view wins, averaged; texels no view saw take the colour of those next to them;
then averaged down DOWN x DOWN into the finished blocks, cut to a small palette of the painting's
own colours, and cleared of lone stray texels. Writes assets/people/<id>_paint_<shape>.png and
assets/people/<id>_paint.json ({shape: {uv_rect, size}}), which PeopleBodies loads.
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
# Raw texels per finished texel (paint_bake.gd bakes at 256/m: finished blocks at 128/m, ~2-3
# screen pixels at the painting's distance).
DOWN = 1
COLOURS = 24
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


def finish(src):
    raw = os.path.join(src, "raw")
    with open(os.path.join(raw, "shapes.json")) as f:
        info = json.load(f)
    person = info["person"]
    out_dir = os.path.dirname(os.path.normpath(src))
    report = {}
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
        fh, fw = h // DOWN, w // DOWN
        rgb = rgb[:fh * DOWN, :fw * DOWN].reshape(fh, DOWN, fw, DOWN, 3).mean(axis=(1, 3))
        pim = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8)).quantize(colors=COLOURS, method=Image.Quantize.MEDIANCUT)
        pal = np.array(pim.getpalette()[:COLOURS * 3], dtype=np.uint8).reshape(-1, 3)
        idx = faces._despeckle(np.asarray(pim), np.ones((fh, fw), dtype=bool))
        name = "%s_paint_%s.png" % (person, shape)
        Image.fromarray(pal[idx], "RGB").save(os.path.join(out_dir, name))
        report[shape] = {"uv_rect": s["uv_rect"], "size": [fw, fh], "seen": round(float(known.mean()), 3)}
        print(name, fw, fh, "seen %.0f%%" % (100 * known.mean()))
    with open(os.path.join(out_dir, "%s_paint.json" % person), "w") as f:
        json.dump({"views": info["views"], "shapes": report}, f, indent=1)


if __name__ == "__main__":
    finish(sys.argv[1] if len(sys.argv) > 1 else "assets/people/paint")
