#!/usr/bin/env python3
"""The tambourine (#790): the minstrel band's "tambo", a calfskin head on a wooden hoop with pairs of
tin jingles in slots round it. Our own model from the physics, no copied code; the part from the
tune's beat grid (rhythm.grid).

    python3 experiments/sound_lab/fiddle/tambourine.py turkey_in_the_straw.json [--out=...wav]

**The sound:** the head is a damped membrane (a circular membrane's Bessel modes over ~190 Hz, a
hand on the hoop damping it hard) and the hoop knocks a little. The jingles are what make it a
tambourine, and what a recording can't fake by a loop: each pair is two thin tin discs on a pin
that clatter against each other while the hoop moves. Each pair carries its own energy; a hit or a
shake gives it some, it bleeds away (~0.1 s), and while it has energy the discs collide at random,
more often and harder the more it has (a Poisson process; Cook's PhISEM idea, 1997), each
collision ringing the discs' own modes (a thin free plate's: ~1 : 1.73 : 2.33 : 3.91 over 3-4 kHz,
each pair its own) for a few ms. So a hit's jingle thins out as it dies and no two are alike.

**How he plays:** a hit on each beat (the heel of the hand, harder at the bar), a lighter tap on the
half beat, a little shake before each bar (only there: the jingle needs room to breathe); a thumb roll (the jingles kept going, the head rubbed) over the
last half of each four bars; one hit on the last note.
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
PAIRS = 6
DISC = [1.0, 1.73, 2.33, 3.91, 4.11]
HEAD_F01 = 190.0
BESSEL = [1.0, 1.594, 2.136, 2.296, 2.653, 2.918, 3.156, 3.501]
STEP = 0.0005         # the jingles' energy bookkeeping, s
SETTLE = 0.07         # s: how fast a pair's energy bleeds away
RATE = 450.0          # collisions a second at full energy


def arrange(sc, seed=None):
    if seed is None:  # each tune its own playing (two tunes at one tempo would otherwise match)
        seed = 1872 + zlib.crc32(sc["tune"].encode()) % 100000
    rng = np.random.default_rng(seed)
    when, beats, last, unit = rhythm.grid(sc)
    strokes = []

    def st(u, kind, amp, dur=0.0):
        strokes.append({"t": round(float(when(u) + rng.normal(0, 0.005)), 4), "kind": kind,
                        "amp": round(float(amp * rng.uniform(0.85, 1.15)), 3), "dur": round(float(dur), 4)})

    for u0, bar_start, phrase_end in beats:
        if when(u0) < rhythm.LEAD - 1e-6:
            continue
        st(u0, "hit", 1.0 if bar_start else 0.75)
        if phrase_end:
            st(u0 + 2, "roll", 0.7, when(u0 + 4) - when(u0 + 2) - 0.02)
            continue
        st(u0 + 2, "tap", 0.6)
        if not bar_start:  # a shake only before the next bar, so the jingle breathes between
            st(u0 + 3, "shake", 0.3, 0.06)
    st(last, "hit", 1.0)
    strokes.sort(key=lambda s: s["t"])
    return {"tune": sc["tune"], "instrument": "tambourine (calfskin, tin jingles)", "seed": seed,
            "length_s": round(strokes[-1]["t"] + 1.2, 3), "strokes": strokes}


def _modes(sr, freqs, qs, weights, length, rng):
    n = int(length * sr)
    t = np.arange(n) / sr
    y = np.zeros(n)
    for f, q, w in zip(freqs, qs, weights):
        if f < 0.45 * sr:
            y += w * np.exp(-np.pi * f * t / q) * np.sin(2 * np.pi * f * t + rng.uniform(0, 2 * np.pi))
    return y


def render(part, sr=common.SR, seed=None):
    rng = np.random.default_rng(part.get("seed", 1872) if seed is None else seed)
    n = int(part["length_s"] * sr)
    head = np.zeros(n)
    jingle = np.zeros(n)
    # the head's strikes: a hand's soft pulse into the membrane's modes, the hoop's knock
    for s in part["strokes"]:
        if s["kind"] not in ("hit", "tap"):
            continue
        i = int(s["t"] * sr)
        g = s["amp"] * (1.0 if s["kind"] == "hit" else 0.35)
        fr = [HEAD_F01 * r * rng.uniform(0.99, 1.01) for r in BESSEL] + [520.0, 880.0]
        qs = [rng.uniform(5, 10) for _ in BESSEL] + [15.0, 18.0]
        ws = [rng.uniform(0.5, 1.0) / (1 + 0.3 * k) for k in range(len(BESSEL))] + [0.25, 0.15]
        ir = _modes(sr, fr, qs, ws, 0.2, rng)
        m = int(0.0015 * sr)  # the heel of the hand: soft
        ir = np.convolve(ir, np.hanning(m) / np.hanning(m).sum())[:len(ir)]
        seg = head[i:i + len(ir)]
        seg += g * ir[:len(seg)] / (np.max(np.abs(ir)) + 1e-12)
        if s["kind"] == "hit" and i + int(0.003 * sr) < n:  # skin and knuckle: a little slap
            k = int(0.003 * sr)
            head[i:i + k] += 0.2 * g * rng.standard_normal(k) * np.exp(-np.arange(k) / (0.0008 * sr))
    # the jingles: each pair's energy, given by the strokes, bled away, spent in random collisions
    steps = int(part["length_s"] / STEP)
    inject = np.zeros((PAIRS, steps))
    for s in part["strokes"]:
        k0 = int(s["t"] / STEP)
        share = rng.uniform(0.6, 1.0, PAIRS)
        if s["kind"] in ("hit", "tap"):
            inject[:, min(k0, steps - 1)] += s["amp"] * (1.0 if s["kind"] == "hit" else 0.5) * share
        else:
            # a shake or roll: energy fed in as the hand moves, pulsing at the shake's ~11 Hz
            k1 = min(steps, k0 + max(1, int(s["dur"] / STEP)))
            tt = np.arange(k1 - k0) * STEP
            pulse = (0.5 + 0.5 * np.cos(2 * np.pi * 11.0 * tt)) ** 4
            for p in range(PAIRS):
                inject[p, k0:k1] += s["amp"] * 0.12 * share[p] * pulse
    decay = np.exp(-STEP / SETTLE)
    pings = []
    for p in range(PAIRS):
        e = 0.0
        f1 = rng.uniform(3000, 4300)
        for k in range(steps):
            e = e * decay + inject[p, k]
            if e < 1e-4:
                continue
            if rng.random() < RATE * np.sqrt(min(e, 1.5)) * STEP:
                a = np.sqrt(e) * rng.uniform(0.3, 1.0)
                pings.append((k * STEP + rng.uniform(0, STEP), p, f1, a))
                e *= 0.93  # each collision spends some
    for t, p, f1, a in pings:
        i = int(t * sr)
        if i >= n:
            continue
        fr = [f1 * r * rng.uniform(0.995, 1.005) for r in DISC]
        ir = _modes(sr, fr, [rng.uniform(40, 110) for _ in DISC],
                    [rng.uniform(0.3, 1.0) for _ in DISC], 0.03, rng)
        k = int(0.0008 * sr)  # tin on tin: a short click under the ring
        ir[:k] += 0.6 * rng.standard_normal(k) * np.exp(-np.arange(k) / (0.0002 * sr))
        seg = jingle[i:i + len(ir)]
        seg += a * ir[:len(seg)] / (np.max(np.abs(ir)) + 1e-12)
    b, a = butter(2, 2000 / (sr / 2), "high")  # the jingles' own band; the pin's thud isn't heard
    jingle = lfilter(b, a, jingle)
    y = head / (np.std(head) + 1e-12) * 0.6 + jingle / (np.std(jingle) + 1e-12)
    b, a = butter(2, 80 / (sr / 2), "high")
    return lfilter(b, a, y), len(pings)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    part = arrange(sc)
    name = os.path.splitext(os.path.basename(src))[0]
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_tambourine.wav"))
    y, pings = render(part)
    common.write_wav(out, common.normalise(y))
    kinds = {}
    for s in part["strokes"]:
        kinds[s["kind"]] = kinds.get(s["kind"], 0) + 1
    print(f"{out}: {part['tune']}, {kinds}, {pings} jingle collisions, {part['length_s']} s")


if __name__ == "__main__":
    main()
