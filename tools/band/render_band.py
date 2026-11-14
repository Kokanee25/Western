#!/usr/bin/env python3
"""The band's parts for the game (#799): one tune's note data rendered once, offline, by the sound
lab's own instrument models (experiments/sound_lab/fiddle/: bowed.py the fiddle, banjo.py, bones.py,
tambourine.py, piano.py, harmonica.py), one Ogg a player, all starting at the tune's t = 0, each at
its level in the band; and the game's note data beside them (`notes.json`: the bars, the phrases a
player can stop at and start from, the fiddle's bow strokes and the piano's keys for the players'
hands). The game (src/audio/band.gd) plays the parts together, each placed at its player, from the
same clock: the one note data drives the sound and the hands.

Why rendered ahead (#799's "decide first"): the models run in Python with numba, ~1-3 s for 20 s of
the fiddle, and the piano and banjo longer; six of them live is not a frame budget's worth (the
People budget is 4 ms, the whole frame 14). A stop is the bow lifted: the game fades the part out in
`stop_s` (the strings ring on that long when the bow's force goes to zero) and starts again at a
phrase's start, so a part needs no cut.

    python3 tools/band/render_band.py payday_night [--only=fiddle,piano] [--q=4]

Writes assets/audio/band/<tune>/<player>.ogg and notes.json. Needs numpy, scipy, numba, ffmpeg.
"""
import json
import os
import subprocess
import sys
import tempfile
import time

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LAB = os.path.join(ROOT, "experiments", "sound_lab", "fiddle")
sys.path.insert(0, LAB)
import banjo  # noqa: E402
import bones  # noqa: E402
import bowed  # noqa: E402
import common  # noqa: E402
import harmonica  # noqa: E402
import piano  # noqa: E402
import tambourine  # noqa: E402

PLAYERS = ("fiddle", "banjo", "piano", "harmonica", "bones", "tambourine")
# Each player's loudness against the fiddle's (dB): band.py's LEVELS, the harmonica under the fiddle
# (it doubles the tune).
LEVELS = {"fiddle": 0.0, "banjo": -2.5, "piano": -4.0, "harmonica": -6.0, "bones": -9.0, "tambourine": -11.0}
# The fiddle's level (LUFS, common.loudness): the lab's -18, the parts' sum peaking under 1.
FIDDLE_LUFS = -20.0
PHRASE_BARS = 4


def part(name, sc):
    """[samples at common.SR, the part's data for the hands or None]."""
    if name == "fiddle":
        return bowed.render(sc), None
    if name == "banjo":
        return banjo.render(banjo.arrange(sc)), None
    if name == "bones":
        return bones.render(bones.arrange(sc)), None
    if name == "tambourine":
        return tambourine.render(tambourine.arrange(sc))[0], None
    if name == "piano":
        p = piano.arrange(sc)
        return piano.render(p), p
    if name == "harmonica":
        return harmonica.render(harmonica.arrange(sc)), None
    raise ValueError(name)


def bars_of(sc):
    """Each bar's start (s): its first melody note's time (the tunes have no pickup bar: tune.py
    and abc_tune.py start on the downbeat)."""
    first = {}
    for n in sc["notes"]:
        if n.get("voice") == "melody" and "bar" in n:
            b = int(n["bar"])
            first[b] = min(first.get(b, 1e9), float(n["t"]))
    return [round(first[b], 4) for b in sorted(first)]


def notes_for_game(sc, piano_part, length_s):
    bars = bars_of(sc)
    phrases = [bars[i] for i in range(0, len(bars), PHRASE_BARS)]
    strokes = [[round(s["t0"], 3), round(s["t1"], 3), 1 if s["dir"] == "down" else -1, s["strings"][0]]
               for s in sc.get("strokes", [])]
    keys = []
    if piano_part:
        keys = [[round(k["t"], 3), round(k["dur"], 3), int(k["midi"]), 0 if k["hand"] == "left" else 1]
                for k in piano_part["keys"]]
    return {
        "_doc": "Made by tools/band/render_band.py from experiments/sound_lab/fiddle/%s (don't edit: render "
                "again). bars: each bar's start (s); phrases: where a player can stop and start (every %d bars); "
                "strokes: the fiddle's bow [t0, t1, 1 down | -1 up, string]; keys: the piano's [t, dur, midi, "
                "0 left | 1 right hand]; players: each part's file and its peak." % (sc.get("_file", ""), PHRASE_BARS),
        "tune": sc["tune"], "source": sc.get("source", ""), "tempo_half_bpm": sc["tempo_half_bpm"],
        "length_s": round(length_s, 3), "end_s": round(float(max(n["t"] + n["dur"] for n in sc["notes"])), 3),
        "bars": bars, "phrases": phrases, "strokes": strokes, "keys": keys, "players": {},
    }


def write_ogg(path, x, q):
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        wav = f.name
    common.write_wav(wav, x)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-ac", "1", "-c:a", "libvorbis",
                    "-q:a", str(q), path], check=True)
    os.unlink(wav)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    name = args[0] if args else "payday_night"
    src = os.path.join(LAB, name + ".json")
    sc = json.load(open(src))
    sc["_file"] = name + ".json"
    banjo.strings("gut")
    only = [w for w in opt.get("only", ",".join(PLAYERS)).split(",") if w]
    out_dir = os.path.join(ROOT, "assets", "audio", "band", name)
    os.makedirs(out_dir, exist_ok=True)
    notes_path = os.path.join(out_dir, "notes.json")
    old = json.load(open(notes_path)) if os.path.exists(notes_path) else {}
    rendered = {}
    piano_part = None
    for who in only:
        t0 = time.time()
        y, data = part(who, sc)
        if who == "piano":
            piano_part = data
        rendered[who] = y
        print(f"{who}: {len(y) / common.SR:.1f} s in {time.time() - t0:.1f} s", flush=True)
    if piano_part is None and old.get("keys"):
        piano_part = {"keys": [{"t": k[0], "dur": k[1], "midi": k[2], "hand": "left" if k[3] == 0 else "right"} for k in old["keys"]]}
    length = max([len(y) for y in rendered.values()] + [int(old.get("length_s", 0) * common.SR)]) / common.SR
    notes = notes_for_game(sc, piano_part, length)
    notes["players"] = old.get("players", {})
    for who, y in rendered.items():
        x = common.normalise(y, target=FIDDLE_LUFS) * 10 ** (LEVELS[who] / 20.0)
        x = np.concatenate([x, np.zeros(max(0, int(length * common.SR) - len(x)))])
        path = os.path.join(out_dir, who + ".ogg")
        write_ogg(path, x, int(opt.get("q", 3)))
        notes["players"][who] = {"file": who + ".ogg", "level_db": LEVELS[who], "peak": round(float(np.max(np.abs(x))), 3)}
        print(f"  {path}: peak {np.max(np.abs(x)):.2f}, {os.path.getsize(path) // 1024} KB")
    json.dump(notes, open(notes_path, "w"), indent=None, separators=(",", ":"))
    with open(notes_path, "a") as f:
        f.write("\n")
    print(f"{notes_path}: {len(notes['bars'])} bars, {len(notes['phrases'])} phrases, {len(notes['strokes'])} strokes, {len(notes['keys'])} keys")


if __name__ == "__main__":
    main()
