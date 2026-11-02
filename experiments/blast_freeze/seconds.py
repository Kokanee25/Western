#!/usr/bin/env python3
"""The blast-freeze lab's long runs second by second (#584: the farmhouse's slow motion): for each
`bf_blast ... seconds=60 out=FILE.json`, a row a second from the first stick: the frames' median and
worst (ms, this workspace's clock), how many over 33 ms, the biggest timers' means, the rubble awake,
and the body census (bf_blast's twice-a-second `bodies`: speeds, on the ground, on steep ground,
touching). Seconds are counted from the LAST stick.

    python3 experiments/blast_freeze/seconds.py build/farm/a.json [--every=5] [--top=6]
    python3 experiments/blast_freeze/seconds.py --brief build/farm/*.json   # a line a run: broken, awake after, asleep when
"""
import json
import statistics
import sys

SKIP = ("q_", "n_", "rest_")


def rows(path, every=5, top=6):
    d = json.load(open(path))
    s = d["setup"]
    frames = [f for f in d["frames"] if f["after"] >= 0]
    last = int(round(s["gap"] * (len(s["spots"]) - 1) * 60))
    print(f"{path}: {s['in']}, {len(s['spots'])} sticks {s['gap']} s apart, broken {s['broken_now']} "
          f"(hash {s['broken_ids_hash']}), people {s['people']}, rubble at the end {s.get('rubble_end', '?')}")
    by_sec = {}
    for f in frames:
        sec = (f["after"] - last) // 60
        by_sec.setdefault(sec, []).append(f)
    print(f"{'s':>4} {'med':>6} {'worst':>6} {'>33':>4}  {'awake':>5} {'active':>6}  census  | top timers (mean ms a frame)")
    for sec in sorted(by_sec):
        if sec > 2 and sec % every and sec != max(by_sec):
            continue
        fs = by_sec[sec]
        ms = [f["ms"] for f in fs]
        tot = {}
        for f in fs:
            for k, v in f["prof"].items():
                if k.startswith(SKIP):
                    continue
                tot[k] = tot.get(k, 0.0) + float(v)
        keys = sorted(tot, key=lambda k: -tot[k])[:top]
        cen = [f["bodies"] for f in fs if "bodies" in f]
        c = cen[-1] if cen else None
        cs = (f"v{c['v_med']:.3f} slow{c['under_sleep_v']} creep{c['creeping']} gnd{c['on_ground']} "
              f"steep{c['on_steep']} touch{c['touching']}") if c else ""
        print(f"{sec:>4} {statistics.median(ms):6.1f} {max(ms):6.1f} {sum(1 for x in ms if x > 33):>4}  "
              f"{fs[-1]['awake']:>5} {fs[-1]['active']:>6}  {cs} | "
              + ", ".join(f"{k} {tot[k] / len(fs):.1f}" for k in keys))


def brief(path):
    """A line a run: what broke, how many awake 2/5/10/20 s after the last stick and at the end, when
    it settled (fewer than 50 awake from then on; s after the last stick; None: not by the end), the frames' median from +3 s on, and
    how many pieces Ground lifted out of the earth or rescued from under it."""
    d = json.load(open(path))
    s = d["setup"]
    last = int(round(s["gap"] * (len(s["spots"]) - 1) * 60))
    fr = [f for f in d["frames"] if f["after"] >= 0]

    def at(sec):
        c = [f for f in fr if f["after"] - last >= sec * 60]
        return c[0]["awake"] if c else None
    # Settled: fewer than 50 awake from then to the end (a few pieces still rolling cost nothing).
    asleep = None
    for f in reversed(fr):
        if f["after"] <= last or f["awake"] >= 50:
            break
        asleep = round((f["after"] - last) / 60, 1)
    tail = [f["ms"] for f in fr if f["after"] - last >= 180]
    cen = [f["bodies"] for f in fr if "bodies" in f]
    c = cen[-1] if cen else {}
    print(f"{path.split('/')[-1]:16} broken {s['broken_now']:4d}  awake +2 {at(2)} +5 {at(5)} +10 {at(10)} +20 {at(20)} "
          f"end {fr[-1]['awake']}  settled at +{asleep}  median from +3 s {statistics.median(tail) if tail else 0:.1f} ms  "
          f"lifted {c.get('lifted')} rescued {c.get('rescued')}")


if __name__ == "__main__":
    if "--brief" in sys.argv:
        for p in [a for a in sys.argv[1:] if not a.startswith("--")]:
            brief(p)
        sys.exit(0)
    opts = {a.split("=")[0][2:]: a.split("=")[1] for a in sys.argv[1:] if a.startswith("--")}
    for p in [a for a in sys.argv[1:] if not a.startswith("--")]:
        rows(p, int(opts.get("every", 5)), int(opts.get("top", 6)))
