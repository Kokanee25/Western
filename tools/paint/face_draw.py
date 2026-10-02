#!/usr/bin/env python3
"""The face drawn, as a pixel artist would over the painted squares: the painting's man has open
eyes (a white either side of a dark iris, a glint, a heavy upper lid), heavy dark brows, a thick
walrus moustache and a mouth shut hard under it, all bold enough to read at a glance; the paint bake gives us his face softer, eyes
half shut and features muddy. This draws them in, on the finished head texture.

    python3 tools/paint/face_draw.py [--id=outlaw] [--show=out.png]

Reads assets/people/<id>_paint_head.png and where his eyes are (assets/people/<id>_paint.json,
shapes.head.eyes: 0..1 of the texture, written by paint_bake.gd through finish.py), and writes the
texture back. The head is drawn DETAIL (3) texels a square, finer round the eyes (finish.py), so
the eyes are drawn texel by texel and everything else in whole squares. finish.py runs this last.
By hand, run it only on a texture finish.py wrote before it drew (git checkout the PNG first): it
draws over whatever is there. Colours are taken from the face itself (its darkest for
lids, iris and brows; its own white), in the texture's dark painted values (body_skin brightens
them: paint_look).
"""
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PEOPLE = os.path.join(ROOT, "assets", "people")

# The eye, in texels (1 texel ~1.75 mm on the face): the opening's half-width and the rows of it
# from its centre line (upper lid, white, lower lid), and the iris's size.
EYE_HALF_W = 5
IRIS_W = 5
# The white, a warm off-white in painted values (the shader lifts it to the painting's cream).
WHITE = (92, 72, 54)
GLINT = (140, 124, 104)
# Brows: rows above the eye's centre, and how far past the eye they reach.
BROW_ROWS = (-9, -6)
BROW_REACH = 8
# The moustache: from this many texels under the eyes to this many, across this half-width from
# the middle between the eyes; it droops this far further at its ends.
MOUSTACHE_ROWS = (22, 38)
MOUSTACHE_HALF_W = 24
MOUSTACHE_DROOP = 5
# The mouth, shut and stern under the moustache (the bake gave him a bright band there between the
# moustache's dark ends: a grin): a straight dark line this many texels under the eyes, this
# half-width, its corners turned down a row; under it a muted lower lip and a calmer chin.
MOUTH_ROW = 37
MOUTH_HALF_W = 13
LIP_ROWS = 3
CHIN_ROWS = 6
# Local contrast over the face (round the mean): the painting's face is lit firmer than the bake.
CONTRAST = 1.2
# The whole head's colour pushed this much further from grey: the painting's skin is lamplit
# orange, the bake's a greyer brown.
SATURATION = 1.25


def draw(img, eyes):
    """img: HxWx3 uint8; eyes: [(x, y)] texel centres. Returns the drawn image."""
    a = img.astype(np.float64)
    grey = a.mean(2, keepdims=True)
    a = np.clip(grey + (a - grey) * SATURATION, 0, 255)
    h, w, _ = a.shape
    (lx, ly), (rx, ry) = sorted(eyes)
    mid_x = (lx + rx) * 0.5
    mid_y = (ly + ry) * 0.5
    span = rx - lx
    # The face's region: from above the brows to under the moustache, cheek to cheek.
    fx0, fx1 = int(lx - span * 0.75), int(rx + span * 0.75)
    fy0, fy1 = int(mid_y + BROW_ROWS[0] - 4), int(mid_y + MOUSTACHE_ROWS[1] + MOUSTACHE_DROOP + 2)
    fx0, fy0 = max(fx0, 0), max(fy0, 0)
    fx1, fy1 = min(fx1, w), min(fy1, h)
    face = a[fy0:fy1, fx0:fx1]
    lum = face.mean(2)
    dark = face.reshape(-1, 3)[lum.reshape(-1).argsort()[:max(4, lum.size // 50)]].mean(0)
    skin = np.median(face.reshape(-1, 3), 0)
    # Firmer light and shade across the face.
    mean = face.mean((0, 1))
    a[fy0:fy1, fx0:fx1] = np.clip(mean + (face - mean) * CONTRAST, 0, 255)

    def put(x, y, c, k=1.0):
        if 0 <= x < w and 0 <= y < h:
            a[y, x] = a[y, x] * (1.0 - k) + np.asarray(c, float) * k

    for (cx, cy) in [(int(round(lx)), int(round(ly))), (int(round(rx)), int(round(ry)))]:
        outer = -1 if cx < mid_x else 1
        # Brows: thick, dark, the outer end a row lower.
        for x in range(cx - BROW_REACH, cx + BROW_REACH + 1):
            drop = 1 if (x - cx) * outer > BROW_REACH * 0.4 else 0
            for y in range(cy + BROW_ROWS[0] + drop, cy + BROW_ROWS[1] + drop + 1):
                put(x, y, dark, 0.85)
        # The opening: upper lid (two rows, arched), the white, the iris looking at you with a
        # glint, a lower lid a shade darker than the skin.
        for x in range(cx - EYE_HALF_W, cx + EYE_HALF_W):
            end = abs(x - cx + 0.5) > EYE_HALF_W - 1.5
            for y in (cy - 2, cy - 3):
                put(x, y + (1 if end else 0), dark, 0.95)
            for y in (cy - 1, cy, cy + 1):
                if end and y == cy + 1:
                    continue
                put(x, y, WHITE, 1.0)
            put(x, cy + 2, skin * 0.62, 1.0)
        i0 = cx - IRIS_W // 2
        for x in range(i0, i0 + IRIS_W):
            for y in (cy - 2, cy - 1, cy, cy + 1):
                put(x, y, dark * 0.9 + np.array([10, 6, 3]), 1.0)
        put(i0 + IRIS_W - 2, cy - 1, GLINT, 1.0)
    # The moustache: a thick dark mass under the nose, its ends drooping past the mouth's corners.
    for x in range(int(mid_x - MOUSTACHE_HALF_W), int(mid_x + MOUSTACHE_HALF_W) + 1):
        edge = abs(x - mid_x) / MOUSTACHE_HALF_W
        top = int(mid_y + MOUSTACHE_ROWS[0] + edge * 3)
        bottom = int(mid_y + MOUSTACHE_ROWS[0] + (MOUSTACHE_ROWS[1] - MOUSTACHE_ROWS[0]) * (0.55 + 0.45 * edge)
                     + (MOUSTACHE_DROOP if edge > 0.75 else 0))
        for y in range(top, bottom + 1):
            if 0 <= x < w and 0 <= y < h:
                # Keep its own texture, made dark: lighter squares in it go dark brown, dark stay.
                put(x, y, dark * 0.8 + a[y, x] * 0.25, 0.8)
    # The mouth: the chin's light toned down to the skin's, a muted lip, then the line on top of
    # them, flat, its ends dropping (a frown's corners, not a smile's).
    my = int(round(mid_y + MOUTH_ROW))
    for x in range(int(mid_x - MOUTH_HALF_W - 2), int(mid_x + MOUTH_HALF_W + 3)):
        for y in range(my + 1 + LIP_ROWS, my + 1 + LIP_ROWS + CHIN_ROWS):
            if 0 <= x < w and 0 <= y < h:
                put(x, y, np.minimum(a[y, x], skin * 0.95), 0.6)
        for y in range(my + 1, my + 1 + LIP_ROWS):
            put(x, y, skin * 0.74, 0.85)
    for x in range(int(mid_x - MOUTH_HALF_W), int(mid_x + MOUTH_HALF_W) + 1):
        drop = 1 if abs(x - mid_x) > MOUTH_HALF_W * 0.7 else 0
        put(x, my + drop, dark * 0.85, 1.0)
        put(x, my + drop - 1, dark * 0.85 + skin * 0.1, 0.7)
    return np.clip(a, 0, 255).astype(np.uint8)


def main():
    pid = "outlaw"
    show = None
    for arg in sys.argv[1:]:
        if arg.startswith("--id="):
            pid = arg.split("=", 1)[1]
        if arg.startswith("--show="):
            show = arg.split("=", 1)[1]
    path = os.path.join(PEOPLE, pid + "_paint_head.png")
    info_path = os.path.join(PEOPLE, pid + "_paint.json")
    info = json.load(open(info_path))
    head = info["shapes"]["head"]
    img = np.asarray(Image.open(path).convert("RGB"))
    h, w, _ = img.shape
    eyes = [(u * w, v * h) for u, v in head["eyes"]]
    out = draw(img, eyes)
    Image.fromarray(out).save(path)
    print("drew the face:", path, "eyes at", [(round(x), round(y)) for x, y in eyes])
    if show:
        both = np.concatenate([img, out], 1)
        Image.fromarray(both).resize((both.shape[1] * 4, both.shape[0] * 4), Image.NEAREST).save(show)


if __name__ == "__main__":
    main()
