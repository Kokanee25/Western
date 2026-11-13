#!/usr/bin/env python3
"""The banjo (#790, after the fiddle): the fiddler's partner at the dances, made the same way, by our
own model, from the same note data. Written fresh from the physics, no copied code.

    python3 experiments/sound_lab/fiddle/banjo.py turkey_in_the_straw.json [--out=build/.../turkey_banjo.wav]
        [--part=OUT.json] (the banjo's own note data: what his hands do)
        [--strings=gut|steel|modern] (gut, the default: the period's; steel: from the 1890s, Macon's;
        modern: steel on a tight synthetic head, an open-back as The Dead South's banjoist plays)
        [--style=clawhammer|rolls] (clawhammer, the default; rolls: three-finger with picks)

**The instrument:** an 1870s-80s five-string banjo: gut strings, a calfskin head on an open-backed
pot, the short fifth string a drone the thumb plays. It's tuned to the tune's key the way old-time
players retune rather than capo: open G (gDGBD) for G tunes, open A (aEAC#E) for A, and D (aDF#AD)
for D.

**How he plays (the part):** the stroke style the minstrel books taught (Briggs, 1855) and old-time
players kept as clawhammer: the back of a nail strikes down, the thumb catches the fifth string on
the way back. Each beat (four of the tune's running notes) is "bum-ditty": the tune's note on the
beat struck by the nail (bum), then a brush down across three strings with the tune's note on top
(dit), then the thumb on the fifth string (ty). Where the tune moves on the beat's second note on
the same string he hammers on (a finger comes down on the ringing string) or pulls off (a finger
leaves it, plucking it); every other beat, when the tune's last note of the beat is on a long
string, the thumb drops onto that string to play it instead of the drone (drop thumb). The rest of
the tune he leaves to the fiddle: a banjo plays its skeleton. The tune goes down an octave when that
keeps more of it in the first five frets (most fiddle tunes; octave_for), and a note still above
the ninth fret down another. Fretted notes ring until the finger leaves (a beat on at most), open strings until struck
again or they fade. The chords are the fiddle part's (abc_tune.chords_of), the brush's other
strings fretted to them near the hand.

**The sound (the model):** each string a digital waveguide (the Karplus-Strong loop made
physical: a delay of one period, a one-pole loss that dulls the highs each pass as gut does, a
loop gain set by each string's decay time). A strike is fed in as a short pulse (a nail sharp, a
thumb's flesh softer), combed by where on the string it lands (clawhammer strikes over the head's
neck end, ~0.28 of the string from the bridge: the mellow knock), and pulls the string a few cents
sharp for a moment (a hard strike stretches it). The strings' force at the bridge goes through the
head: a stretched skin's modes (a circular membrane's Bessel ratios over a ~260 Hz fundamental,
heavily damped as calfskin is) with a dense upper set under a broad 1-3 kHz rise, and a little of
the pot's air. That head is why a banjo is loud, bright and short. Each string runs twice, its two ways of
swinging (POLS: into the head, loud and soon gone; along it, quiet and ringing on, a hair sharper),
so a note drops fast then rings with a waver; each strike also thumps the skin itself (POP); and
no string is dead in tune, no two strikes or brushes alike (a keyboard's tells, taken out). Ideas from Rae & Rossing's
banjo measurements, Dickey's (2003) banjo model and Jaffe & Smith's (1983) plucked-string
extensions; the code is ours.
"""
import json
import os
import sys

import numpy as np
from numba import njit
from scipy.signal import butter, fftconvolve, lfilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
import tune  # noqa: E402
from bowed import _read  # noqa: E402  (the cubic fractional read)

HERE = os.path.dirname(os.path.abspath(__file__))
OVER = 2
BUF = 8192
# strings 1 (the highest long string) to 4, and 5 the short drone; midi
TUNINGS = {
    "G": {1: 62, 2: 59, 3: 55, 4: 50, 5: 67},   # gDGBD, open G
    "A": {1: 64, 2: 61, 3: 57, 4: 52, 5: 69},   # aEAC#E, open G a tone up
    "D": {1: 62, 2: 57, 3: 54, 4: 50, 5: 69},   # aDF#AD
    "C": {1: 62, 2: 60, 3: 55, 4: 48, 5: 67},   # gCGCD, double C
}
NAMES = {0: "C", 2: "D", 7: "G", 9: "A"}
MAX_FRET = 9
STRIKE_POS = 0.28
HEAD_RISE = 2200.0
NAIL_W = 0.00025
# a string swings two ways at once: across the head (vertical: it drives the head, so it's loud and
# dies fast) and along it (horizontal: barely coupled, quiet, rings on), a hair apart in pitch, so the
# note beats and its decay has two stages (Weinreich's two polarisations; on a banjo the vertical one
# drains into the head fastest of any string instrument). (level, decay time x, cents)
POLS = [(1.0, 0.55, 0.0), (0.35, 1.9, 1.3)]
CLICK = 0.06        # the nail's tick on the string (a broadband scrape, a few ms)
PICK_W = 0.0001      # a metal fingerpick: harder and narrower than a nail
POP = 0.25          # the head struck through the bridge: a small drum's thump under each strike


# ----------------------------------------------------------------------------------------- the part

def key_of(sc):
    """The tune's key: the pitch it ends on (fiddle tunes end on their tonic)."""
    mel = [n for n in sc["notes"] if n["voice"] == "melody"]
    return NAMES.get(mel[-1]["midi"] % 12, "D")


def octave_for(mel, tuning):
    """The octave the banjo takes the tune in: down one (as banjo players take most fiddle tunes)
    or as written, whichever puts more of its notes in the first five frets."""
    def fits(shift):
        return sum(tuning[4] <= n["midi"] + shift <= tuning[1] + 5 for n in mel)
    return max((0, -12), key=fits)


def place(midi, tuning, hand):
    """Where a tune's note goes: (string, fret, midi) on strings 1-4, the cheapest by fret height,
    an open string preferred, near where the hand is; above the ninth fret an octave down."""
    while midi > tuning[1] + MAX_FRET:
        midi -= 12
    while midi < tuning[4]:
        midi += 12
    best = None
    for s in (1, 2, 3, 4):
        f = midi - tuning[s]
        if 0 <= f <= MAX_FRET:
            cost = (-0.6 if f == 0 else 0.25 * f + 0.35 * abs(f - hand))
            if best is None or cost < best[0]:
                best = (cost, s, f)
    return best[1], best[2], midi


def chord_fret(s, pcs, tuning, near):
    """A chord tone on string s within the first four frets, nearest the hand (open preferred)."""
    opts = [f for f in range(0, 5) if (tuning[s] + f) % 12 in pcs]
    if not opts:
        return 0
    return min(opts, key=lambda f: (abs(f - near) if f else -0.5 + 0.2 * near))


def arrange(sc, seed=1866):
    """The banjo's part for the fiddle's note data: events {t, string, fret, midi, kind, amp, dur}
    (kind: nail, brush, thumb, drop, hammer, pull)."""
    rng = np.random.default_rng(seed)
    key = key_of(sc)
    tuning = TUNINGS[key]
    mel = sorted([n for n in sc["notes"] if n["voice"] == "melody"], key=lambda n: n["unit"])
    shift = octave_for(mel, tuning)
    mel = [dict(n, midi=n["midi"] + shift) for n in mel]
    unit = 60.0 / sc["tempo_half_bpm"] / 4.0
    lead = 0.3
    when = lambda u: lead + tune._swung(u, unit, 0.55)  # noqa: E731
    starts = {round(n["unit"], 4): n for n in mel}
    ends = [mel[i + 1]["unit"] if i + 1 < len(mel) else n["unit"] + n["dur"] / unit for i, n in enumerate(mel)]
    bar1 = next((n["unit"] for n in mel if n["bar"] >= 1), 0.0)
    chords = sc.get("chords") or [key] * (mel[-1]["bar"] + 1)

    def sounding(u):
        for n, e in zip(mel, ends):
            if n["unit"] <= u + 1e-6 < e and n["t"] + n["dur"] > when(u) - 0.02:
                return n
        return None

    events = []
    hand = 0

    def ev(u, s, f, midi, kind, amp, ring_units):
        t = when(u) + rng.normal(0, 0.005)
        events.append({"t": round(float(t), 4), "unit": u, "string": s, "fret": int(f), "midi": int(midi),
                       "kind": kind, "amp": round(float(amp * np.clip(np.exp(rng.normal(0, 0.15)), 0.7, 1.25)), 3),
                       "ring": round(ring_units * unit, 4)})

    last_u = mel[-1]["unit"]
    first = bar1 - 4 * np.ceil((bar1 - mel[0]["unit"]) / 4.0 - 1e-6)
    u0 = first
    cell = 0
    while u0 < last_u - 1e-6:
        m0 = sounding(u0)
        bar = (m0 or mel[0])["bar"] if m0 else max(0, int((u0 - bar1) // 8) + 1)
        pcs = {m % 12 for m in tune.CHORD_TONES[chords[min(bar, len(chords) - 1)]]}
        accent = 1.0 if abs(((u0 - bar1) % 8)) < 1e-6 else 0.85
        # bum: the beat's note by the nail
        if m0 is not None:
            s0, f0, p0 = place(m0["midi"], tuning, hand)
            if f0:
                hand = f0
            ev(u0, s0, f0, p0, "nail", accent, 2)
            # its second note: a hammer-on or pull-off on the same string
            m1 = starts.get(round(u0 + 1, 4))
            if m1 is not None and m1["midi"] != m0["midi"]:
                s1, f1, p1 = place(m1["midi"], tuning, hand)
                if s1 == s0 and 0 < f1 - f0 <= 4:
                    ev(u0 + 1, s1, f1, p1, "hammer", 0.4, 1)
                elif s1 == s0 and 0 < f0 - f1 <= 4:
                    ev(u0 + 1, s1, f1, p1, "pull", 0.5, 1)
        # dit: a brush down three strings, the tune's note on top
        m2 = sounding(u0 + 2)
        if m2 is not None:
            s2, f2, p2 = place(m2["midi"], tuning, hand)
            if f2:
                hand = f2
            # the nail lands on the tune's string and carries on down (toward the floor, string 1)
            group = [s for s in (s2, s2 - 1, s2 - 2) if s >= 1]
            if len(group) < 2:
                group = [s2 + 1] + group
            gap = 0.0
            for k, s in enumerate(group):
                f = f2 if s == s2 else chord_fret(s, pcs, tuning, hand)
                if k == len(group) - 1 and k >= 2 and rng.random() < 0.2:
                    break  # the nail runs out before the last string
                ev(u0 + 2 + gap / unit, s, f, tuning[s] + f, "brush", 0.75 if s == s2 else 0.45 - 0.08 * k, 1)
                gap += rng.uniform(0.005, 0.014)  # a hand, not a comb
        else:
            gap = 0.0
            for k, s in enumerate((3, 2, 1)):
                f = chord_fret(s, pcs, tuning, hand)
                ev(u0 + 2 + gap / unit, s, f, tuning[s] + f, "brush", 0.5 - 0.08 * k, 1)
                gap += rng.uniform(0.005, 0.014)
        # ty: the thumb on the drone, or dropped onto a long string for the tune's note
        m3 = starts.get(round(u0 + 3, 4))
        dropped = False
        if m3 is not None and cell % 2 == 1 and m2 is not None and m3["midi"] != m2["midi"]:
            s3, f3, p3 = place(m3["midi"], tuning, hand)
            if s3 >= 2 and abs(f3 - hand) <= 3:
                ev(u0 + 3, s3, f3, p3, "drop", 0.6, 1)
                dropped = True
        if not dropped:
            ev(u0 + 3, 5, 0, tuning[5], "thumb", 0.55, 1)
        u0 += 4
        cell += 1
    # the last note: a full brush on the tonic chord, the drone with it, let ring
    pcs = {m % 12 for m in tune.CHORD_TONES[key]}
    for k, s in enumerate((4, 3, 2, 1)):
        f = chord_fret(s, pcs, tuning, 0)
        ev(last_u + k * 0.012 / unit, s, f, tuning[s] + f, "brush", 0.85, 12)
    ev(last_u + 0.04 / unit, 5, 0, tuning[5], "thumb", 0.5, 12)
    events.sort(key=lambda e: e["t"])
    return {"tune": sc["tune"], "instrument": "five-string banjo, gut strings, calfskin head",
            "key": key, "tuning": tuning, "style": "stroke style (clawhammer): bum-ditty, hammer-ons, "
            "pull-offs, drop thumb", "seed": seed, "length_s": round(events[-1]["t"] + 2.5, 3),
            "octave": shift // 12, "events": events}


def arrange_rolls(sc, seed=1949):
    """Three-finger rolls (the banjo bench): thumb, index and middle with metal picks, a note on
    every one of the tune's running notes, accents on 1, the and of 2, and 4 (3-3-2, the bluegrass
    roll's): the tune's notes go there, on the finger whose string they're on (the thumb the third
    and fourth strings, the index the second, the middle the first); between them the roll cycles
    round the fingers, never one twice running nor the one the next tune note needs, the index and
    middle on the chord's notes and the thumb on the fifth-string drone. Picked near the bridge (bright). The last note a pinch on the tonic chord."""
    import rhythm
    rng = np.random.default_rng(seed)
    key = key_of(sc)
    tuning = TUNINGS[key]
    mel = sorted([n for n in sc["notes"] if n["voice"] == "melody"], key=lambda n: n["unit"])
    shift = octave_for(mel, tuning)
    mel = [dict(n, midi=n["midi"] + shift) for n in mel]
    when, beats, last, unit = rhythm.grid(sc)
    ends = [mel[i + 1]["unit"] if i + 1 < len(mel) else n["unit"] + 4 for i, n in enumerate(mel)]
    bar1 = next((n["unit"] for n in mel if n["bar"] >= 1), 0.0)
    chords = sc.get("chords") or [key] * (mel[-1]["bar"] + 1)
    events, hand, prev, pfinger = [], 0, None, None

    def sounding(u):
        for n, e in zip(mel, ends):
            if n["unit"] <= u + 1e-6 < e:
                return n
        return None

    def ev(u, s, f, kind, amp):
        events.append({"t": round(float(when(u) + rng.normal(0, 0.004)), 4), "unit": u, "string": s,
                       "fret": int(f), "midi": int(tuning[s] + f), "kind": kind,
                       "amp": round(float(amp * np.clip(np.exp(rng.normal(0, 0.12)), 0.75, 1.2)), 3),
                       "ring": round(2 * unit, 4), "pos": round(float(rng.uniform(0.12, 0.18)), 3)})

    held = {}  # string -> fret the left hand holds for the tune's note
    for u0, bar_start, phrase_end in beats:
        for k in range(4):
            u = u0 + k
            if when(u) < rhythm.LEAD - 1e-6 or u > last + 1e-6:
                continue
            slot = int(round((u - bar1) % 8))
            bar = max(0, int((u - bar1) // 8) + 1)
            pcs = {m % 12 for m in tune.CHORD_TONES[chords[min(bar, len(chords) - 1)]]}
            n = sounding(u)
            if slot in (0, 3, 6) and n is not None:
                s, f, _ = place(n["midi"], tuning, hand)
                if f:
                    hand = f
                held = {s: f}
                # the third string is the thumb's or the index's: whichever the roll leaves free
                finger = "M" if s == 1 else ("I" if s == 2 or (s == 3 and pfinger == "T") else "T")
                ev(u, s, f, "tpick" if finger == "T" else "pick", 1.05 if slot == 0 else 0.95)
                prev, pfinger = s, finger
                continue
            # the roll goes on round the fingers (T I M T ...), never the same finger twice running,
            # nor the one the tune's next note needs; the thumb's filler is the fifth-string drone
            nxt = sounding(u + 1) if int(round((u + 1 - bar1) % 8)) in (0, 3, 6) else None
            need = None
            if nxt is not None:
                ns = place(nxt["midi"], tuning, hand)[0]
                need = "M" if ns == 1 else ("I" if ns == 2 else ("T" if ns == 4 else None))
            order = ["T", "I", "M"]
            i0 = (order.index(pfinger) + 1) % 3 if pfinger else 0
            finger = next(fg for fg in order[i0:] + order[:i0] if fg != pfinger and fg != need)
            s = {"T": 5, "I": 2, "M": 1}[finger]
            if s == prev:
                s = {"T": 3, "I": 3, "M": 2}[finger]
            f = 0 if s == 5 else held.get(s, chord_fret(s, pcs, tuning, hand))
            ev(u, s, f, "tpick" if finger == "T" else "pick", 0.6)
            prev, pfinger = s, finger
    # the last note: a pinch, thumb and middle together, the tonic chord left to ring
    pcs = {m % 12 for m in tune.CHORD_TONES[key]}
    for k, s in enumerate((3, 1, 5)):
        f = 0 if s == 5 else chord_fret(s, pcs, tuning, 0)
        ev(last + k * 0.003 / unit, s, f, "tpick" if s != 1 else "pick", 1.0 if s != 5 else 0.6)
        events[-1]["ring"] = round(12 * unit, 4)
    events.sort(key=lambda e: e["t"])
    return {"tune": sc["tune"], "instrument": "five-string banjo", "key": key, "tuning": tuning,
            "style": "three-finger rolls (forward roll, metal picks)", "seed": seed,
            "length_s": round(events[-1]["t"] + 3.0, 3), "octave": shift // 12, "events": events}


# ---------------------------------------------------------------------------------------- the sound

@njit(cache=True)
def run_string(f0, exc, gain, loss, damp, sr):
    """One string's loop: per sample its pitch (Hz), the strikes fed in, the loop's gain and its
    one-pole loss (how much duller each pass leaves it: loop_filter) and a mute (1 free, <1 a finger
    lifting or the nail landing on it), all per pass."""
    n = f0.shape[0]
    out = np.zeros(n)
    buf = np.zeros(BUF)
    w = 0
    lp = 0.0
    for i in range(n):
        a = loss[i]
        om = 2.0 * np.pi * f0[i] / sr
        # the loss filter's own delay at the note's pitch, taken off the line so it stays in tune
        pd = np.arctan2(a * np.sin(om), 1.0 - a * np.cos(om)) / om
        d = sr / f0[i] - pd
        if d < 2.0:
            d = 2.0
        x = _read(buf, w, d)
        lp = (1.0 - a) * x + a * lp
        y = exc[i] + gain[i] * damp[i] * lp
        buf[w] = y
        out[i] = lp  # what the bridge feels: the wave arriving at it, not the strike itself
        w = (w + 1) % BUF
    return out


def _pulse(sr, width, rng):
    """A strike: a raised-cosine pulse `width` s wide (the nail ~0.4 ms, flesh ~1.5 ms), a hint of
    noise for the nail's scrape."""
    m = max(3, int(width * sr))
    p = 0.5 - 0.5 * np.cos(2 * np.pi * np.arange(m) / (m - 1))
    p = p + 0.15 * rng.standard_normal(m) * p
    return p / p.sum()


def head_ir(sr, seed=1866, length=0.18):
    """The calfskin head and the pot: a membrane's modes (Bessel ratios over ~260 Hz; heavily
    damped), a dense set above under a broad 1-3 kHz rise, and the open back's air low down."""
    rng = np.random.default_rng(seed)
    t = np.arange(int(length * sr)) / sr
    f01 = HEAD_F01
    ratios = [1.0, 1.594, 2.136, 2.296, 2.653, 2.918, 3.156, 3.501, 3.600, 3.652, 4.060, 4.154, 4.601]
    modes = [(150.0, 6.0, 0.35)]  # the pot's air
    for k, r in enumerate(ratios):
        modes.append((f01 * r, HEAD_Q * rng.uniform(10, 20), (1.0 if k < 4 else 0.8) * rng.uniform(0.6, 1.0)))
    f = f01 * 4.8
    while f < 9000:
        f *= 1.0 + rng.uniform(0.02, 0.06)
        rise = np.exp(-0.5 * (np.log(f / HEAD_RISE) / 0.6) ** 2)
        amp = (0.25 + 0.75 * rise) * (1.0 if f < 4000 else (4000 / f) ** 2) * rng.uniform(0.5, 1.0)
        modes.append((f, HEAD_Q * rng.uniform(12, 25), amp))
    ir = np.zeros_like(t)
    for fr, q, a in modes:
        # a mode's peak in the response goes as amp x Q / f: scaled so `a` is that peak's height
        a = a * fr / f01 * 15.0 / q
        ir += a * np.exp(-np.pi * fr * t / q) * np.sin(2 * np.pi * fr * t + rng.uniform(0, 2 * np.pi))
    ir /= np.max(np.abs(ir))
    ir[0] += 0.6  # the bridge's own push into the air, straight through
    return ir


def t60(f):
    """A gut banjo string's ring: ~2 s low, about one up high (the head drinks it)."""
    return T60_LOW * (147.0 / f) ** 0.5


T60_HIGH = 0.25     # s: how long a partial near 2 kHz rings (the "pl" of the plunk goes at once)
T60_LOW = 1.9       # s: the note's own ring at D3 (t60 scales it by pitch)
HEAD_F01 = 260.0    # Hz: the head's first mode (its tension)
HEAD_Q = 1.0        # the head's ring (calfskin damps hard; a synthetic head rings longer)

# The strings (Sean, 2026-11-12: "can I hear the clawhammer version", the steel-strung one):
# gut, the 1870s-80s banjo's (dull, short: the default); steel, as from the 1890s on and on Uncle
# Dave Macon's records (thin steel loses its highs far slower, rings longer, takes a harder nail; the
# head pulled tighter to stand the tension). Same hand, same part, same model.
STRINGS = {
    "gut": {"T60_LOW": 1.9, "T60_HIGH": 0.25, "NAIL_W": 0.00025, "HEAD_F01": 260.0, "HEAD_RISE": 2200.0,
            "HEAD_Q": 1.0},
    "steel": {"T60_LOW": 3.0, "T60_HIGH": 0.7, "NAIL_W": 0.00018, "HEAD_F01": 300.0, "HEAD_RISE": 2800.0,
              "HEAD_Q": 1.0},
    # a modern open-back (the banjo bench, Sean 2026-11-12: "more like The Dead South", whose
    # banjoist plays open-backs, clawhammer and three-finger): steel, and a synthetic head pulled
    # tight, which rings longer and brighter than calfskin
    "modern": {"T60_LOW": 3.2, "T60_HIGH": 0.8, "NAIL_W": 0.00018, "HEAD_F01": 330.0, "HEAD_RISE": 3000.0,
               "HEAD_Q": 1.8},
}


def strings(kind="gut"):
    """Strings the banjo with gut or steel (sets the module's dials)."""
    g = globals()
    for k, v in STRINGS[kind].items():
        g[k] = v
    return kind
F_HIGH = 2000.0


def loop_filter(f0, sr, t_low, t_high, f_high=F_HIGH):
    """The loop's gain and one-pole coefficient per pass so the note rings t_low and its partials
    near f_high ring t_high (two decay times set the filter; Valimaki-style loss design, solved by
    bisection). Gut strings and a head that takes the highs first: a banjo's bright strike and dull
    ring, where a uniform loss (take 1, 2) left every partial ringing as long as the note."""
    g0 = 10 ** (-3.0 / (t_low * f0))
    g2 = 10 ** (-3.0 / (np.minimum(t_high, t_low) * f0))
    w0, w2 = 2 * np.pi * f0 / sr, 2 * np.pi * f_high / sr
    mag = lambda a, w: (1 - a) / np.sqrt(1 - 2 * a * np.cos(w) + a * a)  # noqa: E731
    want = g2 / g0
    lo, hi = np.zeros_like(f0), np.full_like(f0, 0.999)
    for _ in range(40):
        a = 0.5 * (lo + hi)
        r = mag(a, w2) / mag(a, w0)
        lo = np.where(r > want, a, lo)
        hi = np.where(r > want, hi, a)
    a = 0.5 * (lo + hi)
    return g0 / mag(a, w0), a


def render(part, sr=common.SR, seed=1866):
    srm = sr * OVER
    rng = np.random.default_rng(seed)
    n = int(part["length_s"] * srm)
    tuning = {int(k): v for k, v in part["tuning"].items()}
    total = np.zeros(n)
    click = np.zeros(n)
    pop = np.zeros(n)
    pk = _pulse(srm, 0.0012, rng)
    for s in (1, 2, 3, 4, 5):
        evs = [e for e in part["events"] if e["string"] == s]
        midi = np.full(n, float(tuning[s]))
        # no string is dead in tune (gut drifts, pegs slip): a few cents off, wandering slowly
        drift = lfilter(*butter(1, 1.5 / (srm / 2)), rng.standard_normal(n))
        drift = rng.normal(0, 3.0) + 1.5 * drift / (np.std(drift) + 1e-9)
        exc = np.zeros(n)
        damp = np.ones(n)
        for j, e in enumerate(evs):
            i0 = int(e["t"] * srm)
            if i0 >= n:
                continue
            nxt = int(evs[j + 1]["t"] * srm) if j + 1 < len(evs) else n
            # the finger holds the fret until the next strike on this string or the ring's end
            ring_end = min(nxt, i0 + int(max(e["ring"], 0.05) * srm))
            midi[i0:nxt] = e["midi"]
            # a hard strike stretches the string: a few cents sharp, settling in ~60 ms
            k = np.arange(nxt - i0) / srm
            cents = 9.0 * e["amp"] * np.exp(-k / 0.06) * (e["kind"] not in ("hammer", "pull"))
            midi[i0:nxt] += cents / 100.0
            if e["fret"] > 0 and ring_end < nxt:
                # the finger leaves: a short mute, then the open string (quiet: the mute took it)
                m = int(0.03 * srm)
                damp[ring_end:ring_end + m] = 0.6
                midi[ring_end:nxt] = tuning[s]
            if e["kind"] in ("nail", "brush", "drop", "thumb", "pick", "tpick"):
                damp[i0:i0 + int(0.004 * srm)] = 0.93  # the nail lands on the moving string (not a gate)
            width = {"nail": NAIL_W, "brush": NAIL_W * 1.5, "drop": 0.0012, "thumb": 0.0015,
                     "hammer": 0.0009, "pull": 0.0007, "pick": PICK_W, "tpick": PICK_W * 1.3}[e["kind"]]
            width *= rng.uniform(0.7, 1.4)  # no two strikes the same nail
            p = _pulse(srm, width, rng) * e["amp"] * (0.5 if e["kind"] == "hammer" else 1.0)
            # where it lands: a comb at the strike point's share of the period
            period = srm / common.hz(e["midi"])
            lag = int(round((e["pos"] if "pos" in e else rng.uniform(0.2, 0.34)) * period))
            if e["kind"] not in ("hammer", "pull"):
                pseg = pop[i0:i0 + len(pk)]
                pseg += pk[:len(pseg)] * e["amp"] * (0.6 if e["kind"] in ("thumb", "drop") else 1.0)
            shaped = np.zeros(len(p) + lag)
            shaped[:len(p)] += p
            shaped[lag:lag + len(p)] -= p
            seg = exc[i0:i0 + len(shaped)]
            seg += shaped[:len(seg)] * 0.5
            if e["kind"] in ("nail", "brush", "pick", "tpick"):
                L = int((0.006 if e["kind"] == "brush" else 0.003) * srm)  # the nail's (or pick's) scrape
                nb = rng.standard_normal(L) * np.exp(-np.arange(L) / (0.0012 * srm))
                cseg = click[i0:i0 + len(nb)]
                cseg += CLICK * e["amp"] * nb[:len(cseg)]
        f0 = common.hz(midi + drift / 100.0)
        for level, decay, cents in POLS:
            fp = f0 * 2.0 ** (cents / 1200.0)
            gain, loss = loop_filter(fp, srm, decay * t60(fp), decay * T60_HIGH)
            out = run_string(fp, exc, gain, loss, damp, float(srm))
            total += level * out * (0.8 if s == 5 else 1.0)
    b, a = butter(2, [2000 / (srm / 2), 9000 / (srm / 2)], "band")
    total += lfilter(b, a, click) * np.std(total) * 4
    total += pop * POP * np.std(total) / (np.std(pop) + 1e-12)
    y = common.resample(total, srm, sr)
    y = fftconvolve(y, head_ir(sr, seed))[: len(y)]
    b, a = butter(2, 80 / (sr / 2), "high")
    return lfilter(b, a, y)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    src = args[0] if os.path.isabs(args[0]) else os.path.join(HERE, args[0])
    sc = json.load(open(src))
    strings(opt.get("strings", "gut"))
    part = arrange_rolls(sc) if opt.get("style") == "rolls" else arrange(sc)
    if "part" in opt:
        json.dump(part, open(opt["part"], "w"), indent=1)
    name = os.path.splitext(os.path.basename(src))[0]
    suffix = ("" if opt.get("strings", "gut") == "gut" else "_" + opt["strings"]) + \
        ("_rolls" if opt.get("style") == "rolls" else "")
    out = opt.get("out", os.path.join(common.BUILD, "dry", f"{name}_banjo{suffix}.wav"))
    y = render(part)
    common.write_wav(out, common.normalise(y))
    kinds = {}
    for e in part["events"]:
        kinds[e["kind"]] = kinds.get(e["kind"], 0) + 1
    print(f"{out}: {part['tune']} in {part['key']} ({part['length_s']} s), {kinds}")


if __name__ == "__main__":
    main()
