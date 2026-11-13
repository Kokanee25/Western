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

## Open
- **First-person hands, option 2** (#896, a lab: `experiments/viewmodel_rig/`, `tools/blender/fp_arms.py`): the
  MetaHuman's hands cut at the wrist, modelled cuff and coat sleeve, a rig posed per gun from data (the Colt,
  the Winchester). Waiting on Sean's pick against #890's full arms (the pick issue). Its glb is private
  (git-ignored); rebuild it from the Studio's frozen `sean_metahuman_s3` before the lab runs.
- **Harlan / MetaHuman Sean** (#692): waiting on Sean's Unreal re-export with blend shapes
  (`Sean_blendshapes.zip` in the private `sean-metahuman` release). Then his first-person arms holding the
  guns (#693), week 3.
- Talking face: four men's jaws go back more than down (#247).
- Proper garments (shirt, waistcoat, trousers as their own meshes): brief first; not in the slice.
- The run's planting foot drifts (foot IK).

## Traps
- After a build, `godot --headless --import` first; lab renders via `tools/characters/lab_run.sh`.
- `talking_face.py --pin=no` for loose hair or a short head mesh (the edge pin slashes the chin).
- Judge every change against Sean's pictures and his words.
