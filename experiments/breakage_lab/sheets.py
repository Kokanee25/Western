#!/usr/bin/env python3
"""Before-and-after sheets from a rendered run (run.py --render): one sheet a target, a row a
weapon (before / just after / at the end), or for a scenario with a man, a row a body.

    python3 experiments/breakage_lab/sheets.py RENDER_ROOT OUT_DIR             # every target
    python3 experiments/breakage_lab/sheets.py RENDER_ROOT OUT_DIR --only=lamp,man_on_table
    python3 experiments/breakage_lab/sheets.py RENDER_ROOT OUT_DIR --bodies=chair_dynamite_1m
    python3 experiments/breakage_lab/sheets.py side BASE_ROOT CANDIDATE_ROOT OUT.jpg NAME,NAME   # before/after a change
    python3 experiments/breakage_lab/sheets.py look ROOT OUT.jpg [ROOT2 ...]   # run.py --look: a row a run, a column a moment

Rows come from RENDER_ROOT/<scenario>[__<body>]/{before,mid,after}.png; a missing frame is a grey
tile. Each row is labelled with what the summary says happened.
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

TILE = (320, 180)
LABEL_W = 230
FRAMES = ("before", "mid", "after")


def font(size):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/dejavu/DejaVuSans.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def row_label(summary):
    if not summary:
        return ["(no summary)"]
    t = summary["target_result"]
    lines = [summary["scenario"] + (f"  [{summary['body']}]" if summary.get("body") else "")]
    lines.append(f"target: {t.get('result', '?')}")
    lines.append(f"broken {summary['broken']['count']}, pieces {summary['pieces']['count']}")
    if summary["fire"]["caught_count"] or summary["fire"]["spills_at_end"]:
        lines.append(f"caught {summary['fire']['caught_count']}, spills {summary['fire']['spills_at_end']}")
    for m in summary.get("men", []):
        bits = [m["role"]]
        if m.get("knocked_down"):
            bits.append("down")
        if m.get("role") == "dropped":
            bits.append("on table" if m.get("rests_on_table") else "off table")
        lines.append(" ".join(bits))
    q = summary["setup"].get("blast_query")
    if q:
        lines.append(f"blast looked at {q['found']}/{q['in_reach']}" + ("" if q["target_found"] else ", not the target"))
    return lines


def sheet(rows, title, out_path):
    f_title, f_row, f_col = font(18), font(13), font(14)
    w = LABEL_W + TILE[0] * len(FRAMES)
    h = 34 + 22 + TILE[1] * len(rows)
    img = Image.new("RGB", (w, h), (24, 22, 20))
    d = ImageDraw.Draw(img)
    d.text((8, 8), title, fill=(235, 225, 205), font=f_title)
    for i, name in enumerate(FRAMES):
        d.text((LABEL_W + i * TILE[0] + 6, 36), {"before": "before", "mid": "just after (~0.15 s)", "after": "at the end"}[name],
               fill=(200, 190, 170), font=f_col)
    for r, (path, summary) in enumerate(rows):
        y = 56 + r * TILE[1]
        for i, name in enumerate(FRAMES):
            p = os.path.join(path, name + ".png")
            if os.path.exists(p):
                tile = Image.open(p).convert("RGB")
                tile.thumbnail(TILE)
                img.paste(tile, (LABEL_W + i * TILE[0], y))
            else:
                d.rectangle([LABEL_W + i * TILE[0], y, LABEL_W + (i + 1) * TILE[0] - 1, y + TILE[1] - 1], fill=(70, 70, 70))
        for k, line in enumerate(row_label(summary)):
            d.text((8, y + 6 + k * 17), line, fill=(230, 220, 200) if k == 0 else (190, 180, 165), font=f_row)
        d.line([0, y, w, y], fill=(60, 55, 50))
    img.save(out_path, quality=82)
    print(out_path)


def summary_of(path):
    p = os.path.join(path, "summary.json")
    return json.load(open(p)) if os.path.exists(p) else None


def side(base, cand, out, names):
    """Before and after a change: a row a scenario, the base run's just-after and end frames beside
    the candidate's."""
    f_title, f_row = font(18), font(13)
    cols = [("before: just after", base, "mid"), ("before: at the end", base, "after"),
            ("after the change: just after", cand, "mid"), ("after the change: at the end", cand, "after")]
    w = LABEL_W + TILE[0] * len(cols)
    img = Image.new("RGB", (w, 56 + TILE[1] * len(names)), (24, 22, 20))
    d = ImageDraw.Draw(img)
    d.text((8, 8), os.path.basename(out).rsplit(".", 1)[0], fill=(235, 225, 205), font=f_title)
    for i, (label, _, _) in enumerate(cols):
        d.text((LABEL_W + i * TILE[0] + 6, 36), label, fill=(200, 190, 170), font=f_row)
    for r, n in enumerate(names):
        y = 56 + r * TILE[1]
        for i, (_, root, frame) in enumerate(cols):
            p = os.path.join(root, n, frame + ".png")
            if os.path.exists(p):
                tile = Image.open(p).convert("RGB")
                tile.thumbnail(TILE)
                img.paste(tile, (LABEL_W + i * TILE[0], y))
        sb, sc = summary_of(os.path.join(base, n)), summary_of(os.path.join(cand, n))
        lines = [n.split("__")[0]]
        for tag, sm in (("before", sb), ("after", sc)):
            if sm:
                lines.append(f"{tag}: {sm['target_result'].get('result')}, {sm['broken']['count']} broken")
        for k, line in enumerate(lines):
            d.text((8, y + 6 + k * 17), line, fill=(230, 220, 200) if k == 0 else (190, 180, 165), font=f_row)
    img.save(out, quality=82)
    print(out)


def look(roots, out):
    """The look over time (run.py --look): a row a run, its t*.png frames left to right. Several
    roots (a base and a candidate) give their rows one after the other, each labelled with its root."""
    f_title, f_row = font(18), font(13)
    rows = []
    for root in roots:
        for x in sorted(os.listdir(root)):
            p = os.path.join(root, x)
            frames = sorted(f for f in os.listdir(p) if f.startswith("t") and f.endswith(".png")) if os.path.isdir(p) else []
            if frames:
                rows.append((os.path.basename(root), x, p, frames))
    if not rows:
        sys.exit("no t*.png frames under " + ", ".join(roots))
    times = sorted({f for r in rows for f in r[3]})
    tile = (240, 135)
    w = LABEL_W + tile[0] * len(times)
    img = Image.new("RGB", (w, 56 + tile[1] * len(rows)), (24, 22, 20))
    d = ImageDraw.Draw(img)
    d.text((8, 8), os.path.basename(out).rsplit(".", 1)[0], fill=(235, 225, 205), font=f_title)
    for i, f in enumerate(times):
        d.text((LABEL_W + i * tile[0] + 6, 36), f"{float(f[1:-4]):g} s", fill=(200, 190, 170), font=f_row)
    for r, (root, name, path, frames) in enumerate(rows):
        y = 56 + r * tile[1]
        for i, f in enumerate(times):
            if f in frames:
                t = Image.open(os.path.join(path, f)).convert("RGB")
                t.thumbnail(tile)
                img.paste(t, (LABEL_W + i * tile[0], y))
        for k, line in enumerate([name.split("__")[0], root]):
            d.text((8, y + 6 + k * 17), line, fill=(230, 220, 200) if k == 0 else (190, 180, 165), font=f_row)
    img.save(out, quality=85)
    print(out)


def main():
    if len(sys.argv) >= 4 and sys.argv[1] == "look":
        return look([os.path.abspath(a) for a in sys.argv[2:3] + sys.argv[4:]], sys.argv[3])
    if len(sys.argv) >= 2 and sys.argv[1] == "side":
        # sheets.py side BASE_ROOT CANDIDATE_ROOT OUT.jpg NAME[,NAME...] (the run folders' names)
        return side(os.path.abspath(sys.argv[2]), os.path.abspath(sys.argv[3]), sys.argv[4], sys.argv[5].split(","))
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    root, out = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
    os.makedirs(out, exist_ok=True)
    only = bodies = None
    for a in sys.argv[3:]:
        if a.startswith("--only="):
            only = a[7:].split(",")
        elif a.startswith("--bodies="):
            bodies = a[9:].split(",")
    lab = os.path.dirname(os.path.abspath(__file__))
    d = json.load(open(os.path.join(lab, "scenarios.json")))
    dirs = sorted(x for x in os.listdir(root) if os.path.isdir(os.path.join(root, x)) and "_repeat" not in x)
    if bodies:
        for scen in bodies:
            rows = [(os.path.join(root, x), summary_of(os.path.join(root, x))) for x in dirs if x.split("__")[0] == scen]
            if rows:
                sheet(rows, f"{scen}: each body", os.path.join(out, f"{scen}_bodies.jpg"))
        return
    for t in list(d["targets"]) + list(d["extras"]):
        if only and t not in only:
            continue
        rows = []
        ws = d["targets"][t].get("weapons", [w for w in d["weapons"] if not d["weapons"][w].get("only_listed")]) if t in d["targets"] else [""]
        for w in ws:
            scen = f"{t}_{w}" if w else t
            match = [x for x in dirs if x.split("__")[0] == scen]
            for x in match[:1] if t in d["targets"] else match:
                rows.append((os.path.join(root, x), summary_of(os.path.join(root, x))))
        if rows:
            sheet(rows, f"{t}: before and after", os.path.join(out, f"{t}.jpg"))


if __name__ == "__main__":
    main()
