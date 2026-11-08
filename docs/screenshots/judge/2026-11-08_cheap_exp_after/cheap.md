# Cheap judge, 2026-11-08_cheap_exp_after

## a
- 1 Flat light: PASS (a clear high sun: porch shade, rock shadows falling back-left, ruts darkened; the shade is a little grey-lifted under the left porches, `0 180 480 260`)
- 2 No atmosphere: PASS (the canyon walls and the street's far end soften and pale in haze, `280 30 360 200`)
- 3 Too clean: FAIL (`820 80 460 300`; `a_a_jail.png`: the jail's side wall a pale, even sheet of corrugated metal with blocky leftover squares, no rust, streaks or dirt where it meets the ground)
- 4 Too straight: PASS (the jail porch roof sags and tilts, fronts lean a little, the ruts wander)
- 5 Floating objects: PASS (rocks, hooves, the crate and the men's feet carry small contact shadows)
- 6 Repetition: FAIL (`900 440 380 200`; `a_a_rocks.png`: the same faceted grey rock scattered evenly over the whole road; the same dry-grass clump stamped along both boardwalks, `a_a_jail.png`)
- 7 Empty: PASS (tied horses, a crate, townsfolk, a wagon down the street; thin but lived in)
- 8 Scale tells: PASS (horses, men, doors and porches agree)
- 9 Edges of the world: FAIL (`540 220 220 100`; `a_a_far_wagon.png`: the street ends at a flat strip of painted scrub and an orange band with a wagon parked in front of it, like a stage flat)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Low-poly rocks pasted on the road** (tell 6, `900 440 380 200`): a dozen identical grey faceted pebbles, cooler than the tan dirt, spaced like they were sprinkled by a brush tool; they read as a free asset pack. Cause: dressing. Cheapest fix: tint the rocks to the road's dirt and half-bury them, with two or three shapes and far fewer of them, clustered in the ruts and at the boardwalk edge.
2. **The far end is a flat backdrop** (tell 9, `540 220 220 100`): the street's vanishing point is a horizontal painted strip with a glowing orange band; the eye goes straight to it and the town stops being a place. Cause: geometry. Cheapest fix: close the street's end with a real building, wagon or turn of the road in the same haze, so no flat strip shows at eye height.
3. **Billboard grass clumps** (tell 6, `920 300 360 120`): the same pale tuft with a hard cut-off base and stair-stepped edges lines both boardwalks at even spacing. Cause: dressing. Cheapest fix: vary the clump size and tint, and sink their bases into the dirt with a darker ring so they grow out of it.
4. **Leftover squares and a clean metal wall** (tell 3, `920 200 340 180`): the corrugated side of the jail shows chunky texel squares and one even pale tone end to end; it breaks the realistic read next to the smoother timber. Cause: material. Cheapest fix: a smooth, filtered corrugated-iron material with rust runs and a dirt band at the bottom.
5. **Grey, lifted shade** (tell 1, `0 180 480 260`): the shade under the store's porch is a milky blue-grey rather than a deep warm shadow, so the noon sun has less punch than KCD2's or RDR2's streets. Cause: light. Cheapest fix: lower the ambient fill in shade and add ambient occlusion under porch roofs and between boards.

## b
- 1 Flat light: PASS (a low warm sun from the far end, long rut shadows, lit windows against shaded fronts)
- 2 No atmosphere: PASS (warm haze and light shafts in the far street, the cliffs fading back)
- 3 Too clean: PASS (weathered, patched boards, ruts and stones in the road, dust on the steps)
- 4 Too straight: PASS (porch posts, braces and fronts vary; the telegraph pole leans)
- 5 Floating objects: PASS (horses, crate and men sit on the ground with shadows)
- 6 Repetition: FAIL (`40 420 480 170`; `b_grass.png`: the same tuft of yellow grass with a hard cut base repeated along the boardwalk; the same pale pebble dotted across the road)
- 7 Empty: PASS (a man on the porch, horses tied, figures and a wagon down the street, a wanted poster)
- 8 Scale tells: FAIL (`730 430 380 290`; `b_hand.png`: the first-person hand is huge and faceted beside a small revolver gripped from the side, its grip smeared in stretched stripes)
- 9 Edges of the world: FAIL (`640 280 440 140`; `b_far.png`: the street ends against a flat painted plate with the light shafts painted on; `b_sky.png`: the sky is an oil-painting texture with brush ridges and stepped edges)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The player's own hand and gun** (tell 8, `730 430 380 290`): the biggest, nearest thing on screen is a low-poly, flat-shaded hand with visible facets and a revolver whose grip and cylinder textures are stretched into streaks; a player sees it every second and reads "student project". Cause: geometry. Cheapest fix: a properly modelled and textured hand with knuckles and skin shading, and the gun's UVs fixed so the grip shows wood, not stripes.
2. **A painted sky over a realistic street** (tell 9, `640 0 640 240`): the clouds are a stylised oil painting with brush texture and stepped edges, saturated orange and violet; it looks like a pasted matte, toy-like against the 3D town. Cause: material. Cheapest fix: a photographic or smooth volumetric sunset sky, less saturated, without the brush texture.
3. **Flat backdrop at the end of the street** (tell 9, `640 280 440 140`): the far canyon and the shafts of light are one flat plate behind the last building; the parallax dies there. Cause: geometry. Cheapest fix: put a few real 3D rocks, a building or a bend in front of the plate, so the street doesn't end on a picture.
4. **Repeated grass tufts** (tell 6, `40 420 480 170`): identical clumps with hard bases and pixelly blade edges line the boardwalk. Cause: dressing. Cheapest fix: fewer clumps in three sizes and two tints, bases blended into the dirt.
5. **Horses and saddles read as smooth plastic** (tell 3, `0 350 420 300`): the near horse and saddle are uniform shiny brown with no hair, dust or leather wear, next to well-weathered timber. Cause: material. Cheapest fix: dust and sweat darkening on the horse's legs and belly, scuffing and stitching on the saddle leather.

## c
- 1 Flat light: FAIL (`0 170 640 160`; `c_sconces.png`: one orange wash over every wall; fourteen sconces each make the same bright patch and nothing between them falls into shadow; the roof is lit as bright as the walls)
- 2 No atmosphere: FAIL (`0 170 640 160`; `c_sconces.png`: no smoke or haze in the lamplight; the far wall is as crisp as the near table)
- 3 Too clean: FAIL (`40 430 600 290`; `c_floor.png`: the floor one even plank texture from wall to wall, no scuffs, spills, sawdust or worn path to the bar; the walls the same)
- 4 Too straight: FAIL (`220 330 440 150`; `c_bar.png`: a dead-straight bar, perfectly parallel planks and evenly spaced stools; nothing worn, sagging or out of line)
- 5 Floating objects: FAIL (`220 330 440 150`; `c_bar.png`: blue light leaks through the bar's left end where its panels meet; the ceiling has hard round light discs that don't belong to any lamp, `c_ceiling.png`)
- 6 Repetition: FAIL (`0 170 640 160`; `c_sconces.png`: identical brass sconces at even spacing round the room, identical bottles in two ruler-straight rows, identical chairs)
- 7 Empty: FAIL (`640 340 640 260`; `c_tables.png`: a barn-sized room with two tables, one barkeep and acres of bare floor; no crowd, no coats on hooks, no pictures, no clutter)
- 8 Scale tells: FAIL (`760 440 340 280`; `c_hand.png`: the giant faceted hand and the small striped revolver, as on the street; the room's height also reads more barn than saloon)
- 9 Edges of the world: PASS (an interior; the walls and roof close it)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Orange wash with no dark** (tell 1, `0 170 640 160`): everything is the same orange-brown, the walls glow evenly, and the roof is bright; there's no pool of light falling off into near-black as in a lamplit saloon, so the room reads as lit by a filter, not by lamps. Cause: light. Cheapest fix: drop the room's ambient fill hard and let only a few lamps carry the light, with darkness between them and on the roof.
2. **Big and empty** (tell 7, `640 340 640 260`): a huge plank barn with two card tables and one man; it says "test level" more than a working saloon. Cause: dressing. Cheapest fix: half the floor filled with people, tables, spittoons, a piano, coats and pictures; or a smaller room.
3. **Repeated fixtures** (tell 6, `0 170 640 160`): identical sconces at even intervals round every wall, bottles in perfect rows; the pattern shouts copy-paste. Cause: dressing. Cheapest fix: fewer lamps of two or three kinds at uneven spacing, a chandelier, and bottles in uneven groups.
4. **Render artefacts** (tell 5, `240 0 400 160`): hard-edged round discs of light on the roof boards and a blue light leak at the bar's end; a player reads them as bugs. Cause: light. Cheapest fix: soften or remove the lamp shades' cast circles on the roof and close the gap at the bar's end.
5. **The first-person hand** (tell 8, `760 440 340 280`): the same low-poly, flat-skinned hand and streaky revolver grip sit in the bottom right of every frame. Cause: geometry. Cheapest fix: a better-modelled, textured hand and the grip's UVs fixed.

## Ranking
From least to most cheap-looking: b, a, c
