"""The hooves in the reference clip, by subtracting the ground: every frame shifted by the camera's
pan (pan.json) onto the ground, the ground's own picture the median of all frames, the horse what
differs from it. Then, per frame and ground column, the lowest pixel of horse in the hoof band:
a space-time picture (a frame a row) coloured by that height, near hooves (lower in the picture)
warm, far hooves cool. A planted hoof is a vertical streak at one height.

    python3 experiments/horse_walk/hooves.py [--band=440,505] [--frames=0,250]
"""
import glob
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "build", "horse_walk")
W = 970


def stabilised(frames, pan, y0, y1, lo, width):
    """Every frame's band laid on the ground's columns (nan where the frame doesn't reach)."""
    st = np.full((len(frames), y1 - y0, width, 3), np.nan, np.float32)
    for i, p in enumerate(frames):
        a = np.asarray(Image.open(p).convert("RGB"), np.float32)[y0:y1]
        x = int(round(-pan[i] - lo))
        st[i, :, x:x + W] = a
    return st


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    y0, y1 = (int(v) for v in opts.get("band", "440,505").split(","))
    f0, f1 = (int(v) for v in opts.get("frames", "0,250").split(","))
    thr = float(opts.get("thr", "38"))
    pan = json.load(open(os.path.join(OUT, "pan.json")))["pan"]
    frames = sorted(glob.glob(os.path.join(OUT, "frames", "f*.png")))
    lo = int(np.floor(min(-v for v in pan))) - 1
    width = W + int(np.ceil(max(-v for v in pan) - lo)) + 2
    st = stabilised(frames, pan, y0, y1, lo, width)
    bg = np.nanmedian(st, axis=0)
    diff = np.sqrt(np.nansum((st - bg[None]) ** 2, axis=3))
    fg = diff > thr
    # small specks out: a pixel needs a neighbour above it that is horse too (legs are vertical)
    fg[:, 1:] &= fg[:, :-1]
    np.save(os.path.join(OUT, "fg_%d_%d.npy" % (y0, y1)), np.packbits(fg, axis=2))
    json.dump({"band": [y0, y1], "lo": lo, "width": width, "frames": len(frames)},
              open(os.path.join(OUT, "fg_meta.json"), "w"))
    # lowest horse pixel per (frame, column)
    h = fg.shape[1]
    rev = fg[:, ::-1, :]
    has = fg.any(axis=1)
    low = h - 1 - np.argmax(rev, axis=1)  # row index of lowest fg pixel
    low = np.where(has, low, -1)
    n = f1 - f0
    img = np.zeros((n, width, 3), np.uint8)
    sub = low[f0:f1]
    t = np.clip((sub - (h - 45)) / 45.0, 0, 1)  # bottom 45 rows of the band coloured
    img[..., 0] = np.where(sub >= 0, 60 + 195 * t, 0)
    img[..., 1] = np.where(sub >= 0, 60 + 120 * (1 - abs(t - 0.5) * 2), 0)
    img[..., 2] = np.where(sub >= 0, 255 - 195 * t, 0)
    s = int(opts.get("scale", "2"))
    im = Image.fromarray(img).resize((width, n * s), Image.NEAREST)
    d = ImageDraw.Draw(im)
    for f in range(f0, f1, 10):
        y = (f - f0) * s
        d.line([(0, y), (12 if f % 30 else 30, y)], fill=(255, 255, 255))
        if f % 30 == 0:
            d.text((32, y - 5), str(f), fill=(255, 255, 255))
    for gx in range(0, width, 50):
        d.line([(gx, 0), (gx, 6 if gx % 100 else 14)], fill=(255, 255, 255))
        if gx % 100 == 0:
            d.text((gx + 2, 14), str(gx), fill=(255, 255, 255))
    path = os.path.join(OUT, opts.get("out", "hooves_%d_%d.png" % (f0, f1)))
    im.save(path)
    print(path, im.size, "lo", lo)


if __name__ == "__main__":
    main()
