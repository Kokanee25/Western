#!/usr/bin/env python3
"""The reference photo's rifle cut from its wood ground (#734): the silhouette overlay.py measures
the model against.

    ~/bpyenv/bin/python experiments/gun_lab/win73/photo_mask.py docs/concept/guns/ref/w73_hmaag_right.jpg build/win73/mask.png

The ground is orange-brown wood and the gun is blued steel and dark walnut: a pixel is the gun where
red less blue is under 38 (steel and wood are near grey; the wood ground is strongly orange). Round
the action, where the case-coloured lever is browner, red less blue under 55 or a dark pixel counts too
(only between x 450 and 1250: the ground's dark corner and the barrel's shadow stay out). The largest
piece is kept, closed by 2 px; holes under 1,200 px are filled (the lever's two loops stay open).
The photo's tang sight (a vernier peep on the upper tang, an accessory the standard rifle doesn't
have) is cut out of the mask: everything above the wrist's top line between x 470 and 560.
"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as nd


def largest(m):
    lab, n = nd.label(m)
    sz = nd.sum(m, lab, range(1, n + 1))
    return lab == (np.argmax(sz) + 1)


def main():
    src, out = sys.argv[1], sys.argv[2]
    im = np.asarray(Image.open(src).convert("RGB")).astype(int)
    R, B = im[..., 0], im[..., 2]
    L = im.mean(2)
    a = nd.binary_opening((R - B) < 38, iterations=2)
    a = largest(a)
    a = nd.binary_closing(a, iterations=3)
    m = nd.binary_opening(((R - B) < 55) | (L < 70), iterations=2)
    m[:, 1250:] = False
    m[:, :450] = False
    g = largest(a | m)
    g = nd.binary_closing(g, iterations=2)
    h = nd.binary_fill_holes(g)
    holes = h & ~g
    hl, hn = nd.label(holes)
    hs = nd.sum(holes, hl, range(1, hn + 1))
    for i, s in enumerate(hs):
        if s < 1200:
            g |= hl == i + 1
    # The tang sight: its staff and base stand above the wrist's top; cut along a line just over the
    # wrist's top, y 214 at x 470 to y 190 at x 560 (this photo's pixels).
    ys, xs = np.mgrid[0:g.shape[0], 0:g.shape[1]]
    top = 214 - (xs - 470) * (214 - 190) / 90.0
    g[(xs >= 470) & (xs <= 560) & (ys < top)] = False
    g = largest(g)
    Image.fromarray((g * 255).astype(np.uint8)).save(out)
    print("mask %s: %d px, holes kept %s" % (out, g.sum(), [int(s) for s in hs if s >= 1200]))


main()
