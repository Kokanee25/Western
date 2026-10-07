"""A blind critic's packet for the seated man (the characters session's experiments,
docs/screenshots/tripo/experiments/): the master painting's own crops beside anonymous crops of
each render, the labels shuffled, the key kept apart.

    python3 tools/characters/critic_pack.py --out=DIR --master=DIR_OF_MASTER_CROPS \\
        --render=NAME:PATH [--render=NAME:PATH ...] [--seed=N] [--boxes=name:x0,y0,x1,y1;...]

Each render is a 1280x720 shot_match_saloon.png (or any render of the same shot). For each box
(BOXES: the face, eyes, nose and moustache, ear, collar and coat of the seated man in the saloon
shot), DIR/<box>.png lays out the master's crop of that feature (master/<file>, as Sean cut it,
04_MASTER_nose_moustache_philtrum_mouth.png and so on) and the renders' crops, each scaled with
nearest neighbour to the same height and labelled only A, B, C... in an order shuffled once per
packet (seed). DIR/key.json says which label is which render: the lead keeps it; the critic gets
DIR/*.png and DIR/prompt.md only.
"""
import json
import os
import random
import sys

from PIL import Image, ImageDraw

# Boxes in the 1280x720 saloon shot: each master crop found in 01_MASTER_full_saloon.png (1536 wide,
# every crop there at 3.5x) and scaled by 1280/1536 (the shot's camera is fitted to the painting's).
# The ear is the exception: the master shows his right ear (screen left), our man's head turn shows
# his left ear (screen right), so that box is our visible ear.
BOXES = {
    "face": ((403, 218, 594, 423), "02_MASTER_face_close.png"),
    "eyes": ((432, 243, 568, 304), "03_MASTER_eyes_brows.png"),
    "nose_moustache": ((440, 285, 568, 374), "04_MASTER_nose_moustache_philtrum_mouth.png"),
    "ear": ((538, 262, 581, 332), "05_MASTER_ear.png"),
    "collar": ((418, 353, 542, 426), "06_MASTER_collar_neckerchief.png"),
    "hat": ((412, 215, 584, 268), "07_MASTER_hat_brim.png"),
    "coat": ((400, 322, 483, 422), "08_MASTER_coat_shoulders_cells.png"),
}
HEIGHT = 420

PROMPT = """You are a blind art critic. You are judging whether 3D game renders of a character are
painted in the same visual language as a master painting. You know nothing about how any render
was made. Look only at the images in this folder.

Each image is one feature. The leftmost panel, labelled MASTER, is cut from the master painting:
it is the authority on style. The other panels, labelled A, B, C..., are the same feature from
different renders of a game character. They are anonymous and in no particular order.

The master's style: a realistic, three-dimensional Western character drawn in deliberate, crisp,
square clusters of colour (about 6-8 screen pixels each at the shot's size), with the important
features (eyes, lids, brows, nostrils, the moustache with a small gap of skin at the middle of
the upper lip, the mouth, ears, the collar and its shadow) kept at a finer, deliberate drawing.

For EACH feature image, score each lettered panel from 1 (far from the master) to 5 (as the
master) on:
  1. square regularity: are the squares regular, even, authored, on a steady grid, or slanted,
     trapezoidal, fragmented, uneven?
  2. crispness: hard, intentional edges, or soft, muddy, averaged?
  3. 3D form: does the shape read as a solid, three-dimensional form?
  4. semantic readability: can you tell what each part is (eye, lid, nostril, moustache masses
     and the philtrum gap, lip, ear rim and hollow, collar edge and its shadow)?
  5. resemblance to the MASTER'S STYLE (the visual language, not the person's likeness).
Do not judge which looks more realistic, and do not judge likeness to the master's man.

Then, for each feature, one or two sentences on the single biggest difference between the best
panel and the master, and the single biggest flaw of the worst panel, pointing at where in the
panel it is.

Write your answer as a table per feature (rows A, B, C...; columns the five scores) followed by the
notes, then a final ranking of the panels over all features with one line of reasons each.
"""


def main():
    out, master, renders, seed = None, None, [], 1882
    for a in sys.argv[1:]:
        if a.startswith("--out="):
            out = a.split("=", 1)[1]
        elif a.startswith("--master="):
            master = a.split("=", 1)[1]
        elif a.startswith("--render="):
            name, path = a.split("=", 1)[1].split(":", 1)
            renders.append((name, path))
        elif a.startswith("--seed="):
            seed = int(a.split("=", 1)[1])
    os.makedirs(out, exist_ok=True)
    order = list(range(len(renders)))
    random.Random(seed).shuffle(order)
    labels = {chr(ord("A") + i): renders[j][0] for i, j in enumerate(order)}
    for box, (rect, mfile) in BOXES.items():
        panels = [("MASTER", Image.open(os.path.join(master, mfile)).convert("RGB"))]
        for i, j in enumerate(order):
            panels.append((chr(ord("A") + i), Image.open(renders[j][1]).convert("RGB").crop(rect)))
        scaled = []
        for lab, im in panels:
            w = max(1, round(im.width * HEIGHT / im.height))
            scaled.append((lab, im.resize((w, HEIGHT), Image.NEAREST)))
        sheet = Image.new("RGB", (sum(im.width for _, im in scaled) + 12 * (len(scaled) - 1), HEIGHT + 28), (18, 18, 18))
        x = 0
        d = ImageDraw.Draw(sheet)
        for lab, im in scaled:
            sheet.paste(im, (x, 28))
            d.text((x + 6, 6), lab, fill=(255, 255, 255))
            x += im.width + 12
        sheet.save(os.path.join(out, box + ".png"))
    open(os.path.join(out, "prompt.md"), "w").write(PROMPT)
    os.makedirs(os.path.join(out, "..", "keys"), exist_ok=True)
    json.dump({"seed": seed, "labels": labels, "renders": dict(renders)},
              open(os.path.join(out, "..", "keys", os.path.basename(os.path.normpath(out)) + "_key.json"), "w"), indent=1)
    print("packet", out, "labels kept in keys/")


if __name__ == "__main__":
    main()
