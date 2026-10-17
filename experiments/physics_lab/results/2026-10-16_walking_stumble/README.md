# 2026-10-16: shot down on the move, he stumbles on a step, then his legs go

Sean (2026-10-16): "Yeah walking stumble". **Needs Sean's OK before merging** (Prompt 09).

## What was wrong

A ball that drops a man (`take_bullet`'s knockdown roll) made him go limp on the tick it hit him.
Walking or running, he dropped in his tracks. Two blind judges:
- "knees down by 0.4 and propped up on his arms, like a marionette dropped onto its knees";
- "too sudden for a running man".

## The change (`HumanBody._knocked`, `_stumble_on`, `_fall_now`)

- **When he stumbles:** he's on the move (walking or running, over `STUMBLE_FROM` = 0.8 m/s),
  conscious, and not hit in the head or neck.
- **What he does:** he stays on his feet about a step.
  - A walk's ~0.6 s, a run's ~0.35 s (cadence rises with speed), ±20%.
  - A shot leg gives in 0.25 s.
  - His stride carries him on, slowing to 60%.
  - He flinches at the hit and folds round a wound in his front within 0.2 s, toward its side
    (`STUMBLE_FOLD`).
- **Then his legs go:**
  - He goes limp with the ball's push on the part it hit, and curls round it (`_hunch`).
  - The stance-leg column is off; his knees keep a third of their tone (`LEGS_GONE`), so they
    buckle first.
- **While he stumbles, his body steers.** Brains leave him be (outlaw and civilian brains), and
  anyone else's `walk_to` doesn't move him.
- **A second hit** as he stumbles drops him at once.
- **No change when:**
  - he's standing still or slow: he drops where he is, as before;
  - he's killed outright (the head shot): he drops at once, as before.
- **The lab:**
  - New option `"knock"` (a ball as `take_bullet` has it, stumble and all).
  - New group L: walking chest, belly, back and thigh; running chest and belly-from-the-side.
  - The lab's "limp" is when he actually goes limp. Summaries carry `hit_t`.

## Numbers

- Group L flags: 1 before, 14 now. All marginal:
  - running, an arm or knee 3.1-3.3 cm off its joint as he lands at speed (threshold 3);
  - a planted foot 3.5-3.9 cm into the ground;
  - the neck 15 deg past its cone, landing face first.
- He stays up 0.25-0.6 s, and walking carries on 0.6 m.
- **Tests:**
  - New: `test_bodies::test_shot_down_walking_he_stumbles_on_a_step_then_drops`. It checks:
    - he's not limp the instant he's hit;
    - he's down within 1.5 s and stays up at least 0.25;
    - he goes on forward at least 0.3 m (0.57 s and 0.63 m);
    - another brain's `walk_to` can't move him;
    - a second hit drops him.
  - All 393 pass.
- **Goldens:** unchanged by this. The golden men stand still; `outlaw_down`'s change is the hunch
  (`../2026-10-16_hit_reactions/`).

## By eye (two blind judges, shuffled and unlabelled)

- **The stumble against dropping where he's hit: the stumble better in 6 of 6, twice.**
  - The first judge saw the stumble with his legs held; it named the moment his legs go: "he
    tips forward as a stiff plank pivoting at his boots, or bends double on near-straight legs".
  - So at the end of a stumble his knees give (above). The second judge: "in every sheet the
    better version carries him on 0.6 to 0.8 s and then collapses at the knees; the other is a
    rigid plank or dive within 0.4 s".
- **The second judge's remaining fault:** "for 0.6 to 0.8 s he walks on completely normally, with
  no flinch or hunch". So he folds round a wound in his front within 0.2 s, not over the whole
  stumble. In the final sheets he's hunched over it by 0.4 s.

Sheets: `side_<scenario>.jpg`. Side view, columns 0, 0.2 ... 3 s after the ball hits him. The
top row is before (down where he was hit), the bottom row is now.

## Left

- No hand to the wound: his arms swing on.
- A shot from behind: he only carries on, with no arch while he stumbles.
- The run's joints are a little loose at landing (above).
