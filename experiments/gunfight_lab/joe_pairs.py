#!/usr/bin/env python3
"""Seed by seed, without Joe and with him (#859): where you live in one and go down in the other.

    python3 experiments/gunfight_lab/joe_pairs.py build/A_nojoe build/B_joe [--show=SEED] [--why]

For each seed: you alive or down in each run, the fight's length, when you were first hit and by
whom, and with Joe his shots, hits and seconds holding fire. --why: for the seeds you lived without
him and went down with him, who hit you and when, and Joe's own lines of the timeline (his changes
of mind) up to your going down. --show=SEED: that seed's two timelines' hits, shots and Joe lines.
"""
import glob
import json
import os
import re
import sys


def load(root):
    out = {}
    for f in glob.glob(os.path.join(root, "fights", "*.json")):
        with open(f) as fh:
            r = json.load(fh)
        out[int(r["seed"])] = r
    return out


def main(argv):
    roots = [a for a in argv if not a.startswith("--")]
    show = next((int(a.split("=")[1]) for a in argv if a.startswith("--show=")), None)
    a, b = load(roots[0]), load(roots[1])
    print("seed | without: alive, s, first hit | with Joe: alive, s, first hit | Joe shots/hits, held")
    flips = []
    for s in sorted(set(a) & set(b)):
        ra, rb = a[s], b[s]
        la, lb = not ra["you"]["down"], not rb["you"]["down"]
        j = rb.get("joe", {})
        mark = "  <- worse with Joe" if la and not lb else "  <- better with Joe" if lb and not la else ""
        print("%3d | %-5s %5.0f %6s | %-5s %5.0f %6s | %d/%d held %s%s" % (
            s, la, ra["length_s"], "%.1f" % ra["you"]["first_hit_at"], lb, rb["length_s"], "%.1f" % rb["you"]["first_hit_at"],
            j.get("shots", 0), j.get("hits", 0), j.get("held_fire", "-"), mark))
        if la and not lb:
            flips.append(s)
    print("worse with Joe:", flips)
    if "--why" in argv or show is not None:
        for s in ([show] if show is not None else flips):
            rb = b[s]
            print("\n== seed %d with Joe: ending %s at %.1f s; first hit %.1f by %s" % (
                s, rb["ending"], rb["length_s"], rb["you"]["first_hit_at"], rb.get("first_hit_by")))
            for e in rb["timeline"]:
                kind, what = e[1], e[2]
                if kind in ("joe", "end", "start", "hit", "out") or re.search(r"\bjoe\b", what, re.I) and kind in ("shot", "said", "decision"):
                    print("  %6.1f %-9s %s" % (e[0], kind, what[:150]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
