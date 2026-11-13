"""Harlan's first-person arms, option 2 of #890's fallback (#896, the viewmodel rig lab): the
MetaHuman's hands cut at the wrist, on a first-person rig of their own, with modelled sleeves.

    ~/.venvs/studio/bin/python tools/blender/fp_arms.py \
        --src=../saltcreek-characters/frozen/sean_metahuman_s3/sean_metahuman_s3.glb \
        --out=experiments/viewmodel_rig/private [--cloth=experiments/viewmodel_rig/cloth]

What it makes (Godot space, metres; the man's rest pose, arms hanging):
  <out>/harlan_fp.glb   one armature `fp_rig` (per side: forearm_<s> as the root, hand_<s>, the 15
                        finger bones finger_<f>_<s>_<k>, the game skeleton's names) and three meshes:
                        `fp_hands` (his skin from the fingertips to KEEP_UP above the wrist, his own
                        weights, the twist bones folded into the forearm), `fp_cuffs` (the shirt's
                        cuff band, a button) and `fp_sleeves` (the coat's sleeve to near the elbow,
                        folds at the wrist, a turned hem).
  <out>/harlan_fp.json  the numbers: wrist and knuckle points, cut height, sleeve sizes, counts.
  <cloth>/wool_*.png, linen_*.png  the cloth (made here: the material library has woods only).

**The private folder is git-ignored:** the hands are the MetaHuman's mesh and skin, which never go in
this public repo (#692's licence rule; never used to train anything). The cloth and this script are
ours and are committed. Nothing in the game reads any of it: the lab (experiments/viewmodel_rig/) does.

Ideas, not code, from the usual first-person practice (a separate arms rig posed per weapon, the
sleeve hiding the cut: e.g. GDC talks on first-person viewmodels); written fresh here.
"""
import argparse
import json
import math
import os
import sys

import bpy  # first: bmesh and mathutils come with it
import bmesh
import numpy as np
from mathutils import Matrix, Vector

SIDES = ("r", "l")
FINGERS = ("thumb", "index", "middle", "ring", "little")
# His skin kept up the forearm from the wrist joint (m): inside the cuff and sleeve, so the cut never shows.
KEEP_UP = 0.095
# The shirt's cuff band: from just over the heel of the hand to up the wrist (m along the forearm).
CUFF_FROM, CUFF_TO = -0.010, 0.058
CUFF_CLEAR = 0.0055   # off his skin (m)
# The coat's sleeve: its hem a little above the cuff's lower edge, up to near the elbow.
SLEEVE_FROM, SLEEVE_TO = 0.030, 0.255
SLEEVE_CLEAR = (0.0125, 0.024)   # off his skin at the hem, at the top
TILE = 0.03   # one cloth texture tile (m)


def args():
    p = argparse.ArgumentParser()
    p.add_argument("--src", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--cloth", default="experiments/viewmodel_rig/cloth")
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    return p.parse_args(argv)


# --- the cloth -----------------------------------------------------------------------------------

def _height_to_normal(h, strength):
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * strength
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * strength
    n = np.stack([-gx, gy, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return (n * 0.5 + 0.5)


def _periodic_noise(n, cells, rng):
    """Smooth noise that tiles: a sum of a few random waves with whole periods across the tile."""
    y, x = np.mgrid[0:n, 0:n] / n
    out = np.zeros((n, n))
    for _ in range(24):
        kx, ky = rng.integers(-cells, cells + 1, 2)
        if kx == 0 and ky == 0:
            continue
        out += rng.normal() * np.sin(2 * np.pi * (kx * x + ky * y) + rng.uniform(0, 6.3)) / math.hypot(kx, ky)
    return (out - out.min()) / (np.ptp(out) + 1e-9)


def make_cloth(folder):
    """Wool twill for the coat (2/2 twill: diagonal wales ~1 mm apart), plain-weave linen for the
    shirt (warp and weft ~0.6 mm, with slubs). 512 px a 3 cm tile, seamless; albedo, normal and
    roughness (in the glTF way: G roughness, B metal)."""
    from PIL import Image
    os.makedirs(folder, exist_ok=True)
    n = 512
    rng = np.random.default_rng(896)
    y, x = np.mgrid[0:n, 0:n].astype(float)
    # Wool twill: 30 wales across the tile on the diagonal, the yarns' twist within each.
    wales = 30
    t = (x + y) / n * wales
    rib = 0.5 + 0.5 * np.cos(2 * np.pi * t)
    twist = 0.5 + 0.5 * np.cos(2 * np.pi * ((x - y) / n * wales * 3))
    fuzz = _periodic_noise(n, 40, rng)
    mottle = _periodic_noise(n, 3, rng)
    h = rib ** 1.5 * (0.8 + 0.2 * twist) + 0.25 * fuzz
    base = np.array([0.205, 0.165, 0.125])   # a worn brown wool, sun-faded (linear-ish sRGB values below)
    shade = (0.72 + 0.28 * rib * (0.85 + 0.15 * twist)) * (0.9 + 0.2 * mottle) * (0.93 + 0.14 * fuzz)
    alb = np.clip(base[None, None, :] * shade[..., None] * 1.0, 0, 1)
    Image.fromarray((alb ** (1 / 1.0) * 255).astype(np.uint8)).save(f"{folder}/wool_albedo.png")
    Image.fromarray((_height_to_normal(h, 2.2) * 255).astype(np.uint8)).save(f"{folder}/wool_normal.png")
    rough = np.clip(0.86 + 0.1 * fuzz - 0.06 * rib, 0, 1)
    orm = np.stack([np.ones_like(rough), rough, np.zeros_like(rough)], -1)
    Image.fromarray((orm * 255).astype(np.uint8)).save(f"{folder}/wool_orm.png")
    # Linen, plain weave: 50 threads each way across the tile, over-under, uneven yarn (slubs).
    th = 50
    u, v = x / n * th, y / n * th
    over = ((np.floor(u) + np.floor(v)) % 2)
    warp = np.sin(np.pi * (v % 1.0)) ** 0.7
    weft = np.sin(np.pi * (u % 1.0)) ** 0.7
    h = np.where(over > 0, warp * (0.6 + 0.4 * np.sin(np.pi * (u % 1.0))), weft * (0.6 + 0.4 * np.sin(np.pi * (v % 1.0))))
    slub = _periodic_noise(n, 20, rng)
    soil = _periodic_noise(n, 2, rng)
    h = h * (0.75 + 0.5 * slub)
    base = np.array([0.80, 0.76, 0.66])   # unbleached linen, a day's wear
    shade = (0.82 + 0.18 * h) * (0.9 + 0.1 * slub) * (0.92 + 0.08 * soil)
    alb = np.clip(base[None, None, :] * shade[..., None], 0, 1)
    Image.fromarray((alb * 255).astype(np.uint8)).save(f"{folder}/linen_albedo.png")
    Image.fromarray((_height_to_normal(h, 1.6) * 255).astype(np.uint8)).save(f"{folder}/linen_normal.png")
    rough = np.clip(0.82 + 0.1 * slub, 0, 1)
    orm = np.stack([np.ones_like(rough), rough, np.zeros_like(rough)], -1)
    Image.fromarray((orm * 255).astype(np.uint8)).save(f"{folder}/linen_orm.png")


def cloth_material(name, folder, stem):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    def img(file, colour):
        node = nt.nodes.new("ShaderNodeTexImage")
        node.image = bpy.data.images.load(os.path.abspath(f"{folder}/{file}"))
        if not colour:
            node.image.colorspace_settings.name = "Non-Color"
        return node
    a = img(f"{stem}_albedo.png", True)
    nt.links.new(a.outputs["Color"], bsdf.inputs["Base Color"])
    o = img(f"{stem}_orm.png", False)
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(o.outputs["Color"], sep.inputs["Color"])
    nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
    nt.links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])
    nm = img(f"{stem}_normal.png", False)
    nmap = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(nm.outputs["Color"], nmap.inputs["Color"])
    nt.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def plain_material(name, rgb, rough):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1.0)
    b.inputs["Roughness"].default_value = rough
    return m


# --- the hands -----------------------------------------------------------------------------------

def frames(arm):
    """Per side: the wrist, the elbow, the forearm's axis (wrist to elbow), and a hand frame: x the
    back of the hand, y from the little finger's knuckle to the index's, z from the middle knuckle
    to the wrist (HeldHand's hand space; for the left hand x is its palm, its mirror)."""
    mw = arm.matrix_world
    bones = arm.data.bones
    out = {}
    for s in SIDES:
        w = mw @ bones[f"hand_{s}"].head_local
        e = mw @ bones[f"forearm_{s}"].head_local
        ki = mw @ bones[f"finger_index_{s}_0"].head_local
        km = mw @ bones[f"finger_middle_{s}_0"].head_local
        kl = mw @ bones[f"finger_little_{s}_0"].head_local
        z = (w - km).normalized()
        y = ki - kl
        y = (y - z * y.dot(z)).normalized()
        x = y.cross(z)
        out[s] = {"wrist": w, "elbow": e, "axis": (e - w).normalized(), "x": x, "y": y, "z": z,
                  "k_index": ki, "k_middle": km, "k_little": kl}
    return out


def cut_hands(skin, fr):
    """A copy of his skin with only the hands and the forearms' last KEEP_UP kept, each vertex by its
    own side's weights (his hands hang by his thighs: weights, not distance, say what's his hand)."""
    hands = skin.copy()
    hands.data = skin.data.copy()
    hands.name = "fp_hands"
    bpy.context.collection.objects.link(hands)
    groups = {g.index: g.name for g in hands.vertex_groups}
    mw = hands.matrix_world
    keep = []
    counts = {s: 0 for s in SIDES}
    for v in hands.data.vertices:
        p = mw @ v.co
        best = None
        for s in SIDES:
            chain = 0.0
            for g in v.groups:
                n = groups[g.group]
                if n.endswith(f"_{s}") or f"_{s}_" in n:
                    if n.startswith(("forearm", "hand", "finger")):
                        chain += g.weight
            if chain > 0.5:
                best = s
        ok = False
        if best:
            f = fr[best]
            ok = (p - f["wrist"]).dot(f["axis"]) < KEEP_UP
        keep.append(ok)
        if ok:
            counts[best] += 1
    bm = bmesh.new()
    bm.from_mesh(hands.data)
    bm.verts.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not keep[v.index]], context="VERTS")
    bm.to_mesh(hands.data)
    bm.free()
    # Twist bones fold into the forearm (the first-person rig has none; the sleeve covers the forearm).
    vg = hands.vertex_groups
    for s in SIDES:
        fa = vg.get(f"forearm_{s}")
        for tw in (f"forearm_twist_{s}_0", f"forearm_twist_{s}_1"):
            g = vg.get(tw)
            if g is None:
                continue
            for v in hands.data.vertices:
                for e in v.groups:
                    if e.group == g.index and e.weight > 0:
                        fa.add([v.index], e.weight, "ADD")
            vg.remove(g)
    return hands, counts


def trim_armature(arm):
    """Only the first-person rig's bones: forearm_<s> (now a root), hand_<s>, the fingers."""
    keep = set()
    for s in SIDES:
        keep |= {f"forearm_{s}", f"hand_{s}"} | {f"finger_{f}_{s}_{k}" for f in FINGERS for k in range(3)}
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    for s in SIDES:
        eb[f"forearm_{s}"].parent = None
    for b in list(eb):
        if b.name not in keep:
            eb.remove(b)
    bpy.ops.object.mode_set(mode="OBJECT")
    arm.name = "fp_rig"
    arm.data.name = "fp_rig"


# --- the sleeves ---------------------------------------------------------------------------------

def slices(hands, fr, s, hs):
    """His forearm's cross-section at each height (m above the wrist along the forearm): the centre
    and the half-extents along the back of the hand (x) and across it (y), from his own skin."""
    f = fr[s]
    mw = hands.matrix_world
    pts = np.array([tuple(mw @ v.co) for v in hands.data.vertices])
    w = np.array(f["wrist"])
    a, x = np.array(f["axis"]), np.array(f["x"])
    y = np.cross(a, x)
    rel = pts - w
    h = rel @ a
    side = (rel @ np.array(f["y"]))   # keep only this side's points: they're near this wrist
    near = np.linalg.norm(rel - np.outer(h, a), axis=1) < 0.09
    out = []
    for hh in hs:
        sel = near & (np.abs(h - hh) < 0.006)
        if sel.sum() < 6:
            out.append(out[-1] if out else (0.0, 0.0, 0.03, 0.025))
            continue
        px, py = rel[sel] @ x, rel[sel] @ y
        cx, cy = (px.max() + px.min()) / 2, (py.max() + py.min()) / 2
        out.append((cx, cy, (px.max() - px.min()) / 2, (py.max() - py.min()) / 2))
    return out


def tube(name, fr, s, hs, sec, clear, folds, hem, mat, group, segs=48):
    """A cloth tube round the forearm: rings at heights `hs`, each an ellipse round that height's
    section plus `clear` (a number or (at the first ring, at the last)), pushed in and out by
    `folds(h, theta)` (m), UVs by the cloth's own scale. `hem` turns the first ring's edge back on
    itself (a folded edge with thickness) so the open end reads as cloth, not a shell."""
    f = fr[s]
    w, a, x = f["wrist"], f["axis"], f["x"]
    y = a.cross(x)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    rings = []
    rows = []
    n = len(hs)
    for i, h in enumerate(hs):
        c = clear if isinstance(clear, float) else clear[0] + (clear[1] - clear[0]) * i / max(n - 1, 1)
        cx, cy, rx, ry = sec[i]
        ring = []
        for j in range(segs):
            th = 2 * math.pi * j / segs
            r = 1.0 + folds(h, th) / max(rx, ry)
            p = w + a * h + x * (cx + (rx + c) * r * math.cos(th)) + y * (cy + (ry + c) * r * math.sin(th))
            ring.append(bm.verts.new(p))
        rings.append(ring)
        rows.append((h, rx + c, ry + c))
    if hem:
        # The hem: the edge turned inside by 1.2 cm, 3 mm in from the outside.
        h0 = hs[0]
        cx, cy, rx, ry = sec[0]
        c = clear if isinstance(clear, float) else clear[0]
        inner = []
        for j in range(segs):
            th = 2 * math.pi * j / segs
            r = 1.0 + folds(h0, th) / max(rx, ry)
            p = w + a * (h0 + 0.012) + x * (cx + (rx + c - 0.003) * r * math.cos(th)) + y * (cy + (ry + c - 0.003) * r * math.sin(th))
            inner.append(bm.verts.new(p))
        rings.insert(0, inner)
        rows.insert(0, (h0 + 0.012, rx + c - 0.003, ry + c - 0.003))
    bm.verts.ensure_lookup_table()
    for i in range(len(rings) - 1):
        for j in range(segs):
            j2 = (j + 1) % segs
            face = bm.faces.new((rings[i][j], rings[i][j2], rings[i + 1][j2], rings[i + 1][j]))
            for k, (ri, jj) in enumerate(((i, j), (i, j2), (i + 1, j2), (i + 1, j))):
                h, rx, ry = rows[ri]
                per = math.pi * (3 * (rx + ry) - math.sqrt((3 * rx + ry) * (rx + 3 * ry)))
                u = (jj if not (jj == 0 and j == segs - 1) else segs) / segs * per / TILE
                # the hem's turned-in ring reads along the cloth's length as the run doubles back
                v = (h if ri > 0 or not hem else hs[0] - 0.012) / TILE
                face.loops[k][uv].uv = (u, v)
    # A tube's outside should face out: our winding faces in for a right-handed (x, y, a); flip if so.
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    me.materials.append(mat)
    for p in me.polygons:
        p.use_smooth = True
    g = ob.vertex_groups.new(name=group)
    g.add(list(range(len(me.vertices))), 1.0, "REPLACE")
    return ob


def button(name, fr, s, h, sec, clear, mat):
    """A shirt button on the cuff's outer side (the little finger's side of the wrist), 9 mm."""
    f = fr[s]
    w, a, x = f["wrist"], f["axis"], f["x"]
    y = a.cross(x)
    cx, cy, rx, ry = sec
    # the little finger's side: -y in hand space for both hands (y runs little -> index)
    dirv = (f["y"] * -1.0)
    dirv = (dirv - a * dirv.dot(a)).normalized()
    th = math.atan2(dirv.dot(y), dirv.dot(x))
    p = w + a * h + x * (cx + (rx + clear) * math.cos(th)) + y * (cy + (ry + clear) * math.sin(th))
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.0045, radius2=0.0042, depth=0.0018)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    me.materials.append(mat)
    rot = Vector((0, 0, 1)).rotation_difference(dirv).to_matrix().to_4x4()
    ob.matrix_world = Matrix.Translation(p + dirv * 0.0009) @ rot
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    ob.select_set(False)
    ob.vertex_groups.new(name=f"forearm_{s}").add(list(range(len(me.vertices))), 1.0, "REPLACE")
    return ob


def coat_folds(h, th):
    """The coat sleeve's folds (m out from the ellipse): it bunches where it rests on the cuff, a
    few soft rings broken round the arm, strongest in the first 10 cm, a slight sag under the arm."""
    env = max(0.0, 1.0 - (h - SLEEVE_FROM) / 0.12) ** 1.3
    ring = math.sin(2 * math.pi * (h + 0.006 * math.sin(2 * th + 0.7) + 0.004 * math.sin(5 * th)) / 0.026)
    lobes = math.sin(3 * th + 11.0 * h) * 0.5 + math.sin(5 * th + 1.3) * 0.25
    sag = 0.0025 * max(0.0, -math.sin(th))   # the underside hangs a little
    return 0.0032 * env * ring + 0.0018 * env * lobes + sag + 0.0010 * math.sin(4 * th + 23 * h)


def cuff_folds(h, th):
    """The cuff band is stiff: only a soft wave where it's gathered at the top."""
    top = max(0.0, (h - (CUFF_TO - 0.015)) / 0.015)
    return 0.0012 * top * math.sin(9 * th)


def to_rig(ob, rig):
    ob.parent = rig
    ob.matrix_parent_inverse = rig.matrix_world.inverted()
    mod = ob.modifiers.new("rig", "ARMATURE")
    mod.object = rig


def main():
    a = args()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    make_cloth(a.cloth)
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(a.src))
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    skin = bpy.data.objects["body_skin"]
    fr = frames(arm)
    hands, counts = cut_hands(skin, fr)
    for o in list(bpy.data.objects):
        if o not in (arm, hands):
            bpy.data.objects.remove(o, do_unlink=True)
    trim_armature(arm)
    wool = cloth_material("wool_coat", a.cloth, "wool")
    linen = cloth_material("linen_shirt", a.cloth, "linen")
    horn = plain_material("button_bone", (0.62, 0.56, 0.45), 0.45)
    info = {"src": os.path.basename(a.src), "keep_up_m": KEEP_UP, "kept_vertices": counts, "sides": {}}
    made = []
    for s in SIDES:
        hc = [CUFF_FROM + (CUFF_TO - CUFF_FROM) * i / 10 for i in range(11)]
        sc = slices(hands, fr, s, [min(h, KEEP_UP - 0.006) for h in hc])
        # a cuff is a band: one section for its length, the widest of his wrist under it
        wide = (float(np.mean([q[0] for q in sc])), float(np.mean([q[1] for q in sc])),
                max(q[2] for q in sc), max(q[3] for q in sc))
        made.append(tube(f"fp_cuff_{s}", fr, s, hc, [wide] * len(hc), CUFF_CLEAR, cuff_folds, True, linen, f"forearm_{s}"))
        made.append(button(f"fp_button_{s}", fr, s, (CUFF_FROM + CUFF_TO) * 0.5, wide, CUFF_CLEAR, horn))
        hs = [SLEEVE_FROM + (SLEEVE_TO - SLEEVE_FROM) * i / 28 for i in range(29)]
        ss = slices(hands, fr, s, [min(h, KEEP_UP - 0.006) for h in hs])
        # past his kept skin the forearm thickens towards the elbow (~+35% at 25 cm)
        ss = [(q[0], q[1], q[2] * (1 + 1.4 * max(0.0, h - KEEP_UP)), q[3] * (1 + 1.4 * max(0.0, h - KEEP_UP))) for q, h in zip(ss, hs)]
        # the hem sits over the cuff: never tighter than the cuff plus cloth
        ss = [(q[0], q[1], max(q[2], wide[2] + CUFF_CLEAR), max(q[3], wide[3] + CUFF_CLEAR)) for q in ss]
        made.append(tube(f"fp_sleeve_{s}", fr, s, hs, ss, SLEEVE_CLEAR, coat_folds, True, wool, f"forearm_{s}"))
        f = fr[s]
        # in Godot's space (glTF: x, z, -y)
        info["sides"][s] = {k: [round(f[k].x, 4), round(f[k].z, 4), round(-f[k].y, 4)] for k in ("wrist", "elbow", "k_index", "k_middle", "k_little")}
        info["sides"][s]["cuff_half_extents_m"] = [round(wide[2] + CUFF_CLEAR, 4), round(wide[3] + CUFF_CLEAR, 4)]
    # Join: the cuffs with their buttons, the sleeves; all on the rig.
    def join(names, into):
        obs = [o for o in bpy.data.objects if o.name.startswith(names)]
        bpy.ops.object.select_all(action="DESELECT")
        for o in obs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = obs[0]
        bpy.ops.object.join()
        obs[0].name = into
        return obs[0]
    cuffs = join(("fp_cuff", "fp_button"), "fp_cuffs")
    sleeves = join(("fp_sleeve",), "fp_sleeves")
    for ob in (cuffs, sleeves):
        to_rig(ob, arm)
    sol = sleeves.modifiers.new("thick", "SOLIDIFY")
    sol.thickness = 0.0022
    sol.offset = -1.0
    bpy.context.view_layer.objects.active = sleeves
    bpy.ops.object.modifier_move_to_index(modifier="thick", index=0)
    sol = cuffs.modifiers.new("thick", "SOLIDIFY")
    sol.thickness = 0.0012
    sol.offset = -1.0
    bpy.context.view_layer.objects.active = cuffs
    bpy.ops.object.modifier_move_to_index(modifier="thick", index=0)
    info["triangles"] = {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in (hands, cuffs, sleeves)}
    os.makedirs(a.out, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=os.path.abspath(f"{a.out}/harlan_fp.glb"), export_format="GLB",
                              use_selection=True, export_skins=True, export_apply=True,
                              export_animations=False, export_yup=True)
    with open(f"{a.out}/harlan_fp.json", "w") as fh:
        json.dump(info, fh, indent=1)
    print("fp arms:", json.dumps(info["triangles"]), "kept", counts)


main()
