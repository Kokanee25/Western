#!/usr/bin/env python3
"""Run the ragdoll lab's scenarios, one Godot process each (README.md, "Determinism": in one
process a scenario after the first can fall differently), then gather their summaries.

  python3 experiments/physics_lab/run.py --out=build/physics_lab/base [--scenario=all|group:F|A_x,B_y]
      (--follow: the cameras keep him in shot across the ground, for footage of a runner)
      [--render [--views=front,side,three] [--size=480x360] [--every=2]] [--seed=N] [--model=ID] [--jobs=N]
  python3 experiments/physics_lab/run.py --perf --out=build/physics_lab/perf

Writes <out>/<scenario>/{ticks.csv,segments.csv,summary.json,manifest.json[,frames/]} and
<out>/baseline.json + <out>/baseline.md (one row a scenario, its flags).
"""
import json, os, subprocess, sys, concurrent.futures as cf

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GODOT = os.environ.get("GODOT", "godot")


def arg(name, default=None):
    for a in sys.argv[1:]:
        if a == "--" + name:
            return "1"
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def scenarios():
    data = json.load(open(os.path.join(ROOT, "experiments/physics_lab/scenarios.json")))
    return data["scenarios"]


def pick(all_):
    """all, or a comma list of names and groups: A_stand_blackout,group:F,G (a bare letter is a group)."""
    want = arg("scenario", "all")
    if want == "all":
        return all_
    out, unknown = [], []
    for w in want.split(","):
        g = w[6:] if w.startswith("group:") else (w if len(w) == 1 else None)
        hit = [s for s in all_ if (s["group"] == g if g else s["name"] == w)]
        if not hit:
            unknown.append(w)
        out += [s for s in hit if s not in out]
    if unknown:
        sys.exit("run.py: no scenario or group %s (names: --scenario=list)" % ", ".join(unknown))
    return out


def run_one(name, out, extra, render):
    cmd = [GODOT, "--path", ROOT, "--fixed-fps", "60"]
    if render:
        cmd = ["xvfb-run", "-a"] + cmd + ["--rendering-driver", "vulkan"]
    else:
        cmd += ["--headless"]
    cmd += ["-s", "res://experiments/physics_lab/lab.gd", "--", "--scenario=" + name, "--out=" + out] + extra
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=7200)
    line = [l for l in p.stdout.splitlines() if l.startswith(name) or (l.startswith("   ") and " at: " not in l)]
    return name, p.returncode, "\n".join(line), p.stderr[-2000:] if p.returncode else ""


def main():
    out = arg("out", "build/physics_lab/run")
    out = out if os.path.isabs(out) else os.path.join(ROOT, out)
    os.makedirs(out, exist_ok=True)
    render = arg("render") is not None
    extra = [a for a in sys.argv[1:] if a.split("=")[0] in
             ("--render", "--views", "--size", "--every", "--seed", "--model", "--seconds", "--follow", "--cam-dist")]
    if arg("scenario") == "list":
        for s in scenarios():
            print("%-24s %s  %s" % (s["name"], s["group"], s["fixture"]))
        return 0
    if arg("perf"):
        names = ["--perf"]
        jobs = 1  # nothing else running while it measures
    else:
        names = [s["name"] for s in pick(scenarios())]
        jobs = int(arg("jobs", "1" if render else str(max(1, (os.cpu_count() or 2) // 2))))
    results = []
    if names == ["--perf"]:
        cmd = [GODOT, "--path", ROOT, "--headless", "--fixed-fps", "60", "-s",
               "res://experiments/physics_lab/lab.gd", "--", "--perf", "--in-process", "--out=" + out]
        p = subprocess.run(cmd, capture_output=True, text=True)
        print("\n".join(l for l in p.stdout.splitlines() if l.startswith("perf") or l.startswith("   ")))
        return p.returncode
    with cf.ThreadPoolExecutor(jobs) as ex:
        for name, rc, line, err in ex.map(lambda n: run_one(n, out, extra, render), names):
            print(line if rc == 0 else "%s FAILED (%d)\n%s" % (name, rc, err))
            results.append((name, rc))
    gather(out, names)
    return 1 if any(rc for _, rc in results) else 0


def gather(out, names):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import analyse
    rows = analyse.gather(out, names)
    for r in rows:
        print("%-24s %s" % (r["scenario"], ", ".join("%s(%d)" % (k, v["count"]) for k, v in r["flags"].items()) or "-"))
    print("gathered %d into %s" % (len(rows), os.path.join(out, "baseline.md")))


if __name__ == "__main__":
    sys.exit(main())
