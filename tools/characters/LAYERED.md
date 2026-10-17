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
4. **His clothes:**
   ```sh
   ~/bpyenv/bin/python tools/characters/twin_pieces.py --body=<man>_body --dressed=<man>_dressed --out=<man>
   ~/bpyenv/bin/python tools/characters/body_paint.py --body=<man>_vest_dressed --dressed --unsquare=1 \
       --views=front:<pics>/front.png,left:<pics>/left.png,right:<pics>/right.png,back:<pics>/back.png
   ~/bpyenv/bin/python tools/characters/twin_pieces.py --body=<man>_body --dressed=<man>_vest_dressed \
       --out=<man>_under --split=layers --painted
   ```
   → `assets/people/tripo/<man>_coat.glb` (and `_trousers`, unused now) and
   `<man>_under_{shirt,vest,trousers}.glb` + `.json`. Good: "twin laid on the body: scale ~1.0,
   turn ~1 deg"; `--split=layers` also lays his sleeves on the body's arm bones joint to joint.
5. **The fit:** `~/bpyenv/bin/python tools/blender/fit_tripo.py --only=<man>_body` (and again
   `--only=<man>_vest_body`)
   → `assets/people/<man>_body.glb` (+ `_skin.png`, `_coat.png`, `_trousers.png`, `.json`). The
   report's `shoulders`, `own_fingers` (palm and finger triangles a side), `piece_coat`
   (`pushed_out_after_warp`, `weights_from_skin`) and `skin_tucked` say what it did.
6. **His head on, through the ring** (right after the fit: it reads `build/bare_skin/`) (and the same with `--body=<man>_vest_body
   --out=<man>_vest_layered`):
   `~/bpyenv/bin/python tools/characters/neck_ring.py --body=<man>_body --head=<head> --out=<man>_layered --head_scale=0.92`
   (`--collar=none` for the man in his coat: his coat's twin's collar and tie are clean;
   `--collar=smooth` for the coatless man: his twin's own collar and knot smoothed)
   → `assets/people/<man>_layered.glb` (+ textures, `.json` with `neck_ring`).
7. **Import, test, look:** `godot --headless --import`; `test_bodies`; then the lab:
   ```sh
   bash tools/characters/lab_run.sh build/l.log --out=build/l --id=<man>_layered --turns=0,-45,-90,180 \
       --lights=neutral,warm --materials=game --hat=none --fov=35 --dist=3.4 --aim=1.0 --tag=full
   ```
   (`tools/characters/lab_run.sh` ends the lab when it hangs on quit.)
   `--hide=Skin_whole` (or `Coat_whole`, ...) draws him without a mesh: a garment seen alone.
   The pose check: `xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/people_lineup.gd
   -- --out=build/pc --ids=<man>_layered,<man>_vest_layered --poses=stand,sit,hands_up,crouch,aim --hatless`.

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
  his face's skin matched to the body's; the white collar under his jaw repainted to skin.
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
- His clothes' paint (painted illustration, DESIGN.md §4): every twin piece's texture smoothed
  within its own UV islands (`paint_cloth`: a median of `CLOTH_MEDIAN` texels, a soft blur), and
  toned by people.json `cloth.<shape>`: `light` and `chroma` (the coat 1.35 and 1.6: it came out
  darker and greyer than his painting's), `mottle` (the share of Rodin's camouflage blotches,
  between `MOTTLE_FINE` and `MOTTLE_WIDE` texels, taken out: coat 0.7, trousers 0.6). Sheet
  `d3_cloth.png`.
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
    through it): the coated man goes without it (`--collar=none`); the coatless man still has it,
    his twin's own collar and tie knot being ragged fins in Rodin's model (sheet `d7_cloth_crisp.png`).
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

## 5. Known

- A light band at his nape (his dressed twin's hair over the collar).
- His hands have far fewer texels than his face (184 a side for a whole hand): fine detail
  (tendons, veins) can't show. His forearm's own paint has dark streaks (the pictures' shading),
  and one runs on into his hand on his left wrist.
- His thumb lies along the revolver, a little high on its grip; the revolver sits where the game
  hangs it from the anatomy's hand (gameplay's), not this hand's palm.
- With his hands up his coat's sides stretch from his arms (its sleeves and sides are fused in
  the dressed model; cut or weighted apart they gaped when he stood). The coatless man doesn't.
- Sitting and crouching, his coat's skirt and his trousers' seat crumple at the bench and the
  ground (as before the layers); a few dark specks by his armpits in the coat.
- The coat's front still has the dressed model's vest and shirt painted in its opening's edges
  (the real vest shows in the middle).
- From behind, his coat's skirt parts at the vent and shows his trousers (the painting's hangs
  closed); from the front it hangs a little narrower than the painting's.
- A few white shards round his tie's knot; under the coat his trousers render near black.
- In lamp light his face's colour strength rises from ~37 to ~58 (Lab chroma), as before these
  changes (his face is unchanged: the light is art's).
- Only his head and skin are drawn in the painted look in the game so far (`<pid>_paint.json`,
  `RECIPE.md`); the layered man isn't wired to it yet.
