#!/usr/bin/env python3
"""The probe mosaic trial in motion: measure the shimmer in tools/probe_walk.gd's frames and put
runs side by side as a video.

    python3 tools/probe_walk.py measure DIR [DIR ...]
    python3 tools/probe_walk.py stability DEPTH_DIR DIR [DIR ...]
    python3 tools/probe_walk.py video OUT.mp4 LABEL=DIR [LABEL=DIR ...] [--paths=turn,walk]

`measure` prints, for each path and run, the share of pixels that change by more than 8/255 from
one frame to the next (motion shows as change too), and the share that flip and flip back: a
pixel that jumps by more than 24/255 and is back within 8/255 a frame later (A, B, A). On a moving
camera an edge passing a pixel changes it once; blocks crawling over a moving picture flip it back
and forth, so the second number is the shimmer. But with few colours (the light in bands) a fast move
brings the same colour back by chance, so `stability` is the better measure: it takes a
--depth-pass run of the same paths (each pixel's distance, and every frame's camera in poses.json)
and moves each pixel of a frame back to where that point of the world was in the frame before,
and counts the pixels that can't find their colour again there (within 24/255, anywhere in the
3x3 pixels round that spot). What the camera's movement explains is subtracted; what's left is
pixels changing under you: blocks crawling or re-cut, flicker. Points hidden in the frame before
are left out. `video` stacks the runs (two side by side, more in a grid), each labelled, at
30 fps (ffmpeg on the PATH, or imageio-ffmpeg's).
"""
import json
import math
import glob
import os
import shutil
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image, ImageDraw

PATHS = ["still", "turn", "walk", "strafe", "circle", "approach", "face"]


def frames(run, path):
    return sorted(glob.glob(os.path.join(run, "%s_[0-9][0-9][0-9].png" % path)))


def load(f):
    return np.asarray(Image.open(f).convert("RGB")).astype(np.int16)


def shimmer(files):
    """(changed share, flip-back share), each the mean over the path's frames."""
    if len(files) < 3:
        return None
    changed, flips = [], []
    a, b = load(files[0]), load(files[1])
    changed.append(float((np.abs(b - a).max(-1) > 8).mean()))
    for f in files[2:]:
        c = load(f)
        d_ab = np.abs(b - a).max(-1)
        d_ac = np.abs(c - a).max(-1)
        changed.append(float((np.abs(c - b).max(-1) > 8).mean()))
        flips.append(float(((d_ab > 24) & (d_ac <= 8)).mean()))
        a, b = b, c
    return float(np.mean(changed)), float(np.mean(flips))


def measure(runs):
    print("%-10s %-38s %9s %9s" % ("path", "run", "changed", "flip-back"))
    for p in PATHS:
        for r in runs:
            m = shimmer(frames(r, p))
            if m:
                print("%-10s %-38s %8.2f%% %8.3f%%" % (p, os.path.basename(r.rstrip("/")), m[0] * 100, m[1] * 100))


def depth(f):
    a = np.asarray(Image.open(f).convert("RGB")).astype(np.int64)
    return (a[..., 0] * 65536 + a[..., 1] * 256 + a[..., 2]) / 1000.0


def poses(depth_dir):
    out = {}
    for p in json.load(open(os.path.join(depth_dir, "poses.json"))):
        out[(p["path"], p["frame"])] = p
    return out


def unstable(img0, img1, d0, d1, p0, p1, step=2):
    """Share of the pixels of frame 1 (every `step`th) seen in frame 0 whose colour isn't within
    24/255 of frame 0's anywhere in the 3x3 pixels where that point was."""
    h, w = d1.shape
    tan_y = math.tan(math.radians(p1["fov"]) * 0.5)
    tan_x = tan_y * w / h
    ys, xs = np.mgrid[0:h:step, 0:w:step]
    nx = (xs + 0.5) / w * 2.0 - 1.0
    ny = 1.0 - (ys + 0.5) / h * 2.0
    b1 = np.array(p1["basis"])
    ray = nx[..., None] * tan_x * b1[0] + ny[..., None] * tan_y * b1[1] - b1[2]
    ray /= np.linalg.norm(ray, axis=-1, keepdims=True)
    dist1 = d1[ys, xs]
    pts = np.array(p1["camera"]) + ray * dist1[..., None]
    b0 = np.array(p0["basis"])
    rel = pts - np.array(p0["camera"])
    v = np.stack([rel @ b0[0], rel @ b0[1], rel @ b0[2]], -1)
    ahead = v[..., 2] < -0.01
    z = np.where(ahead, -v[..., 2], 1.0)
    sx = np.rint(((v[..., 0] / z / tan_x) + 1.0) * 0.5 * w - 0.5).astype(int)
    sy = np.rint((1.0 - v[..., 1] / z / tan_y) * 0.5 * h - 0.5).astype(int)
    inside = ahead & (sx >= 1) & (sx < w - 1) & (sy >= 1) & (sy < h - 1) & (dist1 < 150.0) & (dist1 > 0.05)
    sxc, syc = np.clip(sx, 1, w - 2), np.clip(sy, 1, h - 2)
    r0 = np.linalg.norm(rel, axis=-1)
    seen = inside & (np.abs(d0[syc, sxc] - r0) < 0.02 * r0 + 0.01)
    c1 = img1[ys, xs]
    best = np.full(sx.shape, 999)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            best = np.minimum(best, np.abs(img0[syc + dy, sxc + dx] - c1).max(-1))
    n = int(seen.sum())
    return (float(((best > 24) & seen).sum()) / n if n else 0.0), n / seen.size


def stability(depth_dir, runs):
    ps = poses(depth_dir)
    print("%-10s %-38s %10s %8s" % ("path", "run", "unstable", "seen"))
    for p in PATHS:
        dfiles = frames(depth_dir, p)
        if len(dfiles) < 2:
            continue
        ds = [depth(f) for f in dfiles]
        for r in runs:
            files = frames(r, p)
            if len(files) < 2:
                continue
            shares, seens = [], []
            prev = load(files[0])
            for i in range(1, min(len(files), len(ds))):
                cur = load(files[i])
                s, seen = unstable(prev, cur, ds[i - 1], ds[i], ps[(p, i - 1)], ps[(p, i)])
                shares.append(s)
                seens.append(seen)
                prev = cur
            print("%-10s %-38s %9.2f%% %7.0f%%" % (p, os.path.basename(r.rstrip("/")), 100 * np.mean(shares), 100 * np.mean(seens)))


def ffmpeg():
    exe = shutil.which("ffmpeg")
    if exe:
        return exe
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        sys.exit("no ffmpeg: install it, or pip install imageio-ffmpeg")


def video(out, runs, paths):
    labels = [r.split("=", 1)[0] for r in runs]
    dirs = [r.split("=", 1)[1] for r in runs]
    cols = 2 if len(dirs) <= 4 else 3
    rows = (len(dirs) + cols - 1) // cols
    tmp = tempfile.mkdtemp()
    k = 0
    for p in paths:
        lists = [frames(d, p) for d in dirs]
        n = min(len(x) for x in lists)
        for i in range(n):
            ims = [Image.open(x[i]).convert("RGB") for x in lists]
            w, h = ims[0].size
            sheet = Image.new("RGB", (cols * w, rows * h), (12, 10, 9))
            d = ImageDraw.Draw(sheet)
            for j, im in enumerate(ims):
                x, y = (j % cols) * w, (j // cols) * h
                sheet.paste(im, (x, y))
                d.rectangle((x, y, x + 12 + 8 * len(labels[j] + p) + 30, y + 22), fill=(0, 0, 0))
                d.text((x + 8, y + 5), "%s  %s" % (labels[j], p), fill=(240, 228, 205))
            sheet.save(os.path.join(tmp, "f%05d.png" % k))
            k += 1
    subprocess.run([ffmpeg(), "-y", "-loglevel", "error", "-framerate", "30", "-i", os.path.join(tmp, "f%05d.png"),
                    "-c:v", "libx264", "-crf", "24", "-pix_fmt", "yuv420p", "-movflags", "+faststart", out], check=True)
    shutil.rmtree(tmp)
    print(out, k, "frames")


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    if sys.argv[1] == "measure":
        measure(sys.argv[2:])
    elif sys.argv[1] == "stability":
        stability(sys.argv[2], sys.argv[3:])
    elif sys.argv[1] == "video":
        opts = [a for a in sys.argv[3:] if a.startswith("--")]
        runs = [a for a in sys.argv[3:] if not a.startswith("--")]
        paths = PATHS
        for o in opts:
            if o.startswith("--paths="):
                paths = o[8:].split(",")
        video(sys.argv[2], runs, paths)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
