# Cheap judge, 2026-11-14_saloon_b_stage_r1

## a
- 1 Flat light: FAIL (`880 180 400 360`; `a_a_right_wall.png`): the curtain and the wall lamp at left have real light, but the big right-hand walls are one even beige wash with no lamp near them and no falloff from top to bottom. You can't say what lights them.
- 2 No atmosphere: FAIL (`400 380 490 140`; `a_a_footlights.png`): the footlights and the sconce make glow spots on surfaces, but the air between them has no haze, smoke or dust. The room reads as a vacuum lit at night.
- 3 Too clean: FAIL (`0 440 1280 280`; `a_a_empty_floor.png`): a big dance floor with no scuffs, no worn path to the stage, no dirt in the corners or along the stage base. Only the board tones vary.
- 4 Too straight: FAIL (`400 200 490 320`, the stage box; `a_a_footlights.png`): the proscenium is a perfect black rectangle, the stage front a flat box with ruled lines, the walls dead plumb and the beams dead level. Nothing has settled.
- 5 Floating objects: PASS (`400 500 490 20`): the stage front, the rail posts and the partition walls sit on the floor with some contact darkening, and the partition casts a shadow onto the boards.
- 6 Repetition: FAIL (`880 180 400 360`; `a_a_right_wall.png`): every wall has the same board texture with the same scatter of pale speckles, at the same density from one end of the room to the other. They look like a noise pattern, not paint wear.
- 7 Empty: FAIL (`0 440 1280 280`; `a_a_empty_floor.png`): a stage with nothing on it and a hall with no chairs, tables, piano, spittoons or bottles. Nobody uses this room.
- 8 Scale tells: FAIL (`400 380 490 140`; `a_a_footlights.png`): the five footlights are the size of buckets beside the stage, and the stage lip is so low and so thick that the stage reads more as a box on the floor than as a raised platform.
- 9 Edges of the world: FAIL (`1210 240 70 260`; `a_a_window.png`): the window shows a dark olive smudge, with no street, no sky shape and no reflection. Outside does not exist.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **An empty hall** (tell 7, `0 440 1280 280`): the first thing you notice is half a screen of bare floor in front of an empty stage. It looks like a level waiting for its dressing pass. Cause: dressing. Cheapest fix: put chairs and a few round tables, a piano at stage left and some clutter (bottles, a coat on a chair) on the floor.
2. **Speckled flat walls** (tell 6 and 1, `880 180 400 360`): the large wall planes are one flat tone covered in a regular confetti of pale specks. They read as a tiled noise texture and show the leftover squares at the edge of the boards. Cause: material. Cheapest fix: replace the uniform speckle with wear that follows the boards (darker near the floor and around the door frames, lighter at head height) and let the walls fall off into darkness away from the lamps.
3. **The window to nowhere** (tell 9, `1210 240 70 260`): a murky green blur where the night street should be. Cause: dressing. Cheapest fix: a dark blue night exterior with one warm window across the street, or a pulled-down blind.
4. **Toy stage** (tell 8 and 4, `400 200 490 320`): the curtain is a set of evenly spaced bright red ridges with a sawtooth gold hem, set in a perfectly square black frame, with oversized bucket footlights. It reads as a playset. Cause: geometry. Cheapest fix: drape the curtain with uneven folds and a swag at the top, add a valance, and shrink the footlights to shallow tin reflectors.
5. **Lamplight with no air** (tell 2, `260 280 80 120`): the sconce makes a clean disc on the wall but does nothing to the air. Cause: light. Cheapest fix: a faint volumetric haze (tobacco smoke) that catches the footlights and the sconces.

## b
- 1 Flat light: FAIL (`470 230 350 190`; `b_backdrop.png`): the painted drop is lit evenly from corner to corner, with no brighter band from the footlights below and no shadow from the side curtains. It looks pasted on. The right walls are a flat wash as in a (`b_right_wall.png`).
- 2 No atmosphere: FAIL (`400 380 490 140`; `b_footlights.png`): bright footlights, but no glow in the air in front of the drop and no smoke under the rafters.
- 3 Too clean: FAIL (`0 440 1280 280`; `b_empty_floor.png`): unmarked boards with no wear path and no dirt along the stage front.
- 4 Too straight: FAIL (`400 200 490 320`, the stage box; `b_footlights.png`): a ruler-straight proscenium, ruler-straight curtain legs and a drop hung perfectly square.
- 5 Floating objects: PASS (`400 500 490 20`): the stage, the rail and the partitions meet the floor with contact shade.
- 6 Repetition: FAIL (`880 180 400 360`; `b_right_wall.png`): the same speckled board texture on every wall plane.
- 7 Empty: FAIL (`0 440 1280 280`; `b_empty_floor.png`): the drop says "show tonight", but the room has no seats, no tables and no bar clutter.
- 8 Scale tells: FAIL (`400 380 490 140`; `b_footlights.png`): the bucket-sized footlights, and a stage too shallow for the large drop behind it.
- 9 Edges of the world: FAIL (`1210 240 70 260`; `b_window.png`): the same green-smudge window.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **An empty hall** (tell 7, `0 440 1280 280`): the drop sets up a performance space, and the bare floor in front of it undercuts it. Cause: dressing. Cheapest fix: rows of mismatched chairs and a couple of tables facing the stage.
2. **A backdrop that looks pasted on** (tell 1, `470 230 350 190`): the painting is the best thing in the shot and reads as period-correct. But it is lit flat, a little softer than the surrounding geometry, and has no shadow from the curtains or the frame, so it looks like a decal. Cause: light. Cheapest fix: let the footlights light it from below (bright bottom edge, falling off toward the top) and let the curtain legs cast a shadow on its edges.
3. **Speckled flat walls** (tell 6, `880 180 400 360`): the same confetti-speckle walls as in a, with no lamp to shape them. Cause: material. Cheapest fix: board wear that follows the boards, plus darkness away from the lamps.
4. **Toy stage parts** (tell 8, `400 380 490 140`): the oversized footlight buckets and the plain box front, with ruled lines across it. Cause: geometry. Cheapest fix: low tin reflectors and a stage front with planking, a skirt or bunting.
5. **The window to nowhere** (tell 9, `1210 240 70 260`): a featureless smudge outside. Cause: dressing. Cheapest fix: a night exterior or a blind.

## c
- 1 Flat light: FAIL (`1130 170 150 340`; `c_right_rail.png`): the near right wall is lit bright and even top to bottom with no visible source. The rest of the frame has decent pools and dark corners (the far sconce, the black rafters).
- 2 No atmosphere: FAIL (`500 280 600 160`; `c_far_room.png`): a long room at night with no haze in the depth. The far wall and its sconce are as crisp as the near panel.
- 3 Too clean: FAIL (`0 200 520 520`; `c_panel_stairs.png`): the stair treads and the big panel look freshly varnished. There is no wear on the step noses and no scuffing where feet go.
- 4 Too straight: FAIL (`500 400 640 320`; `c_empty_floor.png`): long dead-straight boards, a dead-level beam line and a perfectly regular railing. Nothing in the old building has settled.
- 5 Floating objects: FAIL (`260 620 120 100`; `c_glow.png`): bright light orbs hang at the edge of the panel with no lamp or fixture around them. They read as lights left floating in space.
- 6 Repetition: FAIL (`1130 170 150 340`; `c_right_rail.png`): the same speckled board texture as the far walls, and a dark post behind the rail made of noisy leftover squares.
- 7 Empty: FAIL (`500 400 640 320`; `c_empty_floor.png`): a huge bare floor and bare walls. The only things in the room are the doors and one lamp.
- 8 Scale tells: FAIL (`0 200 330 520`; `c_panel_stairs.png`): the wood grain on the near panel is huge, with swirls as big as a man's forearm, like printed plywood veneer blown up. It makes the panel feel like a toy block.
- 9 Edges of the world: FAIL (`880 300 120 120`; `c_doorway.png`): through the doors there is a balcony rail, then a flat dark brown plain and a band of sky. That is an empty horizon where a street and buildings should be.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Plywood clip-art panel** (tell 8, `0 200 330 520`): the closest, largest surface in the frame has wildly oversized, cartoon-smooth grain. It is the most "asset flip" thing in all three pictures. Cause: material. Cheapest fix: scale the grain down 4 to 6 times, break it into vertical boards with seams, and dull the varnish.
2. **An empty hall** (tell 7, `500 400 640 320`): a great dark floor with nothing on it, which makes the space feel unfinished. Cause: dressing. Cheapest fix: tables and chairs, a few crates or barrels by the stage stairs, and a coat hook with something hung on it.
3. **Floating light orbs** (tell 5, `260 620 120 100`): glowing balls with no fixture, sitting at the panel's edge. Cause: light. Cheapest fix: give each light a visible candle, lamp or footlight housing, or remove the stray glows.
4. **An empty world through the doors** (tell 9, `880 300 120 120`): a flat dark plain past the balcony. Cause: dressing. Cheapest fix: put the street's facades and a lit window or two beyond the balcony.
5. **A sourceless bright wall** (tell 1, `1130 170 150 340`): the right wall glows evenly next to a black, noisy post. Cause: light. Cheapest fix: drop the wall's fill so that it falls to shadow, or hang a sconce on it that explains the light.

## Ranking
From least to most cheap-looking: b, a, c
