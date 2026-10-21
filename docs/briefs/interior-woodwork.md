# Brief: the saloon's interior woodwork (art; Sean 2026-10-21)

**Goal.** Every wooden surface inside Sean's saloon picture, made on the material lab's bench and
approved by Sean, so the saloon session can build the room from it. It covers the gallery's
balustrade, the posts and beams, the wainscot and walls, the bar and back bar, the casings and the
floor, all in one interior stain. The saloon's structure starts when Sean has picked these woods
and gameplay has promoted the breakable railing (`docs/briefs/building-pipeline.md`; the roadmap's
"When the labs start").

**What it is not.** It is not the room: the frame, floors, stairs and walls as members are the
building lab's (gameplay structures, art look). It is not the room's light: the lamps' falloff,
the dark corners and the moonlit windows belong to the saloon session. It is not the props (the
prop lab) or the railing's breaking (gameplay's `BodyImpacts`). This brief makes the shapes and the
stain those pieces are drawn with.

## References, in order

1. **Sean's picture**, `docs/concept/targets/10_saloon_interior.png`: the look of the woodwork.
   We take its shapes and colour, not its chunky squares: the woods stay smooth and painted, as
   the material lab's rounds have made them (Sean, 2026-10-21: "we ain't doing that anymore").
2. **The saloon sheet**, `docs/concept/saloon-sheet.png`: what the room has and where (a gallery
   round an open well over the bar, the stair up the left, the bar along the back, the back bar,
   the piano, the doors). Its "view from entrance" and "view from second floor balcony" are the
   woodwork's second target.
3. **The Studio's men** (`9_studio_men.png`), as for every material: the woodwork must read as
   painted by the same hand.

## What the picture's woodwork measures (2026-10-21, the picture's own pixels)

| Where | L* 10th / median / 90th | C* median / 90th | Hue |
|---|---|---|---|
| Post by the stair, lamplit | 14 / 22 / 36 | 18 / 34 | 47 |
| Gallery posts and beam | 10 / 20 / 30 | 17 / 29 | 44 |
| Bar front panelling | 5 / 16 / 63 | 21 / 47 | 51 |
| Wall boards | 11 / 24 / 52 | 28 / 64 | 44 |
| Back wall panels | 10 / 19 / 34 | 18 / 37 | 43 |
| Floor | 5 / 24 / 39 | 15 / 30 | 37-43 |
| Table top, lamplit | 13 / 42 / 62 | 47 / 64 | 53 |

One warm umber family (hue ~43-51), dark in the mean (L* ~20), deep in shadow, bright only where
a lamp reaches. Ours, under the lab's saloon lamps today: L* 22 (floor) to 44 (store boards), each
wood its own colour.

## The pieces (sizes are the usual period ones, to be checked against a period stairbuilding and
joinery manual before production; Sean is not a framer)

- **The gallery's balustrade:** a moulded handrail (~65 x 60 mm, rounded top, grooved sides),
  turned balusters (~45 mm, about two per 270 mm stair going, ~110 mm centres on the level), a
  bottom rail, square newels (~125 mm) with caps and drops, the rail 1 m over the gallery floor.
  The oak stair's turnings and rail are the start (`OakStair`).
- **Posts and beams:** ~200 mm square posts with chamfered arrises and stops, brackets (curved knee
  braces or corbels) under ~200 x 250 mm beams, the gallery's joists showing under it.
- **Walls:** a panelled wainscot (~0.9 m: stiles and rails ~100 mm, raised or flat panels, a moulded
  cap rail, a skirting), vertical boards above, a picture rail.
- **The bar:** ~1.1 m high, a ~50 mm top ~0.6 m deep with a rounded front edge (worn where arms rest),
  a raised-panel front between pilasters, a foot rail on brackets ~0.15 m up (brass, not wood).
- **The back bar:** a base cupboard and counter, shelves on brackets, a framed mirror between
  columns, a cornice and crest across the top.
- **Casings:** door and window casings ~110 mm with a head casing and a small cornice; the batwing
  doors' frame.
- **The floor:** 150 mm planks, darker and worn in the traffic (wear-down waits for Gate A).

## How it's made

- **One interior stain** (a material lab set, `studio_int`): the woods the room uses graded into the
  picture's umber family with the round 3-5 tools (`grade`, `match`, `unify`, `highs`, `lows`,
  `calm`), from paintings we have (the dark oak and walnut of the oak stair, dark trim, timber). No
  paint unless grading can't reach it; then Sean is given the cost first.
- **A profile kit** (`src/art/profiles.gd`): any cross-section run along a board as smooth geometry
  with its end grain on the cut ends, generalising the worn tread (`MaterialStand._worn_box`):
  chamfer (with stops), round, bullnose, bead, ogee, cove, a moulded handrail, a raised panel (a
  field and its bevels), a bracket's curve. Each is data (a list of points), so gameplay's railing
  part and the saloon builder draw with the same shapes. Smooth normals on curves, the woods' strips
  along the grain, flags for end grain as every board.
- **The interior stand** (`InteriorStand`, `--material=interior`): a corner of the saloon at its real
  sizes, the ground floor's 3.7 m: a post and beam with brackets, the gallery's edge with its
  balustrade over the open well, a run of wainscot and wall, a door casing, a piece of the bar and
  the back bar, the floor. The Studio's men in front; the three lights, the saloon's lamps first.

## Done, and how it's judged

- **A/B sheets for Sean:** the woodwork today's way (the game's woods, square edges) against the
  kit in the interior stain, under the saloon's lamps and the other two lights.
- **The measures:** the woodwork's L*, C* and hue under the saloon's lamps against the picture's
  numbers above, and against the men's range.
- **The blind critic**, two questions a crop: "Do the man and the woodwork look like the same
  painting?" and, with the picture's crops beside it, "Is this the same woodwork as the reference:
  its shapes, its colour?"
- **Done** when Sean picks: the stain goes into the game's woods (with a golden view), the kit is in
  `src/art/profiles.gd` with tests (every piece closed, its ends in end grain, sizes as above), and
  the saloon session is told what to build with.

## Cost

Free (grading and geometry). A paid painting only with Sean's OK and its cost first.
