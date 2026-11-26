# McCready's Opera House (#1143): the design and the spec

The building lab's steps 1 and 2 (Sean, 2026-11-24: "design only", then on the sheet and plan "Looks good let's spec
it out"). Nothing here is built: the build (step 3) waits for after the slice, behind the line shack (#1091).
**Redesigned 2026-11-26 (#1289) at about 100 seats**, a two-row balcony and two private boxes (Sean's answers 7,
below); the painted sheet stays the look, the spec and the plans are what changed.

- **The sheet** (step 1): `sheet/` (ten views, `sheet/request.json`; painted by `building_sheet.yml`).
- **The spec** (step 2): `config/buildings/opera_house.json`, written by `tools/buildings/opera_house_spec.py`
  (edit the script, re-run it; `--sizing` prints the frame's checks); `status: "spec"`, on no valley lot, so
  nothing loads it. Its trial load in the lab is below.
- **The plans**: `plans.png` (the ground floor, the balcony and box level with the boxes' sightlines, and two sections
  through the box: A-A across the hall, B-B along the passage to the yard), drawn from the spec by the same script
  (`--plans=OUT.png`; `--members=OLD_SPEC.py` prints the member estimate below).

## Sean's answers (2026-11-24, this session)

1. **The lot:** a new one at Main Street's east end, north side, past the undertaker's (the front faces south).
2. **The front:** red brick with dressed stone quoins, base, sills and keystones.
3. **The name:** MCCREADY'S OPERA HOUSE, 1881 (the cornice's frieze, the pediment's roundel).
4. *(superseded by 7: a straight two-row balcony)* **The balcony:** a horseshoe.
5. **The sheet and plan: OK** ("Looks good let's spec it out", #1242). Taken with it, as recommended there: **three
   tiers on the front** and **the lot kept** (say so on #1244 if either is wrong).
6. *(superseded by 7)* **Fewer seats, a bigger lobby with a bar** (Sean, 2026-11-24: "I don't think we need 523 chairs for a town so
   small... push the lobby forward a little bit and have a bar and something else in there"): **about 300 seats**,
   and the other room **a ladies' parlour** (his picks). The lobby block 33 ft deep (was 23), the hall shorter.

7. **About 100 seats, a small balcony and two private boxes** (Sean, 2026-11-26, #1244's comments and this session,
   #1289): a room holds 40-60 living people (the people budget), so a 300-seat hall would always look empty. His picks
   in this session: **"about 100 seats mixed between the two"** (floor and balcony: 56 on the floor, 36 in two
   balcony rows, 8 in the boxes), **one box each side**, and for the narrower hall **"more backstage area for the
   opera props and scenes"**: the front block keeps its 60 ft (front, cornice, gilt name, bar, lobby, parlour
   unchanged), the hall steps in to 42 ft between two open courts, and the stage house keeps the full 60 ft (wings
   17 ft a side, a scene dock and a property room). The boxes are built for an assassination (#1287: "John Wilkes
   Booth private seating"); the mission isn't designed, the building only makes it possible.
8. **The plan: OK** (Sean, 2026-11-26, on `plans.png` and the numbers: "OK, as drawn"). The build (#1244) builds this.

**A correction about the light (my mistake when I asked):** I said the front would catch sun all day. In the game
the sun stands over valley north (-Z) at noon (DayCycle's `sun_tilt_degrees`, `sun_azimuth_degrees` 0; the art
lane's trap), so **every north-side front (this one, the hotel's, saloon B's, the store's) is in shade by day**
and lit from the sky; the low evening sun comes from the west, grazing. At show time (dusk) the front is lit by
its own lamps either way. Sean kept the lot (#1242, the recommendation).

## The lot

valley.json town.north: the undertaker's lot ends at x 128.0. Proposed (not changed yet; the build's step):
a lane x 128.0-130.4 (8 ft), **the lot x 130.4-149.0** (61 ft) by the town's 125 ft depth to Back Street (the
building 105 ft deep, a 20 ft yard behind); Main Street's and Back Street's `x` grow from 130 to 150. The East Road still leaves from
(130, 0) south-east; at x 149 its north edge is at z ~+2, clear of the walk (z -7.65 to -10.05).

**The ground** (probed, `ValleyTerrain.main().height`): the front line -0.44 (west) to -0.58 (east); 20 m back
+0.18 to +0.06; 30 m back +0.84 to +0.38 (Back Street's bank). So **0.65-1.0 m of rise to the back wall**: a pad dug
level at the walk's street edge (y -0.5) under the building and its yard, a bank left behind, as saloon B's.
The walk 0.45 m high (three steps), no awning; the building's floor its top.

## The plan (2026-11-26: about 100 seats)

| | |
| --- | --- |
| Building | a cross, 105 ft deep: the **front block** 60 x 34.5 ft; the **hall** 42 ft wide (outside) x 35 ft between two open **courts** (9 ft, open to the lane and the open ground: the hall's exits); the **stage house** and **dressing block** 60 ft wide again; a 20 ft yard to Back Street |
| Walls | brick (Kidder): 17 in outside to the upper floor, 13 in above; 13 in the lobby's back wall (the front block's back on the courts), the proscenium (a fire wall through the roof; the stage house's front on the courts) and the dressing block; footings 8 in wider, 4 ft down; stone base, quoins, sills, keystones |
| Front | unchanged: 46 ft to the cornice's top, the pediment 52 ft; three arched doorways, an arched window each side; five tall arched foyer windows, five small attic windows; the gilt name; two lamp standards, poster boards |
| Front block | unchanged: the vestibule with the box office and the cloak room; the **bar** (east), the **lobby** with its two stairs to landings that open into the balcony's back aisle, the **ladies' parlour** (west); upstairs the foyer, the gallery, **McCready's office**, the **committee room**; the scene loft. New: back windows from the bar, parlour, office and committee room onto the courts |
| Hall | 39 ft clear x 35 ft (lobby wall to proscenium), a level dance floor (all four rows on runners), 32 ft to the plaster ceiling and a 16-lamp chandelier; two bays of arched windows a side in two tiers on the courts, iron shutters; exits: the front, a pair each side by the boxes and one each side at the back, all onto the courts; standing room under the balcony |
| Seats | **100** (Sean: "about 100 seats mixed between the two"): **parquet 56** (4 rows of 14 in two blocks of 7, a middle aisle, side aisles 1.9 m), **balcony 36** (2 rows of 18), **boxes 8** (4 each). 50-60 people fill the floor and read as a full house; the balcony is the cheap seats |
| Balcony | straight across the hall's back: a 1 m cross aisle at the foyer's level and two rows stepping down 0.3 m (9 ft deep in all), the rail beam 8x14 on three 6 in cast-iron columns (in the middle and side aisles), 4 m clear under it. Its ends shut off by the box passages' walls |
| **The boxes** | **one each side over the forestage's ends**, either side of the proscenium: 1.6 x 2.4 m, the floor **3.5 m over the stage** (5.0 m over the pad), four gilt chairs, a padded rail and a red curtain on a rod on the house side, a bracket lamp. **Shut off from the house:** each reached only from the balcony's back aisle through its **vestibule door** (it opens in; a bar drops into iron keepers on the passage side, as at Ford's in 1865), then two steps down and along its own **passage** (0.9 m wide, 7.3 m long, plastered and papered, a lamp, no opening on the house) on the hall's side wall to the **box's door** (a gimlet hole in it) in the box's back wall, by the side wall. Under each box a door through the proscenium into the wings; steps from the forestage's end down into the side aisle |
| Stage | 3 ft 6 in up; proscenium 22 x 18 ft; 22 ft deep behind it and 60 ft wide (wings 17 ft a side), plus a **forestage** the hall's width 8 ft out with 12 kerosene footlights; a pit for the band (piano, fiddle, cornet); a trap; the drop curtain and three roll drops (no fly tower: the stage house 42 ft), a pin rail on a fly gallery; the **scene dock** (east wing, racks of flats, the scenery door at a wagon bed's height) and the **property room** (west wing, walled, a wide door) |
| Back | four dressing rooms down, four up, a corridor and the stage door to the yard |
| Roof | two Howe trusses over the hall (41 ft span, 4.9 ft deep, 6 panels, rods 1 3/8 in at the ends) at 11.7 ft; two over the stage house (59 ft); purlins, 2x8 rafters, boards, tin; 3/12. The front block and dressing block flat behind parapets. The hall's ceiling hung from the bottom chords |

## The boxes' sightlines (`boxes.sightlines` in the spec, drawn on the balcony plan and section A-A)

The east box (the west one mirrors it). A line from an eye to the target must pass through the box's open front
(between its back wall and the proscenium) and over its rail (0.75 m). Targets: **the door** (the head of a man
standing in it) and **the guest** (seated at the front, the rail's back chair).

- **The door is 0.9 m behind the guest's chair, 166 degrees off where he looks** (at the stage): a man comes in
  behind him.
- **Nobody in the parquet or the balcony sees the door**: the box's back wall hides it. They see the guest (the
  west half of the house, the balcony, the band); the east side of the parquet, under the box, sees neither.
- **The stage sees in**: an actor on the forestage or at centre stage, the prompter in the west wing and the west
  box's guest see the door and the guest (who'd see the shot, and the man who fired it).
- **Who goes along the passage is unseen**: its house side is a plastered wall with no opening.
- **The drop** to the forestage is 3.5 m (a sprain or a broken leg); then the door under the box into the wings,
  across the stage, the corridor and the stage door to the yard (section B-B's magenta line). Or back along the
  passage, through the barred door (if he unbars it) to the balcony and down the lobby's stairs.

| Who | sees the door | sees the guest |
| --- | --- | --- |
| parquet, back row, east block | - | - |
| parquet, front row, east end | - | - |
| parquet, front row, west end | - | sees |
| standing room, the back | - | - |
| balcony, front row, middle | - | sees |
| balcony, front row, west end | - | sees |
| the band in the pit | - | sees |
| an actor on the forestage | sees | sees |
| an actor at centre stage | sees | sees |
| the west wing (prompter's side) | sees | sees |
| the west box's guest | sees | sees |

## The frame's checks (`opera_house_spec.py --sizing`)

Yellow pine at 1,200 lb/in2 in bending (the Wood Handbook's working stress), deflection under the live load against
L/360; 100 lb/ft2 where a crowd stands (Kidder, theatres), 70 the dance floor, 40 roofs and lofts; cast iron by
Gordon's formula; the truss by the method of sections. Every member passes; the tightest are the front block's 4x14s
over 24 ft (unchanged, 0.78-0.83) and the balcony's rail beam (0.81). The hall truss's end rods went from 1 1/4 in
(0.96) to 1 3/8 in.

| Member | Size, span, load | Stress | Deflection (live) | |
| --- | --- | --- | --- | --- |
| hall floor | 2x12 at 16 in, 9.5 ft, 70 lb/ft2 | 468 lb/in2 (0.39) | 0.06 in of 0.32 | ok |
| lobby, dressing floors | 2x10 at 16 in, 9.8 ft, 100 lb/ft2 | 995 lb/in2 (0.83) | 0.17 in of 0.33 | ok |
| office, gallery, committee | 4x14 at 12 in, 23.9 ft, 100 lb/ft2 | 937 lb/in2 (0.78) | 0.68 in of 0.80 | ok |
| scene loft, front roof | 4x14 at 12 in, 23.9 ft, 40 lb/ft2 | 435 lb/in2 (0.36) | 0.27 in of 0.80 | ok |
| stair landing | 2x10 at 16 in, 4.5 ft, 100 lb/ft2 | 212 lb/in2 (0.18) | 0.01 in of 0.15 | ok |
| balcony carriage | 3x12 at 16 in, 9.0 ft, 100 lb/ft2 | 340 lb/in2 (0.28) | 0.04 in of 0.30 | ok |
| box passage floor | 2x8 at 16 in, 3.3 ft, 100 lb/ft2 | 183 lb/in2 (0.15) | 0.00 in of 0.11 | ok |
| box floor | 3x10 at 16 in, 5.2 ft, 100 lb/ft2 | 173 lb/in2 (0.14) | 0.01 in of 0.17 | ok |
| dressing roof | 2x10 at 16 in, 9.8 ft, 40 lb/ft2 | 462 lb/in2 (0.39) | 0.07 in of 0.33 | ok |
| hall ceiling (hung) | 2x8 at 16 in, 12.0 ft, 10 lb/ft2 | 482 lb/in2 (0.40) | 0.08 in of 0.40 | ok |
| roof rafter | 2x8 at 24 in, 7.4 ft, 40 lb/ft2 | 650 lb/in2 (0.54) | 0.07 in of 0.25 | ok |
| rail beam | 8x14, 16.3 ft, 100 lb/ft2 | 976 lb/in2 (0.81) | 0.31 in of 0.54 | ok |
| passage beam | 6x10, 9.1 ft, 100 lb/ft2 | 422 lb/in2 (0.35) | 0.06 in of 0.30 | ok |
| box front beam | 8x12, 7.9 ft, 100 lb/ft2 | 185 lb/in2 (0.15) | 0.02 in of 0.26 | ok |
| box header (the passage beam's end on it) | 8x12, 5.2 ft, 100 lb/ft2 | 266 lb/in2 (0.22) | 0.01 in of 0.17 | ok |
| well trimmer (a bay) | 8x12, 10.5 ft, 100 lb/ft2 | 391 lb/in2 (0.33) | 0.06 in of 0.35 | ok |
| cast-iron column | 6 in, 3/4 in metal, 13.1 ft, 10758 lb | 1619 lb/in2 (0.16 of 10,000 working) |  | ok |
| Howe truss, hall, chords | 41 ft span, 4.9 ft deep, 26796 lb a truss | 28006 lb: bottom 2-6x12 226 lb/in2, top 8x12 332 lb/in2 |  | ok (the joints govern: keyed and bolted) |
| Howe truss, hall, end rods | 1 3/8 in wrought, 11723 lb | 7895 lb/in2 (of 10,000) |  | ok |
| Howe truss, stage house, chords | 59 ft span, 6.6 ft deep, 39746 lb a truss | 44785 lb: bottom 2-6x12 362 lb/in2, top 8x12 531 lb/in2 |  | ok (the joints govern: keyed and bolted) |
| Howe truss, stage house, end rods | 1 5/8 in wrought, 17389 lb | 8385 lb/in2 (of 10,000) |  | ok |

## The member count and memory (`opera_house_spec.py --members=OLD_SPEC.py`)

**Not built yet**, so estimated from the spec, part by part (brick lifts by area, joists and boards by spacing, the
trusses, rafters, boards and tin by the roof's size), and calibrated against the lab's trial load of the 310-seat
spec (6,983 members, 3,981 of them brick lifts: the estimator's factors came out 1.23 and 1.16). Memory at the
hotel's measured 18.6 KB a member (#1259 aims at 15). The hotel: ~15.7k members, ~285 MB (Sean, 2026-11-25: every
other building under it).

| Part | 310-seat spec | this spec, 0.6 x 1.2 m lifts | this spec, 1.2 x 2.4 m lifts |
| --- | --- | --- | --- |
| brick lifts | 3981 | 3888 | 1073 |
| partitions | 1058 | 1572 | 1572 |
| floors | 2950 | 2876 | 2876 |
| stairs | 243 | 243 | 243 |
| balcony | 625 | 192 | 192 |
| boxes | 144 | 19 | 19 |
| stage | 508 | 571 | 571 |
| roof | 1320 | 1022 | 1022 |
| ceiling | 245 | 163 | 163 |
| seats | 359 | 116 | 116 |
| **whole** | **11433** | **10662** | **7847** |
| memory at 18.6 KB a member | 208 MB | 194 MB | 143 MB |
| against the hotel (~15.7k, ~285 MB) | 73% | 68% | 50% |

So at about 100 seats the opera house is **~10.7k members (~195 MB, 68% of the hotel) with today's brick lifts**, and
**~7.8k (~145 MB, half the hotel) with the 1.2 x 2.4 m lifts** Sean took on #1244. The smaller hall saves less than
its seats suggest: the cross plan adds the courts' walls (the front block's back, the stage house's front) and the
passages and the property room add partitions; the seats, balcony and boxes were never the bulk. The build measures
the real count and memory before merging (the trial's numbers aren't for this plan).

## Where the sheet differs from the spec (the spec wins)

Painted 2026-11-24, ten views, **$1.407** (run 14 of `building_sheet.yml`). The look is right: red brick, buff stone
quoins and keystones, the bracketed cornice and pediment, gilt and red plush inside, the horseshoe on iron columns.
- **The front is two storeys**, not the spec's three tiers: no row of small attic windows, the cornice lower. Either
  reads; the spec's 46 ft front stands taller over the undertaker's (Sean's call at the build).
- **The flank** has the stage house right (taller at the back), but only one scenery door and no fire shutters.
- **The hall view** draws the old horseshoe and a big house: the plan now has a straight two-row balcony, a 39 ft
  hall of 56 seats and two closed boxes over the forestage (the painted sheet stays the look: Sean, 2026-11-26).
- **The footlights** are drawn as big lanterns on the stage's edge (house view): the spec's are a trough of 12 small
  lamps with tin reflectors along the forestage's middle.
- **The flank** shows one long wall: the plan is now a cross (the hall stepped in between two courts).
- The plan view's rooms agree with the spec's order (vestibule, lobby, hall, pit, stage, dressing rooms); its scale is
  decoration (the recipe's trap).

## The new parts (each promoted into `src/structures` and `docs/PARTS.md` when built, shared)

| Part | What it is | Shared with |
| --- | --- | --- |
| **New levels** | `stage`, `attic`, `dress_upper`, `dress_roof`, `front_roof`: floors at any named height (the builder's cellar/ground/upper made a list) | every building after |
| **BrickWall** | the jail's stone walls with `masonry: brick` (they build today as stone pieces): the brick shader (common bond), lifts big enough to keep the count down (above), chipped by voxel carving, a charge drops lifts; stone dressings; a `set_off`'s thinner wall | the bank, the Baron's house, chimneys |
| **Round-arched openings** | a gauged-brick arch with a stone keystone; `SashWindow`'s head (the church's `rise`) as a semicircle; arched doorways with fanlights | the hotel (arched ground-floor windows), the bank |
| **Cornice** | bracketed, galvanized iron on a timber frame; a frieze for the gilt name; a pediment with a roundel | the hotel, the bank, saloon B's (one part) |
| **Cast-iron column** | hollow, 6 in: shatters rather than bends; saloon B's corner column made a part | the hotel's storefront, the bank, storefronts |
| **Plaster on lath and wallpaper** | cracks, falls in chunks off its lath, the paper tears with it; a plaster ceiling with a cornice and a rose | the hotel (in its plan), the bank, the Baron's house |
| **Hung chandelier** | a kerosene chandelier on the `Rope` part through the ceiling's rose (hung things aren't supported members) | the hotel, saloon B |
| **Howe truss** | 57 ft span, timber chords and braces, iron rods | the freight warehouse, the livery |
| **Balcony and stepped floors** | a straight deck in tiers stepped 0.3 m on raking carriages, a panelled gilt front on a rail beam and cast-iron columns | a church gallery |
| **Private box** | a small floor at any height on a wall's pockets, a header and a corner column; a padded rail, a curtain on a rod; its passage (a partition with no opening, a door that takes a bar: a door's `bar` keepers, NEW) | (the assassination, #1287) |
| **Stage** | saloon B's stage grown up: raised floor with a trap, a forestage and footlight trough, a proscenium `void` with an arch, roll drops on battens (`PaintedDrop`), the pin rail (`Rope`) | saloon B; the moments system's shows (#1143's idea) |
| **Theatre chairs** (prop lab) | folding seats on cast-iron standards in rows, plush | the church's pews later? |
| **Lamp standard, poster boards, gilt letters** (prop lab, sign art) | kerosene street lamps, show bills, gold leaf on the frieze and glass | the hotel |

**Cost to measure before building:** the estimate above; the BrickWall's lifts and resting members
(`rest_batched`) decide how far under the hotel it comes.

**For the prop lab** (`props_wanted` in the spec): the opera chair (and the boxes' gilt chairs), the scene dock's racks, the pit's upright
piano, McCready's safe, the foyer's settees, the lamp standard; then the posters (texture factory) and the drops.

## References that matter (the recipe's blocked hosts: Sean to check)

Central City Opera House (1878) and the Tabor Opera House, Leadville (1879): size, the horseshoe, the boxes;
Kidder's *Building Construction and Superintendence* (brick walls); Haupt and Hatfield (Howe trusses);
A. H. Andrews & Co.'s opera-chair catalogues; the Wright Opera House, Ouray (1888, a cast-iron front: a little late).

## What the redesign session read (#1289)

CLAUDE.md; `docs/lanes/art.md`; #1289, #1244 and its comments, #1287; RECIPE.md "Step 2", "A two-storey building
under trusses", "A church"; the spec script whole. Not re-read: FORMAT.md, PARTS.md (no new part was promoted).

## What the first sessions read (both steps)

CLAUDE.md; `docs/lanes/art.md`; RECIPE.md ("Before step 1", steps 1-2, "two-storey building under trusses",
"The valley", "A church", "A big two-storey hotel"); FORMAT.md's parts table; `docs/PARTS.md`'s structures;
`config/valley.json` town.north, roads, places; the hotel's `sheet_request.json` and brief §9-11 (branch
`claude/salt-creek-hotel-design-olzd6z`); `src/world/day_cycle.gd` (the sun); for the spec: the jail's, saloon B's and the
hotel's specs (stone walls, stage, balconies, floors, posts, beams, stairs), `stone.gd`'s profile, `marks.gd`'s use paths.
