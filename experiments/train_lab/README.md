# The train lab

The train, built step by step (`docs/briefs/train.md`, plan #542). **Step 1 (#543): the track and
the 1D train. Step 2 (#551): couplers, riding, and stops to a timetable** (below). Nothing in the town changes: the test line is laid far out on the flat south and
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

## The test line (`routes/test_line.json`; since step 2 a route file, `test_line.gd` loads it)

| s (m) | What |
|---|---|
| 0–400 | straight, level, south; **the depot** (step 1's mark A) at 120 |
| 400–648 | a left-hand bend, 120 m radius, 90 degrees, 30 m spirals in and out |
| 750–1050 | the climb, 2.5 % (7.5 m up on a fill) |
| 1050–1350 | the descent, 2.5 % |
| 1350–1500 | level; **the mine** (step 1's B) at 1440; the end of the line at 1500 |

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


## Step 2 (#551): couplers, riding, the timetable

**What's new in `src/train/`** (docs/LAYOUT.md "src/train"):

- **Slack:** `TrainSim` steps each car as its own mass, coupled by 65 mm of free play and a draft
  gear's spring past it (dials `coupler_slack`, `draft_stiffness`, `draft_damping`, `substeps`); the
  brakes come on car by car (`brake_propagation`, 0.35 s a car). A start takes the slack up front to
  back (the coach moves ~1.9 s after the engine); a stop bunches it back to front. Every slack-out
  and bunch is an event `{t, coupler, kind out|in, speed, bang}` (`Train.coupler`, `train_events`).
- **The six cars** (`TrainTuning.consist`, #552): engine 9.4 m / 31 t, tender 6.4 / 24, two ore cars
  7.3 / 14 (loaded), a boxcar 9.1 / 12, the express car 10.4 / 11, a coach 12.8 / 13.5: 119.5 t, 66 m.
- **Solids** (`TrainCars`, `TrainView.solids`): every car is boxes you can walk end to end at a
  1.1 m deck with 0.3 m gaps: through the coach and express car (doorways), up steps over the
  boxcar's roof and the tender's tank, along the ore cars, into the cab (open at the gangway). The
  stairs are walked as ramps over them (as the saloon's stair). Bullets hit them; they shove crates
  (struck, a crate goes loose and the pilot's wedge turns it aside) and strike men.
- **The route as data** (`TrainRoute`, `routes/*.json`): plan, profile and named marks. The
  re-laid line (`routes/relaid.json`: 2.1 km, a right-hand bend and a left-hand one, 3 % up, 1.5 %
  down, a water stop) runs the same timetable.
- **The timetable** (`timetable.json`, `TrainTimetable`): stops by mark and dwell; the run times are
  measured on the line itself (the engineer drives it once at `planned_kmh`) plus `padding`.
- **The engineer** (`TrainEngineer`): drives by the regulator, brake and reverser to the timetable;
  brakes for the mark from the stopping distance; late, he runs up to `max_kmh` and stands only
  `dwell_min`. His body stands in the cab (a ball kills him, and then nobody drives).

**Running it**

```sh
# The scenarios (step 1's and step 2's: slack, ten stops, the timetable on time / late / re-laid)
godot --headless -s res://experiments/train_lab/run.gd -- --out=build/train_lab
python3 experiments/train_lab/graphs.py --runs=build/train_lab --out=build/train_lab/graphs

# In a game: the engineer runs the timetable, you on the coach, walk to the cab, jump off
python3 tools/bridge.py "train_lab" "train_run 0" "train_board coach back" "wait 30" "train_cross" "train_jump_off right"
# The films (each a game under xvfb, ~10-20 min under lavapipe)
python3 tools/bridge.py run experiments/train_lab/films/slack.txt --size=960x540 --movie=build/films/slack.avi
```

New bridge commands: `train_route test_line|relaid`, `train_run [LATE]`, `train_goto MARK [KMH]`,
`train_engineer`, `train_board CAR [back|front|mid]`, `train_cross [run] [nojump]`,
`train_jump_off [left|right]`, `train_rider`, `train_crate S [SIDE]`, `train_man S [SIDE]`,
`train_struck`, `train_placed`, `train_hits`, `train_events [N]`, `train_where CAR`, `train_watch
CAR ... [follow]`, `train_slowmo X`.

**In a build:** **8** starts the engineer on the timetable and puts you on the coach's back
platform: walk forward through the train to the cab, ride it round, jump off (8 again for a new run).

Results: `results/2026-11-01_step2/` (its `summary.md`).


## Step 3 (#542): the models

**What's new:**

- **The engine and tender** from Blender by script (`blender/engine.py` -> `assets/train/engine.glb`,
  `tender.glb`, `engine_rig.json`; `~/bpyenv/bin/python experiments/train_lab/blender/engine.py`,
  bpy 5.2): a D&RG class 70-style 2-8-0 (37 in drivers, 15 x 20 in cylinders, a diamond stack, box
  headlight, wooden pilot and cab), the tender a U tank round its coal. `EngineModel` moves its
  parts by distance: drivers s / r, the side rods on the pins (right leading left by a quarter),
  the main rods from pin to crosshead; four exhaust beats a wheel turn, each a puff up the stack
  sized by the steam, the cylinder cocks blowing at a start; the stack's own smoke; the headlight
  at night. Materials by name in the game's look (PixelArt metals, woods mapped in their own space).
- **The five cars of boards** (`TrainModels`): sills, a plank deck, truss rods, drawheads,
  stirrups; the ore cars' plank sides on stakes and a low heap of ore; the boxcar's red sheathing,
  sliding doors, roof walk, end ladders and brake wheel; the express car's green sheathing, doors,
  barred windows, and inside the strongbox, mail case and parcels; the coach's varnished sides,
  windows, clerestory, platforms with railings, and inside benches both sides of the aisle, a stove
  and two lamps (lit at night). Arch-bar trucks, their wheels turning with distance.
- **Ladders:** the boxcar is shut; you go over it by the ladder at each end and its roof walk
  (`Ladder`, the player's `_ladder_step`: walk into it to climb, walk out over its top to go down;
  it carries you with the car). Step 2's steps up its ends are gone.
- **Passengers:** `train_passengers N` seats the Studio's men in the coach, window seats first.

New bridge commands: `train_passengers N`, `train_models on|off`. Run files: `sheet.txt` (golden
hour and night), `cost.txt` (the frame with the whole train in view, models then boxes),
`films/rods_start.txt`, `films/walk_train.txt`.

Results: `results/2026-11-02_step3/` (its `summary.md`).
