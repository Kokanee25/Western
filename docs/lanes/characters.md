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
  ~150 MB textures a distinct man). Not cast yet: the game can't fetch private files on Sean's PC or CI.

## Open
- **First-person hands, option 2** (#896, a lab: `experiments/viewmodel_rig/`, `tools/blender/fp_arms.py`): the
  MetaHuman's hands cut at the wrist, modelled cuff and coat sleeve, a rig posed per gun from data (the Colt,
  the Winchester). **Sean picked it (#913): next its promotion into the game, #914.** Its glb is private
  (git-ignored); rebuild it from the Studio's frozen `sean_metahuman_s3` before the lab runs.
- **Harlan / MetaHuman Sean** (#692): waiting on Sean's Unreal re-export with blend shapes
  (`Sean_blendshapes.zip` in the private `sean-metahuman` release). Then his first-person arms holding the
  guns (#693), week 3.
- Talking face: four men's jaws go back more than down (#247).
- Proper garments (shirt, waistcoat, trousers as their own meshes): brief first; not in the slice.
- The run's planting foot drifts (foot IK).

## Traps
- Bench: `tools/characters/metahuman_bench.py` (~4 h, one game at a time); its `pgrep -f` waits match themselves, use `ps`.
- After a build, `godot --headless --import` first; lab renders via `tools/characters/lab_run.sh`.
- `talking_face.py --pin=no` for loose hair or a short head mesh (the edge pin slashes the chin).
- Judge every change against Sean's pictures and his words.
