# Cheap judge, 2026-11-15_valley_land2_r1_cheap

## a
- 1 Flat light: FAIL (`0 380 1280 340`, `a_flat_road.png`): high sun, the street is one even brown, buildings cast almost nothing across it.
- 2 No atmosphere: PASS (a little haze at the far end of the street)
- 3 Too clean: FAIL (`30 330 290 165`, `a_stone_wall.png`): the stone wall is a pixelated camouflage pattern with blue and purple blotches, no dirt at its foot.
- 4 Too straight: FAIL (`30 330 290 165`, `a_stone_wall.png`): every wall and roofline ruler-straight, block courses perfectly level.
- 5 Floating objects: FAIL (`700 360 580 40`, `a_base_contact.png`): the saloon and its porch meet the dirt with no darkening or dust banked against them.
- 6 Repetition: FAIL (`30 330 290 165`, `a_stone_wall.png`): the same stone tile is stamped block after block.
- 7 Empty: FAIL (`320 340 760 80`, `a_empty_street.png`): a huge street with one tiny figure; no wagons, horses, barrels, hitching rails.
- 8 Scale tells: PASS (the street is very wide but plausible for a cattle town)
- 9 Edges of the world: FAIL (`520 310 90 65`, `a_white_blocks.png`): plain white untextured boxes stand in for buildings down the street.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Camouflage stone wall** (tell 3, `30 330 290 165`): the left building looks wrapped in a digital-camo bitmap with blue and purple blotches, not stone. Cause: material. Cheapest fix: replace the stone texture with a desaturated, sun-bleached sandstone without the coloured blotches.
2. **Untextured white blocks** (tell 9, `520 310 90 65`): grey-white boxes at the end of the street read as unfinished placeholders. Cause: geometry. Cheapest fix: give the far buildings any textured facade, or hide them until they have one.
3. **Dead-empty street** (tell 7, `320 340 760 80`): a wide street with nobody and nothing in it. Cause: dressing. Cheapest fix: a wagon, two tied horses and a scatter of crates and barrels along the boardwalks.
4. **Flat noon light** (tell 1, `0 380 1280 340`): no shadow shapes on the street, so it reads as a flat plane. Cause: light. Cheapest fix: lower the sun for this view or add porch and building shadows reaching into the street.
5. **No contact at bases** (tell 5, `700 360 580 40`): buildings sit on the dirt like on a table. Cause: material. Cheapest fix: a dark, dusty skirt of ground blend along every wall base.

## b
- 1 Flat light: FAIL (`0 380 1280 340`, `b_flat_road.png`): same even high-sun fill; the ruts have more contrast than in a but the buildings throw nothing.
- 2 No atmosphere: PASS (slight haze down the street)
- 3 Too clean: FAIL (`30 330 290 165`, `b_stone_wall.png`): the camouflage stone wall, no dirt or wear.
- 4 Too straight: FAIL (`30 330 290 165`, `b_stone_wall.png`): ruler-straight walls and courses.
- 5 Floating objects: FAIL (`30 330 290 165`, `b_stone_wall.png`): the wall foot meets the street with a clean line.
- 6 Repetition: FAIL (`30 330 290 165`, `b_stone_wall.png`): the stone tile stamps visibly.
- 7 Empty: FAIL (`0 380 1280 340`, `b_flat_road.png`): an empty street.
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`520 310 90 65`, `b_white_blocks.png`): untextured white boxes down the street.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Camouflage stone wall** (tell 3, `30 330 290 165`): blue/purple pixel blotches instead of stone. Cause: material. Cheapest fix: a plain, weathered sandstone texture.
2. **Placeholder white boxes** (tell 9, `520 310 90 65`): unfinished buildings in plain view. Cause: geometry. Cheapest fix: texture or hide them.
3. **Empty street** (tell 7, `0 380 1280 340`): no life or clutter. Cause: dressing. Cheapest fix: wagons, horses, barrels.
4. **Flat light** (tell 1, `0 380 1280 340`): no shadow shapes. Cause: light. Cheapest fix: a lower sun or cast shadows from porches.
5. **Ruts too regular** (tell 4, `0 380 1280 340`): the wheel ruts run as clean parallel grooves to the vanishing point. Cause: material. Cheapest fix: break the ruts with puddle-dried patches, hoof churn and wander.

## c
- 1 Flat light: PASS (low sun ahead, long shadows, warm porch lamps; the light has a direction)
- 2 No atmosphere: PASS (sun glare and haze down the street)
- 3 Too clean: FAIL (`30 330 290 165`, `c_stone_wall.png`): the camouflage stone wall again, even in shadow its blue blotches show.
- 4 Too straight: FAIL (`30 330 290 165`, `c_stone_wall.png`): perfectly level walls and courses.
- 5 Floating objects: PASS (the backlight and long shadows ground things)
- 6 Repetition: FAIL (`30 330 290 165`, `c_stone_wall.png`): the stone tile repeats.
- 7 Empty: FAIL (`320 340 760 80`, `c_empty_street.png`): two tiny figures in a huge street; only the saloon porch has life.
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`520 310 90 65`, `c_white_blocks.png`): white placeholder boxes catch the sun at the far end.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Camouflage stone wall** (tell 3, `30 330 290 165`): the left building's texture still reads as a bitmap pattern. Cause: material. Cheapest fix: a plain weathered stone.
2. **White placeholder boxes** (tell 9, `520 310 90 65`): untextured shapes break the mood the light builds. Cause: geometry. Cheapest fix: texture or hide them.
3. **Empty street** (tell 7, `320 340 760 80`): good light on nothing. Cause: dressing. Cheapest fix: a wagon and horses silhouetted against the sun.
4. **Too-even ground** (tell 3, `0 400 1280 320`): the street is one gravel material end to end with no manure, boards or puddle marks. Cause: material. Cheapest fix: blend in darker trodden patches by the porches.
5. **Ruler-straight buildings** (tell 4, `30 330 290 165`): nothing sags or leans. Cause: geometry. Cheapest fix: a slight sag in the porch roof and a lean on the false fronts.

## d
- 1 Flat light: PASS (backlit low sun, strong shadow on the right)
- 2 No atmosphere: PASS (sun glare, haze)
- 3 Too clean: FAIL (`30 330 290 165`, `d_stone_wall.png`): camouflage stone wall.
- 4 Too straight: FAIL (`30 330 290 165`, `d_stone_wall.png`): level walls and courses.
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`30 330 290 165`, `d_stone_wall.png`): the stone tile repeats.
- 7 Empty: FAIL (`520 310 90 65`, `d_white_blocks.png`): the street is empty to the far end.
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`520 310 90 65`, `d_white_blocks.png`): white boxes at the end.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Camouflage stone wall** (tell 3, `30 330 290 165`): reads as a pattern, not stone. Cause: material. Cheapest fix: a plain weathered stone.
2. **White placeholder boxes** (tell 9, `520 310 90 65`): unfinished buildings. Cause: geometry. Cheapest fix: texture or hide them.
3. **Empty street** (tell 7, `520 310 90 65`): no traffic or clutter. Cause: dressing. Cheapest fix: wagons, horses, people.
4. **Ruts read as a pattern** (tell 4, `0 400 1280 320`): the deeper ruts here look printed onto the gravel, all parallel. Cause: material. Cheapest fix: vary their width and let them cross.
5. **Ruler-straight buildings** (tell 4, `30 330 290 165`): nothing sags. Cause: geometry. Cheapest fix: sag and lean on the timber fronts.

## e
- 1 Flat light: PASS (bushes cast clear shadows; the sun has a direction)
- 2 No atmosphere: PASS (blue haze on the distant hills)
- 3 Too clean: PASS (gravel, stones, ruts vary)
- 4 Too straight: FAIL (`640 310 460 60`, `e_tree_row.png`): the road runs dead straight to the horizon and the trees stand in an even row like a planted hedge.
- 5 Floating objects: PASS (bushes have contact shadows)
- 6 Repetition: FAIL (`640 310 460 60`, `e_tree_row.png`): the same green tree model repeated along a line.
- 7 Empty: PASS (open range, a road is enough)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (a hazy range and mesas on the horizon)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Tree row** (tell 6, `640 310 460 60`): identical leafy trees spaced evenly along a line; the bright green also clashes with the dry land. Cause: dressing. Cheapest fix: vary size and spacing, clump them, and dull the green.
2. **Ruler road** (tell 4, `300 360 500 360`): the twin ruts run perfectly straight to the vanishing point. Cause: geometry. Cheapest fix: a gentle curve or dip in the road.
3. **Flat thin horizon** (tell 9, `0 310 1100 40`): the far range is a thin flat band with a lake-like blue strip. Cause: geometry. Cheapest fix: a nearer rise or butte to break the line.
4. **Bush spacing** (tell 6, `0 340 600 120`): the dark shrubs are scattered at an even density. Cause: dressing. Cheapest fix: clump them along washes.
5. **Bright cloud texture** (tell 2, `350 0 900 160`): clouds look like flat sprites. Cause: light. Cheapest fix: softer, sun-tinted cloud edges.

## f
- 1 Flat light: PASS (clear shadows, warm light)
- 2 No atmosphere: PASS (haze on the far range)
- 3 Too clean: PASS (dry grass, stones, varied ground)
- 4 Too straight: FAIL (`300 360 500 360`, `e_tree_row.png` for the same road; the box here): the road runs ruler-straight to the horizon.
- 5 Floating objects: PASS
- 6 Repetition: PASS (grass clumps vary enough)
- 7 Empty: PASS
- 8 Scale tells: PASS
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Ruler road** (tell 4, `300 360 500 360`): dead straight to the vanishing point. Cause: geometry. Cheapest fix: a slight curve or rise.
2. **Thin flat horizon** (tell 9, `0 310 1100 40`): a low, flat band. Cause: geometry. Cheapest fix: a nearer landform.
3. **Lone round tree** (tell 6, `1220 285 60 90`): a lollipop-shaped tree that looks out of place. Cause: dressing. Cheapest fix: a scrubbier, wind-bent tree.
4. **Rut edges too crisp** (tell 3, `380 380 300 340`): the rut walls are cleanly cut. Cause: material. Cheapest fix: crumble the edges.
5. **Clouds** (tell 2, `350 0 900 160`): flat sprite clouds. Cause: light. Cheapest fix: softer edges.

## g
- 1 Flat light: PASS (shadows from scrub and an off-screen tree)
- 2 No atmosphere: PASS (some haze at the far ridge)
- 3 Too clean: PASS
- 4 Too straight: FAIL (`0 270 1280 90`, `g_tree_repeat.png`): the trees line the horizon at an even height and spacing; the road is dead straight.
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 270 1280 90`, `g_tree_repeat.png`): one pine model copied dozens of times.
- 7 Empty: PASS
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 320 1280 40`, `g_tree_repeat.png`): the far ridge is a bare flat tan wall with a tree fringe on top.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Copied pines** (tell 6, `0 270 1280 90`): the same tree stamped in a band. Cause: dressing. Cheapest fix: two or three variants with scale and lean jitter.
2. **Even tree line** (tell 4, `0 270 1280 90`): trees form a fence across the view. Cause: dressing. Cheapest fix: clump them, leave gaps.
3. **Bare ridge** (tell 9, `0 320 1280 40`): a flat tan backdrop. Cause: geometry. Cheapest fix: texture and haze on the ridge.
4. **Ruler road** (tell 4, `500 360 300 360`): straight to the vanishing point. Cause: geometry. Cheapest fix: a curve.
5. **Big black tree silhouette** (tell 1, `1180 0 100 280`): the near tree is pure black with no light on it. Cause: light. Cheapest fix: let sunlight catch its edges.

## h
- 1 Flat light: PASS (dappled ground, shadows)
- 2 No atmosphere: PASS
- 3 Too clean: PASS
- 4 Too straight: PASS (the road edges wander a little)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 220 1280 140`, `h_tree_repeat.png`): the same pom-pom pine repeated, some stretched tall.
- 7 Empty: PASS
- 8 Scale tells: FAIL (`0 220 1280 140`, `h_tree_repeat.png`): trees on bare thin trunks with topiary tufts look like toy bonsai.
- 9 Edges of the world: FAIL (`380 315 300 40`, `h_white_specks.png`): a row of pale blue-white specks on the far ridge reads as broken or popped-in objects.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Topiary trees** (tell 8, `0 220 1280 140`): pines like pom-poms on sticks, toy-like. Cause: geometry. Cheapest fix: fuller, irregular crowns.
2. **Pale specks on the ridge** (tell 9, `380 315 300 40`): bluish-white blobs at distance look like a rendering fault. Cause: geometry. Cheapest fix: check the far LOD of these trees; tint them with the haze.
3. **Copied trees** (tell 6, `0 220 1280 140`): one model repeated. Cause: dressing. Cheapest fix: variants.
4. **Bare ridge** (tell 9, `400 320 400 30`): a flat tan backdrop. Cause: geometry. Cheapest fix: texture and haze.
5. **Ruler road** (tell 4, `500 360 300 360`): straight to the horizon. Cause: geometry. Cheapest fix: a curve.

## i
- 1 Flat light: PASS (shrubs cast shadows)
- 2 No atmosphere: PASS (haze on the far range)
- 3 Too clean: FAIL (`380 360 900 360`, `i_uniform_gravel.png`): one gravel texture from foreground to horizon, no sand drift or patches.
- 4 Too straight: PASS
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`380 360 900 360`, `i_uniform_gravel.png`): the same round shrub dotted evenly.
- 7 Empty: PASS
- 8 Scale tells: FAIL (`700 295 560 65`, `i_cone_hill.png`): the hill is a smooth cone, size unreadable.
- 9 Edges of the world: FAIL (`700 295 560 65`, `i_cone_hill.png`): untextured cone and flat mound on the horizon look like primitive shapes.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Primitive cone hill** (tell 9, `700 295 560 65`): a perfect smooth cone and a flat slab on the skyline. Cause: geometry. Cheapest fix: erode the cone into a butte with ledges and texture it.
2. **Uniform gravel** (tell 3, `380 360 900 360`): the same ground everywhere. Cause: material. Cheapest fix: blend in sand and dry grass patches.
3. **Evenly scattered shrubs** (tell 6, `380 360 900 360`): one shrub model dotted uniformly. Cause: dressing. Cheapest fix: clump and vary them.
4. **Cone scale** (tell 8, `700 295 560 65`): can't tell if it's near and small or far and huge. Cause: geometry. Cheapest fix: haze it to its distance.
5. **Flat road plane** (tell 4, `0 360 580 360`): the road is a dark stripe with little relief. Cause: material. Cheapest fix: crumble the rut edges.

## j
- 1 Flat light: PASS (cloud shadows dapple the ground)
- 2 No atmosphere: PASS
- 3 Too clean: PASS (sand, grass, variation)
- 4 Too straight: PASS
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 470 330 170`, `j_zipper_rut.png`): a sawtooth zipper pattern runs along the rut, clearly a repeating stamp.
- 7 Empty: PASS
- 8 Scale tells: FAIL (`700 295 560 65`, `j_cone_hill.png`): smooth cone hill, scale unreadable.
- 9 Edges of the world: FAIL (`700 295 560 65`, `j_cone_hill.png`): primitive cone and flat mound on the horizon.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Primitive cone hill** (tell 9, `700 295 560 65`): a geometric cone on the skyline. Cause: geometry. Cheapest fix: erode and texture it.
2. **Zipper rut** (tell 6, `0 470 330 170`): a chain-like sawtooth line printed along the rut. Cause: material. Cheapest fix: remove that stamp or randomise it.
3. **Cone scale** (tell 8, `700 295 560 65`): unreadable size. Cause: geometry. Cheapest fix: more haze at its distance.
4. **Flat far plain** (tell 9, `0 340 700 30`): a thin blue strip at the horizon reads like a lake that isn't there. Cause: geometry. Cheapest fix: a nearer range.
5. **Shrub spacing** (tell 6, `0 360 1280 120`): even scatter. Cause: dressing. Cheapest fix: clump them.

## k
- 1 Flat light: PASS (shadows exist, blocks have lit and shaded sides)
- 2 No atmosphere: PASS (haze on the far range)
- 3 Too clean: FAIL (`370 315 400 110`, `k_white_boxes.png`): buildings are clean untextured grey-white boxes.
- 4 Too straight: FAIL (`380 350 780 320`, `k_road_patches.png`): the roads are hard-edged rectangles laid on the ground.
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`370 315 400 110`, `k_white_boxes.png`): identical boxes in a grid.
- 7 Empty: FAIL (`380 350 780 320`, `k_road_patches.png`): a town with no people, carts, fences or yards.
- 8 Scale tells: FAIL (`380 350 780 320`, `k_road_patches.png`): the road strips are enormous next to the buildings.
- 9 Edges of the world: FAIL (`0 270 1280 40`, `k_horizon_band.png`): a white band like a seam between the plain and the mountains.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Untextured box town** (tell 3, `370 315 400 110`): the town is grey-white blockout boxes. Cause: geometry. Cheapest fix: use the street's real buildings at distance, or a textured stand-in.
2. **Rectangular road patches** (tell 4, `380 350 780 320`): roads are giant dark rectangles with hard edges and square ends. Cause: material. Cheapest fix: feather their edges and narrow them.
3. **Road scale** (tell 8, `380 350 780 320`): streets far wider than the buildings are long. Cause: geometry. Cheapest fix: narrow them to wagon width.
4. **White seam on the horizon** (tell 9, `0 270 1280 40`): a bright strip under the far range. Cause: geometry. Cheapest fix: blend the backdrop into the terrain with haze.
5. **Empty town** (tell 7, `380 350 780 320`): no yards, fences, corrals or wagons. Cause: dressing. Cheapest fix: corrals and fences round the edges.

## l
- 1 Flat light: PASS
- 2 No atmosphere: PASS
- 3 Too clean: FAIL (`370 315 400 110`, `l_white_boxes.png`): untextured box buildings.
- 4 Too straight: FAIL (`380 350 780 320`, `l_road_patches.png`): hard rectangular road patches.
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`370 315 400 110`, `l_white_boxes.png`): identical boxes.
- 7 Empty: FAIL (`380 350 780 320`, `l_road_patches.png`): no life.
- 8 Scale tells: FAIL (`380 350 780 320`, `l_road_patches.png`): roads far too wide.
- 9 Edges of the world: FAIL (`0 270 1280 40`, `k_horizon_band.png` for the same band): white seam under the far range.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Untextured box town** (tell 3, `370 315 400 110`): blockout boxes. Cause: geometry. Cheapest fix: real or textured buildings.
2. **Rectangular road patches** (tell 4, `380 350 780 320`): hard-edged dark rectangles; the lighter grass here makes them stand out more. Cause: material. Cheapest fix: feather and narrow them.
3. **Road scale** (tell 8, `380 350 780 320`): too wide. Cause: geometry. Cheapest fix: wagon width.
4. **White horizon seam** (tell 9, `0 270 1280 40`): bright strip. Cause: geometry. Cheapest fix: haze blend.
5. **Empty town** (tell 7, `380 350 780 320`): nothing lived-in. Cause: dressing. Cheapest fix: fences and corrals.

## Ranking
From least to most cheap-looking: f, j, e, h, i, g, d, c, b, a, l, k
