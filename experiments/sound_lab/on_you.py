#!/usr/bin/env python3
"""What a stick does to you (#596 step 2), from the sound lab's dynamite_you_* runs.

    python3 experiments/sound_lab/on_you.py ROOT [--md=FILE]

From each run's voices.csv (a row a frame: the ears' cutoff, the whine's level, the shake, the
grit; runner.gd) and heard.wav: how long the world is dull and how far (cutoff under 15 kHz, its
lowest), how long the whine is heard and how loud (its level, and in the recording the 3.6-4.0 kHz
band against the rest of the highs, to show it comes through the dull world), the shake's top and
length, the grit's length. Burst eardrums keep the cutoff low for good: that's counted apart
("for good" when it never comes back up within the run).
"""
import csv
import json
import math
import os
import sys

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt


def _opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
    return default


def measure(d):
    s = json.load(open(os.path.join(d, "summary.json")))
    rows = list(csv.DictReader(open(os.path.join(d, "voices.csv"))))
    lit = next((m["t"] for m in s["marks"] if m.get("name") == "lit"), 0.0)
    boom = lit + 0.5
    rows = [r for r in rows if float(r["t"]) >= boom]
    dt = 1.0 / 60.0
    hz = [float(r["ear_hz"]) for r in rows]
    ring = [float(r["ring"]) for r in rows]
    shake = [float(r["shake_deg"]) for r in rows]
    grit = [float(r["grit"]) for r in rows]
    t = [float(r["t"]) - boom for r in rows]
    floor = hz[-1] if hz else 20000.0  # what's left at the end: burst eardrums
    dull = [i for i, h in enumerate(hz) if h < 15000.0 and h < floor * 0.95]
    out = {
        "distance_m": s["setup"].get("distance_m"),
        "muffle_s": round(len(dull) * dt, 2),
        "muffle_from_s": round(t[dull[0]], 2) if dull else None,
        "deepest_hz": round(min(hz)) if hz else None,
        "left_hz": round(floor),
        "ring_s": round(sum(1 for x in ring if x > 0.0011) * dt, 2),
        "ring_top_db": round(20 * math.log10(max(ring)), 1) if max(ring, default=0) > 0 else None,
        "shake_top_deg": round(max(shake, default=0.0), 2),
        "shake_s": round(sum(1 for x in shake if x > 0.02) * dt, 2),
        "grit_s": round(sum(1 for x in grit if x > 0.0) * dt, 2),
    }
    rate, a = wavfile.read(os.path.join(d, "heard.wav"))
    x = a.astype(np.float64).mean(axis=1) / 32768.0
    # (the marks are on the recording's clock: its first frame is 0)
    whine = sosfilt(butter(4, [3600, 4000], btype="band", fs=rate, output="sos"), x)
    rest = sosfilt(butter(4, [2000, 3400], btype="band", fs=rate, output="sos"), x)

    def db(sig, a0, a1):
        seg = sig[max(int(a0 * rate), 0):max(int(a1 * rate), 1)]
        return round(10 * math.log10(max(float(np.mean(seg ** 2)), 1e-12)), 1)

    for name, (a0, a1) in {"0-1s": (0.0, 1.0), "1-3s": (1.0, 3.0), "3-6s": (3.0, 6.0), "10-15s": (10.0, 15.0)}.items():
        out[f"whine_{name}_db"] = db(whine, boom + a0, boom + a1)
        out[f"highs_{name}_db"] = db(rest, boom + a0, boom + a1)
    return out


def main():
    root = sys.argv[1]
    names = sorted((n for n in os.listdir(root) if n.startswith("dynamite_you_")), key=lambda n: int(n.rsplit("_", 1)[1]))
    res = {n: measure(os.path.join(root, n)) for n in names}
    json.dump(res, open(os.path.join(root, "on_you.json"), "w"), indent=1)
    cols = ["distance_m", "muffle_s", "deepest_hz", "left_hz", "ring_s", "ring_top_db", "shake_top_deg", "shake_s", "grit_s",
            "whine_1-3s_db", "highs_1-3s_db", "whine_10-15s_db", "highs_10-15s_db"]
    lines = ["| run | " + " | ".join(cols) + " |", "|---" * (len(cols) + 1) + "|"]
    for n, r in res.items():
        lines.append(f"| {n} | " + " | ".join(str(r.get(c)) for c in cols) + " |")
    text = "\n".join(lines)
    print(text)
    if _opt("md"):
        open(_opt("md"), "w").write(text + "\n")


if __name__ == "__main__":
    main()
