# Cheap judge, 2026-11-25_hotel_r2

## a
- 1 Flat light: PASS (whole frame; clear sun from the left, long porch shadow)
- 2 No atmosphere: FAIL (`1100 270 180 160`; `cut a_a_haze.png`: far mesas as crisp and saturated as the porch)
- 3 Too clean: FAIL (`160 380 400 130`; `cut a_a_clean.png`: the blue siding is one flat colour wall to wall, no streaks, stains or dirt at the base)
- 4 Too straight: PASS (porch posts and roof line are ruler-true but the boards and posts vary a little; borderline)
- 5 Floating objects: PASS (porch and posts sit with contact shadow)
- 6 Repetition: PASS (balusters and windows repeat, but that is how such a building is)
- 7 Empty: FAIL (`0 560 1280 160`; `cut a_a_empty.png`: a bare sand apron, no hitching rail, barrel, bench, boots or tracks in front of a hotel)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (backdrop cliffs read as far away, no visible seam)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Plain painted-blue box** (tell 3, `160 380 400 130`): the walls are a single saturated blue with faint plank lines, like a model, not a weathered building. Cause: material. Cheapest fix: add vertical dirt streaks, sun fade and a grimy base band to the siding.
2. **Bare ground in front** (tell 7, `0 560 1280 160`): nothing says anyone arrives here. Cause: dressing. Cheapest fix: place a hitching rail, trough, crates and a bench on the sand and porch.
3. **No air in the distance** (tell 2, `1100 270 180 160`): the rock spire is crisp and warm like the foreground. Cause: light. Cheapest fix: add a blue-grey haze that grows with distance.
4. **Sky and flat dune** (tell 3, `0 570 1280 150`): the sand is a smooth beige with no tracks or texture. Cause: material. Cheapest fix: scuff it with wheel ruts and footprints.
5. **Overly even ground light** (tell 1, `0 560 640 160`): the shadow edge is hard and the sand is flat, with no bounce from the blue wall. Cause: light. Cheapest fix: add bounce light and softer shadow edges.

## b
- 1 Flat light: PASS (warm side light, dark floor, bright stair landing)
- 2 No atmosphere: FAIL (`400 300 480 230`; `cut b_b_air.png`: the stair hall has no dust or haze in its light)
- 3 Too clean: PASS (chipped paint flecks and darkened floor show wear)
- 4 Too straight: PASS
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 0 330 720`; `cut b_b_repeat.png`: the same chipped-paint plank texture, with a visible dashed seam line in the ceiling at y~110)
- 7 Empty: FAIL (`280 460 600 260`; `cut b_b_empty.png`: a bare lobby with no desk, rug, furniture or luggage)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Empty lobby** (tell 7, `280 460 600 260`): a hotel hall with no reception desk, chairs or rug. Cause: dressing. Cheapest fix: put in a desk, a rug, two chairs and a lamp.
2. **Repeated chip texture** (tell 6, `0 0 330 720`): the same white chip pattern covers every wall and the pillar. Cause: material. Cheapest fix: vary the tile with a per-wall tint and grime masks.
3. **Ceiling seam** (tell 6, `330 100 600 20`): a dashed light line shows where tiles meet. Cause: geometry. Cheapest fix: close the gap or overlap the panels.
4. **No air in the light** (tell 2, `400 300 480 230`): the sunbeam through the far window hits nothing. Cause: light. Cheapest fix: add a faint dust volume near the windows.
5. **Mid-hall is dark and murky** (tell 1, `280 480 700 240`): the floor is a dull brown with little reflected light. Cause: light. Cheapest fix: raise bounce and add a floor sheen.

## c
- 1 Flat light: PASS (strong sun shafts and shadows)
- 2 No atmosphere: PASS (the sun patches read well, though without dust; borderline)
- 3 Too clean: PASS (chipped paint on the walls)
- 4 Too straight: PASS
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 0 640 400`; `cut c_c_repeat.png`: the same chipped plank tile across both walls)
- 7 Empty: FAIL (`400 380 480 240`; `cut c_c_empty.png`: the landing and the hall below hold nothing)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (the window shows the street outside, with a sign)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Empty landing** (tell 7, `400 380 480 240`): no furniture, lamp or rug on the upper hall. Cause: dressing. Cheapest fix: add a bench, a lamp and a runner.
2. **Repeated wall tile** (tell 6, `0 0 640 400`): identical chip flecks on both walls. Cause: material. Cheapest fix: vary tint and chip density per panel.
3. **Dust missing in the shafts** (tell 2, `60 50 340 340`): the sunbeam edges are crisp and carry no floating motes. Cause: light. Cheapest fix: add a light volume with dust.
4. **Railing is a dark mass** (tell 1, `0 400 1280 220`): the balusters read as black with no edge light. Cause: light. Cheapest fix: add a rim light or bounce on the rail.
5. **Floor stripes mimic the baluster shadow** (tell 4, `0 620 1280 100`): perfectly regular. Cause: geometry. Cheapest fix: vary board widths and add a worn patch.

## d
- 1 Flat light: PASS (sun glare, side shadows)
- 2 No atmosphere: FAIL (`130 170 240 260`; `cut d_d_haze.png`: the rock mass is crisp and orange with no haze)
- 3 Too clean: FAIL (`360 200 560 300`; `cut d_d_clean.png`: the blue siding is one flat colour with no streaks, stains or fade)
- 4 Too straight: PASS
- 5 Floating objects: PASS (shrubs and the steps are grounded with some shadow)
- 6 Repetition: FAIL (`150 440 1000 280`; `cut d_d_grass.png`: the same few grass clumps are scattered evenly, like stamped assets)
- 7 Empty: FAIL (`150 440 1000 280`; sand with grass and nothing else: no barrels, wagons or tracks)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Flat blue walls** (tell 3, `360 200 560 300`): enormous uniform surfaces that read as plastic. Cause: material. Cheapest fix: dirt streaks, fade and a grimy base.
2. **Stamped grass clumps** (tell 6, `150 440 1000 280`): the same shrubs at even spacing. Cause: dressing. Cheapest fix: vary size and tint, add bare patches.
3. **Crisp far rocks** (tell 2, `130 170 240 260`): no distance haze on the mesas. Cause: light. Cheapest fix: add distance haze.
4. **Nothing lived-in around the door** (tell 7, `500 360 200 240`): a back door with no barrels, wood pile or path. Cause: dressing. Cheapest fix: add a worn path and a few crates.
5. **Hard sun with no bounce** (tell 1, `360 520 900 80`): the wall base is a cut-off dark band. Cause: light. Cheapest fix: soften the base with bounce and dirt.

## Ranking
From least to most cheap-looking: c, b, a, d
