#!/usr/bin/env python3
"""The perf of one or more lab runs, side by side (step 6's script, copied for step 7): each fight's `perf` averaged over the run's
fights (ms a frame on this workspace's core; a q_* row is queries a frame, q_writes the people's
pivots set a frame). Step 6's copy (physics on its own thread): with the thread, `step` is only the
deferred calls after the ticks (Jolt steps beside the idle frame and the draw), and a step still
running when the next frame starts is waited for in `rest` (the next frame's sync); `frame_ms` is
the measure.

    python3 perf.py NAME=RUN_ROOT [NAME=RUN_ROOT ...]
"""
import glob
import json
import os
import sys

TOP = ["frame_ms", "frame_p95_ms", "people_ms", "people_p95_ms", "three_men_ms"]
SPLIT = ["window", "step", "rest"]
SYSTEMS = ["people_bands", "n_people_ticked", "n_people_owed", "people_prep", "people_prep_sum", "people_body", "people_skeleton", "senses", "lines_senses", "outlaw_brain", "civilian_brain",
           "faces", "lamps", "sight_sync", "player", "town_life", "horses", "ballistics", "fire", "structures", "voxels"]


def load(root):
    fights = []
    for p in sorted(glob.glob(os.path.join(root, "fights", "*.json"))):
        with open(p) as fh:
            fights.append(json.load(fh)["perf"])
    return fights


def mean(xs):
    return sum(xs) / len(xs) if xs else 0.0


def main(argv):
    runs = [(a.split("=", 1)[0], load(a.split("=", 1)[1])) for a in argv]
    keys = set()
    for _, fs in runs:
        for f in fs:
            keys |= set(f["per_system_ms"])
    queries = sorted(k for k in keys if k.startswith("q_"))
    subs = sorted(k for k in keys if k.startswith("hb_"))
    rows = [(k, lambda f, k=k: f.get(k, 0.0)) for k in TOP]
    rows += [(k, lambda f, k=k: f["per_system_ms"].get(k, 0.0)) for k in SPLIT + SYSTEMS + subs + queries]
    print("| | " + " | ".join("%s (%d fights)" % (n, len(fs)) for n, fs in runs) + " |")
    print("|---|" + "---|" * len(runs))
    for name, get in rows:
        print("| %s | %s |" % (name, " | ".join("%.2f" % mean([get(f) for f in fs]) for _, fs in runs)))


if __name__ == "__main__":
    main(sys.argv[1:])
