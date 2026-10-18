# Recipe: garments made on a man's base body (shirt, waistcoat, trousers; boots from his twin)

Brief: `docs/briefs/garments.md`. This replaces the cut-twin clothes of `LAYERED.md` §3 step 4
(kept there as a bookmark): every garment is lofted from his base body's own skin by
`tools/characters/garments.py`, so the sleeves are tubes of their own (no web between arm and
side), the collar stands round his neck, the trousers hang, and the shirt, trousers and
waistcoat nest one inside another by construction. Sheets: `docs/style_test/garments-2026-10-18/`.
The trial man is `bold_cowboy_made_layered` (people.json `bold_cowboy_made_body`); today's
`bold_cowboy_vest_layered` stays in the game until Sean says the new one is better.

## 1. What you need

- His **base body** (Rodin from his boxer-shorts pictures, `assets/people/tripo/test/<body>_rodin.glb`,
  A-pose, arms ~9°), fitted **bare** (people.json `"bare": true`: his shoulders onto ours and all
  above them as one; without it a Rodin body is fitted as a hatted whole man, 7-8 cm too high in
  the shoulders, no neck) with `"shoulders": 1.0`.
- His **four dressed pictures** with his arms a little out, as the body stands (the bold cowboy:
  `docs/concept/style/factory/bold_cowboy_armsout_dressed/`): painted from by projection.
- His **dressed twin's trousers piece** (`tripo/<man>_under_trousers.glb`, `twin_pieces.py`): only
  for the boots, cut from it below `TROUSERS boot_top`.
- His head through the ring at **`--head_scale=1.05`** (the pictures' head: ~0.14 of his height
  crown to chin), his approved head texture copied in first so it is kept.

## 2. The chain (the workspace as `RECIPE.md` §3; `P=docs/concept/style/factory/bold_cowboy_armsout_dressed`)

```sh
# 1. the garments on his base body, painted from his four pictures
~/bpyenv/bin/python tools/characters/garments.py --body=bold_cowboy_body --out=bold_cowboy_made \
    --garments=shirt,vest,trousers,boots --preview \
    --views=front:$P/front.png,left:$P/left.png,right:$P/right.png,back:$P/back.png
#    → assets/people/tripo/bold_cowboy_made_{shirt,vest,trousers,boots}.glb + .json ("made", "islands");
#      build/garments/: the flat preview (no game), each view's outline fit, which view painted what,
#      each garment's texture (<out>_<garment>_paint.png).
# 2. the fit (people.json bold_cowboy_made_body: bare, shoulders 1.0, pieces = the four above)
~/bpyenv/bin/python tools/blender/fit_tripo.py --only=bold_cowboy_made_body
# 3. his head (first: cp assets/people/bold_cowboy_vest_layered_head.png assets/people/bold_cowboy_made_layered_head.png)
~/bpyenv/bin/python tools/characters/neck_ring.py --body=bold_cowboy_made_body --head=bold_cowboy_painterly_lit \
    --out=bold_cowboy_made_layered --head_scale=1.05 --collar=made
godot --headless --import
```

`--preview` alone (no `--views`) builds the garments without painting in ~30 s: shape first.

## 3. How each garment is made (`garments.py`; its numbers at its top)

- **One trunk tube** (`trunk_tube`): lofted round his trunk's axis from under his hips to his
  neck's narrowest (cells: the 95th percentile of his skin's radii there, his arms' points left
  out, empty cells **filled round** from his chest and back, never down from his deltoids; no
  wider under his hips than at them). The shirt is it at `OFFSET shirt` (6 mm), the trousers'
  seat at 9 mm, the waistcoat at 14 mm: **they nest by construction**.
- **Cut along lines, not face by face** (`cut_along`: a field per edge, vertices moved onto its
  zero): the waistcoat's hem and points, V, armholes (`VEST arm_*`), shoulder seams and top; the
  trousers' waist; the collar's front opening.
- **Shirt:** the trunk; **each sleeve a tube of its own** round a straight axis through his arm,
  lofted from his arm's own skin (and his shoulder's cap for its head); the **collar** a stand
  from his neck's narrowest + `COLLAR_EASE`, lower behind (`COLLAR_BACK_DROP`), open in front
  (`COLLAR_GAP`), a fall and two points; the tie a knot and two ends. The trunk runs up into the
  collar so no skin shows on his shoulders.
- **Waistcoat:** the trunk at 14 mm cut to shape; lapels, buttons, pockets and back belt painted.
- **Trousers:** the seat, and **each leg a tube round a straight axis** whose radius runs in a
  straight line from his upper thigh (`thigh_drop` under the crotch) to the boot's top
  (`boot_ease` outside the boot), his calf allowed `tuck` inside it (the fitter tucks his skin);
  the inner sides a `gap` apart below the crotch. Never pushed out along his skin.
- **Boots:** the twin's trousers below `boot_top` (a boot is fused to nothing), their own piece.
- **Paint** (`paint`): his body and the garments lined up with each picture by the figure's
  outline; a texel takes only colours of its garment's **Lab class** (`CLASS`: lightness, chroma,
  and for the shirt a hue floor, so his skin never paints his collar), not near his hands' and
  head's outline (`SKIN_MASK`); what no picture sees takes the class's lit colour (`FILL_LIT`).

## 4. In the fitter (`fit_tripo.py`, made pieces only; cut-twin men unchanged)

- A made piece is **not decimated** (its own triangles: the collar shredded at the twin budget).
- A made garment's **parts** come from its texture islands (`islands` in its .json), with
  `ISLAND_EPS` slack (float32 UVs: a sleeve's seam fell outside its island and tore).
- **Weights**, applied after the nearest-skin pass: a shirt's trunk, collar and tie and a
  waistcoat take none of his arms'; a sleeve takes only its own arm's past `SLEEVE_OWN_T` of
  the upper arm; a trouser leg only its own leg's and the pelvis'. (Weighted from the nearest
  skin alone, sleeve and side stretched into sheets when he raised his hands, aimed or sat.)
- Pushed off **his own** skin: sleeves off his arms', the rest off his trunk's and legs' (the
  warp swings his arm in through the shirt's side); the collar and tie not at all (`NECK_PARTS`).
- `neck_ring --collar=made` pushes the collar out of the bust's neck and never cuts it.

## 5. How it's judged

The game's poses first: `xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/people_lineup.gd
-- --out=DIR --ids=bold_cowboy_vest_layered,bold_cowboy_made_layered --poses=stand,hands_up,sit,aim,crouch --hatless`.
The lab in any pose with layers hidden (`--pose=hands_up --hide=Skin_whole,...`) says which layer
a defect is in. Beside his pictures at equal height (`s3_stand_vs_pictures.png`, a line every 5%).

## 6. Known (2026-10-18; sheets `s3_*`)

- His knees and calves are wider than the pictures' (0.099 of his height at the knee against
  0.079): Rodin's legs are bulkier than the pictured man's. The head reads a little narrow
  (0.121 across the hair against 0.132): his painted hair is thin at the sides.
- Grey-brown smears on the upper sleeves and shoulders from the side pictures (their outlines
  fit at 0.62); the collar's back takes the fill (hair covers it in the back picture); the tie's
  ends run past its painted bow; no lapel notch.
- In the game's stand his arms hang ~10° (the pictures' 21°): gameplay's pose (`human_body.gd`
  POSES), noted, not changed.
- Lighting (the clothes render darker than their textures) is art's.
- Next: the coat man (`bold_cowboy_layered`): the coat as a made garment (the trunk tube further
  out, sleeves of its own, lapels and collar, the skirt draped from his hips).
