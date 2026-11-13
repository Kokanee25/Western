#!/usr/bin/env python3
"""Drums, a kick and a snare (Sean, 2026-11-13: under the Caamp-style songs; #822's march drums can
start here): modal synthesis written from the physics, no copied code; the pattern from the song's
bars.

    python3 experiments/sound_lab/fiddle/drums.py porch_light.json [--out=...wav] [--style=stomp|four]

**The kick:** a felt beater on a big skin (a 20-22" bass drum), damped inside: the membrane's modes
(Bessel ratios over ~55 Hz), the fundamental ringing ~0.25 s and the upper modes far less; the hit
stretches the skin, so the pitch starts high and falls in a few tens of ms (tension modulation; Fletcher
& Rossing); the beater's own click (a short felt slap, 1-4 kHz).
**The snare:** a smaller, tighter skin (~190 Hz and its modes, brief) and under it the snare wires,
which rattle against the bottom head while it moves: a burst of noise (2-9 kHz) a moment after the hit,
dying in ~0.15 s; played soft here, the folk band's light backbeat.

**How he plays:** "stomp": the kick on one and three, the snare on two and four; "four": the kick on
every beat (the up-tempo stomp), the snare on two and four. The last bar one kick and let it ring.
"""
import json
import os
import sys

import numpy as np
from scipy.signal import butter, lfilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
import rhythm  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
BESSEL = [1.0, 1.594, 2.136, 2.296, 2.653, 2.918]
STYLE = "stomp"
SNARE = 0.45     # the snare's level against the kick


def arrange(sc, seed=1959):
    rng = np.random.default_rng(seed)
    when, beats, last, unit = rhythm.grid(sc)
    starts = sc.get("bar_units") or []
    hits = []
    first = rhythm.LEAD - 1e-6
    for b, u in enumerate(starts):
        final = b == len(starts) - 1
        for q in range(4):
            t = when(u + 2 * q)
            if t < first:
                continue
            if final and q > 0:
                break
            if q in (0, 2) or STYLE == "four" or final:
                hits.append({"t": round(float(t + rng.normal(0, 0.004)), 4), "drum": "kick",
                             "amp": round(float((1.0 if q == 0 else 0.9) * np.exp(rng.normal(0, 0.06))), 3)})
            if q in (1, 3) and not final:
                hits.append({"t": round(float(t + rng.normal(0, 0.005)), 4), "drum": "snare",
                             "amp": round(float(np.exp(rng.normal(0, 0.1))), 3)})
    hits.sort(key=lambda h: h["t"])
    return {"tune": sc["tune"], "instrument": "kick and snare", "style": STYLE, "seed": seed,
            "length_s": round(hits[-1]["t"] + 2.0, 3), "hits": hits}


def _kick(sr, rng, amp):
    n = int(0.6 * sr)
    t = np.arange(n) / sr
    f0 = 55.0 * rng.uniform(0.97, 1.03)
    bend = 1.0 + 0.35 * amp * np.exp(-t / 0.025)  # the skin stretched by the hit, settling
    y = np.zeros(n)
    for k, r in enumerate(BESSEL):
        decay = 0.25 if k == 0 else 0.06 / (1 + k)
        ph = 2 * np.pi * np.cumsum(f0 * r * bend) / sr
        y += (1.0 if k == 0 else 0.5 / (1 + k)) * np.exp(-t / decay) * np.sin(ph)
    L = int(0.004 * sr)  # the beater's felt slap
    click = rng.standard_normal(L) * np.exp(-np.arange(L) / (0.0008 * sr))
    click = lfilter(*butter(2, [1000 / (sr / 2), 4000 / (sr / 2)], "band"), click)
    y[:L] += 0.6 * click / (np.max(np.abs(click)) + 1e-12)
    return amp * y / np.max(np.abs(y))


def _snare(sr, rng, amp):
    n = int(0.4 * sr)
    t = np.arange(n) / sr
    f0 = 190.0 * rng.uniform(0.98, 1.02)
    y = np.zeros(n)
    for k, r in enumerate(BESSEL):
        y += (1.0 / (1 + k)) * np.exp(-t / (0.06 / (1 + 0.5 * k))) * np.sin(2 * np.pi * f0 * r * t + rng.uniform(0, 6))
    wires = rng.standard_normal(n) * np.exp(-np.maximum(t - 0.002, 0) / 0.15) * (t > 0.002)
    wires = lfilter(*butter(2, [2000 / (sr / 2), 9000 / (sr / 2)], "band"), wires)
    y = y / np.max(np.abs(y)) + 1.2 * wires / (np.max(np.abs(wires)) + 1e-12)
    return amp * y / np.max(np.abs(y))


def render(part, sr=common.SR, seed=1959):
    rng = np.random.default_rng(seed)
    n = int(part["length_s"] * sr)
    y = np.zeros(n)
    for h in part["hits"]:
        i = int(h["t"] * sr)
        if i >= n:
            continue
        s = _kick(sr, rng, h["amp"]) if h["drum"] == "kick" else SNARE * _snare(sr, rng, h["amp"])
        seg = y[i:i + len(s)]
        seg += s[:len(seg)]
    b, a = butter(2, 30 / (sr / 2), "high")
    return lfilter(b, a, y)


def main():
    global STYLE
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    STYLE = opt.get("style", "stomp")
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    part = arrange(sc)
    name = os.path.splitext(os.path.basename(src))[0]
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_drums.wav"))
    y = render(part)
    common.write_wav(out, common.normalise(y))
    print(f"{out}: {part['tune']}, {len(part['hits'])} hits ({STYLE}), {part['length_s']} s")


if __name__ == "__main__":
    main()
