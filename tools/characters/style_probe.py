"""Where a Rodin portrait man still differs from his portraits, measured (docs/briefs/
character-style-fidelity.md, phase 1).

    ~/bpyenv/bin/python tools/characters/style_probe.py --man=bold_cowboy [--game=DIR] [--out=DIR] [--tag=before]
        [--work=DIR]   (the paint, mesh and report to read: rodin_portrait.py's build/rodin_portrait by default)

For each portrait the man was painted from (front, three-quarter, the profile on the left), our
head drawn through that portrait's own fitted camera (rodin_portrait.py's report), at the
portrait's pixels, so every panel is framed exactly as the portrait:

  portrait | clay (shape alone; the portrait's landmarks red, ours green) | the projection before
  squares and fills | the final paint (unlit) | the game in neutral light | the game in the saloon

The game panels are rendered by distance_lab.gd (at the portrait's turn) and screenshots.gd
(shot_match_close), found in --game (DIR/dist, DIR/shots) and laid onto the portrait by their face
landmarks (a similarity, nearest pixels), so they are framed as the portrait too.

Measures, each panel against the portrait, inside the portrait's face outline:
  geometry   landmark error per feature group (brow, eyes, nose, mouth, jaw), % of eye-to-chin;
             and proportions (cheek width, jaw width, nose length, mouth width over eye-to-chin)
  patches    the median run of one colour along rows and columns (a run ends where the colour
             strays RUN_TOL from where it began), % of eye-to-chin: how big the blocks read
  tones      how many colours k-means needs before the face is within TONE_DE of them
  detail     what's left under a median the size of the portrait's own patches (RMS, 0-255): the
             photographic detail under the blocks
  light      mean and spread of brightness (L*), mean chroma, share of highlights (L* > 85)
→ OUT/<man>_<tag>_sheet.png, OUT/<man>_<tag>.json, and each panel cropped in OUT/<man>_<tag>/
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import portrait as P  # noqa: E402
import rodin_portrait as RP  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
VIEWS = ("front", "three_quarter", "profile_left")
RUN_TOL = 0.07
TONE_DE = 6.0
PANEL_H = 300

# MediaPipe's face mesh: the outline, and the groups whose error is reported.
OVAL = [10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288, 397, 365, 379, 378, 400, 377, 152,
        148, 176, 149, 150, 136, 172, 58, 132, 93, 234, 127, 162, 21, 54, 103, 67, 109]
GROUPS = {
    "brow": [70, 63, 105, 66, 107, 336, 296, 334, 293, 300],
    "eyes": [33, 133, 159, 145, 362, 263, 386, 374],
    "nose": [1, 2, 98, 327, 168, 6, 197, 4],
    "mouth": [61, 291, 0, 17, 13, 14, 40, 270],
    "jaw": [152, 148, 377, 172, 397, 136, 365, 58, 288],
}
# Points used to lay a game render onto a portrait (the face's firm points).
ALIGN = [33, 133, 362, 263, 1, 4, 61, 291, 152, 168, 105, 334, 234, 454]


# --- Drawing our head through a portrait's camera -----------------------------------------------------

def draw(V, T, UV, cam, w, h, tex=None, clay=False):
    """Our head as the camera sees it: (h, w, 3) floats, and where he is (mask)."""
    tid, bary, _zb = P.rasterise(cam.project(V), cam.depth(V), T, w, h)
    img = np.zeros((h, w, 3))
    hit = tid >= 0
    t = T[tid[hit]]
    b = bary[hit]
    if clay:
        n = P.vertex_normals(V, T)
        nn = (n[t] * b[:, :, None]).sum(1)
        nn /= np.maximum(np.linalg.norm(nn, axis=1, keepdims=True), 1e-9)
        L = cam.R.T @ np.array([-0.45, 0.5, -0.74])     # from the camera's upper left
        img[hit] = (0.25 + 0.7 * np.clip(nn @ (L / np.linalg.norm(L)), 0, 1))[:, None] * np.array([0.82, 0.78, 0.72])
    else:
        uv = (UV[t] * b[:, :, None]).sum(1)
        img[hit] = RP.sample_tex(tex, uv)
    return img, hit


def similarity(src, dst):
    """Scale, rotation, offset taking src points to dst (Umeyama, 2D)."""
    ms, md = src.mean(0), dst.mean(0)
    a, b = src - ms, dst - md
    u, s, vt = np.linalg.svd(b.T @ a)
    d = np.sign(np.linalg.det(u @ vt))
    R = u @ np.diag([1, d]) @ vt
    k = (s * [1, d]).sum() / (a ** 2).sum()
    return k, R, md - k * R @ ms


def lay_onto(game, lm_game, lm_paint, w, h):
    """A game render laid onto the portrait's frame by their landmarks (nearest pixels)."""
    k, R, t = similarity(lm_game[ALIGN, :2], lm_paint[ALIGN, :2])
    gy, gx = np.mgrid[0:h, 0:w]
    dst = np.stack([gx + 0.5, gy + 0.5], -1).reshape(-1, 2)
    src = ((dst - t) @ R) / k
    x = np.floor(src[:, 0]).astype(int)
    y = np.floor(src[:, 1]).astype(int)
    ok = (x >= 0) & (x < game.shape[1]) & (y >= 0) & (y < game.shape[0])
    out = np.zeros((h * w, 3))
    out[ok] = game[y[ok], x[ok]]
    return out.reshape(h, w, 3), ok.reshape(h, w), k


def game_landmarks(img):
    """Landmarks on a small game render: found on it enlarged (MediaPipe misses small faces)."""
    for up in (4, 3, 2, 1):
        big = Image.fromarray((img * 255).astype(np.uint8)).resize((img.shape[1] * up, img.shape[0] * up), Image.NEAREST)
        lm = P.landmarks(big)
        if lm is not None:
            return lm / up
    return None


# --- Measures --------------------------------------------------------------------------------------

def face_mask(lm, w, h):
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).polygon([tuple(lm[i, :2]) for i in OVAL], fill=255)
    return np.asarray(m) > 0


def to_lab(rgb):
    c = np.where(rgb > 0.04045, ((rgb + 0.055) / 1.055) ** 2.4, rgb / 12.92)
    M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ M.T / np.array([0.9505, 1.0, 1.089])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def runs(img, mask):
    """Every run of one colour along rows and columns inside the mask (pixels)."""
    out = []
    for a, m in ((img, mask), (img.transpose(1, 0, 2), mask.T)):
        for row, mr in zip(a, m):
            xs = np.nonzero(mr)[0]
            if len(xs) < 2:
                continue
            seg = row[xs[0]:xs[-1] + 1]
            start, n = seg[0], 1
            for px in seg[1:]:
                if np.abs(px - start).max() > RUN_TOL:
                    out.append(n)
                    start, n = px, 1
                else:
                    n += 1
            out.append(n)
    return np.array(out)


def tones(lab):
    """How many k-means colours before every pixel is within TONE_DE (Lab) of one."""
    from scipy.cluster.vq import kmeans2
    x = lab[np.random.default_rng(0).choice(len(lab), min(len(lab), 6000), replace=False)]
    for k in (2, 3, 4, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 64):
        c, lab_ = kmeans2(x, k, minit="++", seed=0)
        d = np.linalg.norm(x - c[lab_], axis=1)
        if np.percentile(d, 90) < TONE_DE:
            return k
    return 64


def measure(img, mask, scale, patch_px):
    """The painting-language and light measures of one panel's face (scale: pixels of eye-to-chin)."""
    px = img[mask]
    lab = to_lab(px)
    r = runs(img, mask)
    u8 = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8))
    size = max(3, int(round(patch_px)) | 1)
    med = np.asarray(u8.filter(ImageFilter.MedianFilter(min(size, 15)))).astype(float)
    detail = float(np.sqrt(np.mean((np.asarray(u8).astype(float)[mask] - med[mask]) ** 2)))
    chroma = np.hypot(lab[:, 1], lab[:, 2])
    return {"patch_pct": round(100 * float(np.median(r)) / scale, 2), "patch_mean_pct": round(100 * float(r.mean()) / scale, 2),
            "tones": tones(lab), "detail_rms": round(detail, 1),
            "L_mean": round(float(lab[:, 0].mean()), 1), "L_sd": round(float(lab[:, 0].std()), 1),
            "chroma": round(float(chroma.mean()), 1), "highlights_pct": round(100 * float((lab[:, 0] > 85).mean()), 2)}


def proportions(lm):
    h = np.linalg.norm(lm[168, :2] - lm[152, :2])
    d = lambda a, b: float(np.linalg.norm(lm[a, :2] - lm[b, :2]) / h)  # noqa: E731
    return {"cheeks": round(d(234, 454), 3), "jaw": round(d(172, 397), 3), "nose": round(d(168, 2), 3),
            "mouth": round(d(61, 291), 3), "brow_to_eye": round(d(105, 159), 3), "chin": round(d(17, 152), 3)}


# --- The sheet -------------------------------------------------------------------------------------

def crop_box(lm, w, h):
    top, chin = lm[:, 1].min(), lm[152, 1]
    face = chin - top
    y0, y1 = top - 0.45 * face, chin + 0.12 * face
    cx = lm[:, 0].mean()
    half = (y1 - y0) * 0.55
    return (int(max(0, cx - half)), int(max(0, y0)), int(min(w, cx + half)), int(min(h, y1)))


def panel(img, box, title, dots=()):
    im = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).crop(box)
    k = PANEL_H / im.height
    im = im.resize((int(im.width * k), PANEL_H), Image.NEAREST)
    d = ImageDraw.Draw(im)
    for pts, col in dots:
        for x, y in pts:
            x, y = (x - box[0]) * k, (y - box[1]) * k
            d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=col)
    d.rectangle([0, 0, 7 * len(title) + 8, 14], fill=(22, 20, 18))
    d.text((4, 1), title, fill=(235, 225, 205))
    return im


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    man = a.get("--man", "bold_cowboy")
    game = a.get("--game")
    out = a.get("--out", os.path.join(ROOT, "docs", "screenshots", "portrait", "probe"))
    tag = a.get("--tag", "now")
    work = a.get("--work", RP.WORK)
    os.makedirs(out, exist_ok=True)
    spec = json.load(open(os.path.join(ROOT, "assets", "people", "portrait.json")))["men"][man]
    rep = json.load(open(os.path.join(work, man + "_report.json")))
    mesh = np.load(os.path.join(work, man + "_mesh.npy"), allow_pickle=True).item()
    V, T, UV, pts = mesh["V"], mesh["T"], mesh["UV"], mesh["pts"]
    paint = np.asarray(Image.open(os.path.join(work, man + "_paint.png")).convert("RGB")).astype(float) / 255
    proj_p = os.path.join(work, man + "_projected.png")
    proj = np.asarray(Image.open(proj_p).convert("RGB")).astype(float) / 255 if os.path.exists(proj_p) else None
    result = {"man": man, "tag": tag, "views": {}}
    rows = []
    for view in VIEWS:
        if view not in rep["cameras"]:
            continue
        cam = P.PoseCamera.of(rep["cameras"][view])
        pic = Image.open(os.path.join(ROOT, spec["paint_views"][view])).convert("RGB")
        w, h = pic.size
        ref = np.asarray(pic).astype(float) / 255
        lm = P.landmarks(pic)
        mask = face_mask(lm, w, h)
        scale = float(np.linalg.norm(lm[168, :2] - lm[152, :2]))
        r_ref = runs(ref, mask)
        patch_px = float(np.median(r_ref))
        ours = cam.project(pts)
        geo = {}
        for g, ids in GROUPS.items():
            e = np.linalg.norm(ours[ids] - lm[ids, :2], axis=1)
            geo[g] = round(100 * float(np.sqrt(np.mean(e ** 2))) / scale, 1)
        clay, _m = draw(V, T, UV, cam, w, h, clay=True)
        fin, hit = draw(V, T, UV, cam, w, h, tex=paint)
        panels = {"portrait": ref, "clay": clay, "final paint": fin}
        if proj is not None:
            panels["projected"] = draw(V, T, UV, cam, w, h, tex=proj)[0]
        v = {"geometry_err_pct": geo, "proportions": {"portrait": proportions(lm), "ours": proportions(ours)},
             "panels": {}}
        turn = int(round(rep["cameras"][view]["yaw"]))
        game_files = {}
        if game:
            game_files["game, neutral"] = os.path.join(game, "dist", "%s_rodin_1.2_%d.png" % (man, turn))
            if view == "front":
                game_files["game, saloon"] = os.path.join(game, "shots", "shot_match_close.png")
        game_px = {}
        for name, path in game_files.items():
            if not os.path.exists(path):
                continue
            g = np.asarray(Image.open(path).convert("RGB")).astype(float) / 255
            glm = game_landmarks(g)
            if glm is None:
                v["panels"][name] = "no face found"
                continue
            laid, ok, px_size = lay_onto(g, glm, lm, w, h)
            panels[name] = laid
            game_px[name] = round(px_size, 2)
        for name, img in panels.items():
            m = mask if name == "portrait" else mask & (img.sum(-1) > 0)
            v["panels"][name] = measure(img, m, scale, patch_px)
            if name in game_px:
                v["panels"][name]["game_pixel_pct"] = round(100 * game_px[name] / scale, 2)
        result["views"][view] = v
        box = crop_box(lm, w, h)
        pdir = os.path.join(out, "%s_%s" % (man, tag))
        os.makedirs(pdir, exist_ok=True)
        for name, img in panels.items():
            Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).crop(box).save(
                os.path.join(pdir, "%s_%s.png" % (view, name.replace(", ", "_").replace(" ", "_"))))
        order = ["portrait", "clay", "projected", "final paint", "game, neutral", "game, saloon"]
        row = []
        for name in order:
            if name not in panels:
                continue
            dots = ((lm[:, :2][list(range(0, 468, 3))], (230, 40, 40)), (ours[list(range(0, 468, 3))], (40, 230, 60))) \
                if name == "clay" else ()
            row.append(panel(panels[name], box, "%s: %s" % (view.replace("_", " "), name), dots))
        rows.append(row)
        print(view, json.dumps(v))
    W = max(sum(p.width for p in r) + 6 * len(r) for r in rows)
    sheet = Image.new("RGB", (W, len(rows) * (PANEL_H + 6)), (22, 20, 18))
    for i, r in enumerate(rows):
        x = 0
        for p in r:
            sheet.paste(p, (x, i * (PANEL_H + 6)))
            x += p.width + 6
    sheet.save(os.path.join(out, "%s_%s_sheet.png" % (man, tag)))
    json.dump(result, open(os.path.join(out, "%s_%s.json" % (man, tag)), "w"), indent=1)
    print("style_probe: wrote", os.path.join(out, "%s_%s_sheet.png" % (man, tag)))
    P.close_landmarker()


if __name__ == "__main__":
    main()
