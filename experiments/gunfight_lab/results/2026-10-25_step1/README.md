# More cores, step 1: the determinism ground (2026-10-25)

`docs/briefs/more-cores.md` "Step 1". This workspace's 2.1 GHz core (x0.65 for Sean's), headless,
`--fixed-fps 60`, one game at a time. The lab command, run twice on the new build (`step1_a`,
`step1_b`) and once on main before it (`main_before`, main at 3eab313):

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall --hours=golden --weapons=revolver \
    --styles=careful --bodies=studio --variant=D --seeds=1-10 --jobs=1 --out=build/gf/<run>
python3 experiments/gunfight_lab/same_fight.py build/gf/step1_a build/gf/step1_b
python3 experiments/gunfight_lab/results/2026-10-25_step1/perf.py main=... step1_a=... step1_b=...
```

## The gate

**10 of 10 fights the same** (`same_fight.txt`), `step1_b` run with the full test sweep on the
other three cores at the same time. The runs' records are in `step1_a/`, `step1_b/` and
`main_before/` (`fights/*.json`, `manifest.json`).

The new build's fights are **not main's** (`same_fight_main_vs_step1.txt`: 0 of 10), on purpose:
the player's shot now leaves on the physics tick after the trigger's read (its line, sway and
kick read then: the query rule), and the settle's budgets are counts. Same kind of fight
(main: 6 gang out, 4 you down, 27-90 s; step 1: 4 and 6, 17-88 s; a re-baseline, not a change).

## The numbers (`perf.md`; ms a frame, a `q_*` row queries a frame)

| | main | step 1 (a) | step 1 (b, tests alongside) |
|---|---|---|---|
| frame (mean / p95) | 14.11 / 18.94 | 14.59 / 20.36 | 16.61 / 24.90 |
| people (mean / p95) | 7.92 / 10.01 | 8.34 / 10.72 | 8.65 / 11.61 |
| window / step / rest | - | 10.01 / 1.09 / 3.42 | 10.41 / 1.96 / 4.17 |

No gain expected and none had: the 0.5 ms between main and `step1_a` is different fights (each
system's ms moves with how long the men search and shoot), not the counters: `Prof.count` is
0.09 µs a call with Prof off (the game) and 0.31 µs on (the lab), ~0.05 ms a frame in the lab.

**The counts, step 2's targets** (the same in both runs, to the hundredth):

| Counter | a frame | Of |
|---|---|---|
| `q_writes` | 335.9 | the people's pivots set (~20 people x 17) |
| `q_cover` | 65.3 | the cover search and routes (bursts while searching) |
| `q_senses` | 46.4 | the looks' lines |
| `q_walk` | 18.5 | the slide, the ground ray, the waypoints' footing |
| `q_lamps` | 4.5 | SightLight's lines |
| `q_brain` | 0.37 | the brains' own rays (clear shot, friend in the way, aim point) |
| `q_balls` | 0.19 | the balls in flight |
| `q_signs` / `q_body` | 0.10 / 0.01 | wound signs' drips; the body's other queries |

The frame's split (`PhysicsWindow`): the **window** (our physics ticks) is 10.0 of 14.6 ms, Jolt's
**step** 1.1, the **rest** (idle process, the engine; headless, no drawing) 3.4. The "untimed
~6.5 ms" of the threading review is mostly the step and the rest: the window is nearly all named
timers (people_body 3.3, outlaw_brain 2.3, senses 1.0, floor_marks 0.8, civilian_brain 0.4,
player 0.3, structures 0.3, fire 0.3, ...), and `people_skeleton`'s 1.0 is in the idle process,
so inside `rest`.

## What else was checked

- Every test file, each in its own Godot (98 files, 0 failures; `World.space`'s guard on: the
  sites it found are in commit 2).
- `test_chaos` five times on one worker thread with the CPU loaded (`chaos.md`, `chaos_load.sh`):
  five different results before, the same five after.
- The physics lab's 151 falls against main's run (`compare.py diff`): 150 identical; the 151st,
  `Q_rail_charge_front` (a charge into the railing), differs from main's one run, but main gives
  three different results in four runs of it (the railing's settle timed by the clock, as the lab
  runs without `deterministic`) and this build the same in three.
