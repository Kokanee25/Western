"""The UV portrait, step 3: painting the head's patches (docs/briefs/uv-portrait.md; Sean, 2026-10-13).

    python3 tools/characters/uv_paint.py guides --man=bold_cowboy           # here (bpy for the factory man)
    FAL_KEY=... python3 tools/characters/uv_paint.py paint --man=bold_cowboy [--round=1]   # People workflow `style: uvpaint`
    python3 tools/characters/uv_paint.py paint --man=bold_cowboy --dry-run  # the requests, written not sent
    python3 tools/characters/uv_paint.py apply --man=bold_cowboy --take=NAME   # here: onto him, squared

Each patch of uv_layout.py's layout is seen by its own camera, so a picture made from that camera
IS the patch: no projection between views, no blending of views, one painting per patch.

1. guides: from each painted view's camera (face: the front; right, left: each side, with its
   ear; back), the whole head drawn into DIR = docs/style_test/uv/<man>/: its depth (near
   white: the ControlNet's), its normals, and the start picture: the head in even light, soft
   colour where things are (skin; brows, the moustache's place, the lips and eyes from his
   landmarks; hair above his hairline and at his temples, grey at the sides as the bold
   portrait has it; red on the nose, cheeks and ears; blue-grey stubble on the jaw). The image
   model repaints it all; the start picture only says where.
2. paint (fal, FLUX [dev] image-to-image with the style LoRA, depth ControlNet from the same
   camera, optionally his style portrait for that side as an IP-Adapter reference): ROUNDS lists
   the takes. A request fal turns down (422) costs nothing: the next way of asking for the
   ControlNet is tried and the answer logged (DIR/paint/fal_log.json).
3. apply: each patch's texels take the take's painting at their own point (the same camera), the
   start picture's light divided out (DELIGHT of the way: the game lights him), the patches' seams
   matched in low-frequency colour only (the face never moves), the crown and throat (under the
   hat and collar) filled from their nearest painted neighbours on him, then squares once: an
   SQUARE grid in each patch's own camera plane, each cell the median of its texels; cells
   smoothed across their neighbours where they're alike (not across edges) and lone cells that
   differ from every neighbour pulled to them, so squares group into shapes. Every square keeps
   its own shade; no palette. → build/uv_head/<man>_<take>_tex.png, and uv_head.py build puts it
   on him (--build).
"""
import json
import os
import sys
import time

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.dirname(os.path.dirname(HERE))
WORK = os.path.join(ROOT, "build", "uv_head")
DIR = os.path.join(ROOT, "docs", "style_test", "uv", "%s")
LORA = os.path.join(ROOT, "tools", "style", "style_lora.json")
QUEUE = "https://queue.fal.run/"
APP = "fal-ai/flux-general/image-to-image"
PAINTED = ("face", "right", "left", "back")
# Each painted view: the patches it paints, its picture's size (under a megapixel: fal bills by the
# megapixel, rounded up), and his style portrait for that side.
SIZE = {"face": (768, 1152), "right": (896, 1024), "left": (896, 1024), "back": (768, 1024)}
PATCHES = {"face": ("face",), "right": ("right", "ear_r"), "left": ("left", "ear_l"), "back": ("back",)}
STYLE = {"face": "portrait-cowboy-front.png", "right": "portrait-cowboy-profile-right.png",
         "left": "portrait-cowboy-profile.png", "back": "portrait-cowboy-from-behind.png"}
MARGIN = 0.12         # the frame round a patch, of its size
SEEN = {"face": "seen from straight in front, his face filling the picture",
        "right": "seen in full profile facing right, his ear in the middle of the picture",
        "left": "seen in full profile facing left, his ear in the middle of the picture",
        "back": "seen from straight behind, the back of his head filling the picture"}
ASK = ("SLTCRK pixel-art painting, close {what} of a weathered cowboy's bare head, {seen}, no hat, "
       "{hair}{face}flat even light from the front, no cast shadows, plain grey background, the same "
       "head shape and features as the picture, painted in many small shades of colour")
FACE_WORDS = ("peach and cream skin where the light falls, a ruddy red nose, red cheeks and ears, "
              "blue-grey stubble on his jaw and chin, olive-grey in the hollows under his brow and "
              "cheekbones, a heavy dark drooping moustache, thick dark eyebrows, brown eyes, ")
HAIR_WORDS = "thick dark brown hair swept back, grey at the temples and over the ears, "
# The takes, a round at a time: (name, LoRA scale, strength, ControlNet scale, IP-Adapter scale, seed).
ROUNDS = {
    1: [("a", 0.8, 0.82, 0.6, 0.0, 11), ("b", 1.0, 0.88, 0.6, 0.0, 12), ("c", 0.8, 0.82, 0.6, 0.5, 11)],
}
# The ways of asking flux-general for a depth ControlNet, tried in order on a 422.
CONTROL = [
    lambda url, s: {"controlnet_unions": [{"path": "InstantX/FLUX.1-dev-Controlnet-Union", "controls": [
        {"control_image_url": url, "control_mode": "depth", "conditioning_scale": s}]}]},
    lambda url, s: {"controlnets": [{"path": "Shakker-Labs/FLUX.1-dev-ControlNet-Depth",
                                     "control_image_url": url, "conditioning_scale": s}]},
    lambda url, s: {},
]
IP_ADAPTER = {"path": "XLabs-AI/flux-ip-adapter", "image_encoder_path": "openai/clip-vit-large-patch14"}
DELIGHT = 0.7
SQUARE = 0.008
LIKE = 0.10           # cells nearer than this (RGB distance) are smoothed together
LONE = 0.16           # a cell further than this from every neighbour, its neighbours agreeing, is pulled in
SEAM_SIGMA = 0.03     # metres: how far a seam's colour match reaches into the side patches


# --- Shared -------------------------------------------------------------------------------------------

def load(man):
    import uv_layout as L
    z = np.load(os.path.join(WORK, man + "_layout.npz"), allow_pickle=True)
    rep = json.load(open(os.path.join(WORK, man + "_layout.json")))
    shape = np.load(os.path.join(WORK, man + "_shape.npz"))
    faces = [list(map(int, f)) for f in z["faces"]]
    return L, z["v"], faces, list(z["label"]), rep, shape["lm"]


def frame(L, view, v, faces, label):
    """A view's picture: metres → pixels (x0, y0, s) framing its patches with MARGIN round them."""
    ids = sorted({i for k, f in enumerate(faces) if label[k] in PATCHES[view] for i in f})
    xy = L.project(view, v[ids])
    lo, hi = xy.min(0), xy.max(0)
    W, H = SIZE[view]
    span = (hi - lo) * (1 + 2 * MARGIN)
    s = min(W / span[0], H / span[1])
    c = (lo + hi) / 2
    return float(c[0] - W / 2 / s), float(c[1] - H / 2 / s), float(s)


# --- 1. Guides ----------------------------------------------------------------------------------------

FACE_OVAL = [10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288, 397, 365, 379, 378, 400, 377,
             152, 148, 176, 149, 150, 136, 172, 58, 132, 93, 234, 127, 162, 21, 54, 103, 67, 109]
BROWS = [[70, 63, 105, 66, 107, 55, 65, 52, 53, 46], [300, 293, 334, 296, 336, 285, 295, 282, 283, 276]]
EYES = [[33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246],
        [263, 249, 390, 373, 374, 380, 381, 382, 362, 398, 384, 385, 386, 387, 388, 466]]
LIPS = [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0, 37, 39, 40, 185]
SKIN = np.array([0.82, 0.63, 0.50])
HAIR = np.array([0.24, 0.17, 0.12])
GREY = np.array([0.56, 0.54, 0.51])
TACHE = np.array([0.17, 0.12, 0.09])
BROW = np.array([0.20, 0.14, 0.10])
LIP = np.array([0.62, 0.38, 0.33])
RED = np.array([0.80, 0.40, 0.33])
STUBBLE = np.array([0.50, 0.52, 0.56])
WHITE = np.array([0.84, 0.81, 0.75])
IRIS = np.array([0.26, 0.17, 0.10])
SIDEBURN = 0.03       # metres in front of his ear his sideburns reach
BLUR = 3.0            # pixels: the start picture's colour edges softened


def inside(poly, pts):
    """Which 2D points are inside the polygon (even-odd)."""
    x, y = pts[:, 0], pts[:, 1]
    out = np.zeros(len(pts), bool)
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        cross = ((yi > y) != (yj > y)) & (x < (xj - xi) * (y - yi) / (yj - yi + 1e-12) + xi)
        out ^= cross
        j = i
    return out


def moustache(F, lm):
    """His moustache's place, in the front camera's plane: from under his nose to his upper lip,
    drooping past the corners of his mouth (as his pictures have it)."""
    nose_l, nose_r, base = F(lm[98]), F(lm[327]), F(lm[2])
    lip = F(lm[13])
    cl, cr = F(lm[61]), F(lm[291])
    width = abs(cr[0] - cl[0])
    drop = abs(lip[1] - base[1])
    out = np.sign(cl[0] - cr[0])       # +1: his left corner is on the image's right
    up_l = nose_l + np.array([out * 0.15 * width, 0.0])
    up_r = nose_r + np.array([-out * 0.15 * width, 0.0])
    top_l = cl + np.array([out * 0.20 * width, -0.35 * drop])
    top_r = cr + np.array([-out * 0.20 * width, -0.35 * drop])
    tip_l_out = cl + np.array([out * 0.24 * width, 1.7 * drop])
    tip_l_in = cl + np.array([out * 0.04 * width, 1.8 * drop])
    tip_r_out = cr + np.array([-out * 0.24 * width, 1.7 * drop])
    tip_r_in = cr + np.array([-out * 0.04 * width, 1.8 * drop])
    return [up_l, base + np.array([0, 0.1 * drop]), up_r, top_r, tip_r_out, tip_r_in, cr + np.array([0, 0.1 * drop]),
            lip + np.array([0, 0.12 * drop]), cl + np.array([0, 0.1 * drop]), tip_l_in, tip_l_out, top_l]


def marks_of(L, v, faces, label, lm):
    """Where his hair stops, from the head: each ear's front (z), the jaw's angle (y)."""
    out = {}
    for ear in ("ear_r", "ear_l"):
        ids = sorted({i for k, f in enumerate(faces) if label[k] == ear for i in f})
        out[ear + "_front"] = float(v[ids, 2].min()) if ids else 0.0
        out[ear + "_back"] = float(v[ids, 2].max()) if ids else 0.05
    out["jaw_y"] = float(lm[[172, 397], 1].mean())
    return out


def hints(L, P, pts, nrm, lab, lm, marks):
    """The start picture's colour at surface points (n, 3) with normals and patch names."""
    def F(p):
        return L.project("face", np.asarray(p, float))
    q = F(pts)
    col = np.tile(SKIN, (len(pts), 1))
    front = nrm @ L.toward("face") > 0.15
    ear = np.isin(lab, ["ear_r", "ear_l"])
    oval = inside(F(lm[FACE_OVAL]), q)
    # Hair: above his hairline; outside his face's oval above the jaw's angle (temples and the big
    # sideburns his pictures have); on his sides from SIDEBURN in front of the ear back; all the
    # back and crown; and behind the ears down to his collar.
    right = pts[:, 0] > 0
    ear_front = np.where(right, marks["ear_r_front"], marks["ear_l_front"])
    ear_back = np.where(right, marks["ear_r_back"], marks["ear_l_back"])
    above_jaw = pts[:, 1] > marks["jaw_y"]
    hair = pts[:, 1] > lm[10, 1] - 0.004 - 4.0 * (pts[:, 0] - lm[10, 0]) ** 2   # arching down at his temples
    hair |= ~oval & above_jaw
    hair |= (pts[:, 2] > ear_front - SIDEBURN) & above_jaw
    hair |= pts[:, 2] > ear_back
    hair |= np.isin(lab, ["back", "crown"])
    hair &= ~ear
    side = np.clip((np.abs(pts[:, 0]) - 0.045) / 0.035, 0, 1) * np.clip((lm[10, 1] + 0.03 - pts[:, 1]) / 0.03, 0, 1)
    col[hair] = HAIR * (1 - side[hair, None] * 0.75) + GREY * side[hair, None] * 0.75
    jaw = oval & ~hair & (pts[:, 1] < lm[2, 1])
    col[jaw] = col[jaw] * 0.72 + STUBBLE * 0.28
    for c, r, k in ((lm[1], 0.014, 0.45), (lm[205], 0.022, 0.30), (lm[425], 0.022, 0.30)):
        w = np.clip(1 - np.linalg.norm(pts - c, axis=1) / r, 0, 1) * k
        col = col * (1 - w[:, None]) + RED * w[:, None]
    col[ear] = col[ear] * 0.7 + RED * 0.3
    for idx in BROWS:
        m = front & inside(F(lm[idx]), q)
        col[m] = BROW
    m = front & inside(moustache(F, lm), q)
    col[m] = TACHE
    m = front & inside(F(lm[LIPS]), q) & ~m
    col[m] = LIP
    for k, idx in enumerate(EYES):
        m = front & inside(F(lm[idx]), q)
        col[m] = WHITE
        iris = lm[468 if k == 0 else 473]
        d = np.linalg.norm(q - F(iris), axis=1)
        eye_w = np.linalg.norm(F(lm[idx[0]]) - F(lm[idx[8]]))
        col[m & (d < 0.30 * eye_w)] = IRIS
        col[m & (d < 0.12 * eye_w)] = 0.05
    return col


def render_view(L, P, view, v, faces, label, lm, marks):
    """A view's guides: depth (near white), normals, start picture, and which patch each pixel is."""
    W, H = SIZE[view]
    x0, y0, s = frame(L, view, v, faces, label)
    tris, src = P.triangles(faces)
    vn = P.vertex_normals(v, tris)
    xy = (L.project(view, v) - [x0, y0]) * s
    dep = L.depth(view, v)
    tid, bary, _z = P.rasterise(xy, dep, tris, W, H)
    hit = tid >= 0
    t = tris[tid[hit]]
    b = bary[hit][:, :, None]
    pts = (v[t] * b).sum(1)
    nn = (vn[t] * b).sum(1)
    nn /= np.maximum(np.linalg.norm(nn, axis=1, keepdims=True), 1e-9)
    lab = np.array(label, dtype=object)[src[tid[hit]]]
    d = (dep[t] * bary[hit]).sum(1)
    depth = np.zeros((H, W))
    depth[hit] = 1 - (d - d.min()) / max(np.ptp(d), 1e-9) * 0.85
    a, up = (np.array(x, float) for x in L.VIEWS[view])
    up /= np.linalg.norm(up)
    tw = L.toward(view)
    normal = np.full((H, W, 3), 0.5)
    normal[hit] = np.stack([nn @ a, nn @ up, nn @ tw], 1) * 0.5 + 0.5
    light = tw + 0.35 * up + 0.15 * a
    light /= np.linalg.norm(light)
    shade = np.ones((H, W))
    shade[hit] = 0.62 + 0.38 * np.clip(nn @ light, 0, 1)
    colour = np.zeros((H, W, 3))
    colour[hit] = hints(L, P, pts, nn, lab, lm, marks)
    # Soft edges: the colour blurred within the head (normalised), then the even light on it.
    from scipy import ndimage
    wgt = ndimage.gaussian_filter(hit.astype(float), BLUR)
    colour = np.stack([ndimage.gaussian_filter(colour[:, :, k], BLUR) for k in range(3)], 2) / np.maximum(wgt, 1e-6)[:, :, None]
    start = np.full((H, W, 3), 0.5)
    start[hit] = colour[hit] * shade[hit][:, None]
    patch = np.zeros((H, W), bool)
    patch[hit] = np.isin(lab, PATCHES[view])
    return depth, normal, start, shade, patch, (x0, y0, s)


def guides(man):
    import portrait as P
    L, v, faces, label, rep, lm = load(man)
    out = DIR % man
    os.makedirs(out, exist_ok=True)
    meta = {"layout": rep, "views": {}}
    marks = marks_of(L, v, faces, label, lm)
    for view in PAINTED:
        depth, normal, start, shade, patch, cam = render_view(L, P, view, v, faces, label, lm, marks)
        P.to_pil(np.repeat(depth[:, :, None], 3, 2)).save(os.path.join(out, view + "_depth.png"))
        P.to_pil(normal).save(os.path.join(out, view + "_normal.png"))
        P.to_pil(start).save(os.path.join(out, view + "_start.png"))
        P.to_pil(np.repeat(shade[:, :, None], 3, 2)).save(os.path.join(out, view + "_shade.png"))
        Image.fromarray(patch.astype(np.uint8) * 255).save(os.path.join(out, view + "_patch.png"))
        meta["views"][view] = {"frame": cam, "size": SIZE[view], "patches": PATCHES[view], "style": STYLE[view]}
    json.dump(meta, open(os.path.join(out, "guides.json"), "w"), indent=1)
    sheet = [Image.open(os.path.join(out, "%s_%s.png" % (view, k))).convert("RGB").resize((240, 320))
             for view in PAINTED for k in ("start", "depth", "normal")]
    S = Image.new("RGB", (240 * 3, 320 * len(PAINTED)), (22, 20, 18))
    for i, im in enumerate(sheet):
        S.paste(im, ((i % 3) * 240, (i // 3) * 320))
    S.save(os.path.join(WORK, man + "_guides.png"))
    print("guides:", out)


# --- 2. Paint (fal) -------------------------------------------------------------------------------------

def request(method, url, key, body=None):
    import paint_full_length as pf
    return pf.request(method, url, key, body)


def data_url(path):
    import base64
    return "data:image/png;base64," + base64.b64encode(open(path, "rb").read()).decode()


def ask(view):
    what = "portrait" if view == "face" else "study"
    return ASK.format(what=what, seen=SEEN[view], hair=HAIR_WORDS, face=FACE_WORDS if view != "back" else "")


def paint(man, rnd, dry):
    import io
    import paint_full_length as pf
    out = DIR % man
    meta = json.load(open(os.path.join(out, "guides.json")))
    key = os.environ.get("FAL_KEY", "")
    if not key and not dry:
        print("No FAL_KEY: nothing painted.")
        return
    lora_url = json.load(open(LORA))["lora_url"]
    os.makedirs(os.path.join(out, "paint"), exist_ok=True)
    logp = os.path.join(out, "paint", "fal_log.json")
    log = json.load(open(logp)) if os.path.exists(logp) else []
    made, spent = 0, 0.0
    control_way = 0
    for name, lora, strength, cn, ip, seed in ROUNDS[rnd]:
        for view in PAINTED:
            W, H = meta["views"][view]["size"]
            body = {"prompt": ask(view), "image_url": data_url(os.path.join(out, view + "_start.png")),
                    "strength": strength, "num_inference_steps": 30, "guidance_scale": 3.5, "seed": seed,
                    "num_images": 1, "enable_safety_checker": False, "output_format": "png",
                    "image_size": {"width": W, "height": H},
                    "loras": [{"path": lora_url, "scale": lora}]}
            if ip > 0:
                body["ip_adapters"] = [dict(IP_ADAPTER, image_url=data_url(os.path.join(
                    ROOT, "docs", "concept", "style", STYLE[view])), scale=ip)]
            depth = data_url(os.path.join(out, view + "_depth.png"))
            what = "r%d_%s_%s" % (rnd, name, view)
            if dry:
                b = dict(body, **CONTROL[0](depth, cn))
                print(what, {k: (x if not isinstance(x, str) or len(x) < 120 else x[:40] + "...") for k, x in b.items() if k not in ("loras",)})
                continue
            img = None
            while control_way < len(CONTROL):
                b = dict(body, **CONTROL[control_way](depth, cn))
                try:
                    queued = request("POST", QUEUE + APP, key, b)
                except RuntimeError as e:
                    log.append({what: {"refused": str(e)[:1500], "control_way": control_way}})
                    if "422" in str(e) and "ip_adapter" in str(e) and "ip_adapters" in body:
                        body.pop("ip_adapters")   # turned down over the reference: free; without it
                        continue
                    if "422" in str(e):
                        control_way += 1   # turned down for the asking: free; try the next way
                        continue
                    raise
                log.append({what: {"queued": queued, "control_way": control_way, "lora": lora, "strength": strength,
                                   "controlnet": cn, "ip_adapter": ip, "seed": seed, "prompt": body["prompt"]}})
                status_url = queued.get("status_url") or "%s%s/requests/%s/status" % (QUEUE, APP, queued["request_id"])
                response_url = queued.get("response_url") or "%s%s/requests/%s" % (QUEUE, APP, queued["request_id"])
                for _ in range(180):
                    st = request("GET", status_url, key)
                    if st.get("status") == "COMPLETED":
                        answer = request("GET", response_url, key)
                        log.append({what + "_answer": {k: x for k, x in answer.items() if k != "images"},
                                    "image": (answer.get("images") or [{}])[0].get("url")})
                        images = answer.get("images") or []
                        if images:
                            img = Image.open(io.BytesIO(pf.fetch(images[0]["url"]))).convert("RGB")
                        break
                    if st.get("status") not in ("IN_QUEUE", "IN_PROGRESS"):
                        log.append({what + "_status": st})
                        break
                    time.sleep(5)
                break
            json.dump(log, open(logp, "w"), indent=1)
            if img is not None:
                img.save(os.path.join(out, "paint", what + ".png"))
                made += 1
                spent += 0.075 * max(1, -(-W * H // 1000000))
                print("painted", what)
            else:
                print("failed", what)
    print("uv_paint: %d pictures, about $%.2f on fal" % (made, spent))


# --- 3. Apply --------------------------------------------------------------------------------------------

def sample(img, xy):
    """Bilinear samples of img (h, w, 3) at pixel coordinates xy (n, 2)."""
    h, w = img.shape[:2]
    x = np.clip(xy[:, 0] - 0.5, 0, w - 1.001)
    y = np.clip(xy[:, 1] - 0.5, 0, h - 1.001)
    x0, y0 = x.astype(int), y.astype(int)
    fx, fy = (x - x0)[:, None], (y - y0)[:, None]
    return (img[y0, x0] * (1 - fx) * (1 - fy) + img[y0, x0 + 1] * fx * (1 - fy) +
            img[y0 + 1, x0] * (1 - fx) * fy + img[y0 + 1, x0 + 1] * fx * fy)


def squares(tex, mask, rect, density):
    """The patch's texels in rect squared once: SQUARE cells in its camera plane, each the median of
    its texels, then grouped (see the module's note). Texels of the rect outside the patch take
    their nearest cell, so nothing dark bleeds in at its edge."""
    x, y, w, h = rect
    n = SQUARE * density
    gx = (np.arange(w) / n).astype(int)
    gy = (np.arange(h) / n).astype(int)
    cw, ch = gx.max() + 1, gy.max() + 1
    sub = tex[y:y + h, x:x + w]
    m = mask[y:y + h, x:x + w]
    cell = np.full((ch, cw, 3), np.nan)
    for j in range(ch):
        rows = gy == j
        for i in range(cw):
            sel = m[np.ix_(rows, gx == i)]
            if sel.any():
                cell[j, i] = np.median(sub[np.ix_(rows, gx == i)][sel], 0)
    have = np.isfinite(cell[:, :, 0])
    cell = group(cell, have)
    # Cells with no texel of the patch: their nearest cell's colour.
    from scipy import ndimage
    _d, (iy, ix) = ndimage.distance_transform_edt(~have, return_indices=True)
    cell = cell[iy, ix]
    tex[y:y + h, x:x + w] = cell[gy][:, gx]
    return tex


def group(cell, have):
    """Neighbouring squares into shapes: each cell smoothed with its alike neighbours (RGB within
    LIKE: not across an edge), then a lone cell (further than LONE from every neighbour, while
    they agree among themselves) takes their median."""
    ch, cw = have.shape
    out = cell.copy()
    nbrs = [(dj, di) for dj in (-1, 0, 1) for di in (-1, 0, 1) if (dj, di) != (0, 0)]
    for _ in range(2):
        src = out.copy()
        for j in range(ch):
            for i in range(cw):
                if not have[j, i]:
                    continue
                c = src[j, i]
                acc, wsum = c * 2.0, 2.0
                for dj, di in nbrs:
                    jj, ii = j + dj, i + di
                    if 0 <= jj < ch and 0 <= ii < cw and have[jj, ii]:
                        d = np.linalg.norm(src[jj, ii] - c)
                        if d < LIKE:
                            acc += src[jj, ii] * (1 - d / LIKE)
                            wsum += 1 - d / LIKE
                out[j, i] = acc / wsum
    src = out.copy()
    for j in range(ch):
        for i in range(cw):
            if not have[j, i]:
                continue
            ns = [src[j + dj, i + di] for dj, di in nbrs
                  if 0 <= j + dj < ch and 0 <= i + di < cw and have[j + dj, i + di]]
            if len(ns) < 5:
                continue
            ns = np.array(ns)
            med = np.median(ns, 0)
            if np.linalg.norm(ns - src[j, i], axis=1).min() > LONE and np.linalg.norm(ns - med, axis=1).mean() < LONE * 0.6:
                out[j, i] = med
    return out


def apply(man, take, build):
    import uv_layout as L
    import portrait as P
    from scipy.spatial import cKDTree
    _L, v, faces, label, rep, lm = load(man)
    out = DIR % man
    meta = json.load(open(os.path.join(out, "guides.json")))
    ras = np.load(os.path.join(WORK, man + "_raster.npz"))
    surf, face_at = ras["surf"], ras["face_at"]
    lab_arr = np.array(label, dtype=object)
    texl = np.where(face_at >= 0, lab_arr[np.maximum(face_at, 0)], "")
    size = face_at.shape[0]
    tex = np.zeros((size, size, 3))
    done = np.zeros((size, size), bool)
    rects = rep["rects"]
    density = rep["texels_a_metre"]
    for view in PAINTED:
        path = os.path.join(out, "paint", "%s_%s.png" % (take, view))
        if not os.path.exists(path):
            print("apply: no painting", path)
            continue
        img = np.asarray(Image.open(path).convert("RGB").resize(tuple(SIZE[view]), Image.LANCZOS)).astype(float) / 255
        shade = np.asarray(Image.open(os.path.join(out, view + "_shade.png")).convert("L")).astype(float) / 255
        # The start picture's light out, DELIGHT of the way (blurred: its broad light, not detail).
        sh = np.asarray(Image.fromarray((shade * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(6))).astype(float) / 255
        sh = sh / max(np.median(sh[shade < 0.999]), 1e-3) if (shade < 0.999).any() else sh
        img = img / np.clip(sh, 0.5, 1.6)[:, :, None] ** DELIGHT
        x0, y0, s = meta["views"][view]["frame"]
        for patch in PATCHES[view]:
            m = texl == patch
            xy = (L.project(view, surf[m]) - [x0, y0]) * s
            tex[m] = np.clip(sample(img, xy), 0, 1)
            done[m] = True
    # Seams: the side patches' colour matched to the face's along where they meet on him, low
    # frequency only (a smooth offset fading over SEAM_SIGMA), the face itself untouched.
    face_m = texl == "face"
    if face_m.any():
        tree = cKDTree(surf[face_m])
        face_col = tex[face_m]
        for patch in ("right", "left", "back", "ear_r", "ear_l"):
            m = (texl == patch) & done
            if not m.any():
                continue
            d, idx = tree.query(surf[m])
            near = d < 0.006
            if near.sum() < 10:
                continue
            diff = face_col[idx[near]] - tex[m][near]
            seam_pts = surf[m][near]
            t2 = cKDTree(seam_pts)
            dd, ii = t2.query(surf[m], k=min(24, len(seam_pts)))
            w = np.exp(-(dd / SEAM_SIGMA) ** 2)
            off = (diff[ii] * w[:, :, None]).sum(1) / np.maximum(w.sum(1, keepdims=True), 1e-9)
            fade = np.exp(-(d / SEAM_SIGMA) ** 2)[:, None]
            tex[m] = np.clip(tex[m] + off * fade, 0, 1)
    # Crown, throat and anything unpainted: their nearest painted texel on him.
    todo = (face_at >= 0) & ~done
    if todo.any():
        tree = cKDTree(surf[done])
        _d, idx = tree.query(surf[todo])
        tex[todo] = tex[done][idx]
    # Squares once, each patch in its own camera's grid.
    for patch, rect in rects.items():
        tex = squares(tex, texl == patch, rect, density)
    path = os.path.join(WORK, "%s_%s_tex.png" % (man, take))
    P.to_pil(tex).save(path)
    print("apply: wrote", path)
    if build:
        import uv_head as U
        U.build(man, path)


def main():
    args = dict(a.split("=", 1) for a in sys.argv[1:] if "=" in a)
    man = args.get("--man", "bold_cowboy")
    os.chdir(ROOT)
    if "guides" in sys.argv:
        guides(man)
    elif "paint" in sys.argv:
        rnd = args.get("--round", "next")
        if rnd == "next":   # the first round with a take not painted yet
            done = os.listdir(os.path.join(DIR % man, "paint")) if os.path.isdir(os.path.join(DIR % man, "paint")) else []
            rnd = next((r for r in sorted(ROUNDS) if not all("r%d_%s_face.png" % (r, t[0]) in done for t in ROUNDS[r])), None)
            if rnd is None:
                print("uv_paint: every round in ROUNDS is painted; add one")
                return
        paint(man, int(rnd), "--dry-run" in sys.argv)
    elif "apply" in sys.argv:
        apply(man, args["--take"], "--build" in sys.argv)
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
