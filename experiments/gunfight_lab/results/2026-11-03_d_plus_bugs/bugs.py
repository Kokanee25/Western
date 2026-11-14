#!/usr/bin/env python3
"""#595's two gang-side bugs, measured over gunfight lab runs (records with `muzzle_probe`):

1. Shots from past something: how many of the gang's shots left a muzzle that had something (a
   floor board, a wall board) between it and his own eye, and how many of those hit you.
2. Rescues repeated: "drag X to cover" decisions, and how often one man went for the same friend
   again and again (the Kid's 5+ over 100 s from the gallery).

    python3 bugs.py RUN [RUN...] [--out=FILE.md]
"""
import collections
import glob
import json
import os
import re
import sys


def runs(args):
    return [a for a in args if not a.startswith("--")]


def one(root):
    shots = past = past_hits = hits = 0
    past_what = collections.Counter()
    drags = 0
    pairs = collections.Counter()
    fights = 0
    by_fight_repeat = 0
    for p in sorted(glob.glob(os.path.join(root, "fights", "*.json"))):
        r = json.load(open(p))
        fights += 1
        hit_t = collections.defaultdict(list)
        for t, kind, text in r.get("timeline", []):
            m = re.match(r"you hit in the \S+ by (\w+)", text)
            if kind == "hit" and m:
                hit_t[m.group(1)].append(t)
        repeat = False
        for mid, man in r["men"].items():
            probe = man.get("muzzle_probe", [])
            shots += len(probe)
            hits += int(man.get("hits_on_you", 0))
            times = hit_t.get(mid, [])
            for s in probe:
                if s[1]:
                    past += 1
                    past_what[s[1].split(":")[0]] += 1
                    if any(0.0 <= h - s[0] <= 0.25 for h in times):
                        past_hits += 1
            here = collections.Counter()
            for _t, d in man.get("decisions", []):
                m = re.match(r"drag (\w+) to cover", d)
                if m:
                    drags += 1
                    here[m.group(1)] += 1
            for mate, n in here.items():
                pairs[n] += 1
                if n >= 2:
                    repeat = True
        by_fight_repeat += repeat
    return {"fights": fights, "shots": shots, "past": past, "past_hits": past_hits, "hits": hits,
            "past_what": past_what, "drags": drags, "pairs": pairs, "repeat_fights": by_fight_repeat}


def main(args):
    rows = ["| Run | Fights | Gang shots | From past a board (eye) | ...of them hit you | Hits on you | Rescues (drag) | Same friend 2+ times | 3+ times | Fights with a repeat |",
            "|---|---|---|---|---|---|---|---|---|---|"]
    notes = []
    for root in runs(args):
        o = one(root)
        two = sum(n for k, n in o["pairs"].items() if k >= 2)
        three = sum(n for k, n in o["pairs"].items() if k >= 3)
        rows.append("| %s | %d | %d | %d (%.1f%%) | %d | %d | %d | %d | %d | %d |" % (
            os.path.basename(root.rstrip("/")), o["fights"], o["shots"], o["past"], 100.0 * o["past"] / max(o["shots"], 1),
            o["past_hits"], o["hits"], o["drags"], two, three, o["repeat_fights"]))
        notes.append("- %s: what stood between his eye and his muzzle: %s" % (os.path.basename(root.rstrip("/")),
                     ", ".join("%s %d" % kv for kv in o["past_what"].most_common()) or "nothing"))
    text = "\n".join(rows + [""] + notes) + "\n"
    out = [a.split("=", 1)[1] for a in args if a.startswith("--out=")]
    if out:
        open(out[0], "w").write(text)
    print(text)


if __name__ == "__main__":
    main(sys.argv[1:])
