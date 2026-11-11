#!/usr/bin/env python3
"""C: the hybrid (issue #790). The samples (A, without their short-stroke bites) carry the body of
the tone; our bowed-string model (B), driven by the same note data, supplies what samples do
worst: each stroke's start (the model's own stick-slip settling into the note, ~60 ms), the slurred
note changes (the model's string carrying the change for ~40 ms), and the bow's scratch (the
model above 3 kHz, quietly, throughout).

    python3 experiments/sound_lab/fiddle/hybrid.py [--out=build/sound_lab/fiddle/dry/C.wav]
"""
import os
import sys

import numpy as np
from scipy.signal import butter, lfilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bowed  # noqa: E402
import common  # noqa: E402
import samples  # noqa: E402

ONSET_S = 0.05     # the model's share at a stroke's start decays with this time constant
CHANGE_S = 0.02    # and round a slurred note change
SCRATCH = 0.35     # the model above 3 kHz, under the whole


def weights(sc, n, sr=common.SR):
    t = np.arange(n) / sr
    w = np.zeros(n)
    for st in sc["strokes"]:
        i0 = int(st["t0"] * sr)
        m = min(n - i0, int(6 * ONSET_S * sr))
        w[i0:i0 + m] = np.maximum(w[i0:i0 + m], np.exp(-np.arange(m) / sr / ONSET_S))
    for nt in sc["notes"]:
        if nt["slur"] and nt["voice"] == "melody":
            c = nt["t"]
            a, b = max(0, int((c - 4 * CHANGE_S) * sr)), min(n, int((c + 4 * CHANGE_S) * sr))
            w[a:b] = np.maximum(w[a:b], 0.6 * np.exp(-np.abs(t[a:b] - c) / CHANGE_S))
    return w


def render(sc, folder=samples.DEFAULT_DIR, sr=common.SR):
    a = common.normalise(samples.render(sc, folder, sr, bites=False), sr)
    b = common.normalise(bowed.render(sc, sr), sr)
    n = min(len(a), len(b))
    a, b = a[:n], b[:n]
    w = weights(sc, n, sr)
    hb, ha = butter(2, 3000 / (sr / 2), "high")
    return a * (1 - 0.75 * w) + b * w + SCRATCH * lfilter(hb, ha, b)


if __name__ == "__main__":
    out = next((x.split("=", 1)[1] for x in sys.argv[1:] if x.startswith("--out=")),
               os.path.join(common.BUILD, "dry", "C.wav"))
    y = render(common.score())
    common.write_wav(out, common.normalise(y))
    print(out)
