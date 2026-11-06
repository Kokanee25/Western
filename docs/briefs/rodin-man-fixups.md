# Fix-ups on Sean's own Rodin man (the stranger): an experiment in three passes

Sean, 2026-11-06: "Can we try doing some fix ups as an experiment". The man is `stranger_s2_talking`
(the Studio's `stranger_s2`: Sean's own Rodin export, smoothed normals, decimated 150k -> 38k
triangles; in the street 7 m ahead of where you start; branch `claude/rodin-character-formats-ydzgfl`
in both repos, not merged). Lane: characters, with one art file (the people shader) named below.
**One pass a session; Sean's word between passes.** Every pass is judged against the pass before it,
the same views and light, and against his first in-game shot (`docs/style_test/stranger/` once made).

## What's known (2026-11-06)

- **The game draws people with `src/bodies/shaders/body_skin.gdshaderinc`** (art's): his colour
  texture and one `roughness_value` for the whole man; the default look steps the light in 4 bands;
  under `REAL_LOOK` (the look going realistic, `docs/briefs/red-dead.md`) the engine lights him, but
  still no normal map and no roughness map. Only the eyes get their own gloss (the eye sphere).
- **His Rodin maps** (2048 px; source zip in the Studio's `inputs/sean/rodin_2026-11-06/` README):
  roughness ~0.83 everywhere (skin 0.78, shirt 0.81: no material told apart, nothing glossy); metallic
  0 (the brass buttons are paint); the normal map carries real detail in 19% of texels (p90 7°, p99 24°:
  folds, seams, hair) but is baked to the 150k mesh, not the 38k one the game draws.
- **His face in the game is MakeHuman's patch** (`tools/faces/talking_face.py`) painted from his
  texture into `stranger_s2_talking_head.png`: any map his body gets, the patch needs by the same
  transfer as its paint.
- His works check fails aim 718, sit 566, crouch 253, ragdoll 436, hands_up 3561 cm² (the approved
  men ~0 but hands_up ~100-530); stand, walk, run 0.

## Pass 1: materials and light (geometry unchanged)

1. Rebake his normal map from the 150k model (with its own normal map applied) onto `stranger_s2`'s
   38k mesh and UVs (Blender Cycles, selected to active; the Studio's bpy), and carry it onto the
   face patch as its paint is.
2. A roughness map by material, from masks in his UV space (colour clusters plus his landmarks):
   skin (a little shine on forehead, nose and cheekbones), lips, eyes (the eye sphere's code),
   hair and moustache, the cotton shirt (matt), the leather waistcoat (a sheen), the string tie,
   trousers, boots; metallic only on the buttons. Each a number in one config file, not per texel.
3. The game: optional `normal_tex` and `rough_tex` (and a metallic mask) in the skin shader, used
   only when set, so every other man draws as today (**art's file: say so in the commit**);
   `BodyMesh` reads them from his `.json` (characters'). The Studio's assemble and `to_game.sh` carry
   the maps. Under the painted look they matter little (stepped light); judge under `--real` too.
4. Judge: the same views before and after (street noon and golden hour, saloon at night; 1, 3 and
   6 m; `tools/fit_shot.gd` or the bridge), side by side; the cheap judge (`critic.py cheap`) on both.
   Cost of the maps: texture memory per man (two more 2048 maps: say the MB) and the shader's cost.
   **Done when** Sean has the sheet and picks.

## Pass 2: targeted geometry (his identity kept)

Eyeballs, lids, hairline, moustache, clothing edges. **Identity is measured, not eyeballed:** his
478 MediaPipe landmarks and the face crop before and after; a change that moves the landmarks past a
set tolerance (or a blind judge says "a different man") is taken back. Never regenerate the head.

## Pass 3: rig and motion

Much is there already (the talking face's 20 blend shapes, `FaceLife` blinks and looks, the works
check's 8 poses, `arm_poses.gd`). The pass: loops round the eyes and mouth, the blink and jaw-open
without tearing, head turn (the neck seam), shoulders and the waistcoat; and his works-check failures
above (the fit's weights about the shoulders and hips: compare with the blacksmith's, PLAYBOOK §6).

## Setting up a fresh container (what this session needed)

`tools/setup.sh`; `STUDIO_GAME_REF=/home/user/Western tools/game_checkout.sh`; `godot --headless
--import` in `../western-workbench` and in the game; in the game `python3 tools/blender/fetch_makehuman.py`
and `~/.venvs/studio/bin/python tools/faces/mh_units.py`; `cargo build --release` in
`addons/saltcreek_native` and copy the `.so` into its `bin/`. Godot is `/root/godot/godot`: put it on
`PATH` for `to_game.sh` and `bridge.py`. The player starts at (24, -9) looking west (the scene file's
(11, -9) is moved). `test_break_off_a_fight_and_they_ride_out_not_stand_about` fails here on main too.
