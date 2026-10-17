"""His clothes out of his dressed twin (docs/briefs/layered-people.md): what of the dressed man
stands off his bare body, cut into garment pieces the fitter carries on him as they are
(tools/blender/fit_tripo.py `pieces`, a twin piece: not placed by landmarks nor rebuilt as a shell).

    ~/bpyenv/bin/python tools/characters/twin_pieces.py --body=bold_cowboy_body \\
        --dressed=bold_cowboy_dressed --out=bold_cowboy
    ~/bpyenv/bin/python tools/characters/twin_pieces.py --body=bold_cowboy_body \\
        --dressed=bold_cowboy_vest_dressed --out=bold_cowboy --split=layers

- His bare body and his dressed twin are both Rodin's whole man, the same man in the same A-pose
  (assets/people/tripo/test/<id>_rodin.glb). Both are turned into Tripo's frame as
  fit_tripo.load_rodin turns a Rodin man (facing +X, feet on 0, 1.0 tall, centred), and the twin
  is laid on the body by a trimmed ICP (scale, turn, shift: his face and hands, which match, carry
  it; the clothes standing off have no partner and drop out of each round).
- His clothes: the twin's surface below his chin (CHIN of his height) except where it lies on the
  bare body's skin (within SKIN_NEAR, in a skin colour): his hands and the open throat stay the
  body's. What of them lies inside his skin or nearer it than CLEAR is pushed out along the
  skin's normal to CLEAR, so his skin never shows through a sleeve.
- Cut into pieces: the coat (with what it shows at the front: vest, shirt, tie), and the
  trousers with the boots (below his belt, near black: told from the coat's brown by colour).
  `--split=layers` (his twin without a coat): shirt with its tie, vest, trousers with boots.
  `--without=<out>` (with the coated twin): the coat less what lies on that cut's shirt and vest
  in their colour (them, seen through its open front); `--only=coat` writes the coat alone.
→ assets/people/tripo/<out>_<piece>.glb (unrigged, the twin's texture inside, at TEX px) and
  <out>_<piece>.json (`twin`: the body it was laid on).
"""
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
TRIPO = os.path.join(ROOT, "assets", "people", "tripo")
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "tools", "blender"))
CHIN = 0.855       # of his height: nothing above (his face and hair are the head's)
BELT = 0.50        # of his height: below it his coat and his trousers are told apart by colour
BOOT_TOP = 0.12    # of his height: below it, boots (brown, with the trousers' piece)
TROUSER_CHROMA = 6.0
TIE_LOW = 0.66     # of his height: dark cloth above it is his tie (--split=layers), below his trousers
VEST_LOW = 0.48    # of his height: brown cloth below it is his boots' (--split=layers)
WITHOUT_NEAR = 0.006  # of his height (~11 mm): the coated twin this near his coatless twin's shirt or vest ...
WITHOUT_DE = 22.0     # ... and this near its colour (Lab) is them, seen through the coat's front
WOOL_DE = 16.0        # ... or this far from the coat's own wool colour (Lab)
ELBOW_BLEND = 0.25    # of his upper arm's length: upper and lower sleeve blended across his elbow (--split=layers)
SHOULDER_EASE = 0.35  # ... and the sleeve eased onto the bones from nothing at his shoulder over this much of it
COLLAR_TOP = 0.875    # of his height: his shirt's collar kept up to here (--split=layers)
HEM_BINS = 36         # angles round his waist the vest's hem is read at (--split=layers) ...
HEM_BAND = 0.03       # ... and how far either side of it (of his height) it decides vest or trousers
MIN_PART = 40         # triangles: a garment's piece smaller than this is a stray fragment
UNDERLAP = 0.008      # of his height (~1.5 cm): an inner garment runs on this far under an outer's edge
LAYER_NEAR = 0.006  # of his height (~1 cm): each triangle the commonest class within it
SKIN_NEAR = 0.006  # of his height (~1 cm): the twin's surface this near the bare skin, in a skin colour, is skin
THROAT = 0.80      # of his height: above it, the twin's surface on his skin in a skin colour is his skin
SKIN_DE = 18.0     # Lab distance from his skin tone that still counts as skin
CLEAR = 0.006      # of his height (~11 mm): clothes at least this far outside his skin
HAND_LEN = 0.12    # of his height: wrist to finger tips, and a little
ARM_DARK_L = 40.0  # Lab lightness: cut into layers, a twin point drawn darker is cloth over his trunk, not his sleeve
HAND_R = 0.03      # of his height: how far off the forearm's line his hand reaches
HAND_PAST = 0.006  # of his height (~1 cm) past his wrist along the forearm: his hand, not his cuff
TEX = 2048


def frame(pos):
    """fit_tripo.load_rodin's turn: Tripo's frame, feet on 0, 1.0 tall, centred."""
    v = np.stack([pos[:, 2], pos[:, 1], -pos[:, 0]], axis=1)
    y0, y1 = v[:, 1].min(), v[:, 1].max()
    v = (v - [0, y0, 0]) / (y1 - y0)
    return v - [(v[:, 0].min() + v[:, 0].max()) / 2, 0, (v[:, 2].min() + v[:, 2].max()) / 2]


def _lab(rgb):
    c = np.where(rgb > 0.04045, ((rgb + 0.055) / 1.055) ** 2.4, rgb / 12.92)
    xyz = c @ np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]]).T
    xyz /= [0.9505, 1.0, 1.089]
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[:, 1] - 16, 500 * (f[:, 0] - f[:, 1]), 200 * (f[:, 1] - f[:, 2])], 1)


def vertex_normals(v, t):
    fn = np.cross(v[t[:, 1]] - v[t[:, 0]], v[t[:, 2]] - v[t[:, 0]])
    n = np.zeros_like(v)
    for k in range(3):
        np.add.at(n, t[:, k], fn)
    return n / (np.linalg.norm(n, axis=1, keepdims=True) + 1e-12)


def bone_of(p, j):
    """Which of his bones each point is nearest (by its segment): trunk, a thigh or shin, an
    upper arm, or a forearm with its hand (the wrist's segment run on past the finger tips)."""
    segs = {"trunk": (j["Hip"], j["NeckTwist01"])}
    for lr in "RL":
        segs[lr + "_thigh"] = (j[lr + "_Thigh"], j[lr + "_Calf"])
        segs[lr + "_shin"] = (j[lr + "_Calf"], j[lr + "_Foot"])
        segs[lr + "_upper"] = (j[lr + "_Upperarm"], j[lr + "_Forearm"])
        a, b = j[lr + "_Forearm"], j[lr + "_Hand"]
        segs[lr + "_fore"] = (a, b + (b - a) * 1.5)
    names = list(segs)
    D = []
    for n in names:
        a, b = segs[n]
        t = np.clip((p - a) @ (b - a) / max((b - a) @ (b - a), 1e-12), 0, 1)
        D.append(np.linalg.norm(p - (a + t[:, None] * (b - a)), axis=1))
    return np.array(names)[np.argmin(np.array(D), 0)]


def _tri_adjacency(v, tris):
    """Each triangle's neighbours (sharing a corner's place: Rodin's triangles share no points)."""
    _u, weld = np.unique(np.round(v / 1e-6).astype(np.int64), axis=0, return_inverse=True)
    wt = weld.ravel()[tris]
    by_pt = {}
    for t, row in enumerate(wt):
        for q in row:
            by_pt.setdefault(int(q), []).append(t)
    adj = [set() for _ in range(len(tris))]
    for ts in by_pt.values():
        for t in ts:
            adj[t].update(ts)
    return [np.array(sorted(a - {i}), np.int64) for i, a in enumerate(adj)]


def _components(adj, ids):
    """Connected pieces of the triangles `ids` (lists of triangle ids)."""
    left = set(int(i) for i in ids)
    out = []
    while left:
        seed = left.pop()
        comp, stack = [seed], [seed]
        while stack:
            i = stack.pop()
            for j in adj[i]:
                j = int(j)
                if j in left:
                    left.remove(j)
                    comp.append(j)
                    stack.append(j)
        out.append(np.array(comp, np.int64))
    return out


def _turn_onto(u, v):
    """The least rotation taking direction u onto direction v (Rodrigues)."""
    u = u / np.linalg.norm(u)
    v = v / np.linalg.norm(v)
    c = float(u @ v)
    ax = np.cross(u, v)
    s_ = np.linalg.norm(ax)
    if s_ < 1e-9:
        return np.eye(3)
    k = ax / s_
    K = np.array([[0, -k[2], k[1]], [k[2], 0, -k[0]], [-k[1], k[0], 0]])
    return np.eye(3) + s_ * K + (1 - c) * K @ K


def write_piece(name, v, uv, t, colour, body, out):
    import bpy
    used = np.unique(t)
    remap = -np.ones(len(v), int)
    remap[used] = np.arange(len(used))
    vk, tk, uvk = v[used], remap[t], uv[used]
    # Stored in his Tripo frame: fit_tripo turns the piece's positions into body space as it turns
    # his body's after load_rodin. Blender's Z up: glTF (x, y, z) is (x, -z, y).
    g = vk
    bpy.ops.wm.read_factory_settings(use_empty=True)
    me = bpy.data.meshes.new(name)
    me.from_pydata([(p[0], -p[2], p[1]) for p in g], [], [tuple(int(i) for i in f) for f in tk])
    uvl = me.uv_layers.new(name="UVMap")
    corner = uvk[tk.ravel()]
    uvl.data.foreach_set("uv", np.c_[corner[:, 0], 1.0 - corner[:, 1]].astype(np.float32).ravel())
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    tex_path = os.path.join(ROOT, "build", "%s_%s_tex.png" % (out, name))
    os.makedirs(os.path.dirname(tex_path), exist_ok=True)
    colour.resize((TEX, TEX)).save(tex_path)
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    node = mat.node_tree.nodes.new("ShaderNodeTexImage")
    node.image = bpy.data.images.load(tex_path)
    mat.node_tree.links.new(node.outputs["Color"], bsdf.inputs["Base Color"])
    me.materials.append(mat)
    path = os.path.join(TRIPO, "%s_%s.glb" % (out, name))
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_texcoords=True, export_normals=True,
                              export_materials="EXPORT", export_image_format="AUTO")
    json.dump({"twin": body, "note": "cut from his dressed twin by tools/characters/twin_pieces.py; "
               "already in place on the body: fit_tripo carries it as it is"},
              open(os.path.join(TRIPO, "%s_%s.json" % (out, name)), "w"), indent=1)
    print("twin_pieces: %-8s %6d triangles → %s" % (name, len(tk), path))


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    body, dressed, out = a["--body"], a["--dressed"], a["--out"]
    import fit_tripo as FT
    import neck_ring as NR
    import rodin_portrait as RP
    from scipy.spatial import cKDTree
    bpos, _bn, buv, btris, _bj, bcol = FT.load_glb(os.path.join(TRIPO, "test", body + "_rodin.glb"))
    dpos, _dn, duv, dtris, _dj, dcol = FT.load_glb(os.path.join(TRIPO, "test", dressed + "_rodin.glb"))
    from PIL import Image
    # --painted: the garments written with the twin's texture painted from his pictures
    # (body_paint.py --dressed; Sean, 2026-10-17), cut as ever by Rodin's own colours.
    wcol = Image.open(os.path.join(TRIPO, dressed + "_color.png")).convert("RGB") if "--painted" in sys.argv else dcol
    bv, dv = frame(bpos), frame(dpos)
    # The twin onto the body: trimmed ICP, half the pairs (what matches: face, hands, skin).
    tree = cKDTree(bv)
    s, R, t = 1.0, np.eye(3), np.zeros(3)
    for _ in range(40):
        d, j = tree.query(s * dv @ R.T + t)
        keep = d < np.percentile(d, 50)
        s, R, t = NR.similarity(dv[keep], bv[j[keep]])
    dv = s * dv @ R.T + t
    # His arms hang a little differently in each (the twin's ~4 cm higher, nearer his sides): each
    # sleeve turned onto the body's arm by his hands, which match (a rigid ICP of the twin's hand
    # onto the body's), in full from the elbow down, fading to nothing at the shoulder.
    jb, jd = FT.find_joints(bv, btris), FT.find_joints(dv, dtris)
    bone_d = bone_of(dv, jd)
    # Cut into layers, only his sleeves move with his arms: the coatless twin's arms hang against
    # his waist, so the waistcoat's sides (and his trousers by his hands) were nearer an arm bone
    # than his trunk's, went out with the sleeves onto the body's arms and flared the waistcoat
    # from armpit to hem (Sean, 2026-10-16: "barrel chested"; ~560 of its points). What is drawn
    # dark (the waistcoat, trousers) is not arm.
    not_arm = np.zeros(len(dv), dtype=bool)
    if a.get("--split") == "layers":
        not_arm = _lab(RP.sample_tex(np.asarray(dcol).astype(float) / 255, duv))[:, 0] < ARM_DARK_L
        bone_d = np.where(not_arm & np.isin(bone_d, ["R_upper", "R_fore", "L_upper", "L_fore"]), "trunk", bone_d)
    for lr in "RL":
        sh, el, wr = jd[lr + "_Upperarm"], jd[lr + "_Forearm"], jd[lr + "_Hand"]
        ax = (wr - sh) / np.linalg.norm(wr - sh)
        along = (dv - sh) @ ax
        arm = np.isin(bone_d, [lr + "_upper", lr + "_fore"])
        bax = (jb[lr + "_Hand"] - jb[lr + "_Forearm"])
        bax /= np.linalg.norm(bax)
        bh = bv[((bv - jb[lr + "_Hand"]) @ bax > -0.01) & (np.sign(bv[:, 2]) == np.sign(sh[2]))
                & (np.linalg.norm(bv - jb[lr + "_Hand"], axis=1) < 0.08)]
        dh = dv[arm & (along > (wr - sh) @ ax - 0.01)]
        htree = cKDTree(bh)
        Rh, th = np.eye(3), np.zeros(3)
        for _ in range(30):
            hd, hj = htree.query(dh @ Rh.T + th)
            k = hd < np.percentile(hd, 80)
            _s, Rh, th = NR.similarity(dh[k], bh[hj[k]])
            th += (_s - 1.0) * (Rh @ dh[k].mean(0))      # rigid: the scale left out
        w = np.clip(along / max((el - sh) @ ax, 1e-6), 0, 1) * arm
        dv += w[:, None] * (dv @ Rh.T + th - dv)
        print("twin_pieces: %s sleeve turned %.1f deg, moved %.0f mm at the hand" % (
            lr, np.degrees(np.arccos(np.clip((np.trace(Rh) - 1) / 2, -1, 1))), 1850 * np.linalg.norm(dh.mean(0) @ Rh.T + th - dh.mean(0))))
    if a.get("--split") == "layers":
        # His sleeves laid on the body's arm bones, joint to joint (roadmap 1.3): turned by his
        # hands alone, the coatless twin's upper sleeves sat off his arms, and his arm came
        # through the inside of his shirt's sleeve however thin it was drawn. Each part of the
        # sleeve turned and moved from the twin's joints onto the body's (upper: shoulder to
        # elbow, about the shoulder; lower: elbow to wrist, about the elbow), blended across his
        # elbow and eased into his shoulder.
        jd = FT.find_joints(dv, dtris)
        bone_d = bone_of(dv, jd)
        bone_d = np.where(not_arm & np.isin(bone_d, ["R_upper", "R_fore", "L_upper", "L_fore"]), "trunk", bone_d)
        moved = dv.copy()
        for lr in "RL":
            shd, eld, wrd = jd[lr + "_Upperarm"], jd[lr + "_Forearm"], jd[lr + "_Hand"]
            shb, elb, wrb = jb[lr + "_Upperarm"], jb[lr + "_Forearm"], jb[lr + "_Hand"]
            R1, R2 = _turn_onto(eld - shd, elb - shb), _turn_onto(wrd - eld, wrb - elb)
            arm = np.isin(bone_d, [lr + "_upper", lr + "_fore"])
            up_ax = (eld - shd) / np.linalg.norm(eld - shd)
            t_up = (dv - shd) @ up_ax / np.linalg.norm(eld - shd)
            p_up = shb + (dv - shd) @ R1.T
            p_lo = elb + (dv - eld) @ R2.T
            # Upper or lower by where along the arm (blended over ELBOW_BLEND of the upper arm).
            w_lo = np.clip((t_up - 1.0) / ELBOW_BLEND + 0.5, 0, 1)
            target = p_up * (1 - w_lo)[:, None] + p_lo * w_lo[:, None]
            w_in = np.clip(t_up / SHOULDER_EASE, 0, 1)      # nothing at his shoulder, all of it beyond
            k = (arm * w_in)[:, None]
            moved = moved * (1 - k) + target * k
        print("twin_pieces: sleeves laid on the body's arm bones (shift up to %.0f mm)" % (1850 * np.abs(moved - dv).max()))
        dv = moved
    d, j = tree.query(dv)
    print("twin_pieces: twin laid on the body: scale %.3f, turn %.1f deg, median gap %.1f mm of a 1.85 m man"
          % (s, np.degrees(np.arccos(np.clip((np.trace(R) - 1) / 2, -1, 1))), np.median(d) * 1850))
    # Which side of his skin each twin point is on, and is it skin.
    bnorm = vertex_normals(bv, btris)
    side = ((dv - bv[j]) * bnorm[j]).sum(1)
    btone = RP.sample_tex(np.asarray(bcol).astype(float) / 255, buv)
    trunk = (bv[:, 1] > 0.55) & (bv[:, 1] < 0.75)
    skin_lab = np.median(_lab(btone[trunk]), 0)
    dtone = RP.sample_tex(np.asarray(dcol).astype(float) / 255, duv)
    skinlike = np.linalg.norm(_lab(dtone) - skin_lab, axis=1) < SKIN_DE
    # Bare skin on a dressed man is his hands (below) and his throat: only there (the coat's lit
    # brown is near enough his skin's colour to be cut out of a sleeve).
    skin = (np.abs(side) < SKIN_NEAR) & skinlike & (dv[:, 1] > THROAT)
    # His twin's hands are his body's hands' business (a colour or a pose apart, they'd double):
    # past each wrist (the body's joints, from his shape), along the forearm, nothing is cloth.
    hand = np.zeros(len(dv), bool)
    bone_b = bone_of(dv, jb)
    for lr in "RL":
        el, wr = jb[lr + "_Forearm"], jb[lr + "_Hand"]
        u = (wr - el) / np.linalg.norm(wr - el)
        along = (dv - wr) @ u
        off = np.linalg.norm((dv - wr) - along[:, None] * u, axis=1)
        # Past his wrist on the forearm's line, or within a hand's reach of it (hanging by his
        # thigh, his hand is nearer the thigh's bone than the forearm's); never his coat's body.
        hand |= ((bone_b == lr + "_fore") & (along > HAND_PAST)) | (
            (along > HAND_PAST) & (along < HAND_LEN) & (off < HAND_R) & (bone_b != "trunk"))
    cy = dv[dtris].mean(1)[:, 1]
    cloth = (cy < CHIN) & ~skin[dtris].any(1) & ~hand[dtris].any(1)
    # Out of his skin: each point's nearest point on his skin's surface (not his nearest vertex:
    # Rodin's triangles share none, and at a fold like the shorts' fly one face's normal points
    # anywhere), and the point set CLEAR outside it along that face's normal; twice, as a push can
    # bring it nearer another face.
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    bvh = BVHTree.FromPolygons([tuple(p) for p in bv], [tuple(int(i) for i in f) for f in btris])
    pts = np.unique(dtris[cloth])
    moved = np.zeros(len(dv), bool)
    for _ in range(2):
        for i in pts:
            loc, nrm, _f, _d = bvh.find_nearest(Vector(dv[i]))
            if loc is None:
                continue
            sd = (dv[i] - np.array(loc)) @ np.array(nrm)
            if sd < CLEAR:
                dv[i] = dv[i] + np.array(nrm) * (CLEAR - sd)
                moved[i] = True
    low = moved
    print("twin_pieces: %d of %d twin triangles are clothes; %.0f%% of their points pushed out of his skin"
          % (cloth.sum(), len(dtris), 100 * low[np.unique(dtris[cloth])].mean()))
    # Coat from trousers by colour below his belt (the coat's brown wool, chroma ~15-30; the
    # trousers near black, ~2), each triangle by the share of dark ones within 1.5 cm, so the
    # split follows the coat's own edges; his boots go with the trousers.
    tl = _lab(RP.sample_tex(np.asarray(dcol).astype(float) / 255, duv[dtris].mean(1)))
    dark = np.hypot(tl[:, 1], tl[:, 2]) < TROUSER_CHROMA
    cent = dv[dtris].mean(1)
    ctree = cKDTree(cent)
    share = np.array([dark[n].mean() for n in ctree.query_ball_point(cent, 0.008)])
    legs = cloth & (cy < BELT) & ((share > 0.5) | (cy < BOOT_TOP))
    if os.environ.get("TWIN_DEBUG"):
        np.savez(os.path.join(ROOT, "build", "twin_debug.npz"), dv=dv, dtris=dtris, cloth=cloth, skin=skin, hand=hand, cy=cy, legs=legs)
    if a.get("--split", "coat") == "layers":
        # His twin without a coat (roadmap 1.3): shirt (with its tie), vest, trousers (with
        # boots), each by its colour (from Sean's coatless bold cowboy: the shirt cream, L 55+,
        # chroma under 20; the vest brown, chroma 10-30, L under 40; the trousers and the tie
        # near black, chroma under 10, told apart by height; boots by height), then each
        # triangle the commonest class within LAYER_NEAR (a stray lit or shadowed patch, and
        # what's left of his hands' skin, go with what's round them).
        L, C = tl[:, 0], np.hypot(tl[:, 1], tl[:, 2])
        cls = np.full(len(dtris), -1)
        SHIRT, VEST, TROUSERS = 0, 1, 2
        cls[(L >= 40) & (C < 20)] = SHIRT
        cls[(L < 40) & (C >= 10)] = VEST
        cls[(L < 40) & (C < 10)] = TROUSERS
        cls[(cls == TROUSERS) & (cy > TIE_LOW)] = SHIRT        # his tie, at his throat
        cls[(cls == VEST) & (cy < VEST_LOW)] = TROUSERS        # brown below his waist: his boots
        cls[cy < BOOT_TOP] = TROUSERS
        for _ in range(2):
            near = ctree.query_ball_point(cent, LAYER_NEAR)
            votes = np.array([np.bincount(cls[n][(cls[n] >= 0) & cloth[n]], minlength=3) for n in near])
            cls = np.where(votes.sum(1) > 0, votes.argmax(1), cls)
        # His shirt's collar stands up past CHIN (the head's cut): kept, white cloth to COLLAR_TOP.
        collar = (cy >= CHIN) & (cy < COLLAR_TOP) & (L >= 55) & (C < 20) & (np.abs(cent[:, 2]) < 0.08)
        cloth = cloth | collar
        cls[collar] = SHIRT
        cls[~cloth] = -1
        # Stray fragments (a fold's shadow read as vest on his shirt, a lit patch on his vest)
        # folded into the garment round them: each connected piece of a garment smaller than
        # MIN_PART triangles takes the commonest garment it touches.
        adj = _tri_adjacency(dv, dtris)
        for _ in range(3):
            changed = 0
            for k in (SHIRT, VEST, TROUSERS):
                for comp in _components(adj, np.nonzero(cloth & (cls == k))[0]):
                    if len(comp) >= MIN_PART:
                        continue
                    nb = np.concatenate([adj[i] for i in comp])
                    nb = nb[(cls[nb] >= 0) & (cls[nb] != k)]
                    if len(nb):
                        cls[comp] = np.bincount(cls[nb], minlength=3).argmax()
                        changed += len(comp)
            if not changed:
                break
        # The vest's hem on a smooth curve round his waist (cut by colour, triangle by triangle,
        # it came out in sawteeth): at each of HEM_BINS angles round his middle, the height where
        # vest meets trousers (the median of the vest's triangles touching the trousers), eased
        # round him; within HEM_BAND of it, vest above, trousers below.
        cen_x, cen_z = float(np.median(cent[cloth, 0])), float(np.median(cent[cloth, 2]))
        ang = np.arctan2(cent[:, 2] - cen_z, cent[:, 0] - cen_x)
        edge = np.array([(cls[i] == VEST) and np.any(cls[adj[i]] == TROUSERS) for i in range(len(dtris))])
        bins = np.linspace(-np.pi, np.pi, HEM_BINS + 1)
        b_of = np.clip(np.searchsorted(bins, ang, side="right") - 1, 0, HEM_BINS - 1)
        hem = np.full(HEM_BINS, np.nan)
        for k in range(HEM_BINS):
            m = edge & (b_of == k) & (cy > VEST_LOW) & (cy < TIE_LOW)
            if m.sum() >= 3:
                hem[k] = np.median(cy[m])
        ok = np.isfinite(hem)
        if ok.sum() >= 4:
            mids = 0.5 * (bins[:-1] + bins[1:])
            xs = np.r_[mids[ok] - 2 * np.pi, mids[ok], mids[ok] + 2 * np.pi]
            hem = np.interp(mids, xs, np.tile(hem[ok], 3))
            for _ in range(2):
                hem = (np.roll(hem, 1) + 2 * hem + np.roll(hem, -1)) / 4
            h_at = np.interp(ang, np.r_[mids - 2 * np.pi, mids, mids + 2 * np.pi], np.tile(hem, 3))
            band = cloth & np.isin(cls, [VEST, TROUSERS]) & (np.abs(cy - h_at) < HEM_BAND)
            cls[band] = np.where(cy[band] > h_at[band], VEST, TROUSERS)
            print("twin_pieces: the vest's hem laid on a smooth line round his waist (%.3f to %.3f of his height)" % (hem.min(), hem.max()))
        # And what's still left alone (no garment round it) dropped.
        for k in (SHIRT, VEST, TROUSERS):
            for comp in _components(adj, np.nonzero(cloth & (cls == k))[0]):
                if len(comp) < MIN_PART:
                    cls[comp] = -1
        if os.environ.get("TWIN_DEBUG"):
            np.savez(os.path.join(ROOT, "build", "twin_layers.npz"), dv=dv, dtris=dtris, cloth=cloth, cls=cls, cy=cy)
        # Each garment runs on UNDERLAP under the edges of those over it (shirt < trousers < vest):
        # cut at one line, the vest's hem and the waistband stood apart in sawteeth with his skin
        # between; overlapped, the fitter tucks the inner under the outer and no gap can open.
        order = (SHIRT, TROUSERS, VEST)
        tree_c = cKDTree(cent)
        for n, k in enumerate(order):
            own = cloth & (cls == k)
            over = np.isin(cls, order[n + 1:]) & cloth
            near = np.zeros(len(dtris), bool)
            for hits in tree_c.query_ball_point(cent[own], UNDERLAP):
                near[hits] = True
            sel = own | (near & over)
            name = ("shirt", "vest", "trousers")[k]
            write_piece(name, dv, duv, dtris[sel], wcol, body, out)
        return
    coat = cloth & ~legs
    if a.get("--without"):
        # The coat alone (roadmap 1.3): what of it lies on his coatless twin's shirt, vest or
        # trousers (`--without=<out>` of a --split=layers cut, laid on the same body), in their
        # colour or not in the coat's, is them seen through its open front: dropped, so his own
        # vest and trousers show.
        under_v, under_c = [], []
        for name in ("shirt", "vest", "trousers"):
            upos, _un, uuv, utris, _uj, ucol = FT.load_glb(os.path.join(TRIPO, "%s_%s.glb" % (a["--without"], name)))
            # The pieces are stored in his Tripo frame already (glTF y-up as written).
            uc = upos[utris].mean(1)
            under_v.append(uc)
            under_c.append(_lab(RP.sample_tex(np.asarray(ucol).astype(float) / 255, uuv[utris].mean(1))))
        under_v, under_c = np.vstack(under_v), np.vstack(under_c)
        dist, k = cKDTree(under_v).query(cent)
        same = np.linalg.norm(tl - under_c[k], axis=1) < WITHOUT_DE
        # Or not the coat's own wool (its colour across his back, above his belt, where nothing
        # shows through): the two twins paint his vest in different browns.
        back = coat & (cent[:, 0] < np.median(cent[coat, 0])) & (cy > BELT) & (cy < CHIN - 0.1)
        wool = np.median(tl[back], 0)
        not_wool = np.linalg.norm(tl - wool, axis=1) > WOOL_DE
        # Only his front shows through (the coat is open there); its back lies on his vest's back
        # in much the same brown and is the coat.
        front = cent[:, 0] > np.median(cent[coat, 0])
        shown = coat & front & (dist < WITHOUT_NEAR) & (not_wool | (same & (np.linalg.norm(tl - under_c[k], axis=1) < WITHOUT_DE / 2)))
        # Each triangle as most of those within LAYER_NEAR (no speckle along the lapels).
        near = ctree.query_ball_point(cent, LAYER_NEAR)
        shown = coat & np.array([shown[n].mean() > 0.5 for n in near])
        print("twin_pieces: %d of %d coat triangles are his vest and shirt seen through it: dropped" % (shown.sum(), coat.sum()))
        coat = coat & ~shown
    for name, sel in (("coat", coat), ("trousers", legs)):
        if a.get("--only") and name not in a["--only"].split(","):
            continue
        write_piece(name, dv, duv, dtris[sel], wcol, body, out)


if __name__ == "__main__":
    main()
