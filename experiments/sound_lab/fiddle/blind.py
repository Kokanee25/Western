#!/usr/bin/env python3
"""The blind listening set (#790): the reference and A, B, C as numbered clips in a random order
(drawn fresh from the system's randomness; nobody, us included, knows it until the key is read),
the key in its own file.

  listen/1-4.mp3  up close: on the saloon's balcony beside the fiddler (the game's Room bus)
  listen/5-8.mp3  from the bar room under the balcony, its boards between (RoomMuffled)
  key/KEY.md      which is which (and the seed), with each one's dry render

Each set is shuffled on its own. Every source went in at the same loudness (-18 LUFS); what comes
out of the game differs by its spectrum (through the floor the record, all in the low-pass's band,
comes out 5-7 dB louder than ours), so each clip is set to its set's loudness (up close -16 LUFS,
through the floor -24: quieter, as it is, but audible on a phone) and every clip cut to the same
length: nothing but the sound tells them apart (not their level, not their file size).

    python3 experiments/sound_lab/fiddle/blind.py [--out=experiments/sound_lab/results/2026-11-10_fiddle]
"""
import json
import os
import random
import secrets
import subprocess
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
import render  # noqa: E402

NAMES = {"ref": "the 1922 reference (Eck Robertson, Sallie Gooden)", "A": "A, the samples",
         "B": "B, our bowed-string model", "C": "C, the hybrid"}
SETS = [("music_balcony_close", "Up close: on the saloon's balcony beside him", 1),
        ("music_balcony_below", "Through the floor: in the bar room under the balcony", 5)]


def mp3(x, sr, path):
    tmp = path + ".wav"
    import scipy.io.wavfile as wavfile
    x = np.clip(x, -1, 1)
    wavfile.write(tmp, sr, (x * 32767).astype(np.int16))
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", tmp, "-codec:a", "libmp3lame", "-b:a", "192k", path], check=True)
    os.remove(tmp)


def main():
    out = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--out=")),
               os.path.join(common.ROOT, "experiments", "sound_lab", "results", "2026-11-10_fiddle"))
    listen, key = os.path.join(out, "listen"), os.path.join(out, "key")
    os.makedirs(listen, exist_ok=True)
    os.makedirs(key, exist_ok=True)
    seed = secrets.randbits(32)
    rnd = random.Random(seed)
    lines = ["# The key (#790): open after listening", "",
             f"Shuffled with seed {seed} (`random.Random`, drawn from the system's randomness).", ""]
    for place, title, first in SETS:
        clips = {}
        for src in render.SOURCES:
            sr, x = None, None
            import scipy.io.wavfile as wavfile
            sr, x = wavfile.read(os.path.join(render.GAME, src, place, "heard.wav"))
            marks = json.load(open(os.path.join(render.GAME, src, place, "summary.json")))["marks"]
            t = next(m["t"] for m in marks if m["name"] == "music")
            # from just before the music (the lab's half second of quiet trimmed)
            clips[src] = x[int(max(0.0, t - 0.05) * sr):].astype(np.float64) / 32768.0
        target = -16.0 if first == 1 else -24.0
        length = min(len(x) for x in clips.values())
        order = list(render.SOURCES)
        rnd.shuffle(order)
        lines += [f"## {title} (clips {first}-{first + 3})", ""]
        for i, src in enumerate(order):
            n = first + i
            x = clips[src][:length].copy()
            x = x * 10 ** ((target - common.loudness(x.mean(axis=1), sr)) / 20)
            fade = int(0.2 * sr)
            x[-fade:] *= np.linspace(1, 0, fade)[:, None]
            mp3(x, sr, os.path.join(listen, f"{n}.mp3"))
            lines.append(f"- **{n}**: {NAMES[src]}")
        lines.append("")
    for src in render.SOURCES:
        sr, x = common.read_wav(os.path.join(render.DRY, f"{src}.wav"))
        mp3(x, sr, os.path.join(key, f"dry_{src}.mp3"))
    lines += ["The dry renders (no room, at -18 LUFS) are beside this file: `dry_ref.mp3`, `dry_A.mp3`, "
              "`dry_B.mp3`, `dry_C.mp3`.", ""]
    open(os.path.join(key, "KEY.md"), "w").write("\n".join(lines))
    print(f"clips in {listen}, key in {key}/KEY.md")


if __name__ == "__main__":
    main()
