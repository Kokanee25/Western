# Cheap judge, 2026-11-12_doctor_daylight_r1

## a
- 1 Flat light: FAIL (`300 180 660 360`, `a_flat_desk.png`): the desk and walls take the same even fill; the pigeonholes are as bright inside as out, the papers and inkstand cast nothing, and no window or lamp says where the light comes from (the hanging lamp is dark)
- 2 No atmosphere: FAIL (`0 0 1280 720`, `a_flat_desk.png`): a daylight room with no air at all; no dust or haze in front of the wall, the far corner as crisp as the near chair
- 3 Too clean: FAIL (`0 0 320 640`, `a_wall_grain.png`): the white boards are one even grey from top to bottom, a few stamped speckles at the foot; the desk has no scuffs, worn edges or stains; the papers are pristine white sheets
- 4 Too straight: FAIL (`300 180 660 360`, `a_flat_desk.png`): pigeonholes evenly spaced, every paper square to its slot, every board plumb and evenly spaced
- 5 Floating objects: PASS (inkstand sits on the blotter, desk against wall; the desk's and chair's feet are out of frame)
- 6 Repetition: FAIL (`0 0 320 640`, `a_wall_grain.png`): the same stretched wavy grain runs down every wall board, and the desk's grain is the same swirl on every drawer front
- 7 Empty: FAIL (`330 240 480 230`, `a_empty_desk.png`): a doctor's desk with one inkstand and a blotter; no books, bottles, instruments, letters spread out, lamp or coffee cup; nobody works here
- 8 Scale tells: PASS (desk, drawer pulls and bentwood chair read right for each other)
- 9 Edges of the world: PASS (an interior; the window at right is barely in frame)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Even grey fill, no light source** (tell 1, `300 180 660 360`): the whole room is lit like a showroom on an overcast day; no window patch, no shadow from the desk on the wall or floor, the hanging lamp dark. Cause: light. Cheapest fix: let a hard sun shaft or the lamp's pool fall across the desk so half the room drops into real shadow.
2. **A desk nobody uses** (tell 7, `330 240 480 230`): one inkstand on a blotter and a few white sheets; a doctor's desk should be buried in papers, ledgers, a lamp, a bottle, a stethoscope. Cause: dressing. Cheapest fix: scatter five or six period objects (open ledger, oil lamp, spectacles, a bottle and glass, loose letters) across the top.
3. **Wall boards one even grey with stretched grain** (tells 3 and 6, `0 0 320 640`): the paint has no chipping, soot or hand-grime; the same smeared grain repeats down every board, reading as a painted, toy finish. Cause: material. Cheapest fix: a grime/wear pass on the wall material (darker near floor and corners, chipped paint at edges) and a finer, non-stretched grain.
4. **No contact darkening anywhere** (tell 1, `380 240 420 140`): papers in the pigeonholes and the inkstand sit with no shadow under them, so they look pasted on. Cause: light. Cheapest fix: turn on ambient occlusion / contact shadows for small props.
5. **Dark ink outlines on every edge** (tell 4, `300 180 660 360`): black lines trace the desk and boards like a cel-shaded cartoon, at odds with the realistic aim. Cause: material. Cheapest fix: drop or soften the outline pass on interiors.

## b
- 1 Flat light: FAIL (`280 330 380 300`, `b_flat_cabinet.png`): a dim blue-grey wash over everything; the window is bright but throws no patch of light on the floor or cabinet; the blacks are lifted to slate
- 2 No atmosphere: FAIL (`230 50 260 220`, `b_blank_window.png`): no haze or dust in the window's light, the room's air is empty
- 3 Too clean: FAIL (`280 330 380 300`, `b_flat_cabinet.png`): the cabinet, the floor and the walls are uniform end to end; no dirt along the skirting, no worn path in the floor boards
- 4 Too straight: FAIL (`680 20 400 500`, `b_bottle_rows.png`): bottles in perfect rows on ruler-straight shelves, cabinet square to the wall
- 5 Floating objects: FAIL (`680 20 400 500`, `b_bottle_rows.png`): a bright white plane slices across behind the middle shelves, so the shelf unit looks like it stands in front of nothing; the cabinet's base has no darkening on the floor
- 6 Repetition: FAIL (`680 20 400 500`, `b_bottle_rows.png`): the same handful of bottle shapes and labels stamped down every shelf
- 7 Empty: PASS (the bottle wall, the mortar and pestle and the scales say an apothecary works here)
- 8 Scale tells: PASS (bottles, drawers and window read in proportion)
- 9 Edges of the world: FAIL (`230 50 260 220`, `b_blank_window.png`): the window is a flat beige card with nothing outside it
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **The window is a blank beige card** (tell 9, `230 50 260 220`): no street, no sky, no glare; a player sees that the world stops at the glass. Cause: geometry. Cheapest fix: show the street through the window (or at least a blown-out bright sky with a frame silhouette) and let it bloom.
2. **Murky, sourceless light** (tell 1, `280 330 380 300`): the whole room is the same dim blue-grey; the only bright thing in the room lights nothing. Cause: light. Cheapest fix: cast the window's sunlight as a hard patch across the floor and the cabinet front, and keep the corners black.
3. **Copy-pasted bottles** (tell 6, `680 20 400 500`): row after row of the same few bottles evenly spaced; it reads as one prop instanced a hundred times. Cause: dressing. Cheapest fix: vary spacing, height, fill level, and leave gaps, a tipped bottle and some boxes and papers among them.
4. **A bright slab cutting through the shelf unit** (tell 5, `680 20 400 500`): a white plane shows through behind the middle shelves, so the unit seems to float in a doorway with light leaking round it. Cause: geometry. Cheapest fix: give the shelf unit a solid back panel (or fix the wall/floor it leaks through).
5. **Clean cabinet and floor, ink outlines** (tell 3, `280 330 380 300`): the drawer bank is one smooth dark slab with outlined edges, the floor a uniform swirled grain with no wear; toy-like rather than used. Cause: material. Cheapest fix: wear on the cabinet top and drawer pulls, a worn path in the floor in front of it.

## c
- 1 Flat light: PASS (a warm sun streak on the left wall and a shaft on the floor, the right wall in shade: you can tell where the light comes from)
- 2 No atmosphere: PASS (the distance does fade to a pale, hazy grey)
- 3 Too clean: FAIL (`0 0 480 720`, `c_clean_wall.png`): the board walls are evenly painted from end to end, a few speckles low down; no grime in the corner or along the floor
- 4 Too straight: FAIL (`440 80 420 530`, `c_window_view.png`): plumb boards evenly spaced, a perfectly square window, a dead-level horizon line
- 5 Floating objects: FAIL (`540 120 80 400`, `c_hanging_post.png`): the porch post ends in mid-air above the plain, reaching nothing
- 6 Repetition: PASS (the wall boards repeat as boards do; nothing stamped stands out)
- 7 Empty: FAIL (`440 80 420 530`, `c_window_view.png`): a bare corner of a room and, outside, an empty plain with no road, fence, building, tree or person
- 8 Scale tells: PASS (window, porch and boards in proportion)
- 9 Edges of the world: FAIL (`440 80 420 530`, `c_window_view.png`): the world outside is a flat beige floor to a ruler-straight horizon with one cut-out strip of mesa; the clouds are posterised into a few flat bands
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Nothing outside the window** (tells 9 and 7, `440 80 420 530`): a flat beige plain, a straight grey band and a cardboard mesa; it reads as an unfinished test level. Cause: geometry. Cheapest fix: put the street (fronts, a hitching rail, a wagon) or at least rolling ground, scrub and a road into the view.
2. **A porch post hanging in the air** (tell 5, `540 120 80 400`): the post stops short of anything and dangles from the roof beam. Cause: geometry. Cheapest fix: run the post down to the porch deck (or extend the deck under it).
3. **Posterised sky** (tell 9, `500 100 320 200`): the clouds are a few flat cut-out tones with hard steps, the painted toy finish the game is leaving behind. Cause: material. Cheapest fix: smooth the sky's gradients (more colour steps, soft cloud edges).
4. **Spotless walls** (tell 3, `0 0 480 720`): the warm light is the best thing here, but it falls on boards with no grime, nail heads or worn paint; the corner is clean to the floor. Cause: material. Cheapest fix: corner and floor-line grime and chipped paint on the boards.
5. **Empty room corner** (tell 7, `0 520 480 200`): sun on a bare floor and nothing in it: no rug, chair, crate or dropped thing. Cause: dressing. Cheapest fix: one or two lived-in objects in the light (a chair, a coat on a peg, a crate).

## Ranking
From least to most cheap-looking: c, a, b
