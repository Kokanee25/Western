#!/usr/bin/env python3
"""A game wood regraded into a new one: its strips and end grain lightened (or darkened) so its
median L* lands on a target, contrast and colour kept, saved under a new name in the game's woods
with its lab.json entry. No paid call.

    python3 tools/textures/regrade_wood.py --wood=int_oak --as=int_oak_light --L=33 [--C=1.0]

Made for the bar and back bar's lighter oak (Sean, 2026-10-22, issue #218: the kit fixtures read
near black against the saloon's walls, int_boards at L* 35; the picture's bar is the walls' value).
"""
import glob
import json
import os
import shutil
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import reduce  # noqa: E402 (its Lab conversions)

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
WOODS = os.path.join(ROOT, "assets", "textures", "woods")


def main():
    args = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    if "wood" not in args or "as" not in args or "L" not in args:
        print(__doc__)
        sys.exit(1)
    old, new, target, chroma = args["wood"], args["as"], float(args["L"]), float(args.get("C", 1.0))
    strips = sorted(glob.glob(os.path.join(WOODS, "%s_b[0-9]*.png" % old)))
    labs = {f: reduce.to_lab(np.asarray(Image.open(f).convert("RGB"))) for f in strips}
    median = float(np.median(np.concatenate([a[..., 0].ravel() for a in labs.values()])))
    shift = target - median
    params = open(os.path.join(WOODS, "floor_b0.png.import")).read().split("[params]", 1)[1]
    files = strips + [f for f in (os.path.join(WOODS, "%s_end.png" % old), os.path.join(WOODS, "%s.png" % old))
                      if os.path.exists(f)]
    for f in files:
        a = labs[f] if f in labs else reduce.to_lab(np.asarray(Image.open(f).convert("RGB")))
        a = a.copy()
        a[..., 0] = np.clip(a[..., 0] + shift, 0, 100)
        a[..., 1:] *= chroma
        dst = os.path.join(WOODS, new + os.path.basename(f)[len(old):])
        Image.fromarray(reduce.lab_to_rgb(a)).save(dst)
        if not os.path.exists(dst + ".import"):
            with open(dst + ".import", "w") as fh:
                fh.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]' + params)
    index_path = os.path.join(WOODS, "lab.json")
    index = json.load(open(index_path))
    entry = dict(index["woods"][old])
    entry["end"] = "%s_end.png" % new
    entry["regraded_from"] = "%s, median L* %.1f -> %.1f" % (old, median, target)
    index["woods"][new] = entry
    json.dump(index, open(index_path, "w"), indent=1)
    print("regrade: %s -> %s (%d files, L* %+.1f)" % (old, new, len(files), shift))


if __name__ == "__main__":
    main()
