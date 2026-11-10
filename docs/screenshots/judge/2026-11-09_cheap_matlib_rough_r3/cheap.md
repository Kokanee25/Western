# Cheap judge, 2026-11-09_cheap_matlib_rough_r3

## a
- 1 Flat light: PASS (`455 405 545 230`: a real sun, hard cast shadows from rail, posts and the man on the sand)
- 2 No atmosphere: FAIL (`0 20 530 240`; `cut a_mesa_sharp.png`: the mesa a few kilometres off is as crisp and saturated as the near boards, no air between)
- 3 Too clean: FAIL (`455 525 500 110`; `cut a_deck_clean.png`: the floor patch sits on spotless sand, no dust, scuffs or sand drifted onto the boards; treads unworn)
- 4 Too straight: FAIL (`495 165 385 370`; `cut a_panel_straight.png`: every board plumb, the top edges ruler-level, the seams evenly spaced; nothing cups, splits or leans)
- 5 Floating objects: PASS (`455 600 500 40`, `330 560 120 40`: the decks and the man's boots have contact shadow)
- 6 Repetition: FAIL (`0 180 245 365`; `cut a_grain_repeat.png`: the left panel's boards carry the same loud flat-sawn swirl figure, the same cathedral pattern recurring board to board)
- 7 Empty: N/A (the test area)
- 8 Scale tells: PASS (`320 220 900 400`: the man about 1.8 m against a 2 m panel and a waist-high rail reads right)
- 9 Edges of the world: N/A (the test area)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **The left wood looks like a printed veneer** (tell 6, `0 180 245 365`): big contrasty plywood-face grain swirls, sharpened and grainy, the same figure on several boards; it reads as a photo texture laid on flat cards, not as old pine. Cause: material. Cheapest fix: a rift- or quarter-sawn source with tight straight grain, contrast down by half.
2. **Boards too new and too perfect** (tell 4, `495 165 385 370`): the centre panel is a flat grid of identical, dead-straight strips with clean cut ends; no cupping, splits, nail stains or end checks. Cause: geometry. Cheapest fix: a small random twist/cup per board and darkened nail heads and end grain.
3. **No ground contact grime** (tell 3, `455 525 500 110`): sand and boards meet with a clean line; no sand on the treads, no darker damp/dirt band at the foot of the panels. Cause: material. Cheapest fix: a dirt/sand gradient on the lowest 20 cm of every wood surface.
4. **The sky is posterised paint** (tell 2, `520 0 760 200`; `cut a_sky_posterised.png`): the clouds are flat-cut blobs with hard bands, a painted, toy finish next to the semi-photographic mesa. Cause: light. Cheapest fix: a photographic or volumetric sky with soft cloud edges.
5. **No air at distance** (tell 2, `0 20 530 240`): the mesa keeps full contrast and red saturation; noon desert should flatten and blue it. Cause: light. Cheapest fix: aerial-perspective fog tinted by the sky.

## b
- 1 Flat light: PASS (`0 435 745 285`: low warm sun, a hard cast shadow of the rail, light direction clear)
- 2 No atmosphere: N/A (a close-up of one wall)
- 3 Too clean: FAIL (`720 0 240 720`; `cut b_uniform_speckle.png`: each board the same even speckle top to bottom; weathering spread like a filter, not gathered at ends, seams or the bottom)
- 4 Too straight: FAIL (`0 0 1280 420`; `cut b_boards_straight.png`: board edges dead straight and parallel, no splits, checks or warping along their length)
- 5 Floating objects: N/A (no ground or props in frame)
- 6 Repetition: FAIL (`280 0 420 400`; `cut b_speckle_repeat.png`: the same fine dark-dash noise on every board, varied only in base colour)
- 7 Empty: N/A (the test area)
- 8 Scale tells: FAIL (`300 100 200 200`; `cut b_burlap_scale.png`: the surface detail is a fine woven/canvas-like screen of dots, reading as burlap or cardboard at arm's length, not as wood fibre)
- 9 Edges of the world: N/A (the test area)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Wood that reads as burlap** (tell 8, `300 100 200 200`): up close the boards are a crosshatched speckle, like sacking or over-sharpened JPEG noise; there is no grain line running the board's length. Cause: material. Cheapest fix: drop the high-frequency speckle layer and let a long-grain normal/roughness carry the detail.
2. **Stair-stepped shadow** (no tell, `0 435 745 60`; `cut b_shadow_steps.png`): the rail's shadow edge has clear blocky steps across the boards; a player reads it at once as a low-res shadow map. Cause: light. Cheapest fix: a higher shadow resolution or softer PCF filter for this cascade.
3. **Weathering spread evenly** (tell 3, `720 0 240 720`): grey bleaching and dark flecks sit everywhere at the same density; old siding goes grey on the weather side and darker at the seams and foot. Cause: material. Cheapest fix: a mask that gathers wear at seams, ends and the base.
4. **One orange board** (tell 6, `850 0 170 720`): a single saturated orange strip with the same noise; it reads as a recolour of the next board, not a replaced plank. Cause: material. Cheapest fix: desaturate it and give it its own grain map.
5. **No damage on a weathered wall** (tell 4, `0 0 1280 420`): nothing split, no nail holes, rusted heads or end checks to say these boards are years old. Cause: geometry. Cheapest fix: nail heads with rust streaks at a fixed spacing.

## c
- 1 Flat light: PASS (`380 60 640 480`: two lamps pool on the wall, the corners fall to true black)
- 2 No atmosphere: FAIL (`380 60 180 180`; `cut c_lamp_smudge.png`: the lamps are soft glows painted on the wall; no haze or dust in the air around them)
- 3 Too clean: FAIL (`495 165 385 365`; `cut c_panel_clean.png`: the panel looks freshly milled and varnished, no grime, dents or scuffs, no darkening at the base)
- 4 Too straight: PASS (`495 165 385 30`: the boards' top ends stand at different heights, a little irregular)
- 5 Floating objects: PASS (`460 600 500 60`: the deck has a contact shadow on the floor)
- 6 Repetition: FAIL (`500 170 380 250`; `cut c_swirl_repeat.png`: the bold cathedral-grain swirl recurs on several boards, the same figure in two places)
- 7 Empty: N/A (the test room)
- 8 Scale tells: PASS (`320 165 640 460`: the man and panel read in proportion)
- 9 Edges of the world: N/A (the test room)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Glossy new-flooring look** (tell 3, `495 165 385 365`): the boards glow honey-orange with loud contrasty grain, like laminate flooring in a shop display, not old saloon timber under oil light. Cause: material. Cheapest fix: darken and desaturate the albedo by a third and add a grime layer in the grain.
2. **Repeated swirl figure** (tell 6, `500 170 380 250`): the same flat-sawn figure turns up board after board and is the first thing the eye catches. Cause: material. Cheapest fix: more source boards or a random offset/flip per board.
3. **The man drowns in the dark** (no tell, `320 220 140 380`; `cut c_man_dark.png`): he stands outside the lamps' pools and reads as a murky cutout beside a glowing panel; nothing rims him. Cause: light. Cheapest fix: let the lamps' bounce from the bright floor and wall reach him.
4. **Lamps without air** (tell 2, `380 60 180 180`): two round glows on the wall with no visible fixture and no haze; indoors lamplight wants a little smoke catching it. Cause: light. Cheapest fix: a faint volumetric fog in the room.
5. **Speckle under the grain** (tell 3, `540 300 120 120`): over the swirl sits a fine salt-and-pepper noise that reads as sanding dust or a compression artefact. Cause: material. Cheapest fix: remove the speckle layer.

## d
- 1 Flat light: PASS (`250 360 1030 260`: low golden sun, long raking shadows, warm key and cooler shade)
- 2 No atmosphere: FAIL (`0 20 520 240`; `cut d_mesa_sharp.png`: at golden hour the far mesa stays crisp and sharp; no dust or glow in the low sun)
- 3 Too clean: FAIL (`490 170 395 235`; `cut d_pale_boards.png`: the centre panel's pale boards are nearly blank, like unprinted card, with a few small marks)
- 4 Too straight: FAIL (`490 170 395 360`; `cut d_level_boards.png`: horizontal boards ruler-level and evenly spaced, no sag or cup)
- 5 Floating objects: PASS (`465 600 490 40`: the deck and boots sit in their shadows)
- 6 Repetition: FAIL (`490 250 395 150`; `cut d_boards_alike.png`: the pale boards are the same colour and the same sparse marks, board after board)
- 7 Empty: N/A (the test area)
- 8 Scale tells: PASS (`320 220 640 400`: man, rail and panel in proportion)
- 9 Edges of the world: N/A (the test area)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **The centre wall reads as cardboard** (tell 3, `490 170 395 235`): pale, low-contrast, almost featureless boards under a warm sun; no grain, no weather. Cause: material. Cheapest fix: a real weathered-grey pine with visible long grain at this distance.
2. **Board after board the same** (tell 6, `490 250 395 150`): one colour and one pattern across all eight boards; old siding varies plank to plank. Cause: material. Cheapest fix: per-board tint and grain offset.
3. **Three woods, three different renderers** (tell 3, `0 180 250 380`, `1115 150 165 380`): the grey left panel, the blank centre and the orange right panel look like three asset packs at three resolutions. Cause: material. Cheapest fix: one shared grime and wear layer over all of them.
4. **No glow in the golden air** (tell 2, `0 20 520 240`): the sky is pretty, but the low sun puts no haze or dust between viewer and mesa. Cause: light. Cheapest fix: sun-tinted height fog.
5. **Perfect courses** (tell 4, `490 170 395 360`): every board level and the same width; nothing to say a carpenter hung them by hand. Cause: geometry. Cheapest fix: a few millimetres of random tilt and overlap per board.

## e
- 1 Flat light: PASS (`0 460 400 260`: a cast shadow at the lower left and shade in the board laps; direction readable)
- 2 No atmosphere: N/A (a close-up of one wall)
- 3 Too clean: FAIL (`0 300 1280 180`; `cut e_lower_uniform.png`: the lower boards are one even dark grey-brown from end to end; no wear at ends or laps)
- 4 Too straight: PASS (`1150 280 130 440`: the boards' ends stagger and the laps differ a little)
- 5 Floating objects: N/A (no ground contact in frame)
- 6 Repetition: FAIL (`0 300 1280 400`; `cut e_speckle_repeat.png`: the three lower boards share one speckle pattern; only the top board differs)
- 7 Empty: N/A (the test area)
- 8 Scale tells: FAIL (`400 330 250 120`; `cut e_burlap_scale.png`: the fine detail is dot noise, reading as woven cloth or felt rather than wood fibre)
- 9 Edges of the world: N/A (the test area)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Felt, not wood** (tell 8, `400 330 250 120`): the lower boards are a fuzz of dots without a grain direction; at this distance a player sees fabric or carpet. Cause: material. Cheapest fix: replace the noise with the long streaky grain of the top board.
2. **Two boards from different worlds** (tell 6, `0 80 1280 220`): the top board has convincing streaked, silvered grain; the ones below are flat noise. The contrast exposes both. Cause: material. Cheapest fix: use the top board's material for all of them.
3. **Even weathering** (tell 3, `0 300 1280 180`): no lighter sun-bleached faces, no darker laps, no rust runs under nail heads; the rust flecks are scattered evenly. Cause: material. Cheapest fix: a wear mask driven by seam and edge distance.
4. **Soft, jaggy board ends** (no tell, `1150 450 130 270`): the right-hand ends step in a stair pattern and blur, like a low-res mask edge. Cause: geometry. Cheapest fix: a real cut end with end-grain texture.
5. **Dull, shallow light** (tell 1, `0 300 1280 400`): the faces have no sheen or raking texture; the laps' shadows alone give depth. Cause: light. Cheapest fix: a stronger normal map along the grain so raking light catches it.

## f
- 1 Flat light: PASS (`380 60 640 480`: lamp pools, deep corners)
- 2 No atmosphere: FAIL (`930 60 180 180`; `cut f_lamp_smudge.png`: the glows are smudges on the wall, no haze in the air)
- 3 Too clean: FAIL (`490 170 395 360`; `cut f_panel_clean.png`: the panel is evenly stained, no grime, dents or a darker base)
- 4 Too straight: FAIL (`490 170 395 360`; `cut f_level_boards.png`: the courses are level and evenly spaced)
- 5 Floating objects: PASS (`460 600 490 50`: the deck has a contact shadow)
- 6 Repetition: FAIL (`495 200 385 180`; `cut f_boards_repeat.png`: the same streaky dash pattern on every board)
- 7 Empty: N/A (the test room)
- 8 Scale tells: PASS (`320 165 640 460`: the man and panel in proportion)
- 9 Edges of the world: N/A (the test room)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Same streaks on every board** (tell 6, `495 200 385 180`): a horizontal dash noise repeated across all courses; under the lamp it reads like a cheap wood-print laminate. Cause: material. Cheapest fix: per-board variation and a longer, smoother grain.
2. **Furniture-stain finish** (tell 3, `490 170 395 360`): one even reddish stain with no grime; old saloon siding would be darker in the laps and lighter on the edges. Cause: material. Cheapest fix: a cavity-darkening and edge-wear layer.
3. **The man left in the dark** (no tell, `320 220 140 380`): he is a murky shape beside the bright panel, the face barely read. Cause: light. Cheapest fix: bounce from the lit floor reaching him.
4. **Level, even courses** (tell 4, `490 170 395 360`): no sag, cup or uneven lap. Cause: geometry. Cheapest fix: random tilt per board.
5. **Lamp glows without air** (tell 2, `930 60 180 180`): no haze, no fixture. Cause: light. Cheapest fix: a thin volumetric fog.

## Ranking
From least to most cheap-looking: d, f, e, a, c, b

## The man and the wood
- **a** (shows the man): **partly.** He is cleaner and smoother than the wood: a soft, evenly painted vest and shirt with almost no dirt or wear, against boards with loud, sharpened, noisy grain; his detail per metre is lower but his colour and the sun on him sit in the same light as the panels.
- **b** (no man in frame): N/A.
- **c** (shows the man): **no.** The panel glows bright honey with loud grain while he stands outside the light as a murky, low-contrast figure; the wood is much sharper and more saturated, he has no wear to match its noise, and the light seems to belong to the panel alone.
- **d** (shows the man): **partly.** The low sun sits on him and the wood alike, and his clothes have more readable detail than the blank pale centre panel; but he is smooth and painted (soft edges, stepped shadow on his trousers) beside wood that is either blank card or speckle noise; no dust on his boots to match the setting.
- **e** (no man in frame): N/A.
- **f** (shows the man): **no.** As in c: the lit, evenly stained panel and the unlit man read as two separately lit things; his clothes are smooth and clean against wood with busy repeated streaks.
- Overall: the man and the wood look made by different hands: he is smooth, clean and painted, the woods are sharpened noise or loud photo grain, and only the golden-hour daylight (d) puts them convincingly in the same light.
