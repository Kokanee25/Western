#!/usr/bin/env python3
"""See what the style LoRA learned (tools/style/train_style.py -> tools/style/style_lora.json):
FLUX with the LoRA on fal paints a few set prompts, each with the trigger word, and they go in a
contact sheet beside the paintings they were trained on.

    FAL_KEY=... python3 tools/style/sample_style.py [--scale=1.0] [--steps=28] [--seed=7]
        [--only=name,name]

Runs on GitHub Actions (People workflow, input `style: sample`; the key is a repo secret, never the
repo). Writes docs/style_test/lora/<name>.png and docs/style_test/lora/sheet.png, and keeps every
answer in build/style_sample/fal_log.json. fal's queue API (POST https://queue.fal.run/<app>, its
status_url and response_url) as train_style.py uses it; the generator is FAL_SAMPLER, default
fal-ai/flux-lora (FLUX.1 [dev] with LoRAs: `loras: [{path, scale}]`).
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RECORD = os.path.join(ROOT, "tools", "style", "style_lora.json")
OUT = os.path.join(ROOT, "docs", "style_test", "lora")
BUILD = os.path.join(ROOT, "build", "style_sample")
SAMPLER = os.environ.get("FAL_SAMPLER") or "fal-ai/flux-lora"
QUEUE = "https://queue.fal.run/"

# What to ask for: the things the pipeline will want painted in this style. Sizes as fal names
# them (portrait_4_3 etc.) or [w, h].
PROMPTS = {
    "gunman_full": ("SLTCRK, a weathered frontier gunman of about forty in 1882 standing in an A-pose, full "
                    "length, facing the viewer, dark wide-brimmed hat, long dark hair, thick drooping moustache, "
                    "white shirt, dark necktie, patterned vest, heavy dark brown frock coat, cartridge belt and "
                    "holster, worn boots, on a plain grey background, soft even light", "portrait_16_9"),
    "saloon_night": ("SLTCRK, the inside of a frontier saloon at night lit by oil lamps, a long bar with a "
                     "mirror and bottles, men at card tables, warm lamplight and deep shadows", "landscape_16_9"),
    "street_golden": ("SLTCRK, the main street of a frontier town at golden hour, false-front wooden buildings "
                      "with painted signs, horses at a hitching rail, red rock spires beyond, the low sun ahead",
                      "landscape_16_9"),
    "portrait": ("SLTCRK, a close portrait of a frontier gunman looking at the viewer from under a dark hat brim, "
                 "heavy brows, a thick moustache, lamplight on one side of his face", "square"),
    "horse": ("SLTCRK, a bay horse with a stock saddle standing at a hitching rail in a dusty street, side view, "
              "golden afternoon light", "landscape_4_3"),
    "boards": ("SLTCRK, sun-bleached weathered pine siding boards of a frontier building, seen straight on, "
               "filling the frame", "square"),
}


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


def generate(prompt, size, lora_url, scale, steps, seed, key, log):
    body = {"prompt": prompt, "image_size": size, "num_inference_steps": steps, "guidance_scale": 3.5,
            "num_images": 1, "seed": seed, "output_format": "png", "enable_safety_checker": False,
            "loras": [{"path": lora_url, "scale": scale}]}
    queued = request("POST", QUEUE + SAMPLER, key, body)
    log.append({"queued": queued, "prompt": prompt})
    status_url = queued.get("status_url") or "%s%s/requests/%s/status" % (QUEUE, SAMPLER, queued["request_id"])
    response_url = queued.get("response_url") or "%s%s/requests/%s" % (QUEUE, SAMPLER, queued["request_id"])
    for _ in range(120):
        st = request("GET", status_url, key)
        state = st.get("status")
        if state == "COMPLETED":
            answer = request("GET", response_url, key)
            log.append({"answer": answer})
            images = answer.get("images") or []
            if not images:
                raise RuntimeError("no image in the answer: %s" % json.dumps(answer)[:600])
            with urllib.request.urlopen(images[0]["url"], timeout=600) as r:
                return r.read()
        if state not in ("IN_QUEUE", "IN_PROGRESS"):
            log.append({"status": st})
            raise RuntimeError("generation stopped: %s" % json.dumps(st)[:800])
        time.sleep(5)
    raise RuntimeError("generation still not done after ten minutes")


def sheet(names, path, cell=420):
    tiles = []
    for name in names:
        p = os.path.join(OUT, name + ".png")
        if not os.path.exists(p):
            continue
        im = Image.open(p).convert("RGB")
        s = cell / max(im.size)
        im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)
        tile = Image.new("RGB", (cell, cell + 18), (28, 28, 28))
        tile.paste(im, ((cell - im.width) // 2, 18 + (cell - im.height) // 2))
        ImageDraw.Draw(tile).text((4, 3), name, fill=(255, 255, 255))
        tiles.append(tile)
    for ref in ("saloon-night", "street-golden-hour"):
        p = os.path.join(ROOT, "docs", "concept", ref + ".png")
        if os.path.exists(p):
            im = Image.open(p).convert("RGB")
            s = cell / max(im.size)
            im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
            tile = Image.new("RGB", (cell, cell + 18), (28, 28, 28))
            tile.paste(im, (0, 18 + (cell - im.height) // 2))
            ImageDraw.Draw(tile).text((4, 3), "painting: " + ref, fill=(255, 255, 255))
            tiles.append(tile)
    if not tiles:
        return
    cols = 4
    rows = (len(tiles) + cols - 1) // cols
    out = Image.new("RGB", (cols * (cell + 4), rows * (cell + 22)), (28, 28, 28))
    for i, t in enumerate(tiles):
        out.paste(t, ((i % cols) * (cell + 4), (i // cols) * (cell + 22)))
    out.save(path)


def main():
    key = os.environ.get("FAL_KEY", "")
    if not key:
        print("No FAL_KEY: nothing sampled.")
        return
    if not os.path.exists(RECORD):
        print("No %s: train the style first (train_style.py)." % RECORD)
        sys.exit(1)
    record = json.load(open(RECORD))
    lora_url = record["lora_url"]
    scale, steps, seed, only = 1.0, 28, 7, None
    for a in sys.argv[1:]:
        if a.startswith("--scale="):
            scale = float(a.split("=", 1)[1])
        elif a.startswith("--steps="):
            steps = int(a.split("=", 1)[1])
        elif a.startswith("--seed="):
            seed = int(a.split("=", 1)[1])
        elif a.startswith("--only=") and a.split("=", 1)[1]:
            only = a.split("=", 1)[1].split(",")
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(BUILD, exist_ok=True)
    log = [{"sampler": SAMPLER, "lora_url": lora_url, "scale": scale, "steps": steps, "seed": seed}]
    failed = []
    for name, (prompt, size) in PROMPTS.items():
        if only and name not in only:
            continue
        try:
            png = generate(prompt, size, lora_url, scale, steps, seed, key, log)
            with open(os.path.join(OUT, name + ".png"), "wb") as f:
                f.write(png)
            print("painted:", name)
        except (RuntimeError, OSError, KeyError, ValueError) as e:
            print("failed:", name, e)
            failed.append(name)
        with open(os.path.join(BUILD, "fal_log.json"), "w") as f:
            json.dump(log, f, indent=1)
    sheet(list(PROMPTS), os.path.join(OUT, "sheet.png"))
    if failed:
        print("not painted:", ", ".join(failed))
        if len(failed) == len(PROMPTS):
            sys.exit(1)


if __name__ == "__main__":
    main()
