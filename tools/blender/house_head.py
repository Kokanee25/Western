"""The house head: a drawn face on a shared base head (docs/briefs/faces.md, a test).

    ~/bpyenv/bin/python tools/blender/house_head.py [--out=assets/people] [--views=DIR]

MakeHuman's base mesh (CC0, v1.2.0, fetched by fetch_makehuman.py) with the targets in
assets/people/house_head.json (MakeHuman's own, so the base topology stays and targets still
apply: the stylised ears, nose, brow and lips), warped into our body space as make_people.py does
and fitted so his eyes are the anatomy's (those of `stranger2s`, whose body and hat he wears).
Then:
  * a moustache shell of his own, proud of his lip with an overhang;
  * the house UV layout: each triangle on the plane square to the way it faces, the skin in
    squares of exactly SQUARE_M (8 mm), placed so the lip parting, the eyelids and the nostrils
    fall on rows and squares; each ear an island of its own; the moustache an island; the eyes on
    a finer grid (EYE_TEXELS a square) that nests in the skin's;
  * painted by script in UV space (no image model): a skin ramp, cavity and AO stepped into it,
    a one-step jitter, region tints, the glyph stamps, then the eyes;
  * one normal a square, from an exaggerated copy of the head (rims out, hollows in);
  * written as a whole man, `faces_test`: stranger2s's body (`body_skin`), his hat cut from his
    own head (`body_hat`, on his own texture) and this head (`body_head`) + <id>.json.
Repeatable: nothing is hand-edited.
"""
import json
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_people as mp  # noqa: E402

SPEC = "assets/people/house_head.json"
OUT = "assets/people"
# Whose body and hat he wears, and where that man's drawn irises are (our body space).
DONOR = "stranger2s"
SQUARE_M = 0.008
ID = "faces_test"
AO_NEAR = 0.012         # metres: an ear's hollow, a nostril, the lip's line, under the moustache
AO_FAR = 0.04           # the eye sockets, under the nose and the jaw
PER = 4                 # texels a square: the eyes are drawn on the 2 mm texels, the skin in squares
NECK_FROM = 1.47        # his neck goes down into the donor's collar to here
COLLAR_BELOW = 1.51     # the donor's head mesh under here that isn't skin is his collar
NECK_R = 0.075          # and no wider than this round it (his shoulders are the donor's)


def load_spec():
    return json.load(open(SPEC))


def read_glb(path):
    """A glb's meshes by node name: positions, normals, uvs, joints, weights, triangles (numpy), and
    its skin's joint names. Only what our fitted men are made of (one primitive a mesh)."""
    import struct
    b = open(path, "rb").read()
    n = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + n])
    binary = b[20 + n + 8:]
    kinds = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}
    width = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}

    def acc(i):
        a = j["accessors"][i]
        bv = j["bufferViews"][a["bufferView"]]
        off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        dt = kinds[a["componentType"]]
        k = width[a["type"]]
        arr = np.frombuffer(binary, dtype=dt, count=a["count"] * k, offset=off)
        return arr.reshape(a["count"], k) if k > 1 else arr

    out = {}
    for node in j["nodes"]:
        if "mesh" not in node:
            continue
        prim = j["meshes"][node["mesh"]]["primitives"][0]
        at = prim["attributes"]
        m = {"pos": acc(at["POSITION"]).astype(float), "tris": acc(prim["indices"]).astype(int).reshape(-1, 3)}
        for key, name in (("nrm", "NORMAL"), ("uv", "TEXCOORD_0"), ("joints", "JOINTS_0"), ("weights", "WEIGHTS_0")):
            if name in at:
                m[key] = acc(at[name]).astype(float if key != "joints" else int)
        out[node["name"]] = m
    joints = [j["nodes"][i]["name"] for i in j["skins"][0]["joints"]] if j.get("skins") else []
    return out, joints


def smoothstep(a, b, x):
    t = np.clip((np.asarray(x, float) - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


class Hat:
    """The donor's hat: the part of his head mesh above his brim's plane, and the plane."""
    AXIS_Z = 0.02          # his head's upright axis (x 0, z this), our body space
    BRIM_R = 0.14          # past this from the axis, it's brim

    def __init__(self, head):
        v = head["pos"]
        r = np.hypot(v[:, 0], v[:, 2] - self.AXIS_Z)
        brim = (r > self.BRIM_R) & (v[:, 1] > 1.6)
        A = np.c_[np.ones(brim.sum()), v[brim, 0], v[brim, 2]]
        self.plane, *_ = np.linalg.lstsq(A, v[brim, 1], rcond=None)
        h = self.above(v)
        c = v[head["tris"]].mean(1)
        hc = self.above(c)
        rc = np.hypot(c[:, 0], c[:, 2] - self.AXIS_Z)
        self.is_hat = (hc > -0.004) | ((rc > self.BRIM_R - 0.01) & (hc > -0.03))
        # The band: his head just under the brim, its distance from the axis by bearing.
        slab = (h > -0.02) & (h < -0.003) & (r < self.BRIM_R - 0.01)
        self.band_bearing = np.arctan2(v[slab, 0], v[slab, 2] - self.AXIS_Z)
        self.band_r = r[slab]

    def above(self, p):
        p = np.asarray(p, float)
        return p[..., 1] - (self.plane[0] + self.plane[1] * p[..., 0] + self.plane[2] * p[..., 2])

    def band(self, bins=24):
        """His band's radius in `bins` bearings (the median of each, gaps filled round)."""
        edges = np.linspace(-np.pi, np.pi, bins + 1)
        out = np.full(bins, np.nan)
        for i in range(bins):
            m = (self.band_bearing >= edges[i]) & (self.band_bearing < edges[i + 1])
            if m.sum() >= 3:
                out[i] = np.median(self.band_r[m])
        ok = np.isfinite(out)
        x = np.arange(bins)
        out = np.interp(x, x[ok], out[ok], period=bins)
        return (edges[:-1] + edges[1:]) / 2, out


# ---------------------------------------------------------------- the head's shape

class Head:
    def __init__(self, spec):
        env = json.load(open(mp.ENVELOPE))
        targets = dict(spec.get("targets", {}))
        targets.update(spec.get("style", {}))
        p = mp.Person("house_head", {"targets": targets}, env)
        p.warp()
        self.spec = spec
        self.person = p
        v = p.v.copy()
        # MakeHuman's eyeballs (helpers) tell us where his eyes are.
        eye_ids = {s: sorted({i for f in p.groups["helper-%s-eye" % s] for i in f[0]}) for s in "rl"}
        centres = {s: v[eye_ids[s]].mean(0) for s in "rl"}
        fronts = {s: v[eye_ids[s]][np.argmin(v[eye_ids[s]][:, 2])] for s in "rl"}
        # Onto the donor's eyes: his eyes' fronts on the drawn irises, the spacing his.
        donor = json.load(open(os.path.join(OUT, DONOR + ".json")))["eyes"]
        target = {"r": np.array(donor["right"]), "l": np.array(donor["left"])}
        mid_mh = (fronts["r"] + fronts["l"]) / 2
        mid_to = (target["r"] + target["l"]) / 2
        k = np.linalg.norm(target["r"] - target["l"]) / np.linalg.norm(fronts["r"] - fronts["l"])
        k *= float(spec.get("scale", 1.0))
        self.k = k
        self.v = (v - mid_mh) * k + mid_to
        self.eye_centres = {s: (centres[s] - mid_mh) * k + mid_to for s in "rl"}
        self.eye_ids = eye_ids
        self.uv_mh = p.uv
        self.groups = p.groups
        self.eye_y = float(mid_to[1])

    def fit_crown(self, hat, share):
        """His cranium eased out toward the hat's band, so the hat sits on him: by bearing, from
        nothing at his brow to `share` of the gap at the brim and all above it."""
        v = self.v
        bear_c, band = hat.band()
        rel_z = v[:, 2] - hat.AXIS_Z
        r = np.hypot(v[:, 0], rel_z)
        bear = np.arctan2(v[:, 0], rel_z)
        h = hat.above(v)
        slab = (h > -0.02) & (h < -0.003)
        bins = len(band)
        idx = np.clip(((bear + np.pi) / (2 * np.pi) * bins).astype(int), 0, bins - 1)
        mine = np.array([np.median(r[slab & (idx == i)]) if (slab & (idx == i)).sum() >= 3 else np.nan for i in range(bins)])
        ok = np.isfinite(mine)
        x = np.arange(bins)
        mine = np.interp(x, x[ok], mine[ok], period=bins)
        gain = np.clip(band * 0.97 / mine, 1.0, 1.35)
        g = np.interp(bear, bear_c, gain, period=2 * np.pi)
        w = smoothstep(self.eye_y + 0.012, self.eye_y + 0.012 + max(float(np.median(-h[np.abs(v[:, 1] - self.eye_y) < 0.005])) - 0.012, 0.01), v[:, 1]) * share
        k = 1.0 + (g - 1.0) * w
        self.v = np.c_[v[:, 0] * k, v[:, 1], hat.AXIS_Z + rel_z * k]


def triangles(faces):
    """MakeHuman's faces (quads and tris, (vertex ids, uv ids)) as triangles of vertex ids."""
    out = []
    for fv, _ft in faces:
        for i in range(1, len(fv) - 1):
            out.append((fv[0], fv[i], fv[i + 1]))
    return np.array(out)


# ---------------------------------------------------------------- his face's landmarks

# MediaPipe face mesh points (indices into its 478).
LM = {"nose_tip": 1, "subnasale": 2, "nostril_r": 98, "nostril_l": 327, "wing_r": 64, "wing_l": 294,
      "mouth_r": 61, "mouth_l": 291, "lip_top": 0, "lip_upper_in": 13, "lip_lower_in": 14, "lip_bottom": 17,
      "eye_r_top": 159, "eye_r_bottom": 145, "eye_r_out": 33, "eye_r_in": 133,
      "eye_l_top": 386, "eye_l_bottom": 374, "eye_l_out": 263, "eye_l_in": 362,
      "iris_r": 468, "iris_l": 473, "brow_r": 105, "brow_l": 334, "chin": 152}
LM_SIZE = 768
LM_HALF = 0.13
LM_CENTRE = (0.0, 1.62, 0.0)


def landmarks(v, tris, light=(0.0, 0.3, -1.0)):
    """MediaPipe's 478 face points on the head, in our body space (from a clay render in front of
    him and its depth), or None."""
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "paint"))
    import align
    from PIL import Image
    img, depth = render(v, tris, FRONT, size=LM_SIZE, centre=LM_CENTRE, half=LM_HALF, light=light)
    im = Image.fromarray((np.clip(img * 0.9 + 0.05, 0, 1) * 255).astype(np.uint8)).convert("RGB")
    pts = align.face_points(im, list(range(478)))
    if pts is None:
        return None
    out = []
    seen_y, seen_x = np.nonzero(np.isfinite(depth))
    for x, y in pts:
        xi, yi = int(np.clip(x, 0, LM_SIZE - 1)), int(np.clip(y, 0, LM_SIZE - 1))
        d = depth[yi, xi]
        if not np.isfinite(d):
            k = int(np.argmin((seen_x - x) ** 2 + (seen_y - y) ** 2))
            d = depth[seen_y[k], seen_x[k]]
        out.append(front_point(x, y, d))
    return np.array(out)


def front_point(x, y, d):
    """A pixel of the front render (LM_SIZE, LM_HALF) and its depth -> our body space."""
    r, u, f = [np.asarray(a, float) for a in FRONT]
    c = np.asarray(LM_CENTRE, float)
    return c + (x / LM_SIZE - 0.5) * 2 * LM_HALF * r + (0.5 - y / LM_SIZE) * 2 * LM_HALF * u + d * f


def front_depth(v, tris):
    """The face's depth seen from in front (LM_SIZE, LM_HALF): where along +Z it is at any x, y."""
    _img, depth = render(v, tris, FRONT, size=LM_SIZE, centre=LM_CENTRE, half=LM_HALF)
    return depth


def surface(depth, x, y):
    """Our body-space point on the face in front of (x, y) (metres), from the front depth."""
    px = (0.5 - (np.asarray(x) - LM_CENTRE[0]) / (2 * LM_HALF)) * LM_SIZE   # FRONT's right is -X
    py = (0.5 - (np.asarray(y) - LM_CENTRE[1]) / (2 * LM_HALF)) * LM_SIZE
    xi = np.clip(px.astype(int), 0, LM_SIZE - 1)
    yi = np.clip(py.astype(int), 0, LM_SIZE - 1)
    return np.stack([np.asarray(x, float), np.asarray(y, float), LM_CENTRE[2] + depth[yi, xi]], -1)


# ---------------------------------------------------------------- the moustache

def moustache(depth, L, spec):
    """A moustache as a shell of its own: a loft along his upper lip from past one corner of his
    mouth to past the other, `proud` metres off the lip at its middle, its lower edge hanging
    `overhang` below the parting and drooping `droop` at its ends, so it stands in front of his lip
    and casts a shadow on it. Returns points and triangles (our body space), and each point's
    (across, round) on the loft for its UVs."""
    proud = float(spec.get("proud", 0.010))
    over = float(spec.get("overhang", -0.004))     # its lower edge over the lip line, not on it
    droop = float(spec.get("droop", 0.014))
    reach = float(spec.get("reach", 0.006))
    sub = L[LM["subnasale"]]
    part = (L[LM["lip_upper_in"]] + L[LM["lip_lower_in"]]) / 2
    corner_x = abs(L[LM["mouth_r"]][0] - L[LM["mouth_l"]][0]) / 2
    half_w = corner_x + reach
    cols, k = 31, 9
    xs = np.linspace(-half_w, half_w, cols)
    wing_y = (L[LM["wing_r"]][1] + L[LM["wing_l"]][1]) / 2
    nose_half = abs(L[LM["wing_r"]][0] - L[LM["wing_l"]][0]) / 2
    rings = []
    for x in xs:
        a = min(abs(x) / half_w, 1.0)
        # Its top: under his nose, then along the foot of the nose's wings, then down the cheeks.
        under = smoothstep(nose_half * 0.4, nose_half * 1.1, abs(x))
        top_y = sub[1] - 0.0015 + (wing_y - sub[1]) * 0.4 * under - 0.012 * smoothstep(0.55, 1.0, a)
        # Its lower edge: over the lip, hanging at the corners (a walrus's).
        bot_y = part[1] - over - droop * smoothstep(0.35, 1.0, a) ** 1.4
        top_y = max(top_y, bot_y + 0.003)
        # Thick in two lobes either side of the philtrum, thinning to its tails.
        t = proud * (1.0 - a ** 2.5) * (1.0 - 0.18 * math.exp(-(x / 0.005) ** 2))
        ring = []
        for phi in np.linspace(0.0, math.pi, k):
            y = top_y + (bot_y - top_y) * (1 - math.cos(phi)) / 2
            y -= 0.002 * math.sin(phi) ** 2 * (phi / math.pi) * (1.0 - a)   # its front hangs a little lower
            sk = surface_one(depth, x, y)
            ring.append(sk + np.array([0.0, 0.0, -1.0]) * (0.0006 + t * math.sin(phi) ** 0.8))
        rings.append(ring)
    P = np.array(rings).reshape(-1, 3)
    tris = []
    for i in range(cols - 1):
        for j in range(k - 1):
            a, b, c, d = i * k + j, i * k + j + 1, (i + 1) * k + j, (i + 1) * k + j + 1
            tris += [(a, c, b), (b, c, d)]
    # The two ends closed.
    for i, flip in ((0, False), (cols - 1, True)):
        for j in range(1, k - 1):
            t = (i * k, i * k + j, i * k + j + 1)
            tris.append(t[::-1] if flip else t)
    return P, np.array(tris)


def surface_one(depth, x, y):
    return surface(depth, np.array([x]), np.array([y]))[0]


# ---------------------------------------------------------------- the head as one mesh

def target_ids(name, least=0.0):
    """The MakeHuman vertices a target moves (more than `least` decimetres)."""
    out = []
    for line in open(os.path.join(mp.MH, "targets", name + ".target")):
        if line[:1].isdigit():
            i, x, y, z = line.split()
            if math.sqrt(float(x) ** 2 + float(y) ** 2 + float(z) ** 2) > least:
                out.append(int(i))
    return out


def assemble(h, hat, spec):
    """The head's triangles (his skin under the hat and down his neck, his eyeballs, the
    moustache), each with its part, and his face's landmarks."""
    t = triangles(h.groups["body"])
    c = h.v[t].mean(1)
    neck_r = np.hypot(c[:, 0], c[:, 2] - 0.01)
    keep = (h.v[t, 1] > NECK_FROM).all(axis=1) & (hat.above(h.v[t]) < 0.01).all(axis=1) \
        & ((c[:, 1] > NECK_FROM + 0.045) | (neck_r < NECK_R))
    t = t[keep]
    eyes = {s: triangles(h.groups["helper-%s-eye" % s]) for s in "rl"}
    # Only the front of each eyeball (the rest is inside his head and would share its texels).
    for s_ in "rl":
        e = eyes[s_]
        fn = np.cross(h.v[e[:, 1]] - h.v[e[:, 0]], h.v[e[:, 2]] - h.v[e[:, 0]])
        eyes[s_] = e[fn[:, 2] < 0]
    lm_tris = np.concatenate([t, eyes["r"], eyes["l"]])
    L = landmarks(h.v, lm_tris)
    if L is None:
        raise RuntimeError("MediaPipe found no face on the house head")
    depth = front_depth(h.v, lm_tris)
    mv, mt = moustache(depth, L, spec.get("moustache", {}))
    ear_v = np.zeros(len(h.v), bool)
    for side in "rl":
        ear_v[target_ids("ears/%s-ear-flap-incr" % side)] = True
    V = np.concatenate([h.v, mv])
    F = np.concatenate([t, eyes["r"], eyes["l"], mt + len(h.v)])
    part = np.array(["skin"] * len(t) + ["eye_r"] * len(eyes["r"]) + ["eye_l"] * len(eyes["l"])
                    + ["moustache"] * len(mt), dtype=object)
    part[:len(t)][ear_v[t].all(axis=1)] = "ear"
    # Drop vertices nothing uses.
    used = np.unique(F)
    remap = -np.ones(len(V), int)
    remap[used] = np.arange(len(used))
    return {"V": V[used], "F": remap[F], "part": part, "L": L}


def vertex_normals(V, F):
    fn = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]])
    n = np.zeros_like(V)
    for k in range(3):
        np.add.at(n, F[:, k], fn)
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


# ---------------------------------------------------------------- the house UV layout

# Each plane: its (u, v) axes (metres on it; v up) and the way it faces.
PLANES = {
    "front": ((1, 0, 0), (0, 1, 0), (0, 0, -1)),
    "back": ((-1, 0, 0), (0, 1, 0), (0, 0, 1)),
    "right": ((0, 0, -1), (0, 1, 0), (1, 0, 0)),
    "left": ((0, 0, 1), (0, 1, 0), (-1, 0, 0)),
    "top": ((1, 0, 0), (0, 0, -1), (0, 1, 0)),
    "bottom": ((1, 0, 0), (0, 0, 1), (0, -1, 0)),
}
PLANE_NAMES = list(PLANES)


def assign_planes(V, F, part, face_front, settle):
    """Each triangle's plane: the face's within `face_front` degrees of straight ahead on the
    front, the rest the plane square to the way it faces most; the eyes and the moustache on the
    front; then `settle` passes in which a triangle takes its neighbours' plane where most of them
    are on another (the lines between planes ran ragged)."""
    fn = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]])
    fn /= np.maximum(np.linalg.norm(fn, axis=1, keepdims=True), 1e-12)
    dots = np.stack([fn @ np.array(PLANES[k][2], float) for k in PLANE_NAMES], 1)
    plane = np.argmax(dots, 1)
    front = PLANE_NAMES.index("front")
    plane[(dots[:, front] > math.cos(math.radians(face_front))) & (part != "ear")] = front
    plane[(part == "eye_r") | (part == "eye_l")] = front
    nb = neighbours(F)
    for _ in range(settle):
        new = plane.copy()
        for i, ns in enumerate(nb):
            if part[i] not in ("skin", "moustache") or not ns:
                continue
            same = [plane[j] for j in ns if part[j] == part[i]]
            if same and all(p == same[0] for p in same) and same[0] != plane[i] and dots[i, same[0]] > 0.2:
                new[i] = same[0]
        plane = new
    return plane


def neighbours(F):
    edges = {}
    for i, f in enumerate(F):
        for a, b in ((f[0], f[1]), (f[1], f[2]), (f[2], f[0])):
            edges.setdefault((min(a, b), max(a, b)), []).append(i)
    nb = [[] for _ in range(len(F))]
    for tri in edges.values():
        for i in tri:
            nb[i] += [j for j in tri if j != i]
    return nb


def islands(F, plane, part):
    """Connected triangles on one plane and of one part."""
    nb = neighbours(F)
    label = -np.ones(len(F), int)
    n = 0
    for s in range(len(F)):
        if label[s] >= 0:
            continue
        stack = [s]
        label[s] = n
        while stack:
            i = stack.pop()
            for j in nb[i]:
                if label[j] < 0 and plane[j] == plane[i] and part[j] == part[i]:
                    label[j] = n
                    stack.append(j)
        n += 1
    return label, n


def layout(mesh, spec):
    """The house UVs: per triangle corner, its place in the atlas in squares (col, row: row down),
    each island on whole squares of its plane's grid; the front's grid set so the lip parting is
    the middle of a row and the face's middle a line between columns (the nostrils then fall on
    squares either side). Returns per-corner (col, row), the atlas's size in squares and each
    triangle's plane and island."""
    V, F, part, L = mesh["V"], mesh["F"], mesh["part"], mesh["L"]
    plane = assign_planes(V, F, part, float(spec.get("face_front", 55)), int(spec.get("settle", 3)))
    label, n = islands(F, plane, part)
    part_y = float((L[LM["lip_upper_in"]][1] + L[LM["lip_lower_in"]][1]) / 2)
    origin = {k: np.zeros(2) for k in PLANE_NAMES}
    origin["front"] = np.array([0.0, part_y - SQUARE_M / 2])
    uv = np.zeros((len(F), 3, 2))
    boxes = []
    for i in range(n):
        tris = np.nonzero(label == i)[0]
        U, Vv, _N = [np.array(a, float) for a in PLANES[PLANE_NAMES[plane[tris[0]]]]]
        o = origin[PLANE_NAMES[plane[tris[0]]]]
        p = V[F[tris]]
        su = (p @ U - o[0]) / SQUARE_M
        sv = (p @ Vv - o[1]) / SQUARE_M
        c0, c1 = math.floor(su.min()), math.ceil(su.max())
        r0, r1 = math.floor(sv.min()), math.ceil(sv.max())
        uv[tris, :, 0] = su - c0
        uv[tris, :, 1] = r1 - sv
        boxes.append((i, max(c1 - c0, 1), max(r1 - r0, 1)))
    # Shelf-pack the islands, a square of room round each.
    area = sum((w + 1) * (h + 1) for _, w, h in boxes)
    width = max(int(math.ceil(math.sqrt(area * 1.15))), max(w for _, w, _h in boxes) + 2)
    place = {}
    x = y = 1
    shelf = 0
    for i, w, h in sorted(boxes, key=lambda b: (-b[2], -b[1])):
        if x + w + 1 > width:
            x, y = 1, y + shelf + 1
            shelf = 0
        place[i] = (x, y)
        x += w + 1
        shelf = max(shelf, h)
    height = y + shelf + 1
    for i, (px, py) in place.items():
        tris = label == i
        uv[tris, :, 0] += px
        uv[tris, :, 1] += py
    return uv, (width, height), plane, label


def raster(mesh, uv, size, per):
    """Which triangle each texel of the atlas shows and where (barycentrics): uv in squares,
    `per` texels a square. Returns tri (h, w) (-1 where none) and bary (h, w, 3)."""
    W, H = size[0] * per, size[1] * per
    tri = -np.ones((H, W), int)
    bary = np.zeros((H, W, 3))
    F = mesh["F"]
    for i in range(len(F)):
        xs, ys = uv[i, :, 0] * per, uv[i, :, 1] * per
        x0, x1 = int(max(math.floor(xs.min()), 0)), int(min(math.ceil(xs.max()), W - 1))
        y0, y1 = int(max(math.floor(ys.min()), 0)), int(min(math.ceil(ys.max()), H - 1))
        d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
        if abs(d) < 1e-12 or x1 < x0 or y1 < y0:
            continue
        py, px = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        cx, cy = px + 0.5, py + 0.5
        a = ((ys[1] - ys[2]) * (cx - xs[2]) + (xs[2] - xs[1]) * (cy - ys[2])) / d
        b = ((ys[2] - ys[0]) * (cx - xs[2]) + (xs[0] - xs[2]) * (cy - ys[2])) / d
        c = 1 - a - b
        m = np.minimum(np.minimum(a, b), c) >= -1e-6
        tri[py[m], px[m]] = i
        bary[py[m], px[m]] = np.stack([a[m], b[m], c[m]], -1)
    # Texels a triangle's edge only grazes: take the nearest covered texel's (so a square split by
    # a triangle edge isn't left half empty), within the island's own squares.
    return tri, bary


# ---------------------------------------------------------------- views for checking

def render(v, tris, cam, size=512, centre=None, half=0.13, light=(-0.4, 0.5, -0.75)):
    """An orthographic grey render of triangles, our body space: cam = (right, up, forward)."""
    r, u, f = [np.asarray(a, float) for a in cam]
    c = np.asarray(centre, float)
    rel = v - c
    x = (rel @ r / (2 * half) + 0.5) * size
    y = (0.5 - rel @ u / (2 * half)) * size
    z = rel @ f
    fn = np.cross(v[tris[:, 1]] - v[tris[:, 0]], v[tris[:, 2]] - v[tris[:, 0]])
    fn /= np.maximum(np.linalg.norm(fn, axis=1, keepdims=True), 1e-12)
    L = np.asarray(light, float)
    L /= np.linalg.norm(L)
    shade = np.clip(fn @ L, 0, 1) * 0.8 + 0.15
    depth = np.full((size, size), np.inf)
    img = np.zeros((size, size))
    for t, s in zip(tris, shade):
        xs, ys, zs = x[t], y[t], z[t]
        x0, x1 = int(max(xs.min(), 0)), int(min(xs.max() + 1, size - 1))
        y0, y1 = int(max(ys.min(), 0)), int(min(ys.max() + 1, size - 1))
        if x1 < x0 or y1 < y0:
            continue
        d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
        if abs(d) < 1e-9:
            continue
        py, px = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        cx, cy = px + 0.5, py + 0.5
        a = ((ys[1] - ys[2]) * (cx - xs[2]) + (xs[2] - xs[1]) * (cy - ys[2])) / d
        b = ((ys[2] - ys[0]) * (cx - xs[2]) + (xs[0] - xs[2]) * (cy - ys[2])) / d
        cc = 1 - a - b
        m = np.minimum(np.minimum(a, b), cc) >= -0.01
        zz = a * zs[0] + b * zs[1] + cc * zs[2]
        sub = depth[y0:y1 + 1, x0:x1 + 1]
        w = m & (zz < sub)
        sub[w] = zz[w]
        img[y0:y1 + 1, x0:x1 + 1][w] = s
    return img, depth


FRONT = ((-1, 0, 0), (0, 1, 0), (0, 0, 1))         # stood in front of him, looking along +Z
SIDE = ((0, 0, -1), (0, 1, 0), (-1, 0, 0))        # from his right (+X), looking along -X


# ---------------------------------------------------------------- Blender: AO and the export

WORK = "build/house_head"


def to_blender(p):
    p = np.asarray(p, float)
    return np.stack([p[..., 0], -p[..., 2], p[..., 1]], -1)


def blender_mesh(name, V, F, corner_uv, normals=None):
    """A Blender mesh from our-space points, triangles and per-corner UVs (Godot's: v down)."""
    import bpy
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(to_blender(V).tolist(), [], F.tolist())
    layer = mesh.uv_layers.new(name="UVMap")
    c = corner_uv.reshape(-1, 2)
    layer.data.foreach_set("uv", np.stack([c[:, 0], 1.0 - c[:, 1]], 1).reshape(-1))
    for poly in mesh.polygons:
        poly.use_smooth = True
    if normals is not None:
        mesh.normals_split_custom_set_from_vertices(to_blender(normals).tolist())
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def stage_blender():
    """AO of the head (near and far) into its atlas, and the glb: the donor's body and hat, this
    head, on our skeleton."""
    import bpy
    d = np.load(os.path.join(WORK, "mesh.npz"))
    V, F, cuv, W = d["V"], d["F"], d["cuv"], d["weights"]
    size = tuple(int(x) for x in d["texels"])
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.world = bpy.data.worlds.new("World")
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 96
    scene.render.bake.margin = 0
    head = blender_mesh("body_head", V, F, cuv, d["N"])
    out = []
    for metres in (AO_NEAR, AO_FAR):
        scene.world.light_settings.distance = metres
        img = bpy.data.images.new("ao", size[0], size[1], float_buffer=True)
        img.colorspace_settings.name = "Non-Color"
        mat = bpy.data.materials.new("bake")
        mat.use_nodes = True
        node = mat.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = img
        mat.node_tree.nodes.active = node
        head.data.materials.clear()
        head.data.materials.append(mat)
        bpy.ops.object.select_all(action="DESELECT")
        head.select_set(True)
        bpy.context.view_layer.objects.active = head
        bpy.ops.object.bake(type="AO")
        out.append(np.array(img.pixels[:]).reshape(size[1], size[0], 4)[::-1, :, 0])
    np.save(os.path.join(WORK, "ao.npy"), np.stack(out, -1))
    head.data.materials.clear()
    # The skeleton (make_people's: a bone a segment, at its centre, parented as the anatomy).
    env = json.load(open(mp.ENVELOPE))
    bones = env["bones"]
    arm_data = bpy.data.armatures.new("Skeleton")
    arm = bpy.data.objects.new("Skeleton", arm_data)
    scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for b in bones:
        c = np.array(env["segments"][b]["center"])
        eb = arm_data.edit_bones.new(b)
        eb.head = tuple(to_blender(c))
        eb.tail = tuple(to_blender(c + np.array([0, 0.05, 0])))
    for b in bones:
        parent = env["segments"][b]["parent"]
        if parent:
            arm_data.edit_bones[b].parent = arm_data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    donor, joints = read_glb(os.path.join(OUT, DONOR + ".glb"))

    def skin(obj, weights):
        for b in bones:
            obj.vertex_groups.new(name=b)
        for i, row in enumerate(weights):
            for b, w in enumerate(row):
                if w > 0.001:
                    obj.vertex_groups[b].add([i], float(w), "REPLACE")
        m = obj.modifiers.new("skeleton", "ARMATURE")
        m.object = arm
        obj.parent = arm

    def donor_weights(m):
        w = np.zeros((len(m["pos"]), len(bones)))
        for k in range(4):
            for i, name in enumerate(joints):
                sel = m["joints"][:, k] == i
                w[sel, bones.index(name)] += m["weights"][sel, k]
        return w

    body = donor["body_skin"]
    sk = blender_mesh("body_skin", body["pos"], body["tris"], body["uv"][body["tris"]], body["nrm"])
    skin(sk, donor_weights(body))
    hm = donor["body_head"]
    hat_tris = hm["tris"][d["hat_tris"]]
    used = np.unique(hat_tris)
    remap = -np.ones(len(hm["pos"]), int)
    remap[used] = np.arange(len(used))
    hat = blender_mesh("body_hat", hm["pos"][used], remap[hat_tris], hm["uv"][hat_tris], hm["nrm"][used])
    skin(hat, donor_weights(hm)[used])
    col_tris = hm["tris"][d["collar_tris"]]
    cused = np.unique(col_tris)
    cremap = -np.ones(len(hm["pos"]), int)
    cremap[cused] = np.arange(len(cused))
    collar = blender_mesh("body_collar", hm["pos"][cused], cremap[col_tris], hm["uv"][col_tris], hm["nrm"][cused])
    skin(collar, donor_weights(hm)[cused])
    # The head's corners split where its UVs do (Blender keeps per-corner UVs; the glb exporter
    # splits the points itself), weighted from the donor's head.
    skin(head, W)
    bpy.ops.object.select_all(action="DESELECT")
    for o in (sk, hat, collar, head, arm):
        o.select_set(True)
    path = os.path.join(OUT, ID + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_skins=True, export_animations=False,
                              export_apply=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="NONE", use_selection=True)
    print("wrote", path)


# ---------------------------------------------------------------- stage 1: the mesh and its layout

def nearest(src, dst, chunk=2000):
    """For each point of dst, the index of the nearest point of src."""
    out = np.zeros(len(dst), int)
    for i in range(0, len(dst), chunk):
        d = ((dst[i:i + chunk, None, :] - src[None, :, :]) ** 2).sum(-1)
        out[i:i + chunk] = np.argmin(d, 1)
    return out


def stage_mesh(spec):
    donor, joints = read_glb(os.path.join(OUT, DONOR + ".glb"))
    dh = donor["body_head"]
    hat = Hat(dh)
    h = Head(spec)
    h.fit_crown(hat, float(spec.get("crown", 0.9)))
    mesh = assemble(h, hat, spec)
    uv, size, plane, label = layout(mesh, spec)
    texels = (size[0] * PER, size[1] * PER)
    cuv = uv * PER / np.array(texels, float)          # Godot's UVs: 0..1, v down
    env = json.load(open(mp.ENVELOPE))
    bones = env["bones"]
    # Weights from the donor's own head and neck (not his hat), nearest point.
    face_pts = np.unique(dh["tris"][~hat.is_hat])
    near = face_pts[nearest(dh["pos"][face_pts], mesh["V"])]
    W = np.zeros((len(mesh["V"]), len(bones)))
    for k in range(4):
        for i, name in enumerate(joints):
            sel = dh["joints"][near, k] == i
            W[sel, bones.index(name)] += dh["weights"][near, k][sel]
    rigid = np.unique(mesh["F"][np.isin(mesh["part"], ["eye_r", "eye_l", "moustache"])])
    W[rigid] = 0.0
    W[rigid, bones.index("head")] = 1.0
    W /= np.maximum(W.sum(1, keepdims=True), 1e-9)
    # His collar, shirt and neckerchief were in the donor's head mesh too: what's below his jaw
    # and isn't skin goes on as a piece of its own (on the donor's head texture).
    from PIL import Image
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    import judge
    tex = np.asarray(Image.open(os.path.join(OUT, DONOR + "_head.png")).convert("RGB"))
    cuv_d = dh["uv"][dh["tris"]].mean(1)
    px = tex[np.clip((cuv_d[:, 1] * tex.shape[0]).astype(int), 0, tex.shape[0] - 1),
             np.clip((cuv_d[:, 0] * tex.shape[1]).astype(int), 0, tex.shape[1] - 1)]
    lab = judge.to_lab(px[None])[0]
    skinlike = (lab[:, 1] > 7) & (lab[:, 2] > 10) & (lab[:, 0] > 22) & (lab[:, 0] < 80)
    centroid = dh["pos"][dh["tris"]].mean(1)
    collar = ~hat.is_hat & (centroid[:, 1] < COLLAR_BELOW) & ~skinlike
    os.makedirs(WORK, exist_ok=True)
    # His normals from an exaggerated copy of him (rims out, hollows in, the moustache's edge
    # harder): the shader lights each square once, at its centre, so this is a normal a square.
    ex = float(spec.get("paint", {}).get("exaggerate", PAINT["exaggerate"]))
    Vx = mesh["V"] + ex * (mesh["V"] - laplacian_smooth(mesh["V"], mesh["F"], 4))
    np.savez(os.path.join(WORK, "mesh.npz"), collar_tris=collar, V=mesh["V"], F=mesh["F"], N=vertex_normals(Vx, mesh["F"]),
             cuv=cuv, uv=uv, size=np.array(size), texels=np.array(texels), part=mesh["part"].astype(str),
             plane=plane, label=label, L=mesh["L"], weights=W, hat_tris=hat.is_hat,
             eye_centres=np.array([h.eye_centres["r"], h.eye_centres["l"]]))
    print("head: %d triangles, %d islands, atlas %dx%d squares (%dx%d texels)" % (
        len(mesh["F"]), label.max() + 1, size[0], size[1], texels[0], texels[1]))


# ---------------------------------------------------------------- stage 3: the paint

# MediaPipe's points round each eye and along each brow (his right first).
UPPER_LID = {"r": [33, 246, 161, 160, 159, 158, 157, 173, 133], "l": [263, 466, 388, 387, 386, 385, 384, 398, 362]}
LOWER_LID = {"r": [33, 7, 163, 144, 145, 153, 154, 155, 133], "l": [263, 249, 390, 373, 374, 380, 381, 382, 362]}
BROW = {"r": [(70, 46), (63, 53), (105, 52), (66, 65), (107, 55)], "l": [(300, 276), (293, 283), (334, 282), (296, 295), (336, 285)]}

PAINT = {
    "ramp": [26, 31, 36, 41, 46, 52],     # the skin's tones, L* (his base 41: the donor's albedo)
    "hue": [13.0, 19.0],                   # a*, b*
    "base": 3,                             # his open skin's step
    "ao_far": 2.5, "ao_near": 2.0,         # steps darker where shut in (1 - AO)
    "cavity": 0.0012, "ridge": 0.0016,     # metres in or out of the smoothed head: a step each way
    "jitter": 0.3,                         # share of squares a step off
    "tints": {"nose": [0, 5, 2], "cheek": [0, 4, 1], "ear": [-1, 5, 2], "jaw": [-2, -2, -3], "lip": [-5, 9, 2]},
    "hair": [15, 4, 7], "brow": [11, 3, 5],
    "moustache": [15, 4, 8], "moustache_top": [28, 6, 10], "moustache_under": [6, 2, 3],
    "lip_line": [19, 9, 7], "corner": [21, 8, 8],
    "lid": [12, 5, 6],
    "eye_gain": 1.2,                       # the shader's lift on his drawn whites (the donor's 1.8)
    "white": [212, 198, 180], "white_shade": [182, 165, 145], "iris": [62, 40, 26], "iris_rim": [26, 16, 10],
    "pupil": [10, 7, 6], "glint": [248, 244, 236],
    "iris_mm": 5.4, "pupil_share": 0.38, "exaggerate": 1.5,
}


def lab_rgb(lab):
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    import judge
    return np.clip(judge.lab_to_rgb(np.asarray(lab, float)), 0, 255)


def laplacian_smooth(V, F, passes, keep=None):
    nb = [set() for _ in range(len(V))]
    for f in F:
        for a, b in ((f[0], f[1]), (f[1], f[2]), (f[2], f[0])):
            nb[a].add(b)
            nb[b].add(a)
    idx = [np.array(sorted(n)) for n in nb]
    out = V.copy()
    for _ in range(passes):
        new = out.copy()
        for i, n in enumerate(idx):
            if len(n):
                new[i] = out[n].mean(0)
        out = new
    return out


def curve_y(points, x):
    """A curve through points (x, y) sorted by x, at x (clamped)."""
    p = points[np.argsort(points[:, 0])]
    return np.interp(x, p[:, 0], p[:, 1])


def stage_paint(spec):
    d = np.load(os.path.join(WORK, "mesh.npz"))
    V, F, N, L = d["V"], d["F"], d["N"], d["L"]
    part, label, uv = d["part"], d["label"], d["uv"]
    tW, tH = (int(x) for x in d["texels"])
    sW, sH = (int(x) for x in d["size"])
    ao = np.load(os.path.join(WORK, "ao.npy"))                     # (tH, tW, 2): near, far
    P = dict(PAINT)
    P.update(spec.get("paint", {}))
    tri, bary = raster({"F": F}, uv, (sW, sH), PER)
    cov = tri >= 0
    t = np.where(cov, tri, 0)
    pos = (V[F[t]] * bary[..., None]).sum(2)
    nrm = (N[F[t]] * bary[..., None]).sum(2)
    nrm /= np.maximum(np.linalg.norm(nrm, axis=-1, keepdims=True), 1e-9)
    tpart = np.where(cov, part[t], "")
    # The squares: mean place and normal, AO, and part, from their texels.
    sq = (np.arange(tH)[:, None] // PER) * sW + (np.arange(tW)[None, :] // PER)
    nsq = sW * sH
    cnt = np.bincount(sq[cov], minlength=nsq).astype(float)
    has = cnt > 0
    def mean(vals):
        out = np.zeros((nsq,) + vals.shape[2:])
        np.add.at(out, sq[cov], vals[cov])
        return out / np.maximum(cnt, 1).reshape((-1,) + (1,) * (vals.ndim - 2))
    sp, sn = mean(pos), mean(nrm)
    sn /= np.maximum(np.linalg.norm(sn, axis=-1, keepdims=True), 1e-9)
    aok = cov & (ao[..., 1] > 0)
    acnt = np.bincount(sq[aok], minlength=nsq).astype(float)
    sao = np.zeros((nsq, 2))
    np.add.at(sao, sq[aok], ao[aok])
    sao = np.where(acnt[:, None] > 0, sao / np.maximum(acnt, 1)[:, None], 1.0)
    # Every texel in exactly one square: no square holds two islands (the eyes' 2 mm texels nest
    # four a side in the skin's 8 mm squares).
    owners = {}
    for k, lab_ in zip(sq[cov].tolist(), label[t[cov]].tolist()):
        owners.setdefault(k, set()).add(lab_)
    shared = sum(1 for v in owners.values() if len(v) > 1)
    spart = np.full(nsq, "", dtype=object)
    spart[sq[cov]] = tpart[cov]
    # Cavity and ridges: how far each square is in or out of the head smoothed.
    sm = laplacian_smooth(V, F, 8)
    off = ((V - sm) * N).sum(1)
    toff = (off[F[t]] * bary).sum(-1)
    soff = mean(toff[..., None])[:, 0]
    # Landmarks.
    iris = {"r": L[LM["iris_r"]], "l": L[LM["iris_l"]]}
    part_y = (L[LM["lip_upper_in"]][1] + L[LM["lip_lower_in"]][1]) / 2
    corners = {"r": L[LM["mouth_r"]], "l": L[LM["mouth_l"]]}
    corner_x = (abs(corners["r"][0]) + abs(corners["l"][0])) / 2
    chin = L[LM["chin"]]
    ear_pts = sp[spart == "ear"]
    ear_front = float(np.percentile(ear_pts[:, 2], 5)) if len(ear_pts) else 0.0
    ear_low = float(np.percentile(ear_pts[:, 1], 5)) if len(ear_pts) else 1.6
    ear_top = float(np.percentile(ear_pts[:, 1], 95)) if len(ear_pts) else 1.7
    skin = spart == "skin"
    # Steps on the ramp.
    step = np.full(nsq, float(P["base"]))
    step -= np.rint((1 - sao[:, 1]) * P["ao_far"] + (1 - sao[:, 0]) * P["ao_near"])
    step -= (soff < -P["cavity"]).astype(float)
    step += (soff > P["ridge"]).astype(float)
    rng = np.random.default_rng(1871)
    j = rng.random(nsq)
    step += np.where(j < P["jitter"] / 2, -1, np.where(j > 1 - P["jitter"] / 2, 1, 0))
    # Regions.
    def near(pts, r):
        return np.min(np.linalg.norm(sp[:, None, :] - np.atleast_2d(pts)[None, :, :], axis=2), axis=1) < r
    nose = near(np.linspace(L[6], L[LM["nose_tip"]], 6), 0.011) | near([L[LM["wing_r"]], L[LM["wing_l"]]], 0.009)
    cheek = near([L[50], L[280]], 0.02)
    socket = near([iris["r"], iris["l"]], 0.018) & (sp[:, 1] < max(iris["r"][1], iris["l"][1]) + 0.006)
    face_side = sp[:, 2] < ear_front
    jaw = face_side & (sp[:, 1] < part_y + 0.006) & (sp[:, 1] > chin[1] - 0.004) & (sn[:, 1] > -0.5)
    lower_lip = (sp[:, 1] < part_y - 0.002) & (sp[:, 1] > L[LM["lip_bottom"]][1]) & (np.abs(sp[:, 0]) < corner_x * 0.85) & (sn[:, 2] < -0.5)
    hair = skin & (((sp[:, 2] > ear_front) & (sp[:, 1] > ear_low + 0.004))
                   | ((sp[:, 2] > ear_front - 0.013) & (sp[:, 1] > (ear_low + ear_top) / 2)))
    nape = skin & (sp[:, 2] > ear_front + 0.03) & (sp[:, 1] > ear_low - 0.03)
    hair |= nape
    brow_curve = {sd: np.array([(L[a] + L[b]) / 2 for a, b in BROW[sd]]) for sd in "rl"}
    brow = skin & (near(np.concatenate([np.linspace(c[i], c[i + 1], 4) for c in brow_curve.values() for i in range(len(c) - 1)]), 0.0045))
    step -= socket.astype(float)
    step = np.clip(step, 0, len(P["ramp"]) - 1)
    ramp = np.array(P["ramp"], float)
    lab = np.zeros((nsq, 3))
    lab[:, 0] = ramp[step.astype(int)]
    lab[:, 1], lab[:, 2] = P["hue"]
    tints = P["tints"]
    for mask, key in ((nose & skin, "nose"), (cheek & skin & ~nose, "cheek"), (spart == "ear", "ear"),
                      (jaw & skin & ~lower_lip, "jaw"), (lower_lip & skin, "lip")):
        lab[mask] += np.array(tints[key], float)
    def put(mask, col, steps=0):
        c = np.array(col, float)
        lab[mask] = c + np.array([steps * 5.0, 0, 0])
    # Hair and brows, each on the hair's own small ramp (the jitter and AO carried over).
    hs = (step - P["base"]).clip(-2, 2)
    lab[hair] = np.array(P["hair"], float) + np.c_[hs[hair] * 3.0, np.zeros((hair.sum(), 2))]
    lab[brow] = np.array(P["brow"], float) + np.c_[(hs[brow] * 1.5).clip(-1, 2), np.zeros((brow.sum(), 2))]
    mous = spart == "moustache"
    lab[mous] = np.array(P["moustache"], float) + np.c_[hs[mous] * 1.5, np.zeros((mous.sum(), 2))]
    # ---- the stamps
    stamps = {}
    def sq_at(p, where):
        cand = np.nonzero(where)[0]
        return int(cand[np.argmin(np.linalg.norm(sp[cand] - p, axis=1))])
    front_skin = skin & (sn[:, 2] < -0.3)
    # Nostrils: the square under his nose half way from its middle to each wing, facing down.
    for sd, wing in (("r", LM["wing_r"]), ("l", LM["wing_l"])):
        aim = (L[LM["subnasale"]] + L[wing]) / 2 - np.array([0.0, 0.002, 0.0])
        under = skin & (sn[:, 1] < -0.25) & (np.sign(sp[:, 0]) == np.sign(L[wing][0]))
        if under.any():
            k = sq_at(aim, under)
            lab[k] = [ramp[0] - 4, P["hue"][0] + 4, P["hue"][1]]
            stamps["nostril_" + sd] = int(k)
    # The lip line: the row through his parting, corner to corner, darker than both lips.
    part_z = (L[LM["lip_upper_in"]][2] + L[LM["lip_lower_in"]][2]) / 2
    line = front_skin & (np.abs(sp[:, 1] - part_y) < SQUARE_M / 2) & (np.abs(sp[:, 0]) < corner_x - 0.001) \
        & (sp[:, 2] < part_z + 0.006)        # on his lips' front, not inside his mouth
    put(line, P["lip_line"])
    stamps["lip_line"] = np.nonzero(line)[0].tolist()
    for sd in "rl":
        k = sq_at(corners[sd], skin & (sn[:, 2] < -0.4))
        put(np.arange(nsq) == k, P["corner"])
        stamps["corner_" + sd] = k
    # The nose's tip a step lighter.
    k = sq_at(L[LM["nose_tip"]], skin)
    lab[k, 0] += 8.0
    stamps["nose_tip"] = k
    # Each ear: its hollow two steps down, the canal the darkest.
    for sd, sign in (("r", 1), ("l", -1)):
        cand = np.nonzero((spart == "ear") & (np.sign(sp[:, 0]) == sign) & (sn[:, 0] * sign > 0.55))[0]
        if len(cand) >= 4:
            order = cand[np.argsort(sao[cand, 0] + sao[cand, 1])]
            lab[order[0], 0] = ramp[0] - 8
            lab[order[1:4], 0] -= 10.0
            stamps["ear_canal_" + sd] = int(order[0])
            stamps["ear_hollow_" + sd] = order[1:4].tolist()
    # The moustache: its underside near-black where it meets the lip, its top a step lighter.
    under = mous & (sn[:, 1] < -0.3)
    top = mous & (sn[:, 1] > 0.35)
    put(under, P["moustache_under"])
    put(top, P["moustache_top"])
    stamps["moustache_under"] = np.nonzero(under)[0].tolist()
    stamps["moustache_top"] = np.nonzero(top)[0].tolist()
    # ---- to texels: each square its colour
    rgb_sq = lab_rgb(lab)
    img = np.zeros((tH, tW, 3))
    img[:] = rgb_sq[sq]
    # ---- the eyes, texel by texel (on the 2 mm texels inside his squares)
    centres = {"r": d["eye_centres"][0], "l": d["eye_centres"][1]}
    for sd in "rl":
        c = centres[sd]
        eye = cov & (tpart == "eye_" + sd)
        p = pos[eye]
        r = np.linalg.norm(p - c, axis=1)
        dirs = (p - c) / r[:, None]
        R = float(np.median(r))
        gaze = np.array([-0.06 * np.sign(c[0]), 0.02, -1.0])     # ahead, a little in: at you
        gaze /= np.linalg.norm(gaze)
        ang = np.degrees(np.arccos(np.clip(dirs @ gaze, -1, 1)))
        ia = np.degrees(np.arcsin(min(P["iris_mm"] / 1000 / R, 0.95)))
        col = np.zeros((len(p), 3))
        # The white, shaded toward the lids and the corners.
        up = (p[:, 1] - c[1]) / R
        side = np.abs(p[:, 0] - iris[sd][0]) / R
        shade = np.clip(0.55 * up.clip(0, None) * 2 + 0.6 * smoothstep(0.55, 1.0, side), 0, 1)[:, None]
        col[:] = np.array(P["white"]) * (1 - shade) + np.array(P["white_shade"]) * shade
        col[ang < ia] = P["iris"]
        col[(ang < ia) & (ang > ia * 0.8)] = P["iris_rim"]
        col[ang < ia * P["pupil_share"]] = P["pupil"]
        # The glint: up and toward his left (the shot's lamp is on your right).
        g = c + R * (gaze + np.array([-0.32, 0.3, 0.0]) * math.sin(math.radians(ia)))
        col[np.linalg.norm(p - g, axis=1) < 0.0013] = P["glint"]
        img[eye] = col
    # The lids: the texels of his skin just over each upper lid dark, a hair under the lower lid
    # a step down.
    lid_rgb = lab_rgb(np.array([P["lid"]], float))[0]
    for sd in "rl":
        up_c = np.array([[L[i][0], L[i][1]] for i in UPPER_LID[sd]])
        lo_c = np.array([[L[i][0], L[i][1]] for i in LOWER_LID[sd]])
        x0, x1 = up_c[:, 0].min(), up_c[:, 0].max()
        ex = cov & (tpart == "skin") & (pos[..., 0] > x0 - 0.0015) & (pos[..., 0] < x1 + 0.0015) & (nrm[..., 2] < -0.2) \
            & (np.abs(pos[..., 1] - iris[sd][1]) < 0.012)
        yy = pos[..., 1]
        uy = curve_y(up_c, pos[..., 0])
        ly = curve_y(lo_c, pos[..., 0])
        upper = ex & (yy > uy - 0.0004) & (yy < uy + 0.0022)
        lower = ex & (yy < ly + 0.0004) & (yy > ly - 0.0012)
        img[upper] = lid_rgb
        img[lower] *= 0.8
        stamps["lid_upper_" + sd] = int(upper.sum())
    # Pad each island a square round, so the mipmaps don't fetch the black between them.
    filled = np.zeros((sH, sW), bool)
    filled.reshape(-1)[has] = True
    sqimg = img.reshape(sH, PER, sW, PER, 3)
    for _ in range(2):
        grow = filled.copy()
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            src = np.roll(filled, (dy, dx), (0, 1))
            new = src & ~grow
            if new.any():
                ys, xs = np.nonzero(new)
                sqimg[ys, :, xs, :, :] = sqimg[(ys - dy) % sH, :, (xs - dx) % sW, :, :]
                grow |= new
        filled = grow
    img = sqimg.reshape(tH, tW, 3)
    from PIL import Image
    Image.fromarray(np.clip(img + 0.5, 0, 255).astype(np.uint8)).save(os.path.join(OUT, ID + "_head.png"))
    # Where each stamp is on him and the squares round it (for the judge: tools/characters/faces_lights.gd).
    lab_of = {}
    stamp_sq = set()
    for v in stamps.values():
        stamp_sq.update(v if isinstance(v, list) else [v])
    sq_label = np.full(nsq, -1)
    sq_label[sq[cov]] = label[t[cov]]
    points = {}
    for name, v in stamps.items():
        ks = v if isinstance(v, list) else [v]
        if not ks or name.startswith("lid_"):
            continue
        ring = set()
        for k in ks:
            r0, c0 = divmod(k, sW)
            for dr in (-1, 0, 1):
                for dc in (-1, 0, 1):
                    n = (r0 + dr) * sW + c0 + dc
                    if 0 <= n < nsq and has[n] and n not in stamp_sq and sq_label[n] == sq_label[k]:
                        ring.add(n)
        points[name] = {"at": sp[ks].round(5).tolist(), "round": sp[sorted(ring)].round(5).tolist(),
                        "facing": sn[ks].mean(0).round(3).tolist()}
    # ---- the rest of him is the donor's, and his report
    import shutil
    rep = json.load(open(os.path.join(OUT, DONOR + ".json")))
    shutil.copyfile(os.path.join(OUT, DONOR + "_skin.png"), os.path.join(OUT, ID + "_skin.png"))
    shutil.copyfile(os.path.join(OUT, DONOR + "_head.png"), os.path.join(OUT, ID + "_hat.png"))
    shutil.copyfile(os.path.join(OUT, DONOR + "_head.png"), os.path.join(OUT, ID + "_collar.png"))
    per = rep["texture"]["texels_per_square"]
    base_rgb = lab_rgb(np.array([[ramp[P["base"]], P["hue"][0], P["hue"][1]]]))[0] / 255.0
    out = {"id": ID, "source": "house_head", "whole": True, "model": "MakeHuman base mesh (CC0), house_head.json",
           "donor": DONOR, "eyes": rep["eyes"], "eye_gain": P["eye_gain"],
           "skin_tone": [round(float(x), 4) for x in base_rgb],
           "texture": {"size": [tW, tH], "squares": [sW, sH], "square_m": SQUARE_M,
                       "texels_per_square": {"head": PER, "skin": per["skin"], "hat": per["head"], "collar": per["head"]},
                       "normals": "exaggerated x%.1f (vertex normals, lit a square at a time)" % P["exaggerate"]},
           "stamps": points, "triangles": {"head": int(len(F))},
           "squares": {"filled": int(has.sum()), "shared_by_islands": int(shared), "texel_m": SQUARE_M / PER}}
    json.dump(out, open(os.path.join(OUT, ID + ".json"), "w"), indent=1)
    print("painted %s: %d squares; stamps %s" % (ID, int(has.sum()), {k: (len(v) if isinstance(v, list) else v) for k, v in stamps.items()}))


def main():
    spec = load_spec()
    stages = ["mesh", "blender", "paint"]
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            stages = a.split("=", 1)[1].split(",")
    if "mesh" in stages:
        stage_mesh(spec)
    if "blender" in stages:
        try:
            import bpy  # noqa: F401
            stage_blender()
        except ImportError:
            import subprocess
            py = os.path.expanduser("~/bpyenv/bin/python")
            subprocess.run([py, os.path.abspath(__file__), "--only=blender"], check=True)
    if "paint" in stages:
        stage_paint(spec)


if __name__ == "__main__":
    main()
