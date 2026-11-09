#!/usr/bin/env python3
"""The trestle lab's collapse runs (#623): each in a fresh headless game through the dev bridge
(`trestle_lab`, then `trestle_collapse`, collapse.gd), then the frame table of every collapse
against #492's gate (one hitch under ~100 ms at Sean's, back over 50 fps within half a second;
here's frames x0.65 for his clock, as step 5's derail runs), with what fell and the piece counts.

    python3 experiments/trestle_lab/collapse_runs.py --out=build/trestle/runs
    python3 experiments/trestle_lab/collapse_runs.py --out=... --only=bent_blown,two_under_40
    python3 experiments/trestle_lab/collapse_runs.py --table=build/trestle/runs   # the table again
    python3 experiments/trestle_lab/collapse_runs.py --world=valley --out=...    # on the valley's canyon (G3)

--world=valley: each run in the valley world (the main line's great trestle, its bents footed on the
baked canyon; ValleyRailway), not the lab's gorge line.
"""
import functools
import json
import os
import subprocess
import sys

print = functools.partial(print, flush=True)
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BRIDGE = [sys.executable, os.path.join(ROOT, "tools", "bridge.py")]

# name: (what it is, collapse.gd's spec). Charges are bundles of four sticks a post (0.8 kg, touching
# it: since heavy timber was made tough, #647, three sticks don't cut a 12 x 12 in post; these were
# two sticks 5 cm off before), at the foot of the tallest bent's bottom story unless said.
RUNS = {
    "bent_blown": ("one bent blown, no train", {"how": "stick", "posts": "all", "sticks": 4}),
    "bent_blown_one_tick": ("the same, all eight on one tick", {"how": "stick", "posts": "all", "sticks": 4, "stagger": 0}),
    "rim_bent_blown": ("a short bent near the rim (the 8th) blown, no train", {"bent": 8, "how": "stick", "posts": "all", "sticks": 4}),
    "two_bents_blown": ("two bents side by side blown, no train", {"how": "stick", "posts": "all", "sticks": 4, "bents": 2}),
    "light_then_engine_30": ("a light charge (the two inner posts), then the train at 30 km/h", {"how": "stick", "posts": "inner", "sticks": 4, "train": "cross", "when": "before", "kmh": 30}),
    "light_then_engine_15": ("the same at 15 km/h", {"how": "stick", "posts": "inner", "sticks": 4, "train": "cross", "when": "before", "kmh": 15}),
    "one_under_40": ("one bent blown as the engine comes on (40 m short) at 40 km/h", {"how": "stick", "posts": "all", "sticks": 4, "train": "cross", "when": "under", "lead": 40, "kmh": 40}),
    "two_under_40": ("two bents blown as the engine comes on (40 m short) at 40 km/h", {"how": "stick", "posts": "all", "sticks": 4, "bents": 2, "train": "cross", "when": "under", "lead": 40, "kmh": 40}),
    "two_under_40_coach": ("the same, twelve men seated in the coach", {"how": "stick", "posts": "all", "sticks": 4, "bents": 2, "train": "cross", "when": "under", "lead": 40, "kmh": 40, "riders": 12}),
    "three_under_40": ("three bents blown as the engine comes on (60 m short) at 40 km/h", {"how": "stick", "posts": "all", "sticks": 4, "bents": 3, "train": "cross", "when": "under", "lead": 60, "kmh": 40}),
    "three_under_40_coach": ("the same, twelve men seated in the coach", {"how": "stick", "posts": "all", "sticks": 4, "bents": 3, "train": "cross", "when": "under", "lead": 60, "kmh": 40, "riders": 12}),
    # Bundles (#647): two bundles of four sticks on the tallest bent's two inner posts (the light
    # charge), fired by the plunger (a tick apart, the game's fire_spread_ticks), as the engine comes
    # on; with no train; and the same on one tick for comparison.
    "bundles_two": ("two bundles of four on the inner posts, the plunger, no train", {"how": "stick", "posts": "inner", "sticks": 4, "stagger": 1}),
    "bundles_two_one_tick": ("the same, both on one tick", {"how": "stick", "posts": "inner", "sticks": 4, "stagger": 0}),
    "bundles_two_under_40": ("two bundles of four on the inner posts, the plunger as the engine comes on (40 m short) at 40 km/h", {"how": "stick", "posts": "inner", "sticks": 4, "stagger": 1, "train": "cross", "when": "under", "lead": 40, "kmh": 40}),
}


# The train going over is chaotic (Jolt's threads, where the charges fall against the frames): these
# run three times each (name_r2, name_r3 beside name).
REPEAT = ["one_under_40", "two_under_40", "three_under_40", "three_under_40_coach", "bundles_two_under_40"]
for _n in REPEAT:
    for _k in (2, 3):
        RUNS[f"{_n}_r{_k}"] = (RUNS[_n][0] + f" (run {_k})", RUNS[_n][1])


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
    return default


def run_one(name, spec, out):
    path = os.path.abspath(os.path.join(out, f"{name}.json"))
    args = " ".join(f"{k}={v}" for k, v in spec.items())
    start = BRIDGE + ["start", "--headless", "--fps=60"]
    if opt("world"):
        start.append(f"--game-args=--world={opt('world')}")
    subprocess.run(start, cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        r = subprocess.run(BRIDGE + ["trestle_lab", f"trestle_collapse {args} secs=12 out={path}"], cwd=ROOT,
                           capture_output=True, text=True, timeout=1200)
        last = r.stdout.strip().splitlines()[-1][:200] if r.stdout.strip() else r.stderr[-200:]
        print(name, last)
    finally:
        subprocess.run(BRIDGE + ["stop"], cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def table(out):
    rows = ["| Run | What | Broke | Bents down | Rails gone | Train | Cars in the gorge | Rubble pieces (awake at the end) | Worst frame here / at Sean's (ms) | Slow spell (s) | Gate | The fall's worst at Sean's (ms) |",
            "|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for name, (what, _spec) in RUNS.items():
        p = os.path.join(out, f"{name}.json")
        if not os.path.exists(p):
            continue
        d = json.load(open(p))
        a = d["after"]
        fr = d["frames"]
        w = d.get("wreck", {})
        empty = d.get("empty")
        train = d["outcome"]
        if empty is not None:
            train += f" (empty first: {empty['broken']} broke, {empty['rails_gone']} rails gone)"
        fall = d.get("frames_fall", {})
        rows.append(f"| {name} | {what} | {a['broken']} | {a['bents_down']} | {a['rails_gone']} | {train} | "
                    f"{w.get('fell_into_gorge', '-')} of {w.get('bodies', '-')} | {d['rubble']['pieces']} ({d['rubble']['awake_at_end']}) | "
                    f"{fr['worst_ms']} / {fr['sean_worst_ms']} | {fr['slow_spell_s']} | {fr['gate']} | "
                    f"{fall.get('sean_worst_ms', '-')} {('(' + fall['gate'] + ')') if fall else ''} |")
    text = "\n".join(rows) + "\n"
    with open(os.path.join(out, "table.md"), "w") as f:
        f.write(text)
    print(text)


def main():
    out = opt("out", "build/trestle/runs")
    if opt("table"):
        table(opt("table"))
        return
    os.makedirs(out, exist_ok=True)
    only = opt("only")
    names = only.split(",") if only else list(RUNS)
    for n in names:
        run_one(n, RUNS[n][1], out)
    table(out)


if __name__ == "__main__":
    main()
