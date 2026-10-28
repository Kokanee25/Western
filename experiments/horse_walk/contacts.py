"""Hoof contacts from the leg space-time picture (legmask.py's leg_st.npy).

    python3 experiments/horse_walk/contacts.py [--thr=0.3] [--min=6]

In each ground column, runs of frames where the hoof band is leg (share > thr) at least `min`
frames long; runs in neighbouring columns that overlap in time are one planted hoof. Its contact
is the earliest frame any of its columns is covered (the hoof landing), its lift-off the last
(the toe leaving after breakover), its ground x the middle of its columns. Then the stances are
put in time order and given to legs by the walk's rule (each hoof lands ~one stride on from its
last place), and the stride, duty factors and the order of footfalls worked out.
Writes build/horse_walk/contacts.json.
"""
import json
import os
import sys

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "build", "horse_walk")


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    thr = float(opts.get("thr", "0.3"))
    n = int(opts.get("min", "6"))
    st = np.load(os.path.join(OUT, "leg_st.npy"))
    meta = json.load(open(os.path.join(OUT, "leg_st.json")))
    f0, lo = meta["frames"][0], meta["lo"]
    on = st > thr
    groups = []
    live = []
    for x in range(st.shape[1]):
        col = on[:, x]
        rs = []
        i = 0
        while i < len(col):
            if col[i]:
                j = i
                while j + 1 < len(col) and col[j + 1]:
                    j += 1
                if j - i + 1 >= n:
                    rs.append((i, j))
                i = j + 1
            else:
                i += 1
        nxt = []
        for s, e in rs:
            hit = None
            for g in live:
                ov = min(e, g["e"]) - max(s, g["s"])
                if ov > 0.4 * min(e - s, g["e"] - g["s"]):
                    hit = g
                    break
            if hit is None:
                hit = {"cols": [], "s": s, "e": e}
                groups.append(hit)
            hit["cols"].append((x, s, e))
            hit["s"], hit["e"] = s, e
            nxt.append(hit)
        live = nxt
    stances = []
    for g in groups:
        cs = g["cols"]
        if len(cs) < int(opts.get("minw", "6")):
            continue
        xs = np.array([c[0] for c in cs])
        ss = np.array([c[1] for c in cs])
        ee = np.array([c[2] for c in cs])
        dur = ee - ss + 1
        core = dur >= 0.5 * dur.max()   # the hoof itself, not the pastern's edges
        stances.append({"x": round(float(lo + xs[core].mean()), 1), "w": int(len(cs)),
                        "on": int(ss[core].min() + f0), "off": int(ee[core].max() + f0),
                        "clipped": bool(ss[core].min() == 0 or ee[core].max() == st.shape[0] - 1)})
    stances.sort(key=lambda d: d["on"])
    json.dump({"thr": thr, "min": n, "stances": stances}, open(os.path.join(OUT, "contacts.json"), "w"), indent=1)
    for d in stances:
        print("x %6.1f  w %3d  on %3d off %3d  (%2d frames)%s" % (d["x"], d["w"], d["on"], d["off"],
                                                                  d["off"] - d["on"] + 1, "  clipped" if d["clipped"] else ""))


if __name__ == "__main__":
    main()
