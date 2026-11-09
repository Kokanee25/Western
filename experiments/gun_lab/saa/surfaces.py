#!/usr/bin/env python3
"""The SAA's surfaces (#693 step 1; Sean's yes on #740, 2026-11-09: "paint it with 2.50 cap", the grip
frame blued): the image model paints only flat, tiling surfaces, never the gun's shape. Three
materials: the frame's colour case-hardening, worn bluing, oiled walnut. The wear and grime are the
gun's own (saa_blender.py's bake, free).

    # on GitHub Actions (gun_surfaces.yml; the key is a secret there, never here): the calls
    OPENROUTER_API_KEY=... python3 experiments/gun_lab/saa/surfaces.py --paint
    # here, free: each painting made seamless and cut to its maps
    python3 experiments/gun_lab/saa/surfaces.py --cut

--paint reads surfaces/request.json ({"cap": dollars, "items": [{"id", "tries", "what"}]}), paints each
try not yet painted into surfaces/raw/<id>_<k>.jpg with the texture factory's own call
(tools/textures/paint_textures.ask: FLUX.2 [max] on OpenRouter, each call's cost reported), and stops
before a call that could take the run past the cap (the spend so far plus NEXT_CALL, a call's worst
case). surfaces/spent.json keeps every call and its cost across runs; request.done.json marks it run.
--cut makes each painting seamless (tools/textures/reduce.seamless: blended with a copy rolled half a
turn behind a wavy edge) at SIZE and writes surfaces/<id>_<k>.png beside a 2x2 tiling check.
"""
import glob
import json
import os
import sys
import time

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "textures"))
DIR = os.path.join(HERE, "surfaces")
RAW = os.path.join(DIR, "raw")
REQUEST = os.path.join(DIR, "request.json")
SPENT = os.path.join(DIR, "spent.json")
# A FLUX.2 [max] call's worst case, held back before each call (runs 87-88: ~$0.22 a call).
NEXT_CALL = 0.35
SIZE = 1024

FLAT = ("A seamless, tileable texture: {what}. Seen perfectly straight on (orthographic, no perspective), "
        "filling the whole frame edge to edge with the surface and nothing else. Soft, even, flat light with "
        "no cast shadows, no reflections and no highlights, so it can be lit again in a game. Photographic, "
        "realistic and sharp, with rich fine detail and many close shades of colour. No text, no lettering, "
        "no stamps or markings, no screws, no edges, no objects, no border, no vignette.")


def ledger():
    return json.load(open(SPENT)) if os.path.exists(SPENT) else {"calls": []}


def paint():
    import paint_textures as pt  # the texture factory's call (art's; used, not changed)
    key = os.environ.get("OPENROUTER_API_KEY")
    if not key:
        sys.exit("no OPENROUTER_API_KEY (this runs on GitHub Actions)")
    req = json.load(open(REQUEST))
    cap = float(req["cap"])
    led = ledger()
    spent = sum(c["cost"] for c in led["calls"])
    os.makedirs(RAW, exist_ok=True)
    for item in req["items"]:
        for k in range(int(item["tries"])):
            out = os.path.join(RAW, "%s_%d.jpg" % (item["id"], k))
            if os.path.exists(out):
                continue
            if spent + NEXT_CALL > cap:
                print("stopping: $%.2f spent, the next call could pass the $%.2f cap" % (spent, cap))
                break
            before = pt.SPENT
            what = "%s %d" % (item["id"], k)
            try:
                img = pt.ask(FLAT.format(what=item["what"]), [], {"aspect_ratio": "1:1"}, what, key)
            except RuntimeError as e:
                print(e)
                led["calls"].append({"what": what, "cost": pt.SPENT - before, "ok": False, "at": time.time()})
                spent += pt.SPENT - before
                continue
            cost = pt.SPENT - before
            spent += cost
            img.save(out, quality=95)
            led["calls"].append({"what": what, "cost": round(cost, 4), "ok": True, "size": list(img.size), "at": time.time()})
            json.dump(led, open(SPENT, "w"), indent=1)
            print("%s: %dx%d, $%.4f (run so far $%.2f of $%.2f)" % (what, img.width, img.height, cost, spent, cap), flush=True)
    led["total"] = round(spent, 4)
    json.dump(led, open(SPENT, "w"), indent=1)
    json.dump({"done": True, "spent": round(spent, 4), "cap": cap}, open(REQUEST.replace(".json", ".done.json"), "w"))
    print("spent $%.2f of the $%.2f cap" % (spent, cap))


def cut():
    import reduce as rd  # the texture factory's seamless blend (art's; used, not changed)
    for path in sorted(glob.glob(os.path.join(RAW, "*.jpg"))):
        name = os.path.splitext(os.path.basename(path))[0]
        img = Image.open(path).convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)
        a = np.asarray(img).astype(np.float32) / 255.0
        a = rd.seamless(a, np.random.default_rng(sum(map(ord, name))))
        out = Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8))
        out.save(os.path.join(DIR, name + ".png"))
        check = Image.new("RGB", (SIZE, SIZE))
        half = out.resize((SIZE // 2, SIZE // 2), Image.LANCZOS)
        for x in (0, SIZE // 2):
            for y in (0, SIZE // 2):
                check.paste(half, (x, y))
        os.makedirs(os.path.join(DIR, "check"), exist_ok=True)
        check.save(os.path.join(DIR, "check", name + "_2x2.jpg"), quality=85)
        print("cut", name)


if __name__ == "__main__":
    if "--paint" in sys.argv:
        paint()
    elif "--cut" in sys.argv:
        cut()
    else:
        print(__doc__)
