# The ragdoll lab

Prompt 01 (`docs/prompts/01_Testing_Lab.md`): a bench for measuring how a man falls today. It runs the
**production** passive ragdoll (`HumanBody.go_limp()`, untouched) through fixed scenarios. It logs every
physics tick, renders three matched views and compares runs. **It changes nothing in the game and
claims no improvement.** It exists so that a later fix (Prompt 09) can be measured against this
baseline.

Everything is in this folder. Outputs go under `build/physics_lab/` (git-ignored; never commit
videos). The baseline's numbers and contact sheets are in `baseline/`.

## Commands

```sh
# all 25 scenarios, headless, one Godot process each (~1 min on 4 cores)
python3 experiments/physics_lab/run.py --out=build/physics_lab/base
python3 experiments/physics_lab/run.py --scenario=group:F,G,A_stand_blackout --out=...  # groups and names
python3 experiments/physics_lab/run.py --scenario=list                      # the names
# footage: three views (front, side, three-quarter; add top), a frame every 2 ticks (30 fps)
python3 experiments/physics_lab/run.py --render --seconds=4 --views=front,side,three --out=build/physics_lab/render
# 1, 5 and 10 men going limp on one tick (run it with nothing else using the CPU)
python3 experiments/physics_lab/run.py --perf --out=build/physics_lab/perf
# the flags again after moving a threshold (no Godot)
python3 experiments/physics_lab/analyse.py build/physics_lab/base
# pictures
python3 experiments/physics_lab/compare.py sheet RUN/SCENARIO [--times=0,0.25,0.5,1,2,3]   # writes RUN/SCENARIO/sheet.png (or --out=)
python3 experiments/physics_lab/compare.py side BASE/SCENARIO CANDIDATE/SCENARIO   # matched times
python3 experiments/physics_lab/compare.py video RUN/SCENARIO [--slow=4]            # game speed, then slowed
python3 experiments/physics_lab/compare.py diff BASE_ROOT CANDIDATE_ROOT            # headline numbers, side by side
# one scenario straight from Godot (what run.py calls)
godot --headless --fixed-fps 60 -s res://experiments/physics_lab/lab.gd -- --scenario=A_stand_shot_front --out=DIR
godot --headless -s res://experiments/physics_lab/lab.gd -- --scenario=list
```

`lab.gd` also takes `--seed=N` (HumanBody.rng_seed), `--model=ID` (the body; default `outlaw`, the
MakeHuman man), `--repeat=K` (in one process; see Determinism), `--cam-dist=M` and `--size=WxH`.
Rendering needs xvfb and lavapipe (`apt-get install mesa-vulkan-drivers xvfb`). Each scenario takes
about a minute for every 4 s drawn.

To try a controller later, put it behind a switch read by the scenario (a new field in
`scenarios.json`). Run both into two roots, then `compare.py diff` and `compare.py side`.

## Files

- `scenarios.json`: the 25 scenarios, A–I. Directions are in the man's frame (−z is the way he
  faces, +x his right):
  - `push` is what's handed to `go_limp()`: 1.2 m/s is a bullet knockdown, 3.0 a heavy blow, 0 a
    blackout.
  - `impulses` are the lab's own named-point impulses (N·s).
  - `pre` is stand, walk, run or crouch before he goes limp.
  - Edit this file to add scenarios.
- `lab.gd` is the command line. `lab_runner.gd` builds the fixture and the man, runs it and logs it.
- Fixtures: level ground, a 20° slope, four 18 cm stairs, a wall, a doorway, a table ahead, a
  table at his side, and a loose 6 kg chair. The chair is the lab's own: production's chairs are
  static props.
- `analyse.py` + `thresholds.json` turn the logs into flags.
- `run.py` runs the scenarios and gathers them.
- `compare.py` makes the pictures and comparisons.
- `baseline/`: the committed baseline. `baseline.json` / `baseline.md` (the numbers and flags of all
  25), `manifest.json`, `perf_run1.json` / `perf_run2.json`, and `sheets/` (contact sheets from the
  footage). `compare.py diff experiments/physics_lab/baseline NEW_ROOT` compares a new run with it.
- A rendered run's flags come from `analyse.py RUN_ROOT` (run.py does it). Rendered runs are cut
  to 4 s (`--seconds=4`), so their settle times and flags are not the baseline's: use the headless
  run for numbers and the rendered one for eyes.

### Outputs per scenario

`ticks.csv` (one row per tick) has:
- centre of mass, position and velocity;
- the fastest part;
- the deepest penetration, self-overlap and joint gap;
- awake parts;
- engine contacts and the sum of engine-reported contact impulses;
- wall-clock frame time.

`segments.csv` (one row per part per tick) has:
- position and orientation;
- velocity: the engine's once he's a ragdoll, finite differences before (the standing parts are
  AnimatableBodies moved by script);
- asleep or not;
- contacts and contact impulse (`get_contact_impulse`, as Jolt reports it);
- penetration;
- self-overlap;
- swing and twist from the pose he went limp in, against `HumanBody.JOINT_LIMITS`;
- knee/elbow bend (the sign as in `tests/test_bodies.gd`);
- the gap at the production joint's anchor;
- per-tick step in m and degrees.

`summary.json` holds the peaks, settle time, sleeping and frame times, plus **`events`**: what was
applied and by whom (below). `flags.json` holds the flags. `manifest.json` records:
- the source SHA;
- the Godot version, physics engine and every Jolt setting;
- ticks per second;
- CPU and threads;
- the command line;
- the scenario's definition, seed and start.

### What is applied, kept apart from collisions

Each scenario's `events` reads the bodies straight after `go_limp()` returns, before the solver
runs:
- `push_given_every_part_mps`: go_limp sets **every** part's velocity to `push`;
- `chest_push_x4_Ns`: the chest's extra `push × 4` impulse;
- `chest_random_impulse_Ns`: the random level kick from `HumanBody._rng`, ±3 N·s per axis;
- `momentum_before_Ns` / `momentum_after_Ns`;
- `lab_impulse` events: the lab's own impulses.

Collision forces are not available per contact as forces. What exists is Jolt's reported contact
impulse per contact (`contact_impulse`), labelled as engine-reported. Constraint forces are not
logged: the engine doesn't expose them.

## Measures and their limits

- **Penetration**: the deepest pair from `collide_shape` of each capsule against the world (layer
  WORLD). Jolt lets resting contacts sink about 2 cm (its penetration slop): a resting foot reads
  0.020.
- **Self-overlap**: computed from the capsules, because the parts don't collide with each other
  (their mask is WORLD only), so the engine reports nothing. Pairs that touch at rest (parent and
  child, siblings at one joint) are left out. Each pair's overlap at the moment he goes limp is
  subtracted.
- **Swing/twist**: measured against the pose he went limp in, which is also where the production
  joints take their zero. The axis is the limb's, from the joint's anchor; twist is the swing-twist
  split about it.
- **Joint gap**: the distance between where the parent and the child each carry the production
  joint's anchor (`Joint_<segment>`'s position at go_limp).
- **Settled**: every part under 5 cm/s and 0.3 rad/s for 30 ticks.
- Frame time is wall clock per tick, measured headless (`--fixed-fps` runs unpaced), and it includes
  the lab's own measuring. The `--perf` runs turn the measuring off.

## Thresholds

The flags are in `thresholds.json`. Each rule needs the measure past its value for N ticks in a row,
so a one-tick spike at impact isn't a flag (its peak is still reported). The values were set on
2026-10-11 from the first baseline:
- 3 cm penetration sits above Jolt's 2 cm slop.
- The joint and limit rules sit above what a clean fall in A shows only at impact.

They are provisional. **They flag; they don't judge.** The visual verdicts below are mine, from the
footage, and kept apart from them.

## Determinism

- **Across processes**, the same build on the same machine is bit-identical: `A_stand_shot_front`
  run three times in three processes: every part at every tick, 0.0 m apart.
- **In one process** it is not. The same scenario run again in the same Godot (`--repeat=2`) was
  19 cm apart by tick 166. Something carried over from the first run (Jolt's body ordering or
  cached state) changes the second, so `run.py` starts one process per scenario. **This matters
  beyond the lab:** `tests/run_tests.gd` runs every test in one process, so a test's fall can depend
  on which tests ran before it. That may be behind the chaos test's same-seed drift (CLAUDE.md,
  2026-10-05).
- Across machines, OSes or Godot builds, results aren't expected to match. Compare numbers within a
  tolerance; compare footage by eye.

## Baseline (2026-10-11, source 59da029)

See `baseline/baseline.md` for the full table and `baseline/*.png` for the contact sheets.

**Since 2026-10-11** (`results/2026-10-11_carry/`): he keeps his momentum into the fall, and a shot
pushes with the ball's own momentum on the part it hit. The scripted shove and random kick below
are gone, and fault 2 is fixed. The baseline is kept as it was, for comparison.

Results of changes measured against the baseline go in `results/<date>_<name>/` (a README with
the numbers and the before/after sheets).

### What go_limp() applied at the baseline (scripted, not physics)

From `events` in every scenario (`baseline/baseline.json`):

- **Every part's velocity is set to `push`.** A bullet knockdown passes 1.2 m/s, so 80 kg gets
  **96 N·s**. A .45 ball carries 4.5 N·s (16.5 g at 274 m/s), so that's about 21 times the ball.
  A heavy blow (3 m/s) is 240 N·s.
- **The chest also takes `push × 4`** (4.8 N·s for a shot) **plus a random level kick.** With seed 1
  the kick is (−1.02, 0, −1.34) N·s, 1.7 N·s across. It's drawn in **world** axes, so the same seed
  pushes him a different way depending on which way he faces. In G (one fall at five headings) his
  resting place, in his own frame, wanders 14 cm sideways (x −0.10 to +0.03) and 5 cm along.
- **Whatever he was doing is thrown away.**
  - Walking at 1.4 m/s he carried 112 N·s; after go_limp, 1.7 N·s.
  - Running at 3.5 m/s he carried 279 N·s; after, 1.7 N·s.
  - Shot while running, the push replaces his run with +99 N·s backwards: he reverses on the spot.
- The parts don't collide with each other (`collision_mask = WORLD`), and the ragdoll doesn't
  collide with other ragdolls or with debris.

### The five most obvious faults (my eye on the footage, numbers from the logs)

1. **He folds straight down like a puppet with its strings cut, every time he goes down from his
   feet.**
   - A blackout from standing (`sheets/A_stand_blackout.png`, t+0.2 to 0.8 s): his centre of mass
     falls from 1.05 m to hip height (0.55 m) in **0.45 s**, nearly free fall (0.32 s), while it
     moves only **5 cm** sideways. The knees fold to **159°**, his heels under his seat; then he
     tips over backwards.
   - The same fold in B, C, D, on the stairs (`F_stairs_down`: he lands kneeling upright on a step
     for ~0.5 s, then tumbles) and at the table (`F_table_ahead`: he folds down and ends lying
     under it, never across it).
   - Nothing in him resists the fold: the joints are limits only, with no stiffness or motor.
2. **A walking or running man stops dead** (fault 1's numbers, above).
   - `sheets/C_run_blackout.png`: at 3.5 m/s he moves **4 cm** before his centre of mass is at
     hip height, and 0.46 m in all.
   - `B_walk_blackout`: he drops to his knees on the spot and folds over them.
   - A real man running at that speed pitches forward 1.5–3 m.
3. **His arms go into his own body.**
   - The parts don't collide with each other, so capsules pass through one another. The peak
     self-overlap beyond the pose he went limp in is 7–21 cm, and every scenario has it (the
     `limb_through_body` column).
   - At rest after a shot from the front, his left forearm lies 8.6 cm inside his pelvis
     (`sheets/A_stand_shot_front_rest_top.png`: one arm shows, the other is inside his hip).
   - Folding over his knees, his chest sinks 17 cm into his thighs (`B_walk_blackout`).
4. **Joints overrun their limits and come apart on impact.**
   - On landing, the head swings 40–61° on a 35° cone. Hands and feet swing up to 43° past their
     limits and twist up to 38° past them, for a tenth of a second or more (`swing_past_limit`,
     `twist_past_limit`; peaks in `baseline.json`).
   - Feet and shins pull **3–4.6 cm off their joints** for several ticks (`joint_pulled_apart`).
   - A hard shove at the shoulder (`E_shoulder_from_left`, t+0.12–0.18 s) whips the hand at
     **~45 rad/s** (47° in one tick) as the arm flails out, and the body doesn't topple the way
     it was pushed: he folds down again.
5. **Some falls never come to rest.**
   - From the crouch (`D_crouch_blackout`), his left foot keeps spinning at ~1.7 rad/s with the
     rest of him still, to the end of the run. All 17 parts stay awake (Jolt sleeps an island
     only when all of it is still).
   - Elsewhere he settles in 1.8–5.0 s. Everything was asleep by the end of the 30 s run (H).

What looks right: the slump against a wall behind him (`F_wall_behind`), sitting back into a loose
chair and going over with it (`F_chair_behind`), the arm catching a table's edge as he goes down
beside it (`I_arm_on_table`), the knees and elbows never bending the wrong way (`wrong_bend` peaks
under 9° in every scenario, the flag's 10° never reached), and nothing launched or exploding (peak part speed 3.3–7.6 m/s, no
discontinuity except the whipped hand).

Measured artefacts, not faults: resting parts sit 2 cm into the ground (Jolt's slop), and
`sunk_into_world` flags 3–7 cm for a few ticks at impact. The three `bounce` flags (E) are his
trunk rocking back as he folds; I couldn't see a bounce in the footage.

### Performance (`--perf`, two runs, headless, this workspace's 4-thread Xeon; ×0.65 for Sean's)

Frame time is the whole frame (his body's script, physiology and pools included), mean (p99):

| men | standing | first 3 s after going limp | from 5 s on (all asleep) | the go_limp tick | bodies / shapes / joints |
|---|---|---|---|---|---|
| 1 | 1.6 (20, warm-up) | 0.5–0.6 (2–3) | 0.04 | 4–5 ms | 17 / 21 / 16 |
| 5 | 1.4–1.6 (2.6) | 1.2–1.3 (2.3–10) | 0.14–0.25 | 11–15 ms | 85 / 105 / 80 |
| 10 | 2.3–3.0 (4–5) | 1.6–1.9 (3.5–4.7) | 0.26–0.27 | 17–26 ms | 170 / 210 / 160 |

- Ten men collapsing at once take ~1.0–1.2 ms a frame on Sean's core. That's against the **whole
  game's** 2 ms physics budget, and it's less than ten men standing: the standing pose script
  costs more than the ragdoll.
- The spike is the tick go_limp builds 17 rigid bodies and 16 joints per man: 26 ms (17 on Sean's)
  for ten in one tick.
- Everyone was asleep within 3–4 s.
- Not split out: the physics engine on its own. Pausing the server freezes the fall it would
  measure.


## Limitations

- Headless numbers aren't visual verification: the footage is what counts. Lavapipe renders only
  (no GPU here); Sean's eye on a real GPU is still the judge.
- One body (the MakeHuman `outlaw`), unarmed, no hat physics (his hat stays on his head as part of
  his head piece).
- The lab drives walking with `walk_to()` as the brains do. The parts are moved by script, so the
  "momentum before" is computed from his centre of mass.
- Joint limits are checked against the pose he went limp in, as the joints are. A limb that was
  already far bent (the crouch) is measured from there, not from anatomy.
- Frame times are this workspace's core (measured 2.1 GHz, CLAUDE.md), ×0.65 for Sean's (CLAUDE.md, Frame budget). They
  include his body's own script (physiology, pools).
- No mocap, no active controller: there is nothing to compare against yet. That's Prompt 09.
