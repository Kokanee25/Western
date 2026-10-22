# A ball on the tick he goes limp (fix 1)

**Before:** `HumanBody.go_limp()` moved each part's collision shapes onto a new RigidBody3D, and
the physics space doesn't hold a new body until it next steps. A ball flown on that tick passed
through him. That means a blast's gravel and splinters (fired on the tick the blast throws him),
and a shotgun charge's pellets after the one that knocked him down.

**The fix:** the standing part keeps a copy of its shapes until it's freed with the rig at the end
of the frame. A ball's push on a man already limp goes to his rigid part, whichever part it struck.
Regression test: `test_injuries.gd`, `test_a_ball_on_the_tick_he_goes_limp_still_hits_him`. It
fails before the fix and passes after.

**Measured** (`run.py` against `baseline/`, `report.py diff`). Only these runs changed, and they
changed the same way on all four men (the outlaw's rows shown):

| run | what changed | before | after |
|---|---|---|---|
| dynamite_1m outlaw | outcomes | {'doctor': 'n/a', 'none': 'lives (-0 ml)', 'packing': 'n/a', 'tourniquet': 'n/a'} | {'doctor': 'lives (-0 ml)', 'none': 'lives (-0 ml)', 'packing': 'lives (-0 ml)', 'tourniquet': 'n/a'} |
| dynamite_1m outlaw | wounds | 1 | 3 |
| shotgun_05m_belly outlaw | outcomes | {'doctor': 'dead first (4:23)', 'none': '1:25 blood', 'packing': '4:23 blood', 'tourniquet': 'n/a'} | {'doctor': 'dead first (4:22)', 'none': '1:25 blood', 'packing': '4:22 blood', 'tourniquet': 'n/a'} |
| shotgun_05m_belly outlaw | wounds | 6 | 7 |
| shotgun_05m_belly outlaw | pellets_hit | 6 | 7 |
| same_tick outlaw | wounds | [1, 0, 1] | [1, 1, 1] |

- At 1 m two pieces of gravel now wound him: flesh wounds that clot.
- The 5 m charge into the belly lands seven pellets, not six; the seventh is the one after the
  knockdown.
- Nothing else in the 160 runs moved.
