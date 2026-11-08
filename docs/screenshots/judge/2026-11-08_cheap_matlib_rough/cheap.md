# Cheap judge, 2026-11-08_cheap_matlib_rough

## a
- 1 Flat light: PASS (`460 400 500 230`: a hard sun from the left-front, the rail and the floor patch throw clean shadows, the board faces step in tone)
- 2 No atmosphere: FAIL (`10 30 520 230`; `a_a_mesa.png`): the mesa behind is nearly as crisp and saturated as the boards in front; little air between them
- 3 Too clean: FAIL (`490 470 420 160`; `a_a_base.png`): the floor patch and the foot of the wall have no grime, no darker band where the boards meet the floor, no worn tread; every board is weathered the same from top to bottom
- 4 Too straight: PASS (`495 165 385 20`: the board tops are ragged in height; the rail and floor are true but this is a fresh test panel)
- 5 Floating objects: PASS (`330 540 130 60`: the man's boots and the patch corners sit in their shadows)
- 6 Repetition: FAIL (`0 185 245 360`; `a_a_left_grain.png`): the left panel's boards carry the same oval flat-sawn figure, embossed the same depth, board after board
- 7 Empty: N/A
- 8 Scale tells: PASS (the man reads ~1.8 m against a ~2 m wall and a hip-high rail)
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Embossed laminate grain** (tell 6, `0 185 245 360`): the boards look like a wood-grain print pressed into a flat sheet: deep, even, same figure on each board, no checking, splits or end-grain. Cause: material. Cheapest fix: vary figure per board and drop the relief on the figure lines; add a few splits and nail rust.
2. **No dirt where wood meets ground** (tell 3, `490 470 420 160`): the floor patch and the wall's foot are as clean as the top; no splash, dust or darker damp band. Cause: material. Cheapest fix: a grime gradient up the bottom 30 cm of the wall and on the floor's edges.
3. **Distance as sharp as the near boards** (tell 2, `10 30 520 230`): the mesa and sky read as a clean backdrop. Cause: light. Cheapest fix: more aerial haze at range (desaturate and lift the mesa).
4. **Uniform weathering** (tell 3, `495 170 385 360`): the middle wall is one even brown with grey streaks; nothing bleached on the top edge, nothing darker low. Cause: material. Cheapest fix: sun-bleach the top edges and darken the lower third.
5. **The rail and posts too new** (tell 3, `460 400 490 220`): crisp square sections, no rounded worn edges where hands would go. Cause: geometry. Cheapest fix: bevel and darken the rail's top edge.

## b
- 1 Flat light: PASS (`0 430 760 290`: a warm low sun, a hard rail shadow across the boards, the boards' bevels catch it)
- 2 No atmosphere: N/A (a close-up of a wall face; no distance)
- 3 Too clean: FAIL (`0 0 700 440`; `b_b_speckle.png`): the surface is covered edge to edge in the same fine black-and-cream speckle; it reads as digital noise, not dirt, and is identical from board to board
- 4 Too straight: PASS (`1000 0 280 720`: the boards bow slightly and the seams wander)
- 5 Floating objects: PASS (`0 440 760 280`: the shadow lies on the boards, no gap)
- 6 Repetition: FAIL (`300 100 320 200`; `b_b_speckle_zoom.png`): the same speckle and vertical streak pattern repeats over every board
- 7 Empty: N/A
- 8 Scale tells: N/A
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Noise, not wood** (tell 3, `300 100 320 200`): up close the board is a field of single-pixel black and pale flecks, like a sandpaper filter or dithering; no fibre, no grain lines, no pores. Cause: material. Cheapest fix: replace the speckle with long fibre streaks along the grain and cut its contrast by half.
2. **Every board the same** (tell 6, `0 0 1280 440`): four boards, one treatment; no board darker, redder or more weathered than its neighbour. Cause: material. Cheapest fix: a per-board tint and wear offset.
3. **No edge wear** (tell 3, `1000 0 280 720`): the right board's arris is the only feature; the seams have no dirt packed in, no rounded edges. Cause: material. Cheapest fix: dark grime along the seams and lighter worn arrises.
4. **Orange wash** (tell 1, `0 0 1280 720`): the whole frame is one saturated ochre; the light has no cool side and the shadow is near black-brown. Cause: light. Cheapest fix: a cooler sky fill in the shadow.
5. **Hard-edged shadow with stair-steps** (tell 1, `0 440 760 60`): the rail's shadow edge is notched like a low-resolution shadow map. Cause: light. Cheapest fix: finer shadow resolution or a softer filter at this range.

## c
- 1 Flat light: FAIL (`300 540 860 180`; `c_c_floor.png`): the test floor is a pale, evenly lit slab and the panel face is lit flat from the front; the shadows on the floor are stair-stepped
- 2 No atmosphere: FAIL (`380 60 600 200`; `c_c_lamps.png`): the lamp glows are round blobs on the back wall with no haze or dust in the air between lamp and panel
- 3 Too clean: FAIL (`500 170 380 360`; `c_c_grain.png`): the panel is a showroom veneer, swirling figure over every board, no dirt, no wear, no damage
- 4 Too straight: PASS (`495 165 385 20`: ragged board tops)
- 5 Floating objects: PASS (`460 600 500 40`: the floor patch's shadow sits under it)
- 6 Repetition: FAIL (`500 170 380 360`): the same exaggerated oak swirls repeat in several boards
- 7 Empty: N/A
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Veneer, not old boards** (tell 3, `500 170 380 360`): the panel reads as polished furniture-grade oak laminate with cartoonishly strong figure; nothing about it says rough-sawn, weathered or old. Cause: material. Cheapest fix: tone the figure down sharply and add the age the daylight panels have.
2. **Man lost against a lit panel** (tell 1, `320 220 140 380`; `c_c_man.png`): the panel is the brightest thing in the room while the man beside it is nearly black from the waist down; light doesn't fall on both alike. Cause: light. Cheapest fix: let the same lamp reach him (or place the panel and man in one pool).
3. **Lamp blobs with no air** (tell 2, `380 60 600 200`): two soft discs painted on the back wall; no glow in the air, no beam. Cause: light. Cheapest fix: light volumetric haze near the lamps.
4. **Pale, flat floor slab** (tell 1, `300 540 860 180`): a bright grey-pink plane with jagged shadows. Cause: light. Cheapest fix: darker floor and filtered shadows.
5. **Same swirls repeated** (tell 6, `640 170 240 360`): several boards share the same oval figure. Cause: material. Cheapest fix: more grain variants per board.

## d
- 1 Flat light: PASS (`0 360 1280 300`: long low shadows across the sand, the rail's shadow on the wall)
- 2 No atmosphere: FAIL (`0 30 515 230`; `d_d_mesa.png`): the mesa in the low sun is as crisp as the panels; no warm haze at range
- 3 Too clean: FAIL (`490 170 395 360`; `d_d_cork.png`): the siding reads as cork board or particle board: a pale even field of brown flecks, no grain, no weathering pattern; one board (`495 200 385 60`) is a stripy plywood edge that matches nothing
- 4 Too straight: FAIL (`1115 155 165 360`; `d_d_level.png`): the stacked siding is dead level and evenly spaced, like a pallet
- 5 Floating objects: PASS (`340 560 120 50`: boots in their shadows)
- 6 Repetition: FAIL (`490 170 395 360`): the same fleck pattern on every board, the posts and the rail
- 7 Empty: N/A
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Cork, not wood** (tell 3, `490 170 395 360`): from a few metres the boards look like pin-board or chipboard; nothing reads as aged siding. Cause: material. Cheapest fix: replace the fleck with grain streaks running along each board.
2. **One board from another set** (tell 3, `495 200 385 60`): a single board of stripy plywood-like grain in a wall of flecked boards. Cause: material. Cheapest fix: one material family per wall.
3. **Pale and bloodless** (tell 1, `490 170 395 360`): in golden light the wall is a bleached beige with almost no value range, while the man next to it is rich and saturated. Cause: material. Cheapest fix: darker base tone and more value range in the wood.
4. **Pallet-straight stacking** (tell 4, `1115 155 165 360`): perfectly level, evenly spaced boards. Cause: geometry. Cheapest fix: slight cup, sag and uneven overlap per board.
5. **Crisp backdrop** (tell 2, `0 30 515 230`): the mesa as sharp as the near boards. Cause: light. Cheapest fix: warm aerial haze at range.

## e
- 1 Flat light: PASS (`0 460 260 260`: a hard curved shadow; the board edges catch the light)
- 2 No atmosphere: N/A (a close-up)
- 3 Too clean: FAIL (`0 320 1280 400`; `e_e_dither.png`): the lower boards are a dithered, posterised grey-brown speckle, the same everywhere; no grain, stains or wear
- 4 Too straight: PASS (`1150 450 130 270`: the board ends step and taper)
- 5 Floating objects: FAIL (`0 75 1280 40`; `e_e_gap.png`): a clean bright gap shows the background between the top boards, as if the boards don't touch or have no backing
- 6 Repetition: FAIL (`0 95 1280 215`; `e_e_bark.png`): the top board's deep ridges repeat in an even ripple along its length
- 7 Empty: N/A
- 8 Scale tells: N/A
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Posterised speckle** (tell 3, `0 320 1280 400`): the lower boards look like a low-colour dither, the leftover-squares look the game is moving away from. Cause: material. Cheapest fix: a smoother fibre texture with fewer, larger tonal steps.
2. **Bark on a plank** (tell 6, `0 95 1280 215`): the top board is crocodile-skin ridges, too deep and too regular for sawn wood, more like a generated bark pattern. Cause: material. Cheapest fix: cut the relief by two-thirds and add long grain lines.
3. **Light through the wall** (tell 5, `0 75 1280 40`): a bright band between boards, no shadow in the joint. Cause: geometry. Cheapest fix: close the gap or put a dark backer behind the siding.
4. **Two boards, two different worlds** (tell 3, `0 95 1280 400`): the ridged board and the speckled boards don't read as the same wood or age. Cause: material. Cheapest fix: one family per wall.
5. **No wear at the edges** (tell 3, `0 300 1280 30`): each board's lower edge is a clean dark line; no rot, no dirt caught at the laps. Cause: material. Cheapest fix: grime and weathering along each lap.

## f
- 1 Flat light: FAIL (`490 165 395 365`; `f_f_cork.png`): the panel face lit evenly from the front, a uniform orange field; the man in near dark beside it
- 2 No atmosphere: FAIL (`380 60 600 200`; `f_f_lamps.png`): round lamp glows on the wall, no air
- 3 Too clean: FAIL (`490 165 395 365`): flecked cork-board texture, no grain or age
- 4 Too straight: FAIL (`490 165 395 365`): level, evenly stacked boards
- 5 Floating objects: PASS (`460 600 490 40`: the patch's shadow is under it)
- 6 Repetition: FAIL (`490 165 395 365`): the same fleck everywhere, rail and posts included
- 7 Empty: N/A
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Cork board under lamplight** (tell 3, `490 165 395 365`): the siding reads as an orange foam or cork sheet; no grain, no old-wood character. Cause: material. Cheapest fix: grain streaks along each board, more value range.
2. **The panel lit, the man not** (tell 1, `315 225 150 380`; `f_f_man.png`): he's in darkness from the vest down while the panel glows. Cause: light. Cheapest fix: put both in the same lamp pool.
3. **Lamp blobs with no air** (tell 2, `380 60 600 200`): two discs on the back wall. Cause: light. Cheapest fix: a little haze near the lamps.
4. **Level and even** (tell 4, `490 165 395 365`): stacked like a pallet. Cause: geometry. Cheapest fix: per-board cup, sag and lap variation.
5. **Pale flat floor with jagged shadow** (tell 1, `330 540 820 180`): a bright slab with stair-stepped shadow edges. Cause: light. Cheapest fix: darker floor, filtered shadows.

## Ranking
From least to most cheap-looking: a, c, b, f, d, e

## The man and the wood
- **a** (shows the man): **partly.** The man is cleaner and more finely detailed (a smooth, sharp face, saturated vest, clean shirt, no dust on his boots) while the wood is coarse and deeply embossed; the light sits on both the same way (hard sun, matching shadows), and the colours share a world, but he looks freshly made and the wood is a uniform texture print.
- **b** (no man): N/A.
- **c** (shows the man): **no.** The panel is a bright, polished veneer and he is nearly black below the waist; the light doesn't treat them alike, and his sharp, painted-detail face sits beside a wood whose detail is exaggerated swirl rather than real texture.
- **d** (shows the man): **no.** He is rich, warm and saturated, with painted detail per centimetre (vest pattern, buttons, creases); the wood beside him is a pale, bloodless cork-fleck with no grain, so he looks like a different game's character standing in front of placeholder material.
- **e** (no man; only a curved shadow, perhaps his): N/A.
- **f** (shows the man): **partly.** Lamp-warm on both, but he's sunk in shadow while the flecked cork wall glows evenly; his detail and finish are far finer than the wood's, which reads as noise.
- Overall: the man reads as more finished, sharper and cleaner than every wood here; the vertical embossed boards of **a** come closest to sharing his world, and the flecked siding of **d** and **f** is furthest from it.
