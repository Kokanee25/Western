#!/usr/bin/env python3
"""The lab's falls in a few numbers, for comparing rounds (2026-10-21).

  python3 experiments/physics_lab/tally.py ROOT [ROOT...] [--rest] [--peaks] [--only=A,B,K_stand]

Per root: the flags by family over the falls (groups V, W and R, which aren't falls, left out);
the peaks summed and their worst (swing and twist past the limit, joint gap); and from each
summary's "rest" (lab_runner._rest): how many end on their back, side or face, up on their knees
at the end, seconds spent kneeling, and the deepest hand in his body at rest. --rest prints each
scenario's ending; --peaks each scenario's worst joint.
"""
import collections, glob, json, os, signal, sys
signal.signal(signal.SIGPIPE, signal.SIG_DFL)


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def scenarios(root):
    only = [o for o in (opt("only") or "").split(",") if o]
    for f in sorted(glob.glob(os.path.join(root, "*", "summary.json"))):
        name = os.path.basename(os.path.dirname(f))
        if name[0] in "VWR":
            continue
        if only and not any(name == o or name.startswith(o if "_" in o else o + "_") for o in only):
            continue
        yield name, os.path.dirname(f)


def tally(root):
    fam = collections.Counter()
    ends = collections.Counter()
    peaks = collections.defaultdict(list)
    kneel, kneel_s, hands, n, folded = 0, 0.0, [], 0, 0
    rows = []
    for name, d in scenarios(root):
        n += 1
        fl = json.load(open(os.path.join(d, "flags.json"))) if os.path.exists(os.path.join(d, "flags.json")) else {"flags": {}, "peaks": {}}
        for k, v in fl["flags"].items():
            fam[k] += v["count"]
        for k in ("swing_excess", "twist_excess", "joint_gap", "penetration"):
            if k in fl.get("peaks", {}):
                peaks[k].append((max(fl["peaks"][k][0], 0.0), name, fl["peaks"][k][1]))
        rest = json.load(open(os.path.join(d, "summary.json"))).get("rest", {})
        if rest:
            ends[rest["lying"]] += 1
            if rest["knee_bend"] and min(rest["knee_bend"].values()) > 120:
                folded += 1
            if rest.get("kneeling"):
                kneel += 1
            kneel_s += rest.get("kneel_s") or 0.0
            hands.append((max(rest["hand_in_body"].values()), name))
            rows.append((name, rest))
    print("%s: %d falls, %d flags %s" % (root, n, sum(fam.values()), dict(sorted(fam.items()))))
    for k, v in sorted(peaks.items()):
        w = max(v)
        print("  %-13s sum %7.2f  worst %6.3f (%s, %s)" % (k, sum(p[0] for p in v), w[0], w[1], w[2]))
    if rows:
        h = max(hands)
        print("  ends %s; both knees folded > 120 deg at rest %d; up on his knees at the end %d; kneeling %.1f s in all; deepest hand at rest %.3f m (%s); hands > 2 cm in: %d"
              % (dict(ends), folded, kneel, kneel_s, h[0], h[1], sum(1 for x in hands if x[0] > 0.02)))
    if "--rest" in sys.argv:
        for name, r in rows:
            print("    %-26s %-9s seat %s kneel %s s knees %s hands %s" % (name, r["lying"], r.get("seat_h"), r.get("kneel_s"),
                  r["knee_bend"], r["hand_in_body"]))
    if "--peaks" in sys.argv:
        for k, v in sorted(peaks.items()):
            for p in sorted(v, reverse=True)[:8]:
                print("    %-13s %7.3f %-26s %s" % (k, p[0], p[1], p[2]))


for r in [a for a in sys.argv[1:] if not a.startswith("--")]:
    tally(r)
