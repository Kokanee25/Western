# The barkeep's rag's lab

The barkeep's bar cloth (`docs/briefs/barkeep-rag.md`): the cloth (`ClothProp`, kit kind `cloth`,
`assets/props/kit/bar_cloth.json`) and his chore of wiping the bar with it (`WipeBar`, in
`CivilianBrain.chore`). This bench puts the barkeep (`barkeep_s2_talking`, his brain and chore as
in the game, his FaceLife watching his work) behind the kit's bar with his cloth over his shoulder and two
tin cups, runs one scenario seeded, and measures every tick.

```sh
python3 experiments/barkeep_rag/run.py --out=build/barkeep_rag/base            # every scenario, headless, table.md
python3 experiments/barkeep_rag/run.py --out=DIR --render --jobs=3             # frames for the film (xvfb + lavapipe, ~25 min)
python3 experiments/barkeep_rag/run.py --film=DIR                              # DIR/barkeep_rag.mp4 from the frames
python3 experiments/barkeep_rag/run.py --perf=3 --out=DIR                      # the cost, with and without the rag, one core
godot --headless --fixed-fps 60 -s res://experiments/barkeep_rag/bench.gd -- --scenario=NAME --out=DIR [--debug]
xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://experiments/barkeep_rag/bench.gd -- \
    --scenario=NAME --out=DIR --shots=6.4,10,22 [--cam=side|front|close]       # a few stills (seconds)
godot --headless --fixed-fps 60 -s res://experiments/barkeep_rag/softbody_probe.gd -- [--n=8] [--res=6]   # SoftBody3D under Jolt
```

- **Scenarios** (`bench.gd` `SCENARIOS`): `cycle` (a whole go: off his shoulder, four stretches, a
  cup, back on), `customer` (a man walks up to the bar mid-wipe and leaves), `trouble` (a shot hits
  the bar by his hand), `dropped` (the cloth knocked out of his hand onto the floor), `blast` (a
  30 g charge across the room blows it off his shoulder), `burn` (burning oil spilt on the bar
  beside it), `blood` (a 400 J ball in his right flank as he wipes: the hand with the cloth goes to
  the wound), `perf_on`/`perf_off` (the cycle with and without the cloth, for the cost). An event
  with `"when": "wipe"` waits until he's wiping.
- **Each summary** (`DIR/<scenario>/summary.json`): the chore's steps with their times and why it
  stopped, goes/stretches/cups, the cloth at the end (held, burnt, blood), faults counted a tick
  (a point below the floor, inside the bar top while free, faster than 20 m/s, not finite), the
  cost a tick (his brain with the chore, his body, the cloth's script, the whole tick) over the
  run and while he's working (`ms_working`).
- **The dev bridge** (`bridge.gd`): `rag` (the barkeep's chore and cloth in the running game) and
  `rag_do knock|drop|ignite|wipe`.

## What the probe found (SoftBody3D under Jolt, Godot 4.7.2)

- It runs: a 48-point rag is ~0.07 ms a tick on one core here (~0.04 ms at Sean's), eight of them
  ~0.24 ms. Nothing blows up or goes missing. On four cores Jolt's job system adds a fixed ~0.3 ms
  of waiting, and now and then prints "exceeded the maximum number of jobs" (it carries on).
- **Pinned points aren't held:** a pinned point creeps down at ~0.16 m/s, and SoftBody3D's
  attachment never moves it with its node. `ClothProp` moves its pinned points itself each tick
  (`PhysicsServer3D.soft_body_move_point`), which holds them to ~3 mm.
- Setting a soft body's transform after it's made moves it by that transform; `ClothProp.place`
  lays every point instead.
- Default stiffness stretches the rag ~10% hanging from a corner; `linear_stiffness` 1.0 with
  `simulation_precision` 10 doesn't.

## Results

- `results/2026-10-22/`: `barkeep_rag.mp4` (the film, 3 min: cycle, customer, trouble, dropped,
  blast, burn at twice speed, blood), `table.md` (every scenario), `perf.md` (the cost), the
  cloth's texture at the end of `cycle`, `blood` and `burn`. Same seed, same result: 7 of 7.
  Faults: nothing below the floor, inside the bar or lost in any run; one or two ticks a run with
  points faster than 20 m/s (a point snagged on the bar's edge springing off as his hand pulls the
  cloth away; a blast). The cost while he works, at Sean's: People +0.12 ms (his chore 0.044, his
  arms' IK 0.069, the cloth's script 0.007), the soft body ~+0.08 ms of Physics.
