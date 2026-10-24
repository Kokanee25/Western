#!/usr/bin/env python3
"""Holes in a talking man's face: background showing through inside his silhouette, counted on the
face lab's frames (docs/briefs/face-seam.md: the storekeeper's chin, 2026-10-23, where the grey
behind him showed through under his jaw and turned black as his mouth opened).

    ~/.venvs/studio/bin/python tools/faces/hole_count.py DIR [DIR ...] [--map=OUT]   # every *.png in each

A frame's background is its corner colour. A hole is background-coloured pixels the man's
silhouette closes round (filled by scipy's binary_fill_holes): not the gaps beside his ears or
between his arm and side, which open to the frame's edge. Black inside him (the mouth's inside, a
painted shadow) isn't counted: it can't be told from paint by colour alone; look at the frames.
Gaps the silhouette also closes round count too (under a hat's brim, between strands of hair: the
drifter's brim, 600 px, is no fault), so a count is a pointer: `--map=OUT` writes each frame with
its holes in magenta, and the map says whether they're in his face. Prints each frame's count and
exits 1 if any frame has more than LIMIT.
"""
import glob
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

TOL = 6        # a pixel this near the corner colour (each channel) is background
LIMIT = 0      # holes allowed in a frame (pixels)


def holes(path, map_dir=None):
    a = np.asarray(Image.open(path).convert("RGB")).astype(int)
    bg = a[2, 2]
    is_bg = (np.abs(a - bg) <= TOL).all(-1)
    h = ndimage.binary_fill_holes(~is_bg) & is_bg
    if map_dir:
        v = a.astype(np.uint8)
        v[ndimage.binary_dilation(h, iterations=2)] = (255, 0, 255)
        name = os.path.basename(os.path.dirname(os.path.abspath(path))) + "_" + os.path.basename(path)
        Image.fromarray(v).save(os.path.join(map_dir, name))
    return int(h.sum())


def main():
    bad = 0
    map_dir = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--map=")), None)
    if map_dir:
        os.makedirs(map_dir, exist_ok=True)
    for d in [a for a in sys.argv[1:] if not a.startswith("--")]:
        for f in sorted(glob.glob(os.path.join(d, "*.png"))):
            n = holes(f, map_dir)
            bad += n > LIMIT
            print("%-60s %5d%s" % (os.path.relpath(f), n, "  HOLES" if n > LIMIT else ""))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
