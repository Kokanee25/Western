# The trestle lab

The game's biggest moment, measured (#623; brief `docs/briefs/trestle.md`; the plan #542, the last
act #466): a towering timber viaduct over a deep gorge, the charges that bring it down by its load
paths, and the train going with it, every frame of it held to #492's gate. Nothing in the town
changes: the lab's line is laid 2.6 km east of town, past the town's ground (it collides out to
2 km), and only while the lab's built.

## The parts

- `src/train/trestle.gd` (`Trestle`, a `TrackChunk`): the viaduct over the route's crossing, built
  from the ground under each panel point; dials `TrestleTuning` (`config/trestle.tres`, all
  proposed, the sources in the brief). Its links are set as framed; its ties and rails are the
  line's (the track's state and the derail read them as anywhere).
- `src/train/track_line.gd`, `train_route.gd`: a route's `"crossings"` (named, by distance along
  the line) built as a Trestle each, no ballast or fill under them.
- `src/train/train.gd` (`_check_bridge`, `carry` each tick), `train_wreck.gd` (kind `fell`: no
  derail kick; no ploughing in the air or off the deck's sides).
- `src/structures/`: `StructureMember.extra_points` (weights at points along a member; the
  analysis bends it under each), the viaduct's kinds (`pier`, `bent_sill`, `cap`, `girt`, `brace`,
  `stringer`, `guard`), `StructuralAnalysis.begin_update`'s `stop` (`Structure.closure_stop`),
  `Structure.lost_below`.

## The lab

- `routes/gorge.json`: the line (1.3 km east, a 900 m bend over the gorge), its crossing `gorge`
  (560-690 m: 130 m) and the gorge's numbers (26 m deep, a 28 m floor, its walls, its wander, the
  river on its floor).
- `gorge.gd`: the gorge cut to fit the crossing (it moves with the route): the ground's height for
  the line (`TrackLine.ground_y`: the fill and the bents reach down to it), drawn and solid.
- `lab_line.gd`: the line laid out with its gorge, built, a train on it.
- `lab.gd`: the train lab's lab on this line (node `TrainLab`: every `train_*` bridge command works
  on it), its save and load with the viaduct's wreck.
- `collapse.gd`: a run (charges on a bent's posts, the train or not; what fell, the train, every
  drawn frame and the slow frames' biggest systems); `collapse_runs.py` runs them each in a fresh
  headless game and writes the frame table.

## Running it

```sh
# The table: every collapse in a fresh headless game (~2 min a run)
python3 experiments/trestle_lab/collapse_runs.py --out=build/trestle/runs
python3 experiments/trestle_lab/collapse_runs.py --table=build/trestle/runs

# In the game
python3 tools/bridge.py start --headless --fps=60
python3 tools/bridge.py "trestle_lab" "trestle_cost 10" "trestle_cost 10 train=30"
python3 tools/bridge.py "trestle_matrix out=$PWD/build/trestle/matrix.json"
python3 tools/bridge.py "trestle_collapse how=stick posts=all sticks=4 bents=2 train=cross when=under lead=40 kmh=40"
python3 tools/bridge.py "train_save /tmp/s.json" "train_load /tmp/s.json"
```

Bridge commands (`bridge.gd`): `trestle_lab`, `trestle`, `trestle_cost [S] [train=KMH] [bare]`,
`trestle_matrix`, `trestle_collapse k=v...` (collapse.gd's header has every key), `trestle_cam
floor|rim|deck|under`, `trestle_where`. The train lab's commands work on the gorge line once
`trestle_lab` has built it (`train_watch`, `train_cam`, `train_passengers`, `train_save`...).

## Traps

- The sight world (`Sight`) takes new bodies in at the first look after they're added: the
  viaduct's 7,700 members were ~300 ms on the engineer's first look after a charge. `lab_line.gd`
  looks once at the build; anything that builds a viaduct in the world must too.
- A run compares frames: never run two games (or the tests) at once while one is measured.
- A run's own steps (waits, when the charge goes off) are on the game's clock, its frames on the
  wall's: under the movie writer a frame takes seconds, and on the wall's clock the films ran 2.6 s.
- The runs place the train and hold its speed with the lab's `hold` driver: nobody's watching the
  line (it's the trap), so the engineer doesn't brake for the gap.

## Results

`results/` (one folder a round): `2026-11-04_r1/` (the 66 m, 300 m viaduct) and
`2026-11-04_r2_kwai/` (Sean's River Kwai size, 130 m and ~27 m over a river: today's route). Each
has `summary.md`, the frame table `runs/table.md`, the cut matrix, the idle cost, the sheet and
the films.
