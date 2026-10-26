# More cores, step 4: the people's tick in phases (2026-10-26)

`docs/briefs/more-cores.md` "Step 4" (issue #395). This workspace's VM (4 vCPUs; x0.65 for Sean's
core, as the brief scales), headless, `--fixed-fps 60`, one game at a time, nothing else running. Every timed run
is the lab's ten D fights:

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall --hours=golden --weapons=revolver \
    --styles=careful --bodies=studio --variant=D --seeds=1-10 --jobs=1 --out=build/gf/<run> \
    [--game-args=--people-threads=off | --game-args=--jolt-sight]
python3 experiments/gunfight_lab/same_fight.py build/gf/<a> build/gf/<b>
python3 experiments/gunfight_lab/results/2026-10-26_step4/perf.py name=build/gf/<run> ...
```

**before** is main at c1352a34 (step 3 merged); **step4a** is the first commit (b756fda5, the order
made explicit, no threads); **step4b** the second (c69aa698, the phases; the pure half on the
worker pool); **step4b_off** the same build with `--people-threads=off`; **step4b_jolt** the same
build with `--jolt-sight` (every sight line asked of Jolt). Each from its own worktree. `runs/<name>/`
has every fight.

## What it is

**The order made explicit (step4a).** `PeopleTick` (`src/people/people_tick.gd`) gives every
`HumanBody` a `tick_index` as he first enters the world (kept; in `to_dict`). The people's own
`_physics_process` is gone: the body's step is `HumanBody._tick`, and his brain, `FaceLife`,
`FaceSpeech` and `Senses` each have a `tick(delta)` they register with him (`add_ticker`, in tree
order). PeopleTick ticks everyone in index order, each man's body then his nodes, every node only
while its physics processing is on and it can process (its switch, as before: the tests and labs
that turn a brain off still do).

Where PeopleTick stands decides what ticks before and after the people, since the engine ticks a
priority in tree order. In the lab's street the people aren't together in the tree: the street
dressing's eight townsfolk come first, then **the player**, then the town's men, then the spec
saloon and its 70-odd props, then the fight's men. A PeopleTick before the first man moved the
fight's men ahead of the player, and seed 1 parted from main at 0.97 s (the Kid saw you a tick
later). So it's an internal child of the **last** man to come in: the fight's men, who come last,
tick after what they ticked after before (the player, the room), and what came after the people
(the balls in flight, a stick's fuse) still does. The street's townsfolk now tick after the player
and the props instead of before them. Made in his `_enter_tree`, a man added before the frame's
ticks ticks in that frame, as the engine did.

**The phases (step4b).** Each physics tick, in PeopleTick:
1. each man that ticks, on the main thread, `begin_prepare`: the day's time scale (a node), and
   whether his pose can be worked out ahead (standing, on no clip or mocap walk, not stumbling or
   getting up: those move him or ask the physics as the pose goes);
2. each man's `prepare`, pure, his own data only: `Physiology.step`, then, standing,
   `_favour_step` and `_pose_maths` (the goals, the blends, the flinch springs, the breath, into
   `_rots`, the 17 joints' turns). On the worker pool (`WorkerThreadPool.add_group_task`, high
   priority, issue #392) while `Settings.people_threads` is on, else one after another here;
3. each man's tick in order: `_physics_step` takes what was done ahead (the stains, the signs, his
   velocity, `_pose_writes`: the joints set, the rig, the hands, the skeleton), then his brain, face
   and senses.

`_apply_pose` was split into `_pose_maths` and `_pose_writes` with the same arithmetic in the same
order (a man not ahead runs both on the main thread, as before). The maths moved ahead of the
stains, signs and `_after_step`, which read none of it. `Physiology.warm()` fills its shared
muscle lists on the main thread so the workers only read them.

Not moved, and why:
- **The gun hand** (`GunHand.step`): it takes the aim the brain chooses that tick, read off the
  gun's muzzle node mid-brain; a tick early it would aim at last tick's want. 0.25 ms here for the
  three men.
- **The signs' decisions** (`WoundSigns`): every fourth tick, each decision followed at once by its
  decal or drip in the scene; nothing worth a worker.
- **The people's capsules in SightWorld** (the issue's last line): no sight line asks `BODY_PARTS`
  through Sight yet (step 3's handover). Feeding 17 parts a man every tick (~250 bodies moved in
  SightWorld a tick) would pay for `_friend_in_the_way`'s 0.36 lines a frame (`q_brain`). They
  come with the first batch of lines that should meet a man.
- **Phase 3, one batch of sight lines for the tick**, measured instead (below).

## The gate

- **Ten fights twice at each commit: 10 of 10 the same** (`same_fight_step4a.txt`,
  `same_fight_step4b.txt`; main's own runs too, `same_fight_before.txt`, `same_fight_before_1_vs_3.txt`).
- **Against main, event for event: 10 of 10 at both commits** (`same_fight_before_vs_step4a.txt`,
  `same_fight_step4a_vs_step4b.txt`): every fight's record (the gang's and your events, shots,
  hits, moods, the ending) is main's. Not every number in the street is: the townsfolk who now
  tick after the player and the saloon's props (the street dressing's eight, before the player;
  the town's men, before the props) walk and look a little differently, so the fights' line counts
  move by a few in a thousand (`q_walk` +2-3 % in the long fights, `q_senses` and `q_lamps` a
  few dozen a fight, `line_counts.txt`). Main against itself and step 4a against step 4b are count
  for count the same, so that's the order made explicit, not noise.
- **Threads on against off: 10 of 10 the same**, every count too (`same_fight_threads_on_vs_off.txt`):
  the workers are the same game as one thread. `tests/test_people_tick.gd` holds it for six
  wounded men (every pose, flinch, favour, breath and physiology number) and holds the order and
  the switches.
- **The physics lab: 151 of 151 falls the before's** (`physics_lab.md`).
- **The body lab: 216 of 216 records the before's** (`body_lab.md`).
- **The whole suite: 739 passed**, and `test_perf`'s three budgets failed, as they do on main in
  this container today (alone, main 20.1 / 20.9 / 42.3 ms a frame against 16 / 16 / 30; step 4
  19.1 / 19.4 / 42.4): this VM is slower than the one the budgets were set on, not this step.

## The numbers (ms a frame; a `q_*` row is a count a frame) — `perf.md`

This VM read slower than on step 3's day (main 28.4-30.0 ms a frame against 19.6 then) and
drifted about 10% between runs: two runs of one build differ by up to 1.6 ms, and the systems this
step doesn't touch (`player`, `structures`, `fire`, `horses`) drift with it. So the runs were
alternated (before, 4a, 4b, 4b off, 4a, 4b, before, 4b jolt, 4b, 4b off), and the table after
this one scales each run by those controls (`normalise.py`, `normalised.md`). Means of the runs:

| | before (3) | step 4a (2) | **step 4b (3)** | 4b, threads off (2) |
|---|---|---|---|---|
| frame (mean / p95) | 29.32 / 34.89 | 30.97 / 37.46 | **30.74 / 36.85** | 30.74 / 36.85 |
| window / step / rest | 19.83 / 3.18 / 6.21 | 21.07 / 3.31 / 6.49 | 20.89 / 3.30 / 6.46 | 21.00 / 3.23 / 6.41 |
| people | 16.03 | 16.82 | 16.51 | 16.73 |
| `people_prep` (phase 2, the main thread's time) | – | – | **1.08** | **1.72** |
| `people_prep_sum` (its men's own times) | – | – | 2.11 | 1.67 |
| `people_body` | 7.09 | 7.35 | 5.88 | 5.68 |
| `people_skeleton` / `senses` / `outlaw_brain` | 1.07 / 2.10 / 3.85 | 1.12 / 2.21 / 4.09 | 1.12 / 2.30 / 4.07 | 1.10 / 2.23 / 4.01 |
| `q_cover` / `q_senses` / `q_lamps` / `q_walk` | 60.6 / 45.7 / 4.4 / 16.6 | 60.6 / 45.7 / 4.4 / 16.8 | the same | the same |
| `q_writes` | 74.05 | 74.05 | 74.05 | 74.05 |

Scaled by the controls (`normalised.md`), means:

| | before | step 4a | **step 4b** | 4b, threads off |
|---|---|---|---|---|
| frame | 29.32 | 29.44 | **29.22** | 29.82 |
| people | 16.03 | 15.99 | **15.69** | 16.23 |
| `people_body` + `people_prep` | 7.09 | 6.98 | **6.62** | 7.18 |

- **The order made explicit is free**: step 4a against main, the frame +0.1 and the people
  -0.04 scaled, inside the noise.
- **Phase 2, its wall time against its single-thread sum: 1.68-1.76 ms on one thread; on the pool
  1.04-1.12 ms of the main thread's time** for 2.04-2.15 ms of the men's own time. A man's half
  costs about a quarter more on a worker (GDScript there, its data warm in another core's cache),
  and the pool's wake and wait are inside the 1.08. So on this 4-core box the threads pay
  **~0.6 ms of the main thread** (threads on against off, scaled: people -0.54, the frame -0.6).
- **Against main: the people -0.34 ms, the frame -0.1** (scaled; unscaled +1.4, the drift). The
  brief expected -0.5 to -1. What's on the workers is ~1.7 ms of work (physiology and the pose's
  maths for ~16 people); its quarter dearer on a worker and the split's own cost on the main
  thread (threads off is +0.2 against 4a) take the rest. More cores won't do much more for
  phase 2: the ideal on Sean's 16 is ~1.7 / 16 plus the wait, so ~0.3 ms better than here at
  best (x0.65 for his core: ~0.7 ms against 1.1 here).
- `senses` reads +0.1 in step 4b: the `lines_senses` timer below, inside it (the lab runs with
  Prof on; off in the game it's two calls that return at once).
- **Threads stay on** (`Settings.people_threads`, default on; `-- --people-threads=off` for a
  run, `[performance] people_threads=false` in the settings file): they pay here, and they are the
  same game.

### Phase 3, one sight batch a tick: measured, not built

`lines_senses` times `Senses._clear`'s line (the review's ask: that phase on its own, Jolt as the
control on the same build):

| | step 4b, Sight (3 runs) | step 4b, `--jolt-sight` |
|---|---|---|
| `lines_senses` (ms a frame) | 0.47 | 0.62 |
| `q_senses` (lines a frame) | 45.7 | 47.5 (other fights: Jolt's hits round differently) |
| per line, with the timer | ~10 us | ~13 us |

Sight one at a time already saves 0.15 ms of the senses' lines against Jolt. One batch at the
bench's 0.7 us a line (x1.5 for this VM's day) would be ~0.05 ms, so **phase 3 could save ~0.4 ms
here** of the senses' lines, plus the lamps' (4.4 a frame, ~0.04). The cover search's 60 lines
are asked inside each brain's decisions and don't batch without restructuring the brains.

Not built, because a batch for the tick means every man looks from the tick's snapshot (where
everyone stood before anyone's tick), not from where the men before him in the order have just
moved: a change to what each man sees when, so the fights re-baseline. That is a step's worth on
its own (its gate is the perception lab and the fights, as step 3's was), and this step's gate
held main's fights. The handover on #396 carries it for the review to place.

## Files

`perf.md`, `perf.py` (step 3's with the people's phases first), `normalised.md`, `normalise.py`,
`same_fight*.txt`, `line_counts.txt`, `physics_lab.md`, `body_lab.md`, `runs/` (every run's fights). What was read for this step: CLAUDE.md; the brief's
"The per-person work", "The design" B and F, "The steps" 3 and 4, "How a step is reviewed"; step
3's README and the handover on #395; the gunfight lab's README; HumanBody's tick, pose, favouring
and walking; Physiology's step; Senses, the brains' and faces' ticks; Godot's WorkerThreadPool and
`Node.is_greater_than`, by experiment.
