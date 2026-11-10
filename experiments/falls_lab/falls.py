#!/usr/bin/env python3
"""The falls lab's table (issue #759): python3 experiments/falls_lab/falls.py RUN [--md=OUT.md]
One row a height, a cell a pose: of the men dropped, how many died (in ten minutes), and the
worst injuries' counts, beside Sean's table on #762 (TARGET)."""
import json, sys, os
from collections import Counter, defaultdict

# Sean's table (#762), as shares of men: dead, and the injury it names.
TARGET = {
    ("feet", 2): "foot 1/10", ("feet", 3): "foot 1/3, shin 1/10", ("feet", 4.5): "heel/shin 6/10, lives",
    ("feet", 6): "legs 8/10, pelvis 3/10, dead 1/20", ("feet", 9): "legs+pelvis, dead 2/10", ("feet", 12): "dead 4/10",
    ("feet", 15): "dead 1/2", ("feet", 22): "dead 9/10",
    ("back", 2): "bruised", ("back", 3): "ribs 1/3", ("back", 4.5): "ribs 6/10, organ 2/10, lives",
    ("back", 6): "dead 1/6", ("back", 9): "dead 4/10", ("back", 12): "dead 6/10", ("back", 15): "dead 3/4", ("back", 22): "dead",
    ("head", 2): "out cold, skull 1/10", ("head", 3): "skull 4/10, dead 2/10", ("head", 4.5): "dead 1/2",
    ("head", 6): "dead 8/10", ("head", 9): "dead", ("head", 12): "dead", ("head", 15): "dead", ("head", 22): "dead",
    ("feet", 1): "nothing", ("back", 1): "nothing", ("head", 1): "nothing",
}

WORDS = [("dead", None), ("skull crushed", "crushed"), ("neck broken", "neck"), ("aorta torn", "aorta"),
         ("back broken", "back"), ("skull cracked", "skull"), ("concussion", "cold"), ("ribs broken", "ribs"),
         ("lung bruised", "lung"), ("liver burst", "organ"), ("spleen burst", "organ"), ("pelvis broken", "pelvis"),
         ("thigh broken", "thigh"), ("shin broken", "shin"), ("foot broken", "foot")]


def cell(rows):
    n = len(rows)
    c = Counter()
    for r in rows:
        if r["dead"]:
            c["dead"] += 1
        seen = set()
        for h in r["harm"]:
            for w, key in WORDS:
                if key and h == w:
                    seen.add(key)
        for k in seen:
            c[k] += 1
    order = ["dead", "crushed", "neck", "aorta", "back", "skull", "cold", "ribs", "lung", "organ", "pelvis", "thigh", "shin", "foot"]
    return n, ", ".join("%s %d" % (k, c[k]) for k in order if c[k])


def through_table(rows):
    """--onto runs: per height and pose, how many went through and how many broke a board."""
    by = defaultdict(list)
    for r in rows:
        by[(r["pose"], r["height"])].append(r)
    poses = sorted({k[0] for k in by})
    lines = ["| Fell onto %s from | " % rows[0]["onto"] + " | ".join(poses) + " |", "|---|" + "---|" * len(poses)]
    for h in sorted({k[1] for k in by}):
        cells = []
        for p in poses:
            rs = by.get((p, h), [])
            needs = sorted(r.get("need", 0) for r in rs)
            cells.append("through %d, a board broken %d (of %d); need %.2f/%.2f/%.2f" % (sum(r["through"] for r in rs), sum(bool(r["broke"]) for r in rs), len(rs),
                         needs[len(needs) // 4], needs[len(needs) // 2], needs[3 * len(needs) // 4]))
        lines.append("| %g m | " % h + " | ".join(cells) + " |")
    return "\n".join(lines)


def main():
    run = sys.argv[1]
    rows = json.load(open(os.path.join(run, "falls.json")))
    if rows and rows[0].get("onto"):
        md = through_table(rows)
        print(md)
        out = next((a.split("=", 1)[1] for a in sys.argv[2:] if a.startswith("--md=")), None)
        if out:
            open(out, "w").write(md + "\n")
        return
    by = defaultdict(list)
    for r in rows:
        by[(r["pose"], r["height"])].append(r)
    poses = [p for p in ("feet", "back", "head") if any(k[0] == p for k in by)]
    heights = sorted({k[1] for k in by})
    lines = ["| Height | " + " | ".join(poses) + " |", "|---|" + "---|" * len(poses)]
    undrawn = [r for r in rows if not r.get("drawn", True)]
    print("not drawn where they lay: %d of %d" % (len(undrawn), len(rows)))
    for h in heights:
        cells = []
        for p in poses:
            rs = by.get((p, h), [])
            if not rs:
                cells.append("")
                continue
            n, txt = cell(rs)
            sp = sum(r["speed"] for r in rs) / n
            tgt = TARGET.get((p, h if h != int(h) else int(h)), "")
            cells.append("%s<br>of %d, %.1f m/s; *target: %s*" % (txt or "nothing", n, sp, tgt))
        lines.append("| %g m | " % h + " | ".join(cells) + " |")
    md = "\n".join(lines)
    print(md)
    out = next((a.split("=", 1)[1] for a in sys.argv[2:] if a.startswith("--md=")), None)
    if out:
        open(out, "w").write(md + "\n")


if __name__ == "__main__":
    main()
