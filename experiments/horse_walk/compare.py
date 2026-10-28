"""Matched-phase pairs: the reference clip's horse at an event of its clean stride (contacts,
lift-offs; frames from reference/measurements.json) beside ours at the same event, ours mirrored to
face the same way (both show the left side). Also writes the reference crops alone.

    python3 experiments/horse_walk/compare.py     (needs the stills: render.py --phases=... --name=pairs;
                                                   the clip's frames and pan.json if there, else
                                                   reference/crops/)
"""
import json
import os

from PIL import Image, ImageDraw, ImageOps

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
B = os.path.join(ROOT, "build", "horse_walk")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "compare")
REF = os.path.join(os.path.dirname(os.path.abspath(__file__)), "reference")

# event: (clip frame, our phase). Our walk: LH lands 0, LF 0.30, RH 0.5, RF 0.80; each stance 0.62.
EVENTS = [
    ("LH contact", 106, 0.0),
    ("RH lift-off", 117, 0.12),
    ("LF contact", 135, 0.30),
    ("RH contact", 144, 0.5),
    ("LH lift-off", 159, 0.62),
    ("LF mid-stance", 160, 0.61),
    ("RF contact", 172, 0.80),
    ("LF lift-off", 184, 0.92),
]


def ref_crop(f):
    """The clip's horse at frame f; without the clip (it isn't in the repo), the committed crop."""
    if not os.path.exists(os.path.join(B, "frames", "f%03d.png" % (f + 1))):
        return Image.open(os.path.join(REF, "crops", "f%03d.jpg" % f)).convert("RGB")
    pan = json.load(open(os.path.join(B, "pan.json")))["pan"]
    sp = json.load(open(os.path.join(B, "speed.json")))
    k = min(range(len(sp["frames"])), key=lambda i: abs(sp["frames"][i] - f))
    cx = sp["x"][k] + pan[f] + 15
    im = Image.open(os.path.join(B, "frames", "f%03d.png" % (f + 1))).convert("RGB")
    return im.crop((int(cx - 200), 215, int(cx + 200), 507)).resize((800, 584), Image.LANCZOS)


def ours(ph):
    im = Image.open(os.path.join(B, "pairs", "p%03d.png" % int(round(ph * 1000)))).convert("RGB")
    im = ImageOps.mirror(im)
    w, h = im.size
    return im.crop((int(w * 0.04), int(h * 0.02), int(w * 0.96), int(h * 0.97))).resize((800, 584), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(os.path.join(REF, "crops"), exist_ok=True)
    cells = []
    for name, f, ph in EVENTS:
        a, b = ref_crop(f), ours(ph)
        if not os.path.exists(os.path.join(REF, "crops", "f%03d.jpg" % f)):
            a.save(os.path.join(REF, "crops", "f%03d.jpg" % f), quality=85)
        pair = Image.new("RGB", (1600, 584 + 30), (255, 255, 255))
        pair.paste(a, (0, 30))
        pair.paste(b, (800, 30))
        d = ImageDraw.Draw(pair)
        d.text((8, 8), "%s   left: reference (clip frame %d)   right: ours (phase %.2f)" % (name, f, ph), fill=(0, 0, 0))
        slug = name.lower().replace(" ", "_").replace("-", "")
        pair.save(os.path.join(OUT, "pair_%s.jpg" % slug), quality=85)
        cells.append(pair.resize((800, 307), Image.LANCZOS))
    sheet = Image.new("RGB", (1600, 307 * ((len(cells) + 1) // 2)), (255, 255, 255))
    for i, c in enumerate(cells):
        sheet.paste(c, ((i % 2) * 800, (i // 2) * 307))
    sheet.save(os.path.join(OUT, "pairs_sheet.jpg"), quality=82)
    print("wrote", len(cells), "pairs to", OUT)


if __name__ == "__main__":
    main()
