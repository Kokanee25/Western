#!/usr/bin/env python3
"""Joe beside you or not (#843, No Justice step 1): two runs of the gunfight lab side by side.

    python3 experiments/gunfight_lab/joe_stats.py build/gf_nojoe build/gf_joe [--md=FILE]

For each run: you alive (not down), how the fight ended, its length, your shots and hits, the
gang's shots and hits on you; with Joe, his shots, hits (and on your man), the men he put out and
you put out, his seconds in your line of fire (and the steps he took out of it), how often he held
fire on your man, your balls in him, the gang's balls in him, his downs, and his calls.
"""
import glob
import json
import os
import statistics as st
import sys


def load(root):
    out = []
    for f in sorted(glob.glob(os.path.join(root, "fights", "*.json"))):
        with open(f) as fh:
            out.append(json.load(fh))
    return out


def med(xs):
    return st.median(xs) if xs else 0.0


def summary(recs):
    n = len(recs)
    alive = sum(1 for r in recs if not r["you"]["down"])
    lengths = [r["length_s"] for r in recs]
    ends = {}
    for r in recs:
        ends[r["ending"]] = ends.get(r["ending"], 0) + 1
    row = {
        "fights": n,
        "you alive": f"{alive} of {n}",
        "length median (s)": round(med(lengths), 1),
        "length range (s)": f"{min(lengths):.0f}-{max(lengths):.0f}" if lengths else "-",
        "your hits taken (mean)": round(st.mean([r["you"]["hits_taken"] for r in recs]), 2) if n else 0,
        "your shots (mean)": round(st.mean([r["you"]["shots"] for r in recs]), 1) if n else 0,
        "gang shots (mean)": round(st.mean([r["gang"]["shots"] for r in recs]), 1) if n else 0,
        "endings": ", ".join(f"{k} {v}" for k, v in sorted(ends.items())),
    }
    joes = [r["joe"] for r in recs if "joe" in r]
    if joes:
        def tot(k):
            return sum(j[k] for j in joes)
        row.update({
            "Joe's shots (all)": tot("shots"),
            "Joe's hits (all)": tot("hits"),
            "of them on your man": tot("hits_on_your_man"),
            "men put out by you / Joe / nobody's ball": "%d / %d / %d" % (
                sum(j["put_out"]["you"] for j in joes), sum(j["put_out"]["joe"] for j in joes), sum(j["put_out"]["none"] for j in joes)),
            "Joe in your line (s, median / max)": f"{med([j['line_s'] for j in joes]):.2f} / {max(j['line_s'] for j in joes):.2f}",
            "Joe in your line (share of the fight)": "%.1f%%" % (100.0 * sum(j["line_s"] for j in joes) / max(sum(lengths), 0.01)),
            "steps out of your line (all)": tot("line_steps"),
            "your balls in Joe (all)": tot("hit_by_you"),
            "gang's shots at Joe / hits on him (all)": f"{tot('gang_shots_at_him')} / {tot('hits_taken')}",
            "Joe down (fights)": sum(1 for j in joes if j["downs"] > 0),
            "Joe up at the end (fights)": sum(1 for j in joes if j["conscious"]),
            "Joe dead": sum(1 for j in joes if not j["alive"]),
            "Joe's calls (median a fight)": med([j["calls"] for j in joes]),
        })
    return row


def main(argv):
    roots = [a for a in argv if not a.startswith("--")]
    md = next((a.split("=", 1)[1] for a in argv if a.startswith("--md=")), None)
    rows = [(os.path.basename(r.rstrip("/")), summary(load(r))) for r in roots]
    keys = []
    for _, row in rows:
        for k in row:
            if k not in keys:
                keys.append(k)
    lines = ["| | " + " | ".join(n for n, _ in rows) + " |", "|---|" + "---|" * len(rows)]
    for k in keys:
        lines.append(f"| {k} | " + " | ".join(str(row.get(k, "-")) for _, row in rows) + " |")
    text = "\n".join(lines)
    print(text)
    if md:
        with open(md, "w") as fh:
            fh.write(text + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
