# Cheap judge, 2026-11-22_homestead_r2_cheap

## a
- 1 Flat light: PASS (whole frame; low sun, long soft ground shadows, dark undersides)
- 2 No atmosphere: PASS (far mesas and ridge go blue-grey; a little haze, though thin)
- 3 Too clean: FAIL (`0 420 640 300`; `cut a_ground.png`): bare ground with scattered identical grass tufts, no litter, hoof prints, manure, firewood or tools.
- 4 Too straight: PASS (ruts curve, tufts vary)
- 5 Floating objects: PASS (buildings and tufts carry contact shadow)
- 6 Repetition: FAIL (`0 100 500 300`; `cut a_trees.png`): the same pine silhouette and the same grass clump repeat across the frame.
- 7 Empty: FAIL (`430 270 480 150`; `cut a_yard.png`): two small buildings in a flat yard with a dark roof and almost nothing around them to say anyone works here.
- 8 Scale tells: PASS (cabin and barn look small against the pines, but plausible)
- 9 Edges of the world: PASS (horizon is soft; a little flat at the left mesa)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Same pines and tufts in rows** (tell 6, `0 100 1280 300`): the treeline is one tree model with the same shape and tone, the grass is one clump pasted everywhere. Cause: dressing. Cheapest fix: add two or three more tree variants with random scale and lean and break up the tuft spacing.
2. **Empty yard** (tell 7, `430 270 480 150`): cabin and barn sit on bare dirt with nothing lived-in. Cause: dressing. Cheapest fix: scatter a woodpile, a cart, tools, a washtub and laundry by the door.
3. **Clean ground** (tell 3, `0 420 640 300`): the dirt is evenly gritty with no trampled patch, puddle stain or droppings near the buildings. Cause: material. Cheapest fix: blend a darker trampled decal around doors and the trough.
4. **Roof reads as a black hole** (tell 3, `720 285 150 45`): the cabin roof is a flat dark slab with no shingle detail or sun on it. Cause: material. Cheapest fix: lift its albedo and add shingle normal detail.
5. **Thin atmosphere** (tell 2, `0 330 1280 60`): distance is soft but no dust or haze catches the low light. Cause: light. Cheapest fix: raise the haze density near the horizon and add warm scatter toward the sun.

## b
- 1 Flat light: PASS (strong backlight, deep shadow side, long shadows)
- 2 No atmosphere: PASS (far mountains pale and hazy)
- 3 Too clean: FAIL (`270 440 400 170`; `cut b_foundation.png`): the blue-grey foundation looks like a flat noisy texture, the logs are all the same tone, nothing weathered at the corners.
- 4 Too straight: PASS (logs have uneven ends, the chinking is irregular)
- 5 Floating objects: PASS (shadow and dirt line at the base)
- 6 Repetition: FAIL (`560 0 220 600`; `cut b_chimney.png`): the chimney is a checkerboard of two stone tiles stacked in a regular pattern, and the log boards share one grain.
- 7 Empty: FAIL (`0 440 1280 280`): the whole foreground is empty dark dirt, no woodpile, no steps worn, nothing at the door.
- 8 Scale tells: PASS (chimney thick but acceptable; window small and plausible)
- 9 Edges of the world: FAIL (`800 300 480 120`; `cut b_horizon.png`): the snowy mountains read as a flat pale cut-out with a ruler-straight base on a flat plain, and a tiny train on the line.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Checkerboard chimney** (tell 6, `560 0 220 600`): the stonework is two textures alternating in blocks, like a game tile, not laid stone, with no mortar logic. Cause: material. Cheapest fix: use a random-coursed stone with varied block size and mortar depth.
2. **Foundation is a blue noise slab** (tell 3, `270 440 400 170`): the blue-grey base has a pixel-noise texture that doesn't read as stone. Cause: material. Cheapest fix: swap it for the same stone as the chimney, darkened at the soil line.
3. **Pasted mountains** (tell 9, `800 300 480 120`): saturated white-blue peaks with a hard base line against a brown plain. Cause: geometry. Cheapest fix: fade them into haze and put a low ridge in front to hide the base.
4. **Empty crushed foreground** (tell 7, `0 440 1280 280`): a third of the frame is black dirt with no detail. Cause: light. Cheapest fix: lift fill in shadows and add debris and chips near the wall.
5. **Over-regular chinking** (tell 4, `280 250 360 250`): bright white lines run at identical thickness along every log, with thin diagonal straps. Cause: material. Cheapest fix: vary chinking width and darken it with dirt and rain streaks.

## c
- 1 Flat light: PASS (clear sun, dappled leaf shadows on the door, long shadows)
- 2 No atmosphere: PASS (sea and hills fade, though the air is thin)
- 3 Too clean: FAIL (`0 600 640 120`; `cut c_floor.png`): the yard is smooth even dirt, the barn wall is clean unbroken planks, no stains or dust at the base.
- 4 Too straight: PASS (the fence rails lean, the door is ajar)
- 5 Floating objects: PASS (shadows sit under the posts and barn)
- 6 Repetition: FAIL (`0 0 640 380`; `cut c_pines.png`): the pines are the same stacked-pad shape, near-identical, and pad edges show leftover square-ish pixel texture.
- 7 Empty: FAIL (`150 360 480 150`; `cut c_fence.png`): an empty corral with no animals, hay, tack or tools, a barn with its door open on nothing.
- 8 Scale tells: PASS (the door and barn are in proportion)
- 9 Edges of the world: PASS (the ocean-like blue horizon is odd but not a seam)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Stacked-pad pines** (tell 6, `0 0 640 380`): the trees look like layered green discs with a stiff pixel edge, the same tree many times. Cause: geometry. Cheapest fix: break up the pad silhouettes with alpha-cut needles and vary the models.
2. **Empty corral** (tell 7, `150 360 480 150`): fence and trough with no life, no hay or animals. Cause: dressing. Cheapest fix: add hay, a bucket, a saddle on the rail and a horse.
3. **Clean dirt and wall** (tell 3, `0 600 640 120`): the ground is one even brown with no wear paths. Cause: material. Cheapest fix: add a darker worn path from the door and a splash line on the planks.
4. **Water band horizon** (tell 9, `0 330 620 30`): a flat bright blue strip at the left looks like a sea in a desert. Cause: geometry. Cheapest fix: replace with a ridge or haze it out.
5. **Door shadow is a pasted leaf pattern** (tell 4, `660 310 130 210`): the leaf gobo is crisp and uniform on the open door. Cause: light. Cheapest fix: soften the shadow edge and let it fall off with distance.

## d
- 1 Flat light: PASS (raking sun, long shadows over the flat)
- 2 No atmosphere: PASS (distant ridges blue-purple and soft)
- 3 Too clean: FAIL (`440 480 360 130`; `cut d_trough.png`): the trough and stumps are blocky dark slabs with a speckled noise grain and no wear.
- 4 Too straight: PASS (the plank leans, scrub is irregular)
- 5 Floating objects: PASS (stumps and scrub have contact shadow)
- 6 Repetition: FAIL (`0 100 1000 260`; `cut d_treeline.png`): the same pine model in a neat band across the middle, and the same two grass tufts repeated over the plain.
- 7 Empty: FAIL (`0 360 1280 120`; `cut d_flats.png`): a huge open flat with a pit and two buildings far off, nothing between them.
- 8 Scale tells: PASS (the stumps are plausible beside the trough)
- 9 Edges of the world: FAIL (`0 360 1280 120`): the horizon is a flat line with a dark band on the right and the treeline sits in one tidy row.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Empty plain** (tell 7, `0 360 1280 120`): the middle ground is flat grit and tufts with nothing for the eye. Cause: dressing. Cheapest fix: add a fence line, a wagon, rocks and a path leading to the buildings.
2. **Treeline in one row** (tell 6, `0 100 1000 260`): identical pines in a belt against the sky. Cause: dressing. Cheapest fix: stagger the depth, vary height and add dead trees.
3. **Blocky trough and stumps** (tell 3, `440 480 360 130`): hard-edged slabs with a pixel speckle look like early-2000s props. Cause: material. Cheapest fix: round the corners, add normal detail and moss and wear.
4. **Gritty ground noise** (tell 3, `0 560 1280 160`): the ground texture is a uniform sandpaper grain with visible noise, no big-scale variation. Cause: material. Cheapest fix: add low-frequency colour patches and cracks.
5. **Flat horizon line** (tell 9, `900 330 380 40`): the far dark hills form a ruled band with a black blob. Cause: geometry. Cheapest fix: add height variation and haze.

## Ranking
From least to most cheap-looking: c, a, d, b
