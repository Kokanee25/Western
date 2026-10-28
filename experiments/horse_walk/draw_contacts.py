"""Draws contacts.json's stances over legmask.png's space-time picture (a box per stance, its
label: index and leg if assigned), to check the detection by eye.

    ~/cvenv/bin/python experiments/horse_walk/draw_contacts.py [--in=contacts.json] [--scale=2]
"""
import json
import os
import sys

import cv2
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "build", "horse_walk")
COL = {"LH": (0, 0, 255), "LF": (0, 160, 255), "RH": (255, 0, 0), "RF": (255, 160, 0), None: (0, 170, 0)}


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    st = np.load(os.path.join(OUT, "leg_st.npy"))
    meta = json.load(open(os.path.join(OUT, "leg_st.json")))
    f0, lo = meta["frames"][0], meta["lo"]
    c = json.load(open(os.path.join(OUT, opts.get("in", "contacts.json"))))["stances"]
    x0, x1 = (int(v) for v in opts.get("cols", "400,1000").split(","))
    s = int(opts.get("scale", "2"))
    img = (255 - np.clip(st[:, x0 - lo:x1 - lo] * 3, 0, 1) * 200).astype(np.uint8)
    img = cv2.resize(img, (img.shape[1], img.shape[0] * s), interpolation=cv2.INTER_NEAREST)
    img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    for f in range(f0, f0 + st.shape[0], 10):
        y = (f - f0) * s
        cv2.line(img, (0, y), (10 if f % 30 else 24, y), (0, 0, 0), 1)
        if f % 30 == 0:
            cv2.putText(img, str(f), (26, y + 4), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 0, 0), 1)
    for gx in range(x0, x1, 25):
        cv2.line(img, (gx - x0, 0), (gx - x0, 6 if gx % 100 else 14), (0, 0, 0), 1)
        if gx % 100 == 0:
            cv2.putText(img, str(gx), (gx - x0 + 2, 24), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 0, 0), 1)
    for i, d in enumerate(c):
        if not (x0 < d["x"] < x1):
            continue
        cx = int(d["x"] - x0)
        col = COL.get(d.get("leg"))
        cv2.rectangle(img, (cx - 8, (d["on"] - f0) * s), (cx + 8, (d["off"] - f0) * s), col, 1)
        cv2.putText(img, "%d %s" % (i, d.get("leg") or ""), (cx + 10, (d["on"] - f0) * s + 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.38, col, 1)
    cv2.imwrite(os.path.join(OUT, opts.get("out", "contacts.png")), img)
    print("ok")


if __name__ == "__main__":
    main()
