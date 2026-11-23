# The general store's stock and fittings (#1139)

Hollis's store (`config/buildings/store.json`, written by `experiments/building_lab/store/gen_spec.py`), dressed as a
real 1882 Colorado general store, in batches as the doctor's (D1 to D3) and saloon B's (S1 to S3). Props are made by
`tools/props/store_g1.py` (and `store_g2.py`, `store_g3.py` when they come), placed by the spec's `dressing`
(`PropDressing`, #844), batch `G1` plus the show windows' `windows` (which G1 took over from #1076).

## What the store held, and where (period sources)

Written from: Montgomery Ward's 1872 and 1875 catalogues and Sears-era trade lists (what a country store was
stocked from: bolts of calico, gingham, flannel; boots by the pair; coffee in 60 kg sacks, sugar and flour in barrels,
crackers in barrels, pickles in brine, tinware, lamp oil, nail kegs, ammunition); the 1880s store interiors in the
Library of Congress and Colorado Historical Society collections (long counters down both walls, shelving to the
ceiling with a rolling ladder on a rail, a box stove in the middle of the floor with chairs and a cracker barrel
round it, the scales on the counter, the post office pigeonholes at the back, the till and ledger by the door);
Preservation Brief 11 for the front (already built, #1053). G2 saved four dated interiors (LoC, 1895-1900) in
`refs/store/` and what each would change (its README).

| Where | What | Batch |
| --- | --- | --- |
| East wall (the alley), between its windows (z 2.3, 4.2) | wall shelving to the ceiling (cupboards below, a working shelf, five open boards, cornice, iron ladder rail), three bays, a rolling ladder on the last (not over the cellar's trap: it fell through) | G1 |
| East counter, x 2.0 to 2.6 | long panelled counter in two lengths with the clerk's gap between (the flap), brass yardstick let into the top, drawers on his side; the scales and the candy jars on it | G1 |
| West wall (the hardware store's, blank), between its lamps (z 3.4, 8.0) | wall shelving, four bays (the last is the post office's, G3): dry goods on it, the bolts of cloth | G1 (bolts), G2 (boots, hats, thread, notions) |
| West counter, x 14.3 to 14.9 | dry goods counter with the scales | G1 |
| Back counter (z 8.4 to 9.0), x 11.8 to 14.8 | the till, later the ledger | G1 (till), G3 (ledger, the day-book) |
| The middle, by the stove (x 10.2, z 9.0) | box stove with a pipe to the ceiling, three chairs, the spittoon, cracker barrel and pickle barrel | G1 |
| The back wall either side of the door (x 8.28) | flour and sugar barrels, coffee and flour sacks | G1 |
| The show windows | the east one dry goods and groceries (a cracker barrel, blankets, bolts, scales, sacks), the west one housewares and hardware (lamps, basin and pitcher, saw, cups, a flour barrel) | G1 (what #1076 replaced); G2 completes (tins, boots, tinware, hardware) |
| Behind the counter, on the shelves | tins, jars, lamp chimneys, boxes of ammunition, soap, tobacco | G2 |
| Hardware | nail kegs, tools (axe, shovel), rope, lamp oil cans, a coffee mill, tinware (pail, coffeepot, kettle) | G2 |
| The post office | the pigeonholes (west_shelves_d), the postmaster's desk | G3 |
| The day-book | the ledger, the pen, the till's cash | G3 |

## G1 (this batch): what's made, how, what's judged

Made with the kit's members and the library's woods only: no Blender in this session's sandbox, so nothing baked.
That's the batch's honest limit: the brass and iron are bare `prop:brass` / `prop:iron` looks, the bolts are three
`prop:` cloths, the barrels and sacks the kit's. **Left for G2**: baked metal (the yardstick, the pulls, the ladder
rail, the scales), a Rodin sack (the flour and coffee sacks are the feed sack's shape in other looks), painted
barrel stencils (a barrel's name is not yet on its head: flour, sugar and crackers read as three heaps in three
looks), the tins on the shelves.

| Prop | Kit file | What it is |
| --- | --- | --- |
| Store counter | `store_counter` | `like counter`: 3 m fitted per place, panelled front, brass yardstick, drawers behind |
| Wall shelving | `store_shelving` | `like shelves`: 3.1 m, cupboards and five boards, cornice, ladder rail on two arms |
| Rolling ladder | `rolling_ladder` | two oak rails, nine rungs, iron hooks over the rail |
| Stove | `store_stove` | the saloon's `box_stove` with one more length of pipe, cut to the shop's ceiling |
| Barrels | `cracker_barrel`, `flour_barrel`, `sugar_barrel`, `pickle_barrel` | the kit's barrel, open (no top head), its goods heaped in |
| Sacks | `coffee_sack`, `flour_sack` | `like feed_sack`, burlap and canvas |
| Counter scales | `store_scales` | iron base and pillar, brass beam, tin scoop, brass weights |
| Bolts of cloth | `bolt_calico`, `bolt_felt`, `bolt_plaid` | cloth on a board, standing |

The chairs by the stove are the kit's `chair`, the spittoon the kit's, the till the saloon's (`till_drawer`, S1).

**The placement** (`store_g1.dressing_g1`): the east counter in two lengths (z 2.0 to 5.3 and 6.2 to 8.6) leaves the
clerk 0.9 m for the flap and the aisle behind it 1.5 m wide against the shelving (the cellar's trap, x 0.5 to 1.5,
z 5.95 to 8.7, is in that aisle); the use points moved with it (`gen_spec.py`: `serve_east` behind the first length,
`buy_1` and `buy_2` in front of the counters, `ledger` behind the back counter, `post_office` at the pigeonholes' bay).
`Checks.people_fit` passes (the test above, `tests/test_building_store.gd`).

**Cost** (counted from the dressing, not measured in the valley): 14 kit files; 203 dressed props and 659 member bodies
standing in G1, 49 more in the windows (recounted in G2: G1's own count, 86 and ~530, missed the rows). The lane's rate (the doctor's ~390 resting bodies: ~0.3 ms at Sean's) puts it near 0.4 ms. The barrels
(21 bodies each, 9 of them) and the shelving (18 each, 7 bays) are the largest shares; G2 should keep barrels few.

## G1 judged blind in the room (two rounds, `results/2026-11-22_store_g1/`; `sheet.jpg` is r2: shop from the door, the clerk's side, the stove, the street windows from the back; by day)

Round 1 (`r1/critic.md`): "an empty freshly painted hall with a few props dropped in": empty shelves, a huge bare floor,
teal counters. Fixed for round 2: the counters' body in the library's oak (the pine's paint read teal), stock on the
shelves (bolts, jars, bottles, lamps, cups), two crates and a heap of sacks, a display table of dry goods. (Found on the
way: PropDressing's `on` takes a fitted fixture's *top* (3.1 m for the shelving), so round 1's bolts were hung at the
ceiling: shelf stock is placed at its board's own y.)

Round 2 (`r2/critic.md`): counters DIFFERENT ("smooth orange cabinets"), shelving and its stock DIFFERENT ("almost
empty", only a few dark specks), bolts DIFFERENT (not seen as bolts), window goods DIFFERENT; ladder, stove and chairs,
barrels, sacks and scales CLOSE. Not fixed (two rounds spent; Sean decides): **the shelf stock does not read** from the
critic's cameras (the shelves face the walls the cameras look along, small goods in 1000 px; the jars are the
doctor's clear glass); the room feels vast because the shop is 16.6 x 10.7 m and G1 has no hanging goods, no
ceiling lamps, and G2's tins and hardware aren't in. The window lettering reads backwards from inside (true of any
painted glass). Next, G2: tins and boxed goods in quantity on the shelves, boots and hats, hardware (nail kegs,
tools, rope, tinware), a glass display case and the coffee mill on the counters, hanging lamps and goods, a pot-bellied
stove if Sean wants one, baked metal, and the three or four dated interiors in `refs/store/`. **The counters' warmth is
the oak's**; if Sean wants them painted, that's the library's painted finish (#721), not G1's.

**CI found (#1158):** a counter running to z 8.9 and a ladder over the cellar's trap were moved by the valley's settle (`test_save_game`): the second counter now ends at z 8.6 (the girder at 8.8) and the east ladder stands in the last bay, z 9.65.

## G2 (#1172): the shelves filled, boots and hats, hardware, the mill and showcase, baked metal

**The shelf stock's fault was placement, not only size.** `experiments/prop_lab/store/probe_shelves.gd` (headless: builds
the store, runs physics 3 s, reports every good's foot against the board it should stand on) found all 172 of G1's shelf
goods 4 to 9 cm over their boards or dropped onto them, and the bolts through the board over them: `bay()` fitted the
shelving to [0.36, 3.1] where its members' own box is [0.46, 3.2] (the cornice, the cupboards' top and the ladder rail
stand proud), so PropKit.fit squashed it and every board came down from `SHELF_YS`. Fixed in `store_g1.bay()` (fitted to
its own box across and up, stretched only along its wall); the bolts cut to 0.30 (0.325 clear between boards); the till
moved off the back counter's edge (it dropped 0.19 m). After: every shelf good's gap 0.000, nothing moved or loose.

**Made** (`tools/props/store_g2.py` numbers and kit files; `tools/blender/props/store_g2.py` models, ~1 min of bakes):

| Prop | What it is |
| --- | --- |
| `tin_row`, `tin_row_flat`, `box_row`, `box_row_flat`, `case_row` (+ `_half`) | a 0.6 m row of goods as two members (blocks of 0.3), drawn from `glb:store_goods`: tall cans (tomatoes, peaches, corn, condensed milk...) two high and two deep, flat cans (oysters, salmon, sardines) three high, cartons (soap, starch, baking powder, tea), flat boxes in stacks (cartridges, matches, collars, thread), stencilled packing cases with a carton on each for the shelving's top. Every label printed on one 2048 sheet (Pillow), a column one line of goods as a clerk stocks a facing, a few gone from the top tier |
| `boot_row` | two pairs (blacked and russet) on the working shelf, 33 cm |
| `hat_stack`, `hat_single` | three wide-brimmed felts nested (black, brown, buff); one buff hat |
| `rope_coil`, `nail_keg`, `tool_keg`, `oil_can` | manila rope; a 100 lb keg of cut nails, open; an axe, shovel and hoe in a keg; a 5 gal kerosene can |
| `tin_pail`, `coffeepot`, `tea_kettle` | tinware |
| `showcase` | oak base and posts, `glass:clear` on four sides, spools, pocket knives on a card, pipes, combs in it |
| `coffee_mill` | the two-wheel counter mill, red enamel, a brass hopper, 50 cm spoked wheels |
| `store_scales` (G1's, rebuilt) | an even balance: japanned base and pillar, a brass beam and pointer, two pans hung on three wires each |
| `pbr:store_brass`, `pbr:store_iron` | G1's yardstick, pulls, ladder rail, arms and hooks: a fitted box can't take a mesh (it doesn't stretch with the fit), so each metal is baked onto one plate filling its atlas and tiles as a look |

New finishes in `metal.py`: `boot_leather`, `russet_leather`, `felt_buff`, `felt_brown`, `hemp`, `mill_red`, `kraft`.

**Placed** (`dressing_g2()`, batch G2; `STOCK` names what's on each board of each bay): the grocery's east wall all rows of
cans, cartons and boxes on every board, the cases on top; the dry goods' west wall boots on the working shelf, G1's bolts
on boards 1 and 2, boxes, hats on the top board; the post office's bay (G3's) only cases on top. The coffee mill at the
grocery counter's back end, the showcase, a hat stack and the rope on the dry goods counter, tinware either side of the
till, the hardware corner on the floor at the dry goods counter's back end (two nail kegs, the tools, a pail), two oil
cans by the back wall, three hanging lamps down the room (lit by the clock, no shadows). Counter goods take the counter's
top as y (`on` only names an entry of its own batch). G1 gave up its shelf rows of jars, bottles and cups to G2 (it keeps
the patent medicines and lamps on the grocery's top boards and the post office's jars).

**Cost**: G1 + G2 + windows 242 props and 794 member bodies standing (was 225 and 708: +12%), at the lane's rate ~0.6 ms
at Sean's for the whole store (barrels and shelving still the largest shares). Not measured in the valley.

**Rodin**: the sacks (G1's "lumpy urns") and boots quoted on #1175 (~$2.02 each; the Studio's ledger $64.89 of $66 with
the doctor's bag counted, so neither fits without Sean raising the cap). Nothing paid sent.
