"""Rodin's model of the horse (the Character Studio's `horse-shape`, from the picture set Sean
approved 2026-10-24: its inputs/horse/shape.glb) made ready for tools/blender/horse.py: turned to our
axes (his head at -X, his right +Y, the ground z = 0), scaled to his size (his ear tips at EAR_TOP,
a 15-hand horse's), centred on his barrel, and measured: each leg's joints, the poll, the muzzle,
the withers and the tail's line, set into horse_shape's landmarks so the skeleton, tack and
collision fit him as they fitted the sculpt.

Measured by slicing the mesh: below the belly a level cut through a leg is a ring round its bone,
so the ring's middle is the leg's line at that height; the joints are where the pictures' horse
has them on that line (fetlock, knee or hock, elbow or stifle). The tail is found by its paint (the
darkest of his coat behind the hocks, near his middle line).
"""
import math

import numpy as np

import horse_shape as hs

EAR_TOP = 2.05   # m: a 15-hand horse's ear tips (1.52 m at the withers)


def load(bpy, path):
    """Rodin's glb as one mesh object in our axes and size, its painted texture kept: (object, image)."""
    from mathutils import Matrix
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    for o in objs:
        o.data.transform(o.matrix_world)
        o.parent = None
        o.matrix_world = Matrix.Identity(4)
    if len(objs) > 1:
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        bpy.ops.object.join()
    obj = objs[0]
    for o in [o for o in bpy.data.objects if o not in before and o.type != "MESH"]:
        bpy.data.objects.remove(o)
    v = np.array([x.co[:] for x in obj.data.vertices])
    # His long way along x, his head (the ear tips: the top of him) at -x.
    ext = v.max(axis=0) - v.min(axis=0)
    top = v[v[:, 2] > np.quantile(v[:, 2], 0.995)]
    if ext[0] >= ext[1]:
        turn = 0.0 if top[:, 0].mean() < v[:, 0].mean() else math.pi
    else:
        turn = math.pi / 2 if top[:, 1].mean() > v[:, 1].mean() else -math.pi / 2
    obj.data.transform(Matrix.Rotation(turn, 4, "Z"))
    v = np.array([x.co[:] for x in obj.data.vertices])
    k = EAR_TOP / (v[:, 2].max() - v[:, 2].min())
    obj.data.transform(Matrix.Scale(k, 4) @ Matrix.Translation((0.0, 0.0, -v[:, 2].min())))
    v = np.array([x.co[:] for x in obj.data.vertices])
    trunk = v[(v[:, 2] > 1.0) & (v[:, 2] < 1.2)]
    mid = ((trunk[:, 0].min() + trunk[:, 0].max()) / 2, (trunk[:, 1].min() + trunk[:, 1].max()) / 2)
    obj.data.transform(Matrix.Translation((-mid[0], -mid[1], 0.0)))
    obj.data.update()
    obj.name = obj.data.name = "rodin_hi"
    image = None
    for m in obj.data.materials:
        if m and m.use_nodes:
            for n in m.node_tree.nodes:
                if n.bl_idname == "ShaderNodeTexImage" and n.image and "diffuse" in n.image.name.lower():
                    image = n.image
    if image is None:
        for m in obj.data.materials:
            for n in (m.node_tree.nodes if m and m.use_nodes else []):
                if n.bl_idname == "ShaderNodeTexImage" and n.image:
                    image = image or n.image
    return obj, image


def vertex_colours(obj, image):
    """His painted colour at each vertex (the texture under its UV), 0-1 RGB."""
    w, h = image.size
    px = np.array(image.pixels[:], dtype=np.float32).reshape(h, w, image.channels)[:, :, :3]
    uv = obj.data.uv_layers.active.data
    col = np.zeros((len(obj.data.vertices), 3))
    n = np.zeros(len(obj.data.vertices))
    for poly in obj.data.polygons:
        for li, vi in zip(poly.loop_indices, poly.vertices):
            u, t = uv[li].uv
            col[vi] += px[min(h - 1, max(0, int(t * h))), min(w - 1, max(0, int(u * w)))]
            n[vi] += 1
    return col / np.maximum(n, 1)[:, None]


def _ring(v, z, front, s, half=0.012):
    """The middle (x, y) of the level cut through one leg at height z (front or hind, side s), or None."""
    band = v[(np.abs(v[:, 2] - z) < half) & ((v[:, 0] < 0) == front) & (np.sign(v[:, 1]) == s) & (np.abs(v[:, 1]) > 0.02)]
    if len(band) < 6:
        return None
    # The leg's own ring: the cluster nearest the leg's line below (the band can reach the belly).
    return np.array([np.median(band[:, 0]), np.median(band[:, 1])])


def measure(obj, colours):
    """His landmarks from the mesh, set into horse_shape (legs, poll, muzzle, withers, tail); the
    tail's vertices (bool) returned for the weights and the UVs."""
    v = np.array([x.co[:] for x in obj.data.vertices])
    legs = {}
    for front in (True, False):
        for s in (-1.0, 1.0):
            pts = {}
            for z in (0.04, 0.12, 0.18, 0.3, 0.42, 0.5, 0.58, 0.66, 0.75):
                c = _ring(v, z, front, s)
                if c is not None:
                    pts[z] = c
            legs[(front, s)] = pts

    def at(pts, z):
        zs = sorted(pts)
        z0 = min(zs, key=lambda q: abs(q - z))
        return pts[z0]

    def p3(xy, z):
        return (float(xy[0]), float(xy[1]), float(z))

    joints = {}
    for s in (-1.0, 1.0):
        f = legs[(True, s)]
        fet, knee, up = at(f, 0.18), at(f, 0.5), at(f, 0.75)
        elbow = up + (up - knee) * (0.15 / 0.25)
        toe_band = v[(v[:, 2] < 0.03) & (v[:, 0] < 0) & (np.sign(v[:, 1]) == s)]
        toe_x = float(toe_band[:, 0].min()) if len(toe_band) else fet[0] - 0.06
        joints[("front", s)] = {
            "shoulder": (float(elbow[0]) - 0.17, s * 0.14, 1.08),
            "elbow": p3(elbow, 0.9),
            "knee": p3(knee, 0.5),
            "fetlock": p3(fet, 0.18),
            "coronet": p3(at(f, 0.04) + np.array([0.0, 0.0]), 0.075),
            "toe": (toe_x, float(fet[1]), 0.0),
        }
        h = legs[(False, s)]
        fet, hock, up = at(h, 0.18), at(h, 0.58), at(h, 0.75)
        stifle = up + (up - hock) * 0.75
        toe_band = v[(v[:, 2] < 0.03) & (v[:, 0] > 0) & (np.sign(v[:, 1]) == s)]
        toe_x = float(toe_band[:, 0].min()) if len(toe_band) else fet[0] - 0.06
        joints[("hind", s)] = {
            "hip": (float(stifle[0]) + 0.12, s * 0.15, 1.27),
            "stifle": p3(stifle, 0.9),
            "hock": p3(hock, 0.58),
            "fetlock": p3(fet, 0.18),
            "coronet": p3(at(h, 0.04), 0.075),
            "toe": (toe_x, float(fet[1]), 0.0),
        }
    hs.set_legs(joints)

    # The head: the ear tips are his top; the poll just behind and below them; the muzzle his front.
    ztop = v[:, 2].max()
    tips = v[v[:, 2] > ztop - 0.03]
    poll = (float(tips[:, 0].mean()) + 0.03, float(ztop) - 0.14)
    front = v[v[:, 0] < v[:, 0].min() + 0.02]
    muzzle = (float(v[:, 0].min()) + 0.06, float(front[:, 2].mean()))
    # The withers: the top of him a little behind the elbows.
    ex = joints[("front", 1.0)]["elbow"][0]
    near = v[(v[:, 0] > ex) & (v[:, 0] < ex + 0.35) & (np.abs(v[:, 1]) < 0.05)]
    wi = near[np.argmax(near[:, 2])] if len(near) else np.array([ex + 0.18, 0, 1.52])
    hs.set_head(poll, muzzle, (float(wi[0]), float(wi[2])))

    # The tail: the darkest paint behind the hocks, near his middle; its line by height.
    dark = colours.mean(axis=1)
    hock_x = max(joints[("hind", -1.0)]["hock"][0], joints[("hind", 1.0)]["hock"][0])
    tail = (dark < np.quantile(dark, 0.2)) & (v[:, 0] > hock_x + 0.03) & (np.abs(v[:, 1]) < 0.16) & (v[:, 2] > 0.35)
    tv = v[tail]
    line = []
    for z in np.arange(tv[:, 2].max() - 0.03, tv[:, 2].min(), -0.15):
        b = tv[np.abs(tv[:, 2] - z) < 0.04]
        if len(b):
            line.append((float(np.median(b[:, 0])), float(z)))
    # The dock first: where the tail leaves the croup (the tail's top, a little forward).
    if line:
        dock = (line[0][0] - 0.04, line[0][1] + 0.02)
        pts = [dock] + line
        # Six bones (horse_idle swings tail1..tail6): seven points along it.
        d = np.r_[0, np.cumsum([math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1)])]
        tt = np.linspace(0, d[-1], 7)
        hs.set_tail([(float(np.interp(t, d, [p[0] for p in pts])), float(np.interp(t, d, [p[1] for p in pts]))) for t in tt])
    # Every vertex near the tail's line behind the buttock is the tail's (the weights keep the tail's
    # bones to these).
    tail_mask = np.zeros(len(v), bool)
    for i in range(len(hs.TAIL) - 1):
        a = np.array([hs.TAIL[i][0], 0.0, hs.TAIL[i][1]])
        b = np.array([hs.TAIL[i + 1][0], 0.0, hs.TAIL[i + 1][1]])
        dist, _t = hs._seg_dist(v, a, b)
        tail_mask |= dist < 0.13
    tail_mask &= v[:, 0] > hs.TAIL[0][0] - 0.02
    tail_mask &= ~((v[:, 0] < hock_x + 0.1) & (v[:, 2] < 1.0))
    hs.set_trunk(float(v[(v[:, 2] > 1.0) & (v[:, 2] < 1.2)][:, 0].min()),
                 float(v[(v[:, 2] > 1.0) & (v[:, 2] < 1.2) & ~tail_mask][:, 0].max()))
    return tail_mask
