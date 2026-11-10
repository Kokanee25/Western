# Cheap judge, 2026-11-09_cheap_matlib_r3_metahuman

## a
- 1 Flat light: PASS (`0 500 1920 450`: a low warm sun from the left, long shadows on the sand, the rail's shadow across the floor; the light has a direction. The wall face itself is evenly lit end to end, and the shadow edges stair-step: `a_a_man_feet.png`)
- 2 No atmosphere: FAIL (`0 30 800 360`; `a_a_mesa_sharp.png`: the mesa a mile off is as crisp and saturated as the panel in front; no haze between)
- 3 Too clean: FAIL (`740 250 580 560`; `a_a_pine_clean.png`: the pale pine is fresh-from-the-mill, high-contrast flat-sawn figure with no grey, dirt, splash-back or sun bleaching; the floor patch meets the sand with no dust on it)
- 4 Too straight: FAIL (`690 590 760 60`; `a_a_rail_straight.png`: the rail dead level, both posts plumb, every board the same width and plumb; only the board tops vary a little)
- 5 Floating objects: FAIL (`690 600 760 360`; `a_a_floor_contact.png`: the floor patch sits on the sand with only a hairline under its front edge; `520 780 220 120`, `a_a_man_feet.png`: the planted heel has no contact darkening)
- 6 Repetition: FAIL (`0 380 1920 100`; `a_a_green_blobs.png`: the same smooth olive-green lump repeated over the whole desert floor)
- 7 Empty: N/A
- 8 Scale tells: PASS (`480 330 950 620`: the man, the 2 m wall and the hip-high rail read right for each other)
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **New lumberyard pine with drawn-on grain** (tell 3, `740 250 580 560`): the boards look like a stock "pine plank" texture: bright, even, wildly figured, no weathering, no dirt; it reads as laminate flooring stood on end, not a rough-sawn wall in the desert. Cause: material. Cheapest fix: grey and dull the sun side, push the figure's contrast down by half, and add dust and splash-back on the lowest 20 cm.
2. **The background is as sharp as the foreground** (tell 2, `0 30 800 360`): the mesa is full contrast and full saturation, so the scene has no depth and looks pasted. Cause: light. Cheapest fix: a warm aerial haze that lifts and desaturates anything past ~200 m.
3. **Dashed seams on the floor** (tell 3, `760 820 640 90`): bright dotted lines run along the floor boards' joints, like a texture's alpha edge, not a gap between boards. Cause: material. Cheapest fix: draw the joints dark (a shadowed gap), not light.
4. **The green lumps** (tell 6, `0 380 1920 100`): identical smooth olive pebbles scattered across the sand look like placeholder primitives. Cause: dressing. Cheapest fix: replace with two or three varied rocks and dry scrub, or remove them.
5. **Jagged shadows and floating contacts** (tell 5, `520 780 220 120`): the man's and the posts' shadows have sawtooth edges and the feet and floor have no contact darkening, so things sit on the ground rather than in it. Cause: light. Cheapest fix: a filtered (soft) shadow edge and a small contact-shadow/AO term at the ground.

## b
- 1 Flat light: PASS (`0 500 1920 450`: low sun from the left, shadows with shape; the wall faces are evenly lit, the shadow edges sawtooth)
- 2 No atmosphere: FAIL (`0 30 800 360`; `b_b_mesa_sharp.png`: the mesa crisp and saturated, no haze)
- 3 Too clean: FAIL (`740 250 580 560`; `b_b_wall_mid.png`: the middle wall is a clean, even orange-brown, freshly oiled-looking, the same tone top to bottom; the left pine panel (`0 270 380 700`, `b_b_left_pine.png`) mill-new)
- 4 Too straight: FAIL (`690 600 760 60`: rail level, posts plumb, boards evenly spaced; a few board tops staggered)
- 5 Floating objects: FAIL (`680 780 760 180`; `b_b_floor_contact.png`: the floor patch's edge on the sand with no contact darkening; `520 760 200 140`, `b_b_man_feet.png`)
- 6 Repetition: FAIL (`740 250 580 560`; `b_b_wall_mid.png`: the same pair of pale knots recurs at the same spacing on several boards; `0 380 1920 100`, `b_b_green_blobs.png`: the identical green lumps)
- 7 Empty: N/A
- 8 Scale tells: PASS (`480 330 950 620`)
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Oiled, uniform boards** (tell 3, `740 250 580 560`): the middle wall reads as freshly stained furniture wood; every board the same saturated orange, no grey weathering, no dirt low down. Cause: material. Cheapest fix: desaturate toward silver-brown on the sun side and vary the tone board to board.
2. **Repeated knots** (tell 6, `900 300 400 500`): the same pale knot shape repeats on several boards at the same height, giving the tile away. Cause: material. Cheapest fix: offset and flip each board's UVs at random so no two show the same patch.
3. **No haze** (tell 2, `0 30 800 360`): the mesa as sharp as the panel; no depth. Cause: light. Cheapest fix: aerial haze over distance.
4. **Contacts and jagged shadows** (tell 5, `680 780 760 180`): floor and feet sit on the sand without contact darkening; the rail's shadow on the wall and the floor stair-steps. Cause: light. Cheapest fix: soft shadow filtering and contact AO.
5. **Placeholder rocks** (tell 6, `0 380 1920 100`): the same green lump everywhere. Cause: dressing. Cheapest fix: varied rocks and scrub, or none.

## c
- 1 Flat light: PASS (`0 500 1920 450`: the light has a direction and shadow shapes; the wall in the man's shadow side reads right)
- 2 No atmosphere: FAIL (`0 30 800 360`; `c_c_mesa_sharp.png`: the mesa crisp and saturated, no haze)
- 3 Too clean: PASS (`740 250 580 560`; `c_c_wall_old.png`: grey-brown weathered boards with checks, dark streaks and pale scuffs, nail heads; the floor dark and worn. The two fresh orange battens stand out as new, which is plausible as repairs)
- 4 Too straight: FAIL (`690 600 760 60`: rail level, posts plumb, boards plumb and evenly spaced; the wood looks old but the carpentry is new)
- 5 Floating objects: FAIL (`680 780 760 180`; `c_c_floor_contact.png`: the floor patch's front edge sits on the sand with no dust or darkening; `500 760 200 140`, `c_c_man_feet.png`: the planted heel has no contact shadow)
- 6 Repetition: FAIL (`745 255 80 540`; `c_c_knot_repeat.png`: the same pale knot patch repeats down the leftmost board at a fixed interval; `0 380 1920 100`, `c_c_green_blobs.png`)
- 7 Empty: N/A
- 8 Scale tells: PASS (`480 330 950 620`)
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The knot that repeats** (tell 6, `745 255 80 540`): the same scuffed knot appears three times down one board, the only thing here that says "texture". Cause: material. Cheapest fix: randomise each board's UV offset along its length.
2. **Old wood, new carpentry** (tell 4, `690 600 760 60`): the weathering is convincing but the rail is laser-level and the posts plumb; nothing has moved in years of weather. Cause: geometry. Cheapest fix: a degree or two of lean on a post and a slight sag in the rail.
3. **No haze** (tell 2, `0 30 800 360`): the mesa as sharp as the panel. Cause: light. Cheapest fix: aerial haze.
4. **No ground contact** (tell 5, `680 780 760 180`): floor and feet sit on the sand cleanly; no dust drifted against the boards. Cause: dressing. Cheapest fix: a darker, sand-dusted band where wood meets ground, plus contact AO.
5. **The new battens** (tell 3, `1140 260 30 530`): two bright orange battens look unweathered against the grey wall; good if intended as repairs, otherwise they break the age story. Cause: material. Cheapest fix: weather them part-way.

## d
- 1 Flat light: FAIL (`400 0 1100 1080`; `d_d_grain_close.png`: the wall face is one even grey from top to bottom, no light gradient and no relief catching it; the only shape is a soft shadow at the lower left, `d_d_shadow_edge.png`)
- 2 No atmosphere: N/A (a wall close up)
- 3 Too clean: PASS (`0 0 1920 1080`: the boards are dark, stained, streaked and nailed; old)
- 4 Too straight: PASS (`1500 0 420 1080`: the boards splay and taper at the right, the joints are not perfect)
- 5 Floating objects: N/A
- 6 Repetition: FAIL (`600 580 260 300`; `d_d_grid_patch.png`: square patches with a mesh/screen-door dot grid inside them, stamped across the boards; the same blotches recur)
- 7 Empty: N/A
- 8 Scale tells: PASS (`1250 0 670 1080`, `d_d_right_boards.png`: board widths and nails read right)
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The screen-door squares** (tell 6, `600 580 260 300`): close up the wood shows rectangular patches filled with a dotted grid, like a decal stamp or a compression artefact; it is the first thing a player sees and it reads as broken or generated. Cause: material. Cheapest fix: find and remove the grid in the source texture (or the shader term making it), and soften the patch borders.
2. **No relief under the light** (tell 1, `400 0 1100 1080`): the grain is painted on a flat plane; the checks and splits don't catch the low sun, so it looks like a photo on a board. Cause: light. Cheapest fix: a normal map from the dark streaks so grazing light picks them out.
3. **Smeared detail** (tell 6, `1100 300 400 500`): the pale scuffs and streaks look smudged and blurry rather than carved, with no clear wood fibre at this distance. Cause: material. Cheapest fix: a sharper texture at close range (or a detail map) for this distance.
4. **Muddy grey with no warmth** (tell 1, `0 0 1920 1080`): the whole wall is one desaturated grey-brown under a warm sun; the sun's colour doesn't reach it. Cause: light. Cheapest fix: let the sunlit face take the warm key; keep the grey in the shade.
5. **The mismatched orange batten** (tell 3, `1280 0 250 1080`): a clean orange board in a grey wall reads as a texture mix-up up close. Cause: material. Cheapest fix: weather it part-way to the wall.

## Ranking
From least to most cheap-looking: c, b, a, d

## The man and the wood
- **a: partly.** Colour and the sun's warmth match, but the man is soft and low on detail (a smeared, slightly blurred skin and beard) beside crisp, high-contrast pine; the wood is spotless and new, he is clean too, so wear agrees, but sharpness and detail per metre don't (`480 330 200 300`, `a_a_man_head.png`).
- **b: partly.** The same softness against the sharp, saturated oiled boards; his skin is a warmer, more orange-pink than the wood's brown, and the light sits on him as an even fill while the wall shows its grain hard (`480 330 200 300`, `b_b_man_head.png`).
- **c: partly, closest.** The weathered grey wood carries grime and age and he doesn't (clean, even skin), but his tone sits closest to it and his shading (one leg in the panel's shadow) agrees with the scene's light (`480 330 200 300`, `c_c_man_head.png`).
- Overall: the light and colour make him belong to the same sun, but he is drawn at a lower sharpness and detail per metre than the wood and is clean where the best wood is worn, so he reads as from a slightly different, softer game.

## The man on his own
**Verdict: good indie (low end).** What lifts him: a realistic, well-proportioned face and body, believable skin tone with soft shading, a full beard and hair with real shape, the brass buttons catching the sun. What gives him away: everything is soft and slightly smeared at this size (the beard and hair edges blur into clumps, the eyes don't read as eyes), the skin is an even waxy orange with no pores, redness or grime, and he takes the low sun as a flat front fill with no rim or specular on the brow and nose, so he looks lit by the camera rather than the sun (`a_a_man_head.png`, `c_c_man_head.png`).
