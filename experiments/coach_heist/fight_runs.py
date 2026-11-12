#!/usr/bin/env python3
"""The coach heist after the hit (#815): N scripted runs of `ch_fight_run` in the valley (the game
under the dev bridge, headless), each its own seed, and a summary: who won, how long the fight was,
what was taken, who lived, the worst frames.

    python3 experiments/coach_heist/fight_runs.py --seeds=1-8 [--take=papers|box] [--aim=1.0] [--auto] --out=DIR
"""
import json, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BRIDGE = [sys.executable, os.path.join(ROOT, "tools", "bridge.py")]


def opt(name, dflt=None):
    for a in sys.argv[1:]:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
        if a == "--%s" % name:
            return "1"
    return dflt


def seeds(spec):
    out = []
    for part in spec.split(","):
        if "-" in part:
            a, b = part.split("-")
            out += list(range(int(a), int(b) + 1))
        else:
            out.append(int(part))
    return out


def main():
    out = os.path.abspath(opt("out", os.path.join(ROOT, "build", "coach_fight")))
    os.makedirs(out, exist_ok=True)
    take = opt("take", "papers")
    extra = ["take=" + take, "aim=" + opt("aim", "1.0"), "max=" + opt("max", "300")] + (["auto"] if opt("auto") else [])
    subprocess.run(BRIDGE + ["stop"], capture_output=True)
    rows = []
    try:
        for s in seeds(opt("seeds", "1-8")):
            # A fresh game each run (your wounds, your cartridges and the bodies don't carry over).
            subprocess.run(BRIDGE + ["start", "--headless", "--fps=60", "--game-args=--world=valley"], check=True)
            f = os.path.join(out, "seed%d_%s.json" % (s, take))
            subprocess.run(BRIDGE + ["wait 1", "ch_fight_run seed=%d out=%s %s" % (s, f, " ".join(extra))], capture_output=True)
            subprocess.run(BRIDGE + ["stop"], capture_output=True)
            try:
                r = json.load(open(f))
            except Exception as e:
                print("seed %d: no result (%s)" % (s, e))
                continue
            rows.append(r)
            print(line(r))
    finally:
        subprocess.run(BRIDGE + ["stop"], capture_output=True)
    with open(os.path.join(out, "summary_%s.md" % take), "w") as fh:
        fh.write("# The coach heist after the hit: %d runs (take=%s)\n\n" % (len(rows), take))
        for r in rows:
            fh.write("- " + line(r) + "\n")
        won = sum(1 for r in rows if r["outcome"] == "won")
        fh.write("\nWon %d of %d. Worst frame %.1f ms here (%.0f at Sean's).\n" % (won, len(rows),
                 max([r["frames"]["max_ms"] for r in rows] or [0]), max([r["frames"]["max_ms"] for r in rows] or [0]) * 0.65))


def line(r):
    fight_end = r["bot"]["phase_at"].get("down", r["end"] if r["end"] > 0 else r["t"])
    dead_at_hit = [e[1].split(" ")[0] for e in r["timeline"] if "dead" in e[1] and "out" not in e[1] and e[0] - r["hit"] < 1.0]
    gave = [e[1].split(" ")[0] for e in r["timeline"] if "gives up" in e[1]]
    up = [e[1].split(" ")[0] for e in r["timeline"] if "getting up" in e[1]]
    return ("seed %d: %s (%s) at %.0f s; the fight %.0f s from the hit; %s; up %d, gave up %d, dead %d (%d at the hit), "
            "guards fired %d, you %d; pin shots %d, padlock shots %d; frames mean %.1f p95 %.1f max %.1f ms" % (
                r["seed"], r["outcome"], r["state"], r["t"], fight_end - r["hit"], ("took " + r["took"]) if r["took"] else "took nothing",
                len(up), len(gave), len(r["story"].get("coach.dead", [])) if r["story"] else sum(1 for m in r["men"] if m.get("alive") is False),
                len(dead_at_hit), r.get("shots_men", 0), r.get("shots_you", 0), r["bot"]["pin_shots"], r["bot"]["padlock_shots"],
                r["frames"]["mean_ms"], r["frames"]["p95_ms"], r["frames"]["max_ms"]))


if __name__ == "__main__":
    main()
