# Cheap judge, 2026-11-14_cheap_fp_hands_r2

## a
- 1 Flat light: PASS (strong low sun, long rail and post shadows across the street)
- 2 No atmosphere: PASS (the mesas and far end of the street soften into a little haze; thin, but there)
- 3 Too clean: FAIL (`540 330 280 210`, the cuff and sleeve; `a_hand.png`): the shirt cuff is a spotless pale band and the coat sleeve a clean dark tube; the white pebbles are evenly scattered like rice (`0 280 960 260`, `a_ground.png`)
- 4 Too straight: PASS (sagging boards, leaning fronts, uneven ruts)
- 5 Floating objects: PASS (horses, posts and trough have contact shadows)
- 6 Repetition: FAIL (`140 240 160 130`, `a_horse.png`): the same saddled bay horse with the same white socks stands on both sides of the street, and again further down
- 7 Empty: FAIL (`330 260 300 60`): a whole main street in daylight with horses and no single person
- 8 Scale tells: FAIL (`540 330 280 210`, `a_hand.png`): the revolver's grip reads as a thick wooden puck the fingers wrap round from the front; the hand is big and the gun small and unreadable
- 9 Edges of the world: PASS (mesas and desert close the view)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Mannequin hand on a smeared revolver** (tell 8, `540 330 280 210`): smooth, waxy, uniformly peach fingers with no knuckle shadow, holding a grip whose wood is stretched into vertical streaks; the cylinder and barrel are a black blob. It does not read as a hand gripping a gun. Cause: geometry. Cheapest fix: re-pose the fingers round the grip from behind (three fingers under the guard, thumb along the frame) and fix the grip's UVs.
2. **Paper-towel cuff on a tube sleeve** (tell 3, `600 450 200 90`): the cuff is a perfect clean cylinder, lighter than anything in the scene, and the coat sleeve ends in a hard flat ring with a visible step. Cause: material. Cheapest fix: dirty and darken the cuff, add a crease and a soft overlap where the coat sleeve meets it.
3. **Clone horses** (tell 6, `140 240 160 130`): four identical saddled bays, same markings, same pose, with flat posterised patches on their coats. Cause: dressing. Cheapest fix: vary coat colour and markings per horse and turn their heads.
4. **No people in a lived-in street** (tell 7, `330 260 300 60`): horses tied up, but nobody on a porch or in the road. Cause: people. Cheapest fix: one or two figures on the porches.
5. **Rice-grain pebbles** (tell 3, `0 280 960 260`): bright white stones spread at an even density, all the same size and brightness, which reads as a scatter tool. Cause: dressing. Cheapest fix: cluster them in the ruts and edges and darken them to the ground's colour.

## b
- 1 Flat light: PASS (sun shadows from posts and horses)
- 2 No atmosphere: PASS (some haze on the mesas)
- 3 Too clean: FAIL (`420 280 260 260`, `b_hand.png`): pristine cuff, unmarked black sleeve
- 4 Too straight: PASS
- 5 Floating objects: FAIL (`420 280 260 260`, `b_hand.png`): the hand and gun hang in the middle of the frame with nothing tying them to a body; the arm is a black tube rising from the bottom edge
- 6 Repetition: FAIL (`640 300 320 160`, `b_horses.png`): the same horse three times
- 7 Empty: FAIL (`280 250 400 60`): no one in the street
- 8 Scale tells: FAIL (`420 280 260 260`, `b_hand.png`): the sleeve is enormous next to the hand, wider than the hand is long, and the gun is a thin stick held vertically
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Giant black sleeve filling the lower middle** (tell 8, `440 360 220 180`): the forearm is a featureless dark cylinder far too thick for the hand on it, so the arm reads as a stovepipe. Cause: geometry. Cheapest fix: slim the forearm and lower it so the wrist, not the sleeve, leads into frame.
2. **The gun is a stick** (tell 5, `440 280 100 220`): seen from behind, the revolver is a thin brown upright with a black blob on top; the fingers lie flat against it instead of wrapping round. Cause: geometry. Cheapest fix: turn the gun a few degrees so its side shows, and close the fingers round the grip.
3. **Clean cuff band** (tell 3, `470 350 120 70`): the brightest, cleanest object on screen is the shirt cuff. Cause: material. Cheapest fix: dirty, crease and darken it.
4. **Clone horses** (tell 6, `640 300 320 160`): identical bays and markings. Cause: dressing. Cheapest fix: vary coats and poses.
5. **Empty street** (tell 7, `280 250 400 60`): nobody about. Cause: people. Cheapest fix: a figure on the saloon porch.

## c
- 1 Flat light: PASS
- 2 No atmosphere: PASS (thin haze on the mesas)
- 3 Too clean: FAIL (`540 330 280 210`, `c_hand.png`): spotless cuff and sleeve; evenly sprinkled white pebbles
- 4 Too straight: PASS
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`140 240 160 130`): the same horse on both sides
- 7 Empty: FAIL (`330 260 300 60`): no people
- 8 Scale tells: FAIL (`540 330 280 210`, `c_hand.png`): oversized smooth hand, tiny unreadable revolver with a puck-like grip
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Mannequin hand on a smeared revolver** (tell 8, `540 330 280 210`): waxy, unshaded fingers wrapped from the front round a streaky wooden grip; the gun's metal is a black lump. Cause: geometry. Cheapest fix: re-grip the fingers and fix the grip's UVs.
2. **Clean cuff and tube sleeve** (tell 3, `600 450 200 90`): perfect pale cylinder ending in a hard ring. Cause: material. Cheapest fix: grime and a soft overlap.
3. **Clone horses** (tell 6, `140 240 160 130`): same bay everywhere, posterised coat patches. Cause: dressing. Cheapest fix: vary them.
4. **No people** (tell 7, `330 260 300 60`). Cause: people. Cheapest fix: one or two figures.
5. **Trough reads as a new grey box** (tell 3, `600 300 70 40`, `c_trough.png`): pale, square and clean in the middle of a dusty street. Cause: material. Cheapest fix: darken and weather it, add wet dirt at its base.

## d
- 1 Flat light: PASS
- 2 No atmosphere: PASS (mild haze on the mesas)
- 3 Too clean: FAIL (`360 260 340 280`, `d_shotgun.png`): clean cuff, clean unworn sleeves
- 4 Too straight: PASS
- 5 Floating objects: FAIL (`360 330 160 210`): a dark flat slab (the other arm) slides in from the bottom left with no shoulder or shape; it reads as a board laid over the screen
- 6 Repetition: FAIL (`0 250 200 180`, `d_horse.png`): same horse again
- 7 Empty: FAIL (`280 250 300 50`): no people
- 8 Scale tells: FAIL (`360 260 340 280`, `d_shotgun.png`): the sleeves take up a third of the screen; the forearm is wider than the street's ruts
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Two black tubes eat the screen** (tell 8, `360 260 340 280`): the shooting arm is a huge smooth dark cylinder and the other arm a flat dark slab, together a third of the frame with no folds, seams or shape. Cause: camera. Cheapest fix: pull the viewmodel lower and to the right and slim the forearms so the street shows.
2. **Toy-blue receiver** (tell 3, `460 270 40 30`): the little bit of metal at the front is saturated royal blue, like painted plastic. Cause: material. Cheapest fix: blued steel is near-black with a faint blue sheen; drop the saturation.
3. **Stock as a striped log** (tell 3, `440 340 80 200`): the wooden stock is a round pole with regular stripes running across it, no checkering, no wear. Cause: material. Cheapest fix: proper grain along the length and a worn, darker grip area.
4. **Hand floating over the gun** (tell 5, `410 260 120 140`): the left hand rests on top of the barrel with fingers splayed, not under or round it. Cause: geometry. Cheapest fix: re-pose the support hand under the fore-end.
5. **Clone horses, empty street** (tells 6 and 7, `0 250 200 180`): the same bay twice, no people. Cause: dressing. Cheapest fix: vary the horses, add a figure.

## e
- 1 Flat light: PASS
- 2 No atmosphere: PASS (thin)
- 3 Too clean: FAIL (`460 330 480 210`, `e_rifle.png`): the rifle's receiver is a spotless, saturated blue; clean cuffs
- 4 Too straight: PASS
- 5 Floating objects: FAIL (`600 490 50 40`, `e_rifle.png`): a translucent grey-blue lump floats beside the left hand near the lever
- 6 Repetition: FAIL (`140 240 160 130`): same horse on both sides
- 7 Empty: FAIL (`330 260 300 60`): no people
- 8 Scale tells: PASS (the rifle and hands are roughly right for each other)
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Plastic blue rifle** (tell 3, `470 335 230 120`, `e_rifle.png`): the receiver, barrel and lever are a flat, bright, uniform royal blue with no wear on edges, the single loudest colour in the scene; it reads as a toy or an untextured placeholder. Cause: material. Cheapest fix: near-black blued steel with worn bright edges.
2. **Fingers through the stock** (tell 5, `600 400 180 140`): the trigger hand's fingers pass into the wood and the index finger lies on the receiver like a sausage, with no contact shadow. Cause: geometry. Cheapest fix: re-pose the grip so the fingers wrap under the wrist of the stock.
3. **Floating translucent blob** (tell 5, `600 490 50 40`): a pale see-through shape hangs by the lever with nothing holding it. Cause: geometry. Cheapest fix: hide or fix that piece (a stray mesh or a broken material).
4. **Clean cuffs and tube sleeves** (tell 3, `460 400 100 140`): left sleeve a dark smooth tube, both cuffs spotless. Cause: material. Cheapest fix: grime and folds.
5. **Clone horses, empty street** (tells 6 and 7, `140 240 160 130`). Cause: dressing. Cheapest fix: vary the horses, add people.

## f
- 1 Flat light: PASS (warm lantern pool against a cold night, clear direction)
- 2 No atmosphere: FAIL (`0 0 290 300`, `f_sky.png`): the night outside is flat black with smeared streaks for clouds and no glow or air round the lamp
- 3 Too clean: FAIL (`640 0 320 540`, `f_wall.png`): the siding is evenly weathered from top to bottom; the porch floor shows no dirt or tracks
- 4 Too straight: PASS (boards vary in colour and width)
- 5 Floating objects: FAIL (`510 310 100 170`): the two stacked crates have no contact shadow with each other or the floor and look pasted on
- 6 Repetition: FAIL (`640 290 120 120`, `f_wall.png`): a square patch of differently coloured planks sits in the wall by the window like a mismatched texture tile
- 7 Empty: PASS (crates, lantern, lit window: someone lives here)
- 8 Scale tells: FAIL (`540 330 260 210`, `f_hand.png`): big orange mannequin hand on a tiny unreadable revolver with a streaky puck grip
- 9 Edges of the world: FAIL (`0 220 290 100`): the plain beyond the porch is a flat dark band with a hard, even horizon
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Mannequin hand glowing orange** (tell 8, `540 330 260 210`): the hand catches the lamp as one smooth orange surface, no knuckles or tendons, wrapped from the front round a smeared wooden grip; the revolver's metal is a black lump. Cause: geometry. Cheapest fix: re-grip the fingers and give the skin a little detail and darker creases.
2. **Mismatched wall patch** (tell 6, `640 290 120 120`): a rectangle of browner boards cuts across the lit red siding. Cause: material. Cheapest fix: match that section's texture and colour to the wall.
3. **Floating crates** (tell 5, `510 310 100 170`): no shadow under or between them. Cause: light. Cheapest fix: contact shadow / ambient occlusion where they meet.
4. **Dead night outside** (tell 2, `0 0 290 300`): smeared cloud streaks on black, no moonlight on the ground, a flat dark plain to a hard horizon. Cause: light. Cheapest fix: a faint moonlit haze near the horizon.
5. **Blown hotspot** (tell 1, `780 0 180 120`): the top right corner burns to flat cream above the lantern, as if the lamp were a spotlight. Cause: light. Cheapest fix: soften the lamp's falloff.

## g
- 1 Flat light: PASS (lantern light with direction)
- 2 No atmosphere: FAIL (`0 0 290 300`, `g_sky.png`): flat black night, smeared clouds, no air round the lamp
- 3 Too clean: FAIL (`470 340 450 200`, `g_rifle.png`): unworn rifle metal, clean cuffs
- 4 Too straight: PASS
- 5 Floating objects: FAIL (`510 310 100 80`): the crate has no contact shadow
- 6 Repetition: FAIL (`640 290 120 120`): the same mismatched square patch in the wall
- 7 Empty: PASS
- 8 Scale tells: PASS (rifle and hands roughly match)
- 9 Edges of the world: FAIL (`0 220 290 100`): flat dark plain with a hard horizon
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Fingers through the stock** (tell 5, `640 400 200 140`, `g_rifle.png`): the trigger hand's fingers sink into the wood and the index finger lies on the receiver like a sausage. Cause: geometry. Cheapest fix: re-pose the grip round the stock's wrist.
2. **Blue toy receiver, even in lamplight** (tell 3, `470 340 230 110`): darker than in daylight, but still a clean saturated blue with no wear at the edges. Cause: material. Cheapest fix: near-black blued steel, worn edges.
3. **Tube sleeve and clean cuff** (tell 3, `460 400 100 140`): the left forearm is a smooth dark pipe; both cuffs are spotless. Cause: material. Cheapest fix: folds, grime, a softer cuff edge.
4. **Mismatched wall patch** (tell 6, `640 290 120 120`). Cause: material. Cheapest fix: match the boards.
5. **Dead night outside** (tell 2, `0 0 290 300`): black sky with smeared streaks, flat plain. Cause: light. Cheapest fix: moonlit horizon haze.

## Ranking
From least to most cheap-looking: f, a, c, g, b, e, d
