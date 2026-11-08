#!/usr/bin/env python3
"""The material library's sheets (#701; docs/briefs/material-library.md): a sheet per family from
the material lab's panel renders (tools/material_lab.gd --panels=FAMILY --out=DIR).

  python3 tools/material_library_sheet.py DIR FAMILY OUT.jpg [--cols=noon_far,noon_near,...]
      a row per panel (its swatch code, the wood, its age), the lights and views across;
      the scale (the man's height, the rail's, the wall's) in the header from DIR/FAMILY/numbers.json.

Swatch codes are the entry's `code` in config/material_library.json plus N / F / O (new, a few
years, old): what Sean answers yes or change to on the waiting-on-Sean issue.
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AGE = {"new": ("N", "new"), "few": ("F", "a few years"), "old": ("O", "old")}
COL_NAMES = {"noon_far": "noon, 5 m", "noon_near": "noon, 1 m", "golden_far": "golden hour, 5 m",
             "golden_near": "golden hour, 1 m", "saloon_far": "night inside, 5 m", "saloon_near": "night inside, 1 m",
             "long_angle": "6 m, at an angle", "long_square": "7.5 m, square on", "rake": "raking, along the wall",
             "near": "1 m"}


def font(size):
    for f in ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"]:
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def codes():
    lib = json.load(open(os.path.join(ROOT, "config/material_library.json")))
    return {e["id"]: e for e in lib["entries"]}


def sheet(src, family, out, cols=None, cell=(384, 216), title=None):
    fam = os.path.join(src, family)
    nums = json.load(open(os.path.join(fam, "numbers.json")))
    lib = codes()
    panels = nums["panels"]
    if cols is None:
        cols = ["noon_far", "noon_near", "golden_far", "golden_near", "saloon_far", "saloon_near"]
        cols = [c for c in cols if any(os.path.exists(os.path.join(fam, p["name"], c + ".png")) for p in panels)]
    label_w, head_h, row_gap = 230, 74, 6
    W = label_w + len(cols) * cell[0]
    H = head_h + 24 + len(panels) * (cell[1] + row_gap)
    img = Image.new("RGB", (W, H), (22, 21, 20))
    d = ImageDraw.Draw(img)
    f_big, f_mid, f_small = font(26), font(18), font(15)
    man_h = max((p.get("man_height", 0) for p in panels), default=0)
    rails = sorted({p.get("rail_height", 0) for p in panels})
    d.text((12, 8), title or f"Material library: {family} woods (#701)", fill=(240, 236, 228), font=f_big)
    d.text((12, 44), f"Beside each panel: {nums.get('man', '?')}, {man_h:.2f} m tall. Wall 2.00 m high and wide; "
           f"rail at {', '.join(f'{r:.2f}' for r in rails)} m. The real look; scanned CC0 woods.",
           fill=(200, 196, 188), font=f_small)
    for i, c in enumerate(cols):
        d.text((label_w + i * cell[0] + 8, head_h), COL_NAMES.get(c, c), fill=(220, 214, 200), font=f_mid)
    y = head_h + 24
    for p in panels:
        e = lib.get(p["entry"], {})
        age = p.get("age", "")
        code = f"{e.get('code', '?')}-{AGE.get(age, ('?', age))[0]}"
        suffix = p["name"].replace(p["entry"] + "_" + age, "").strip("_")
        d.text((10, y + 6), code + (f" {suffix}" if suffix else ""), fill=(255, 220, 150), font=f_big)
        words = e.get("name", p["entry"]).split(", ")
        ty = y + 42
        for w in words:
            d.text((10, ty), w, fill=(225, 220, 210), font=f_small)
            ty += 19
        d.text((10, ty + 4), AGE.get(age, ("", age))[1], fill=(180, 200, 220), font=f_mid)
        for i, c in enumerate(cols):
            pth = os.path.join(fam, p["name"], c + ".png")
            if os.path.exists(pth):
                im = Image.open(pth).convert("RGB").resize(cell, Image.LANCZOS)
                img.paste(im, (label_w + i * cell[0], y))
        y += cell[1] + row_gap
    img.save(out, quality=88)
    print(out, img.size)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    if len(args) < 3:
        print(__doc__)
        return 2
    cols = opts["cols"].split(",") if "cols" in opts else None
    sheet(args[0], args[1], args[2], cols, title=opts.get("title"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
