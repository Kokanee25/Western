# Cheap judge, 2026-11-13_saloon_b_sign

## a
- 1 Flat light: FAIL (`260 360 760 240`, `a_porch_ground.png`): there is a sun and a hard porch shadow, but the facade is one even dull grey-brown, the blacks are lifted to a milky grey everywhere, and the lit sand is a flat beige with no falloff. The shadow is the only shape the light has.
- 2 No atmosphere: PASS (`0 330 1280 120`): the distant blocks and horizon do fade into a pale haze, even though nothing in the air catches the light.
- 3 Too clean: FAIL (`0 560 1280 160`, `a_empty_ground.png`): the street is a spotless, even plane of sand with no ruts, hoofprints, puddles or dirt. Nothing darkens where the porch meets the ground, and the siding is one tone from end to end with no weathering, streaks or paint loss (`400 160 560 200`, `a_facade_upper.png`).
- 4 Too straight: FAIL (`400 160 560 200`, `a_facade_upper.png`): the cornice, balcony rail, posts and windows are perfectly level, evenly spaced and plumb. Nothing on the building sags or leans.
- 5 Floating objects: FAIL (`260 360 760 240`, `a_porch_ground.png`): the posts and steps sit inside the big cast shadow, but nothing darkens where they meet the ground, and the posts' feet simply stop at the sand. The table and chairs on the right (`1060 465 80 40`) have no contact shadow.
- 6 Repetition: PASS: the four upper doors and three lower windows are similar, but they are dressed differently (curtains, lit vs unlit).
- 7 Empty: FAIL (`0 560 1280 160`, `a_empty_ground.png`): one man on the porch and one lone table out on the sand. There are no horses, wagons, barrels, troughs, hitching rails or signs, so the town reads as a test map.
- 8 Scale tells: PASS: the man, the doors and the steps agree with each other.
- 9 Edges of the world: FAIL (`0 280 400 220`, `a_grey_blocks.png`; `1040 330 240 180`, `a_right_edge.png`): untextured grey boxes stand in for the buildings either side, there are more grey blocks on the horizon, and the ground runs flat to an empty horizon.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Grey placeholder boxes either side** (tell 9, `0 280 400 220`): flat, untextured grey slabs where neighbouring buildings should be, plus more grey blocks on the horizon. They read instantly as an unfinished level or a greybox. Cause: geometry. Cheapest fix: hide them out of shot or give them even a rough false-front with a material and a roofline.
2. **Washed-out, lifted light** (tell 1, `260 360 760 240`): the whole frame sits in a milky mid-grey. The saloon's dark wood has no contrast or shading from top to bottom, and the sunlit sand has no warmth or falloff, so it looks like an engine default. Cause: light. Cheapest fix: drop the ambient fill and the black level so shadows go properly dark, and warm the sun.
3. **A blank, spotless street** (tells 3 and 7, `0 560 1280 160`): a third of the picture is perfectly smooth beige with nothing on it: no ruts, tracks, scrub or props. Cause: dressing / material. Cheapest fix: a ground material with wheel ruts and hoof churn, plus a hitching rail, trough and barrels in front of the porch.
4. **Posterised, painted sky** (tell 2 / finish, `0 0 1280 330`, `a_sky_posterised.png`): the clouds are hard-edged bands of three or four flat tones, like a filter. Against a "realistic" building it looks toy-like. Cause: material. Cheapest fix: a smooth-gradient photographic or soft-shaded cloud sky without banding.
5. **Uniform, unweathered facade and stray white specks** (tell 3, `400 160 560 200`, `a_facade_upper.png`): the siding is one flat colour, and odd white dashes speckle the cornice, the wall and the ground in shadow (`820 570 220 20`). These read as texture or render artefacts. Cause: material. Cheapest fix: remove the speckle artefacts and add weathering at the base of the wall and under the eaves.

## b
- 1 Flat light: PASS (`260 340 520 260`, `b_porch_lamps.png`): the warm sconces, lit windows and pools of light on the ground under the porch give the light a clear source and shape against a cold night. The blacks are deep.
- 2 No atmosphere: PASS (`260 340 520 260`): the lamps bloom softly and the distant street fades into the purple night, though there is no dust or smoke in the lamplight.
- 3 Too clean: FAIL (`0 380 700 340`, `b_dark_ground.png`): the ground is a smooth, even gradient with no ruts or texture. The siding is one uniform red-brown with no wear where the wall meets the porch.
- 4 Too straight: FAIL (`640 40 340 260`, `b_false_front.png`): the false front, parapet trim, balcony and porch line are ruler-straight and perfectly regular. Nothing sags.
- 5 Floating objects: PASS (`260 480 520 120`): the porch footings catch the lamp glow and darken where they meet the ground.
- 6 Repetition: FAIL (`0 0 1280 330`, `b_night_sky.png`): the stars are identical square white dots scattered evenly, and the identical wall sconces are spaced evenly along the wall.
- 7 Empty: FAIL (`0 380 700 340`, `b_dark_ground.png`): there is nothing in front of the saloon (no horses, rails, wagon or crates), and only two dim figures far down the street.
- 8 Scale tells: PASS: the doors, windows and porch agree with each other.
- 9 Edges of the world: FAIL (`0 380 700 340`, `b_dark_ground.png`; `1040 360 240 160`, `b_right_street.png`): a dead-flat horizon line on the left with one lone figure on a featureless plain, and the street on the right is flat dark slabs with little detail.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Empty void of ground in the foreground** (tells 3, 7 and 9, `0 380 700 340`): nearly half the frame is smooth black-purple ground running to a ruler-flat horizon, with nothing in front of the saloon. It reads as an unfinished level around a finished building. Cause: dressing. Cheapest fix: a hitching rail with a horse or two, a trough and a wagon in the lamplight in front of the porch, and a broken horizon (hills or buildings) on the left.
2. **Square, evenly sprinkled stars and banded clouds** (tell 6, `0 0 1280 330`): the stars are identical white pixel squares at an even density, and the clouds are posterised into hard flat bands. This is the most "cheap filter" part of the frame. Cause: material. Cheapest fix: varied, tiny, soft stars that thin out near the horizon, and soft-gradient clouds.
3. **Ruler-straight, uniform building** (tell 4, `640 40 340 260`): every line of the false front, balcony and porch is perfect, and the siding is one flat tone with no weathering. The silhouette looks modelled, not built. Cause: geometry / material. Cheapest fix: a slight sag in the porch roof and balcony line, with wear and darkening at the base of the walls.
4. **Neighbouring street reads as dark slabs** (tell 9, `1040 360 240 160`): the buildings down the street are flat dark boxes with no lit windows. At night a town would show some lamplight elsewhere. Cause: light / dressing. Cheapest fix: one or two lit windows or lanterns down the street.
5. **Repeated identical sconces with no air around them** (tell 6, `260 340 520 260`): the same lamp appears five times at even spacing, and the glow is clean, with no dust, moths or haze. Cause: light / dressing. Cheapest fix: vary their spacing and brightness, and leave one unlit.

## Ranking
From least to most cheap-looking: b, a
