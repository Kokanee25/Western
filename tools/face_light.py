#!/usr/bin/env python3
"""The light on a seated man's face, as the game draws it against his paint (art's, 2026-10-14;
docs/briefs/character-style-fidelity.md "For the art session").

    xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd -- \\
        --out=DIR --only=shot_match_close --model=<id> --face-probe
    python3 tools/face_light.py DIR [--view=shot_match_close] [--json=OUT]

screenshots.gd --face-probe saves, beside each shot, <view>_paint.png (his head as painted,
unlit: the grade gives back the paint) and <view>_headblack.png (his head black). Where the two
differ is his head (hat, hair and all that's his head piece); there:
  light   the frame's luminance ÷ the paint's (linear), its median and 90th percentile, over the
          pixels whose paint isn't near black (L* >= 15: hair and pupils would divide by ~0);
  clip    the share of his head's pixels with a channel at 250 or more in the frame;
  L*      the median lightness of the frame and of the paint there.
The asked-for hold: the 90th percentile under ~1.3, nothing clipped.
"""
import json
import os
import sys

import numpy as np
from PIL import Image


def lin(u8):
    c = u8.astype(np.float64) / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def luminance(u8):
    l = lin(u8)
    return l[..., 0] * 0.2126 + l[..., 1] * 0.7152 + l[..., 2] * 0.0722


def lightness(y):
    f = np.where(y > 0.008856, np.cbrt(y), 7.787 * y + 16.0 / 116.0)
    return 116.0 * f - 16.0


def measure(d, view):
    load = lambda n: np.asarray(Image.open(os.path.join(d, "%s%s.png" % (view, n))).convert("RGB"))
    game, paint, black = load(""), load("_paint"), load("_headblack")
    head = np.abs(paint.astype(int) - black.astype(int)).max(axis=2) > 12
    yg, yp = luminance(game), luminance(paint)
    lit = head & (lightness(yp) >= 15.0)
    ratio = yg[lit] / np.maximum(yp[lit], 1e-4)
    return {
        "pixels": int(head.sum()),
        "light_median": round(float(np.median(ratio)), 2),
        "light_p90": round(float(np.percentile(ratio, 90)), 2),
        "clip_share": round(float((game[head].max(axis=1) >= 250).mean()), 3),
        "lstar_game": round(float(np.median(lightness(yg[head]))), 1),
        "lstar_paint": round(float(np.median(lightness(yp[head]))), 1),
    }


def main():
    a = dict(x.split("=", 1) for x in sys.argv[2:] if x.startswith("--") and "=" in x)
    d = sys.argv[1]
    r = measure(d, a.get("--view", "shot_match_close"))
    print("head %(pixels)d px: light median %(light_median).2f, p90 %(light_p90).2f; clipped %(clip_share).1f%%; "
          "L* %(lstar_game).0f (paint %(lstar_paint).0f)" % dict(r, clip_share=r["clip_share"] * 100))
    if "--json" in a:
        json.dump(r, open(a["--json"], "w"), indent=1)


if __name__ == "__main__":
    main()
