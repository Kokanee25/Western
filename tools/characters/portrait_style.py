"""The portrait factory's styled pictures: a man's plain views (front, left, right, back) repainted
in our style by FLUX Kontext with the style LoRA on fal, same pose, same framing, flat light, so the
factory can be run on pictures that are already painted (Sean, 2026-10-13: is the reference the
gap?). People workflow input `style: portrait`, `characters: <man>` (needs FAL_KEY).

    FAL_KEY=... python3 tools/characters/portrait_style.py --man=bold_cowboy [--scales=0.3,0.6] [--seed=7]
    python3 tools/characters/portrait_style.py --man=bold_cowboy --dry-run   # no network: a stand-in

Writes docs/concept/style/factory/<man>_styled_<scale*100>/{front,left,right,back}.png (1254 px, as
the plain ones) and the fal log to build/portrait_style/fal_log.json. Each view is one Kontext
edit ($0.035-0.04 a picture on fal): the man in his own picture repainted, nothing moved, so the
factory's fit and projection work on it as on the plain set. `style_hair` in portrait.json (his
style portrait's hair, where it differs from his plain pictures') goes into the ask.
"""
import json
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import paint_full_length as pf  # noqa: E402  (fal's queue, the LoRA's file)

ROOT = pf.ROOT
PORTRAIT = os.path.join(ROOT, "assets", "people", "portrait.json")
LOG = os.path.join(ROOT, "build", "portrait_style", "fal_log.json")
VIEWS = ("front", "left", "right", "back")
SEEN = {"front": "from straight in front", "left": "in profile, facing left", "right": "in profile, facing right",
        "back": "from straight behind"}
ASK = (
    "SLTCRK. Repaint this exact picture as a painting in the SLTCRK style: the same man, seen {seen}, "
    "in exactly the same pose, size and place in the frame, nothing moved. Paint his face in a few "
    "simplified planes of warm, earthy colour with clear edges between them, the way a painter "
    "blocks in a weathered face: his brow, eye sockets, cheekbones, nose, moustache and jaw as "
    "readable shapes, his eyes and the line of his mouth drawn clearly. {hair}Flat, even light from "
    "the front, no strong shadows, no highlights. No hat. A plain grey background. Smooth paint, "
    "NOT square pixels, no mosaic, no text."
)


def ask(view, spec):
    hair = ("His hair is %s. " % spec["style_hair"]) if spec.get("style_hair") else "Keep his hair as it is. "
    return ASK.format(seen=SEEN[view], hair=hair)


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if x.startswith("--") and "=" in x)
    dry = "--dry-run" in sys.argv
    men = json.load(open(PORTRAIT))["men"]
    ids = [m for m in a.get("--man", "bold_cowboy").split(",") if m]
    scales = [float(s) for s in a.get("--scales", "0.3,0.6").split(",")]
    seed = int(a.get("--seed", "7"))
    key = os.environ.get("FAL_KEY", "")
    if not key and not dry:
        print("No FAL_KEY: nothing painted.")
        sys.exit(1)
    lora_url = json.load(open(pf.LORA))["lora_url"]
    log = [{"editor": pf.EDITOR, "lora_url": lora_url, "scales": scales, "seed": seed}]
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    made = 0
    try:
        for man in ids:
            spec = men[man]
            for scale in scales:
                out = os.path.join(ROOT, "docs", "concept", "style", "factory", "%s_styled_%d" % (man, round(scale * 100)))
                os.makedirs(out, exist_ok=True)
                for view in VIEWS:
                    src = Image.open(os.path.join(ROOT, spec["pictures"], view + ".png")).convert("RGB")
                    if dry:
                        img = src.copy()
                    else:
                        img = pf.edit(src, ask(view, spec), lora_url, scale, seed, key, log, "%s_%s_%s" % (man, scale, view))
                    # Back to the plain picture's size: the fit takes each set as framed alike.
                    img.resize(src.size, Image.LANCZOS).save(os.path.join(out, view + ".png"))
                    made += 1
                    print("painted", man, scale, view)
    finally:
        json.dump(log, open(LOG, "w"), indent=1)
    print("portrait_style: %d pictures (about $%.2f on fal)" % (made, 0.04 * made if not dry else 0.0))


if __name__ == "__main__":
    main()
