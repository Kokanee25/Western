"""A base body painted from its four full-figure paintings (docs/briefs/layered-people.md), as
rodin_portrait.py paints a head from its portraits.

    ~/bpyenv/bin/python tools/characters/body_paint.py --body=bold_cowboy_body \\
        --views=front:PATH,left:PATH,right:PATH,back:PATH [--unsquare=9]
    then tools/blender/fit_tripo.py --only=<body> (it takes assets/people/tripo/<body>_color.png)
    --dressed: a dressed twin (--body=<man>_vest_dressed) painted from its own pictures, every
    picture painting what it sees; tools/characters/twin_pieces.py --painted writes its garments
    with that paint. Dressed, too (2026-10-17, the flecks at his sleeves' edges): the figure's
    outermost BG_ERODE pixels are never sampled (they blend into the backdrop), a picture colour
    within BG_DE of the backdrop's is the backdrop (its grey is as light as the shirt rule allows),
    and what no picture sees is filled from its own UV island (the nearest painted texel of any
    island put a sleeve's edge, or the vest's brown, inside the sleeve). The base body's paint is
    left as approved (the man's face is matched to it).

- Each painting is lined up with his Rodin body (assets/people/tripo/test/<body>_rodin.glb) by
  outline: an orthographic view from the side the painting shows (front: from in front of him,
  "left": facing the picture's left, so his left side), scaled and moved so his outline's height
  and middle match the figure's in the painting (the figure: what isn't the plain backdrop).
- The paintings' own squares are taken out first (a median over `unsquare` pixels, a little blur).
- Each texel of his body's texture takes its colour from the painting facing it squarest that
  sees it (depth-tested, and inside that painting's figure), feathered between views; what none
  sees takes the nearest painted texel's colour. A side picture paints only texels of its own
  kind (skin or cloth: his arms skin, between his shorts' waistband and hem cloth, elsewhere as
  the front or back picture shows): the pictures' arms hang against his shorts, where Rodin's
  are held out.
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
DRESSED_LIGHT = 0.42   # --dressed: luma (0-1) parting light texels (shirt, skin) from dark (waistcoat, trousers, tie)
SEAM = 0.08            # facing difference over which two views blend
MIN_FACING = 0.15
BG_TOL = 0.09
# Skin or cloth: his cream shorts' blue is ~half their red (0.41-0.61 in his pictures), his skin's,
# lit or shadowed, a third or less (0.17-0.34).
CLOTH_BR = 0.38
CLOTH_RED = 0.35       # and light (his dark hair and the shadow between his legs are bluish too)
CLOTH_BR_MAX = 0.75    # and warmer than the grey backdrop (blue as much as red)
# Of his height off his middle: past this, his arms (Rodin holds them well out from his shorts).
ARM_OUT = 0.15
SHORTS_MID = 0.05      # of his height either side of his middle: where his shorts' band is read
SHORTS_INSET = 0.008   # of his height in from the waistband and hem (~1.5 cm)
BG_ERODE = 2           # --dressed: pixels in from the figure's edge never sampled (the outermost ring is half backdrop)
BG_DE = 12.0           # --dressed: Lab distance from the backdrop's colour within which a picture colour is backdrop


def cloth_like(c):
    br = c[..., 2] / np.maximum(c[..., 0], 1e-6)
    return (br > CLOTH_BR) & (br < CLOTH_BR_MAX) & (c[..., 0] > CLOTH_RED)


def backdrop(img):
    """The plain backdrop's colour, from the picture's edges."""
    edge = np.concatenate([img[:20].reshape(-1, 3), img[-20:].reshape(-1, 3), img[:, :20].reshape(-1, 3)])
    return np.median(edge, 0)


def _lab(rgb):
    c = np.where(rgb > 0.04045, ((rgb + 0.055) / 1.055) ** 2.4, rgb / 12.92)
    M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ M.T / np.array([0.9505, 1.0, 1.089])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def island_fill(tex, have, cover):
    """Unpainted texels (`cover` and not `have`) filled from the nearest painted texel of their own
    UV island (a connected patch of `cover`); an island with no painted texel, and what lies
    outside every island, from the nearest painted texel anywhere."""
    from scipy import ndimage
    _d, (iy, ix) = ndimage.distance_transform_edt(~have, return_indices=True)
    lbl, n = ndimage.label(cover)
    wrong = cover & ~have & (lbl[iy, ix] != lbl)
    fixed = 0
    for c in np.unique(lbl[wrong]):
        ys, xs = np.nonzero(lbl == c)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        own = (lbl[y0:y1, x0:x1] == c) & have[y0:y1, x0:x1]
        if not own.any():
            continue
        _d2, (jy, jx) = ndimage.distance_transform_edt(~own, return_indices=True)
        sel = wrong[y0:y1, x0:x1]
        iy[y0:y1, x0:x1][sel] = jy[sel] + y0
        ix[y0:y1, x0:x1][sel] = jx[sel] + x0
        fixed += int(sel.sum())
    print("body_paint: %d unpainted texels filled from their own island (of %d unpainted)" % (fixed, int((cover & ~have).sum())))
    return tex[iy, ix]


def figure_mask(img):
    """What isn't the plain backdrop (its colour from the picture's edges)."""
    from scipy import ndimage
    bg = backdrop(img)
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
    pics, cams, masks, bgs, samp = {}, {}, {}, {}, {}
    dressed = "--dressed" in sys.argv
    for view, path in views.items():
        raw = Image.open(os.path.join(ROOT, path)).convert("RGB")
        masks[view] = figure_mask(np.asarray(raw).astype(float) / 255)
        bgs[view] = backdrop(np.asarray(raw).astype(float) / 255)
        from scipy import ndimage as _nd
        samp[view] = _nd.binary_erosion(masks[view], iterations=BG_ERODE) if dressed else masks[view]
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
    SEEN = np.zeros((len(names), len(p)), bool)
    for k, view in enumerate(names):
        cam, img, mask = cams[view], pics[view], masks[view]
        h, w = mask.shape
        _tid, _b, zb = P.rasterise(cam.project(V), cam.depth(V), T, w, h)
        q = cam.project(p)
        qi = np.clip(q.astype(int), 0, [w - 1, h - 1])
        seen = (cam.depth(p) <= zb[qi[:, 1], qi[:, 0]] + 0.01) & samp[view][qi[:, 1], qi[:, 0]]
        f = n @ cam.toward_v
        S[k] = np.where(seen & (f > MIN_FACING), f, -np.inf)
        C[k] = P.sample(img, q[:, 0], q[:, 1])
        SEEN[k] = seen & (f > 0)
    # The side pictures hang his arms against his shorts, where Rodin's body holds them out: from
    # the side his hand was painted on his hip (Sean: "looks like there's more than one hand")
    # and his shorts on his forearm. What each texel is, skin or cloth: his arms skin; the rest as
    # the front or back picture (whichever faces it squarer) shows it. No picture's colour of the
    # other kind is taken there (another's, or a neighbour's, is).
    height = float(V[:, 1].max() - V[:, 1].min())
    arm = np.abs(p[:, 0] - np.median(V[:, 0])) > ARM_OUT * height
    fb = [k for k, v in enumerate(names) if v in ("front", "back")]
    kind = np.full(len(p), -1)
    if fb:
        f_fb = np.array([np.where(SEEN[k], n @ cams[names[k]].toward_v, -np.inf) for k in fb])
        pick = np.argmax(f_fb, 0)
        known = np.isfinite(f_fb.max(0))
        kc = cloth_like(np.array([C[fb[j]][i] for i, j in enumerate(pick)])) if len(p) else np.zeros(0, bool)
        kind = np.where(known, kc.astype(int), -1)
    # Between his shorts' waistband and hem (where his middle shows cloth, front or back), all
    # but his arms is cloth: the front picture's hands hang by his shorts too.
    mid = (np.abs(p[:, 0] - np.median(V[:, 0])) < SHORTS_MID * height) & (kind >= 0)
    edges = np.arange(V[:, 1].min(), V[:, 1].max() + 0.02, 0.02)
    n_all, _e = np.histogram(p[mid, 1], edges)
    n_cloth, _e = np.histogram(p[mid & (kind == 1), 1], edges)
    share = n_cloth / np.maximum(n_all, 1)
    if n_cloth.max() > 100:
        # The one run of mostly-cloth rows round the clothiest row.
        a = b = int(np.argmax(n_cloth))
        while a > 0 and share[a - 1] > 0.5:
            a -= 1
        while b < len(share) - 1 and share[b + 1] > 0.5:
            b += 1
        lo, hi = edges[a], edges[b + 1]
        kind[(p[:, 1] > lo + SHORTS_INSET * height) & (p[:, 1] < hi - SHORTS_INSET * height)] = 1
        print("body_paint: his shorts from %.2f to %.2f m (of %.2f to %.2f)" % (lo, hi, V[:, 1].min(), V[:, 1].max()))
    kind[arm] = 0
    dressed_light = None
    if "--dressed" in sys.argv:
        # A dressed twin (Rodin's man made from these same pictures, stood as they show him): no
        # skin-or-shorts rule. Each texel takes only picture colour as light or as dark as Rodin
        # painted it there (his shirt and skin light; his waistcoat, trousers and tie dark): where
        # the outlines are a little off, the waistcoat's brown fell on his sleeves' edges and the
        # backdrop on his trousers.
        kind[:] = -1
        lum = lambda c: c @ np.array([0.299, 0.587, 0.114])
        dressed_light = lum(own[idx][:, :3].astype(float) / (255.0 if own.max() > 1.5 else 1.0)) >= DRESSED_LIGHT
    rejected = 0
    for k, view in enumerate(names):
        grey = C[k][:, 2] >= CLOTH_BR_MAX * np.maximum(C[k][:, 0], 1e-6)   # the backdrop, between arm and body
        if dressed:
            # His white shirt is as blue as red too: the backdrop is what is near its own colour.
            grey = np.linalg.norm(_lab(C[k]) - _lab(bgs[view][None])[0], axis=1) < BG_DE
        wrong = (((kind >= 0) & (cloth_like(C[k]).astype(int) != kind)) | grey) & np.isfinite(S[k])
        if dressed_light is not None:
            wrong |= ((C[k] @ np.array([0.299, 0.587, 0.114]) >= DRESSED_LIGHT) != dressed_light) & np.isfinite(S[k])
        S[k][wrong] = -np.inf
        rejected += int(wrong.sum())
    if os.environ.get("BODY_PAINT_DEBUG"):
        np.savez(os.path.join(WORK, "debug.npz"), p=p, n=n, kind=kind, S=S, C=C, SEEN=SEEN, names=np.array(names))
    print("body_paint: %d picture texels of the other kind (skin on cloth, cloth on skin) left out" % rejected)
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
    if dressed:
        tex = island_fill(tex, have, cover)
    else:
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
