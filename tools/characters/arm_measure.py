"""How a man's upper arm keeps its thickness with his hands up (issue #388).

Reads tools/characters/arm_dump.gd's DIR/<id>/ and skins his pieces on the CPU, as the GPU does
(linear blend: each vertex the weighted sum of its bones' moves). Then, in slabs across his raised
upper arm at SHARES of shoulder-to-elbow, its width seen from in front and from the side, each over
his arm's own width at rest below the armpit (`widths`). The doctor before the shoulder helpers
(PeopleBodies.shoulder_share): 0.63 of it a fifth of the way down, 0.76 at 0.3, whole from 0.5.
Near the shoulder (shares 0.1-0.2) a slab can take in a lifted shoulder, a collar or hair: there,
on a man with bulky clothes, judge by the pictures (tools/characters/arm_poses.gd), not the number.

    python3 tools/characters/arm_measure.py DIR/<id> [--pose=hands_up] [--json=OUT]
"""
import json
import sys
from pathlib import Path

import numpy as np

SHARES = (0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)
SLAB_M = 0.012
ANATOMY = Path(__file__).resolve().parents[2] / "config" / "anatomy.json"


def load(d):
    d = Path(d)
    meta = json.loads((d / "meta.json").read_text())
    pieces = {}
    for key, p in meta["pieces"].items():
        f = d / p["file"]
        n, per = p["n"], p["per"]
        pc = {"V": np.fromfile(f.with_suffix(".v"), np.float32).reshape(n, 3).astype(float),
              "B": np.fromfile(f.with_suffix(".b"), np.int32).reshape(n, per),
              "W": np.fromfile(f.with_suffix(".w"), np.float32).reshape(n, per).astype(float),
              "I": np.fromfile(f.with_suffix(".i"), np.int32).reshape(-1, 3),
              "binds": p["binds"], "M": {}}
        for pose in meta["poses"]:
            pc["M"][pose] = np.fromfile(d / (p["file"] + "." + pose + ".m"), np.float32).reshape(-1, 3, 4).astype(float)
        pieces[key] = pc
    return meta, pieces


def skin(V, B, W, M):
    """Linear blend skinning: V (n,3), B/W (n,k) bind indices and weights, M (binds,3,4)."""
    Vh = np.concatenate([V, np.ones((len(V), 1))], 1)
    out = np.zeros_like(V)
    tot = np.zeros(len(V))
    for k in range(B.shape[1]):
        w = W[:, k]
        out += w[:, None] * np.einsum("nij,nj->ni", M[B[:, k]], Vh)
        tot += w
    return out / np.maximum(tot, 1e-9)[:, None]


def whole(meta, pieces, shape="skin"):
    """Every piece of one shape as one set of vertices with weights by bone name (n, bones)."""
    names = sorted({b for p in pieces.values() for b in p["binds"]})
    col = {b: i for i, b in enumerate(names)}
    Vs, Ws, P = [], [], {pose: [] for pose in meta["poses"]}
    for key, p in pieces.items():
        if not key.startswith(shape + "/"):
            continue
        Wn = np.zeros((len(p["V"]), len(names)))
        for k in range(p["B"].shape[1]):
            np.add.at(Wn, (np.arange(len(p["V"])), [col[p["binds"][b]] for b in p["B"][:, k]]), p["W"][:, k])
        Vs.append(p["V"])
        Ws.append(Wn)
        for pose in meta["poses"]:
            P[pose].append(skin(p["V"], p["B"], p["W"], p["M"][pose]))
    return names, np.vstack(Vs), np.vstack(Ws), {k: np.vstack(v) for k, v in P.items()}


def frame(a, b):
    """The arm's line from a to b, and two directions across it: 'across' (seen from in front: the
    one in his frontal plane) and 'depth' (front to back)."""
    ax = (b - a) / np.linalg.norm(b - a)
    z = np.array([0, 0, 1.0])
    depth = z - ax * (z @ ax)
    depth /= np.linalg.norm(depth)
    across = np.cross(ax, depth)
    return ax, across, depth


def moves(pieces):
    """Each bone's move in each pose, by name (the same in every piece)."""
    out = {}
    for p in pieces.values():
        for pose, M in p["M"].items():
            for k, b in enumerate(p["binds"]):
                out.setdefault(pose, {})[b] = M[k]
    return out


def joint_line(mv, pose, seg):
    """A segment's two ends (joint to joint) where its bone has them in this pose."""
    cap = json.loads(ANATOMY.read_text())["segments"][seg]["capsules"][0]
    M = mv[pose][seg]
    return [M[:, :3] @ np.array(cap[k], float) + M[:, 3] for k in (0, 1)]


def arm_line(V, W, names, mv, side, rest, pose):
    """His arm's own line at rest (V: his vertices in the rest pose; the mesh's arm needn't lie on
    the anatomy's): the anatomy's direction through the middle of his upper arm's own vertices
    (weighted 0.9+ to it); from the anatomy's shoulder (projected onto it) to its elbow. Posed, the
    same line moved by the bone."""
    a, b = joint_line(mv, rest, "upper_arm_" + side)
    pure = W[:, names.index("upper_arm_" + side)] >= 0.9
    X = V[pure]
    c = X.mean(0)
    ax = (b - a) / np.linalg.norm(b - a)   # the anatomy's direction (his pure arm is a short band)
    a0 = c + ax * ((a - c) @ ax)
    b0 = c + ax * ((b - c) @ ax)
    M0, M1 = mv[rest]["upper_arm_" + side], mv[pose]["upper_arm_" + side]
    back = np.linalg.inv(np.vstack([M0, [0, 0, 0, 1]]))
    to = np.vstack([M1, [0, 0, 0, 1]]) @ back
    a1 = to[:3, :3] @ a0 + to[:3, 3]
    b1 = to[:3, :3] @ b0 + to[:3, 3]
    return a0, b0, a1, b1, X


def widths(V, W, names, P, mv, side="r", pose="hands_up", rest="stand"):
    """What a viewer sees: his raised upper arm's width from in front (across it, in his frontal
    plane) and from the side (front to back), in slabs across it at SHARES of shoulder-to-elbow,
    every posed vertex within R of its line; each over his arm's own width at rest, measured on his
    pure arm (weighted 0.9+ to the upper arm) below the armpit, where nothing else is near."""
    a0, b0, a1, b1, _X = arm_line(P[rest], W, names, mv, side, rest, pose)
    L = np.linalg.norm(b0 - a0)
    ax0, ac0, de0 = frame(a0, b0)
    ax1, ac1, de1 = frame(a1, b1)
    pure = W[:, names.index("upper_arm_" + side)] >= 0.9
    Xr = P[rest][pure] - a0
    tx = Xr @ ax0 / L
    rx = np.linalg.norm(Xr - np.outer(Xr @ ax0, ax0), axis=1)
    R = float(np.percentile(rx[(tx > 0.55) & (tx < 0.95)], 95)) * 1.25
    ref_ac, ref_de = [], []
    for s in (0.6, 0.7, 0.8, 0.9):
        k = np.abs(tx - s) * L < SLAB_M
        if k.sum() >= 8:
            ref_ac.append(np.ptp(Xr[k] @ ac0))
            ref_de.append(np.ptp(Xr[k] @ de0))
    ref_ac, ref_de = float(np.median(ref_ac)), float(np.median(ref_de))
    Q = P[pose] - a1
    t = Q @ ax1
    r = np.linalg.norm(Q - np.outer(t, ax1), axis=1)
    out = {"ref_across_cm": round(ref_ac * 100, 1), "ref_depth_cm": round(ref_de * 100, 1), "rings": []}
    for s in SHARES:
        k = (np.abs(t - s * L) < SLAB_M) & (r < R)
        if k.sum() < 8:
            out["rings"].append({"share": s, "n": int(k.sum())})
            continue
        ac, de = float(np.ptp(Q[k] @ ac1)), float(np.ptp(Q[k] @ de1))
        out["rings"].append({"share": s, "n": int(k.sum()), "across_cm": round(ac * 100, 1),
                             "depth_cm": round(de * 100, 1), "across_kept": round(ac / ref_ac, 2),
                             "depth_kept": round(de / ref_de, 2)})
    return out


def summary(res):
    """One line a side: across_kept/depth_kept at each share."""
    return {side: " ".join("%.2f:%s/%s" % (r["share"], r.get("across_kept"), r.get("depth_kept"))
                           for r in w["rings"]) for side, w in res.items()}


if __name__ == "__main__":
    d = sys.argv[1]
    pose = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--pose=")), "hands_up")
    meta, pieces = load(d)
    names, V, W, P = whole(meta, pieces)
    mv = moves(pieces)
    res = {side: widths(V, W, names, P, mv, side, pose) for side in ("r", "l")}
    print(meta["id"])
    for side, line in summary(res).items():
        print(side, "ref %.1f x %.1f cm" % (res[side]["ref_across_cm"], res[side]["ref_depth_cm"]), line)
    js = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--json=")), None)
    if js:
        Path(js).write_text(json.dumps(res, indent=1))
