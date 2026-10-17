#!/usr/bin/env python3
"""How much each expression changes his face at the game's size: the face lab's renders at
1920x1080, 75°, 2 m (tools/faces/face_lab.gd --fov=75 --dist=2) against his face at rest.

    python3 tools/faces/readability.py DIR
Per expression: the pixels of his face (a box round it) that change by more than STEP in any
channel, and the mean change; jaw_open is the yardstick a viewer reads at once.
"""
import glob
import os
import sys

import numpy as np
from PIL import Image

STEP = 12          # 0..255: a change a viewer sees between neighbouring frames
BOX = (915, 485, 1005, 590)   # his head at 2 m in the 1080p frame


def main():
    d = sys.argv[1]
    rest = np.asarray(Image.open(os.path.join(d, "rest_0.png")).convert("RGB").crop(BOX), int)
    rows = []
    for p in sorted(glob.glob(os.path.join(d, "*_0.png"))):
        e = os.path.basename(p)[:-6]
        if e == "rest":
            continue
        im = np.asarray(Image.open(p).convert("RGB").crop(BOX), int)
        diff = np.abs(im - rest).max(2)
        rows.append((e, int((diff > STEP).sum()), float(diff.mean())))
    ref = next((r[1] for r in rows if r[0] == "jaw_open"), 1) or 1
    for e, n, m in sorted(rows, key=lambda r: -r[1]):
        print("%-11s %4d px changed (%3.0f%% of jaw_open's), mean %.1f" % (e, n, 100 * n / ref, m))


if __name__ == "__main__":
    main()
