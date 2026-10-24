#!/usr/bin/env python3
"""How the gang gets to cover (Experiment B, 2026-10-23: "can the three escape the initial exchange
and create a meaningful second exchange of gunfire?").

    python3 experiments/gunfight_lab/cover_runs.py ROOT [ROOT...] [--out=FILE.md]

From each fight's decisions (the brain's `decision` lines in the timeline):

- each man's first word on cover: ran for it (how far, straight), or "no cover he can reach";
- each run for cover: how it ended (got there; hit or down on the way; gave it up: stuck or too
  long; something else first) and how long it took to get there;
- arrivals where the spot didn't hide him ("you can see him there now" within 2 s of getting there);
- per man: how often his first word was no cover, and his first run's median time to get there.
"""
import glob
import json
import os
import re
import statistics
import sys

MEN = ("brody", "lyle", "kid")


def study(root):
    runs = []  # (man, metres, seconds or None, how)
    first = {m: {"none": 0, "ran": 0, "fights": 0, "first_t": []} for m in MEN}
    seen_at_cover = arrivals = 0
    for f in sorted(glob.glob(os.path.join(root, "fights", "*.json"))):
        r = json.load(open(f))
        dec = [(float(e[0]), str(e[2])) for e in r.get("timeline", []) if e[1] == "decision"]
        events = [(float(e[0]), e[1], str(e[2])) for e in r.get("timeline", [])]
        for m in MEN:
            mine = [(t, d.split(": ", 1)[1]) for t, d in dec if d.startswith(m + ": ")]
            first[m]["fights"] += 1
            for t, d in mine:
                if d.startswith("fight from where he is: no cover"):
                    first[m]["none"] += 1
                    break
                if d.startswith("run for cover") or d.startswith("go round on you"):
                    first[m]["ran"] += 1
                    break
            open_run = None
            first_done = False
            for i, (t, d) in enumerate(mine):
                if d.startswith("run for cover") or d.startswith("go round on you"):
                    mm = re.search(r"(\d+) m$", d)
                    open_run = (t, int(mm.group(1)) if mm else -1)
                    continue
                if open_run is None:
                    continue
                t0, metres = open_run
                if d.startswith("behind cover: got there"):
                    runs.append((m, metres, t - t0, "got there"))
                    arrivals += 1
                    if any(d2.startswith("leave his cover: you can see him") and 0 <= t2 - t <= 2.0 for t2, d2 in mine[i + 1:]):
                        seen_at_cover += 1
                    if not first_done:
                        first[m]["first_t"].append(t - t0)
                if not first_done:
                    first_done = True
                elif d.startswith("give that cover up"):
                    runs.append((m, metres, None, "stuck" if "stuck" in d else "too long"))
                else:
                    runs.append((m, metres, None, "something else first"))
                open_run = None
            if open_run is not None:
                t0, metres = open_run
                hit = any(k in ("hit", "fell") and txt.startswith(m) and tt >= t0 for tt, k, txt in events)
                runs.append((m, metres, None, "hit or down on the way" if hit else "fight ended first"))
    return runs, first, seen_at_cover, arrivals


def main(argv):
    roots = [a for a in argv if not a.startswith("--")]
    out = next((a.split("=", 1)[1] for a in argv if a.startswith("--out=")), "")
    lines = ["# How the gang gets to cover", ""]
    for root in roots:
        runs, first, seen, arrivals = study(root)
        got = [x for x in runs if x[3] == "got there"]
        how = {}
        for x in runs:
            how[x[3]] = how.get(x[3], 0) + 1
        secs = [x[2] for x in got]
        speed = [x[1] / x[2] for x in got if x[2] and x[2] > 0.05 and x[1] > 0]
        lines.append("## " + os.path.basename(root.rstrip("/")))
        lines.append("")
        lines.append("- runs for cover: %d; %s" % (len(runs), ", ".join("%s %d" % kv for kv in sorted(how.items(), key=lambda kv: -kv[1]))))
        if secs:
            lines.append("- getting there: median %.1f s (90th %.1f s) for a median %d m straight; that's %.1f m/s straight (they run 3.8)" % (
                statistics.median(secs), sorted(secs)[int(0.9 * (len(secs) - 1))], statistics.median([x[1] for x in got]),
                statistics.median(speed) if speed else 0.0))
        lines.append("- got there and you could still see him within 2 s: %d of %d" % (seen, arrivals))
        lines.append("")
        lines.append("| man | first word: no cover he can reach | first word: ran for it | first run, median s to get there |")
        lines.append("|---|---|---|---|")
        for m in MEN:
            x = first[m]
            lines.append("| %s | %d of %d | %d | %s |" % (m, x["none"], x["fights"], x["ran"],
                         "%.1f" % statistics.median(x["first_t"]) if x["first_t"] else "-"))
        lines.append("")
    text = "\n".join(lines) + "\n"
    if out:
        open(out, "w").write(text)
    print(text)


if __name__ == "__main__":
    main(sys.argv[1:])
