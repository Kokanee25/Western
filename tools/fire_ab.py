"""The fire's A/B film from tools/fire_ab.gd's frames: the drawn fire sheets on the left, the
simulated flipbooks on the right, each view in turn, labelled, at 24 fps (ffmpeg, H.264).

    python3 tools/fire_ab.py --frames=DIR --out=docs/screenshots/fire/flipbooks_ab.mp4 [--width=1280]
"""
import glob
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw

LABELS = {"sheets": "drawn fire sheets (now)", "flipbooks": "simulated flipbooks (new)"}


def main():
    args = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    src, out = args["frames"], args["out"]
    width = int(args.get("width", "1280"))
    views = sorted({os.path.basename(p).split("_sheets_")[0] for p in glob.glob(os.path.join(src, "*_sheets_*.png"))},
                   key=lambda v: 0 if v.startswith("livery") else 1)
    tmp = tempfile.mkdtemp(prefix="fire_ab_")
    n = 0
    for view in views:
        count = len(glob.glob(os.path.join(src, "%s_sheets_*.png" % view)))
        for f in range(count):
            a = Image.open(os.path.join(src, "%s_sheets_%03d.png" % (view, f))).convert("RGB")
            b = Image.open(os.path.join(src, "%s_flipbooks_%03d.png" % (view, f))).convert("RGB")
            half = (width // 2, int(a.height * (width // 2) / a.width))
            frame = Image.new("RGB", (half[0] * 2, half[1]))
            frame.paste(a.resize(half, Image.BOX), (0, 0))
            frame.paste(b.resize(half, Image.BOX), (half[0], 0))
            d = ImageDraw.Draw(frame)
            for i, mode in enumerate(("sheets", "flipbooks")):
                d.rectangle((i * half[0], 0, i * half[0] + 8 * len(view + LABELS[mode]) + 30, 16), fill=(0, 0, 0))
                d.text((i * half[0] + 4, 3), "%s: %s" % (view, LABELS[mode]), fill=(255, 255, 255))
            frame.save(os.path.join(tmp, "f%04d.png" % n))
            n += 1
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "24", "-i", os.path.join(tmp, "f%04d.png"),
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "23", "-movflags", "+faststart", out], check=True)
    print("fire_ab: %d frames, %s views, %s (%.1f MB)" % (n, views, out, os.path.getsize(out) / 1e6))


if __name__ == "__main__":
    main()
