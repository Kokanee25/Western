#!/usr/bin/env python3
"""A bug report's frame timing (F12's .saltbug, src/debug/perf_ring.gd; #433), without replaying it:
the summary at the top of report.json, the last 15 s of frames (mean, p95, worst, how many over 20
and 50 ms, and each system's total, p95 and worst, as experiments/blast_freeze/summary.py prints a
run), then the per-second table (the last 10 minutes: each second's frames, mean and worst frame,
process, physics, ticks, render, draws, and its biggest systems). Systems are there only for the
frames F3 was up (the profiler on).

    python3 tools/perf_report.py FILE.saltbug [--seconds=N|--all] [--over=MS]

--seconds=N: the table's last N seconds (default 60); --all: every second kept. --over=MS: also list
each frame of the last 15 s longer than MS with its split and systems.
"""
import json
import sys
import zipfile


def pct(xs, p):
    if not xs:
        return 0.0
    s = sorted(xs)
    return s[min(len(s) - 1, int(round(p / 100.0 * (len(s) - 1))))]


def is_cost(name):
    return not (name.startswith("q_") or name.startswith("n_"))


def pieces(d, n=None):
    """{name: ms} as "name 1.23" pieces, largest first."""
    items = sorted(d.items(), key=lambda kv: -kv[1])
    return "  ".join(f"{k} {v:.2f}" for k, v in items[:n])


def summary_lines(s):
    """The same lines as PerfRing.summary_lines (the game's log and the replay print them)."""
    if not s or not s.get("frames"):
        return ["perf: no frames recorded"]
    w = s["worst"]
    out = [f"perf: the last {s['seconds']:.1f} s, {s['frames']} frames: mean {s['mean_ms']:.1f} ms "
           f"({1000.0 / max(s['mean_ms'], 0.001):.0f} fps), p95 {s['p95_ms']:.1f}, worst {w['frame_ms']:.1f} at {w['at']:.1f} s",
           f"  the worst frame: process {w['process_ms']:.1f}, physics {w['physics_ms']:.1f} ({int(w['ticks'])} ticks), "
           f"render cpu {w['render_cpu_ms']:.1f}, gpu {w['render_gpu_ms']:.1f}, untimed {w.get('untimed_ms', 0.0):.1f}; "
           f"draws {int(w['draws'])}, objects {int(w['objects'])}, "
           f"nodes {int(w['nodes'])}, bodies awake {int(w['bodies_awake'])}"]
    if w.get("systems"):
        out.append("  its systems: " + pieces(w["systems"]))
    if not s.get("biggest"):
        out.append("  systems: none (the profiler is on only while F3 is up: open F3, then F12)")
    else:
        out.append(f"  biggest a frame (over the {s['profiler_frames']} frames F3 was up): "
                   + pieces({b["name"]: b["ms"] for b in s["biggest"]}))
    if "worst_second" in s:
        ws = s["worst_second"]
        out.append(f"  the worst second of the last 10 min: at {ws['at']:.0f} s, mean {ws['mean_ms']:.1f} ms, "
                   f"worst {ws['worst_ms']:.1f} ({ws['frames']} frames)")
    return out


def frames_part(perf, over):
    cols = perf["frames_columns"]
    rows = [dict(zip(cols, r)) for r in perf["frames"]]
    ms = [r["frame_ms"] for r in rows]
    if not ms:
        return ["frames: none"]
    out = [f"frames (the last {rows[-1]['t'] - rows[0]['t']:.1f} s): {len(ms)}, mean {sum(ms) / len(ms):.1f}, "
           f"p95 {pct(ms, 95):.1f}, worst {max(ms):.1f}; over 20 ms {sum(1 for x in ms if x > 20)}, "
           f"over 50 ms {sum(1 for x in ms if x > 50)}"]
    for key in ("process_ms", "physics_ms", "render_cpu_ms", "render_gpu_ms"):
        vals = [r[key] for r in rows]
        out.append(f"    {key:<18} mean {sum(vals) / len(vals):6.1f}  p95 {pct(vals, 95):6.1f}  worst {max(vals):6.1f}")
    named = [r for r in rows if r["systems"]]
    if named:
        keys = set()
        for r in named:
            keys.update(k for k in r["systems"] if is_cost(k))
        table = []
        for k in keys:
            vals = [float(r["systems"].get(k, 0.0)) for r in named]
            table.append((sum(vals), k, max(vals), pct(vals, 95)))
        table.sort(reverse=True)
        out.append(f"  systems over the {len(named)} frames F3 was up (each frame's biggest eight):")
        for tot, k, worst, p95 in table[:14]:
            out.append(f"    {k:<18} total {tot:8.1f}  a frame {tot / len(named):6.2f}  p95 {p95:6.1f}  worst {worst:6.1f}")
    if over is not None:
        slow = [r for r in rows if r["frame_ms"] > over]
        out.append(f"  frames over {over:g} ms: {len(slow)}")
        for r in slow:
            out.append(f"    {r['t']:8.2f} s  {r['frame_ms']:6.1f} ms: process {r['process_ms']:.1f}, physics {r['physics_ms']:.1f} "
                       f"({int(r['ticks'])} ticks), render cpu {r['render_cpu_ms']:.1f}, gpu {r['render_gpu_ms']:.1f}, "
                       f"draws {int(r['draws'])}  {pieces(r['systems'])}")
    return out


def seconds_part(perf, last):
    cols = perf["seconds_columns"]
    rows = [dict(zip(cols, r)) for r in perf["seconds"]]
    if last is not None:
        rows = rows[-last:]
    out = [f"seconds ({len(rows)} of {len(perf['seconds'])} kept; ms, means with the worst frame):",
           f"  {'t':>7} {'frames':>6} {'mean':>6} {'worst':>6} {'proc':>6} {'phys':>6} {'ticks':>5} {'r.cpu':>6} {'r.gpu':>6} "
           f"{'draws':>6} {'nodes':>6} {'awake':>5}  systems"]
    for r in rows:
        top = {k: v for k, v in r["systems"].items() if is_cost(k)}
        out.append(f"  {r['t']:7.0f} {r['frames']:6d} {r['frame_ms']:6.1f} {r['frame_ms_worst']:6.1f} {r['process_ms']:6.1f} "
                   f"{r['physics_ms']:6.1f} {r['ticks']:5.1f} {r['render_cpu_ms']:6.1f} {r['render_gpu_ms']:6.1f} "
                   f"{r['draws']:6.0f} {r['nodes']:6.0f} {r['bodies_awake']:5.0f}  {pieces(top, 4)}")
    return out


def main(argv):
    path, last, over = "", 60, None
    for a in argv:
        if a == "--all":
            last = None
        elif a.startswith("--seconds="):
            last = int(a.split("=", 1)[1])
        elif a.startswith("--over="):
            over = float(a.split("=", 1)[1])
        elif not a.startswith("--"):
            path = a
    if not path:
        print(__doc__)
        return 2
    with zipfile.ZipFile(path) as z:
        report = json.loads(z.read("report.json"))
        if "perf.json" not in z.namelist():
            print(f"{path}: no perf.json (a report from before #433)")
            return 1
        perf = json.loads(z.read("perf.json"))
    print(f"{path}: {report.get('build', '?')}, {report.get('os', '?')}, {report.get('video', '?')}, "
          f"{report.get('game_seconds', 0):.0f} s of play, {report.get('fps', 0):.0f} fps when saved")
    print("\n".join(summary_lines(report.get("perf_summary", {}))))
    rec = perf.get("recorder_us", {})
    print("(the recorder a frame: " + ", ".join(f"F3 {k[3:]} {v['mean']:.1f} µs, worst {v['worst']} ({v['frames']} frames)"
                                             for k, v in rec.items() if isinstance(v, dict)) + ")")
    print()
    print("\n".join(frames_part(perf, over)))
    print()
    print("\n".join(seconds_part(perf, last)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
