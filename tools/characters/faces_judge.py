#!/usr/bin/env python3
"""The faces test's numbers (docs/briefs/faces.md, step 6), from tools/characters/faces_lights.gd's
pictures:

    python3 tools/characters/faces_judge.py DIR [--out=DIR/faces_judge.json]

* Each stamp's OKLab lightness against the squares round it, in each light, in the view where it
  faces you most (the brief asks 0.08-0.10 or more in at least two of three lights).
* Whether MediaPipe's face landmarker finds each man's eyes, nose tip and lip line, in each light
  and view (the front and three-quarters), with its confidence in the face.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "paint"))

GOAL = 0.08
VIEWS = {"front": (0, 0, 5), "three_quarter": (3.5, 0, 3.5), "side": (5, 0, 0)}   # faces_lights.gd's


def visible_mask(view, pts):
    """Which of the house head's points (body space) face the camera unhidden in a view of
    faces_lights.gd: a depth test against his own head (build/house_head/mesh.npz)."""
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "blender"))
    import house_head as hh
    d = np.load(os.path.join(hh.WORK, "mesh.npz"))
    to = np.array(VIEWS[view], float)
    to /= np.linalg.norm(to)
    yaw = np.arctan2(to[0], to[2]) + np.pi          # his front (-Z) turned onto `to`
    c, s_ = np.cos(yaw), np.sin(yaw)
    R = np.array([[c, 0, s_], [0, 1, 0], [-s_, 0, c]])
    f = R.T @ np.array([0.0, 0.0, -1.0])            # the camera's look, in his body space
    r = np.cross(f, [0.0, 1.0, 0.0])
    r /= np.linalg.norm(r)
    u = np.cross(r, f)
    centre = np.array([0.0, 1.62, 0.0])
    size, half = 600, 0.15
    _img, depth = hh.render(d["V"], d["F"], (r, u, f), size=size, centre=centre, half=half)
    rel = np.asarray(pts, float) - centre
    x = ((rel @ r) / (2 * half) + 0.5) * size
    y = (0.5 - (rel @ u) / (2 * half)) * size
    z = rel @ f
    out = []
    for xi, yi, zi in zip(x, y, z):
        xs, ys = int(np.clip(xi, 0, size - 1)), int(np.clip(yi, 0, size - 1))
        win = depth[max(ys - 1, 0):ys + 2, max(xs - 1, 0):xs + 2]
        out.append(bool(zi <= np.nanmin(np.where(np.isfinite(win), win, np.inf)) + 0.0025))
    return np.array(out)


def oklab_l(rgb):
    """OKLab lightness of sRGB (0-255) pixels (Ottosson 2020)."""
    c = np.asarray(rgb, float) / 255.0
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    l = 0.4122214708 * lin[..., 0] + 0.5363325363 * lin[..., 1] + 0.0514459929 * lin[..., 2]
    m = 0.2119034982 * lin[..., 0] + 0.6806995451 * lin[..., 1] + 0.1073969566 * lin[..., 2]
    s = 0.0883024619 * lin[..., 0] + 0.2817188376 * lin[..., 1] + 0.6299787005 * lin[..., 2]
    l_, m_, s_ = np.cbrt(l), np.cbrt(m), np.cbrt(s)
    return 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_


def sample(L, pts, r=1):
    h, w = L.shape
    out = []
    for x, y in pts:
        xi, yi = int(round(x)), int(round(y))
        if 0 <= xi < w and 0 <= yi < h:
            out.append(L[max(yi - r, 0):yi + r + 1, max(xi - r, 0):xi + r + 1].mean())
    return float(np.mean(out)) if out else float("nan")


def main():
    d = sys.argv[1]
    out = os.path.join(d, "faces_judge.json")
    for a in sys.argv[2:]:
        if a.startswith("--out="):
            out = a.split("=", 1)[1]
    rec = json.load(open(os.path.join(d, "stamps.json")))
    imgs = {}
    stamps = {}
    for p in rec["points"]:
        key = (p["light"], p["view"])
        if key not in imgs:
            imgs[key] = oklab_l(np.asarray(Image.open(os.path.join(d, "%s_%s.png" % key)).convert("RGB")))
        stamps.setdefault((p["man"], p["stamp"], p["light"]), []).append(p)
    result = {"stamps": {}, "landmarks": {}}
    lights = ["lamp", "sun", "shade"]
    reports = {}
    for (man, stamp, light), ps in sorted(stamps.items()):
        if man not in reports:
            reports[man] = json.load(open(os.path.join("assets/people", man + ".json"))).get("stamps", {})
        body = reports[man].get(stamp, {})
        best, a, b, seen = None, float("nan"), float("nan"), 0.0
        # The view where most of it, and of the squares round it, is in sight.
        for p in ps:
            va = visible_mask(p["view"], body["at"]) if man == "faces_test" else np.ones(len(p["at"]), bool)
            vr = visible_mask(p["view"], body["round"]) if man == "faces_test" else np.ones(len(p["round"]), bool)
            if not va.any() or not vr.any():
                continue
            score = va.mean() + 0.5 * vr.mean() + 0.25 * p["toward_you"]
            if best is None or score > seen:
                L = imgs[(light, p["view"])]
                best, seen = p, score
                a = sample(L, [q for q, v in zip(p["at"], va) if v])
                b = sample(L, [q for q, v in zip(p["round"], vr) if v])
        if best is None:
            result["stamps"].setdefault(man, {}).setdefault(stamp, {})[light] = {"view": None, "contrast": 0.0, "hidden": True}
            continue
        result["stamps"].setdefault(man, {}).setdefault(stamp, {})[light] = {
            "view": best["view"], "stamp": round(a, 3), "round": round(b, 3), "contrast": round(abs(a - b), 3)}
    for man, st in result["stamps"].items():
        for stamp, by in st.items():
            by["lights_over_goal"] = sum(1 for l in lights if l in by and by[l]["contrast"] >= GOAL)
    # MediaPipe on each man's square of the picture.
    import align
    ids = rec["ids"]
    for light in lights:
        for view in ("front", "three_quarter"):
            img = Image.open(os.path.join(d, "%s_%s.png" % (light, view))).convert("RGB")
            for i, man in enumerate(ids):
                crop = img.crop((i * 500, 0, i * 500 + 500, 500)).resize((1000, 1000), Image.LANCZOS)
                pts = align.face_points(crop, list(range(478)))
                entry = {"found": pts is not None}
                # Where it puts his nose tip and his mouth's corners against where they are (mm).
                if pts is not None:
                    mm = 0.42 / 500 * 1000 / 2.0                    # a pixel of the 2x crop, in mm
                    for stamp, lm in (("nose_tip", [1]), ("corner_r", [61, 291]), ("corner_l", [61, 291])):
                        mine = [p for p in rec["points"] if p["man"] == man and p["light"] == light
                                and p["view"] == view and p["stamp"] == stamp]
                        if mine:
                            x, y = mine[0]["at"][0]
                            x, y = (x - i * 500) * 2, y * 2
                            entry[stamp + "_mm"] = round(min(float(np.hypot(*(pts[k] - (x, y)))) for k in lm) * mm, 1) \
                                if stamp != "nose_tip" else round(float(np.hypot(*(pts[1] - (x, y)))) * mm, 1)
                result["landmarks"].setdefault(man, {})["%s_%s" % (light, view)] = entry
    json.dump(result, open(out, "w"), indent=1)
    for man, st in result["stamps"].items():
        print(man)
        for stamp, by in st.items():
            print("  %-16s %s  over %.2f in %d of 3  (%s)" % (stamp, "  ".join(
                "%s %.3f" % (l, by[l]["contrast"]) for l in lights if l in by), GOAL, by["lights_over_goal"],
                by.get("lamp", {}).get("view")))
    for man, found in result["landmarks"].items():
        print("%s: MediaPipe finds his face in %d of %d; %s" % (man, sum(f["found"] for f in found.values()), len(found),
              {k: {kk: vv for kk, vv in v.items() if kk != "found"} for k, v in found.items() if len(v) > 1}))


if __name__ == "__main__":
    main()
