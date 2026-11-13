# Cheap judge, cheap_r2

## a
- 1 Flat light: PASS (whole frame: a clear low sun from the left, long hard shadows off posts and horses across the street)
- 2 No atmosphere: FAIL (`300 0 420 190`, the sky and the mesas; `a_sky_flat.jpg`)
- 3 Too clean: FAIL (`540 330 290 210`, the hand and revolver; `a_a_hand_revolver.jpg`)
- 4 Too straight: FAIL (`100 290 500 250`, the wheel ruts; `a_ruts_straight.jpg`)
- 5 Floating objects: PASS (horses' hooves, posts and the crate all sit in their own shadows)
- 6 Repetition: FAIL (`140 240 760 150`, the horses; `a_horses_repeat.jpg`)
- 7 Empty: FAIL (`330 250 330 80`, the street; `a_street_empty.jpg`)
- 8 Scale tells: PASS (doors, porches, horses and hitch rails agree)
- 9 Edges of the world: PASS (the street runs out to flats and mesas; no seam)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The gun hand is a clay mitten** (tell 3, `540 330 290 210`): the hand holding the revolver is one smooth, orange-brown lump with no knuckles, nails, tendons or creases; the fingers below the grip are rounded beads, the thumb does not wrap the grip, and there is no cuff or sleeve, the wrist just runs out of frame as a tube. In a first-person game this is on screen every second, so it sets the whole impression. Cause: people. Cheapest fix: a hand with modelled knuckles and a skin texture (creases, veins, dirt under the nails) and a shirt cuff at the wrist.
2. **The revolver's grip is smeared stripes** (tell 3, `600 420 70 120`): the wooden grip panels are vertical streaks of stretched texture, the frame and cylinder a uniform black plastic with no bluing wear, no screw heads, no edge highlights. Cause: material. Cheapest fix: fix the grip's UVs and give the steel worn edges and a gloss break-up.
3. **The sky is posterised paint** (tell 2, `300 0 420 190`): the clouds are hard-edged bands of three or four flat tones, like a filter, and the mesas sit sharp and saturated with little air in front of them; no dust hangs in the noon street. Cause: light. Cheapest fix: a real cloud texture with soft gradients and a little warm dust haze down the street.
4. **The same horse four times** (tell 6, `140 240 760 150`): the same bay horse with the same white socks and the same saddle stands at every rail, facing the same way. Cause: dressing. Cheapest fix: vary coat colour, socks and tack and turn one or two.
5. **A dead-straight empty street** (tells 4 and 7, `100 290 500 250`): the ruts are perfectly parallel rails to the vanishing point, the white pebbles are scattered evenly as if by a brush, and nobody is in the street or on the porches at noon. Cause: dressing. Cheapest fix: break the ruts with puddles, hoof churn and dung, and put two or three people at work in the street.

## b
- 1 Flat light: PASS (the same clear low sun; long shadows from horses and posts)
- 2 No atmosphere: FAIL (`250 0 450 160`, sky and mesas; `b_sky_flat.jpg`)
- 3 Too clean: FAIL (`410 270 290 270`, hand and revolver; `b_b_hand_revolver.jpg`)
- 4 Too straight: FAIL (`0 380 440 160`, ruts; `b_ruts_straight.jpg`)
- 5 Floating objects: PASS (hooves, posts and the crate shadowed)
- 6 Repetition: FAIL (`0 240 960 190`, the horses; `b_horses_repeat.jpg`)
- 7 Empty: FAIL (`300 250 320 70`, the street; `b_street_empty.jpg`)
- 8 Scale tells: FAIL (`410 270 290 270`, the hand against the revolver; `b_hand_oversized.jpg`)
- 9 Edges of the world: PASS (the street opens to flats and mesas)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A giant blob for a hand** (tells 3 and 8, `410 270 290 270`): aimed down the sights, the hand is a huge smooth dome of skin, bigger than the whole revolver, with no knuckles or nails; the fingers poke out under the grip as three loose balls, as if the gun were stuck to the side of a potato. It fills a third of the frame's bottom and is the first thing seen. Cause: people. Cheapest fix: scale the hand to the gun and model a real grip pose (fingers around the grip, thumb along the frame), with skin detail.
2. **The grip and gun read as unfinished** (tell 3, `450 280 70 260`): the grip is vertical streaks of stretched wood texture, the steel flat black with no wear or highlights, the sights a plain block. Cause: material. Cheapest fix: correct the grip UVs and add edge wear and specular break-up on the steel.
3. **No sleeve, no wrist** (tell 3, `480 330 220 210`): the hand ends in a tube of identical skin out of the frame's bottom, no cuff, no shirt, no sense of an arm behind it. Cause: people. Cheapest fix: show the shirt cuff and forearm sleeve under the gun hand.
4. **Posterised sky, no air** (tell 2, `250 0 450 160`): flat-banded cloud tones, the mesas crisp and saturated, no dust over the street. Cause: light. Cheapest fix: soft-gradient clouds and a little dust haze.
5. **The same horse at every rail, nobody about** (tells 6 and 7, `0 240 960 190`): two identical bays on the left and right with identical saddles, and an empty noon street with mechanical parallel ruts. Cause: dressing. Cheapest fix: vary the horses and add people at work.

## c
- 1 Flat light: PASS (low sun from the left, hard shadows)
- 2 No atmosphere: FAIL (`300 0 420 190`, sky and mesas; `c_sky_flat.jpg`)
- 3 Too clean: FAIL (`400 270 330 270`, hand and revolver; `c_c_hand_revolver.jpg`)
- 4 Too straight: FAIL (`100 290 500 250`, ruts; `c_ruts_straight.jpg`)
- 5 Floating objects: FAIL (`400 270 330 270`, the revolver in the hand; `c_gun_floats.jpg`)
- 6 Repetition: FAIL (`140 240 760 150`, the horses; `c_horses_repeat.jpg`)
- 7 Empty: FAIL (`330 250 330 80`, the street; `c_street_empty.jpg`)
- 8 Scale tells: PASS (buildings, horses and hand roughly agree)
- 9 Edges of the world: PASS (flats and mesas beyond the street)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The revolver is not held, it hangs off the wrist** (tell 5, `400 270 330 270`): cocked and tilted, the gun sticks out of the side of the hand at an angle with no fingers around the grip and no trigger finger; the hand is a closed smooth lump beside it, so it reads as a gun glued on. Cause: people. Cheapest fix: pose the fingers around the grip and the thumb on the hammer for the cocked pose.
2. **Clay skin, no sleeve** (tell 3, `520 370 200 170`): the hand and forearm are one smooth orange-brown surface with no knuckles, veins or hair, and no shirt cuff; it looks like a mannequin's arm. Cause: people. Cheapest fix: skin texture with creases and dirt, and a cuff at the wrist.
3. **A plastic gun** (tell 3, `410 275 120 160`): blue-black flat steel with a hard plastic sheen, smeared stripes for the grip, no wear on the cylinder or muzzle. Cause: material. Cheapest fix: worn bluing on the edges and a proper wood grip.
4. **Posterised sky** (tell 2, `300 0 420 190`): flat-banded clouds and crisp mesas, no dust in the air. Cause: light. Cheapest fix: soft clouds and street haze.
5. **Repeated horses on an empty, ruled street** (tells 6, 7 and 4, `140 240 760 150`): the same bay horse at every rail, nobody about, ruts like rails. Cause: dressing. Cheapest fix: vary the horses and break the ruts.

## d
- 1 Flat light: PASS (the wall lamp throws a warm pool and a hard shadow of the brace; the street beyond is cool)
- 2 No atmosphere: FAIL (`330 200 230 160`, the lamps down the porch; `d_lamps_no_air.jpg`)
- 3 Too clean: FAIL (`560 340 280 200`, hand and revolver; `d_d_hand_revolver.jpg`)
- 4 Too straight: PASS (posts and boards have knots, grain and some wear)
- 5 Floating objects: PASS (barrel, crate and posts sit on the boards)
- 6 Repetition: FAIL (`20 260 220 200`, the two posters; `d_posters_repeat.jpg`)
- 7 Empty: PASS (barrel, crate, posters, a horse at the rail: a lived-in porch at night)
- 8 Scale tells: PASS (door, barrel and crate agree)
- 9 Edges of the world: PASS (the street and buildings continue into the dark)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A debug error across the picture** (no tell; a HUD message, `0 440 960 30`, `d_stall_overlay.jpg`): yellow text "The game stalled over 5 s just now..." with a file path runs across the frame; a player reads it as a broken build. Cause: camera. Cheapest fix: keep developer messages off the game view.
2. **The gun hand is a clay lump in lamplight** (tell 3, `560 340 280 200`): orange, smooth, featureless skin with bead fingers under a smeared, striped grip; no sleeve. The lamplight makes it glow like plasticine. Cause: people. Cheapest fix: a real hand mesh and skin texture, with a cuff.
3. **Pixel-art wanted posters, twice, with a mirrored word** (tell 6, `20 260 220 200`): two identical posters made of big chunky squares, with "REWARD" printed backwards; leftover squares in a realistic scene look like a placeholder. Cause: material. Cheapest fix: a properly printed paper poster texture, and vary or remove the second.
4. **The foreground horse is orange plastic** (tell 3, `700 330 260 210`): the horse at bottom right is lit a flat orange with no hair, no shine on the eye and no shadow modelling. Cause: material. Cheapest fix: give the horse a coat texture and let the lamp shadow it.
5. **No air round the lamps** (tell 2, `330 200 230 160`): the porch lanterns glow but the air around them is clear; nothing catches the light, so the night reads crisp instead of smoky. Cause: light. Cheapest fix: a faint haze or glow in the lamplight down the porch.

## e
- 1 Flat light: PASS (low sun from the left, long hard shadows; the arms take the light)
- 2 No atmosphere: FAIL (`300 0 420 190`, sky and mesas; `e_sky_flat.jpg`)
- 3 Too clean: FAIL (`220 330 720 210`, arms and rifle; `e_e_arms_rifle.jpg`)
- 4 Too straight: FAIL (`470 340 90 200`, the sling; `e_sling_rigid.jpg`)
- 5 Floating objects: PASS (the hands grip the forend and wrist of the stock; horses and crate shadowed)
- 6 Repetition: FAIL (`140 240 760 150`, the horses; `e_horses_repeat.jpg`)
- 7 Empty: FAIL (`330 250 330 80`, the street; `e_street_empty.jpg`)
- 8 Scale tells: PASS (rifle, hands and sleeve in proportion)
- 9 Edges of the world: PASS (flats and mesas beyond)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The sling is a rigid rod** (tell 4, `470 340 90 200`): the rifle's sling drops from the forend as a straight black bar and comes back as another, with no sag, curve or swing; it reads as a stick, not leather. Cause: geometry. Cheapest fix: let the sling hang in a curve (a simple sagging rope or bone chain).
2. **Sleeve and skin are clean and uniform** (tell 3, `220 380 330 160`): the linen sleeve has a weave but no folds, creases, sweat or dirt and ends in a smooth bulb at the wrist; the hands are a uniform tan with no knuckle or nail detail. Cause: material. Cheapest fix: fold normals and grime on the sleeve, and a skin texture on the hands.
3. **The rifle is clean and flat** (tell 3, `470 340 400 200`): the receiver is a flat blue-black with crisp plastic edges, the stock's wood is good but unworn; no scratches or bluing loss where hands go. Cause: material. Cheapest fix: edge wear on the receiver and lever.
4. **Posterised sky, no dust** (tell 2, `300 0 420 190`): banded cloud tones and crisp distance; no haze in the street. Cause: light. Cheapest fix: soft clouds and street haze.
5. **Repeated horses, nobody in town** (tells 6 and 7, `140 240 760 150`): the same horse at every rail, an empty street with ruled ruts. Cause: dressing. Cheapest fix: vary the horses and put people in the street.

## f
- 1 Flat light: PASS (low sun from the left, long hard shadows)
- 2 No atmosphere: FAIL (`300 0 420 190`, sky and mesas; `f_sky_flat.jpg`)
- 3 Too clean: FAIL (`220 330 720 210`, arms and rifle; `f_f_arms_rifle.jpg`)
- 4 Too straight: FAIL (`470 340 90 200`, the sling; `f_sling_rigid.jpg`)
- 5 Floating objects: PASS (hands grip the rifle; horses and crate shadowed)
- 6 Repetition: FAIL (`140 240 760 150`, the horses; `f_horses_repeat.jpg`)
- 7 Empty: FAIL (`330 250 330 80`, the street; `f_street_empty.jpg`)
- 8 Scale tells: PASS (rifle, hands, sleeve in proportion)
- 9 Edges of the world: PASS (flats and mesas beyond)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The sling is a rigid rod** (tell 4, `470 340 90 200`): two straight black bars hang from the rifle with no sag. Cause: geometry. Cheapest fix: a sagging, swinging sling.
2. **Sleeve and hands too clean** (tell 3, `220 380 330 160`): an even linen weave with no folds or dirt, a bulbous cuff; tan hands with no knuckles or nails. Cause: material. Cheapest fix: folds and grime on the sleeve, skin detail on the hands.
3. **The sky is harder and more posterised here** (tell 2, `300 0 420 190`): the cloud bands are higher in contrast than a real sky, with crisp mesas and no dust in the street. Cause: light. Cheapest fix: soft cloud gradients and a warm haze.
4. **Clean, flat rifle steel** (tell 3, `470 340 400 200`): an unworn blue-black receiver with plastic edges. Cause: material. Cheapest fix: edge wear and bluing loss.
5. **Repeated horses, empty street** (tells 6 and 7, `140 240 760 150`): the same horse at every rail, nobody in town, ruled ruts. Cause: dressing. Cheapest fix: vary the horses, add people.

## g
- 1 Flat light: PASS (the lamp throws a big hard shadow of the post's brace on the wall; warm and cool separate)
- 2 No atmosphere: FAIL (`330 200 230 160`, the lamps down the porch; `g_lamps_no_air.jpg`)
- 3 Too clean: FAIL (`330 240 480 300`, hands and rifle; `g_g_hands_rifle.jpg`)
- 4 Too straight: PASS (the post and planks have grain, knots and wear)
- 5 Floating objects: PASS (barrel and boards sit together; the hands touch the rifle)
- 6 Repetition: PASS (one poster in view, lanterns down a porch are normal)
- 7 Empty: PASS (barrel, crate, poster, horses at the rail)
- 8 Scale tells: FAIL (`330 340 630 200`, the forearm; `g_forearm_huge.jpg`)
- 9 Edges of the world: PASS (the street continues into the dark)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A huge orange forearm across the shot** (tell 8, `330 340 630 200`): aimed down the barrel, the left forearm is a giant smooth slab running across half the bottom of the frame, far too big for the rifle, glowing orange in the lamplight, with no sleeve, hair or muscle shape. Cause: people. Cheapest fix: pull the arm in and down to a real shouldering pose and put a sleeve on it.
2. **The thumb sticks up beside the sights** (tell 3, `490 255 50 90`): the right thumb points straight up behind the receiver like a sausage, not resting on the stock; the hands are featureless clay with no knuckles. Cause: people. Cheapest fix: lay the thumb over the wrist of the stock and add skin detail.
3. **A pixel-art poster** (tell 3, `0 255 100 150`): the wanted poster is made of big chunky squares, mirrored lettering included; in this realistic porch it looks like a placeholder. Cause: material. Cheapest fix: a printed paper texture.
4. **The rifle is a flat black silhouette** (tell 3, `440 270 90 270`): from behind, the receiver and barrel are uniform black with one specular dot; the stock's wood is good. Cause: material. Cheapest fix: edge highlights and wear on the receiver.
5. **No air round the lamps** (tell 2, `330 200 230 160`): the lanterns glow but the porch air is perfectly clear. Cause: light. Cheapest fix: a faint haze around the lamps.

## h
- 1 Flat light: PASS (the wall lamp pools warm light, the street beyond is cool and dark)
- 2 No atmosphere: FAIL (`330 200 230 160`, lamps down the porch; `h_lamps_no_air.jpg`)
- 3 Too clean: FAIL (`150 250 600 290`, arms and rifle; `h_h_arms_rifle.jpg`)
- 4 Too straight: FAIL (`160 270 280 270`, the sling; `h_sling_rigid.jpg`)
- 5 Floating objects: FAIL (`430 370 120 90`, the lever hand; `h_lever_hand_floats.jpg`)
- 6 Repetition: FAIL (`20 260 220 210`, the two posters; `h_posters_repeat.jpg`)
- 7 Empty: PASS (barrel, crate, posters, horses: a lived-in porch)
- 8 Scale tells: PASS (rifle, arms and porch agree)
- 9 Edges of the world: PASS (the street continues into the dark)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The lever hand floats open beside the lever** (tell 5, `430 370 120 90`): with the lever thrown, the right hand is open with fingers splayed in the air, not inside the lever loop; the lever has moved on its own. Cause: people. Cheapest fix: keep the fingers through the lever loop through the whole throw.
2. **Bare orange arms with no sleeves** (tell 3, `150 330 300 210`): both forearms are smooth orange skin from wrist to the bottom edge, no sleeve, cuff, hair or tendons, the hands like rubber gloves. Cause: people. Cheapest fix: the shirt sleeves and cuffs that the day shots have, and skin detail.
3. **The sling is a rigid bar** (tell 4, `160 270 280 270`): a straight black strap from the muzzle end down past the arm, with no sag. Cause: geometry. Cheapest fix: a hanging, sagging sling.
4. **Two identical pixel-art posters** (tell 6, `20 260 220 210`): the same chunky-square poster twice, "REWARD" mirrored. Cause: material. Cheapest fix: one printed paper poster texture, varied.
5. **No air round the lamps** (tell 2, `330 200 230 160`): clear air down the lit porch, nothing catching the lamplight. Cause: light. Cheapest fix: a faint haze in the lamplight.

## Ranking
From least to most cheap-looking: e, f, a, c, h, d, g, b
