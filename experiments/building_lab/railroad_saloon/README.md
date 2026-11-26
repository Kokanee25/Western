# The Railroad Saloon: THE SILVER SPIKE (#1285 the design, #1286 the build)

Sean, 2026-11-26 (#1097): Payday Night's floor falls here, not in saloon B, and the dance floor is **upstairs**, so the
dancers come down onto the drinkers. Small, rough and cramped on purpose, with 25-40 packed upstairs on payday.

**Sean's picks** (this session's chat, 2026-11-26):
- Raw board-and-batten, the gable to Back Street (no false front).
- A short built bar with barrels on racks behind it.
- One outside stair up the side.
- The piano carried up the stair for the dance (S24), the band upstairs, and the piano comes down with the floor.
- The name **THE SILVER SPIKE**.
- 24 x 30 ft on the 12 x 9 m lot.

**Built** (#1286, Sean 2026-11-26 "Okay build it", the sheet approved): from its spec in the lab and on its lot in
the valley; `tests/test_building_railroad_saloon.gd` (built and destructible, 1,499 members; stands, nothing over its
limit with a crowd; built right; people fit; whole it carries 70 lb/ft2, sawn the middle bay comes down on the bar).

**Files:**
- `render_lab.gd`: the lab renders (front, rear, bar, upstairs) in the game's street, facing south as on its lot.
- `crowd_bench.gd` (`crowd_runner.gd`): the crowd bench, below.
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

## The look, judge round 1 (`results/2026-11-26_r1`, the blind cheap judge)

All four views were rated cheap indie.
- **The setting, not the building:** the front's backdrop is the lab street's flat cliff card, and the rear's sand
  has repeated green rocks. It needs rendering on its lot in the valley, which wants a bigger box than this one.
- **The bar room and the dance floor are empty:** dressing them is the prop lab's job (#1222's casks and bottles,
  glasses, sawdust, coats on pegs).
- **The building's own faults:**
  - Light under the near table where its shadow should be.
  - Pinpoints of sky through the dance floor's square-edged boards and the roof upstairs.
  - The dark raw boards on a bright sand plain with no contact shadow.

One round used; a second waits for the dressing.

## Builder parts it uses (docs/PARTS.md)

All shared with the hotel, saloon B and the doctor's:
- **Walls and floors from a spec:** balloon walls with tall studs on the side walls, ribbons, floors with `breaks`
  and `end_gap`; the dance floor as three floors, a bay each.
- **Posts and beams cut over each post;** `sabotage` and `cut_member` (saloon B, #772).
- **A stair as a part:** the outside stair with its rail and posts, like saloon B's.
- **The landing:** a balcony of three beams across it on posts, its joists along the wall.
- **Rafters and collars, the gable sign:** the doctor's.
- **FloorDust** under the middle floor; **the pad** and the valley's lot `spec`.
- **Kit props:** `bar`, `keg_rack`, `wall_bench`, `upright_piano`, `piano_stool`, `box_stove`, `spittoon`, `table`,
  `reflector_lamp`, `hanging_lamp`.

**Added by #1286:**
- `spec_building.gd`: an upper floor more than 0.3 m under the plates is a storey with knee walls, not a loft, so
  the rafters take their own spacing. They had followed only the first upper floor's joists, leaving two bays bare.
- `spec_building.gd`: a gable sign on board-and-batten sits on the battens' face, in their band (it hung on nothing).
- `lab.gd`: `lot.walk: false` lays no boardwalk.
- The valley builds a spec on a town extra (`valley_world.gd`, `valley_markers.gd`, the bake's pads in
  `valley_plan.py`): gameplay's files, a line each.

**Not done:**
- The barrels and bottles of #1222 on the racks (the prop lab's).
- The pale kerf drawn before the event (S23's tell).
- A lamp on a post: the bar room's lamps are on the walls.

## The crowd bench (#1286; Sean on #1097)

`godot --headless --fixed-fps 60 -s res://experiments/building_lab/railroad_saloon/crowd_bench.gd -- --seeds=10`
writes `build/railroad_saloon_crowd/crowd.json`.

**The setup:**
- The Silver Spike in the building lab: 40 HumanBodies upstairs (the middle reel set on its points, the rest
  dancing round them, on the benches and in the band) and 15 below (at the bar, behind it, at the tables, standing).
- Each man's weight is on the board under him: 75 kg, at 1.8x upstairs for a reel stamping in step.
- Then the cut and 8 s of the fall; each man's physiology is run on ten minutes after.

**Ten seeds, 2026-11-26** (this workspace's 2.1 GHz core; x0.65 for Sean's):

| | Result |
| --- | --- |
| Whole, with all 55 in | nothing gives in any seed |
| What comes down | the middle bay every time: 16 joists, 34 boards, 20.3 m²; the front and back bays stand |
| Time to come down | 1.1-1.6 s from the cut to nine in ten joist pieces 0.8 m down (2 seeds: one piece stayed up past 8 s) |
| Upstairs | 18-22 of 40 go down with it (195 in 10 nights); 19 broke a bone (a foot, a hand, an arm, ribs, 3 skulls) |
| Below | about 7 a night struck by the timbers (blows up to 485 J); 16 broke a bone in 10 nights |
| Dead ten minutes later | **none in any seed** |
| The men's cost | 13.7-15.9 ms a frame here for 55 standing HumanBodies (**~9-10 ms at Sean's against people's 4.0**) |
| The fall's worst frame | 157-248 ms here (~100-160 ms at Sean's, over #492's 100 ms gate) |
| Collision objects | ~2,820-2,860 in the lab (the building, the men's hitboxes and ragdolls, the rubble) |
| Memory | ~540 MB static in the lab |

**What it means for Payday Night (gameplay's):**
- **The fall works as designed.** Only the sawn bay comes down, about half the dancers with it, onto the bar.
  It hurts about one in five who go down or are under it, and kills nobody straight off. "Hurt but not normally
  killed" holds for Harlan.
- **The wounded:** about 3-4 broken bones a night plus bruises. Whether that "outnumbers the one doctor" (Rourke's
  offer) is the mission's to tune: more men below, or harder falls.
- **Nothing drops a standing man when his floor goes.** The bench sends him limp when the board under him breaks.
  The game needs that rule, and Payday Night needs it.
- **`fell_from` fired twice in 195 falls.** The men falling limp with the floor aren't measured as falls; their
  harm comes from the timbers and the landing's blows.
- **55 men in one building is over the people budget by about 2.5x** when each HumanBody runs every tick. The
  town's tick scheduling (people_tick.tres) has to carry the crowd, or the crowd upstairs is thinner.
- **The fall's worst frame is over the 100 ms gate.** The joists, boards and ragdolls all wake at once; the settle
  queue slices the structure, but not the ragdolls.
- **Not measured:**
  - **The jam:** these men don't walk. It needs townsfolk's AI and the stair. The one 2 ft 8 in door upstairs is
    the limit: at best about a man a second.
  - **In the valley:** this is the lab. The valley under lavapipe is too big for this box, so the valley's Jolt
    count and memory with the saloon on its lot are the next measure, on Sean's PC or a bigger box.

## Open

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
