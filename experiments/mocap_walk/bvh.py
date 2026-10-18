#!/usr/bin/env python3
"""Reading a BVH file and posing its skeleton (forward kinematics): joint positions and world
rotations per frame. The BVH format as documented by Biovision / in M. Meredith and S. Maddock,
"Motion Capture File Formats Explained" (2001); written from that description.
"""
import numpy as np


class Joint:
    def __init__(self, name, parent):
        self.name, self.parent = name, parent
        self.offset = np.zeros(3)
        self.channels = []
        self.children = []
        self.end = None  # an End Site's offset, if any


def _rot(axis, deg):
    a = np.radians(deg)
    c, s = np.cos(a), np.sin(a)
    if axis == "X":
        return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])
    if axis == "Y":
        return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def load(path):
    """-> (joints in file order, frames array [n, channels], frame time)."""
    tok = open(path).read().split()
    i = 0
    joints, stack = [], []
    while tok[i] != "MOTION":
        t = tok[i]
        if t in ("ROOT", "JOINT"):
            j = Joint(tok[i + 1], stack[-1] if stack else None)
            if j.parent:
                j.parent.children.append(j)
            joints.append(j)
            stack.append(j)
            i += 2
        elif t == "End":
            # End Site { OFFSET x y z }
            stack[-1].end = np.array([float(x) for x in tok[i + 4:i + 7]])
            i += 8
        elif t == "OFFSET":
            stack[-1].offset = np.array([float(x) for x in tok[i + 1:i + 4]])
            i += 4
        elif t == "CHANNELS":
            n = int(tok[i + 1])
            stack[-1].channels = tok[i + 2:i + 2 + n]
            i += 2 + n
        elif t == "}":
            stack.pop()
            i += 1
        else:
            i += 1
    n = int(tok[i + 2])
    dt = float(tok[i + 5])
    count = sum(len(j.channels) for j in joints)
    data = np.array([float(x) for x in tok[i + 6:i + 6 + n * count]]).reshape(n, count)
    return joints, data, dt


def pose(joints, frame):
    """-> {name: (position, world rotation 3x3)} for one frame's channel values."""
    out = {}
    k = 0
    for j in joints:
        local_t = j.offset.copy()
        r = np.eye(3)
        for ch in j.channels:
            v = frame[k]
            k += 1
            if ch.endswith("position"):
                local_t["XYZ".index(ch[0])] = v
            else:
                r = r @ _rot(ch[0], v)
        if j.parent is None:
            out[j.name] = (local_t, r)
        else:
            pp, pr = out[j.parent.name]
            out[j.name] = (pp + pr @ local_t, pr @ r)
    return out


def end_position(j, posed):
    """Where a joint's End Site is (its bone's tip), for joints that have one."""
    p, r = posed[j.name]
    return p + r @ j.end
