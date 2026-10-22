#!/usr/bin/env python3
"""A talking man's new face bound to his old head along the stitch (2026-10-22: FaceLife turns his
head, and a crack opened along his jaw, from under his ear to his chin).

The talking face (talking_face.py) stitches MakeHuman's face into his head with two vertices at
each point of the stitch: his kept head's, bound to his head and (low on the jaw) some of his neck,
and the new face's, bound to his head alone. Turned, his head's bone and his neck's pull them
apart. Here each stitch point's face vertex takes his kept head's weights, and the face's vertices
within FADE of the stitch fade from those to their own, so the face stretches with his neck there
rather than tearing from it. (No expression moves the stitch: the face's shapes fade out before it.)

    ~/.venvs/studio/bin/python tools/faces/neck_seam.py --man=sean_s3_talking [--check]

→ assets/people/<man>.glb in place, and what it did in <man>.json's facerig.stitch.
"""
import json
import os
import sys

import numpy as np
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
from glb_io import Glb  # noqa: E402

PEOPLE = os.path.join(ROOT, "assets", "people")
# Over this (summed absolute difference) two vertices at one point are bound differently.
DIFFERS = 0.02
# How far into the face the kept head's weights fade out (m).
FADE = 0.02
# Vertices nearer than this are one point (m).
SAME = 2e-4


def dense(J, W, n):
    """Each vertex's weights as a row over all n joints."""
    D = np.zeros((len(J), n))
    for j in range(J.shape[1]):
        np.add.at(D, (np.arange(len(J)), J[:, j].astype(int)), W[:, j])
    return D


def top4(D):
    """Rows of weights → the four strongest (joints, weights), renormalised."""
    J = np.argsort(-D, 1)[:, :4]
    W = np.take_along_axis(D, J, 1)
    W = W / np.maximum(W.sum(1, keepdims=True), 1e-9)
    return J, W


def points(V):
    """Each vertex's point: vertices within SAME of each other share one (a component label)."""
    label = np.arange(len(V))

    def root(i):
        while label[i] != i:
            label[i] = label[label[i]]
            i = label[i]
        return i
    for a, b in cKDTree(V).query_pairs(SAME):
        ra, rb = root(a), root(b)
        if ra != rb:
            label[max(ra, rb)] = min(ra, rb)
    return np.array([root(i) for i in range(len(V))])


def stitch_weights(H, D, head):
    """His head's weights with the stitch bound alike on both sides (J, W), and what it did."""
    pt = points(H["V"])
    stitch, target = [], []
    for p in np.unique(pt[np.bincount(pt, minlength=len(pt))[pt] > 1]):
        vs = np.nonzero(pt == p)[0]
        rows = D[vs]
        if np.abs(rows - rows[0]).sum(1).max() <= DIFFERS:
            continue
        # His kept head's vertex: the one least on his head bone (it carries his neck's share).
        kept = rows[np.argmin(rows[:, head])]
        stitch.extend(vs)
        target.extend([kept] * len(vs))
    if not stitch:
        return None, {"stitch_points": 0}
    stitch, target = np.array(stitch), np.array(target)
    before = float(np.abs(D[stitch] - target).sum(1).max())
    # The face's side near the stitch: vertices all on his head bone, within FADE of a stitch point.
    dist, near = cKDTree(H["V"][stitch]).query(H["V"])
    blend = np.clip(1.0 - dist / FADE, 0.0, 1.0)
    blend = blend * blend * (3 - 2 * blend)
    fade = np.nonzero((D[:, head] > 0.999) & (blend > 1e-3))[0]
    D2 = D.copy()
    D2[fade] = (1 - blend[fade, None]) * D[fade] + blend[fade, None] * target[near[fade]]
    D2[stitch] = target
    J, W = top4(D2)
    after = float(np.abs(dense(J, W, D.shape[1])[stitch] - target).sum(1).max())
    return (J, W), {"stitch_points": int(len(stitch)), "faded": int(len(fade)), "fade_m": FADE,
                    "worst_before": round(before, 2), "worst_after": round(after, 3)}


def bind(man, check=False):
    path = os.path.join(PEOPLE, man + ".glb")
    g = Glb(path)
    H = g.mesh("body_head")
    D = dense(H["J"], H["W"], len(g.joint_names()))
    jw, report = stitch_weights(H, D, g.joint_names().index("head"))
    print(f"{man}: {report}")
    if check:
        return report
    prim = g.g["meshes"][g.mesh_index("body_head")]["primitives"][0]
    if jw is not None:
        prim["attributes"]["JOINTS_0"] = g._add(jw[0].astype(np.uint16), 5123, "VEC4", 34962)
        prim["attributes"]["WEIGHTS_0"] = g._add(jw[1].astype(np.float32), 5126, "VEC4", 34962)
    g.compact()
    g.save(path)
    rp = os.path.join(PEOPLE, man + ".json")
    if os.path.exists(rp):
        rep = json.load(open(rp))
        old = rep.setdefault("facerig", {}).get("stitch", {})
        # A second run finds nothing left to do: keep what the first did.
        rep["facerig"]["stitch"] = report if report["stitch_points"] or not old else old
        json.dump(rep, open(rp, "w"), indent=1)
    return report


if __name__ == "__main__":
    args = dict(a[2:].split("=", 1) if "=" in a else (a[2:], True) for a in sys.argv[1:])
    bind(args["man"], bool(args.get("check")))
