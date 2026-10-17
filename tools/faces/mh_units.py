#!/usr/bin/env python3
"""MakeHuman's face pose units as vertex offsets on its base mesh (all CC0 data, our own code).

    ~/bpyenv/bin/python tools/faces/mh_units.py        # → build/faces/mh_units.npz

MakeHuman 1.2 poses a face with 59 "pose units" (data/poseunits/face-poseunits.bvh: frame 0 the
rest, then one unit a frame: JawDrop, LeftUpperLidClosed, MouthLeftPullUp, ...), each a rotation
of the face bones of its default skeleton (rigs/default.mhskel), and the base mesh follows the
bones by rigs/default_weights.mhw. Here each unit is posed by plain linear blend skinning and kept
as the offset of every base-mesh vertex (decimetres, MakeHuman's own space: Y up, facing +Z).

The BVH is Z up (its spine runs up +Z); MakeHuman's mesh is Y up: (x, y, z)_bvh → (x, z, -y).
Its joints carry no rest rotation, so a bone's skinning matrix is its posed transform times the
inverse of its rest one, both from the BVH alone. Fetch the files first:
    python3 tools/blender/fetch_makehuman.py; python3 tools/faces/mh_units.py --fetch
"""
import json
import os
import sys
import urllib.request

import numpy as np

MH = "build/makehuman/makehuman/data"
OUT = "build/faces/mh_units.npz"
COMMIT = "c28443c2af7e6b6e9367a3c6ee76f090c81796fd"   # tag v1.2.0, as fetch_makehuman.py
FILES = ["poseunits/face-poseunits.bvh", "poseunits/face-poseunits.json", "rigs/default_weights.mhw",
         "rigs/default.mhskel",
         "eyes/high-poly/high-poly.obj", "eyes/high-poly/high-poly.mhclo"]
C = np.array([[1, 0, 0], [0, 0, 1], [0, -1, 0]], float)   # BVH (Z up) → MakeHuman (Y up)


def fetch():
    base = "https://raw.githubusercontent.com/makehumancommunity/makehuman/%s/makehuman/data/" % COMMIT
    for f in FILES:
        out = os.path.join(MH, f)
        if os.path.exists(out):
            continue
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with urllib.request.urlopen(base + f, timeout=120) as r, open(out, "wb") as w:
            w.write(r.read())
        print("fetched", f)


def load_obj(path):
    """Vertices, UVs and faces (vertex ids, uv ids) per group."""
    verts, uvs, groups, cur = [], [], {}, None
    for line in open(path):
        if line.startswith("v "):
            verts.append([float(x) for x in line.split()[1:4]])
        elif line.startswith("vt "):
            uvs.append([float(x) for x in line.split()[1:3]])
        elif line.startswith("g "):
            cur = line.split()[1]
        elif line.startswith("f ") and cur:
            vi, ti = [], []
            for p in line.split()[1:]:
                b = p.split("/")
                vi.append(int(b[0]) - 1)
                ti.append(int(b[1]) - 1 if len(b) > 1 and b[1] else -1)
            groups.setdefault(cur, []).append((vi, ti))
    return np.array(verts), np.array(uvs), groups


def parse_bvh(path):
    """Joints [(name, parent index, offset, channels)] and the frames (F, channels)."""
    joints, stack, frames = [], [], []
    lines = iter(open(path).read().split("\n"))
    for line in lines:
        t = line.split()
        if not t:
            continue
        if t[0] in ("ROOT", "JOINT"):
            joints.append([t[1], stack[-1] if stack else -1, None, []])
            pending = len(joints) - 1
        elif t[0] == "End":
            joints.append([None, stack[-1], None, []])
            pending = len(joints) - 1
        elif t[0] == "{":
            stack.append(pending)
        elif t[0] == "}":
            stack.pop()
        elif t[0] == "OFFSET":
            joints[stack[-1]][2] = np.array([float(x) for x in t[1:4]])
        elif t[0] == "CHANNELS":
            joints[stack[-1]][3] = t[2:]
        elif t[0] == "MOTION":
            next(lines); next(lines)
            for fl in lines:
                if fl.strip():
                    frames.append([float(x) for x in fl.split()])
            break
    return joints, np.array(frames)


def rot(axis, deg):
    a = np.radians(deg); c, s = np.cos(a), np.sin(a)
    return {"X": np.array([[1, 0, 0], [0, c, -s], [0, s, c]]),
            "Y": np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]]),
            "Z": np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])}[axis]


def globals_at(joints, frame, heads=None):
    """Each joint's global 4x4 (BVH space) for one frame. `heads` (BVH space, per joint) replaces
    the BVH's own offsets: its skeleton was saved from a slightly different body (its jaw sits
    0.3 dm off the base mesh's), so the bones turn about the base mesh's own joints instead."""
    G, k = [], 0
    for j, (name, parent, off, ch) in enumerate(joints):
        L = np.eye(4); L[:3, 3] = off
        if heads is not None and heads[j] is not None:
            L[:3, 3] = heads[j] - (heads[parent] if parent >= 0 and heads[parent] is not None else 0)
        R = np.eye(3)
        for c in ch:
            v = frame[k]; k += 1
            if not c.endswith("position"):    # the root's translation: 0 in every frame
                R = R @ rot(c[0], v)
        L[:3, :3] = R
        G.append((G[parent] if parent >= 0 else np.eye(4)) @ L)
    return G


def units():
    v, _, groups = load_obj(os.path.join(MH, "3dobjs/base.obj"))
    joints, frames = parse_bvh(os.path.join(MH, "poseunits/face-poseunits.bvh"))
    names = json.load(open(os.path.join(MH, "poseunits/face-poseunits.json")))["framemapping"]
    weights = json.load(open(os.path.join(MH, "rigs/default_weights.mhw")))["weights"]
    index = {j[0]: i for i, j in enumerate(joints) if j[0]}
    skel = json.load(open(os.path.join(MH, "rigs/default.mhskel")))
    heads = []
    for name, *_ in joints:
        bone = skel["bones"].get(name) if name else None
        ids = skel["joints"].get(bone["head"]) if bone else None
        heads.append(C.T @ v[ids].mean(0) if ids else None)
    rest = globals_at(joints, frames[0], heads)
    print("jaw joint (MakeHuman space):", (C @ rest[index["jaw"]][:3, 3]).round(3))
    Cm = np.eye(4); Cm[:3, :3] = C
    out = {}
    tot = np.zeros(len(v))
    for b, pairs in weights.items():
        for i, w in pairs:
            tot[i] += w
    for f, name in enumerate(names):
        if f == 0:
            continue
        G = globals_at(joints, frames[f], heads)
        acc = np.zeros_like(v)
        for b, pairs in weights.items():
            if b not in index or not pairs:
                continue
            S = Cm @ G[index[b]] @ np.linalg.inv(rest[index[b]]) @ Cm.T
            if np.allclose(S, np.eye(4), atol=1e-7):
                continue
            ids = np.array([p[0] for p in pairs], int); w = np.array([p[1] for p in pairs])
            moved = v[ids] @ S[:3, :3].T + S[:3, 3]
            acc[ids] += (w / np.maximum(tot[ids], 1e-9))[:, None] * (moved - v[ids])
        out[name] = acc.astype(np.float32)
        print("%-22s moves %5d vertices, max %.3f dm" % (name, int((np.linalg.norm(acc, axis=1) > 1e-4).sum()),
                                                         float(np.linalg.norm(acc, axis=1).max())))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    np.savez_compressed(OUT, names=np.array(names[1:]), base=v.astype(np.float32),
                        **{"u_" + k: d for k, d in out.items()})
    print("wrote", OUT)


if __name__ == "__main__":
    if "--fetch" in sys.argv:
        fetch()
    units()
