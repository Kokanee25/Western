"""Read a .glb's meshes as numpy arrays, and write one back with meshes replaced or added.

Plain glTF 2.0 binary; enough for the people models (tools/blender/fit_tripo.py writes them).
"""
import json
import struct

import numpy as np

_CT = {5126: np.float32, 5123: np.uint16, 5125: np.uint32, 5121: np.uint8}
_NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


class Glb:
    def __init__(self, path):
        f = open(path, "rb").read()
        n = struct.unpack("<I", f[12:16])[0]
        self.g = json.loads(f[20:20 + n])
        m = 20 + n
        bn = struct.unpack("<I", f[m:m + 4])[0]
        self.bin = bytearray(f[m + 8:m + 8 + bn])

    def accessor(self, i):
        a = self.g["accessors"][i]
        bv = self.g["bufferViews"][a["bufferView"]]
        off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        n = _NC[a["type"]]
        dt = np.dtype(_CT[a["componentType"]])
        stride = bv.get("byteStride", 0)
        if stride and stride != dt.itemsize * n:
            raw = np.frombuffer(self.bin, np.uint8, count=stride * a["count"], offset=off)
            return raw.reshape(a["count"], stride)[:, :dt.itemsize * n].copy().view(dt).reshape(a["count"], n)
        return np.frombuffer(self.bin, dt, count=a["count"] * n, offset=off).reshape(a["count"], n).copy()

    def mesh(self, name):
        """{V, N, UV, J, W, T} of the mesh's first primitive (J are skin joint numbers)."""
        me = self.g["meshes"][self.mesh_index(name)]
        p = me["primitives"][0]
        at = p["attributes"]
        out = {"V": self.accessor(at["POSITION"]).astype(float), "T": self.accessor(p["indices"]).reshape(-1, 3).astype(int)}
        for k, a in (("N", "NORMAL"), ("UV", "TEXCOORD_0"), ("J", "JOINTS_0"), ("W", "WEIGHTS_0")):
            if a in at:
                out[k] = self.accessor(at[a])
        return out

    def mesh_index(self, name):
        """The mesh on the node called `name` (Blender may have suffixed the mesh's own name)."""
        for n in self.g["nodes"]:
            if n.get("name") == name and "mesh" in n:
                return n["mesh"]
        return next(i for i, m in enumerate(self.g["meshes"]) if m["name"] == name)

    def joint_names(self):
        s = self.g["skins"][0]
        return [self.g["nodes"][j]["name"] for j in s["joints"]]

    def _add(self, arr, comp, typ, target=None, minmax=False):
        arr = np.ascontiguousarray(arr)
        while len(self.bin) % 4:
            self.bin.append(0)
        off = len(self.bin)
        self.bin += arr.tobytes()
        bv = {"buffer": 0, "byteOffset": off, "byteLength": arr.nbytes}
        if target:
            bv["target"] = target
        self.g["bufferViews"].append(bv)
        a = {"bufferView": len(self.g["bufferViews"]) - 1, "componentType": comp, "count": len(arr), "type": typ}
        if minmax:
            a["min"] = arr.min(0).tolist()
            a["max"] = arr.max(0).tolist()
        self.g["accessors"].append(a)
        return len(self.g["accessors"]) - 1

    def _bv(self, arr):
        arr = np.ascontiguousarray(arr)
        while len(self.bin) % 4:
            self.bin.append(0)
        self.g["bufferViews"].append({"buffer": 0, "byteOffset": len(self.bin), "byteLength": arr.nbytes})
        self.bin += arr.tobytes()
        return len(self.g["bufferViews"]) - 1

    def _add_sparse(self, d):
        """Offsets (N, 3) as a sparse accessor: only the vertices that move are stored."""
        d = np.asarray(d, np.float32)
        ids = np.where(np.abs(d).max(1) > 1e-7)[0].astype(np.uint32)
        if len(ids) == 0:
            ids = np.array([0], np.uint32)
        a = {"componentType": 5126, "count": len(d), "type": "VEC3",
             "min": d.min(0).tolist(), "max": d.max(0).tolist(),
             "sparse": {"count": len(ids), "indices": {"bufferView": self._bv(ids), "componentType": 5125},
                        "values": {"bufferView": self._bv(d[ids])}}}
        self.g["accessors"].append(a)
        return len(self.g["accessors"]) - 1

    def set_mesh(self, name, V, N, UV, J, W, T, shapes=None, node_like=None):
        """Replace the mesh `name` (or add it, on a node copied from `node_like`'s, same skin) with
        one primitive; shapes {name: (N, 3) offsets} become morph targets (glTF: offsets)."""
        prim = {"attributes": {
            "POSITION": self._add(np.asarray(V, np.float32), 5126, "VEC3", 34962, True),
            "NORMAL": self._add(np.asarray(N, np.float32), 5126, "VEC3", 34962),
            "TEXCOORD_0": self._add(np.asarray(UV, np.float32), 5126, "VEC2", 34962),
            "JOINTS_0": self._add(np.asarray(J, np.uint16), 5123, "VEC4", 34962),
            "WEIGHTS_0": self._add(np.asarray(W, np.float32), 5126, "VEC4", 34962)},
            "indices": self._add(np.asarray(T, np.uint32).ravel(), 5125, "SCALAR", 34963), "mode": 4}
        mesh = {"name": name, "primitives": [prim]}
        if shapes:
            prim["targets"] = [{"POSITION": self._add_sparse(d)} for d in shapes.values()]
            mesh["weights"] = [0.0] * len(shapes)
            mesh["extras"] = {"targetNames": list(shapes)}
        try:
            self.g["meshes"][self.mesh_index(name)] = mesh
            return
        except StopIteration:
            pass
        self.g["meshes"].append(mesh)
        like = self.mesh_index(node_like)
        si = next(i for i, n in enumerate(self.g["nodes"]) if n.get("mesh") == like)
        node = {k: v for k, v in self.g["nodes"][si].items() if k != "children"}
        node["name"] = name
        node["mesh"] = len(self.g["meshes"]) - 1
        self.g["nodes"].append(node)
        ni = len(self.g["nodes"]) - 1
        for n in self.g["nodes"]:
            if si in n.get("children", []):
                n["children"].append(ni)
                break
        else:
            self.g["scenes"][self.g.get("scene", 0)]["nodes"].append(ni)

    def compact(self):
        """Drop the accessors (and their data) nothing refers to any more."""
        used = set()
        for m in self.g["meshes"]:
            for p in m["primitives"]:
                used |= set(p["attributes"].values())
                if "indices" in p:
                    used.add(p["indices"])
                for t in p.get("targets", []):
                    used |= set(t.values())
        for s in self.g.get("skins", []):
            if "inverseBindMatrices" in s:
                used.add(s["inverseBindMatrices"])
        for an in self.g.get("animations", []):
            for smp in an["samplers"]:
                used |= {smp["input"], smp["output"]}
        old_acc, old_bv, old_bin = self.g["accessors"], self.g["bufferViews"], bytes(self.bin)
        self.g["accessors"], self.g["bufferViews"], self.bin = [], [], bytearray()
        amap = {}
        def copy_bv(k):
            bv = dict(old_bv[k])
            data = old_bin[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]]
            while len(self.bin) % 4:
                self.bin.append(0)
            bv["byteOffset"] = len(self.bin)
            self.bin += data
            self.g["bufferViews"].append(bv)
            return len(self.g["bufferViews"]) - 1
        for i in sorted(used):
            a = json.loads(json.dumps(old_acc[i]))
            if "bufferView" in a:
                a["bufferView"] = copy_bv(a["bufferView"])
            if "sparse" in a:
                a["sparse"]["indices"]["bufferView"] = copy_bv(a["sparse"]["indices"]["bufferView"])
                a["sparse"]["values"]["bufferView"] = copy_bv(a["sparse"]["values"]["bufferView"])
            self.g["accessors"].append(a)
            amap[i] = len(self.g["accessors"]) - 1
        for m in self.g["meshes"]:
            for p in m["primitives"]:
                p["attributes"] = {k: amap[v] for k, v in p["attributes"].items()}
                if "indices" in p:
                    p["indices"] = amap[p["indices"]]
                p["targets"] = [{k: amap[v] for k, v in t.items()} for t in p.get("targets", [])] or None
                if p["targets"] is None:
                    del p["targets"]
        for s in self.g.get("skins", []):
            if "inverseBindMatrices" in s:
                s["inverseBindMatrices"] = amap[s["inverseBindMatrices"]]
        for an in self.g.get("animations", []):
            for smp in an["samplers"]:
                smp["input"], smp["output"] = amap[smp["input"]], amap[smp["output"]]

    def save(self, path):
        self.compact()
        while len(self.bin) % 4:
            self.bin.append(0)
        self.g["buffers"] = [{"byteLength": len(self.bin)}]
        js = json.dumps(self.g, separators=(",", ":")).encode()
        js += b" " * (-len(js) % 4)
        total = 12 + 8 + len(js) + 8 + len(self.bin)
        with open(path, "wb") as f:
            f.write(struct.pack("<III", 0x46546C67, 2, total))
            f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
            f.write(struct.pack("<II", len(self.bin), 0x004E4942) + bytes(self.bin))
