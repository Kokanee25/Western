#!/usr/bin/env python3
"""Paint the game's blood marks in its painted hand (Sean, 2026-10-21: "do the paid part, take $3"):
splats on the ground, soaks on cloth, the pool under a man, and the marks round a wound, as sheets of
four on plain white with the layered cowboy's model sheet as the style. cut_blood.py cuts them into
the decal textures PixelArt.blood hands out (assets/textures/blood/<key>.png).

    OPENROUTER_API_KEY=... python3 tools/textures/paint_blood.py [--only=splats,stains] [--repaint] [--budget=3]

Run it on Actions (People workflow, textures = blood): openrouter.ai is blocked from the workspace.
Every call prints its cost; it stops before a call would take the run past --budget dollars (each
call is reckoned at the dearest one so far). Written for the gameplay session's body lab
(experiments/body_lab/results/2026-10-21_blood_look/); the model call is the texture factory's.
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import paint_textures as factory  # noqa: E402  (its OpenRouter call and the man's hand)

RAW = os.path.join(factory.ROOT, "assets", "textures", "raw", "blood")

WHITE = ("on a plain, flat, pure white background, the four well apart in a two by two grid, nothing "
         "touching the edges. " + factory.MAN_HAND + " Seen from straight above, flat on. No shadows "
         "cast, no text, no border, no frame, no hands, no people.")

# The image model's provider turns blood down as violence, the request and the picture both (run
# 100: splats, stains and pools refused; run 101: the stains painted as dye, splats and pools
# refused again). Splats and pools are painted as black ink and cut_blood.py colours them in the
# game's blood reds (blood_map.json "tint"): only their shapes matter.
SHEETS = {
    # Bloodstain pattern analysis: a drop that lands square is round with a scalloped rim and a few
    # satellite drops; one that lands at an angle draws out into a tail (James, Kish & Sutton).
    "splats": "Four separate splashes of black ink on paper: a round drop splash with a scalloped rim "
              "and a few tiny satellite droplets; a long splash from a drop that struck at a slant, "
              "with a tail; a small cluster of drops; a larger splash with a wavy edge. Thicker and "
              "darker in the middle, thinner at the edges. " + WHITE,
    "stains": "Four separate patches where thick dark crimson dye has soaked into cloth, each spreading "
              "out from a small hole through the weave, darkest and wettest round the hole, the soaked "
              "edge irregular and following the threads: two on pale linen shirting, one on brown wool, "
              "one on dark grey wool (where it shows as a darker wet patch). " + WHITE,
    "pool": "Four separate puddles of black ink, each a different size, irregular edges where it ran, "
            "darker in the middle and a thin rim at the edge. " + WHITE,
    # An entry is a small round hole in a ring of scraped skin (the abrasion collar); an exit has no
    # collar and is bigger and irregular, often split in a star with its edges turned out (DiMaio,
    # Gunshot Wounds). Run 100 painted the exit as a slash like the furrow.
    "wounds": "Four separate small wounds on weathered skin, each with a little skin round it: a small "
              "round bullet hole with a dark centre and a reddened, scraped ring round it; a larger "
              "exit hole, star-shaped and split open, ragged edges turned outward; a short torn furrow where a ball grazed the skin; a purple and yellow "
              "bruise. Painted, not gory. " + WHITE,
}


def main():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    if not key:
        print("No OPENROUTER_API_KEY: blood not painted.")
        return
    only = None
    budget = 3.0
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1] not in ("", "all"):
            only = a.split("=", 1)[1].split(",")
        elif a.startswith("--budget="):
            budget = float(a.split("=", 1)[1])
    repaint = "--repaint" in sys.argv
    os.makedirs(RAW, exist_ok=True)
    man = Image.open(factory.MAN).convert("RGB")
    man.thumbnail((768, 768))
    spent, dearest, failed = 0.0, 0.25, []
    for name, prompt in SHEETS.items():
        if only and name not in only:
            continue
        out = os.path.join(RAW, name + ".jpg")
        if os.path.exists(out) and not repaint:
            print("already painted:", name)
            continue
        img = None
        for attempt in range(2):
            if spent + dearest > budget:
                print("stopping: $%.2f spent of $%.2f" % (spent, budget))
                break
            try:
                img, cost = ask(prompt, [man], name, key)
                spent += cost
                dearest = max(dearest, cost)
                break
            except (RuntimeError, OSError, KeyError, ValueError) as e:
                print("failed (try %d):" % (attempt + 1), e)
        if img is None:
            failed.append(name)
            continue
        if max(img.size) > 1536:
            s = 1536 / max(img.size)
            img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
        img.save(out, "JPEG", quality=92)
        print("painted:", name, img.size)
    print("blood: $%.2f spent of $%.2f" % (spent, budget))
    if failed:
        print("not painted:", ", ".join(failed))


def ask(prompt, images, what, key):
    """The factory's call, with what it cost (the factory prints it; read back here for the budget)."""
    import io
    import contextlib
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        img = factory.ask(prompt, images, {"aspect_ratio": "1:1"}, what, key)
    said = buf.getvalue()
    print(said, end="", flush=True)
    cost = 0.0
    for line in said.splitlines():
        if "cost $" in line:
            try:
                cost = float(line.rsplit("$", 1)[1])
            except ValueError:
                cost = 0.3  # not said: reckon it dear
    return img, cost


if __name__ == "__main__":
    main()
