# Cheap judge, cheap

## a
- 1 Flat light: PASS (a light pool lies on the floor at top left, posts cast shadows, the stairwell falls into dark; the light has a direction)
- 2 No atmosphere: FAIL (`0 0 600 220`, `a_floor_lightpool.png`): the window light sits on the floor as a decal with no shaft or dust in the air; the room reads airless
- 3 Too clean: FAIL (`0 560 1280 160`, `a_floor_tiling.png`): the floorboards are glossy, varnished-looking planks with no scuffs, grit, tracked mud or wear paths, even at the head of the stairs where feet would go
- 4 Too straight: FAIL (`0 560 1280 160`, `a_floor_tiling.png`): every board is the same width, dead level and evenly spaced, with nothing cupped, warped or gapped
- 5 Floating objects: PASS (posts and the stair rail meet the floor with some darkening; hard to fault from this angle)
- 6 Repetition: FAIL (`760 220 400 300`, `a_floor_empty.png`): the same grain swirls and pale blotch come back board after board across the floor
- 7 Empty: FAIL (`760 220 400 300`, `a_floor_empty.png`): a big upper floor with nothing on it: no crate, coffin, tool or rug; only bare boards
- 8 Scale tells: PASS (the stair, rail and posts look right for each other)
- 9 Edges of the world: PASS (an interior; walls close the room)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A vast bare floor** (tell 7, `760 220 400 300`): two thirds of the picture is empty planking with nothing to say anyone works here. Cause: dressing. Cheapest fix: put a few working things on the floor (a coffin on trestles, planks, a sawhorse, sawdust).
2. **Shiny, unworn boards** (tell 3, `0 560 1280 160`): the floor looks freshly varnished, glossy grain on every plank, no dirt by the stairs or walls. Cause: material. Cheapest fix: drop the floor's sheen and add a grime/wear mask darkest along the walls and the traffic path to the stairs.
3. **The grain repeats** (tell 6, `760 220 400 300`): the same knot swirls and light blotches recur plank to plank, so the floor reads as one tile laid over and over. Cause: material. Cheapest fix: randomise the texture offset and tint per board.
4. **Ruler-straight planking** (tell 4, `0 560 1280 160`): identical widths, perfect level, perfect gaps. Cause: geometry. Cheapest fix: vary board widths and add slight height and gap jitter per board.
5. **Blocky, pixelated cellar floor below the stairs** (tell 3, `560 170 220 230`, `a_stair_well.png`): the stone below shows leftover square blotches and a thin bright seam line down the middle, which looks like a texture bug, not a floor. Cause: material. Cheapest fix: replace the blocky blotch texture with a smooth stone/dirt one and close the seam.

## b
- 1 Flat light: PASS (one wall lamp lights its corner warmly and the room falls off into real darkness; the light has a source)
- 2 No atmosphere: FAIL (`880 180 140 120` around the lamp): the lamp glows with no haze or bloom of air around it; the dark is just black, not smoky lamplit air
- 3 Too clean: FAIL (`540 450 520 270`, `b_floor_tiles.png`): the floor tiles carry pixelated square blotches that read as leftover low-res squares, not real dirt; tables and walls show no wear
- 4 Too straight: FAIL (`340 180 450 220`, `b_back_rooms.png`): partition walls, beams and tile grid are all ruler-true; nothing sags
- 5 Floating objects: FAIL (`440 390 520 230`, `b_table_float.png`): the table legs stand on the tiles with no contact shadow, so the table looks set on top of the picture
- 6 Repetition: FAIL (`540 450 520 270`, `b_floor_tiles.png`): every floor tile carries the same mottled blotch pattern; the two tables are the same plain table
- 7 Empty: FAIL (`340 180 450 220`, `b_back_rooms.png`): an undertaker's back room with two bare tables and nothing on them: no body, sheet, tools, bottles or coffins
- 8 Scale tells: PASS (rooms, doorways and tables look right for a person)
- 9 Edges of the world: PASS (interior, closed)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Nothing in the room** (tell 7, `340 180 450 220`): bare tables and empty stalls; for a place where bodies are laid out, there is no sign of use at all. Cause: dressing. Cheapest fix: a sheeted body or a coffin on the near table, tools and a basin beside it.
2. **Leftover squares on the floor** (tell 3, `540 450 520 270`): the tile blotches are visibly made of square pixels, a cheap low-res texture against otherwise smooth light. Cause: material. Cheapest fix: a higher-res, smooth stained-stone texture for the floor.
3. **Table with no contact** (tell 5, `440 390 520 230`): legs just touch the tiles with no shadow or darkening, so the table floats. Cause: light. Cheapest fix: let the lamp cast shadows from the table, or add ambient occlusion under furniture.
4. **Crushed black left third** (tell 2, `0 0 380 720`, `b_black_left.png`): a third of the frame is solid black with no air or bounce light, reading as unlit rather than dark. Cause: light. Cheapest fix: a faint warm bounce/fog so the near wall's shape just reads.
5. **Same tile, same table** (tell 6, `540 450 520 270`): the identical blotch on every tile and two copies of the same table make the room look assembled from a kit. Cause: material. Cheapest fix: rotate/offset the tile texture per tile and vary the second table.

## Ranking
From least to most cheap-looking: a, b
