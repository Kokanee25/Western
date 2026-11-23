# The undertaker's (#1141)

14 Undertaker, the east end of Main Street's north side (`config/valley.json` town.north `undertaker`):
an 1882 undertaker and cabinetmaker with a period-true, walkable cellar. Sean's brief is #1141's body.

## Step 1: the target sheet (Sean OK, 2026-11-23, #1171: cost yes; white with black trim; 32 ft shop west, yard east; stair and bulkhead)

`sheet/sheet.jpg` (panels in `sheet/panels/`): twelve views painted 2026-11-23 for **$1.69** (run 12 of
`building_sheet.yml` on `claude/art-building-undertaker`). Where the pictures differ from the words (the spec
settles each, never the pictures): the front's walk drawn low (it's 1.15 m) and the trim grey, not near-black;
the plan puts the yard and shed inside the 32 ft (they're beside it, east); the cutaway digs the cellar under the
front, not the back half; the back view's hearse is an open carriage, the yard's the glass box; the coffin
store's safety coffin shows no bell frame. Sean OK'd the sheet 2026-11-23 (#1173); steps 2-6 are #1174.

## What the lot gives (probed 2026-11-23 from `config/valley_ground/heights.r16.gz`)

- The lot: x 106.0-128.0 (22 m, 72 ft), the front at z -10.05, depth 18 (to z -28); the back street at
  z -48. It faces south (facing 180): **its x runs from its EAST corner** (RECIPE step 2).
- The ground falls east ~0.12 m across the lot and rises to the back: about -0.40 m at the front's middle,
  -0.05 at z -20, +0.20 at z -28, +1.3 at z -40. The walk's top (`h` 1.15) puts the floor near world +0.75:
  1.15 m over the dirt at the front, ~0.55 m at the back. A cellar 2.4 m under the floor is ~1.3 m below
  the dirt at the front and ~1.9 m at the back: the bulkhead's steps want ~4 risers at the back, ~3 at the
  front. Plan: the building on the lot's west (against the junk alley, x 106-115.75, 32 ft), the yard east
  with a wagon gate to the street, the hearse shed at the yard's back, the walk's `span` the building's.
- Neighbours: the junk alley (`alley_n8`, crates across it 6-9 m back) and the barber west; nothing east
  (Main Street ends at x 130).

## How the town uses him today

- The undertaker (`config/valley_folk.json` `undertaker`) works by day at `undertaker_walk` (the lot's
  [5.0, -1.2], tool `bench`: planing on the walk) and eats and sleeps `in` the lot. Earl and the dead go
  "to the undertaker's" as a story fact and leave the world (`ValleyFolk.to_undertaker`): no body is laid
  in the building yet. The parlour's bier and the cellar's sheeted board are where a body could lie
  (gameplay's to wire, after the building).

## Period notes for the props (checked against what's known; the archives are blocked here)

- Arterial embalming spread after the Civil War; in 1882 it was often done at the dead man's house, but an
  undertaker's own room in a town is right. Tables then were wood (a cooling board of slats or cane on
  trestles; a board table with a zinc-lined, sloped top and a drain). Porcelain tables are 1890s on.
- Fluids in glass carboys and bottles (arsenic and zinc chloride solutions in the 1880s); a hand pump and
  rubber tubes, a gravity bottle.
- Ice: corpse coolers (a box with an ice pan over the chest) were sold from the 1870s; ice cut in winter
  and kept in sawdust.
- Coffins: the six-sided "toe-pincher" still common in the West, rectangular caskets coming in; a child's
  often white.
- Safety coffins: many patents 1850s-1890s, a bell on a frame at the grave's head with a cord to the hand.
  A sample one in a town undertaker's cellar is plausible, not common.
- Hair wreaths: Victorian mourning work, framed under glass: true.
- **The posing stand:** photographers' iron stands held living sitters still for long exposures; that they
  propped up the dead is mostly a modern myth. It stands by the stair as the photographer's kit, with a
  draped chair, never with a body in it.

## Steps 2-4: the spec, the build, the cellar walked (#1174, 2026-11-23)

- **The spec** (`config/buildings/undertaker.json`, written by `make_spec.py`): 32 x 50 ft (9.754 x 15.24 m) on the
  lot's west against the junk alley (`at` x 115.784: its siding 3 cm inside the lot's line at 106.0), facing 180. The
  floor at the walk's top (1.15), 11 ft to the ceiling, a low loft on 2x10s under a 6/12 rafter roof (2 m at the
  ridge), the false front 7.6 m (UNDERTAKER). Rooms by the plan panel (it settles the sides): the parlour east by the
  yard (its wall on the east girder's line carries the loft's joists in front), the showroom west with his office
  in its back corner, the workroom across the width (the hatch girder to girder, the side door's pair of leaves
  opening in, a 1 in 5 plank ramp to the yard), his room behind. Girders at x 3.25 and 6.47, piers outside the
  cellar; the loft's joists break over two summer beams on 4x4 posts through slots onto the girders.
- **The cellar** (under the back 25 ft, its floor 1.6 m under the street edge, flags at -1.52: 2.41 m to the joists,
  2.26 under the girders): the coffin store across its front (the stair's foot, the bulkhead's passage, two coffin
  racks), the embalming room (west) and the ice room (east) behind a cross wall that carries both girders; the ice
  room's wall under the east girder, its door 10 cm thick. The steep stair: 13 risers of 0.205 on 0.21 goings
  (44 degrees). Three posts; a lamp a room.
- **The bulkhead** (`Bulkhead`, new): on the yard wall at z 8.1-9.1, its areaway 2.45 m out, 10 risers from the yard
  (building y 0.31) to the flags, a stone lintel over the passage, the doors standing open.
- **No pad:** the lot keeps its slope (the yard's plane [0, 0.0055, 0.034] within 4 cm of the bake); the cellar and
  areaway are dug in the valley by `CellarDig` (new). The yard: the picket fence and wagon gate on the front line,
  a board fence down its east edge on the slope, the hearse shed (6.6 x 5.6 m, board and batten, gable roof, double
  doors open, the stall on its west side) at its back.
- **Checks** (`tests/test_building_undertaker.gd`, 9): destructible (4,060 members + U0's props), stands (dead and
  crowd; the game's settle drops nothing), built right, people fit, every room lit (the cellar's three too), the
  bulkhead open and its passage clear, a man walks from the workroom down the stair, through the coffin store into
  the embalming and ice rooms, out through the passage and up the bulkhead, round to the ramp and up into the
  workroom. In the valley (`tests/test_undertaker_valley.gd`): dug where it should be and nowhere else, walked
  from the yard to the workroom through the cellar. Draws 167 (112 batches, 55 own meshes, 8 lights).
  X-ray: `results/xray.jpg`.
- **The look** (step 4): the library by name: white lead on narrow clapboard (`painted_white_lap`, passed), pale
  boards inside, worn fir floor; the near-black trim wants `painted_black_trim` (not in the library: drawn in dark
  walnut till it is); the cellar's plank walls, the bulkhead, ramp and shed rough pine.
- **The props** (U0, the spec's `dressing`): what the kit has, standing in (tables fitted as his bench, the bier, the
  coffin trestles and racks, the cooling board and the embalming table; his desk, bed, stoves, chair, the fluids'
  shelf, a barrel). The trade's own (coffins, the box hearse, the embalming table's zinc top and pump, ice in
  sawdust, the corpse cooler, the safety coffin and its bell, the posing stand, the hair wreath, shrouds, carboys)
  are the prop lab's: the next step.

## Step 5: the judges (two rounds, #1174)

- **Round 1** (`docs/screenshots/judge/2026-11-23_undertaker_r1/`, renders by `render_valley.gd`, ~25 min a view
  here with LP_NUM_THREADS=2 and a 12 GB swap file: the first try was killed for memory): cheap judge front, yard,
  stair, embalming **cheap indie**, workroom **good indie**. Blind critic: front and yard SIMILAR, workroom, stair
  and embalming DIFFERENT; its top three: the cellar's stone a blue placeholder camouflage, the cellar boarded not
  stone (the partitions are plank; the foundation is the game's `stone` till `rubble_whitewash` passes), a black
  band across the embalming view. The neighbours' grey blocks (the barber's lot is unbuilt) and the empty rooms
  lead the rest.
- **The fix:** the band and the blue were the room's fill box stopping at the building's 0: below it the sky's
  ambient lit the cellar, its edge a band at that height. A dug cellar's fill now reaches its floor
  (`_add_interior_ambient`). Also the yard's doors (bulkhead, shed) took the inside's pale paint: their surfaces
  go first now.
- **Round 2** (`2026-11-23_undertaker_r2/`, stair and embalming): both cheap indie, for the empty rooms (props),
  the floor's gloss and repeat, the stone's square blotches and no contact shadow under the tables. The cellar now
  reads dark and lamplit. Left for the props step and the library (stone, black trim).
