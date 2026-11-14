"""Reading a glTF/GLB skeleton animation without Blender's bone conventions: the nodes' rest
(their default transforms, the bind pose in Mixamo-style exports) and the animation sampled at a
rate, each as joint name -> 4x4 world matrix in glTF's axes (metres once the root's scale is in; y
up, -z forward: Godot's). Written from the glTF 2.0 specification for this project; used by
tools/blender/retarget_motion.py (Blender's importer turns joints into bones whose frames point
along the bone, which hides the joints' own axes the retarget needs).
"""
import json
import math
import os
import struct

import numpy as np

COMPONENT = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2), 5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
COUNT = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


class Gltf:
    def __init__(self, path):
        with open(path, "rb") as f:
            data = f.read()
        self.dir = os.path.dirname(os.path.abspath(path))
        if data[:4] == b"glTF":
            length = struct.unpack_from("<I", data, 12)[0]
            self.doc = json.loads(data[20:20 + length].decode())
            off = 20 + length
            self.bins = []
            while off < len(data):
                ln, kind = struct.unpack_from("<II", data, off)
                if kind == 0x004E4942:
                    self.bins.append(data[off + 8:off + 8 + ln])
                off += 8 + ln
        else:
            self.doc = json.loads(data.decode())
            self.bins = []
        self.nodes = self.doc.get("nodes", [])
        self.parent = {}
        for i, n in enumerate(self.nodes):
            for c in n.get("children", []):
                self.parent[c] = i

    def buffer(self, i):
        b = self.doc["buffers"][i]
        if "uri" in b:
            with open(os.path.join(self.dir, b["uri"]), "rb") as f:
                return f.read()
        return self.bins[i]

    def accessor(self, i):
        a = self.doc["accessors"][i]
        bv = self.doc["bufferViews"][a["bufferView"]]
        buf = self.buffer(bv["buffer"])
        fmt, size = COMPONENT[a["componentType"]]
        n = COUNT[a["type"]]
        stride = bv.get("byteStride", size * n)
        start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        out = np.empty((a["count"], n), dtype=np.float64)
        for k in range(a["count"]):
            out[k] = struct.unpack_from("<" + fmt * n, buf, start + k * stride)
        if a.get("normalized"):
            out /= float(2 ** (8 * size - 1) - 1)
        return out if n > 1 else out[:, 0]

    @staticmethod
    def trs(t, r, s):
        x, y, z, w = r
        R = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                      [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                      [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
        m = np.eye(4)
        m[:3, :3] = R @ np.diag(s)
        m[:3, 3] = t
        return m

    def local(self, i, overrides=None):
        n = self.nodes[i]
        o = (overrides or {}).get(i, {})
        if "matrix" in n and not o:
            return np.array(n["matrix"], dtype=np.float64).reshape(4, 4).T
        t = o.get("translation", n.get("translation", [0.0, 0.0, 0.0]))
        r = o.get("rotation", n.get("rotation", [0.0, 0.0, 0.0, 1.0]))
        s = o.get("scale", n.get("scale", [1.0, 1.0, 1.0]))
        return self.trs(t, r, s)

    def world(self, overrides=None):
        """Every node's world matrix, by index, with `overrides` (node -> {path: value}) in place
        of the defaults."""
        out = {}

        def visit(i, parent_m):
            m = parent_m @ self.local(i, overrides)
            out[i] = m
            for c in self.nodes[i].get("children", []):
                visit(c, m)
        for root in self.doc["scenes"][self.doc.get("scene", 0)]["nodes"]:
            visit(root, np.eye(4))
        return out

    def names(self):
        return {i: n.get("name", "node%d" % i) for i, n in enumerate(self.nodes)}

    def rest(self):
        """Joint name -> rest world matrix (the nodes' defaults)."""
        names = self.names()
        return {names[i]: m for i, m in self.world().items()}

    def animation(self, index=0):
        """The animation's channels: node -> {path: (times, values, interpolation)}."""
        a = self.doc["animations"][index]
        ch = {}
        for c in a["channels"]:
            s = a["samplers"][c["sampler"]]
            node = c["target"]["node"]
            ch.setdefault(node, {})[c["target"]["path"]] = (self.accessor(s["input"]), self.accessor(s["output"]), s.get("interpolation", "LINEAR"))
        return ch

    def duration(self, index=0):
        d = 0.0
        for node, paths in self.animation(index).items():
            for times, _v, _i in paths.values():
                d = max(d, float(times[-1]))
        return d

    def sample(self, channels, t):
        """Each animated node's TRS at time t (seconds)."""
        o = {}
        for node, paths in channels.items():
            vals = {}
            for path, (times, values, interp) in paths.items():
                if path not in ("translation", "rotation", "scale"):
                    continue
                vals[path] = _interp(times, values, t, interp, path == "rotation")
            o[node] = vals
        return o

    def frames(self, fps=30.0, index=0):
        """The animation as frames at `fps`: a list of joint name -> world matrix."""
        channels = self.animation(index)
        names = self.names()
        n = max(2, int(round(self.duration(index) * fps)) + 1)
        out = []
        for k in range(n):
            w = self.world(self.sample(channels, k / fps))
            out.append({names[i]: m for i, m in w.items()})
        return out


def _interp(times, values, t, interp, is_rot):
    if t <= times[0]:
        return list(values[0])
    if t >= times[-1]:
        return list(values[-1])
    j = int(np.searchsorted(times, t, side="right")) - 1
    if interp == "STEP":
        return list(values[j])
    if interp == "CUBICSPLINE":
        # in-tangent, value, out-tangent triples: the value is enough at these rates.
        return list(values[j * 3 + 1])
    k = (t - times[j]) / max(times[j + 1] - times[j], 1e-9)
    a, b = values[j], values[j + 1]
    if is_rot:
        d = float(np.dot(a, b))
        if d < 0:
            b = -b
            d = -d
        if d > 0.9995:
            q = a + (b - a) * k
        else:
            th = math.acos(min(1.0, d))
            q = (math.sin((1 - k) * th) * a + math.sin(k * th) * b) / math.sin(th)
        return list(q / np.linalg.norm(q))
    return list(a + (b - a) * k)


def rotation_of(m):
    """The rotation of a 4x4 with scale in it (columns normalised)."""
    R = m[:3, :3].copy()
    for c in range(3):
        n = np.linalg.norm(R[:, c])
        if n > 1e-12:
            R[:, c] /= n
    return R
