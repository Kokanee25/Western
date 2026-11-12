#!/usr/bin/env python3
"""The saloon piano (#790): an upright in a saloon, worn and a little out of tune, playing a tune's
melody over an oom-pah bass from the same note data as the fiddle. Our own model from the physics,
no copied code.

    python3 experiments/sound_lab/fiddle/piano.py oh_susanna.json [--out=...wav] [--part=OUT.json]

**The instrument:** an upright (short strings, stiffer for their length), each note one wound string
in the bass, two in the tenor, three from the middle up. It hasn't seen a tuner in a while: each
note a few cents off, and its strings off one another (the "honky-tonk" chorus is the unisons
beating). Its hammers' felt has gone hard, so it's brighter and harder than a parlour grand.

**The sound (the model):** each string is a set of partials. A stiff string's partials run sharp of
whole multiples, more so the higher (f_n = n f0 sqrt(1 + B n^2); B from an upright's short scale,
large in the bass and the top). The hammer's felt is a stiffening spring, so the harder it strikes,
the shorter it stays on the string (from ~4 ms in the bass to under 1 ms at the top, shorter still
for a hard blow): the force pulse's spectrum sets which partials it wakes, which is why a loud note
is a bright one. It strikes ~1/8 of the way along, so the partials with a node there are missing.
Each partial dies at its own rate (the losses grow with frequency) and in two stages: the strings
of a note, slightly apart, first drain fast into the bridge together, then ring on quietly (the
aftersound; Weinreich, 1977). A key let go drops its damper (the top notes have none). The bridge
drives the soundboard and the case: a few strong low modes and a dense set above. Each key also
knocks: the hammer's thump and the key hitting its bed, a short low thud under the note. Ideas from
Askenfelt & Jansson's hammer measurements, Fletcher's inharmonicity, Weinreich's coupled strings
and Bank's modal piano; the code is ours.

**How he plays (the part):** the saloon style of the time: the left hand a bass note on the beat
(root, then the fifth, an octave under it on the strong beats) and a chord off the beat (the
"oom-pah"), the right hand the tune, a third or sixth under it on the long strong notes, an octave
on the strongest; the melody a hair ahead of the bass, as pianists play it.
"""
import json
import os
import sys
import zlib

import numpy as np
from numba import njit
from scipy.signal import butter, fftconvolve, lfilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
import rhythm  # noqa: E402
import tune  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_OF_TUNE = 6.0      # cents: each note off true (s.d.)
UNISON = 7.0           # cents: a note's strings off one another (s.d.): the honky-tonk
HARD_FELT = 0.7        # the felt gone hard: its contact time x this
STRIKE = 1.0 / 8.0     # where the hammer meets the string
SYMPATHY = 0.025      # how strongly the unstruck strings answer (against the struck ones)
WORN = 1.5             # dB: each key a little off even (fixed per key)
AFTER = 0.12           # the aftersound's share (Weinreich's second stage)
ROOTS = {"C": 48, "D": 50, "E": 52, "F": 53, "G": 43, "A": 45, "B": 47}


def strings_for(midi):
    return 1 if midi < 34 else (2 if midi < 48 else 3)


def inharm(midi):
    """B, the stiffness coefficient: ~2e-4 mid-keyboard, rising to ~3e-3 at the top; and rising
    again in an upright's short bass."""
    b = 10 ** (-3.7 + 0.022 * (midi - 60))
    if midi < 40:
        b *= 1 + ((40 - midi) / 10.0) ** 2
    return b


def t60(f):
    """The note's long ring (the aftersound's), s: ~14 at A1, ~8 at C4, ~2 at C7; a worn upright."""
    return float(np.clip(9.0 * (262.0 / f) ** 0.6, 0.6, 16.0))


_PULSES = {}


def hammer_force(midi, vel):
    """The hammer's push on the string: how long it stays on is what's measured on real pianos
    (Askenfelt & Jansson, 1990/91: ~4 ms in the low bass at an ordinary touch, ~2 at middle C, ~1
    two octaves up, ~0.7 near the top), a little shorter for a harder blow (felt stiffens as it's
    squeezed) and for this piano's hard felt; its shape a half-sine sharpened by the felt; and on it
    the jolts of the wave coming back from the near end (the agraffe) every beta x period, which is
    where a struck string's brightness comes from, sharper the harder the blow. (A hammer-and-string
    simulation was tried first: with the string as a line that passes the wave through, it held
    middle C on for ~4 ms however hard the felt; it needs the string modelled under the hammer.)
    The push's peakedness and the jolts' size and width are fitted so middle C's partials match a
    piano's (Fletcher's measurements: an ordinary touch's 5th-7th partials ~10 dB under the
    fundamental, its 10th-12th ~25; a soft one ~20 and ~35; a hard one ~5 and ~18): fitted, ~-11/-22,
    -21/-31 and -9/-14. Returns (force, dt)."""
    key = (midi, round(vel, 2))
    if key in _PULSES:
        return _PULSES[key]
    f0 = float(common.hz(midi))
    tau = float(np.interp(midi, [21, 36, 60, 84, 96, 108], [5.5, 4.0, 2.0, 1.0, 0.7, 0.5])) * 1e-3
    tau *= (max(vel, 0.1) / 0.7) ** -0.4 * HARD_FELT ** 0.5
    dt = 2.5e-6
    t = np.arange(int(tau / dt) + 1) * dt
    F = np.clip(np.sin(np.pi * t / tau), 0, None) ** 2.0  # the felt stiffening: a peaked push
    t_ref = STRIKE / f0
    w = 4e-5
    r = 1.0 + 2.0 * vel  # the jolts: the shape and these two fitted to a piano's tone (below)
    k = 1
    while k * t_ref < tau:
        F = F * (1.0 + r * np.exp(-0.5 * ((t - k * t_ref) / w) ** 2) * (0.8 ** (k - 1)))
        k += 1
    F = F * (0.5 + 4.5 * vel ** 1.5)
    _PULSES[key] = (F, dt)
    return F, dt


def pulse_spectrum_at(midi, vel, f):
    """The push's spectrum at frequencies f (its magnitude, 1 at its peak)."""
    F, dt = hammer_force(midi, vel)
    t = np.arange(len(F)) * dt
    P = np.abs(np.exp(-2j * np.pi * np.outer(f, t)) @ F)
    return P / (P.max() + 1e-12)


@njit(cache=True)
def _add_string(out, i0, n, sr, freqs, amps, s_fast, s_slow, after, phases, off, tau_d):
    """Add one string's partials into out from i0: each partial a recursive oscillator, its level
    two decays (fast, then the aftersound), damped from sample `off` (relative) with time tau_d."""
    for k in range(freqs.shape[0]):
        w = 2.0 * np.pi * freqs[k] / sr
        c, s = np.cos(w), np.sin(w)
        re, im = np.cos(phases[k]), np.sin(phases[k])
        gf = np.exp(-s_fast[k] / sr)
        gs = np.exp(-s_slow[k] / sr)
        ef = amps[k] * (1.0 - after)
        es = amps[k] * after
        gd = np.exp(-1.0 / (tau_d * sr)) if tau_d > 0 else 1.0
        d = 1.0
        for j in range(n):
            idx = i0 + j
            if idx >= out.shape[0]:
                break
            out[idx] += (ef + es) * d * im
            r2 = re * c - im * s
            im = re * s + im * c
            re = r2
            ef *= gf
            es *= gs
            if j >= off:
                d *= gd
            if (ef + es) * d < 1e-7 * amps[0] + 1e-12:
                break


_VOICING = {}


def voicing(sr):
    """The technician's pass: each key struck alone at an ordinary touch through the soundboard, its
    loudness measured, its gain set so the scale runs even (the bass ~3 dB over the top). Done once."""
    if sr in _VOICING:
        return _VOICING[sr]
    path = os.path.join(HERE, "piano_voicing.json")
    if os.path.exists(path):
        saved = json.load(open(path))
        if saved.get("sr") == sr:
            _VOICING[sr] = {int(k): v for k, v in saved["gains"].items()}
            return _VOICING[sr]
    gains = {}
    rng = np.random.default_rng(7)
    ir = board_ir(sr)
    for m in range(21, 109):
        e = []
        for _ in range(4):  # four strikes: one alone is ~2 dB either way (its strings' beating)
            out = np.zeros(int(0.9 * sr))
            play_note(out, sr, rng, m, 0.0, 0.5, 0.7, 0.0, gain=1.0)
            y = fftconvolve(out, ir)[:len(out)]
            e.append(10 ** (common.loudness(y[:int(0.6 * sr)], sr) / 10.0))
        L = 10 * np.log10(np.mean(e))
        gains[m] = 10 ** ((1.5 * (60 - m) / 40.0 - L - 20.0) / 20.0)
    _VOICING[sr] = gains
    json.dump({"sr": sr, "note": "piano.voicing(): each key's gain; delete to voice again after changing the model",
               "gains": {str(k): round(v, 6) for k, v in gains.items()}}, open(path, "w"), indent=1)
    return gains


def play_note(out, sr, rng, midi, t, dur, vel, detune, pedal=False, gain=None):
    """Strike one key at time t, held dur (s), velocity 0-1."""
    if gain is None:  # (the voicing pass plays with gain=1)
        worn = np.random.default_rng(2000 + midi).normal(0, WORN)  # a worn piano's keys aren't quite even
        gain = voicing(sr)[midi] * 10 ** (worn / 20.0)
    i0 = int(t * sr)
    f0 = common.hz(midi + detune / 100.0)
    b = inharm(midi)
    damped = midi < 89 and not pedal
    tau_d = (0.1 + 0.4 * (89 - midi) / 68.0) if damped else 0.0  # felt dampers, not a gate
    off = int(dur * sr)
    ring = t60(f0)
    n = int(min(ring * 1.2, dur + (6 * tau_d if damped else ring)) * sr) + 1
    key = np.random.default_rng(1000 + midi)  # the key's own: how its strings are tuned, its hammer's line
    unis = [0.0] + list(key.normal(0, UNISON, 2))
    line = STRIKE * key.uniform(0.95, 1.05)
    ph0 = rng.uniform(0, 2 * np.pi, 64)  # one hammer strikes all a note's strings at once: they start in step
    stiff = key.uniform(0.94, 1.06, 3)  # no two strings of a note alike: each overtone beats its own way
    for k in range(strings_for(midi)):
        fs = f0 * 2 ** (unis[k] / 1200.0)
        bk = b * stiff[k]
        nmax = int(min(60, 18000.0 / fs))
        nn = np.arange(1, nmax + 1)
        fn = nn * fs * np.sqrt(1 + bk * nn ** 2)
        keep = fn < 18000.0
        nn, fn = nn[keep], fn[keep]
        a = pulse_spectrum_at(midi, vel, fn) * np.abs(np.sin(nn * np.pi * line * rng.uniform(0.995, 1.005)))
        # each string's energy set by the blow (and the key's voicing); the blow's brightness stays
        # in the shape
        a *= gain * vel ** 1.2 / (np.sqrt(np.sum(a ** 2)) + 1e-12)
        # losses: each partial's long ring, shorter with frequency (air, the felt-less copper's
        # losses: sigma = b1 + b3 f^2); the first stage three times faster
        s_slow = 6.91 / ring * (1.0 + (fn / 2500.0) ** 2)
        s_fast = 3.0 * s_slow
        ph = ph0[:len(fn)]
        _add_string(out, i0, n, float(sr), fn, a / np.sqrt(strings_for(midi)), s_fast, s_slow, AFTER, ph, off, tau_d)


def knocks(n, events, sr, rng):
    """Each key's knock: the hammer's thump and the key on its bed, a short low thud."""
    y = np.zeros(n)
    L = int(0.03 * sr)
    tt = np.arange(L) / sr
    for e in events:
        i = int(e["t"] * sr)
        if i + L > n:
            continue
        f = rng.uniform(110, 260)
        y[i:i + L] += e["vel"] * np.exp(-tt / 0.008) * np.sin(2 * np.pi * f * tt) * rng.uniform(0.7, 1.0)
    return y


_SYM = {}


def sympathetic(sr, length=4.0):
    """What the unstruck strings answer: every string's first partials (to 6 kHz), each ringing at
    its own pitch and fading as a string does; as an impulse response the bridge's signal drives.
    Returns (all strings, the undamped top ones)."""
    if sr in _SYM:
        return _SYM[sr]
    rng = np.random.default_rng(1881)
    t = np.arange(int(length * sr)) / sr
    out = []
    for lo in (21, 89):
        ir = np.zeros(len(t))
        for m in range(lo, 109):
            f0 = float(common.hz(m + rng.normal(0, OUT_OF_TUNE) / 100.0))
            for k in range(1, 7):
                f = k * f0 * np.sqrt(1 + inharm(m) * k * k)
                if f > 6000:
                    break
                sg = 6.91 / (0.5 * t60(f0)) * (1 + (f / 2500.0) ** 2)
                ir += np.exp(-sg * t) * np.sin(2 * np.pi * f * t + rng.uniform(0, 2 * np.pi)) / k
        out.append(ir / (np.sqrt(np.sum(ir ** 2)) + 1e-12))
    _SYM[sr] = tuple(out)
    return _SYM[sr]


def board_ir(sr, seed=1880, length=0.25):
    """The soundboard and case: a few strong low modes (the board's, and the case's box near
    150-250 Hz) and a dense set above, falling past ~4 kHz."""
    rng = np.random.default_rng(seed)
    t = np.arange(int(length * sr)) / sr
    modes = [(f, rng.uniform(25, 45), rng.uniform(0.6, 1.0)) for f in (62, 95, 128, 168, 205, 240)]
    f = 260.0
    while f < 12000:
        f *= 1 + rng.uniform(0.01, 0.04)
        modes.append((f, rng.uniform(30, 70), rng.uniform(0.3, 1.0) * (1.0 if f < 4000 else (4000 / f) ** 1.5)))
    ir = np.zeros_like(t)
    for fr, q, a in modes:
        a = a * fr / 300.0 * 40.0 / q  # each mode's peak height a (see banjo.head_ir)
        ir += a * np.exp(-np.pi * fr * t / q) * np.sin(2 * np.pi * fr * t + rng.uniform(0, 2 * np.pi))
    ir /= np.max(np.abs(ir))
    ir[0] += 1.0  # the bridge's own share, straight through
    # its overall shape set, its detail kept: the modes' peaks and dips over a smooth curve (a little
    # body from the case round 100-400 Hz, level to 3 kHz, falling past 4 kHz)
    N = 1 << int(np.ceil(np.log2(len(ir) * 2)))
    H = np.fft.rfft(ir, N)
    f = np.fft.rfftfreq(N, 1 / sr)
    mag = np.abs(H) + 1e-12
    sm = np.exp(np.convolve(np.log(mag), np.ones(64) / 64, mode="same"))  # ~1/3 octave at 1 kHz
    target = (1 + 0.6 * np.exp(-0.5 * (np.log(np.maximum(f, 1) / 200.0) / 0.7) ** 2)) / (1 + (f / 4000.0) ** 2) ** 0.5
    target[f < 40] = 0.0
    ir = np.fft.irfft(H / sm * target, N)[:len(ir)]
    return ir / np.max(np.abs(ir))


# --------------------------------------------------------------------------------------- the part

def key_of(sc):
    mel = [n for n in sc["notes"] if n["voice"] == "melody"]
    return {0: "C", 2: "D", 4: "E", 5: "F", 7: "G", 9: "A", 11: "B"}.get(mel[-1]["midi"] % 12, "D")


def arrange(sc, seed=None):
    """The pianist's part: keys {t, midi, dur, vel, hand}."""
    if seed is None:
        seed = 1880 + zlib.crc32(sc["tune"].encode()) % 100000
    rng = np.random.default_rng(seed)
    when, beats, last, unit = rhythm.grid(sc)
    mel = sorted([n for n in sc["notes"] if n["voice"] == "melody"], key=lambda n: n["unit"])
    key = key_of(sc)
    chords = sc.get("chords") or [key] * (mel[-1]["bar"] + 1)
    keys = []
    # the right hand: the tune, in the piano's singing middle (C5 or so); a third or sixth under it
    # on the long strong notes, the octave under it on the strongest
    shift = 12 * round((76 - np.median([n["midi"] for n in mel])) / 12)
    for k, n in enumerate(mel):
        m = n["midi"] + shift
        t = n["t"] - 0.008 + rng.normal(0, 0.005)  # the melody a hair ahead
        nxt = mel[k + 1]["t"] if k + 1 < len(mel) else n["t"] + n["dur"]
        dur = max(0.06, min(n["dur"] * 1.05, nxt - n["t"] + 0.02))
        vel = float(np.clip(0.55 + 0.3 * n.get("accent", 0.7) + rng.normal(0, 0.05), 0.3, 0.95))
        keys.append({"t": t, "midi": m, "dur": dur, "vel": vel, "hand": "right"})
        bar = n["bar"]
        pcs = {x % 12 for x in tune.CHORD_TONES[chords[min(bar, len(chords) - 1)]]}
        if n["dur"] >= 0.3 and n.get("accent", 0) >= 0.9:
            under = [m - i for i in (3, 4, 8, 9) if (m - i) % 12 in pcs]
            if under:
                keys.append({"t": t + 0.004, "midi": under[0], "dur": dur, "vel": vel * 0.75, "hand": "right"})
            if n["dur"] >= 0.6 and rng.random() < 0.5:
                keys.append({"t": t + 0.002, "midi": m - 12, "dur": dur, "vel": vel * 0.8, "hand": "right"})
    # the left hand: oom on the beat, pah off it
    for i, (u0, bar_start, phrase_end) in enumerate(beats):
        if when(u0) < rhythm.LEAD - 1e-6:
            continue
        bar = next((n["bar"] for n in mel if n["unit"] >= u0 - 1e-6), mel[-1]["bar"])
        ch = chords[min(bar, len(chords) - 1)]
        root = ROOTS[ch]
        bass = root if (i % 2 == 0) else root + 7 - 12 * (root + 7 > 52)  # root, then the fifth
        t = when(u0) + rng.normal(0, 0.006)
        beat_len = when(u0 + 2) - when(u0)
        keys.append({"t": t, "midi": bass, "dur": beat_len * 0.9, "vel": 0.62 + 0.08 * bar_start, "hand": "left"})
        if bar_start:
            keys.append({"t": t + 0.003, "midi": bass - 12, "dur": beat_len * 0.9, "vel": 0.5, "hand": "left"})
        # the chord: close, round middle C, its voicing turned now and then (a hand, not a stamp),
        # sometimes rolled, the last note of it a touch louder
        lo = 52 + (3 if rng.random() < 0.35 else 0) - (2 if rng.random() < 0.2 else 0)
        tri = sorted({lo + ((p - lo) % 12) for p in tune.CHORD_TONES[ch]})
        tc = when(u0 + 2) + rng.normal(0, 0.007)
        spread = rng.uniform(0.012, 0.025) if rng.random() < 0.2 else 0.006
        for j, p in enumerate(tri):
            keys.append({"t": tc + j * spread * rng.uniform(0.5, 1.0), "midi": int(p), "dur": beat_len * 0.55,
                         "vel": 0.4 + 0.04 * (j == len(tri) - 1) + rng.normal(0, 0.04), "hand": "left"})
    # the end: the tonic, low and full, held
    tl = when(last)
    r = ROOTS[key]
    for p in (r - 12, r, r + 7, r + 12, r + 16):  # root low, root, fifth, root, the third above
        keys.append({"t": tl + rng.uniform(0, 0.01), "midi": p, "dur": 2.5, "vel": 0.6, "hand": "left"})
    # a player's left hand drifts a little against the beat (a slow wander, ~10 ms), and each phrase
    # of four bars swells and eases (+-10%), over a slow random lean
    drift = np.cumsum(rng.normal(0, 0.003, 4096)); drift -= np.convolve(drift, np.ones(9) / 9, mode="same")
    for j, e in enumerate(keys):
        if e["hand"] == "left":
            e["t"] += float(np.clip(drift[j % 4096], -0.012, 0.012))
    span = max(e["t"] for e in keys)
    lean = np.cumsum(rng.normal(0, 0.02, 64)); lean = 0.06 * lean / (np.abs(lean).max() + 1e-9)
    phrase = 8 * 4 * unit * 1.0  # four bars of the tune's running notes
    for e in keys:
        arc = 0.1 * np.sin(np.pi * ((e["t"] - rhythm.LEAD) % phrase) / phrase)
        e["vel"] = float(np.clip(e["vel"] * (0.95 + arc + lean[int(63 * e["t"] / (span + 1e-9))]), 0.15, 1.0))
    # the pedal: down just after each bar's bass note, up just before the next (each beat in a slow tune)
    starts = [when(u0) for u0, bs, _ in beats if when(u0) >= rhythm.LEAD - 1e-6 and bs]
    if len(starts) > 1 and np.median(np.diff(starts)) > 1.6:
        starts = [when(u0) for u0, bs, _ in beats if when(u0) >= rhythm.LEAD - 1e-6]
    starts.append(when(last))
    pedal = [[round(a + rng.uniform(0.04, 0.08), 4), round(b - rng.uniform(0.02, 0.04), 4)] for a, b in zip(starts, starts[1:])]
    pedal.append([round(when(last) + 0.05, 4), round(when(last) + 3.0, 4)])
    keys.sort(key=lambda e: e["t"])
    return {"tune": sc["tune"], "instrument": "saloon upright piano", "key": key, "seed": seed,
            "length_s": round(max(e["t"] + e["dur"] for e in keys) + 3.0, 3), "keys": keys, "pedal": pedal}


def render(part, sr=common.SR, seed=None):
    rng = np.random.default_rng(part.get("seed", 1880) if seed is None else seed)
    n = int(part["length_s"] * sr)
    out = np.zeros(n)
    detune = {m: rng.normal(0, OUT_OF_TUNE) for m in range(21, 109)}  # each key's own wrongness
    pedal = part.get("pedal", [])

    def released(t):  # with the pedal down the dampers stay off until it comes up
        for a, b in pedal:
            if a <= t < b:
                return b
        return t
    falls = []
    for e in part["keys"]:
        r = released(e["t"] + e["dur"])
        play_note(out, sr, rng, e["midi"], e["t"], r - e["t"], e["vel"], detune[e["midi"]])
        if e["midi"] < 89:
            falls.append((r, e["vel"]))
    # the strings that aren't struck: with the dampers off (the pedal) every string answers what the
    # bridge plays it, at its own partials, and rings on; the top strings have no dampers and always do
    gate = np.zeros(n)
    for a, b in pedal:
        gate[int(a * sr):int(b * sr)] = 1.0
    gate = lfilter(*butter(1, 20 / (sr / 2)), gate)
    sym_all, sym_top = sympathetic(sr)
    out = out + SYMPATHY * (fftconvolve(out * gate, sym_all)[:n] + 0.3 * fftconvolve(out, sym_top)[:n])
    y = fftconvolve(out, board_ir(sr))[:n]
    # each damper's felt settling back on its strings: a faint soft thud
    d = np.zeros(n)
    L = int(0.02 * sr)
    for t, v in falls:
        i = int(t * sr)
        if i + L < n:
            d[i:i + L] += v * rng.standard_normal(L) * np.exp(-np.arange(L) / (0.004 * sr))
    d = lfilter(*butter(2, [150 / (sr / 2), 1200 / (sr / 2)], "band"), d)
    y = y + 0.012 * np.std(y) / (np.std(d) + 1e-12) * d
    k = knocks(n, [{"t": e["t"], "vel": e["vel"]} for e in part["keys"]], sr, rng)
    y = y + 0.06 * np.std(y) / (np.std(k) + 1e-12) * k
    b, a = butter(2, 40 / (sr / 2), "high")
    return lfilter(b, a, y)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    part = arrange(sc)
    if "part" in opt:
        json.dump(part, open(opt["part"], "w"), indent=1)
    name = os.path.splitext(os.path.basename(src))[0]
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_piano.wav"))
    y = render(part)
    common.write_wav(out, common.normalise(y))
    hands = {}
    for e in part["keys"]:
        hands[e["hand"]] = hands.get(e["hand"], 0) + 1
    print(f"{out}: {part['tune']} in {part['key']}, {hands}, {part['length_s']} s")


if __name__ == "__main__":
    main()
