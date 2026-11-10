# Cheap judge, 2026-11-08_cheap_matlib_rough_r2

## a
- 1 Flat light: PASS (`0 500 1280 220`: the noon sun throws hard, readable shadows from the man, rail and decks; the shade side of each board is a little lifted but the light has a direction)
- 2 No atmosphere: FAIL (`230 230 300 50`; `a_a_sharp_mesa.png`: the far mesa and the stones on the flat are as crisp and saturated as the near boards; no heat haze or dust anywhere)
- 3 Too clean: FAIL (`495 165 385 460`; `a_a_clean_wall.png`: the centre wall is one even brown from top to bottom; no darker foot where it meets the deck, no sun-bleached tops, no splits or worn edges; the deck's front edge is knife-clean)
- 4 Too straight: FAIL (`495 165 385 460`; `a_a_clean_wall.png`: every board plumb and dead flat, the rail ruler-level, the deck's corners square; only the board tops vary a little)
- 5 Floating objects: PASS (`455 590 500 50`: the decks cast a thin shadow on the sand and the man's boots have shadows; the contact is hard but present)
- 6 Repetition: FAIL (`0 180 245 370`; `a_a_left_grain.png`: the left panel's boards carry the same loud figured grain, swirl for swirl, like one printed photo strip reused)
- 7 Empty: N/A (the test area's emptiness is the setup)
- 8 Scale tells: PASS (`320 220 560 380`: the man is about right against a 2 m wall and a hip-high rail; the left panel's grain figure is a touch large for a pine board)
- 9 Edges of the world: N/A (test area)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **The wood is a clean texture on flat boxes** (tell 3, `495 165 385 460`): the centre wall reads as a stock "old wood" texture on perfectly flat boards, the same tone from top to bottom, with no weather where rain and sun would hit it. Cause: material. Cheapest fix: a darker, dirtier band along the bottom 20-30 cm of each board and bleached, split top ends.
2. **Photo grain repeated board to board** (tell 6, `0 180 245 370`): the left panel's loud cathedral grain looks like one photo tile repeated, and it is far stronger than anything else in the frame. Cause: material. Cheapest fix: offset and flip the grain for each board and turn its contrast down by half.
3. **Ruler-straight joinery** (tell 4, `460 400 490 230`): the rail is dead level, the posts dead plumb, the deck boards perfectly parallel; nothing has sagged or cupped. Cause: geometry. Cheapest fix: a few mm of cup across each board and a slight sag in the rail between posts.
4. **No air** (tell 2, `230 230 300 50`): the mesa behind is as sharp as the boards, so the light reads as a studio, not a hot desert noon. Cause: light. Cheapest fix: a warm aerial haze that softens and lightens everything past ~100 m.
5. **Hard, unbroken contact** (tell 5, `455 590 500 50`): the decks sit on the sand with a crisp drop shadow but no sand drifted against them or dust on the lower boards. Cause: dressing. Cheapest fix: dust and sand blown onto the deck's lower edge and the boards' feet.

## b
- 1 Flat light: PASS (`0 430 760 290`: a warm low sun and the rail's crisp cast shadow; the light clearly comes from behind the camera, low)
- 2 No atmosphere: N/A (a close-up of one wall)
- 3 Too clean: FAIL (`0 0 700 420`; `b_b_noise_weave.png`: the "wear" is an even speckle spread uniformly over every board, reading like canvas or sandpaper, not dirt that gathers in grain, ends and edges)
- 4 Too straight: FAIL (`700 0 580 720`: board edges ruler-straight and parallel, no cupping, splits or uneven gaps)
- 5 Floating objects: N/A (nothing meets the ground in frame)
- 6 Repetition: FAIL (`0 0 700 420`; `b_b_noise_weave.png`: the same fine cross-hatch weave and black dashes on every board; the boards differ only in tint)
- 7 Empty: N/A (the test area's emptiness is the setup)
- 8 Scale tells: FAIL (`0 0 700 420`; `b_b_noise_weave.png`: the texture's grain is a fine woven mesh, the scale of cloth, not of a sawn board seen from a metre)
- 9 Edges of the world: N/A (test area)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Boards that look like burlap** (tell 8, `0 0 700 420`): up close the surface is a cross-hatched weave with speckles, and a player reads canvas or a noise filter, not wood fibre. Cause: material. Cheapest fix: replace the high-frequency noise with long, lengthwise grain streaks that follow the board.
2. **Uniform speckle as "wear"** (tell 3, `0 0 700 420`): the dark flecks are spread evenly over every square cm; real weathering pools at ends, nail holes and the lower edge. Cause: material. Cheapest fix: mask the grime by where water runs: heavier toward board ends and the bottom, near none in the middle.
3. **One board in candy orange** (tell 3, `860 0 140 720`; `b_b_orange_board.png`): a single plank is a saturated orange that looks freshly varnished next to grey-brown neighbours. Cause: material. Cheapest fix: pull its saturation down to the others' and let the variation be in value, not hue.
4. **Same pattern on every plank** (tell 6, `220 0 560 720`): the boards are tinted copies of one texture; the flecks and weave line up in character. Cause: material. Cheapest fix: per-board offsets and two or three distinct source boards.
5. **Ruler edges** (tell 4, `700 0 580 720`): every joint is a perfect straight line; no split ends, no warped board standing proud. Cause: geometry. Cheapest fix: one or two boards slightly twisted or proud, and a few split ends.

## c
- 1 Flat light: PASS (`0 0 1280 720`: two lamps pool light on the wall and fall to black; the shadows of the rail and deck lie on the floor)
- 2 No atmosphere: FAIL (`380 60 650 220`; `c_c_hotspots.png`: the lamps are bright spots on the back wall with a bloom halo; no air, smoke or dust catching the light between them and the panel)
- 3 Too clean: FAIL (`495 165 385 370`; `c_c_veneer.png`: the wall is fresh, honey-coloured, flat-sawn pine with crisp cathedral grain; no grime, no age, no wear at all, like new plywood)
- 4 Too straight: FAIL (`460 400 490 230`: the rail and deck are dead level and square; the board tops vary but nothing leans or sags)
- 5 Floating objects: PASS (`460 600 500 100`: the deck's shadow lies under it on the floor)
- 6 Repetition: FAIL (`495 165 385 370`; `c_c_veneer.png`: the same arched figure appears on several boards, reading as one veneer photo cut into strips)
- 7 Empty: N/A (the test room's emptiness is the setup)
- 8 Scale tells: PASS (`320 220 630 400`: the man and the 2 m wall agree)
- 9 Edges of the world: N/A (test room)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Brand-new plywood, not old boards** (tell 3, `495 165 385 370`): bright, glossy-looking pine with crisp cathedral figure; it reads as a home-improvement-store panel, nothing a frontier town would have weathered. Cause: material. Cheapest fix: darken and desaturate the wood, and lose the strong figure in favour of plain straight grain with grime.
2. **The man isn't lit by the lamps that light the wall** (tell 1, `320 220 150 380`; `c_c_man_dark.png`): he stands a step from a brightly lit panel, yet his face and legs fall to near black and his feet are lost. Cause: light. Cheapest fix: let the lamps' falloff reach him (or move him into the pool) so wall and man share the light.
3. **Lamp spots on a wall with no air** (tell 2, `380 60 650 220`): two clean bloom discs on the back wall; no haze, so the light looks like a photo studio's. Cause: light. Cheapest fix: a faint room haze that lifts in the cones under each lamp.
4. **Veneer cut into strips** (tell 6, `495 165 385 370`): the arched figure repeats across boards. Cause: material. Cheapest fix: distinct grain per board, offset and flipped.
5. **A pale plane for a floor** (tell 3, `300 535 850 185`): the floor under the panel is a flat light grey slab, untextured, which makes the panel look placed on a tabletop. Cause: material. Cheapest fix: a dark, worn floor texture, or at least a value close to the room's.

## d
- 1 Flat light: PASS (`0 360 1280 360`: low golden sun, long raking shadows across the sand and the rail's shadow on the wall)
- 2 No atmosphere: FAIL (`0 0 520 260`; `d_d_sharp_mesa.png`: the mesa is sharp and saturated orange at golden hour; no dust or haze in the low sun)
- 3 Too clean: FAIL (`490 170 395 360`; `d_d_bleached.png`: the horizontal boards are one even pale tan, nearly flat colour, with tiny flecks; no grime at the foot, no darker weather streaks below the nails)
- 4 Too straight: FAIL (`490 170 395 360`; `d_d_bleached.png`: perfectly horizontal laps, level rail, square deck)
- 5 Floating objects: PASS (`465 600 490 40`: the deck shades the sand under it; the man's boots carry shadows)
- 6 Repetition: FAIL (`490 170 395 360`; `d_d_bleached.png`: every lap board the same flat tan with the same fine streaks; the dots of the nails in a regular grid)
- 7 Empty: N/A (the test area's emptiness is the setup)
- 8 Scale tells: PASS (`320 220 560 400`)
- 9 Edges of the world: N/A (test area)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **The wall looks like painted MDF** (tell 3, `490 170 395 360`): pale, even, nearly grainless boards; at a glance it reads as a flat colour with noise, not sun-bleached timber. Cause: material. Cheapest fix: give the bleached wood stronger grain and darker weather streaks running down from each lap and nail.
2. **Thin light lines between the laps** (tell 4, `490 240 395 220`; `d_d_bleached.png`): the seams between boards show as broken pale and dark slivers that start and stop, like z-fighting rather than a shadowed lap. Cause: geometry. Cheapest fix: a continuous dark shadow line under each lap's lower edge.
3. **No dust in the golden light** (tell 2, `0 0 520 260`): a low desert sun with a crystal-clear mesa behind; the moment begs for warm haze. Cause: light. Cheapest fix: warm aerial haze and a faint dust glow toward the sun.
4. **Every board alike** (tell 6, `490 170 395 360`): one tan, one streak pattern, nails in a grid. Cause: material. Cheapest fix: per-board value shifts and a few irregular nail spacings.
5. **Perfect carpentry** (tell 4, `460 400 490 230`): the laps, rail and deck are machine-true. Cause: geometry. Cheapest fix: let one or two laps droop or curl at an end.

## e
- 1 Flat light: PASS (`0 460 260 260`: a hard cast shadow at lower left and dark lines under each board's edge give the light a direction; the faces themselves are evenly lit)
- 2 No atmosphere: N/A (a close-up)
- 3 Too clean: FAIL (`0 300 1280 400`; `e_e_tweed.png`: the lower boards are covered edge to edge in a uniform fine speckle that reads as tweed fabric; no wear concentrated at ends or edges)
- 4 Too straight: PASS (`0 300 1280 420`: the lower boards sit at slightly different angles and lengths, overlapping unevenly)
- 5 Floating objects: N/A (nothing meets the ground in frame)
- 6 Repetition: FAIL (`0 90 1280 220`; `e_e_smear.png`: the second board is long horizontal streaks that look like a texture stretched along the board, repeating as identical lines from end to end)
- 7 Empty: N/A (the test area's emptiness is the setup)
- 8 Scale tells: FAIL (`0 300 1280 400`; `e_e_tweed.png`: the surface pattern is at the scale of woven wool, not of sawn wood)
- 9 Edges of the world: N/A (test area)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Wood that reads as tweed** (tell 8, `0 300 1280 400`): grey-brown boards with a fine woven fleck all over; a player sees upholstery, not weathered planks. Cause: material. Cheapest fix: replace the fine noise with lengthwise silvered grain and checks a few mm wide.
2. **A stretched, streaky board** (tell 6, `0 90 1280 220`): the second board is a smear of horizontal lines with no knots or fibre breaks, like a texture pulled across a long face. Cause: material. Cheapest fix: map that board's texture at the same density as its neighbours and break the streaks with a knot or check.
3. **Uniform grime** (tell 3, `0 300 1280 400`): the flecks are the same density over every board. Cause: material. Cheapest fix: concentrate weathering at board ends and lower edges, leave the middles plainer.
4. **Bright sand showing through seams** (tell 3, `0 80 1280 20`): a pale cream line along the top board's edge looks like an unlit gap or a missing back, a flat colour against the dark wood. Cause: geometry. Cheapest fix: close the gap or put a dark backing behind the boards.
5. **Even light across the faces** (tell 1, `0 300 1280 300`): apart from the cast shadow, each board is one value end to end; no raking light to show the surface. Cause: light. Cheapest fix: a normal or height map so the grain catches the light.

## f
- 1 Flat light: PASS (`0 0 1280 720`: lamps pool on the upper wall and fall off into deep shadow; blacks are black)
- 2 No atmosphere: FAIL (`380 60 650 220`; `f_f_hotspots.png`: the lamps are bloom discs on the back wall with no haze between them and the panel)
- 3 Too clean: FAIL (`460 525 490 110`; `f_f_deck.png`: the deck boards are tidy and even; no dirt at the wall's foot or tracked across the deck)
- 4 Too straight: PASS (`490 165 395 370`; `f_f_wall.png`: the laps have different widths and lengths, the top boards overhang unevenly; it reads as hand-nailed)
- 5 Floating objects: PASS (`460 600 500 100`: the deck's shadow falls on the floor beneath it)
- 6 Repetition: PASS (`490 165 395 370`; `f_f_wall.png`: the boards differ in tone and figure, one carries a knot)
- 7 Empty: N/A (the test room's emptiness is the setup)
- 8 Scale tells: PASS (`320 220 630 400`)
- 9 Edges of the world: N/A (test room)
- 10 Stiff people: N/A (a still)
- **Verdict: good indie**
1. **The man stands outside the light** (tell 1, `320 220 150 380`; `f_f_man.png`): the wall beside him is warmly lit but he is dim, his legs and feet lost in black. Cause: light. Cheapest fix: extend the nearest lamp's falloff to him so both share one pool.
2. **No air in the lamplight** (tell 2, `380 60 650 220`): spots on the back wall, but the space in front is clear. Cause: light. Cheapest fix: a faint haze lit under each lamp.
3. **Grain is a fine noise under the warm light** (tell 3, `490 165 395 370`; `f_f_wall.png`): close up the figure is a busy fleck rather than fibres; at this distance it passes, nearer it won't. Cause: material. Cheapest fix: longer, softer grain lines and fewer high-frequency flecks.
4. **A clean deck** (tell 3, `460 525 490 110`): the deck and the wall's foot have no dirt or scuff. Cause: dressing. Cheapest fix: a darker, dirtier band where the wall meets the deck and scuffs on the deck's front edge.
5. **A pale slab floor** (tell 3, `330 535 820 185`): the room's floor is a flat light grey plane, which pulls the eye and makes the panel look set on a tabletop. Cause: material. Cheapest fix: a dark, textured floor.

## Ranking
From least to most cheap-looking: f, d, a, c, b, e

## The man and the wood
- **a** (shows the man): **partly.** The man is a smooth, painted-looking figure with clean cloth and crisp edges; the wood beside him is a noisy photographic texture with far more fine detail per metre, so they read as two art styles; both are clean, with no wear or dust on him or on the boards, and the sun sits on both the same way.
- **c** (shows the man): **no.** The wall glows honey-bright under the lamps while he, a step away, is nearly black; the wood is fresh, saturated pine and he is dark, matte, painted cloth; the light that falls on one doesn't reach the other.
- **d** (shows the man): **partly.** The golden sun sits on both alike, but his waistcoat and boots are richly coloured and painted smooth, with stair-stepped, posterised shadow edges on his trousers (`d_d_man.png`), while the wall is pale, flat, finely flecked tan; he looks sharper and more saturated than the wood.
- **f** (shows the man): **partly, closest of the four.** The warm lamplight and the brown palette tie him to the wood, and the wood's age suits him, but he is still lit much dimmer than the panel beside him, and his smooth painted cloth has less fine detail than the flecked boards.
- **b, e:** no man in frame.

Overall: the man and the wood come from two different hands (a smooth, painted, stylised figure beside noisy, photo-sourced board textures), and where lamps light the wood they often fail to light him; f's aged boards under warm light come nearest to one game.
