#!/usr/bin/env python3
"""The sheet Sean judges an art change by (2026-10-12: "the gate is Sean's eye, not the judge"):
the painting, the render before and the render after side by side, and under them the area that
changed at three times, the same crop from each.

    python3 tools/review_sheet.py PAINTING BEFORE AFTER OUT --crop=x0,y0,x1,y1 [--crop=...]
                                  [--title="Job 1: the road"]

Crops are in the 1280x720 frame (the painting is scaled to it first). Renders keep their pixels
(nearest); the painting is scaled smoothly. Each row is three panels; a crop wider than a third of
the sheet is scaled down to fit, still nearest.
"""
import sys

from PIL import Image, ImageDraw

W, H = 1280, 720
PANEL = 600  # each of the three panels' width on the sheet
GAP = 8
INK = (230, 210, 175)
BG = (16, 12, 10)


def load(path: str, smooth: bool) -> Image.Image:
    img = Image.open(path).convert("RGB")
    return img.resize((W, H), Image.LANCZOS if smooth else Image.NEAREST) if img.size != (W, H) else img


def main() -> None:
    pos = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = [a for a in sys.argv[1:] if a.startswith("--")]
    if len(pos) != 4:
        print(__doc__)
        sys.exit(1)
    painting, before, after = load(pos[0], True), load(pos[1], False), load(pos[2], False)
    crops = [tuple(int(v) for v in o.split("=", 1)[1].split(",")) for o in opts if o.startswith("--crop=")]
    title = next((o.split("=", 1)[1] for o in opts if o.startswith("--title=")), "")
    names = ("painting", "before", "after")
    imgs = (painting, before, after)
    rows = [[im.resize((PANEL, PANEL * H // W), Image.LANCZOS if i == 0 else Image.NEAREST)
             for i, im in enumerate(imgs)]]
    for x0, y0, x1, y1 in crops:
        s = min(3.0, PANEL / (x1 - x0))
        size = (round((x1 - x0) * s), round((y1 - y0) * s))
        rows.append([im.crop((x0, y0, x1, y1)).resize(size, Image.NEAREST) for im in imgs])
    head = 28 if title else 0
    height = head + sum(r[0].height + 20 + GAP for r in rows)
    sheet = Image.new("RGB", (PANEL * 3 + GAP * 4, height), BG)
    d = ImageDraw.Draw(sheet)
    if title:
        d.text((GAP, 8), title, fill=INK)
    y = head
    for ri, row in enumerate(rows):
        for i, im in enumerate(row):
            x = GAP + i * (PANEL + GAP)
            sheet.paste(im, (x, y))
            label = names[i] if ri == 0 else "%s x%.0f" % (names[i], im.width / (crops[ri - 1][2] - crops[ri - 1][0]))
            d.text((x + 4, y + im.height + 4), label, fill=INK)
        y += row[0].height + 20 + GAP
    sheet.save(pos[3])
    print(pos[3])


if __name__ == "__main__":
    main()
