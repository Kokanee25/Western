# Cheap judge, 2026-11-12_doctor_light_r2

## a
- 1 Flat light: FAIL (`0 0 640 360`; `cut a_flat_wall.png`): an even grey-green fill over walls and desk; no window shaft, no lamp pool, the wall lamp at top right is dark; you can't say where the light comes from.
- 2 No atmosphere: FAIL (`0 0 640 360`; `cut a_flat_wall.png`): the room's air is empty; no dust, no haze, no fall-off into the corners beyond a uniform darkening.
- 3 Too clean: FAIL (`380 180 560 320`; `cut a_desk_clean.png`): the desk's varnish is one even procedural grain from top to plinth, no worn edges on the drawer fronts or the roll, no rings or ink on the blotter.
- 4 Too straight: FAIL (`0 0 1280 300`; `cut a_straight_boards.png`): the wall boards are ruler-straight and evenly spaced, same width, same seam; nothing warps or gaps.
- 5 Floating objects: PASS (`380 500 300 220`): the desk's foot and the chair sit in darker floor; reads as on the ground.
- 6 Repetition: PASS (`0 0 1280 720`): the board pattern is regular but not an obvious tile; the dark specks vary.
- 7 Empty: FAIL (`520 340 320 160`; `cut a_empty_desk.png`): a doctor's desk with two inkwells and a few white slips in the pigeonholes; no books, papers, pen, lamp, anything personal.
- 8 Scale tells: PASS (`300 180 640 540`): desk, drawers, pulls and chair read at a plausible size together.
- 9 Edges of the world: FAIL (`1200 220 80 220`; `cut a_window_blocks.png`): the window at the right edge shows flat blue blocks with stripe lines, not a view.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Flat, sourceless light** (tell 1, `0 0 640 360`): the whole room sits in a dull grey-green with no light pool and the wall lamp unlit; it looks like ambient light only. Cause: light. Cheapest fix: light the wall lamp (or let a window shaft in) so the desk has a lit side and a cast shadow on the wall.
2. **The desk is a clean showroom piece** (tell 3, `380 180 560 320`): one uniform red-brown grain with no handling wear, no darkened edges, no dust on top. Cause: material. Cheapest fix: an edge-wear and grime mask (lighter worn edges on the roll and drawer fronts, darker in the corners).
3. **Nothing on the desk** (tell 7, `520 340 320 160`): a working doctor's desk with only two inkwells reads as placed, not used. Cause: dressing. Cheapest fix: a scatter of papers, an open book and a pen on the blotter.
4. **Ruler-straight wall boards** (tell 4, `0 0 1280 300`): every board the same width and dead vertical, seams identical. Cause: geometry. Cheapest fix: vary board widths and add a slight gap/warp per board.
5. **The window shows flat blue blocks** (tell 9, `1200 220 80 220`): a glimpse outside is a striped blue panel, not a world. Cause: geometry. Cheapest fix: make the window show the real exterior (or frosted glass with outdoor light coming through).

## b
- 1 Flat light: FAIL (`0 380 700 340`; `cut b_flat_floor.png`): the window glows but throws no light on the floor or counter; the room is one even dim grey.
- 2 No atmosphere: FAIL (`270 70 200 190`; `cut b_blank_window.png`): a bright window in a dark room with no shaft, haze or bloom around it.
- 3 Too clean: FAIL (`0 380 700 340`; `cut b_flat_floor.png`): the floor boards are a uniform clean varnish with no traffic path in front of the counter or shelves.
- 4 Too straight: PASS (`690 60 360 420`): the shelf bottles are scattered and the shelving is plausibly built; not perfectly even.
- 5 Floating objects: PASS (`290 340 360 300`): the counter and shelving sit into darker floor.
- 6 Repetition: FAIL (`690 60 360 420`; `cut b_bottle_rows.png`): a few bottle shapes and one label repeated down every shelf; reads as copy-paste up close.
- 7 Empty: FAIL (`200 300 460 140`; `cut b_sparse_counter.png`): the long counter holds a mortar, a balance and a few bottles at one end; the rest of the room is bare floor.
- 8 Scale tells: PASS (`280 60 780 500`): window, counter, shelving and bottles sized right for each other.
- 9 Edges of the world: FAIL (`270 70 200 190`; `cut b_blank_window.png`): the window is a flat beige rectangle with nothing beyond it.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The window is a blank beige card** (tell 9, `270 70 200 190`): the brightest thing in the shot is a featureless panel; a player instantly reads "no outside". Cause: geometry. Cheapest fix: render the real exterior through the glass, or put a dirty pane/curtain over it.
2. **The window lights nothing** (tell 1, `0 380 700 340`): no sun patch or bounce on the floor and counter under a bright window; the room is evenly dim. Cause: light. Cheapest fix: let the window cast a light patch across the floor and counter.
3. **Copy-paste bottles** (tell 6, `690 60 360 420`): the same three bottle shapes and identical labels in rows down the shelving. Cause: dressing. Cheapest fix: vary bottle size, fill level, label and tilt per bottle, with gaps and a few lying down.
4. **No air** (tell 2, `270 70 200 190`): a bright opening in a dark room with no dust in the light. Cause: light. Cheapest fix: a faint volumetric shaft from the window.
5. **A bare dispensary** (tell 7, `200 300 460 140`): the counter is mostly empty and the floor has nothing on it; no crates, rags, stool, papers. Cause: dressing. Cheapest fix: a stool, a crate of bottles on the floor and clutter along the counter.

## c
- 1 Flat light: PASS (`200 600 400 120`): a warm sun patch on the floor and a lit wall/shadowed jamb give a clear direction.
- 2 No atmosphere: PASS (`480 280 340 280`): the distance does fade into a grey haze band; there is some air.
- 3 Too clean: FAIL (`840 0 440 620`; `cut c_clean_wall.png`): the inside wall is one even pale grey from floor to ceiling, a few specks only; no dirt at the base, no wear by the window.
- 4 Too straight: PASS (`540 140 80 380`): the outside post is weathered and the porch boards vary; the inside boards are straight but acceptable.
- 5 Floating objects: FAIL (`540 140 80 380`; `cut c_floating_post.png`): the porch post stops in mid-air above the sand; nothing under it, no footing, no shadow.
- 6 Repetition: PASS (`0 0 1280 720`): no visible tile.
- 7 Empty: FAIL (`480 280 340 280`; `cut c_empty_horizon.png`): out the window is a bare flat plain; no road, fence, building, plant or any sign of a town.
- 8 Scale tells: PASS (`480 0 360 620`): window, post and porch read at right scale.
- 9 Edges of the world: FAIL (`480 280 340 280`; `cut c_empty_horizon.png`): a flat sand plane to a straight horizon with one grey cut-out mesa; the world ends at the porch.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The world outside is an empty plane** (tell 9, `480 280 340 280`): a ruler-flat beige floor to a straight horizon and a single flat mesa silhouette; it looks like a default scene. Cause: geometry. Cheapest fix: ground with relief and scrub, a road or fence line, and layered distant hills.
2. **The porch post hangs in the air** (tell 5, `540 140 80 380`): the post ends well above the sand with no deck or footing under it. Cause: geometry. Cheapest fix: bring the porch deck (or the post) down to the ground with a footing.
3. **Nothing lives out there** (tell 7, `480 280 340 280`): no sign of a street, neighbour or any use. Cause: dressing. Cheapest fix: put the town (a facade, a hitch rail, a wagon) in the window's view.
4. **Painted, posterised clouds** (tell 2, `480 80 340 220`; `cut c_painted_clouds.png`): the sky reads as banded flat-colour strokes, a painted toy finish against the realistic room. Cause: material. Cheapest fix: a smooth photographic/volumetric sky texture.
5. **The inside wall is uniformly clean** (tell 3, `840 0 440 620`): even pale paint with no grime at the skirting or around the window. Cause: material. Cheapest fix: a grime gradient low on the wall and darkening around the frame.

## d
- 1 Flat light: PASS (`480 260 700 400`): the lamp throws a clear warm key with long hard shadows of the table legs across the floor; the light has shape.
- 2 No atmosphere: PASS (`860 20 160 260`): a glow and bloom around the lamp, the room falling into dark; some air, though no visible haze.
- 3 Too clean: FAIL (`0 380 900 340`; `cut d_plastic_floor.png`): the floor is one saturated orange-red glossy grain, like laminate, with no scuffs, dirt or traffic wear; the shadow edges show stepped blocks.
- 4 Too straight: PASS (`0 0 1280 720`): the posts and frames lean slightly with the lens; boards vary.
- 5 Floating objects: PASS (`480 260 500 380`): the table legs cast and meet their shadows.
- 6 Repetition: PASS (`0 0 1280 720`): no visible repeats.
- 7 Empty: PASS (`0 180 300 260`): a bed, basin and pitcher, an exam table and a lamp on the sill; the room reads as used, if sparse.
- 8 Scale tells: PASS (`480 260 500 380`): the exam table, bed and doors are in scale.
- 9 Edges of the world: PASS (`760 0 480 320`): the windows are dark night with a reflection; believable.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The floor reads as orange plastic** (tell 3, `0 380 900 340`): the boards are oversaturated red with an even gloss and loud, repeating grain; no dirt or worn path. Cause: material. Cheapest fix: desaturate and roughen the floor, with a worn, darker traffic path.
2. **Blocky shadow edges** (tell 1, `0 380 900 340`): the leg and table shadows on the floor break into stepped squares close up. Cause: light. Cheapest fix: a higher shadow resolution or softer filtering for the lamp's shadow.
3. **The exam table's cushion is a lumpy blob** (tell 3, `480 260 500 200`; `cut d_lumpy_table.png`): the leather pad is a smooth dark mass with no seams, buttons or wear. Cause: material. Cheapest fix: a leather texture with seams and creasing.
4. **The lamp is a glare sprite** (tell 2, `860 20 160 260`): a white blown-out bloom on the frame, with little visible flame or chimney. Cause: light. Cheapest fix: tone down the bloom and show the lamp's glass and flame.
5. **The doorway is a flat dark hole** (tell 9, `600 0 120 300`; `cut d_dark_doorway.png`): the next room is a blank dark rectangle with a faint blue blot. Cause: light. Cheapest fix: a little fill or a glimpse of furniture in the next room.

## Ranking
From least to most cheap-looking: d, c, a, b
