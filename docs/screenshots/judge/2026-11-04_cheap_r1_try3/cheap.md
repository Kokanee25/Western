# Cheap judge, 2026-11-04_cheap_r1_try3

## a
- 1 Flat light: FAIL (`0 0 760 200`, `a_a_ceiling_flat.png`): the whole hall sits in one even orange wash. The ceiling boards are as bright and pale as the walls with no lamp to account for it, the shade under the roof never goes dark, and the blacks are lifted to brown everywhere. The sconces make pools on the walls, but nothing in the room is in real shadow.
- 2 No atmosphere: FAIL (`640 160 640 260`, `a_a_empty_back.png`): the far wall is a little softer, but no smoke, dust or beams catch the lamplight. The air between the lamps is clean.
- 3 Too clean: FAIL (`30 440 420 280`, `a_a_clean_floor.png`): the floor is the same knotty grain from wall to bar, with no dirt, spills, sawdust or tracked mud where people would walk. The walls carry one mottled stain end to end. The back-bar mirror is pale and made of leftover squares (`230 200 300 180`, `a_a_backbar.png`).
- 4 Too straight: FAIL (`0 0 760 200`, `a_a_ceiling_flat.png`): the rafters are evenly spaced and dead straight, the wall boards plumb and the gable a perfect triangle. Nothing sags or warps.
- 5 Floating objects: PASS (`720 420 240 120`): the table, chairs and stools cast shadows and meet the floor.
- 6 Repetition: FAIL (`1080 220 200 120`, `a_a_sconces.png`): the same sconce repeats every couple of metres on every wall, and the back bar is three identical rows of the same bottle (`230 200 300 180`, `a_a_backbar.png`).
- 7 Empty: FAIL (`640 160 640 260`, `a_a_empty_back.png`): a cavernous room with three tables, one person at the edge and long runs of bare plank wall. There is no clutter, crowd, glasses or coats.
- 8 Scale tells: FAIL (`640 160 640 260`, `a_a_empty_back.png`): the hall is barn-sized, roughly three storeys to the ridge, and the tables and stools look small in it. It reads as a hay barn with saloon furniture put in, not a saloon.
- 9 Edges of the world: PASS (`640 80 500 120`): the gaps in the gable boards show night through cracks, which is believable.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **One orange wash, no darkness** (tell 1, `0 0 760 200`): every surface is lit the same warm brown. The roof is as bright as the walls and there are no deep blacks between the lamps, so the room feels lit by a fill light, not by oil lamps. Cause: light. Cheapest fix: drop the ambient fill indoors so the space between lamp pools and the roof go near black.
2. **Empty barn, not a saloon** (tell 7, `640 160 640 260`): huge bare wall surfaces and a few tables lost in a big floor. Nobody lives or drinks here. Cause: dressing. Cheapest fix: add people at the tables and the bar, with glasses, hats and coats on chairs.
3. **Same sconce, same bottle, over and over** (tell 6, `1080 220 200 120`): identical sconces march along each wall at even spacing, and the back bar is rows of the same bottle. Cause: dressing. Cheapest fix: vary the bottles (shape, height, gaps) and space the sconces unevenly or swap some for other fixtures.
4. **Pixelated pale mirror** (tell 3, `230 200 300 180`): the back-bar mirror is a flat cream panel of chunky squares, a leftover of the old pixel look. It reads as a texture error next to the smooth wood. Cause: material. Cheapest fix: render the mirror smooth and darker so it shows the room in dim reflection.
5. **Clean, uniform floor** (tell 3, `30 440 420 280`): perfect boards with repeated knots and no grime, wear paths or spills. Cause: material. Cheapest fix: a darkened, worn traffic path from door to bar and grime along the walls.

## b
- 1 Flat light: FAIL (`300 0 700 260`, `b_b_ceiling.png`): the roof boards are lit pale and even all the way down the hall. Walls, floor and bar share one orange level, and the blacks are lifted.
- 2 No atmosphere: FAIL (`400 280 600 200`, `b_b_back_wall.png`): looking 20+ m down the room, the far wall is barely softer than the near one. There is no smoke haze or light shafts in the air.
- 3 Too clean: FAIL (`240 460 560 260`, `b_b_empty_floor.png`): a long, unmarked stretch of floor. The bar top is bleached evenly from end to end, and the mirror is again cream squares (`0 280 480 260`, `b_b_bar.png`).
- 4 Too straight: FAIL (`0 280 480 260`, `b_b_bar.png`): the bar is a single ruler-straight slab, and the shelves and rafters are mechanically regular. The symmetric one-point view down the room makes it worse.
- 5 Floating objects: PASS (`240 480 300 200`): the stools and tables have contact shadows.
- 6 Repetition: FAIL (`400 280 600 200`, `b_b_back_wall.png`): the same sconce at even spacing on every wall. Each casts the same tall tent-shaped shadow of the board leaning beneath it, and the bottles are identical rows.
- 7 Empty: FAIL (`240 460 560 260`, `b_b_empty_floor.png`): a long empty floor, two tables and one barkeep bent over. The room has nothing in it.
- 8 Scale tells: FAIL (`300 0 700 260`, `b_b_ceiling.png`): a barn-height roof over small furniture. The hanging lamps sit high up in a void.
- 9 Edges of the world: PASS (`400 180 500 120`): the gable cracks show night.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Empty hall, nothing happening** (tell 7, `240 460 560 260`): the eye runs down a long, bare, clean floor to an empty back wall. One barkeep and two tables don't make a saloon. Cause: dressing. Cheapest fix: fill the near and middle floor with tables, drinkers and a spittoon, and break the run of the bar with people leaning on it.
2. **Faceted, rubbery hand** (tell 3, `760 540 330 180`, `b_b_hand.png`): the player's hand is low-poly. The facets show across the back of the hand, the skin is a uniform pink-lilac and the nails are pale blobs. It is the closest thing on screen and the cheapest-looking. Cause: people. Cheapest fix: smooth the hand mesh's normals and give the skin some colour variation and darker creases.
3. **Even orange light, lifted blacks** (tell 1, `300 0 700 260`): the roof is bright with nothing lighting it, and the room has no dark. Cause: light. Cheapest fix: cut the indoor ambient so the lamps alone make the pools.
4. **Repeated sconces with odd tent shadows** (tell 6, `400 280 600 200`): identical lamps evenly spaced, each throwing the same big A-shaped shadow down the wall. Cause: dressing. Cheapest fix: vary the fixtures and their spacing, and remove or move the boards leaning under them.
5. **Pixelated mirror, bleached bar top** (tell 3, `0 280 480 260`): the mirror is cream squares and the bar top a pale even grey-tan. Neither reads as varnished wood or glass. Cause: material. Cheapest fix: smooth, darker mirror glass and a darker varnished bar top worn only where elbows go.

## c
- 1 Flat light: FAIL (`0 80 560 380`, `c_c_leftwall.png`): the left wall glows orange from floor to roof with the same mottled level between the sconces. The roof boards are pale, and the shade never gets below mid-brown.
- 2 No atmosphere: FAIL (`560 180 520 240`, `c_c_back.png`): some warm softness at the back, but no smoke or dust catches the lamps. Every lamp is a crisp flare in clean air.
- 3 Too clean: FAIL (`360 470 480 250`, `c_c_floor.png`): a broad clean floor with repeated knots and no dirt or wear path. The wall stain is the same blotch end to end, and the mirror is cream squares (`1080 160 200 280`, `c_c_mirror.png`).
- 4 Too straight: FAIL (`560 180 520 240`, `c_c_back.png`): a dead-straight stair stringer and balustrade, regular rafters and plumb wall boards.
- 5 Floating objects: PASS (`120 400 330 220`): the tables and chairs cast shadows on the floor.
- 6 Repetition: FAIL (`0 80 560 380`, `c_c_leftwall.png`): the same sconce every couple of metres, with the same tent-shadow of a leaning board below. The same landscape painting appears twice, and the bottles are identical rows.
- 7 Empty: FAIL (`360 470 480 250`, `c_c_floor.png`): one woman at the far end and nobody else. The tables are set but unattended.
- 8 Scale tells: FAIL (`1080 0 200 140`, `c_c_lamp.png`): the foreground ceiling lamps are the size of cartwheels. Under the barn-height roof the saloon reads as a converted barn.
- 9 Edges of the world: FAIL (`690 240 110 160`, `c_c_back.png`): through the back doorway a flat blue wedge sits where a wall should be, like a missing backdrop or an unlit sky leaking through.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Orange wash with no darkness** (tell 1, `0 80 560 380`): the walls glow evenly, the roof is lit and nothing falls into shadow. There are lamp pools, but no story in the light. Cause: light. Cheapest fix: lower the indoor ambient and bounce so only the lamp pools stay lit.
2. **Room with one person in it** (tell 7, `360 470 480 250`): a dressed saloon (stair, balcony, piano, paintings) with nobody drinking, playing or talking. It feels like a set before shooting. Cause: dressing. Cheapest fix: populate the tables and the bar.
3. **Blue hole in the back doorway** (tell 9, `690 240 110 160`): a flat blue triangle through the doorway breaks the room and reads as a bug. Cause: geometry. Cheapest fix: close the wall or room behind that doorway so it shows a dark interior.
4. **Repeated sconces and paintings** (tell 6, `0 80 560 380`): the same lamp fixture and the same painting twice along one wall, with identical shadows. Cause: dressing. Cheapest fix: vary the fixtures and pictures, and add irregular wall clutter (notices, a clock, hooks).
5. **Pixelated mirror and faceted hand** (tell 3, `1080 160 200 280`): the back-bar mirror is chunky cream squares, and the player's hand (`770 550 300 170`) is low-poly and evenly pink. Cause: material. Cheapest fix: a smooth, darker reflective mirror and smoothed normals on the hand.

## d
- 1 Flat light: FAIL (`0 0 760 210`, `d_d_ceiling_flat.png`): the roof is lit pale and even with no source. The whole room is one orange level with lifted blacks.
- 2 No atmosphere: FAIL (`640 170 640 260`, `d_d_empty_back.png`): a slight warm softness at the back, but no smoke or beams in the lamplight.
- 3 Too clean: FAIL (`30 460 420 260`, `d_d_clean_floor.png`): the floor is uniform grain with no grime or wear, and the mirror is cream squares (`230 210 300 180`, `d_d_backbar.png`).
- 4 Too straight: FAIL (`0 0 760 210`, `d_d_ceiling_flat.png`): regular rafters and plumb, even wall boards.
- 5 Floating objects: PASS (`720 430 240 120`): the table and chairs have shadows.
- 6 Repetition: FAIL (`640 170 640 260`, `d_d_empty_back.png`): identical sconces evenly spaced, each with the same tent-shaped shadow, and identical rows of bottles.
- 7 Empty: FAIL (`640 170 640 260`, `d_d_empty_back.png`): large bare walls, three tables and two people in a huge hall.
- 8 Scale tells: FAIL (`640 170 640 260`, `d_d_empty_back.png`): a barn-height space dwarfs the furniture.
- 9 Edges of the world: PASS (`640 80 500 120`): the gable cracks read as cracks.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **One orange wash, no dark** (tell 1, `0 0 760 210`): the light is evenly warm everywhere, the roof is lit with no source and there are no blacks. Cause: light. Cheapest fix: cut the indoor ambient so the lamps alone shape the room.
2. **Empty barn** (tell 7, `640 170 640 260`): the room is mostly bare plank wall and floor, with two people and no activity. Cause: dressing. Cheapest fix: people and clutter at the tables and bar.
3. **Repeated sconces and bottles** (tell 6, `640 170 640 260`): the same fixture and shadow every few metres, and a bottle wall made of one bottle. Cause: dressing. Cheapest fix: vary the fixtures and bottles.
4. **Man jammed behind her hair** (tell 8, `590 300 140 180`, `d_d_man.png`): the man in the vest stands so close behind the woman that his face disappears into her hair. They read as overlapping models, not two people sharing a space. Cause: people. Cheapest fix: give him space, or turn him to face something.
5. **Pixelated mirror, clean floor** (tell 3, `230 210 300 180`): cream squares in the mirror, a spotless floor. Cause: material. Cheapest fix: a smooth darker mirror and a grime and wear path on the floor.

## Ranking
From least to most cheap-looking: c, d, a, b
