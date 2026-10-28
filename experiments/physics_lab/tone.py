#!/usr/bin/env python3
"""How a man goes down, for the tone fade (issue #442, 2026-10-28): per scenario, from its logs.

  python3 experiments/physics_lab/tone.py ROOT [ROOT...] [--only=A,F_stairs] [--each]

- `ground` (s from going limp): his centre of mass has come 90% of the way down to where it ends.
- `first`: the first part, not his feet, to touch anything he wasn't already touching as he went
  (a knee, a hand, his seat, his chest...), and when.
- `planked`: when his chest, belly, neck or head first touched, both knees were bent under 25
  degrees and neither knee nor his seat had touched: he went down straight as a board.
- `head_v` / `chest_v`: how fast his head and his chest were moving as each first touched (m/s):
  a sack dropped lands hard; a man who crumples lands softer.
- `ms`: the lab's frame time over the first 3 s after he went limp (headless, measuring included).
- `speed` / `travel` (issue #446): his centre of mass's level speed as he went limp, and how far
  (level, m) it went from there to the end; `broke`: members broken after he went limp (the
  fixture's: what he went into); `ends`: his centre of mass at the end in his starting frame
  (z ahead of him is negative; `final_com_local`).

Per root a line of totals; --each a line per scenario. Groups V, W and R (not falls) are left out.
"""
import csv, glob, json, os, signal, sys
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

TRUNK = {"chest", "abdomen", "neck", "head"}
PLANK_KNEE = 25.0


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


def one(d):
    sm = json.load(open(os.path.join(d, "summary.json")))
    limp_t = sm.get("limp_t")
    if limp_t is None:
        return None
    coms = []
    flat = []
    with open(os.path.join(d, "ticks.csv")) as f:
        for r in csv.DictReader(f):
            coms.append((float(r["t"]), float(r["com_y"])))
            flat.append((float(r["t"]), float(r["com_x"]), float(r["com_z"]), float(r["com_vx"]), float(r["com_vz"]), r["phase"]))
    after = [c for c in coms if c[0] >= limp_t - 1e-6]
    if not after:
        return None
    y0, y1 = after[0][1], after[-1][1]
    ground = None
    if y0 - y1 > 0.05:
        for t, y in after:
            if y <= y1 + 0.1 * (y0 - y1):
                ground = t - limp_t
                break
    touching = None  # parts touching something as he went
    first = None
    knees = {}
    trunk_at = None
    caught = None
    hit_v = {}
    with open(os.path.join(d, "segments.csv")) as f:
        t_first = None  # the tick he went limp: what he touches then doesn't count
        for r in csv.DictReader(f):
            t = float(r["t"])
            if t < limp_t - 1e-6:
                continue
            seg = r["segment"]
            c = int(r.get("world_contacts", r["contacts"]))
            if t_first is None:
                t_first = t
                touching = set()
            if t == t_first:
                if c > 0:
                    touching.add(seg)
                if seg.startswith("shin"):
                    knees[seg] = abs(float(r["bend"]))
                continue
            if seg.startswith("shin"):
                knees[seg] = abs(float(r["bend"]))
            if c <= 0 or seg in touching or seg.startswith("foot"):
                continue
            base = seg.rsplit("_", 1)[0] if seg.endswith(("_l", "_r")) else seg
            if first is None:
                first = (seg, t - limp_t)
            if base in ("head", "chest") and base not in hit_v:
                hit_v[base] = (float(r["vx"]) ** 2 + float(r["vy"]) ** 2 + float(r["vz"]) ** 2) ** 0.5
            if base in TRUNK and trunk_at is None:
                trunk_at = t - limp_t
                knee = max(knees.values()) if knees else 0.0
                if caught is None and knee < PLANK_KNEE:
                    caught = "planked"
            elif base in ("shin", "thigh", "pelvis") and trunk_at is None and caught is None:
                caught = base
    level = [c for c in flat if c[0] >= limp_t - 1e-6]
    travel = ((level[-1][1] - level[0][1]) ** 2 + (level[-1][2] - level[0][2]) ** 2) ** 0.5
    # (The tick he goes limp on is a finite difference across the rig and the ragdoll: the next.)
    at_limp = next((c for c in level if c[5] == "limp"), level[0])
    speed = (at_limp[3] ** 2 + at_limp[4] ** 2) ** 0.5
    limp_tick = next((e["tick"] for e in sm.get("events", []) if e.get("kind") == "go_limp"), 0)
    broke = sorted({e["member"].split("/", 1)[-1] for e in sm.get("events", [])
                    if e.get("kind") == "member_broken" and e.get("tick", 0) >= limp_tick})
    return {"travel": travel, "speed": speed, "broke": broke, "ends": sm.get("final_com_local"),
            "ground": ground, "first": first, "planked": caught == "planked", "head_v": hit_v.get("head"), "chest_v": hit_v.get("chest"),
            "trunk_at": trunk_at, "ms": sm.get("frame_ms_collapse_3s"), "settle": sm.get("settle_s"),
            "lying": (sm.get("rest") or {}).get("lying"), "kneel_s": (sm.get("rest") or {}).get("kneel_s")}


def fmt(v, f="%.2f"):
    return "-" if v is None else (f % v if isinstance(v, (int, float)) else str(v))


def mean(xs):
    xs = [x for x in xs if x is not None]
    return sum(xs) / len(xs) if xs else None


def main():
    roots = [a for a in sys.argv[1:] if not a.startswith("--")]
    each = "--each" in sys.argv
    for root in roots:
        rows = []
        for name, d in scenarios(root):
            r = one(d)
            if r is None:
                continue
            r["name"] = name
            rows.append(r)
            if each:
                ms = r["ms"]
                ms = ms.get("mean") if isinstance(ms, dict) else ms
                print("  %-30s ground %s  first %-12s %s  trunk %s  %s head %s chest %s  lying %-9s settle %s  ms %s" % (
                    name, fmt(r["ground"]), (r["first"] or ("-",))[0], fmt((r["first"] or (0, None))[1]),
                    fmt(r["trunk_at"]), "PLANK " if r["planked"] else "      ", fmt(r["head_v"]), fmt(r["chest_v"]),
                    fmt(r["lying"], "%s"), fmt(r["settle"]), fmt(ms)))
                ends = r["ends"] or [0, 0, 0]
                print("  %-30s   speed %s  travel %s  ends (%.2f, %.2f, %.2f)  broke %d %s" % (
                    "", fmt(r["speed"]), fmt(r["travel"]), ends[0], ends[1], ends[2], len(r["broke"]), ", ".join(r["broke"][:6])))
        ms = [r["ms"].get("mean") if isinstance(r["ms"], dict) else r["ms"] for r in rows]
        print("%s: %d falls, travel %s m (mean), broke something %d, ground %s s (mean), planked %d, head lands %s m/s, chest %s, settle %s s, ms %s" % (
            root, len(rows), fmt(mean([r["travel"] for r in rows])), sum(1 for r in rows if r["broke"]), fmt(mean([r["ground"] for r in rows])), sum(r["planked"] for r in rows),
            fmt(mean([r["head_v"] for r in rows])), fmt(mean([r["chest_v"] for r in rows])), fmt(mean([r["settle"] for r in rows])), fmt(mean(ms), "%.3f")))


if __name__ == "__main__":
    main()
