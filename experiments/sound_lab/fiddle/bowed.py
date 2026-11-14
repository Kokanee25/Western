#!/usr/bin/env python3
"""B: our own bowed-string model (issue #790), written fresh from the physics, no copied code.

Each of the four strings is a digital waveguide: the string's velocity waves run from the bow to
the bridge and back, and from the bow to the finger (or nut) and back, each end reflecting them
inverted and a little duller (a one-pole low-pass: the bridge loses more, a stopped finger more
than the nut). Where the bow touches, the bow and string meet by friction: the hair grips the
string (stick, the string moving with the bow) until the force it would take passes the static
friction (mu_s x the bow's force), then the string slips back under the kinetic friction, which
falls as the slip gets faster (mu = mu_d + (mu_s - mu_d) v0 / (v0 + |slip|), the "hyperbolic"
curve). That stick-slip is solved each sample in closed form (a quadratic in the slip speed) and
holds its state through the curve's two-valued part (it stays slipping while a slipping solution
exists), which is what gives a bowed string its Helmholtz corner and its scratch when pressed
hard. Ideas from McIntyre, Schumacher & Woodhouse (1983) "On the oscillations of musical
instruments", J. O. Smith's waveguide papers (1986, 1992) and Woodhouse & Galluzzo (2004) on the
friction curve; the code is ours.

The note data drives it (common.string_controls): each string's stopped pitch (slides included),
the bow's force on it (from each note's pressure, leaning in on accents), and the bow's speed and
direction (from the strokes). Strings no note is on ring open and fade (an old fiddle's open
strings sing along). The bridge's force goes through a fiddle body: a synthetic impulse response
of decaying modes, the low air and plate modes (A0 ~275 Hz, B1- ~460, B1+ ~540) and a dense
upper set under the "bridge hill" near 2.5 kHz (Jansson; Bissinger's mode surveys), seeded.

    python3 experiments/sound_lab/fiddle/bowed.py [--out=build/sound_lab/fiddle/dry/B.wav]
"""
import os
import sys

import numpy as np
from numba import njit
from scipy.signal import fftconvolve, lfilter, butter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

OVER = 2                      # run the strings at 96 kHz (near the bridge the E string's segment is tiny)
MU_S, MU_D, V0 = 0.8, 0.32, 0.12
Z = 0.30                      # string wave impedance, kg/s (a violin string's ~0.2-0.4)
BUF = 8192


@njit(cache=True)
def _read(buf, w, d):
    """The buffer's value `d` samples back from write position `w` (cubic Lagrange)."""
    n = buf.shape[0]
    di = int(d)
    fr = d - di
    i0 = (w - di + 1) % n
    i1 = (w - di) % n
    i2 = (w - di - 1) % n
    i3 = (w - di - 2) % n
    x0, x1, x2, x3 = buf[i0], buf[i1], buf[i2], buf[i3]
    # points at delays di-1, di, di+1, di+2; evaluate at d = di + fr
    c0 = -fr * (fr - 1.0) * (fr - 2.0) / 6.0
    c1 = (fr + 1.0) * (fr - 1.0) * (fr - 2.0) / 2.0
    c2 = -(fr + 1.0) * fr * (fr - 2.0) / 2.0
    c3 = (fr + 1.0) * fr * (fr - 1.0) / 6.0
    return c0 * x0 + c1 * x1 + c2 * x2 + c3 * x3


@njit(cache=True)
def run_string(sr, f0, force, vbow, beta, stopped, noise, mu_s, mu_d, v0, z):
    n = f0.shape[0]
    out = np.zeros(n)
    slipping = np.zeros(n)
    b_out = np.zeros(BUF)
    b_back = np.zeros(BUF)
    n_out = np.zeros(BUF)
    n_back = np.zeros(BUF)
    w = 0
    lp_b = 0.0
    lp_n = 0.0
    a_lb = 0.22               # bridge reflection's low-pass coefficient
    sl = False
    for i in range(n):
        st = stopped[i]
        a_ln = 0.30 if st else 0.12
        g_b = 0.992
        g_n = 0.975 if st else 0.996
        if force[i] <= 0.0:
            g_n *= 0.997      # an unbowed string rings down (a lifted finger, the hand)
        # the loop's length less the two low-passes' delay, split by the bow
        d_tot = sr / f0[i] - (a_lb / (1.0 - a_lb) + a_ln / (1.0 - a_ln))
        hb = 0.5 * beta[i] * d_tot
        hn = 0.5 * (1.0 - beta[i]) * d_tot
        if hb < 1.5:
            hb = 1.5
        a_b = _read(b_back, w, hb)
        a_n = _read(n_back, w, hn)
        vh = a_b + a_n
        vb = vbow[i]
        fb = force[i] * (1.0 + noise[i])
        delta = 0.0
        if fb > 0.0:
            k = fb / (2.0 * z)
            wv = abs(vh - vb)
            stick_ok = wv <= k * mu_s
            if sl:
                # stay slipping while a slip solution exists
                bq = v0 + k * mu_d - wv
                cq = v0 * (k * mu_s - wv)
                disc = bq * bq - 4.0 * cq
                x = -1.0
                if disc >= 0.0:
                    x = 0.5 * (-bq + np.sqrt(disc))
                if x > 0.0:
                    sgn = 1.0 if vh > vb else -1.0
                    u = sgn * x
                    delta = (vb + u) - vh
                elif stick_ok:
                    sl = False
                    delta = vb - vh
                else:
                    delta = 0.0
            else:
                if stick_ok:
                    delta = vb - vh
                else:
                    sl = True
                    bq = v0 + k * mu_d - wv
                    cq = v0 * (k * mu_s - wv)
                    disc = bq * bq - 4.0 * cq
                    x = 0.5 * (-bq + np.sqrt(max(disc, 0.0)))
                    sgn = 1.0 if vh > vb else -1.0
                    delta = (vb + sgn * x) - vh
        else:
            sl = False
        slipping[i] = 1.0 if sl else 0.0
        o_b = a_n + delta
        o_n = a_b + delta
        b_out[w] = o_b
        n_out[w] = o_n
        # the bridge end: what arrives is the force on the bridge (out); it goes back inverted, duller
        x = _read(b_out, w, hb)
        lp_b = (1.0 - a_lb) * x + a_lb * lp_b
        b_back[w] = -g_b * lp_b
        out[i] = x
        y = _read(n_out, w, hn)
        lp_n = (1.0 - a_ln) * y + a_ln * lp_n
        n_back[w] = -g_n * lp_n
        w = (w + 1) % BUF
    return out, slipping


# How much of the bow's hair a string gets: the melody's string all of it; a double stop most; a
# drone, the bow tilted off it, half (a string's swing follows the bow's speed, not its force,
# so the tilt is what keeps a drone under the tune). Smoothed over 15 ms.
SHARE = {"melody": 1.0, "double": 0.8, "drone": 0.5}


def _shares(sc, n, sr):
    out = {}
    for s in common.STRINGS:
        g = np.ones(n)
        for nt in sc["notes"]:
            if nt["string"] == s:
                i0, i1 = int(nt["t"] * sr), int((nt["t"] + nt["dur"]) * sr)
                g[i0:i1] = SHARE[nt["voice"]]
        k = int(0.015 * sr)
        out[s] = np.convolve(np.pad(g, (k, k), mode="edge"), np.ones(k) / k, mode="same")[k:-k]
    return out


def body_ir(sr, seed=1882, length=0.35):
    """A fiddle body's response at the bridge: decaying modes, the strong low ones from the
    literature's typical violin, a seeded dense set above under a bridge hill near 2.5 kHz."""
    rng = np.random.default_rng(seed)
    t = np.arange(int(length * sr)) / sr
    modes = [(275, 14, 1.0), (405, 25, 0.5), (460, 22, 0.9), (540, 22, 1.0), (650, 20, 0.6),
             (840, 20, 0.55), (1030, 18, 0.5), (1250, 18, 0.45)]
    f = 1350.0
    while f < 9000:
        f *= 1.0 + rng.uniform(0.02, 0.07)
        hill = np.exp(-0.5 * (np.log(f / 2500.0) / 0.35) ** 2)
        amp = (0.25 + 0.7 * hill) * (1.0 if f < 4500 else (4500 / f) ** 2) * rng.uniform(0.5, 1.0)
        modes.append((f, rng.uniform(12, 30), amp))
    ir = np.zeros_like(t)
    for fr, q, a in modes:
        ir += a * np.exp(-np.pi * fr * t / q) * np.sin(2 * np.pi * fr * t + rng.uniform(0, 2 * np.pi))
    return ir / np.max(np.abs(ir))


def render(sc, sr=common.SR, seed=1882):
    srm = sr * OVER
    f0, force, stopped = common.string_controls(sc, srm)
    vb = common.bow_envelope(sc, srm)
    rng = np.random.default_rng(seed)
    total = np.zeros(len(vb))
    share = _shares(sc, len(vb), srm)
    for si, s in enumerate(common.STRINGS):
        # rosin and hair: the bow's grip wavers, a little band-limited noise on the force
        nz = rng.standard_normal(len(vb))
        bb, ab = butter(2, [300 / (srm / 2), 6000 / (srm / 2)], "band")
        nz = lfilter(bb, ab, nz)
        nz = 0.10 * nz / (np.std(nz) + 1e-9)
        # the hand never holds a pitch dead still: a slow wander, ~3 cents, under the fingers' own
        wander = lfilter([1.0], [1.0, -0.99995], rng.standard_normal(len(vb)))
        wander = lfilter(*butter(1, 6 / (srm / 2)), wander)
        wander = sc.get("player", {}).get("wander_cents", 3.0) * wander / (np.std(wander) + 1e-9)  # (drunk.py: more)
        f0s = f0[s] * 2.0 ** (wander / 1200.0)
        beta = np.full(len(vb), 0.10)
        for st in sc["strokes"]:
            i0, i1 = int(st["t0"] * srm), int(st["t1"] * srm)
            beta[i0:i1] = st["pos"]
        out, _ = run_string(float(srm), f0s, force[s], vb, beta, stopped[s], nz, MU_S, MU_D, V0, Z)
        total += out * share[s]
    y = common.resample(total, srm, sr)
    y = fftconvolve(y, body_ir(sr, seed))[: len(y)]
    # the bridge force is velocity-like; a gentle tilt for the air (radiation rises with frequency
    # below ~1 kHz) - a first difference blended in
    y = y + 0.6 * np.concatenate([[0], np.diff(y)]) * 6
    b, a = butter(2, 70 / (sr / 2), "high")
    return lfilter(b, a, y)


if __name__ == "__main__":
    out = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--out=")),
               os.path.join(common.BUILD, "dry", "B.wav"))
    import time
    t = time.time()
    y = render(common.score())
    common.write_wav(out, common.normalise(y))
    print(f"{out} ({time.time() - t:.1f} s)")
