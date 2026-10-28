"""Builds the walk on the game horse (its own copy, the hind legs fixed: rigtools.fix_hind) as a
looping action, measures it, and saves build/horse_walk/walk.blend (and walk.glb).

    ~/bpyenv/bin/python experiments/horse_walk/blender/walk_build.py [--T=1.1] [--L=1.5] [--duty=0.62]
        [--lateral=0.30] [--no-fix]

The action "walk" is in place (the root stays; planted hooves slide back at the walking speed);
the preview's armature object is moved forward at that speed ("walk_root") so planted hooves stand.
Prints and writes build/horse_walk/walk_report.json: slide of each planted hoof (from the bones,
the evaluated pose), the footfalls and duty factors read back off the toes' heights, each joint's
range over the stride, folded triangles in each leg.
"""
import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as C  # noqa: E402
import gait as G  # noqa: E402
import rigtools as R  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
opts = dict(a[2:].split("=", 1) for a in args if a.startswith("--") and "=" in a)
W = G.Walk(T=float(opts.get("T", 1.1)), L=float(opts.get("L", 1.5)), duty=float(opts.get("duty", 0.62)),
           lateral=float(opts.get("lateral", 0.30)))

arm = C.load()
arm.animation_data.action = None
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
if "--no-fix" not in args:
    R.fix_hind(arm, meshes)
bones = arm.data.bones
REST = {b.name: np.array(b.matrix_local) for b in bones}
HEAD = {b.name: np.array(b.head_local[:]) for b in bones}
TAIL = {b.name: np.array(b.tail_local[:]) for b in bones}
PARENT = {b.name: (b.parent.name if b.parent else None) for b in bones}


def uz(p):
    return np.array([-p[0], p[2]])


def ry(deg_or_rad, pivot, rad=True):
    a = deg_or_rad if rad else math.radians(deg_or_rad)
    c, s = math.cos(a), math.sin(a)
    M = np.eye(4)
    M[0, 0], M[0, 2], M[2, 0], M[2, 2] = c, s, -s, c
    T1, T2 = np.eye(4), np.eye(4)
    T1[:3, 3] = pivot
    T2[:3, 3] = -np.asarray(pivot)
    return T1 @ M @ T2


def rz(deg, pivot):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    M = np.eye(4)
    M[0, 0], M[0, 1], M[1, 0], M[1, 1] = c, -s, s, c
    T1, T2 = np.eye(4), np.eye(4)
    T1[:3, 3] = pivot
    T2[:3, 3] = -np.asarray(pivot)
    return T1 @ M @ T2


def trans(d):
    M = np.eye(4)
    M[:3, 3] = d
    return M


CHAINS = {}
for leg, names in C.LEGS.items():
    fore = leg[1] == "F"
    seg = names[:-1]              # the hoof bone is placed from the target, not solved
    pts = [uz(HEAD[seg[0]])] + [uz(TAIL[n]) for n in seg]
    joints = ["shoulder", "elbow", "knee", "fetlock"] if fore else ["stifle", "hock", "fetlock"]
    chain = G.Leg(pts, joints, G.FORE_LIMITS if fore else G.HIND_LIMITS, G.FORE_ROOT if fore else G.HIND_ROOT)
    hoof = names[-1]
    hv = uz(TAIL[hoof]) - uz(HEAD[hoof])
    CHAINS[leg] = {"chain": chain, "seg": seg, "hoof": hoof, "fore": fore,
                   "toe": uz(TAIL[hoof]), "hoof_len": float(np.linalg.norm(hv)),
                   "hoof_rest": math.atan2(hv[1], hv[0]),
                   "coffin_rest": math.atan2(hv[1], hv[0]) - chain.rest_abs[-1]}

PIVOT = HEAD["body"]
WITHERS_U, CROUP_U = uz(HEAD["scapula.L"])[0], uz(HEAD["thigh.L"])[0]


def pose(t):
    """Every bone's A (posed = A @ rest, armature space) at time t, in place; and per leg the
    solve's joint changes (degrees) and the target miss (m)."""
    A = {"root": np.eye(4)}
    rw, rc = W.trunk(t)
    pitch = math.atan2(rw - rc, WITHERS_U - CROUP_U)          # + lifts the front
    Ab = trans([0, 0, (rw + rc) / 2]) @ ry(pitch, PIVOT)
    for n in ("body", "pelvis", "spine", "chest"):
        A[n] = Ab
    info = {}
    for leg, c in CHAINS.items():
        ch = c["chain"]
        anchor = uz((Ab @ np.append(HEAD[c["seg"][0]], 1))[:3])
        (tu, tz), ha = W.hoof(leg, t, c["toe"], c["hoof_rest"])
        tu -= W.v * t                                           # in place
        coronet = np.array([tu, tz]) - c["hoof_len"] * np.array([math.cos(ha), math.sin(ha)])
        rel, pts, absang, miss = ch.solve(anchor, coronet, W.prefs(leg, t), tilt=pitch,
                                          hoof=ha, rest_coffin=c["coffin_rest"])
        for i, n in enumerate(c["seg"]):
            new_head = np.array([-pts[i][0], HEAD[n][1], pts[i][1]])
            A[n] = trans(new_head - HEAD[n]) @ ry(absang[i] - ch.rest_abs[i], HEAD[n])
        h = c["hoof"]
        A[h] = trans(np.array([-coronet[0], HEAD[h][1], coronet[1]]) - HEAD[h]) @ ry(ha - c["hoof_rest"], HEAD[h])
        d = (rel - ch.rest_rel) / G.D2R
        info[leg] = {"joints": dict(zip(["root"] + ch.joints, d.tolist())), "miss": miss,
                     "coffin": (ha - absang[-1] - c["coffin_rest"]) / G.D2R}
    nod = math.radians(W.neck(t))
    low = math.radians(W.neck_carriage)
    An = Ab @ ry(0.6 * low - 0.6 * nod, HEAD["neck1"])
    A["neck1"] = An
    A["neck2"] = An @ ry(0.4 * low - 0.3 * nod, HEAD["neck2"])
    A["neck3"] = A["neck2"] @ ry(-0.1 * nod, HEAD["neck3"])
    A["head"] = A["neck3"] @ ry(math.radians(W.head_carriage) + 0.3 * nod, HEAD["head"])
    for e in ("ear.L", "ear.R"):
        A[e] = A["head"]
    prev = Ab
    for k in range(1, 7):
        n = "tail%d" % k
        if n not in HEAD:
            break
        # sideways once a stride, and a lagging lift and drop with the croup's rise, twice
        prev = prev @ rz(W.tail(t, k), HEAD[n]) @ ry(math.radians(0.8) * math.sin(4 * math.pi * (t / W.T - 0.05 * k)), HEAD[n])
        A[n] = prev
    return A, info


def key(action_name):
    arm.animation_data_create()
    act = bpy.data.actions.new(action_name)
    arm.animation_data.action = act
    prev = {}
    infos = []
    for f in range(W.frames + 1):
        t = f / W.fps
        A, info = pose(t % W.T)
        infos.append(info)
        for pb in arm.pose.bones:
            pb.rotation_mode = "QUATERNION"
            n = pb.name
            Ap = A[PARENT[n]] if PARENT[n] else np.eye(4)
            basis = np.linalg.inv(REST[n]) @ np.linalg.inv(Ap) @ A[n] @ REST[n]
            loc, rot, _ = Matrix(basis.tolist()).decompose()
            if n in prev and prev[n].dot(rot) < 0:
                rot.negate()
            prev[n] = rot.copy()
            pb.location = loc
            pb.rotation_quaternion = rot
            pb.keyframe_insert("location", frame=f)
            pb.keyframe_insert("rotation_quaternion", frame=f)
    for fc in _fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    return act, infos


def _fcurves(act):
    if hasattr(act, "fcurves") and len(act.fcurves):
        return list(act.fcurves)
    out = []
    for layer in getattr(act, "layers", []):
        for strip in layer.strips:
            for bag in strip.channelbags:
                out.extend(bag.fcurves)
    return out


act, infos = key("walk")
sc = bpy.context.scene
sc.render.fps = W.fps
sc.frame_start, sc.frame_end = 0, W.frames - 1

# --- measure, from the evaluated pose: root motion on, hooves in the world ----------------------
SUB = 2   # samples between keys (the game samples between keys too)
toes = {leg: [] for leg in CHAINS}
times = []
for i in range(W.frames * SUB * 2):            # two strides
    fr = i / SUB
    sc.frame_set(int(math.floor(fr)) % W.frames, subframe=fr - math.floor(fr))
    t = fr / W.fps
    arm.location = (-W.v * t, 0, 0)
    bpy.context.view_layer.update()
    times.append(t)
    for leg, c in CHAINS.items():
        p = arm.matrix_world @ arm.pose.bones[c["hoof"]].tail
        toes[leg].append((p.x, p.y, p.z))
arm.location = (0, 0, 0)
times = np.array(times)
report = {"walk": {"T": W.T, "L": W.L, "v": round(W.v, 3), "duty": W.duty, "offsets": W.offset, "frames": W.frames},
          "legs": {}}
for leg, c in CHAINS.items():
    P = np.array(toes[leg])
    st = np.array([W.stance(leg, t % W.T) for t in times])
    # stances as runs; slide = the toe's largest distance from where it landed (x, z), over the
    # stance before breakover lifts the heel (the toe stays put through breakover too: included)
    runs, i = [], 0
    while i < len(st):
        if st[i]:
            j = i
            while j + 1 < len(st) and st[j + 1]:
                j += 1
            if i > 0 and j < len(st) - 1:
                runs.append((i, j))
            i = j + 1
        else:
            i += 1
    slides = [float(np.max(np.linalg.norm(P[a:b + 1][:, [0, 2]] - P[a][[0, 2]], axis=1))) for a, b in runs]
    # duty and landing read back from the toe's height (on the ground = within 5 mm of where it
    # stands at rest); and how far it ever goes under that (keys blended at breakover)
    z = P[:, 2]
    zr = c["toe"][1]
    down = z < zr + 0.005
    j = {k: [inf[leg]["joints"][k] for inf in infos] for k in infos[0][leg]["joints"]}
    report["legs"][leg] = {
        "slide_cm_max": round(100 * max(slides), 3) if slides else None,
        "duty_from_toe": round(float(down.mean()), 3),
        "lift_cm": round(100 * float(z.max() - zr), 1),
        "below_ground_mm": round(1000 * float(max(0.0, zr - z.min())), 1),
        "miss_worst_phase": round(W.phase(leg, max(range(len(infos)), key=lambda k: infos[k][leg]["miss"]) / W.fps), 2),
        "joint_ranges_deg": {k: [round(min(v), 1), round(max(v), 1)] for k, v in j.items()},
        "coffin_range_deg": [round(min(inf[leg]["coffin"] for inf in infos), 1), round(max(inf[leg]["coffin"] for inf in infos), 1)],
        "miss_mm_max": round(1000 * max(inf[leg]["miss"] for inf in infos), 2),
    }
# the footfall order read from the toes: each leg's first landing in the second stride
land = {}
for leg in CHAINS:
    z = np.array([p[2] for p in toes[leg]])
    down = z < CHAINS[leg]["toe"][1] + 0.005
    idx = [k for k in range(1, len(down)) if down[k] and not down[k - 1]]
    land[leg] = [round(times[k] / W.T, 3) for k in idx]
report["landings_in_strides"] = land
report["under_ground_at"] = {leg: sorted({round(W.phase(leg, times[k] % W.T), 2) for k in range(len(times))
                                          if toes[leg][k][2] < CHAINS[leg]["toe"][1] - 0.002}) for leg in CHAINS}
print("under at phases", report["under_ground_at"])
report["misses_over_5mm"] = {leg: [[round(W.phase(leg, k / W.fps), 2), round(1000 * inf[leg]["miss"])]
                                   for k, inf in enumerate(infos[:-1]) if inf[leg]["miss"] > 0.005] for leg in CHAINS}
print("misses", report["misses_over_5mm"])
# the cyclic order from the left hind's landing, and each landing's share of the stride after it
first = {leg: (v[0] % 1.0) for leg, v in land.items() if v}
lh = first["LH"]
seq = sorted(first, key=lambda leg: (first[leg] - lh) % 1.0)
report["order"] = seq
report["landing_after_LH"] = {leg: round((first[leg] - lh) % 1.0, 3) for leg in seq}
json.dump(report, open(os.path.join(C.OUT, "walk_report.json"), "w"), indent=1)
for leg, r in report["legs"].items():
    print(leg, "slide %.3f cm" % r["slide_cm_max"], "duty", r["duty_from_toe"], "lift", r["lift_cm"], "cm",
          "under", r["below_ground_mm"], "mm", "worst miss at phase", r["miss_worst_phase"],
          "miss", r["miss_mm_max"], "mm", "coffin", r["coffin_range_deg"], r["joint_ranges_deg"])
print("order", report["order"], report["landing_after_LH"])

# --- folds: a triangle turned more than 90 degrees away from where its own bone turned it --------
# (a hoof that is turned turns its triangles with it; a fold turns them against their bone)
coat = bpy.data.objects["coat"]


def tri_state(ob):
    dg = bpy.context.evaluated_depsgraph_get()
    e = ob.evaluated_get(dg)
    m = e.to_mesh()
    n = np.array([p.normal[:] for p in m.polygons])
    c = np.array([p.center[:] for p in m.polygons])
    e.to_mesh_clear()
    return n, c


gname = {g.index: g.name for g in coat.vertex_groups}
vbone = []
for v in coat.data.vertices:
    best = max(v.groups, key=lambda g: g.weight, default=None)
    vbone.append(gname[best.group] if best else "root")
pbone = []
for poly in coat.data.polygons:
    cnt = {}
    for vi in poly.vertices:
        cnt[vbone[vi]] = cnt.get(vbone[vi], 0) + 1
    pbone.append(max(cnt, key=cnt.get))
arm.animation_data.action = None
R.reset(arm)
bpy.context.view_layer.update()
n0, c0 = tri_state(coat)
arm.animation_data.action = act
worst = {}
for f in range(0, W.frames, 2):
    sc.frame_set(f)
    bpy.context.view_layer.update()
    rot = {pb.name: np.array((pb.matrix @ pb.bone.matrix_local.inverted()).to_3x3()) for pb in arm.pose.bones}
    n1, _ = tri_state(coat)
    pred = np.array([rot[b] @ n for b, n in zip(pbone, n0)])
    folded = np.einsum("ij,ij->i", pred, n1) < 0.0
    for name, sel in (("fore legs", (c0[:, 0] < -0.4) & (c0[:, 2] < 1.0)),
                      ("hind legs", (c0[:, 0] > 0.35) & (c0[:, 2] < 1.0)),
                      ("trunk, neck, head", (c0[:, 2] >= 1.0))):
        k = int(np.sum(folded & sel))
        if k >= worst.get(name, (0, 0))[0]:
            worst[name] = (k, f)
report["folded_triangles_worst"] = {k: {"count": v[0], "frame": v[1]} for k, v in worst.items()}
report["triangles"] = len(n0)
json.dump(report, open(os.path.join(C.OUT, "walk_report.json"), "w"), indent=1)
print("folded (worst frame)", report["folded_triangles_worst"], "of", len(n0))

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(C.OUT, "walk.blend"))
print("saved walk.blend")
# the horse with the walk as a glb (in place, 60 keys a second), for a later look in the game; not
# the game's asset (assets/creatures/horse/ is untouched)
for o in bpy.data.objects:
    o.select_set(o.type in ("ARMATURE", "MESH"))
bpy.ops.export_scene.gltf(filepath=os.path.join(C.OUT, "walk.glb"), export_format="GLB", use_selection=True,
                          export_skins=True, export_animations=True, export_force_sampling=True,
                          export_frame_step=1, export_def_bones=False, export_yup=True,
                          export_materials="NONE", export_attributes=False)
print("wrote walk.glb")
