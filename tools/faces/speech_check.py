#!/usr/bin/env python3
"""How well FaceSpeech's letter rules see a line: every line the brains say (tools/faces/
speech_dump.gd's JSON), its mouth classes against espeak-ng's phonemes for the same line (the
mbrola us1 voice, 160 words a minute; espeak-ng and mbrola run as programs, nothing of theirs is
kept), and its length against espeak-ng's.

    godot --headless -s res://tools/faces/speech_dump.gd -- --out=build/faces/speech_plans.json
    python3 tools/faces/speech_check.py build/faces/speech_plans.json [--wpm=160] [--show=10]

Classes are what the lips show: SHUT (m b p), BITE (f v), ROUND (oo, w, oh, aw), OPEN (ah, a, e),
WIDE (ee, i, ay), TONGUE (everything the lips barely take part in). Agreement is 1 - the edit
distance between the two class sequences over espeak's length; the lip sounds (SHUT, BITE) are
also counted alone, since a missed or a false closure is what a viewer sees first.
"""
import json
import subprocess
import sys

MINE = {"m": "SHUT", "f": "BITE", "w": "ROUND", "uw": "ROUND", "uh": "ROUND", "ow": "ROUND",
        "aa": "OPEN", "ao": "OPEN", "ae": "OPEN", "eh": "OPEN", "ah": "OPEN", "er": "OPEN",
        "iy": "WIDE", "ih": "WIDE", "y": "WIDE", "gasp": "OPEN", "hum": "TONGUE", "catch": "TONGUE"}
GLIDES = {("ae", "iy"): "WIDE", ("aa", "ih"): "OPEN", ("aa", "uw"): "OPEN", ("ow", "iy"): "ROUND"}
VOWELS = {"aa", "ao", "ae", "eh", "iy", "ih", "er", "ah", "uw", "uh", "ow"}
ESPEAK = {**{p: "OPEN" for p in ["a", "A", "{", "V", "@", "E", "AI", "aI", "aU", "Q", "3", "r=", "@`", "3:", "A:",
                                   "A@", "e@", "aI@", "aU@", "@L"]},
          **{p: "WIDE" for p in ["i", "I", "e", "eI", "EI", "j", "i:", "i@", "I@", "I2", "i@3"]},
          **{p: "ROUND" for p in ["u", "U", "oU", "@U", "w", "OI", "u:", "U@", "o@", "o", "O", "O:", "O@", "Or"]},
          **{p: "SHUT" for p in ["p", "b", "m"]},
          **{p: "BITE" for p in ["f", "v"]}}


def mine(words):
    out = []
    for w in words:
        s = w["sounds"]
        i = 0
        while i < len(s):
            if i + 1 < len(s) and (s[i], s[i + 1]) in GLIDES:
                out.append(GLIDES[(s[i], s[i + 1])])
                i += 2
                continue
            out.append(MINE.get(s[i], "TONGUE"))
            i += 1
    return out


def espeak(text, wpm):
    pho = subprocess.run(["espeak-ng", "-v", "mb-us1", "-s", str(wpm), "-q", "--pho", text],
                         capture_output=True, text=True).stdout
    seq, t, first, last = [], 0.0, None, 0.0
    for line in pho.splitlines():
        b = line.split()
        if len(b) < 2:
            continue
        d = float(b[1]) / 1000
        if b[0] != "_":
            seq.append(ESPEAK.get(b[0].replace("_h", ""), "TONGUE"))
            first = t if first is None else first
            last = t + d
        t += d
    return seq, (last - (first or 0.0))


def edits(a, b):
    """Levenshtein distance, and the alignment's pairs (a index, b index or None)."""
    D = [[0] * (len(b) + 1) for _ in range(len(a) + 1)]
    for i in range(len(a) + 1):
        D[i][0] = i
    for j in range(len(b) + 1):
        D[0][j] = j
    for i in range(1, len(a) + 1):
        for j in range(1, len(b) + 1):
            D[i][j] = min(D[i - 1][j] + 1, D[i][j - 1] + 1, D[i - 1][j - 1] + (a[i - 1] != b[j - 1]))
    return D[len(a)][len(b)]


def main():
    args = dict(x.split("=", 1) for x in sys.argv[1:] if x.startswith("--"))
    path = next((x for x in sys.argv[1:] if not x.startswith("--")), "build/faces/speech_plans.json")
    wpm = int(args.get("--wpm", 160))
    show = int(args.get("--show", 10))
    plans = json.load(open(path))
    rows = []
    lips = {"SHUT": [0, 0, 0], "BITE": [0, 0, 0]}   # espeak's, ours, both (by alignment of counts)
    for p in plans:
        if not any(ch in p["text"].lower() for ch in "aeiouy"):
            continue   # the groans and chokes: espeak-ng says them as letters
        a, ref_len = espeak(p["text"], wpm)
        b = mine(p["words"])
        e = edits(a, b)
        voice = p["voice"][1] - p["voice"][0]
        rows.append((1 - e / max(len(a), 1), voice / max(ref_len, 1e-3), p["text"], a, b))
        for k in lips:
            lips[k][0] += a.count(k)
            lips[k][1] += b.count(k)
            lips[k][2] += min(a.count(k), b.count(k))
    agree = sum(r[0] for r in rows) / len(rows)
    ratio = sorted(r[1] for r in rows)
    print("speech_check: %d lines; mouth classes agree with espeak-ng %.0f%% (mean); length ours/espeak at "
          "%d wpm: median %.2f, 10th-90th %.2f-%.2f" % (len(rows), agree * 100, wpm, ratio[len(ratio) // 2],
                                                       ratio[len(ratio) // 10], ratio[len(ratio) * 9 // 10]))
    for k, (ref, ours, both) in lips.items():
        print("  %s: espeak %d, ours %d, in common %d" % (k, ref, ours, both))
    print("worst lines:")
    for r in sorted(rows)[:show]:
        print("  %.0f%%  %s\n      espeak %s\n      ours   %s" % (r[0] * 100, r[2], " ".join(r[3]), " ".join(r[4])))


if __name__ == "__main__":
    main()
