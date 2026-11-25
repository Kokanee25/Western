# Cheap judge, 2026-11-25_hotel_r1

## a
- 1 Flat light: FAIL (`180 200 920 330`; `a_a_ground.png` region of facade, see `a_a_posts.png`): the blue clapboard is evenly lit, with no gradient, eave shadow or sun/shade variation.
- 2 No atmosphere: PASS (`1100 260 180 200`): the buttes on the right sit in the distance, though the air is not strongly hazed.
- 3 Too clean: FAIL (`0 480 1280 240`; `a_a_ground.png`): the ground is a smooth beige plane with no footprints, dust or dirt at the base of the posts or wall; the siding is one uniform blue.
- 4 Too straight: FAIL (`180 160 920 140`; `a_a_cornice.png`): the cornice, balcony rail and 6 windows are in a perfect row at even spacing. Nothing sags or leans.
- 5 Floating objects: PASS (`60 340 700 220`; `a_a_posts.png`): the posts cast soft shadows on the ground and the wall bases have a little darkening. It is a weak pass.
- 6 Repetition: FAIL (`60 340 700 220`; `a_a_posts.png`): the clapboard tile repeats across the whole wall, and the window and post patterns repeat identically.
- 7 Empty: FAIL (`60 340 1140 200`; `a_a_posts.png`): the porch and yard have no chairs, barrels, signs or people, so nobody seems to live here.
- 8 Scale tells: PASS (`550 400 80 110`): the door and windows are plausible against the posts.
- 9 Edges of the world: PASS (`0 270 1280 200`): the mesas and barn give a fair backdrop, but the bare foreground plane is a very flat horizon.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Evenly lit, uniform paint** (tell 1, `180 200 920 330`): the facade reads as a flat blue plane with little shadow shape. Cause: light. Cheapest fix: add a deeper eave and porch-roof shadow and vary the wall tint.
2. **Empty bare yard** (tells 3 and 7, `0 480 1280 240`): clean beige sand with nothing on it. Cause: dressing. Cheapest fix: scatter props, dust trails and grass tufts at the wall base.
3. **Perfect rhythm** (tell 4, `180 160 920 140`): everything is evenly spaced and plumb. Cause: geometry. Cheapest fix: jitter the window sizes and add a slight lean or sag to the rail.
4. **Repeating siding** (tell 6, `60 340 700 220`): the clapboard is the same everywhere, and the lower-wall paint patches look stamped on. Cause: material. Cheapest fix: break the tile up with a per-wall wear mask.
5. **Windows are dark rectangles** (tell 7, `190 375 800 120`): the interior is hardly readable through the glass. Cause: light. Cheapest fix: add a glass reflection and a warmer interior glow.

## b
- 1 Flat light: PASS (`330 260 560 280`): the light shafts at the stair landing give a clear source, though the near room is murky.
- 2 No atmosphere: FAIL (`330 260 560 280`): there is no dust or haze in the light shafts, so the air is empty.
- 3 Too clean: FAIL (`0 0 330 720`; `b_b_pillar.png`): the pillar's paint chips are evenly scattered speckles with no grime or edge wear, and the floor is spotless.
- 4 Too straight: PASS (`260 520 1020 200`): the floorboards have some variation in plank length and tone.
- 5 Floating objects: PASS (`560 380 180 150`): the stair base and posts sit with plausible contact darkness.
- 6 Repetition: FAIL (`300 90 700 40`; `b_b_seam.png`): the ceiling planks tile visibly and a bright dashed seam line runs across them. The wall speckles repeat too.
- 7 Empty: FAIL (`260 260 1020 460`): the lobby has no desk, furniture, rug or baggage. It is only an empty shell.
- 8 Scale tells: PASS (`380 260 520 270`): the stair and doorframes look believable.
- 9 Edges of the world: PASS (`730 400 150 120`): the doorway shows a lit space beyond.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Empty lobby** (tell 7, `260 260 1020 460`): nothing in it implies a hotel. Cause: dressing. Cheapest fix: add a desk, a rug, trunks and a bench.
2. **Ceiling seam and tiling** (tell 6, `300 90 700 40`): a bright dashed line and visible repeats. Cause: material. Cheapest fix: fix the UV seam and use a larger tile with variation.
3. **Speckle wear** (tell 3, `0 0 330 720`): the white dots look like a noise overlay, not real wear. Cause: material. Cheapest fix: replace it with grime gathered at edges and the bottoms of the planks.
4. **No air in the light** (tell 2, `330 260 560 280`): the shafts are bare. Cause: light. Cheapest fix: add dust motes and a light haze.
5. **Wall tone is flat** (tell 1, `930 150 350 400`): the wall is a uniform tan. Cause: light. Cheapest fix: add a shadow gradient and a lamp pool.

## c
- 1 Flat light: FAIL (`870 120 410 500`; `c_c_wall.png`): both walls are evenly mid-tone and the light has no clear direction or fall-off.
- 2 No atmosphere: FAIL (`560 150 160 260`): there is no dust and the far room is the same sharpness as the near one.
- 3 Too clean: FAIL (`0 400 1280 320`; `c_c_floor.png`): the floor is spotless and the baseboards are pristine. The wall chips are the only wear.
- 4 Too straight: FAIL (`120 420 1040 300`; `c_c_floor.png`): the planks are perfectly parallel and plumb, and the hall is a perfect corridor.
- 5 Floating objects: PASS (`430 150 40 70`): the wall lamp is plausibly mounted and the baseboards give contact.
- 6 Repetition: FAIL (`870 120 410 500`; `c_c_wall.png`): the black-fleck wall texture is a visible tile, and the lamp style repeats the one in b.
- 7 Empty: FAIL (`0 0 1280 720`): the corridor is bare, with no runner, door, painting or table.
- 8 Scale tells: PASS (`530 110 200 320`): the door and the lamp are plausible.
- 9 Edges of the world: PASS (`540 130 180 270`): the view through the door shows more rooms.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Bare corridor** (tell 7, `0 0 1280 720`): no sign of use. Cause: dressing. Cheapest fix: add a runner, a side table, pictures and a second door.
2. **Flat walls with speckle** (tells 1 and 6, `870 120 410 500`): the wall texture is a tiled noise. Cause: material. Cheapest fix: vary the tone per board and add a light gradient.
3. **Perfect floor** (tells 3 and 4, `0 400 1280 320`): clean and parallel. Cause: geometry. Cheapest fix: add scuffs, a worn path and boards with a slight warp.
4. **No air** (tell 2, `560 150 160 260`): the doorway view is crisp. Cause: light. Cheapest fix: a faint haze and a light shaft from the far room.
5. **Light direction is unclear** (tell 1, `120 420 1040 300`): the floor shows only a faint shadow. Cause: light. Cheapest fix: a stronger window light and a falloff.

## d
- 1 Flat light: PASS (`370 120 900 420`; `d_d_wall.png`): the sun is clearly overhead-left with some wall shading, though the wall is a fairly uniform blue.
- 2 No atmosphere: FAIL (`150 170 220 250`): the mesa is vivid with no haze and saturated as it is in the foreground.
- 3 Too clean: FAIL (`370 120 900 420`; `d_d_wall.png`): the walls have no stains, rain streaks or wear, and the paint is uniformly saturated blue.
- 4 Too straight: FAIL (`370 120 900 420`; `d_d_wall.png`): the building is a perfect box with evenly spaced windows and ruler-straight siding lines.
- 5 Floating objects: FAIL (`0 440 1280 280`; `d_d_grass.png`): the grass clumps sit on the sand with only a hint of contact shadow, and the stair rail has none.
- 6 Repetition: FAIL (`0 440 1280 280`; `d_d_grass.png`): the same few grass-clump models repeat.
- 7 Empty: PASS (`0 440 1280 280`): the scrub fills the foreground, though there are no props.
- 8 Scale tells: PASS (`560 340 160 200`; `d_d_door.png`): the door and stair rail look plausible against the windows.
- 9 Edges of the world: PASS (`0 400 1280 120`): the distant desert and the mesa blend fairly well.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Saturated, spotless blue box** (tells 3 and 4, `370 120 900 420`): reads as a toy block. Cause: material. Cheapest fix: desaturate and add weathering, streaks and fading toward the lower half.
2. **Grass clumps float and repeat** (tells 5 and 6, `0 440 1280 280`): spiky cards sit on a flat ground. Cause: geometry. Cheapest fix: add contact shadow, size variation and mixed models.
3. **Crisp distant mesa** (tell 2, `150 170 220 250`): no depth haze. Cause: light. Cheapest fix: stronger distance haze.
4. **Plain ground** (tell 3, `0 480 1280 240`): a smooth sand colour with no variation. Cause: material. Cheapest fix: add a ground detail texture and a few tracks.
5. **Siding lines are too even** (tell 4, `370 120 900 420`): the siding is tiny and regular. Cause: geometry. Cheapest fix: vary the board width and add some warp.

## Ranking
From least to most cheap-looking: d, b, a, c
