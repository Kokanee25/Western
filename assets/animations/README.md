# Animations

Clips `HumanBody.play_clip` plays (`MotionClip`, `src/bodies/motion_clip.gd`): `<name>.json` is
what the game reads (each segment's turn a sample, the root's travel, the heading, the hips'
height, the marks); `<name>.glb` is the same motion on a Blender armature of our rig, for the
record and for looking at in Blender. Made by `tools/blender/retarget_motion.py` (docs/MOCAP.md
"Pipeline"); which take became which clip and why is in the report it writes (`takes.json`) and
in the PR that brought them.

| Clip | From | Take | Why |
|---|---|---|---|
| `walk_angry` | Uthana text-to-motion, the Studio's `motions/card_cheat/` (2026-10-24) | 3 of 3 | 5.6 m in 4 s and the least foot slide; take 1 went as far but slid twice as much, take 2 only 3.3 m |
| `kick_back` | same | 2 of 3 | the fastest boot (6.9 m/s) with the left foot stillest; see the report for height and direction |
| `draw` | same | 3 of 3 | stands still (0.05 m of travel), the steadiest hands |
| `stand_over` | same | 2 of 3 | leans down and stays (0.8 m of travel, the least); take 3 walks about |

Credit: the four clips were generated with Uthana's text-to-motion model
(`uthana/text-to-motion-diffusion-v2` on Replicate) for this project (CREDITS.md).

## The clavicles (#708, 2026-11-08)

Every clip from Uthana (the four above, the chores `wipe_bar`, `mop_floor`, `scoop_water`, the walk
`walk_old`, and the library's `reload`, `walk_gun`, `run_gun`, `stagger`) carries a `clavicle_r` and
`clavicle_l` channel each frame: the clavicle's turn from rest in the chest's frame, which
`HumanBody._pose_deform` hands to `DeformRig.pose` over its drive from the arms while the clip
leads. Their segments and every other field are exactly as before. **No channel** (the drive
stays): the library's CMU clips (B. Hahne's BVH conversion holds every clavicle at zero),
`library/pistol_aim` (only its legs are kept), and any KayKit or Quaternius take (KayKit's rig has
no clavicles; Quaternius' rest puts its shoulders a fixed 19-31 degrees back, so none are read).
How the channel is made: `tools/blender/retarget_motion.py`'s docstring.

Each clavicle's turn as retargeted, before the limits the game holds its own drive to (26 up, 6
down, 18 forward, 14 back: SkeletonTuning), over the whole take (degrees), and the frames the
exporter held to them. The roll about the clavicle's own length is left out (the drive has none).
Uthana's man standing still (`card_cheat_rest`) reads right 1/2 (up/forward), left 5/5: its left
shoulder sits a little higher in every take.

| Clip | Right: up; forward | Left: up; forward | Roll left out (r / l) | Frames held (r / l) |
|---|---|---|---|---|
| `draw` | 2 to 12; 0 to 8 | 7 to 19; -1 to 7 | 8 / 7 | 0 / 0 of 89 |
| `kick_back` | 0 to 14; -1 to 17 | 5 to 22; -11 to 12 | 18 / 14 | 0 / 0 of 89 |
| `stand_over` | -12 to 29; 1 to 31 | -9 to 8; 8 to 27 | 18 / 11 | 53 / 61 of 149 |
| `walk_angry` | 7 to 15; 1 to 14 | 8 to 16; -6 to 8 | 14 / 13 | 0 / 0 of 119 |
| `mop_floor` | 2 to 20; -3 to 7 | 4 to 17; 1 to 13 | 9 / 11 | 0 / 0 of 179 |
| `wipe_bar` | 1 to 16; -2 to 10 | 4 to 15; -3 to 8 | 4 / 2 | 0 / 0 of 149 |
| `scoop_water` | 5 to 15; -4 to 2 | 8 to 18; 0 to 7 | 18 / 17 | 0 / 0 of 179 |
| `walk_old` | 2 to 7; 2 to 6 | 3 to 9; 2 to 7 | 9 / 8 | 0 / 0 of 149 |
| `library/reload` | 3 to 10; 0 to 3 | 9 to 14; 1 to 4 | 4 / 5 | 0 / 0 |
| `library/walk_gun` | -8 to 1; -3 to 7 | -9 to -1; -2 to 11 | 7 / 7 | 19 / 43 of the take |
| `library/run_gun` | 12 to 21; 2 to 18 | -3 to 6; 2 to 21 | 8 / 6 | 0 / 11 of the take |
| `library/stagger` | 2 to 12; -1 to 19 | 3 to 17; -2 to 13 | 25 / 27 | 3 / 0 |

To make them again (the Studio's takes from its `claude/studio-gun-moves` branch, `motions/`,
copied under `build/motion_src/motions/`; the library's sources by `tools/blender/fetch_library.sh`
and the Uthana gun moves with `card_cheat_rest/rest_pose_01.glb` in `build/library_src/uthana/`):

```sh
PY=~/.venvs/studio/bin/python; M=build/motion_src/motions; REST=$M/card_cheat_rest/rest_pose_01.glb
C="--credit=Uthana text-to-motion (uthana/text-to-motion-diffusion-v2 on Replicate), generated for this project"
$PY tools/blender/retarget_motion.py $M/card_cheat/draw_01.glb --name=draw --rest=$REST "$C" --take=1
$PY tools/blender/retarget_motion.py $M/card_cheat/kick_back_02.glb --name=kick_back --rest=$REST "$C" --strike=foot_r --event=strike:auto --take=2
$PY tools/blender/retarget_motion.py $M/card_cheat/stand_over_03.glb --name=stand_over --rest=$REST "$C" --take=3
$PY tools/blender/retarget_motion.py $M/card_cheat/walk_angry_01.glb --name=walk_angry --rest=$REST "$C" --take=1
$PY tools/blender/retarget_motion.py $M/chores/mop_floor_03.glb --name=mop_floor --rest=$REST "$C" --take=3
$PY tools/blender/retarget_motion.py $M/chores/wipe_bar_03.glb --name=wipe_bar --rest=$REST "$C" --take=3
$PY tools/blender/retarget_motion.py $M/chores/scoop_water_02.glb --name=scoop_water --rest=$REST "$C" --event=splash:hands_high --take=2
$PY tools/blender/retarget_motion.py $M/walks/walk_old_02.glb --name=walk_old --rest=$REST "$C" --take=2
$PY tools/blender/library_motion.py promote
```

(The takes the JSONs name are the ones used; the first table's take numbers for `walk_angry`,
`draw` and `stand_over` don't match them, from before.)
