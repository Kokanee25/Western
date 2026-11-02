#!/usr/bin/env python3
"""The train's sound film measured (step 4, #571): each section's loudness (RMS and peak, dBFS),
the exhaust's beats a second where they can be told apart (onsets of the low band), and a
spectrogram of the whole soundtrack with the sections marked.

    python3 experiments/train_lab/sound_measure.py FILM.avi BRIDGE_LOG OUTDIR

BRIDGE_LOG is the bridge's output for the film's run (one JSON line a command): the sections are
cut at each `train_caption` by the game's clock (`t`), which the movie keeps (a fixed step).
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

RATE = 22050


def soundtrack(avi):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", avi, "-ac", "1", "-ar", str(RATE), "-f", "s16le", "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0


def sections(log):
    out = []
    for line in open(log):
        line = line.strip()
        if not line.startswith("{"):
            continue
        d = json.loads(line)
        if d.get("cmd", "").startswith("train_caption"):
            out.append((float(d["t"]), d.get("caption", "")))
    return out


def db(x):
    return float(20.0 * np.log10(max(float(x), 1e-6)))


def onsets_per_second(s):
    """Beats a second from the low band's envelope (the chuffs): peaks of its rise."""
    k = int(RATE * 0.01)
    if len(s) < k * 20:
        return 0.0
    # The low band: a moving average (a crude low-pass, ~100 Hz) of the rectified signal's change.
    lo = np.convolve(s, np.ones(64) / 64, mode="same")
    env = np.sqrt(np.convolve(lo * lo, np.ones(k) / k, mode="same"))[::k]
    rise = np.maximum(np.diff(env), 0.0)
    if rise.max() <= 0:
        return 0.0
    thr = rise.mean() + 1.5 * rise.std()
    peaks = [i for i in range(1, len(rise) - 1) if rise[i] > thr and rise[i] >= rise[i - 1] and rise[i] >= rise[i + 1]]
    gaps = [b - a for a, b in zip(peaks, peaks[1:]) if b - a > 2]
    return float(100.0 / np.median(gaps)) if gaps else 0.0


def spectrogram(s, marks, path, width=1600, height=360):
    n = 1024
    hop = max(1, len(s) // width)
    cols = []
    win = np.hanning(n)
    for i in range(0, len(s) - n, hop):
        cols.append(np.abs(np.fft.rfft(s[i:i + n] * win))[: n // 2])
    m = 20 * np.log10(np.array(cols).T + 1e-6)
    m = np.clip((m + 80.0) / 80.0, 0, 1)
    # Log frequency rows, 40 Hz to 11 kHz.
    f = np.linspace(0, RATE / 2, n // 2)
    rows = np.geomspace(40, RATE / 2 - 1, height)[::-1]
    idx = np.searchsorted(f, rows)
    img = (m[idx] * 255).astype(np.uint8)
    im = Image.fromarray(img).resize((width, height)).convert("RGB")
    d = ImageDraw.Draw(im)
    secs = len(s) / RATE
    for t, text in marks:
        x = int(t / secs * width)
        d.line([(x, 0), (x, height)], fill=(255, 200, 0))
        d.text((x + 3, 3), text[:40], fill=(255, 220, 80))
    im.save(path)


def main():
    avi, log, out = sys.argv[1:4]
    os.makedirs(out, exist_ok=True)
    s = soundtrack(avi)
    marks = sections(log)
    secs = len(s) / RATE
    rows = []
    bounds = marks + [(secs, "end")]
    for (t0, name), (t1, _) in zip(bounds, bounds[1:]):
        if not name:
            continue
        seg = s[int(t0 * RATE): int(t1 * RATE)]
        if len(seg) == 0:
            continue
        # The loudest second and the quietest (where the train is nearest and furthest).
        per = [np.sqrt(np.mean(seg[i:i + RATE] ** 2)) for i in range(0, max(1, len(seg) - RATE), RATE // 2)]
        rows.append({"section": name, "from": round(t0, 1), "to": round(t1, 1),
                     "rms_db": round(db(np.sqrt(np.mean(seg ** 2))), 1), "peak_db": round(db(np.abs(seg).max()), 1),
                     "loudest_s_db": round(db(max(per)), 1), "quietest_s_db": round(db(min(per)), 1),
                     "beats_a_s": round(onsets_per_second(seg), 1)})
    json.dump({"seconds": round(secs, 1), "sections": rows}, open(os.path.join(out, "levels.json"), "w"), indent=1)
    spectrogram(s, marks, os.path.join(out, "spectrogram.png"))
    for r in rows:
        print(r)


if __name__ == "__main__":
    main()
