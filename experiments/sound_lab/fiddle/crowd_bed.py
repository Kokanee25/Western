#!/usr/bin/env python3
"""A steady saloon crowd from a short recording (#790, the fiddle heard from outside with the room's
crowd): the cinematic's ElevenLabs take `sfx_room.mp3` (branch claude/cinematic-saloon,
assets/cinematic/audio/; "Quiet 1880s saloon at night: low murmur of men..."; made through fal,
2026-10-26). It's busy for ~2 s and then dies away, so: its first 10 s levelled to one loudness
(a slow gain riding 0.4 s windows), then a bed built of overlapping slices of it (1.2-2.6 s each,
50 ms crossfades, seeded), in three layers at slightly different speeds (0.97, 1.0, 1.03: more
people, not the same ones). A stand-in until a crowd is recorded or generated for the dance.

    python3 experiments/sound_lab/fiddle/crowd_bed.py SRC.wav OUT.wav [--seconds=24]
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402


def level(x, sr, win=0.4, target=-30.0, cap=26.0):
    """Ride the gain so every window sits at `target` (dB RMS), smoothed; at most `cap` dB either way."""
    h = int(win * sr)
    n = len(x) // h
    g = np.ones(n)
    for i in range(n):
        r = np.sqrt(np.mean(x[i * h:(i + 1) * h] ** 2)) + 1e-9
        g[i] = 10 ** (np.clip(target - 20 * np.log10(r), -cap, cap) / 20)
    g = np.convolve(np.pad(g, 2, mode="edge"), np.ones(5) / 5, mode="same")[2:-2]
    gain = np.interp(np.arange(len(x)), (np.arange(n) + 0.5) * h, g)
    return x * gain


def bed(src, sr, seconds, seed=1882):
    rng = np.random.default_rng(seed)
    n = int(seconds * sr)
    out = np.zeros(n)
    fade = int(0.05 * sr)
    for speed in (0.97, 1.0, 1.03):
        layer = np.zeros(n + sr * 3)
        pos = int(rng.uniform(0, 0.5) * sr)
        while pos < n:
            ln = int(rng.uniform(1.2, 2.6) * sr)
            start = int(rng.uniform(0, len(src) - ln / speed - 1))
            idx = start + np.arange(ln) * speed
            g = np.interp(idx, np.arange(len(src)), src)
            w = np.ones(ln)
            w[:fade] = np.sin(np.linspace(0, np.pi / 2, fade)) ** 2
            w[-fade:] = np.cos(np.linspace(0, np.pi / 2, fade)) ** 2
            layer[pos:pos + ln] += g * w
            pos += ln - fade
        out += layer[:n]
    return out / 3 ** 0.5


if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    secs = float(next((a.split("=")[1] for a in sys.argv[3:] if a.startswith("--seconds=")), 24))
    sr, x = common.read_wav(src)
    x = level(x[int(0.45 * sr):int(10.0 * sr)], sr)
    y = level(bed(x, sr, secs), sr, win=0.6)  # and the bed itself ridden level (a crowd doesn't come and go)
    f = int(0.3 * sr)
    y[:f] *= np.linspace(0, 1, f)
    y[-f:] *= np.linspace(1, 0, f)
    common.write_wav(dst, common.normalise(y, sr, -18.0), sr)
    print(dst, f"{len(y) / sr:.1f} s")
