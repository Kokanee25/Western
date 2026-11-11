#!/usr/bin/env python3
"""Fiddle and banjo together (#790): the dance band of the 1870s and 80s, both from one tune's note
data (bowed.py the fiddle, banjo.py the banjo's part and sound), the fiddle on top as it leads.
Written as one sound, the way the game would place them: two men side by side on the balcony.

    python3 experiments/sound_lab/fiddle/duet.py turkey_in_the_straw.json [--out=...wav]
        [--banjo-db=-2.5] (the banjo's loudness against the fiddle's)
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import banjo  # noqa: E402
import bowed  # noqa: E402
import common  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))


def render(sc, banjo_db=-2.5):
    fiddle = common.normalise(bowed.render(sc))
    part = banjo.arrange(sc)
    b = common.normalise(banjo.render(part)) * 10 ** (banjo_db / 20.0)
    n = max(len(fiddle), len(b))
    y = np.zeros(n)
    y[:len(fiddle)] += fiddle
    y[:len(b)] += b
    return common.normalise(y), part


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    name = os.path.splitext(os.path.basename(src))[0]
    y, part = render(sc, float(opt.get("banjo-db", -2.5)))
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_duet.wav"))
    common.write_wav(out, y)
    print(f"{out}: {sc['tune']}, fiddle and banjo (in {part['key']}), {len(y) / common.SR:.1f} s")


if __name__ == "__main__":
    main()
