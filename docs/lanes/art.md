# Art lane: current state

Branch `claude/art-…`. Files: see CLAUDE.md "How we work". Replace your lines here at the end of a
session (no history: that goes in `docs/status/` and the PR). Keep this file under ~10 KB.
Full history to 2026-11-11: `docs/status/current-state-2026-11-11.md` "Art".

## Where the look stands
- **Realistic, toward Red Dead** (Sean 2026-11-04; DESIGN.md §4, `docs/briefs/red-dead.md`). The real
  look (`RealLook`) is the default (#641); N turns it off; goldens exist in both looks (`<view>_real`).
  Day exposure blended by the sun (`config/looks/real_light.json`). SDFGI off (#643).
- **Material library** (`config/material_library.json`, `SamplePanel`, `scan_wood.gdshader`; LAYOUT
  "src/render"). Passing woods: R1 (all ages), C1, F2. Approved paints: `painted_white_lap`,
  `painted_green_trim`, `painted_buff_drop`, `painted_pale_tg`, `painted_pale_tg_green` (all ages),
  `painted_oxblood_batten` (few, old). Buildings take finishes by name. Floors and furniture (#825):
  `floor_fir_worn` FL1 (all ages; feet's wear from the building's traffic map), `furniture_oak` FN1 (all),
  `furniture_painted_pine` FN2 (new, few); `furniture_walnut` FN3 parked (top clouds, no walnut figure).
- **Judges decide** (Sean, #721): materials judge (`tools/material_judge.py`,
  `docs/concept/judge/MATERIAL.md`): a swatch passes at "game" or better with no tile tell. Cheap judge
  (`critic.py cheap`, `--refs=<Studio>/references`) for whole views. Judges vary about a grade run to run.

## Open
- **Buildings in mission order** (#765): doctor's office done, in his paints (`experiments/building_lab/doctor/`,
  `RECIPE.md`); **the jail done** (#811, steps 1-6; `experiments/building_lab/jail/` README, on its valley lot).
  **Next: the jail's stone as rubble, not boxes (#860, Sean: "too square and perfect")**, then the general store
  (#858); saloon B is Fable's (#848: step 1 done, below).
- **The valley's ground and scatter** (#891; LAYOUT "src/world/town_layout.gd", PARTS "Materials and look"): the
  valley's ground drawn real from six CC0 scans by a ground map baked from valley.json (re-bake
  `tools/textures/valley_ground_map.gd` when it changes); rutted streets; the scatter (grass, stones, sage, rocks,
  boulders, logs, pines, cottonwoods) by rules. Cheap judge: the roads good indie (from cheap), streets and the
  height still cheap (the sky's flat bands, greybox fronts, backlit near-black bushes, cloned trees, one grass).
  Render CPU at Sean's: street 2.37 -> 2.80, road 0.58 -> 0.90. Next: its issue (sky, trees, bushes, grass kinds).
- **The jail's open form** (round 2: critic 4 CLOSE / 4 DIFFERENT; the corridor at night good indie): plaster and
  whitewash inside and rubble outside not in the library (the game's stone stands in; both judges name it first);
  the parapet flat where the sheet's steps up in the middle; the 10 ft yard wall hides the cell wing from the lane.
  Sean's picks (the `waiting on Sean` issue). The rooms wait on the prop lab's furniture.
- **The doctor's room review** (#818, `docs/reviews/2026-11-doctor-room.md`): its rules all approved (#821) and in
  `RECIPE.md` (#824-#826, #829); the jail built on them.
- **Saloon B, the corner saloon** (#772): step 1 merged (#848: spec and frame on the corner lot,
  `experiments/building_lab/saloon_b/` README, `tests/test_building_saloon_b.gd`). **Step 2 (the look) is PR #884,
  held** on three red people tests in its CI (Earl's chair, No Law's murder, the wound smear; the card game is
  played beside the saloon): Sean's pick, merge red or hold, is #923. **Step 3 (#886), on branch
  `claude/art-saloon-b-sign` (built on #884)**: THE SALT CREEK painted ($0.10) on a walnut board cut to it,
  four lamps on the walks (`lamps.kit` `side: "out"`), the corner at dusk judged good indie (was cheap); the
  critic: the lamps' light doesn't reach the walk, the sign grey on grey by day and lost at dusk. It merges
  after #884. The girder test (#922) allows only what the falling floor hits. The valley's collision bodies
  30,993 of Jolt's 32,768 with main today (step 2 measured 27,908): little headroom.
  Traps: a `void` opening must reach the wall's end; rerun `b.settle()` after any frame change; a factory
  entry goes under `materials` in materials.json; a People texture run rewrites every painted sign's
  `.import` bare: restore all but the new one.
- **Floors and furniture, still open** (#825's judge, `docs/screenshots/judge/2026-11-12_floor_furniture_r2`): the
  floor's path reads as a milky haze, not abraded wood; the oak has no pores or ray fleck (no quartersawn scan in
  the library: fetch one by `scans.yml`); walnut parked; painted pine old's cloudy top.
- Paint round 2 (#804: an opaque film inside, failing in strips outside, P3 new): parked until after the slice unless Sean says otherwise.
- Lighting (#711): the sun's saw-tooth shadows, rim light, shadows under feet, the shade fill; F2's varnish waits on it. Week 2.
- **The doctor's walls and windows** (#826): every window a `SashWindow` (src/structures, a part: lined reveal,
  two sashes by the spec's `lights`, a glass member a pane that breaks alone, dusty glass), the inside boards
  drawn at their paint's judged 9 cm (`inside_finish.boards: "judged"`, `strips_mesh`), a skirting, casings
  and sashes in the trim's green (reads near black indoors: the approved chrome green). Rules in
  `experiments/building_lab/RECIPE.md` "Walls and windows". +38 draws (panes); render CPU <= 2.3 ms at Sean's.
  Cheap judge still cheap indie for the walk's floating porch posts, grey neighbours, empty rooms.
- **The doctor lit as a room** (#824) **and by day** (#829): his spec names a lamp a room (`lamps.kit`), `light`
  (`fill` to the outer walls, near neutral; `day_fill` 0.1, DayCycle reads the probe's `day_ambient`;
  `window_day` 7). RoomLight's daylight rooms (`RoomLightTuning` "Daylight"): windows aimed at the floor 0.6
  across, reaching twice the far wall, falling off, shadowed by day; a soft light off each sunlit patch.
  Cheap judge round 2 (`docs/screenshots/judge/2026-11-12_doctor_daylight_r2/`): tell 1 passes on desk and
  window, fails on the dispensary (judged before #826's sashes; with them, `results/2026-11-12_daylight/with_826.jpg`,
  the light holds, not re-judged). Render CPU at Sean's <= 2.83 ms.
  Rule in `experiments/building_lab/RECIPE.md` "Light". Next: contact shadows with #711.
- Room light (#608): on under the real look; its painted-look switch still waiting on Sean.
- Waiting on Sean: #615 (yardstick), #641 follow-ups.

## Traps
- One lavapipe render at a time (~10 GB each; two OOM). A real-look view ~10 min; a full golden render
  ~2.5 h (batches of 24-25 with `--only=`); a material lab shot ~1 min after ~1.5 min of load.
- Start with `--game-args=--real`: switching the real look on at runtime crashes lavapipe. Needs
  `mesa-vulkan-drivers`, or Vulkan silently falls back to OpenGL.
- Moving the clock re-blends the look (a bridge `set` before `time` is lost); wait ~5 s after a clock jump
  before a screenshot. Try dials with `screenshots.gd --variants=` (one load).
- `pgrep -f`/`pkill -f` match their own command; `pkill -x godot` stops every render.
- A per-board hashed value must be a flat varying (the weave). Check a scan's grain with the test, not by eye.
- A data texture with alpha needs `process/fix_alpha_border=false`. After a local import the Studio men's
  `.import` stubs fill in: keep them out of commits but filled locally, or the men draw white.
- Render only what changed; a review round is ~2.5 h here.
- The valley's views: `tools/textures/valley_ground_shots.sh OUT` (~10 min, one game). A drawn perf_bench
  run's first load compiles every shader under lavapipe (the scatter's "4 s" load is that; headless 0.2 s).
- Poly Haven's scanned trees are millions of triangles (the fetch's `max_tris` skips them); its plants' glTF
  diffuse is a JPEG without alpha (the fetch bakes their `Alpha` map in). Never LOD-cut card foliage.
