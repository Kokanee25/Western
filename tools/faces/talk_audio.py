#!/usr/bin/env python3
"""A stand-in recorded line for FaceSpeech's audio timing, before real ones exist: the line spoken
by espeak-ng with the mbrola us1 voice (programs only, nothing of theirs is kept), and its
phonemes with their times in ARPAbet (as a forced aligner such as the Montreal Forced Aligner
gives for a real recording).

    python3 tools/faces/talk_audio.py --text="Open the drawer. Slow." --out=build/faces/talk/rob [--wpm=150]
→ <out>/line.wav, <out>/phonemes.json ([[start, end, "AH1"], ...]: a vowel of 75 ms or more counted stressed)
"""
import json
import os
import subprocess
import sys

# mbrola us1's symbols (espeak-ng --pho) to ARPAbet
SAMPA = {"p": "P", "b": "B", "t": "T", "d": "D", "k": "K", "g": "G", "f": "F", "v": "V", "T": "TH", "D": "DH",
         "s": "S", "z": "Z", "S": "SH", "Z": "ZH", "h": "HH", "tS": "CH", "dZ": "JH", "m": "M", "n": "N", "N": "NG",
         "l": "L", "r": "R", "w": "W", "j": "Y", "i": "IY", "i:": "IY", "I": "IH", "E": "EH", "{": "AE", "A": "AA",
         "A:": "AA", "V": "AH", "@": "AH", "O": "AO", "O:": "AO", "U": "UH", "u": "UW", "u:": "UW", "EI": "EY",
         "eI": "EY", "aI": "AY", "AI": "AY", "OI": "OY", "@U": "OW", "oU": "OW", "aU": "AW", "r=": "ER",
         "3": "ER", "3:": "ER", "@`": "ER", "_": "sil"}
VOWELS = {"IY", "IH", "EH", "AE", "AA", "AH", "AO", "UH", "UW", "EY", "AY", "OY", "OW", "AW", "ER"}


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    out = a["--out"]
    os.makedirs(out, exist_ok=True)
    wpm = a.get("--wpm", "150")
    text = a["--text"]
    pho = subprocess.run(["espeak-ng", "-v", "mb-us1", "-s", wpm, "-q", "--pho", text], capture_output=True, text=True).stdout
    subprocess.run(["espeak-ng", "-v", "mb-us1", "-s", wpm, "-w", os.path.join(out, "line.wav"), text], check=True)
    t, track = 0.0, []
    for line in pho.splitlines():
        b = line.split()
        if len(b) < 2:
            continue
        d = float(b[1]) / 1000
        ph = SAMPA.get(b[0].replace("_h", ""), "sil")
        if ph in VOWELS:
            ph += "1" if d >= 0.075 else "0"
        track.append([round(t, 4), round(t + d, 4), ph])
        t += d
    json.dump(track, open(os.path.join(out, "phonemes.json"), "w"))
    print("talk_audio: %.2f s, %d phonemes -> %s" % (t, len(track), out))


if __name__ == "__main__":
    main()
