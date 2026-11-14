#!/usr/bin/env python3
"""MetaHumans at town scale (#889): the valley's frame bench (tools/valley/bench_runs.py, #865) with
the townsfolk all one MetaHuman, against today's Studio men, one game at a time.

    python3 tools/characters/metahuman_bench.py [--configs=today,mh,levels] [--counts=0,5,10,15,25]
        [--scenes=day,night,gunfight] [--seconds=10] [--drawn=15] [--out=build/mh_bench]

Configs: `today` the bench's Studio men; `mh` Sean's MetaHuman as exported (LOD0) everywhere;
`levels` his lighter levels by band (near lod1, far lod3) and re-dressed (hats, vests). His files
must be laid in first (the Studio's tools/metahuman_to_game.sh; git-ignored, never committed).
--drawn=N: one drawn lavapipe run a scene and config with N townsfolk (render CPU, draws,
primitives, video memory). Writes --out/<config>_<scene>_<n>.json and --out/table.md.
"""
import importlib.util
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("bench_runs", HERE.parent / "valley" / "bench_runs.py")
br = importlib.util.module_from_spec(spec)
spec.loader.exec_module(br)

MODEL = "private/sean_metahuman_s3"
CONFIGS = {
    "today": [],
    "mh": [f"--folk-model={MODEL}"],
    "levels": [f"--folk-model={MODEL}_lod1", f"--folk-far-model={MODEL}_lod3", "--folk-dress"],
}
SCALE = br.SCALE


def main():
    out = Path(br.arg("out", "build/mh_bench"))
    out.mkdir(parents=True, exist_ok=True)
    configs = str(br.arg("configs", "today,mh,levels")).split(",")
    counts = [int(c) for c in str(br.arg("counts", "0,5,10,15,25")).split(",")]
    scenes = str(br.arg("scenes", "day,night,gunfight")).split(",")
    seconds = str(br.arg("seconds", "10"))
    drawn = int(br.arg("drawn", 15))
    results = {}
    allp = out / "all.json"
    if allp.exists():
        results = json.loads(allp.read_text())
    for c in configs:
        for s in scenes:
            for n in counts:
                if n == 0 and c != "today":
                    continue  # no townsfolk: the same street whatever they'd be made of
                tag = f"{c}_{s}_{n}"
                if tag in results and results[tag]:
                    continue
                results[tag] = br.run(out, tag, [f"--scene={s}", f"--townsfolk={n}", "--no-ablate", f"--seconds={seconds}"] + CONFIGS[c])
                allp.write_text(json.dumps(results, indent=1))
        if drawn:
            for s in scenes:
                tag = f"{c}_{s}_{drawn}_drawn"
                if tag in results and results[tag]:
                    continue
                results[tag] = br.run(out, tag, [f"--scene={s}", f"--townsfolk={drawn}", "--no-ablate", "--no-budget", "--seconds=1"]
                                      + CONFIGS[c], drawn=True, timeout=5400)
                allp.write_text(json.dumps(results, indent=1))
    table = write_table(results, configs, scenes, counts, drawn)
    (out / "table.md").write_text(table)
    print(table)


def _get(results, tag, scene):
    r = results.get(tag, {})
    return r.get(scene) if isinstance(r, dict) else None


def write_table(results, configs, scenes, counts, drawn):
    L = ["Headless, at Sean's (this core x 0.65): the frame, people's part (budget 4.0), and the time to lay the townsfolk (load).", "",
         "| Scene | Townsfolk | " + " | ".join(f"{c}: frame / people / lay s" for c in configs) + " |",
         "|---|---|" + "---|" * len(configs)]
    for s in scenes:
        for n in counts:
            cells = []
            for c in configs:
                r = _get(results, f"{'today' if n == 0 else c}_{s}_{n}", s)
                if not r:
                    cells.append("-")
                    continue
                f, b, p = r["frames"], r.get("budget", {}), r.get("people", {})
                cells.append(f"{f['avg_ms'] * SCALE:.2f} / {float(b.get('people', 0)):.2f} / {p.get('townsfolk_lay_ms', 0) / 1000:.1f}")
            L.append(f"| {s} | {n} | " + " | ".join(cells) + " |")
    L += ["", "The people's systems at Sean's (ms), 25 townsfolk:", "",
          "| Scene | Config | " + " | ".join(br.PEOPLE[:6]) + " |", "|---|---|" + "---|" * 6]
    for s in scenes:
        for c in configs:
            r = _get(results, f"{c}_{s}_25", s)
            if r:
                sy = r["frames"]["systems_ms"]
                L.append(f"| {s} | {c} | " + " | ".join(f"{float(sy.get(k, 0)) * SCALE:.2f}" for k in br.PEOPLE[:6]) + " |")
    if drawn:
        L += ["", f"Drawn under lavapipe, {drawn} townsfolk (render CPU at Sean's = here x 0.65; GPU is lavapipe's, on the CPU: only relative):", "",
              "| Scene | Config | Render CPU (Sean's) | Draws | Primitives | Lavapipe GPU ms | Video MB | Texture MB | Static MB |",
              "|---|---|---|---|---|---|---|---|---|"]
        for s in scenes:
            for c in configs:
                r = _get(results, f"{c}_{s}_{drawn}_drawn", s)
                if not r:
                    continue
                f = r["frames"]
                L.append(f"| {s} | {c} | {f['render_cpu_ms'] * SCALE:.2f} | {f['draw_calls']:.0f} | {f.get('primitives', 0) / 1e6:.2f} M | "
                         f"{f.get('render_gpu_ms', 0):.0f} | {f.get('video_mb', 0):.0f} | {f.get('texture_mb', 0):.0f} | {f.get('static_mb', 0):.0f} |")
    L += ["", "Static memory after the headless run (MB), 25 townsfolk:", ""]
    for s in scenes:
        L.append(f"- {s}: " + ", ".join(f"{c} {(_get(results, f'{c}_{s}_25', s) or {}).get('frames', {}).get('static_mb', 0):.0f}" for c in configs))
    return "\n".join(L) + "\n"


if __name__ == "__main__":
    main()
