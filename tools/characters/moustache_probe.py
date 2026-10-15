"""The moustache test, old against new (the fidelity investigation, task 4): which of a man's
vertices style_shape.relief would raise as moustache, drawn green on his paint through his front
portrait's camera. A lab tool; relief itself is unchanged.

    ~/bpyenv/bin/python tools/characters/moustache_probe.py --out=PNG [--men=bold_cowboy,older_heavyset_cowboy]

old: relief's test, "well darker than his skin, or much greyer", over the upper lip only (nose to
     the lips' parting, the mouth's width + 1.2 cm). It missed the older man's grey moustache:
     grey is lighter than his skin and not grey enough by its ratio, and it droops past the
     parting.
new: colour-independent, "differs from his skin": ΔE (Lab) from his cheeks' median over SKIN_DE,
     his lips (their landmark outline) left out; seeded over the upper lip as before, then grown
     across his surface (vertices welded across UV seams) into the corners beside his mouth, down
     to 3 cm under his lower lip and out to the mouth's width + 2.2 cm, only through vertices that
     pass the test.
"""
import json
import os
import sys

import numpy as np
import scipy.sparse as sp
from matplotlib.path import Path as MPath
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import portrait as P  # noqa: E402
import rodin_portrait as RP  # noqa: E402
import style_probe as S  # noqa: E402

LIPS = [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0, 37, 39, 40, 185]
SKIN_DE = 16.0


def welded_adjacency(V, T):
    """Vertex adjacency with vertices at one position (split by UV seams) joined."""
    _u, wi = np.unique(np.round(V / 1e-5).astype(np.int64), axis=0, return_inverse=True)
    wi = wi.ravel()
    Tw, nw = wi[T], wi.max() + 1
    e = np.r_[Tw[:, [0, 1]], Tw[:, [1, 2]], Tw[:, [2, 0]]]
    A = sp.coo_matrix((np.ones(len(e)), (e[:, 0], e[:, 1])), shape=(nw, nw)).tocsr()
    A = A + A.T
    S2 = sp.coo_matrix((np.ones(len(V)), (np.arange(len(V)), wi)), shape=(len(V), nw)).tocsr()
    return S2 @ A @ S2.T + S2 @ S2.T


def moustache(V, T, col, pts):
    """→ (old, new, seed region, grown region): vertex masks."""
    n = P.vertex_normals(V, T)
    front = n[:, 2] < -0.2
    eye_y = (pts[468, 1] + pts[473, 1]) / 2
    cheek = front & (V[:, 1] < eye_y - 0.015) & (V[:, 1] > pts[2, 1]) \
        & (np.abs(V[:, 0] - pts[1, 0]) > 0.025) & (np.abs(V[:, 0] - pts[1, 0]) < 0.05)
    lab = RP._lab(col)
    d_e = np.linalg.norm(lab - np.median(lab[cheek], 0), axis=1)
    lips = MPath(pts[LIPS][:, :2]).contains_points(V[:, :2]) & front
    mouth = np.linalg.norm(pts[61] - pts[291]) / 2
    mid = (pts[61] + pts[291]) / 2
    ax = np.abs(V[:, 0] - mid[0])
    region = front & (V[:, 1] < pts[2, 1] - 0.002) & (V[:, 1] > pts[13, 1]) & (ax < mouth + 0.012)
    w = np.array([0.2126, 0.7152, 0.0722])
    lum, sk = col @ w, np.median(col[cheek], 0)
    sat = col.max(1) - col.min(1)
    old = ((lum < 0.62 * (sk @ w)) | ((sat < 0.45 * (sk.max() - sk.min())) & (np.abs(lum - sk @ w) > 0.04))) & region
    ends = front & (V[:, 1] <= pts[13, 1]) & (V[:, 1] > pts[17, 1] - 0.03) & (ax > mouth - 0.004) & (ax < mouth + 0.022)
    ok = (d_e > SKIN_DE) & ~lips & (region | ends)
    new = ok & region
    A = welded_adjacency(V, T)
    for _ in range(80):
        g = (A @ new.astype(float) > 0) & ok & ~new
        if not g.any():
            break
        new |= g
    return old, new, region, region | ends


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    men = a.get("--men", "bold_cowboy,older_heavyset_cowboy").split(",")
    tiles = []
    for man in men:
        mesh = np.load(os.path.join(RP.WORK, man + "_mesh.npy"), allow_pickle=True).item()
        V, T, UV, pts = mesh["V"], mesh["T"], mesh["UV"], mesh["pts"]
        paint = np.asarray(Image.open(os.path.join(RP.WORK, man + "_paint.png")).convert("RGB")) / 255.0
        old, new, _r, _w = moustache(V, T, RP.sample_tex(paint, UV), pts)
        print("%s: old test %d vertices, new %d" % (man, old.sum(), new.sum()))
        rep = json.load(open(os.path.join(RP.WORK, man + "_report.json")))
        cam = P.PoseCamera.of(rep["cameras"]["front"])
        img, _hit = S.draw(V, T, UV, cam, 1672, 941, tex=paint)
        tid, bary, _ = P.rasterise(cam.project(V), cam.depth(V), T, 1672, 941)
        q = cam.project(pts[[13]])[0].astype(int)
        for m in (old, new):
            im = img.copy()
            h = tid >= 0
            mv = (m[T[tid[h]]] * bary[h]).sum(1)
            im[h] = im[h] * (1 - 0.6 * mv[:, None]) + np.array([0.1, 1.0, 0.2]) * 0.6 * mv[:, None]
            c = im[max(0, q[1] - 170):q[1] + 200, max(0, q[0] - 260):q[0] + 260]
            tiles.append(Image.fromarray((np.clip(c, 0, 1) * 255).astype(np.uint8)))
    sheet = Image.new("RGB", (sum(t.width for t in tiles) + 6 * len(tiles), max(t.height for t in tiles)))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0))
        x += t.width + 6
    sheet.thumbnail((1600, 400))
    sheet.save(a.get("--out", os.path.join(RP.WORK, "moustache_probe.png")))


if __name__ == "__main__":
    main()
