#!/usr/bin/env python3
"""The bar top's wood (Sean, 2026-10-21: "bar top? drink rings in the wood?"; docs/briefs/interior-woodwork.md):
the interior oak (assets/textures/woods/int_oak_b*.png) glued up into a bar top's full depth, its
finish oiled and rubbed (lab.json `roughness`: a soft sheen, not lacquer), drink rings where men stand (soft, broken, of two kinds: the
dark ring a wet glass leaves in the finish and the pale bloom of a hot one), and the front edge worn
lighter and smoother where elbows rest. Free (no paid call), seeded: the same every run.

    python3 tools/textures/bar_top.py [--strips=3] [--seed=1882]

The strip runs along the bar (u) as every board's; v across its depth from the front edge, as the
bar top profile's top face runs (Profiles.bar_top through Profiles.extrude_tris: v from its front).
Writes woods/int_bar_top_b<k>.png, its end grain (the oak's) and its lab.json entry.
"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
WOODS = os.path.join(ROOT, "assets", "textures", "woods")
TPM = 384
DEPTH_M = 0.84
NAME = "int_bar_top"


def glued_up(rng, length):
    """Several oak boards side by side across the top's depth, each from its own strip and place."""
    rows = int(round(DEPTH_M * TPM))
    out = np.zeros((rows, length, 3), np.float32)
    boards = sorted(f for f in os.listdir(WOODS) if f.startswith("int_oak_b") and f.endswith(".png"))
    y = 0
    while y < rows:
        im = np.asarray(Image.open(os.path.join(WOODS, boards[rng.integers(len(boards))])).convert("RGB")).astype(np.float32)
        im = np.roll(im, rng.integers(im.shape[1]), axis=1)
        if im.shape[1] < length:
            im = np.concatenate([im, im[:, ::-1]], axis=1)
        h = min(im.shape[0], rows - y)
        out[y:y + h] = im[:h, :length]
        # The glue line: a faint dark seam between boards.
        out[y:y + 1] *= 0.82
        y += h
    return out


def rings(rng, shape):
    """Two masks (dark rings, pale blooms), 0-1: rings 7-9 cm across, clustered every ~0.6 m along
    the bar where men stand, near the front (8-35 cm in), broken and soft-edged."""
    rows, cols = shape
    dark = np.zeros(shape, np.float32)
    pale = np.zeros(shape, np.float32)
    yy, xx = np.mgrid[0:rows, 0:cols]
    places = np.arange(0.3, cols / TPM, 0.6)
    places = places + rng.uniform(-0.12, 0.12, len(places))
    for p in places:
        for _ in range(rng.integers(2, 6)):
            cx = (p + rng.normal(0, 0.12)) * TPM
            cy = rng.uniform(0.08, 0.35) * TPM
            r = rng.uniform(0.035, 0.045) * TPM
            w = rng.uniform(2.0, 4.0)
            # Wrapped along the strip (it tiles along its length).
            dx = (xx - cx + cols / 2) % cols - cols / 2
            d = np.hypot(dx, yy - cy)
            ring = np.exp(-((d - r) / w) ** 2)
            # Broken: part of the ring faded, where the glass sat unevenly.
            ang = np.arctan2(yy - cy, dx)
            gap = 0.5 + 0.5 * np.cos(ang - rng.uniform(0, 2 * np.pi))
            ring *= np.clip(0.35 + 0.9 * gap, 0, 1) * rng.uniform(0.5, 1.0)
            target = pale if rng.random() < 0.3 else dark
            np.maximum(target, ring, out=target)
    return gaussian_filter(dark, 1.0), gaussian_filter(pale, 1.4)


def make(seed, strips):
    rng = np.random.default_rng(seed)
    length = 3 * TPM
    for k in range(strips):
        a = glued_up(rng, length)
        rows = a.shape[0]
        lum = a.mean(axis=2, keepdims=True)
        # The front edge worn where arms rest: lighter, the grain's contrast eased, fading in over
        # 12 cm, uneven along the bar.
        v = np.linspace(0.0, DEPTH_M, rows)[:, None, None]
        along = gaussian_filter(rng.random(length), 40, mode="wrap")
        along = (along - along.min()) / max(np.ptp(along), 1e-6)
        wear = np.clip(1.0 - v / 0.12, 0.0, 1.0) ** 1.5 * (0.55 + 0.45 * along[None, :, None])
        soft = gaussian_filter(a, (2.0, 3.0, 0))
        a = a * (1 - 0.6 * wear) + soft * 0.6 * wear
        a = a * (1.0 + 0.22 * wear)
        dark, pale = rings(rng, (rows, length))
        a = a * (1.0 - 0.32 * dark[..., None])
        a = a + (np.array([214.0, 196.0, 170.0]) - a) * 0.28 * pale[..., None]
        # Toward the picture's bar: warm umber, not cherry (the blind critic, 2026-10-21): a little
        # less red, a little lighter.
        a = a * np.array([1.06, 1.12, 1.04])
        out = Image.fromarray(np.clip(a + 0.5, 0, 255).astype(np.uint8))
        out.save(os.path.join(WOODS, "%s_b%d.png" % (NAME, k)))
        if k == 0:
            out.crop((0, 0, min(length, 1024), rows)).save(os.path.join(WOODS, "%s.png" % NAME))
    Image.open(os.path.join(WOODS, "int_oak_end.png")).save(os.path.join(WOODS, "%s_end.png" % NAME))
    params = open(os.path.join(WOODS, "floor_b0.png.import")).read().split("[params]", 1)[1]
    for f in os.listdir(WOODS):
        if f.startswith(NAME) and f.endswith(".png") and not os.path.exists(os.path.join(WOODS, f + ".import")):
            with open(os.path.join(WOODS, f + ".import"), "w") as fh:
                fh.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]' + params)
    index_path = os.path.join(WOODS, "lab.json")
    index = json.load(open(index_path))
    index["woods"][NAME] = {"boards": strips, "rows": int(round(DEPTH_M * TPM)), "length": length, "texels_per_metre": TPM,
                            "end": "%s_end.png" % NAME, "end_texels": 256, "roughness": 0.6, "specular": 0.4,
                            "made_by": "tools/textures/bar_top.py (int_oak glued up, rings, worn front, polished)"}
    json.dump(index, open(index_path, "w"), indent=1)
    print("bar top: %d strips of %dx%d into woods/%s_b*.png" % (strips, length, int(round(DEPTH_M * TPM)), NAME))


def main():
    args = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    make(int(args.get("seed", 1882)), int(args.get("strips", 3)))


if __name__ == "__main__":
    main()
