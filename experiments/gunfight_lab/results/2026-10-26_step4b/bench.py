#!/usr/bin/env python3
"""perf_bench's calm street at one and two times the townsfolk, the bands on and off (step 4b's
gate: "the people's share flat where it was linear"). Each run's --out json; the people's share is
FrameBudget's people part (the people's timers, phase 2's wall and the bands' pass), ms a frame on
this VM, unscaled; each run's controls (`structures`, `day_cycle`, `horses`, `kit_balance`: the
step touches none) give a scaled column, as normalise.py does for the lab.

    python3 bench.py DIR   (DIR has f_folk{1,2}_{on,off}_{1,2,3}.json)
"""
import glob
import json
import os
import re
import sys

PEOPLE = ["people_body", "people_skeleton", "senses", "outlaw_brain", "civilian_brain", "player", "town_life",
          "blood", "cloth", "mop", "faces", "people_prep", "people_bands"]
CONTROLS = ["structures", "day_cycle", "horses", "kit_balance"]
SHOW = ["people_body", "people_skeleton", "senses", "civilian_brain", "outlaw_brain", "people_prep", "people_bands",
        "n_people_ticked", "n_people_owed", "q_senses", "q_writes", "q_walk"]


def main(d):
    runs = {}
    for p in sorted(glob.glob(os.path.join(d, "f_folk*_*_*.json"))):
        m = re.match(r"f_folk(\d)_(on|off)_(\d)\.json", os.path.basename(p))
        f = json.load(open(p))["calm"]["frames"]
        s = f["systems_ms"]
        runs.setdefault((int(m[1]), m[2]), []).append({
            "frame": f["avg_ms"], "p99": f["p99_ms"], "people": sum(s.get(k, 0.0) for k in PEOPLE),
            "ctrl": sum(s.get(k, 0.0) for k in CONTROLS), "s": s})
    base = sum(r["ctrl"] for rs in runs.values() for r in rs) / sum(len(rs) for rs in runs.values())
    mean = lambda xs: sum(xs) / len(xs)
    print("| folk, bands | runs | frame | frame p99 | people | frame, scaled | people, scaled |")
    print("|---|---|---|---|---|---|---|")
    out = {}
    for key in [(1, "off"), (2, "off"), (1, "on"), (2, "on")]:
        rs = runs.get(key, [])
        if not rs:
            continue
        fr = mean([r["frame"] for r in rs])
        pe = mean([r["people"] for r in rs])
        frs = mean([r["frame"] * base / r["ctrl"] for r in rs])
        pes = mean([r["people"] * base / r["ctrl"] for r in rs])
        out[key] = (frs, pes)
        print("| x%d, %s | %d | %.2f | %.2f | %.2f | %.2f | %.2f |" % (key[0], key[1], len(rs), fr, mean([r["p99"] for r in rs]), pe, frs, pes))
    for b in ["off", "on"]:
        if (1, b) in out and (2, b) in out:
            print("\nbands %s: the town doubled adds %.2f ms to the frame, %.2f to the people (scaled)" % (
                b, out[(2, b)][0] - out[(1, b)][0], out[(2, b)][1] - out[(1, b)][1]))
    print("\n| system (ms, or a count a frame) | " + " | ".join("x%d %s" % k for k in [(1, "off"), (2, "off"), (1, "on"), (2, "on")]) + " |")
    print("|---|---|---|---|---|")
    for k in SHOW:
        print("| %s | %s |" % (k, " | ".join("%.2f" % mean([r["s"].get(k, 0.0) for r in runs.get(key, [{"s": {}}])])
                                            for key in [(1, "off"), (2, "off"), (1, "on"), (2, "on")])))


if __name__ == "__main__":
    main(sys.argv[1])
