"""The beat grid the rhythm players (bones, tambourine) play to (#790): from a tune's note data, each
beat's start in the tune's running notes and its time, swung as the fiddler swings it. A beat is four
of the tune's running notes (a half note in a reel's cut time; tune.arrange's unit), the bars start
where the tune's bar 1 does (after the pickup). Same grid as banjo.arrange's."""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tune  # noqa: E402

LEAD = 0.3


def grid(sc):
    """(when, beats, last): when(u) the time of unit u; beats a list of (u0, bar_start, phrase_end)
    from the first beat that holds a note to the tune's last note; last the last note's unit."""
    mel = sorted([n for n in sc["notes"] if n["voice"] == "melody"], key=lambda n: n["unit"])
    unit = 60.0 / sc["tempo_half_bpm"] / 4.0

    def when(u):
        return LEAD + tune._swung(u, unit, 0.55)

    bar1 = next((n["unit"] for n in mel if n["bar"] >= 1), 0.0)
    first = bar1 - 4 * np.ceil((bar1 - mel[0]["unit"]) / 4.0 - 1e-6)
    starts = sc.get("bar_units")
    if starts and len(starts) > 2:
        # the bars as written (a song that opens on rests, or a line that starts after its downbeat)
        full = float(np.median(np.diff(starts)))
        bar1 = starts[0] if starts[1] - starts[0] >= full - 1e-6 else starts[1]
        first = bar1 - 4 * np.ceil((bar1 - starts[0]) / 4.0 - 1e-6)
    last = mel[-1]["unit"]
    beats = []
    u0 = first
    while u0 < last - 1e-6:
        k = (u0 - bar1) / 4.0  # beats since bar 1 (two a bar)
        bar_start = abs(k - 2 * round(k / 2)) < 1e-6 and k >= 0
        phrase_end = k >= 0 and (int(round(k)) % 8) == 7  # the last beat of every four bars
        beats.append((u0, bar_start, phrase_end))
        u0 += 4
    return when, beats, last, unit
