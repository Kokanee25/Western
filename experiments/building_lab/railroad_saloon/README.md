# The Railroad Saloon: THE SILVER SPIKE (#1285; design only, the build after the slice)

Sean, 2026-11-26 (#1097): Payday Night's floor falls here, not in saloon B, and the dance floor is **upstairs**, so the
dancers come down onto the drinkers. Small, rough and cramped on purpose, with 25-40 packed upstairs on payday.

**Sean's picks** (this session's chat, 2026-11-26):
- Raw board-and-batten, the gable to Back Street (no false front).
- A short built bar with barrels on racks behind it.
- One outside stair up the side.
- The piano carried up the stair for the dance (S24), the band upstairs, and the piano comes down with the floor.
- The name **THE SILVER SPIKE**.
- 24 x 30 ft on the 12 x 9 m lot.

**Files:**
- `sheet/`: the target sheet, ten views, $1.41, the look only. The west-side view invents a taller back wing (none
  in the spec), and the plan draws the stair inside (the spec has it outside).
- `make_spec.py` writes `config/buildings/railroad_saloon.json`. Re-run it; never edit the JSON by hand.
- `collapse_sheet.py` draws `plan/collapse.png` (the upstairs, the long section and the cross-section).
- `tools/buildings/plan_sheet.py` draws `plan/ground.png`. Its walk and street labels are Main Street's
  defaults; this building stands on Back Street with no walk.

**Read for this:** RECIPE "Before step 1", "Step 1", "Step 2", "A two-storey building under trusses", "A big
two-storey hotel"; FORMAT "The parts"; `saloon_b.json` (sabotage, outside stair, landing, dust);
`doctor.json` (gable front, rafters); the story's Payday Night (docs/story/MISSIONS.md).

## On the lot

- **The lot:** valley.json `second_saloon` (x -48..-36, z -66.5..-57.5). The building stands on the lot's west half
  (x -39.5 to -46.8).
- **Back wall:** on the lot's back line. 30 ft runs 0.14 m into the 3.25 m verge before Back Street.
- **The stair:** on the lot's west edge (out to x -47.88).
- **The east yard:** 3.5 m for the empty kegs, the privy and the way round to the pens.
- **The ground:** probed through the valley plan's terrain (Python). It rises 0.66 m from front to back (world 2.18 to
  2.84) and falls 0.06 m from west to east. It needs a pad dug level at the front's ground (2.17), running 1.5 m on
  behind the back wall so the back door opens two steps down onto it, with the cut bank behind. The build adds the
  lot's `spec` and `pad` to valley.json and re-bakes.

## The building

- **Plan:** 24 x 30 ft, a plain rectangle, balloon-framed, rough-sawn full sizes, ponderosa pine.
- **Bar room:** one room, floor 0.375 m over the pad (one plank step). 7 ft 6 in clear under the girder, 8 ft 6 in to
  the joists, no ceiling.
  - **The bar:** one 10 ft built section down the east wall, right under the middle bay.
  - **Behind it:** barrels on a rack against the wall (#1222's rotgut: Lowry Bros. XXX, Brandauer's, South Platte).
  - **The stove:** at the front, forward of the fall.
  - **Tables:** west of the girder, spittoons, sawdust.
- **Upstairs:** the dance floor at 3.245 m, the whole building's size (7.1 x 8.9 m), 4 ft walls to the plate.
  - **The roof:** 10/12, open to its rafters, a collar on every pair 8 ft over the floor; the lamps hang from them.
  - **Round the walls:** benches.
  - **The piano:** against the back wall, with the band (4) beside it.
  - **The door:** in the back gable over the back door, off the landing (#1286: a 6 ft 6 in door won't go in a 4 ft
    knee wall, so it moved from the west side to the gable).
- **The outside stair:** up the west wall from z 5.1, past the back corner, to a landing behind the back wall (three
  beams on posts, the joists along the wall; it roofs the back door). 17 risers of 7.5 in, 10 in
  treads, 3 ft 6 in wide, a pole rail. It is the only way up.
- **No upstairs posts.** The sheet paints posts carrying the roof. The spec hangs the lamps from the collars over
  the girder's posts instead: a post on the dance floor would put the roof on the girder that's sawn.

## The collapse, designed in

**The frame** (Wood Handbook, FPL-GTR-282, Table 5-3a, ponderosa pine; knotty rough timber breaks at about 4,500 psi
in bending; the period books allowed about 1,000 psi):
- **Joists:** 2x10 at 16 in across the building, side wall's ribbon to the girder, a clear span of 11 ft 8 in. About
  660 psi at a dance load.
- **The girder:** one 6x12 down the middle on two 6x6 posts at 10 and 20 ft, in three bays of 10 ft, jointed over
  the posts. It carries 12 ft of floor.
  - At Hatfield's 70 lb/ft² dance load it works at **950 psi**, right at the book's limit: a cheap man's size
    that still holds.
  - The middle bay is over the bar, and that is the one sawn.

**The loads on the middle bay:**
- The floor's own weight: 6 lb/ft².
- An ordinary night (15 upstairs, one reel set stamping at 1.5x): 5.4 lb/ft² live.
- **Payday packed** (40 upstairs, about 28 dancing in the middle 36 m², a reel in step at 1.8x): **21.5 lb/ft²** live.

**The girder's moment against its strength (lb-in):**

| The night | Moment | Whole 6x12 (648,000) | Sawn 9 of 12 in, 3 in left (40,500) |
| --- | --- | --- | --- |
| quiet (dead only) | 10,800 | 60x | **3.75x: holds the afternoon** |
| ordinary night | 20,600 | 31x | **2.0x: holds** |
| payday, packed reel | 49,500 | **13x: never falls whole** | **0.82x: breaks** |

**The cut:**
- **When and how:** sawn that morning from below with a ladder in the empty bar, 9 of its 12 in. A lamp held up
  from the bar finds the pale kerf (S23's tell).
- **What holds it:** the 3 in left holds the quiet afternoon at nearly 4x and an ordinary night at 2x.
- **What breaks it:** the payday reel stamping in step over the middle bay.
- **In the game:** the event cuts it through at its time (`sabotage`: `beam/spine/1`, a kerf by `cut_member`). The
  numbers are the story's truth and the bench's yardstick, not a simulation of the saw.

**What falls:**
- The middle bay's floor: 10 ft by the whole width, **21.6 m², about 12 dancers** (the middle reel set) and whoever
  is at the bench ends there.
- Both halves of each joist hinge down on the side walls' ribbons, **2.9 m (9.4 ft)**: the east half onto the bar,
  the west half onto the tables.
- The front and back bays hold on their posts: the band, the piano and the far benches stay up at the hole's edge.
- **Laid out for it** (RECIPE "A collapse on purpose needs room to fall"):
  - The dance floor is three floors, a bay each, so the boards stop at the bay lines.
  - The joists are cut 12 mm short (`end_gap`).
  - No brackets under the girder.
  - The bar room's wall boards stop under the ribbon (`to_y`).

**Who's under it:**
- The barman behind the bar.
- Four at the bar (the Kid among them, if he lived the farmhouse).
- Four at the two tables west of the girder.
- The standing drinkers at the front and back are outside the bay.

**The crowd:** 40 upstairs (about 28 dancing, about 8 on the benches, 4 in the band) and about 15 below.
`use_points` mark the places: `bar_*`, `barman`, `table_*`, `edge_*`, `band_*` and `reel_*` (the middle set).

**The ways out:**
- **Upstairs:**
  - The one 2 ft 8 in door onto the landing, then the 3 ft 6 in stair. **The jam**: about one person a second through
    the door at best, so 25 people take half a minute or more, and the stair's rail and treads are loaded with a
    crush.
  - Five small windows (2 x 2.5 ft): a man can squeeze out and hang and drop 3.2 m to the pad.
  - The hole itself.
- **Below:**
  - The front door (3 ft 6 in) to Back Street.
  - The back door to the pens.
  - Four small windows.
  - The fallen floor blocks the bar's side, and the stove stands at the front by the door.

## Builder parts it needs, shared with the hotel and saloon B (docs/PARTS.md)

All in the game, unless marked as needed:
- **Walls and floors from a spec:** balloon walls with the tall studs, ribbons, floors with `breaks`, `end_gap`,
  `board_length`; three floors a bay.
- **Posts and beams cut over each post.**
- **`sabotage` and `cut_member`** (saloon B, #772).
- **A stair as a part:** the outside stair with its rail and posts, like saloon B's.
- **The landing:** saloon B's balcony a bay.
- **Rafters and collars, and the gable sign:** the doctor's.
- **FloorDust:** the middle floor.
- **The pad and the valley's lot `spec`.**
- **Kit props:** `bar`, `keg_rack`, `wall_bench`, `upright_piano`, `piano_stool`, `box_stove`, `spittoon`, `table`,
  `reflector_lamp`, `hanging_lamp`, and the casks and bottles of #1222.
- **To check or add (NEW):**
  - A kit lamp on a post (`lamps.kit` `post`) and one hung from a collar (`hang` [x, z]; the church hangs from a
    truss).
  - The outside siding's battens (`battens`).
  - The pad's `behind`.
  - The sabotage's `from_below` as a mark drawn before the event: the pale kerf a lamp finds.

## The crowd bench (before Payday Night is built; Sean on #1097)

Forty people upstairs at night, fifteen below, then the cut. Measure on the built saloon in the valley:

1. **The frame whole:**
   - `Checks.stands`, and the game's settle on the built saloon with 40 HumanBodies stamping (a reel's step load):
     nothing breaks or sags past its limit.
   - The same with the girder cut to its last 3 in, if the members can take a reduced section; else the full cut
     only.
2. **The fall:**
   - Seconds from the cut to the floor on the bar.
   - The area down (the `rubble` group's bodies, not broken members): it must be the middle bay only, with the front
     and back bays standing.
   - Whether pieces jam.
3. **The people** (across 10 seeds):
   - How many fall, how many are struck below, wounds by kind and the dead (the physiology decides, never placed).
   - Harlan at the bar's end and on the dance floor: hurt, and not normally killed.
4. **The jam:**
   - Seconds for the upstairs survivors to get out the one door and down the stair.
   - The most on the stair at once and whether it holds.
   - How many go by the windows.
5. **The cost:**
   - People ms with 55 in the building plus the town's 24 (budget 4.0).
   - Physics ms at the fall (ragdolls plus rubble; budget 2.0) and the worst frame.
   - Jolt bodies against the valley's cap (saloon B's note: the valley is near 32,768).
   - Memory against the valley's 4,096 MB.

## Open

- **Sean's OK on the sheet:** asked in the chat with no answer; asked again on #1285.
- **The story to update** (the story's docs, not this lane's):
  - The band now plays here on Payday Night, upstairs with the piano carried up (MISSIONS.md beat 7 has saloon B's
    stage; band.json's Payday entry places them there).
  - The open question "which saloon" is settled (#1097).
- **Where the men saw from:** a cut from below (the bottom is in tension, so it is the cut that weakens the girder,
  and it is S23's pale kerf a lamp finds) means the bar room, entered by the back door while it's shut. The story's
  beat 4 has them go up the outside stair, but there is no stair inside, so from upstairs they would lift two boards
  over the girder and saw from the top. That cut is in compression and closes under load, so it would need to go
  deeper, and its tell is a sag and sawdust on the bar. The story picks; the frame works either way.
- **Saloon B's `sabotage` is superseded:** its girder is no longer the one sawn. Leave it until Payday Night is built
  here.
