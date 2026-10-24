#!/usr/bin/env python3
"""The card cheat, run and measured (docs/briefs/showcase-moments.md): the moment played N times
in the game's saloon through the dev bridge, headless, each run's result kept, and the tally:
how often Earl ends on his back, how long the kick takes to put him down, what the boot did.

    python3 experiments/card_cheat/run.py --runs=20 --out=build/card_cheat/runs [--animated=0] [--per-game=5]
    python3 experiments/card_cheat/run.py --tally=DIR1[,DIR2] [--animated=0]     # the tally alone, over runs made in parts

A game is started fresh for every run (--per-game=1; more a game and the moment puts a whole chair
back, but the game drifts: by the fourth run of one the chair wouldn't seat him); each run has its
own seed (the men's randomness, a hand's width on Cody's entry), since the simulation is otherwise
the same every time. Writes <out>/run_NN.json and <out>/tally.md.
"""
import json
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BRIDGE = os.path.join(ROOT, "tools", "bridge.py")


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def bridge(*cmds):
    r = subprocess.run([sys.executable, BRIDGE, *cmds], cwd=ROOT, capture_output=True, text=True, timeout=600)
    out = []
    for line in r.stdout.splitlines():
        line = line.strip()
        if line.startswith("{"):
            try:
                out.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    return out


def main():
    if opt("tally"):
        # Only the tally, over the run_*.json of these folders (runs made in parts).
        import glob
        results = []
        dirs = opt("tally").split(",")
        for d in dirs:
            for f in sorted(glob.glob(os.path.join(d, "run_*.json"))):
                with open(f) as fh:
                    results.append(json.load(fh))
        for i, r in enumerate(results):
            r["run"] = i + 1
        tally(results, os.path.join(dirs[0], "tally.md"), opt("animated", "1"))
        return
    runs = int(opt("runs", "20"))
    per_game = int(opt("per-game", "1"))
    animated = opt("animated", "1")
    out_dir = opt("out", os.path.join(ROOT, "build", "card_cheat", "runs"))
    hour = opt("hour", "17.5")
    os.makedirs(out_dir, exist_ok=True)
    results = []
    i = 0
    while i < runs:
        subprocess.run([sys.executable, BRIDGE, "start", "--headless", "--fps=60"], cwd=ROOT, check=True, timeout=600)
        try:
            for _ in range(per_game):
                if i >= runs:
                    break
                replies = bridge("time %s" % hour, "moment card_cheat animated=%s hour=%s seed=%d" % (animated, hour, i + 1), "moment_result wait 40")
                res = replies[-1] if replies else {"ok": False, "error": "no reply"}
                res["run"] = i + 1
                with open(os.path.join(out_dir, "run_%02d.json" % (i + 1)), "w") as f:
                    json.dump(res, f, indent=1, sort_keys=True)
                print("run %d: %s on_back=%s front_up=%s behind=%s strikes=%s" % (
                    i + 1, res.get("state"), res.get("on_back"), res.get("chest_front_up"), res.get("behind_m"), res.get("strikes")))
                results.append(res)
                i += 1
        finally:
            subprocess.run([sys.executable, BRIDGE, "stop"], cwd=ROOT, timeout=300)
    tally(results, os.path.join(out_dir, "tally.md"), animated)


def tally(results, path, animated):
    n = len(results)
    done = [r for r in results if r.get("done")]
    on_back = [r for r in results if r.get("on_back")]
    down = [r for r in results if r.get("cheater_down")]
    loose = [r for r in results if r.get("chair_loose")]
    drew = [r for r in results if r.get("victim_drew")]
    times = [float(r["fell_t"]) - float(r["kick_t"]) for r in results if float(r.get("fell_t", -1)) >= 0 and float(r.get("kick_t", -1)) >= 0]
    fronts = [float(r.get("chest_front_up", 0)) for r in results if "chest_front_up" in r]
    states = {}
    for r in results:
        states[r.get("state")] = states.get(r.get("state"), 0) + 1
    lines = ["# The card cheat, %d runs (%s)" % (n, "on the clips" if animated != "0" else "pose to pose"), "",
             "| what | runs |", "|---|---|",
             "| finished (timed out, no one dead) | %d / %d |" % (len(done), n),
             "| the chair went from under him | %d / %d |" % (len(loose), n),
             "| Earl went down | %d / %d |" % (len(down), n),
             "| **Earl ends on his back** (chest front up > 0.5) | **%d / %d** |" % (len(on_back), n),
             "| Cody drew | %d / %d |" % (len(drew), n), "",
             "Kick to fall: %s s (mean of %d). Chest front up: mean %.2f, min %.2f, max %.2f." % (
                 ("%.2f" % (sum(times) / len(times))) if times else "-", len(times),
                 (sum(fronts) / len(fronts)) if fronts else 0, min(fronts) if fronts else 0, max(fronts) if fronts else 0),
             "End states: %s" % json.dumps(states), "", "| run | state | boot | front up | behind m | kick->fall s |", "|---|---|---|---|---|---|"]
    for r in results:
        kf = (float(r["fell_t"]) - float(r["kick_t"])) if float(r.get("fell_t", -1)) >= 0 and float(r.get("kick_t", -1)) >= 0 else None
        lines.append("| %d | %s | %s | %s | %s | %s |" % (r.get("run"), r.get("state"), ", ".join(r.get("strikes", [])) or "-",
                                                     r.get("chest_front_up"), r.get("behind_m"), ("%.2f" % kf) if kf is not None else "-"))
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")
    print("\n".join(lines[:12]))


if __name__ == "__main__":
    main()
