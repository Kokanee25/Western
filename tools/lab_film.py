#!/usr/bin/env python3
"""A lab's film made on a CI runner (.github/workflows/lab_film.yml, #973): for sessions whose
workspace can't build the native plugin (crates.io unreachable) or render fast enough.

    python3 tools/lab_film.py experiments/<lab>/film/request.txt

The request is the dev bridge's commands, one a line (# comments), and these of the runner's own:

    @start ARGS...                 tools/bridge.py start ARGS (e.g. --size=960x540 --game-args=--real)
    @stop                          tools/bridge.py stop
    @encode FRAMES_DIR OUT [FPS=60] [SKIP=0]   FRAMES_DIR/0000.png... to OUT (H.264 mp4)
    @still FRAMES_DIR N OUT        frame N of FRAMES_DIR as a JPEG, 960 wide
    @godot ARGS...                 godot ARGS (headless scripts: benches); its lines starting BENCH or RESULT (else its last 20) as the answer

Every command's answer goes to film/out/replies.jsonl beside the request; OUT paths are relative to
the repository (put them under the request's film/out/). Exits 1 if a command answers ok: false.
"""
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main(req: str) -> int:
    out_dir = os.path.join(os.path.dirname(os.path.abspath(req)), "out")
    os.makedirs(out_dir, exist_ok=True)
    # (Godot mustn't import the stills: their .import files would be new to every checkout.)
    open(os.path.join(out_dir, ".gdignore"), "w").close()
    replies = open(os.path.join(out_dir, "replies.jsonl"), "w")
    bridge = [sys.executable, os.path.join(ROOT, "tools", "bridge.py")]
    failed = 0
    for line in open(req).read().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        w = line.split()
        if w[0] == "@start":
            r = subprocess.run(bridge + ["start"] + w[1:], cwd=ROOT, capture_output=True, text=True)
            text = r.stdout.strip() or r.stderr.strip()
        elif w[0] == "@stop":
            r = subprocess.run(bridge + ["stop"], cwd=ROOT, capture_output=True, text=True)
            text = r.stdout.strip()
        elif w[0] == "@encode":
            fps = w[3] if len(w) > 3 else "60"
            skip = w[4] if len(w) > 4 else "0"
            os.makedirs(os.path.dirname(os.path.join(ROOT, w[2])), exist_ok=True)
            r = subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", fps, "-start_number", skip,
                                "-i", os.path.join(ROOT, w[1], "%04d.png"), "-c:v", "libx264", "-preset", "slow",
                                "-crf", "26", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
                                os.path.join(ROOT, w[2])], capture_output=True, text=True)
            text = json.dumps({"encoded": w[2], "ok": r.returncode == 0, "error": r.stderr[-300:]})
        elif w[0] == "@still":
            os.makedirs(os.path.dirname(os.path.join(ROOT, w[3])), exist_ok=True)
            r = subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i",
                                os.path.join(ROOT, w[1], "%04d.png" % int(w[2])), "-vf", "scale=960:-2",
                                "-q:v", "3", os.path.join(ROOT, w[3])], capture_output=True, text=True)
            text = json.dumps({"still": w[3], "ok": r.returncode == 0})
        elif w[0] == "@godot":
            r = subprocess.run([os.environ.get("GODOT", "godot")] + w[1:], cwd=ROOT, capture_output=True, text=True)
            # Its BENCH/RESULT lines if it prints any, else its last 20 lines.
            lines = (r.stdout + r.stderr).strip().splitlines()
            keep = [l for l in lines if l.startswith(("BENCH", "RESULT"))]
            text = "\n".join(keep or lines[-20:])
            if r.returncode != 0:
                text += '\n{"ok": false}'
        else:
            r = subprocess.run(bridge + ["--timeout=2400", line], cwd=ROOT, capture_output=True, text=True)
            text = r.stdout.strip() or json.dumps({"ok": False, "error": r.stderr.strip()[-300:]})
        print(f"> {line}\n{text[:600]}", flush=True)
        replies.write(json.dumps({"command": line, "reply": text}) + "\n")
        replies.flush()
        if '"ok": false' in text.replace('"ok":false', '"ok": false'):
            failed += 1
    subprocess.run(bridge + ["stop"], cwd=ROOT, capture_output=True)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
