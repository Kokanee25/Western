#!/usr/bin/env python3
"""A banjo bench clip (#790): a dry render at one fixed gain to a common loudness (-22 LUFS: the
banjo's strikes peak ~20 dB over it, so nothing clips), faded at the end, as an mp3. One gain, not
a leveller: the attacks are what's being judged.

    python3 experiments/sound_lab/fiddle/bench_clip.py IN.wav OUT.mp3 [--lufs=-22]
"""
import os
import subprocess
import sys
import tempfile

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

args = [a for a in sys.argv[1:] if not a.startswith("--")]
target = float(next((a.split("=")[1] for a in sys.argv[1:] if a.startswith("--lufs=")), -22))
sr, x = common.read_wav(args[0])
y = x * 10 ** ((target - common.loudness(x, sr)) / 20)
f = int(0.8 * sr)
y[-f:] *= np.linspace(1, 0, f)
peak = np.max(np.abs(y))
with tempfile.TemporaryDirectory() as d:
    tmp = os.path.join(d, "c.wav")
    common.write_wav(tmp, y, sr)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", tmp, "-codec:a", "libmp3lame", "-b:a", "192k", args[1]], check=True)
print(f"{args[1]}: {target} LUFS, peak {20 * np.log10(peak):.1f} dBFS")
