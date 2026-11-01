"""The deer head fidelity lab's contact sheet (issue #524): one row a version, one column a view,
every cell the same square round the deer cut from the stand's frames (stand.gd: DIR/<id>_<light>_
<view>.png and crops.json), scaled to one size with nearest neighbour so the game's own pixels
show; each row labelled with its version and its costs.

    python3 experiments/prop_lab/deer_fidelity/sheet.py DIR OUT.jpg [--only=C0,C4,A] [--cell=220]
        [--cols=studio_front,studio_threeq,...]
    python3 experiments/prop_lab/deer_fidelity/sheet.py --game GDIR OUT.jpg   # the game's own saloon
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

COLS = [("studio_front", "front"), ("studio_threeq", "three-quarter"), ("studio_profile", "profile"),
        ("studio_close", "close (a couple of steps, player's lens)"), ("studio_across", "across the saloon (9 m)"),
        ("day_threeq", "daylight"), ("lamp_threeq", "night, lamplight")]


def font(px):
    for f in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/dejavu/DejaVuSans.ttf"):
        if os.path.exists(f):
            return ImageFont.truetype(f, px)
    return ImageFont.load_default()


def cost_line(c):
    mb = c["vram_bc"] / 2 ** 20
    r = c.get("render", {})
    return "%s tris | textures %.1f MB (BC), %.0f MB raw | lavapipe close %.1f ms, across %.1f ms" % (
        format(c["triangles"], ","), mb, c["rgba8"] / 2 ** 20, r.get("close", {}).get("gpu_ms", 0), r.get("across", {}).get("gpu_ms", 0))


def sheet(d, out, only=None, cell=220, cols=None):
    costs = json.load(open(os.path.join(d, "costs.json")))
    crops = json.load(open(os.path.join(d, "crops.json")))
    ids = only or list(costs)
    cols = [c for c in COLS if c[0] in cols] if cols else COLS
    head, label_h = 28, 40
    W, H = cell * len(cols), head + (cell + label_h) * len(ids)
    im = Image.new("RGB", (W, H), (24, 24, 24))
    dr = ImageDraw.Draw(im)
    f1, f2 = font(15), font(13)
    for j, (_, name) in enumerate(cols):
        dr.text((j * cell + 6, 6), name, fill=(230, 230, 230), font=f2)
    for i, vid in enumerate(ids):
        y = head + i * (cell + label_h)
        dr.text((6, y + 3), costs[vid]["label"], fill=(255, 220, 140), font=f1)
        dr.text((6, y + 21), cost_line(costs[vid]), fill=(180, 180, 180), font=f2)
        for j, (key, _) in enumerate(cols):
            light, view = key.split("_")
            p = os.path.join(d, "%s_%s_%s.png" % (vid, light, view))
            if not os.path.exists(p):
                continue
            x0, y0, s = crops[view]
            src = Image.open(p).convert("RGB").crop((x0, y0, x0 + s, y0 + s))
            im.paste(src.resize((cell, cell), Image.NEAREST if s < cell else Image.LANCZOS), (j * cell, y + label_h))
    im.save(out, quality=90)
    print(out, im.size)


def game_sheet(d, out, cell=300):
    """The game's own saloon (bridge shots: GDIR/<id>_<shot>.png, GDIR/shots.json {shot: [x, y, side]}),
    one row a version."""
    shots = json.load(open(os.path.join(d, "shots.json")))
    labels = json.load(open(os.path.join(d, "labels.json")))
    head, label_h = 28, 22
    W, H = cell * len(shots), head + (cell + label_h) * len(labels)
    im = Image.new("RGB", (W, H), (24, 24, 24))
    dr = ImageDraw.Draw(im)
    for j, name in enumerate(shots):
        dr.text((j * cell + 6, 6), name, fill=(230, 230, 230), font=font(13))
    for i, (vid, lab) in enumerate(labels.items()):
        y = head + i * (cell + label_h)
        dr.text((6, y + 3), lab, fill=(255, 220, 140), font=font(15))
        for j, (name, (x0, y0, s)) in enumerate(shots.items()):
            p = os.path.join(d, "%s_%s.png" % (vid, name))
            if os.path.exists(p):
                src = Image.open(p).convert("RGB").crop((x0, y0, x0 + s, y0 + s))
                im.paste(src.resize((cell, cell), Image.NEAREST if s < cell else Image.LANCZOS), (j * cell, y + label_h))
    im.save(out, quality=90)
    print(out, im.size)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    kw = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    if "--game" in sys.argv:
        game_sheet(args[0], args[1])
    else:
        sheet(args[0], args[1], kw["only"].split(",") if "only" in kw else None, int(kw.get("cell", 220)),
              kw["cols"].split(",") if "cols" in kw else None)
