#!/usr/bin/env python3
"""The acoustic guitar (Sean, 2026-11-13: toward Caamp, "we may need an actual guitar"): a steel-strung
flat-top, strummed with a pick in the indie-folk way, from a song's chords. Our own model, the banjo's
strings on a guitar's wooden body; no copied code.

    python3 experiments/sound_lab/fiddle/guitar.py porch_light.json [--out=...wav]

**The instrument:** six steel strings in standard tuning (E A D G B E) over a wooden box. The strings
are banjo.py's waveguides (two ways of swinging each, a loop loss set from two decay times), longer
ringing than the banjo's: steel on a wooden bridge loses less to its body than a string on a drum head.
The body is a box: the air in it breathing through the soundhole (~100 Hz), the top plate (~190 Hz),
the back (~230), then a dense set of the wood's modes, with a little presence round 2-4 kHz and the top
falling away past 6 (Caldersmith; Christensen and Vistisen on the guitar's low modes); its overall curve
is set and its detail kept, as the piano's board.

**How he plays:** the folk shapes that keep the top two strings ringing through the changes (G 320033,
Cadd9 x32033, D xx0232, Em7 022033), strummed "down, down-up, up-down-up" through each bar: a down
stroke rakes the strings from the lowest of the shape up (~20 ms across, the bar's first beat the
hardest), an up stroke catches the top three or four on the way back, lighter and quicker. A string
rings until it's struck again; one the new chord doesn't use is damped by the fretting hand.
"""
import json
import os
import sys

import numpy as np
from scipy.signal import butter, fftconvolve, lfilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import banjo  # noqa: E402  (the strings: run_string, loop_filter, _pulse)
import common  # noqa: E402
import rhythm  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
TUNING = [40, 45, 50, 55, 59, 64]           # E2 A2 D3 G3 B3 E4, low to high
SHAPES = {                                   # frets low E to high E; None not played
    "G": [3, 2, 0, 0, 3, 3], "C": [None, 3, 2, 0, 3, 3], "D": [None, None, 0, 2, 3, 2],
    "Em": [0, 2, 2, 0, 3, 3], "Am": [None, 0, 2, 2, 1, 0], "A": [None, 0, 2, 2, 2, 0],
    "E": [0, 2, 2, 1, 0, 0], "Bm": [None, 2, 4, 4, 3, 2], "F": [1, 3, 3, 2, 1, 1], "Dm": [None, None, 0, 2, 3, 1],
}
PATTERN = [(0, "D"), (2, "D"), (3, "U"), (5, "U"), (6, "D"), (7, "U")]  # eighths of a 4/4 bar
T60_LOW, T60_HIGH = 5.0, 0.8                 # s: a string's own ring (E2), and its partials near 2 kHz
POLS = [(1.0, 1.0, 0.0), (0.4, 1.7, 0.8)]   # (level, decay x, cents): the two ways a string swings


def arrange(sc, seed=1972):
    """The guitarist's part: strokes {t, dir, strings [(index, fret, amp)], chord} from the song's chords
    (one a bar) over the beat grid."""
    rng = np.random.default_rng(seed)
    when, beats, last, unit = rhythm.grid(sc)
    mel = sorted([n for n in sc["notes"] if n["voice"] == "melody"], key=lambda n: n["unit"])
    bar1 = next((n["unit"] for n in mel if n["bar"] >= 1), 0.0)
    chords = sc.get("chords") or ["G"]
    strokes = []
    starts = sc.get("bar_units") or [bar1 + 8 * k for k in range(int((last - bar1) // 8) + 2)]
    first = rhythm.LEAD - 1e-6
    for b, u in enumerate(starts):
        ch = chords[min(b, len(chords) - 1)]
        shape = SHAPES.get(ch, SHAPES["G"])
        played = [i for i, f in enumerate(shape) if f is not None]
        final = b == len(starts) - 1
        for k, d in (PATTERN[:1] if final else PATTERN):  # the last bar: one chord, let ring
            t0 = when(u + k)
            if t0 < first:
                continue
            if d == "D":
                strs = played if k == 0 else (played[1:] if len(played) > 4 else played)
                amp = (1.0 if k == 0 else 0.78) * np.exp(rng.normal(0, 0.08))
                spread = rng.uniform(0.016, 0.028) * (1.6 if final else 1.0)
            else:
                strs = played[::-1][:rng.integers(3, 5)]
                amp = 0.55 * np.exp(rng.normal(0, 0.1))
                spread = rng.uniform(0.008, 0.015)
            tt = t0 + rng.normal(0, 0.005)
            strokes.append({"t": round(float(tt), 4), "dir": d, "chord": ch, "spread": round(float(spread), 4),
                            "strings": [[int(i), int(shape[i]), round(float(amp * (1.05 if i == played[0] and d == "D" else 1.0)), 3)]
                                        for i in strs]})
    strokes.sort(key=lambda s: s["t"])
    return {"tune": sc["tune"], "instrument": "steel-string acoustic guitar, strummed", "seed": seed,
            "length_s": round(strokes[-1]["t"] + 4.0, 3), "strokes": strokes}


def body_ir(sr, seed=1972, length=0.3):
    """The wooden box: the air through the soundhole, the top, the back, then a dense set of modes; its
    overall curve set (a body round 100-250 Hz, the box's hollow round 500, a little presence at 2-4 kHz,
    falling past 6), its detail kept."""
    rng = np.random.default_rng(seed)
    t = np.arange(int(length * sr)) / sr
    modes = [(100, 18, 1.0), (190, 30, 0.9), (230, 30, 0.6), (280, 30, 0.5), (390, 35, 0.4), (460, 35, 0.4)]
    f = 500.0
    while f < 12000:
        f *= 1 + rng.uniform(0.01, 0.035)
        modes.append((f, rng.uniform(30, 60), rng.uniform(0.3, 1.0)))
    ir = np.zeros_like(t)
    for fr, q, a in modes:
        a = a * fr / 200.0 * 30.0 / q
        ir += a * np.exp(-np.pi * fr * t / q) * np.sin(2 * np.pi * fr * t + rng.uniform(0, 2 * np.pi))
    ir /= np.max(np.abs(ir))
    ir[0] += 0.8
    N = 1 << int(np.ceil(np.log2(len(ir) * 2)))
    H = np.fft.rfft(ir, N)
    fq = np.fft.rfftfreq(N, 1 / sr)
    sm = np.exp(np.convolve(np.log(np.abs(H) + 1e-12), np.ones(64) / 64, mode="same"))
    lf = np.log(np.maximum(fq, 1))
    target = (1 + 0.8 * np.exp(-0.5 * ((lf - np.log(150)) / 0.5) ** 2)
              - 0.25 * np.exp(-0.5 * ((lf - np.log(500)) / 0.4) ** 2)
              + 0.3 * np.exp(-0.5 * ((lf - np.log(3000)) / 0.4) ** 2)) / (1 + (fq / 6000.0) ** 2) ** 0.5
    target[fq < 60] = 0.0
    ir = np.fft.irfft(H / sm * target, N)[:len(ir)]
    return ir / np.max(np.abs(ir))


def render(part, sr=common.SR, seed=1972):
    srm = sr * banjo.OVER
    rng = np.random.default_rng(seed)
    n = int(part["length_s"] * srm)
    total = np.zeros(n)
    click = np.zeros(n)
    detune = rng.normal(0, 3.0, 6)  # a guitar in tune, near enough
    for s in range(6):
        evs = []
        for st in part["strokes"]:
            order = [x[0] for x in st["strings"]]
            for i, f, a in st["strings"]:
                if i == s:
                    pos = order.index(i)
                    evs.append((st["t"] + pos * st["spread"] / max(1, len(order) - 1), f, a, st["dir"]))
        # the strokes that leave this string out damp it (the fretting hand lifts off, the other fingers
        # lie across it): a string rings on only through strokes of chords that use it
        mutes = [st["t"] for st in part["strokes"] if s not in [x[0] for x in st["strings"]]
                 and SHAPES.get(st["chord"], [0] * 6)[s] is None]
        midi = np.full(n, float(TUNING[s]))
        exc = np.zeros(n)
        damp = np.ones(n)
        evs.sort()
        for j, (t, f, a, d) in enumerate(evs):
            i0 = int(t * srm)
            if i0 >= n:
                continue
            nxt = int(evs[j + 1][0] * srm) if j + 1 < len(evs) else n
            midi[i0:nxt] = TUNING[s] + f
            k = np.arange(nxt - i0) / srm
            midi[i0:nxt] += 5.0 * a * np.exp(-k / 0.05) / 100.0  # a hard stroke stretches it a moment
            damp[i0:i0 + int(0.002 * srm)] = 0.95  # the pick meets the moving string
            p = banjo._pulse(srm, 0.00018 * rng.uniform(0.8, 1.3), rng) * a * (1.0 if d == "D" else 0.85)
            period = srm / common.hz(TUNING[s] + f)
            lag = int(round(rng.uniform(0.2, 0.3) * period))
            shaped = np.zeros(len(p) + lag)
            shaped[:len(p)] += p
            shaped[lag:lag + len(p)] -= p
            seg = exc[i0:i0 + len(shaped)]
            seg += shaped[:len(seg)] * 0.5
            L = int(0.002 * srm)
            nb = rng.standard_normal(L) * np.exp(-np.arange(L) / (0.0005 * srm))
            cseg = click[i0:i0 + L]
            cseg += 0.015 * a * nb[:len(cseg)]
        for t in mutes:
            i0 = int(t * srm)
            damp[i0:i0 + int(0.04 * srm)] = np.minimum(damp[i0:i0 + int(0.04 * srm)], 0.7)
        f0 = common.hz(midi + detune[s] / 100.0)
        for level, decay, cents in POLS:
            fp = f0 * 2.0 ** (cents / 1200.0)
            t_low = decay * T60_LOW * (82.4 / fp) ** 0.5
            gain, loss = banjo.loop_filter(fp, srm, t_low, decay * T60_HIGH)
            total += level * banjo.run_string(fp, exc, gain, loss, damp, float(srm))
    b, a = butter(2, [2000 / (srm / 2), 9000 / (srm / 2)], "band")
    total += lfilter(b, a, click) * np.std(total) * 3
    y = common.resample(total, srm, sr)
    y = fftconvolve(y, body_ir(sr, seed))[: len(y)]
    b, a = butter(2, 60 / (sr / 2), "high")
    return lfilter(b, a, y)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    part = arrange(sc)
    name = os.path.splitext(os.path.basename(src))[0]
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_guitar.wav"))
    y = render(part)
    common.write_wav(out, common.normalise(y))
    print(f"{out}: {part['tune']}, {len(part['strokes'])} strokes, {part['length_s']} s")


if __name__ == "__main__":
    main()
