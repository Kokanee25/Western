# Cheap judge, 2026-11-13_cheap_vmr_held

## a
- 1 Flat light: PASS (`700 490 580 230`: the revolver has a sun-side highlight and a dark side; the ruts and grass cast shadows)
- 2 No atmosphere: PASS (`0 130 1280 200`: the far mesas are paler and softer than the near ground)
- 3 Too clean: FAIL (`700 490 580 230`, `cut a_arm_gun.png`: the bare forearm is one smooth tan with no hair, dirt, sweat or sleeve; the revolver's bluing has no holster wear)
- 4 Too straight: FAIL (`0 380 600 340`, `cut a_pebbles_ruts.png`: the wheel ruts run as ruler-straight parallel grooves to the horizon)
- 5 Floating objects: FAIL (`700 490 580 230`, `cut a_arm_gun.png`: no hand closes on the grip; a thumb-like stub touches the cylinder and the grip hangs below with nothing holding it, so the gun floats beside the arm)
- 6 Repetition: FAIL (`560 340 720 200`, `cut a_grass_repeat.png`: the same yellow grass tuft with black underside stamped over and over; identical white pebbles sprinkled evenly)
- 7 Empty: FAIL (`0 320 560 80`, `cut a_flat_town.png`: the "town" is a pale flat pad with a crate stack, a plank wall and one man standing still)
- 8 Scale tells: FAIL (`700 490 580 230`, `cut a_arm_gun.png`: the forearm is as thick as the revolver is long and the "hand" is a single fat digit)
- 9 Edges of the world: FAIL (`0 0 1280 140`, `cut a_sky_posterised.png`: the sky is flat posterised bands of four colours, like a paint-by-numbers backdrop)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The hand isn't a hand** (tell 5, `700 490 580 230`): the player's "hand" is a faceted mitten with one thumb-like stub poking at the cylinder; no fingers wrap the grip and no trigger finger. The gun reads as glued beside the arm. Cause: geometry. Cheapest fix: pose real fingers around the grip (index on the trigger guard, three under it).
2. **A bare, faceted, clean forearm** (tell 3, `850 560 430 160`): low-poly creases show as hard triangles across the skin, and there is no sleeve, cuff, dirt or hair: it looks like a placeholder limb. Cause: material. Cheapest fix: put a rolled shirt sleeve or cuff on the forearm and smooth the normals.
3. **Posterised sky** (tell 9, `0 0 1280 280`): four flat colour bands with cut-out edges; it reads as a painted toy backdrop, not a sky. Cause: light. Cheapest fix: remove the colour quantising on the sky so it grades smoothly.
4. **An empty pad for a town** (tell 7, `140 320 400 40`): a flat, cracked, pale slab with a few crates and one figure; nothing says anyone lives here. Cause: dressing. Cheapest fix: add wagon, barrels, hitching posts and a second building edge to the pad.
5. **Stamped grass and pebbles** (tell 6, `560 340 720 200`): one grass tuft and one pebble repeated in even rows. Cause: dressing. Cheapest fix: vary tuft scale/hue and cluster the pebbles near ruts instead of scattering evenly.

## b
- 1 Flat light: PASS (`600 380 480 340`: the arm has a lit top and a shadowed underside; the grass casts shadows)
- 2 No atmosphere: PASS (`0 160 1280 180`: the mesas fade warm and soft with distance)
- 3 Too clean: FAIL (`580 360 520 360`, `cut b_arm_gun.png`: the forearm is a smooth, hairless, unworn tan tube; the revolver is a mirror-chrome stick)
- 4 Too straight: FAIL (`0 380 560 340`, `cut b_pebbles_ruts.png`: parallel ruts drawn with a ruler)
- 5 Floating objects: FAIL (`580 360 520 360`, `cut b_arm_gun.png`: the gun stands upright beside the wrist; smeared finger-blobs at its side don't close on anything)
- 6 Repetition: FAIL (`700 360 580 260`, `cut b_grass_repeat.png`: the same tuft card copied across the field)
- 7 Empty: FAIL (`150 320 400 70`, `cut b_flat_town.png`: a flat pad with crates and one standing man)
- 8 Scale tells: FAIL (`580 360 520 360`, `cut b_arm_gun.png`: the forearm fills a quarter of the frame and dwarfs the pistol; it reads as a giant's arm or a camera inside the elbow)
- 9 Edges of the world: FAIL (`0 0 1280 160`, `cut b_sky_posterised.png`: posterised paint-band sky; a lone shack at the left edge cut off by the frame with nothing around it)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A huge tube of an arm with no hand** (tell 8, `580 360 520 360`): the forearm is enormous, swells toward the camera like a fisheye, and ends in smudged blobs instead of fingers; the gun is held upright like a candle. Cause: camera. Cheapest fix: narrow the viewmodel FOV and pull the arm down and out so the hand, not the forearm, leads the frame.
2. **Gun not gripped** (tell 5, `590 360 80 200`): the chrome revolver stands at the side of the fist with no fingers around it. Cause: geometry. Cheapest fix: a proper closed-grip hand pose on the stocks.
3. **Bare, smeared skin** (tell 3, `600 400 450 320`): no sleeve, the skin texture streaks along the length of the arm like a stretched decal. Cause: material. Cheapest fix: a sleeve to the wrist so only the hand is skin.
4. **Posterised sky** (tell 9, `0 0 1280 280`): flat colour bands; reads as a painted dome. Cause: light. Cheapest fix: smooth sky gradients (no quantise on the sky).
5. **Empty, stamped landscape** (tell 6, `700 360 580 260`): repeated tufts and evenly sprinkled pebbles round an empty town pad. Cause: dressing. Cheapest fix: vary and cluster the scatter; put props on the pad.

## c
- 1 Flat light: FAIL (`460 340 340 380`, `cut c_gun_hands.png`: the gun's flat sides are one even saturated blue with a single blown white streak down the barrel; no shaped shadow from the hands)
- 2 No atmosphere: PASS (`0 160 1280 180`: distance hazes and softens)
- 3 Too clean: FAIL (`460 340 340 380`, `cut c_gun_hands.png`: the gun is spotless flat blue, like painted plastic)
- 4 Too straight: FAIL (`0 380 560 340`, `cut c_pebbles_ruts.png`: ruler-straight ruts)
- 5 Floating objects: FAIL (`450 420 330 300`, `cut c_hands_fingers.png`: the left fingers lie flat on the ground plane beside the receiver rather than under the fore-end; the right hand is a smeared lump on the stock)
- 6 Repetition: FAIL (`700 360 580 260`, `cut c_grass_repeat.png`: repeated tufts)
- 7 Empty: FAIL (`150 320 400 70`, `cut c_flat_town.png`: an empty pad with a few crates)
- 8 Scale tells: FAIL (`460 340 340 380`, `cut c_gun_hands.png`: the receiver is a fat box as wide as both hands; the front sight looks like a little crown)
- 9 Edges of the world: FAIL (`0 0 1280 160`, `cut c_sky_posterised.png`: posterised sky bands)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Toy-blue box of a gun** (tell 3, `570 360 140 360`): seen end-on the rifle is a flat, saturated royal-blue box with a hot white stripe; it reads as painted plastic, not blued steel. Cause: material. Cheapest fix: darken and desaturate the bluing toward near-black with a rough, worn sheen.
2. **Melted hands** (tell 5, `450 420 330 300`): the fingers are smeared, stair-stepped blobs; the left ones lie off to the side not touching the wood. Cause: geometry. Cheapest fix: a clean hand mesh with fingers curled under the fore-end.
3. **One hot specular streak** (tell 1, `620 400 40 80`): a single blown highlight down the barrel, everything else flat. Cause: light. Cheapest fix: raise the roughness so the highlight spreads and dims.
4. **Posterised sky** (tell 9, `0 0 1280 280`): banded flat colour. Cause: light. Cheapest fix: unquantised sky.
5. **Empty town pad and stamped scatter** (tell 7, `150 320 400 70`): nothing on the street. Cause: dressing. Cheapest fix: dress the pad.

## d
- 1 Flat light: PASS (`600 450 420 270`: the receiver has a lit top edge and darker side; the hands have shadowed creases)
- 2 No atmosphere: PASS (`0 130 1280 200`: mesas soften with distance)
- 3 Too clean: FAIL (`600 450 420 270`, `cut d_rifle_hands.png`: the receiver is a flat black slab with an outline drawn on it, no wear on edges; hands bare with no sleeve)
- 4 Too straight: FAIL (`0 380 600 340`, `cut d_pebbles_ruts.png`: straight parallel ruts)
- 5 Floating objects: PASS (`600 450 420 270`: the left hand cups the fore-end and the right is round the wrist of the stock; the gun is held)
- 6 Repetition: FAIL (`560 340 720 200`, `cut d_grass_repeat.png`: repeated tufts and evenly sprinkled pebbles)
- 7 Empty: FAIL (`0 320 560 80`, `cut d_flat_town.png`: empty pad, a few crates, one figure)
- 8 Scale tells: PASS (`600 450 420 270`: hands and rifle are in proportion)
- 9 Edges of the world: FAIL (`0 0 1280 140`, `cut d_sky_posterised.png`: posterised sky bands)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Bare hands with smeared paint** (tell 3, `640 520 220 200`): the hands are held right, but their skin is a blotchy hand-painted smear with dark stains at the fingertips and no sleeve or cuff, so they end in nothing at the wrist. Cause: material. Cheapest fix: sleeves to the wrist and a cleaner skin texture with knuckle detail.
2. **Receiver like a cut-out** (tell 3, `740 520 200 160`): a flat black plate with a drawn panel line, no engraving, edge wear or bevel highlight. Cause: material. Cheapest fix: a worn-edge mask so the corners catch the light.
3. **Posterised sky** (tell 9, `0 0 1280 280`): flat colour bands. Cause: light. Cheapest fix: smooth sky.
4. **Empty town pad** (tell 7, `140 320 400 40`): nothing lived-in on the street. Cause: dressing. Cheapest fix: dress the pad.
5. **Stamped grass and pebbles** (tell 6, `560 340 720 200`): uniform scatter. Cause: dressing. Cheapest fix: vary and cluster.

## e
- 1 Flat light: PASS (`800 0 480 400`: warm lamps with pools of light, a sun shaft through the door, dark corners)
- 2 No atmosphere: PASS (`1100 230 180 200`: the back of the saloon glows warm and soft through the lamplight)
- 3 Too clean: FAIL (`700 460 580 260`, `cut e_arm_gun.png`: bare, clean, faceted forearm with no sleeve)
- 4 Too straight: PASS (`0 0 310 700`: planks vary in tone and width; floor boards vary)
- 5 Floating objects: FAIL (`700 460 580 260`, `cut e_arm_gun.png`: no fingers close on the revolver's grip; a stub touches the cylinder and the gun hangs off it)
- 6 Repetition: PASS (`800 0 480 600`: varied lamps, posters, crates, people)
- 7 Empty: PASS (`900 30 380 560`: people, crates, posters, lamps, barrels)
- 8 Scale tells: FAIL (`700 460 580 260`, `cut e_arm_gun.png`: forearm as thick as the man's thigh across the room; one fat digit for a hand)
- 9 Edges of the world: FAIL (`410 40 340 460`, `cut e_door_blur.png`: the swinging door is a blurry, low-resolution grid of smeared squares, like a texture that never loaded)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Broken door texture** (tell 9, `410 40 340 460`): the big door panel is a blurred grid of purple-brown squares, the first thing the eye lands on; it reads as a missing texture. Cause: material. Cheapest fix: give the door the same plank material as the walls beside it.
2. **The hand isn't a hand** (tell 5, `700 460 580 260`): same fingerless mitten as outdoors; the grip hangs with nothing around it. Cause: geometry. Cheapest fix: a real closed-grip pose.
3. **Faceted bare forearm** (tell 3, `850 560 430 160`): hard triangle creases in the skin and no sleeve, glaring next to a well-dressed townsman. Cause: material. Cheapest fix: sleeve and smoothed normals.
4. **Hard letter-shaped shadow and mirrored posters** (tell 4, `800 0 200 480`, `cut e_wall_shadow.png`): a giant crisp "Y" shadow slashes across the wall and the wanted posters' lettering is mirrored and garbled ("MANTED"). Cause: dressing. Cheapest fix: flip the poster text; soften or move the sign casting the shadow.
5. **Candy-striped walls** (tell 3, `0 0 310 700`, `cut e_plank_wall.png`): the left wall's planks alternate saturated red and blue-grey, more paint swatch than weathered wood. Cause: material. Cheapest fix: pull the plank colours toward one weathered brown-grey.

## Ranking
From least to most cheap-looking: d, e, a, c, b
