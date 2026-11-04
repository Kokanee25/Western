#!/usr/bin/env python3
"""The train's sounds cut from real recordings (train sound 2, #586): every source on Wikimedia
Commons, every cut, in recordings.json beside this script; the game's files in assets/audio/train/.

    python3 -I experiments/train_lab/recordings.py fetch [DIR]   # sources into build/train_rec/src/
    python3 -I experiments/train_lab/recordings.py onsets KEY [FROM TO]   # beats found in a source
    python3 -I experiments/train_lab/recordings.py cut [ID ...]  # assets/audio/train/<id>.wav
    python3 -I experiments/train_lab/recordings.py credits       # CREDITS.md lines for the sources
    ... --manifest=PATH   another manifest (the dynamite's: experiments/sound_lab/blast_recordings.json,
                          #596): its "src_dir", "out" and "report" in place of the train's, a source's
                          "file" in place of its url's name

Every file is mono 16-bit at 44.1 kHz, as TrainSynth's (src/audio/train_synth.gd) and with its
rules (tests/test_train_sound.gd): a one-shot starts with LEAD (50 ms) of silence, then its onset;
a loop is seamless (its tail crossfaded into its head, equal power, then filtered round the circle,
so the seam has no step); nothing under ~40 Hz (a high-pass), nothing near full scale. Each is set
to the loudness the synthesised sound had (build/train_rec/synth/<id>.wav, written by
tools/train_synth_dump.gd), so TrainSound's dials keep their meaning, then by its cut's `db`.

Downloads are untrusted data: they go in build/train_rec/src/ and are only read by ffmpeg.
"""
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import wave

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
MANIFEST = os.path.join(HERE, "recordings.json")
SRC = os.path.join(ROOT, "build", "train_rec", "src")
SYNTH = os.path.join(ROOT, "build", "train_rec", "synth")
OUT = os.path.join(ROOT, "assets", "audio", "train")
REPORT = os.path.join(ROOT, "build", "train_rec", "cuts.json")
RATE = 44100
LEAD = 0.05
UA = "SaltCreekGame/0.1 (https://github.com/Kokanee25/western; sound research)"
PEAK = 0.89  # the loudest sample a file may have (the test allows up to 32700 of 32767)
# Each file's import (Godot fills in the rest): kept 16-bit PCM, mono, untrimmed, unlooped (TrainSynth
# sets the loop), so the game plays exactly these samples and the tests read them.
IMPORT = """[remap]

importer="wav"
type="AudioStreamWAV"

[params]

force/8_bit=false
force/mono=true
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode=0
edit/loop_begin=0
edit/loop_end=-1
compress/mode=0
"""


def manifest():
    return json.load(open(MANIFEST))


def _use_manifest(path):
    """Point the cutter at another manifest: its own sources, output folder and report."""
    global MANIFEST, SRC, OUT, REPORT
    MANIFEST = os.path.abspath(path)
    m = manifest()
    SRC = os.path.join(ROOT, m.get("src_dir", os.path.relpath(SRC, ROOT)))
    OUT = os.path.join(ROOT, m.get("out", os.path.relpath(OUT, ROOT)))
    REPORT = os.path.join(ROOT, m.get("report", os.path.relpath(REPORT, ROOT)))


def src_path(key, m):
    s = m["sources"][key]
    if s.get("file"):
        return os.path.join(SRC, s["file"])
    ext = os.path.splitext(urllib.parse.urlparse(s["url"]).path)[1].lower()
    return os.path.join(SRC, key + ext)


def fetch(to=None):
    """Each source not yet in `to` (build/train_rec/src/), downloaded politely: when Wikimedia
    answers 429 it waits as long as it's told, once a minute at most."""
    m = manifest()
    to = to or SRC
    os.makedirs(to, exist_ok=True)
    open(os.path.join(to, ".gdignore"), "w").close()  # not the game's: Godot leaves them alone
    for key, s in m["sources"].items():
        path = os.path.join(to, os.path.basename(src_path(key, m)))
        if os.path.exists(path):
            continue
        url = s["url"].split("?")[0]
        for attempt in range(30):  # Wikimedia limits a shared address hard: wait as long as it asks
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            try:
                with urllib.request.urlopen(req, timeout=120) as r, open(path + ".part", "wb") as f:
                    f.write(r.read())
                break
            except urllib.error.HTTPError as e:
                if e.code != 429:
                    raise
                time.sleep(max(60, int(e.headers.get("retry-after", "10") or 10)))
        os.replace(path + ".part", path)
        print("fetched", key, os.path.getsize(path), "after", attempt, "waits", flush=True)
        time.sleep(3)


def decode(path, channel=None):
    """Mono float32 at RATE (a stereo file's channels averaged, or one of them)."""
    args = ["ffmpeg", "-v", "error", "-i", path]
    if channel is not None:
        args += ["-af", "pan=mono|c0=c%d" % channel]
    args += ["-ac", "1", "-ar", str(RATE), "-f", "f32le", "-"]
    raw = subprocess.run(args, check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)


def envelope(x, win=0.01):
    n = int(RATE * win)
    e = np.sqrt(np.convolve(x * x, np.ones(n) / n, mode="same"))
    return e


def onsets(key, t0=0.0, t1=None):
    """The beats in a stretch of a source: where the 10 ms envelope rises past its slow mean by a
    margin, at least 80 ms apart. Prints each with its rise and peak, to choose the cuts by."""
    m = manifest()
    x = decode(src_path(key, m))
    t1 = len(x) / RATE if t1 is None else t1
    seg = x[int(t0 * RATE):int(t1 * RATE)]
    seg = highpass(seg, 60.0)
    e = envelope(seg)
    slow = np.convolve(e, np.ones(int(RATE * 0.4)) / int(RATE * 0.4), mode="same")
    edb = 20 * np.log10(e + 1e-9)
    sdb = 20 * np.log10(slow + 1e-9)
    hop = int(RATE * 0.005)
    last = -1e9
    print("%s %.2f-%.2f s, rms %.1f dB" % (key, t0, t1, 20 * np.log10(np.sqrt(np.mean(seg ** 2)) + 1e-9)))
    for i in range(hop, len(seg) - hop, hop):
        rise = edb[i] - edb[i - hop * 4] if i >= hop * 4 else 0.0
        if edb[i] - sdb[i] > 3.0 and rise > 4.0 and i - last > RATE * 0.08:
            pk = edb[i:i + int(RATE * 0.08)].max()
            print("  %.3f s  rise %.1f dB  peak %.1f dB" % (t0 + i / RATE, rise, pk))
            last = i


def highpass(x, hz, circular=False):
    """Zero-phase high-pass by the FFT (a smooth step from hz/2 to hz). `circular` filters a loop
    round its seam (no padding), so it stays seamless."""
    n = len(x)
    if not circular:
        pad = int(RATE * 0.5)
        y = np.concatenate([x, np.zeros(pad)])
    else:
        y = x
    f = np.fft.rfft(y)
    fr = np.fft.rfftfreq(len(y), 1.0 / RATE)
    g = np.clip((fr - hz * 0.5) / (hz * 0.5), 0.0, 1.0)
    g = 0.5 - 0.5 * np.cos(np.pi * g)
    out = np.fft.irfft(f * g, len(y))
    return out[:n]


def lowpass(x, hz, circular=False):
    n = len(x)
    y = x if circular else np.concatenate([x, np.zeros(int(RATE * 0.5))])
    f = np.fft.rfft(y)
    fr = np.fft.rfftfreq(len(y), 1.0 / RATE)
    g = np.clip((hz * 1.5 - fr) / (hz * 0.5), 0.0, 1.0)
    g = 0.5 - 0.5 * np.cos(np.pi * g)
    return np.fft.irfft(f * g, len(y))[:n]


def stft(x, n=2048, hop=512):
    w = np.hanning(n)
    pad = np.concatenate([np.zeros(n), x, np.zeros(n)])
    frames = [np.fft.rfft(pad[i:i + n] * w) for i in range(0, len(pad) - n, hop)]
    return np.array(frames)


def istft(F, length, n=2048, hop=512):
    w = np.hanning(n)
    out = np.zeros(hop * len(F) + n)
    norm = np.zeros_like(out)
    for k, f in enumerate(F):
        out[k * hop:k * hop + n] += np.fft.irfft(f, n) * w
        norm[k * hop:k * hop + n] += w * w
    out /= np.maximum(norm, 1e-6)
    return out[n:n + length]


def denoise(x, profile_from, amount):
    """The recording's steady background taken out (spectral subtraction, after S. Boll 1979): its
    level in each frequency is the median over `profile_from` (a stretch of the same source: the
    steady part, a machine's hum, stays under every frame; a beat is over the median), and
    `amount` times that comes off each frame's magnitude, never below a tenth of it (a floor
    against the warble bare subtraction leaves). Phases kept."""
    a, b = int(profile_from[0] * RATE), int(profile_from[1] * RATE)
    prof = np.median(np.abs(stft(x[a:b])), axis=0)
    F = stft(x)
    mag = np.abs(F)
    keep = np.maximum(mag - amount * prof, 0.1 * mag)
    return istft(F * (keep / np.maximum(mag, 1e-12)), len(x))


def fade(n, kind):
    t = np.linspace(0.0, 1.0, n)
    return np.sin(t * np.pi / 2) if kind == "in" else np.cos(t * np.pi / 2)


def one_shot(x, c):
    """From `at` for `len` s: a short fade in, a fade out over `tail`, then led by LEAD of silence."""
    a, n = int(c["at"] * RATE), int(c["len"] * RATE)
    s = x[a:a + n].copy()
    fi = int(RATE * c.get("fade_in", 0.002))
    fo = int(RATE * c.get("tail", min(0.25, c["len"] * 0.4)))
    s[:fi] *= fade(fi, "in")
    s[-fo:] *= fade(fo, "out") ** 2
    if c.get("decay"):  # a burst made from a steady sound: up in `fade_in`, then down by `decay` s
        s *= np.exp(-np.arange(len(s)) / (RATE * c["decay"]))
    return s


def loop(x, c):
    """`len` s from `at`, its last `xfade` s crossfaded (equal power) with the `xfade` s before
    `at`, so the end runs on into the start."""
    a, n = int(c["at"] * RATE), int(c["len"] * RATE)
    f = int(RATE * c.get("xfade", 0.5))
    if a < f:
        raise SystemExit("%s: a loop needs %.2f s before its start" % (c["id"], f / RATE))
    s = x[a:a + n].copy()
    pre = x[a - f:a]
    s[n - f:] = s[n - f:] * fade(f, "out") + pre * fade(f, "in")
    return s


def shape(s, c, circular):
    s = highpass(s, c.get("hp", 60.0), circular)
    if c.get("lp"):
        s = lowpass(s, c["lp"], circular)
    if circular:
        s = s - s.mean()
    return s


def rms_loud(s):
    """The RMS of the loudest half of its 50 ms windows (a one-shot's body, not its silence)."""
    w = int(RATE * 0.05)
    k = max(1, len(s) // w)
    r = np.sqrt(np.mean(s[:k * w].reshape(k, w) ** 2, axis=1))
    r = np.sort(r)[k // 2:]
    return float(np.sqrt(np.mean(r ** 2)))


def read_wav(path):
    with wave.open(path) as w:
        a = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32767.0
    return a


def write_wav(path, s):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((np.clip(s, -1.0, 1.0) * 32767.0).astype(np.int16).tobytes())


def cut(only):
    m = manifest()
    os.makedirs(OUT, exist_ok=True)
    cache = {}
    report = {}
    for c in m["cuts"]:
        if only and c["id"] not in only:
            continue
        key = (c["src"], c.get("channel"))
        if key not in cache:
            cache[key] = decode(src_path(c["src"], m), c.get("channel"))
        x = cache[key]
        if c.get("denoise"):  # only the stretch around the cut, worked on its own
            d = c["denoise"]
            lo = int(min(d["from"][0], c["at"] - c.get("xfade", 0.0) - 0.2) * RATE)
            hi = int(max(d["from"][1], c["at"] + c["len"] + 0.2) * RATE)
            x = x.copy()
            x[lo:hi] = denoise(x[lo:hi], (d["from"][0] - lo / RATE, d["from"][1] - lo / RATE), d.get("amount", 1.5))
        is_loop = c["kind"] == "loop"
        s = loop(x, c) if is_loop else one_shot(x, c)
        s = shape(s, c, is_loop)
        if not is_loop:
            fo = int(RATE * 0.01)
            s[-fo:] *= fade(fo, "out")
        # Its loudness: the synthesised sound's, then the cut's own `db`.
        target = None
        sp = os.path.join(SYNTH, c["id"] + ".wav")
        if os.path.exists(sp):
            target = rms_loud(read_wav(sp))
        gain = (target / max(rms_loud(s), 1e-9) if target else 0.25 / max(rms_loud(s), 1e-9))
        gain *= 10 ** (c.get("db", 0.0) / 20.0)
        s = s * gain
        pk = float(np.abs(s).max())
        if pk > PEAK:  # held under full scale (the dials take up any difference)
            s *= PEAK / pk
        if not is_loop:
            s = np.concatenate([np.zeros(int(RATE * LEAD)), s])
            s[int(RATE * LEAD)] = s[int(RATE * LEAD)] or 1e-4
        dest = os.path.join(OUT, c["id"] + ".wav")
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        write_wav(dest, s)
        imp = dest + ".import"
        if not os.path.exists(imp):  # PCM, as it is: Godot's default squeezes it (QOA)
            open(imp, "w").write(IMPORT)
        report[c["id"]] = {"s": round(len(s) / RATE, 3), "rms_db": round(20 * np.log10(rms_loud(s) + 1e-9), 1),
                           "synth_rms_db": round(20 * np.log10(target), 1) if target else None,
                           "peak_db": round(20 * np.log10(np.abs(s).max() + 1e-9), 1)}
        print("%-22s %5.2f s  rms %6.1f dB (synth %s)  peak %5.1f dB" % (
            c["id"], report[c["id"]]["s"], report[c["id"]]["rms_db"], report[c["id"]]["synth_rms_db"],
            report[c["id"]]["peak_db"]))
    if not only:
        os.makedirs(os.path.dirname(REPORT), exist_ok=True)
        json.dump(report, open(REPORT, "w"), indent=1)


def credits():
    m = manifest()
    for key, s in m["sources"].items():
        print("- **%s** by %s, %s (%s): %s. Cut into `%s`." % (
            s["title"], s["author"], s["licence"], s["page"], s.get("note", ""),
            "`, `".join(c["id"] for c in m["cuts"] if c["src"] == key)))


if __name__ == "__main__":
    for a in [a for a in sys.argv[1:] if a.startswith("--manifest=")]:
        _use_manifest(a.split("=", 1)[1])
        sys.argv.remove(a)
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "fetch":
        fetch(sys.argv[2] if len(sys.argv) > 2 else None)
    elif cmd == "onsets":
        a = sys.argv[2:]
        onsets(a[0], float(a[1]) if len(a) > 1 else 0.0, float(a[2]) if len(a) > 2 else None)
    elif cmd == "cut":
        cut(set(sys.argv[2:]))
    elif cmd == "credits":
        credits()
    else:
        print(__doc__)
