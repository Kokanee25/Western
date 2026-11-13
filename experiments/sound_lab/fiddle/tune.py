#!/usr/bin/env python3
"""Soldier's Joy as the fiddler's note data (issue #790): the tune, then how an old-time dance
fiddler plays it, written out note by note so the sound and (later) his hands come from one source.

    python3 experiments/sound_lab/fiddle/tune.py          # writes soldiers_joy.json beside this file

The tune: the A part of "The Soldier's Joy" as O'Neill's *Music of Ireland* (1903; No. 1642) prints
it, from music21's corpus (oneills1850); the tune is traditional and the book public domain. Its A
part is the one old-time fiddlers play ("AFDF AFDF | A2 d2 d2 cB"). Played twice, the second time
with the turn varied, then a closing D: about 20 s.

How it's played (our own rules, from how old-time fiddling is described, not from any code):
- first position, standard tuning (G3 D4 A4 E5); each note on its string and finger, open strings
  where a fiddler takes them;
- the bow: the "Nashville shuffle" on runs of eighths (two slurred, two separate: long short short),
  each stroke the other way; quarter notes a stroke each; the stroke's bow speed from its length;
- swung a little (eighth pairs 55:45), pushed off the beat (the slur's start accented);
- drones and double stops: the open string beside the melody's, when it's in the chord, bowed with
  it softly (the D under A-string notes in a D bar, the A over the D string's); the long d's and the
  last note full double stops;
- slides: up into the long notes and the bar's first F#, from a semitone or a tone under;
- small differences: timing within ±7 ms, pressure ±8%, a stopped note's finger a few cents off
  (s.d. 5), by a fixed seed (the same file every run).

Each note: t, dur (s), midi, cents (where the finger lands, off the true pitch), string (G D A E), finger (0 open, 1-4), stroke (index), slur (tied to
the note before in one stroke), bow (down/up), speed (bow m/s), pressure (0-1, of the most a
fiddler leans), pos (bow from the bridge, of the string's length), accent, slide_from (midi or
null), slide_s, voice (melody, drone, double); a melody note also its bar (0 the pickup) and unit
(its start in the tune's running notes, unswung: the beat grid a banjo plays to).
Strokes: index, t0, t1, dir, strings, pressure, speed, pos.
"""
import json
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))

# O'Neill's 1642, the A part (L:1/8, cut time), in our own spelling: (pitch, eighths). Lower case
# is the octave above as in ABC; ' is "a" up. A trailing ' marks a held note (2 eighths).
ABC_A = "FG|AFDF AFDF|A2 d2 d2 cB|AFDF AFDF|G2E2 E2 FG|AFDF AFDF|A2 d2 d2 de|fafd egec|d2 d2 d2"
# Second time: the old-time fiddler's turn into the last bar (the D's held, the end let ring).
ABC_A2 = "FG|AFDF AFDF|A2 d2 d2 cB|AFDF AFDF|G2E2 E2 FG|AFDF AFDF|A2 d2 d2 de|fafd egec|d6"

PITCH = {"C": 60, "D": 62, "E": 64, "F": 66, "G": 67, "A": 69, "B": 71,  # K:D (F and C sharp)
         "c": 73, "d": 74, "e": 76, "f": 78, "g": 79, "a": 81, "b": 83}
# The bars' chords (D major; bar 4's G E E the dominant, A). (D major, the A bar the dominant).
CHORDS_A = ["D", "D", "D", "D", "A", "D", "D", "D", "D"]  # pickup counts as bar 0
CHORD_TONES = {"D": {62, 66, 69}, "A": {69, 73, 64}, "G": {67, 71, 62}, "E": {64, 68, 71}, "C": {60, 64, 67}}
# the minor chords a song writes over its notes (abc_tune reads them from the ABC's chord symbols)
CHORD_TONES.update({"Em": {64, 67, 71}, "Am": {69, 72, 64}, "Bm": {71, 74, 66}, "Dm": {62, 65, 69}, "F": {65, 69, 60},
                    "Gm": {67, 70, 62}, "Bb": {70, 62, 65}})

STRINGS = {"G": 55, "D": 62, "A": 69, "E": 76}
ORDER = ["G", "D", "A", "E"]


def string_finger(midi):
    """First position: the highest string the note is at or above, fingers by semitones (0 open,
    1 a tone up, 2 two or three semitones (low/high 2nd), 3 a fourth, 4 a fifth)."""
    best = None
    for s in ORDER:
        o = STRINGS[s]
        if o <= midi <= o + 7:
            best = s
    # the 4th finger is rare in old-time playing: the open string above takes it
    s = best
    semis = midi - STRINGS[s]
    finger = {0: 0, 1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3, 7: 4}[semis]
    return s, finger


def parse(abc):
    """(midi, eighths) list and the bar each note starts in (the pickup is bar 0)."""
    out = []
    bar = 0
    i = 0
    toks = abc.replace(" ", "")
    while i < len(toks):
        c = toks[i]
        if c == "|":
            bar += 1
            i += 1
            continue
        n = 1
        j = i + 1
        while j < len(toks) and toks[j].isdigit():
            n = n * 1 if j == i + 1 else n
            j += 1
        if j > i + 1:
            n = int(toks[i + 1:j])
        out.append((PITCH[c], n, bar))
        i = j
    return out


def arrange(tempo_half=108.0, seed=1882, phrases=None, chords=None, title=None, source=None):
    """The tune as played. `phrases`: [(notes, rep)], notes [(midi or None for a rest, units, bar)], a
    unit the tune's running note (an eighth in Soldier's Joy's cut time, a sixteenth in a 2/4 reel);
    `chords`: a chord name per bar (D, G, A). Default: Soldier's Joy."""
    rnd = random.Random(seed)
    eighth = 60.0 / tempo_half / 4.0
    swing = 0.55
    notes = []
    strokes = []
    t_eighths = 0.0
    lead = 0.3  # a breath before the first note
    if phrases is None:
        phrases = [(parse(ABC_A), 0), (parse(ABC_A2), 1)]
        chords = CHORDS_A
        title = "Soldier's Joy (A part twice)"
        source = ("O'Neill's Music of Ireland (1903) No. 1642, via music21's corpus (oneills1850); "
                  "traditional, public domain")
    direction = "up"  # the pickup comes up-bow so the bar starts down
    for phrase, rep in phrases:
        run = 0  # position within a run of eighths, for the shuffle
        prev_dur = None
        last_bar = -1
        for k, (midi, n8, bar) in enumerate(phrase):
            if bar != last_bar:
                run = 0  # the shuffle starts again on each bar's downbeat
                last_bar = bar
            chord = chords[min(bar, len(chords) - 1)]
            if midi is None:  # a rest: the bow lifts, the time goes by
                t_eighths += n8
                run = 0
                prev_dur = None
                continue
            # swing: an eighth on the beat is long, off it short
            on_beat = (t_eighths % 2) < 1e-6
            start = lead + _swung(t_eighths, eighth, swing)
            end = lead + _swung(t_eighths + n8, eighth, swing)
            dur = end - start
            s, f = string_finger(midi)
            slur = False
            if n8 < 1 and prev_dur is not None and prev_dur < 1:
                slur = True  # a triplet's notes in one bow
            elif n8 == 1:
                # Nashville shuffle on runs of eighths: notes 1-2 slurred, 3 and 4 separate.
                if prev_dur == 1 and run % 4 == 1 and k > 0:
                    slur = True
                run += 1
            else:
                run = 0
            prev_dur = n8
            if not slur:
                direction = "down" if direction == "up" else "up"
                strokes.append({"index": len(strokes), "t0": start, "t1": end, "dir": direction,
                                "strings": [s], "pressure": 0.0, "speed": 0.0, "pos": 0.0})
            st = strokes[-1]
            st["t1"] = end
            if s not in st["strings"]:
                st["strings"].append(s)
            accent = 1.0 if (not slur and run % 4 == 1) or n8 >= 2 else (0.7 if on_beat else 0.55)
            if bar >= 1 and k > 0 and on_beat and (t_eighths % 4) < 1e-6:
                accent = max(accent, 0.9)
            jitter = rnd.uniform(-0.007, 0.007)
            pressure = min(1.0, (0.55 + 0.3 * accent) * rnd.uniform(0.92, 1.08))
            slide = None
            if n8 >= 4 and midi == 74:
                slide = 73  # into the held d from its leading note
            elif n8 >= 4 and f > 0:
                slide = midi - 1  # into any other held stopped note from a semitone under
            elif bar >= 1 and midi == 66 and on_beat and rnd.random() < 0.5:
                slide = 65  # the bar's F# smeared up from F natural, as old-time players do
            # where the finger lands: a few cents off each time (an open string is where it's tuned)
            cents = 0.0 if f == 0 else round(rnd.gauss(0.0, 5.0), 1)
            notes.append({"t": round(start + jitter, 4), "dur": round(dur, 4), "midi": midi, "cents": cents, "string": s,
                          "finger": f, "stroke": st["index"], "slur": slur, "bow": st["dir"],
                          "pressure": round(pressure, 3), "accent": round(accent, 2), "pos": 0.0,
                          "speed": 0.0, "slide_from": slide, "slide_s": 0.06 if slide else 0.0,
                          "voice": "melody", "bar": bar, "unit": round(t_eighths, 4)})
            # drones and double stops
            if n8 >= 2 and midi in (74, 69):
                # the held d with F# under it on the D string (a sixth); the open A with the open D
                lower = 66 if midi == 74 else 62
                ls, lf = string_finger(lower)
                notes.append(_extra(notes[-1], lower, ls, lf, "double", 0.85))
                if ls not in st["strings"]:
                    st["strings"].append(ls)
            else:
                beside = {"G": "D", "D": "A", "A": "D", "E": "A"}[s]
                if STRINGS[beside] % 12 in {m % 12 for m in CHORD_TONES[chord]} and (n8 >= 2 or on_beat or slur):
                    notes.append(_extra(notes[-1], STRINGS[beside], beside, 0, "drone", 0.45))
                    if beside not in st["strings"]:
                        st["strings"].append(beside)
            t_eighths += n8
        if rep == 0:
            pass
    # the last d6: a full D chord, A string and D string (d over the open A, F# below on the D)
    last = notes[-1] if notes[-1]["voice"] == "melody" else [n for n in notes if n["voice"] == "melody"][-1]
    last["dur"] = round(last["dur"] + 0.6, 4)
    for n in notes:
        if n["t"] >= last["t"] - 1e-6 and n is not last:
            n["dur"] = last["dur"]
    # bow speed and position per stroke: the bow covers a length chosen by the stroke's length
    # (short strokes ~0.15 m, long ~0.45 m), pressed near the bridge for the old-time bite.
    for st in strokes:
        length = st["t1"] - st["t0"]
        travel = min(0.5, 0.12 + 0.5 * length)
        st["speed"] = round(travel / max(length, 0.05), 3)
        mine = [n for n in notes if n["stroke"] == st["index"] and n["voice"] == "melody"]
        st["pressure"] = round(max(n["pressure"] for n in mine), 3)
        st["pos"] = 0.09 if length < 0.5 else 0.11
        st["t0"] = round(st["t0"], 4)
        st["t1"] = round(st["t1"], 4)
        for n in notes:
            if n["stroke"] == st["index"]:
                n["speed"] = st["speed"]
                n["pos"] = st["pos"]
    notes.sort(key=lambda n: (n["t"], n["voice"] != "melody"))
    return {"tune": title,
            "source": source,
            "tempo_half_bpm": tempo_half, "tuning": STRINGS, "seed": seed,
            "length_s": round(max(n["t"] + n["dur"] for n in notes), 3), "notes": notes, "strokes": strokes}


def _swung(e, eighth, swing):
    pair = int(e // 2)
    within = e - pair * 2
    first = 2 * swing
    return pair * 2 * eighth + (within * swing * 2 if within <= 1 else first + (within - 1) * (2 - first)) * eighth


def _extra(melody, midi, s, f, voice, level):
    n = {k: v for k, v in melody.items() if k not in ("bar", "unit")}
    n.update({"midi": midi, "cents": 0.0 if f == 0 else round(melody["cents"] * -0.5, 1), "string": s, "finger": f,
              "voice": voice, "slur": melody["slur"],
              "pressure": round(melody["pressure"] * level, 3), "slide_from": None, "slide_s": 0.0})
    return n


if __name__ == "__main__":
    d = arrange()
    path = os.path.join(HERE, "soldiers_joy.json")
    with open(path, "w") as f:
        json.dump(d, f, indent=1)
    mel = [n for n in d["notes"] if n["voice"] == "melody"]
    print(f"{path}: {len(mel)} melody notes, {len(d['notes']) - len(mel)} drones/doubles, "
          f"{len(d['strokes'])} strokes, {d['length_s']} s")
