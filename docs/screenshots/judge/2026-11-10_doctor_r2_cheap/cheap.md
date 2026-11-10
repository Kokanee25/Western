# Cheap judge, 2026-11-10_doctor_r2_cheap

## a
- 1 Flat light: FAIL (`405 310 480 200`; `a_front_shade.png`): the whole front of the house sits in one even blue-grey shade, blacks lifted; only the porch's cast shadow on the sand gives the sun a direction.
- 2 No atmosphere: FAIL (`870 330 410 120`; `a_crisp_distance.png`): the boxes and fence behind the house as crisp as the porch; no dust or haze between them and us; the noon air is clean glass.
- 3 Too clean: FAIL (`0 560 1280 160`; `a_bare_ground.png`): the ground is one flat sand colour to the camera, no ruts, prints, stones or grass, no dirt where the steps meet it.
- 4 Too straight: FAIL (`370 115 560 460`; `a_symmetric_house.png`): the house dead square-on and mirror-symmetric, the ridge, eaves and porch beam ruler-straight; the old timber has some patching but nothing sags.
- 5 Floating objects: PASS (porch steps and fences sit in their shadows)
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 560 1280 160`; `a_bare_ground.png`): no person, horse, barrel, wagon or sign of work anywhere in the frame.
- 8 Scale tells: PASS (door, windows and steps agree with each other)
- 9 Edges of the world: FAIL (`0 140 410 400`; `a_grey_block.png`; and `860 355 140 30`; `a_debug_label.png`): the buildings either side are untextured grey boxes, and a floating debug label ("...ght warehouse and platform") is printed in the air at the back.
- **Verdict: cheap indie**
1. **Greybox buildings and a debug label in shot** (tell 9, `0 140 410 400`, `860 355 140 30`): two of the three buildings are plain grey prisms and there is editor text floating mid-air; a player reads "unfinished prototype" before anything else. Cause: geometry. Cheapest fix: hide the debug labels in screenshots and give the neighbouring blocks even a placeholder clapboard front.
2. **A bare sand plane for a street** (tell 3, `0 560 1280 160`): the bottom third is a single smooth colour with nothing in it; no wheel ruts, hoof prints, puddle stains or grass tufts. Cause: material. Cheapest fix: a ground material with tracks and colour variation, plus scattered stones/scrub decals.
3. **Nothing alive** (tell 7, `0 560 1280 160`): no people or props to say anyone lives here; the doctor's front is a stage set. Cause: dressing. Cheapest fix: a hitching post, a barrel and a crate by the porch steps, a bench on the porch.
4. **The front all one flat shade** (tell 1, `405 310 480 200`): with the sun behind, the facade is a single lifted blue-grey with no bounce from the bright ground and no darker contact under the eaves. Cause: light. Cheapest fix: stronger ground bounce/ambient occlusion so the porch ceiling and corners go darker than the open wall.
5. **Posterised, cartoon sky** (tell 2, `0 0 1280 120`): the clouds are hard-edged flat cut-outs in three tones, which reads painted and toy-like against realistic wood. Cause: material. Cheapest fix: a photographic or smoothly-shaded sky dome without the tone steps.

## b
- 1 Flat light: PASS (backlit by a low sun, long shadows across the street, the house front in shade)
- 2 No atmosphere: PASS (sun rays and a warm haze softening the far blocks and the hill)
- 3 Too clean: FAIL (`0 470 1280 250`; `b_bare_ground.png`): the street is one smooth tan plane, no ruts, prints, stones or tufts.
- 4 Too straight: FAIL (`0 300 300 160`; `b_even_posts.png`): the boardwalk's posts at metronome spacing, its roof beam and deck dead level.
- 5 Floating objects: PASS
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 470 1280 250`; `b_bare_ground.png`): a whole street at golden hour with no one and nothing in it.
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`975 80 305 440`; `b_grey_block.png`; and `600 0 400 300`; `b_posterised_sky.png`): the right and left buildings are untextured grey boxes; the sky is posterised flat cloud shapes.
- **Verdict: cheap indie**
1. **Untextured grey blocks frame the shot** (tell 9, `975 80 305 440`): the right third of the picture is a featureless grey wall with a porch bolted on, the left a long grey box; reads as greybox. Cause: geometry. Cheapest fix: placeholder facades (clapboard, a window and a sign) on every block in view.
2. **An empty plane of a street** (tell 3, `0 470 1280 250`): the foreground half of the frame is smooth tan with nothing to catch the low sun: no ruts, ridges or stones to throw the long shadows that would sell golden hour. Cause: material. Cheapest fix: a rutted, tracked ground texture with some height so the low sun rakes it.
3. **No life** (tell 7, `0 470 1280 250`): no people, horses or carts; the god rays fall on nothing. Cause: dressing. Cheapest fix: a wagon, a tied horse and a couple of figures under the boardwalk roof.
4. **Posterised sky** (tell 9, `600 0 400 300`): cloud shapes in hard flat tone steps, a painted/vector look against the realistic house. Cause: material. Cheapest fix: a smooth-gradient sky texture without banding.
5. **Ruler-straight boardwalk** (tell 4, `0 300 300 160`): evenly spaced posts and a level roof line; no sag, lean or mismatched post. Cause: geometry. Cheapest fix: jitter post spacing and lean, a slight sag in the long beam.

## c
- 1 Flat light: PASS (clear sun on the house's gable side, the porch roof's shadow on the wall, the side wall in shade)
- 2 No atmosphere: FAIL (`0 230 450 270`; `c_crisp_block.png`): the block behind is as crisp and clean as the house; no dust or haze in the air at all.
- 3 Too clean: FAIL (`0 545 1280 175`; `c_bare_ground.png`): the ground a smooth beige slope; nothing at the foot of the house or stair.
- 4 Too straight: PASS (the siding varies board to board, the house has some wear; acceptable)
- 5 Floating objects: PASS (the stair foot and the post sit on the ground with the house's dark footing)
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 545 1280 175`; `c_bare_ground.png`): nothing and no one around the house.
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`880 0 400 590`; `c_beige_wall.png`; and `0 230 450 270`; `c_crisp_block.png`): a huge blank beige wall fills the right third; the left building is an untextured grey box.
- **Verdict: cheap indie**
1. **A blank wall eats a third of the frame** (tell 9, `880 0 400 590`): a flat, featureless beige slab right in front of the camera; no siding, no window, no edge detail. Cause: geometry. Cheapest fix: give the neighbouring building a textured side wall (boards, a window, a downpipe) or move it out of shot.
2. **Bare ground** (tell 3, `0 545 1280 175`): the house stands on a smooth sand slope with no trodden path to its stair, no weeds against the footing, no junk. Cause: material. Cheapest fix: a worn path to the stair and grass/weeds along the foundation.
3. **Greybox block behind** (tell 9, `0 230 450 270`): the left building is a grey prism with a fence stuck to it. Cause: geometry. Cheapest fix: placeholder facade texture.
4. **No air** (tell 2, `0 230 450 270`): everything is crisp; the sun is bright but the air has no warmth or dust in it, so it reads as a render, not a place. Cause: light. Cheapest fix: a little height fog/aerial haze tinted to the sky.
5. **Empty** (tell 7, `0 545 1280 175`): the house itself is the best-made thing in this set (weathered boards, rusty footing, a sunlit gable), but nothing around it says a doctor works here. Cause: dressing. Cheapest fix: a shingle sign, a buggy, a rain barrel at the corner.

## d
- 1 Flat light: FAIL (`0 0 1280 720`; `d_no_source.png`): a dim red-brown murk with no lamp, no window beam, no shadow shape; the orange door slabs glow evenly as if self-lit.
- 2 No atmosphere: FAIL (`690 180 280 250`; `d_no_air.png`): the window's daylight doesn't reach into the room or catch any dust; the back room is just darker, not hazy.
- 3 Too clean: FAIL (`0 450 1000 270`; `d_clean_floor.png`): the floor and walls one uniform polished red wood, no scuffs, dirt in corners or wear at the thresholds.
- 4 Too straight: FAIL (`420 0 600 200`; `d_straight_beams.png`): the beams and door frames perfectly straight and parallel.
- 5 Floating objects: FAIL (`210 285 125 180`; `d_floating_slab.png`): an orange panel stands out from the left wall in mid-air with no hinge, frame or shadow.
- 6 Repetition: FAIL (`210 230 820 350`; `d_same_slabs.png`): the same flat orange door slab three times, in the same colour and texture.
- 7 Empty: FAIL (`0 450 1000 270`; `d_clean_floor.png`): a room with no furniture, no bed, desk, chair or object at all.
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`770 255 90 125`; `d_window_void.png`): the window looks out on a grey void and a bare plane.
- **Verdict: cheap indie**
1. **An empty room** (tell 7, `0 450 1000 270`): a doctor's house with nothing in it: no table, cabinet, bottles, bed or lamp. A player reads "level geometry, not a place." Cause: dressing. Cheapest fix: a desk, a chair, a cot and a shelf of bottles in the front room.
2. **No light source, murky red everywhere** (tell 1, `0 0 1280 720`): you can't say where the light comes from; everything is the same dim red-brown with lifted, muddy darks. Cause: light. Cheapest fix: a lit oil lamp on a table (a warm pool with falloff) or a sun shaft through the window.
3. **Flat orange door slabs** (tells 5 and 6, `210 230 820 350`): the doors are untextured-looking orange boards that glow brighter than the room around them and one floats off the wall. Cause: material. Cheapest fix: give the doors the same lit wood material as the walls, with frames and hinges.
4. **Uniform, spotless wood** (tell 3, `0 450 1000 270`): walls and floor one even polished red; no dirt, wear paths or scuffs. Cause: material. Cheapest fix: a darker worn path through the doorways and grime in the corners.
5. **A void outside the window** (tell 9, `770 255 90 125`): the window shows grey nothing. Cause: geometry. Cheapest fix: something behind the window (the next building's textured side, a fence, the sky).

## e
- 1 Flat light: PASS (sun shafts fall through the windows and the open door as sharp patches on the floor; clear direction)
- 2 No atmosphere: FAIL (`440 470 560 250`; `e_no_dust.png`): the sun patches are on the floor but there's no dust or haze in the beams on their way in.
- 3 Too clean: FAIL (`440 560 560 160`; `e_clean_floor.png`): the boards in the sun are clean, even and new-looking.
- 4 Too straight: PASS
- 5 Floating objects: FAIL (`580 460 60 240`; `e_light_leak.png`): a thin bright segmented sliver runs across the floor from under the door, reading as a light leak or a stray rod lying on nothing.
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 460 1000 260`; `e_empty_room.png`): a sunny room with nothing in it.
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`670 160 345 290`; `e_window_void.png`): the big windows show a flat grey-blue void over a bare fence and plane.
- **Verdict: cheap indie**
1. **An empty room** (tell 7, `0 460 1000 260`): the best-lit room of the set, and nothing in the light: no chair by the window, rug, desk or clutter. Cause: dressing. Cheapest fix: a chair and table in the window light, a rug, something on the sill.
2. **Grey void through the windows** (tell 9, `670 160 345 290`): a flat grey-blue sky with no gradient over a bare fence; it kills the sunlight's story. Cause: light. Cheapest fix: let the windows see the real sky and the street beyond, with some exposure bloom.
3. **Beams with no air** (tell 2, `440 470 560 250`): crisp sun patches but no visible shafts; the room's air is empty. Cause: light. Cheapest fix: light volumetric fog indoors so the window beams show.
4. **The bright sliver on the floor** (tell 5, `580 460 60 240`): a thin segmented bright line from the door edge across the floor looks like a rendering glitch. Cause: geometry. Cheapest fix: close the gap under the door or remove the stray thin piece.
5. **Clean, uniform floor and flat orange doors** (tell 3, `440 560 560 160`): boards uniform and new, the open doors a flat brighter orange than the walls. Cause: material. Cheapest fix: wear and dirt on the floor along the walking line; match the doors' wood to the walls.

## f
- 1 Flat light: FAIL (`0 0 1000 720`; `f_crushed_dark.png`): almost the whole frame is near-black red with no light source and no shapes in it; only the small window reads.
- 2 No atmosphere: FAIL (`740 270 190 120`; `f_window_haze.png`): the window's light stays in the window; no haze or glow spreads into the room.
- 3 Too clean: FAIL (`0 0 480 560`; `f_wall_grain.png`): the walls one even dark red wood, no grime or wear (what can be seen of them).
- 4 Too straight: PASS
- 5 Floating objects: PASS
- 6 Repetition: PASS
- 7 Empty: FAIL (`300 480 700 240`; `f_empty_room.png`): an empty floor and bare walls.
- 8 Scale tells: FAIL (`0 0 480 560`; `f_wall_grain.png`): the wall's wood grain is blown up so each streak is a hand's width and leans diagonally, so the wall reads as a stretched texture, not boards.
- 9 Edges of the world: FAIL (`760 280 155 105`; `f_window_void.png`): the window shows a bare flat plane to a hard horizon.
- **Verdict: cheap indie**
1. **Too dark to read, with no source** (tell 1, `0 0 1000 720`): the room is a red-black murk; the player can't tell what's in it or where light comes from. Cause: light. Cheapest fix: a lamp in the room, or let the window throw a lit patch and bounce.
2. **Stretched, slanted wood grain** (tell 8, `0 0 480 560`): grain streaks far too big and on a slant, no board seams; reads as a scaled texture. Cause: material. Cheapest fix: correct the wall texture's scale and orientation so boards are board-sized and upright.
3. **Empty** (tell 7, `300 480 700 240`): nothing on the floor or walls. Cause: dressing. Cheapest fix: one piece of furniture and a hanging object to give the dark something to shape.
4. **A bare world through the window** (tell 9, `760 280 155 105`): a flat empty plain to a straight horizon. Cause: geometry. Cheapest fix: put the town's buildings or scrub in the window's view.
5. **No air from the window** (tell 2, `740 270 190 120`): the daylight doesn't spill or haze into the room. Cause: light. Cheapest fix: indoor fog density so the window glows into the dark.

## g
- 1 Flat light: FAIL (`0 0 1280 720`; `g_crushed_dark.png`): the frame is nearly all black-red; no source, no shadow shapes, just two door slabs faintly lit.
- 2 No atmosphere: FAIL (`450 180 420 340`; `g_no_air.png`): no air or glow; the doorways open onto more darkness.
- 3 Too clean: FAIL (`850 0 300 500`; `g_wall_grain.png`): the walls one uniform wood texture.
- 4 Too straight: PASS
- 5 Floating objects: PASS
- 6 Repetition: PASS
- 7 Empty: FAIL (`200 480 900 240`; `g_empty_room.png`): a bare floor and two doors, nothing else.
- 8 Scale tells: FAIL (`850 0 300 500`; `g_wall_grain.png`): the wood grain's streaks enormous and slanted across the walls, reading as one stretched texture rather than boards.
- 9 Edges of the world: N/A (no view out)
- **Verdict: cheap indie**
1. **A black frame** (tell 1, `0 0 1280 720`): the player sees almost nothing; a dark room needs one light to shape it, this has none. Cause: light. Cheapest fix: a lamp or a lit doorway beyond, so there's a pool and falloff instead of uniform murk.
2. **Empty** (tell 7, `200 480 900 240`): two doors and a floor. Cause: dressing. Cheapest fix: furniture against the walls.
3. **Stretched grain on the walls** (tell 8, `850 0 300 500`): giant slanted grain streaks with no board seams. Cause: material. Cheapest fix: fix the texture's scale/rotation on the interior walls.
4. **Flat orange door slab** (tell 3, `450 180 420 340`): the one lit object is a smooth orange board with no frame or panel detail. Cause: material. Cheapest fix: panelled door geometry and the walls' wood on it.
5. **No air** (tell 2, `450 180 420 340`): the doorway onto the next room has no haze or light in it to give depth. Cause: light. Cheapest fix: light the next room so the doorway reads as a lit opening.

## h
- 1 Flat light: FAIL (`0 0 1280 720`; `h_crushed_dark.png`): almost all dark red-black; only cool edge-light from the window frames at the sides; no light source in the room.
- 2 No atmosphere: FAIL (`560 150 420 400`; `h_no_air.png`): no haze or glow; the doorway beyond is as murky as the room.
- 3 Too clean: FAIL (`580 0 400 500`; `h_uniform_wall.png`): the walls one even dark wood.
- 4 Too straight: PASS
- 5 Floating objects: PASS (the chimney meets the floor)
- 6 Repetition: PASS
- 7 Empty: FAIL (`200 480 900 240`; `h_empty_room.png`): nothing in the room.
- 8 Scale tells: FAIL (`470 0 110 570`; `h_blotchy_chimney.png`): the chimney/post is wrapped in a low-resolution blotchy brown texture, smeared large, with visible seams between its sections.
- 9 Edges of the world: PASS
- **Verdict: cheap indie**
1. **Too dark, no source** (tell 1, `0 0 1280 720`): the room is murk; the eye has nowhere to go. Cause: light. Cheapest fix: a lamp on a table or a lit stove.
2. **A blotchy low-res chimney** (tell 8, `470 0 110 570`): the brightest thing in the room is a smeared, blurry brown texture with seams, reading as an early-2000s placeholder. Cause: material. Cheapest fix: a proper brick or plastered-stone material at the right scale.
3. **Empty** (tell 7, `200 480 900 240`): no furniture or objects. Cause: dressing. Cheapest fix: a stove, a chair and a shelf by the chimney.
4. **Uniform walls** (tell 3, `580 0 400 500`): one dark wood everywhere, no wear or grime. Cause: material. Cheapest fix: soot above the chimney and grime low on the walls.
5. **No air** (tell 2, `560 150 420 400`): no haze or light through the doorway to give the room depth. Cause: light. Cheapest fix: light the next room and add a little indoor fog.

## Ranking
From least to most cheap-looking: c, e, b, d, a, f, h, g
