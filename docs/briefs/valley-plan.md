# The Salt Creek Valley master plan (Phase 1: planning)

Sean's brief of 2026-11-07 ("Complete valley master plan handoff"), issue #467. **Planning only:
nothing in the game changes.** The decided inputs are PR #621's `docs/briefs/valley.md` (the
November 3 lock), #467's comments and the November 7 town picture. This file holds the reasons
and the calls; the numbers live in one place:

| File | What it is |
|---|---|
| `config/valley.json` | **The plan as data.** Every place, road, bridge, the creek, canyon and arroyo, the railway in `TrainRoute`'s own format, the town's lots, viewpoints, terrain control points. Inert: nothing reads it until Sean approves. |
| `tools/valley/valley_plan.py` | Draws and checks everything from that file: `python3 tools/valley/valley_plan.py` (numpy, matplotlib). `--check` runs the checks only. |
| `docs/concept/valley-map.png` | **A. The master map.** West at the top, north right, east at the bottom, south left (as `town-map.png`), with world X and Z on its axes. Contours every 5 m. |
| `docs/concept/valley-town.png` | **B. The town, enlarged.** North up, as Sean's November 7 picture, so the two compare side by side. |
| `docs/concept/valley-profiles.png` | **E.** The rail profile, its cut and fill, the creek's profile, the canyon's sections, road profiles. |
| `docs/concept/valley-decisions.png` | **H.** Small diagrams for the decisions. |
| `docs/briefs/valley-tables.md` | **D, E, F.** Generated: the checks, the coordinate schedule, the town's lots, rail marks and earthworks, the creek and canyon, road grades, travel times, train times, trestle sightlines. |

Status words as Sean's: **DECIDED** (his; not reopened), **PROPOSED** (this plan's), **OPEN**
(needs his call; listed under "Decisions" at the end). Every number in `valley.json` is PROPOSED
unless its entry says DECIDED.

## 1. How the sources were reconciled

- **The town:** Sean's November 7 picture is the reference, and its spacing stands as drawn
  (#467, Sean's last comment). This replaces the comment above it about tightening the core.
- **The trestle:** 130 m long, rail 27 m over the creek (`docs/briefs/trestle.md`, round 2). This
  replaces #623's original 250–350 m by 60–75 m. Its place is about 1 km east of town (the brief's
  proposal), not the picture's 3.5 km.
- **The railway already runs** (#552, call 1 A). DESIGN.md's day-30 arrival isn't used anywhere
  here. The mine is silver, bulk ore to a smelter (#552, call 3 B). The train has six cars (#552,
  call 2 A).
- **Harlan's commute:** the November 2 route is the baseline (no overpass). The November 7 comment
  (his daily ride crosses the overpass) is drawn as the alternative. The geometry rules it out
  together with the two-minute ride: see decision 1.
- **One physical correction.** Water flows downhill, and the creek passes south of town before it
  reaches the trestle north-east of town. So the creek flows **north** through the canyon. The
  canyon's shallow, passable southern end is therefore its **upstream** end. The brief's "more
  passable farther downstream" is read as "farther south". Everything DECIDED about the canyon
  still holds: deepest and narrowest at the trestle, carrying on south, widening and shallowing
  to a crossing, and not ending just past the bridge.
- **The town's depth:** the picture's notes say 300 m from rail to creek. Its drawing, measured at
  its own 250 m street, gives about 130 m. Period lot sizes give 186 m. Decision 3.

## 2. The frame and the envelope (PROPOSED)

- **The origin** is the new town's crossroads (Main Street × North–South Street) at ground level,
  Y = 0. X is east, Z is south, north is −Z. Main Street lies along z = 0, heading due west, so
  the sun sets straight down it (DECIDED).
- **The real altitude** is about 2,070 m above sea level (Durango is 1,988 m; the La Plata
  foothills run 2,050–2,300 m). Y is always relative to the crossroads.
- **The new valley is its own scene behind a switch** (Sean, #467). It can therefore reuse the old
  town's numbers. Everything stays within about 2.5 km of the origin, so float precision is fine.
- **The playable area** is 4.4 × 3.6 km (x −2000..2400, z −1400..2200): 15.8 km², the DECIDED
  "about 4 × 4". The town sits west of the middle, near the base of the western foothills
  (DECIDED). That leaves room east for the canyon, the trestle, the overpass and the widow, and
  south for the homesteads, the ranch and the mesas.
- **Boundaries are selective, not a wall** (each side's rule is in `valley.json`'s `envelope`):
  - **West:** the La Plata front steepens into slopes too steep to ride.
  - **North:** broken mesa country.
  - **East:** the creek leaves through a narrowing gorge, and the road and the rail run on toward
    Durango.
  - **South:** rimrock mesas, and the Baron's fence line.
- **Scenery beyond the edges:** the La Plata Mountains at 20–30 km from north-west to west, and
  the sunset notch, a low saddle due west of Main Street, kept clear of the rail.

## 3. The town (B, `valley-town.png`; lots in the tables)

**DECIDED, kept as the picture draws it:**
- Main Street east–west, with businesses on both sides and one principal crossing.
- The saloon on the crossing's north corner, the stone jail directly opposite.
- The depot, freight warehouse, rail yard and water tank north of Back Street, along the tracks.
- Homes south toward the creek, with the creek along the south edge.
- The church and cemetery on higher ground to the north-west.
- The picture's buildings, lanes and vacant lots, in its order and spacing.

**Measured:** the picture draws Main Street's 250 m frontage as 1,250 px, so 5 px is one metre
along the street: x = (px − 808) / 5, where 808 px is the North–South Street's middle. Each lot's
picture pixels are in the tables. Across the street (z), the picture is a bird's-eye view and
squeezed, so its rows keep their order and take period sizes (PROPOSED):
- Main Street is 20.1 m between the fronts: 66 ft, one surveyor's chain. The old street was
  16.8 m.
- Lots are 38.1 m deep (125 ft).
- Back Street and the rear lane are 6.1 m (20 ft).
- The North–South Street is 15.2 m (50 ft).
- The main line runs at z −74.5, with the passing siding and team track north of it.
- The creek runs at z +112. Rail to creek is 186 m (decision 3).
- The ground falls about 4 % from the rail bench (+2.8) to the creek bank (−4), and 1.5 m along
  the street eastward.

**The lanes and alleys** (Sean: keep the lanes the picture shows; the narrowest become the
1–1.5 m gameplay alleys):

| Where | Width as drawn | PROPOSED use |
|---|---|---|
| Lumber yard \| carpenter; carpenter \| hardware | 2.8 m, 2.4 m | walkable lanes to Back Street |
| Hardware \| store; bakery \| butcher | about 1.6 m (one px band) | shoulder to shoulder, a 0.3 m gap |
| Store \| bakery | about 1.6 m | **gameplay alley**, 1.2 m |
| Saloon \| hotel | 7.6 m | the saloon lane, wagon width, to Back Street |
| Hotel \| doctor | 3.6 m | lane |
| Doctor \| barber; barber \| undertaker | 1.2 m each | **gameplay alleys**. The undertaker's is blocked by junk you climb. |
| South side: blacksmith \| wagonwright | 7.2 m | the smith's yard lane |
| South side: wagonwright \| livery | 9.6 m | **vacant lot** (kept, a shed at its back) |

Climbable routes (PROPOSED for the greybox, not a continuous rooftop course):
- the saloon's outside stair and balcony;
- the hotel's gallery;
- low lean-to roofs over the north side's backs, between the doctor's and the undertaker's alleys;
- the livery's loft door.

**The story buildings** (PROPOSED; none moves a drawn building on Main Street except the two
houses for the bank and the land office):

| Building | PROPOSED place | Why there |
|---|---|---|
| Bank (brick) | South side, the first house lot east of the jail (x +42..+52) | On Main Street, opposite the hotel; its rear wall on the rear lane for the break-in. Alternative: the hotel's west end. |
| Land office | South side, the second house east of the jail (x +60..+69), as an office | Beside the bank: deeds and water rights in one block. Alternative: the depot (the railroad's land agent). |
| Telegraph | Inside the depot | Period practice: the station agent was the telegrapher. Alternative: a small office beside the depot on Back Street. |
| Assay office | South side, west end: the small building the picture draws there (x −110..−101) | On the West Road, where ore and miners come in. |
| The Baron's town house (masonry) | On a rise west of town above the creek bend, (−215, +75), about 4 m above the street's west end | Apart from the core, overlooking the creek, with its own drive off Main Street. |
| The second, cheap saloon (the "Railroad Saloon") | Between Back Street and the tracks, by the stock pens, (−42, −62) | Across the tracks from the respectable side: teamsters, railroad men, payday. |
| Post office, boarding house | Not reserved (not approved) | If wanted: the post office counter in the general store, rooms at the hotel. |

**The jail is stone** (DECIDED). The picture draws the office at x +7.6..+32.8 and the cell wing
at x +32.8..+38.4. The cell wing's back wall faces the rear lane: that wall is the jailbreak's
(masonry lab step 8, a bundle of about three sticks, #676). The masonry lab's rubble panel is
0.55 m thick, and that sets the walls' thickness in the greybox.

The old stock pens stand empty and weathered: horses only, so they serve as the teamsters' horse
corrals.

## 4. The railway (DECIDED order, PROPOSED geometry)

`valley.json` `railway.route` is a `TrainRoute` file (plan, profile, marks, crossings), laid out
by the tool with `TrackLine`'s maths. Train step 6 can load it as it stands. It runs east to west,
the brief's order, so distances count from the east entrance:

| Along (m) | Mark | Where | Rail Y | |
|---|---|---|---|---|
| 0–50 | east entrance | (2450, −344), a rock cut out to Durango | −2.5 | the train climbs westbound at 1.5 % |
| 550 | **Bridge B, the overpass** | (1912, −230), a cutting about 6.5 m deep through a low ridge | 5.7 | the road deck 5.45 m over the rail |
| 1229–1359 | **Bridge C, the great trestle** | middle (1183, −80); 900 m curve, 12° | 7.1 | 27.2 m over the creek |
| 2230–2720 | depot yard (level) | through the town's north edge at z −74.5 | 3.6 | passing siding and team track |
| 2416 | **Salt Creek Depot** | (61, −75) | 3.6 | |
| 2727–3930 | climbing west at 1.8 % | | | |
| 3930–4130 | **Ore Works** (level) | middle (−1542, −234) | 25.3 | the ore siding under the bins |
| 4130–4480 | 2.5 % up a deepening rock cut | | | |
| 4480 | **west portal** | (−1971, −360) | 34.0 | the tunnel: the line leaves the map 12° north of the sunset notch |

- **Limits held:**
  - sharpest curve 300 m radius (limit 120);
  - steepest grade 2.5 % (the ruling grade, the D&RG's Silverton branch figure);
  - the depot's and the Ore Works' tracks dead level;
  - no fill or cut over 3 m except the overpass cutting (6.9 m deepest) and the tunnel's approach
    cut. The tables list them.
- **The train between stops** (planned 22 km/h, `timetable.json`):
  - entrance to overpass: 1:22;
  - overpass to trestle: 1:51;
  - trestle to depot: 2:53;
  - depot to the Ore Works: 4:24.
- **The Runaway Payroll Train:** the westbound train passes under the overpass on the 1.5 %
  climb, at the planned 22 km/h or slower.
  - The deck stands 5.45 m over the rail: 1.1 m clear of the engine's stack.
  - A man dropping off the deck falls 2.0 m to the coach roof (the last car, so the first under
    him), 2.4 m to the boxcar's roof walk, or 3.8 m into an ore car.
  - From the overpass he has **679 m** to the trestle's east end: 1:51 at 22 km/h, 1:16 at
    32 km/h. That's enough to fight back over six cars (66 m) and still brake.
  - A full stop takes 54 m from 22 km/h, 109 m from 32 and 166 m from 40 (`brake_g` 0.042, 3 s
    to set). The engineer's service stop is longer.
  - Where the gang breaks the track is the mission's choice (the trestle's approach, or past it
    toward town). The physics decides, as #542 step 7 says.
- **No branch line** to the mine (DECIDED). The mine road carries ore down to the Ore Works'
  bins.

## 5. The great canyon and the trestle (C)

- **The canyon** is Salt Creek's own lower course. East of town the creek drops off the rail's
  bench toward the lower north-east basin and cuts down through it.
- **Its shape along the creek** (natural ground over the bed, from the generated table):

  | Place | Depth | Rim to rim |
  |---|---|---|
  | Head, by Bridge A | 2–4 m | 44 m |
  | Half way | about 19 m | |
  | The trestle | 26 m | 130 m: the bridge spans rim to rim, its abutments on the bench at Y +6.1 under a rail at +7.1 |
  | 170 m north | 24.5 m | |
  | The mouth, 340 m north | 16 m | 170 m, opening onto the widow's bottomland |

- **Narrowest at the trestle:** above it the canyon is shallower but no narrower. Below it, it
  opens.
- **Its length:** about 520 m from the head to the trestle, and 340 m on to the mouth.
- **The creek is small** (DECIDED): 2–4 m wide and ankle to knee deep at low water, in a gravel
  floor 28 m wide under the trestle. The trestle lab's gorge has an 18 m river: narrowing it is a
  dial in the lab's `gorge.gd`, for Phase 2 (the bridge isn't touched).
- **Where the whole bridge can be seen**, bents and all (lines of sight over the ground, in the
  tables):

  | Viewpoint | Distance | What it sees |
  |---|---|---|
  | **The trestle overlook**, on the canyon's west rim up-canyon, 140 m off the East Road | 267 m | all of it: **the finale's vantage point** |
  | The east rim north of the bridge | 241 m | 85 % |
  | Bridge A, looking down the canyon (on the everyday road) | 425 m | 65 % |
  | The canyon floor | | all |
  | The canyon mouth below the widow's | | all |

- **From town it's the deck and the train on it.** The depot, Main Street's east end, the saloon
  balcony, the cemetery hill and Harlan's door all see the train cross on a high, level line 1.1
  to 1.3 km off, with its smoke and whistle. The bents stand inside the canyon, below the bench
  the town stands on, so no point in town sees them. Seeing them from Main Street would mean
  turning the canyon to open toward town (running south-west to the town's east end, not south),
  or a town much higher than the bench. Decision 2 asks.

## 6. The east: the widow, the East Road, Bridges A and B

All DECIDED as a system (PR #621). PROPOSED in metres:

**The East Road (3.0 km to the eastern exit; wagon road; steepest 8.1 %):**
1. Leaves Main Street's east end along the creek's north bank.
2. At about 1 km reaches **Bridge A** at the canyon's head (965, 288): two 8 m timber stringer
   spans on a log crib over a creek 3.7 m below the natural banks. A modest county bridge from
   before the railroad.
3. Climbs the east rim on a 2 % grade.
4. Passes 140 m from the trestle overlook.
5. Runs north-east across the bench and over **Bridge B** (1912, −230): a 14 m timber bridge over
   the railway's cutting. The old through-road, cut beneath when the line came (DECIDED).
6. Descends north at 5–8 % to **the widow's lane** at 2.6 km.
7. Goes on east along the creek to the exit toward Durango.

**The widow's homestead (1712, −560), Y −10:**
- **North of the railway**, 330 m below it, on a knoll, its front to the lane (south).
- **Her creek frontage:** fields and garden on the bottomland down to Salt Creek 130 m north. Her
  water right is a ditch heading at the canyon mouth: the only irrigable bottomland in the east,
  which is why the Baron wants it.
- **Clean water:** the mine's arroyo joins the creek 707 m below her fields, never above.
- **Ways in for Phase A:**
  - the front, from the lane;
  - the rear, up from the creek and the canyon mouth;
  - the side, from the overpass road's descent;
  - from above: the rail bench and the overpass look down on the yard, which is where the peaceful
    visit lets Harlan study the place.
- **Room:** the house and the farmhouse mission's existing hills (knoll, west rise and draw, east
  hill, the ridge behind) fit in a 34 × 30 m pad plus the yard. The outbuildings and the Phase B
  hold sit north-east toward the creek.

**From town:** 1.8 km in a straight line, **2.6 km by road**.

| Pace | Time |
|---|---|
| Canter | 7:56 |
| Trot | 11:12 |
| On foot (2.8 m/s) | 15:36 |

That's closer than the picture's 3.5 km. The detour round the canyon is what the canyon costs,
and it's DECIDED.

**The opening's encounter site** (PROPOSED, (530, 128)) is on the East Road, the sheriff's road
from home to the doctor's, 420 m from Main Street's east end, where Harlan's ford path meets it.
Harlan's dawn ride by the ford (a horse track from his place, the creek at a gravel ford) brings
him onto the East Road there. From there he can bring the sheriff about 480 m to the doctor's. Who shot
the sheriff, and where, stays OPEN (PR #621).

**The Baron's Shipment:** the ranch has two ways out:
- the South Road through town, past Harlan's;
- its own canyon road north to the East Road at Bridge A, and on east (to the overpass and the
  widow's) without touching town.

Either gives interception ground: the draw on the South Road, Bridge A, the canyon rim, the
overpass cutting and the descent to the widow's. The ambush itself is OPEN and not chosen here.

## 7. The south: Harlan, the Baron, the Southern Ute community, the hideout

- **Harlan's homestead** (432, 470), Y +2 (DECIDED south-east, about two minutes):
  - On the slope south of the creek: cabin, small barn and shelter, fencing, a garden, the work
    area.
  - **His spring** (480, 420) is on the slope above, its run going down to the creek (kept;
    decision 4).
  - **His daily ride:** his lane west along the south bank to the town bridge, up the
    North–South Street: **692 m, 2:06 at a canter, 2:57 at a trot**, no overpass (November 2
    baseline).
  - His ford path is his way east without going through town.
- **The town bridge** (0, +116) is the picture's own, a 14 m timber wagon bridge. It isn't one of
  the three named bridges, and is never called A.
- **The Baron's ranch** (1320, 1260), Y +20, on the open south-east grazing upland (DECIDED):
  - 2.0 km by the South Road: **6:03** at a canter.
  - A 120 × 90 m headquarters: the painted house, bunkhouse, barns, horse corrals, a windpump and
    tanks.
  - A draw to the west and a low ridge to the east for covert approaches (and horse theft).
  - **Horses only:** the herds are off the map (decision 5). Inside the valley his wealth shows in
    fences, brands on the tack and freight, the tanks, the hands and the shipments.
- **The Southern Ute community** (−1350, 1230), Y +41 (DECIDED, south-west):
  - On a sheltered bench by the creek's upper reach, above everything that could foul the water,
    with a spring (−1420, 1180), cottonwoods and juniper.
  - 1.9 km by the trail: **5:41** at a canter.
  - Only the footprint is reserved. **How it looks is research done with care** (DESIGN.md §5
    "History, handled with care"), not this plan's to draw. In 1882 the Southern Utes (Mouache,
    Capote, Weeminuche bands) lived on and off the reservation strip along the New Mexico line,
    south of Durango.
  - Dwellings of the time ranged from canvas lodges and brush shelters to shade arbours and, near
    the agency, cabins. Which fits a settled family community here is for that research and Sean,
    and never a generic Plains camp (the brief's rule).
- **The outlaw hideout** (OPEN; PROPOSED (−450, 2020), Y +86):
  - A line shack in a box canyon under the southern rimrock.
  - The front way: a 1.7 km horse track up a dry wash off the South Road.
  - The unseen way: a foot path along the mesa top from the Ute trail, ending above the shack.

## 8. The west: the West Road, the Ore Works, the mine, the timber camp

- **The West Road** (1.4 km; steepest 9.7 % for 40 m):
  - Leaves Main Street's west end on its axis for 175 m, so the street's sunset stays open.
  - Then bends west-north-west along the rail.
  - Crosses the main line at grade and reaches **the Ore Works**: **4:48** at a canter, 1.59 km
    by road (the DECIDED "about 1.5 km").
- **The Ore Works** (PROPOSED layout): a yard 200 × 70 m north of the track.
  - Ore bins built into the slope over the ore siding, where mine wagons tip in from above.
  - A sampling and crushing house, sheds, timber stores and a wagon yard.
  - Tailings and wash water go to the arroyo just north, never to the creek.
- **The mine** (−1720, −790), Y +79: a timbered adit on a foothill bench 55 m over the Ore Works.
  - The powder magazine is set apart up the gulch, the waste dumps go down toward the arroyo, and
    there's a shop and a bunkhouse.
  - **The mine road** (1.2 km) goes over the arroyo on a log-cribbed fill and up two long legs at
    5–7 % (one 5 m pitch at 10.6 %): 2.8 km from town, **8:21** at a canter, 83 m of climbing.
  - Room for the Buried Alive rescue: the adit, the slope over it, the dumps, the yard.
- **The timber camp** (−1150, −1150), Y +61 (PROPOSED: north-west foothills):
  - A modest pine stand on north-facing slopes. The pines start about 40 m above town, never on
    the valley floor.
  - A saw pit and a small horse sawmill.
  - The timber road (1.5 km, 9.9 % steepest) fords the arroyo and crosses the tracks at grade
    west of the depot, delivering to the lumber yard by Back Street: **5:09** at a canter.
- **The western exit:** the line climbs at 2.5 % into a deepening rock cut and a tunnel at
  (−1971, −360), bearing 12° north of Main Street's sunset notch, so the notch stays clear.

## 9. The water (all checked downhill)

**Salt Creek** (5.6 km on the map) falls from +55 at the south-west edge to −30 at the north-east.
Its gradient by reach:

| Reach | Gradient |
|---|---|
| Foothills | 2.3–3 % |
| Past town and on to the canyon's head | 0.6–0.7 % |
| Through the canyon | 1.3–1.6 % (the knickpoint) |
| Out across the basin | 0.5–0.7 % |

Every vertex is lower than the last, and the banks stand at least 1.3 m all along (median 5.1 m).

It comes past the Ute community first, then the **town ditch's head** (−620, 540): a period water
ditch that brings clean water along the slope to a cistern behind the jail, the town's supply and
the bucket line's source. Then the town's south edge, Bridge A, the canyon, the widow's fields,
and out north-east.

**The dry arroyo:**
- Rises in the foothills under the mine.
- Takes the mine's and the Ore Works' drainage.
- Runs east 300 m north of town (2–5 m cut banks, sand and cobble, dry except after a storm),
  crossing the lower basin.
- Joins Salt Creek **707 m below the widow's fields**, level with it at −29 m.

So the mine's drainage never reaches the town's water or hers (valley.md DECIDED). The rail never
crosses it: no fourth bridge is needed.

## 10. The missions against the map

| Mission | What the geography gives it |
|---|---|
| Opening: the wounded sheriff | Harlan's dawn ride by his ford path joins the East Road 420 m from town; the sheriff on his road from home to the doctor's; about 480 m to the doctor. Seen again later as the road to the widow's. |
| Farmhouse rescue (A and B) | Front, rear (the creek, the canyon mouth), side, and the overlook from the bench; the peaceful visit by the same road; the yard to the north-east for Phase B. |
| Buried Alive | The mine on its bench, the yard and dumps, the mine road from the Ore Works (an everyday place on the train's run). |
| The Baron's Shipment | Two routes off the ranch, five candidate interception points, none chosen (OPEN). |
| Runaway Payroll Train | The overpass on the climb, 679 m to the trestle, a known stopping distance; the overpass is first met as the widow's road. |
| The trestle finale | The overlook and the east rim see the whole bridge; the canyon floor from Bridge A or the mouth to reach the bents; the train seen every day from town and the East Road. |
| Jailbreak, bank | Both back walls on the rear lane, the lane reached by the vacant lot and the lanes. |
| Joe and the rope (the rifle overlook, 100–150 m, #546) | Not placed: reserved as OPEN. The creek's cottonwoods below the Baron's rise, or the canyon rims, give that distance. |

Everyday reuse:
- The East Road, Bridge A and the trestle's view come with every visit to the widow's.
- The Ore Works comes with every train-watching day.
- Harlan's ride passes the town bridge daily.

## 11. The ground: what it takes, and what can't be (E)

- **Levels:**

  | Place | Y |
  |---|---|
  | Main Street | 0 (+0.75 at its west end, −0.8 at its east end) |
  | The rail bench | +3 to +7 |
  | The creek in town | −6.3 (banks −4) |
  | The trestle's rims | +6.1; its floor −20.1 |
  | The widow's | −10 |
  | The lower basin | −15 to −25 |
  | The Ore Works | +24 |
  | The mine | +79 |
  | The timber camp | +61 |
  | The Ute bench | +41 |
  | The south-east upland | +12 to +30 |
  | The western edge | +65 to +150 |

- **Earthworks needed** (the tables have the list):
  - the overpass cutting (about 6.5 m at the bridge, 6.9 m deepest);
  - the tunnel's approach cut (to 26 m at the portal);
  - a 3.6 m cut at the depot yard's west end;
  - the mine road's crib fill;
  - level pads for each place: the town plane is about 3 m under the natural slope at its north
    edge, a terrace cut back into the bench;
  - the depot's platform fill;
  - retaining cribs where the town's north lots meet the bench.
- **Roads:**
  - every wagon road keeps to 10 % except the mine road's one 5 m pitch;
  - the Baron's drive has a 16 m pitch onto its rise;
  - the horse tracks stay under 15 %.
- **Impossibilities found and not hidden:**
  1. The canyon's passable end must be upstream (above).
  2. The picture's 300 m town depth doesn't match its own drawing (decision 3).
  3. Harlan's two-minute ride and a daily overpass crossing can't both be true while the overpass
     is east of the trestle (decision 1).
  4. The trestle's bents can't be seen from town while the canyon runs south below the bench
     (decision 2).
  5. The picture's 3.5 km to the trestle and to the widow's doesn't fit a 4 km valley with the
     town near its western foothills.
  6. The picture's saloon is drawn about 27 m long, but the built spec saloon is 15.2 m: the lot's
     east part is its yard (or an annex: OPEN).

## 12. Migration plan (G): the new valley beside the old town

**What exists today:**
- The old town: `config/town.json` is about 109 m of Main Street (x −80..29) with the hills and
  the farmhouse at (102, −46).
- The labs:
  - the train lab's test line runs south of the old town;
  - the trestle lab's gorge line is at x 2,600;
  - the spec saloon sits in the desert;
  - the masonry panel.
- The ground is slabs out to 2 km, with dug tiles.
- Nothing knows about a valley. The town's places, routes, tests, goldens and the dev bridge's
  places all live on the old street.

**The rule (Sean, #467):** the new valley is built beside the old town, behind a switch, as the
real look was. The old town keeps working, with its labs, missions and tests, until the new one is
better. Then the switch flips and old saves reset.

**The order** (each step one session, merged on its own green "Test and build", stopping for Sean
as usual):

| Step | What | Depends on | Gate (regressions it must not cause) |
|---|---|---|---|
| G0 | **Sean approves this plan.** `valley.json` becomes the source; his answers are written in. | This issue | – |
| G1 | **The switch and an empty valley scene.** `Settings.world` = `town` (default) or `valley`, `--world=valley`, the bridge's `world`; a `ValleyLayout` that reads `valley.json`. Nothing else uses it. | G0 | The whole suite unchanged with the switch off; the goldens unchanged; a smoke test boots both. |
| G2 | **The ground.** This tool bakes the height field (the same function) to a 16-bit height map at 2 m; a chunked height-map ground (Godot's `HeightMapShape3D` per chunk, a mesh per chunk with distance LOD). The town plane, pads, cuts and channels come from the bake. Our own chunking or a licensed addon is Sean's call (CLAUDE.md: a licence in `CREDITS.md`, ask first). The dig-able `Ground` tiles keep working over the bake. | G1 | The frame budget on the calm street (render CPU ≤ 4 ms at Sean's) and the soak; `Ground.height_at` the bake's within 1 cm; dig tests on both worlds. |
| G3 | **The rail corridor:** step 6 lays `railway.route` with `TrainRoute`/`TrackLine` as they are; the trestle lab's `Trestle` at the `great_trestle` crossing; the overpass cutting and Bridge B; the tunnel portal. The daily timetable on the real line. | G2, #542 step 6 | Every train test on the lab line and the valley line (`test_line.json` and the new route: #542's re-laid-line test is already that check); the trestle lab's films and frame table re-run on the valley's canyon; the 1D train far off costs nothing. |
| G4 | **Greybox markers:** every place's pad and a block for each building volume; roads as graded strips; bridges A, B and the town bridge as greybox members; fords. | G2 | Bridge `goto` to every place works; travel times measured on foot and (when it rides) on the horse against the tables; nothing above the frame budget. |
| G5 | **The town greybox** (Phase 3): the lots at true size, the lanes and alleys walkable, the boardwalks, Back Street. Then the buildings move over one at a time, each through the building lab from its spec: the saloon first (its spec unchanged, placed on its lot), then the jail with the masonry lab, then the rest. The old town's buildings stay where they are. | G4, #695 | Per building: its tests on both worlds; the gang's day, townsfolk's posts and routes on the new streets (Waypoints from `valley.json`'s town); the sunset down the street (a golden); the gunfight lab's saloon setups re-pointed or kept on the old town until moved. |
| G6 | **The farmhouse moves** to the widow's pad: its spec unchanged, its hills carried relative to it, `FarmhouseMission` places from the spec. PR #621's widow changes land on top. | G4 | The farm bot's runs (wins, ways in, the rancher or widow alive) the same within noise on the new site. |
| G7 | **Outlying places** (Phase 4, when scheduled): the Ore Works, mine, ranch, widow, Harlan's, by the existing building pipeline; horse travel, the creek crossing, the overpass boarding, the trestle approaches. | G5, G6, the horse ridden (#341, #478) | Mission runs per place; the frame budget at each place. |
| G8 | **The switch flips** when Sean says the new valley is better: `town.json` and the old street retire, old saves reset, the goldens re-approved. | Sean | The whole suite on the valley; the nightly visual checks; a playtest. |

**Kept everywhere:** every system; the characters and anatomy; the saloon spec; the farmhouse
spec; the props; the train, trestle, masonry, breakage and gunfight labs (each keeps its own scene
or the old town until it moves); the dev bridge and tools; every test (a test that names old-town
places keeps running on the old town until its subject moves).

**Risks to watch:**
- The ground at 4.4 km is the first real performance question (G2).
- Waypoints and routes are hand-placed today and need generating from `valley.json`.
- The goldens all live on the old street.
- Lab coordinates collide only if the two worlds ever load together. They mustn't, which is the
  switch's job.

## Decisions (H): only what's Sean's

`docs/concept/valley-decisions.png` draws the first three.

1. **Harlan's daily ride: A (Nov 2 baseline, recommended) or B (Nov 7).**
   - **A:** he rides his lane over the town bridge, 692 m and 2:06 at a canter. He crosses the
     overpass only on the early missions (the widow's road). The opening finds the sheriff where
     his ford path meets the East Road.
   - **B:** his ride crosses the overpass every day. The overpass must stay east of the trestle
     (hard rule), so his house moves near it, north of the rail: 2.3 km and 6:52 at a canter. The
     two-minute ride is lost.
   - No layout gives both. Pick A, B, or say which rule bends.
2. **The trestle's place: as drawn, 1.18 km east of the crossroads (recommended), or another.**
   - It sits 1.05 km past Main Street's east end, 1.12 km of track from the depot, and 679 m west
     of the overpass. The tables give the train's times and stops.
   - From town you see the deck and the train crossing every day. The whole bridge shows from the
     overlook, Bridge A, the east rim, the canyon floor and the mouth.
   - If the bents must be seen from Main Street, the canyon has to run south-west toward town's
     east end instead of south: say so and it's redrawn.
3. **The town's depth, rail to creek: 186 m (recommended), or 300 m as the picture's notes say?**
   - 186 m keeps the picture's rows with period lots: depot, Back Street, 38 m lots, a 20 m Main
     Street, the rear lane, one row of houses and gardens, the creek bank.
   - 300 m would add a second residential street and a wider creek-side.
   - The picture's own drawing is about 130 m.
4. **The water story: Harlan's spring and the widow's water rights.** PROPOSED (the brief's):
   - Harlan keeps a small spring for his homestead (placed, kept).
   - The widow holds the valuable right: the creek frontage and the bottomland ditch at the canyon
     mouth.
   - The Baron wants both, but hers is the immediate reason for the murder. Yes, or another split?
5. **The Baron's herds: off the map** (PROPOSED). He stays a cattle baron. His range and herds lie
   beyond the south-east fence, and inside the valley his wealth shows in the ranch, the tanks,
   brands, freight and his men. Yes or no?
6. **Places still PROPOSED** (a yes to each, or move it):
   - the timber camp in the north-west pines;
   - the hideout in the south rimrock (OPEN in the brief);
   - the Baron's town house on the rise west of town;
   - the bank and land office on the two house lots east of the jail;
   - the second saloon across the tracks;
   - the telegraph in the depot;
   - the assay office at the west end;
   - the saloon lot's east part as yard (or an annex: the picture draws the saloon about 27 m long,
     the spec is 15.2 m).

## What was read (so the next session can skip it)

- #467 and its seven comments.
- PR #621's three briefs.
- DESIGN.md: the index, §1, §3, §5 (premise, cast, story flow, missions).
- `docs/TOWN.md`, `docs/ROADMAP.md` (grep), the town, main-street, train and trestle briefs.
- `config/town.json`.
- `src/train/train_route.gd`, `track_line.gd`, `train_cars.gd`, `train_tuning.gd`.
- `experiments/train_lab/routes/` and `timetable.json`, `experiments/trestle_lab/routes/gorge.json`.
- `experiments/building_lab/saloon.json`'s lot.
- The player's movement tuning.
- Issues #542, #552, #546, #623, #663, #676, #466.
- LAYOUT "src/missions".
