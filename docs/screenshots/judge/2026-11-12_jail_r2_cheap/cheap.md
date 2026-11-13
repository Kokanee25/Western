# Cheap judge, 2026-11-12_jail_r2_cheap

## a
- 1 Flat light: FAIL (`0 150 380 520`, the left wall; `cut a_flat_grey_wall.png`): the walls and ceiling sit in one even grey-blue fill with the blacks lifted; the sun from the side door only leaves two thin slivers on the floor (`780 430 380 90`), no real shadow shapes in the room.
- 2 No atmosphere: PASS (`600 220 400 220`): a little haze softens the back wall and the doorway glow.
- 3 Too clean: FAIL (`280 400 640 320`; `cut a_clean_floor.png`): the plank floor is one even varnish from front to back, no dust, scuffs or tracked dirt by the door or along the walls.
- 4 Too straight: FAIL (`300 0 900 240`; `cut a_straight_joists.png`): ceiling joists and boards perfectly parallel and evenly spaced; wall courses ruler-straight, nothing sags.
- 5 Floating objects: PASS (`340 330 460 140`; `cut a_wall_floor_contact.png` checked): the walls darken where they meet the floor.
- 6 Repetition: FAIL (`160 200 200 420`; `cut a_blotch_blocks.png`): every stone block wears the same blue-and-ochre camouflage blotch, with stair-stepped posterised edges; it reads as one tile stamped on every block.
- 7 Empty: FAIL (`300 380 700 340`): a large room with nothing in it: no desk, chair, stove, rack or paper; an unlit sconce on the back wall is the only object.
- 8 Scale tells: PASS (`880 240 120 220`): door, windows and room height read right for each other.
- 9 Edges of the world: FAIL (`880 240 120 220`; `cut a_white_void_door.png`): through the side door the outside is a flat pale grey-white plane with a hard line, no street, no building, no sky detail; the right window (`1220 220 60 220`) is the same blank white.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Camouflage stone** (tell 6, `160 200 200 420`): every block has the same blotchy blue and mustard pattern with pixel-stepped edges; it looks like military camo, not stone. Cause: material. Cheapest fix: replace the blotch noise on the stone with a varied, desaturated stone texture (no blue), one variant per block.
2. **Empty room** (tell 7, `300 380 700 340`): a big jail office with nothing to say anyone works here. Cause: dressing. Cheapest fix: a desk, chair, stove and a gun rack against the walls.
3. **Even grey fill** (tell 1, `0 150 380 520`): the walls are lit the same everywhere and the shadows are grey, so the room looks lit from nowhere though there is sun at the door. Cause: light. Cheapest fix: drop the ambient fill indoors so the sun from the door and windows makes the shapes.
4. **Blank outside** (tell 9, `880 240 120 220`): the doorway opens onto a flat white plane. Cause: camera. Cheapest fix: let the street and the opposite fronts render through openings (or a painted card behind them).
5. **Showroom floor** (tell 3, `280 400 640 320`): clean, uniform planks with no wear path or dirt at the threshold. Cause: material. Cheapest fix: a darker worn path from the door and grime along the wall bases.

## b
- 1 Flat light: FAIL (`540 220 460 500`; `cut b_blue_fill.png`): an even blue moonlight fill over walls, floor and cages, blacks lifted to slate blue; the wall lamp is unlit and nothing throws a shadow you can read.
- 2 No atmosphere: FAIL (`570 200 320 240`; `cut b_far_end_sharp.png`): the far end of the corridor is as crisp as the near cages; no air, and the warm glow behind the far door doesn't spill.
- 3 Too clean: FAIL (`520 420 280 300`; `cut b_clean_tiles.png`): the floor slabs are evenly blotched with no dirt in the corners or along the cage feet.
- 4 Too straight: FAIL (`690 140 570 560`; `cut b_cage_rows.png`): the cage grids are perfectly regular lattices in a perfectly straight row.
- 5 Floating objects: PASS (`760 520 200 200`): cage posts sit on the floor with a little darkening.
- 6 Repetition: FAIL (`690 140 570 560`; `cut b_cage_rows.png`): the same cage repeated four or five times, plus the same blue-ochre blotch on every wall slab and floor tile.
- 7 Empty: FAIL (`900 420 360 280`; `cut b_empty_cells.png`): the cells hold nothing: no bunk, bucket, blanket or prisoner.
- 8 Scale tells: PASS (`560 230 120 180`): cell door and corridor width read right.
- 9 Edges of the world: PASS (interior; no seams seen).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Blue fill everywhere** (tell 1, `540 220 460 500`): the whole block is the same moonlit blue-grey, with no source and no shadow shapes. Cause: light. Cheapest fix: light the wall lamp (or one moon shaft through a window) and pull the ambient down so the rest goes near black.
2. **One cage, copied** (tell 6, `690 140 570 560`): identical lattice cages in a row. Cause: geometry. Cheapest fix: vary them: a door hanging open, a bent slat, one with a bunk and blanket.
3. **Empty cells** (tell 7, `900 420 360 280`): nothing inside to say men are kept here. Cause: dressing. Cheapest fix: a cot, a slop bucket and a blanket in each cell.
4. **Camouflage stone** (tell 3, `520 420 280 300`): the same blue-yellow blotches on walls and floor, posterised. Cause: material. Cheapest fix: a stone texture without the blue blotch, with grime in the corners.
5. **Clean air** (tell 2, `570 200 320 240`): no haze down the corridor. Cause: light. Cheapest fix: a light interior fog so the far end softens and the far door's warm light glows.

## c
- 1 Flat light: PASS (`520 200 160 160`, the lamp, and `880 560 320 160`, cage shadows on the floor): one warm lamp, real falloff, the near wall going to black, lattice shadows on the floor.
- 2 No atmosphere: FAIL (`520 200 160 160`; `cut c_lamp_no_air.png`): the lamp has a small bloom but no glow in the air around it; the corridor's depth is clear.
- 3 Too clean: FAIL (`520 480 300 240`; `cut c_clean_tiles.png`): the lit tiles show the same blotch pattern evenly, no grime or wear underfoot.
- 4 Too straight: FAIL (`690 140 570 560`; `cut c_cage_rows.png`): perfect lattices in a perfect row.
- 5 Floating objects: FAIL (`520 470 110 90`; `cut c_blob_shadow.png`): a hard black oval shadow lies on the floor beside the wall with nothing above it to cast it; it reads as a stray blob.
- 6 Repetition: FAIL (`690 140 570 560`; `cut c_cage_rows.png`): the same cage repeated down the row.
- 7 Empty: FAIL (`920 380 320 300`; `cut c_empty_cells.png`): the cells are bare.
- 8 Scale tells: PASS (`540 220 100 80`): the lamp, door and corridor read right.
- 9 Edges of the world: PASS (interior).
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Identical cages** (tell 6, `690 140 570 560`): the right side is one cage copied in a straight line. Cause: geometry. Cheapest fix: vary the cells (an open door, a broken slat, a different lock).
2. **Empty cells** (tell 7, `920 380 320 300`): no bunks, buckets or prisoner. Cause: dressing. Cheapest fix: a cot and a bucket in each cell; one man asleep.
3. **Black blob on the floor** (tell 5, `520 470 110 90`): an oval of pure black that belongs to nothing. Cause: light. Cheapest fix: stop the lamp's own bracket casting a hard shadow from inside the lamp (or soften it).
4. **Blotched tiles** (tell 3, `520 480 300 240`): the same posterised patches on every slab. Cause: material. Cheapest fix: a stone floor texture with real variation and dirt along the walls.
5. **Clean air** (tell 2, `520 200 160 160`): the lamp lights surfaces but not the air. Cause: light. Cheapest fix: a faint volumetric haze so the lamp has a halo and the corridor depth softens.

## d
- 1 Flat light: PASS (`420 250 160 180`, the lamp pool): a warm sconce pools light on the back wall with a cast shadow below it; the rest of the room falls dark; moonlight at the windows.
- 2 No atmosphere: FAIL (`420 250 160 180`; `cut d_lamp_no_air.png`): the lamp pool has a hard edge on the wall and no glow in the air; the moonlit windows throw no light in.
- 3 Too clean: FAIL (`330 420 640 300`; `cut d_clean_floor.png`): the floor is one even red varnish, no scuffs or dirt.
- 4 Too straight: FAIL (`300 0 800 230`; `cut d_straight_joists.png`): perfectly parallel joists and boards.
- 5 Floating objects: PASS (`470 380 50 40`): the small object under the lamp sits on the floor with shadow.
- 6 Repetition: FAIL (`370 220 240 200`; `cut d_blotch_blocks.png`): the same blotch on every lit stone block.
- 7 Empty: FAIL (`340 360 700 340`; `cut d_empty_room.png`): a large room with nothing in it.
- 8 Scale tells: PASS (`900 240 110 200`): door and windows in proportion.
- 9 Edges of the world: FAIL (`900 240 110 200`; `cut d_blank_door.png`): through the door, a flat blue plane above a flat dark one: no street, no buildings.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Empty room** (tell 7, `340 360 700 340`): a dark, bare hall; the lamp lights a wall with nothing beside it. Cause: dressing. Cheapest fix: a desk under the lamp, a chair, a stove, papers.
2. **Camouflage stone** (tell 6, `370 220 240 200`): the lamp shows off the blue-ochre blotch on every block. Cause: material. Cheapest fix: the stone texture without blotch noise, each block varied.
3. **Nothing outside** (tell 9, `900 240 110 200`): the door opens on a blank blue plane. Cause: camera. Cheapest fix: render the street beyond the door.
4. **Lamp with no air** (tell 2, `420 250 160 180`): a crisp-edged light cone on the wall, no glow in the room. Cause: light. Cheapest fix: a little interior haze so the lamp has a halo and the moonlit windows a faint beam.
5. **Clean ruler floor** (tell 3, `330 420 640 300`): uniform planks and joists. Cause: material. Cheapest fix: wear and dirt on the floor near the door and lamp.

## e
- 1 Flat light: FAIL (`0 380 1280 340`; `cut e_flat_roof.png`): the roof deck and parapet are one even dull tone; the low sun is somewhere behind but casts no shape, no rim and no long shadow on the roof.
- 2 No atmosphere: PASS (`0 230 1280 130`): the far buildings fade into a warm haze.
- 3 Too clean: FAIL (`420 320 640 90`; `cut e_clean_parapet.png`): the parapet is a clean slab with sharp edges, no chips, no debris or tar seams on the roof.
- 4 Too straight: FAIL (`0 230 1280 130`; `cut e_box_town.png`): parapet and every building ruler-straight boxes.
- 5 Floating objects: PASS (`0 330 1280 60`): the parapet sits on the roof with a dark seam.
- 6 Repetition: FAIL (`0 230 1280 130`; `cut e_box_town.png`): the town around is the same untextured box over and over, each with the same thin porch.
- 7 Empty: FAIL (`0 330 1280 390`; `cut e_empty_roof.png`): a bare roof and a lifeless town: no chimney smoke, lamps, people or signs.
- 8 Scale tells: PASS (`600 240 340 90`): porches and fronts plausibly sized at this distance.
- 9 Edges of the world: FAIL (`0 230 1280 130`; `cut e_box_town.png`): the town is grey blockout boxes with no windows or detail, and nothing beyond them: no hills, no horizon.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Blockout town** (tell 9, `0 230 1280 130`): the buildings are blank boxes with no windows, signs or roofs; it looks unfinished. Cause: geometry. Cheapest fix: give the far fronts windows, false-front cornices and a few lit windows, even as flat cards.
2. **Posterised sky** (tell 1, `0 0 1280 240`; `cut e_painted_sky.png`): the clouds are hard orange cut-outs on purple, with stars visible at sunset; painted and toy-like, not a sky. Cause: light. Cheapest fix: softer cloud edges and gradients, stars only once the sky is dark.
3. **Unlit roof** (tell 1, `0 380 1280 340`): the low sun leaves no shape on the deck or parapet. Cause: light. Cheapest fix: let the sun graze the parapet top and throw its long shadow across the roof.
4. **No horizon** (tell 9, `0 230 1280 130`): nothing behind the town: no hills, no distant land. Cause: camera. Cheapest fix: a hazy line of hills behind the town.
5. **Empty roof** (tell 7, `0 330 1280 390`): nothing on the roof or in the town. Cause: dressing. Cheapest fix: a chimney with smoke, a water barrel and a ladder hatch on the roof.

## Ranking
From least to most cheap-looking: c, d, a, b, e
