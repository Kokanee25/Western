#!/usr/bin/env python3
"""The mopping lab (README.md beside this): run its scenarios headless or rendered, make the film,
and measure the cost.

  python3 experiments/mopping/run.py --out=build/mopping/base                 # every scenario, numbers
  python3 experiments/mopping/run.py --out=DIR --render [--scenario=a,b] [--jobs=2]
  python3 experiments/mopping/run.py --film=DIR [--to=OUT.mp4]                # the rendered scenarios -> one film
  python3 experiments/mopping/run.py --perf=3 --out=DIR                       # cost: with and without the mopping, one core
  python3 experiments/mopping/run.py --table=DIR                              # DIR/table.md from the summaries
"""
import argparse, glob, json, os, statistics, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BENCH = "res://experiments/mopping/bench.gd"
# The film: each scenario's part (seconds from, to) and how many ticks a frame (2: real time at 30 fps;
# more: sped up, said in the caption).
FILM = [
    ("spill", 0.0, 100.0, 6),
    ("blood", 0.0, 125.0, 6),
    ("muddy", 0.0, 220.0, 8),
    ("trouble", 0.0, 180.0, 6),
    ("change_water", 0.0, 300.0, 12),
]
SCENARIOS = [f[0] for f in FILM]
CLOCK = 0.65  # this workspace's 2.1 GHz core -> Sean's 3.25 GHz


def godot(args, render=False, core=None):
    cmd = ["godot", "--headless"] if not render else ["xvfb-run", "-a", "godot", "--path", ".", "--rendering-driver", "vulkan"]
    cmd += ["--fixed-fps", "60", "-s", BENCH, "--"] + args
    if core is not None:
        cmd = ["taskset", "-c", str(core)] + cmd
    return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=14400)


def run_one(name, out, render):
    args = ["--scenario=" + name, "--out=" + out]
    if render:
        part = next(f for f in FILM if f[0] == name)
        args += ["--render", "--from=%s" % part[1], "--seconds=%s" % part[2], "--every=%d" % part[3]]
    r = godot(args, render)
    path = os.path.join(ROOT, out, name, "summary.json")
    ok = os.path.exists(path)
    print("%s: %s" % (name, "done" if ok else "FAILED\n" + r.stdout[-2000:] + r.stderr[-2000:]), flush=True)
    return ok


def film(src, to):
    parts = []
    for name, _a, _b, _every in FILM:
        frames = sorted(glob.glob(os.path.join(ROOT, src, name, "f_*.png")))
        if not frames:
            continue
        lst = os.path.join(ROOT, src, name, "frames.txt")
        with open(lst, "w") as f:
            for p in frames:
                f.write("file '%s'\nduration %f\n" % (p, 1.0 / 30.0))
        part = os.path.join(ROOT, src, name + ".mp4")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", lst, "-vf", "fps=30,format=yuv420p",
                        "-c:v", "libx264", "-crf", "32", "-preset", "slow", part], check=True)
        parts.append(part)
    lst = os.path.join(ROOT, src, "parts.txt")
    with open(lst, "w") as f:
        for p in parts:
            f.write("file '%s'\n" % p)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", to], check=True)
    print("film: %s (%.1f MB)" % (to, os.path.getsize(to) / 1e6))


def perf(n, out):
    rows = {"on": [], "off": []}
    for i in range(n):
        for which in ("on", "off"):
            name = "perf_" + which
            godot(["--scenario=" + name, "--out=%s/%d" % (out, i)], core=1)
            with open(os.path.join(ROOT, out, str(i), name, "summary.json")) as f:
                rows[which].append(json.load(f))
    med = lambda which, key, part="ms": statistics.median(r[part][key] for r in rows[which] if part in r)
    lines = ["| ms a tick (median of %d, one core) | with the mopping (whole run) | while he mops | without | the mopping's share | at Sean's (x%.2f) |" % (n, CLOCK),
             "|---|---|---|---|---|---|"]
    for key, what in (("people_mean", "People (his brain, body, the chore, the mop's script)"), ("mop_mean", "the mop's script (in People)"),
                      ("marks_mean", "the floor's marks (Structures)"), ("frame_mean", "the whole tick (adds the mop head's soft body, Physics)")):
        on, work, off = med("on", key), med("on", key, "ms_working"), med("off", key)
        lines.append("| %s | %.3f | %.3f | %.3f | %.3f | %.3f |" % (what, on, work, off, work - off, (work - off) * CLOCK))
    text = "\n".join(lines)
    print(text)
    with open(os.path.join(ROOT, out, "perf.md"), "w") as f:
        f.write(text + "\n")


def table(src):
    lines = ["| scenario | steps | why it stopped | floor's mess at the start -> end | bucket | faults (below floor / flung) | People ms |",
             "|---|---|---|---|---|---|---|"]
    for name in SCENARIOS:
        p = os.path.join(ROOT, src, name, "summary.json")
        if not os.path.exists(p):
            continue
        s = json.load(open(p))
        steps = " ".join("%s@%.0f" % (st[1], st[0]) for st in s.get("steps", []))
        if len(steps) > 160:
            steps = steps[:160] + " ..."
        mess = s.get("mess", [])
        m = "%s -> %s" % (json.dumps(mess[0][1:]) if mess else "", json.dumps(mess[-1][1:]) if mess else "")
        b = s.get("bucket", {})
        bk = "%.2f l, murk %.2f, dirt %.1f g, blood %.1f ml, %d changes" % (b.get("litres", 0), b.get("murk", 0), b.get("dirt", 0), b.get("blood", 0), s.get("chore", {}).get("changes", 0))
        f = s["faults"]
        lines.append("| %s | %s | %s | %s | %s | %d / %d | %.3f |" % (name, steps, s.get("chore", {}).get("stopped", ""), m, bk,
                     f["below_floor"], f["flung"], s["ms"]["people_mean"]))
    text = "\n".join(lines)
    print(text)
    with open(os.path.join(ROOT, src, "table.md"), "w") as f:
        f.write(text + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="build/mopping/base")
    ap.add_argument("--scenario", default="")
    ap.add_argument("--render", action="store_true")
    ap.add_argument("--jobs", type=int, default=2)
    ap.add_argument("--film", default="")
    ap.add_argument("--to", default="")
    ap.add_argument("--perf", type=int, default=0)
    ap.add_argument("--table", default="")
    a = ap.parse_args()
    if a.film:
        film(a.film, a.to or os.path.join(ROOT, a.film, "mopping.mp4"))
        return
    if a.table:
        table(a.table)
        return
    if a.perf:
        perf(a.perf, a.out)
        return
    names = a.scenario.split(",") if a.scenario else SCENARIOS
    with ThreadPoolExecutor(max_workers=a.jobs) as ex:
        ok = list(ex.map(lambda n: run_one(n, a.out, a.render), names))
    if not a.render:
        table(a.out)
    sys.exit(0 if all(ok) else 1)


if __name__ == "__main__":
    main()
