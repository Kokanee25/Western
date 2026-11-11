# The sheriff's office and jail (#780): the second practice building

Art lane, branch `claude/art-building-jail-xrtsvh`. The building lab's steps by `../RECIPE.md`
(the doctor's office, `../doctor/`, is the worked example), each shown to Sean before the next.
Steps 4-6 (the look, the judge, the recipe) are the next session's: the look waits on the masonry
lab's stone (#663) and the paints (#779).

| File | What |
| --- | --- |
| `sheet/` | step 1, the target sheet: `request.json` (the views' words), `panels/`, `sheet.jpg`, `spent.json` |
| `jail.json` | step 2, the spec (format 1 and what's NEW for a one-storey stone building) |
| `results/plan.png` | the ground plan drawn from the spec (`tools/buildings/plan_sheet.py`) |

## Before step 1

- **The ground** (the bake, `config/valley_ground/`, read in Python): the lot falls away from Main
  Street, about 0.45 m over the office's 14 m and 0.75 m to the cell wing's end, and 0.2 m west to
  east over the lot's 30.8 m. In the building's space (y 0 the ground at the walk's street edge by
  the door, world -0.322): the front wall's foot -0.05/-0.11, the office's back corners -0.49/-0.56,
  the ell's end -0.82/-0.85, the lane's corners -1.26/-1.45.
- **The lot** (`config/valley.json` town.south `jail`): x 7.6-38.4 (101 ft), the south-east corner of
  the crossroads, across Main Street from the saloon; its west line on the cross street; the bank
  (brick) from x 42. valley.json's "back wall onto the rear lane" can't be: a 46 ft deep building on a
  125 ft lot leaves 79 ft of yard (Sean's answer below).

## Step 1: the target sheet (approved by Sean, 2026-11-11)

Sean's form calls (2026-11-11), asked before the prompts: **stone all round, one storey**; the
**office on the corner** (36 x 46 ft) with a **short stone cell ell** (16 x 30 ft) straight back from its
east half, the yard walled in stone to the rear lane (the cells' end wall faces the lane across the
yard: the jailbreak's); a **flat roof behind a stone parapet** (men can hold it on the jail night; it
doesn't burn); **three strap-iron cages**; **raw rubble with dressed corners**, lintels and sills,
oxblood plank doors and gates; outside views lit by a **summer evening sun from the north-west** (the
front faces north and stands in its own shade most of the day).

Ten views by Nano Banana Pro on GitHub (`building_sheet.yml`), each given the front and the plan:
**$1.55** of a $2.50 cap (the first run $1.27 for nine; the cage view failed at no charge and the
corner came out a near copy of the front: both asked again, the corner given only the plan, $0.28).
The sheet's faults are settled in the spec, not repainted:
- the plan runs the cell wing to the rear lane and puts the yard only beside the office (the spec:
  Sean's short ell, the yard walled all round);
- the roof is drawn as planks (the spec: tin over boards);
- the front shows one window either side and a front walk the width of the lot's frontage (the spec:
  the walk stops at the building).

## Step 2: the spec (`jail.json`)

Sean's calls on the conflicts (2026-11-11): **no pad**, the stone follows the fall (the base shows
2 ft at the front, 3.5 ft at the office's back, 4.5 ft at the ell's end); **the walk stops at the
building** (valley.json's walk `span` [7.6, 18.57], `door_x` 13.085 when the jail goes onto its lot);
**stone yard walls all round** (10 ft, 18 in, a wagon gate on Main Street and on the lane); the stone
walls laid as **the builder's stone pieces** now, marked `masonry: rubble_stone` for the masonry lab's
step 8 to lay its stones and joints in their place.

The building: the office block 36 x 46 ft (10.97 x 14.02 m), walls of 22 in rubble (the masonry lab's
0.55 m panel), one storey, the floor 2 ft up (the walk's top), 11 ft clear inside, a flat tin roof on
3x12 joists front to back in pockets, its parapet's coping 17 ft over the floor. Inside: the office
across the front (9.8 x 6.8 m), an 18 in stone cross wall bearing the roof joists at mid depth, the
sheriff's room (west) and the guard room (east) behind it, split by a plastered stud partition. The
guard room has the yard door (five stone steps down), the ladder to the roof hatch and the cell wing's
strapped door. The cell ell 16 x 30 ft (4.88 x 9.14 m), 10 ft clear, 3x10 roof joists across it: a 4 ft
6 in corridor on its west side, a grille gate at its north end, three riveted strap-iron cages (7 x 8 x
7 ft) on stone flags along the east side, a high barred slit over each cage and the corridor, one in the
blank south end wall (the jailbreak's). Openings: the front door in the middle with a barred transom,
eight barred six-over-six windows with inside shutters (two front, two west, one east, one back), seven
slits. Use points in every room and four on the roof behind the parapet.

NEW to the builder (step 3): stone outer walls in pieces (footings, quoins, lintels, sills, the coping)
whose foot follows the ground; stone partitions; a flat roof of joists in pockets, boards and tin; an
L footprint (`lot.footprint`); stone flags on fill; the cages; the yard's stone walls and gates; a
plank shed; an inside ladder.

## Step 3: the build, the checks, the X-ray sheet

`stone.gd` builds a stone building from its spec (`spec_building.gd` hands it over when
`frame.stone_wall` is given; the saloon, farmhouse and doctor build as before):
- **The walls are stone pieces** (Sean's call): each wall in rows (the 0.6 m courses, broken at the
  set-offs, sills, heads, lintel tops and the coping), cut into pieces of at most 1.5 m, staggered row
  to row; a dressed sill under each window and a lintel over each opening (bearing 12 in each side),
  named so `Checks.built_right` counts them as the opening's framing. Each wall's thickness by height is
  its `profile`: a 6 in set-off under the floor (the side walls carry the 2x10 joists on it, the front,
  back and cross walls the girders), 22 in up to the roof, then a 6 in ledge the roof's joists bear on
  (no pockets to fill: the parapet over it is 16 in). The footings go 3 ft under the ground, following
  its fall (the spec's plane). Every piece is kind `sill` of the game's `stone`: a piece rests on the
  one under it.
- **The floors**: 2x10 joists across on the side walls' set-offs and two girders (on stone piers,
  between the front, cross and back walls' set-offs); the cell wing a stone fill under 4 in flags.
- **The roofs**: the office's 3x12 joists front to back on the front wall's, cross wall's and back
  wall's ledges (spans 7.1 and 6.0 m), boards, tin sheets; the hatch between two joists over the guard
  room, headers on its trimmers, its leaf folded back, a ladder up through it. The ell's 3x10 across.
- **The cages**: strap-iron lattices as members (`iron`): straps 2 1/2 x 1/4 in, uprights at 6 in on
  the flags, cross straps at 12 in on them, straps over the top; each door the lattice's own straps;
  a plank bunk; the corridor's grille gate.
- **The yard**: 10 ft walls of 18 in stone on all four sides, their tops stepped with the ground in
  6 m lengths, the wagon gates open from the ground up (a footing under each), the leaves standing
  open against the wall's inside.

`tests/test_building_jail.gd` (6, all pass): **3,094 members** (1,648 stone), destructible through and
through; **it stands** (none without a load path, none over its limit under its own weight; with a
crowd on its floors and roof the worst is a 3x12 roof joist at 84%); **built right** (18 openings,
nothing across any, the 16 in the outer walls under their lintels, the windows on their sills and glazed,
the slits open); people fit (5 doors, 17 use points; every room used, the roof's four behind the
parapet); **the jailbreak by the rules**: the ell's end wall blown out 1.5 m wide and 1.8 m high at
its foot (6 pieces), and only what was over the hole goes (1 piece: the stone either side carries
the rest); **80 draws** (71 batches, 9 own meshes).

`results/xray.jpg` (`tools/buildings/xray.py`, a stone building's views): each wall from outside
with its openings' clear areas, a section along through the office, cross wall, guard room and
corridor, a section across the cells, the floors' framing and the roofs' from above, the whole lot
from above.

What the checks caught on the way: the cages' door straps were kind `door`, which rests on nothing
beside it (they're the lattice's own straps now); a gate leaf placed in the gateway floated (it stands
against the wall's inside face); a footing drawn from above across a gateway read as a wall (the
X-ray hides what's buried).

Not built yet (the look's, step 4, and the props'): the plaster and whitewash inside, the painted
sign and the cut JAIL panel, the sashes and shutters, the shed and the privy, the lamps; the
valley lot (`spec`, the walk's `span` and `door_x`) waits for the judge (step 5).
