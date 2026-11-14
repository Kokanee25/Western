#!/usr/bin/env python3
"""The travelling band's cornet (#822): a B-flat cornet, the lead voice of every town and touring
band of the 1880s (Levy's and Arbuckle's day). Our own model from the physics, no copied code; it
plays a tune's melody from the same note data as the fiddle, banjo and piano.

    python3 experiments/sound_lab/fiddle/cornet.py yankee_doodle.json [--out=...wav]
    python3 experiments/sound_lab/fiddle/cornet.py --note=70 --vel=0.5 [--dur=1.5]   one note

**The lips:** the player's lips are a valve that the breath pushes open (an "outward-striking" valve):
one mass on a spring, its own resonance tuned by the player's lip tension near the note he wants,
pushed by the difference between his mouth's pressure and the mouthpiece's. The air through the
slit between them is the opening's area times the speed the pressure difference gives it (Bernoulli:
the root of the difference over the air's density). Ideas from Elliott & Bowsher (1982), Adachi &
Sato (1996, "Trumpet sound simulation using a two-dimensional lip vibration model") and Fletcher &
Rossing ("The Physics of Musical Instruments", ch. 14); the code is ours.

**The bore:** what the lips push into is the cornet's input impedance, a row of resonances, one a
"partial" of the tube (Bb3, F4, Bb4, D5, F5, ... on the open horn); its valves add tubing and lower
every resonance by 1, 2 or 3 semitones (1+3 and 1+2+3 a little sharp, as on every real valve
horn). Each resonance is a second-order filter from the lips' flow to the mouthpiece's pressure,
its height and width from a cornet's measured shape: peaks highest in the middle (the mouthpiece
cup's resonance near 850 Hz) and dying above the bell's cutoff (~1.3 kHz), where the bell lets the
sound out instead of reflecting it (a modal impedance, after Silva, Vergez et al. 2007's modal brass
models). The mouthpiece's pressure and the flow are solved together each sample in closed form
(the flow's square root and the filters' direct term make a quadratic), so the loop is stable.

**What you hear:** the bell passes the highs and holds back the lows (a high-pass on the mouthpiece
pressure, ~+12 dB an octave below the cutoff). The brass's "blare" at forte is the bore's own: a
loud wave's crests travel faster than its troughs (the air is hotter and moving), so each period's
front steepens on the way to the bell (Hirschberg et al. 1996, "Shock waves in trombones"); we warp
each period's time by its pressure (a cornet's bore is mostly conical, so it blares less than a
trumpet's: a short effective length). Breath noise rides on the flow.

**How he plays:** each note tongued (the tongue lets the breath in: the mouth's pressure rises in
~10 ms) or slurred (pressure held, the valves and lips change under it: the resonances move in a
few ms, the lip tension glides); the loudness by the breath (2.5 kPa soft to 9 kPa loud, more for
high notes); a band player's short lift between tongued notes; a slow vibrato only on long notes.
"""
import json
import math
import os
import sys

import numpy as np
from scipy.signal import butter, lfilter, resample_poly, sosfilt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

try:  # the other models use numba; the cornet runs without it (pure Python, ~1 s an audio second)
    from numba import njit
except ImportError:  # pragma: no cover
    def njit(*a, **k):
        return a[0] if a and callable(a[0]) else (lambda f: f)

HERE = os.path.dirname(os.path.abspath(__file__))
RHO = 1.2  # air, kg/m^3
C = 343.0
PEDAL = 116.54  # the open B-flat cornet's fundamental (Bb2)
# the open horn's resonances as multiples of PEDAL (the first well below: no note is played on it)
RATIOS = [0.74, 1.99, 3.0, 4.0, 5.0, 6.0, 6.95, 7.98, 8.96, 9.92, 10.9, 11.9, 12.9, 13.9]
# each valve combination: (semitones lower, cents sharp because added tubes don't add up exactly)
VALVES = {(): (0, 0.0), (2,): (1, 0.0), (1,): (2, 0.0), (1, 2): (3, 5.0), (2, 3): (4, 8.0),
          (1, 3): (5, 22.0), (1, 2, 3): (6, 35.0)}
LIP_B = 8e-3  # lip width (m)
LIP_MU = 1.5  # lip mass per area (kg/m^2)
LIP_Q = 5.0
LIP_X0 = 0.5e-4  # the lips' rest opening (m)
BORE_Q = 50.0
ZMAX = 4.2e7  # the bore's highest resonance peak (Pa s/m^3)
STEEP_L = 1.1  # m of the bore where the forte blare forms
KICK_X = 0.0  # where the tongue leaves the lips (m: closed)
KICK_V = 0.0  # and the buzz they start with (m of swing): the player sets it up before the tongue lets go
NOISE = 0.05  # the breath's hiss (it was 0.5: a hiss over every note, against VSCO's clean trumpet)
SETTLE = 0.08  # how much slacker his lips start a tongued note
START = 0.55  # the start transient's level against the breath's pressure
ATTACK = (0.1, 0.025)  # the tongue's push at a note's start: the breath's overshoot, and how fast it settles (s)
TUNING = os.path.join(HERE, "cornet_tuning.json")


def fingering(midi):
    """(valves, partial, cents the horn is off at that note) for a concert pitch, the commonest a
    cornetist uses: the partial and valves nearest in tune, open first."""
    best = None
    for valves, (low, sharp) in VALVES.items():
        for n in range(2, 10):
            if n == 7:
                continue  # the flat seventh partial, avoided
            m = 46.0 + 12.0 * math.log2(RATIOS[n - 1]) - low + sharp / 100.0
            err = abs(m - midi)
            if err < 0.5:
                cost = err + 0.02 * len(valves) + (0.05 if (1, 3) == valves or (1, 2, 3) == valves else 0)
                if best is None or cost < best[0]:
                    best = (cost, valves, n, (m - midi) * 100.0)
    if best is None:
        raise ValueError(f"midi {midi} is outside the cornet's range")
    return best[1], best[2], best[3]


def bore_modes(valves, shift=0.0):
    """The resonances (Hz), their peak impedances (Pa s/m^3) and Qs for a valve combination,
    `shift` cents (the note's tuning: see `calibrate`)."""
    low, sharp = VALVES[tuple(valves)]
    s = 2.0 ** ((-low + (sharp + shift) / 100.0) / 12.0)
    f = np.array(RATIOS) * PEDAL * s
    # height: the cup's resonance lifts the middle; the bell's cutoff lets the highs out
    cup = 1.0 / (1.0 + ((f - 850.0) / 700.0) ** 2) ** 0.5
    cut = 1.0 / (1.0 + (f / 1300.0) ** 6)
    low_roll = (f / 300.0) ** 2 / (1.0 + (f / 300.0) ** 2)
    z = ZMAX * (0.35 + 0.65 * cup) * cut * (0.4 + 0.6 * low_roll)
    q = BORE_Q * np.clip(np.sqrt(f / 400.0), 0.5, 1.6) * (0.35 + 0.65 * cut)
    z[0] *= 0.4  # the first resonance is weak and wide
    q[0] = 6.0
    return f, z, q


def coeffs(f, z, q, sr):
    """Each resonance as a bilinear filter, flow -> pressure, prewarped to its centre."""
    w = 2 * np.pi * f
    K = w / np.tan(w / (2 * sr))
    c = w / q
    a0 = K * K + c * K + w * w
    b0 = z * c * K / a0
    a1 = (2 * w * w - 2 * K * K) / a0
    a2 = (K * K - c * K + w * w) / a0
    return b0, a1, a2


@njit(cache=False)
def _run(pm, flip, fl, b0s, a1s, a2s, sr, seed, kick, puff):
    """The lips and bore, sample by sample. pm: mouth pressure (Pa); flip: the lips' resonance
    (Hz); fl: each sample's row of the resonances' coefficients b0s/a1s/a2s [sets, modes]; kick: a
    tongued start there; puff: the tongue's release puff (flow, m^3/s), added to the lips' flow.
    Returns the mouthpiece pressure and the flow."""
    n = pm.shape[0]
    m = b0s.shape[1]
    s1 = np.zeros(m)
    s2 = np.zeros(m)
    p_out = np.zeros(n)
    u_out = np.zeros(n)
    x = LIP_X0
    v = 0.0
    dt = 1.0 / sr
    k2r = math.sqrt(2.0 / RHO)
    for i in range(n):
        if kick[i]:  # the tongue: it held the lips shut; they open from closed with the breath behind them
            x = KICK_X
            v = KICK_V * 2.0 * math.pi * flip[i]
        row = fl[i]
        zd = 0.0
        ps = 0.0
        for j in range(m):
            zd += b0s[row, j]
            ps += s1[j]
        h = x if x > 0.0 else 0.0
        a = LIP_B * h * k2r
        d = pm[i] - ps - zd * puff[i]
        if a <= 0.0:
            u = 0.0
        else:
            a2 = a * a
            r = math.sqrt(a2 * a2 * zd * zd + 4.0 * a2 * abs(d))
            u = 0.5 * (r - a2 * zd)
            if d < 0.0:
                u = -u
        ut = u + puff[i]
        p = zd * ut + ps
        for j in range(m):
            y = b0s[row, j] * ut + s1[j]
            s1[j] = s2[j] - a1s[row, j] * y
            s2[j] = -b0s[row, j] * ut - a2s[row, j] * y
        dp = pm[i] - p
        wl = 2.0 * math.pi * flip[i]
        v += dt * (-(wl / LIP_Q) * v - wl * wl * (x - LIP_X0) + dp / LIP_MU)
        x += dt * v
        if x < -2e-4:  # the lips pressed together don't go further
            x = -2e-4
            v = 0.0
        p_out[i] = p
        u_out[i] = u
    return p_out, u_out


def _bell(p, u, sr, rng, vel_env):
    """The mouthpiece's pressure to the sound outside: the forte's steepening, the bell's high-pass,
    breath noise."""
    # steepening: each sample arrives earlier by its pressure (Lagrangian warp, 2x oversampled)
    up = resample_poly(p, 2, 1)
    srs = 2 * sr
    L = STEEP_L  # m of the bore's narrow, cylindrical part where the blare forms
    shift = L * 1.2 / (RHO * C ** 3) * up * srs  # samples
    t = np.arange(len(up)) - shift
    t = np.maximum.accumulate(t)
    warped = np.interp(np.arange(len(up)), t, up)
    p = resample_poly(warped, 1, 2)[:len(u)]
    sos = butter(2, 1300.0, "highpass", fs=sr, output="sos")
    y = sosfilt(sos, p) + 0.06 * p
    y = sosfilt(butter(2, 9000.0, "lowpass", fs=sr, output="sos"), y)
    # breath: turbulence in the jet, with the flow
    noise = rng.normal(0, 1, len(u))
    noise = sosfilt(butter(2, [1500.0, 7000.0], "bandpass", fs=sr, output="sos"), noise)
    y += noise * np.abs(u) / 1e-3 * 0.0025 * np.max(np.abs(y)) * NOISE
    return y


def breath(f_t, vel):
    """The mouth's pressure (Pa) for a note: 2.5 kPa soft to ~12 loud in the middle, more up high."""
    return (2500.0 + 9500.0 * vel ** 1.4) * (f_t / 350.0) ** 0.6 * (1.0 + max(0.0, f_t - 550.0) / 500.0)


def target(midi):
    """The pitch the player aims for (midi): the horn's own fault at that note, half lipped away."""
    valves, partial, off = fingering(midi)
    return midi + 0.5 * off / 100.0


def resonance(midi, shift=0.0):
    """The frequency (Hz) of the bore resonance a note is played on."""
    valves, partial, _ = fingering(midi)
    low, sharp = VALVES[tuple(valves)]
    return RATIOS[partial - 1] * PEDAL * 2.0 ** ((-low + (sharp + shift) / 100.0) / 12.0)


def _add_puff(puff, i0, midi, shift, pv, sr, tau=0.010):
    """The start transient: as the tongue lets go, a puff of air goes down the bore and comes back
    from the bell, starting the played resonance ringing at once (without it a note grows from rest
    over ~150 ms; a cornet speaks in ~20-50). A burst of flow at the resonance's pitch, a Hann
    window `tau` long, sized to bring the resonance to START of the breath's pressure."""
    valves, partial, _ = fingering(midi)
    f, z, q = bore_modes(valves, shift)
    j = partial - 1
    k = int(tau * sr)
    t = np.arange(k) / sr
    amp = START * pv / (z[j] * np.pi * f[j] * tau / q[j])
    seg = amp * np.sin(2 * np.pi * f[j] * t) * np.hanning(k)
    i1 = min(len(puff), i0 + k)
    puff[i0:i1] += seg[:i1 - i0]


def _sound(midi, ratio, vel, shift, sr=common.SR, dur=0.4):
    """One held note's pitch (cents off its target), or None if it doesn't speak there. The lips are
    tuned to `ratio` of the note's resonance."""
    valves, _, _ = fingering(midi)
    f_t = float(common.hz(target(midi)))
    pv = breath(f_t, vel)
    n = int(dur * sr)
    pm = np.full(n, pv)
    pm[:500] = np.linspace(0, pv, 500)
    s = coeffs(*bore_modes(valves, shift), sr)
    flip = np.full(n, resonance(midi, shift) * ratio)
    kick = np.zeros(n, dtype=np.int8)
    kick[0] = 1
    puff = np.zeros(n)
    _add_puff(puff, 0, midi, shift, pv, sr)
    p, _ = _run(pm, flip, np.zeros(n, dtype=np.int64), s[0][None], s[1][None], s[2][None], float(sr), 1, kick, puff)
    seg = p[int(0.7 * n):]
    seg = seg - seg.mean()
    if seg.std() < 0.05 * pv:
        return None
    a = np.correlate(seg, seg, "full")[len(seg) - 1:]
    # the period nearest the note's (within a fifth either way), refined by a parabola
    lo, hi = int(sr / (f_t * 1.5)), int(sr / (f_t / 1.5)) + 1
    k = lo + int(np.argmax(a[lo:hi]))
    if a[k] < 0.5 * a[0]:
        return None  # not periodic at the note: another regime
    if 0 < k < len(a) - 1:
        d = a[k - 1] - 2 * a[k] + a[k + 1]
        k = k + (0.5 * (a[k - 1] - a[k + 1]) / d if d != 0 else 0.0)
    c = 1200.0 * math.log2(sr / k / f_t)
    return c if abs(c) < 300 else None


VELS = (0.2, 0.5, 0.85)


def _calibrate_note(midi):
    """The lip tuning (a ratio of the note's resonance) that sounds the note soft, middling and loud
    with the least change of pitch, and the resonances moved so it sounds in tune at a middle
    loudness. A cornet's lips sound above the bore's resonance (an outward-striking valve), so a
    real horn's resonances sit a little under its notes; this places them."""
    best = None
    for ratio in np.arange(0.70, 1.02, 0.04 if midi < 74 else 0.02):
        c = _sound(midi, ratio, 0.5, 0.0)
        if c is None or not -20 < c < 180:  # another partial's: not this note (the lips sound above it)
            continue
        shift = -c
        cs = [_sound(midi, ratio, v, shift) for v in VELS]
        if any(x is None for x in cs):
            continue
        cost = abs(cs[1]) * 0.3 + (max(cs) - min(cs))
        if best is None or cost < best[0]:
            best = (cost, float(ratio), shift)
    if best is None:
        return midi, None
    ratio, shift = best[1], best[2]
    for _ in range(2):
        c = _sound(midi, ratio, 0.5, shift)
        if c is None:
            break
        shift -= c
    cs = [_sound(midi, ratio, v, shift) for v in VELS]
    return midi, {"ratio": round(ratio, 3), "shift": round(shift, 1), "cents": [None if x is None else round(x, 1) for x in cs]}


def calibrate(lo=54, hi=84, keep=False):
    """Each note's lip tuning and resonance placement into cornet_tuning.json (delete it after
    changing the model; `keep` keeps the notes outside lo..hi)."""
    from multiprocessing import Pool
    out = json.load(open(TUNING)) if keep and os.path.exists(TUNING) else {}
    with Pool(os.cpu_count() or 2) as pool:
        out.update(dict((str(m), r) for m, r in pool.map(_calibrate_note, range(lo, hi + 1)) if r is not None))
    out = dict(sorted(out.items(), key=lambda kv: int(kv[0])))
    json.dump(out, open(TUNING, "w"), indent=1)
    return out


def tuning():
    if not os.path.exists(TUNING):
        calibrate()
    return json.load(open(TUNING))


def render_part(part, sr=common.SR, seed=1882):
    """part: {"notes": [{t, dur, midi, vel, slur}], "length_s"}. Returns (the sound outside the bell,
    the mouthpiece pressure, the flow)."""
    rng = np.random.default_rng(seed)
    tun = tuning()
    n = int((part["length_s"] + 1.0) * sr)
    pm = np.zeros(n)
    flip = np.full(n, 300.0)
    fl = np.zeros(n, dtype=np.int64)
    kick = np.zeros(n, dtype=np.int8)
    puff = np.zeros(n)
    sets, key = [], {}
    notes = sorted(part["notes"], key=lambda q: q["t"])
    for k, nt in enumerate(notes):
        midi = nt["midi"]
        tn = tun[str(midi)]
        vel = float(np.clip(nt["vel"], 0.05, 1.0 if midi <= 80 else 0.7))  # the top notes won't hold loud
        # his ear: he lips a loud note's sharpness and a soft one's flatness half away
        shift = tn["shift"] - 0.5 * float(np.interp(vel, VELS, tn["cents"]))
        valves, _, _ = fingering(midi)
        sk = (tuple(valves), round(shift / 2.0))
        if sk not in key:
            key[sk] = len(sets)
            sets.append(coeffs(*bore_modes(valves, sk[1] * 2.0), sr))
        i0 = int(nt["t"] * sr)
        i1 = min(n, int((nt["t"] + nt["dur"]) * sr))
        nxt = notes[k + 1] if k + 1 < len(notes) else None
        slur_next = nxt is not None and nxt.get("slur") and abs(nxt["t"] - (nt["t"] + nt["dur"])) < 0.02
        slurred = bool(nt.get("slur")) and k > 0
        f_t = float(common.hz(target(midi)))
        base = breath(f_t, vel)
        L = i1 - i0
        tt = np.arange(L) / sr
        if slurred:
            rise = np.ones(L)
        else:
            # the tongue lets the breath in: up in ~10 ms, a push that settles in ~30
            rise = (0.5 - 0.5 * np.cos(np.pi * np.clip(tt / 0.005, 0, 1))) * (1.0 + ATTACK[0] * (0.5 + vel) * np.exp(-tt / ATTACK[1]))
            kick[i0] = 1
            _add_puff(puff, i0, midi, sk[1] * 2.0, START * base * (0.6 + 0.6 * vel) / START, sr)
        if slur_next:
            fall = np.ones(L)
        else:
            rel = min(0.04, 0.3 * nt["dur"])
            fall = np.clip((nt["dur"] - tt) / rel, 0, 1)
        swell = np.ones(L)
        if nt["dur"] > 0.6:  # a long note: a little swell, and a slow vibrato once it's settled
            vib = 0.02 * np.clip((tt - 0.3) / 0.3, 0, 1) * np.sin(2 * np.pi * 5.0 * tt + rng.uniform(0, 6))
            swell = 1.0 + vib + 0.05 * np.sin(np.pi * np.clip(tt / nt["dur"], 0, 1))
        # the breath is never quite steady: a slow wander of ~1%
        wander = np.cumsum(rng.normal(0, 1, L // 240 + 2))
        wander = 1.0 + 0.01 * np.interp(np.arange(L) / 240.0, np.arange(len(wander)), wander) / np.sqrt(len(wander))
        pm[i0:i1] = np.maximum(pm[i0:i1], base * rise * fall * swell * wander)
        lip = resonance(midi, sk[1] * 2.0) * tn["ratio"] * (1.0 + rng.normal(0, 0.004))
        if slurred:
            prev = flip[i0 - 1]
            g = np.clip(tt / 0.012, 0, 1)
            flip[i0:i1] = prev + (lip - prev) * g
        else:
            # he sets the lips a little slack for the attack (the puff and the tongue's push pull a
            # note sharp for its first ~100 ms) and firms them as it settles
            flip[i0:i1] = lip * (1.0 - SETTLE * np.exp(-tt / 0.06))
        j1 = min(n, i1 + int(0.08 * sr))
        flip[i1:j1] = lip
        fl[i0:j1] = key[sk]
    b0s = np.array([s[0] for s in sets])
    a1s = np.array([s[1] for s in sets])
    a2s = np.array([s[2] for s in sets])
    p, u = _run(pm, flip, fl, b0s, a1s, a2s, float(sr), seed, kick, puff)
    return _bell(p, u, sr, rng, None), p, u


def arrange(sc, lo=54, hi=83):
    """The cornet's part from a tune's melody: the tune's notes in the cornet's range (an octave
    moved if out of it), a march tongued and a little detached, a reel's running notes slurred in
    pairs (tongued on the beat), the strong notes louder."""
    mel = sorted([nt for nt in sc["notes"] if nt["voice"] == "melody"], key=lambda q: q["t"])
    march = "beats" in sc
    out = []
    for k, nt in enumerate(mel):
        m = nt["midi"]
        while m > hi:
            m -= 12
        while m < lo:
            m += 12
        nxt = mel[k + 1]["t"] if k + 1 < len(mel) else nt["t"] + nt["dur"]
        gap = nxt - nt["t"]
        u = nt.get("unit", 0.0)
        if march:
            dur = gap * (0.82 if gap < 0.4 else 0.9)
            slur = False
        else:
            slur = (u % 2) == 1 and k > 0 and abs(mel[k - 1]["t"] + mel[k - 1]["dur"] - nt["t"]) < 0.03
            dur = gap * 0.93 if not ((u % 2) == 0 and k + 1 < len(mel) and (mel[k + 1].get("unit", 0) % 2) == 1) else gap
        dur = min(dur, nt["dur"] * 1.05 if not march else gap)
        acc = nt.get("accent", 0.7)
        out.append({"t": round(nt["t"], 4), "dur": round(max(0.05, dur), 4), "midi": m,
                    "vel": round(0.5 + 0.3 * acc, 3), "slur": slur})
    # the last note held
    out[-1]["dur"] = round(out[-1]["dur"] + 0.6, 4)
    return {"notes": out, "length_s": out[-1]["t"] + out[-1]["dur"] + 0.3}


def main():
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if "note" in opt:
        dur = float(opt.get("dur", 1.5))
        part = {"notes": [{"t": 0.1, "dur": dur, "midi": int(opt["note"]), "vel": float(opt.get("vel", 0.6))}],
                "length_s": dur + 0.2}
        name = f"cornet_note_{opt['note']}_{opt.get('vel', '0.6')}"
    else:
        src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
        part = arrange(json.load(open(src)))
        name = os.path.splitext(os.path.basename(src))[0] + "_cornet"
    y, _, _ = render_part(part)
    out = opt.get("out", os.path.join(common.BUILD, "dry", name + ".wav"))
    common.write_wav(out, common.normalise(y))
    print(f"{out}: {len(y) / common.SR:.1f} s")


if __name__ == "__main__":
    main()
