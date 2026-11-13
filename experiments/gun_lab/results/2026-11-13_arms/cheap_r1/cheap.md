# Cheap judge, 2026-11-13_cheap_harlan_arms_r1

## a
- 1 Flat light: PASS (`0 0 960 540`: a clear low sun from the left, awning and grass shadows across the street, fronts shaded)
- 2 No atmosphere: FAIL (`300 180 260 100`; `a_sharp_mesas_sky.png`: the mesas as crisp and saturated as the near street, the sky a posterised, painted cloud pattern with hard tone bands)
- 3 Too clean: FAIL (`100 280 760 260`; `a_clean_ruts_pebbles.png`: an even dust street with evenly sprinkled white pebbles, no dung, hoofprints, puddles or litter, no dirt up the boardwalk edges)
- 4 Too straight: FAIL (`100 280 760 260`; `a_clean_ruts_pebbles.png`: the wheel ruts run as ruler-straight parallel lines to the vanishing point)
- 5 Floating objects: PASS (`130 240 780 150`: horses, posts and the trough carry contact shadows)
- 6 Repetition: FAIL (`130 240 780 150`; `a_same_horses_empty.png`: the same bay horse with the same saddle, white socks and pose four times along the street)
- 7 Empty: FAIL (`130 240 780 150`; `a_same_horses_empty.png`: a whole main street at midday with no person in it, only tied horses)
- 8 Scale tells: FAIL (`540 330 280 210`; `a_hand_blob.png`: the gun hand fills a fifth of the frame, a huge smooth orange paw dwarfing the revolver)
- 9 Edges of the world: FAIL (`0 440 960 30`; `a_debug_text.png`: a yellow debug banner "Salt Creek froze last time ... /root/.local/share/godot/..." printed across the picture)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The gun hand is an orange rubber paw** (tell 8, `540 330 280 210`): a giant smooth, uniformly orange-tan hand with sausage fingers and no knuckles, nails, veins or hair; no shirt cuff anywhere, the arm just a featureless skin tube out of the frame corner. Cause: material. Cheapest fix: a desaturated, mottled skin albedo with knuckle/nail detail and a sleeve cuff at the wrist, and a hand scaled to the gun.
2. **The revolver is held wrong and its grip is a smeared texture** (tell 8, `540 330 280 210`): the gun sits on top of the fist at an angle, barrel up-left, the grip a column of stretched brown stripes (UV smear), the fingers not wrapped round it. Cause: geometry. Cheapest fix: fix the grip's UVs and pose the fingers closed round the grip with the trigger finger on the guard.
3. **A debug banner across the frame** (tell 9, `0 440 960 30`): a crash-report line printed over the world. Cause: camera. Cheapest fix: hide the report notice in screenshots and release builds.
4. **An empty town of repeated horses** (tells 6, 7, `130 240 780 150`): the same horse four times, no people. Cause: dressing. Cheapest fix: vary coat and tack per horse and put two or three townsfolk on the boardwalks.
5. **Clean, ruled street and painted sky** (tells 2, 3, 4, `100 280 760 260`): ruts like rails, pebbles sprinkled evenly, a posterised sky and razor-sharp distance. Cause: material. Cheapest fix: break the ruts with hoofprints and dung, and add distance haze that softens and cools the mesas.

## b
- 1 Flat light: PASS (`0 0 960 540`: sun from the left, the fronts and awnings shade properly)
- 2 No atmosphere: FAIL (`280 160 280 130`; `b_sharp_mesas_sky.png`: mesas crisp and saturated, sky a posterised pattern)
- 3 Too clean: FAIL (`0 380 960 160`; `b_ruts_pebbles.png`: an even dust street sprinkled with the same white pebbles, no wear or dirt)
- 4 Too straight: FAIL (`0 380 960 160`; `b_ruts_pebbles.png`: ruts as ruler lines)
- 5 Floating objects: PASS (`0 240 960 180`: horses and trough sit with contact shadows)
- 6 Repetition: FAIL (`0 240 960 180`; `b_same_horses_empty.png`: the same saddled bay horse repeated)
- 7 Empty: FAIL (`0 240 960 180`; `b_same_horses_empty.png`: no one in the street)
- 8 Scale tells: FAIL (`400 330 290 210`; `b_thumb_blob.png`: the thumb alone is as big as the whole revolver, a sausage that fills the lower middle of the frame)
- 9 Edges of the world: PASS (`0 250 960 60`: the street ends on a plain and mesas, no seam)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A giant orange thumb blocks the aim** (tell 8, `400 330 290 210`): aiming down the sights, a smooth, shiny-orange thumb the size of a loaf covers a third of the lower frame; no nail, no creases, one flat skin tone. Cause: geometry. Cheapest fix: lay the thumb along the frame's side as a real one-hand aim (or a two-hand cup) and pull the hand lower and smaller in the view.
2. **The grip is a smear of stretched texels** (tell 3, `440 280 80 260`; `b_gun_grip.png`): seen from behind, the revolver grip is a column of vertical stripes, plainly a broken texture. Cause: material. Cheapest fix: correct the grip's UVs or give it a proper wood/hard-rubber material.
3. **Fingers stuck on like pills** (tell 8, `400 330 290 210`): the three fingers in front of the grip are separate rounded pegs, not wrapped round anything; no wrist, no cuff, no sleeve. Cause: geometry. Cheapest fix: close the fingers round the grip and show a shirt cuff at the wrist.
4. **Empty street of one horse** (tells 6, 7, `0 240 960 180`): the same horse repeated, no people. Cause: dressing. Cheapest fix: vary the horses and add people.
5. **Painted sky, sharp distance** (tell 2, `280 160 280 130`): posterised clouds, no haze before the mesas. Cause: light. Cheapest fix: a smoother sky and aerial haze.

## c
- 1 Flat light: PASS (`0 0 960 540`: directional sun, cast shadows on the street)
- 2 No atmosphere: FAIL (`300 180 260 100`; `c_sharp_mesas_sky.png`: crisp, saturated mesas, posterised sky)
- 3 Too clean: FAIL (`100 280 760 260`; `c_clean_ruts_pebbles.png`: even dust, even pebbles, no dirt)
- 4 Too straight: FAIL (`100 280 760 260`; `c_clean_ruts_pebbles.png`: ruler-straight ruts)
- 5 Floating objects: PASS (`130 240 780 150`: contact shadows under horses and trough)
- 6 Repetition: FAIL (`130 240 780 150`; `c_same_horses_empty.png`: the same horse repeated)
- 7 Empty: FAIL (`130 240 780 150`; `c_same_horses_empty.png`: no people)
- 8 Scale tells: FAIL (`400 270 320 270`; `c_tilted_gun_hand.png`: a long bare orange forearm and fist, chunky beside a toy-small revolver)
- 9 Edges of the world: PASS (`0 250 960 60`: no seam)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The cocked revolver isn't really held** (tell 8, `400 270 320 270`; `c_tilted_gun_hand.png`): the gun juts out of the top of a fist at 45 degrees, the hand closed round the cylinder rather than the grip, no thumb on the hammer, so cocking doesn't read. Cause: geometry. Cheapest fix: re-pose the hand on the grip with the thumb on the hammer spur.
2. **Bare orange tube for an arm** (tell 3, `400 270 320 270`): a smooth, single-tone orange arm from wrist to frame edge, no sleeve, no hair, no tendons, faintly plastic. Cause: material. Cheapest fix: a rolled shirt sleeve on the forearm and a mottled, less saturated skin.
3. **Toy-blue gun with a striped grip** (tell 3, `400 270 320 270`): the steel reads candy-blue, the grip a stretched texture smear. Cause: material. Cheapest fix: darker, worn blued steel with edge wear, and fixed grip UVs.
4. **Empty street, cloned horses** (tells 6, 7, `130 240 780 150`): no people, same horse four times. Cause: dressing. Cheapest fix: vary horses, add townsfolk.
5. **Ruled ruts and painted sky** (tells 2, 3, 4, `100 280 760 260`): clean street, posterised clouds, no haze. Cause: material. Cheapest fix: hoofprints and dung in the ruts, aerial haze.

## d
- 1 Flat light: PASS (`60 80 400 360`: the wall lantern throws a warm pool and hard post shadows on the planks, the rest falls to dark)
- 2 No atmosphere: FAIL (`380 230 260 230`; `d_boardwalk_no_air.png`: the lamplit boardwalk is clear as glass, no smoke or dust in the light)
- 3 Too clean: PASS (`0 0 380 460`: the wall's red paint is flaked and weathered, the planks varied)
- 4 Too straight: PASS (`300 0 400 300`: the porch beams vary and the wall boards wander)
- 5 Floating objects: PASS (`280 380 140 120`: the barrel and crates sit with contact shadow)
- 6 Repetition: FAIL (`30 260 210 200`; `d_garbled_posters.png`: two copies of the same wanted poster side by side)
- 7 Empty: FAIL (`680 160 280 200`; `d_empty_night_street.png`: the night street beyond has only a dark horse; no one on the boardwalk)
- 8 Scale tells: FAIL (`570 350 230 190`; `d_orange_hand.png`: the gun hand is a huge glowing orange mitten next to the revolver)
- 9 Edges of the world: FAIL (`0 440 960 30`; `d_debug_text.png`: a yellow debug banner "The game stalled over 5 s ..." across the picture)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Garbled wanted posters** (tell 6, `30 260 210 200`; `d_garbled_posters.png`): the posters read "KEMARD" and "MUNTED", the numbers mangled, the face a blocky pixel sprite; it looks generated, and it is at eye level. Cause: material. Cheapest fix: hand-lettered poster textures with correct words, a drawn face, and two different posters.
2. **A sunlit orange hand at night** (tell 8, `570 350 230 190`; `d_orange_hand.png`): under lamplight the hand stays bright orange as if lit by day, a smooth mitten with peg fingers, no sleeve; it ignores the lantern's warm light and the night's dark. Cause: light. Cheapest fix: light the arms by the scene's lights (no unshaded/emissive skin) and give them a cuff.
3. **The revolver is a smear in the hand** (tell 3, `570 350 230 190`): the grip a column of stretched stripes, the fingers not round it. Cause: material. Cheapest fix: fix the grip UVs and close the fingers.
4. **A debug banner across the frame** (tell 9, `0 440 960 30`): crash-report text over the world. Cause: camera. Cheapest fix: hide the notice in screenshots and release builds.
5. **No air in the lamplight, no one about** (tells 2, 7, `380 230 260 230`): the boardwalk's lamps cast clean pools in clear air, and the porch is empty. Cause: light. Cheapest fix: a thin volumetric haze catching the lanterns, and one figure in a doorway.

## e
- 1 Flat light: PASS (`0 0 960 540`: sun from the left, cast shadows of the rifle and arms on the ground)
- 2 No atmosphere: FAIL (`300 180 260 100`; `e_sharp_mesas_sky.png`: crisp mesas, posterised sky)
- 3 Too clean: FAIL (`100 280 760 140`; `e_ruts_pebbles.png`: even dust with sprinkled pebbles, no wear)
- 4 Too straight: FAIL (`100 280 760 140`; `e_ruts_pebbles.png`: ruler-straight ruts)
- 5 Floating objects: PASS (`130 240 780 150`: contact shadows under horses)
- 6 Repetition: FAIL (`130 240 780 150`; `e_same_horses_empty.png`: cloned horses)
- 7 Empty: FAIL (`130 240 780 150`; `e_same_horses_empty.png`: no people)
- 8 Scale tells: PASS (`230 330 640 210`: arms, hands and rifle read at a believable size for a two-hand carry)
- 9 Edges of the world: PASS (`0 250 960 60`: no seam)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **A plain, clean sleeve and orange skin** (tell 3, `230 330 640 210`; `e_sleeve_rifle.png`): the cream shirt sleeve is a smooth tube with a faint weave and no folds, creases, sweat or dust; the hands are a single saturated orange with no knuckle or nail detail. Cause: material. Cheapest fix: fold and crease normals and dust on the sleeve; a desaturated, mottled skin.
2. **Hands placed, not gripping** (tell 8, `230 330 640 210`; `e_sleeve_rifle.png`): the forend hand's thumb sticks straight up past the barrel; the right thumb lies flat on the receiver's side plate and the fingers hang below the lever, so the rifle seems to rest on the hands. Cause: geometry. Cheapest fix: wrap the left fingers under the forend and put the right hand through the lever loop, thumb over the wrist of the stock.
3. **A toy-clean rifle** (tell 3, `230 330 640 210`): the receiver is an even, saturated blue-black with no wear on the edges, the wood unmarked. Cause: material. Cheapest fix: worn edges and handling marks on the steel, darker oil-dulled wood.
4. **Empty street, cloned horses** (tells 6, 7, `130 240 780 150`): no people, the same horse four times. Cause: dressing. Cheapest fix: vary horses, add townsfolk.
5. **Ruled ruts and painted sky** (tells 2, 3, 4, `100 280 760 140`): clean street, posterised clouds, no haze. Cause: material. Cheapest fix: hoofprints in the ruts, aerial haze.

## f
- 1 Flat light: PASS (`0 0 960 540`: sun from the left, cast shadows of rifle and arms)
- 2 No atmosphere: FAIL (`300 180 260 100`; `f_sharp_mesas_sky.png`: crisp mesas, posterised sky)
- 3 Too clean: FAIL (`100 280 760 140`; `f_ruts_pebbles.png`: even dust and pebbles)
- 4 Too straight: FAIL (`100 280 760 140`; `f_ruts_pebbles.png`: ruler ruts)
- 5 Floating objects: PASS (`130 240 780 150`: contact shadows)
- 6 Repetition: FAIL (`130 240 780 150`; `f_same_horses_empty.png`: cloned horses)
- 7 Empty: FAIL (`130 240 780 150`; `f_same_horses_empty.png`: no people)
- 8 Scale tells: PASS (`230 330 640 210`: believable sizes)
- 9 Edges of the world: PASS (`0 250 960 60`: no seam)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Lever thrown, but the hand doesn't show it** (tell 8, `230 330 640 210`; `f_sleeve_rifle.png`): the pose is the same as the idle carry; the lever hand's fingers hang below the loop rather than through it, so nothing says the action is working. Cause: geometry. Cheapest fix: the fingers through the loop and the lever visibly swung down and forward.
2. **Plain sleeve, orange skin** (tell 3, `230 330 640 210`): a smooth cream tube of a sleeve with no folds or dirt, the hands one saturated orange. Cause: material. Cheapest fix: creased, dusty sleeve; mottled skin.
3. **Forend thumb sticking up** (tell 8, `230 330 640 210`): the left thumb points straight up past the barrel as if not holding it. Cause: geometry. Cheapest fix: wrap the hand under the forend.
4. **Empty street, cloned horses** (tells 6, 7, `130 240 780 150`): no people, same horse. Cause: dressing. Cheapest fix: vary horses, add people.
5. **Ruled ruts and painted sky** (tells 2, 3, 4, `100 280 760 140`): clean street, posterised clouds, sharp mesas. Cause: material. Cheapest fix: hoofprints, aerial haze.

## g
- 1 Flat light: FAIL (`0 300 500 240`; `g_flat_night_ground.png`: the night ground is one even grey-blue moonlit wash with no pools or shadow shapes)
- 2 No atmosphere: FAIL (`40 220 460 120`; `g_bare_dunes.png`: the dunes and the plain sit in clear air, no night mist or depth falloff)
- 3 Too clean: FAIL (`40 220 460 120`; `g_bare_dunes.png`: the dunes are perfectly smooth, untextured mounds)
- 4 Too straight: PASS (`500 0 120 360`: the porch post is weathered with knots and grain)
- 5 Floating objects: PASS (`0 300 500 240`: the brush and rails sit on the ground)
- 6 Repetition: PASS (`0 300 500 240`: nothing visibly cloned)
- 7 Empty: FAIL (`40 220 460 120`; `g_bare_dunes.png`: a bare plain with scattered grey blocks and nothing alive)
- 8 Scale tells: FAIL (`330 260 630 280`; `g_glowing_arms.png`: the right forearm is a giant orange log filling the lower right third of the frame)
- 9 Edges of the world: FAIL (`0 0 270 270`; `g_black_slab.png`: a flat black rectangle with a hard edge stands against the sky at top left)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A glowing orange log of an arm** (tell 8, `330 260 630 280`; `g_glowing_arms.png`): aiming the rifle, the right forearm is a huge, smooth, bright-orange tube that fills a third of the frame and shines as if lit by a sun the rest of the night scene doesn't have. Cause: light. Cheapest fix: light the arms by the scene (moon and lamp) and pull the arm out of the camera so the cheek-weld view shows the rifle, not the forearm.
2. **No sleeve, no hand detail** (tell 3, `330 260 630 280`): bare skin from the frame edge to the fingers, the left hand a smooth mitten under the forend, no cuff, cloth or knuckles. Cause: material. Cheapest fix: a rolled sleeve and skin detail.
3. **A black slab against the sky** (tell 9, `0 0 270 270`; `g_black_slab.png`): a featureless black rectangle with a ruler edge, like a missing wall or a hole in the world. Cause: geometry. Cheapest fix: light the building's face (moon fill or a lit window) or give its silhouette a roofline.
4. **Smooth, empty dunes and grey blocks** (tells 3, 7, `40 220 460 120`): placeholder-smooth mounds and boxes on a flat plain. Cause: geometry. Cheapest fix: break the dunes with scrub and rock, and replace the blocks with real props.
5. **Flat moonlight, clear air** (tells 1, 2, `0 300 500 240`): the whole ground evenly grey-blue, no mist or pools. Cause: light. Cheapest fix: darker night ground with low mist and one warm window pool.

## h
- 1 Flat light: FAIL (`0 280 300 200`; `h_flat_night_ground.png`: an even grey-blue wash over the ground and rails)
- 2 No atmosphere: FAIL (`120 70 380 230`; `h_flat_mesa_dune.png`: the mesa a flat black cutout and the dune a smooth pale mound, no mist between them)
- 3 Too clean: FAIL (`740 320 200 220`; `h_clean_crates.png`: the crates are fresh pale boards, unmarked)
- 4 Too straight: PASS (`490 0 450 330`: the porch timbers are knotted and vary)
- 5 Floating objects: FAIL (`160 280 480 260`; `h_open_hands.png`: the rifle floats over open, splayed hands)
- 6 Repetition: PASS (`740 320 200 220`: two crates, not obviously cloned)
- 7 Empty: FAIL (`120 70 380 230`; `h_flat_mesa_dune.png`: a bare plain, no one about)
- 8 Scale tells: PASS (`160 280 480 260`: the arms and rifle are of plausible size)
- 9 Edges of the world: FAIL (`0 400 180 140`; `h_clipped_object.png`: a dark object, apparently part of the player's own kit or body, clips into the lower-left corner)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The hands don't hold the rifle** (tell 5, `160 280 480 260`; `h_open_hands.png`): during the lever throw the left hand is an open palm with fingers splayed under the forend, and the right hand's fingers spread beside the receiver; the rifle floats between them. Cause: geometry. Cheapest fix: close the left hand round the forend and put the right fingers through the lever loop in every frame of the throw.
2. **Glowing orange arms with a blown-out wrist** (tell 1, `160 280 480 260`): bare, saturated orange skin at night, as if sunlit, with a white specular flare on the left wrist; no sleeve. Cause: light. Cheapest fix: light the arms by the scene and lower the skin's specular; add a rolled sleeve.
3. **Something clips into the corner** (tell 9, `0 400 180 140`; `h_clipped_object.png`): a dark yellow-and-blue shape cut by the frame at bottom left, unreadable. Cause: camera. Cheapest fix: keep the player's own body and kit out of the viewmodel camera's near field.
4. **Cardboard mesa and smooth dune** (tell 2, `120 70 380 230`): the far rock a flat black cutout, the dune a featureless mound. Cause: geometry. Cheapest fix: moonlit rim and low mist on the mesa, scrub on the dune.
5. **New-looking crates on an old porch** (tell 3, `740 320 200 220`): pale, clean boards next to weathered posts. Cause: material. Cheapest fix: the porch's weathered wood on the crates, with dirt at their feet.

## Ranking
From least to most cheap-looking: e, f, d, a, c, b, h, g
