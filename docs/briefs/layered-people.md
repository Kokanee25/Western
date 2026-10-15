# Brief: layered people (a body in underwear, his head, clothes over it)

Characters session, from 2026-10-15. Sean: "why aren't we just starting with the body next so it
all fits"; "if we're going Skyrim are we doing clothes on or in underwear" → underwear, clothes
as separate pieces; "just plain cream old looking boxer shorts". A trial beside the approved route (`tools/characters/RECIPE.md`), not in
place of it until Sean says.

## Why

The approved man is a Rodin bust stuck on the factory's MakeHuman body: the joins are what look
worst (a band of bare neck, a hard line where his head meets the body, the vest's collar in
spikes, no coat). Sean's second style (painterly, `docs/concept/style/portrait-painterly-*`,
trial `bold_cowboy_painterly`, sheets `docs/style_test/painterly-2026-10-15/`) shows it most.
Clothes baked into one mesh would hide the joins but cost what the game is built on: a ball goes
through coat, vest and shirt, each holed and bloodied (`HumanBody` garments); a hat is shot off,
a coat taken, a shirt opened to tend a wound; and one coat should dress every man in town.

## What to build

1. **His body, in plain old cream boxer shorts** (bare chest, arms and legs), from four plain pictures: Rodin ($1.60)
   builds it whole, head included, so neck and head fit by construction. Fitted to the game's
   skeleton and hitboxes as `tools/blender/fit_tripo.py` fits a whole man (warp limb by limb to
   `envelope.json`, eyes onto the anatomy's, skinned to our 17 bones, fingers off), but not
   "whole": he comes undressed.
2. **His face and hair** painted from his five head-and-shoulders portraits as now
   (`rodin_portrait.py paint`: `shape_fit`, relief, `keep_features`; for the painterly style
   `patches` "none", `unsquare` 0, `delight` low). His body's skin from the full-figure paintings.
3. **Clothes as separate pieces**, one at a time, the coat first (collar, lapels, the skirt over
   his legs: the hard parts). Each made to the base body's shape so it fits any man built on the
   same skeleton: `tools/blender/clothes.py` already shells a body, raises a collar, cuts lapels,
   drapes a skirt (cloth sim), bakes a texture; it works on MakeHuman's person and wants to work
   on any body mesh. Painted from the full-figure paintings by the same projection as his face
   (`rodin_portrait.py`'s view choice and de-light), not baked cloth noise. Layered in the order
   the game expects (shirt, vest, coat; trousers, boots), each its own mesh and texture, so
   `HumanBody`'s garments, holes and blood keep working.
4. A **hat** stays its own piece (`style_hat.py`, designed paint), as on the bold cowboy now.

## What Sean makes (ChatGPT)

- **Shape:** four plain pictures, full figure head to bare feet, in plain cream, old-looking
  boxer shorts and nothing else, bare-headed, standing upright, arms a little away from his sides, feet
  a little apart; front, facing the picture's left, facing its right, from behind; plain grey
  ground, flat even light; square.
- **Paint:** the same four views dressed (long brown wool coat, dark vest, white shirt with a high
  collar, black tie, dark trousers, brown boots), full figure, in the painterly style, the same
  saloon light; the plain pictures attached so he matches. His five head-and-shoulders paintings
  already exist.

## Done looks like

The bold cowboy (painterly) built this way: no seam or gap at his neck from any side; collar,
tie and lapels where the paintings put them; his coat hanging over his legs and moving with
them; the coat comes off (the game's coat colour alpha 0) and his vest and shirt are whole under
it; shot through the chest, holes in coat, vest and shirt in line; all from five sides at 1.2 m,
in warm and neutral light and in the saloon. Tests: `test_bodies` (eyes within 1.5 cm of the
anatomy's), the people and wound tests. Inside the people frame budget (triangles about the
factory man's: skin 5k, head 12k, coat 2.2k).

## How it's judged

Sean's eye on sheets beside his paintings (`fidelity_compare.py` numbers alongside: tones,
lightness, contrast, chroma, block size). The art session judges him in the shots.

## Steps and cost

1. Rodin builds his body from the four plain pictures (People workflow, `style: rodin`;
   $1.60, total ~$6.86 of $15).
2. Fit it to the skeleton (a `fit_tripo.py` mode for an undressed Rodin body); render him bare in
   the lab (`art_lab.gd`).
3. His head painted onto it (the projection on the whole body's head).
4. The coat: shaped on his body, painted from the paintings; sheet. Then shirt, vest, trousers.
5. Each step on its own trial entry in `portrait.json`; nothing replaces the approved men until
   Sean says.

## Not in this brief

Changing the game's lighting (the art session's: faces' tones and saturation under its lamps,
measured in `character-style-fidelity.md`); the other two men; women; a wardrobe for the town.
