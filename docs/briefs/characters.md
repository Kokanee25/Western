# Brief: characters in layers (the characters session)

Sean, 2026-10-05: the characters session makes the people; every man is built in layers
(docs/DESTRUCTION_BRIEF.md part 5). This brief says what a layered man is, what the game
already expects from each layer, how the pieces are made and checked, and who comes first.
Written by the art session from the code as it stands; where the code and this disagree, the
code wins and this gets fixed.

## Goal

Every person in the game is a body with his clothes on it as separate pieces: each one can be
hidden, dropped or taken, a bullet holes the garment over the wound as well as the body, and a
hat can be shot off. Each looks like the paintings' men once the game lights him.

## What a layered man is

Inside to out. The **shape name** is the name the game already uses for that piece: each piece
is exported in the man's glb as `body_<shape>` (`fit_tripo.py`, `make_people.py`) and its
texture as `assets/people/<id>_<shape>.png`. Use these names; the game keys off them.

| Layer | Shape name(s) | Game's garment id (damage) | Covers (body parts) | Notes |
|---|---|---|---|---|
| Body | `skin`, `head` | — | all | The whole body, complete under every garment (a coat can come off and a wound can open anywhere), bare-headed. Hands and fingers are the game's own parts: cut at the knuckles. |
| Hair | `hair` | — | head | Its own shell, so a hat can come off over it. Drawn from both sides. |
| Undershirt | (the body's texture today) | `long_johns` (0.5 J) | torso, arms, legs, pelvis | The game counts it; it need not be its own mesh. Painting the body in long johns rather than bare skin is the period answer and spares any nudity question. |
| Shirt | `shirt` | `shirt` (1 J) | chest, abdomen, arms | Complete, collar and cuffs included, so it reads with the vest or coat off. |
| Trousers | `trousers` | `trousers` (2 J) | pelvis, thighs, shins | |
| Vest | `vest` | `vest` (3 J) | chest, abdomen | Open at the front (a V); drawn from both sides. |
| Coat | `coat` | `coat` (6 J) | chest, abdomen, arms, pelvis, thighs | Skirt hung from the hips, never the thighs (it stretches into a flap when he sits). Open front, lapels, collar. Drawn from both sides. |
| Tie or bandana | `cravat` / `bandana` | — | neck | A man with a tie doesn't also get the lofted bandana. |
| Boots | `boots` | `boots` (15 J) | feet | Measured from the mesh, not Tripo's toe joint (it sits 4 cm before the ankle). |
| Belts | `gun_belt`, `belt`, `holster` | — | pelvis | The holster is where gameplay's draw starts: keep it on his right hip where BodyMesh puts it. |
| Hat | `hat` (or `hat_brim` + `hat_band`) | — | head | Gameplay builds the hat's hitbox from the hat pieces' bounds (`HumanBody._hat_box`) and throws exactly those meshes when it's shot off, so the hat must be only hat. Brim onto the head's band (`HAT_BAND`). |

Per man, a garment he doesn't wear is just absent (Lyle and the Kid have no coat; the
storekeeper and barkeep have a vest and no hat). `people.json`'s `outfit` turns pieces on and
off; `PeopleBodies.OUTFIT_KEYS` are the ones it may turn off.

## What every piece must do

- **Fit in every pose, not just standing.** Stand, sit and `sit_lean` (the card table), hands
  up, crouch, prone, cower, drag, and the ragdoll: no layer pokes through the one outside it,
  and none floats off the body. The skinning is the body's own tables (`Person.weights`); a
  piece inherits the weights of the body under it.
- **Clear the layer under it** by a set margin after decimation (the MakeHuman route's
  `clothes.py` `separate()` does this; the Tripo route needs the same).
- **Be cut per body part**, as every shape is (`PeopleBodies` and `BodyMesh.split_pieces`), so
  wound openings land on the piece over the wound. Its UVs and a rest position per vertex come
  through as they do now.
- **Its own texture**, painted in **flat, even light** (no lamp, no cast shadow, no baked
  ambient occlusion: the game lights him), smooth at about 1024² for a coat, less for small
  pieces (the screen mosaic makes the squares; see A1 in CLAUDE.md). The cloth drawn as cloth:
  a tweed check, a vest's pattern, stitching, wear at the elbows and knees.
- **A triangle budget** so a man stays within the frame budget (CLAUDE.md, People row): today
  body 5,500, head 2,200, coat 2,600, hat 700; the others to be set by the first man.
- **Open garments drawn from both sides** (`HumanBody.DOUBLE_SIDED`): vest, coat, brim, band,
  hair, belts, bandana, tie, shirt, trousers.

## How a piece is made

Two routes; pick per man.

1. **Tripo** (the principal characters: the stranger, the gang, the sheriff): the body painted
   bare-headed in long johns (or shirt and trousers until the layer below works), and each
   garment painted alone as a ghost-mannequin picture and modelled as an unrigged item; the fit
   places and warps each piece onto the body (`Piece.place`, `warp_points`). The hat works this
   way (`stranger_layered`). **The coat doesn't yet:** a Tripo garment is a double shell sized for
   an average man, and no landmark fit put it cleanly over a broad body. The route to try next
   (CLAUDE.md, "Layers"): build the coat as an offset shell of his own body, then bake the Tripo
   coat's colour onto it (per vertex from the nearest coat point at full resolution, unwrapped and
   baked to its own texture, then decimated).
2. **MakeHuman** (`make_people.py` + `clothes.py`; the townsfolk and extras): the garments are
   shells over the fitted body by construction, already layered, with draped coat skirts. Cheap
   and certain; their look is the weaker part (textures from the bake, faces code-painted).

**A wardrobe, not a coat per man.** A garment fitted by construction (an offset shell of the
body, coloured from a painted garment) can be fitted to any body. Keep the painted garments as a
wardrobe (`characters.json` items: frock coat, duster, sack coat, vests, shirts, hats) and dress
each man from it with his own colours, so a new townsman costs a fit, not three Tripo runs.

## Who, in order

From the code today (`src/people/town_life.gd`, `src/art/street_dressing.gd` FOLK,
`src/art/shot_match.gd` EXTRAS):

1. **The stranger** (the saloon shot's seated man): finish him in layers (body, shirt, vest,
   trousers, coat, boots, gun belt, hat, hair) so `stranger_layered` replaces the whole
   `stranger` in the shot. The art session judges him in the saloon shot; he's done when the
   layered man scores no worse than the whole one (judge v2 0.231 on 2026-10-05_r1) and the
   critic's "his face is an orange smear" point is answered.
2. **The gang**, the men you fight: **Brody** (leader, cool; dark coat, buff shirt, near-black
   hat), **Lyle** (hothead; rust-red shirt, no coat, tan hat), **the Kid** (19, nervous; pale
   grey shirt, no coat, pale hat). Each needs every layer, the hat above all (it gets shot off).
3. **The storekeeper and the barkeep** (no hat; shirt and vest, sleeves rolled for the barkeep).
4. **The townsfolk and the saloon's extras** from the wardrobe, MakeHuman bodies or Tripo bodies.

## Spending

Ask Sean before any training run. Give the cost of each man before Tripo is paid: a layered
Tripo man is a body plus one Tripo item per garment painted for him (about $1–1.50 each) plus
the paintings (~$0.15 a set on fal), so $4–8 a man until the wardrobe carries the garments.

## How it's judged

- **The pose check:** each new man rendered in the character lab (`tools/character_lab.gd
  --model=<id>`) standing, sitting at the table, hands up and crouched, from the front, side and
  back. A test in `tests/test_bodies.gd` (gameplay's file: ask, or have them add it) should
  measure poke-through: no vertex of an inner layer outside its outer layer by more than a few
  millimetres in those poses.
- **The game's own tests** keep passing: the hat test (`test_hat`: shot off, flies, he's
  frightened), wounds through clothes (`test_openings`), the layered man's hat
  (`test_bodies::test_the_layered_man_wears_his_own_hat`).
- **In the shots:** the art session renders him in the judge's saloon shot (and the street's,
  once he stands there), judges him with judge v2 and the blind critic, and says what's off.

## Done when

- The stranger is layered in full and is the shot's seated man, scoring no worse than today.
- The gang are layered men in the game; shooting a hat off any of them works; taking a coat off
  (gameplay's call when) leaves a dressed man underneath.
- New townsmen come from the wardrobe at a fit's cost.

## Open questions for Sean

- The body under the clothes: long johns (period, simple) or bare skin?
- A wardrobe shared between men (cheaper, consistent) or every garment painted for its man?
- Who goes after the gang: the sheriff (the story's opening) or the storekeeper and barkeep?
