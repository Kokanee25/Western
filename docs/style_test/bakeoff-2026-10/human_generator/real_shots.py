"""The realistic men in the game, shot the same way every time (#547: every step judged by a
side-by-side of the same man, Blender against in-game, saloon and street). Each man stands in the
saloon by lamplight (21:30) and in the street by day (14:00), facing the camera; per man and place
a face shot (0.9 m) and a half-figure shot (2.2 m), at the game's 1280x720. Game renders only (the
men's own files stay in the private Studio; copy them into assets/people/ first and import).

    python3 docs/style_test/bakeoff-2026-10/human_generator/real_shots.py --men=hg_real_rancher,hg_real_cowboy \
        --out=build/realshots2/after [--game-args=--real-off=fringe+highlight] \
        [--variants=a:fringe+highlight+soft,b:highlight+soft,c:soft,d:none]

Writes <out>/<man>_<place>_<face|half>.png; with --variants, <out>/<variant>/... for each, shot one
after the other at the same moment (the realistic men lab's real_off: what of #547 step 3 is left
out), so a pair differs only by the change. Uses the dev bridge and the body lab's body_spawn.
"""
import json
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BRIDGE = [sys.executable, os.path.join(ROOT, "tools/bridge.py")]
# Where they stand: x along the room or street, a man every 1.3 m; facing +Z (yaw 180) toward a
# camera on their +Z side.
PLACES = {
    "saloon": {"time": 21.5, "floor": 0.78, "z": 4.0, "x0": 8.3},
    "street": {"time": 14.0, "floor": 0.0, "z": -10.0, "x0": 11.0},
}


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
    return default


def main():
    men = opt("men", "hg_real_rancher").split(",")
    variants = [v.split(":", 1) for v in opt("variants").split(",")] if opt("variants") else [("", None)]
    out = os.path.abspath(opt("out", os.path.join(ROOT, "build/realshots2")))
    os.makedirs(out, exist_ok=True)
    start = BRIDGE + ["start", "--size=1280x720"]
    if opt("game-args"):
        start.append("--game-args=" + opt("game-args"))
    subprocess.run(BRIDGE + ["stop"], capture_output=True)
    subprocess.run(start, check=True)
    try:
        n = 0
        for place, p in PLACES.items():
            cmds = ["time %s" % p["time"]]
            for i, man in enumerate(men):
                cmds.append("body_spawn %s %.2f %.2f %.2f 180" % (man, p["x0"] + 1.3 * i, p["floor"], p["z"]))
            # The clock jump re-blends the look; under lavapipe wait before the first shot.
            cmds.append("wait 6")
            subprocess.run(BRIDGE + cmds, check=True, capture_output=True)
            for i, man in enumerate(men):
                n += 1
                x, z = p["x0"] + 1.3 * i, p["z"]
                r = subprocess.run(BRIDGE + ["body_where body%d" % n], capture_output=True, text=True)
                head = json.loads(r.stdout.strip().splitlines()[-1])["head"][1] - 0.03
                shots = [
                    ("face", (x, head + 0.03, z + 0.9), (x, head, z), 40),
                    ("half", (x, head - 0.2, z + 2.2), (x, head - 0.42, z), 45),
                ]
                cmds = []
                for name, eye, at, fov in shots:
                    cmds += ["camera %.2f %.2f %.2f %.2f %.2f %.2f %d" % (*eye, *at, fov), "wait 1.5"]
                    for v, off in variants:
                        os.makedirs(os.path.join(out, v), exist_ok=True)
                        if off is not None:
                            cmds.append("real_off %s" % off)
                        cmds.append("screenshot %s" % os.path.join(out, v, "%s_%s_%s.png" % (man, place, name)))
                r = subprocess.run(BRIDGE + cmds, capture_output=True, text=True)
                if '"ok": false' in r.stdout:
                    print(r.stdout)
            # Clear them before the next place (they're spawned again there).
            subprocess.run(BRIDGE + ["camera player"], capture_output=True)
        print("shots in", out)
    finally:
        subprocess.run(BRIDGE + ["stop"], capture_output=True)


if __name__ == "__main__":
    main()
