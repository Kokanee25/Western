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

Looked into (the research note below has the links): **not a source of garments.**

- **What exists:** MakeHuman 1.x's shipped ("system") clothes are nineteen items: six male
  casual suits, an elegant suit, a work suit, female suits, a fedora and shoes. Every male item
  is **one fused mesh** (shirt and trousers as one piece; the elegant suit jacket, trousers and
  shirt as one), so they have the very defect we are leaving: nothing separable, no standing
  collar, no waistcoat, no coat on its own. The repo MakeHuman downloads them from
  (`makehumancommunity/makehuman-assets`) now returns 404 on GitHub; a 2018 mirror has them.
- **Licence:** MakeHuman's `license.txt` says the assets (base mesh, targets, clothes) are CC0,
  and MPFB2's `LICENSE.md` says the same of its asset packs; but the mirror's `LICENSE` is
  AGPL-3 and every clothes `.mhclo` file's header reads "licensed AGPLv3". Contradictory; if
  one were ever shipped, `CREDITS.md` would cite both statements. Moot, since they are unusable.
- **Community assets** (makehumancommunity.org): per-asset CC0 or CC-BY (the FAQ says only
  those two), fetchable by script from the site's `assets.json` index (type, licence, files).
  No cowboy, waistcoat or frock-coat item turned up in search; the site is blocked from this
  workspace, so the index could not be read.
- **Fit, had one existed:** an `.mhclo` binds each garment vertex to three MakeHuman base-mesh
  vertices with weights and a scaled offset (a 30-line numpy fitter, no code copied), but our
  base body is **Rodin's mesh, not MakeHuman's**, so it would still need MakeHuman's base warped
  onto the Rodin body first (new work), or the garment laid on by landmarks and carried as a
  twin piece is (`clear_twin`, `weights_from_skin`), with the Tripo coat's old risk (a garment
  made for another girth).

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

- **MPFB2** (MakeHuman's Blender plugin): code GPL-3, assets CC0 by its own licence file; it
  ships no clothes itself (the same asset packs, downloaded), and its fitter is Blender-bound
  GPL code we would not copy. Not for our Rodin bodies.
- **Garment-pattern tools:** **GarmentCode** (MIT; `pygarment`) makes parametric sewing
  patterns (bodice, sleeves, trousers, band collars, a simple lapel) and drapes them with a
  GPU simulator; it has no shirt collar with a stand and fold, no waistcoat and no coat, and
  its own body set. Research-grade; worth a look once the wardrobe grows, not for three
  garments now. SewFormer (no licence, needs Maya) and FreeSewing (MIT, 2D patterns only,
  JavaScript) are out.
- **Model libraries:** nothing period-appropriate under CC0 or CC-BY: Quaternius' outfits are
  fantasy and its newer licence forbids redistribution; Kenney and Poly Haven have no clothes;
  OpenGameArt has a CC0 cowboy hat and sprites; Sketchfab's CC0 finds are a 286k-triangle
  scanned military coat and a modern vest; every western outfit on the stores is paid and
  non-redistributable.

### Recommendation

**(b).** The collar and the separate sleeves are what Sean asked for, and (b) is the only route
that gives them by construction on *our* body; it reuses what exists (`clothes.py`'s collar,
points, lapels and tie; `fit_tripo`'s carry of a laid-on piece; `body_paint --dressed`'s
projection) and nothing in it is paid or licensed. (a) would still need the collar built and a
new whole-body fit for a cut that isn't his, and no separable shirt exists there anyway. If
(b)'s shapes disappoint close up, the fallback is GarmentCode's (MIT) draped sleeves and
trousers laid on him through the same fitter, with (b)'s collar and waistcoat.

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

## For Sean to decide (with his OK on the brief)

1. Route (b); GarmentCode's draped sleeves and trousers as the fallback only if (b)'s shapes
   disappoint close up.
2. The order: the shirt first on the no-coat man, then waistcoat and trousers, then the coat man;
   one garment a merge, his OK on each sheet.
3. The tie stays part of the shirt's mesh (as today), the boots stay with the trousers' piece
   (as today), buttons and pockets are painted, not modelled.
4. The trial outfit is built beside today's men (`bold_cowboy_garments`); today's
   `bold_cowboy_vest_layered` and `bold_cowboy_layered` stay in the game until he says the new
   one is better.

## Paid calls

None planned. ~$11.66 of Sean's $15 is spent.

## Research note (2026-10-18, a sub-agent's web search; the makehumancommunity.org,
sketchfab and opengameart hosts are blocked from this workspace, so the listings were read on
GitHub and by search, not verified file by file)

- MakeHuman 1.2.0 `makehuman/download_assets_git.py` clones `makehumancommunity/makehuman-assets`
  (404 now; not in the org's public list). Mirror: `github.com/dmaugis/makehuman-py3-assets`,
  `base/clothes/` = fedora01, female_casualsuit01/02, female_elegantsuit01, female_sportsuit01,
  male_casualsuit01-06, male_elegantsuit01, male_worksuit01, shoes01-06; each `.mhclo + .mhmat +
  .obj + diffuse/normal/ao`. Its README: "provided under the standard makehuman license (AGPL)";
  `.mhclo` headers: "Copyright (C) 2016 Data Collection AB ... licensed AGPLv3". MakeHuman's
  `license.txt`: the assets "have been released under CC0 1.0 Universal"; MPFB2 `LICENSE.md`
  the same for its packs, its code "released under GPLv3".
- Community assets: FAQ "What do I need to do when I use a CC-BY asset?" (CC0 and CC-BY only);
  the downloader plugin `community-plugins-assetdownload` reads
  `www.makehumancommunity.org/sites/default/files/assets.json` (records: type, license, title,
  files{type: url}).
- `.mhclo` binding: `verts 0` then one line per garment vertex, `i j k w1 w2 w3 ox oy oz` (or one
  index: a copy); `x_scale A B f` (two body vertices whose distance was f when authored) and
  `y_scale`, `z_scale` scale the offsets; `delete_verts` hides body vertices under the garment.
- GarmentCode: `github.com/maria-korosteleva/GarmentCode`, "MIT License, Copyright (c) 2024
  Maria Korosteleva"; collars.py has band and simple-lapel collars, hoods and necklines; no
  jacket or vest program.
- Quaternius' "Modular Character Outfits" (fantasy; a 2026 note puts new downloads under a
  licence forbidding redistribution as a pack); Sketchfab CC0: a scanned military coat (286k
  tris, Małopolska museums); OpenGameArt CC0: a cowboy hat.
