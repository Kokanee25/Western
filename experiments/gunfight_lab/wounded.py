#!/usr/bin/env python3
"""Do wounded men keep fighting? (Experiment A, 2026-10-23: "if Brody takes a survivable wound,
does he continue creating tactical problems for the player?")

    python3 experiments/gunfight_lab/wounded.py ROOT [ROOT...] [--out=FILE.md]

Each ROOT is a run.py output. A ball that hits a man is his timeline's `hit` lines at one moment
(a ball through two parts is two lines). For each ROOT:

- balls that hit the gang; the share after which that man fired again, and how soon (median s);
- of those, the balls that left him on his feet (no `fell` within 1 s) and the ones that dropped him;
- shots fired by men already down (after a `fell` of theirs), and the share of fallen men who fired;
- shots the gang fired after their first ball hit them (a man's own), a fight.
"""
import glob
import json
import os
import statistics
import sys

MEN = ("brody", "lyle", "kid")


def study(root):
    balls = again = stood = stood_again = dropped = dropped_again = 0
    gaps = []
    floor_shots = fallen = fallen_fired = 0
    after_first = []
    for f in sorted(glob.glob(os.path.join(root, "fights", "*.json"))):
        r = json.load(open(f))
        tl = r.get("timeline", [])
        by_man = {m: {"hits": [], "shots": [], "fell": []} for m in MEN}
        for e in tl:
            t, kind, text = float(e[0]), e[1], str(e[2])
            who = text.split(" ")[0]
            if who not in by_man:
                continue
            if kind == "hit":
                if not by_man[who]["hits"] or t - by_man[who]["hits"][-1] > 0.05:
                    by_man[who]["hits"].append(t)
            elif kind == "shot":
                by_man[who]["shots"].append(t)
            elif kind == "fell":
                by_man[who]["fell"].append(t)
        shots_after = 0
        for m, d in by_man.items():
            for t in d["hits"]:
                balls += 1
                nxt = [s for s in d["shots"] if s > t]
                down = any(t <= x <= t + 1.0 for x in d["fell"])
                if down:
                    dropped += 1
                else:
                    stood += 1
                if nxt:
                    again += 1
                    gaps.append(nxt[0] - t)
                    if down:
                        dropped_again += 1
                    else:
                        stood_again += 1
            if d["fell"]:
                fallen += 1
                fs = [s for s in d["shots"] if s > d["fell"][0]]
                floor_shots += len(fs)
                fallen_fired += 1 if fs else 0
            if d["hits"]:
                shots_after += len([s for s in d["shots"] if s > d["hits"][0]])
        after_first.append(shots_after)
    n = len(after_first)
    pct = lambda a, b: "%d%%" % round(100.0 * a / b) if b else "-"
    return {
        "fights": n, "balls": balls, "again": pct(again, balls),
        "gap": "%.1f" % statistics.median(gaps) if gaps else "-",
        "stood": stood, "stood_again": pct(stood_again, stood),
        "dropped": dropped, "dropped_again": pct(dropped_again, dropped),
        "fallen": fallen, "fallen_fired": pct(fallen_fired, fallen), "floor_shots": floor_shots,
        "after_first": "%.1f" % (sum(after_first) / n) if n else "-",
    }


def main(argv):
    roots = [a for a in argv if not a.startswith("--")]
    out = next((a.split("=", 1)[1] for a in argv if a.startswith("--out=")), "")
    head = ["run", "fights", "balls on them", "fired again", "first shot after (med s)", "stayed up",
            "of those fired again", "dropped", "of those fired again", "men down", "fired from the floor",
            "shots from the floor", "their shots after being hit, a fight"]
    lines = ["# Do wounded men keep fighting?", "", "| " + " | ".join(head) + " |", "|" + "---|" * len(head)]
    for root in roots:
        x = study(root)
        lines.append("| " + " | ".join([os.path.basename(root.rstrip("/")), str(x["fights"]), str(x["balls"]), x["again"], x["gap"],
                                        str(x["stood"]), x["stood_again"], str(x["dropped"]), x["dropped_again"],
                                        str(x["fallen"]), x["fallen_fired"], str(x["floor_shots"]), x["after_first"]]) + " |")
    text = "\n".join(lines) + "\n"
    if out:
        open(out, "w").write(text)
    print(text)


if __name__ == "__main__":
    main(sys.argv[1:])
