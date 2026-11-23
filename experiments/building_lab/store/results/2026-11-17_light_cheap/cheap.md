# Cheap judge, 2026-11-17_light_cheap

## a
- 1 Flat light: PASS (hard sun shadow under the porch, 0 340 800 60)
- 2 No atmosphere: FAIL (distance as crisp as foreground, no haze or dust; `0 150 180 180`, cut a_a_box.png)
- 3 Too clean: FAIL (street dirt is a smooth orange gradient, nothing at the porch base; `150 350 500 100`, cut a_a_street.png)
- 4 Too straight: PASS (porch posts and rails have some lean and wear)
- 5 Floating objects: PASS (steps and posts sit in the porch shadow)
- 6 Repetition: PASS
- 7 Empty: FAIL (empty street, no props, no people, no traces of use; `0 340 800 110`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (flat grey-blue blank boxes on both sides read as unfinished backdrop; `0 150 180 180`, cut a_a_box.png)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Blank grey side buildings** (tell 9, `0 150 180 180`): flat untextured boxes beside a detailed storefront. Cause: geometry. Cheapest fix: texture and dress them with the same siding and a roofline.
2. **Empty clean street** (tells 7, 3, `150 350 500 100`): a smooth orange plane, no ruts, hoofprints, litter or props. Cause: dressing. Cheapest fix: ruts, hoofprints and a barrel or trough in front of the porch.
3. **No air** (tell 2, `0 0 800 150`): saturated blue sky and sharp distance with no haze. Cause: light. Cheapest fix: add horizon haze and a little dust in the sun.

## b
- 1 Flat light: PASS (dark, lamplit interior with directional pools)
- 2 No atmosphere: PASS
- 3 Too clean: PASS (weathered grey boards, worn steps)
- 4 Too straight: PASS (leaning posts, uneven rails)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (the same striped siding fills every interior wall; `130 110 670 190`)
- 7 Empty: FAIL (empty porch and room, nothing says anyone works here; `270 290 530 40`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (white blank box at the far left; `0 60 70 100`)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Empty porch and room** (tell 7, `270 290 530 40`): bare deck, no chair, crate or lamp. Cause: dressing. Cheapest fix: a chair, a barrel and a hanging lamp.
2. **Repeated striped siding** (tell 6, `130 110 670 190`): one tile with no stains or breaks. Cause: material. Cheapest fix: add per-board tint variation and water stains.
3. **Blank white building at left** (tell 9, `0 60 70 100`). Cause: geometry. Cheapest fix: dress or darken it.

## c
- 1 Flat light: PASS (sun patches on the floor, though soft)
- 2 No atmosphere: FAIL (no air or dust in the light beams; `0 0 800 450`)
- 3 Too clean: FAIL (floor and walls are spotless, no dirt at wall bases; `0 280 800 170`, cut c_c_floor.png)
- 4 Too straight: FAIL (every plank and board is ruler-straight, columns perfectly vertical; `0 280 800 170`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (striped wall and ceiling tile repeated across all surfaces; `100 0 600 150`, cut c_c_ceil.png)
- 7 Empty: FAIL (a vacant hall; the only objects are two flat grey squares on the floor, `380 340 40 20`)
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Empty, spotless hall** (tells 7, 3, `0 280 800 170`): nothing lived in or used. Cause: dressing. Cheapest fix: counters, crates, scuffs and dirt along the wall bases.
2. **Grey placeholder rectangles on the floor** (tell 7, `380 340 40 20`): read as missing assets. Cause: geometry. Cheapest fix: remove them or give them a real object.
3. **Repeated wall and ceiling stripe** (tell 6, `100 0 600 150`): one uniform tile with no wear. Cause: material. Cheapest fix: vary the tile and add stains near the ceiling.
4. **Dust-free light** (tell 2, `0 0 800 450`): sun patches with no volumetric air. Cause: light. Cheapest fix: a faint dust haze.

## d
- 1 Flat light: PASS (clear floor shadows from the posts)
- 2 No atmosphere: FAIL (no air in the light; the outside is blank; `200 150 400 130`, cut d_d_win.png)
- 3 Too clean: FAIL (spotless floor and walls; `0 280 800 170`)
- 4 Too straight: FAIL (ruler-straight planks and walls; `0 280 800 170`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (striped wall and ceiling tile everywhere; `0 0 800 280`)
- 7 Empty: FAIL (empty room, only the grey floor squares; `380 310 40 30`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (flat white and grey boxes through the windows instead of a world; `200 150 400 130`, cut d_d_win.png)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Blank white world outside the windows** (tell 9, `200 150 400 130`): the view is flat white panels. Cause: geometry. Cheapest fix: a backdrop, building or distant ground.
2. **Empty clean hall** (tells 7, 3, `0 280 800 170`). Cause: dressing. Cheapest fix: props and floor and wall dirt.
3. **Striped tile repeated** (tell 6, `0 0 800 280`). Cause: material. Cheapest fix: vary the tile and stain it.
4. **Grey placeholder squares** (tell 7, `380 310 40 30`). Cause: geometry. Cheapest fix: remove them.

## e
- 1 Flat light: PASS (long directional shadows on the floor)
- 2 No atmosphere: FAIL (no haze or dust, and the windows show blank white; `600 190 200 130`, cut e_e_win.png)
- 3 Too clean: FAIL (spotless floor and walls; `0 280 800 170`)
- 4 Too straight: FAIL (ruler-straight boards and walls; `0 280 800 170`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (the stripe tile aliases into heavy moire bands on the ceiling and walls; `0 0 450 200`, cut e_e_moire.png)
- 7 Empty: FAIL (empty hall, grey squares at `140 365 40 15` and `380 340 30 10`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (flat white and grey blocks outside the windows; `600 190 200 130`, cut e_e_win.png)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Moire on the striped ceiling and walls** (tell 6, `0 0 450 200`): interference rings shimmer across the surfaces. Cause: material. Cheapest fix: mipmap the stripe texture, or lower its contrast in the distance.
2. **White blank outside the windows** (tell 9, `600 190 200 130`). Cause: geometry. Cheapest fix: a backdrop or street beyond the glass.
3. **Empty clean hall** (tells 7, 3, `0 280 800 170`). Cause: dressing. Cheapest fix: props and dirt.
4. **Grey placeholder squares** (tell 7, `140 365 40 15`). Cause: geometry. Cheapest fix: remove them.

## Ranking
From least to most cheap-looking: b, a, d, c, e
