"""The controlled comparison (the fidelity investigation, task 5): a portrait and the game's
renders of the same man, each face found by its landmarks, cropped alike and measured alike
(style_probe.measure: patch size, tones, detail, lightness, chroma, highlights), with each
measure's distance from the portrait's; one sheet and the numbers.

    ~/bpyenv/bin/python tools/characters/fidelity_compare.py --out=PNG --ref="Portrait=PATH" \\
        "Title=PATH" ...  [--json=OUT]

Titles may hold spaces (quote each argument); PATH@x0,y0,x1,y1 measures that part of the frame
(MediaPipe finds a small face in a crop, not in the whole frame). A panel whose face isn't found is drawn uncropped
and left out of the numbers.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import portrait as P  # noqa: E402
import style_probe as S  # noqa: E402

KEYS = ["patch_pct", "tones", "detail_rms", "L_mean", "L_sd", "chroma", "highlights_pct"]
TILE = 360


def one(title, path, is_ref=False):
    src = Image.open(path.split("@")[0]).convert("RGB")
    if "@" in path:      # PATH@x0,y0,x1,y1: that part of the frame (small faces are found in a crop)
        src = src.crop(tuple(int(v) for v in path.split("@")[1].split(",")))
    img = np.asarray(src).astype(float) / 255
    h, w = img.shape[:2]
    lm = P.landmarks(src) if is_ref else S.game_landmarks(img)
    if lm is None:
        return {"title": title, "img": img, "box": (0, 0, w, h), "m": None}
    scale = float(np.linalg.norm(lm[168, :2] - lm[152, :2]))
    mask = S.face_mask(lm, w, h)
    m = S.measure(img, mask, scale, scale / 25)
    return {"title": title, "img": img, "box": S.crop_box(lm, w, h), "m": m, "face_px": round(scale, 1)}


def main():
    args = [a for a in sys.argv[1:]]
    opts = dict(a.split("=", 1) for a in args if a.startswith("--"))
    panels = [a for a in args if not a.startswith("--")]
    rt, rp = opts["--ref"].split("=", 1)
    rows = [one(rt, rp, True)] + [one(*p.split("=", 1)) for p in panels]
    P.close_landmarker()
    ref = rows[0]["m"]
    tiles = []
    for r in rows:
        im = Image.fromarray((np.clip(r["img"], 0, 1) * 255).astype(np.uint8)).crop(r["box"])
        im = im.resize((TILE, int(TILE * im.height / max(im.width, 1))), Image.NEAREST)
        canvas = Image.new("RGB", (TILE, TILE + 118), (18, 16, 14))
        canvas.paste(im.crop((0, 0, TILE, min(TILE, im.height))), (0, 0))
        d = ImageDraw.Draw(canvas)
        d.text((6, TILE + 4), r["title"], fill=(240, 230, 200))
        if r["m"] is None:
            d.text((6, TILE + 20), "face not found", fill=(240, 120, 100))
        else:
            for i, k in enumerate(KEYS):
                v = r["m"][k]
                dv = "" if r is rows[0] or ref is None else "  (%+.1f)" % (v - ref[k])
                d.text((6 + (i % 2) * 180, TILE + 20 + (i // 2) * 16), "%s %s%s" % (k, v, dv), fill=(210, 200, 180))
            d.text((6, TILE + 20 + 4 * 16), "face (eye line to chin) %s px" % r.get("face_px"), fill=(160, 150, 130))
        tiles.append(canvas)
    cols = min(4, len(tiles))
    rows_n = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (TILE + 6), rows_n * (TILE + 124)), (8, 8, 8))
    for i, t in enumerate(tiles):
        sheet.paste(t, ((i % cols) * (TILE + 6), (i // cols) * (TILE + 124)))
    sheet.save(opts["--out"])
    out = [{"title": r["title"], "measures": r["m"], "face_px": r.get("face_px")} for r in rows]
    if "--json" in opts:
        json.dump(out, open(opts["--json"], "w"), indent=1)
    for r in out:
        print("%-34s" % r["title"], r["measures"])


if __name__ == "__main__":
    main()
