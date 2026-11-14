#!/usr/bin/env python3
"""The kick and shove lab (issue #479): the ragdoll lab's group O (experiments/physics_lab, cause
"push" through HumanBody.take_push, the player's numbers from ShoveTuning) run once a seed, each
seed jittering where he stands (2 cm, 3 deg) and the push (10% of its momentum, 4 cm up or down,
6 deg either way), then tallied (tally.py).

  python3 experiments/kick_shove/run.py --out=build/kick_shove/base [--seeds=20] [--scenario=group:O|O_x,O_y] [--jobs=3]
"""
import os, subprocess, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def arg(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def main():
    out = arg("out", "build/kick_shove/run")
    out = out if os.path.isabs(out) else os.path.join(ROOT, out)
    seeds = int(arg("seeds", "20"))
    scenario = arg("scenario", "group:O")
    jobs = arg("jobs", "3")
    for seed in range(1, seeds + 1):
        d = os.path.join(out, "seed_%02d" % seed)
        cmd = [sys.executable, os.path.join(ROOT, "experiments/physics_lab/run.py"), "--scenario=" + scenario,
               "--out=" + d, "--jitter=%d" % seed, "--jobs=" + jobs]
        p = subprocess.run(cmd, capture_output=True, text=True)
        print("seed %d: %s" % (seed, "ok" if p.returncode == 0 else "exit %d\n%s" % (p.returncode, p.stderr[-800:])), flush=True)
    subprocess.run([sys.executable, os.path.join(ROOT, "experiments/kick_shove/tally.py"), out])


if __name__ == "__main__":
    sys.exit(main())
