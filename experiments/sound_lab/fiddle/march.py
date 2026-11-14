#!/usr/bin/env python3
"""A march for the travelling band (#822): Yankee Doodle as a quickstep, the tune every American
band of the 1880s played (traditional; the words and tune long public domain), written here as note
data from the common setting: the verse and chorus, eight bars each, played twice, in F (a
band key that keeps the chorus's top in a cornet's easy range), 2/4 at a quarter = 116. The drums'
two-bar roll-off comes first, so the band's first note is at bar 2's top.

    python3 experiments/sound_lab/fiddle/march.py       -> yankee_doodle.json

The note data: {"notes": [{t, dur, midi, voice: "melody", bar, unit, accent}], "beats": [[t,
bar_start, phrase_end]], ...}: units are eighths from bar 0; beats two a bar (quarters).
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
# in G, eighths unless a number follows (quarters as 2); -2 to F
G = {"D4": 62, "E4": 64, "F#4": 66, "G4": 67, "A4": 69, "B4": 71, "C5": 72, "D5": 74, "E5": 76, "F#5": 78,
     "G5": 79, "A5": 81}
BARS = [
    "G4 G4 A4 B4", "G4 B4 A4 D4", "G4 G4 A4 B4", "G4:2 F#4:2",
    "G4 G4 A4 B4", "C5 B4 A4 G4", "F#4 D4 E4 F#4", "G4:2 G4:2",
    "E5 F#5 E5 D5", "E5 F#5 G5:2", "D5 E5 D5 C5", "B4:2 G4:2",
    "E5 F#5 E5 D5", "E5 F#5 G5 E5", "D5 G5 F#5 A5", "G5:2 G5:2",
]
BPM = 116.0
TRANSPOSE = -2
INTRO_BARS = 2


def build(times=2):
    q = 60.0 / BPM
    e = q / 2
    t0 = 0.4 + INTRO_BARS * 2 * q
    notes, beats = [], []
    unit = 0.0
    for rep in range(times):
        for b, bar in enumerate(BARS):
            barno = rep * len(BARS) + b
            bt = t0 + barno * 2 * q
            beats.append([round(bt, 4), True, False])
            beats.append([round(bt + q, 4), False, (b % 4) == 3])
            u = 0.0
            for tok in bar.split():
                name, _, ln = tok.partition(":")
                d = float(ln or 1)
                t = bt + u * e
                notes.append({"t": round(t, 4), "dur": round(d * e, 4), "midi": G[name] + TRANSPOSE, "voice": "melody",
                              "bar": barno, "unit": barno * 4 + u, "accent": 1.0 if u in (0.0, 2.0) else 0.7})
                u += d
    end = t0 + times * len(BARS) * 2 * q
    return {"tune": "Yankee Doodle (quickstep)", "source": "traditional; common setting, written out for #822",
            "tempo_quarter_bpm": BPM, "length_s": round(end + 0.3, 3), "notes": notes, "beats": beats,
            "intro_s": round(t0, 4)}


if __name__ == "__main__":
    sc = build()
    json.dump(sc, open(os.path.join(HERE, "yankee_doodle.json"), "w"), indent=0)
    print(f"yankee_doodle.json: {len(sc['notes'])} notes, {sc['length_s']:.1f} s")
