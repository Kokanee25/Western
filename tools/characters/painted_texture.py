"""The painted texture experiment (docs/briefs/character-art-convergence.md, phase 2): a man's
head texture with its light painted in, the same all round his head.

    ~/bpyenv/bin/python tools/characters/painted_texture.py --man=bold_cowboy [--out=PNG] [--k=V ...]

From rodin_portrait.py's paint and mesh (build/rodin_portrait/<man>_paint.png, _mesh.npy):

1. His colours, de-lit all the way: what light is left in the paint (60 % was taken out) fitted
   to his surface's normals and divided out, so only his colours stay.
2. A painted light laid back on, from his shape alone, so no portrait's light makes a seam: one
   key from the portraits' lamp (KEY: in front of him, to his right, above), wrapped a little;
   his hollows darker (OCCLUSION: how much of the sky round him each point sees, from ROUNDS
   directions), so his sockets, under his nose and lip and cheekbones go dark.
3. The light in BANDS hard steps, each tinted (TINTS: warm in the light, brown in the shade).
4. Patches by anatomy (rodin_portrait.patch_squares, PATCH_M) and the colours snapped to the
   portraits' own palette (PALETTE colours, k-means of his five portraits' faces, Lab).
5. Stored at LOW_RES a side, to be read nearest.
→ build/rodin_portrait/<man>_painted.png (and _painted_light.png, the light alone, to check by).
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import portrait as P  # noqa: E402
import rodin_portrait as RP  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
KEY = (0.55, 0.45, -0.7)     # body space: his right (+X), up, in front (-Z)
WRAP = 0.25
OCCLUSION = 0.65             # how much the hollows darken (0 none, 1 to black where nothing is seen)
ROUNDS = 32                  # directions the occlusion is seen from
AMBIENT = 0.35               # the shade side's light against the key's
BANDS = [0.30, 0.52, 0.74, 0.9]  # where one band of light ends and the next begins
TINTS = [(0.40, 0.28, 0.21), (0.60, 0.46, 0.36), (0.84, 0.74, 0.64), (1.02, 0.93, 0.80), (1.16, 1.03, 0.86)]
PATCH_M = 0.003
PALETTE = 28
LOW_RES = 512


def texel_frame(V, T, UV, size):
    """Each texel's place on him and its normal (smooth over welded positions)."""
    n = P.vertex_normals(V, T)
    key = np.round(V / 1e-6).astype(np.int64)
    _u, inv = np.unique(key, axis=0, return_inverse=True)
    inv = inv.ravel()
    acc = np.zeros((inv.max() + 1, 3))
    np.add.at(acc, inv, n)
    n = acc[inv] / np.maximum(np.linalg.norm(acc[inv], axis=1, keepdims=True), 1e-9)
    table = {tuple(t): [tuple(UV[i]) for i in t] for t in T}
    M, cover = P.raster_uv(table, [list(t) for t in T], np.concatenate([V, n], 1), size)
    Pp, N = M[..., :3], M[..., 3:]
    N /= np.maximum(np.linalg.norm(N, axis=-1, keepdims=True), 1e-9)
    return Pp, N, cover, n


def occlusion(V, T, points, normals, rounds=ROUNDS, res=384):
    """How much of the sky round him each point sees (1 all, 0 none): depth maps of him from
    `rounds` directions spread over the sphere; a point counts a direction it faces and is the
    nearest thing to, there."""
    rng = np.random.default_rng(3)
    dirs = rng.normal(size=(rounds * 3, 3))
    dirs /= np.linalg.norm(dirs, axis=1, keepdims=True)
    dirs = dirs[dirs[:, 1] > -0.4][:rounds]      # mostly from above and round him, as a room's light
    seen = np.zeros(len(points))
    count = np.zeros(len(points))
    centre = V.mean(0)
    for d in dirs:
        # An orthographic view looking along -d: two axes across it.
        a = np.cross(d, [0, 1, 0] if abs(d[1]) < 0.9 else [1, 0, 0])
        a /= np.linalg.norm(a)
        b = np.cross(d, a)
        span = np.ptp(V @ np.stack([a, b], 1), axis=0).max() * 1.05
        s = res / span

        def proj(p):
            q = (p - centre) @ np.stack([a, b], 1) * s + res / 2
            return q

        depth_v = -(V - centre) @ d
        _tid, _bary, zb = P.rasterise(proj(V), depth_v, T, res, res)
        q = proj(points)
        qi = np.clip(q.astype(int), 0, res - 1)
        zp = -(points - centre) @ d
        facing = normals @ d > 0.05
        vis = facing & (zp <= zb[qi[:, 1], qi[:, 0]] + 0.004)
        seen += vis * np.clip(normals @ d, 0, 1)
        count += np.clip(normals @ d, 0, 1)
    return np.clip(seen / np.maximum(count, 1e-6), 0, 1)


def palette_of(spec, k):
    """The portraits' face colours, k of them (k-means in Lab)."""
    from scipy.cluster.vq import kmeans2
    px = []
    for view, path in spec["paint_views"].items():
        img = Image.open(os.path.join(ROOT, path)).convert("RGB")
        lm = P.landmarks(img) if view != "back" else None
        a = np.asarray(img).astype(float) / 255
        if lm is not None:
            x0, y0 = lm[:, :2].min(0).astype(int)
            x1, y1 = lm[:, :2].max(0).astype(int)
            pad = int(0.25 * (x1 - x0))
            a = a[max(0, y0 - pad):y1 + pad, max(0, x0 - pad):x1 + pad]
        px.append(a.reshape(-1, 3)[::7])
    px = np.concatenate(px)
    lab = RP._lab(px)
    c, _ = kmeans2(lab, k, minit="++", seed=0)
    return c


def snap(colours, pal_lab):
    """Each colour the palette's nearest (Lab)."""
    from scipy.spatial import cKDTree
    lab = RP._lab(colours)
    _d, j = cKDTree(pal_lab).query(lab)
    return pal_lab[j]


def lab_to_rgb(lab):
    fy = (lab[:, 0] + 16) / 116
    fx = fy + lab[:, 1] / 500
    fz = fy - lab[:, 2] / 200
    f = np.stack([fx, fy, fz], 1)
    xyz = np.where(f ** 3 > 0.008856, f ** 3, (f - 16 / 116) / 7.787) * np.array([0.9505, 1.0, 1.089])
    M = np.array([[3.2406, -1.5372, -0.4986], [-0.9689, 1.8758, 0.0415], [0.0557, -0.2040, 1.0570]])
    c = xyz @ M.T
    return np.clip(np.where(c > 0.0031308, 1.055 * np.clip(c, 0, None) ** (1 / 2.4) - 0.055, 12.92 * c), 0, 1)


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    man = a.get("--man", "bold_cowboy")
    spec = json.load(open(os.path.join(ROOT, "assets", "people", "portrait.json")))["men"][man]
    mesh = np.load(os.path.join(RP.WORK, man + "_mesh.npy"), allow_pickle=True).item()
    V, T, UV, pts = mesh["V"], mesh["T"], mesh["UV"], mesh["pts"]
    paint = np.asarray(Image.open(os.path.join(RP.WORK, man + "_paint.png")).convert("RGB")).astype(float) / 255
    size = paint.shape[0]
    Pp, N, cover, n_v = texel_frame(V, T, UV, size)
    idx = np.nonzero(cover)
    col, nrm, pos = paint[idx], N[idx], Pp[idx]
    # 1. De-lit all the way: the paint's leftover light, fitted to the normals, divided out.
    lum = col @ np.array([0.2126, 0.7152, 0.0722])
    A = np.c_[np.ones(len(nrm)), nrm]
    coef = np.linalg.lstsq(A, lum, rcond=None)[0]
    shade = np.clip(A @ coef / max(float(np.median(A @ coef)), 1e-6), 0.6, 1.6)
    albedo = np.clip(col / shade[:, None], 0, 1)
    # 2. The painted light: the key, wrapped, and the hollows.
    L = np.array(KEY, float)
    L /= np.linalg.norm(L)
    key = np.clip((nrm @ L + WRAP) / (1 + WRAP), 0, 1)
    print("painted_texture: occlusion from", ROUNDS, "directions")
    occ = occlusion(V, T, pos[::1], nrm)
    light = (AMBIENT + (1 - AMBIENT) * key) * (1 - OCCLUSION * (1 - occ))
    light = np.clip(light / max(float(np.percentile(light, 97)), 1e-6), 0, 1)
    # 3. Bands, each tinted.
    band = np.searchsorted(np.array(BANDS), light)
    tinted = albedo * np.array(TINTS)[band] * 1.25
    tex = paint.copy()
    tex[idx] = np.clip(tinted, 0, 1)
    lt = np.zeros_like(paint)
    lt[idx] = np.array(TINTS)[band] / 1.2
    P.to_pil(np.clip(lt, 0, 1)).save(os.path.join(RP.WORK, man + "_painted_light.png"))
    # 4. Patches by anatomy, then the portraits' palette.
    sq, npatch = RP.patch_squares(tex, cover, Pp, PATCH_M, 12.0)
    pal = palette_of(spec, PALETTE)
    sq[idx] = lab_to_rgb(snap(sq[idx], pal))
    # 5. Low resolution, nearest (each LOW_RES texel the colour at its middle).
    step = size // LOW_RES
    low = sq[step // 2::step, step // 2::step]
    out = a.get("--out", os.path.join(RP.WORK, man + "_painted.png"))
    P.to_pil(low).save(out)
    print("painted_texture: wrote", out, low.shape, "patches", npatch, "palette", PALETTE)
    P.close_landmarker()


if __name__ == "__main__":
    main()
