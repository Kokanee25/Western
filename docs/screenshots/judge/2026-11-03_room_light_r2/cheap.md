# Cheap judge, 2026-11-03_room_light_r2

## a
- 1 Flat light: FAIL (`0 0 1280 230`; `docs/screenshots/judge/2026-11-03_room_light_r2/a_ceiling.png`): the pine ceiling is lit pale and even from end to end, as bright as the walls, with no dark falling off above the lamps; the blacks sit at a warm mid-brown, so the room reads daylit, not lamplit.
- 2 No atmosphere: FAIL (`600 90 680 330`; `docs/screenshots/judge/2026-11-03_room_light_r2/a_air.png`): the far gable wall 15 m off is as crisp and saturated as the near boards; no smoke or haze hangs round the sconces or under the roof.
- 3 Too clean: FAIL (`40 470 360 250`; `docs/screenshots/judge/2026-11-03_room_light_r2/a_floor.png`): the floorboards are one even pine with the same scattered dark knots, a dotted seam line running across them, no grime at the foot of the bar or worn path to it; her skin (`400 250 340 470`; `docs/screenshots/judge/2026-11-03_room_light_r2/a_skin.png`) is one smooth orange plastic.
- 4 Too straight: FAIL (`220 220 330 280`; `docs/screenshots/judge/2026-11-03_room_light_r2/a_bar.png`): the bar, back bar and walls are clean boxes with dead-level tops and plumb walls; nothing sags, leans or is patched.
- 5 Floating objects: PASS (`330 380 560 330`: the stools, chair and table each cast a soft shadow onto the boards).
- 6 Repetition: FAIL (`690 230 590 100`; `docs/screenshots/judge/2026-11-03_room_light_r2/a_sconces.png`): the same brass sconce repeated at the same height and spacing round every wall, the same chair everywhere, and the back bar's bottles are one bottle in rows.
- 7 Empty: FAIL (`760 330 400 140`; `docs/screenshots/judge/2026-11-03_room_light_r2/a_tables.png`): the back half of the saloon has empty tables, bare walls with one deer head and one dark picture, and nobody sitting anywhere.
- 8 Scale tells: PASS (bar, stools, chairs and the people read the right size for each other).
- 9 Edges of the world: PASS (an interior; the gable's board gaps show only thin slits of night).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The whole room is one orange at one brightness** (tell 1, `0 0 1280 230`): the ceiling and walls are lit as evenly as a showroom; nothing tells you the light comes from a dozen small oil flames. Cause: light. Cheapest fix: let the fill die off with height and distance from the lamps, so the roof and corners go nearly black.
2. **No air in the lamplight** (tell 2, `600 90 680 330`): the far wall is pin-sharp; no smoke, haze or glow round the sconces, which is half of what makes a saloon at night. Cause: light. Cheapest fix: a thin warm volumetric haze indoors, thicker under the roof, that catches each lamp.
3. **A woman's back fills the middle of the frame** (tell 3, `400 250 340 470`): she stands square to camera blocking the view, her skin one smooth orange plastic and her hair a single red mass. Cause: people. Cheapest fix: shade her skin with the room's light and shadow (darker away from the lamps) and break up the hair's highlights.
4. **The saloon is half empty** (tell 7, `760 330 400 140`): tables set with lamps and cups but no one at them, the back walls bare. Cause: dressing. Cheapest fix: put two or three seated drinkers at the far tables.
5. **Every lamp the same lamp** (tell 6, `690 230 590 100`): one sconce model copied at even spacing round every wall. Cause: dressing. Cheapest fix: vary the fixtures (a few unlit, a few askew, two kinds) and break the spacing.

## b
- 1 Flat light: FAIL (`0 90 550 420`; `docs/screenshots/judge/2026-11-03_room_light_r2/b_walls.png`): the left wall is one saturated orange from floor to plate, evenly lit between the sconces; the floor's big cast shadow is the only real shadow shape.
- 2 No atmosphere: FAIL (`560 180 420 230`; `docs/screenshots/judge/2026-11-03_room_light_r2/b_air.png`): the back of the room, the stair and the doorway are as sharp and saturated as the near tables; no haze or smoke in the lamplight.
- 3 Too clean: FAIL (`880 360 400 360`; `docs/screenshots/judge/2026-11-03_room_light_r2/b_bartop.png`): the bar top is glossy pale pine with its grain stretched the whole length, no rings, scuffs or worn edge; the floor the same pine with the same knots throughout; the held hand (`740 440 340 280`; `docs/screenshots/judge/2026-11-03_room_light_r2/b_hand.png`) smooth pink plastic.
- 4 Too straight: FAIL (`0 0 1280 240`; `docs/screenshots/judge/2026-11-03_room_light_r2/b_rafters.png`): rafters, wall plates and the bar run in perfectly parallel, evenly spaced lines.
- 5 Floating objects: PASS (`100 380 380 260`: chairs and the table cast soft shadows on the boards).
- 6 Repetition: FAIL (`130 250 400 70`; `docs/screenshots/judge/2026-11-03_room_light_r2/b_paintings.png`): the same sconce at the same height and spacing, and the same small desert painting hung three times along the walls.
- 7 Empty: FAIL (`440 380 440 300`; `docs/screenshots/judge/2026-11-03_room_light_r2/b_floor.png`): a long bare floor and empty tables, one woman far off at the piano; nobody at the bar.
- 8 Scale tells: PASS (door, stair, stools and furniture agree).
- 9 Edges of the world: PASS (the open door shows a back room and a sliver of night sky; it holds together).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A pink plastic hand fills the bottom right** (tell 3, `740 440 340 280`): the hand is waxy and unshaded by the room, and it seems to hold the revolver by the cylinder with no grip in it; it is the first thing the eye meets. Cause: people. Cheapest fix: light and colour the arm with the room's warm light and dark, and seat the grip in the palm.
2. **Walls of one flat orange** (tell 1, `0 90 550 420`): the boards are equally bright between the lamps, so the sconces don't seem to be doing the lighting. Cause: light. Cheapest fix: tighten each sconce's pool and drop the wall's fill so the dark falls between them.
3. **No air** (tell 2, `560 180 420 230`): the far end is as crisp as the foreground; no smoke under the roof. Cause: light. Cheapest fix: a warm indoor haze, thicker up high, that the lamps glow in.
4. **The room is empty** (tell 7, `440 380 440 300`): set tables and a long bar with no drinkers. Cause: dressing. Cheapest fix: men at the bar and at two of the tables.
5. **Repeated pictures and lamps** (tell 6, `130 250 400 70`): the same painting hung three times and the same sconce at the same spacing. Cause: dressing. Cheapest fix: different pictures and frames, some hung crooked, and fixtures varied.

## c
- 1 Flat light: FAIL (`0 0 1280 230`; `docs/screenshots/judge/2026-11-03_room_light_r2/c_ceiling.png`): the pine ceiling is lit pale and even from end to end, as bright as the walls, with no dark falling off above the lamps; the blacks sit at a warm mid-brown, so the room reads daylit, not lamplit.
- 2 No atmosphere: FAIL (`600 90 680 330`; `docs/screenshots/judge/2026-11-03_room_light_r2/c_air.png`): the far gable wall 15 m off is as crisp and saturated as the near boards; no smoke or haze hangs round the sconces or under the roof.
- 3 Too clean: FAIL (`40 470 360 250`; `docs/screenshots/judge/2026-11-03_room_light_r2/c_floor.png`): the floorboards are one even pine with the same scattered dark knots, a dotted seam line running across them, no grime at the foot of the bar or worn path to it; her skin (`400 250 340 470`; `docs/screenshots/judge/2026-11-03_room_light_r2/c_skin.png`) is one smooth orange plastic.
- 4 Too straight: FAIL (`220 220 330 280`; `docs/screenshots/judge/2026-11-03_room_light_r2/c_bar.png`): the bar, back bar and walls are clean boxes with dead-level tops and plumb walls; nothing sags, leans or is patched.
- 5 Floating objects: PASS (`330 380 560 330`: the stools, chair and table each cast a soft shadow onto the boards).
- 6 Repetition: FAIL (`690 230 590 100`; `docs/screenshots/judge/2026-11-03_room_light_r2/c_sconces.png`): the same brass sconce repeated at the same height and spacing round every wall, the same chair everywhere, and the back bar's bottles are one bottle in rows.
- 7 Empty: FAIL (`760 330 400 140`; `docs/screenshots/judge/2026-11-03_room_light_r2/c_tables.png`): the back half of the saloon has empty tables, bare walls with one deer head and one dark picture, and nobody sitting anywhere.
- 8 Scale tells: PASS (bar, stools, chairs and the people read the right size for each other).
- 9 Edges of the world: PASS (an interior; the gable's board gaps show only thin slits of night).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The whole room is one orange at one brightness** (tell 1, `0 0 1280 230`): the ceiling and walls are lit as evenly as a showroom; nothing tells you the light comes from a dozen small oil flames. Cause: light. Cheapest fix: let the fill die off with height and distance from the lamps, so the roof and corners go nearly black.
2. **No air in the lamplight** (tell 2, `600 90 680 330`): the far wall is pin-sharp; no smoke, haze or glow round the sconces, which is half of what makes a saloon at night. Cause: light. Cheapest fix: a thin warm volumetric haze indoors, thicker under the roof, that catches each lamp.
3. **A woman's back fills the middle of the frame** (tell 3, `400 250 340 470`): she stands square to camera blocking the view, her skin one smooth orange plastic and her hair a single red mass. Cause: people. Cheapest fix: shade her skin with the room's light and shadow (darker away from the lamps) and break up the hair's highlights.
4. **The saloon is half empty** (tell 7, `760 330 400 140`): tables set with lamps and cups but no one at them, the back walls bare. Cause: dressing. Cheapest fix: put two or three seated drinkers at the far tables.
5. **A dark pole slashes across the view** (tell 3, `790 400 230 320`; `docs/screenshots/judge/2026-11-03_room_light_r2/c_pole.png`): the held weapon is a smooth blurry tube from the bottom edge into the table, unreadable as any object. Cause: camera. Cheapest fix: lower and angle the held weapon so it sits in the bottom corner and reads as a gun.

## d
- 1 Flat light: FAIL (`0 0 1280 290`; `docs/screenshots/judge/2026-11-03_room_light_r2/d_ceiling.png`): the whole roof is lit pale and even to the ridge; the walls a uniform orange; you can't tell the light comes from the small lamps.
- 2 No atmosphere: FAIL (`400 280 480 200`; `docs/screenshots/judge/2026-11-03_room_light_r2/d_air.png`): the far end wall is as crisp and saturated as the bar beside you; no haze in the lamplight.
- 3 Too clean: FAIL (`150 480 620 240`; `docs/screenshots/judge/2026-11-03_room_light_r2/d_floor.png`): one even pine floor with scattered identical knots and no grime under the bar rail or round the spittoons; the held hand (`740 440 380 280`; `docs/screenshots/judge/2026-11-03_room_light_r2/d_hand.png`) smooth waxy pink.
- 4 Too straight: FAIL (`0 420 480 300`; `docs/screenshots/judge/2026-11-03_room_light_r2/d_bar.png`): the bar is one dead-straight box of stretched grain, and the rafters march in perfect parallel.
- 5 Floating objects: PASS (`230 440 300 260`: the stools and spittoons cast soft shadows).
- 6 Repetition: FAIL (`240 450 280 240`; `docs/screenshots/judge/2026-11-03_room_light_r2/d_stools.png`): the same stool at even spacing down the bar, the same sconce in a level row round the walls, and the bottles one bottle in rows.
- 7 Empty: FAIL (`480 470 460 250`; `docs/screenshots/judge/2026-11-03_room_light_r2/d_emptyfloor.png`): a long empty aisle of floor to a bare end wall, empty tables; only the barman, half off the left edge.
- 8 Scale tells: PASS (bar, stools, chairs and door agree).
- 9 Edges of the world: PASS (an interior; the gable gaps show only slits of night).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A pink plastic hand fills the bottom right** (tell 3, `740 440 380 280`): waxy, faceted, unshaded by the room, gripping the revolver by its frame with the grip nowhere in the palm. Cause: people. Cheapest fix: light the arm with the room's light and dark and seat the grip in the hand.
2. **A daylit roof over a lamplit room** (tell 1, `0 0 1280 290`): the ceiling is as bright at the ridge as over the lamps. Cause: light. Cheapest fix: let the fill die off with height so the roof goes dark above the lamps.
3. **The room is empty** (tell 7, `480 470 460 250`): a long bare aisle down the middle, tables set for no one. Cause: dressing. Cheapest fix: drinkers along the bar and at the far tables.
4. **No air** (tell 2, `400 280 480 200`): the end wall is sharp and saturated; no smoke catching the lamps. Cause: light. Cheapest fix: a warm indoor haze, thicker up high.
5. **One stool, one lamp, one bottle, repeated** (tell 6, `240 450 280 240`): the same stool at even spacing, the same sconce in a level row. Cause: dressing. Cheapest fix: vary and knock a few stools askew, mix the fixtures and bottles.

## e
- 1 Flat light: FAIL (`0 0 1280 230`; `docs/screenshots/judge/2026-11-03_room_light_r2/e_ceiling.png`): the pine ceiling is lit pale and even from end to end, as bright as the walls, with no dark falling off above the lamps; the blacks sit at a warm mid-brown, so the room reads daylit, not lamplit.
- 2 No atmosphere: FAIL (`600 90 680 330`; `docs/screenshots/judge/2026-11-03_room_light_r2/e_air.png`): the far gable wall 15 m off is as crisp and saturated as the near boards; no smoke or haze hangs round the sconces or under the roof.
- 3 Too clean: FAIL (`40 470 360 250`; `docs/screenshots/judge/2026-11-03_room_light_r2/e_floor.png`): the floorboards are one even pine with the same scattered dark knots, a dotted seam line running across them, no grime at the foot of the bar or worn path to it; her skin (`400 250 340 470`; `docs/screenshots/judge/2026-11-03_room_light_r2/e_skin.png`) is one smooth orange plastic.
- 4 Too straight: FAIL (`220 220 330 280`; `docs/screenshots/judge/2026-11-03_room_light_r2/e_bar.png`): the bar, back bar and walls are clean boxes with dead-level tops and plumb walls; nothing sags, leans or is patched.
- 5 Floating objects: PASS (`330 380 560 330`: the stools, chair and table each cast a soft shadow onto the boards).
- 6 Repetition: FAIL (`690 230 590 100`; `docs/screenshots/judge/2026-11-03_room_light_r2/e_sconces.png`): the same brass sconce repeated at the same height and spacing round every wall, the same chair everywhere, and the back bar's bottles are one bottle in rows.
- 7 Empty: FAIL (`760 330 400 140`; `docs/screenshots/judge/2026-11-03_room_light_r2/e_tables.png`): the back half of the saloon has empty tables, bare walls with one deer head and one dark picture, and nobody sitting anywhere.
- 8 Scale tells: PASS (bar, stools, chairs and the people read the right size for each other).
- 9 Edges of the world: PASS (an interior; the gable's board gaps show only thin slits of night).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The whole room is one orange at one brightness** (tell 1, `0 0 1280 230`): the ceiling and walls are lit as evenly as a showroom; nothing tells you the light comes from a dozen small oil flames. Cause: light. Cheapest fix: let the fill die off with height and distance from the lamps, so the roof and corners go nearly black.
2. **No air in the lamplight** (tell 2, `600 90 680 330`): the far wall is pin-sharp; no smoke, haze or glow round the sconces, which is half of what makes a saloon at night. Cause: light. Cheapest fix: a thin warm volumetric haze indoors, thicker under the roof, that catches each lamp.
3. **A woman's back fills the middle of the frame** (tell 3, `400 250 340 470`): she stands square to camera blocking the view, her skin one smooth orange plastic and her hair a single red mass. Cause: people. Cheapest fix: shade her skin with the room's light and shadow (darker away from the lamps) and break up the hair's highlights.
4. **The saloon is half empty** (tell 7, `760 330 400 140`): tables set with lamps and cups but no one at them, the back walls bare. Cause: dressing. Cheapest fix: put two or three seated drinkers at the far tables.
5. **A dark pole slashes across the view** (tell 3, `790 400 230 320`; `docs/screenshots/judge/2026-11-03_room_light_r2/e_pole.png`): the held weapon is a smooth blurry tube crossing the table, and the barman stands out at the bar's end, not behind it. Cause: camera. Cheapest fix: lower and angle the held weapon so it sits in the bottom corner and reads as a gun.

## f
- 1 Flat light: FAIL (`0 0 1280 230`; `docs/screenshots/judge/2026-11-03_room_light_r2/f_ceiling.png`): the pine ceiling is lit pale and even from end to end, as bright as the walls, with no dark falling off above the lamps; the blacks sit at a warm mid-brown, so the room reads daylit, not lamplit.
- 2 No atmosphere: FAIL (`600 90 680 330`; `docs/screenshots/judge/2026-11-03_room_light_r2/f_air.png`): the far gable wall 15 m off is as crisp and saturated as the near boards; no smoke or haze hangs round the sconces or under the roof.
- 3 Too clean: FAIL (`40 470 360 250`; `docs/screenshots/judge/2026-11-03_room_light_r2/f_floor.png`): the floorboards are one even pine with the same scattered dark knots, a dotted seam line running across them, no grime at the foot of the bar or worn path to it; her skin (`400 250 340 470`; `docs/screenshots/judge/2026-11-03_room_light_r2/f_skin.png`) is one smooth orange plastic.
- 4 Too straight: FAIL (`220 220 330 280`; `docs/screenshots/judge/2026-11-03_room_light_r2/f_bar.png`): the bar, back bar and walls are clean boxes with dead-level tops and plumb walls; nothing sags, leans or is patched.
- 5 Floating objects: PASS (`330 380 560 330`: the stools, chair and table each cast a soft shadow onto the boards).
- 6 Repetition: FAIL (`690 230 590 100`; `docs/screenshots/judge/2026-11-03_room_light_r2/f_sconces.png`): the same brass sconce repeated at the same height and spacing round every wall, the same chair everywhere, and the back bar's bottles are one bottle in rows.
- 7 Empty: FAIL (`760 330 400 140`; `docs/screenshots/judge/2026-11-03_room_light_r2/f_tables.png`): the back half of the saloon has empty tables, bare walls with one deer head and one dark picture, and nobody sitting anywhere.
- 8 Scale tells: PASS (bar, stools, chairs and the people read the right size for each other).
- 9 Edges of the world: PASS (an interior; the gable's board gaps show only thin slits of night).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The whole room is one orange at one brightness** (tell 1, `0 0 1280 230`): the ceiling and walls are lit as evenly as a showroom; nothing tells you the light comes from a dozen small oil flames. Cause: light. Cheapest fix: let the fill die off with height and distance from the lamps, so the roof and corners go nearly black.
2. **No air in the lamplight** (tell 2, `600 90 680 330`): the far wall is pin-sharp; no smoke, haze or glow round the sconces, which is half of what makes a saloon at night. Cause: light. Cheapest fix: a thin warm volumetric haze indoors, thicker under the roof, that catches each lamp.
3. **A woman's back fills the middle of the frame** (tell 3, `400 250 340 470`): she stands square to camera blocking the view, her skin one smooth orange plastic and her hair a single red mass. Cause: people. Cheapest fix: shade her skin with the room's light and shadow (darker away from the lamps) and break up the hair's highlights.
4. **The saloon is half empty** (tell 7, `760 330 400 140`): tables set with lamps and cups but no one at them, the back walls bare. Cause: dressing. Cheapest fix: put two or three seated drinkers at the far tables.
5. **Every lamp the same lamp** (tell 6, `690 230 590 100`): one sconce model copied at even spacing round every wall, and no barman in sight. Cause: dressing. Cheapest fix: vary the fixtures (a few unlit, a few askew, two kinds) and break the spacing.

## g
- 1 Flat light: FAIL (`0 0 1280 290`; `docs/screenshots/judge/2026-11-03_room_light_r2/g_ceiling.png`): the whole roof is lit pale and even to the ridge; the walls a uniform orange; you can't tell the light comes from the small lamps.
- 2 No atmosphere: FAIL (`400 280 480 200`; `docs/screenshots/judge/2026-11-03_room_light_r2/g_air.png`): the far end wall is as crisp and saturated as the bar beside you; no haze in the lamplight.
- 3 Too clean: FAIL (`150 480 620 240`; `docs/screenshots/judge/2026-11-03_room_light_r2/g_floor.png`): one even pine floor with scattered identical knots and no grime under the bar rail or round the spittoons; the held hand (`740 440 380 280`; `docs/screenshots/judge/2026-11-03_room_light_r2/g_hand.png`) smooth waxy pink.
- 4 Too straight: FAIL (`0 420 480 300`; `docs/screenshots/judge/2026-11-03_room_light_r2/g_bar.png`): the bar is one dead-straight box of stretched grain, and the rafters march in perfect parallel.
- 5 Floating objects: PASS (`230 440 300 260`: the stools and spittoons cast soft shadows).
- 6 Repetition: FAIL (`240 450 280 240`; `docs/screenshots/judge/2026-11-03_room_light_r2/g_stools.png`): the same stool at even spacing down the bar, the same sconce in a level row round the walls, and the bottles one bottle in rows.
- 7 Empty: FAIL (`480 470 460 250`; `docs/screenshots/judge/2026-11-03_room_light_r2/g_emptyfloor.png`): a long empty aisle of floor to a bare end wall, empty tables; the barman cut off at the left edge.
- 8 Scale tells: PASS (bar, stools, chairs and door agree).
- 9 Edges of the world: PASS (an interior; the gable gaps show only slits of night).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A pink plastic hand fills the bottom right** (tell 3, `740 440 380 280`): waxy, faceted, unshaded by the room, gripping the revolver by its frame with the grip nowhere in the palm. Cause: people. Cheapest fix: light the arm with the room's light and dark and seat the grip in the hand.
2. **A daylit roof over a lamplit room** (tell 1, `0 0 1280 290`): the ceiling is as bright at the ridge as over the lamps. Cause: light. Cheapest fix: let the fill die off with height so the roof goes dark above the lamps.
3. **The room is empty** (tell 7, `480 470 460 250`): a long bare aisle down the middle, tables set for no one. Cause: dressing. Cheapest fix: drinkers along the bar and at the far tables.
4. **No air** (tell 2, `400 280 480 200`): the end wall is sharp and saturated; no smoke catching the lamps. Cause: light. Cheapest fix: a warm indoor haze, thicker up high.
5. **One stool, one lamp, one bottle, repeated** (tell 6, `240 450 280 240`): the same stool at even spacing, the same sconce in a level row. Cause: dressing. Cheapest fix: vary and knock a few stools askew, mix the fixtures and bottles.

## h
- 1 Flat light: FAIL (`0 90 550 420`; `docs/screenshots/judge/2026-11-03_room_light_r2/h_walls.png`): the left wall is one saturated orange from floor to plate, evenly lit between the sconces; the floor's big cast shadow is the only real shadow shape.
- 2 No atmosphere: FAIL (`560 180 420 230`; `docs/screenshots/judge/2026-11-03_room_light_r2/h_air.png`): the back of the room, the stair and the doorway are as sharp and saturated as the near tables; no haze or smoke in the lamplight.
- 3 Too clean: FAIL (`880 360 400 360`; `docs/screenshots/judge/2026-11-03_room_light_r2/h_bartop.png`): the bar top is glossy pale pine with its grain stretched the whole length, no rings, scuffs or worn edge; the floor the same pine with the same knots throughout; the held hand (`740 440 340 280`; `docs/screenshots/judge/2026-11-03_room_light_r2/h_hand.png`) smooth pink plastic.
- 4 Too straight: FAIL (`0 0 1280 240`; `docs/screenshots/judge/2026-11-03_room_light_r2/h_rafters.png`): rafters, wall plates and the bar run in perfectly parallel, evenly spaced lines.
- 5 Floating objects: PASS (`100 380 380 260`: chairs and the table cast soft shadows on the boards).
- 6 Repetition: FAIL (`130 250 400 70`; `docs/screenshots/judge/2026-11-03_room_light_r2/h_paintings.png`): the same sconce at the same height and spacing, and the same small desert painting hung three times along the walls.
- 7 Empty: FAIL (`440 380 440 300`; `docs/screenshots/judge/2026-11-03_room_light_r2/h_floor.png`): a long bare floor and empty tables, one woman far off at the piano; nobody at the bar.
- 8 Scale tells: PASS (door, stair, stools and furniture agree).
- 9 Edges of the world: PASS (the open door shows a back room and a sliver of night sky; it holds together).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A pink plastic hand fills the bottom right** (tell 3, `740 440 340 280`): the hand is waxy and unshaded by the room, and it seems to hold the revolver by the cylinder with no grip in it; it is the first thing the eye meets. Cause: people. Cheapest fix: light and colour the arm with the room's warm light and dark, and seat the grip in the palm.
2. **Walls of one flat orange** (tell 1, `0 90 550 420`): the boards are equally bright between the lamps, so the sconces don't seem to be doing the lighting. Cause: light. Cheapest fix: tighten each sconce's pool and drop the wall's fill so the dark falls between them.
3. **No air** (tell 2, `560 180 420 230`): the far end is as crisp as the foreground; no smoke under the roof. Cause: light. Cheapest fix: a warm indoor haze, thicker up high, that the lamps glow in.
4. **The room is empty** (tell 7, `440 380 440 300`): set tables and a long bar with no drinkers. Cause: dressing. Cheapest fix: men at the bar and at two of the tables.
5. **Repeated pictures and lamps** (tell 6, `130 250 400 70`): the same painting hung three times and the same sconce at the same spacing. Cause: dressing. Cheapest fix: different pictures and frames, some hung crooked, and fixtures varied.

## i
- 1 Flat light: FAIL (`0 90 550 420`; `docs/screenshots/judge/2026-11-03_room_light_r2/i_walls.png`): the left wall is one saturated orange from floor to plate, evenly lit between the sconces; the floor's big cast shadow is the only real shadow shape.
- 2 No atmosphere: FAIL (`560 180 420 230`; `docs/screenshots/judge/2026-11-03_room_light_r2/i_air.png`): the back of the room, the stair and the doorway are as sharp and saturated as the near tables; no haze or smoke in the lamplight.
- 3 Too clean: FAIL (`880 360 400 360`; `docs/screenshots/judge/2026-11-03_room_light_r2/i_bartop.png`): the bar top is glossy pale pine with its grain stretched the whole length, no rings, scuffs or worn edge; the floor the same pine with the same knots throughout; the held hand (`740 440 340 280`; `docs/screenshots/judge/2026-11-03_room_light_r2/i_hand.png`) smooth pink plastic.
- 4 Too straight: FAIL (`0 0 1280 240`; `docs/screenshots/judge/2026-11-03_room_light_r2/i_rafters.png`): rafters, wall plates and the bar run in perfectly parallel, evenly spaced lines.
- 5 Floating objects: PASS (`100 380 380 260`: chairs and the table cast soft shadows on the boards).
- 6 Repetition: FAIL (`130 250 400 70`; `docs/screenshots/judge/2026-11-03_room_light_r2/i_paintings.png`): the same sconce at the same height and spacing, and the same small desert painting hung three times along the walls.
- 7 Empty: FAIL (`440 380 440 300`; `docs/screenshots/judge/2026-11-03_room_light_r2/i_floor.png`): a long bare floor and empty tables, one woman far off at the piano; nobody at the bar.
- 8 Scale tells: PASS (door, stair, stools and furniture agree).
- 9 Edges of the world: PASS (the open door shows a back room and a sliver of night sky; it holds together).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A pink plastic hand fills the bottom right** (tell 3, `740 440 340 280`): the hand is waxy and unshaded by the room, and it seems to hold the revolver by the cylinder with no grip in it; it is the first thing the eye meets. Cause: people. Cheapest fix: light and colour the arm with the room's warm light and dark, and seat the grip in the palm.
2. **Walls of one flat orange** (tell 1, `0 90 550 420`): the boards are equally bright between the lamps, so the sconces don't seem to be doing the lighting. Cause: light. Cheapest fix: tighten each sconce's pool and drop the wall's fill so the dark falls between them.
3. **No air** (tell 2, `560 180 420 230`): the far end is as crisp as the foreground; no smoke under the roof. Cause: light. Cheapest fix: a warm indoor haze, thicker up high, that the lamps glow in.
4. **The room is empty** (tell 7, `440 380 440 300`): set tables and a long bar with no drinkers. Cause: dressing. Cheapest fix: men at the bar and at two of the tables.
5. **Repeated pictures and lamps** (tell 6, `130 250 400 70`): the same painting hung three times and the same sconce at the same spacing. Cause: dressing. Cheapest fix: different pictures and frames, some hung crooked, and fixtures varied.

## j
- 1 Flat light: FAIL (`0 0 1280 290`; `docs/screenshots/judge/2026-11-03_room_light_r2/j_ceiling.png`): the whole roof is lit pale and even to the ridge; the walls a uniform orange; you can't tell the light comes from the small lamps.
- 2 No atmosphere: FAIL (`400 280 480 200`; `docs/screenshots/judge/2026-11-03_room_light_r2/j_air.png`): the far end wall is as crisp and saturated as the bar beside you; no haze in the lamplight.
- 3 Too clean: FAIL (`150 480 620 240`; `docs/screenshots/judge/2026-11-03_room_light_r2/j_floor.png`): one even pine floor with scattered identical knots and no grime under the bar rail or round the spittoons; the held hand (`740 440 380 280`; `docs/screenshots/judge/2026-11-03_room_light_r2/j_hand.png`) smooth waxy pink.
- 4 Too straight: FAIL (`0 420 480 300`; `docs/screenshots/judge/2026-11-03_room_light_r2/j_bar.png`): the bar is one dead-straight box of stretched grain, and the rafters march in perfect parallel.
- 5 Floating objects: PASS (`230 440 300 260`: the stools and spittoons cast soft shadows).
- 6 Repetition: FAIL (`240 450 280 240`; `docs/screenshots/judge/2026-11-03_room_light_r2/j_stools.png`): the same stool at even spacing down the bar, the same sconce in a level row round the walls, and the bottles one bottle in rows.
- 7 Empty: FAIL (`480 470 460 250`; `docs/screenshots/judge/2026-11-03_room_light_r2/j_emptyfloor.png`): a long empty aisle of floor to a bare end wall, empty tables; the barman barely in frame at the left.
- 8 Scale tells: PASS (bar, stools, chairs and door agree).
- 9 Edges of the world: PASS (an interior; the gable gaps show only slits of night).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A pink plastic hand fills the bottom right** (tell 3, `740 440 380 280`): waxy, faceted, unshaded by the room, gripping the revolver by its frame with the grip nowhere in the palm. Cause: people. Cheapest fix: light the arm with the room's light and dark and seat the grip in the hand.
2. **A daylit roof over a lamplit room** (tell 1, `0 0 1280 290`): the ceiling is as bright at the ridge as over the lamps. Cause: light. Cheapest fix: let the fill die off with height so the roof goes dark above the lamps.
3. **The room is empty** (tell 7, `480 470 460 250`): a long bare aisle down the middle, tables set for no one. Cause: dressing. Cheapest fix: drinkers along the bar and at the far tables.
4. **No air** (tell 2, `400 280 480 200`): the end wall is sharp and saturated; no smoke catching the lamps. Cause: light. Cheapest fix: a warm indoor haze, thicker up high.
5. **One stool, one lamp, one bottle, repeated** (tell 6, `240 450 280 240`): the same stool at even spacing, the same sconce in a level row. Cause: dressing. Cheapest fix: vary and knock a few stools askew, mix the fixtures and bottles.

## k
- 1 Flat light: FAIL (`0 0 1280 230`; `docs/screenshots/judge/2026-11-03_room_light_r2/k_ceiling.png`): the pine ceiling is lit pale and even from end to end, as bright as the walls, with no dark falling off above the lamps; the blacks sit at a warm mid-brown, so the room reads daylit, not lamplit.
- 2 No atmosphere: FAIL (`600 90 680 330`; `docs/screenshots/judge/2026-11-03_room_light_r2/k_air.png`): the far gable wall 15 m off is as crisp and saturated as the near boards; no smoke or haze hangs round the sconces or under the roof.
- 3 Too clean: FAIL (`40 470 360 250`; `docs/screenshots/judge/2026-11-03_room_light_r2/k_floor.png`): the floorboards are one even pine with the same scattered dark knots, a dotted seam line running across them, no grime at the foot of the bar or worn path to it; her skin (`400 250 340 470`; `docs/screenshots/judge/2026-11-03_room_light_r2/k_skin.png`) is one smooth orange plastic.
- 4 Too straight: FAIL (`220 220 330 280`; `docs/screenshots/judge/2026-11-03_room_light_r2/k_bar.png`): the bar, back bar and walls are clean boxes with dead-level tops and plumb walls; nothing sags, leans or is patched.
- 5 Floating objects: PASS (`330 380 560 330`: the stools, chair and table each cast a soft shadow onto the boards).
- 6 Repetition: FAIL (`690 230 590 100`; `docs/screenshots/judge/2026-11-03_room_light_r2/k_sconces.png`): the same brass sconce repeated at the same height and spacing round every wall, the same chair everywhere, and the back bar's bottles are one bottle in rows.
- 7 Empty: FAIL (`760 330 400 140`; `docs/screenshots/judge/2026-11-03_room_light_r2/k_tables.png`): the back half of the saloon has empty tables, bare walls with one deer head and one dark picture, and nobody sitting anywhere.
- 8 Scale tells: PASS (bar, stools, chairs and the people read the right size for each other).
- 9 Edges of the world: PASS (an interior; the gable's board gaps show only thin slits of night).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The whole room is one orange at one brightness** (tell 1, `0 0 1280 230`): the ceiling and walls are lit as evenly as a showroom; nothing tells you the light comes from a dozen small oil flames. Cause: light. Cheapest fix: let the fill die off with height and distance from the lamps, so the roof and corners go nearly black.
2. **No air in the lamplight** (tell 2, `600 90 680 330`): the far wall is pin-sharp; no smoke, haze or glow round the sconces, which is half of what makes a saloon at night. Cause: light. Cheapest fix: a thin warm volumetric haze indoors, thicker under the roof, that catches each lamp.
3. **A woman's back fills the middle of the frame** (tell 3, `400 250 340 470`): she stands square to camera blocking the view, her skin one smooth orange plastic and her hair a single red mass. Cause: people. Cheapest fix: shade her skin with the room's light and shadow (darker away from the lamps) and break up the hair's highlights.
4. **The saloon is half empty** (tell 7, `760 330 400 140`): tables set with lamps and cups but no one at them, the back walls bare. Cause: dressing. Cheapest fix: put two or three seated drinkers at the far tables.
5. **Every lamp the same lamp** (tell 6, `690 230 590 100`): one sconce model copied at even spacing round every wall; the barman is hidden behind her. Cause: dressing. Cheapest fix: vary the fixtures and break the spacing.

## l
- 1 Flat light: FAIL (`0 0 1280 230`; `docs/screenshots/judge/2026-11-03_room_light_r2/l_ceiling.png`): the pine ceiling is lit pale and even from end to end, as bright as the walls, with no dark falling off above the lamps; the blacks sit at a warm mid-brown, so the room reads daylit, not lamplit.
- 2 No atmosphere: FAIL (`600 90 680 330`; `docs/screenshots/judge/2026-11-03_room_light_r2/l_air.png`): the far gable wall 15 m off is as crisp and saturated as the near boards; no smoke or haze hangs round the sconces or under the roof.
- 3 Too clean: FAIL (`40 470 360 250`; `docs/screenshots/judge/2026-11-03_room_light_r2/l_floor.png`): the floorboards are one even pine with the same scattered dark knots, a dotted seam line running across them, no grime at the foot of the bar or worn path to it; her skin (`400 250 340 470`; `docs/screenshots/judge/2026-11-03_room_light_r2/l_skin.png`) is one smooth orange plastic.
- 4 Too straight: FAIL (`220 220 330 280`; `docs/screenshots/judge/2026-11-03_room_light_r2/l_bar.png`): the bar, back bar and walls are clean boxes with dead-level tops and plumb walls; nothing sags, leans or is patched.
- 5 Floating objects: PASS (`330 380 560 330`: the stools, chair and table each cast a soft shadow onto the boards).
- 6 Repetition: FAIL (`690 230 590 100`; `docs/screenshots/judge/2026-11-03_room_light_r2/l_sconces.png`): the same brass sconce repeated at the same height and spacing round every wall, the same chair everywhere, and the back bar's bottles are one bottle in rows.
- 7 Empty: FAIL (`760 330 400 140`; `docs/screenshots/judge/2026-11-03_room_light_r2/l_tables.png`): the back half of the saloon has empty tables, bare walls with one deer head and one dark picture, and nobody sitting anywhere.
- 8 Scale tells: PASS (bar, stools, chairs and the people read the right size for each other).
- 9 Edges of the world: PASS (an interior; the gable's board gaps show only thin slits of night).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The whole room is one orange at one brightness** (tell 1, `0 0 1280 230`): the ceiling and walls are lit as evenly as a showroom; nothing tells you the light comes from a dozen small oil flames. Cause: light. Cheapest fix: let the fill die off with height and distance from the lamps, so the roof and corners go nearly black.
2. **No air in the lamplight** (tell 2, `600 90 680 330`): the far wall is pin-sharp; no smoke, haze or glow round the sconces, which is half of what makes a saloon at night. Cause: light. Cheapest fix: a thin warm volumetric haze indoors, thicker under the roof, that catches each lamp.
3. **A woman's back fills the middle of the frame** (tell 3, `400 250 340 470`): she stands square to camera blocking the view, her skin one smooth orange plastic and her hair a single red mass. Cause: people. Cheapest fix: shade her skin with the room's light and shadow (darker away from the lamps) and break up the hair's highlights.
4. **The saloon is half empty** (tell 7, `760 330 400 140`): tables set with lamps and cups but no one at them, the back walls bare. Cause: dressing. Cheapest fix: put two or three seated drinkers at the far tables.
5. **A dark pole slashes across the view** (tell 3, `790 400 230 320`; `docs/screenshots/judge/2026-11-03_room_light_r2/l_pole.png`): the held weapon is a smooth blurry tube crossing the table, and the barman loiters by the doorway, away from the bar. Cause: camera. Cheapest fix: lower and angle the held weapon so it sits in the bottom corner and reads as a gun.

## Ranking
From least to most cheap-looking: b, h, i, a, k, f, d, g, j, c, e, l
