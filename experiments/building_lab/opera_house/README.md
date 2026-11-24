# McCready's Opera House (#1143): the design

The building lab's steps 1 and 2 as a design only (Sean, 2026-11-24 on #1143: "design only ... then stop for
Sean's OK"; the build waits for after the slice, behind the line shack #1091). Nothing here is built.

- **The sheet** (step 1): `sheet/` (ten views, `sheet/request.json`; painted by `building_sheet.yml`).
- **The spec** (step 2): `config/buildings/opera_house.json`, written by `tools/buildings/opera_house_spec.py`
  (edit the script, re-run it); `status: "design"`, not on any valley lot, so nothing loads it.
- **The plans**: `plans.png` (ground floor and the balcony level, drawn from the spec by the same script).

## Sean's answers (2026-11-24, this session)

1. **The lot:** a new one at Main Street's east end, north side, past the undertaker's (the front faces south).
2. **The front:** red brick with dressed stone quoins, base, sills and keystones.
3. **The name:** MCCREADY'S OPERA HOUSE, 1881 (the cornice's frieze, the pediment's roundel).
4. **The balcony:** a horseshoe.

**A correction about the light (my mistake when I asked):** I said the front would catch sun all day. In the game
the sun stands over valley north (-Z) at noon (DayCycle's `sun_tilt_degrees`, `sun_azimuth_degrees` 0; the art
lane's trap), so **every north-side front (this one, the hotel's, saloon B's, the store's) is in shade by day**
and lit from the sky; the low evening sun comes from the west, grazing. At show time (dusk) the front is lit by
its own lamps either way. Put to Sean on the design's issue.

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
| Walls | brick, 17 in outside (Kidder: public halls to 40 ft), the proscenium a 13 in fire wall full height, 12 in lobby and dressing walls; stone base, quoins, sills, keystones |
| Front | 46 ft to the cornice's top, the pediment 52 ft; three arched doorways (pairs of glazed doors, fanlights, outward-opening), an arched window each side; five tall arched foyer windows, five small attic windows; two kerosene lamp standards on the walk, poster boards on the piers |
| Front block | vestibule (8 ft) with the **box office** (ticket window with a brass grille onto the vestibule) and the cloak room; the **lobby** (15 ft) with two dog-leg stairs (26 risers to the foyer, 5 m) in an open well; upstairs the **foyer** and McCready's office |
| Hall | 57 x 41 ft clear to the pit, level floor (a dance floor too: the front four rows on runners), 32 ft to a plaster ceiling with a rose and the brass chandelier; four tall arched windows a side, iron shutters; exits: the front, a pair each side by the boxes, one each side at the back |
| Seats | **parquet 312** (12 rows of 6-14-6, 32 in rows, 20 in chairs), **balcony 152** (4 back rows, 2 down each side), **boxes 16** (four, 4 chairs): **480** (Central City's, 1878: ~550) |
| Balcony | a horseshoe: back arm 11 ft deep (4 rows rising 0.3 m each to the foyer's level), side arms 7.5 ft (2 rows) running to the boxes, corners on a 10.5 ft radius; ten 6 in cast-iron columns under its rail |
| Stage | 3 ft 6 in up; proscenium 28 x 20 ft; 22 ft deep plus a 4 ft apron with 14 kerosene footlights; a 6 ft pit for the band; a trap; the drop curtain and three roll drops (a small town's stage rolled its scenery, so no fly tower: the stage house 44 ft); a pin rail; the scenery door in the east wall at the stage's height (a wagon's bed) |
| Back | four dressing rooms down, four up, a corridor and the stage door to the yard |
| Roof | Howe trusses (timber chords and braces, iron rods) at 12 ft over the 57 ft hall, 3/12 behind parapets |

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
| **BrickWall** | bricks in common bond, members as lifts of courses (~0.6 m, the jail's stone courses' size, to keep the count near 2,000 not 12,000), chipped by voxel carving, a charge drops courses; stone dressings from the jail's stone pieces | the bank, the Baron's house, chimneys |
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

**Cost to measure before building:** the hotel's 12.5k members already slowed every valley load (#1227, #1237);
an opera house is bigger. The BrickWall's lifts and resting members (`rest_batched`) decide whether it fits.

## References that matter (the recipe's blocked hosts: Sean to check)

Central City Opera House (1878) and the Tabor Opera House, Leadville (1879): size, the horseshoe, the boxes;
Kidder's *Building Construction and Superintendence* (brick walls); Haupt and Hatfield (Howe trusses);
A. H. Andrews & Co.'s opera-chair catalogues; the Wright Opera House, Ouray (1888, a cast-iron front: a little late).

## What this session read

CLAUDE.md; `docs/lanes/art.md`; RECIPE.md ("Before step 1", steps 1-2, "two-storey building under trusses",
"The valley", "A church", "A big two-storey hotel"); FORMAT.md's parts table; `docs/PARTS.md`'s structures;
`config/valley.json` town.north, roads, places; the hotel's `sheet_request.json` and brief §9-11 (branch
`claude/salt-creek-hotel-design-olzd6z`); `src/world/day_cycle.gd` (the sun).
