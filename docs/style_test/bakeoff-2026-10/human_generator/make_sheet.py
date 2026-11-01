"""The Human Generator man's sheet for issue #522 (route C of the character bake-off), from the
bridge shots in build/hgshots/ (game renders only: the man's own files stay in the private Studio).

    ~/.venvs/studio/bin/python docs/style_test/bakeoff-2026-10/human_generator/make_sheet.py
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


def shot(name, w=640, h=360):
    return Image.open(os.path.join(S, name)).convert("RGB").resize((w, h))


def face(name, w=320):
    return Image.open(os.path.join(S, name)).convert("RGB").crop((390, 110, 890, 610)).resize((w, w))


def main():
    cells = [("s1_saloon_close.png", "saloon, lamplight 21:30, 1.6 m (Human Generator left)"),
             ("s2_saloon_across.png", "saloon, across the room, 5.5 m (Human Generator right)"),
             ("s3_street_close.png", "street, 14:00, 1.7 m (Human Generator left)"),
             ("s4_street_across.png", "street, across, 5.8 m (Human Generator left)")]
    sheet = Image.new("RGB", (1280, 360 * 2 + 320 + 360), (20, 20, 20))
    for i, (n, t) in enumerate(cells):
        sheet.paste(label(shot(n), t), ((i % 2) * 640, (i // 2) * 360))
    y = 720
    for i, (n, t) in enumerate([("f1_saloon_hg.png", "HG, saloon"), ("f1_saloon_ref.png", "bold cowboy, saloon"),
                                ("f2_street_hg.png", "HG, street"), ("f2_street_ref.png", "bold cowboy, street")]):
        sheet.paste(label(face(n), t), (i * 320, y))
    sheet.paste(label(shot("s5_street_golden.png"), "street, golden hour 17:36, 1.7 m (Human Generator left)"), (0, y + 320))
    sk = Image.open(os.path.join(S, "skin_head.jpg")).convert("RGB").resize((360, 360)) if os.path.exists(os.path.join(S, "skin_head.jpg")) else None
    if sk:
        sheet.paste(label(sk, "his face in the baked skin (haircap painted)"), (640, y + 320))
    sheet.save(os.path.join(OUT, "sheet.jpg"), quality=88)
    print("wrote", os.path.join(OUT, "sheet.jpg"), sheet.size)


if __name__ == "__main__":
    main()
