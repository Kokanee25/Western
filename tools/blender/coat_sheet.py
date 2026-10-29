#!/usr/bin/env python3
"""The sack coat template's sheet for Sean (docs/briefs/fitted-coat.md, step 2): his coated pictures
first, then the template alone on the stand (front, side, back, three-quarter), the collar and
lapels close beside the manual's plate 18, the pattern as laid out beside plate 8, and the numbers
underneath (DONT_REPEAT 12).

    ~/bpyenv/bin/python tools/blender/coat_template.py --sheet=build/coat/sheet
    python3 tools/blender/coat_sheet.py build/coat/sheet docs/style_test/coat/template_sheet.jpg
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def fit(im, h):
    return im.resize((max(1, int(im.width * h / im.height)), h), Image.LANCZOS)


def row(ims, h, gap=12, bg=(40, 36, 32)):
    ims = [fit(i, h) for i in ims]
    out = Image.new("RGB", (sum(i.width for i in ims) + gap * (len(ims) + 1), h + 2 * gap), bg)
    x = gap
    for i in ims:
        out.paste(i, (x, gap))
        x += i.width + gap
    return out


def label(img, text, size=22):
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype(FONT, size)
    d.rectangle([0, 0, img.width, size + 12], fill=(40, 36, 32))
    d.text((10, 4), text, fill=(235, 225, 205), font=f)
    return img


def main(src, out):
    pics = os.path.join(ROOT, "docs", "concept", "style", "factory", "bold_cowboy_dressed")
    plates = os.path.join(ROOT, "docs", "style_test", "coat", "mitchell_1886")
    open_ = lambda p: Image.open(p).convert("RGB")  # noqa: E731
    r0 = label(row([open_(os.path.join(pics, v + ".png")) for v in ("front", "left", "back")], 520),
               "His coated pictures (the look: knee length, open over his waistcoat, broad notched lapels, half-belt and vent)")
    r1 = label(row([open_(os.path.join(src, v + ".png")) for v in ("front", "side", "back", "three_quarter")], 760),
               "The template alone, on the neutral MakeHuman stand (plain wool colour; no paint yet)")
    r2 = label(row([open_(os.path.join(src, "collar.png")), open_(os.path.join(src, "collar_back.png")),
                    open_(os.path.join(plates, "plate18_collars.jpg"))], 520),
               "Collar and lapels close, beside Mitchell 1886 plate 18 (diagram A: the ordinary collar, stand 1 1/8 in)")
    r3 = label(row([open_(os.path.join(ROOT, "docs", "style_test", "coat", "sack_coat_pattern.png")),
                    open_(os.path.join(plates, "plate08_straight_front_sack.jpg")),
                    open_(os.path.join(plates, "plate16_sleeve.jpg"))], 620),
               "The pattern as laid out (its UVs), beside plates 8 (the sack) and 16 (the sleeve) it was traced from")
    cfg = json.load(open(os.path.join(ROOT, "assets", "people", "garments", "sack_coat.json")))
    t = cfg["template"]
    f = t["faults"]
    st = t["stand"]
    lines = [
        "Numbers (sack_coat.json `template`):",
        "  stand %.3f m, breast over vest %.1f in (Mitchell drafts a 36: widths x %.2f), depth of scye %.1f, natural waist %.1f, length to hem %.1f in (hem: %s)"
        % (st["height_m"], st["breast_over_vest_in"], st["width_scale"], st["depth_of_scye_in"], st["natural_waist_in"], st["full_length_in"], t["hem"]),
        "  DONT_REPEAT 2: shoulder line %.1f mm off his skin (limit 12); collar stand %.1f cm (limit 3.5); collar round over neck round %.2f (limit 1.25)"
        % (f["shoulder_line_max_off_skin_mm"], f["collar_stand_m"] * 100, f["collar_over_neck_girth"]),
        "  triangles %d (budget about 6,000), %d pieces; sleeve round at the elbow %.0f cm, cap scaled x%.2f to his armhole (%.1f in)"
        % (t["triangles"], len(t["pieces"]), t["sleeve"]["tube_round_at_elbow_m"] * 100, t["sleeve"]["cap_width_scale"], t["sleeve"]["armhole_in"]),
        "  the coat's stand-off over the form (its drafted ease, as if buttoned): " + ", ".join("%s %.1f cm" % (e["line"], e["stand_off_m"] * 100) for e in t["ease"]),
        "  laid over drafted area: " + ", ".join("%s %.2f" % (k, v["laid_over_drafted"]) for k, v in t["pieces"].items() if k.endswith("_r") and "fold" not in k),
    ]
    W = max(r.width for r in (r0, r1, r2, r3))
    fnt = ImageFont.truetype(FONT, 24)
    txt = Image.new("RGB", (W, 36 * len(lines) + 30), (40, 36, 32))
    d = ImageDraw.Draw(txt)
    for i, ln in enumerate(lines):
        d.text((14, 14 + 36 * i), ln, fill=(235, 225, 205), font=fnt)
    rows = [r0, r1, r2, r3, txt]
    sheet = Image.new("RGB", (W, sum(r.height for r in rows)), (40, 36, 32))
    y = 0
    for r in rows:
        sheet.paste(r, (0, y))
        y += r.height
    if sheet.width > 2400:
        sheet = sheet.resize((2400, int(sheet.height * 2400 / sheet.width)), Image.LANCZOS)
    sheet.save(out, quality=88, optimize=True)
    print("sheet:", out, sheet.size)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
