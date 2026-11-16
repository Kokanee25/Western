#!/usr/bin/env python3
"""The band heard from somewhere else in Saloon B (Sean, 2026-11-16: "the live sound from the lower floor
of the saloon and from outside"): sections.py --live --place=downstairs|outside hands its stage mix here.
Our own model, from the building's numbers (experiments/building_lab/saloon_b/README.md) and textbook
acoustics (the mass law, Sabine's reverberation, Fletcher & Rossing; Long's Architectural Acoustics on
floors and walls); no copied code.

**Where the band is:** upstairs, in the dance hall (36 x 44 ft, 11 ft high, a floor of boards on bare
3x12 joists, the 14 x 22 ft open well down to the bar room). Nobody stands at a microphone: what leaves
the hall is the hall's own sound, the band and its reverberation together (a bare wooden room, ~1.1 s).
**The dancers:** forty-odd people on the boards, a heel on every beat and many on the off-beat too, a
little early or late; each footfall a knock on the boards and a thump in the joists (the floor's low
modes, ~50-130 Hz). A floor carries a thump far better than it carries a fiddle.

**Downstairs, at the bar** (under the dance hall, not under the well): two ways in. Through the well:
the hall's sound spilling down, a little darker (off to one side, round the well's edge) and a few dB down. Through
the floor: a board floor's mass (~10 kg/m2) lets the lows through and stops the highs (the mass law,
-6 dB an octave), a little of everything leaking through the boards' gaps; and the feet, straight down
the joists, loud. Both then fill the bar room (54 x 44 x 13 ft, wood, men: ~0.8 s) and a murmur of the
men at the bar.
**Outside, across Main Street** (~12 m off the front): the walls (clapboard on studs, plaster inside) pass
the bass and kick and little above ~200 Hz; the open doors and the upper windows let out the hall's
sound, faint and dulled; the false front across the street sends a slap back (~55 ms); the feet only as
a low thud. Around it the night: a little wind, crickets.
"""
import numpy as np
from scipy.signal import butter, fftconvolve, lfilter

import common


def _db(x):
    return 10 ** (x / 20)


def footfall(sr, rng, knock=1.0):
    """One heel on the boards: a short knock (the board, 200-900 Hz) and the joists' thump (a few damped
    modes 50-130 Hz)."""
    n = int(0.25 * sr)
    t = np.arange(n) / sr
    y = np.zeros(n)
    for f, d, a in ((rng.uniform(48, 60), 0.09, 1.0), (rng.uniform(78, 92), 0.06, 0.7), (rng.uniform(115, 135), 0.04, 0.45)):
        y += a * np.exp(-t / d) * np.sin(2 * np.pi * f * t) * (1 - np.exp(-t / 0.003))
    L = int(0.012 * sr)
    k = rng.standard_normal(L) * np.exp(-np.arange(L) / (0.002 * sr))
    k = lfilter(*butter(2, [200 / (sr / 2), 900 / (sr / 2)], "band"), k)
    y[:L] += knock * 0.5 * k / (np.max(np.abs(k)) + 1e-12)
    return y / np.max(np.abs(y))


def feet(beats, n, sr, rng, dancers=44):
    """The dance floor: every dancer's heel on the beat, about half of them on the off-beat as well
    (lighter), each a little early or late."""
    bank = [footfall(sr, rng) for _ in range(16)]
    y = np.zeros(n)
    for j, t in enumerate(beats):
        for t0, who, amp in ((t, dancers, 1.0), (t + 0.5 * (beats[j + 1] - t) if j + 1 < len(beats) else None, dancers // 2, 0.55)):
            if t0 is None:
                continue
            for _ in range(who):
                f = bank[rng.integers(len(bank))]
                i = int((t0 + rng.normal(0.0, 0.018)) * sr)
                if i < 0 or i >= n:
                    continue
                seg = y[i:i + len(f)]
                seg += amp * rng.uniform(0.4, 1.0) * f[:len(seg)]
    return y / (np.max(np.abs(y)) + 1e-12)


def crickets(n, sr, rng, k=5):
    """A few field crickets, each chirping on its own: three or four pulses of a ~4.5 kHz tone, ~15 ms
    each, every half second or so; left to right."""
    L, R = np.zeros(n), np.zeros(n)
    for c in range(k):
        f = rng.uniform(4200, 4900)
        pan = rng.uniform(-0.9, 0.9)
        gain = rng.uniform(0.3, 1.0)
        t = rng.uniform(0, 0.5)
        per = rng.uniform(0.42, 0.7)
        while t < n / sr - 0.2:
            for p in range(rng.integers(3, 5)):
                m = int(0.015 * sr)
                tt = np.arange(m) / sr
                pulse = np.sin(2 * np.pi * f * tt) * np.sin(np.pi * tt / tt[-1]) ** 2
                i = int((t + p * 0.032) * sr)
                th = (pan + 1) * np.pi / 4
                for ch, g in ((L, np.cos(th)), (R, np.sin(th))):
                    seg = ch[i:i + m]
                    seg += gain * g * pulse[:len(seg)]
            t += per * rng.uniform(0.95, 1.05)
    return L, R


def wind(n, sr, rng):
    y = lfilter(*butter(2, 350 / (sr / 2)), rng.standard_normal(n))
    gust = lfilter(*butter(1, 0.15 / (sr / 2)), rng.standard_normal(n))
    y *= 0.6 + 0.4 * np.tanh(gust / (np.std(gust) + 1e-12))
    return y / (np.std(y) + 1e-12)


def _lp(x, f, sr, order=1):
    return lfilter(*butter(order, f / (sr / 2)), x)


def _delay(x, s, sr):
    d = int(s * sr)
    return np.concatenate([np.zeros(d), x[:len(x) - d]])


def _peak(x, f, q, gain_db, sr):
    """A resonance added: the band round f, boosted."""
    bw = f / q
    band = lfilter(*butter(2, [(f - bw / 2) / (sr / 2), (f + bw / 2) / (sr / 2)], "band"), x)
    return x + (_db(gain_db) - 1) * band


def hear(place, L, R, beats, sr, rng, room_ir):
    """The stage mix (L, R: the band and the crowd, dry) as heard at `place`; returns (stereo, target LUFS)."""
    n = len(L)
    rms = np.std(np.concatenate([L, R]))
    # the dance hall's own sound: the band and its reverberation, nobody close to a player
    hl, hr = room_ir(sr, rng, rt60=1.1)
    HL = L + _db(-7) * fftconvolve(L, hl)[:n]
    HR = R + _db(-7) * fftconvolve(R, hr)[:n]
    stomp = feet(beats, n, sr, rng) * rms
    out = []
    if place == "downstairs":
        bl, br = room_ir(sr, rng, rt60=0.8)
        murmur = None
        for H, b in ((HL, bl), (HR, br)):
            well = _delay(_lp(H, 6000, sr, 1), 0.015, sr) * _db(-3)
            floor = _peak(_lp(H, 130, sr, 1), 70, 2.0, 4, sr) * _db(-6) + _lp(H, 2500, sr) * _db(-26)
            step = stomp * _db(-11)
            room = well + floor + step
            x = room + _db(-5) * fftconvolve(room, b)[:n]
            m = lfilter(*butter(2, [250 / (sr / 2), 1800 / (sr / 2)], "band"), rng.standard_normal(n))
            wob = lfilter(*butter(1, 4 / (sr / 2)), rng.standard_normal(n))
            m *= 1 + 0.6 * wob / (np.std(wob) + 1e-12)
            murmur = m / (np.std(m) + 1e-12)
            out.append(x + _db(-30) * rms * murmur)
        target = -12.0
    elif place == "outside":
        ol, orr = room_ir(sr, rng, rt60=0.5)
        cl, cr = crickets(n, sr, rng)
        for H, o, g, c in ((HL, ol, 1.0, cl), (HR, orr, 0.78, cr)):  # the saloon a little to the left
            walls = _lp(_lp(H, 180, sr, 2), 400, sr, 1) * _db(-12)
            openings = _delay(_lp(H, 3500, sr, 1), 0.035, sr) * _db(-13)
            step = _lp(stomp, 140, sr, 2) * _db(-21)
            src = g * (walls + openings + step)
            slap = _delay(_lp(src, 2000, sr), 0.055, sr) * _db(-9)
            x = src + slap + _db(-16) * fftconvolve(src, o)[:n]
            out.append(x + _db(-38) * rms * wind(n, sr, rng) + _db(-34) * rms * c / (np.std(c) + 1e-12))
        target = -17.0
    else:
        raise ValueError(place)
    return np.stack(out, axis=1), target


def level_and_limit(y, sr, target):
    """Up (or down) to the target loudness, the peaks held under -1 dBFS by a short look-ahead limiter."""
    from scipy.ndimage import minimum_filter1d
    y = y * _db(target - common.loudness(y.mean(axis=1), sr))
    need = np.minimum(1.0, _db(-1) / (np.max(np.abs(y), axis=1) + 1e-12))
    need = minimum_filter1d(need, size=2 * int(0.005 * sr) + 1)
    sm = np.empty_like(need)
    cur, a = 1.0, np.exp(-1 / (0.08 * sr))
    for i, v in enumerate(need):
        cur = v if v < cur else a * cur + (1 - a) * v
        sm[i] = cur
    return y * sm[:, None]
