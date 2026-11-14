#!/usr/bin/env python3
"""How the gang moves (issue #465, Sean 2026-10-28: "move more, with purpose": up the stairs, to
real cover, behind the timber posts).

    python3 experiments/gunfight_lab/moves.py ROOT [ROOT...] [--out=FILE.md]

From each fight's `moves` and `stays` (fight.gd `_watch_moves`), a table a root (split by opening):

- **runs**: runs for cover a man a fight; how far he ran (median); seconds running (in the open)
  a man a fight; the share that got there, switched to another spot on the way, or were given up
  (stuck, too long, or anything else that ended the run first);
- **stays**: stays behind cover a man a fight, their median length; **dropped on arrival**: left
  within 2 s (and 0.5 s) of getting there because "you can see him there now" (#294);
- **posts**: runs to a post, stays at one, seconds there a man a fight, hits taken and given there;
- **up**: climbs to the galleries, stays up there, hits on you from up there;
- the fight: the shooting (to the last shot, median), 45-90 s of it, hits on you a fight, you down.
"""
import glob
import json
import os
import statistics
import sys

MEN = ("brody", "lyle", "kid")


def med(xs):
    return statistics.median(xs) if xs else 0.0


def shooting(r):
    shots = [float(e[0]) for e in r.get("timeline", []) if e[1] == "shot"]
    return max(shots) if shots else 0.0


def study(root, opening):
    fights = 0
    men = 0
    runs = []
    stays = []
    shoot = []
    you_down = 0
    hits_on_you = 0
    hits_up = 0
    for f in sorted(glob.glob(os.path.join(root, "fights", "*.json"))):
        r = json.load(open(f))
        if (r.get("opening") or "they") != opening:
            continue
        fights += 1
        shoot.append(shooting(r))
        you_down += 1 if r.get("you", {}).get("down") else 0
        hits_on_you += int(r.get("gang", {}).get("hits_on_you", 0))
        for mid, m in (r.get("men") or {}).items():
            if not m.get("fought"):
                continue
            men += 1
            runs += m.get("moves", [])
            stays += m.get("stays", [])
            hits_up += int(m.get("hits_from_up", 0))
    if not fights:
        return None
    n = max(men, 1)
    got = [x for x in runs if x["how"] == "arrived"]
    switched = [x for x in runs if x["how"] == "switched"]
    over = [x for x in runs if x["how"] == "fight over"]
    gave_up = [x for x in runs if x["how"] not in ("arrived", "switched", "fight over")]
    dropped2 = [s for s in stays if s["s"] < 2.0 and s["left"].startswith("leave his cover")]
    dropped05 = [s for s in stays if s["s"] < 0.5 and s["left"].startswith("leave his cover")]
    post_runs = [x for x in runs if x.get("post")]
    post_stays = [s for s in stays if s.get("post")]
    up_runs = [x for x in runs if x.get("climb")]
    up_stays = [s for s in stays if s.get("up")]
    ended = max(len(runs) - len(over), 1)
    return {
        "fights": fights, "men": men,
        "runs_a_man": len(runs) / n, "run_m": med([x["ran"] for x in runs]), "run_s_a_man": sum(x["s"] for x in runs) / n,
        "got": len(got) / ended, "switched": len(switched) / ended, "gave_up": len(gave_up) / ended,
        "stays_a_man": len(stays) / n, "stay_s": med([s["s"] for s in stays]),
        "dropped2": len(dropped2), "dropped05": len(dropped05), "arrivals": len(got),
        "post_runs": len(post_runs), "post_stays": len(post_stays), "post_s_a_man": sum(s["s"] for s in post_stays) / n,
        "post_hits": sum(s["hits"] for s in post_stays), "post_hits_on_you": sum(s["hits_on_you"] for s in post_stays),
        "climbs": len(up_runs), "up_stays": len(up_stays), "up_s_a_man": sum(s["s"] for s in up_stays) / n, "hits_from_up": hits_up,
        "shooting": med(shoot), "45_90": sum(1 for s in shoot if 45.0 <= s <= 90.0) / fights,
        "hits_on_you": hits_on_you / fights, "you_down": you_down / fights,
        "gave_up_why": tally([x["how"] for x in gave_up]),
    }


def tally(xs):
    out = {}
    for x in xs:
        k = x.split(":")[0]
        out[k] = out.get(k, 0) + 1
    return dict(sorted(out.items(), key=lambda kv: -kv[1]))


def main(argv):
    roots = [a for a in argv if not a.startswith("--")]
    out = next((a.split("=", 1)[1] for a in argv if a.startswith("--out=")), None)
    rows = []
    for root in roots:
        for opening in ("they", "shoot"):
            s = study(root, opening)
            if s:
                rows.append((os.path.basename(root.rstrip("/")), opening, s))
    lines = ["# How the gang moves (`moves.py`)", "",
             "Runs and stays a man a fight are of men who fought. Dropped: left his cover within 2 s (0.5 s) of getting there, \"you can see him there now\".", "",
             "| Run | Opening | Fights | Runs a man | Run m (med) | Running s a man | Got there | Switched | Given up | Stays a man | Stay s (med) | Dropped 2 s / 0.5 s of arrivals |",
             "|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for name, op, s in rows:
        lines.append("| %s | %s | %d | %.1f | %.1f | %.1f | %.0f%% | %.0f%% | %.0f%% | %.1f | %.1f | %d / %d of %d |" % (
            name, "they" if op == "they" else "you", s["fights"], s["runs_a_man"], s["run_m"], s["run_s_a_man"], 100 * s["got"],
            100 * s["switched"], 100 * s["gave_up"], s["stays_a_man"], s["stay_s"], s["dropped2"], s["dropped05"], s["arrivals"]))
    lines += ["", "| Run | Opening | Runs to a post | Stays at a post | Post s a man | Hits taken / given there | Climbs | Stays up | Up s a man | Hits on you from up | Shooting s (med) | 45-90 s | Hits on you | You down |",
              "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for name, op, s in rows:
        lines.append("| %s | %s | %d | %d | %.1f | %d / %d | %d | %d | %.1f | %d | %.1f | %.0f%% | %.1f | %.0f%% |" % (
            name, "they" if op == "they" else "you", s["post_runs"], s["post_stays"], s["post_s_a_man"], s["post_hits"], s["post_hits_on_you"],
            s["climbs"], s["up_stays"], s["up_s_a_man"], s["hits_from_up"], s["shooting"], 100 * s["45_90"], s["hits_on_you"], 100 * s["you_down"]))
    lines += ["", "Runs given up, by why:", ""]
    for name, op, s in rows:
        lines.append("- %s, %s: %s" % (name, "they" if op == "they" else "you", ", ".join("%s %d" % kv for kv in s["gave_up_why"].items()) or "none"))
    text = "\n".join(lines) + "\n"
    if out:
        open(out, "w").write(text)
    print(text)


if __name__ == "__main__":
    main(sys.argv[1:])
