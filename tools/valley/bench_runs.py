#!/usr/bin/env python3
"""The valley's frame bench, every count and scene (#865, the review's R4).

Runs tools/perf_bench.gd in the valley one game at a time (never two at once: they'd share the
core), each scene with 0, 5, 10, 15 and 25 more townsfolk, and writes the table: each scene's frame
and its budget parts at Sean's (FrameBudget's clock_scale), the people's systems, the men by band.

    python3 tools/valley/bench_runs.py [--counts=0,5,10,15,25] [--scenes=day,night,gunfight,blast]
        [--seconds=10] [--bands] [--ablate=15] [--render] [--out=build/valley_bench]

--bands: also the day with 10 townsfolk all near, then all far (the per-man cost of each band).
--ablate=N: also day and night with N townsfolk, each system switched off in turn (what it saves).
--render: one drawn run a scene under lavapipe (xvfb, Vulkan) with 15 townsfolk: render CPU only.
Each game's log and JSON go in --out; the table is --out/table.md (and printed).
"""
import json
import subprocess
import sys
import time
from pathlib import Path

GODOT = "godot"
PEOPLE = ["people_body", "people_skeleton", "people_prep", "people_bands", "senses", "civilian_brain",
          "outlaw_brain", "player", "valley_folk", "blood", "faces", "cloth", "mop"]
PARTS = ["people", "physics", "structures", "fire_effects", "else", "total"]
BUDGET = {"people": 4.0, "physics": 2.0, "structures": 1.0, "fire_effects": 2.0, "render_cpu": 4.0, "else": 1.0, "total": 14.0}
SCALE = 0.65


def arg(name, default):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
        if a == f"--{name}":
            return True
    return default


def run(out: Path, tag: str, args: list, drawn=False, timeout=1800) -> dict:
    js = out / f"{tag}.json"
    log = out / f"{tag}.log"
    if drawn:
        cmd = ["xvfb-run", "-a", GODOT, "--rendering-driver", "vulkan", "-s", "res://tools/perf_bench.gd", "--"]
    else:
        cmd = [GODOT, "--headless", "--fixed-fps", "60", "-s", "res://tools/perf_bench.gd", "--"]
    cmd += ["--world=valley", f"--out={js}"] + args
    t = time.time()
    with open(log, "w") as f:
        subprocess.run(cmd, stdout=f, stderr=subprocess.STDOUT, timeout=timeout)
    print(f"  {tag}: {time.time() - t:.0f} s", flush=True)
    try:
        return json.loads(js.read_text())
    except (OSError, ValueError):
        print(f"  {tag}: no result (see {log})")
        return {}


def main():
    out = Path(arg("out", "build/valley_bench"))
    out.mkdir(parents=True, exist_ok=True)
    counts = [int(c) for c in str(arg("counts", "0,5,10,15,25")).split(",")]
    scenes = str(arg("scenes", "day,night,gunfight,blast")).split(",")
    seconds = str(arg("seconds", "10"))
    results = {}
    load = run(out, "load", ["--scene=load", "--bodies"])
    results["load"] = load
    for s in scenes:
        for n in counts:
            results[f"{s}_{n}"] = run(out, f"{s}_{n}", [f"--scene={s}", f"--townsfolk={n}", "--no-ablate", f"--seconds={seconds}"])
    if arg("bands", False):
        for b in ["near", "far"]:
            results[f"day_10_{b}"] = run(out, f"day_10_{b}", ["--scene=day", "--townsfolk=10", f"--band={b}", "--no-ablate", f"--seconds={seconds}"])
    ab = arg("ablate", None)
    if ab:
        for s in ["day", "night"]:
            results[f"{s}_{ab}_ablate"] = run(out, f"{s}_{ab}_ablate", [f"--scene={s}", f"--townsfolk={ab}", f"--seconds={seconds}"], timeout=3600)
    if arg("render", False):
        for s in scenes:
            results[f"{s}_15_drawn"] = run(out, f"{s}_15_drawn", [f"--scene={s}", "--townsfolk=15", "--no-ablate", "--no-budget", "--seconds=1"],
                                           drawn=True, timeout=3600)
    (out / "all.json").write_text(json.dumps(results, indent=1))
    table = write_table(results, counts, scenes)
    (out / "table.md").write_text(table)
    print(table)


def write_table(results, counts, scenes) -> str:
    lines = []
    load = results.get("load", {}).get("load", {})
    if load:
        lines.append(f"Load here: bake {load['bake_ms'] / 1000:.1f} s, scene {load['scene_ms'] / 1000:.1f} s, "
                     f"first frames {load['first_frames_ms'] / 1000:.1f} s; parts (s): "
                     + ", ".join(f"{k} {v / 1000:.1f}" for k, v in sorted(load.get("parts_ms", {}).items(), key=lambda kv: -kv[1]))
                     + "; folk (s): " + ", ".join(f"{k} {v / 1000:.1f}" for k, v in load.get("folk_ms", {}).items()))
        lines.append("")
    lines.append("Each scene's frame at Sean's (ms; this core x 0.65), headless (no render CPU); OVER marks a part over its budget.")
    lines.append("")
    lines.append("| Scene | Townsfolk | Men (near/far) | Frame | p99 | People (4.0) | Physics (2.0) | Structures (1.0) | Fire+fx (2.0) | Else (1.0) | Total |")
    lines.append("|---|---|---|---|---|---|---|---|---|---|---|")
    for s in scenes:
        for n in counts:
            r = results.get(f"{s}_{n}", {}).get(s)
            if not r:
                lines.append(f"| {s} | {n} | - | no result | | | | | | | |")
                continue
            f, b, p = r["frames"], r.get("budget", {}), r.get("people", {})
            cells = []
            for k in PARTS:
                v = float(b.get(k, 0.0))
                cells.append(f"{v:.2f}{' OVER' if k != 'total' and v > BUDGET[k] else ''}")
            lines.append(f"| {s} | {n} | {p.get('men', 0)} ({p.get('near_25', 0)}/{p.get('far_60', 0)}) | {f['avg_ms'] * SCALE:.2f} | "
                         f"{f['p99_ms'] * SCALE:.1f} | " + " | ".join(cells) + " |")
    lines.append("")
    lines.append("The people's systems at Sean's (ms a frame), by scene and townsfolk:")
    lines.append("")
    lines.append("| Scene | Townsfolk | " + " | ".join(PEOPLE) + " |")
    lines.append("|---|---|" + "---|" * len(PEOPLE))
    for key in [f"{s}_{n}" for s in scenes for n in counts] + ["day_10_near", "day_10_far"]:
        r = results.get(key, {})
        s = key.split("_")[0]
        if s not in r:
            continue
        sy = r[s]["frames"]["systems_ms"]
        lines.append(f"| {s} | {key.split('_', 1)[1]} | " + " | ".join(f"{float(sy.get(k, 0)) * SCALE:.2f}" for k in PEOPLE) + " |")
    for key in [k for k in results if k.endswith("_drawn")]:
        r = results[key]
        s = key.split("_")[0]
        if s in r:
            f = r[s]["frames"]
            lines.append(f"\nDrawn ({key}): render CPU {f['render_cpu_ms']:.2f} ms here, {f['render_cpu_ms'] * SCALE:.2f} at Sean's; "
                         f"{f['draw_calls']:.0f} draws, {f['objects_in_frame']:.0f} objects")
    for key in [k for k in results if k.endswith("_ablate")]:
        r = results[key]
        s = key.split("_")[0]
        if s in r and "systems" in r[s]:
            lines.append(f"\nSwitched off in turn ({key}), what each saves at Sean's (ms):")
            for row in r[s]["systems"]:
                lines.append(f"- {row['system']} ({row['nodes']} nodes): {row['saves_ms'] * SCALE:.2f}")
    bodies = results.get("load", {}).get("bodies")
    if bodies:
        lines.append(f"\nCollision bodies after the load: {bodies['total']} of max_bodies {bodies['max_bodies']}: "
                     + ", ".join(f"{k} {v}" for k, v in bodies["by"].items()))
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    main()
