#!/usr/bin/env python3
"""The breakage lab's runs (README.md beside this file): one fresh game a scenario, driven through
the dev bridge (`breakage SCENARIO ...`, this lab's bridge.gd), several at once.

    python3 experiments/breakage_lab/run.py --out=build/breakage_lab/base               # everything
    python3 experiments/breakage_lab/run.py --scenario=list
    python3 experiments/breakage_lab/run.py --scenario=wall_dynamite_1m,man_on_table --bodies=outlaw --out=...
    python3 experiments/breakage_lab/run.py --scenario=target:lamp --out=...            # a target's five
    python3 experiments/breakage_lab/run.py --scenario=weapon:dynamite_3m --out=...     # a weapon's seven
    python3 experiments/breakage_lab/run.py --repeat=2 --out=...      # each twice, compared (same seed, same result?)
    python3 experiments/breakage_lab/run.py --compare=ROOT           # that comparison again (no Godot)
    python3 experiments/breakage_lab/run.py --render --bodies=bold_cowboy_s0 --out=...  # frames for the sheets (xvfb, lavapipe)
    python3 experiments/breakage_lab/run.py --serial --out=...        # one game at a time, for frame times
    python3 experiments/breakage_lab/run.py --skip-done --out=ROOT    # again, leaving out what's already in ROOT
    python3 experiments/breakage_lab/run.py --table=ROOT [--frames=SERIAL_ROOT]  # the table again (no Godot), frame times from a serial run
    python3 experiments/breakage_lab/run.py --table=ROOT --frames=SERIAL --keep=experiments/breakage_lab/baseline   # commit it

A scenario with a man in it (every blast has a bystander; man_on_table) runs once per body in
--bodies (default: every body in scenarios.json, the Studio's three men and the old outlaw); the
gun scenarios have no man and run once. --seed=N, --seconds=S, --jobs=N (default 4).
"""
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
LAB = os.path.join(ROOT, "experiments", "breakage_lab")


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


def weapons_of(d, t):
    """As runner.gd's: a target's own list, else every weapon not marked only_listed."""
    return d["targets"][t].get("weapons", [w for w in d["weapons"] if not d["weapons"][w].get("only_listed")])


def names(d):
    out = [f"{t}_{w}" for t in d["targets"] for w in weapons_of(d, t)]
    return out + list(d["extras"])


def has_man(d, name):
    return name in d["extras"] or any(name.endswith("_" + w) for w in d["weapons"] if "dynamite" in d["weapons"][w])


def pick(d, want):
    alln = names(d)
    if want in (None, "all"):
        return alln
    out = []
    for w in want.split(","):
        if w.startswith("target:"):
            out += [n for n in alln if n.startswith(w[7:] + "_")]
        elif w.startswith("weapon:"):
            out += [n for n in alln if n.endswith("_" + w[7:])]
        elif w in alln:
            out.append(w)
        else:
            sys.exit(f"no scenario {w} (--scenario=list)")
    return out


def job_dir(out, name, body):
    return os.path.join(out, name + (f"__{body}" if body else ""))


def run_one(job):
    name, body, out_dir, port, seed, seconds, render = job
    os.makedirs(out_dir, exist_ok=True)
    cmds = os.path.join(out_dir, "cmds.txt")
    words = [f"breakage {name}", f"seed={seed}", f"out={out_dir}"]
    if body:
        words.append(f"body={body}")
    if seconds:
        words.append(f"seconds={seconds}")
    if render:
        words.append("shots")
    if opt("novoxels"):
        words.append("novoxels")
    with open(cmds, "w") as f:
        f.write(" ".join(words) + "\nquit\n")
    godot = os.environ.get("GODOT", "godot")
    cmd = [godot, "--path", ROOT]
    if render:
        cmd = ["xvfb-run", "-a", "-s", "-screen 0 960x540x24"] + cmd + ["--rendering-driver", "vulkan", "--resolution", "960x540"]
    else:
        cmd += ["--headless"]
    cmd += ["--fixed-fps", "60", "--", "--dev-bridge", f"--bridge-port={port}", f"--bridge-script={cmds}"]
    t0 = time.time()
    summary = os.path.join(out_dir, "summary.json")
    log_path = os.path.join(out_dir, "godot.log")
    if opt("skip-done") and os.path.exists(summary):
        print(f"done   {name:22} {body or '-':18}", flush=True)
        return True
    with open(log_path, "w") as log:
        # Its own process group: a drawn game (xvfb-run, then Godot) sometimes hangs on quit after
        # it's answered, so once the quit is answered it gets 20 s, then the group is ended.
        proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        limit = t0 + (1800 if render else 400)
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
    ok = os.path.exists(summary)
    print(f"{'ok ' if ok else 'FAILED'} {name:22} {body or '-':18} {time.time() - t0:5.0f}s", flush=True)
    return ok


def load(root):
    rows = []
    for name in sorted(os.listdir(root)):
        p = os.path.join(root, name, "summary.json")
        if os.path.exists(p) and "_repeat" not in name:
            with open(p) as f:
                rows.append(json.load(f))
    return rows


def short_target(s):
    t = s["target_result"]
    r = t.get("result", "?")
    if "blast" in t:
        r += f" (blast {t['blast']['ratio']:.2g}x)"
    if t.get("utilisation_after") is not None and s["weapon"] in ("revolver_5m", "shotgun_5m"):
        r += f" (u {t.get('utilisation_before', 0):.2f}->{t['utilisation_after']:.2f})"
    return r


def table(rows, frames=None):
    """The baseline table (markdown): a line a scenario and body. `frames`: frame numbers from a
    serial run (scenario -> its summary's "frame"), in place of this run's (several games at once
    share the cores, so their frames are slower)."""
    lines = ["| scenario | body | target | first hit | broken (nearest) | pieces (largest) | flew m (max/median) | caught | man | event ms | +ms 1st s | flags |",
             "|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for s in rows:
        b = s["broken"]
        near = b["nearest"][0]["id"].split(":")[-1] + f" {b['nearest'][0]['m_from_event']:.1f} m" if b["nearest"] else ""
        p = s["pieces"]
        kinds = " ".join(f"{k} {v['n']}" for k, v in sorted(p["by_kind"].items()))
        lg = p["largest"]
        largest = f"{lg['kind']} {lg['kg']:.2g} kg/{lg['longest_m']:.2g} m" if lg else ""
        hit = s["hits"][0]["what"].split(":")[-1] if s.get("hits") else ""
        if s.get("line") and not s["line"]["clear"]:
            hit = "BLOCKED " + s["line"]["first_hit"]
        q = s["setup"].get("blast_query")
        if q:
            hit = f"looked at {q['found']}/{q['in_reach']}" + ("" if q["target_found"] else ", target not found")
            missed = q.get("left_out_within_1_2_break_m") or q.get("left_out_within_1_2_5m")
            if missed and missed[1]:
                hit += f", {missed[1]} within 2 m left out"
        men = []
        for m in s["men"]:
            bits = []
            if m.get("knocked_down"):
                bits.append("down")
            if m.get("alive") is False:
                bits.append("dead")
            if m.get("severed"):
                bits.append("lost " + ",".join(m["severed"]))
            if m.get("role") == "dropped":
                bits.append("on table" if m.get("rests_on_table") else "off table")
            if m.get("settle_s") is not None and m.get("limp"):
                bits.append(f"rest {m['settle_s']:.1f}s")
            bits.append(f"{m.get('peak_part_mps', 0):.1f} m/s")
            men.append(" ".join(bits))
        f = (frames or {}).get(s["scenario"], s["frame"])
        fire = s["fire"]
        caught = f"{fire['caught_count']}" + (f", {fire['spills_at_end']} spill" if fire["spills_at_end"] else "")
        lines.append(f"| {s['scenario']} | {s.get('body') or '-'} | {short_target(s)} | {hit} | {b['count']} {near} | "
                     f"{p['count']} {kinds} ({largest}) | {p['max_m']:.1f}/{p['median_m']:.1f} | {caught} | {'; '.join(men)} | "
                     f"{f['event_frame_ms']:.0f} | {f.get('added_ms_first_1s', 0):.0f} | {len(s['flags'])} |")
    return "\n".join(lines)


def keep(root, rows, frames, to):
    """--keep=DIR: the table, the summaries (slimmed: no per-piece ends, fire log or warnings; the
    first hits and nearest breaks) and the manifest, into DIR (the committed baseline)."""
    os.makedirs(to, exist_ok=True)
    slim = []
    for s in rows:
        s = json.loads(json.dumps(s))
        s["hits"] = s.get("hits", [])[:3]
        s["broken"]["nearest"] = s["broken"]["nearest"][:10]
        s["fire"].pop("log", None)
        s.pop("warnings", None)
        s["fingerprint"].pop("piece_ends", None)
        if frames and s["scenario"] in frames:
            s["frame_serial"] = frames[s["scenario"]]
        slim.append(s)
    with open(os.path.join(to, "baseline.json"), "w") as f:
        json.dump(slim, f, indent=1)
    with open(os.path.join(to, "table.md"), "w") as f:
        f.write(table(rows, frames) + "\n")
    m = os.path.join(root, "manifest.json")
    if os.path.exists(m):
        with open(m) as src, open(os.path.join(to, "manifest.json"), "w") as dst:
            dst.write(src.read())
    print(f"kept in {to}")


def same(a, b):
    """Two runs' fingerprints: equal, or how they differ."""
    fa, fb = a["fingerprint"], b["fingerprint"]
    diffs = []
    for k in ("broken", "pieces", "caught", "target"):
        if fa.get(k) != fb.get(k):
            diffs.append(f"{k}: {fa.get(k)} vs {fb.get(k)}")
    ia, ib = set(fa.get("broken_ids", [])), set(fb.get("broken_ids", []))
    if ia != ib:
        diffs.append(f"nearest broken differ: {sorted(ia - ib)[:4]} vs {sorted(ib - ia)[:4]}")
    ea, eb = fa.get("piece_ends", []), fb.get("piece_ends", [])
    if len(ea) == len(eb) and ea:
        worst = max(abs(x - y) for x, y in zip(ea, eb))
        if worst > 0.001:
            diffs.append(f"pieces end up to {worst:.3f} m apart")
    for ma, mb in zip(fa.get("men", []), fb.get("men", [])):
        if ma and mb:
            d = max(abs(x - y) for x, y in zip(ma, mb))
            if d > 0.011:
                diffs.append(f"man's pelvis {d:.2f} m apart")
    return diffs


def determinism(root):
    """Every ROOT/X with a ROOT/X_repeatK beside it: the same seed's runs compared."""
    det = {}
    for name in sorted(os.listdir(root)):
        if "_repeat" in name or not os.path.exists(os.path.join(root, name, "summary.json")):
            continue
        k = 1
        while os.path.isdir(os.path.join(root, f"{name}_repeat{k}")):
            try:
                a = json.load(open(os.path.join(root, name, "summary.json")))
                b = json.load(open(os.path.join(root, f"{name}_repeat{k}", "summary.json")))
                det[name + (f"#{k}" if k > 1 else "")] = same(a, b)
            except (OSError, ValueError) as e:
                det[name] = [f"missing: {e}"]
            k += 1
    n_diff = sum(1 for v in det.values() if v)
    print(f"same seed, same result: {len(det) - n_diff} of {len(det)}")
    for k, v in det.items():
        if v:
            print(f"  {k}: {'; '.join(v)}")
    return det


def compare(d, root):
    """--compare=ROOT: the same-seed comparison again, from a finished --repeat run (no Godot)."""
    path = os.path.join(root, "manifest.json")
    manifest = json.load(open(path)) if os.path.exists(path) else {}
    manifest["same_seed_same_result"] = determinism(root)
    with open(path, "w") as f:
        json.dump(manifest, f, indent=1)
    return 0


def main():
    d = data()
    want = opt("scenario", "all")
    if want == "list":
        for n in names(d):
            print(f"{n:22} {'(one per body)' if has_man(d, n) else ''}")
        return 0
    out = os.path.abspath(opt("out", os.path.join(ROOT, "build", "breakage_lab", "run")))
    if opt("table"):
        root = os.path.abspath(opt("table"))
        rows = load(root)
        frames = None
        if opt("frames"):
            frames = {s["scenario"]: s["frame"] for s in load(os.path.abspath(opt("frames")))}
        with open(os.path.join(root, "table.md"), "w") as f:
            f.write(table(rows, frames) + "\n")
        if opt("keep"):
            keep(root, rows, frames, os.path.abspath(opt("keep")))
        else:
            print(table(rows, frames))
        return 0
    bodies = d["bodies"] if opt("bodies", "all") == "all" else opt("bodies").split(",")
    seed = int(opt("seed", d["seed"]))
    seconds = opt("seconds")
    render = bool(opt("render"))
    repeat = int(opt("repeat", "1"))
    jobs_n = 1 if opt("serial") else int(opt("jobs", "4"))
    if opt("compare"):
        return compare(d, os.path.abspath(opt("compare")))
    os.makedirs(out, exist_ok=True)
    # Thousands of CSVs and PNGs: keep Godot's import from taking them for translations and textures.
    open(os.path.join(out, ".gdignore"), "a").close()
    jobs = []
    port = 8800
    for name in pick(d, want):
        for body in (bodies if has_man(d, name) else [""]):
            for k in range(repeat):
                path = job_dir(out, name, body) + ("" if k == 0 else f"_repeat{k}")
                jobs.append((name, body, path, port, seed, seconds, render))
                port += 1
    print(f"{len(jobs)} game(s), {jobs_n} at a time, into {out}", flush=True)
    sha = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    with ThreadPoolExecutor(max_workers=jobs_n) as ex:
        results = list(ex.map(run_one, jobs))
    rows = load(out)
    with open(os.path.join(out, "baseline.json"), "w") as f:
        json.dump(rows, f, indent=1)
    with open(os.path.join(out, "table.md"), "w") as f:
        f.write(table(rows) + "\n")
    manifest = {"source_sha": sha, "command": " ".join(sys.argv), "seed": seed, "bodies": bodies, "jobs": jobs_n,
                "games": len(jobs), "failed": [j[2] for j, ok in zip(jobs, results) if not ok],
                "cpu": open("/proc/cpuinfo").read().split("model name")[1].split("\n")[0].strip(": ") if os.path.exists("/proc/cpuinfo") else "",
                "threads": os.cpu_count()}
    if repeat > 1:
        manifest["same_seed_same_result"] = determinism(out)
    with open(os.path.join(out, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1)
    print(f"{sum(results)} of {len(jobs)} ok; table in {os.path.join(out, 'table.md')}")
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
