#!/usr/bin/env python3
"""A: the fiddle from a sample set (issue #790): VSCO 2 Community Edition's solo violin (CC0,
github.com/sgossner/VSCO-2-CE; CREDITS.md), played from the note data as an old-time fiddler
plays, not as the library's classical player did.

- The sustains (`Arco Vib`, every third or fourth semitone, p and f) are a classical player's,
  with vibrato. Each is read through a pointer that follows the sample's own pitch, measured
  every 5 ms (YIN), so the read speed both moves it to the note and cancels the vibrato: a
  straight old-time tone. The same pointer does the slides and the slurs (a slur is one bow
  stroke: the sample runs on and only its pitch moves, 12 ms between notes, as a finger does).
- Each new bow stroke starts with the bite of a short stroke (`spic`: two takes, two dynamics,
  chosen by the accent and turn about), then the sustain under it; strokes alternate takes and
  start the sustain at different places in it (round-robins), detuned a few cents apart.
- Drones and double stops are their strings' own voices, softer, bowed with the melody's stroke.
- The bow's speed (strokes, note data) shapes the level: rise, hold and ease into the change; when
  the bow leaves a string it rings on (an open string ~0.2 s, a stopped one briefly).
- A last touch toward a fiddle: less low body, more bite at 2-4 kHz.

    python3 experiments/sound_lab/fiddle/samples.py [--out=build/sound_lab/fiddle/dry/A.wav]
                                                    [--samples=DIR (VSCO's 'Strings/Solo Violin')]
"""
import glob
import os
import re
import sys

import numpy as np
from numba import njit
from scipy.signal import butter, lfilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

DEFAULT_DIR = os.path.join(common.BUILD, "vsco", "Strings", "Solo Violin")
NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
HOP = 0.005


def _midi_of(name):
    m = re.match(r"([A-G])(#?)(\d)", name)
    return 12 * (int(m.group(3)) + 1) + NAMES[m.group(1)] + (1 if m.group(2) else 0)


def f0_track(x, sr, nominal_hz, hop=HOP, win=1024):
    """The sample's pitch every `hop` s by YIN on FFT autocorrelation, held near its nominal note
    (a frame further off than 80 cents is taken as the nominal: octave slips, the attack)."""
    h = int(hop * sr)
    tmax = int(sr / (nominal_hz * 0.8))
    tmin = int(sr / (nominal_hz * 1.25))
    frames = range(0, len(x) - win - tmax, h)
    out = np.full(len(frames), nominal_hz)
    nfft = 1 << int(np.ceil(np.log2(win + tmax)))
    for j, a in enumerate(frames):
        seg = x[a:a + win + tmax]
        e = np.cumsum(seg ** 2)
        F = np.fft.rfft(seg, nfft)
        F2 = np.fft.rfft(seg[:win], nfft)
        ac = np.fft.irfft(F * np.conj(F2), nfft)[:tmax + 1]
        energy0 = e[win - 1]
        lag_e = np.array([e[t + win - 1] - (e[t - 1] if t > 0 else 0) for t in range(tmax + 1)])
        d = energy0 + lag_e - 2 * ac
        cm = d[1:] * np.arange(1, tmax + 1) / np.maximum(np.cumsum(d[1:]), 1e-12)
        t = int(np.argmin(cm[tmin - 1:]) + tmin - 1)
        if 1 <= t < len(cm) - 1:
            aa, bb, cc = cm[t - 1], cm[t], cm[t + 1]
            den = aa - 2 * bb + cc
            t = t + 1 + (0.5 * (aa - cc) / den if den != 0 else 0)
        else:
            t += 1
        f = sr / t
        if abs(1200 * np.log2(f / nominal_hz)) < 80:
            out[j] = f
    # a light smoothing: the 5 ms frames' own jitter, not the vibrato (~6 Hz) - that's followed
    pad = np.concatenate([out[:1], out, out[-1:]])
    return (pad[:-2] + pad[1:-1] + pad[2:]) / 3.0


class Bank:
    def __init__(self, folder):
        self.arco = []  # (midi, dyn, x, sr, f0 contour)
        for p in sorted(glob.glob(os.path.join(folder, "Arco Vib", "*.wav"))):
            m = re.search(r"_([A-G]#?\d)_([pf])\.wav$", p)
            midi = _midi_of(m.group(1))
            if not 55 <= midi <= 84:
                continue
            sr, x = common.read_wav(p)
            cache = os.path.join(common.BUILD, "cache", os.path.basename(p) + ".f0.npy")
            if os.path.exists(cache):
                f0 = np.load(cache)
            else:
                f0 = f0_track(x[: int(8 * sr)], sr, float(common.hz(midi)))
                os.makedirs(os.path.dirname(cache), exist_ok=True)
                np.save(cache, f0)
            self.arco.append((midi, m.group(2), x, sr, f0))
        self.spic = []  # (midi (named an octave low in the set), vel, rr, x, sr)
        for p in sorted(glob.glob(os.path.join(folder, "spic", "*.wav"))):
            m = re.search(r"_([A-G]#?\d)_v(\d)_rr(\d)\.wav$", p)
            midi = _midi_of(m.group(1)) + 12
            if not 55 <= midi <= 88:
                continue
            sr, x = common.read_wav(p)
            self.spic.append((midi, int(m.group(2)), int(m.group(3)), x, sr))

    def nearest_arco(self, midi, dyn):
        c = [a for a in self.arco if a[1] == dyn]
        return min(c, key=lambda a: (abs(a[0] - midi), a[0] < midi))

    def nearest_spic(self, midi, vel, rr):
        c = [s for s in self.spic if s[1] == vel and s[2] == rr]
        return min(c, key=lambda s: abs(s[0] - midi))


@njit(cache=True)
def follow(x, sr_s, f0, hop_s, start, ftarget, sr_out):
    """Read `x` from `start` (s) at the speed that turns its own pitch (f0 every hop_s) into
    `ftarget` (Hz per output sample): the vibrato cancelled, the note's pitch and slides drawn."""
    n = ftarget.shape[0]
    y = np.zeros(n)
    pos = start * sr_s
    hop = hop_s * sr_s
    m = x.shape[0]
    for i in range(n):
        k = pos / hop
        k0 = int(k)
        if k0 + 1 >= f0.shape[0] or pos + 3 >= m:
            break
        fs = f0[k0] + (k - k0) * (f0[k0 + 1] - f0[k0])
        p0 = int(pos)
        fr = pos - p0
        if p0 >= 1:
            a, b, c, d = x[p0 - 1], x[p0], x[p0 + 1], x[p0 + 2]
            y[i] = b + 0.5 * fr * (c - a + fr * (2 * a - 5 * b + 4 * c - d + fr * (3 * (b - c) + d - a)))
        pos += (ftarget[i] / fs) * (sr_s / sr_out)
    return y


def segments(sc):
    """Per string, the runs of notes one bow stroke plays on it: (string, [notes], stroke)."""
    out = []
    by = {}
    for nt in sc["notes"]:
        key = (nt["stroke"], nt["string"])
        by.setdefault(key, []).append(nt)
    for (si, s), ns in sorted(by.items(), key=lambda kv: kv[1][0]["t"]):
        ns.sort(key=lambda n: n["t"])
        out.append((s, ns, sc["strokes"][si]))
    return out


def render(sc, folder=DEFAULT_DIR, sr=common.SR, seed=1882, bites=True):
    """`bites`: each new stroke starts with a short stroke's attack (the hybrid, C, takes the
    model's instead)."""
    bank = Bank(folder)
    rng = np.random.default_rng(seed)
    n = common.length_samples(sc, sr)
    out = np.zeros(n)
    bowv = np.abs(common.bow_envelope(sc, sr))
    bowv /= max(bowv.max(), 1e-9)
    take = 0
    for s, ns, st in segments(sc):
        t0 = ns[0]["t"]
        t1 = max(nt["t"] + nt["dur"] for nt in ns)
        # after the bow leaves it the string rings on: an open string ~a quarter second, a stopped
        # one briefly (the finger and the next note damp it)
        ring = 0.22 if ns[-1]["finger"] == 0 else 0.045
        i0, i1 = int(t0 * sr), min(n, int((t1 + 4 * ring) * sr))
        bowed_len = int((t1 - t0) * sr)
        L = i1 - i0
        if L <= 16:
            continue
        # the pitch line over the segment: each note's pitch, 12 ms glides between slurred notes
        pitch = [nt["midi"] + nt.get("cents", 0.0) / 100.0 for nt in ns]
        midi = np.full(L, float(pitch[0]))
        for k, nt in enumerate(ns):
            a = int((nt["t"] - t0) * sr)
            midi[a:] = pitch[k]
            if k > 0:
                g = min(int(0.012 * sr), L - a)
                if g > 0:
                    midi[a:a + g] = pitch[k - 1] + (pitch[k] - pitch[k - 1]) * np.linspace(0, 1, g)
            if nt.get("slide_from"):
                m = min(int(nt["slide_s"] * sr), L - a)
                r = 0.5 - 0.5 * np.cos(np.pi * np.linspace(0, 1, m))
                midi[a:a + m] = nt["slide_from"] + (pitch[k] - nt["slide_from"]) * r
        cents = rng.uniform(-4, 4)
        ft = common.hz(midi + cents / 100.0)
        mel = ns[0]["voice"] == "melody"
        press = max(nt["pressure"] for nt in ns)
        dyn = "f" if press > 0.62 else "p"
        am, _, ax, asr, af0 = bank.nearest_arco(ns[0]["midi"], dyn)
        start = 0.35 + 0.9 * rng.random() + 1.3 * (take % 4)  # round-robin: a different stretch of the sustain
        body = follow(ax, float(asr), af0, HOP, start, ft, float(sr))
        # the sustain enters under the bite: 25 ms rise (a crossing within a slur: 15 ms)
        k = np.arange(L) / sr
        new_stroke = not ns[0]["slur"] and abs(t0 - st["t0"]) < 0.02
        rise = np.clip(k / (0.018 if new_stroke else 0.015), 0, 1)
        bow = 0.6 + 0.4 * bowv[i0:i1]
        after = k > bowed_len / sr
        bow[after] = bow[min(bowed_len, L) - 1] * np.exp(-(k[after] - bowed_len / sr) / ring)
        env = rise * bow
        level = (0.55 + 0.6 * press) * (1.0 if mel else 0.8)
        seg = body * env * level
        if new_stroke and bites:
            vel = 2 if ns[0]["accent"] >= 0.9 else 1
            sm, _, _, sx, ssr = bank.nearest_spic(ns[0]["midi"], vel, 1 + take % 2)
            onset = int(np.argmax(np.abs(sx) > 0.02 * np.abs(sx).max()))
            ratio = float(common.hz(ns[0]["midi"] + cents / 100.0) / common.hz(sm))
            m = min(L, int(0.16 * sr))
            pos = onset + np.arange(m) * ratio * ssr / sr
            pos = pos[pos < len(sx) - 2]
            bite = np.interp(pos, np.arange(len(sx)), sx)
            bite *= np.clip(1 - (np.arange(len(bite)) / sr - 0.04) / 0.1, 0, 1)
            gain_bite = 0.9 * (np.std(body[: int(0.2 * sr)]) + 1e-6) / (np.std(bite[: int(0.05 * sr)]) + 1e-6)
            seg[: len(bite)] += bite * gain_bite * level * (1.0 if mel else 0.6)
            take += 1
        out[i0:i1] += seg
    # toward a fiddle: less low body, more bite
    b, a = butter(2, 160 / (sr / 2), "high")
    y = lfilter(b, a, out)
    b, a = butter(2, [2000 / (sr / 2), 4500 / (sr / 2)], "band")
    y = y + 0.5 * lfilter(b, a, y)
    return y


if __name__ == "__main__":
    out = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--out=")),
               os.path.join(common.BUILD, "dry", "A.wav"))
    folder = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--samples=")), DEFAULT_DIR)
    import time
    t = time.time()
    y = render(common.score(), folder)
    common.write_wav(out, common.normalise(y))
    print(f"{out} ({time.time() - t:.1f} s)")
