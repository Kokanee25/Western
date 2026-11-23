# Cheap judge, 2026-11-14_cheap_fp_hands

## a
- 1 Flat light: PASS (long hard shadows across the street from the left; the sun's side is clear)
- 2 No atmosphere: PASS (a little haze softens the mesas `330 190 300 80`; thin, but there)
- 3 Too clean: FAIL (`0 380 480 160`; `cut a_pebbles.png`): the street is one even sand tone with evenly sprinkled bright-white pebbles like confetti; no dung, hoofprints, puddle stains or dirt banked against porches
- 4 Too straight: FAIL (`600 0 360 320`; `cut a_straight.png`): every roofline, porch beam and sign dead level and square
- 5 Floating objects: PASS (horses' hooves, the trough and posts sit in their shadows)
- 6 Repetition: FAIL (`140 240 740 150`; `cut a_horses.png`): the same saddled bay with the same white socks, three times
- 7 Empty: FAIL (`300 270 360 110`; `cut a_empty.png`): a main street with horses and no people, no wagon, no goods on porches
- 8 Scale tells: PASS (doors, horses and porches read in proportion)
- 9 Edges of the world: FAIL (`330 255 300 40`; `cut a_horizon.png`): the street runs out into a bare flat plain with a few tiny boxes, then the mesas as a cut-out
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The hand and gun look like a placeholder rig** (tell 3, `540 340 280 200`; `cut a_hand_gun.png`): a smooth, rubbery pink hand with sausage fingers holds the revolver from the side, the grip passing beside the fingers rather than in the palm; the cylinder is a black blob; the cuff is a stiff khaki tube with a printed weave and a hard-edged black coat sleeve below it. Cause: people. Cheapest fix: re-pose the grip so the revolver's handle sits in the palm with the fingers wrapped around it and the barrel pointing ahead, and give the skin knuckle creases and a darker, sunburnt tone.
2. **Identical horses** (tell 6, `140 240 740 150`; `cut a_horses.png`): the same horse, same tack, same markings, repeated down both sides. Cause: dressing. Cheapest fix: vary coat colour and markings per horse (a grey, a black, a paint) and turn one to face another way.
3. **An empty street** (tell 7, `300 270 360 110`; `cut a_empty.png`): no townsfolk, wagon, barrels, crates of goods or laundry; it reads as a set. Cause: dressing. Cheapest fix: a parked wagon and a man on the store's porch.
4. **Confetti pebbles on clean sand** (tell 3, `0 380 480 160`; `cut a_pebbles.png`): uniform white stones scattered at even density, too bright for the ground they sit on. Cause: material. Cheapest fix: darken and tint the pebbles to the sand, halve their number and cluster them along the ruts and porch edges.
5. **The far end of the street stops** (tell 9, `330 255 300 40`; `cut a_horizon.png`): a flat empty plain and toy-sized boxes between town and mesas. Cause: geometry. Cheapest fix: a few far buildings, fences and scrub at the street's end to carry the eye out.

## b
- 1 Flat light: PASS (clear sun from the left, shadows cast across the street)
- 2 No atmosphere: PASS (light haze on the mesas)
- 3 Too clean: FAIL (`0 400 420 140`; `cut b_pebbles.png`): even sand, bright pebbles evenly scattered
- 4 Too straight: FAIL (`620 0 340 300`; `cut b_straight.png`): perfectly square, level facades
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 240 960 200`; `cut b_horses.png`): the same horse four times
- 7 Empty: FAIL (`280 270 340 110`; `cut b_empty.png`): no people in the street
- 8 Scale tells: FAIL (`420 290 260 250`; `cut b_hand_sleeve.png`): the forearm and cuff are huge for the hand, the khaki cuff as wide as a stovepipe
- 9 Edges of the world: FAIL (`290 255 340 40`; `cut b_horizon.png`): bare plain and tiny boxes at the street's end
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A giant forearm and cuff block a third of the view** (tell 8, `420 290 260 250`; `cut b_hand_sleeve.png`): the black coat sleeve and pale cuff are a fat cylinder, out of proportion with the small hand; the revolver's grip shows beside the fingers instead of inside them. Cause: camera. Cheapest fix: narrow the field of view for the arms (or pull the arm back and lower) so the sleeve doesn't fill the lower centre, and scale the cuff to the wrist.
2. **Identical horses** (tell 6, `0 240 960 200`; `cut b_horses.png`). Cause: dressing. Cheapest fix: vary coats and poses.
3. **Empty street** (tell 7, `280 270 340 110`; `cut b_empty.png`). Cause: dressing. Cheapest fix: one or two townsfolk and a wagon.
4. **Confetti pebbles** (tell 3, `0 400 420 140`; `cut b_pebbles.png`). Cause: material. Cheapest fix: fewer, ground-tinted, clustered stones.
5. **The world ends past the last building** (tell 9, `290 255 340 40`; `cut b_horizon.png`). Cause: geometry. Cheapest fix: dress the street's far end.

## c
- 1 Flat light: PASS
- 2 No atmosphere: PASS (light haze on the mesas)
- 3 Too clean: FAIL (`0 380 480 160`; `cut c_pebbles.png`): even sand, confetti pebbles
- 4 Too straight: FAIL (`600 0 360 320`; `cut c_straight.png`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`140 240 740 150`; `cut c_horses.png`)
- 7 Empty: FAIL (`300 270 360 110`; `cut c_empty.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`330 255 300 40`; `cut c_horizon.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The rubbery hand holding the revolver sideways** (tell 3, `540 340 280 200`; `cut c_hand_gun.png`): as in a: smooth pink hand, fingers like sausages, the grip beside the fingers, a blob cylinder, a printed-weave cuff tube. Cause: people. Cheapest fix: put the grip in the palm and add knuckle and tendon shading to the hand.
2. **Identical horses** (tell 6, `140 240 740 150`; `cut c_horses.png`). Cause: dressing. Cheapest fix: vary coats.
3. **Empty street** (tell 7, `300 270 360 110`; `cut c_empty.png`). Cause: dressing. Cheapest fix: people and a wagon.
4. **Confetti pebbles** (tell 3, `0 380 480 160`; `cut c_pebbles.png`). Cause: material. Cheapest fix: tint and cluster them.
5. **Level, square facades** (tell 4, `600 0 360 320`; `cut c_straight.png`): nothing sags; the porch roofs and signs are ruler-straight. Cause: geometry. Cheapest fix: a slight sag in the porch beams and a sign hung a little crooked.

## d
- 1 Flat light: PASS
- 2 No atmosphere: PASS (thin haze on the far mesas)
- 3 Too clean: FAIL (`0 400 360 140`; `cut d_pebbles.png`): even sand, confetti pebbles
- 4 Too straight: PASS (the facades are at the frame's edges; little to judge)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 260 960 190`; `cut d_horses.png`): the same horse three times
- 7 Empty: FAIL (`250 270 380 80`; `cut d_empty.png`)
- 8 Scale tells: FAIL (`380 260 380 280`; `cut d_rifle_hands.png`): the near hand and sleeve swell to fill the lower half of the screen; the fingers poking up beside the front sight look like a giant's
- 9 Edges of the world: FAIL (`240 255 400 40`; `cut d_horizon.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The rifle aim is a wall of arm and a bright-blue toy receiver** (tell 8, `380 260 380 280`; `cut d_rifle_hands.png`; `cut d_blue_receiver.png`): the rifle is sighted down the middle with a fat black sleeve and cuff swallowing the lower half, pink fingers floating either side of the barrel, and the receiver a saturated royal blue like plastic. Cause: camera. Cheapest fix: pull the arms out of the centre (shoulder the rifle to the right, cheek on the stock) and make the steel a dark, desaturated blued-grey with worn silver edges.
2. **Identical horses** (tell 6, `0 260 960 190`; `cut d_horses.png`). Cause: dressing. Cheapest fix: vary coats.
3. **Empty street** (tell 7, `250 270 380 80`; `cut d_empty.png`). Cause: dressing. Cheapest fix: people at the hitching rails.
4. **Confetti pebbles** (tell 3, `0 400 360 140`; `cut d_pebbles.png`). Cause: material. Cheapest fix: tint and cluster.
5. **The far end is a bare plain** (tell 9, `240 255 400 40`; `cut d_horizon.png`). Cause: geometry. Cheapest fix: dress the street's end.

## e
- 1 Flat light: PASS
- 2 No atmosphere: PASS (thin haze on the mesas)
- 3 Too clean: FAIL (`0 380 480 160`; `cut e_pebbles.png`)
- 4 Too straight: FAIL (`600 0 360 320`; `cut e_straight.png`)
- 5 Floating objects: FAIL (`460 330 500 210`; `cut e_rifle_hands.png`): the hands don't touch the rifle: a thumb lies flat on the receiver's side like a sticker, the trigger fingers hover, and a pale blue-grey lump floats below the lever
- 6 Repetition: FAIL (`140 240 740 150`; `cut e_horses.png`)
- 7 Empty: FAIL (`300 270 360 110`; `cut e_empty.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`330 255 300 40`; `cut e_horizon.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Hands that don't grip the rifle** (tell 5, `460 330 500 210`; `cut e_rifle_hands.png`): stubby pink fingers sit beside and on top of the gun rather than around it, a thumb is pasted on the receiver's flat, and an unexplained blue-grey blob hangs under the lever. Cause: people. Cheapest fix: pose the right hand round the wrist of the stock with the finger through the lever, the left under the forend, and remove or fix the stray blob.
2. **A saturated, plastic-blue receiver and barrel** (tell 3, `460 330 500 210`): the steel reads as painted toy blue with no wear, while the stock's grain is good. Cause: material. Cheapest fix: desaturate the bluing to near-black grey with worn bright edges and a dull sheen.
3. **Identical horses** (tell 6, `140 240 740 150`; `cut e_horses.png`). Cause: dressing. Cheapest fix: vary coats.
4. **Empty street** (tell 7, `300 270 360 110`; `cut e_empty.png`). Cause: dressing. Cheapest fix: a few people and a wagon.
5. **Confetti pebbles** (tell 3, `0 380 480 160`; `cut e_pebbles.png`). Cause: material. Cheapest fix: tint and cluster.

## f
- 1 Flat light: FAIL (`640 0 320 540`; `cut f_wall_light.png`): the wall's brightest patch is a blown-out wash up near the roof, not around the lantern, and the lantern itself throws no visible glow; the light reads as coming from nowhere
- 2 No atmosphere: FAIL (`760 60 140 160`; `cut f_lamp.png`): no bloom or haze round the lamp; the night beyond the porch is a clean black
- 3 Too clean: FAIL (`510 310 110 170`; `cut f_crates.png`): two crisp new crates on a spotless porch; no dust, boot marks or wear on the boards
- 4 Too straight: PASS (the boards' grain and colour vary; posts are square but timber is)
- 5 Floating objects: PASS (the crates sit in their own shadow)
- 6 Repetition: FAIL (`640 220 320 320`; `cut f_wall_repeat.png`): the siding is a photo texture whose knots and colour bands repeat board to board, with stair-stepped saw-tooth edges along each board's lip
- 7 Empty: FAIL (`510 310 110 170`): a porch with two crates and nothing else: no chair, bench, barrel or door
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 260 300 120`; `cut f_dark_plain.png`): beyond the rail a flat dark plain to a hard horizon, no town lights
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The rubbery hand and sideways revolver again** (tell 3, `540 340 280 200`; `cut f_hand_gun.png`): under warm lamplight the hand is a smooth pink mitt, the grip beside the fingers, a printed-weave cuff tube. Cause: people. Cheapest fix: re-pose the grip into the palm and give the hand creases and a rougher, darker skin.
2. **Light from nowhere** (tell 1, `640 0 320 540`; `cut f_wall_light.png`): a hot white blowout on the upper wall while the lantern sits dark-glassed below it. Cause: light. Cheapest fix: put the light's origin inside the lantern and let it fall off around it, with the glass emissive.
3. **Photo-wood siding with saw-tooth edges** (tell 6, `640 220 320 320`; `cut f_wall_repeat.png`): oversaturated red photo planks, repeating knots, jagged stair-step lines along every board. Cause: material. Cheapest fix: desaturate the red and anti-alias or soften the board-lip edge.
4. **A bare porch** (tell 7, `510 310 110 170`; `cut f_crates.png`). Cause: dressing. Cheapest fix: a chair, a spittoon and a door with light under it.
5. **A dead, empty night beyond** (tell 9, `0 260 300 120`; `cut f_dark_plain.png`). Cause: geometry. Cheapest fix: a few lit windows or a lamp down the street.

## g
- 1 Flat light: FAIL (`640 0 320 540`; `cut g_wall_repeat.png`): the same blown-out patch above an unlit-looking lantern
- 2 No atmosphere: FAIL (`760 60 140 160`; `cut g_lamp.png`): no glow or air round the lamp
- 3 Too clean: FAIL (`510 310 110 170`; `cut g_crates.png`): a new crate on a spotless porch
- 4 Too straight: PASS
- 5 Floating objects: FAIL (`470 330 450 210`; `cut g_rifle_hands.png`; `cut g_blob.png`): the fingers sit on and beside the rifle without gripping it; a pale lump floats by the lever
- 6 Repetition: FAIL (`640 220 320 320`; `cut g_wall_repeat.png`): repeating photo planks with saw-tooth edges
- 7 Empty: FAIL (`510 310 110 170`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 260 300 120`; `cut g_dark_plain.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Hands that don't hold the rifle, and plastic-blue steel** (tell 5, `470 330 450 210`; `cut g_rifle_hands.png`): pink stubby fingers resting on the receiver's flat, a thumb pasted on, a stray blob under the lever, and the metal a saturated royal blue even by lamplight. Cause: people. Cheapest fix: a real two-handed grip (wrist of the stock and forend) and a dark worn-steel material.
2. **Light from nowhere** (tell 1, `640 0 320 540`): the blowout sits above the lantern, not in it. Cause: light. Cheapest fix: emit from the lantern glass.
3. **Saw-tooth photo planks** (tell 6, `640 220 320 320`; `cut g_wall_repeat.png`). Cause: material. Cheapest fix: desaturate and smooth the board edges.
4. **Bare porch** (tell 7, `510 310 110 170`; `cut g_crates.png`). Cause: dressing. Cheapest fix: a chair and a door.
5. **Empty night beyond the rail** (tell 9, `0 260 300 120`; `cut g_dark_plain.png`). Cause: geometry. Cheapest fix: distant lit windows.

## Ranking
From least to most cheap-looking: a, c, b, f, d, e, g
