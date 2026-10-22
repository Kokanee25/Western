#!/usr/bin/env python3
"""The sound lab's runs (README.md): one fresh game a scenario under Movie Maker (xvfb, lavapipe,
nothing drawn but the view's one frame), the heard WAVs measured by measure.py, the clips cut.

    python3 experiments/sound_lab/run.py --out=build/sound_lab/base           # every scenario, then the table
    python3 experiments/sound_lab/run.py --scenario=list
    python3 experiments/sound_lab/run.py --scenario=revolver_street_20,dynamite_out_30 --out=...
    python3 experiments/sound_lab/run.py --scenario=revolver_* --out=...     # a prefix
    python3 experiments/sound_lab/run.py --table=ROOT                        # the table again, no Godot
    python3 experiments/sound_lab/run.py --clips=ROOT                        # mp3 clips of every scenario
    --jobs=N (3), --seed=N, --picture (draw every frame: slow, the movie kept as ROOT/<s>/movie.avi)
"""
import fnmatch
import json
import os
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import measure  # noqa: E402


def _opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
        if a == f"--{name}":
            return True
    return default


def names():
    d = json.load(open(os.path.join(HERE, "scenarios.json")))
    out = []
    for w in d["guns"]["weapons"]:
        for place, p in d["guns"]["places"].items():
            for l in p["listeners"]:
                out.append(f"{w}_{place}_{l}")
    return out + list(d["scenarios"].keys())


def run_one(job):
    name, out_dir, port, seed, picture = job
    os.makedirs(out_dir, exist_ok=True)
    cmds = os.path.join(out_dir, "cmds.txt")
    with open(cmds, "w") as f:
        f.write(f"sound {name} seed={seed} out={out_dir}{' picture' if picture else ''}\nquit\n")
    movie = os.path.join(out_dir, "movie.avi")
    godot = os.environ.get("GODOT", "godot")
    cmd = ["xvfb-run", "-a", "-s", "-screen 0 640x360x24", godot, "--path", ROOT, "--rendering-driver", "vulkan",
           "--resolution", "640x360", "--fixed-fps", "60", "--write-movie", movie,
           "--", "--dev-bridge", f"--bridge-port={port}", f"--bridge-script={cmds}"]
    if not picture:
        cmd.append("--sound-lab-dark")
    t = time.time()
    with open(os.path.join(out_dir, "godot.log"), "w") as log:
        try:
            subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, timeout=900, start_new_session=True)
        except subprocess.TimeoutExpired:
            pass
    if not picture and os.path.exists(movie):
        os.remove(movie)
    ok = os.path.exists(os.path.join(out_dir, "summary.json"))
    print(f"{'ok ' if ok else 'FAIL'} {name} ({time.time() - t:.0f} s)", flush=True)
    return name, ok


def main():
    if _opt("scenario") == "list":
        print("\n".join(names()))
        return 0
    if _opt("table"):
        measure.table(_opt("table"))
        return 0
    if _opt("clips"):
        clips(_opt("clips"))
        return 0
    out = os.path.abspath(_opt("out", os.path.join(ROOT, "build", "sound_lab", "run")))
    want = _opt("scenario")
    todo = names()
    if want:
        pats = want.split(",")
        todo = [n for n in todo if any(fnmatch.fnmatch(n, p) for p in pats)]
    os.makedirs(out, exist_ok=True)
    # Godot's import mustn't take the WAVs and PNGs for the project's.
    open(os.path.join(out, ".gdignore"), "w").close()
    seed = int(_opt("seed", 1))
    jobs = [(n, os.path.join(out, n), 8820 + i, seed, bool(_opt("picture"))) for i, n in enumerate(todo)]
    with ThreadPoolExecutor(int(_opt("jobs", 3))) as ex:
        results = list(ex.map(run_one, jobs))
    failed = [n for n, ok in results if not ok]
    measure.table(out)
    if failed:
        print("failed:", ", ".join(failed))
        return 1
    return 0


def clips(root):
    """Each scenario's heard.wav as an mp3 (192 kb/s) beside it, and the lot in ROOT/clips/."""
    dest = os.path.join(root, "clips")
    os.makedirs(dest, exist_ok=True)
    for name in sorted(os.listdir(root)):
        wav = os.path.join(root, name, "heard.wav")
        if not os.path.exists(wav):
            continue
        mp3 = os.path.join(dest, f"{name}.mp3")
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-codec:a", "libmp3lame", "-b:a", "192k", mp3], check=True)
    print(f"clips in {dest}")


if __name__ == "__main__":
    sys.exit(main())
