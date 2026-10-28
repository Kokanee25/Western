#!/usr/bin/env python3
"""Every man down in a run's fights (fall_log.gd; `run.py ... --falls=1`), issue #446: how fast he
was going, what stood in his way within 2 m, how far he travelled once limp and what he went into
and broke.

    python3 experiments/gunfight_lab/falls.py ROOT [ROOT...] [--each] [--md=OUT.md]

The headline: metres travelled, and how many falls hit or broke something (not the floor or
the ground he lands on, nor another man). `--each` lists every fall.
"""
import glob
import json
import os
import statistics
import sys

# What a touch is, from the member's kind (or the node's): the floor and ground he lands on aren't
# "something he fell into".
FLOOR = {"floor_board", "joist", "ground", "Ground", "tread", "stair_tread", "deck", "slab", "rubble", "man", "player"}


def what(t):
    kind = t.get("kind", "")
    mid = t.get("member", "")
    s = t.get("structure", "")
    if t.get("kit"):
        return "prop:" + t["kit"]
    low = (mid + " " + kind + " " + s).lower()
    for key, name in [("baluster", "rail"), ("rail", "rail"), ("newel", "rail"), ("banister", "rail"),
                      ("stair", "stair"), ("tread", "stair"), ("riser", "stair"), ("stringer", "stair"),
                      ("bar", "bar"), ("door", "door"), ("stud", "wall"), ("board", "wall"), ("siding", "wall"),
                      ("plate", "wall"), ("post", "post"), ("trim", "trim")]:
        if key in low:
            if key == "board" and kind == "floor_board":
                break
            return name
    return kind or t.get("node", "?")


def solid(t):
    return t.get("kind", "") not in FLOOR and t.get("node", "") not in FLOOR and what(t) not in ("stair",)


def load(roots):
    out = []
    for root in roots:
        for p in sorted(glob.glob(os.path.join(root, "fights", "*.json"))):
            r = json.load(open(p))
            for f in r.get("falls", []):
                f["fight"] = os.path.basename(p)[:-5]
                f["root"] = root
                out.append(f)
    return out


def summary(falls):
    n = len(falls)
    if n == 0:
        return {"falls": 0}
    moving = [f for f in falls if f.get("speed", 0) >= 0.8]
    ahead = [f for f in falls if f.get("ahead")]
    hit = [f for f in falls if any(solid(t) and t.get("speed", 0) >= 0.5 for t in f.get("touched", []))]
    broke = [f for f in falls if f.get("broke") or f.get("props_loosed")]
    # Of the props loosed near him, the ones he touched.
    def med(xs):
        return round(statistics.median(xs), 2) if xs else None
    return {
        "falls": n,
        "moving (>= 0.8 m/s)": len(moving),
        "stumbling": sum(1 for f in falls if f.get("stumbling")),
        "speed median": med([f.get("speed", 0) for f in falls]),
        "speed median, moving": med([f.get("speed", 0) for f in moving]),
        "something within 2 m ahead": len(ahead),
        "travel median (m)": med([f.get("travel", 0) for f in falls]),
        "travel median, moving (m)": med([f.get("travel", 0) for f in moving]),
        "travel max (m)": round(max(f.get("travel", 0) for f in falls), 2),
        "hit something (>= 0.5 m/s)": len(hit),
        "broke something": len(broke),
        # (Standing to lying drops his centre ~0.85 m: more is down stairs or over an edge.)
        "fell further (drop > 1.4 m)": sum(1 for f in falls if f.get("drop", 0) > 1.4),
    }


def line(f):
    touched = sorted({what(t) for t in f.get("touched", []) if solid(t)})
    ahead = f.get("ahead")
    a = "%s at %.1f m" % (what(ahead["what"]), ahead["dist"]) if ahead else "-"
    broke = ", ".join(sorted({b.get("kit") or b.get("kind", "") for b in f.get("broke", [])} | set(f.get("props_loosed", []))))
    return "| %s | %s | %s%s | %.2f | %s | %.2f | %s | %s |" % (
        f["fight"].replace("_golden_revolver_careful_studio", ""), f["id"], f.get("gait") or "stand",
        " (stumble)" if f.get("stumbling") else "", f.get("speed", 0), a, f.get("travel", 0),
        ", ".join(touched) or "-", broke or "-")


def main(argv):
    roots = [a for a in argv if not a.startswith("--")]
    each = "--each" in argv
    md = next((a.split("=", 1)[1] for a in argv if a.startswith("--md=")), None)
    rows = []
    for root in roots:
        falls = load([root])
        rows.append((root, summary(falls), falls))
    keys = []
    for _, s, _ in rows:
        for k in s:
            if k not in keys:
                keys.append(k)
    text = ["| | " + " | ".join(os.path.basename(r.rstrip("/")) for r, _, _ in rows) + " |",
            "|---|" + "---|" * len(rows)]
    for k in keys:
        text.append("| %s | %s |" % (k, " | ".join(str(s.get(k, "")) for _, s, _ in rows)))
    if each:
        for root, _, falls in rows:
            text += ["", "### " + root, "",
                     "| fight | man | going | speed | ahead | travel | into | broke/loosed |", "|---|---|---|---|---|---|---|---|"]
            text += [line(f) for f in falls]
    out = "\n".join(text)
    print(out)
    if md:
        open(md, "w").write(out + "\n")


if __name__ == "__main__":
    main(sys.argv[1:])
