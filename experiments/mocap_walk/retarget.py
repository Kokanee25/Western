#!/usr/bin/env python3
"""A CMU walk or run onto our rig: one cycle of each segment's local rotation (a quaternion
[x, y, z, w] for its pivot, from its parent's), sampled evenly over the stride from a left heel
strike, plus the stride's length at our leg length. Quaternions, not Euler angles: a knee or elbow
read as Euler flips between frames (-88/163/-163) and blends through a spin.

  python3 experiments/mocap_walk/retarget.py CLIP.bvh --gait=walk --out=experiments/mocap_walk/clips/walk.json

The data: the CMU Graphics Lab Motion Capture Database (mocap.cs.cmu.edu; "free for use in research
and commercial projects worldwide"), in B. Hahne's 2010 BVH conversion (fetch.sh). The method:
each of our segments turns from its rest by what the mocap bone turned from the capture's T pose
(frame one of these files), after a fixed turn that takes the T pose's bone onto our rest (the arms,
out in the T pose, hang at our rest). Written for this project.
"""
import json, math, os, sys
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bvh

HERE = os.path.dirname(os.path.abspath(__file__))
# Our segment <- the BVH joint whose rotation carries that bone, and the joint (or "end") its tip is.
MAP = {
    # (CMU's Spine1, Neck, LeftFingerBase... sit on their parents' points: bones of no length.)
    "pelvis": ("Hips", None), "abdomen": ("LowerBack", "Spine"), "chest": ("Spine", "Spine1"),
    "neck": ("Neck", "Neck1"), "head": ("Neck1", "Head"),
    "thigh_l": ("LeftUpLeg", "LeftLeg"), "shin_l": ("LeftLeg", "LeftFoot"), "foot_l": ("LeftFoot", "LeftToeBase"),
    "thigh_r": ("RightUpLeg", "RightLeg"), "shin_r": ("RightLeg", "RightFoot"), "foot_r": ("RightFoot", "RightToeBase"),
    "upper_arm_l": ("LeftArm", "LeftForeArm"), "forearm_l": ("LeftForeArm", "LeftHand"), "hand_l": ("LeftHand", "LeftHandIndex1"),
    "upper_arm_r": ("RightArm", "RightForeArm"), "forearm_r": ("RightForeArm", "RightHand"), "hand_r": ("RightHand", "RightHandIndex1"),
}
C = np.diag([-1.0, 1.0, -1.0])  # the capture faces +z with his right at -x; ours faces -z, right +x


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def arc(u, v):
    """The shortest rotation taking direction u onto v."""
    u, v = u / np.linalg.norm(u), v / np.linalg.norm(v)
    axis = np.cross(u, v)
    s, c = np.linalg.norm(axis), float(np.dot(u, v))
    if s < 1e-8:
        return np.eye(3)
    k = axis / s
    K = np.array([[0, -k[2], k[1]], [k[2], 0, -k[0]], [-k[1], k[0], 0]])
    a = math.atan2(s, c)
    return np.eye(3) + math.sin(a) * K + (1 - math.cos(a)) * K @ K


def yaw(theta):
    c, s = math.cos(theta), math.sin(theta)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def quat(R):
    """A rotation matrix as a quaternion [x, y, z, w] (Godot's order), w >= 0."""
    t = R[0, 0] + R[1, 1] + R[2, 2]
    if t > 0:
        s = math.sqrt(t + 1.0) * 2
        q = [(R[2, 1] - R[1, 2]) / s, (R[0, 2] - R[2, 0]) / s, (R[1, 0] - R[0, 1]) / s, 0.25 * s]
    elif R[0, 0] > R[1, 1] and R[0, 0] > R[2, 2]:
        s = math.sqrt(1.0 + R[0, 0] - R[1, 1] - R[2, 2]) * 2
        q = [0.25 * s, (R[0, 1] + R[1, 0]) / s, (R[0, 2] + R[2, 0]) / s, (R[2, 1] - R[1, 2]) / s]
    elif R[1, 1] > R[2, 2]:
        s = math.sqrt(1.0 + R[1, 1] - R[0, 0] - R[2, 2]) * 2
        q = [(R[0, 1] + R[1, 0]) / s, 0.25 * s, (R[1, 2] + R[2, 1]) / s, (R[0, 2] - R[2, 0]) / s]
    else:
        s = math.sqrt(1.0 + R[2, 2] - R[0, 0] - R[1, 1]) * 2
        q = [(R[0, 2] + R[2, 0]) / s, (R[1, 2] + R[2, 1]) / s, 0.25 * s, (R[1, 0] - R[0, 1]) / s]
    if q[3] < 0:
        q = [-c for c in q]
    return [round(c, 5) for c in q]


def euler_yxz(R):
    """Godot's Basis.get_euler(YXZ): R = Ry(y) Rx(x) Rz(z), degrees as Vector3(x, y, z)."""
    x = math.asin(max(-1.0, min(1.0, -R[1, 2])))
    y = math.atan2(R[0, 2], R[2, 2])
    z = math.atan2(R[1, 0], R[1, 1])
    return [math.degrees(x), math.degrees(y), math.degrees(z)]


def main():
    path = sys.argv[1]
    gait = opt("gait", "walk")
    samples = int(opt("samples", "40"))
    rig = json.load(open(os.path.join(HERE, "rig_rest.json")))
    joints, data, dt = bvh.load(path)
    by = {j.name: j for j in joints}
    T = bvh.pose(joints, data[0])
    frames = [bvh.pose(joints, f) for f in data[1:]]

    def tip(posed, seg):
        j, t = MAP[seg]
        if t == "end":
            return bvh.end_position(by[j], posed)
        return posed[t][0]

    # Fixed turns: the T pose's bone (in our axes) onto our rest bone.
    q_off = {}
    for seg, (j, t) in MAP.items():
        if t is None:
            q_off[seg] = np.eye(3)
            continue
        t_dir = C @ (tip(T, seg) - T[j][0])
        r = rig[seg]
        ours = np.array(r["b"]) - np.array(r["a"])
        q_off[seg] = arc(t_dir, ours)
    # His heading: the way the hips went over the clip, turned to face -z.
    h0, h1 = C @ frames[0]["Hips"][0], C @ frames[-1]["Hips"][0]
    d = h1 - h0
    H = yaw(math.atan2(d[0], -d[2]))  # takes (d.x, d.z) to (0, -1)
    hd = H @ d
    assert hd[2] < 0 and abs(hd[0]) < 1e-6 * np.linalg.norm(d) + 1e-6, hd
    order = list(rig.keys())

    def globals_at(posed):
        g = {}
        for seg, (j, _t) in MAP.items():
            g[seg] = H @ C @ posed[j][1] @ T[j][1].T @ C @ q_off[seg].T
        return g

    # One stride: between two strikes of the left foot, when it's furthest out in front of his
    # hips (a heel strike), a third of a second apart walking (a fifth running).
    hips = np.array([H @ C @ p["Hips"][0] for p in frames])
    lf = np.array([H @ C @ p["LeftFoot"][0] for p in frames])
    ahead = -(lf - hips)[:, 2]
    ahead = np.convolve(ahead, np.ones(9) / 9, mode="same")
    gap = int((0.33 if gait == "walk" else 0.2) / dt)
    starts = [i for i in range(gap, len(ahead) - gap)
              if ahead[i] == ahead[i - gap:i + gap + 1].max() and ahead[i] > np.percentile(ahead, 70)]
    if len(starts) < 2:
        sys.exit("retarget: fewer than two left-foot strikes in %s" % path)
    a, b = starts[0], starts[1]
    stride_units = float(np.linalg.norm((hips[b] - hips[a])[[0, 2]]))
    leg_units = float(np.linalg.norm(T["LeftUpLeg"][0] - T["LeftLeg"][0]) + np.linalg.norm(T["LeftLeg"][0] - T["LeftFoot"][0]))
    leg_ours = float(np.linalg.norm(np.array(rig["thigh_l"]["a"]) - np.array(rig["thigh_l"]["b"]))
                     + np.linalg.norm(np.array(rig["shin_l"]["a"]) - np.array(rig["shin_l"]["b"])))
    stride_m = stride_units / leg_units * leg_ours
    cycle_s = (b - a) * dt
    out_frames = []
    for k in range(samples):
        f = a + (b - a) * k / samples
        i0 = int(math.floor(f))
        g = globals_at(frames[i0])  # nearest-below frame (120 fps: fine at 40 samples a stride)
        local = {}
        for seg in order:
            parent = rig[seg]["parent"]
            gp = g[parent] if parent else np.eye(3)
            local[seg] = quat(gp.T @ g[seg])
        out_frames.append(local)
    # His hip joints' height through the stride above the ground (his lowest ankle in the clip), in leg
    # lengths: what the rig rides at on the clip (a run leaves the ground; the capture's T pose
    # isn't placed at his standing height, so it's no use as a reference).
    ankles = np.array([[(C @ p["LeftFoot"][0])[1], (C @ p["RightFoot"][0])[1]] for p in frames])
    ground = float(ankles[a:b].min())
    hipj = np.array([(C @ (p["LeftUpLeg"][0] + p["RightUpLeg"][0]) / 2)[1] for p in frames])
    hip_h = [float(hipj[int(a + (b - a) * k / samples)] - ground) / leg_units for k in range(samples)]
    res = {
        "gait": gait, "source": os.path.basename(path),
        "credit": "CMU Graphics Lab Motion Capture Database, mocap.cs.cmu.edu (BVH conversion by B. Hahne)",
        "stride_m": round(stride_m, 3), "cycle_s": round(cycle_s, 3), "speed_mps": round(stride_m / cycle_s, 3),
        "frames": out_frames, "hip_height": [round(h, 4) for h in hip_h],
    }
    out = opt("out", os.path.join(HERE, "clips", gait + ".json"))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump(res, open(out, "w"), separators=(",", ":"))
    print("%s: %s stride %.2f m in %.2f s (%.2f m/s at our size), strikes at %d and %d of %d" % (
        out, os.path.basename(path), stride_m, cycle_s, stride_m / cycle_s, a, b, len(frames)))


if __name__ == "__main__":
    main()
