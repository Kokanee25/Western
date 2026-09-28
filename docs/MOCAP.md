# Motion capture guide

Sean records motions on his iPhone; Claude turns them into game animations. This file is the shot
list, the recording rules and the pipeline. See DESIGN.md §7 ("Bodies in motion") for how recorded
animation hands over to the active ragdoll.

## Tools

- **Move One** (Move AI) — iPhone app, single-camera markerless capture.
- **Rokoko Vision** — browser-based: upload a phone video, download the animation (free tier).
- Faces (later): the iPhone's Face ID camera with a face-capture app for talking characters.
- Prices and features change; check the current ones.

## Recording rules

- Phone on a tripod or propped up (never handheld), **whole body in frame**, good light, plain
  background, fitted clothes.
- **One action per clip**, a few seconds each; **2–3 takes** of each, keep the best.
- Walk, run, crouch-run and crawl: keep going in a straight line for several steps so there's a clean
  loop in the middle.
- **Props:** a toy or replica gun **weighted close to the real thing** (Colt single action ≈ 2.5 lb,
  lever-action rifle 7–9 lb) — a light toy makes motion look light. A blue training gun works. Never a
  real firearm. Film indoors or somewhere private.
- **Don't record recoil** — it's procedural (DESIGN.md "Recoil"). Record the stance and the settle
  between shots with a mimed kick; only the posture is used.
- **Falls and "getting shot":** onto a mattress. Deaths aren't recorded at all — the ragdoll does those.
- **Your own recordings are fine to commit** (the repo is public). **Mixamo downloads are not** —
  their licence doesn't allow redistributing the files; use them only if the repo goes private.
- Fingers are the weakest part of phone capture; hand poses (grip, cocking, bandaging) are finished in
  code.
- **Adults play adults** (children move differently — bouncier gait, different balance — and it shows
  on adult characters). **Sean's kids play the town's children.**

## Naming and where files go

- Name: `<action>_<variant>_<take>`, e.g. `gut_shot_stagger_front_01.fbx`, `walk_normal_02.fbx`.
- Put raw exports in `assets/mocap/raw/`. Keep the best take per action; delete the rest before
  committing (FBX files are large).
- Pipeline (Claude): raw FBX → headless Blender script in `tools/blender/` retargets to the game
  skeleton, trims, fixes foot sliding and jitter, makes loops loop → glTF in `assets/animations/` →
  Godot import. Record which take became which animation in `assets/mocap/README.md`.

## Shot list

### Batch 1 — M2, bodies and gunfights (~10)
1. `idle_stand` — standing, weight shifting
2. `walk_normal`, `run_normal` — straight lines, for loops
3. `draw_aim_holster` — draw the revolver, aim, holster
4. `hit_stagger_front`, `hit_stagger_side` — hit, catching yourself
5. `leg_buckle` — leg gives out, down to one knee
6. `gut_shot_stagger` — doubled over, staggering to cover
7. `crawl_wounded` — dragging yourself along
8. `surrender_hands_up`
9. `beg_kneeling` — cowering, begging on your knees
10. `flee_panic` — running away in a panic

### Batch 1b — combat moves for enemies (~8)
`crouch_run`, `peek_over_cover`, `lean_out_corner`, `blind_fire_over_cover`, `dive_to_cover`,
`reload_crouched`, `drag_wounded_friend`, `fire_and_recover` (posture only)

### Batch 1c — moving with a weapon (~12)
Each weapon state needs its own movement set (people move differently with a rifle in hand). Use the
weighted prop.
- **Rifle:** `rifle_walk`, `rifle_run`, `rifle_crouch_walk`, `rifle_ready_carry` (held low across the
  body), `rifle_turn_in_place`
- **Pistol drawn:** `pistol_walk`, `pistol_crouch_walk`, `pistol_turn_in_place`
- **Empty hands:** `crouch_walk`, `turn_in_place`

### Batch 1d — touching the world (~6, finished by IK)
Don't record one clip per object: the game uses **inverse kinematics** to put the hand exactly on the
real rail, barrel or doorframe. Record general reaches so the body's lean, reach and weight shift are
real:
`reach_rest_hand_waist`, `reach_rest_hand_chest`, `reach_rest_hand_head` (rail, counter, doorframe),
`lean_one_hand_catch_breath`, `crouch_hand_on_cover` (barrel/trough), `steady_self_stumbling`,
`push_off_cover_to_run`

### Batch 2 — first aid (~8)
`pressure_on_wound`, `tourniquet_thigh`, `bandage_arm`, `splint_leg`, `drag_by_collar`,
`carry_over_shoulder`, `pour_whiskey_on_wound`, `check_pulse_breathing`

### Batch 3 — town life (~12–15)
`lean_bar_drink`, `sit_cards`, `talk_calm`, `talk_agitated`, `tip_hat`, `point`, `sweep_boardwalk`,
`carry_bucket`, `shovel`, `hammer`, `lead_horse`, `sleep_in_bed`, `wake_up`

### Batch 4 — the kids (~6–8)
`kid_run_chase`, `kid_play`, `kid_peek_corner`, `kid_hide_behind_adult`, `kid_wave`, `kid_scared_walk`

### Batch 5 — later
Fistfights (punches, blocks, taking hits), climbing, mounting and dismounting a horse, dynamite
(light the fuse, throw, run).

Free libraries (Mixamo, the CMU library) fill generic gaps; Sean's recordings are for the moves that
make this game different.
