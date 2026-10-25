#!/usr/bin/env python3
"""What the fights cost a frame (docs/briefs/more-cores.md): each run's mean frame, its worst 5%,
the people's share and the heaviest systems, from the `perf` every fight records.

    python3 experiments/gunfight_lab/perf.py build/perf/P_base build/perf/P_fix [--systems=a,b] [--all]

Each ROOT is a run.py --out folder. Numbers are this workspace's core, headless (no drawing);
x0.65 for Sean's (CLAUDE.md "Frame budget"). --all lists every system, timers named x_* included
(a measuring session's own).
"""
import glob
import json
import os
import sys

SYSTEMS = ["outlaw_brain", "people_body", "people_skeleton", "senses", "fire", "floor_marks", "structures",
           "civilian_brain", "player", "day_cycle"]


def load(root):
    out = []
    for f in sorted(glob.glob(os.path.join(root, "fights", "*.json"))):
        with open(f) as fh:
            out.append(json.load(fh))
    return out


def mean(xs):
    return sum(xs) / len(xs) if xs else 0.0


def main(argv):
    roots = [a for a in argv if not a.startswith("--")]
    systems = SYSTEMS
    for a in argv:
        if a.startswith("--systems="):
            systems = a.split("=", 1)[1].split(",")
    if "--all" in argv:
        names = set()
        for r in roots:
            for f in load(r):
                names |= set(f.get("perf", {}).get("per_system_ms", {}))
        systems = sorted(names)
    head = "%-12s %3s %6s %6s %6s %5s " % ("run", "n", "frame", "p95", "people", "len") + " ".join("%8s" % s[:8] for s in systems)
    print(head)
    for r in roots:
        fights = [f for f in load(r) if "perf" in f]
        if not fights:
            print("%-12s   0" % os.path.basename(r.rstrip("/")))
            continue
        p = [f["perf"] for f in fights]
        row = "%-12s %3d %6.1f %6.1f %6.1f %5.1f " % (
            os.path.basename(r.rstrip("/")), len(fights), mean([x["frame_ms"] for x in p]), mean([x["frame_p95_ms"] for x in p]),
            mean([x["people_ms"] for x in p]), mean([f.get("length_s", 0.0) for f in fights]))
        row += " ".join("%8.2f" % mean([x["per_system_ms"].get(s, 0.0) for x in p]) for s in systems)
        print(row)
        print("   endings", sorted(f.get("ending", "?") for f in fights))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
