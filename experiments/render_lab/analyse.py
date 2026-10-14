#!/usr/bin/env python3
"""The render lab's measures (experiments/render_lab/README.md).

  analyse.py light DIR [DIR2 ...]     what the light does to the paint, per shot and in sum
  analyse.py paint IMAGE BOX [IMAGE BOX ...]   the same contrast measures on any picture's region
  analyse.py motion DIR [DIR2 ...]    shimmer in the lab's camera paths (DIR/motion/<path>/*.png)
  analyse.py sheet OUT.png LABEL=DIR ... --shots=a,b [--crop=x,y,w,h] [--painting=FILE]
                                      side-by-side boards

`light` pairs each lab frame X.png with X__paint.png (the paint probe: every surface's own colour,
unlit, no grade; lab.gd --probe) and measures, over the pixels that show a surface:
  ratio      the frame's luminance over the paint's (median, 90th percentile): how much brighter
             than painted the light makes things
  clipped    the share of pixels with a channel at 250 or more
  hue        mean OKLab hue turn (degrees) between paint and frame, over coloured pixels: how far
             the light's colour drags every material toward its own
  chroma     the frame's OKLab chroma over the paint's (median)
  keep       the painted detail that survives: the spread of the fine detail in log luminance
             (each pixel against a 9 px box mean round it) in the frame over the same in the
             paint. A pure light multiplies the paint and keeps it all (1.0); a shoulder or a
             clip squeezes it (< 1); light stepping square by square adds some (> 1)
  matkeep    the hue differences between materials that survive: the spread of OKLab a,b over
             the frame against the paint's (1.0: as painted)
The paintings have no paint under them, so `paint` gives their own fine detail and chroma over a
region, to set beside the frame's.
"""
import glob
import json
import os
import sys

import numpy as np
from PIL import Image


def load(p):
    return np.asarray(Image.open(p).convert("RGB"), dtype=np.float64) / 255.0


def to_linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def oklab(rgb):
    lin = to_linear(rgb)
    m1 = np.array([[0.4122214708, 0.5363325363, 0.0514459929],
                   [0.2119034982, 0.6806995451, 0.1073969566],
                   [0.0883024619, 0.2817188376, 0.6299787005]])
    lms = np.cbrt(lin @ m1.T)
    m2 = np.array([[0.2104542553, 0.7936177850, -0.0040720468],
                   [1.9779984951, -2.4285922050, 0.4505937099],
                   [0.0259040371, 0.7827717662, -0.8086757660]])
    return lms @ m2.T


def lum(rgb):
    return to_linear(rgb) @ np.array([0.2126, 0.7152, 0.0722])


def box_mean(a, r=4):
    """Mean over a (2r+1) square round each pixel (edges clamped), by summed-area table."""
    p = np.pad(a, r + 1, mode="edge")
    s = p.cumsum(0).cumsum(1)
    k = 2 * r + 1
    tot = s[k:, k:] - s[:-k, k:] - s[k:, :-k] + s[:-k, :-k]
    return tot[: a.shape[0], : a.shape[1]] / (k * k)


def detail(rgb, mask=None):
    """Fine detail: log luminance against its 9 px box mean."""
    ll = np.log(lum(rgb) + 1e-3)
    return ll - box_mean(ll)


def light_measures(frame, paint):
    f, p = load(frame), load(paint)
    mask = (p.max(axis=2) > 8 / 255.0)
    # Keep away from silhouettes (the detail measure would count an edge as detail).
    edge = np.abs(box_mean(mask.astype(float), 2) - 1.0) > 1e-6
    inner = mask & ~edge
    if inner.sum() < 500:
        return None
    lf, lp = lum(f), lum(p)
    ratio = lf[inner] / np.maximum(lp[inner], 1e-3)
    clipped = (f[inner].max(axis=1) >= 250 / 255.0).mean()
    of, op = oklab(f), oklab(p)
    cf = np.hypot(of[..., 1], of[..., 2])
    cp = np.hypot(op[..., 1], op[..., 2])
    col = inner & (cp > 0.03) & (cf > 0.02)
    hf = np.degrees(np.arctan2(of[..., 2], of[..., 1]))
    hp = np.degrees(np.arctan2(op[..., 2], op[..., 1]))
    dh = np.abs((hf - hp + 180) % 360 - 180)
    df, dp = detail(f), detail(p)
    keep = df[inner].std() / max(dp[inner].std(), 1e-6)
    ab_f = of[..., 1:][inner]
    ab_p = op[..., 1:][inner]
    matkeep = np.sqrt(ab_f.var(axis=0).sum()) / max(np.sqrt(ab_p.var(axis=0).sum()), 1e-6)
    return {
        "ratio_median": float(np.median(ratio)), "ratio_p90": float(np.percentile(ratio, 90)),
        "clipped": float(clipped), "hue_turn": float(dh[col].mean()) if col.any() else 0.0,
        "chroma": float(np.median(cf[col] / np.maximum(cp[col], 1e-4))) if col.any() else 1.0,
        "keep": float(keep), "matkeep": float(matkeep), "lstar_median": float(np.median(of[..., 0][inner]) * 100),
        "pixels": int(inner.sum()),
    }


def cmd_light(dirs):
    keys = ["ratio_median", "ratio_p90", "clipped", "hue_turn", "chroma", "keep", "matkeep", "lstar_median"]
    allres = {}
    for d in dirs:
        res = {}
        for paint in sorted(glob.glob(os.path.join(d, "*__paint.png"))):
            frame = paint.replace("__paint.png", ".png")
            if os.path.exists(frame):
                m = light_measures(frame, paint)
                if m:
                    res[os.path.basename(frame)[:-4]] = m
        allres[d] = res
        with open(os.path.join(d, "light.json"), "w") as f:
            json.dump(res, f, indent=1)
        print("== %s (%d shots)" % (d, len(res)))
        print("%-34s " % "shot" + " ".join("%9s" % k[:9] for k in keys))
        for k, m in res.items():
            print("%-34s " % k + " ".join("%9.3f" % m[x] for x in keys))
        by_light = {}
        for k, m in res.items():
            by_light.setdefault(k.split("__")[1] if "__" in k else "shot", []).append(m)
        for l, ms in by_light.items():
            print("%-34s " % ("mean " + l) + " ".join("%9.3f" % np.mean([m[x] for m in ms]) for x in keys))
        print("%-34s " % "mean all" + " ".join("%9.3f" % np.mean([m[x] for m in res.values()]) for x in keys))
    return allres


def cmd_paint(args):
    for i in range(0, len(args), 2):
        img = load(args[i])
        x, y, w, h = [int(v) for v in args[i + 1].split(",")]
        sub = img[y:y + h, x:x + w]
        d = detail(sub)[4:-4, 4:-4]
        o = oklab(sub)
        c = np.hypot(o[..., 1], o[..., 2])
        print("%s [%s]: detail %.3f, L* median %.1f, chroma median %.3f, a,b spread %.3f" % (
            os.path.basename(args[i]), args[i + 1], d.std(), np.median(o[..., 0]) * 100, np.median(c),
            np.sqrt(o[..., 1:].reshape(-1, 2).var(axis=0).sum())))


def motion_measures(frames):
    """Between consecutive frames: the share of pixels that change by more than 24/255, and the
    share that flip and come back (A, B, A: crawl and shimmer; an edge passing changes a pixel
    once), as tools/probe_walk.py measures."""
    prev2 = prev = None
    changed, flipped = [], []
    for fp in frames:
        cur = load(fp)
        if prev is not None:
            d = np.abs(cur - prev).max(axis=2)
            changed.append((d > 24 / 255).mean())
            if prev2 is not None:
                back = np.abs(cur - prev2).max(axis=2)
                d1 = np.abs(prev - prev2).max(axis=2)
                flipped.append(((d1 > 24 / 255) & (back < 8 / 255)).mean())
        prev2, prev = prev, cur
    return {"changed": float(np.mean(changed)), "flipped_back": float(np.mean(flipped)), "frames": len(frames)}


def cmd_motion(dirs):
    out = {}
    for d in dirs:
        for path in sorted(glob.glob(os.path.join(d, "motion", "*"))):
            frames = sorted(glob.glob(os.path.join(path, "*.png")))
            if len(frames) > 3:
                m = motion_measures(frames)
                out["%s:%s" % (d, os.path.basename(path))] = m
                print("%-50s changed %.4f  flipped back %.5f  (%d frames)" % (
                    "%s %s" % (d, os.path.basename(path)), m["changed"], m["flipped_back"], m["frames"]))
    return out


def cmd_sheet(args):
    from PIL import ImageDraw
    out = args[0]
    cols, shots, crop, painting, width = [], [], None, None, 480
    for a in args[1:]:
        if a.startswith("--shots="):
            shots = a[8:].split(",")
        elif a.startswith("--crop="):
            crop = [int(v) for v in a[7:].split(",")]
        elif a.startswith("--painting="):
            painting = a[11:]
        elif a.startswith("--width="):
            width = int(a[8:])
        else:
            label, d = a.split("=", 1)
            cols.append((label, d))
    tiles = []
    for s in shots:
        row = []
        if painting:
            row.append(("painting", painting))
        for label, d in cols:
            row.append((label, os.path.join(d, s + ".png")))
        tiles.append((s, row))
    ims = {}
    h = None
    for s, row in tiles:
        for label, p in row:
            im = Image.open(p).convert("RGB")
            if crop:
                if label == "painting":
                    im = im.resize((1280, 720), Image.LANCZOS)
                im = im.crop((crop[0], crop[1], crop[0] + crop[2], crop[1] + crop[3]))
            hh = int(width * im.size[1] / im.size[0])
            ims[(s, label)] = im.resize((width, hh), Image.NEAREST if crop else Image.LANCZOS)
            h = hh
    ncol = len(tiles[0][1])
    sheet = Image.new("RGB", (width * ncol, (h + 18) * len(tiles)), (20, 18, 16))
    dr = ImageDraw.Draw(sheet)
    for r, (s, row) in enumerate(tiles):
        for c, (label, p) in enumerate(row):
            sheet.paste(ims[(s, label)], (c * width, r * (h + 18) + 18))
            dr.text((c * width + 4, r * (h + 18) + 3), "%s  %s" % (label, s), fill=(235, 225, 200))
    sheet.save(out)
    print("wrote", out, sheet.size)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    cmd, rest = sys.argv[1], sys.argv[2:]
    {"light": cmd_light, "paint": cmd_paint, "motion": cmd_motion, "sheet": cmd_sheet}[cmd](rest)
