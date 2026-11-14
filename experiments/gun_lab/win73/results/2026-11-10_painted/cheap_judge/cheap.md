# Cheap judge, cheap_judge

## a
- 1 Flat light: PASS (`0 0 1600 900`: long hard sun shadows across the road, porches in real shade; you can tell where the sun is)
- 2 No atmosphere: PASS (`500 0 700 300`: the far end of the street softens and warms in dust)
- 3 Too clean: FAIL (`320 300 860 340`; `cut a_a_receiver.jpg`)
- 4 Too straight: PASS (`0 0 600 300`: porch posts, signs and the ruts wander a little)
- 5 Floating objects: PASS (`880 530 560 200`: horses, people and pebbles are shadowed onto the dirt; the rifle hangs by design)
- 6 Repetition: FAIL (`110 140 1390 180`; `cut a_a_horses.jpg`)
- 7 Empty: PASS (`500 150 600 150`: people, a wagon, tied horses, a crate)
- 8 Scale tells: PASS (`0 0 1600 330`: doors, people and horses agree)
- 9 Edges of the world: FAIL (`780 0 450 210`; `cut a_a_backdrop.jpg`)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The rifle looks like a fresh CG model, not a used gun** (tell 3, `320 300 860 340`): the receiver is one even satin blue-black slab, and the side plate's outline is drawn as thin pale lines, like a decal. The edges, the lever and the screws have no rubbed-through bluing, no grime in the seams and no handling marks. The screw heads are glossy blue beads. Cause: material. Cheapest fix: an edge-wear mask, with the bluing worn to grey-silver on every edge and corner and dirt packed into the seams and screw slots.
2. **The canyon at the street's end is a low-res picture** (tell 9, `780 0 450 210`): the cliffs break up into blocky squares, their silhouette is ragged and stair-stepped against a second, paler picture, and the plain at their feet is a flat grey band. Cause: material. Cheapest fix: a sharper backdrop sunk deeper into the haze, so the blocks can't be read.
3. **Twin horses frame the shot** (tell 6, `110 140 1390 180`): the same bay with the same saddle stands at each side, mirrored. Cause: dressing. Cheapest fix: give one a different coat or tack, or turn it to graze.
4. **The stock reads as dark plastic** (tell 3, `0 440 420 360`): a near-black brown with barely any grain or oil sheen next to the blue metal. Cause: material. Cheapest fix: lighter walnut with visible grain and a soft oiled highlight.
5. **The pebbles are faceted gems** (tell 6, `880 530 560 200`): the same few low-poly stones, scattered evenly, with hard flat facets. Cause: geometry. Cheapest fix: smooth their normals and sink them part-way into the dirt.

## b
- 1 Flat light: PASS (`0 400 1600 500`: hard sun stripes and shadows across the road, the porch in shade)
- 2 No atmosphere: N/A (close shot, no distance)
- 3 Too clean: FAIL (`280 120 740 520`; `cut b_b_rifle.jpg`)
- 4 Too straight: FAIL (`0 120 800 300`; `cut b_b_porch.jpg`)
- 5 Floating objects: PASS (`280 560 760 200`: the stones have small dark undersides on the dirt; the rifle hangs by design)
- 6 Repetition: FAIL (`780 0 820 420`; `cut b_b_horses.jpg`)
- 7 Empty: PASS (`0 0 1600 450`: porch, crates, tied horses)
- 8 Scale tells: PASS (`0 0 1600 900`)
- 9 Edges of the world: N/A (no horizon)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Low-poly horses with slab tails** (tell 6, `780 0 820 420`): two identical bays in the same stance, their bodies faceted, the tails flat dark sheets, and the saddle bags cutting into their flanks. They are the most "asset" thing in the frame. Cause: geometry. Cheapest fix: a smoother horse mesh and a tail of hair cards; failing that, keep the horses farther from the camera.
2. **The barrel and magazine are showroom new** (tell 3, `280 120 740 520`): one even satin finish all the way to the muzzle, a crisp unworn crown, and a magazine tube with no scratches or dust. Cause: material. Cheapest fix: wear on the muzzle crown, the barrel's flats and the band edges, plus dust in the corners.
3. **Faceted rocks** (tell 3, `280 560 760 200`): pale low-poly stones whose triangles read clearly at this distance, the cheapest-looking thing on the ground. Cause: geometry. Cheapest fix: smooth normals plus a rock texture, or smaller stones.
4. **The porch is a clean, even grid of boards** (tell 4, `0 120 800 300`): the boards are all the same length with the same gaps, unworn and pale, laid like parquet. Cause: geometry. Cheapest fix: vary the board lengths and widths and darken the worn path and the edges.
5. **Grass with stair-stepped edges** (tell 3, `0 260 280 240`): the tufts' blades break into visible pixel steps (leftover squares), which reads low-res next to the smooth rifle. Cause: material. Cheapest fix: anti-alias the grass cards' alpha (alpha-to-coverage) or soften the cutout.

## c
- 1 Flat light: PASS (`0 0 1600 900`: a hard sun and cast shadows over the dirt)
- 2 No atmosphere: N/A (looking down at the ground)
- 3 Too clean: FAIL (`520 100 560 800`; `cut c_c_receiver.jpg`)
- 4 Too straight: PASS (`0 0 1600 900`)
- 5 Floating objects: FAIL (`1100 150 500 550`; `cut c_c_rocks.jpg`, `cut c_c_stick.jpg`)
- 6 Repetition: FAIL (`0 0 800 500`; `cut c_c_ground.jpg`)
- 7 Empty: N/A (a close view of the ground)
- 8 Scale tells: FAIL (`0 0 800 500`; `cut c_c_ground.jpg`)
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The dirt is visibly made of big squares** (tell 8, `0 0 800 500`): from this close the ground texture breaks into blocky texels a thumbnail wide, smeared along the view, beside a rifle modelled to the screw. The ground's resolution is far coarser than everything on it. Cause: material. Cheapest fix: a detail texture or normal layer at close range, so the near ground has grain finer than the gun's parts.
2. **The rocks are two-tone toy gems sitting on the ground** (tell 5, `1100 150 500 550`): each is a cream low-poly ball with a hard black half, no texture and no cast shadow or contact dark where it meets the dirt. A yellow straw at `1390 360 30 90` hangs with no shadow at all. Cause: geometry. Cheapest fix: contact shadows (or an AO decal) under the scatter, and smooth normals on the stones.
3. **The same rock, over and over** (tell 6, `0 0 1600 900`): one or two faceted shapes at different sizes, all lit the same, sprinkled evenly. Cause: dressing. Cheapest fix: more stone variants with varied colour, clustered rather than evenly spread.
4. **The receiver is saturated royal blue** (tell 3, `520 100 560 800`): an even, anodised-looking blue with brushed streaks and no wear, which reads as a coloured plastic toy more than a blued gun. The opening behind the hammer is a flat pale-grey rectangle. Cause: material. Cheapest fix: pull the blue's saturation down toward blue-black, and wear the top edges to bare grey steel.
5. **The ground is clean dirt and nothing else** (tell 3, `0 500 800 400`): no tracks, no dropped things, no grass roots, no darkening around the stones. Cause: dressing. Cheapest fix: a few hoof and boot prints and some dark damp around the stones.

## d
- 1 Flat light: PASS (`0 480 1600 420`: the shadows of the ruts, grass and post agree on one sun)
- 2 No atmosphere: FAIL (`0 340 1600 180`; `cut d_d_horizon.jpg`)
- 3 Too clean: FAIL (`480 480 680 420`; `cut d_d_hands.jpg`)
- 4 Too straight: FAIL (`150 480 650 420`; `cut d_d_ruts.jpg`)
- 5 Floating objects: FAIL (`150 480 650 420`; `cut d_d_ruts.jpg`)
- 6 Repetition: FAIL (`730 470 870 300`; `cut d_d_grass.jpg`)
- 7 Empty: PASS (`380 440 300 40`: a cabin, crates and a figure out on the road; it's a desert)
- 8 Scale tells: PASS (`0 380 1600 120`)
- 9 Edges of the world: FAIL (`0 0 1600 300`; `cut d_d_sky.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The sky is a posterised vector painting** (tell 9, `0 0 1600 300`): the clouds are four or five flat tones with hard edges, like a cel-shaded illustration pasted behind a realistic scene. It is the first thing a player sees, and it fights everything else. Cause: material. Cheapest fix: a real photographic or volumetric sky with soft gradients.
2. **The mesas are crisp cutouts with no air in front of them** (tell 2, `0 340 1600 180`): kilometres away, they are as sharp and saturated as the middle ground. Their edges read like photo cards, and the plain at their feet is a flat, empty band of beige with a few green blobs. Cause: light. Cheapest fix: much stronger warm-blue aerial haze with distance, plus some broken ground between the plain and the cliffs.
3. **The rifle balances on an open palm** (tell 5, `150 480 650 420`): the left hand is held flat under the forend with its fingers spread and not closed round the wood, so the gun floats on the fingertips. The right hand's fingers lie over the lever like stickers. Cause: people. Cheapest fix: a real grip pose, with the fingers wrapped round the forend and the wrist.
4. **The same tuft of grass, cloned in rows** (tell 6, `730 470 870 300`): identical yellow-and-black clumps repeat to the horizon, their blades stair-stepped into pixel squares. Cause: dressing. Cheapest fix: three or four tuft variants with random scale, tint and lean, and anti-aliased cards.
5. **Pristine bare forearms with a painted look** (tell 3, `480 480 680 420`): clean skin with a visible seam ring at the wrist, and fingernails smeared like paint dabs. Next to the photographic ground they look like a mannequin's arms. Cause: people. Cheapest fix: sleeves, dirt and sun on the skin, and a clean nail texture; at least hide the wrist seam.

## e
- 1 Flat light: PASS (`0 480 1600 420`: one sun, the shadows agree)
- 2 No atmosphere: FAIL (`0 340 1600 180`; `cut e_e_horizon.jpg`)
- 3 Too clean: FAIL (`420 640 560 260`; `cut e_e_sleeve.jpg`)
- 4 Too straight: FAIL (`150 480 650 420`; `cut e_e_ruts.jpg`)
- 5 Floating objects: FAIL (`780 560 460 340`; `cut e_e_gun.jpg`)
- 6 Repetition: FAIL (`730 470 870 300`; `cut e_e_grass.jpg`)
- 7 Empty: PASS (`380 440 300 40`: a cabin, crates and a figure out on the road)
- 8 Scale tells: PASS (`0 380 1600 120`)
- 9 Edges of the world: FAIL (`0 0 1600 300`; `cut e_e_sky.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The sky is a posterised vector painting** (tell 9, `0 0 1600 300`): flat bands of cloud with hard edges, like an illustration behind a realistic scene. Cause: material. Cheapest fix: a photographic or volumetric sky with soft gradients.
2. **The sleeve is a smooth rubbery tube** (tell 3, `420 640 560 260`): a big cream shape in the foreground with painted folds, no weave, no seams, no dirt and no wrinkles at the cuff. It looks like a clay sleeve. Cause: material. Cheapest fix: a cloth texture with a weave normal, dust and sweat darkening, and a proper cuff.
3. **The hands don't hold the gun** (tell 5, `780 560 460 340`): the fingers lie on the wood and the lever like flat cutouts with no contact shadow, the trigger hand doesn't close, and the nails are smeared paint blobs. Cause: people. Cheapest fix: a gripping hand pose and contact shadowing between the fingers and the gun.
4. **No air before the mesas** (tell 2, `0 340 1600 180`): the distant cliffs are crisp and saturated photo-cutouts above an empty, flat beige plain. Cause: light. Cheapest fix: much stronger distance haze, plus broken ground at the cliffs' feet.
5. **Cloned grass and dead-straight ruts** (tell 6, `730 470 870 300`; tell 4, `150 480 650 420`): rows of the same pixel-edged tuft, and the two wheel ruts ruled straight and parallel to the horizon. Cause: dressing. Cheapest fix: varied tufts, and ruts that wander and fade.

## Ranking
From least to most cheap-looking: a, b, d, e, c
