#!/usr/bin/env python3
"""A Live Link Face take (ARKit mode) as weights on a talking man's expressions, for the face lab.

    python3 tools/faces/arkit_take.py --csv=TAKE.csv [--mov=TAKE.mov] --out=build/faces/take [--neutral=auto|A:B|none]
→ <out>/take.json ({"fps": 30, "names": [...], "frames": [[w, ...], ...], "head": [[yaw, pitch,
  roll], ...]}) and <out>/audio.wav (the .mov's sound, from where the CSV starts).

Live Link Face's CSV: a Timecode column (HH:MM:SS:FF.fff, its frame rate the highest frame number
+ 1), BlendShapeCount, then ARKit's 52 blend shapes (0..1) and the head's and eyes' turns. The
52 come down to his 20 expressions (his resting face taken off first: neutral()) (tools/faces/talking_face.py EXPRESSIONS) by MAP below, each
expression a sum of ARKit values times a gain, less what the others already show (his "aa" holds
some jaw, his "scowl" the brows), clamped to 0..1, then lightly smoothed (SMOOTH frames).
The .mov's own timecode (if it has one) lines its sound up with the CSV's first row.
"""
import csv
import json
import os
import subprocess
import sys

import numpy as np

FPS = 30
SMOOTH = 1          # frames either side averaged at FPS (ARKit's jitter)
NEUTRAL_LEAD = 0.25  # seconds before his voice starts that his resting face is still taken from
# ARKit names (lower case) times gains, per expression. A negative entry takes away.
MAP = {
    "jaw_open": {"jawopen": 1.3, "mouthclose": -0.6},
    "aa": {},                                  # his authored "ah" (jaw and lips): a take has both apart
    "lips_apart": {"mouthlowerdownleft": 0.45, "mouthlowerdownright": 0.45, "mouthupperupleft": 0.2, "mouthupperupright": 0.2},
    "ee": {"mouthstretchleft": 1.2, "mouthstretchright": 1.2, "mouthdimpleleft": 0.3, "mouthdimpleright": 0.3},
    "oo": {"mouthfunnel": 1.0, "mouthpucker": 0.8},
    "fv": {"mouthrolllower": 1.3, "mouthshrugupper": 0.3},
    "mbp": {"mouthpressleft": 0.7, "mouthpressright": 0.7, "mouthrollupper": 0.8, "mouthclose": 0.4},
    "blink_l": {"eyeblinkleft": 1.15},
    "blink_r": {"eyeblinkright": 1.15},
    "squint": {"eyesquintleft": 0.6, "eyesquintright": 0.6, "cheeksquintleft": 0.4, "cheeksquintright": 0.4},
    "brows_up": {"browinnerup": 0.8, "browouterupleft": 0.5, "browouterupright": 0.5},
    "scowl": {"@scowl_both": 1.3},
    "brows_down": {"browdownleft": 0.6, "browdownright": 0.6, "@scowl": -1.0},
    "smile": {"@smile_both": 1.2},
    "smile_l": {"mouthsmileleft": 1.2, "@smile_both": -1.2},
    "smile_r": {"mouthsmileright": 1.2, "@smile_both": -1.2},
    # his eyes: to his left the left eye looks out and the right one in (ARKit's left is his left)
    "look_left": {"eyelookoutleft": 0.6, "eyelookinright": 0.6},
    "look_right": {"eyelookinleft": 0.6, "eyelookoutright": 0.6},
    "look_up": {"eyelookupleft": 0.6, "eyelookupright": 0.6},
    "look_down": {"eyelookdownleft": 0.6, "eyelookdownright": 0.6},
}
# Expressions worked out first, so others can take them away ("@name").
ORDER = ["aa", "lips_apart", "scowl", "jaw_open", "ee", "oo", "fv", "mbp", "blink_l", "blink_r", "squint", "brows_up",
         "brows_down", "smile", "smile_l", "smile_r", "look_left", "look_right", "look_up", "look_down"]


def seconds(tc, fps):
    h, m, s, f = tc.split(":")
    return int(h) * 3600 + int(m) * 60 + int(s) + float(f) / fps


def read_csv(path):
    rows = list(csv.reader(open(path, newline="")))
    head = [h.strip().lower() for h in rows[0]]
    data = [r for r in rows[1:] if r and len(r) >= len(head) - 1]
    fps = 1 + max(int(float(r[0].split(":")[3])) for r in data)
    fps = 60 if fps > 50 else 30 if fps > 25 else fps
    t = np.array([seconds(r[0], fps) for r in data])
    vals = {h: np.array([float(r[i]) for r in data]) for i, h in enumerate(head) if i >= 2}
    return t, vals, fps


def weights(vals):
    out = {}
    n = len(next(iter(vals.values())))
    get = lambda k: vals.get(k, np.zeros(n))
    sm = np.minimum(get("mouthsmileleft"), get("mouthsmileright"))
    # a scowl or snarl: the nose wrinkled with the brows down or the cheeks squinting (talking
    # wrinkles the nose a little too, but leaves the cheeks and brows be)
    brow = (get("browdownleft") + get("browdownright")) / 2
    cheek = (get("cheeksquintleft") + get("cheeksquintright")) / 2
    sc = np.minimum((get("nosesneerleft") + get("nosesneerright")) / 2, np.maximum(brow, cheek))
    for e in ORDER:
        w = np.zeros(n)
        for k, g in MAP[e].items():
            if k == "@smile_both":
                w += g * sm
            elif k == "@scowl_both":
                w += g * sc
            elif k.startswith("@"):
                w += g * out.get(k[1:], 0)
            else:
                w += g * get(k)
        out[e] = np.clip(w, 0, 1)
    return out


def neutral(t, vals, wav=None, spec="auto"):
    """His resting face, taken off every value (a take recorded uncalibrated reads a resting face
    as brows half down, eyes a sixth shut...): the mean over a quiet stretch before he speaks
    (`spec` "auto": from the sound, the start to NEUTRAL_LEAD before his voice; "A:B" seconds;
    "none"), else each value's 5th percentile. Each value then (v - rest) / (1 - rest), clamped."""
    rest = {}
    if spec == "none":
        return vals, None
    span = None
    if spec != "auto":
        a, b = (float(x) for x in spec.split(":"))
        span = (a, b)
    elif wav is not None:
        import wave
        w = wave.open(wav)
        x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(float)
        hop = w.getframerate() // 20
        rms = np.array([np.sqrt((x[i:i + hop] ** 2).mean()) for i in range(0, len(x) - hop, hop)])
        floor = np.percentile(rms, 30)
        loud = np.where(rms > max(4 * floor, 0.02 * 32768 * 0.05))[0]
        onset = loud[0] * 0.05 if len(loud) else 0.0
        if onset - NEUTRAL_LEAD > 0.4:
            span = (0.1, onset - NEUTRAL_LEAD)
    t0 = t - t[0]
    keep = (t0 >= span[0]) & (t0 <= span[1]) if span else None
    out = {}
    for k, v in vals.items():
        if keep is not None and keep.sum() > 5:
            base = float(np.mean(v[keep]))
        else:
            base = float(np.percentile(v, 5))
        rest[k] = base
        if k.startswith("head") or k.endswith(("yaw", "pitch", "roll")):
            out[k] = v - base
        else:
            out[k] = np.clip((v - base) / max(1.0 - base, 1e-3), 0, 1)
    return out, {"span": span, "rest": {k: round(v, 3) for k, v in rest.items() if abs(v) > 0.05}}


def mov_start(mov):
    """The .mov's starting timecode in seconds (None if it has none)."""
    try:
        r = subprocess.run(["ffprobe", "-v", "quiet", "-print_format", "json", "-show_streams", "-show_format", mov],
                           capture_output=True, text=True, check=True)
        info = json.loads(r.stdout)
        tags = [info.get("format", {}).get("tags", {})] + [s.get("tags", {}) for s in info.get("streams", [])]
        for t in tags:
            if "timecode" in t:
                rate = next((s.get("r_frame_rate") for s in info["streams"] if s.get("codec_type") == "video"), "30/1")
                a, b = rate.split("/")
                return seconds(t["timecode"].replace(";", ":"), round(float(a) / float(b)))
    except (subprocess.CalledProcessError, json.JSONDecodeError, ValueError):
        pass
    return None


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    out = a.get("--out", "build/faces/take")
    os.makedirs(out, exist_ok=True)
    t, vals, fps = read_csv(a["--csv"])
    wav = None
    if a.get("--mov"):
        start = mov_start(a["--mov"])
        skip = max(0.0, t[0] - start) if start is not None and abs(t[0] - start) < 600 else 0.0
        wav = os.path.join(out, "audio.wav")
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-ss", "%.3f" % skip, "-i", a["--mov"], "-vn", "-ac", "1",
                        "-ar", "48000", wav], check=True)
        print("arkit_take: sound from %.3f s into the .mov -> %s" % (skip, wav))
    vals, cal = neutral(t, vals, wav, a.get("--neutral", "auto"))
    if cal:
        print("arkit_take: his resting face from %s s: %s" % (cal["span"] or "each value's 5th percentile",
              {k: v for k, v in list(cal["rest"].items())[:12]}))
    w = weights(vals)
    t0 = t[0]
    grid = np.arange(0, t[-1] - t0, 1.0 / FPS)
    names = list(MAP)
    cols = []
    for e in names:
        c = np.interp(grid, t - t0, w[e])
        if SMOOTH:
            k = np.ones(2 * SMOOTH + 1) / (2 * SMOOTH + 1)
            c = np.convolve(np.pad(c, SMOOTH, mode="edge"), k, mode="valid")
        cols.append(c)
    frames = np.round(np.stack(cols, 1), 3).tolist()
    head = np.stack([np.interp(grid, t - t0, vals.get(k, np.zeros(len(t)))) for k in ("headyaw", "headpitch", "headroll")], 1)
    take = {"fps": FPS, "names": names, "frames": frames, "head": np.round(head, 4).tolist(),
            "from": os.path.basename(a["--csv"]), "csv_fps": fps}
    json.dump(take, open(os.path.join(out, "take.json"), "w"))
    peaks = {e: round(float(np.max(c)), 2) for e, c in zip(names, cols)}
    print("arkit_take: %d frames at %d fps (%.1f s) from %d rows at %d fps" % (len(frames), FPS, len(frames) / FPS, len(t), fps))
    print("arkit_take: peaks", peaks)


if __name__ == "__main__":
    main()
