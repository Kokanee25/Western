# Cheap judge, 2026-11-09_cheap_matlib_common_r3

Material test panels (a 2 m board wall, a floor patch, a rail on two posts, one man for scale) in an
empty test area: the materials and the man are judged; "7 Empty" and "9 Edges of the world" are
N/A throughout (the emptiness is the test setup's).

## a
- 1 Flat light: PASS (sun from behind left; the posts, man and floor cast clear shadows on the sand, `460 480 560 160`)
- 2 No atmosphere: FAIL (`0 20 540 240`; `cut a_a_mesa_sharp.png`)
- 3 Too clean: FAIL (`495 150 385 250`; `cut a_a_wall_clean.png`)
- 4 Too straight: FAIL (`460 400 500 240`; `cut a_a_rail_straight.png`)
- 5 Floating objects: PASS (feet, posts and floor patch all have contact shadow)
- 6 Repetition: FAIL (`495 180 385 200`; `cut a_a_board_repeat.png`)
- 7 Empty: N/A
- 8 Scale tells: PASS (wall a little over his height, rail at his hip)
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Pale, uniform, new-looking boards** (tell 3, `495 150 385 250`): the whole wall is one even biscuit colour with fine speckle, no weathering, no grey sun-bleach, no dirt splashed up from the ground at its foot; it reads as a laminate sample, not 1880s siding. Cause: material. Cheapest fix: a grime and bleach pass (darker, greyer at the bottom and along seams, lighter grey on the top edges).
2. **Nails in a perfect grid, the same speckle in every board** (tell 6, `495 180 385 200`): nail dots sit in identical vertical columns on every board and the grain/speckle is the same pattern board after board; the eye catches the tiling at once. Cause: material. Cheapest fix: jitter nail positions per board and offset the grain texture per board.
3. **Ruler-perfect panel and rail** (tell 4, `460 400 500 240`): every board dead level, the rail a perfect rectangle on perfectly plumb posts, the seams drawn as even dashed lines like stitching. Cause: geometry. Cheapest fix: a few millimetres of cup, sag and lean per board and post, seams of varying width.
4. **Noon light with no shape on the wood** (tell 1, `495 150 385 400`): the wall face is one flat tone top to bottom, no falloff, no relief in the grain catching the sun; the shadow on the floor is good but the material itself looks unlit. Cause: light. Cheapest fix: stronger normal/relief response on the boards so grain and edges catch the raking sun.
5. **Sharp, saturated distance** (tell 2, `0 20 540 240`): the mesa is as crisp and coloured as the panel; no heat haze. Cause: light. Cheapest fix: aerial haze on the distance.

## b
- 1 Flat light: FAIL (`0 0 1280 400`; `cut b_b_orange_clean.png`)
- 2 No atmosphere: N/A (a close-up of one wall, no distance)
- 3 Too clean: FAIL (`0 0 1280 400`; `cut b_b_orange_clean.png`)
- 4 Too straight: FAIL (`1100 380 180 340`; `cut b_b_board_ends.png`)
- 5 Floating objects: PASS (the rail's shadow lies on the boards where it should)
- 6 Repetition: FAIL (`300 60 700 200`; `cut b_b_speckle_repeat.png`)
- 7 Empty: N/A
- 8 Scale tells: N/A
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Stair-stepped shadow** (tell 1, `0 420 780 300`; `cut b_b_shadow_steps.png`): the rail's shadow has a jagged, pixel-stepped edge and is a single flat brown cut-out; the cheapest-looking thing in the set. Cause: light. Cheapest fix: higher shadow resolution / filtering on this cascade so the edge is soft and clean.
2. **Saturated orange, one tone everywhere** (tell 3, `0 0 1280 400`): every board the same bright tangerine, no grey weathering, no dirt, no darker end grain; looks like varnished furniture stock, not exterior siding. Cause: material. Cheapest fix: desaturate and grey the wood, vary tone board to board.
3. **The light doesn't move across the wall** (tell 1, `0 0 1280 400`): apart from the cast shadow the whole face is evenly lit; the lap of each board casts nothing. Cause: light. Cheapest fix: let each board's lap throw a thin shadow line and give the grain relief.
4. **Same speckle pattern repeated** (tell 6, `300 60 700 200`): the dotted grain is the same noise on every board, like a filter, not wood fibres. Cause: material. Cheapest fix: a texture with real figure (knots, rays) and per-board offset.
5. **Board ends stepping out like steps** (tell 4, `1100 380 180 340`): the right edge staircases board by board with perfect regularity. Cause: geometry. Cheapest fix: vary board lengths and cut ends slightly.

## c
- 1 Flat light: PASS (two lamps on the back wall, falloff into near black, the panel lit from above)
- 2 No atmosphere: FAIL (`380 60 720 260`; `cut c_c_lamp_glows.png`)
- 3 Too clean: PASS (the boards are dark, rough and weathered, `495 150 385 380`)
- 4 Too straight: FAIL (`460 150 500 480`; `cut c_c_panel_straight.png`)
- 5 Floating objects: PASS (posts and floor patch shadowed; his feet lost in dark but grounded)
- 6 Repetition: FAIL (`495 260 385 40`; `cut c_c_odd_board.png`)
- 7 Empty: N/A
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **One bright new board that doesn't match** (tell 6, `495 260 385 40`): a single clean, smooth orange pine board in a wall of dark rough boards; it reads as a different texture pasted in, not a repair, because it has no wear at all and different grain scale. Cause: material. Cheapest fix: weather the replacement board a little so it reads as newer, not as from another game.
2. **The pale floor plane under the light** (tell 1, `320 530 840 190`; `cut c_c_floor_plane.png`): a flat lilac-grey slab, evenly lit, with jagged-stepped shadow edges; it fights the warm room. Cause: light. Cheapest fix: a darker, textured floor and soft shadow edges.
3. **Lamp glows painted on the wall, no air** (tell 2, `380 60 720 260`): the two glows are soft discs on the wall, no lamp, no haze in the beam, nothing in the air. Cause: light. Cheapest fix: a faint volumetric haze around each light.
4. **Ruler-straight panel** (tell 4, `460 150 500 480`): perfect rectangle, perfect rail. Cause: geometry. Cheapest fix: slight lean and sag.
5. **Wood grain reads as noise up close** (tell 3, `495 290 385 240`): the weathering is there but as fine speckle that crawls rather than as checks, splits and raised grain. Cause: material. Cheapest fix: lower-frequency grain with real cracks, mipmap/filter so it doesn't sparkle.

## d
- 1 Flat light: PASS (low golden sun, long shadows of the man and posts, `30 360 470 260`)
- 2 No atmosphere: FAIL (`0 20 900 240`; `cut d_d_mesa_sky.png`)
- 3 Too clean: FAIL (`495 170 385 250`; `cut d_d_wall_clean.png`)
- 4 Too straight: FAIL (`460 400 500 240`; `cut d_d_rail_straight.png`)
- 5 Floating objects: FAIL (`280 360 200 70`; `cut d_d_bush_blobs.png`)
- 6 Repetition: FAIL (`495 170 385 250`; `cut d_d_wall_clean.png`)
- 7 Empty: N/A
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Clean, uniform orange wood** (tell 3, `495 170 385 250`): the wall is a flat honey colour with faint grain, no weathering, no dirt at the base; under the golden sun it looks like a new pine crate. Cause: material. Cheapest fix: grey and darken the boards, grime at the foot, bleach on top edges.
2. **The wood takes the low sun with no relief** (tell 1/3, `495 170 385 250`): a raking golden light should pick out every grain line and board lap; here the face is smooth and even. Cause: light. Cheapest fix: stronger relief/normal response and lap shadows.
3. **Golden hour without dust or glow** (tell 2, `0 20 900 240`): a dramatic sky but the air is clear; the mesa crisp and saturated; nothing in the light. Cause: light. Cheapest fix: warm haze toward the sun.
4. **Green blobs with no contact** (tell 5, `280 360 200 70`): the shrubs beside him are smooth low-poly blobs sitting on the sand, unshadowed underneath. Cause: geometry. Cheapest fix: contact shadow / a proper shrub model.
5. **Perfect rectangle, repeated boards** (tell 4, 6, `460 170 500 460`): every board level and alike. Cause: geometry. Cheapest fix: per-board variation in tone, width and level.

## e
- 1 Flat light: PASS (warm light from one side, a soft shadow falling in at left, `0 430 280 290`)
- 2 No atmosphere: N/A (a close-up of one wall)
- 3 Too clean: PASS (dark, weathered, rough boards)
- 4 Too straight: FAIL (`0 0 1280 420`; `cut e_e_seams_straight.png`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 0 640 360`; `cut e_e_grain_noise.png`)
- 7 Empty: N/A
- 8 Scale tells: N/A
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Grain that reads as digital noise** (tell 6, `0 0 640 360`): up close the weathering is a salt-and-pepper speckle with a fine grid pattern in it, like a sharpening filter or aliased texture, the same everywhere; real weathered wood has long fibres, checks and splits. Cause: material. Cheapest fix: proper texture filtering (mipmaps/anisotropic) and a lower-frequency grain map.
2. **Seams perfectly straight and parallel** (tell 4, `0 0 1280 420`): every board edge a ruled line, every gap the same. Cause: geometry. Cheapest fix: a slight cup and wave per board, varying gap.
3. **Boards all one tone** (tell 3/6, `0 0 1280 720`): each board the same dark grey-brown; no board stands out as older, wetter or sun-struck. Cause: material. Cheapest fix: a per-board tint variation.
4. **The bottom strip a different material** (tell 6, `300 680 900 40`; `cut e_e_bottom_strip.png`): a rusty orange speckled strip under the boards that doesn't read as wood or as dirt. Cause: material. Cheapest fix: match it to the boards or make it read clearly as a sill.
5. **Light without relief** (tell 1, `0 0 1280 420`): the light is directional but the rough surface doesn't throw any micro-shadow; texture is colour only. Cause: light. Cheapest fix: relief/normal strength up.

## f
- 1 Flat light: PASS (top boards lit, falling off to dark toward the floor; lamps on the back wall)
- 2 No atmosphere: FAIL (`380 60 720 200`; `cut f_f_lamp_glows.png`)
- 3 Too clean: FAIL (`495 170 385 360`; `cut f_f_wall_clean.png`)
- 4 Too straight: FAIL (`460 390 500 240`; `cut f_f_rail_straight.png`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`495 170 385 360`; `cut f_f_wall_clean.png`)
- 7 Empty: N/A
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Red-orange wood with banded static** (tell 6, `495 170 385 360`): the boards alternate between smooth bands and bands of crawling orange-black noise, like a broken texture rather than grain; the top two boards look smooth and polished, the rest like TV static. Cause: material. Cheapest fix: one consistent grain texture, filtered, per-board offset.
2. **Colour too saturated, varnished look** (tell 3, `495 170 385 360`): a mahogany red-orange that reads as polished furniture, not a weathered wall; no dust or grime. Cause: material. Cheapest fix: desaturate toward brown-grey, add dirt low down.
3. **The pale floor plane** (tell 1, `320 530 840 190`; `cut f_f_floor_plane.png`): flat lilac slab with stepped shadow edges, out of key with the room. Cause: light. Cheapest fix: darker textured floor, filtered shadows.
4. **Glows on the wall, no air** (tell 2, `380 60 720 200`): no haze in the lamplight. Cause: light. Cheapest fix: faint volumetric haze.
5. **Ruler-straight panel and rail** (tell 4, `460 390 500 240`): perfect lines. Cause: geometry. Cheapest fix: slight sag and lean.

## Ranking
From least to most cheap-looking: c, e, f, d, a, b

## The man and the wood
Pictures with the man: a, c, d, f (b and e are close-ups of the wall only).
- **a: no.** The man is smooth and painted-looking, with soft shading baked into his face and clothes and darker, richer colour; the wood beside him is pale, crisp, high-frequency speckle with ruled seams. Different detail per metre and different finish: he looks like a stylised character model, the wall like a photo-texture sample. Neither shows dirt, but he has none of the wood's grain-level noise.
- **c: partly.** The dark hides most of it: both are warm and dim; his lit shirt and the panel's lit top agree on the light. Up close the wood is rough noisy grain, he is soft and smooth, and his edges are slightly stair-stepped.
- **d: partly.** The golden sun sits on both the same way and the colours belong together; but his clothes and face are softly painted with smooth gradients while the boards are flat colour with fine grain, and both are equally clean.
- **f: partly.** Both are steeped in the same red lamp light; the wood's crawling noise against his smooth painted vest and shirt is the difference.
Overall: the man reads as a smooth, softly painted game character and the wood as a crisp, noisy scanned texture; they share light and colour but not sharpness or finish, and night (c, f) hides the gap best while noon (a) shows it most.
