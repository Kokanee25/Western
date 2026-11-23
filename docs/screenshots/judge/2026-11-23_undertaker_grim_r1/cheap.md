# Cheap judge, 2026-11-23_undertaker_grim_r1

## a
- 1 Flat light: PASS (`840 240 120 200`: one wall lamp, warm pool, real shadow of the lamp bracket and table; the corners fall to true black)
- 2 No atmosphere: PASS (`500 210 290 200`: a faint haze softens the far doorways; the lamplight has some air)
- 3 Too clean: FAIL (`440 385 485 200`, `a_table_clean.png`: the embalming table top is one even, smooth dark slab with no stains, scrubbed patches, scratches or worn edge; the floor tiles' blotches read as a printed pattern, not spills)
- 4 Too straight: FAIL (`300 0 980 180`, `a_joists.png`: joists dead parallel and evenly spaced, the post plumb, every board edge ruler-straight; nothing sags)
- 5 Floating objects: PASS (`780 450 300 270`: table and stool legs have contact shadows on the floor)
- 6 Repetition: FAIL (`500 210 290 200`, `a_twin_doors.png`: two identical plain doorways side by side; the floor tile stain pattern repeats tile to tile)
- 7 Empty: FAIL (`1055 180 225 330`, `a_empty_shelf.png`: the shelving is bare; the room holds a table, a stool, a bucket and a basin, no jars, tubing, rags, tools or sheets)
- 8 Scale tells: PASS (table, stool, doors and lamp sit at believable sizes)
- 9 Edges of the world: PASS (closed interior; the far rooms carry on through the doors)
- 10 Stiff people: N/A
- **Verdict: good indie**
- Used and stained: Half way: the walls and floor tiles carry some dark blotches and the low light hides a lot, but the table itself, the shelves and the joins look clean and new; nothing says decades of bodies were worked here.
1. **The embalming table is spotless** (tell 3, `440 385 485 200`): the one object the room is about is a smooth, even, near-black box with no stains, wear on the edges or drainage grime. Cause: material. Cheapest fix: a worn, stained table material (dark patches where fluids ran, rubbed pale edges, drip marks on the floor below its foot end).
2. **Bare shelves and no tools of the trade** (tell 7, `1055 180 225 330`): empty shelving and an empty room read as unfinished. Cause: dressing. Cheapest fix: fill the shelf with bottles, jars, a pump, folded sheets and rags.
3. **Blocky, printed-looking floor stains** (tell 3/6, `780 450 300 270`): the tile blotches are coarse squares that repeat and sit glossy and uniform; one reads as leftover pixel squares rather than stain. Cause: material. Cheapest fix: a higher-resolution, non-repeating grime layer concentrated round the table and drain, duller in the worn paths.
4. **Ruler-straight timber** (tell 4, `300 0 980 180`): joists, post and boards are perfectly regular, so the cellar reads as freshly built. Cause: geometry. Cheapest fix: small random sag, twist and spacing variation in the joists, and one shimmed or patched board.
5. **Jagged sawtooth edges on the table's lower rails** (tell 3, `520 520 400 120`): the rail edges show a stair-stepped serration that reads as a rendering artefact. Cause: geometry. Cheapest fix: smooth or bevel those rail edges (or fix the aliasing on them).

## b
- 1 Flat light: FAIL (`700 200 400 400`, `b_flat_floor.png`: the whole floor is evenly lit with no clear source or falloff; the cellar below is the only contrast)
- 2 No atmosphere: FAIL (`0 150 560 400`: no dust or haze in the room or rising from the cellar; every board equally crisp)
- 3 Too clean: FAIL (`0 150 560 400`, `b_floor_tile.png`: a glossy, varnished, even floor with no scuffs, tracks or dirt round the stair opening that people climbed for years)
- 4 Too straight: FAIL (`0 150 560 400`, `b_floor_tile.png`: every plank perfectly parallel and evenly spaced, no warp or gaps)
- 5 Floating objects: PASS (the posts and rail meet the floor with some shading)
- 6 Repetition: FAIL (`0 150 560 400`, `b_floor_tile.png`: the same wood-grain pattern and the same bleached streak repeat across the planks)
- 7 Empty: FAIL (`700 200 400 400`: a huge bare floor with nothing on it; the workroom gives no sign of work)
- 8 Scale tells: PASS (stair, rail and planks plausible)
- 9 Edges of the world: FAIL (`500 120 300 450`, `b_stairwell.png`: the stairwell is a hard-edged box with a thin white seam line down the cellar wall, and a blocky, pixelated cellar floor below)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
- Used and stained: Clean and new: the floor is glossy and uniform with no wear path to the stair, no drips or tracked grime; only the stair treads and rail have weathered grain, and that reads as an old-wood texture, not use.
1. **A bare, polished floor fills the frame** (tells 3/7, `0 150 560 400`): two thirds of the picture is clean, shiny, empty planking. Cause: dressing. Cheapest fix: dirt and scuffs in a worn path to the stair, dark drips near the opening, and a few things on the floor (a stretcher, a bucket, a coffin board).
2. **Repeating, ruler-straight planks** (tells 4/6, `0 150 560 400`): the same grain and streak tile over and over on perfectly parallel boards. Cause: material. Cheapest fix: vary each plank's colour, gloss and grain offset, and break the tile.
3. **Seam and blocky texture in the stairwell** (tell 9, `500 120 300 450`): a bright vertical line down the cellar wall and coarse squares on the cellar floor give the render away. Cause: geometry. Cheapest fix: close the wall seam and use a finer floor texture below.
4. **No light source, no falloff** (tell 1, `700 200 400 400`): the floor is lit evenly with no window or lamp pool to explain it. Cause: light. Cheapest fix: one strong directional pool (a window or lamp) with the rest falling into darkness.
5. **No air** (tell 2, `500 120 300 450`): no dust in the light, nothing coming up from the dark cellar. Cause: light. Cheapest fix: a light dust volume in the room and a faint haze in the stairwell.

## Ranking
From least to most cheap-looking: a, b
