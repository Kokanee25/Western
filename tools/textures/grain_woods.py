#!/usr/bin/env python3
"""The material lab's second woods (art, 2026-10-14; Sean's reference pack, docs/concept/material_pack/,
brief docs/briefs/material-lab-timber.md): timber, planks and painted siding as coherent pieces of
wood with grain along their length, for the grounded-3D direction (the approved saloon exterior),
not squares.

    python3 tools/textures/grain_woods.py [--set=lab3] [--only=timber,floor] [--sheet=PATH]

--set: which spec and output, tools/textures/woods_<set>.json -> assets/textures/<set>/ (lab2, the
timber pass, by default; lab3 its finish: weathered timber, localised paint wear, the rim board).

Each board strip (2 m along the grain at the wood's texels a metre, `rows` across, seamless along it):
  - one colour a piece: the board's place on its ramp, a little off its neighbours';
  - large soft patches of tone along the length, stepped into a few flat tones (the characters'
    painted facets, not per-texel noise), never a stripe board to board;
  - fine grain lines along the length, wandering and bending round knots;
  - knots (a dark eye, the grain deflected round it), checks (dark splits along the grain), faint
    saw marks across it, the long edges a shade lighter where they wear;
  - painted wood: the paint one colour with faint grain under it, worn to the bare wood under it in
    ragged clumps where paint wears: the board's exposed lower edge and round its nails.
And a wood's end grain (`<wood>_end.png`): growth bands as broad arcs from a pith below the face
(a flat-sawn board's end), darker than the long grain (end grain soaks up weather), cut fibres,
a rare check from the pith outward.

Writes assets/textures/lab2/<wood>_b<k>.png, <wood>_end.png, <wood>.png (boards stacked) and
lab.json. The game reads them only with PixelArt.lab_set = "lab2" (tools/material_lab.gd --lab2).
Deterministic: each wood's `seed` in tools/textures/woods_lab2.json.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "textures", "lab2")


def hex_rgb(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], dtype=np.float64) / 255.0


def ramp_at(ramp, t):
    """Colours along a ramp at fractional places t (clamped), linearly between its entries."""
    t = np.clip(t, 0.0, len(ramp) - 1.001)
    i = np.floor(t).astype(int)
    f = (t - i)[..., None]
    return ramp[i] * (1 - f) + ramp[i + 1] * f


def noise2(w, h, cx, cy, rng):
    """2-D value noise, w x h, cx cells across w (seamless along it), cy cells down h."""
    cx, cy = max(1, int(cx)), max(1, int(cy))
    pts = rng.random((cy + 2, cx))
    x = np.arange(w) * cx / w
    y = np.arange(h) * cy / h
    xi, yi = np.floor(x).astype(int), np.floor(y).astype(int)
    tx, ty = x - xi, y - yi
    tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
    a = pts[yi[:, None], xi[None, :] % cx]
    b = pts[yi[:, None], (xi[None, :] + 1) % cx]
    c = pts[yi[:, None] + 1, xi[None, :] % cx]
    d = pts[yi[:, None] + 1, (xi[None, :] + 1) % cx]
    top = a * (1 - tx) + b * tx
    bot = c * (1 - tx) + d * tx
    return top * (1 - ty[:, None]) + bot * ty[:, None]


def fbm2(w, h, cx, cy, rng, octaves=3):
    out, amp, tot = np.zeros((h, w)), 1.0, 0.0
    for o in range(octaves):
        out += noise2(w, h, cx * 2 ** o, cy * 2 ** o, rng) * amp
        tot += amp
        amp *= 0.5
    return out / tot


def board(w, spec, n, rows, dens, rng):
    ramp = np.array([hex_rgb(h) for h in spec["ramp"]])
    x_m = np.arange(n) / dens
    y_m = np.arange(rows) / dens
    base = np.clip(rng.normal(*spec["base"]), 0.8, len(ramp) - 1.8)
    # Large soft patches along the board, stepped into a few flat tones.
    amt, plen, pwid = spec["patch"]
    p = fbm2(n, rows, round(2.0 / plen), max(1, rows / dens / pwid), rng)
    p = (p - p.min()) / max(p.max() - p.min(), 1e-6)
    lv = spec["levels"]
    p = (np.floor(p * lv) + 0.5) / lv
    t = base + (p - 0.5) * 2.0 * amt
    # Grain lines: a phase across the board, wandering slowly along it and bent round a knot.
    g_amt, spacing, wander = spec["grain"]
    wav = (noise2(n, 1, round(2.0 / 0.25), 1, rng)[0] - 0.5) * 2.0 * wander
    yy = y_m[:, None] + wav[None, :]
    knots = []
    # `knots` [min, max] a board (lab3), else `knot` [chance, size] for one.
    nk = int(rng.integers(spec["knots"][0], spec["knots"][1] + 1)) if "knots" in spec else int(rng.random() < spec["knot"][0])
    for _ in range(nk):
        s = spec["knot"][1] * rng.uniform(0.7, 1.3)
        kx, ky = rng.uniform(0, n / dens), rng.uniform(0.3, 0.7) * rows / dens
        dx = (x_m[None, :] - kx + 1.0) % 2.0 - 1.0
        dy = y_m[:, None] - ky
        yy = yy + np.sign(dy + 1e-6) * s * 1.6 * np.exp(-(dx / (s * 3.0)) ** 2 - (dy / (s * 1.8)) ** 2)
        knots.append((dx, dy, s))
    phase = yy / spacing + rng.random()
    d = np.abs((phase % 1.0) - 0.5) * 2.0
    fade = noise2(n, rows, round(2.0 / 0.3), 2, rng)
    line = np.clip((d - 0.8) / 0.2, 0, 1) * np.clip(fade * 1.6 - 0.3, 0, 1)
    t = t - line * g_amt
    # Saw marks: faint bands across the grain; lab3's (`saw_patchy`) in patches and unevenly
    # spaced, as a mill's sash saw left them, not an even ripple.
    s_amt, s_sp = spec["saw"]
    if s_amt > 0:
        ph = x_m[None, :] / s_sp + y_m[:, None] * 3.0
        if spec.get("saw_patchy"):
            ph = ph + noise2(n, 1, round(2.0 / 0.3), 1, rng)[0][None, :] * 2.5
            s_amt = s_amt * np.clip(noise2(n, rows, round(2.0 / 0.4), 1, rng) * 2.2 - 0.6, 0, 1)
        t = t + np.sin(2 * np.pi * ph) * 0.5 * s_amt
    # Weathering (lab3): long streaks down the grain where water runs and the wood greys and
    # darkens, stepped like the patches.
    if "weather" in spec:
        w_amt, w_wid, w_len = spec["weather"]
        st = noise2(n, rows, round(2.0 / w_len), max(1, rows / dens / w_wid), rng)
        st = np.clip((st - 0.55) / 0.3, 0, 1)
        t = t - (np.floor(st * 3) / 3) * w_amt
    # The worn long edges a shade lighter.
    e = np.zeros(rows)
    e[:2] = e[-2:] = spec["edge"]
    t = t + e[:, None] * 0.5
    # Splash (lab3 `stain` [amount, height share]): darker toward the board's lower edge (row 0),
    # raggedly, where rain splashes up and dirt sticks.
    if "stain" in spec:
        st_amt, st_h = spec["stain"]
        rg = noise2(n, rows, round(2.0 / 0.15), 2, rng)
        t = t - st_amt * np.clip(np.exp(-np.arange(rows) / (rows * st_h))[:, None] * (0.4 + rg * 1.2) - 0.25, 0, 1)
    img = ramp_at(ramp, t)
    # Greyed where the sun has bleached it (lab3 `grey` [amount, patch m]): towards its own grey.
    if "grey" in spec:
        g_amt, g_len = spec["grey"]
        gm = noise2(n, rows, round(2.0 / g_len), 1, rng)
        gm = np.floor(np.clip((gm - 0.4) / 0.4, 0, 1) * 3) / 3 * g_amt
        lum = (img @ np.array([0.3, 0.59, 0.11]))[..., None]
        img = img * (1 - gm[..., None]) + (lum * np.array([1.0, 0.98, 0.95])) * gm[..., None]
    # Paint worn through: ragged clumps by the lower (exposed) edge and round the nails.
    if spec.get("paint"):
        under = np.array([hex_rgb(h) for h in spec["under"]])
        w_amt, w_edge, w_nail = spec["wear"]
        rag = fbm2(n, rows, round(2.0 / 0.08), max(1, rows / dens / 0.02), rng)
        if spec.get("wear_local"):
            # lab3: no edge strip. The lap edge wears only in a few short broken runs, the nails
            # some of them, and a patch or two flakes off along the grain on some boards; most
            # of the board's paint whole.
            runs = np.clip((noise2(n, 1, round(2.0 / 0.35), 1, rng)[0] - 0.62) / 0.2, 0, 1)
            m = np.exp(-np.arange(rows) / (rows * 0.1))[:, None] * w_edge * runs[None, :]
            for nx in spec["nails"]:
                if rng.random() > 0.55:
                    continue
                dx = (x_m[None, :] - nx + 1.0) % 2.0 - 1.0
                for ny in (0.25, 0.75):
                    dy = y_m[:, None] - ny * rows / dens
                    m = m + w_nail * rng.uniform(0.5, 1.2) * np.exp(-(dx / 0.03) ** 2 - (dy / 0.018) ** 2)
            fl = spec.get("flakes", [0, 2])
            for _ in range(int(rng.integers(fl[0], fl[1] + 1))):
                fx, fy = rng.uniform(0, n / dens), rng.uniform(0.2, 0.8) * rows / dens
                dx = (x_m[None, :] - fx + 1.0) % 2.0 - 1.0
                dy = y_m[:, None] - fy
                m = m + 0.9 * np.exp(-(dx / rng.uniform(0.04, 0.12)) ** 2 - (dy / 0.02) ** 2)
            m = m * (0.3 + rag * 1.4)
            worn = m > 0.55 * (1.0 - w_amt)
        else:
            m = np.exp(-np.arange(rows) / (rows * 0.12))[:, None] * w_edge * np.ones((1, n))
            for nx in spec["nails"]:
                dx = (x_m[None, :] - nx + 1.0) % 2.0 - 1.0
                for ny in (0.25, 0.75):
                    dy = y_m[:, None] - ny * rows / dens
                    m = m + w_nail * np.exp(-(dx / 0.025) ** 2 - (dy / 0.02) ** 2)
            # Ragged: the noise decides most of it, so a worn edge breaks into clumps, not a line.
            m = m * (0.15 + rag * 1.7) + rag * 0.25
            worn = m > np.quantile(m, 1.0 - w_amt)
        ut = 1.5 + (p - 0.5) * 2.0 - line * 0.8
        img = np.where(worn[..., None], ramp_at(under, ut), img)
        # Nail heads: dark, a glint above.
        for nx in spec["nails"]:
            xi = int(round(nx * dens)) % n
            for ny in (0.25, 0.75):
                yi = int(round(ny * rows))
                img[yi, xi] = hex_rgb("#2a221e")
                if yi + 1 < rows:
                    img[yi + 1, xi] = hex_rgb("#6d625a")
    # Checks: dark splits along the grain, tapering; lab3's (`check_lip`) with the split's lower
    # edge a shade lighter, a lifted lip catching the light.
    lo, hi = spec["checks"][0]
    lip = spec.get("check_lip", 0.0)
    for _ in range(int(rng.integers(lo, hi + 1))):
        ln = rng.uniform(*spec["checks"][1]) * dens
        x0, y0 = rng.uniform(0, n), rng.uniform(0.2, 0.8) * rows
        for i in range(int(ln)):
            if rng.random() < 0.06:
                y0 += rng.choice([-1, 1])
            yi = int(np.clip(y0, 1, rows - 2))
            k = 0.55 + 0.45 * np.sin(np.pi * i / max(ln, 1))
            xi = int(x0 + i) % n
            img[yi, xi] = img[yi, xi] * (1 - 0.55 * k)
            if lip > 0:
                img[yi - 1, xi] = np.clip(img[yi - 1, xi] * (1 + lip * k), 0, 1)
    # The knots' eyes: dark, a ring a shade lighter round each.
    for knot in knots:
        dx, dy, s = knot
        r = np.sqrt((dx / (s * 1.3)) ** 2 + (dy / s) ** 2)
        img = np.where((r < 0.55)[..., None], ramp[0] * 0.75, img)
        img = np.where(((r >= 0.55) & (r < 0.9))[..., None], img * 0.82, img)
    return np.clip(img, 0, 1)


def end_grain(spec, dens, rng, size=32):
    ramp = np.array([hex_rgb(h) for h in spec["end"]])
    y, x = np.mgrid[0:size, 0:size] / dens
    cx = rng.uniform(0.2, 0.8) * size / dens
    pith = rng.uniform(*spec["pith"])
    r = np.sqrt((x - cx) ** 2 + (y + pith) ** 2)
    spacing, amt = spec["rings"]
    # Growth bands: broad arcs, the late wood of each year a little darker; not hard rings.
    bands = 0.5 + 0.5 * np.sin(2 * np.pi * r / spacing + noise2(size, size, 3, 3, rng) * 2.0)
    fv = spec.get("fibres", 0.35)
    fib = rng.random((size, size)) * fv
    t = 1.6 + (bands - 0.5) * 2.0 * amt + (fib - (fv * 0.5 if "fibres" in spec else 0.17)) + (noise2(size, size, 2, 2, rng) - 0.5) * 0.8
    # lab3 `end_rim`: the cut end's outer texels darker (the arris dirtied and weathered), so the
    # end reads as a cut face with an edge, not a decal.
    if spec.get("end_rim"):
        rim = np.zeros((size, size))
        rim[0, :] = rim[-1, :] = rim[:, 0] = rim[:, -1] = 1.0
        t = t - rim * spec["end_rim"]
    img = ramp_at(ramp, t)
    # A check: a dark split running outward from the pith.
    if rng.random() < spec["end_checks"]:
        ang = np.arctan2(-(y + pith), x - cx)
        a0 = np.arctan2(-(size / dens * rng.uniform(0.3, 0.9) + pith), rng.uniform(0, size / dens) - cx)
        crack = (np.abs(ang - a0) < 0.012 * (1 + r * 8)) & (r < pith + size / dens * rng.uniform(0.4, 0.9))
        img = np.where(crack[..., None], ramp[0] * 0.6, img)
    return np.clip(img, 0, 1)


def save(arr, path):
    Image.fromarray((arr * 255 + 0.5).astype(np.uint8)).save(path)


def main():
    args = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    global OUT
    lab_set = args.get("set", "lab2")
    spec = json.load(open(os.path.join(ROOT, "tools", "textures", "woods_%s.json" % lab_set)))
    OUT = os.path.join(ROOT, "assets", "textures", lab_set)
    only = set(args["only"].split(",")) if "only" in args else None
    os.makedirs(OUT, exist_ok=True)
    # Merged into what's there: painting some woods (--only) keeps the others listed.
    lj = os.path.join(OUT, "lab.json")
    info = json.load(open(lj)) if os.path.exists(lj) else {"woods": {}}
    sheet = []
    for name, w in spec["woods"].items():
        if only and name not in only:
            continue
        rng = np.random.default_rng(w["seed"])
        dens, rows = w["texels_per_metre"], w["rows"]
        n = int(round(spec["length_m"] * dens))
        boards = [board(None, w, n, rows, dens, rng) for _ in range(w["count"])]
        for i, b in enumerate(boards):
            save(b, os.path.join(OUT, "%s_b%d.png" % (name, i)))
        save(np.concatenate(boards[:4], 0), os.path.join(OUT, "%s.png" % name))
        end = end_grain(w, dens, rng)
        save(end, os.path.join(OUT, "%s_end.png" % name))
        info["woods"][name] = {"boards": w["count"], "rows": rows, "length": n, "texels_per_metre": dens,
                               "end": "%s_end.png" % name}
        # A painted wood's bare wood (lab3 `end_wear`: the shader wears the paint to it near each
        # board's ends): one board of its `under` ramp, grain and all.
        if w.get("end_wear"):
            bare = dict(w, ramp=w["under"] + w["under"][-1:] * 3, paint=False, base=[2.0, 0.3], knots=[0, 0],
                        checks=[[0, 1], w["checks"][1]])
            save(board(None, bare, n, rows, dens, rng), os.path.join(OUT, "%s_bare.png" % name))
            info["woods"][name]["end_wear"] = w["end_wear"]
        sheet.append((name, boards, end))
        print("%-14s %d boards %dx%d at %d/m (a texel %.1f mm), end %dx%d" % (
            name, w["count"], n, rows, dens, 1000.0 / dens, end.shape[1], end.shape[0]))
    json.dump(info, open(os.path.join(OUT, "lab.json"), "w"), indent=1)
    if "sheet" in args:
        blocks = []
        for name, boards, end in sheet:
            wall = np.concatenate([np.concatenate([b, np.full((2, b.shape[1], 3), 0.1)], 0) for b in boards[:6]], 0)
            wall = np.kron(wall[:, :160], np.ones((3, 3, 1)))
            e = np.kron(end, np.ones((6, 6, 1)))
            col = np.ones((max(wall.shape[0], e.shape[0]), wall.shape[1] + e.shape[1] + 8, 3)) * 0.85
            col[:wall.shape[0], :wall.shape[1]] = wall
            col[:e.shape[0], wall.shape[1] + 8:] = e
            blocks.append(col)
        wmax = max(b.shape[1] for b in blocks)
        out = np.ones((sum(b.shape[0] + 8 for b in blocks), wmax, 3)) * 0.85
        y = 0
        for b in blocks:
            out[y:y + b.shape[0], :b.shape[1]] = b
            y += b.shape[0] + 8
        save(out, args["sheet"])
        print("sheet", args["sheet"])


if __name__ == "__main__":
    main()
