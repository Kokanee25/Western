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
    # Gore, by Google's Gemini (gore_test.py, run 104: FLUX.2 refuses it, Gemini painted it with the
    # anatomy right). A limb in section: skin, the yellow fat under it, the muscle bellies in their
    # pale sheaths round the bone, the marrow in the bone (Gray's Anatomy, cross-sections of the
    # limbs); a forearm and a shin each have two bones side by side.
    "stumps": "Four separate cross-sections of a man's limbs where they were torn off by a gunshot or a "
              "blast, for a gritty frontier Western game, frank and bloody. Each seen exactly end-on, the "
              "cut face filling a round shape, none of the limb's length showing: an upper arm, one white "
              "bone with dark red marrow in the middle, red muscle bellies in thin pale sheaths round it, "
              "a yellow layer of fat and a rim of weathered skin, ragged and bleeding at the edge; a thigh, "
              "bigger, a thick bone and more muscle; a forearm, two bones side by side; a limb torn by a "
              "blast, the bone splintered and sticking out, the muscle shredded, the skin torn in ragged "
              "flaps. Wet, glistening, blood pooling on the faces. " + WHITE,
    "gore": "Four separate large gunshot and blast wounds on weathered skin, for a gritty frontier Western "
            "game, frank and bloody, each only the wound and a hand's width of skin round it, the skin "
            "fading out to white at the edge: a shotgun wound from a few feet, one ragged crater torn "
            "through the skin, raw red flesh inside, blood running from it; an exit wound, the skin burst "
            "outward in torn flaps round a dark bloody hole; a blast wound, skin torn open and peppered "
            "round it with small bleeding wounds from flying gravel; a long gash torn open to the red "
            "muscle, blood welling. Seen straight on, flat. " + WHITE,
    # The gore lab's second round (docs/briefs/gore-lab.md). A near shot with black powder leaves
    # soot and a tattoo of burnt grains round the hole (DiMaio); a burn goes red, blisters, chars.
    "marks2": "Four separate marks for a gritty frontier Western game, frank and bloody: a small bullet "
              "hole on weathered skin with a sooty black ring round it and a wide peppering of tiny dark "
              "burnt powder grains tattooed into the skin around that; a bloody handprint, a whole palm "
              "and fingers pressed flat in wet blood; a long smear of blood where a bleeding body was "
              "dragged, streaked along its length; a burn on skin, an angry red patch with blisters and "
              "charred black edges. Each seen straight on, flat. " + WHITE,
    # The doctor's work and after: a flap amputation closed over the bone with stitches (the
    # Medical and Surgical History), a healed bullet scar, a wound gone bad.
    "aftercare": "Four separate studies for a gritty frontier Western game: the end of an amputated "
                 "limb seen exactly end-on, a round stump closed with a flap of skin and a line of dark "
                 "surgical stitches across it, bruised and a little bloody; a healed bullet scar on "
                 "weathered skin, a pale pink puckered round scar; an infected bullet wound, red and "
                 "swollen, yellow pus, dark dead edges; blood that has run from a man's ear in thin "
                 "trickles down his skin. Each seen straight on, flat. " + WHITE,
    "cloth": "Four square swatches of cloth for a frontier Western game, each filling its whole quarter "
             "of the picture edge to edge, seen flat, the four in a two by two grid with a thin gap: "
             "off-white linen bandage, a loose weave; the same bandage soaked through with dark blood "
             "in the middle; faded red cotton kerchief cloth; cloth burnt black and brown, charred and "
             "holed. " + factory.MAN_HAND + " No text, no border.",
    # Run 108 painted the sewn stump at a slant; here it's asked as a coin, flat on.
    "aftercare2": "Four separate studies for a gritty frontier Western game: the end of an amputated "
                  "arm seen exactly end-on like a coin, filling a circle, a round flap of skin closed "
                  "over it with a line of dark surgical stitches straight across the middle, bruised, a "
                  "little dried blood, none of the arm's length showing; a small scorched hole burnt "
                  "through a shirt by a gun fired close, a ring of black soot and singed threads round "
                  "it; a long thin pale healed knife scar on weathered skin; a wound gone to gangrene, "
                  "black and green dead flesh, wet, the skin round it dusky purple. Each seen straight "
                  "on, flat. " + WHITE,
    # An ear or the nose shot off and the jaw shot away (HumanBody.shoot_off, jaw_away): the
    # Medical and Surgical History's face wounds, the soft parts torn away, the bone and the dark
    # of the passages showing. Each with a little skin round it for the cut's skin key.
    "face": "Four separate studies of gunshot wounds to a man's face for a gritty frontier Western "
            "game, frank and bloody, each only the wound and a hand's width of weathered skin round "
            "it, the skin fading out to white at the edge, no eyes in any of them: the side of a head "
            "where the ear was shot off, a ragged red stump of torn ear at the ear hole, raw flesh, "
            "blood running down from it, a little dark hair above; the middle of a face where the "
            "nose was torn away, a raw red wound between the cheeks with the two dark openings of the "
            "nose in it, ragged edges, blood running down over the upper lip; the lower face where a "
            "blast carried away the jaw, a raw red ruin below the upper lip, broken teeth in the upper "
            "gum, torn flesh, blood pouring down; a man's ear torn off, lying flat on its side, its "
            "torn edge ragged and bloody. Each seen straight on, flat. " + WHITE,
}

# The model each sheet is painted with, where it isn't the texture factory's.
GEMINI = "google/gemini-3-pro-image-preview"
MODELS = {"stumps": GEMINI, "gore": GEMINI, "marks2": GEMINI, "aftercare": GEMINI, "cloth": GEMINI,
          "aftercare2": GEMINI, "face": GEMINI}


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
    default_model = factory.MODEL
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
                factory.MODEL = MODELS.get(name, default_model)
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
