# Cheap judge, 2026-11-03_room_light_r1

## a
- 1 Flat light: FAIL (`300 0 600 230`; `a_ceiling.png`): the whole roof is lit as evenly bright as the floor, though the only sources are small hanging lamps; no dark corners anywhere in a night interior
- 2 No atmosphere: FAIL (`540 120 520 300`; `a_back.png`): the far end of the hall is as crisp and saturated as the near tables; no smoke or haze in the lamplight
- 3 Too clean: FAIL (`300 480 600 240`; `a_floor.png`): the floor is one clean board texture end to end; no tracks, sawdust, spills or worn path to the bar
- 4 Too straight: FAIL (`0 0 1280 90`; `a_rafters.png`): rafters, wall seams and ceiling boards are ruler-straight and evenly spaced; nothing sags
- 5 Floating objects: FAIL (`100 440 380 200`; `a_chairs.png`): chair and table feet meet the floor with almost no contact darkening
- 6 Repetition: FAIL (`100 255 460 70`; `a_sconces.png`): the same twin wall sconce every few metres down both walls; identical chairs; the bottle wall one bottle cloned
- 7 Empty: FAIL (`150 330 700 330`; `a_empty.png`): a huge saloon with one small figure at the back; tables set but nobody at them
- 8 Scale tells: PASS (door, stair, stools and bar read right for each other)
- 9 Edges of the world: FAIL (`690 245 110 160`; `a_doorway.png`): the open back door shows a flat blue sky over a dark box; reads as a hole into nothing
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The whole room is one even orange** (tell 1, `300 0 600 230`): roof, walls and floor all glow the same; no pool of light falls off into dark, so the lamps don't seem to do anything. Cause: light. Cheapest fix: cut the ambient fill hard so the roof and corners drop to near black between the lamps.
2. **Walls look like a blown-up low-res texture** (tell 3, `0 90 260 330`, `a_wall.png`): big blurry blocks running across the board seams, not paint following the boards. Cause: material. Cheapest fix: make the squares follow each board (one value per board stretch) instead of a grid across them.
3. **Empty hall** (tell 7, `150 330 700 330`): a dozen chairs, one person far away. Cause: dressing. Cheapest fix: seat two or three men at the near table with cards and glasses.
4. **The player's hand is pink plastic** (tell 3, `730 430 360 290`, `a_hand.png`): smeared flat skin, no knuckles or shadow, the gun's frame a striped smear. Cause: material. Cheapest fix: paint the hand with a dark shadow side and knuckle creases, and darken it to the room's light.
5. **Cloned sconces in rows** (tell 6, `100 255 460 70`): the same fixture repeated at regular intervals. Cause: dressing. Cheapest fix: vary spacing, leave some unlit, swap in a second fixture type.

## b
- 1 Flat light: FAIL (`0 0 760 220`; `b_ceiling.png`): the roof boards are evenly bright with nothing lighting them that strongly; the blacks never go below a warm brown
- 2 No atmosphere: FAIL (`600 120 560 300`; `b_back.png`): no haze around the lamps; the far wall as clear as the near table
- 3 Too clean: FAIL (`40 440 360 280`; `b_floor.png`): the floor is clean knotted boards with no dirt where it meets the bar or wall
- 4 Too straight: FAIL (`0 0 760 220`; `b_ceiling.png`): ceiling boards and rafters perfectly regular
- 5 Floating objects: PASS (the table and chairs carry shadow under them, `700 380 270 330`)
- 6 Repetition: FAIL (`1060 220 220 100`; `b_sconces.png`): the same paired sconces down every wall; the same chair
- 7 Empty: PASS (the woman, a barkeep, a set table with lamp, cup and bottle; it reads as occupied)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`600 120 560 300`; `b_back.png`): blue pinpricks of sky show through the gable boards like holes in the model
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Flat, even warmth** (tell 1, `0 0 760 220`): the roof is as lit as the tables; there's no shape to the light. Cause: light. Cheapest fix: lower the room's fill so only what's near a flame is bright.
2. **The held weapon is a featureless dark tube** (tell 3, `780 400 240 320`, `b_barrel.png`): no hand, no shape, it reads as a stick poking into frame. Cause: material. Cheapest fix: show the hand and the gun's lock or stock, or lower it out of the view.
3. **Blocky wall texture** (tell 3, `600 120 560 300`): the walls are big soft squares running across the boards. Cause: material. Cheapest fix: one value per board, so the squares follow the wood.
4. **Light leaks in the gable** (tell 9, `600 120 560 300`): blue specks through the roof boards. Cause: geometry. Cheapest fix: close the gaps or put a dark sheathing behind the boards.
5. **Cloned sconces** (tell 6, `1060 220 220 100`). Cause: dressing. Cheapest fix: vary spacing and type, leave some dark.

## c
- 1 Flat light: FAIL (`0 0 640 240`; `c_ceiling.png`): the roof is lit like a sunlit deck; nothing dark between the lamps
- 2 No atmosphere: FAIL (`380 280 520 200`; `c_backwall.png`): no air in the lamplight; the far wall crisp
- 3 Too clean: FAIL (`0 600 640 120`; `c_floor.png`): floor uniform clean boards, no worn path along the bar
- 4 Too straight: FAIL (`0 0 640 240`; `c_ceiling.png`): rafters, purlins, bar front perfectly straight and regular
- 5 Floating objects: PASS (stools and spittoon have light contact shading, `230 430 260 260`)
- 6 Repetition: FAIL (`380 280 520 200`; `c_backwall.png`): identical sconces evenly placed, the back wall a single texture
- 7 Empty: FAIL (`380 450 560 270`; `c_empty.png`): a long empty floor; the barkeep cut off at the edge, nobody else
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`380 140 520 160`; `c_gable.png`): blue sky specks through the gable boards
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The roof glows evenly** (tell 1, `0 0 640 240`): most of the picture is evenly lit ceiling, which flattens the room. Cause: light. Cheapest fix: let the ceiling fall off to near black above the lamps' reach.
2. **Empty middle of the frame** (tell 7, `380 450 560 270`): a bare floor running to a bare wall. Cause: dressing. Cheapest fix: put people at the far table and along the bar.
3. **The back wall is one flat smeared plane** (tell 6, `380 280 520 200`): a wall-wide texture with sconce glows on it and a dark box in the middle. Cause: material. Cheapest fix: break it with a doorway, shelving or a dark wainscot.
4. **Pink plastic hand** (tell 3, `770 450 340 270`, `c_hand.png`): flat pink skin and smeared gun parts in the nearest, biggest object. Cause: material. Cheapest fix: darker, shaded hand painted in the room's warm light.
5. **Gable light leaks** (tell 9, `380 140 520 160`). Cause: geometry. Cheapest fix: dark backing behind the boards.

## d
- 1 Flat light: FAIL (`0 0 760 220`; `d_ceiling.png`): roof evenly bright, the room's darks lifted to brown
- 2 No atmosphere: FAIL (`600 120 560 300`; `d_back.png`): no haze around the lamps
- 3 Too clean: FAIL (`40 440 360 280`; `d_floor.png`): clean boards, no dirt at the bar's foot
- 4 Too straight: FAIL (`0 0 760 220`; `d_ceiling.png`): perfectly regular ceiling
- 5 Floating objects: PASS (table and chairs shaded beneath)
- 6 Repetition: FAIL (`1060 220 220 100`; `d_sconces.png`): the same sconces in rows
- 7 Empty: PASS (the woman, a man in a waistcoat by the bar, a laid table)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`600 120 560 300`; `d_back.png`): blue specks through the gable
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Even, shapeless light** (tell 1, `0 0 760 220`). Cause: light. Cheapest fix: drop the ambient so the lamps make pools.
2. **Blocky walls** (tell 3, `600 120 560 300`): soft grid squares across the boards. Cause: material. Cheapest fix: squares that follow the boards.
3. **No air** (tell 2, `600 120 560 300`): a smoky saloon with perfectly clear air. Cause: light. Cheapest fix: a faint warm haze that gathers round each lamp and up under the roof.
4. **Clean floor** (tell 3, `40 440 360 280`). Cause: material. Cheapest fix: darken the floor along the bar's foot and the walls, a worn path to the door.
5. **Gable light leaks** (tell 9, `600 120 560 300`). Cause: geometry. Cheapest fix: dark backing behind the boards.

## e
- 1 Flat light: FAIL (`0 0 760 220`; `e_ceiling.png`): roof evenly bright; the whole frame washed lighter than the others' darks
- 2 No atmosphere: FAIL (`600 120 560 300`; `e_back.png`)
- 3 Too clean: FAIL (`40 440 360 280`; `e_floor.png`): clean boards, and washed a pinkish lilac
- 4 Too straight: FAIL (`0 0 760 220`; `e_ceiling.png`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`1060 220 220 100`; `e_sconces.png`)
- 7 Empty: PASS (the woman, the barkeep, a laid table)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`600 120 560 300`; `e_back.png`): blue specks through the gable
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A pink-lilac wash over the floor and walls** (tell 1, `40 440 360 280`): the near floor goes mauve, as if a colour grade slipped; it reads as a wrong filter, not lamplight. Cause: light. Cheapest fix: pull the magenta out of the grade so the wood stays warm brown.
2. **Lifted, even light** (tell 1, `0 0 760 220`): brighter than the scene needs, no darks. Cause: light. Cheapest fix: lower the fill and exposure.
3. **The barkeep stands outside his bar against the wall** (tell 7, `190 300 120 160`, `e_barkeep.png`): standing at the bar's end doing nothing, his arm through the counter's edge. Cause: people. Cheapest fix: put him behind the bar with a rag or glass.
4. **Featureless dark tube for a weapon** (tell 3, `780 400 240 320`, `e_barrel.png`). Cause: material. Cheapest fix: show the hand and the gun's lock.
5. **Cloned sconces** (tell 6, `1060 220 220 100`). Cause: dressing. Cheapest fix: vary and thin them.

## f
- 1 Flat light: FAIL (`300 0 600 230`; `f_ceiling.png`): roof as bright as the floor, no dark corners
- 2 No atmosphere: FAIL (`540 120 520 300`; `f_back.png`)
- 3 Too clean: FAIL (`300 480 600 240`; `f_floor.png`)
- 4 Too straight: FAIL (`300 0 600 230`; `f_ceiling.png`)
- 5 Floating objects: FAIL (`100 440 380 200`; `f_chairs.png`): chair feet with little contact darkening
- 6 Repetition: FAIL (`100 255 460 70`; `f_sconces.png`)
- 7 Empty: FAIL (`150 330 700 330`; `f_empty.png`): one figure in a big hall
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`690 245 110 160`; `f_doorway.png`): the back door opens onto a flat blue sky over a dark box
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **One even orange everywhere** (tell 1, `300 0 600 230`). Cause: light. Cheapest fix: cut the ambient so the lamps make pools and the roof goes dark.
2. **Walls of blurry squares** (tell 3, `0 90 260 330`, `f_wall.png`). Cause: material. Cheapest fix: squares that follow the boards.
3. **An empty hall** (tell 7, `150 330 700 330`). Cause: dressing. Cheapest fix: men at the near table.
4. **Pink plastic hand** (tell 3, `730 430 360 290`, `f_hand.png`). Cause: material. Cheapest fix: shade and darken the hand.
5. **The doorway into nothing** (tell 9, `690 245 110 160`). Cause: geometry. Cheapest fix: put a lit back room or a street front behind the door.

## g
- 1 Flat light: FAIL (`0 0 760 220`; `g_ceiling.png`)
- 2 No atmosphere: FAIL (`600 120 560 300`; `g_back.png`)
- 3 Too clean: FAIL (`40 440 360 280`; `g_floor.png`)
- 4 Too straight: FAIL (`0 0 760 220`; `g_ceiling.png`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`1060 220 220 100`; `g_sconces.png`)
- 7 Empty: FAIL (`520 260 200 260`; `g_hidden.png`): the only other person is hidden behind her hair, a white sleeve poking out; the barkeep's place empty
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`600 120 560 300`; `g_back.png`): blue specks through the gable
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A sleeve growing out of her hair** (tell 7, `520 260 200 260`): the man behind her shows only a white arm beside her head, so it reads as a glitch, not a second person. Cause: camera. Cheapest fix: frame or place him so his face shows, or so he's fully hidden.
2. **Even, shapeless light** (tell 1, `0 0 760 220`). Cause: light. Cheapest fix: lower the fill.
3. **Blocky walls** (tell 3, `600 120 560 300`). Cause: material. Cheapest fix: squares that follow the boards.
4. **A faint mauve cast on the near floor** (tell 1, `40 440 360 280`). Cause: light. Cheapest fix: keep the grade warm brown.
5. **Cloned sconces and gable leaks** (tell 6, `1060 220 220 100`). Cause: dressing. Cheapest fix: vary the fixtures and close the gable.

## h
- 1 Flat light: FAIL (`0 0 640 240`; `h_ceiling.png`)
- 2 No atmosphere: FAIL (`380 280 520 200`; `h_backwall.png`)
- 3 Too clean: FAIL (`0 600 640 120`; `h_floor.png`)
- 4 Too straight: FAIL (`0 0 640 240`; `h_ceiling.png`)
- 5 Floating objects: PASS (stools shaded at the feet)
- 6 Repetition: FAIL (`380 280 520 200`; `h_backwall.png`)
- 7 Empty: FAIL (`380 450 560 270`; `h_empty.png`): not one person in the frame; a long bar with nobody behind it
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`380 140 520 160`; `h_gable.png`): blue specks through the gable
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Nobody in the saloon** (tell 7, `380 450 560 270`): a lit bar, set tables and no one at all. Cause: dressing. Cheapest fix: a barkeep and two drinkers.
2. **The roof glows evenly** (tell 1, `0 0 640 240`). Cause: light. Cheapest fix: let it fall dark beyond the lamps.
3. **The back wall a single flat plane** (tell 6, `380 280 520 200`). Cause: material. Cheapest fix: break it with shelving, a door or a dark wainscot.
4. **Pink plastic hand** (tell 3, `770 450 340 270`, `h_hand.png`). Cause: material. Cheapest fix: a shaded, darker hand.
5. **Gable light leaks** (tell 9, `380 140 520 160`). Cause: geometry. Cheapest fix: dark backing behind the boards.

## Ranking
From least to most cheap-looking: d, b, e, g, a, f, c, h

---
(Pictures not kept, to save space: the round's stills are in
`experiments/light_lab/results/2026-11-03_r1/round1_sheet_before_after.jpg`; which letter is which
is in `sources.txt`.)
