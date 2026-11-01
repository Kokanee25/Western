"""The realistic men's sheet (#522, Sean 2026-11-01: "see what real looking characters will look like
in game", a possible change of art style): hg_real_cowboy (the bold cowboy, realistic), hg_real_rancher
(a second man of the Studio's own design) and, for comparison, the painted bold_cowboy_s3_talking, in
the saloon by lamplight and the street by day, close and across, and their faces. Game renders only
(the men's own files stay in the private Studio).

    ~/.venvs/studio/bin/python docs/style_test/bakeoff-2026-10/human_generator/make_real_sheet.py
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.dirname(os.path.abspath(__file__))
S = "build/realshots"


def label(im, text):
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 8 + 6 * len(text), 15), fill=(0, 0, 0))
    d.text((4, 2), text, fill=(255, 255, 255))
    return im


def shot(n, w=640, h=360):
    return Image.open(os.path.join(S, n)).convert("RGB").resize((w, h))


def face(n, w=320):
    return Image.open(os.path.join(S, n)).convert("RGB").crop((390, 110, 890, 610)).resize((w, w))


def main():
    order = "left to right: rancher (realistic), cowboy (realistic), bold cowboy (painted)"
    sal = "left to right: bold cowboy (painted), cowboy (realistic), rancher (realistic)"
    cells = [("s1_saloon_close.png", "saloon, lamplight 21:30, close; " + sal),
             ("s2_saloon_across.png", "saloon, across the room (5.5 m); " + sal),
             ("s3_street_close.png", "street 14:00, close; " + order),
             ("s4_street_across.png", "street 14:00, across (5.8 m); " + order)]
    sheet = Image.new("RGB", (1280, 720 + 2 * 214 + 360), (20, 20, 20))
    for i, (n, t) in enumerate(cells):
        sheet.paste(label(shot(n), t), ((i % 2) * 640, (i // 2) * 360))
    y = 720
    for row, (place, names) in enumerate([("saloon", "f_saloon_%s.png"), ("street", "f_street_%s.png")]):
        for k, (who, t) in enumerate([("rancher", "rancher (realistic)"), ("cowboy", "cowboy (realistic)"), ("ref", "bold cowboy (painted)")]):
            sheet.paste(label(face(names % who, 214), "%s, %s" % (t, place)), (k * 214, y + row * 214))
    sheet.paste(label(shot("s5_street_golden.png"), "street, golden hour 17:36; " + order), (640, 720))
    sheet = sheet.crop((0, 0, 1280, 720 + 2 * 214))
    sheet.save(os.path.join(OUT, "real_sheet.jpg"), quality=90)
    print("wrote", os.path.join(OUT, "real_sheet.jpg"), sheet.size)


if __name__ == "__main__":
    main()
