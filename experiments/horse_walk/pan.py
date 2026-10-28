"""The camera's pan in the reference clip, frame to frame, from the ground under the horse.

    ~/bpyenv/bin/python experiments/horse_walk/pan.py [--frames=build/horse_walk/frames]

Phase correlation (numpy FFT) between each frame and the next, on a strip of ground below the
hooves (the rocks and dirt: the same depth as the horse, so his hooves are measured against what
they stand on, not the hills, which pan slower by parallax). Writes build/horse_walk/pan.json:
the ground's x in each frame's pixels (cumulative), so a pixel x in frame i is at ground x
`x - pan[i]`.
"""
import glob
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "build", "horse_walk")


def grey(path, y0, y1):
    a = np.asarray(Image.open(path).convert("L"), float)[y0:y1]
    a = a - a.mean()
    return a * np.hanning(a.shape[1])[None, :] * np.hanning(a.shape[0])[:, None]


def shift(a, b):
    """The (dy, dx) that moves a onto b, to a tenth of a pixel (parabolic peak)."""
    F = np.fft.fft2(a) * np.conj(np.fft.fft2(b))
    r = np.fft.ifft2(F / (np.abs(F) + 1e-9)).real
    iy, ix = np.unravel_index(np.argmax(r), r.shape)
    h, w = r.shape

    def sub(i, n, line):
        l, c, rr = line[(i - 1) % n], line[i], line[(i + 1) % n]
        d = (l - 2 * c + rr)
        return i + (0.5 * (l - rr) / d if abs(d) > 1e-12 else 0.0)
    dx = sub(ix, w, r[iy])
    dy = sub(iy, h, r[:, ix])
    if dx > w / 2:
        dx -= w
    if dy > h / 2:
        dy -= h
    return -dy, -dx


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    frames = sorted(glob.glob(os.path.join(opts.get("frames", os.path.join(OUT, "frames")), "f*.png")))
    y0, y1 = (int(v) for v in opts.get("rows", "494,512").split(","))
    pan = [0.0]
    steps = []
    prev = grey(frames[0], y0, y1)
    for p in frames[1:]:
        cur = grey(p, y0, y1)
        dy, dx = shift(prev, cur)
        steps.append(dx)
        pan.append(pan[-1] + dx)
        prev = cur
    json.dump({"rows": [y0, y1], "pan": [round(v, 2) for v in pan], "step": [round(v, 2) for v in steps]},
              open(os.path.join(OUT, "pan.json"), "w"))
    s = np.array(steps)
    print("frames", len(frames), "pan px/frame mean %.2f sd %.2f min %.2f max %.2f" % (s.mean(), s.std(), s.min(), s.max()))
    for i in range(0, len(steps), 30):
        print(i, "%.2f" % np.mean(s[i:i + 30]), "cum %.1f" % pan[i])


if __name__ == "__main__":
    main()
