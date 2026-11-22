# Cheap judge, 2026-11-22_homestead_r1_cheap

## a
- 1 Flat light: PASS (low sun, long bush shadows across the track, `0 440 1280 280`)
- 2 No atmosphere: PASS (the far mesa and hills fade blue, `0 325 270 35`)
- 3 Too clean: PASS (wheel ruts, hoof prints and patchy ground, `0 440 640 280`)
- 4 Too straight: PASS (buildings lean a little, ruts wander)
- 5 Floating objects: FAIL (`0 390 590 70`; `cut a_a_floating_plank.png`)
- 6 Repetition: FAIL (`930 380 350 80`; `cut a_a_repeated_bushes.png`)
- 7 Empty: FAIL (`0 440 640 280`; `cut a_a_empty_yard.png`)
- 8 Scale tells: PASS (cabin, barn, fence and porch agree)
- 9 Edges of the world: FAIL (`860 320 420 45`; `cut a_a_purple_horizon.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Flat purple ground plane and smooth bare dunes as the horizon** (tell 9, `860 320 420 45`): to the right the world ends in a flat, untextured mauve band, and behind the barn two smooth tan mounds with a white box sitting on the skyline; they read as placeholder geometry. Cause: geometry. Cheapest fix: give the far terrain the same ground texture and scrub as the foreground, fogged by distance, and remove the box.
2. **Pale plank lying across the yard like a stray beam** (tell 5, `0 390 590 70`): a long, evenly lit board runs from the left edge to the barn with no shadow under it and no reason to be there. Cause: dressing. Cheapest fix: sink it into the dirt with a contact shadow, or remove it.
3. **The same scrub clump stamped over the plain** (tell 6, `930 380 350 80`): the mid-distance bushes are one green blob repeated at the same size and spacing. Cause: dressing. Cheapest fix: two or three more bush shapes with random scale and colour.
4. **Bright tan rectangle on the cabin roof** (tell 3, `700 270 200 145`): a newly patched square of shingles reads as a texture swatch, not a repair. Cause: material. Cheapest fix: weather the patch most of the way to the rest of the roof.
5. **A homestead with no sign of anyone** (tell 7, `0 440 640 280`): no wagon, tools, washing, animals or firewood; the yard is grass tufts. Cause: dressing. Cheapest fix: a woodpile, a bucket and a wagon by the barn.

## b
- 1 Flat light: PASS (the barn throws a clear shadow across the yard, `0 440 560 100`)
- 2 No atmosphere: PASS (slight haze on the far plain)
- 3 Too clean: FAIL (`0 520 1280 200`; `cut b_b_bare_yard.png`)
- 4 Too straight: FAIL (`430 300 440 170`; `cut b_b_straight_logs.png`)
- 5 Floating objects: PASS (porch on stone piers with shadow, stump with shadow)
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 520 1280 200`; `cut b_b_bare_yard.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`840 330 440 40`; `cut b_b_flat_horizon.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A bare, even sheet of dirt in front of the house** (tell 3, `0 520 1280 200`): the whole lower third is one uniform brown with no path to the door, no footprints, no grass at the walls. Cause: material. Cheapest fix: a worn path from the steps and darker trodden dirt at the porch edge.
2. **Roof patch like pasted planks** (tell 3, `540 200 120 70`): bright orange boards in a neat rectangle with a dark gap, the squares of the texture still visible; it reads as a texture test. Cause: material. Cheapest fix: weather and darken the patch, break its outline.
3. **Flat mauve horizon** (tell 9, `840 330 440 40`): the plain ends against a smooth purple band with no detail. Cause: geometry. Cheapest fix: textured, hazed distant hills.
4. **Perfectly boxy cabin, front-on** (tell 4, `430 300 440 170`): square, level, evenly spaced logs and posts, dead centre in the frame; nothing sags. Cause: geometry. Cheapest fix: a slight ridge sag and uneven log ends.
5. **Nothing lived in on the porch** (tell 7, `430 380 440 110`): one washstand with a white jug; no chair, boots, tools or lamp. Cause: dressing. Cheapest fix: a chair, a hung lantern and boots by the door.

## c
- 1 Flat light: PASS (backlit by a low sun, strong cast shadow, `280 480 1000 240`)
- 2 No atmosphere: PASS (sun bloom and hazy distance)
- 3 Too clean: FAIL (`630 0 130 590`; `cut c_c_blue_chimney.png`)
- 4 Too straight: FAIL (`270 250 370 240`; `cut c_c_chinking_lines.png`)
- 5 Floating objects: FAIL (`280 480 480 130`; `cut c_c_base_contact.png`)
- 6 Repetition: FAIL (`630 0 130 590`; `cut c_c_blue_chimney.png`)
- 7 Empty: PASS (a close view of a wall)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`820 300 460 80`; `cut c_c_streaky_mountains.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A bright blue checkered chimney** (tell 6, `630 0 130 590`): the stone tile repeats course after course in saturated blue and grey blocks with visible leftover squares; it looks like a placeholder texture, not stone in shade. Cause: material. Cheapest fix: a warm, varied fieldstone texture with no blue cast and no visible tile.
2. **Streaky, smeared white mountains** (tell 9, `820 300 460 80`): the far range is a pale streaked shape with drawn lines across it, like a stretched texture. Cause: geometry. Cheapest fix: replace with hazed, shaded far peaks or a fogged silhouette.
3. **Ruler-straight white chinking** (tell 4, `270 250 370 240`): every gap between logs is a perfect bright line of the same width. Cause: material. Cheapest fix: vary and darken the chinking, break it in places.
4. **Cabin sitting on the ground like a box** (tell 5, `280 480 480 130`): the base is the same blue stone tile and meets the dirt in a clean line, no dirt splash or grass. Cause: dressing. Cheapest fix: dirt and grass at the foot of the walls, a darker band at the base.
5. **Stone base turned blue too** (tell 3, `280 480 480 130`): the sill stones share the chimney's blue tint, so the cool cast reads as a material error, not sky light. Cause: light. Cheapest fix: lower the sky fill's saturation on stone.

## d
- 1 Flat light: PASS (barn and fence cast clean, long shadows, `560 450 720 270`)
- 2 No atmosphere: PASS (mild haze toward the horizon)
- 3 Too clean: FAIL (`240 470 600 240`; `cut d_d_clean_corral.png`)
- 4 Too straight: FAIL (`160 365 460 145`; `cut d_d_straight_fence.png`)
- 5 Floating objects: FAIL (`650 300 145 225`; `cut d_d_door_slab.png`)
- 6 Repetition: PASS
- 7 Empty: FAIL (`240 470 600 240`; `cut d_d_clean_corral.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 325 620 40`; `cut d_d_flat_sea.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The barn door is a flat slab stuck in the ground** (tell 5, `650 300 145 225`): one thick board standing open, no hinges, no framing, its foot meeting the dirt with no gap or shadow. Cause: geometry. Cheapest fix: a planked, braced door hung on visible hinges clear of the ground.
2. **A flat blue band on the horizon like a sea** (tell 9, `0 325 620 40`): the far distance is an even blue stripe, and on the right a bare smooth dune (`1060 300 220 60`). Cause: geometry. Cheapest fix: textured, hazed hills instead of flat bands.
3. **An empty, spotless corral** (tell 7, `240 470 600 240`): no hoof churn, dung, trough or animal; the dirt inside is the same as outside. Cause: dressing. Cheapest fix: a trough and churned, darker ground inside the rails.
4. **Pale, identical fence rails** (tell 4, `160 365 460 145`): straight, clean, light rails at even heights, newer-looking than the grey barn. Cause: material. Cheapest fix: grey and weather the rails, sag one or two.
5. **Ground that stops at the wall** (tell 3, `900 460 380 80`): the barn's base meets uniform dirt with no weeds, scraps or splashing. Cause: dressing. Cheapest fix: weeds and darker dirt along the foot of the walls.

## e
- 1 Flat light: PASS (sun from the left, shadows under each bush)
- 2 No atmosphere: PASS (the far buildings soften a little)
- 3 Too clean: FAIL (`490 490 240 95`; `cut e_e_box_trough.png`)
- 4 Too straight: FAIL (`370 325 910 30`; `cut e_e_flat_bands.png`)
- 5 Floating objects: FAIL (`580 365 110 140`; `cut e_e_pale_log.png`)
- 6 Repetition: FAIL (`0 360 1280 160`; `cut e_e_bush_repeat.png`)
- 7 Empty: PASS (it is open range; the scrub fills it)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`230 290 160 60`; `cut e_e_grey_cone.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The centre prop is a ring of dark grey boxes around a mirror of water** (tell 3, `490 490 240 95`): plain, untextured blocks and a flat blue reflective sheet; it doesn't read as a well, trough or spring. Cause: geometry. Cheapest fix: stone and timber with real texture, and muddy edges to the water.
2. **A grey cone and a white box on the skyline** (tell 9, `230 290 160 60`): an untextured volcano-shaped primitive and a stray cube sit on a smooth dune. Cause: geometry. Cheapest fix: remove them or replace with textured rock.
3. **The same bush stamped across the plain** (tell 6, `0 360 1280 160`): one dark-green shrub and one dry tuft repeated at even spacing to the horizon. Cause: dressing. Cheapest fix: more variants, varied scale and clustering.
4. **Pale log floating over the scrub** (tell 5, `580 365 110 140`): a long light pole runs from the prop to the distance with no shadow on the ground. Cause: dressing. Cheapest fix: lay it on the dirt with a contact shadow, or cut it.
5. **The horizon is stacked flat bands** (tell 4, `370 325 910 30`): straight purple and blue strips run across the frame, ruler-level. Cause: geometry. Cheapest fix: break the line with textured rises and haze.

## f
- 1 Flat light: FAIL (`0 130 1280 420`; `cut f_f_blue_stripes.png`)
- 2 No atmosphere: FAIL (`200 230 300 300`; no light from the window into the room; `cut f_f_trunk_bed.png`)
- 3 Too clean: FAIL (`430 290 360 220`; `cut f_f_trunk_bed.png`)
- 4 Too straight: FAIL (`720 130 560 420`; `cut f_f_wall_tile.png`)
- 5 Floating objects: FAIL (`430 290 360 220`; `cut f_f_trunk_bed.png`)
- 6 Repetition: FAIL (`720 130 560 420`; `cut f_f_wall_tile.png`)
- 7 Empty: FAIL (`700 450 580 270`; `cut f_f_empty_floor.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`860 235 380 20`; `cut f_f_light_leaks.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Blue-purple shine along every log seam** (tell 1, `0 130 1280 420`): the chinking lines glint cold blue across all walls, the same in every direction, so you can't tell where the light comes from. Cause: light. Cheapest fix: kill the blue specular on the chinking and let the window and stove be the only sources.
2. **A toy trunk and a bed with a torn-through blanket** (tell 3, `430 290 360 220`): the trunk is flat beige with clean pale straps, like a game pickup; the blanket's edge has jagged holes where the frame pokes through; neither has a contact shadow on the floor. Cause: material. Cheapest fix: a darker, worn trunk and a blanket that drapes clear of the frame, with ambient occlusion under both.
3. **One wood texture on walls, ceiling and floor** (tell 6, `720 130 560 420`): every surface is the same grey plank, so the room reads as a textured box. Cause: material. Cheapest fix: a different wood and tone for floor and ceiling.
4. **Bare floor, nothing lived in** (tell 7, `700 450 580 270`): a bed, a trunk and the corner of a stove; no table, chair, lamp, clothes or rug. Cause: dressing. Cheapest fix: a table and chair, a lamp and a coat on a peg.
5. **Pinpricks of light through the seams and a brand-new board** (tell 9, `860 235 380 20`): bright specks leak through the right wall's gaps, and a yellow new plank runs along the left wall (`0 395 445 95`) unlike all the rest. Cause: geometry. Cheapest fix: close the wall gaps and weather the plank to match.

## Ranking
From least to most cheap-looking: a, d, b, c, f, e
