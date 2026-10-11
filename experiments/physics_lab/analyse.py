#!/usr/bin/env python3
"""The ragdoll lab's flags, from a run's per-tick logs and thresholds.json (README.md).

  python3 experiments/physics_lab/analyse.py RUN_ROOT [SCENARIO...]

Writes <scenario>/flags.json and RUN_ROOT/baseline.{json,md}. Run again after moving a threshold:
no Godot needed.
"""
import csv, json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
TH = json.load(open(os.path.join(HERE, "thresholds.json")))
STEP_M, STEP_DEG = 0.25, 45.0


def measures(row):
    seg = row["segment"]
    key = seg[:-2] if seg.endswith(("_r", "_l")) else seg
    m = {"penetration": float(row["penetration"]), "self_overlap": float(row["self_overlap"]),
         "joint_gap": float(row["joint_gap"]), "speed": math.sqrt(sum(float(row[k]) ** 2 for k in ("vx", "vy", "vz")))}
    sw, tw, ls, lt, bend = (float(row[k]) for k in ("swing", "twist", "swing_limit", "twist_limit", "bend"))
    if key in ("shin", "forearm"):
        m["wrong_bend"] = bend if key == "shin" else -bend
    elif ls > 0:
        m["swing_excess"] = sw - ls
        m["twist_excess"] = abs(tw) - lt
    m["step"] = 2.0 if (float(row["step_m"]) > STEP_M or float(row["step_deg"]) > STEP_DEG) else 0.0
    return m


def analyse(run):
    sm = json.load(open(os.path.join(run, "summary.json")))
    limp = int(round(sm["limp_t"] * 60))
    settle = None if sm["settle_s"] is None else limp + int(round(sm["settle_s"] * 60))
    runs, peaks, flags = {}, {}, {}

    def hit(rule, t, what, seg=""):
        f = flags.setdefault(rule, {"count": 0, "first_t": round(t, 3), "first": what, "parts": []})
        f["count"] += 1
        if seg and seg not in f["parts"]:
            f["parts"].append(seg)

    for row in csv.DictReader(open(os.path.join(run, "segments.csv"))):
        tick = int(row["tick"])
        if tick <= limp + 1:
            continue
        seg = row["segment"]
        t = (tick - limp) / 60.0
        for name, val in measures(row).items():
            pk = peaks.setdefault(name, [-1e9, "", 0])
            if val > pk[0]:
                peaks[name] = [round(val, 4), seg, round(t, 3)]
            for rule, r in TH.items():
                if not isinstance(r, dict) or r.get("measure") != name:
                    continue
                k = (rule, seg)
                runs[k] = runs.get(k, 0) + 1 if val > r["over"] else 0
                if runs[k] == r["ticks"]:
                    hit(rule, t, "%s %s %.3f (over %s for %d ticks)" % (seg, name, val, r["over"], r["ticks"]), seg)
        if settle is not None and tick > settle + 30:
            sp = measures(row)["speed"]
            if sp > TH["lingering_motion"]["over"]:
                hit("lingering_motion", t, "%s at %.2f m/s, %.1f s after settling" % (seg, sp, (tick - settle) / 60), seg)
    start_y, com_low, up_run = None, 1e9, 0
    for row in csv.DictReader(open(os.path.join(run, "ticks.csv"))):
        tick = int(row["tick"])
        y, vy = float(row["com_y"]), float(row["com_vy"])
        if tick == limp:
            start_y = y
        if tick <= limp + 1 or start_y is None:
            continue
        com_low = min(com_low, y)
        if start_y - com_low > 0.3:
            up_run = up_run + 1 if vy > TH["bounce"]["over"] else 0
            if up_run == TH["bounce"]["ticks"]:
                hit("bounce", (tick - limp) / 60, "centre of mass rising %.2f m/s at %.2f m" % (vy, y))
    if sm["settle_s"] is None:
        hit("never_settled", 0, "still moving at the end")
    if not sm["all_asleep_at_end"]:
        hit("awake_at_end", 0, "%d of %d parts asleep at the end" % (sm["asleep_at_end"], sm["bodies"]))
    out = {"scenario": sm["scenario"], "flags": flags, "peaks": peaks}
    json.dump(out, open(os.path.join(run, "flags.json"), "w"), indent=1)
    sm["flags"] = flags
    sm["peaks"] = peaks
    return sm


def gather(root, names=None):
    if not names:
        names = sorted(d for d in os.listdir(root) if os.path.exists(os.path.join(root, d, "segments.csv")))
    order = [s["name"] for s in json.load(open(os.path.join(HERE, "scenarios.json")))["scenarios"]]
    names = sorted(names, key=lambda n: order.index(n) if n in order else 999)
    rows = [analyse(os.path.join(root, n)) for n in names]
    json.dump(rows, open(os.path.join(root, "baseline.json"), "w"), indent=1)
    rules = [k for k, v in TH.items() if isinstance(v, dict)]
    used = [k for k in rules if any(k in r["flags"] for r in rows)]
    with open(os.path.join(root, "baseline.md"), "w") as f:
        f.write("| scenario | settle s | peak speed | pen. peak | self-overlap peak | joint gap peak | chest random kick N*s | momentum before -> after N*s | " + " | ".join(used) + " |\n")
        f.write("|" + "---|" * (8 + len(used)) + "\n")
        for r in rows:
            ev = next((e for e in r["events"] if e["kind"] == "go_limp"), {})
            rk = ev.get("chest_random_impulse_Ns", [0, 0, 0])
            mb, ma = ev.get("momentum_before_Ns", [0, 0, 0]), ev.get("momentum_after_Ns", [0, 0, 0])
            norm = lambda v: math.sqrt(sum(x * x for x in v))
            f.write("| %s | %s | %.1f | %.3f | %.3f | %.3f | %.1f | %.0f -> %.0f | %s |\n" % (
                r["scenario"], "%.2f" % r["settle_s"] if r["settle_s"] is not None else "never",
                r["peak"]["speed"], r["peak"]["penetration"], r["peak"]["self_overlap"], r["peak"]["joint_gap"],
                math.hypot(rk[0], rk[2]), norm(mb), norm(ma),
                " | ".join(str(r["flags"].get(k, {}).get("count", "")) for k in used)))
    return rows


if __name__ == "__main__":
    root = sys.argv[1]
    rows = gather(root, sys.argv[2:])
    for r in rows:
        print("%-24s %s" % (r["scenario"], ", ".join("%s(%d)" % (k, v["count"]) for k, v in r["flags"].items()) or "-"))
