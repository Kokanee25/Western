#!/usr/bin/env python3
"""The train lab's derail runs (train step 5, #616), breakage-lab style: each in a fresh headless
game through the dev bridge (`train_derail`, derail.gd), then a table of who stopped in time and
who derailed, and where, and what the derail cost the frames against #492's gate.

    python3 experiments/train_lab/derail_runs.py --out=build/train_lab/derail
    python3 experiments/train_lab/derail_runs.py --out=... --only=straight_40_night,bend_20_day
    python3 experiments/train_lab/derail_runs.py --table=build/train_lab/derail   # the table again
"""
import json
import functools
print = functools.partial(print, flush=True)
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BRIDGE = [sys.executable, os.path.join(ROOT, "tools", "bridge.py")]

# name: the spec (derail.gd's keys). Straight: the break 380 m along, at the end of the first
# straight. The bend: 560 m, in the middle of the left-hand 120 m bend (the engineer sits on the
# right: the boiler hides the inside of the curve from him).
RUNS = {}
for kmh, word in [(5, "walk"), (20, "20"), (40, "40")]:
    for hour, when in [(12, "day"), (23, "night")]:
        RUNS[f"straight_{word}_{when}"] = {"kmh": kmh, "at": 380, "how": "rail", "hour": hour, "run_up": 60 if kmh < 10 else 300}
for kmh in [20, 40]:
    for hour, when in [(12, "day"), (23, "night")]:
        RUNS[f"bend_{kmh}_{when}"] = {"kmh": kmh, "at": 560, "how": "rail", "hour": hour, "run_up": 320}
RUNS["nobody_walk"] = {"kmh": 5, "at": 380, "how": "rail", "hour": 12, "driver": "none", "run_up": 20}
RUNS["nobody_20"] = {"kmh": 20, "at": 380, "how": "rail", "hour": 12, "driver": "none"}
RUNS["nobody_40"] = {"kmh": 40, "at": 380, "how": "rail", "hour": 12, "driver": "none"}
RUNS["stick_40_night"] = {"kmh": 40, "at": 380, "how": "stick", "hour": 23}
RUNS["bent_40_night"] = {"kmh": 40, "at": 380, "how": "bent", "hour": 23}
RUNS["crate_20_nobody"] = {"kmh": 20, "at": 380, "how": "crate", "hour": 12, "driver": "none", "run_up": 80}
RUNS["wagon_20_nobody"] = {"kmh": 20, "at": 380, "how": "wagon", "hour": 12, "driver": "none", "run_up": 80}


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
    return default


def run_one(name, spec, out):
    path = os.path.join(out, f"{name}.json")
    args = " ".join(f"{k}={v}" for k, v in spec.items())
    subprocess.run(BRIDGE + ["start", "--headless", "--fps=60"], cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        r = subprocess.run(BRIDGE + ["train_lab", f"train_derail {args} out={path}"], cwd=ROOT, capture_output=True, text=True, timeout=900)
        print(name, r.stdout.strip().splitlines()[-1][:300] if r.stdout.strip() else r.stderr[-300:])
    finally:
        subprocess.run(BRIDGE + ["stop"], cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def table(out):
    rows = []
    for name in RUNS:
        p = os.path.join(out, f"{name}.json")
        if not os.path.exists(p):
            continue
        d = json.load(open(p))
        s = d["spec"]
        seen = d["seen"][0] if d["seen"] else None
        fr = d["frames"]
        where = ""
        if d["outcome"] == "derailed":
            w = d.get("wreck", {})
            where = f"left the rails at {d['derail']['s']:.0f} m at {d['derail']['kmh']:.0f} km/h; {w.get('furthest_past_m', 0):.0f} m on, {w.get('most_off_m', 0):.1f} m off, {w.get('tipped', 0)} tipped"
        elif d["outcome"] == "stopped":
            where = f"stopped {d['short_by']:.0f} m short"
        else:
            where = "ran on"
        ev = d.get("wreck", {}).get("events", [])
        torn = sum(1 for e in ev if e["what"] == "coupler torn")
        broke = sum(1 for e in ev if e["what"] == "car broken")
        rows.append([name, f"{s['kmh']}", "day" if float(s["hour"]) < 18 else "night", s["how"], s.get("driver", "engineer"),
                     f"{seen['distance']:.0f} m" if seen else "-", d["outcome"], where,
                     f"{d['thrown']}", f"{torn}/{broke}",
                     f"{fr['worst_ms']:.0f} ({fr['sean_worst_ms']:.0f})", f"{fr['over_50']}",
                     f"{fr['last_under_50fps_s']:.2f}" if fr["last_under_50fps_s"] >= 0 else "-", fr["gate"]])
    head = ["run", "km/h", "light", "break", "driver", "seen at", "outcome", "where", "thrown", "couplers torn / cars broken",
            "worst frame ms here (Sean's)", "frames > 50 ms", "slow till s", "#492 gate"]
    lines = ["| " + " | ".join(head) + " |", "|" + "---|" * len(head)]
    for r in rows:
        lines.append("| " + " | ".join(r) + " |")
    md = "\n".join(lines) + "\n"
    open(os.path.join(out, "table.md"), "w").write(md)
    print(md)


def main():
    out = os.path.abspath(opt("out", os.path.join(ROOT, "build", "train_lab", "derail")))
    if opt("table"):
        table(os.path.abspath(opt("table")))
        return
    os.makedirs(out, exist_ok=True)
    only = opt("only")
    names = only.split(",") if only else list(RUNS)
    for name in names:
        run_one(name, RUNS[name], out)
    table(out)


if __name__ == "__main__":
    main()
