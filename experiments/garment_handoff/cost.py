#!/usr/bin/env python3
"""The garment handoff's cost table (#895): bench runs with the glove and bare (the same hands,
nothing on them), each phase's mean tick and the glove's own systems, scaled to Sean's core.

    python3 experiments/garment_handoff/cost.py build/gh/perf_glove_* -- build/gh/perf_bare_* > cost.md
"""
import json
import sys

SCALE = 0.65  # this workspace's 2.1 GHz core to Sean's 3.25 GHz (CLAUDE.md's frame budget)
PHASES = ["worn", "present", "reach", "take", "draw", "toss", "lie", "rest"]
OWN = ["garment", "glove_handoff", "cloth"]


def load(dirs):
    out = []
    for d in dirs:
        out.append(json.load(open(d + "/summary.json")))
    return out


def mean(xs):
    return sum(xs) / len(xs) if xs else float("nan")


def main():
    args = sys.argv[1:]
    cut = args.index("--")
    glove, bare = load(args[:cut]), load(args[cut + 1:])
    print("| Phase | ticks | tick, glove (ms) | tick, bare (ms) | difference | GarmentHandoff (rule, skin shape) | the lab's choreography | ClothProp script |")
    print("|---|---|---|---|---|---|---|---|")
    for ph in PHASES:
        g = [r["phase_ms"][ph] for r in glove if ph in r["phase_ms"]]
        b = [r["phase_ms"][ph] for r in bare if ph in r["phase_ms"]]
        if not g:
            continue
        gm = mean([x["median"] for x in g]) * SCALE
        bm = mean([x["median"] for x in b]) * SCALE if b else float("nan")
        own = [mean([x.get(k, 0.0) for x in g]) * SCALE for k in OWN]
        n = int(mean([x["n"] for x in g]))
        print(f"| {ph} | {n} | {gm:.2f} | {bm:.2f} | {gm - bm:+.2f} | {own[0]:.2f} | {own[1]:.2f} | {own[2]:.3f} |")
    rests = [r["handoff"].get("rest_at", -1) for r in glove]
    print()
    print(f"Medians of each phase's ticks (wall clock, the whole tick), the mean of {len(glove)} runs each way, x{SCALE} "
          f"to Sean's core. Glove at rest after {', '.join(f'{x:.2f}' for x in rests)} s from the cue.")


main()
