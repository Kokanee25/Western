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
- **Eased edges** (#873): every library board's arrises and ends rounded in `scan_wood.gdshader`'s normal
  (`edge_round` by age and wood class, `MaterialLibrary.EDGE_ROUND`; shaped boards, role + 10, keep their own
  normals). `Railing`'s rail is the `handrail` profile, kept under a library finish (`PropKit.lib_profile_mesh`,
  meta `draw`). Not eased yet: Main Street's older buildings (texel_grid) and kit props (desk, newel posts).
- **Wear by use** (#901, PR #963; RECIPE.md "Wear by use"): scan_wood's use pass from a spec's `materials.wear` and
  members' `use_role` or a kit look's `/<role>` (the bar's top `bar`, plinth `kick`). Dents (`dings`) built, set 0
  (Sean). Not done: chairs (test_perf's 1800 meshes), the brass rail. Quick look: `tools/wood_probe.gd`.
- **Saloon B's gallery view over budget on main:** render CPU 5.9 ms at Sean's (lavapipe) since step 2's look (was 3.8-4.0); find what step 2 added.
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
  (`experiments/building_lab/store/` README: bodies 38,185 of 65,536; render CPU 1.5-2.4 ms (cellar 5.4, over); the rear's gabled wing is Sean's call). **Lit** (#1053): a `Storefront` (show windows, recessed entry; PARTS.md), RoomLight's cap 12 m², RealLook `exposure_indoor` 1.7, a pale beaded ceiling; back wall card 0.110 -> 0.193. **Hollis's** (#1074): pale posts and beams, A. P. HOLLIS gilded on the show windows (`Storefront.gilt`), kit goods in the windows (real stock #1076); the dark brackets are Sean's call;
  saloon B is Fable's (#848: step 1 done, below).
- **The church** (#1203, `church/` README r7): open truss nave. Open: #1217 (ceiling), #1202 q2 (pews). Render: swap + lavapipe.
- **The hotel** (#1220, PR #1224; `hotel/` README, `make_spec.py`): main block built and tested in the lab (12.5k members). Not on its lot till #1227 (its bodies slowed every valley frame). Next #1226 (the grand stair, Sean's pick of `stair_options.png`; kitchen wing; P7-P9 judged); plaster #1225.
- **Harlan's homestead** (#1126, #1160, `homestead/` README): look pass 1 merged: R3 `hewn_pine_log`, R4 `fieldstone_rubble` (unapproved: no yardstick for the materials judge), pines and grass by ValleyScatter's `place` rule, the spring on posts. Left: golden light, thinner pines, chimney courses, yard props.
- **The undertaker's** (#1174, `undertaker/` README): built, on its lot, its cellar dug (`CellarDig`) and walked. Props in (U1, #1181). **Grim** (#1187): old blood by its `past` (`PastStains`: Blood splats, FloorMarks stains), a smoky lamp, CellarHaze; embalming good indie. Damp waits on Sean (#1197); the black trim wants `painted_black_trim`.
- **Stone and lime, not approved** (#928, Sean's pick of method): S1 `rubble_stone`, PL1 `plaster_whitewash`, PL2
  `rubble_whitewash` (`src/render/rubble_stone.gdshader`, `src/art/stone_finish.gd`; LAYOUT "Stone and lime")
  failed two judge rounds: a procedural height field through `real_bump` draws an outline round every stone.
  Drawn only once `materials.stone.want` is approved; never `"trial": true` committed. Its dials reusable (#928 (a)).
  The rooms wait on the prop lab's furniture.
- **The valley's ground and scatter** (#891, #962; LAYOUT "src/world/town_layout.gd"): scanned ground by a map baked
  from valley.json (re-bake `tools/textures/valley_ground_map.gd` when it changes); ruts with parallax depth, berms and
  the sun's shadow in them; a tufted grassland; dry bunch grass (two scans' `dry_diff`) to 105 m, sage lit through,
  stones and clods in the streets, clumped pines (five shapes, open crowns), cottonwoods, snags. Cheap judge
  (`2026-11-15_valley_land2_r2_cheap`): roads good indie, streets cheap (stone wall, greybox, empty). Left: bonsai-pad clumps, even shrubs, pale far ground, a zip on low-sun ruts.
- **Saloon B, the corner saloon** (#772; #848, #884, the stage #902): `experiments/building_lab/saloon_b/` README,
  `tests/test_building_saloon_b.gd`. 7,775 members; 31,688 valley bodies, **1,080 left** of Jolt's 32,768 (the prop
  lab's sets, ~550, fit once; the jail and store need the guard raised or members put to rest). Look judged good indie
  (bar room) / cheap indie (corner). **The stage**: 30 in, of members, clear of the sawn panel; the wing; room_6 the
  dressing room (mirror, pegs, trunk, screen are the prop lab's to place); `DrawCurtain` and `PaintedDrop` (src/art,
  PARTS); the Baron's drop `drop_baron`. Band use points in the README for gameplay. Judged once (`2026-11-14_saloon_b_stage_r1`):
  cheap indie (empty hall, bare proscenium box, tin-bucket footlights, even pleats). Render CPU 3.48 shut / 3.71 open.
  Open with Sean: the roof. Step 3 (#886) merged: THE NEW OCCIDENTAL on a walnut board, four walk lamps; reads by day, weakly at dusk, not at night. Wants: a dressed-timber entry, a matt floor. Not done: the cellar in the valley (#695), No Law's set.
  Traps (saloon B): RECIPE "A two-storey building under trusses"; `reduce.py` rewrites the vram signs' `.import` files short (restore from git).
- **Floors and furniture, still open:** FL1's path a milky haze, FN1 laminate-looking (no pores, ray fleck): #964 (slice, week 3).
- Paint round 2 (#804: an opaque film inside, failing in strips outside, P3 new): parked until after the slice unless Sean says otherwise.
- Lighting (#711): the sun's saw-tooth shadows, rim light, shadows under feet, the shade fill; F2's varnish waits on it. Week 2.
- **The doctor's walls, windows and light** (#826, #824, #829): rules in `experiments/building_lab/RECIPE.md` ("Walls and windows", "Light"); contact shadows wait on #711.
- Room light (#608): on under the real look; its painted-look switch still waiting on Sean.
- Waiting on Sean: #615 (yardstick), #641 follow-ups.

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
  `mesa-vulkan-drivers`, or Vulkan silently falls back to OpenGL.
- Moving the clock re-blends the look (a bridge `set` before `time` is lost); wait ~5 s after a clock jump
  before a screenshot. Try dials with `screenshots.gd --variants=` (one load).
- `pgrep -f`/`pkill -f` match their own command; `pkill -x godot` stops every render.
- A per-board hashed value must be a flat varying (the weave). Check a scan's grain with the test, not by eye.
- A data texture with alpha needs `process/fix_alpha_border=false`. After a local import the Studio men's
  `.import` stubs fill in: keep them out of commits but filled locally, or the men draw white.
- The valley's views: `tools/textures/valley_ground_shots.sh OUT` (~10 min, one game). A drawn perf_bench
  run's first load compiles every shader under lavapipe (the scatter's "4 s" load is that; headless 0.2 s).
- Poly Haven's scanned trees are millions of triangles (the fetch's `max_tris` skips them); its plants' glTF
  diffuse is a JPEG without alpha (the fetch bakes their `Alpha` map in). Never LOD-cut card foliage.
