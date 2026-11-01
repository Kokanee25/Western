#!/usr/bin/env python3
"""The farmhouse's scripted runs (issue #520, step 4): each run its own headless game, the mission
started with the player at the edge of town and the scripted player (farm_bot.gd) going in one way.
The same seed gives the same run (--deterministic: the bridge script starts on the same frame).

    python3 experiments/farmhouse/run.py --ways=front,breach,back --seeds=1-8 --out=experiments/farmhouse/results/DATE_x [--jobs=3] [--max=240]
    python3 experiments/farmhouse/run.py --summary --out=DIR      # the table of an earlier run

Each run's record in OUT/runs/<way>_s<seed>.json (FarmhouseMission.result + the bot's stats), its
log in OUT/logs/; a run already recorded is skipped. Then OUT/summary.md and summary.json: how
often the rancher lives, how long it takes, how often you're down, by way in.
"""
import json
import os
import queue
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
        if a == f"--{name}":
            return True
    return default


def seeds(spec):
    out = []
    for part in str(spec).split(","):
        if "-" in part:
            a, b = part.split("-")
            out += list(range(int(a), int(b) + 1))
        elif part:
            out.append(int(part))
    return out


def run_one(way, seed, out, ports, max_s):
    name = f"{way}_s{seed}"
    rec = os.path.join(out, "runs", name + ".json")
    if os.path.exists(rec):
        return name, "kept"
    script = os.path.join(out, "scripts", name + ".txt")
    with open(script, "w") as fh:
        fh.write(f"farm_run {way} seed={seed} max={max_s} out={os.path.abspath(rec)}\nquit\n")
    port = ports.get()
    cmd = [os.environ.get("GODOT", "godot"), "--headless", "--fixed-fps", "60", "--path", ROOT, "--", "--dev-bridge",
           "--deterministic", f"--bridge-port={port}", f"--bridge-script={os.path.abspath(script)}"]
    try:
        with open(os.path.join(out, "logs", name + ".log"), "w") as log:
            subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, timeout=1800)
    except subprocess.TimeoutExpired:
        return name, "timed out"
    finally:
        ports.put(port)
    return name, "done" if os.path.exists(rec) else "FAILED"


def summary(out):
    rows = []
    d = os.path.join(out, "runs")
    for f in sorted(os.listdir(d)):
        if f.endswith(".json"):
            rows.append(json.load(open(os.path.join(d, f))))
    by = {}
    for r in rows:
        by.setdefault(r["way"], []).append(r)
    lines = ["| way in | runs | rancher lives | won | you down | the guard fired on him | alarm (s, median) | breach | ended (s, median) | men out (mean) |",
             "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
    out_json = {}
    for way, rs in sorted(by.items()):
        n = len(rs)
        lives = sum(1 for r in rs if r.get("hostage_alive"))
        won = sum(1 for r in rs if r.get("outcome") == "won")
        down = sum(1 for r in rs if r.get("player_down"))
        shot = sum(1 for r in rs if r.get("executed", -1) >= 0)
        alarms = sorted(r["alarm"] for r in rs if r.get("alarm", -1) >= 0)
        ends = sorted(r["t"] for r in rs)
        med = lambda xs: xs[len(xs) // 2] if xs else -1
        mean_out = sum(r.get("men_out", 0) for r in rs) / max(n, 1)
        breach = sum(1 for r in rs if r.get("breach", -1) >= 0)
        lines.append(f"| {way} | {n} | {lives} | {won} | {down} | {shot} | {med(alarms):.1f} | {breach} | {med(ends):.1f} | {mean_out:.1f} |")
        out_json[way] = {"runs": n, "lives": lives, "won": won, "down": down, "executed": shot, "alarm_median": med(alarms),
                         "end_median": med(ends), "men_out_mean": mean_out}
    with open(os.path.join(out, "summary.md"), "w") as f:
        f.write("\n".join(lines) + "\n")
    with open(os.path.join(out, "summary.json"), "w") as f:
        json.dump(out_json, f, indent=1)
    print("\n".join(lines))


def main():
    out = opt("out", "experiments/farmhouse/results/runs")
    if opt("summary"):
        summary(out)
        return
    for sub in ("runs", "scripts", "logs"):
        os.makedirs(os.path.join(out, sub), exist_ok=True)
    jobs = int(opt("jobs", 3))
    max_s = int(opt("max", 240))
    ports = queue.Queue()
    for i in range(jobs):
        ports.put(8840 + i)
    todo = [(w, s) for w in opt("ways", "front,breach,back").split(",") for s in seeds(opt("seeds", "1-4"))]
    t0 = time.time()
    with ThreadPoolExecutor(jobs) as ex:
        for name, how in ex.map(lambda ws: run_one(ws[0], ws[1], out, ports, max_s), todo):
            print(f"{name}: {how} ({time.time() - t0:.0f} s)", flush=True)
    summary(out)


if __name__ == "__main__":
    main()
