# Art lane: current state

Branch `claude/art-…`. Files: see CLAUDE.md "How we work". Replace your lines here at the end of a
session (no history: that goes in `docs/status/` and the PR). Keep under 10 KB (a test fails the build over it). History: `docs/status/`.

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
- **Our own sky** (#918, under the real look; LAYOUT "src/render" "The real sky"): `RealSky` swaps a
  physically based sky in (scattering, sun and moon light, moon phase by date with day 1 full, stars
  and the Milky Way), lights the world from it (sun colour and energy, ambient, fog), draws one sheet of
  drifting cloud (`coverage`; `RealSky.set_coverage` for weather) and in the valley the far land (the
  bake past 800 m and the ranges to 45 km, over the sky only). Dials `config/looks/real_sky.json`.
  Weather (#947) is after the slice.
- **Shared board meshes** (#1246, PR #1254): a SpecBuilding's plain library boards take one mesh per (length, width,
  thickness, role) (`PropKit.shared_board`); seed, warp, nails and ground ride on the node (`board_values`) and the batch
  writes them into the vertex channels; a board drawn alone gets its own back (`own_board`). Valley load -2.2 s, -480 MB.
  Tests reading CUSTOM1/2 off one board read `board_values`. Next cut: the batches' per-vertex copies (and shadow mesh).
- **Eased edges** (#873): library boards' arrises rounded in `scan_wood.gdshader` (`MaterialLibrary.EDGE_ROUND`); `Railing`'s
  rail the `handrail` profile. Not eased: Main Street's older buildings, kit props.
- **Wear by use** (#901, PR #963; RECIPE.md "Wear by use"): scan_wood's use pass from a spec's `materials.wear` and
  members' `use_role` or a kit look's `/<role>` (the bar's top `bar`, plinth `kick`). Dents (`dings`) built, set 0
  (Sean). Not done: chairs (test_perf's 1800 meshes), the brass rail. Quick look: `tools/wood_probe.gd`.
- **Saloon B's gallery view over budget:** render CPU 5.9 ms at Sean's (lavapipe) since step 2's look (was 3.8-4.0).
- **Goldens stale on main:** the nightly fails 69 of 84 views (porch_dusk, street_night, the outlaws...), not
  from one change; re-approving them needs each view's diff looked at, not a blanket approve.
- **Judges decide** (Sean, #721): materials judge (`tools/material_judge.py`,
  `docs/concept/judge/MATERIAL.md`): a swatch passes at "game" or better with no tile tell. Cheap judge
  (`critic.py cheap`, `--refs=<Studio>/references`) for whole views. Judges vary about a grade run to run.

## Open
- **The builder is in the game** (R1, #975): `src/structures/spec_building.gd` (+ stair, marks, stone), specs in
  `config/buildings/`; the lab (`experiments/building_lab/`) loads them from there. New buildings: add a spec there.
- **Buildings in mission order** (#765): doctor's office done, in his paints (`experiments/building_lab/doctor/`,
  `RECIPE.md`); **the jail done** (#811, steps 1-6; `experiments/building_lab/jail/` README, on its valley lot).
  **The jail's stone and form** (#860, PR #927): the stepped parapet with corner piers, the cell wing a metre lower,
  the 7 ft yard wall, proud sills, lintels and coping, the walk stopping at the building. **The general store (#858): steps 1-3 done**
  (`experiments/building_lab/store/` README: bodies 38,185 of 65,536; render CPU 1.5-2.4 ms (cellar 5.4, over); its cellar dug in the valley (#1266); the rear's gabled wing is Sean's call). **Lit** (#1053): a `Storefront` (show windows, recessed entry; PARTS.md), RoomLight's cap 12 m², RealLook `exposure_indoor` 1.7, a pale beaded ceiling; back wall card 0.110 -> 0.193. **Hollis's** (#1074): pale posts and beams, A. P. HOLLIS gilded on the show windows (`Storefront.gilt`), kit goods in the windows (real stock #1076); the dark brackets are Sean's call;
  saloon B is Fable's (#848: step 1 done, below).
- **The church** (#1203, `church/` README r7): open truss nave. Open: #1217 (ceiling), #1202 q2 (pews). Render: swap + lavapipe.
- **The hotel** (#1220, #1226, #1247; `hotel/` README, `make_spec.py`): layout A and the kitchen wing built in the lab (15.7k members, test cap 16k); P7-P9 approved (judged without the yardstick); two judge rounds used (`results/2026-11-25_r2`: stair hall good indie, the rest cheap indie). Not on its lot till #1227. Next: P7's far hue, the dressing (prop lab), plaster #1225.
- **The Railroad Saloon, THE SILVER SPIKE** (#1285, #1286; `railroad_saloon/` README, `make_spec.py`, `crowd_bench.gd`): built, on its lot (a town extra), tested; sawn, the middle bay falls on the bar. Crowd bench: no deaths, ~20 of 40 go down; the men are over the people budget (~2.5x) and the fall's worst frame is over 100 ms (gameplay's for Payday). Not dressed: #1222's casks and bottles.
- **Harlan's homestead** (#1126, #1160, `homestead/` README): look pass 1 merged: R3 `hewn_pine_log`, R4 `fieldstone_rubble` (unapproved: no yardstick for the materials judge), pines and grass by ValleyScatter's `place` rule, the spring on posts. Left: golden light, thinner pines, chimney courses, yard props.
- **The line shack** (#1250, PR #1267; `line_shack/` README): in No Justice from its spec (861 members); Joe reaches Kett 10/10. Not built: patches, shutter, guys. Kit: #1263.
- **The undertaker's** (#1174, `undertaker/` README): built, on its lot, its cellar dug (`CellarDig`) and walked. Props in (U1, #1181). **Grim** (#1187): old blood by its `past` (`PastStains`: Blood splats, FloorMarks stains), a smoky lamp, CellarHaze; embalming good indie. Damp waits on Sean (#1197); the black trim wants `painted_black_trim`.
- **Stone and lime, not approved** (#928): S1 `rubble_stone`, PL1, PL2 (`rubble_stone.gdshader`, `stone_finish.gd`; LAYOUT
  "Stone and lime") failed two judge rounds (an outline round every stone from `real_bump`). Drawn only once approved; never
  `"trial": true` committed.
- **The valley's ground and scatter** (#891, #962; LAYOUT "src/world/town_layout.gd"): scanned ground from a map baked from
  valley.json (re-bake `tools/textures/valley_ground_map.gd` when it changes), ruts, bunch grass, sage, pines, cottonwoods. Cheap
  judge `2026-11-15_valley_land2_r2_cheap`: roads good indie, streets cheap. Left: bonsai-pad clumps, pale far ground. **Trap
  (#1266):** a scan's `.import` must keep `mipmaps/generate=true` or the ground swims (the other scans, plaster, rock, wood, have none).
- **Saloon B, the corner saloon** (#772, #848, #884, the stage #902, step 3 #886): `experiments/building_lab/saloon_b/` README,
  `tests/test_building_saloon_b.gd`. 7,775 members; valley bodies near Jolt's 32,768 (the jail and store need the guard raised or
  members put to rest). Judged good indie (bar room) / cheap indie (corner, the stage: empty hall, bare proscenium). Open with Sean:
  the roof. Wants: a dressed-timber entry, a matt floor; the cellar in the valley (#695: its trap and stair go into undug ground; its
  dig moves the card set's ground). Doors swing clear (`Checks.door_swings`, `test_building_doors.gd`, #1266). Traps: RECIPE "A
  two-storey building under trusses"; `reduce.py` rewrites the vram signs' `.import` files short (restore from git).
- **Floors and furniture, still open:** FL1's path a milky haze, FN1 laminate-looking (no pores, ray fleck): #964 (slice, week 3).
- **The doctor's walls, windows and light** (#826, #824, #829): RECIPE.md "Walls and windows", "Light".

## Traps
- The sky: Godot keeps a 24-bit depth where the card has it (no tricks behind the far plane); the scene's
  fog reads a fragment's depth; LightFinish's quad (sorting -1000) wipes any transparent sorted before
  it; a sky shader reading POSITION re-lights on every camera move; DayCycle sends `sun_dir`/`moon_dir`/
  `star_strength` to whatever sky is in place. The valley's sun stands in the north at noon (DayCycle
  tilts it to -Z; valley.json's north is -Z): the stars turn round a southern pole to match. Poly
  Haven is blocked here (no photo skies for the judges).
- One lavapipe render at a time (~10-13 GB each; two OOM; the store's views need swap on a 15 GB box). On an 8 GB box: swap (`fallocate -l 6G`, `mkswap`, `swapon`) or the valley is killed; nothing else heavy beside it. A real-look view ~10 min; a full golden render
  ~2.5 h (batches of 24-25 with `--only=`); a material lab shot ~1 min after ~1.5 min of load.
- Start with `--game-args=--real`: switching the real look on at runtime crashes lavapipe. Needs
  `mesa-vulkan-drivers` (or `VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json`), or Vulkan falls back to OpenGL.
  The valley under lavapipe OOMs a 15 GB box alone: draw a building in the street's desert (`line_shack/render_lab.gd`).
- Moving the clock re-blends the look (a bridge `set` before `time` is lost); wait ~5 s after a clock jump
  before a screenshot. Try dials with `screenshots.gd --variants=` (one load).
- `pgrep -f`/`pkill -f` match their own command; `pkill -x godot` stops every render.
- A per-board hashed value must be a flat varying (the weave). Check a scan's grain with the test, not by eye.
- A data texture with alpha needs `process/fix_alpha_border=false`. After a local import the Studio men's
  `.import` stubs fill in: keep them out of commits but filled locally, or the men draw white.
- The valley's views: `tools/textures/valley_ground_shots.sh OUT`. A drawn perf_bench's first load compiles every shader.
- Poly Haven's scanned trees are millions of triangles (`max_tris` skips them); its plants' diffuse has no alpha (the fetch bakes `Alpha` in). Never LOD-cut card foliage.
