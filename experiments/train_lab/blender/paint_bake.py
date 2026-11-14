"""The train's paint baked onto its models (#577): Sean's pick E (the Studio's realistic working-dirty
repaint of `paint_views.py`'s clay layout, experiments/train_lab/paint/real_dirty.png) projected
from every orthographic panel back onto the engine's and tender's own UVs (engine.py unwraps every
node, moving ones too, into one atlas a car).

    ~/bpyenv/bin/python experiments/train_lab/blender/engine.py
    ~/bpyenv/bin/python experiments/train_lab/blender/paint_views.py build/train_paint --scale=2
    ~/bpyenv/bin/python experiments/train_lab/blender/paint_bake.py build/train_paint [--size=2048]

Out: assets/train/engine_paint.png, assets/train/tender_paint.png (the game lays them on with
`TrainModels.painted`), and in the layout dir `register.jpg` (each panel's clay outline over the
painting after registration), `coverage_<car>.png` (which panel each texel took most from) and
`bake.json` (the fits, the coverage).

How (the gun route, experiments/gun_lab/blender/guns_blender.py, from many views):
1. Each car's triangles from its glb at rest (Blender's frame: +Y the front, +Z up, +X its right),
   rasterised into its atlas: every texel's world point, its face's normal and its material.
2. Each panel's depth (a z-buffer of the same triangles in the panel's own orthographic view), so a
   texel only takes paint from a panel that sees it.
3. Each panel's registration: the painting keeps ~96% of the clay silhouette but not to the pixel,
   so the clay's mask is fitted to the painted silhouette (not the grey ground) by a scale and an
   offset on each axis, searched for the best overlap.
4. A texel's colour: the panels that see it, weighted by dot(normal, toward)^2, each sampled a
   little inside the part (along -normal), so a top or an end doesn't take the edge line of the
   side it borders. A texel no panel sees (inside the frames, the backs of the wheels) takes its
   material's mean colour from what the panels did see.
"""
import json
import math
import os
import sys

import bpy
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))


def arg(name, default):
    for a in sys.argv:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
    return default


DIR = os.path.abspath([a for a in sys.argv[1:] if not a.startswith("--")][-1])
SIZE = int(arg("size", "2048"))
PAINT = arg("paint", os.path.join(ROOT, "experiments", "train_lab", "paint", "real_dirty.png"))
ZS = 2  # the z-buffers' pixels a layout pixel
INSET = 0.012  # m: how far inside its part a texel's paint is taken
MIN_DOT = 0.12  # a panel seen this edge-on gives nothing
GROUND_TOL = 14  # the painting's ground: within this of grey 128 in every channel
MARGIN = 10  # texels the bake bleeds past each island (for the mipmaps)


# --- the models ---------------------------------------------------------------------------------

def load_car(path):
    """Every triangle of the glb at rest: world points (n, 3, 3), UVs (n, 3, 2), material names
    (n,), face normals (n, 3)."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    bpy.context.view_layer.update()
    P, UV, M, N = [], [], [], []
    for ob in bpy.data.objects:
        if ob.type != "MESH":
            continue
        me = ob.data
        me.calc_loop_triangles()
        nt = len(me.loop_triangles)
        if nt == 0:
            continue
        co = np.zeros(len(me.vertices) * 3, np.float64)
        me.vertices.foreach_get("co", co)
        co = co.reshape(-1, 3)
        mw = np.array(ob.matrix_world)
        co = co @ mw[:3, :3].T + mw[:3, 3]
        tv = np.zeros(nt * 3, np.int64)
        me.loop_triangles.foreach_get("vertices", tv)
        tl = np.zeros(nt * 3, np.int64)
        me.loop_triangles.foreach_get("loops", tl)
        mi = np.zeros(nt, np.int64)
        me.loop_triangles.foreach_get("material_index", mi)
        uvl = me.uv_layers.active
        if uvl is None:
            raise SystemExit("%s has no UVs: rebuild it with engine.py" % ob.name)
        uv = np.zeros(len(me.loops) * 2, np.float64)
        uvl.data.foreach_get("uv", uv)
        uv = uv.reshape(-1, 2)
        names = [(m.name.split(".")[0] if m else "iron") for m in me.materials] or ["iron"]
        pts = co[tv.reshape(-1, 3)]
        P.append(pts)
        UV.append(uv[tl.reshape(-1, 3)])
        M += [names[i] if i < len(names) else names[0] for i in mi]
        n = np.cross(pts[:, 1] - pts[:, 0], pts[:, 2] - pts[:, 0])
        N.append(n)
    P = np.concatenate(P)
    N = np.concatenate(N)
    ln = np.linalg.norm(N, axis=1)
    keep = ln > 1e-12
    N = N[keep] / ln[keep, None]
    return P[keep], np.concatenate(UV)[keep], np.array(M)[keep], N


def raster(tri2d, shape, values_cb):
    """Rasterises 2D triangles (n, 3, 2, pixel coordinates; centres at +0.5) into `shape`: calls
    values_cb(i, ys, xs, w) with the covered pixels and their barycentric weights (k, 3)."""
    h, w = shape
    for i in range(len(tri2d)):
        t = tri2d[i]
        x0 = max(int(math.floor(t[:, 0].min() - 0.5)), 0)
        x1 = min(int(math.ceil(t[:, 0].max() - 0.5)), w - 1)
        y0 = max(int(math.floor(t[:, 1].min() - 0.5)), 0)
        y1 = min(int(math.ceil(t[:, 1].max() - 0.5)), h - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        a, b, c = t
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-12:
            continue
        l0 = ((b[1] - c[1]) * (xs - c[0]) + (c[0] - b[0]) * (ys - c[1])) / den
        l1 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / den
        l2 = 1.0 - l0 - l1
        inside = (l0 >= -1e-6) & (l1 >= -1e-6) & (l2 >= -1e-6)
        if not inside.any():
            continue
        iy, ix = np.nonzero(inside)
        values_cb(i, iy + y0, ix + x0, np.stack([l0[inside], l1[inside], l2[inside]], axis=1))


def atlas_points(P, UV, M, N):
    """Every covered texel's world point, normal and material (the texel's own triangle)."""
    pos = np.full((SIZE, SIZE, 3), np.nan, np.float32)
    nrm = np.zeros((SIZE, SIZE, 3), np.float32)
    mat = np.full((SIZE, SIZE), -1, np.int32)
    names = sorted(set(M))
    mid = np.array([names.index(m) for m in M])
    # Blender's UV v runs up; the image's rows down.
    t2 = np.stack([UV[..., 0] * SIZE, (1.0 - UV[..., 1]) * SIZE], axis=-1)

    def put(i, ys, xs, w):
        pos[ys, xs] = w @ P[i]
        nrm[ys, xs] = N[i]
        mat[ys, xs] = mid[i]

    raster(t2, (SIZE, SIZE), put)
    return pos, nrm, mat, names


# --- the panels -------------------------------------------------------------------------------

def panel_frame(p):
    return (np.array(p["origin"]), np.array(p["right"]), np.array(p["down"]), np.array(p["toward"]),
            float(p["ppm"]))


def to_panel(p, X):
    """World points (..., 3) to the panel's layout pixels (..., 2) and their depth toward the camera."""
    o, r, d, t, ppm = panel_frame(p)
    rx, ry = p["rect"][0], p["rect"][1]
    q = X - o
    return np.stack([rx + (q @ r) * ppm, ry + (q @ d) * ppm], axis=-1), X @ t


def zbuffer(p, P):
    """The panel's depth (toward the camera: bigger is nearer), ZS pixels a layout pixel, over its rect."""
    x, y, w, h = p["rect"]
    zb = np.full((h * ZS, w * ZS), -np.inf, np.float32)
    px, dep = to_panel(p, P)
    t2 = (px - np.array([x, y])) * ZS

    def put(i, ys, xs, wts):
        z = wts @ dep[i]
        np.maximum.at(zb, (ys, xs), z.astype(np.float32))

    raster(t2, zb.shape, put)
    return zb


def painted_mask(paint_small):
    g = np.abs(paint_small.astype(np.int16) - 128)
    return (g > GROUND_TOL).any(axis=2)


def register(p, code, clay, painted):
    """The scale and offset on each axis (layout px -> layout px) that lays the panel's clay silhouette
    best on the painted one: a bbox fit, then a search for the most overlap (IoU)."""
    s = clay.shape[1] / 1920.0  # the masks' pixels a layout pixel
    x, y, w, h = p["rect"]
    pad = 12
    X0, Y0 = int((x - pad) * s), int((y - pad) * s)
    X1, Y1 = int((x + w + pad) * s), int((y + h + pad) * s)
    X0, Y0 = max(X0, 0), max(Y0, 0)
    X1, Y1 = min(X1, clay.shape[1]), min(Y1, clay.shape[0])
    cm = clay[Y0:Y1, X0:X1] == code
    pm = painted[Y0:Y1, X0:X1]
    # The painting's silhouette in this window: only what overlaps or touches the clay's (a
    # neighbouring panel's paint or a shadow on the ground left out by the overlap search).
    cy, cx = np.nonzero(cm)
    py, px = np.nonzero(pm)

    def bbox(ys, xs):
        return xs.min(), xs.max(), ys.min(), ys.max()

    cb = bbox(cy, cx)
    pb = bbox(py, px) if len(px) else cb
    ax = (pb[1] - pb[0]) / max(cb[1] - cb[0], 1)
    ay = (pb[3] - pb[2]) / max(cb[3] - cb[2], 1)
    bx = pb[0] - cb[0] * ax
    by = pb[2] - cb[2] * ay
    # A fit is clay window px -> painted window px: u' = a u + b. Start near 1 (a shadow can stretch
    # the bbox), keep the bbox's guess too, and search.
    hh, ww = cm.shape
    yy, xx = np.mgrid[0:hh, 0:ww]

    def iou(f):
        a_x, b_x, a_y, b_y = f
        # Each painted pixel back to the clay's window (the inverse map), nearest.
        u = np.round((xx - b_x) / a_x).astype(np.int64)
        v = np.round((yy - b_y) / a_y).astype(np.int64)
        ok = (u >= 0) & (u < ww) & (v >= 0) & (v < hh)
        warped = np.zeros_like(cm)
        warped[ok] = cm[v[ok], u[ok]]
        inter = (warped & pm).sum()
        return inter / max((warped | pm).sum(), 1)

    best = max([(1.0, 0.0, 1.0, 0.0), (ax, bx, ay, by)], key=iou)
    score = iou(best)
    steps = [(0.01, 3.0), (0.004, 1.0), (0.0015, 0.5)]
    for ds, db in steps:
        improved = True
        while improved:
            improved = False
            for k, dv in ((0, ds), (1, db), (2, ds), (3, db)):
                for sgn in (-1, 1):
                    f = list(best)
                    f[k] += sgn * dv
                    sc = iou(f)
                    if sc > score + 1e-5:
                        best, score, improved = tuple(f), sc, True
    a_x, b_x, a_y, b_y = best
    # In layout px: L' = a L + b' with the window's origin taken out.
    lx0, ly0 = X0 / s, Y0 / s
    fit = (a_x, (b_x / s) + lx0 - a_x * lx0, a_y, (b_y / s) + ly0 - a_y * ly0)
    return fit, score, iou((1.0, 0.0, 1.0, 0.0))


def bilinear(img, x, y):
    h, w = img.shape[:2]
    x = np.clip(x - 0.5, 0, w - 1.001)
    y = np.clip(y - 0.5, 0, h - 1.001)
    x0 = np.floor(x).astype(np.int64)
    y0 = np.floor(y).astype(np.int64)
    fx = (x - x0)[:, None]
    fy = (y - y0)[:, None]
    a = img[y0, x0] * (1 - fx) + img[y0, x0 + 1] * fx
    b = img[y0 + 1, x0] * (1 - fx) + img[y0 + 1, x0 + 1] * fx
    return a * (1 - fy) + b * fy


def dilate(img, filled, n):
    """Spreads the filled texels' colours n steps into the empty ones (the islands' margins)."""
    img = img.copy()
    filled = filled.copy()
    for _ in range(n):
        acc = np.zeros_like(img)
        cnt = np.zeros(filled.shape, np.float32)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)):
            sh = np.roll(np.roll(filled, dy, 0), dx, 1)
            acc += np.roll(np.roll(img, dy, 0), dx, 1) * sh[..., None]
            cnt += sh
        new = (~filled) & (cnt > 0)
        img[new] = acc[new] / cnt[new, None]
        filled |= new
    return img, filled


def bake_car(car, glb, layout, clay, painted, paint, sx, sy, fits, report):
    P, UV, M, N = load_car(glb)
    pos, nrm, mat, names = atlas_points(P, UV, M, N)
    covered = mat >= 0
    pts = pos[covered].astype(np.float64)
    ns = nrm[covered].astype(np.float64)
    acc = np.zeros((len(pts), 3))
    wsum = np.zeros(len(pts))
    best_w = np.zeros(len(pts))
    best_p = np.full(len(pts), -1)
    panels = [(i, p) for i, p in enumerate(layout["panels"]) if p.get("car") == car]
    for i, p in panels:
        t = np.array(p["toward"])
        c = ns @ t
        cand = c > MIN_DOT
        zb = zbuffer(p, P)
        px, dep = to_panel(p, pts[cand])
        x, y = p["rect"][0], p["rect"][1]
        zx = np.clip(((px[:, 0] - x) * ZS).astype(np.int64), 0, zb.shape[1] - 1)
        zy = np.clip(((px[:, 1] - y) * ZS).astype(np.int64), 0, zb.shape[0] - 1)
        cc = c[cand]
        # A depth test's slack: the pixel's own size along a slanted face, and a few cm.
        slack = 0.02 + (1.0 / (p["ppm"] * ZS)) * np.sqrt(np.maximum(1 - cc * cc, 0)) / np.maximum(cc, 0.1) * 1.5
        vis = dep >= zb[zy, zx] - np.minimum(slack, 0.12)
        idx = np.nonzero(cand)[0][vis]
        q = pts[idx] - ns[idx] * INSET
        qpx, _ = to_panel(p, q)
        a_x, b_x, a_y, b_y = fits[p["name"]]
        lx = a_x * qpx[:, 0] + b_x
        ly = a_y * qpx[:, 1] + b_y
        col = bilinear(paint, lx * sx, ly * sy)
        w = cc[vis] ** 2
        acc[idx] += col * w[:, None]
        wsum[idx] += w
        better = w > best_w[idx]
        best_w[idx[better]] = w[better]
        best_p[idx[better]] = i
        report["panels"][p["name"]]["texels"] = int(len(idx))
    seen = wsum > 0
    out = np.zeros((len(pts), 3))
    out[seen] = acc[seen] / wsum[seen, None]
    mats = mat[covered]
    means = {}
    for k, nme in enumerate(names):
        sel = (mats == k) & seen
        if sel.any():
            means[nme] = out[sel].mean(axis=0)
        else:
            means[nme] = out[seen].mean(axis=0)
    for k, nme in enumerate(names):
        sel = (mats == k) & ~seen
        out[sel] = means[nme]
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[covered] = out
    img, _ = dilate(img, covered, MARGIN)
    report["cars"][car] = {
        "texels": int(covered.sum()), "seen": float(seen.mean()), "atlas_used": float(covered.mean()),
        "texels_a_metre": float(math.sqrt(covered.sum() / max(area(P), 1e-6))),
        "unseen_mean": {k: [round(float(v), 1) for v in means[k]] for k in names},
    }
    # Which panel each texel took most from (a colour a panel), for checking.
    cov = np.zeros((SIZE, SIZE, 3), np.uint8)
    pal = np.array([[230, 60, 60], [60, 200, 60], [60, 90, 230], [230, 200, 50], [200, 60, 200],
                    [50, 200, 210], [240, 140, 40], [140, 140, 140], [120, 60, 20], [255, 255, 255],
                    [100, 255, 160], [255, 120, 180]], np.uint8)
    tmp = np.zeros((len(pts), 3), np.uint8)
    tmp[best_p >= 0] = pal[best_p[best_p >= 0] % len(pal)]
    tmp[best_p < 0] = (25, 25, 25)
    cov[covered] = tmp
    Image.fromarray(cov).resize((SIZE // 2, SIZE // 2), Image.NEAREST).save(os.path.join(DIR, "coverage_%s.png" % car))
    out_png = os.path.join(ROOT, "assets", "train", "%s_paint.png" % car)
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save(out_png)
    print("WROTE", out_png, report["cars"][car])


def area(P):
    return float(np.linalg.norm(np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0]), axis=1).sum() * 0.5)


def main():
    layout = json.load(open(os.path.join(DIR, "layout.json")))
    clay = np.asarray(Image.open(os.path.join(DIR, "mask.png")))
    pim = Image.open(PAINT).convert("RGB")
    paint = np.asarray(pim).astype(np.float32)
    W, H = layout["size"]
    sx, sy = pim.size[0] / W, pim.size[1] / H
    painted = painted_mask(np.asarray(pim.resize((clay.shape[1], clay.shape[0]), Image.BILINEAR)))
    fits = {}
    report = {"paint": os.path.relpath(PAINT, ROOT), "size": SIZE, "inset": INSET, "panels": {}, "cars": {}}
    reg = pim.resize((1920, int(1920 * pim.size[1] / pim.size[0])), Image.BILINEAR)
    draw = ImageDraw.Draw(reg)
    rs = reg.size[0] / W
    for i, p in enumerate(layout["panels"]):
        if p.get("view") == "persp":
            continue
        fit, score, before = register(p, i + 1, clay, painted)
        fits[p["name"]] = fit
        report["panels"][p["name"]] = {"fit": [round(v, 4) for v in fit], "iou": round(float(score), 4),
                                       "iou_unfitted": round(float(before), 4)}
        # The clay's outline laid on the painting by the fit (for register.jpg).
        s = clay.shape[1] / W
        m = clay == i + 1
        edge = m & ~(np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1))
        ey, ex = np.nonzero(edge[::2, ::2])
        lx = fit[0] * (ex * 2 / s) + fit[1]
        ly = fit[2] * (ey * 2 / s) + fit[3]
        for a, b in zip(lx * rs, ly * rs * (sy / sx)):
            draw.point((a, b), fill=(0, 255, 255))
        print("panel", p["name"], report["panels"][p["name"]])
    reg.save(os.path.join(DIR, "register.jpg"), quality=88)
    bake_car("engine", os.path.join(ROOT, "assets", "train", "engine.glb"), layout, clay, painted, paint, sx, sy,
             fits, report)
    bake_car("tender", os.path.join(ROOT, "assets", "train", "tender.glb"), layout, clay, painted, paint, sx, sy,
             fits, report)
    with open(os.path.join(DIR, "bake.json"), "w") as f:
        json.dump(report, f, indent=1)
    print("DONE")


main()
