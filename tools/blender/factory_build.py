"""The character factory's Blender half (tools/blender/factory.py runs it; needs bpy).

The head's UV layout (laid out once from the base head and shared by every man), the hair and
facial hair shells, the head and hair textures stamped by script, and the man built and exported
the way make_people.py builds a MakeHuman man (his garments by clothes.py).
"""
import json
import math
import os
import time

import bpy
import numpy as np

import clothes
import factory as F
import make_people as mp

# Texture density of each island of the head's layout, in UV units a metre (the atlas is 1 x 1):
# the face, ears and eyes get far more of it than the scalp (the hair covers it).
DENSITY = {"face": 3.6, "ear_r": 3.2, "ear_l": 3.2, "eye_r": 6.0, "eye_l": 6.0, "scalp": 1.5}
ISLAND_ORDER = ["face", "scalp", "ear_r", "ear_l", "eye_r", "eye_l"]
GAP = 0.012           # between islands (UV units)
HEAD_TEX = F.HEAD_TEX
HAIR_TEX = F.HAIR_TEX
SKIN_TRIS = 5200      # the body below the head, after decimation (the head isn't cut down)
EYE_Y_ANAT = 1.655    # make_people's fit puts the eyes here


# --- The base head and its layout ---------------------------------------------------------------

class Base:
    """The base head (base targets and forms, no archetype), in body space before the warp, with
    everything the layout and the stamps need: per vertex positions, normals and regions."""

    def __init__(self, env, factory):
        p = F.make_person("base", {}, env, factory, base_only=True)
        self.p = p
        v = p.v
        n = len(v)
        self.v = v
        body = np.zeros(n)
        body[sorted({i for f in p.body_faces for i in f[0]})] = 1.0
        self.body = body
        self.normals = F.vertex_normals(v, p.body_faces)
        J = p.j
        self.eye = {"r": J["r-eye"], "l": J["l-eye"]}
        self.eye_y = float((J["r-eye"][1] + J["l-eye"][1]) / 2)
        self.neck_y = float(J["neck"][1])
        reg = lambda name: F.region(name, n, body)
        self.ear = {s: F.smoothstep(0.1, 0.3, reg("ears/%s-ear-wing-incr" % s)) for s in "rl"}
        self.nose = np.maximum(reg("nose/nose-scale-horiz-incr"), reg("nose/nose-nostrils-width-incr"))
        self.nostril = reg("nose/nose-nostrils-width-incr")
        wu = reg("mouth/mouth-upperlip-volume-incr")
        wl = reg("mouth/mouth-lowerlip-volume-incr")
        self.lip_u, self.lip_l = wu, wl
        self.lip_seam = F.lip_seam(wu, wl, p.body_faces)
        self.lid = {s: reg("eyes/%s-eye-eyefold-down" % s) for s in "rl"}
        self.eye_faces = {"r": p.groups["helper-r-eye"], "l": p.groups["helper-l-eye"]}
        hv = v[:, 1] > self.neck_y + 0.04
        self.centre = np.array([0.0, float(v[hv, 1].mean()), float(v[hv & (body > 0), 2].mean())])
        # The head's outside (the shells stay on it): not the insides of the mouth and eye sockets.
        out = ((v - self.centre) * self.normals).sum(1) / np.maximum(np.linalg.norm(v - self.centre, axis=1), 1e-9)
        self.outside = F.smoothstep(0.05, 0.25, out) * body
        # The mouth: the middle of the lips' seam.
        s = self.lip_seam > 0.6
        self.mouth = (v[s] * self.lip_seam[s, None]).sum(0) / self.lip_seam[s].sum()
        self.mouth_w = float(np.ptp(v[self.lip_seam > 0.3, 0]))
        # The nostrils' middles (as shape_base cut them).
        self.nostrils = []
        for sx in (1.0, -1.0):
            sel = (self.nostril > 0.15) & (self.normals[:, 1] < -0.3) & (v[:, 0] * sx > 0.0035)
            self.nostrils.append((v[sel] * self.nostril[sel, None]).sum(0) / self.nostril[sel].sum())
        # The head's faces (a little below the neck joint: every man's head faces are among them).
        lo = self.neck_y - 0.04
        self.head_faces = [f for f in p.body_faces if (v[f[0], 1] > lo).all()]
        self.eye_ids = {s: sorted({i for f in self.eye_faces[s] for i in f[0]}) for s in "rl"}

    def island_of(self, fv):
        v = self.v
        c = v[fv].mean(0)
        fn = np.cross(v[fv[1]] - v[fv[0]], v[fv[2]] - v[fv[0]])
        fn = fn / max(np.linalg.norm(fn), 1e-12)
        for s in "rl":
            if self.ear[s][fv].mean() > 0.5:
                return "ear_" + s
        ey = self.eye_y
        in_oval = abs(c[0]) < 0.072 and ey - 0.14 < c[1] < ey + 0.085 and c[2] < self.centre[2]
        if in_oval and (fn[2] < -0.2 or self.nose[fv].mean() > 0.2 or self.lip_u[fv].mean() + self.lip_l[fv].mean() > 0.2):
            return "face"
        return "scalp"


def _mesh_from(v, faces, name):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([mp.to_blender(p) for p in v], [], [list(f) for f in faces])
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def head_layout(base):
    """{face's vertex ids: [(u, v) per corner]} (image convention: v down) and the island rects.

    The base head's faces are cut into islands (face, scalp, each ear, each eyeball), unwrapped
    by Blender (angle based, so the nose's underside and the ear's folds open out), each turned
    upright, scaled to its density and packed in a fixed order."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    faces = [f[0] for f in base.head_faces] + [f[0] for s in "rl" for f in base.eye_faces[s]]
    island = [base.island_of(f) for f in faces[:len(base.head_faces)]]
    for s in "rl":
        island += ["eye_" + s] * len(base.eye_faces[s])
    obj = _mesh_from(base.v, faces, "base_head")
    me = obj.data
    # Seams: between islands, and down the back of the head (the scalp opens there).
    face_of_edge = {}
    for pi, poly in enumerate(me.polygons):
        for ek in poly.edge_keys:
            face_of_edge.setdefault(ek, []).append(pi)
    v = base.v
    for e in me.edges:
        a, b = e.vertices
        fs = face_of_edge.get(tuple(sorted((a, b))), [])
        isl = {island[f] for f in fs}
        back = abs(v[a][0]) < 1e-5 and abs(v[b][0]) < 1e-5 and v[a][2] > base.centre[2] and v[b][2] > base.centre[2]
        e.use_seam = len(isl) > 1 or (back and "scalp" in isl)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.unwrap(method="ANGLE_BASED", margin=0.0)
    bpy.ops.object.mode_set(mode="OBJECT")
    uvl = me.uv_layers.active.data
    corners = [[tuple(uvl[li].uv) for li in poly.loop_indices] for poly in me.polygons]
    # Pieces: faces of one island joined across edges that aren't seams (an island can come out
    # in several: the eye sockets' insides and the mouth's lie apart from the face).
    parent = list(range(len(faces)))
    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    seam = {tuple(sorted(e.vertices)) for e in me.edges if e.use_seam}
    for ek, fs in face_of_edge.items():
        if len(fs) == 2 and tuple(sorted(ek)) not in seam and island[fs[0]] == island[fs[1]]:
            parent[root(fs[0])] = root(fs[1])
    pieces = {}
    for i in range(len(faces)):
        pieces.setdefault(root(i), []).append(i)
    # Each piece turned so up on him is up in the picture, scaled to its island's density; the
    # eyeballs projected straight from the front instead (a closed ball doesn't unwrap).
    placed = []
    for ids in pieces.values():
        name = island[ids[0]]
        p3 = np.array([v[x] for i in ids for x in faces[i]])
        if name.startswith("eye_"):
            for i in ids:
                corners[i] = [(-v[x][0] * DENSITY[name], v[x][1] * DENSITY[name]) for x in faces[i]]
        else:
            uv = np.array([c for i in ids for c in corners[i]])
            A = np.c_[uv - uv.mean(0), np.ones(len(uv))]
            g = np.linalg.lstsq(A, p3[:, 1], rcond=None)[0][:2]
            rot = -math.atan2(g[1], g[0]) + math.pi / 2
            R = np.array([[math.cos(rot), -math.sin(rot)], [math.sin(rot), math.cos(rot)]])
            a3 = sum(_area3(v[faces[i]]) for i in ids)
            a2 = sum(_area2(np.array(corners[i])) for i in ids)
            k = DENSITY[name] * math.sqrt(a3 / max(a2, 1e-12))
            for i in ids:
                corners[i] = [tuple(R @ (np.array(c) - uv.mean(0)) * k) for c in corners[i]]
            # His right on the picture's left, as you face him (the unwrap may mirror it).
            q = np.array([c for i in ids for c in corners[i]])
            if np.ptp(p3[:, 0]) > 0.01 and np.polyfit(q[:, 0], p3[:, 0], 1)[0] > 0 and name == "face":
                for i in ids:
                    corners[i] = [(-c[0], c[1]) for c in corners[i]]
        q = np.array([c for i in ids for c in corners[i]])
        placed.append((ISLAND_ORDER.index(name), -len(ids), ids, q.min(0), q.max(0)))
    placed.sort(key=lambda t: (t[0], t[1]))
    # Pack: shelves, in order (the face first), image convention (v down from the top-left).
    scale = 1.0
    while True:
        rects, x, y, shelf, ok = [], GAP, GAP, 0.0, True
        for _o, _n, ids, lo, hi in placed:
            w, h = (hi - lo) * scale
            if x + w > 1 - GAP:
                x, y, shelf = GAP, y + shelf + GAP, 0.0
            if y + h > 1 - GAP or w > 1 - 2 * GAP:
                ok = False
                break
            rects.append((x, y, w, h))
            x += w + GAP
            shelf = max(shelf, h)
        if ok:
            break
        scale *= 0.97
    table, named = {}, {}
    for (_o, _n, ids, lo, hi), (rx, ry, rw, rh) in zip(placed, rects):
        name = island[ids[0]]
        if name not in named or rw * rh > named[name][2] * named[name][3]:
            named[name] = (rx, ry, rw, rh)   # an island's largest piece is its rect
        for i in ids:
            table[tuple(faces[i])] = [((c[0] - lo[0]) * scale + rx, (hi[1] - c[1]) * scale + ry) for c in corners[i]]
    bpy.data.objects.remove(obj)
    return table, named, island, faces, scale


def _area3(p):
    a = 0.5 * np.linalg.norm(np.cross(p[1] - p[0], p[2] - p[0]))
    if len(p) == 4:
        a += 0.5 * np.linalg.norm(np.cross(p[2] - p[0], p[3] - p[0]))
    return a


def _area2(p):
    x, y = p[:, 0], p[:, 1]
    return 0.5 * abs(np.dot(x, np.roll(y, 1)) - np.dot(y, np.roll(x, 1)))


# --- Rasterising into UV space --------------------------------------------------------------------

def raster(table, faces, values, size):
    """Interpolate per-vertex `values` (n, k) over the faces' UVs into a (size, size, k) map, and
    a mask of the texels any face covers."""
    k = values.shape[1]
    out = np.zeros((size, size, k))
    mask = np.zeros((size, size), bool)
    for fv in faces:
        uvs = table.get(tuple(fv))
        if uvs is None:
            continue
        tris = [(0, 1, 2)] + ([(0, 2, 3)] if len(fv) == 4 else [])
        for t in tris:
            P = np.array([uvs[i] for i in t]) * size
            val = values[[fv[i] for i in t]]
            x0, x1 = int(max(0, math.floor(P[:, 0].min()) - 1)), int(min(size - 1, math.ceil(P[:, 0].max()) + 1))
            y0, y1 = int(max(0, math.floor(P[:, 1].min()) - 1)), int(min(size - 1, math.ceil(P[:, 1].max()) + 1))
            if x1 < x0 or y1 < y0:
                continue
            gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
            (ax, ay), (bx, by), (cx, cy) = P
            d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
            if abs(d) < 1e-12:
                continue
            w0 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / d
            w1 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / d
            w2 = 1 - w0 - w1
            pad = 1.5 / max(abs(d) ** 0.5, 1e-6)   # a texel and a half past the edge (no seams)
            inside = (w0 >= -pad) & (w1 >= -pad) & (w2 >= -pad)
            sub = out[y0:y1 + 1, x0:x1 + 1]
            sm = mask[y0:y1 + 1, x0:x1 + 1]
            fill = inside & ~sm | ((w0 >= 0) & (w1 >= 0) & (w2 >= 0))
            sub[fill] = (w0[fill, None] * val[0] + w1[fill, None] * val[1] + w2[fill, None] * val[2])
            sm[fill] = True
    return out, mask


# --- The shells: hair, moustache, beard -------------------------------------------------------------

def _azimuth(base, v):
    """Degrees round the head from straight ahead (0) to the back (180), either side."""
    return np.degrees(np.abs(np.arctan2(v[:, 0], -(v[:, 2] - base.centre[2]))))


def hair_mask(base, style):
    """Which base vertices the hair covers (0..1), from the style's hairline round the head."""
    v = base.v
    az = _azimuth(base, v)
    dy = v[:, 1] - base.eye_y
    pts = np.array(style["line"], float)
    line = np.interp(az, pts[:, 0], pts[:, 1])
    m = F.smoothstep(-0.004, 0.004, dy - line)
    if "crown" in style:   # a bald top: hair only round the sides and back
        m *= 1.0 - F.smoothstep(style["crown"] - 0.004, style["crown"] + 0.004, dy)
    ears = np.maximum(base.ear["r"], base.ear["l"])
    m *= 1.0 - F.smoothstep(0.02, 0.15, ears)
    return m * base.outside


def moustache_mask(base, style):
    v = base.v
    m = base.mouth
    x = np.abs(v[:, 0] - m[0])
    dy = v[:, 1] - m[1]
    w = style["width"]
    top = style.get("top", 0.013) - 0.22 * x + style.get("up", 0.0) * F.smoothstep(0.75 * w, w, x)
    bottom = -style["below"] - style.get("droop", 0.0) * F.smoothstep(0.45 * w, 1.0 * w, x) \
        + style.get("up", 0.0) * F.smoothstep(0.7 * w, w, x)
    front = v[:, 2] < base.centre[2] - 0.03
    inside = (x < w) & (dy < top) & (dy > bottom) & front
    edge = np.minimum.reduce([w - x, top - dy, dy - bottom])
    return np.where(inside, F.smoothstep(0.0, 0.002, edge), 0.0) * base.outside


def beard_mask(base):
    """The jaw, chin and cheeks below the cheekbones, round to the ears, down under the jaw."""
    v = base.v
    az = _azimuth(base, v)
    dy = v[:, 1] - base.eye_y
    top = np.interp(az, [0, 25, 50, 85, 100], [-0.045, -0.04, -0.035, -0.02, -0.02])
    m = F.smoothstep(0.0, 0.006, top - dy) * (1.0 - F.smoothstep(95, 105, az))
    m *= F.smoothstep(base.neck_y + 0.0, base.neck_y + 0.03, v[:, 1])   # not down the neck
    lips = np.maximum(base.lip_u, base.lip_l)
    m *= 1.0 - F.smoothstep(0.15, 0.4, lips)
    return m * base.outside


def shell(person, base, mask, thickness, faces, droop=0.0, name=""):
    """A shell standing `thickness` off the man's skin where `mask` (base vertex ids) is set, with a
    wall round its edge back to the skin. Returns (positions, weights, faces, uv kind per face)."""
    v = person.v
    n = F.vertex_normals(v, person.body_faces)
    keep = [f for f in faces if (mask[f[0]] > 0.5).all()]
    if not keep:
        return None
    ids = sorted({i for f in keep for i in f[0]})
    # How far each vertex is inside the shell's edge, in edges (thin at the edge, full inside).
    edge_count = {}
    for f in keep:
        fv = f[0]
        for i in range(len(fv)):
            e = tuple(sorted((fv[i], fv[(i + 1) % len(fv)])))
            edge_count[e] = edge_count.get(e, 0) + 1
    rim = {a for e, c in edge_count.items() if c == 1 for a in e}
    nbr = {i: set() for i in ids}
    for e in edge_count:
        nbr[e[0]].add(e[1])
        nbr[e[1]].add(e[0])
    hops = {i: 0 for i in rim}
    frontier = list(rim)
    while frontier:
        nxt = []
        for i in frontier:
            for j in nbr[i]:
                if j not in hops:
                    hops[j] = hops[i] + 1
                    nxt.append(j)
        frontier = nxt
    P, W, idx = [], [], {}
    for i in ids:
        full = F.smoothstep(0.0, 2.5, float(hops.get(i, 3)))
        t = thickness * (0.25 + 0.75 * full) * (mask[i] if mask[i] < 1 else 1.0)
        d = n[i] + np.array([0.0, -droop, 0.0])
        d /= np.linalg.norm(d)
        idx[i] = len(P)
        P.append(v[i] + d * t)
        W.append(person.W[i])
    F_out, kind = [], []
    for f in keep:
        F_out.append([idx[i] for i in f[0]])
        kind.append("top")
    # The wall round the edge, from the shell back down to just off the skin.
    for (a, b), c in edge_count.items():
        if c != 1:
            continue
        ia = len(P)
        P.append(v[a] + n[a] * 0.0005)
        W.append(person.W[a])
        ib = len(P)
        P.append(v[b] + n[b] * 0.0005)
        W.append(person.W[b])
        F_out.append([idx[a], idx[b], ib, ia])
        kind.append("wall")
    return np.array(P), np.array(W), F_out, kind


def shells(person, base, spec, factory):
    """Every shell the man wears, in one piece (the `hair` shape): hair, moustache, beard."""
    out = []
    faces = person.body_faces
    hs = factory["hair"].get(spec.get("hair", "none"))
    if hs:
        out.append(("hair", shell(person, base, hair_mask(base, hs), hs["thickness"], faces)))
    ms = factory["moustache"].get(spec.get("moustache", "none"))
    if ms:
        out.append(("moustache", shell(person, base, moustache_mask(base, ms), ms["thickness"], faces, droop=0.8)))
    bs = factory["beard"].get(spec.get("beard", "none"))
    if bs and bs.get("shell", 0) > 0:
        out.append(("beard", shell(person, base, beard_mask(base), bs["shell"], faces, droop=0.5)))
    return [(k, s) for k, s in out if s is not None]


# --- Textures -------------------------------------------------------------------------------------

def _hex(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def _noise(rng, size, cell):
    """Smooth value noise (size x size), cells of `cell` texels."""
    n = max(2, size // cell + 2)
    g = rng.random((n, n))
    y, x = np.mgrid[0:size, 0:size] / cell
    x0, y0 = x.astype(int), y.astype(int)
    fx, fy = x - x0, y - y0
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = g[y0, x0], g[y0, x0 + 1]
    c, d = g[y0 + 1, x0], g[y0 + 1, x0 + 1]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def paint_head(base, table, rects, spec, factory, seed):
    """His head's texture: skin tone, then the details stamped where the base head has them. In
    flat even light (the game lights him); every stamp is placed by the base head, so it lands on
    the same part of every man."""
    size = HEAD_TEX
    v = base.v
    nv = len(v)
    vals = np.zeros((nv, 12))
    vals[:, 0:3] = v
    vals[:, 3:6] = base.normals
    vals[:, 6] = base.lip_seam
    vals[:, 7] = np.maximum(base.lip_u, base.lip_l)
    vals[:, 8] = beard_mask(base)
    vals[:, 9] = np.maximum(base.ear["r"], base.ear["l"])
    vals[:, 10] = np.maximum(base.lid["r"], base.lid["l"])
    vals[:, 11] = base.nose
    faces = [f[0] for f in base.head_faces] + [f[0] for s in "rl" for f in base.eye_faces[s]]
    M, cover = raster(table, faces, vals, size)
    P, N = M[..., 0:3], M[..., 3:6]
    rng = np.random.default_rng(seed)
    skin = _hex(spec.get("skin", "#b88866"))
    wear = float(spec.get("wear", 0.5))
    img = np.ones((size, size, 3)) * skin
    # Skin: a faint mottle, warmer and redder on the nose, cheeks and ears with wear.
    mott = _noise(rng, size, 24) * 0.6 + _noise(rng, size, 7) * 0.4
    img *= (0.94 + 0.12 * mott)[..., None]
    ey = base.eye_y
    cheeks = np.exp(-(((np.abs(P[..., 0]) - 0.035) / 0.018) ** 2 + ((P[..., 1] - ey + 0.03) / 0.02) ** 2))
    flush = np.clip(M[..., 11] * 0.8 + cheeks * 0.6 + M[..., 9] * 0.3, 0, 1) * (0.25 + 0.5 * wear)
    img = img * (1 - flush[..., None] * 0.25) + flush[..., None] * 0.25 * np.array([0.72, 0.38, 0.3])
    dark = lambda amount, mask_, colour=None: _over(img, mask_ * amount, colour if colour is not None else skin * 0.35)
    # Stubble or the beard's colour under a shell: mottled, darker with more of it.
    beard = factory["beard"].get(spec.get("beard", "none")) or {}
    hair_c = _hex(spec.get("hair_colour", "#2e231c"))
    if beard.get("paint"):
        speck = (_noise(rng, size, 3) > 0.45).astype(float) * 0.6 + _noise(rng, size, 9) * 0.4
        dark(beard["paint"] * 0.55, M[..., 8] * speck, hair_c * 0.9 + skin * 0.1)
    # Lips: a muted red-brown, the line between them dark.
    _over(img, F.smoothstep(0.25, 0.6, M[..., 7]) * 0.45, np.array([0.55, 0.3, 0.27]))
    dark(0.85, F.smoothstep(0.75, 0.95, M[..., 6]), np.array([0.18, 0.08, 0.07]))
    # The nostrils' dark.
    for c in base.nostrils:
        r = np.linalg.norm(P - c, axis=-1)
        dark(0.9, (1 - F.smoothstep(0.0022, 0.0042, r)) * (N[..., 1] < 0.2), np.array([0.12, 0.06, 0.05]))
    # The ear's bowl and the fold behind it.
    bowl = np.zeros((size, size))
    for s in "rl":
        c = base.v[base.ear[s] > 0.5].mean(0)
        bowl = np.maximum(bowl, M[..., 9] * (1 - F.smoothstep(0.004, 0.014, np.linalg.norm(P - c, axis=-1))))
    dark(0.55, bowl)
    # Eyes: the lid line along the top of each opening, a lighter one under it; the brows.
    brows = float(spec.get("brows", 1.0))
    for s, e in base.eye.items():
        dx, dy = P[..., 0] - e[0], P[..., 1] - e[1]
        side = np.sign(e[0])
        # The opening as an ellipse; the upper lid line just above it.
        ex, eh = 0.0145, 0.0058
        rr = np.sqrt((dx / ex) ** 2 + (np.maximum(dy, 0) / eh) ** 2 + (np.minimum(dy, 0) / (eh * 0.9)) ** 2)
        upper = (dy > -0.001) & (P[..., 2] < e[2] + 0.02)
        dark(0.85, (1 - F.smoothstep(0.08, 0.22, np.abs(rr - 1.05))) * upper, np.array([0.15, 0.09, 0.07]))
        lower = (dy < 0) & (P[..., 2] < e[2] + 0.02)
        dark(0.35, (1 - F.smoothstep(0.06, 0.2, np.abs(rr - 1.08))) * lower)
        # The brow: an arc over the eye, thick at the inside, thinning and dropping at the outside.
        t = np.clip((dx * side + 0.016) / 0.044, 0, 1)
        centre_y = 0.0175 + 0.004 * np.sin(t * math.pi) - 0.004 * t
        thick = (0.0055 - 0.003 * t) * (0.6 + 0.4 * brows)
        inband = (np.abs(dy - centre_y) < thick / 2) & (dx * side > -0.017) & (dx * side < 0.03) & (P[..., 2] < e[2])
        hairs = 0.75 + 0.25 * _noise(rng, size, 2)
        _over(img, inband * hairs * min(1.0, 0.65 + 0.35 * brows), hair_c * 0.85)
        # Lines at the eye's outer corner and across the brow, with wear.
        if wear > 0.3:
            crow = (dx * side > 0.016) & (dx * side < 0.026) & (np.abs(dy) < 0.008)
            ln = (np.abs(np.sin((dy * 900) + dx * side * 300)) > 0.92)
            dark(0.25 * wear, crow * ln)
    if wear > 0.3:
        fore = (P[..., 1] > ey + 0.03) & (P[..., 1] < ey + 0.06) & (np.abs(P[..., 0]) < 0.04) & (N[..., 2] < -0.5)
        ln = np.abs(np.sin((P[..., 1] - ey) * 2 * math.pi / 0.009)) > 0.94
        dark(0.22 * wear, fore * ln)
    # The eyeballs: a warm white, the iris and pupil looking straight ahead. Each is projected
    # from the front into its own square, so the iris is the middle of the square (its back half
    # lies under its front: the same colours, hidden).
    iris_c = _hex(spec.get("iris", "#4a3423"))
    yy, xx = np.mgrid[0:size, 0:size] + 0.5
    for s in "rl":
        x, y, w, h = rects["eye_" + s]
        r = np.hypot(xx / size - (x + w / 2), yy / size - (y + h / 2)) / (w / 2)
        on = (r < 1.05) & cover
        col = np.where((r < 0.46)[..., None], iris_c, np.array([0.8, 0.76, 0.68]))
        col = np.where(((r < 0.46) & (r > 0.37))[..., None], iris_c * 0.55, col)
        col = np.where((r < 0.17)[..., None], np.array([0.03, 0.03, 0.03]), col)
        # A shade under the upper lid, across the top of the white.
        lid = (yy / size < y + h * 0.36) & (r >= 0.46)
        col = np.where(lid[..., None], col * 0.78, col)
        img[on] = col[on]
    img[~cover] = skin
    return np.clip(img, 0, 1)


def _island_map(rects, size):
    m = np.full((size, size), -1)
    for k, (x, y, w, h) in rects.items():
        m[int(y * size):int((y + h) * size) + 1, int(x * size):int((x + w) * size) + 1] = ISLAND_ORDER.index(k)
    return m


def _over(img, a, colour):
    a = np.clip(a, 0, 1)[..., None]
    img[:] = img * (1 - a) + a * colour


def shell_uv(base_centre, P, F_out, kind):
    """Hair texture UVs: round the head (u) by height (v), the walls on a dark strip at the bottom."""
    uv = []
    for f, k in zip(F_out, kind):
        if k == "wall":
            uv.append([(0.1 + 0.8 * (j % 2), 0.97) for j in range(len(f))])
            continue
        c = P[f] - base_centre
        az = np.arctan2(c[:, 0], -c[:, 2])
        if np.ptp(az) > math.pi:   # across the back
            az = np.where(az < 0, az + 2 * math.pi, az)
        el = np.arctan2(c[:, 1], np.hypot(c[:, 0], c[:, 2]))
        uv.append([((a / (2 * math.pi) + 0.5) % 1.0001, 0.92 - (e / math.pi + 0.5) * 0.9) for a, e in zip(az, el)])
    return uv


def paint_hair(spec, seed):
    """The hair texture: his hair colour in strands, darker at the roots, the wall strip dark."""
    size = HAIR_TEX
    rng = np.random.default_rng(seed)
    c = _hex(spec.get("hair_colour", "#2e231c"))
    strands = _noise(rng, size, 3)
    strands = np.repeat(strands[:1, :], size, 0) * 0.6 + _noise(rng, size, 5) * 0.4
    img = c * (0.72 + 0.5 * strands)[..., None]
    img[int(0.94 * size):] = c * 0.4
    return np.clip(img, 0, 1)


def save_png(img, path):
    from PIL import Image
    Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8)).save(path)


# --- The man --------------------------------------------------------------------------------------

_cache = {}


def build(pid, spec, env, factory):
    t0 = time.time()
    if "base" not in _cache:
        base = Base(env, factory)
        _cache["base"] = base
        _cache["layout"] = head_layout(base)
    base = _cache["base"]
    table, rects, _isl, _faces, _scale = _cache["layout"]
    p = F.make_person(pid, spec, env, factory)
    p.run()
    rep = p.report
    rep["layout"] = {k: [round(x, 4) for x in r] for k, r in rects.items()}
    head_ids = p.region == "head"
    head_faces = [f for f in p.body_faces if head_ids[f[0]].all() and tuple(f[0]) in table]
    head_keys = {tuple(f[0]) for f in head_faces}
    skin_faces = [f for f in p.body_faces if tuple(f[0]) not in head_keys]
    head_faces += p.eye_faces
    rep["head_faces_off_layout"] = sum(1 for f in p.body_faces if head_ids[f[0]].all() and tuple(f[0]) not in table)
    sh = shells(p, base, spec, factory)
    # Textures.
    seed = sum(ord(c) for c in pid)
    head_png = os.path.join(mp.OUT, "%s_head.png" % pid)
    save_png(paint_head(base, table, rects, spec, factory, seed), head_png)
    hair_png = os.path.join(mp.OUT, "%s_hair.png" % pid)
    if sh:
        save_png(paint_hair(spec, seed), hair_png)
    # Blender.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bones = env["bones"]
    arm_data = bpy.data.armatures.new("Skeleton")
    arm = bpy.data.objects.new("Skeleton", arm_data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for b in bones:
        c = np.array(env["segments"][b]["center"])
        eb = arm_data.edit_bones.new(b)
        eb.head = mp.to_blender(c)
        eb.tail = mp.to_blender(c + np.array([0, 0.05, 0]))
    for b in bones:
        parent = env["segments"][b]["parent"]
        if parent:
            arm_data.edit_bones[b].parent = arm_data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")

    def make(name, P, W, faces, uvs):
        verts, loops_uv, polys, key_index = [], [], [], {}
        for fv, fuv in zip(faces, uvs):
            poly = []
            for i, (u, vv) in zip(fv, fuv):
                k = (i, round(u, 5), round(vv, 5))
                if k not in key_index:
                    key_index[k] = len(verts)
                    verts.append(i)
                    loops_uv.append((u, vv))
                poly.append(key_index[k])
            polys.append(poly)
        mesh = bpy.data.meshes.new("body_" + name)
        mesh.from_pydata([mp.to_blender(P[i]) for i in verts], [], polys)
        uv_layer = mesh.uv_layers.new(name="UVMap")
        for poly in mesh.polygons:
            poly.use_smooth = True
            for li in poly.loop_indices:
                u, vv = loops_uv[mesh.loops[li].vertex_index]
                uv_layer.data[li].uv = (u, 1.0 - vv)
        obj = bpy.data.objects.new("body_" + name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        for bname in bones:
            obj.vertex_groups.new(name=bname)
        for new_i, old_i in enumerate(verts):
            for b, w in enumerate(W[old_i]):
                if w > 0.001:
                    obj.vertex_groups[b].add([new_i], float(w), "REPLACE")
        return obj

    skin = make("skin", p.v, p.W, [f[0] for f in skin_faces],
                [[(p.uv[t][0] * 1.8, (1.0 - p.uv[t][1]) * 1.8) for t in f[1]] for f in skin_faces])
    head = make("head", p.v, p.W, [f[0] for f in head_faces], [table[tuple(f[0])] for f in head_faces])
    objs = [skin, head]
    if sh:
        P_all, W_all, F_all, K_all = [], [], [], []
        off = 0
        for _k, (P, W, Fo, kind) in sh:
            P_all.append(P)
            W_all.append(W)
            F_all += [[i + off for i in f] for f in Fo]
            K_all += kind
            off += len(P)
        P_all, W_all = np.concatenate(P_all), np.concatenate(W_all)
        hair = make("hair", P_all, W_all, F_all, shell_uv(_head_centre(p), P_all, F_all, K_all))
        objs.append(hair)
    # Garments, as make_people builds them.
    p.normals = clothes.vertex_normals(p.v, p.body_faces)
    outfit = spec.get("outfit", {})
    garments = clothes.make_all(p, outfit)
    cloth_objs = {n: clothes.to_object(g, mp.to_blender, bones) for n, g in garments.items()}
    if "coat" in cloth_objs:
        clothes.drape(cloth_objs["coat"], garments["coat"], skin)
    rep["textures"] = {}
    for n, obj in cloth_objs.items():
        clothes.unwrap(obj)
        png = os.path.join(mp.OUT, "%s_%s.png" % (pid, n))
        over = [o for m, o in cloth_objs.items() if clothes.OFFSET.get(m, 0.0) > clothes.OFFSET.get(n, 0.0)]
        size = clothes.bake_texture(obj, clothes.hex_colour(outfit[n]), os.path.abspath(png), seed=len(n) * 7 + 3,
                                    style="wool" if n in ("coat", "vest", "trousers") else "cotton", over=over)
        rep["textures"][n] = size
    for n, obj in cloth_objs.items():
        clothes.decimate(obj, clothes.BUDGET.get(n, 1000))
    tris = sum(len(pp.vertices) - 2 for pp in skin.data.polygons)
    mod = skin.modifiers.new("decimate", "DECIMATE")
    mod.ratio = min(1.0, SKIN_TRIS / max(tris, 1))
    mod.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = skin
    bpy.ops.object.modifier_apply(modifier="decimate")
    layers = dict(cloth_objs)
    layers["skin"] = skin
    clothes.separate(layers)
    for obj in objs + list(cloth_objs.values()):
        m = obj.modifiers.new("skeleton", "ARMATURE")
        m.object = arm
        obj.parent = arm
    rep["triangles"] = {o.name.split("_", 1)[1]: sum(len(pp.vertices) - 2 for pp in o.data.polygons)
                        for o in objs + list(cloth_objs.values())}
    # His eyes (the eyeballs' middles) and skin tone, for the game and the tests.
    rep["eyes"] = {}
    for s, side in (("r", "right"), ("l", "left")):
        ids = sorted({i for f in p.groups["helper-%s-eye" % s] for i in f[0]})
        rep["eyes"][side] = [round(float(x), 4) for x in p.v[ids].mean(0)]
    rep["skin_tone"] = [round(float(x), 4) for x in _hex(spec.get("skin", "#b88866"))]
    rep["shells"] = [k for k, _s in sh]
    rep["seconds"] = round(time.time() - t0, 1)
    mp.export(p)
    print("factory: built", pid, rep["triangles"], rep["seconds"], "s")


def _head_centre(p):
    hv = p.region == "head"
    return np.array([0.0, float(p.v[hv, 1].mean()), float(p.v[hv, 2].mean())])
