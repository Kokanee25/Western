#!/usr/bin/env python3
"""#626: the farmhouse collapsing, a line a run (collapse_runs.sh's): the frames' median over the
collapse (FROM..TO s after the stick), Jolt's step, our scripts' ticks (window), the rest, the
biggest other timers, the rubble awake at 2/5/10 s, when fewer than 50 stay awake, what broke.

    python3 experiments/blast_freeze/collapse.py build/cc/s1/*.json [--from=0 --to=10] [--top=4]
"""
import json
import statistics
import sys

SKIP = ("q_", "n_", "rest_", "window", "step", "rest")


def line(path, a, b, top):
    d = json.load(open(path))
    s = d["setup"]
    fr = [f for f in d["frames"] if f["after"] >= 0]
    col = [f for f in fr if a * 60 <= f["after"] < b * 60]
    med = lambda k: statistics.median(float(f["prof"].get(k, 0.0)) for f in col)
    tot = {}
    for f in col:
        for k, v in f["prof"].items():
            if not k.startswith(SKIP):
                tot[k] = tot.get(k, 0.0) + float(v)
    keys = sorted(tot, key=lambda k: -tot[k])[:top]

    def at(sec):
        c = [f for f in fr if f["after"] >= sec * 60]
        return c[0]["awake"] if c else None
    settled = None
    for f in reversed(fr):
        if f["awake"] >= 50:
            break
        settled = round(f["after"] / 60, 1)
    ms = [f["ms"] for f in col]
    print(f"{path.split('/')[-1][:-5]:14} frame {statistics.median(ms):5.1f} (p90 {sorted(ms)[int(len(ms) * 0.9)]:5.1f}) "
          f"step {med('step'):5.1f} ({statistics.median(float(f['prof'].get('step', 0.0)) * 100 / max(f['awake'], 1) for f in col if f['awake'] >= 100):4.1f}/100 awake) window {med('window'):5.1f} rest {med('rest'):4.1f} | "
          + ", ".join(f"{k} {tot[k] / len(col):.1f}" for k in keys)
          + f" | awake +2 {at(2)} +5 {at(5)} +10 {at(10)} max {max(f['awake'] for f in fr)} settled {settled} "
          f"| broken {s['broken_now']} rubble {s.get('rubble_end')}")


if __name__ == "__main__":
    o = {x.split("=")[0][2:]: x.split("=")[1] for x in sys.argv[1:] if x.startswith("--")}
    for p in [x for x in sys.argv[1:] if not x.startswith("--")]:
        line(p, float(o.get("from", 0)), float(o.get("to", 10)), int(o.get("top", 4)))
