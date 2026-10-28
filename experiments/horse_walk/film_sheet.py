"""A contact sheet of one stride of our side film, laid out as the clip's (reference/stride_sheet.jpg:
14 frames, two rows of seven), mirrored to walk the clip's way, for the blind judge to set beside it.

    python3 experiments/horse_walk/film_sheet.py   (needs build/horse_walk/film_side/, make_films.sh)
Writes experiments/horse_walk/films/walk_side_sheet.jpg.
"""
import json
import os

from PIL import Image, ImageDraw, ImageOps

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
B = os.path.join(ROOT, "build", "horse_walk")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "films", "walk_side_sheet.jpg")
N, COLS, CELL = 14, 7, (240, 175)


def main():
    T = json.load(open(os.path.join(B, "walk_report.json")))["walk"]["T"]
    fps = 30
    start = int(round(T * fps))              # the second stride: from the left hind's landing
    frames = [start + int(round(k * T * fps / N)) for k in range(N)]
    sheet = Image.new("RGB", (CELL[0] * COLS, CELL[1] * ((N + COLS - 1) // COLS)), (255, 255, 255))
    for k, f in enumerate(frames):
        im = ImageOps.mirror(Image.open(os.path.join(B, "film_side", "f%03d.png" % f)).convert("RGB"))
        w, h = im.size
        # the horse fills the middle of the side film's frame
        im = im.crop((int(w * 0.27), int(h * 0.20), int(w * 0.77), int(h * 0.78))).resize(CELL, Image.LANCZOS)
        ImageDraw.Draw(im).text((4, 3), "%.2f" % (k / N), fill=(255, 255, 0))
        sheet.paste(im, ((k % COLS) * CELL[0], (k // COLS) * CELL[1]))
    sheet.save(OUT, quality=85)
    print("wrote", OUT, "frames", frames)


if __name__ == "__main__":
    main()
