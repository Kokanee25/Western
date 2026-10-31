# The character bake-off, route B: MPFB (issue #505)

**Sean's verdict (2026-10-31): "he sucks... that was terrible". Not the direction. Human Generator
is next** (route C, then A, the Studio from realistic pictures). What stays useful from this: the
body. MakeHuman's mesh bent better than the Studio man's (both arms up 496 against 917 cm²), it
costs nothing and a man builds in 32 s, every man shares one UV layout, and the talking face's
expressions are MakeHuman's own: a candidate *base* under a better head, not a route for faces.

Why he looks this bad (near MakeHuman's floor, and its ceiling isn't much higher for faces): the
face gets ~400 px of MakeHuman's 2048 skin and the game ignores the normal maps (smooth, plastic,
young); hair, brows and lashes flattened into the skin (the game draws no alpha cards); MPFB's
skin material not used (a Blender node tree, and its code wasn't run); the system kit's modern
clothes; an hour's tuning. Done properly it reaches a competent background extra; every face
comes from one base moved by sliders, so none has the character Sean wants.

Sean, 2026-10-31: find the route that makes men he actually likes; realistic is fine, the concept
painting's squares can go. Route B is MPFB (MakeHuman for Blender), free. Same brief for every
route: a weathered man of about 40, stubble, a hat, period clothes, on the game's 17 bones, shot
beside the current Studio man (`bold_cowboy_s3_talking`).

**Sheets:** `poses.jpg` (the pose check, MPFB over Studio; taken before the trousers' regrade, so
his jeans' pale fades still show there), `shots.jpg` (the step-4 shots), `faces.jpg` (faces close,
and the second man). Remade by `make_sheets.py` from the renders in `build/`. Not made (stopped at
Sean's verdict): the card table's close view and the Studio man's table renders, the one-arm-high
pose, the frame-time and draw-call numbers.

## What was made

`mpfb_drifter` (and `mpfb_teamster`, the timing test), by `tools/blender/mpfb_man.py` from
`assets/people/mpfb_men.json`; data fetched by `tools/blender/fetch_mpfb.py` into `build/mpfb/`.

- **Body:** MPFB's base mesh (MakeHuman's hm08) with MPFB's macro targets mixed as its `macro.json`
  lays them out (male, ~40, a little muscular, lean), plus ten face targets from MPFB's library
  (square head, cheekbones up, cheeks hollowed, chin wider, a hump in the nose, `head-age`).
- **Rig:** MPFB's `game_engine` rig (53 bones) on the joints its rig file names, with MPFB's own
  weights. Posed onto our skeleton's rest (arms down) by that rig: each limb bone turned and
  stretched from MPFB's joints to ours, the trunk scaled to our height (×0.99), blended by MPFB's
  weights. Then summed into our 17 bones (clavicles to the chest, fingers to the hand), with the
  neck re-blended to our joints (MPFB's head bone is at the skull's base, 1.65 m; ours pivots at
  1.56).
- **Assets:** MakeHuman's CC0 system kit: skin `middleage_caucasian_male`, brown high-poly eyes
  (the see-through cornea shells dropped: the game draws no see-through skin), the striped work
  shirt and trousers (`male_casualsuit03`; the jeans regraded to brown canvas, the stripes toned
  down), black boots to brown leather (`shoes03`), the fedora with its brim pushed out 45% and its
  crown raised, dark brown. Each placed by its `.mhclo` binding and weighted through it; what the
  clothes hide of his body deleted. Hair and brows are alpha cards, which the game's skin shader
  doesn't draw, so they're painted into his skin texture through their bindings.
- **Finish:** MakeHuman's own albedo, no squares, no light painted in. Stubble (a soft shadow and
  faint hairs) and sun on face, neck and hands, laid by where they are on him. Textures with
  mipmaps (his own `.import` files), so the game's sharp texels don't sparkle at a distance.
- **No shader or game change.** The game draws him as a "whole" man through `PeopleBodies`, like
  the Studio men; the wounds cut through his skin and clothes by the same shader.

**MPFB's own code was not run.** Running the downloaded add-on was refused in this session (the
session won't execute code fetched from outside). Everything MPFB *is* for this job is data (CC0):
the base mesh, the targets and how macros mix them, the rig, its weights, the asset bindings;
`mpfb_man.py` reads those itself (fresh code, nothing copied). What that leaves out of "MPFB done
properly": its procedural skin and eye materials (Blender node trees; they'd have to be baked to
textures for Godot anyway), its asset browser and sliders (a person at a PC), and its hair-card and
cloth tools. Sean can allow MPFB to run in a later session if he wants those.

## The pose check (`poses.jpg`; `tools/characters/works_check.gd`, `arm_poses.gd`)

Stretched-sheet area (cm², the works check's measure: triangles stretched past 2.5× between parts):

| pose | MPFB man | Studio man | |
|---|---|---|---|
| stand, walk, run | 0 | 0 | |
| aim | 56 (pass) | 2 | the shirt between chest and right upper arm |
| crouch | 89 (fail) | 0 | the trousers behind the left knee, the seat |
| seated | 78 (fail) | 0 | the same: trousers at the knee and seat |
| both arms up | 496 (fail) | 917 (fail) | every Studio man fails this (PLAYBOOK §6) |
| lying dead (ragdoll) | 0 | 4 | |
| hat off when he goes down | yes | no | |

What it means: the MPFB man's **body** bends cleanly (MPFB's weights are made for this mesh: no
collapsed elbows or knees, no candy-wrapping at the wrists). The sheets are in his **clothes**:
MakeHuman's garments take their weights from the body under them, and a tight trouser leg folded
90° at the knee pulls a few triangles across the fold. A raised arm stretches the shirt's side
less than the Studio man's (496 against 917 cm²). Fix if this route is chosen: a garment's weights
smoothed at the knee and hip (a pass over its own mesh), or MPFB's corrective shape keys baked
for the bent poses.

## The shots (`shots.jpg`)

Taken in the game's own render (lavapipe, no real GPU): the saloon by lamplight at 21:30 from 1.6 m
and across the room (5.6 m, the men swapped); the card table from the player's seat
(`screenshots.gd --only=shot_match_saloon --model=mpfb_drifter`; ~20 min a view under lavapipe); the street at golden hour (1.7 m, 5.8 m) and noon;
shot standing (arm and thigh: the hole, blood on the sleeve, blood running) and down (ragdoll).
At the table he sits in ShotMatch's fallback pose (`sit_lean`, the stranger's): it has no fit for
him (adding one is the art session's file).

The bridge's `body_shoot` sometimes hits "bench_man_b" in the line of fire, not the man (seen on
the MPFB man; not his model's doing).

## Talking

Not made. His face is MakeHuman's own face, so the talking face would need no graft: the 20
expressions the Studio men get (`tools/faces/talking_face.py`) are MakeHuman's own face pose
units (CREDITS), made for this mesh. It would take baking those units as blend shapes onto his
head (a step in `mpfb_man.py`, about half a day), no landmarks, no edge pin, no stitch.

## Cost

| | MPFB man | Studio man (bold_cowboy_s3_talking) |
|---|---|---|
| triangles | 26,724 (skin 15,492, eyes 1,060, shirt and trousers 4,800, boots 4,128, hat 1,244) | 34,182 (skin 28,063, head 6,119) + bandanas, hands |
| draw calls (whole) | 5 (skin, eyes, clothes, boots, hat) | 2 + bandana + hands (not counted) |
| textures | 3 × 2048² (skin, clothes, hat) + 1024² eyes + 1024² boots | 2048² skin + 3072×2048 head + bandanas |
| headless frame | not measured (stopped) | not measured |
| money | $0 | $1.60 Rodin a man, plus pictures |

## Making one more man (timed)

`mpfb_teamster` (older, heavier, canvas bib overalls, grey hair): a new entry in
`mpfb_men.json` (~5 minutes, mostly choosing assets and colours), then **32 s** to build
(`mpfb_man.py --only=mpfb_teamster`), ~2 min to import, ~2 min for the works check. One parser
fix was needed on the way (a hair file names its material after its vertex list).

**Manual (by eye):** choosing the clothes, boots, hat, hair and brows from the kit; their colours
(the retint rules); the targets for his face; checking the preview. **Automatic:** everything else
(shape, rig, fit, weights, textures, export).

## What's rough, and what every man this way would take

- **The clothes are the limit.** MakeHuman's kit is modern: casual suits, jeans, a printed T-shirt
  (the teamster's shows its logo), sneakers, a fedora. Regrading colours gets so far; period
  garments (a collarless shirt, a sack coat, waistcoat, braces, a wide-brimmed hat, boots) would
  have to be modelled once (MPFB's cloth tools or by hand in Blender, ~a day each) and then fit
  every man for free. The community's CC0 packs (`crude_kit_CC0`) were not tried.
- **Faces are generic.** Targets move the face only so far; the face texture is MakeHuman's (the
  face is ~400 px across in its 2048 skin), smooth and young beside the Studio man's painted
  likeness. Every man shares one UV layout, so a better skin (painted or generated once) carries to
  all.
- **Stubble and weather** are laid by heights on this head (`mpfb_man.py`); a second head shape
  moves them (the teamster's stubble is faint).
- **Fingers** ride the hand (not separate, can't be shot off) until the Studio's skinned hands
  are run on him.
- **His eyes sit ~3 cm above our anatomy's** (1.687 m against 1.655): the face's hitboxes are a
  little low for him.
