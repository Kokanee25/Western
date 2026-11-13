#!/usr/bin/env python3
"""Any fiddle tune in ABC as the fiddler's note data (#790): read through music21 (repeats played as written,
ties joined, triplets and rests kept), each bar's chord worked out from its notes, then played by
tune.arrange's old-time rules (strings and fingers, the shuffle, drones, double stops, slides).

    python3 experiments/sound_lab/fiddle/abc_tune.py ryansMammoth/ArkansasTravellerReel.abc arkansas_traveller.json
    (a path inside music21's corpus, or any .abc file; --tempo=108 half notes a minute,
     --times=2 the whole tune played that many times, as for a dance, --title="..." the name it goes by)

The chords: the ABC's own chord symbols where it has them ("G", "Em", "Cadd9" as C); otherwise, of the key's three (I, IV and V of K:'s major; D, G and A when it isn't one of
tune.CHORD_TONES' keys), the one whose notes take up most of the bar, the bar's first note counted double; a tie keeps the bar
before's. Only tunes that are public domain (traditional, or old books like Ryan's Mammoth
Collection, 1883, and O'Neill's, 1903).
"""
import json
import os
import re
import sys

from music21 import converter, corpus, harmony, note

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tune  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
KEYS = {"D": ["D", "G", "A"], "G": ["G", "C", "D"], "A": ["A", "D", "E"]}


def triads(key):
    return {c: {m % 12 for m in tune.CHORD_TONES[c]} for c in KEYS.get(key, KEYS["D"])}


def read(path, times=1):
    full = path if os.path.exists(path) else str(corpus.getWork(path))
    text = open(full, errors="ignore").read()
    title = re.search(r"^T:\s*(.*)$", text, re.M).group(1).strip()
    book = re.search(r"^B:\s*(.*)$", text, re.M)
    unit_len = re.search(r"^L:\s*(\d+)/(\d+)", text, re.M)
    unit_q = 4.0 * int(unit_len.group(1)) / int(unit_len.group(2)) if unit_len else 0.5
    key = re.search(r"^K:\s*([A-G])\s*$", text, re.M)
    score = converter.parse(full)
    out, bar, written, starts, total = [], -1, [], [], 0.0
    for m in played_bars(score) * times:
        bar += 1
        starts.append(round(total, 4))  # where each bar begins, in the tune's running notes
        total += sum(round(float(n.quarterLength) / unit_q, 4) for n in m.recurse().notesAndRests
                     if not isinstance(n, harmony.Harmony) and n.quarterLength > 0)
        written.append(next((_chord_name(h) for h in m.recurse().getElementsByClass(harmony.Harmony)
                             if _chord_name(h)), None))
        for n in m.recurse().notesAndRests:
            if isinstance(n, harmony.Harmony) or n.quarterLength == 0:
                continue  # a "0"/"4" in quotes is the book's fingering, read as a chord symbol; grace notes
            units = round(float(n.quarterLength) / unit_q, 4)
            _add(out, n, units, bar)
    return title, (book.group(1).strip() if book else full), out, bar + 1, (key.group(1) if key else "D"), written, starts


def _chord_name(h):
    """A written chord symbol as the arranger's name: its root, and "m" if minor (Cadd9 -> C, Em7 -> Em);
    None for what isn't a chord (a book's fingering digits, read as symbols)."""
    try:
        root = h.root().name.replace("-", "b")
    except Exception:  # noqa: BLE001
        return None
    if not h.figure or not h.figure[0].isalpha():
        return None
    minor = "m" in h.figure[1:3] and not h.figure[1:4].startswith("maj")
    name = root + ("m" if minor else "")
    return name if name in tune.CHORD_TONES else None


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


def chords_of(notes, n_bars, key="D"):
    tri = triads(key)
    chords, last = [], next(iter(tri))
    for b in range(n_bars):
        mine = [(m, u) for m, u, bb in notes if bb == b and m is not None]
        if not mine:
            chords.append(last)
            continue
        score = {}
        for name, pcs in tri.items():
            score[name] = sum(u * (2 if i == 0 else 1) for i, (m, u) in enumerate(mine) if m % 12 in pcs)
        best = max(score, key=lambda k: (score[k], k == last))
        chords.append(best)
        last = best
    return chords


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    tempo = float(next((a.split("=")[1] for a in sys.argv[1:] if a.startswith("--tempo=")), 108))
    times = int(next((a.split("=")[1] for a in sys.argv[1:] if a.startswith("--times=")), 1))
    title, book, notes, n_bars, key, written, starts = read(args[0], times)
    chords = chords_of(notes, n_bars, key)
    if any(written):  # the song's own chords where it writes them (each held until the next)
        last = written[next(i for i, c in enumerate(written) if c)]
        chords = [last := (c or last) for c in written]
    title = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--title=")), title)
    d = tune.arrange(tempo_half=tempo, phrases=[(notes, 0)], chords=chords, title=title.title(),
                     source=(f"{book}, via music21's corpus ({args[0]}); traditional, public domain"
                             if not os.path.exists(args[0]) else book))
    d["chords"] = chords
    d["bar_units"] = starts  # each bar's start (the beat grid's downbeats: rhythm.grid)
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
