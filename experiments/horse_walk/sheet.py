"""Contact sheets of the reference's legs: frames cropped to the horse (the crop follows him),
numbered, a grid line every 50 ground pixels (pan.json) so a planted hoof's x can be read.

    python3 experiments/horse_walk/sheet.py --frames=60,90,2 [--cols=4] [--rows=380,510] [--out=NAME]
"""
import glob
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "build", "horse_walk")


def centre(f):
    """The horse's middle in frame f's pixels: on the ground ~500 at frame 35 and 2.35 px a frame
    on (stances.py: the planted hooves' march), shifted by the pan into the frame."""
    return 500 + 2.35 * (f - 35) + json.load(open(os.path.join(OUT, "pan.json")))["pan"][f]


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    f0, f1, step = (int(v) for v in opts.get("frames", "60,90,2").split(","))
    y0, y1 = (int(v) for v in opts.get("rows", "380,510").split(","))
    cw = int(opts.get("width", "300"))
    cols = int(opts.get("cols", "4"))
    sc = float(opts.get("scale", "1"))
    pan = json.load(open(os.path.join(OUT, "pan.json")))["pan"]
    frames = sorted(glob.glob(os.path.join(OUT, "frames", "f*.png")))
    idx = list(range(f0, f1 + 1, step))
    cells = []
    for f in idx:
        im = Image.open(frames[f]).convert("RGB")
        cx = int(opts["x"]) + pan[f] if "x" in opts else centre(f)
        x0 = int(round(cx - cw / 2))
        c = im.crop((x0, y0, x0 + cw, y1))
        d = ImageDraw.Draw(c)
        # ground grid: ground x g sits at frame x g + pan[f]
        for g in range(-200, 1400, 50):
            x = g + pan[f] - x0
            if 0 <= x < cw:
                d.line([(x, y1 - y0 - 8), (x, y1 - y0)], fill=(0, 255, 255))
                if g % 100 == 0:
                    d.text((x + 2, y1 - y0 - 18), str(g), fill=(0, 255, 255))
        d.text((3, 3), str(f), fill=(255, 255, 0))
        if sc != 1:
            c = c.resize((int(cw * sc), int((y1 - y0) * sc)), Image.LANCZOS)
        cells.append(c)
    w, h = cells[0].size
    rows = (len(cells) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * w, rows * h))
    for k, c in enumerate(cells):
        sheet.paste(c, ((k % cols) * w, (k // cols) * h))
    path = os.path.join(OUT, opts.get("out", "sheet_%d_%d.jpg" % (f0, f1)))
    sheet.save(path, quality=88)
    print(path, sheet.size)


if __name__ == "__main__":
    main()
