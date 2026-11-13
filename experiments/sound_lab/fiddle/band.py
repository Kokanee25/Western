#!/usr/bin/env python3
"""The minstrel band (#790): fiddle, banjo, bones and tambourine, every part from one tune's note
data (bowed.py, banjo.py, bones.py, tambourine.py), mixed as one sound the way the game places a
band: the fiddle on top, the banjo just under it, the bones and tambourine in the rhythm's place.

    python3 experiments/sound_lab/fiddle/band.py turkey_in_the_straw.json [--out=...wav]
        [--with=banjo,bones,tambourine] (who plays with the fiddle; piano too: --with=banjo,bones,tambourine,piano)
    --strings=gut|steel|modern (the banjo's strings), --banjo-style=clawhammer|rolls
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import banjo  # noqa: E402
import bones  # noqa: E402
import bowed  # noqa: E402
import common  # noqa: E402
import piano  # noqa: E402
import tambourine  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
# each player's loudness against the fiddle's (dB)
BANJO_STYLE = "clawhammer"  # or "rolls" (three-finger, banjo.arrange_rolls)
LEVELS = {"banjo": -2.5, "bones": -9.0, "tambourine": -11.0, "piano": -4.0}


def player(name, sc):
    if name == "banjo":
        part = banjo.arrange_rolls(sc) if BANJO_STYLE == "rolls" else banjo.arrange(sc)
        return banjo.render(part)
    if name == "bones":
        return bones.render(bones.arrange(sc))
    if name == "tambourine":
        return tambourine.render(tambourine.arrange(sc))[0]
    if name == "piano":
        return piano.render(piano.arrange(sc))
    raise ValueError(name)


def render(sc, who=("banjo", "bones", "tambourine")):
    parts = [common.normalise(bowed.render(sc))]
    for name in who:
        parts.append(common.normalise(player(name, sc)) * 10 ** (LEVELS[name] / 20.0))
    y = np.zeros(max(len(p) for p in parts))
    for p in parts:
        y[:len(p)] += p
    return common.normalise(y)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    banjo.strings(opt.get("strings", "gut"))
    global BANJO_STYLE
    BANJO_STYLE = opt.get("banjo-style", "clawhammer")
    who = tuple(w for w in opt.get("with", "banjo,bones,tambourine").split(",") if w)
    name = os.path.splitext(os.path.basename(src))[0]
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_band" + ("" if opt.get("strings", "gut") == "gut" else "_" + opt["strings"])
                  + ("_rolls" if BANJO_STYLE == "rolls" else "") + ("_piano" if "piano" in who else "") + ".wav"))
    y = render(sc, who)
    common.write_wav(out, y)
    print(f"{out}: {sc['tune']}, fiddle with {', '.join(who)}, {len(y) / common.SR:.1f} s, peak {np.max(np.abs(y)):.2f}")


if __name__ == "__main__":
    main()
