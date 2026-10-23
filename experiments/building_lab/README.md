# The building lab: the saloon from its spec

Gameplay (structures) with art for the look; branch `claude/gameplay-building-spec`; brief
`docs/briefs/building-pipeline.md` (steps 2 to 5). The spec format is `FORMAT.md`; the saloon's
spec is `saloon.json`. **The game's saloon is unchanged**: the builder, the stair part and the
checks live here, and the town's saloon (`SaloonBuilding`) stands as it was. The one way into the
game is F5's last stop (below), to walk it in a build.

**Walk it in a build:** press F5 (D-pad up) until you're past the outlaw: the eighth stop builds the
spec saloon out in the desert west of town (`play.gd`, `DebugSpawns/SpecSaloon`; a hitch of about
3 s the first time) and puts you in front of its door. Everything in it breaks, burns and takes a
shot as the town does. Its cellar is closed (the town's ground is one plane, item 7 below), and
nobody in town uses it.

| File | What |
| --- | --- |
| `saloon.json` | the saloon's spec (format 1) |
| `FORMAT.md` | the format, its bands, the framing rules, the checks |
| `spec_building.gd` | the builder: a `FalseFrontBuilding` built from a spec (its wall helpers reused) with bands of the support ladder and a grid broadphase |
| `stair.gd` | the Stair part (stringers, treads, risers, newel, Railing, posts, the walking ramp) |
| `lab.gd` | the set: the saloon on ground with the cellar's pit, the boardwalk, Fittings, the fire, ballistics |
| `checks.gd` | the brief's checks, shared by the test and the runner |
| `run.gd`, `runner.gd` | every headless check on fresh builds -> `results/<date>/results.json` |
| `render.gd` | the sheet's views in the game's own street, for the blind critic |
| `play.gd` | the saloon and its boardwalk set down in the street (F5's last stop, and the renders) |
| `tests/test_building_lab.gd` | the walk (destructible), it stands (crowd too), posts knocked out, people fit, rooms used |

```sh
godot --headless --fixed-fps 60 -s res://tests/run_tests.gd -- --only=building_lab
godot --headless --fixed-fps 60 -s res://experiments/building_lab/run.gd -- --out=experiments/building_lab/results/2026-10-22   # ~15 min (the fire)
xvfb-run -a godot --path . --rendering-driver vulkan -s res://experiments/building_lab/render.gd -- --out=DIR   # ~2 min a view
```

## The saloon's spec: the critiques settled

| Critique (the brief's table) | Settled |
| --- | --- |
| Outside stair on the side elevation only | Sean, 2026-10-21: keep it. **2026-10-22: on the east side** (Freight Street), rising from the yard toward the street to a side landing; the street balcony wraps the east corner to meet it; a door from the landing into the front gallery |
| The street balcony | Sean: both balconies. The street one 8 ft deep over the boardwalk on 6x6 posts at 10 ft, its joists on a ledger through the siding into the studs; the gallery round the open well inside |
| Too big for its lot | Sean: widen it. **2026-10-22: 50 ft (15.24 m), a double lot; the room from Freight Street, which moves ~5.5 m east** (the south side has only ~2.5 m of slack, and the doctor's already stands 0.5 m into Market Street); nothing on the south side moves |
| No frame | a balloon frame (Bell 1858, Woodward 1865) sized by the Wood Handbook's figures; queen-post trusses (Tredgold, 1886 ed.); the gallery on 8x8 posts and 8x10 beams with brackets |
| Indoor restrooms | Sean: an outhouse out back. **2026-10-22: in the saloon's spec**, a two-holer 8 m behind the back door |
| Upstairs | five bedrooms: three over the back rooms, two over the bar |
| A cellar | Sean: yes, and big: 7.6 x 7.9 m under the bar and the kitchen (the west half), rubble-stone walls, stone flags, six posts under the girders, a trap girder to girder and a steep stair; the floor over it on its own joists |
| Views that don't agree | sizes from the spec only. **The bar along a side wall, on your right as you walk in** (Sean, 2026-10-22: as his picture and the sheet's view from the entrance; the sheet's plan has it across the back). It was first built on the east wall as today's game saloon has it, which is on your left from the door; the blind critic's first round saw it mirrored, and Sean picked the mirror: the bar, back bar, kitchen, cellar and rooms 4 and 5 on the west, the hall stair up the east wall |

## Results (2026-10-22, `results/2026-10-22/results.json`)

- **Built:** 5,183 members in ~1.5 s, 23 kit props (482 members: three bar sections, three back
  bar sections, three card tables, fourteen chairs), 31 OilLamps (18 sconces on bracket members,
  three on the tables, two on the bar, eight on the chandelier), 21 use points and the tables' 14 seats.
- **Destructible:** the walk finds nothing but members, kit props' members and fittings, plus 118
  batches, 31 lamp hitboxes and 4 stair ramps (the exceptions below). 133 members are stone (the
  foundation, cellar walls, piers, flags: they don't burn; blasts and falls break them), 3 iron
  (the chandelier's rods), 16 glass (the windows: they shatter).
- **It stands:** every member has a load path and none is over its limit, under its own weight and
  with a crowd on every floor (40 lb/ft2, 60 on the balcony and galleries). Worst under the crowd:
  the back rooms' joists (0.83), the east gallery's (0.79). Getting there found and fixed, in the
  builder: interior boards narrower than the stud spacing with nothing to nail to (nailers added),
  cripples resting on nailers, plates and ribbons jointed over doors, floor boards jointed between
  joists, the trap's tail joists (the trap now runs girder to girder), 2x4 balloon studs buckling
  at 7-10 m (3x4s), kings doubled under the balcony's ledger, and the roof's trusses bearing on the
  upstairs partitions (they now stop 2 cm short).
- **It falls right:** each of the 14 gallery posts knocked out leaves 2-3 members over their limit
  (the beams over it); for real with physics the well's corner post at (5.49, 10.67) brought down
  223 members as 110 pieces of rubble, and **nothing is left floating**. The six cellar posts and most
  of the balcony's are redundant (the girder or beam spans to the next): knocked out alone, nothing
  goes.
- **People fit:** 13 doors at least 0.76 x 1.98 m and clear, 2 m of head room up all four stairs,
  every use point on a floor, clear of steps and doorways, with room to stand.
- **It's used:** every room has its people's places; the barmen between the bar and the back bar;
  14 seats at the tables.
- **It burns:** a board on the hall's back wall and a floor board alight: 1,000 members burning at
  2 min (and 161 of the kit's), 3,987 at 4 min, 86% consumed at 12 min, the furniture with it. The
  fire's rules cost ~185 ms a 0.5 s step on this core with the whole saloon alight (gameplay's
  known fire-tick item at town scale, performance part B).
- **It breaks:** revolver balls from the door hole a bar section's panel, a post, the east wall's
  boards, a card table's foot (in front of the chair aimed at) and the front gallery floor's edge
  (holes drawn: the native plugin isn't built in this workspace, so no voxel carving here). A stick
  on the hall's floor breaks 301 members (263 pieces of rubble) and throws or breaks 20 kit props.
- **Budget:** 389 draws standing (118 batches, 23 meshes of their own (glass), 248 lamp meshes: 8 an
  OilLamp); headless, 0.13 ms a frame standing with every lamp lit (today's test street: 4.5 ms).
  The render CPU and the lamps' cost need a render run (`render.gd`; perf_bench on the real street
  once it's in the town).
- **The look** (`results/2026-10-22/renders/`, the blind critic's `critic.md`; round 1, before the
  mirror, in `critic_round1.md`): **front CLOSE, entrance CLOSE** (round 1 had the entrance DIFFERENT:
  the bar on the wrong side); front at night, the east side, from the balcony and Sean's picture's
  view DIFFERENT. Its top three: (1) the interiors far darker and emptier than the paintings (no
  amber glow, few things, no people: the lamps' light is the game's, the material lab's known
  finding; the dressing is the missing kit props); (2) the woodwork thin and plain (square
  spindles where the paintings turn heavy balusters, posts without caps, no capped pilasters or
  pediment round the sign outside); (3) the outside a plain weathered box (dark windows, no porch
  furniture, the outside stair and the side gallery all but invisible: the same grey pine as the
  wall behind them). The rest is art's: turned balusters and newel caps as kit draws, the back
  bar's bottles, the lit windows' look, the outside stair's wood.

## Lived in, step 1 (2026-10-22; brief `docs/briefs/lived-in.md`)

The saloon's spec now says how it's used (`use`: four years of ten walking paths, the four stairs,
people at the gallery's rail, the doors, two spills, the furniture, the lamps' soot, the weather)
and what happened in it (`past`: nine events, from the 1880 brawl's replaced baluster and the ball
still in the post by the bar to a scrubbed patch by the middle table). The lived-in pass
(`marks.gd`) turns them into ~1,600 marks on 1,093 members (518 `foot`, 216 `scuff`, 339 `bleach`,
109 `soot`...), every one with its cause and none unresolved; the test checks they land where their
causes are. Nothing is drawn yet (the shader is art's, after Gate A). **The wear map** for Sean,
`results/2026-10-22/wear/` (`render.gd --wear`: members tinted by their strongest mark, a mark's
stretch drawn over just that part): the ground and upper plans (the street at the bottom), the
view from the door, the front, the back. Colours: orange foot, yellow heel, red scuff, cyan
hand/boot, blue rings/elbow/streak, purple spill, grey soot, brown splash, white bleach, green new,
magenta the past's marks, red the ball.

## Lived in, step 2: drawn in the lab (2026-10-22; Sean: "go ahead", ahead of Gate A, lab only)

The marks drawn on the saloon's wood, in the lab only: `wear_paint.gd` bakes them into a wear
volume in the saloon's own space (6 cells a metre; R worn, G polished, B dirt, A fresh) and a map
a floor level (20 a metre, softened), and draws its batches in `wear_wood.gdshader`: the game's
wood (`texel_grid.gdshaderinc`) with `wear.gdshaderinc` laid on through a `WEAR` hook (three lines
in art's include, inert unless a shader defines `WEAR`: the game's look is untouched). Each change
is relative to the wood it's on (boots wear any wood paler, dirt darkens any, hands polish warmer
and glossier). Worn nosings are geometry: each tread's front edge rounded deeper the busier the
stair (`marks.gd`). The outside weather (splash, streaks, bleach) stays the weathering layer's:
through a wall thinner than a cell it darkened the wall's inside. (A see-through overlay was tried
first: the depth mosaic redraws the frame from a copy taken before see-through passes, so it never
showed; hence the opaque hook.) `render.gd --worn` draws it; the A/B pairs are in
`results/2026-10-22/worn_round3/` (`key.json` says which is which).

Three blind rounds (each pair shuffled; the critic told one has the marks, not which): **round 1**
found them only by measuring, too faint, and two marks read as bugs (soot over whole boards);
**round 2** the stair treads right ("sure"), speckle and a glowing pale patch; **round 3** all five
found by eye (three sure), strength about right in three of five; most convincing: the scuffs
under the chairs, the dark foot of the bar with a stain in front of it, the trodden floor round the
tables toward the door. What's left is the lab method's: marks on a world grid coarser than the
boards (stepped edges that don't run along the grain), the polish barely showing, the soot lost in
the lamps' glow, the stair weakest where use should show most. Its verdict: "a bit scuffed", not
"long drunk in" yet.

**For the real thing (art, in the woods' shader):** draw each mark in its member's own space along
its grain (the marks already say where on the member: `along` a stretch, `at` a point), not on a
world grid; the polish as gloss the lamps pick out; soot as a plume above the glow; and push the
wear harder for the wide shots. The marks and their causes are ready for it.

## The exceptions the walk allows (`Checks.EXCEPTIONS`)

| Exception | Owner |
| --- | --- |
| A structure's batched draw of its untouched members (a member leaves it the moment anything happens to it) | gameplay, `src/structures/structure.gd` |
| A stair's walking ramp (`Layers.WALK` only; freed when its stringers go) | gameplay, the Stair part (to be promoted) |
| An OilLamp's hitbox | gameplay, `src/world/oil_lamp.gd` |
| The ground (boxes round the cellar's pit here) | gameplay, the town's ground |

Not things (neither collide nor draw a surface): the lamps' lights, the room's light probe and
haze, the use points.

## What isn't in the saloon yet (not destructible), and whose

In the order the saloon needs them:
1. **Prop lab: whiskey bottles** (glass members that shatter): the back bar's shelves stand empty
   and the bottle wall isn't built.
2. **Prop lab: bar stools**, then **beds and washstands** (none exist in any form: the five bedrooms
   are empty), **the piano**, **kegs and barrels** (the cellar's racks are empty), spittoons,
   framed paintings, the deer head, tin cups, a kitchen stove.
3. **Prop lab: the sconce's model breaking with its lamp.** Here a sconce is a bracket member with
   an OilLamp on it (it falls with its bracket and smashes); the drawn sconce isn't used.
4. **Sean: the bar and back bar in a lighter oak** (the critic: darker than the walls). (The kit card
   table went into the game on main, 2026-10-21.)
5. **Gameplay:** a prop knocked by a ball or a body doesn't move; what stands on a shelf adds no
   weight (`extra_load` unused); `furniture_frame` members are never load-checked.

## Fought in (2026-10-23, the gunfight lab)

The gunfight lab's setups are in this saloon now (`experiments/gunfight_lab/`, `spec_*` arenas;
`spec_saloon.gd` joins its ways into the town's places). What it took, as built:
- **The batwings were solid**: two `door` members across the doorway at 0.4–1.55 m, on the world's
  layer, so neither you nor anyone could walk in (the town's saloon has drawn batwings, FacadeArt's,
  nothing to collide with). In the builder they're on `Layers.DEBRIS` now: a ball still hits them,
  a walker passes.
- **No places**: a man walks by `Waypoints` (straight to the nearest place he can reach, then along
  the links); the spec saloon had none, so the stair, the galleries and the back rooms were out of
  his reach. 48 places from the spec (doors, the bar's open end, round the open cellar trap, the
  stair's foot and head, the galleries, the rooms, the balcony, the yard); every link walked by a
  man (`gf_ways`: 52 of 52).
- Walking needed nothing else: the stair's ramp carries a man up (1.5 s foot to head), the
  doorways pass him. Two things to route round: the kitchen's cellar trap stands open, and the back
  room's door leaf stands open into the hall beside a gallery post.

## Open for Sean

(Settled: rooms 4 and 5, over the bar against the store, stay **without windows**, the cheap rooms
lit by a lamp; Sean, 2026-10-22, issue #242.)

- A lighter oak for the bar and back bar (art's call), as above.

## What the format needs before it's used for real

The spec built the saloon and it passes every check that runs headless; before it replaces
`SaloonBuilding` in the town (roadmap 4.3, "Building lab for real"), these, each with its owner:

**Into the game's shared code (gameplay, `src/structures/`; each a promotion with its PARTS.md row):**
1. **Bands on the support ladder** (`StructureMember.band`, `Structure._place_in_stack`/`_link`):
   without them a second storey can't stand (a joist on a beam, a board on an upper joist, a
   partition on a floor). Today's saloon gets round it with `rafter` joists and `furniture_top`
   boards on its balcony.
2. **The broadphase in `Structure.infer_supports`** (a grid; the same links in the same order):
   pairs grow as n²: 977 members took 0.4 s, this one's 5,183 would take ~11 s.
3. **The Stair part** (`stair.gd` -> `src/structures/stair.gd`), with SaloonDressing's stair rebuilt
   on it; its ramp goes when the stringers do (today's stays).
4. **Wall framing as a part**: FalseFrontBuilding's framing from any foot, doubled kings, plates and
   ribbons jointed over studs, nailers, the inside finishes (wainscot, beaded boards, casings,
   picture rail) as members drawn as woodwork. They live in the builder here.
5. **Floors as a part**: joists between girders, openings framed girder to girder, boards jointed
   on joists.
6. **`Fittings.drop`** assigns a freed node to a typed variable before checking it (a structure
   rebuilt after Fittings has collected errors there); one line.

**The town (gameplay):**
7. **A ground with a hole**: the town's ground is one plane; a cellar needs a pit (ties to the
   dig-able ground brief). The lab's ground is boxes round it.
8. **`config/town.json`**: the saloon's entry, Freight Street's line (x 23 -> 28.5), the range's
   cover (30 -> 35.5), the saloon's boardwalk (16.4 m); and everything placed by the old saloon's
   layout (x 0..10): ShotMatch's set, the screenshot views, waypoints, DebugSpawns, the soak's and
   playtest's places, the goldens that show the saloon (art's, with Sean's OK).
9. **`SaloonBuilding` replaced** by the builder reading `saloon.json` (and SaloonDressing's walls,
   stair, balcony, mirrors and bottle wall retired into the spec and the kit).

**The format itself:**
10. **Finishes by room, not by level span:** the inside finish is given per wall and level; it
    should come from the rooms (the hall wainscoted, a bedroom boarded, the kitchen rough), so a
    wall between two rooms takes each side's.
11. **Ceilings** for the bedrooms (they're open to the trusses now) and the trusses' look in the
    hall (the picture shows them).
12. **Deflection:** the checks test strength under a crowd; a floor's bounce (L/360) needs its own
    check (the format gives spans; the analysis gives loads).
13. **Working doors:** doors are members standing open; the format names them, but opening,
    closing and barring them is gameplay's.
14. **The views for the judge:** the sheet's plans and its cutaway need section renders (members
    hidden past a plane); the elevations and interiors render now.
15. **Its size:** 5,183 members, 5,800 bodies; with the town 13,313, past Jolt's default 10,240
    (`project.godot`'s `max_bodies` raised to 32,768 for it). Built at runtime it takes ~4.3 s here
    (~3 s at Sean's); in the town it would be built at load, with the broadphase (item 2).
16. **A recipe**: what went wrong here (the list under "It stands") goes into the recipe once the
    second building is built from the format, so the tenth is easier than the first.

## What I read

`docs/briefs/building-pipeline.md`, `docs/briefs/interior-woodwork.md` ("What the picture's
woodwork measures" to "What's next (round 3)"), `docs/PARTS.md` (all), `docs/SESSION_PROMPTS.md`
(the building lab and test saloon prompts), `docs/LAYOUT.md` (town layout, src/structures, the
prop kit, saloon dressing), `config/town.json`, and the code of `Structure`, `StructureMember`,
`StructuralAnalysis`, `FalseFrontBuilding`, `SaloonBuilding`, `SaloonDressing` (stair, balcony,
mirrors), `Railing`, `PropKit`, `KitProp` (head), `Fittings`, `OilLamp`, `InteriorStand`
(wainscot, gallery, brackets), `Boardwalk`, the kit's bar, back bar, chair and card table.
