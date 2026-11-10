# Cheap judge, cheap_judge

## a
- 1 Flat light: PASS (`0 0 1600 900`: a low sun from behind-left, long hard shadows of posts across the street, the gun's frame shaded on its far side)
- 2 No atmosphere: PASS (`880 0 720 180`: the far street and canyon soften and warm into haze)
- 3 Too clean: FAIL (`656 168 240 360`, `cut a_a_frame.jpg`; also `400 400 352 448`, `cut a_a_grip.jpg`): the frame wears one mottled grey-green pattern edge to edge like lichen on a rock, with no edge wear where steel would rub bright; the grip is an even brown with a uniform black rim round it
- 4 Too straight: PASS (the frontier buildings and rails lean and vary enough; the gun is machined, so straight is right)
- 5 Floating objects: PASS (the gun hangs on purpose; the planter, horse and posts sit in their shadows)
- 6 Repetition: FAIL (`928 480 672 416`, `cut a_a_pebbles.jpg`): the same small grey stone repeated at an even spacing over the whole road
- 7 Empty: PASS (horse, people, planter box, wagon down the street)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (the canyon closes the street's end inside haze)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The frame's finish reads as camouflage, not case-hardened steel** (tell 3, `656 168 240 360`): a player sees a mossy stone or camo-print texture on the frame and hammer, evenly blotched everywhere, no colour-case blues and straws, no bright worn edges, and a fine screen-door speckle in it up close. Cause: material. Cheapest fix: replace the frame's colour with a darker steel base plus a soft case-colour wash, and let the edges and the hammer spur wear through to bright metal.
2. **The barrel's top glint blows out to a white flare** (tell 3, `1200 176 400 144`): the bluing behaves like clean chrome or wet plastic, one long perfect highlight running out of frame. Cause: material. Cheapest fix: raise the barrel's roughness a little and break it with a faint roughness map of fine lengthwise scratches.
3. **The grip is a flat brown slab with a black outline** (tell 3, `400 400 352 448`): the wood has faint grain but no figure, polish or handling wear, and the black rim round it reads as a cartoon outline. Cause: material. Cheapest fix: drop the black rim to a thin worn edge and add darker hand-worn varnish where the palm sits.
4. **Even pepper of identical pebbles** (tell 6, `928 480 672 416`): the same stone over and over, spaced like a grid sprinkled by script. Cause: dressing. Cheapest fix: cluster the stones along the ruts and edges, vary their size and colour, and drop half of them.
5. **The hammer spur is a flat slab cut to a point** (tell 3, `656 168 240 160`): it reads as a horn or a fin rather than a chequered, rounded spur, which a gun-minded player looks at first. Cause: geometry. Cheapest fix: round and thicken the spur with a bevel and a chequering normal on its top.

## b
- 1 Flat light: PASS (`0 0 1600 900`: strong sun, the gun's shadow side dark, tufts cast shadows)
- 2 No atmosphere: PASS (`0 0 1600 260`: the canyon walls fade and cool with distance)
- 3 Too clean: FAIL (`392 176 400 352`, `cut b_b_frame.jpg`): the same evenly mottled frame finish as camo, no wear at the edges; the cylinder a clean uniform dark blue with one painted streak
- 4 Too straight: PASS
- 5 Floating objects: PASS (the gun on purpose; tufts and stones sit in their shadows)
- 6 Repetition: FAIL (`0 480 480 420`, `cut b_b_pebbles.jpg`; also `1056 272 544 224`, `cut b_b_grass.jpg`): bright white pebbles scattered evenly like confetti; the grass tufts the same card again and again in a row
- 7 Empty: FAIL (`800 220 800 160`): a bare flat with a few dots of brush and nothing that says anyone was ever here
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 96 800 176`, `cut b_b_backdrop.jpg`): a smooth bald dune shape on the left meets the canyon as a hard cut-out, the horizon reads as a backdrop
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Confetti pebbles** (tell 6, `0 480 480 420`): pale, faceted stones of one size sprinkled evenly over the whole ground, the first thing your eye catches after the gun. Cause: dressing. Cheapest fix: darken them toward the ground's colour, vary size and cluster them in the ruts, and cut the count by more than half.
2. **The frame's camo finish** (tell 3, `392 176 400 352`): a noisy rock-like pattern evenly over every face of the frame, nothing worn bright. Cause: material. Cheapest fix: a darker steel base with a case-colour wash and bright edge wear.
3. **An empty flat to a backdrop** (tell 7/9, `0 96 800 176`): the ground runs bare to a smooth dune and a canyon wall with nothing in between, no fence, track or debris. Cause: dressing. Cheapest fix: one piece of human trace in the middle distance (a fence line, a wagon track's ruts with a dropped wheel, a cairn).
4. **Grass as repeated cards** (tell 6, `1056 272 544 224`): the same tuft, dark at the root and blond at the tips, copied in a line with stair-stepped edges. Cause: dressing. Cheapest fix: vary the tuft's scale, colour and tilt, and soften its alpha edge.
5. **The grip's black outline** (tell 3, `880 400 320 450`): an even dark rim round the wood reads as an inked outline, not a worn edge. Cause: material. Cheapest fix: a thin, uneven darker edge only where hands would wear it.

## c
- 1 Flat light: PASS (`0 0 1600 900`: low sun, long shadows of the horses across the street)
- 2 No atmosphere: FAIL (`600 0 1000 400`): the boardwalk, horses and fronts behind sit as sharp and saturated as the gun, no dust or haze between
- 3 Too clean: FAIL (`528 240 512 416`, `cut c_c_muzzle.jpg`): the barrel and ejector housing are clean smooth black tubes with no muzzle wear, no bright bore edge, no dirt
- 4 Too straight: PASS
- 5 Floating objects: PASS (gun on purpose; horses and boxes grounded)
- 6 Repetition: FAIL (`848 96 752 528`, `cut c_c_horses.jpg`): two identical horses with the same brown coat, white socks and saddle stood side by side
- 7 Empty: PASS (a man on the boardwalk, crates, tied horses)
- 8 Scale tells: FAIL (`528 240 512 416`): seen end-on the barrel's bore and the ejector housing read like two pipes of a double gun, the muzzle a thick-walled tube far too big for a .45
- 9 Edges of the world: PASS (the street is closed by fronts)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The muzzle reads as a toy pipe** (tell 8, `528 240 512 416`): from the front the barrel is a smooth black tube with a fat rounded lip and no rifling or bright crown; the housing under it reads as a second barrel. Cause: geometry. Cheapest fix: thin the muzzle wall to scale with a sharp, slightly bright crown and a dark rifled bore.
2. **Twin horses** (tell 6, `848 96 752 528`): the same horse, coat and saddle twice, right next to each other. Cause: dressing. Cheapest fix: a different coat or tack on one, or turn one away.
3. **Pixel-stepped grass right behind the gun** (tell 3/6, `640 400 400 220`): the tufts' blades break into stair-stepped squares and dark speckle, leftover squares right where the eye is. Cause: material. Cheapest fix: filter or anti-alias the grass's alpha (alpha-to-coverage) so the blades end in soft tips.
4. **Clean black tubes** (tell 3, `528 240 512 416`): no worn bluing at the muzzle, no wear on the ejector housing, the grip a striped black block. Cause: material. Cheapest fix: edge wear to grey steel on the muzzle and housing, and a real wood colour on the grip from this side.
5. **A faceted white rock in the foreground** (tell 3, `336 790 160 110`, `cut c_c_rock.jpg`): a low-poly stone with flat facets, pale and clean in the shade. Cause: geometry. Cheapest fix: a rounder, ground-coloured stone sunk partly into the dirt.

## d
- 1 Flat light: PASS (`0 0 1600 900`: low sun from the right, the street in shade under the fronts, light raking across the cylinder)
- 2 No atmosphere: PASS (`0 0 700 450`: the canyon and the far wagon go soft and warm in dusty haze)
- 3 Too clean: FAIL (`392 200 672 448`, `cut d_d_frame.jpg`): close up the frame is the same lichen-camo blotching all over, with a fine dither speckle and a stair-stepped serrated edge on the recoil shield; the cylinder a flat uniform blue-black
- 4 Too straight: PASS (the jail front and posts vary; the rails curve)
- 5 Floating objects: PASS (the gun on purpose; the people and wagon sit on the street)
- 6 Repetition: PASS
- 7 Empty: PASS (a lawman, a horse, a man walking, a wagon, the JAIL sign, barrels and brush)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (the canyon and sky close the street within haze)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The frame's camo finish, worst up close** (tell 3, `392 200 672 448`): a blotchy lichen pattern on every face, with a screen-door speckle and sawtooth edges where the recoil shield meets the cylinder; no case colours, no worn-bright edges. Cause: material. Cheapest fix: a darker steel base with a smooth case-colour wash and bright edge wear, and a cleaner normal on the shield's edge.
2. **The grip a black block with a light rim line** (tell 3, `160 528 480 372`, `cut d_d_grip.jpg`): the wood goes near black in the shade with a thin light line traced round its edge, reading as plastic with an outline. Cause: material. Cheapest fix: lift the wood's colour so grain reads in shade and drop the traced rim.
3. **A gold disc glowing in the hammer cut** (tell 3, `720 330 120 160`): a flat orange-yellow shape behind the cylinder reads as a texture hole rather than a cartridge's brass. Cause: material. Cheapest fix: give the cartridge base a darker brass with a primer and let the frame's shadow fall on it.
4. **The walking man a flat dark shape** (tell 3, `1024 384 144 336`, `cut d_d_man.jpg`): in the shade his clothes are one near-black mass, no cloth or edge light. Cause: light. Cheapest fix: a little more sky fill in the street's shade so cloth reads.
5. **The cylinder flat and uniform** (tell 3, `720 220 360 300`): one even blue-black with brushed lines, no turn-ring worn by the bolt, no edge wear on the flutes' ends. Cause: material. Cheapest fix: a worn turn-line and bright edges at the cylinder's front.

## e
- 1 Flat light: PASS (`0 0 1600 900`: sun from the left, the ground's stones cast shadows, the gun's far side dark)
- 2 No atmosphere: FAIL (`576 0 1024 160`): the dunes behind are as clear and even as the foreground, no haze or dust
- 3 Too clean: FAIL (`384 176 704 480`, `cut e_e_frame.jpg`): the frame's camo finish again, unworn; the barrel a smooth clean grey tube
- 4 Too straight: PASS
- 5 Floating objects: PASS (gun on purpose; the man and tufts grounded)
- 6 Repetition: FAIL (`944 128 656 272`, `cut e_e_grass.jpg`): one tuft card copied into a hedge-like row; the pebbles one stone at even spacing
- 7 Empty: FAIL (`576 0 1024 160`): bare dunes with nothing on them but a few dark blobs
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`576 0 1024 160`, `cut e_e_dunes.jpg`): smooth featureless dunes dotted with identical round blob bushes, like an unfinished terrain
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Blob-bush dunes for a horizon** (tell 9, `576 0 1024 160`): smooth, untextured slopes with a dozen olive spheres placed on them read as a greybox, not land. Cause: dressing. Cheapest fix: lay the ground's dirt and grass texture and real brush over the dunes, or fog them out.
2. **The frame's camo finish** (tell 3, `384 176 704 480`): the same rock-like mottling on every face, the top strap and hammer with no wear. Cause: material. Cheapest fix: a darker steel base with a case-colour wash and bright edge wear.
3. **A row of identical tufts** (tell 6, `944 128 656 272`): one grass card repeated into a hedge across the frame. Cause: dressing. Cheapest fix: vary scale, colour and spacing, break the row with gaps and bare ground.
4. **The grip a black tube from behind** (tell 3, `800 560 400 340`): from this side the grip's back strap and wood read as one black, outlined shape. Cause: material. Cheapest fix: let the wood's colour and grain read in shade and give the back strap a steel colour.
5. **The barrel a smooth grey pipe** (tell 3, `384 176 300 160`): no bluing depth, no wear, a plastic-looking even grey. Cause: material. Cheapest fix: darker blued steel with lengthwise wear and a roughness map.

## Ranking
From least to most cheap-looking: d, a, b, c, e
