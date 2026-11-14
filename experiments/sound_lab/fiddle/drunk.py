#!/usr/bin/env python3
"""The fiddler, drunk (#790): the same tune's note data, played the way a drunk man plays it, for the
same bowed-string model (bowed.py) to sound. Nothing here makes sound; it only changes what the
hands do, so a drunk fiddler in the game is the same fiddler with a dial turned.

    python3 experiments/sound_lab/fiddle/drunk.py cotton_eyed_joe.json cotton_eyed_joe_drunk.json [--drink=1.0] [--seed=7]

What drink does to him, each scaled by --drink (0 sober, 1 well gone):
- **Time:** his tempo wanders (a slow drift, +-12%, and he drags as the tune goes on), each bow
  stroke lands early or late (~35 ms), and now and then he loses his place: a stumble, where a
  stroke's notes come late and crowded, or a hiccup, a gap before he picks up again.
- **Pitch:** a fingered note is rarely where it should be (+-22 cents), sometimes a finger lands
  wide (70-110 cents off) and slides over to the note; his hand wavers more on a held note.
- **Bow:** the pressure is all over the place: some strokes dig in past what the string can hold
  (the crunch), some barely touch it (the whistle); the bow wanders toward the bridge and the
  fingerboard; and it catches the open string beside the one he meant (a stray drone).
"""
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
NEIGHBOURS = {"G": ["D"], "D": ["G", "A"], "A": ["D", "E"], "E": ["A"]}
OPEN = {"G": 55, "D": 62, "A": 69, "E": 76}


def _warp(length, rng, drink):
    """Played time -> his time: a tempo that drifts (smoothed noise, +-12%) and drags (to ~8%
    slower by the end), integrated."""
    dt = 0.01
    n = int(length / dt) + 2
    noise = rng.standard_normal(n)
    k = np.exp(-np.arange(-150, 151) ** 2 / (2 * 60.0 ** 2))  # ~0.6 s smoothing
    drift = np.convolve(noise, k / k.sum(), mode="same")
    drift = drift / (np.std(drift) + 1e-9) * 0.12 * drink
    drag = 0.08 * drink * np.linspace(0, 1, n)
    rate = np.clip(1.0 + drift + drag, 0.7, 1.5)  # his seconds per played second
    clock = np.concatenate([[0.0], np.cumsum(rate * dt)])[:n]
    grid = np.arange(n) * dt
    return lambda t: float(np.interp(t, grid, clock))


def drink_it(sc, drink=1.0, seed=7):
    rng = np.random.default_rng(seed)
    notes, strokes = sc["notes"], sc["strokes"]
    W = _warp(sc["length_s"] + 2.0, rng, drink)

    # each stroke's new start: the drifting clock, a jitter, and a stumble or a hiccup now and then
    starts, ends = [], []
    shift = 0.0
    for st in strokes:
        if rng.random() < 0.03 * drink:
            shift += rng.uniform(0.12, 0.35)  # a hiccup: he loses it for a moment
        s = W(st["t0"]) + shift + rng.normal(0, 0.035 * drink)
        if starts:
            s = max(s, starts[-1] + 0.03)
        starts.append(s)
    for i, st in enumerate(strokes):
        e = starts[i + 1] if i + 1 < len(strokes) else W(st["t1"]) + shift
        ends.append(max(e, starts[i] + 0.03))

    def remap(i, t):
        st = strokes[i]
        L = max(st["t1"] - st["t0"], 1e-6)
        return starts[i] + (t - st["t0"]) / L * (ends[i] - starts[i])

    stumbles = {i for i in range(len(strokes)) if rng.random() < 0.04 * drink}
    out_notes = []
    for nt in notes:
        n = dict(nt)
        i = nt["stroke"]
        t0, t1 = remap(i, nt["t"]), remap(i, nt["t"] + nt["dur"])
        if i in stumbles:  # late into the stroke and then crowded to catch up
            a = starts[i] + 0.45 * (t0 - starts[i]) + 0.4 * (ends[i] - starts[i])
            t1 = min(ends[i], a + max(0.04, (t1 - t0) * 0.6))
            t0 = a
        n["t"], n["dur"] = round(t0, 4), round(max(0.03, t1 - t0), 4)
        if n["finger"] > 0:
            n["cents"] = round(n.get("cents", 0.0) + rng.normal(0, 22 * drink), 1)
            if n["voice"] == "melody" and not n.get("slide_from") and rng.random() < 0.08 * drink:
                wide = rng.choice([-1, 1]) * rng.uniform(70, 110) / 100.0
                n["slide_from"] = n["midi"] + n["cents"] / 100.0 + wide
                n["slide_s"] = round(rng.uniform(0.05, 0.12), 3)
        out_notes.append(n)

    out_strokes = []
    for i, st in enumerate(strokes):
        s = dict(st)
        s["t0"], s["t1"] = round(starts[i], 4), round(ends[i], 4)
        r = rng.random()
        if r < 0.10 * drink:
            p = rng.uniform(1.7, 2.3)  # dug in past what the string holds: the crunch
        elif r < 0.20 * drink:
            p = rng.uniform(0.08, 0.18)  # barely on: the whistle
        else:
            p = st["pressure"] * np.exp(rng.normal(0, 0.3 * drink))
        s["pressure"] = round(float(p), 3)
        s["speed"] = round(float(st["speed"] * np.exp(rng.normal(0, 0.25 * drink))), 3)
        s["pos"] = round(float(np.clip(st["pos"] + rng.normal(0, 0.035 * drink), 0.045, 0.2)), 3)
        # Schelleng: a string crunches when the force passes what the bow's speed holds at that
        # point (more force, a slower bow, further from the bridge); it whistles when the force
        # is under what holds it at all (light, near the bridge)
        if p >= 1.7:
            s["speed"] = round(s["speed"] * rng.uniform(0.3, 0.5), 3)
            s["pos"] = round(float(rng.uniform(0.15, 0.2)), 3)
        elif p <= 0.18:
            s["pos"] = round(float(rng.uniform(0.045, 0.06)), 3)
        out_strokes.append(s)
        # the stroke's notes take its pressure (scaled from their own share of it)
        for n in out_notes:
            if n["stroke"] == i:
                n["pressure"] = round(float(n["pressure"] * p / max(st["pressure"], 1e-3)), 3)
        # catching the string beside: a stray open string for part of the stroke
        if rng.random() < 0.12 * drink:
            mine = [n for n in out_notes if n["stroke"] == i and n["voice"] == "melody"]
            if mine:
                m = mine[0]
                beside = rng.choice(NEIGHBOURS[m["string"]])
                if beside not in s["strings"]:
                    s["strings"] = s["strings"] + [beside]
                stray = dict(m, string=beside, midi=OPEN[beside], finger=0, cents=0.0, voice="drone",
                             slide_from=None, slide_s=0.0, pressure=round(m["pressure"] * 0.6, 3),
                             dur=round(min(m["dur"], rng.uniform(0.05, 0.15)), 4))
                out_notes.append(stray)
    out_notes.sort(key=lambda n: n["t"])

    d = dict(sc)
    d["notes"], d["strokes"] = out_notes, out_strokes
    d["length_s"] = round(max(n["t"] + n["dur"] for n in out_notes), 3)
    d["tune"] = sc["tune"] + " (drunk)"
    d["player"] = {"drink": drink, "seed": seed, "wander_cents": 3.0 + 9.0 * drink}
    return d


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    src, dst = (os.path.join(HERE, p) if not os.path.isabs(p) else p for p in args[:2])
    d = drink_it(json.load(open(src)), float(opt.get("drink", 1.0)), int(opt.get("seed", 7)))
    json.dump(d, open(dst, "w"), indent=1)
    print(f"{dst}: {d['tune']}, {d['length_s']} s, {len(d['notes'])} notes")


if __name__ == "__main__":
    main()
