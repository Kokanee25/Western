"""Human Generator in Blender against the same men in the game (#522, Sean: "you are using Human
Generator, right?"). Left: Blender/Cycles, its own strand hair, subsurface skin and materials
(Studio tools/humgen/hg_render.py, renders copied to build/hgrenders/). Right: the same men in the
game (build/realshots/, the real_sheet's faces). Renders only.

    ~/.venvs/studio/bin/python docs/style_test/bakeoff-2026-10/human_generator/make_blender_sheet.py
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.dirname(os.path.abspath(__file__))
R, S = "build/hgrenders", "build/realshots"


def label(im, text):
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 8 + 6 * len(text), 15), fill=(0, 0, 0))
    d.text((4, 2), text, fill=(255, 255, 255))
    return im


def main():
    H = 400
    sheet = Image.new("RGB", (320 * 3 + 233 * 1, H * 2), (20, 20, 20))
    for row, (man, who, tag) in enumerate([("hg_real_cowboy", "cowboy", "realistic cowboy"), ("hg_real_rancher", "rancher", "rancher")]):
        p = Image.open(os.path.join(R, man + "_portrait.png")).convert("RGB").resize((320, H))
        sheet.paste(label(p, "%s: Blender (Cycles, strand hair)" % tag), (0, row * H))
        for k, place in enumerate(("saloon", "street")):
            f = Image.open(os.path.join(S, "f_%s_%s.png" % (place, who))).convert("RGB").crop((440, 110, 840, 610)).resize((320, H))
            sheet.paste(label(f, "%s: in the game, %s" % (tag, place)), (320 * (k + 1), row * H))
        b = Image.open(os.path.join(R, man + "_full.png")).convert("RGB")
        b = b.resize((233, H))
        sheet.paste(label(b, "Blender, full"), (960, row * H))
    sheet.save(os.path.join(OUT, "blender_vs_game.jpg"), quality=90)
    print("wrote", os.path.join(OUT, "blender_vs_game.jpg"), sheet.size)


if __name__ == "__main__":
    main()
