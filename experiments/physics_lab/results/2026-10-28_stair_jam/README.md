# 2026-10-28: the stair-down "jam" (issue #471), and keep_stride on in the game

Issue #471 step 1: running straight down the saloon stair with `--momentum=on`
(`X_stair_down_run_back`), he seemed to land on the lower treads with his left shin and right
forearm 8-10 cm apart at their joints for ~5 s (`segments.csv` `joint_gap` > 0.08 for ~300 ticks a
part), and the momentum round's flags rose 94 -> 434 (`joint_pulled_apart` 46 -> 289).

## What it was: the lab's ruler, not his joints

- Measured at the anchors the physics joints hold (each joint's point in both its bodies as
  `go_limp` makes it), every joint of his stayed within 5 mm through the whole fall and at rest,
  in this scenario and the six others that showed it.
- The lab measures `joint_gap` (and swing and twist) from a reference taken when it sees him go limp
  (`lab_runner._go_limp` -> `_take_reference`). A `knock` on the move doesn't put him down at once:
  he stumbles on and goes limp in his own tick (`HumanBody._fall_now`), and the lab sees it the tick
  after. By then, at 3.3 m/s, every part has gone on ~5.5 cm (checked in `X_wall_run_back`: the
  joint nodes 4-7 cm from the joints' true points in the parts, the planted foot's 0.5 cm). Both of a joint's points are off the same way, so a
  straight limb reads whole; bend the knee or elbow ~120 deg and they read 2 x 5.5 x sin 60 = 9.5 cm
  apart. That's the 8-12 cm, on knees and elbows folded hard, only in the stumble falls (the walking
  ones at ~1.3 m/s read 3-5 cm), and more of them with `keep_stride` (he goes limp at 3.3 m/s, not
  ~2).
- The lab now takes the reference on `HumanBody.fell` (inside `go_limp`, before the solver moves
  him); a fall the lab starts itself is measured as before (`fell` fires in the lab's own
  `go_limp` call, the same tick).
- Contacts at rest (`X_stair_down_run_back`): his shin lies on the floor against the first tread's
  nose, his foot up on it, his right forearm on the floor under his chest by the door's king stud:
  head-down at the stair's foot with his legs up the treads. Nothing wedged.

Group X, `x_gaps_before_after.txt` (momentum on, the falls themselves identical):

| | ref a tick late | ref as he goes limp |
|---|---|---|
| falls with a joint > 8 cm apart | 7 of 16 (2,976 ticks) | 0 |
| falls ending with a joint > 4 cm apart | 13 of 16 | 0 |

`x_tally.txt`, `x_tone.txt` (this session, off vs on; the momentum round's x_off / x_half in
brackets):

| | keep_stride off | on |
|---|---|---|
| travel (mean) | 0.84 m (0.84) | 1.16 m (1.17) |
| broke something | 8 of 16 (7) | 13 (13) |
| flags | 25 (94) | 63 (434) |
| `joint_pulled_apart` | 4 (46) | 5 (289) |
| `launch` | 5 (5) | 35 (34) |
| `sunk_into_world` | 7 (7) | 12 (11) |

The falls are the momentum round's (travel, breaks); the flags it added were nearly all the ruler.
What's left with the switch: `launch` (the three railing falls' 2.3 m drop, and the stumble's gait
at 3 m/s down the treads before he goes limp) and a few more `sunk_into_world` (harder landings).

`X_stair_down_run_back` has cameras that see him now: `focus_ahead` 2.6 m (the lab's new scenario
field: where he lands, not where he's hit) and the views `three_left^1.5`, `left^1.5` (seen 0.80
and 0.67 of his parts on average; the old `front^3.0` looked from behind the stair's foot).

```sh
python3 experiments/physics_lab/run.py --scenario=group:X --model=bold_cowboy_s3_talking [--momentum=on] --jobs=4 --out=...
python3 experiments/physics_lab/tally.py OFF ON;  python3 experiments/physics_lab/tone.py OFF ON --each
```

## Step 2: keep_stride on in the game

`HumanBody.KEEP_STRIDE_GAME := true`. The gunfight lab's `momentum=` now defaults to the game's
(it forced the switch off unless asked); the ragdoll lab already did.

The 50 D+ fights with the game's setting (no `momentum=`; `falls_game.md`, `quits_game.md`):

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall,spec_stair,spec_gallery,spec_back,spec_front \
    --hours=golden --weapons=revolver --styles=careful --bodies=studio --variant=D \
    --fixes=all+pain_fight+floor_fight+odds+flinch --seeds=1-10 --jobs=4 --falls=1 --out=build/gf/game
python3 experiments/gunfight_lab/falls.py build/gf/game;  python3 experiments/gunfight_lab/quits.py build/gf/game
```

- Falls: the momentum round's `on` column (50 down, 10 moving, 6 stumbling, travel max 1.57 m, 28 hit
  something at >= 0.5 m/s, 4 fell further), but one broke something (none then).
- They still commit: fights 53.8 s (median), 41.4 s of shooting, 45-90 s of shooting in 36%, anyone
  quits in 46%, you down in 56%.
- Still four men in five go down standing: more deaths on the move is the gang's brain (the momentum
  README's step 4, issue #483).

Tests: all pass but `test_perf`'s budgets, which fail on this VM on main's setting too (calm 17.1,
cluttered 19.5 ms with the switch off; cluttered 16.8, burning 30.1 with it on: the VM's noise).
