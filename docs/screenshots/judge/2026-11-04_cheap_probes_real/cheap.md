# Cheap judge, probes_r0

## a
- 1 Flat light: FAIL (`330 370 320 130`; `cut a_people_ground.png`): the sun sits dead ahead at the street's end, yet both rows of fronts, the men and the horses are lit evenly from the camera's side in one orange; the men and horses throw almost no shadow toward us
- 2 No atmosphere: PASS (`560 180 480 230`): the street's far end and the canyon wash out into warm haze
- 3 Too clean: PASS (the fronts): boards streaked and stained, ruts in the road, dry grass along the porches
- 4 Too straight: FAIL (`380 230 380 200`; `cut a_fronts_row.png`): the fronts stand in a ruler-straight row, porches all at one height, roof lines parallel to the vanishing point; nothing sags
- 5 Floating objects: PASS (`330 370 320 130`): feet and hooves sit on small dark contact patches; the grass hides the posts' feet
- 6 Repetition: FAIL (`0 440 560 160`; `cut a_grass_tufts.png`): the same clump of straw-coloured grass stamped along both porch lines, and the same pale oval pebble scattered over the whole road
- 7 Empty: PASS: men at work, saddled horses, crates, barrels, a wagon, lamps lit
- 8 Scale tells: FAIL (`760 440 520 280`; `cut a_hand_gun.png`): the player's hand is a big, smooth, pink lump made of a few faces, bigger than the revolver's frame; the gun's texture is stretched in streaks
- 9 Edges of the world: FAIL (`560 180 480 230`; `cut a_canyon_sky.png`): the canyon and sky are a painting behind the town: the far fronts are cut out against it, and its brushwork has no depth; the town ends in a picture
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The player's hand and gun** (tell 8, `760 440 520 280`): the first thing in the frame is a smooth pink low-poly hand and a revolver whose metal is smeared streaks; it reads as a placeholder. Cause: geometry. Cheapest fix: a real hand model with skin and a sleeve, and the gun's texture laid out without stretching.
2. **Backlit sun, front-lit town** (tell 1, `330 370 320 130`): the sun is ahead of us but the faces of the buildings, men and horses are all lit as if from behind the camera, with no long shadows coming at us; the light has no story. Cause: light. Cheapest fix: let the low sun put the near sides of the men, horses and posts in shade with long shadows toward the camera, and rim-light their edges.
3. **A painted backdrop** (tell 9, `560 180 480 230`): the canyon and sky are a painting with brush marks, the far fronts cut out against it; realistic 3D in front, a matte painting behind. Cause: geometry. Cheapest fix: a modelled far ridge in the scene's haze, or the backdrop softened and graded into the same air as the street.
4. **Leftover squares and stamped grass** (tell 6, `0 440 560 160`): the same grass clump repeated in a row, the same pebble everywhere, and up close the horses' and men's edges are stair-stepped pixels; a toy-like finish against a realistic aim. Cause: material. Cheapest fix: three or four grass variants scaled and turned at random, and the square-pixel look turned off.
5. **A ruler-straight street** (tell 4, `380 230 380 200`): every front square to the street, every porch at one height, every roof parallel. Cause: geometry. Cheapest fix: a few porches higher or lower by a step, one front leaning, a sagging awning.

## b
- 1 Flat light: FAIL (`540 80 450 400`; `cut b_store_flat.png`): the store's front is one even grey-brown from top to bottom, the porch's shade a soft smudge; noon with no sun shapes on the wall or the street
- 2 No atmosphere: N/A (a square-on view of three fronts; almost no distance in the frame)
- 3 Too clean: FAIL (`480 440 700 280`; `cut b_ground_trough.png`): the sand is bleached almost white and even, the trough's boards new, the signs' paint crisp and fresh; no dirt where the porches meet the ground
- 4 Too straight: FAIL (`0 20 1280 280`; `cut b_fronts_row.png`): three fronts square-on, cornices dead level, identical brackets evenly spaced; nothing leans
- 5 Floating objects: FAIL (`0 330 300 230`; `cut b_horse.png`): the horse's legs bend wrong and its hooves barely touch the sand, its shadow a faint grey patch
- 6 Repetition: FAIL (`740 440 540 80`; `cut b_tufts_row.png`): the same tuft (white grass with black spikes) set in a row along the porches; the same bracket repeated along every cornice
- 7 Empty: FAIL (`300 300 700 200`; `cut b_bare_porches.png`): three porches with almost nothing on them, a couple of dim figures, one horse and one trough on a wide bare street
- 8 Scale tells: FAIL (`0 330 300 230`; `cut b_horse.png`): the horse is small next to the porch and its legs long and bent like a toy's
- 9 Edges of the world: FAIL (`540 0 740 230`; `cut b_sky_streaks.png`): the sky is a smeared texture of white and blue streaks, like a stretched image, not clouds
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A smeared sky** (tell 9, `540 0 740 230`): the sky is diagonal blue and white smears, as if a cloud picture had been stretched; it says "placeholder" at once. Cause: material. Cheapest fix: a real sky (a photographed or simulated cloud dome) at its proper resolution.
2. **Flat noon light** (tell 1, `540 80 450 400`): the fronts are evenly lit grey-brown, the ground bleached white; no hard sun, no shadow shapes, so nothing has volume. Cause: light. Cheapest fix: a high hard sun at an angle so the porch roofs throw sharp shadows down the fronts and the posts throw shadows on the street.
3. **The horse** (tell 8, `0 330 300 230`): the one living thing in the frame is a small dark horse with broken-looking legs and no weight on the ground. Cause: geometry. Cheapest fix: fix its leg pose so its hooves plant under it, with a contact shadow.
4. **A clean, empty street** (tell 7, `300 300 700 200`): bare porches, bleached sand without hoof marks, ruts or dung, fresh signs; nobody lives here. Cause: dressing. Cheapest fix: crates, sacks and barrels on the porches, men on them, dark trodden earth and wheel ruts in front of the doors.
5. **The whole frame is soft and blocky** (no tell; `1150 680 130 40`, `cut b_corner_mark.png`): the picture looks upscaled from a small compressed image, with block artefacts on every edge and a mark in the corner; it reads as a low-quality capture. Cause: camera. Cheapest fix: render and save at full resolution without compression.

## c
- 1 Flat light: FAIL (`330 370 320 130`; `cut c_people_ground.png`): as in a: the sun is ahead, but the men, horses and fronts are evenly lit from the camera's side with almost no shadows toward us
- 2 No atmosphere: PASS (`560 250 360 180`; `cut c_street_end_rays.png`): the street's end is full of warm dust with shafts of light through it, and the far fronts fade
- 3 Too clean: PASS (the fronts): weathered, stained boards, ruts, dry grass
- 4 Too straight: FAIL (`380 230 380 200`; `cut c_fronts_row.png`): the fronts in a ruler-straight row, porches at one height
- 5 Floating objects: PASS (`330 370 320 130`): small contact shadows under feet and hooves
- 6 Repetition: FAIL (`0 440 560 160`; `cut c_grass_tufts.png`): the same grass clump repeated along the porches, the same pebble across the road
- 7 Empty: PASS: men, horses, a wagon, crates, barrels, lamps
- 8 Scale tells: FAIL (`760 440 520 280`; `cut c_hand_gun.png`): the hand is a big smooth pink lump, the gun's texture stretched
- 9 Edges of the world: FAIL (`560 180 480 230`; `cut c_street_end_rays.png`): the canyon and sky are a painted backdrop, the far fronts cut out against it (the rays soften the seam a little)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The player's hand and gun** (tell 8, `760 440 520 280`): a smooth pink low-poly hand and a streaky revolver fill the bottom right; it reads as a placeholder. Cause: geometry. Cheapest fix: a real hand with skin, knuckles and a sleeve, the gun's texture unstretched.
2. **Backlit sun, front-lit town** (tell 1, `330 370 320 130`): the sun is ahead but the near sides of men, horses and posts are lit, with no long shadows coming at us. Cause: light. Cheapest fix: put the near sides in shade with long shadows toward the camera and rim light on their edges.
3. **A painted backdrop** (tell 9, `560 180 480 230`): the canyon is a matte painting with brushwork; the dust shafts help tie it in, but the cut-out far fronts still give it away. Cause: geometry. Cheapest fix: a modelled far ridge in the same haze, or the painting softened into the dust.
4. **Leftover squares and stamped grass** (tell 6, `0 440 560 160`): one grass clump repeated, one pebble everywhere, stair-stepped pixel edges on horses and men. Cause: material. Cheapest fix: grass variants at random scale and turn, and the square-pixel look turned off.
5. **A ruler-straight street** (tell 4, `380 230 380 200`): every front square, every porch level. Cause: geometry. Cheapest fix: vary porch heights by a step and let one front or awning sag.

## d
- 1 Flat light: PASS (`600 420 680 300`): a low sun throws long, clear shadows of the posts and porch across the street; you can tell where the light comes from
- 2 No atmosphere: PASS (`640 200 640 220`): heavy warm haze swallows the far end (though it is one even pink wash over everything)
- 3 Too clean: FAIL (`640 400 640 320`; `cut d_empty_street.png`): the street is one flat, even grey-violet plane: no ruts, no hoof marks, no dirt at the walls' feet
- 4 Too straight: FAIL (`960 280 320 200`; `cut d_box_buildings.png`): the buildings across the street are flat slabs, plumb and square, windows dark rectangles painted on
- 5 Floating objects: FAIL (`960 280 320 200`; `cut d_box_buildings.png`): the walls meet the street with no contact darkening; they sit on it like cardboard
- 6 Repetition: FAIL (`0 120 450 420`; `cut d_porch_texels.png`): the same blotchy nail-mark texture in big squares on every wall, post and beam
- 7 Empty: FAIL (`640 400 640 320`; `cut d_empty_street.png`): no people, no horses; one crate on a street that runs empty to the horizon
- 8 Scale tells: FAIL (`740 450 300 270`; `cut d_hand_gun.png`): the hand and arm are a few pink cubes under a detailed revolver; the far tower is a single spike against an outsized sun
- 9 Edges of the world: FAIL (`960 280 320 200`; `cut d_box_buildings.png`): the far buildings are single walls with nothing behind them, and the horizon is a flat empty line
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Cardboard buildings** (tell 9, `960 280 320 200`): the far side of the street is flat walls with dark rectangles for windows and nothing behind them; it reads as a blockout. Cause: geometry. Cheapest fix: give those fronts depth: porches, roofs, frames and doors, even simple ones.
2. **Big squares on every surface** (tell 6, `0 120 450 420`): the wood is a coarse grid of blotchy squares, the same pattern on every board and post; very low-resolution textures. Cause: material. Cheapest fix: real wood textures at a proper resolution with filtering on.
3. **An empty street** (tell 7, `640 400 640 320`): nobody, no animals, one crate; the town is a set before anyone moved in. Cause: dressing. Cheapest fix: a few people, a hitched horse and a wagon in the street.
4. **A blocky hand** (tell 8, `740 450 300 270`): the arm and hand holding the gun are a few untextured pink boxes; the first thing a player sees. Cause: geometry. Cheapest fix: a modelled hand and sleeve.
5. **A blank ground** (tell 3, `640 400 640 320`): the street is a smooth even plane with only shadows on it: no ruts, dirt, stones or tracks. Cause: material. Cheapest fix: a packed-dirt texture with wheel ruts and darker trodden earth at the porches.

## e
- 1 Flat light: FAIL (`340 300 600 200`; `cut e_flat_fronts.png`): the fronts are evenly dim under the porches and evenly pale above; the ground one bright wash; no sun shapes, shadows faint
- 2 No atmosphere: N/A (a square-on view of the fronts; little distance in the frame)
- 3 Too clean: FAIL (`0 500 1280 220`; `cut e_ground.png`): the ground is even pale sand with a straight dark line across it and a few pebbles, the bench's boards clean; the signs crisply painted
- 4 Too straight: FAIL (`0 180 1280 140`; `cut e_fronts_sky.png`): three fronts square to the camera, cornices level, brackets and posts evenly spaced
- 5 Floating objects: PASS (`235 520 225 70`): the bench and the tufts sit in their own dark contact shadows
- 6 Repetition: FAIL (`480 490 800 80`; `cut e_tufts_row.png`): the same white grass tuft with black spikes repeated along the porches; every window the same four lit dots
- 7 Empty: FAIL (`300 330 700 170`; `cut e_bare_porches.png`): the porches are bare, a lone rider and a half-seen horse; nothing on display, no one at the doors
- 8 Scale tells: FAIL (`700 380 400 340`; `cut e_hand_gun.png`): the hand is huge and smooth, gripping the revolver from the wrong side with the barrel pointing back past it; it doesn't hold the gun
- 9 Edges of the world: PASS (`860 0 420 300`): a real-looking cloud sky and trees behind the telegraph office
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The hand doesn't hold the gun** (tell 8, `700 380 400 340`): a large smooth hand floats at the bottom right with the revolver at a wrong angle across it; it breaks the shot at once. Cause: geometry. Cheapest fix: the gun seated in the palm with the fingers round the grip, pointing forward.
2. **Flat, washed light** (tell 1, `340 300 600 200`): the fronts and ground are low-contrast and evenly lit, with no sun shapes; the frame looks greyed. Cause: light. Cheapest fix: a hard sun at an angle with sharp porch-roof shadows down the fronts, and the blacks under the porches kept dark.
3. **Bare porches, quiet street** (tell 7, `300 330 700 170`): three shops with nothing outside them and one rider. Cause: dressing. Cheapest fix: goods, barrels and sacks on the porches and a couple of townsfolk at the doors.
4. **Stamped grass and same windows** (tell 6, `480 490 800 80`): one grass tuft repeated along the porches, every window the same lit dots. Cause: dressing. Cheapest fix: grass variants and spacing at random; vary what's behind each window.
5. **Clean sand and square fronts** (tell 3, `0 500 1280 220`): pale even sand, fresh paint, three fronts square to the camera; plus the whole frame is soft, as if upscaled from a small image. Cause: material. Cheapest fix: trodden dark earth and hoof prints in front of the doors, and a render at full resolution.

## Ranking
From least to most cheap-looking: c, a, e, b, d
