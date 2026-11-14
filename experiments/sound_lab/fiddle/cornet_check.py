#!/usr/bin/env python3
"""Checks a cornet part's render note by note (#822): does each note speak, at what pitch (cents off
the note), how long its onset takes (10% to 90% of its level), and how bright it is (the spectral
centroid of its steady part) against how loud.

    python3 experiments/sound_lab/fiddle/cornet_check.py yankee_doodle.json
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
import cornet  # noqa: E402


def pitch(x, sr, f_t):
    x = x - x.mean()
    a = np.correlate(x, x, "full")[len(x) - 1:]
    lo, hi = int(sr / (f_t * 1.4)), int(sr / (f_t / 1.4)) + 1
    k = lo + int(np.argmax(a[lo:hi]))
    if a[k] < 0.4 * a[0]:
        return None
    d = a[k - 1] - 2 * a[k] + a[k + 1]
    k = k + (0.5 * (a[k - 1] - a[k + 1]) / d if d else 0)
    return 1200 * np.log2(sr / k / f_t)


def check(part, y, sr=common.SR):
    rows = []
    for nt in part["notes"]:
        i0, i1 = int(nt["t"] * sr), int((nt["t"] + nt["dur"]) * sr)
        seg = y[i0:i1]
        if len(seg) < int(0.04 * sr):
            continue
        r = np.sqrt(np.convolve(seg ** 2, np.ones(96) / 96, "same"))
        top = np.percentile(r, 90)
        on = (np.argmax(r > 0.9 * top) - np.argmax(r > 0.1 * top)) / sr * 1000
        st = seg[len(seg) // 3: max(len(seg) // 3 + 600, int(len(seg) * 0.85))]
        c = pitch(st, sr, float(common.hz(nt["midi"])))
        X = np.abs(np.fft.rfft(st * np.hanning(len(st))))
        f = np.fft.rfftfreq(len(st), 1 / sr)
        cen = float(np.sum(X * f) / np.sum(X))
        rows.append({"t": nt["t"], "midi": nt["midi"], "vel": nt["vel"], "cents": None if c is None else round(float(c), 1),
                     "onset_ms": round(float(on), 1), "centroid": round(cen), "level_db": round(20 * np.log10(top + 1e-9), 1)})
    return rows


def main():
    src = sys.argv[1] if os.path.isabs(sys.argv[1]) else os.path.join(cornet.HERE, sys.argv[1])
    part = cornet.arrange(json.load(open(src)))
    y, p, u = cornet.render_part(part)
    rows = check(part, y)
    bad = [r for r in rows if r["cents"] is None or abs(r["cents"]) > 35]
    cs = np.array([r["cents"] for r in rows if r["cents"] is not None])
    print(f"{len(rows)} notes; {len(bad)} off (silent, another partial, or >35 cents): {bad[:6]}")
    print(f"pitch: median {np.median(cs):+.1f} cents, spread (5-95%) {np.percentile(cs, 5):+.0f}..{np.percentile(cs, 95):+.0f}")
    print(f"onsets: median {np.median([r['onset_ms'] for r in rows]):.0f} ms")
    lv = np.array([r["level_db"] for r in rows])
    ce = np.array([r["centroid"] for r in rows])
    print(f"brightness against loudness: {np.polyfit(lv, ce, 1)[0]:.0f} Hz a dB (centroid {ce.min()}..{ce.max()} Hz)")
    return rows


if __name__ == "__main__":
    main()
