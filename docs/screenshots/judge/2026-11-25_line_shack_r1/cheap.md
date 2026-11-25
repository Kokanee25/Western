# Cheap judge, 2026-11-25_line_shack_r1

## a
- 1 Flat light: PASS (`90 320 380 80` the porch throws a hard, readable shadow; the sun is clearly low left-front, and the shack's walls take it in light and shade)
- 2 No atmosphere: FAIL (`640 120 320 160`; `a_cliff_backdrop.png`): the far mesas are nearly as crisp and saturated as the shack; only a faint lift toward the horizon, no dust or heat haze
- 3 Too clean: FAIL (`0 370 960 170`; `a_bare_ground.png`): the whole foreground is one smooth tan sheet with no tracks, stones, grass tufts, ruts or drift against the walls; the board siding itself is weathered, which helps
- 4 Too straight: FAIL (`340 130 330 240`; `a_porch_contact.png`): ridge, eaves, corner posts and wall plumb and true; nothing sags or leans on a shack that is plainly meant to be old
- 5 Floating objects: FAIL (`780 270 180 80`; `a_floating_rocks.png`): the dark green boulders on the right sit on the sand like pasted ovals with only a thin smudge under them; the shack's skirting has a gravel band, the porch litter has little contact shade (`a_porch_contact.png`)
- 6 Repetition: PASS (`0 280 340 50` the yellow scrub tufts are a single repeated plant, but small and in the distance)
- 7 Empty: FAIL (`0 370 960 170`; `a_bare_ground.png`): half the frame is empty sand; outside the porch litter nothing says a man works here (no woodpile, trough, fence, horse post, trail)
- 8 Scale tells: PASS (door, porch posts and roof pitch read right for a one-room shack)
- 9 Edges of the world: FAIL (`0 200 340 130`; `a_left_town.png`): the town and the "DOCTOR" front sit a stone's throw from the shack on the same bare plain; the mesas behind read as a painted backdrop standing on the ground line
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Bare, untextured ground** (tell 3, `0 370 960 170`): the bottom third of the picture is one smooth beige gradient, like an untouched default terrain. Cause: material. Cheapest fix: a ground material with tracks, pebbles and colour breakup, plus scattered grass and stones near the shack.
2. **Nothing lived around the shack** (tell 7, `0 370 960 170`): no woodpile, path, fence, washtub or tracks; the shack is set down on a blank plain. Cause: dressing. Cheapest fix: a worn footpath to the door and a woodpile against the side wall.
3. **Boulders pasted on the sand** (tell 5, `780 270 180 80`): dark, glossy green ovals with no seating or contact shade, like placeholder primitives. Cause: geometry. Cheapest fix: sink them into the ground and give them rock material instead of the green tint.
4. **Postcard-sharp mesas** (tell 2, `640 120 320 160`): the far cliffs are as crisp and red as the near wall, so the distance reads as a picture, not miles of air. Cause: light. Cheapest fix: stronger aerial haze/desaturation with distance.
5. **Ruler-straight old shack** (tell 4, `340 130 330 240`): ridge and walls dead level and plumb; weathered boards on a perfect frame look like a new set. Cause: geometry. Cheapest fix: a slight sag in the ridge and porch roof, one corner settled.

## b
- 1 Flat light: PASS (`480 310 300 60` a clear cast shadow; lit and shaded walls)
- 2 No atmosphere: FAIL (`0 0 500 270`; `b_backdrop_seam.png`): the cliff wall is pin-sharp and fully saturated right to its top
- 3 Too clean: FAIL (`0 260 960 280`; `b_empty_ground.png`): an unbroken tan floor; no dirt or drift where the walls meet the ground
- 4 Too straight: FAIL (`260 120 400 260`; `b_clean_walls.png`): two boxy volumes, dead-straight eaves and boards, the roof a flat plane
- 5 Floating objects: FAIL (`600 220 360 90`; `b_dome_horizon.png`): the small green rocks dot the sand with no seating; the leaning stick at the lean-to end pokes into nothing
- 6 Repetition: FAIL (`0 260 960 280`; `b_empty_ground.png`): the same little green rock repeated evenly across the plain
- 7 Empty: FAIL (`0 260 960 280`; `b_empty_ground.png`): nothing but the shack and sand; no door or window on these two walls, no sign of use
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 0 500 270`; `b_backdrop_seam.png`): the mesa is a flat picture card that stops with a hard vertical edge at x≈485, blue sky beside it; the right side is smooth sand domes against a clean horizon
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Backdrop card cut off mid-cliff** (tell 9, `0 0 500 270`): the red mountain ends in a straight vertical edge in open sky; it reads at once as a photo pasted on a board. Cause: geometry. Cheapest fix: extend or wrap the backdrop so no edge is in view from here (or end it behind a ridge).
2. **Empty plain with dotted rocks** (tells 6/7, `0 260 960 280`): flat sand with one identical green pebble sprinkled evenly; nothing else. Cause: dressing. Cheapest fix: vary rocks (size, colour, clusters) and add brush, tracks and ground breakup.
3. **Blank walls, box massing** (tell 4, `260 120 400 260`): two windowless walls, all straight lines; reads like a blockout. Cause: geometry. Cheapest fix: a window or stovepipe on this side, and a slight sag.
4. **No air in the distance** (tell 2, `0 0 500 270`): the cliffs are as sharp as the shack. Cause: light. Cheapest fix: distance haze over the backdrop.
5. **No ground contact on the shack** (tell 3, `270 330 360 50`): the wall bottoms meet the sand with a clean line and no dirt kicked up. Cause: material. Cheapest fix: a dark grime band and blown sand at the foot of the walls.

## c
- 1 Flat light: FAIL (`0 0 960 330`; `c_flat_walls.png`): the room is evenly lit from every side, blacks lifted grey; you cannot tell whether the light is the window, the lamp or the stove
- 2 No atmosphere: FAIL (`300 230 220 250`; `c_table.png`): the lamp is unlit and there is no dust, smoke or glow in the air; the room has no depth falloff
- 3 Too clean: PASS (`0 360 960 180` the floor boards and walls are well worn and stained)
- 4 Too straight: FAIL (`0 0 960 330`; `c_flat_walls.png`): rafters, studs and braces all crisp and evenly spaced; the beds are perfectly square and tidy
- 5 Floating objects: FAIL (`600 300 360 240`; `c_bed_artefact.png`): the bed's frame cuts through the blanket in jagged triangles, and the bed and benches have little contact shade on the floor
- 6 Repetition: FAIL (`0 360 300 180`; `c_bed_left.png`): two identical beds, two identical coat-and-hat pegs on opposite walls, mirrored
- 7 Empty: PASS (`300 230 220 250` table with bottles, lamp, stove, coats; it reads as used)
- 8 Scale tells: PASS (bunks, table and benches sized right)
- 9 Edges of the world: PASS (`200 60 400 80` bright gaps at the eaves read as a real gappy roof)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Flat, sourceless interior light** (tell 1, `0 0 960 330`): every wall is the same brightness; the shack interior looks lit by a studio fill, not a window and a lamp. Cause: light. Cheapest fix: drop the ambient fill so the room is dark except where window/door light falls.
2. **Bed frame poking through the blanket** (tell 5, `600 300 360 240`): saw-tooth holes along the blanket's edge where the wood shows through; an instant "game bug" tell. Cause: geometry. Cheapest fix: push the blanket mesh out (or the rail in) so they don't intersect.
3. **Mirrored, duplicated furniture** (tell 6, `0 360 300 180`): same bed, same coat and hat on both sides; reads as copy-paste. Cause: dressing. Cheapest fix: a rumpled blanket and different gear on one bunk, one peg empty.
4. **No air** (tell 2, `300 230 220 250`): no lamp glow, no dust in the light, no stove haze. Cause: light. Cheapest fix: dust motes or volumetric shafts from the eave gaps and door.
5. **Perfect carpentry** (tell 4, `0 0 960 330`): every rafter and stud dead straight and regularly spaced; the sharp wall texture repeats board to board. Cause: geometry. Cheapest fix: small random twists and offsets on the framing members.

## d
- 1 Flat light: PASS (`330 330 220 120` the door throws a bright wedge across the floor; the far corners fall off into shadow)
- 2 No atmosphere: FAIL (`380 160 120 180`; `d_door_view.png`): the doorway shows a clean, sharp outdoors and the sunlit wedge has no dust in it
- 3 Too clean: PASS (worn floor, stained boards, dark table top)
- 4 Too straight: FAIL (`0 60 960 200`; `d_walls_roof.png`): rafters and wall framing perfectly regular; neatly made beds
- 5 Floating objects: FAIL (`450 280 400 260`; `d_table_dark.png`): the bench and table legs show little contact shadow on the floor; the bench seems to hover
- 6 Repetition: FAIL (`140 240 400 220` the two identical bunks with identical pillows, and the coat-and-hat pegs again at both sides)
- 7 Empty: PASS (table set with bottles and lamp, coats, bunks)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (`380 160 120 180` the view out the door carries on into the desert)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Duplicated bunks and pegs** (tell 6, `140 240 400 220`): two matching beds with matching pillows, two matching coat pegs; set-dressed by copy. Cause: dressing. Cheapest fix: vary one bunk (rumpled, a bedroll, boots under it).
2. **Benches and table not grounded** (tell 5, `450 280 400 260`): the green bench and table legs meet the floor without a shadow, so they look placed rather than standing. Cause: light. Cheapest fix: stronger ambient occlusion/contact shadows on furniture.
3. **Dry, dustless sunbeam** (tell 2, `380 160 120 180`): a bright door wedge with no dust in the air; the room feels vacuum-clean. Cause: light. Cheapest fix: a light volumetric haze so the door light shows as a shaft.
4. **Regular framing** (tell 4, `0 60 960 200`): rafters perfectly parallel and evenly spaced, a showroom-built shack. Cause: geometry. Cheapest fix: jitter member angles and spacing a little.
5. **Hard eave-light triangles** (tell 9, `250 60 400 80`): the little blue triangles of sky along the top plate are evenly spaced and identical, so they read as a modelling gap rather than weathered boards. Cause: geometry. Cheapest fix: vary the gaps or fill most of them, leaving a few irregular chinks.

## Ranking
From least to most cheap-looking: d, a, c, b
