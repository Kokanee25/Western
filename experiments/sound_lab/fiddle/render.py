#!/usr/bin/env python3
"""The fiddle experiment end to end (README.md): the three renders and the reference's excerpt,
each at -18 LUFS, then each played in the game's saloon through the sound lab (up close on the
balcony, and from the bar room under it).

    python3 experiments/sound_lab/fiddle/render.py              # dry renders + the game runs
    python3 experiments/sound_lab/fiddle/render.py --dry        # only the dry renders
    python3 experiments/sound_lab/fiddle/render.py --game       # only the game runs (dry ones made)
    --reference=FILE (the 1922 record; default build/sound_lab/fiddle/ref/sallie_gooden.flac,
    fetched by fetch.sh) --ref-from=100 (s into it) --jobs=1 (two games at once run out of memory here)
"""
import os
import subprocess
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bowed  # noqa: E402
import common  # noqa: E402
import hybrid  # noqa: E402
import samples  # noqa: E402

DRY = os.path.join(common.BUILD, "dry")
GAME = os.path.join(common.BUILD, "game")
SOURCES = ["ref", "A", "B", "C"]
PLACES = ["music_balcony_close", "music_balcony_below"]
REF_LEN = 20.0


def _opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
        if a == f"--{name}":
            return True
    return default


def reference(path, start):
    """The record from `start` s for 20 s, faded 0.3 s at each end, mono at 48 kHz, as it is
    (the surface noise and the horn's band left in: it's the target, not a clean copy)."""
    tmp = os.path.join(common.BUILD, "ref", "ref48.wav")
    os.makedirs(os.path.dirname(tmp), exist_ok=True)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-ss", str(start), "-t", str(REF_LEN), "-i", path,
                    "-ar", str(common.SR), "-ac", "1", tmp], check=True)
    _, x = common.read_wav(tmp)
    f = int(0.3 * common.SR)
    x[:f] *= np.linspace(0, 1, f)
    x[-f:] *= np.linspace(1, 0, f)
    return x


def dry():
    sc = common.score()
    lead = np.zeros(int(0.2 * common.SR))
    out = {
        "A": samples.render(sc),
        "B": bowed.render(sc),
        "C": hybrid.render(sc),
        "ref": reference(_opt("reference", os.path.join(common.BUILD, "ref", "sallie_gooden.flac")),
                         float(_opt("ref-from", 100.0))),
    }
    for k, x in out.items():
        x = np.concatenate([lead, x])
        common.write_wav(os.path.join(DRY, f"{k}.wav"), common.normalise(x, target=-18.0))
        print(f"dry {k}: {len(x) / common.SR:.1f} s")


def game():
    run = os.path.join(common.LAB, "run.py")
    for src in SOURCES:
        wav = os.path.join(DRY, f"{src}.wav")
        out = os.path.join(GAME, src)
        subprocess.run([sys.executable, run, f"--scenario={','.join(PLACES)}", f"--out={out}",
                        f"--file={wav}", f"--jobs={_opt('jobs', 1)}"], check=False)


if __name__ == "__main__":
    if not _opt("game"):
        dry()
    if not _opt("dry"):
        game()
