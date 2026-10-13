"""The UV portrait, step 2: the head's texture layout (docs/briefs/uv-portrait.md; Sean, 2026-10-13).

    python3 tools/characters/uv_layout.py --man=bold_cowboy     # numpy (bpy for the factory man)

The layout is made so the image model can read every patch as a picture of him:

- **The face** is one patch, made by looking straight at him (orthographic, from the front): as an
  image it is a straight-on portrait. It holds every face of the head that turns less than
  FACE_TURN from the front, between the hairline and under the chin and not on the ears, joined
  to the nose; then every hole in it filled (the nose's underside, the lids' insides, the
  mouth's line: seen from the front they're where a portrait has them), and the eyeballs. Its
  edges, where the surface turns away, are the seams: the hairline, down the sideburns, under the
  jaw. Nothing crosses the face.
- **The rest**, each its own patch seen from its own side (orthographic): his right side, his
  left side, the back, the crown from above, the throat from in front and below, and each ear
  from its side. Each remaining face goes to the view it faces most squarely, then the patches
  are tidied (a face takes its neighbours' patch when most of them are in another) so each is
  one clean piece.
- Every patch at the same density (texels a metre), packed into one HEAD_TEX atlas, the face first
  and largest. A patch's texel is a point on his surface where that patch's camera sees it, so a
  painting made from that camera drops straight in.

→ build/uv_head/<man>_layout.npz (each face's corner UVs, its patch, each patch's camera and
rect), <man>_layout.json (the patches, their sizes, how much each is stretched), and the
checkpoint's pictures: <man>_checker.png (the atlas: an 8 mm checker per patch, the square size),
<man>_face_patch.png (the face patch alone, the head shaded in it: a straight-on portrait),
<man>_layout_views.png (the checker on the head, from five sides).
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "blender"))
import portrait as P  # noqa: E402
import uv_head as U  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
WORK = U.WORK
HEAD_TEX = 1024
FACE_TURN = 60.0      # degrees: the face patch holds what turns less than this from the front
HAIRLINE_UP = 0.05    # metres above MediaPipe's forehead top (landmark 10) the face may reach (the
                      # seam up there is where his forehead turns into the crown: his fringe is
                      # painted from the front, as the portraits have it)
CLOSE_TURN = 72.0     # notches in the face patch's edge closed where the surface turns less than this
CHIN_DOWN = 0.03      # metres under the chin (landmark 152) the face may reach
EAR_IN = 0.25         # an ear's region weight from which a face is the ear's
CHECK = 0.008         # the checker's squares: the face's squares, 8 mm
GAP = 10              # texels between patches
SMOOTH = 6            # rounds of normal smoothing before faces are sorted into patches
# Each patch's camera: image right is `a`, image up is `up` (orthographic; depth along a x up).
VIEWS = {
    "face": ((-1, 0, 0), (0, 1, 0)),
    "right": ((0, 0, -1), (0, 1, 0)),      # from his right (+X): his face to the image's right
    "left": ((0, 0, 1), (0, 1, 0)),        # from his left: his face to the image's left
    "back": ((1, 0, 0), (0, 1, 0)),
    "crown": ((-1, 0, 0), (0, 0, -1)),     # from above, his brow at the top
    "throat": ((-1, 0, 0), (0, 0.6, 0.8)),  # from in front and below
    "ear_r": ((0, 0, -1), (0, 1, 0)),
    "ear_l": ((0, 0, 1), (0, 1, 0)),
}
# The way each of the rest looks at him (toward the camera from him), for sorting faces.
FACING = {"right": (1, 0, 0), "left": (-1, 0, 0), "back": (0, 0, 1), "crown": (0, 1, 0),
          "throat": (0, -0.8, -0.6)}
ORDER = ["face", "right", "left", "back", "crown", "throat", "ear_r", "ear_l"]


def toward(view):
    """The direction from him to a patch's camera."""
    a, up = (np.array(x, float) for x in VIEWS[view])
    up /= np.linalg.norm(up)
    return np.cross(a, up)


def face_normals(v, faces):
    """Each face's normal (Newell's, so quads that aren't flat are fair) and middle."""
    n = np.zeros((len(faces), 3))
    c = np.zeros((len(faces), 3))
    for k, f in enumerate(faces):
        p = v[f]
        q = np.roll(p, -1, 0)
        n[k] = [((p[:, 1] - q[:, 1]) * (p[:, 2] + q[:, 2])).sum(),
                ((p[:, 2] - q[:, 2]) * (p[:, 0] + q[:, 0])).sum(),
                ((p[:, 0] - q[:, 0]) * (p[:, 1] + q[:, 1])).sum()]
        c[k] = p.mean(0)
    # Newell's sum is twice the area along -normal for our winding: point it out of the head.
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
    out = c - c.mean(0)
    if (n * out).sum() < 0:
        n = -n
    return n, c


def face_adjacency(faces):
    """Pairs of faces sharing an edge."""
    by_edge = {}
    for k, f in enumerate(faces):
        for i in range(len(f)):
            e = tuple(sorted((f[i], f[(i + 1) % len(f)])))
            by_edge.setdefault(e, []).append(k)
    nb = [[] for _ in faces]
    for ks in by_edge.values():
        for a in ks:
            for b in ks:
                if a != b:
                    nb[a].append(b)
    return nb


def grow(seed, ok, nb):
    """The faces reachable from seed through faces where ok."""
    out = np.zeros(len(ok), bool)
    stack = [seed]
    while stack:
        k = stack.pop()
        if out[k] or not ok[k]:
            continue
        out[k] = True
        stack += nb[k]
    return out


def components(mask, nb):
    lab = -np.ones(len(mask), int)
    n = 0
    for k in np.nonzero(mask)[0]:
        if lab[k] >= 0:
            continue
        stack = [k]
        while stack:
            j = stack.pop()
            if lab[j] >= 0 or not mask[j]:
                continue
            lab[j] = n
            stack += nb[j]
        n += 1
    return lab, n


def smooth_normals(n, nb, rounds):
    """Each face's normal averaged with its neighbours', a few rounds: patch edges follow the
    head's broad turn, not each little face's."""
    for _ in range(rounds):
        s = n.copy()
        for k, js in enumerate(nb):
            if js:
                s[k] += n[js].sum(0)
        n = s / np.maximum(np.linalg.norm(s, axis=1, keepdims=True), 1e-12)
    return n


def assign(v, faces, n, c, lm, ear_w):
    """Each head face's patch (a name), the face patch first (see the module's note)."""
    nb = face_adjacency(faces)
    n = smooth_normals(n, nb, SMOOTH)
    m = len(faces)
    label = np.array([""] * m, dtype=object)
    ear_f = np.array([ear_w[f].mean() for f in faces])
    side = np.sign(c[:, 0])
    ears = ear_f > EAR_IN
    label[ears & (side > 0)] = "ear_r"
    label[ears & (side <= 0)] = "ear_l"
    facing = n @ toward("face")
    hair_y, chin_y = lm[10, 1] + HAIRLINE_UP, lm[152, 1] - CHIN_DOWN
    ok = (facing > np.cos(np.radians(FACE_TURN))) & (c[:, 1] < hair_y) & (c[:, 1] > chin_y) & ~ears
    nose = int(np.argmin(np.where(ok, np.linalg.norm(c - lm[1], axis=1), np.inf)))
    face = grow(nose, ok, nb)
    # Holes in it (the nose's underside, the lids' insides, the lips' line) are face too: every
    # piece of the rest but the biggest (the head round it) and the ears.
    lab, k = components(~face & ~ears, nb)
    if k > 1:
        sizes = np.bincount(lab[lab >= 0], minlength=k)
        outer = sizes.argmax()
        face |= (lab >= 0) & (lab != outer)
    # Notches closed: a face most of whose neighbours are face, turning less than CLOSE_TURN.
    near = (facing > np.cos(np.radians(CLOSE_TURN))) & ~ears & (c[:, 1] < hair_y)
    for _ in range(4):
        add = np.array([near[k] and not face[k] and sum(face[j] for j in nb[k]) * 2 > len(nb[k])
                        for k in range(m)])
        if not add.any():
            break
        face |= add
    label[face] = "face"
    rest = label == ""
    names = list(FACING)
    score = np.stack([n @ (np.array(FACING[k_]) / np.linalg.norm(FACING[k_])) for k_ in names], 1)
    label[rest] = np.array(names, dtype=object)[score[rest].argmax(1)]
    print("before tidying:", {k_: int((label == k_).sum()) for k_ in ORDER})
    # Tidy: a face of the rest takes the patch most of its neighbours are in, a few rounds; then
    # small islands of a patch join the patch round them.
    for _ in range(4):
        new = label.copy()
        for i in np.nonzero(rest)[0]:
            ls = [label[j] for j in nb[i] if rest[j]]
            if ls:
                best = max(set(ls), key=ls.count)
                if ls.count(best) > len(ls) / 2:
                    new[i] = best
        label = new
    for name in names:
        lab, k = components(label == name, nb)
        if k <= 1:
            continue
        sizes = np.bincount(lab[lab >= 0], minlength=k)
        for piece in range(k):
            if piece == sizes.argmax():
                continue
            ids = np.nonzero(lab == piece)[0]
            around = [label[j] for i in ids for j in nb[i] if lab[j] != piece and rest[j]]
            if around:
                label[ids] = max(set(around), key=around.count)
    return label


def project(view, p):
    a, up = (np.array(x, float) for x in VIEWS[view])
    up /= np.linalg.norm(up)
    return np.stack([p @ a, -(p @ up)], -1)


def depth(view, p):
    return -(np.asarray(p, float) @ toward(view))


def layout(man):
    p = U.factory_man(man)
    shaped = np.load(os.path.join(WORK, man + "_shape.npz"))
    p.v = shaped["v"].copy()
    lm = shaped["lm"]
    faces, eyes, _join, ear = U.head_parts(p)
    eye_faces = [list(f[0]) for s in "rl" for f in p.groups["helper-%s-eye" % s]]
    v = p.v
    n, c = face_normals(v, faces)
    label = assign(v, faces, n, c, lm, ear)
    print("faces per patch:", {k: int((label == k).sum()) for k in ORDER})
    all_faces = faces + eye_faces
    label = np.concatenate([label, np.array(["face"] * len(eye_faces), dtype=object)])
    # Each patch's extent in its camera (metres), then one density for all that packs them.
    ext = {}
    for name in ORDER:
        ids = sorted({i for k, f in enumerate(all_faces) if label[k] == name for i in f})
        if ids:
            xy = project(name, v[ids])
            ext[name] = (xy.min(0), xy.max(0))
    density, rects = pack(ext)
    corner = []
    for k, f in enumerate(all_faces):
        name = label[k]
        lo, _hi = ext[name]
        x0, y0, _w, _h = rects[name]
        xy = (project(name, v[f]) - lo) * density + np.array([x0, y0])
        corner.append([(float(px / HEAD_TEX), float(py / HEAD_TEX)) for px, py in xy])
    # How much each patch is stretched: the surface's area over its area in the layout.
    stretch = {}
    nn_all, _c = face_normals(v, all_faces)
    for name in ext:
        ks = [k for k in range(len(faces)) if label[k] == name]
        if not ks:
            continue
        cosines = np.abs(nn_all[ks] @ toward(name))
        stretch[name] = {"faces": len(ks), "median": round(float(np.median(1 / np.maximum(cosines, 0.05))), 2),
                         "p95": round(float(np.percentile(1 / np.maximum(cosines, 0.05), 95)), 2)}
    rep = {"man": man, "tex": HEAD_TEX, "texels_a_metre": round(float(density), 1),
           "texels_a_square": round(float(density * CHECK), 1),
           "rects": {k: [int(x) for x in r] for k, r in rects.items()},
           "size_m": {k: [round(float(x), 3) for x in (hi - lo)] for k, (lo, hi) in ext.items()},
           "stretch_area": stretch}
    np.savez(os.path.join(WORK, man + "_layout.npz"), faces=np.array(all_faces, dtype=object),
             corner=np.array(corner, dtype=object), label=label, v=v)
    json.dump(rep, open(os.path.join(WORK, man + "_layout.json"), "w"), indent=1)
    print(json.dumps(rep, indent=1))
    pictures(man, v, all_faces, corner, label, ext, rects, density)


def pack(ext):
    """One density (texels a metre) and each patch's rect (x, y, w, h) in texels: shelves, face
    first, the largest density that fits."""
    for density in np.arange(4000, 500, -25):
        x, y, shelf, rects = GAP, GAP, 0, {}
        ok = True
        for name in ORDER:
            if name not in ext:
                continue
            w, h = ((ext[name][1] - ext[name][0]) * density).astype(int) + 1
            if x + w + GAP > HEAD_TEX:
                x, y, shelf = GAP, y + shelf + GAP, 0
            if x + w + GAP > HEAD_TEX or y + h + GAP > HEAD_TEX:
                ok = False
                break
            rects[name] = (x, y, w, h)
            x += w + GAP
            shelf = max(shelf, h)
        if ok:
            return density, rects
    raise SystemExit("uv_layout: the patches don't fit")


# --- The checkpoint's pictures ---------------------------------------------------------------------

HUES = {"face": (0.86, 0.66, 0.52), "right": (0.55, 0.70, 0.86), "left": (0.60, 0.82, 0.62),
        "back": (0.82, 0.74, 0.50), "crown": (0.76, 0.60, 0.80), "throat": (0.88, 0.56, 0.56),
        "ear_r": (0.50, 0.80, 0.80), "ear_l": (0.80, 0.80, 0.45)}


def uv_raster(faces, corner, v, label, size):
    """Draw each face in the atlas: per texel the surface point, its normal (smooth), its depth in
    its patch's camera and its face (-1 none); where a patch overlaps itself (an ear's back
    under its front, the nose's underside), the one nearest its camera wins."""
    tris_all, _src = P.triangles(faces)
    vn = P.vertex_normals(v, tris_all)
    xy, ids, dep, T, owner = [], [], [], [], []
    for k, f in enumerate(faces):
        base = len(xy)
        for (u, w), i in zip(corner[k], f):
            xy.append((u * size, w * size))
            ids.append(i)
            dep.append(depth(label[k], v[i]))
        for j in range(1, len(f) - 1):
            T.append((base, base + j, base + j + 1))
            owner.append(k)
    xy, ids, dep, T, owner = np.array(xy), np.array(ids), np.array(dep), np.array(T), np.array(owner)
    tid, bary, _z = P.rasterise(xy, dep, T, size, size)
    hit = tid >= 0
    t = T[tid[hit]]
    b = bary[hit][:, :, None]
    surf = np.zeros((size, size, 3))
    surf[hit] = (v[ids[t]] * b).sum(1)
    nrm = np.zeros((size, size, 3))
    nn = (vn[ids[t]] * b).sum(1)
    nrm[hit] = nn / np.maximum(np.linalg.norm(nn, axis=1, keepdims=True), 1e-9)
    dz = np.full((size, size), np.nan)
    dz[hit] = (dep[t] * bary[hit]).sum(1)
    face_at = np.full((size, size), -1)
    face_at[hit] = owner[tid[hit]]
    return surf, nrm, dz, face_at


def checker(label, surf, face_at, size):
    """An 8 mm checker in each patch's own camera plane, each patch its own colour."""
    img = np.full((size, size, 3), 0.12)
    for name, hue in HUES.items():
        m = (face_at >= 0) & (label[np.maximum(face_at, 0)] == name)
        if not m.any():
            continue
        xy = project(name, surf[m])
        odd = (np.floor(xy[:, 0] / CHECK) + np.floor(xy[:, 1] / CHECK)) % 2
        img[m] = np.array(hue) * np.where(odd[:, None] > 0, 1.0, 0.55)
    return img


def shaded_patch(nrm, face_at, label, rect, name="face"):
    """One patch alone, the head shaded in it from its own camera: what the image model reads."""
    x, y, w, h = rect
    out = np.full((h, w, 3), 0.5)
    sub = face_at[y:y + h, x:x + w]
    m = (sub >= 0) & (label[np.maximum(sub, 0)] == name)
    L = toward(name) * 1.0 + np.array([0.3, 0.4, 0.0])
    L /= np.linalg.norm(L)
    out[m] = (0.3 + 0.7 * np.clip(nrm[y:y + h, x:x + w][m] @ L, 0, 1))[:, None] * np.array([0.82, 0.78, 0.74])
    return out


def textured_views(v, faces, corner, tex, size=420):
    """The head with the atlas on it from the front, three-quarters, both sides and behind."""
    T, uvs = [], []
    pts = []
    for k, f in enumerate(faces):
        base = len(pts)
        for (u, w), i in zip(corner[k], f):
            pts.append(v[i])
            uvs.append((u, w))
        for j in range(1, len(f) - 1):
            T.append((base, base + j, base + j + 1))
    pts, T, uvs = np.array(pts), np.array(T), np.array(uvs)
    vn = P.vertex_normals(pts, T)
    th = tex.shape[0]
    out = []
    for name, yaw in (("front", 0), ("three-quarter", 35), ("his right side", 90), ("his left side", -90), ("back", 180)):
        r = np.radians(yaw)
        R = np.array([[np.cos(r), 0, np.sin(r)], [0, 1, 0], [-np.sin(r), 0, np.cos(r)]])
        q = pts @ R.T
        cam = P.head_camera(q, "front", size, fill=0.85)
        tid, bary, _z = P.rasterise(cam.project(q), cam.depth(q), T, size, size)
        img = np.full((size, size, 3), 0.5)
        hit = tid >= 0
        t = T[tid[hit]]
        b = bary[hit]
        uv = (uvs[t] * b[:, :, None]).sum(1)
        px = np.clip((uv * th).astype(int), 0, th - 1)
        nn = (vn[t] * b[:, :, None]).sum(1) @ R.T
        nn /= np.maximum(np.linalg.norm(nn, axis=1, keepdims=True), 1e-9)
        shade = 0.55 + 0.45 * np.clip(nn @ np.array([0, 0, -1.0]), 0, 1)
        img[hit] = tex[px[:, 1], px[:, 0]] * shade[:, None]
        out.append(U.label(P.to_pil(img), name))
    return out


def pictures(man, v, faces, corner, label, ext, rects, density):
    size = HEAD_TEX
    surf, nrm, dz, face_at = uv_raster(faces, corner, v, label, size)
    np.savez(os.path.join(WORK, man + "_raster.npz"), surf=surf, nrm=nrm, depth=dz, face_at=face_at)
    tex = checker(label, surf, face_at, size)
    atlas = P.to_pil(tex)
    d = ImageDraw.Draw(atlas)
    for name, (x, y, w, h) in rects.items():
        d.rectangle([x, y, x + w, y + h], outline=(235, 225, 205))
        d.text((x + 4, y + 4), name, fill=(255, 255, 255))
    atlas.save(os.path.join(WORK, man + "_checker.png"))
    P.to_pil(tex).save(os.path.join(WORK, man + "_checker_tex.png"))
    face = shaded_patch(nrm, face_at, label, rects["face"])
    P.to_pil(face).save(os.path.join(WORK, man + "_face_patch.png"))
    views = textured_views(v, faces, corner, tex)
    W = sum(im.width for im in views) + 10 * (len(views) - 1)
    sheet = Image.new("RGB", (W, views[0].height), (22, 20, 18))
    x = 0
    for im in views:
        sheet.paste(im, (x, 0))
        x += im.width + 10
    sheet.save(os.path.join(WORK, man + "_layout_views.png"))
    print("wrote", man + "_checker.png, _face_patch.png, _layout_views.png in", WORK)


def main():
    args = dict(a.split("=", 1) for a in sys.argv[1:] if "=" in a)
    os.chdir(ROOT)
    layout(args.get("--man", "bold_cowboy"))


if __name__ == "__main__":
    main()
