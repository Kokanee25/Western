# Cheap judge, cheap

## a
- 1 Flat light: FAIL (`0 200 380 330`, the side building lit as one even pale-blue plane with no shape; `cut a_blank_wall.png`)
- 2 No atmosphere: PASS (`870 400 410 110`, the mountains go pale and blue in the distance)
- 3 Too clean: FAIL (`0 200 380 330`, a bare untextured wall with no siding, trim or wear; `cut a_blank_wall.png`)
- 4 Too straight: FAIL (`360 230 420 270`, the facade, porch rail and posts are perfectly plumb and level; `cut a_porch_base.png`)
- 5 Floating objects: PASS (`360 470 420 70`, the porch base sits in shadow on the ground)
- 6 Repetition: FAIL (`440 255 255 75`, the sign board shows a stamped, repeated smudge pattern where the lettering should be; `cut a_sign_blotch.png`)
- 7 Empty: FAIL (`0 520 1280 200`, a wide bare dirt street with a few pebbles and nothing else: no ruts, wagon, barrel or person; `cut a_empty_street.png`)
- 8 Scale tells: PASS (the doors, steps and the figure in the doorway agree)
- 9 Edges of the world: FAIL (`870 400 410 110`, flat empty plain to a ruler-straight horizon, with the train sitting on it like a cut-out; `cut a_flat_horizon.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **An untextured grey box for a building** (tell 3, `0 200 380 330`): the whole left third is a blank pale block with a porch bolted to it, so it reads as greybox or unfinished. Cause: material. Cheapest fix: give it the same clapboard siding, trim and roof as its neighbour.
2. **The sign is a smudge** (tell 6, `440 255 255 75`): the false-front sign board shows a repeated grey blotch, not lettering or weathered paint. Cause: material. Cheapest fix: paint real lettering ("UNDERTAKER") or leave the board plain and weathered.
3. **An empty street** (tell 7, `0 520 1280 200`): half the frame is flat brown dirt with scattered pebbles; nothing says a town lives here. Cause: dressing. Cheapest fix: wheel ruts, hoof prints, a hitching rail and a barrel or crate by the porch.
4. **A flat, empty horizon** (tell 9, `870 400 410 110`): the plain runs dead flat to the mountains and the train sits on it with no track bed, poles or brush. Cause: geometry. Cheapest fix: low rolling ground, scrub and a telegraph line along the track.
5. **Flat, even light on the walls** (tell 1, `0 200 380 330`): the low sun gives the street a shadow, but the building faces are an even cool fill with no shape. Cause: light. Cheapest fix: let the low sun rake across the facades, warm, with a darker side wall.

## b
- 1 Flat light: PASS (`0 430 1280 290`, there's a real shadow across the yard and a lit sunset glow top left)
- 2 No atmosphere: FAIL (`730 230 110 100`, the distance is as crisp as the foreground, with no dust in the low sun; `cut b_grey_boxes.png`)
- 3 Too clean: FAIL (`0 120 730 310`, the white siding is spotless and even from end to end, with no dirt at the base; `cut b_clean_siding.png`)
- 4 Too straight: FAIL (`0 120 730 310`, the eave, siding and windows are dead level and evenly spaced; `cut b_clean_siding.png`)
- 5 Floating objects: FAIL (`480 360 150 70`, the cellar doors are flat pale slabs propped in the air with no hinges and no contact; `cut b_floating_doors.png`)
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 430 1280 290`, a large bare gravel yard; `cut b_empty_yard.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`730 230 110 100`, untextured grey boxes stand in the gap between buildings; `cut b_grey_boxes.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Greybox buildings in the gap** (tell 9, `730 230 110 100`): plain grey blocks fill the view between the two buildings and give the game away at once. Cause: geometry. Cheapest fix: finish those buildings, or turn the camera or put a fence and a shed so that gap is closed.
2. **A blank white door on the barn** (tell 3, `940 250 105 180`): a flat, untextured off-white rectangle on an otherwise weathered barn, plus a white beam above it. Cause: material. Cheapest fix: plank the door in the barn's weathered wood.
3. **Paper cellar doors** (tell 5, `480 360 150 70`): two thin, flat-coloured panels with no wood, hinges or frame, and a ramp that doesn't meet them. Cause: geometry. Cheapest fix: plank doors with strap hinges set into a framed hatch.
4. **Spotless, ruler-straight siding** (tell 3/4, `0 120 730 310`): perfect white boards with no grime, rain streaks or sag. Cause: material. Cheapest fix: dirt and splash darkening up the bottom of the walls and streaks under the windows.
5. **An empty yard** (tell 7, `0 430 1280 290`): a third of the frame is bare gravel. Cause: dressing. Cheapest fix: a wagon, a coffin stack or lumber, a water trough, a path worn to the door.

## c
- 1 Flat light: PASS (`500 300 400 300`, the sun comes in through the doors and window and throws strong shadows across the floor)
- 2 No atmosphere: FAIL (`300 250 700 300`, sunbeams through the doorway but no dust caught in them; the air is clear)
- 3 Too clean: FAIL (`0 60 520 480`, the board walls are even and clean from floor to ceiling; `cut c_clean_walls.png`)
- 4 Too straight: FAIL (`300 100 700 150`, the ceiling boards break into hard moiré rings and bands; everything is laid dead square; `cut c_ceiling_moire.png`)
- 5 Floating objects: PASS (`720 380 170 60`, the table has a shadow and a rug under it)
- 6 Repetition: FAIL (`300 100 700 150`, the ceiling texture tiles into a visible ripple pattern; `cut c_ceiling_moire.png`)
- 7 Empty: FAIL (`0 250 1280 470`, a big room holding only one table and a counter: nothing hangs on the walls and nothing is stored; `cut c_empty_room.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **A shimmering ceiling** (tell 6, `300 100 700 150`): the ceiling boards alias into concentric moiré rings, the first thing the eye goes to. Cause: material. Cheapest fix: mipmaps or anisotropic filtering on that texture, or wider boards.
2. **An empty room** (tell 7, `0 250 1280 470`): an undertaker's shop with almost nothing in it, no coffins, tools, shelves or calendar. Cause: dressing. Cheapest fix: a coffin on trestles, planks against a wall, a shelf of jars, a hat on a peg.
3. **Clean walls** (tell 3, `0 60 520 480`): the boarding is even and unmarked, with no scuffs by the doors or soot near the lamp. Cause: material. Cheapest fix: grime and scuffing near the floor and around door frames.
4. **No dust in the sunbeams** (tell 2, `300 250 700 300`): good sun shapes on the floor, but the air between is empty. Cause: light. Cheapest fix: light volumetric fog or dust motes in the sun shafts.
5. **Square and level everywhere** (tell 4, `0 60 1280 660`): posts, beams and boards are perfectly true. Cause: geometry. Cheapest fix: a slight sag in the long beam and a few boards out of line.

## d
- 1 Flat light: PASS (`0 0 1280 600`, warm sun shapes and shadows across the floor)
- 2 No atmosphere: N/A
- 3 Too clean: FAIL (`980 0 300 300`, clean, even wall boards; `cut d_clean_wall.png`)
- 4 Too straight: PASS (the stair rail and old timbers have some wear and character)
- 5 Floating objects: PASS (`420 320 360 240`, the stairs sit in the hatch)
- 6 Repetition: FAIL (`0 140 560 420`, the floorboards repeat one grain over and over; `cut d_plank_repeat.png`)
- 7 Empty: FAIL (`0 0 1280 720`, a big bare floor seen from above, nothing on it)
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A blue camouflage cellar floor** (tell 3, `550 180 200 370`): down the hatch, the floor is bright blue-and-yellow blocky camo, like a placeholder or a missing texture. It wrecks an otherwise decent shot. Cause: material. Cheapest fix: give the cellar a packed-earth or stone floor in dark, dull colours.
2. **Repeated floor grain** (tell 6, `0 140 560 420`): every board carries the same glossy grain, row after row. Cause: material. Cheapest fix: vary the plank tint and grain offset, and dull the gloss.
3. **A bare floor** (tell 7, `0 0 1280 720`): nothing lies on the boards, no sawdust, tools or rugs. Cause: dressing. Cheapest fix: sawdust and shavings round the hatch, a crate or rope coil by it.
4. **Plastic shine on the floor** (tell 3, `0 140 560 420`): the boards look varnished and new, not trodden. Cause: material. Cheapest fix: rougher, duller floor with worn paths to the doors.
5. **Clean walls** (tell 3, `980 0 300 300`): even painted boards with no wear. Cause: material. Cheapest fix: grime along the skirting.

## e
- 1 Flat light: PASS (`880 180 120 100`, the wall lamp casts a warm pool; there's falloff into the dark)
- 2 No atmosphere: FAIL (`340 180 600 220`, the lamplight has no haze in the air)
- 3 Too clean: FAIL (`340 340 940 380`, the floor is bright blocky blue camo, not dirt or stone; `cut e_blue_tiles.png`)
- 4 Too straight: PASS (the hewn beams and posts have some irregularity)
- 5 Floating objects: FAIL (`440 390 500 220`, the tables stand on the bright tiles with no contact shadow; `cut e_blue_table.png`)
- 6 Repetition: FAIL (`340 340 940 380`, the same camo tile repeats across the floor and up the walls; `cut e_blue_tiles.png`)
- 7 Empty: FAIL (`340 180 600 220`, two plain tables and nothing else; `cut e_empty_cellar.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 175 1280 95`, a hard black band runs right across the frame, a render or clipping fault; `cut e_black_band.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A black band across the picture** (tell 9, `0 175 1280 95`): a hard-edged dark stripe cuts the whole frame in two, which reads as broken. Cause: camera. Cheapest fix: find what's drawn in front of the camera (the floor above or a fog plane) and clip it.
2. **Blue camouflage floor and walls** (tell 3/6, `340 340 940 380`): a posterised blue, yellow and purple block pattern stands in for the cellar's surfaces and looks like a missing texture. Cause: material. Cheapest fix: dark earth or flagstone, low saturation.
3. **Blotchy wall** (tell 6, `80 260 280 460`): the near-left wall is the same blurry camo, smeared and low-res. Cause: material. Cheapest fix: the same rough boarding as the back wall.
4. **Floating, blue-black tables** (tell 5, `440 390 500 220`): the tables are tinted an unnatural blue and have no shadow on the floor. Cause: light. Cheapest fix: contact shadows (AO) and a neutral wood colour.
5. **An empty cellar** (tell 7, `340 180 600 220`): an embalming room with two tables and nothing else. Cause: dressing. Cheapest fix: a coffin, a sheet on one table, a bucket, jars on a shelf.

## Ranking
From least to most cheap-looking: c, d, a, b, e
