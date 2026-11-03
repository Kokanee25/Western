#!/usr/bin/env python3
"""Blind clips of the recorded dynamite sets (issue #596, step 1) for Sean to pick by ear.

Each set in assets/sounds/blast/sets.json is played through the game itself (the sound lab's runs:
GameAudio's placement, late by distance, the air, rooms, walls, slaps), one stick each, heard from
5 m, 30 m and 150 m in the street and 5 m inside the saloon. The sets are shuffled to the labels
1, 2, 3 (the key in OUT/key.json, not for Sean); OUT/clips/<label>_<where>.mp3 a clip each and
OUT/clips/<label>_all.mp3 the four one after another (a second of quiet between) for the phone.

    python3 experiments/sound_lab/blast_clips.py --out=build/sound_lab/blast [--sets=1,2,3] [--jobs=2]
    python3 experiments/sound_lab/blast_clips.py --out=... --clips-only     # cut the clips again
"""
import json
import os
import random
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SCENARIOS = [("5m", "dynamite_out_5"), ("30m", "dynamite_out_30"), ("150m", "dynamite_out_150"),
             ("saloon", "dynamite_in_5")]


def _opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
        if a == f"--{name}":
            return True
    return default


def main():
    out = os.path.abspath(_opt("out", os.path.join(ROOT, "build", "sound_lab", "blast")))
    sets = json.load(open(os.path.join(ROOT, "assets", "sounds", "blast", "sets.json")))["sets"]
    ids = _opt("sets", ",".join(sorted(sets, key=int))).split(",")
    os.makedirs(out, exist_ok=True)
    key_path = os.path.join(out, "key.json")
    if os.path.exists(key_path):
        key = json.load(open(key_path))
    else:
        shuffled = ids[:]
        random.Random(int(_opt("seed", 596))).shuffle(shuffled)
        key = {str(i + 1): s for i, s in enumerate(shuffled)}
        json.dump(key, open(key_path, "w"), indent=1)
    if not _opt("clips-only"):
        names = ",".join(s for _, s in SCENARIOS)
        for label, s in key.items():
            subprocess.run([sys.executable, os.path.join(HERE, "run.py"), f"--scenario={names}",
                            f"--blast-set={s}", f"--out={os.path.join(out, 'set' + s)}",
                            f"--jobs={_opt('jobs', 2)}"], check=False)
    clips = os.path.join(out, "clips")
    os.makedirs(clips, exist_ok=True)
    for label, s in key.items():
        parts = []
        for where, scen in SCENARIOS:
            wav = os.path.join(out, "set" + s, scen, "heard.wav")
            if not os.path.exists(wav):
                print(f"missing: set {s} {scen}")
                continue
            mp3 = os.path.join(clips, f"{label}_{where}.mp3")
            # From the half second of quiet before the stick to the end of its tail.
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-codec:a", "libmp3lame", "-b:a", "192k", mp3],
                           check=True)
            parts.append(wav)
        if parts:
            inputs, chain = [], ""
            for i, w in enumerate(parts):
                inputs += ["-i", w]
                chain += f"[{i}:a]apad=pad_dur=1[a{i}];"
            chain += "".join(f"[a{i}]" for i in range(len(parts))) + f"concat=n={len(parts)}:v=0:a=1[o]"
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", *inputs, "-filter_complex", chain, "-map", "[o]",
                            "-codec:a", "libmp3lame", "-b:a", "192k", os.path.join(clips, f"{label}_all.mp3")], check=True)
    print(f"clips in {clips}")


if __name__ == "__main__":
    main()
