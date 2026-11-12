# Cheap judge, 2026-11-12_doctor_light_r1

## a
- 1 Flat light: FAIL (`0 0 320 720`; `a_grey_wall.png`): one even grey-green wash over walls and desk, no light shape anywhere, the darks lifted to murky grey; the wall lamp at top right is unlit and nothing says where the light comes from.
- 2 No atmosphere: FAIL (`0 0 1280 720`; `a_grey_wall.png`): a dim room with no air at all, no falloff, no dust, every surface the same clarity.
- 3 Too clean: FAIL (`860 0 420 560`; `a_straight_boards.png`): the board wall is one even off-white with a scatter of identical black flecks; the desk has no wear on edges, the blotter is spotless.
- 4 Too straight: FAIL (`860 0 420 560`; `a_straight_boards.png`): every board dead vertical, evenly spaced, no warp or gap variation.
- 5 Floating objects: PASS (desk base and chair at the floor, `400 600 700 120`, read as grounded in the gloom).
- 6 Repetition: PASS (the wall flecks repeat but read as one material).
- 7 Empty: FAIL (`340 240 440 120`; `a_blank_pigeonholes.png`; `540 360 260 110`; `a_bare_desk.png`): the pigeonholes hold blank white cards, the desk holds one inkwell; nothing says a doctor works here.
- 8 Scale tells: PASS (desk, drawers, chair agree).
- 9 Edges of the world: PASS (interior; the window at right is a sliver).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Grey, sourceless light** (tell 1, `0 0 1280 720`): the whole frame is one dull murk, the blacks grey, a lamp on the wall that isn't lit. Cause: light. Cheapest fix: light the wall lamp (or a window shaft) as the key and let the rest fall to true dark.
2. **Blank papers in the pigeonholes** (tell 7, `340 240 440 120`): flat white rectangles, no writing, no curl, no clutter; reads as placeholder. Cause: dressing. Cheapest fix: give the papers ink, bundles, envelopes and varied heights, and put a few things on the desk (pen, open ledger, spectacles).
3. **Wall boards spotless and identical** (tell 3, `860 0 420 560`): one paint tone end to end with stamped black dots, no grime near the floor or the lamp. Cause: material. Cheapest fix: grime low, soot above the lamp, and tone variation board to board.
4. **Ruler-straight boards** (tell 4, `860 0 420 560`): perfect vertical rhythm. Cause: geometry. Cheapest fix: small random lean/width per board and the odd gap.
5. **No air** (tell 2, `0 0 1280 720`): nothing to catch light, so the room reads as a gray box render. Cause: light. Cheapest fix: a faint volumetric haze that only shows in the lamp's pool.

## b
- 1 Flat light: FAIL (`0 0 300 600`; `b_grey_wall.png`): flat grey fill over walls, cabinet and shelves; the window gives no beam or pool on the floor.
- 2 No atmosphere: FAIL (`270 70 200 190`; `b_blank_window.png`): no light through the window into the room, no haze.
- 3 Too clean: FAIL (`300 450 720 270`; `b_uniform_floor.png`): the floor is one glossy red-brown, no tracking, wear paths or dirt by the counter; the walls spotless.
- 4 Too straight: FAIL (`0 0 300 600`; `b_grey_wall.png`): walls, floor boards, shelves all ruler-perfect.
- 5 Floating objects: PASS (counter base meets the floor, `290 520 360 100`).
- 6 Repetition: FAIL (`700 60 340 440`; `b_bottle_grid.png`): the shelf is the same few bottle shapes and labels copied in rows, the same blue bottle every few places; a lit slab cuts through the middle shelf.
- 7 Empty: PASS (the shelving and counter are dressed, if sparsely on the counter).
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`270 70 200 190`; `b_blank_window.png`): the window is a flat beige-pink card with nothing behind it.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Window shows nothing** (tell 9, `270 70 200 190`): a flat blown-out rectangle, no street, no sky, no frame shadow. Cause: camera. Cheapest fix: let the exterior render through (or a proper exposure-matched backdrop) and throw its light onto the floor.
2. **Flat grey light** (tell 1, `0 0 300 600`): no key, the room's darks a lifted grey. Cause: light. Cheapest fix: a window shaft as the key, deeper darks away from it.
3. **Copied bottles** (tell 6, `700 60 340 440`): rows of the same few bottles and labels, plus a grey slab clipping across one shelf. Cause: dressing. Cheapest fix: vary heights, fill levels, gaps and lean, remove the stray slab.
4. **Untouched floor** (tell 3, `300 450 720 270`): even varnish everywhere, no wear in front of the counter or the door. Cause: material. Cheapest fix: a worn, dull path where feet go and dust in the corners.
5. **Perfect geometry** (tell 4, `0 0 300 600`): boards and shelves dead level. Cause: geometry. Cheapest fix: slight sag on the long shelves and per-board variation on the walls.

## c
- 1 Flat light: PASS (`200 600 400 120`): a real sun patch on the floor with a shaped shadow edge; the light has a direction.
- 2 No atmosphere: FAIL (`500 290 320 270`; `c_empty_desert.png`): the sunbeam crosses no air indoors, and outside the plain is a smooth gradient with a hard grey band at the horizon.
- 3 Too clean: FAIL (`850 0 430 650`; `c_clean_boards.png`): wall boards uniform pale paint, the corner and sill have no grime.
- 4 Too straight: FAIL (`850 0 430 650`; `c_clean_boards.png`): perfect vertical boards and frame.
- 5 Floating objects: FAIL (`500 130 320 380`; `c_floating_post.png`): the porch post hangs from the beam and stops in mid-air, nothing under it.
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 0 480 720`; `c_bare_room.png`): a bare room corner and a bare desert; nothing lives here.
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`500 290 320 270`; `c_empty_desert.png`): a flat, featureless plain to a flat mesa strip, the clouds banded in posterised steps.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Post ends in the air** (tell 5, `500 130 320 380`): the porch post visibly hangs, its foot over empty sand; a player clocks it instantly. Cause: geometry. Cheapest fix: run the post down to a footing or the porch deck.
2. **Empty, flat world outside** (tell 9, `500 290 320 270`): smooth beige plane, a cardboard grey mesa, no brush, ruts or fence. Cause: dressing. Cheapest fix: scatter scrub, rocks and a track in the near ground and haze the horizon band.
3. **Posterised sky** (tell 2, `500 90 320 210`): the clouds are stepped flat shapes, a painted leftover in a realistic frame. Cause: material. Cheapest fix: use a smooth photographic-style sky texture.
4. **Bare room** (tell 7, `0 0 480 720`): two blank walls and a floor. Cause: dressing. Cheapest fix: one or two props in the sun patch (a chair, a crate, dust on the sill).
5. **Clean, straight boards** (tells 3/4, `850 0 430 650`): perfect paint and spacing. Cause: material. Cheapest fix: grime at the sill and floor line, per-board tone variation.

## d
- 1 Flat light: PASS (`880 0 120 280`): a lamp on the sill throws warm light and long table-leg shadows across the floor; clear source.
- 2 No atmosphere: PASS (the lamp's bloom gives the room some air; thin but present).
- 3 Too clean: FAIL (`0 260 640 460`; `d_plastic_floor.png`): the floor is a saturated orange-red varnish, glossy and identical board to board, like plastic laminate; no wear or dust.
- 4 Too straight: FAIL (`290 0 300 330`; `d_straight_walls.png`): walls, doorframes and boards dead straight and evenly spaced.
- 5 Floating objects: PASS (table legs and bed meet the floor with shadow).
- 6 Repetition: PASS
- 7 Empty: PASS (exam table, washbasin, bed, lamp: the room is used, if spare).
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (the dark doorway and window read as night).
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Blue sparkles on the floor** (tell 3, `380 340 600 380`; `d_blue_sparkles.png`): cold blue specular dots scattered under and around the table, with no blue light anywhere; reads as a lighting bug. Cause: light. Cheapest fix: remove or warm whatever cool source/reflection probe is making them.
2. **Plastic-looking floor** (tell 3, `0 260 640 460`): oversaturated orange, uniform gloss, the grain like a printed pattern. Cause: material. Cheapest fix: desaturate and roughen the varnish, break the gloss with worn patches.
3. **Ruler-straight room** (tell 4, `290 0 300 330`): every board, frame and wall line perfect. Cause: geometry. Cheapest fix: small per-board variation and a slightly crooked frame.
4. **Wall paint uniform** (tell 3, `1170 260 110 460`): the pale walls carry no smoke or grime from the lamp. Cause: material. Cheapest fix: soot above the lamp, grime near the floor.
5. **Spare dressing** (tell 7, `480 260 500 200`): a doctor's room with almost no instruments, cloths or bottles out. Cause: dressing. Cheapest fix: a tray of tools and a towel on the table.

## Ranking
From least to most cheap-looking: d, c, a, b
