# Cheap judge, 2026-11-15_valley_land2_r2_cheap

## a
- 1 Flat light: FAIL (`0 280 330 100`; `a_flatlight.png`): high sun with weak shaping; the stone walls and white blocks read evenly lit, little shadow shape on the facades.
- 2 No atmosphere: PASS (slight haze down the street at `600 300 120 60`)
- 3 Too clean: FAIL (`30 330 290 170`; `a_wallmaterial.png`): the stone wall is a posterised, pixel-blocky texture with blue and purple blotches, like digital camouflage, not stone; no grime at the base.
- 4 Too straight: FAIL (`380 290 150 130`; `a_straightwalls.png`): walls dead level, ruler-straight tops, no sag or settling.
- 5 Floating objects: FAIL (`0 470 340 60`; `a_wallbase.png`): the wall meets the dirt on a clean line; no dust drift, no darkening.
- 6 Repetition: FAIL (`30 330 290 170`; `a_wallmaterial.png`): the same blotchy block tile repeats block after block.
- 7 Empty: FAIL (`600 360 300 160`; `a_emptystreet.png`): a wide main street with one distant figure, nothing parked, piled or dropped.
- 8 Scale tells: PASS (the hotel's doors, windows and balcony sit right for each other)
- 9 Edges of the world: FAIL (`520 300 120 70`; `a_whiteblocks.png`): untextured white boxes stand at the end of the street like placeholders.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Camouflage stone** (tell 3, `30 330 290 170`): the left-hand walls look like blocky digital camo in tan, blue and purple, and the eye goes there first. Cause: material. Cheapest fix: replace the stone texture with a desaturated, unquantised sandstone with mortar lines and base grime.
2. **Placeholder white boxes** (tell 9, `520 300 120 70`): blank grey-white blocks close the end of the street. Cause: geometry. Cheapest fix: texture them or hide them behind dressing and haze until the buildings exist.
3. **An empty main street** (tell 7, `600 360 300 160`): acres of rutted dirt, one figure, no wagons, barrels, horses or trash. Cause: dressing. Cheapest fix: a wagon, a hitched horse and a few barrels and crates along the boardwalks.
4. **Walls sit on the dirt** (tell 5, `0 470 340 60`): a hard line where the stone meets the ground. Cause: material. Cheapest fix: a dirt and dust decal or blend band up the bottom of every wall.
5. **Midday light without shape** (tell 1, `0 280 330 100`): the facades read evenly lit and the scene looks like an editor view. Cause: light. Cheapest fix: lower the sun or strengthen the ambient occlusion and contact shadows so the porches and walls throw shapes.

## b
- 1 Flat light: PASS (backlit low sun with long shadows and warm lamplight under the porch, `620 260 120 140`)
- 2 No atmosphere: PASS (sun glare and haze down the street)
- 3 Too clean: FAIL (`30 330 290 170`; `b_wallmaterial.png`): the same blotchy camo stone, still with blue and purple patches even in shadow.
- 4 Too straight: FAIL (`230 290 300 130`; `b_straightwalls.png`): walls dead level and ruler-straight.
- 5 Floating objects: FAIL (`0 460 340 60`; `b_wallbase.png`): the wall base meets the ground on a clean line with no dirt build-up.
- 6 Repetition: FAIL (`30 330 290 170`; `b_wallmaterial.png`): the same block tile is repeated.
- 7 Empty: FAIL (`600 340 320 120`; `b_emptystreet.png`): an empty street; the only life is one lit figure on the porch.
- 8 Scale tells: PASS (the hotel, its porch and the figure read right)
- 9 Edges of the world: FAIL (`520 300 120 70`; `b_whiteblocks.png`): untextured white boxes at the end of the street.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Camouflage stone** (tell 3, `30 330 290 170`): the posterised blue and purple blotches still show in shadow and kill the mood the light builds. Cause: material. Cheapest fix: a real sandstone texture without the colour quantising.
2. **Placeholder white boxes** (tell 9, `520 300 120 70`): grey-white blocks at the vanishing point, right under the sun where the eye is led. Cause: geometry. Cheapest fix: texture them or put buildings there.
3. **An empty street** (tell 7, `600 340 320 120`): a beautiful sunset over nothing: no wagon, horse or clutter. Cause: dressing. Cheapest fix: a few street props and a hitched horse catching the backlight.
4. **Hard wall bases** (tell 5, `0 460 340 60`): the walls are stamped onto the ground. Cause: material. Cheapest fix: a grime and dust band at the base.
5. **Ruler-straight walls** (tell 4, `230 290 300 130`): perfectly level tops and corners. Cause: geometry. Cheapest fix: slight unevenness in the top courses and a broken corner or two.

## c
- 1 Flat light: PASS (shrubs cast clear shadows, `0 480 140 50`)
- 2 No atmosphere: PASS (the far mountains go blue and soft)
- 3 Too clean: PASS (the road has gravel, ruts and a hoofprint)
- 4 Too straight: FAIL (`330 370 620 350`; `c_straightroad.png`): the road runs dead straight to the horizon, and its two ruts are perfectly parallel, crisp-edged trenches.
- 5 Floating objects: PASS (shrubs and trees have shadows)
- 6 Repetition: FAIL (`0 340 640 160`; `c_shrubrepeat.png`): the same couple of shrub and grass-tuft models evenly sprinkled across the plain.
- 7 Empty: PASS (open range; the emptiness suits it)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 310 1100 45`; `c_horizon.png`): a flat pale-blue band along the horizon reads like a painted backdrop or a lake with a hard seam; the far mountains look like flat cutouts.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Backdrop band at the horizon** (tell 9, `0 310 1100 45`): a flat blue strip with hard edges where the land should fade out. Cause: geometry. Cheapest fix: blend the backdrop into the terrain with a haze gradient and let the land run up to the mountains.
2. **A ruler road** (tell 4, `330 370 620 350`): two ruts like machined grooves, perfectly parallel to the vanishing point. Cause: geometry. Cheapest fix: wander the road slightly and soften and vary the rut edges.
3. **Sprinkled shrubs** (tell 6, `0 340 640 160`): the same few plants spaced evenly, with no clumping. Cause: dressing. Cheapest fix: cluster the vegetation with noise and add two or three more variants.
4. **Few landmarks** (tell 7, `620 340 60 20`): the eye has only a tiny marker at the vanishing point. Cause: dressing. Cheapest fix: a fence line or telegraph poles along the road.
5. **Bright, even sky and ground** (tell 2, `0 340 1280 40`): the middle distance stays as saturated as the foreground. Cause: light. Cheapest fix: a touch more warm dust haze low over the plain.

## d
- 1 Flat light: PASS (cloud and tree shadows give the ground shape)
- 2 No atmosphere: FAIL (`600 320 680 50`; `d_horizon.png`): trees half a mile off are as dark and sharp as the near ones.
- 3 Too clean: PASS
- 4 Too straight: FAIL (`440 360 400 360`; `d_straighttrench.png`): a single dead-straight trench with crisp, even banks, like a cut channel, not a trail.
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 210 1280 160`; `d_treerepeat.png`): the same pine-like tree, stretched and copied, stands in a row on both sides.
- 7 Empty: PASS
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`600 320 680 50`; `d_horizon.png`): a bare, flat ridge line closes the view with nothing beyond.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Toy bonsai trees** (tell 6, `900 200 120 170`; `d_blobtree.png`): tall bare trunks topped with flat, dark, blobby pads; they read like store-bought model-railway trees. Cause: material. Cheapest fix: a real pine or juniper model with lighter, translucent foliage and branch detail.
2. **Copied trees in rows** (tell 6, `0 210 1280 160`): one tree repeated, all the same dark green. Cause: dressing. Cheapest fix: three variants, random scale and tint, clumped.
3. **A carved trench for a trail** (tell 4, `440 360 400 360`): a crisp channel running straight to the horizon. Cause: geometry. Cheapest fix: a shallower, wider, wandering trail with soft edges.
4. **No air between the trees** (tell 2, `600 320 680 50`): the far trees aren't fading. Cause: light. Cheapest fix: stronger distance fog, tinted to the sky.
5. **A bare ridge horizon** (tell 9, `600 320 680 50`): a smooth sand ridge with nothing behind it. Cause: geometry. Cheapest fix: let the far mountains show over it.

## e
- 1 Flat light: PASS (cloud shadows and shrub shadows)
- 2 No atmosphere: PASS (the far range goes blue)
- 3 Too clean: PASS
- 4 Too straight: PASS (the track curves slightly and its edges vary)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 380 1280 140`; `e_shrubrepeat.png`): the same tuft and shrub models scattered evenly over the whole plain.
- 7 Empty: PASS (open range)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`1090 295 160 60`; `e_conemesa.png`): a smooth, untextured brown cone sits on the horizon like a placeholder; at `0 335 720 30` (`e_bluehorizon.png`) a flat blue strip reads like a backdrop seam.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Placeholder cone** (tell 9, `1090 295 160 60`): a perfectly smooth brown cone with no rock, erosion or texture. Cause: geometry. Cheapest fix: replace it with a textured butte, or remove it.
2. **Blue backdrop strip** (tell 9, `0 335 720 30`): the land stops at a flat pale-blue band. Cause: geometry. Cheapest fix: haze-blend the terrain into the backdrop.
3. **Even shrub sprinkle** (tell 6, `0 380 1280 140`): the same few plants at the same density everywhere. Cause: dressing. Cheapest fix: clumping by noise, bare patches and more variants.
4. **Smooth sand ridges** (tell 9, `700 335 430 25`): the low hills are clean bulges with no rock or erosion. Cause: geometry. Cheapest fix: rock outcrops and gullies on the ridges.
5. **Nothing made by people** (tell 7, `0 360 600 200`): a road, but no post, fence or wreck to say anyone uses it. Cause: dressing. Cheapest fix: one fence line or a trail marker.

## f
- 1 Flat light: PASS (the boxes cast shadows; the sun is clear)
- 2 No atmosphere: PASS (the far range is hazed)
- 3 Too clean: FAIL (`330 350 820 370`; `f_groundpatches.png`): giant rectangular patches of a different dirt texture with hard edges sit on the plain like ground decals.
- 4 Too straight: FAIL (`330 350 820 370`; `f_groundpatches.png`): the town ground is ruler-cut rectangles and the roads are perfectly straight strips.
- 5 Floating objects: FAIL (`380 380 320 60`; `f_boxbase.png`): the boxes sit on the ground with no contact or dirt.
- 6 Repetition: FAIL (`380 320 380 110`; `f_whiteboxes.png`): the same white-grey box, again and again.
- 7 Empty: FAIL (`200 280 1000 170`; `f_empty.png`): no people, animals or smoke anywhere in town.
- 8 Scale tells: FAIL (`380 320 380 110`; `f_whiteboxes.png`): low, slab-like blocks with no doors or windows, so you can't tell how big anything is.
- 9 Edges of the world: FAIL (`0 260 1280 50`; `f_horizonband.png`): a bright white band at the horizon, then a painted mountain strip; it reads as a backdrop seam.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A town of grey boxes** (tell 6, `380 320 380 110`): untextured blocks where buildings should be. Cause: geometry. Cheapest fix: a low-detail stand-in with roofs, colour and texture for every building seen from this distance.
2. **Rectangular ground decals** (tell 3, `330 350 820 370`): huge hard-edged patches of darker dirt show the town's layout like a level-editor grid. Cause: material. Cheapest fix: feather the edges and blend the street dirt into the plain with noise.
3. **White seam on the horizon** (tell 9, `0 260 1280 50`): a glowing white strip between the land and the painted mountains. Cause: geometry. Cheapest fix: extend the terrain into the backdrop and tint the seam with haze.
4. **A dead town** (tell 7, `200 280 1000 170`): no smoke from chimneys, no wagons on the roads, no stock in the fields. Cause: dressing. Cheapest fix: chimney smoke and a wagon or two on the roads.
5. **Ruler-straight roads** (tell 4, `330 350 820 370`): roads as straight strips with clean ends. Cause: geometry. Cheapest fix: wander the roads and fray their ends into the plain.

## Ranking
From least to most cheap-looking: c, e, b, d, a, f
