# Cheap judge, 2026-11-26_r1

## a
- 1 Flat light: FAIL (`300 250 400 170`, `a_base.png`): the facade is in full shadow with no shape on it, a flat blue-black slab; the sun falls only on the sand.
- 2 No atmosphere: FAIL (`610 0 300 340`, `a_backdrop.png`): the cliff behind is as crisp and saturated as the house; no haze between them.
- 3 Too clean: FAIL (`0 320 960 220`, `a_ground.png`): smooth, untouched sand right up to the walls; no ruts, tracks or dirt kick-up.
- 4 Too straight: FAIL (`300 250 400 170`, `a_base.png`): ruler-straight walls, eaves and ridge, the sign board a perfect rectangle.
- 5 Floating objects: FAIL (`300 250 400 170`, `a_base.png`): the walls meet the sand along a hard line with no contact darkening or soil build-up.
- 6 Repetition: FAIL (`0 320 960 220`, `a_ground.png`): identical little grey-green pebbles dotted evenly across the plain.
- 7 Empty: FAIL (`0 320 960 220`, `a_ground.png`): a lone house on a bare plain; no hitching post, barrels, wagon, track or fence.
- 8 Scale tells: PASS (door, windows and storeys read right for each other).
- 9 Edges of the world: FAIL (`610 0 300 340`, `a_backdrop.png`): the cliff is a flat card with a hard vertical right edge and sky showing beside it.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The cliff is a cardboard cut-out** (tell 9, `610 0 300 340`): a photo of a mesa stands on the plain with a sharp vertical edge and its own lighting. Cause: dressing. Cheapest fix: replace the card with real distant terrain, or at least fade its edges into haze and set it far back.
2. **A house with no shape in its light** (tell 1, `300 250 400 170`): the whole front is one dark, cold blue slab; no bounce from the bright sand, no edge light. Cause: light. Cheapest fix: add ground-bounce / ambient from the sand so a shadowed wall reads warm brown, not navy.
3. **Nothing round it** (tell 7, `0 320 960 220`): a saloon alone in a perfectly smooth sand field with scattered identical pebbles. Cause: dressing. Cheapest fix: wheel ruts, hoof-churned dirt, a hitching rail and a couple of barrels at the door.
4. **Walls planted, not built** (tell 5, `300 400 400 30`): a knife line where the siding meets the sand, no sill, no dirt splash, no shadow seam. Cause: geometry. Cheapest fix: a darkened, dirt-stained band and a raised boardwalk or sill at the base.
5. **The sign is blank and too white** (tell 3, `400 258 210 26`): a pale empty plank the brightest thing in the shadow, unlettered. Cause: material. Cheapest fix: letter it and darken it to sun-faded paint in shadow.

## b
- 1 Flat light: PASS (the side wall takes low raking light; the balcony throws shade).
- 2 No atmosphere: FAIL (`0 260 240 120`, `b_town.png`): the town and mesas in the distance are almost as sharp and clean as the foreground.
- 3 Too clean: FAIL (`220 380 600 80`, `b_base.png`): smooth sand to the wall foot, no wear on the stair or posts.
- 4 Too straight: FAIL (`560 150 240 300`): balcony posts and rails dead plumb and evenly spaced.
- 5 Floating objects: FAIL (`220 380 600 80`, `b_base.png`): wall and posts sit on the sand with little contact shadow; the green rocks sit on top like pebbles on a table.
- 6 Repetition: FAIL (`0 380 200 120`, `b_rocks.png`): the same smooth green blob-rock repeated.
- 7 Empty: FAIL (`0 380 200 120`, `b_rocks.png`): bare ground all round; nothing at the stair foot.
- 8 Scale tells: FAIL (`0 380 200 120`, `b_rocks.png`): the green rocks read as shrubs or toys, unclear size; the stair under the balcony looks short for the deck height.
- 9 Edges of the world: PASS (a town and mesas fill the horizon).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Lumpy green blobs on the sand** (tell 6, `0 380 200 120`): smooth, low-poly, saturated green rocks that read as placeholder bushes. Cause: dressing. Cheapest fix: swap them for proper sage/brush meshes or sandy stones in the ground's colour.
2. **Building pasted on the ground** (tell 5, `220 380 600 80`): the wall foot is a straight line on clean sand; the posts don't sink in. Cause: geometry. Cheapest fix: contact AO and a dirt band, posts set on stones.
3. **Empty sand round it** (tell 7, `0 380 960 160`): a large flat empty foreground with nothing to say people come and go. Cause: dressing. Cheapest fix: tracks, a path to the stair, crates or a woodpile under the balcony.
4. **No haze to the town** (tell 2, `0 260 240 120`): the distant buildings are crisp and cold-clean. Cause: light. Cheapest fix: warm distance fog/dust so far things soften toward the sky.
5. **Machine-straight balcony** (tell 4, `560 150 240 300`): every baluster identical and plumb. Cause: geometry. Cheapest fix: small random lean and spacing jitter on the balusters and posts.

## c
- 1 Flat light: PASS (warm lamp pools and dark corners; the light has a source).
- 2 No atmosphere: FAIL (`0 180 420 300`, `c_room.png`): the lamplight hangs in clear air; no smoke or dust haze in a saloon.
- 3 Too clean: FAIL (`0 180 420 300`, `c_room.png`): floor and walls even from end to end; no scuffs, stains or spills.
- 4 Too straight: FAIL (`0 0 960 200`): beams, joists and boards ruler-straight and evenly spaced.
- 5 Floating objects: FAIL (`290 340 360 200`, `c_table.png`): a bright hot patch under the near table with no shadow; table and chairs barely ground on the floor.
- 6 Repetition: FAIL (`100 290 300 180`): the same chair repeated round identical tables.
- 7 Empty: FAIL (`0 180 420 300`, `c_room.png`): tables bare; no glasses, bottles, cards, spittoons or pictures on the walls.
- 8 Scale tells: PASS (tables, chairs, bar and window read right).
- 9 Edges of the world: PASS (the windows show a dim outside).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A saloon with nothing in it** (tell 7, `0 180 420 300`): bare tables, bare bar, bare walls. Cause: dressing. Cheapest fix: bottles and glasses on the bar, cards and a lamp on tables, a picture or two on the walls.
2. **Light glowing up from under the table** (tell 5, `290 340 360 200`): a bright orange pool beneath the table where its shadow should be, and a blue sheen on the table top. Cause: light. Cheapest fix: make the lamp cast shadows from the table and kill the stray blue specular.
3. **Lit like a set, no air** (tell 2, `0 180 420 300`): no smoke or dust in the lamplight; corners crisp. Cause: light. Cheapest fix: a faint warm volumetric haze in the room.
4. **One chair, copied** (tell 6, `100 290 300 180`): the same slatted chair at every table, all square to the table. Cause: dressing. Cheapest fix: turn and push chairs at random, mix in a second chair model or a stool.
5. **Uniform, unworn wood** (tell 3, `540 330 420 210`): the floor is one plank texture, the same saturated red-brown everywhere, no wear path to the bar. Cause: material. Cheapest fix: a worn, darker traffic path and grime at the wall foot.

## d
- 1 Flat light: FAIL (`0 0 960 280`, `d_roof.png`): murky even red-brown everywhere; you can't tell where the light comes from.
- 2 No atmosphere: FAIL (`0 0 960 280`, `d_roof.png`): no dust in the beams of light through the roof cracks; the air is empty.
- 3 Too clean: FAIL (`260 300 440 200`, `d_floor.png`): bare boards end to end with no dust, straw or clutter.
- 4 Too straight: FAIL (`0 0 960 280`, `d_roof.png`): rafters perfectly straight and evenly spaced.
- 5 Floating objects: FAIL (`260 300 440 200`, `d_floor.png`): the hanging lamp's shadow is a detached blob on the floor; the benches sit with no contact shade.
- 6 Repetition: FAIL (`300 280 400 60`): the same bench repeated along the walls.
- 7 Empty: FAIL (`0 280 960 260`): a huge empty loft with three benches.
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`260 300 440 200`, `d_floor.png`): a dotted line of bright specks along a floor seam and slivers through the roof: light leaking through gaps in the geometry.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Light leaking through the seams** (tell 9, `260 300 440 200`): a row of bright dots along one floor joint and thin lines through the roof, reading as a broken mesh. Cause: geometry. Cheapest fix: close the gaps (overlap boards, thicken the floor/roof shell) or shadow-cast both sides.
2. **Muddy, flat colour** (tell 1, `0 0 960 280`): everything a dull red-brown, walls an odd cold blue-grey; no clear key light. Cause: light. Cheapest fix: one clear light source (a gable window shaft or the lamp) with dark falloff around it.
3. **An empty barn of a room** (tell 7, `0 280 960 260`): a cavernous space holding three benches. Cause: dressing. Cheapest fix: crates, bedrolls, sacks, a cot: whatever the room is for.
4. **Over-red, plastic floor** (tell 3, `260 300 440 200`): the boards are saturated and glossy, alternating tones like a tile. Cause: material. Cheapest fix: desaturate and roughen the floor, add dust in the corners.
5. **A lamp hanging from nothing over a smudge** (tell 5, `150 330 260 140`): the lamp's shadow sits as a soft blob not matched to it. Cause: light. Cheapest fix: let the lamp cast a proper shadow or light the room, and anchor its chain to a beam.

## Ranking
From least to most cheap-looking: c, b, a, d
