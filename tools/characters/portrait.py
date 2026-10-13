"""The portrait factory (docs/briefs/portrait-factory.md): a man's face from his pictures, projected
onto the character factory's shared base head.

    python3 tools/blender/fetch_makehuman.py                       # once: MakeHuman (CC0)
    ~/bpyenv/bin/python tools/characters/portrait.py fit --only=bold_cowboy      # targets + cameras
    ~/bpyenv/bin/python tools/characters/portrait.py paint --only=bold_cowboy    # his textures
    ~/bpyenv/bin/python tools/characters/portrait.py build --only=bold_cowboy    # bpy: the glb
    ~/bpyenv/bin/python tools/characters/portrait.py all --only=bold_cowboy

(~/bpyenv: python3.11 with bpy==5.0.1, numpy, pillow, scipy, mediapipe; MediaPipe needs libegl1.)

A man is an entry in assets/people/portrait.json: his pictures (front, left, right, back: plain,
hatless, flat light, grey ground, docs/concept/style/factory/<id>/) and a few settings. Steps:

  1. The base head: tools/blender/factory.py's (MakeHuman's base mesh with the small forms built in,
     one UV layout shared by every man, factory_build.head_layout).
  2. The fit: MediaPipe's face landmarks on his front picture and the same landmarks found once on
     a render of the plain base head (so each is a point on the mesh), and his profile's outline
     from each side picture; MakeHuman's face targets solved to match both (scipy least squares,
     weights bounded to the targets' ranges). The base head's targets and forms go on after the
     fit, so its exaggerations survive it.
  3. The cameras: each picture's scale and offset (orthographic), solved with the fit.
  4. The projection: every texel of the shared layout takes its colour from the picture facing it
     squarest (depth-tested), with a narrow feathered blend at the seams only.
  5. The de-light: each picture's shading fitted to the head's normals and divided out.
  6. Squares, once, last, in UV space: ~4 mm on the face, each one flat colour (the median), a
     limited palette per region; the eyes and mouth finer; features stamped where it's weak.
  7. The build: factory_build's route (our joints, envelope, 17 bones, garments) → assets/people/
     <id>_portrait.glb, with his hair, moustache and sideburns as a shell whose depth is the hull of
     his pictures' outlines.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "blender"))
import factory as F  # noqa: E402
import make_people as mp  # noqa: E402

PORTRAIT = "assets/people/portrait.json"
WORK = "build/portrait"             # intermediate pictures and the fit's working files
LANDMARKER = "build/mediapipe/face_landmarker.task"
LANDMARKER_URL = ("https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/"
                  "float16/1/face_landmarker.task")
VIEWS = ("front", "left", "right", "back")
# Each picture's camera: image right is `a` in body space (his right is +X, he faces -Z), depth
# (smaller is nearer) along `d`. left.png faces left: we see his left side (-X).
AXES = {"front": ((-1, 0, 0), (0, 0, 1)), "left": ((0, 0, 1), (1, 0, 0)),
        "right": ((0, 0, -1), (-1, 0, 0)), "back": ((1, 0, 0), (0, 0, -1))}


# --- Cameras and rasterising -------------------------------------------------------------------------

class Camera:
    """Orthographic: pixel = (s * (a . p) + tu, -s * y + tv), depth = d . p."""

    def __init__(self, view, s, tu, tv):
        self.view = view
        self.a = np.array(AXES[view][0], float)
        self.d = np.array(AXES[view][1], float)
        self.s, self.tu, self.tv = float(s), float(tu), float(tv)

    def project(self, p):
        p = np.asarray(p, float)
        return np.stack([self.s * (p @ self.a) + self.tu, -self.s * p[..., 1] + self.tv], -1)

    def depth(self, p):
        return np.asarray(p, float) @ self.d

    def toward(self):
        """The direction from him to the camera."""
        return -self.d

    def json(self):
        return {"view": self.view, "s": self.s, "tu": self.tu, "tv": self.tv}


def triangles(faces):
    """Quads and triangles (vertex id lists) → triangles (m, 3), and each one's face index."""
    tris, src = [], []
    for k, fv in enumerate(faces):
        for j in range(1, len(fv) - 1):
            tris.append((fv[0], fv[j], fv[j + 1]))
            src.append(k)
    return np.array(tris), np.array(src)


def rasterise(xy, depth, tris, w, h):
    """z-buffer: per pixel the nearest triangle's id (-1 for none) and its barycentrics (h, w, 3)."""
    zb = np.full((h, w), np.inf)
    tid = np.full((h, w), -1)
    bary = np.zeros((h, w, 3))
    for k, (i, j, l) in enumerate(tris):
        xs = np.array([xy[i, 0], xy[j, 0], xy[l, 0]])
        ys = np.array([xy[i, 1], xy[j, 1], xy[l, 1]])
        x0, x1 = int(max(0, math.floor(xs.min()))), int(min(w - 1, math.ceil(xs.max())))
        y0, y1 = int(max(0, math.floor(ys.min()))), int(min(h - 1, math.ceil(ys.max())))
        if x1 < x0 or y1 < y0:
            continue
        d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
        if abs(d) < 1e-12:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        w0 = ((ys[1] - ys[2]) * (gx - xs[2]) + (xs[2] - xs[1]) * (gy - ys[2])) / d
        w1 = ((ys[2] - ys[0]) * (gx - xs[2]) + (xs[0] - xs[2]) * (gy - ys[2])) / d
        w2 = 1 - w0 - w1
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        z = w0 * depth[i] + w1 * depth[j] + w2 * depth[l]
        sub = zb[y0:y1 + 1, x0:x1 + 1]
        win = inside & (z < sub)
        sub[win] = z[win]
        tid[y0:y1 + 1, x0:x1 + 1][win] = k
        bary[y0:y1 + 1, x0:x1 + 1][win] = np.stack([w0, w1, w2], -1)[win]
    return tid, bary, zb


# --- Landmarks ------------------------------------------------------------------------------------

_landmarker = None


def close_landmarker():
    """Close MediaPipe's landmarker (left to the interpreter's exit, it complains)."""
    global _landmarker
    if _landmarker is not None:
        _landmarker.close()
        _landmarker = None


def landmarks(img):
    """MediaPipe's 478 face landmarks on img (PIL RGB), in pixels (478, 3) (z in x's pixels), or None."""
    global _landmarker
    import mediapipe as mpipe
    from mediapipe.tasks import python as mpt
    from mediapipe.tasks.python import vision
    if _landmarker is None:
        if not os.path.exists(LANDMARKER):
            import urllib.request
            os.makedirs(os.path.dirname(LANDMARKER), exist_ok=True)
            urllib.request.urlretrieve(LANDMARKER_URL, LANDMARKER)
        _landmarker = vision.FaceLandmarker.create_from_options(vision.FaceLandmarkerOptions(
            base_options=mpt.BaseOptions(model_asset_path=LANDMARKER), num_faces=1,
            min_face_detection_confidence=0.1, min_face_presence_confidence=0.1))
    rgb = np.ascontiguousarray(np.asarray(img.convert("RGB")))
    found = _landmarker.detect(mpipe.Image(image_format=mpipe.ImageFormat.SRGB, data=rgb))
    if not found.face_landmarks:
        return None
    return np.array([(p.x * img.width, p.y * img.height, p.z * img.width) for p in found.face_landmarks[0]])


# --- The head's shape: MakeHuman's face targets, as the fit's parameters -----------------------------

TARGET_DIRS = ["head", "chin", "cheek", "nose", "mouth", "eyes", "eyebrows", "forehead", "ears"]
OPPOSITE = [("decr", "incr"), ("down", "up"), ("in", "out"), ("backward", "forward"),
            ("concave", "convex"), ("compress", "uncompress")]
# Not fitted: whole-head moves (the cameras do that), the nose's and mouth's sideways shifts, and
# the ear's forms (the base head's; only where the ear is and how big are his).
NOT_FITTED = ("head/head-trans-", "head/head-angle-", "nose/nose-trans-in", "nose/nose-trans-out",
              "mouth/mouth-trans-in", "mouth/mouth-trans-out", "ears/{s}-ear-wing", "ears/{s}-ear-flap",
              "ears/{s}-ear-shape", "ears/{s}-ear-lobe", "ears/{s}-ear-scale-depth")


# His build, fitted from his face as lone parameters on top of the default build: heavier, leaner,
# older (they move his whole body; the envelope fit holds that to ours afterwards).
BUILD = ["macrodetails/universal-male-young-averagemuscle-maxweight",
         "macrodetails/universal-male-young-averagemuscle-minweight", "macrodetails/caucasian-male-old"]


def fit_parameters():
    """The fit's parameters: [(name, negative target or None, positive target)], each target with
    "{s}" for both sides. A pair (decr/incr, down/up, ...) is one signed parameter in [-1, 1]; a
    lone target (head-oval) one in [0, 1]."""
    names = set()
    for d in TARGET_DIRS:
        for f in os.listdir(os.path.join(mp.MH, "targets", d)):
            if f.endswith(".target"):
                n = d + "/" + f[:-7]
                n = n.replace("/r-", "/{s}-").replace("/l-", "/{s}-")
                if not n.startswith(NOT_FITTED):
                    names.add(n)
    out, used = [], set()
    for n in sorted(names):
        if n in used:
            continue
        for neg, pos in OPPOSITE:
            stem = n.rsplit("-", 1)[0]
            if n == stem + "-" + neg and stem + "-" + pos in names:
                out.append((stem, n, stem + "-" + pos))
                used |= {n, stem + "-" + pos}
                break
            if n == stem + "-" + pos and stem + "-" + neg in names:
                out.append((stem, stem + "-" + neg, n))
                used |= {n, stem + "-" + neg}
                break
        else:
            out.append((n, None, n))
            used.add(n)
    return out + [(b, None, b) for b in BUILD]


class Shape:
    """A man's head as v0 + sum of parameters times their targets' moves (body space, metres; the
    ground shift MakeHuman's targets make is ignored: the cameras' offsets absorb it)."""

    def __init__(self, env, targets, ids):
        p = mp.Person("shape", {"targets": targets}, env)
        self.p = p
        self.ids = np.asarray(ids)           # the head's vertices (the fit only moves these)
        self.v0 = p.v.copy()
        self.params = fit_parameters()
        n = len(p.v)
        self.neg, self.pos = [], []
        for _name, neg, pos in self.params:
            self.neg.append(self._disp(neg, n) if neg else None)
            self.pos.append(self._disp(pos, n))
        self.lo = np.array([-1.0 if neg else 0.0 for _n, neg, _p in self.params])
        self.hi = np.ones(len(self.params))

    def _disp(self, name, n):
        d = sum(F.target_disp(t, n) for t in F.expand({name: 1.0}))
        return d[self.ids]

    def head(self, x):
        """The head's vertices for parameters x."""
        v = self.v0[self.ids].copy()
        pos, neg = split(np.asarray(x, float))
        for k in range(len(pos)):
            v += pos[k] * self.pos[k]
            if self.neg[k] is not None:
                v += neg[k] * self.neg[k]
        return v

    def targets(self, x, cut=0.005):
        """The parameters as MakeHuman targets {path: weight} ("{s}" kept; F.expand splits it)."""
        out = {}
        pw, nw = split(np.asarray(x, float))
        for (_name, neg, pos), a, b in zip(self.params, pw, nw):
            if a > cut:
                out[pos] = round(float(a), 4)
            if neg and b > cut:
                out[neg] = round(float(b), 4)
        return out


KINK = 0.05


def split(x):
    """A signed parameter → (its positive target's weight, its negative's), smoothed round 0 (a
    kink there stalls the solver): both ~0 at 0, x or -x away from it."""
    r = np.sqrt(x * x + KINK * KINK)
    return (x + r) / 2 - KINK / 2, (r - x) / 2 - KINK / 2


# --- Drawing the head (no Blender): for the landmark map and the previews -----------------------------

def vertex_normals(v, tris):
    n = np.zeros_like(v)
    fn = np.cross(v[tris[:, 1]] - v[tris[:, 0]], v[tris[:, 2]] - v[tris[:, 0]])
    for k in range(3):
        np.add.at(n, tris[:, k], fn)
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


def eye_colour(v, eye_ids, centre, forward=(0.0, 0.0, -1.0)):
    """Per-vertex colours for the eyeballs: white, a brown iris, a black pupil (for the landmark map's
    render: MediaPipe wants eyes)."""
    c = np.ones((len(v), 3)) * np.array([0.85, 0.82, 0.78])
    d = v[eye_ids] - centre
    d /= np.maximum(np.linalg.norm(d, axis=1, keepdims=True), 1e-9)
    ang = np.degrees(np.arccos(np.clip(d @ np.array(forward), -1, 1)))
    c[eye_ids] = np.where(ang[:, None] < 12, [0.05, 0.04, 0.03], np.where(ang[:, None] < 30, [0.30, 0.20, 0.12], [0.85, 0.82, 0.78]))
    return c


def render(v, tris, colours, cam, w, h, light=(-0.3, 0.4, -1.0), ambient=0.35):
    """A shaded picture (h, w, 3) floats of the triangles, per-vertex colours, smooth normals; and
    the raster (triangle ids, barycentrics, depth) it was drawn from."""
    xy = cam.project(v)
    depth = cam.depth(v)
    tid, bary, zb = rasterise(xy, depth, tris, w, h)
    n = vertex_normals(v, tris)
    L = np.array(light, float)
    L /= np.linalg.norm(L)
    shade = ambient + (1 - ambient) * np.clip(n @ L, 0, 1)
    col = colours * shade[:, None]
    img = np.full((h, w, 3), 0.5)
    hit = tid >= 0
    t = tris[tid[hit]]
    b = bary[hit]
    img[hit] = (col[t[:, 0]] * b[:, :1] + col[t[:, 1]] * b[:, 1:2] + col[t[:, 2]] * b[:, 2:3])
    return img, (tid, bary, zb)


def to_pil(img):
    return Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8))


# --- The head's vertices and faces ----------------------------------------------------------------------

# A man's build below the face when portrait.json doesn't say (the factory's lean hard man's).
DEFAULT_MACRO = {
    "macrodetails/caucasian-male-young": 0.6,
    "macrodetails/caucasian-male-old": 0.4,
    "macrodetails/universal-male-young-maxmuscle-averageweight": 0.35,
    "macrodetails/universal-male-young-averagemuscle-minweight": 0.3,
}


class Head:
    """Which of MakeHuman's vertices and faces are the head (a little below the neck joint, as the
    factory's layout cuts it, and the eyeballs), as local triangles."""

    def __init__(self, person):
        p = person
        v = p.v
        lo = p.j["neck"][1] - 0.04
        self.faces = [f[0] for f in p.body_faces if (v[f[0], 1] > lo).all()]
        self.eye_faces = {s: [f[0] for f in p.groups["helper-%s-eye" % s]] for s in "rl"}
        allf = self.faces + self.eye_faces["r"] + self.eye_faces["l"]
        self.ids = np.array(sorted({i for f in allf for i in f}))
        local = {g: k for k, g in enumerate(self.ids)}
        self.local = local
        self.tris, self.tri_face = triangles([[local[i] for i in f] for f in allf])
        self.n_skin_tris = len(triangles([[local[i] for i in f] for f in self.faces])[0])
        self.eye_ids = {s: np.array(sorted({local[i] for f in self.eye_faces[s] for i in f})) for s in "rl"}
        self.eye_centre = {s: v[self.ids][self.eye_ids[s]].mean(0) for s in "rl"}


def head_camera(v, view, size, fill=0.82):
    """A camera framing the head's vertices v in a size x size picture."""
    cam = Camera(view, 1.0, 0.0, 0.0)
    xy = cam.project(v)
    lo, hi = xy.min(0), xy.max(0)
    s = fill * size / max(hi - lo)
    c = (lo + hi) / 2 * s
    return Camera(view, s, size / 2 - c[0], size / 2 - c[1])


def landmark_map(env, macro, out=WORK):
    """MediaPipe's landmarks as points on the mesh: found once on a render of the plain head (his
    build, no face targets), each landmark the triangle under it and its barycentrics. Cached in
    build/portrait/landmark_map.json; the render beside it."""
    path = os.path.join(out, "landmark_map.json")
    if os.path.exists(path):
        m = json.load(open(path))
        return np.array(m["tri"]), np.array(m["bary"])
    os.makedirs(out, exist_ok=True)
    p = mp.Person("plain", {"targets": macro}, env)
    head = Head(p)
    v = p.v[head.ids]
    size = 1024
    cam = head_camera(v[: len(v)], "front", size, fill=0.62)
    col = np.ones((len(v), 3)) * np.array([0.78, 0.6, 0.48])
    for s in "rl":
        col[head.eye_ids[s]] = eye_colour(v, head.eye_ids[s], head.eye_centre[s])[head.eye_ids[s]]
    img, (tid, bary, _zb) = render(v, head.tris, col, cam, size, size)
    pic = to_pil(img)
    pic.save(os.path.join(out, "landmark_map_render.png"))
    lm = landmarks(pic)
    if lm is None:
        raise SystemExit("portrait: MediaPipe found no face on the plain head's render")
    px = np.clip(lm[:, :2].astype(int), 0, size - 1)
    tri = tid[px[:, 1], px[:, 0]]
    b = bary[px[:, 1], px[:, 0]]
    # A landmark that fell between triangles (or off the head) takes its nearest hit pixel's.
    hit = np.argwhere(tid >= 0)
    for k in np.where(tri < 0)[0]:
        j = np.argmin(((hit - px[k, ::-1]) ** 2).sum(1))
        tri[k] = tid[hit[j][0], hit[j][1]]
        b[k] = bary[hit[j][0], hit[j][1]]
    json.dump({"tri": tri.tolist(), "bary": np.round(b, 5).tolist(), "note": "triangles of Head.tris (plain head)"},
              open(path, "w"))
    return tri, b


def at_landmarks(v, tris, tri, bary):
    """The landmarks' points on a head (v: the head's local vertices)."""
    t = tris[tri]
    return (v[t[:, 0]] * bary[:, :1] + v[t[:, 1]] * bary[:, 1:2] + v[t[:, 2]] * bary[:, 2:3])


# --- His pictures ---------------------------------------------------------------------------------------

def euler(yaw, pitch, roll):
    """A rotation (degrees): yaw about y, pitch about x, roll about z."""
    a, b, c = (math.radians(t) for t in (yaw, pitch, roll))
    ry = np.array([[math.cos(a), 0, math.sin(a)], [0, 1, 0], [-math.sin(a), 0, math.cos(a)]])
    rx = np.array([[1, 0, 0], [0, math.cos(b), -math.sin(b)], [0, math.sin(b), math.cos(b)]])
    rz = np.array([[math.cos(c), -math.sin(c), 0], [math.sin(c), math.cos(c), 0], [0, 0, 1]])
    return ry @ rx @ rz


class PoseCamera(Camera):
    """A Camera that sees him turned a little (each picture's pose): p → R p first."""

    def __init__(self, view, s, tu, tv, yaw=0.0, pitch=0.0, roll=0.0):
        super().__init__(view, s, tu, tv)
        self.yaw, self.pitch, self.roll = float(yaw), float(pitch), float(roll)
        self.R = euler(yaw, pitch, roll)

    def project(self, p):
        return super().project(np.asarray(p, float) @ self.R.T)

    def depth(self, p):
        return super().depth(np.asarray(p, float) @ self.R.T)

    def toward(self):
        return self.R.T @ -self.d

    def json(self):
        out = super().json()
        out.update(yaw=round(self.yaw, 3), pitch=round(self.pitch, 3), roll=round(self.roll, 3))
        return out

    @staticmethod
    def of(j):
        return PoseCamera(j["view"], j["s"], j["tu"], j["tv"], j.get("yaw", 0), j.get("pitch", 0), j.get("roll", 0))


class Pictures:
    """His four plain pictures, as floats, with the ground (grey) told apart from him."""

    def __init__(self, folder):
        self.folder = folder
        self.img = {}
        for v in VIEWS:
            self.img[v] = np.asarray(Image.open(os.path.join(folder, v + ".png")).convert("RGB")).astype(float) / 255.0
        self.h, self.w = self.img["front"].shape[:2]

    def ground(self, view):
        """The ground's colour (the corners' median) and how far each pixel is from it."""
        a = self.img[view]
        k = 40
        corners = np.concatenate([a[:k, :k], a[:k, -k:]]).reshape(-1, 3)
        g = np.median(corners, 0)
        return g, np.linalg.norm(a - g, axis=2)

    def him(self, view, tol=0.06):
        """Pixels that are him, not the ground (bool, h x w), holes filled."""
        from scipy import ndimage
        _g, dist = self.ground(view)
        m = ndimage.binary_opening(dist > tol, iterations=2)
        m = ndimage.binary_fill_holes(m)
        lab, n = ndimage.label(m)
        if n > 1:
            sizes = ndimage.sum(m, lab, range(1, n + 1))
            m = lab == (1 + int(np.argmax(sizes)))
        return m


def front_edge(him, faces_left):
    """Per row, the column of his outline's front (the first pixel of him from the side he faces), or -1."""
    h, w = him.shape
    any_ = him.any(1)
    if faces_left:
        col = np.argmax(him, 1)
    else:
        col = w - 1 - np.argmax(him[:, ::-1], 1)
    return np.where(any_, col, -1)


def ear_blob(skin, face_col, band, faces_left):
    """His ear in a side picture: the biggest patch of skin within the rows `band` (eye to the
    nose's foot) that isn't joined to his face (the skin at his outline's front), as its centroid
    (x, y) in pixels, or None."""
    from scipy import ndimage
    r0, r1 = band
    m = np.zeros_like(skin)
    m[r0:r1] = skin[r0:r1]
    lab, n = ndimage.label(m)
    if n == 0:
        return None
    face = set()
    for r in range(r0, r1):
        c = face_col[r]
        if c >= 0:
            seg = lab[r, c:c + 12] if faces_left else lab[r, max(0, c - 11):c + 1]
            face |= set(seg[seg > 0].tolist())
    sizes = ndimage.sum(m, lab, range(1, n + 1))
    best = [k for k in np.argsort(-sizes) + 1 if k not in face and sizes[k - 1] >= 300]
    if not best:
        return None
    ys, xs = np.nonzero(lab == best[0])
    return np.array([xs.mean(), ys.mean()])


class Colours:
    """Skin and hair colours, sampled from his front picture by the landmarks, as Gaussians: each
    pixel told skin or hair by which is likelier."""

    # MediaPipe landmarks on the cheeks, the nose's bridge, the forehead's middle.
    SKIN = [50, 280, 101, 330, 6, 197, 195, 151, 9, 108, 337, 117, 346]

    def __init__(self, pics, lm):
        a = pics.img["front"]
        samples = []
        for i in self.SKIN:
            x, y = int(lm[i, 0]), int(lm[i, 1])
            samples.append(a[y - 6:y + 7, x - 6:x + 7].reshape(-1, 3))
        skin = np.concatenate(samples)
        # Hair: above the forehead's top landmark to the top of his outline, in the middle third.
        him = pics.him("front")
        top = int(np.argmax(him[:, int(lm[10, 0])]))
        y1 = int(lm[10, 1]) - int(0.25 * (lm[10, 1] - top))
        x0, x1 = int(lm[10, 0] - 0.12 * pics.w), int(lm[10, 0] + 0.12 * pics.w)
        hair = a[top + 10:y1, x0:x1].reshape(-1, 3)
        # And the back of his head (all hair, unless he's bald): the middle third, from the top of
        # his outline down a fifth of the picture.
        b = pics.img["back"]
        hb = pics.him("back")
        cols_b = np.where(hb.any(0))[0]
        if len(cols_b):
            cx = int((cols_b.min() + cols_b.max()) / 2)
            tb = int(np.argmax(hb[:, cx]))
            back = b[tb + 15:tb + int(0.2 * pics.h), cx - int(0.08 * pics.w):cx + int(0.08 * pics.w)].reshape(-1, 3)
            hair = np.concatenate([hair, back])
        self.skin_mean, self.skin_cov = skin.mean(0), np.cov(skin.T) + np.eye(3) * 1e-4
        self.hair_mean, self.hair_cov = hair.mean(0), np.cov(hair.T) + np.eye(3) * 1e-4

    @staticmethod
    def _logp(a, m, c):
        d = a - m
        ci = np.linalg.inv(c)
        return -0.5 * np.einsum("...i,ij,...j->...", d, ci, d) - 0.5 * math.log(np.linalg.det(c))

    def likelihood(self, a, which):
        """Log-likelihood of each colour under the skin's or the hair's Gaussian."""
        return self._logp(a, getattr(self, which + "_mean"), getattr(self, which + "_cov"))

    def hair(self, a):
        """How hair-like each pixel is (0..1)."""
        lh = self._logp(a, self.hair_mean, self.hair_cov)
        ls = self._logp(a, self.skin_mean, self.skin_cov)
        return 1.0 / (1.0 + np.exp(np.clip(ls - lh, -50, 50)))


# --- The fit ----------------------------------------------------------------------------------------------

# MediaPipe's lip landmarks: a moustache hides the upper lip, so they count less.
LIPS = [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 185, 40, 39, 37, 0, 267, 269, 270, 409, 78, 95,
        88, 178, 87, 14, 317, 402, 318, 324, 308, 191, 80, 81, 82, 13, 312, 311, 310, 415]
LIP_WEIGHT = 0.3
EAR_WEIGHT = 2.0      # the ear's centre (one point, but it alone says how deep his head is)
REG = 0.0025          # a parameter at 1 costs as much as a landmark 2.5 mm off
ROBUST_M = 0.003      # residuals past this count less (soft L1): a stray outline row or landmark
                      # can't hold the solve (plain least squares stalled on them)
POSE_LIMIT = 15.0     # degrees the front picture may turn him
SIDE_YAW_LIMIT = 5.0  # and a side picture about the vertical (they're true profiles)


def profile_points(v, lm_pts):
    """The plain head's profile (local ids): its midline's front-most vertex every 2.5 mm, from the
    chin to a centimetre over the brow."""
    mid = np.where(np.abs(v[:, 0]) < 1e-4)[0]
    y0, y1 = lm_pts[152, 1], lm_pts[9, 1] + 0.01
    keep = []
    for y in np.arange(y0, y1, 0.0025):
        sel = mid[(v[mid, 1] >= y) & (v[mid, 1] < y + 0.0025)]
        if len(sel):
            keep.append(int(sel[np.argmin(v[sel, 2])]))
    return np.array(sorted(set(keep)))


def fit(man, spec, env, out):
    """Solve his face targets and each picture's camera; writes <out>/<man>_fit.json and overlays."""
    from scipy.optimize import least_squares
    pics = Pictures(spec["pictures"])
    macro = spec.get("macro", DEFAULT_MACRO)
    tri, bary = landmark_map(env, macro)
    plain = mp.Person("plain", {"targets": macro}, env)
    head = Head(plain)
    shape = Shape(env, macro, head.ids)
    lm = landmarks(Image.fromarray((pics.img["front"] * 255).astype(np.uint8)))
    if lm is None:
        raise SystemExit("portrait: no face found in %s/front.png" % spec["pictures"])
    cols = Colours(pics, lm)
    v_plain = shape.head(np.zeros(len(shape.params)))
    lm_plain = at_landmarks(v_plain, head.tris, tri, bary)
    prof = profile_points(v_plain, lm_plain)
    K = len(shape.params)

    def verts(x):
        pos, neg = split(x)
        return v0 + np.tensordot(pos, Dp, 1) + np.tensordot(neg, Dn, 1)

    def lms(vv):
        return (vv[t_local[:, 0]] * bary[:, :1] + vv[t_local[:, 1]] * bary[:, 1:2] + vv[t_local[:, 2]] * bary[:, 2:3])

    # Each side picture's outline: per row, his front's column, where it's skin (not hair, not ground).
    edges = {}
    for view, faces_left in (("left", True), ("right", False)):
        him = pics.him(view)
        col = front_edge(him, faces_left)
        a = pics.img[view]
        ok = np.zeros(len(col), bool)
        for r in np.where(col >= 0)[0]:
            c0 = col[r] + (4 if faces_left else -12)
            patch = a[r, max(0, c0):c0 + 8]
            ok[r] = len(patch) > 0 and cols.hair(patch).mean() < 0.5
        edges[view] = (col, ok)
    # His ears: the model's (the vertices MakeHuman's ear target moves) and each side picture's.
    nv = len(plain.v)
    body = np.zeros(nv)
    body[sorted({i for f in plain.body_faces for i in f[0]})] = 1.0
    ear_ids = {}
    for side in "rl":
        w = F.region("ears/%s-ear-wing-incr" % side, nv, body)[head.ids]
        ear_ids[side] = np.where(w > 0.3)[0]
    # Only the vertices the residuals need: the landmarks' triangles', the profile's, the ears'.
    need = np.array(sorted(set(head.tris[tri].ravel()) | set(prof) | set(np.concatenate(list(ear_ids.values())))))
    at = {g: k for k, g in enumerate(need)}
    t_local = np.vectorize(at.get)(head.tris[tri])
    p_local = np.array([at[i] for i in prof])
    e_local = {side: np.array([at[i] for i in ear_ids[side]]) for side in "rl"}
    v0 = v_plain[need]
    Dp = np.stack([d[need] for d in shape.pos])
    Dn = np.stack([d[need] if d is not None else np.zeros((len(need), 3)) for d in shape.neg])
    # Starting cameras: the front by a similarity of the plain head's landmarks onto his.
    P0 = lm_plain[:, [0, 1]] * np.array([-1, -1])
    A = np.c_[P0, np.ones(len(P0))]
    su = np.linalg.lstsq(A[:, [0, 2]], lm[:, 0], rcond=None)[0]
    sv = np.linalg.lstsq(A[:, [1, 2]], lm[:, 1], rcond=None)[0]
    s0 = float((su[0] + sv[0]) / 2)
    cam0 = {"front": [s0, su[1], sv[1], 0, 0, 0]}
    # Each side picture is framed on its own (they're tighter than the front): its scale and height
    # from MediaPipe's rough landmarks there (the nose's root to the chin), its offset from the nose.
    for view in ("left", "right"):
        col, ok = edges[view]
        lp = landmarks(Image.fromarray((pics.img[view] * 255).astype(np.uint8)))
        k = (lp[152, 1] - lp[168, 1]) / (lm[152, 1] - lm[168, 1]) if lp is not None else 1.0
        s = s0 * k
        tv = (lp[168, 1] if lp is not None else lm[168, 1]) + s * lm_plain[168, 1]
        c = PoseCamera(view, s, 0, tv)
        r = int(np.clip(c.project(lm_plain[1:2])[0, 1], 0, len(col) - 1))
        tu = col[r] - c.project(lm_plain[1:2])[0, 0]
        cam0[view] = [s, tu, tv, 0, 0, 0]
    ears = {}
    for view, side, faces_left in (("left", "l", True), ("right", "r", False)):
        s, tu, tv = cam0[view][:3]
        c = PoseCamera(view, s, tu, tv)
        band = (int(c.project(lm_plain[168:169])[0, 1]), int(c.project(lm_plain[2:3])[0, 1]))
        skin = pics.him(view) & (cols.hair(pics.img[view]) < 0.5)
        ears[view] = (side, ear_blob(skin, edges[view][0], band, faces_left))
    names = ["front", "left", "right"]

    # The solver's camera parameters are near 1 (its step tolerance is relative): the scale over
    # s0, the offsets in metres (pixels over s0), the turns in tens of degrees.
    unit = np.array([s0, s0, s0, 10.0, 10.0, 10.0])

    def unpack(z):
        x = z[:K]
        cams = {n: PoseCamera(n, *(z[K + 6 * i:K + 6 * i + 6] * unit)) for i, n in enumerate(names)}
        return x, cams

    w_lm = np.ones(len(lm))
    w_lm[LIPS] = LIP_WEIGHT

    def residuals(z):
        x, cams = unpack(z)
        vv = verts(x)
        sf = cams["front"].s
        r = [((cams["front"].project(lms(vv)) - lm[:, :2]) / sf * w_lm[:, None]).ravel()]
        for view in ("left", "right"):
            c = cams[view]
            col, ok = edges[view]
            uv = c.project(vv[p_local])
            # The outline between rows, linearly (a step per row stalls the solver), weighted by how
            # much of it there is skin.
            y = np.clip(uv[:, 1], 0, len(col) - 2)
            r0 = np.floor(y).astype(int)
            f = y - r0
            good = ok & (col >= 0)
            wgt = good[r0] * (1 - f) + good[r0 + 1] * f
            edge = np.where(good[r0], col[r0], col[r0 + 1]) * (1 - f) + np.where(good[r0 + 1], col[r0 + 1], col[r0]) * f
            r.append(wgt * (uv[:, 0] - edge) / c.s)
            side, blob = ears[view]
            if blob is not None:
                r.append((c.project(vv[e_local[side]]).mean(0) - blob) / c.s * EAR_WEIGHT)
        r.append(REG * x)
        return np.concatenate([np.ravel(a) for a in r])

    z0 = np.concatenate([np.zeros(K)] + [np.array(cam0[n], float) / unit for n in names])
    lim = [[POSE_LIMIT] * 3, [SIDE_YAW_LIMIT, POSE_LIMIT, POSE_LIMIT], [SIDE_YAW_LIMIT, POSE_LIMIT, POSE_LIMIT]]
    lo = np.concatenate([shape.lo] + [np.array([0.4 * s0, -1e5, -1e5] + [-a for a in l]) / unit for l in lim])
    hi = np.concatenate([shape.hi] + [np.array([2.5 * s0, 1e5, 1e5] + l) / unit for l in lim])
    z0 = np.clip(z0, lo + 1e-9, hi - 1e-9)
    r0 = residuals(z0)
    # Restarted from its own answer while that still helps (a fresh trust region each time: the
    # outlines' rows make the cost a little rough, and it can stall short of the bottom).
    z = z0.copy()
    best = None
    for _round in range(4):
        res = least_squares(residuals, z, bounds=(lo, hi), x_scale=1.0, diff_step=1e-4, max_nfev=300,
                            xtol=1e-15, ftol=1e-10, gtol=1e-10, loss="soft_l1", f_scale=ROBUST_M)
        if best is not None and res.cost > best.cost * 0.99:
            best = res if res.cost < best.cost else best
            break
        best = res
        z = res.x
    res = best
    x, cams = unpack(res.x)
    print("portrait: solver:", res.message)
    r1 = res.fun
    nf = 2 * len(lm)
    report = {"landmarks_mm": round(float(np.sqrt(np.mean(r1[:nf] ** 2)) * 1000), 2),
              "landmarks_mm_before": round(float(np.sqrt(np.mean(r0[:nf] ** 2)) * 1000), 2),
              "cost": round(float(res.cost), 6), "evaluations": int(res.nfev),
              "ears": {v: {"picture": np.round(ears[v][1], 1).tolist(),
                           "model": np.round(cams[v].project(verts(x)[e_local[ears[v][0]]]).mean(0), 1).tolist()}
                       for v in ears if ears[v][1] is not None}}
    # The back picture: the front's scale and height, centred on his outline at the ears.
    him = pics.him("back")
    cf = cams["front"]
    r_eye, r_chin = int(cf.project(lm_plain[168:169])[0, 1]), int(cf.project(lm_plain[152:153])[0, 1])
    centre = np.mean([np.where(him[r])[0].mean() for r in range(r_eye, r_chin) if him[r].any()])
    back = PoseCamera("back", cf.s, 0.0, cf.tv)
    back.tu = float(centre - back.project(np.array([[0.0, 0.0, 0.0]]))[0, 0])
    cams["back"] = back
    fit_out = {"man": man, "macro": macro, "targets": shape.targets(x), "x": [round(float(a), 4) for a in x],
               "cameras": {k: c.json() for k, c in cams.items()}, "report": report,
               "skin": [round(float(c), 4) for c in cols.skin_mean],
               "hair": [round(float(c), 4) for c in cols.hair_mean],
               "skin_cov": np.round(cols.skin_cov, 6).tolist(), "hair_cov": np.round(cols.hair_cov, 6).tolist()}
    os.makedirs(out, exist_ok=True)
    json.dump(fit_out, open(os.path.join(out, man + "_fit.json"), "w"), indent=1)
    print("portrait: fitted", man, json.dumps(report))
    return fit_out


def overlay(man, spec, env, fitted, out, size=420):
    """Each picture with the fitted head drawn over it, half and half, side by side → <out>/<man>_fit.jpg."""
    pics = Pictures(spec["pictures"])
    plain = mp.Person("plain", {"targets": fitted["macro"]}, env)
    head = Head(plain)
    shape = Shape(env, fitted["macro"], head.ids)
    v = shape.head(np.array(fitted["x"]))
    col = np.ones((len(v), 3)) * np.array([0.9, 0.75, 0.6])
    tiles = []
    for view in VIEWS:
        cam = PoseCamera.of(fitted["cameras"][view])
        img, (tid, _b, _z) = render(v, head.tris, col, cam, pics.w, pics.h)
        a = pics.img[view].copy()
        hit = tid >= 0
        a[hit] = 0.45 * a[hit] + 0.55 * img[hit]
        # The outline of the head over the picture, in green.
        from scipy import ndimage
        edge = hit & ~ndimage.binary_erosion(hit, iterations=2)
        a[edge] = [0.1, 1.0, 0.2]
        tiles.append(to_pil(a).resize((size, size)))
    sheet = Image.new("RGB", (size * len(tiles), size))
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * size, 0))
    sheet.save(os.path.join(out, man + "_fit.jpg"), quality=88)


# --- The shared layout, and his head in it --------------------------------------------------------------

def layout(env):
    """The factory's head layout (laid out once from the base head by Blender, shared by every man):
    {face's vertex ids: [(u, v) per corner]} (v down) and the islands' rects. Cached as JSON."""
    path = os.path.join(WORK, "layout.json")
    if os.path.exists(path):
        j = json.load(open(path))
        return {tuple(f): [tuple(c) for c in uv] for f, uv in j["table"]}, {k: tuple(r) for k, r in j["rects"].items()}
    import factory_build as FB  # noqa: E402  (bpy)
    base = FB.Base(env, F.load_factory())
    table, rects, _isl, _faces, _scale = FB.head_layout(base)
    os.makedirs(WORK, exist_ok=True)
    json.dump({"table": [[list(f), [list(c) for c in uv]] for f, uv in table.items()],
               "rects": {k: list(r) for k, r in rects.items()}}, open(path, "w"))
    return table, rects


def man_targets(fitted, with_base):
    """His MakeHuman targets: his build, the fit's face targets, and (with_base) the base head's."""
    out = {}
    blocks = [fitted["macro"], fitted["targets"]] + ([F.load_factory()["base"]["targets"]] if with_base else [])
    for b in blocks:
        for t, w in F.expand(b).items():
            out[t] = out.get(t, 0.0) + w
    return out


def raster_uv(table, faces, values, size):
    """Per-vertex values (n, k) over the layout → (size, size, k) and the texels covered (factory_build's
    raster, without bpy)."""
    k = values.shape[1]
    out = np.zeros((size, size, k))
    mask = np.zeros((size, size), bool)
    for fv in faces:
        uvs = table.get(tuple(fv))
        if uvs is None:
            continue
        for t in [(0, 1, 2)] + ([(0, 2, 3)] if len(fv) == 4 else []):
            Pp = np.array([uvs[i] for i in t]) * size
            val = values[[fv[i] for i in t]]
            x0, x1 = int(max(0, math.floor(Pp[:, 0].min()) - 1)), int(min(size - 1, math.ceil(Pp[:, 0].max()) + 1))
            y0, y1 = int(max(0, math.floor(Pp[:, 1].min()) - 1)), int(min(size - 1, math.ceil(Pp[:, 1].max()) + 1))
            if x1 < x0 or y1 < y0:
                continue
            gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
            (ax, ay), (bx, by), (cx, cy) = Pp
            d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
            if abs(d) < 1e-12:
                continue
            w0 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / d
            w1 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / d
            w2 = 1 - w0 - w1
            pad = 1.5 / max(abs(d) ** 0.5, 1e-6)
            inside = (w0 >= -pad) & (w1 >= -pad) & (w2 >= -pad)
            sub = out[y0:y1 + 1, x0:x1 + 1]
            sm = mask[y0:y1 + 1, x0:x1 + 1]
            fill = inside & ~sm | ((w0 >= 0) & (w1 >= 0) & (w2 >= 0))
            sub[fill] = (w0[fill, None] * val[0] + w1[fill, None] * val[1] + w2[fill, None] * val[2])
            sm[fill] = True
    return out, mask


def sample(a, x, y):
    """a (h, w, c) at float pixel coordinates (bilinear, clamped)."""
    h, w = a.shape[:2]
    x = np.clip(x - 0.5, 0, w - 1.001)
    y = np.clip(y - 0.5, 0, h - 1.001)
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    fx, fy = (x - x0)[..., None], (y - y0)[..., None]
    return (a[y0, x0] * (1 - fx) * (1 - fy) + a[y0, x0 + 1] * fx * (1 - fy)
            + a[y0 + 1, x0] * (1 - fx) * fy + a[y0 + 1, x0 + 1] * fx * fy)


# --- Projecting his pictures ---------------------------------------------------------------------------

HEAD_TEX = 1024
SEAM = 0.04           # the feathered band at a seam: a view this much less square than the best weighs 1/e
DEPTH_TOL = 0.004     # metres: a texel this far behind the nearest surface in a picture isn't seen there
MIN_FACING = 0.08     # a picture never paints a texel it sees edge-on


# Which pictures may paint each ear (his hair hides them from the front): his left ear is seen in
# left.png (he faces left: his left side is toward you), his right in right.png.
EAR_VIEWS = {"ear_l": ("left", "back"), "ear_r": ("right", "back")}


def project(pics, cams, person, table, size=HEAD_TEX, rects=None):
    """His pictures on the shared layout: each texel's colour from the picture facing it squarest,
    feathered only where two are nearly as square. Returns the colours, the texels covered, each
    texel's position and normal, and per view its weight (for the de-light)."""
    faces = list(table.keys())
    v = person.v
    tris, _src = triangles([list(f) for f in faces])
    n_v = vertex_normals(v, tris)
    M, cover = raster_uv(table, faces, np.concatenate([v, n_v], 1), size)
    P = M[..., :3]
    N = M[..., 3:]
    N /= np.maximum(np.linalg.norm(N, axis=-1, keepdims=True), 1e-9)
    idx = np.nonzero(cover)
    p, n = P[idx], N[idx]
    score, colour = {}, {}
    # A picture only paints what lands inside his outline there (a little in from its edge: the
    # ground's grey bleeds into the edge's pixels).
    from scipy import ndimage
    inside = {view: ndimage.binary_erosion(pics.him(view), iterations=3) for view in VIEWS}
    for view in VIEWS:
        cam = cams[view]
        xy = cam.project(v)
        _tid, _b, zb = rasterise(xy, cam.depth(v), tris, pics.w, pics.h)
        from scipy import ndimage
        zb = ndimage.minimum_filter(zb, size=3)
        q = cam.project(p)
        qi = np.clip(q.astype(int), 0, [pics.w - 1, pics.h - 1])
        seen = cam.depth(p) <= zb[qi[:, 1], qi[:, 0]] + DEPTH_TOL
        seen &= inside[view][qi[:, 1], qi[:, 0]]
        f = n @ cam.toward()
        allowed = np.ones(len(p), bool)
        for isl, views in (EAR_VIEWS.items() if rects else ()):
            if view not in views:
                x, y, w, h = rects[isl]
                allowed &= ~((idx[1] >= x * size - 1) & (idx[1] <= (x + w) * size + 1)
                             & (idx[0] >= y * size - 1) & (idx[0] <= (y + h) * size + 1))
        score[view] = np.where(seen & allowed & (f > MIN_FACING), f, -np.inf)
        colour[view] = sample(pics.img[view], q[:, 0], q[:, 1])
    S = np.stack([score[v_] for v_ in VIEWS])
    best = S.max(0)
    W = np.where(np.isfinite(S), np.exp((S - best[None]) / SEAM), 0.0)
    W /= np.maximum(W.sum(0, keepdims=True), 1e-9)
    weights = {v_: W[k] for k, v_ in enumerate(VIEWS)}
    return colour, weights, (idx, P, N, cover), np.isfinite(best)


def delight(colour, weights, n, skin, strength=1.0):
    """Each picture's shading taken out: its skin's brightness fitted as a + b . normal (the pictures
    are lit flat, but not evenly) and divided out, so the game's light is the only light."""
    out = {}
    lum = np.array([0.2126, 0.7152, 0.0722])
    report = {}
    for view, c in colour.items():
        y = c @ lum
        sel = (weights[view] > 0.5) & skin
        if sel.sum() < 200:
            out[view] = c
            continue
        A = np.c_[np.ones(sel.sum()), n[sel]]
        coef = np.linalg.lstsq(A, y[sel], rcond=None)[0]
        for _ in range(3):   # robust: drop the worst fifth (dark creases, highlights) and fit again
            r = np.abs(A @ coef - y[sel])
            keep = r < np.percentile(r, 80)
            coef = np.linalg.lstsq(A[keep], y[sel][keep], rcond=None)[0]
        shade = np.c_[np.ones(len(n)), n] @ coef
        mean = float(np.median(shade[sel]))
        k = np.clip(shade / max(mean, 1e-6), 0.6, 1.6) ** strength
        out[view] = np.clip(c / k[:, None], 0, 1)
        report[view] = [round(float(x), 3) for x in coef]
    return out, report


def render_textured(v, table, tex, cam, w, h, light=(-0.35, 0.45, -1.0), ambient=0.45, bg=0.5):
    """The head (the layout's faces) drawn with its texture (nearest texel), lit by one light."""
    faces = list(table.keys())
    tris, src = triangles([list(f) for f in faces])
    corner = []
    for f in faces:
        uv = table[f]
        for j in range(1, len(f) - 1):
            corner.append((uv[0], uv[j], uv[j + 1]))
    corner = np.array(corner)
    tid, bary, _zb = rasterise(cam.project(v), cam.depth(v), tris, w, h)
    n = vertex_normals(v, tris)
    L = np.array(light, float)
    L /= np.linalg.norm(L)
    img = np.full((h, w, 3), bg)
    hit = tid >= 0
    t = tid[hit]
    b = bary[hit]
    uv = (corner[t] * b[:, :, None]).sum(1)
    size = tex.shape[0]
    ui = np.clip((uv * size).astype(int), 0, size - 1)
    col = tex[ui[:, 1], ui[:, 0], :3]
    nn = (n[tris[t]] * b[:, :, None]).sum(1)
    nn /= np.maximum(np.linalg.norm(nn, axis=1, keepdims=True), 1e-9)
    shade = ambient + (1 - ambient) * np.clip(nn @ L, 0, 1)
    img[hit] = col * shade[:, None]
    return img


def views_sheet(v, table, tex, path, size=360, yaws=(0, 35, 90)):
    """The head from the front, three-quarter and side, textured → path."""
    tiles = []
    for yaw in yaws:
        cam = PoseCamera("front", 1, 0, 0, yaw, 0, 0)
        xy = cam.project(v[list({i for f in table for i in f})])
        lo, hi = xy.min(0), xy.max(0)
        s = 0.86 * size / max(hi - lo)
        cam = PoseCamera("front", s, size / 2 - (lo[0] + hi[0]) / 2 * s, size / 2 - (lo[1] + hi[1]) / 2 * s, yaw, 0, 0)
        tiles.append(to_pil(render_textured(v, table, tex, cam, size, size)))
    sheet = Image.new("RGB", (size * len(tiles), size))
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * size, 0))
    sheet.save(path, quality=90)


def paint(man, spec, env, fitted, out):
    """His head's texture on the shared layout: projected, de-lit, then squared (squares())."""
    table, rects = layout(env)
    pics = Pictures(spec["pictures"])
    cams = {k: PoseCamera.of(c) for k, c in fitted["cameras"].items()}
    plain = mp.Person(man, {"targets": man_targets(fitted, False)}, env)
    colour, weights, (idx, P, N, cover), seen = project(pics, cams, plain, table, rects=rects)
    n = N[idx]
    cols = Colours.__new__(Colours)
    cols.skin_mean, cols.hair_mean = np.array(fitted["skin"]), np.array(fitted["hair"])
    cols.skin_cov, cols.hair_cov = np.array(fitted["skin_cov"]), np.array(fitted["hair_cov"])
    hairy = sum(weights[v_] * cols.hair(colour[v_]) for v_ in VIEWS)
    lit, rep = delight(colour, weights, n, hairy < 0.5, spec.get("delight", 1.0))
    c = sum(weights[v_][:, None] * lit[v_] for v_ in VIEWS)
    tex = np.zeros((HEAD_TEX, HEAD_TEX, 3))
    tex[idx] = c
    # What no picture sees (under the jaw, inside the ears' folds): the nearest seen texel's colour.
    from scipy import ndimage
    have = np.zeros((HEAD_TEX, HEAD_TEX), bool)
    have[idx] = seen
    _d, (iy, ix) = ndimage.distance_transform_edt(~have, return_indices=True)
    tex = tex[iy, ix]
    # Below his jaw the pictures show his collar: what isn't skin or hair there is skin (the
    # nearest skin texel's).
    tri, bary = landmark_map(env, fitted["macro"])
    head = Head(plain)
    chin_y = at_landmarks(plain.v[head.ids], head.tris, tri, bary)[152, 1]
    pix = tex[idx]
    lik = np.maximum(cols.likelihood(pix, "skin"), cols.likelihood(pix, "hair"))
    below = P[idx][:, 1] < chin_y - 0.004
    skinlike = cols.likelihood(pix, "skin") > cols.likelihood(pix, "hair")
    # The front and sides of his neck: skin. The nape (his hair hangs over it): hair stays.
    low = P[idx][:, 1] < chin_y - 0.025
    neckish = below & (((N[idx][:, 2] < 0.3) & ~skinlike) | (lik < -6.0) | (low & ~skinlike))
    good = np.zeros((HEAD_TEX, HEAD_TEX), bool)
    good[idx] = ~neckish & skinlike
    _d, (gy, gx) = ndimage.distance_transform_edt(~good, return_indices=True)
    fill = tex[gy, gx]
    tex[idx[0][neckish], idx[1][neckish]] = fill[idx[0][neckish], idx[1][neckish]]
    tex[~cover] = tex[cover].mean(0)
    os.makedirs(out, exist_ok=True)
    to_pil(tex).save(os.path.join(out, man + "_projected.png"))
    best = np.argmax(np.stack([weights[v_] for v_ in VIEWS]), 0)
    vmap = np.zeros((HEAD_TEX, HEAD_TEX, 3))
    pal = np.array([[0.9, 0.3, 0.3], [0.3, 0.9, 0.3], [0.3, 0.3, 0.9], [0.9, 0.9, 0.3]])
    vmap[idx] = pal[best] * np.where(seen, 1.0, 0.2)[:, None]
    to_pil(vmap).save(os.path.join(out, man + "_which_view.png"))
    final = mp.Person(man, {"targets": man_targets(fitted, True)}, env)
    F.shape_base(final, F.load_factory()["base"]["forms"])
    views_sheet(final.v, table, tex, os.path.join(out, man + "_projected_views.jpg"))
    # The regions (each its own palette) and the fine zones round the eyes and mouth.
    nv = len(plain.v)
    body = np.zeros(nv)
    body[sorted({i for f in plain.body_faces for i in f[0]})] = 1.0
    lips = np.maximum(F.region("mouth/mouth-upperlip-volume-incr", nv, body),
                      F.region("mouth/mouth-lowerlip-volume-incr", nv, body))
    Mr, _c = raster_uv(table, list(table.keys()), lips[:, None], HEAD_TEX)
    hair_t = np.zeros((HEAD_TEX, HEAD_TEX))
    hair_t[idx] = np.where(neckish, 0.0, hairy)
    hair_t = hair_t[iy, ix]
    eyes = np.zeros((HEAD_TEX, HEAD_TEX), bool)
    for k in ("eye_r", "eye_l"):
        x, y, w, h = rects[k]
        eyes[int(y * HEAD_TEX):int((y + h) * HEAD_TEX) + 1, int(x * HEAD_TEX):int((x + w) * HEAD_TEX) + 1] = True
    eyes &= cover
    hair_m = (hair_t > 0.5) & cover & ~eyes
    lips_m = (Mr[..., 0] > 0.35) & cover & ~eyes & ~hair_m
    regions = {"eye": eyes, "hair": hair_m, "lips": lips_m, "skin": cover & ~eyes & ~hair_m & ~lips_m}
    zones = np.zeros((HEAD_TEX, HEAD_TEX), bool)
    centres = [plain.v[sorted({i for f in plain.groups["helper-%s-eye" % sd] for i in f[0]})].mean(0) for sd in "rl"]
    for c in centres:
        d = (P - c) / np.array([0.024, 0.016, 0.03])
        zones |= (d ** 2).sum(-1) < 1
    m = plain.j["mouth"]
    zones |= (((P - (m + np.array([0, -0.004, -0.01]))) / np.array([0.032, 0.016, 0.04])) ** 2).sum(-1) < 1
    zones &= cover
    lm = landmarks(Image.fromarray((pics.img["front"] * 255).astype(np.uint8)))
    iris_c, white_c = eye_colours(pics.img["front"], lm)
    eye_ids = [sorted({i for f in plain.groups["helper-%s-eye" % sd] for i in f[0]}) for sd in "rl"]
    # The skin: the picture's highlights clipped, its pores smoothed (at the face's texel size).
    skin_m = regions["skin"] | regions["lips"]
    lum = tex @ np.array([0.2126, 0.7152, 0.0722])
    top = np.percentile(lum[skin_m], HIGHLIGHT)
    over = skin_m & (lum > top)
    tex[over] *= (top / lum[over])[:, None]
    x, y, w, h = rects["face"]
    fy0, fy1, fx0, fx1 = int(y * HEAD_TEX), int((y + h) * HEAD_TEX), int(x * HEAD_TEX), int((x + w) * HEAD_TEX)
    sub = cover[fy0:fy1, fx0:fx1 - 1] & cover[fy0:fy1, fx0 + 1:fx1]
    mpt = float(np.median(np.linalg.norm(P[fy0:fy1, fx0 + 1:fx1] - P[fy0:fy1, fx0:fx1 - 1], axis=-1)[sub]))
    tex = smooth_region(tex, regions["skin"], SMOOTH_M / mpt)
    nb = np.zeros(nv)
    nb[sorted({i for f in plain.body_faces for i in f[0]})] = 1.0
    wn = F.region("nose/nose-nostrils-width-incr", nv, nb)
    vn = vertex_normals(plain.v, triangles([f[0] for f in plain.body_faces])[0])
    nostrils = []
    for sx in (1.0, -1.0):
        sel = (wn > 0.15) & (vn[:, 1] < -0.3) & (plain.v[:, 0] * sx > 0.0035)
        if sel.sum() >= 3:
            nostrils.append((plain.v[sel] * wn[sel, None]).sum(0) / wn[sel].sum())
    tex = stamp_nostrils(tex, P, N, cover, nostrils, np.array(spec.get("nostril", [0.16, 0.08, 0.06])))
    lid_c = np.array(spec.get("lid", [0.13, 0.08, 0.06]))
    tex = stamp_eyes(tex, P, cover, eyes, [plain.v[e] for e in eye_ids], iris_c, white_c, lid_c)
    regions["lid"] = np.zeros_like(cover)
    # `"squares": false` in portrait.json: the smooth-faced man (the brief's route 4), no squares.
    sq = squares(tex, cover, P, rects, zones, regions)[0] if spec.get("squares", True) else tex
    to_pil(sq).save(os.path.join(out, man + "_head.png"))
    # His hair's shell: where the hair is (not his brows: they're painted), as deep as his outlines.
    hv = hair_vertices(table, np.where(cover, hair_t, 0.0), HEAD_TEX, nv)
    vn_all = vertex_normals(plain.v, triangles([list(f) for f in table])[0])
    eye_y = float(np.mean([c[1] for c in centres]))
    brow = (plain.v[:, 1] < eye_y + 0.035) & (plain.v[:, 1] > eye_y - 0.01) & (np.abs(plain.v[:, 0]) < 0.055) \
        & (vn_all[:, 2] < -0.5)
    edges = neighbours([list(f) for f in table], nv)
    hv = mesh_smooth(hv, edges, 3)
    # Where a shell may be: his scalp, sides and back (round from straight ahead past SIDE_DEG, or
    # over his brow), and his moustache (between his nose and mouth); his stubble stays painted.
    vv = plain.v
    hc = vv[sorted({i for f in table for i in f})].mean(0)
    az = np.degrees(np.abs(np.arctan2(vv[:, 0] - hc[0], -(vv[:, 2] - hc[2]))))
    mouth = plain.j["mouth"]
    tash = (np.abs(vv[:, 0] - mouth[0]) < 0.034) & (vv[:, 1] > mouth[1] - 0.022) & (vv[:, 1] < mouth[1] + 0.022) \
        & (vn_all[:, 2] < -0.3)
    allowed = ((az > SIDE_DEG) | (vv[:, 1] > eye_y + 0.035) | tash) & (vv[:, 1] > chin_y - 0.03)
    mask = mesh_islands((hv > 0.5) & ~brow & allowed, edges, HAIR_ISLAND)
    ids = np.where(mask)[0]
    d_all = np.zeros(nv)
    d_all[ids] = hull_depth(pics, cams, plain.v, vn_all, ids)
    d_all = mesh_smooth(d_all, edges, 8, only=mask)
    d_all *= np.clip(edge_hops(mask, edges, 3) / 3.0, 0.0, 1.0) * 0.8 + 0.2
    depth = np.maximum(d_all[ids], HAIR_MIN_M)
    depth[tash[ids]] = np.minimum(depth[tash[ids]], TASH_MAX_M)
    under_hat = plain.v[ids, 1] > eye_y + HAT_BAND_M
    depth[under_hat] = np.minimum(depth[under_hat], UNDER_HAT_M)
    json.dump({"note": "per vertex (MakeHuman ids): how far his hair's shell stands off his skin (m)",
               "depth": {int(i): round(float(d), 4) for i, d in zip(ids, depth)}},
              open(os.path.join(out, man + "_hair.json"), "w"))
    # The shell's own picture: the pictures projected onto its outside (the same layout).
    shell = mp.Person.__new__(mp.Person)
    shell.v = plain.v.copy()
    shell.v[ids] += vn_all[ids] * depth[:, None]
    hcol, hw, (hidx, HP, HN, hcover), hseen = project(pics, cams, shell, table, rects=rects)
    hc = sum(hw[v_][:, None] * hcol[v_] for v_ in VIEWS)
    htex = np.zeros((HEAD_TEX, HEAD_TEX, 3))
    htex[hidx] = hc
    hhave = np.zeros((HEAD_TEX, HEAD_TEX), bool)
    hhave[hidx] = hseen
    _d, (yy, xx) = ndimage.distance_transform_edt(~hhave, return_indices=True)
    htex = htex[yy, xx]
    hregions = {"hair": hcover}
    hsq = squares(htex, hcover, HP, rects, np.zeros_like(hcover), hregions)[0] if spec.get("squares", True) else htex
    to_pil(hsq).save(os.path.join(out, man + "_hair.png"))
    print("portrait: hair shell", len(ids), "vertices, depth mm median %.1f max %.1f" % (np.median(depth) * 1000, depth.max() * 1000))
    views_sheet(final.v, table, sq, os.path.join(out, man + "_views.jpg"))
    print("portrait: painted", man, "de-light", json.dumps(rep))
    return sq


# --- Feature stamps: where the projection is weak ------------------------------------------------------

IRIS_M = 0.0058       # the iris's radius on the eyeball
PUPIL_M = 0.0024
LID_M = 0.0022        # the upper lid's line: this far out from the eyeball's surface
LID_LOWER_M = 0.0012


def eye_colours(img, lm):
    """His iris and whites from his front picture: the iris the median inside MediaPipe's iris
    landmarks (468-477), the whites the brightest third of the rest of each eye's opening."""
    from PIL import ImageDraw
    h, w = img.shape[:2]
    iris, white = [], []
    rings = {468: [33, 246, 161, 160, 159, 158, 157, 173, 133, 155, 154, 153, 145, 144, 163, 7],
             473: [263, 466, 388, 387, 386, 385, 384, 398, 362, 382, 381, 380, 374, 373, 390, 249]}
    yy, xx = np.mgrid[0:h, 0:w]
    for c, ring in rings.items():
        r = np.mean([np.linalg.norm(lm[c + k, :2] - lm[c, :2]) for k in range(1, 5)])
        d = np.hypot(xx - lm[c, 0], yy - lm[c, 1])
        mask = Image.new("L", (w, h), 0)
        ImageDraw.Draw(mask).polygon([tuple(lm[i, :2]) for i in ring], fill=255)
        opening = np.asarray(mask) > 0
        iris.append(img[opening & (d < 0.7 * r)])
        rest = img[opening & (d > 1.1 * r)]
        if len(rest):
            y = rest.sum(1)
            white.append(rest[y >= np.percentile(y, 66)])
    iris = np.median(np.concatenate(iris), 0)
    white = np.median(np.concatenate(white), 0) if white else np.array([0.75, 0.7, 0.62])
    return iris, white


def stamp_eyes(tex, P, cover, eyes, balls, iris_c, white_c, lid_c):
    """On the eyeballs: the white, the iris (a darker ring), the pupil and a glint, looking straight
    ahead (by distance across the front: an eyeball's back half shares its front's UVs). Round
    each opening: the upper lid's dark line and a softer lower one (face texels within LID_M of
    the eyeball)."""
    from scipy.spatial import cKDTree
    out = tex.copy()
    for ball in balls:
        c = ball.mean(0)
        d = P - c
        across = np.hypot(d[..., 0], d[..., 1])
        on = eyes & (np.linalg.norm(d, axis=-1) < 0.03)
        col = np.where((across < IRIS_M)[..., None], iris_c, white_c)
        col = np.where(((across < IRIS_M) & (across > IRIS_M * 0.78))[..., None], iris_c * 0.6, col)
        col = np.where((across < PUPIL_M)[..., None], np.array([0.03, 0.025, 0.02]), col)
        glint = np.hypot(d[..., 0] - 0.0018 * np.sign(c[0] or 1), d[..., 1] - 0.0022) < 0.0011
        col = np.where(glint[..., None], np.array([0.92, 0.9, 0.85]), col)
        out[on] = col[on]
        dist, _i = cKDTree(ball).query(P[cover & ~eyes])
        near = np.zeros_like(cover)
        near[cover & ~eyes] = dist < LID_M
        front = d[..., 2] < -0.004
        upper = near & front & (d[..., 1] > -0.001)
        lower = near & front & (d[..., 1] <= -0.001)
        out[upper] = lid_c
        out[lower] = out[lower] * 0.6 + lid_c * 0.4
    return out


NOSTRIL_M = 0.0032     # the nostrils' dark: this radius round each
SMOOTH_M = 0.0015      # the skin's pores and fine creases smoothed away before the squares
HIGHLIGHT = 97         # skin brighter than this percentile is a highlight in the picture: clipped


def stamp_nostrils(tex, P, N, cover, centres, colour):
    """The nostrils' dark, under the nose round each nostril's middle (the factory's nostril cut)."""
    out = tex.copy()
    for c in centres:
        r = np.linalg.norm(P - c, axis=-1)
        k = np.clip(1.0 - (r - NOSTRIL_M * 0.5) / (NOSTRIL_M * 0.5), 0, 1) * (N[..., 1] < 0.3) * cover
        out = out * (1 - k[..., None]) + colour * k[..., None]
    return out


def smooth_region(tex, mask, sigma):
    """A Gaussian blur of tex inside mask only (normalised: nothing bleeds in from outside it)."""
    from scipy import ndimage
    m = mask.astype(float)
    num = np.stack([ndimage.gaussian_filter(tex[..., k] * m, sigma) for k in range(3)], -1)
    den = ndimage.gaussian_filter(m, sigma)[..., None]
    out = tex.copy()
    out[mask] = (num / np.maximum(den, 1e-6))[mask]
    return out


# --- His hair as a shell: the hull of his pictures' outlines ------------------------------------------

HAIR_MAX_M = 0.045     # the most a shell stands off his skin
HAIR_MIN_M = 0.003     # and the least (where there's hair at all)
HAT_BAND_M = 0.035     # above his eyes by this, the hat sits: the hair there stays thin
UNDER_HAT_M = 0.005
HULL_STEP_M = 0.0015
SIDE_DEG = 62          # degrees round from straight ahead: past this, his side (sideburns, hair)
TASH_MAX_M = 0.008
HAIR_ISLAND = 40       # a patch of hair smaller than this many vertices is painted, not a shell


def hair_vertices(table, hair_t, size, nv):
    """Per vertex of the layout's faces, the share of hair at its corners (0..1)."""
    tot = np.zeros(nv)
    cnt = np.zeros(nv)
    for f, uvs in table.items():
        for i, (u, v) in zip(f, uvs):
            x, y = min(size - 1, int(u * size)), min(size - 1, int(v * size))
            tot[i] += hair_t[y, x]
            cnt[i] += 1
    return tot / np.maximum(cnt, 1)


def neighbours(faces, nv):
    """Edges of the faces as two index arrays (both directions)."""
    e = set()
    for f in faces:
        for i in range(len(f)):
            a, b = f[i], f[(i + 1) % len(f)]
            e.add((a, b))
            e.add((b, a))
    e = np.array(sorted(e))
    return e[:, 0], e[:, 1]


def mesh_smooth(x, edges, steps, only=None):
    """Each step, every vertex (of `only`) takes the mean of itself and its neighbours."""
    a, b = edges
    x = x.astype(float).copy()
    deg = np.bincount(a, minlength=len(x)).astype(float)
    for _ in range(steps):
        s = np.bincount(a, weights=x[b], minlength=len(x))
        y = (x + s) / (1 + deg)
        x = y if only is None else np.where(only, y, x)
    return x


def mesh_islands(mask, edges, min_size):
    """mask without its connected pieces smaller than min_size vertices."""
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import connected_components
    a, b = edges
    keep = mask[a] & mask[b]
    g = coo_matrix((np.ones(keep.sum()), (a[keep], b[keep])), shape=(len(mask), len(mask)))
    _n, lab = connected_components(g, directed=False)
    sizes = np.bincount(lab[mask], minlength=lab.max() + 1)
    return mask & (sizes[lab] >= min_size)


def edge_hops(mask, edges, most):
    """How many edges each masked vertex is from the mask's edge (0 on it), up to `most`."""
    a, b = edges
    hops = np.where(mask, most, 0).astype(float)
    edge = np.zeros(len(mask), bool)
    np.logical_or.at(edge, a, mask[a] & ~mask[b])
    hops[edge] = 0
    for _ in range(most):
        nb = np.full(len(mask), np.inf)
        np.minimum.at(nb, a, hops[b])
        hops = np.where(mask, np.minimum(hops, nb + 1), 0)
    return hops


def hull_depth(pics, cams, v, n, ids):
    """How far out along its normal each vertex can stand and still be inside his outline in every
    picture (the visual hull), from 0 to HAIR_MAX_M."""
    from scipy import ndimage
    masks = {view: ndimage.binary_dilation(pics.him(view), iterations=2) for view in VIEWS}
    depth = np.zeros(len(ids))
    alive = np.ones(len(ids), bool)
    for t in np.arange(HULL_STEP_M, HAIR_MAX_M + 1e-9, HULL_STEP_M):
        q = v[ids] + n[ids] * t
        inside = np.ones(len(ids), bool)
        for view in VIEWS:
            uv = cams[view].project(q)
            x = np.clip(uv[:, 0].astype(int), 0, pics.w - 1)
            y = np.clip(uv[:, 1].astype(int), 0, pics.h - 1)
            inside &= masks[view][y, x]
        alive &= inside
        depth[alive] = t
    return depth


# --- Squares, once, last ---------------------------------------------------------------------------------

SQUARE_M = 0.004      # a square on his face: half the world's 8 mm
FINE_M = 0.002        # round his eyes and mouth
EYEBALL_M = 0.0015    # on the eyeballs
PALETTE = {"skin": 10, "hair": 6, "lips": 5, "eye": 5}


def kmeans(x, k, iters=12, seed=0):
    """Plain k-means: k colours for the rows of x (for a region's palette)."""
    rng = np.random.default_rng(seed)
    if len(x) <= k:
        return x.copy()
    c = x[rng.choice(len(x), k, replace=False)]
    for _ in range(iters):
        d = ((x[:, None] - c[None]) ** 2).sum(-1)
        lab = d.argmin(1)
        for j in range(k):
            if (lab == j).any():
                c[j] = x[lab == j].mean(0)
    return c


def squares(tex, cover, P, rects, zones, regions):
    """tex cut into squares in UV space, each the median of its texels: SQUARE_M on him, FINE_M
    where `zones` (bool, texels) says, EYEBALL_M on the eyeballs; then each square snapped to its
    region's palette (regions: {name: bool texels}). Returns the squared texture and its square ids."""
    size = tex.shape[0]
    out = tex.copy()
    ids = np.full((size, size), -1)
    nid = 0
    # Metres per texel, per island (the layout scales each island to its own density).
    dP = np.linalg.norm(np.diff(P, axis=1), axis=-1)
    ok = cover[:, 1:] & cover[:, :-1]
    for name, (x, y, w, h) in rects.items():
        x0, y0 = int(x * size), int(y * size)
        x1, y1 = min(size, int((x + w) * size) + 2), min(size, int((y + h) * size) + 2)
        sub_ok = ok[y0:y1, x0:min(x1, size - 1)]
        if not sub_ok.any():
            continue
        mpt = float(np.median(dP[y0:y1, x0:min(x1, size - 1)][sub_ok]))
        steps = [EYEBALL_M] if name.startswith("eye_") else [SQUARE_M, FINE_M]
        for k, step_m in enumerate(steps):
            step = max(1, int(round(step_m / max(mpt, 1e-9))))
            for by in range(y0, y1, step):
                for bx in range(x0, x1, step):
                    blk = (slice(by, min(by + step, y1)), slice(bx, min(bx + step, x1)))
                    cv = cover[blk]
                    if not cv.any():
                        continue
                    if k == 1 and not zones[blk][cv].mean() > 0.5:
                        continue
                    out[blk] = np.median(tex[blk][cv], 0)
                    ids[blk] = nid
                    nid += 1
    # The palette: each region's colours (k-means of its squares'), every square snapped to the
    # nearest of them all (a region told wrong, a grey moustache taken for skin, keeps its colour).
    pals = []
    for name, m in regions.items():
        sel = m & (ids >= 0)
        if sel.any():
            _u, first = np.unique(ids[sel], return_index=True)
            pals.append(kmeans(out[sel][first], PALETTE.get(name, 8)))
    if pals:
        pal = np.concatenate(pals)
        sel = ids >= 0
        u, first = np.unique(ids[sel], return_index=True)
        cols = out[sel][first]
        lab = ((cols[:, None] - pal[None]) ** 2).sum(-1).argmin(1)
        lut = np.zeros((ids.max() + 1, 3))
        lut[u] = pal[lab]
        out[sel] = lut[ids[sel]]
    return out, ids


# --- Running it -------------------------------------------------------------------------------------------

def men(only=None):
    m = json.load(open(PORTRAIT))["men"]
    return [(k, s) for k, s in m.items() if not only or k in only.split(",")]


def main():
    args = sys.argv[1:]
    step = args[0] if args and not args[0].startswith("--") else "all"
    only = next((a.split("=", 1)[1] for a in args if a.startswith("--only=")), None)
    env = json.load(open(mp.ENVELOPE))
    for man, spec in men(only):
        fpath = os.path.join(WORK, man + "_fit.json")
        if step in ("fit", "all"):
            fitted = fit(man, spec, env, WORK)
            overlay(man, spec, env, fitted, WORK)
        fitted = json.load(open(fpath))
        if step in ("paint", "all"):
            paint(man, spec, env, fitted, WORK)
        if step in ("build", "all"):
            import portrait_build  # noqa: E402  (needs bpy)
            portrait_build.build(man, spec, env, fitted)
    close_landmarker()


if __name__ == "__main__":
    main()
