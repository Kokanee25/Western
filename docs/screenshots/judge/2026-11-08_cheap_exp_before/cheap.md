# Cheap judge, 2026-11-08_cheap_exp_before

## a
- 1 Flat light: FAIL (`0 380 1280 340`; `a_a_flat_ground.png`)
- 2 No atmosphere: PASS (`600 90 320 160`: the mesas go pale and soft with distance)
- 3 Too clean: FAIL (`900 0 380 330`; `a_a_jail_clean.png`)
- 4 Too straight: FAIL (`300 170 320 160`; `a_a_street_lines.png`)
- 5 Floating objects: FAIL (`880 470 300 160`; `a_a_rocks_float.png`)
- 6 Repetition: FAIL (`840 290 440 130`; `a_a_grass_repeat.png`)
- 7 Empty: FAIL (`300 270 700 130`; `a_a_empty_street.png`)
- 8 Scale tells: PASS (doors, porches, horses and men agree with each other)
- 9 Edges of the world: FAIL (`560 230 140 70`; `a_a_orange_blob.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Grey midday light with no shape** (tell 1, `0 380 1280 340`): half the frame is the road, evenly lit in a dull beige with almost no shadow under horses, people or porches; you can't tell where the sun is, and the blacks sit at grey. Cause: light. Cheapest fix: a stronger, lower sun with real cast shadows across the road and darker shade under the porches.
2. **Scattered low-poly rocks lying on the ground** (tells 5 and 6, `880 470 300 160`): faceted grey pebbles of one size and colour, spread evenly over the whole street; none sits in the dirt or has a contact shadow, so they look dropped on top. Cause: dressing. Cheapest fix: fewer, smaller rocks, half-buried and tinted to the ground, clustered at the ruts' edges and the building feet.
3. **Ruler-straight street and identical tufts** (tells 4 and 6, `300 170 320 160`, `840 290 440 130`): the wheel ruts run as parallel lines to the vanishing point, the fronts line up perfectly, and the same pale grass clump is stamped along each boardwalk. Cause: geometry. Cheapest fix: wander the ruts and break the grass into a few different clump kinds and sizes, absent in trodden spots.
4. **A wide street with nobody working in it** (tell 7, `300 270 700 130`): a few horses and a couple of standing men, one crate; no wagons, barrels, hitching gear, washing, signs of trade. Cause: dressing. Cheapest fix: a parked wagon, barrels and goods on the boardwalks, a pair of men doing something mid-street.
5. **A smeared orange block in the middle distance** (tell 9, `560 230 140 70`): something at the far end of the street draws as a blurry, blocky orange-brown smear, like a low-res backdrop or a broken sprite; the eye goes straight to it. Also the fronts read clean and uniformly grey (`900 0 380 330`). Cause: material. Cheapest fix: replace or remove whatever that far object is, and add grime low on the jail and store fronts.

## b
- 1 Flat light: PASS (`0 0 640 440`: a low sun, porch roofs throwing shadow, warm key against cool sky)
- 2 No atmosphere: PASS (`900 260 330 130`: the far street and cliffs dissolve in sun haze)
- 3 Too clean: PASS (`140 100 360 260`: grey weathered boards, worn signs)
- 4 Too straight: PASS (`420 150 260 260`: braces and posts, some variety in the fronts)
- 5 Floating objects: FAIL (`260 460 180 120`; `b_b_hooves.png`)
- 6 Repetition: FAIL (`270 350 480 210`; `b_b_repeat.png`)
- 7 Empty: PASS (`0 230 1280 260`: horses tied, men on the porches and in the street, lamps lit)
- 8 Scale tells: FAIL (`730 430 360 290`; `b_b_hand.png`)
- 9 Edges of the world: FAIL (`440 0 840 260`; `b_b_sky.png`)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The player's hand is a plastic mannequin's** (tell 8, `730 430 360 290`): the closest object on screen is a huge, faceted, flat-shaded pink hand with fingers like tubes, holding a gun whose grip is smeared stripes; it reads as placeholder. Cause: material. Cheapest fix: a skin shader with subsurface and a glove or dirt, smoother normals on the hand, and a proper wood texture on the grip.
2. **The sky is a painting, oversharpened** (tell 9, `440 0 840 260`): the clouds have brushstroke texture and HDR-like over-saturated magenta and orange; it looks like a backdrop pasted behind a realistic street, the "AI wallpaper" sky. Cause: light. Cheapest fix: a calmer, less saturated sky with soft volumetric clouds that match the haze at the horizon.
3. **Horses copy-pasted and not standing on the dirt** (tells 5 and 6, `260 460 180 120`): the same bay with the same white socks and saddle appears four times; the hooves end in black blobs with no shadow under them. Cause: dressing. Cheapest fix: vary coat colour and tack per horse and add a contact shadow and a little dust at the hooves.
4. **The same grass tuft repeated** (tell 6, `270 350 480 210`): identical straw clumps in a row in front of the boardwalk. Cause: dressing. Cheapest fix: two or three clump shapes, scaled and bent differently, thinner where feet go.
5. **People blocky and dimly lit** (tell 8, `140 300 70 140`): the man on the saloon porch is a stiff dark silhouette with a pale face, less detailed than the wood behind him. Cause: people. Cheapest fix: a rim of the warm sun on the figures and a little more contrast in their clothes.

## c
- 1 Flat light: FAIL (`600 180 680 230`; `c_c_wash.png`)
- 2 No atmosphere: FAIL (`580 60 500 300`; `c_c_no_air.png`)
- 3 Too clean: FAIL (`60 450 700 270`; `c_c_floor_clean.png`)
- 4 Too straight: FAIL (`0 0 1280 220`; `c_c_roof.png`)
- 5 Floating objects: PASS (`640 420 320 160`: chairs and the table cast shadows on the floor)
- 6 Repetition: FAIL (`90 170 560 180`; `c_c_sconces.png`)
- 7 Empty: FAIL (`560 280 600 200`; `c_c_empty.png`)
- 8 Scale tells: FAIL (`600 0 680 300`; `c_c_hall_height.png`)
- 9 Edges of the world: PASS (an interior; the room closes on all sides)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **One orange wash over everything** (tell 1, `600 180 680 230`): walls, floor, roof, bar and bottles are all the same orange-brown; the sconces light every wall evenly, so there are no dark corners, no pools of light and no blacks. Cause: light. Cheapest fix: drop the fill so the room falls to near black between lamps, and cool the shadow side.
2. **A barn, not a saloon** (tell 8, `600 0 680 300`): the room is a huge open shed with a high gabled roof and a slatted barn end wall; the bar and a few tables are tiny in it. Cause: geometry. Cheapest fix: a flat ceiling or balcony at a human height, closing the room down around the tables.
3. **Lamplight with hard disc patches on the roof and no air** (tells 2 and 4, `580 60 500 300`, `0 0 1280 220`): pale circles with crisp edges sit on the roof boards like stencils, and the lamps don't glow in any haze or smoke; the rafters are perfectly regular. Cause: light. Cheapest fix: soften or remove the ceiling light discs and add a thin smoke haze that the lamps bloom in.
4. **The same sconce and bottle everywhere** (tell 6, `90 170 560 180`): a dozen identical brass sconces evenly spaced round the walls, and three shelves of one bottle stamped hundreds of times. Cause: dressing. Cheapest fix: fewer, varied lamps (a chandelier, two kinds of sconce) and mixed bottles, jars and gaps on the shelves.
5. **Empty, clean floor and walls** (tells 3 and 7, `560 280 600 200`, `60 450 700 270`): one barkeep, two tables, a deer head; the floor is uniform planks with no stains, spit, sawdust or wear by the bar. The near hand is the same plastic mannequin hand (`770 430 330 290`). Cause: dressing. Cheapest fix: more tables and drinkers, clutter on the bar, and dark worn traffic paths on the floor.

## Ranking
From least to most cheap-looking: b, a, c
