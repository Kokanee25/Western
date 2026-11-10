# Cheap judge, 2026-11-09_cheap_matlib_common_r2

## a
- 1 Flat light: PASS (`460 480 560 140`: the sun casts clear shadows from the posts, rail and man to the right; the wall face itself is evenly lit top to bottom, but the light's direction reads)
- 2 No atmosphere: FAIL (`0 0 540 260`; `a_a_mesa_sky.png`): the mesa is as sharp and saturated as the panel 2 m from the camera, and the sky's clouds are posterised into flat painted bands
- 3 Too clean: FAIL (`460 150 500 490`; `a_a_wall_clean.png`): the boards are the same pale tan from end to end, no dirt or splash where the floor meets the ground, no wear on the rail's top or the posts' corners
- 4 Too straight: FAIL (`460 400 500 240`; `a_a_rail_straight.png`): rail dead level, posts dead plumb, every board the same width and perfectly parallel
- 5 Floating objects: PASS (`460 600 500 40`: the floor patch and posts sit with contact shadow; the man's boots shadowed)
- 6 Repetition: FAIL (`460 150 500 490`; `a_a_wall_clean.png`): the nail holes sit in the same columns on every board, a regular grid, and every board's seam has the same dotted dash
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS (the man, the ~2 m wall and the waist-high rail agree)
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: good indie**
1. **Nail holes in a grid** (tell 6, `500 160 380 370`): every board has its nails at the same x, so the wall reads as one texture stamped, not boards nailed by a man. Cause: material. Cheapest fix: jitter each board's nail positions and let a few miss or double up.
2. **Wood like new pine** (tell 3, `460 150 500 490`): no greying at the bottom, no dark where the floor and wall meet, no wear on the rail's top; it looks weathered in the texture but never touched. Cause: material. Cheapest fix: a ground-up grime gradient and a rubbed, darker top on the rail.
3. **Posterised sky and razor mesa** (tell 2, `0 0 540 260`): the clouds are flat painted shapes and the far cliffs have no haze, so the realistic wood sits in front of a painted backdrop. Cause: light. Cheapest fix: aerial haze over distance and a smooth-gradient sky.
4. **Ruler-straight build** (tell 4, `460 400 500 240`): rail, posts and boards perfectly level and plumb, every board the same width. Cause: geometry. Cheapest fix: a few millimetres of cup, bow and varying board width.
5. **Wall face evenly lit** (tell 1, `500 160 380 240`): the board face has no relief catching the sun, so it reads as a flat printed plane up close. Cause: light. Cheapest fix: a stronger normal/relief between boards so each lap casts a thin shadow line.

## b
- 1 Flat light: FAIL (`0 380 780 340`; `b_b_shadow_steps.png`): the whole face is one even orange with no falloff; the rail's shadow is a stair-stepped, jagged silhouette (shadow-map steps), not a clean edge
- 2 No atmosphere: N/A (a close-up of a wall; no distance)
- 3 Too clean: FAIL (`0 0 1280 380`; `b_b_veneer.png`): saturated orange like fresh-cut veneer, no grey, no dirt, no split ends, no stains
- 4 Too straight: FAIL (`0 60 1280 360`; `b_b_lines.png`): every lap a perfect horizontal, every gap the same
- 5 Floating objects: N/A (nothing meets the ground in the frame)
- 6 Repetition: FAIL (`0 0 1280 380`; `b_b_veneer.png`): each seam has the same row of little dark dots under it, board after board
- 7 Empty: N/A (test setup)
- 8 Scale tells: N/A
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Shadow in stair steps** (tell 1, `0 430 760 290`): the rail's shadow edge is a row of jagged blocks; a player sees the engine's shadow resolution, not a shadow. Cause: light. Cheapest fix: higher shadow resolution or filtering for this distance.
2. **Orange veneer, not old wood** (tell 3, `0 0 1280 380`): an even, saturated orange with fine grain; reads as a furniture laminate, not a sun-beaten wall. Cause: material. Cheapest fix: pull the saturation down and add sun-greying and grime.
3. **Uniform lit face** (tell 1, `0 0 1280 720`): no change in tone across the wall, no gap shadows with depth. Cause: light. Cheapest fix: deeper relief at the laps so each board edge throws a dark line.
4. **Same speckle row under each seam** (tell 6, `0 150 1280 180`): the dotted dash repeats board to board. Cause: material. Cheapest fix: vary or drop the seam dots per board.
5. **Perfect laps** (tell 4, `0 60 1280 360`): every board the same height, dead parallel. Cause: geometry. Cheapest fix: vary board widths and add a slight warp to a few.

## c
- 1 Flat light: PASS (`300 0 700 720`: deep blacks kept black, warm pools from two lamps, a lit floor in front; the shape reads)
- 2 No atmosphere: PASS (`380 60 640 200`: the lamp glows bloom softly into the dark; a hint of air)
- 3 Too clean: PASS (`500 150 380 380`: the wall boards are dark, grey-brown and worn, with one fresh orange board patched in; the floor boards vary)
- 4 Too straight: FAIL (`460 150 500 480`; `c_c_panel.png`): the boards, rail and posts are dead level and square; the patched board sits perfectly in line
- 5 Floating objects: PASS (`460 590 500 50`: the floor patch and posts shadowed on the pale floor)
- 6 Repetition: FAIL (`500 290 380 110`; `c_c_grain.png`): the old boards' grain is horizontal streaky noise, the same smear on each board, more like a stretched pixel texture than wood
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: good indie**
1. **Streaky, stretched grain** (tell 6, `500 290 380 110`): up close the old boards are horizontal smeared noise, the same on each board. Cause: material. Cheapest fix: a real weathered-board scan with checks, knots and end splits at this scale.
2. **Light with no lamps** (tell 1, `380 60 640 200`): two warm hotspots on the walls with no fixture in them; a player looks for the lamp and finds nothing. Cause: dressing. Cheapest fix: hang the lamps in view.
3. **Jagged floor shadow** (tell 1, `440 530 720 190`; `c_c_floor_shadow.png`): the panel's shadow on the pale floor has stepped edges. Cause: light. Cheapest fix: softer, higher-resolution shadows from that light.
4. **Ruler-straight boards** (tell 4, `460 150 500 480`): every board and the rail dead level. Cause: geometry. Cheapest fix: a slight sag in the rail and uneven board widths.
5. **The fresh board too bright** (tell 3, `500 265 380 30`): the patched board glows flat orange with no grain depth, like a different, cheaper material dropped in. Cause: material. Cheapest fix: give the new board some grain and a little dust so it is new, not plastic.

## d
- 1 Flat light: PASS (`230 380 1050 300`: a low sun from the left throws long shadows; the sky is warm-to-purple)
- 2 No atmosphere: FAIL (`0 0 520 260`; `d_d_mesa.png`): at sunset the mesa is crisp and fully saturated, no haze or dust in the low light
- 3 Too clean: FAIL (`495 170 385 460`; `d_d_panel.png`): the centre panel is one even orange-tan with no dirt, no greying, no wear on the rail or posts
- 4 Too straight: FAIL (`0 160 250 490`; `d_d_left_panel.png`): every panel's boards, rails and posts perfectly level and plumb
- 5 Floating objects: PASS (`460 590 500 50`, `340 560 120 40`: floor patch and boots shadowed)
- 6 Repetition: FAIL (`500 200 370 330`; `d_d_tiled.png`): the centre panel's boards are the same cork-like noise board after board, with the grain running vertically across horizontal boards, like a tiled texture rotated wrong
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Grain running the wrong way** (tell 6, `500 170 380 40`): the top board and the panel's faces show vertical streaks across horizontal boards; it reads as cork or particle board, not planks. Cause: material. Cheapest fix: turn the grain to run along each board.
2. **One noise on every board** (tell 6, `500 200 370 330`): the centre wall repeats the same speckled noise, no board different. Cause: material. Cheapest fix: per-board tone and grain offset.
3. **Floor like carpet** (tell 3, `520 530 360 80`): the floor patch is dark brown streaky noise, reads as a rug or hay mat rather than boards. Cause: material. Cheapest fix: board seams and grain the floor can be read by.
4. **No golden-hour air** (tell 2, `0 0 520 260`): the sunset sky is rich but the mesa is sharp and saturated; no dust glow. Cause: light. Cheapest fix: warm aerial haze that thickens with distance.
5. **Ruler-straight panels** (tell 4, `0 160 250 490`): everything level and plumb. Cause: geometry. Cheapest fix: small sag, lean and width variation.

## e
- 1 Flat light: FAIL (`0 200 1280 300`; `e_e_flat.png`): the wall is evenly lit corner to corner, only the curved cast shadow at bottom left changes anything; the boards have no relief catching light
- 2 No atmosphere: N/A (a close-up of a wall; no distance)
- 3 Too clean: PASS (`0 200 1280 520`: dark, weathered, dirty boards)
- 4 Too straight: FAIL (`0 380 1280 340`; `e_e_lines.png`): every lap a perfect level line, the boards the same width
- 5 Floating objects: N/A (nothing meets the ground in the frame)
- 6 Repetition: FAIL (`0 0 1280 220`; `e_e_zigzag.png`): the top two boards carry the same rust-orange zig-zag band pattern, repeated along their length, and the surface is a woven crosshatch like burlap
- 7 Empty: N/A (test setup)
- 8 Scale tells: N/A
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Rust zig-zags on the top boards** (tell 6, `0 0 1280 220`): a regular orange chevron pattern running along two boards; meaningless, almost generated-looking. Cause: material. Cheapest fix: drop that layer, or break it into irregular stains that follow the grain.
2. **Wood like woven cloth** (tell 6, `0 200 1280 300`): the surface is a fine crosshatch weave rather than grain, reads as burlap or a canvas print. Cause: material. Cheapest fix: a weathered-board texture with grain running along the board.
3. **Even light over the face** (tell 1, `0 200 1280 300`): no shading across the boards, the laps barely shadow. Cause: light. Cheapest fix: deeper lap relief so each board edge throws a shadow line.
4. **Boards of two different woods** (tell 3, `0 300 1280 120`): one board shows coarse striped grain, the next smooth matte; they don't read as one wall's weathering. Cause: material. Cheapest fix: one board stock, varied by tone and wear, not by texture type.
5. **Perfect laps** (tell 4, `0 380 1280 340`): every board level and parallel. Cause: geometry. Cheapest fix: vary widths and add a little warp.

## f
- 1 Flat light: PASS (`300 0 700 720`: deep blacks, lamp pools, a lit floor; shape reads)
- 2 No atmosphere: PASS (`380 60 640 200`: the lamp glows bloom into the dark)
- 3 Too clean: FAIL (`495 170 385 360`; `f_f_wall.png`): the wall is one smooth red-orange, boards barely different, like painted or varnished plastic
- 4 Too straight: FAIL (`460 400 500 230`; `f_f_rail.png`): rail and boards dead level and square
- 5 Floating objects: PASS (`460 590 500 50`)
- 6 Repetition: PASS (the boards vary a little in tone and noise)
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Orange wash on the wood** (tell 3, `495 170 385 360`): the whole panel and floor go one red-orange; wood colour is lost under the lamplight, reads as plastic. Cause: light. Cheapest fix: a less saturated lamp colour, or a wood that keeps its own grey-brown under it.
2. **Wall too smooth** (tell 3, `495 170 385 360`): almost no grain or wear visible on the upper boards. Cause: material. Cheapest fix: stronger grain and relief that survives warm light.
3. **Light with no lamps** (tell 1, `380 60 640 200`): hotspots on the walls without a fixture. Cause: dressing. Cheapest fix: hang the lamps in view.
4. **Jagged floor shadow** (tell 1, `440 530 720 190`): stepped shadow edges on the pale floor. Cause: light. Cheapest fix: softer, higher-resolution shadows.
5. **Ruler-straight boards and rail** (tell 4, `460 400 500 230`). Cause: geometry. Cheapest fix: a slight sag and uneven board widths.

## Ranking
From least to most cheap-looking: c, a, f, b, d, e

## The man and the wood
- **a** (shows the man): **partly.** The wood is pale, crisp, fine-grained, with nail-hole detail at every board; the man is softer and smoother, darker and more saturated (a brown vest, near-black trousers), with painted-looking shading and clean clothes. He has less detail per metre than the boards and no dust where the wood is weathered; the sun sits on both the same way.
- **c** (shows the man): **partly.** Both sit in the same dark, warm light, which binds them; but the man stands in shade with only his face and shirt lit and his clothes are clean and smooth, while the boards beside him are grey, worn and noisy. His detail is softer than the wood's streaky grain.
- **d** (shows the man): **partly.** The low sun lights both from the left and the colours match the warm hour; but the centre wood is coarse orange noise and the man is smooth and clean, sharper-edged in silhouette, his vest richer in detail than the cork-like boards.
- **f** (shows the man): **partly.** The red-orange wash covers the wood more than the man: the panel goes plastic orange while his white shirt stays near white, so they read lit by different lamps; his clothes clean, the wood unworn too.
- b and e show no man.

Overall: the man and the wood live in roughly the same world, but never fully: the wood is crisper and noisier per metre and the man smoother, cleaner and more painted, with the best match in the night room (c), where shared darkness hides the difference.
