# The blood marks painted (Sean, 2026-10-21: "do the free part and paid part, take $3")

**Spent $0.95 of the $3** on four People-workflow runs (`textures = blood`, `tools/textures/paint_blood.py`):

| Run | Sheet | Cost | What came back |
|---|---|---|---|
| 100 | wounds | $0.19 | painted; splats, stains and pools refused as violence |
| 101 | stains (asked as dye) | $0.19 | painted on swatches of cloth; splats and pools refused again |
| 102 | splats, pools (asked as black ink) | $0.38 | painted |
| 103 | wounds again | $0.19 | the exit wound a split star, not a slash like the furrow |

- **The refusals:** the image model's provider turns down blood, both the request and the picture.
  Only the shapes matter, so splats and pools are painted as black ink and `cut_blood.py`
  colours them in the game's blood reds from their darkness (`blood_map.json` "tint"). Stains are
  asked for as crimson dye soaking into cloth and keyed by redness, so the cloth drops out.
- **The cutter** (`tools/textures/cut_blood.py`, no calls) turns each sheet of four into
  `assets/textures/blood/<key>.png`, which `PixelArt.blood` loads before its drawn fallback:
  - the white keyed out and un-mixed from the soft edges;
  - the pools' painted outline opened away (it read as a pale ring);
  - each stain cropped to where its mass is, not to its stray threads (those had left the patch
    covering a twentieth of its decal, so a 27 cm soak showed as a 6 cm dot);
  - the hole the model painted pale filled wet, and a wet soak laid under each.
  - The brown-wool and grey-wool stains didn't key clean, so they are the other two turned over.
- **The shapes follow the sources in `../2026-10-21_blood_look/`.**
  - A drop landing square is round with a scalloped rim and satellites; one landing at a slant
    draws out into a tail (James, Kish & Sutton).
  - An entry wound is a small hole in a ring of scraped skin; an exit wound is bigger and
    irregular, often split into a star with its edges turned out (DiMaio, *Gunshot Wounds*).

**In the game** (`marks_and_soak.jpg`):
- Top: the sixteen marks on a sand ground.
- Below: the rancher shot from 5 m in the neck, upper arm and belly (the lab's new
  `soak_<spot>` scenarios: his bleeding run 20× fast). On the left is the hit at 0.15 s, on the
  right a minute of bleeding.
- A stain now starts the size of the hole and soaks out over a minute or so
  (`HumanBody.STAIN_WICK`). As it grows it runs down from the hole (`STAIN_RUN`): a neck wound's
  soak used to climb onto his jaw. His hand on the wound comes away bloody.

**Not yet:**
- On dark wool trousers the stain hardly shows. That's true to life, but it reads as nothing.
- The pool under a man and the splats are seen from the street, so they want judging in the
  saloon's and the street's light, not the lab's grey.
- Sean's call: the stains used to be big at once (the pre-paint look). Now they take a minute to
  spread, as blood does.
