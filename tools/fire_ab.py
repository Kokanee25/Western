"""The fire's A/B film from tools/fire_ab.gd's frames: the drawn fire sheets on the left, the
simulated flipbooks on the right, each view in turn, labelled, at 24 fps (ffmpeg, H.264).

    python3 tools/fire_ab.py --frames=DIR --out=docs/screenshots/fire/flipbooks_ab.mp4 [--width=1280]
        [--crop=livery_fire_dusk:560,170,440,320;saloon_fire_inside:...] [--repeat=2]

Each view is shown whole, then (with --crop) the box round its fire close up, each `repeat` times.
"""
import glob
import os
import subprocess
import sys
import shutil
import tempfile

from PIL import Image, ImageDraw

LABELS = {"sheets": "drawn fire sheets (now)", "flipbooks": "simulated flipbooks (new)"}


def main():
    args = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    src, out = args["frames"], args["out"]
    width = int(args.get("width", "1280"))
    views = sorted({os.path.basename(p).split("_sheets_")[0] for p in glob.glob(os.path.join(src, "*_sheets_*.png"))},
                   key=lambda v: 0 if v.startswith("livery") else 1)
    crops = {}
    for part in filter(None, args.get("crop", "").split(";")):
        name, box = part.split(":")
        x, y, w, h = (int(v) for v in box.split(","))
        crops[name] = (x, y, x + w, y + h)
    repeat = int(args.get("repeat", "2"))
    tmp = tempfile.mkdtemp(prefix="fire_ab_")
    half_w = width // 2
    canvas_h = half_w * 3 // 4  # every frame one size: each half a 4:3 box, the picture fitted in it
    n = 0
    for view in views:
        count = len(glob.glob(os.path.join(src, "%s_sheets_*.png" % view)))
        for box in [None] + ([crops[view]] if view in crops else []):
            for _ in range(repeat):
                for f in range(count):
                    frame = Image.new("RGB", (half_w * 2, canvas_h))
                    d = ImageDraw.Draw(frame)
                    for i, mode in enumerate(("sheets", "flipbooks")):
                        im = Image.open(os.path.join(src, "%s_%s_%03d.png" % (view, mode, f))).convert("RGB")
                        if box:
                            im = im.crop(box)
                        k = min(half_w / im.width, canvas_h / im.height)
                        im = im.resize((int(im.width * k), int(im.height * k)), Image.NEAREST if box else Image.BOX)
                        frame.paste(im, (i * half_w + (half_w - im.width) // 2, (canvas_h - im.height) // 2))
                        label = "%s%s: %s" % (view, " (close)" if box else "", LABELS[mode])
                        d.rectangle((i * half_w, 0, i * half_w + 6 * len(label) + 10, 16), fill=(0, 0, 0))
                        d.text((i * half_w + 4, 3), label, fill=(255, 255, 255))
                    frame.save(os.path.join(tmp, "f%05d.png" % n))
                    n += 1
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "24", "-i", os.path.join(tmp, "f%05d.png"),
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "28", "-movflags", "+faststart", out], check=True)
    shutil.rmtree(tmp)
    print("fire_ab: %d frames, %s views, %s (%.1f MB)" % (n, views, out, os.path.getsize(out) / 1e6))


if __name__ == "__main__":
    main()
