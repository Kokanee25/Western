# The two tests (2026-10-19): the bold cowboy only

Branch `claude/characters-two-tests` (not merged). Paid calls: **$0** of the $5 (no Rodin, Tripo or
image-model call; Test 1's model is run 89, already paid).

## What each test is

- **The fit's stretch, fixed** (both tests' first step). `tools/blender/fit_tripo.py` fitted a
  hatless dressed man as if hatted: Tripo's joint shares (of a man's height *with* a hat) put his
  neck joint under his shoulders and his hips low, so the trunk's joint-to-joint warp stretched him.
  With people.json `"bare": true` a whole man is now fitted at our skeleton's own shares of its
  height to the crown (`bare_shares`), his hips 4.5 cm over his crotch (`HIP_OVER_CROTCH`, from the
  Oct 14 man: skin 3 cm under our hip joints), his shoulders onto ours with all above them scaled
  as one, his widths at his true height. Men on main fit byte-identically (the key is new;
  `stranger2s` refitted: glb unchanged). Sheet `f1_fit_stretch.png`: 1.875 m → 1.815 m, shoulders'
  top 1.57 → 1.51 m (sloped), a neck, crotch 0.82 → 0.885 m.
  The Oct 14 man (`look/portrait-men-2026-10-14`) is the factory's MakeHuman body with the Rodin
  head; fit_tripo never fitted him, so the fix can't change him. It was checked on the whole
  dressed Rodin bold cowboy (Test 1's body) with the Oct 14 man beside him as the build to match.
- **Test 1: the arms-out bold cowboy kept whole** (`bold_cowboy_whole`). Rodin run 89
  (`bold_cowboy_armsout_dressed`) fitted whole to our 17 bones, his clothes part of his skin,
  nothing cut out; painted from his arms-out pictures by the recipe's projection
  (`body_paint.py --dressed`); the approved Oct 14 game head and face paint (byte for byte) put on
  at his collar (`tools/characters/whole_man.py`); his own hat (`look/bold-cowboy-own-hat-2026-10-14`)
  as three pieces on his head bone, which come off.
- **Test 2: a free ready-made dressed body: not done.** This workspace's network policy allows
  GitHub only: sketchfab.com, api.sketchfab.com, quaternius.com, opengameart.org, poly.pizza,
  kenney.nl, itch.io, blendswap.com and polyhaven.com are all refused. Nothing on GitHub is a
  rigged, dressed Western man under CC0/CC-BY with a clear source (one unofficial mirror of
  Quaternius's Patreon-only "Cowboy Pack" has no licence file: not used, deleted). Nothing was
  downloaded, so nothing goes in CREDITS.md. The three best candidates for Sean to check and
  download (licence pages not openable from here; check each for NC/ND/NoAI before use):
  1. "Western Cowboy (Rigged)" by stevedaman, Sketchfab, listed CC Attribution:
     https://sketchfab.com/3d-models/western-cowboy-rigged-160bf043b71c458984c81c717b7483c9
  2. "Mexican Outlaw" by JuriK, Sketchfab, listed CC Attribution, ~8k triangles, tagged rigged,
     outlaw, cowboy: https://sketchfab.com/3d-models/mexican-outlaw-2270ee74361d4a5f8fab11ce64b8e7d1
  3. Quaternius's "Cowboy" (Cowboy Pack), CC0 if released on quaternius.com (low-poly, toon
     proportions): https://quaternius.com
  To let a session fetch them: add the host under the environment's Allowed domains (the cloud
  environment menu → Edit → Network access); Sketchfab downloads also need an API token secret.
  The night went on Test 1, as the brief said.

## The works check (`tools/characters/works_check.gd`)

In the game's own HumanBody, plain light: stand, walk, run, hands up, aim, sit, crouch, a ragdoll
fall, the hat shot off (`take_hat_shot`), a .45 through his arm and his chest. Every triangle's
stretch measured against his rest; a **sheet** is one stretched past x2 *and* longer than 5 cm,
counted by area (what shows). Judged against the **Oct 14 man's own numbers** (he bends cleanly,
Sean's word): a pose passes with up to 1.25x his sheet area (or 20 cm²). Numbers in `works/`.

| | stand | walk | run | hands up | aim | sit | crouch | ragdoll | hat off | wounds, blood |
|---|---|---|---|---|---|---|---|---|---|---|
| Oct 14 man, cm² | 0 | 0 | 0 | 1394 | 451 | 2747 | 2890 | 473 | yes | yes |
| Test 1, cm² | 0 | 0 | 0 | 695 | 12 | 20 | 30 | 37 | yes | yes |
| Test 1 | pass | pass | pass | pass | pass | pass | pass | pass | pass | pass |

No tears or poke-through by eye (sheets `s4_poses.jpg`, `s5_hat_wounds.jpg`): a whole man has one
skin, so nothing can poke through a layer. Walk is caught with a short stride.

**Load test** (`tools/characters/men_bench.gd`, perf_bench's calm street + 10 copies, headless,
ms at Sean's 3.25 GHz):

| | people (budget 4.0) | physics | else | total (budget 14) | draw calls (OpenGL) |
|---|---|---|---|---|---|
| the street as it is (two runs) | 4.0 / 4.4 | 0.8 / 2.1 | 1.5 / 0.5 | 6.4 / 7.1 | 9,355 |
| + 10 Test 1 | 6.9 | 2.6 | 1.0 | 10.6 | 10,255 |
| + 10 Oct 14 men | 7.0 | 1.4 | 2.2 | 10.8 | 10,527 |

The frame stays within 14 ms; "people" goes over its own 4 ms with ten more men whichever model
(it's the HumanBody's simulation, not his mesh; the street is at 4.0-4.4 without them). Test 1
draws fewer calls than the Oct 14 man (one skin against six garments). Frame times in the rendered
runs are lavapipe's (over a second a frame): only the draw calls count there.

**All tests:** 401 passed (before the last head fixes; rerun at the end: see the PR).

## The sheets

`s1_close_up.jpg` (the card table at night and plain light, with his portraits), `s2_game_distance.jpg`
(across the saloon at night, the card table from the room, across the street at golden hour),
`s3_plain_light.jpg` (front, three-quarter, side, back), `s4_poses.jpg`, `s5_hat_wounds.jpg`,
`f1_fit_stretch.png`. Test 2's column is empty (above).

## The art judge (docs/concept/judge/RUBRIC.md; blind sub-agents)

Six renders a man (card table close and wide, across the saloon at night, across the street at
golden hour, plain front, plain head), five traits each; verdicts in `judge/*/verdict.md`.

| | card table close | card table wide | saloon night | street golden | plain front | plain head |
|---|---|---|---|---|---|---|
| Oct 14 man | FAIL | FAIL | FAIL | FAIL | FAIL | FAIL |
| Test 1, round 1 | FAIL | FAIL | FAIL | FAIL | FAIL | FAIL |
| Test 1, round 2 (neck closed, hat softened) | FAIL | FAIL | FAIL | FAIL | **PASS** | FAIL |

- **Oct 14 man:** the coat, vest and trousers in random squares coarser than the face ("two
  hands"); orange shards at his neck, no white collar; too dark, close to a silhouette in the street.
- **Test 1, round 2:** close up "reads as the authority's kind of painted man and as his style
  portrait", "the best face of the set"; a lit person across the saloon, not a silhouette. Its
  three biggest problems: **the shirt's paint** (sleeves and shoulders a camouflage mottle, not
  fold planes; too bright under the lamps); **the pose and hands** (the game's stand pose reads as
  an A-pose, claw fingers, a fused mitt on the mug); **outdoor light** (backlit at golden hour, his
  face 42 of 255). Behind those: skin too red-orange, the red boots and vest, ragged hair behind
  the ear under the brim. Round 1's neck gap (jaw to collar) is gone from the list.

## What I chose, and why

1. **The fix behind a new key** (`"bare": true`), so no man on main changes; the layered men's
   base body (`bold_cowboy_body`, also a hatless Rodin man) has the same stretch: a note, not work.
2. **His body painted from his front and back pictures only.** The side pictures are half-turned
   (outline overlap 0.58 against the recipe's ~0.86) and smeared his sides with white flecks; front
   and back line up at 0.94 / 0.93. Same projection code (`body_paint.py --dressed`).
3. **The approved head taken from the game itself** (`bold_cowboy_rodin.glb`'s head and
   `_head.png`): rerunning `rodin_portrait.py paint` today gives a different paint (26% of texels
   off by more than 8), the pipeline having moved on since Oct 14. Kept as
   `assets/people/heads/bold_cowboy_rodin_mesh.npz`.
4. **Joined at his collar, not through `neck_ring.py`.** The dressed twin's collar stands 3-4 cm
   before the head's throat; a level ring pulled the head's neck out to his shoulders (a flare and
   a gap). Instead his body is cut 12 mm under the head's chin and its edge drawn in onto the
   head's neck (his collar hugging his throat), a lid under it, and the head's throat drawn from
   inside too (the approved head has no throat under the jaw: on Oct 14 the factory collar hid it).
5. **Arms and legs told by shape** (`limb_sides`) and **weights smoothed across the limb seams**
   (`smooth_seams`): the fit's distance rule gave his upper arms and inner thighs to his trunk, and
   the cut it then made tore his sleeves into flaps. Only for bare whole men.
6. **Our 17 bones, no skinned fingers**: his hands are cut at the knuckles and the game's own
   finger parts drawn (`own_fingers: skinned` adds 15 finger bones). The judge calls them blocks.
7. **His hat**: the bookmark's crown had a quarter of its top wound inward (a sliver of sky
   through it from behind, on its own sheet too): turned outward. Its designed paint (256 texels,
   1.5 cm patches) read as a checker beside his painted face: softened (the band keeps its studs).
8. **The works check judged against the Oct 14 man, by area**: by count every man fails (the
   Oct 14 man doubles ~200 triangles at shoulders and hips) and a finer mesh counts more.
9. **The load test as a subclass of perf_bench** (gameplay's, unchanged).

## Recommendation

**Test 1's route as the recipe for the bold cowboy**: the arms-out dressed Rodin man kept whole,
fitted bare-headed, the approved head at his collar, his own hat. It passes every works check, at
a twentieth to a half of the approved man's stretched area; it costs no new paid run; it draws less
than today's man; his clothes look like his pictures (shirt, tie, waistcoat, trousers, boots) with
none of the cut-out smears. What it gives up: **he has no coat** (the arms-out pictures are
coatless) and his clothes can't come off (one skin). A coated version is one Rodin run of his
arms-out coated pictures ($1.60, Sean's OK) through the same chain, the coat in his skin.
Test 2 can't be judged until a model is reachable.

## For the art session (not changed here)

- At golden hour in the street he's the darkest thing in frame: face L 57, trousers 28, the
  store's wall 86 (the judge's numbers). Not a silhouette.
- The saloon at night is one warm orange on his face, no cool side; a white specular glint on his
  cheek at the card table (likely the head's wet-eye glint, as on the Oct 14 man: not checked).
- When wounded, both men's waistcoats show white "teeth" under the blood (the wound paint).

## For gameplay (not changed here)

- The standing pose holds the arms out from the sides (an A-pose "mannequin" at game distance,
  the judge says of both men).

## Notes about other men (no work done on them)

- The layered men's base body (`bold_cowboy_body`) is fitted with the same stretch; `"bare": true`
  on it would refit it, changing a man on main (Sean's call).
- The whole-man chain (`whole_man.py`) takes any approved game head with eyes on the anatomy.
