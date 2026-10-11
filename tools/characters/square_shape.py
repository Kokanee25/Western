"""How square, upright and even the seated man's squares are on screen (the characters session's
experiment E6, docs/screenshots/tripo/experiments/): the master's squares are near-square, upright
and one size on the screen's grid; ours lie on his surfaces and turn, stretch and shrink with them.

    python3 tools/characters/square_shape.py DIR [--boxes=name:x0,y0,x1,y1;...] [--out=FILE.json]

DIR holds tools/screenshots.gd --man-diag's id pass of the saloon shot
(shot_match_saloon_diag_id.png: each square of his texture its own colour). Each square seen whole
on screen (at least MIN_PX pixels, none of them beside his outline) is measured by the second
moments of its pixels: `aspect` (the long side over the short, 1 a square), `tilt` (degrees its
sides are turned off the screen's rows and columns, 0-45), `size` (the side of a square of its
area, pixels). Printed and written as medians and 90th percentiles over all of him and per box.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

VIEW = "shot_match_saloon"
MIN_PX = 12


def measure(d, boxes):
    ids = np.asarray(Image.open(os.path.join(d, VIEW + "_diag_id.png")).convert("RGB")).astype(np.int64)
    man = ids.sum(axis=2) > 30
    key = np.where(man, (ids[..., 0] << 16) | (ids[..., 1] << 8) | ids[..., 2], -1)
    # Pixels beside his outline: a square cut by it isn't seen whole.
    edge = np.zeros_like(man)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        edge |= man & ~np.roll(man, (dy, dx), axis=(0, 1))
    ys, xs = np.nonzero(man)
    k = key[ys, xs]
    uk, inv = np.unique(k, return_inverse=True)
    n = np.bincount(inv)
    cut = np.bincount(inv, edge[ys, xs].astype(np.float64)) > 0
    mx, my = np.bincount(inv, xs) / n, np.bincount(inv, ys) / n
    dx, dy = xs - mx[inv], ys - my[inv]
    sxx, syy, sxy = (np.bincount(inv, v) / n for v in (dx * dx, dy * dy, dx * dy))
    tr, det = sxx + syy, sxx * syy - sxy * sxy
    disc = np.sqrt(np.maximum(tr * tr / 4 - det, 0.0))
    l1, l2 = tr / 2 + disc, np.maximum(tr / 2 - disc, 1e-6)
    aspect = np.sqrt(l1 / l2)
    theta = np.degrees(0.5 * np.arctan2(2 * sxy, sxx - syy)) % 90.0
    tilt = np.minimum(theta, 90.0 - theta)
    # A near-square's principal axes are ill-defined: its tilt from the second moments is noise. For
    # those, the tilt of its outline instead: the angle of the line from its middle to its farthest
    # pixel (a corner), less 45 degrees.
    dist = dx * dx + dy * dy
    order = np.lexsort((dist, inv))
    last = np.cumsum(n) - 1
    fx, fy = dx[order[last]], dy[order[last]]
    corner = (np.degrees(np.arctan2(fy, fx)) - 45.0) % 90.0
    corner = np.minimum(corner, 90.0 - corner)
    tilt = np.where(aspect < 1.25, corner, tilt)
    size = np.sqrt(n)
    whole = (n >= MIN_PX) & ~cut

    def stats(sel):
        if not sel.any():
            return None
        return {"squares": int(sel.sum()),
                "aspect_median": round(float(np.median(aspect[sel])), 3),
                "aspect_p90": round(float(np.percentile(aspect[sel], 90)), 3),
                "tilt_median": round(float(np.median(tilt[sel])), 2),
                "tilt_p90": round(float(np.percentile(tilt[sel], 90)), 2),
                "size_median": round(float(np.median(size[sel])), 2),
                "size_spread": round(float(np.percentile(size[sel], 90) / max(np.percentile(size[sel], 10), 1e-6)), 3)}

    out = {"all": stats(whole)}
    for name, (x0, y0, x1, y1) in boxes.items():
        inb = (mx >= x0) & (mx < x1) & (my >= y0) & (my < y1)
        out[name] = stats(whole & inb)
    return out


BOXES = {"face": (403, 218, 594, 423), "cheek": (432, 285, 500, 340), "collar": (418, 353, 542, 426),
         "coat": (400, 322, 483, 422), "hat": (412, 215, 584, 268)}


def main():
    d = sys.argv[1]
    boxes, out = dict(BOXES), None
    for a in sys.argv[2:]:
        if a.startswith("--boxes="):
            boxes = {}
            for part in a.split("=", 1)[1].split(";"):
                name, nums = part.split(":")
                boxes[name] = tuple(int(v) for v in nums.split(","))
        elif a.startswith("--out="):
            out = a.split("=", 1)[1]
    res = measure(d, boxes)
    for name, st in res.items():
        if st:
            print("%-7s %4d squares  aspect %.2f (p90 %.2f)  tilt %4.1f° (p90 %4.1f°)  size %.1f px (p90/p10 %.2f)"
                  % (name, st["squares"], st["aspect_median"], st["aspect_p90"], st["tilt_median"], st["tilt_p90"],
                     st["size_median"], st["size_spread"]))
    if out:
        json.dump(res, open(out, "w"), indent=1)


if __name__ == "__main__":
    main()
