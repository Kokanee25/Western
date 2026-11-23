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


## Steps 4-6: the look, the judges, the recipe (#1035)

`render_valley.gd` draws the store on its lot in the valley's real look from the sheet's views (`results/2026-11-17_look/`:
each view as a jpg, `pairs.jpg` beside the targets, `cpu.txt`); `--variants=NAME:day_fill=a,window_day=b;...` tries light dials in one load.
Rendered here under lavapipe (the cloud workspace had no Vulkan ICD until `apt-get update && apt-get install mesa-vulkan-drivers`:
that closes step 3's gap), ~15 min a view, one run at a time.

- **The look is the library's, by name** (nothing new): `painted_buff_drop` few for the siding, `painted_green_trim` for trim, sash
  and sign, `painted_pale_tg` inside, `floor_fir_worn` on its traffic ways; every entry's `approved` list passes "few".
- **The one change: the light.** The spec's step-2 numbers (`day_fill` 0.18, `window_day` 9) left a 16.8 m shop near black by day.
  Tried 0.35/16 and 0.55/26 (shop and loft, one load): the second is lit to the back wall without flattening it. Now in `gen_spec.py`
  and `store.json`. Tests 8/8 (the README's "9" counted one too many).
- **Render CPU in the valley, measured at last** (x0.65 for Sean's core): 1.5-2.4 ms a view (front 2.4, shop 1.8, loft 2.1, night 1.5)
  of 935-2,652 draws, under the 4 ms budget. **The cellar is 5.4 ms (7,788 draws): over budget.** A camera below the dug lot's
  ground sees the whole valley through the pad's hole; a player on the cellar stair may too. Not fixed: gameplay's to cull.
- **Round 1** (`docs/screenshots/judge/2026-11-17_store_r1/`, `_cheap/`): the blind critic 0 SAME / 2 CLOSE (front, loft) / 6 DIFFERENT;
  its five: the bare interiors (dressing, the prop lab's), the cellar near black with no stair or door light (#695's doors and lantern),
  the rear a flat box beside the sheet's gabled wing with a hoist (spec), the front dull olive in cool light with the sign at the
  parapet where the sheet puts a lower sign band, the dock with no cellar flap (#695). The cheap judge: five cheap indie, the loft
  good indie; its reasons: empty rooms, the grey placeholder neighbours, tiled post grain and floor, the night room's black crush.
- **No round 2:** every fault above is another lane's (props, #695, the neighbours' lots) or a form call for Sean (the sign's place,
  the rear's wing); a second round of renders (~2.5 h) would only find them again.

## The sign band (Sean's answer on #1045, 2026-11-17)

Sean: move the sign to the band over the porch. `front.sign_from` 4.4 / new `front.sign_to` 5.45 (the board's bottom and top; default
the parapet's, so no other building changes): the board sits between the porch roof (~4.5 m at the wall) and the upper windows' sills
(5.6 m), the letters 0.5 m tall. `results/2026-11-17_look/front_band.jpg`. `spec_building.gd` is the structure code (one line, art's
lab); FORMAT.md says so. Tests 8/8. Not re-judged (a sign's place isn't a look the judges grade). The rear wing (#1045's second call) is still open.

## Lighting the shop (#1053, from the #1052 review)

Grey cards (`light_review.gd`, `build/light/*/cards.txt`), noon: shop middle / back / back wall; counter front / middle.

| | shop mid | shop back | back wall | counter front | counter mid |
|---|---|---|---|---|---|
| before (sash windows, cap 2.5, x1.05) | 0.298 | 0.103 | 0.110 | 0.475 | 0.222 |
| storefront + cap 12 + pale ceiling | 0.541 | 0.190 | 0.150 | – | – |
| + indoor exposure 1.7 | 0.661 | 0.256 | 0.193 | 0.699 | 0.590 |

4 pm: shop 0.676 / 0.262 / 0.190, counter 0.712 / 0.606.

- **Storefront** (`src/structures/storefront.gd`, a part in PARTS.md; NPS Preservation Brief 11): two show windows 3.44 x 2.9 m on
  a 0.5 m panelled bulkhead, 2 lights over 4 transom lights, glass to 3.4 m; a recessed entry 5.18 m wide and 1.2 m deep, the
  door (1.22 x 2.4, glazed leaf) set back, angled glass sides on bulkheads, a transom over the door, a beaded recess ceiling and a
  threshold. Spec: opening `type` `recess` (its `depth`, `door`, `bulkhead`, `transom`, `header`) and a window's `show` block. A
  per-opening `header` depth (0.25 here) carries the wide openings.
- **RoomLight's cap** `opening_max_area` 2.5 -> 12 m² (energy still by sqrt(area)), so a show window lights like the glass it is.
- **Indoor exposure**: RealLook's `exposure_indoor` 1.7, eased over `indoor_ease` 1 s, blended by daylight, only under a roof and
  inside a building's interior probe; the street stays x1.05.
- **Ceiling**: beaded boards in `painted_pale_tg` across the shop (spec `ceilings`: `rooms`, `around_beams`, `width`), stopping at
  the beams. Dark posts and beams kept; the pale-beam variant is in the before/after sheet for Sean.
- `day_fill` / `window_day` left at 0.55 / 26: the shop doesn't read flat with them (the beams and posts still shade).
- Lamps by day: not needed, the back reads lit.
- **The other buildings re-checked** (`light_recheck.gd`, old = cap 2.5 and x1.05 / new; whole frame mean, middle): doctor's office
  0.184/0.222 -> 0.269/0.314, jail office 0.079/0.086 -> 0.144/0.148, saloon B to the door 0.145/0.109 -> 0.250/0.193 (its bar view
  under the new light didn't finish in an hour under lavapipe, twice). All read brighter, none blown; their looks have no goldens.
- **Goldens**: `inside_store_afternoon_real` re-approved (the old town store by day, brighter by the indoor exposure, diff looked
  at). The street's real views keep x1.05; their small fails (mean ~3.4) are the revolver hand's pose in the corner, from main, not
  this change, left for the nightly run.
- **Pale posts and beams**: the variant (`timber` in `painted_pale_tg`) was killed three times before a frame; not shown. Sean's call.
- **Cheap judge** (`results/2026-11-17_light_cheap/cheap.md`, one round): the entry good indie, the rest cheap indie; tell 1 (flat
  light) passed in all five. What it marks is the store's emptiness (props, #695), the grey neighbours and the blank outside the
  windows, the stripe's moire at 800 px, and the grey cards it took for placeholders: none of it this step's light.

## Hollis's store (#1074, Sean's answers on #1067)

`results/2026-11-18_hollis_before_after.jpg` (noon: front12, entry12, counter12; the before is #1053's).

- **Pale posts and beams:** `finishes.timber` wants `painted_pale_tg` (few), as the ceiling and the walls inside do; the
  floor joists take their own `joists` finish and stay dark (hidden over the shop, bare over the storeroom). The carved
  brackets (`bracket/` `-`) keep their own dark wood: Sean's call if they go pale too.
- **Why the pale render died before:** not the texture factory (`few` is in the entry's `approved`, and it's the walls'
  material already). A front view peaks at 13.1 GB RSS (`build/light/pale/mem.log`) on a 15 GB box: anything else
  running tips it over. With 6 GB of swap (`fallocate`, `mkswap`, `swapon`) it finished in 23 min, swap never used; three
  views in one run 53 min, peak 12.6 GB.
- **Gold leaf:** each show window's `gilt` {id `hollis`, y 1.45, width 2.65}: "A. P. HOLLIS" over "DRY GOODS · GROCERIES ·
  HARDWARE", `Storefront.gilt` (PARTS.md "A storefront") laying `assets/textures/gilt_hollis.png` (`tools/textures/gold_leaf.py`:
  set in DejaVu Serif Bold, burnished leaf, black outline and drop shade; no paid call) on the inside of each pane it
  crosses. Metal 0.3: at 0.85 it showed only reflections and went grey under the porch roof. Reads backwards from inside.
- **Window goods** (`dressing.windows`): a low platform (the kit's table fitted 0.6 m, the glass's foot) behind each window;
  east: blankets, a feed sack, the scales, three jars, a barrel at its end; west: the strongbox, two lamps, basin and
  pitcher, a chamber pot, a handsaw, tin cups. Stand-ins for a store's own stock (#1076, the prop lab's, after the slice).
  The mop bucket isn't a member prop (the destructible test refuses it).
- **Story:** Hollis named in `docs/story/VOICES.md` and `SETUPS.md` (S23's day-book).
