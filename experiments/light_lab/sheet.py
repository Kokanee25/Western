#!/usr/bin/env python3
"""The light lab's before/after sheet (issue #608 part 1).

    python3 experiments/light_lab/sheet.py DIR OUT.png [VIEW ...]

DIR is a screenshots.gd --variants=room_on.json,room_off.json run: each VIEW.png (before: the
game's light), VIEW_room_on.png (after: RoomLight on) and VIEW_room_off.png (off again). The sheet
has a row a view, before | after, each at 640 wide, labelled. It prints, for each view, how far
"off again" is from "before" (max channel difference and pixels differing: 0 is the old look
exactly) and the after's change in mean lightness by region (the room's back third, the floor)."""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

W = 640


def lum(a):
    a = a[..., :3].astype(np.float32) / 255.0
    return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]


def main():
    src, out = sys.argv[1], sys.argv[2]
    views = sys.argv[3:] or sorted(f[:-4] for f in os.listdir(src)
                                   if f.endswith(".png") and "_room_" not in f and not f.endswith("_x3.png"))
    rows = []
    for v in views:
        before = Image.open(os.path.join(src, v + ".png")).convert("RGB")
        after_p = os.path.join(src, v + "_room_on.png")
        off_p = os.path.join(src, v + "_room_off.png")
        if not os.path.exists(after_p):
            continue
        after = Image.open(after_p).convert("RGB")
        b, a = np.asarray(before), np.asarray(after)
        line = "%-26s mean L %.3f -> %.3f" % (v, lum(b).mean(), lum(a).mean())
        h = b.shape[0]
        lo = lum(b)[: h // 3].mean(), lum(a)[: h // 3].mean()
        bot = lum(b)[2 * h // 3:].mean(), lum(a)[2 * h // 3:].mean()
        dark_b = (lum(b) < 0.06).mean()
        dark_a = (lum(a) < 0.06).mean()
        line += "  top third %.3f -> %.3f  bottom third %.3f -> %.3f  near-black %.1f%% -> %.1f%%" % (
            lo[0], lo[1], bot[0], bot[1], dark_b * 100, dark_a * 100)
        if os.path.exists(off_p):
            o = np.asarray(Image.open(off_p).convert("RGB")).astype(np.int16)
            d = np.abs(o - b.astype(np.int16))
            line += "  | off again vs before: max %d, %.3f%% of pixels differ" % (d.max(), (d.max(axis=2) > 0).mean() * 100)
        print(line)
        pair = Image.new("RGB", (W * 2 + 8, int(W * h / b.shape[1]) + 22), (20, 20, 20))
        for i, (im, label) in enumerate([(before, "before (the game's light)"), (after, "after (RoomLight on)")]):
            small = im.resize((W, int(W * h / b.shape[1])), Image.LANCZOS)
            pair.paste(small, (i * (W + 8), 22))
            ImageDraw.Draw(pair).text((i * (W + 8) + 4, 4), "%s: %s" % (v, label), fill=(230, 230, 230))
        rows.append(pair)
    if not rows:
        sys.exit("no views with a _room_on variant in " + src)
    sheet = Image.new("RGB", (rows[0].width, sum(r.height for r in rows) + 6 * len(rows)), (0, 0, 0))
    y = 0
    for r in rows:
        sheet.paste(r, (0, y))
        y += r.height + 6
    sheet.save(out)
    print("sheet", out)


if __name__ == "__main__":
    main()
