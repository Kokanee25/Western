# Cheap judge, 2026-11-08_cheap_matlib_common

These are material test panels (a 2 m board wall, a floor patch, a rail on two posts, one man for
scale) in an empty test area: judged on the materials and the man against them; 7 and 9 are N/A
throughout.

## a
- 1 Flat light: FAIL (`495 150 385 260`, the panel's face; `cut a_flat_panel.png`)
- 2 No atmosphere: FAIL (`0 20 540 240`, the mesa and sky; `cut a_sharp_mesa.png`)
- 3 Too clean: FAIL (`460 520 490 115`, the panel's foot and floor patch; `cut a_clean_base.png`)
- 4 Too straight: FAIL (`455 395 500 230`, rail, posts and boards; `cut a_straight_rail.png`)
- 5 Floating objects: PASS (feet and posts have contact shadows)
- 6 Repetition: FAIL (`0 255 520 50`, the identical grey-green stones; `cut a_same_stones.png`)
- 7 Empty: N/A
- 8 Scale tells: PASS (rail at his hip, the 2 m wall a head over him)
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The wood is a pale, washed-out decal** (tell 1, `495 150 385 260`): the sun-facing wall is one even biscuit tone from top to bottom, with no raking light catching board edges; the lap lines are thin dark pen strokes and the "grain" is oak-figure printed flat on siding, with a fine dither noise over it. Nails sit in identical columns. Cause: material. Cheapest fix: lower albedo and give each board its own tone, with a real lap shadow under each board's edge.
2. **No wear where wood meets ground** (tell 3, `460 520 490 115`): the bottom board, posts and floor patch are as clean as the top; no grey sun-bleach, splash dirt or darkened end grain. Cause: material. Cheapest fix: a ground-up grime and bleach gradient on every board.
3. **Everything ruler-true** (tell 4, `455 395 500 230`): the rail, the posts and every board are dead level and identical in width, with sharp CG edges. Cause: geometry. Cheapest fix: vary board widths and add a few mm of cup, sag and twist.
4. **Clean air, posterised sky** (tell 2, `0 20 540 240`): the mesa is crisp and saturated for its distance, and the clouds are flat cut-out bands of colour. Cause: light. Cheapest fix: aerial haze on distance and a smooth sky.
5. **Copy-pasted stones** (tell 6, `0 255 520 50`): the same rounded grey-green pebble is stamped across the sand. Cause: dressing. Cheapest fix: vary their shape, scale and colour, or remove them.

## b
- 1 Flat light: FAIL (`0 420 780 300`, the rail's shadow; `cut b_blocky_shadow.png`)
- 2 No atmosphere: N/A (a close-up, no distance)
- 3 Too clean: FAIL (`0 60 1280 340`; `cut b_clean_veneer.png`)
- 4 Too straight: FAIL (`0 0 1280 720`; `cut b_straight_boards.png`)
- 5 Floating objects: PASS (each lap has a faint shadow line)
- 6 Repetition: PASS (no obvious tile at this range)
- 7 Empty: N/A
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Furniture veneer, not outdoor boards** (tell 3, `0 60 1280 340`): a saturated orange, evenly varnished-looking surface with fine pore speckle and soft blotches, like a laminate sample; no checking, grey weathering, splits or nail rust. Cause: material. Cheapest fix: desaturate toward grey-brown and add sun-bleach and checks along the grain.
2. **A stair-stepped shadow** (tell 1, `0 420 780 300`): the rail's shadow on the wall has jagged steps along its edge, a low-resolution shadow map, the first thing the eye goes to. Also, no raking light shows relief in the grain. Cause: light. Cheapest fix: a higher shadow resolution or filtering on the sun for close views.
3. **Perfect parallel boards** (tell 4, `0 0 1280 720`): every board is the same height, perfectly straight and flush. Cause: geometry. Cheapest fix: per-board width and slight warp.
4. **Grain with no depth** (tell 1, `0 60 1280 340`): the figure is all colour, with no normal or roughness change, so under direct sun it reads as printed. Cause: material. Cheapest fix: drive roughness and a normal from the grain so raised grain catches the light.
5. **No lap shadow weight** (tell 4, `0 380 1280 60`): the lap edges barely step out, so the wall reads as one flat sheet with lines drawn on. Cause: geometry. Cheapest fix: a thicker board edge with a clear shadow under it.

## c
- 1 Flat light: PASS (deep blacks, falloff from the lamps)
- 2 No atmosphere: FAIL (`380 60 640 160`, the glows on the wall; `cut c_glow_no_air.png`)
- 3 Too clean: PASS (the wall is weathered; see reason 3 for the one fresh board)
- 4 Too straight: FAIL (`460 260 420 360`; `cut c_straight_wall.png`)
- 5 Floating objects: PASS
- 6 Repetition: PASS
- 7 Empty: N/A
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The grain reads as static, not wood** (tell 4, `460 260 420 360`): the weathered grey-brown wall is a dense high-frequency speckle with no long grain lines, knots or splits; up close it looks like TV noise laid on planks. Cause: material. Cheapest fix: a weathered texture with long, directional grain and checks, at a lower frequency.
2. **Glows with no lamp and no air** (tell 2, `380 60 640 160`): two soft discs of light on the back walls with no visible fixture and no haze in the beam; the light comes from nowhere. Cause: light. Cheapest fix: show the lamps and add a little volumetric haze near them.
3. **One board from another set** (tell 3, `497 268 380 22`): a single bright, clean orange board across the old grey wall; it could be a deliberate patch, but it reads as a texture error. Cause: material. Cheapest fix: age it down so it's a newer board, not a different material.
4. **The man is left out of the light** (tell 1, `300 220 180 380`; `cut c_man_unlit.png`): he stands a step from the lit wall but gets almost none of its light; his legs sink into black. Cause: light. Cheapest fix: let the lamps (or a weak fill) reach him as they reach the panel.
5. **A blocky shadow on a pale floor** (tell 1, `470 600 520 110`; `cut c_blocky_floor_shadow.png`): the panel's shadow on the bright pinkish floor has stair-stepped edges, and the floor is a flat untextured plane lit like a spotlight. Cause: light. Cheapest fix: shadow filtering and a darker, textured floor.

## d
- 1 Flat light: PASS (low warm sun, long shadows, post shadows on the wall)
- 2 No atmosphere: FAIL (`0 30 520 230`; `cut d_sharp_mesa.png`)
- 3 Too clean: FAIL (`460 520 490 115`; `cut d_clean_base.png`)
- 4 Too straight: FAIL (`455 395 500 230`; `cut d_straight_rail.png`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`230 260 900 40`; `cut d_same_stones.png`)
- 7 Empty: N/A
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie** (the best of the six; the light alone is good indie)
1. **The top board's grain runs the wrong way** (tell 3, `495 165 385 60`; `cut d_top_board_grain.png`): the top board shows vertical, bark-like streaks across a horizontal board, a texture mapped 90° off. Cause: material. Cheapest fix: rotate the UVs on that face so the grain follows the board.
2. **No dust in the low sun** (tell 2, `0 30 520 230`): golden hour with a dramatic sky, but the mesa is crisp and saturated and there's no glow or dust in the air; the light has direction but no body. Cause: light. Cheapest fix: warm aerial haze and a little sun-lit dust.
3. **Clean, uniform orange wood** (tell 3, `460 520 490 115`): the wall is one even orange from top to bottom, and the floor patch's dark grain looks like printed bark; no grey bleach, no dirt line at the foot. Cause: material. Cheapest fix: a bleach and grime gradient, and a less saturated base.
4. **Box-straight panels** (tell 4, `455 395 500 230`): the rail and posts are perfect boxes with sharp edges and the boards are identical. Cause: geometry. Cheapest fix: eased edges, slight warps, varied widths.
5. **Stamped stones** (tell 6, `230 260 900 40`): the same green-grey pebble repeated over the sand. Cause: dressing. Cheapest fix: vary them or remove them.

## e
- 1 Flat light: FAIL (`0 220 640 200`; `cut e_noise_grain.png`)
- 2 No atmosphere: N/A (a close-up)
- 3 Too clean: PASS (dark, weathered, rusty)
- 4 Too straight: FAIL (`0 0 1280 720`; `cut e_straight_boards.png`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 100 1280 240`; `cut e_rust_patches.png`)
- 7 Empty: N/A
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Patchwork stain with hard geometric edges** (tell 6, `0 100 1280 240`): the orange-rust weathering on the top two boards is made of hard-edged triangles and rectangles, the same blotch shape repeating along the board; it looks like a mask showing through, not wear. Cause: material. Cheapest fix: soft, grain-following stain masks that don't repeat along the board.
2. **Speckle noise for grain** (tell 1, `0 220 640 200`): the dark boards are covered in a dense black-and-tan dot noise that has no direction or depth; under daylight nothing catches the light, so it reads as burnt toast rather than old pine. Cause: material. Cheapest fix: directional grain with a normal and roughness change, less pepper.
3. **A bright line between boards** (tell 4, `0 95 1280 12`): a thin cream line along the top seam, like the background showing through a gap or a UV edge. Cause: geometry. Cheapest fix: close the gap or shade the seam dark.
4. **Same plank, ruler-straight** (tell 4, `0 0 1280 720`): perfectly parallel, identical-height boards. Cause: geometry. Cheapest fix: vary width and add slight warp.
5. **No surface light** (tell 1, `0 0 1280 720`): apart from a cast shadow at bottom left, the face is evenly lit; no sheen or relief on the weathered surface. Cause: light. Cheapest fix: roughness variation so worn high spots catch a little sheen.

## f
- 1 Flat light: PASS (dark room, falloff downward)
- 2 No atmosphere: FAIL (`380 60 640 160`; `cut f_glow_no_air.png`)
- 3 Too clean: FAIL (`495 170 385 360`; `cut f_fresh_red.png`)
- 4 Too straight: FAIL (`455 395 500 230`; `cut f_straight_rail.png`)
- 5 Floating objects: PASS
- 6 Repetition: PASS
- 7 Empty: N/A
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Glowing, over-saturated red wood** (tell 3, `495 170 385 360`): the panel is a hot red-orange, as if it were lit from inside; it reads as fresh stained lumber with little wear and none of the dark, varnished depth of an old saloon. Cause: material. Cheapest fix: lower albedo and saturation so the lamps, not the wood, make the warmth.
2. **Glows with no lamp and no air** (tell 2, `380 60 640 160`): the same two fixture-less light discs on the walls, no haze. Cause: light. Cheapest fix: visible lamps, a little haze.
3. **Boxy, perfect geometry** (tell 4, `455 395 500 230`): the rail, posts and boards are identical sharp-edged boxes. Cause: geometry. Cheapest fix: eased edges, slight sag and twist.
4. **A blocky shadow on a plain floor** (tell 1, `470 600 520 110`; `cut f_blocky_floor_shadow.png`): stair-stepped shadow edges on a flat pale plane. Cause: light. Cheapest fix: shadow filtering.
5. **The man outside the lamplight** (tell 1, `320 225 140 360`): he stands beside the lit panel but gets almost none of its light; his legs are lost in black. Cause: light. Cheapest fix: let the lamps' light reach him.

## Ranking
From least to most cheap-looking: d, c, f, e, a, b

## The man and the wood
- **a (shows the man): no.** He is sharp, contrasty and richly coloured (dark trousers, patterned vest, defined face), while the wood beside him is pale, low-contrast and washed out. He has much more detail per metre and real shading; the wood has none of his wear or depth, so he looks pasted onto a flat stage set.
- **b (no man).**
- **c (shows the man): partly.** Both sit in the same warm night, but the wall's coarse speckle noise is much harsher and higher-frequency than his smooth, soft-shaded clothes and face, and the lamps light the wood while barely touching him.
- **d (shows the man): partly (closest).** The low warm sun sits on both the same way and the colours agree; the difference is in the material: he is modelled, soft and believable, while the wood is a flat, saturated photo-like texture on sharp boxes (and the top board's grain is mapped the wrong way).
- **e (no man).**
- **f (shows the man): partly.** The red wood is far more saturated and glows brighter than anything on him; he is darker and more muted, so they look lit by different lights. His clothes show more fine detail than the wood's flat stain.
- **Overall: the man looks like a more finished, more realistic asset than the boards beside him in every picture; the gap is the wood's (flat, over-saturated or noisy texture on perfect boxes), not his, and it closes most under the low sun of d.**
