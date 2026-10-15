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

## Shared bodies, swappable heads (Sean, 2026-10-15: "option 2")

Skyrim's way: a few **base bodies** (average first, from the bold cowboy's pictures; lean and
heavyset later) and every **head cut to one standard neck ring**, so any head goes on any body
and clothes are made once per body type.

- **The neck ring:** a fixed loop round the neck, between the jaw and the collarbones, defined on
  the game's skeleton (`envelope.json`: the neck bone, a height above the shoulders and a section
  shape). Every base body is cut there; every head is cut there too and its last few centimetres
  pulled onto the ring (position and shape), so the seam closes with no gap or step.
  `rodin_portrait_build.py` already scales each head to the anatomy's eyes and trims its neck
  (`neck_cut` "smooth"); the ring makes that trim the same for everyone.
- **Skin at the seam:** each head's neck paint blended to the body's skin colour over the last
  2 cm; the body's skin tinted to the head's (`skin_from_paint`, already measured per man).
- **The body's head** (Rodin builds his body with a head on) is cut off at the ring; the bold
  cowboy's own head goes back on through the ring like anyone's, so the swap is tested on day one.
- **Clothes per body type:** each garment made once on a base body, sized to its shape; a man of
  that type wears it as is. A new body type gets the wardrobe refitted (`clothes.py` shapes from
  whatever body it's given).
- **A new man then needs:** head pictures (four plain, five portraits; Rodin bust $1.60) and a
  body type. His entry in `portrait.json` names his `body` ("average" ...).

## Steps and cost

1. Rodin builds the average body from the four plain pictures (People workflow, `style: rodin`;
   $1.60, total ~$6.86 of $15).
2. Fit it to the skeleton (a `fit_tripo.py` mode for an undressed Rodin body); define the neck
   ring; cut the body there; render it bare in the lab (`art_lab.gd`).
3. Heads through the ring: the bold cowboy's (both styles), then the older and young men's
   existing busts on the same body, as the proof that any head fits.
4. The coat: shaped on the average body, painted from the paintings; sheet. Then shirt, vest,
   trousers, boots.
5. Lean and heavyset bodies (two more Rodin bodies, $3.20, Sean's go) and the wardrobe refitted.
6. Each step on its own trial entry in `portrait.json`; nothing replaces the approved men until
   Sean says.

## Not in this brief

Changing the game's lighting (the art session's: faces' tones and saturation under its lamps,
measured in `character-style-fidelity.md`); women (their own base bodies, later); a wardrobe for
the town beyond the first outfit.

**Sean, 2026-10-15, on the painterly trial sheets** (`docs/style_test/painterly-2026-10-15/`):
"it's fucking mint - it needs a bit of fixing up but that's fucking it". The painterly style is the
direction: his paintings' brushwork kept (`patches` "none", `unsquare` 0), their light mostly kept
(`delight` 0.15), drawn with the game's own material (not self-lit). Bookmark:
`look/painterly-2026-10-15`.

**Paid calls:** 2026-10-15, Rodin Gen-2.5 (Extreme-High, 18K quads, HighPack, A-pose) on fal for
`bold_cowboy_body` from his four boxer-shorts pictures: $1.60 (the characters session's total
~$6.86 of the $15 Sean allowed).
2026-10-15, Rodin on fal for `bold_cowboy_dressed` (his four dressed pictures, whole, A-pose):
$1.60 (total ~$8.46 of $15). His clothes from it: what stands off the bare body, cut into coat,
trousers and boots (a quicker route to the coat's real shape than shelling the body).

**2026-10-15, the twin route (done; sheet `docs/style_test/layered-2026-10-15/c2_dressed.png`):**
his clothes are cut from Rodin's dressed model of him, not rebuilt as a shell (tried first: the
shell placed by landmarks came out scrambled, `fit_tripo` `as_shell`).
`tools/characters/twin_pieces.py` lays the dressed twin on the bare body (trimmed ICP; each sleeve
turned onto its arm by his hands, ~10°), keeps what stands off his skin below his chin (not his
hands, not his throat), pushes it out of his skin and splits coat from trousers by colour
(`assets/people/tripo/bold_cowboy_{coat,trousers}.glb` + a `.json` naming the body). `fit_tripo`
carries a twin piece as it is: warped with him, pushed out again after the warp
(`clear_twin`), weighted from the skin under it (`weights_from_skin`), and his skin tucked
under it (`tuck_skin`: Rodin's long faces cut through an arm's round otherwise). Painting the
twin from the dressed pictures failed (their dark glowing backdrop defeats `body_paint`'s
outline): Rodin's own colours, darker and more mottled than the paintings. Open: the coat's
colour; a light band at the nape (his twin's hair over the collar); specks of skin at the
shoulders; the game's holster outside the coat; vest and shirt are painted on the coat (one
layer: the coat off shows his bare chest).
