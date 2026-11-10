#!/usr/bin/env python3
"""The weave's number (#721): a pixel-scale checker in the 1 m material shots.

  python3 tools/weave_measure.py IMG [IMG...] [--box=x,y,w,h]

For each picture: `weave`, the mean response to a 2x2 checker kernel (+1 -1 / -1 +1) per 100 of
the mean brightness (luma): the alternating single pixels the judges called a weave or burlap.
Real grain at 1 m is a few pixels wide and barely answers it. Also `rows` and `cols`: the
[1 -2 1] second difference down and across (row- and column-alternation).
"""
import sys
import numpy as np
from PIL import Image


def measure(path, box=None):
    a = np.asarray(Image.open(path).convert("RGB"), dtype=float)
    a = a @ np.array([0.299, 0.587, 0.114])
    if box:
        x, y, w, h = box
        a = a[y:y + h, x:x + w]
    m = max(a.mean(), 1.0)
    chk = np.abs(a[:-1, :-1] - a[1:, :-1] - a[:-1, 1:] + a[1:, 1:]).mean() / 4.0
    rows = np.abs(a[:-2] - 2 * a[1:-1] + a[2:]).mean() / 4.0
    cols = np.abs(a[:, :-2] - 2 * a[:, 1:-1] + a[:, 2:]).mean() / 4.0
    return 100 * chk / m, 100 * rows / m, 100 * cols / m


if __name__ == "__main__":
    box = None
    paths = []
    for arg in sys.argv[1:]:
        if arg.startswith("--box="):
            box = tuple(int(v) for v in arg[6:].split(","))
        else:
            paths.append(arg)
    for p in paths:
        w, r, c = measure(p, box)
        print("%-60s weave %.2f  rows %.2f  cols %.2f" % (p, w, r, c))
