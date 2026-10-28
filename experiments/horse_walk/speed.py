"""The horse's speed over the ground in the reference: the trunk's leg-coloured pixels (rows
330-400: barrel and saddle flap, under the saddle's dark leather) found per frame, their
mean x on the ground (pan taken out); a straight line through them.

    ~/cvenv/bin/python experiments/horse_walk/speed.py [--rows=330,400] [--frames=20,240]
"""
import glob
import json
import os
import sys

import cv2
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from legmask import leg_mask, OUT  # noqa: E402


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    y0, y1 = (int(v) for v in opts.get("rows", "330,400").split(","))
    f0, f1 = (int(v) for v in opts.get("frames", "20,240").split(","))
    pan = json.load(open(os.path.join(OUT, "pan.json")))["pan"]
    frames = sorted(glob.glob(os.path.join(OUT, "frames", "f*.png")))
    xs, ts, front, back = [], [], [], []
    for i in range(f0, f1):
        m = leg_mask(cv2.imread(frames[i]))[y0:y1]
        cols = np.where(m.mean(axis=0) > 0.5)[0]
        if len(cols) < 50:
            continue
        xs.append(cols.mean() - pan[i])
        front.append(np.percentile(cols, 98) - pan[i])
        back.append(np.percentile(cols, 2) - pan[i])
        ts.append(i)
    ts = np.array(ts)
    for name, v in (("middle", xs), ("front", front), ("back", back)):
        v = np.array(v)
        k, c = np.polyfit(ts, v, 1)
        r = v - (k * ts + c)
        print("%-6s %.3f px/frame  residual sd %.1f px" % (name, k, r.std()))
    v = np.array(xs)
    # the speed in thirds of the stretch: does he slow down?
    for a, b in ((0, len(ts) // 3), (len(ts) // 3, 2 * len(ts) // 3), (2 * len(ts) // 3, len(ts))):
        k, _ = np.polyfit(ts[a:b], v[a:b], 1)
        print("  frames %d-%d: %.3f px/frame" % (ts[a], ts[b - 1], k))
    print("trunk length (front-back) median %.0f px" % np.median(np.array(front) - np.array(back)))
    json.dump({"frames": ts.tolist(), "x": [round(float(a), 1) for a in xs]}, open(os.path.join(OUT, "speed.json"), "w"))


if __name__ == "__main__":
    main()
