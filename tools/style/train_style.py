#!/usr/bin/env python3
"""Train the image model on our style: a style LoRA on fal, from crops of the concept paintings
(docs/concept/*.png) and whatever Sean adds to docs/concept/style/ (pictures in the look we want:
keep anything that isn't ours out of the repo's history if it's public, or ask first).

    FAL_KEY=... python3 tools/style/train_style.py [--dry-run] [--steps=1000] [--trigger=SLTCRK]

1. Crops: every concept painting cut into overlapping squares (CROP of its height, three rows of
   crops across, so the man, the bar, the door, the street and the rocks each get some whole), and
   every picture in docs/concept/style/ as its middle square plus, if it's wide, its two ends.
   Each crop is cut to TRAIN_SIZE and gets a caption (the trigger word, then what it shows: its
   painting's `about` below, or docs/concept/style/captions.json {file: words}, else plain words).
2. Zipped (pictures + captions as same-name .txt) into build/style_train/train.zip.
3. Uploaded to fal's storage, then fal's LoRA trainer (FAL_TRAINER, default
   fal-ai/flux-lora-fast-training with is_style) is queued with it and waited on.
4. The result (the LoRA file's URL and its config, every answer fal gave) is written to
   tools/style/style_lora.json: the weights stay on fal; painters can use it from there.

--dry-run does 1 and 2 only (no key, no network) and prints what it would send: run it here to
check the crops (build/style_train/sheet.png shows them all).

UNTESTED against the live API (no key yet): written to fal's queue API (POST
https://queue.fal.run/<app>, then its status_url and response_url) and its storage upload
(rest.alpha.fal.ai/storage/upload/initiate, then a PUT). Every answer is printed and saved, so the
first run on Actions shows what to change. The key comes from the environment (the repo secret
FAL_KEY on Actions), never the repo. Runs on GitHub Actions: People workflow, input `style: train`.
"""
import io
import json
import os
import sys
import time
import urllib.error
import urllib.request
import zipfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONCEPT = os.path.join(ROOT, "docs", "concept")
STYLE = os.path.join(CONCEPT, "style")
BUILD = os.path.join(ROOT, "build", "style_train")
OUT = os.path.join(ROOT, "tools", "style", "style_lora.json")
TRAINER = os.environ.get("FAL_TRAINER") or "fal-ai/flux-lora-fast-training"
QUEUE = "https://queue.fal.run/"
STORAGE = "https://rest.alpha.fal.ai/storage/upload/initiate"
# Crops: this share of a painting's height a side, three rows of them, as many across as it
# takes to overlap by about a third.
CROP = 0.5
ROWS = 3
TRAIN_SIZE = 1024
PICTURES = (".png", ".jpg", ".jpeg", ".webp")
# What each concept painting shows (the words after the trigger in its crops' captions).
ABOUT = {
    "saloon-night": "pixel-art painting of an 1880s frontier saloon at night, lamplit, warm browns and "
                    "orange, a weathered gunman at a card table, chunky square pixels on every surface",
    "street-golden-hour": "pixel-art painting of an 1880s western main street at golden hour, false-front "
                          "timber buildings, red-rock spires beyond, chunky square pixels on every surface",
    "livery-fire": "pixel-art painting of a burning livery stable in an 1880s western town at night, "
                   "flames and smoke, chunky square pixels on every surface",
}
PLAIN = "pixel-art painting, chunky square pixels on every surface, clean shapes, warm painterly light"


def crops_of(img, rows):
    """Squares of CROP x height, `rows` rows of them down and enough across to overlap."""
    w, h = img.size
    side = int(round(h * CROP))
    out = []
    ys = [round(i * (h - side) / max(rows - 1, 1)) for i in range(rows)]
    across = max(1, int(round((w - side) / (side * 0.66))) + 1)
    xs = [round(i * (w - side) / max(across - 1, 1)) for i in range(across)]
    for y in ys:
        for x in xs:
            out.append(img.crop((x, y, x + side, y + side)))
    return out


def style_crops(img):
    """A picture of Sean's: its middle square, and its two ends if it's wide (or tall)."""
    w, h = img.size
    side = min(w, h)
    if abs(w - h) < side * 0.25:
        return [img.crop(((w - side) // 2, (h - side) // 2, (w - side) // 2 + side, (h - side) // 2 + side))]
    if w > h:
        return [img.crop((x, 0, x + side, side)) for x in (0, (w - side) // 2, w - side)]
    return [img.crop((0, y, side, y + side)) for y in (0, (h - side) // 2, h - side)]


def gather(trigger):
    """[(name, image, caption)] for every crop."""
    items = []
    for name in sorted(os.listdir(CONCEPT)):
        if not name.lower().endswith(PICTURES):
            continue
        stem = os.path.splitext(name)[0]
        img = Image.open(os.path.join(CONCEPT, name)).convert("RGB")
        for i, c in enumerate(crops_of(img, ROWS)):
            items.append(("%s_%02d" % (stem, i), c, "%s, %s" % (trigger, ABOUT.get(stem, PLAIN))))
    captions = {}
    cap_path = os.path.join(STYLE, "captions.json")
    if os.path.exists(cap_path):
        captions = json.load(open(cap_path))
    if os.path.isdir(STYLE):
        for name in sorted(os.listdir(STYLE)):
            if not name.lower().endswith(PICTURES):
                continue
            stem = os.path.splitext(name)[0]
            img = Image.open(os.path.join(STYLE, name)).convert("RGB")
            for i, c in enumerate(style_crops(img)):
                items.append(("style_%s_%d" % (stem, i), c, "%s, %s" % (trigger, captions.get(name, PLAIN))))
    # Every crop the training size; the pixel art kept crisp when it's enlarged (nearest), smoothed
    # when it's shrunk.
    out = []
    for name, c, cap in items:
        resample = Image.NEAREST if c.width < TRAIN_SIZE else Image.LANCZOS
        out.append((name, c.resize((TRAIN_SIZE, TRAIN_SIZE), resample), cap))
    return out


def make_zip(items, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        for name, img, cap in items:
            buf = io.BytesIO()
            img.save(buf, "PNG")
            z.writestr(name + ".png", buf.getvalue())
            z.writestr(name + ".txt", cap)
    return path


def contact_sheet(items, path, cell=160):
    cols = 8
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell, rows * cell), (20, 16, 12))
    for i, (_, img, _) in enumerate(items):
        sheet.paste(img.resize((cell, cell), Image.LANCZOS), ((i % cols) * cell, (i // cols) * cell))
    sheet.save(path)


def request(method, url, key, body=None, raw=None, ctype=None):
    headers = {"Authorization": "Key " + key}
    data = None
    if raw is not None:
        data = raw
        headers["Content-Type"] = ctype or "application/octet-stream"
    elif body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            text = r.read().decode(errors="replace")
            return json.loads(text) if text.strip() else {}
    except urllib.error.HTTPError as e:
        raise RuntimeError("%s %s: fal said %d: %s" % (method, url, e.code, e.read().decode(errors="replace")[:800])) from None


def upload(path, key, log):
    """The zip into fal's storage; returns its URL."""
    init = request("POST", STORAGE, key, {"file_name": os.path.basename(path), "content_type": "application/zip"})
    log.append({"upload_initiate": init})
    put = urllib.request.Request(init["upload_url"], data=open(path, "rb").read(),
                                 headers={"Content-Type": "application/zip"}, method="PUT")
    with urllib.request.urlopen(put, timeout=600) as r:
        log.append({"upload_put": r.status})
    return init["file_url"]


def train(zip_url, key, trigger, steps, log):
    body = {"images_data_url": zip_url, "trigger_word": trigger, "is_style": True, "steps": steps,
            "create_masks": False}
    queued = request("POST", QUEUE + TRAINER, key, body)
    log.append({"queued": queued})
    status_url = queued.get("status_url") or "%s%s/requests/%s/status" % (QUEUE, TRAINER, queued["request_id"])
    response_url = queued.get("response_url") or "%s%s/requests/%s" % (QUEUE, TRAINER, queued["request_id"])
    for _ in range(360):  # an hour
        st = request("GET", status_url, key)
        state = st.get("status")
        print("training:", state, st.get("queue_position", ""))
        if state == "COMPLETED":
            log.append({"status": st})
            return request("GET", response_url, key)
        if state not in ("IN_QUEUE", "IN_PROGRESS"):
            log.append({"status": st})
            raise RuntimeError("training stopped: %s" % json.dumps(st)[:800])
        time.sleep(10)
    raise RuntimeError("training still not done after an hour")


def main():
    dry = "--dry-run" in sys.argv
    steps = 1000
    trigger = "SLTCRK"
    for a in sys.argv[1:]:
        if a.startswith("--steps="):
            steps = int(a.split("=", 1)[1])
        if a.startswith("--trigger="):
            trigger = a.split("=", 1)[1]
    items = gather(trigger)
    path = make_zip(items, os.path.join(BUILD, "train.zip"))
    contact_sheet(items, os.path.join(BUILD, "sheet.png"))
    n_style = sum(1 for n, _, _ in items if n.startswith("style_"))
    print("%d crops (%d from docs/concept/style/), %d KB zipped: %s" % (len(items), n_style, os.path.getsize(path) // 1024, path))
    if dry:
        print("dry run: would upload it and queue %s (steps %d, trigger %s, is_style)." % (TRAINER, steps, trigger))
        return
    key = os.environ.get("FAL_KEY", "")
    if not key:
        sys.exit("No FAL_KEY: nothing trained (try --dry-run).")
    log = []
    try:
        url = upload(path, key, log)
        result = train(url, key, trigger, steps, log)
    finally:
        os.makedirs(BUILD, exist_ok=True)
        json.dump(log, open(os.path.join(BUILD, "fal_log.json"), "w"), indent=1)
    lora = (result.get("diffusers_lora_file") or {}).get("url")
    config = (result.get("config_file") or {}).get("url")
    record = {"trainer": TRAINER, "trigger": trigger, "steps": steps, "crops": len(items),
              "lora_url": lora, "config_url": config, "answer": result, "log": log}
    json.dump(record, open(OUT, "w"), indent=1)
    print("trained:", lora)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
