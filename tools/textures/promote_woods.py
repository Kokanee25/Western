#!/usr/bin/env python3
"""Promote a material lab set's woods into the game's woods (docs/PARTS.md: "labs measure; parts live
in the game"; docs/briefs/material-lab.md "Sean's picks"): each wood's strips, end grain and
preview copied from assets/textures/mlab_<set>/ into assets/textures/woods/ under the name the game
will ask for, with its lab.json entry, so WoodMaterials and PixelArt draw it like any game wood.

    python3 tools/textures/promote_woods.py --set=studio_int --as=floor:int_floor,timber:int_timber,...
        [--extra=int_floor:roughness=0.9,...]

A new name leaves the game's woods of the old name untouched (the interior stain: Sean picked C,
2026-10-21, for the saloon's interior; the outside keeps its woods). No paid calls.
"""
import json
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TEX = os.path.join(ROOT, "assets", "textures")
WOODS = os.path.join(TEX, "woods")


def promote(set_name, mapping, extra):
    src = os.path.join(TEX, "mlab_" + set_name)
    src_index = json.load(open(os.path.join(src, "lab.json")))["woods"]
    index_path = os.path.join(WOODS, "lab.json")
    index = json.load(open(index_path))
    params = open(os.path.join(WOODS, "floor_b0.png.import")).read().split("[params]", 1)[1]
    for old, new in mapping:
        if old not in src_index:
            print("promote: %s has no wood %s" % (set_name, old))
            sys.exit(1)
        n = 0
        for f in sorted(os.listdir(src)):
            if not f.endswith(".png"):
                continue
            stem = f[:-4]
            if stem == old or stem.startswith(old + "_") and (stem[len(old) + 1:] in ("end", "bare") or
                                                             stem[len(old) + 1:].lstrip("b").isdigit()):
                dst = os.path.join(WOODS, new + stem[len(old):] + ".png")
                shutil.copyfile(os.path.join(src, f), dst)
                if not os.path.exists(dst + ".import"):
                    with open(dst + ".import", "w") as fh:
                        fh.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]' + params)
                n += 1
        entry = dict(src_index[old])
        entry["end"] = "%s_end.png" % new
        entry.pop("end_wear", None)
        entry["promoted_from"] = "mlab_%s/%s" % (set_name, old)
        entry.update(extra.get(new, {}))
        index["woods"][new] = entry
        print("promote: %s/%s -> woods/%s (%d files)" % (set_name, old, new, n))
    json.dump(index, open(index_path, "w"), indent=1)


def main():
    args = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    if "set" not in args or "as" not in args:
        print(__doc__)
        sys.exit(1)
    mapping = [tuple(p.split(":", 1)) for p in args["as"].split(",")]
    extra = {}
    for item in filter(None, args.get("extra", "").split(",")):
        wood, kv = item.split(":", 1)
        k, v = kv.split("=", 1)
        extra.setdefault(wood, {})[k] = float(v)
    promote(args["set"], mapping, extra)


if __name__ == "__main__":
    main()
