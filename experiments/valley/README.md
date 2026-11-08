# The valley's migration (docs/briefs/valley-plan.md §12)

Results of the G steps that build the new valley beside the old town.

- **G1** (#702): `results/g1_crossroads_1812.jpg`, the empty valley from the crossroads at 18:12,
  looking down Main Street (west): the sun sets straight ahead over the flat placeholder ground.
  `python3 tools/bridge.py start --game-args=--world=valley`, then `time 18.2`, `wait 6`,
  `screenshot PATH` (lavapipe, 960x540).
- **G2** (#709, the valley's ground baked from valley.json; Sean's pick #706: our own chunks):
  - **The bake:** `python3 tools/valley/valley_plan.py --bake` -> `config/valley_ground/`
    (2241 x 1857 at 2 m, -30.0..174.1 m, a 3.2 mm step, 5.8 MB gzipped). Against the plan's own
    10 m map at all 167,028 shared points: 1.6 mm worst (the step). Crossroads exactly 0.
  - **The ground:** `Ground.height_at` against a ray down onto the collision at 2,000 random points
    over the envelope: within 1 cm (`test_valley_ground`); on the bake's points exactly. Digging,
    craters, saving: `test_valley_ground` (a stick on the bench's slope, tiles across a chunk's edge,
    a box into a hole, a save and load, holes 25 m down in the canyon and 79 m up at the mine).
  - **Render CPU** (`tools/valley/valley_bench.gd`, lavapipe, 960x540, real look; x0.65 for Sean's):

    | Where | render CPU here | at Sean's | draws | primitives |
    |---|---|---|---|---|
    | crossroads | 0.68 ms | 0.44 | 100 | 344k |
    | corner NW | 0.54 | 0.35 | 96 | 274k |
    | corner NE | 0.58 | 0.38 | 100 | 299k |
    | corner SW | 0.60 | 0.39 | 51 | 342k |
    | corner SE | 0.60 | 0.39 | 53 | 349k |
    | trestle overlook | 0.58 | 0.38 | 48 | 345k |
    | (the town's street, same tool) | 1.81 | 1.18 | 957 | 2,294k |

    Budget: render CPU <= 4 ms at Sean's. Load: the bake 0.3 s, the valley scene 2.8 s here.
  - **Streaming** (`valley_bench.gd --ride`, headless): 13.4 km at 15 m/s round the valley, the
    ground's own frame (Prof `valley_ground`) 0.07 ms mean, 0.35 p99, 6.0 worst (a far block built),
    913 blocks built and freed on the way.
  - **The soak** (`tools/soak.gd -- --world=valley --minutes=240`): passed; median frame 0.5-0.7 ms,
    resident 448 -> 483 MB. The stress run (`--every=300`: a stick and a hole every 5 min, 180 min)
    fails "nodes still climbing" (3,948 -> 37,144): each dug 4 m tile is ~100 nodes (its columns),
    and dug ground is kept by design; its p99 climbs with the nodes because the soak's own check
    walks every node once a second.
  - **Pictures:** `results/g2_crossroads_1800.jpg` (Main Street west at 18:00: the town's plane, the
    sun down the street; the scene's fog, the town's 0.0035, hides the foothills 2 km off: a look
    call for art) and `results/g2_trestle_overlook_1800.jpg` (from vp_trestle_overlook north up the
    canyon to where the trestle will stand). Bridge: `start --game-args=--world=valley`,
    `time 18.0`, `goto X Y Z YAW`, `look 1183 7 -80`, `wait 8`, `screenshot`.
