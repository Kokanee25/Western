# Cheap judge, 2026-11-12_doctor_light_before

## a
- 1 Flat light: FAIL (`300 180 660 420`; `cut a_a_flat_desk.png`): the desk and walls sit in one dim, even tone; no lamp, window or shadow shape tells you where the light comes from; the warm left wall and cold right wall read as two tints, not two lights.
- 2 No atmosphere: FAIL (`0 0 640 720`; `cut a_a_noair_wall.png`): no air, glow or falloff in the room; the wall is the same value top to bottom.
- 3 Too clean: FAIL (`380 340 560 300`; `cut a_a_clean_desk.png`): the desk is one glossy, saturated red-mahogany with a smeared, procedural-looking grain; no wear on edges, handles or the writing surface; pale light-leak slivers along the drawer seams.
- 4 Too straight: FAIL (`0 0 1280 260`; `cut a_a_straight_boards.png`): the wall boards are perfectly plumb and evenly spaced, the desk perfectly square.
- 5 Floating objects: PASS (the desk and chair sit in dark at the floor).
- 6 Repetition: PASS.
- 7 Empty: FAIL (`530 350 280 120`; `cut a_a_empty_blotter.png`): a doctor's desk with a bare blotter, one inkstand and a few identical slips in the pigeonholes; nothing says anyone writes here.
- 8 Scale tells: PASS.
- 9 Edges of the world: N/A (interior).
- 10 Stiff people: N/A (a still).
- **Verdict: cheap indie**
1. **No readable light** (tell 1, `300 180 660 420`): the whole picture is a murky, even dim with no key light, so the best-modelled object in it, the roll-top, reads as a dark lump. Cause: light. Cheapest fix: one real source (a desk lamp or the window) throwing a lit pool and a cast shadow across the desk.
2. **Toy mahogany** (tell 3, `380 340 560 300`): the desk's red is oversaturated and its grain is a stretched, wavy noise with no varnish wear, so it looks like a plastic toy desk. Cause: material. Cheapest fix: desaturate and darken the wood toward brown, give it a worn sheen on the edges and writing surface.
3. **Two-tone walls** (tell 1, `0 0 1280 720`): the left wall is orange, the right wall blue-grey, with a hard line at the corner; it looks like a colour grade, not light. Cause: light. Cheapest fix: let the warm light fall off across both walls instead of tinting each wall.
4. **A bare desk** (tell 7, `530 350 280 120`): no papers, books, pen, bottle, spectacles; nothing lived. Cause: dressing. Cheapest fix: a few loose papers, a ledger and a pen on the blotter.
5. **Ruler-straight boards** (tell 4, `0 0 1280 260`): identical vertical boards with crisp grooves and no stain, nail heads or warping. Cause: geometry. Cheapest fix: vary the boards' tone and add grime near the floor and a few nail rows.

## b
- 1 Flat light: FAIL (`0 0 640 720`; `cut b_b_flat_wall.png`): the wall is lit evenly grey-blue with no shadow shapes; the window throws no light pool into the room.
- 2 No atmosphere: FAIL (`600 280 460 100`; `cut b_b_noair.png`): no dust or haze in the window's light; the far shelves are as crisp as the near counter.
- 3 Too clean: FAIL (`200 460 840 260`; `cut b_b_clean_floor.png`): the floor is a uniform, saturated red-orange gloss, no scuffs, dirt at the walls or worn path.
- 4 Too straight: FAIL (`0 0 1280 720`; `cut b_b_straight.png`): every board, shelf and counter perfectly level and plumb.
- 5 Floating objects: FAIL (`610 300 450 60`; `cut b_b_shelf_through.png`): a grey plank pokes out of the shelving to the left into the air in front of the wall, attached to nothing.
- 6 Repetition: FAIL (`680 20 380 480`; `cut b_b_bottles_repeat.png`): rows of the same few bottles at the same spacing, shelf after shelf.
- 7 Empty: PASS (the shelving and counter are dressed).
- 8 Scale tells: PASS.
- 9 Edges of the world: FAIL (`280 60 200 200`; `cut b_b_window_blank.png`): the window is a flat, featureless grey card; nothing behind it.
- 10 Stiff people: N/A (a still).
- **Verdict: cheap indie**
1. **A blank window** (tell 9, `280 60 200 200`): the window is a flat grey panel, no sky, no street, no light coming through; it reads as unfinished. Cause: light. Cheapest fix: let the window show the outside and push a soft daylight pool across the counter and floor.
2. **Even grey fill** (tell 1, `0 0 640 720`): the walls are one tone everywhere, no source, no shadow in the corners. Cause: light. Cheapest fix: darken the room's ambient and let the window be the key light.
3. **A shelf board through the shelving** (tell 5, `610 300 450 60`): a plank sticks out of the cabinet's side into empty air; players spot this kind of error at once. Cause: geometry. Cheapest fix: trim the shelf to the cabinet's width.
4. **Stamped bottles** (tell 6, `680 20 380 480`): the same bottles in the same rhythm on every shelf. Cause: dressing. Cheapest fix: vary heights, gaps and a few gaps or tipped/missing bottles, a box or a book per shelf.
5. **Candy-red floor** (tell 3, `200 460 840 260`): the floor's saturated orange-red gloss is the brightest colour in the room and has no wear. Cause: material. Cheapest fix: desaturate and grey the floor, add a trodden path and dirt in the corners.

## c
- 1 Flat light: FAIL (`0 0 480 720`; `cut c_c_flat_walls.png`): the inside walls are one even blue-grey; only the sun patch on the floor says where the light is.
- 2 No atmosphere: PASS (the distance outside is paler and softer than the room).
- 3 Too clean: FAIL (`100 590 700 130`; `cut c_c_clean_floor.png`): a glossy, unworn orange floor; spotless walls and sill.
- 4 Too straight: FAIL (`840 0 440 720`; `cut c_c_straight_walls.png`): ruler boards and a perfectly square window.
- 5 Floating objects: FAIL (`540 140 70 380`; `cut c_c_floating_post.png`): the porch post hangs from the roof and stops in mid-air above the ground.
- 6 Repetition: PASS.
- 7 Empty: FAIL (`500 280 320 280`; `cut c_c_empty_desert.png`): the view out is an empty flat of sand; the room has nothing in it.
- 8 Scale tells: PASS.
- 9 Edges of the world: FAIL (`500 90 320 230`; `cut c_c_horizon_sky.png`): a flat grey ridge silhouette on a ruler horizon, under a posterised, painted-looking cloud sky.
- 10 Stiff people: N/A (a still).
- **Verdict: cheap indie**
1. **A post hanging in the air** (tell 5, `540 140 70 380`): the porch post ends a metre above the ground; the porch roof looks unsupported. Cause: geometry. Cheapest fix: run the post down to the porch deck or ground.
2. **An empty desert out the window** (tell 7 and 9, `500 280 320 280`): flat, smooth sand to a straight horizon with a cut-out grey ridge; the town the building is in is nowhere. Cause: dressing. Cheapest fix: put something in the view (a neighbour's wall, a fence, brush, a wagon track) and break the horizon.
3. **A posterised sky** (tell 9, `500 90 320 230`): the clouds are flat blobs in a few tones, a painted card behind a realistic-ish room. Cause: material. Cheapest fix: a smoother, photographic sky texture graded to match the room.
4. **Grey walls with no light on them** (tell 1, `0 0 480 720`): the sun is clearly up (the floor patch) but the walls get no bounce or warmth. Cause: light. Cheapest fix: more warm bounce from the sunlit floor up the walls near the window.
5. **Clean, glossy floor and walls** (tell 3, `100 590 700 130`): no sand tracked in under a window onto a desert, no wear. Cause: material. Cheapest fix: dust and grit on the sill and the floor under it.

## d
- 1 Flat light: PASS (a hard key from the lamp outside, long cast shadows of the window frame and table across the floor, deep blacks kept black).
- 2 No atmosphere: FAIL (`760 0 520 320`; `cut d_d_noair_lamp.png`): the lamp blooms in the glass but the room's air has no haze; the shadow bars on the floor are clean.
- 3 Too clean: FAIL (`480 260 520 400`; `cut d_d_clean_floor.png`): the floor is a glossy, oversaturated orange with no wear or dirt; the leather of the table is new.
- 4 Too straight: FAIL (`240 0 360 360`; `cut d_d_straight_boards.png`): perfectly plumb, even wall boards and a square doorway.
- 5 Floating objects: PASS (the table's legs cast shadows onto the floor).
- 6 Repetition: PASS.
- 7 Empty: FAIL (`0 0 480 720`; `cut d_d_empty_room.png`): an examining table, a side table and bare walls; no instruments, cloth, basin in use or anything left lying.
- 8 Scale tells: PASS.
- 9 Edges of the world: PASS (the doorway gives onto dark).
- 10 Stiff people: N/A (a still).
- **Verdict: good indie**
1. **Oversaturated floor** (tell 3, `480 260 520 400`): the lamp turns the floor a hot, glossy orange-red that looks like varnished plastic, the loudest thing in the frame. Cause: material. Cheapest fix: lower the floor's saturation and gloss and add wear along the paths.
2. **No air in the lamplight** (tell 2, `760 0 520 320`): the light is strong and directional, but there is no dust or haze for it to show in; the beams from the window would sell the mood. Cause: light. Cheapest fix: a thin volumetric haze in the room so the window's light shows as shafts.
3. **A bare examining room** (tell 7, `0 0 480 720`): nothing says a doctor works here: no bag, instruments, towels, bottles, a sheet on the table. Cause: dressing. Cheapest fix: a folded sheet on the table and a tray of instruments on the side table.
4. **Ruler boards** (tell 4, `240 0 360 360`): crisp, identical vertical boards, no stains near the floor, no nails. Cause: geometry. Cheapest fix: vary the boards' tone and grime the bottom.
5. **Pale patches on the right wall** (tell 3, `1180 260 100 320`): bright flat white rectangles on the right wall read as a light leak or a missing texture. Cause: material. Cheapest fix: make them clear papers/notices with content, or remove them.

## Ranking
From least to most cheap-looking: d, a, b, c
