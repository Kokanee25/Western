# Cheap judge, 2026-11-04_cheap_r1_saloon

## a
- 1 Flat light: FAIL (`0 0 1280 230`, the ceiling and upper walls; `a_a_ceiling.png`): the roof boards read pale cream as if daylit though nothing lights them; the whole room sits in one amber tone, the darkest corners a warm brown, never black.
- 2 No atmosphere: FAIL (`600 180 640 260`; `a_a_walls_wash.png`): the far wall and its sconces are as crisp as the near table; no smoke or haze in the lamplight of a saloon at night.
- 3 Too clean: FAIL (`40 420 600 300`; `a_a_floor.png`): spotless planks with even knots, no sawdust, mud, spills or a trodden path; the walls the same mottle end to end.
- 4 Too straight: FAIL (`0 0 1280 230`; `a_a_ceiling.png`): ruler-straight rafters at even spacing, walls perfectly plumb, the bar a clean box.
- 5 Floating objects: FAIL (`230 250 330 240`; `a_a_back_bar.png`): the bar stools' feet and the bar's base meet the floor with no contact darkening.
- 6 Repetition: FAIL (`600 180 640 260`; `a_a_walls_wash.png`): the same sconce again and again, each throwing the identical arch-shaped shadow under it; rows of identical bottles on the back bar.
- 7 Empty: FAIL (`40 380 1240 340`; `a_a_empty.png`): a barn-sized floor with two tables, a piano box and one man half out of frame; nothing on the tables but a cup and a bottle.
- 8 Scale tells: FAIL (`1050 320 230 230`; `a_a_right_wall.png`): the piano is a squat box with wood grain blown up to plank size; the board leaning on the wall has knots as big as fists; the hall is twice the height its tables and doors suggest.
- 9 Edges of the world: N/A (interior; the gable gaps read fine).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **One orange wash, a daylit ceiling** (tell 1, `0 0 1280 230`): everything — wall, floor, roof, skin — is the same amber; the roof boards are bright as noon in a lamplit room, so the light has no story. Cause: light. Cheapest fix: cut the room's ambient fill so the ceiling and the spaces between lamps drop to near black.
2. **An empty barn** (tell 7, `40 380 1240 340`): a huge plank floor with almost nothing on it; nobody lives or drinks here. Cause: dressing. Cheapest fix: fill the floor with more tables, chairs pulled out, cards, glasses, coats, a spittoon, and a few drinkers.
3. **Stamped sconces** (tell 6, `600 180 640 260`): a regimented row of identical lamps, each with the same shadow arch painted beneath it. Cause: light. Cheapest fix: fewer, varied fixtures, or turn off their bracket shadows.
4. **Clean, even floor and walls** (tell 3, `40 420 600 300`): no grime at the wall bases, no wear by the bar, the wall's mottle a blurry uniform pattern. Cause: material. Cheapest fix: a dirt and wear layer where feet go and where walls meet floor.
5. **Wrong-scale grain on the piano and boards** (tell 8, `1050 320 230 230`): the texture is sized for a wall and reads as toy-like on furniture. Cause: material. Cheapest fix: set the grain's scale per prop (or replace the piano with a modelled one).

## b
- 1 Flat light: PASS (the floor drops dark between the lamp pools and you can say where the light comes from; the ceiling is still too bright, see reason 2).
- 2 No atmosphere: FAIL (`400 280 520 240`; `b_b_end_wall.png`): the sconce glows are bloom and lens streaks on a clear room; no smoke hangs in the light, the end wall is as sharp as the bar.
- 3 Too clean: FAIL (`160 460 900 260`; `b_b_empty_floor.png`): a long, clean floor; the bar's front even, no scuffs at the foot rail.
- 4 Too straight: FAIL (`0 0 1280 200`; `b_b_roof.png`): perfectly regular rafters and a dead-straight bar running into the distance.
- 5 Floating objects: FAIL (`230 440 300 280`; `b_b_stools.png`): the stools stand on the floor with no shadow or darkening at their feet; a pale streak of light lies across the boards with nothing to cast it.
- 6 Repetition: FAIL (`0 280 480 220`; `b_b_bottles.png`): hundreds of the same few bottles in grid rows; the same sconce and same arch shadow along both walls.
- 7 Empty: FAIL (`160 460 900 260`; `b_b_empty_floor.png`): one barkeep bent over, a far table empty, the rest bare boards.
- 8 Scale tells: FAIL (`400 280 520 240`; `b_b_end_wall.png`): the hall's roof is far too high for the small tables, stools and the tiny window on the end wall.
- 9 Edges of the world: N/A (interior).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A faceted, plastic hand** (tell 3, `760 540 360 180`): the player's own hand fills the foreground in flat pink polygons with blocky white nails; it is the first thing you see and it reads as an early-2000s mod. Cause: people. Cheapest fix: smooth the arm's normals and give it a real skin texture (knuckles, veins, dirt).
2. **No air in the lamplight** (tell 2, `400 280 520 240`): bright lens streaks round each sconce but no haze, so the room looks like a clear box with stickers of light. Cause: light. Cheapest fix: a low, warm volumetric fog so the lamps glow in the air.
3. **Empty room** (tell 7, `160 460 900 260`): the long floor has nothing on it and no one in it but a barkeep with his face in the bar. Cause: dressing. Cheapest fix: drinkers at the bar, clutter on the floor and tables.
4. **Grid of identical bottles** (tell 6, `0 280 480 220`): a shelf wall of clones, evenly spaced. Cause: dressing. Cheapest fix: thin them out and vary heights, labels, gaps, a few lying down.
5. **Stools with no contact** (tell 5, `230 440 300 280`): the stools float on the boards and a stray pale light streak cuts the floor. Cause: light. Cheapest fix: contact shadows/AO at the feet and remove the stray streak.

## c
- 1 Flat light: FAIL (`0 80 560 300`; `c_c_left_wall.png`): the left wall glows evenly amber its whole length; the ceiling bright cream; the blacks warm brown.
- 2 No atmosphere: FAIL (`380 300 440 260`; `c_c_empty.png`): the far room and doorway are as sharp as the foreground; no smoke in the light.
- 3 Too clean: FAIL (`860 360 420 360`; `c_c_bar.png`): the bar top is a single clean slab of stretched grain with no rings, wear or spills; the floor spotless.
- 4 Too straight: FAIL (`860 360 420 360`; `c_c_bar.png`): the bar is a perfect box, the rafters and wall boards ruler-straight.
- 5 Floating objects: FAIL (`100 380 400 260`; `c_c_table.png`): chair and table feet sit on the boards with no contact darkening.
- 6 Repetition: FAIL (`0 80 560 300`; `c_c_left_wall.png`): two near-identical landscape paintings and a march of identical sconces with the same arch shadows.
- 7 Empty: FAIL (`380 300 440 260`; `c_c_empty.png`): one woman with her arms up in a far corner, otherwise empty tables and floor.
- 8 Scale tells: FAIL (`380 300 440 260`; `c_c_empty.png`): the doorway and piano are small against a wall and roof that tower over them.
- 9 Edges of the world: PASS (`560 220 260 200`; the door shows a building and night sky outside, it holds).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The faceted hand again** (tell 3, `760 540 360 180`): flat orange polygons and blocky nails front and centre. Cause: people. Cheapest fix: a smoothed, textured arm.
2. **One amber glow on every wall** (tell 1, `0 80 560 300`): the wall is evenly lit and smeared, the ceiling bright; the room has no darks to give the lamps meaning. Cause: light. Cheapest fix: drop the fill so light falls off between sconces.
3. **A near-empty saloon** (tell 7, `380 300 440 260`): a lone figure with her hands up in a big empty hall; the subtitle carries the drama, the room doesn't. Cause: dressing. Cheapest fix: more people and clutter, overturned chairs for the robbery.
4. **Clean, stretched bar top** (tell 3, `860 360 420 360`): stretched streaky grain, no glass rings or wear, a perfect box. Cause: material. Cheapest fix: a worn, stained top with a darker varnish and rounded edges.
5. **Furniture with no contact** (tell 5, `100 380 400 260`): chairs and the table look set down on the floor rather than standing on it. Cause: light. Cheapest fix: contact shadows/AO.

## d
- 1 Flat light: FAIL (`0 0 1280 250`; `d_d_ceiling.png`): as in the same view before: a cream, daylit-looking ceiling and the room in a single amber tone.
- 2 No atmosphere: FAIL (`600 180 640 260`; `d_d_walls.png`): no haze in the lamplight; the far wall crisp.
- 3 Too clean: FAIL (`40 440 600 280`; `d_d_floor.png`): spotless, even plank floor.
- 4 Too straight: FAIL (`0 0 1280 250`; `d_d_ceiling.png`): ruler-straight rafters and plumb walls.
- 5 Floating objects: FAIL (`230 270 330 240`; `d_d_back_bar.png`): stools and the bar base with no contact darkening.
- 6 Repetition: FAIL (`600 180 640 260`; `d_d_walls.png`): identical sconces with identical arch shadows; clone bottles.
- 7 Empty: FAIL (`40 440 600 280`; `d_d_floor.png`): a wide bare floor, two tables, one man by the woman.
- 8 Scale tells: FAIL (`1050 330 230 230`; `d_d_right_wall.png`): the box piano and the oversized grain on it and on the leaning board.
- 9 Edges of the world: N/A (interior).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **One orange wash, a daylit ceiling** (tell 1, `0 0 1280 250`): the roof is lit like noon and everything shares one amber colour. Cause: light. Cheapest fix: kill the ambient fill above the lamps.
2. **An empty barn** (tell 7, `40 440 600 280`): a big floor with almost nothing in it; the one man beside her only underlines the emptiness. Cause: dressing. Cheapest fix: tables, people and clutter.
3. **Stamped sconces and clone bottles** (tell 6, `600 180 640 260`): the same lamp and shadow shape over and over. Cause: light. Cheapest fix: vary or thin the fixtures.
4. **No air** (tell 2, `600 180 640 260`): no smoke or haze to soften the far wall. Cause: light. Cheapest fix: a low warm fog.
5. **Clean floor** (tell 3, `40 440 600 280`): no dirt, no path worn to the bar. Cause: material. Cheapest fix: a grime and wear layer.

## Ranking
From least to most cheap-looking: b, c, d, a
