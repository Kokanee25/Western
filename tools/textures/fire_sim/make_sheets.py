"""The flame types' sheets, from their baked simulations (bake_flames.py), and the fire's colours.

    python3 tools/textures/fire_sim/make_sheets.py [--only=lick] [--sim=build/fire_sim] [--preview=DIR]

For each type in flames.json: the projected frames looped (the last `blend` frames cross-faded
into the first, so frame 63 runs on into frame 0), resampled to the type's `squares`, and packed
8 x 8 into two sheets in assets/textures/fire/:

- fire_<type>.png: R the flame (how much fire the eye looks through, 1 - exp(-k x metres), k so
  the core fills), G the smoke's cover (the same, of the smoke), B the heat (for the haze).
- fire_<type>_mv.png: R G the motion, how far each square's fire moves to the next frame, in the
  frame's UV (0.5 still, +-`mv_range` at 0 and 1; y down, as UV is).

The motion is the simulation's own velocity (flame-weighted where there's fire, smoke-weighted
where there's smoke), blurred and spread out past the fire's edge so an edge moves with it, and
scaled to the frames by the scale that best carries each frame onto the next (measured, since
Mantaflow's units aren't the picture's). The idea is the motion-vector flipbook of games' VFX
(described in Guerrilla's and SideFX's talks on flipbook blending): two frames each pushed along
their vectors toward the moment between them and mixed.

And fire_ramp.png: the fire painting's colours (docs/concept/livery-fire-painted.png) from its
reds at the flames' edges to its near-white at their roots, by brightness, for the shader to band
the flame by (the painted push; the final painted pass waits for Gate A). fire_sheets.json has
each type's size in metres, its motion range and fps for the shader and FireFX.
"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(ROOT, "assets", "textures", "fire")
PAINTING = os.path.join(ROOT, "docs", "concept", "livery-fire-painted.png")


def loop(a, n, k):
    """Frames 0..n+k-1 into n frames that loop: the tail's last k cross-faded into the head."""
    out = a[:n].copy()
    for j in range(k):
        w = j / float(k)
        out[j] = a[j + n] * (1.0 - w) + a[j] * w
    return out


def resample(img, w, h):
    """[z up, x] floats to [row down, col] at w x h, by area."""
    im = Image.fromarray(np.flipud(img).astype(np.float32), mode="F")
    return np.asarray(im.resize((w, h), Image.BOX), dtype=np.float32)


def window(w, h, top=0.2, side=0.12):
    """1 inside the frame, fading to 0 over its top `top` and each side's `side` (a share of it):
    a flame that leaves the simulation's domain ends in a fade, not a cut."""
    y = np.linspace(0.0, 1.0, h, dtype=np.float32)[:, None]  # 0 at the top
    x = np.linspace(0.0, 1.0, w, dtype=np.float32)[None, :]
    ty = np.clip(y / top, 0.0, 1.0)
    tx = np.clip(np.minimum(x, 1.0 - x) / side, 0.0, 1.0)
    return (ty * ty * (3.0 - 2.0 * ty)) * (tx * tx * (3.0 - 2.0 * tx))


def cover(metres, k):
    return 1.0 - np.exp(-metres * k)


def spread(vel, weight, sigma):
    """Velocity blurred by its weight and carried past where the weight ends (normalised blur)."""
    out = np.empty_like(vel)
    wb = ndimage.gaussian_filter(weight, sigma) + 1e-4
    wide = ndimage.gaussian_filter(weight, sigma * 3.0) + 1e-4
    for c in range(2):
        near = ndimage.gaussian_filter(vel[..., c] * weight, sigma) / wb
        far = ndimage.gaussian_filter(vel[..., c] * weight, sigma * 3.0) / wide
        t = np.clip(wb / (wb.max() * 0.05 + 1e-6), 0.0, 1.0)
        out[..., c] = near * t + far * (1.0 - t)
    return out


def warp(img, mv):
    """The frame pushed along its motion (mv in pixels, x right, y down), sampled back."""
    h, w = img.shape
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    return ndimage.map_coordinates(img, [yy - mv[..., 1], xx - mv[..., 0]], order=1, mode="constant")


def best_scale(r, mv):
    """The scale on the simulation's velocity that best carries each frame onto the next: tried
    from a hundredth to ten times a first guess (log steps), then refined round the best."""
    def err(s):
        return sum(float(np.mean((warp(r[i], mv[i] * s) - r[i + 1]) ** 2)) for i in range(0, len(r) - 1, 4))
    guess = best_guess(r, mv)
    tried = [(err(0.0), 0.0)] + [(err(s), s) for s in guess * np.logspace(-2, 1, 16)]
    best = min(tried)[1]
    if best > 0.0:
        tried += [(err(s), s) for s in best * np.linspace(0.75, 1.3, 12)]
    return min(tried)[1]


def best_guess(r, mv):
    """A first scale: the fire's mean rise a frame (its centre of brightness) over the vectors'."""
    rows = np.arange(r.shape[1], dtype=np.float32)[:, None]
    up = []
    for i in range(len(r) - 1):
        a, b = r[i], r[i + 1]
        ca = (a * rows).sum() / (a.sum() + 1e-6)
        cb = (b * rows).sum() / (b.sum() + 1e-6)
        up.append(abs(cb - ca))
    v = np.abs(mv[..., 1]).mean() + 1e-6
    return max(np.mean(up) * 6.0 / v, 1e-4)


def extent(z, cell):
    """The part of the domain the flame uses (in 2% of its frames or more): from the floor to its
    highest tips and a little over (the smoke above is the smoke field's to draw), and as far
    either side of the middle as it reaches (in cells), so few squares are wasted."""
    fl = z["flame"]
    used = fl > np.percentile(fl[fl > 0], 50) * 0.05
    any_ = used.mean(axis=0) > 0.02
    rows = np.nonzero(any_.any(axis=1))[0]
    cols = np.nonzero(any_.any(axis=0))[0]
    mid = (any_.shape[1] - 1) * 0.5
    half = int(np.ceil(max(mid - cols.min(), cols.max() - mid))) + 1
    top = min(int(rows.max() * 1.12) + 2, any_.shape[0])
    lo, hi = max(int(round(mid - half)), 0), min(int(round(mid + half)) + 1, any_.shape[1])
    return top, lo, hi


def sheet(kind, spec, cfg, sim):
    z = np.load(os.path.join(sim, kind + ".npz"))
    n, k = cfg["frames"], spec["blend"]
    cell = float(z["cell"])
    top, lo, hi = extent(z, cell)
    # The frame's squares: its height as asked, its width from the part it uses (even, at most asked).
    w_max, h = spec["squares"]
    w = int(min(w_max, max(8, 2 * round(h * (hi - lo) / top / 2.0))))
    def rs(a):
        return resample(a[:top, lo:hi], w, h)
    fl = np.stack([rs(f) for f in z["flame"]])
    sm = np.stack([rs(f) for f in z["smoke"]])
    ht = np.stack([rs(f) for f in z["heat"]])
    fv = np.stack([np.dstack([rs(v[..., 0]), -rs(v[..., 1])]) for v in z["flame_vel"]])
    sv = np.stack([np.dstack([rs(v[..., 0]), -rs(v[..., 1])]) for v in z["smoke_vel"]])
    # Cover scaled so the fire's thick middle (its 90th percentile of metres) is well into the
    # core but not all of it solid: the core's bands then run from the roots out.
    kf = 1.4 / max(np.percentile(fl[fl > 1e-4], 90), 1e-6)
    ks = 1.2 / max(np.percentile(sm[sm > 1e-4], 99), 1e-6) if (sm > 1e-4).any() else 1.0
    win = window(w, h, top=0.25, side=0.28)
    # The flame smoothed a square or so before it's banded: the painting's fire is a few big shapes,
    # and banding the simulation's fine grain drew speckle.
    smooth = np.stack([ndimage.gaussian_filter(f, spec.get("smooth", 1.2)) for f in fl])
    r = cover(smooth, kf) * win
    # The smoke's thin haze everywhere in the domain left out (it drew the quad's edges).
    g = np.clip((cover(sm, ks) - 0.12) / 0.88, 0.0, 1.0) * win
    b = np.clip(ht / max(np.percentile(ht[ht > 1e-4], 98), 1e-6), 0.0, 1.0) * win
    weight_f = r
    weight_s = g
    mv = np.empty(fv.shape, dtype=np.float32)
    for i in range(len(fv)):
        a = spread(fv[i], weight_f[i] + 1e-3, 1.0)
        s = spread(sv[i], weight_s[i] + 1e-3, 1.5)
        t = np.clip(weight_f[i] * 4.0, 0.0, 1.0)[..., None]
        mv[i] = a * t + s * (1.0 - t)
    # Fitted on the flame as simulated (the smoothing would hide how it moves).
    scale = best_scale(cover(fl, kf) * win, mv)
    mv *= scale
    r, g, b = loop(r, n, k), loop(g, n, k), loop(b, n, k)
    mv = loop(mv, n, k)
    # The loop's seam, measured: how much frame 63 carried on misses frame 0, beside a frame's.
    seam = float(np.mean((warp(r[-1], mv[-1]) - r[0]) ** 2))
    step = float(np.mean([np.mean((warp(r[i], mv[i]) - r[i + 1]) ** 2) for i in range(n - 1)]))
    # Motion in UV a frame, x and y each against the frame's own size.
    uv = mv / np.array([w, h], dtype=np.float32)
    rng = float(np.ceil(np.percentile(np.abs(uv), 99.5) * 200.0) / 200.0) or 0.005
    cols, rows = cfg["grid"]
    colour = np.zeros((rows * h, cols * w, 3), dtype=np.uint8)
    motion = np.zeros((rows * h, cols * w, 3), dtype=np.uint8)
    for i in range(n):
        y0, x0 = (i // cols) * h, (i % cols) * w
        colour[y0:y0 + h, x0:x0 + w] = (np.dstack([r[i], g[i], b[i]]).clip(0, 1) * 255.0 + 0.5).astype(np.uint8)
        m = np.clip(uv[i] / (2.0 * rng) + 0.5, 0.0, 1.0)
        motion[y0:y0 + h, x0:x0 + w, :2] = (m * 255.0 + 0.5).astype(np.uint8)
    Image.fromarray(colour).save(os.path.join(OUT, "fire_%s.png" % kind), optimize=True)
    Image.fromarray(motion).save(os.path.join(OUT, "fire_%s_mv.png" % kind), optimize=True)
    sx, sz = (hi - lo) * cell, top * cell
    print("%s: %dx%d squares (%.2f x %.2f m), %d frames; flame k %.1f, smoke k %.1f; motion x%.4f, range %.3f UV;"
          " seam %.5f against a step's %.5f" % (kind, w, h, sx, sz, n, kf, ks, scale, rng, seam, step))
    return {"size": [round(sx, 3), round(sz, 3)], "squares": [w, h], "mv_range": rng, "fps": cfg["fps"], "frames": n,
            "grid": cfg["grid"], "seam_error": round(seam, 6), "step_error": round(step, 6)}


def tones(px, k, seed=7, steps=25):
    """The painting's k tones among these pixels (k-medians: means of flame colours dulled them), darkest first."""
    rng = np.random.default_rng(seed)
    lum = px @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    centres = px[np.argsort(lum)][np.linspace(0, len(px) - 1, k).astype(int)].copy()
    sample = px[rng.choice(len(px), min(len(px), 40000), replace=False)]
    for _ in range(steps):
        near = np.argmin(((sample[:, None, :] - centres[None]) ** 2).sum(-1), axis=1)
        for i in range(k):
            if (near == i).any():
                centres[i] = np.median(sample[near == i], axis=0)
    return centres[np.argsort(centres @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32))]


def ramp():
    """The painting's fire, edge to root: its fire's tones (the flames' clean colours, not the
    smoke-dulled ones), darkest to brightest, each an equal span of 256 steps, softened a little
    where they meet."""
    im = np.asarray(Image.open(PAINTING).convert("RGB"), dtype=np.float32)
    h, w, _ = im.shape
    # The burning livery (the painting's middle right, under the smoke).
    crop = im[int(h * 0.06):int(h * 0.56), int(w * 0.46):int(w * 0.86)].reshape(-1, 3)
    r, g, b = crop[:, 0], crop[:, 1], crop[:, 2]
    fire = crop[(r > 150) & (r >= g) & (g >= b) & ((r - b) > 0.62 * r) | ((r > 235) & (g > 190))]
    centres = tones(fire, 8)
    # The clean tones only (the browns of flame dulled by smoke, bluer than a quarter of their red
    # and darker than the oranges, left out), and the painting's brightest (its top half percent)
    # as the root's near-white.
    lum_c = centres @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    clean = ~((centres[:, 2] > 0.25 * centres[:, 0]) & (lum_c < 150.0))
    lum = fire @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    root = fire[lum >= np.percentile(lum, 99.5)].mean(axis=0)
    centres = np.vstack([centres[clean], root[None]])
    steps = np.repeat(centres, int(np.ceil(256 / len(centres))), axis=0)[:256]
    steps = ndimage.uniform_filter1d(steps, 11, axis=0, mode="nearest")
    img = np.clip(steps, 0, 255).astype(np.uint8)[None, :, :]
    Image.fromarray(np.repeat(img, 4, axis=0)).save(os.path.join(OUT, "fire_ramp.png"))
    # The smoke over it: its darkest heaps and the underside the fire lights.
    plume = im[0:int(h * 0.2), int(w * 0.46):int(w * 0.80)].reshape(-1, 3)
    pl = plume @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    dark = np.median(plume[pl < np.percentile(pl, 30)], axis=0)
    lit = np.median(plume[(pl > np.percentile(pl, 60)) & (plume[:, 0] > plume[:, 2])], axis=0)
    print("ramp: %d fire pixels, tones %s; smoke dark %s, lit %s" % (
        len(fire), centres.astype(int).tolist(), dark.astype(int), lit.astype(int)))
    return {"smoke_dark": [round(float(c) / 255.0, 3) for c in dark],
            "smoke_lit": [round(float(c) / 255.0, 3) for c in lit]}


def main():
    args = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    cfg = json.load(open(os.path.join(HERE, "flames.json")))
    sim = os.path.join(ROOT, args.get("sim", "build/fire_sim"))
    os.makedirs(OUT, exist_ok=True)
    meta_path = os.path.join(OUT, "fire_sheets.json")
    meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {"types": {}}
    meta["_doc"] = "Written by tools/textures/fire_sim/make_sheets.py: each flame type's sheet, its size in metres (across, up), squares a frame, motion range (UV a frame) and fps; the painting's smoke colours."
    meta.update(ramp())
    only = args.get("only", "").split(",") if args.get("only") else list(cfg["types"])
    for kind in only:
        if os.path.exists(os.path.join(sim, kind + ".npz")):
            meta["types"][kind] = sheet(kind, cfg["types"][kind], cfg, sim)
    json.dump(meta, open(meta_path, "w"), indent=1, sort_keys=True)
    if args.get("preview"):
        preview(args["preview"], list(meta["types"]))


def preview(out, kinds):
    """Every type's first frame and every eighth, through the ramp, for a look."""
    os.makedirs(out, exist_ok=True)
    rp = np.asarray(Image.open(os.path.join(OUT, "fire_ramp.png")).convert("RGB"))[0]
    for kind in kinds:
        im = np.asarray(Image.open(os.path.join(OUT, "fire_%s.png" % kind)), dtype=np.float32) / 255.0
        meta = json.load(open(os.path.join(OUT, "fire_sheets.json")))["types"][kind]
        w, h = meta["squares"]
        tiles = []
        for i in range(0, 64, 8):
            y0, x0 = (i // 8) * h, (i % 8) * w
            t = im[y0:y0 + h, x0:x0 + w]
            f = t[..., 0]
            c = rp[np.clip((f * 255).astype(int), 0, 255)].astype(np.float32)
            bg = np.array([40, 30, 45], dtype=np.float32)
            smoke = np.array([45, 35, 30], dtype=np.float32)
            a = np.clip((f - 0.08) * 6.0, 0, 1)[..., None]
            base = bg * (1 - t[..., 1:2] * 0.9) + smoke * t[..., 1:2] * 0.9
            tiles.append(base * (1 - a) + c * a)
        strip = np.concatenate(tiles, 1).clip(0, 255).astype(np.uint8)
        Image.fromarray(strip).resize((strip.shape[1] * 3, strip.shape[0] * 3), Image.NEAREST).save(
            os.path.join(out, "preview_%s.png" % kind))


if __name__ == "__main__":
    main()
