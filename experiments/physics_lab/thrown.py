#!/usr/bin/env python3
"""Issue #596 step 3b: how far and how high each man was thrown, from a run's ticks.csv.

  python3 experiments/physics_lab/thrown.py ROOT [ROOT...]

Per scenario: the lift it was given (m/s), the arc's top (his weight's centre over where it
started, m), how far it went along the ground (m) by the time he first came down to lying height
and at the end, his turn in the air (degrees, the chest about its own axes isn't logged: the
summary's rest), what the blast and the landing did (harm), members broken, and the frame.
"""
import csv, json, math, os, sys


def one(d):
    s = json.load(open(os.path.join(d, "summary.json")))
    rows = list(csv.DictReader(open(os.path.join(d, "ticks.csv"))))
    hit = next((i for i, r in enumerate(rows) if r["phase"] != "before"), 0)
    x0, y0, z0 = (float(rows[hit][k]) for k in ("com_x", "com_y", "com_z"))
    top = max(float(r["com_y"]) for r in rows[hit:]) - y0
    land = None
    for r in rows[hit + 6:]:
        if float(r["com_y"]) < 0.35:
            land = r
            break
    def flat(r):
        return math.hypot(float(r["com_x"]) - x0, float(r["com_z"]) - z0)
    ev = s.get("events", [])
    blast = next((e for e in ev if e.get("kind") == "blast"), {})
    broke = sum(1 for e in ev if e.get("kind") == "member_broken")
    blows = [e for e in ev if e.get("kind") == "blow"]
    ms = s.get("frame_ms", {})
    return {
        "scenario": s["scenario"], "lift": round(float(blast.get("lift", 0.0)), 2),
        "top": round(top, 2), "land_d": round(flat(land), 2) if land else None,
        "land_t": round(float(land["t"]) - float(rows[hit]["t"]), 2) if land else None,
        "end_d": round(flat(rows[-1]), 2), "harm": blast.get("harm", []), "broke": broke,
        "landing": ["%s %.0f J%s" % (b["segment"], b["joules"], (": " + ", ".join(b["harm"])) if b["harm"] else "") for b in blows],
        "rest": s.get("rest", {}).get("on"), "frame_p99": ms.get("p99"), "frame_max": ms.get("max"),
    }


def main():
    for root in sys.argv[1:]:
        print("##", root)
        for name in sorted(os.listdir(root)):
            d = os.path.join(root, name)
            if os.path.exists(os.path.join(d, "summary.json")):
                r = one(d)
                print("{scenario:24s} lift {lift:5.2f}  top {top:5.2f}  land {land_d} m at {land_t} s  end {end_d:5.2f}  broke {broke:2d}  rest {rest}  frame p99 {frame_p99} max {frame_max}".format(**r))
                print("    harm:", ", ".join(r["harm"]))
                if r["landing"]:
                    print("    landing:", "; ".join(r["landing"]))


if __name__ == "__main__":
    main()
