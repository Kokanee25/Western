#!/usr/bin/env python3
"""The ragdoll lab's pictures and comparisons (README.md).

  sheet RUN_DIR [--times=0,0.25,0.5,1,2,3] [--out=PNG] [--from=hit]
      one scenario's views (rows) at times after he goes limp (or the ball hits him) (columns)
  side BASE_DIR CANDIDATE_DIR [--times=...] [--out=PNG]
      two runs of one scenario, matched by time after going limp: base above, candidate below,
      with the per-time numbers (centre of mass height, peak speed) and the metric differences
  video RUN_DIR [--slow=4] [--out=MP4]
      the views side by side at game speed, then again slowed down (into build/, never git)
  diff BASE_ROOT CANDIDATE_ROOT
      each scenario's headline numbers (settle, peak speed, penetration, self-overlap, joint gap,
      how many flags), base -> candidate, and which scenarios only one of them has
"""
import csv, json, os, subprocess, sys
from PIL import Image, ImageDraw


def opt(name, default=None):
    for a in sys.argv[2:]:
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def pos_args():
    return [a for a in sys.argv[2:] if not a.startswith("--")]


def summary(run):
    sm = json.load(open(os.path.join(run, "summary.json")))
    fl = os.path.join(run, "flags.json")
    sm["flags"] = json.load(open(fl))["flags"] if os.path.exists(fl) else None
    return sm


def ticks(run):
    return {int(r["tick"]): r for r in csv.DictReader(open(os.path.join(run, "ticks.csv")))}


def views(run):
    d = os.path.join(run, "frames")
    return sorted(os.listdir(d), key=lambda v: ["front", "side", "three", "top"].index(v) if v in ["front", "side", "three", "top"] else 9)


def frame_at(run, view, tick):
    d = os.path.join(run, "frames", view)
    have = sorted(int(f[:-4]) for f in os.listdir(d) if f.endswith(".png"))
    best = min(have, key=lambda t: abs(t - tick))
    return Image.open(os.path.join(d, "%04d.png" % best)).convert("RGB"), best


def label(img, text, colour=(255, 255, 255)):
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, img.width, 14], fill=(0, 0, 0))
    d.text((3, 1), text, fill=colour)
    return img


def strip(run, times, title):
    sm = summary(run)
    # --from=hit: times after the ball hit him (a hit that doesn't drop him), not after he went limp.
    limp = int(round(sm["hit_t" if opt("from") == "hit" else "limp_t"] * 60))
    tk = ticks(run)
    vs = views(run)
    tiles = []
    for v in vs:
        row = []
        for t in times:
            im, got = frame_at(run, v, limp + int(round(t * 60)))
            r = tk.get(got, {})
            row.append(label(im.copy(), "%s t+%.2fs  com y %.2f  vmax %.1f" % (v, (got - limp) / 60.0,
                       float(r.get("com_y", 0)), float(r.get("max_speed", 0)))))
        tiles.append(row)
    w, h = tiles[0][0].size
    sheet = Image.new("RGB", (w * len(times), h * len(vs) + 18), (30, 30, 30))
    ImageDraw.Draw(sheet).text((4, 3), title, fill=(255, 220, 120))
    for i, row in enumerate(tiles):
        for k, im in enumerate(row):
            sheet.paste(im, (k * w, 18 + i * h))
    return sheet


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    times = [float(x) for x in opt("times", "0,0.25,0.5,0.75,1,1.5,2,3").split(",")]
    p = pos_args()
    if cmd == "sheet":
        run = p[0]
        sm = summary(run)
        out = opt("out", os.path.join(run, "sheet.png"))
        flags = "not analysed (analyse.py)" if sm["flags"] is None else (", ".join(sm["flags"]) or "none")
        settle = "never" if sm["settle_s"] is None else "%.2f s" % sm["settle_s"]
        strip(run, times, "%s  (settle %s, flags: %s)" % (sm["scenario"], settle, flags)).save(out)
        print(out)
    elif cmd == "side":
        a, b = p[0], p[1]
        sa, sb = strip(a, times, "BASE " + a), strip(b, times, "CANDIDATE " + b)
        sheet = Image.new("RGB", (max(sa.width, sb.width), sa.height + sb.height + 4), (0, 0, 0))
        sheet.paste(sa, (0, 0))
        sheet.paste(sb, (0, sa.height + 4))
        out = opt("out", os.path.join(b, "side_by_side.png"))
        sheet.save(out)
        print(out)
        print_diff([summary(a)], [summary(b)])
    elif cmd == "video":
        run = p[0]
        slow = float(opt("slow", "4"))
        out = opt("out", os.path.join(run, "views.mp4"))
        vs = views(run)
        every = 2
        fps = 60 / every
        inputs = []
        for v in vs:
            inputs += ["-framerate", str(fps), "-pattern_type", "glob", "-i", os.path.join(run, "frames", v, "*.png")]
        stack = "".join("[%d:v]" % i for i in range(len(vs))) + "hstack=inputs=%d[s]" % len(vs) if len(vs) > 1 else "[0:v]null[s]"
        filt = stack + ";[s]split[a][b];[b]setpts=%.2f*PTS[c];[a][c]concat=n=2:v=1[o]" % slow
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error"] + inputs + ["-filter_complex", filt, "-map", "[o]",
                        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "28", out], check=True)
        print(out)
    elif cmd == "diff":
        a, b = p[0], p[1]
        ra = json.load(open(os.path.join(a, "baseline.json")))
        rb = json.load(open(os.path.join(b, "baseline.json")))
        print_diff(ra, rb)
    else:
        print(__doc__)
        return 1
    return 0


def print_diff(ra, rb):
    by = {r["scenario"]: r for r in rb}
    only_a = [r["scenario"] for r in ra if r["scenario"] not in by]
    only_b = [r["scenario"] for r in rb if r["scenario"] not in {x["scenario"] for x in ra}]
    if only_a or only_b:
        print("not in both: base only %s; candidate only %s" % (only_a or "-", only_b or "-"))
    print("| scenario | settle s | peak speed | penetration | self overlap | joint gap | flags |")
    print("|---|---|---|---|---|---|---|")
    for r in ra:
        s = by.get(r["scenario"])
        if not s:
            continue
        f = lambda x: "never" if x is None else "%.2f" % x
        print("| %s | %s -> %s | %.1f -> %.1f | %.3f -> %.3f | %.3f -> %.3f | %.3f -> %.3f | %s -> %s |" % (
            r["scenario"], f(r["settle_s"]), f(s["settle_s"]), r["peak"]["speed"], s["peak"]["speed"],
            r["peak"]["penetration"], s["peak"]["penetration"], r["peak"]["self_overlap"], s["peak"]["self_overlap"],
            r["peak"]["joint_gap"], s["peak"]["joint_gap"], len(r.get("flags") or {}), len(s.get("flags") or {})))


if __name__ == "__main__":
    sys.exit(main())
