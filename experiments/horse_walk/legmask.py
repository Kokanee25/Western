"""The reference's legs by colour, laid on the ground, as a space-time picture.

    ~/cvenv/bin/python experiments/horse_walk/legmask.py [--band=452,492] [--frames=20,250]

A pixel is leg when it is red-brown (R/G > 1.55, not bright) or near black (the hooves); specks
cleared by a morphological opening (3 px). For each frame and ground column (the camera's pan
taken out, pan.json), the share of the hoof band that is leg. Saved as build/horse_walk/leg_st.npy
(frames x ground columns) and drawn as legmask.png: a planted hoof is a vertical bar, a swinging
one a slanting line.
"""
import glob
import json
import os
import sys

import cv2
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "build", "horse_walk")
W = 970


def leg_mask(bgr):
    b, g, r = [bgr[..., i].astype(np.float32) for i in range(3)]
    lum = (r + g + b) / 3
    m = (((r / (g + 1)) > 1.55) & (lum < 130)) | (lum < 45)
    m = m.astype(np.uint8)
    k = np.ones((3, 3), np.uint8)
    return cv2.morphologyEx(m, cv2.MORPH_OPEN, k)


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    y0, y1 = (int(v) for v in opts.get("band", "452,492").split(","))
    f0, f1 = (int(v) for v in opts.get("frames", "20,250").split(","))
    pan = json.load(open(os.path.join(OUT, "pan.json")))["pan"]
    frames = sorted(glob.glob(os.path.join(OUT, "frames", "f*.png")))
    lo = int(np.floor(min(-v for v in pan))) - 1
    width = W + int(np.ceil(max(-v for v in pan) - lo)) + 2
    st = np.zeros((f1 - f0, width), np.float32)
    for k, i in enumerate(range(f0, f1)):
        m = leg_mask(cv2.imread(frames[i]))[y0:y1].mean(axis=0)
        x = int(round(-pan[i] - lo))
        st[k, x:x + W] = m
    np.save(os.path.join(OUT, "leg_st.npy"), st)
    json.dump({"band": [y0, y1], "frames": [f0, f1], "lo": lo}, open(os.path.join(OUT, "leg_st.json"), "w"))
    x0, x1 = (int(v) for v in opts.get("cols", "400,1000").split(","))
    img = (255 - np.clip(st[:, x0 - lo:x1 - lo] * 3, 0, 1) * 255).astype(np.uint8)
    s = int(opts.get("scale", "3"))
    img = cv2.resize(img, (img.shape[1], img.shape[0] * s), interpolation=cv2.INTER_NEAREST)
    img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    for f in range(f0, f1, 10):
        y = (f - f0) * s
        cv2.line(img, (0, y), (10 if f % 30 else 24, y), (0, 0, 255), 1)
        if f % 30 == 0:
            cv2.putText(img, str(f), (26, y + 4), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 0, 255), 1)
    for gx in range(x0, x1, 25):
        c = gx - x0
        cv2.line(img, (c, 0), (c, 6 if gx % 100 else 14), (255, 128, 0), 1)
        if gx % 100 == 0:
            cv2.putText(img, str(gx), (c + 2, 24), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (255, 128, 0), 1)
    cv2.imwrite(os.path.join(OUT, opts.get("out", "legmask.png")), img)
    print("ok", img.shape)


if __name__ == "__main__":
    main()
