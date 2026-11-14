# Cheap judge, 2026-11-13_saloon_b_r2

## a
- 1 Flat light: PASS (the sun throws one long, clear shadow of the building and balcony on the ground, `30 520 1020 80`; the shaded front itself is one even dark tone)
- 2 No atmosphere: PASS (the far boxes do fade into a pale haze; the sky's hard-edged colour patches are counted under 9)
- 3 Too clean: FAIL (`0 520 1280 200`; `a_a_clean_ground.png`)
- 4 Too straight: FAIL (`270 160 740 380`; `a_a_straight.png`)
- 5 Floating objects: PASS (the porch posts, steps and the far table all sit in shadow)
- 6 Repetition: PASS
- 7 Empty: FAIL (`455 185 450 35`; `a_a_blank_sign.png`)
- 8 Scale tells: PASS (the man at the door fits the door and the porch)
- 9 Edges of the world: FAIL (`0 280 1280 220`; `a_a_grey_boxes.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The town is untextured grey boxes** (tell 9, `0 280 1280 220`): left and right of the saloon stand plain grey slabs with no windows, boards or roofs, and beyond them a flat bare line. A player reads "unfinished level". Cause: geometry. Cheapest fix: frame the shot so neighbours are out of it, or give the slabs a board texture and a roofline.
2. **The ground is one smooth beige sheet** (tell 3, `0 520 1280 200`): no ruts, stones, hoof prints, dung, darker dirt at the porch or scuffing by the steps; half the frame is a blank gradient. Cause: material. Cheapest fix: a ground texture with wheel ruts and a darker, trodden band along the porch.
3. **The sky is posterised** (tell 9, `0 0 1280 280`): the clouds are flat patches of three or four colours with hard edges, like a paint-by-numbers backdrop behind a realistic building. Cause: material. Cheapest fix: a smooth-gradient sky texture (no colour reduction on the sky).
4. **The front is a blank dark face with a blank sign** (tell 7, `455 185 450 35`): the sign board has no lettering, the porch has no chairs, barrels, horses or hitch rail, one man stands alone. Cause: dressing. Cheapest fix: paint the saloon's name on the board and put a bench and two barrels on the porch.
5. **Everything is ruler-straight** (tell 4, `270 160 740 380`): balusters, posts, windows and the roofline are perfectly even and level; nothing sags or leans. Cause: geometry. Cheapest fix: a few degrees of lean on two porch posts and a slight sag in the balcony rail.

## b
- 1 Flat light: FAIL (`0 430 1280 290`; `b_b_black_ground.png`)
- 2 No atmosphere: FAIL (`0 0 640 300`; `b_b_sky_stars.png`)
- 3 Too clean: N/A (too dark to see any surface)
- 4 Too straight: PASS (the dark hides it; the silhouette reads as a real building)
- 5 Floating objects: PASS
- 6 Repetition: PASS
- 7 Empty: PASS (a lit saloon on a dark street at night can be quiet; one figure stands far left)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`1040 360 240 150`; `b_b_grey_neighbours.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The lit windows light nothing** (tell 1, `0 430 1280 290`): six windows glow orange but the porch boards, posts and street in front of them stay black, except one small patch at the right corner (`900 510 110 40`). The bottom 40% of the picture is a featureless black void. Cause: light. Cheapest fix: a warm pool of light spilling from each window and the door across the porch and onto the dirt.
2. **Square stars on a cut-out sky** (tell 2, `0 0 640 300`): the stars are little white squares and diamonds, all the same size and brightness, and the clouds are flat hard-edged purple and grey patches. It reads as a stylised cartoon sky over a realistic building. Cause: material. Cheapest fix: point stars of varied brightness and a soft-gradient night sky.
3. **No air around the lamplight** (tell 2, `600 380 110 110`): the one visible lamp inside is a hard dot; no glow, no dust or smoke at the windows, no haze over the street. Cause: light. Cheapest fix: a soft glow around the lamps and a thin lit haze at the windows.
4. **Grey neighbours and a flat black horizon** (tell 9, `1040 360 240 150`): the buildings to the right are plain boxes and the left horizon is a straight line with nothing on it. Cause: geometry. Cheapest fix: a lit window or two in the neighbours, and a ridge line on the horizon.
5. **The saloon is a near-silhouette** (tell 1, `280 40 770 550`): the wood shows only as dark red-brown; no moonlit edge separates roof, balcony and posts from each other. Cause: light. Cheapest fix: a faint cool moon rim on the roof and balcony rail.

## c
- 1 Flat light: FAIL (`360 190 590 340`; `c_c_flat_wall.png`)
- 2 No atmosphere: PASS (the far slabs fade to pale haze)
- 3 Too clean: FAIL (`0 470 1280 250`; `c_c_clean_ground.png`)
- 4 Too straight: FAIL (`360 190 590 340`; `c_c_flat_wall.png`)
- 5 Floating objects: FAIL (`330 420 640 110`; `c_c_no_contact.png`)
- 6 Repetition: PASS (the windows repeat, as windows do)
- 7 Empty: FAIL (`170 440 100 45`; `c_c_lone_table.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 320 370 140`; `c_c_grey_slabs.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A red box on a blank plane** (tell 5, `330 420 640 110`): the building meets the sand in a clean straight line with no dirt, no weeds, no foundation and almost no shadow on the ground; it looks dropped onto a default terrain. Cause: light. Cheapest fix: a darkened, dirty band at the wall's foot and a visible cast shadow on the ground.
2. **Two flat, evenly lit walls** (tell 1, `360 190 590 340`): both visible walls are the same flat maroon from end to end, the corner between them barely changes tone, and nothing says where the sun is. Cause: light. Cheapest fix: put the sun to one side so one wall is clearly in shade.
3. **The ground is smooth beige over more than half the frame** (tell 3, `0 470 1280 250`): no texture, tracks, stones, scrub or rubbish; a gradient. Cause: material. Cheapest fix: a real dirt texture with scattered stones and scrub.
4. **Grey slabs and an empty horizon** (tell 9, `0 320 370 140`): the neighbouring buildings are untextured grey blocks and the horizon is a bare line, under a posterised patchy sky (`0 0 1280 330`, `c_c_sky.png`). Cause: geometry. Cheapest fix: texture the slabs or keep them out of frame.
5. **Nothing lives behind the saloon** (tell 7, `170 440 100 45`): a lone table and chairs stand in open sand; no woodpile, privy, barrels, crates, washing line or fence. Cause: dressing. Cheapest fix: a woodpile, a privy and a few crates against the back wall.

## d
- 1 Flat light: PASS (sun through the windows lays clear patches and post shadows on the floor, `560 440 520 180`; the space under the gallery is properly darker)
- 2 No atmosphere: PASS (the far bar end softens into a haze)
- 3 Too clean: FAIL (`80 220 230 180`; `d_d_speckled_wall.png`)
- 4 Too straight: PASS (curved brackets and arches break the lines)
- 5 Floating objects: PASS (chairs and tables cast shadows)
- 6 Repetition: FAIL (`590 150 450 420`; `d_d_same_grain.png`)
- 7 Empty: FAIL (`680 290 400 150`; `d_d_bare_bar.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (the open door at the left shows only a white blur, `0 330 55 90`, a small thing)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **A saloon with nobody and nothing in it** (tell 7, `680 290 400 150`): the back bar's arched shelves are bare, no bottles, glasses, mirror or till; the tables have no cards, glasses or hats; no people. It reads as a level before set dressing. Cause: dressing. Cheapest fix: fill the back-bar shelves with bottles and put glasses and cards on two tables.
2. **All the wood is the same new, shiny wood** (tell 6, `590 150 450 420`): posts, beams, joists and floor share one bold orange grain with a varnished, plastic sheen; no scuffed walkways, stains or worn post bases. Cause: material. Cheapest fix: a duller, darker floor with a worn track from door to bar, and a different wood for the posts.
3. **The walls are speckled with pale square flecks** (tell 3, `80 220 230 180`): the cream boarding is covered in an even scatter of small light squares, like noise or leftover pixels, not dirt or wear. Cause: material. Cheapest fix: remove the fleck layer and add smoke staining near the lamps and grime at the wainscot.
4. **The lamp glows are banded** (tell 2, `680 290 400 150`): the light on the wall behind the bar steps in visible rings, a posterised look. Cause: material. Cheapest fix: dither or stop reducing colour in the dim range.
5. **Six identical chairs to a table, all squared up** (tell 6, `30 410 400 230`): every chair is the same model, pushed in at the same distance. Cause: dressing. Cheapest fix: pull two chairs out at angles and tip one over.

## e
- 1 Flat light: PASS (pools of lamplight on the bar top and walls, real darkness between)
- 2 No atmosphere: FAIL (`330 300 70 80`; `e_e_hard_glow.png`)
- 3 Too clean: FAIL (`1140 60 140 420`; `e_e_speckle_wall.png`)
- 4 Too straight: PASS
- 5 Floating objects: FAIL (`440 10 220 110`; `e_e_light_leak.png`)
- 6 Repetition: PASS
- 7 Empty: FAIL (`60 390 590 330`; `e_e_clean_bar.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **An empty bar at night** (tell 7, `60 390 590 330`): the bar top carries two lamps and nothing else; no bottles, glasses, rag, spills or ring marks beyond faint circles, no barman, no drinkers. Cause: dressing. Cheapest fix: bottles and glasses along the bar and one person behind it.
2. **Light leaking through the ceiling** (tell 5, `440 10 220 110`): a row of five bright blobs sits on the ceiling boards with no lamp under them; it reads as light coming through a gap between parts, a rendering fault. Cause: light. Cheapest fix: stop the light above shining through the floor (close the gap or shadow that light).
3. **Everything is one red-orange** (tell 2, `0 0 1280 720`): wood, walls and air are all the same saturated red-brown and the middle of the room falls to pure black; the only other colour is the purple dusk in the windows. Cause: light. Cheapest fix: a little cool fill from the windows so the shadows have colour and the floor's centre reads.
4. **No air in the lamplight** (tell 2, `330 300 70 80`): each wall lamp is a hard bright disc on the boards with no glow around the flame and no smoke haze in a room that should be full of it. Cause: light. Cheapest fix: a soft glow on each flame and a thin haze layer at head height.
5. **Speckled wall and door** (tell 3, `1140 60 140 420`): the right wall and the dark door panel are scattered with pale square flecks like noise; under raking light it looks like a texture error rather than wear. Cause: material. Cheapest fix: remove the fleck layer.

## f
- 1 Flat light: PASS (three wall lamps make clear warm pools and the roof falls into dark)
- 2 No atmosphere: FAIL (`300 300 100 130`; `f_f_doorway.png`)
- 3 Too clean: FAIL (`60 230 600 200`; `f_f_speckle_wall.png`)
- 4 Too straight: PASS (the roof trusses and braces give it some irregularity)
- 5 Floating objects: PASS
- 6 Repetition: PASS
- 7 Empty: FAIL (`180 400 880 320`; `f_f_empty_floor.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`1050 200 230 520`; `f_f_black_slab.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A big bare room** (tell 7, `180 400 880 320`): an upstairs floor the size of a dance hall with not one bed, table, chair, trunk, rug or partition; it reads as an unfurnished shell. Cause: dressing. Cheapest fix: partition it into rooms with doors, or put beds and trunks along the walls.
2. **A pure black slab fills the right of the frame** (tell 9, `1050 200 230 520`): a featureless black rectangle, edge to edge, with no surface, grain or light on it; a player would take it for a missing texture or an unlit object. Cause: light. Cheapest fix: let the nearest lamp reach it, or move the camera off it.
3. **The floor's centre is black** (tell 2, `380 420 660 300`): the lamplight dies a metre from each wall and the middle of the room is a red-black hole; nothing bounces. Cause: light. Cheapest fix: a low warm ambient so the boards read across the room.
4. **Speckled walls** (tell 3, `60 230 600 200`): the cream boards carry an even scatter of pale square flecks, most obvious in the lamp pools. Cause: material. Cheapest fix: remove the fleck layer and add smoke stain above each lamp.
5. **The doorway shows flat purple bands** (tell 2, `300 300 100 130`): outside is two flat stripes of colour and a railing, no depth, no stars, no town. Cause: material. Cheapest fix: a smooth sky gradient and a lit window opposite.

## g
- 1 Flat light: PASS (the chandelier and wall lamps light the walls warmly and the well below is dark)
- 2 No atmosphere: PASS (no haze, but the dim far wall and the dark well give depth)
- 3 Too clean: FAIL (`800 380 380 280`; `g_g_big_grain.png`)
- 4 Too straight: PASS
- 5 Floating objects: FAIL (`440 440 160 160`; `g_g_light_leak.png`)
- 6 Repetition: PASS (the balusters repeat, as balusters do)
- 7 Empty: FAIL (`0 60 240 220`; `g_g_blank_slab.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Varnished toy wood** (tell 3, `800 380 380 280`): floor, rails and posts share one glossy orange wood whose grain is drawn large and bold, like a printed laminate; no dust, scuffs or worn rail tops. It looks plastic. Cause: material. Cheapest fix: halve the grain's contrast and gloss and darken the floor's walked-on middle.
2. **Light bleeding through the balusters' feet** (tell 5, `440 440 160 160`): a bright hot spot glows between the balusters at the floor with no lamp there; a light leak. Cause: light. Cheapest fix: shadow that light or close the gap under the rail.
3. **A blank dark slab at the left** (tell 7, `0 60 240 220`): a large flat brown rectangle with nothing on it stands beside the gallery, unexplained. Cause: geometry. Cheapest fix: make it read as what it is (a door with panels, a wall with boards) or move the camera.
4. **The chandelier's flames light nothing nearby** (tell 1, `620 170 180 90`): six flames burn on the ring but the ring's own top and the rail a metre away show no extra light from them, and the hanging ropes are hairline white strokes. Cause: light. Cheapest fix: a small warm light at the chandelier that reaches the rail and wall.
5. **Nobody and nothing upstairs** (tell 7, `0 280 480 440`): bare boards all round the gallery; no chairs, spittoon, pictures, coats or people leaning on the rail. Cause: dressing. Cheapest fix: a chair and a small table by the rail and a picture on the cream wall.

## Ranking
From least to most cheap-looking: d, e, g, b, f, a, c
