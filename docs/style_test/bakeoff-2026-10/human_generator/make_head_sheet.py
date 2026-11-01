"""The corrected Human Generator head's sheet (#522, after Sean's "unacceptable"): bald,
clean-shaven, in the Studio turntable's neutral light (one sun, warm ambient, orthographic: Studio
studio/godot/turntable.gd run in this checkout) beside bold_cowboy_s3_talking, and the untextured
shapes before and after the face fit. Game renders and shape renders only.

    ~/.venvs/studio/bin/python docs/style_test/bakeoff-2026-10/human_generator/make_head_sheet.py
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.dirname(os.path.abspath(__file__))
S = "build/hgshots"


def label(im, text):
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 8 + 6 * len(text), 15), fill=(0, 0, 0))
    d.text((4, 2), text, fill=(255, 255, 255))
    return im


def main():
    sheet = Image.new("RGB", (1200, 200 * 2 + 300), (20, 20, 20))
    for k, t in enumerate(["front", "three-quarter", "profile"]):
        im = Image.open(os.path.join(S, "head_turn_%d.png" % k)).convert("RGB").resize((600, 300))
        sheet.paste(label(im, "%s: corrected head (left), bold cowboy (right)" % t), ((k % 2) * 600, (k // 2) * 300))
    shp = Image.open(os.path.join(S, "shape_view.jpg")).convert("RGB")
    w = 600
    shp = shp.resize((w, int(shp.size[1] * w / shp.size[0])))
    sheet.paste(label(shp, "shape: HG neutral | corrected | bold cowboy"), (600, 300))
    sheet = sheet.crop((0, 0, 1200, 600))
    sheet.save(os.path.join(OUT, "head_sheet.jpg"), quality=90)
    print("wrote", os.path.join(OUT, "head_sheet.jpg"), sheet.size)


if __name__ == "__main__":
    main()
