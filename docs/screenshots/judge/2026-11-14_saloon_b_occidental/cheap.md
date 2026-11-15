# Cheap judge, 2026-11-14_saloon_b_occidental

## a
- 1 Flat light: FAIL (`0 540 1280 180`; `a_empty_ground.png`): hard sun and a clean cast shadow, but the facade itself is evenly lit dark red end to end and the ground is one flat beige with nothing for light to model.
- 2 No atmosphere: FAIL (`0 290 400 210`; `a_grey_blocks_left.png`): distant mountains, grey blocks and the near building are all equally crisp and clean; no dust or haze in the noon air.
- 3 Too clean: FAIL (`400 170 560 190`; `a_facade_upper.png`): the siding is one uniform paint colour from corner to corner, no weathering, no dirt at the base; ground has no ruts, prints or debris.
- 4 Too straight: FAIL (`400 170 560 190`; `a_facade_upper.png`): dead-level eaves, balcony rail and boards, evenly spaced windows and balusters, perfectly symmetrical front shot straight on.
- 5 Floating objects: FAIL (`260 470 780 80`; `a_porch_contact.png`): porch piers and steps sit on bright flat sand with no contact darkening; the porch reads as set down on top of the ground.
- 6 Repetition: FAIL (`400 170 560 190`; `a_facade_upper.png`): identical baluster run and identical bracket row across the full width.
- 7 Empty: FAIL (`0 540 1280 180`; `a_empty_ground.png`): one figure in the doorway and a lone table set off to the right; the street is a bare plain, no horses, wagons, barrels, signs, trash.
- 8 Scale tells: PASS (door, figure, windows and steps read consistent).
- 9 Edges of the world: FAIL (`0 290 400 210`; `a_grey_blocks_left.png`, `a_grey_blocks_right.png`): untextured grey boxes stand in for the neighbouring buildings, and a strip of snowy mountains and a flat grey slab float on the horizon behind the porch.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Grey placeholder buildings** (tell 9, `0 290 400 210` and `1060 320 220 180`): flat untextured blocks either side of the hero building; reads as a level in grey-box. Cause: geometry. Cheapest fix: hide them (frame them out or swap in any finished facade) before shooting.
2. **Bare sand street** (tell 7, `0 540 1280 180`): two thirds of the frame is a smooth beige plane with nothing on it. Cause: dressing. Cheapest fix: ground texture with wheel ruts, hoof prints and a few scattered props (barrel, trough, hitching rail).
3. **Uniform, unweathered siding** (tell 3, `400 170 560 190`): flat painted red with little light leak specks of sky through the boards under the eave; no sun-bleach, no grime line at the bottom. Cause: material. Cheapest fix: weathering mask (sun-faded top, dirt-splashed bottom, darker seams) and close the gaps under the cornice.
4. **No ground contact** (tell 5, `260 470 780 80`): porch piers and steps sit on clean sand with no dark rim or drifted dirt. Cause: light. Cheapest fix: ambient occlusion / a dirt decal around every pier and step.
5. **Dead-straight symmetrical framing** (tell 4, `400 170 560 190`): building square to camera, every line level, every baluster the same; looks like a CAD model. Cause: camera. Cheapest fix: a three-quarter angle plus a slight sag/lean on the balcony rail and boards.

## b
- 1 Flat light: FAIL (`0 500 1280 220`; `b_crushed_black.png`): the opposite of flat, but the lamps light only a few feet of wall; everything else crushes to pure black with no moonlight shape at all.
- 2 No atmosphere: FAIL (`280 340 300 220`; `b_porch_left.png`): no glow halo or haze around the sconces and window light; light just stops.
- 3 Too clean: PASS (too dark to read cleanliness; what shows, the board texture, has some variation).
- 4 Too straight: PASS (three-quarter view hides the straightness; nothing reads as ruled).
- 5 Floating objects: PASS (porch posts meet a lit patch of ground with shadow under the deck).
- 6 Repetition: PASS (sconces repeat but that is honest for a facade).
- 7 Empty: FAIL (`0 500 1280 220`; `b_crushed_black.png`): nobody on the porch, no light from neighbours, a lit saloon at night with no sign of life outside.
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`560 80 400 260`; `b_roof_lost.png`): the roof and upper storey dissolve into the starfield; the building has no silhouette and the town around it does not exist.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Crushed black** (tell 1, `0 500 1280 220`): half the frame is solid black; the street, the upper floor and the roof are gone. Cause: light. Cheapest fix: a weak blue moonlight / sky fill so shapes read against the sky.
2. **Building lost against the sky** (tell 9, `560 80 400 260`): the roofline only appears as a few orange-lit brackets; no silhouette. Cause: light. Cheapest fix: brighter night sky near the horizon, or a rim from moonlight on the eaves.
3. **Light with no air** (tell 2, `280 340 300 220`): sconces make sharp pools on the boards but no glow, no bloom, no dust. Cause: light. Cheapest fix: a little bloom and volumetric haze around lamps and windows.
4. **Dead street** (tell 7, `0 500 1280 220`): no figures, horses or other lit windows; a saloon at night with nobody about. Cause: dressing. Cheapest fix: one or two figures on the porch and a lit window or lamp across the street.
5. **Speckled, noisy wall** (tell 3, `280 340 300 220`): the siding under the lamps shows blocky orange specks and stair-stepped pixels, reading as a render artefact rather than wood. Cause: material. Cheapest fix: smoother filtering / higher-resolution siding texture.

## c
- 1 Flat light: PASS (low sun behind gives real long shadows, a warm rim and lamplight on the side wall; the light has a direction).
- 2 No atmosphere: FAIL (`0 430 480 190`; `c_grey_blocks.png`): the sun sets into clear air; the street toward the sun has a little glow but no dust, the far buildings as clean as the near ones.
- 3 Too clean: FAIL (`780 240 420 330`; `c_side_wall.png`): the huge side wall is uniform red with no weathering or grime at the ground, and the street is untouched smooth sand.
- 4 Too straight: PASS (the perspective and stairs give it some variety; nothing jumps out as ruled).
- 5 Floating objects: FAIL (`930 500 200 100`; `c_outdoor_bar.png`): the bar counter and bartender stand on the bare sand outside the wall, like interior furniture left in the street, with only a faint contact shadow.
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 560 900 160`; `c_empty_street.png`): a long empty street, two figures in the whole town.
- 8 Scale tells: FAIL (`590 280 100 80`; `c_sign.png`): the sign and its lettering read small and blurred for a building this size; the 2-storey side wall is a vast, almost blank expanse with few small windows.
- 9 Edges of the world: FAIL (`0 430 480 190`; `c_grey_blocks.png`): grey untextured blocks line the street to the left, and to the right of the stairs the horizon is a flat grey slab and a pasted mountain strip (`1080 380 200 210`; `c_stairs.png`).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Grey-box town** (tell 9, `0 430 480 190`): every other building on the street is a plain grey box; the sunset shot is framed straight down them. Cause: geometry. Cheapest fix: aim the camera away from them or give them any finished facade.
2. **Bar standing outside** (tell 5, `930 500 200 100`): a bar counter, bartender and piano sit on open sand against the outer wall, which looks like a bug. Cause: dressing. Cheapest fix: move them inside, or make it a deliberate lean-to with a roof and floor.
3. **Empty, untextured street** (tell 7, `0 560 900 160`): the biggest area of the frame is smooth pale sand catching nothing. Cause: dressing. Cheapest fix: ruts, prints and a few street props (troughs, wagons, posts).
4. **Blank side wall** (tell 3, `780 240 420 330`): an enormous red plane with no weathering, signs or wear and scattered bright specks. Cause: material. Cheapest fix: a weathering pass plus a painted side-wall advert, which would also tell the story of the building.
5. **Clear, dustless sunset** (tell 2, `0 430 480 190`): the low sun should fill the street with haze and dust; instead the air is clean. Cause: light. Cheapest fix: distance fog tinted by the sun, and a little dust in the light shafts.

## Ranking
From least to most cheap-looking: c, a, b
