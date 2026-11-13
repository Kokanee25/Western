# Cheap judge, 2026-11-13_cheap_vmr_fp

## a
- 1 Flat light: PASS (`0 380 1280 340`: low sun, rut and grass shadows, the arm shaded top to bottom)
- 2 No atmosphere: FAIL (`0 0 1280 330`; `a_a_sky_mesa.png`: posterised, painted cloud bands; mesas nearly as crisp as the foreground, no dust in a low desert sun)
- 3 Too clean: FAIL (`700 490 580 230`; `a_a_arm_gun.png`: revolver pristine and evenly blued, no holster wear, no dirt on the skin)
- 4 Too straight: FAIL (`0 380 700 340`; `a_ruts_pebbles.png`: wheel ruts ruler-straight and parallel all the way to the vanishing point)
- 5 Floating objects: FAIL (`700 490 580 230`; `a_a_arm_gun.png`: no fingers on the revolver; it hangs in the air beside the arm)
- 6 Repetition: FAIL (`0 380 700 340`; `a_ruts_pebbles.png`: identical white pebbles sprinkled evenly; identical green dome shrubs on the plain)
- 7 Empty: FAIL (`0 280 1280 110`; `a_horizon.png`: a flat grey plain with two fence panels, three crates and one figure for a "town")
- 8 Scale tells: FAIL (`750 580 530 140`; `a_a_arm_gun.png`: the skin mass in the foreground is far bigger than the revolver it should be holding)
- 9 Edges of the world: FAIL (`0 280 1280 110`; `a_horizon.png`: the flat ground plane meets the mesa backdrop in a hard line; fence panels stand alone with nothing behind them)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The hand is a featureless skin blob** (tell 8, `750 580 530 140`): what should be the gun hand is a bulging, fingerless pink mound, like a knee or a sausage, filling the bottom right. Cause: geometry. Cheapest fix: pull the camera back or turn the wrist so fingers and a sleeve read; never let the back of a bare hand fill a quarter of the frame.
2. **Nobody is holding the gun** (tell 5, `710 500 210 140`): the revolver floats beside the arm with no fingers through the guard or round the grip. Cause: geometry. Cheapest fix: fit the hand pose to the grip so fingers visibly wrap it.
3. **Toy-clean blued revolver** (tell 3, `710 500 210 140`): one even saturated blue, mirror highlight, no worn edges. Cause: material. Cheapest fix: desaturate the bluing toward grey-black and add edge wear on the cylinder flutes and muzzle.
4. **Painted, posterised sky** (tell 2, `0 0 1280 330`): flat cream and slate bands like a painted backdrop next to a realistic ground; reads as two styles pasted together. Cause: light. Cheapest fix: a smoothly graded sky with soft clouds plus a little warm haze over the mesas.
5. **Empty, straight-ruled plain** (tells 4, 7, `0 280 1280 440`): perfectly straight ruts, evenly sprinkled pebbles, a "town" of three crates. Cause: dressing. Cheapest fix: bend and break the ruts and cluster the stones, and put a few real buildings at the end of the road.

## b
- 1 Flat light: PASS (`0 380 1280 340`: sun from the right, the sleeve shaded, rut shadows)
- 2 No atmosphere: FAIL (`0 0 1280 330`; `b_sky_mesa.png`: the same posterised painted sky, little haze on the mesas)
- 3 Too clean: FAIL (`530 360 480 360`; `b_b_hand_sleeve.png`: the cuff a spotless cream ring, the coat sleeve one even dark brown with no dust, fraying or creases at the elbow)
- 4 Too straight: FAIL (`0 380 540 340`; `b_ruts_pebbles.png`: ruler-straight ruts)
- 5 Floating objects: FAIL (`530 360 480 360`; `b_b_hand_sleeve.png`: the hand is open and empty; the revolver peeks out beyond it at the top, held by nothing)
- 6 Repetition: FAIL (`0 380 540 340`; `b_ruts_pebbles.png`: identical pebbles and grass clumps)
- 7 Empty: FAIL (`0 250 640 120`; `b_horizon.png`: a lone shack, fence panels and one figure on a bare plain)
- 8 Scale tells: PASS (`530 360 480 360`: hand, cuff and sleeve are in proportion)
- 9 Edges of the world: FAIL (`0 250 640 120`; `b_horizon.png`: the shack and panels stand alone; ground meets the backdrop mesas in a hard seam)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The gun floats beyond an empty hand** (tell 5, `600 360 80 30`): the hand makes a loose shape with nothing in it while the blue revolver hangs ahead of it. Cause: geometry. Cheapest fix: parent the gun to the palm and close the fingers on it.
2. **Spotless costume** (tell 3, `530 360 480 360`): the cuff is a clean cream tube and the sleeve has no dust, sweat or wear for a man on a desert road. Cause: material. Cheapest fix: dust and grime the cuff edge and the sleeve's lower half, add a few creases at the wrist.
3. **Painted sky over a realistic ground** (tell 2, `0 0 1280 330`): the posterised cloud bands read as a cartoon backdrop. Cause: light. Cheapest fix: smooth sky gradient and haze on the far mesas.
4. **Empty plain, lone props** (tells 7, 9, `0 250 640 120`): the shack and fence panels look dropped on a flat floor. Cause: dressing. Cheapest fix: tie the props together with a fence line, a trail and ground clutter around them.
5. **Straight ruts, sprinkled pebbles** (tells 4, 6, `0 380 540 340`): too regular to be a worn road. Cause: dressing. Cheapest fix: wobble the ruts and cluster the stones.

## c
- 1 Flat light: PASS (`570 380 140 200`: a strong sun highlight on the receiver, shaded thumbs)
- 2 No atmosphere: FAIL (`0 0 1280 330`; `c_sky_mesa.png`: posterised painted sky, crisp mesas)
- 3 Too clean: FAIL (`420 350 400 370`; `c_c_gun_hands.png`: the rifle is flat royal blue with sharp untouched edges and a mirror-hot highlight)
- 4 Too straight: FAIL (`0 380 440 340`; `c_ruts_pebbles.png`: ruler-straight ruts)
- 5 Floating objects: FAIL (`420 350 400 370`; `c_c_gun_hands.png`: the left thumb sticks straight out into the air, touching nothing)
- 6 Repetition: FAIL (`0 380 440 340`; `c_ruts_pebbles.png`: identical pebbles and grass clumps)
- 7 Empty: FAIL (`0 250 640 120`; `c_horizon.png`: bare plain, three props and a figure)
- 8 Scale tells: FAIL (`430 470 380 250`; `c_c_gun_hands.png`: the thumbs are as thick as the rifle's receiver, like sausages)
- 9 Edges of the world: FAIL (`0 250 640 120`; `c_horizon.png`: lone shack and panels, hard ground-to-backdrop seam)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A toy-blue box for a gun** (tell 3, `570 360 140 360`): from behind, the rifle is a saturated royal-blue block with a blown white highlight; it reads as plastic. Cause: material. Cheapest fix: near-black bluing with grey wear on the edges and a rougher, dimmer highlight.
2. **Sausage thumbs** (tell 8, `430 470 380 250`): swollen, smooth thumbs with no knuckles or nails, too big for the gun. Cause: geometry. Cheapest fix: correct the hand scale in the aim pose and wrap the thumbs over the wrist of the stock.
3. **A thumb in the air** (tell 5, `430 470 150 100`): the left thumb juts sideways, touching nothing, so the grip doesn't read. Cause: geometry. Cheapest fix: pose the support hand under the forend.
4. **Painted sky** (tell 2, `0 0 1280 330`): cartoon cloud bands against realistic ground. Cause: light. Cheapest fix: smooth graded sky and haze.
5. **Empty, ruled plain** (tells 4, 7, `0 250 640 470`): straight ruts and a three-prop town. Cause: dressing. Cheapest fix: break the ruts and fill the end of the road.

## d
- 1 Flat light: PASS (`600 450 420 270`: sun shading on knuckles and receiver, rifle shadow sense)
- 2 No atmosphere: FAIL (`0 0 1280 330`; `d_sky_mesa.png`: posterised painted sky, crisp mesas)
- 3 Too clean: FAIL (`600 450 420 270`; `d_d_rifle_hands.png`: receiver a flat dark plate with a neat inset outline and no wear; cuff spotless cream)
- 4 Too straight: FAIL (`0 380 600 340`; `d_ruts_pebbles.png`: ruler-straight ruts)
- 5 Floating objects: PASS (`600 450 420 270`: both hands visibly grip the forend and wrist)
- 6 Repetition: FAIL (`0 380 600 340`; `d_ruts_pebbles.png`: identical pebbles, identical dome shrubs)
- 7 Empty: FAIL (`0 280 1280 110`; `d_horizon.png`: bare plain, fence panels, crates, one figure)
- 8 Scale tells: PASS (`600 450 420 270`: hands and rifle in proportion)
- 9 Edges of the world: FAIL (`0 280 1280 110`; `d_horizon.png`: hard ground-to-backdrop seam, panels standing alone)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Factory-new rifle** (tell 3, `740 480 220 200`): the receiver is a smooth slab with a CG outline panel; no worn bluing, scratches or dirt in the seams. Cause: material. Cheapest fix: edge wear and a little grime in the recesses, slightly less blue.
2. **Spotless cuff and sleeve** (tell 3, `610 590 160 130`): the cream cuff is pristine and the coat sleeve one even brown. Cause: material. Cheapest fix: dust and fray the cuff edge.
3. **Painted sky** (tell 2, `0 0 1280 330`): posterised cloud bands break the realism the hands and rifle earn. Cause: light. Cheapest fix: smooth sky and haze on the mesas.
4. **Empty plain** (tells 7, 9, `0 280 1280 110`): the destination is three props and a figure in a flat field. Cause: dressing. Cheapest fix: real buildings at the end of the road.
5. **Ruled ruts, sprinkled stones** (tells 4, 6, `0 380 600 340`): too regular. Cause: dressing. Cheapest fix: wobble and break the ruts, cluster the stones.

## e
- 1 Flat light: PASS (`800 0 480 400`: lamplight with real cast shadows of the posts and the man on the wall)
- 2 No atmosphere: PASS (`1100 180 180 250`: the boardwalk falls off into warm, softer depth)
- 3 Too clean: FAIL (`715 455 200 190`; `e_gun_clean.png`: the revolver is unmarked glossy blue-black against a weathered wooden world)
- 4 Too straight: PASS (`0 0 420 720`: boards and posts vary, weathered and uneven)
- 5 Floating objects: FAIL (`700 480 580 240`; `e_e_arm_gun.png`: the revolver hangs beside the arm with no fingers on it)
- 6 Repetition: PASS (`800 150 120 160`: two posters, but different; props vary)
- 7 Empty: PASS (`800 0 480 600`: men, lamps, posters, crates, barrels)
- 8 Scale tells: FAIL (`760 590 520 130`; `e_e_arm_gun.png`: the orange skin mound is bigger than the gun and reads as a giant fingerless hand)
- 9 Edges of the world: PASS (`1180 0 100 80`: a sliver of sky beyond the roof, no seam visible)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Orange skin blob for a hand** (tell 8, `760 590 520 130`): a bulbous, fingerless mound, lit orange by the lamps, that a player can't read as a hand. Cause: geometry. Cheapest fix: the same as a: show fingers and a sleeve, keep the back of the hand out of the lower quarter.
2. **Gun not held** (tell 5, `715 500 200 140`): the revolver floats beside the blob. Cause: geometry. Cheapest fix: close the fingers round the grip.
3. **A smeared, low-res panel in the middle of the frame** (tell 3, `420 45 325 445`; `e_e_panel.png`): a door or shutter textured with a blurry, magnified checker of brown blobs, next to crisp planks. Cause: material. Cheapest fix: give it the same wood texture at the same resolution as its neighbours.
4. **Toy-clean revolver** (tell 3, `715 455 200 190`): glossy and unmarked among weathered boards. Cause: material. Cheapest fix: worn edges, duller finish.
5. **Painted signs over realistic wood** (tell 3, `800 150 120 160`): the posters and the painted figure on the wall read flat and graphic. Cause: material. Cheapest fix: age the posters (tears, stains, curled corners).

## Ranking
From least to most cheap-looking: d, b, a, e, c
