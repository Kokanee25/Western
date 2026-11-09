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
- **G4** (#720, the greybox markers):
  - **The roads graded** into the bake (`valley_plan.py` `Terrain._roads`): on G3's bake they ran over
    the natural banks (36 % up the mine road's arroyo bank, 27 % at the timber road's ford, 21 % on
    Harlan's ford path, 14 % at Bridge A's banks, 12 % on the North-South Street at the creek). Now
    each road's graded profile is cut and filled across its width: fords' banks cut to 8 % (12 % a
    track), the mine road's crib fill, the bridges' approaches at their decks 3 m past their spans
    and eased into the road. Measured in the game over the bake and the decks (`road_grades`):
    every road within the plan's limits but Church Lane (11.8 % for ~30 m by the stock pens' pad)
    and the Baron's drive (12.4 %, its pitch). The tables moved a little (Church Lane 10.0 -> 9.3 %,
    Harlan's ford path 14.2 -> 9.9 %); 22 checks pass; the 10 m map and the 2 m bake agree to
    1.6 mm; the formation under the line within 2 mm.
  - **Two changes to valley.json**: `block`s for the depot, freight warehouse, water tank, church
    and the Baron's house (the church's its own 8 x 12 m in the churchyard: Church Lane runs
    through the yard to the cemetery), Bridge A's `cribs`; and the East Road straight over Bridge
    B (its 14 deg bend at the bridge split into two 7 deg bends 20 m either side: the deck hung off
    the road at one end).
  - **Built** (`ValleyMarks`, `ValleyMarkers`, `ValleyRoads`; LAYOUT "src/world/town_layout.gd"):
    the marks on the ground (a byte a bake point, ~0.3 s to paint), 23 blocks, 31 posts and names,
    73 places for `goto`; Bridge A 17.5 m on its log crib (spans 8.5 and 9.5 m), the town bridge
    13 m, Bridge B now 40.5 m (G3's 44; its approaches graded); every deck meets its approaches
    within a step (0.3 m) across its width. Two viewpoints the plan put just inside their lots
    (`vp_main_east`, `vp_saloon_balcony` at z -12; the fronts at -10.05) stand in the street in
    front for now.
  - **On foot from the crossroads** (`valley_walk`, headless, the road network's shortest way,
    the game's walk 2.8 m/s): every place arrives, within 7 s of the plan's time (the walk cuts the
    corners; `g4_walks.txt`). The horse isn't ridden yet (#341): no times on it.

    | To | By road (m) | Walked (m) | In the game | The plan's walk | Climb / descent (m) |
    |---|---|---|---|---|---|
    | Depot | 123 | 111 | 0:40 | 0:43 | +3 / -0 |
    | Cemetery | 243 | 240 | 1:25 | 1:26 | +12 / -2 |
    | The Baron's town house | 244 | 235 | 1:23 | 1:27 | +5 / -1 |
    | The opening's encounter site | 553 | 551 | 3:17 | 3:17 | +1 / -6 |
    | Harlan's homestead | 713 | 710 | 4:13 | 4:14 | +8 / -6 |
    | Bridge A | 1016 | 1015 | 6:02 | 6:02 | +1 / -11 |
    | Trestle overlook | 1314 | 1310 | 7:48 | 7:49 | +10 / -11 |
    | Ore Works | 1587 | 1583 | 9:25 | 9:26 | +27 / -2 |
    | Timber camp | 1701 | 1697 | 10:06 | 10:07 | +70 / -9 |
    | Southern Ute community | 1899 | 1897 | 11:18 | 11:18 | +46 / -5 |
    | The Baron's ranch | 2000 | 1998 | 11:53 | 11:54 | +25 / -5 |
    | Outlaw hideout | 2118 | 2115 | 12:37 | 12:36 | +91 / -5 |
    | Bridge B | 2132 | 2130 | 12:41 | 12:41 | +23 / -11 |
    | The widow's homestead | 2621 | 2617 | 15:35 | 15:36 | +23 / -33 |
    | The mine | 2756 | 2735 | 16:17 | 16:24 | +85 / -6 |
    | East exit | 3159 | 3148 | 18:44 | 18:48 | +23 / -41 |

  - **The frame** (`valley_bench.gd`, lavapipe, real look; `-- --no-markers` the before), render CPU
    at Sean's: crossroads 0.53 -> 0.57 ms (draws 199 -> 209), corners 0.46-0.47 -> 0.48-0.50,
    overlook 0.55 -> 0.53 (noise); nodes +180; load the same (~8 s drawn). Budget 4 ms.
  - **Pictures** (real look, lavapipe, 10:30; `g4_pictures.txt`): `results/g4_top_town.jpg` (the town
    from 160 m up: the streets, lots' blocks, the depot's pad outlined), `results/g4_top_bridge_a.jpg`
    (the East Road over Bridge A and the creek, taken before the roads were darkened),
    `results/g4_main_street.jpg` (west down Main Street between the lots' blocks, the `town` post at
    the crossroads), `results/g4_bridge_a.jpg` (Bridge A on its crib from the west bank). The marks
    read from above; at eye level the real look washes the greybox ground to one pale tone (for art).
- **G5** (#724, the town greybox, first half; the buildings moving over is its second, after #695):
  - **Built** (`ValleyTown`; LAYOUT "src/world/town_layout.gd"): the game's `Boardwalk` along all 17
    building fronts (1,766 members, ~0.45 s to build), each its own level from the ground at its street
    edge, joined over the two shoulder-to-shoulder gaps, end steps to every lane, alley and street, a
    flight at each door; 15 passages to Back Street and the rear lane (5 lanes, the 1.2 m store's,
    doctor's and undertaker's alleys, 2 yards, the vacant lot, the house lots, the 2 gaps between the
    jail, bank and land office); the undertaker's alley filled by junk in 0.5 m tiers (jumped over, not
    walked); the town's ways from valley.json: 362 places and 337 links in the valley's `places`.
  - **valley.json**: `vp_main_east` and `vp_saloon_balcony` onto their lots' walks (z -8.9; were -12,
    inside the lots); `alley_n8`'s `junk`. Re-baked (the heights the same), the plain run 22/22.
  - **The gate** (`tests/test_valley_town.gd`): `walk` (running) from the crossroads to every door,
    and to every passage's mouth and on through it to the back, all arrive; the three alleys measure
    1.20 m between the blocks, a man's sweep clears them, two abreast don't; every town link walkable
    (a man's sweep and the steps under it). The old town's suite unchanged (1,104 pass).
  - **Waypoints** (shared): `route` searches once back from the goal and asks the places in order
    (the same ways): from a back yard 1,082 -> 10 ms, to the junk alley's back 235 -> 5 ms; a step
    probe that fell between two planks (18 mm) is asked again a foot's width round.
  - **On foot from the crossroads** (`valley_walk`, `g4_walks.txt`, headless): the same as G4's table
    to the second at all 16 places (the mine and the east exit re-run alone: a background command
    stops at 2 hours).
  - **The frame** (`valley_bench.gd`, lavapipe, real look; `-- --no-town` the before), render CPU at
    Sean's: crossroads 0.57 -> 0.88 ms (draws 209 -> 474: the walks), corners 0.47-0.53 -> 0.55-0.59,
    overlook 0.85 -> 0.70 (noise); load 7.6 -> 9.1 s drawn here. Budget 4 ms.
  - **Pictures** (real look, lavapipe, 10:30; `g5_pictures.txt`): `results/g5_top_north_east.jpg`,
    `results/g5_top_north_west.jpg` (the north side from 45 m up: the walks, lanes and alleys to Back
    Street), `results/g5_doctors_alley.jpg` (the doctor's alley from Main Street, open to the back),
    `results/g5_hotel_walk.jpg` (west along the hotel's walk), `results/g5_junk.jpg` (the undertaker's
    alley and its junk).
