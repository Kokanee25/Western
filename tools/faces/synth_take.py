#!/usr/bin/env python3
"""A stand-in Live Link Face take, for testing the face pipeline before a real one: a line spoken
by espeak-ng with the mbrola us1 voice (apt-get install espeak-ng mbrola mbrola-us1; used as
programs, nothing of theirs is kept), its phonemes turned into ARKit values, written as Live Link
Face writes them (CSV at 60 fps, and a .mov with the sound and a timecode).

    python3 tools/faces/synth_take.py --text="Well, I reckon that's the end of it." --out=build/faces/synth
→ <out>/take.csv, <out>/take.mov

Each phoneme pulls the ARKit values toward its mouth shape (VISEME) at its middle; between them
the values are eased (a 45 ms Gaussian), as a mouth runs one sound into the next. He blinks every
few seconds and lifts his brows on the line's first stressed word. Not a performance: a test.
"""
import csv
import os
import subprocess
import sys

import numpy as np

ARKIT = ["EyeBlinkLeft", "EyeLookDownLeft", "EyeLookInLeft", "EyeLookOutLeft", "EyeLookUpLeft", "EyeSquintLeft",
         "EyeWideLeft", "EyeBlinkRight", "EyeLookDownRight", "EyeLookInRight", "EyeLookOutRight", "EyeLookUpRight",
         "EyeSquintRight", "EyeWideRight", "JawForward", "JawRight", "JawLeft", "JawOpen", "MouthClose",
         "MouthFunnel", "MouthPucker", "MouthRight", "MouthLeft", "MouthSmileLeft", "MouthSmileRight",
         "MouthFrownLeft", "MouthFrownRight", "MouthDimpleLeft", "MouthDimpleRight", "MouthStretchLeft",
         "MouthStretchRight", "MouthRollLower", "MouthRollUpper", "MouthShrugLower", "MouthShrugUpper",
         "MouthPressLeft", "MouthPressRight", "MouthLowerDownLeft", "MouthLowerDownRight", "MouthUpperUpLeft",
         "MouthUpperUpRight", "BrowDownLeft", "BrowDownRight", "BrowInnerUp", "BrowOuterUpLeft",
         "BrowOuterUpRight", "CheekPuff", "CheekSquintLeft", "CheekSquintRight", "NoseSneerLeft",
         "NoseSneerRight", "TongueOut"]
EXTRA = ["HeadYaw", "HeadPitch", "HeadRoll", "LeftEyeYaw", "LeftEyePitch", "LeftEyeRoll", "RightEyeYaw",
         "RightEyePitch", "RightEyeRoll"]
OPEN = {"JawOpen": 0.45, "MouthLowerDownLeft": 0.35, "MouthLowerDownRight": 0.35}
WIDE = {"JawOpen": 0.15, "MouthStretchLeft": 0.45, "MouthStretchRight": 0.45, "MouthSmileLeft": 0.15, "MouthSmileRight": 0.15}
ROUND = {"JawOpen": 0.15, "MouthFunnel": 0.6, "MouthPucker": 0.5}
CLOSED = {"MouthClose": 0.3, "MouthPressLeft": 0.6, "MouthPressRight": 0.6, "MouthRollUpper": 0.2}
LIPTEETH = {"MouthRollLower": 0.7, "MouthUpperUpLeft": 0.15, "MouthUpperUpRight": 0.15, "JawOpen": 0.05}
SMALL = {"JawOpen": 0.12, "MouthStretchLeft": 0.15, "MouthStretchRight": 0.15}
VISEME = {**{p: OPEN for p in ["a", "A", "{", "V", "@", "E", "AI", "aU", "O", "Q", "3", "r="]},
          **{p: WIDE for p in ["i", "I", "e", "eI", "j"]},
          **{p: ROUND for p in ["u", "U", "oU", "w", "OI"]},
          **{p: CLOSED for p in ["p", "b", "m"]},
          **{p: LIPTEETH for p in ["f", "v"]},
          **{p: SMALL for p in ["t", "d", "n", "l", "s", "z", "k", "g", "h", "T", "D", "S", "Z", "tS", "dZ", "N", "r"]}}


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    text = a.get("--text", "Well, I reckon that's the end of it, friend.")
    out = a.get("--out", "build/faces/synth")
    os.makedirs(out, exist_ok=True)
    wav = os.path.join(out, "line.wav")
    pho = subprocess.run(["espeak-ng", "-v", "mb-us1", "-s", "140", "-q", "--pho", text], capture_output=True, text=True).stdout
    subprocess.run(["espeak-ng", "-v", "mb-us1", "-s", "140", "-w", wav, text], capture_output=True)
    lead = 0.4                                        # silence before the line, as a take has
    keys, t = [], lead
    for line in pho.splitlines():
        b = line.split()
        if len(b) < 2:
            continue
        d = float(b[1]) / 1000
        keys.append((t + d / 2, VISEME.get(b[0], {})))
        t += d
    end = t + 0.6
    fps = 60
    T = np.arange(0, end, 1 / fps)
    vals = {k: np.zeros(len(T)) for k in ARKIT + EXTRA}
    for k in ARKIT:
        pts = np.array([(c, shape.get(k, 0.0)) for c, shape in keys])
        if len(pts) and pts[:, 1].any():
            w = np.exp(-0.5 * ((T[:, None] - pts[None, :, 0]) / 0.045) ** 2)
            vals[k] = np.clip((w * pts[None, :, 1]).sum(1) / np.maximum(w.sum(1), 1e-3) * np.minimum(1, w.sum(1) * 2), 0, 1)
    for tb in np.arange(0.9, end, 2.7):                  # blinks: 150 ms
        b = np.clip(1 - np.abs(T - tb) / 0.075, 0, 1)
        vals["EyeBlinkLeft"] = np.maximum(vals["EyeBlinkLeft"], b)
        vals["EyeBlinkRight"] = np.maximum(vals["EyeBlinkRight"], b)
    first = keys[min(4, len(keys) - 1)][0]
    lift = np.exp(-0.5 * ((T - first) / 0.25) ** 2) * 0.7
    vals["BrowInnerUp"] = lift
    vals["BrowOuterUpLeft"] = vals["BrowOuterUpRight"] = lift * 0.6
    vals["HeadPitch"] = 0.05 * np.sin(T * 2.1)
    vals["HeadYaw"] = 0.06 * np.sin(T * 1.3)
    start = 10 * 3600 + 30 * 60
    with open(os.path.join(out, "take.csv"), "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(["Timecode", "BlendShapeCount"] + ARKIT + EXTRA)
        for i, ti in enumerate(T):
            s = start + 2.0 + ti                      # the CSV starts 2 s into the .mov
            h, m, sec = int(s // 3600), int(s % 3600 // 60), int(s % 60)
            fr = (s - int(s)) * fps
            wr.writerow(["%02d:%02d:%02d:%06.3f" % (h, m, sec, fr), 61] + ["%.4f" % vals[k][i] for k in ARKIT + EXTRA])
    # The .mov: 2 s of quiet, the lead, the line; timecode 10:30:00:00.
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "lavfi", "-i", "color=c=black:s=320x240:r=30:d=%.2f" % (end + 2.5),
                    "-f", "lavfi", "-t", "%.2f" % (2.0 + lead), "-i", "anullsrc=r=16000:cl=mono", "-i", wav,
                    "-filter_complex", "[1:a][2:a]concat=n=2:v=0:a=1[a]", "-map", "0:v", "-map", "[a]",
                    "-timecode", "10:30:00:00", "-c:v", "libx264", "-c:a", "aac", "-shortest",
                    os.path.join(out, "take.mov")], check=True)
    print("synth_take: %.1f s, %d phonemes -> %s/take.csv, take.mov" % (end, len(keys), out))


if __name__ == "__main__":
    main()
