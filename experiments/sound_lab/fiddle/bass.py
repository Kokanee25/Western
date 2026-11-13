#!/usr/bin/env python3
"""The upright bass, plucked (Sean, 2026-11-13: under the Caamp-style songs): a double bass played
pizzicato, from a song's chords over the beat grid. Our own model, the banjo's strings again
(banjo.run_string, banjo.loop_filter) on a big wooden body; no copied code.

    python3 experiments/sound_lab/fiddle/bass.py porch_light.json [--out=...wav] [--style=folk|drive]

**The instrument:** four long heavy strings, E1 A1 D2 G2, plucked with the side of a finger: a wide,
soft pluck (~2.5 ms of flesh) low on the fingerboard, so the note is round, its highs gone almost at
once (a partial near 1 kHz rings ~0.2 s: its woody thwack, which a phone's small speaker still carries) while the fundamental thrums on, and the fingers lift each
note off before the next. The body: a big box with the air's mode ~60 Hz, the top's ~100, a few more up
to ~250, then the wood falling away past ~1.5 kHz (Askenfelt's double-bass measurements).

**How he plays:** "folk": the chord's root on beat one, its fifth on three (each held most of two beats),
and in the bar before a change, a walk into the next root on beat four (a step from below or above);
"drive": every beat, root, root, fifth, and the walk on four.
"""
import json
import os
import sys

import numpy as np
from scipy.signal import butter, fftconvolve, lfilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import banjo  # noqa: E402
import common  # noqa: E402
import rhythm  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
TUNING = [28, 33, 38, 43]                     # E1 A1 D2 G2
ROOT = {"C": 36, "C#": 37, "Db": 37, "D": 38, "Eb": 39, "E": 40, "F": 41, "F#": 42, "Gb": 42, "G": 43,
        "Ab": 44, "A": 33, "Bb": 34, "B": 35}
STYLE = "folk"


def root_of(ch):
    name = ch[:-1] if ch.endswith("m") else ch
    r = ROOT.get(name, 38)
    return r if r <= 43 else r - 12


def arrange(sc, seed=1964):
    """The bassist's part: notes {t, dur, midi, amp} on the song's quarter-note beats."""
    rng = np.random.default_rng(seed)
    when, beats, last, unit = rhythm.grid(sc)
    starts = sc.get("bar_units") or []
    chords = sc.get("chords") or ["G"]
    notes = []
    for b, u in enumerate(starts):
        ch = chords[min(b, len(chords) - 1)]
        nxt = chords[min(b + 1, len(chords) - 1)]
        r = root_of(ch)
        fifth = r + 7 if r + 7 <= 47 else r - 5
        final = b == len(starts) - 1
        if final:
            plan = [(0, r, 8, 1.0)]
        elif STYLE == "drive":
            plan = [(0, r, 2, 1.0), (2, r, 2, 0.8), (4, fifth, 2, 0.9), (6, r, 2, 0.8)]
        else:
            plan = [(0, r, 4, 1.0), (4, fifth, 4, 0.85)]
        if not final and nxt != ch:  # walk into the next chord on beat four
            n_r = root_of(nxt)
            walk = n_r - 1 if rng.random() < 0.6 else n_r + 2  # a half step from below, or a step from above
            plan = [p for p in plan if p[0] < 6] + [(6, walk, 2, 0.8)]
            plan = [(k, m, (6 - k) if k < 6 and k + d > 6 else d, a) for k, m, d, a in plan]
        for k, m, d, a in plan:
            t0 = when(u + k)
            t1 = when(u + k + d)
            notes.append({"t": round(float(t0 + rng.normal(0, 0.006)), 4), "dur": round(float((t1 - t0) * 0.88), 4),
                          "midi": int(m), "amp": round(float(a * np.exp(rng.normal(0, 0.07))), 3)})
    notes.sort(key=lambda n: n["t"])
    return {"tune": sc["tune"], "instrument": "upright bass, pizzicato", "style": STYLE, "seed": seed,
            "length_s": round(notes[-1]["t"] + notes[-1]["dur"] + 2.5, 3), "notes": notes}


def place(midi):
    """The string a note goes on: the highest string it's at or above, within the first seven frets."""
    for s in (3, 2, 1, 0):
        if TUNING[s] <= midi <= TUNING[s] + 7:
            return s, midi - TUNING[s]
    return 0, max(0, midi - TUNING[0])


def body_ir(sr, seed=1964, length=0.35):
    rng = np.random.default_rng(seed)
    t = np.arange(int(length * sr)) / sr
    modes = [(60, 12, 1.0), (100, 18, 0.9), (130, 20, 0.6), (180, 25, 0.5), (250, 25, 0.4)]
    f = 280.0
    while f < 8000:
        f *= 1 + rng.uniform(0.015, 0.04)
        modes.append((f, rng.uniform(25, 50), rng.uniform(0.3, 1.0) * (1.0 if f < 1500 else (1500 / f) ** 1.5)))
    ir = np.zeros_like(t)
    for fr, q, a in modes:
        a = a * fr / 100.0 * 20.0 / q
        ir += a * np.exp(-np.pi * fr * t / q) * np.sin(2 * np.pi * fr * t + rng.uniform(0, 2 * np.pi))
    ir /= np.max(np.abs(ir))
    ir[0] += 1.0
    return ir / np.max(np.abs(ir))


def render(part, sr=common.SR, seed=1964):
    srm = sr * banjo.OVER
    rng = np.random.default_rng(seed)
    n = int(part["length_s"] * srm)
    total = np.zeros(n)
    by_string = {s: [] for s in range(4)}
    for nt in part["notes"]:
        s, f = place(nt["midi"])
        by_string[s].append((nt["t"], nt["dur"], f, nt["amp"]))
    for s, evs in by_string.items():
        if not evs:
            continue
        midi = np.full(n, float(TUNING[s]))
        exc = np.zeros(n)
        damp = np.ones(n)
        for j, (t, d, f, a) in enumerate(sorted(evs)):
            i0 = int(t * srm)
            if i0 >= n:
                continue
            nxt = int(sorted(evs)[j + 1][0] * srm) if j + 1 < len(evs) else n
            midi[i0:nxt] = TUNING[s] + f
            p = banjo._pulse(srm, 0.0025 * rng.uniform(0.85, 1.15), rng) * a
            period = srm / common.hz(TUNING[s] + f)
            lag = int(round(rng.uniform(0.25, 0.35) * period))
            shaped = np.zeros(len(p) + lag)
            shaped[:len(p)] += p
            shaped[lag:lag + len(p)] -= p
            seg = exc[i0:i0 + len(shaped)]
            seg += shaped[:len(seg)] * 0.5
            off = int((t + d) * srm)  # the finger lifts the note off
            damp[off:min(nxt, off + int(0.06 * srm))] = 0.85
        f0 = common.hz(midi)
        for level, decay, cents in ((1.0, 1.0, 0.0), (0.35, 1.6, 0.6)):
            fp = f0 * 2.0 ** (cents / 1200.0)
            gain, loss = banjo.loop_filter(fp, srm, decay * 3.0 * (41.2 / fp) ** 0.3, decay * 0.2, f_high=1000.0)
            total += level * banjo.run_string(fp, exc, gain, loss, damp, float(srm))
    y = common.resample(total, srm, sr)
    y = fftconvolve(y, body_ir(sr, seed))[: len(y)]
    b, a = butter(2, 35 / (sr / 2), "high")
    return lfilter(b, a, y)


def main():
    global STYLE
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    STYLE = opt.get("style", "folk")
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    part = arrange(sc)
    name = os.path.splitext(os.path.basename(src))[0]
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_bass.wav"))
    y = render(part)
    common.write_wav(out, common.normalise(y))
    print(f"{out}: {part['tune']}, {len(part['notes'])} notes ({STYLE}), {part['length_s']} s")


if __name__ == "__main__":
    main()
