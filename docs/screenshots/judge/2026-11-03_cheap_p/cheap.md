# Cheap judge, 2026-11-03_cheap_p

## a
- 1 Flat light: PASS (low sun down the street, long post and figure shadows across the road, warm lamplight under the saloon porch; the light clearly comes from the far end)
- 2 No atmosphere: PASS (`500 280 300 140`: haze and sun shafts at the street's end, the far fronts and canyon fall back into warm dust)
- 3 Too clean: PASS (rutted, pebbled road; weathered siding; the porch boards worn)
- 4 Too straight: PASS (fronts vary in height and set-back; the boardwalk fascia `0 380 460 160` is ruler-straight and the step a clean block, but a player wouldn't call it out first)
- 5 Floating objects: PASS (people and horse carry shadows; posts and porch sit on the ground; the grass clumps have no base shading but read as planted)
- 6 Repetition: FAIL (`40 440 400 110` and `860 420 420 180`: the same dry-grass clump, same height and colour, lined along both boardwalks; `cut a_a_grass.png`, `cut a_a_grass_r.png`)
- 7 Empty: PASS (men on the porch, a horse and two men talking, barrels, figures down the street)
- 8 Scale tells: FAIL (`760 450 240 270`: the hand and revolver are built of squares ten times the size of the world's texels, a toy hand against a painted street; `cut a_a_hand.png`)
- 9 Edges of the world: PASS (the canyon closes the street; the road meets it on a flat bright band `500 380 300 40`, softened by the haze)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The blocky toy hand and gun** (tell 8, `760 450 240 270`): the nearest, biggest thing on screen is chunky blocks, a much coarser square than anything else, so it reads as a placeholder pasted over a painted scene. Cause: material. Cheapest fix: draw the viewmodel at the world's square size (or painted smooth like the townsfolk).
2. **The same grass tuft in a row** (tell 6, `40 440 400 110`, `860 420 420 180`): identical clumps at even height along both sides look like planters, not scrub. Cause: dressing. Cheapest fix: vary each clump's size, tilt and colour, and leave bare dirt and low weeds between them.
3. **The middle of the street is bare road** (tell 7, `400 440 480 280`): a big empty foreground of dirt and pebbles between two well-dressed sides; nothing crossing or parked. Cause: dressing. Cheapest fix: a wagon, a trough or a rider in the middle distance of the road.
4. **The boardwalk edge and step are ruler-straight and unworn** (tell 4, `0 380 460 160`): a perfectly level fascia and a box step under an otherwise weathered porch. Cause: geometry. Cheapest fix: a little sag in the boardwalk and a worn, uneven step.
5. **The street runs into a flat glowing band** (tell 9, `500 380 300 40`): where the road meets the canyon there is a plain bright line, like a fog wall. Cause: geometry. Cheapest fix: something at the street's end (a fence, a shack, a rise in the road) to break that line.

## b
- 1 Flat light: PASS (low sun, long shadows across the road; the jail's pale side `1020 300 70 150` is a blown, flat panel, but the scene has clear light direction)
- 2 No atmosphere: PASS (`560 300 240 120`: dust and haze at the street's end, the far fronts soften)
- 3 Too clean: FAIL (`800 600 360 120`: the player's hand is smooth, untextured peach with stretched streaks on the grip; the pebbles are clean smooth blobs; `cut b_b_hand.png`)
- 4 Too straight: PASS (fronts vary, the right-hand building's boards and stains are irregular)
- 5 Floating objects: FAIL (`200 560 600 160`: the yellow pebbles sit on top of the dirt, lit brighter than the ground, with no contact shadow; `cut b_b_pebbles.png`)
- 6 Repetition: FAIL (`340 370 300 120`: three identical bay horses with identical saddles side by side; the grass tufts repeat along both sides; `cut b_b_horses.png`)
- 7 Empty: PASS (porch loungers, horses, men on the street, a wagon down the road, the apron man close on the right)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (canyon closes the street; same flat bright band at the road's end as in a, softened)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The plastic hand** (tell 3, `800 600 360 120`): the nearest object is a smooth, flat-shaded, unpainted hand with smeared stripes, next to a richly painted world; it reads as a default mesh. Cause: material. Cheapest fix: paint the hand in the same hand as the townsfolk's skin.
2. **Glowing pebbles that float** (tell 5, `200 560 600 160`): bright yellow bread-roll stones scattered evenly, no contact shading, brighter than the sunlit dirt. Cause: material. Cheapest fix: darken them to the dirt's value and sink them in with a contact shadow; fewer of them.
3. **Cloned horses** (tell 6, `340 370 300 120`): three of the same horse, same coat, same tack, in a line. Cause: dressing. Cheapest fix: vary coat colour and markings, and turn one.
4. **Copy-pasted grass tufts** (tell 6, `50 470 290 80`, `860 430 420 160`): the same clump at the same height lining both boardwalks. Cause: dressing. Cheapest fix: vary size, colour and spacing; leave gaps.
5. **The jail's side is a blown, flat cream panel** (tell 1, `1020 300 70 150`): a big bright wall with no shading or weathering, unlike every other wall. Cause: light. Cheapest fix: grade that pale paint down and give it the same grime as its neighbours.

## c
- 1 Flat light: PASS (low sun, long shadows, sun shafts at the street's end; the jail's pale side `1020 300 70 150` is flat and bright)
- 2 No atmosphere: PASS (`560 300 240 120`: dust and stronger light shafts at the far end)
- 3 Too clean: FAIL (`800 600 360 120`: the smooth untextured hand; the clean pebbles; `cut c_c_hand.png`)
- 4 Too straight: PASS
- 5 Floating objects: FAIL (`200 560 600 160`: bright pebbles on top of the road with no contact; `cut c_c_pebbles.png`)
- 6 Repetition: FAIL (`340 370 300 120`: three identical saddled bays in a row; repeated grass clumps; `cut c_c_horses.png`)
- 7 Empty: PASS (`960 360 320 240`: the apron man, a man at the rail, folk on the jail's porch; the street is lived in)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (canyon closes the street; flat bright band at the road's end, softened by the shafts)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The plastic hand** (tell 3, `800 600 360 120`): smooth, unpainted, streaky skin right in front of the camera, against a painted world. Cause: material. Cheapest fix: paint the hand like the townsfolk's skin.
2. **Glowing pebbles that float** (tell 5, `200 560 600 160`): evenly scattered yellow blobs lit brighter than the ground, with no contact shadow. Cause: material. Cheapest fix: darken and sink them, add contact shading, thin them out.
3. **Cloned horses** (tell 6, `340 370 300 120`): three of the same horse and saddle side by side. Cause: dressing. Cheapest fix: vary coats and tack.
4. **Copy-pasted grass tufts** (tell 6, `50 470 290 80`, `860 430 420 160`): one clump repeated at one height along both sides. Cause: dressing. Cheapest fix: vary size, colour and spacing.
5. **The jail's side is a blown, flat cream panel** (tell 1, `1020 300 70 150`): bright, unshaded, unweathered beside grimy neighbours. Cause: light. Cheapest fix: grade it down and give it the street's grime.

## d
- 1 Flat light: PASS (a clear low sun with long post shadows on the road and a lamp-warm porch; the far right row is evenly washed pink)
- 2 No atmosphere: PASS (heavy warm haze swallows the distance; if anything too much, like fog)
- 3 Too clean: FAIL (`640 440 640 280`: the road is one uniform pink plane, no ruts, tracks, stones or dirt at wall bases; `cut d_d_ground.png`)
- 4 Too straight: FAIL (`960 230 320 250`: the fronts are perfect plumb slabs with rectangles punched for doors and windows, no frames, sills or sag; `cut d_d_right.png`)
- 5 Floating objects: FAIL (`960 230 320 250`: the right-hand fronts meet the road on a thin bluish line with no contact darkening, as if set on top of it; `cut d_d_right.png`)
- 6 Repetition: FAIL (`100 260 480 280`: the same blotch stain stamped over the red door, the siding and the red building alike; `cut d_d_wall.png`)
- 7 Empty: FAIL (`640 440 640 280`: no people, no horses, no signs or troughs; one crate in the whole street; `cut d_d_ground.png`)
- 8 Scale tells: FAIL (`760 500 260 220`: a hand and gun of huge blocks, far coarser than the world's squares; `cut d_d_hand.png`)
- 9 Edges of the world: FAIL (`580 220 200 200`: the buildings are single flat cards with nothing behind them, seen edge-on; a box-and-cone church; a blank pink sky and empty horizon; `cut d_d_cards.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The town is cardboard fronts** (tell 9, `580 220 200 200`): each building is one flat wall with no body or roof behind it, the thinness visible edge-on, the church a primitive; it reads as a greybox. Cause: geometry. Cheapest fix: give every front a building behind it, with a roofline.
2. **An empty street** (tell 7, `640 440 640 280`): no people, horses, wagons, signs or clutter; a single crate. Cause: dressing. Cheapest fix: put the town's people and porch clutter in.
3. **A blank ground plane** (tell 3, `640 440 640 280`): uniform pink, no ruts, stones or dirt, no change where it meets the walls. Cause: material. Cheapest fix: the rutted, pebbled dirt road.
4. **One stain stamped everywhere** (tell 6, `100 260 480 280`): the same blotches on the door, boards, brick and adobe, so every surface looks like the same texture. Cause: material. Cheapest fix: a distinct material per surface, the stain varied in size and placement.
5. **The blocky hand and gun** (tell 8, `760 500 260 220`): giant squares, much coarser than the world, a placeholder look at the centre of the screen. Cause: material. Cheapest fix: draw the viewmodel at the world's square size.
