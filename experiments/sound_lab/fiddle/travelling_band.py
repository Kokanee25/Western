#!/usr/bin/env python3
"""The travelling band (#822): the cornet and drums (our own models, cornet.py and drums.py) added
to the band's parts as the game has them (assets/audio/band/<tune>/*.ogg, rendered by
tools/band/render_band.py from the same note data), mixed dry at the band's levels: the fiddle at
-20 LUFS, the cornet 2 dB under it, the drums 7 under.

    python3 experiments/sound_lab/fiddle/travelling_band.py payday_night [--out=...wav]
"""
import json
import os
import subprocess
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
import cornet  # noqa: E402
import drums  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
LEVELS = {"cornet": -2.0, "drums": -7.0}  # against the fiddle's -20 LUFS


def ogg(path):
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", path, "-f", "f32le", "-ac", "1", "-ar", str(common.SR), "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)


def main():
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    tune = [a for a in sys.argv[1:] if not a.startswith("--")][0]
    sc = json.load(open(os.path.join(HERE, tune + ".json")))
    folder = os.path.join(common.ROOT, "assets", "audio", "band", tune)
    parts = [ogg(os.path.join(folder, f)) for f in sorted(os.listdir(folder)) if f.endswith(".ogg")]
    c, _, _ = cornet.render_part(cornet.arrange(sc))
    d = drums.render(drums.arrange(drums.beats_of(sc), intro=False))[0]
    parts.append(common.normalise(c, target=-20.0 + LEVELS["cornet"]))
    parts.append(common.normalise(d, target=-20.0 + LEVELS["drums"]))
    y = np.zeros(max(len(p) for p in parts))
    for p in parts:
        y[:len(p)] += p
    out = opt.get("out", os.path.join(common.BUILD, "dry", tune + "_travelling_band.wav"))
    common.write_wav(out, y)
    print(f"{out}: {len(y) / common.SR:.1f} s, peak {np.max(np.abs(y)):.2f}")


if __name__ == "__main__":
    main()
