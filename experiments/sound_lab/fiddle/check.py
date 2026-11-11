#!/usr/bin/env python3
"""A render against its note data: each melody note's pitch (cents off), how periodic it is (the
normalised autocorrelation at the period: 1 a pure tone, ~0.5 noisy), its level. For our renders
only (the reference has no note data).

    python3 experiments/sound_lab/fiddle/check.py build/sound_lab/fiddle/dry/B.wav
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402


def yin_f0(x, sr, fmin=150, fmax=1400):
    """YIN (de Cheveigne & Kawahara 2002): the lag where the cumulative-mean-normalised difference
    first dips under 0.15, refined by a parabola; (f0, periodicity 1 - d')."""
    tmax = int(sr / fmin)
    tmin = int(sr / fmax)
    n = len(x) - tmax
    if n < 64:
        return 0.0, 0.0
    d = np.array([np.sum((x[:n] - x[t:t + n]) ** 2) for t in range(tmax + 1)])
    cm = d.copy()
    cm[0] = 1
    cm[1:] = d[1:] * np.arange(1, tmax + 1) / np.maximum(np.cumsum(d[1:]), 1e-12)
    cand = np.where(cm[tmin:] < 0.15)[0]
    if cand.size:
        t = cand[0] + tmin
        while t + 1 <= tmax and cm[t + 1] < cm[t]:
            t += 1
    else:
        t = int(np.argmin(cm[tmin:]) + tmin)
    if 1 <= t < tmax:
        a, b, c = cm[t - 1], cm[t], cm[t + 1]
        den = a - 2 * b + c
        tt = t + (0.5 * (a - c) / den if den != 0 else 0)
    else:
        tt = t
    return sr / tt, float(1 - cm[t])


def main(path):
    sr, x = common.read_wav(path)
    sc = common.score()
    rows = []
    for nt in sc["notes"]:
        if nt["voice"] != "melody":
            continue
        a = int((nt["t"] + 0.35 * nt["dur"]) * sr)
        b = int((nt["t"] + 0.85 * nt["dur"]) * sr)
        seg = x[a:b]
        if len(seg) < 600:
            continue
        f, per = yin_f0(seg, sr)
        want = float(common.hz(nt["midi"]))
        # a double stop or drone shares the window: compare against the melody or the lower note
        cents = 1200 * np.log2(max(f, 1) / want)
        rms = 20 * np.log10(np.sqrt(np.mean(seg ** 2)) + 1e-9)
        rows.append((nt["t"], nt["midi"], f, cents, per, rms))
    c = np.array([r[3] for r in rows])
    ok = np.abs(((c + 600) % 1200) - 600) < 30  # within 30 cents, octave errors forgiven
    print(f"{path}: {len(rows)} notes, pitch within 30 cents (octaves aside) {ok.mean():.0%}, "
          f"median periodicity {np.median([r[4] for r in rows]):.2f}, level spread {np.std([r[5] for r in rows]):.1f} dB")
    bad = [r for r, k in zip(rows, ok) if not k]
    for r in bad[:12]:
        print(f"  t {r[0]:.2f} midi {r[1]} got {r[2]:.0f} Hz ({r[3]:+.0f} c) per {r[4]:.2f} {r[5]:.0f} dB")


if __name__ == "__main__":
    main(sys.argv[1])
