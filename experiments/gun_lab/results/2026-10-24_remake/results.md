# The guns remade and the arms painted (2026-10-24, docs/briefs/gun-remake.md)

Sean, 2026-10-23: "remake the shot gun and handgun so they look and match the art style - if you
need paid art rounds those are approved for $3"; then "go with blender" and "paint the arms".
Measured against `../2026-10-23_hands/` (the hands round). Sheets in `sheets/` (`run.py --job=fp`).

## What changed

- **Both guns rebuilt in Blender** (`blender/guns_blender.py`, from each gun's parts as code
  draws them, `views.gd --side`): bevelled, smoothed, every moving part its own mesh, the side
  painting (run 117) baked on through one 2048 texture a gun (`assets/weapons/<gun>.glb`,
  `<gun>_paint.png`; `GunParts.blender_meshes` lays them on the code's parts). Each point samples
  the painting most of its part's half thickness inside; tops take it smeared along the gun and
  darkened; the walnut's oranges browned. The guns cast no shadow (the sun's shadow map at a
  gun's size striped their tops) and are matte (a shiny top mirrored the sun). A painting from
  above (run 118) came back as the side again: not used.
- **The coach gun**: a pistol grip (as the Colt 1878 and Remington 1882 hammer doubles), the
  standard first-person view and aim down the sights.
- **The arms painted** (`blender/arm_blender.py`): Sean's man's arm from four sides as one sheet,
  repainted in the men's hand (run 119, $0.22), softened (its hairs read as veins: a median, the
  colour half way to his own), baked back onto both arms through his UVs (each texel from the
  views facing it, a depth test a view): `assets/weapons/held_arm_skin.png`. His mesh is split at
  nearly every triangle: the held arm's normals are now averaged a point (no facets).

## The blind judge

A fresh sub-agent given only `docs/concept/targets/9_studio_men.png` and four pairs of sheets (old
`../2026-10-23_hands/sheets/`, new here) labelled A/B at random: the new chosen in all four pairs;
the new guns and arms CLOSE in every sheet, the old DIFFERENT ("faceted low-poly arm", "a crate-like
stock", "a grey-tan mottle"). Its first fault (looking down the coach gun the stock's top read
salmon, the skin's colour) fixed after (tops darker, matte). Left: the forearm's stepped light (the
men's skin shader's, art's), the sleeve without folds, the revolver's reload covering the hand.

## The hold

Sean, on the films: "that shotgun hold still looks like shit". The hold is still computed
(`HeldHand`'s fit and IK); the next step replaces it with a rig posed by eye
(`docs/briefs/viewmodel-rig.md`), against the references gathered here:
`docs/concept/guns/ref/SOURCES.md` (13 first-person holds in public GitHub repos, links only) and
three game frames with only the hands repainted holding the guns right
(`assets/textures/guns/hold_game_{hip,aim,rev}.jpg`, Nano Banana Pro). OpenAI's image model
refused or errored (runs 120, 121).

## Cost

Of Sean's $3: gun paintings $0.88 (runs 117, 118), the arm $0.22 (119), refused holds $0.17
(120), drawn holds $0.42 (122), game-frame holds $0.42 (123): $2.11, $0.89 left. Earlier, the metals $0.88 of
#249's $0.90.
