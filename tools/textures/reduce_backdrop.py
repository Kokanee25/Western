#!/usr/bin/env python3
"""The painted backdrop, step 2: cut the image model's panels (paint_backdrop.py) into the game's
strips, one 360-degree strip of squares per layer.

    python3 tools/textures/reduce_backdrop.py [--sheet=docs/screenshots/backdrop/x.png]

For each panel in tools/textures/backdrop.json with a raw painting
(assets/textures/raw/backdrop_<layer>_<n>.jpg):
  1. the green screen keyed out (alpha), green spill taken off the edges;
  2. cut to squares: `degrees_per_texel` of horizon a texel (0.3: ~3 screen pixels on the street
     shot's lens, the painting's far rock), each the average of the opaque paint under it, kept
     where at least half of it is land;
  3. laid into its layer's strip at its bearing (centre + shift), round the circle;
  4. the land made solid: each column filled down from its top (no holes to see the sky through
     under a rock), the nearest layer's foot carried right round so the horizon has no gaps, lone
     specks dropped;
  5. the painting's mosaic pushed (reduce.py's MOSAIC) and each layer cut to its own palette.
Writes assets/textures/backdrop_<layer>.png (RGBA, read nearest; alpha = land) and
assets/textures/backdrop.json (each layer's ring: radius, bearings, the angles its rows span,
haze), which src/art/backdrop.gd reads; and a contact sheet with --sheet.
"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy.ndimage import label

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import reduce as rd  # noqa: E402

SPEC = os.path.join(rd.ROOT, "tools", "textures", "backdrop.json")
OUT_JSON = os.path.join(rd.OUT, "backdrop.json")
# Keying: how much greener than its red and blue a pixel is before it's background (fully at the
# second number).
KEY = (24.0, 70.0)
# Land islands smaller than this many texels are dropped (stray specks the model left in the green).
MIN_ISLAND = 6
IMPORT = rd.IMPORT.replace("mipmaps/generate=true", "mipmaps/generate=false")


def key_out(img):
    """RGBA float (h, w, 4): alpha from how green each pixel is; spill taken off what's kept."""
    a = np.asarray(img.convert("RGB")).astype(np.float64)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    green = g - np.maximum(r, b)
    alpha = 1.0 - np.clip((green - KEY[0]) / (KEY[1] - KEY[0]), 0.0, 1.0)
    # Spill: no kept pixel greener than the middle of its red and blue (green mixed into red rock
    # at an edge otherwise reads as a yellow line).
    a[..., 1] = np.minimum(g, (r + b) * 0.5 + 6.0)
    return np.concatenate([a / 255.0, alpha[..., None]], -1)


def to_squares(rgba, size):
    """Each square the average of the opaque paint under it; opaque where half of it is land."""
    w, h = size
    prem = rgba[..., :3] * rgba[..., 3:4]
    img = Image.fromarray((np.clip(np.concatenate([prem, rgba[..., 3:4]], -1), 0, 1) * 255).astype(np.uint8), "RGBA")
    small = np.asarray(img.resize((w, h), Image.BOX)).astype(np.float64) / 255.0
    alpha = small[..., 3]
    rgb = small[..., :3] / np.maximum(alpha[..., None], 1e-4)
    return np.clip(rgb, 0, 1), alpha >= 0.5


def solid(rgb, land, ground):
    """Fill each column down from its topmost land texel; `ground`: carry the foot round so every
    column has land at least up to the horizon row (the nearest layer)."""
    h, w = land.shape
    out_rgb, out_land = rgb.copy(), land.copy()
    for x in range(w):
        rows = np.where(land[:, x])[0]
        if len(rows):
            top = rows[0]
            for y in range(top + 1, h):
                if not out_land[y, x]:
                    out_rgb[y, x] = out_rgb[y - 1, x]
                    out_land[y, x] = True
    if ground is not None:
        # Columns with no land at the horizon take the nearest column that has some.
        horizon_row, colour = ground
        have = np.where(out_land[horizon_row])[0]
        for x in range(w):
            if out_land[horizon_row, x]:
                continue
            if len(have):
                d = np.minimum(np.abs(have - x), w - np.abs(have - x))
                src = have[d.argmin()]
                out_rgb[:, x] = np.where(out_land[:, src, None], out_rgb[:, src], out_rgb[:, x])
                out_land[:, x] = out_land[:, src]
            else:
                out_rgb[horizon_row:, x] = colour
                out_land[horizon_row:, x] = True
    # Specks.
    lab, n = label(out_land)
    for i in range(1, n + 1):
        m = lab == i
        if m.sum() < MIN_ISLAND:
            out_land[m] = False
    return out_rgb, out_land


def main():
    sheet = None
    for a in sys.argv[1:]:
        if a.startswith("--sheet="):
            sheet = a.split("=", 1)[1]
    spec = json.load(open(SPEC))
    dpt = spec["degrees_per_texel"]
    span = spec["span"]
    width = int(round(360.0 / dpt))
    info = {"degrees_per_texel": dpt, "layers": {}}
    strips = []
    for lid, layer in spec["layers"].items():
        rgb = np.zeros((1, width, 3))
        land = None
        height_deg = None
        painted = 0
        for i, panel in enumerate(layer["panels"]):
            path = os.path.join(rd.RAW, "backdrop_%s_%d.jpg" % (lid, i))
            if not os.path.exists(path):
                continue
            img = Image.open(path)
            if height_deg is None:
                height_deg = span * img.height / img.width
                th = int(round(height_deg / dpt))
                rgb = np.zeros((th, width, 3))
                land = np.zeros((th, width), dtype=bool)
            pw = int(round(span / dpt))
            prgb, pland = to_squares(key_out(img), (pw, rgb.shape[0]))
            x0 = int(round(((panel["centre"] + panel.get("shift", 0.0) - span / 2.0) % 360.0) / dpt))
            cols = (np.arange(pw) + x0) % width
            for k, x in enumerate(cols):
                m = pland[:, k]
                rgb[m, x] = prgb[m, k]
                land[m, x] |= True
            painted += 1
            print("%-16s %3d%% land" % ("backdrop_%s_%d" % (lid, i), round(100 * pland.mean())))
        if painted == 0:
            print("no panels painted for", lid)
            continue
        th = rgb.shape[0]
        horizon_row = th - 1 - int(round(-spec["bottom"] / dpt))
        ground = None
        if lid == "near":
            ground = (horizon_row, np.median(rgb[land], 0))
        rgb, land = solid(rgb, land, ground)
        # The mosaic: on the whole strip (neighbours), then the palette on the land.
        full = rd.to_lab((rgb * 255).astype(np.uint8))
        full = rd.mosaic(full, rd.MOSAIC, True)
        snapped, pal = rd.palette_snap(full[land][None], layer["colours"], sum(map(ord, lid)))
        full[land] = snapped[0]
        out = np.zeros((th, width, 4), dtype=np.uint8)
        out[..., :3] = rd.lab_to_rgb(full)
        out[..., 3] = np.where(land, 255, 0)
        name = "backdrop_%s.png" % lid
        Image.fromarray(out, "RGBA").save(os.path.join(rd.OUT, name))
        imp = os.path.join(rd.OUT, name + ".import")
        if not os.path.exists(imp):
            with open(imp, "w") as f:
                f.write(IMPORT)
        info["layers"][lid] = {"texture": name, "radius": layer["radius"], "haze": layer["haze"],
                               "bottom": spec["bottom"], "top": spec["bottom"] + th * dpt,
                               "texels": [width, th], "panels": painted}
        strips.append(out)
        print("%-16s %dx%d texels, %d colours, %d of %d panels" % (name, width, th, len(pal), painted, len(layer["panels"])))
    with open(OUT_JSON, "w") as f:
        json.dump(info, f, indent=1)
    if sheet and strips:
        os.makedirs(os.path.dirname(sheet), exist_ok=True)
        bg = np.array([96, 140, 196, 255], dtype=np.uint8)
        rows = []
        for s in strips:
            canvas = np.tile(bg, (s.shape[0], s.shape[1], 1))
            m = s[..., 3:4] > 0
            canvas = np.where(m, s, canvas)
            rows.append(canvas)
            rows.append(np.zeros((4, s.shape[1], 4), dtype=np.uint8) + 255)
        im = Image.fromarray(np.concatenate(rows, 0), "RGBA").convert("RGB")
        im.resize((im.width * 2, im.height * 2), Image.NEAREST).save(sheet)
        print("sheet:", sheet)


if __name__ == "__main__":
    main()
