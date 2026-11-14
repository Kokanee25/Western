# The prop lab's bench

The prop lab (Sean, 2026-10-21; `docs/briefs/prop-lab.md`) makes each prop end to end and promotes
it into the **prop kit** (`assets/props/kit/<id>.json`, built by `KitProp`/`PropKit` in
`src/props/`; `docs/PARTS.md` "Props"). This bench measures a kit prop against the breakage lab's
set and the prop's own cases, the way the breakage lab measures the street: one fresh headless game
per scenario, on a 4 x 4 m floor of boards on joists (a room's), every physics tick measured.

```sh
python3 experiments/prop_lab/run.py --out=build/prop_lab/base            # every scenario, 4 at a time (~10 min)
python3 experiments/prop_lab/run.py --out=DIR --scenario=seated_kick_front_leg,table_burn
python3 experiments/prop_lab/run.py --out=DIR --render --jobs=3 --scenario=...   # frames (xvfb + lavapipe)
python3 experiments/prop_lab/run.py --sheet=DIR --only=seated_kick_front_leg     # frames -> DIR/<name>_sheet.jpg
python3 experiments/prop_lab/run.py --table=DIR                                  # DIR/table.md from the summaries
godot --headless --fixed-fps 60 -s res://experiments/prop_lab/bench.gd -- --scenario=list
xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://experiments/prop_lab/bench.gd -- --look --out=DIR
godot --headless --fixed-fps 60 -s res://experiments/prop_lab/bench.gd -- --perf=kit|lib --out=DIR [--render]
```

- **Scenarios** (`scenarios.json`; edit it to add one): the breakage lab's set (`revolver` and
  `shotgun` from 5 m with the production loads through `Ballistics`; dynamite 1, 3 and 6 m off
  through `Blast.detonate` with a stick's charge; a limp man on his back dropped from 1 m over it),
  `kick` (`KitProp.take_blow`: a leg of ~8 kg at 6 m/s, 48 N·s), `burn` (members lit, FireSystem
  running, 10 minutes), and for chairs `seated`: a Studio man (`bold_cowboy_s0`) posed sitting, his
  weight on the seat (`KitProp.sit`), before the shot or kick. `"prop": ""` is the floor alone, the
  frame-time baseline for the blasts. Every run is seeded: run it twice into two folders and compare
  the summaries' fingerprints.
- **Each summary** (`DIR/<scenario>/summary.json`): what snapped, whether it went over (loose) and
  when, pieces and how far, the hits, what caught and burnt away (and when), the man (down, when,
  on the floor), the lamp (on the table: smashed, spills), physics faults (sunk, below ground,
  flung over 20 m/s, a man's part over 12 m/s), frame times (the event's frames, the settle's, the
  first second's added mean; this workspace's 2.1 GHz core: x0.65 for Sean's), a fingerprint.
- **Full barrels and loose props:** a full barrel's summary has `contents` (left, run out, on the bus,
  leaks and slots, released, litres in the first second); a loose prop put on with `glass` (the
  spittoon, the cups) reports holes, dents, spilt, upright and how far it went; `kick_glass` kicks
  one (`take_blow`).
- **`--look`**: the kit's chair and card table (right) beside PropModels' (left), a Studio man
  between, lamplight and daylight, wide and close: the sheet the kit's look is judged on.
  `--props=barrel,crate,bar_stool` puts those in a row each side instead (wall props hung on a
  boarded wall behind).
- **`--perf`**: the saloon's set (two tables, four chairs at each, as `SaloonBuilding` places
  them) untouched, as kit props or as PropLibrary's props through `StaticBatch`; `--set=stores`
  the town's barrels, crates and bar stools instead (14, 12 with 4 stacked, 7).

## Results

- `results/2026-10-21_baseline/`: the chair and the card table, every scenario (`table.md`), the
  budget (`perf_*.json`). Same seed, same result: 22 of 22.
- `results/2026-10-22_stores/`: the barrel, the crate and the bar stool: 19 scenarios (`table.md`),
  the look sheets (`look_*.png`), the budget for the town's set (`perf_*_stores.json`: +0.05 ms
  physics and +127 draws at Sean's for all 45).
- `results/2026-10-23_contents/`: full barrels (`whiskey_*`, `water_*`, `oil_burn`) and the loose
  props (`spittoon_*`, `cup_*`, `cups_*`): `table.md`, the summaries, the budget (`perf_*.json`:
  the saloon's set with its 2 spittoons and 5 cups +0.018 ms physics at Sean's and 30 fewer draws
  than the drawn props; the town's stores with 8 full barrels +0.054 ms and +127 draws, as when
  they were empty), the look sheet's blind critic (`critic.md`).
- `results/2026-11-01_deer_fidelity/`: the deer head's fidelity (issue #524; the lab in
  `deer_fidelity/`): which step loses Rodin's deer between its render and the saloon's wall (the
  grid shader's min-square coarsening, then no mipmaps; not the triangles or the paint's size),
  the stand and in-game sheets, costs, the kit checks.

## Saloon B, batch S1 (#866)

Made and judged on the lab's stand, **not placed** (the valley is near Jolt's body limit, #865; the
furniture's route into the game is #862). `tools/props/saloon.py` (kit files), `tools/blender/props/
saloon_s1.py` (models), `saloon/s1_sheet.py` (the stand: `prop_stand`, `prop`, `prop_light` on this lab's
bridge; noon and night), references `refs/saloon/`. Results `results/2026-11-13_saloon_s1/`.

**Physics bodies**: each kit member is a body while the prop stands (a StaticBody3D), a glass prop
one (its frozen body). Broken: a kit prop's broken members each a rubble body and, gone over, the
rest one; a glass prop's shards (each a RigidBody3D, frozen once still, at most 160 in the world,
oldest freed) and its whole parts one each. The placing session counts the room's total
(~215 bodies as below; the valley had ~5,100 to spare under Jolt's 32,768 at #865's count).

| Prop | Bodies standing | Broken | Where in saloon B (room, count) |
| --- | --- | --- | --- |
| `hanging_lamp` | 1 | up to 10 shards + the brass | bar room: two rows of three hung from the dance floor's joists (6); dance hall: 2. With an OilLamp at `light_height` |
| `hanging_lamp_shaded` | 1 | up to 10 shards + the brass and shade | gaming room: one over each table (2-3) |
| `shot_glass` / `schooner` / `decanter` | 1 each | 8-12 shards (+ the stopper) | ~40 in all: back bar rows, the bar top, the tables in play (No Law's: a few; Payday: on the bar for the dust). Set fewer as props and more as dress if the count bites |
| `work_board` | 17 | its members | behind the bar under its top, its back on the bar's back boards: 3 sections along the 34 ft run |
| `slat_mat` | 3 | its members | behind the bar along the aisle: 5-6 |
| `box_stove` | 16 | iron doesn't break; its pipe comes down; its coals a small fire | bar room, mid-room, 1: its pipe up to the flue (take off the lengths the ceiling doesn't want) |
| `faro_table` | 16 | its members | bar room 1, gaming room 1 |
| `lookout_stool` | 9 | its members | one at each faro table's dealer's elbow (2) |
| `piano_stool` | 6 | its members | before the upright piano on the back wall, 1 |
| `wheel_of_fortune` | 3 | its members | gaming room's wall, ~1.9 m to its middle, 1 |
| `gold_scales` | 6 | its members | the back bar by the till, 1 |
| `till_drawer` | 2 | its members | the back bar, 1 |
| `card_deck` | 1 | 1 | each table in play (~5) |
| `chip_stacks` | 1 | 1 | each table in play (~5) |
| `bar_arm_rail` | 1 | 1 | on each bar section's top at its front edge (bar space x 0, y 1.095, z 0.455): 4. Its own prop, not a `bar` member: added to every bar in the valley it tipped the card-game chair tests (#834) |

## Saloon B, batch S2 (#879)

Made and judged on the same stand, **not placed** (as S1: #865's body fix and #862's route first).
`tools/props/saloon_s2.py` (kit files), `tools/blender/props/saloon_s2.py` (models: the saw, the fiddle
and bow, the cookstove; the keg is the barrel's staves, the bench and rack library pine); the stand's
groups `bench`, `saw_fiddle`, `kegs`, `cookstove` in `saloon/s1_sheet.py`; references `refs/saloon/`
("Batch S2"). Results `results/2026-11-13_saloon_s2/`.

S1's three DIFFERENTs were redone first: the **wheel of fortune** (now the Evans dice wheel: 48 in, open,
30 panels of dice, 16 spokes, a gilt star hub, brass pegs out of its rim, a leather flapper on an oak
plank), the **lookout's chair** (seat at 1.1 m, a back and a footrest: 11 bodies, was 9) and the **till**
and the scales' base (`lib:furniture_oak/old`, not `few/top`: its varnish mirrored the sky). Also: the bar
glasses are `glass:flint` (a thicker, brighter outline: clear vanished at night), the hanging lamps'
chimney is `prop:chimney_glass@0.330` (its flame's height; the table lamp's 0.205 left it dark), and the
bridge's `prop_light` puts the lamp 0.16 under the height as the game does (S1's stand lit the lamps from
their smoke bells; the game's placing was right).

**Judged** (the blind critic, two rounds; `r1/critic.md`, `r2/critic.md`): r1 1 SAME (the plain hanging
lamp), 15 CLOSE, 2 DIFFERENT (the fiddle a toy guitar, the keg rack); r2 (S2's and the redone S1 groups) 1
SAME (the cookstove), 8 CLOSE, 1 DIFFERENT: **the keg rack** (kegs stand on end; a rack lays them on their
sides in cradles, tap end out). A kit prop is held only by what's under its own bottom (`KitProp._find_footing`
looks down its own y), so a keg turned on its side goes loose: a lying keg needs its own kit file, its staves
laid out one by one round a horizontal axis. Left for the next step, with the CLOSE notes still open: the
wheel's dice don't read (a blank navy ring; brighter, fewer, bigger marks), the fiddle's f-holes and teeth-like
strings, the saw's teeth and its handle's hole (a knife from a few steps), the bow's stick and hair too far
apart, the gold scales twice too big, the faro table unplayed (no chips), the kegs near-black with hoops the
wood's colour, the stove's smooth casting, the till a plain box, glass faint at night. (Round 2's critic read
round 1's file for its format before it was told to skip it, and says it judged only what it saw.)

| Prop | Bodies standing | Broken | Where in saloon B (room, count) |
| --- | --- | --- | --- |
| `wall_bench` | 10 | its members | dance hall: 6 round its walls; balcony: 1 (Balcony Ambush); the walk: 1-2. Its back against the wall (-z) |
| `handsaw` | 1 (LooseProp) | 1 (holed, bent) | Payday Night: carried up the outside stair; before that, by the yard's woodpile or the store room (1) |
| `fiddle` | 1 | 1 | dance hall: on the platform, on or by the fiddler's chair (1); in his hands while he plays (`grips`, no code yet) |
| `fiddle_bow` | 1 | 1 | with the fiddle (1) |
| `beer_keg` | 10 (8 staves, 2 heads) | its members; its beer runs (PropContents) | store room and cellar: ~12 on the racks (most as drawn stand-ins: twelve real are 120 bodies), 1 in the work board's ice box, empties on the yard's pile |
| `keg_rack` | 10 | its members | store room 1, cellar 1: four kegs a tier (rails' tops at 0.16 and 0.88 m). DIFFERENT: redo with kegs on their sides |
| `cookstove` | 12 | iron doesn't break; its pipe comes down; its coals a small fire | kitchen: 1, its pipe to the chimney (trim the lengths); the doctor's office: 1 (his kitchen) |

S2 as listed is ~145 bodies (eight benches 80, three real kegs 30, two racks 20, the cookstove 12, the
saw, fiddle and bow 3); with S1's (~219 now, the lookout's chairs 2 more each) ~365 for both batches. The
valley had ~5,100 to spare at #865's count.

## Saloon B, batch S3 (#892)

Made and judged on the same stand, **not placed** (as S1 and S2: #865's body fix and #862's route first).
`tools/props/saloon_s3.py` writes the kit files; no Blender this batch (the session couldn't install `bpy`:
pypi isn't reachable from it). The stand's groups `kegs` (redone), `bed`, `desk` in `saloon/s1_sheet.py`.
Results `results/2026-11-14_saloon_s3/` (r1: all three groups; r2: the desk again). **No new references**:
Commons and the Met's images weren't reachable from the session (a sub-agent tried ~12 min); the kegs were
judged against S2's racking-room photo, the bed and desk against the critic's knowledge of the period.

- **The keg on its side** (`beer_keg_side`, S2's DIFFERENT): S2's keg laid along z, tap head (its bung drawn on)
  at +z, its eight staves laid out one by one, each with its own `rot` (Godot's YXZ; `euler_yxz` in the factory),
  the sweep drawn about the keg's axis with the draw's `at`/`rot`. Kinds by height (post, stud, furniture_frame,
  rafter: the support graph is boxes, and a lying stave's box overlaps its neighbour's in height, so each pair
  rests on the pair under it by tier). **Its feet:** the two bottom staves, each two members end to end, their
  boxes flat (`solid` 0.32, a stave's weight): KitProp settles a prop by a ray under the middle of each foot's
  four lowest corners, so a whole-length foot's ray fell between a rack's rails to the floor, and a tilted box's
  corners sank it 11 mm. Full of beer: `holds` written for the lying cask (its height across, the middle's radius
  the round with the middle slice's area, the ends' solved to hold the upright keg's ~59 l).
- **The keg rack** (`keg_rack`, redone): a stillage, two tiers of oak cradle rails on six posts, the kegs lying
  across them tap end out, four a tier, chocks either side of each drawn on the rails; its kit file's `slots`
  say where each keg goes (the tests and the stand read them). 2.35 m long, the upper rails at 0.745 m.
- **The bed** (`plank_bed`): a single cottage bedstead, square posts with turned caps, a two-board headboard, a
  footboard, side rails and slats, in library walnut (old); its bedding the doctor's cot's (`iron_cot`'s Tick,
  Blanket, Pillow, the same size). New, not the cot: a rented room's bed, not a ward's. The brief's "iron or
  plain wood": two rooms the cot, two this (or four of this).
- **The owner's desk** (`owner_desk`): a flat-top double-pedestal kneehole desk (three drawers a side with brass
  pulls, a knee drawer, a modesty panel, a two-board top, a back gallery), library oak; on its top, drawn on,
  his ledgers (two closed, one open), papers, an inkstand and pen, a cigar box. New, not the doctor's roll-top
  (42 bodies, a professional man's). His strongbox is the kit's `strongbox`; his chair the kit's.
- **The washstand set** is the doctor's (`washstand`, `wash_basin`, `wash_pitcher`, `chamber_pot`, `hand_towel`):
  one set a rented room and one in the owner's office, the pot under each bed.

**Judged** (the blind critic, two rounds): r1 4 CLOSE (the rack, the lying kegs, the bed, the desk's things),
1 DIFFERENT (the desk: the chair hid one pedestal, it read as a one-pedestal school desk with a Mission chair);
r2 (the desk, the chair moved, the bentwood chair): the desk and its things CLOSE; **the kit's `bentwood_chair`
DIFFERENT** (a black tubular bistro chair) and **`strongbox` DIFFERENT** (a black steamer trunk): both existing
kit props, not S3's, for the placing session or a later batch. CLOSE notes open: the rack's posts and upper
rails cross the lower kegs' fronts and it's near-black at noon; the kegs near-black at noon (staves, hoops and
bung one mass: S2's note too); the bed clean and new (a slab blanket, no sag, square rails); the desk dark and
grainless, no mouldings or plinth; the ledgers blank slabs, the inkstand unreadable.

| Prop | Bodies standing | Broken | Where in saloon B (room, count) |
| --- | --- | --- | --- |
| `beer_keg_side` | 12 (8 staves, the bottom two in two lengths, 2 heads) | its members; its beer runs (PropContents) | store room and cellar: on the racks (`keg_rack.slots`; most as drawn stand-ins: eight real are 96), a few on the floor |
| `keg_rack` | 10 | its members; its kegs come down with it | store room 1, cellar 1 (2.35 x 0.57 m), back to the wall, tap ends out |
| `plank_bed` | 14 | its members; the rails, slats and bedding burn | rented rooms: 2-4 (the rest `iron_cot`), head against the wall (-z), a chamber pot under each |
| `owner_desk` | 13 | its members (the drawer fronts one member a pedestal) | the owner's office: 1, back to the wall; `strongbox` on the floor by it; his chair |

S3 as listed: two racks 20, a few real lying kegs ~36, four beds 56, the desk 13: ~125 bodies (S1 and S2 ~355
now the S2 rack's 20 are this one's): ~480 for the three batches.
