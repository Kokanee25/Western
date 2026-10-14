"""A target frame for people (Sean, 2026-10-13): a real game frame of a man across the table, the
man alone painted over by FLUX Kontext with the style LoRA, at the frame's own size, as the concept
painting would have him. What a man should look like where the player sees him, for every route
(the portrait factory, Meshy, Tripo) to be judged against. People workflow `style: target`.

    FAL_KEY=... python3 tools/characters/target_frame.py [--frame=PNG] [--scales=0.6,1.0] [--seeds=7,11]
    python3 tools/characters/target_frame.py --dry-run

The frame is docs/screenshots/portrait/target/frame.png (tools/screenshots.gd shot_match_close,
Forward+); the paint-overs go beside it as target_<scale*100>_<seed>.png, back at the frame's size.
About $0.04 a picture on fal.
"""
import json
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import paint_full_length as pf  # noqa: E402

ROOT = pf.ROOT
DIR = os.path.join(ROOT, "docs", "screenshots", "portrait", "target")
LOG = os.path.join(ROOT, "build", "target_frame", "fal_log.json")
ASK = (
    "SLTCRK. Repaint ONLY the seated man in this saloon scene as the painter of the SLTCRK paintings "
    "would paint him: a hard, weathered frontier man with a thick dark moustache, his face modelled "
    "in a few strong planes of warm lamplight and deep shadow under his hat brim, his eyes dark and "
    "clear, his coat and shirt in broad painted shapes. Keep him exactly where he is, the same size, "
    "pose, hat and clothes, and keep everything else in the picture exactly as it is: the table, the "
    "lamp, the room. The same square-pixel painted look as the rest of the picture."
)


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if x.startswith("--") and "=" in x)
    dry = "--dry-run" in sys.argv
    frame_path = a.get("--frame", os.path.join(DIR, "frame.png"))
    scales = [float(s) for s in a.get("--scales", "0.6,1.0").split(",")]
    seeds = [int(s) for s in a.get("--seeds", "7,11").split(",")]
    key = os.environ.get("FAL_KEY", "")
    if not key and not dry:
        print("No FAL_KEY: nothing painted.")
        sys.exit(1)
    frame = Image.open(frame_path).convert("RGB")
    lora_url = json.load(open(pf.LORA))["lora_url"]
    log = [{"editor": pf.EDITOR, "lora_url": lora_url, "frame": frame_path}]
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    os.makedirs(DIR, exist_ok=True)
    made = 0
    try:
        for scale in scales:
            for seed in seeds:
                img = frame.copy() if dry else pf.edit(frame, ASK, lora_url, scale, seed, key, log, "target_%s_%d" % (scale, seed))
                out = os.path.join(DIR if not dry else os.path.dirname(LOG), "target_%d_%d.png" % (round(scale * 100), seed))
                img.resize(frame.size, Image.LANCZOS).save(out)
                made += 1
                print("painted", out)
    finally:
        json.dump(log, open(LOG, "w"), indent=1)
    print("target_frame: %d pictures (about $%.2f on fal)" % (made, 0.0 if dry else 0.04 * made))


if __name__ == "__main__":
    main()
