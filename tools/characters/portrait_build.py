"""The portrait factory's Blender half (tools/characters/portrait.py build; needs bpy).

His body is the character factory's (tools/blender/factory_build.py: MakeHuman's base mesh with the
base head's targets and forms, warped onto our joints and the envelope, skinned to our 17 bones,
clothes.py's garments) with his fitted face targets, and his head wears the portrait's texture on
the shared layout instead of the factory's scripted paint. → assets/people/<id>_portrait.glb,
<id>_portrait_head.png, <id>_portrait.json.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "blender"))
import factory as F  # noqa: E402
import factory_build as FB  # noqa: E402
import make_people as mp  # noqa: E402
import portrait as PT  # noqa: E402


def hair_shell(person, table, depth):
    """His hair's shell on his built (warped) head: every layout face whose corners all have a depth,
    moved out along the normals by it, with a wall round its edge back to just off the skin. Returns
    (positions, weights, faces, uvs per face): the shell's faces use the head's own layout."""
    v = person.v
    faces = [list(f) for f in table]
    tris = np.array([t for f in faces for t in [(f[0], f[j], f[j + 1]) for j in range(1, len(f) - 1)]])
    n = PT.vertex_normals(v, tris)
    keep = [f for f in table if all(i in depth for i in f)]
    ids = sorted({i for f in keep for i in f})
    idx = {i: k for k, i in enumerate(ids)}
    P = [v[i] + n[i] * depth[i] for i in ids]
    W = [person.W[i] for i in ids]
    F_out = [[idx[i] for i in f] for f in keep]
    uvs = [list(table[f]) for f in keep]
    # The wall: each edge only one kept face has, from the shell down to the skin.
    count, uv_of = {}, {}
    for f in keep:
        for j in range(len(f)):
            a, b = f[j], f[(j + 1) % len(f)]
            e = (min(a, b), max(a, b))
            count[e] = count.get(e, 0) + 1
            uv_of[(a, b)] = (table[f][j], table[f][(j + 1) % len(f)])
    for f in keep:
        for j in range(len(f)):
            a, b = f[j], f[(j + 1) % len(f)]
            if count[(min(a, b), max(a, b))] != 1:
                continue
            ua, ub = uv_of[(a, b)]
            ia, ib = len(P), len(P) + 1
            P += [v[a] + n[a] * 0.0005, v[b] + n[b] * 0.0005]
            W += [person.W[a], person.W[b]]
            F_out.append([idx[b], idx[a], ia, ib])
            uvs.append([ub, ua, ua, ub])
    return np.array(P), np.array(W), F_out, uvs


def build(man, spec, env, fitted):
    pid = man + "_portrait"
    tex_path = os.path.join(PT.WORK, man + "_head.png")
    tex = np.asarray(Image.open(tex_path).convert("RGB")).astype(float) / 255.0
    if tex.shape[0] != FB.HEAD_TEX:
        raise SystemExit("portrait: %s is %d texels, the layout wants %d" % (tex_path, tex.shape[0], FB.HEAD_TEX))
    factory = F.load_factory()
    skin = np.array(fitted.get("skin_tone", fitted["skin"]))
    fspec = {
        "source": "factory",
        "targets": {**fitted["macro"], **fitted["targets"]},
        "hair": "none", "moustache": "none", "beard": "none",
        "skin": "#%02x%02x%02x" % tuple(int(round(c * 255)) for c in skin),
        "outfit": spec.get("outfit", {}),
    }
    # The factory's build, with his projected head in place of its scripted paint, and his hair's
    # shell (portrait.py's depths, its own projected texture on the same layout) for its shells.
    table, _rects = PT.layout(env)
    hair = json.load(open(os.path.join(PT.WORK, man + "_hair.json")))
    depth = {int(k): float(d) for k, d in hair["depth"].items()}
    hair_tex = np.asarray(Image.open(os.path.join(PT.WORK, man + "_hair.png")).convert("RGB")).astype(float) / 255.0
    made = {}

    def shells(person, _base, _spec, _factory):
        P, W, F_out, uvs = hair_shell(person, table, depth)
        made["uvs"] = uvs
        return [("hair", (P, W, F_out, ["top"] * len(F_out)))]

    FB.paint_head = lambda *_a, **_k: tex
    FB.shells = shells
    FB.shell_uv = lambda *_a, **_k: made["uvs"]
    FB.paint_hair = lambda *_a, **_k: hair_tex
    FB.build(pid, fspec, env, factory)
    rep_path = os.path.join(mp.OUT, pid + ".json")
    rep = json.load(open(rep_path))
    rep["source"] = "portrait"
    rep["portrait"] = {"pictures": spec["pictures"], "fit": fitted["report"], "targets": fitted["targets"]}
    json.dump(rep, open(rep_path, "w"), indent=1)
    print("portrait: built", pid)
