"""A before/after sheet for a garment step (docs/briefs/garments.md): today's man, the new man and
his pictures side by side, whole and close up (collar, armpits, waist, sleeves).

    python3 tools/characters/garment_sheet.py --before=build/lab_bold_cowboy_vest_layered \\
        --after=build/lab_bold_cowboy_made_layered --pictures=docs/concept/style/factory/bold_cowboy_armsout_dressed \\
        --out=docs/style_test/garments-2026-10-18/g1_shirt.png [--before_head=DIR --after_head=DIR]

Each lab dir holds game_neutral_<turn>.png from tools/characters/lab_run.sh (the whole man at
--fov=6 --dist=20 --aim=0.95; a head dir at --fov=16 --dist=2.0 --aim=1.55). Rows: the whole man
at 0/90/180 beside the front/left/back pictures; then the head-and-shoulders turns; then crops.
"""
import os
import sys

from PIL import Image, ImageDraw

# Close-ups (shares of a render's width and height): off the head-and-shoulders render at 0
# (the collar, the right armpit) and the whole-man render at 0 (the waist, the left sleeve).
CROPS = {"collar": ("head", (0.40, 0.33, 0.60, 0.52)), "armpit": ("head", (0.58, 0.40, 0.74, 0.62)),
         "waist": ("whole", (0.42, 0.38, 0.58, 0.50)), "sleeve": ("whole", (0.57, 0.20, 0.68, 0.52))}
# The same places in a front picture (the figure fills about the middle 45% of it).
PIC_CROPS = {"collar": (0.42, 0.11, 0.58, 0.24), "armpit": (0.56, 0.22, 0.70, 0.38), "waist": (0.40, 0.42, 0.60, 0.56),
             "sleeve": (0.60, 0.24, 0.72, 0.54)}
# A picture cut to its figure (the backdrop either side dropped).
PIC_FIGURE = (0.24, 0.0, 0.76, 1.0)


def load(path, size=None):
    im = Image.open(path).convert("RGB")
    if size:
        im = im.resize(size, Image.LANCZOS)
    return im


def crop(im, box):
    w, h = im.size
    return im.crop((int(box[0] * w), int(box[1] * h), int(box[2] * w), int(box[3] * h)))


def row(images, height, labels=None, gap=8):
    tiles = []
    for k, im in enumerate(images):
        t = im.resize((int(im.width * height / im.height), height), Image.LANCZOS)
        if labels:
            d = ImageDraw.Draw(t)
            d.rectangle([0, 0, 8 * len(labels[k]) + 6, 14], fill=(0, 0, 0))
            d.text((3, 1), labels[k], fill=(255, 230, 120))
        tiles.append(t)
    out = Image.new("RGB", (sum(t.width for t in tiles) + gap * (len(tiles) - 1), height), (60, 60, 60))
    x = 0
    for t in tiles:
        out.paste(t, (x, 0))
        x += t.width + gap
    return out


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    before, after, pics, out = a["--before"], a["--after"], a["--pictures"], a["--out"]
    rows = []
    # The whole man: three turns each, the pictures beside.
    whole = []
    labels = []
    for turn, pic in ((0, "front"), (90, "left"), (180, "back")):
        b = load(os.path.join(before, "game_neutral_%d.png" % turn))
        n = load(os.path.join(after, "game_neutral_%d.png" % turn))
        w, h = b.size
        whole += [b.crop((int(w * 0.33), 0, int(w * 0.67), h)), n.crop((int(w * 0.33), 0, int(w * 0.67), h)),
                  crop(load(os.path.join(pics, pic + ".png")), PIC_FIGURE)]
        labels += ["before %d" % turn, "after %d" % turn, "picture " + pic]
    rows.append(row(whole, 440, labels))
    if "--before_head" in a and "--after_head" in a:
        heads, labels = [], []
        for turn in (0, 45, 90):
            for name, d in (("before", a["--before_head"]), ("after", a["--after_head"])):
                im = load(os.path.join(d, "game_neutral_%d.png" % turn))
                w, h = im.size
                heads.append(im.crop((int(w * 0.28), 0, int(w * 0.72), h)))
                labels.append("%s %d" % (name, turn))
        heads.append(crop(load(os.path.join(pics, "front.png")), (0.36, 0.08, 0.64, 0.36)))
        labels.append("picture")
        rows.append(row(heads, 360, labels))
    # Close-ups off the front render and the front picture.
    src = {"whole": (load(os.path.join(before, "game_neutral_0.png")), load(os.path.join(after, "game_neutral_0.png")))}
    if "--before_head" in a and "--after_head" in a:
        src["head"] = (load(os.path.join(a["--before_head"], "game_neutral_0.png")), load(os.path.join(a["--after_head"], "game_neutral_0.png")))
    p0 = load(os.path.join(pics, "front.png"))
    crops, labels = [], []
    for name, (which, box) in CROPS.items():
        if which not in src:
            continue
        b0, n0 = src[which]
        crops += [crop(b0, box), crop(n0, box), crop(p0, PIC_CROPS[name])]
        labels += ["before " + name, "after " + name, "picture " + name]
        if len(crops) == 6:
            rows.append(row(crops, 300, labels))
            crops, labels = [], []
    if crops:
        rows.append(row(crops, 300, labels))
    width = max(r.width for r in rows)
    sheet = Image.new("RGB", (width, sum(r.height for r in rows) + 10 * (len(rows) - 1)), (60, 60, 60))
    y = 0
    for r in rows:
        sheet.paste(r, (0, y))
        y += r.height + 10
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print("garment_sheet: wrote %s (%dx%d)" % (out, sheet.width, sheet.height))


if __name__ == "__main__":
    main()
