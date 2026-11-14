# Cheap judge, 2026-11-10_doctor_cheap

## a
- 1 Flat light: PASS (`380 540 740 70`: the sun's cast shadows under the porch and fence say where the light is)
- 2 No atmosphere: FAIL (`860 330 200 120`; `a_a_far_no_haze.png`)
- 3 Too clean: FAIL (`380 540 520 140`; `a_a_ground_clean.png`)
- 4 Too straight: FAIL (`370 110 560 200`; `a_a_symmetric_gable.png`)
- 5 Floating objects: PASS (`390 490 520 80`: steps and porch footings sit in their own shadow)
- 6 Repetition: PASS (whole frame)
- 7 Empty: FAIL (`0 560 1280 160`; `a_a_empty_street.png`)
- 8 Scale tells: PASS (`600 350 50 140`: door, steps and porch read the right size)
- 9 Edges of the world: FAIL (`0 140 410 400`; `a_a_greybox_left.png`; `860 190 420 260`; `a_a_greybox_label.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Untextured grey blocks and a debug label** (tell 9, `860 190 420 260`): both neighbours are plain grey boxes with no windows, boards or roofs, and a floating text label "...ght warehouse and platform" sits on the far wall. A player reads a greybox level, not a town. Cause: geometry. Cheapest fix: hide the debug labels and put any textured facade (even a borrowed one) on the blockout boxes in view.
2. **A street with nothing in it** (tell 7, `0 560 1280 160`): a third of the frame is bare, even sand: no people, wagon, barrel, trough, sign or hitching rail. Cause: dressing. Cheapest fix: a few props at the porch and fence (barrel, bench, crate, a tied horse) and one figure.
3. **Ground like a clean floor** (tell 3, `380 540 520 140`): the sand is one flat tone right up to the steps; no tracks, ruts, stones, grass tufts or dirt piled where wood meets ground. Cause: material. Cheapest fix: a ground material with tracks, pebbles and darker trodden earth, plus a dirt decal at every footing.
4. **A dead-symmetric front** (tell 4, `370 110 560 200`): the gable, porch and two windows mirror exactly, ridge and eaves ruler-straight, the sign board pale and unlettered. Cause: geometry. Cheapest fix: break the symmetry (one shutter, a sagging porch beam, a lettered sign).
5. **Clear, sharp distance** (tell 2, `860 330 200 120`): the far building is as crisp as the near post; nothing softens with distance, no dust in the light. Cause: light. Cheapest fix: more height/distance fog with a warm dust tint.

## b
- 1 Flat light: FAIL (`280 300 580 200`; `b_b_flat_front.png`)
- 2 No atmosphere: PASS (`0 0 450 300`: sun glare and rays, the far buildings softened)
- 3 Too clean: FAIL (`0 480 1280 240`; `b_b_ground_clean.png`)
- 4 Too straight: FAIL (`350 170 500 160`; `b_b_straight_roof.png`)
- 5 Floating objects: PASS (`290 430 380 60`: the steps and fence sit in the shade band)
- 6 Repetition: FAIL (`0 300 300 160`; `b_b_porch_posts.png`)
- 7 Empty: FAIL (`0 450 1280 270`; `b_b_empty_street.png`)
- 8 Scale tells: PASS (whole frame)
- 9 Edges of the world: FAIL (`975 80 305 330`; `b_b_greybox_right.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Greybox buildings beside a finished one** (tell 9, `975 80 305 330`): the building on the right and the long one on the left are flat grey walls with a porch stuck on; the house in the middle is the only thing that looks built. Cause: geometry. Cheapest fix: give the blockout walls siding and windows, or frame the shot so they aren't in it.
2. **The backlit house is a flat, lifted grey-brown** (tell 1, `280 300 580 200`): with the sun behind it the front is one even murky tone, no bounce from the ground, no rim on the roof edge, the darks milky. Cause: light. Cheapest fix: deepen the shade side's blacks and add a warm ground bounce and rim on edges facing the sun.
3. **The street is empty** (tell 7, `0 450 1280 270`): a wide, flat road with no people, horses, wagons, tracks or clutter. Cause: dressing. Cheapest fix: dress the boardwalk fronts with barrels, crates and a hitching rail, and wheel ruts down the road.
4. **Ground with no wear** (tell 3, `0 480 1280 240`): sand one smooth tone with a single hard shadow line; nothing trodden or rutted. Cause: material. Cheapest fix: a road material with ruts, hoof prints and darker damp patches.
5. **Rows of identical posts and steps, roofs dead straight** (tells 6/4, `0 300 300 160`, `350 170 500 160`): the left porch is one post repeated at even spacing with identical step blocks; the house roof and eaves are perfect lines. Cause: geometry. Cheapest fix: vary post spacing, lean and step height; a slight sag in the ridge and porch beams.

## c
- 1 Flat light: PASS (`500 300 300 240`: the porch roof's shadow falls across the siding, light clearly from the left)
- 2 No atmosphere: FAIL (`0 230 450 270`; `c_c_crisp_distance.png`)
- 3 Too clean: FAIL (`0 540 1280 180`; `c_c_ground_clean.png`)
- 4 Too straight: FAIL (`450 180 350 330`; `c_c_plumb_siding.png`)
- 5 Floating objects: FAIL (`860 520 420 100`; `c_c_wall_no_contact.png`)
- 6 Repetition: PASS (whole frame)
- 7 Empty: FAIL (`0 480 900 240`; `c_c_empty_lot.png`)
- 8 Scale tells: PASS (`460 360 200 180`: stair, door and window sizes agree)
- 9 Edges of the world: FAIL (`880 0 400 590`; `c_c_greybox_wall.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A giant blank wall fills a third of the frame** (tell 9, `880 0 400 590`): a featureless beige slab on the right and a grey box on the left, both untextured; the house sits between placeholders. Cause: geometry. Cheapest fix: texture the blockouts or move the camera so the house is framed by finished things.
2. **Bare sand all round** (tell 7, `0 480 900 240`): a yard and lot with nothing in it: no woodpile, outhouse, cart, washtub, weeds. Cause: dressing. Cheapest fix: three or four lived-in props by the back stair and along the fence.
3. **Smooth, spotless ground and no contact** (tells 3/5, `0 540 1280 180`, `860 520 420 100`): the sand is a single smooth gradient, and the big wall meets it with no shadow or dirt line at all. Cause: material. Cheapest fix: ground texture with tracks and stones, and an ambient-occlusion/dirt band where walls meet ground.
4. **Siding too regular** (tell 4, `450 180 350 330`): the house is the best-made thing here (weathered boards, a cast shadow) but its walls are plumb and its boards evenly spaced with no warp, sag or missing board. Cause: geometry. Cheapest fix: a slight lean and sag, one or two boards loose or missing.
5. **Crisp air** (tell 2, `0 230 450 270`): sky and far box as sharp and saturated as the near house; the posterised, flat-coloured cloud shapes read painted, not real. Cause: light. Cheapest fix: distance haze, and a sky with soft gradients instead of flat-coloured cloud patches.

## d
- 1 Flat light: FAIL (`380 260 600 120`; `d_d_flat_dots.png`)
- 2 No atmosphere: FAIL (`560 250 160 200`; `d_d_no_air.png`)
- 3 Too clean: FAIL (`100 520 450 200`; `d_d_floor_clean.png`)
- 4 Too straight: FAIL (`520 0 260 600`; `d_d_straight_corridor.png`)
- 5 Floating objects: FAIL (`770 580 160 100`; `d_d_post_foot.png`)
- 6 Repetition: PASS (whole frame)
- 7 Empty: FAIL (`80 50 450 540`; `d_d_empty_room.png`)
- 8 Scale tells: PASS (`570 250 140 330`: doorway and corridor proportions read right)
- 9 Edges of the world: FAIL (`600 260 80 140`; `d_d_blank_outside.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Dim, sourceless fill with glowing dots** (tell 1, `380 260 600 120`): the room is one murky red-brown; two small blue-white points float on the walls with no lamp, sconce or light on anything around them. You can't tell where light comes from. Cause: light. Cheapest fix: put a visible lamp at each light and let it throw a warm pool and shadows; remove lights with no fixture.
2. **An empty room** (tell 7, `80 50 450 540`): bare walls and floor, no furniture, no doctor's things (cabinet, cot, bottles, chair). Cause: dressing. Cheapest fix: a desk, a chair and a shelf of bottles in view.
3. **No air in the corridor** (tell 2, `560 250 160 200`): the bright doorway at the end throws no light down the hall and no haze glows in it, unlike a real dim interior. Cause: light. Cheapest fix: volumetric fog indoors so the doorway's light becomes a soft beam.
4. **Uniform walls and floor, a post in a slot** (tells 3/5, `100 520 450 200`, `770 580 160 100`): the same flat stained wood from end to end with no scuffs at the doorways; the right post stands in a dark rectangular gap in the floor; the big orange slab at the right edge is a blotchy low-res texture. Cause: material. Cheapest fix: worn paths and scuffs on the floor, and fix the floor around the post.
5. **Nothing outside** (tell 9, `600 260 80 140`): the far door shows a blank pale void with a grey block. Cause: geometry. Cheapest fix: put something (a fence, a building, a sky) behind each exterior door in view.

## e
- 1 Flat light: PASS (`690 540 300 180`: sun patches on the floor through the window, dark room around them)
- 2 No atmosphere: FAIL (`690 440 300 280`; `e_e_no_beam.png`)
- 3 Too clean: FAIL (`690 540 300 180`; `e_e_floor_clean.png`)
- 4 Too straight: PASS (whole frame: a room's lines are straight, nothing jars)
- 5 Floating objects: PASS (`520 220 120 300`: the doors sit at the floor)
- 6 Repetition: PASS (whole frame)
- 7 Empty: FAIL (`0 300 680 420`; `e_e_empty_room.png`)
- 8 Scale tells: PASS (whole frame)
- 9 Edges of the world: FAIL (`680 140 350 300`; `e_e_blank_window.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **An empty room** (tell 7, `0 300 680 420`): two open doors, a window, and nothing else: no bed, table, rug, clutter. The best light of the set falls on bare boards. Cause: dressing. Cheapest fix: furnish it (a bed or desk under the window, a chair the sun lands on).
2. **The sun on the floor but no beam in the air** (tell 2, `690 440 300 280`): bright sun patches with sharp edges, yet no dust in the shaft between window and floor. Cause: light. Cheapest fix: a little indoor volumetric fog so the sunlight shows as shafts.
3. **The outside is a grey void** (tell 9, `680 140 350 300`): through the window, a flat grey sky and a plain fence; the grey doesn't match the sunlight on the floor, so the light makes no sense. Cause: light. Cheapest fix: show the sunlit street or sky through the window, matching the sun's colour.
4. **Clean, even floorboards** (tell 3, `690 540 300 180`): fine grain, but no wear by the door, no dust, no scuffs; walls one tone. Cause: material. Cheapest fix: wear paths and a grime gradient along the wall bottoms.
5. **A thin bright light-leak line** (tell 1/5, `595 470 40 220`): a hairline of light runs across the floor from the open door's hinge side, reading as a render gap. Cause: geometry. Cheapest fix: close the gap between door and frame so the shadow is solid.

## f
- 1 Flat light: FAIL (`660 150 300 250`; `f_f_flat_dot.png`)
- 2 No atmosphere: FAIL (`360 140 200 190`; `f_f_window_no_spill.png`)
- 3 Too clean: FAIL (`0 300 400 400`; `f_f_wall_uniform.png`)
- 4 Too straight: PASS (whole frame)
- 5 Floating objects: PASS (`150 470 500 250`: the skirting meets the floor)
- 6 Repetition: PASS (whole frame)
- 7 Empty: FAIL (`0 0 660 720`; `f_f_empty_hall.png`)
- 8 Scale tells: PASS (whole frame)
- 9 Edges of the world: FAIL (`380 160 140 150`; `f_f_window_blank.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A window of flat grey** (tell 9, `380 160 140 150`): the pane is a solid light-grey rectangle, nothing outside. Cause: geometry. Cheapest fix: a sky or building behind every window, or frosted/dirty glass with a texture.
2. **No light from the window into the hall** (tell 2, `360 140 200 190`): the brightest thing in the frame lights nothing: no spill on the sill or the boards. Cause: light. Cheapest fix: a window light/area light so the wall around the frame warms.
3. **Murky fill and a lone glowing dot** (tell 1, `660 150 300 250`): everything is the same dim grey-red, and a small blue point floats on the door with no lamp. Cause: light. Cheapest fix: remove the stray light point; light the hall from its window and one lamp.
4. **A bare corridor** (tell 7, `0 0 660 720`): no coat hooks, pictures, rug or chair. Cause: dressing. Cheapest fix: a coat on a hook, a framed picture and a runner on the floor.
5. **Uniform board walls** (tell 3, `0 300 400 400`): the planks are one even dark grey-blue to the end of the hall, with no grime at the bottom or wear at hand height. Cause: material. Cheapest fix: a grime and wear gradient on the lower wall.

## g
- 1 Flat light: PASS (`150 0 520 540`: one warm light, falling off into deep black)
- 2 No atmosphere: FAIL (`180 200 170 90`; `g_g_glow_no_air.png`)
- 3 Too clean: FAIL (`150 380 500 160`; `g_g_wall_uniform.png`)
- 4 Too straight: PASS (whole frame)
- 5 Floating objects: N/A (`240 430 420 120`: the floor is unlit, the contact can't be seen)
- 6 Repetition: PASS (whole frame)
- 7 Empty: FAIL (`660 0 620 720`; `g_g_black_void.png`)
- 8 Scale tells: PASS (whole frame)
- 9 Edges of the world: FAIL (`130 0 560 560`; `g_g_wall_alone.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Two thirds pitch black** (tell 7, `660 0 620 720`): the right of the frame is an unreadable void; the player can't tell if there's a room there. Cause: light. Cheapest fix: a low fill (moonlight through the window, a lamp's bounce) so shapes read in the dark.
2. **A lit wall standing alone in the dark** (tell 9, `130 0 560 560`): one tilted panel with a window floats in black with no floor, ceiling or corner around it; it reads as a stage flat. Cause: light. Cheapest fix: let the same light reach the floor and ceiling beside the wall.
3. **A light with no lamp** (tell 2, `180 200 170 90`): a hard-edged warm semicircle on the wall and no fixture, flame or glow in the air making it. Cause: light. Cheapest fix: put the lamp in view, with a glow and soft haze round its flame.
4. **Glossy, uniform boards** (tell 3, `150 380 500 160`): the planks shine like varnished plastic, one tone, no wear. Cause: material. Cheapest fix: lower the gloss, add grime and edge wear.
5. **The window shows a flat brown plane** (tell 9, `415 160 115 210`): no night outside, just a tinted block. Cause: geometry. Cheapest fix: a night sky or the next building through it.

## h
- 1 Flat light: FAIL (`0 400 520 320`; `h_h_no_spill.png`)
- 2 No atmosphere: FAIL (`100 100 280 450`; `h_h_wall_unlit.png`)
- 3 Too clean: FAIL (`0 0 380 600`; `h_h_wall_uniform.png`)
- 4 Too straight: PASS (whole frame)
- 5 Floating objects: PASS (`100 520 420 200`: the skirting meets the floor)
- 6 Repetition: PASS (whole frame)
- 7 Empty: FAIL (`520 0 760 720`; `h_h_door_slab.png`)
- 8 Scale tells: PASS (whole frame)
- 9 Edges of the world: FAIL (`380 150 130 260`; `h_h_window_blank.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A window of solid beige** (tell 9, `380 150 130 260`): the pane is one flat colour, blown out, nothing beyond it. Cause: geometry. Cheapest fix: a real view or textured glass behind it.
2. **The bright window lights nothing** (tells 1/2, `0 400 520 320`, `100 100 280 450`): a blazing window beside a wall and floor that stay dark and even; no spill, no shaft, no air. Cause: light. Cheapest fix: a light at the window so the sill, wall and floor catch it.
3. **A huge dark slab fills the frame** (tell 7, `520 0 760 720`): over half the picture is the flat face of a door or wall a step away, nothing on it. Cause: camera. Cheapest fix: don't frame the shot with a near blank surface; pull back or turn so the room shows.
4. **Uniform walls** (tell 3, `0 0 380 600`): the boards are one dark tone, clean top to bottom. Cause: material. Cheapest fix: grime low, wear at hand height.
5. **An empty corner** (tell 7, `0 0 520 720`): nothing hung, stood or dropped anywhere in view. Cause: dressing. Cheapest fix: a hook with a coat and a crate under the window.

## Ranking
From least to most cheap-looking: e, c, b, a, d, f, h, g
