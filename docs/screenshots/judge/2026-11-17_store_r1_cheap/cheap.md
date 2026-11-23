# Cheap judge, 2026-11-17_store_r1_cheap

## a
- 1 Flat light: PASS (sky and facade have a clear low sun direction)
- 2 No atmosphere: FAIL (the grey boxes and the distance are as crisp as the foreground, no haze; `0 280 290 320`; `cut a_grey_box.png`)
- 3 Too clean: FAIL (siding is one even beige with no streaks, sun-fade or grime; `300 180 700 200`; `cut a_clean_wall.png`)
- 4 Too straight: PASS (porch posts and rail lean and vary a little)
- 5 Floating objects: PASS (porch posts and steps meet the ground with some contact shadow)
- 6 Repetition: PASS
- 7 Empty: FAIL (bare dirt street, no people, cart, barrel or hitching rail; `0 600 1280 120`; `cut a_empty_street.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (neighbouring buildings are blank grey boxes with a few posts, nothing behind them; `0 280 290 320`; `cut a_grey_box.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Grey placeholder boxes either side** (tell 9, `0 280 290 320`): two flat grey slabs read as unfinished stand-ins. Cause: geometry. Cheapest fix: give them siding, windows and roofline, or hide them behind dressing.
2. **Empty street** (tell 7, `0 600 1280 120`): smooth brown ground with nothing on it. Cause: dressing. Cheapest fix: wheel ruts, a barrel, a crate, a hitched horse.
3. **Facade too clean** (tell 3, `300 180 700 200`): even tan boards, crisp sign, no weathering. Cause: material. Cheapest fix: add vertical grime and board-to-board colour variation.

## b
- 1 Flat light: PASS (hard sun with a clear cast shadow across the wall)
- 2 No atmosphere: PASS (the distance is limited here, and the grey block is the only far element)
- 3 Too clean: FAIL (one huge uniform wall of tan siding with ruler-straight dark lines; `150 100 800 400`; `cut b_clean_wall.png`)
- 4 Too straight: FAIL (dead-straight board lines and a perfect stepped gable; `150 100 800 400`; `cut b_clean_wall.png`)
- 5 Floating objects: PASS (the stair has contact shadow)
- 6 Repetition: PASS
- 7 Empty: FAIL (bare gravel yard and a blank wall with nothing against it; `0 600 1280 120`; `cut b_bare_yard.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (a flat pale grey block stands alone at the right edge; `1120 190 160 450`; `cut b_grey_block.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Giant clean wall** (tells 3 and 4, `150 100 800 400`): a vast surface of one tone and one board pattern. Cause: material. Cheapest fix: vary board colour and add stains, lean-tos and downpipes.
2. **Grey block at right** (tell 9, `1120 190 160 450`): reads as an untextured placeholder. Cause: geometry. Cheapest fix: textured walls or a dressing screen.
3. **Bare yard** (tell 7, `0 600 1280 120`): gravel with nothing on it. Cause: dressing. Cheapest fix: crates, barrels, a woodpile.

## c
- 1 Flat light: PASS (the floor has shadow shapes and light shafts)
- 2 No atmosphere: FAIL (no dust or haze in the light; `0 0 1280 440`; `cut c_empty_room.png`)
- 3 Too clean: PASS (the floor has some wear and variation)
- 4 Too straight: PASS
- 5 Floating objects: PASS
- 6 Repetition: FAIL (the same wood-grain tile is on every post, and the floorboards are clearly tiled; `100 440 1000 270`; `cut c_floor_repeat.png`)
- 7 Empty: FAIL (a huge room with no goods, shelves or counter; `0 0 1280 440`; `cut c_empty_room.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Empty store** (tell 7, `0 0 1280 440`): a general store with no shelves or stock. Cause: dressing. Cheapest fix: shelves, counter, crates.
2. **Tiled grain on posts** (tell 6, `100 440 1000 270`): identical swirly grain on every post, oversaturated orange. Cause: material. Cheapest fix: vary the texture offset and tone down the saturation.
3. **No air in the light** (tell 2, `0 0 1280 440`): add dust motes in the shafts. Cause: light. Cheapest fix: a dust particle layer.

## d
- 1 Flat light: PASS (shafts on the floor, dark ceiling, clear source)
- 2 No atmosphere: FAIL (the light shafts are floor patches only, with no haze in the air; `100 440 1000 270`; `cut d_empty_floor.png`)
- 3 Too clean: PASS
- 4 Too straight: PASS
- 5 Floating objects: PASS (posts cast shadows)
- 6 Repetition: PASS
- 7 Empty: FAIL (an empty hall; one silhouette in the window is the only life; `100 440 1000 270`; `cut d_empty_floor.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (the door opens on a flat pale void with a bare blue strip; `600 310 100 130`; `cut d_door_void.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Empty hall** (tell 7, `100 440 1000 270`): nothing is in the room. Cause: dressing. Cheapest fix: stock and furniture.
2. **Door onto a blank void** (tell 9, `600 310 100 130`): the outside is a flat haze. Cause: geometry. Cheapest fix: put a street view behind the door.
3. **Floor light is just patches** (tell 2, `100 440 1000 270`): no volumetric beams. Cause: light. Cheapest fix: a light-shaft haze.

## e
- 1 Flat light: PASS
- 2 No atmosphere: PASS (some dust specks drift in the light)
- 3 Too clean: PASS
- 4 Too straight: PASS
- 5 Floating objects: PASS
- 6 Repetition: FAIL (the floorboards repeat one pattern edge to edge, with regular orange dashes; `0 420 1280 300`; `cut e_floor_repeat.png`)
- 7 Empty: FAIL (a vast empty loft; `0 0 1280 420`; `cut e_empty_loft.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (the windows show landscape)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Empty loft** (tell 7, `0 0 1280 420`): nothing lives here. Cause: dressing. Cheapest fix: crates, sacks, a bed or a ladder.
2. **Floor tiling** (tell 6, `0 420 1280 300`): a regular repeat with dashes of bright orange. Cause: material. Cheapest fix: break the tile with per-board colour and remove the bright dashes.
3. Roof and trusses read well, and the light direction is good.

## f
- 1 Flat light: FAIL (the middle of the picture is crushed to pure black and nothing reads; `300 150 700 450`; `cut f_black_crush.png`)
- 2 No atmosphere: PASS
- 3 Too clean: PASS
- 4 Too straight: PASS
- 5 Floating objects: PASS
- 6 Repetition: PASS
- 7 Empty: FAIL (empty and mostly unseen; `300 150 700 450`; `cut f_black_crush.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Black crush** (tells 1 and 7, `300 150 700 450`): most of the frame is black with no gradient and no bounce light. Cause: light. Cheapest fix: raise ambient or exposure and add bounce.
2. **Flat bright wall panels** (tell 1, `110 250 950 180`): the walls glow evenly orange with hard edges and no falloff. Cause: light. Cheapest fix: a light falloff and a lamp source.
3. **Banding in the red** (tell 3): posterised dark reds. Cause: light. Cheapest fix: dither or grade the shadows.

## Ranking
From least to most cheap-looking: e, a, c, d, b, f
