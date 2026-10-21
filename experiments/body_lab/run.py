#!/usr/bin/env python3
"""Run the body lab (README.md): every scenario on every man, one Godot process each (as the
ragdoll lab does: experiments/physics_lab/README.md, "Determinism"), then gather the table.

  python3 experiments/body_lab/run.py --out=build/body_lab/base [--scenario=all|group:revolver|NAME,NAME]
      [--model=bold_cowboy_s0,old_rancher_s1,young_drifter_s1,hothead_lyle_s1] [--seed=N] [--jobs=N]
  python3 experiments/body_lab/run.py --render --out=build/body_lab/render     (the wound sheets' scenarios, pictures)
  python3 experiments/body_lab/run.py --vessels --out=build/body_lab/base      (every vessel cut alone)
  python3 experiments/body_lab/run.py --perf --model=mixed --out=build/body_lab/perf   (ten wounded men)

Writes <out>/<model>/<scenario>/{summary.json,manifest.json[,frames/]} and, through report.py,
<out>/baseline.json and <out>/baseline.md.
"""
import json, os, subprocess, sys, concurrent.futures as cf

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
GODOT = os.environ.get("GODOT", "godot")
sys.path.insert(0, os.path.join(ROOT, "experiments", "physics_lab"))
from run import arg  # the ragdoll lab's argument reader  # noqa: E402

# The scenarios drawn for the wound sheets: every spot from 5 m, the dynamite, each man's check.
SHEET = ["revolver_05m_%s", "shotgun_05m_%s"]


def scenarios():
    d = json.load(open(os.path.join(HERE, "scenarios.json")))
    out = []
    for w in d["weapons"]:
        for r in d["ranges"]:
            for spot in d["spots"]:
                out.append(("%s_%02dm_%s" % (w, r, spot), w))
    for r in d["dynamite"]["distances"]:
        out.append(("dynamite_%dm" % r, "dynamite"))
    for spot in d["spots"]:
        out.append(("grab_%s" % spot, "grab"))
    for spot in d["spots"]:
        out.append(("soak_%s" % spot, "soak"))
    out.append(("check", "check"))
    out.append(("same_tick", "probe"))
    return out, d


def pick(all_, d):
    want = arg("scenario", "all")
    if arg("render") and want == "all":
        names = [s % spot for s in SHEET for spot in d["spots"]]
        names += ["dynamite_%dm" % r for r in d["dynamite"]["distances"]] + ["check"]
        return names
    if want == "all":
        return [n for n, _ in all_]
    out = []
    for w in want.split(","):
        hit = [n for n, g in all_ if (w.startswith("group:") and g == w[6:]) or n == w]
        if not hit:
            sys.exit("run.py: no scenario %s" % w)
        out += [n for n in hit if n not in out]
    return out


def godot(extra, render):
    cmd = [GODOT, "--path", ROOT, "--fixed-fps", "60"]
    if render:
        cmd = ["xvfb-run", "-a"] + cmd + ["--rendering-driver", "vulkan"]
    else:
        cmd += ["--headless"]
    return cmd + ["-s", "res://experiments/body_lab/lab.gd", "--"] + extra


def run_one(name, model, out, extra, render):
    cmd = godot(["--scenario=" + name, "--model=" + model, "--out=" + out] + extra, render)
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=3600)
    line = [l for l in p.stdout.splitlines() if l.startswith(name)]
    ok = p.returncode == 0 and os.path.exists(os.path.join(out, model, name, "summary.json"))
    return name, model, ok, "\n".join(line), (p.stdout + p.stderr)[-1500:] if not ok else ""


def main():
    all_, d = scenarios()
    out = arg("out", "build/body_lab/run")
    out = out if os.path.isabs(out) else os.path.join(ROOT, out)
    os.makedirs(out, exist_ok=True)
    render = arg("render") is not None
    extra = [a for a in sys.argv[1:] if a.split("=")[0] in ("--render", "--seed", "--size", "--brains")]
    if arg("scenario") == "list":
        for n, g in all_:
            print("%-26s %s" % (n, g))
        return 0
    if arg("vessels") or arg("perf"):
        flag = "--vessels" if arg("vessels") else "--perf"
        p = subprocess.run(godot([flag, "--out=" + out, "--model=" + arg("model", "mixed")] + extra, False),
                           capture_output=True, text=True)
        print("\n".join(l for l in p.stdout.splitlines() if l.startswith("lab:") or l.startswith("perf")))
        return p.returncode
    models = arg("model", ",".join(d["models"])).split(",")
    names = pick(all_, d)
    jobs = int(arg("jobs", "2" if render else str(max(1, (os.cpu_count() or 2) // 2))))
    todo = [(n, m) for m in models for n in names]
    bad = 0
    with cf.ThreadPoolExecutor(jobs) as ex:
        for name, model, ok, line, err in ex.map(lambda nm: run_one(nm[0], nm[1], out, extra, render), todo):
            print(line if ok else "%s %s FAILED\n%s" % (name, model, err))
            bad += 0 if ok else 1
    sys.path.insert(0, HERE)
    import report
    report.gather(out)
    if render:
        report.sheets(out)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
