# Harlan's homestead (#1126): a log cabin, a barn and corral, the spring

Art lane, branch `claude/art-harlan-homestead`. Sean's decisions are on #1126 (2026-11-21). The building
lab's steps by `../RECIPE.md`, in one session: the target sheet, the specs, the frame and its checks, the
look, the judges.

| File | What |
| --- | --- |
| `sheet/` | step 1, the target sheet: `request.json`, `panels/`, `sheet.jpg`, `spent.json` ($1.12, eight views) |
| `gen_spec.py` | writes `config/buildings/harlan_cabin.json`, `harlan_barn.json` and the site `harlan_homestead.json` |
| `render_valley.gd` | step 5: the sheet's views in the valley (`--views=yard,cabin_front,cabin_back,barn,spring,inside`) |

## What it is

- **The cabin** (`harlan_cabin.json`): one room 14 x 16 ft inside 6 1/2 in hewn logs (4.61 x 5.22 m), nine
  courses of 9 in logs on 2 in chinking, the corners notched (the logs' ends alternate past each corner), on
  hewn sills on a fieldstone footing; the floor's joists between the sills on a middle girder; a loft on hewn
  4 x 9 in joists over the room; a 10/12 roof of common rafters, skip sheathing and split shakes; board gables;
  the stone chimney up the outside of the south gable. The door gable (the spec's `back`) faces north to the
  yard and the lane, a small two-over-two window either side of the door and one in the spec's `east` wall over
  the table (the cabin is turned 180 on its pad, so that wall faces west; the woodpile is on the other side). The
  porch across the door gable on three hewn posts, three steps down to the yard. Inside: the plank bed (the
  save's bed: use point `bed`, `bedside` the clear spot beside it), the army trunk at its foot, the cookstove
  against the chimney gable, the table and one chair under the east window with a lamp, shelves by the door.
  The washstand, basin and pitcher on the porch under his shaving mirror (`hung`).
- **The barn** (`harlan_barn.json`): 16 x 20 ft of studs and vertical boards, a dirt floor, a hayloft over all
  on 2x10s (its ladder up the west wall's inside, a hay hole over the stall), the big door to the yard.
- **The site** (`harlan_homestead.json`, `Homestead`): on valley.json's `harlan_homestead` pad (30 x 24 m), the
  lane in at its north edge. The corral of peeled poles east of the barn, its gate to the yard; the woodpile
  against the cabin's east wall, the chopping block with the axe in it; the trough in the yard; the stall and
  the repair stock (new boards on bearers, three bundles of shakes) in the barn; the spring box on the slope
  70 m north-east (valley.json's `harlan_spring`) and its bored-log pipe down the ground to the trough, the
  last length on a post over it.

## The five repair jobs (real pieces; `repair_jobs`, each member's meta `repair`)

| Id | Where | What it is in the game |
| --- | --- | --- |
| `roof_patch` | cabin, west slope over the bed | shakes.missing: no shakes there, the skip sheathing shows (new pale shakes round it where he's started) |
| `porch_board` | cabin porch, `side_porch/board_9` | sprung 7 cm at its west end (a crowd breaks it: the test lets a repair's piece fail) |
| `rotten_step` | cabin, `stair/porch/tread/00` | snapped in two, the halves sagging, both marked `rotten` |
| `barn_door` | barn, `front/door_*` | off its top hinge, its free end dropped to the ground |
| `corral_rail` | corral, `rail/1_2_1` | snapped near one post: a stub on it, the long piece hanging from the other post to the ground |

## The checks (`tests/test_building_homestead.gd`, 5 tests)

The cabin and the barn each: destructible (nothing but members, kit props and fittings), stand (dead load,
a crowd but on a repair's piece), built right (a log wall's openings bucked: `Checks.built_right` reads
`<wall>/opening<j>/buck/`), people fit (doors, use points; the barn's dirt floor counted), every room used, the
game's own settle finds nothing to fall. The cabin's walls are logs (36+ logs, chinking, a new one, the
corners alternating, four openings bucked); its repairs are real pieces; the whole site stands on its pad
(the yard's things and the corral's broken rail rest on something, the pipe's lengths, the bed's use point).

## Settled without asking (Sean can change any)

1. **The door in the gable**, its porch across it (the sheet painted it under the eave in two views): the
   builder's ridge runs front to back, and the gable door reads as a cabin's from the lane.
2. **Butt-and-pass corners** for the notches: the courses level all round (a log's end lands on the crossing
   log, not on air), the ends alternating as a notched corner's do.
3. **The spring stays where valley.json put it** (70 m up the slope), so the pipe is long.
4. **Nothing interactive** (sleeping, washing, the trunk, the repairs): gameplay's.

## Sean's calls and the judge (2026-11-21/22)

- **The door on the long side** (Sean): the porch along it (`side_porch`), the cabin turned so it faces the yard.
- **Silver logs and pale chinking, a fieldstone chimney** (Sean: fix those two first): R1 "few" for the logs, the
  chinking in whitewash set 1/2 in back, the chimney laid in courses of stones (`fieldstone`).
- **Option A** (Sean): merge as it stands; the rest after. Renders: `results/2026-11-21_pairs_r*.jpg`.
- **Cheap judge, one round** (`docs/screenshots/judge/2026-11-22_homestead_r1_cheap/`): all six cheap indie. Its
  reasons: the bare land round it (no trees, a flat horizon band), the chimney's game stone blue and checkered,
  the barn door a flat slab, the spring's box grey with mirror-flat water, inside the log seams cold blue (before
  the chinking change) and the trunk toy-like. Not done: stone and warm hewn-log entries in the library, trees.
- Renders: a valley run is killed past two or three views (memory); render two views a run.
