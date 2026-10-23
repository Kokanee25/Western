#!/usr/bin/env python3
"""The bandana's mask moves with his mouth: his face's mouth shapes (talking_face.py's jaw_open,
aa, lips_apart, ee, oo, fv, mbp) copied onto `cloth_bandana_mask` (bandana.py) as its own morph
targets of the same names, so FaceSpeech, which sets every mesh that carries them, moves the cloth
over his chin with his jaw.

    python3 tools/faces/mask_jaw.py --man=hothead_lyle_s2_talking     (or --man=all)

→ assets/people/<man>.glb with the mask's morph targets (replaced), <man>.json `bandana.mask.follows`.

Each cloth vertex takes the offset of the skin under it (his outer skin only: the inside of his
mouth moves far more, and the cloth never touches it): the mean of its nearest face vertices'
offsets, weighted by a Gaussian on their distance (its width the nearest one's distance, so the
cloth takes from the folds round it). That holds where the cloth lies on him (within TOUCH: his
nose, cheeks, chin); between and below those it hangs, so it settles there as a stretched sheet
does (each vertex the mean of its neighbours, the touching ones held): from his nose to his chin
it stretches, and below his chin it hangs from it. The band and the knot, tied tight round his
head, stay put.

His mask hangs straight down from the tip of his nose (bandana.py), 2.5-3.5 cm clear of his lips
and chin, so his jaw drops inside it touching little but the sides of his jaw (a few mm of follow).
What shows of a masked man talking is the cloth breathing with his voice: each sound also pushes
the cloth over his mouth out by its breath (BREATH, PUFF), most on an open "ah", none on shut lips.
"""
import glob
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
from glb_io import Glb  # noqa: E402

PEOPLE = os.path.join(ROOT, "assets", "people")
SHAPES = ["jaw_open", "aa", "lips_apart", "ee", "oo", "fv", "mbp"]
NEAREST = 12          # face vertices each cloth vertex takes from
MIN_WIDTH = 0.008     # metres: the Gaussian's narrowest
SMOOTH = 4            # passes of smoothing over the cloth (it doesn't follow every fold of his lips)
TOUCH = 0.011         # metres: a cloth vertex this near his skin lies on it (bandana.py's GAP_MASK is 6 mm)
FILL = 400            # passes settling the hanging cloth between where it lies
# The breath of each sound pushing the cloth over his mouth out (metres at the shape's full
# weight): open and rounded sounds blow, the shut lips don't.
PUFF = 0.007
BREATH = {"jaw_open": 1.0, "aa": 0.85, "lips_apart": 0.35, "ee": 0.35, "oo": 0.7, "fv": 0.5, "mbp": 0.0}
PUFF_HIGH, PUFF_LOW = 0.02, 0.045   # metres: how far above and below his mouth the puff reaches
PUFF_DEG = 45.0       # and round from his front
FRONT_DEG = 70.0      # degrees round from his front past which the cloth is the band (no motion)
SHELL_DEG, SHELL_M = 3.0, 0.004   # the outer-skin grid (bandana.py's cylinder): angle and height steps
SHELL_TOL = 0.006     # metres inside the outermost surface still counted as his skin


def outer(V, axis):
    """Which of the head's vertices are his outer skin (not his mouth's inside, teeth, tongue):
    those within SHELL_TOL of the outermost surface seen from his head's axis."""
    ang = np.degrees(np.arctan2(V[:, 0] - axis[0], -(V[:, 2] - axis[1])))
    r = np.hypot(V[:, 0] - axis[0], V[:, 2] - axis[1])
    ia = np.floor((ang + 180) / SHELL_DEG).astype(int)
    iy = np.floor((V[:, 1] - V[:, 1].min()) / SHELL_M).astype(int)
    top = np.zeros((ia.max() + 3, iy.max() + 3))
    np.maximum.at(top, (ia + 1, iy + 1), r)
    spread = top.copy()   # each cell's most among its neighbours too (the grid's gaps)
    for da in (-1, 0, 1):
        for dy in (-1, 0, 1):
            spread = np.maximum(spread, np.roll(np.roll(top, da, 0), dy, 1))
    return r >= spread[ia + 1, iy + 1] - SHELL_TOL


def targets(g, name):
    """{target name: (N, 3) offsets} of the mesh `name`'s first primitive (sparse or dense)."""
    me = g.g["meshes"][g.mesh_index(name)]
    p = me["primitives"][0]
    names = me.get("extras", {}).get("targetNames", [])
    n = g.g["accessors"][p["attributes"]["POSITION"]]["count"]
    out = {}
    for k, t in enumerate(p.get("targets", [])):
        a = g.g["accessors"][t["POSITION"]]
        d = np.zeros((n, 3))
        if "bufferView" in a:
            d = g.accessor(t["POSITION"]).astype(float)
        if "sparse" in a:
            sp = a["sparse"]
            idx = _view(g, sp["indices"]["bufferView"], sp["indices"]["componentType"], sp["count"], 1).ravel()
            val = _view(g, sp["values"]["bufferView"], 5126, sp["count"], 3)
            d[idx.astype(int)] = val
        out[names[k] if k < len(names) else str(k)] = d
    return out


def _view(g, bv_i, comp, count, ncomp):
    bv = g.g["bufferViews"][bv_i]
    dt = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}[comp]
    return np.frombuffer(g.bin, dt, count=count * ncomp, offset=bv.get("byteOffset", 0)).reshape(count, ncomp)


def neighbours(T, n):
    """Each vertex's neighbours over the triangles (as index arrays)."""
    nb = [set() for _ in range(n)]
    for a, b, c in T:
        nb[a] |= {b, c}
        nb[b] |= {a, c}
        nb[c] |= {a, b}
    return [np.array(sorted(s), int) for s in nb]


def follow(man):
    path = os.path.join(PEOPLE, man + ".glb")
    g = Glb(path)
    head = g.mesh("body_head")
    try:
        mask = g.mesh("cloth_bandana_mask")
    except StopIteration:
        print("mask_jaw: %s has no mask" % man)
        return None
    face = targets(g, "body_head")
    if not all(s in face for s in SHAPES):
        print("mask_jaw: %s's head has no mouth shapes" % man)
        return None
    HV, MV = head["V"], mask["V"]
    # Where the mask's front is: round from his head's axis (bandana.py's), his front -Z.
    axis = np.array([(HV[:, 0].min() + HV[:, 0].max()) / 2, (HV[:, 2].min() + HV[:, 2].max()) / 2])
    skin = np.where(outer(HV, axis))[0]
    HV = HV[skin]
    face = {k: v[skin] for k, v in face.items()}
    ang = np.degrees(np.arctan2(MV[:, 0] - axis[0], -(MV[:, 2] - axis[1])))
    front = np.clip((FRONT_DEG - np.abs(ang)) / 20.0, 0, 1)
    # Each cloth vertex's nearest face vertices.
    d2 = ((MV[:, None, :] - HV[None, :, :]) ** 2).sum(2)
    near = np.argsort(d2, 1)[:, :NEAREST]
    dn = np.sqrt(np.take_along_axis(d2, near, 1))
    width = np.maximum(dn[:, :1] * 1.0, MIN_WIDTH)
    w = np.exp(-0.5 * (dn / width) ** 2)
    w /= w.sum(1, keepdims=True)
    nb = neighbours(mask["T"], len(MV))
    # Where the cloth lies on him (his nose, his chin, the band) it moves as his skin does; between
    # and below, it hangs: the rest settles as a stretched sheet between what it lies on.
    touching = (dn[:, 0] < TOUCH) | (front == 0)
    # The breath's puff: the cloth over his mouth (the height his lips part at), out along it.
    lips = np.linalg.norm(face["lips_apart"], axis=1)
    mouth_y = float(HV[lips > lips.max() * 0.5, 1].mean())
    dy = MV[:, 1] - mouth_y
    puff = np.exp(-0.5 * (dy / np.where(dy > 0, PUFF_HIGH, PUFF_LOW)) ** 2)
    puff *= np.clip((PUFF_DEG - np.abs(ang)) / PUFF_DEG, 0, 1) ** 1.5 * (~(dn[:, 0] < TOUCH))
    N = mask["N"] / np.maximum(np.linalg.norm(mask["N"], axis=1, keepdims=True), 1e-9)
    shapes = {}
    rep = {}
    for s in SHAPES:
        o = (w[:, :, None] * face[s][near]).sum(1) * front[:, None]
        fixed = o.copy()
        for _ in range(FILL):
            avg = np.array([o[x].mean(0) if len(x) else o[i] for i, x in enumerate(nb)])
            o = np.where(touching[:, None], fixed, avg)
        for _ in range(SMOOTH):
            o = 0.5 * o + 0.5 * np.array([o[x].mean(0) if len(x) else o[i] for i, x in enumerate(nb)])
        o *= front[:, None]
        o += puff[:, None] * N * PUFF * BREATH[s]
        shapes[s] = o
        rep[s] = round(float(np.linalg.norm(o, axis=1).max()) * 1000, 1)   # mm, its most
    g.set_mesh("cloth_bandana_mask", MV, mask["N"], mask["UV"], mask["J"], mask["W"], mask["T"], shapes=shapes)
    g.save(path)
    info_p = os.path.join(PEOPLE, man + ".json")
    info = json.load(open(info_p))
    info.setdefault("bandana", {}).setdefault("mask", {})["follows"] = {"shapes": SHAPES, "most_mm": rep}
    json.dump(info, open(info_p, "w"), indent=1)
    print("mask_jaw:", man, json.dumps(rep), "(face's jaw_open most %.1f mm)" % (np.linalg.norm(face["jaw_open"], axis=1).max() * 1000))
    return rep


if __name__ == "__main__":
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    men = [a["--man"]]
    if men == ["all"]:
        men = sorted(os.path.basename(p)[:-4] for p in glob.glob(os.path.join(PEOPLE, "*_talking.glb")))
    for m in men:
        follow(m)
