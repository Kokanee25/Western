"""Does one of the seated man's squares take two tones of light? (the characters session's crispness
experiments, docs/screenshots/tripo/experiments/).

    python3 tools/characters/square_split.py DIR [--lit=lit|litfix] [--boxes=name:x0,y0,x1,y1;...]
        [--out=DIR2]

DIR holds tools/screenshots.gd --man-diag's passes of the saloon shot: shot_match_saloon_diag_id.png
(each square of his texture its own colour), _diag_wire.png (his triangles' edges) and
_diag_lit.png (his albedo grey: the light alone). Within each square seen on screen (the pixels of
one id colour), the spread of the light (L*, the 90th percentile less the 10th) should be ~0: the
game lights a square at its centre, as one. A square whose spread passes SPLIT_L takes more than
one tone. Its tone edges (neighbouring pixels of the same square more than EDGE_L apart) are
checked against the triangle edges: the share within a pixel of a wireframe line, against the
share of all his pixels within a pixel of one (chance).

Writes DIR2/split_overlay.png (the light alone, square edges cyan, triangle edges magenta, split
squares tinted red, their tone edges yellow), a crop at 4x per box, and split.json.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

SPLIT_L = 2.0
EDGE_L = 1.5
VIEW = "shot_match_saloon"


def lstar(rgb):
    c = rgb / 255.0
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    y = lin @ np.array([0.2126, 0.7152, 0.0722])
    return np.where(y > 216 / 24389, 116 * np.cbrt(y) - 16, y * 24389 / 27)


def near(mask, r=1):
    out = mask.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            out |= np.roll(mask, (dy, dx), axis=(0, 1))
    return out


def analyse(d, lit_pass, boxes, out):
    ids = np.asarray(Image.open(os.path.join(d, VIEW + "_diag_id.png")).convert("RGB")).astype(np.int64)
    lit = lstar(np.asarray(Image.open(os.path.join(d, VIEW + "_diag_%s.png" % lit_pass)).convert("RGB")).astype(np.float64))
    man = ids.sum(axis=2) > 30
    wire_path = os.path.join(d, VIEW + "_diag_wire.png")
    wire = np.zeros_like(man)
    if os.path.exists(wire_path):
        wire = (np.asarray(Image.open(wire_path).convert("RGB")).max(axis=2) > 40) & man
    key = (ids[..., 0] << 16) | (ids[..., 1] << 8) | ids[..., 2]
    key = np.where(man, key, -1)
    flat = key.ravel()
    sel = flat >= 0
    uk, inv = np.unique(flat[sel], return_inverse=True)
    L = lit.ravel()[sel]
    n = np.bincount(inv)
    # Per square: the 10th and 90th percentiles of its light.
    order = np.lexsort((L, inv))
    start = np.concatenate([[0], np.cumsum(n)[:-1]])
    p10 = L[order[start + (n * 0.1).astype(int)]]
    p90 = L[order[start + np.minimum((n * 0.9).astype(int), n - 1)]]
    spread = p90 - p10
    big = n >= 9
    split_sq = big & (spread > SPLIT_L)
    split_px = np.zeros(flat.shape, dtype=bool)
    split_px[np.nonzero(sel)[0]] = split_sq[inv]
    split_px = split_px.reshape(key.shape)
    # Tone edges inside a square, and square edges.
    tone = np.zeros_like(man)
    sq_edge = np.zeros_like(man)
    for dy, dx in ((0, 1), (1, 0)):
        k2 = np.roll(key, (-dy, -dx), axis=(0, 1))
        l2 = np.roll(lit, (-dy, -dx), axis=(0, 1))
        same = (k2 == key) & man
        tone |= same & (np.abs(l2 - lit) > EDGE_L)
        sq_edge |= man & (k2 != key) & (k2 >= 0)
    tone_in_split = tone & split_px
    wire_near = near(wire, 1)
    stats = {"squares_seen": int(big.sum()), "split_squares": int(split_sq.sum()),
             "split_share": round(float(split_sq.sum() / max(big.sum(), 1)), 4),
             "split_pixels_share": round(float(split_px.sum() / max(man.sum(), 1)), 4),
             "tone_edges_on_triangle_edges": round(float((tone_in_split & wire_near).sum() / max(tone_in_split.sum(), 1)), 4),
             "chance_of_a_pixel_on_a_triangle_edge": round(float((man & wire_near).sum() / max(man.sum(), 1)), 4),
             "median_spread_L": round(float(np.median(spread[big])), 3),
             "mean_spread_L": round(float(np.mean(spread[big])), 3)}
    region = {}
    for name, (x0, y0, x1, y1) in boxes.items():
        m = np.zeros_like(man)
        m[y0:y1, x0:x1] = True
        m &= man
        ksel = np.unique(key[m & (key >= 0)])
        idx = np.searchsorted(uk, ksel)
        b = big[idx]
        region[name] = {"squares": int(b.sum()), "split": int((split_sq[idx] & b).sum()),
                        "split_share": round(float((split_sq[idx] & b).sum() / max(b.sum(), 1)), 4),
                        "median_spread_L": round(float(np.median(spread[idx][b])), 3) if b.any() else None,
                        "tone_edges_on_triangle_edges": round(float((tone_in_split & wire_near & m).sum()
                                                                    / max((tone_in_split & m).sum(), 1)), 4),
                        "chance": round(float((m & wire_near).sum() / max(m.sum(), 1)), 4)}
    stats["regions"] = region
    # The overlay.
    g = np.clip(lit / 100.0 * 255, 0, 255)
    img = np.stack([g, g, g], axis=2)
    img[split_px] = img[split_px] * 0.6 + np.array([255, 40, 40]) * 0.4
    img[sq_edge] = [0, 200, 220]
    img[wire] = [230, 0, 200]
    img[tone_in_split] = [255, 230, 0]
    img[~man] *= 0.25
    os.makedirs(out, exist_ok=True)
    tag = "" if lit_pass == "lit" else "_" + lit_pass
    ov = Image.fromarray(img.astype(np.uint8))
    ov.save(os.path.join(out, "split_overlay%s.png" % tag))
    for name, (x0, y0, x1, y1) in boxes.items():
        for what, im in (("overlay", ov), ("lit", Image.open(os.path.join(d, VIEW + "_diag_%s.png" % lit_pass))),
                         ("beauty", Image.open(os.path.join(d, VIEW + ".png")))):
            c = im.crop((x0, y0, x1, y1))
            c.resize((c.width * 4, c.height * 4), Image.NEAREST).save(os.path.join(out, "%s_%s%s.png" % (name, what, tag)))
    json.dump(stats, open(os.path.join(out, "split%s.json" % tag), "w"), indent=1)
    print(json.dumps(stats, indent=1))


def main():
    args = sys.argv[1:]
    d = args[0]
    lit_pass = "lit"
    out = d
    boxes = {}
    for a in args[1:]:
        if a.startswith("--lit="):
            lit_pass = a.split("=", 1)[1]
        elif a.startswith("--out="):
            out = a.split("=", 1)[1]
        elif a.startswith("--boxes="):
            for part in a.split("=", 1)[1].split(";"):
                name, nums = part.split(":")
                boxes[name] = tuple(int(v) for v in nums.split(","))
    analyse(d, lit_pass, boxes, out)


if __name__ == "__main__":
    main()
