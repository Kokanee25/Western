#!/usr/bin/env python3
"""Cut paint_blood.py's sheets (assets/textures/raw/blood/<sheet>.png, four marks on white in a two
by two grid) into the decal textures PixelArt.blood hands out: assets/textures/blood/<key>.png,
the white keyed out to transparency, each mark cropped, squared and sized. No calls; runs anywhere.

    python3 tools/textures/cut_blood.py [--sheet=docs/screenshots/textures/blood.png]

Which quadrant becomes which key is in blood_map.json beside this file (the model doesn't always
draw them in the order it was asked).
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
RAW = os.path.join(ROOT, "assets", "textures", "raw", "blood")
OUT = os.path.join(ROOT, "assets", "textures", "blood")
MAP = os.path.join(HERE, "blood_map.json")
# How far from white a pixel must be to be part of a mark (0..255, on its least-white channel):
# fully transparent below LO, fully opaque above HI.
LO, HI = 16.0, 56.0


def cut(sheet, quadrant):
    a = np.asarray(sheet.convert("RGB"), dtype=np.float32)
    h, w = a.shape[:2]
    qy, qx = divmod(quadrant, 2)
    q = a[qy * h // 2:(qy + 1) * h // 2, qx * w // 2:(qx + 1) * w // 2]
    away = (255.0 - q).max(axis=2)
    alpha = np.clip((away - LO) / (HI - LO), 0.0, 1.0)
    ys, xs = np.nonzero(alpha > 0.5)
    if len(ys) == 0:
        return None
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    pad = max(2, (max(y1 - y0, x1 - x0)) // 24)
    y0, x0 = max(y0 - pad, 0), max(x0 - pad, 0)
    y1, x1 = min(y1 + pad, q.shape[0]), min(x1 + pad, q.shape[1])
    rgb = q[y0:y1, x0:x1]
    al = alpha[y0:y1, x0:x1]
    # Un-mix the white the soft edge was painted against, so the rim isn't pale.
    safe = np.maximum(al, 0.05)[..., None]
    rgb = np.clip((rgb - 255.0 * (1.0 - safe)) / safe, 0, 255)
    side = max(rgb.shape[0], rgb.shape[1])
    square = np.zeros((side, side, 4), dtype=np.float32)
    oy, ox = (side - rgb.shape[0]) // 2, (side - rgb.shape[1]) // 2
    square[oy:oy + rgb.shape[0], ox:ox + rgb.shape[1], :3] = rgb
    square[oy:oy + rgb.shape[0], ox:ox + rgb.shape[1], 3] = al * 255.0
    return Image.fromarray(square.astype(np.uint8), "RGBA")


def main():
    plan = json.load(open(MAP))
    os.makedirs(OUT, exist_ok=True)
    made = []
    for sheet_name, spec in plan["sheets"].items():
        path = os.path.join(RAW, sheet_name + ".png")
        if not os.path.exists(path):
            print("not painted yet:", sheet_name)
            continue
        sheet = Image.open(path)
        for quadrant, key in enumerate(spec["keys"]):
            if not key:
                continue
            mark = cut(sheet, quadrant)
            if mark is None:
                print("nothing in %s quadrant %d" % (sheet_name, quadrant))
                continue
            size = int(spec.get("size", 64))
            mark = mark.resize((size, size), Image.LANCZOS)
            mark.save(os.path.join(OUT, key + ".png"))
            made.append((key, mark))
            print("cut:", key, "from", sheet_name, quadrant)
    for a in sys.argv[1:]:
        if a.startswith("--sheet=") and made:
            tile = 96
            out = Image.new("RGBA", (tile * min(len(made), 8), tile * ((len(made) + 7) // 8)), (210, 200, 185, 255))
            for i, (key, mark) in enumerate(made):
                m = mark.resize((tile, tile), Image.NEAREST)
                out.alpha_composite(m, ((i % 8) * tile, (i // 8) * tile))
            path = a.split("=", 1)[1]
            os.makedirs(os.path.dirname(path), exist_ok=True)
            out.convert("RGB").save(path)
            print("sheet:", path)


if __name__ == "__main__":
    main()
