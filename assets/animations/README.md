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
| `get_up_back` | Uthana, the Studio's `motions/get_up/` (2026-10-24, branch `claude/studio-chair-getup`) | 3 of 3 | on his back, rolls to his side, a knee and a hand, up, brushes off; take 1 walks (into the wreck and onto the table); played by `HumanBody._rise_on_clip` (no `.glb` kept: the Studio has the takes) |

Credit: the clips were generated with Uthana's text-to-motion model
(`uthana/text-to-motion-diffusion-v2` on Replicate) for this project (CREDITS.md).
