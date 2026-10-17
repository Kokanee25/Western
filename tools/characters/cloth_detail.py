"""How much of his pictures' fine detail each step of his clothes' texture keeps (the layered man,
LAYERED.md): the painted twin texture at each stage re-projected into a picture's own frame, so
the picture and every stage are compared pixel for pixel, and a render of him laid over the same
frame for what the light and the mesh add.

    ~/bpyenv/bin/python tools/characters/cloth_detail.py --dressed=bold_cowboy_vest_dressed \\
        --picture=docs/concept/style/factory/bold_cowboy_vest_dressed/front.png [--view=front] \\
        [--render=build/l/game_neutral_0.png] [--out=build/cloth_detail] [--square=2] [--median=3]
        [--tex=PATH.png]

Stages (the chain as twin_pieces.write_piece and fit_tripo.paint_cloth/squares run it):
  picture → painted (body_paint's <dressed>_color.png, 4096) → resized (write_piece, TEX 2048,
  bicubic) → median (paint_cloth, CLOTH_MEDIAN) → squares (fit_tripo SQUARE_TEXELS, 1024).
For each garment (shirt, vest, trousers, told by Rodin's colours as twin_pieces tells them) and
each stage: the texel's size on him (mm), the mean edge strength (Sobel of lightness, as a share
of the picture's), and the lightness contrast (RMS) in bands of 1, 2, 4, 8, 16 and 32 picture
pixels (~1.7 mm each on a 1254 px picture of a 1.85 m man), as shares of the picture's: under 1
is detail lost, over 1 is detail added (blotches). Writes <out>/<view>_stages.png (crops of the
chest, each stage beside the picture) and <out>/<view>.json.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(HERE)), "tools", "blender"))
import portrait as P  # noqa: E402
import rodin_portrait as RP  # noqa: E402
import body_paint as BP  # noqa: E402
import twin_pieces as TP  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
BANDS = [1, 2, 4, 8, 16, 32]
HEIGHT_M = 1.85


def garment_classes(own, UV, T):
    """Each triangle's garment as twin_pieces --split=layers first reads it (shirt 0, vest 1,
    trousers 2, -1 none), by Rodin's own colours; height rules as there."""
    tl = TP._lab(RP.sample_tex(own, UV[T].mean(1)))
    L, C = tl[:, 0], np.hypot(tl[:, 1], tl[:, 2])
    cls = np.full(len(T), -1)
    cls[(L >= 40) & (C < 20)] = 0
    cls[(L < 40) & (C >= 10)] = 1
    cls[(L < 40) & (C < 10)] = 2
    return cls


def luma(a):
    return a @ np.array([0.299, 0.587, 0.114])


def band_rms(lum, mask, bands):
    """RMS of the lightness in each band (a difference of Gaussians an octave wide) within mask."""
    out = {}
    prev = ndimage.gaussian_filter(lum, 0.5)
    for b in bands:
        cur = ndimage.gaussian_filter(lum, b)
        d = prev - cur
        out[b] = float(np.sqrt(np.mean(d[mask] ** 2)))
        prev = cur
    return out


def edge_strength(lum, mask):
    gx = ndimage.sobel(lum, axis=1)
    gy = ndimage.sobel(lum, axis=0)
    return float(np.mean(np.hypot(gx, gy)[mask]))


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    dressed = a["--dressed"]
    view = a.get("--view", "front")
    out = a.get("--out", os.path.join(ROOT, "build", "cloth_detail"))
    square = int(a.get("--square", 2))
    median = int(a.get("--median", 3))
    tex_size = int(a.get("--tex_size", TP.TEX))
    os.makedirs(out, exist_ok=True)
    V, T, UV, own = RP.load_glb(os.path.join(ROOT, "assets", "people", "tripo", "test", dressed + "_rodin.glb"))
    V = RP.to_body(V)
    own_f = own[..., :3].astype(float) / (255.0 if own.max() > 1.5 else 1.0)
    raw = Image.open(os.path.join(ROOT, a["--picture"])).convert("RGB")
    pic = np.asarray(raw).astype(float) / 255
    mask = BP.figure_mask(pic)
    cam = BP.Ortho(*BP.VIEWS[view], V, mask)
    BP.refine(cam, V, T, mask)
    h, w = mask.shape
    print("cloth_detail: %s outline over the picture, %.0f px/m: %.2f mm a picture pixel" % (view, cam.s, 1000 * HEIGHT_M / cam.s))
    tid, bary, _zb = P.rasterise(cam.project(V), cam.depth(V), T, w, h)
    seen = tid >= 0
    # Each pixel's UV (its triangle's, by barycentrics) and garment.
    uvp = np.zeros((h, w, 2))
    ys, xs = np.nonzero(seen)
    tri = T[tid[ys, xs]]
    uvp[ys, xs] = (UV[tri] * bary[ys, xs][..., None]).sum(1)
    cls = garment_classes(own_f, UV, T)
    gar = np.full((h, w), -1)
    gar[ys, xs] = cls[tid[ys, xs]]
    # The stages.
    painted = Image.open(a.get("--tex", os.path.join(ROOT, "assets", "people", "tripo", dressed + "_color.png"))).convert("RGB")
    resized = painted.resize((tex_size, tex_size))
    med = resized.filter(ImageFilter.MedianFilter(median)) if median > 1 else resized
    sq = np.asarray(med, dtype=np.float64)
    hs = (sq.shape[0] // square) * square
    sq = sq[:hs, :hs].reshape(hs // square, square, hs // square, square, 3).mean(axis=(1, 3))
    squares = Image.fromarray(np.clip(sq, 0, 255).astype(np.uint8))
    stages = [("painted", painted), ("resized", resized), ("median", med), ("squares", squares)]

    def reproject(img):
        t = np.asarray(img).astype(float) / 255
        th, tw = t.shape[:2]
        o = np.zeros((h, w, 3))
        o[ys, xs] = t[np.clip((uvp[ys, xs, 1] * th).astype(int), 0, th - 1), np.clip((uvp[ys, xs, 0] * tw).astype(int), 0, tw - 1)]
        return o
    frames = [("picture", pic)] + [(n, reproject(im)) for n, im in stages]
    if a.get("--render"):
        # A render of him (the lab, near-orthographic: --fov=6 --dist=20) laid on the picture by his
        # figure's box: scaled and moved so the figure's height and middle match.
        r = np.asarray(Image.open(os.path.join(ROOT, a["--render"])).convert("RGB")).astype(float) / 255
        rm = BP.figure_mask(r)
        rys, rxs = np.nonzero(rm)
        pys, pxs = np.nonzero(seen)
        s = (pys.max() - pys.min()) / max(rys.max() - rys.min(), 1)
        rim = Image.fromarray((r * 255).astype(np.uint8)).resize((int(round(r.shape[1] * s)), int(round(r.shape[0] * s))), Image.LANCZOS)
        ra = np.asarray(rim).astype(float) / 255
        dx = int(round((pxs.min() + pxs.max()) / 2 - s * (rxs.min() + rxs.max()) / 2))
        dy = int(round(pys.min() - s * rys.min()))
        o = np.zeros((h, w, 3))
        y0, x0 = max(dy, 0), max(dx, 0)
        y1, x1 = min(dy + ra.shape[0], h), min(dx + ra.shape[1], w)
        o[y0:y1, x0:x1] = ra[y0 - dy:y1 - dy, x0 - dx:x1 - dx]
        frames.append(("render", o))
    # Texel sizes on him: each garment's 3D area over its UV area.
    report = {"view": view, "mm_per_picture_px": 1000 * HEIGHT_M / cam.s, "garments": {}}
    e1, e2 = V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]]
    a3 = 0.5 * np.linalg.norm(np.cross(e1, e2), axis=1)
    u1, u2 = UV[T[:, 1]] - UV[T[:, 0]], UV[T[:, 2]] - UV[T[:, 0]]
    a2 = 0.5 * np.abs(u1[:, 0] * u2[:, 1] - u1[:, 1] * u2[:, 0])
    names = {0: "shirt", 1: "vest", 2: "trousers"}
    lums = {n: luma(f) for n, f in frames}
    for k, name in names.items():
        sel = cls == k
        if sel.sum() < 10:
            continue
        m_per_uv = np.sqrt(a3[sel].sum() / max(a2[sel].sum(), 1e-9)) * HEIGHT_M   # metres of him per UV unit
        texel_mm = {n: 1000 * m_per_uv / im.size[0] for n, im in stages}
        region = ndimage.binary_erosion(gar == k, iterations=3)
        g = {"texel_mm": {n: round(v, 2) for n, v in texel_mm.items()}, "pixels": int(region.sum())}
        base_e = edge_strength(lums["picture"], region)
        base_b = band_rms(lums["picture"], region, BANDS)
        g["edge"] = {}
        g["bands_px"] = BANDS
        g["bands"] = {}
        for n, _f in frames:
            if n == "picture":
                continue
            g["edge"][n] = round(edge_strength(lums[n], region) / max(base_e, 1e-9), 3)
            bb = band_rms(lums[n], region, BANDS)
            g["bands"][n] = [round(bb[b] / max(base_b[b], 1e-9), 2) for b in BANDS]
        g["picture_bands_rms"] = [round(base_b[b], 4) for b in BANDS]
        report["garments"][name] = g
        print("cloth_detail: %-8s texel %s mm; edge %s; bands (x%s px) %s" % (
            name, g["texel_mm"], g["edge"], BANDS, g["bands"]))
    json.dump(report, open(os.path.join(out, view + ".json"), "w"), indent=1)
    # The sheet: a crop of his chest (the vest's middle) at each stage, 2x.
    vy, vx = np.nonzero(gar == 1)
    if len(vy):
        cy, cx = int(np.median(vy)), int(np.median(vx))
    else:
        cy, cx = h // 2, w // 2
    half = int(a.get("--crop", 150))
    tiles = []
    for n, f in frames:
        crop = f[max(cy - half, 0):cy + half, max(cx - half, 0):cx + half]
        im = Image.fromarray((np.clip(crop, 0, 1) * 255).astype(np.uint8)).resize((4 * half, 4 * half), Image.NEAREST)
        from PIL import ImageDraw
        ImageDraw.Draw(im).text((6, 4), n, fill=(255, 255, 0))
        tiles.append(im)
    sheet = Image.new("RGB", (sum(t.width for t in tiles), tiles[0].height))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0))
        x += t.width
    sheet.save(os.path.join(out, view + "_stages.png"))
    print("cloth_detail: wrote", os.path.join(out, view + "_stages.png"))


if __name__ == "__main__":
    main()
