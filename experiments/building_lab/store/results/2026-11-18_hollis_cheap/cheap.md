# Cheap judge, 2026-11-18_hollis_cheap

## a
- 1 Flat light: PASS (`0 540 1280 100`: the porch throws a real shadow band across the street; sun direction readable)
- 2 No atmosphere: FAIL (`0 100 1280 120`: the far sky, neighbours and facade are all equally crisp and saturated, with no dust in a dirt street; `cut a_sky_sharp.png`)
- 3 Too clean: FAIL (`280 120 720 220`: the siding is one even beige from corner to corner, with no streaks, sun-bleach or grime at the base; `cut a_clean_facade.png`)
- 4 Too straight: FAIL (`280 120 720 220`: dead-level cornice, three identical evenly spaced windows, a ruler-straight porch roof, nothing sags; `cut a_clean_facade.png`)
- 5 Floating objects: PASS (`590 505 110 70`: the steps and porch posts sit in the porch shadow, with nothing visibly hovering)
- 6 Repetition: PASS (the two "A. P. HOLLIS" window signs repeat, but that's believable for a shopfront)
- 7 Empty: FAIL (`0 560 1280 160`: the street is bare dirt with three pebbles; no wagon, trough, barrel, hitching rail, tracks or people; `cut a_bare_street.png`; also `360 340 560 160`: the store reads empty through the glass, `cut a_empty_store.png`)
- 8 Scale tells: PASS (door, steps, windows and railing read right against each other)
- 9 Edges of the world: FAIL (`0 230 290 330`: both neighbours are untextured light-grey boxes, like placeholder blockout; `cut a_grey_neighbours.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Grey placeholder buildings either side** (tell 9, `0 230 290 330`): the store is flanked by blank untextured grey blocks, and they're the first thing that says "unfinished". Cause: geometry. Cheapest fix: give the neighbours any finished facade (even a simple false-front with siding), or frame the shot so they're out of it.
2. **Dead empty street** (tell 7, `0 560 1280 160`): a third of the frame is flat dirt with nothing in it: no ruts, hoofprints, wagon, barrels or people. Cause: dressing. Cheapest fix: wheel ruts and hoof-churned dirt in the ground material, plus one wagon or hitching rail with a horse.
3. **Factory-clean facade** (tell 3, `280 120 720 220`): the siding is a uniform painted tile with no weathering, water streaks or dirt splashed up from the ground. Cause: material. Cheapest fix: a grime and sun-fade gradient, darker and dirtier toward the bottom and streaked under the windows and cornice.
4. **Ruler-perfect symmetry** (tell 4, `280 120 720 220`): the front is dead centred and mirrored, with level lines everywhere, so it reads as a 3D model and not a building. Cause: geometry. Cheapest fix: a slight sag in the porch roof and small lean or height jitter on the posts and window frames.
5. **No air** (tell 2, `0 100 1280 120`): midday desert with no heat haze or dust; the sky is a clean gradient and the distance is as crisp as the foreground. Cause: light. Cheapest fix: warm distance fog and a little low dust over the street.

## b
- 1 Flat light: FAIL (`930 180 350 260`: the interior glows a flat, even grey-white with no lamp, pool of light or falloff, so you can't tell what lights it; `cut b_flat_glow.png`)
- 2 No atmosphere: PASS (dusk tone, deep shadow under the porch; no distance to judge)
- 3 Too clean: PASS (`270 545 370 175`: the steps and boards are properly weathered, grained and knotted)
- 4 Too straight: FAIL (`0 380 1280 180`: the railings are evenly spaced, perfectly vertical balusters running the full length; `cut b_straight_rails.png`)
- 5 Floating objects: PASS (`100 520 1180 200`: the posts go down into dark ground; no obvious hover)
- 6 Repetition: PASS
- 7 Empty: FAIL (`430 220 440 230`: through the big shop windows the store is a bare room of walls and a post, with no shelves, goods, counter or keeper; `cut b_empty_interior.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 90 140 320`: a blank grey box beside the store; `cut b_grey_box.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Empty shop behind the glass** (tell 7, `430 220 440 230`): it's a general store whose windows show nothing but bare striped walls. The eye goes straight there and finds nothing. Cause: dressing. Cheapest fix: a counter and a wall of loaded shelves visible through the door.
2. **Interior lit like a light box** (tell 1, `930 180 350 260`): the inside is a flat, uniform glow with no lamp source, no warm pools and no shadowed corners, which fights the dusk outside. Cause: light. Cheapest fix: one or two warm oil lamps with falloff, and the ambient fill turned down.
3. **Grey placeholder block** (tell 9, `0 90 140 320`): an untextured grey building at the edge of the frame. Cause: geometry. Cheapest fix: texture it or replace it with a finished facade.
4. **Machine-even railings** (tell 4, `0 380 1280 180`): every baluster has identical spacing and is perfectly plumb. Cause: geometry. Cheapest fix: a little jitter in spacing and tilt, and one broken or missing baluster.
5. **Nothing on the porch** (tell 7, `430 440 800 100`): no crates, sacks, broom, bench or goods on a store's porch. Cause: dressing. Cheapest fix: a few barrels and sacks stacked by the door and a bench against the wall.

## c
- 1 Flat light: PASS (`0 440 1280 280`: low sun throws post shadows and window shafts across the floor; the direction is clear)
- 2 No atmosphere: FAIL (`380 300 520 220`: strong sun shafts come in through the windows, but there's no dust in the air and no bloom, so the room feels vacuum-sealed; `cut c_no_dust.png`)
- 3 Too clean: FAIL (`0 440 1280 280`: the floor is a glossy, varnished, showroom-perfect plank with no scuffs, worn path to the door or tracked-in dirt; `cut c_glossy_floor.png`)
- 4 Too straight: FAIL (`0 200 1280 300`: perfectly mirrored symmetry, with identical posts, brackets, windows and walls left and right; `cut c_empty_room.png`)
- 5 Floating objects: FAIL (`580 440 120 110`: two flat grey rectangles sit on the floor like unlit patches or z-fighting; `cut c_floor_squares.png`; also `1190 310 70 50`: the wall lamp is a tiny stuck-on object, `cut c_wall_lamp.png`)
- 6 Repetition: PASS (the mirrored sign is correct seen from inside)
- 7 Empty: FAIL (`0 200 1280 300`: a big store floor with nothing on it but two small tables of goods by the windows; no counter, shelves, stove or stock; `cut c_empty_room.png`)
- 8 Scale tells: PASS (posts, windows and door read right; the room is perhaps generous)
- 9 Edges of the world: FAIL (`320 270 640 180`: the windows look out onto a blank white-grey wall and a flat desert; `cut c_window_backdrop.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **An empty room, not a store** (tell 7, `0 200 1280 300`): a general store with a bare floor, no counter, no shelving and no goods on the walls. It reads like a level before dressing. Cause: dressing. Cheapest fix: a long counter with a till, and floor-to-ceiling shelves of tins and bolts along one wall.
2. **Grey rectangles on the floor** (tell 5, `580 440 120 110`): two flat, untextured grey squares in the middle of the floor look like a rendering bug. Cause: material. Cheapest fix: remove them, or give them the floor's material if they're trapdoors or registers.
3. **Showroom floor** (tell 3, `0 440 1280 280`): high-gloss, evenly varnished boards with no wear path from the door, no boot scuffs and no dust. Cause: material. Cheapest fix: drop the gloss and add a worn, dirtier traffic lane from the door to where the counter would be.
4. **Blank world outside the windows** (tell 9, `320 270 640 180`): through the glass are untextured white walls and an empty desert plane. Cause: geometry. Cheapest fix: a textured building across the street, or frosted or dirty glass that hides it.
5. **Sunbeams in clean air, perfect symmetry** (tells 2 and 4, `380 300 520 220`): with light shafts this strong, no dust in the air and a mirror-perfect layout make it feel like an architectural render. Cause: light. Cheapest fix: volumetric dust in the window light.

## Ranking
From least to most cheap-looking: c, a, b
