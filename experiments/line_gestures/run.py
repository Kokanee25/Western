#!/usr/bin/env python3
"""The line gestures bench (#1316): what a man saying a line does now, and what the men by him do, in
the running valley, gestures off (the before) and on. Usage:

    python3 experiments/line_gestures/run.py OUT_DIR [--only=bar,street] [--hours=2]

Each spot x mode is its own headless game (three at once at most: a valley is ~3.5 GB). An evening in
saloon B (20:00, `--no-murder`) stood at the bar; Main Street by day (13:00) walked end to end. Writes
OUT_DIR/<spot>_<off|on>.json (bridge.gd's lines) and OUT_DIR/table.md: lines heard, how many had a
tag, and for speakers and listeners the share whose face moved (> 0.15 of a shape), whose arms moved
(> 8 degrees), body (> 4) and head (> 6), and the median of each.
"""
import json, os, subprocess, sys, statistics
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
BRIDGE = [sys.executable, os.path.join(ROOT, "tools", "bridge.py")]
WALK = ["hotel_walk", "store_walk", "saloon_porch", "livery_door", "smith_door", "livery_door", "saloon_porch",
        "store_walk", "hotel_walk", "undertaker_walk", "bank_walk", "undertaker_walk"]
SPOTS = {"bar": (20.0, ["walk saloon_room", "drink bar"]), "street": (13.0, ["walk hotel_walk"])}
FACE, ARMS, BODY, HEAD = 0.15, 8.0, 4.0, 6.0


def bridge(port, *cmds, timeout=3000):
    p = subprocess.run(BRIDGE + list(cmds) + ["--port=%d" % port, "--timeout=%d" % timeout], capture_output=True,
                       text=True, cwd=ROOT, timeout=timeout + 120)
    out = []
    for line in p.stdout.splitlines():
        if line.strip().startswith("{"):
            try:
                out.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    return out


def one(job, hours):
    name, on, port = job
    hour, setup = SPOTS[name]
    subprocess.run(BRIDGE + ["stop", "--port=%d" % port], capture_output=True, cwd=ROOT)
    p = subprocess.run(BRIDGE + ["start", "--headless", "--port=%d" % port, "--game-args=--world=valley,--no-murder"],
                       capture_output=True, text=True, cwd=ROOT, timeout=1200)
    if p.returncode != 0:
        return job, {"error": p.stdout[-300:] + p.stderr[-300:]}
    bridge(port, "lg_on %d" % (1 if on else 0), "time %.2f" % hour, "clock on", "wait 15", *setup)
    bridge(port, "lg_start")
    s = hours * 112.5
    if name == "street":
        t0, i = None, 0
        while True:
            r = bridge(port, "walk " + WALK[i % len(WALK)], "wait 12")
            i += 1
            t = float(r[-1].get("t", 0)) if r else 0
            t0 = t if t0 is None else t0
            if t - t0 >= s or not r:
                break
    else:
        bridge(port, "wait %d" % s)
    res = bridge(port, "lg_stop")
    subprocess.run(BRIDGE + ["stop", "--port=%d" % port], capture_output=True, cwd=ROOT)
    return job, (res[0] if res else {"error": "no answer"})


def share(rows, key, lim):
    return "%d%%" % round(100.0 * sum(1 for r in rows if r.get(key, 0) > lim) / len(rows)) if rows else "-"


def med(rows, key):
    return "%.2f" % statistics.median(r.get(key, 0) for r in rows) if rows else "-"


def row(name, on, d):
    ls = [l for l in d.get("lines", []) if l.get("d", 99) <= 15.0 and "speaker" in l]
    sp = [l["speaker"] for l in ls]
    li = [x for l in ls for x in l.get("listeners", [])]
    tagged = sum(1 for l in ls if l.get("tag") not in ("calm", ""))
    cells = [name, "on" if on else "off", str(len(ls)), str(tagged)]
    for rows in (sp, li):
        cells += [share(rows, "face", FACE), share(rows, "arms", ARMS), share(rows, "body", BODY), share(rows, "head", HEAD),
                  med(rows, "face"), med(rows, "arms")]
    return "| " + " | ".join(cells) + " |"


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    only = [a.split("=", 1)[1].split(",") for a in sys.argv if a.startswith("--only=")]
    hours = float(([a.split("=", 1)[1] for a in sys.argv if a.startswith("--hours=")] or ["2"])[0])
    names = only[0] if only else list(SPOTS)
    jobs = [(n, on, 8751 + i * 2 + on) for i, n in enumerate(names) for on in (0, 1)]
    with ThreadPoolExecutor(min(3, len(jobs))) as ex:
        results = list(ex.map(lambda j: one(j, hours), jobs))
    rows = ["| spot | gestures | lines within 15 m | tagged | speaker: face moved | arms | body | head | face median | arms median (deg) "
            "| listeners: face moved | arms | body | head | face median | arms median (deg) |",
            "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for (name, on, _), d in results:
        json.dump(d, open(os.path.join(out, "%s_%s.json" % (name, "on" if on else "off")), "w"), indent=1)
        rows.append(row(name, on, d) if "lines" in d else "| %s | %s | failed: %s |" % (name, on, str(d.get("error"))[:80]))
    open(os.path.join(out, "table.md"), "w").write("\n".join(rows) + "\n")
    print("\n".join(rows))


if __name__ == "__main__":
    main()
