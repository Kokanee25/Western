#!/usr/bin/env python3
"""Each run's frame and people scaled by how fast the machine ran it: the systems step 4 doesn't
touch (`player`, `structures`, `fire`, `horses`) against their mean over the before runs. This
VM drifted ~10% between runs on 2026-10-26 (two runs of one build 1.5 ms apart); the controls
drift with it.

    python3 normalise.py RUNS_DIR NAME [NAME ...]   (the before runs' names start with "before")
"""
import glob
import json
import os
import sys

CONTROLS = ["player", "structures", "fire", "horses"]


def load(root):
    fs = [json.load(open(p))["perf"] for p in sorted(glob.glob(os.path.join(root, "fights", "*.json")))]
    mean = lambda get: sum(get(f) for f in fs) / len(fs)
    sys_ms = lambda k: mean(lambda f: f["per_system_ms"].get(k, 0.0))
    return {"frame": mean(lambda f: f["frame_ms"]), "people": mean(lambda f: f["people_ms"]),
            "body": sys_ms("people_body") + sys_ms("people_prep"), "ctrl": sum(sys_ms(k) for k in CONTROLS)}


def main(argv):
    root, names = argv[0], argv[1:]
    d = {n: load(os.path.join(root, n)) for n in names}
    befores = [n for n in names if n.startswith("before")]
    base = sum(d[n]["ctrl"] for n in befores) / len(befores)
    print("| run | frame | people | body + prep | controls | frame, scaled | people, scaled | body + prep, scaled |")
    print("|---|---|---|---|---|---|---|---|")
    for n in names:
        x = d[n]
        k = base / x["ctrl"]
        print("| %s | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f |" % (
            n, x["frame"], x["people"], x["body"], x["ctrl"], x["frame"] * k, x["people"] * k, x["body"] * k))


if __name__ == "__main__":
    main(sys.argv[1:])
