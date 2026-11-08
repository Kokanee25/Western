# Cheap judge, 2026-11-04_cheap_r1_real2

## a
- 1 Flat light: FAIL (`0 0 1280 200`; `cut a_ceiling_flat.png`): the whole roof, walls and floor glow the same orange; no lamp makes a pool or leaves a dark corner, and the blacks never get to black
- 2 No atmosphere: FAIL (`560 120 600 260`; `cut a_no_air.png`): the far end of a lamp-lit room is as crisp as the near end; no smoke or haze anywhere near the lamps
- 3 Too clean: FAIL (`60 440 700 280`; `cut a_clean_floor.png`): the floorboards are one even texture from wall to wall; no trodden path, spills or dirt by the bar foot
- 4 Too straight: FAIL (`220 200 320 280`; `cut a_straight_bar.png`): the bar, back shelves and wall boards are ruler-straight and evenly spaced
- 5 Floating objects: PASS (stools and the table cast shadows on the floor, `340 390 200 90`)
- 6 Repetition: FAIL (`240 255 290 100`; `cut a_bottle_rows.png`): three shelves of the same bottle in even rows; the same sconce repeated down both walls
- 7 Empty: FAIL (`650 380 500 200`; `cut a_empty_floor.png`): most of the floor is bare; two tables in a hall this size, nothing on the walls but sconces
- 8 Scale tells: FAIL (`600 60 680 360`; `cut a_barn_scale.png`): the room reads as a huge empty barn; the bar and tables look small in it
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **One orange wash with no light shapes** (tell 1, `0 0 1280 200`): every surface is the same warm brightness, so you can't tell which lamp lights what. Cause: light. Cheapest fix: drop the room's fill a long way so each lamp makes a pool and the roof goes dark between them.
2. **A barn, not a saloon** (tell 7, `650 380 500 200`): a big empty floor and bare high walls; nobody lives or works here. Cause: dressing. Cheapest fix: fill the floor with more tables, clutter on them, and lower the gloomy roof with a dark ceiling.
3. **Copy-pasted bottles and sconces** (tell 6, `240 255 290 100`): identical bottles in perfect rows and the same sconce every few metres. Cause: dressing. Cheapest fix: mix bottle shapes, heights and gaps; vary the wall fixtures.
4. **No air in the lamplight** (tell 2, `560 120 600 260`): no smoke or haze, so the depth is lost and the room feels sterile. Cause: light. Cheapest fix: a thin warm haze that catches light near the lamps.
5. **Floor and walls without wear** (tell 3, `60 440 700 280`): an even, tidy wood texture end to end. Cause: material. Cheapest fix: darker trodden paths, grime at the bar foot and at the base of the walls.

## b
- 1 Flat light: FAIL (`880 120 400 300`; `cut b_flat_walls.png`): the right wall is the same orange glow everywhere; the sconces add hot spots but no shapes
- 2 No atmosphere: FAIL (`420 160 480 320`; `cut b_no_air.png`): the back wall and its lamps are clear and flat; no haze
- 3 Too clean: FAIL (`150 480 650 240`; `cut b_clean_floor.png`): the floor is one clean texture; the bar front is uniform
- 4 Too straight: FAIL (`0 420 480 300`; `cut b_straight_bar.png`): the bar, stools and shelves line up perfectly, evenly spaced
- 5 Floating objects: PASS (stools cast shadows, `240 520 200 160`)
- 6 Repetition: FAIL (`0 290 330 180`; `cut b_bottles.png`): rows of identical bottles; the same sconce down the walls
- 7 Empty: FAIL (`480 420 420 120`; `cut b_empty.png`): a long empty floor to the back wall; one dark barman, no customers
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The player's hand is a low-poly, untextured mitt** (tell 3, `770 550 320 170`; `cut b_hand.png`): flat facets and smooth pink skin, right in front of the eye. Cause: material. Cheapest fix: a smoother, textured hand mesh with knuckles and some sun and dirt on the skin.
2. **Flat orange glow over everything** (tell 1, `880 120 400 300`): the walls and roof are lit evenly, with no dark between the lamps. Cause: light. Cheapest fix: much less ambient fill, so the lamps make pools.
3. **Empty hall** (tell 7, `480 420 420 120`): a long bare floor and one shadowy barman. Cause: dressing. Cheapest fix: people at the bar, and clutter and tables down the middle.
4. **Repeated bottles and sconces** (tell 6, `0 290 330 180`): the same bottle copied in neat rows. Cause: dressing. Cheapest fix: mix the bottle kinds and leave gaps.
5. **No haze** (tell 2, `420 160 480 320`): the back of the room is as sharp as the front. Cause: light. Cheapest fix: a light volumetric haze near the lamps.

## c
- 1 Flat light: PASS (the gable goes dark, and lamplight pools on the floor and tables, `0 380 600 300`)
- 2 No atmosphere: FAIL (`100 0 200 140`; `cut c_lamp_no_air.png`): the hanging lamps blow out to white discs with no glow or haze around them
- 3 Too clean: FAIL (`880 360 400 300`; `cut c_clean_bar.png`): the bar top and front are one clean grain, no rings, stains or chipped edges
- 4 Too straight: FAIL (`770 210 300 200`; `cut c_straight_rails.png`): the stair and balcony rails are perfectly straight and evenly spaced
- 5 Floating objects: PASS (chairs and tables are grounded with shadows)
- 6 Repetition: FAIL (`1080 230 200 200`; `cut c_sconces_bottles.png`): identical bottles in rows; the same sconce repeated
- 7 Empty: PASS (tables with bottles, a woman by the piano, a stair to a gallery)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`680 190 360 120`; `cut c_blue_void.png`): a blue void through the back doorway and black slits of nothing under the roof, like a gap in the walls
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Holes in the room** (tell 9, `680 190 360 120`): a flat blue shape in the back doorway and dark slits under the eaves show the room isn't sealed. Cause: geometry. Cheapest fix: close the gaps under the roof and put a lit room or a dark backing behind that door.
2. **Lamps blown to white discs** (tell 2, `100 0 200 140`): the shade discs are pure white with no glow or air around them. Cause: light. Cheapest fix: tone the shades down and add a soft bloom or haze halo.
3. **Copied bottles and sconces** (tell 6, `1080 230 200 200`): the back bar is one bottle repeated. Cause: dressing. Cheapest fix: vary the bottles and add other things to the shelves.
4. **Bar without wear** (tell 3, `880 360 400 300`): a long, clean, even plank top. Cause: material. Cheapest fix: glass rings, wet patches and darkened, worn edges where elbows rest.
5. **Ruler-straight rails** (tell 4, `770 210 300 200`): the stair and gallery look modelled in a grid. Cause: geometry. Cheapest fix: turned balusters and a slight sag and uneven spacing.

## d
- 1 Flat light: FAIL (`0 0 470 720`; `cut d_orange_wall.png`): the wall is one smooth orange glow with no direction
- 2 No atmosphere: PASS (the window's reflection carries some glow; the corner shows no more)
- 3 Too clean: PASS (the panels are blotched, though it reads as smear, not dirt)
- 4 Too straight: FAIL (`540 570 600 150`; `cut d_straight_panels.png`): the low panels are a perfect even grid
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`170 0 300 600`; `cut d_blotch_panels.png`): every board carries the same blurry blotches, stretched and smeared as if the texture were low-res
- 7 Empty: N/A (a corner)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`1130 60 150 240`; `cut d_jagged_edge.png`): a stair-stepped, pixelated light shape on the right wall and a hard diagonal shadow cut with no visible cause
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Smeared, melted wall texture** (tell 6, `170 0 300 600`): the boards are blurry orange with repeating blotches, like a low-resolution texture stretched over big panels. Cause: material. Cheapest fix: a sharp wood texture at the right scale with real grain on these panels.
2. **Light and shadow artefacts** (tell 9, `1130 60 150 240`): a stepped, blocky patch of light and a knife-edge diagonal shadow on the right wall. Cause: light. Cheapest fix: a higher shadow/GI resolution or a softer filter for this corner.
3. **One flat orange glow** (tell 1, `0 0 470 720`): the walls are lit the same with no light source you can read. Cause: light. Cheapest fix: less fill, so a real lamp or window decides the light.
4. **Grid-perfect panels** (tell 4, `540 570 600 150`): the boards and frames are exact rectangles. Cause: geometry. Cheapest fix: vary the board widths and add gaps and warps.
5. **Nothing in the frame to look at** (tell 7, `0 0 1280 720`): bare boards and a dark window; it reads as a camera stuck in a wall. Cause: camera. Cheapest fix: keep the camera out of tight corners or dress them (a hook, a coat, a stain).

## e
- 1 Flat light: FAIL (`900 100 380 300`; `cut e_washed_front.png`): the fronts are washed pale grey; shadows are weak and you can barely say where the sun is
- 2 No atmosphere: PASS (the far street and cliffs fade into haze)
- 3 Too clean: PASS (ruts, hoof scuffs and grit on the road)
- 4 Too straight: FAIL (`380 300 500 200`; `cut e_straight_ruts.png`): parallel, ruler-straight ruts and building lines running to one vanishing point
- 5 Floating objects: FAIL (`900 480 250 140`; `cut e_rocks_float.png`): faceted rocks sit on the sand with no bedding into it
- 6 Repetition: FAIL (`840 310 440 100`; `cut e_tufts.png`): the same grass tuft placed again and again along the fronts; the same rocks sprinkled evenly
- 7 Empty: PASS (horses, a few people, a crate)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`570 240 130 60`; `cut e_blob.png`): a painted card at the end of the street, its flat buildings and colours not matching the 3D street
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Washed, flat noon** (tell 1, `900 100 380 300`): grey fronts, faint shadows, a milky low-contrast frame. Cause: light. Cheapest fix: a stronger sun with darker, crisper shadows under the porches.
2. **Painted card at the street's end** (tell 9, `570 240 130 60`): a flat picture of buildings sits where the street should continue. Cause: geometry. Cheapest fix: hide the card behind a real building or the street's curve, or blend it into the haze.
3. **Low-poly rocks pasted on the sand** (tell 5, `900 480 250 140`): gem-faceted pebbles sit on top of the ground, evenly scattered. Cause: geometry. Cheapest fix: fewer, smoother rocks half sunk in the sand with contact shadow.
4. **One grass tuft cloned along the fronts** (tell 6, `840 310 440 100`): the same clump repeated in a line. Cause: dressing. Cheapest fix: vary size and kind, and cluster them where feet don't go.
5. **Ruler-straight street** (tell 4, `380 300 500 200`): parallel ruts and perfectly level rooflines. Cause: geometry. Cheapest fix: wander the ruts and lean or sag a few fronts and posts.

## f
- 1 Flat light: PASS (a low warm sun, long shadows, lamps lit on the porch)
- 2 No atmosphere: PASS (the street end and canyon soften into warm haze)
- 3 Too clean: FAIL (`770 550 330 170`; `cut f_hand.png`): the player's hand is smooth, untextured, faceted skin; the horses are glossy and uniform
- 4 Too straight: FAIL (`600 400 600 320`; `cut f_straight_ruts.png`): parallel ruts running dead straight to the horizon
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`280 340 140 220`; `cut f_horse.png`): the same bay horse with the same saddle stands at several rails
- 7 Empty: PASS (riders, people on porches, a wagon down the street)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`420 0 860 260`; `cut f_painted_sky.png`): the sky is an obviously painted, brushy image whose style doesn't match the 3D street under it
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Painted sky over a 3D street** (tell 9, `420 0 860 260`): the clouds have visible brush strokes and oil-painting colour, so the world looks set against a backdrop. Cause: material. Cheapest fix: a photographic or volumetric sky in the same lighting as the scene.
2. **Low-poly hand in front of the camera** (tell 3, `770 550 330 170`): faceted, flat pink skin, which spoils an otherwise warm frame. Cause: material. Cheapest fix: a smooth, textured hand with tan and grime.
3. **Clone horses** (tell 6, `280 340 140 220`): identical bay horse and saddle at each rail, with a plastic sheen. Cause: dressing. Cheapest fix: two or three coat colours and different tack, with a rougher hair material.
4. **Ruler-straight ruts** (tell 4, `600 400 600 320`): the road's tracks run in perfect parallel lines. Cause: geometry. Cheapest fix: let the ruts wander, cross and fade.
5. **Rocks sprinkled evenly** (tell 6, `900 600 380 120`): the same small rocks scattered over the whole road. Cause: dressing. Cheapest fix: fewer stones, gathered at the road's edges and in the ruts.

## g
- 1 Flat light: PASS (low golden sun, the porch lamps glow, and the porch shade is dark)
- 2 No atmosphere: PASS (the canyon sits back in warm haze)
- 3 Too clean: PASS (the boards are weathered and the ground scuffed)
- 4 Too straight: PASS (the porch posts and rail read as rough timber)
- 5 Floating objects: PASS (the horses' hooves and the grass are shadowed on the ground)
- 6 Repetition: FAIL (`150 90 200 140`; `cut g_twin_horses.png`): two identical bays with the same saddle side by side; the grass clumps (`380 170 110 90`; `cut g_card_grass.png`) are the same crossed cards
- 7 Empty: PASS (men on the porch, horses at the rail)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 110 170 60`; `cut g_flat_plain.png`): a flat, empty plain runs straight to a painted-looking canyon and sky with nothing in between
- 10 Stiff people: FAIL (`0 0 966 272`; `cut g_g_frames12.png`): the horses hold the same pose through all eight frames, with no head, tail or weight moving; the porch men pop in and out more than they move
- **Verdict: good indie**
1. **Horses frozen like statues** (tell 10, `0 0 966 272`): over eight frames neither horse shifts weight, swishes or moves its head. Cause: people. Cheapest fix: an idle loop with tail swish, head bob and a hoof shift, offset per horse.
2. **Twin horses** (tell 6, `150 90 200 140`): the same model, coat and saddle copied side by side. Cause: dressing. Cheapest fix: a different coat and tack on the second horse.
3. **Grass as crossed cards** (tell 6, `380 170 110 90`): the clumps read as flat planes, all the same shape. Cause: geometry. Cheapest fix: denser, varied clumps with softer, thinner blades.
4. **Empty plain to a backdrop** (tell 9, `0 110 170 60`): a flat, featureless desert floor meets a painted canyon and sky. Cause: geometry. Cheapest fix: break the plain with scrub, rocks and a fence line, and haze the canyon's base.
5. **People hard to see** (tell 7, `830 180 140 140`): the porch men are dark shapes with no faces caught by the lamplight. Cause: people. Cheapest fix: let the lamps light their faces and hats as they pass.

## Ranking
From least to most cheap-looking: f, g, c, e, a, b, d
