# Cheap judge, 2026-11-09_cheap_matlib_r3e

## a
- 1 Flat light: PASS (`0 840 400 240`: a man's head shadow falls across the wall, the light has a side)
- 2 No atmosphere: N/A (a wall close up, no distance in frame)
- 3 Too clean: FAIL (`1100 100 400 900`; `a_smear.png`): plenty of grime, but it is the same grey smudge spread evenly over every board, no more dirt toward the foot, no splash line, no sun-bleach; it reads as a filter over the wall rather than weather
- 4 Too straight: FAIL (`400 0 1100 1080`; `a_straight.png`): boards and battens dead straight, equal widths, no cup, warp or gap
- 5 Floating objects: N/A (no meeting with the ground in frame)
- 6 Repetition: FAIL (`880 640 200 120`; `a_weave.png`): the pale patches break into a grid of little square blocks, a canvas-weave dither repeated all over the wall
- 7 Empty: FAIL (`1780 250 140 830`; `a_void.png`): the wall stands against flat untextured beige
- 8 Scale tells: PASS (nail heads and board widths plausible)
- 9 Edges of the world: FAIL (`1780 250 140 830`; `a_void.png`): the ground beyond is a blank beige plane
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Smudged, blocky grime** (tell 6, `880 640 200 120`): up close the weathering turns into soft blurred blots stamped with a square grid of pixels, like an upscaled low-res texture. Cause: material. Cheapest fix: a sharper source for the grime layer at this distance (or detail-normal grain over it) so the squares and the blur stop showing.
2. **Weather with no story** (tell 3, `1100 100 400 900`): dirt is even from top to bottom and board to board; nothing says rain, ground splash or sun. Cause: material. Cheapest fix: a vertical gradient of grime heavier at the foot and bleached at the top.
3. **Ruler-straight boards** (tell 4, `400 0 1100 1080`): every board the same width and perfectly true. Cause: geometry. Cheapest fix: vary board widths and add a slight bow/twist per board.
4. **Seams with no depth** (tell 6, `1380 300 200 500`): the gaps read as drawn rust-orange lines, not shadowed grooves. Cause: material. Cheapest fix: darken the groove into an occlusion line instead of an orange tint.
5. **Blank beige beyond** (tell 9, `1780 250 140 830`): the world at the edges is untextured sand colour. Cause: dressing. Cheapest fix: a textured ground with pebbles and tracks.

## b
- 1 Flat light: PASS (`0 780 380 300`: a cast shadow, the bevels catch light on one side)
- 2 No atmosphere: N/A (a wall close up)
- 3 Too clean: FAIL (`1100 100 400 600`; `b_smear.png`): heavy grime but uniform and smeared, no wear gradient toward the base
- 4 Too straight: FAIL (`600 0 900 1080`; `b_straight.png`): every board and batten true and evenly spaced
- 5 Floating objects: N/A (no ground contact in frame)
- 6 Repetition: FAIL (`1150 380 200 160`; `b_weave.png`): the same canvas-weave square dither in the light patches
- 7 Empty: FAIL (`1830 550 90 500`; `b_void.png`): blank beige beside the wall
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`1830 550 90 500`; `b_void.png`): untextured ground at the edge
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Rust-orange outlines on every edge** (tell 3, `1380 200 250 400`): each board's bevel is traced with a bright orange stripe of the same width the whole length, like an outline drawn on, toy-like. Cause: material. Cheapest fix: kill the orange edge tint; let the bevel show by light and a little lighter worn wood only where hands and weather reach.
2. **Smeared grime** (tell 3, `1100 100 400 600`): the weathering is soft brush-blur with no crisp grain, splits or nail streaks except on the right board. Cause: material. Cheapest fix: carry the crisp crack detail of the rightmost board (`1560 0 360 1080`) across all boards.
3. **Square dither in the pale patches** (tell 6, `1150 380 200 160`): a little grid of blocks shows through the light grime. Cause: material. Cheapest fix: higher-resolution or filtered grime mask.
4. **Perfectly true boards** (tell 4, `600 0 900 1080`). Cause: geometry. Cheapest fix: per-board width and bow variation.
5. **Blank beige edge** (tell 9, `1830 550 90 500`). Cause: dressing. Cheapest fix: textured ground.

## c
- 1 Flat light: PASS (`50 540 700 300`: long low-sun shadows with a clear direction)
- 2 No atmosphere: FAIL (`0 30 800 360`; `c_mesa.png`): the far mesa is as sharp, saturated and contrasty as the foreground; no haze
- 3 Too clean: FAIL (`750 250 570 560`; `c_pine.png`): bright, brand-new pine with showroom grain, no dirt, sun-greying or wear; the sand around its base spotless
- 4 Too straight: FAIL (`690 600 740 340`; `c_bench.png`): every plank, rail and post square and plumb
- 5 Floating objects: FAIL (`420 550 300 90`; `c_rocks.png`): the green boulders are flat-shaded blobs with no contact shadow, pasted on the sand
- 6 Repetition: FAIL (`1320 380 600 80`; `c_pebbles.png`): the same green lozenge rock repeated in an even scatter across the plain
- 7 Empty: FAIL (`0 600 500 480`; `c_empty.png`): bare flat sand, a lone panel, a man in a vest and underpants; nothing to say anyone lives or works here
- 8 Scale tells: PASS (the man, the bench at his waist and the panel agree)
- 9 Edges of the world: FAIL (`1310 290 610 110`; `c_horizon.png`): the mesa and hills are a painted card sitting on a perfectly flat beige floor; a hard seam where they meet
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Lumber-yard pine** (tell 3, `750 250 570 560`): the panel looks like a new fence kit from a store, glowing yellow, every board the same clean colour. Cause: material. Cheapest fix: grey the sun side and dirty the lower 30 cm.
2. **Flat sand to a painted card** (tell 9, `1310 290 610 110`): the ground is one untextured beige plane ending at a backdrop; no track, no grass, no fall-off. Cause: dressing. Cheapest fix: a textured ground with scrub and ruts that runs into the backdrop's foot.
3. **Pasted green rocks** (tell 5, `420 550 300 90`): low-poly, flat green, no shadow under them. Cause: geometry. Cheapest fix: replace with shaded rock meshes that sit in the sand with contact shadow.
4. **No air** (tell 2, `0 30 800 360`): the mesa miles off is as crisp and orange as the panel. Cause: light. Cheapest fix: aerial haze that lifts and desaturates the far distance.
5. **Half-dressed man in an empty plain** (tell 7, `490 340 230 540`): vest, underpants, bare feet, nothing around. Cause: people. Cheapest fix: dress him (trousers, boots) and put one prop of work by the panel.

## d
- 1 Flat light: PASS (`0 760 380 320`: a hard cast shadow, side light)
- 2 No atmosphere: N/A (a wall close up)
- 3 Too clean: FAIL (`400 30 1500 900`; `d_clean.png`): clean pinkish new board, the same tone from end to end, no dirt or weather
- 4 Too straight: FAIL (`400 30 1500 900`; `d_clean.png`): ruler-level laps, even spacing; nail dots on a neat grid
- 5 Floating objects: N/A
- 6 Repetition: FAIL (`0 230 1920 120`; `d_sawtooth.png`): a row of identical saw-tooth marks repeats along every lap edge like a stamped pattern
- 7 Empty: FAIL (`1800 0 120 600`; `d_void.png`): a bare wall against blank beige
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`1700 600 220 480`; `d_stepped.png`): the board ends step down in a jagged staircase against the blank beige beyond
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Saw-tooth artefact along every lap** (tell 6, `0 230 1920 120`): each board's lower edge carries a repeating row of little dark hooks, like a broken relief/parallax effect. It reads as a bug. Cause: material. Cheapest fix: turn off or fix the relief on the lap edge so it is one clean shadow line.
2. **New, uniform wood** (tell 3, `400 30 1500 900`): pink-tan pine with no weather, the same everywhere. Cause: material. Cheapest fix: a weathering pass (grey on top, grime at the foot).
3. **Square weave in the grain** (tell 6, `700 600 300 120`; `d_weave.png`): the surface carries a fine grid texture like canvas. Cause: material. Cheapest fix: filter or replace the detail layer.
4. **Staircase board ends** (tell 9, `1700 600 220 480`): the right edge jags like stacked cards against beige. Cause: geometry. Cheapest fix: a corner board/trim to close the ends.
5. **Grid-placed nails** (tell 4, `800 30 1100 900`): nail heads in neat columns. Cause: material. Cheapest fix: jitter nail positions per board.

## e
- 1 Flat light: PASS (`0 540 720 400`: low sun, long shadows, the siding's top lit warm, the bench shades the deck)
- 2 No atmosphere: FAIL (`0 30 780 360`; `e_mesa.png`): the far mesa crisp and saturated, no haze
- 3 Too clean: FAIL (`700 880 720 100`; `e_base.png`): the deck sits on spotless sand; no dust drift, no dirt on the posts' feet
- 4 Too straight: FAIL (`745 230 570 380`; `e_level.png`): siding laps perfectly level and evenly spaced
- 5 Floating objects: PASS (`700 800 720 150`: contact shadow under the deck)
- 6 Repetition: FAIL (`1350 390 570 60`; `e_pebbles.png`): the same green rock scattered evenly; and an identical orange stripe on every siding seam (`750 440 560 160`; `e_seams.png`)
- 7 Empty: FAIL (`1420 450 500 600`; `e_empty.png`): bare sand plain
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`1310 290 610 110`; `e_horizon.png`): painted backdrop on a flat beige floor, seam at the foot of the hills
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **One leg a different colour** (tell 8, `580 600 100 280`; `e_leg.png`): the man's left leg is dark red-brown, as if painted with a different skin or a shadow stuck to it, while the other leg is pale and lit. Cause: people. Cheapest fix: check his leg's material/shadow; it should match the other leg.
2. **Glowing orange seams** (tell 6, `750 440 560 160`): every lap seam is the same bright orange line, reading as drawn rather than shadowed. Cause: material. Cheapest fix: seams as dark occlusion, not an orange tint.
3. **Flat sand to a backdrop** (tell 9, `1310 290 610 110`). Cause: dressing. Cheapest fix: textured ground with scrub running into the backdrop.
4. **No air** (tell 2, `0 30 780 360`). Cause: light. Cheapest fix: distance haze.
5. **Clean sand at the base** (tell 3, `700 880 720 100`): nothing kicked up against the deck. Cause: dressing. Cheapest fix: a dust/dirt decal along the base.

## f
- 1 Flat light: PASS (`690 790 720 150`: strong shadow on the deck, low sun)
- 2 No atmosphere: FAIL (`0 30 780 360`; `f_mesa.png`): far mesa sharp and saturated
- 3 Too clean: FAIL (`750 260 560 300`; `f_mahogany.png`): smooth red mahogany like indoor furniture panelling, uniform, no weather; the board grooves fade out in a soft horizontal band halfway down (`750 480 560 80`)
- 4 Too straight: FAIL (`690 560 740 380`; `f_bench.png`): plumb posts, level rail, even boards
- 5 Floating objects: PASS (deck has contact shadow)
- 6 Repetition: FAIL (`1350 390 570 60`; `f_pebbles.png`): the same green rock repeated
- 7 Empty: FAIL (`1420 450 500 600`; `f_empty.png`): bare sand
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`1310 290 610 110`; `f_horizon.png`): painted backdrop on flat beige floor
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Furniture wood in the desert** (tell 3, `750 260 560 300`): polished red hardwood, the look of a sauna or a sideboard, out in the sun with no weathering. Cause: material. Cheapest fix: a weathered, sun-greyed wood for outdoors; keep this one for indoors.
2. **Grooves that fade in a band** (tell 3, `750 480 560 80`): halfway down the wall the board lines soften and vanish, a rendering/texture seam. Cause: material. Cheapest fix: fix the mip/detail fade so grooves hold their strength.
3. **Flat sand to a painted card** (tell 9, `1310 290 610 110`). Cause: dressing. Cheapest fix: textured ground into the backdrop.
4. **No air** (tell 2, `0 30 780 360`). Cause: light. Cheapest fix: distance haze.
5. **Repeated green rocks** (tell 6, `1350 390 570 60`). Cause: dressing. Cheapest fix: vary rock shapes, sizes and colours.

## g
- 1 Flat light: FAIL (`600 300 700 500`; `g_black.png`): the frame is crushed nearly black with a faint red cast; you cannot see where the light is or what the surface is
- 2 No atmosphere: N/A (a wall close up)
- 3 Too clean: N/A (too dark to read)
- 4 Too straight: FAIL (`700 0 800 1080`; `g_straight.png`): the only readable thing is evenly spaced straight seam lines
- 5 Floating objects: N/A
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 600 900 480`; `g_empty.png`): nothing to look at
- 8 Scale tells: N/A
- 9 Edges of the world: N/A (only a sliver of something at `1710 1050 210 30`)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **A black screen** (tell 1, `600 300 700 500`): the wall is lit so low it reads as a broken frame, faint wine-red grain barely there. Cause: light. Cheapest fix: a fill or bounce so the dark wood keeps a readable midtone.
2. **Red cast in the blacks** (tell 1, `0 0 900 600`): the darks are tinted red instead of neutral, making it look like a colour error. Cause: material. Cheapest fix: lower the red saturation of this stain in shade.
3. **Only straight lines readable** (tell 4, `700 0 800 1080`). Cause: geometry. Cheapest fix: board width variation so the pattern isn't a ruler.
4. **Nothing in frame** (tell 7, `0 600 900 480`). Cause: camera. Cheapest fix: frame the wall with something lit beside it.
5. **Grain invisible** (tell 1, `300 0 400 1080`): the only grain detail is a faint brighter streak on two boards. Cause: light. Cheapest fix: raise exposure/fill as in 1.

## h
- 1 Flat light: PASS (`300 860 1600 120`: hard, directional shadows of the rail across the deck), but the shadow edges are saw-toothed (`1700 400 220 560`; `h_jaggies.png`)
- 2 No atmosphere: N/A (no distance in frame)
- 3 Too clean: FAIL (`350 650 1250 400`; `h_deck.png`): the dark stained deck is uniform and glossy, no grit, no tread wear where feet go, no dust in the gaps
- 4 Too straight: FAIL (`0 470 1920 200`; `h_rail.png`): the rail a perfect box, deck boards ruler-straight and evenly gapped
- 5 Floating objects: PASS (the rail and posts shadow the deck)
- 6 Repetition: FAIL (`450 880 1100 170`; `h_boards.png`): the deck boards near-identical in tone and grain one after another
- 7 Empty: FAIL (`0 0 450 400`; `h_empty.png`): blank beige ground around the deck
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`1700 400 220 560`; `h_jaggies.png`): untextured beige floor with stair-stepped shadow edges
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Jagged shadow edges on blank ground** (tell 9, `1700 400 220 560`): the sun's shadows have visible saw-teeth on a flat beige floor; a tech-demo look. Cause: light. Cheapest fix: softer filtering/higher resolution on the near shadow cascade, and a textured ground.
2. **Showroom deck** (tell 3, `350 650 1250 400`): even dark stain, no scuffing or dust in the gaps. Cause: material. Cheapest fix: lighter worn paths and dirt in the board gaps.
3. **Lumpy dark leg** (tell 8, `0 200 320 620`; `h_leg.png`): the man's leg at the edge is a dark, lumpy, nearly untextured shape. Cause: people. Cheapest fix: check his skin shading in shade (it goes muddy).
4. **Box-perfect rail** (tell 4, `0 470 1920 200`). Cause: geometry. Cheapest fix: rounded, worn arrises and a slight sag.
5. **Repeated boards** (tell 6, `450 880 1100 170`). Cause: material. Cheapest fix: vary each board's tone and grain offset.

## Ranking
From least to most cheap-looking: e, h, b, a, c, f, d, g

## Man and wood
- c: NEARLY. The wood is bright, brand-new store pine, cleaner and more saturated than the man; it looks like a product shot beside a game character (`750 250 570 560`).
- e: NEARLY. The weathered grey siding is the closest to his gritty realism; what separates them is the bright orange seam stripes drawn on every lap, a painted touch next to his realistic skin (`750 440 560 160`).
- f: NO. Polished red mahogany panelling, furniture-grade and spotless, beside a rough bearded outdoorsman; the wood belongs in a parlour render, not his world (`750 260 560 300`).
