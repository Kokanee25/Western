"""The MPFB man's sheets for issue #505 (route B of the character bake-off), from the renders in
build/ (works_check, arm_poses, the bridge shots, screenshots.gd's card table).

    ~/.venvs/studio/bin/python docs/style_test/bakeoff-2026-10/mpfb/make_sheets.py
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.dirname(os.path.abspath(__file__))
B = "build"


def label(im, text):
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 8 + 7 * len(text), 16), fill=(0, 0, 0))
    d.text((4, 2), text, fill=(255, 255, 255))
    return im


def tile(path, w, h, crop=None):
    im = Image.open(path).convert("RGB")
    if crop:
        im = im.crop(crop)
    im.thumbnail((w, h))
    c = Image.new("RGB", (w, h), (40, 40, 40))
    c.paste(im, ((w - im.size[0]) // 2, (h - im.size[1]) // 2))
    return c


def grid(cells, cols, w, h, path):
    rows = (len(cells) + cols - 1) // cols
    s = Image.new("RGB", (cols * w, rows * h), (20, 20, 20))
    for i, (p, text, crop) in enumerate(cells):
        if p and os.path.exists(p):
            s.paste(label(tile(p, w, h, crop), text), ((i % cols) * w, (i // cols) * h))
    s.save(path, quality=88)
    print("wrote", path, s.size)


def poses():
    """Every pose, the MPFB man (top) over the bold cowboy (bottom)."""
    names = [("stand_front", "stand"), ("aim_side", "aim"), ("crouch_side", "crouch"), ("sit_side", "seated"),
             ("hands_up_front", "both arms up"), ("ragdoll_side", "lying dead")]
    cells = []
    for who, d, arms in (("MPFB", "works_mpfb", "arms_mpfb"), ("Studio", "works_ref", "arms_ref")):
        for n, t in names:
            p = os.path.join(B, arms if n.startswith("up_") else d, n + ".png")
            cells.append((p, "%s: %s" % (who, t), None))
    grid(cells, len(names), 260, 400, os.path.join(OUT, "poses.jpg"))


def shots():
    S = os.path.join(B, "shots")
    cells = [
        (os.path.join(S, "s1_saloon_close.png"), "saloon, lamplight, 1.6 m (Studio left, MPFB right)", None),
        (os.path.join(S, "s2_saloon_across.png"), "across the room, 5.6 m, swapped (MPFB left)", None),
        (os.path.join(B, "table_mpfb_drifter", "shot_match_saloon.png"), "the card table: MPFB (Studio extras behind)", None),
        (os.path.join(S, "s3_street_golden_close.png"), "street, golden hour, 1.7 m", None),
        (os.path.join(S, "s3_street_golden_far.png"), "street, golden hour, 5.8 m", None),
        (os.path.join(S, "s3_street_noon_close.png"), "street, noon", None),
        (os.path.join(S, "s4_wound_close.png"), "shot: arm (MPFB), wound and blood", None),
        (os.path.join(S, "s1_down.png"), "both down (ragdoll), belly shots", None),
        (os.path.join(S, "s4_wounds.png"), "shot standing: arm and thigh", None),
    ]
    grid(cells, 2, 640, 360, os.path.join(OUT, "shots.jpg"))


def faces():
    S = os.path.join(B, "shots")
    cells = [(os.path.join(S, "s1_face_mpfb.png"), "MPFB, lamplight, 1.15 m", (300, 0, 660, 360)),
             (os.path.join(S, "s1_face_ref.png"), "Studio, same light and distance", (300, 0, 660, 360)),
             (os.path.join(S, "s3_street_golden_close.png"), "MPFB, golden hour", (180, 80, 420, 320)),
             (os.path.join(S, "s3_street_golden_close.png"), "Studio, golden hour", (520, 80, 760, 320)),
             (os.path.join(B, "pv_teamster.png"), "the second man (timing test), Blender preview", None)]
    grid(cells, 5, 360, 360, os.path.join(OUT, "faces.jpg"))


if __name__ == "__main__":
    poses()
    shots()
    faces()
