#!/usr/bin/env python3
"""The chair falls' own measures (group U; 2026-10-24, results/2026-10-24_chair_tip/).

  python3 experiments/physics_lab/chair_measure.py ROOT [ROOT...] [--only=U_a,U_b] [--json=OUT]

From each scenario's segments.csv, chair.csv and man.csv (lab_runner writes the last two for the
kit chair). Times are from the cause (the tick the chair's first piece broke). His frame: -z is
the way he faced, +z behind him, +x his right.

- tip: does the chair pivot back on its front legs with him, or fold flat and drop him?
  - drop15_s: how long until his pelvis has dropped 15 cm;
  - head_back_at_drop15: how far back his head has gone by then (m), and pelvis_back the same for
    his hips: a tip carries his head and shoulders back first, a drop sinks him straight down;
  - seat_pitch_at_drop15: the seat's tilt back (deg; + is back);
  - feet_slide: how far the chair's front feet slid by 0.6 s (m; a pivot keeps them put);
  - floor_s: how long until his pelvis is down (under 0.3 m).
- head: his head against his chest as he goes (deg, + is back from how he held it as he went):
  loll_max over 1.5 s and loll_s, how long it's more than 25 deg back.
- turn: his shoulder line's turn about the vertical by 1.5 s (deg) and its most tip (deg, + his
  right shoulder up), where his head went sideways by 1 s (x: + his right) and his pelvis by 1.5 s;
  the chair pieces' fastest sideways speed in the first 0.3 s.
- rise: from man.csv: when he started up, how long each stage held, how long it all took, the
  deepest his legs went into the wreck while rising, and his hat at the end.
"""
import csv
import json
import math
import os
import sys


def arg(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def qmul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz)


def qconj(q):
    return (-q[0], -q[1], -q[2], q[3])


def qrot(q, v):
    p = qmul(qmul(q, (v[0], v[1], v[2], 0.0)), qconj(q))
    return (p[0], p[1], p[2])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def load_segments(path):
    by_tick = {}
    with open(path) as f:
        for r in csv.DictReader(f):
            t = int(r["tick"])
            by_tick.setdefault(t, {})[r["segment"]] = {
                "p": (float(r["px"]), float(r["py"]), float(r["pz"])),
                "q": (float(r["qx"]), float(r["qy"]), float(r["qz"]), float(r["qw"]))}
    return by_tick


def load_rows(path):
    if not os.path.exists(path):
        return []
    with open(path) as f:
        return list(csv.DictReader(f))


def head_back(seg):
    """His head's tilt back against his chest (deg): the head's up in the chest's frame, toward
    the chest's back (+z) positive."""
    up = qrot(qmul(qconj(seg["chest"]["q"]), seg["head"]["q"]), (0, 1, 0))
    return math.degrees(math.atan2(up[2], up[1]))


def yaw_of(q):
    f = qrot(q, (0, 0, -1))
    return math.degrees(math.atan2(-f[0], -f[2]))


def measure(run):
    seg = load_segments(os.path.join(run, "segments.csv"))
    chair = load_rows(os.path.join(run, "chair.csv"))
    man = load_rows(os.path.join(run, "man.csv"))
    out = {"scenario": os.path.basename(run)}
    if not seg or not chair:
        return out
    # The cause: the first tick with a piece of chair loose.
    t0 = min((int(r["tick"]) for r in chair if r["piece"] != "standing"), default=None)
    if t0 is None:
        out["note"] = "the chair never broke"
        return out
    stand = [r for r in chair if r["piece"] == "standing" and int(r["tick"]) < t0]
    cxf = stand[-1] if stand else None
    ticks = sorted(t for t in seg if t >= t0)
    start = seg[t0 - 1] if (t0 - 1) in seg else seg[ticks[0]]
    p0 = start["pelvis"]["p"]
    h0 = start["head"]["p"]
    # Tip or drop.
    drop_t = None
    floor_t = None
    for t in ticks:
        s = seg[t]
        if drop_t is None and p0[1] - s["pelvis"]["p"][1] >= 0.15:
            drop_t = t
        if floor_t is None and s["pelvis"]["p"][1] < 0.3:
            floor_t = t
    out["drop15_s"] = round((drop_t - t0) / 60.0, 3) if drop_t else None
    out["floor_s"] = round((floor_t - t0) / 60.0, 3) if floor_t else None
    if drop_t:
        s = seg[drop_t]
        out["head_back_at_drop15"] = round(s["head"]["p"][2] - h0[2], 3)
        out["head_drop_at_drop15"] = round(h0[1] - s["head"]["p"][1], 3)
        out["pelvis_back_at_drop15"] = round(s["pelvis"]["p"][2] - p0[2], 3)
    # The seat's piece: its tilt and the front feet.
    seat_rows = {}
    for r in chair:
        if "seat" in r["members"].split("+") and r["piece"] != "standing":
            seat_rows.setdefault(int(r["tick"]), r)
    if seat_rows and cxf:
        first = seat_rows[min(seat_rows)]
        cq = tuple(float(cxf[k]) for k in ("qx", "qy", "qz", "qw"))
        cp = tuple(float(cxf[k]) for k in ("px", "py", "pz"))
        q0 = tuple(float(first[k]) for k in ("qx", "qy", "qz", "qw"))
        o0 = tuple(float(first[k]) for k in ("px", "py", "pz"))
        feet_local = []
        members = first["members"].split("+")
        for leg, x in (("leg_front_l", -0.19), ("leg_front_r", 0.19)):
            if leg in members:
                w = qrot(cq, (x, 0.0, 0.2))
                w = (w[0] + cp[0], w[1] + cp[1], w[2] + cp[2])
                feet_local.append(qrot(qconj(q0), sub(w, o0)))

        def feet_at(r):
            q = tuple(float(r[k]) for k in ("qx", "qy", "qz", "qw"))
            o = tuple(float(r[k]) for k in ("px", "py", "pz"))
            return [tuple(a + b for a, b in zip(qrot(q, fl), o)) for fl in feet_local]

        def pitch_at(r):
            q = tuple(float(r[k]) for k in ("qx", "qy", "qz", "qw"))
            up = qrot(q, (0, 1, 0))
            return math.degrees(math.atan2(up[2], up[1]))

        feet0 = feet_at(first)
        if drop_t and drop_t in seat_rows:
            out["seat_pitch_at_drop15"] = round(pitch_at(seat_rows[drop_t]), 1)
        t6 = min(seat_rows, key=lambda t: abs(t - (t0 + 36)))
        if feet0:
            f6 = feet_at(seat_rows[t6])
            out["feet_slide_0.6s"] = round(max(math.hypot(a[0] - b[0], a[2] - b[2]) for a, b in zip(f6, feet0)), 3)
            out["feet_lift_0.6s"] = round(max(a[1] - b[1] for a, b in zip(f6, feet0)), 3)
        out["seat_pitch_0.3_0.6_1.0"] = [round(pitch_at(seat_rows[min(seat_rows, key=lambda t: abs(t - (t0 + k)))]), 1) for k in (18, 36, 60)]
        out["seat_piece"] = first["members"]
    # His head against his chest.
    hb0 = head_back(start)
    lolls = [(t, head_back(seg[t]) - hb0) for t in ticks if t <= t0 + 90]
    out["loll_max"] = round(max(l for _, l in lolls), 1)
    out["loll_s"] = round(sum(1 for _, l in lolls if l > 25.0) / 60.0, 3)
    out["loll_at_0.2_0.4_0.6_0.8"] = [round(dict(lolls).get(t0 + k, float("nan")), 1) for k in (12, 24, 36, 48)]
    # His turn and where he went.
    t15 = min(ticks, key=lambda t: abs(t - (t0 + 90)))
    t10 = min(ticks, key=lambda t: abs(t - (t0 + 60)))

    def shoulders(q):
        x = qrot(q, (1, 0, 0))
        return math.degrees(math.atan2(-x[2], x[0])), math.degrees(math.asin(max(-1.0, min(1.0, x[1]))))

    y0, _ = shoulders(start["chest"]["q"])
    y1, _ = shoulders(seg[t15]["chest"]["q"])
    # The line of his shoulders turned about the vertical (+: his left shoulder back, turned to his
    # right) and tipped (+: right shoulder up), whichever way he lies.
    out["shoulder_turn_1.5s"] = round((y1 - y0 + 180.0) % 360.0 - 180.0, 1)
    rolls = [shoulders(seg[t]["chest"]["q"])[1] for t in ticks if t <= t0 + 90]
    out["shoulder_tip_extreme"] = round(max(rolls, key=abs), 1)
    out["head_x_1.0s"] = round(seg[t10]["head"]["p"][0] - h0[0], 2)
    out["pelvis_moved_1.5s"] = [round(a - b, 2) for a, b in zip(seg[t15]["pelvis"]["p"], p0)]
    side = 0.0
    for r in chair:
        if r["piece"] != "standing" and t0 <= int(r["tick"]) <= t0 + 18:
            side = max(side, abs(float(r["vx"])))
    out["pieces_side_speed_max"] = round(side, 2)
    out["pieces"] = len({r["piece"] for r in chair if r["piece"] != "standing"})
    # Getting up.
    if man:
        rising = [r for r in man if r["rising"] == "1"]
        if rising:
            rt0 = int(rising[0]["tick"])
            rt1 = int(rising[-1]["tick"])
            out["rise_start_s"] = round((rt0 - t0) / 60.0, 2)
            out["rise_s"] = round((rt1 - rt0 + 1) / 60.0, 2)
            stages = []
            for r in rising:
                if not stages or stages[-1][0] != r["pose"]:
                    stages.append([r["pose"], 0])
                stages[-1][1] += 1
            out["stages"] = [[p, round(n / 60.0, 2)] for p, n in stages]
            out["legs_in_wreck_max"] = round(max(float(r["legs_in_wreck_m"]) for r in rising), 3)
            out["legs_in_wreck_s"] = round(sum(1 for r in rising if float(r["legs_in_wreck_m"]) > 0.03) / 60.0, 2)
        out["hat_off_end"] = man[-1]["hat_off"] == "1"
        out["pose_end"] = man[-1]["pose"]
    return out


def main():
    roots = [a for a in sys.argv[1:] if not a.startswith("--")]
    only = arg("only")
    rows = []
    for root in roots:
        for name in sorted(os.listdir(root)):
            run = os.path.join(root, name)
            if not os.path.isdir(run) or not name.startswith("U_"):
                continue
            if only and name not in only.split(","):
                continue
            m = measure(run)
            m["root"] = os.path.basename(os.path.normpath(root))
            rows.append(m)
    for m in rows:
        print("%s/%s" % (m["root"], m["scenario"]))
        for k, v in m.items():
            if k not in ("root", "scenario"):
                print("    %-24s %s" % (k, v))
    if arg("json"):
        with open(arg("json"), "w") as f:
            json.dump(rows, f, indent=1)


if __name__ == "__main__":
    main()
