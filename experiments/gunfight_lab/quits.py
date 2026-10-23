#!/usr/bin/env python3
"""How the gang quits (Sean, issue #257: "the bad guys just kept quitting, wouldn't even really fight").

    python3 experiments/gunfight_lab/quits.py ROOT [ROOT...] [--by=variant,opening] [--where=k=v,...] [--out=FILE.md]

Each ROOT is a run.py output (its fights/*.json). Rows are grouped by --by (any record field:
variant, opening, scenario, style, weapon, hour; default variant,opening). For each row:

- fights, median length, the share 45-90 s (the brief's target) and under 15 s;
- how they end; how often anyone quits (gives up or runs) and how soon (the first quit);
- quits a fight, and on how many hits the quitter had taken (0, 1, 2+);
- who quits first (Brody, Lyle, the Kid), each man's quit rate and median time;
- where the quitters' fear came from (the brain's own ledger, OutlawBrain.fear_from), as a share;
- whether they fought back: shots a man, the share of men who fired at all, hits on you, you down.

A quit is a man giving up or running while he could still fight; going down or dying isn't one.
"""
import glob
import json
import os
import statistics
import sys

MEN = ["brody", "lyle", "kid"]


def opt(args, name, default):
    for a in args:
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def load(roots, where):
    out = []
    for root in roots:
        for f in sorted(glob.glob(os.path.join(root, "fights", "*.json"))):
            r = json.load(open(f))
            if all(str(r.get(k, "")) == v for k, v in where.items()):
                out.append(r)
    return out


def med(xs):
    return statistics.median(xs) if xs else float("nan")


def pct(n, d):
    return "%d%%" % round(100.0 * n / d) if d else "-"


def quits_of(r):
    """[(t, man, how, hits, fear ledger)] in the order they came."""
    q = []
    for mid, m in r["men"].items():
        if "quit" in m and m.get("outcome") in ("surrendered", "fled", "broke_off", "down", "dead", "standing"):
            qq = m["quit"]
            q.append((float(qq["t"]), mid, qq["how"], int(qq.get("hits", 0)), qq.get("fear_named") or qq.get("fear_from", {}),
                      qq.get("following", "")))
    return sorted(q)


def row(rs):
    n = len(rs)
    lengths = [float(r["length_s"]) for r in rs]
    endings = {}
    for r in rs:
        endings[r["ending"]] = endings.get(r["ending"], 0) + 1
    with_quit = [r for r in rs if quits_of(r)]
    first = [quits_of(r)[0][0] for r in with_quit]
    all_q = [q for r in rs for q in quits_of(r)]
    by_hits = {"0": 0, "1": 0, "2+": 0}
    for q in all_q:
        by_hits["0" if q[3] == 0 else "1" if q[3] == 1 else "2+"] += 1
    firsts = {m: 0 for m in MEN}
    for r in with_quit:
        firsts[quits_of(r)[0][1]] = firsts.get(quits_of(r)[0][1], 0) + 1
    fear = {}
    for q in all_q:
        tot = sum(float(v) for v in q[4].values()) or 1.0
        for k, v in q[4].items():
            k = k.split(" (")[0]
            fear[k] = fear.get(k, 0.0) + float(v) / tot
    following = sum(1 for q in all_q if q[5])
    per_man = {}
    for mid in MEN:
        ms = [r["men"][mid] for r in rs if mid in r["men"]]
        qs = [float(m["quit"]["t"]) for m in ms if "quit" in m]
        per_man[mid] = (pct(len(qs), len(ms)), med(qs), sum(int(m.get("shots", 0)) for m in ms) / max(len(ms), 1))
    men = [m for r in rs for m in r["men"].values()]
    fired = sum(1 for m in men if int(m.get("shots", 0)) > 0)
    return {
        "n": n, "len": med(lengths), "in_target": pct(sum(1 for x in lengths if 45 <= x <= 90), n),
        "under15": pct(sum(1 for x in lengths if x < 15), n), "endings": endings,
        "any_quit": pct(len(with_quit), n), "first_quit": med(first),
        "quits_a_fight": len(all_q) / n if n else 0.0, "by_hits": by_hits, "firsts": firsts,
        "following": following, "fear": {k: v / max(len(all_q), 1) for k, v in sorted(fear.items(), key=lambda kv: -kv[1])},
        "per_man": per_man, "fired": pct(fired, len(men)), "shots_a_man": sum(int(m.get("shots", 0)) for m in men) / max(len(men), 1),
        "hits_on_you": sum(int(r["you"].get("hits_taken", 0)) for r in rs) / max(n, 1),
        "you_down": pct(sum(1 for r in rs if r["ending"] in ("you_down", "you_dead")), n),
    }


def main(argv):
    args = [a for a in argv if a.startswith("--")]
    roots = [a for a in argv if not a.startswith("--")]
    by = opt(args, "by", "variant,opening").split(",")
    where = dict(kv.split("=", 1) for kv in opt(args, "where", "").split(",") if kv)
    rs = load(roots, where)
    groups = {}
    for r in rs:
        key = tuple(str(r.get(k, "")) or "-" for k in by)
        groups.setdefault(key, []).append(r)
    lines = ["# How they quit (%d fights; %s)" % (len(rs), ", ".join(roots)), ""]
    head = by + ["fights", "length s (med)", "45-90 s", "< 15 s", "anyone quits", "first quit s (med)", "quits a fight",
                 "quit on 0 / 1 / 2+ hits", "first to quit B/L/K", "men who fired", "shots a man", "hits on you", "you down"]
    lines.append("| " + " | ".join(head) + " |")
    lines.append("|" + "---|" * len(head))
    rows = {}
    for key in sorted(groups):
        x = row(groups[key])
        rows[key] = x
        bh = x["by_hits"]
        f = x["firsts"]
        lines.append("| " + " | ".join(list(key) + [
            str(x["n"]), "%.1f" % x["len"], x["in_target"], x["under15"], x["any_quit"], "%.1f" % x["first_quit"],
            "%.2f" % x["quits_a_fight"], "%d / %d / %d" % (bh["0"], bh["1"], bh["2+"]),
            "%d / %d / %d" % (f.get("brody", 0), f.get("lyle", 0), f.get("kid", 0)), x["fired"], "%.1f" % x["shots_a_man"],
            "%.1f" % x["hits_on_you"], x["you_down"]]) + " |")
    lines.append("")
    lines.append("Per man (quit rate, median quit time s, shots a fight), endings, and where the quitters' fear came from (share of a quitter's fear, averaged):")
    lines.append("")
    for key, x in rows.items():
        pm = "; ".join("%s %s at %.1f, %.1f shots" % (m, v[0], v[1], v[2]) for m, v in x["per_man"].items())
        fear = ", ".join("%s %.0f%%" % (k, 100 * v) for k, v in list(x["fear"].items())[:7])
        end = ", ".join("%s %d" % kv for kv in sorted(x["endings"].items(), key=lambda kv: -kv[1]))
        lines.append("- **%s**: %s. Endings: %s. Quitters' fear: %s. Quits that followed a friend's word: %d." % (
            " ".join(key), pm, end, fear or "-", x["following"]))
    text = "\n".join(lines) + "\n"
    out = opt(args, "out", "")
    if out:
        open(out, "w").write(text)
    print(text)


if __name__ == "__main__":
    main(sys.argv[1:])
