#!/usr/bin/env python3
"""Promote a material lab set's woods into the game's woods (docs/PARTS.md: "labs measure; parts live
in the game"; docs/briefs/material-lab.md "Sean's picks"): each wood's strips, end grain and
preview copied from assets/textures/mlab_<set>/ into assets/textures/woods/ under the name the game
will ask for, with its lab.json entry, so WoodMaterials and PixelArt draw it like any game wood.

    python3 tools/textures/promote_woods.py --set=studio_int --as=floor:int_floor,timber:int_timber,...
        [--extra=int_floor:roughness=0.9,...]

A wood promoted under a name the game already has replaces that wood's strips (round 5's exterior
woods: Sean's pick, 2026-10-22; `--extra=saloon_red:edge_aa=1,...` carries the lab's finish).
A new name leaves the game's woods of the old name untouched (the interior stain: Sean picked C,
2026-10-21, for the saloon's interior; the outside keeps its woods). No paid calls.

    python3 tools/textures/promote_woods.py --vram=saloon_red,floor,...   # [--lossless=...]

Sets how the game's woods named import (strips, end grain, bare wood; the stub's [params]):
`--vram` VRAM-compressed at high quality (BC7 on desktop, a quarter of RGBA8's memory: the memory
test, Sean's pick 2026-10-23, docs/briefs/material-lab.md), `--lossless` back to RGBA8. A promotion
keeps the compression the wood it replaces had (a new wood: lossless unless named in `--vram`).
Re-import (`godot --headless --import`) after either.
"""
import json
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TEX = os.path.join(ROOT, "assets", "textures")
WOODS = os.path.join(TEX, "woods")


def _params(vram):
    """The woods' import [params] (floor_b0's), lossless or VRAM-compressed at high quality."""
    params = open(os.path.join(WOODS, "floor_b0.png.import")).read().split("[params]", 1)[1]
    if vram:
        return params.replace("compress/mode=0", "compress/mode=2").replace(
            "compress/high_quality=false", "compress/high_quality=true")
    return params.replace("compress/mode=2", "compress/mode=0").replace(
        "compress/high_quality=true", "compress/high_quality=false")


def _files_of(wood, folder):
    """A wood's pngs in `folder`: its strips (_b<k>), end grain and bare wood, and its preview."""
    return [f for f in sorted(os.listdir(folder)) if f.endswith(".png") and
            (f[:-4] == wood or f[:-4].startswith(wood + "_") and
             (f[:-4][len(wood) + 1:] in ("end", "bare") or f[:-4][len(wood) + 1:].lstrip("b").isdigit()))]


def _is_vram(wood):
    stub = os.path.join(WOODS, wood + "_b0.png.import")
    return os.path.exists(stub) and "compress/mode=2" in open(stub).read()


def _write_stub(path, vram):
    """A png's .import set lossless or VRAM-compressed: an existing one edited in place (its uid
    and the rest kept), else a stub with the woods' [params] (`godot --headless --import` fills in
    the rest)."""
    if os.path.exists(path + ".import"):
        text = open(path + ".import").read()
        if vram:
            text = text.replace("compress/mode=0", "compress/mode=2").replace(
                "compress/high_quality=false", "compress/high_quality=true")
        else:
            text = text.replace("compress/mode=2", "compress/mode=0").replace(
                "compress/high_quality=true", "compress/high_quality=false")
        open(path + ".import", "w").write(text)
        return
    params = _params(vram)
    with open(path + ".import", "w") as fh:
        fh.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]' + params)


def set_compression(woods, vram):
    for wood in woods:
        files = _files_of(wood, WOODS)
        if not files:
            print("compress: no wood %s" % wood)
            sys.exit(1)
        for f in files:
            _write_stub(os.path.join(WOODS, f), vram)
        print("compress: woods/%s %s (%d files)" % (wood, "VRAM (BC7)" if vram else "lossless", len(files)))


def promote(set_name, mapping, extra, vram_woods=()):
    src = os.path.join(TEX, "mlab_" + set_name)
    src_index = json.load(open(os.path.join(src, "lab.json")))["woods"]
    index_path = os.path.join(WOODS, "lab.json")
    index = json.load(open(index_path))
    for old, new in mapping:
        vram = new in vram_woods or _is_vram(new)
        if old not in src_index:
            print("promote: %s has no wood %s" % (set_name, old))
            sys.exit(1)
        if new in index["woods"]:
            # Replacing a game wood under its own name: its old strips move aside first (a set may cut
            # fewer boards, or none bare), so no stale strip is left beside the new ones; they're
            # kept in build/promote_backup/<wood>/ (and in git) until the merge.
            backup = os.path.join(ROOT, "build", "promote_backup", new)
            os.makedirs(backup, exist_ok=True)
            for f in os.listdir(WOODS):
                stem = f.split(".png")[0]
                if f.endswith((".png", ".png.import")) and (stem == new or stem.startswith(new + "_") and
                                                             (stem[len(new) + 1:] in ("end", "bare") or
                                                              stem[len(new) + 1:].lstrip("b").isdigit())):
                    shutil.move(os.path.join(WOODS, f), os.path.join(backup, f))
        n = 0
        for f in sorted(os.listdir(src)):
            if not f.endswith(".png"):
                continue
            stem = f[:-4]
            if stem == old or stem.startswith(old + "_") and (stem[len(old) + 1:] in ("end", "bare") or
                                                             stem[len(old) + 1:].lstrip("b").isdigit()):
                dst = os.path.join(WOODS, new + stem[len(old):] + ".png")
                shutil.copyfile(os.path.join(src, f), dst)
                if vram or not os.path.exists(dst + ".import"):
                    _write_stub(dst, vram)
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
    vram_woods = [w for w in args.get("vram", "").split(",") if w]
    if "set" not in args and ("vram" in args or "lossless" in args):
        set_compression(vram_woods, True)
        set_compression([w for w in args.get("lossless", "").split(",") if w], False)
        return
    if "set" not in args or "as" not in args:
        print(__doc__)
        sys.exit(1)
    mapping = [tuple(p.split(":", 1)) for p in args["as"].split(",")]
    extra = {}
    for item in filter(None, args.get("extra", "").split(",")):
        wood, kv = item.split(":", 1)
        k, v = kv.split("=", 1)
        extra.setdefault(wood, {})[k] = float(v)
    promote(args["set"], mapping, extra, vram_woods)


if __name__ == "__main__":
    main()
