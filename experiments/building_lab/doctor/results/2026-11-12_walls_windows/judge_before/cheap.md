# Cheap judge, judge_before

## a
- 1 Flat light: FAIL (`220 200 740 300`; `a_wall_clean.jpg`): the porch roof throws no shadow on the wall and the front is lit evenly from top to bottom. The only shape comes from the lamps inside, and the low sun in the sky shows on nothing.
- 2 No atmosphere: FAIL (`0 0 1280 330`; `a_sky_edges.jpg`): a golden-hour sky with no dust or haze in front of anything. The buildings behind are as clean and flat as the house.
- 3 Too clean: FAIL (`30 470 1100 240`; `a_steps_ground.jpg`): the sand is smooth and one colour right up to the steps. No dirt, no scuffing and no worn treads. The siding is the same from end to end.
- 4 Too straight: FAIL (`220 200 740 300`; `a_wall_clean.jpg`): siding, sills and the ridge are all ruler-straight and perfectly level. Nothing sags. The one lean, on the left post, looks like a mistake rather than wear.
- 5 Floating objects: FAIL (`20 150 120 380`; `a_post_float_left.jpg`): the corner post stops short of the ground and hangs in mid-air. The steps and stringers sit on the sand with no contact shadow.
- 6 Repetition: FAIL (`20 150 120 380`; `a_post_float_left.jpg`): the grain on the post is mirrored, with the same knot pair stacked down it. The same pattern shows on the right post, and the siding repeats as one even grid.
- 7 Empty: FAIL (`30 470 1100 240`; `a_steps_ground.jpg`): the porch and yard are bare, with no chair, barrel, sign, tracks or tools. Only the desk seen through the right window says anyone uses the place.
- 8 Scale tells: PASS (door, windows and steps read as the right size for a person).
- 9 Edges of the world: FAIL (`0 0 1280 330`; `a_sky_edges.jpg`): the flanking walls are blank, untextured beige blocks, and on the right is a bare box with a notched cut-out roofline. The sky is a smeared, high-contrast orange and blue texture.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Blank placeholder buildings either side** (tell 9, `0 0 1280 330`): flat beige boxes with no texture frame the house, so it looks like a greybox level with one finished asset dropped in. Cause: geometry. Cheapest fix: give the neighbouring blocks real siding or false fronts, or hide them behind dressing and the backdrop.
2. **Porch posts hanging above the ground** (tell 5, `20 150 120 380`): both outer posts end in the air short of the sand, which is the classic "nobody checked" bug. Cause: geometry. Cheapest fix: run the posts down to the ground or a footing stone, and add a contact shadow.
3. **No shadow from the low sun** (tell 1, `220 200 740 300`): the porch roof and posts throw nothing on the wall or the deck, so the facade reads as evenly filled even though the sky says sunset. Cause: light. Cheapest fix: turn on, or strengthen, the sun's shadow on this building, and lower the ambient fill so the shade under the porch goes dark.
4. **Bare, spotless yard and porch** (tells 3 and 7, `30 470 1100 240`): uniform sand, clean treads and nothing on the porch. Cause: dressing. Cheapest fix: dark dirt and footprints at the foot of the steps and the posts, plus two or three props on the porch (a chair, a bucket, a shingle sign).
5. **Mirrored, tiled wood and a garish sky** (tell 6, `20 150 120 380`): the knot pattern on the posts repeats in mirror image, and the sky's swirled orange and blue blotches look like a filter. Cause: material. Cheapest fix: break the post UVs (offset and rotate per post), and calm the sky texture's saturation and contrast.

## b
- 1 Flat light: PASS (`0 560 860 160`; `b_floor.jpg`): a clear patch of sun lies on the floor, the room is darker than outside, and you can tell where the light comes from.
- 2 No atmosphere: FAIL (`0 560 860 160`; `b_floor.jpg`): the sunlight lands on the floor with no shaft and no dust in the air. Indoors the air reads as a vacuum. Outside, a little haze sits on the horizon.
- 3 Too clean: FAIL (`860 0 420 720`; `b_wall_clean.jpg`): the wall is one even flat grey-green, with no grime at the floor line, no scuffs and no dust in the corners. The few dark flecks are sprinkled evenly.
- 4 Too straight: FAIL (`860 0 420 720`; `b_wall_clean.jpg`): the boards are dead vertical and evenly spaced, and the window frame is a perfect rectangle. No warp, gap or sag.
- 5 Floating objects: FAIL (`490 280 330 280`; `b_post_horizon.jpg`): the porch post outside the window hangs from the roof and stops in mid-air above the ground.
- 6 Repetition: PASS (`860 0 420 720`; the board pattern varies a little and is what a board wall would be)
- 7 Empty: FAIL (`0 560 860 160`; `b_floor.jpg`): the room has nothing in it, with no furniture, nail, hook or rug. Outside is an empty plain.
- 8 Scale tells: PASS (window, boards and porch rafters agree with each other)
- 9 Edges of the world: FAIL (`490 280 330 280`; `b_post_horizon.jpg`): the plain runs flat and empty to a hard horizon line, with a flat grey cut-out mesa and a hard band at the ground's edge.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Post hanging in mid-air outside the window** (tell 5, `490 280 330 280`): it is the brightest, most central object in the frame, and it plainly doesn't reach the ground. Cause: geometry. Cheapest fix: extend the post to the ground or a footing.
2. **Flat, empty world beyond the window** (tell 9, `490 280 330 280`): a featureless sand plain, a hard horizon stripe and a cardboard mesa silhouette. It looks like the edge of a test map. Cause: geometry. Cheapest fix: put a few things in the middle distance (fence line, scrub, a shed, the town), and blend the horizon band into haze.
3. **Empty room** (tell 7, `0 560 860 160`): bare walls and a bare floor, with nothing to say this is a doctor's or anyone's room. Cause: dressing. Cheapest fix: one or two props in view (a chair or cabinet against the wall, a coat on a nail).
4. **Clean, uniform walls** (tells 3 and 4, `860 0 420 720`): the paint is even from top to bottom, and the boards are perfectly vertical and evenly gapped. Cause: material. Cheapest fix: a darker grime band at the floor and around the window sill, and a slight per-board variation in tone and a small tilt.
5. **Sunlight with no air** (tell 2, `0 560 860 160`): the sun patch on the floor is good, but no light shaft or dust connects it to the window, so the room feels sterile. Cause: light. Cheapest fix: a faint volumetric or fog shaft from the window, with a few motes.

## Ranking
From least to most cheap-looking: b, a
