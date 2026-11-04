# Cheap judge, 2026-11-04_cheap_r0_before

## a
- 1 Flat light: FAIL (`620 160 640 280`; `cut a_a_backwall.png`): the whole hall is one saturated orange; ceiling, walls and floor equally lit, no dark left between a dozen lamps, the blacks lifted to brown.
- 2 No atmosphere: FAIL (`560 0 720 400`; `cut a_gable.png`): the far gable is as sharp and saturated as the near floor; no haze or smoke in the lamplight.
- 3 Too clean: FAIL (`0 440 420 280`; `cut a_a_floor.png`): the floor is one even honey plank with the same dark knots and pin dots all over; no scuffs, spills or traffic paths; the walls one coarse-square red from end to end.
- 4 Too straight: FAIL (`560 0 720 400`; `cut a_gable.png`): a perfect box with rafters, wall boards and sconces at ruler spacing; nothing sags or warps.
- 5 Floating objects: FAIL (`700 400 400 320`; `cut a_a_table_floor.png`): the chair in front of the table passes into its rim; chair and table legs have no contact darkening on the floor.
- 6 Repetition: FAIL (`1120 220 160 100`; `cut a_sconces.png`): the same brass sconce repeated in pairs at even spacing round every wall; the same chair at every table.
- 7 Empty: FAIL (`620 160 640 280`; `cut a_a_backwall.png`): a barn-sized room with one barkeep, one deer head and a bare back wall; nobody drinking, nothing on the floor.
- 8 Scale tells: FAIL (`560 0 720 400`; `cut a_gable.png`): the roof rises two storeys over a bar and tables sized for a small room; it reads as a barn, not a saloon.
- 9 Edges of the world: N/A (interior; the blue slits in the gable read as gaps between boards)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Flat orange light everywhere** (tell 1, `620 160 640 280`): every surface glows the same orange; the lamps make no pools and the room has no darks. Cause: light. Cheapest fix: cut the room's fill/ambient so only the area round each lamp is lit and the corners and ceiling fall to near black.
2. **Walls drawn in coarse squares** (tell 3, `620 160 640 280`): the wall boards are big blotchy blocks of red and brown, a mosaic rather than wood; a player reads it as a low-res or filtered texture. Cause: material. Cheapest fix: replace the wall texture with a finer real-wood one, no square filter.
3. **No air in the room** (tell 2, `560 0 720 400`): the far gable and lamps are crisp; no smoke hangs under the roof. Cause: light. Cheapest fix: a thin warm volumetric haze that lamps light up.
4. **A big empty barn** (tell 7, `620 160 640 280`): the back wall is bare and the floor clear; one person in a room for fifty. Cause: dressing. Cheapest fix: a few drinkers at the tables and clutter (glasses, hats, coats, sawdust) on surfaces and floor.
5. **Furniture not sitting in the room** (tell 5, `700 400 400 320`): a chair cuts into the table edge and legs have no contact shadow. Cause: geometry. Cheapest fix: screen-space ambient occlusion and move that chair clear of the table.

## b
- 1 Flat light: FAIL (`380 280 520 220`; `cut b_backwall.png`): the back wall and floor are an even orange; the sconce pools blur into a general glow; no deep shadow anywhere in the hall.
- 2 No atmosphere: FAIL (`0 0 1280 300`; `cut b_roof.png`): the roof and far wall are as crisp as the bar; no haze or smoke under the lamps.
- 3 Too clean: FAIL (`0 420 500 300`; `cut b_bar_front.png`): the bar front is one streaky, stretched plank texture from end to end, its top unworn; the floor meets it with no dirt line.
- 4 Too straight: FAIL (`0 0 1280 300`; `cut b_roof.png`): rafters, wall boards and bar run dead straight and evenly spaced; the hall is a perfect symmetrical box.
- 5 Floating objects: PASS (`0 420 500 300`): the stools and spittoon carry small shadows on the floor.
- 6 Repetition: FAIL (`860 280 420 180`; `cut b_rightwall.png`): identical sconces in matched pairs along both walls; identical stools along the bar.
- 7 Empty: FAIL (`380 280 520 220`; `cut b_backwall.png`): a long bare back wall with one deer head; one barkeep; the floor down the middle empty.
- 8 Scale tells: FAIL (`0 0 1280 300`; `cut b_roof.png`): the roof is barn-high above a room of bar stools and a few small tables.
- 9 Edges of the world: N/A (interior)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The player's hand is pink plastic** (tell 3, `760 440 380 280`; `cut b_hand_gun.png`): a smooth, blotchy, posterised pink hand with faceted fingers and a revolver that is a black lump with banded edges, right in the middle of the view. Cause: material. Cheapest fix: a proper skin texture with tan, knuckles and dirt, and a gun with readable metal and wood.
2. **Flat orange light** (tell 1, `380 280 520 220`): the whole room is one warm wash; nothing falls off into dark. Cause: light. Cheapest fix: lower the fill so the lamps make pools and the ceiling goes dark.
3. **Blocky walls** (tell 3, `860 280 420 180`): the wall planks are coarse squares; the painting and plank panel on them sharper than the wall itself. Cause: material. Cheapest fix: a finer, real wood texture without the square filter.
4. **An empty hall** (tell 7, `380 280 520 220`): the back wall bare, nobody at the tables, the floor clear. Cause: dressing. Cheapest fix: people at the tables and clutter on the bar and floor.
5. **Repeated fixtures in perfect rhythm** (tell 6, `860 280 420 180`): the same sconce pair every few metres on both walls, rafters at ruler spacing. Cause: dressing. Cheapest fix: fewer, varied lamps (a chandelier, a few odd sconces) placed unevenly.

## c
- 1 Flat light: FAIL (`0 120 560 300`; `cut c_walls.png`): walls, floor and ceiling share one orange level; the lamps add hot spots but no darkness between them.
- 2 No atmosphere: FAIL (`540 220 540 200`; `cut c_backroom.png`): the doorway, stair and far wall are as sharp as the near table; no smoke in the light.
- 3 Too clean: FAIL (`0 120 560 300`; `cut c_walls.png`): the walls are one uniform coarse-square red; the floor the same planks and knots everywhere; the bar top unworn.
- 4 Too straight: FAIL (`0 120 560 300`; `cut c_walls.png`): wall boards, rafters and sconces at perfect spacing; the stair a single straight plank ramp.
- 5 Floating objects: FAIL (`100 380 380 260`; `cut c_table.png`): chair and table legs meet the floor with no contact darkening; the table's foot beam looks laid on the floor rather than part of it.
- 6 Repetition: FAIL (`0 120 560 300`; `cut c_walls.png`): matched sconce pairs at equal intervals; the same chair and table repeated.
- 7 Empty: FAIL (`540 220 540 200`; `cut c_backroom.png`): one dancer in the back and nobody else on the floor of a big hall.
- 8 Scale tells: FAIL (`0 120 560 300`; `cut c_walls.png`): the walls and roof tower over the furniture; the room reads as a barn.
- 9 Edges of the world: FAIL (`540 220 540 200`; `cut c_backroom.png`): through the open door, a flat grey box of a building under a night sky; nothing out there.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Flat orange light** (tell 1, `0 120 560 300`): the room is one warm wash with lamp hot spots; it doesn't feel like night. Cause: light. Cheapest fix: drop the ambient fill and let the corners, ceiling and back of the room go dark.
2. **Blocky, posterised walls** (tell 3, `0 120 560 300`): the wall planks are coarse squares; up close they read as a filtered low-res texture. Cause: material. Cheapest fix: a finer real-wood wall texture.
3. **A big room with nobody in it** (tell 7, `540 220 540 200`): one dancer posing at the back, tables unused. Cause: dressing. Cheapest fix: drinkers and card players at the tables.
4. **The pink hand and black lump of a gun** (tell 3, `760 440 380 280`): the same smooth, faceted pink hand front and centre. Cause: material. Cheapest fix: a textured, sun-tanned hand and a gun with real metal.
5. **An empty world through the door** (tell 9, `540 220 540 200`): the doorway shows a flat untextured wall under a dark blue sky. Cause: geometry. Cheapest fix: a lit window or porch lamp and some detail on the building across the way.

## d
- 1 Flat light: FAIL (`560 0 720 420`; `cut d_gable.png`): the same even orange wash on walls, ceiling and floor; no dark gaps between lamps.
- 2 No atmosphere: FAIL (`560 0 720 420`; `cut d_gable.png`): the far gable and lamps are crisp; no haze in the room.
- 3 Too clean: FAIL (`1050 300 230 260`; `cut d_rightwall.png`): the floor is one plank pattern with even pin dots; the piano a pale grey board with a clean edge; no dirt or wear where things meet.
- 4 Too straight: FAIL (`560 0 720 420`; `cut d_gable.png`): rafters, wall boards and lamps on a perfect grid.
- 5 Floating objects: FAIL (`740 440 280 280`; `cut d_table.png`): the chair runs into the table rim; the dark blocks under the table and chair legs sit on the floor with no contact shading.
- 6 Repetition: FAIL (`1050 300 230 260`; `cut d_rightwall.png`): identical sconces in rows; the same tables and chairs.
- 7 Empty: FAIL (`560 0 720 420`; `cut d_gable.png`): two people in a hall with a bare back wall and an empty floor.
- 8 Scale tells: FAIL (`1050 300 230 260`; `cut d_rightwall.png`): the pale plank panel on the right wall has grain the size of a door, out of scale with the wall boards beside it; the roof barn-high.
- 9 Edges of the world: N/A (interior)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Flat orange light** (tell 1, `560 0 720 420`): the room is lit evenly and saturated; nothing reads as night. Cause: light. Cheapest fix: cut the fill so lamps make pools and the room goes dark between them.
2. **Coarse, blocky walls** (tell 3, `1050 300 230 260`): the planks are squares of red; the panel and piano beside them show sharper but mismatched grain. Cause: material. Cheapest fix: one consistent fine wood texture for walls and fittings.
3. **Saturated plastic people** (tell 3, `380 250 340 470`; `cut d_woman.png`): the woman's hair and corset are one pure red and her skin a smooth orange; the barkeep's face posterised to a few blotches (`590 300 120 170`; `cut d_man.png`). Cause: people. Cheapest fix: desaturate hair and skin and add skin texture and cloth wear.
4. **Empty hall** (tell 7, `560 0 720 420`): two people in a room for fifty, bare walls. Cause: dressing. Cheapest fix: a crowd at the tables and clutter on the floor and bar.
5. **Furniture through furniture** (tell 5, `740 440 280 280`): the chair intersects the table, no contact shadow on the floor. Cause: geometry. Cheapest fix: fix the placement and add ambient occlusion.

## e
- 1 Flat light: PASS (`0 280 1280 440`): the sun is clear; the horses and buildings throw shadows across the road; though the whole frame is pale and low in contrast.
- 2 No atmosphere: PASS (`280 100 360 220`): the far canyon and the street's end soften into a pale haze.
- 3 Too clean: FAIL (`900 0 380 400`; `cut e_jail.png`): the jail's side wall is one pale blue-grey block of coarse squares from top to bottom; no stain or wear where it meets the ground.
- 4 Too straight: PASS (`900 0 380 400`): the fronts and posts lean a little; the porch roofs aren't ruler-straight.
- 5 Floating objects: FAIL (`800 450 480 180`; `cut e_rocks.png`): the road stones are low-poly grey lumps sitting on the dirt with no contact shadow or bedding.
- 6 Repetition: FAIL (`800 450 480 180`; `cut e_rocks.png`): the same grey lozenge stone scattered at even density down the whole road; the same grass clump at every porch; the same bay horse with white socks three times.
- 7 Empty: PASS (`0 180 1280 200`): riders, horses, men on the porches, a wagon far off.
- 8 Scale tells: PASS (`0 180 1280 200`): horses, people and fronts agree.
- 9 Edges of the world: FAIL (`540 200 200 110`; `cut e_mid.png`): the street ends in a painted canyon, and in the middle of it sits a smeared brown-green blot that reads as a broken backdrop.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Faceted, untextured horses** (tell 3, `0 180 300 310`; `cut e_horse.png`): the near horses are flat-shaded low-poly shapes with no hair, sheen or sweat, the first thing the eye lands on. Cause: material. Cheapest fix: a proper coat texture with normal map and a little sheen.
2. **The smeared blot in the distance** (tell 9, `540 200 200 110`): at the end of the street a brown-green smudge floats in the canyon backdrop. Cause: camera. Cheapest fix: remove or repaint whatever the backdrop is showing there.
3. **Plastic road stones** (tell 5, `800 450 480 180`): grey lumps of identical shape float on the dirt. Cause: geometry. Cheapest fix: smaller, varied, earth-coloured stones sunk into the ground.
4. **Blocky pale side walls** (tell 3, `900 0 380 400`): the jail's side is coarse pale squares, unlike its signed front. Cause: material. Cheapest fix: the same weathered plank material as the front.
5. **Washed-out noon** (tell 1, `0 280 1280 440`): the frame is pale and grey-blue in its shadows; it lacks the hard noon contrast. Cause: light. Cheapest fix: deepen the shadows and keep the blacks black.

## f
- 1 Flat light: PASS (`640 280 640 240`): low sun from the end of the street, long shadows, sun shafts, lamps lit under the porches.
- 2 No atmosphere: PASS (`640 280 640 240`; `cut f_distance.png`): golden haze and sun rays down the street; the far fronts soften.
- 3 Too clean: FAIL (`740 440 380 280`; `cut f_hand.png`): the hand is one smooth pink plastic surface; the gun a black lump without wear.
- 4 Too straight: PASS (`0 0 640 440`): bracing, posts and boards vary and weather.
- 5 Floating objects: PASS (`0 250 440 330`): horses, crates and porch posts are anchored by the long shadows.
- 6 Repetition: FAIL (`0 250 440 330`; `cut f_porch.png`): the same bay horse with the same saddle and white socks four times along the street.
- 7 Empty: PASS (`0 0 1280 720`): people on the porches and road, horses, a wagon, lamps, a wanted poster.
- 8 Scale tells: PASS (`0 250 440 330`): man, horses and fronts agree.
- 9 Edges of the world: FAIL (`640 0 640 260`; `cut f_sky.png`): the sky is visibly a painting (brush texture in the clouds), and the cliffs carry a bright halo outline where they meet it; the street runs straight into a painted wall.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The pink plastic hand** (tell 3, `740 440 380 280`): the player's hand is smooth, faceted and candy-pink, the cheapest-looking thing on screen. Cause: material. Cheapest fix: a tanned, textured skin with dirt and knuckle shading.
2. **A painted backdrop sky with haloed cliffs** (tell 9, `640 0 640 260`): the clouds have painting brush texture and the cliffs a bright outline; it reads as a backdrop, not a sky. Cause: light. Cheapest fix: a smooth sky with real cloud volumes and no outline at the cliff edge.
3. **Faceted, matching horses** (tell 6, `0 250 440 330`): the same low-poly bay four times. Cause: material. Cheapest fix: a coat texture and two or three different horse colours.
4. **A stiff man under the lamp** (tell 8, `0 250 440 330`): the man on the porch stands square, arms hanging, with the lantern sitting on his hat. Cause: people. Cheapest fix: a lean or idle pose and moving him out from under the lamp.
5. **Posterised details** (tell 3, `0 0 640 440`; `cut f_front.png`): the wanted poster and shutter at left are coarse squares beside finely made fronts. Cause: material. Cheapest fix: replace those few low-res textures.

## g
- 1 Flat light: PASS (`483 0 483 272`): golden low sun, long horse shadows, lamps lit on the porch.
- 2 No atmosphere: PASS (`0 0 483 272`): the cliffs and plain fade into warm haze.
- 3 Too clean: PASS (`0 0 483 272`): weathered boards, rutted road, grass at the porch.
- 4 Too straight: PASS (`0 0 483 272`): posts and boards vary.
- 5 Floating objects: PASS (`0 0 483 272`): horses and porch anchored by shadows.
- 6 Repetition: FAIL (`483 0 483 272`; `cut g_frame2.png`): two identical bays with the same saddles and white socks side by side.
- 7 Empty: PASS (`966 0 483 272`): men come and go on the porch, one seated.
- 8 Scale tells: PASS (`483 0 483 272`): people, horses and porch agree.
- 9 Edges of the world: FAIL (`0 90 200 60`; `cut g_frame1.png`): left of the porch, a flat empty plain runs to a painted-looking cliff, with nothing between.
- 10 Stiff people: FAIL (`966 0 483 272`; `cut g_frame3.png`): over eight frames the horses barely shift; men appear in the doorway and stand square; the seated man holds his arms out stiffly in every frame.
- **Verdict: good indie**
1. **Horses frozen in place** (tell 10, `0 0 1932 544`): across the strip the two horses hold the same pose; no head toss, tail flick or weight shift. Cause: people. Cheapest fix: an idle loop for tied horses (head, ears, tail, a hoof shift).
2. **Faceted, matching horses** (tell 6, `483 0 483 272`): two identical low-poly bays fill the centre. Cause: material. Cheapest fix: a coat texture and different coat colours.
3. **Stiff men on the porch** (tell 10, `966 0 483 272`): the men stand square or sit with arms out, no idle movement. Cause: people. Cheapest fix: idle animation (weight shift, arms crossed, a drink).
4. **An empty plain to the horizon** (tell 9, `0 90 200 60`): left of the building the land is flat and bare up to the cliffs. Cause: dressing. Cheapest fix: a fence line, a shed, scrub or a road out of town on the plain.
5. **A painted sky** (tell 9, `0 0 483 100`): the clouds look brushed on, not volumetric. Cause: light. Cheapest fix: a smoother real-sky dome.

## Ranking
From least to most cheap-looking: f, g, e, c, d, a, b
