#!/usr/bin/env python3
"""The painted sky, step 2 (tools/textures/sky.json): cut the two panels paint_sky.py painted
(assets/textures/raw/sky_<panel>.jpg) for the game, and measure what src/world/sky.gdshader needs to
lay them round the town.

    python3 tools/textures/reduce_sky.py

Writes assets/textures/sky/sky_sun.jpg and sky_away.jpg (the panels, their two meeting edges eased
toward each other's colour so the seams don't show) and assets/textures/sky/sky.json:
- `span`: the degrees of sky a panel's height covers (it's 180 degrees wide, painted without
  perspective, so its height in degrees is 180 x height / width);
- `sun`: where the painted sun is in the sun panel (u across, and degrees above its bottom edge),
  found as the brightest spot once blurred; the shader turns and lifts both panels so it lies on
  DayCycle's sun;
- `zenith`: the panels' mean colour along their top edges, which the sky fades to overhead, above
  what was painted.
"""
import json
import os

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RAW = os.path.join(ROOT, "assets", "textures", "raw", "sky_%s.jpg")
OUT = os.path.join(ROOT, "assets", "textures", "sky")
# How many columns at each meeting edge are eased toward the other panel's edge (a share of the width).
SEAM = 0.04


def main():
    os.makedirs(OUT, exist_ok=True)
    sun = np.asarray(Image.open(RAW % "sun").convert("RGB")).astype(np.float32)
    away = np.asarray(Image.open(RAW % "away").convert("RGB")).astype(np.float32)
    h, w, _ = sun.shape
    away = np.asarray(Image.fromarray(away.astype(np.uint8)).resize((w, h), Image.LANCZOS)).astype(np.float32)

    blur = np.asarray(Image.fromarray(sun.astype(np.uint8)).filter(ImageFilter.GaussianBlur(6))).astype(np.float32)
    lum = blur.mean(axis=2)
    sy, sx = np.unravel_index(lum.argmax(), lum.shape)
    span = 180.0 * h / w

    # The seams: the sun panel's right edge meets the away panel's left, and the away panel's right
    # meets the sun panel's left. Each side eased half way toward the mean of the two edge columns,
    # fading out over SEAM of the width (the shader crossfades what's left).
    n = max(int(w * SEAM), 2)
    ramp = (1.0 - np.arange(n) / n)[None, :, None] * 0.5
    for left, right in ((away, sun), (sun, away)):
        meet = (left[:, :1] + right[:, -1:]) * 0.5
        left[:, :n] += (meet - left[:, :n]) * ramp
        right[:, -n:] += (meet - right[:, -n:]) * ramp[:, ::-1]

    zenith = np.concatenate([sun[: h // 40], away[: h // 40]], axis=1).reshape(-1, 3).mean(axis=0) / 255.0
    for name, a in (("sun", sun), ("away", away)):
        Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).save(os.path.join(OUT, "sky_%s.jpg" % name), quality=92)
    info = {
        "span": round(span, 2),
        "sun": [round(float(sx) / w, 4), round(float(h - sy) / h * span, 2)],
        "zenith": [round(float(c), 3) for c in zenith],
    }
    with open(os.path.join(OUT, "sky.json"), "w") as f:
        json.dump(info, f, indent=1)
    print("sky:", info)


if __name__ == "__main__":
    main()
