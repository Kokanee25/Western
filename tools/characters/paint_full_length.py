#!/usr/bin/env python3
"""Characters by image-to-3D, step 1: have an image model paint a man full length, the way an
image-to-3D service wants him (DESIGN.md §4 "The plan from here" 1; docs/ART_REVIEW.md §6).

    FAL_KEY=... python3 tools/characters/paint_full_length.py [--only=stranger] [--repaint]
        [--via=fal|openrouter] [--scale=0.5] [--from=painting] [--seed=7]
    python3 tools/characters/paint_full_length.py --dry-run     (no key, no network)

Two routes. **fal** (the default when FAL_KEY is set and the style LoRA exists,
tools/style/style_lora.json): FLUX Kontext with our style LoRA (FAL_EDITOR, default
fal-ai/flux-kontext-lora) redraws the man from a picture of him: the full-length painting already
there (its mosaic smoothed away first) or, with --from=painting or for a new man, the concept
painting's man (characters.json `refs`). It's asked for him clean: smooth, real, flat-lit, no
square pixels (Tripo wants a clean picture; the squares are made last, by the paint bake or
finish), the LoRA at a low scale for the drawing's character, not its blocks. Then from that
front it paints his left side, back and right side the same way (Tripo's multi-view input,
tools/characters/tripo.py) and lays all four in a sheet to look at. **openrouter**: the first
route, FLUX.2 [max] with the painting's man as a reference (OPENROUTER_API_KEY).

Saves assets/people/tripo/<id>_full.png (front), <id>_left.png, <id>_back.png, <id>_right.png and
<id>_turn.png (the sheet), with every fal answer in build/characters/fal_log.json. Runs on GitHub
Actions (People workflow: `style: characters` paints only; the `characters` input paints then
runs Tripo). --dry-run runs the fal route against a stand-in (flat pictures, no network).
"""
import base64
import io
import json
import os
import sys
import time
import urllib.error
import urllib.request

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "textures"))
import paint_textures as pt  # noqa: E402  (the OpenRouter call, shared)

from PIL import Image, ImageDraw, ImageFilter  # noqa: E402

ROOT = pt.ROOT
SPEC = os.path.join(ROOT, "tools", "characters", "characters.json")
OUT = os.path.join(ROOT, "assets", "people", "tripo")
BUILD = os.path.join(ROOT, "build", "characters")
LORA = os.path.join(ROOT, "tools", "style", "style_lora.json")
EDITOR = os.environ.get("FAL_EDITOR") or "fal-ai/flux-kontext-lora"
QUEUE = "https://queue.fal.run/"
# The LoRA's share on the clean pictures: enough for the drawing's character (the period
# detail, the palette), not enough to paint its mosaic (at 1.0 it draws the blocks too; at 0.5,
# People run 20, the coat's front still came out in check blocks while the back was plain wool).
SCALE = 0.25
# The turnaround's other views, in Tripo's order after the front.
TURN = ("left", "back", "right")

ASK = (
    "A full-length character reference for a 3D model: {what}. He stands perfectly straight facing "
    "the viewer in an A-pose (arms held straight out and down at 45 degrees from his body, palms "
    "down, fingers together; feet a little apart), the whole of him in the frame from the top of "
    "his hat to the soles of his boots with a little space round him, seen straight on at his "
    "chest's height (no perspective). Soft, even, flat studio light from the front, no cast "
    "shadows, a plain light grey background. Realistic and sharp, every detail of his face, hat and "
    "clothes clear. He is the man in the reference image (a cropped pixel-art painting): his face, "
    "moustache, hair, hat and clothes, but painted clean and real, NOT in square pixels. Nothing "
    "in his hands, nothing else in the picture, no text."
)
# fal: Kontext edits the picture it's given. The front, from a picture of him.
ASK_FRONT = (
    "SLTCRK. Redraw this same man as a clean full-length character reference for a 3D model: "
    "{what}. {change} He stands "
    "perfectly straight facing the viewer in an A-pose (arms straight out and down at 45 degrees "
    "from his body, palms down, fingers together; feet a little apart), the whole of him in the "
    "frame from hat to boots with a little space round him, seen straight on at his chest's "
    "height. Soft, even, flat studio light from the front, no cast shadows, a plain light grey "
    "background. Smooth, realistic and sharp, every detail clear, with NO pixel mosaic, NO square "
    "pixels and NO blocky texture anywhere: smooth cloth, smooth skin. Nothing in his hands, "
    "nothing else in the picture, no text."
)
# What ASK_FRONT's {change} says unless the character's spec has its own (the body piece: hat and
# coat off).
KEEP = "Keep his face, hat, hair, moustache and clothes exactly as they are."
# A piece made from a character's finished front (characters.json `from` with `keep_pose`): the
# edit and nothing else. Asked to redraw him as a reference in an A-pose (ASK_FRONT), Kontext drew
# the Kid's arms in close to his sides (11 degrees where Sean's front has 40), Tripo fused his arms
# to his body where they touched, and they tore sheets of shirt off his sides when he raised them.
ASK_EDIT = (
    "SLTCRK. {change} Keep his pose exactly as it is, his arms held out from his body as they are, "
    "the whole of him in the frame as he is, the flat studio light and the plain light grey "
    "background. Smooth, realistic and sharp, with NO pixel mosaic, NO square pixels and NO blocky "
    "texture anywhere. Nothing in his hands, no text."
)
ASK_TURN = {
    "left": "SLTCRK. The same man, the same clothes, the same A-pose and the same flat studio light "
            "and plain light grey background, but seen from his left side (a true profile, he faces the "
            "left edge of the picture), the whole of him from {top} to boots. Smooth and realistic, NO "
            "pixel mosaic, NO square pixels. Nothing in his hands, no text.",
    "back": "SLTCRK. The same man, the same clothes, the same A-pose and the same flat studio light "
            "and plain light grey background, but seen from directly behind (his back to the viewer, "
            "{back_of}), the whole of him from {top} to boots. "
            "Smooth and realistic, NO pixel mosaic, NO square pixels. Nothing in his hands, no text.",
    "right": "SLTCRK. The same man, the same clothes, the same A-pose and the same flat studio light "
             "and plain light grey background, but seen from his right side (a true profile, he faces "
             "the right edge of the picture), the whole of him from {top} to boots. Smooth and realistic, "
             "NO pixel mosaic, NO square pixels. Nothing in his hands, no text.",
}
# A garment alone (characters.json `item`: the coat, the hat), the man removed, as a ghost-mannequin
# product picture: Tripo models it as the hollow garment, and fit_tripo.py hangs it on the body.
ASK_ITEM_FRONT = (
    "SLTCRK. From this picture of the man, show ONLY {item}, exactly as he wears it, as a ghost-mannequin "
    "product photograph: the man himself removed entirely (no head, no face, no hair, no hands, no "
    "legs, no body, none of his other clothes), the garment alone keeping exactly the shape it has on "
    "him, seen straight on from the front at its own middle height, the whole of it in the frame with "
    "a little space round it. {pose}Soft, even, flat studio light from the front, no cast shadows, a plain "
    "light grey background. Smooth, realistic and sharp, every detail clear, with NO pixel mosaic, NO "
    "square pixels and NO blocky texture anywhere. Nothing else in the picture, no text."
)
ASK_ITEM_TURN = {
    "left": "SLTCRK. The same {item} alone as a ghost-mannequin product photograph, the same flat studio "
            "light and plain light grey background, but seen from its left side (a true profile), the "
            "whole of it in the frame. {pose}Smooth and realistic, NO pixel mosaic, NO square pixels. Nothing "
            "else, no text.",
    "back": "SLTCRK. The same {item} alone as a ghost-mannequin product photograph, the same flat studio "
            "light and plain light grey background, but seen from directly behind, the whole of it in "
            "the frame. {pose}Smooth and realistic, NO pixel mosaic, NO square pixels. Nothing else, no text.",
    "right": "SLTCRK. The same {item} alone as a ghost-mannequin product photograph, the same flat studio "
             "light and plain light grey background, but seen from its right side (a true profile), the "
             "whole of it in the frame. {pose}Smooth and realistic, NO pixel mosaic, NO square pixels. Nothing "
             "else, no text.",
}


def asks(spec):
    """The front prompt and the three turn prompts for this character (a man, or an item)."""
    if spec.get("item"):
        # `pose`: how the garment is held (the coat's sleeves out at the A-pose's angle, so the
        # body's bones carry them right); nothing for a hat.
        words = {"item": spec["item"], "pose": (spec["pose"].strip() + " ") if spec.get("pose") else ""}
        return ASK_ITEM_FRONT.format(**words), {v: ASK_ITEM_TURN[v].format(**words) for v in TURN}
    words = {"top": "head", "back_of": "the back of his head and vest, his hair on his collar"} \
        if spec.get("hatless") else {"top": "hat", "back_of": "the back of his hat and coat, his hair on his collar"}
    if spec.get("back_of"):
        words["back_of"] = spec["back_of"]  # what his back shows, when it isn't a coat and long hair
    if spec.get("keep_pose") and spec.get("change"):
        front = ASK_EDIT.format(change=spec["change"])
    else:
        front = ASK_FRONT.format(what=spec["what"], change=spec.get("change", KEEP))
    return front, {v: ASK_TURN[v].format(**words) for v in TURN}


def request(method, url, key, body=None):
    headers = {"Authorization": "Key " + key}
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            text = r.read().decode(errors="replace")
            return json.loads(text) if text.strip() else {}
    except urllib.error.HTTPError as e:
        raise RuntimeError("%s %s: fal said %d: %s" % (method, url, e.code, e.read().decode(errors="replace")[:800])) from None


def fetch(url):
    with urllib.request.urlopen(url, timeout=600) as r:
        return r.read()


def data_url(img, longest=1024):
    """The picture as a data URL for fal's image_url, no bigger than Kontext works at."""
    img = img.convert("RGB")
    s = longest / max(img.size)
    if s < 1.0:
        img = img.resize((max(1, round(img.width * s)), max(1, round(img.height * s))), Image.LANCZOS)
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def smoothed(img, radius=4):
    """The mosaic taken out of a painting (its blocks are ~8 px): a median over them, so Kontext
    is shown a smooth man and doesn't copy the squares back."""
    img = img.convert("RGB")
    return img.filter(ImageFilter.MedianFilter(2 * radius + 1)).filter(ImageFilter.GaussianBlur(1.0))


def edit(img, prompt, lora_url, scale, seed, key, log, what):
    """One Kontext edit on fal's queue: the picture, the ask, the LoRA; the answer's picture."""
    body = {"image_url": data_url(img), "prompt": prompt, "num_inference_steps": 30, "guidance_scale": 2.5,
            "num_images": 1, "seed": seed, "output_format": "png", "enable_safety_checker": False,
            "resolution_mode": "match_input", "loras": [{"path": lora_url, "scale": scale}] if scale > 0 else []}
    queued = request("POST", QUEUE + EDITOR, key, body)
    log.append({what: {"queued": queued, "prompt": prompt, "scale": scale, "seed": seed}})
    status_url = queued.get("status_url") or "%s%s/requests/%s/status" % (QUEUE, EDITOR, queued["request_id"])
    response_url = queued.get("response_url") or "%s%s/requests/%s" % (QUEUE, EDITOR, queued["request_id"])
    for _ in range(120):
        st = request("GET", status_url, key)
        state = st.get("status")
        if state == "COMPLETED":
            answer = request("GET", response_url, key)
            log.append({what + "_answer": answer})
            images = answer.get("images") or []
            if not images:
                raise RuntimeError("no image in the answer: %s" % json.dumps(answer)[:600])
            return Image.open(io.BytesIO(fetch(images[0]["url"]))).convert("RGB")
        if state not in ("IN_QUEUE", "IN_PROGRESS"):
            log.append({what + "_status": st})
            raise RuntimeError("%s stopped: %s" % (what, json.dumps(st)[:800]))
        time.sleep(5)
    raise RuntimeError("%s: still not done after ten minutes" % what)


def turn_sheet(cid, out_dir, cell=512):
    """The four views side by side, labelled, to look at: <id>_turn.png."""
    tiles = []
    for view in ("full",) + TURN:
        p = os.path.join(out_dir, "%s_%s.png" % (cid, view))
        if not os.path.exists(p):
            continue
        im = Image.open(p).convert("RGB")
        s = cell / im.height
        im = im.resize((max(1, round(im.width * s)), cell), Image.LANCZOS)
        tile = Image.new("RGB", (im.width, cell + 18), (28, 28, 28))
        tile.paste(im, (0, 18))
        ImageDraw.Draw(tile).text((4, 3), "front" if view == "full" else view, fill=(255, 255, 255))
        tiles.append(tile)
    if not tiles:
        return
    sheet = Image.new("RGB", (sum(t.width for t in tiles) + 4 * (len(tiles) - 1), cell + 18), (28, 28, 28))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0))
        x += t.width + 4
    sheet.save(os.path.join(out_dir, cid + "_turn.png"))


def paint_fal(cid, spec, painting, key, lora_url, scale, seed, from_painting, out_dir, log, editor=edit):
    """The fal route for one man: the clean front, then the three other views from it."""
    full = os.path.join(out_dir, cid + "_full.png")
    parent = os.path.join(out_dir, spec["from"] + "_full.png") if spec.get("from") else ""
    if parent and os.path.exists(parent) and not from_painting:
        # A piece of another character (the body without hat and coat, the coat alone): redrawn
        # from that character's finished clean front, so it is the same man and the same clothes.
        source = Image.open(parent).convert("RGB")
        where = "%s's clean front" % spec["from"]
    elif os.path.exists(full) and not from_painting:
        source = smoothed(Image.open(full))
        where = "the full-length painting, smoothed"
    else:
        box = spec.get("refs", [[0, 0, painting.width, painting.height]])[0]
        source = smoothed(painting.crop(tuple(box)), 3)
        where = "the concept painting's man"
    ask_front, ask_turn = asks(spec)
    if spec.get("given") and os.path.exists(full) and not from_painting:
        # Sean's own front picture (clean, full length, in the A-pose): kept as it is, only the
        # other three views painted from it.
        front = Image.open(full).convert("RGB")
        log.append({"source": "the given front, kept"})
        print("kept:", cid, "front", front.size, "(given)")
    else:
        log.append({"source": where})
        front = editor(source, ask_front, lora_url, scale, seed, key, log, cid + "_front")
        front.save(full)
        print("painted:", cid, "front", front.size, "from", where)
    for i, view in enumerate(TURN):
        img = editor(front, ask_turn[view], lora_url, scale, seed + 1 + i, key, log, "%s_%s" % (cid, view))
        img.save(os.path.join(out_dir, "%s_%s.png" % (cid, view)))
        print("painted:", cid, view, img.size)
    turn_sheet(cid, out_dir)


def paint_openrouter(cid, spec, painting, key, out):
    refs = [painting.crop(tuple(b)) for b in spec.get("refs", [])]
    for attempt in range(3):
        try:
            img = pt.ask(ASK.format(what=spec["what"]), refs, {"aspect_ratio": "3:4"}, cid, key)
            img.save(out)
            print("painted:", cid, img.size)
            return True
        except (RuntimeError, OSError, KeyError, ValueError) as e:
            print("failed (try %d):" % (attempt + 1), e)
    return False


def dry_run():
    """The fal route with a stand-in editor (flat pictures, no network) into a scratch folder."""
    import tempfile
    scratch = tempfile.mkdtemp(prefix="characters_dry_")
    people = json.load(open(SPEC))["characters"]
    painting = Image.new("RGB", (1672, 941), (90, 70, 50))

    def standin(img, prompt, lora_url, scale, seed, key, log, what):
        log.append({what: {"prompt": prompt, "scale": scale, "seed": seed, "input": img.size}})
        if "SLTCRK" not in prompt or "NO pixel mosaic" not in prompt:
            raise RuntimeError("the ask lost its trigger word or its no-mosaic rule: " + what)
        return Image.new("RGB", (768, 1024), (120 + 20 * seed % 60, 110, 100))

    log = []
    for cid, spec in people.items():
        paint_fal(cid, spec, painting, "dry-run-key", "lora.safetensors", SCALE, 7, True, scratch, log, standin)
        for view in ("full",) + TURN + ("turn",):
            p = os.path.join(scratch, "%s_%s.png" % (cid, view))
            if not os.path.exists(p):
                print("dry run FAILED: no", p)
                sys.exit(1)
    print("dry run passed: %s (%d edits)" % (scratch, sum(1 for e in log if any(k.endswith(("_front", "_left", "_back", "_right")) for k in e))))


def main():
    if "--dry-run" in sys.argv:
        dry_run()
        return
    only, via, scale, seed, from_painting = None, "", SCALE, 7, False
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1]:
            only = a.split("=", 1)[1].split(",")
        elif a.startswith("--via="):
            via = a.split("=", 1)[1]
        elif a.startswith("--scale="):
            scale = float(a.split("=", 1)[1])
        elif a.startswith("--seed="):
            seed = int(a.split("=", 1)[1])
        elif a == "--from=painting":
            from_painting = True
    repaint = "--repaint" in sys.argv
    fal_key = os.environ.get("FAL_KEY", "")
    or_key = os.environ.get("OPENROUTER_API_KEY", "")
    if not via:
        via = "fal" if fal_key and os.path.exists(LORA) else "openrouter"
    if via == "fal" and not fal_key:
        print("No FAL_KEY: nobody painted.")
        return
    if via == "openrouter" and not or_key:
        print("No OPENROUTER_API_KEY: nobody painted.")
        return
    lora_url = json.load(open(LORA))["lora_url"] if via == "fal" and os.path.exists(LORA) else ""
    if via == "fal" and not lora_url:
        print("No %s: the LoRA isn't trained (train_style.py); painting without it." % LORA)
        scale = 0.0
    people = json.load(open(SPEC))["characters"]
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(BUILD, exist_ok=True)
    painting = Image.open(os.path.join(ROOT, "docs", "concept", "saloon-night.png")).convert("RGB")
    log = [{"via": via, "editor": EDITOR, "lora_url": lora_url, "scale": scale, "seed": seed}]
    failed = []
    for cid, spec in people.items():
        if only and cid not in only:
            continue
        out = os.path.join(OUT, cid + "_full.png")
        done = os.path.exists(out) and (via == "openrouter" or all(
            os.path.exists(os.path.join(OUT, "%s_%s.png" % (cid, v))) for v in TURN))
        if done and not repaint:
            print("already painted:", cid)
            continue
        try:
            if via == "fal":
                paint_fal(cid, spec, painting, fal_key, lora_url, scale, seed, from_painting, OUT, log)
            elif not paint_openrouter(cid, spec, painting, or_key, out):
                failed.append(cid)
        except (RuntimeError, OSError, KeyError, ValueError) as e:
            print("failed:", cid, e)
            failed.append(cid)
        with open(os.path.join(BUILD, "fal_log.json"), "w") as f:
            json.dump(log, f, indent=1)
    if failed:
        print("not painted:", ", ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    main()
