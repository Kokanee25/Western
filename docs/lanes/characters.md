# Characters lane: current state

Branch `claude/characters-…`. **Read the Studio's `docs/PLAYBOOK.md` first** (`Kokanee25/saltcreek-characters`,
attach it). Replace your lines here at the end of a session; no history (that goes in `docs/status/`).
Keep this file under ~10 KB. Full history to 2026-11-11: `docs/status/current-state-2026-11-11.md` "Characters".

## How men are made
- New men by `tools/characters/RECIPE.md` (Rodin portrait route; skill `new-portrait-man`); another route
  only with Sean's OK. Women and hard faces: from Sean's own pictures (the widow, #414).
- Paid calls run in the Studio on GitHub (a request in its `requests/` on a `claude/studio-*` branch). Ask
  Sean before any training run; give each man's cost before paying. Studio ledger ~$68 of $75 (check it).
- Meshy is a second opinion only; Rodin stays.

## What's in the game
- Every Studio man: MakeHuman face grafted (20 blend shapes), `FaceLife`, `FaceSpeech` (talking), skinned
  hands, bandanas; the fuller skeleton (`DeformRig`: 30 finger, 10 deform bones; LAYOUT "src/bodies").
- Motion: `LibraryMotion` (CMU basics, Uthana gun walk/run; clips carry clavicles, #708). Uthana bills ~$0.50
  a prediction.
- No working girl for now (#698).
- MetaHumans (#889): `tools/metahuman_to_game.sh <build>` in the Studio lays one into the git-ignored
  `assets/people/private/` (model `private/<build>`; never committed, #692's licence) with three lighter
  levels cut at load (`<build>_lod1..3`, `PeopleBodies.glb_of/simplified/thin_cards`), the grooms' alpha cut,
  his hair under a hat. Costs: `docs/reviews/2026-11-metahumans-town.md` (~18 with levels, like today's men;
  ~150 MB textures a distinct man). Fetched by `tools/characters/fetch_private.sh` (CI's export, with
  `STUDIO_TOKEN`); cast by `config/private_cast.json` (townsman, loudmouth; lod1; hat and vest re-dressed)
  but **off**: his export wears only a vest and drawers. Sean picks how to dress him (#933's waiting issue).

## Open
- **First-person hands, option 2: in the game** (#914). `HeldHand` cuts MetaHuman Sean's hands, cuff and coat
  sleeve from `assets/people/private/harlan_fp.glb` (git-ignored; `tools/characters/fetch_fp_hands.sh` builds it
  from the Studio's frozen `sean_metahuman_s3`); else the painted arms. Holds and poses: `config/fp_holds.json`.
  CI's export builds it into Windows/Linux (not web) **only once the `STUDIO_TOKEN` secret is set**.
- **The Colt in hand** (#1014, branch `claude/characters-viewmodel-colt-ps2nlf`): `ColtModel` (the approved SAA,
  joined to 26 draws) in `RevolverViewmodel`; the viewmodels' own field of view (`view_fov` 54, a shear, no
  second pass); per-pose elbows; the in-hand albedo grade (`held_albedo`); poses on a plain stage in seconds:
  `experiments/viewmodel_rig/game_views.gd`. Blind judge r1 and r2: cheap indie (all 20), r2's top three: the
  hand clamps the frame (not the grip), the rifle's steel black and its hands float, the hands and sleeve
  toy-like; the town bench's cocking and firing frames show no change. Waiting on Sean (the issue linked in #1014).
- **Harlan / MetaHuman Sean** (#692): waiting on Sean's Unreal re-export with blend shapes
  (`Sean_blendshapes.zip` in the private `sean-metahuman` release).
- A MetaHuman's finger bones point +Y to the tip with the hinge flipped (rest hand ~20° closed):
  `HeldHand._canonical_fingers` reframes them (from #919, closed unmerged; its Studio branch kept).
- Talking face: four men's jaws go back more than down (#247).
- Proper garments (shirt, waistcoat, trousers as their own meshes): brief first; not in the slice.
- The run's planting foot drifts (foot IK).
- **The garment handoff** (#895, a lab): `experiments/garment_handoff/`, a worn skinned glove becoming cloth
  as it's drawn off (the core for #874's acts, coats hung up, a torn-shirt bandage). Into the game is
  gameplay's, on Sean's word (README: the part, a native skin shape).

## Traps
- The town's gun_arms bench under lavapipe: ~45 min; move `crash_reports/` aside first (a notice draws over frame 1).
- Bench: `tools/characters/metahuman_bench.py` (~4 h, one game at a time); its `pgrep -f` waits match themselves, use `ps`.
- After a build, `godot --headless --import` first; lab renders via `tools/characters/lab_run.sh`.
- `talking_face.py --pin=no` for loose hair or a short head mesh (the edge pin slashes the chin).
- Judge every change against Sean's pictures and his words.
- A MetaHuman in a lab: copy the Studio's `frozen/<build>/` into `assets/people/` and list it in
  `.git/info/exclude` (never committed, #692). A skinned mesh added to a man needs his `custom_aabb`; a
  SoftBody3D's mesh needs normals (without them it's drawn scrambled).

## Printable guns (#1027)
- Studio `printing/guns/` (private; never in this repo). Colt done, untested by print: `colt/`, generator in `src/`. Winchester and coach gun next: same slice-the-game-model method (`src/lib.py`), halves with pockets, steel tube barrels.
