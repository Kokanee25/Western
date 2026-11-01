#!/usr/bin/env python3
"""The people after a blast (#495): tools/people_after_blast.gd's JSON runs side by side.

    python3 experiments/people_after_blast/summary.py RUN.json [RUN2.json ...] [--scale=0.65]

For each run: before the stick (s < 0), the first 7 s after (the townsfolk cower) and 7 s on
(shaken): the men ticked a tick, the men in a slowed band, the people's ms a tick (here and at
Sean's clock) and its parts, and the commonest reasons a man ticked every tick.
"""
import json
import sys

TIMERS = ["people_body", "people_skeleton", "senses", "civilian_brain", "outlaw_brain", "people_prep_sum"]


def mean(rows, k):
    return sum(r.get(k, 0.0) for r in rows) / max(len(rows), 1)


def main():
    scale = 0.65
    paths = []
    for a in sys.argv[1:]:
        if a.startswith("--scale="):
            scale = float(a[8:])
        else:
            paths.append(a)
    print("%-28s %-8s %6s %5s %6s %6s | %s | why (a tick)" % ("run", "window", "ticked", "slow", "ms", "Sean", " ".join("%6s" % t[:6] for t in TIMERS)))
    for p in paths:
        d = json.load(open(p))
        rows = d["rows"]
        for name, sel in [("before", lambda s: s < 0), ("0-6 s", lambda s: 0 <= s < 7), ("7 s on", lambda s: s >= 7)]:
            rs = [r for r in rows if sel(r["s"])]
            if not rs:
                continue
            why = {k[7:]: mean(rs, k) for k in {k for r in rs for k in r if k.startswith("n_full_")}}
            top = ", ".join("%s %.1f" % (k, v) for k, v in sorted(why.items(), key=lambda kv: -kv[1])[:4] if v >= 0.05)
            ms = mean(rs, "people_ms")
            print("%-28s %-8s %6.1f %5.1f %6.2f %6.2f | %s | %s" % (p.split("/")[-1][:28], name, mean(rs, "n_people_ticked"),
                    mean(rs, "n_slow"), ms, ms * scale, " ".join("%6.2f" % mean(rs, t) for t in TIMERS), top))


if __name__ == "__main__":
    main()
