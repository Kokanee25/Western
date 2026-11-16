#!/usr/bin/env python3
"""A song arranged by sections (Sean, 2026-11-15: "a real banger ... something they would stomp their feet to"):
each player renders the whole song once from its note data, then comes in and drops out by the bars a
sections file gives (an intro of the stomp and the hook, the band in for the verse, everyone on the
chorus, a breakdown to the stomp and claps), each section's edges a short fade on the bar line.

    python3 experiments/sound_lab/fiddle/sections.py stomp_the_boards.json tunes/stomp_the_boards.sections.json
        [--levels=fiddle:0,guitar:-3,banjo:-4,bass:-2,drums:-2] [--out=...wav]

The players: fiddle (bowed.py), guitar (the driving strum), banjo (modern open-back, three-finger rolls),
bass (every beat), drums (four on the floor, hand claps on two and four). Each is rendered to build/ once
and reused while the mix is tuned (delete build/sound_lab/fiddle/parts/<song>_* to render again).
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import banjo  # noqa: E402
import bass  # noqa: E402
import bowed  # noqa: E402
import common  # noqa: E402
import drums  # noqa: E402
import guitar  # noqa: E402
import rhythm  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
LEVELS = {"fiddle": 0.0, "guitar": -3.0, "banjo": -4.0, "bass": -2.0, "drums": -2.0}
EDGE = 0.02   # s: each section's fade on the bar line
DRUM_CLAPS = True
DRUM_STYLE = "four"   # the plan's drum_style: "four" the kick on every beat, "stomp" boom-chick (1 and 3)
# --live: where each player stands (-1 left, +1 right), the crowd, the room, the mix pushed up loud
PAN = {"fiddle": -0.1, "guitar": -0.55, "banjo": 0.55, "bass": 0.0, "drums": 0.05}
LIVE_LUFS = -10.0


def part(name, sc):
    if name == "fiddle":
        return bowed.render(sc)
    if name == "guitar":
        guitar.STYLE = "drive"
        return guitar.render(guitar.arrange(sc))
    if name == "banjo":
        banjo.strings("modern")
        return banjo.render(banjo.arrange_rolls(sc))
    if name == "bass":
        bass.STYLE = "drive"
        return bass.render(bass.arrange(sc))
    if name == "drums":
        drums.STYLE, drums.CLAP = DRUM_STYLE, DRUM_CLAPS
        return drums.render(drums.arrange(sc))
    raise ValueError(name)


def crowd_clap(sr, rng, people=28):
    """A crowd's clap on one beat: each person's clap (drums._clap), a little early or late (s.d. ~22 ms),
    some harder than others."""
    n = int(0.35 * sr)
    y = np.zeros(n)
    for _ in range(people):
        c = drums._clap(sr, rng, rng.uniform(0.4, 1.0))
        d = int(np.clip(rng.normal(0.03, 0.022), 0, 0.08) * sr)
        seg = y[d:d + len(c)]
        seg += c[:len(seg)]
    return y / (np.max(np.abs(y)) + 1e-12)


def roar(sr, rng, seconds):
    """A crowd's cheer: many voices as noise in the voice's band (300 Hz-4 kHz), each voice's level
    wandering a few times a second."""
    n = int(seconds * sr)
    from scipy.signal import butter, lfilter
    y = lfilter(*butter(2, [300 / (sr / 2), 4000 / (sr / 2)], "band"), rng.standard_normal(n))
    wob = lfilter(*butter(1, 6 / (sr / 2)), rng.standard_normal(n))
    y *= 1 + 0.5 * wob / (np.std(wob) + 1e-12)
    return y / (np.max(np.abs(y)) + 1e-12)


def applause(sr, rng, seconds=5.0):
    """Applause: claps at random (a few hundred people, ~60 a second at first), thinning out."""
    n = int(seconds * sr)
    y = np.zeros(n)
    t = 0.0
    while t < seconds - 0.3:
        rate = 60 * np.exp(-t / 2.0) + 4
        t += rng.exponential(1 / rate)
        c = drums._clap(sr, rng, rng.uniform(0.3, 1.0) * np.exp(-t / 2.5))
        i = int(t * sr)
        seg = y[i:i + len(c)]
        seg += c[:len(seg)]
    return y / (np.max(np.abs(y)) + 1e-12)


def room_ir(sr, rng, rt60=1.4):
    """A hall's sound: a few early reflections, then a diffuse tail that dies over rt60 and darkens as it
    goes (the highs gone sooner). Two channels, unalike, for width."""
    from scipy.signal import butter, lfilter
    n = int(rt60 * sr)
    t = np.arange(n) / sr
    out = []
    for _ in range(2):
        nz = rng.standard_normal(n)
        lo = lfilter(*butter(2, 2500 / (sr / 2)), nz)
        ir = lo * np.exp(-6.91 * t / rt60) + 0.5 * nz * np.exp(-6.91 * t / (0.4 * rt60))
        ir[:int(0.012 * sr)] = 0
        for d, g in ((0.011, 0.7), (0.019, 0.5), (0.027, 0.45), (0.041, 0.35)):
            ir[int(rng.uniform(0.85, 1.15) * d * sr)] += g * rng.choice([-1, 1])
        out.append(ir / np.sqrt(np.sum(ir ** 2)))
    return out


def glue_and_limit(x, sr, target):
    """The live engineer's bus: a slow compressor that pulls the band together (3:1 over the louder
    passages, 10 ms attack, 150 ms release), up to the target loudness, then a peak limiter (5 ms look
    ahead) holding everything under -1 dBFS."""
    from scipy.signal import lfilter
    level = np.sqrt(lfilter([0.002], [1, -0.998], np.mean(x ** 2, axis=1)) + 1e-12)  # ~10 ms RMS
    thr = np.percentile(level, 60)
    over = np.maximum(level / thr, 1.0)
    gain = over ** (1 / 3 - 1)
    a_att, a_rel = np.exp(-1 / (0.01 * sr)), np.exp(-1 / (0.15 * sr))
    g = np.empty_like(gain)
    cur = 1.0
    for i, v in enumerate(gain):  # attack fast down, release slow up
        cur = a_att * cur + (1 - a_att) * v if v < cur else a_rel * cur + (1 - a_rel) * v
        g[i] = cur
    y = x * g[:, None]
    # then saturation, as a desk and its tape do when pushed: the peaks rounded off (tanh), so the
    # whole can sit louder; the drive set until the loudness reaches the target
    for _ in range(4):
        y *= 10 ** ((target - common.loudness(y.mean(axis=1), sr)) / 20)
        y = np.tanh(1.1 * y) / 1.1
    ceil = 10 ** (-1 / 20)
    y *= min(10 ** ((target - common.loudness(y.mean(axis=1), sr)) / 20), ceil / np.max(np.abs(y)))
    peak = np.max(np.abs(y), axis=1)
    need = np.minimum(1.0, ceil / (peak + 1e-12))
    la = int(0.005 * sr)
    from scipy.ndimage import minimum_filter1d
    need = minimum_filter1d(need, size=2 * la + 1)
    sm = np.empty_like(need)
    cur = 1.0
    a_rel = np.exp(-1 / (0.08 * sr))
    for i, v in enumerate(need):
        cur = v if v < cur else a_rel * cur + (1 - a_rel) * v
        sm[i] = cur
    return y * sm[:, None]


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    planf = json.load(open(args[1] if os.path.isabs(args[1]) else os.path.join(HERE, args[1])))
    plan = planf["sections"]
    global DRUM_CLAPS, DRUM_STYLE
    DRUM_CLAPS = planf.get("drum_claps", True)
    DRUM_STYLE = planf.get("drum_style", "four")
    for kv in filter(None, opt.get("levels", "").split(",")):
        k, v = kv.split(":")
        LEVELS[k] = float(v)
    name = os.path.splitext(os.path.basename(src))[0]
    cache = os.path.join(common.BUILD, "parts")
    os.makedirs(cache, exist_ok=True)
    when, _, _, _ = rhythm.grid(sc)
    starts = sc["bar_units"]
    sr = common.SR
    players = sorted({p for s in plan for p in s["players"]})
    parts = {}
    for p in players:
        path = os.path.join(cache, f"{name}_{p}.wav")
        if not os.path.exists(path):
            common.write_wav(path, common.normalise(part(p, sc)))
            print(f"rendered {p}")
        parts[p] = common.read_wav(path)[1]
    n = max(len(x) for x in parts.values())
    mix = np.zeros(n)
    for p, x in parts.items():
        gate = np.zeros(n)
        for s in plan:
            if p not in s["players"]:
                continue
            b0, b1 = s["bars"]
            t0 = when(starts[b0]) - 0.03  # a stroke can land a hair before the bar
            last = b1 >= len(starts)
            t1 = n / sr if last else when(starts[b1]) - 0.03
            i0, i1 = max(0, int(t0 * sr)), min(n, int(t1 * sr))
            gate[i0:i1] = 1.0
        # the edges: a short fade, so a player comes in and drops out on the bar line, cleanly
        k = int(EDGE * sr)
        ramp = np.convolve(gate, np.ones(k) / k, mode="same")
        mix[:len(x)] += x * ramp[:len(x)] * 10 ** (LEVELS.get(p, 0.0) / 20)
    if "--live" in sys.argv:
        return live(sc, planf, parts, when, starts, name, opt, sr, n)
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_sections.wav"))
    y = common.normalise(mix)
    common.write_wav(out, y)
    print(f"{out}: {sc['tune']}, {len(plan)} sections, {', '.join(players)}, {n / sr:.1f} s, peak {np.max(np.abs(y)):.2f}")



def live(sc, planf, parts, when, starts, name, opt, sr, n):
    """The live show: each player gated by its sections as in the plain mix, placed left to right, the
    crowd clapping along where a section says so (joining over its first bar), a cheer swelling into the
    plan's cheer_bar, applause at the end, the hall's reverb, the bus pushed up loud."""
    import scipy.io.wavfile as wavfile
    from scipy.signal import fftconvolve
    rng = np.random.default_rng(1880)
    plan = planf["sections"]
    tail = 6.0
    N = n + int(tail * sr)
    L, R = np.zeros(N), np.zeros(N)
    k = int(EDGE * sr)
    for p, x in parts.items():
        gate = np.zeros(n)
        for s in plan:
            if p in s["players"]:
                b0, b1 = s["bars"]
                t0 = when(starts[b0]) - 0.03
                t1 = n / sr if b1 >= len(starts) else when(starts[b1]) - 0.03
                gate[max(0, int(t0 * sr)):min(n, int(t1 * sr))] = 1.0
        ramp = np.convolve(gate, np.ones(k) / k, mode="same")
        y = x * ramp[:len(x)] * 10 ** (LEVELS.get(p, 0.0) / 20)
        th = (PAN.get(p, 0.0) + 1) * np.pi / 4
        L[:len(y)] += np.cos(th) * y
        R[:len(y)] += np.sin(th) * y
    band_rms = np.std(np.concatenate([L, R]))
    # the crowd's hands on two and four, joining in over a section's first bar
    claps = [crowd_clap(sr, rng) for _ in range(8)]
    cl_l, cl_r = np.zeros(N), np.zeros(N)
    for s in plan:
        if not s.get("crowd"):
            continue
        b0, b1 = s["bars"]
        for b in range(b0, min(b1, len(starts))):
            for q in (1, 3):
                t = when(starts[b] + 2 * q)
                join = min(1.0, 0.35 + 0.65 * (b - b0 + q / 4))
                for ch in (cl_l, cl_r):
                    c = claps[rng.integers(len(claps))]
                    i = int((t + rng.normal(0, 0.006)) * sr)
                    seg = ch[i:i + len(c)]
                    seg += join * c[:len(seg)]
    g = 0.45 * band_rms / (np.std(cl_l[cl_l != 0]) + 1e-12) if np.any(cl_l) else 0
    L += g * cl_l
    R += g * cl_r
    # the cheer into the last chorus, and at the end the cheer and applause
    cb = planf.get("cheer_bar")
    if cb is not None and cb < len(starts):
        t = when(starts[cb])
        for ch in (L, R):
            r = roar(sr, rng, 6.0)
            env = np.interp(np.arange(len(r)) / sr, [0, 1.8, 2.3, 6.0], [0, 1, 0.8, 0])
            i = int((t - 2.0) * sr)
            seg = ch[i:i + len(r)]
            seg += 0.25 * band_rms * (r * env)[:len(seg)] / (np.std(r) + 1e-12)
    # (the crowd's clapping, along or at the end, is off unless the plan asks: Sean, 2026-11-16, "the
    # clap sounds horrible"; the cheer carries the end)
    end = n / sr - 2.0
    for ch in (L, R):
        r = roar(sr, rng, tail + 1.0)
        env = np.interp(np.arange(len(r)) / sr, [0, 0.3, 2.5, tail + 1.0], [0, 1, 0.6, 0])
        i = int(end * sr)
        seg = ch[i:i + len(r)]
        x = 0.45 * band_rms * r * env / (np.std(r) + 1e-12)
        if planf.get("applause"):
            a = applause(sr, rng, tail + 1.0)
            x = x + 0.5 * band_rms * a / (np.std(a) + 1e-12)
        seg += x[:len(seg)]
    # the hall
    irl, irr = room_ir(sr, rng)
    wet = 10 ** (-13 / 20)
    L2 = L + wet * fftconvolve(L, irl)[:N]
    R2 = R + wet * fftconvolve(R, irr)[:N]
    y = glue_and_limit(np.stack([L2, R2], axis=1), sr, LIVE_LUFS)
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_live.wav"))
    wavfile.write(out, sr, (np.clip(y, -1, 1) * 32767).astype(np.int16))
    print(f"{out}: {sc['tune']}, live: {N / sr:.1f} s stereo, {common.loudness(y.mean(axis=1), sr):.1f} LUFS, "
          f"peak {20 * np.log10(np.max(np.abs(y))):.1f} dBFS")


if __name__ == "__main__":
    main()
