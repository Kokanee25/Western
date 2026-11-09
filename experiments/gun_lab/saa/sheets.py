#!/usr/bin/env python3
"""The SAA's sheets from a saa_views.gd folder: the turntable (a sheet and a film), the close shots,
the mechanism strip.

    python3 experiments/gun_lab/saa/sheets.py VIEWS_DIR OUT_DIR
"""
import glob
import os
import subprocess
import sys

from PIL import Image, ImageDraw


def label(img, text):
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, 8 + 7 * len(text), 18), fill=(0, 0, 0))
    d.text((4, 3), text, fill=(255, 255, 255))
    return img


def grid(paths, cols, w, out, names=True, crop=None):
    ims = []
    for p in paths:
        im = Image.open(p).convert("RGB")
        if crop:
            W, H = im.size
            im = im.crop((int(crop[0] * W), int(crop[1] * H), int(crop[2] * W), int(crop[3] * H)))
        h = int(im.height * w / im.width)
        im = im.resize((w, h), Image.LANCZOS)
        ims.append(label(im, os.path.splitext(os.path.basename(p))[0]) if names else im)
    rows = (len(ims) + cols - 1) // cols
    h = ims[0].height
    sheet = Image.new("RGB", (cols * w, rows * h), (20, 20, 20))
    for i, im in enumerate(ims):
        sheet.paste(im, ((i % cols) * w, (i // cols) * h))
    sheet.save(out, quality=86)
    print(out, sheet.size)


def main():
    src, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    tt = sorted(glob.glob(os.path.join(src, "turntable_*.png")))
    if tt:
        grid(tt, 6, 400, os.path.join(out, "turntable.jpg"), names=False, crop=(0.12, 0.08, 0.88, 0.92))
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "6", "-i", os.path.join(src, "turntable_%02d.png"),
                        "-vf", "crop=iw*0.76:ih*0.84:iw*0.12:ih*0.08,scale=1216:-2", "-pix_fmt", "yuv420p", "-c:v", "libx264",
                        "-crf", "22", os.path.join(out, "turntable.mp4")], check=True)
        print(os.path.join(out, "turntable.mp4"))
    close = [os.path.join(src, n + ".png") for n in ("close_right", "close_left", "close_muzzle", "close_hammer_top",
                                                     "close_loading", "close_cocked", "fp_sights")]
    close = [p for p in close if os.path.exists(p)]
    if close:
        grid(close, 2, 960, os.path.join(out, "close.jpg"))
        for p in close:
            Image.open(p).convert("RGB").save(os.path.join(out, os.path.splitext(os.path.basename(p))[0] + ".jpg"), quality=88)
    mech = sorted(glob.glob(os.path.join(src, "mech_*.png")))
    if mech:
        grid(mech, 4, 480, os.path.join(out, "mech.jpg"), crop=(0.18, 0.12, 0.82, 0.88))


main()
