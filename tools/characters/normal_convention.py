#!/usr/bin/env python3
"""Which way a tangent-space normal map's green channel points, measured (docs/briefs/faces.md).

    python3 tools/characters/normal_convention.py MAP.png|MODEL.glb [...]

A correct normal map is the slope of a height field, so its curl is near nothing: with slopes
p = dh/du and q = dh/dv taken from the map, dp/dv = dq/du. Read with the wrong sign on green the
two disagree. Each map is read both ways (OpenGL, +Y up the texture; DirectX, green flipped) and
the curl's share of the whole is printed for each: the convention is the one with the smaller
share. A glb's first material's normal texture is read. Calibrated on tools/blender/normal_check.py's
bump (OpenGL: 0.12 against 8.2 flipped).
"""
import io
import json
import struct
import sys

import numpy as np
from PIL import Image


def load_normal(path):
    if not path.endswith(".glb"):
        return np.asarray(Image.open(path).convert("RGB")).astype(float) / 255
    b = open(path, "rb").read()
    n = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + n])
    start = 20 + n + 8
    for m in j.get("materials", []):
        if "normalTexture" in m:
            img = j["images"][j["textures"][m["normalTexture"]["index"]]["source"]]
            bv = j["bufferViews"][img["bufferView"]]
            o = start + bv.get("byteOffset", 0)
            return np.asarray(Image.open(io.BytesIO(b[o:o + bv["byteLength"]])).convert("RGB")).astype(float) / 255
    return None


def shares(a):
    """The curl's share read as OpenGL (+Y) and as DirectX (-Y)."""
    n = a * 2 - 1
    nz = np.clip(n[..., 2], 0.2, None)
    p = -n[..., 0] / nz
    q = -n[..., 1] / nz
    dp_dv = -(p[2:, 1:-1] - p[:-2, 1:-1]) / 2      # rows run down the texture, v up it
    dq_du = (q[1:-1, 2:] - q[1:-1, :-2]) / 2
    m = (np.abs(n[1:-1, 1:-1, 2]) > 0.2) & (np.abs(dp_dv) < 1) & (np.abs(dq_du) < 1)  # not across island edges
    out = []
    for sign in (1, -1):
        c = dp_dv - sign * dq_du
        s = dp_dv + sign * dq_du
        out.append(float(np.sqrt((c[m] ** 2).mean()) / max(np.sqrt((s[m] ** 2).mean()), 1e-9)))
    return out


def main():
    for path in sys.argv[1:]:
        a = load_normal(path)
        if a is None:
            print("%s: no normal map" % path)
            continue
        gl, dx = shares(a)
        print("%s: curl share read as OpenGL %.3f, as DirectX %.3f: %s" % (path, gl, dx, "OpenGL (+Y)" if gl < dx else "DirectX (-Y)"))


if __name__ == "__main__":
    main()
