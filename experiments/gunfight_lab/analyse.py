#!/usr/bin/env python3
"""The gunfight lab's numbers (README.md): every fight in RUN/fights/*.json into tables.

    python3 experiments/gunfight_lab/analyse.py RUN [RUN2 ...] [--out=DIR] [--where=scenario=street,bodies=studio]

Writes DIR (default the first RUN) /baseline.md (the tables), baseline.json (the same numbers) and
fights.csv (one row a fight). Several RUNs are pooled; --where keeps the fights that match.
--vs=BEFORE writes DIR/compare.md instead: BEFORE against RUN, headline numbers side by side, by
arena and in all (a fix against the baseline: --vs=experiments/gunfight_lab/baseline isn't
enough, it needs a run root with its fights/). Fights are grouped into setups (scenario, hour, weapon, style,
bodies); the tables pool them as each says.
"""
import csv
import glob
import json
import os
import statistics as st
import sys
from collections import Counter, defaultdict

MEN = ["brody", "lyle", "kid"]
SIT = ["cover_shot_away", "lamps_hit", "fires_started", "dust_on_line", "dust_by_man", "surrenders", "flights", "hats_shot", "townsfolk_hit", "shaken", "rallied"]
ENDINGS = ["you_down", "you_dead", "all_dead", "dead", "down", "surrendered", "fled", "broke_off", "lull", "timeout"]


def load(run):
    fights = []
    for p in sorted(glob.glob(os.path.join(run, "fights", "*.json"))):
        with open(p) as fh:
            f = json.load(fh)
        f["_name"] = os.path.basename(p)[:-5]
        fights.append(f)
    return fights


def med(xs):
    return st.median(xs) if xs else float("nan")


def mean(xs):
    return sum(xs) / len(xs) if xs else float("nan")


def q(xs, p):
    if not xs:
        return float("nan")
    s = sorted(xs)
    i = (len(s) - 1) * p
    lo, hi = int(i), min(int(i) + 1, len(s) - 1)
    return s[lo] + (s[hi] - s[lo]) * (i - lo)


def ci(xs):
    """Half-width of a 95% interval on the mean."""
    return 1.96 * st.stdev(xs) / len(xs) ** 0.5 if len(xs) > 1 else float("nan")


def pct(n, d):
    return 100.0 * n / d if d else float("nan")


def ending(f):
    e = f["ending"]
    return "you_down" if e == "you_dead" else e


def summary(fs):
    """The headline numbers for a set of fights."""
    n = len(fs)
    L = [f["length_s"] for f in fs]
    hit_you = [f["you"]["first_hit_at"] for f in fs if f["you"]["first_hit_at"] >= 0]
    mins = [max(f["length_s"], 1) / 60 for f in fs]
    per_man = defaultdict(lambda: defaultdict(list))
    for f in fs:
        for m in MEN:
            mm = f["men"].get(m)
            if not mm:
                continue
            for k in ["cover_changes", "flanks", "suppressing_shots", "pinned", "peeks", "shots", "hits_on_you", "hits_taken"]:
                per_man[m][k].append(mm[k])
            per_man[m]["outcome"].append(mm["outcome"])
    sit = {k: mean([f["situations"].get(k, 0) for f in fs]) for k in SIT}
    sit["ground_hits"] = mean([f["situations"].get("ground_hits", 0) for f in fs])
    sit["fights_with_any"] = pct(sum(1 for f in fs if any(f["situations"].get(k, 0) for k in SIT if k != "townsfolk_hit")), n)
    out = {
        "fights": n,
        "length_median_s": med(L), "length_q1_s": q(L, 0.25), "length_q3_s": q(L, 0.75),
        "length_mean_s": mean(L), "length_ci95_s": ci(L),
        "in_45_90_pct": pct(sum(1 for x in L if 45 <= x <= 90), n),
        "under_15_pct": pct(sum(1 for x in L if x < 15), n),
        "gang_hit_first_pct": pct(sum(1 for f in fs if f["first_hit_by"] == "gang"), n),
        "you_hit_first_pct": pct(sum(1 for f in fs if f["first_hit_by"] == "you"), n),
        "gang_shot_first_pct": pct(sum(1 for f in fs if f["first_shot_by"] not in ("you", "none")), n),
        "first_hit_at_median_s": med([f["first_hit_at"] for f in fs if f["first_hit_at"] >= 0]),
        "you_first_hit_median_s": med(hit_you), "you_never_hit_pct": pct(n - len(hit_you), n),
        "your_hits_mean": mean([f["you"]["hits"] for f in fs]), "your_shots_mean": mean([f["you"]["shots"] for f in fs]),
        "gang_hits_mean": mean([f["gang"]["hits_on_you"] for f in fs]), "gang_shots_mean": mean([f["gang"]["shots"] for f in fs]),
        "near_misses_per_min": mean([f["you"]["near_misses"] / m for f, m in zip(fs, mins)]),
        "near_misses_mean": mean([f["you"]["near_misses"] for f in fs]),
        "quiet_median_s": med([f["longest_quiet_s"] for f in fs]),
        "quiet_share_median": med([f["longest_quiet_s"] / max(f["length_s"], 0.01) for f in fs]),
        "endings": dict(Counter(ending(f) for f in fs)),
        "you_down_pct": pct(sum(1 for f in fs if f["you"]["down"]), n),
        "situations_per_fight": sit,
        "per_man": {m: {k: (mean(v) if k != "outcome" else dict(Counter(v))) for k, v in d.items()} for m, d in per_man.items()},
        "three_men_ms": mean([f["perf"]["three_men_ms"] for f in fs]),
        "people_ms": mean([f["perf"]["people_ms"] for f in fs]),
        "people_p95_ms": mean([f["perf"]["people_p95_ms"] for f in fs]),
        "frame_ms": mean([f["perf"]["frame_ms"] for f in fs]),
        "your_cover_moves_mean": mean([f["you"].get("cover_moves", 0) for f in fs]),
        "your_reloads_mean": mean([f["you"].get("reloads", 0) for f in fs]),
        "bot_stuck_mean": mean([f["you"].get("stuck", 0) for f in fs]),
        "body_notes": sorted({nt for f in fs for nt in f.get("body_notes", [])}),
    }
    return out


def diagnostics(fs):
    """The numbers behind the reasons in README.md's baseline."""
    first_shots = [f["first_shot_at"] for f in fs if f["first_shot_by"] not in ("you", "none")]
    first_hit_gang = [f for f in fs if f["first_hit_by"] == "gang"]
    gang_shots = sum(f["gang"]["shots"] for f in fs)
    gang_hits = sum(f["gang"]["hits_on_you"] for f in fs)
    your_shots = sum(f["you"]["shots"] for f in fs)
    your_hits = sum(f["you"]["hits"] for f in fs)
    quit_hits = Counter()
    quitters = 0
    for f in fs:
        for m in f["men"].values():
            if m["outcome"] in ("surrendered", "fled"):
                quitters += 1
                quit_hits[min(m["hits_taken"], 3)] += 1
    arm = [f["you"]["arm_out_at"] for f in fs if f["you"].get("arm_out_at", -1) >= 0]
    state = Counter()
    for f in fs:
        for row in f["track"]:
            for m in row["men"].values():
                if m[3] in ("fighting", "reloading"):
                    state[m[2]] += 1
    tot = sum(state.values()) or 1
    longest = [f["longest_quiet_s"] for f in fs]
    return {
        "the gang's first shot (median s after they turn)": fmt(med(first_shots), 2),
        "fights where the gang's first shot hit you": f"{fmt(pct(sum(1 for f in fs if f['first_hit_by'] == 'gang' and abs(f['first_hit_at'] - f['first_shot_at']) < 0.2), len(fs)), 0)}%",
        "the gang's hits a shot at you": f"{fmt(pct(gang_hits, gang_shots), 0)}% ({gang_hits} of {gang_shots})",
        "your hits a shot (a charge once)": f"{fmt(pct(your_hits, your_shots), 0)}% ({your_hits} of {your_shots})",
        "men who quit (gave up or ran), by hits taken first: 0 / 1 / 2 / 3+": " / ".join(str(quit_hits[i]) for i in range(4)) + f" of {quitters}",
        "fights where a hit took your gun arm (you can't hold the revolver; the coach gun needs both)": f"{fmt(pct(len(arm), len(fs)), 0)}% (median {fmt(med(arm), 1)} s in)",
        "the men's time while fighting: open / moving / hidden / peeking / searching": " / ".join(f"{fmt(pct(state[k], tot), 0)}%" for k in ("open", "moving", "hidden", "peeking", "searching")),
        "you went down when the gang hit first / when you hit first": " / ".join(
            f"{fmt(pct(sum(1 for f in g if f['you']['down']), len(g)), 0)}% (of {len(g)})"
            for g in ([f for f in fs if f["first_hit_by"] == "gang"], [f for f in fs if f["first_hit_by"] == "you"])),
        "flank callouts in all": sum(m["flanks"] for f in fs for m in f["men"].values()),
        "fights with a quiet stretch of 5 s or more": f"{fmt(pct(sum(1 for x in longest if x >= 5), len(fs)), 0)}%",
        "fights lasting 45 s or more": f"{fmt(pct(sum(1 for f in fs if f['length_s'] >= 45), len(fs)), 0)}%",
    }


def headline(fs):
    """The numbers a fix is judged on."""
    s = summary(fs)
    gs = sum(f["gang"]["shots"] for f in fs)
    gh = sum(f["gang"]["hits_on_you"] for f in fs)
    ys = sum(f["you"]["shots"] for f in fs)
    yh = sum(f["you"]["hits"] for f in fs)
    open_ = Counter()
    for f in fs:
        for row in f["track"]:
            for m in row["men"].values():
                if m[3] in ("fighting", "reloading"):
                    open_[m[2] == "open"] += 1
    gang_first = [f["first_shot_at"] for f in fs if f["first_shot_by"] not in ("you", "none")]
    top = sorted(s["endings"].items(), key=lambda kv: -kv[1])[:3]
    return [
        ("fights", str(len(fs))),
        ("length, median s", fmt(s["length_median_s"])),
        ("in 45–90 s", f"{fmt(s['in_45_90_pct'], 0)}%"),
        ("the gang's first shot, median s", fmt(med(gang_first), 2)),
        ("the gang hits first", f"{fmt(s['gang_hit_first_pct'], 0)}%"),
        ("you're first hit at, median s (never)", f"{fmt(s['you_first_hit_median_s'])} ({fmt(s['you_never_hit_pct'], 0)}%)"),
        ("the gang's hits a shot", f"{fmt(pct(gh, gs), 0)}% ({gh}/{gs})"),
        ("your hits a shot", f"{fmt(pct(yh, ys), 0)}%"),
        ("near misses on you a minute", fmt(s["near_misses_per_min"])),
        ("longest quiet, median s", fmt(s["quiet_median_s"])),
        ("the men's fighting time in the open", f"{fmt(pct(open_[True], sum(open_.values())), 0)}%"),
        ("you down", f"{fmt(s['you_down_pct'], 0)}%"),
        ("quits on 0 / 1 / 2+ hits (a man a fight)", " / ".join(fmt(sum(1 for f in fs for m in f["men"].values()
            if m.get("outcome") in ("surrendered", "fled") and (min(m["hits_taken"], 2) == h)) / len(fs), 2) for h in (0, 1, 2))),
        ("shaken, rallied (a fight)", f"{fmt(s['situations_per_fight'].get('shaken', 0), 2)}, {fmt(s['situations_per_fight'].get('rallied', 0), 2)}"),
        ("how it ended (top 3)", ", ".join(f"{k} {round(100 * v / len(fs))}%" for k, v in top)),
    ]


def compare(before, after, title):
    lines = [f"### {title}", "", "| | before | after |", "|---|---|---|"]
    for (k, a), (_, b) in zip(headline(before), headline(after)):
        lines.append(f"| {k} | {a} | {b} |")
    return lines + [""]


def group(fights, keys):
    g = defaultdict(list)
    for f in fights:
        g[tuple(f[k] for k in keys)].append(f)
    return g


def fmt(x, d=1):
    if isinstance(x, float) and x != x:
        return "–"
    return f"{x:.{d}f}" if isinstance(x, float) else str(x)


def endings_line(e, n):
    return ", ".join(f"{k} {round(100 * v / n)}%" for k, v in sorted(e.items(), key=lambda kv: -kv[1]))


def table(rows, keys, title):
    lines = [f"### {title}", "",
             "| " + " | ".join(keys) + " | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) "
             "| hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |",
             "|" + "---|" * (len(keys) + 11)]
    for k, s in rows:
        lines.append("| " + " | ".join(k) + f" | {s['fights']} | {fmt(s['length_median_s'])} ({fmt(s['length_q1_s'])}–{fmt(s['length_q3_s'])})"
                     f" | {fmt(s['in_45_90_pct'], 0)}% | {fmt(s['under_15_pct'], 0)}% | {fmt(s['gang_hit_first_pct'], 0)}%"
                     f" | {fmt(s['you_first_hit_median_s'])} ({fmt(s['you_never_hit_pct'], 0)}%)"
                     f" | {fmt(s['your_hits_mean'])} / {fmt(s['gang_hits_mean'])} | {fmt(s['your_shots_mean'])} / {fmt(s['gang_shots_mean'])}"
                     f" | {fmt(s['near_misses_per_min'])} | {fmt(s['quiet_median_s'])} | {endings_line(s['endings'], s['fights'])} |")
    return lines + [""]


def men_table(s, title):
    lines = [f"### {title}", "", "| man | shots | hits on you | hit | cover changes | peeks | flanks | suppressing shots | pinned | how he ended |",
             "|---|---|---|---|---|---|---|---|---|---|"]
    for m in MEN:
        d = s["per_man"].get(m)
        if not d:
            continue
        n = sum(d["outcome"].values())
        lines.append(f"| {m} | {fmt(d['shots'])} | {fmt(d['hits_on_you'])} | {fmt(d['hits_taken'])} | {fmt(d['cover_changes'])} | {fmt(d['peeks'])}"
                     f" | {fmt(d['flanks'], 2)} | {fmt(d['suppressing_shots'])} | {fmt(d['pinned'])} | {endings_line(d['outcome'], n)} |")
    return lines + ["", "(each a mean a fight)", ""]


def sit_table(rows, keys, title):
    lines = [f"### {title}", "", "| " + " | ".join(keys) + " | " + " | ".join(SIT) + " | fights with any | balls into the ground |",
             "|" + "---|" * (len(keys) + len(SIT) + 2)]
    for k, s in rows:
        sp = s["situations_per_fight"]
        lines.append("| " + " | ".join(k) + " | " + " | ".join(fmt(sp[x], 2) for x in SIT) + f" | {fmt(sp['fights_with_any'], 0)}% | {fmt(sp['ground_hits'], 1)} |")
    return lines + ["", "(each a mean a fight; fights with any: a situation change other than a townsman hit)", ""]


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    runs = [a for a in argv if not a.startswith("--")]
    run = runs[0]
    out = next((a.split("=", 1)[1] for a in argv if a.startswith("--out=")), run)
    fights = [f for r in runs for f in load(r)]
    where = next((a.split("=", 1)[1] for a in argv if a.startswith("--where=")), "")
    for cond in filter(None, where.split(",")):
        k, v = cond.split("=")
        fights = [f for f in fights if str(f[k]) == v]
    run = " + ".join(runs) + (f" where {where}" if where else "")
    if not fights:
        print("no fights in", run)
        return 1
    os.makedirs(out, exist_ok=True)
    vs = next((a.split("=", 1)[1] for a in argv if a.startswith("--vs=")), "")
    if vs:
        before = load(vs)
        for cond in filter(None, where.split(",")):
            k, v = cond.split("=")
            before = [f for f in before if str(f[k]) == v]
        md = [f"# Gunfight lab: {vs} (before) against {run} (after)", ""] + compare(before, fights, "All")
        for (sc,), fs in sorted(group(fights, ("scenario",)).items()):
            md += compare([f for f in before if f["scenario"] == sc], fs, sc)
        with open(os.path.join(out, "compare.md"), "w") as fh:
            fh.write("\n".join(md))
        print("->", os.path.join(out, "compare.md"))
        return 0
    data = {"all": summary(fights)}
    md = [f"# Gunfight lab: {len(fights)} fights ({run})", ""]
    if os.path.exists(os.path.join(runs[0], "manifest.json")):
        man = json.load(open(os.path.join(runs[0], "manifest.json")))
        md += [f"Source {man.get('source')}, {man.get('godot')}, fights capped at {man.get('max_s')} s.", ""]
    for keys, title in [(("bodies",), "By bodies"), (("scenario", "hour", "weapon", "bodies"), "By arena, hour and gun (the three styles pooled)"),
                        (("style", "bodies"), "By the scripted player's style"), (("scenario", "style", "bodies"), "By arena and style")]:
        g = group(fights, keys)
        rows = [(k, summary(v)) for k, v in sorted(g.items())]
        data[" x ".join(keys)] = {" ".join(k): s for k, s in rows}
        md += table(rows, keys, title)
    for b, fs in sorted(group(fights, ("bodies",)).items()):
        md += men_table(summary(fs), f"Each man ({b[0]} bodies)")
    rows = [(k, summary(v)) for k, v in sorted(group(fights, ("scenario", "bodies")).items())]
    md += sit_table(rows, ("scenario", "bodies"), "Situation changes")
    md += ["### What the three men cost a frame (headless, this workspace's core; x0.65 for Sean's)", "",
           "| bodies | people ms a frame | the second before they came | the three men | people p95 | whole physics frame |", "|---|---|---|---|---|---|"]
    for b, fs in sorted(group(fights, ("bodies",)).items()):
        s = summary(fs)
        calm = mean([f["perf"]["people_calm_ms"] for f in fs])
        md.append(f"| {b[0]} | {fmt(s['people_ms'], 2)} | {fmt(calm, 2)} | {fmt(s['three_men_ms'], 2)} | {fmt(s['people_p95_ms'], 2)} | {fmt(s['frame_ms'], 2)} |")
    md += ["", "### Steadiness: the first half of the seeds against the second", "",
           "| setup group | fights | median length, seeds first half | second half | gang hit first, first half | second half |", "|---|---|---|---|---|---|"]
    for k, fs in sorted(group(fights, ("scenario", "bodies")).items()):
        seeds = sorted({f["seed"] for f in fs})
        a = [f for f in fs if f["seed"] in seeds[: len(seeds) // 2]]
        b = [f for f in fs if f["seed"] in seeds[len(seeds) // 2:]]
        if a and b:
            sa, sb = summary(a), summary(b)
            md.append(f"| {' '.join(k)} | {len(fs)} | {fmt(sa['length_median_s'])} | {fmt(sb['length_median_s'])} | {fmt(sa['gang_hit_first_pct'], 0)}% | {fmt(sb['gang_hit_first_pct'], 0)}% |")
    for b, fs in sorted(group(fights, ("bodies",)).items()):
        dg = diagnostics(fs)
        data[f"diagnostics {b[0]}"] = dg
        md += [f"### Why fights are short: diagnostics ({b[0]} bodies)", ""] + [f"- {k}: {v}" for k, v in dg.items()] + [""]
    notes = data["all"]["body_notes"]
    md += ["", "### Body notes (what the fight's setup found missing on a man)", ""] + ([f"- {n}" for n in notes] or ["- none"]) + [""]
    with open(os.path.join(out, "baseline.md"), "w") as fh:
        fh.write("\n".join(md))
    with open(os.path.join(out, "baseline.json"), "w") as fh:
        json.dump(data, fh, indent=1, default=str)
    cols = ["_name", "scenario", "hour", "weapon", "style", "bodies", "seed", "length_s", "end", "ending", "first_shot_by", "first_shot_at",
            "first_hit_by", "first_hit_at", "longest_quiet_s"]
    with open(os.path.join(out, "fights.csv"), "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(cols + ["you_shots", "you_hits", "you_hits_taken", "you_first_hit_at", "you_near_misses", "you_down", "gang_shots",
                           "you_cover_moves", "you_stuck"] + SIT + [f"{m}_{k}" for m in MEN for k in ("outcome", "shots", "cover_changes", "flanks", "suppressing_shots")]
                   + ["three_men_ms"])
        for f in fights:
            w.writerow([f[c] for c in cols] + [f["you"]["shots"], f["you"]["hits"], f["you"]["hits_taken"], f["you"]["first_hit_at"], f["you"]["near_misses"],
                                                f["you"]["down"], f["gang"]["shots"], f["you"].get("cover_moves", 0), f["you"].get("stuck", 0)]
                       + [f["situations"].get(k, 0) for k in SIT]
                       + [f["men"].get(m, {}).get(k, "") for m in MEN for k in ("outcome", "shots", "cover_changes", "flanks", "suppressing_shots")]
                       + [f["perf"]["three_men_ms"]])
    print(f"{len(fights)} fights -> {out}/baseline.md, baseline.json, fights.csv")
    s = data["all"]
    print(f"length median {fmt(s['length_median_s'])} s, in 45-90 {fmt(s['in_45_90_pct'], 0)}%, gang hit first {fmt(s['gang_hit_first_pct'], 0)}%, "
          f"endings {endings_line(s['endings'], s['fights'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
