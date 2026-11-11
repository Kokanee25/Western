#!/usr/bin/env python3
"""Any fiddle tune in ABC as the fiddler's note data (#790): read through music21 (repeats played as written,
ties joined, triplets and rests kept), each bar's chord worked out from its notes, then played by
tune.arrange's old-time rules (strings and fingers, the shuffle, drones, double stops, slides).

    python3 experiments/sound_lab/fiddle/abc_tune.py ryansMammoth/ArkansasTravellerReel.abc arkansas_traveller.json
    (a path inside music21's corpus, or any .abc file; --tempo=108 half notes a minute)

The chords: of D, G and A (the key of D's three; a tune in another key needs its own three), the
one whose notes take up most of the bar, the bar's first note counted double; a tie keeps the bar
before's. Only tunes that are public domain (traditional, or old books like Ryan's Mammoth
Collection, 1883, and O'Neill's, 1903).
"""
import json
import os
import re
import sys

from music21 import converter, corpus, note

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tune  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
TRIADS = {"D": {2, 6, 9}, "G": {7, 11, 2}, "A": {9, 1, 4}}


def read(path):
    full = path if os.path.exists(path) else str(corpus.getWork(path))
    text = open(full, errors="ignore").read()
    title = re.search(r"^T:\s*(.*)$", text, re.M).group(1).strip()
    book = re.search(r"^B:\s*(.*)$", text, re.M)
    unit_len = re.search(r"^L:\s*(\d+)/(\d+)", text, re.M)
    unit_q = 4.0 * int(unit_len.group(1)) / int(unit_len.group(2)) if unit_len else 0.5
    score = converter.parse(full)
    out, bar = [], -1
    for m in played_bars(score):
        bar += 1
        for n in m.recurse().notesAndRests:
            units = round(float(n.quarterLength) / unit_q, 4)
            _add(out, n, units, bar)
    return title, (book.group(1).strip() if book else full), out, bar + 1


def played_bars(score):
    """The bars in the order they're played: each part from a start repeat (or the last part's end)
    to an end repeat, twice. (music21's expandRepeats takes an end repeat with no start repeat back
    to the tune's start, playing A A B A A B for A A B B.)"""
    from music21 import bar as m21bar
    measures = list(score.recurse().getElementsByClass("Measure"))
    order, start = [], 0
    for i, m in enumerate(measures):
        left = m.leftBarline
        if isinstance(left, m21bar.Repeat) and left.direction == "start":
            start = i
        right = m.rightBarline
        if isinstance(right, m21bar.Repeat) and right.direction == "end":
            part = measures[start:i + 1]
            order += part + part
            start = i + 1
    order += measures[start:]
    return order


def _add(out, n, units, bar):
    if True:
        if isinstance(n, note.Note):
            if n.tie is not None and n.tie.type in ("continue", "stop") and out and out[-1][0] == n.pitch.midi:
                out[-1] = (out[-1][0], out[-1][1] + units, out[-1][2])
                return
            out.append((n.pitch.midi, units, bar))
        elif n.isChord:
            out.append((max(p.midi for p in n.pitches), units, bar))  # the top note as the tune
        else:
            out.append((None, units, bar))


def chords_of(notes, n_bars):
    chords, last = [], "D"
    for b in range(n_bars):
        mine = [(m, u) for m, u, bb in notes if bb == b and m is not None]
        if not mine:
            chords.append(last)
            continue
        score = {}
        for name, pcs in TRIADS.items():
            score[name] = sum(u * (2 if i == 0 else 1) for i, (m, u) in enumerate(mine) if m % 12 in pcs)
        best = max(score, key=lambda k: (score[k], k == last))
        chords.append(best)
        last = best
    return chords


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    tempo = float(next((a.split("=")[1] for a in sys.argv[1:] if a.startswith("--tempo=")), 108))
    title, book, notes, n_bars = read(args[0])
    chords = chords_of(notes, n_bars)
    d = tune.arrange(tempo_half=tempo, phrases=[(notes, 0)], chords=chords, title=title.title(),
                     source=f"{book}, via music21's corpus ({args[0]}); traditional, public domain")
    d["chords"] = chords
    out = args[1] if len(args) > 1 else os.path.join(HERE, re.sub(r"\W+", "_", title.lower()).strip("_") + ".json")
    if not os.path.isabs(out):
        out = os.path.join(HERE, out)
    json.dump(d, open(out, "w"), indent=1)
    mel = [n for n in d["notes"] if n["voice"] == "melody"]
    lo, hi = min(n["midi"] for n in mel), max(n["midi"] for n in mel)
    print(f"{out}: {title}, {len(mel)} melody notes ({lo}-{hi}), {len(d['notes']) - len(mel)} drones/doubles, "
          f"{len(d['strokes'])} strokes, {d['length_s']} s; chords {' '.join(chords)}")


if __name__ == "__main__":
    main()
