"""The distance test's sheet (claude/characters-face-distance): distances across, his head texture's
versions down, per scene, with his portrait shrunk to the same size in game pixels beside each
distance (box-filtered to that size, then shown x3 nearest as the game shows a frame).

    python3 tools/characters/distance_sheet.py --dir=build/dist --out=SHEET.jpg [--title=...]

Each cell: the render's x3 nearest frame (screenshots.gd's *_x3.png), cropped round his head (its
place and size from the log's man_head_px line: px for 12 cm at his head), all cells of a column at
one magnification, labelled with his eye-to-chin in game pixels.
"""
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
VERSIONS = [("asis", "as now (no mipmaps)"), ("mips", "mipmaps on"), ("custom", "painted mips"),
            ("value", "painted mips + value pass"), ("hybrid", "as now up close,\npainted mips from 6 m")]
SCENES = [("man_saloon_night", "saloon, night", ["1.2", "3", "6", "10", "20"]),
          ("man_store_golden", "street, golden hour", ["1.2", "3", "6", "10", "20"])]
PORTRAIT = os.path.join(ROOT, "docs", "concept", "style", "portrait-cowboy-front.png")
P_EYE_CHIN = 466.0          # the front portrait's eye line to chin, px (MediaPipe)
P_CENTRE = (805.0, 534.0)   # ... the middle of his face (between eyes and chin), px
CELL = 230
SPECKLE = {}
CROP_HEADS = 4.2            # each crop this many of his 12 cm head-heights across (head and shoulders)
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def font(n):
    try:
        return ImageFont.truetype(FONT, n)
    except OSError:
        return ImageFont.load_default()


def head(log):
    m = re.search(r"man_head_px ([\d.]+) ([\d.]+) ([\d.]+)", open(log).read()) if os.path.exists(log) else None
    return tuple(float(x) for x in m.groups()) if m else None


def crop_man(png, hx, hy, size):
    im = Image.open(png).convert("RGB")
    w = size * CROP_HEADS
    x0, y0 = (hx - w / 2) * 3, (hy - w * 0.38) * 3
    c = im.crop((int(x0), int(y0), int(x0 + w * 3), int(y0 + w * 1.15 * 3)))
    return c.resize((CELL, int(CELL * 1.15)), Image.NEAREST)


def speckle(png, hx, hy, size):
    """How much of his face's pixel-to-pixel contrast is speckle: within a box on his face (the game's
    own 1280x720 frame), the share of its contrast a 3x3 median takes away (painted features survive a
    median; single-pixel noise doesn't)."""
    from scipy import ndimage
    im = np.asarray(Image.open(png).convert("L")).astype(float)
    r = max(1, int(round(size * 0.35)))
    box = im[int(hy - r * 0.6):int(hy + r * 1.1) + 1, int(hx - r):int(hx + r) + 1]
    if box.size < 4:
        return float("nan")
    med = ndimage.median_filter(box, 3)
    total = np.abs(np.diff(box, axis=1)).mean() + np.abs(np.diff(box, axis=0)).mean()
    noise = np.abs(box - med).mean()
    return noise / max(total, 1e-6)


def crop_portrait(size):
    """His portrait with his eye-to-chin the man's in game pixels, shown x3 nearest, framed alike."""
    p = Image.open(PORTRAIT).convert("RGB")
    ec = size * 0.112 / 0.12                     # his eye-to-chin, game px
    s = ec / P_EYE_CHIN
    small = p.resize((max(1, round(p.width * s)), max(1, round(p.height * s))), Image.BOX)
    big = small.resize((small.width * 3, small.height * 3), Image.NEAREST)
    w = size * CROP_HEADS
    cx, cy = P_CENTRE[0] * s * 3, P_CENTRE[1] * s * 3
    x0, y0 = cx - w * 1.5, cy - w * 0.38 * 3 - 0.05 * w * 3
    # The portrait is a landscape picture ending at his chin: past its edges the sheet's own grey.
    box = (int(x0), int(y0), int(x0 + w * 3), int(y0 + w * 1.15 * 3))
    c = Image.new("RGB", (box[2] - box[0], box[3] - box[1]), (30, 30, 32))
    c.paste(big, (-box[0], -box[1]))
    c = c.resize((CELL, int(CELL * 1.15)), Image.NEAREST)
    # The same speckle measure on the shrunk portrait (its face's middle, a box of the same size).
    import tempfile
    with tempfile.NamedTemporaryFile(suffix=".png") as tmp:
        small.save(tmp.name)
        sp = speckle(tmp.name, P_CENTRE[0] * s, P_CENTRE[1] * s - size * 0.3, size)
    d = ImageDraw.Draw(c)
    d.rectangle((0, c.height - 20, 120, c.height), fill=(0, 0, 0))
    d.text((4, c.height - 18), "speckle %.2f" % sp, fill=(255, 240, 200), font=font(13))
    return c


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    d = a["--dir"]
    label_w, pad, head_h = 190, 6, 70
    rows = []
    for scene, sname, dists in SCENES:
        sizes = {}
        for dist in dists:
            h = head(os.path.join(d, "asis", "%s_%s.log" % (scene, dist)))
            sizes[dist] = h
        row = [("%s: his portrait, same size" % sname, [crop_portrait(sizes[x][2]) if sizes[x] else None for x in dists])]
        for v, vname in VERSIONS:
            cells = []
            for dist in dists:
                h = head(os.path.join(d, v, "%s_%s.log" % (scene, dist)))
                png = os.path.join(d, v, "%s_%s" % (scene, dist), "%s_x3.png" % scene)
                cells.append(crop_man(png, *h) if h and os.path.exists(png) else None)
                if h and os.path.exists(png):
                    sp = speckle(png.replace("_x3.png", ".png"), *h)
                    dr_c = ImageDraw.Draw(cells[-1])
                    dr_c.rectangle((0, cells[-1].height - 20, 120, cells[-1].height), fill=(0, 0, 0))
                    dr_c.text((4, cells[-1].height - 18), "speckle %.2f" % sp, fill=(255, 240, 200), font=font(13))
                    SPECKLE.setdefault((scene, v), []).append((dist, round(sp, 3)))
            row.append(("%s: %s" % (sname, vname), cells))
        rows.append((dists, sizes, row))
    ncol = 5
    ch = int(CELL * 1.15)
    H = head_h + sum(len(r[2]) * (ch + pad) + 40 for r in rows) + 60
    W = label_w + ncol * (CELL + pad) + pad
    canvas = Image.new("RGB", (W, H), (30, 30, 32))
    dr = ImageDraw.Draw(canvas)
    dr.text((pad * 2, 14), a.get("--title", "His face by distance"), fill=(235, 230, 220), font=font(22))
    y = head_h
    for dists, sizes, row in rows:
        for i, dist in enumerate(dists):
            sz = sizes[dist]
            txt = "%s m: eye to chin %.0f px" % (dist, sz[2] * 0.112 / 0.12) if sz else "%s m: the room is shorter" % dist
            dr.text((label_w + pad + i * (CELL + pad), y + 8), txt, fill=(220, 210, 190), font=font(14))
        y += 34
        for label, cells in row:
            dr.text((pad, y + ch // 2 - 16), label.replace(": ", ":\n"), fill=(200, 200, 200), font=font(14))
            for i, c in enumerate(cells):
                x = label_w + pad + i * (CELL + pad)
                if c is None:
                    dr.rectangle((x, y, x + CELL, y + ch), outline=(70, 70, 70))
                    dr.text((x + 10, y + ch // 2), "doesn't fit\n(saloon < 20 m)", fill=(150, 150, 150), font=font(13))
                else:
                    canvas.paste(c, (x, y))
            y += ch + pad
        y += 6
    for i, n in enumerate(a.get("--notes", "").split("|") if a.get("--notes") else []):
        dr.text((pad * 2, y + 6 + 20 * i), n, fill=(210, 205, 195), font=font(15))
    canvas = canvas.crop((0, 0, W, y + 30 + 20 * len(a.get("--notes", "").split("|"))))
    canvas.save(a["--out"], quality=90)
    for k, vals in SPECKLE.items():
        print("speckle", k, vals)
    print("distance_sheet: wrote", a["--out"], canvas.size)


if __name__ == "__main__":
    main()
