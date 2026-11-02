#!/usr/bin/env python3
"""The gang's shots by kind (#566): stepped out from a post, pointed round one, aimed from one
(the regular post style), and every other shot; how far off the barrel was from where he meant it
(degrees), the range, and how many of those shots hit you. A shot's kind is the sixth field of
fight.gd's `shot_errors` (runs made after it was added); a hit is the shot of that man's that went
off last before it, within 0.6 s.

    python3 shots.py RUN [RUN...]
"""
import glob
import json
import os
import statistics
import sys


def kinds(run):
    out = {}
    for f in glob.glob(os.path.join(run, "fights", "*.json")):
        d = json.load(open(f))
        hits = [e for e in d.get("timeline", []) if e[1] == "hit" and e[2].startswith("you hit")]
        for mid, m in d.get("men", {}).items():
            errs = m.get("shot_errors", [])
            mine = [e[0] for e in hits if e[2].endswith("by " + mid)]
            hit_shots = set()
            for ht in mine:
                before = [i for i, e in enumerate(errs) if e[0] <= ht + 0.01 and ht - e[0] < 0.6]
                if before:
                    hit_shots.add(before[-1])
            for i, e in enumerate(errs):
                k = e[5] if len(e) > 5 and e[5] else "other"
                out.setdefault(k, []).append((e[1], e[2], i in hit_shots))
    return out


def main():
    print("| Run | Kind | Shots | Error deg (med) | Range m (med) | Hits on you | Shots a hit |")
    print("|---|---|---|---|---|---|---|")
    for run in sys.argv[1:]:
        for k, v in sorted(kinds(run).items()):
            h = sum(1 for x in v if x[2])
            print("| %s | %s | %d | %.2f | %.1f | %d | %s |" % (os.path.basename(run.rstrip("/")), k, len(v),
                statistics.median(x[0] for x in v), statistics.median(x[1] for x in v), h,
                "%.1f" % (len(v) / h) if h else "-"))


if __name__ == "__main__":
    main()
