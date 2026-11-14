#!/usr/bin/env python3
"""Issue #596 step 3b: one film a scenario, its lift settings side by side, labelled, at game speed
and then slowed (as compare.py video). Frames from run.py --render roots.

  python3 experiments/physics_lab/thrown_films.py --out=DIR [--view=side] \
      --roots="lift 0=build/physics_lab/f0,lift 0.8=build/physics_lab/f08,lift 1.1=build/physics_lab/f11" \
      Z_thrown_1m Z_thrown_3m ...
"""
import glob, os, shutil, subprocess, sys, tempfile
from PIL import Image, ImageDraw


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def main():
    out = opt("out", "build/physics_lab/films")
    view = opt("view", "all")
    slow = float(opt("slow", "3"))
    roots = [r.split("=", 1) for r in opt("roots", "").split(",") if r]
    names = [a for a in sys.argv[1:] if not a.startswith("--")]
    os.makedirs(out, exist_ok=True)
    for name in names:
        # Every view the scenario rendered (its own `views` win over --views), one row each; or --view.
        first = os.path.join(roots[0][1], name, "frames")
        vs = [view] if view != "all" else (sorted(os.listdir(first)) if os.path.isdir(first) else [])
        lists = []  # (label, [frames of each view])
        for label, root in roots:
            per = [sorted(glob.glob(os.path.join(root, name, "frames", v, "*.png"))) for v in vs]
            if not per or not all(per):
                print("no frames:", root, name, vs)
                per = []
            lists.append((label, per))
        n = min((len(fs) for _, per in lists for fs in per), default=0)
        if n == 0 or any(not per for _, per in lists):
            continue
        tmp = tempfile.mkdtemp()
        for i in range(n):
            cols = []
            for label, per in lists:
                rows = [Image.open(fs[i]).convert("RGB") for fs in per]
                w, h = rows[0].size
                col = Image.new("RGB", (w, h * len(rows) + 4 * (len(rows) - 1)), (20, 20, 20))
                for r, im in enumerate(rows):
                    col.paste(im, (0, r * (h + 4)))
                d = ImageDraw.Draw(col)
                d.rectangle((0, 0, 8 + 7 * len(label), 16), fill=(0, 0, 0))
                d.text((4, 3), label, fill=(255, 255, 255))
                cols.append(col)
            w, h = cols[0].size
            sheet = Image.new("RGB", (w * len(cols) + 4 * (len(cols) - 1), h), (20, 20, 20))
            for k, col in enumerate(cols):
                sheet.paste(col, (k * (w + 4), 0))
            if sheet.width % 2 or sheet.height % 2:
                sheet = sheet.crop((0, 0, sheet.width - sheet.width % 2, sheet.height - sheet.height % 2))
            sheet.save(os.path.join(tmp, "%05d.png" % i))
        mp4 = os.path.join(out, "%s.mp4" % name)
        filt = "[0:v]split[a][b];[b]setpts=%.2f*PTS[c];[a][c]concat=n=2:v=1[o]" % slow
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "30", "-i", os.path.join(tmp, "%05d.png"),
                        "-filter_complex", filt, "-map", "[o]", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "26", mp4],
                       check=True)
        # A still sheet too: from just before the blast (0.5 s in, after the stand) to 2 s after it.
        shutil.copy(os.path.join(tmp, "%05d.png" % 0), os.path.join(out, "%s_start.png" % name))
        picks = [min(int(t * 30), n - 1) for t in (0.45, 0.65, 0.85, 1.05, 1.3, 1.6, 2.0, 2.5)]
        rows = [Image.open(os.path.join(tmp, "%05d.png" % p)) for p in picks]
        sw = 1200
        rows = [r.resize((sw, int(r.height * sw / r.width))) for r in rows]
        sh = Image.new("RGB", (sw, sum(r.height for r in rows)))
        y = 0
        for r in rows:
            sh.paste(r, (0, y))
            y += r.height
        sh.save(os.path.join(out, "%s_sheet.jpg" % name), quality=80)
        os.remove(os.path.join(out, "%s_start.png" % name))
        shutil.rmtree(tmp)
        print(mp4)


if __name__ == "__main__":
    main()
