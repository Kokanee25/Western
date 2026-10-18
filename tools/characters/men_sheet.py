"""Sean's sheet of the men who work (tools/characters/men.py): them side by side in four poses
from tools/people_lineup.gd (two to a row), and an in-game shot of the street with them in it.

    python3 tools/characters/men_sheet.py --lineup=DIR --game=street.png --out=sheet.jpg
        [--poses=stand:three_quarter,run:side,hands_up:three_quarter,fall:three_quarter]
"""
import sys

import numpy as np
from PIL import Image, ImageDraw

WIDTH = 1600


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    poses = [p.split(":") for p in a.get("--poses", "stand:three_quarter,run:side,hands_up:three_quarter,"
                                                   "fall:three_quarter").split(",")]
    rows = []
    for pose, view in poses:
        im = Image.open("%s/%s_%s.png" % (a["--lineup"], pose, view)).convert("RGB")
        # Trimmed to the men (the lineup's grey round them).
        px = np.asarray(im)
        mask = Image.fromarray(((px != px[2, 2]).any(-1) * 255).astype(np.uint8))
        box = mask.getbbox() or (0, 0, im.width, im.height)
        im = im.crop((max(box[0] - 20, 0), max(box[1] - 20, 0), min(box[2] + 20, im.width), min(box[3] + 20, im.height)))
        rows.append(("%s (%s)" % (pose.replace("_", " "), view.replace("_", " ")), im))
    # Two poses a row, each half the sheet wide, a row as tall as its taller.
    half = WIDTH // 2
    pairs = []
    for k in range(0, len(rows), 2):
        two = [(lab, im.resize((half, int(im.height * half / im.width)))) for lab, im in rows[k:k + 2]]
        h = max(im.height for _, im in two)
        row = Image.new("RGB", (WIDTH, h), (128, 128, 132))
        for j, (_, im) in enumerate(two):
            row.paste(im, (j * half, (h - im.height) // 2))
        pairs.append(("    |    ".join(lab for lab, _ in two), row))
    rows = pairs
    game = Image.open(a["--game"]).convert("RGB")
    rows.append(("in the game", game.resize((WIDTH, int(game.height * WIDTH / game.width)))))
    pad = 28
    sheet = Image.new("RGB", (WIDTH, sum(im.height + pad for _, im in rows)), (34, 34, 34))
    d = ImageDraw.Draw(sheet)
    y = 0
    for label, im in rows:
        d.text((8, y + 8), label, fill=(235, 235, 235))
        sheet.paste(im, (0, y + pad))
        y += im.height + pad
    sheet.save(a["--out"], quality=88)
    print("men_sheet: wrote", a["--out"], sheet.size)


if __name__ == "__main__":
    main()
