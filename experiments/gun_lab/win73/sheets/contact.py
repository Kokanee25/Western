"""A contact sheet of the first-person shots (fp_game.txt): every PNG in DIR, named, 3 a row.

    python3 experiments/gun_lab/win73/sheets/contact.py build/win73_fp OUT.jpg [--width=480]
"""
import os
import sys

from PIL import Image, ImageDraw


def main(argv):
    src, out = argv[1], argv[2]
    width = int(next((a.split("=")[1] for a in argv if a.startswith("--width=")), 480))
    names = sorted(n for n in os.listdir(src) if n.endswith(".png"))
    if not names:
        print("no shots in", src)
        return 1
    cells = []
    for n in names:
        im = Image.open(os.path.join(src, n)).convert("RGB")
        im = im.resize((width, int(im.height * width / im.width)), Image.LANCZOS)
        d = ImageDraw.Draw(im)
        d.rectangle([0, 0, width, 18], fill=(0, 0, 0))
        d.text((6, 3), n[:-4].replace("_", " "), fill=(255, 255, 255))
        cells.append(im)
    cols = 3
    h = cells[0].height
    sheet = Image.new("RGB", (cols * width, ((len(cells) + cols - 1) // cols) * h), (20, 20, 20))
    for i, c in enumerate(cells):
        sheet.paste(c, ((i % cols) * width, (i // cols) * h))
    sheet.save(out, quality=88)
    print(out, sheet.size)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
