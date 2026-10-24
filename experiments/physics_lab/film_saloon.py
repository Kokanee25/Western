#!/usr/bin/env python3
"""A film of a saloon fight catching a man sat in a kit chair (2026-10-24, results/2026-10-24_chair_tip).

    python3 experiments/physics_lab/film_saloon.py [--out=build/video/saloon] [--size=960x540]

The game under the dev bridge, recording every frame (Godot's Movie Maker, 30 fps on game time) to a
PNG sequence (an AVI is only finished as the game quits, and a game stopped by force saved none):
Brody sat back at a table in the saloon (this lab's `seat`), you beside his chair, your kick (E,
PlayerKick) takes its back legs out, he goes over with it, gets up and draws on you, and you shoot.
Two cameras: a free one beside the chair for the kick and the fall, then yours. Then ffmpeg makes
OUT/saloon_chair.mp4 from the frames (the first second, the game loading, cut).
"""
import glob
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import bridge  # noqa: E402


def arg(name, default):
    for a in sys.argv[1:]:
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def one(cmd):
    r = bridge.send([cmd])
    out = r[0] if r else {}
    print(cmd, "->", json.dumps(out) if cmd.startswith("events") else json.dumps(out)[:300])
    return out


def main():
    out = os.path.join(ROOT, arg("out", "build/video/saloon"))
    frames = os.path.join(out, "frames")
    os.makedirs(frames, exist_ok=True)
    for f in glob.glob(os.path.join(frames, "*.png")):
        os.remove(f)
    dry = "--dry" in sys.argv  # headless, no frames: the commands only
    peek = "--peek" in sys.argv  # drawn, no movie: two screenshots of the framing (OUT/peek_*.png)
    opts = ["--headless"] if dry else ["--size=" + arg("size", "960x540")]
    if not dry and not peek:
        opts.append("--movie=" + os.path.join(frames, "f.png"))
    if bridge.start(opts) != 0:
        return 1
    marks = {}
    try:
        one("time 16")
        one("gang")
        one("wait 1")
        places = one("read places").get("places", {})
        at = places.get("saloon_floor", [11.0, 0.78, 3.5])
        sat = one("seat brody %f %f %f" % (at[0], at[1], at[2]))
        if not sat.get("ok"):
            print("Brody didn't sit:", sat)
            return 1
        spot = one("chair_kick_spot brody side")
        one("goto %f %f %f %f" % (spot["x"], spot["y"], spot["z"], spot["yaw"]))
        leg = spot["leg"]
        # The free camera on the far side of the chair from you, three-quarter on: you kick toward
        # it and he goes over across the frame (from your side your body stood in front of him).
        c = sat["at"]
        dx, dz = leg[0] - spot["x"], leg[2] - spot["z"]
        n = max((dx * dx + dz * dz) ** 0.5, 1e-3)
        dx, dz = dx / n, dz / n
        cam = (c[0] + dx * 2.9 - dz * 2.1, c[1] + 1.6, c[2] + dz * 2.9 + dx * 2.1)
        one("camera %f %f %f %f %f %f 55" % (cam[0], cam[1], cam[2], c[0], c[1] + 0.55, c[2]))
        one("wait 2")
        if peek:
            one("screenshot " + os.path.join(out, "peek_0.png"))
        marks["kick"] = one("read frame").get("frame", {})
        one("press kick 0.1")
        if peek:
            one("wait 0.5")
            one("screenshot " + os.path.join(out, "peek_1.png"))
            return 0
        one("wait 1.2")
        one("fight brody")
        one("wait 7")
        marks["up"] = one("read frame").get("frame", {})
        one("camera player")
        one("weapon revolver")
        one("wait 1")
        one("look brody")
        one("shoot 2")
        one("wait 3")
        marks["end"] = one("read frame").get("frame", {})
        one("events 30")
    finally:
        bridge.stop()
    if dry:
        return 0
    pngs = sorted(glob.glob(os.path.join(frames, "f*.png")))
    print("frames:", len(pngs), "marks:", marks)
    if not pngs:
        return 1
    mp4 = os.path.join(out, "saloon_chair.mp4")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "30", "-start_number", "30",
                    "-i", os.path.join(frames, "f%08d.png"), "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "23", mp4], check=True)
    print("wrote", mp4)
    return 0


if __name__ == "__main__":
    sys.exit(main())
