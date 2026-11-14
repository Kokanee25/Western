#!/usr/bin/env python3
"""Before/after sheets of the old-buildings shots (experiments/old_buildings/shoot.sh).

    python3 experiments/old_buildings/sheet.py build/old_buildings OUT.jpg [--width=640]

Each row a view: as new (--young-town) on the left, as old on the right, its name over it.
"""
import os
import sys

from PIL import Image, ImageDraw


def main(argv):
    src, out = argv[0], argv[1]
    width = 640
    for a in argv[2:]:
        if a.startswith("--width="):
            width = int(a.split("=", 1)[1])
    names = sorted(f[:-4] for f in os.listdir(os.path.join(src, "old")) if f.endswith(".png")
                   and os.path.exists(os.path.join(src, "new", f)))
    if not names:
        print("no pairs in", src)
        return 1
    first = Image.open(os.path.join(src, "old", names[0] + ".png"))
    height = round(first.height * width / first.width)
    label = 22
    sheet = Image.new("RGB", (width * 2 + 6, (height + label) * len(names)), (24, 22, 20))
    draw = ImageDraw.Draw(sheet)
    for row, name in enumerate(names):
        y = row * (height + label)
        draw.text((6, y + 4), "%s   new | old" % name, fill=(235, 225, 205))
        for col, run in enumerate(["new", "old"]):
            im = Image.open(os.path.join(src, run, name + ".png")).convert("RGB").resize((width, height), Image.LANCZOS)
            sheet.paste(im, (col * (width + 6), y + label))
    sheet.save(out, quality=88)
    print("wrote", out, len(names), "views")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
