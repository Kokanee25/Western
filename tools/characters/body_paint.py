"""A base body painted from its four full-figure paintings (docs/briefs/layered-people.md), as
rodin_portrait.py paints a head from its portraits.

    ~/bpyenv/bin/python tools/characters/body_paint.py --body=bold_cowboy_body \\
        --views=front:PATH,left:PATH,right:PATH,back:PATH [--unsquare=9]
    then tools/blender/fit_tripo.py --only=<body> (it takes assets/people/tripo/<body>_color.png)

- Each painting is lined up with his Rodin body (assets/people/tripo/test/<body>_rodin.glb) by
  outline: an orthographic view from the side the painting shows (front: from in front of him,
  "left": facing the picture's left, so his left side), scaled and moved so his outline's height
  and middle match the figure's in the painting (the figure: what isn't the plain backdrop).
- The paintings' own squares are taken out first (a median over `unsquare` pixels, a little blur).
- Each texel of his body's texture takes its colour from the painting facing it squarest that
  sees it (depth-tested, and inside that painting's figure), feathered between views; what none
  sees takes the nearest painted texel's colour.
→ assets/people/tripo/<body>_color.png (the fitter's repaint), build/body_paint/<body>_*.png
  (each view's outline over its painting, and which view painted each texel) to check by.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import portrait as P  # noqa: E402
import rodin_portrait as RP  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
WORK = os.path.join(ROOT, "build", "body_paint")
# Body space: Y up, facing -Z, his right +X. Per view, the picture's x axis and the direction
# towards the viewer (picture x × up).
VIEWS = {"front": (np.array([-1.0, 0, 0]), np.array([0, 0, -1.0])),
         "back": (np.array([1.0, 0, 0]), np.array([0, 0, 1.0])),
         "left": (np.array([0, 0, 1.0]), np.array([-1.0, 0, 0])),
         "right": (np.array([0, 0, -1.0]), np.array([1.0, 0, 0]))}
SEAM = 0.08            # facing difference over which two views blend
MIN_FACING = 0.15
BG_TOL = 0.09


def figure_mask(img):
    """What isn't the plain backdrop (its colour from the picture's edges)."""
    from scipy import ndimage
    edge = np.concatenate([img[:20].reshape(-1, 3), img[-20:].reshape(-1, 3), img[:, :20].reshape(-1, 3)])
    bg = np.median(edge, 0)
    m = np.linalg.norm(img - bg, axis=-1) > BG_TOL
    m = ndimage.binary_opening(m, iterations=2)
    lbl, n = ndimage.label(m)
    if n:
        sizes = ndimage.sum(m, lbl, range(1, n + 1))
        m = lbl == 1 + int(np.argmax(sizes))
    return ndimage.binary_fill_holes(m)


class Ortho:
    def __init__(self, xaxis, toward, V, mask):
        self.x, self.toward_v = xaxis, toward
        u = V @ xaxis
        v = -V[:, 1]
        ys, xs = np.nonzero(mask)
        self.s = (ys.max() - ys.min()) / (v.max() - v.min())
        self.ox = (xs.min() + xs.max()) / 2 - self.s * (u.min() + u.max()) / 2
        self.oy = ys.min() - self.s * v.min()

    def project(self, p):
        return np.stack([self.s * (p @ self.x) + self.ox, self.s * (-p[..., 1]) + self.oy], -1)

    def depth(self, p):
        return -(p @ self.toward_v)


def refine(cam, V, T, mask, rounds=3):
    """Scale and offset searched for the most overlap of his outline and the figure (at a quarter
    size): his A-pose arms and his hair can pull a plain bounding-box fit off."""
    sub = mask[::4, ::4]
    h, w = sub.shape

    from scipy import ndimage
    u, v = V @ cam.x, -V[:, 1]

    def iou(s, ox, oy):
        # His outline from his vertices splatted at a quarter size (dense enough, closed by a
        # dilation): milliseconds a try, where drawing his triangles took seconds.
        x = ((s * u + ox) / 4).astype(int)
        y = ((s * v + oy) / 4).astype(int)
        ok = (x >= 0) & (x < w) & (y >= 0) & (y < h)
        m = np.zeros((h, w), bool)
        m[y[ok], x[ok]] = True
        m = ndimage.binary_fill_holes(ndimage.binary_closing(m, iterations=2))
        return (m & sub).sum() / max((m | sub).sum(), 1)

    best = (iou(cam.s, cam.ox, cam.oy), cam.s, cam.ox, cam.oy)
    for step in (24.0, 8.0, 3.0)[:rounds]:
        _v, s0, x0, y0 = best
        for ds in (-0.04, -0.02, 0, 0.02, 0.04):
            for dx in (-step, 0, step):
                for dy in (-step, 0, step):
                    s1 = s0 * (1 + ds)
                    score = iou(s1, x0 + dx, y0 + dy)
                    if score > best[0]:
                        best = (score, s1, x0 + dx, y0 + dy)
    _v, cam.s, cam.ox, cam.oy = best


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    body = a["--body"]
    views = dict(kv.split(":", 1) for kv in a["--views"].split(","))
    uns = int(a.get("--unsquare", 9))
    os.makedirs(WORK, exist_ok=True)
    V, T, UV, own = RP.load_glb(os.path.join(ROOT, "assets", "people", "tripo", "test", body + "_rodin.glb"))
    V = RP.to_body(V)
    size = own.shape[0]
    pics, cams, masks = {}, {}, {}
    for view, path in views.items():
        raw = Image.open(os.path.join(ROOT, path)).convert("RGB")
        masks[view] = figure_mask(np.asarray(raw).astype(float) / 255)
        img = raw.filter(ImageFilter.MedianFilter(uns)).filter(ImageFilter.GaussianBlur(1.0)) if uns > 1 else raw
        pics[view] = np.asarray(img).astype(float) / 255
        cams[view] = Ortho(*VIEWS[view], V, masks[view])
        refine(cams[view], V, T, masks[view])
        # The check: his outline over the painting.
        h, w = masks[view].shape
        tid, _b, _z = P.rasterise(cams[view].project(V), cams[view].depth(V), T, w, h)
        mine = tid >= 0
        iou = (mine & masks[view]).sum() / max((mine | masks[view]).sum(), 1)
        chk = np.asarray(raw).astype(float) / 255
        edge = mine & ~np.roll(mine, 2, 0) | mine & ~np.roll(mine, 2, 1)
        chk[edge] = [0.1, 1.0, 0.3]
        Image.fromarray((chk * 255).astype(np.uint8)).resize((w // 2, h // 2)).save(os.path.join(WORK, "%s_%s_fit.png" % (body, view)))
        print("body_paint: %-5s outline overlap %.2f (scale %.0f px/m)" % (view, iou, cams[view].s))
    # His texels: where on him, which way they face.
    n_v = P.vertex_normals(V, T)
    table = {tuple(t): [tuple(UV[i]) for i in t] for t in T}
    print("body_paint: laying out %d triangles on a %d texture" % (len(T), size))
    M, cover = P.raster_uv(table, [list(t) for t in T], np.concatenate([V, n_v], 1), size)
    Pp, N = M[..., :3], M[..., 3:]
    N /= np.maximum(np.linalg.norm(N, axis=-1, keepdims=True), 1e-9)
    idx = np.nonzero(cover)
    p, n = Pp[idx], N[idx]
    names = list(views)
    S = np.full((len(names), len(p)), -np.inf)
    C = np.zeros((len(names), len(p), 3))
    for k, view in enumerate(names):
        cam, img, mask = cams[view], pics[view], masks[view]
        h, w = mask.shape
        _tid, _b, zb = P.rasterise(cam.project(V), cam.depth(V), T, w, h)
        q = cam.project(p)
        qi = np.clip(q.astype(int), 0, [w - 1, h - 1])
        seen = (cam.depth(p) <= zb[qi[:, 1], qi[:, 0]] + 0.01) & mask[qi[:, 1], qi[:, 0]]
        f = n @ cam.toward_v
        S[k] = np.where(seen & (f > MIN_FACING), f, -np.inf)
        C[k] = P.sample(img, q[:, 0], q[:, 1])
    best = S.max(0)
    ok = np.isfinite(best)
    Wt = np.where(np.isfinite(S), np.exp((S - np.where(ok, best, 0)[None]) / SEAM), 0.0)
    Wt /= np.maximum(Wt.sum(0, keepdims=True), 1e-9)
    col = (Wt[..., None] * C).sum(0)
    tex = np.zeros((size, size, 3))
    have = np.zeros((size, size), bool)
    tex[idx] = col
    have[idx] = ok
    from scipy import ndimage
    _d, (iy, ix) = ndimage.distance_transform_edt(~have, return_indices=True)
    tex = tex[iy, ix]
    which = np.zeros((size, size, 3))
    pal = np.array([[0.9, 0.3, 0.3], [0.3, 0.9, 0.3], [0.3, 0.3, 0.9], [0.9, 0.9, 0.3]])
    which[idx] = pal[np.argmax(S, 0) % 4] * np.where(ok, 1.0, 0.2)[:, None]
    P.to_pil(which).save(os.path.join(WORK, body + "_which_view.png"))
    out = os.path.join(ROOT, "assets", "people", "tripo", body + "_color.png")
    P.to_pil(np.clip(tex, 0, 1)).save(out)
    print("body_paint: wrote %s (painted %.0f%% of him, the rest from its neighbours)" % (out, 100 * ok.mean()))


if __name__ == "__main__":
    main()
