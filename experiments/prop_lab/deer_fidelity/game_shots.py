"""The deer fidelity lab's shots in the game itself (issue #524, B and D): each version wired into the
kit's deer_head (the prop lab bridge's `deer_variant`) where the town hangs it on the saloon's back
wall, shot at noon and at night by the game's own light and pixel pipeline, the same three cameras
for each: the player's eye a couple of steps off it (his 75 degree lens and a narrow 25 degree one,
as near as the eye can take it in) and across the saloon (9 m). Each shot is cut round the deer by
where it differs from the same shot with no deer.

    python3 tools/bridge.py start --size=1280x720
    python3 experiments/prop_lab/deer_fidelity/game_shots.py OUT [--versions=game,C1f,C2,C7,A]
    python3 tools/bridge.py stop
    python3 experiments/prop_lab/deer_fidelity/sheet.py --game OUT OUT/sheet_game.jpg
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, HERE)

# The saloon's back-wall head (SaloonBuilding, at 10, 3.48, 11.9, facing -z; the floor 0.78 up).
TARGET = "10 3.42 12.1"
EYE = 0.78 + 1.64
CAMS = {"close": "10.3 %.2f 10.3 %s 75" % (EYE, TARGET), "zoom": "10.3 %.2f 10.3 %s 25" % (EYE, TARGET),
        "across": "11 %.2f 3.0 %s 75" % (EYE, TARGET)}
TIMES = {"noon": 12, "night": 22}
LABELS = {"game": "C0 the game's deer now (6k, 1k paint, grid shader, no mipmaps)", "C1": "C1 + mipmaps",
          "C1f": "C1f + mipmaps, no min-square coarsening (the game's look kept)", "C2": "C2 the game's mesh and paint, standard material",
          "C4": "C4 6k, 2k paint, baked normals, Rodin's roughness",
          "C7": "C7 15k, 2k paint, baked normals, roughness by surface", "A": "A Rodin's master (30k, 4k, all its maps)"}


# The head's box (the plaque on the wall at z 11.9, the head 0.4 out into the room, -z).
HEAD_BOX = ((9.78, 3.03, 11.5), (10.22, 3.83, 11.9))


def crop(cam, w=1280, h=720):
    """The square round the head's box as camera `cam` sees it (Godot's lens: fov the frame's height)."""
    v = [float(x) for x in CAMS[cam].split()]
    eye, target, fov = np.array(v[0:3]), np.array(v[3:6]), v[6]
    fwd = target - eye
    fwd /= np.linalg.norm(fwd)
    right = np.cross(fwd, [0, 1, 0])
    right /= np.linalg.norm(right)
    up = np.cross(right, fwd)
    f = (h / 2) / np.tan(np.radians(fov) / 2)
    pts = []
    for x in (HEAD_BOX[0][0], HEAD_BOX[1][0]):
        for y in (HEAD_BOX[0][1], HEAD_BOX[1][1]):
            for z in (HEAD_BOX[0][2], HEAD_BOX[1][2]):
                d = np.array([x, y, z]) - eye
                zc = d @ fwd
                pts.append((w / 2 + f * (d @ right) / zc, h / 2 - f * (d @ up) / zc))
    pts = np.array(pts)
    lo, hi = pts.min(0), pts.max(0)
    side = min(int(max(hi - lo) * 1.15) + 6, h)  # (the narrow lens: the frame's height, the deer filling it)
    c = np.clip((lo + hi) / 2, [side / 2, side / 2], [w - side / 2, h - side / 2])
    return [int(c[0]) - side // 2, int(c[1]) - side // 2, side]


def bridge(cmds):
    r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "bridge.py")] + cmds, capture_output=True, text=True)
    for line in r.stdout.splitlines():
        if '"ok": false' in line:
            print(line)
    return r.stdout


def main():
    out = os.path.abspath(sys.argv[1])
    os.makedirs(out, exist_ok=True)
    kw = dict(a[2:].split("=", 1) for a in sys.argv[2:] if a.startswith("--") and "=" in a)
    versions = kw.get("versions", "game,C1f,C2,C7,A").split(",")
    for tname, hour in TIMES.items():
        bridge(["time %d" % hour, "wait 6"])
        for v in ["none"] + versions:
            cmds = ["deer_variant %s" % v, "wait 1"]
            for cname, cam in CAMS.items():
                cmds += ["camera %s" % cam, "wait 0.5", "screenshot %s" % os.path.join(out, "%s_%s_%s.png" % (v, tname, cname))]
            bridge(cmds)
            print(tname, v, "done")
    bridge(["deer_variant game", "camera player"])
    shots = {"%s_%s" % (t, c): crop(c) for t in TIMES for c in CAMS}
    json.dump(shots, open(os.path.join(out, "shots.json"), "w"), indent=1)
    json.dump({v: LABELS.get(v, v) for v in versions}, open(os.path.join(out, "labels.json"), "w"), indent=1)
    print(shots)


if __name__ == "__main__":
    main()
