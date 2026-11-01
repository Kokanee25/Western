# The post pose (issue #531, step 3's first part)

Sean, 2026-11-01 (on #531): the side-on pose comes before the narrow cover that uses it. A man
behind a narrow vertical post, using as much of it as he can: bladed, left shoulder on the post's
face, left arm hanging; the right upper arm down against his ribs, the elbow about square, the
forearm level across his stomach or lower chest, the revolver along it out past the post's edge
(his right of it as he looks at the threat); point-fired, not aimed; his head turned to the threat,
leaning out enough to see; legs behind the post. Not one pose but a family, seeded per man.

## What's here

- `src/bodies/post_pose.gd` (`PostPose`): `dials(seed)`, `make(body, dials)`, `yaw`, `place_at`,
  `capsules_now`, `eye_now`, `point_spread`. `HumanBody.take_post(threat)` and the pose `post`.
- `post_stand.gd`: the saloon's gallery post on its own (`saloon.json` "post": 8x8 in, chamfered,
  `wood:int_timber`), a real `Structure` member.
- `post_views.gd`: a Studio man (default `bold_cowboy_s3_talking`) at the post, the threat 6 m north
  (eye 1.6 m), the man south of it facing east. Four views (front = the opponent's, three-quarter,
  overhead square on, side from the east) and the checks in `checks.json`:

  ```sh
  xvfb-run -a godot --path . -s res://experiments/post_pose/post_views.gd -- --out=build/post --seeds=1,2,3,4,5,6,7,8
  python3 experiments/post_pose/summary.py build/post/checks.json   # a line a seed
  python3 experiments/post_pose/sheet.py build/post --hero=3        # hero.png, family.png
  ```

  `--views=none` measures without saving pictures (12 men in ~30 s here). The renders are
  OpenGL on llvmpipe here (no Vulkan in this container): ~6 s a man for four views.

## How the pose is made

The joints aren't typed in: they're worked out from where things have to be, on his own anatomy.

1. **Turn:** side-on, the threat at his left, turned toward it by `turn` (0-8 degrees; 14-22 for a
   man showing chest; 40-55 for the regular hold), the trunk twisted toward it by `twist` over
   the hips (4-12; 18-26 showing chest). More twist let the upper arm hang straighter, but a
   22 degree twist turned 15 cm of chest past the post (round 1's front view), so it's small.
2. **The gun arm** (in the chest's frame): the forearm along the threat's line (with a few degrees
   of his own error, `hold_yaw`/`hold_pitch`); the elbow by his ribs, starting low (`elbow_h`) and
   raised a centimetre at a time till the forearm capsule clears his belly by 5 mm (a higher elbow
   sits further forward, the upper arm less straight down). Each limb's turn is the rotation from
   its rest line to that line with the elbow's hinge square to both; the hand rolled so the gun's
   top is up, then canted by `cant` (+-12 degrees).
3. **The lean:** his trunk stays behind the post; he leans forward (abdomen 45%, chest 55%) till
   his leading eye is `peek` (1-4 cm) past the post's edge, checked by forward kinematics through
   his joints (round 2 slid his whole body out instead: the post covered half of him and his
   shoulder was on its corner). The neck and head take the lean back so his eyes stay near level.
4. **The rest:** head and neck the remaining turn to the threat less what his eyes take; the left
   arm hangs plumb, back by part of his turn so his hand doesn't reach the post before his
   shoulder; legs straight, or staggered (right back); "backside": hips back, chest over.
5. **At the post** (`place_at`): his trunk centred on the post's width, his nearest part behind
   the post's width against its face, then out only if his eye or the gun in his hand needs it.

## The point-fired shot (the rule, not built)

Pointed by the body, not the sights, so variant A's cone widens: `spread x 2.5 + 1.5` degrees
(2.4 calm becomes 7.5), and no hold-over for range. Point shooting's practice (Fairbairn and Sykes,
*Shooting to Live*, 1942; the US Army's quick-kill and the FBI's close-quarters courses) puts it on
a man's chest out to ~7 m and falling off past 10-15 m: about two and a half times the aimed
group. He can only point where his forearm points: the threat within `POINT_ARC` (25 degrees) of
it, or he shifts first. For the brain when the narrow cover kind goes in.

## Results 2026-11-01 (`results/2026-11-01/`)

`hero.jpg` (seed 3), `family.jpg` (seeds 1-8), `checks.json` (seeds 1-12). Over seeds 1-12:

| | gun across him (10) | regular hold (2) |
|---|---|---|
| right upper arm off vertical | 8-21 deg | 82-84 (arm out) |
| elbow | 90-98 deg | 176 |
| forearm off level / off the threat's line | within 4.4 / 5.5 deg | within 4.1 / 2.7 |
| left arm off vertical | 2-8 deg | 2-4 |
| lean | 12-18 deg | 16-21 |
| hidden from the threat (of his capsules' surface toward it) | 63-82% (head 50-90, trunk 85-91) | 57-62% |
| his eye sees past the edge; the gun clear of the post; body into the post | all; all; 0 cm | all; all; 0 cm |

Limits:
- **Measured on the capsules**, not the Studio mesh: his clothes stand a little proud of them,
  so the forearm "clear of the belly" is clear of the capsule (0.6-2.1 cm); on the mesh the sleeve
  may touch the vest. Fine for a still pose; resting parts collide only in the ragdoll.
- **Not entered, held, fired from or left:** a still pose (Sean: those later, once the pose is
  right). No brain takes it; `HumanBody.face` would turn him square again.
- **The family is in the dials;** on one man the differences read small at a glance (legs and
  lean show most). Wider ranges are a dial each in `PostPose.dials`.
