# Cheap judge, 2026-11-03_cheap_r2

## a
- 1 Flat light: FAIL (`0 0 1280 230`, the ceiling as bright as the floor; `a_flat_ceiling.png`)
- 2 No atmosphere: FAIL (`620 180 540 260`, the back wall as crisp as the near table, no smoke in the lamplight; `a_backwall.png`)
- 3 Too clean: FAIL (`40 450 720 270`, the floor evenly lit planks with no tracked dirt by the bar or the door; `a_floor.png`)
- 4 Too straight: FAIL (`0 0 1280 230`, rafters evenly spaced and dead straight, walls plumb, the bar ruled; `a_flat_ceiling.png`)
- 5 Floating objects: FAIL (`330 380 180 100`, bar stools with no contact shadow on the floor; `a_stools.png`)
- 6 Repetition: FAIL (`680 260 600 60`, the same brass sconce repeated in rows on every wall; `a_sconces.png`)
- 7 Empty: FAIL (`620 180 540 260`, a hall the size of a barn with one barman, one card table set, a bare back wall; `a_backwall.png`)
- 8 Scale tells: FAIL (`620 180 540 260`, a ceiling three storeys up, the deer head a speck on the wall, the tables small in the hall; `a_backwall.png`)
- 9 Edges of the world: PASS (the gable's board gaps read as a barn's)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Everything the same orange** (tell 1, `0 0 1280 720`): ceiling, walls, floor and skin all in one warm wash; no pool of dark between the lamps, so you can't tell which lamp lights what. Cause: light. Cheapest fix: drop the room's fill hard so the ceiling and the corners between sconces go near black.
2. **A huge empty barn** (tell 7, `620 180 540 260`): two tables and a deer head in a hall that would hold forty men; nobody drinks, nothing on the walls between the sconces. Cause: dressing. Cheapest fix: put people at the tables and frames, shelves or posters on the back wall.
3. **No air** (tell 2, `620 180 540 260`): the far wall is as sharp and saturated as the table in front of you; lamps have no glow in smoke. Cause: light. Cheapest fix: a thin warm haze that thickens with distance and blooms round each flame.
4. **Sconce wallpaper** (tell 6, `680 260 600 60`): a dozen identical brass lamps at one height in even rows. Cause: dressing. Cheapest fix: fewer lamps, of two or three kinds, at uneven spacing.
5. **The woman's skin flat and blown** (tell 1, `390 430 330 290`): shoulders and arms one bright orange with no form shadow, the hair a single red mass. Cause: people. Cheapest fix: let her skin take the room's darkness: a key from the nearest lamp, the far side in shade.

## b
- 1 Flat light: FAIL (`380 0 520 300`, the roof boards lit evenly end to end; `b_ceiling.png`)
- 2 No atmosphere: FAIL (`400 290 480 200`, the back wall sharp and saturated, no haze round the lamps; `b_backwall.png`)
- 3 Too clean: FAIL (`0 420 480 300`, the bar front's grain uniform from end to end, no kick marks or grime at its foot; `b_bar.png`)
- 4 Too straight: FAIL (`380 0 520 300`, perfectly even rafters and a ruler-straight bar; `b_ceiling.png`)
- 5 Floating objects: FAIL (`240 450 260 230`, stools and the spittoon with almost no contact shadow; `b_stools.png`)
- 6 Repetition: FAIL (`80 260 880 140`, the same sconce down both walls, the same stool repeated; `b_sconces.png`)
- 7 Empty: FAIL (`400 290 480 200`, a long hall with nobody in it, the back wall a bare plane; `b_backwall.png`)
- 8 Scale tells: FAIL (`400 290 480 200`, the barn-height ceiling dwarfs the bar and tables; `b_backwall.png`)
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The player's hand** (tell 3, `770 520 330 200`): a smooth pink low-poly hand with faceted shading and a gun grip whose texture smears into vertical streaks; it is the nearest thing on screen and it reads unfinished. Cause: material. Cheapest fix: repaint the hand with the world's darker, dirtier skin and fix the grip's stretched UVs.
2. **Nobody here** (tell 7, `400 290 480 200`): a vast saloon with not one person, bottles lined up but no glasses out, no coats on hooks. Cause: dressing. Cheapest fix: people, or at least the leavings of people (glasses, cards, a hat) on the tables and bar.
3. **One even orange** (tell 1, `380 0 520 300`): the roof is as lit as the floor, so the sconces look like decorations, not light sources. Cause: light. Cheapest fix: let the roof fall to dark above the lamp line.
4. **Barn proportions** (tell 8, `400 290 480 200`): the gable rises like a hay barn's; the bar, tables and deer head look toy-sized under it. Cause: geometry. Cheapest fix: a lower ceiling or a gallery to break the height.
5. **Stools stuck on, not standing** (tell 5, `240 450 260 230`): legs meet the boards with no darkening, so they float. Cause: light. Cheapest fix: contact shadow (AO) under the furniture.

## c
- 1 Flat light: FAIL (`0 0 1280 230`, the roof lit evenly; `c_flat_ceiling.png`)
- 2 No atmosphere: FAIL (`620 200 520 240`, the back wall crisp, no smoke; `c_backwall.png`)
- 3 Too clean: FAIL (`40 470 720 250`, floor clean and even, no wear in front of the bar; `c_floor.png`)
- 4 Too straight: FAIL (`0 0 1280 230`, rafters, walls and bar all ruled; `c_flat_ceiling.png`)
- 5 Floating objects: FAIL (`220 360 290 140`, stools at the bar without contact shadow; `c_bar.png`)
- 6 Repetition: FAIL (`680 280 600 60`, the same sconce in rows; `c_sconces.png`)
- 7 Empty: FAIL (`620 200 520 240`, one man standing in a hall built for dozens; `c_backwall.png`)
- 8 Scale tells: FAIL (`620 200 520 240`, the barn-high room shrinks everything in it; `c_backwall.png`)
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Flat orange wash** (tell 1, `0 0 1280 720`): the same as a: every surface lit alike, no darks, no direction. Cause: light. Cheapest fix: darken the fill so the lamps make pools.
2. **One man in a barn** (tell 7, `590 300 120 180`): the barman stands in the open floor past the end of his bar, doing nothing; the rest of the room is empty. Cause: dressing. Cheapest fix: put him behind the bar at work and fill two tables.
3. **Lamps without air** (tell 2, `620 200 520 240`): the sconces have small glows but no haze or smoke catches them. Cause: light. Cheapest fix: a warm volumetric haze.
4. **Repeated sconces and chairs** (tell 6, `680 280 600 60`): identical lamps in rows; every chair the same. Cause: dressing. Cheapest fix: vary the lamp kinds and break the spacing.
5. **The subtitle carries the life** (tell 7, `500 660 280 30`): the woman's "Lord. Lord, lord." is the only sign anything is happening; nothing in the picture backs it up. Cause: people. Cheapest fix: give her and the barman something to do with their hands (a tray, a glass, a rag).

## d
- 1 Flat light: PASS (the sun has a direction; horses and men cast shadows down the street)
- 2 No atmosphere: PASS (the far street and the mesas soften a little; could use more dust)
- 3 Too clean: FAIL (`1120 140 160 200`, the jail's pale front a blotch of grey squares with no boards, no dirt at its foot; `d_jail_wall.png`)
- 4 Too straight: FAIL (`300 300 400 420`, the wheel ruts two clean parallel ribbons running dead straight to the vanishing point; `d_ruts.png`)
- 5 Floating objects: PASS (feet and hooves have shadows)
- 6 Repetition: FAIL (`840 460 320 150`, the same faceted grey pebble scattered evenly over the whole street; `d_pebbles.png`)
- 7 Empty: PASS (people, horses, a wagon in the distance)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (the mesas close the street)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Plastic pebbles** (tell 6, `840 460 320 150`): low-poly grey stones with hard facets and a cool sheen, sprinkled evenly like a scatter tool; they are the biggest things in the foreground and they look like a default asset. Cause: material. Cheapest fix: half as many, painted in the ground's colour, half sunk in the dirt.
2. **The jail's front is noise** (tell 3, `1120 140 160 200`): a pale blue-grey patchwork with no board lines or weathering, unlike the wood beside it. Cause: material. Cheapest fix: give it the same painted boards as its neighbours.
3. **Ruler-straight ruts** (tell 4, `300 300 400 420`): two even dark ribbons from the camera to the horizon, like rails. Cause: geometry. Cheapest fix: let them wander and break, with hoof-churned dirt between.
4. **The far fronts all one cold grey** (tell 6, `420 140 440 170`): the false fronts down the street share one blue-grey tone and similar sign boards. Cause: material. Cheapest fix: vary the paint (a red, a cream, bare wood) building to building.
5. **Clean air at noon** (tell 2, `420 140 440 170`): a dusty street with nothing kicked up; the distance is only slightly softer. Cause: light. Cheapest fix: a low warm dust haze along the street.

## e
- 1 Flat light: PASS (low sun ahead, long shadows, rays down the street)
- 2 No atmosphere: PASS (haze and rays at the street's end)
- 3 Too clean: FAIL (`760 440 330 280`, the player's hand smooth pink plastic with faceted shading and a streaked grip; `e_hand.png`)
- 4 Too straight: PASS (the fronts sag a little, the ruts curve)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 340 1280 180`, the same bay horse with the same saddle five times along the street; `e_horses.png`)
- 7 Empty: PASS (people on the porch and in the street, horses tied, a wagon)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The hand again** (tell 3, `760 440 330 280`): a bright pink low-poly hand, lit differently from everything behind it, with the grip texture stretched into stripes; it sits in the middle of a nice frame and cheapens it. Cause: material. Cheapest fix: repaint and light the viewmodel with the scene (the low warm sun from the front, the hand's top in shade).
2. **Clone horses** (tell 6, `0 340 1280 180`): five of the same bay, same saddle, same white socks, in near-identical idle poses. Cause: dressing. Cheapest fix: two or three coat colours and different tack.
3. **The porch man is a mannequin** (tell 7, `140 290 270 150`): standing square, arms hanging, staring at the camera, dark against the lit wall. Cause: people. Cheapest fix: a lean on the post or a seat on the bench.
4. **One orange over everything** (minor, tell 1, `0 0 1280 720`): sky, wood, dirt and skin all pushed to the same amber, so the materials stop reading apart. Cause: light. Cheapest fix: let the shade side of the fronts go cooler and darker.
5. **The sky outshines the town** (minor, tell 9, `400 0 880 300`): a dense, very busy painted sky with more detail and contrast than the street under it; it reads pasted on. Cause: light. Cheapest fix: soften and darken the sky's upper clouds so the street is the subject.

## f
- 1 Flat light: PASS (low warm sun, shadows on the road, lit lanterns on the porch)
- 2 No atmosphere: PASS (the mesas fade in the distance)
- 3 Too clean: PASS (worn boards, dirt, dry grass)
- 4 Too straight: PASS
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`160 105 170 145`, two identical bays with the same saddle side by side; `f_frame1.png`)
- 7 Empty: PASS (men on the porch, a rider)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (a desert plain to the mesas, thin but believable)
- 10 Stiff people: FAIL (`1126 105 200 160`, the horses hold the same pose through all eight frames while men pop in and out on the porch; `f_frame3.png`)
- **Verdict: good indie**
1. **Frozen horses** (tell 10, `160 105 170 145` in each frame): across eight frames the two horses barely shift: no head toss, no tail swish, no weight change, like props. Cause: people. Cheapest fix: an idle cycle with a head drop and a hind-leg rest, offset per horse.
2. **People pop rather than move** (tell 10, `1126 105 200 160`): men appear behind the horses and on the porch between frames without visible steps. Cause: people. Cheapest fix: check the walk actually plays (and isn't culled or snapping) near the porch.
3. **Twin horses** (tell 6, `160 105 170 145`): the same model and colour twice, side by side. Cause: dressing. Cheapest fix: a second coat colour.
4. **Glossy uniform coats** (minor, tell 3, `160 105 170 145`): the horses are smooth faceted orange with no dust or dried sweat, cleaner than the porch behind them. Cause: material. Cheapest fix: dust their legs and bellies.
5. **A thin middle distance** (minor, tell 9, `0 95 330 50`): a flat pale plain with a few dark scrub dots between the road and the mesas. Cause: dressing. Cheapest fix: a fence line, a wagon or a windmill out there.

## Ranking
From least to most cheap-looking: e, f, d, c, a, b
