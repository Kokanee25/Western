# Cheap judge, 2026-11-26_line_shack_r2

## a
- 1 Flat light: FAIL (`0 0 960 540`; whole room evenly lit, no light pool or shadow shape, no source readable; no sun through the roof gaps. See a_table.png)
- 2 No atmosphere: FAIL (`300 60 360 300`; no dust or beams in the air, the back doorway is a dim plain blue; a_table.png)
- 3 Too clean: PASS (`0 0 960 540`; walls and floor are weathered, grained and stained, tin cup and bottles have some grime)
- 4 Too straight: FAIL (`620 230 340 200`; bunk rails, rafters and table are dead straight and square, nothing sags or leans; a_bunk.png)
- 5 Floating objects: FAIL (`300 270 200 230`; table legs and the bench have no contact shadow on the floor, and the bench and the stove base look pasted on; a_table.png)
- 6 Repetition: FAIL (`0 80 960 300`; the same wall plank texture tiles across every wall with visible repeating knots, the dotted white seam lines in the floor repeat; a_table.png)
- 7 Empty: PASS (`300 220 160 130`; table has bottles, lamp, cup, coats on pegs, bedrolls, stove: it reads as lived in, if sparse)
- 8 Scale tells: PASS (`300 270 200 230`; the bench is small and spindly beside the table but plausible)
- 9 Edges of the world: PASS (`440 180 80 150`; the back doorway shows a small blue patch, and bright pinholes in the roof edge read as gaps, but it is acceptable)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Flat, source-less light** (tell 1, `0 0 960 540`): everything is the same mid-brown with weak shadows, so the room has no mood. Cause: light. Cheapest fix: one hard sun shaft through a wall gap with a real shadow, and darken the corners.
2. **Props float, no contact shadow** (tell 5, `300 270 200 230`): table legs, bench and stove sit on the floor with no darkening where they touch it. Cause: light. Cheapest fix: add ambient occlusion or a blob contact shadow under legs and feet.
3. **Repeated wall and floor texture, white dotted seams** (tell 6, `300 330 150 200`): the same plank tile repeats, and thin white dashed lines run down the floor like a road marking. Cause: material. Cheapest fix: fix the floor seam gaps and vary the tile with a macro dirt mask.
4. **Too square** (tell 4, `620 230 340 200`): bunk, rafters and rails are perfect and uniform, with no sag or warp. Cause: geometry. Cheapest fix: jitter the rotation and length of the members a degree or two and sag the bedroll.
5. **No air** (tell 2, `300 60 360 300`): no dust motes or haze, and the doorway to the outside is a flat blue. Cause: light. Cheapest fix: a faint volumetric fog with dust in the light shaft.

## b
- 1 Flat light: PASS (`330 320 200 140`; a real sun patch falls through the door onto the floor with a hard edge, and the corners go dark)
- 2 No atmosphere: FAIL (`380 170 140 160`; the doorway shows a flat beige plain with no haze, and no dust in the shaft; b_floor.png)
- 3 Too clean: PASS (`330 320 400 220`; floor boards are dirty and stained, walls are weathered)
- 4 Too straight: FAIL (`120 190 230 290`; the bunk frame, its timbers and the rafters are dead straight and evenly spaced; b_bunk.png)
- 5 Floating objects: FAIL (`380 320 260 220`; the bench in the floor lacks contact shadow and looks decal-like and flattened on the boards, the table legs are weakly grounded; the bedroll at the bottom-left rests with no shadow; b_floor.png)
- 6 Repetition: FAIL (`330 320 400 220`; the wall plank tile repeats, and the dashed white floor seam lines recur; b_floor.png)
- 7 Empty: PASS (`500 270 330 160`; plate, cards, bottle, lamp, coats and bedrolls give use, though thin)
- 8 Scale tells: PASS (`120 190 230 290`; the bunk is a little short and narrow, plausible overall)
- 9 Edges of the world: FAIL (`400 170 130 170`; the outside through the door is a smooth featureless beige plane with a lone rock and a pasted strip of red cliff: it reads as a backdrop; b_floor.png)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Door view is a flat backdrop** (tell 9, `400 170 130 170`): a bare beige plane, one dark rock, a strip of cliff; it looks pasted. Cause: geometry. Cheapest fix: add haze, a horizon gradient and a few mid-distance shapes beyond the door.
2. **Bench and table do not sit in the floor** (tell 5, `380 320 260 220`): the bench looks like a flat decal with floating rails, and legs have no contact darkening. Cause: geometry. Cheapest fix: add a contact shadow, and rebuild the bench's slab to sit on the boards.
3. **White dashed seam lines in the floor** (tell 6, `330 330 80 210`): bright dotted lines look like a road marking or texture error. Cause: material. Cheapest fix: close the plank gaps or darken the seam.
4. **Bunk and rafters perfectly straight** (tell 4, `120 190 230 290`): rails and posts are regular, and the bedroll is a clean tube. Cause: geometry. Cheapest fix: add per-member tilt and a sagging bedroll.
5. **No dust in the sun shaft** (tell 2, `330 320 200 140`): the hard sun patch is not backed by any air, so the light reads as a cutout. Cause: light. Cheapest fix: soft dust haze in the shaft.

## Ranking
From least to most cheap-looking: b, a
