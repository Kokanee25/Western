#!/usr/bin/env python3
"""A building's target sheet (the building lab's step 1, docs/briefs/building-pipeline.md): the image
model paints the building from every side, its plan, a cutaway and its rooms, one picture a view, and
the views are laid out on one sheet for Sean to approve. The sheet is the look to match, never a
drawing to build from (sizes come from the spec, step 2).

    # on GitHub Actions (building_sheet.yml; the key is a secret there, never here): the calls
    OPENROUTER_API_KEY=... python3 tools/buildings/target_sheet.py --paint
    # here, free: lay the views out on one sheet
    python3 tools/buildings/target_sheet.py --sheet=experiments/building_lab/doctor/sheet

--paint finds every experiments/building_lab/<building>/sheet/request.json without its
request.done.json and paints each view not yet painted into panels/<id>.jpg with the texture
factory's own call (tools/textures/paint_textures.ask, each call's cost reported). A request:

    {"cap": dollars, "model": "google/gemini-3-pro-image-preview",
     "building": "what the building is, said once and sent with every view",
     "look": "how every view is drawn",
     "views": [{"id", "title", "aspect": "16:9", "size": "2K", "refs": [earlier ids], "view": "..."}]}

A view's `refs` are earlier views sent with it as pictures ("the same building as the pictures
given"), so the outside, the plan and the rooms agree as well as the model can make them. A view
whose refs failed is skipped. The run stops before a call that could take it past the cap (the spend
so far plus NEXT_CALL). spent.json keeps every call across runs. To paint a view again, delete its
panel and request.done.json and push.
"""
import glob
import json
import os
import sys
import time

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "textures"))
# Nano Banana Pro's worst case at 2K with a few pictures in (~$0.14 a picture out, the inputs a cent).
NEXT_CALL = 0.25

ASK = ("{look}\n\nTHE BUILDING (the same in every view): {building}\n\nTHIS VIEW: {view}")
WITH_REFS = ("The pictures given show this same building from other views: keep it exactly the same "
             "building (its size, proportions, roof, siding, colours, sign, doors and windows "
             "in the same places, its rooms where the plan puts them). ")


def requests():
    out = []
    for path in sorted(glob.glob(os.path.join(ROOT, "experiments", "building_lab", "*", "sheet", "request.json"))):
        if not os.path.exists(path.replace(".json", ".done.json")):
            out.append(path)
    return out


def paint_one(path, key):
    import paint_textures as pt  # the texture factory's call (art's; used, not changed)
    pt.MODEL = json.load(open(path)).get("model", pt.MODEL)
    d = os.path.dirname(path)
    req = json.load(open(path))
    cap = float(req["cap"])
    spent_path = os.path.join(d, "spent.json")
    led = json.load(open(spent_path)) if os.path.exists(spent_path) else {"calls": []}
    spent = sum(c["cost"] for c in led["calls"])
    panels = os.path.join(d, "panels")
    os.makedirs(panels, exist_ok=True)
    for v in req["views"]:
        out = os.path.join(panels, v["id"] + ".jpg")
        if os.path.exists(out):
            continue
        refs = [os.path.join(panels, r + ".jpg") for r in v.get("refs", [])]
        if any(not os.path.exists(r) for r in refs):
            print("%s: skipped (a picture it needs failed)" % v["id"])
            continue
        if spent + NEXT_CALL > cap:
            print("stopping: $%.2f spent, the next call could pass the $%.2f cap" % (spent, cap))
            break
        prompt = ASK.format(look=req["look"], building=req["building"],
                            view=(WITH_REFS if refs else "") + v["view"])
        images = [Image.open(r).convert("RGB") for r in refs]
        config = {"aspect_ratio": v.get("aspect", "16:9"), "image_size": v.get("size", "2K")}
        before = pt.SPENT
        try:
            img = pt.ask(prompt, images, config, v["id"], key)
        except RuntimeError as e:
            print(e)
            led["calls"].append({"what": v["id"], "cost": round(pt.SPENT - before, 4), "ok": False, "at": time.time()})
            spent += pt.SPENT - before
            json.dump(led, open(spent_path, "w"), indent=1)
            continue
        cost = pt.SPENT - before
        spent += cost
        img.save(out, quality=94)
        led["calls"].append({"what": v["id"], "cost": round(cost, 4), "ok": True, "size": list(img.size),
                             "model": pt.MODEL, "at": time.time()})
        json.dump(led, open(spent_path, "w"), indent=1)
        print("%s: %dx%d, $%.4f (run so far $%.2f of $%.2f)" % (v["id"], img.width, img.height, cost, spent, cap),
              flush=True)
    led["total"] = round(spent, 4)
    json.dump(led, open(spent_path, "w"), indent=1)
    json.dump({"done": True, "spent": round(spent, 4), "cap": cap}, open(path.replace(".json", ".done.json"), "w"))
    print("%s: spent $%.2f of the $%.2f cap" % (os.path.relpath(d, ROOT), spent, cap))


def paint():
    key = os.environ.get("OPENROUTER_API_KEY")
    if not key:
        sys.exit("no OPENROUTER_API_KEY (this runs on GitHub Actions)")
    todo = requests()
    print("requests:", [os.path.relpath(p, ROOT) for p in todo])
    for path in todo:
        paint_one(path, key)


def font(size):
    for f in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            pass
    return ImageFont.load_default()


def sheet(d, cols=3, cell_w=900):
    """Every painted view, in the request's order, on one sheet with its title (sheet.jpg)."""
    req = json.load(open(os.path.join(d, "request.json")))
    cells = []
    for v in req["views"]:
        p = os.path.join(d, "panels", v["id"] + ".jpg")
        if os.path.exists(p):
            cells.append((v.get("title", v["id"]), Image.open(p).convert("RGB")))
    if not cells:
        sys.exit("no panels in " + d)
    title_h, pad = 44, 16
    scaled = [(t, im.resize((cell_w, round(im.height * cell_w / im.width)), Image.LANCZOS)) for t, im in cells]
    rows = [scaled[i:i + cols] for i in range(0, len(scaled), cols)]
    row_h = [max(im.height for _, im in r) + title_h for r in rows]
    head = 70
    W = cols * cell_w + (cols + 1) * pad
    H = head + sum(row_h) + (len(rows) + 1) * pad
    out = Image.new("RGB", (W, H), (236, 230, 218))
    dr = ImageDraw.Draw(out)
    dr.text((pad, 16), req.get("sheet_title", "Target sheet"), fill=(40, 30, 20), font=font(34))
    y = head + pad
    for r, h in zip(rows, row_h):
        x = pad
        for t, im in r:
            dr.text((x, y + 6), t, fill=(40, 30, 20), font=font(26))
            out.paste(im, (x, y + title_h))
            x += cell_w + pad
        y += h + pad
    path = os.path.join(d, "sheet.jpg")
    out.save(path, quality=90)
    small = out.resize((1600, round(H * 1600 / W)), Image.LANCZOS)
    small.save(os.path.join(d, "sheet_small.jpg"), quality=88)
    print("%s: %d views, %dx%d" % (os.path.relpath(path, ROOT), len(cells), W, H))


if __name__ == "__main__":
    args = dict(a.lstrip("-").split("=", 1) if "=" in a else (a.lstrip("-"), "") for a in sys.argv[1:])
    if "paint" in args:
        paint()
    elif "sheet" in args:
        sheet(os.path.join(ROOT, args["sheet"]) if not os.path.isabs(args["sheet"]) else args["sheet"])
    else:
        print(__doc__)
