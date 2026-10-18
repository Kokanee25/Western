"""The men who work (Sean, 2026-10-18: men that bend, lose their hats, bleed and fit the frame,
three or four of them from one build, before any more looks). Each is the made-clothes man
(tools/characters/GARMENTS.md: his base body, the made shirt, waistcoat and trousers, the boots)
with a portrait head through the neck ring, his own build and his own colours
(tools/characters/men.json).

    ~/bpyenv/bin/python tools/characters/men.py build [--only=heavy_made,...]   # bpy: the bodies, heads, colours
    python3 tools/characters/men.py colour [--only=...]                          # the colours alone (numpy)

- **Build**: every mesh of the fitted made-clothes body (`from`, assets/people/<from>.glb) moved
  out or in about each body part's own axis (the middle of his skin's cross-section there, height
  by height) by men.json's `build` factors, x (his sides) and y (front to back) apart, and his
  belly forward. Each point's part is read off his **skin's** weights near it (not the garment's
  own), so a point of the waistcoat and the shirt under it move alike and the layers stay nested
  as they were made. Head, hands and feet are left as they are (the head is replaced next).
  → assets/people/<man>_body.glb (+ the body's textures and report), removed once his head's on.
- **Head**: tools/characters/neck_ring.py lays his portrait head on it (`--collar=made`,
  `--head_scale` 1.05 as GARMENTS.md) → assets/people/<man>.glb. A head painted by
  rodin_portrait.py (build/rodin_portrait/) is kept in assets/people/heads/ first.
- **Colours**: each garment texture's main cloth (the colours near its median, in Lab) moved to
  men.json's colour, its shading and painted detail kept; what's far from it (the tie, buttons)
  left. His report gets `game_hat` (PeopleBodies: he wears the game's hat, in his HumanBody's
  hat colour, shot off as any). A `ways` entry writes <way>.json (`mesh_from`, `textures_from`
  his man) and its own garment textures: the same man in other clothes, his mesh loaded once.
"""
import json
import os
import shutil
import subprocess
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PEOPLE = os.path.join(ROOT, "assets", "people")
HEADS = os.path.join(PEOPLE, "heads")
WORK = os.path.join(ROOT, "build", "rodin_portrait")
SPEC = os.path.join(HERE, "men.json")
GARMENTS = ["shirt", "vest", "trousers", "boots"]
HEAD_SCALE = 1.05
# Body parts moved by `build` (the rest, head, hands, feet and fingers, are left).
PARTS = ["pelvis", "abdomen", "chest", "neck", "upper_arm", "forearm", "thigh", "shin"]
BIN_M = 0.02        # his skin's cross-section middles, height by height
NEAR = 64           # skin points whose weights a point takes...
SMOOTH_M = 0.03     # ...by a Gaussian of their distance this wide
MAIN_DE = 35.0      # a texel this near (ΔE) a cloth's median moves with it...
FADE_DE = 15.0      # ...fading out over this much further
OWN_BIAS = 10.0     # a garment's texel goes with its own cloth unless another's is this much nearer
OWN_ONLY = ["trousers", "boots"]                  # textures recoloured all as their own cloth
CAN_TAKE = {"vest": ["vest", "shirt", "black"],   # the cloths a texture's texels can go with
            "shirt": ["shirt", "skin", "black"]}  # (the skin texture: any)
HIDDEN_M = 0.08     # his skin is under a garment when one is this near straight out from it...
EDGE_KEEP_M = 0.035 # ...and no edge of his shirt is this near
SEAT_BAND_M = 0.10  # the band round his crotch where seat and legs are weighted alike...
SEAT_BLEND_M = 0.05 # ...from the points this near
TUCK_M = 0.03       # his shirt ends this far inside his trousers' waistband
CLOTHED = ["pelvis", "abdomen", "chest", "upper_arm", "thigh", "shin", "foot"]   # parts always clothed
SOLE_LIFT = 0.047   # his boots' soles were this far under the skeleton's (the stand sank them 5-6 cm)...
SOLE_TOP = 0.20     # ...lifted by squashing what's under this height (m), the shafts kept
STRAY_SHARE = 0.05  # a piece of a part's skinning this much smaller than its biggest is a stray


# --- colour ------------------------------------------------------------------------------------

def to_lab(rgb):
    c = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def from_lab(lab):
    fy = (lab[..., 0] + 16) / 116
    f = np.stack([fy + lab[..., 1] / 500, fy, fy - lab[..., 2] / 200], -1)
    xyz = np.where(f > 0.2069, f ** 3, (f - 16 / 116) / 7.787) * np.array([0.95047, 1.0, 1.08883])
    m = np.array([[3.2406, -1.5372, -0.4986], [-0.9689, 1.8758, 0.0415], [0.0557, -0.2040, 1.0570]])
    c = np.clip(xyz @ m.T, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def cloth_median(lab):
    """A garment texture's main cloth: the median of the texels near the median (twice, so the
    tie or a painted smear doesn't pull it)."""
    flat = lab.reshape(-1, 3)
    mid = np.median(flat, 0)
    for _ in range(2):
        mid = np.median(flat[np.linalg.norm(flat - mid, axis=1) < MAIN_DE], 0)
    return mid


def recolour_man(out, plain, colours, skin_rgb):
    """His textures (each garment's and his skin's: the fitter paints skin under his clothes in
    their colours, so a point of it through a sleeve doesn't show) recoloured: each texel moves
    with the cloth it's nearest in Lab (a garment's own cloth by OWN_BIAS first, of CAN_TAKE's):
    a waistcoat's side painted with the shirt from the side picture goes with the shirt. Texels
    nearest his skin or black (the tie) keep theirs; past MAIN_DE from everything (brass,
    highlights) too. Trousers and boots go all one way (OWN_ONLY)."""
    labs = {g: to_lab(np.asarray(Image.open(p).convert("RGB")).astype(np.float64) / 255) for g, p in plain.items()}
    mids = {g: cloth_median(labs[g]) for g in GARMENTS if g in labs and g in colours}
    classes = [(g, mids[g], to_lab(np.asarray(colours[g], np.float64)[None, None])[0, 0] - mids[g]) for g in mids]
    classes += [("skin", to_lab(np.asarray(skin_rgb, np.float64)[None, None])[0, 0], np.zeros(3)),
                ("black", np.array([8.0, 0.0, 0.0]), np.zeros(3))]
    done = {}
    for g, lab in labs.items():
        if g in OWN_ONLY:
            # Trousers and boots: all of it their own cloth (a smear of his hand or cuff from a
            # side picture is still trouser), but black.
            sh = dict((c, x) for c, _, x in classes).get(g, np.zeros(3))
            w = np.clip((lab[..., 0] - 10.0) / 10.0, 0, 1)
            shift = np.broadcast_to(sh, lab.shape)
        else:
            mine = [x for x in classes if x[0] in CAN_TAKE.get(g, [x[0] for x in classes])]
            d = np.stack([np.linalg.norm(lab - m, axis=-1) - (OWN_BIAS if c == g else 0) for c, m, _ in mine], -1)
            k = d.argmin(-1)
            best = np.take_along_axis(d, k[..., None], -1)[..., 0] + np.where(np.array([c for c, _, _ in mine])[k] == g, OWN_BIAS, 0)
            w = np.clip(1 - (best - MAIN_DE) / FADE_DE, 0, 1)
            shift = np.stack([sh for _, _, sh in mine])[k]
        rgb = from_lab(lab + w[..., None] * shift)
        Image.fromarray((rgb * 255 + 0.5).astype(np.uint8)).save(os.path.join(PEOPLE, "%s_%s.png" % (out, g)))
        moved = (w > 0.5) & (np.abs(shift).sum(-1) > 0)
        done[g] = round(float(moved.mean()), 3)
    print("men: coloured", out, "(share of each texture moved)", done)
    return {"medians": {g: [round(float(x), 1) for x in m] for g, m in mids.items()}, "moved": done}


def plain_textures(man, base):
    """His textures as made (before any colours): kept by build_man, else his base body's."""
    out = {}
    for g in GARMENTS + ["skin"]:
        kept = os.path.join(ROOT, "build", "men_plain", "%s_%s.png" % (man, g))
        out[g] = kept if os.path.exists(kept) else os.path.join(PEOPLE, "%s_%s.png" % (base, g))
    return out


# --- build -------------------------------------------------------------------------------------

def part_of(group):
    """A vertex group's body part for `build` (its side dropped), or None."""
    g = group.rsplit("_", 1)[0] if group.endswith(("_r", "_l")) else group
    return g if g in PARTS else None


def warp(src, dst, build):
    """Every mesh of `src` moved about each body part's axis by `build` → `dst` (both glbs)."""
    import bpy
    from scipy.spatial import cKDTree
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
    meshes = [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("body_")]
    for o in list(bpy.data.objects):
        if o.type == "MESH" and o not in meshes:
            bpy.data.objects.remove(o)
    skin = bpy.data.objects["body_skin"]
    groups = [g.name for g in skin.vertex_groups]
    P = np.array([v.co[:] for v in skin.data.vertices])
    W = np.zeros((len(P), len(groups)))
    for v in skin.data.vertices:
        for ge in v.groups:
            W[v.index, ge.group] = ge.weight
    W /= np.maximum(W.sum(1, keepdims=True), 1e-9)
    own = W.argmax(1)
    # Each group's axis: the middle (x, y) of the skin it owns, height by height (z up here).
    lo, hi = P[:, 2].min(), P[:, 2].max()
    nb = int((hi - lo) / BIN_M) + 1
    axes = {}
    for gi, name in enumerate(groups):
        if part_of(name) is None:
            continue
        pts = P[own == gi]
        if len(pts) < 10:
            continue
        b = ((pts[:, 2] - lo) / BIN_M).astype(int)
        mids = np.full((nb, 2), np.nan)
        for k in np.unique(b):
            mids[k] = pts[b == k, :2].mean(0)
        have = ~np.isnan(mids[:, 0])
        idx = np.arange(nb)
        for c in range(2):      # carried flat past the part's ends, between bins by line
            mids[:, c] = np.interp(idx, idx[have], mids[have, c])
        axes[gi] = mids
    fx = np.ones(len(groups))
    fy = np.ones(len(groups))
    for gi, name in enumerate(groups):
        p = part_of(name)
        if p in build:
            fx[gi], fy[gi] = build[p]
    belly = float(build.get("belly", 1.0))
    front = 1.0 if P[np.argmax(np.abs(P[:, 1]) * (P[:, 2] > 1.6)), 1] > 0 else -1.0   # his nose
    # Each point takes its part's widening from his skin of its own family (his trunk, an arm, a
    # leg, his head: by its own weights): his hands hang by his waist, and the waistcoat's sides
    # took the arms' widening from them and hardly moved.
    skin_fam = family_of(groups, own)
    trees = {f: (cKDTree(P[skin_fam == f]), np.nonzero(skin_fam == f)[0]) for f in np.unique(skin_fam)}

    def moved(X, fam):
        # Weights smoothed over SMOOTH_M: blended from too few points, the hip's widening and
        # the thigh's changed within a centimetre, and the trousers there crossed the shirt.
        w = np.zeros((len(X), len(groups)))
        for f in np.unique(fam):
            tree, idx = trees.get(f, trees["trunk"])
            at = fam == f
            d, i = tree.query(X[at], min(NEAR, len(idx)))
            k = np.exp(-0.5 * (d / SMOOTH_M) ** 2) + 1e-12
            k /= k.sum(1, keepdims=True)
            w[at] = (W[idx[i]] * k[..., None]).sum(1)
        b = np.clip(((X[:, 2] - lo) / BIN_M).astype(int), 0, nb - 1)
        out = X.copy()
        for gi, mids in axes.items():
            if fx[gi] == 1.0 and fy[gi] == 1.0 and not (belly != 1.0 and groups[gi] == "abdomen"):
                continue
            off = X[:, :2] - mids[b]
            sx, sy = fx[gi], fy[gi]
            dy = off[:, 1] * (sy - 1)
            if groups[gi] == "abdomen":
                dy += np.where(off[:, 1] * front > 0, off[:, 1] * (belly - 1), 0)
            out[:, 0] += w[:, gi] * off[:, 0] * (sx - 1)
            out[:, 1] += w[:, gi] * dy
        return out

    for o in meshes:
        X = np.array([v.co[:] for v in o.data.vertices])
        names = [g.name for g in o.vertex_groups]
        Wo = np.zeros((len(X), len(names)))
        for v in o.data.vertices:
            for ge in v.groups:
                Wo[v.index, ge.group] = ge.weight
        Y = moved(X, family_of(names, Wo.argmax(1)))
        for v, y in zip(o.data.vertices, Y):
            v.co = y
        o.data.update()
        print("men: %s moved %.1f mm at most" % (o.name, 1000 * np.linalg.norm(Y - X, axis=1).max()))
    # His boots onto the ground: everything under SOLE_TOP squashed up so the soles are
    # SOLE_LIFT higher (the same map for every layer, so they keep their order).
    low = min(v.co.z for v in bpy.data.objects["body_boots"].data.vertices)
    k = (SOLE_TOP - low - SOLE_LIFT) / (SOLE_TOP - low)
    for o in meshes:
        for v in o.data.vertices:
            if v.co.z < SOLE_TOP:
                v.co.z = SOLE_TOP - (SOLE_TOP - v.co.z) * k
        o.data.update()
    for o in meshes:
        mend_strays(o)
    kept = drop_hidden_skin(skin, [o for o in meshes if o.name[5:] in GARMENTS])
    drop_shirt_tail(bpy.data.objects["body_shirt"], bpy.data.objects["body_trousers"])
    blend_seat(bpy.data.objects["body_trousers"])
    bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_skins=True, export_animations=False,
                              export_apply=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="NONE")
    return kept


def family_of(groups, dominant):
    """Each point's family by its strongest group: trunk, arm_r, arm_l, leg_r, leg_l or head."""
    fam = {}
    for gi, g in enumerate(groups):
        bits = g.split("_")
        side = "r" if "r" in bits[1:] else ("l" if "l" in bits[1:] else "")
        part = bits[0]
        if part in ("upper", "forearm", "hand", "finger"):
            fam[gi] = "arm_" + side
        elif part in ("thigh", "shin", "foot"):
            fam[gi] = "leg_" + side
        elif part == "head":
            fam[gi] = "head"
        else:
            fam[gi] = "trunk"
    return np.array([fam[int(d)] for d in dominant])


def mend_strays(o):
    """Patches skinned to a part they don't join (the fitter weights a point from the nearest
    skin: his palm lies against his thigh in the A-pose, and with his hands up a piece of it
    stayed at his hip) take their neighbours' weights: each part's points split into pieces
    joined by edges, any piece under STRAY_SHARE of that part's biggest is filled in from round it."""
    import bmesh
    names = [g.name for g in o.vertex_groups]
    n = len(o.data.vertices)
    W = np.zeros((n, len(names)))
    for v in o.data.vertices:
        for ge in v.groups:
            W[v.index, ge.group] = ge.weight
    dom = W.argmax(1)
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.verts.ensure_lookup_table()
    nbr = [[e.other_vert(v).index for e in v.link_edges] for v in bm.verts]
    bm.free()
    seen = np.full(n, -1)
    pieces = []
    for start in range(n):
        if seen[start] >= 0:
            continue
        piece, todo = [], [start]
        seen[start] = len(pieces)
        while todo:
            i = todo.pop()
            piece.append(i)
            for j in nbr[i]:
                if seen[j] < 0 and dom[j] == dom[start]:
                    seen[j] = len(pieces)
                    todo.append(j)
        pieces.append(piece)
    biggest = {}
    for p in pieces:
        biggest[dom[p[0]]] = max(biggest.get(dom[p[0]], 0), len(p))
    stray = np.zeros(n, bool)
    for p in pieces:
        if len(p) < STRAY_SHARE * biggest[dom[p[0]]]:
            stray[p] = True
    left = int(stray.sum())
    # Filled from the edge in: each pass, a stray point beside good ones takes their mean.
    while stray.any():
        fixed = []
        for i in np.nonzero(stray)[0]:
            good = [j for j in nbr[i] if not stray[j]]
            if good:
                W[i] = W[good].mean(0)
                fixed.append(i)
        if not fixed:
            break
        stray[fixed] = False
    if left:
        for gi, g in enumerate(o.vertex_groups):
            g.remove(list(range(n)))
            nz = np.nonzero(W[:, gi] > 1e-4)[0]
            for i in nz:
                g.add([int(i)], float(W[i, gi]), "REPLACE")
        print("men: %s: %d points skinned to a part they don't join, mended" % (o.name, left))


def drop_hidden_skin(skin, garments):
    """His skin under his clothes taken out: a skin point is hidden when straight out from it
    (its normal) a garment is within HIDDEN_M and no edge of his shirt (cuff, collar) is within
    EDGE_KEEP_M; a triangle goes when all three are. (The fitter paints his skin under his clothes
    in their colours, so what came through a sleeve didn't show till the shirt was recoloured.) What poked
    through the trousers at his hip as his thigh bent goes with it (and two thirds of his
    triangles). A ball's opening still shows his inside: BodyInterior draws it under every layer."""
    import bmesh
    from mathutils.bvhtree import BVHTree
    from scipy.spatial import cKDTree
    deps = __import__("bpy").context.evaluated_depsgraph_get()
    trees = [BVHTree.FromObject(g, deps, deform=False) for g in garments]
    edge_pts = []
    # Only the shirt's edges (cuffs, collar) show skin: the waistcoat's are over the shirt, the
    # trousers' under it and in the boots.
    for g in [g for g in garments if g.name == "body_shirt"]:
        bm = bmesh.new()
        bm.from_mesh(g.data)
        for e in bm.edges:
            if len(e.link_faces) < 2:
                a, b = e.verts[0].co, e.verts[1].co
                for t in np.linspace(0, 1, 4):
                    edge_pts.append(a.lerp(b, t)[:])
        bm.free()
    edges = cKDTree(np.array(edge_pts))
    co = np.array([v.co[:] for v in skin.data.vertices])
    near_edge = edges.query(co)[0] < EDGE_KEEP_M
    names = [g.name for g in skin.vertex_groups]
    hidden = np.zeros(len(co), bool)
    for v in skin.data.vertices:
        # His trunk, upper arms and legs are always clothed: what of them is out (a patch where
        # Rodin fused his palm to his thigh, at his hip; points by a cuff, out through the
        # trousers or a sleeve: the visual checks' "skin through") goes too, cuff or no cuff.
        part = max(v.groups, key=lambda ge: ge.weight).group if len(v.groups) else -1
        if part >= 0 and names[part].rsplit("_", 1)[0] in CLOTHED:
            hidden[v.index] = True
            continue
        if near_edge[v.index]:
            continue
        o = v.co + v.normal * 0.001
        hidden[v.index] = any(t.ray_cast(o, v.normal, HIDDEN_M)[0] is not None for t in trees)
    bm = bmesh.new()
    bm.from_mesh(skin.data)
    gone = [f for f in bm.faces if all(hidden[v.index] for v in f.verts)]
    before = len(bm.faces)
    bmesh.ops.delete(bm, geom=gone, context="FACES")
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bm.to_mesh(skin.data)
    bm.free()
    skin.data.update()
    print("men: skin under his clothes taken out: %d of %d triangles" % (len(gone), before))
    return before - len(gone)


def drop_shirt_tail(shirt, trousers):
    """His shirt tucked into his trousers ends TUCK_M under their waistband: the tail came out
    through the seat as he sat."""
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(trousers.data)
    top = [v.co.z for e in bm.edges if len(e.link_faces) < 2 for v in e.verts]
    bm.free()
    # The waistband: the open edge's highest ring (the hems are at his boots).
    waist = min(z for z in top if z > max(top) - 0.08) - TUCK_M
    bm = bmesh.new()
    bm.from_mesh(shirt.data)
    groups = [g.name for g in shirt.vertex_groups]
    dl = bm.verts.layers.deform.active
    def body(v):    # a point of his trunk's tube, not a sleeve or cuff
        w = v[dl] if dl else {}
        part = groups[max(w.items(), key=lambda x: x[1])[0]] if w else ""
        return part.rsplit("_", 1)[0] in ("pelvis", "abdomen", "thigh")
    gone = [f for f in bm.faces if all(v.co.z < waist and body(v) for v in f.verts)]
    bmesh.ops.delete(bm, geom=gone, context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(shirt.data)
    bm.free()
    print("men: shirt's tail under his waistband (%.3f m) taken out: %d triangles" % (waist, len(gone)))


def blend_seat(trousers):
    """His trousers' seat and legs (pieces of their own, garments.py) weighted alike where they
    meet: each point in the band round his crotch takes the mean of the pelvis and its own
    thigh's weights of the points near it (SEAT_BLEND_M, both pieces, its own side), so the seat
    and the leg's top move as one. Shot down with his legs splayed, the fly opened between them."""
    from scipy.spatial import cKDTree
    names = [g.name for g in trousers.vertex_groups]
    co = np.array([v.co[:] for v in trousers.data.vertices])
    W = np.zeros((len(co), len(names)))
    for v in trousers.data.vertices:
        for ge in v.groups:
            W[v.index, ge.group] = ge.weight
    thighs = [i for i, n in enumerate(names) if n.startswith("thigh")]
    crotch = co[W[:, thighs].sum(1) > 0.5, 2].max() if thighs else co[:, 2].max()
    band = np.nonzero((co[:, 2] > crotch - SEAT_BAND_M) & (co[:, 2] < crotch + SEAT_BAND_M))[0]
    tree = cKDTree(co)
    keep = [i for i, n in enumerate(names) if n == "pelvis" or n.startswith("thigh")]
    new = W.copy()
    for i in band:
        near = np.array(tree.query_ball_point(co[i], SEAT_BLEND_M))
        near = near[np.sign(co[near, 0]) == np.sign(co[i, 0])] if abs(co[i, 0]) > 0.01 else near
        k = np.exp(-0.5 * (np.linalg.norm(co[near] - co[i], axis=1) / (SEAT_BLEND_M / 2)) ** 2)
        w = (W[near][:, keep] * k[:, None]).sum(0) / k.sum()
        if w.sum() > 0.5:
            new[i] = 0
            new[i, keep] = w / w.sum()
    for gi, g in enumerate(trousers.vertex_groups):
        g.remove([int(i) for i in band])
        for i in band:
            if new[i, gi] > 1e-4:
                g.add([int(i)], float(new[i, gi]), "REPLACE")
    print("men: trousers' seat and legs blended over %d points round %.3f m" % (len(band), crotch))


def keep_head(head):
    """A head painted by rodin_portrait.py kept in assets/people/heads (build/ is wiped)."""
    if os.path.exists(os.path.join(HEADS, head + "_mesh.npz")):
        return
    m = np.load(os.path.join(WORK, head + "_mesh.npy"), allow_pickle=True).item()
    np.savez_compressed(os.path.join(HEADS, head + "_mesh.npz"), V=m["V"], T=m["T"], UV=m["UV"], pts=m["pts"])
    shutil.copy(os.path.join(WORK, head + "_paint.png"), os.path.join(HEADS, head + "_paint.png"))
    print("men: kept", head, "in", HEADS)


def eye_height(man, head):
    """How high his eyes are on the laid head (game y, m): the bust's irises (MediaPipe 468, 473,
    as neck_ring.py) found on his head by their texture point. PeopleBodies fits the hat's band
    above them (the head is laid at its own height, not the anatomy's EYE_HEIGHT)."""
    import bpy
    m = np.load(os.path.join(HEADS, head + "_mesh.npz"))
    V, UV, pts = m["V"], m["UV"], m["pts"]
    hs = []
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(PEOPLE, man + ".glb"))
    h = bpy.data.objects["body_head"]
    luv = np.array([d.uv[:] for d in h.data.uv_layers.active.data])
    lz = np.array([h.data.vertices[lp.vertex_index].co[2] for lp in h.data.loops])
    for k in (468, 473):
        uv = UV[np.argmin(np.linalg.norm(V - pts[k], axis=1))]
        d = np.minimum(np.linalg.norm(luv - uv, axis=1), np.linalg.norm(luv - [uv[0], 1 - uv[1]], axis=1))
        hs.append(float(lz[np.argmin(d)]))
    print("men: %s's eyes at %.3f m" % (man, np.mean(hs)))
    return round(float(np.mean(hs)), 4)


def build_man(man, spec, base):
    body = man + "_body"
    skin_tris = warp(os.path.join(PEOPLE, base + ".glb"), os.path.join(PEOPLE, body + ".glb"), spec["build"])
    for f in os.listdir(PEOPLE):
        if f.startswith(base + "_") and f.endswith(".png"):
            shutil.copy(os.path.join(PEOPLE, f), os.path.join(PEOPLE, body + f[len(base):]))
    rep = json.load(open(os.path.join(PEOPLE, base + ".json")))
    rep.update({"id": body, "build": spec["build"], "built_from": base})
    rep["triangles"] = dict(rep.get("triangles", {}), skin=skin_tris)
    json.dump(rep, open(os.path.join(PEOPLE, body + ".json"), "w"), indent=1)
    # The neck ring matches his face to his bare skin as the fitter wrote it (build/bare_skin: his
    # shirted skin is the shirt's colour at the neck, and turned every face yellow).
    bare = os.path.join(ROOT, "build", "bare_skin", base + "_skin.png")
    if not os.path.exists(bare):
        sys.exit("men: no %s: run tools/blender/fit_tripo.py --only=%s first" % (bare, base))
    shutil.copy(bare, os.path.join(ROOT, "build", "bare_skin", body + "_skin.png"))
    keep_head(spec["head"])
    # A fresh head texture each build (the head's paint is the approved one: it is a copy).
    for f in (man + "_head.png",):
        if os.path.exists(os.path.join(PEOPLE, f)):
            os.remove(os.path.join(PEOPLE, f))
    subprocess.run([sys.executable, os.path.join(HERE, "neck_ring.py"), "--body=" + body, "--head=" + spec["head"],
                    "--out=" + man, "--head_scale=%s" % HEAD_SCALE, "--collar=made"], check=True)
    rep = json.load(open(os.path.join(PEOPLE, man + ".json")))
    rep["hat_eye_y"] = eye_height(man, spec["head"])
    json.dump(rep, open(os.path.join(PEOPLE, man + ".json"), "w"), indent=1)
    # His warped body is a step on the way (men.py makes it again): not kept with the game's.
    for f in os.listdir(PEOPLE):
        if f.startswith(body + ".") or f.startswith(body + "_"):
            os.remove(os.path.join(PEOPLE, f))
    # His textures as made (before his colours), for his colours and his townsman ways.
    os.makedirs(os.path.join(ROOT, "build", "men_plain"), exist_ok=True)
    for g in GARMENTS + ["skin"]:
        shutil.copy(os.path.join(PEOPLE, "%s_%s.png" % (man, g)), os.path.join(ROOT, "build", "men_plain", "%s_%s.png" % (man, g)))


def finish_man(man, spec, base):
    rep = json.load(open(os.path.join(PEOPLE, man + ".json")))
    rep.update({"game_hat": True, "men": "tools/characters/men.py",
                "colours": recolour_man(man, plain_textures(man, base), spec["colours"], rep["skin_tone"])})
    json.dump(rep, open(os.path.join(PEOPLE, man + ".json"), "w"), indent=1)


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    a = dict(x.split("=", 1) for x in sys.argv[2:] if "=" in x)
    spec = json.load(open(SPEC))
    only = a["--only"].split(",") if "--only" in a else None
    for man, s in spec["men"].items():
        if only and man not in only:
            continue
        if cmd == "build":
            build_man(man, s, spec["from"])
        finish_man(man, s, spec["from"])
    for way, s in spec.get("ways", {}).items():
        if only and way not in only and s["man"] not in only:
            continue
        rep = json.load(open(os.path.join(PEOPLE, s["man"] + ".json")))
        rep.update({"id": way, "mesh_from": s["man"], "textures_from": s["man"],
                    "colours": recolour_man(way, plain_textures(s["man"], spec["from"]), s["colours"], rep["skin_tone"])})
        json.dump(rep, open(os.path.join(PEOPLE, way + ".json"), "w"), indent=1)
        print("men: wrote", way)


if __name__ == "__main__":
    main()
