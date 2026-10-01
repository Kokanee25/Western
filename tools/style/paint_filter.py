#!/usr/bin/env python3
"""The painted-pixel finish, tried on a still image (DESIGN.md §4 style test).

    python3 tools/style/paint_filter.py photo.png out.png [--block=6] [--near=14] [--depth=d.png]
        [--grade=0.7] [--colours=64]

1. Grade: move the photo's colours toward the concept painting's (per-channel mean and spread in
   a log space), by --grade.
2. Blocks: average the image over square blocks. The painting's blocks are bigger close up (on
   the man's coat ~12 px of 1672, on the far bar ~3): they belong to surfaces, like texels. With
   --depth (white = near) blocks run from --block far to --near close; without it, one size.
3. Palette: cut to --colours taken from the concept painting itself, no dithering.
Output is the same size as the input, blocks drawn with nearest filtering.
"""
import sys

import numpy as np
from PIL import Image

CONCEPT = "docs/concept/saloon-night.png"


def args():
    a = {"block": 6, "near": 14, "depth": None, "grade": 0.7, "colours": 64}
    pos = []
    for s in sys.argv[1:]:
        if s.startswith("--"):
            k, v = s[2:].split("=", 1)
            a[k] = v if k == "depth" else float(v)
        else:
            pos.append(s)
    return pos, a


def grade(img, ref, amount):
    li, lr = np.log1p(img), np.log1p(ref)
    out = (li - li.mean((0, 1))) / (li.std((0, 1)) + 1e-6) * lr.std((0, 1)) + lr.mean((0, 1))
    return np.expm1(li + (out - li) * amount).clip(0, 255)


def mosaic(img, size):
    h, w, _ = img.shape
    s = max(1, int(round(size)))
    hh, ww = (h + s - 1) // s * s, (w + s - 1) // s * s
    pad = np.pad(img, ((0, hh - h), (0, ww - w), (0, 0)), mode="edge")
    m = pad.reshape(hh // s, s, ww // s, s, 3).mean((1, 3))
    return np.repeat(np.repeat(m, s, 0), s, 1)[:h, :w]


def main():
    pos, a = args()
    src, dst = pos
    ref_im = Image.open(CONCEPT).convert("RGB")
    img = np.asarray(Image.open(src).convert("RGB"), dtype=float)
    # Block sizes are given at the painting's width (1672); scale to this image.
    k = img.shape[1] / ref_im.width
    img = grade(img, np.asarray(ref_im, dtype=float), a["grade"])
    if a["depth"]:
        d = np.asarray(Image.open(a["depth"]).convert("L").resize((img.shape[1], img.shape[0])), dtype=float) / 255
        sizes = np.linspace(a["block"], a["near"], 5)
        layers = [mosaic(img, s * k) for s in sizes]
        band = np.clip(np.round(d * (len(sizes) - 1)), 0, len(sizes) - 1).astype(int)
        # Each pixel takes the block size for its depth (stepped, so blocks stay square).
        out = np.zeros_like(img)
        for i, L in enumerate(layers):
            out[band == i] = L[band == i]
    else:
        out = mosaic(img, a["block"] * k)
    pal = ref_im.quantize(colors=int(a["colours"]), method=Image.Quantize.MEDIANCUT)
    q = Image.fromarray(out.astype(np.uint8)).quantize(palette=pal, dither=Image.Dither.NONE)
    q.convert("RGB").save(dst)
    print("wrote", dst)


if __name__ == "__main__":
    main()
