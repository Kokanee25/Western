#!/usr/bin/env python3
"""A song arranged by sections (Sean, 2026-11-15: "a real banger ... something they would stomp their feet to"):
each player renders the whole song once from its note data, then comes in and drops out by the bars a
sections file gives (an intro of the stomp and the hook, the band in for the verse, everyone on the
chorus, a breakdown to the stomp and claps), each section's edges a short fade on the bar line.

    python3 experiments/sound_lab/fiddle/sections.py stomp_the_boards.json tunes/stomp_the_boards.sections.json
        [--levels=fiddle:0,guitar:-3,banjo:-4,bass:-2,drums:-2] [--out=...wav]

The players: fiddle (bowed.py), guitar (the driving strum), banjo (modern open-back, three-finger rolls),
bass (every beat), drums (four on the floor, hand claps on two and four). Each is rendered to build/ once
and reused while the mix is tuned (delete build/sound_lab/fiddle/parts/<song>_* to render again).
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import banjo  # noqa: E402
import bass  # noqa: E402
import bowed  # noqa: E402
import common  # noqa: E402
import drums  # noqa: E402
import guitar  # noqa: E402
import rhythm  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
LEVELS = {"fiddle": 0.0, "guitar": -3.0, "banjo": -4.0, "bass": -2.0, "drums": -2.0}
EDGE = 0.02   # s: each section's fade on the bar line


def part(name, sc):
    if name == "fiddle":
        return bowed.render(sc)
    if name == "guitar":
        guitar.STYLE = "drive"
        return guitar.render(guitar.arrange(sc))
    if name == "banjo":
        banjo.strings("modern")
        return banjo.render(banjo.arrange_rolls(sc))
    if name == "bass":
        bass.STYLE = "drive"
        return bass.render(bass.arrange(sc))
    if name == "drums":
        drums.STYLE, drums.CLAP = "four", True
        return drums.render(drums.arrange(sc))
    raise ValueError(name)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    plan = json.load(open(args[1] if os.path.isabs(args[1]) else os.path.join(HERE, args[1])))["sections"]
    for kv in filter(None, opt.get("levels", "").split(",")):
        k, v = kv.split(":")
        LEVELS[k] = float(v)
    name = os.path.splitext(os.path.basename(src))[0]
    cache = os.path.join(common.BUILD, "parts")
    os.makedirs(cache, exist_ok=True)
    when, _, _, _ = rhythm.grid(sc)
    starts = sc["bar_units"]
    sr = common.SR
    players = sorted({p for s in plan for p in s["players"]})
    parts = {}
    for p in players:
        path = os.path.join(cache, f"{name}_{p}.wav")
        if not os.path.exists(path):
            common.write_wav(path, common.normalise(part(p, sc)))
            print(f"rendered {p}")
        parts[p] = common.read_wav(path)[1]
    n = max(len(x) for x in parts.values())
    mix = np.zeros(n)
    for p, x in parts.items():
        gate = np.zeros(n)
        for s in plan:
            if p not in s["players"]:
                continue
            b0, b1 = s["bars"]
            t0 = when(starts[b0]) - 0.03  # a stroke can land a hair before the bar
            last = b1 >= len(starts)
            t1 = n / sr if last else when(starts[b1]) - 0.03
            i0, i1 = max(0, int(t0 * sr)), min(n, int(t1 * sr))
            gate[i0:i1] = 1.0
        # the edges: a short fade, so a player comes in and drops out on the bar line, cleanly
        k = int(EDGE * sr)
        ramp = np.convolve(gate, np.ones(k) / k, mode="same")
        mix[:len(x)] += x * ramp[:len(x)] * 10 ** (LEVELS.get(p, 0.0) / 20)
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_sections.wav"))
    y = common.normalise(mix)
    common.write_wav(out, y)
    print(f"{out}: {sc['tune']}, {len(plan)} sections, {', '.join(players)}, {n / sr:.1f} s, peak {np.max(np.abs(y)):.2f}")


if __name__ == "__main__":
    main()
