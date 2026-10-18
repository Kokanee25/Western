# Brief: garments and the body under them (shirt with a collar, waistcoat, trousers that hang, then the coat)

Characters session, from 2026-10-18. Builds on `docs/briefs/layered-people.md` (the base body, the
neck ring, clothes as layers) and the recipe `tools/characters/LAYERED.md`. **Status: Sean's go on the revision (2026-10-18, "Go"). Steps 1-3 built on the trial man
`bold_cowboy_made_layered` (branch `claude/characters-garments`, not merged): the body fitted bare,
the made shirt and waistcoat, trousers that hang and the boots; through the pose check with no web
and nothing through the waistcoat (sheets `s3_*` in `docs/style_test/garments-2026-10-18/`; recipe
`tools/characters/GARMENTS.md`). Waiting on Sean's OK to merge the no-coat man; then the coat man.**

## Why

His clothes are cut out of one Rodin model of the dressed man (`twin_pieces.py`) and laid on a
base body Rodin made from the boxer-shorts pictures. Every patch since has moved the problems
around, not fixed them (LAYERED.md §4 "defects by cause"):

1. **A web of shirt and skin between his arms and body**, the full length, when he stands with
   his arms down; shirt and skin at his shoulders push out through the waistcoat's upper chest.
   Rodin fuses sleeve to side and collar to neck: the armpit is tied to arm and body at once.
2. **A poor collar:** a flat band, a neck brace or ragged slivers. Sean turned the band down twice.
3. **A body wrong beside his pictures:** legs like a bodybuilder's in tights (the trousers cling
   to thigh, knee and calf; in the pictures they hang straight from hip to boot); a head too
   small; high boxy shoulders, almost no neck, a block of a chest (the pictures: sloping
   shoulders, the neck showing, the chest narrowing to the waist); puffy sleeves, arms that look
   short and thick.

A second Rodin model with his arms out (`bold_cowboy_armsout_dressed`, run 89, $1.60) separated
the arms at the source but still needed the cut-twin recipe retuned: that road is closed.

## Goal

- **Proper garments, each its own clean mesh:** a **shirt** with a real standing collar (its
  points either side of the tie knot) and **sleeves as tubes of their own** with a clean armhole
  seam; a **waistcoat**; **trousers that hang straight**; later **the coat**. Each fitted and
  weighted to the body so it bends with him, painted from his pictures, and **reusable**: every
  man in town wears them in his own colours (from his pictures) and sizes (from his body).
- **His body under them matched to his pictures:** height, head size, shoulders, neck, the
  chest's taper, the legs' line, arm length.
- The game sees no change in how people work: `people.json` `pieces` as now, `HumanBody`'s
  garments, holes and blood; the game's skeleton (`envelope.json`) unchanged.

## References

- **His pictures** (`docs/concept/style/factory/`): `bold_cowboy_armsout_dressed/` (no coat, arms
  held out, collar standing: the set for shape and painting; its arm angle, 10°, is the base
  body's own 9°, so projection lines up), `bold_cowboy_vest_dressed/` (no coat, older),
  `bold_cowboy_dressed/` (the coat), `bold_cowboy_body/` (his body in boxer shorts). The collar
  (arms-out front): a turned-down collar standing off his neck, its two points over the
  waistcoat's lapels either side of a loose black tie knot. The waistcoat: notched lapels, five
  buttons, two welt pockets, a pointed hem, a belt across the back. The trousers: dark, straight
  from the seat to the boot, a little break over the boot.
- **Sean's words:** the flat collar band turned down twice ("a flat straight piece"); "the arm
  and body meshing together"; "it just doesn't look natural or right"; "a little blockiness in
  the cloth is fine".
- **The art judge** (PR #150, `docs/screenshots/judge/2026-10-18_man/verdict.md`, references
  `docs/concept/judge/10_authority_saloon_man.jpg`, `14_style_man_saloon_front.jpg`): the shirt
  and collar should read clean lit white and the tie one black shape (they render grey-brown);
  the coat warmer and rougher-squared than ours. (His hat, hands and face are not this brief.)
- **The look:** painted illustration with a bit of square (DESIGN.md §4), like his face.
- **Today's man** for before/after: `docs/style_test/layered-2026-10-15/d17_take2.png`.

## Measured before choosing

**His body against his pictures** (a sub-agent, 2026-10-18; sheets
`docs/style_test/garments-2026-10-18/p0_proportions_front.png`, `_side.png`: the vest picture,
the body picture and the game's `stand` at equal height, a line every 5%). Shares of his height,
crown to sole; the game is `bold_cowboy_vest_layered`, 1.89 m:

| | pictures (vest / body) | game | game ÷ pictures |
|---|---|---|---|
| head, crown to chin | .142 / .152 | .138 | 0.97 / 0.91 |
| head width with hair (front) | .135 / .157 | .115 | 0.85 / 0.73 |
| shoulders' width | .313 | .313 | 1.00 |
| shoulder top over the shoulder joint | 6 cm | 12 cm skin, 15 cm clothed | ×2 |
| neck showing, front / side | .013 / .023 | .007 / .017 | 0.5 / 0.7 |
| crotch (from the top) | .53-.55 | .61 | inseam 0.85 |
| thigh / knee / calf, one leg (front) | .091 / .077 / .086 | .097 / .079 / .093 | bulges at thigh and calf |
| upper sleeve, front | .070 | .052 (deep oval, .081 front to back) | thin and deep |
| arms off vertical (stand) | 21° (his own) | 3.5° (the game's hang) | pressed to his sides |

**Why** (all `tools/blender/fit_tripo.py` but the head):
1. **The Rodin base body is fitted as a hatted, dressed "whole man".** `self.bare = "model" in
   spec` (:472) is false for a Rodin body (his entry names `"rodin"`), so the hatted branch
   stretches trunk, neck and head joint to joint from Tripo's fixed joint shares (`RIG_Y`): his
   trunk ×1.16, shoulders and chin up 7-8 cm while his arm joints rise 1.4 cm, and he ends 1.89 m
   on a skeleton built for 1.815. That is the boxy high shoulders, the missing neck, the block of
   a chest and the low crotch. Its HAIR_M note (:54-62) describes this very failure for Tripo
   men. The same key runs `skirt()` on his thighs (:1475). Checked numerically (scratch only):
   fitted bare he is 1.815 m, his shoulder top 6 cm over the joint (his own), the crotch at .43
   of his height from the floor (was .40).
2. **`shoulders: 1.1`** (people.json; `broaden` :797) moves each arm out 2.6 cm at the shoulder
   and squares the upper chest; his width already matches the pictures without it.
3. **The head:** `neck_ring --head_scale=0.92` and thin hair at the sides (width ×0.85); the
   collar (`--collar=plain`) stands 1.5 cm over his chin and hides the neck.
4. **The legs:** the twin's trousers are pushed out along his skin's normals (`clear_twin`,
   27,000 points at 1.2 cm), so they take every bulge of the bodybuilder legs under them; the
   base body has a web of skin between the thighs down to .41 of his height (pictures .45-.47).
5. **The arms:** the game hangs them at 3.5° against his 21°, `_arms_in_sleeves` then squeezes
   the arm to fit the twin's sleeve (one to 0.55 of itself) and the sleeve bulges at the elbow.
   The arms are not short (upper arm ×1.05, forearm ×1.06 of his own); they look it from the
   high shoulders and the stand pose's bent elbows (gameplay's pose).
6. **Not the envelope:** the game's skeleton has normal lengths and needs no change.

**The pose:** the base body holds his arms 9.4° from vertical; the arms-out twin 10.3°, the old
coatless twin 4.4-5.1°. Garments made on the base body stand as the arms-out pictures do.

**Triangles:** today's pieces after the fitter: shirt 5,000, waistcoat 4,337, trousers 8,000. The
made shirt is 7,700 and the waistcoat 2,000.

## What the trial runs taught (2026-10-18, two sessions at once)

Both built route (b) below for the shirt and waistcoat on the trial man `bold_cowboy_made_layered`:
`claude/characters-garments` (sheets `g1_shirt.png`, `g2_vest.png`; recipe LAYERED.md §6) and
`claude/characters-garments-second` (sheet `g1_shirt_vest.png`; side by side
`g2_two_sessions.png`). What held:
- **Shirt and waistcoat from one tube** round his trunk, the waistcoat 8 mm further out: they
  nest by construction and nothing shows through from any side. Lofted separately (or a made
  shirt under the cut twin's waistcoat), the shirt came through everywhere.
- **Cut along a line, not face by face** (`cut_along`): hem, points, V, armholes clean, no
  sawtooth.
- **The collar from his neck's narrowest + 1 cm**, lower behind, open in front: it hugs his neck
  (from the neck's base it was a ring round his trapezius: a neck brace); the shirt runs up into
  it so no skin shows on his shoulders.
- **In the fitter a made piece is kept whole** (decimated to the twin's budget its collar
  shredded), its collar and tie are not pushed off his skin (the fall stood out under his chin),
  its sleeve heads are tucked; `neck_ring --collar=made` pushes it out of the bust's neck and
  never cuts it. A made waistcoat takes none of his arms' weights (its edge swung with his arm).
- **Paint by Lab class with a hue floor** (his throat painted the collar tan), the mask round his
  head small enough to leave the collar, unpainted cloth its lit colour.
- Still open: the shirt shows at his back waist (the twin's trousers, ragged there); grey-brown
  smears on the upper sleeves from the side pictures (their outlines fit at 0.62); the collar
  greyer than his picture's white; the tie's ends past its painted bow; no lapel notch.
The second branch's garments are the base going on (no poke-through); the first's lapel strips,
arm-weight rule and recipe text are carried into it.

## The options

**(a) MakeHuman's own clothes: no.** Nineteen system items, every male one a fused suit (shirt
and trousers one mesh): the defect we are leaving; no standing collar, waistcoat or coat. The
licence contradicts itself (CC0 in `license.txt`, AGPL-3 in every `.mhclo` header) and the asset
repo is gone (404). And our bodies are Rodin's, not MakeHuman's base mesh. (Research note below.)

**(b) Garments modelled by script, shaped by his body (recommended; trial-run above).**
`tools/characters/garments.py`: each garment lofted from the fitted base body's own
cross-sections as tubes (trunk, each sleeve, each leg, the collar), cut to shape along lines,
unwrapped by construction, painted by projection from his four pictures (only colours of the
garment's own class, depth-tested against the whole dressed man), carried by the fitter as a
laid-on `made` piece and weighted from his skeleton. Parameters per garment (offsets, hem, V,
armholes, collar, colours by picture), so another man is another run.
- **The shirt:** trunk tube, sleeve tubes of their own (no strip of shirt can lie between arm and
  side), a stand collar with a fall and two points, the tie a knot and two ends.
- **The waistcoat:** the shirt's trunk tube 8 mm out, cut to its hem and points, V, armholes and
  shoulder seams; lapel strips with a notch; buttons, pockets and the back belt painted.
- **The trousers (new):** a waistband tube round his hips and **a tube per leg that hangs**: at
  each angle round the leg the radius is the widest his leg reaches anywhere *above* that height
  (cloth falls from the seat and the front of the thigh, it does not follow the knee in or the
  calf out), eased to a straight line from seat to boot top and a slight taper; the crotch a
  seam joining the two legs below his own; a break over the boot. Never pushed out along his
  skin's normals. **His legs under them shrunk inside** (as `_trunk_in` does for the trunk), so
  no knee or calf comes through when he crouches or sits.
- **The boots:** their own piece, cut from the coatless twin below the boot top (a boot is not
  fused to anything else, so the twin cut is clean there), the trousers' hem over them.
- **The coat (last):** the waistcoat's tube further out for the body, sleeve tubes of their own
  over the shirt's, lapels and collar, the skirt draped from the hips (as `clothes.py` drapes it);
  painted from the coat pictures.
- **Bending with him:** sleeves weighted to the arm bones by their position along the arm, the
  trunk tube to the spine (none of the arms' weight below the shoulder cap: the armpit fold is
  where the web came from), the trouser legs to the thigh and shin by their height along the leg,
  not from the nearest skin (a loose leg's nearest skin is the other leg at the crotch).
- **No licence, no cost:** our own code; nothing for `CREDITS.md`.

**(c) Others:** MPFB2 (assets CC0, no clothes of its own, GPL fitter we would not copy);
GarmentCode (MIT; parametric patterns draped by a GPU simulator; no stand collar, waistcoat or
coat; the fallback for draped sleeves and trousers only if (b)'s disappoint close up); no
period garments under CC0 or CC-BY in any model library.

**Recommendation: (b)** for every garment, on a base body fitted right first.

## His body under them

1. **Fit the Rodin base body bare-headed** (`fit_tripo`: a base body is bare whether its entry
   names `model` or `rodin`, e.g. a `"bare": true` in people.json or "a Rodin body with
   `pieces`"); no `skirt()` on a body that wears trousers. Expected (measured in scratch): 1.815 m,
   his own shoulder slope and neck, the crotch at .43 of his height from the floor (pictures
   .45-.47; the web's cut in step 4 takes it the rest of the way).
2. **`shoulders` 1.0** (or ~1.05 with a longer fade), measured again after step 1.
3. **His head to the pictures' size:** `--head_scale` ~1.05 (to ~.15 of his height crown to
   chin and ~.13 wide), checked on the sheet; the head's texture stays byte-identical (only its
   scale changes); the collar's top under his chin so the neck shows.
4. **His legs:** the web between his thighs cut to the pictures' height (`cut_bridges`, which
   the bare branch runs), his legs shrunk inside the hanging trousers.
5. **His arms:** they look right once the shoulders are down; the stand pose's 3.5° hang and
   bent elbows are gameplay's (noted to them, not changed here).
6. **If the reshaped Rodin body still reads wrong** beside the pictures: a new Rodin base body
   from new boxer-shorts pictures ($1.60), asked first.
The same rule fits every base body, so the next man's body comes out right too.

## Steps (each with sheets against his pictures; the trial man beside today's)

1. **The body:** fitted bare, `shoulders` 1.0, head ~1.05; sheet: the pictures and the bare
   body at equal height, front and side (as `p0_proportions_*`), and the dressed man's stand.
2. **The shirt** on the no-coat trial man: collar, sleeves, armholes, the tie; then **the
   waistcoat**; one sheet each.
3. **The trousers and boots**; the waist close up (the shirt tucked, the waistcoat's hem over
   the waistband) and the legs front and side.
4. **The pose check** for the no-coat man, then Sean's OK on him; then **merge** him in place of
   `bold_cowboy_vest_layered`.
5. **The coat man** (`bold_cowboy_layered`): the coat made, his shirt's collar and sleeves under
   it; the pose check; Sean's OK; merge.
6. **The recipe:** `tools/characters/GARMENTS.md` (LAYERED.md points to it; the cut twin kept as a
   bookmark), so a fresh session dresses a new man from his base body and pictures alone.

Order: no-coat man first, coat man after; today's men stay in the game until Sean says the new
one is better; a merge only with his OK on its sheets.

## How it's judged (every step)

- **In the game's own poses first, not the A-pose:** standing with his arms down at his sides as
  he idles in town, and the pose check: `xvfb-run -a godot --path . --rendering-driver vulkan -s
  res://tools/people_lineup.gd -- --out=DIR --ids=<no-coat>,<coat> --poses=stand,hands_up,sit,aim,crouch --hatless`.
- **Side by side with his pictures at equal height,** front and side, before and after.
- **Close-ups** of the collar, armpits, shoulders, waist and trouser legs (`lab_run.sh` at
  `--fov=16 --dist=2.0 --aim=1.55`; `--hide=Shirt_whole` / `Skin_whole` / `Vest_whole` /
  `Coat_whole` shows which layer a defect is in).
- By eye against his pictures and Sean's words, not by numbers alone. Lighting (the dark
  trousers, the orange lamp light, the clothes rendering darker than their textures) is art's:
  noted, not fixed here.

## What done looks like (in every pose)

- **No web** between arm and body.
- **Nothing showing through** the waistcoat (or the coat).
- **The collar standing up,** its points either side of the knot; Sean says it's a collar.
- **The trousers hanging straight** from seat to boot.
- **His proportions as the pictures':** head, shoulders, neck, chest to waist, crotch, arms.
- Each garment its own mesh and texture, painted from his pictures, with a bit of square; the
  garments under ~12k triangles together for the no-coat man.
- His face's textures byte-identical (`assets/people/bold_cowboy_*layered_head.png`, `md5sum`).
- All tests green; a fresh session can dress a new man by `GARMENTS.md` without retuning.

## Not in this brief

The hat (its own piece already), his hands and face (the art judge's other points); women's
garments; a wardrobe beyond his outfit (other cuts and colours come from the same script, after);
the game's lighting and the stand pose's arm hang; cloth simulation in play.

## For Sean to decide (with his OK on the brief)

1. Route (b) for every garment, the trousers hanging by construction; the second trial branch's
   garments as the base.
2. **The body first:** fitted bare, `shoulders` 1.0, the head up to ~1.05 (his face's texture
   unchanged), before any more garment work.
3. The boots their own piece cut from the twin; the tie part of the shirt's mesh; buttons and
   pockets painted.
4. The order: no-coat man, then the coat man; today's men stay until he says the new one is
   better; a merge only with his OK on its sheets.

## Paid calls

None planned. A new Rodin base body ($1.60) only if the reshaped one still reads wrong, asked
first. ~$11.66 of Sean's $15 is spent.

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

## Progress

- 2026-10-18 (second session): **the shirt and the waistcoat made** (sheet
  `docs/style_test/garments-2026-10-18/g1_shirt_vest.png`: today's coatless man, the trial man,
  his pictures). The shirt alone under the cut twin's waistcoat poked through it everywhere (two
  surfaces from two sources never nest; today's man hides it by his shirt painted brown under the
  waistcoat), so step 2's waistcoat came forward: one trunk tube for both, 8 mm apart. Fixed on
  the way: the collar was as wide as his neck's base (a ring round his trapezius) and flared out
  22 mm (now his neck's narrowest + 10 mm, lower behind, open in front); the fitter's decimation
  shredded the collar (made pieces kept whole: shirt 7.7k, waistcoat 2.0k triangles) and its push
  off his skin stood the fall out under his chin; `neck_ring`'s cut sliced the collar flat
  (`--collar=made`); his throat painted the collar tan (a hue floor on the shirt's class; the
  mask round his head halved; unpainted cloth its lit colour, not the shadowed median).
  Chain: `garments.py --garments=shirt,vest --views=...armsout_dressed...`, `fit_tripo.py
  --only=bold_cowboy_made_body`, `neck_ring.py --body=bold_cowboy_made_body
  --head=bold_cowboy_painterly_lit --out=bold_cowboy_made_layered --head_scale=0.92
  --collar=made` (seed `bold_cowboy_made_layered_head.png` from the vest man's first: the head
  texture is kept). Today's men byte-identical through the changed fitter.
  **Open:** the shirt shows at his back waist (the twin trousers' top is ragged there: made
  trousers next); grey-brown smears on the upper sleeves from the side pictures (their outlines
  fit at 0.62); the collar reads tan in the lab's light and its back takes the fill (hair covers
  it in the back picture); the tie's strips hang past its painted bow; the knot's box shows
  black at the collar; the waistcoat's back is boxy at the shoulders. Waiting on Sean's eye.
