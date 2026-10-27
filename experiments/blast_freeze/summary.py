#!/usr/bin/env python3
"""The blast-freeze lab's runs side by side (more-cores step 5): for each `bf_blast ... out=FILE.json`
the frames' mean, p95 and worst (ms, this workspace's clock), how many are over 20 and 50 ms, and
each timer's total and its worst single frame, before the stick (the fire burning, the town
watching) and after it. `--same A B` compares two runs of one build: the broken set and the frames'
per-frame counters (what broke, what's hot) must match.

    python3 experiments/blast_freeze/summary.py build/step5/before_a.json build/step5/after_a.json
    python3 experiments/blast_freeze/summary.py --same build/step5/after_a.json build/step5/after_b.json
"""
import json
import sys

TIMERS = ["civilian_brain", "fire", "fire_tick", "fire_grid", "fire_loads", "fire_analyse", "fire_apply",
          "fire_fx", "fire_near", "fire_flee", "smoke", "batches", "dynamite", "blast_break", "people_body",
          "senses", "physics_step", "untimed"]


def pct(xs, p):
    if not xs:
        return 0.0
    s = sorted(xs)
    return s[min(len(s) - 1, int(round(p / 100.0 * (len(s) - 1))))]


def part(frames, label):
    ms = [f["ms"] for f in frames]
    out = [f"  {label}: {len(ms)} frames, mean {sum(ms) / max(len(ms), 1):.1f}, p95 {pct(ms, 95):.1f}, "
           f"worst {max(ms or [0]):.1f}; over 20 ms {sum(1 for x in ms if x > 20)}, over 50 ms {sum(1 for x in ms if x > 50)}"]
    keys = set()
    for f in frames:
        keys.update(f["prof"].keys())
    rows = []
    for k in keys:
        if k.startswith("q_") or k.startswith("n_"):
            continue
        vals = [float(f["prof"].get(k, 0.0)) for f in frames]
        rows.append((sum(vals), k, max(vals), pct(vals, 95)))
    rows.sort(reverse=True)
    for tot, k, worst, p95 in rows[:14]:
        out.append(f"    {k:<18} total {tot:8.1f}  p95 {p95:6.1f}  worst {worst:6.1f}")
    return out


def summary(path):
    d = json.load(open(path))
    frames = d["frames"]
    before = [f for f in frames if f["after"] < 0]
    after = [f for f in frames if f["after"] >= 0]
    s = d["setup"]
    lines = [f"{path}: broken {s['broken_now']} (hash {s['broken_ids_hash']}), cut {s['cut']}, "
             f"rubble {s['rubble_after']}, burning {s['burning_before']} -> {s['burning_after']}"]
    lines += part(before, "before the stick (1 s)")
    lines += part(after, "the stick and after")
    lines += part([f for f in after if f["after"] > 60], "after the stick's first second")
    return "\n".join(lines)


def same(a, b):
    da, db = json.load(open(a)), json.load(open(b))
    ok = da["setup"]["broken_ids_hash"] == db["setup"]["broken_ids_hash"]
    print(f"broken set: {'same' if ok else 'DIFFERENT'} ({da['setup']['broken_ids_hash']} / {db['setup']['broken_ids_hash']})")
    fa = {f["tick"] - (da['frames'][0]['tick']): f for f in da["frames"]}
    fb = {f["tick"] - (db['frames'][0]['tick']): f for f in db["frames"]}
    diff = 0
    for t in sorted(set(fa) & set(fb)):
        x, y = fa[t], fb[t]
        if (x["after"], x["broken"], x["hot"]) != (y["after"], y["broken"], y["hot"]):
            if diff < 5:
                print(f"  tick +{t}: after/broken/hot {x['after']}/{x['broken']}/{x['hot']} vs {y['after']}/{y['broken']}/{y['hot']}")
            diff += 1
    print(f"frames compared {len(set(fa) & set(fb))}, differing {diff}")
    for k in ("cut", "rubble_after", "burning_after", "members_after"):
        if da["setup"][k] != db["setup"][k]:
            ok = False
            print(f"  {k}: {da['setup'][k]} vs {db['setup'][k]}")
    return ok and diff == 0


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "--same":
        sys.exit(0 if same(args[1], args[2]) else 1)
    for p in args:
        print(summary(p))
