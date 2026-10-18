# Brief: garments (a shirt with a collar, a waistcoat and trousers, each its own clean mesh)

Characters session, from 2026-10-18. Sean, 2026-10-18: proper garments in place of clothes cut
from Rodin's dressed twin; brief first, his OK before building. Builds on
`docs/briefs/layered-people.md` (the base body, the neck ring, clothes as layers) and the recipe
`tools/characters/LAYERED.md`. **Status: draft for Sean's OK; nothing built yet.**

## Why

Today his shirt, waistcoat and trousers are cut out of one Rodin model of the whole dressed man
(`twin_pieces.py`). Rodin makes one fused shell: the sleeve joined to the shirt's side, the collar
joined to the neck, the waistcoat's armhole and the sleeve's root one surface. Two defects come
from that and have been patched for a week without being fixed (LAYERED.md §4, "defects by
cause"):

- **the white smear** between his arms and his body: the shirt's side and sleeve are one skin, so
  cutting the sleeve free leaves a comb of strips, or shirt where the waistcoat should be;
- **the collar**: Rodin's twin has no collar above the neck ring, so every attempt to raise one
  (a built band, a lift, a smooth) came out as a flat band, a neck brace or ragged slivers. Sean
  turned the band down twice.

And every new twin needs the recipe retuned (the arms-out twin, run 89, fixed the arms at the
source and still left shirt and skin out past the waistcoat), so no new man can be dressed yet.

## Goal

A **shirt** (a collar that stands round his neck with its points either side of the tie knot, the
tie, separate sleeves that end past his wrist cut), a **waistcoat** (lapels, a V, a pointed hem,
armholes clear of the sleeves) and **trousers**, each its own clean mesh with its own texture,
shaped to a man's base body, painted from his pictures, and reusable: one wardrobe fits every
man built on the average body, and a new body type gets it refitted by script. The coat the same
way after them (its sleeves apart from its sides by construction, which ends "the wing"). The
game sees no change: `people.json` `pieces` as now, `HumanBody`'s garments, holes and blood.

## References

- His pictures (`docs/concept/style/factory/`): **`bold_cowboy_armsout_dressed/`** (no coat, arms
  held out, the collar standing: the set to paint from), `bold_cowboy_vest_dressed/` (no coat, the
  old set), `bold_cowboy_dressed/` (the coat). The collar in the arms-out front picture: a
  turned-down collar standing off his neck, its two points lying over the waistcoat's lapels
  either side of a loose black tie knot, the shirt's neckband showing between them. The
  waistcoat: notched lapels, five buttons, two welt pockets, a pointed hem below his belt.
- Sean's words: the flat collar band turned down twice (2026-10-16, 2026-10-17: "a flat straight
  piece"); "the arm and body meshing together"; "a little blockiness in the cloth is fine".
- The look: painted illustration with a bit of square (DESIGN.md §4), like his face.
- Today's man, for before/after: `docs/style_test/layered-2026-10-15/d17_take2.png`.

## Measured before choosing

- Pose: the base body (`bold_cowboy_body_rodin`) holds his arms **9.4°** from vertical; the
  arms-out twin 10.3°; the old coatless twin 4.4-5.1°, the coated 5.7°. So garments shaped on
  the base body stand as the arms-out pictures show him, and paint by projection should line up
  better than the old set's 0.82 (`body_paint.py` lines a picture up by the figure's outline).
- Today's pieces (cut from the twin): shirt 6,100 triangles, waistcoat 4,337, trousers 14,057,
  coat 20,095, before the fitter's budgets (shirt 5,000, vest 4,337, trousers 7,999 on
  `bold_cowboy_vest_body`). A made garment needs far fewer for a cleaner shape.
- `tools/blender/clothes.py` already shells a MakeHuman person into shirt, trousers, vest and
  coat with a stand collar (`_collar`), collar points (`_collar_points`), lapels, a draped skirt
  and a string tie; it was retired (2026-10-07) for its blotchy baked textures, not its shapes.
  `fit_tripo.Piece.as_shell` (a body shell wearing the Tripo coat's UVs) was the scrambled one:
  the scramble was the borrowed UVs, not the shell.

## The options

### (a) MakeHuman's own clothes

MakeHuman's **system assets** (`makehumancommunity/makehuman-assets`, the clothes MakeHuman 1.x
ships: suits, shoes, a few shirts and trousers) are CC0 like the base mesh we already fetch
(`tools/blender/fetch_makehuman.py`). Each garment is an `.obj` with an `.mhclo` file binding
every garment vertex to three base-mesh vertices with weights and an offset, so it follows any
MakeHuman body made from targets. The **community assets** (the site's user clothes) are
per-asset licences, mostly CC-BY or CC0, some with no-derivatives terms: each one checked before
use, and credited in `CREDITS.md` if not CC0.

- **Fit:** our base body is **Rodin's mesh, not MakeHuman's**, so the `.mhclo` binding does not
  apply to it directly. Two ways round it: (1) warp MakeHuman's base mesh onto the Rodin body
  (the portrait factory fits MakeHuman's head to a face by targets; a whole-body non-rigid fit
  is new work, a few days), then carry each garment by its binding; (2) treat the garment as a
  shape only: lay it on the body by landmarks (shoulders, wrists, waist, as `Piece` places a
  Tripo coat), push it out of the skin and weight it from the skin under it (`clear_twin`,
  `weights_from_skin`, as a twin piece is carried today). (2) is what the fitter does already;
  the risk is the same one the Tripo coat had (a garment made for another girth, torn by every
  correction), smaller here because the clothes are clean single shells, not double ones.
- **Paint:** by projection from his pictures, as (b).
- **Cut:** the shipped clothes are modern (casual suits, work suits, T-shirts); none has an
  1880s standing collar with points, a notched-lapel waistcoat or a frock coat, so each would be
  reshaped by script anyway (the collar built as in (b)). What they give is clean topology and
  real sleeves; what they cost is the fit to a body they were not made for, and a cut that
  isn't his.

### (b) Garments modelled by script, shaped by his body (recommended)

Each garment is built from the fitted base body's own skin, as `clothes.py` does for a MakeHuman
man, in a new `tools/blender/garments.py` run between the base body's fit and the neck ring:

- **The shirt:** the trunk's skin from the neck ring to below the belt (tucked under the
  trousers), shelled out 5-8 mm, as the body; each arm's skin from the shoulder to `CUFF_PAST`
  beyond the wrist cut as a **sleeve tube of its own**, shelled out, joined to the body at the
  armhole by one ring of faces (so no strip of shirt can ever lie between arm and side: the
  smear is impossible by construction); the **collar** a stand of cloth round the neck ring
  (`_collar`: the shirt's top ring doubled, raised ~3 cm, leaning out) with a neckband, and
  **two points** turned down over the waistcoat's lapels either side of the knot
  (`_collar_points`, sized from his picture: ~5 cm long, standing ~2 cm off his chest); the
  **tie** a knot and two loose ends (`_string_tie`, reshaped to his loose bow), part of the
  shirt's mesh as today. Judged close up against the picture, not by numbers.
- **The waistcoat:** the trunk's skin from under the collar to below the belt, shelled 13 mm;
  the V cut down the front to the top button; notched lapels as flat strips (`_lapels`); a hem
  on a curve ending in two points; armholes cut wide of the sleeves' roots (the sleeve passes
  under the armhole, never through it). Buttons and pockets painted, not modelled.
- **The trousers:** the trunk from the waist and each leg's skin to the boot top, shelled 8 mm;
  the boots stay as today (the trousers piece carries them, or the body's painted boots show).
- **Thickness and clearance:** the fitter's `CLEAR`/push-out (11-12 mm) and `tuck_layers` work
  unchanged; a made garment is marked `"made": true` in its `.json` and the fitter skips the
  twin's repairs (`ARMPIT_DROP`, the comb, `_arms_in_sleeves`): none is needed.
- **UVs:** unwrapped by script, each part upright and whole (the body tube round the trunk's
  axis, each sleeve round its arm's axis, the collar and points flat strips), written at the
  skin's density (2048 a side, ~1.8 mm a texel, as today's painted cloth).
- **Paint:** `body_paint.py --dressed` generalised to paint a **set** of meshes: the body and
  its garments, stood as the pictures show him, are lined up with each picture by the whole
  figure's outline (as now), and each garment's texels take the facing picture's colour where
  that colour is the garment's kind (light: shirt and collar; brown: waistcoat; dark: trousers
  and tie), depth-tested against the whole dressed figure, so the waistcoat never paints the
  shirt and the sleeve's inside is filled from its own island. The four arms-out pictures first;
  the picture's own squares kept (DESIGN.md §4, "a bit of square"). The collar's and tie's
  paint from the front picture; buttons and pockets with it.
- **Fit to any man:** the garment is a function of the body (the skin's regions, the joints and
  the neck ring from `envelope.json` and the fitter's report), so a lean or heavyset base body
  gets its own wardrobe by running the script again; a man of a type wears that type's.
- **Cost:** no paid calls. Risks: the sleeve's join at the armpit (a visible ring if the
  shell's normals cross there: smooth the ring's positions, as `mh_hand.smooth_wrist` does at
  the wrist); the skirt-less shapes are easy, the collar's points are the hand-made part; the
  tie knot's paint from one picture.

### (c) Other sources

- **MPFB2** (MakeHuman's Blender plugin; its assets are the same system assets, CC0; its code
  GPL): a scripted `.mhclo` fitter for MakeHuman bodies. Not for our Rodin bodies, and we don't
  copy code.
- **Garment-pattern tools** (GarmentCode, ETH, MIT-licensed: sewing patterns from parameters,
  draped by simulation): real patterns, a collar with points by parameter, but a long pipeline
  (pattern → simulation on a body → remeshing) for one man's three garments; worth a look once
  the wardrobe grows (women's dresses, the coat's skirt) and not now.
- **Model libraries** (Quaternius, Kenney, Poly Haven, Sketchfab CC0, OpenGameArt): no period
  men's garments of use found; most are whole dressed characters or modern clothes, and each
  would need the same fit as (a).

(The licence findings and links are in the research note at the end of this brief.)

### Recommendation

**(b).** The collar and the separate sleeves are what Sean asked for, and (b) is the only route
that gives them by construction on *our* body; it reuses what exists (`clothes.py`'s collar,
points, lapels and tie; `fit_tripo`'s carry of a laid-on piece; `body_paint --dressed`'s
projection) and nothing in it is paid or licensed. (a) would still need the collar built and a
new whole-body fit for a cut that isn't his. If (b)'s shapes disappoint close up, MakeHuman's
CC0 shirt and trousers meshes are the fallback for the sleeves and legs, through the same fitter.

## Steps (each with a before/after sheet against his pictures)

1. **The shirt, on the no-coat man** (`bold_cowboy_vest_layered`): collar and points, sleeves,
   the tie; painted from the arms-out pictures. Sheet: the whole man at 0°/90°/180° and close-ups
   of the collar, armpits, sleeves (`lab_run.sh`, `--fov=16 --dist=2.0 --aim=1.55` for the
   head and shoulders; `--hide=Vest_whole` to see the shirt alone). Sean's call on the collar.
2. **The waistcoat and trousers** the same way; the waist close up (hem, belt, the shirt tucked).
3. **The coat man** (`bold_cowboy_layered`): the coat as a made garment too (shell + skirt,
   lapels, collar; `clothes.py` drapes the skirt), painted from the coat pictures (their dark
   backdrop defeated the outline line-up before: the figure mask by colour distance, or Rodin's
   own texture as today for the coat alone); his shirt's collar and sleeves under it.
4. **The pose check** (stand, sit, hands up, crouch, aim; `people_lineup.gd`): no poke-through,
   no tears, coat on and off. Tests: `test_bodies`, the people and wound tests, all green.
5. **The recipe**: `LAYERED.md` rewritten for garments (the twin cut kept as a bookmark), so a
   fresh session dresses a new man from his base body alone.

Order of merges: one garment per merge at most, with Sean's OK on its sheet; today's man stays
in the game (`bold_cowboy_vest_layered`, `bold_cowboy_layered` as they are) until the new one is
better; the new one is built as a trial outfit (`bold_cowboy_garments`) beside him first.

## What done looks like

- The collar stands round his neck, its points either side of the knot, from the front and
  three-quarter views at 1.2 m and close up; Sean says it's a collar.
- No shirt or skin between his arms and body, at the armholes or through the waistcoat, from any
  of five sides, with his hands down, up and on the revolver.
- Each garment its own mesh and texture, painted from his pictures (edge strength in the
  picture's frame ≥ today's 0.88 by `cloth_detail.py`), with a bit of square.
- The whole man inside the people budget: garments under ~12k triangles together (today's three
  are 17k before the fitter cuts them).
- A fresh session can dress a new man by the recipe without retuning.
- His face unchanged: `assets/people/bold_cowboy_*layered_head.png` byte-identical (`md5sum`).

## How it's judged

Sean's eye on the sheets beside his pictures (close-ups at the same framing: collar, armpits,
waist, sleeves; neutral and warm light), each step's sheet in `docs/style_test/garments-2026-10-18/`;
`cloth_detail.py`'s numbers alongside; the art session judges him in the shots. Lighting (the
dark trousers, the orange lamp light) is art's: reported, not fixed here.

## Not in this brief

The hat (its own piece already); women's garments; a wardrobe beyond his outfit (other cuts
and colours come from the same script with other parameters, after); the game's lighting;
cloth simulation in play.

## Paid calls

None planned. ~$11.66 of Sean's $15 is spent.

## Research note (2026-10-18)

(filled in below)
