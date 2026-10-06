#!/usr/bin/env python3
"""The Tripo man's head painted in the style, texel by texel onto his own texture.

    python3 tools/characters/head_paint.py guides [--id=stranger]      (numpy only: clay views of his head)
    FAL_KEY=... python3 tools/characters/head_paint.py paint [--scale=1.0] [--strength=0.68] [--seed=7] [--repaint] [--only=front,left]
    python3 tools/characters/head_paint.py bake                         (numpy only: the painted views onto his texture)
    python3 tools/characters/head_paint.py paint --dry-run              (a stand-in painter, no key, no network)

Why: Tripo wants a smooth picture to model from (tools/characters/paint_full_length.py), so the
style LoRA was held back there and the model's face came out smooth. The drawing we want on his
face is the one the LoRA paints at full strength (docs/style_test/lora/portrait.png). So, as the
MakeHuman man's face is done (tools/blender/faces.py, tools/paint_bake.gd): the head is cut off
the Tripo mesh above the collar, rendered in grey clay from six views with an orthographic camera
(`guides`: assets/people/tripo/<id>_head_<view>_guide.png + the view's depth), FLUX Kontext with
the LoRA at full scale paints each clay view as the painting's man (`paint`: Kontext keeps the
clay's outline and features where they are, so no fitting is needed; <id>_head_<view>_painted.png),
and `bake` projects every painted view back through the same camera into the mesh's own UV
space, depth-tested, the view facing each texel squarest winning (weights^3), fills what no view
saw, cuts the head's texels to a palette and to squares of a set size on him (SQUARE_M, the
painting's face squares), and writes <id>_color.png: Tripo's colour texture with the head
repainted (the body as Tripo made it; tools/tripo_lab.gd lays it over his material). A contact
sheet goes to docs/screenshots/tripo/<id>_head_views.png. Runs on Actions (People workflow,
`style: head`) or here; every fal answer is kept in build/characters/head_log.json.

The whole man (2026-10-06, the Rodin stranger: a clean mesh whose skin is a photo): a character
with `body` words in characters.json gets six full-length views as well (<id>_body_<view>_guide.png,
painted as <id>_body_<view>_painted.png), and `bake` lays them on everything below the head the same
way (texels no view saw keep the model's own colour). A Rodin man (people.json `"source": "rodin"`,
his glb at <rodin>.glb under assets/people/tripo) is turned into Tripo's frame and set 1.0 tall
first (load_man). His guides can be lit evenly (`head.guide_light`, 0 = his colours flat, 1 = the
key light the stranger's were painted from): the game lights him, so the paint shouldn't carry
light of its own.
"""
import base64
import io
import json
import os
import struct
import sys
import time
import urllib.error
import urllib.request

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DIR = os.path.join(ROOT, "assets", "people", "tripo")
SPEC = os.path.join(ROOT, "tools", "characters", "characters.json")
LORA = os.path.join(ROOT, "tools", "style", "style_lora.json")
BUILD = os.path.join(ROOT, "build", "characters")
SHOTS = os.path.join(ROOT, "docs", "screenshots", "tripo")
EDITOR = os.environ.get("FAL_HEAD_EDITOR") or "fal-ai/flux-lora/image-to-image"
# How far image-to-image departs from the rendered view (0 = the render back, 1 = text alone):
# enough to repaint it in the style, not enough to move his features or turn his head.
STRENGTH = 0.68
QUEUE = "https://queue.fal.run/"

GUIDE_PX = 768
# The head: everything above this share of his height (the collar's top; chin ~0.86, hat ~1.0).
HEAD_FROM = 0.815
# He stands 1.0 tall in the glb; in the game he's this tall (tools/tripo_lab.gd --height).
HEIGHT_M = 1.8
# The painting's face squares are ~5 mm on him (190 a metre, tools/paint/finish.py).
SQUARE_M = 0.0028
COLOURS = 40
# --smooth (the "quantise once" set): no squares and no palette on the head, written as
# <id>_color_smooth.png (fit_tripo.py --smooth takes it); the screen mosaic quantises once.
SMOOTH = False
# The views: camera yaw about him (0 = in front of him, + round to his left) and a pitch, and
# how much each is trusted where views overlap.
VIEWS = {
    "front": (0.0, 0.0, 1.5),
    "three_quarter_left": (45.0, 0.0, 1.0),
    "left": (90.0, 0.0, 1.0),
    "three_quarter_right": (-45.0, 0.0, 1.0),
    "right": (-90.0, 0.0, 1.0),
    "back": (180.0, 0.0, 0.8),
}
# The whole man's views (characters with `body` words): the same turns, full length, and how much
# each is trusted on the body. Their guides show all of him (a headless figure would puzzle the
# painter); only what's below the head is baked from them.
BODY_VIEWS = dict(VIEWS)
BODY_PX = 1024
ASK_BODY = "SLTCRK, a full-length figure of {of} standing {view}, {looks}, {light}, a plain dark brown background"
BODY_VIEW_WORDS = {
    "front": "seen straight on, his arms held a little out from his sides",
    "three_quarter_left": "turned three-quarters to his left",
    "left": "in full profile from his left side, facing the left edge of the picture",
    "three_quarter_right": "turned three-quarters to his right",
    "right": "in full profile from his right side, facing the right edge of the picture",
    "back": "seen from directly behind, his back to the viewer",
}
# The body's squares on him (the painting's coat squares, tools/paint/finish.py's cloth: 160 a
# metre) and its palette.
SQUARE_M_BODY = 0.00625
COLOURS_BODY = 48
# The bake's texture: the model's own size up to this (a Rodin man's 4096 texels a side are more
# than the fit keeps: tools/blender/fit_tripo.py squares a texture this size to his skin's).
BAKE_MAX = 2048
PEOPLE = os.path.join(ROOT, "assets", "people", "people.json")
# Tripo's man faces +X with Y up.
FORWARD = np.array([1.0, 0.0, 0.0])
UP = np.array([0.0, 1.0, 0.0])

ASK = "SLTCRK, a close portrait of {of} {view}, {looks}, {light}, a plain dark brown background"
# Whose head: the stranger's words, unless the character (characters.json, by the glb's id) has a
# `head` of its own: `of`, `looks`, `light`, any view's words (`front`, `back`, ...), and `cut`,
# the head's share of his height in place of HEAD_FROM (a bare-headed man is shorter, so his collar
# is a larger share of it).
HEAD = {
    "of": "a frontier gunman's head",
    "looks": "weathered sun-darkened skin, deep-set dark eyes, heavy dark brows, a thick dark drooping "
             "moustache, no beard, long dark hair to his collar, a dark brown wide-brimmed hat with a "
             "studded band",
    "light": "warm oil-lamp light on his face",
}
# Each view's words (the render it starts from already has the head turned that way).
VIEW_WORDS = {
    "front": "seen straight on, looking at the viewer from under the hat brim",
    "three_quarter_left": "turned three-quarters to his left, looking off to the left of the viewer",
    "left": "in full profile from his left side, his nose pointing to the left edge of the picture",
    "three_quarter_right": "turned three-quarters to his right, looking off to the right of the viewer",
    "right": "in full profile from his right side, his nose pointing to the right edge of the picture",
    "back": "seen from directly behind, the back of his hat and his long hair on his collar, no face",
}


# ---------------------------------------------------------------- the glb

def load_glb(path):
    """The one mesh's positions, normals, UVs, triangles, and the colour texture (a PIL image)."""
    f = open(path, "rb").read()
    _magic, _ver, _length = struct.unpack("<4sII", f[:12])
    clen, _ctype = struct.unpack("<I4s", f[12:20])
    doc = json.loads(f[20:20 + clen])
    blen, _btype = struct.unpack("<I4s", f[20 + clen:28 + clen])
    binary = f[28 + clen:28 + clen + blen]

    def accessor(i):
        a = doc["accessors"][i]
        bv = doc["bufferViews"][a["bufferView"]]
        dtype = {5126: np.float32, 5123: np.uint16, 5125: np.uint32, 5121: np.uint8}[a["componentType"]]
        n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
        start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        stride = bv.get("byteStride", 0)
        if stride and stride != n * np.dtype(dtype).itemsize:
            rows = np.frombuffer(binary, dtype=np.uint8, count=stride * a["count"], offset=start).reshape(a["count"], stride)
            return rows[:, :n * np.dtype(dtype).itemsize].copy().view(dtype).reshape(a["count"], n)
        return np.frombuffer(binary, dtype=dtype, count=a["count"] * n, offset=start).reshape(a["count"], n).astype(np.float64 if dtype == np.float32 else np.int64)

    prim = doc["meshes"][0]["primitives"][0]
    pos = accessor(prim["attributes"]["POSITION"])
    nrm = accessor(prim["attributes"]["NORMAL"])
    uv = accessor(prim["attributes"]["TEXCOORD_0"])
    tris = accessor(prim["indices"]).reshape(-1, 3)
    mat = doc["materials"][prim.get("material", 0)]
    tex = doc["textures"][mat["pbrMetallicRoughness"]["baseColorTexture"]["index"]]
    img = doc["images"][tex["source"]]
    bv = doc["bufferViews"][img["bufferView"]]
    colour = Image.open(io.BytesIO(binary[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]])).convert("RGB")
    return pos, nrm, uv, tris, colour


def load_man(cid):
    """His mesh and colour as the rest works on them: Tripo's frame (facing +X, his right at +Z),
    feet on 0, 1.0 tall. A Tripo man's glb comes so; a Rodin man (people.json `source` rodin) is
    built facing +Z with his right at -X at a size of its own, and is turned and set so."""
    spec = json.load(open(PEOPLE))["people"].get(cid, {}) if os.path.exists(PEOPLE) else {}
    if spec.get("source") != "rodin":
        return load_glb(os.path.join(DIR, cid + ".glb"))
    pos, nrm, uv, tris, colour = load_glb(os.path.join(DIR, spec["rodin"] + ".glb"))
    turn = lambda p: np.stack([p[:, 2], p[:, 1], -p[:, 0]], axis=1)
    pos, nrm = turn(pos), turn(nrm)
    y0, y1 = pos[:, 1].min(), pos[:, 1].max()
    pos = (pos - np.array([0.0, y0, 0.0])) / (y1 - y0)
    pos -= np.array([(pos[:, 0].min() + pos[:, 0].max()) / 2, 0.0, (pos[:, 2].min() + pos[:, 2].max()) / 2])
    return pos, nrm, uv, tris, colour


def head_spec(cid):
    """The character's head words (HEAD, with characters.json's `head` over it) and view words."""
    own = json.load(open(SPEC))["characters"].get(cid, {}).get("head", {})
    return dict(HEAD, **own), dict(VIEW_WORDS, **{k: v for k, v in own.items() if k in VIEW_WORDS})


def body_spec(cid):
    """The character's body words (characters.json `body`: of, looks, light, any view's words),
    and the view words; None when he has none (his head alone is painted)."""
    own = json.load(open(SPEC))["characters"].get(cid, {}).get("body")
    if not own:
        return None, None
    return own, dict(BODY_VIEW_WORDS, **{k: v for k, v in own.items() if k in BODY_VIEW_WORDS})


def body_triangles(pos, tris, share=None):
    """Everything not in his head: the triangles with a corner at or below the head's cut."""
    y0, y1 = pos[:, 1].min(), pos[:, 1].max()
    cut = y0 + (y1 - y0) * (HEAD_FROM if share is None else share)
    return tris[~(pos[tris, 1] > cut).all(axis=1)]


def head_triangles(pos, tris, share=None):
    """The triangles of his head: all three corners above HEAD_FROM (or `share`) of his height."""
    y0, y1 = pos[:, 1].min(), pos[:, 1].max()
    cut = y0 + (y1 - y0) * (HEAD_FROM if share is None else share)
    return tris[(pos[tris, 1] > cut).all(axis=1)]


# ---------------------------------------------------------------- cameras and rasters

def camera(yaw, pitch):
    """An orthographic camera's axes: right, up, forward (the way it looks)."""
    yaw, pitch = np.deg2rad(yaw), np.deg2rad(pitch)
    # Round him: yaw 0 stands in front of him looking back at him.
    left = np.cross(UP, FORWARD)
    at = np.cos(yaw) * FORWARD + np.sin(yaw) * left        # where the camera stands, from him
    at = np.cos(pitch) * at + np.sin(pitch) * UP
    f = -at / np.linalg.norm(at)
    r = np.cross(f, UP)
    r /= np.linalg.norm(r)
    u = np.cross(r, f)
    return r, u, f


def head_frame(pos, htris):
    """The head's centre and the frame's size (square, a little room round it)."""
    v = pos[np.unique(htris)]
    lo, hi = v.min(axis=0), v.max(axis=0)
    centre = (lo + hi) / 2
    return centre, float((hi - lo).max() * 1.18)


def to_view(p, centre, frame, r, u, f, size=GUIDE_PX):
    """Points -> (x px, y px, depth) in a view `size` pixels a side; depth grows away from the camera."""
    d = p - centre
    x = (d @ r / frame + 0.5) * size
    y = (0.5 - d @ u / frame) * size
    return x, y, d @ f


def raster(xs, ys, w, h):
    """Pixel centres inside a triangle and their barycentrics (as faces.py)."""
    x0, x1 = int(max(np.floor(xs.min()), 0)), int(min(np.ceil(xs.max()), w - 1))
    y0, y1 = int(max(np.floor(ys.min()), 0)), int(min(np.ceil(ys.max()), h - 1))
    d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
    if x1 < x0 or y1 < y0 or abs(d) < 1e-9:
        return None
    py, px = np.mgrid[y0:y1 + 1, x0:x1 + 1]
    cx, cy = px + 0.5, py + 0.5
    a = ((ys[1] - ys[2]) * (cx - xs[2]) + (xs[2] - xs[1]) * (cy - ys[2])) / d
    b = ((ys[2] - ys[0]) * (cx - xs[2]) + (xs[0] - xs[2]) * (cy - ys[2])) / d
    c = 1 - a - b
    inside = np.minimum(np.minimum(a, b), c) >= -0.015
    return px[inside], py[inside], a[inside], b[inside], c[inside]


def render_view(pos, nrm, htris, centre, frame, cam, uv=None, colour=None, size=GUIDE_PX, key=1.0):
    """A render of the head (or whatever `htris` holds) from a view `size` pixels a side (grey clay,
    or the model's own colours when `uv` and `colour` are given; a key light up and to the
    camera's left, `key` of it: 0 is his colours evenly lit, shaded only a little by how squarely
    each part faces you; a dark ground) and its depth buffer (inf where nothing is)."""
    GUIDE_PX = size
    r, u, f = cam
    tex = np.asarray(colour, dtype=np.float64) if colour is not None else None
    tex_u = np.zeros((GUIDE_PX, GUIDE_PX))
    tex_v = np.zeros((GUIDE_PX, GUIDE_PX))
    x, y, z = to_view(pos, centre, frame, r, u, f, size)
    depth = np.full((GUIDE_PX, GUIDE_PX), np.inf)
    shade = np.zeros((GUIDE_PX, GUIDE_PX))
    even = np.zeros((GUIDE_PX, GUIDE_PX))
    light = -f * 0.8 + u * 0.45 - r * 0.35
    light /= np.linalg.norm(light)
    lit = np.clip(nrm @ light, 0.0, 1.0)
    fill = np.clip(nrm @ (-f), 0.0, 1.0)
    for t in htris:
        rr = raster(x[t], y[t], GUIDE_PX, GUIDE_PX)
        if rr is None:
            continue
        px, py, a, b, c = rr
        zz = a * z[t[0]] + b * z[t[1]] + c * z[t[2]]
        near = zz < depth[py, px]
        if not near.any():
            continue
        px, py, a, b, c, zz = px[near], py[near], a[near], b[near], c[near], zz[near]
        depth[py, px] = zz
        facing = a * fill[t[0]] + b * fill[t[1]] + c * fill[t[2]]
        shade[py, px] = 0.16 + 0.62 * (a * lit[t[0]] + b * lit[t[1]] + c * lit[t[2]]) + 0.14 * facing
        even[py, px] = 0.8 + 0.2 * facing
        if tex is not None:
            tex_u[py, px] = a * uv[t[0], 0] + b * uv[t[1], 0] + c * uv[t[2], 0]
            tex_v[py, px] = a * uv[t[0], 1] + b * uv[t[1], 1] + c * uv[t[2], 1]
    img = np.full((GUIDE_PX, GUIDE_PX, 3), (46.0, 34.0, 24.0) if tex is not None else 34.0)
    seen = np.isfinite(depth)
    if tex is not None:
        th, tw = tex.shape[:2]
        ui = np.clip((tex_u[seen] * tw).astype(int), 0, tw - 1)
        vi = np.clip((tex_v[seen] * th).astype(int), 0, th - 1)
        lit_by = np.clip(0.35 + 0.75 * shade[seen], 0, 1.1) * key + even[seen] * (1.0 - key)
        img[seen] = tex[vi, ui] * lit_by[:, None]
    else:
        g = np.clip(shade[seen], 0, 1) * 255
        img[seen] = np.stack([g, g, g * 0.97], axis=1)
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)), depth


def body_frame(pos):
    """All of him: his middle and the frame's size (square, a little room round him)."""
    lo, hi = pos.min(axis=0), pos.max(axis=0)
    return (lo + hi) / 2, float((hi - lo).max() * 1.06)


def guides(cid):
    pos, nrm, uv, tris, colour = load_man(cid)
    head = head_spec(cid)[0]
    key = float(head.get("guide_light", 1.0))
    htris = head_triangles(pos, tris, head.get("cut"))
    centre, frame = head_frame(pos, htris)
    print("%s: %d head triangles of %d, frame %.3f (%.0f mm)" % (cid, len(htris), len(tris), frame, frame * HEIGHT_M * 1000))
    for view, (yaw, pitch, _w) in VIEWS.items():
        img, depth = render_view(pos, nrm, htris, centre, frame, camera(yaw, pitch), uv, colour, key=key)
        img.save(os.path.join(DIR, "%s_head_%s_guide.png" % (cid, view)))
        print("  guide:", view)
    if body_spec(cid)[0] is None:
        return
    centre, frame = body_frame(pos)
    for view, (yaw, pitch, _w) in BODY_VIEWS.items():
        img, depth = render_view(pos, nrm, tris, centre, frame, camera(yaw, pitch), uv, colour, size=BODY_PX, key=key)
        img.save(os.path.join(DIR, "%s_body_%s_guide.png" % (cid, view)))
        print("  guide: body", view)


# ---------------------------------------------------------------- fal

def request(method, url, key, body=None):
    headers = {"Authorization": "Key " + key}
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            text = r.read().decode(errors="replace")
            return json.loads(text) if text.strip() else {}
    except urllib.error.HTTPError as e:
        raise RuntimeError("%s %s: fal said %d: %s" % (method, url, e.code, e.read().decode(errors="replace")[:800])) from None


def data_url(img):
    buf = io.BytesIO()
    img.convert("RGB").save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def edit(img, prompt, lora_url, scale, seed, key, log, what, strength=None):
    body = {"image_url": data_url(img), "prompt": prompt, "num_images": 1, "seed": seed, "output_format": "png",
            "enable_safety_checker": False, "loras": [{"path": lora_url, "scale": scale}] if scale > 0 else []}
    if "kontext" in EDITOR:
        body.update({"num_inference_steps": 30, "guidance_scale": 2.5, "resolution_mode": "match_input"})
    else:
        body.update({"num_inference_steps": 28, "guidance_scale": 3.5, "strength": STRENGTH if strength is None else strength})
    queued = request("POST", QUEUE + EDITOR, key, body)
    log.append({what: {"queued": queued, "prompt": prompt, "scale": scale, "seed": seed}})
    status_url = queued.get("status_url") or "%s%s/requests/%s/status" % (QUEUE, EDITOR, queued["request_id"])
    response_url = queued.get("response_url") or "%s%s/requests/%s" % (QUEUE, EDITOR, queued["request_id"])
    for _ in range(120):
        st = request("GET", status_url, key)
        state = st.get("status")
        if state == "COMPLETED":
            answer = request("GET", response_url, key)
            log.append({what + "_answer": answer})
            images = answer.get("images") or []
            if not images:
                raise RuntimeError("no image in the answer: %s" % json.dumps(answer)[:600])
            with urllib.request.urlopen(images[0]["url"], timeout=600) as r:
                return Image.open(io.BytesIO(r.read())).convert("RGB")
        if state not in ("IN_QUEUE", "IN_PROGRESS"):
            log.append({what + "_status": st})
            raise RuntimeError("%s stopped: %s" % (what, json.dumps(st)[:800]))
        time.sleep(5)
    raise RuntimeError("%s: still not done after ten minutes" % what)


def jobs(cid):
    """What there is to paint: (kind, view, the ask, the guide's size). His head's six views, then,
    if he has body words, his whole body's six; `--only` names a head view as `front` and a body
    view as `body_front`."""
    head, view_words = head_spec(cid)
    out = [("head", view, ASK.format(of=head["of"], view=view_words[view], looks=head["looks"], light=head["light"]),
            GUIDE_PX) for view in VIEWS]
    body, body_words = body_spec(cid)
    if body is not None:
        out += [("body", view, ASK_BODY.format(of=body["of"], view=body_words[view], looks=body["looks"],
                                               light=body["light"]), BODY_PX) for view in BODY_VIEWS]
    return out


def paint(cid, key, scale, seed, repaint, only, editor=edit, out_dir=None, strength=None):
    out_dir = out_dir or DIR
    lora_url = json.load(open(LORA))["lora_url"] if os.path.exists(LORA) else ""
    if not lora_url:
        print("No %s: the LoRA isn't trained; painting without it." % LORA)
        scale = 0.0
    os.makedirs(BUILD, exist_ok=True)
    log = [{"editor": EDITOR, "lora_url": lora_url, "scale": scale, "seed": seed, "strength": STRENGTH if strength is None else strength}]
    failed = []
    for kind, view, ask, size in jobs(cid):
        name = view if kind == "head" else "body_" + view
        if only and name not in only:
            continue
        out = os.path.join(out_dir, "%s_%s_%s_painted.png" % (cid, kind, view))
        if os.path.exists(out) and not repaint:
            print("already painted:", name)
            continue
        guide = os.path.join(DIR, "%s_%s_%s_guide.png" % (cid, kind, view))
        if not os.path.exists(guide):
            print("no guide for", name, "(run `guides` first)")
            failed.append(name)
            continue
        try:
            img = editor(Image.open(guide), ask, lora_url, scale, seed, key, log, "%s_%s_%s" % (cid, kind, view), strength)
            if img.size != (size, size):
                img = img.resize((size, size), Image.LANCZOS)
            img.save(out)
            print("painted:", name, img.size)
        except (RuntimeError, OSError, KeyError, ValueError) as e:
            print("failed:", name, e)
            failed.append(name)
        with open(os.path.join(BUILD, "head_log.json"), "w") as f:
            json.dump(log, f, indent=1)
    if failed:
        print("not painted:", ", ".join(failed))
        sys.exit(1)


# ---------------------------------------------------------------- the bake

def uv_raster(uv, htris, size):
    """Every texel of the head's UV islands: which triangle and where in it."""
    tri_id = np.full((size, size), -1, dtype=np.int64)
    bary = np.zeros((size, size, 3))
    xs = uv[:, 0] * size
    ys = uv[:, 1] * size
    for i, t in enumerate(htris):
        rr = raster(xs[t], ys[t], size, size)
        if rr is None:
            continue
        px, py, a, b, c = rr
        tri_id[py, px] = i
        bary[py, px] = np.stack([a, b, c], axis=1)
    return tri_id, bary


def palette(rgb, n, seed=3):
    """k-means to n colours (float 0..255 rows)."""
    rng = np.random.default_rng(seed)
    pick = rgb[rng.choice(len(rgb), size=min(len(rgb), 4000), replace=False)]
    centres = pick[rng.choice(len(pick), size=n, replace=False)]
    for _ in range(12):
        d = ((pick[:, None, :] - centres[None, :, :]) ** 2).sum(axis=2)
        lab = d.argmin(axis=1)
        for k in range(n):
            m = lab == k
            if m.any():
                centres[k] = pick[m].mean(axis=0)
    d = ((rgb[:, None, :] - centres[None, :, :]) ** 2).sum(axis=2)
    return centres[d.argmin(axis=1)]


def project(cid, kind, views, pos, nrm, uv, tris, render_tris, centre, frame, size, px):
    """The texels of `tris`'s UV islands (a texture `size` a side) and their colours from his
    painted views of this kind, each seen through its guide's camera (`px` a side, the depth of
    `render_tris` as the guide drew them) and depth-tested; returns their rows and columns, their
    colours, which were seen, and the views used."""
    tri_id, bary = uv_raster(uv, tris, size)
    texels = np.argwhere(tri_id >= 0)
    ty, tx = texels[:, 0], texels[:, 1]
    t = tris[tri_id[ty, tx]]
    b = bary[ty, tx]
    p = (pos[t[:, 0]] * b[:, :1] + pos[t[:, 1]] * b[:, 1:2] + pos[t[:, 2]] * b[:, 2:3])
    n = (nrm[t[:, 0]] * b[:, :1] + nrm[t[:, 1]] * b[:, 1:2] + nrm[t[:, 2]] * b[:, 2:3])
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)
    print("%s: %d %s texels of %d^2" % (cid, len(texels), kind, size))
    total = np.zeros((len(texels), 3))
    weight = np.zeros(len(texels))
    tolerance = frame * 0.012
    used = []
    for view, (yaw, pitch, trust) in views.items():
        painted = os.path.join(DIR, "%s_%s_%s_painted.png" % (cid, kind, view))
        if not os.path.exists(painted):
            print("  no painting for", kind, view)
            continue
        img = np.asarray(Image.open(painted).convert("RGB").resize((px, px), Image.LANCZOS), dtype=np.float64)
        cam = camera(yaw, pitch)
        _guide, depth = render_view(pos, nrm, render_tris, centre, frame, cam, size=px)   # the view's depth, as the guide saw it
        r, u, f = cam
        x, y, z = to_view(p, centre, frame, r, u, f, px)
        xi = np.clip(np.floor(x).astype(int), 0, px - 1)
        yi = np.clip(np.floor(y).astype(int), 0, px - 1)
        inside = (x >= 0) & (x < px) & (y >= 0) & (y < px)
        # Seen: at the front of what the view's depth buffer holds there (loosened to the farthest
        # of the 3x3 round it, so a texel a pixel off an edge still counts).
        d3 = depth.copy()
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                d3 = np.maximum(d3, np.roll(np.roll(depth, dy, axis=0), dx, axis=1))
        seen = inside & (z <= d3[yi, xi] + tolerance)
        facing = np.clip(n @ (-f), 0.0, 1.0)
        # The squarest view wins outright (weights^8): averaging views that don't register
        # exactly blurred the drawing to blobs; the painting's blocks are crisp.
        w = np.where(seen, facing ** 8, 0.0) * trust
        total += img[yi, xi] * w[:, None]
        weight += w
        used.append(view)
        print("  %s %s: %.0f%% of the texels seen" % (kind, view, 100.0 * seen.mean()))
    got = weight > 1e-6
    rgb = np.zeros((len(texels), 3))
    rgb[got] = total[got] / weight[got, None]
    return ty, tx, rgb, got, used


def in_squares(sheet, mask, pos, uv, tris, size, square_m, colours, what):
    """The masked texels of `sheet` (in place) in squares of `square_m` on him (texels a metre from
    the islands' UV area against their true area) and cut to `colours` colours."""
    a3 = 0.5 * np.linalg.norm(np.cross(pos[tris[:, 1]] - pos[tris[:, 0]], pos[tris[:, 2]] - pos[tris[:, 0]]), axis=1).sum() * HEIGHT_M ** 2
    e1, e2 = uv[tris[:, 1]] - uv[tris[:, 0]], uv[tris[:, 2]] - uv[tris[:, 0]]
    a2 = 0.5 * np.abs(e1[:, 0] * e2[:, 1] - e1[:, 1] * e2[:, 0]).sum() * size ** 2
    texels_per_m = np.sqrt(a2 / a3)
    sq = max(1, int(round(square_m * texels_per_m)))
    print("  %.0f texels a metre on the %s; squares of %d texels" % (texels_per_m, what, sq))
    if sq > 1:
        hs = (size // sq) * sq
        block = sheet[:hs, :hs].reshape(hs // sq, sq, hs // sq, sq, 3)
        count = mask[:hs, :hs].reshape(hs // sq, sq, hs // sq, sq).astype(np.float64)
        mean = (block * count[..., None]).sum(axis=(1, 3)) / np.maximum(count.sum(axis=(1, 3)), 1)[..., None]
        squared = np.repeat(np.repeat(mean, sq, axis=0), sq, axis=1)
        inside = np.repeat(np.repeat(count.sum(axis=(1, 3)) > 0, sq, axis=0), sq, axis=1)
        sheet[:hs, :hs][inside] = squared[inside]
    ty, tx = np.nonzero(mask)
    sheet[ty, tx] = palette(sheet[ty, tx], colours)


def bake(cid):
    from scipy import ndimage
    pos, nrm, uv, tris, colour = load_man(cid)
    head = head_spec(cid)[0]
    htris = head_triangles(pos, tris, head.get("cut"))
    size = min(colour.width, BAKE_MAX)
    base = colour if colour.width == size else colour.resize((size, size), Image.LANCZOS)
    out = np.asarray(base, dtype=np.float64).copy()
    centre, frame = head_frame(pos, htris)
    ty, tx, rgb, got, used = project(cid, "head", VIEWS, pos, nrm, uv, htris, htris, centre, frame, size, GUIDE_PX)
    if not used:
        print("nothing painted yet (run `paint`)")
        sys.exit(1)
    # The head: what no view saw filled from the nearest texel that was (in UV space).
    mask = np.zeros((size, size), dtype=bool)
    mask[ty, tx] = True
    known = np.zeros((size, size), dtype=bool)
    known[ty[got], tx[got]] = True
    sheet = np.zeros((size, size, 3))
    sheet[ty, tx] = rgb
    _d, (iy, ix) = ndimage.distance_transform_edt(~known, return_indices=True)
    sheet = sheet[iy, ix]
    if not SMOOTH:
        in_squares(sheet, mask, pos, uv, htris, size, SQUARE_M, COLOURS, "head")
    out[ty, tx] = sheet[ty, tx]
    if body_spec(cid)[0] is not None:
        # The body: from the full-length views; what none saw keeps the model's own colour.
        btris = body_triangles(pos, tris, head.get("cut"))
        centre, frame = body_frame(pos)
        by, bx, brgb, bgot, bused = project(cid, "body", BODY_VIEWS, pos, nrm, uv, btris, tris, centre, frame, size, BODY_PX)
        if bused:
            sheet = np.asarray(base, dtype=np.float64).copy()
            sheet[by[bgot], bx[bgot]] = brgb[bgot]
            bmask = np.zeros((size, size), dtype=bool)
            bmask[by, bx] = True
            bmask[ty, tx] = False      # a texel in both (a seam's edge) stays the head's
            if not SMOOTH:
                in_squares(sheet, bmask, pos, uv, btris, size, SQUARE_M_BODY, COLOURS_BODY, "body")
            out[bmask] = sheet[bmask]
            used += ["body " + v for v in bused]
            print("  %.0f%% of the body's texels painted" % (100.0 * bgot.mean()))
    name = cid + ("_color_smooth.png" if SMOOTH else "_color.png")
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(os.path.join(DIR, name))
    print("wrote", os.path.join(DIR, name), "from", ", ".join(used))
    if not SMOOTH:
        contact(cid)


def contact(cid, cell=384):
    """Guides over paintings, a view a column: docs/screenshots/tripo/<id>_head_views.png, and
    <id>_body_views.png for a man painted whole."""
    os.makedirs(SHOTS, exist_ok=True)
    for kind, views in (("head", VIEWS), ("body", BODY_VIEWS)):
        cols = []
        for view in views:
            g = os.path.join(DIR, "%s_%s_%s_guide.png" % (cid, kind, view))
            p = os.path.join(DIR, "%s_%s_%s_painted.png" % (cid, kind, view))
            if not os.path.exists(g):
                continue
            col = Image.new("RGB", (cell, cell * 2 + 18), (28, 28, 28))
            col.paste(Image.open(g).convert("RGB").resize((cell, cell), Image.LANCZOS), (0, 18))
            if os.path.exists(p):
                col.paste(Image.open(p).convert("RGB").resize((cell, cell), Image.NEAREST), (0, cell + 18))
            ImageDraw.Draw(col).text((4, 3), view, fill=(255, 255, 255))
            cols.append(col)
        if not cols:
            continue
        sheet = Image.new("RGB", (len(cols) * (cell + 4), cell * 2 + 18), (28, 28, 28))
        for i, c in enumerate(cols):
            sheet.paste(c, (i * (cell + 4), 0))
        sheet.save(os.path.join(SHOTS, "%s_%s_views.png" % (cid, kind)))


def dry_run(cid):
    """The paint step on a stand-in editor (flat pictures with the guide's shape), into a scratch folder."""
    import tempfile
    scratch = tempfile.mkdtemp(prefix="head_dry_")

    def standin(img, prompt, lora_url, scale, seed, key, log, what, strength=None):
        if "SLTCRK" not in prompt or "hat" not in prompt:
            raise RuntimeError("the ask lost its trigger word or its pixels: " + what)
        a = np.asarray(img.convert("RGB"), dtype=np.float64)
        a[..., 0] *= 1.2
        a[..., 2] *= 0.6
        return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))

    paint(cid, "dry-run-key", 1.0, 7, True, None, standin, scratch)
    for kind, view, _ask, _size in jobs(cid):
        if not os.path.exists(os.path.join(scratch, "%s_%s_%s_painted.png" % (cid, kind, view))):
            print("dry run FAILED: no", kind, view)
            sys.exit(1)
    print("dry run passed:", scratch)


def main():
    global SMOOTH
    SMOOTH = "--smooth" in sys.argv
    step = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else ""
    cid, scale, seed, only, strength = "stranger", 1.0, 7, None, None
    for a in sys.argv[2:]:
        if a.startswith("--id="):
            cid = a.split("=", 1)[1]
        elif a.startswith("--strength="):
            strength = float(a.split("=", 1)[1])
        elif a.startswith("--scale="):
            scale = float(a.split("=", 1)[1])
        elif a.startswith("--seed="):
            seed = int(a.split("=", 1)[1])
        elif a.startswith("--only=") and a.split("=", 1)[1]:
            only = a.split("=", 1)[1].split(",")
    if step == "guides":
        guides(cid)
    elif step == "paint":
        if "--dry-run" in sys.argv:
            dry_run(cid)
            return
        key = os.environ.get("FAL_KEY", "")
        if not key:
            print("No FAL_KEY: nothing painted.")
            return
        paint(cid, key, scale, seed, "--repaint" in sys.argv, only, strength=strength)
    elif step == "bake":
        bake(cid)
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main()
