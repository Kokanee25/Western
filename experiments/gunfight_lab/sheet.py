#!/usr/bin/env python3
"""A gunfight's contact sheet (README.md): the overview and your eyes at each moment drawn, what
happened between them, and a strip of the whole fight (who was where in it, every shot and hit).

    python3 experiments/gunfight_lab/sheet.py FIGHT.json SHOTS_DIR [--out=sheet.png] [--width=1800]

FIGHT.json and SHOTS_DIR come from a drawn `gf_fight ... out=FIGHT.json shots=SHOTS_DIR every=S`
(run.py --sheet does it). With no SHOTS_DIR (or none drawn) it's the strip alone.
"""
import glob
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

MEN = ["brody", "lyle", "kid"]
COL = {"you": (40, 40, 40), "brody": (176, 70, 40), "lyle": (40, 110, 170), "kid": (90, 140, 50)}
STATE = {"open": (225, 200, 120), "moving": (240, 150, 60), "hidden": (130, 130, 130), "peeking": (200, 90, 90),
         "searching": (170, 140, 200), "rescuing": (120, 200, 200)}
OUT_STATE = {"surrendered": (236, 232, 222), "fleeing": (250, 230, 60), "down": (60, 60, 60), "dead": (0, 0, 0),
             "tending": (150, 200, 150), "calm": (210, 210, 240)}


def font(size):
    for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/TTF/DejaVuSans.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def strip(fight, width):
    """The fight along a time line: each man's state, shots (ticks) and hits (dots), situations."""
    L = max(fight["length_s"], 1.0)
    h_row = 26
    top = 34
    img = Image.new("RGB", (width, top + h_row * 4 + 60), (250, 248, 242))
    d = ImageDraw.Draw(img)
    f = font(14)
    x0, x1 = 90, width - 20
    X = lambda t: x0 + (x1 - x0) * min(max(t / L, 0), 1)
    head = (f"{fight['scenario']} · {fight['hour']} · {fight['weapon']} · {fight['style']} · {fight['bodies']} bodies · seed {fight['seed']} — "
            f"{fight['length_s']:.1f} s, ended: {fight['ending']}; first hit by {fight['first_hit_by']} at {fight['first_hit_at']:.1f} s; "
            f"you hit {fight['you']['hits']}× / hit {fight['you']['hits_taken']}×")
    d.text((10, 8), head, fill=(20, 20, 20), font=f)
    rows = ["you"] + MEN
    track = fight["track"]
    for i, who in enumerate(rows):
        y = top + i * h_row
        d.text((10, y + 4), who, fill=COL[who], font=f)
        for a, b in zip(track, track[1:] + [{"t": L, "men": {}, "you": None}]):
            if who == "you":
                c = (120, 120, 120) if a["you"][2] else (200, 200, 200)
            else:
                m = a["men"].get(who)
                if not m:
                    continue
                c = OUT_STATE.get(m[3]) or STATE.get(m[2], (200, 200, 200))
            d.rectangle([X(a["t"]), y + 6, X(b["t"]), y + h_row - 4], fill=c)
    for t, kind, text in fight["timeline"]:
        if kind == "shot":
            who = text.split(" ")[0]
            if who in rows:
                y = top + rows.index(who) * h_row
                d.line([X(t), y + 2, X(t), y + h_row], fill=(0, 0, 0), width=1)
        elif kind == "hit":
            victim = text.split(" ")[0]
            if victim in rows:
                y = top + rows.index(victim) * h_row + h_row // 2
                d.ellipse([X(t) - 4, y - 4, X(t) + 4, y + 4], fill=(200, 20, 20))
        elif kind == "situation":
            y = top + 4 * h_row + 6
            d.polygon([(X(t), y), (X(t) - 5, y + 9), (X(t) + 5, y + 9)], fill=(150, 60, 160))
    y = top + 4 * h_row + 20
    for s in range(0, int(L) + 1, 5 if L < 60 else 10):
        d.line([X(s), top, X(s), y - 4], fill=(225, 220, 210))
        d.text((X(s) - 6, y), f"{s}", fill=(90, 90, 90), font=font(11))
    d.text((x0, y + 18), "bars: open · moving · hidden · peeking · searching (colours); white gave up, yellow fleeing, dark down/dead · ticks: shots · red: hits · purple: situation changes",
           fill=(90, 90, 90), font=font(11))
    return img


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    fight = json.load(open(argv[0]))
    shots = argv[1] if len(argv) > 1 and not argv[1].startswith("--") else ""
    out = next((a.split("=", 1)[1] for a in argv if a.startswith("--out=")), os.path.splitext(argv[0])[0] + "_sheet.png")
    width = int(next((a.split("=", 1)[1] for a in argv if a.startswith("--width=")), 1800))
    top = strip(fight, width)
    tags = sorted({os.path.basename(p).rsplit("_", 1)[0] for p in glob.glob(os.path.join(shots, "t*_over.png"))}) if shots else []
    if not tags:
        top.save(out)
        print("strip only ->", out)
        return 0
    cols = 4
    cell_w = width // cols
    pairs = []
    for tag in tags:
        over = Image.open(os.path.join(shots, tag + "_over.png")).convert("RGB")
        you_p = os.path.join(shots, tag + "_you.png")
        you = Image.open(you_p).convert("RGB") if os.path.exists(you_p) else None
        pairs.append((tag, over, you))
    ch = int(cell_w * pairs[0][1].height / pairs[0][1].width)
    caption_h = 92
    rows = (len(pairs) + cols - 1) // cols
    sheet = Image.new("RGB", (width, top.height + rows * (ch * 2 + caption_h)), (250, 248, 242))
    sheet.paste(top, (0, 0))
    d = ImageDraw.Draw(sheet)
    f = font(12)
    times = [float(t[1:]) for t, _, _ in pairs]
    for i, (tag, over, you) in enumerate(pairs):
        x = (i % cols) * cell_w
        y = top.height + (i // cols) * (ch * 2 + caption_h)
        sheet.paste(over.resize((cell_w - 4, ch - 2)), (x + 2, y))
        marks_p = os.path.join(shots, tag + "_marks.json")
        if os.path.exists(marks_p):
            for who, (fx, fy) in json.load(open(marks_p)).items():
                px, py = x + 2 + fx * (cell_w - 4), y + fy * (ch - 2)
                if 0 <= fx <= 1 and 0 <= fy <= 1:
                    d.rectangle([px - 18, py - 13, px + 18, py + 1], fill=COL.get(who, (0, 0, 0)))
                    d.text((px - 15, py - 13), who[:5], fill=(255, 255, 255), font=font(11))
        if you:
            sheet.paste(you.resize((cell_w - 4, ch - 2)), (x + 2, y + ch))
        t = times[i]
        nxt = times[i + 1] if i + 1 < len(times) else fight["length_s"] + 0.01
        happened = [e for e in fight["timeline"] if t <= e[0] < nxt and e[1] in ("hit", "situation", "out", "cover", "mood", "near_miss", "callout")]
        lines = [f"t {t:.1f} s (overview above, your eyes below)"] + [f"{e[0]:.1f} {e[2]}"[:60] for e in happened[:5]]
        if len(happened) > 5:
            lines.append(f"... and {len(happened) - 5} more")
        d.multiline_text((x + 6, y + ch * 2 + 4), "\n".join(lines), fill=(30, 30, 30), font=f, spacing=2)
    sheet.save(out)
    print(f"{len(pairs)} moments -> {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
