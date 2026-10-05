#!/usr/bin/env python3
"""The visual checks (docs/briefs/review-tools.md / automated-checks.md, the art session's part):
what a reviewer would otherwise catch by eye, as a pass/fail for CI.

  python3 tools/visual_checks.py --from=DIR [--twin=DIR2] [--probe=PDIR] [--tour=build/tour] [--only=a,b]

From the renders in DIR (tools/screenshots.gd's views; the tour's frames in --tour when given):
  blank     a frame of one colour, black, or mostly exact black (a NaN in the lighting draws
            black: the saloon at 23:40 did, with only its doorway left)
  missing   Godot's magenta for a texture or shader that failed (pixels)
  flicker   (--twin) a second render of the same build: a view that should be still differs by
            more than its run-to-run noise (docs/screenshots/golden/tolerances.json gives each
            view's measured noise; a scenario view's physics is what it allows for)
From the scene data in PDIR (tools/scene_probe.gd, run it first; it's headless):
  missing   grid materials drawn with no texture
  feet      a standing or seated man's soles in the ground or floor, or a standing man's both
            soles off it
  floating  floor-standing props and the street's dressing off whatever is under them, or sunk
            into it
  clothes   body skin (or an inner garment) through the garment over it: the share of the inner
            layer's vertices near the garment that lie outside its surface, per man, worst pair

Each check prints one line per view or item (ok / FAIL / warn, the value and its limit) and
the run exits 1 on any FAIL. Limits are DEFAULTS below unless tools/visual_checks.json sets one
for a view, a man or a prop ("known" entries record a measured fault being tolerated until it's
fixed, with why).

Run order in CI: render (tools/screenshots.gd twice for --twin, or reuse the golden check's
pair), probe (godot --headless --fixed-fps 60 -s res://tools/scene_probe.gd -- --out=PDIR),
then this.
"""
import argparse
import glob
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIMITS = os.path.join(ROOT, "tools", "visual_checks.json")
GOLDEN_TOL = os.path.join(ROOT, "docs", "screenshots", "golden", "tolerances.json")

DEFAULTS = {
    "blank_std": 3.0,        # luminance standard deviation (0-255) below this: one colour
    "blank_mean": 2.0,       # mean luminance below this: black
    "black_share": 0.6,      # share of exactly (0,0,0) pixels above this: NaN-black
    "magenta_share": 0.0005, # share of pure magenta pixels above this
    "flicker_mean": 1.5,     # still views: mean abs difference between two renders
    "flicker_share": 0.01,   # ... and share of pixels moved by more than 24/255
    "feet_in": 0.04,         # a sole this far into the ground or floor (m)
    "feet_float": 0.05,      # a standing man's both soles this far off it (m)
    "prop_float": 0.03,      # a floor-standing thing this far over what's under it (m)
    "prop_sunk": 0.05,       # ... or this far into it (m)
    "clothes_share": 0.03,   # share of inner vertices near a garment that are outside it
    "clothes_out": 0.004,    # how far outside counts (m)
    "clothes_near": 0.03,    # inner vertices within this of the garment are checked (m)
}

# HumanBody._dress(): which body parts each garment covers; inner to outer.
TORSO = ["chest", "abdomen"]
ARMS = ["upper_arm_r", "upper_arm_l", "forearm_r", "forearm_l"]
LEGS = ["thigh_r", "thigh_l", "shin_r", "shin_l"]
COVERS = {
    "shirt": TORSO + ARMS,
    "trousers": ["pelvis"] + LEGS,
    "vest": TORSO,
    "coat": TORSO + ARMS + ["pelvis", "thigh_r", "thigh_l"],
    "hat": ["head"],
}
ORDER = ["skin", "head", "hair", "shirt", "trousers", "vest", "coat", "hat"]
HAT = ["hat", "hat_brim", "hat_band"]
STANDING = {"stand", "wary", "aim", "hands_up", "draw", "hold", "shove", "watch"}
SEATED = {"sit", "sit_lean"}


def views():
    names = []
    with open(os.path.join(ROOT, "tools", "screenshots.gd")) as f:
        on = False
        for line in f:
            if line.startswith("const VIEWS"):
                on = True
            elif on and line.startswith("]"):
                break
            elif on and line.strip().startswith('["'):
                s = line.strip()
                names.append(s[2:s.index('"', 2)])
    return names


def limits_for(table, section, key):
    lim = dict(DEFAULTS)
    lim.update(table.get(section, {}).get(key, {}))
    return lim


class Report:
    def __init__(self):
        self.rows = []
        self.failed = 0

    def add(self, check, item, ok, text, warn=False):
        status = "ok  " if ok else ("warn" if warn else "FAIL")
        if not ok and not warn:
            self.failed += 1
        self.rows.append((check, item, status, text))

    def print(self):
        w = max([len(r[1]) for r in self.rows] + [10])
        for check, item, status, text in self.rows:
            print("  %-9s %-*s %s  %s" % (check, w, item, status, text))
        print("%d checks, %d failed" % (len(self.rows), self.failed))


def load_rgb(path):
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.int16)


def pixel_checks(rep, table, frames):
    for name, path in frames:
        lim = limits_for(table, "views", name)
        a = load_rgb(path)
        lum = 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]
        std, mean = float(lum.std()), float(lum.mean())
        black = float((a.sum(axis=2) == 0).mean())
        ok = std >= lim["blank_std"] and mean >= lim["blank_mean"] and black <= lim["black_share"]
        rep.add("blank", name, ok, "lum mean %.1f sd %.1f, exact black %.3f (limits %.1f / %.1f / %.2f)"
                % (mean, std, black, lim["blank_mean"], lim["blank_std"], lim["black_share"]))
        mag = float(((a[..., 0] > 220) & (a[..., 1] < 40) & (a[..., 2] > 220)).mean())
        rep.add("missing", name, mag <= lim["magenta_share"], "magenta %.4f (limit %.4f)" % (mag, lim["magenta_share"]))


def flicker_checks(rep, table, src, twin, names):
    gtol = {}
    if os.path.exists(GOLDEN_TOL):
        with open(GOLDEN_TOL) as f:
            gtol = json.load(f)
    for v in names:
        a, b = os.path.join(src, v + ".png"), os.path.join(twin, v + ".png")
        if not (os.path.exists(a) and os.path.exists(b)):
            continue
        lim = limits_for(table, "views", v)
        m = gtol.get(v, {})
        tm, ts = max(lim["flicker_mean"], m.get("mean", 0)), max(lim["flicker_share"], m.get("share", 0))
        x, y = load_rgb(a), load_rgb(b)
        d = np.abs(x - y)
        mean, share = float(d.mean()), float((d.max(axis=2) > 24).mean())
        rep.add("flicker", v, mean <= tm and share <= ts, "two renders differ: mean %.2f share %.4f (limits %.2f / %.4f)"
                % (mean, share, tm, ts))


def probe_checks(rep, table, pdir):
    with open(os.path.join(pdir, "scene_probe.json")) as f:
        data = json.load(f)
    bones = data["bones"]
    for m in data["materials"]:
        rep.add("missing", m["node"], False, "grid material with no %s (%s)" % (m["missing"], m["shader"]))
    if not data["materials"]:
        rep.add("missing", "grid materials", True, "every grid material has its texture")
    for p in data["people"]:
        key = "%s/%s" % (p["phase"], p["name"])
        lim = limits_for(table, "people", key)
        feet_check(rep, key, p, lim)
        clothes_check(rep, key, p, lim, bones, pdir)
    for q in data["props"]:
        lim = limits_for(table, "props", q["name"])
        if q["ground"] is None:
            rep.add("floating", q["name"], False, "nothing solid within 0.6 m under it (a shelf with no collision?)", warn=True)
            continue
        gap = q["origin"][1] - q["ground"]
        ok = -lim["prop_sunk"] <= gap <= lim["prop_float"]
        rep.add("floating", q["name"], ok, "%+.3f m over what's under it (limits +%.2f / -%.2f)%s"
                % (gap, lim["prop_float"], lim["prop_sunk"], known(lim)))


def known(lim):
    return ("  known: " + lim["known"]) if "known" in lim else ""


def feet_check(rep, key, p, lim):
    if p["limp"] or p["prone"] or not (p["pose"] in STANDING or p["pose"] in SEATED):
        return
    depths = []
    for side, f in p["feet"].items():
        if f["ground"] is None:
            continue
        depths.append(f["low"] - f["ground"])
    if not depths:
        return
    deepest = min(depths)
    ok = deepest >= -lim["feet_in"]
    text = "soles %s m over the ground (limit -%.2f)" % (", ".join("%+.3f" % d for d in depths), lim["feet_in"])
    if p["pose"] in STANDING:
        ok = ok and min(depths) <= lim["feet_float"]
        text += ", both off it over +%.2f fails" % lim["feet_float"]
    rep.add("feet", "%s (%s)" % (key, p["pose"]), ok, text + known(lim))


def clothes_check(rep, key, p, lim, bones, pdir):
    from scipy.spatial import cKDTree
    rows = np.fromfile(os.path.join(pdir, p["mesh"]), dtype=np.float32).reshape(-1, 7)
    shapes = p["shapes"]

    def layer(names):
        parts = [rows[shapes[n][0]:shapes[n][0] + shapes[n][1]] for n in names if n in shapes]
        return np.concatenate(parts) if parts else np.zeros((0, 7), np.float32)

    worst = (0.0, "", 0)
    for outer in ["shirt", "trousers", "vest", "coat", "hat"]:
        g = layer(HAT if outer == "hat" else [outer])
        if len(g) < 10:
            continue
        covered = [bones.index(s) for s in COVERS[outer] if s in bones]
        tree = cKDTree(g[:, :3])
        inner_names = [n for n in ORDER[:ORDER.index(outer)] if n in shapes and n not in HAT]
        for inner in inner_names:
            v = layer([inner])
            v = v[np.isin(v[:, 6].astype(int), covered)]
            if len(v) == 0:
                continue
            dist, idx = tree.query(v[:, :3], k=3)
            near = dist[:, 0] < lim["clothes_near"]
            if near.sum() < 20:
                continue
            n = g[idx, 3:6].mean(axis=1)
            n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-9
            d = ((v[:, None, :3] - g[idx, :3]).mean(axis=1) * n).sum(axis=1)
            out = (d > lim["clothes_out"]) & near
            share = float(out.sum()) / float(near.sum())
            if share > worst[0] or worst[1] == "":
                worst = (share, "%s through %s" % (inner, outer), int(near.sum()))
    if worst[1] == "":
        rep.add("clothes", key, True, "no garments over a body layer (%s)" % (p["model"] or "BodyMesh"))
        return
    rep.add("clothes", key, worst[0] <= lim["clothes_share"], "worst: %s %.3f of %d vertices (limit %.3f)%s"
            % (worst[1], worst[0], worst[2], lim["clothes_share"], known(lim)))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--from", dest="src")
    ap.add_argument("--twin", default=None)
    ap.add_argument("--probe", default=None)
    ap.add_argument("--tour", default=None)
    ap.add_argument("--only", default="")
    args = ap.parse_args()
    table = {}
    if os.path.exists(LIMITS):
        with open(LIMITS) as f:
            table = json.load(f)
    rep = Report()
    names = views()
    if args.only:
        keys = args.only.split(",")
        names = [v for v in names if any(k in v for k in keys)]
    frames = []
    if args.src:
        frames += [(v, os.path.join(args.src, v + ".png")) for v in names if os.path.exists(os.path.join(args.src, v + ".png"))]
    if args.tour and os.path.isdir(args.tour):
        frames += [("tour/" + os.path.basename(p)[:-4], p) for p in sorted(glob.glob(os.path.join(args.tour, "*.png")))]
    pixel_checks(rep, table, frames)
    if args.src and args.twin:
        flicker_checks(rep, table, args.src, args.twin, names)
    if args.probe:
        probe_checks(rep, table, args.probe)
    if not rep.rows:
        ap.error("nothing to check: --from=DIR and/or --probe=DIR")
    rep.print()
    sys.exit(1 if rep.failed else 0)


if __name__ == "__main__":
    main()
