# 2026-10-16: weighed as a man; the solver given steps; tone about the joint

Sean (2026-10-16): "Nah build the falls spend all night working on it if needed" (roadmap 3.2,
Prompt 09, moved up). Brief: `docs/briefs/fix-the-falls.md`. **Needs Sean's OK before merging**
(Prompt 09: `human_body.gd` changes go to him with before/after first).

## The change

One family at a time, each measured against the last (`compare.py diff`):

| step | what | lab flags |
|---|---|---|
| main (a741f3c) | | 90 |
| 1 | **Parts weighed as a man's** (`HumanBody.MASS_SHARE`, Winter's segment table after Dempster; head/neck split as de Leva). By capsule volume the trunk was 70% of him (real ~50%), a foot 0.8% (1.45%), the head 3.6% (6.9%): Jolt couldn't hold a 25 kg chest to a 0.34 kg hand or the body to a 0.7 kg foot. | 69 |
| 2 | **Hands collide with his other parts** again (left out for jitter; with true masses they settle). Limbs through the body 16 -> 0. | 52 |
| 3 | **Jolt 20 velocity / 8 position steps** (`project.godot`; were 10 / 2). Sinking 16 -> 7, joints apart 4 -> 0. | 20 |
| 4 | **Wrists and ankles damped** (`angular_damp` 6, was 2): a hand or foot at rest kept turning ~2 rad/s and he never slept. | 20 |
| 5 | **Tone capped by inertia about the joint** (parallel axis), not about each part's centre: a thigh read an eighth of what swinging it at the hip is, and with the true masses the hips held a fifth of their tone: he folded double (seen in the footage, not in the flags). | 18 |
| 6 | **Tone retuned for the honest cap**: knees 300 -> 100 (in a faint they give first), hips 320 -> 160, belly 260 -> 130, chest 220 -> 110. | **10** |
| also | A man hauled by the collar brings his trunk along (`drag_toward`): towing the chest alone, his hips and legs (half of him now) held it (test_gang's rescue went 0.7 of 1.5 m). | |

Tried and dropped: the foot's twist 5 -> 15 deg (61 flags); feet swept (no change: they sink because
the joint drives them, not by tunnelling); the foot's cone tilted 15 deg toes-down (115 flags);
tone as an implicit "stable PD" spring with no cap (Tan, Liu and Turk 2011): the neck, between two
joints, spun 45 deg a tick.

## Numbers (`compare.py diff build/physics_lab/now build/physics_lab/allhalf`)

Flags 90 -> 10 (sunk 31 -> 5, swing past limit 27 -> 4, joints apart 10 -> 0, limbs through the body
10 -> 0, twist 5 -> 0, launch 2 -> 0). Peaks over the 28: penetration 0.062 -> 0.040 m, self-overlap
0.113 -> 0.052 m, joint gap 0.058 -> 0.027 m. The wall slump now settles (4.1 s; never before); the
chair behind doesn't (a slow slide; 3.5 s before).

Left: a foot 3-4 cm into the ground on landing (Jolt's slop is 2), the neck past its cone when he
lands face first after a shove from behind (partly real), the chair.

## Cost

Ten men going down at once (`run.py --perf`): 2.0 -> 2.3 ms a frame here (x0.65 at Sean's), all
asleep a second sooner. The game's bench: the fire scene's physics 0.6 -> 1.1 ms (noisy), inside its
2.0 budget; the wall scene the same.

## By eye

Two blind judges (fresh sub-agents shown only the contact sheets, versions shuffled and unlabelled):
- Steps 1-5 against main: main better in 5 of 6 (he bent at the waist on straight legs, the
  "toe-touch", or folded double).
- With the knees given first (step 6's knee alone) against main: 3-3, "no real difference".
- Both versions share the flaw the judges named: he drops to his knees and folds into a kneel,
  hips high; he rarely goes down sideways or ends with his legs out. With the trunk weighed as a
  man's he's less top-heavy, so he crumples rather than pitching over.

Sheets: `side_<scenario>.jpg` (top three rows main, bottom three this; front, side, three-quarter).
