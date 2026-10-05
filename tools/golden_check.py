#!/usr/bin/env python3
"""Golden images: every fixed view in tools/screenshots.gd has an approved render in
docs/screenshots/golden/<view>.png, and a change beyond its tolerance fails the check
(CLAUDE.md "Golden images"; docs/briefs/review-tools.md, art item 3).

  python3 tools/golden_check.py --render [--only=a,b] [--out=DIR] [--diffs=DIR]
      renders the views (tools/screenshots.gd, Vulkan under xvfb) and checks them
  python3 tools/golden_check.py --from=DIR [--only=a,b] [--diffs=DIR]
      checks renders already made
  python3 tools/golden_check.py --approve --from=DIR [--only=a,b] [--noise=DIR_A,DIR_B]
      copies the renders in as the new goldens (an approved look updates them in the same
      merge); with two renders of the same build, --noise sets each view's tolerance from the
      run-to-run noise (NOISE_FACTOR times it, never under the floor), else the floor
  python3 tools/golden_check.py --list

Two measures per view, on RGB at the golden's size: `mean`, the mean absolute difference per
channel (0-255), and `share`, the share of pixels whose largest channel difference is over
PIXEL_STEP. A view passes when both are within its tolerance in tolerances.json (views without
an entry use DEFAULT). Views whose scenario runs physics, particles or people's brains (fire,
blasts, a fight, smoke) are noisier than a still, so their tolerances come from measured noise,
not one number for all. A render with no golden fails (--allow-new lets it through, printed).
Exit code 1 on any failure, so CI can run it (the gameplay session wires it in).

The renders are what a software GPU (lavapipe) draws at 1280x720; a real GPU differs a little
everywhere (filtering, precision), so goldens are compared only against renders made the same
way. A failing view writes <diffs>/<view>.png: golden | render | the difference, amplified.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

import numpy as np
from PIL import Image, ImageChops, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GOLDEN = os.path.join(ROOT, "docs", "screenshots", "golden")
TOLERANCES = os.path.join(GOLDEN, "tolerances.json")
PIXEL_STEP = 24  # a pixel "differs" when a channel moves more than this (of 255)
DEFAULT = {"mean": 1.5, "share": 0.01}  # the floor: what a still view may drift
NOISE_FACTOR = 3.0  # a view's tolerance from its measured run-to-run noise
W, H = 1280, 720


def views():
    """The view names in tools/screenshots.gd, in its order."""
    names = []
    with open(os.path.join(ROOT, "tools", "screenshots.gd")) as f:
        in_views = False
        for line in f:
            if line.startswith("const VIEWS"):
                in_views = True
                continue
            if in_views:
                if line.startswith("]"):
                    break
                s = line.strip()
                if s.startswith('["'):
                    names.append(s[2:s.index('"', 2)])
    return names


def load(path):
    img = Image.open(path).convert("RGB")
    if img.size != (W, H):
        img = img.resize((W, H), Image.LANCZOS)
    return img


def compare(a, b):
    """mean abs difference per channel, share of pixels over PIXEL_STEP."""
    x = np.asarray(a, dtype=np.int16)
    y = np.asarray(b, dtype=np.int16)
    d = np.abs(x - y)
    return float(d.mean()), float((d.max(axis=2) > PIXEL_STEP).mean())


def diff_image(golden, render, path, name, mean, share, tol):
    amp = ImageChops.difference(golden, render).point(lambda v: min(255, v * 6))
    out = Image.new("RGB", (W * 3 + 16, H + 28), (20, 20, 20))
    out.paste(golden, (0, 28))
    out.paste(render, (W + 8, 28))
    out.paste(amp, (2 * W + 16, 28))
    d = ImageDraw.Draw(out)
    d.text((8, 8), "%s   golden | render | difference x6   mean %.2f (tol %.2f)  share %.4f (tol %.4f)"
           % (name, mean, tol["mean"], share, tol["share"]), fill=(255, 255, 255))
    out.save(path)


def render(out_dir, only):
    godot = os.environ.get("GODOT", "godot")
    # --fresh: the scene loaded again for every view, so a view never inherits the one before
    # (smoke in the air, a pose half eased, the clouds' drift) and a subset renders as the full run.
    cmd = [godot, "--path", ROOT, "--rendering-driver", "vulkan", "-s", "res://tools/screenshots.gd",
           "--", "--out=" + out_dir, "--fresh"]
    if only:
        cmd.append("--only=" + only)
    if not os.environ.get("DISPLAY"):
        cmd = ["xvfb-run", "-a"] + cmd
    print("rendering:", " ".join(cmd), flush=True)
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def tolerances():
    if os.path.exists(TOLERANCES):
        with open(TOLERANCES) as f:
            return json.load(f)
    return {}


def selected(only):
    names = views()
    if not only:
        return names
    keys = only.split(",")
    return [v for v in names if any(k in v for k in keys)]


def check(src, only, diffs, allow_new):
    tol_all = tolerances()
    failed = 0
    missing = 0
    rows = []
    if diffs:
        os.makedirs(diffs, exist_ok=True)
    for v in selected(only):
        rpath = os.path.join(src, v + ".png")
        gpath = os.path.join(GOLDEN, v + ".png")
        if not os.path.exists(rpath):
            rows.append((v, "no render"))
            continue
        if not os.path.exists(gpath):
            rows.append((v, "no golden" + ("" if allow_new else "  FAIL")))
            if not allow_new:
                missing += 1
            continue
        tol = dict(DEFAULT)
        tol.update(tol_all.get(v, {}))
        g, r = load(gpath), load(rpath)
        mean, share = compare(g, r)
        ok = mean <= tol["mean"] and share <= tol["share"]
        rows.append((v, "%s  mean %.2f/%.2f  share %.4f/%.4f" % ("ok  " if ok else "FAIL", mean, tol["mean"], share, tol["share"])))
        if not ok:
            failed += 1
            if diffs:
                diff_image(g, r, os.path.join(diffs, v + ".png"), v, mean, share, tol)
    width = max(len(r[0]) for r in rows) if rows else 10
    for name, text in rows:
        print("  %-*s  %s" % (width, name, text))
    print("%d views, %d failed, %d without a golden" % (len(rows), failed, missing))
    return failed + missing == 0


def approve(src, only, noise):
    os.makedirs(GOLDEN, exist_ok=True)
    tol_all = tolerances()
    pair = noise.split(",") if noise else None
    n = 0
    for v in selected(only):
        rpath = os.path.join(src, v + ".png")
        if not os.path.exists(rpath):
            print("  %s: no render, skipped" % v)
            continue
        shutil.copyfile(rpath, os.path.join(GOLDEN, v + ".png"))
        n += 1
        if pair:
            a, b = (os.path.join(d, v + ".png") for d in pair)
            if os.path.exists(a) and os.path.exists(b):
                mean, share = compare(load(a), load(b))
                tol_all[v] = {"mean": round(max(DEFAULT["mean"], mean * NOISE_FACTOR), 3),
                              "share": round(max(DEFAULT["share"], share * NOISE_FACTOR), 4),
                              "noise": {"mean": round(mean, 3), "share": round(share, 4)}}
                print("  %-28s noise mean %.3f share %.4f -> tolerance mean %.2f share %.4f"
                      % (v, mean, share, tol_all[v]["mean"], tol_all[v]["share"]))
    with open(TOLERANCES, "w") as f:
        json.dump(dict(sorted(tol_all.items())), f, indent=1, sort_keys=True)
        f.write("\n")
    print("%d goldens written to %s" % (n, os.path.relpath(GOLDEN, ROOT)))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--render", action="store_true")
    ap.add_argument("--from", dest="src")
    ap.add_argument("--out", default=os.path.join(ROOT, "build", "golden_check"))
    ap.add_argument("--only", default="")
    ap.add_argument("--diffs", default=None, help="where failing views' comparison pictures go (default <out>/diffs)")
    ap.add_argument("--approve", action="store_true")
    ap.add_argument("--noise", default=None, help="DIR_A,DIR_B: two renders of the same build, for tolerances")
    ap.add_argument("--allow-new", action="store_true")
    ap.add_argument("--list", action="store_true")
    args = ap.parse_args()
    if args.list:
        for v in views():
            print(("golden " if os.path.exists(os.path.join(GOLDEN, v + ".png")) else "       ") + v)
        return
    src = args.src
    if args.render:
        src = args.out
        os.makedirs(src, exist_ok=True)
        render(src, args.only)
    if not src:
        ap.error("--render or --from=DIR")
    if args.approve:
        approve(src, args.only, args.noise)
        return
    ok = check(src, args.only, args.diffs or os.path.join(args.out, "diffs"), args.allow_new)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
