#!/usr/bin/env python3
"""The material lab's woods (art, 2026-10-14): boards painted stroke by stroke in the language of
the masters (docs/concept/street-golden-hour.png, saloon-blocks.png) and the exterior wood sheet
(docs/concept/wood-materials.png).

    python3 tools/textures/paint_woods.py [--only=saloon_red,floor] [--sheet=PATH]

What it does that tools/textures/draw_boards.py (production) doesn't:
  - colour from an authored ramp a wood (tools/textures/woods_lab.json), its intrinsic colours dark
    to light from the sheet's swatch, not k-means of the golden-hour painting's lit pixels (which
    baked the sunset in: lamp-lit, the saloon red went hot pink-orange);
  - strokes, not speckle: each row of a board is laid as strokes 3-11 squares long along the grain,
    each a step or two off the board's tone, over a slow lengthwise wave, with a few long dark grain
    lines: the sheet's and masters' squares run in streaks (median run 4.7 along to 2.5 across);
  - detail placed: knots (a dark eye, its ring, the grain bent round it), nails at the stud places by
    the board's edges (a dark head, a lit glint), and on painted wood the paint worn through in clumps
    where boards wear, by their edges and ends, to the bare wood under it.
The board's edges are the member's (texel_grid's edge_shade and edge_lip: a dark seam on one long
edge, a lit lip on the other, on the board's own geometry), so the strip holds only its face.

Writes assets/textures/lab/<wood>_b<k>.png (LENGTH x rows, one board each, seamless along the grain),
<wood>.png (the first boards stacked) and lab.json; with --sheet, a contact sheet (each board and
an 8x close-up). The game reads them only with PixelArt.lab on (tools/material_lab.gd).
"""
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SPEC = os.path.join(ROOT, "tools", "textures", "woods_lab.json")
OUT = os.path.join(ROOT, "assets", "textures", "lab")


def hex_rgb(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], dtype=np.float64) / 255.0


def lum(c):
    return c[..., 0] * 0.2126 + c[..., 1] * 0.7152 + c[..., 2] * 0.0722


def periodic_noise(n, cells, rng):
    """1-D value noise over n texels, seamless (its cells divide n)."""
    pts = rng.random(cells)
    x = np.arange(n) * cells / n
    i = np.floor(x).astype(int)
    t = x - i
    t = t * t * (3 - 2 * t)
    return pts[i % cells] * (1 - t) + pts[(i + 1) % cells] * t


def greyed(c, g):
    """Colours pulled toward their own lightness by g (0 none): the sheet's swatches are more
    saturated than the masters' same woods, which a low warm sun saturates again in the game."""
    return c + (lum(c)[..., None] - c) * g


def paint_board(w, k, rng):
    n, rows = w["length"], w["rows"]
    ramp = len(w["ramp"])
    steps, weights = zip(*w["tones"])
    weights = np.array(weights) / sum(weights)
    base = np.clip(rng.normal(*w["base"]), 1.0, ramp - 2.0)
    # The board's tone along it: a slow wave (one or two swells in its 2 m), the same for every row,
    # so the board reads as one piece of wood that lightens and darkens along its length.
    wave = (periodic_noise(n, 2, rng) + periodic_noise(n, 4, rng) * 0.5 - 0.75) * 2.0 * w["wave"]
    place = np.zeros((rows, n))
    for r in range(rows):
        # Strokes round the strip (seamless): the first starts somewhere random, the last wraps.
        x = int(rng.integers(n))
        done = 0
        prev = 0
        while done < n:
            ln = int(rng.integers(w["stroke"][0], w["stroke"][1] + 1))
            s = int(rng.choice(steps, p=weights))
            # Neighbouring strokes step, not jump: no two in a row two places apart.
            if abs(s - prev) > 2:
                s = prev + np.sign(s - prev) * 2
            prev = s
            for i in range(min(ln, n - done)):
                place[r, (x + i) % n] = base + s
            x += ln
            done += ln
    place += wave[None, :]
    # Long dark grain lines: a row or two of a long run, wandering a row at most.
    for _ in range(int(rng.integers(w["streaks"][0], w["streaks"][1] + 1))):
        r = int(rng.integers(1, rows - 1))
        x0 = int(rng.integers(n))
        ln = int(rng.integers(12, 30))
        for i in range(ln):
            if rng.random() < 0.12:
                r = int(np.clip(r + rng.choice([-1, 1]), 1, rows - 2))
            place[r, (x0 + i) % n] = min(place[r, (x0 + i) % n], base - 1.6)
    idx = np.clip(np.rint(place), 0, ramp - 1).astype(int)
    colours = greyed(np.array([hex_rgb(h) for h in w["ramp"]]), w.get("grey", 0.0))
    img = colours[idx]
    # A knot: a dark eye two squares across, a darker ring of grain round it, lighter squares
    # either side along the grain where the fibres bend round it (the sheet's knots).
    if rng.random() < w["knot"]:
        kx, ky = int(rng.integers(n)), int(rng.integers(1, rows - 1))
        kc = [hex_rgb(h) for h in w["knot_colours"]]
        for dx in range(-4, 5):
            for dy in (-1, 0, 1):
                y = ky + dy
                if not 0 <= y < rows:
                    continue
                x = (kx + dx) % n
                if abs(dx) <= 0 and dy == 0:
                    img[y, x] = kc[0]
                elif abs(dx) <= 1 and abs(dy) <= 1:
                    img[y, x] = kc[1] if (dx, dy) != (0, 0) else kc[0]
                elif abs(dx) <= 3 and dy == 0:
                    img[y, x] = colours[min(ramp - 1, idx[y, x] + 1)]
                elif abs(dx) == 4 and dy != 0:
                    img[y, x] = colours[max(0, idx[y, x] - 1)]
    # Worn paint: clumps of the bare wood under it, mostly where a board wears (its edges and its
    # ends' quarter), each clump strokes along the grain, the bare wood's own tones in it.
    if w.get("wear", 0) > 0 and w.get("under"):
        under = greyed(np.array([hex_rgb(h) for h in w["under"]]), w.get("grey", 0.0) * 0.5)
        field = np.zeros((rows, n))
        edge = np.abs(np.arange(rows) - (rows - 1) / 2.0) / ((rows - 1) / 2.0)
        for _ in range(int(rng.integers(2, 5))):
            cx, cy = rng.integers(n), rng.choice(rows, p=(0.2 + edge) / (0.2 + edge).sum())
            sx, sy = rng.uniform(3, 9), rng.uniform(0.6, 1.6)
            dx = (np.arange(n) - cx + n / 2) % n - n / 2
            field += np.exp(-(dx[None, :] / sx) ** 2 - ((np.arange(rows)[:, None] - cy) / sy) ** 2)
        field += rng.random((rows, n)) * 0.35 + edge[:, None] * 0.25
        cut = np.quantile(field, 1.0 - w["wear"])
        worn = field >= cut
        # Each worn square takes a stroke's tone of the bare wood (runs along the row, not speckle).
        for r in range(rows):
            t = int(rng.integers(len(under)))
            for x in range(n):
                if rng.random() < 0.3:
                    t = int(np.clip(t + rng.choice([-1, 1]), 0, len(under) - 1))
                if worn[r, x]:
                    img[r, x] = under[t]
    # Nails: a board nailed at some of the stud places (not all: the sheet's are few), a square in
    # from one edge, the same edge along the board: a dark head with a lit glint above it.
    nc = [hex_rgb(h) for h in w["nails_colours"]] if "nails_colours" in w else [hex_rgb(h) for h in w["nail"]]
    ny = 1 if rng.random() < 0.5 else rows - 2
    for nx in w["nails"]:
        if rng.random() > w.get("nail_share", 0.45):
            continue
        x = (nx + int(rng.integers(-1, 2))) % n
        img[ny, x] = nc[0]
        if 0 <= ny + 1 < rows and rng.random() < 0.7:
            img[ny + 1, x] = nc[1]
    return img


def lay_round_albedo(boards, albedo):
    """Each wood's boards scaled together so their mean lightness is the production wood's (the
    game's exposure was tuned to it); the ramp's own hues and steps kept."""
    allpx = np.concatenate([b.reshape(-1, 3) for b in boards])
    k = lum(np.array(albedo)) / max(lum(allpx.mean(0)), 1e-4)
    return [np.clip(b * k, 0, 1) for b in boards]


def main():
    args = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    spec = json.load(open(SPEC))
    only = set(args["only"].split(",")) if "only" in args else None
    os.makedirs(OUT, exist_ok=True)
    info = {"texels_per_metre": spec["texels_per_metre"], "length": spec["length"], "woods": {}}
    sheet_rows = []
    for name, w in spec["woods"].items():
        if only and name not in only:
            continue
        # A wood laid coarser or finer than 32 a metre keeps its strip 2 m long (and its nails at the
        # same places along it).
        dens = w.get("texels_per_metre", spec["texels_per_metre"])
        k = dens / spec["texels_per_metre"]
        w = dict(w, length=int(round(spec["length"] * k)), nails=[int(round(x * k)) for x in w["nails"]],
                 stroke=[max(2, int(round(v * k))) for v in w["stroke"]])
        rng = np.random.default_rng(sum(map(ord, name)) * 7919)
        boards = lay_round_albedo([paint_board(w, k, rng) for k in range(w["count"])], w["albedo"])
        for i, b in enumerate(boards):
            Image.fromarray((b * 255 + 0.5).astype(np.uint8)).save(os.path.join(OUT, "%s_b%d.png" % (name, i)))
        stack = np.concatenate(boards[:4], 0)
        Image.fromarray((stack * 255 + 0.5).astype(np.uint8)).save(os.path.join(OUT, "%s.png" % name))
        info["woods"][name] = {"boards": w["count"], "rows": w["rows"], "length": w["length"], "texels_per_metre": dens}
        sheet_rows.append((name, boards))
        print("%-14s %d boards, %dx%d at %g/m" % (name, w["count"], w["length"], w["rows"], dens))
    json.dump(info, open(os.path.join(OUT, "lab.json"), "w"), indent=1)
    if "sheet" in args:
        zoom, pad = 6, 6
        blocks = []
        for name, boards in sheet_rows:
            # The boards stacked as a wall would hold them (a dark line between: the member's seam).
            wall = []
            for b in boards:
                wall.append(b)
                wall.append(np.full((1, b.shape[1], 3), 0.12))
            wall = np.concatenate(wall, 0)
            blocks.append(np.kron(wall, np.ones((zoom, zoom, 1))))
        wmax = sum(b.shape[1] for b in blocks) + pad * (len(blocks) - 1)
        hmax = max(b.shape[0] for b in blocks)
        out = np.ones((hmax, wmax, 3)) * 0.85
        x = 0
        for b in blocks:
            out[:b.shape[0], x:x + b.shape[1]] = b
            x += b.shape[1] + pad
        Image.fromarray((out * 255).astype(np.uint8)).save(args["sheet"])
        print("sheet", args["sheet"])


if __name__ == "__main__":
    main()
