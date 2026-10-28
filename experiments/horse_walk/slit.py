"""Space-time pictures of the hoof row: each frame's band of rows at hoof height, shifted by the
camera's pan (pan.json) so the ground stands still, stacked one frame a row. A planted hoof is a
vertical streak; a swinging hoof a slanting one.

    python3 experiments/horse_walk/slit.py --rows=455,495 --frames=0,250 [--scale=2]
"""
import glob
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "build", "horse_walk")


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    y0, y1 = (int(v) for v in opts.get("rows", "455,495").split(","))
    f0, f1 = (int(v) for v in opts.get("frames", "0,250").split(","))
    pan = json.load(open(os.path.join(OUT, "pan.json")))["pan"]
    frames = sorted(glob.glob(os.path.join(OUT, "frames", "f*.png")))
    W = 970
    lo = int(min(-pan[i] for i in range(f0, f1))) - 1
    width = W + int(max(-pan[i] for i in range(f0, f1)) - lo) + 2
    img = np.zeros((f1 - f0, width, 3), np.uint8)
    for k, i in enumerate(range(f0, f1)):
        a = np.asarray(Image.open(frames[i]).convert("RGB"), float)[y0:y1]
        # the darkest pixel down the band in each column (hooves and legs are the darkest things)
        lum = a.mean(axis=2)
        idx = np.argmin(lum, axis=0)
        row = a[idx, np.arange(a.shape[1])]
        x = -pan[i] - lo
        xi = int(np.floor(x))
        fr = x - xi
        shifted = np.zeros((width, 3))
        shifted[xi:xi + W] += row * (1 - fr)
        shifted[xi + 1:xi + 1 + W] += row * fr
        img[k] = np.clip(shifted, 0, 255)
    if "clean" in opts:
        # each ground column's own look over time (its median) taken away: the ground's streaks
        # go, the horse stays (a hoof stands on a column ~1 s of the clip's 8)
        f = img.astype(float)
        valid = f.sum(axis=2) > 0
        med = np.array([np.median(f[valid[:, x], x], axis=0) if valid[:, x].any() else np.zeros(3)
                        for x in range(width)])
        dark = np.clip((med.mean(axis=1)[None, :] - f.mean(axis=2)) * float(opts["clean"]), 0, 255)
        img = np.where(valid[..., None], np.stack([255 - dark] * 3, axis=2), 255).astype(np.uint8)
    s = int(opts.get("scale", "1"))
    im = Image.fromarray(img).resize((width, (f1 - f0) * s), Image.NEAREST)
    d = ImageDraw.Draw(im)
    for f in range(f0, f1, 10):
        y = (f - f0) * s
        d.line([(0, y), (12 if f % 30 else 30, y)], fill=(255, 255, 0))
        if f % 30 == 0:
            d.text((32, y - 5), str(f), fill=(255, 255, 0))
    for gx in range(0, width, 50):
        d.line([(gx, 0), (gx, 4)], fill=(0, 255, 255))
    path = os.path.join(OUT, opts.get("out", "slit_%d_%d.png" % (y0, y1)))
    im.save(path)
    print(path, im.size, "ground x of column 0 =", lo)


if __name__ == "__main__":
    main()
