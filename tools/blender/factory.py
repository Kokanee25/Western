"""The character factory: men from one base head by parameters (docs/briefs/character-factory.md).

    python3 tools/blender/fetch_makehuman.py                 # once: the CC0 assets (factory.json's too)
    ~/bpyenv/bin/python tools/blender/factory.py --only=stranger_factory     # one man (bpy)
    python3 tools/blender/factory.py --preview=DIR [--only=...]   # no bpy: grey views of the heads

Every factory man is MakeHuman's base mesh (CC0) through make_people.py's route (targets, warp
onto our joints, envelope fit, fingers cut, skinned to our 17 bones, clothes.py's garments), with:

  1. The base head (assets/people/factory.json `base`): targets and shaping that every man has,
     making the small forms readable at the game's ~8 mm squares: the ears flared out with a rim
     raised and the bowl pushed in, the nose larger with the nostrils cut
     in, the upper lid a ledge over the eye, a crease along the lips, a heavier brow. The shaping
     works on the regions MakeHuman's own targets move (an ear is what `ears/r-ear-scale-incr`
     moves), so it follows each man's own shape.
  2. One head UV layout (`head_layout`), laid out once from the base head: the face projected from
     the front (eyes, nose and mouth large), each ear front and back on its own, the scalp on a
     cylinder, the crown from above, under the jaw from below, the eyeballs, and a patch for facial
     hair. Every man shares it, so whatever is drawn on it lands on every man.
  3. Facial hair and hair as shells of their own, fitted to any head by the same script: the
     moustache stands off the lip (it casts a shadow), a beard off the jaw; the hair is its own
     shape (`hair`) so a hat comes off over it.
  4. A texture for the head painted by script on that layout: his skin tone, the small details
     stamped (the nostrils' dark, the lip line, the lid line, the ear's bowl, the moustache's
     underside, brows, stubble, the eyes' whites and irises), in flat even light.

A man is a people.json entry with "source": "factory" (archetype, targets, hair, moustache,
beard, skin, brows, wear, outfit). Output: assets/people/<id>.glb (body_skin, body_head,
body_hair, the garments), <id>_head.png, <id>_hair.png, the garments' textures and <id>.json.
Nothing here is paid for and nothing is hand-edited: every man repeats from the repo.
"""
import json
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_people as mp  # noqa: E402

FACTORY = "assets/people/factory.json"
PEOPLE = "assets/people/people.json"
OUT = mp.OUT
# Head texture size (texels a side) and hair texture size.
HEAD_TEX = 1024
HAIR_TEX = 256


# --- Targets ----------------------------------------------------------------------------------

def expand(targets):
    """{"ears/{s}-ear-wing-incr": w} → both sides."""
    out = {}
    for t, w in targets.items():
        for name in ([t.replace("{s}", s) for s in "rl"] if "{s}" in t else [t]):
            out[name] = out.get(name, 0.0) + float(w)
    return out


def targets_of(spec, factory):
    """The base head's targets, then his archetype's, then his own (later ones add)."""
    out = expand(factory["base"]["targets"])
    arch = factory["archetypes"].get(spec.get("archetype", ""), {})
    for src in (arch.get("targets", {}), spec.get("targets", {})):
        for t, w in expand(src).items():
            out[t] = out.get(t, 0.0) + w
    return out


_disp = {}


def target_disp(name, n):
    """A target's displacement per vertex in our body space (metres), (n, 3)."""
    if name not in _disp:
        d = np.zeros((n, 3))
        for line in open(os.path.join(mp.MH, "targets", name + ".target")):
            if line[:1].isdigit():
                i, x, y, z = line.split()
                d[int(i)] = [float(x), float(y), float(z)]
        _disp[name] = d * 0.1 * np.array([-1.0, 1.0, -1.0])
    return _disp[name]


def region(name, n, body):
    """How much a target moves each vertex, 0..1 (its largest move = 1): the region it shapes."""
    m = np.linalg.norm(target_disp(name, n), axis=1)
    m = m / max(m.max(), 1e-9)
    return m * body


def vertex_normals(v, faces):
    n = np.zeros_like(v)
    for fv, _t in faces:
        p = v[fv]
        fn = np.cross(p[1] - p[0], p[2] - p[0])
        if len(fv) == 4:
            fn = fn + np.cross(p[3] - p[2], p[0] - p[2])
        n[fv] += fn
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


def spread(f, faces, steps):
    """A per-vertex field spread over the mesh: each step, every vertex takes the largest of its
    neighbours' values (so two regions that only touch come to overlap along their join)."""
    f = f.copy()
    edges = set()
    for fv, _t in faces:
        for i in range(len(fv)):
            edges.add((fv[i], fv[(i + 1) % len(fv)]))
    a = np.array([e[0] for e in edges])
    b = np.array([e[1] for e in edges])
    for _ in range(steps):
        g = f.copy()
        np.maximum.at(g, a, f[b])
        np.maximum.at(g, b, f[a])
        f = g
    return f


def lip_seam(wu, wl, faces):
    """Where the upper lip's region meets the lower's: 1 along the line between the lips."""
    seam = np.sqrt(spread(wu, faces, 2) * spread(wl, faces, 2))
    return seam / max(seam.max(), 1e-9)


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


# --- 1. The base head's forms -------------------------------------------------------------------

def _ear_frame(v, w):
    """An ear's centre, plane (two axes) and outward normal, from its core vertices."""
    core = w > 0.5
    p = v[core]
    c = (p * w[core, None] ** 2).sum(0) / (w[core] ** 2).sum()
    _u, _s, vt = np.linalg.svd(p - c, full_matrices=False)
    n = vt[2]
    if n[0] * c[0] < 0:  # outward: away from the head's middle (x = 0)
        n = -n
    a2 = np.array([0.0, 1.0, 0.0]) - n * n[1]
    a2 /= np.linalg.norm(a2)
    a1 = np.cross(a2, n)
    return c, a1, a2, n, core


def ear_angle(v, w):
    """How far the ear stands out (degrees): from its root at the front to the back of its rim,
    against the line straight back along the head."""
    core = w > 0.5
    z = v[core, 2]
    root = v[core][z < np.percentile(z, 15)].mean(0)
    back = v[core][z > np.percentile(z, 85)].mean(0)
    return math.degrees(math.atan2(abs(back[0]) - abs(root[0]), back[2] - root[2]))


def _hull_dist(q):
    """Distance of each 2D point inside its convex hull to the hull's edge."""
    pts = sorted(map(tuple, q))
    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    hull = np.array(lower[:-1] + upper[:-1])
    d = np.full(len(q), np.inf)
    for i in range(len(hull)):
        a, b = hull[i], hull[(i + 1) % len(hull)]
        ab = b - a
        t = np.clip(((q - a) @ ab) / max(ab @ ab, 1e-12), 0, 1)
        d = np.minimum(d, np.linalg.norm(q - (a + t[:, None] * ab), axis=1))
    return d


def shape_base(person, forms, plain=None):
    """The base head's forms, on a man's mesh before it's warped (body space, metres).

    plain: the same man's vertices without the base head, to report what it adds."""
    v = person.v
    n = len(v)
    body = np.zeros(n)
    body[sorted({i for f in person.body_faces for i in f[0]})] = 1.0
    normals = vertex_normals(v, person.body_faces)
    rep = {}
    # Ears: flared by MakeHuman's own wing target (in `base.targets`), here the rim raised and
    # the bowl pushed in. The ear is what its wing target moves (its region fades out within a
    # few millimetres of the head).
    neutral = v.copy() if plain is None else plain
    for s in "rl":
        w = smoothstep(0.1, 0.3, region("ears/%s-ear-wing-incr" % s, n, body))
        c, a1, a2, nrm, core = _ear_frame(v, w)
        q = np.stack([(v - c) @ a1, (v - c) @ a2], 1)
        hd = np.full(n, np.inf)
        hd[core] = _hull_dist(q[core])
        lo, hi = q[core, 1].min(), q[core, 1].max()
        upper = smoothstep(lo + 0.25 * (hi - lo), lo + 0.4 * (hi - lo), q[:, 1])
        rim = (1.0 - smoothstep(0.0, 0.004, hd)) * core
        # The bowl (the concha) is the deep middle of the ear towards its root, not its back.
        zc = v[core, 2]
        toward_root = 1.0 - smoothstep(np.percentile(zc, 35), np.percentile(zc, 70), v[:, 2])
        bowl = smoothstep(0.005, 0.009, hd) * core * upper * toward_root
        v += nrm * (forms.get("ear_rim_m", 0.0) * rim - forms.get("ear_hollow_m", 0.0) * bowl)[:, None]
        rep["ear_%s_flare_deg" % s] = round(ear_angle(v, w) - ear_angle(neutral, w), 1)
    # The nostrils cut in: the underside of the nose, either side of the septum, pushed up into it.
    w = region("nose/nose-nostrils-width-incr", n, body)
    for sx in (1.0, -1.0):
        sel = (w > 0.15) & (normals[:, 1] < -0.3) & (v[:, 0] * sx > 0.0035)
        if sel.sum() < 3:
            continue
        cen = (v[sel] * w[sel, None]).sum(0) / w[sel].sum()
        r = np.linalg.norm(v - cen, axis=1)
        bump = (1.0 - smoothstep(0.0025, 0.0065, r)) * body
        v -= normals * (forms.get("nostril_m", 0.0) * bump)[:, None]
        v[:, 1] += forms.get("nostril_m", 0.0) * 0.5 * bump
    size = []
    for k, ax in (("horiz", 0), ("vert", 1), ("depth", 2)):
        sel = region("nose/nose-scale-%s-incr" % k, n, body) > 0.5
        size.append(float(np.ptp(v[sel, ax]) / max(np.ptp(neutral[sel, ax]), 1e-9)))
    rep["nose_scale"] = [round(x, 3) for x in size]
    # The upper lids a ledge over the eyes: the fold brought forward and down a little.
    for s in "rl":
        w = region("eyes/%s-eye-eyefold-down" % s, n, body)
        v[:, 2] -= forms.get("lid_ledge_m", 0.0) * w
        v[:, 1] -= forms.get("lid_ledge_m", 0.0) * 0.35 * w
    # A crease along the lips: where the upper lip's region meets the lower's, pushed in.
    wu = region("mouth/mouth-upperlip-volume-incr", n, body)
    wl = region("mouth/mouth-lowerlip-volume-incr", n, body)
    seam = lip_seam(wu, wl, person.body_faces)
    v[:, 2] += forms.get("lip_line_m", 0.0) * smoothstep(0.2, 0.8, seam)
    # A heavier brow: the ridge over the eyes brought forward.
    w = region("eyebrows/eyebrows-trans-forward", n, body)
    v[:, 2] -= forms.get("brow_ridge_m", 0.0) * w
    person.v = v
    return rep


# --- Making a man -------------------------------------------------------------------------------

def load_factory():
    return json.load(open(FACTORY))


def make_person(pid, spec, env, factory, base_only=False):
    """MakeHuman's base mesh with his targets and the base head's forms, not yet warped."""
    f = {"base": factory["base"], "archetypes": factory["archetypes"]}
    targets = expand(factory["base"]["targets"]) if base_only else targets_of(spec, f)
    p = mp.Person(pid, {"targets": targets, "outfit": spec.get("outfit", {})}, env)
    p.spec = dict(spec)
    p.report["source"] = "factory"
    p.report["archetype"] = spec.get("archetype", "")
    plain = None
    if not base_only:   # the same man without the base head: what the base adds, measured
        f0 = {"base": {"targets": {}}, "archetypes": factory["archetypes"]}
        plain = mp.Person(pid, {"targets": targets_of(spec, f0)}, env).v
    p.report["forms"] = shape_base(p, factory["base"]["forms"], plain)
    return p


# --- Preview (no bpy): grey views of the head ------------------------------------------------------

def render_grey(v, faces, view, size=360, span=0.30, centre=None, light=(-0.4, 0.5, -0.75), pitch=0.0, tint=None):
    """An orthographic grey picture of the faces, lit by one light (numpy, z-buffered).

    view: degrees he's turned from facing you (0 front, 45 three-quarter, 90 his right side)."""
    th = math.radians(view)
    rot = np.array([[math.cos(th), 0, math.sin(th)], [0, 1, 0], [-math.sin(th), 0, math.cos(th)]])
    ph = math.radians(pitch)  # + looks up at him from below
    rx = np.array([[1, 0, 0], [0, math.cos(ph), -math.sin(ph)], [0, math.sin(ph), math.cos(ph)]])
    p = v @ rot.T @ rx.T
    centre = p.mean(0) if centre is None else np.asarray(centre, float) @ rot.T @ rx.T
    sc = size / span
    px = (p[:, 0] - centre[0]) * sc + size / 2
    py = size / 2 - (p[:, 1] - centre[1]) * sc
    depth = p[:, 2]  # camera at -Z looking +Z: smaller z is nearer
    L = np.array(light) / np.linalg.norm(light)
    img = np.full((size, size), 0.12)
    zb = np.full((size, size), np.inf)
    tris, tt = [], []
    for k, (fv, _t) in enumerate(faces):
        for j in range(1, len(fv) - 1):
            tris.append((fv[0], fv[j], fv[j + 1]))
            tt.append(1.0 if tint is None else tint[k])
    tris = np.array(tris)
    a, b, c = p[tris[:, 0]], p[tris[:, 1]], p[tris[:, 2]]
    fn = np.cross(b - a, c - a)
    fn /= np.maximum(np.linalg.norm(fn, axis=1, keepdims=True), 1e-12)
    fn = np.where(fn[:, 2:3] > 0, -fn, fn)  # lit from both sides: each face toward the camera
    shade = (0.2 + 0.8 * np.clip(fn @ L, 0, 1)) * np.array(tt)
    for k, (i, j, l) in enumerate(tris):
        xs = np.array([px[i], px[j], px[l]])
        ys = np.array([py[i], py[j], py[l]])
        x0, x1 = int(max(0, np.floor(xs.min()))), int(min(size - 1, np.ceil(xs.max())))
        y0, y1 = int(max(0, np.floor(ys.min()))), int(min(size - 1, np.ceil(ys.max())))
        if x1 < x0 or y1 < y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
        if abs(d) < 1e-12:
            continue
        w0 = ((ys[1] - ys[2]) * (gx - xs[2]) + (xs[2] - xs[1]) * (gy - ys[2])) / d
        w1 = ((ys[2] - ys[0]) * (gx - xs[2]) + (xs[0] - xs[2]) * (gy - ys[2])) / d
        w2 = 1 - w0 - w1
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        z = w0 * depth[i] + w1 * depth[j] + w2 * depth[l]
        sub = zb[y0:y1 + 1, x0:x1 + 1]
        win = inside & (z < sub)
        sub[win] = z[win]
        img[y0:y1 + 1, x0:x1 + 1][win] = shade[k]
    return img


def head_faces_of(person):
    neck_y = person.j["neck"][1] if not hasattr(person, "region") else None
    if hasattr(person, "region"):
        hr = person.region == "head"
        return [f for f in person.body_faces if hr[f[0]].all()] + person.eye_faces
    return [f for f in person.body_faces if (person.v[f[0], 1] > neck_y).all()] + person.eye_faces


def preview(people, env, factory, out):
    from PIL import Image
    os.makedirs(out, exist_ok=True)
    for pid, spec in people:
        p = make_person(pid, spec, env, factory)
        hf = head_faces_of(p)
        ids = sorted({i for f in hf for i in f[0]})
        cen = p.v[ids].mean(0)
        row = [render_grey(p.v, hf, a, centre=np.array([0, cen[1] - 0.02, 0])) for a in (0, 35, 90)]
        img = np.concatenate(row, 1)
        Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).save(os.path.join(out, pid + ".png"))
        print(pid, json.dumps(p.report["forms"]))


def factory_people(only=None):
    people = json.load(open(PEOPLE))["people"]
    return [(k, s) for k, s in people.items() if s.get("source") == "factory" and (not only or k in only.split(","))]


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    only, prev = None, None
    for a in args:
        if a.startswith("--only="):
            only = a.split("=", 1)[1]
        elif a.startswith("--preview="):
            prev = a.split("=", 1)[1]
    env = json.load(open(mp.ENVELOPE))
    factory = load_factory()
    people = factory_people(only)
    if prev:
        preview(people, env, factory, prev)
        return
    import factory_build  # noqa: E402  (needs bpy)
    for pid, spec in people:
        factory_build.build(pid, spec, env, factory)


if __name__ == "__main__":
    main()
