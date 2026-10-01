#!/usr/bin/env python3
"""Have an image model paint a man's grey views as the concept painting's man (DESIGN.md §4).

    OPENROUTER_API_KEY=... python3 tools/paint/paint_views.py [--only=outlaw] [--views=shot,front,...|none]
        [--sheet] [--head-sheet] [--repaint]

For each view tools/paint_bake.gd rendered (assets/people/paint/<id>_<view>_guide.png: him in plain
grey clay, square), sends the guide (his shape: keep every edge), the painting's man and a close-up
of his face (cut from docs/concept/saloon-night.png: who he is, his clothes and colours), and, once
his front is painted, that too (so every side of him is the same man), and asks for the guide
painted as that man: clean and detailed, in even light, not pixelated. The pixels are made
afterwards, the same way for every man and prop (tools/paint/finish.py): a model that pixelates
each picture its own way gives grids that don't meet once they're wrapped round him. Saves
assets/people/paint/<id>_<view>_painted.png at the guide's size; tools/paint/align.py fits it onto
the guide and tools/paint_bake.gd projects it onto him. Skips views already painted unless --repaint.

--sheet also paints all six views in one picture (a turnaround: views painted together agree with
each other): <id>_sheet_guide.png, <id>_sheet_painted.png, and each view cut back out as
<id>_<view>_tile.png (align.py --source=tile uses those instead). --head-sheet does the same for
six close views of his head (HEAD_SHEET), with his painted front as the reference for who he is,
so his face gets about three times the detail. --views=none paints no single views.

The key comes from the environment (a GitHub Actions secret, never the repo). The model is
OpenRouter's PAINT_MODEL (default FLUX.2 [max]: up to 8 reference images, the same style kit on
every call); any OpenRouter image model that takes images in.
"""
import base64
import io
import json
import os
import sys
import urllib.error
import urllib.request

from PIL import Image

API = "https://openrouter.ai/api/v1/chat/completions"
# An unset repository variable arrives as an empty string, not a missing one.
MODEL = os.environ.get("PAINT_MODEL") or "black-forest-labs/flux.2-max"
DIR = "assets/people/paint"
PAINTING = "docs/concept/saloon-night.png"
# The painting's man, in its pixels (x0, y0, x1, y1): hat to the bottom edge, his arm to the cup.
MAN_BOX = (40, 120, 960, 941)
# His face and hat, close.
FACE_BOX = (430, 180, 850, 560)

VIEWS = {
    "shot": "from where you sit across the table from him (the painting's own view)",
    "front": "from straight in front of him",
    "three_quarter": "from in front of him and 40 degrees round to his right",
    "side": "from his right side",
    "side_left": "from his left side",
    "back": "from behind him",
}
# The turnaround sheet: three across, two down.
SHEET = ["front", "three_quarter", "side", "side_left", "back", "shot"]
# The head sheet: his head close, the same layout (the face gets ~3x the pixels it gets on SHEET).
HEAD_SHEET = ["head_front", "head_three_quarter", "head_side", "head_side_left", "head_back", "head_shot"]
TILE = 640

WHO = (
    "He is the man in the painting (image 2, and his face close up in image 3): a broad, heavy-set "
    "weathered frontier man with a thick dark moustache and short stubble (no beard or goatee), dark "
    "hair to the collar, a dark brown hat with a studded band, a heavy dark-brown wool coat, a "
    "patterned vest, a white collar and cuffs, a dark tie hanging down into the vest. "
)
FINISH = (
    "Paint him clean and detailed, as a hand-painted illustration in the painting's warm, muted browns: "
    "clear shapes, crisp strong dark marks for his eyes, brows and moustache. Light him evenly and "
    "softly from the front: no cast shadows, no lamp glow, no rim light (the game lights him). Do not "
    "pixelate it or add square blocks: that is done afterwards. Everything that isn't him is plain flat "
    "light grey. "
)
KEEP = (
    "Keep image 1's shapes exactly: every edge of him, his hat, arms, hands, legs and anything he holds "
    "exactly where they are in image 1, the same size and the same pose; nothing added outside his "
    "outline and nothing moved. "
)
ASK_VIEW = (
    "Image 1 is a plain grey 3D model of a seated man, seen {view}. Paint image 1 as that man. " + WHO
    + "{same}Parts of him the painting doesn't show (his back, his sides, his legs and boots) are "
    "painted as they would be on that man, in the same clothes. " + KEEP + FINISH
    + "Square picture, framed exactly as image 1."
)
SAME = "Image 4 is this same man already painted from the front: match him exactly (face, clothes, colours). "
ASK_SHEET = (
    "Image 1 is a sheet of six grey views of the same seated 3D man: top row from the front, from 40 "
    "degrees round to his right, from his right side; bottom row from his left side, from behind, and "
    "from where you sit across a card table from him. Paint every view on the sheet as that same man, "
    "identical in every view. " + WHO + KEEP.replace("image 1", "each view of image 1") + FINISH
    + "Keep the sheet's layout exactly: six views, three across and two down, each where it is in image 1."
)


ASK_HEAD_SHEET = (
    "Image 1 is a sheet of six close grey views of the same seated 3D man's head and shoulders: top row "
    "from the front, from 40 degrees round to his right, from his right side; bottom row from his left "
    "side, from behind, and from where you sit across a card table from him. Paint every view on the "
    "sheet as that same man, identical in every view. He is the man in image 4 (already painted: match "
    "his hat and clothes exactly) and the man in the painting (image 2, his face close up in image 3), "
    "whose face he has. His face as the painting has it: a weathered, lined face, deep-set dark eyes "
    "each with a small white glint, heavy dark brows, a thick dark drooping moustache, short dark "
    "stubble on his cheeks and chin and NO beard or goatee (image 4 wrongly has one: leave it out); "
    "dark brown hair falling long behind his ears to his collar; a dark brown hat with a studded band; "
    "a white shirt collar and a dark tie at his throat; the heavy brown coat on his shoulders. His "
    "eyes are open, the whites showing; in the front view and the view from across the table he looks "
    "straight at you, as he does in the painting. Draw the eyes, brows and moustache as crisp, strong, "
    "dark shapes. In each cell turn his head exactly as the grey head in that cell is turned: the "
    "top-right cell is his right profile and the bottom-left his left profile, facing opposite ways. "
    + KEEP.replace("image 1", "each view of image 1") + FINISH
    + "Keep the sheet's layout exactly: six views, three across and two down, each where it is in image 1."
)


def data_url(img):
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def references():
    p = Image.open(PAINTING).convert("RGB")
    return [p.crop(MAN_BOX), p.crop(FACE_BOX)]


def ask(prompt, images, config, what, key):
    """One request; returns the image it painted."""
    body = {
        "model": MODEL,
        # Image-only models (FLUX) refuse to be asked for text as well.
        "modalities": ["image", "text"] if "gemini" in MODEL or "gpt" in MODEL else ["image"],
        "messages": [{
            "role": "user",
            "content": [{"type": "text", "text": prompt}]
            + [{"type": "image_url", "image_url": {"url": data_url(im)}} for im in images],
        }],
        "image_config": config,
    }
    for attempt in (0, 1):
        req = urllib.request.Request(API, data=json.dumps(body).encode(), headers={
            "Authorization": "Bearer " + key,
            "Content-Type": "application/json",
            "X-Title": "Salt Creek people pipeline",
        })
        try:
            with urllib.request.urlopen(req, timeout=600) as r:
                answer = json.load(r)
            break
        except urllib.error.HTTPError as e:
            # OpenRouter says why in the body; show it (it never contains the key).
            said = e.read().decode(errors="replace")[:1000]
            if attempt == 0 and e.code == 400 and "image_config" in body:
                print("%s: OpenRouter said %d (%s); again without image_config" % (what, e.code, said[:200]))
                del body["image_config"]
                continue
            raise RuntimeError("%s: OpenRouter said %d: %s" % (what, e.code, said)) from None
    message = answer["choices"][0]["message"]
    images = message.get("images") or []
    if not images:
        raise RuntimeError("%s: no image in the answer: %s" % (what, str(message.get("content"))[:300]))
    url = images[0]["image_url"]["url"]
    return Image.open(io.BytesIO(base64.b64decode(url.split(",", 1)[1]))).convert("RGB")


def fit_to(img, size, what):
    # Back to the guide's frame (the bake lays it over the guide's view). A model that answers in
    # another shape has reframed him; say so.
    if abs(img.width / img.height - size[0] / size[1]) > 0.02:
        print("warning: %s came back %dx%d for %dx%d" % (what, img.width, img.height, size[0], size[1]))
    return img.resize(size, Image.LANCZOS)


def paint_view(pid, view, refs, front, key):
    guide = Image.open(os.path.join(DIR, "%s_%s_guide.png" % (pid, view))).convert("RGB")
    images = [guide] + refs + ([front] if front is not None else [])
    prompt = ASK_VIEW.format(view=VIEWS[view], same=SAME if front is not None else "")
    img = ask(prompt, images, {"aspect_ratio": "1:1", "image_size": "1K"}, "%s %s" % (pid, view), key)
    got = img.size
    img = fit_to(img, guide.size, "%s %s" % (pid, view))
    out = os.path.join(DIR, "%s_%s_painted.png" % (pid, view))
    img.save(out)
    print("painted", out, "(%dx%d from the model) by" % got, MODEL)
    return img


def sheet_guide(pid, views=SHEET):
    sheet = Image.new("RGB", (TILE * 3, TILE * 2), (219, 219, 219))
    for i, view in enumerate(views):
        g = Image.open(os.path.join(DIR, "%s_%s_guide.png" % (pid, view))).convert("RGB").resize((TILE, TILE), Image.LANCZOS)
        sheet.paste(g, ((i % 3) * TILE, (i // 3) * TILE))
    return sheet


def paint_sheet(pid, refs, key, views=SHEET, prompt=ASK_SHEET, name="sheet"):
    guide = sheet_guide(pid, views)
    guide.save(os.path.join(DIR, "%s_%s_guide.png" % (pid, name)))
    img = ask(prompt, [guide] + refs, {"aspect_ratio": "3:2", "image_size": "2K"}, "%s %s" % (pid, name), key)
    got = img.size
    img = fit_to(img, guide.size, "%s %s" % (pid, name))
    img.save(os.path.join(DIR, "%s_%s_painted.png" % (pid, name)))
    for i, view in enumerate(views):
        size = Image.open(os.path.join(DIR, "%s_%s_guide.png" % (pid, view))).size
        tile = img.crop(((i % 3) * TILE, (i // 3) * TILE, (i % 3 + 1) * TILE, (i // 3 + 1) * TILE))
        tile.resize(size, Image.LANCZOS).save(os.path.join(DIR, "%s_%s_tile.png" % (pid, view)))
    print("painted the %s for" % name, pid, "(%dx%d from the model) by" % got, MODEL)


def paint_head_sheet(pid, refs, key):
    # The man already painted from the front (the body sheet's view, else the single view) keeps the
    # close head the same man.
    for f in ("%s_front_tile.png", "%s_front_painted.png"):
        path = os.path.join(DIR, f % pid)
        if os.path.exists(path):
            front = Image.open(path).convert("RGB")
            break
    else:
        raise RuntimeError("%s head sheet: paint his front first (the body sheet)" % pid)
    paint_sheet(pid, refs + [front], key, HEAD_SHEET, ASK_HEAD_SHEET, "head_sheet")


def main():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    if not key:
        print("No OPENROUTER_API_KEY: views not painted.")
        return
    only = None
    views = list(VIEWS)
    repaint = "--repaint" in sys.argv
    sheet = "--sheet" in sys.argv
    head_sheet = "--head-sheet" in sys.argv
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1]:
            only = a.split("=", 1)[1]
        elif a.startswith("--views=") and a.split("=", 1)[1] == "none":
            views = []
        elif a.startswith("--views=") and a.split("=", 1)[1] not in ("", "all"):
            views = a.split("=", 1)[1].split(",")
    # His front first: it's the reference that keeps his other sides the same man.
    views.sort(key=lambda v: v != "front")
    refs = references()
    people = json.load(open("assets/people/people.json"))["people"]
    failed = []
    painted = 0
    for pid in people:
        if only and pid != only:
            continue
        front = None
        front_path = os.path.join(DIR, "%s_front_painted.png" % pid)
        for view in views:
            if not os.path.exists(os.path.join(DIR, "%s_%s_guide.png" % (pid, view))):
                continue
            out = os.path.join(DIR, "%s_%s_painted.png" % (pid, view))
            if os.path.exists(out) and not repaint:
                print("already painted:", pid, view)
            else:
                try:
                    img = paint_view(pid, view, refs, front if view != "front" else None, key)
                    painted += 1
                except (RuntimeError, OSError, KeyError, ValueError) as e:
                    # One view failing shouldn't lose the others.
                    print("failed:", e)
                    failed.append("%s %s" % (pid, view))
            if view == "front" and os.path.exists(front_path):
                front = Image.open(front_path).convert("RGB")
        if sheet:
            try:
                paint_sheet(pid, refs, key)
                painted += 1
            except (RuntimeError, OSError, KeyError, ValueError) as e:
                print("failed:", e)
                failed.append("%s sheet" % pid)
        if head_sheet:
            try:
                paint_head_sheet(pid, refs, key)
                painted += 1
            except (RuntimeError, OSError, KeyError, ValueError) as e:
                print("failed:", e)
                failed.append("%s head sheet" % pid)
    if failed:
        print("not painted:", ", ".join(failed))
        # Keep what did come back (it's committed); fail only if nothing did.
        if painted == 0:
            sys.exit(1)


if __name__ == "__main__":
    main()
