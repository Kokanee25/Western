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

## Results

### Round 1 (2026-10-21)

Built: `Profiles`, `MaterialStand._profiled` / `_take`, `InteriorStand` (`--material=interior` and
`interior_square`), the interior stain set `studio_int` (floor, timber and the wall boards from
studio5's paintings, the dark oak from the stair's painting Sean picked, all graded to one umber
target with `grade_all.target`; the floor darker). Free. Indoors the lab's lamps are drawn and cast
shadows; the stand has a ceiling.

Sheet `docs/screenshots/material_lab/2026-10-21/interior/sheet_abc.jpg`: A square in the game's
woods, B profiled in the game's woods, C profiled in the interior stain, six views (the corner,
the bar, a post and its brackets, the wainscot and window, along the gallery, up at the gallery),
three lights.

The blind critic (`interior/critic.md`, two questions a crop, Sean's picture's woodwork as the
second reference): **C 1 SAME / 5 CLOSE / 0 DIFFERENT as the same painting as the men, 6 CLOSE /
0 DIFFERENT as the picture's woodwork**; A and B (the game's woods, square or profiled) DIFFERENT on
the second question every time. The stain is what carries it: the critic's first difference is
the game's pale, striped woods. Its others: photographic grain (the game's knotty pine), the
joinery not reading at the crops' distance under these lamps (the panels, chamfers and the bar's
nosing are there but small), the balusters crowded, the floor pale (it faces the open night sky
on the lab's bench; the room's own light is the saloon session's).

Measures under the saloon's lamps: the stain's hue 45 and chroma ~12-16 sit on the picture's
(hue ~45, chroma ~20); its lightness is lower (median ~6-9 against ~20), as the men's is (median
~4.5) in the lab's dim lamps.

### What's next

1. **Sean's pick** on the sheet: the interior stain (C) or changes to it.
2. Then, free: balusters spaced as the picture's (fewer, more light between), the bar's top and
   panels bolder, chamfer stops on the posts, the back bar's columns turned; the floor checked under
   a roof (it reads pale under the open sky).
3. On his pick: the stain into the game's woods as interior woods (their own keys, so the exterior
   woods don't change), `Profiles` and the pieces documented for the saloon session, a golden view
   of the interior stand.

### Round 2: the bar and back bar as parts (2026-10-21)

Sean picked C ("go with C for now") and asked for "any art you feel would be beneficial for our
saloon". Promoted: the interior woods (`int_*`, PR #208). Made, free:

- **Kit draw shapes for woodwork:** a kit member can be drawn as a `profile` (a moulding run along it),
  a `panel` (raised) or a `cut` (a board cut to an outline), from `Profiles` (`PropKit.woodwork_mesh`;
  `Profiles.extrude_tris`/`panel_tris`/`cut_tris`/`to_mesh`, which the stands use too).
- **The bar top's wood** `int_bar_top` (`tools/textures/bar_top.py`): `int_oak` glued up across 0.84 m,
  dark rings and pale blooms where men stand, the front edge worn by elbows, an oiled sheen.
- **The bar** (`assets/props/kit/bar.json`, 3 m, 30 members): tall raised panels under a frieze of short
  ones between chamfered pilasters, plinth, corbels, the top with its bullnose, a brass foot rail.
- **The back bar** (`back_bar.json`, 2.5 m, 44 members): panelled base and counter, three heavy columns
  with bases and capitals, two arched frames and mirrors (`prop:mirror`, a low warm glow: the room
  it gives back), shelves on brackets, frieze, dentils, ogee cornice, cap.
- Both are fixtures (`"fixture": true`, they replace no drawn prop), stand and batch within the kit's
  rules (`tests/test_prop_kit.gd`), and the interior stand now uses them (views `back_bar`, `bar_top`).

Blind critic against the picture (`docs/screenshots/material_lab/2026-10-21/bar/`; round 1 in
`round1/`): **round 1** bar front DIFFERENT, top CLOSE, back bar DIFFERENT (cherry red, black mirrors,
thin back bar with a crest the picture lacks, no frieze panels, lacquer gloss). Fixed: frieze panels,
heavier columns and a stepped entablature with no crest, the top warmer and oiled, the mirrors lit.
**Round 2**: the same verdicts; its first difference is now **value**: the woodwork in `int_oak` sits
near black against the walls (`int_boards`), the picture's bar is the walls' honey-brown. Then: the
mirrors flat ochre (want a painted reflection), the panels lost in the dark, fine grain where the
picture has big squares, the back bar still reads slight. Layout right both rounds.

### What's next (round 3)

1. **Sean's call:** the fixtures in a lighter oak (the walls' value), or `int_oak` as picked.
2. A painted reflection in the mirrors (lamps, the room's warm blur; free, procedural).
3. Coarser squares on the fixtures' woods (the texel size) and the panels' edges catching light.
4. For the saloon session: `PropKit.spawn(&"bar")` and `&"back_bar"` in place of `SaloonBuilding`'s
   hand-built bar, turned to face the room; bars longer than 3 m are sections side by side.

### Round 3: the mirrors (2026-10-22)

`prop:mirror` is painted, not flat ochre: `src/props/mirror.gdshader` reflects the view ray off the
glass into a box of a room in front of it (its far wall `room_depth` away, its ceiling) and paints
that room in squares: a warm smoky haze, sconce lamps (a chimney and a soft glow), posts, the
gallery's rail and balusters, the ceiling's beams, dark shapes of tables and men low down; the
room's light in steps, the lamps' soft. It slides across the glass as you move. Free (two plane
intersections a pixel; no probe, no second camera). Only the kit's back bar uses it (the interior
stand); the old saloon's mirrors (`SaloonDressing.mirror_material`) are left for the saloon session.

Blind critic (`docs/screenshots/material_lab/2026-10-22/mirror/critic.md`, against the picture's
back bar): round 2's glow DIFFERENT (backlit panels); the first pass DIFFERENT (a dark window, flat
discs); **the second CLOSE** (holds a room; the two views one room, the lamps shifting as parallax).
What's left: bottles on the shelves before the glass (the saloon's dressing), lamps as chimneys
rather than squares, smoother haze round them, and a gilt edge or bevel on the glass (a kit member
round the arch, not the shader).
