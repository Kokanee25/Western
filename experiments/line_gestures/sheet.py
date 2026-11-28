#!/usr/bin/env python3
"""Lays out sheet.gd's frames (#1316): each tag's line caught on its beat, before (gestures off: the
game as it was) beside after, and the listeners. Usage: python3 sheet.py FRAMES_DIR OUT.jpg"""
import os
import sys

from PIL import Image, ImageDraw

TAGS = ["angry", "laughing", "mocking", "scared", "sly", "sad", "low", "proud", "pleading", "calm", "listeners"]
LINES = {
    "angry": "You *never paid me for that horse.", "laughing": "And the mule walked in after him!",
    "mocking": "Your mother still *dress you, Wilbur?", "scared": "Somebody's out there. I *heard him.",
    "sly": "I never saw a *thing, Marshal.", "sad": "She was a good woman. *Too good for here.",
    "low": "Don't look now. He's *watching us.", "proud": "Built every board of it *myself.",
    "pleading": "Please, mister. I got *children.", "calm": "Coffee's on, if you want it.",
    "listeners": "mocking, to the man on the right; a third by",
}


def main():
    src, out = sys.argv[1], sys.argv[2]
    cell = 260
    cols = 4  # tag pairs a row: before | after
    rows = (len(TAGS) + 1) // 2
    W, H = cell * cols, (cell + 34) * rows
    sheet = Image.new("RGB", (W, H), (30, 28, 26))
    d = ImageDraw.Draw(sheet)
    for i, tag in enumerate(TAGS):
        r, c = divmod(i, 2)
        x0, y0 = c * 2 * cell, r * (cell + 34)
        for j, mode in enumerate(["before", "after"]):
            p = os.path.join(src, "%s_%s.png" % (mode, tag))
            if os.path.exists(p):
                im = Image.open(p).convert("RGB").resize((cell, cell))
                sheet.paste(im, (x0 + j * cell, y0 + 34))
            f = os.path.join(src, "%s_%s_face.png" % (mode, tag))
            if os.path.exists(f):  # his face inset, top right
                fi = Image.open(f).convert("RGB").crop((70, 50, 350, 330)).resize((cell * 2 // 5, cell * 2 // 5))
                sheet.paste(fi, (x0 + j * cell + cell - fi.width - 2, y0 + 36))
            d.text((x0 + j * cell + 4, y0 + 36), mode, fill=(255, 255, 200))
        d.text((x0 + 4, y0 + 2), tag.upper(), fill=(255, 220, 150))
        d.text((x0 + 4, y0 + 17), LINES[tag], fill=(220, 220, 220))
    sheet.save(out, quality=88)
    print("wrote", out, sheet.size)


if __name__ == "__main__":
    main()
