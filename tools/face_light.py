#!/usr/bin/env python3
"""The light on a seated man's face, as the game draws it against his paint (art's, 2026-10-14;
docs/briefs/character-style-fidelity.md "For the art session").

    xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd -- \\
        --out=DIR --only=shot_match_close --model=<id> --face-probe
    python3 tools/face_light.py DIR [--view=shot_match_close] [--json=OUT]

screenshots.gd --face-probe saves, beside each shot and with him held still, <view>_game.png (as
the game draws him), <view>_paint.png (his head as painted, unlit: the grade gives back the
paint) and <view>_headblack.png (his head black). Where the last two differ is his head; his face is its skin (painted warm, L* >= 25: not his hair, brows or
moustache). On each:
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
from scipy.ndimage import binary_erosion


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
    game, paint, black = load("_game"), load("_paint"), load("_headblack")
    # His head: painted against black, by a margin (every edge in the frame shifts a little
    # between passes), eroded twice so the thin lines that remain drop out. (Blown white bloomed
    # into a disc round him.) Near-black paint (hair) can't be told from black: it isn't measured.
    head = (paint.astype(int) - black.astype(int)).max(axis=2) > 25
    head = binary_erosion(head, iterations=2)
    yg, yp = luminance(game), luminance(paint)
    lp = lightness(yp)
    # His face: the head's skin, painted warm and not dark (his hair, brows and moustache aren't).
    skin = head & (lp >= 25.0) & (paint[..., 0].astype(int) > paint[..., 2].astype(int) + 12)
    out = {"pixels": int(head.sum()), "face_pixels": int(skin.sum())}
    for name, m in (("head", head & (lp >= 15.0)), ("face", skin)):
        ratio = yg[m] / np.maximum(yp[m], 1e-4)
        out[name] = {
            "light_median": round(float(np.median(ratio)), 2),
            "light_p90": round(float(np.percentile(ratio, 90)), 2),
            "clip_share": round(float((game[m].max(axis=1) >= 250).mean()), 3),
            "lstar_game": round(float(np.median(lightness(yg[m]))), 1),
            "lstar_paint": round(float(np.median(lp[m])), 1),
        }
    return out


def main():
    a = dict(x.split("=", 1) for x in sys.argv[2:] if x.startswith("--") and "=" in x)
    d = sys.argv[1]
    r = measure(d, a.get("--view", "shot_match_close"))
    for name in ("face", "head"):
        q = r[name]
        print("%s (%d px): light median %.2f, p90 %.2f; clipped %.1f%%; L* %.0f (paint %.0f)" % (
            name, r["face_pixels" if name == "face" else "pixels"], q["light_median"], q["light_p90"],
            q["clip_share"] * 100, q["lstar_game"], q["lstar_paint"]))
    if "--json" in a:
        json.dump(r, open(a["--json"], "w"), indent=1)


if __name__ == "__main__":
    main()
