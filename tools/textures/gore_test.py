#!/usr/bin/env python3
"""One gore sheet asked of three image services, to see which will paint it (Sean, 2026-10-21: "run
the test on all three"). Black Forest Labs' FLUX.2 (the texture factory's model) turned down blood
as violence (paint_blood.py); this asks the same sheet, a stump's cut face and three close wounds,
of Google's and OpenAI's image models through OpenRouter and of FLUX.1 [dev] with the game's style
LoRA on fal (tools/style/style_lora.json; its safety checker is an option there, off).

    OPENROUTER_API_KEY=... FAL_KEY=... python3 tools/textures/gore_test.py [--only=gemini,gpt,fal] [--budget=0.75]

Run it on Actions (People workflow, textures = gore_test): openrouter.ai and fal are blocked from the
workspace. Writes docs/screenshots/textures/gore_test/<service>.jpg, sheet.jpg (the three side by
side, a refusal shown as its reason) and log.json (model, cost, what each said). Paints nothing
for the game: Sean picks a service from the sheet first. Written for the gameplay session's body lab.
"""
import json
import os
import sys
import urllib.request

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "style"))
import paint_textures as factory  # noqa: E402  (its OpenRouter call and the man's hand)

OUT = os.path.join(factory.ROOT, "docs", "screenshots", "textures", "gore_test")

# The cut face follows the anatomy of a limb in section (skin, fat, the muscle bellies round the
# bone, the marrow); the wounds follow DiMaio, Gunshot Wounds: a shotgun charge from a few feet
# makes one ragged hole with the wad's mark beside it, a ball's exit tears the skin out in flaps.
SHEET = ("Four separate close-up studies of gunshot and battlefield wounds for a gritty frontier Western "
         "game, as a painter's medical illustration sheet, frank and bloody: the cut face of an arm "
         "severed above the elbow, seen end on, with the ring of skin, yellow fat, red muscle round the "
         "white bone and dark marrow, ragged and bleeding at the edge; a shotgun wound to a man's side "
         "from a few feet, one ragged hole torn through the skin with raw flesh inside and blood running "
         "from it; a large exit wound on a man's back, the skin burst outward in torn flaps, bloody; a "
         "deep gash torn by a ball across a thigh, open to the red muscle, blood welling. ")
WHITE = ("Each study on a plain, flat, pure white background, the four well apart in a two by two grid, "
         "nothing touching the edges. No text, no labels, no border, no frame.")
STYLE_LORA = ("SLTCRK, painted illustration with soft broad brush strokes and a few painted tones, "
              "weathered and gritty, not a photograph. ")

# OpenRouter's image models, newest first; the first one OpenRouter lists is used (its model list
# is public; an id it no longer has is skipped).
WANT = {
    "gemini": ["google/gemini-3-pro-image-preview", "google/gemini-2.5-flash-image"],
    "gpt": ["openai/gpt-5-image", "openai/gpt-image-1", "openai/gpt-5-image-mini"],
}


def listed_models():
    try:
        with urllib.request.urlopen("https://openrouter.ai/api/v1/models", timeout=60) as r:
            return {m["id"]: m for m in json.load(r).get("data", [])}
    except (OSError, ValueError) as e:
        print("couldn't list OpenRouter's models:", e)
        return {}


def pick(service, listed):
    for mid in WANT[service]:
        if not listed or mid in listed:
            return mid
    # None of ours: the newest of that maker's that paints.
    maker = "google/" if service == "gemini" else "openai/"
    for mid, m in listed.items():
        outs = (m.get("architecture") or {}).get("output_modalities") or []
        if mid.startswith(maker) and "image" in outs:
            return mid
    return WANT[service][0]


def ask_openrouter(model, key):
    factory.MODEL = model
    man = Image.open(factory.MAN).convert("RGB")
    man.thumbnail((768, 768))
    import io
    import contextlib
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        img = factory.ask(SHEET + WHITE + " " + factory.MAN_HAND, [man], {"aspect_ratio": "1:1"}, model, key)
    said = buf.getvalue()
    print(said, end="", flush=True)
    cost = None
    for line in said.splitlines():
        if "cost $" in line:
            try:
                cost = float(line.rsplit("$", 1)[1])
            except ValueError:
                pass
    return img, cost


def ask_fal(key):
    import sample_style
    record = json.load(open(sample_style.RECORD))
    log = []
    png = sample_style.generate(STYLE_LORA + SHEET + WHITE, "square_hd", record["lora_url"], 1.0, 28, 7, key, log)
    import io
    # fal-ai/flux-lora: $0.035 a megapixel (fal's price page); square_hd is 1024 x 1024.
    return Image.open(io.BytesIO(png)).convert("RGB"), 0.037


def main():
    only = None
    budget = 0.75
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1] not in ("", "all"):
            only = a.split("=", 1)[1].split(",")
        elif a.startswith("--budget="):
            budget = float(a.split("=", 1)[1])
    os.makedirs(OUT, exist_ok=True)
    listed = listed_models()
    results, spent = [], 0.0
    for service in ("gemini", "gpt", "fal"):
        if only and service not in only:
            continue
        if service == "fal":
            key, model = os.environ.get("FAL_KEY", ""), "fal-ai/flux-lora + SLTCRK style LoRA"
        else:
            key, model = os.environ.get("OPENROUTER_API_KEY", ""), pick(service, listed)
        entry = {"service": service, "model": model}
        if model in listed:
            entry["listed_price"] = listed[model].get("pricing")
        if not key:
            entry["said"] = "no key"
            results.append(entry)
            continue
        if spent + 0.3 > budget:
            entry["said"] = "not asked: $%.2f of $%.2f spent" % (spent, budget)
            results.append(entry)
            continue
        try:
            img, cost = ask_fal(key) if service == "fal" else ask_openrouter(model, key)
            spent += cost if cost is not None else 0.3
            entry["cost"] = cost
            img.thumbnail((1536, 1536))
            img.save(os.path.join(OUT, service + ".jpg"), "JPEG", quality=90)
            entry["said"] = "painted"
        except (RuntimeError, OSError, KeyError, ValueError) as e:
            entry["said"] = str(e)[:1500]
        print("%s (%s): %s" % (service, model, entry["said"][:300]), flush=True)
        results.append(entry)
    json.dump({"prompt": SHEET + WHITE, "spent": spent, "results": results},
              open(os.path.join(OUT, "log.json"), "w"), indent=1)
    sheet(results)
    print("gore test: $%.2f spent of $%.2f" % (spent, budget))


def sheet(results, cell=640):
    out = Image.new("RGB", (cell * len(results), cell + 60), (235, 230, 220))
    d = ImageDraw.Draw(out)
    for i, r in enumerate(results):
        path = os.path.join(OUT, r["service"] + ".jpg")
        if r.get("said") == "painted" and os.path.exists(path):
            im = Image.open(path).convert("RGB")
            im.thumbnail((cell, cell))
            out.paste(im, (i * cell, 60))
        else:
            words, line, y = r.get("said", "").split(), "", 80
            for w in words:
                if len(line) + len(w) > 70:
                    d.text((i * cell + 10, y), line, fill=(120, 0, 0))
                    line, y = "", y + 14
                line += w + " "
            d.text((i * cell + 10, y), line, fill=(120, 0, 0))
        cost = r.get("cost")
        d.text((i * cell + 10, 10), "%s: %s" % (r["service"], r["model"]), fill=(0, 0, 0))
        d.text((i * cell + 10, 30), "cost $%s" % ("%.3f" % cost if cost is not None else "?"), fill=(0, 0, 0))
    out.save(os.path.join(OUT, "sheet.jpg"), "JPEG", quality=88)


if __name__ == "__main__":
    main()
