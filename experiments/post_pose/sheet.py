"""The post pose's sheets from post_views.gd's renders (issue #531):
    python3 experiments/post_pose/sheet.py DIR --hero=3 [--man=bold_cowboy_s3_talking] [--out=OUTDIR]
hero.png: one man's four views, big, with his measures; family.png: every seed rendered, a row each."""
import argparse, json, os
from PIL import Image, ImageDraw, ImageFont

VIEWS = ["front", "three_quarter", "overhead", "side"]
TITLES = {"front": "front (the opponent's view)", "three_quarter": "three-quarter (elbow, forearm across)",
          "overhead": "overhead (north up: his turn to the post)", "side": "side, from the east (shoulder on the post, arms)"}

ap = argparse.ArgumentParser()
ap.add_argument("dir")
ap.add_argument("--hero", type=int, default=3)
ap.add_argument("--man", default="bold_cowboy_s3_talking")
ap.add_argument("--out", default=None)
a = ap.parse_args()
out = a.out or a.dir
checks = json.load(open(os.path.join(a.dir, "checks.json")))
try:
    font = ImageFont.truetype("DejaVuSans.ttf", 15)
    small = ImageFont.truetype("DejaVuSans.ttf", 12)
except OSError:
    font = small = ImageFont.load_default()


def img(seed, view, size):
    return Image.open(os.path.join(a.dir, f"{a.man}_s{seed}_{view}.png")).convert("RGB").resize((size, size), Image.LANCZOS)


def measures(c):
    h = c["hidden_from_threat"]
    return (f"upper arm {c['upper_arm_r_from_vertical']:.0f}° off vertical · elbow {c['elbow']:.0f}° · forearm {c['forearm_from_level']:+.0f}° off level, "
            f"{c['forearm_off_threat']:+.0f}° off the threat's line · left arm {c['upper_arm_l_from_vertical']:.0f}° off vertical · lean {c['lean']:.0f}°",
            f"hidden from the threat: {h['all']:.0%} (head {h['head']:.0%}, trunk {h['trunk']:.0%}, legs {h['legs']:.0%}) · eye sees past: {c['eye_sees_threat']} · "
            f"gun into post: {c['gun_into_post']} · body into post: {c['body_into_post']*100:.1f} cm · forearm to belly {c['forearm_to_trunk_gap']*100:.1f} cm")


def label(c):
    d = c["dials"]
    style = "gun across him" if d["style"] == "cross" else "regular hold"
    return f"{style}, {d['legs']} legs, showing {'nothing extra' if d['show'] == 'none' else 'a bit of ' + d['show']}"


# The hero sheet.
S = 480
c = checks[str(a.hero)]
hero = Image.new("RGB", (S * 4, S + 96), (236, 232, 224))
dr = ImageDraw.Draw(hero)
for i, v in enumerate(VIEWS):
    hero.paste(img(a.hero, v, S), (i * S, 26))
    dr.text((i * S + 8, 5), TITLES[v], fill=(30, 25, 20), font=font)
m1, m2 = measures(c)
dr.text((8, S + 32), f"{a.man}, seed {a.hero}: {label(c)}. Threat 6 m north (red line points to it); the gallery's 8x8 post.", fill=(30, 25, 20), font=font)
dr.text((8, S + 54), m1, fill=(60, 50, 40), font=small)
dr.text((8, S + 72), m2, fill=(60, 50, 40), font=small)
hero.save(os.path.join(out, "hero.png"))

# The family sheet.
T = 230
seeds = sorted(int(s) for s in checks)
fam = Image.new("RGB", (T * 4 + 250, T * len(seeds) + 30), (236, 232, 224))
dr = ImageDraw.Draw(fam)
for i, v in enumerate(VIEWS):
    dr.text((250 + i * T + 6, 8), v.replace("_", "-"), fill=(30, 25, 20), font=font)
for r, s in enumerate(seeds):
    c = checks[str(s)]
    for i, v in enumerate(VIEWS):
        fam.paste(img(s, v, T), (250 + i * T, 30 + r * T))
    d = c["dials"]
    txt = [f"seed {s}", "gun across him" if d["style"] == "cross" else "regular hold", f"legs {d['legs']}",
           f"shows: {d['show']}", f"turned {d['turn']:.0f}°, twist {d['twist']:.0f}°", f"lean {c['lean']:.0f}°, peek {d['peek']*100:.0f} cm",
           f"upper arm {c['upper_arm_r_from_vertical']:.0f}°, elbow {c['elbow']:.0f}°", f"hidden {c['hidden_from_threat']['all']:.0%}"]
    for j, t in enumerate(txt):
        dr.text((10, 30 + r * T + 10 + j * 19), t, fill=(30, 25, 20) if j == 0 else (70, 60, 50), font=font if j == 0 else small)
fam.save(os.path.join(out, "family.png"))
print("wrote", os.path.join(out, "hero.png"), os.path.join(out, "family.png"))
