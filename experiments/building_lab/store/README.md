# The general store (#858): the third practice building

Art lane, branch `claude/art-building-store-vejdym`. The building lab's steps by `../RECIPE.md`,
each shown to Sean before the next. Steps 4-6 (the look, the judges, the recipe) are the next session's.

| File | What |
| --- | --- |
| `sheet/` | step 1, the target sheet: `request.json`, `panels/`, `sheet.jpg`, `spent.json` |
| `gen_spec.py` | step 2: writes `config/buildings/store.json` (kept while its numbers move) |
| `results/plan.png` | the ground plan drawn from the spec (`tools/buildings/plan_sheet.py`) |

## Step 1: the sheet (approved by Sean, 2026-11-16)

Sean's calls: a **two-storey false front**, **painted pale buff clapboard** with green trim, a
late-afternoon light (the front faces south, so the front and side views were lit from the south-west),
**$2.50 cap**. Ten views, **$1.41**, none failed. The sheet's faults are settled in the spec, not repainted:
a sign painted "GENERAL STORE & GROCER" (the game's lettering is its own), double doors drawn where the spec
has one wide leaf, doors and stairs in the plan that differ a little from the words.

## Step 2: the spec (`config/buildings/store.json`)

55 x 56 ft (16.76 x 17.07 m), flush to the store alley (the wall 3 cm in, so the alley stays 1.2 m: test_valley_town),
14 cm off the hardware store. Frame from saloon B's (two storeys, queen-post trusses on a 9.46 degree roof behind the
false front at 10.4 m), the doctor's rules for light, floor, walls and windows. Floor at the dock's top (1.10 m),
upper floor 5.00, plate 7.90.

- **Ground:** the shop (16.6 x 10.7 m) with the cellar trap and its stair by the east counter; the storeroom behind
  (6.1 m) with the stair up the alley wall and the back door (six steps to the yard).
- **Upper:** the stock loft over the shop (the stair lands in its north-east corner), the hall and three family
  rooms over the storeroom.
- **Cellar:** under the front half, 16.76 x 9.5 m, rubble-stone walls, 24 posts under five girders.
- **Upper floor's support:** two beam lines (x 5.59 and 11.17) on posts, a pier from the cellar floor where the post
  stands over the cellar (the builder's new `posts.free` rule: `spec_building.gd`). A beam end needs a post under it: a
  bearing partition is not a support in the analysis (the stubs read "joint" over the limit).
- **Valley:** `valley.json` general_store: `spec`, `pad` (y 0.52, dug level, 3 m blend), the cellar's `spec` and
  rect, the walk's `door_x` -45.78; re-baked.
- **Lamps:** a kit lamp in every room but the cellar. **Light:** the doctor's fill, `window_day` 9, `day_fill` 0.18.

### Settled without asking (Sean can change any)

1. **The pad.** The ground rises 0.63 m front to back (0.1 m east to west) under a 17 m deep building with a
   cellar: dug level at the walk's street edge as the doctor's and saloon B's (the jail follows the fall).
2. **One wide door** (4 ft, glazed, a transom) for the sheet's double doors: the builder has no pair of leaves.
3. **No door on the alley** (1.2 m wide: a stoop would close it); the sheet's small east door is dropped. The west
   wall (against the hardware store) is blank.
4. **Waiting on other work:** the cellar's doors under the dock (the bulkhead, #695) and the cellar's lantern (no
   board wall to hang it on); the shop's counters, shelves and stove (the prop lab's dressing).

## Step 3: the tests, the X-ray, the budget (Sean's yes on the spec, #1022)

`tests/test_building_store.gd` (9 tests, ~55 s): built and destructible (5,341 members), stands (dead load and a
crowd), built right, people fit and every room used, **the rooms' own light** (a lamp in every room but the cellar,
each on its own level; RoomLight gets every outer opening; the fill reaches the outer walls), **the walls and windows
as judged** (boards at the paint's judged width, skirting on every boarded ground wall, casings in the trim's finish,
a pane a light, the front's east show window's pane shot alone while its sash stands), **a post knocked out**
(`Checks.knockouts` on the twelve beam posts: each leaves its beam over its limit, none falls outright).

- **Fault the light test caught:** the two family rooms' lamps (`room_1`, `room_2`) were hung at `at` 14.5 on a
  partition that runs front to back, but a partition's `at` counts from the wall's own start (z 12.15), so both hung
  in the yard (z 26.65). Now `at` 2.4 (`gen_spec.py`, spec re-written).
- **The X-ray** (`results/xray.jpg`, `tools/buildings/xray.py`, from `build/store_members.json`): the front and back
  with and without siding, both sides with the alley's and hardware store's openings, a section across the shop and
  cellar, the ground floor's framing (girders on piers, the cellar's posts), the loft's and the roof's. The tool took
  the doctor's wall names (yard, lane) and a "surgery | hall | dispensary" caption: it now reads the spec's, and a
  two-storey frame gets a roof-framing view.
- **Valley bodies: 38,185 of Jolt's 65,536** (`perf_bench --world=valley --bodies`, 15 townsfolk): the store is 5,340,
  the saloon 7,944 + 1,290, the doctor 3,894, the jail 3,172, the railway 10,211.
- **Draws:** the store alone is 235 (120 batches, 115 own meshes, 9 lights). **Render CPU in the valley was not
  measured:** this workspace has no Vulkan (lavapipe's ICD missing, the engine fell back to OpenGL on llvmpipe, 116 s
  for three frames), so a rendered bench says nothing. The CI nightly or Sean's F3 give it; saloon B's 1.8 ms at
  ~2,000 draws is the guide (the store is a tenth of that).

