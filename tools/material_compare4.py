#!/usr/bin/env python3
"""The material lab's final comparison (art, 2026-10-14; Sean's notes on the timber finish): A the
game today (production woods and geometry), B the finish he chose as the baseline (lab3, LabGeometry
`build` 1), C the final candidate (lab4, `build` 2: the middle red, coherent end grain, open steps,
per-member strip offsets), on the lab set (tools/material_lab.gd) and on Main Street itself
(--street: draws, primitives, render CPU per view).

    python3 tools/material_compare4.py [--a=build/fc_A --b=build/fin_B --c=build/fc_C]
        [--sa=build/st_A --sb=build/st_B --sc=build/st_C] [--out=docs/screenshots/material_lab/final]

Writes views_<light>.jpg and closeups_<light>.jpg (A | B | C), street_<light>.jpg (Main Street's
views, A | B | C), street.md (each view's cost, the three side by side) and
build/material_lab_final_pan.gif.
"""
import glob
import os
import re
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from material_compare2 import column, label, row  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VIEWS = ["deck_ends", "deck_end_on", "deck_corner", "steps", "post_close", "post_base", "close", "gameplay", "front"]
STREET = ["street_east", "street_west", "north_fronts", "south_fronts", "saloon_walk"]
CLOSE = [["plank ends", "deck_ends", (320, 200, 960, 520)],
         ["steps", "steps", (240, 260, 1040, 710)],
         ["post", "post_close", (480, 140, 800, 460)],
         ["siding", "close", (440, 100, 840, 400)]]
NAMES = {"A": "A today", "B": "B finish", "C": "C final"}


def sheet(runs, views, light, w=420):
    rows = []
    for v in views:
        paths = [os.path.join(runs[r], "%s_%s.png" % (light, v)) for r in "ABC"]
        if not all(os.path.exists(p) for p in paths):
            continue
        rows.append(row([label(Image.open(p).convert("RGB").resize((w, w * 9 // 16), Image.LANCZOS),
                               "%s · %s" % (NAMES[r], v)) for r, p in zip("ABC", paths)]))
    return column(rows) if rows else None


def costs(log):
    out = {}
    if os.path.exists(log):
        for line in open(log, errors="replace"):
            m = re.match(r"LabStreet (\w+) (\w+) draws ([\d.]+) primitives ([\d.]+) objects ([\d.]+) render_cpu_ms ([\d.]+)", line)
            if m:
                out[(m.group(1), m.group(2))] = [float(x) for x in m.groups()[2:]]
            m = re.match(r"LabCount: (\d+) meshes, (\d+) triangles, (\d+) materials", line)
            if m:
                out["count"] = [int(x) for x in m.groups()]
    return out


def main():
    a = dict(x[2:].split("=", 1) for x in sys.argv[1:] if x.startswith("--") and "=" in x)
    runs = {"A": a.get("a", "build/fc_A"), "B": a.get("b", "build/fin_B"), "C": a.get("c", "build/fc_C")}
    street = {"A": a.get("sa", "build/st_A"), "B": a.get("sb", "build/st_B"), "C": a.get("sc", "build/st_C")}
    out = a.get("out", os.path.join(ROOT, "docs", "screenshots", "material_lab", "final"))
    os.makedirs(out, exist_ok=True)
    for light in ("noon", "golden", "night"):
        s = sheet(runs, VIEWS, light)
        if s:
            s.save(os.path.join(out, "views_%s.jpg" % light), quality=88)
        crows = []
        for name, v, box in CLOSE:
            paths = [os.path.join(runs[r], "%s_%s.png" % (light, v)) for r in "ABC"]
            if not all(os.path.exists(p) for p in paths):
                continue
            cells = []
            for r, p in zip("ABC", paths):
                c = Image.open(p).convert("RGB").crop(box)
                c = c.resize((420, c.height * 420 // c.width), Image.NEAREST)
                cells.append(label(c, "%s · %s · %s" % (r, name, light)))
            crows.append(row(cells))
        if crows:
            column(crows).save(os.path.join(out, "closeups_%s.jpg" % light), quality=90)
        s = sheet(street, STREET, light)
        if s:
            s.save(os.path.join(out, "street_%s.jpg" % light), quality=88)
    c = {r: costs(street[r] + ".log") for r in "ABC"}
    lines = ["# Main Street: what each variant costs to draw", "",
             "Mean of 30 frames a view under lavapipe (CPU-side render time; Sean's GPU differs). "
             "A the game today, B the finish, C the final candidate.", "",
             "| Light | View | Draws A / B / C | Primitives A / B / C | Render CPU ms A / B / C |", "|---|---|---|---|---|"]
    for light in ("noon", "golden"):
        for v in STREET:
            vals = [c[r].get((light, v)) for r in "ABC"]
            if not all(vals):
                continue
            lines.append("| %s | %s | %s | %s | %s |" % (
                light, v, " / ".join("%.0f" % x[0] for x in vals), " / ".join("%.0f" % x[1] for x in vals),
                " / ".join("%.2f" % x[3] for x in vals)))
    if all("count" in c[r] for r in "ABC"):
        lines += ["", "Whole street (visible meshes): " + "; ".join(
            "%s %d meshes, %d triangles, %d materials" % (r, *c[r]["count"]) for r in "ABC")]
    open(os.path.join(out, "street.md"), "w").write("\n".join(lines) + "\n")
    frames = {r: sorted(glob.glob(os.path.join(runs[r], "pan_golden_*.png"))) for r in "ABC"}
    if all(frames.values()):
        n = min(len(f) for f in frames.values())
        ims = [row([label(Image.open(frames[r][k]).convert("RGB").resize((420, 236), Image.LANCZOS), NAMES[r])
                    for r in "ABC"], gap=4) for k in range(n)]
        gif = os.path.join(ROOT, "build", "material_lab_final_pan.gif")
        ims[0].save(gif, save_all=True, append_images=ims[1:] + ims[-2:0:-1], duration=200, loop=0)
        print("gif", gif)
    print("sheets in", out)


if __name__ == "__main__":
    main()
