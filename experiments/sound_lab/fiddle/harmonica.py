#!/usr/bin/env python3
"""The harmonica (#790): the cowhand's pocket instrument, a ten-hole diatonic in Richter tuning
(Hohner made them by the hundred thousand from 1857). Our own model from the physics, no copied
code; it plays a tune's melody from the same note data as the fiddle and banjo.

    python3 experiments/sound_lab/fiddle/harmonica.py red_river_valley.json [--out=...wav]

**The instrument:** each hole has two brass reeds, one sounding on the blow and one on the draw;
a harp is made in a key (G, D, ...). Richter's layout gives the tonic chord blowing and the dominant
drawing, and the full scale only in the middle holes (4-7), so a tune is played there. The blow
chord's third and fifth are tuned just (sweet chords), as harps were.

**The sound (the model):** a free reed sounds by chopping the breath. The reed swings in and out
of its slot; while it's inside, only a hair's clearance leaks; out of the slot, the opening grows
with how far it's out. The air through it is that opening times the breath's speed (Bernoulli: the
root of the mouth's pressure), and what we hear is that pulsing flow's rate of change (a small
source radiating like a monopole). The sharp corner where the reed clears the slot edge is the
harmonica's buzz. Around it: the reed starts by growing from rest over a few tens of ms (it is a
self-starting oscillator) and blows a touch flat when pushed hard; breath turbulence hisses with
the flow; the player's mouth shapes it and his cupped hands muffle it, opening for the long notes
and fluttering in a hand tremolo on them. Ideas from Johnston (1987) and Millot & Baumann (2007) on
free reeds; the code is ours.

**How he plays:** the melody single-note, tongue blocking (the tongue covers the holes to the
left); on the strong notes he lifts the tongue for a moment, a chord slap from the holes beside;
on long notes a soft chord under it and the hand tremolo. Notes on the same breath slur, sliding
across the holes between (they sound for a moment: the harmonica's own smear); a change of breath
direction is a short break; a repeated note is tongued. Missing notes in the low holes are bent
down on the draw (the mouth's resonance pulls the reed flat), with a scoop.
"""
import json
import os
import sys

import numpy as np
from scipy.signal import butter, lfilter, resample_poly

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OVER = 4                       # the reed's corner makes harmonics all the way up: run at 192 kHz
BLOW = [0, 4, 7, 12, 16, 19, 24, 28, 31, 36]   # Richter, semitones over hole 1's blow
DRAW = [2, 7, 11, 14, 17, 21, 23, 26, 29, 33]
HOLE1 = {"C": 60, "D": 62, "G": 55, "A": 57}   # hole 1 blow, each harp's key
JUST = {0: 0.0, 4: -13.7, 7: 2.0}              # the blow chord, tuned just (cents by degree)
NAMES = {0: "C", 2: "D", 7: "G", 9: "A"}
X_REST = 0.25                  # the reed's set: how far it sits out of the slot at rest (of its swing)
EDGE = 0.07                    # how gradually the reed's tip clears the slot (of its swing)
LEAK = 0.03                    # the clearance round a reed inside its slot


def harp_for(sc):
    mel = [n for n in sc["notes"] if n["voice"] == "melody"]
    return NAMES.get(mel[-1]["midi"] % 12, "C")


def reeds(key, seed=1857):
    """Every reed: (hole 1-10, 'blow'|'draw', midi, cents off true)."""
    rng = np.random.default_rng(seed)
    out = []
    for h in range(10):
        for d, row in (("blow", BLOW), ("draw", DRAW)):
            semis = row[h]
            cents = JUST.get(semis % 12, 0.0) if d == "blow" else 0.0
            out.append((h + 1, d, HOLE1[key] + semis, cents + rng.normal(0, 3.0)))
    return out


def arrange(sc, seed=1857):
    """The harmonica's part: each melody note on a reed (or a bent draw), the octave that keeps
    the tune in holes 4-7, chords where he slaps or holds. Voices {t0, t1, hole, dir, midi, cents,
    amp, role, scoop}."""
    rng = np.random.default_rng(seed)
    key = harp_for(sc)
    rd = reeds(key, seed)
    straight = {}
    for h, d, m, c in rd:
        straight.setdefault(m, (h, d, c))
    mel = sorted([n for n in sc["notes"] if n["voice"] == "melody"], key=lambda n: n["t"])

    def fits(shift):  # notes on a straight reed in holes 4-8, then anywhere
        return (sum(1 for n in mel if n["midi"] + shift in straight and 4 <= straight[n["midi"] + shift][0] <= 8),
                sum(1 for n in mel if n["midi"] + shift in straight))
    shift = max((-24, -12, 0, 12, 24), key=fits)
    voices = []
    for k, n in enumerate(mel):
        m = n["midi"] + shift
        scoop = 0.0
        if m in straight:
            h, d, c = straight[m]
        else:
            # bent: a draw reed one or two semitones above, in holes 1-4 (bent flat by the mouth)
            cand = [(h, dd, mm, cc) for h, dd, mm, cc in rd if dd == "draw" and h <= 4 and 1 <= mm - m <= 2]
            if cand:
                h, d, mm, c = cand[0]
                c += (m - mm) * 100.0
                scoop = 60.0
            else:
                m2 = m + 12 if m + 12 in straight else m - 12
                h, d, c = straight.get(m2, straight[min(straight, key=lambda x: abs(x - m))])
                m = m2
        t0 = n["t"] + rng.normal(0, 0.006)
        nxt = mel[k + 1]["t"] if k + 1 < len(mel) else n["t"] + n["dur"] + 0.4
        t1 = min(n["t"] + max(n["dur"], 0.08), nxt)  # legato: he holds to the next note
        if nxt - (n["t"] + n["dur"]) < 0.12:
            t1 = nxt
        voices.append({"t0": round(t0, 4), "t1": round(t1, 4), "hole": h, "dir": d, "midi": m, "cents": round(c, 1),
                       "amp": round(float(0.75 + 0.25 * n.get("accent", 0.7)), 3), "role": "melody", "scoop": scoop,
                       "long": n["dur"] >= 0.9})
    # on one breath the air is already flowing: the next reed speaks at once, and the last one goes on
    # until the mouth is off its hole (they overlap); a change of breath or a gap starts afresh
    for a, b in zip(voices, voices[1:]):
        b["flowing"] = a["dir"] == b["dir"] and b["t0"] - a["t1"] < 0.03
        if b["flowing"] and a["hole"] != b["hole"]:
            a["t1"] = round(a["t1"] + 0.018, 4)
    # the last note held and let go slowly
    voices[-1]["t1"] = round(voices[-1]["t1"] + 0.8, 4)
    voices[-1]["long"] = True
    # chords: the holes just left of the melody's, on the same breath (blow: the tonic; draw 1-4: the
    # dominant), a slap on the strong long notes, a soft chord under the long ones
    rows = {(h, d): (m, c) for h, d, m, c in rd}
    last_slap = -9.0
    for v in list(voices):
        if v["role"] != "melody":
            continue
        # a slap now and then (a strong, held note, not within 1.5 s of the last), a chord on long notes
        strong = v["amp"] >= 0.98 and v["t1"] - v["t0"] >= 0.45 and v["t0"] - last_slap >= 1.5
        if not (strong or v["long"]):
            continue
        if strong:
            last_slap = v["t0"]
        for h in (v["hole"] - 1, v["hole"] - 2):
            if h < 1 or (v["dir"] == "draw" and h > 4 and v["hole"] > 5):
                continue
            m, c = rows[(h, v["dir"])]
            voices.append({"t0": v["t0"] + 0.004, "t1": v["t1"], "hole": h, "dir": v["dir"], "midi": m, "cents": c,
                           "amp": 0.5 if strong else 0.0, "hold": 0.22 if v["long"] else 0.0,
                           "role": "slap" if strong else "chord", "scoop": 0.0, "long": v["long"]})
    # the slide between holes on one breath: the holes passed over sound for a moment
    mv = [v for v in voices if v["role"] == "melody"]
    for a, b in zip(mv, mv[1:]):
        if a["dir"] == b["dir"] and abs(a["hole"] - b["hole"]) >= 2 and b["t0"] - a["t1"] < 0.03:
            step = 1 if b["hole"] > a["hole"] else -1
            for i, h in enumerate(range(a["hole"] + step, b["hole"], step)):
                m, c = rows[(h, a["dir"])]
                t = b["t0"] - 0.012 * (abs(b["hole"] - a["hole"]) - 1 - i)
                voices.append({"t0": t - 0.006, "t1": t + 0.010, "hole": h, "dir": a["dir"], "midi": m, "cents": c,
                               "amp": 0.35, "role": "pass", "scoop": 0.0, "long": False})
    voices.sort(key=lambda v: v["t0"])
    return {"tune": sc["tune"], "instrument": f"diatonic harmonica, Richter, in {key}", "key": key,
            "octave": shift // 12, "seed": seed, "length_s": round(max(v["t1"] for v in voices) + 1.0, 3),
            "voices": voices}


def _breath(part, srm):
    """The breath's pressure (0-1): on through each run of notes on one breath, a dip at each
    tongued repeat, through zero where the breath turns from blow to draw."""
    n = int(part["length_s"] * srm)
    p = np.zeros(n)
    mel = [v for v in part["voices"] if v["role"] == "melody"]
    for k, v in enumerate(mel):
        i0, i1 = int(v["t0"] * srm), int(v["t1"] * srm)
        seg = np.full(i1 - i0, v["amp"])
        prev = mel[k - 1] if k else None
        a = int(0.03 * srm)
        if prev is None or v["t0"] - prev["t1"] > 0.05:
            seg[:a] *= np.linspace(0, 1, a)[:len(seg)] ** 1.5  # a fresh breath
        elif prev["dir"] != v["dir"]:
            r = int(0.015 * srm)  # the breath turns: quick, through a little less
            seg[:r] *= 0.35 + 0.65 * np.linspace(0, 1, r)[:len(seg)]
        elif prev["hole"] == v["hole"]:
            t = int(0.022 * srm)  # tongued: "ta"
            seg[:t] *= 0.5 + 0.5 * np.linspace(0, 1, t)[:len(seg)]
        p[i0:i1] = np.maximum(p[i0:i1], seg)
    b, a = butter(1, 60 / (srm / 2))
    return lfilter(b, a, p)


def render(part, sr=common.SR, seed=1857):
    rng = np.random.default_rng(seed)
    srm = sr * OVER
    n = int(part["length_s"] * srm)
    breath = _breath(part, srm)
    # no breath is steady: a slow wander (a few %) and a faster quiver, the pitch following a little
    wob = lfilter(*butter(1, 3.0 / (srm / 2)), rng.standard_normal(n))
    wob = 0.04 * wob / (np.std(wob) + 1e-12)
    breath = breath * (1.0 + wob)
    wob_c = -25.0 * wob  # the reed goes flat as the breath swells (scaled to a few cents)
    out = np.zeros(n)
    flow = np.zeros(n)
    for v in part["voices"]:
        i0 = max(0, int(v["t0"] * srm))
        i1 = min(n, int((v["t1"] + 0.03) * srm))
        if i1 - i0 < 16:
            continue
        L = i1 - i0
        t = np.arange(L) / srm
        P = breath[i0:i1].copy()
        if v["role"] in ("slap", "chord"):
            # the tongue lifts off the holes: a slap's burst, then the soft chord he leaves (or none)
            P = P * (v["amp"] * np.exp(-t / 0.07) + v.get("hold", 0.0))
        elif v["role"] == "pass":
            P = P * v["amp"]
        # the reed starts by growing from rest (a self-starting oscillator: ~20 ms), and stops
        tau = rng.uniform(0.004, 0.007) if v.get("flowing") else rng.uniform(0.012, 0.025)
        grow = 1.0 - np.exp(-t / tau)
        stop = np.clip((L / srm - t) / 0.012, 0, 1)
        amp = np.sqrt(np.clip(P, 0, None)) * grow * stop
        # pitch: the reed's, blown a touch flat when pushed (~-6 cents at full), a bent note's scoop,
        # and on long notes the hand's tremolo shaking it a little
        # (tuned at an ordinary breath, ~0.8: only pushing past it takes the reed flat)
        cents = (v["cents"] - 6.0 * np.maximum(0.0, P - 0.8) + v["scoop"] * np.exp(-t / 0.08) + wob_c[i0:i1]
                 - 5.0 * np.exp(-t / 0.04))  # each note settles up from a few cents flat
        if v["long"]:
            trem = np.clip((t - 0.35) / 0.3, 0, 1) * np.sin(2 * np.pi * 5.6 * t + rng.uniform(0, 6))
            cents = cents + 1.5 * trem
        f = common.hz(v["midi"] + cents / 100.0)
        ph = 2 * np.pi * np.cumsum(f) / srm + rng.uniform(0, 2 * np.pi)
        # the reed's swing (its second bending mode, ~6.3x, a little at the start) and the slot
        # (the second mode faint and gone in ~10 ms: any stronger, it drags each start sharp, which his
        # record doesn't have: measured, his notes come in ~3 cents flat)
        x = X_REST + amp * (np.sin(ph) + 0.01 * np.exp(-t / 0.01) * np.sin(6.27 * ph))
        # in the slot only the clearance; out of it, the gap it opens. A reed's tip is thick and
        # tapered, so it uncovers the slot over a little of its swing, not at a knife edge
        area = LEAK + EDGE * np.logaddexp(0.0, x / EDGE)
        u = area * np.sqrt(np.clip(P, 0, None))
        if v["long"]:
            u = u * (1.0 + 0.18 * trem)  # the hands' flutter
        seg = out[i0:i1]
        seg += np.diff(np.concatenate([[u[0]], u])) * srm / 1000.0
        flow[i0:i1] += np.abs(u)
    y = resample_poly(out, 1, OVER)
    fl = resample_poly(flow, 1, OVER)
    # the mouth and the cupped hands: a soft body round 1 kHz, the very top taken off, more muffled
    # when the hands close (between the long notes) than open
    b, a = butter(2, [400 / (sr / 2), 4500 / (sr / 2)], "band")
    shaped = lfilter(b, a, y)
    b, a = butter(1, 2500 / (sr / 2))
    muffled = lfilter(b, a, y)
    openness = np.zeros(len(y))
    for v in part["voices"]:
        if v["role"] == "melody" and v["long"]:
            i0, i1 = int(v["t0"] * sr), min(len(y), int(v["t1"] * sr))
            openness[i0:i1] = np.linspace(0.3, 0.9, i1 - i0) if i1 > i0 else 0
    openness = lfilter(*butter(1, 4 / (sr / 2)), np.maximum(openness, 0.35))
    y = 0.6 * y + 0.4 * (openness * shaped + (1 - openness) * muffled)
    # breath: turbulence hissing with the flow
    nz = lfilter(*butter(2, [1500 / (sr / 2), 7000 / (sr / 2)], "band"), rng.standard_normal(len(y)))
    y = y + 0.025 * np.std(y) / (np.std(nz * fl) + 1e-12) * nz * fl
    b, a = butter(2, 120 / (sr / 2), "high")
    return lfilter(b, a, y)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    part = arrange(sc)
    if "part" in opt:
        json.dump(part, open(opt["part"], "w"), indent=1)
    name = os.path.splitext(os.path.basename(src))[0]
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_harmonica.wav"))
    y = render(part)
    common.write_wav(out, common.normalise(y))
    roles = {}
    for v in part["voices"]:
        roles[v["role"]] = roles.get(v["role"], 0) + 1
    bent = sum(1 for v in part["voices"] if v["scoop"])
    print(f"{out}: {part['tune']} on a {part['key']} harp (octave {part['octave']:+d}), {roles}, {bent} bent")


if __name__ == "__main__":
    main()
