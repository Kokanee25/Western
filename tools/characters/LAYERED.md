# Recipe: the layered man (base body, his head through the neck ring, his clothes as pieces)

The bold cowboy built this way is **`bold_cowboy_layered`** (Sean, 2026-10-15: "it looks way
better"; "I don't want this guy to get deleted or disappear by accident"). Bookmark branch:
`look/layered-cowboy-2026-10-15`. The brief is `docs/briefs/layered-people.md`; the approved
portrait route for heads alone is `RECIPE.md`, and this one builds on it.

What he is, outside in:
- **A base body** in plain cream boxer shorts (`bold_cowboy_body`): Rodin's whole man from four
  plain pictures, painted from four painterly boxer pictures, fitted to the game's skeleton, his
  shoulders broadened 10%.
- **His head** (`bold_cowboy_painterly_lit`): the painterly bust from his five portraits
  (`RECIPE.md` route), laid on the body's own head and joined through **the neck ring**, 8% smaller
  than the body's own head.
- **His clothes in layers** (roadmap 1.3, 2026-10-16): shirt (with its tie), vest and trousers
  (`bold_cowboy_under_*`) cut from Rodin's model of him without his coat, and his coat
  (`bold_cowboy_coat`) from Rodin's model of him dressed; each its own mesh (holes, blood work as
  for any garment), one inside another.
- **Two outfits of one man** (the game never takes a coat off): **`bold_cowboy_layered`** in his
  coat (`bold_cowboy_body`: the shirt's sleeves and whatever of vest and shirt the coat covers cut
  away) and **`bold_cowboy_vest_layered`** without it (`bold_cowboy_vest_body`: vest, whole shirt,
  trousers). Sheet `docs/style_test/layered-2026-10-15/d2_layers.png`.
- **His hands:** MakeHuman's (CC0) whole, skinned to the game's finger bones (they curl, grip and
  come off), painted in his skin and his light, joined smoothly at the wrist.

## 1. What Sean makes (ChatGPT, free)

Square pictures, plain grey ground, flat even light, standing upright, arms a little away from
his sides, feet a little apart, full figure head to feet; front, facing the picture's left,
facing its right, from behind:
- **Plain, in boxers:** in plain cream, old-looking boxer shorts and nothing else, bare-headed →
  `docs/concept/style/factory/<man>_body/{front,left,right,back}.png` (Rodin's shape).
- **Painterly, in boxers:** the same four in the painterly style →
  `docs/concept/style/factory/<man>_body/painterly/` (his body's paint).
- **Without his coat:** the four again in shirt, vest, tie, trousers and boots, painterly, on plain
  grey with his arms clear of his sides (the prompt: Sean's chat, 2026-10-16; his dressed front
  picture attached so it's the same man) → `docs/concept/style/factory/<man>_vest_dressed/`
  (his vest, shirt and trousers). A little blockiness in the cloth is fine (Sean).
- **Dressed:** the four dressed (coat, vest, shirt, tie, trousers, boots), painterly →
  `docs/concept/style/factory/<man>_dressed/` (his clothes' shape and colour). A plain flat backdrop
  helps: the bold cowboy's dark, glowing one defeated `body_paint.py`, so his clothes keep
  Rodin's own colours.
- **His five head-and-shoulders portraits** and four plain head pictures, as `RECIPE.md` §1.

## 2. His entries

- `assets/people/portrait.json` `men`: `<man>_body`, `<man>_dressed` and `<man>_vest_dressed`
  (pictures only; an id ending `_dressed` is built whole; the
  workflow reads them), and his head (`<man>_painterly_lit` for the bold cowboy: `fidelity`
  `patches` "none", `unsquare` 0, `delight` 0.15; see that entry).
- `assets/people/people.json` `people.<man>_body`:
  ```json
  "source": "rodin", "rodin": "test/<man>_body_rodin",
  "shoulders": 1.10, "own_fingers": "skinned",
  "tris": {"skin": 30000, "head": 10000}, "outfit": {},
  "pieces": {"coat": "<man>_coat", "vest": "<man>_under_vest",
             "shirt": "<man>_under_shirt", "trousers": "<man>_trousers"}
  ```
  and `people.<man>_vest_body` the same but `"pieces"` without the coat, its trousers
  `<man>_under_trousers`, and
  `"paint": "<man>_body"` (his body's repaint shared, not copied). Insert both by hand (a
  `json.dumps` rewrite reformats the whole file).

## 3. Making him (the workspace as `RECIPE.md` §3; MakeHuman once: `python3 tools/blender/fetch_makehuman.py`)

1. **Three Rodin models ($1.60 each, the only paid steps):** Actions → People → `style: rodin`,
   `characters: <man>_body`, then `<man>_dressed`, then `<man>_vest_dressed`. An id ending `_body` or `_dressed` is built
   whole, not as a bust (`people.yml`). Pull: `assets/people/tripo/test/<man>_{body,dressed}_rodin.glb`.
2. **His head:** `RECIPE.md` §4 steps 1-2 for `<man>_painterly_lit` (a bust, $1.60 if not made
   yet; the paint). Then keep it (build/ is wiped with the workspace):
   ```sh
   ~/bpyenv/bin/python -c "import numpy as np,shutil; m=np.load('build/rodin_portrait/<head>_mesh.npy',allow_pickle=True).item(); np.savez_compressed('assets/people/heads/<head>_mesh.npz',**{k:np.asarray(v) for k,v in m.items()}); [shutil.copy('build/rodin_portrait/<head>_'+s,'assets/people/heads/') for s in ('paint.png','report.json')]"
   ```
3. **His body's paint:**
   ```sh
   P=docs/concept/style/factory/<man>_body/painterly
   ~/bpyenv/bin/python tools/characters/body_paint.py --body=<man>_body \
       --views=front:$P/front.png,left:$P/left.png,right:$P/right.png,back:$P/back.png --unsquare=9
   ```
   → `assets/people/tripo/<man>_body_color.png`. Check `build/body_paint/<man>_body_*_fit.png`
   (the outline over each picture; side views ~0.86 overlap is good). Its log's "his shorts from
   ... to ... m" should span his shorts (-0.19 to 0.15 for the bold cowboy).
4. **His clothes.** The chain from here, in this order after any change (the bold cowboy's
   exact commands; `P=docs/concept/style/factory/bold_cowboy_vest_dressed`):
   ```sh
   # 1. the coatless twin painted from his pictures (only when the painting changes)
   ~/bpyenv/bin/python tools/characters/body_paint.py --body=bold_cowboy_vest_dressed --dressed --unsquare=1 \
       --views=front:$P/front.png,left:$P/left.png,right:$P/right.png,back:$P/back.png
   # 2. the garments cut (shirt+tie, vest, trousers from the coatless twin; the coat from the coated)
   ~/bpyenv/bin/python tools/characters/twin_pieces.py --body=bold_cowboy_body --dressed=bold_cowboy_vest_dressed \
       --out=bold_cowboy_under --split=layers --painted
   ~/bpyenv/bin/python tools/characters/twin_pieces.py --body=bold_cowboy_body --dressed=bold_cowboy_dressed --out=bold_cowboy
   ```
   → `assets/people/tripo/<man>_coat.glb` (and `_trousers`) and `<man>_under_{shirt,vest,trousers}.glb`
   + `.json` (`twin`, `painted`). Good: "twin laid on the body: scale ~1.0, turn ~1 deg";
   `--split=layers` also lays his sleeves on the body's arm bones joint to joint; "his coat's
   collar kept above the head's cut: ~40 triangles" (the coat's collar behind his neck).
5. **The fit (both bodies):**
   ```sh
   ~/bpyenv/bin/python tools/blender/fit_tripo.py --only=bold_cowboy_body
   ~/bpyenv/bin/python tools/blender/fit_tripo.py --only=bold_cowboy_vest_body
   ```
   → `assets/people/<man>_body.glb` (+ `_skin.png`, `_coat.png`, `_trousers.png`, `.json`). The
   report's `shoulders`, `own_fingers` (palm and finger triangles a side), `piece_coat`
   (`pushed_out_after_warp`, `weights_from_skin`, `tails_on_pelvis`), `painted_under_garments`
   and `skin_tucked` say what it did.
6. **His head on, through the ring** (right after the fit: it reads `build/bare_skin/`):
   ```sh
   ~/bpyenv/bin/python tools/characters/neck_ring.py --body=bold_cowboy_body --head=bold_cowboy_painterly_lit \
       --out=bold_cowboy_layered --head_scale=0.92 --collar=smooth
   ~/bpyenv/bin/python tools/characters/neck_ring.py --body=bold_cowboy_vest_body --head=bold_cowboy_painterly_lit \
       --out=bold_cowboy_vest_layered --head_scale=0.92 --collar=plain
   ```
   (`--collar=plain` for the coatless man: his own collar smoothed and cut where it stands,
   higher in front; lifted and levelled (`smooth`) it read as a flat band again (Sean,
   2026-10-17). `--collar=smooth` for the coat man: his twin's own collar and tie knot smoothed,
   its top drawn up to under his jaw and levelled, every garment pushed out of the bust's neck;
   `none` leaves the garments as the fit made them; `built` is the old stand collar, "a neck
   brace") → `assets/people/<man>_layered.glb` (+ textures, `.json` with `neck_ring`).
   **His head's textures must not change:** `assets/people/bold_cowboy_*layered_head.png` are
   byte for byte the approved ones; `neck_ring` keeps an existing one (its neck fade and skin
   match read the fitted skin near the ring, which moves a little with the clothes' tuck, and
   the whole head drifted a level); `--head_png=write` repaints it (a new man, or a new head).
   Check with `md5sum` against main's.
7. **Import, test, look:** `godot --headless --import`; `test_bodies`; then the lab:
   ```sh
   # the whole man (tools/characters/lab_run.sh ends the lab when it hangs on quit)
   bash tools/characters/lab_run.sh build/l.log --out=build/l --id=<outfit> --turns=0,90,180 --lights=neutral \
       --materials=game --hat=none --fov=6 --dist=20 --aim=0.95
   # head and shoulders (add --lights=neutral,warm for lamp light)
   bash tools/characters/lab_run.sh build/l.log --out=build/l --id=<outfit> --turns=0,90,180 --lights=neutral \
       --materials=game --hat=none --fov=16 --dist=2.0 --aim=1.55
   ```
   `--hide=Skin_whole` (or `Shirt_whole`, `Vest_whole`, `Coat_whole`) draws him without a mesh:
   which layer a defect is in.
   The pose check: `xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/people_lineup.gd
   -- --out=build/pc --ids=<man>_layered,<man>_vest_layered --poses=stand,sit,hands_up,crouch,aim --hatless`.
   Each fix gets a before/after sheet against his pictures in `docs/style_test/layered-2026-10-15/`
   (`d11` onward); `cloth_detail.py` gives the numbers for the cloth.

The whole chain from step 4 runs from the repo alone (checked 2026-10-15 with `build/` out of the
way: the same man, triangle for triangle).

## 4. The numbers (and why)

- `shoulders` 1.10 (people.json): his shoulders were 2.4 head-widths in the coat, now 2.9 (Sean:
  "shoulders aren't broad enough"). Arms out 26 mm at the shoulder, nothing at the wrist; no
  joint moves (the hitboxes are the anatomy's).
- `--head_scale=0.92`: his head was 1/7.2 of his height, now 1/7.7 (Sean: "a bit too big").
- `own_fingers: "skinned"`: his hands (docs/briefs/skinned-hands.md; Sean, 2026-10-15/16; sheets
  `c7` to `c12` in `docs/style_test/layered-2026-10-15/`, `c12_hands_finished.png` the last):
  - **The hand** (`tools/blender/mh_hand.py` `skinned`): MakeHuman's (CC0) whole, on each arm by
    an affine through his wrist and four finger knuckles (the thumb where MakeHuman has it),
    `HAND_SCALE` 1.15 bigger about the wrist, its fingers `CHUNK` 1.2 thicker (his paintings'
    hands are big working hands); skinned to 15 finger bones a hand
    (`finger_<finger>_<side>_<0..2>`, resting at MakeHuman's joints, blended `JOINT_BLEND`
    across each).
  - **The wrist** (`fit_tripo.skinned_hands`): his arm cut on a plane `WRIST_CUT` short of his
    wrist, the hand `BRIDGE` (3 mm) below it; his forearm tapered in (`ARM_TAPER`,
    `WRIST_SWELL`); the hand's edge drawn onto his arm's (`join_ring`); both laid on one smooth
    S of a profile across the join (`mh_hand.smooth_wrist`, `WRIST_ARM` up, `WRIST_HAND` down);
    the strip between the cuts stitched (`_stitch`, each triangle one colour of his arm's); and
    everything at the join bending exactly as his arm's cut edge does, easing into the hand's
    own weights over `SEAM_BLEND` (`finger_weights`). Without these: a ledge, a crease, a
    hairline of background and spikes in any pose.
  - **Its paint** (`mh_hand.paint`, into the biggest free squares of his texture, up to
    `fit_tripo.HAND_SQUARE_MAX` 0.09, ~184 of his 2048 texels a side): his repainted skin's
    colour (`MATCH` of his forearm's); shadow from its own shape; his key light laid in as three
    soft tones (`KEY_TONES`, the darks warmer, the light pink), growing in down the hand over
    `LIGHT_IN`; flat planes (`_planes`); lighter knuckles, darker creases (`KNUCKLE_R`); a nail
    on each finger (`NAIL_LEN`, `NAIL_WIDE`; the thumb's facing its own way) kept crisp; and
    fading from his forearm's own colour round the wrist over `WRIST_FADE`.
  - **In the game** (`src/bodies/human_body.gd`, gameplay's file, Sean's OK):
    `_add_finger_bones` puts the finger bones in his skeleton, `_pose_fingers` bends each by
    its finger node's angle about its own joint: a relaxed curl at rest (`RELAXED_BEND`,
    `RELAXED_THUMB`), `FIST_GAIN` more than the node (the game's full curl is a loose claw on a
    whole hand), the thumb leaning `THUMB_ACROSS` 45 deg the `THUMB_ACROSS_SIGN` way so it
    folds across the fist and lies along the revolver. A finger shot off: its bones shrink to
    the knuckle and the drawn finger flies. The drawn cylinder fingers are hidden.
  - Tried and kept as options: `own_fingers: true` (his own Rodin fingers in rigid pieces,
    `fingers.py`) and `"makehuman"` (MakeHuman's in rigid pieces): both read as a wooden doll's.
  - Look at them close with the lab's `--aimx` (sideways), e.g. his right wrist from in front:
    `bash tools/characters/lab_run.sh build/z.log --out=build/z --id=<man>_layered --turns=0
    --lights=neutral --materials=game --hat=none --fov=8 --dist=1.2 --aim=0.86 --aimx=-0.24
    --hide=Coat_whole,Trousers_whole`; `--curl=r:1,l:1` a fist, `--draw` the revolver,
    `--sever=index_l` a finger off.
- His clothes off his hands (Sean: "melting into the jacket"): cloth that isn't a sleeve takes
  none of his arms' weights (`Piece.weights_from_skin`); `Piece.clear_hands` ends a sleeve
  `CUFF_PAST` beyond his wrist's cut and moves the coat's skirt smoothly behind his hand.
- His body's paint (Sean: "more than one hand"): `body_paint.py` takes no picture's colour of
  the wrong kind (skin or cloth, `cloth_like`; between his shorts' waistband and hem all is
  cloth but his arms) or the backdrop's grey: the side pictures' arms hang against his shorts
  where Rodin's are held out, and painted a hand on his hips.
- The neck ring (`neck_ring.py`): 3 cm under his chin; his head's edge pulled onto it over 4.5 cm;
  his face's skin matched to the body's; the white collar under his jaw repainted to skin. His
  shirt's collar (`--collar=smooth`) smoothed, lifted to 25 mm over the ring (5 mm under his
  chin) all round and levelled there; the coat's cut 30 mm over it, the vest's 12.
- Clothes: `twin_pieces.py` CLEAR 11 mm out of his skin; `fit_tripo` pushes again after the warp
  (12 mm), weights each garment point from the skin under it, and tucks his skin 12 mm under his
  garments (this man's skin only).
- His layers (roadmap 1.3; in `fit_tripo`): his arms drawn in under the shirt's sleeves by one
  factor an arm (`_arms_in_sleeves`; point by point they crumpled into shards) and his torso
  narrowed under the shirt (`_trunk_in`, `TRUNK_IN_X`, `TRUNK_IN`); every layer's sleeves
  weighted alike by their place along the arm (`weights_from_skin`, the arm's own profile), the
  shirt's and vest's body cloth none of his arms' (no wing with his hands up), the shirt's sleeve
  cut from its side below his armpit (`ARMPIT_DROP`); garments tucked one under another in
  `LAYERS` order (`tuck_layers`); in a coat, the shirt's sleeves and what of vest and shirt the
  coat covers (ahead, out from his middle, by his armholes: `COVER_REACH`, `ARMHOLE_R`) cut away;
  under a shirt his torso's and upper arms' skin painted the shirt's colour (`paint_under_shirt`).
- His clothes' paint (painted illustration, DESIGN.md §4): a twin piece's texture cut from
  Rodin's own (the coat) is smoothed within its own UV islands (`paint_cloth`: a median of
  `CLOTH_MEDIAN` texels, a soft blur), and toned by people.json `cloth.<shape>`: `light` and
  `chroma` (the coat 1.35 and 1.6: it came out darker and greyer than his painting's), `mottle`
  (the share of Rodin's camouflage blotches, between `MOTTLE_FINE` and `MOTTLE_WIDE` texels, taken
  out: coat 0.7, trousers 0.6). Sheet `d3_cloth.png`. A piece painted from his pictures
  (`twin_pieces --painted`, the piece's json `painted`) gets no median: it is as smooth as they
  are. Every garment's texture is written at his skin's density (2048 a side, `SQUARE_TEXELS` of
  his model's 4096 texels, ~1.8 mm on him; at 1024 the vest's pattern lost its edges).
  **Measure before changing** (`tools/characters/cloth_detail.py`: each stage of the texture
  re-projected into a picture's own frame, with a render laid over it; the edge strength and
  the contrast in bands of 3-100 mm as shares of the picture's).
- His clothes' defects, by cause (Sean, 2026-10-16; sheets `d5_no_coat_fixed.png`,
  `d6_coat_fixed.png`, silhouettes `d4_coat_silhouette.png`):
  - Collar missing (geometry: cut at CHIN, and the bust's neck sat outside it): the twin's collar
    kept to `twin_pieces.COLLAR_TOP`; `neck_ring.collar_out` pushes garments out of the bust's neck
    and `stand_collar` builds the shirt's stand-up collar round it (in his shirt's lightest white)
    in place of the twin's ragged one. His face is matched to his bare skin
    (`build/bare_skin/`, written by the fitter), not his shirt-painted neck.
  - Clothes softer than main's (texture: Sean, 2026-10-16, against the face-rig session's picture):
    `paint_cloth`'s median of 7 texels and blur kept 30-45% of the cloth's fine detail; now a
    median of 3 and no blur (the coat's detail as main's). The coat's tone (`light`, `chroma`,
    `mottle`) had greyed its painted shirt front and tie: `cloth.coat.keep_ends` leaves what is
    painted white or black untoned. The built collar reads as a neck brace close up (the jaw
    through it): the coated man went without it (`--collar=none`, until 2026-10-17: now `smooth`
    too); the coatless man kept it a while, his twin's own collar and tie knot being ragged fins
    in Rodin's model (sheet `d7_cloth_crisp.png`).
  - Barrel chest (two causes; sheet `d8_chest.png`): the coatless twin's arms hang against his
    waist, so laying the sleeves on the body's arms took ~560 of the waistcoat's points with them
    and flared it from armpit to hem (`twin_pieces`: cut into layers, what is drawn darker than
    `ARM_DARK_L` is never arm); and `shoulders` widened his whole upper chest (now only from
    `BROADEN_LOW` 12 cm under the shoulder joints up). His waist is now his picture's (17.6% of his
    height against 21%).
  - Collar (geometry): the coatless twin's collar and tie knot are thin slivers. The built band
    read as "a flat straight piece". Now `neck_ring --collar=smooth` Taubin-smooths his own
    collar (`COLLAR_SMOOTH` 9 cm under the ring) and lets it stand to his jaw in front, lower
    behind (`COLLAR_SMOOTH_UP`, `_BACK`), and his neck under it is painted his shirt's light
    colour, not its average grey (`fit_tripo.UNDER_SHIRT_LIGHT`, his neck only: lighter on his
    chest it showed through a coat's edges). Sheet `d9_collar.png`.
  - His clothes painted from his four coatless pictures (Sean, 2026-10-17): `body_paint --dressed`
    paints the coatless twin's texture from them (lined up by outline; each texel takes only
    picture colour as light or dark as Rodin's there, `DRESSED_LIGHT`, or the waistcoat's brown
    fell on his sleeves' edges); `twin_pieces --painted` writes the garments with it, cut as ever
    by Rodin's own colours. Sheet `d10_painted.png`.
  - Shards on shirt and vest (segmentation: colour, triangle by triangle): pieces under
    `MIN_PART` triangles folded into the garment round them.
  - Sawtooth hem and a gap at the waistband (segmentation and the cut): the vest's hem on a
    smooth curve round his waist (`HEM_BINS`, `HEM_BAND`); each garment runs `UNDERLAP` under the
    edge of the one over it.
  - Arm through the sleeve (overlap: the sleeve dented by the layer tuck): sleeves aren't tucked
    under trousers or vest; `_sleeves_round_arms` keeps a sleeve `SLEEVE_ROOM` outside his arm.
  - Orange skin between garments (texture: his skin under the shirt unpainted where the twin's
    neck reaches into his head's region): painted the shirt's colour up to his collar.
  - Trousers near black (texture and light): `cloth.trousers.L` 24 (his pictures' 20-26); the
    lab's light still renders dark cloth at about half its texture's lightness (art's lane).
  - In a coat he wears his coat's own trousers (`bold_cowboy_trousers`): the coatless ones' top
    showed in the coat's opening, which has the dressed twin's trousers painted in it.
  - Blotchy cloth close up (2026-10-17; sheet `d12_density.png`, numbers in
    `cloth_detail.py`'s json): measured in his front picture's frame, the painted twin texture
    keeps 0.91 of the picture's edge strength on the vest, the piece written at 1024 a side
    0.79 (the 3 mm band 0.71), and the game's render 0.56. Rodin's lumpy surface and the view
    blend add no contrast at 1-10 cm (the render's bands there are the texture's), so the
    "blotches" are the picture's own pattern with its edges lost. Now written at 2048 (1.8 mm a
    texel, the skin's density) and without the median on painted cloth: 0.88 (3 mm band 0.84),
    the render 0.59. What the render loses past that is the light and the shader (the vest and
    trousers render dark and flat: art's).
  - Light flecks at his sleeves' edges (2026-10-17; sheet `d11_flecks.png`): three causes in
    `body_paint --dressed`. The figure mask's outermost pixel ring is half backdrop (Lab ΔE ~18
    from it) and was sampled (now `BG_ERODE` 2 px in); the backdrop's luma (0.405-0.435) straddles
    `DRESSED_LIGHT` 0.42, so it passed as shirt in two pictures and as waistcoat in the other two
    (now a colour within `BG_DE` 12 of the backdrop's is backdrop); and what no picture sees (a
    sleeve's inside) was filled from the nearest painted texel of any UV island (now its own:
    `island_fill`). The side pictures line up 0.82 by outline because his arms hang nearer his
    sides in them than in Rodin's twin; the twin's sleeve edges then project onto the backdrop
    or the vest. What is left at his armpits is geometry: the slit where the sleeve is cut from
    the shirt's side (`ARMPIT_DROP`) shows his skin under it, painted the shirt's light colour
    since the skin is painted by the garment over it (`paint_under_garments`).
  - The collar low and plain (2026-10-17; sheet `d13_collar.png`): Rodin's coatless twin has no
    collar above the ring (3 cm under his chin; no white triangle higher, measured by height and
    radius round his neck), where his pictures' stands to his jaw, so no cut or smoothing could
    raise it. `neck_ring --collar=smooth` now draws his own collar up (`lift_collar`: at 24
    angles round his neck its top is brought to `COLLAR_OVER` above the line, everything from
    `COLLAR_LIFT_FROM` under the ring rising with it on a quadratic ease; his tie's knot half
    way) and levels it there (`top_height`: `COLLAR_SMOOTH_UP` 25 mm over the ring, 5 mm under
    his chin, all round; the faces were cut there before, a sawtooth a face deep), then pushes
    every garment out of the bust's neck. The coat man uses it too (he was `none`): the white
    slivers beside his neck were his shirt's collar standing out of the coat's, which
    `twin_pieces` cut at CHIN 6 cm under his chin; it now keeps the coat's collar behind his
    neck (`COAT_COLLAR_*`: the coat's brown, near the neck's axis and behind it, up to his jaw;
    a looser rule took his jaw and beard for collar, a tan bib over his chin) and
    `COLLAR_COAT_UP` cuts it 30 mm over the ring.
  - Lines of his skin at his clothes' edges (2026-10-17): his skin under his clothes was painted
    his shirt's colour everywhere, so it showed white at a coat's edges and, in the shirt's
    median cream, tan in the slits between his sleeves and his vest. `paint_under_garments`
    paints each skin triangle the colour of the garment over it (a ray out from the skin: the
    furthest garment within `UNDER_REACH` is the one over it; the shirt's light colour, the
    others' median); his neck the shirt's light colour (`UNDER_SHIRT_NECK`, within
    `UNDER_NECK_R` of the neck joint's axis: the joint sits at his shoulder line, and without
    the radius his shoulders were "neck").
  - The coat's vent open behind (2026-10-17; sheet `d14_coat.png`): the fitted coat's skirt is
    closed at rest (rasterised from behind); posed, its tails went apart with his legs because
    its weights came from the skin round his hip joints, which carry a share of each thigh's.
    `fit_tripo.tails_on_pelvis`: below `TAILS_BELOW` under his hips and behind him (within
    `TAILS_FULL` degrees of straight behind, eased out to `TAILS_NONE`) the skirt's leg weights
    go to his pelvis; its front and sides keep their thighs' share (on his lap when he sits).
  - The coat's sides up with his hands (the wing): its sleeves and sides are fused in Rodin's
    model and its body cloth takes his arms' weights. Tried: the sleeve cut from the side below
    his armpit and the body cloth weighted off his arms, as the shirt's (`COAT_SIDES_CUT`,
    `weights_from_skin`); the wing went, but it split Rodin's fused sleeve-and-side blob: each
    upper sleeve lost its inner half (skinny arms) and the side cloth sat where the arm then
    hung (Sean: "the arm and body meshing together"). Off: the wing stays, with the tails on his
    pelvis. The real fix needs the sleeves modelled apart from the sides (a coatless twin's arms
    held out, or a cut that rebuilds the sleeve's inner half).
  - Cream patches on the coat's sides and lines at its seams: what lies under its cut sides,
    showing through where the two surfaces meet. Measured on the game's coat texture, the side
    faces' texels are 99.6% dark wool, so not the coat's paint (hiding the shirt or the skin
    alone left the patches: each is cream there). Two things under it: his skin where no garment
    lay straight out from it (`paint_under_garments`: at his ribs the coat's side hangs up and
    away in the A-pose; now the nearest garment within reach decides, else the shirt's colour),
    and the shirt's rib triangles the cover rule kept (a ray out from his middle or straight
    ahead missed the coat's side there; now at his sides, beyond `COVER_SIDE_X`, the coat anywhere
    within `COVER_REACH` covers). Rodin's cream inside the fused sleeve-and-side (a few thousand
    texels) is painted wool too (`COAT_SIDE_WHITE`, `COAT_SIDE_SPREAD`, beyond `COAT_SIDE_X`).
    Both stay with the sides cut off again: they are what showed as the white lines at the
    sleeves' seams.
  - The collar's back tan-brown once lifted: the twin's collar behind his neck took the back
    picture's hair and neck (the picture's hair hangs over it), and the collar's top at its nape
    stayed low (the lift read the twin's spikes there as its top: now `COLLAR_TOP_PCT`, the
    70th percentile). `whiten_collar_back` paints the lifted faces behind his neck the shirt's
    white; its back stands `COLLAR_SMOOTH_BACK` 40 mm over the ring, up under his hair.
  - White teeth at the vest's armholes (2026-10-17, sheet `d16_armholes.png`): the shirt, not
    the vest's edge (`--hide=Shirt_whole` took them away; smoothing the vest's colour boundary
    round the arm's root, `ARMHOLE_*` in `twin_pieces`, kept for its own sake, changed nothing
    visible). The fitter's cut of the shirt's sleeve from its side below the armpit
    (`ARMPIT_DROP`) leaves the side there in a comb of strips, which stood out beside the vest's
    armhole front and back. **Not fixed yet:** a rule dropping the side's cloth near the arm's bone
    below the armpit (`COMB_T`, `COMB_R`) caught one triangle, so the strips are the sleeve's
    own (`sleeve_of` set), the sleeve's root cut into a comb where its mixed triangles went. Next:
    split or re-weight the mixed triangles at the armpit instead of deleting them, or drop the
    sleeve's strips that reach past the vest's armhole (his skin under them is painted the
    shirt's colour, so a hole there reads as shirt).
  - Sitting and crouching his trousers' seat and the coat's skirt still crumple at the bench
    (linear skinning of a seat folded to 90 degrees: not this recipe's; the pose check shows it).

## 5. Known

- A light band at his nape (his dressed twin's hair over the collar).
- His hands have far fewer texels than his face (184 a side for a whole hand): fine detail
  (tendons, veins) can't show. His forearm's own paint has dark streaks (the pictures' shading),
  and one runs on into his hand on his left wrist.
- His thumb lies along the revolver, a little high on its grip; the revolver sits where the game
  hangs it from the anatomy's hand (gameplay's), not this hand's palm.
- With his hands up his coat's sides still stretch from his arms (the wing; `COAT_SIDES_CUT`
  is off, see the defects); its tails hang from his pelvis.
- Sitting and crouching, his coat's skirt and his trousers' seat crumple at the bench and the
  ground (as before the layers); a few dark specks by his armpits in the coat.
- The coat's front still has the dressed model's vest and shirt painted in its opening's edges
  (the real vest shows in the middle); from the front it hangs a little narrower than the
  painting's.
- Under the coat his trousers render near black, and the vest and trousers render darker and
  flatter than their textures (the lab's light: art's).
- His sleeves' outer edges take the side pictures' colour a little off their place: the
  pictures' arms hang nearer his sides than Rodin's twin's (outline overlap 0.82 against the
  front's 0.87); a per-limb line-up would paint them truer.
- In lamp light his face's colour strength rises from ~37 to ~58 (Lab chroma), as before these
  changes (his face is unchanged: the light is art's).
- Only his head and skin are drawn in the painted look in the game so far (`<pid>_paint.json`,
  `RECIPE.md`); the layered man isn't wired to it yet.

### Second look (2026-10-17, after the fix-up session; sheet `d17_take2.png`)
Kept from the fix-up: the clothes at 2048 with no median on painted cloth, the sleeve-flecks fixes
(`body_paint --dressed`), the coat's tails, sides and its collar. Taken back, both made him worse
than before it (Sean: "why'd he fuck shit up"):
- The coatless man's collar lifted and levelled (`--collar=smooth`) read as the flat band Sean had
  turned down: he has `--collar=plain`.
- Brown-and-cream stripes at his waistcoat's sides: his skin, painted the colour of the outermost
  garment over it (waistcoat brown beside shirt cream, a triangle-sawtooth line between), poked
  out there, and the "comb" cut (`COMB_T`) took away shirt that had covered it. Now the comb cut
  is off and his skin takes a coat's colour only under a coat (`UNDER_COAT_ONLY`), else the
  shirt's median, as before.


## 6. Garments made on the base body (2026-10-18)

**Superseded by `tools/characters/GARMENTS.md`:** the shirt, waistcoat and trousers lofted from his
base body (sleeves of their own, a standing collar, trousers that hang, the three nested by
construction), the base body fitted bare, the boots from the twin. Steps 1-6 above stay for the
cut-twin men in the game today.
