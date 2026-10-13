# 2026-10-12: muscle tone as he goes; his parts collide with each other

Sean: "as real as possible". Faults 1 (he folds straight down like a puppet) and 3 (his arms go
into his own body) of the baseline; fault 4 (joint overruns) as far as these reach it.

**The change** (`src/bodies/human_body.gd`, `src/bodies/layers.gd`):
- **Muscle tone.** As he goes limp each joint is held toward the pose he went limp in, the hold
  fading (`TONE_START` 0.55 of `TONE`'s stiffness, over `TONE_FADE` 0.35 s; a man still conscious
  0.7 over 0.6 s; a dead man none), gone after `TONE_UNTIL` 1.5 s. A spring and a damper on each
  joint (`_step_tone`), equal and opposite on the two parts. Each joint's stiffness and damping are
  capped by what one physics step can take for the pair's inertia about the axis it turns
  (`_tone_inertia`, `TONE_STEP_SHARE` 0.25): uncapped, the hands and neck spun 45 degrees a tick;
  capped by the smallest inertia, a shin's spin about its own length, the knees had no tone at all.
- **Self-collision.** A limp man's parts are on `Layers.RAGDOLL` too and collide with each other
  and with other limp men; not a part and its parent, two parts on one joint, or any pair already
  touching as he goes (`_keep_apart`: Jolt would throw those apart). His hands are left out: one
  resting on him jittered and he never came to rest.
- **The head and hands swept** (`continuous_cd`): toppling more as one piece, his head landed fast
  enough to sink 9 cm into the ground for a few ticks.

**Before -> after** (`compare.py diff build/physics_lab/carry build/physics_lab/final`; carry is
the game as of 2026-10-11, momentum carried):
- Flags over the 28 scenarios: **85 -> 54**.
- Limbs into his own body (self-overlap peak): **0.09-0.20 m -> 0-0.03 m** in most falls; 0.06-0.11 m
  where it's a hand (left out of self-collision) or a pair touching as he went.
- Standing, blacks out: at 0.4 s his middle is still at 0.85 m (0.68 before, a squat); his knees
  buckle forward and he pitches onto his face. Settles in 3.9 s (5.5).
  `A_stand_blackout_before_after.png` (top before, bottom after, matched times).
- Running and walking: on along his run as before, now landing face down along it rather than
  folding at the knees first (`C_run_blackout_before_after.png`, `B_walk_blackout_before_after.png`).
- Crouched: settles in 4.8 s (3.4; with self-collision on his hands it never did).
- Penetration into the world: the head 0.07-0.10 m -> 0.026 m with it swept. A standing blackout's
  feet sink 0.06 m at the knee drop (0.05 before).

Known:
- A standing blackout ends in a hunched heap, knees under him and his face on the ground, where
  before he lay flat out (`A_stand_blackout_before_after.png`, last frames). Plausible for a
  straight-down faint; not the only way one ends.
- A hand can rest a few centimetres into his thigh or chest.
- Joint gaps are much as they were (0.02-0.06 m peaks); the overruns at impact are fewer but not
  gone. More solver iterations would be the next thing to try.

Tests: 376 pass; body hits to stop a man still average 1.54. `test_bodies`' hinge test now kicks
a dead man (no tone) about the hinge's own axis.
