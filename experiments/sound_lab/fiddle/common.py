"""Shared by the fiddle renderers (README.md): the note data, the per-string controls, files."""
import json
import os
import sys

import numpy as np
import scipy.io.wavfile as wavfile
from scipy.signal import resample_poly

HERE = os.path.dirname(os.path.abspath(__file__))
LAB = os.path.dirname(HERE)
ROOT = os.path.dirname(os.path.dirname(LAB))
BUILD = os.path.join(ROOT, "build", "sound_lab", "fiddle")
sys.path.insert(0, LAB)
import measure  # noqa: E402  (the sound lab's K-weighting)

SR = 48000
STRINGS = ["G", "D", "A", "E"]
OPEN = {"G": 55, "D": 62, "A": 69, "E": 76}


def hz(midi):
    return 440.0 * 2.0 ** ((np.asarray(midi, dtype=float) - 69.0) / 12.0)


def score(path=None):
    return json.load(open(path or os.path.join(HERE, "soldiers_joy.json")))


def length_samples(sc, sr=SR, tail=1.2):
    return int((sc["length_s"] + tail) * sr)


def bow_envelope(sc, sr=SR):
    """The bow's speed over time, signed by direction (m/s), and each stroke's start for the
    attacks: a stroke rises in ~18 ms (an accented one digs in faster), holds, and eases for the
    last ~10 ms into the change."""
    n = length_samples(sc, sr)
    v = np.zeros(n)
    for st in sc["strokes"]:
        i0, i1 = int(st["t0"] * sr), int(st["t1"] * sr)
        if i1 <= i0:
            continue
        k = np.arange(i1 - i0) / sr
        L = (i1 - i0) / sr
        rise = np.clip(k / 0.018, 0, 1) ** 0.7
        fall = np.clip((L - k) / 0.012, 0, 1)
        shape = rise * fall * (1.0 - 0.25 * k / max(L, 0.1))  # a stroke slows as it goes
        sign = 1.0 if st["dir"] == "down" else -1.0
        v[i0:i1] = sign * st["speed"] * shape
    return v


def string_controls(sc, sr=SR, release=0.03):
    """Per string: the stopped pitch (Hz, slides included), the bow's force on it (N) and whether a
    finger is down. A string no note is on is open and unbowed (it rings on, as open strings do)."""
    n = length_samples(sc, sr)
    f0 = {s: np.full(n, float(hz(OPEN[s]))) for s in STRINGS}
    force = {s: np.zeros(n) for s in STRINGS}
    stopped = {s: np.zeros(n, dtype=bool) for s in STRINGS}
    for nt in sc["notes"]:
        s = nt["string"]
        i0 = max(0, int(nt["t"] * sr))
        i1 = min(n, int((nt["t"] + nt["dur"]) * sr))
        if i1 <= i0:
            continue
        target = nt["midi"] + nt.get("cents", 0.0) / 100.0
        p = np.full(i1 - i0, target)
        if nt.get("slide_from"):
            m = int(nt["slide_s"] * sr)
            ramp = np.clip(np.arange(i1 - i0) / max(m, 1), 0, 1)
            ramp = 0.5 - 0.5 * np.cos(np.pi * ramp)
            p = nt["slide_from"] + (target - nt["slide_from"]) * ramp
        vib = sc.get("player", {}).get("vibrato_cents", 0.0)
        if vib and nt["voice"] == "melody" and nt["dur"] >= 0.3:
            # a player who leans on the long notes: vibrato (~5.5 Hz), coming in after the note speaks
            kk = np.arange(i1 - i0) / sr
            p = p + vib / 100.0 * np.sin(2 * np.pi * 5.5 * kk) * np.clip((kk - 0.15) / 0.25, 0, 1)
        f0[s][i0:i1] = hz(p)
        stopped[s][i0:i1] = nt["finger"] > 0
        # force: a fiddler's 0.4-1.6 N by pressure; an accent leans in for the first 40 ms
        k = np.arange(i1 - i0) / sr
        lean = 1.0 + 0.35 * nt["accent"] * np.exp(-k / 0.04) * (0 if nt["slur"] else 1)
        fb = (0.35 + 1.25 * nt["pressure"]) * lean
        force[s][i0:i1] = np.maximum(force[s][i0:i1], fb)
        # the finger stays down a moment after (the next note's lift isn't instant)
        j1 = min(n, i1 + int(release * sr))
        if nt["finger"] > 0 and j1 > i1:
            f0[s][i1:j1] = f0[s][i1 - 1]
    return f0, force, stopped


def write_wav(path, x, sr=SR):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) if x.size else 0
    if peak > 0.999:
        x = x * 0.999 / peak
    wavfile.write(path, sr, (x * 32767).astype(np.int16))


def read_wav(path):
    sr, x = wavfile.read(path)
    x = x.astype(np.float64)
    if x.dtype.kind in "iu" or np.max(np.abs(x)) > 2:
        x = x / 32768.0
    if x.ndim == 2:
        x = x.mean(axis=1)
    return sr, x


def loudness(x, sr=SR):
    """Integrated loudness (LUFS) by BS.1770's K-weighting with its gates (-70 absolute, -10 relative),
    400 ms blocks, 75% overlap."""
    kw = measure.k_weight(np.asarray(x, dtype=np.float64), sr)
    blk, hop = int(0.4 * sr), int(0.1 * sr)
    if len(kw) < blk:
        return -120.0
    ms = np.array([np.mean(kw[i:i + blk] ** 2) for i in range(0, len(kw) - blk, hop)])
    l = -0.691 + 10 * np.log10(ms + 1e-20)
    g = ms[l > -70]
    if g.size == 0:
        return -120.0
    rel = -0.691 + 10 * np.log10(np.mean(g)) - 10
    g = ms[(l > -70) & (l > rel)]
    return float(-0.691 + 10 * np.log10(np.mean(g)))


def normalise(x, sr=SR, target=-18.0):
    return x * 10 ** ((target - loudness(x, sr)) / 20.0)


def resample(x, sr_from, sr_to):
    if sr_from == sr_to:
        return x
    from math import gcd
    g = gcd(int(sr_from), int(sr_to))
    return resample_poly(x, int(sr_to) // g, int(sr_from) // g)
