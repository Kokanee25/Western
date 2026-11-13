#!/usr/bin/env python3
"""The bones (#790): the minstrel band's rhythm, two slats of rib bone held between the fingers and
clacked by a shake of the wrist. Our own model from the physics, no copied code; the part from the
tune's beat grid (rhythm.grid), so he plays along with the fiddle and banjo.

    python3 experiments/sound_lab/fiddle/bones.py turkey_in_the_straw.json [--out=...wav]

**The sound:** two free bars striking. A bone slat ~17 cm long, ~6 mm thick (bone: E ~18 GPa,
density ~1,900) rings as a free-free bar: modes at 1 : 2.756 : 5.404 : 8.933 over a first near
650 Hz, damped fast (Q ~20-35: bone, and the hand holding it). Each clack is a short hard contact
(a pulse ~0.3 ms: bone on bone), which strikes both bones: the loose one rings, the one pinched
between the fingers less. Often the two ends meet a hair apart (a flam: the clack's "cl-ack").
No two clacks alike: the contact's force, where it lands (which modes it wakes), the flam.

**How he plays:** the old reel rhythm: a clack on each beat and the half beat, and a triplet roll
(three clacks off one flick of the wrist, each lighter: the bones rebound) leading into the next
beat; at the end of each four bars a longer roll; now and then a beat left plain or an extra clack.
Ideas from Fletcher & Rossing's bar modes and Cook's physically informed percussion; the code is ours.
"""
import json
import os
import sys
import zlib

import numpy as np
from scipy.signal import butter, lfilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
import rhythm  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
RATIOS = [1.0, 2.756, 5.404, 8.933]   # a free-free bar's modes
F1 = (655.0, 610.0)                   # the loose bone, the pinched one (Hz)
Q = (30.0, 18.0)
TICK, TICK_W = 0.2, 0.0003   # the contact's own tick against the bones' ring; its width (s)


def arrange(sc, seed=None):
    if seed is None:  # each tune its own playing (two tunes at one tempo would otherwise match)
        seed = 1871 + zlib.crc32(sc["tune"].encode()) % 100000
    rng = np.random.default_rng(seed)
    when, beats, last, unit = rhythm.grid(sc)
    clicks = []

    def clack(u, amp):
        clicks.append({"t": round(float(when(u) + rng.normal(0, 0.004)), 4), "amp": round(float(amp), 3)})

    def roll(u_from, n, amp):
        # a flick: n clacks evenly over the time to the next beat, each a little lighter (rebounds)
        t0, t1 = when(u_from), when(u_from + 1)
        for k in range(n):
            t = t0 + (t1 - t0) * k / n + rng.normal(0, 0.003)
            clicks.append({"t": round(float(t), 4), "amp": round(float(amp * (0.85 ** k) * rng.uniform(0.85, 1.1)), 3)})

    for u0, bar_start, phrase_end in beats:
        if when(u0) < rhythm.LEAD - 1e-6:
            continue
        clack(u0, 1.0 if bar_start else 0.85)
        if phrase_end:
            roll(u0 + 2, 3, 0.75)
            roll(u0 + 3, 3, 0.7)
            continue
        if rng.random() < 0.1:
            clack(u0 + 1, 0.55)
        clack(u0 + 2, 0.7)
        if rng.random() < 0.85:
            roll(u0 + 3, 3, 0.65)
        else:
            clack(u0 + 3, 0.6)
    clack(last, 1.0)  # the last note: one clack, square on it
    clicks.sort(key=lambda c: c["t"])
    return {"tune": sc["tune"], "instrument": "bones (a pair, rib bone)", "seed": seed,
            "length_s": round(clicks[-1]["t"] + 1.0, 3), "clicks": clicks}


def _clack_ir(sr, rng, amp):
    """One clack: both bones' modes, woken by a ~0.3 ms contact, plus the contact's own tick."""
    n = int(0.12 * sr)
    t = np.arange(n) / sr
    y = np.zeros(n)
    for b in (0, 1):
        f1 = F1[b] * rng.uniform(0.98, 1.02)
        for k, r in enumerate(RATIOS):
            f = f1 * r
            if f > 0.45 * sr:
                continue
            q = Q[b] * rng.uniform(0.8, 1.2) * (1.0 + 0.15 * k)
            # where the bones meet wakes the modes unevenly; the high ones less (the contact's width)
            w = rng.uniform(0.4, 1.0) * (1.0 / (1 + k) ** 0.5) * (0.6 if b else 1.0)
            y += w * np.exp(-np.pi * f * t / q) * np.sin(2 * np.pi * f * t + rng.uniform(0, 0.4))
    m = max(2, int(TICK_W * sr))  # the contact: hard and short
    tick = np.zeros(n)
    tick[:m] = np.sin(np.pi * np.arange(m) / m)
    tick[:int(0.002 * sr)] += 0.5 * rng.standard_normal(int(0.002 * sr)) * np.exp(-np.arange(int(0.002 * sr)) / (0.0004 * sr))
    y = y / np.max(np.abs(y)) + TICK * tick
    if rng.random() < 0.5:  # a flam: the two ends meet a hair apart
        d = int(rng.uniform(0.001, 0.004) * sr)
        y[d:] += rng.uniform(0.3, 0.7) * y[:-d]
    return amp * y


def render(part, sr=common.SR, seed=None):
    rng = np.random.default_rng(part.get("seed", 1871) if seed is None else seed)
    n = int(part["length_s"] * sr)
    y = np.zeros(n)
    for c in part["clicks"]:
        i = int(c["t"] * sr)
        if i >= n:
            continue
        ir = _clack_ir(sr, rng, c["amp"])
        seg = y[i:i + len(ir)]
        seg += ir[:len(seg)]
    b, a = butter(2, 150 / (sr / 2), "high")
    return lfilter(b, a, y)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    part = arrange(sc)
    name = os.path.splitext(os.path.basename(src))[0]
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_bones.wav"))
    y = render(part)
    common.write_wav(out, common.normalise(y))
    print(f"{out}: {part['tune']}, {len(part['clicks'])} clacks, {part['length_s']} s")


if __name__ == "__main__":
    main()
