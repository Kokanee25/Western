# 2026-10-16: shot dead running, he goes over his legs, not onto his knees

Sean (2026-10-16): "Okay keep working on the running death", after sharing a prompt asking for a
runner shot in the head to carry on forward and tumble from physics, with no knockback and no
scripted fall. Brief: `docs/briefs/fix-the-falls.md`. **Needs Sean's OK before merging**
(Prompt 09: `human_body.gd` changes go to him with before/after first).

## What was wrong

The lab's group J (ten head shots: standing, walking, jogging, running, sprinting; four stride
phases; from in front, behind and the side). With the falls' first round (#132) his momentum was
kept (279 -> 279 N*s), but killed running he **folded one knee right under him** (150 deg by 0.4 s)
and knelt, then slid on his knees and fell on his face. Two causes:

1. **His legs gave no support.** A dead man had no tone at all, so the knee he stood on folded on
   the first tick.
2. **The gait's feet skate.** The procedural stride isn't foot-planted: the grounded foot moved at
   5-7 m/s while he ran at 3.5. Handed to the ragdoll, that swing threw his legs out ahead.

## The change (`HumanBody.go_limp`, `_start_tone`)

- **The leg he stands on holds for an instant.** Killed outright he keeps his tone for 0.15 s
  (`TONE_FADE_DEAD`; a blackout keeps it 0.35), and his stance leg's hip and knee hold six times
  harder for it (`TONE_STANCE`). A man's weight on a near-straight leg goes down the bones, so the
  planted leg props him up for a moment and a runner pitches forward over it.
- **His legs go on at his hips' speed, and the stance foot stays put.** The leg turns as one
  about the ankle (w = up x v / height). The ground takes the stance leg's share: a runner keeps
  93% of his momentum (279 -> 260 N*s), and everything above the hips keeps all of it. Real strides
  will come with mocap.
- The lab's "launch" flag now measures a part's speed **over what he was going** when he went
  down (`analyse.py`, `thresholds.json`): a sprinter's head at 8 m/s as he pitches isn't thrown.

Tried and dropped:
- Tone fade alone: no change.
- Leg velocity and plant alone: no change.
- The column without the plant: 19 flags against 13, and less pitch.
- The spine's tone kept longer, or held 6x: no change. The backward arch below is the spine's
  joint limits, not its tone.

## Numbers (38 scenarios, `compare.py diff build/physics_lab/main38 build/physics_lab/pivot2`)

- Flags: **17 on main, 10 now**. No launches; group J goes 6 -> 0.
- At 0.4 s, the knees of a man killed running at four points in his stride:
  - main: one knee 141-149 deg (kneeling);
  - now: both 25-45 deg.
  - This is the new test `test_bodies::test_killed_running_he_pitches_over_not_onto_his_knees`, which fails on main at all four strides.
- Hips pitched forward at 0.3 s: 18 deg on main, 35 now.
- He comes to rest sooner: 2.0-2.8 s killed running, where main took 2.9-4.4.
- Unchanged: the standing, chest-shot, blast, wall, stairs and table falls (A, D-I), and the five
  fall goldens (`outlaw_down`, `porch_collapse`, `outlaw_blast`, `outlaw_graze`,
  `outlaw_surrender`: all within tolerance).
- The walking blackouts gain a foot 4.5 cm into the ground for a few ticks (flags 1 -> 2 each).

## By eye

A blind judge was shown the six sheets here, shuffled and unlabelled, and asked which version is
more believable:

| sheet | judge's pick | which it was |
|---|---|---|
| walking, head shot | B | **this** |
| running, head shot from in front | A | **this** |
| sprinting, head shot | B | **this** |
| running, head shot from the side | A | **this** |
| walking, blacks out | no difference | |
| running, blacks out | B (slightly) | main |

On main, the judge said, he "folds into an upright kneel from 0.3 s and holds it to 1.5 s, exactly
the neat-kneel failure", and "drops to his knees at 0.3 s, on all fours at 0.45 (a kneel and
crawl)". This version "pitches over and slides out, ending stretched face-down", "buckles then the
torso goes down forward".

Shared and next: as his hips go over, his trunk lags and arches back (~32 deg, the spine's own
limits), and his head goes back, a "cobra" for a moment at 0.3-0.45 s. Main's running blackout
does the same; it shows more now that he pitches instead of kneeling.

Sheets: `side_<scenario>.jpg`. In each, the top two rows are main (side and three-quarter views),
the bottom two are this version; the columns are 0, 0.15, 0.3, 0.45, 0.6, 0.9, 1.5 and 3 s after he
goes down.
