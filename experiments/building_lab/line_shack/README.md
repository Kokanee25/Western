# The hideout's line shack (Kett's cabin, No Justice; #1091)

The building lab's treatment of No Justice's stand-in shack (was a FalseFrontBuilding gable box built by
`no_justice_hideout.gd` `_build_shack`). Steps 1-2 #1091; the build (step 3) #1250: No Justice now builds it.

## Sean's answers (2026-11-25, in the session)

Rough vertical boards (not the homestead's logs, so #1091's "use the homestead's log walls" is
overruled by Sean's pick); split shakes; one small window; a board floor; a pole lean-to beside it.

## Step 1: the sheet

`sheet/request.json`, nine views (approach, plan, front, side, back, inside from the door, inside to
the barred door, cutaway, dusk), $1.41 cap, painted by `building_sheet.yml`. `sheet/sheet.jpg`.

## Step 2: the spec and the plan

`gen_spec.py` writes `config/buildings/line_shack.json` (re-run it; never edit the JSON). `plan.py`
draws `plan.png` from the spec: furniture, the kept-clear areas and Joe's walk.

- **Kept from the stand-in:** 4.2 x 5.0 m, the door in the north gable's middle (x 2.1, 0.95 x 1.95),
  floor 0.32 m, the half-height doorstep (#966).
- **The back storeroom** (Sean, 2026-11-25, on the sheet: "somewhere for Kett to hide at the back"; his
  pick of four): a closed lean-to 1.5 m deep across the south gable, no window, a low unbarred plank
  door at the west lane's end (x 1.15) swinging in against its west side. Kett hides behind its leaf in
  the bare west half (`corner` [0.75, 4.3] -> [0.75, 5.95]); the stores stand in its east half. The shack
  is 6.5 m deep in all (`lot.footprint`): `in_shack` must count the storeroom.
- **Joe's walk** (#1091's must: he never stalls on the sill): the door, then a 0.9 m lane down the west
  side between the stacked bunks and the table's west bench, through the storeroom's door to Kett. The door is a
  batten door that breaks along its planks (flat 25 mm boards) into the yellow area; the floor there
  otherwise bare. The build's test: kick the door in, Joe walks door -> Kett in the storeroom, 10 runs (the storeroom's door
  opened or kicked too).
- **Proposed for gameplay** (their file, no_justice_cabin.json, changed in the build's merge and said
  so): `corner` [0.75, 4.3] -> [0.75, 5.95], `joe_in` [3.3, 1.5] -> [1.35, 1.4], `joe_back` [2.9, 0.8] -> [1.6, 0.8] (the old points are behind
  the table and the single bunk).
- **The mission's code** (`_build_shack`) loads the spec instead of the box; `in_shack`, `_shack_door`
  and `shack.width/depth/floor_top` keep working if the SpecBuilding exposes them (or the hideout reads
  them from the spec's lot). `shut_door` and the members `front/door_bar`, `front/door_shut` (the
  cabin's `_door_member`) must exist on the new building.

## New for the builder (step 3)

- `outside.battens`: battens over the vertical boards' joints (`_vertical_siding` has none).
- `outbuildings` `lean_to` (the storeroom: closed, as the farmhouse's, but with the shack's vertical
  siding and no window); the east one with `open`, `posts`, `floor: "dirt"` (today's lean_to is a closed room).
- `chimneys` `kind: "stovepipe"` (a tin pipe through the roof, cap, guys); `doorstep`; a door's `bar`
  and `breaks: "planks"`; `walls[].patches` (tin over holes); a window's `shutter` and `cracked`.
- `kept_clear` and `walk`: data for the build's test (nothing in them; the walk clear 0.7 m wide).

## New kit for the prop lab

bunk_stacked, bunk, plank_bench, saddle, saddle_rack, bedroll, skillet, tin_plate, tin_cans,
gun_belt, bridle (the rest exist: box_stove, coffeepot, table, whiskey_bottle, card_deck, crate...).

## Step 3: the build (#1250)

Built from the spec by `SpecBuilding`; `tests/test_building_line_shack.gd` (stands, built right, fits,
its parts, the door's planks), `tests/test_no_justice_shack_walk.gd` (#1091's must), the X-ray
`xray/xray.png` (`tools/buildings/xray.py`). **861 members.**

- **New in the builder** (`spec_building.gd`, "the line shack's parts"): `outside.battens`; an `open`
  lean_to (juniper posts on flat stones, a pole beam, pole rafters, boards; no walls or floor; on any
  wall, falling along its `out`); the closed storeroom is the farmhouse's lean_to with its own three
  walls (`store_west/back/east`); `chimneys` `kind: "stovepipe"` (joints standing on the floor inside the
  stove, through the roof, a cap; no floor hole); `doorstep`; a door's `bar` (two iron brackets; the
  building's `door_rect`) and `breaks: "planks"` (a threshold under it; `shut_door` makes the shut leaf
  and bar; `break_member` drops the leaf as separate planks); `latch` doors (`shut_leaf`, `open_leaf`,
  `leaf_shut`, `latched_door`). A building with no loft gets its rafters at their spacing (`_rafter_lines`).
- **Changed from the plan** (each to pass the checks): the walls to 2.6 m (2.3 left no room for the
  storeroom's ledger over its door); both doors 1.98 m (a man through them: the back one isn't low);
  the front door hinged on the east jamb (its open leaf was in the lane); 2x6 sleepers, 2x6 rafters and a
  deeper ridge (the 2x4s failed the crowd and the joints); no girt (the `ribbon` crossed both doors);
  Kett's corner [0.65, 6.1] (clear of the storeroom door's open leaf).
- **The door's fall** (10 kicks, the lab): four planks and the bar's halves, in the lane under 0.45 m;
  without the threshold the planks' feet jammed in the gap under the door and they stood at 45 degrees.
- **Not built yet:** `walls[].patches`, the window's `shutter` and `cracked`, the stovepipe's guys.
- **Stand-ins** (gen_spec.py `STAND_IN`, `PLACE`; each keeps `wants`): plank_bed for the bunks,
  wall_bench (scaled) for the plank benches, folded_blanket for the bedrolls, trestles_short for the
  saddle rack; skillet, tin_plate, tin_cans, gun_belt, saddle and bridle wait (`dressing.waiting`).
