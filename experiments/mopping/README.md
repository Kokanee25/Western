# The mopping lab

The barkeep mops his floor (`docs/briefs/mopping.md`): what's on the boards (`FloorMarks`), his mop
and bucket (`MopProp`, `MopBucket`; kit kinds `mop` and `bucket`) and his chore of mopping
(`MopFloor`, in `CivilianBrain.chores` beside his rag's `WipeBar`). This bench puts the barkeep
(`barkeep_s2_talking`, his brain and chores as in the game) behind a bar in a room of boards with
his mop and bucket in the corner, a street and a trough outside the door, runs one scenario
seeded, and measures every tick.

```sh
python3 experiments/mopping/run.py --out=build/mopping/base                 # every scenario, headless, table.md
python3 experiments/mopping/run.py --out=DIR --render --jobs=3              # frames for the film (xvfb + lavapipe)
python3 experiments/mopping/run.py --film=DIR                               # DIR/mopping.mp4 from the frames
python3 experiments/mopping/run.py --perf=3 --out=DIR                       # the cost, with and without, one core
godot --headless --fixed-fps 60 -s res://experiments/mopping/bench.gd -- --scenario=NAME --out=DIR
xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://experiments/mopping/bench.gd -- \
    --scenario=NAME --out=DIR --shots=10,40,80 [--cam=room|close]            # a few stills (seconds)
```

- **Scenarios** (`bench.gd` `SCENARIOS`): `spill` (a bottle of whiskey and a jug of beer on the
  floor), `blood` (90 ml of blood after a fight), `muddy` (three men in off a wet street to the bar
  and out), `trouble` (a shot as he mops), `change_water` (420 g of mud: the bucket goes black, he
  empties it outside and fills it at the trough), `perf_on`/`perf_off` (`muddy` with and without
  the mopping, for the cost).
- **Each summary** (`DIR/<scenario>/summary.json`): the chore's steps with their times and why it
  stopped, goes/stretches/waters changed, the floor's mess over time (dirt g, spilt ml, blood ml,
  stains), the mop and bucket at the end, faults counted a tick (a strand point below the boards,
  faster than 20 m/s), the cost a tick (People, the mop's script, the floor's marks, the whole tick)
  over the run and while he's mopping (`ms_working`).
- **The dev bridge** (`bridge.gd`): `mop` (the chore, mop, bucket and the floor round his post in
  the running game) and `mop_do spill|mud|look`.

## Results

See `results/` (the film, `table.md`, `perf.md`).
