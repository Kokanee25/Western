"""The bold cowboy, take three (Sean, 2026-10-13): his shape from Rodin, his paint from his style
portraits.

    ~/bpyenv/bin/python tools/characters/rodin_portrait.py paint --man=bold_cowboy    # numpy + bpy (to read the glb)
    ~/bpyenv/bin/python tools/characters/rodin_portrait.py build --man=bold_cowboy    # bpy: into the game

1. The shape: Rodin Gen-2.5 built him from his four plain pictures (tools/characters/rodin.py
   --pictures --bust; People workflow `style: rodin`) → assets/people/tripo/test/<man>_rodin.glb.
   A bust: head, hair, collar and shoulders, his own UVs.
2. Where his face is on it: MediaPipe's landmarks found on a render of the bust in Rodin's own
   colours (each landmark a point on the mesh), so his eyes, nose and mouth are known in 3D.
3. The paint: each style portrait (portrait.json `paint_views`: front, three-quarter, both
   profiles, from behind) lined up to the bust by its own landmarks (a camera per picture:
   scale, offset, turn; least squares, soft L1); the picture from behind, which has no face, by
   the profiles' scale and its own outline. Every texel of Rodin's UVs takes its colour from the
   portrait facing it squarest that sees it (depth-tested), feathered only within SEAM of the
   best; never averaged.
4. A light de-light: each portrait's brightness fitted to the bust's normals and divided out by
   DELIGHT of the way, brightness only, so the hues stay (the red nose, the grey stubble, the
   olive shadows) and his lit cheek doesn't burn under the game's lamp.
5. Squares once, last: ~SQUARE_M on him (per UV island at its own density), each the median of
   its texels. No palette.
6. Into the game (build): the factory's body (tools/blender/factory_build.py, our bones,
   envelope, garments) with Rodin's head in place of its own: the bust cut above the collar, set
   so its drawn eyes are the anatomy's (EYES_RULE: within 1.5 cm, tests/test_bodies.gd), all of it
   on the head bone → assets/people/<man>_rodin.glb (`_head.png` is the paint).
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "blender"))
import portrait as P  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
WORK = os.path.join(ROOT, "build", "rodin_portrait")
TEX = 2048            # his paint's size (Rodin's UVs are an atlas of many islands)
SQUARE_M = 0.004
SEAM = 0.04
BG_TOL = 0.09         # a colour this near the painting's background is background
UNSQUARE = 9         # pixels: the style portraits' squares are ~10 px at 1672 wide
BRIM_ABOVE_EYES = 0.032  # the portraits' hat brim: what's above this over his eyes is hat in every one
BRIM_SIDES = 0.002       # and round his sides, where the brim's shadow lies on his hair
HAIRLINE = 0.062         # over his eyes: his forehead's skin up to here, his hair above
HIGHLIGHT_FROM = 90      # percentile of his face's brightness from which the lit side is calmed
HIGHLIGHT_KEEP = 0.4     # how much of the brightness above it stays
DELIGHT = 0.6         # how much of each portrait's shading is taken out (0 none, 1 all)
DELIGHT_CLAMP = (0.75, 1.35)
DEPTH_TOL = 0.004
MIN_FACING = 0.1
# Where each portrait starts turned (degrees about his up axis; he faces -Z, the front camera looks
# along +Z): left faces the picture's left.
VIEW_TURN = {"front": 0.0, "three_quarter": -35.0, "profile_left": -90.0, "profile_right": 90.0, "back": 180.0}
EYE_SPAN = 0.064      # metres between his irises' middles (the anatomy's eyes, 3.2 cm either side)


# --- His bust -----------------------------------------------------------------------------------------

def load_glb(path):
    """Rodin's glb → vertices (n, 3) in glTF space, triangles (m, 3), UVs per vertex (n, 2) with v
    down, and his base colour texture (h, w, 3) floats. Read by Blender (bpy)."""
    import bpy
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(path))
    V, T, UV = [], [], []
    tex = None
    off = 0
    for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        me = obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
        me.calc_loop_triangles()
        mw = np.array(obj.matrix_world)
        co = np.array([v.co for v in me.vertices])
        co = (np.c_[co, np.ones(len(co))] @ mw.T)[:, :3]
        uvl = me.uv_layers.active.data
        # One vertex per loop (UV seams split vertices), so every corner has its own UV.
        loops = np.array([[me.loops[li].vertex_index for li in t.loops] for t in me.loop_triangles])
        lidx = np.array([list(t.loops) for t in me.loop_triangles])
        uv = np.array([uvl[i].uv[:] for i in range(len(uvl))])
        V.append(co[[me.loops[i].vertex_index for i in range(len(me.loops))]])
        UV.append(uv)
        T.append(lidx + off)
        off += len(me.loops)
        if tex is None:
            for slot in obj.material_slots:
                if slot.material and slot.material.use_nodes:
                    for n in slot.material.node_tree.nodes:
                        if n.type == "TEX_IMAGE" and n.image is not None:
                            img = n.image
                            px = np.array(img.pixels[:]).reshape(img.size[1], img.size[0], -1)[::-1, :, :3]
                            tex = px
                            break
                if tex is not None:
                    break
        del loops
    V = np.concatenate(V)
    UV = np.concatenate(UV)
    UV[:, 1] = 1.0 - UV[:, 1]
    return V, np.concatenate(T), UV, tex


def weld(V, T, tol=1e-6):
    """Loop vertices welded where they share a position: (unique positions, triangles on them)."""
    key = np.round(V / tol).astype(np.int64)
    _u, first, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
    return V[first], inv.ravel()[T]


def to_body(V):
    """Blender's import (Z up; Rodin's man faces -Y there, glTF's +Z) → our body space (Y up, facing
    -Z, his right +X): body = (-x, z, y)."""
    return np.stack([-V[:, 0], V[:, 2], V[:, 1]], 1)


def sample_tex(tex, uv):
    h, w = tex.shape[:2]
    x = np.clip((uv[:, 0] * w).astype(int), 0, w - 1)
    y = np.clip((uv[:, 1] * h).astype(int), 0, h - 1)
    return tex[y, x]


def render_own(V, T, UV, tex, cam, size):
    """The bust in Rodin's own colours (for MediaPipe), lit softly from the front."""
    tid, bary, _zb = P.rasterise(cam.project(V), cam.depth(V), T, size, size)
    img = np.full((size, size, 3), 0.5)
    hit = tid >= 0
    t = T[tid[hit]]
    b = bary[hit]
    uv = (UV[t] * b[:, :, None]).sum(1)
    n = P.vertex_normals(V, T)
    nn = (n[t] * b[:, :, None]).sum(1)
    nn /= np.maximum(np.linalg.norm(nn, axis=1, keepdims=True), 1e-9)
    shade = 0.75 + 0.25 * np.clip(nn @ -cam.d, 0, 1)
    img[hit] = sample_tex(tex, uv) * shade[:, None]
    return img, (tid, bary)


def face_points(V, T, UV, tex, size=1024):
    """MediaPipe's landmarks as points on the bust (478, 3), from a front render in his own colours."""
    cam = P.head_camera(V, "front", size, fill=0.9)
    # Frame his head, not the whole bust: the top 60% of him (his chin well inside the picture:
    # cut at it, MediaPipe's chin lands on the edge and the neck cut follows it up to his mouth).
    y0 = V[:, 1].max() - 0.6 * np.ptp(V[:, 1])
    sel = V[:, 1] > y0
    cam = P.head_camera(V[sel], "front", size, fill=0.95)
    img, (tid, bary) = render_own(V, T, UV, tex, cam, size)
    P.to_pil(img).save(os.path.join(WORK, "landmark_render.png"))
    lm = P.landmarks(P.to_pil(img))
    if lm is None:
        raise SystemExit("rodin_portrait: no face found on the bust's render")
    px = np.clip(lm[:, :2].astype(int), 0, size - 1)
    tri = tid[px[:, 1], px[:, 0]]
    b = bary[px[:, 1], px[:, 0]]
    ok = tri >= 0
    pts = np.full((len(lm), 3), np.nan)
    pts[ok] = (V[T[tri[ok]]] * b[ok][:, :, None]).sum(1)
    return pts, cam


# --- Lining the portraits up ------------------------------------------------------------------------

def fit_camera(view, pts, lm, normals_at, s0, turn0):
    """A PoseCamera putting the bust's landmark points onto a portrait's landmarks: only the points
    facing the camera count (the far side of a profile is MediaPipe's guess)."""
    from scipy.optimize import least_squares
    base = "front"

    def cam_of(z):
        return P.PoseCamera(base, z[0], z[1], z[2], z[3], z[4], z[5])

    def residuals(z):
        c = cam_of(z)
        q = c.project(pts)
        facing = (normals_at @ c.toward()) > 0.15
        r = (q - lm[:, :2]) / c.s
        return np.where(facing[:, None], r, 0.0).ravel()

    # A start: scale from the eye spacing in 3D and in the picture, offset by the nose.
    c0 = P.PoseCamera(base, s0, 0, 0, turn0, 0, 0)
    q0 = c0.project(pts)
    z0 = np.array([s0, lm[1, 0] - q0[1, 0], lm[1, 1] - q0[1, 1], turn0, 0.0, 0.0])
    lo = [0.3 * s0, -1e6, -1e6, turn0 - 40, -25, -25]
    hi = [3.0 * s0, 1e6, 1e6, turn0 + 40, 25, 25]
    res = least_squares(residuals, z0, bounds=(lo, hi), loss="soft_l1", f_scale=0.004, x_scale=[s0, 50, 50, 5, 5, 5])
    c = cam_of(res.x)
    q = c.project(pts)
    facing = (normals_at @ c.toward()) > 0.15
    err = np.sqrt(np.mean(((q - lm[:, :2]) / c.s)[facing] ** 2)) * 1000
    return c, round(float(err), 2)



# --- Painting him -------------------------------------------------------------------------------------

def cube_squares(tex, cover, Pp):
    """Each texel the median colour of all texels in its SQUARE_M cube of him (per channel)."""
    sq = tex.copy()
    idx = np.nonzero(cover)
    cell = np.floor(Pp[idx] / SQUARE_M).astype(np.int64)
    _u, gid = np.unique(cell, axis=0, return_inverse=True)
    gid = gid.ravel()
    counts = np.bincount(gid)
    starts = np.concatenate([[0], np.cumsum(counts)[:-1]])
    out = np.zeros((len(counts), 3))
    for c in range(3):
        v = tex[idx][:, c]
        order = np.lexsort((v, gid))
        out[:, c] = v[order][starts + counts // 2]
    sq[idx] = out[gid]
    return sq


def islands(cover):
    from scipy import ndimage
    lab, n = ndimage.label(cover)
    return lab, n


def paint(man, spec):
    from scipy import ndimage
    os.makedirs(WORK, exist_ok=True)
    glb = os.path.join(ROOT, "assets", "people", "tripo", "test", man + "_rodin.glb")
    V, T, UV, own = load_glb(glb)
    V = to_body(V)
    # MediaPipe on his own colours (the loop mesh: one UV a corner).
    pts, _cam = face_points(V, T, UV, own)
    k = EYE_SPAN / float(np.linalg.norm(pts[468] - pts[473]))
    V *= k
    pts *= k
    n_loop = P.vertex_normals(V, T)
    # Smooth normals across UV seams: average over welded positions.
    _u, inv = np.unique(np.round(V / 1e-6).astype(np.int64), axis=0, return_inverse=True)
    inv = inv.ravel()
    acc = np.zeros((inv.max() + 1, 3))
    np.add.at(acc, inv, n_loop)
    n_loop = acc[inv] / np.maximum(np.linalg.norm(acc[inv], axis=1, keepdims=True), 1e-9)
    # Each landmark's normal: its nearest vertex's.
    from scipy.spatial import cKDTree
    ok = ~np.isnan(pts).any(1)
    nrm = np.zeros_like(pts)
    nrm[ok] = n_loop[cKDTree(V).query(pts[ok])[1]]
    report = {"scale": round(k, 5), "views": {}}
    cams, pics = {}, {}
    for view, path in spec["paint_views"].items():
        # The painting's own squares taken out (a median over a square, a little blur), so ours are
        # the only squares: projected and squared again, its squares come out as zigzags.
        from PIL import ImageFilter
        raw = Image.open(os.path.join(ROOT, path)).convert("RGB")
        img = np.asarray(raw.filter(ImageFilter.MedianFilter(UNSQUARE)).filter(ImageFilter.GaussianBlur(1.0))).astype(float) / 255.0
        pics[view] = img
        if view == "back":
            continue
        lm = P.landmarks(Image.open(os.path.join(ROOT, path)).convert("RGB"))
        if lm is None:
            report["views"][view] = "no face found"
            continue
        s0 = float(np.linalg.norm(lm[468, :2] - lm[473, :2])) / EYE_SPAN
        if view.startswith("profile"):
            s0 = float(abs(lm[152, 1] - lm[168, 1])) / max(abs(pts[152, 1] - pts[168, 1]), 1e-6)
        use = ok.copy()
        cam, err = fit_camera(view, np.where(use[:, None], pts, 0.0), lm, np.where(use[:, None], nrm, 0.0), s0, VIEW_TURN[view])
        cams[view] = cam
        report["views"][view] = {"landmarks_mm": err, "turn": round(cam.yaw, 1), "s": round(cam.s, 1)}
    if "back" in pics and any(v.startswith("profile") for v in cams):
        side = [cams[v] for v in cams if v.startswith("profile")]
        s = float(np.mean([c.s for c in side]))
        tv = float(np.mean([c.tv for c in side]))
        back = P.PoseCamera("front", s, 0.0, tv, 180.0, 0, 0)
        # Across: his head's middle on the picture's grey hair (the lightest, least coloured pixels
        # between the eyes' and the chin's heights).
        img = pics["back"]
        y0 = int(back.project(pts[168:169])[0, 1])
        y1 = int(back.project(pts[152:153])[0, 1])
        band = img[max(0, y0):max(y0 + 1, y1)]
        sat = band.max(2) - band.min(2)
        grey = (sat < 0.08) & (band.mean(2) > 0.35)
        xs = np.nonzero(grey)[1]
        cx = float(np.median(xs)) if len(xs) > 50 else img.shape[1] / 2
        back.tu = cx - float(back.project(np.array([[np.median(V[:, 0]), 0.0, 0.0]]))[0, 0])
        cams["back"] = back
        report["views"]["back"] = {"from": "the profiles' scale and height, his grey hair's middle"}
    # Every texel of his UVs: where it is on him, which way it faces.
    table = {tuple(t): [tuple(UV[i]) for i in t] for t in T}
    M, cover = P.raster_uv(table, [list(t) for t in T], np.concatenate([V, n_loop], 1), TEX)
    Pp, N = M[..., :3], M[..., 3:]
    N /= np.maximum(np.linalg.norm(N, axis=-1, keepdims=True), 1e-9)
    idx = np.nonzero(cover)
    p, n = Pp[idx], N[idx]
    score, colour = {}, {}
    for view, cam in cams.items():
        img = pics[view]
        h, w = img.shape[:2]
        _tid, _b, zb = P.rasterise(cam.project(V), cam.depth(V), T, w, h)
        zb = ndimage.minimum_filter(zb, size=3)
        q = cam.project(p)
        qi = np.clip(q.astype(int), 0, [w - 1, h - 1])
        seen = (cam.depth(p) <= zb[qi[:, 1], qi[:, 0]] + DEPTH_TOL) & (q[:, 0] >= 0) & (q[:, 0] < w) & (q[:, 1] >= 0) & (q[:, 1] < h)
        f = n @ cam.toward()
        colour[view] = P.sample(img, q[:, 0], q[:, 1])
        # His mane is bigger than the painted hair: where it lands on the painting's background
        # (the colours of its left and right edges), this view doesn't paint it.
        edge = np.concatenate([img[:, :40].reshape(-1, 3), img[:, -40:].reshape(-1, 3)])
        bg = np.median(edge, 0)
        bg_like = (np.linalg.norm(colour[view] - bg, axis=1) < BG_TOL) & (p[:, 1] > float(pts[152, 1]))
        score[view] = np.where(seen & ~bg_like & (f > MIN_FACING), f, -np.inf)
    names = list(cams)
    S = np.stack([score[v] for v in names])
    best = S.max(0)
    seen_any = np.isfinite(best)
    W = np.where(np.isfinite(S), np.exp((S - np.where(seen_any, best, 0)[None]) / SEAM), 0.0)
    W /= np.maximum(W.sum(0, keepdims=True), 1e-9)
    # The light de-light: brightness only, DELIGHT of each portrait's shading.
    lum = np.array([0.2126, 0.7152, 0.0722])
    lit = {}
    for k_, v in enumerate(names):
        c = colour[v]
        y = c @ lum
        sel = W[k_] > 0.5
        if sel.sum() > 500:
            A = np.c_[np.ones(sel.sum()), n[sel]]
            coef = np.linalg.lstsq(A, y[sel], rcond=None)[0]
            shade = np.c_[np.ones(len(n)), n] @ coef
            ratio = np.clip(shade / max(float(np.median(shade[sel])), 1e-6), 1e-3, None) ** DELIGHT
            ratio = np.clip(ratio, *DELIGHT_CLAMP)
            c = np.clip(c / ratio[:, None], 0, 1)
            report["views"].setdefault(v, {})
            if isinstance(report["views"][v], dict):
                report["views"][v]["shading"] = [round(float(x), 3) for x in coef]
        lit[v] = c
    col = sum(W[k_][:, None] * lit[v] for k_, v in enumerate(names))
    tex = np.zeros((TEX, TEX, 3))
    tex[idx] = col
    have = np.zeros((TEX, TEX), bool)
    have[idx] = seen_any
    _d, (iy, ix) = ndimage.distance_transform_edt(~have, return_indices=True)
    tex = tex[iy, ix]
    P.to_pil(tex).save(os.path.join(WORK, man + "_projected.png"))
    best_v = np.argmax(np.stack([W[k_] for k_ in range(len(names))]), 0)
    which = np.zeros((TEX, TEX, 3))
    palv = np.array([[0.9, 0.3, 0.3], [0.3, 0.9, 0.3], [0.3, 0.3, 0.9], [0.9, 0.9, 0.3], [0.9, 0.3, 0.9]])
    which[idx] = palv[best_v % 5] * np.where(seen_any, 1.0, 0.2)[:, None]
    P.to_pil(which).save(os.path.join(WORK, man + "_which_view.png"))
    # Above the portraits' brim every portrait shows hat: there his hair and forehead's colour
    # carries on up from below (the game's hat covers it).
    eye_y = float((pts[468, 1] + pts[473, 1]) / 2)
    front = (N[..., 2] < -0.5) & (np.abs(Pp[..., 0]) < 0.06)
    # The brim sits lower round his sides than over his forehead (its shadow lies on his hair
    # there): his forehead is hat above BRIM_ABOVE_EYES, the rest above BRIM_SIDES.
    hat = cover & (Pp[..., 1] > eye_y + np.where(front, BRIM_ABOVE_EYES, BRIM_SIDES))
    below = cover & ~hat
    # Under the game's hat nobody sees much, but what shows must be him, not the painted brim: his
    # forehead's skin where it faces you, his grey hair round the rest (the medians of his
    # forehead just under the brim line, and of the grey at his temples and sideburns).
    near = below & front & (Pp[..., 1] > eye_y + BRIM_ABOVE_EYES - 0.025)
    sat = tex.max(-1) - tex.min(-1)
    lumt = tex.mean(-1)
    temples = cover & ~front & (np.abs(Pp[..., 0]) > 0.06) & (Pp[..., 1] > eye_y - 0.03) \
        & (Pp[..., 1] < eye_y + 0.012) & (lumt > 0.2)
    # The painted grey is warm: his temples' least coloured 40% is his hair, the rest skin and ear.
    if temples.sum() > 50:
        cand = tex[temples]
        csat = sat[temples]
        hair_c = np.median(cand[csat <= np.percentile(csat, 40)], 0)
    else:
        hair_c = np.median(tex[below], 0)
    skin_c = np.median(tex[near], 0) if near.sum() > 20 else np.median(tex[below], 0)
    report["fill"] = {"temples": int(temples.sum()), "hair": [round(float(x), 3) for x in hair_c],
                      "forehead": [round(float(x), 3) for x in skin_c]}
    forehead = front & (Pp[..., 1] < eye_y + HAIRLINE)
    tex[hat & forehead] = skin_c
    tex[hat & ~forehead] = hair_c
    # His lit side calmed (the game's lamp lights him again): the face's brightest tenth brought
    # down towards the rest, hue kept; and lone near-white specks (a catchlight that missed his
    # eye) taken to the face's bright level.
    face = below & (Pp[..., 1] > float(pts[152, 1])) & (N[..., 2] < 0.2)
    lum = tex @ np.array([0.2126, 0.7152, 0.0722])
    if face.sum() > 100:
        hi = np.percentile(lum[face], HIGHLIGHT_FROM)
        over = face & (lum > hi)
        target = hi + (lum[over] - hi) * HIGHLIGHT_KEEP
        tex[over] *= (target / np.maximum(lum[over], 1e-6))[:, None]
        speck = face & (sat < 0.1) & (lum > np.percentile(lum[face], 99.5))
        tex[speck] *= (hi / np.maximum(lum[speck], 1e-6))[:, None]
    # Squares, once, last: SQUARE_M cells in 3D on him (so they sit square on his head, whatever
    # Rodin's UV islands do), each the median of its texels.
    sq = cube_squares(tex, cover, Pp)
    P.to_pil(sq).save(os.path.join(WORK, man + "_paint.png"))
    # Rodin's own colour at each corner (the build keeps only his neck's skin, not his collar).
    np.save(os.path.join(WORK, man + "_mesh.npy"), {"V": V, "T": T, "UV": UV, "pts": pts, "own": sample_tex(own, UV)},
            allow_pickle=True)
    report["cameras"] = {v: c.json() for v, c in cams.items()}
    report["seen"] = round(float(seen_any.mean()), 3)
    json.dump(report, open(os.path.join(WORK, man + "_report.json"), "w"), indent=1)
    print("rodin_portrait: painted", man, json.dumps({k: v for k, v in report.items() if k != "cameras"}))
    return V, T, UV, sq


def main():
    args = sys.argv[1:]
    step = args[0] if args and not args[0].startswith("--") else "paint"
    man = next((a.split("=", 1)[1] for a in args if a.startswith("--man=")), "bold_cowboy")
    spec = json.load(open(os.path.join(ROOT, "assets", "people", "portrait.json")))["men"][man]
    if step in ("paint", "all"):
        paint(man, spec)
    if step in ("build", "all"):
        import rodin_portrait_build  # noqa: E402  (bpy)
        rodin_portrait_build.build(man, spec)
    P.close_landmarker()


if __name__ == "__main__":
    main()
