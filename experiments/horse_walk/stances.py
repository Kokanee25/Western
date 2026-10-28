"""Planted hooves in the reference clip, found in numbers rather than by eye.

    python3 experiments/horse_walk/stances.py [--rows=452,490] [--frames=20,250] [--thr=18] [--min=8]

The hoof band (rows at hoof height) laid on the ground's columns by the camera's pan (pan.json);
each column's darkness against its own median over the clip (the ground). A planted hoof keeps a
few ground columns dark for its whole stance; a swinging one crosses a column in a frame or two.
So: in each column, runs of dark frames at least --min long; runs in neighbouring columns that
overlap in time joined into one stance: (ground x, first frame, last frame, width). Writes
build/horse_walk/stances.json and prints them in time order.
"""
import glob
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "build", "horse_walk")
W = 970


def darkness(rows, f0, f1):
    pan = json.load(open(os.path.join(OUT, "pan.json")))["pan"]
    frames = sorted(glob.glob(os.path.join(OUT, "frames", "f*.png")))
    lo = int(np.floor(min(-v for v in pan))) - 1
    width = W + int(np.ceil(max(-v for v in pan) - lo)) + 2
    y0, y1 = rows
    lum = np.full((len(frames), width), np.nan, np.float32)
    for i, p in enumerate(frames):
        a = np.asarray(Image.open(p).convert("L"), np.float32)[y0:y1]
        # a hoof is the darkest few pixels down the band: the mean of the 4 darkest
        row = np.sort(a, axis=0)[:4].mean(axis=0)
        x = -pan[i] - lo
        xi = int(np.floor(x))
        fr = x - xi
        sh = np.zeros(width, np.float32)
        sh[xi:xi + W] += row * (1 - fr)
        sh[xi + 1:xi + 1 + W] += row * fr
        sh[:xi + 1] = np.nan
        sh[xi + W:] = np.nan
        lum[i] = sh
    med = np.nanmedian(lum, axis=0)
    return (med[None, :] - lum)[f0:f1], lo


def runs(col, thr, n):
    out = []
    on = np.nan_to_num(col, nan=0.0) > thr
    i = 0
    while i < len(on):
        if on[i]:
            j = i
            while j + 1 < len(on) and on[j + 1]:
                j += 1
            if j - i + 1 >= n:
                out.append((i, j))
            i = j + 1
        else:
            i += 1
    return out


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    rows = [int(v) for v in opts.get("rows", "452,490").split(",")]
    f0, f1 = (int(v) for v in opts.get("frames", "20,250").split(","))
    thr = float(opts.get("thr", "18"))
    n = int(opts.get("min", "8"))
    D, lo = darkness(rows, f0, f1)
    cols = [runs(D[:, x], thr, n) for x in range(D.shape[1])]
    # join runs in neighbouring columns that overlap in time by more than half the shorter
    events = []  # [x0, x1, s, e, columns]
    open_ev = []
    for x, rs in enumerate(cols):
        nxt = []
        for s, e in rs:
            hit = None
            for ev in open_ev:
                ov = min(e, ev[3]) - max(s, ev[2])
                if ov > 0.5 * min(e - s, ev[3] - ev[2]):
                    hit = ev
                    break
            if hit:
                hit[1] = x
                hit[4].append((x, s, e))
                nxt.append(hit)
            else:
                ev = [x, x, s, e, [(x, s, e)]]
                events.append(ev)
                nxt.append(ev)
        open_ev = nxt
    out = []
    for x0, x1, s, e, cs in events:
        w = x1 - x0 + 1
        if w < int(opts.get("minw", "5")):
            continue
        ss = np.array([c[1] for c in cs])
        ee = np.array([c[2] for c in cs])
        # the stance: the median column's run (the hoof's middle), robust to the leg's edges
        out.append({"x": round(lo + (x0 + x1) / 2, 1), "w": w,
                    "on": int(np.median(ss)) + f0, "off": int(np.median(ee)) + f0,
                    "on_min": int(ss.min()) + f0, "off_max": int(ee.max()) + f0})
    out.sort(key=lambda d: d["on"])
    json.dump({"rows": rows, "thr": thr, "min": n, "stances": out}, open(os.path.join(OUT, "stances.json"), "w"), indent=1)
    for d in out:
        print("x %6.1f  w %3d  frames %3d-%3d (%2d)   extent %3d-%3d" % (d["x"], d["w"], d["on"], d["off"],
                                                                     d["off"] - d["on"] + 1, d["on_min"], d["off_max"]))


if __name__ == "__main__":
    main()
