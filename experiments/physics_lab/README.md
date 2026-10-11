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
python3 experiments/physics_lab/run.py --scenario=group:F --out=...          # or A_x,B_y
# footage: three views (front, side, three-quarter; add top), a frame every 2 ticks (30 fps)
python3 experiments/physics_lab/run.py --render --seconds=4 --views=front,side,three --out=build/physics_lab/render
# 1, 5 and 10 men going limp on one tick (run it with nothing else using the CPU)
python3 experiments/physics_lab/run.py --perf --out=build/physics_lab/perf
# the flags again after moving a threshold (no Godot)
python3 experiments/physics_lab/analyse.py build/physics_lab/base
# pictures
python3 experiments/physics_lab/compare.py sheet RUN/SCENARIO [--times=0,0.25,0.5,1,2,3]
python3 experiments/physics_lab/compare.py side BASE/SCENARIO CANDIDATE/SCENARIO   # matched times
python3 experiments/physics_lab/compare.py video RUN/SCENARIO [--slow=4]            # game speed, then slowed
python3 experiments/physics_lab/compare.py diff BASE_ROOT CANDIDATE_ROOT            # every number, side by side
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
  run three times in three processes, every part at every tick, 0.0 m apart.
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

<!-- FINDINGS -->

## Limitations

- Headless numbers aren't visual verification: the footage is what counts. Lavapipe renders only
  (no GPU here); Sean's eye on a real GPU is still the judge.
- One body (the MakeHuman `outlaw`), unarmed, no hat physics (his hat stays on his head as part of
  his head piece).
- The lab drives walking with `walk_to()` as the brains do. The parts are moved by script, so the
  "momentum before" is computed from his centre of mass.
- Joint limits are checked against the pose he went limp in, as the joints are. A limb that was
  already far bent (the crouch) is measured from there, not from anatomy.
- Frame times are this workspace's 2.1 GHz core, ×0.65 for Sean's (CLAUDE.md, Frame budget). They
  include his body's own script (physiology, pools).
- No mocap, no active controller: there is nothing to compare against yet. That's Prompt 09.
