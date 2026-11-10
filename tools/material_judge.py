#!/usr/bin/env python3
"""The materials judge's crops and prompt (#721; rubric docs/concept/judge/MATERIAL.md).

  python3 tools/material_judge.py prepare --from=DIR --out=docs/screenshots/judge/<round> --refs=REFS
      [--before=DIR0] [--only=R1_old,C1_new,...]

DIR is a material lab review run (tools/material_lab.gd --panels=... --review --hires --aa=taa at
1920x1080): DIR/<class>/<entry>_<age>/<light>_<view>.png. Cuts the wood out of each shot (1 m at
noon, 5 m at golden hour; the fine woods also 1 m at night and the rail at noon), named by swatch
code and age, into OUT, and prints the prompt for a fresh, blind sub-agent, which writes
OUT/material.md. REFS is the Character Studio's `references/` (the AAA yardstick): read in place,
never copied here, and refused if it's inside this checkout.

With --before=DIR0 it's a blind A/B: each swatch's crops come twice, as set P and set Q, which is
which shuffled per swatch (the key goes to OUT/../<round>.key.json's twin under build/, not in OUT,
so the judge can't read it); the judge grades each set on its own against the yardstick.
"""
import json
import os
import random
import sys
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLASSES = ["rough", "common", "fine"]
# shot -> (crop name, box in the 1920x1080 frame)
SHOTS = {
    "noon_near": ("near", (420, 0, 1820, 780)),
    "golden_far": ("far", (750, 240, 1310, 600)),
    "saloon_near": ("saloon_night", (420, 0, 1820, 780)),
    "noon_rail": ("noon_rail", (0, 600, 1920, 1080)),
}
# The six references the first round (2026-11-10_material_r3e) was judged against.
REFS = ["games/rdr2/street_noon_1.jpg", "games/rdr2/street_golden_1.jpg", "games/rdr2/saloon_night_1.jpg",
        "games/hunt1896/street_noon_1.jpg", "games/hunt1896/saloon_night_1.jpg", "games/kcd2/street_noon_1.jpg"]


def swatches(src):
    lib = json.load(open(os.path.join(ROOT, "config/material_library.json")))
    out = {}
    for e in lib["entries"]:
        for age in ("new", "few", "old"):
            d = os.path.join(src, e["class"], "%s_%s" % (e["id"], age))
            if os.path.isdir(d):
                out["%s_%s" % (e["code"], age)] = (d, e)
    return out


def cut(d, dest, stem, sources):
    names = []
    for shot, (name, box) in SHOTS.items():
        p = os.path.join(d, shot + ".png")
        if not os.path.exists(p):
            continue
        im = Image.open(p).convert("RGB")
        if im.size != (1920, 1080):
            raise SystemExit("%s is %s, not 1920x1080" % (p, im.size))
        fn = "%s_%s.png" % (stem, name)
        im.crop(box).save(os.path.join(dest, fn))
        sources.append("%s %s %s" % (fn, os.path.relpath(p, ROOT), box))
        names.append(fn)
    return names


def prepare(args):
    src = os.path.abspath(args["from"])
    out = os.path.abspath(args["out"])
    refs = os.path.abspath(args["refs"])
    if refs.startswith(ROOT + os.sep):
        raise SystemExit("--refs must be outside this checkout (the references are never copied here)")
    only = args.get("only", "").split(",") if args.get("only") else None
    os.makedirs(out, exist_ok=True)
    after = swatches(src)
    before = swatches(os.path.abspath(args["before"])) if args.get("before") else {}
    sources, key, listing = [], {}, []
    rng = random.Random(os.path.basename(out))
    for sw in sorted(after):
        if only and sw not in only:
            continue
        d, e = after[sw]
        if before:
            if sw not in before:
                continue
            flip = rng.random() < 0.5
            key[sw] = {"P": "before" if flip else "after", "Q": "after" if flip else "before"}
            for letter in ("P", "Q"):
                dd = (before if key[sw][letter] == "before" else after)[sw][0]
                listing.append((sw + " set " + letter, e["name"], cut(dd, out, "%s_%s" % (sw, letter), sources)))
        else:
            listing.append((sw, e["name"], cut(d, out, sw, sources)))
    round_name = os.path.basename(out)
    if key:
        kp = os.path.join(ROOT, "build", round_name + ".key.json")
        os.makedirs(os.path.dirname(kp), exist_ok=True)
        json.dump(key, open(kp, "w"), indent=1)
    lines = ["You are the materials judge for a western game's wood materials. You are blind: you know nothing",
             "about how these pictures were made or what changed, and you must not look for that. Do not read",
             "any other file in the repository than the ones named here.",
             "", "Read the rubric first: %s" % os.path.join(ROOT, "docs/concept/judge/MATERIAL.md"),
             "", "The yardstick (official screenshots of shipped AAA games; look only at their wood):"]
    lines += ["  " + os.path.join(refs, r) for r in REFS]
    lines += ["", "The crops to judge, all in %s (near: 1 m at noon; far: 5 m at golden hour;" % out,
              "saloon_night: 1 m by lamplight; noon_rail: a rail and floor of the same wood):"]
    for sw, name, files in listing:
        lines.append("  %s (%s): %s" % (sw, name, ", ".join(files)))
    if key:
        lines += ["", "Each swatch comes as two sets, P and Q: two candidate versions of the same swatch. Grade each",
                  "set on its own against the yardstick (the same six checks, one grade each), then say which set",
                  "is better and whether the difference is a full grade or only within a grade. P and Q mean",
                  "nothing across swatches."]
    lines += ["", "For 'Age reads', compare a swatch's ages with each other where more than one age is given.",
              "The saw-toothed edge of the sun's shadow along battens and laps is a known fault of the light,",
              "not of the material: note it once if you see it, and do not let it fail a check or lower a grade.",
              "", "View every crop (downscale nothing: they are already cut small). Write your judgment to",
              "%s in the rubric's form: per swatch (and set), the six" % os.path.join(out, "material.md"),
              "checks PASS/FAIL with a crop box `x y w h` as evidence for each FAIL, the grade (fake / game /",
              "near the yardstick / at the yardstick), and per swatch the one change that would move it up",
              "most. End the file with a summary table of every grade. Be strict and honest; a grade is",
              "what a player would see, not credit for effort. Reply to me with only the summary table",
              "and one line per swatch on its worst remaining tell."]
    open(os.path.join(out, "sources.txt"), "w").write("\n".join(sources) + "\n")
    prompt = "\n".join(lines)
    pp = os.path.join(ROOT, "build", round_name + ".prompt.txt")
    open(pp, "w").write(prompt + "\n")
    print(prompt)


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] != "prepare":
        raise SystemExit(__doc__)
    a = {}
    for arg in sys.argv[2:]:
        k, _, v = arg.lstrip("-").partition("=")
        a[k] = v
    for need in ("from", "out", "refs"):
        if need not in a:
            raise SystemExit("--%s= is needed\n%s" % (need, __doc__))
    prepare(a)
