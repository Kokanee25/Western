#!/usr/bin/env python3
"""The perception lab's runs (README.md beside this file): one fresh game a group, driven through
the dev bridge (`perception GROUP ...`, this lab's bridge.gd), several at once.

    python3 experiments/perception_lab/run.py --out=build/perception_lab/base          # every group
    python3 experiments/perception_lab/run.py --group=sight,hearing --out=...
    python3 experiments/perception_lab/run.py --case=street_10m --out=...               # one case
    python3 experiments/perception_lab/run.py --list
    python3 experiments/perception_lab/run.py --repeat=2 --out=...   # each group twice: same seed, same result?
    python3 experiments/perception_lab/run.py --table=ROOT            # the tables again (no Godot)
    python3 experiments/perception_lab/run.py --table=ROOT --keep=experiments/perception_lab/baseline  # commit it

--seed=N (default scenarios.json's), --jobs=N (default 3).
"""
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
LAB = os.path.join(ROOT, "experiments", "perception_lab")
GROUPS = ["sight", "hearing", "search", "news", "leaks"]


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a == "--" + name:
            return "1"
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def data():
    with open(os.path.join(LAB, "scenarios.json")) as f:
        return json.load(f)


def run_one(job):
    want, out_dir, port, seed = job
    os.makedirs(out_dir, exist_ok=True)
    cmds = os.path.join(out_dir, "cmds.txt")
    with open(cmds, "w") as f:
        f.write(f"perception {want} seed={seed} out={out_dir}\nquit\n")
    godot = os.environ.get("GODOT", "godot")
    cmd = [godot, "--path", ROOT, "--headless", "--fixed-fps", "60", "--", "--dev-bridge",
           f"--bridge-port={port}", f"--bridge-script={cmds}"]
    t0 = time.time()
    log_path = os.path.join(out_dir, "godot.log")
    with open(log_path, "w") as log:
        proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        limit = t0 + 1800
        quit_at = None
        while proc.poll() is None and time.time() < limit:
            time.sleep(1)
            if quit_at is None and '"cmd":"quit"' in open(log_path, errors="replace").read():
                quit_at = time.time()
            if quit_at is not None and time.time() - quit_at > 20:
                break
        if proc.poll() is None:
            try:
                os.killpg(proc.pid, 9)
            except ProcessLookupError:
                pass
            proc.wait()
    ok = os.path.exists(os.path.join(out_dir, "summary.json"))
    print(f"{'ok ' if ok else 'FAILED'} {want:28} {time.time() - t0:5.0f}s", flush=True)
    return ok


def load(root):
    out = []
    for name in sorted(os.listdir(root)):
        p = os.path.join(root, name, "summary.json")
        if os.path.exists(p) and "_repeat" not in name:
            with open(p) as f:
                out.append(json.load(f))
    return out


def results(root):
    rows = []
    for s in load(root):
        rows += s["results"]
    return rows


def mark(v):
    return {"missed": "MISSED", "false": "FALSE", "slow": "slow", "as_expected": "ok", "either": "-"}[v["verdict"]]


def yn(b):
    return "yes" if b else "no"


def sight_table(rows):
    lines = ["| case | light | distance m | line (Senses' ray meets) | Senses light | spotted s | expected | verdict |",
             "|---|---|---|---|---|---|---|---|"]
    for r in rows:
        v = r["verdicts"][0]
        sp = f"{r['spotted_s']:.2f}" if r["spotted_s"] >= 0 else "never"
        exp = {True: "sees", False: "doesn't", "either": "either"}[v["expect"]]
        lines.append(f"| {r['case']} | {r['light']} | {r['distance_m']:.1f} | {r['line'] or 'clear'} | {r['senses_light']:.2f} | "
                     f"{sp} | {exp} | {mark(v)} |")
    return "\n".join(lines)


def hearing_table(rows):
    lines = ["| case (game reach m) | listener | m | wall | heard | took it for | where (err m / deg) | knows who | verdicts |",
             "|---|---|---|---|---|---|---|---|---|"]
    for r in rows:
        for i, l in enumerate(r["listeners"]):
            vs = [v for v in r["verdicts"] if v["what"].startswith(l["listener"] + " ")]
            heard = (f"{l['heard']} steps" if r["source"] == "steps" else yn(l["heard"])) if l["heard"] else "no"
            where = f"{l['guess_error_m']:.1f} / {l['bearing_error_deg']:.0f}" if l["heard"] else ""
            verdicts = ", ".join(f"{v['what'][len(l['listener']) + 1:]}: {mark(v)}" for v in vs if v["verdict"] != "either")
            lines.append(f"| {r['case']} ({r['noise_reach_m']:.0f}) | {l['listener']} | {l['distance_m']:.1f} | {l['wall'] or ''} | "
                         f"{heard} | {l.get('took_it_for', '')} | {where} | {yn(l.get('knows_who')) if l['heard'] else ''} | {verdicts} |")
    return "\n".join(lines)


def search_table(rows):
    lines = ["| case | lost (truth) s | lost (Senses) s | delay s | last-known error at loss m | nearest to last-known m | "
             "nearest to his spot m | found again s after | gave up s after | leaks | verdicts |", "|---|---|---|---|---|---|---|---|---|---|---|"]
    for r in rows:
        verdicts = ", ".join(f"{v['what']}: {mark(v)}" for v in r["verdicts"] if v["verdict"] != "either")
        gave = f"{r['remembered_s']:.0f}" if r["remembered_s"] >= 0 else "didn't"
        found = f"{r['found_again_s']:.0f}" if r.get("found_again_s", -1) >= 0 else "no"
        lines.append(f"| {r['case']} | {r['lost_truth_s']:.2f} | {r['lost_senses_s']:.2f} | {r['lost_delay_s']:.2f} | "
                     f"{r['lk_error_at_loss_m']:.1f} | {r['nearest_to_last_known_m']:.1f} | {r['nearest_to_true_spot_m']:.1f} | "
                     f"{found} | {gave} | {len(r['leaks'])} | {verdicts} |")
    return "\n".join(lines)


def news_table(rows):
    lines = ["| case | person | t s | heard shot | saw who | knows who | who from the sound only | knows a man was hit | knows the hold-up | mood |",
             "|---|---|---|---|---|---|---|---|---|---|"]
    for r in rows:
        for t, snap in r["snapshots"].items():
            for who, k in snap.items():
                lines.append(f"| {r['case']} | {who} | {t} | {yn(k['heard_shot'])} | {yn(k['saw_shooter'] or k['who_by_sight'])} | "
                             f"{yn(k['knows_who'])} | {yn(k['who_by_sound_only'])} | {yn(k['knows_victim_hurt'])} | "
                             f"{yn(k['knows_holdup'])} | {k.get('mood', '')} |")
    return "\n".join(lines)


def leaks_table(rows):
    lines = ["| case | what he got | verdicts |", "|---|---|---|"]
    for r in rows:
        keep = {k: v for k, v in r.items() if k not in ("verdicts", "leaks", "track", "callouts", "why", "setup", "group",
                                                         "case", "light", "daylight")}
        verdicts = ", ".join(f"{v['what']}: {mark(v)}" for v in r["verdicts"])
        lines.append(f"| {r['case']} | {json.dumps(keep)} | {verdicts} |")
    return "\n".join(lines)


def table(root):
    rows = results(root)
    by = {g: [r for r in rows if r["group"] == g] for g in GROUPS}
    counts = {"cases": 0, "judged": 0, "as_expected": 0, "missed": 0, "false": 0, "slow": 0, "leaks": 0}
    per = {}
    for g in GROUPS:
        c = {"judged": 0, "as_expected": 0, "missed": 0, "false": 0, "slow": 0, "leaks": 0}
        for r in by[g]:
            for v in r.get("verdicts", []):
                if v["verdict"] != "either":
                    c["judged"] += 1
                    c[v["verdict"]] += 1
            c["leaks"] += len(r.get("leaks", []))
        per[g] = c
        counts["cases"] += len(by[g])
        for k in c:
            counts[k] += c[k]
    out = ["## Counts", "", "| group | runs | judged | as expected | missed | false | slow | leaks (sampled) |", "|---|---|---|---|---|---|---|---|"]
    for g in GROUPS:
        c = per[g]
        out.append(f"| {g} | {len(by[g])} | {c['judged']} | {c['as_expected']} | {c['missed']} | {c['false']} | {c['slow']} | {c['leaks']} |")
    out.append(f"| **all** | {counts['cases']} | {counts['judged']} | {counts['as_expected']} | {counts['missed']} | {counts['false']} | "
               f"{counts['slow']} | {counts['leaks']} |")
    for g, fn in (("sight", sight_table), ("hearing", hearing_table), ("search", search_table), ("news", news_table),
                  ("leaks", leaks_table)):
        if by[g]:
            out += ["", f"## {g.capitalize()}", "", fn(by[g])]
    return "\n".join(out), counts


def fingerprint(s):
    """What should be the same run to run on one seed: every verdict and its delay."""
    return [(r["case"], r.get("light"), [(v["what"], v["verdict"], v.get("delay_s")) for v in r.get("verdicts", [])])
            for r in s["results"]]


def compare(root):
    same = True
    for name in sorted(os.listdir(root)):
        if name.endswith("_repeat"):
            continue
        a, b = os.path.join(root, name, "summary.json"), os.path.join(root, name + "_repeat", "summary.json")
        if os.path.exists(a) and os.path.exists(b):
            fa, fb = fingerprint(json.load(open(a))), fingerprint(json.load(open(b)))
            diff = [(x, y) for x, y in zip(fa, fb) if x != y]
            print(f"{name}: {'same' if not diff else f'{len(diff)} differ'}")
            for x, y in diff[:5]:
                print("   ", x, "\n    ", y)
            same = same and not diff
    return same


def keep(root, dest):
    """The baseline for the repo: the tables and every summary with its per-tick tracks left out."""
    os.makedirs(dest, exist_ok=True)
    md, counts = table(root)
    with open(os.path.join(dest, "tables.md"), "w") as f:
        f.write("# The perception lab's baseline: the tables\n\n(Written by `run.py --table=ROOT --keep=...`; "
                "what they show is in `baseline.md`.)\n\n" + md + "\n")
    slim = []
    for s in load(root):
        s = dict(s)
        s["results"] = [{k: v for k, v in r.items() if k != "track"} for r in s["results"]]
        slim.append(s)
    with open(os.path.join(dest, "baseline.json"), "w") as f:
        json.dump({"counts": counts, "groups": slim}, f, indent=1)
    print(f"kept {dest}: tables.md, baseline.json")


def main():
    if opt("list"):
        d = data()
        for g in GROUPS:
            print(g + ":", ", ".join(c["name"] for c in d[g]["cases"]))
        return 0
    if opt("table"):
        md, counts = table(opt("table"))
        print(md)
        if opt("keep"):
            keep(opt("table"), opt("keep"))
        return 0
    if opt("compare"):
        return 0 if compare(opt("compare")) else 1
    out = os.path.abspath(opt("out", "build/perception_lab/run"))
    seed = int(opt("seed", data().get("seed", 1)))
    wants = opt("case", "").split(",") if opt("case") else (opt("group", ",".join(GROUPS)).split(","))
    jobs = []
    port = 8800
    for w in wants:
        for rep in range(int(opt("repeat", "1"))):
            jobs.append((w, os.path.join(out, w + ("_repeat" if rep else "")), port, seed))
            port += 1
    with ThreadPoolExecutor(max_workers=int(opt("jobs", "3"))) as ex:
        oks = list(ex.map(run_one, jobs))
    md, counts = table(out)
    with open(os.path.join(out, "tables.md"), "w") as f:
        f.write(md + "\n")
    print(json.dumps(counts))
    print(f"tables: {os.path.join(out, 'tables.md')}")
    if int(opt("repeat", "1")) > 1:
        compare(out)
    return 0 if all(oks) else 1


if __name__ == "__main__":
    sys.exit(main())
