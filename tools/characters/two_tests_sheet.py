"""Sheets for the two tests (docs/style_test/two-tests-2026-10-19): images in a grid, labelled.

    python3 tools/characters/two_tests_sheet.py --out=SHEET.png --title="..." \\
        --cols="A,B,C" --rows="front,side" --cells="a.png|crop,b.png,...;..." [--notes="line|line"]
        [--width=1800]

Each row is `;`-separated, each cell `,`-separated; a cell is a path, optionally `path@x0:y0:x1:y1`
(a crop, as shares of the image 0..1). Cells in a row are scaled to one height.
"""
import sys

from PIL import Image, ImageDraw, ImageFont

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def font(size, bold=False):
    try:
        return ImageFont.truetype(BOLD if bold else FONT, size)
    except OSError:
        return ImageFont.load_default()


def load(cell):
    path, _, crop = cell.partition("@")
    im = Image.open(path).convert("RGB")
    if crop:
        x0, y0, x1, y1 = (float(c) for c in crop.split(":"))
        im = im.crop((int(x0 * im.width), int(y0 * im.height), int(x1 * im.width), int(y1 * im.height)))
    return im


def sheet(out, title, cols, rows, cells, notes=(), width=1800):
    label_w = 150 if any(rows) else 0
    head_h, col_h, pad = 60, 34, 8
    cw = (width - label_w - pad * (len(cols) + 1)) // max(len(cols), 1)
    strips = []
    for row in cells:
        ims = [load(c) if c else None for c in row]
        h = max(int(im.height * cw / im.width) for im in ims if im is not None)
        strips.append((ims, h))
    nf = font(18)
    wrapped = []
    for n in notes:
        line = ""
        for word in n.split(" "):
            if nf.getlength(line + " " + word) > width - 4 * pad and line:
                wrapped.append(line)
                line = word
            else:
                line = (line + " " + word).strip()
        wrapped.append(line)
    notes = wrapped
    note_h = 26 * len(notes) + (16 if notes else 0)
    H = head_h + col_h + sum(h + pad for _ims, h in strips) + note_h + pad
    canvas = Image.new("RGB", (width, H), (34, 34, 36))
    d = ImageDraw.Draw(canvas)
    tf = font(26, True)
    while tf.getlength(title) > width - 4 * pad and tf.size > 12:
        tf = font(tf.size - 1, True)
    d.text((pad * 2, 14), title, fill=(235, 230, 220), font=tf)
    for i, c in enumerate(cols):
        x = label_w + pad + i * (cw + pad)
        cf = font(20, True)
        while cf.getlength(c) > cw - 8 and cf.size > 11:
            cf = font(cf.size - 1, True)
        d.text((x + 4, head_h + 4), c, fill=(220, 210, 190), font=cf)
    y = head_h + col_h
    for r, (ims, h) in enumerate(strips):
        if r < len(rows) and rows[r]:
            d.text((pad, y + h // 2 - 10), rows[r], fill=(200, 200, 200), font=font(18))
        for i, im in enumerate(ims):
            x = label_w + pad + i * (cw + pad)
            if im is None:
                continue
            s = im.resize((cw, int(im.height * cw / im.width)), Image.LANCZOS)
            if s.height > h:
                s = s.crop((0, 0, cw, h))
            canvas.paste(s, (x, y + (h - s.height) // 2))
        y += h + pad
    y += 8
    for n in notes:
        d.text((pad * 2, y), n, fill=(210, 205, 195), font=font(18))
        y += 26
    canvas.save(out)
    print("two_tests_sheet: wrote", out, canvas.size)


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    cols = a.get("--cols", "").split(",")
    rows = a.get("--rows", "").split(",") if a.get("--rows") else []
    cells = [r.split(",") for r in a["--cells"].split(";")]
    notes = a["--notes"].split("|") if a.get("--notes") else []
    sheet(a["--out"], a.get("--title", ""), cols, rows, cells, notes, int(a.get("--width", 1800)))


if __name__ == "__main__":
    main()
