# McCready's Opera House (#1143): the design and the spec

The building lab's steps 1 and 2 (Sean, 2026-11-24: "design only", then on the sheet and plan "Looks good let's spec
it out"). Nothing here is built: the build (step 3) waits for after the slice, behind the line shack (#1091).

- **The sheet** (step 1): `sheet/` (ten views, `sheet/request.json`; painted by `building_sheet.yml`).
- **The spec** (step 2): `config/buildings/opera_house.json`, written by `tools/buildings/opera_house_spec.py`
  (edit the script, re-run it; `--sizing` prints the frame's checks); `status: "spec"`, on no valley lot, so
  nothing loads it. Its trial load in the lab is below.
- **The plans**: `plans.png` (ground floor and the balcony level, drawn from the spec by the same script).

## Sean's answers (2026-11-24, this session)

1. **The lot:** a new one at Main Street's east end, north side, past the undertaker's (the front faces south).
2. **The front:** red brick with dressed stone quoins, base, sills and keystones.
3. **The name:** MCCREADY'S OPERA HOUSE, 1881 (the cornice's frieze, the pediment's roundel).
4. **The balcony:** a horseshoe.
5. **The sheet and plan: OK** ("Looks good let's spec it out", #1242). Taken with it, as recommended there: **three
   tiers on the front** and **the lot kept** (say so on #1244 if either is wrong).
6. **Fewer seats, a bigger lobby with a bar** (Sean, 2026-11-24: "I don't think we need 523 chairs for a town so
   small... push the lobby forward a little bit and have a bar and something else in there"): **about 300 seats**,
   and the other room **a ladies' parlour** (his picks). The lobby block 33 ft deep (was 23), the hall shorter.

**A correction about the light (my mistake when I asked):** I said the front would catch sun all day. In the game
the sun stands over valley north (-Z) at noon (DayCycle's `sun_tilt_degrees`, `sun_azimuth_degrees` 0; the art
lane's trap), so **every north-side front (this one, the hotel's, saloon B's, the store's) is in shade by day**
and lit from the sky; the low evening sun comes from the west, grazing. At show time (dusk) the front is lit by
its own lamps either way. Sean kept the lot (#1242, the recommendation).

## The lot

valley.json town.north: the undertaker's lot ends at x 128.0. Proposed (not changed yet; the build's step):
a lane x 128.0-130.4 (8 ft: the hall's west exit), **the lot x 130.4-149.0** (61 ft) by the town's 125 ft
depth to Back Street; Main Street's and Back Street's `x` grow from 130 to 150. The East Road still leaves from
(130, 0) south-east; at x 149 its north edge is at z ~+2, clear of the walk (z -7.65 to -10.05).

**The ground** (probed, `ValleyTerrain.main().height`): the front line -0.44 (west) to -0.58 (east); 20 m back
+0.18 to +0.06; 30 m back +0.84 to +0.38 (Back Street's bank). So **0.65-1.0 m of rise to the back wall**: a pad dug
level at the walk's street edge (y -0.5) under the building and its yard, a bank left behind, as saloon B's.
The walk 0.45 m high (three steps), no awning; the building's floor its top.

## The plan

| | |
| --- | --- |
| Building | 60 x 110 ft (18.29 x 33.53 m), one plain rectangle, a 15 ft yard to Back Street |
| Walls | brick (Kidder): 17 in outside to the upper floor, 13 in above (a set-off for the joists), 13 in the lobby's back wall, the proscenium (a fire wall through the roof) and the dressing block; 9 in the vestibule's; footings 8 in wider, 4 ft down; stone base, quoins, sills, keystones. Each side wall in four parts by its height: the front block (14 m, the cornice returns), the hall (11.45 m, pilasters under the trusses), the stage house (13.96 m), the dressing block (8.17 m) |
| Front | 46 ft to the cornice's top, the pediment 52 ft; three arched doorways (pairs of glazed doors, fanlights, outward-opening), an arched window each side; five tall arched foyer windows, five small attic windows; two kerosene lamp standards on the walk, poster boards on the piers |
| Front block | the vestibule (8.5 ft) with the **box office** (ticket window with a brass grille) and the cloak room; behind its brick wall (13 in, to the roof: the block's middle bearing line) a band 24 ft deep: the **bar** (east, 17 x 24 ft: two bar sections and the back bar, its own glazed door onto the open ground), the **lobby** (middle, 23 ft wide) with the two stairs of 26 risers against the bar's and parlour's walls rising to landings at its back wall (doors there straight into the balcony), and the **ladies' parlour** (west, the bar's size, its windows on the lane). Upstairs: the **foyer** behind the five tall windows, through an arch the **gallery** over the lobby between the stairs' wells; **McCready's office** over the bar, the **committee room** over the parlour (the town's and the Miners' Union's meetings); over it all the **scene loft** |
| Hall | 57 x 30 ft clear to the pit, a level floor on five girder lines (a dance floor too: the front four rows on runners), 32 ft to a plaster ceiling with a rose and the 24-lamp chandelier; arched windows in two tiers in two bays a side, iron shutters; exits: the front, a pair each side by the boxes, one each side at the back; standing room behind the last row under the balcony |
| Seats | **310** (Sean: about 300): **parquet 208** (8 rows of 26 in one block, aisles along the walls under the balcony's side arms), **balcony 86** (3 back rows of 26, one row of 4 down each side), **boxes 16**. Small-town opera houses of the period seated 300-400 |
| Balcony | a horseshoe: back arm 11.8 ft deep (a cross aisle at the foyer's level and 3 rows stepping down 0.3 m), side arms 5.3 ft (a passage and a row) to the boxes, corners on a 10.5 ft radius; nine 6 in cast-iron columns under an 8x12 rail beam (they stand in the side aisles and between rows), 3.75 m clear under it; the carriages 3x12 at 16 in into pockets in the brick |
| Stage | 3 ft 6 in up; proscenium 28 x 20 ft; 22 ft deep plus a 4 ft apron with 14 kerosene footlights; a 6 ft pit for the band; a trap; the drop curtain and three roll drops (a small town's stage rolled its scenery, so no fly tower: the stage house 44 ft); a pin rail; the scenery door in the east wall at the stage's height (a wagon's bed) |
| Back | four dressing rooms down, four up, a corridor and the stage door to the yard |
| Roof | four Howe trusses (59 ft, 6.6 ft deep, 8 panels; 8x12 top chord, two 6x12 bottom, iron rods 1 5/8 to 1 in) at 12 ft over the hall, two over the stage house; purlins, 2x8 rafters, boards, tin; 3/12. The front block and the dressing block flat behind their parapets. The hall's ceiling hung from the bottom chords |

## The frame's checks (`opera_house_spec.py --sizing`)

Yellow pine at 1,200 lb/in2 in bending (the Wood Handbook's working stress), deflection under the live load against
L/360; 100 lb/ft2 where a crowd stands (Kidder, theatres), 70 the dance floor, 40 roofs and lofts; cast iron by
Gordon's formula; the truss by the method of sections. Every member passes; the tightest are the balcony's rail beam over its side bay and the office's, gallery's and committee room's 4x14s over 24 ft (0.78-0.83).

| Member | Size, span, load | Stress | Deflection (live) | |
| --- | --- | --- | --- | --- |
| hall floor | 2x12 at 16 in, 9.5 ft, 70 lb/ft2 | 468 lb/in2 (0.39) | 0.06 in of 0.32 | ok |
| lobby, dressing floors | 2x10 at 16 in, 9.8 ft, 100 lb/ft2 | 995 lb/in2 (0.83) | 0.17 in of 0.33 | ok |
| office, gallery, committee | 4x14 at 12 in, 23.9 ft, 100 lb/ft2 | 937 lb/in2 (0.78) | 0.68 in of 0.80 | ok |
| scene loft, front roof | 4x14 at 12 in, 23.9 ft, 40 lb/ft2 | 435 lb/in2 (0.36) | 0.27 in of 0.80 | ok |
| stair landing | 2x10 at 16 in, 4.5 ft, 100 lb/ft2 | 212 lb/in2 (0.18) | 0.01 in of 0.15 | ok |
| balcony carriage, back arm | 3x12 at 16 in, 14.5 ft, 100 lb/ft2 | 893 lb/in2 (0.74) | 0.28 in of 0.48 | ok |
| balcony side arm | 3x12 at 16 in, 8.2 ft, 100 lb/ft2 | 286 lb/in2 (0.24) | 0.03 in of 0.27 | ok |
| box floor | 3x10 at 16 in, 6.6 ft, 100 lb/ft2 | 274 lb/in2 (0.23) | 0.02 in of 0.22 | ok |
| dressing roof | 2x10 at 16 in, 9.8 ft, 40 lb/ft2 | 462 lb/in2 (0.39) | 0.07 in of 0.33 | ok |
| hall ceiling (hung) | 2x8 at 16 in, 12.0 ft, 10 lb/ft2 | 482 lb/in2 (0.40) | 0.08 in of 0.40 | ok |
| roof rafter | 2x8 at 24 in, 7.4 ft, 40 lb/ft2 | 650 lb/in2 (0.54) | 0.07 in of 0.25 | ok |
| rail beam, side bay | 8x12, 14.6 ft, 100 lb/ft2 | 994 lb/in2 (0.83) | 0.29 in of 0.49 | ok |
| rail beam, back bay | 8x12, 9.9 ft, 100 lb/ft2 | 808 lb/in2 (0.67) | 0.11 in of 0.33 | ok |
| well trimmer (a bay) | 8x12, 10.5 ft, 100 lb/ft2 | 391 lb/in2 (0.33) | 0.06 in of 0.35 | ok |
| cast-iron column | 6 in, 3/4 in metal, 12.5 ft, 10613 lb | 1528 lb/in2 (0.15 of 10,000 working) |  | ok |
| Howe truss, chords | 59 ft span, 6.6 ft deep, 39540 lb a truss | 44452 lb: bottom 2-6x12 359 lb/in2, top 8x12 527 lb/in2 |  | ok (the joints govern: keyed and bolted) |
| Howe truss, end rods | 1 5/8 in wrought, 17299 lb | 8341 lb/in2 (of 10,000) |  | ok |

## The trial load (the lab's builder, today)

The spec loaded into `experiments/building_lab/lab.gd` (a throwaway test, not committed): **every part the builder
already has takes it** (the brick walls as the jail's stone walls with their profiles, set-offs and openings; the
floors on ground and upper; the stairs; the partitions; the lamps). It stops only at the new parts: the levels
`stage`, `attic`, `dress_upper`, `dress_roof`, `front_roof` (the builder knows cellar, ground and upper), and so the
stage, the balcony, the boxes, the trusses and the roof aren't built; the bar's kit sections place. What it built
(after Sean's bigger lobby): **6,983 members, 3,981 of them brick lifts** (the walls alone are near twice the 2,000 I estimated: 0.6 m x 1.2 m lifts). With the floors, balcony,
stage and roof the whole will be **~11-13k, like the hotel's 12.5k**, which already slowed every valley load
(#1227, #1237). So the BrickWall's lifts should be bigger (1.2 x 2.4 m: ~1,000) or rest batched until hit.

## Where the sheet differs from the spec (the spec wins)

Painted 2026-11-24, ten views, **$1.407** (run 14 of `building_sheet.yml`). The look is right: red brick, buff stone
quoins and keystones, the bracketed cornice and pediment, gilt and red plush inside, the horseshoe on iron columns.
- **The front is two storeys**, not the spec's three tiers: no row of small attic windows, the cornice lower. Either
  reads; the spec's 46 ft front stands taller over the undertaker's (Sean's call at the build).
- **The flank** has the stage house right (taller at the back), but only one scenery door and no fire shutters.
- **The hall view** draws the horseshoe as a full ring of boxes-like rows on both sides and the chandelier off to one
  side; the plan's side arms are two rows, the chandelier on the hall's middle.
- **The footlights** are drawn as big lanterns on the stage's edge (house view): the spec's are a trough of 14 small
  lamps with tin reflectors, as the hall view draws them.
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
| **Horseshoe balcony and stepped floors** | a curved deck laid in 0.6 m segments (a ball or a charge brings down a segment, not the sweep), rows stepped 0.3 m, a panelled gilt front | the boxes; a church gallery |
| **Stage** | saloon B's stage grown up: raised floor with a trap, apron and footlight trough, a proscenium `void` with an arch, roll drops on battens (`PaintedDrop`), the pin rail (`Rope`) | saloon B; the moments system's shows (#1143's idea) |
| **Theatre chairs** (prop lab) | folding seats on cast-iron standards in rows, plush | the church's pews later? |
| **Lamp standard, poster boards, gilt letters** (prop lab, sign art) | kerosene street lamps, show bills, gold leaf on the frieze and glass | the hotel |

**Cost to measure before building:** the trial's numbers above; the BrickWall's lifts and resting members
(`rest_batched`) decide whether it fits beside the hotel.

**For the prop lab** (`props_wanted` in the spec): the opera chair (and the boxes' gilt chairs), the pit's upright
piano, McCready's safe, the foyer's settees, the lamp standard; then the posters (texture factory) and the drops.

## References that matter (the recipe's blocked hosts: Sean to check)

Central City Opera House (1878) and the Tabor Opera House, Leadville (1879): size, the horseshoe, the boxes;
Kidder's *Building Construction and Superintendence* (brick walls); Haupt and Hatfield (Howe trusses);
A. H. Andrews & Co.'s opera-chair catalogues; the Wright Opera House, Ouray (1888, a cast-iron front: a little late).

## What this session read (both steps)

CLAUDE.md; `docs/lanes/art.md`; RECIPE.md ("Before step 1", steps 1-2, "two-storey building under trusses",
"The valley", "A church", "A big two-storey hotel"); FORMAT.md's parts table; `docs/PARTS.md`'s structures;
`config/valley.json` town.north, roads, places; the hotel's `sheet_request.json` and brief §9-11 (branch
`claude/salt-creek-hotel-design-olzd6z`); `src/world/day_cycle.gd` (the sun); for the spec: the jail's, saloon B's and the
hotel's specs (stone walls, stage, balconies, floors, posts, beams, stairs), `stone.gd`'s profile, `marks.gd`'s use paths.
