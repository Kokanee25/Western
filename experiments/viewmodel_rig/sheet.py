"""Contact sheets for the viewmodel rig lab (#896): a folder of views -> one jpg, each cell labelled.
    python3 experiments/viewmodel_rig/sheet.py DIR OUT.jpg [--cols=4] [--w=480] [--only=a,b] [--crop=x0,y0,x1,y1 (fractions)]
    python3 experiments/viewmodel_rig/sheet.py --pair DIR_A DIR_B OUT.jpg --names=a,b [--labels=A,B]  # side by side, a row a view
"""
import argparse, glob, os
from PIL import Image, ImageDraw


def cell(path, w, label, crop=None):
    im = Image.open(path).convert("RGB")
    if crop:
        W, H = im.size
        im = im.crop((int(crop[0] * W), int(crop[1] * H), int(crop[2] * W), int(crop[3] * H)))
    im = im.resize((w, int(im.height * w / im.width)), Image.LANCZOS)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 8 + 7 * len(label), 16), fill=(0, 0, 0))
    d.text((4, 2), label, fill=(255, 255, 255))
    return im


def grid(cells, cols):
    w, h = cells[0].size
    rows = (len(cells) + cols - 1) // cols
    out = Image.new("RGB", (w * cols, max(c.height for c in cells) * rows), (20, 20, 20))
    for i, c in enumerate(cells):
        out.paste(c, ((i % cols) * w, (i // cols) * h))
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument("paths", nargs="+")
    p.add_argument("--cols", type=int, default=4)
    p.add_argument("--w", type=int, default=480)
    p.add_argument("--only", default="")
    p.add_argument("--crop", default="")
    p.add_argument("--pair", action="store_true")
    p.add_argument("--names", default="")
    p.add_argument("--labels", default="")
    a = p.parse_args()
    crop = [float(x) for x in a.crop.split(",")] if a.crop else None
    if a.pair:
        da, db, outp = a.paths
        la, lb = (a.labels.split(",") + ["", ""])[:2] if a.labels else (os.path.basename(da), os.path.basename(db))
        cells = []
        for n in a.names.split(","):
            cells.append(cell(f"{da}/{n}.png", a.w, f"{la}: {n}", crop))
            cells.append(cell(f"{db}/{n}.png", a.w, f"{lb}: {n}", crop))
        grid(cells, 2).save(outp, quality=88)
        return
    d, outp = a.paths
    files = sorted(glob.glob(f"{d}/*.png"))
    if a.only:
        files = [f"{d}/{n}.png" for n in a.only.split(",")]
    grid([cell(f, a.w, os.path.basename(f)[:-4], crop) for f in files], a.cols).save(outp, quality=88)


main()
