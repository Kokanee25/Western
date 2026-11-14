# Cheap judge, 2026-11-12_doctor_daylight_r2

## a
- 1 Flat light: PASS (`380 400 900 320`: a soft desk shadow falls on the left wall, a dark cavity under the desk and sun streaks across the chair seat; the light has a side, though the cream wall above is evenly lit)
- 2 No atmosphere: FAIL (`0 0 900 450`; `a_air.png`): a sunlit room with no dust or haze in the air at all; every board edge crisp to the corner
- 3 Too clean: FAIL (`380 400 560 320`; `a_clean.png`): the desk's wood is one glossy, loud grain on every face, no worn edges, no rubbed handles, no scuffs on the drawer fronts
- 4 Too straight: FAIL (`340 200 600 200`; `a_straight.png`): pigeonholes, drawers and wall boards in perfect rows and spacing; nothing warped or out of true
- 5 Floating objects: PASS (`600 500 600 220`: the desk's knee-hole and the chair sit in shadow on the floor)
- 6 Repetition: PASS (the desk grain repeats in feel but not as a visible tile)
- 7 Empty: FAIL (`380 330 560 150`; `a_empty.png`): a doctor's desk with a bare blotter, one inkstand and three tidy stacks of paper; no pen, letters, books, instruments, cup or mess
- 8 Scale tells: PASS (desk, drawers and chair read at one scale)
- 9 Edges of the world: PASS (an interior; the side window shows nothing wrong)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Painted, toy-like finish** (tell 3, `380 400 560 320`): the desk's grain is an over-contrasted orange swirl on every surface, and black ink outlines trace the wall boards and furniture edges, so it reads as a cel-shaded asset, not old varnished wood. Cause: material. Cheapest fix: drop the outlines and calm the wood (less contrast, darker varnish, wear on edges and around handles).
2. **Nothing on the desk** (tell 7, `380 330 560 150`): a working doctor's desk with a clean blotter and almost nothing on it; nobody works here. Cause: dressing. Cheapest fix: clutter it: open ledger, pen, letters, a bottle, spectacles, a lamp, paper in the pigeonholes.
3. **No air in a sunlit room** (tell 2, `0 0 900 450`): the light comes in but nothing in the air catches it; the room feels vacuum-clean. Cause: light. Cheapest fix: a faint dust haze or a soft shaft from the window.
4. **Everything square and level** (tell 4, `340 200 600 200`): pigeonholes and drawers like a CAD model; the wall boards ruler-straight. Cause: geometry. Cheapest fix: slightly vary the pigeonhole contents and the wall boards (a gap, a bowed board).
5. **Clean walls** (tell 3, `0 0 400 720`): the cream boards are one even tone floor to ceiling, with only a few chips near the floor. Cause: material. Cheapest fix: grime and smoke-darkening near the lamp, ceiling and floor.

## b
- 1 Flat light: FAIL (`230 60 460 400`; `b_flat.png`): a bright daylit window throws no light into the room; the walls are one murky grey-green and you can't say where the room's light comes from
- 2 No atmosphere: FAIL (`250 60 450 560`; `b_air.png`): no shaft or glow from the window, no dust; just dim grey
- 3 Too clean: FAIL (`380 460 640 260`; `b_clean.png`): the floor is a uniform glossy plank texture, no scuffs where feet go or dirt at the walls
- 4 Too straight: FAIL (`680 20 380 480`; `b_straight.png`): shelf bottles in ruler-straight ranks, every shelf identical
- 5 Floating objects: PASS (the cabinet and shelf sit in shadow on the floor)
- 6 Repetition: FAIL (`700 90 340 380`; `b_repeat.png`): the same few bottle models repeated row after row, evenly spaced
- 7 Empty: PASS (the counter has bottles, mortar and a scale; the shelf is full)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`270 70 200 190`; `b_edge.png`): the window is a blank flat beige-grey pane; nothing outside
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Dead window** (tell 9, `270 70 200 190`): a flat beige rectangle where the outside should be, the first thing the eye goes to. Cause: camera. Cheapest fix: let the sky/street show, or frost the glass with dirt so it reads as a pane.
2. **The window lights nothing** (tell 1, `230 60 460 400`): a daylight window beside a uniformly dim, greyish room with no light pool on the counter or floor. Cause: light. Cheapest fix: a sun shaft or bright patch from the window across the counter and floor, and deeper blacks in the corners.
3. **Copy-pasted bottle wall** (tell 6, `700 90 340 380`): rows of identical bottles at identical spacing read as an array. Cause: dressing. Cheapest fix: vary heights, gaps, a few lying or missing, boxes and papers between.
4. **No air** (tell 2, `250 60 450 560`): nothing in the room's air; the dimness is just grey, not haze. Cause: light. Cheapest fix: dust in a window shaft.
5. **Glossy clean floor** (tell 3, `380 460 640 260`): bright reddish varnish, even everywhere, no tracks or dirt. Cause: material. Cheapest fix: dull it and add a worn path from door to counter and dirt in the corners.

## c
- 1 Flat light: PASS (`200 600 500 120`: a warm sun patch on the floor and a clear shadow edge on the left wall; the light comes from outside, right)
- 2 No atmosphere: PASS (`500 290 320 60`: the distance falls into a grey haze band)
- 3 Too clean: FAIL (`860 0 420 720`; `c_clean.png`): the wall boards are one even pale paint with only a few chips at the bottom
- 4 Too straight: FAIL (`440 0 430 640`; `c_straight.png`): window frame, boards and porch beam perfectly square and plumb
- 5 Floating objects: FAIL (`540 130 80 380`; `c_float.png`): the porch post hangs from the roof and stops in mid-air, its foot well above the ground
- 6 Repetition: PASS
- 7 Empty: FAIL (`500 280 320 280`; `c_empty.png`): outside the window, a bare flat plain; no street, building, fence or person
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`500 280 320 100`; `c_edge.png`): a ruler-flat sand plane meets a flat grey band and a thin cut-out mesa; the world ends there
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Hanging porch post** (tell 5, `540 130 80 380`): the post dangles from the roof with nothing under it; any player sees it as a bug. Cause: geometry. Cheapest fix: run the post down to the ground or the porch floor.
2. **Empty world outside** (tell 9, `500 280 320 100`): a featureless beige plane under a flat grey distance band; no town beyond the window. Cause: camera. Cheapest fix: put the street (or at least ground texture, scrub and a fence) in the window's view.
3. **Nothing out there** (tell 7, `500 280 320 280`): the view is the most important thing in the frame and it holds nothing. Cause: dressing. Cheapest fix: a building, hitching rail or wagon across the way.
4. **Clean paint** (tell 3, `860 0 420 720`): the walls are an even fresh-looking colour with ink outlines on every board, more toy than old timber. Cause: material. Cheapest fix: weathering and grime, darker near floor and window, and drop the outlines.
5. **Square everything** (tell 4, `440 0 430 640`): the frame and boards like a model; the porch floor's broken edge is the only irregular thing. Cause: geometry. Cheapest fix: a slight sag in the porch beam and a little board variation.

## Ranking
From least to most cheap-looking: a, c, b
