#!/usr/bin/env python3
"""The listening bench (#1293): what you hear in four game hours stood at each spot. Usage:

    python3 experiments/overheard/run.py OUT_DIR [--only=bar,table,porch,store,walk] [--murder]

Each spot is its own headless game (its own port, all at once): an ordinary evening in saloon B
20:00-24:00 (`--no-murder`; `--murder` leaves No Law's night on) stood at the bar, by the back table
and on the porch; Main Street by day stood on the store's walk 08:00-12:00 and walked end to end
13:00-17:00. Writes OUT_DIR/<spot>.json (every line: who, words, metres off, clock, kind, clarity;
pairs of men within 6 m, in game minutes) and OUT_DIR/table.md.
A game hour is 112.5 s (config/day_cycle.tres), so four are 450 s.
"""
import json, os, subprocess, sys, collections
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
BRIDGE = [sys.executable, os.path.join(ROOT, "tools", "bridge.py")]
HOURS = 4.0
S = HOURS * 112.5
WALK = ["hotel_walk", "store_walk", "saloon_porch", "livery_door", "smith_door", "livery_door", "saloon_porch",
        "store_walk", "hotel_walk", "undertaker_walk", "bank_walk", "undertaker_walk"]
SPOTS = {
    "bar": (8741, 20.0, ["walk saloon_room", "drink bar"]),
    "table": (8742, 20.0, ["walk saloon_room", "oh_by liveryman 2.5"]),
    "porch": (8743, 20.0, ["walk saloon_porch"]),
    "store": (8744, 8.0, ["walk store_walk"]),
    "walk": (8745, 13.0, ["walk hotel_walk"]),
}
# Heard: the old subtitle shows any line within 45 m; near is what a man stood there would catch.
SHOWN_M, NEAR_M = 45.0, 10.0


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


def one(name, murder):
    port, hour, setup = SPOTS[name]
    subprocess.run(BRIDGE + ["stop", "--port=%d" % port], capture_output=True, cwd=ROOT)
    args = "--world=valley" + ("" if murder else ",--no-murder")
    p = subprocess.run(BRIDGE + ["start", "--headless", "--port=%d" % port, "--game-args=" + args], capture_output=True,
                       text=True, cwd=ROOT, timeout=1200)
    if p.returncode != 0:
        return name, {"error": p.stdout[-300:] + p.stderr[-300:]}
    bridge(port, "time %.2f" % hour, "clock on", "wait 15", *setup)
    start = bridge(port, "oh_where", "oh_start")
    if name == "walk":
        t0 = None
        i = 0
        while True:
            r = bridge(port, "walk " + WALK[i % len(WALK)], "wait 12")
            i += 1
            t = float(r[-1].get("t", 0)) if r else 0
            t0 = t if t0 is None else t0
            if t - t0 >= S or not r:
                break
    else:
        bridge(port, "wait %d" % S)
    res = bridge(port, "oh_stop", "oh_where")
    subprocess.run(BRIDGE + ["stop", "--port=%d" % port], capture_output=True, cwd=ROOT)
    d = res[0] if res else {"error": "no answer"}
    d["start"] = start[0] if start else {}
    return name, d


def row(name, d):
    lines = d.get("lines", [])
    hours = float(d.get("s", S)) / 112.5 or 1.0
    shown = [l for l in lines if l[2] <= SHOWN_M and (l[4] == "said" or l[5] >= 0.12)]
    near = [l for l in lines if l[2] <= NEAR_M]
    ex = [l for l in shown if str(l[4]).startswith("exchange:")]
    texts = collections.Counter(l[1] for l in shown)
    rep = sum(n - 1 for n in texts.values())
    exch = len(set(l[4] for l in ex))
    return "| %s | %.1f | %d | %.1f | %d | %.1f | %d | %d (%.0f%%) | %d |" % (
        name, hours, len(shown), len(shown) / hours, len(near), len(near) / hours, len(texts), rep,
        100.0 * rep / max(len(shown), 1), exch)


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    only = [a.split("=", 1)[1].split(",") for a in sys.argv if a.startswith("--only=")]
    names = only[0] if only else list(SPOTS)
    murder = "--murder" in sys.argv
    with ThreadPoolExecutor(len(names)) as ex:
        results = list(ex.map(lambda n: one(n, murder), names))
    rows = ["| spot | game hours | lines shown | an hour | within 10 m | an hour | different lines | repeats | exchanges |",
            "|---|---|---|---|---|---|---|---|---|"]
    for name, d in results:
        json.dump(d, open(os.path.join(out, name + ".json"), "w"), indent=1)
        rows.append(row(name, d) if "lines" in d else "| %s | failed: %s |" % (name, str(d.get("error"))[:80]))
    open(os.path.join(out, "table.md"), "w").write("\n".join(rows) + "\n")
    print("\n".join(rows))


if __name__ == "__main__":
    main()
