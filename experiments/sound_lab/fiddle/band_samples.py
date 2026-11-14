#!/usr/bin/env python3
"""A, samples, for the travelling band's cornet and drums (#822): the same parts as cornet.py and
drums.py play, from VSCO 2 CE's recordings (CC0): its trumpet (no cornet in the library; the nearest
real brass) and its bass drum and snare drum (snares on). The listening set's "real instrument":
these are real players on real instruments, so they show what ours should sound like note by note.

    python3 experiments/sound_lab/fiddle/band_samples.py yankee_doodle.json [--only=cornet|drums]

Each cornet note: the nearest sample by pitch (VSCO names its trumpet an octave low: "C3" sounds
middle C), staccato for short notes and sustain for long, its dynamic by the note's loudness,
round-robins in turn, resampled to the note's pitch, cut with a 40 ms release. Each drum stroke:
the sample whose dynamic layer is nearest the stroke's force, round-robins in turn, at its level.
fetch.sh fetches the samples into build/sound_lab/cornet/vsco/.
"""
import glob
import json
import os
import re
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
import cornet  # noqa: E402
import drums  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
VSCO = os.path.join(common.ROOT, "build", "sound_lab", "cornet", "vsco")
NAMES = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
_cache = {}


def _load(path):
    if path not in _cache:
        sr, x = common.read_wav(path)
        _cache[path] = common.resample(x, sr, common.SR)
    return _cache[path]


def trumpet_bank():
    bank = []
    for art in ("stac", "sus"):
        for p in glob.glob(os.path.join(VSCO, "Brass", "Trumpet", art, "*.wav")):
            m = re.search(r"_([A-G]#?)(\d)_v(\d)_rr(\d)", os.path.basename(p))
            midi = 12 * (int(m.group(2)) + 2) + NAMES[m.group(1)]  # "C3" is middle C (60)
            bank.append({"art": art, "midi": midi, "v": int(m.group(3)), "rr": int(m.group(4)), "path": p})
    return bank


def render_cornet(part):
    bank = trumpet_bank()
    n = int((part["length_s"] + 1.5) * common.SR)
    out = np.zeros(n)
    turn = 0
    for nt in part["notes"]:
        art = "sus" if nt["dur"] > 0.45 else "stac"
        vs = sorted({b["v"] for b in bank if b["art"] == art})
        want = vs[int(round(np.clip(nt["vel"], 0, 1) * (len(vs) - 1)))]
        cand = [b for b in bank if b["art"] == art and b["v"] == want]
        near = min(abs(b["midi"] - nt["midi"]) for b in cand)
        cand = [b for b in cand if abs(b["midi"] - nt["midi"]) == near]
        b = cand[turn % len(cand)]
        turn += 1
        x = _load(b["path"])
        ratio = 2.0 ** ((nt["midi"] - b["midi"]) / 12.0)
        idx = np.arange(0, len(x) - 1, ratio)
        y = np.interp(idx, np.arange(len(x)), x)
        # the sample's own start: skip its silence
        on = int(np.argmax(np.abs(y) > 0.02 * np.max(np.abs(y))))
        y = y[max(0, on - 48):]
        L = int((nt["dur"] + 0.04) * common.SR)
        y = y[:L].copy()
        if len(y) == L:
            k = int(0.04 * common.SR)
            y[-k:] *= np.linspace(1, 0, k)
        i = int(nt["t"] * common.SR)
        out[i:i + len(y)] += y[:n - i] * (0.6 + 0.4 * nt["vel"])
    return out


def drum_bank():
    bank = {"bass": [], "snare": []}
    for p in glob.glob(os.path.join(VSCO, "Percussion", "BDrumNewhit_v*_rr*_Sum.wav")):
        m = re.search(r"_v(\d)_rr(\d)", p)
        bank["bass"].append((int(m.group(1)), int(m.group(2)), p))
    for p in glob.glob(os.path.join(VSCO, "Percussion", "Snare2-HitSN_v*_rr*_Sum.wav")):
        m = re.search(r"_v(\d)_rr(\d)", p)
        bank["snare"].append((int(m.group(1)), int(m.group(2)), p))
    return bank


def render_drums(part):
    bank = drum_bank()
    n = int((part["length_s"] + 2.0) * common.SR)
    out = np.zeros(n)
    turn = {"bass": 0, "snare": 0}
    for st in part["strokes"]:
        layers = sorted({v for v, _, _ in bank[st["drum"]]})
        want = layers[int(round(np.clip(st["vel"], 0, 1) * (len(layers) - 1)))]
        cand = sorted([b for b in bank[st["drum"]] if b[0] == want])
        b = cand[turn[st["drum"]] % len(cand)]
        turn[st["drum"]] += 1
        x = _load(b[2])
        on = int(np.argmax(np.abs(x) > 0.05 * np.max(np.abs(x))))
        x = x[max(0, on - 24):]
        i = int(st["t"] * common.SR)
        j = min(n, i + len(x))
        out[i:j] += x[:j - i] * (0.75 + 0.25 * st["vel"])
    return out


def main():
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    name = os.path.splitext(os.path.basename(src))[0]
    if opt.get("only") in (None, "cornet"):
        y = render_cornet(cornet.arrange(sc))
        common.write_wav(os.path.join(common.BUILD, "dry", name + "_cornet_A.wav"), common.normalise(y))
    if opt.get("only") in (None, "drums"):
        y = render_drums(drums.arrange(drums.beats_of(sc), intro="beats" in sc))
        common.write_wav(os.path.join(common.BUILD, "dry", name + "_drums_A.wav"), common.normalise(y))
    print("done")


if __name__ == "__main__":
    main()
