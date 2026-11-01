# The train lab

The train, built step by step (`docs/briefs/train.md`, plan #542). **Step 1 (#543): the track and
the 1D train.** Nothing in the town changes: the test line is laid far out on the flat south and
east of town, and only while the lab's built (its own ground drawn under it, the painted
backdrop's rings hidden: the line runs out through them).

## The parts (src/train/, to be promoted into the game)

- `TrainTuning` (`config/train.tres`): every dial, all *proposed*; where each number comes from is
  in the brief's "Numbers and where they're from".
- `TrainSim`: the train in one dimension, `s` (its front's distance along the line) and `v`, from
  tractive effort (least of steam effort falling with speed, power over speed, adhesion), Davis
  resistance, curves, breakaway, the grade under each car by its weight, and brakes gripping
  harder as the wheels slow. The regulator follows the hand at a rate, the steam the regulator with
  a lag, the brakes set and release over seconds. Fixed step, no dice: deterministic.
- `TrackLine`: the line as plan (segments of linearly changing curvature: straights, arcs, easement
  spirals) and profile (grades eased over vertical curves), made into a `Curve3D` (a point every
  5 m, handles on the tangent, baked every 0.25 m); `grade_at`, `curvature_at`, `transform_at`;
  draws rails, ties (a MultiMesh a 100 m chunk), ballast and the fill to the ground (fill and
  ballast collide).
- `TrainView`: boxes on trucks; each truck stands on the line at its own distance, the body is the
  chord between them, so it swings through the bend.
- `Train`: the sim on the physics tick, the cars drawn at the interpolated distance each frame
  (`s_before` to `s`), so they move smoothly at any frame rate; `cost` counters.

## The test line (`test_line.gd`)

| s (m) | What |
|---|---|
| 0–400 | straight, level, south; **mark A** (the depot) at 120 |
| 400–648 | a left-hand bend, 120 m radius, 90 degrees, 30 m spirals in and out |
| 750–1050 | the climb, 2.5 % (7.5 m up on a fill) |
| 1050–1350 | the descent, 2.5 % |
| 1350–1500 | level; **mark B** (the mine) at 1440; the end of the line at 1500 |

## Running it

```sh
# The scenarios on the 1D train alone (seconds), then the graphs
godot --headless -s res://experiments/train_lab/run.gd -- --out=build/train_lab
python3 experiments/train_lab/graphs.py --runs=build/train_lab --frames=build/train_lab/frames_curve.csv --out=build/train_lab/graphs

# In the game
python3 tools/bridge.py start --size=960x540
python3 tools/bridge.py "train_lab" "train_cam chase" "throttle 1" "wait 20" "train" "train_cost 10"
python3 tools/bridge.py run experiments/train_lab/film.txt --size=960x540 --movie=build/train_lab/film.avi
```

Bridge commands (`bridge.gd`): `train_lab`, `train`, `throttle X`, `brake X`, `reverser 1|-1`,
`train_place S|A|B [KMH]`, `train_drive off|hold [KMH]|whole [KMH]`, `train_cam
cab|chase|curve|side_a|side S|player`, `train_log on|off|PATH` (every drawn frame: the jitter and
drift checks), `train_record on|off|PATH` (every tick), `train_cost [S]`.

**In a build** (`play.gd`, added by `main.gd`): **9** builds the line and puts you in the cab (9
again to get out); **0** the next camera (cab, chase, lineside at the bend, lineside at A, you).
In the cab: **W/S** open and shut the regulator, **D/A** the brake on and off, **R** the reverser,
the mouse looks round.

Scenarios (`scenarios.gd`; tests `tests/test_train.gd`): `start`, `stop30`, `climb`, `descent`,
`whole_run` (a simple driver A to B), `top_speed`.

## Results

Step 1: `results/2026-11-01_step1/`: the summary, the graphs, the frame-cost numbers and the film
(`films/start_curve_stop.mp4`, 80 s: the start at A from the lineside then chasing, the bend
chasing and from the lineside, the stop from 30 km/h). The faint vertical stripes in the film are
the movie writer's at this size, in the raw frames too, not the train.
