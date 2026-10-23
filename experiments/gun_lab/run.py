#!/usr/bin/env python3
"""The gun lab's runs (README.md beside this file): each job in a fresh game through the dev
bridge's --bridge-script, then the contact sheets and the table.

    python3 experiments/gun_lab/run.py --out=build/gun_lab/base                 # everything
    python3 experiments/gun_lab/run.py --job=handling --out=...                  # numbers only (headless)
    python3 experiments/gun_lab/run.py --job=fp,men --bodies=sean_s2 --out=...   # frames (xvfb, lavapipe)
    python3 experiments/gun_lab/run.py --sheets=ROOT                             # sheets and table again, no Godot
    python3 experiments/gun_lab/run.py --compare=BASE,NEW                        # the numbers side by side

Options: --jobs=N (games at once, default 2), --hour=H (16), --skip-done.
"""
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MEN = ["bold_cowboy_s0", "old_rancher_s1", "young_drifter_s1", "sean_s2"]
GUNS = ["revolver", "shotgun"]


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a == f"--{name}":
            return True
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
    return default


def run_game(name, line, out, port, render):
    """One fresh game running one bridge command, then quit. Returns True when it answered."""
    jdir = os.path.join(out, "_runs", name)
    os.makedirs(jdir, exist_ok=True)
    cmds = os.path.join(jdir, "cmds.txt")
    with open(cmds, "w") as f:
        f.write(line + "\nquit\n")
    godot = os.environ.get("GODOT", "godot")
    cmd = [godot, "--path", ROOT]
    if render:
        cmd = ["xvfb-run", "-a", "-s", "-screen 0 960x540x24"] + cmd + ["--rendering-driver", "vulkan", "--resolution", "960x540"]
    else:
        cmd += ["--headless"]
    cmd += ["--fixed-fps", "60", "--", "--dev-bridge", f"--bridge-port={port}", f"--bridge-script={cmds}"]
    log_path = os.path.join(jdir, "godot.log")
    t0 = time.time()
    with open(log_path, "w") as log:
        # Its own process group: a drawn game sometimes hangs on quit after it has answered, so once
        # the quit is answered it gets 20 s, then the group is ended.
        proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        limit = t0 + (3600 if render else 1800)
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
    text = open(log_path, errors="replace").read()
    ok = '"ok":false' not in text and "SCRIPT ERROR" not in text
    print(f"{'ok ' if ok else 'FAILED'} {name:28} {time.time() - t0:5.0f}s", flush=True)
    return ok


def jobs_for(out):
    want = (opt("job") or "fp,men,handling").split(",")
    bodies = MEN if opt("bodies") in (None, "all") else opt("bodies").split(",")
    hour = opt("hour")
    extra = f" hour={hour}" if hour else ""
    jobs = []
    if "handling" in want:
        jobs.append(("handling", f"gun_handling out={out}{extra}", False, "handling.json"))
    if "fp" in want:
        for g in GUNS:
            jobs.append((f"fp_{g}", f"gun_fp {g} out={out}{extra}", True, f"fp_{g}.json"))
    if "men" in want:
        for b in bodies:
            jobs.append((f"men_{b}", f"gun_men {b} out={out}{extra}", True, f"men_{b}.json"))
    return jobs


# --- Sheets ---------------------------------------------------------------------------------------

def _font(size):
    from PIL import ImageFont
    for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/dejavu/DejaVuSans.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def sheet(cells, cols, path, title, thumb=(480, 270), crop=None):
    """cells: [(png path or None, label)] laid out `cols` across, a label under each; `crop` a
    box in fractions of the frame (x0, y0, x1, y1) to show instead of all of it."""
    from PIL import Image, ImageDraw
    rows = (len(cells) + cols - 1) // cols
    lab_h = 34
    head = 36
    img = Image.new("RGB", (cols * thumb[0], head + rows * (thumb[1] + lab_h)), (24, 22, 20))
    d = ImageDraw.Draw(img)
    d.text((8, 8), title, fill=(240, 230, 210), font=_font(18))
    f = _font(13)
    for i, (png, label) in enumerate(cells):
        x = (i % cols) * thumb[0]
        y = head + (i // cols) * (thumb[1] + lab_h)
        if png and os.path.isfile(png):
            im = Image.open(png).convert("RGB")
            if crop:
                im = im.crop((int(crop[0] * im.width), int(crop[1] * im.height), int(crop[2] * im.width), int(crop[3] * im.height)))
            im.thumbnail(thumb)
            img.paste(im, (x + (thumb[0] - im.width) // 2, y))
        lines = label.split("\n")
        for k, line in enumerate(lines[:2]):
            d.text((x + 6, y + thumb[1] + 2 + k * 15), line, fill=(230, 220, 200), font=f)
    img.save(path, quality=82)
    return path


def sheets(root):
    out_dir = os.path.join(root, "sheets")
    os.makedirs(out_dir, exist_ok=True)
    made = []
    for g in GUNS:
        j = os.path.join(root, f"fp_{g}.json")
        if not os.path.exists(j):
            continue
        d = json.load(open(j))
        cells = [(os.path.join(root, f"fp_{g}", fr["file"]), f"{fr['name']}: {fr['note']}\n{fr['weapon']}") for fr in d["frames"]]
        made.append(sheet(cells, 4, os.path.join(out_dir, f"fp_{g}.jpg"), f"{g} in first person (hour {d.get('hour')})"))
        # The gun close: the right two thirds of the lower part of the frame, at full size.
        made.append(sheet(cells, 4, os.path.join(out_dir, f"fp_{g}_close.jpg"), f"{g} in first person, the gun close",
                          (480, 320), (0.4, 0.3, 1.0, 1.0)))
    for b in MEN:
        j = os.path.join(root, f"men_{b}.json")
        if not os.path.exists(j):
            continue
        d = json.load(open(j))
        cells = []
        for s in d["states"]:
            gap = s.get("gap", {})
            g = f"{gap.get('where', '')}: nearest {gap.get('nearest_mm', '-')} mm, inside {gap.get('inside_share', '-')}" \
                + (f", buried {gap['buried_mm']} mm" if "buried_mm" in gap else "") + (" FLOATING" if gap.get("floating") else "")
            for dist in ["close", "1", "5", "10", "xray"]:
                if dist not in s["frames"]:
                    cells.append((None, ""))
                    continue
                where = {"close": "close (0.6 m, narrow)", "xray": "close, his body hidden"}.get(dist, f"at {dist} m")
                cells.append((os.path.join(root, f"men_{b}", s["frames"][dist]), f"{s['state']} {where}\n{g}"))
        made.append(sheet(cells, 5, os.path.join(out_dir, f"men_{b}.jpg"),
                          f"{b}: his gun (rows: states; columns: close, then 1, 5, 10 m at the game's view; holstered: his body hidden)", (400, 225)))
    return made


# --- The table ------------------------------------------------------------------------------------

def table(root):
    lines = []
    h = os.path.join(root, "handling.json")
    if os.path.exists(h):
        d = json.load(open(h))
        r, s, o = d["revolver"], d["shotgun"], d["outlaw"]
        lines += ["| Handling | Revolver | Coach gun | A man (OutlawBrain) |", "| --- | --- | --- | --- |",
                  f"| Draw to first shot (s) | {r['draw_to_first_shot_s']} | {s['draw_to_first_shot_s']} | {o['draw_s']} + his aim |",
                  f"| Cocking (s) | {r['cock_s']} | {s['cock_s']} | none (no hammer) |",
                  f"| Fastest shot to shot (s) | {r['cadence_s']} | {s['cadence_s']} | {o['seconds_between_shots']} x 0.75-1.3 |",
                  f"| Reload one (s) | {r['reload_one_round_s']} | {s['reload_one_shell_s']} | - |",
                  f"| Full reload (s) | {r['reload_six_s']} (six) | {s['reload_two_s']} (two) | {o['reload_s']} ({o['rounds_per_load']} rounds, a timer) |",
                  f"| Sight recovery after an aimed shot: settled (s), worst (deg), climb left (deg) | {r['recovery']['settled_s']}, {r['recovery']['worst_deg']}, {r['recovery']['left_deg']} | {s['recovery']['settled_s']}, {s['recovery']['worst_deg']}, {s['recovery']['left_deg']} | - |"]
        lines += ["", "| Accuracy at 10 m (R50 cm / share in a 45x75 cm torso) | Revolver | Coach gun (charge centre) |", "| --- | --- | --- |"]
        for k in ["steady_aimed", "rushed_aimed", "hip", "walking_hip"]:
            a, b = r["accuracy"].get(k, {}), s["accuracy"].get(k, {})
            lines.append(f"| {k.replace('_', ' ')} | {a.get('r50_cm_at_10m')} / {a.get('torso_hits_at_10m')} | {b.get('r50_cm_at_10m')} / {b.get('torso_hits_at_10m')} |")
        for k, v in r["accuracy"].get("wounded_aimed", {}).items():
            if not isinstance(v, dict):
                continue
            lines.append(f"| wounded, {k.replace('_', ' ')} (pain {v.get('pain')}, felt {v.get('felt_pain')}, extra spread {v.get('extra_spread_deg')} deg) | {v.get('r50_cm_at_10m')} / {v.get('torso_hits_at_10m')} | - |")
        lines.append(f"\nThe outlaw's calm spread: {o['spread_degrees_calm']} deg (= {round(1000 * o['spread_degrees_calm'] * 3.14159 / 180, 1)} cm at 10 m, the cone's edge).")
    rows = []
    for b in MEN:
        j = os.path.join(root, f"men_{b}.json")
        if not os.path.exists(j):
            continue
        d = json.load(open(j))
        for s in d["states"]:
            g = s.get("gap", {})
            rows.append(f"| {b} | {s['state']} | {g.get('where', '-')} | {g.get('nearest_mm', '-')} | {g.get('inside_share', '-')} | {g.get('centre_to_grip_mm', '-')} | {'yes' if g.get('floating') else ''} |")
        dr = d.get("dropped", {})
        rows.append(f"| {b} | dropped, 2 s | ground | {dr.get('lowest_above_ground_mm', '-')} above | - | - | {'still moving' if dr and not dr.get('asleep') else ''} |")
    if rows:
        lines += ["", "| Man | State | Against | Nearest (mm) | Share of his hand inside the gun | Middles apart (mm) | Floating |",
                  "| --- | --- | --- | --- | --- | --- | --- |"] + rows
    text = "\n".join(lines) + "\n"
    open(os.path.join(root, "table.md"), "w").write(text)
    return text


def compare(a, b):
    da, db = json.load(open(os.path.join(a, "handling.json"))), json.load(open(os.path.join(b, "handling.json")))

    def flat(d, pre=""):
        out = {}
        for k, v in d.items():
            if isinstance(v, dict):
                out.update(flat(v, f"{pre}{k}."))
            elif isinstance(v, (int, float)) and not isinstance(v, bool):
                out[pre + k] = v
        return out
    fa, fb = flat(da), flat(db)
    for k in sorted(set(fa) | set(fb)):
        if fa.get(k) != fb.get(k):
            print(f"{k:60} {fa.get(k)!s:>10} -> {fb.get(k)!s:>10}")


def main():
    if opt("sheets"):
        root = opt("sheets")
        for p in sheets(root):
            print(p)
        print(table(root))
        return
    if opt("compare"):
        a, b = opt("compare").split(",")
        compare(a, b)
        return
    out = os.path.abspath(opt("out") or "build/gun_lab/run")
    os.makedirs(out, exist_ok=True)
    jobs = jobs_for(out)
    if opt("skip-done"):
        jobs = [j for j in jobs if not os.path.exists(os.path.join(out, j[3]))]
    n = int(opt("jobs") or 2)
    with ThreadPoolExecutor(max_workers=n) as ex:
        res = list(ex.map(lambda ij: run_game(ij[1][0], ij[1][1], out, 8790 + ij[0], ij[1][2]), enumerate(jobs)))
    sha = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    json.dump({"commit": sha, "jobs": [j[0] for j in jobs], "ok": res, "when": time.strftime("%Y-%m-%d %H:%M")},
              open(os.path.join(out, "manifest.json"), "w"), indent=1)
    sheets(out)
    print(table(out))
    if not all(res):
        sys.exit(1)


if __name__ == "__main__":
    main()
