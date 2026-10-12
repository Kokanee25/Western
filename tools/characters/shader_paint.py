"""The shader-paint trial (Sean's go, 2026-10-12): a man's look made by the shader, not baked into
his texture. His model's own colour (before any repaint) is kept as it is, and a palette of his
colours is taken from it; the trial shader (tools/characters/body_paint.gdshader, put on him by
tools/characters/shader_paint.gd) draws him in squares on his body, each square his colour there
pulled to the palette, a shade of its own, lit as one, the light in steps. So a man is his shape,
his model's colour and a palette, and every man is drawn by the same rules.

    python3 tools/characters/shader_paint.py --id=stranger2s [--colours=24] [--from=PNG]

Writes assets/people/<id>_sp_base.png (his model's colour, 2048 square, in his atlas's UVs),
assets/people/<id>_sp_palette.png (the palette, a row of texels) and <id>_sp.json (the colours
and their shares).
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
import head_paint as hp  # noqa: E402

PEOPLE = "assets/people"
SIZE = 2048
COLOURS = 24           # k-means clusters (Lab), before close ones are merged
MERGE_DE = 2.5         # clusters closer than this are one colour
SMOOTH = 1             # median radius on the base (photo grain out; the drawing kept)
SHARPEN = (6, 120, 2)  # unsharp mask (radius in texels, percent, threshold): brows, lids, the
                       # moustache's edge and the hat band stay bold through the squares' average


def coverage(uv, tris, size):
    tri_id, _ = hp.uv_raster(uv, tris, size)
    return tri_id >= 0


def kmeans(x, k, seed=5, iters=25, sample=30000):
    rng = np.random.default_rng(seed)
    pick = x[rng.choice(len(x), size=min(len(x), sample), replace=False)]
    # k-means++ starts, so a small colour (the shirt, the eyes' whites) gets one of its own.
    centres = [pick[rng.integers(len(pick))]]
    for _ in range(k - 1):
        d = np.min(((pick[:, None, :] - np.array(centres)[None]) ** 2).sum(axis=2), axis=1)
        centres.append(pick[rng.choice(len(pick), p=d / d.sum())])
    centres = np.array(centres)
    for _ in range(iters):
        lab = ((pick[:, None, :] - centres[None]) ** 2).sum(axis=2).argmin(axis=1)
        for j in range(k):
            if (lab == j).any():
                centres[j] = pick[lab == j].mean(axis=0)
    share = np.bincount(((pick[:, None, :] - centres[None]) ** 2).sum(axis=2).argmin(axis=1), minlength=k) / len(pick)
    return centres, share


def merge(centres, share):
    keep = []
    for i in np.argsort(-share):
        if all(np.linalg.norm(centres[i] - centres[j]) >= MERGE_DE for j in keep):
            keep.append(i)
    return centres[keep], share[keep]


def main():
    args = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in sys.argv[1:] if a.startswith("--"))
    cid = args.get("id", "stranger2s")
    colours = int(args.get("colours", COLOURS))
    report = json.load(open(os.path.join(PEOPLE, cid + ".json")))
    model = report.get("model", cid)
    _, _, uv, tris, colour = hp.load_glb(os.path.join(PEOPLE, "tripo", model + ".glb"))
    if args.get("from"):
        colour = Image.open(args["from"]).convert("RGB")
    base = colour.resize((SIZE, SIZE), Image.LANCZOS)
    if SMOOTH:
        base = base.filter(ImageFilter.MedianFilter(2 * SMOOTH + 1))
    if SHARPEN:
        base = base.filter(ImageFilter.UnsharpMask(*SHARPEN))
    base.save(os.path.join(PEOPLE, cid + "_sp_base.png"))
    small = 1024
    mask = coverage(uv, tris, small)
    px = np.asarray(base.resize((small, small), Image.BOX), dtype=np.float64)[mask]
    lab = hp._lab(px)
    centres, share = merge(*kmeans(lab, colours))
    order = np.argsort(centres[:, 0])
    centres, share = centres[order], share[order]
    rgb = np.clip(hp._rgb(centres), 0, 255).round().astype(np.uint8)
    Image.fromarray(rgb[None, :, :], "RGB").save(os.path.join(PEOPLE, cid + "_sp_palette.png"))
    json.dump({"id": cid, "from": model + ".glb", "colours": [
        {"rgb": [int(c) for c in r], "share": round(float(s), 4)} for r, s in zip(rgb, share)]},
        open(os.path.join(PEOPLE, cid + "_sp.json"), "w"), indent=1)
    print("%s: %d colours from %s" % (cid, len(rgb), model))


if __name__ == "__main__":
    main()
