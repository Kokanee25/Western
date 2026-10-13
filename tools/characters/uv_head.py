"""The UV portrait, step 1: his head's shape (docs/briefs/uv-portrait.md; Sean, 2026-10-13).

    python3 tools/characters/uv_head.py shape --man=bold_cowboy    # bpy (mathutils), numpy, mediapipe
    python3 tools/characters/uv_head.py build --man=bold_cowboy [--tex=PNG] [--faceted]   # bpy: into the game

One shared head, his shape taken from Rodin by shrinkwrapping, not by fitting landmarks:

1. The shared head: the factory's man (MakeHuman's base mesh, CC0, through make_people's route:
   our joints, the envelope, our 17 bones), his eyeballs where the anatomy's eyes are.
2. Rodin's bust of him (tools/characters/rodin.py --pictures --bust; People workflow
   `style: rodin`) placed on that head by ONE similarity transform, 7 numbers (scale, turn,
   shift), least squares over a few MediaPipe landmarks on both (eye corners, irises, nose,
   mouth corners, chin), the irises weighted most: the eyes are where the anatomy's are.
3. The shrinkwrap: each head vertex is cast along its normal onto Rodin's surface (or to the
   nearest point when the cast misses), within REACH. The displacements are smoothed over the
   head (a Laplacian of the displacement, coarse to fine in ROUNDS), so the head takes Rodin's
   forms without its vertices bunching, and MakeHuman's small forms (lids, nostrils, the ear's
   rim and bowl) ride along instead of being flattened. Held back by a weight: none at the neck
   where the head meets the body (so it stays joined), little round the eyes and on the ears
   (MakeHuman's lids and ears move with the head, not snapped onto Rodin's blobs), none on the
   eyeballs. His hair is part of the head's shape, held to HAIR_OUT off the scalp so the game's
   hat still goes on.

shape → build/uv_head/<man>_shape.npz (every vertex of the factory man, the head's moved),
<man>_shape.json (the alignment, the eyes, how far it moved), and the checkpoint's pictures:
<man>_shape_views.png (our head, grey, front and profile, beside his plain front and profile,
his profile's outline drawn over ours).
build → assets/people/<man>_uv.glb: the factory's body with this head, a grey head texture.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "blender"))
import factory as F  # noqa: E402
import make_people as mp  # noqa: E402
import portrait as P  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
WORK = os.path.join(ROOT, "build", "uv_head")
RODIN = os.path.join(ROOT, "assets", "people", "tripo", "test", "%s_rodin.glb")
PLAIN = os.path.join(ROOT, "docs", "concept", "style", "factory", "%s", "%s.png")
HEAD_FRAC = 0.62      # his plain pictures: the top of his hair to under his chin

# The landmarks the alignment uses (MediaPipe's indices) and their weights: the irises (468, 473)
# most, so his eyes land on the anatomy's.
ALIGN = {468: 8.0, 473: 8.0, 33: 2.0, 133: 2.0, 362: 2.0, 263: 2.0, 6: 1.0, 1: 1.0, 2: 1.0,
         61: 1.0, 291: 1.0, 0: 1.0, 17: 1.0, 152: 1.0, 10: 0.5, 105: 0.5, 334: 0.5}
REACH = 0.03          # metres: a vertex is cast at most this far onto Rodin's surface
FACING = 0.5          # and only onto a surface facing within 60 degrees of its own way
HAIR_REACH = 0.055    # on the scalp, cast this far (his hair stands well off it)
HAIR_OUT = 0.04       # his hair stands at most this far off MakeHuman's scalp
IN_MOST = 0.02        # and nothing goes further in than this
ROUNDS = (60, 25, 10, 4)  # smoothing steps of the displacement, coarse to fine
NECK_HOPS = 8         # edges from the head's join with the body over which the wrap fades in
EYE_HOLD = (0.014, 0.024)  # metres from an eye's middle: held (weight EYE_W) inside, free outside
EYE_W = 0.0           # the lids aren't cast: they ride on the smoothed displacement round them
EAR_W = 0.0           # the ears ride too (Rodin's are under his hair)
FACETED_TRIS = 800     # step 6's test: the head this many triangles, drawn flat
CLAY = 0.5            # the grey head's albedo (until it is painted)
MOUTH_HOLD = (0.008, 0.016)  # metres from a mouth corner: its folds ride, not cast
# His ears in (Sean, 2026-10-13: in his pictures his hair covers them): the base head's flare taken
# back and the wing turned in.
EARS_IN = {"ears/{s}-ear-wing-incr": -0.6, "ears/{s}-ear-wing-decr": 0.7, "ears/{s}-ear-flap-incr": -0.5}
FSPEC = {"source": "factory", "targets": dict(P.DEFAULT_MACRO, **EARS_IN), "hair": "none", "moustache": "none",
         "beard": "none", "skin": "#b07a5a"}


# --- The shared head -------------------------------------------------------------------------------

def factory_man(man):
    """The factory man, warped onto our joints (make_people's route), and his head's parts."""
    env = json.load(open(mp.ENVELOPE))
    p = F.make_person(man + "_uv", dict(FSPEC), env, F.load_factory())
    p.run()
    return p


def head_parts(p):
    """The head's faces (vertex id lists), the eyeballs' vertices, the head region's vertices that
    are also on the body's faces (the join), and the ears' weights."""
    n = len(p.v)
    hr = p.region == "head"
    faces = [list(f[0]) for f in p.body_faces if hr[list(f[0])].all()]
    join = np.zeros(n, bool)
    for f in p.body_faces:
        ids = list(f[0])
        if not hr[ids].all():
            join[ids] = True
    join &= hr
    eyes = {s: np.array(sorted({i for f in p.groups["helper-%s-eye" % s] for i in f[0]})) for s in "rl"}
    body = np.zeros(n)
    body[sorted({i for f in p.body_faces for i in f[0]})] = 1.0
    ear = np.maximum(F.region("ears/r-ear-wing-incr", n, body), F.region("ears/l-ear-wing-incr", n, body))
    return faces, eyes, join, np.clip(ear * 3.0, 0, 1)


def tris_of(faces):
    return P.triangles(faces)[0]


# --- Landmarks on a mesh -----------------------------------------------------------------------------

def mesh_landmarks(V, T, colour_img_fn, size=1024, tag=""):
    """MediaPipe's landmarks as points on a mesh: render it from the front (colour_img_fn(cam) → the
    picture and its raster), find the face, and lift each landmark onto the triangle under it."""
    cam = P.head_camera(V[np.unique(T)], "front", size, fill=0.95)
    img, (tid, bary) = colour_img_fn(cam)
    P.to_pil(img).save(os.path.join(WORK, "landmarks_%s.png" % tag))
    lm = P.landmarks(P.to_pil(img))
    if lm is None:
        raise SystemExit("uv_head: no face found on %s's render" % tag)
    px = np.clip(lm[:, :2].astype(int), 0, size - 1)
    tri = tid[px[:, 1], px[:, 0]]
    b = bary[px[:, 1], px[:, 0]]
    ok = tri >= 0
    pts = np.full((len(lm), 3), np.nan)
    pts[ok] = (V[T[tri[ok]]] * b[ok][:, :, None]).sum(1)
    return pts


def clay_landmarks(V, T, eye_ids, eye_centres):
    """The factory head's landmarks: grey clay with eyes drawn on its eyeballs (MediaPipe wants eyes)."""
    col = np.ones((len(V), 3)) * np.array([0.72, 0.60, 0.52])
    for s in "rl":
        col[eye_ids[s]] = P.eye_colour(V, eye_ids[s], eye_centres[s])[eye_ids[s]]

    def draw(cam):
        img, (tid, bary, _z) = P.render(V, T, col, cam, 1024, 1024, light=(0.0, 0.3, -1.0), ambient=0.55)
        return img, (tid, bary)
    return mesh_landmarks(V, T, draw, tag="factory")


def rodin_bust(man):
    """Rodin's bust in body space: welded vertices and triangles, and its landmarks (on the
    unwelded mesh, in its own colours)."""
    sys.path.insert(0, HERE)
    import rodin_portrait as RP
    V, T, UV, tex = RP.load_glb(RODIN % man)
    V = RP.to_body(V)

    def draw(cam):
        img, (tid, bary) = RP.render_own(V, T, UV, tex, cam, 1024)
        return img, (tid, bary)
    # Frame his head, not the whole bust (his chin well inside the picture).
    sel = V[:, 1] > V[:, 1].max() - 0.6 * np.ptp(V[:, 1])
    Vh = V[sel]
    cam0 = P.head_camera(Vh, "front", 1024, fill=0.95)

    def draw_head(cam):
        return draw(cam0)
    pts = mesh_landmarks(V, T, draw_head, tag="rodin")
    Vw, Tw = RP.weld(V, T)
    return Vw, Tw, pts


def similarity(src, dst, w):
    """Weighted Umeyama: s, R, t minimising sum w |s R src + t - dst|^2 (7 numbers)."""
    w = w / w.sum()
    ms, md = (w[:, None] * src).sum(0), (w[:, None] * dst).sum(0)
    a, b = src - ms, dst - md
    cov = (w[:, None] * b).T @ a
    U, S, Vt = np.linalg.svd(cov)
    d = np.sign(np.linalg.det(U @ Vt))
    D = np.diag([1, 1, d])
    R = U @ D @ Vt
    var = (w * (a ** 2).sum(1)).sum()
    s = np.trace(np.diag(S) @ D) / var
    return s, R, md - s * R @ ms


# --- The shrinkwrap ------------------------------------------------------------------------------

def laplacian_smooth(x, a, b, steps, free):
    """Each step every free vertex takes the mean of itself and its neighbours (x: (n, k))."""
    deg = np.bincount(a, minlength=len(x)).astype(float)[:, None]
    for _ in range(steps):
        s = np.zeros_like(x)
        np.add.at(s, a, x[b])
        x = np.where(free[:, None], (x + s) / (1 + deg), x)
    return x


def wrap(v0, tris, w, Vr, Tr, edges, scalp_n, hair, free):
    """MakeHuman's head shrinkwrapped onto Rodin's surface (see the module's note)."""
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    bvh = BVHTree.FromPolygons([tuple(map(float, p)) for p in Vr], Tr.tolist(), all_triangles=True)
    a, b = edges
    v = v0.copy()
    idx = np.nonzero(w > 0)[0]
    for steps in ROUNDS:
        n = P.vertex_normals(v, tris)
        target = v.copy()
        for i in idx:
            reach = HAIR_REACH if hair[i] else REACH
            o = Vector(v[i])
            nn = Vector(n[i])
            best = None
            for d in (nn, -nn):
                hit, hn, _f, dist = bvh.ray_cast(o, d, reach)
                if hit is not None and hn.dot(nn) > FACING and (best is None or dist < best[1]):
                    best = (hit, dist)
            if best is None:
                hit, hn, _f, dist = bvh.find_nearest(o, reach)
                if hit is not None and hn.dot(nn) > FACING:
                    best = (hit, dist)
            if best is not None:
                target[i] = np.array(best[0])
        d = (target - v) * w[:, None]
        d = laplacian_smooth(d, a, b, steps, free)
        v = v + d
    # Held to the scalp's reach: hair at most HAIR_OUT out, nothing more than IN_MOST in.
    off = ((v - v0) * scalp_n).sum(1)
    out_most = np.where(hair, HAIR_OUT, REACH)
    clamp = np.clip(off, -IN_MOST, out_most) - off
    v = v + scalp_n * clamp[:, None]
    return v


def untangle(v0, v, tris, edges, free, rounds=30):
    """Any triangle the wrap folded over: its corners' displacements relaxed to their neighbours'
    (a few hops round them) until none is folded."""
    a, b = edges
    d = v - v0
    for _ in range(rounds):
        bad = folded_mask(v0, v0 + d, tris)
        if not bad.any():
            break
        near = np.zeros(len(v0), bool)
        near[tris[bad].ravel()] = True
        for _h in range(2):
            grow = near.copy()
            np.logical_or.at(grow, a, near[b])
            near = grow
        d = laplacian_smooth(d, a, b, 3, near & free)
    return v0 + d


def folded_mask(v0, v, tris):
    def fn(x):
        return np.cross(x[tris[:, 1]] - x[tris[:, 0]], x[tris[:, 2]] - x[tris[:, 0]])
    return (fn(v0) * fn(v)).sum(1) < 0


def folded(v0, v, tris):
    """Triangles whose facing turned more than 90 degrees in the wrap."""
    def fn(x):
        return np.cross(x[tris[:, 1]] - x[tris[:, 0]], x[tris[:, 2]] - x[tris[:, 0]])
    return ((fn(v0) * fn(v)).sum(1) < 0).sum()


def weights(p, faces, eyes, join, ear, edges, mouth):
    """How free each vertex is to follow Rodin (0 held, 1 free)."""
    n = len(p.v)
    hr = p.region == "head"
    hops = P.edge_hops(hr & ~join, edges, NECK_HOPS)
    w = np.where(hr, np.clip(hops / NECK_HOPS, 0, 1), 0.0)
    for s in "rl":
        c = p.v[eyes[s]].mean(0)
        r = np.linalg.norm(p.v - c, axis=1)
        hold = np.clip((r - EYE_HOLD[0]) / (EYE_HOLD[1] - EYE_HOLD[0]), 0, 1)
        w *= EYE_W + (1 - EYE_W) * hold
        w[eyes[s]] = 0.0
    w *= 1.0 - (1.0 - EAR_W) * ear
    for c in mouth:
        r = np.linalg.norm(p.v - c, axis=1)
        w *= np.clip((r - MOUTH_HOLD[0]) / (MOUTH_HOLD[1] - MOUTH_HOLD[0]), 0, 1)
    drawn = np.zeros(n, bool)   # MakeHuman's helpers (lashes, brows, joints) share the region
    drawn[[i for f in faces for i in f]] = True
    return w * drawn


def shape(man):
    os.makedirs(WORK, exist_ok=True)
    p = factory_man(man)
    faces, eyes, join, ear = head_parts(p)
    eye_faces = [list(f[0]) for f in p.groups["helper-r-eye"] + p.groups["helper-l-eye"]]
    tris = tris_of(faces)
    all_tris = tris_of(faces + eye_faces)
    centres = {s: p.v[eyes[s]].mean(0) for s in "rl"}
    prep = os.path.join(WORK, man + "_prep.npz")
    if "--again" in sys.argv and os.path.exists(prep):   # the landmarks and the bust as last time
        z = np.load(prep)
        lm_f, Vr, Tr, lm_r = z["lm_f"], z["Vr"], z["Tr"], z["lm_r"]
    else:
        lm_f = clay_landmarks(p.v, all_tris, eyes, centres)
        Vr, Tr, lm_r = rodin_bust(man)
        np.savez(prep, lm_f=lm_f, Vr=Vr, Tr=Tr, lm_r=lm_r)
    ids = [i for i in ALIGN if np.isfinite(lm_f[i]).all() and np.isfinite(lm_r[i]).all()]
    wts = np.array([ALIGN[i] for i in ids])
    s, R, t = similarity(lm_r[ids], lm_f[ids], wts)
    Vr = (s * (R @ Vr.T)).T + t
    lm_r = (s * (R @ lm_r.T)).T + t
    res = np.linalg.norm(lm_r[ids] - lm_f[ids], axis=1)
    turn = np.degrees(np.array([math.atan2(R[2, 1], R[2, 2]), -math.asin(np.clip(R[2, 0], -1, 1)), math.atan2(R[1, 0], R[0, 0])]))
    edges = P.neighbours(faces + eye_faces, len(p.v))
    w = weights(p, faces, eyes, join, ear, edges, [lm_f[61], lm_f[291]])
    # The scalp: MakeHuman's head above his brow and behind his ears (hair may stand off it).
    n0 = P.vertex_normals(p.v, all_tris)
    brow_y = lm_f[10, 1] - 0.01
    hair = (p.v[:, 1] > brow_y) | (p.v[:, 2] > centres["r"][2] + 0.06)
    eyeball = np.zeros(len(p.v), bool)
    for s_ in "rl":
        eyeball[eyes[s_]] = True
    drawn = np.zeros(len(p.v), bool)
    drawn[np.unique(tris)] = True
    free = (p.region == "head") & drawn & ~join & ~eyeball
    v = wrap(p.v, all_tris, w, Vr, Tr, edges, n0, hair, free)
    v = untangle(p.v, v, all_tris, edges, free)
    moved = np.linalg.norm(v - p.v, axis=1)
    hr = drawn
    # How near Rodin's surface the head ended (the free parts).
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    bvh = BVHTree.FromPolygons([tuple(map(float, q)) for q in Vr], Tr.tolist(), all_triangles=True)
    free = np.nonzero(w > 0.9)[0]
    gap = np.array([bvh.find_nearest(Vector(v[i]))[3] for i in free])
    eye_err = {s: round(float(np.linalg.norm(lm_r[468 if s == "r" else 473] - lm_f[468 if s == "r" else 473])), 4) for s in "rl"}
    rep = {"man": man, "rodin": os.path.relpath(RODIN % man, ROOT),
           "align": {"scale": round(float(s), 4), "turn_deg": [round(float(x), 2) for x in turn],
                     "shift_m": [round(float(x), 4) for x in t], "landmarks": ids,
                     "residual_mm_rms": round(float(np.sqrt((res ** 2).mean()) * 1000), 2),
                     "iris_mm": {k: round(x * 1000, 1) for k, x in eye_err.items()}},
           "moved_mm": {"median": round(float(np.median(moved[hr]) * 1000), 1),
                        "p95": round(float(np.percentile(moved[hr], 95) * 1000), 1),
                        "max": round(float(moved.max() * 1000), 1)},
           "gap_to_rodin_mm": {"median": round(float(np.median(gap) * 1000), 2),
                               "p95": round(float(np.percentile(gap, 95) * 1000), 2)},
           "folded_triangles": int(folded(p.v, v, tris)),
           "head_triangles": int(len(tris)), "eye_triangles": int(len(all_tris) - len(tris))}
    np.savez(os.path.join(WORK, man + "_shape.npz"), v=v, v0=p.v, w=w, Vr=Vr, Tr=Tr, tris=all_tris, lm=lm_r)
    json.dump(rep, open(os.path.join(WORK, man + "_shape.json"), "w"), indent=1)
    views(man, v, p.v, all_tris, Vr, Tr, centres)
    print(json.dumps(rep, indent=1))
    P.close_landmarker()


# --- The checkpoint's pictures ---------------------------------------------------------------------

def silhouette(img_rgb, bg_tol=0.12):
    """The man's shape on the plain pictures' grey ground (bool, h x w): what differs from the
    ground's colour (its top corners), the largest piece, holes filled, stray hairs opened off."""
    from scipy import ndimage
    a = np.asarray(img_rgb.convert("RGB")).astype(float) / 255
    bg = np.median(np.concatenate([a[:40, :40].reshape(-1, 3), a[:40, -40:].reshape(-1, 3)]), 0)
    m = np.abs(a - bg).max(2) > bg_tol
    m = ndimage.binary_opening(m, iterations=3)
    lab, n = ndimage.label(m)
    if n:
        m = lab == (np.bincount(lab.ravel())[1:].argmax() + 1)
    return ndimage.binary_fill_holes(m)


def front_edge(mask, facing_left):
    """For each row, the column of the outline's front edge (nan where the row is empty)."""
    cols = np.full(mask.shape[0], np.nan)
    for y in range(mask.shape[0]):
        xs = np.nonzero(mask[y])[0]
        if len(xs):
            cols[y] = xs.min() if facing_left else xs.max()
    return cols


def profile_fit(man, cam, centres, box, size, oe, te):
    """Their profile onto ours (s, dx, dy, in our pixels): his scale and eye height from the plain
    FRONT picture's irises (the plain pictures share one framing; our eyes are the anatomy's), his
    nose tip on ours."""
    front = Image.open(PLAIN % (man, "front")).convert("RGB")
    lm = P.landmarks(front)
    if lm is None:
        return None
    ppm = np.linalg.norm(lm[468, :2] - lm[473, :2]) / np.linalg.norm(centres["r"] - centres["l"])
    eye_row = (lm[468, 1] + lm[473, 1]) / 2
    k = size / (box[3] - box[1])                     # the crop's enlargement
    s = cam.s / (ppm * k)
    ours_eye = cam.project((centres["r"] + centres["l"]) / 2)[1]
    dy = ours_eye - s * (eye_row - box[1]) * k
    if not (np.isfinite(oe).any() and np.isfinite(te).any()):
        return None
    dx = np.nanmin(oe) - s * np.nanmin(te)
    return (0.0, s, dx, dy)


def views(man, v, v0, tris, Vr, Tr, centres, size=560):
    """Ours (grey) front and profile beside his plain front and profile; his outline over ours."""
    keep = np.unique(tris)
    col = np.ones((len(v), 3)) * 0.78
    out = []
    for view, pic in (("front", "front"), ("left", "left")):
        cam = P.head_camera(v[keep], view, size, fill=0.78)
        img, _r = P.render(v, tris, col, cam, size, size, light=(-0.35, 0.4, -1.0) if view == "front" else (0.6, 0.4, -0.6), ambient=0.4)
        ours = P.to_pil(img)
        photo = Image.open(PLAIN % (man, pic)).convert("RGB")
        # His head: from the top of his outline down HEAD_FRAC of the picture, centred on the
        # outline over those rows; the same box cut from his outline (found on the whole picture).
        full = silhouette(photo)
        top = int(np.nonzero(full.any(1))[0][0])
        h = int(HEAD_FRAC * photo.height)
        y0 = max(0, top - h // 12)
        cols = np.nonzero(full[y0:y0 + int(0.8 * h)].any(0))[0]
        cx = int((cols.min() + cols.max()) / 2)
        h = max(h, int(1.08 * (cols.max() - cols.min())))   # his hair wider than tall, in profile
        box = (cx - h // 2, y0, cx + h // 2, y0 + h)
        crop = photo.crop(box).resize((size, size), Image.LANCZOS)
        tm = np.asarray(Image.fromarray(full.astype(np.uint8) * 255).crop(box).resize((size, size), Image.NEAREST)) > 127
        if view == "left":
            # His outline over ours: his front edge fitted to ours over the face (brow to chin).
            om = np.abs(np.asarray(ours).astype(float) / 255 - 0.5).max(2) > 0.02
            oe, te = front_edge(om, True), front_edge(tm, True)
            fit = profile_fit(man, cam, centres, box, size, oe, te)
            ov = ours.copy()
            if fit:
                _e, s, dx, dy = fit
                warped = tm.astype(np.uint8) * 255
                wim = Image.fromarray(warped).resize((int(tm.shape[1] * s), int(tm.shape[0] * s)), Image.NEAREST)
                canvas = Image.new("L", (size, size), 0)
                canvas.paste(wim, (int(round(dx)), int(round(dy))))
                m = np.asarray(canvas) > 127
                edge = m ^ np.roll(m, 1, 0) | m ^ np.roll(m, 1, 1)
                arr = np.asarray(ov).copy()
                arr[edge] = (220, 40, 30)
                ov = Image.fromarray(arr)
            out += [label(crop, "plain " + pic), label(ours, "ours, grey: " + ("front" if view == "front" else "profile")),
                    label(ov, "ours + his outline (red)")]
        else:
            out += [label(crop, "plain " + pic), label(ours, "ours, grey: front")]
    W = size * 3 + 20
    sheet = Image.new("RGB", (W, size * 2 + 10), (22, 20, 18))
    sheet.paste(out[0], (0, 0))
    sheet.paste(out[1], (size + 10, 0))
    for k in range(3):
        sheet.paste(out[2 + k], (k * (size + 10), size + 10))
    path = os.path.join(WORK, man + "_shape_views.png")
    sheet.save(path)
    print("wrote", path)


def label(im, text):
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 8 + 7 * len(text), 16], fill=(22, 20, 18))
    d.text((4, 2), text, fill=(235, 225, 205))
    return im


# --- Into the game ---------------------------------------------------------------------------------

def build(man, tex=None, faceted=False):
    """The factory's body with this head (same vertices, moved); → assets/people/<man>_uv.glb.
    With uv_layout.py's layout (build/uv_head/<man>_layout.npz) its UVs, and tex (a PNG in that
    layout) on it; else the factory's layout, grey."""
    import factory_build as FB
    lay = os.path.join(WORK, man + "_layout.npz")
    if os.path.exists(lay):
        z = np.load(lay, allow_pickle=True)
        table = {tuple(int(i) for i in f): [tuple(uv) for uv in cs] for f, cs in zip(z["faces"], z["corner"])}
        FB._cache["base"] = None
        FB._cache["layout"] = (table, {}, None, None, None)
    shaped = np.load(os.path.join(WORK, man + "_shape.npz"))["v"]
    make = F.make_person

    def make_shaped(*a, **k):
        p = make(*a, **k)
        run = p.run

        def run_shaped():
            run()
            if p.v.shape != shaped.shape:
                raise SystemExit("uv_head: the factory man changed since the shape was made; run shape again")
            p.v = shaped.copy()
        p.run = run_shaped
        return p
    FB.F.make_person = make_shaped
    if tex:
        paint = np.asarray(Image.open(tex).convert("RGB")).astype(float) / 255
        FB.paint_head = lambda *_a, **_k: paint
    else:
        FB.paint_head = lambda *_a, **_k: np.full((FB.HEAD_TEX, FB.HEAD_TEX, 3), CLAY)
    FB.shells = lambda *_a, **_k: []
    env = json.load(open(mp.ENVELOPE))
    spec = dict(FSPEC)
    spec["outfit"] = json.load(open(os.path.join(ROOT, "assets", "people", "portrait.json")))["men"].get(man, {}).get("outfit", {})
    export = FB.mp.export

    def export_faceted(person):
        """The test look (Sean, step 6): the head cut to FACETED_TRIS, every face drawn flat."""
        import bpy
        o = bpy.data.objects["body_head"]
        tris = sum(len(q.vertices) - 2 for q in o.data.polygons)
        mod = o.modifiers.new("facets", "DECIMATE")
        mod.ratio = min(1.0, FACETED_TRIS / max(tris, 1))
        mod.use_collapse_triangulate = True
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_move_to_index(modifier="facets", index=0)
        bpy.ops.object.modifier_apply(modifier="facets")
        for q in o.data.polygons:
            q.use_smooth = False
        person.report["triangles"]["head"] = len(o.data.polygons)
        person.report["faceted"] = True
        export(person)
    if faceted:
        FB.mp.export = export_faceted
    try:
        FB.build(man + ("_uv_faceted" if faceted else "_uv"), spec, env, F.load_factory())
    finally:
        FB.F.make_person = make
        FB.mp.export = export


def main():
    args = dict(a.split("=", 1) for a in sys.argv[1:] if "=" in a)
    man = args.get("--man", "bold_cowboy")
    os.chdir(ROOT)
    if "shape" in sys.argv:
        shape(man)
    elif "build" in sys.argv:
        build(man, args.get("--tex"), "--faceted" in sys.argv)
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
