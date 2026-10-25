#!/usr/bin/env python3
"""Where the gang spends a fight (the saloon dressed for cover, 2026-10-24): each man's share of
his fighting time hidden, peeking, in the open and running for cover, from the fights' tracks
(one row every half second or so).

    python3 experiments/gunfight_lab/tactics.py ROOT [ROOT...] [--out=FILE.md]

Only rows where he's fighting or reloading count. Also each fight's share of rows where he's in
the open (not hidden, peeking or moving), and you crouched.
"""
import glob
import json
import os
import sys

KINDS = ("hidden", "peeking", "open", "moving", "searching", "rescuing")


def study(root):
    n = {k: 0 for k in KINDS}
    total = 0
    you_crouched = you_rows = 0
    for f in sorted(glob.glob(os.path.join(root, "fights", "*.json"))):
        r = json.load(open(f))
        for row in r.get("track", []):
            you = row.get("you")
            if you:
                you_rows += 1
                you_crouched += 1 if you[2] else 0
            for m in row.get("men", {}).values():
                if len(m) < 4 or m[3] not in ("fighting", "reloading"):
                    continue
                total += 1
                if m[2] in n:
                    n[m[2]] += 1
    return n, total, you_crouched, you_rows


def main(argv):
    roots = [a for a in argv if not a.startswith("--")]
    out = next((a.split("=", 1)[1] for a in argv if a.startswith("--out=")), "")
    head = ["run"] + list(KINDS) + ["you crouched"]
    lines = ["# Where the gang spends a fight (share of fighting time)", "", "| " + " | ".join(head) + " |", "|" + "---|" * len(head)]
    for root in roots:
        n, total, yc, yr = study(root)
        lines.append("| " + " | ".join([os.path.basename(root.rstrip("/"))] + ["%d%%" % round(100.0 * n[k] / max(total, 1)) for k in KINDS]
                                         + ["%d%%" % round(100.0 * yc / max(yr, 1))]) + " |")
    text = "\n".join(lines) + "\n"
    if out:
        open(out, "w").write(text)
    print(text)


if __name__ == "__main__":
    main(sys.argv[1:])
