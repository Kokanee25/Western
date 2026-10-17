# 2026-10-16: a ball that drops him shows where it hit; on one foot, his leg holds

Sean (2026-10-16): "Okay keep fixing". The falls' next items (`docs/briefs/fix-the-falls.md`):
- A chest shot looked like a faint, with no sign of the hit (Prompt 09: hit reactions).
- Walking, every fall dropped him straight onto his knees.

**Needs Sean's OK before merging** (Prompt 09).

## The change (`HumanBody`)

- **He curls round the wound as he goes down** (`_hunch`, called by `take_bullet` when the ball
  knocks him down). For the moment his muscles still hold, the tone's target moves from the pose he
  went down in:
  - **Belly or chest from the front:** he doubles over (`HUNCH`) and bends toward the wound's side.
  - **From behind:** he arches a little, away from it (`HUNCH_BACK`).
  - **Thigh or shin:** that leg's hip and knee lose their tone, so it goes from under him and he leans to that side.
  - **Dead:** none of it.

  These are his own forces, not a push, so he goes no faster for them. The ball's own momentum is
  unchanged.
- **On one foot, the stance leg holds for that instant, alive as well as dead.** A walk's or a run's swing foot
  is off the ground, even by 2 cm (`SINGLE_SUPPORT`). Before, only the dead got the column. Standing on both
  feet, the legs share him and it isn't needed: tried, it made the standing falls worse.
- The lab gains group K: six balls that drop him, standing and walking, front, back, side, thigh,
  each `"hunch": true` as `take_bullet` does.

## Numbers (`compare.py diff`)

- **Group K against the version before this** (`rK_old` -> `rK_new`): flags 5 -> 6. The shot from
  behind now comes to rest; before, it never did.
- At 0.3 s, the chest from the front:
  - before: his chest 11 deg back;
  - now: 24 deg forward, with his pelvis tipped back 16 deg as he curls (his own muscles: the halves turn against each other).
- **The column on one foot, all 44 scenarios:** 16 -> 12 flags. Walking blackout and walking ball 2 -> 0 each, walking chest
  shot 2 -> 1. The running chest ball goes 1 -> 2.
- **Tests:**
  - New: `test_bodies::test_a_ball_that_drops_him_shows_where_it_hit`. At 0.45 s the belly-shot chest is 29 deg forward and the thigh-shot chest is 12 deg to his right. Without `_hunch` it's -3 and 0, and the test fails.
  - All 392 pass.
- **Goldens:** `outlaw_down` changes. The shot outlaw now ends on his side, curled; before, he ended folded over his
  knees (`golden_outlaw_down_before_after.jpg`, left the old, right the new). The approval wasn't
  done in this session: the golden is art's file, and Sean decides with the merge. The other four
  fall goldens are unchanged.

## By eye (blind judges, shuffled and unlabelled sheets)

- **The hunch** (`side_K_*.jpg`, top two rows before, bottom two now): **now better in 5 of 6**:
  - chest from the front;
  - belly ("doubles over from 0.3 and goes down folded around his middle"; before, "the classic faint");
  - chest from behind;
  - chest from the side ("bends toward the wounded side, goes down sideways");
  - thigh ("tilts toward the shot side, an arm out for balance").

  Walking chest shot: no difference. The judge's complaint, then fixed: every trunk hit got the same
  forward curl, front or back. Now a ball from behind arches him a little instead.
- **The column on one foot** (`side_walk_*.jpg`, top without, bottom with): **better in 2 of 3**:
  - the walking blackout ("his head drops and he slumps sideways onto a hip"; without it, "sits
    upright on his heels");
  - the walking chest ball.

  The walking chest shot is even: with the column he topples forward stiffly over the planted leg
  instead of dropping onto his knees. Neither shows the hit: walking, the curl doesn't show yet.

## Left

- Walking, the hit reaction doesn't show: he goes over too fast for the curl to read.
- Walking, his momentum never carries him into a stumble or a step: his feet stay planted.
- The endings are believable but much alike: face down, flat.
