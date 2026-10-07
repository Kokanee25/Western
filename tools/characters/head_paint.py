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
# How far the body's views may depart from their guides: less than the head's. At the head's
# 0.68 the painter redrew his clothes (run 50: a sack coat to the hips came back to the knees,
# with a belt and tall boots, and his back as a vest with pale sleeves), and the bake lays a
# painting on the body where the guide drew it, so a coat painted on his thighs is his trousers'.
STRENGTH_BODY = 0.5
# The body's squares on him (the painting's coat squares, tools/paint/finish.py's cloth: 160 a
# metre) and its palette.
SQUARE_M_BODY = 0.00625
COLOURS_BODY = 48
# The bake's texture: the model's own size up to this (a Rodin man's 4096 texels a side are more
# than the fit keeps: tools/blender/fit_tripo.py squares a texture this size to his skin's).
BAKE_MAX = 2048
# Where views overlap, each texel's colour is their average weighted by (facing ** VIEW_POWER) ×
# trust; 0 = no average, the one view with the most weight at facing ** 8 gives it. Painted squares
# from two views never line up, so an average lays one grid over the other (--view-power=N).
VIEW_POWER = 8
# The painter draws its squares with soft edges and little contrast, so at the game's scale they
# read as a smooth painting. FLATTEN > 0 runs each painting through a Kuwahara filter of that
# radius before the bake: each square goes flat and its edge hard, wherever the painter put it (its
# squares drift, so no one grid fits them). characters.json `bake.flatten`, or --flatten=N.
FLATTEN = 0
# Squares on him, as the painting draws them (characters.json `bake.cells`, metres: `m` on his head,
# `body_m` below it, `eye_m` round his drawn eyes): every texel of his atlas takes the one colour
# of its cell, a cube of that size in his body's axes (one for each way a surface faces, so the
# brim's top and its underside don't mix), whichever island of the atlas it lies on (a cell
# across a seam is one square on both sides). The painter's own squares are ~2 mm on his coat
# and too soft on his face to read from your seat; the painting's are ~8 mm on its man, each one
# shade, its eyes drawn finer (within EYE_REACH of each eye's outline). --cells-mm=8,9,2.7 to
# try others, --cells-mm=0 for none.
CELLS = None
EYE_REACH = 1.35
DARK_SHARE = 0.3
DARK_GAP = 30.0
# Squares averaged from the painter's fine strokes come out close in shade, where the painting's
# neighbouring squares differ (its coat is a mosaic of browns): each square's difference from the
# squares round it (the 26 cells about it facing the same way) times `cells["contrast"]` on his
# head, `body_contrast` below (1 = as averaged).
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


def head_frame(pos, htris, scale=1.0):
    """The head's centre and the frame's size (square, a little room round it), times `scale`:
    the head's `frame` in characters.json. The style model draws its squares about 8 px across
    whatever the picture shows, so the smaller his face is in the frame, the fewer squares across
    it (the Rodin stranger's at 1.0: 27; the painting's man: about 20)."""
    v = pos[np.unique(htris)]
    lo, hi = v.min(axis=0), v.max(axis=0)
    centre = (lo + hi) / 2
    return centre, float((hi - lo).max() * 1.18 * scale)


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
    centre, frame = head_frame(pos, htris, float(head.get("frame", 1.0)))
    print("%s: %d head triangles of %d, frame %.3f (%.0f mm)" % (cid, len(htris), len(tris), frame, frame * HEIGHT_M * 1000))
    # `bust`: his shoulders drawn below his head too (a head framed wider floats in an empty
    # frame otherwise; the style model learned portraits with shoulders). Only the head is baked.
    shown = tris if head.get("bust") else htris
    for view, (yaw, pitch, _w) in VIEWS.items():
        img, depth = render_view(pos, nrm, shown, centre, frame, camera(yaw, pitch), uv, colour, key=key)
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
    log = [{"editor": EDITOR, "lora_url": lora_url, "scale": scale, "seed": seed,
            "strength": STRENGTH if strength is None else strength, "strength_body": STRENGTH_BODY if strength is None else strength}]
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
            st = strength if strength is not None else (STRENGTH if kind == "head" else STRENGTH_BODY)
            img = editor(Image.open(guide), ask, lora_url, scale, seed, key, log, "%s_%s_%s" % (cid, kind, view), st)
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


def kuwahara(img, r):
    """Each pixel the mean colour of the most even (by lightness) of the four (r+1)-square windows
    it's a corner of: flat patches with hard edges between them. The filter is Kuwahara et al.'s
    (1976, "Processing of RI-angiocardiographic images"); the windows' means by summed tables."""
    h, w = img.shape[:2]
    k = r + 1
    lum = img @ np.array([0.299, 0.587, 0.114])
    p = np.pad(img, ((r, r), (r, r), (0, 0)), mode="edge")
    l = np.pad(lum, r, mode="edge")

    def box(a):
        c = np.cumsum(np.cumsum(np.pad(a, ((1, 0), (1, 0)) + ((0, 0),) * (a.ndim - 2)), axis=0), axis=1)
        return (c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]) / (k * k)

    m, ml, m2 = box(p), box(l), box(l * l)
    var = m2 - ml * ml
    starts = ((0, 0), (0, r), (r, 0), (r, r))
    vs = np.stack([var[dy:dy + h, dx:dx + w] for dy, dx in starts])
    ms = np.stack([m[dy:dy + h, dx:dx + w] for dy, dx in starts])
    return np.take_along_axis(ms, np.argmin(vs, axis=0)[None, :, :, None], axis=0)[0]


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
        if FLATTEN:
            img = kuwahara(img, FLATTEN)
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
        # The squarest view wins (weights^8): averaging views that don't register exactly
        # blurred the drawing to blobs; the painting's blocks are crisp. VIEW_POWER 0: outright.
        if VIEW_POWER:
            w = np.where(seen, facing ** VIEW_POWER, 0.0) * trust
            total += img[yi, xi] * w[:, None]
            weight += w
        else:
            w = np.where(seen, facing ** 8, 0.0) * trust
            better = w > weight
            total[better] = img[yi, xi][better]
            weight[better] = w[better]
        used.append(view)
        print("  %s %s: %.0f%% of the texels seen" % (kind, view, 100.0 * seen.mean()))
    got = weight > 1e-6
    rgb = np.zeros((len(texels), 3))
    rgb[got] = total[got] / weight[got, None] if VIEW_POWER else total[got]
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
    if colours:
        ty, tx = np.nonzero(mask)
        sheet[ty, tx] = palette(sheet[ty, tx], colours)


def face_points(cid):
    """MediaPipe's face landmarks on him (`<rodin>_face.json`, tools/characters/stylise.py, in
    load_man's frame; a stylised man's are his source's), or None."""
    spec = json.load(open(PEOPLE))["people"].get(cid, {}) if os.path.exists(PEOPLE) else {}
    names = [spec.get("rodin", cid)] + ([spec["stylise"]["from"]] if "stylise" in spec else [])
    for n in names:
        path = os.path.join(DIR, n + "_face.json")
        if os.path.exists(path):
            return np.array(json.load(open(path))["points"], dtype=np.float64)
    return None


# His eyes drawn over his texture, clearer and brighter than the painting draws them (Sean,
# 2026-10-06: "make the eyes super clear and bright - the eyes won't match the art style";
# characters.json `bake.eyes`). The painter leaves them small and dark in their sockets, and its
# own whites and lashes sit a millimetre or two off his landmarks, cut into squares. So each
# eye's socket (`clean` times the opening's size round it) is cleaned of what's much darker,
# lighter or greyer than the skin round it, and the eye is drawn texel by texel from his face's
# landmarks: the opening (MediaPipe's outline of it, `size` times as big and `open` times as
# tall) in a bright warm white, shaded under the lid and at the corners; the iris (its own
# landmarks' ring, times `iris`) with a dark rim and a darker pupil; a glint high on its side
# towards his left (your right, where the saloon shot's lamp is); a dark upper lid `lid` metres
# thick, a little past the outer corner; a lower lid in his skin's shade. Colours 0..255; `bake.eyes`
# can set any of them (`white`, `shade`, `iris_rgb`, `rim_rgb`, `pupil_rgb`, `glint_rgb`, `lid_rgb`:
# [r, g, b]) and the glint's size (`glint`, a share of the iris). Drawn at 1.2 x 1.1 as big in pure
# white they stared (Sean, 2026-10-07: "He's gone too cartoony"): the painting's eyes are clear but
# a natural almond, the iris under both lids and a sliver of warm white either side of it.
EYE_WHITE = (242, 236, 224)
EYE_WHITE_SHADE = (198, 184, 166)
EYE_IRIS = (78, 48, 28)
EYE_IRIS_RIM = (32, 19, 12)
EYE_PUPIL = (10, 7, 6)
EYE_GLINT = (255, 253, 247)
EYE_LID = (30, 18, 12)
# His skin as the game should light it (characters.json `bake.skin`): the painter lights his face
# from one side (in the pose check's even light his left cheek is L* 60, his right 48), and the
# game lights it again, so in the saloon the lit side burns (L* 69 at the top tenth, the painting's
# 45). `even`: that share of the painted light taken out of his skin (each skin texel scaled in
# linear light by its neighbourhood's lightness, SKIN_REACH round it, towards his face's own
# median times `lift`, so the squares' own mosaic stays); `hue`: degrees his skin turns towards
# yellow (ours is ~5 redder than the painting's man's); `stubble`: the grey the painter left on
# his chin and jaw warmed to that share of his skin's colour.
SKIN_REACH = 0.035
SKIN = {}   # --skin=even,hue,stubble,lift over characters.json's
EYES = {}   # --eyes=open:1.3,size:1.1,clean:1.3,lid:0.0024,iris:1.1 over characters.json's
FACE = {}   # --face=paint:0.25,lips:0.6 over characters.json's `bake.face`; --face=off, the painter's
# MediaPipe's outline of each eye (his right, his left).
EYE_OUTLINES = ([33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246],
                [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398])


def in_cells(out, cid, pos, nrm, uv, tris, size, cut, cells):
    """`out` (in place) in squares on him: CELLS. Each texel of his islands is placed on him (its
    triangle's barycentric point), its cell found (the cube it lies in, of `cells["m"]` above the
    head's cut `cut`, `body_m` below it, `eye_m` within EYE_REACH of an eye's outline, and which
    way the surface faces), and every cell given one colour: its middle texel's by lightness, or
    on his head the average of its dark ones when DARK_SHARE of it is darker than the cell by
    DARK_GAP (a brow, a moustache's edge, a dark square of the hat band keep their dark, as the
    painting's squares do)."""
    tri_id, bary = uv_raster(uv, tris, size)
    ty, tx = np.nonzero(tri_id >= 0)
    t = tris[tri_id[ty, tx]]
    b = bary[ty, tx]
    p = pos[t[:, 0]] * b[:, :1] + pos[t[:, 1]] * b[:, 1:2] + pos[t[:, 2]] * b[:, 2:3]
    n = nrm[t[:, 0]] * b[:, :1] + nrm[t[:, 1]] * b[:, 1:2] + nrm[t[:, 2]] * b[:, 2:3]
    axis = np.abs(n).argmax(axis=1)
    faces = axis * 2 + (n[np.arange(len(n)), axis] > 0)
    size_m = np.where(p[:, 1] > cut, float(cells["m"]), float(cells.get("body_m", cells["m"])))
    fine = np.zeros(len(p), dtype=bool)
    face = face_points(cid)
    if face is not None and cells.get("eye_m"):
        for outline in EYE_OUTLINES:
            ring = face[outline]
            centre = ring.mean(axis=0)
            reach = np.linalg.norm(ring - centre, axis=1).max() * EYE_REACH
            fine |= np.linalg.norm(p - centre, axis=1) < reach
        size_m[fine] = float(cells["eye_m"])
    # Thinner along the way the surface faces (`depth`, a share of the square): a tie lies a few
    # millimetres over his collar, and a cube took some of each.
    step = np.repeat(size_m[:, None], 3, axis=1)
    step[np.arange(len(p)), axis] *= float(cells.get("depth", 1.0))
    q = np.floor(p * HEIGHT_M / step).astype(np.int64)
    key = np.concatenate([q, faces[:, None], fine[:, None].astype(np.int64)], axis=1)
    _keys, lab = np.unique(key, axis=0, return_inverse=True)
    lab = lab.ravel()
    k = int(lab.max()) + 1
    rgb = out[ty, tx]
    lum = rgb @ np.array([0.299, 0.587, 0.114])
    count = np.bincount(lab, minlength=k).astype(np.float64)
    # A cell's colour is its middle texel by lightness, a colour the painter laid there: an average
    # greyed the edges between shades (a collar's white against the tie) and evened the coat's
    # browns into one.
    order = np.lexsort((lum, lab))
    start = np.concatenate([[0], np.cumsum(count.astype(np.int64))[:-1]])
    colour = rgb[order[start + count.astype(np.int64) // 2]]
    mean_l = np.bincount(lab, lum, minlength=k) / count
    dark = lum < mean_l[lab] - DARK_GAP
    dcount = np.bincount(lab, dark.astype(np.float64), minlength=k)
    dmean = np.stack([np.bincount(lab, np.where(dark, rgb[:, c], 0.0), minlength=k) for c in range(3)], axis=1)
    dmean /= np.maximum(dcount, 1.0)[:, None]
    on_head = np.bincount(lab, (p[:, 1] > cut).astype(np.float64), minlength=k) > count / 2
    # On his head only: a brow or a moustache's edge keeps its dark (on his shirt the painter's thin
    # outline strokes turned whole squares of the white collar dark).
    colour = np.where(((dcount / count >= DARK_SHARE) & on_head)[:, None], dmean, colour)
    gain = np.where(on_head, float(cells.get("contrast", 1.0)), float(cells.get("body_contrast", cells.get("contrast", 1.0))))
    if (gain != 1.0).any():
        colour = _mosaic(colour, count, _keys, gain)
    out[ty, tx] = colour[lab]
    print("  %d texels in %d squares on him (%.0f mm on his head, %.0f below, %.1f round his eyes: %d texels)" % (
        len(lab), k, cells["m"] * 1000, cells.get("body_m", cells["m"]) * 1000, cells.get("eye_m", 0) * 1000, fine.sum()))


def _mosaic(colour, count, keys, gain):
    """Each cell's colour pushed away from the mean of the cells about it (the 26 round it with the
    same facing and fineness, weighted by their texels) by `gain`, clipped to 0..255."""
    span = keys[:, :3].max(axis=0) - keys[:, :3].min(axis=0) + 3
    base = keys[:, :3] - keys[:, :3].min(axis=0) + 1
    code = lambda q, rest: ((q[:, 0] * span[1] + q[:, 1]) * span[2] + q[:, 2]) * 16 + rest
    rest = keys[:, 3] * 2 + keys[:, 4]
    own = code(base, rest)
    order = np.argsort(own)
    sorted_codes = own[order]
    total = np.zeros_like(colour)
    weight = np.zeros(len(colour))
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                if dx == dy == dz == 0:
                    continue
                c = code(base + np.array([dx, dy, dz]), rest)
                i = np.clip(np.searchsorted(sorted_codes, c), 0, len(c) - 1)
                hit = sorted_codes[i] == c
                j = order[i[hit]]
                total[hit] += colour[j] * count[j, None]
                weight[hit] += count[j]
    has = weight > 0
    around = np.where(has[:, None], total / np.maximum(weight, 1.0)[:, None], colour)
    return np.clip(around + (colour - around) * gain[:, None], 0.0, 255.0)


# MediaPipe's iris rings (centre first) and outer, inner corners of each eye (his right, his left).
IRIS_RINGS = ([468, 469, 470, 471, 472], [473, 474, 475, 476, 477])
EYE_CORNERS = ((33, 133), (263, 362))


def _inside(poly, pts):
    """Which 2D points lie inside the polygon (ray casting)."""
    x, y = pts[:, 0], pts[:, 1]
    inside = np.zeros(len(pts), dtype=bool)
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        cross = ((yi > y) != (yj > y)) & (x < (xj - xi) * (y - yi) / np.where(yj - yi == 0, 1e-12, yj - yi) + xi)
        inside ^= cross
        j = i
    return inside


def _lab(rgb):
    """sRGB 0..255 rows -> CIE Lab (D65)."""
    a = np.clip(rgb / 255.0, 0.0, 1.0)
    lin = np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)
    xyz = lin @ np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]]).T
    xyz /= np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16.0 / 116.0)
    return np.stack([116.0 * f[:, 1] - 16.0, 500.0 * (f[:, 0] - f[:, 1]), 200.0 * (f[:, 1] - f[:, 2])], axis=1)


def _rgb(lab):
    """CIE Lab rows -> sRGB 0..255."""
    fy = (lab[:, 0] + 16.0) / 116.0
    f = np.stack([fy + lab[:, 1] / 500.0, fy, fy - lab[:, 2] / 200.0], axis=1)
    xyz = np.where(f > 0.206893, f ** 3, (f - 16.0 / 116.0) / 7.787) * np.array([0.95047, 1.0, 1.08883])
    lin = xyz @ np.array([[3.2406, -1.5372, -0.4986], [-0.9689, 1.8758, 0.0415], [0.0557, -0.2040, 1.0570]]).T
    lin = np.clip(lin, 0.0, 1.0)
    return 255.0 * np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055)


def even_skin(out, cid, pos, nrm, uv, tris, size, cut, skin):
    """His head's skin in `out` (in place) as the game should light it: SKIN_REACH, `bake.skin`."""
    tri_id, bary = uv_raster(uv, tris, size)
    ty, tx = np.nonzero(tri_id >= 0)
    t = tris[tri_id[ty, tx]]
    b = bary[ty, tx]
    p = pos[t[:, 0]] * b[:, :1] + pos[t[:, 1]] * b[:, 1:2] + pos[t[:, 2]] * b[:, 2:3]
    head = p[:, 1] > cut
    ty, tx, p = ty[head], tx[head], p[head]
    rgb = out[ty, tx]
    lab = _lab(rgb)
    chroma = np.hypot(lab[:, 1], lab[:, 2])
    hue = np.degrees(np.arctan2(lab[:, 2], lab[:, 1]))
    is_skin = (chroma >= 12) & (hue > 20) & (hue < 80) & (lab[:, 0] >= 22)
    face = face_points(cid)
    if face is not None:
        # His face, ears and neck: under the top of his forehead and near his head's middle (his
        # brown hat is skin-coloured by the rest, and darkened his face towards its own).
        middle = (face[234] + face[454]) / 2
        is_skin &= (p[:, 1] < face[10][1]) & (np.hypot(p[:, 0] - middle[0], p[:, 2] - middle[2]) < 0.075)
    if is_skin.sum() < 100:
        print("  no skin found on his head")
        return
    lin = np.where(rgb / 255.0 <= 0.04045, rgb / 255.0 / 12.92, ((rgb / 255.0 + 0.055) / 1.055) ** 2.4)
    y = lin @ np.array([0.2126, 0.7152, 0.0722])
    share = float(skin.get("even", 0.0))
    if share:
        # The neighbourhood's lightness: skin texels averaged in cubes of SKIN_REACH, each texel
        # reading the 27 cubes round its own (dark hair, brows and the moustache left out).
        c = SKIN_REACH / HEIGHT_M
        q = np.floor(p / c).astype(np.int64)
        q -= q.min(axis=0) - 1
        span = q.max(axis=0) + 2
        code = lambda qq: (qq[:, 0] * span[1] + qq[:, 1]) * span[2] + qq[:, 2]
        own = code(q)
        keys, lab_id = np.unique(own[is_skin], return_inverse=True)
        tot = np.bincount(lab_id, y[is_skin])
        cnt = np.bincount(lab_id).astype(np.float64)
        near_tot = np.zeros(len(p))
        near_cnt = np.zeros(len(p))
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for dz in (-1, 0, 1):
                    cc = code(q + np.array([dx, dy, dz]))
                    i = np.clip(np.searchsorted(keys, cc), 0, len(keys) - 1)
                    hit = keys[i] == cc
                    near_tot[hit] += tot[i[hit]]
                    near_cnt[hit] += cnt[i[hit]]
        smooth = np.where(near_cnt > 0, near_tot / np.maximum(near_cnt, 1.0), y)
        # Towards his face's own lightness (between his brows and his mouth, forward of his ears),
        # so the painted light goes and his face keeps its brightness: the median of all his skin
        # (his neck and ears, under the chin and jaw, darker) dimmed his face by L* 9.
        target = float(np.median(y[is_skin]))
        if face is not None:
            cheeks = is_skin & (p[:, 1] < face[105][1]) & (p[:, 1] > face[14][1]) & (p[:, 0] > face[1][0] - 0.05)
            if cheeks.sum() > 100:
                target = float(np.median(y[cheeks]))
        target *= float(skin.get("lift", 1.0))
        factor = np.clip((target / np.maximum(smooth, 1e-4)) ** share, 0.6, 1.6)
        lin[is_skin] *= factor[is_skin, None]
        rgb = 255.0 * np.where(lin <= 0.0031308, lin * 12.92, 1.055 * np.clip(lin, 0, 1) ** (1 / 2.4) - 0.055)
        lab = _lab(rgb)
    turn = np.radians(float(skin.get("hue", 0.0)))
    if turn:
        a, bb = lab[is_skin, 1], lab[is_skin, 2]
        lab[is_skin, 1] = a * np.cos(turn) - bb * np.sin(turn)
        lab[is_skin, 2] = a * np.sin(turn) + bb * np.cos(turn)
    warm = float(skin.get("stubble", 0.0))
    stubble = np.zeros(len(p), dtype=bool)
    if warm and face is not None:
        # His chin and jaw: below his lower lip, forward of his ears, grey (little colour).
        mouth, chin = face[14], face[152]
        jaw = abs(face[234][2] - face[454][2]) / 2
        stubble = (p[:, 1] < mouth[1]) & (p[:, 1] > chin[1] - 0.012) & (np.abs(p[:, 2] - chin[2]) < jaw) & (p[:, 0] > chin[0] - 0.06)
        stubble &= (np.hypot(lab[:, 1], lab[:, 2]) < 14) & (lab[:, 0] > 15)
        skin_ab = np.median(lab[is_skin, 1:], axis=0)
        lab[stubble, 1:] = lab[stubble, 1:] * (1 - warm) + skin_ab * warm
        lab[stubble, 0] *= 0.94
    changed = is_skin | stubble
    out[ty[changed], tx[changed]] = _rgb(lab[changed])
    print("  his skin: %d texels, painted light %.0f%% taken out, turned %+.0f deg, %d texels of stubble warmed" % (
        is_skin.sum(), share * 100, np.degrees(turn), stubble.sum()))


# His face from his model's own colours (characters.json `bake.face`; Sean, 2026-10-07: "He's gone
# too cartoony ... It's the face the most - it's just not the right style"). The painter (the style
# model, image to image) redraws a face in a manner of its own, flat black brows, a solid black
# moustache and a grey muzzle: a game portrait, where the painting's man is a realistic face cut
# into squares. So all of his head under his hat takes the colours of his model as made (`from`: a
# glb in assets/people/tripo with the same UVs; Rodin's realistic face), graded to the painter's
# skin (the mean and spread of L*, a* and b* over the skin in both), its lips (redder than his skin,
# round his mouth) pulled `lips` of the way to his skin, its colour times `chroma`, and `paint` of
# the painter's colours mixed back in; his hat, collar and body keep the painter's. Under his hat:
# below `above` metres over his eyes, down to `below` under them, within `radius` of his head's
# upright axis (`back` behind his eyes; the brim stands further out), the edges eased over a
# centimetre or two.
FACE_REGION = {"above": 0.045, "below": 0.13, "radius": 0.105, "back": 0.085}


def model_face(out, cid, pos, uv, tris, size, cfg):
    """His head under his hat in `out` (in place) from his model's own colours: `bake.face`."""
    face = face_points(cid)
    if face is None:
        print("  no face found: the painter's face kept")
        return
    src = load_glb(os.path.join(DIR, cfg["from"] + ".glb"))
    if len(src[2]) != len(uv) or not np.allclose(src[2], uv):
        raise SystemExit("bake.face: %s hasn't his UVs" % cfg["from"])
    model = np.asarray(src[4].resize((size, size), Image.LANCZOS), dtype=np.float64)
    o = dict(FACE_REGION, **cfg)
    tri_id, bary = uv_raster(uv, tris, size)
    ty, tx = np.nonzero(tri_id >= 0)
    t = tris[tri_id[ty, tx]]
    b = bary[ty, tx]
    p = pos[t[:, 0]] * b[:, :1] + pos[t[:, 1]] * b[:, 1:2] + pos[t[:, 2]] * b[:, 2:3]
    eye = np.mean([face[r[0]] for r in IRIS_RINGS], axis=0)

    def ease(x, edge, feather):
        s = np.clip((edge - x) / feather, 0.0, 1.0)
        return s * s * (3 - 2 * s)

    r = np.hypot(p[:, 0] - (eye[0] - o["back"] / HEIGHT_M), p[:, 2] - eye[2]) * HEIGHT_M
    w = (ease(r, o["radius"], 0.01) * ease((p[:, 1] - eye[1]) * HEIGHT_M, o["above"], 0.01)
         * ease((eye[1] - p[:, 1]) * HEIGHT_M, o["below"], 0.02))
    keep = w > 0
    ty, tx, p, w = ty[keep], tx[keep], p[keep], w[keep]
    painted, own = _lab(out[ty, tx]), _lab(model[ty, tx])

    def skin(lab):
        return (w > 0.5) & (lab[:, 0] > 35) & (np.hypot(lab[:, 1], lab[:, 2]) > 10)

    sp, so = skin(painted), skin(own)
    for k in range(3):
        spread = painted[sp, k].std() / max(own[so, k].std(), 1e-6)
        own[:, k] = painted[sp, k].mean() + (own[:, k] - own[so, k].mean()) * spread
    lips = float(o.get("lips", 0.0))
    if lips:
        mouth = ((np.abs(p[:, 2] - eye[2]) * HEIGHT_M < 0.035) & ((eye[1] - p[:, 1]) * HEIGHT_M > 0.05)
                 & ((eye[1] - p[:, 1]) * HEIGHT_M < 0.10) & ((p[:, 0] - eye[0]) * HEIGHT_M > -0.01))
        sk = skin(own)
        a0, b0 = own[sk, 1].mean(), own[sk, 2].mean()
        red = mouth & (own[:, 1] > a0 + 2.0)
        own[red, 1] += (a0 - own[red, 1]) * lips
        own[red, 2] += (b0 - own[red, 2]) * lips * 0.5
        own[red, 0] *= 1.0 - 0.15 * lips
    own[:, 1:] *= float(o.get("chroma", 1.0))
    share = float(o.get("paint", 0.0))
    lab = own * (1 - share) + painted * share
    out[ty, tx] = out[ty, tx] * (1 - w[:, None]) + _rgb(lab) * w[:, None]
    print("  his head under the hat from %s: %d texels, graded to the painter's skin, %.0f%% of the painter's kept" % (
        cfg["from"], keep.sum(), share * 100))


def draw_eyes(out, cid, pos, nrm, uv, tris, size, eyes):
    """His eyes drawn over `out` (in place): EYE_WHITE and friends, from his face's landmarks."""
    face = face_points(cid)
    if face is None:
        print("  no face found: eyes left as painted")
        return
    tri_id, bary = uv_raster(uv, tris, size)
    ty, tx = np.nonzero(tri_id >= 0)
    t = tris[tri_id[ty, tx]]
    b = bary[ty, tx]
    p = pos[t[:, 0]] * b[:, :1] + pos[t[:, 1]] * b[:, 1:2] + pos[t[:, 2]] * b[:, 2:3]
    n = nrm[t[:, 0]] * b[:, :1] + nrm[t[:, 1]] * b[:, 1:2] + nrm[t[:, 2]] * b[:, 2:3]
    fwd = np.array([1.0, 0.0, 0.0])          # Tripo's frame: he faces +X, his right +Z, up +Y
    opening = float(eyes.get("open", 1.0))
    grow = float(eyes.get("size", 1.0))
    clean = float(eyes.get("clean", 0.0))
    lid_w = float(eyes.get("lid", 0.0012)) / HEIGHT_M
    drawn = cleaned = 0

    def col(key, default):
        # A colour from `eyes` (characters.json `bake.eyes`: "white": [r, g, b], ...), else the default.
        return tuple(eyes[key]) if key in eyes else default

    glint_r = float(eyes.get("glint", 0.34))
    for outline, ring, (outer, inner) in zip(EYE_OUTLINES, IRIS_RINGS, EYE_CORNERS):
        c = face[ring[0]]
        u = face[outer] - face[inner]
        u -= fwd * (u @ fwd)
        u /= np.linalg.norm(u)
        if u[2] < 0:
            u = -u                            # towards his right on both eyes, so the glints agree
        v = np.cross(u, fwd)
        v /= np.linalg.norm(v)
        if v[1] < 0:
            v = -v
        flat = lambda q: np.stack([(q - c) @ u, (q - c) @ v], axis=-1)
        poly = flat(face[outline])
        mid = poly.mean(axis=0)
        poly = mid + (poly - mid) * np.array([grow, grow * opening])
        half = np.abs(poly - mid).max(axis=0)          # half the opening's width and height
        centre = mid * (1.0 - grow)                    # the iris, moved with the eye as it grows
        r_iris = np.linalg.norm(flat(face[ring[1:]]), axis=1).mean() * float(eyes.get("iris", 1.0)) * grow
        reach = half.max() * max(2.0, clean * 1.6)
        near = (np.linalg.norm(p - c, axis=1) < reach) & (np.abs((p - c) @ fwd) < reach) & (n @ fwd > 0.15)
        idx = np.nonzero(near)[0]
        q = flat(p[near])
        white = _inside(poly, q)
        lower_colour = np.array(EYE_LID) * 2.0
        if clean:
            # The socket: an ellipse round the opening, `clean` times its half-width across and
            # twice that up and down. What in it is much lighter or greyer than its skin (the
            # painter's whites off ours) goes, and near the opening (half as far up and down) what
            # is much darker too (its lashes, cut into squares); further up the dark of his
            # brow's shadow stays. They take the colour of the socket's own skin.
            e = (q - mid) / (half * np.array([clean, clean * 2.0]))
            rr = np.hypot(e[:, 0], e[:, 1])
            socket = (rr < 1.0) & ~white
            close = np.hypot(e[:, 0], e[:, 1] * 2.0) < 1.0
            lab = _lab(out[ty[idx], tx[idx]])
            chroma = np.hypot(lab[:, 1], lab[:, 2])
            skin = socket & (chroma >= 12) & (lab[:, 0] > 20)
            if skin.sum() > 10:
                ref = np.median(lab[skin], axis=0)
                odd = socket & ((lab[:, 0] > ref[0] + 12) | (chroma < 10) | (close & (lab[:, 0] < ref[0] - 16)))
                out[ty[idx[odd]], tx[idx[odd]]] = _rgb(ref[None, :])[0]
                cleaned += int(odd.sum())
                lower_colour = _rgb((ref * np.array([0.72, 1.0, 1.0]))[None, :])[0]
        d = np.linalg.norm(q - centre, axis=1)
        shade = white & (~_inside(poly - np.array([0.0, lid_w * 0.8]), q) | (np.abs(q[:, 0] - mid[0]) > half[0] * 0.78))
        iris = white & (d < r_iris)
        rim = iris & (d > r_iris * 0.78)
        pupil = white & (d < r_iris * 0.42)
        glint = white & (np.linalg.norm(q - centre - np.array([-0.36, 0.4]) * r_iris, axis=1) < r_iris * glint_r)
        wide = mid + (poly - mid) * np.array([1.08, 1.0])
        upper = _inside(wide + np.array([0.0, lid_w]), q) & ~white & (q[:, 1] > mid[1] - half[1] * 0.3)
        lower = _inside(poly - np.array([0.0, lid_w * 0.6]), q) & ~white & ~upper & (q[:, 1] < mid[1])
        for mask, colour in ((lower, lower_colour), (white, col("white", EYE_WHITE)), (shade, col("shade", EYE_WHITE_SHADE)),
                             (iris, col("iris_rgb", EYE_IRIS)), (rim, col("rim_rgb", EYE_IRIS_RIM)),
                             (pupil, col("pupil_rgb", EYE_PUPIL)), (glint, col("glint_rgb", EYE_GLINT)),
                             (upper, col("lid_rgb", EYE_LID))):
            out[ty[idx[mask]], tx[idx[mask]]] = colour
        drawn += int(white.sum())
        print("  eye: opening %.1f x %.1f mm, iris %.1f mm across, %d texels of white" % (
            half[0] * 2 * HEIGHT_M * 1000, half[1] * 2 * HEIGHT_M * 1000, r_iris * 2 * HEIGHT_M * 1000, white.sum()))
    print("  eyes drawn: %d texels of white, opened x%.2f, x%.2f as big, %d texels of the painter's eyes cleaned" % (
        drawn, opening, grow, cleaned))


def bake(cid):
    from scipy import ndimage
    pos, nrm, uv, tris, colour = load_man(cid)
    head = head_spec(cid)[0]
    # A character whose bake keeps the painter's own squares (characters.json `bake`: {"squares":
    # false}): no squares of ours over them and no palette, as --smooth, written as his texture.
    # The Rodin stranger's: our squares over the painter's misaligned them, and the palette cut
    # his face into flat bands (2026-10-06).
    bk = json.load(open(SPEC))["characters"].get(cid, {}).get("bake", {})
    plain = SMOOTH or not bk.get("squares", True)
    # characters.json's `bake.flatten` and `bake.view_power`, unless the command line says.
    global FLATTEN, VIEW_POWER
    if not any(a.startswith("--flatten=") for a in sys.argv):
        FLATTEN = int(bk.get("flatten", FLATTEN))
    if not any(a.startswith("--view-power=") for a in sys.argv):
        VIEW_POWER = int(bk.get("view_power", VIEW_POWER))
    print("bake: flatten %d, view power %d%s" % (FLATTEN, VIEW_POWER, ", plain" if plain else ""))
    htris = head_triangles(pos, tris, head.get("cut"))
    size = min(colour.width, BAKE_MAX)
    base = colour if colour.width == size else colour.resize((size, size), Image.LANCZOS)
    out = np.asarray(base, dtype=np.float64).copy()
    centre, frame = head_frame(pos, htris, float(head.get("frame", 1.0)))
    ty, tx, rgb, got, used = project(cid, "head", VIEWS, pos, nrm, uv, htris, tris if head.get("bust") else htris,
                                     centre, frame, size, GUIDE_PX)
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
    if not plain:
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
            if not plain:
                in_squares(sheet, bmask, pos, uv, btris, size, SQUARE_M_BODY, COLOURS_BODY, "body")
            out[bmask] = sheet[bmask]
            used += ["body " + v for v in bused]
            print("  %.0f%% of the body's texels painted" % (100.0 * bgot.mean()))
    y0, y1 = pos[:, 1].min(), pos[:, 1].max()
    cut = y0 + (y1 - y0) * (HEAD_FROM if head.get("cut") is None else head["cut"])
    skin = dict(bk.get("skin") or {}, **SKIN)
    if skin and not SMOOTH:
        even_skin(out, cid, pos, nrm, uv, tris, size, cut, skin)
    face = dict(bk.get("face") or {}, **FACE) if FACE is not None else {}
    if face.get("from") and not SMOOTH:
        model_face(out, cid, pos, uv, tris, size, face)
    cells = dict(bk.get("cells") or {}, **(CELLS or {})) if CELLS != {} else None
    if cells and cells.get("m") and not SMOOTH:
        in_cells(out, cid, pos, nrm, uv, tris, size, cut, cells)
    eyes = dict(bk.get("eyes") or {}, **EYES) if EYES is not None else {}
    if eyes and not SMOOTH:
        draw_eyes(out, cid, pos, nrm, uv, tris, size, eyes)
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
    global SMOOTH, SQUARE_M, SQUARE_M_BODY, COLOURS, COLOURS_BODY, VIEW_POWER, FLATTEN, CELLS, SKIN, EYES, FACE
    SMOOTH = "--smooth" in sys.argv
    step = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else ""
    cid, scale, seed, only, strength = "stranger", 1.0, 7, None, None
    for a in sys.argv[2:]:
        # The bake's squares and palettes, to try others: --square-mm=7 --square-body-mm=10
        # --colours=0 (no palette: each square its own shade) --colours-body=0, how views mix
        # where they overlap: --view-power=8, 0 (the squarest view outright), and --flatten=2 (the
        # paintings' squares made flat and hard-edged first); these two override characters.json
        if a.startswith("--square-mm="):
            SQUARE_M = float(a.split("=", 1)[1]) / 1000.0
        elif a.startswith("--square-body-mm="):
            SQUARE_M_BODY = float(a.split("=", 1)[1]) / 1000.0
        elif a.startswith("--colours="):
            COLOURS = int(a.split("=", 1)[1])
        elif a.startswith("--colours-body="):
            COLOURS_BODY = int(a.split("=", 1)[1])
        elif a.startswith("--view-power="):
            VIEW_POWER = int(a.split("=", 1)[1])
        elif a.startswith("--flatten="):
            FLATTEN = int(a.split("=", 1)[1])
        elif a.startswith("--cells-mm="):
            # Head, body, eyes in millimetres (CELLS): --cells-mm=8,9,2.7; 0 for none.
            mm = [float(x) for x in a.split("=", 1)[1].split(",")]
            CELLS = {} if not mm[0] else dict(CELLS or {}, m=mm[0] / 1000.0, body_m=(mm[1] if len(mm) > 1 else mm[0]) / 1000.0,
                                              eye_m=(mm[2] if len(mm) > 2 else 0.0) / 1000.0)
        elif a.startswith("--skin="):
            # His skin as the game should light it (SKIN_REACH): --skin=0.6,4,0.7,1 (even, hue,
            # stubble, lift)
            v = [float(x) for x in a.split("=", 1)[1].split(",")]
            SKIN = dict(zip(("even", "hue", "stubble", "lift"), v))
        elif a == "--eyes=off":
            # The painter's eyes as painted (nothing drawn over them).
            EYES = None
        elif a == "--face=off":
            # The painter's face as painted (`bake.face` left out).
            FACE = None
        elif a.startswith("--face="):
            # His face from his model's own colours (model_face): --face=paint:0.25,lips:0.6
            FACE = {k: (x if k == "from" else float(x))
                    for k, x in (kv.split(":") for kv in a.split("=", 1)[1].split(","))}
        elif a.startswith("--eyes="):
            # How his eyes are drawn (draw_eyes): --eyes=open:1.3,size:1.1,clean:1.3,lid:0.0024
            # (a colour as r/g/b: white:222/206/186)
            EYES = {k: (tuple(float(c) for c in x.split("/")) if "/" in x else float(x))
                    for k, x in (kv.split(":") for kv in a.split("=", 1)[1].split(","))}
        elif a.startswith("--cells-depth="):
            # The squares' depth along the way the surface faces, a share of their size: 0.5
            CELLS = dict(CELLS or {}, depth=float(a.split("=", 1)[1]))
        elif a.startswith("--cells-contrast="):
            # The squares' contrast with those round them, head and body: --cells-contrast=1.2,1.6
            g = [float(x) for x in a.split("=", 1)[1].split(",")]
            CELLS = dict(CELLS or {}, contrast=g[0], body_contrast=g[1] if len(g) > 1 else g[0])
        elif a.startswith("--id="):
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
