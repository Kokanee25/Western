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


def cut(sheet, quadrant, lo=LO, hi=HI, key="white", open_px=0, core=0.0):
    a = np.asarray(sheet.convert("RGB"), dtype=np.float32)
    h, w = a.shape[:2]
    qy, qx = divmod(quadrant, 2)
    q = a[qy * h // 2:(qy + 1) * h // 2, qx * w // 2:(qx + 1) * w // 2]
    if key == "red":
        # Only the crimson: red well over green (the cloth it was painted on, beige, brown or grey,
        # drops out). `lo`/`hi` are the red-to-green ratio where it starts to show / is solid.
        ratio = q[..., 0] / (q[..., 1] + 8.0)
        alpha = np.clip((ratio - lo) / (hi - lo), 0.0, 1.0)
    else:
        away = (255.0 - q).max(axis=2)
        alpha = np.clip((away - lo) / (hi - lo), 0.0, 1.0)
    if open_px:
        # Thin lines drop out (an outline the model drew a gap outside a pool reads as a pale ring
        # in the game); the mark and its drops stay: the mask eroded then dilated by `open_px`.
        from PIL import ImageFilter
        m = Image.fromarray((alpha * 255.0).astype(np.uint8), "L")
        m = m.filter(ImageFilter.MinFilter(open_px)).filter(ImageFilter.MaxFilter(open_px))
        alpha = np.minimum(alpha, np.asarray(m, dtype=np.float32) / 255.0)
    ys, xs = np.nonzero(alpha > 0.5)
    if len(ys) == 0:
        return None
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    if core:
        # Cropped to where most of the mark is, not its furthest wisp (a stain's stray threads ran
        # to the corners and left the patch a twentieth of its decal): `core` of the mass is let
        # go off each side.
        def span(mass):
            c = np.cumsum(mass) / max(mass.sum(), 1e-6)
            return int(np.searchsorted(c, core)), int(np.searchsorted(c, 1.0 - core)) + 1
        y0, y1 = span(alpha.sum(axis=1))
        x0, x1 = span(alpha.sum(axis=0))
    pad = max(2, (max(y1 - y0, x1 - x0)) // 24)
    y0, x0 = max(y0 - pad, 0), max(x0 - pad, 0)
    y1, x1 = min(y1 + pad, q.shape[0]), min(x1 + pad, q.shape[1])
    rgb = q[y0:y1, x0:x1]
    al = alpha[y0:y1, x0:x1]
    if key == "white":
        # Un-mix the white the soft edge was painted against, so the rim isn't pale.
        safe = np.maximum(al, 0.05)[..., None]
        rgb = np.clip((rgb - 255.0 * (1.0 - safe)) / safe, 0, 255)
    side = max(rgb.shape[0], rgb.shape[1])
    square = np.zeros((side, side, 4), dtype=np.float32)
    oy, ox = (side - rgb.shape[0]) // 2, (side - rgb.shape[1]) // 2
    square[oy:oy + rgb.shape[0], ox:ox + rgb.shape[1], :3] = rgb
    square[oy:oy + rgb.shape[0], ox:ox + rgb.shape[1], 3] = al * 255.0
    return Image.fromarray(square.astype(np.uint8), "RGBA")


def soak(mark, colour):
    """Under a painted stain's spikes and drip, the wet patch they spread from: its own shape
    blurred wide, in `colour`, strongest in the middle round the hole (blood wicks out along the
    threads)."""
    from PIL import ImageFilter
    a = np.asarray(mark, dtype=np.float32)
    side = mark.width
    m = Image.fromarray((a[..., 3]).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(side / 14))
    wet = np.asarray(m, dtype=np.float32) / 255.0
    wet = np.clip(wet / max(wet.max(), 1e-3) * 1.6, 0.0, 1.0) * 0.8
    yy, xx = np.mgrid[0:side, 0:side]
    r = np.hypot(xx - side / 2, yy - side / 2) / (side / 2)
    wet = wet * np.clip(1.2 - r, 0.0, 1.0)
    # Wettest round the hole it came from: the model painted the hole pale (the weave showing), and
    # keyed by redness it cuts out as a gap. What the patch closes round (the outside flooded from
    # the edge; whatever it can't reach) is filled wet, as is the middle.
    from PIL import ImageDraw
    solid = Image.fromarray(((a[..., 3] > 60) * 255).astype(np.uint8), "L").filter(ImageFilter.MaxFilter(3))
    for e in range(side):
        for xy in ((e, 0), (e, side - 1), (0, e), (side - 1, e)):
            if solid.getpixel(xy) == 0:
                ImageDraw.floodfill(solid, xy, 128)
    shut = (np.asarray(solid) == 0).astype(np.uint8) * 255
    shut = np.asarray(Image.fromarray(shut, "L").filter(ImageFilter.GaussianBlur(side / 40)), dtype=np.float32) / 255.0
    core = np.maximum(np.clip(1.0 - r / 0.4, 0.0, 1.0) ** 0.7, np.clip(shut * 1.5, 0.0, 1.0))
    wet = np.maximum(wet, core * 0.9)
    out = np.zeros_like(a)
    out[..., :3] = np.array(colour, dtype=np.float32)
    out[..., 3] = wet * 255.0
    # The painted stain over it.
    k = a[..., 3:4] / 255.0 * (1.0 - core[..., None])
    out[..., :3] = out[..., :3] * (1.0 - k) + a[..., :3] * k
    out[..., 3] = np.maximum(out[..., 3], a[..., 3])
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")


def tint(mark, shades):
    """A mark painted in black ink, coloured from its darkness: darkest (thickest) to the first
    shade, lightest to the last (the game's blood reds)."""
    a = np.asarray(mark, dtype=np.float32)
    lum = a[..., :3].mean(axis=2) / 255.0
    k = np.clip(lum / max(float(np.percentile(lum[a[..., 3] > 128], 95)) if (a[..., 3] > 128).any() else 1.0, 1e-3), 0.0, 1.0)
    dark = np.array(shades[0], dtype=np.float32)
    light = np.array(shades[1], dtype=np.float32)
    rgb = dark[None, None, :] * (1.0 - k[..., None]) + light[None, None, :] * k[..., None]
    out = np.concatenate([rgb, a[..., 3:4]], axis=2)
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")


def main():
    plan = json.load(open(MAP))
    os.makedirs(OUT, exist_ok=True)
    made = []
    for sheet_name, spec in plan["sheets"].items():
        path = os.path.join(RAW, sheet_name + ".jpg")
        if not os.path.exists(path):
            path = os.path.join(RAW, sheet_name + ".png")
        if not os.path.exists(path):
            print("not painted yet:", sheet_name)
            continue
        sheet = Image.open(path)
        for quadrant, key in enumerate(spec["keys"]):
            if not key:
                continue
            mark = cut(sheet, quadrant, float(spec.get("lo", LO)), float(spec.get("hi", HI)), spec.get("key", "white"),
                       int(spec.get("open", 0)), float(spec.get("core", 0.0)))
            if mark is None:
                print("nothing in %s quadrant %d" % (sheet_name, quadrant))
                continue
            if "tint" in spec:
                mark = tint(mark, spec["tint"])
            if "soak" in spec:
                mark = soak(mark, spec["soak"])
            size = int(spec.get("size", 64))
            mark = mark.resize((size, size), Image.LANCZOS)
            mark.save(os.path.join(OUT, key + ".png"))
            made.append((key, mark))
            print("cut:", key, "from", sheet_name, quadrant)
    # A mark that didn't cut clean, replaced by another turned over (blood_map.json "mirror").
    for key, src in plan.get("mirror", {}).items():
        path = os.path.join(OUT, src + ".png")
        if os.path.exists(path):
            m = Image.open(path).transpose(Image.FLIP_LEFT_RIGHT)
            m.save(os.path.join(OUT, key + ".png"))
            made.append((key, m))
            print("mirrored:", key, "from", src)
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
