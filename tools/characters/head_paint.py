#!/usr/bin/env python3
"""The Tripo man's head painted in the style, texel by texel onto his own texture.

    python3 tools/characters/head_paint.py guides [--id=stranger]      (numpy only: clay views of his head)
    FAL_KEY=... python3 tools/characters/head_paint.py paint [--scale=1.0] [--seed=7] [--repaint] [--only=front,left]
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
EDITOR = os.environ.get("FAL_EDITOR") or "fal-ai/flux-kontext-lora"
QUEUE = "https://queue.fal.run/"

GUIDE_PX = 768
# The head: everything above this share of his height (the collar's top; chin ~0.86, hat ~1.0).
HEAD_FROM = 0.815
# He stands 1.0 tall in the glb; in the game he's this tall (tools/tripo_lab.gd --height).
HEIGHT_M = 1.8
# The painting's face squares are ~5 mm on him (190 a metre, tools/paint/finish.py).
SQUARE_M = 0.0053
COLOURS = 28
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
# Tripo's man faces +X with Y up.
FORWARD = np.array([1.0, 0.0, 0.0])
UP = np.array([0.0, 1.0, 0.0])

ASK = (
    "SLTCRK. This is a grey clay sculpture of a man's head and hat. Paint it as a finished picture "
    "of {what}: the same head at exactly the same angle, size and framing, every feature exactly "
    "where the clay has it (eyes, nose, mouth, moustache, hat brim and crown, hair), nothing moved "
    "or resized. Weathered sun-darkened skin, deep-set dark eyes looking at the viewer, heavy dark "
    "brows, a thick dark drooping moustache, stubble, long dark hair to his collar under a dark "
    "brown wide-brimmed hat with a studded band. Warm oil-lamp light from the front, the background "
    "a plain dark brown. Crisp square pixels, the picture's own pixel-art mosaic."
)


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


def head_triangles(pos, tris):
    """The triangles of his head: all three corners above HEAD_FROM of his height."""
    y0, y1 = pos[:, 1].min(), pos[:, 1].max()
    cut = y0 + (y1 - y0) * HEAD_FROM
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


def to_view(p, centre, frame, r, u, f):
    """Points -> (x px, y px, depth) in a view; depth grows away from the camera."""
    d = p - centre
    x = (d @ r / frame + 0.5) * GUIDE_PX
    y = (0.5 - d @ u / frame) * GUIDE_PX
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


def render_view(pos, nrm, htris, centre, frame, cam):
    """A clay render of the head from a view (grey Lambert, a key light up and to the camera's
    left, a dark ground) and its depth buffer (inf where nothing is)."""
    r, u, f = cam
    x, y, z = to_view(pos, centre, frame, r, u, f)
    depth = np.full((GUIDE_PX, GUIDE_PX), np.inf)
    shade = np.zeros((GUIDE_PX, GUIDE_PX))
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
        shade[py, px] = 0.16 + 0.62 * (a * lit[t[0]] + b * lit[t[1]] + c * lit[t[2]]) + 0.14 * (a * fill[t[0]] + b * fill[t[1]] + c * fill[t[2]])
    img = np.full((GUIDE_PX, GUIDE_PX, 3), 34.0)
    seen = np.isfinite(depth)
    g = np.clip(shade[seen], 0, 1) * 255
    img[seen] = np.stack([g, g, g * 0.97], axis=1)
    return Image.fromarray(img.astype(np.uint8)), depth


def guides(cid):
    pos, nrm, uv, tris, colour = load_glb(os.path.join(DIR, cid + ".glb"))
    htris = head_triangles(pos, tris)
    centre, frame = head_frame(pos, htris)
    print("%s: %d head triangles of %d, frame %.3f (%.0f mm)" % (cid, len(htris), len(tris), frame, frame * HEIGHT_M * 1000))
    for view, (yaw, pitch, _w) in VIEWS.items():
        img, depth = render_view(pos, nrm, htris, centre, frame, camera(yaw, pitch))
        img.save(os.path.join(DIR, "%s_head_%s_guide.png" % (cid, view)))
        print("  guide:", view)


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


def edit(img, prompt, lora_url, scale, seed, key, log, what):
    body = {"image_url": data_url(img), "prompt": prompt, "num_inference_steps": 30, "guidance_scale": 2.5,
            "num_images": 1, "seed": seed, "output_format": "png", "enable_safety_checker": False,
            "resolution_mode": "match_input", "loras": [{"path": lora_url, "scale": scale}] if scale > 0 else []}
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


def paint(cid, key, scale, seed, repaint, only, editor=edit, out_dir=None):
    out_dir = out_dir or DIR
    what = json.load(open(SPEC))["characters"].get(cid, {}).get("what", "a weathered frontier gunman")
    lora_url = json.load(open(LORA))["lora_url"] if os.path.exists(LORA) else ""
    if not lora_url:
        print("No %s: the LoRA isn't trained; painting without it." % LORA)
        scale = 0.0
    os.makedirs(BUILD, exist_ok=True)
    log = [{"editor": EDITOR, "lora_url": lora_url, "scale": scale, "seed": seed}]
    failed = []
    for view in VIEWS:
        if only and view not in only:
            continue
        out = os.path.join(out_dir, "%s_head_%s_painted.png" % (cid, view))
        if os.path.exists(out) and not repaint:
            print("already painted:", view)
            continue
        guide = os.path.join(DIR, "%s_head_%s_guide.png" % (cid, view))
        if not os.path.exists(guide):
            print("no guide for", view, "(run `guides` first)")
            failed.append(view)
            continue
        try:
            img = editor(Image.open(guide), ASK.format(what=what), lora_url, scale, seed, key, log, "%s_head_%s" % (cid, view))
            if img.size != (GUIDE_PX, GUIDE_PX):
                img = img.resize((GUIDE_PX, GUIDE_PX), Image.LANCZOS)
            img.save(out)
            print("painted:", view, img.size)
        except (RuntimeError, OSError, KeyError, ValueError) as e:
            print("failed:", view, e)
            failed.append(view)
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


def bake(cid):
    pos, nrm, uv, tris, colour = load_glb(os.path.join(DIR, cid + ".glb"))
    htris = head_triangles(pos, tris)
    centre, frame = head_frame(pos, htris)
    size = colour.width
    tri_id, bary = uv_raster(uv, htris, size)
    texels = np.argwhere(tri_id >= 0)
    ty, tx = texels[:, 0], texels[:, 1]
    t = htris[tri_id[ty, tx]]
    b = bary[ty, tx]
    p = (pos[t[:, 0]] * b[:, :1] + pos[t[:, 1]] * b[:, 1:2] + pos[t[:, 2]] * b[:, 2:3])
    n = (nrm[t[:, 0]] * b[:, :1] + nrm[t[:, 1]] * b[:, 1:2] + nrm[t[:, 2]] * b[:, 2:3])
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)
    print("%s: %d head texels of %d^2" % (cid, len(texels), size))
    total = np.zeros((len(texels), 3))
    weight = np.zeros(len(texels))
    tolerance = frame * 0.012
    used = []
    for view, (yaw, pitch, trust) in VIEWS.items():
        painted = os.path.join(DIR, "%s_head_%s_painted.png" % (cid, view))
        if not os.path.exists(painted):
            print("  no painting for", view)
            continue
        img = np.asarray(Image.open(painted).convert("RGB").resize((GUIDE_PX, GUIDE_PX), Image.LANCZOS), dtype=np.float64)
        cam = camera(yaw, pitch)
        _guide, depth = render_view(pos, nrm, htris, centre, frame, cam)   # the view's depth, as the guide saw it
        r, u, f = cam
        x, y, z = to_view(p, centre, frame, r, u, f)
        xi = np.clip(np.floor(x).astype(int), 0, GUIDE_PX - 1)
        yi = np.clip(np.floor(y).astype(int), 0, GUIDE_PX - 1)
        inside = (x >= 0) & (x < GUIDE_PX) & (y >= 0) & (y < GUIDE_PX)
        # Seen: at the front of what the view's depth buffer holds there (loosened to the farthest
        # of the 3x3 round it, so a texel a pixel off an edge still counts).
        d3 = depth.copy()
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                d3 = np.maximum(d3, np.roll(np.roll(depth, dy, axis=0), dx, axis=1))
        seen = inside & (z <= d3[yi, xi] + tolerance)
        facing = np.clip(n @ (-f), 0.0, 1.0)
        w = np.where(seen, facing ** 3, 0.0) * trust
        total += img[yi, xi] * w[:, None]
        weight += w
        used.append(view)
        print("  %s: %.0f%% of the head's texels seen" % (view, 100.0 * seen.mean()))
    if not used:
        print("nothing painted yet (run `paint`)")
        sys.exit(1)
    got = weight > 1e-6
    rgb = np.zeros((len(texels), 3))
    rgb[got] = total[got] / weight[got, None]
    # Fill what no view saw from the nearest texel that was (in UV space).
    from scipy import ndimage
    head = np.zeros((size, size), dtype=bool)
    head[ty, tx] = True
    known = np.zeros((size, size), dtype=bool)
    known[ty[got], tx[got]] = True
    sheet = np.zeros((size, size, 3))
    sheet[ty, tx] = rgb
    _d, (iy, ix) = ndimage.distance_transform_edt(~known, return_indices=True)
    sheet = sheet[iy, ix]
    # Squares of a set size on him: texels a metre from the head's UV area against its true area.
    a3 = 0.5 * np.linalg.norm(np.cross(pos[htris[:, 1]] - pos[htris[:, 0]], pos[htris[:, 2]] - pos[htris[:, 0]]), axis=1).sum() * HEIGHT_M ** 2
    e1, e2 = uv[htris[:, 1]] - uv[htris[:, 0]], uv[htris[:, 2]] - uv[htris[:, 0]]
    a2 = 0.5 * np.abs(e1[:, 0] * e2[:, 1] - e1[:, 1] * e2[:, 0]).sum() * size ** 2
    texels_per_m = np.sqrt(a2 / a3)
    sq = max(1, int(round(SQUARE_M * texels_per_m)))
    print("  %.0f texels a metre on the head; squares of %d texels" % (texels_per_m, sq))
    if sq > 1:
        hs = (size // sq) * sq
        block = sheet[:hs, :hs].reshape(hs // sq, sq, hs // sq, sq, 3)
        count = head[:hs, :hs].reshape(hs // sq, sq, hs // sq, sq).astype(np.float64)
        mean = (block * count[..., None]).sum(axis=(1, 3)) / np.maximum(count.sum(axis=(1, 3)), 1)[..., None]
        squared = np.repeat(np.repeat(mean, sq, axis=0), sq, axis=1)
        inside = np.repeat(np.repeat(count.sum(axis=(1, 3)) > 0, sq, axis=0), sq, axis=1)
        sheet[:hs, :hs][inside] = squared[inside]
    # A palette for the head.
    flat = sheet[ty, tx]
    sheet[ty, tx] = palette(flat, COLOURS)
    out = np.asarray(colour, dtype=np.float64).copy()
    out[ty, tx] = sheet[ty, tx]
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(os.path.join(DIR, cid + "_color.png"))
    print("wrote", os.path.join(DIR, cid + "_color.png"), "from", ", ".join(used))
    contact(cid)


def contact(cid, cell=384):
    """Guides over paintings, a view a column: docs/screenshots/tripo/<id>_head_views.png."""
    os.makedirs(SHOTS, exist_ok=True)
    cols = []
    for view in VIEWS:
        g = os.path.join(DIR, "%s_head_%s_guide.png" % (cid, view))
        p = os.path.join(DIR, "%s_head_%s_painted.png" % (cid, view))
        if not os.path.exists(g):
            continue
        col = Image.new("RGB", (cell, cell * 2 + 18), (28, 28, 28))
        col.paste(Image.open(g).convert("RGB").resize((cell, cell), Image.LANCZOS), (0, 18))
        if os.path.exists(p):
            col.paste(Image.open(p).convert("RGB").resize((cell, cell), Image.NEAREST), (0, cell + 18))
        ImageDraw.Draw(col).text((4, 3), view, fill=(255, 255, 255))
        cols.append(col)
    if not cols:
        return
    sheet = Image.new("RGB", (len(cols) * (cell + 4), cell * 2 + 18), (28, 28, 28))
    for i, c in enumerate(cols):
        sheet.paste(c, (i * (cell + 4), 0))
    sheet.save(os.path.join(SHOTS, cid + "_head_views.png"))


def dry_run(cid):
    """The paint step on a stand-in editor (flat pictures with the guide's shape), into a scratch folder."""
    import tempfile
    scratch = tempfile.mkdtemp(prefix="head_dry_")

    def standin(img, prompt, lora_url, scale, seed, key, log, what):
        if "SLTCRK" not in prompt or "pixel" not in prompt:
            raise RuntimeError("the ask lost its trigger word or its pixels: " + what)
        a = np.asarray(img.convert("RGB"), dtype=np.float64)
        a[..., 0] *= 1.2
        a[..., 2] *= 0.6
        return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))

    paint(cid, "dry-run-key", 1.0, 7, True, None, standin, scratch)
    for view in VIEWS:
        if not os.path.exists(os.path.join(scratch, "%s_head_%s_painted.png" % (cid, view))):
            print("dry run FAILED: no", view)
            sys.exit(1)
    print("dry run passed:", scratch)


def main():
    step = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else ""
    cid, scale, seed, only = "stranger", 1.0, 7, None
    for a in sys.argv[2:]:
        if a.startswith("--id="):
            cid = a.split("=", 1)[1]
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
        paint(cid, key, scale, seed, "--repaint" in sys.argv, only)
    elif step == "bake":
        bake(cid)
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main()
