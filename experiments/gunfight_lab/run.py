#!/usr/bin/env python3
"""The gunfight lab's runner (README.md): every fight in its own headless game, a few at a time.

    python3 experiments/gunfight_lab/run.py --out=build/gunfight_lab/base            # the baseline matrix
    python3 experiments/gunfight_lab/run.py --scenarios=street --hours=golden --weapons=revolver \\
        --styles=hold,cover,push --seeds=1-8 --bodies=studio --out=build/gunfight_lab/try
    python3 experiments/gunfight_lab/run.py --list --out=...                          # what it would run
    python3 experiments/gunfight_lab/run.py --sheet=street_golden_revolver_cover_studio_s2 --out=...  # drawn, its sheet

Each fight is `gf_fight ...` as the game's --bridge-script (so it starts on the same frame every
time: a seed gives the same fight), its record in OUT/fights/<name>.json, its log in OUT/logs/.
A fight already recorded is skipped, so a run can be resumed. --jobs=N games at once (default: the
cores). --max=S caps a fight (180 s). --opening=draw: your gun starts away and they turn after 3 s (as you play it); --variant=A|B|C the gang's (OutlawBrain.Variant; C, all three
fixes, unless said). Then analyse.py OUT writes OUT/baseline.md and .json.
--sheet=NAME draws that one fight (xvfb and lavapipe; --every=S between pairs of frames, --size=WxH)
into OUT/sheets/NAME/ (fight.json, shots/, sheet.png): the same fight as the headless one.
"""
import itertools
import json
import queue
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def opt(args, name, default=None):
    for a in args:
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


def name_of(f):
    name = "{scenario}_{hour}_{weapon}_{style}_{bodies}_s{seed}".format(**f)
    return name + ("_" + f["opening"] if f.get("opening") else "")


def matrix(args):
    keys = {
        "scenario": opt(args, "scenarios", "street,saloon,ambush").split(","),
        "hour": opt(args, "hours", "golden,night").split(","),
        "weapon": opt(args, "weapons", "revolver,shotgun").split(","),
        "style": opt(args, "styles", "hold,cover,push").split(","),
        "bodies": opt(args, "bodies", "studio").split(","),
        "seed": seeds(opt(args, "seeds", "1-6")),
        "variant": [opt(args, "variant", "C")],
        "opening": opt(args, "opening", "").split(","),
        "fixes": [opt(args, "fixes", "all")],  # variant D's: all, none, a+b, -a (all but a)  # "" (as the arena starts), draw, shoot; several: a,b
    }
    return [dict(zip(keys, combo)) for combo in itertools.product(*keys.values())]


def run_one(f, out, ports, max_s, godot):
    name = name_of(f)
    rec = os.path.join(out, "fights", name + ".json")
    if os.path.exists(rec):
        return name, "kept", 0.0
    script = os.path.join(out, "scripts", name + ".txt")
    with open(script, "w") as fh:
        fh.write("gf_fight {scenario} hour={hour} weapon={weapon} style={style} bodies={bodies} seed={seed} variant={variant} opening={opening} fixes={fixes} dress={dress} max={max} out={out}\nquit\n".format(
            max=max_s, out=os.path.abspath(rec), dress=opt(sys.argv[1:], "dress", ""), **f))
    cmd = [godot, "--headless", "--fixed-fps", "60", "--path", ROOT, "--", "--dev-bridge", "--bridge-port=PORT",
           f"--bridge-script={os.path.abspath(script)}"]
    t0 = time.time()
    port = ports.get()
    cmd[cmd.index("--bridge-port=PORT")] = f"--bridge-port={port}"
    try:
        with open(os.path.join(out, "logs", name + ".log"), "w") as log:
            subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, timeout=1800)
    except subprocess.TimeoutExpired:
        return name, "timed out", time.time() - t0
    finally:
        ports.put(port)
    return name, "done" if os.path.exists(rec) else "FAILED (see logs/%s.log)" % name, time.time() - t0


def sheet(name, out, every, size, variant="C"):
    """One fight drawn (xvfb, lavapipe: drawn only round each capture), then its contact sheet."""
    parts = name.split("_")
    f = dict(zip(["scenario", "hour", "weapon", "style", "bodies"], parts[:5]), seed=int(parts[5][1:]), variant=variant)
    d = os.path.abspath(os.path.join(out, "sheets", name))
    os.makedirs(d, exist_ok=True)
    script = os.path.join(d, "fight.txt")
    with open(script, "w") as fh:
        fh.write("gf_fight {scenario} hour={hour} weapon={weapon} style={style} bodies={bodies} seed={seed} variant={variant} out={d}/fight.json "
                 "shots={d}/shots every={every}\nquit\n".format(d=d, every=every, **f))
    godot = os.environ.get("GODOT", "godot")
    cmd = ["xvfb-run", "-a", "-s", f"-screen 0 {size}x24", godot, "--path", ROOT, "--rendering-driver", "vulkan", "--resolution", size,
           "--fixed-fps", "60", "--", "--dev-bridge", "--bridge-port=8899", f"--bridge-script={script}"]
    with open(os.path.join(d, "godot.log"), "w") as log:
        subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, timeout=7200)
    here = os.path.dirname(os.path.abspath(__file__))
    return subprocess.run([sys.executable, os.path.join(here, "sheet.py"), os.path.join(d, "fight.json"), os.path.join(d, "shots"),
                           f"--out={os.path.join(d, 'sheet.png')}"]).returncode


def main(argv):
    if "-h" in argv or "--help" in argv:
        print(__doc__)
        return 0
    out = opt(argv, "out", os.path.join(ROOT, "build", "gunfight_lab", "base"))
    if opt(argv, "sheet"):
        return sheet(opt(argv, "sheet"), out, float(opt(argv, "every", 1.5)), opt(argv, "size", "960x540"), opt(argv, "variant", "C"))
    fights = matrix(argv)
    if opt(argv, "list"):
        for f in fights:
            print(name_of(f))
        print(len(fights), "fights")
        return 0
    for d in ("fights", "scripts", "logs"):
        os.makedirs(os.path.join(out, d), exist_ok=True)
    jobs = int(opt(argv, "jobs", os.cpu_count() or 2))
    max_s = float(opt(argv, "max", 180))
    godot = os.environ.get("GODOT", "godot")
    sha = subprocess.run(["git", "-C", ROOT, "rev-parse", "--short", "HEAD"], capture_output=True, text=True).stdout.strip()
    version = subprocess.run([godot, "--version"], capture_output=True, text=True).stdout.strip()
    with open(os.path.join(out, "manifest.json"), "w") as fh:
        json.dump({"source": sha, "godot": version, "cpu": os.cpu_count(), "jobs": jobs, "max_s": max_s,
                   "command": " ".join(["run.py"] + argv), "fights": len(fights)}, fh, indent=1)
    t0 = time.time()
    done = 0
    failed = []
    ports = queue.Queue()
    for i in range(jobs):
        ports.put(int(opt(sys.argv[1:], "port_base", "8800")) + i)
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        futures = [pool.submit(run_one, f, out, ports, max_s, godot) for f in fights]
        for fu in futures:
            name, status, secs = fu.result()
            done += 1
            if status.startswith("FAILED") or status == "timed out":
                failed.append(name)
            if status != "kept":
                print(f"[{done}/{len(fights)}] {name}: {status} ({secs:.0f} s; {time.time() - t0:.0f} s in all)", flush=True)
    print(f"{done} fights, {len(failed)} failed, {time.time() - t0:.0f} s")
    for n in failed:
        print("  failed:", n)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
