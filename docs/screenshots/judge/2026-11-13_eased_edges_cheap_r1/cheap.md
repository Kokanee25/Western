# Cheap judge, 2026-11-13_eased_edges_cheap_r1

## a
- 1 Flat light: PASS (`840 360 220 120`: low sun throws a hard, warm pool and the baluster shadows across the gallery floor; the right side falls to real black)
- 2 No atmosphere: FAIL (`820 180 300 300`; `a_sun_no_air.jpg`)
- 3 Too clean: FAIL (`950 250 330 470`; `a_clean_floor.jpg`)
- 4 Too straight: FAIL (`560 180 480 330`; `a_straight_rail.jpg`)
- 5 Floating objects: PASS (`840 380 160 100`: the balustrade's foot shades the floor where it stands)
- 6 Repetition: PASS (identical balusters and lamp chimneys, but that is what a real balustrade and chandelier are)
- 7 Empty: FAIL (`1000 120 280 600`; `a_empty_gallery.jpg`)
- 8 Scale tells: PASS (rail height, baluster size and plank width agree)
- 9 Edges of the world: PASS (`1140 0 140 150`: the doorway's view out is small and hazy, no seam)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Nobody has ever used this gallery** (tell 7, `1000 120 280 600`): a long, swept, empty walkway; the room below has bare tables and no one at them. Cause: dressing. Cheapest fix: a spittoon, a dropped hat, a chair against the wall and one man leaning on the rail.
2. **The sunlight hits the floor but not the air** (tell 2, `820 180 300 300`): the hard sun pool on the boards has no shaft or dust above it, so the hall reads as a vacuum. Cause: light. Cheapest fix: a faint volumetric shaft from the window that makes the pool.
3. **The floor is a clean, glossy laminate** (tell 3, `950 250 330 470`): even varnish and crisp grain plank to plank, no scuffs, no grey wear path along the rail, no dirt in the corners. Cause: material. Cheapest fix: a darker, duller worn track down the walkway and grime where floor meets wall and rail.
4. **The top rail is a hard-edged box** (tell 4, `560 180 480 330`): the long handrail is a dead-straight square beam with a sharp top corner and a visible texture break where two lengths meet; it reads as modelled, not handled. Cause: geometry. Cheapest fix: round the rail's top edges so the light rolls over it.
5. **Plaster walls with stamped speckle** (tell 3, `1190 0 90 180`): the pillar and far wall have a uniform pattern of dark dots instead of real cracks and stains. Cause: material. Cheapest fix: a few large stains and a scuffed band at hip height instead of all-over dots.

## b
- 1 Flat light: FAIL (`420 500 200 220`; `b_flat_drawers.jpg`)
- 2 No atmosphere: N/A (a small room by day with no beam or lamp in view to show air)
- 3 Too clean: FAIL (`300 180 640 380`; `b_clean_desk.jpg`)
- 4 Too straight: FAIL (`380 230 420 130`; `b_straight_cubbies.jpg`)
- 5 Floating objects: PASS (`620 520 220 120`: the knee-hole is shaded and the desk sits on the floor)
- 6 Repetition: PASS (the wall boards are alike but do not visibly tile)
- 7 Empty: FAIL (`540 360 260 110`; `b_empty_desk.jpg`)
- 8 Scale tells: PASS (desk, drawers and chair agree)
- 9 Edges of the world: N/A (an interior corner, no view out)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A showroom desk** (tell 3, `300 180 640 380`): spotless orange varnish everywhere, sharp unworn edges, fresh white papers squared in their cubbies, the green blotter without a stain. It looks like a store-bought asset, not a desk someone writes at. Cause: material. Cheapest fix: wear the varnish off the front edge and around the pulls, darken the grain, ink stains on the blotter.
2. **The light comes from the camera** (tell 1, `420 500 200 220`): the drawer fronts are evenly lit pale orange from top to bottom, the wall lamp is dark, and nothing says where the light enters. Cause: light. Cheapest fix: one motivated key (a window off-frame or the lit lamp) so the drawers fall off into shadow.
3. **Nothing on the desk says who works here** (tell 7, `540 360 260 110`): two ink bottles in the middle of a bare blotter; no pen, no ledger, no lamp, no cup. Cause: dressing. Cheapest fix: an open ledger, a pen across it and an oil lamp.
4. **Cartoon wood on the wall** (tell 3, `960 120 320 420`): the beadboard is cream with smooth, wavy painted grain and a few black dots, a toy-like finish next to the desk. Cause: material. Cheapest fix: a real painted-board texture, with the paint chipped at the baseboard.
5. **Every cubby and drawer is ruler-perfect** (tell 4, `380 230 420 130`): identical divisions, identical drawers, all exactly level. Cause: geometry. Cheapest fix: one drawer left a little open and the papers in the cubbies uneven.

## c
- 1 Flat light: PASS (`120 440 260 280`: window light lies in hard bright panes on the floor; corners fall to black)
- 2 No atmosphere: FAIL (`100 80 380 620`; `c_sun_no_air.jpg`)
- 3 Too clean: FAIL (`0 260 360 460`; `c_clean_floor.jpg`)
- 4 Too straight: FAIL (`250 160 500 140`; `c_straight_rail.jpg`)
- 5 Floating objects: PASS (`580 560 120 140`: the newel post and the balustrade are grounded with shade)
- 6 Repetition: PASS (alike windows and balusters, as in a real building)
- 7 Empty: FAIL (`0 240 600 480`; `c_empty_gallery.jpg`)
- 8 Scale tells: PASS (newel, rails, doors and windows agree)
- 9 Edges of the world: FAIL (`100 0 460 50`; `c_roof_seams.jpg`)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **A huge, bare upper floor** (tell 7, `0 240 600 480`): half the frame is empty planking; no furniture, no doors open, no one upstairs or at the tables below. Cause: dressing. Cheapest fix: chairs and a table along the left wall and a figure at the far rail.
2. **Sun on the floor, none in the air** (tell 2, `100 80 380 620`): two bright window panes land on the boards with nothing visible between the window and the floor. Cause: light. Cheapest fix: a soft dusty shaft from the window to its pool.
3. **Clean, even floorboards with a seam** (tell 3, `0 260 360 460`): the planks are evenly varnished, without scuffs, and a long dark straight line runs down the floor at the left where two floor pieces meet. Cause: material. Cheapest fix: wear and dirt on the boards, and hide the seam under a plank joint.
4. **Light leaking through the roof in dotted lines** (tell 9, `100 0 460 50`): bright dashed slivers between the ceiling boards read as rendering gaps, not as a real roof. Cause: geometry. Cheapest fix: close the gaps or make them few and ragged, like real gaps.
5. **The far balustrade is a ruler line** (tell 4, `250 160 500 140`): perfectly straight and level rails with evenly spaced balusters all round the stairwell; nothing sags. Cause: geometry. Cheapest fix: a slight sag on the long run and one baluster missing or out of line.

## d
- 1 Flat light: PASS (`840 360 220 120`: hard warm sun pool and baluster shadows; deep black at right)
- 2 No atmosphere: FAIL (`820 180 300 300`; `d_sun_no_air.jpg`)
- 3 Too clean: FAIL (`950 250 330 470`; `d_clean_floor.jpg`)
- 4 Too straight: FAIL (`560 180 480 330`; `d_straight_rail.jpg`)
- 5 Floating objects: PASS (`840 380 160 100`: the balustrade's foot shades the floor)
- 6 Repetition: PASS (alike balusters and lamp chimneys, as in reality)
- 7 Empty: FAIL (`1000 120 280 600`; `d_empty_gallery.jpg`)
- 8 Scale tells: PASS (rail, balusters and planks agree)
- 9 Edges of the world: PASS (`1140 0 140 150`: small hazy view out, no seam)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Nobody has ever used this gallery** (tell 7, `1000 120 280 600`): an empty swept walkway and bare tables below. Cause: dressing. Cheapest fix: a chair, a spittoon, a dropped coat and one man on the rail.
2. **The sunlight hits the floor but not the air** (tell 2, `820 180 300 300`): a hard sun pool with no shaft or dust above it. Cause: light. Cheapest fix: a faint shaft from the window to the pool.
3. **The floor is clean, glossy laminate** (tell 3, `950 250 330 470`): even varnish, no worn path, no grime in the corners. Cause: material. Cheapest fix: a dull worn track along the rail and dirt where floor meets wall.
4. **The balustrade is too regular** (tell 4, `560 180 480 330`): even spacing and a dead-straight run; the rounded handrail helps (it catches a soft highlight along its top and looks handled), but nothing leans or sags. Cause: geometry. Cheapest fix: a slight sag in the long rail and one baluster out of line.
5. **Plaster walls with stamped speckle** (tell 3, `1190 0 90 180`): uniform dark dots instead of real stains and cracks. Cause: material. Cheapest fix: a few big stains and a scuffed band at hip height.

## e
- 1 Flat light: FAIL (`420 500 200 220`; `e_flat_drawers.jpg`)
- 2 No atmosphere: N/A (a small room by day with no beam or lamp in view)
- 3 Too clean: FAIL (`300 180 640 380`; `e_clean_desk.jpg`)
- 4 Too straight: FAIL (`380 230 420 130`; `e_straight_cubbies.jpg`)
- 5 Floating objects: PASS (`620 520 220 120`: the knee-hole is shaded, the desk sits down)
- 6 Repetition: PASS (wall boards alike, no visible tiling)
- 7 Empty: FAIL (`540 360 260 110`; `e_empty_desk.jpg`)
- 8 Scale tells: PASS (desk, drawers and chair agree)
- 9 Edges of the world: N/A (an interior corner)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A showroom desk** (tell 3, `300 180 640 380`): spotless orange varnish, unworn edges, squared white papers, a clean blotter. Cause: material. Cheapest fix: worn varnish at the front edge and pulls, ink stains, darker grain.
2. **The light comes from the camera** (tell 1, `420 500 200 220`): drawer fronts evenly lit top to bottom; the wall lamp is dark and no source is implied. Cause: light. Cheapest fix: one motivated key so the drawers fall into shadow.
3. **Nothing on the desk says who works here** (tell 7, `540 360 260 110`): two ink bottles on a bare blotter. Cause: dressing. Cheapest fix: an open ledger, a pen and a lamp.
4. **Cartoon wood on the wall** (tell 3, `960 120 320 420`): cream beadboard with smooth painted grain and a few dots, toy-like. Cause: material. Cheapest fix: a real painted-board texture with chipped paint at the baseboard.
5. **Every cubby and drawer is ruler-perfect** (tell 4, `380 230 420 130`): identical divisions and drawers, exactly level; the seam between the top's boards is a hard, slightly stair-stepped dark line. Cause: geometry. Cheapest fix: one drawer ajar, uneven papers.

## f
- 1 Flat light: PASS (`120 440 260 280`: hard window panes of light on the floor; corners to black)
- 2 No atmosphere: FAIL (`100 80 380 620`; `f_sun_no_air.jpg`)
- 3 Too clean: FAIL (`0 260 360 460`; `f_clean_floor.jpg`)
- 4 Too straight: FAIL (`250 160 500 140`; `f_straight_rail.jpg`)
- 5 Floating objects: PASS (`580 560 120 140`: newel and balustrade grounded)
- 6 Repetition: PASS (alike windows and balusters, as in reality)
- 7 Empty: FAIL (`0 240 600 480`; `f_empty_gallery.jpg`)
- 8 Scale tells: PASS (newel, rails, doors, windows agree)
- 9 Edges of the world: FAIL (`100 0 460 50`; `f_roof_seams.jpg`)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **A huge, bare upper floor** (tell 7, `0 240 600 480`): half the frame empty planking, no one anywhere. Cause: dressing. Cheapest fix: furniture along the left wall and a figure at the rail.
2. **Sun on the floor, none in the air** (tell 2, `100 80 380 620`): window panes on the boards with no shaft between window and floor. Cause: light. Cheapest fix: a soft dusty shaft.
3. **Square-edged, boxy handrails** (tell 4, `640 180 420 260`): the handrails meeting the newel read as sharp rectangular beams with flat tops and hard corners, like cut stock that no hand ever slid along. Cause: geometry. Cheapest fix: round the handrails' top edges.
4. **Clean floorboards with a seam** (tell 3, `0 260 360 460`): evenly varnished planks and a long dark straight seam down the floor at the left. Cause: material. Cheapest fix: wear and dirt, and hide the seam on a plank joint.
5. **Light leaking through the roof in dotted lines** (tell 9, `100 0 460 50`): bright dashed slivers between ceiling boards that read as render gaps. Cause: geometry. Cheapest fix: close them or make a few ragged real gaps.

## Ranking
From least to most cheap-looking: d, c, a, f, b, e

## Pairs
- **a and d** (the gallery rail from above, close): **d is better, clearly** when you look at the rail itself. In a the long handrail is a square box: a sharp top corner, a flat top face, and a visible texture break where two lengths meet (`a_rail_mid.jpg`). In d the same rail has rounded top edges that catch a soft highlight along their length, so it reads as a worn, handled rail, and the joint reads as a crack in old wood rather than a mesh seam (`d_rail_mid.jpg`). The balusters look the same in both (sharp-edged in both). At full frame a player notices it only on the near rail, which is the biggest thing in shot, so it does show.
- **c and f** (the stairwell gallery, wide): **c is better; the difference is slight** at full frame, clear in a close look (`c_newel.jpg` vs `f_newel.jpg`). In c the handrails meeting the newel post have eased, rounded tops with a soft highlight; in f they are square beams with flat tops and hard corners. The newel post itself is a sharp-cornered box in both, and the balusters are the same. Because the rails are smaller in this wide shot, a player would only feel it, not point to it.
- **b and e** (the roll-top desk): **near-identical; b by a hair, and only if you hunt.** The desk's edges and corners look the same in both (`b_desk_top.jpg`, `e_desk_top.jpg`). The one difference found is the seam between the desk top's boards: in b a soft, lighter line; in e a harder dark line with small stair-steps (`b_desk_corner.jpg`, `e_desk_corner.jpg`). No player would see it.


## Unblinded (added after the verdict, #873)
a = saloon B's gallery rail before, d = the same after (eased edges, the handrail profile); c = the well after,
f = before; b = the doctor's desk after, e = before. Every pair prefers the after: the rail clearly, the well
slightly, the desk by a hair (the desk is a kit prop, not a library board: its edges unchanged, as expected).
