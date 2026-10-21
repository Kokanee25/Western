#!/usr/bin/env python3
"""The prop lab's bench, every scenario (experiments/prop_lab/README.md).

  python3 experiments/prop_lab/run.py --out=build/prop_lab/base [--scenario=a,b] [--render] [--jobs=4]
  python3 experiments/prop_lab/run.py --table=build/prop_lab/base      # the table (table.md) from summaries
  python3 experiments/prop_lab/run.py --sheet=build/prop_lab/render --only=seated_kick_front_leg  # frames -> sheet
"""
import json, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def arg(name, default=None):
    for a in sys.argv[1:]:
        if a == "--" + name:
            return True
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def scenarios():
    with open(os.path.join(ROOT, "experiments/prop_lab/scenarios.json")) as f:
        return [s["name"] for s in json.load(f)["scenarios"]]


def run_one(name, out, render):
    cmd = ["godot", "--path", ROOT, "--fixed-fps", "60"]
    if render:
        cmd = ["xvfb-run", "-a"] + cmd + ["--rendering-driver", "vulkan"]
    else:
        cmd += ["--headless"]
    cmd += ["-s", "res://experiments/prop_lab/bench.gd", "--", "--scenario=" + name, "--out=" + out]
    if render:
        cmd.append("--render")
    os.makedirs(os.path.join(out, name), exist_ok=True)
    with open(os.path.join(out, name, "godot.log"), "w") as log:
        subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, timeout=1800)
    return name


def table(root):
    rows = ["| scenario | broke | went over | pieces (farthest) | fire | man | lamp | faults | frame ms (event / settle) |",
            "|---|---|---|---|---|---|---|---|---|"]
    for name in scenarios():
        p = os.path.join(root, name, "summary.json")
        if not os.path.exists(p):
            continue
        s = json.load(open(p))
        broke = ", ".join(s["snapped"]) or "nothing"
        over = "at %.2f s" % s["loose_t"] if s["loose"] and s["loose_t"] is not None else ("yes" if s["loose"] else "no")
        fire = "caught %d, burnt %d" % (len(s["caught"]), len(s["consumed"])) if s["caught"] else "-"
        if s["consumed_t"]:
            fire += " (%s s)" % ", ".join("%g" % t for t in s["consumed_t"][:4])
        man = "-"
        if "man" in s:
            m = s["man"]
            man = ("down at %.2f s, on the floor" % m["limp_t"] if m["limp"] and m["on_floor"] else
                   ("down at %.2f s" % m["limp_t"] if m["limp"] else "still sat" if m.get("seat_h") else "on it"))
        lamp = "-"
        if "lamp" in s:
            lamp = "smashed, %d spill" % s["lamp"]["spills"] if s["lamp"]["smashed"] else "whole"
        faults = ", ".join("%s %d" % (k, v) for k, v in s["faults"].items() if v) or "none"
        fr = s["frame"]
        rows.append("| %s | %s | %s | %d (%.1f m) | %s | %s | %s | %s | %.1f / %.1f |" % (
            name, broke, over, s["pieces"], s["farthest_m"], fire, man, lamp, faults, fr["event_ms"], fr["settle_ms"]))
    out = "\n".join(rows) + "\n"
    with open(os.path.join(root, "table.md"), "w") as f:
        f.write(out)
    print(out)


def sheet(root, only):
    from PIL import Image
    for name in only:
        d = os.path.join(root, name)
        frames = sorted(f for f in os.listdir(d) if f.startswith("f_") and f.endswith(".png"))
        if not frames:
            continue
        ims = [Image.open(os.path.join(d, f)) for f in frames]
        w, h = ims[0].size
        cols = 5
        rows = (len(ims) + cols - 1) // cols
        s = 0.5
        sheet_im = Image.new("RGB", (int(w * s) * cols, int(h * s) * rows))
        for i, im in enumerate(ims):
            sheet_im.paste(im.resize((int(w * s), int(h * s))), ((i % cols) * int(w * s), (i // cols) * int(h * s)))
        out = os.path.join(root, name + "_sheet.jpg")
        sheet_im.save(out, quality=85)
        print(out)


if __name__ == "__main__":
    if arg("table"):
        table(arg("table"))
    elif arg("sheet"):
        sheet(arg("sheet"), (arg("only") or ",".join(scenarios())).split(","))
    else:
        out = arg("out", "build/prop_lab/base")
        names = arg("scenario").split(",") if arg("scenario") else scenarios()
        with ThreadPoolExecutor(int(arg("jobs", 4))) as ex:
            for n in ex.map(lambda n: run_one(n, out, bool(arg("render"))), names):
                print("done", n, flush=True)
        table(out)
