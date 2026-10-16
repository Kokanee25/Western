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
- **His clothes** (`bold_cowboy_coat`, `bold_cowboy_trousers`): cut from Rodin's dressed model of
  the same man, each its own mesh (coat off, holes, blood work as for any garment).
- **His hands:** MakeHuman's (CC0), its fingers the game's finger pieces (they curl, grip and come
  off), in his hand's colour.

## 1. What Sean makes (ChatGPT, free)

Square pictures, plain grey ground, flat even light, standing upright, arms a little away from
his sides, feet a little apart, full figure head to feet; front, facing the picture's left,
facing its right, from behind:
- **Plain, in boxers:** in plain cream, old-looking boxer shorts and nothing else, bare-headed →
  `docs/concept/style/factory/<man>_body/{front,left,right,back}.png` (Rodin's shape).
- **Painterly, in boxers:** the same four in the painterly style →
  `docs/concept/style/factory/<man>_body/painterly/` (his body's paint).
- **Dressed:** the four dressed (coat, vest, shirt, tie, trousers, boots), painterly →
  `docs/concept/style/factory/<man>_dressed/` (his clothes' shape and colour). A plain flat backdrop
  helps: the bold cowboy's dark, glowing one defeated `body_paint.py`, so his clothes keep
  Rodin's own colours.
- **His five head-and-shoulders portraits** and four plain head pictures, as `RECIPE.md` §1.

## 2. His entries

- `assets/people/portrait.json` `men`: `<man>_body` and `<man>_dressed` (pictures only; the
  workflow reads them), and his head (`<man>_painterly_lit` for the bold cowboy: `fidelity`
  `patches` "none", `unsquare` 0, `delight` 0.15; see that entry).
- `assets/people/people.json` `people.<man>_body`:
  ```json
  "source": "rodin", "rodin": "test/<man>_body_rodin",
  "shoulders": 1.10, "own_fingers": "skinned",
  "tris": {"skin": 30000, "head": 10000}, "outfit": {},
  "pieces": {"coat": "<man>_coat", "trousers": "<man>_trousers"}
  ```
  Insert it by hand (a `json.dumps` rewrite reformats the whole file).

## 3. Making him (the workspace as `RECIPE.md` §3; MakeHuman once: `python3 tools/blender/fetch_makehuman.py`)

1. **Two Rodin models ($1.60 each, the only paid steps):** Actions → People → `style: rodin`,
   `characters: <man>_body`, then `<man>_dressed`. An id ending `_body` or `_dressed` is built
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
   `~/bpyenv/bin/python tools/characters/twin_pieces.py --body=<man>_body --dressed=<man>_dressed --out=<man>`
   → `assets/people/tripo/<man>_{coat,trousers}.glb` + `.json`. Good: "twin laid on the body:
   scale ~1.0, turn ~1 deg", each sleeve turned ~10 deg.
5. **The fit:** `~/bpyenv/bin/python tools/blender/fit_tripo.py --only=<man>_body`
   → `assets/people/<man>_body.glb` (+ `_skin.png`, `_coat.png`, `_trousers.png`, `.json`). The
   report's `shoulders`, `own_fingers` (palm and finger triangles a side), `piece_coat`
   (`pushed_out_after_warp`, `weights_from_skin`) and `skin_tucked` say what it did.
6. **His head on, through the ring:**
   `~/bpyenv/bin/python tools/characters/neck_ring.py --body=<man>_body --head=<head> --out=<man>_layered --head_scale=0.92`
   → `assets/people/<man>_layered.glb` (+ textures, `.json` with `neck_ring`).
7. **Import, test, look:** `godot --headless --import`; `test_bodies`; then the lab:
   ```sh
   bash tools/characters/lab_run.sh build/l.log --out=build/l --id=<man>_layered --turns=0,-45,-90,180 \
       --lights=neutral,warm --materials=game --hat=none --fov=35 --dist=3.4 --aim=1.0 --tag=full
   ```
   (`tools/characters/lab_run.sh` ends the lab when it hangs on quit.)
   `--hide=Skin_whole` (or `Coat_whole`, ...) draws him without a mesh: a garment seen alone.

The whole chain from step 4 runs from the repo alone (checked 2026-10-15 with `build/` out of the
way: the same man, triangle for triangle).

## 4. The numbers (and why)

- `shoulders` 1.10 (people.json): his shoulders were 2.4 head-widths in the coat, now 2.9 (Sean:
  "shoulders aren't broad enough"). Arms out 26 mm at the shoulder, nothing at the wrist; no
  joint moves (the hitboxes are the anatomy's).
- `--head_scale=0.92`: his head was 1/7.2 of his height, now 1/7.7 (Sean: "a bit too big").
- `own_fingers: "skinned"` (docs/briefs/skinned-hands.md; Sean: "Let's do the skinned hand"):
  MakeHuman's hand whole on each arm (`mh_hand.skinned`): fitted by an affine through his wrist
  and four finger knuckles (the thumb where MakeHuman has it), fingers `CHUNK` thicker, skinned
  to 15 finger bones a hand (`finger_<finger>_<side>_<0..2>`, resting at MakeHuman's own joints,
  blended `JOINT_BLEND` across each joint). `fit_tripo.skinned_hands` cuts his arm and the hand
  along one plane, tapers his forearm in to meet it and joins the rings (as the neck ring does),
  paints it (`mh_hand.paint`, his forearm's colour near the wrist) into free squares of his
  texture, and exports the finger bones in his armature and their rests in his report
  (`finger_bones`). In the game (`HumanBody._add_finger_bones`, `_pose_fingers`) each finger bone
  takes its finger node's bend about its own joint, so the hand curls, grips the revolver and
  loses a finger (the bones shrink to the knuckle; the drawn finger flies) as before; the drawn
  fingers are hidden. Earlier tries, kept as options: `own_fingers: true` (his own Rodin fingers
  in rigid pieces, `fingers.py`) and `"makehuman"` (MakeHuman's in rigid pieces): both read as a
  wooden doll's. Round two (Sean: "keep fixing them up"): the hand `HAND_SCALE` bigger about
  the wrist and the fingers `CHUNK` thicker (his paintings' hands are big working hands); a
  relaxed idle curl (`HumanBody.RELAXED_BEND`: each joint bent at least that much, the game's own
  curl past it); painted in his repainted skin's colour (`MATCH` of his forearm's), laid in flat
  planes (`_planes`), lighter knuckles and darker creases (`KNUCKLE_R`). Sheets
  `c7_skinned_hands.png`, `c8_hands_round2.png`. Round three (Sean: "his hands seem like
  they're melting into the jacket", "there's more than one hand"): cloth that isn't a sleeve
  takes none of his arms' weights (`Piece.weights_from_skin`: the skirt and trousers by his hand
  had taken the hand's and swung with it); `Piece.clear_hands` drops a sleeve's cloth `CUFF_PAST`
  beyond his wrist's cut and moves the skirt behind his hand, smoothly; `body_paint.py` takes no
  picture's colour of the wrong kind (skin or cloth, `cloth_like`) or the backdrop's grey (the
  side pictures' hands, hanging on his shorts, had been painted on his hips). Sheet
  `c9_hands_clear.png`. Then his fist (`HumanBody.FIST_GAIN`: a skinned hand's joints bend more
  than the finger nodes, whose full curl is a loose claw on a whole hand; `THUMB_ACROSS`: his
  thumb folds across the fist, not into his palm). Sheet `c10_fist.png`.
- The neck ring (`neck_ring.py`): 3 cm under his chin; his head's edge pulled onto it over 4.5 cm;
  his face's skin matched to the body's; the white collar under his jaw repainted to skin.
- Clothes: `twin_pieces.py` CLEAR 11 mm out of his skin; `fit_tripo` pushes again after the warp
  (12 mm), weights each garment point from the skin under it, and tucks his skin 12 mm under his
  garments (this man's skin only).

## 5. Known

- His coat is darker and more mottled than his pictures (Rodin's own colours).
- A light band at his nape (his dressed twin's hair over the collar).
- His hands' paint is plainer than his face's (his forearm's colour, shadow, nails).
- His skin is tucked under his coat: with the coat taken off his arms look rough.
- The vest and shirt are painted on the coat (one layer).
- Only his head and skin are drawn in the painted look in the game so far (`<pid>_paint.json`,
  `RECIPE.md`); the layered man isn't wired to it yet.
