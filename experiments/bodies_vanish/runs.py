#!/usr/bin/env python3
"""Issue #562's runs: each a headless game with bv_watch on, one fight (or mission run) and then a
spell of game time after it, every man leaving the tree or not drawn logged (bridge.gd).

  python3 experiments/bodies_vanish/runs.py --out=build/bodies_vanish/r1 [--jobs=3] [--only=gf,farm,street]
  python3 experiments/bodies_vanish/runs.py --sum build/bodies_vanish/r1   # events grouped by cause

A run's events are DIR/<run>.jsonl; its game log DIR/<run>.log.
"""
import collections
import concurrent.futures
import json
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
AFTER_S = 150  # game time watched after the fight: the standing men's leave walk, the dead lying


def runs():
    out = []
    for scen in ["street", "saloon", "spec_hall", "spec_front"]:
        for seed in range(1, 5):
            aim = 1 if seed <= 2 else 4  # half the runs a poor shot, so men get away wounded
            out.append((f"gf_{scen}_{seed}", [
                "bv_flee 1", "bv_watch out=EVENTS",
                f"gf_fight {scen} seed={seed} style=cover variant=D aim={aim} max=90",
                f"wait {AFTER_S}", "bv_report", "quit"]))
    for how in ["front", "breach", "back"]:
        for seed in range(1, 3):
            out.append((f"farm_{how}_{seed}", [
                "bv_watch out=EVENTS", f"farm_run {how} seed={seed} max=120",
                f"wait {AFTER_S}", "bv_report", "quit"]))
    for r, men in [(2.0, 4), (3.0, 4), (4.0, 6)]:
        out.append((f"blast_r{int(r)}", [
            "bv_watch out=EVENTS", f"bf_blast in=street men={men} men_r={r} lift=0.8 seconds=12",
            "wait 20", "bv_report", "quit"]))
    for seed in range(1, 3):
        out.append((f"street_gang_{seed}", [
            "bv_watch out=EVENTS", "time 14", "gang", "wait 25", "goto street_east",
            "bv_flee 1", "fight", "wait 3", "look brody", "shoot 3", "wait 2", "look lyle", "shoot 3",
            f"wait {AFTER_S}", "bv_report", "quit"]))
    return out


def run_one(name, lines, d, port):
    events = os.path.join(d, name + ".jsonl")
    if os.path.exists(os.path.join(d, name + ".done")):
        return name, "kept"
    script = os.path.join(d, name + ".txt")
    with open(script, "w") as f:
        f.write("\n".join(l.replace("EVENTS", events) for l in lines) + "\n")
    cmd = [os.environ.get("GODOT", "godot"), "--headless", "--fixed-fps", "60", "--path", ROOT, "--",
           "--dev-bridge", f"--bridge-port={port}", f"--bridge-script={script}"]
    with open(os.path.join(d, name + ".log"), "w") as log:
        try:
            r = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, timeout=1800)
            code = r.returncode
        except subprocess.TimeoutExpired:
            code = "timeout"
    open(os.path.join(d, name + ".done"), "w").write(str(code))
    return name, code


def summarise(d):
    by = collections.Counter()
    examples = {}
    for f in sorted(os.listdir(d)):
        if not f.endswith(".jsonl"):
            continue
        for line in open(os.path.join(d, f)):
            e = json.loads(line)
            k = f'{e["kind"]}: {e["cause"]}'
            by[k] += 1
            examples.setdefault(k, []).append({"run": f[:-6], "name": e.get("name"), "alive": e.get("alive"), "limp": e.get("limp"),
                                               "in_view": e.get("in_view"), "dist_m": e.get("dist_m"),
                                               "from_west_edge_m": e.get("from_west_edge_m"), "mood": e.get("mood"),
                                               "before": {k2: e.get("before", {}).get(k2) for k2 in ("mood", "step", "route_n")} if e.get("before") else None})
    for k, n in by.most_common():
        print(f"{n:4d}  {k}")
        for ex in examples[k][:4]:
            print("        ", json.dumps(ex))


def main():
    args = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in sys.argv[1:] if a.startswith("--"))
    if "sum" in args:
        summarise(sys.argv[-1])
        return
    d = os.path.abspath(args.get("out", "build/bodies_vanish/r1"))
    os.makedirs(d, exist_ok=True)
    only = args.get("only", "gf,farm,street,blast").split(",")
    todo = [r for r in runs() if r[0].split("_")[0] in only]
    jobs = int(args.get("jobs", 3))
    with concurrent.futures.ThreadPoolExecutor(jobs) as pool:
        futs = [pool.submit(run_one, n, l, d, 8760 + i) for i, (n, l) in enumerate(todo)]
        for f in concurrent.futures.as_completed(futs):
            print(*f.result(), flush=True)


if __name__ == "__main__":
    main()
