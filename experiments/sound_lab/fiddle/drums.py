#!/usr/bin/env python3
"""The travelling band's drums (#822): a rope-tensioned side drum (the snare) and a bass drum, both
calfskin, as every town and army band of the 1880s marched behind. Our own models from the physics,
no copied code; they play to a tune's beat grid (the march's, or rhythm.py's for a reel).

    python3 experiments/sound_lab/fiddle/drums.py yankee_doodle.json [--only=snare|bass] [--out=...wav]
    python3 experiments/sound_lab/fiddle/drums.py --hit=snare|bass [--vel=0.7]     one stroke

**The heads (modal synthesis):** a stretched skin rings in its membrane modes (m nodal diameters,
n nodal circles), each at a Bessel zero j_mn over the first's, decaying on its own. The air inside
the shell couples the two heads and pushes the low modes nearer a harmonic row (a bass drum's
(1,1), (2,1), (3,1) ... sound almost as harmonics of ~70 Hz) and lowers the (0,1), which radiates
hard and dies quickly (Fletcher & Rossing, ch. 18, "Drums"). Calfskin is lossier than today's
plastic: shorter decays, the highs gone sooner. A stroke at a radius r excites each mode by
J_m(j_mn r/R) (the mode's shape there), times the spectrum of the stick's or beater's contact: a
half-sine push ~0.6 ms long for a hickory stick, ~6 ms for a lambswool beater, shorter for a harder
stroke (the skin and felt stiffen). A hard stroke stretches the skin and raises its pitch for the
first tens of ms (tension modulation, Avanzini & Rocchesso's observation of real drums).

**The snares (the side drum's rattle):** gut strings lie across the bottom (snare) head, pressed on
it. The air in the shell drives that head; whenever it is thrown downward faster than the snares'
tension can follow, they lift off and slap back. We take the snare head's own motion (its modes,
driven through the air a fraction of a ms after the batter head's) and make a burst of noise each
time its acceleration passes the snares' hold, the burst as strong as the excess: so the rattle
starts with the stroke, thickens in a roll, and stops by itself when the head's motion falls under
the threshold, as real snares do. Gut rattles darker than wire. Cook's PhISEM work (1997) has the
idea of collisions as noise events; the snare model here is ours.

**How they play** (Bruce & Emmett's "The Drummers' and Fifers' Guide", 1862, and Strube's 1869
manual, the rudiments every band drummer learned): the side drum on the march's sixteenth grid, a
flam on the strong beats (a grace stroke ~30 ms before), taps between, five- and seven-stroke rolls
(open double strokes) into the accents, a seven-stroke into each phrase's last downbeat, a two-bar
roll-off before the band comes in. The bass drum on every beat, the first of the bar heavier.
"""
import json
import os
import sys

import numpy as np
from scipy.signal import butter, sosfilt
from scipy.special import jv

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
RATTLE = 0.3  # the snares' rattle against the head's loudest
BUZZ_POW = 1.0

# membrane modes (m, n, Bessel zero j_mn)
JMN = [(0, 1, 2.405), (1, 1, 3.832), (2, 1, 5.136), (0, 2, 5.520), (3, 1, 6.380), (1, 2, 7.016),
       (4, 1, 7.588), (2, 2, 8.417), (0, 3, 8.654), (5, 1, 8.771), (3, 2, 9.761), (6, 1, 9.936),
       (1, 3, 10.17), (4, 2, 11.06), (7, 1, 11.09), (2, 3, 11.62), (0, 4, 11.79), (8, 1, 12.23),
       (5, 2, 12.34), (3, 3, 13.02), (1, 4, 13.32), (9, 1, 13.35), (6, 2, 13.59), (4, 3, 14.37)]


def drum_modes(kind):
    """(freqs Hz, T60s s, m, j) for the batter head, with the air's pull on the low modes."""
    if kind == "bass":
        f11, t11 = 72.0, 1.1  # a 28-inch calfskin band drum
        # the air in the shell makes (1,1)...(4,1) nearly harmonic (Fletcher & Rossing's bass drum)
        air = {(0, 1): 0.62, (1, 1): 1.0, (2, 1): 1.48, (3, 1): 1.95, (4, 1): 2.41, (0, 2): 1.62}
    else:
        f11, t11 = 300.0, 0.4  # a 16-inch rope field drum, calfskin, tuned low
        air = {(0, 1): 0.70, (1, 1): 1.0, (2, 1): 1.38, (0, 2): 1.55, (3, 1): 1.70}
    f, t60, ms, js = [], [], [], []
    for m, n, j in JMN:
        r = air.get((m, n), j / 3.832)
        fr = f11 * r
        if fr > 9000:
            continue
        # losses: the skin's damping grows with frequency; the (0,1) radiates its energy away fast
        t = t11 * (f11 / fr) ** 0.75
        if (m, n) == (0, 1):
            t = t11 * 0.32
        if (m, n) == (0, 2):
            t *= 0.6
        f.append(fr)
        t60.append(t)
        ms.append(m)
        js.append(j)
    return np.array(f), np.array(t60), np.array(ms), np.array(js)


def contact_spectrum(f, tau):
    """|F(f)| of a half-sine push of length tau (s), 1 at DC."""
    x = 2.0 * f * tau
    with np.errstate(divide="ignore", invalid="ignore"):
        out = np.abs(np.cos(np.pi * f * tau) / (1.0 - x * x))
    out[np.abs(1.0 - x * x) < 1e-6] = np.pi / 4
    return out


def _ring(freqs, t60, amps, n, sr, glide, glide_tau, phases):
    """Sum of decaying modes over n samples, each starting at the stroke; the pitch raised by `glide`
    (a fraction) at the stroke, falling back with glide_tau."""
    t = np.arange(n) / sr
    g = 1.0 + glide * np.exp(-t / glide_tau)
    # phase of a glide: integral of 2 pi f g(t) dt
    gi = t + glide * glide_tau * (1.0 - np.exp(-t / glide_tau))
    out = np.zeros(n)
    for fr, T, a, ph in zip(freqs, t60, amps, phases):
        if a == 0:
            continue
        out += a * np.exp(-6.91 * t / T) * np.sin(2 * np.pi * fr * gi + ph)
    return out, g


def stroke(kind, vel, r, rng, sr=common.SR):
    """One stroke: (batter head's sound, its displacement for the snares, or None)."""
    f, t60, ms, js = drum_modes(kind)
    det = 1.0 + rng.normal(0, 0.004)  # the rope tension wanders
    f = f * det
    if kind == "bass":
        tau = 0.0065 - 0.002 * vel  # lambswool beater
        n = int(1.8 * sr)
        glide, gtau = 0.05 * vel, 0.06
    else:
        tau = 0.0007 - 0.00025 * vel  # hickory stick on calfskin
        n = int(0.9 * sr)
        glide, gtau = 0.025 * vel, 0.03
    shape = np.abs(jv(ms, js * r))
    a = shape * contact_spectrum(f, tau) * vel
    # radiation: the (0,1) is a monopole and speaks most; the rest radiate weaker at low frequency
    rad = np.where(ms == 0, 1.0, np.clip((f / (f[0] * 3.0)) ** 1.0, 0.25, 1.0))
    if kind == "bass":
        rad[0] *= 0.35  # a big drum's (0,1) is mostly the air's thump: short and low, under the (1,1)
    a = a * rad * (1.0 + 0.15 * rng.normal(size=len(a)))
    ph = rng.uniform(0, 2 * np.pi, len(a)) * 0.15  # all start near zero displacement
    y, _ = _ring(f, t60, a, n, sr, glide, gtau, ph)
    # the skin is pushed over the contact's length, not struck in an instant
    kc = max(2, int(tau * sr))
    y[:kc] *= np.sin(0.5 * np.pi * np.arange(kc) / kc) ** 2
    # the beater's or stick's thud on the skin: a short, low noise
    k = int((0.012 if kind == "bass" else 0.004) * sr)
    thud = rng.normal(0, 1, k) * np.exp(-np.arange(k) / (k / 4))
    lo, hi = (40.0, 900.0) if kind == "bass" else (1500.0, 6000.0)
    thud = sosfilt(butter(2, [lo, hi], "bandpass", fs=sr, output="sos"), thud)
    y[:k] += thud * vel * (0.08 if kind == "bass" else 0.5) * np.max(np.abs(y[:k * 4]) + 1e-9)
    if kind != "snare":
        return y, None
    # the snare head, driven through the air ~0.4 ms later by the batter's breathing modes, tuned
    # higher (it's the thinner, tighter head), its motion what throws the snares off
    fs_, ts_ = f * 1.35, np.maximum(t60 * 0.8, 0.45)
    drive = np.where(fs_ < 1500.0, 1.0, 0.2) * a  # the air drives the low modes; the high ones hardly
    d = int(0.0004 * sr)
    sh, _ = _ring(fs_, ts_, drive / (2 * np.pi * fs_), n - d, sr, glide, gtau, ph)
    sh = np.concatenate([np.zeros(d), sh])
    return y, sh


def snare_rattle(head, sr, rng, hold=0.003, gut=True):
    """The snares slapping the head: noise bursts as strong as the head's downward acceleration is
    over the snares' hold (relative to the drum's loudest stroke)."""
    # the head's swing that throws the snares: its velocity, the low modes' (the high ones are too
    # small to lift a strand's weight)
    vel = sosfilt(butter(2, 1200.0, "lowpass", fs=sr, output="sos"), np.gradient(head))
    scale = np.percentile(np.abs(vel), 99.9) + 1e-12
    # strands lift off whenever the head drops away faster than they fall: a hard swing throws them
    # far (a slap), a small one barely (a light buzz): the excess's power, so the rattle fades with
    # the head instead of stopping dead
    e = np.clip(-vel / scale - hold, 0, None) ** BUZZ_POW
    # the snares take a moment to fall back: each slap's energy lingers ~6 ms
    k = int(0.006 * sr)
    env = np.convolve(e, np.exp(-np.arange(k) / (k / 3)), "full")[:len(e)]
    noise = rng.normal(0, 1, len(e))
    band = [900.0, 5000.0] if gut else [1800.0, 9000.0]
    buzz = sosfilt(butter(2, band, "bandpass", fs=sr, output="sos"), noise * env)
    # a strand's own ring, a little (the gut strings are stretched)
    for fr in (1250.0, 1980.0, 2760.0):
        buzz += 0.15 * sosfilt(butter(1, [fr * 0.97, fr * 1.03], "bandpass", fs=sr, output="sos"), noise * env)
    return buzz


def render(part, sr=common.SR, seed=1862, only=None):
    """part: {"strokes": [{t, drum, vel, r}], "length_s"} -> (mix, snare, bass)."""
    rng = np.random.default_rng(seed)
    n = int((part["length_s"] + 2.0) * sr)
    sn, head, bd = np.zeros(n), np.zeros(n), np.zeros(n)
    for st in part["strokes"]:
        if only and st["drum"] != only:
            continue
        i = int(st["t"] * sr)
        if i >= n:
            continue
        y, sh = stroke(st["drum"], st["vel"], st["r"], rng, sr)
        j = min(n, i + len(y))
        if st["drum"] == "bass":
            bd[i:j] += y[:j - i]
        else:
            sn[i:j] += y[:j - i]
            head[i:j] += sh[:j - i]
    if np.any(head):
        rattle = snare_rattle(head, sr, rng)
        sn = sn + rattle * (np.max(np.abs(sn)) / (np.max(np.abs(rattle)) + 1e-12)) * RATTLE
    # the shell and the room's first moment: a touch of short, dense reflection keeps it a drum, not a click
    return sn + bd * 1.0, sn, bd


# ---- the part: rudiments on the beat grid ----

def _flam(out, t, vel, rng, drum="snare"):
    out.append({"t": t - 0.028 + rng.normal(0, 0.003), "drum": drum, "vel": vel * 0.3, "r": rng.uniform(0.35, 0.6)})
    out.append({"t": t, "drum": drum, "vel": vel, "r": rng.uniform(0.2, 0.4)})


def _roll(out, t0, t_end, strokes, vel, rng):
    """An open roll: (strokes - 1) strokes as doubles (each pair's second a little weaker) spread
    from t0 to just before t_end, then the accented release on t_end."""
    k = strokes - 1
    dt = (t_end - t0) / k
    for i in range(k):
        v = vel * (0.55 + 0.25 * (i / k)) * (0.8 if i % 2 else 1.0)
        out.append({"t": t0 + i * dt + rng.normal(0, 0.002), "drum": "snare", "vel": v, "r": rng.uniform(0.3, 0.55)})
    out.append({"t": t_end, "drum": "snare", "vel": vel, "r": rng.uniform(0.2, 0.35)})


def arrange(beats, seed=1862, intro=True):
    """beats: [(t, bar_start, phrase_end)] for every beat (two a bar) the band plays, and the time
    after the last. Returns the drum part's strokes. With `intro`, a two-bar roll-off before."""
    rng = np.random.default_rng(seed)
    out = []
    times = [b[0] for b in beats]
    beat = float(np.median(np.diff(times)))
    if intro:
        t0 = times[0] - 4 * beat
        # the roll-off: two five-stroke rolls, a flam, a seven-stroke roll into the band's first beat
        _roll(out, t0, t0 + 0.5 * beat, 5, 0.7, rng)
        _roll(out, t0 + beat, t0 + 1.5 * beat, 5, 0.75, rng)
        _flam(out, t0 + 2 * beat, 0.9, rng)
        _roll(out, t0 + 3 * beat, t0 + 4 * beat, 7, 0.95, rng)
        for k in range(4):
            out.append({"t": t0 + k * beat, "drum": "bass", "vel": 0.8 if k % 2 == 0 else 0.6, "r": 0.35})
    for i, (t, bar_start, phrase_end) in enumerate(beats):
        nxt = times[i + 1] if i + 1 < len(times) else t + beat
        s = (nxt - t) / 4.0  # a sixteenth
        last = i == len(beats) - 1
        # the bass drum: every beat, the bar's first heavier
        out.append({"t": t + rng.normal(0, 0.004), "drum": "bass", "vel": (0.85 if bar_start else 0.62) + rng.normal(0, 0.04),
                    "r": 0.33 + rng.normal(0, 0.03)})
        if last:
            _flam(out, t, 1.0, rng)
            continue
        if bar_start:
            _flam(out, t, 0.85 + rng.normal(0, 0.04), rng)
            if rng.random() < 0.5:
                out.append({"t": t + 2 * s, "drum": "snare", "vel": 0.45, "r": rng.uniform(0.3, 0.5)})
                out.append({"t": t + 3 * s, "drum": "snare", "vel": 0.5, "r": rng.uniform(0.3, 0.5)})
            else:
                out.append({"t": t + 2 * s, "drum": "snare", "vel": 0.55, "r": rng.uniform(0.3, 0.5)})
        elif phrase_end:
            # a seven-stroke roll into the next phrase's downbeat (the flam there plays it out)
            _roll(out, t, nxt - 0.6 * s, 7, 0.8, rng)
            out.pop()  # its release is the next bar's flam
        else:
            if rng.random() < 0.55:
                # a five-stroke roll from the beat to its "and", accented
                _roll(out, t, t + 2 * s, 5, 0.75, rng)
                out.append({"t": t + 3 * s, "drum": "snare", "vel": 0.42, "r": rng.uniform(0.3, 0.5)})
            else:
                out.append({"t": t, "drum": "snare", "vel": 0.6, "r": rng.uniform(0.3, 0.5)})
                out.append({"t": t + 2 * s, "drum": "snare", "vel": 0.72, "r": rng.uniform(0.25, 0.4)})
                out.append({"t": t + 3 * s, "drum": "snare", "vel": 0.4, "r": rng.uniform(0.3, 0.5)})
    out.sort(key=lambda q: q["t"])
    shift = min(0.0, out[0]["t"] - 0.1)
    for q in out:
        q["t"] = round(q["t"] - shift, 4)
    return {"strokes": out, "length_s": out[-1]["t"] + 0.5, "shift": -shift}


def beats_of(sc):
    """The tune's beats [(t, bar_start, phrase_end)]: a march's own (its "beats"), or a reel's from
    rhythm.py's grid (two half-note beats a bar, the fiddler's swing)."""
    if "beats" in sc:
        return [tuple(b) for b in sc["beats"]]
    import rhythm
    when, beats, last, unit = rhythm.grid(sc)
    return [(when(u0), bs, pe) for u0, bs, pe in beats]


def main():
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    rng = np.random.default_rng(1)
    if "hit" in opt:
        y, sh = stroke(opt["hit"], float(opt.get("vel", 0.7)), 0.3, rng)
        if sh is not None:
            r = snare_rattle(sh, common.SR, rng)
            y = y + r * np.max(np.abs(y)) / (np.max(np.abs(r)) + 1e-12) * RATTLE
        out = opt.get("out", os.path.join(common.BUILD, "dry", f"drum_{opt['hit']}.wav"))
    else:
        src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
        sc = json.load(open(src))
        part = arrange(beats_of(sc), intro="beats" in sc)
        y = render(part, only=opt.get("only"))[0]
        out = opt.get("out", os.path.join(common.BUILD, "dry", os.path.splitext(os.path.basename(src))[0] + "_drums.wav"))
    common.write_wav(out, common.normalise(y))
    print(f"{out}: {len(y) / common.SR:.1f} s")


if __name__ == "__main__":
    main()
