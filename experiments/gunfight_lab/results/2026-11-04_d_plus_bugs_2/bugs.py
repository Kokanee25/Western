#!/usr/bin/env python3
"""#607's bugs (the third blind playtest of D+), measured over gunfight lab runs. Both runs carry
the lab's notes for them (fight.gd: the drawn-muzzle probe, `cut`, `drag_of`, "(down)" on callouts):

1. Your side: hits on you also logged as near misses ("passed 0.0 m").
2. Their hands through things: shots whose drawn muzzle has something between it and his eye (his
   pose: the pane, the boards; the ball no longer starts there since #595), and the glass that cut
   a man just after his own shot ("Lyle's own shot wounded Lyle").
3. Their words and states: "going round" called by a man down or getting up; a friend dragged who
   was getting up himself (or up); lines in one breath (a man's second line within 1.5 s); cussing
   a friend's shot; "You damn fool!" when the count ran out with nothing done; a man saying he's
   off ("I'm gone!", "To hell with this!") who then moved under 4 m in the next 10 s.

    python3 bugs.py RUN [RUN...] [--out=FILE.md]
"""
import collections
import glob
import json
import os
import re
import sys

FLEE = ["To hell with this!", "I ain't dying for this!", "I'm gone!", "Get out! Fall back!", "That's it, we're done here! Run!"]
PROVOKED = ["You damn fool!", "Your funeral, friend.", "That's how it is? Fine!"]
WATCH_IT = ["Watch where you're shooting!", "Hey! Mind where you're aiming!"]


def runs(args):
    return [a for a in args if not a.startswith("--")]


def _pos(track, who, t):
    """Where he was at the sample nearest t (x, z), or None."""
    best = None
    for row in track:
        p = row.get("men", {}).get(who)
        if p is None:
            continue
        if best is None or abs(row["t"] - t) < abs(best[0] - t):
            best = (row["t"], p)
    return best[1][:2] if best else None


def one(root):
    o = collections.Counter()
    pose_what = collections.Counter()
    for p in sorted(glob.glob(os.path.join(root, "fights", "*.json"))):
        r = json.load(open(p))
        o["fights"] += 1
        tl = r.get("timeline", [])
        track = r.get("track", [])
        hits_on_you = [t for t, k, x in tl if k == "hit" and x.startswith("you hit")]
        o["hits_on_you"] += len(hits_on_you)
        for t, k, x in tl:
            if k == "near_miss":
                m = re.search(r"passed ([\d.]+) m", x)
                o["near_misses"] += 1
                if m and float(m.group(1)) < 0.25 and any(abs(t - h) < 0.1 for h in hits_on_you):
                    o["near_miss_was_hit"] += 1
            elif k == "cut":
                o["glass_cuts"] += 1
                if "just after his own shot" in x:
                    o["own_glass"] += 1
            elif k == "callout" and " called flank" in x:
                o["flank_calls"] += 1
                if x.endswith("(down)"):
                    o["flank_down"] += 1
            elif k == "drag_of":
                o["drags"] += 1
                state = x.rsplit(": ", 1)[-1]
                if state in ("rising", "will rise", "up"):
                    o["drag_getting_up"] += 1
        said = [(t, x.split(":", 1)[0], x.split(": ", 1)[1].strip('"')) for t, k, x in tl if k == "said" and ": " in x]
        o["lines"] += len(said)
        last = {}
        for t, who, line in said:
            if who in last and t - last[who] < 1.5:
                o["one_breath"] += 1
            last[who] = t
            if line in WATCH_IT:
                o["watch_it"] += 1
            if line in FLEE:
                o["flee_lines"] += 1
                a, b = _pos(track, who, t), _pos(track, who, t + 10.0)
                if a and b and ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) ** 0.5 < 4.0:
                    o["flee_stayed"] += 1
        count_out = [t for t, k, x in tl if k == "turn" and "the count's out" in x]
        if count_out:
            o["count_out_fights"] += 1
            if any(line in PROVOKED and 0.0 <= t - count_out[0] < 3.0 for t, _w, line in said):
                o["fool_on_count"] += 1
        for man in r["men"].values():
            for s in man.get("muzzle_probe", []):
                o["shots"] += 1
                if len(s) > 5 and s[5]:
                    o["pose_through"] += 1
                    pose_what[s[5].split(":")[0]] += 1
    return o, pose_what


COLS = [("fights", "Fights"), ("hits_on_you", "Hits on you"), ("near_miss_was_hit", "...also a near miss"),
        ("shots", "Gang shots"), ("pose_through", "Gun hand through something (pose)"), ("own_glass", "Cut by his own pane"),
        ("flank_calls", "Flank calls"), ("flank_down", "...by a man down"), ("drags", "Drags"), ("drag_getting_up", "...of a man getting up"),
        ("lines", "Lines said"), ("one_breath", "Second line within 1.5 s"), ("watch_it", "Cussing a friend's shot"),
        ("count_out_fights", "Count ran out"), ("fool_on_count", "...\"You damn fool!\""), ("flee_lines", "\"I'm off\" lines"),
        ("flee_stayed", "...then under 4 m in 10 s")]


def main(args):
    rows = ["| Run | " + " | ".join(c[1] for c in COLS[1:]) + " |", "|---|" + "---|" * (len(COLS) - 1)]
    notes = []
    for root in runs(args):
        o, what = one(root)
        rows.append("| %s (%d) | " % (os.path.basename(root.rstrip("/")), o["fights"]) + " | ".join(str(o[c[0]]) for c in COLS[1:]) + " |")
        notes.append("- %s: what his gun hand was through (the drawn muzzle from his eye): %s" % (
            os.path.basename(root.rstrip("/")), ", ".join("%s %d" % kv for kv in what.most_common()) or "nothing"))
    text = "\n".join(rows + [""] + notes) + "\n"
    out = [a.split("=", 1)[1] for a in args if a.startswith("--out=")]
    if out:
        open(out[0], "w").write(text)
    print(text)


if __name__ == "__main__":
    main(sys.argv[1:])
