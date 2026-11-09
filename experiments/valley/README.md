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
- **G3** (#716, the rail corridor; train step 6 "into the world", #542):
  - **The line:** `ValleyRailway` lays `config/valley.json`'s `railway.route` as it stands (the train's
    own TrainRoute/TrackLine/TrackChunk), the rail top the route's: every mark where the tables put
    it (x, z to the metre, rail Y to 5 cm), the ground under the line's middle the bake's formation
    (rail less 1 m) within **4 mm** at 870 points (the trestle's span and past the west portal left
    out: the bake leaves them natural). The fill reaches the bake (`Ground.height_at`) exactly; in a
    cut (past the portal) there is no fill. 4.6 km of track: 47 chunks of ties and rails at rest.
  - **The great trestle** at the `great_trestle` crossing, each bent footed on the bake's canyon to
    the centimetre: 1,542 members, 26 bents, the tallest 26.6 m. The trestle lab's frame table on
    it: `experiments/trestle_lab/results/2026-11-08_valley/` (24 runs; the worst frame at Sean's 104
    ms once, the slow spell passing in 15 of 24; the train over with three bents blown in 5 of 6).
  - **Bridge B** (`RoadBridge`): the East Road over the overpass cutting (the bake's, 6.9 m deep),
    its deck 5.45 m over the rail (4.95 m clear: the engine's stack 3.9), 44 m from rim to rim on six
    bents parallel to the track (the road crosses it 37° off square), the posts 4 m from the rails.
  - **The west portal** (`TunnelPortal`) on its mark, a dark mouth behind it (the height field can't
    hold a hole: the train runs into the dark and the hill).
  - **The daily train** (`config/valley_timetable.json`): leaves east_start at 08:00 by the game's
    clock, the depot 12:27-13:31, the Ore Works 16:48-19:28 (five minutes' loading), into the tunnel by
    ~23:00 (the run is in real seconds: 1,680 s, about 15 game hours of the 45-minute day). On the
    1D line every stop on its mark within 0.5 m and on time; up the 2.5 % into the tunnel he runs at
    his least speed and arrives early (the leg's padding unused). At load it's where the clock has
    it, standing or running mid-leg; each day it starts again as the clock passes 08:00.
  - **Pictures** (real look, lavapipe, 12:30): `results/g3_trestle_overlook_1230.jpg` (the train on
    the trestle from vp_trestle_overlook, 267 m: the whole bridge, small, the fog's grey past it),
    `results/g3_trestle_floor_1230.jpg` (from the canyon's floor), `results/g3_depot_1230.jpg` (the
    train at the depot from Main Street's east end). `g3_pictures.txt`.
  - **Films** (`films/`, from the canyon's floor 35 m downstream; the rim and the overlook show it
    too small): `results/g3_trestle_crossing.mp4` (40 km/h across, nothing fails),
    `results/g3_trestle_over.mp4` (three bents blown as the engine comes on: it goes over). The
    crossing film carries a "didn't quit cleanly" line from a game killed before it (not the game's).
    A film's long command needs `bridge.py run ... --timeout=5400` under lavapipe.
  - **The frame** (`tools/valley/valley_bench.gd`, the train running its timetable at the line's
    far end from each spot; `--no-railway` the before):
    - headless, a tick (`train`, `train_view`, `train_sound`): **0.15-0.18 ms here, ~0.1 at Sean's**
      with the train far (`Train.far`: was 0.45-0.6 here before it); the engineer's body ~0.02;
      the track chunks at rest 0.009 (was 0.09: a chunk at rest skips its tick). The frame against
      the before: +0.2-0.3 ms here for the line alone (untimed: ~11,500 resting members' bodies),
      the VM's own noise run to run 0.3 ms.
    - drawn (lavapipe, real look), render CPU at Sean's, before -> with the railway: crossroads 0.42
      -> 0.53 (draws 100 -> 199: the line 75 m north and its chunks' batches), corners 0.40-0.44 ->
      0.43-0.50, the overlook 0.46 -> 0.47. Budget 4 ms.
    - load: the scene 2.7 -> 3.9 s headless (3.1 -> 6.7 s drawn); the line's build ~1 s, the
      timetable's times ~4-7 s more on a worker after it (the train stands at east_start till then).
    - nodes 2,154 -> 13,656 (the track's members at rest, a body each).
  - Bridge (`bridge.gd`): `valley_train [run [S] | at MARK [KMH] | sync]`, `valley_view VP|MARK [LOOK]`;
    the trestle lab's commands take the valley's line in the valley world (`trestle_cam overlook`).
