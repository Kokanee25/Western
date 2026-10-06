"""The bold set for the fitted men: each Tripo man's textures redrawn in the bold style (Sean,
2026-10-05: the street painting's style everywhere, DESIGN.md §4; the saloon's target is
docs/concept/saloon-blocks.png, where the man at the card table has a face of about 22 squares
across, drawn finer at the eyes, brows and moustache, and a coat of bold tweed squares). No image
model and no paid call: it works from his own textures (Tripo's colour, the head repaint).

    python3 tools/characters/bold_paint.py [--only=stranger] [--views] [--eye-grid]

For each person in assets/people/people.json with "source": "tripo" and a fitted glb
(assets/people/<id>.glb, tools/blender/fit_tripo.py):
  1. Every texel his meshes use, with the point on him it shows (his rest pose, our body space,
     metres), the surface's facing and the part it moves with: the glb's triangles drawn into the
     texture by their UVs.
  2. The light taken out: Tripo paints in the light it saw, and the head repaint its lamp. The
     part of his lightness that follows the surface's facing (lit from above, from in front) is
     fitted by least squares, each material's own lightness kept apart, and taken off. Folds,
     pattern and darker garments stay: the game lights him as it lights the walls.
  3. Squares on him, not in the texture: on a grid in body space lined up on his eyes
     (people.json `eyes`), so a square is upright on him whichever way Tripo's atlas island lies;
     a texel's square is the one its point falls in, on the grid of the way the surface mostly
     faces and on its own part. Squares are one size on everyone (FACE_M, CLOTH_M, HAND_M), as
     the world's are; where there's detail in a square (SPLIT) it splits in four, so features are
     drawn finer than plain skin and cloth, as the bold painting's are.
  4. One material a square: his colours sorted into materials (k-means), each square the one most
     of its texels are (dark materials counted more, so brows, the moustache and a tie stay
     whole), then cleaned as a pixel artist would (a square hardly any neighbour shares takes what
     most of them are: stubble flecks go, gaps in the moustache close).
  5. Bold tones: each material's own variation in lightness (its pattern, folds, seams) stretched
     and a little clumped noise added, snapped to its kind's steps (STYLES: cloth in clear steps,
     skin a gentle mottle, a few creams in the shirt), stretched till neighbouring squares differ
     as much as the bold painting's do or STRETCH times.
  6. His eyes keep their own fine drawing, unsquared (the bold painting's eyes are drawn finer
     than its squares).
  → assets/people/<id>_<shape>_bold.png (shape: skin, head, and each piece: hat ...), laid on by
    PeopleBodies.bold_paint (the bold look); <id>_bold.json, what was done. --views writes
    build/bold/<id>_bold.png: him as he was and bold, from four sides and his face close, drawn
    here in numpy with no light. --eye-grid writes his face from the front with a
    centimetre grid (build/bold/<id>_eye_grid.png), to measure his eyes for people.json.
"""
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
PEOPLE = os.path.join(ROOT, "assets", "people")
TRIPO = os.path.join(PEOPLE, "tripo")
BUILD = os.path.join(ROOT, "build", "bold")

# The written textures' size: twice fit_tripo's 1024, so a square's edge on him steps by about
# 1.3 mm (at 1024 the face's squares were three texels across and ragged).
SIZE = 2048
# The squares' sizes on a man, the same for everyone as the world's squares are (metres): his face
# (the bold painting's man's face is about 22 squares across and its face squares 8 px at 1672
# wide; ours in the lab came out a quarter bigger at that, so the stranger's face, 18.5 cm cheek
# to cheek, is 26 across), his clothes (the painting's coat squares measure about 1.25 times its
# face's in pixels, at nearly the same distance) and his hands.
FACE_M = 0.0071
CLOTH_M = 0.0092
HAND_M = 0.0071
# How many times a square may split in four (cloth, head, hands): a kind's squares start at its
# size (FACE_M, CLOTH_M, HAND_M) and each split halves them. SPLIT: a square
# splits when its texels' lightness varies more than this (L*, standard deviation).
SPLITS = (1, 1, 1)
SPLIT = (9.0, 6.0, 7.0)
# How much of the light measured in his colours comes out (1: all of it).
DELIGHT = 0.85
# Materials his colours are sorted into.
MATERIALS = 12
# In a square's vote for its material, a material counts 1 + DARK_VOTE x how dark it is (0 at
# L* 50 and lighter, 1 at black).
DARK_VOTE = 1.0
# The clean-up: a square with at most CLEAN_ALONE neighbours of its own material takes the one
# most of them are, CLEAN_ROUNDS times over.
CLEAN_ALONE = 1
CLEAN_ROUNDS = 2
# The noise added to every square's lightness, in its kind's steps (enough that plain cloth isn't
# flat), and his head's share of it (a felt hat and a face aren't tweed).
DITHER = 0.35
HEAD_MOTTLE = 0.5
# A material's own variation (pattern, folds) is stretched up to this many times to reach its
# kind's `jump`.
STRETCH = 3.0
# His eyes keep their own drawing in an almond this wide and tall round each eye (shares of how
# far apart his eyes are).
EYE_WIDE = 0.26
EYE_TALL = 0.12

# The parts (our bones, the skin's joint order is read from the glb).
HEAD_PARTS = {"head"}
HAND_PARTS = {"hand_r", "hand_l"}


# --- The glb ------------------------------------------------------------------------------------

def read_glb(path):
    """The meshes of a fitted glb {name: {pos, nrm, uv, tris, weights (V x bones)}}, the skin's
    bone names, and any images it carries."""
    f = open(path, "rb").read()
    clen = struct.unpack("<I", f[12:16])[0]
    doc = json.loads(f[20:20 + clen])
    blen = struct.unpack("<I", f[20 + clen:24 + clen])[0]
    binary = f[28 + clen:28 + clen + blen]

    def accessor(i):
        a = doc["accessors"][i]
        bv = doc["bufferViews"][a["bufferView"]]
        dtype = {5126: np.float32, 5123: np.uint16, 5125: np.uint32, 5121: np.uint8}[a["componentType"]]
        n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[a["type"]]
        start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        out = np.frombuffer(binary, dtype=dtype, count=a["count"] * n, offset=start).reshape(a["count"], n)
        if a.get("normalized") and dtype != np.float32:
            return out.astype(np.float64) / np.iinfo(dtype).max
        return out.astype(np.float64)

    # Each node's place in the scene (a fitted man's meshes sit at the origin, but say so).
    world = {}

    def local(node):
        if "matrix" in node:
            return np.array(node["matrix"], dtype=float).reshape(4, 4).T
        m = np.eye(4)
        t = node.get("translation", [0, 0, 0])
        q = node.get("rotation", [0, 0, 0, 1])
        s = node.get("scale", [1, 1, 1])
        x, y, z, w = q
        r = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                      [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                      [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
        m[:3, :3] = r * np.array(s)
        m[:3, 3] = t
        return m

    def walk(i, parent):
        world[i] = parent @ local(doc["nodes"][i])
        for c in doc["nodes"][i].get("children", []):
            walk(c, world[i])

    for root in doc["scenes"][doc.get("scene", 0)]["nodes"]:
        walk(root, np.eye(4))
    names = []
    if doc.get("skins"):
        names = [doc["nodes"][j].get("name", str(j)) for j in doc["skins"][0]["joints"]]
    meshes = {}
    for i, node in enumerate(doc["nodes"]):
        if "mesh" not in node:
            continue
        m = world.get(i, np.eye(4))
        prim = doc["meshes"][node["mesh"]]["primitives"][0]
        pos = accessor(prim["attributes"]["POSITION"])
        pos = pos @ m[:3, :3].T + m[:3, 3]
        nrm = accessor(prim["attributes"]["NORMAL"]) @ m[:3, :3].T
        nrm /= np.maximum(np.linalg.norm(nrm, axis=1, keepdims=True), 1e-9)
        weights = np.zeros((len(pos), max(len(names), 1)))
        if "JOINTS_0" in prim["attributes"]:
            j = accessor(prim["attributes"]["JOINTS_0"]).astype(np.int64)
            w = accessor(prim["attributes"]["WEIGHTS_0"])
            for k in range(j.shape[1]):
                np.add.at(weights, (np.arange(len(pos)), j[:, k]), w[:, k])
        name = node.get("name") or doc["meshes"][node["mesh"]].get("name", str(i))
        meshes[name] = {"pos": pos, "nrm": nrm, "uv": accessor(prim["attributes"]["TEXCOORD_0"]),
                        "tris": accessor(prim["indices"]).reshape(-1, 3).astype(np.int64), "weights": weights}
    images = []
    for img in doc.get("images", []):
        bv = doc["bufferViews"][img["bufferView"]]
        images.append(Image.open(io.BytesIO(binary[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]])).convert("RGB"))
    return meshes, names, images


# --- Texels on him --------------------------------------------------------------------------------

def texels(mesh, size):
    """Every texel of a size x size texture the mesh's triangles cover: its row and column, the
    point on him it shows, the surface's normal there and its part (the bone weighted most)."""
    uv = mesh["uv"] * size - 0.5  # texel centres on whole numbers
    rows, cols, tri, bary = [], [], [], []
    for t, (a, b, c) in enumerate(mesh["tris"]):
        p = uv[[a, b, c]]
        lo = np.floor(p.min(axis=0)).astype(int)
        hi = np.ceil(p.max(axis=0)).astype(int)
        lo = np.maximum(lo, 0)
        hi = np.minimum(hi, size - 1)
        if (hi < lo).any():
            continue
        xs, ys = np.meshgrid(np.arange(lo[0], hi[0] + 1), np.arange(lo[1], hi[1] + 1))
        q = np.stack([xs.ravel(), ys.ravel()], axis=1).astype(float)
        e1, e2 = p[1] - p[0], p[2] - p[0]
        det = e1[0] * e2[1] - e1[1] * e2[0]
        if abs(det) < 1e-12:
            continue
        d = q - p[0]
        w1 = (d[:, 0] * e2[1] - d[:, 1] * e2[0]) / det
        w2 = (e1[0] * d[:, 1] - e1[1] * d[:, 0]) / det
        w0 = 1.0 - w1 - w2
        eps = 1e-6
        inside = (w0 >= -eps) & (w1 >= -eps) & (w2 >= -eps)
        if not inside.any():
            continue
        cols.append(q[inside, 0].astype(int))
        rows.append(q[inside, 1].astype(int))
        tri.append(np.full(inside.sum(), t))
        bary.append(np.stack([w0[inside], w1[inside], w2[inside]], axis=1))
    rows, cols = np.concatenate(rows), np.concatenate(cols)
    tri, bary = np.concatenate(tri), np.concatenate(bary)
    # A texel two triangles share (on their common edge) is kept once.
    key = rows * size + cols
    _u, first = np.unique(key, return_index=True)
    rows, cols, tri, bary = rows[first], cols[first], tri[first], bary[first]
    corners = mesh["tris"][tri]
    point = np.einsum("nk,nkd->nd", bary, mesh["pos"][corners])
    normal = np.einsum("nk,nkd->nd", bary, mesh["nrm"][corners])
    normal /= np.maximum(np.linalg.norm(normal, axis=1, keepdims=True), 1e-9)
    weights = np.einsum("nk,nkb->nb", bary, mesh["weights"][corners])
    return {"row": rows, "col": cols, "point": point, "normal": normal, "bone": np.argmax(weights, axis=1)}


# --- Colour ---------------------------------------------------------------------------------------

def srgb_to_linear(c):
    c = np.asarray(c, dtype=float) / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c):
    c = np.clip(c, 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1 / 2.4) - 0.055) * 255.0


_M = np.array([[0.4124564, 0.3575761, 0.1804375], [0.2126729, 0.7151522, 0.0721750],
               [0.0193339, 0.1191920, 0.9503041]])
_WHITE = np.array([0.95047, 1.0, 1.08883])


def to_lab(rgb):
    """sRGB 0-255 → CIE L*a*b*."""
    xyz = srgb_to_linear(rgb) @ _M.T / _WHITE
    f = np.where(xyz > 216 / 24389, np.cbrt(xyz), (24389 / 27 * xyz + 16) / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], axis=-1)


def from_lab(lab):
    """CIE L*a*b* → sRGB 0-255."""
    fy = (lab[..., 0] + 16) / 116
    fx = fy + lab[..., 1] / 500
    fz = fy - lab[..., 2] / 200
    f = np.stack([fx, fy, fz], axis=-1)
    xyz = np.where(f ** 3 > 216 / 24389, f ** 3, (116 * f - 16) / (24389 / 27)) * _WHITE
    return linear_to_srgb(xyz @ np.linalg.inv(_M).T)


def kmeans(x, k, seed=7, rounds=30):
    """Plain k-means: centres and each row's label."""
    rng = np.random.default_rng(seed)
    centres = x[rng.choice(len(x), size=min(k, len(x)), replace=False)].copy()
    for _ in range(rounds):
        d = ((x[:, None, :] - centres[None, :, :]) ** 2).sum(axis=2)
        label = np.argmin(d, axis=1)
        moved = np.array([x[label == i].mean(axis=0) if (label == i).any() else centres[i] for i in range(len(centres))])
        if np.allclose(moved, centres):
            break
        centres = moved
    return centres, label


# --- A man ----------------------------------------------------------------------------------------

class Man:
    def __init__(self, pid, spec, size):
        self.pid = pid
        self.spec = spec
        self.size = size
        self.meshes, self.bones, _images = read_glb(os.path.join(PEOPLE, pid + ".glb"))
        # Each mesh's texture as the game has it now, and its source at Tripo's resolution where
        # there is one (the head repaint's <model>_color.png, or the piece's own Tripo model).
        self.sources = {}
        model = spec.get("model", pid)
        named = pid if os.path.exists(os.path.join(TRIPO, pid + "_color.png")) else model
        body_src = os.path.join(TRIPO, named + "_color.png")
        for name in self.meshes:
            shape = name.replace("body_", "")
            if shape in ("skin", "head"):
                if os.path.exists(body_src):
                    self.sources[shape] = Image.open(body_src).convert("RGB")
                else:
                    self.sources[shape] = Image.open(os.path.join(PEOPLE, "%s_%s.png" % (pid, shape))).convert("RGB")
            else:
                piece = spec.get("pieces", {}).get(shape)
                glb = os.path.join(TRIPO, (piece or "") + ".glb")
                images = read_glb(glb)[2] if piece and os.path.exists(glb) else []
                self.sources[shape] = images[0] if images else Image.open(os.path.join(PEOPLE, "%s_%s.png" % (pid, shape))).convert("RGB")

    def gather(self):
        """Every texel he uses, all shapes together (a square may span the head and the collar)."""
        parts = []
        for name, mesh in self.meshes.items():
            shape = name.replace("body_", "")
            t = texels(mesh, self.size)
            src = np.asarray(self.sources[shape].resize((self.size, self.size), Image.BILINEAR), dtype=float)
            t["rgb"] = src[t["row"], t["col"]]
            t["shape"] = np.full(len(t["row"]), shape, dtype=object)
            parts.append(t)
        keys = parts[0].keys()
        self.t = {k: np.concatenate([p[k] for p in parts]) for k in keys}
        self.t["lab"] = to_lab(self.t["rgb"])
        self.t["part"] = np.array(self.bones, dtype=object)[self.t["bone"]]
        print("%s: %d texels on %s" % (self.pid, len(self.t["row"]), ", ".join(sorted(set(self.t["shape"])))))


# --- Looking at him -------------------------------------------------------------------------------

# Views for --views and the eye finder: (name, the way the camera looks, the screen's right).
VIEWS = {"front": 0.0, "three_quarter": 35.0, "side": 90.0, "back": 180.0}


def view_axes(view):
    """The way the camera looks and the screen's right for a view: his front turned this many
    degrees to his left (the camera goes round to his right side)."""
    a = np.radians(VIEWS[view] if isinstance(view, str) else view)
    return np.array([np.sin(a), 0.0, np.cos(a)]), np.array([np.cos(a), 0.0, -np.sin(a)])


def draw(meshes, textures, view, px_per_m, box=None):
    """His meshes seen square-on from `view` (orthographic, no light), each texel as it is: an
    RGB image, and where he isn't, the background. `box` (x0, y0, x1, y1 in the view's metres)
    crops it; else his whole height."""
    look, right = view_axes(view)
    up = np.array([0.0, 1.0, 0.0])
    allp = np.concatenate([m["pos"] for m in meshes.values()])
    sx = allp @ right
    sy = allp @ up
    if box is None:
        box = (sx.min() - 0.02, sy.min() - 0.02, sx.max() + 0.02, sy.max() + 0.02)
    w = int(round((box[2] - box[0]) * px_per_m))
    h = int(round((box[3] - box[1]) * px_per_m))
    img = np.full((h, w, 3), 40.0)
    depth = np.full((h, w), np.inf)
    for name, m in meshes.items():
        tex = textures[name.replace("body_", "")]
        th, tw = tex.shape[:2]
        x = (m["pos"] @ right - box[0]) * px_per_m - 0.5
        y = (box[3] - m["pos"] @ up) * px_per_m - 0.5
        z = m["pos"] @ look
        for a, b, c in m["tris"]:
            px = np.array([x[a], x[b], x[c]])
            py = np.array([y[a], y[b], y[c]])
            x0, x1 = max(int(np.floor(px.min())), 0), min(int(np.ceil(px.max())), w - 1)
            y0, y1 = max(int(np.floor(py.min())), 0), min(int(np.ceil(py.max())), h - 1)
            if x1 < x0 or y1 < y0:
                continue
            det = (px[1] - px[0]) * (py[2] - py[0]) - (px[2] - px[0]) * (py[1] - py[0])
            if abs(det) < 1e-9:
                continue
            gx, gy = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
            dx, dy = gx - px[0], gy - py[0]
            w1 = (dx * (py[2] - py[0]) - dy * (px[2] - px[0])) / det
            w2 = ((px[1] - px[0]) * dy - (py[1] - py[0]) * dx) / det
            w0 = 1 - w1 - w2
            inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
            if not inside.any():
                continue
            zz = w0 * z[a] + w1 * z[b] + w2 * z[c]
            gy_i, gx_i = gy[inside], gx[inside]
            zi = zz[inside]
            nearer = zi < depth[gy_i, gx_i]
            if not nearer.any():
                continue
            gy_i, gx_i, zi = gy_i[nearer], gx_i[nearer], zi[nearer]
            uv = (w0[inside][nearer, None] * m["uv"][a] + w1[inside][nearer, None] * m["uv"][b]
                  + w2[inside][nearer, None] * m["uv"][c])
            tc = np.clip((uv[:, 0] * tw).astype(int), 0, tw - 1)
            tr = np.clip((uv[:, 1] * th).astype(int), 0, th - 1)
            depth[gy_i, gx_i] = zi
            img[gy_i, gx_i] = tex[tr, tc]
    return img, box


# --- The bold squares -----------------------------------------------------------------------------

AXES = ((2, 1), (0, 2), (0, 1))  # the two in-plane axes for a surface turned to x, y or z


def clumped(points, spacing, seed):
    """A noise of unit spread at each point: half a lattice of random values `spacing` apart,
    blended between its corners (neighbouring squares lean the same way, in clumps), half each
    point's own."""
    rng = np.random.default_rng(seed)
    q = points / spacing
    base = np.floor(q).astype(np.int64)
    f = q - base
    lo = base.min(axis=0)
    dims = base.max(axis=0) - lo + 2
    lattice = rng.standard_normal(tuple(dims))
    b = base - lo
    out = np.zeros(len(points))
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (np.where(dx, f[:, 0], 1 - f[:, 0]) * np.where(dy, f[:, 1], 1 - f[:, 1])
                     * np.where(dz, f[:, 2], 1 - f[:, 2]))
                out += w * lattice[b[:, 0] + dx, b[:, 1] + dy, b[:, 2] + dz]
    out /= max(out.std(), 1e-9)
    own = rng.standard_normal(len(points))
    n = 0.75 * out + 0.45 * own
    return n / max(n.std(), 1e-9)


# How each kind of material's squares are spread over tones: how many tones, how far apart (L*),
# how much clumped noise picks between them (L*), the clumps' size (squares) and how much of a
# square's own hue it keeps (the rest is its material's). The bold painting's coat is a tweed of
# three or four browns in clumps; its skin a gentle mottle that mostly follows the light (the game
# brings the light); the shirt nearly one cream; hair and brows a few dark browns.
# `step`: the kind's tones are whole steps of this much lightness (L*), so neighbouring squares
# differ by a clear step or not at all. `jump`: the mean step between neighbouring squares of one
# material the noise is tuned to; `clump`: the noise's patches, in squares. The bold painting's
# coat (a tweed) measures 6-7 at L* 18 under its lamp, its other men's clothes 3-5 on dark cloth
# and up to 10-12 on a lit shirt or a patterned vest, the patches two or three squares across.
# His albedo is lighter than its lamplit picture and the game brings the light, so cloth is a
# little under the tweed: a mottle that keeps the garment's own pattern (a vest's argyle, folds).
# Its face varies more on screen, but most of that is the lamp and the face's form.
STYLES = {
    "skin": {"step": 5.0, "jump": 4.5, "clump": 1.6, "own": 0.5},
    "dark": {"step": 5.0, "jump": 4.0, "clump": 1.6, "own": 0.3},
    "light": {"step": 5.0, "jump": 4.0, "clump": 2.0, "own": 0.3},
    "cloth": {"step": 6.0, "jump": 5.0, "clump": 2.0, "own": 0.25},
}


def style_of(lab, head_share):
    """A material's kind from its middle colour (L*, a*, b*) and how much of it is on his head and
    hands."""
    L, a, b = lab
    chroma = np.hypot(a, b)
    hue = np.degrees(np.arctan2(b, a))
    if 15 <= hue <= 75 and chroma >= 14 and L >= 45 and head_share >= 0.25:
        return "skin"
    if L < 18:
        return "dark"
    if L > 72 and chroma < 16:
        return "light"
    return "cloth"


def neighbours(centres, sizes, reach=1.2):
    """Pairs of neighbouring squares: their centres within `reach` squares (1.2: side by side;
    1.5: corners too)."""
    from scipy.spatial import cKDTree
    tree = cKDTree(centres)
    return tree.query_pairs(reach * float(np.median(sizes)), output_type="ndarray").reshape(-1, 2)


class Bold:
    """The bold squares for one man's gathered texels (Man.gather)."""

    def __init__(self, man, eyes=None):
        """`eyes`: where his eyes are seen from straight in front ([x, y] each, people.json); their
        depth is the front of his face there."""
        self.man = man
        self.t = man.t
        self.eyes = None if eyes is None else np.array([self.on_face(e) for e in eyes])
        self.face_m = FACE_M
        if self.eyes is not None:
            self.apart = float(np.linalg.norm(self.eyes[0] - self.eyes[1]))
            self.mid = self.eyes.mean(axis=0)
        else:
            self.mid = None
        self.report = {"face_square_mm": round(FACE_M * 1000, 2), "cloth_square_mm": round(CLOTH_M * 1000, 2)}

    def on_face(self, eye):
        """An eye's place on him: [x, y] seen from in front, and the depth of the front of his head
        there (the texels facing forward within 4 mm of it, the nearest centimetre of them)."""
        t = self.t
        near = np.isin(t["part"], list(HEAD_PARTS)) & (t["normal"][:, 2] < -0.2) \
            & (np.hypot(t["point"][:, 0] - eye[0], t["point"][:, 1] - eye[1]) < 0.004)
        if not near.any():
            raise SystemExit("%s: nothing of his face at the eye %s" % (self.man.pid, eye))
        z = t["point"][near, 2]
        return np.array([eye[0], eye[1], float(np.median(z[z < z.min() + 0.01]))])

    def materials(self):
        """His colours sorted into MATERIALS by k-means (lightness counts a third), and each one's
        kind (STYLES) from its middle colour."""
        lab = self.t["lab"]
        x = lab * np.array([0.33, 1.0, 1.0])
        rng = np.random.default_rng(3)
        sample = x[rng.choice(len(x), size=min(len(x), 120000), replace=False)]
        centres, _ = kmeans(sample, MATERIALS)
        d = ((x[:, None, :] - centres[None, :, :]) ** 2).sum(axis=2)
        mat = np.argmin(d, axis=1)
        self.t["mat"] = mat
        on_head = np.isin(self.t["part"], list(HEAD_PARTS | HAND_PARTS))
        self.styles = []
        self.report["materials"] = []
        for m in range(len(centres)):
            sel = mat == m
            mid = np.median(lab[sel], axis=0) if sel.any() else np.zeros(3)
            self.styles.append(style_of(mid, on_head[sel].mean() if sel.any() else 0.0))
            self.report["materials"].append({"style": self.styles[m], "share": round(float(sel.mean()), 3),
                                             "lab": [round(float(v), 1) for v in mid]})

    def delight(self):
        """The light Tripo and the head repaint drew in, taken out: the part of his lightness that
        follows which way the surface faces (lit from above, from the front, one cheek hot), fitted
        across all his texels with each material's own lightness kept apart (least squares), on his
        head and on the rest of him separately. Darker cloth stays darker and folds stay folds."""
        t = self.t
        lab = t["lab"].copy()
        on_head = np.isin(t["part"], list(HEAD_PARTS))
        self.report["light"] = {}
        for name, sel in (("head", on_head), ("body", ~on_head)):
            n = t["normal"][sel]
            m = t["mat"][sel]
            k = MATERIALS
            a = np.zeros((sel.sum(), k + 3))
            a[np.arange(sel.sum()), m] = 1.0
            a[:, k:] = n
            coef, *_ = np.linalg.lstsq(a, lab[sel, 0], rcond=None)
            light = n @ coef[k:]
            lab[sel, 0] = np.clip(lab[sel, 0] - DELIGHT * (light - light.mean()), 0, 100)
            self.report["light"][name] = [round(float(c), 2) for c in coef[k:]]
        t["flat"] = lab

    def eye_mask(self):
        """Texels in his eyes (an almond round each eye's centre, on the front of his head): they
        keep their own fine drawing, as the bold painting's eyes do, unsquared."""
        t = self.t
        mask = np.zeros(len(t["point"]), bool)
        if self.eyes is None:
            return mask
        on_head = np.isin(t["part"], list(HEAD_PARTS))
        for e in self.eyes:
            d = t["point"] - e
            mask |= on_head & ((d[:, 0] / (EYE_WIDE * self.apart)) ** 2 + (d[:, 1] / (EYE_TALL * self.apart)) ** 2 < 1) \
                & (np.abs(d[:, 2]) < 0.35 * self.apart) & (t["normal"][:, 2] < -0.2)
        return mask

    def squares(self):
        """Each texel's square: a cube on a grid in body space, on the face the surface mostly turns
        to and on its own part. Squares start big and split in four where there's detail in them
        (a square whose lightness varies by more than its kind's SPLIT), as the bold painting draws
        big blocks on a cheek and finer ones at the eyes, brows and moustache."""
        t = self.t
        p, n = t["point"], t["normal"]
        axis = np.argmax(np.abs(n), axis=1)
        sign = np.sign(n[np.arange(len(n)), axis]).astype(np.int64)
        part = t["part"]
        cls = np.where(np.isin(part, list(HEAD_PARTS)), 1, np.where(np.isin(part, list(HAND_PARTS)), 2, 0))
        # Biggest square and how many times it may split, by kind (cloth, head, hands).
        biggest = np.array([CLOTH_M, FACE_M, HAND_M])
        size = biggest[cls].copy()
        # The grid: the middle between his eyes in the middle of a square, his eyes on a row's middle.
        origin = self.mid - self.face_m * 0.5 if self.mid is not None else np.zeros(3)
        u = np.empty(len(p))
        v = np.empty(len(p))
        w = np.empty(len(p))
        for a, (i, j) in enumerate(AXES):
            sel = axis == a
            u[sel] = p[sel, i] - origin[i]
            v[sel] = p[sel, j] - origin[j]
            w[sel] = p[sel, a] - origin[a]
        # Depth along the surface's facing is counted in the biggest squares, so a split square's
        # four stay together.
        iw = np.floor(w / (3 * size)).astype(np.int64)
        shape_id = np.unique(t["shape"], return_inverse=True)[1].ravel()
        piece = np.where(np.isin(t["shape"], ["skin", "head"]), 0, shape_id + 1)
        L = t["flat"][:, 0]
        level = np.zeros(len(p), np.int64)

        def keyed():
            iu = np.floor(u / size).astype(np.int64)
            iv = np.floor(v / size).astype(np.int64)
            key = np.stack([cls, level, piece, t["bone"], axis * 2 + (sign > 0), iu, iv, iw], axis=1)
            return np.unique(key, axis=0, return_inverse=True)[1].ravel()

        splits = np.array(SPLITS)[cls]
        for lev in range(max(SPLITS)):
            sq = keyed()
            cnt = np.bincount(sq)
            mean = np.bincount(sq, L) / cnt
            spread = np.sqrt(np.maximum(np.bincount(sq, L * L) / cnt - mean ** 2, 0))
            split = (spread[sq] > np.array(SPLIT)[cls]) & (level < splits)
            if not split.any():
                break
            size = np.where(split, size / 2, size)
            level = np.where(split, level + 1, level)
        t["square"] = keyed()
        t["square_size"] = size
        t["square_class"] = cls
        self.report["squares"] = int(t["square"].max() + 1)
        self.report["square_mm"] = {name: {str(round(float(s) * 1000, 2)): int((np.round(size[cls == k], 7) == round(float(s), 7)).sum())
                                           for s in np.unique(np.round(size[cls == k], 7))}
                                    for k, name in enumerate(("cloth", "head", "hands"))}

    def colours(self, seed=11):
        """One material a square (a vote of its texels, dark materials counted more, so brows, the
        moustache and a tie stay whole and a square is one thing or another), its colour that
        material's, its lightness that of its texels of that material; then onto its kind's tones."""
        t = self.t
        sq = t["square"]
        count = np.bincount(sq)
        nsq = len(count)
        flat = t["flat"]
        mats = t["mat"]
        mids = np.array([np.median(flat[mats == m], axis=0) if (mats == m).any() else np.zeros(3)
                         for m in range(MATERIALS)])
        # Darker materials weigh more in the vote: a feature drawn thin (a brow, a lid, the line of
        # a tie) keeps its squares.
        weight = 1.0 + DARK_VOTE * np.clip((50.0 - mids[:, 0]) / 50.0, 0.0, 1.0)
        votes = np.zeros((nsq, MATERIALS))
        np.add.at(votes, (sq, mats), weight[mats])
        mat = np.argmax(votes, axis=1)
        mine = mats == mat[sq]
        n_mine = np.bincount(sq, mine, minlength=nsq)
        L_mine = np.bincount(sq, flat[:, 0] * mine, minlength=nsq) / np.maximum(n_mine, 1)
        ab_mine = np.stack([np.bincount(sq, flat[:, k] * mine, minlength=nsq) for k in (1, 2)], axis=1) / np.maximum(n_mine, 1)[:, None]
        colour = np.concatenate([L_mine[:, None], ab_mine], axis=1)
        centre = np.stack([np.bincount(sq, t["point"][:, k], minlength=nsq) for k in range(3)], axis=1) / count[:, None]
        size = np.bincount(sq, t["square_size"], minlength=nsq) / count
        # Cleaned as a pixel artist would: a square of a material hardly any of its neighbours are
        # (a fleck of stubble, a stray strand, a gap in the moustache) takes what most of them are.
        kinds = np.round(size, 6)
        pairs = np.concatenate([np.flatnonzero(kinds == k)[neighbours(centre[kinds == k], size[kinds == k], 1.5)]
                                for k in np.unique(kinds)])
        flipped = 0
        for _ in range(CLEAN_ROUNDS):
            cnt = np.zeros((nsq, MATERIALS))
            np.add.at(cnt, (pairs[:, 0], mat[pairs[:, 1]]), 1)
            np.add.at(cnt, (pairs[:, 1], mat[pairs[:, 0]]), 1)
            deg = cnt.sum(axis=1)
            best = np.argmax(cnt, axis=1)
            same = cnt[np.arange(nsq), mat]
            flip = (same <= CLEAN_ALONE) & (best != mat) & (deg >= 3) & (cnt[np.arange(nsq), best] >= 0.5 * deg)
            if not flip.any():
                break
            # The colour of its neighbours of that material.
            tot = np.zeros((nsq, 3))
            num = np.zeros(nsq)
            for a, b in ((0, 1), (1, 0)):
                ok = mat[pairs[:, b]] == best[pairs[:, a]]
                np.add.at(tot, pairs[ok, a], colour[pairs[ok, b]])
                np.add.at(num, pairs[ok, a], 1)
            flip &= num > 0
            colour[flip] = tot[flip] / num[flip, None]
            mat[flip] = best[flip]
            flipped += int(flip.sum())
        self.report["cleaned"] = flipped
        style = np.array(self.styles, dtype=object)[mat]
        sq_class = np.zeros(nsq, np.int64)
        sq_class[sq] = t["square_class"]
        out = colour.copy()
        for m in range(MATERIALS):
            sel = mat == m
            if sel.any():
                st = STYLES[self.styles[m]]
                out[sel, 1:] = st["own"] * colour[sel, 1:] + (1 - st["own"]) * mids[m, 1:]
        # Lightness: each material's own variation round its middle stretched (its pattern, folds and
        # seams made bold, as the painting's are), a little clumped noise added so plain cloth isn't
        # flat, then snapped to its kind's steps. The stretch is halved till neighbouring squares of
        # one material differ as much as the kind asks (`jump`), up to STRETCH times.
        self.report["jump"] = {}
        mids_sq = np.array([np.median(colour[mat == m, 0]) if (mat == m).any() else 0.0 for m in range(MATERIALS)])
        for name, st in STYLES.items():
            sel = np.flatnonzero(style == name)
            if len(sel) < 2:
                continue
            Ls = colour[sel, 0]
            mid_L = mids_sq[mat[sel]]
            noise = clumped(centre[sel], st["clump"] * float(np.median(size[sel])), seed + len(name))
            # His head is drawn, not woven: its squares take less of the noise.
            noise = np.where(sq_class[sel] == 1, HEAD_MOTTLE, 1.0) * noise * DITHER * st["step"]
            pairs = neighbours(centre[sel], size[sel])
            pairs = pairs[mat[sel][pairs[:, 0]] == mat[sel][pairs[:, 1]]]
            step = st["step"]

            def pick(gain):
                return np.round((mid_L + gain * (Ls - mid_L) + noise) / step) * step

            def jump(L):
                return float(np.abs(L[pairs[:, 0]] - L[pairs[:, 1]]).mean()) if len(pairs) else 0.0

            lo, hi = 1.0, STRETCH
            if jump(pick(hi)) <= st["jump"]:
                lo = hi
            else:
                for _ in range(10):
                    mid = 0.5 * (lo + hi)
                    if jump(pick(mid)) < st["jump"]:
                        lo = mid
                    else:
                        hi = mid
            chosen = pick(lo)
            out[sel, 0] = chosen
            self.report["jump"][name] = {"squares": int(len(sel)), "before": round(jump(Ls), 2),
                                         "after": round(jump(chosen), 2), "stretch": round(lo, 2)}
        self.square_lab = out

    def textures(self):
        """The bold textures {shape: RGB image}, his eyes as they were, gaps between islands filled
        from the nearest texel."""
        t = self.t
        rgb = from_lab(self.square_lab[t["square"]])
        eyes = self.eye_mask()
        rgb[eyes] = t["rgb"][eyes]
        self.report["eye_texels"] = int(eyes.sum())
        out = {}
        for shape in np.unique(t["shape"]):
            sel = t["shape"] == shape
            img = np.zeros((self.man.size, self.man.size, 3))
            have = np.zeros((self.man.size, self.man.size), bool)
            img[t["row"][sel], t["col"][sel]] = rgb[sel]
            have[t["row"][sel], t["col"][sel]] = True
            _d, (ri, ci) = ndimage.distance_transform_edt(~have, return_indices=True)
            out[str(shape)] = np.clip(img[ri, ci], 0, 255)
        return out


# --- Running it -----------------------------------------------------------------------------------

def sheet(man, textures, out):
    """Him as he was and bold, front, three-quarter, side and back, and his face close: drawn here
    with no light, his textures' colours as they are."""
    before = {k: np.asarray(v.resize((man.size, man.size), Image.BILINEAR), dtype=float) for k, v in man.sources.items()}
    rows = []
    for view in VIEWS:
        a, box = draw(man.meshes, before, view, 300)
        b, _ = draw(man.meshes, textures, view, 300, box=box)
        rows.append(np.concatenate([a, np.full((a.shape[0], 4, 3), 20.0), b], axis=1))
    h = max(r.shape[0] for r in rows)
    body = np.concatenate([np.pad(r, ((0, h - r.shape[0]), (0, 12), (0, 0)), constant_values=20) for r in rows], axis=1)
    parts = [body]
    eyes = man.spec.get("eyes")
    if eyes:
        mid = np.mean(eyes, axis=0)
        box = (mid[0] - 0.12, mid[1] - 0.15, mid[0] + 0.12, mid[1] + 0.11)
        head = {k: m for k, m in man.meshes.items() if k != "body_skin"}
        a, _ = draw(head, before, "front", 1500, box=box)
        b, _ = draw(head, textures, "front", 1500, box=box)
        c, _ = draw(head, before, "three_quarter", 1500, box=(box[0] - 0.02, box[1], box[2] + 0.02, box[3]))
        d, _ = draw(head, textures, "three_quarter", 1500, box=(box[0] - 0.02, box[1], box[2] + 0.02, box[3]))
        face = np.concatenate([a, np.full((a.shape[0], 4, 3), 20.0), b, np.full((a.shape[0], 12, 3), 20.0), c,
                               np.full((a.shape[0], 4, 3), 20.0), d], axis=1)
        w = max(body.shape[1], face.shape[1])
        parts = [np.pad(body, ((0, 8), (0, w - body.shape[1]), (0, 0)), constant_values=20),
                 np.pad(face, ((0, 0), (0, w - face.shape[1]), (0, 0)), constant_values=20)]
    Image.fromarray(np.concatenate(parts, axis=0).astype(np.uint8)).save(out)


def eye_grid(man, out):
    """His face from the front with a centimetre grid, labelled every 5 cm: read his eyes off it."""
    head = man.meshes["body_head"]
    pos = head["pos"]
    front = pos[pos[:, 2] < np.percentile(pos[:, 2], 15)]
    cx = float(np.median(front[:, 0]))
    top = float(pos[:, 1].max())
    box = (cx - 0.12, top - 0.30, cx + 0.12, top - 0.02)
    tex = {k: np.asarray(v.resize((man.size, man.size), Image.BILINEAR), dtype=float) for k, v in man.sources.items()}
    img, _ = draw({"body_head": head}, tex, "front", 2500, box=box)
    im = Image.fromarray(img.astype(np.uint8))
    d = ImageDraw.Draw(im)
    for cm in range(int(np.ceil(box[0] * 100)), int(np.floor(box[2] * 100)) + 1):
        x = (cm / 100 - box[0]) * 2500
        d.line([(x, 0), (x, im.height)], fill=(0, 255, 255) if cm % 5 == 0 else (0, 90, 90))
        if cm % 5 == 0:
            d.text((x + 2, 2), "%.2f" % (cm / 100), fill=(0, 255, 255))
    for cm in range(int(np.ceil(box[1] * 100)), int(np.floor(box[3] * 100)) + 1):
        y = (box[3] - cm / 100) * 2500
        d.line([(0, y), (im.width, y)], fill=(255, 255, 0) if cm % 5 == 0 else (90, 90, 0))
        if cm % 5 == 0:
            d.text((2, y + 2), "%.2f" % (cm / 100), fill=(255, 255, 0))
    im.save(out)


def main():
    args = sys.argv[1:]
    only = None
    for a in args:
        if a.startswith("--only="):
            only = set(a.split("=", 1)[1].split(","))
    people = json.load(open(os.path.join(PEOPLE, "people.json")))["people"]
    for pid, spec in people.items():
        if spec.get("source") != "tripo" or (only and pid not in only):
            continue
        if not os.path.exists(os.path.join(PEOPLE, pid + ".glb")):
            print("%s: not fitted yet (tools/blender/fit_tripo.py)" % pid)
            continue
        man = Man(pid, spec, SIZE)
        if "--eye-grid" in args:
            os.makedirs(BUILD, exist_ok=True)
            eye_grid(man, os.path.join(BUILD, pid + "_eye_grid.png"))
            print("%s: his face with a grid in %s" % (pid, BUILD))
            continue
        if not spec.get("eyes"):
            print("%s: no eyes in people.json (measure them with --eye-grid)" % pid)
            continue
        man.gather()
        bold = Bold(man, spec["eyes"])
        bold.materials()
        bold.delight()
        bold.squares()
        bold.colours()
        textures = bold.textures()
        for shape, img in textures.items():
            Image.fromarray(img.astype(np.uint8)).save(os.path.join(PEOPLE, "%s_%s_bold.png" % (pid, shape)))
        report = {"id": pid, "size": SIZE, "eyes": [[round(float(v), 4) for v in e] for e in bold.eyes]}
        report.update(bold.report)
        json.dump(report, open(os.path.join(PEOPLE, pid + "_bold.json"), "w"), indent=1)
        print("%s: %d squares, face %.1f mm, cloth %.1f mm -> %s_*_bold.png" % (
            pid, bold.report["squares"], bold.report["face_square_mm"], bold.report["cloth_square_mm"], pid))
        if "--views" in args:
            os.makedirs(BUILD, exist_ok=True)
            sheet(man, textures, os.path.join(BUILD, pid + "_bold.png"))


if __name__ == "__main__":
    main()
