# Cheap judge, cheap_judge

## a
- 1 Flat light: PASS (`0 450 1600 450`: hard, long post shadows across the road; the light clearly comes from behind-left)
- 2 No atmosphere: PASS (`600 0 700 300`: the far end of the street goes warm and grey in haze)
- 3 Too clean: FAIL (`500 340 440 230`; `cut a_receiver_flat.jpg`): the receiver is one even black with no edge wear, no blue turning to grey, no grime in the joins
- 4 Too straight: PASS (`0 0 600 300`: porches and posts lean and vary a little)
- 5 Floating objects: PASS (the rifle's hang is the test view; stones, crates and horses sit on the ground with shadows)
- 6 Repetition: FAIL (`880 540 420 160`; `cut a_stones_lowpoly.jpg`): the same faceted pebble scattered over the road; two near-identical tied horses either side
- 7 Empty: PASS (`600 150 500 120`: people, a wagon, horses, crates, signs)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`770 0 480 220`; `cut a_canyon_backdrop.jpg`): the canyon closing the street is a flat, low-resolution picture with a jagged, blocky cut-out edge
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The rifle reads as untextured plastic with a drawn outline** (tell 3, `500 340 440 230`): the hero object fills the frame and the receiver is a flat matte black slab; the side-plate seams are pale dashed lines that look like stitching on a leather case, not cuts in steel; the screw heads are bright saturated blue dots. Cause: material. Cheapest fix: make the plate seams dark recessed grooves (no pale stroke) and give the steel a roughness/colour variation with worn bright edges.
2. **The lever is mirror chrome on a black toy** (tell 3, `180 590 360 250`, `cut a_lever_chrome.jpg`): a hard white specular streak runs along the loop's inner edge while the rest is dead black, the look of a glossy plastic model. Cause: material. Cheapest fix: raise the roughness on the lever and receiver edges so highlights spread soft and dull.
3. **The stock is a dark, flat brown block** (tell 3, `0 430 330 300`, `cut a_stock_flat.jpg`): faint grain, no oil sheen, no handling wear, nearly black in the light that lights the road brightly. Cause: material. Cheapest fix: lift the walnut's albedo and add a satin sheen with darker handled patches.
4. **The canyon at the street's end is a pixelated cut-out** (tell 9, `770 0 480 220`, `cut a_canyon_backdrop.jpg`): blocky stair-stepped edges where rock meets sky, coarser than anything near it. Cause: geometry. Cheapest fix: a higher-resolution backdrop with a soft, hazed edge.
5. **Low-poly pebbles repeated over the road** (tell 6, `880 540 420 160`, `cut a_stones_lowpoly.jpg`): every stone is the same faceted lump with hard-shaded facets, unlike the soft ground they sit on. Cause: geometry. Cheapest fix: smooth-shade the pebble meshes and vary their size and colour.

## b
- 1 Flat light: PASS (`0 550 1600 200`: strong rut and rail shadows, a clear low sun)
- 2 No atmosphere: N/A (a close view; nothing far)
- 3 Too clean: FAIL (`840 400 180 230`; `cut b_muzzle_clean.jpg`): barrel, muzzle crown and tube cap untouched, no wear, no dust, an even satin black
- 4 Too straight: PASS
- 5 Floating objects: PASS (the rifle's hang is the test view; hooves and stones have shadows)
- 6 Repetition: FAIL (`760 0 800 420`; `cut b_horses_flat.jpg`): two identical horses in identical tack and stance side by side
- 7 Empty: PASS (`0 0 1600 300`: boardwalk, crates, horses, grass)
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The horses are low-poly and flat-shaded** (tell 6, `760 0 800 420`, `cut b_horses_flat.jpg`): angular hide planes, tails as black hard-edged sheets, painted white socks with stepped edges; and two of the same side by side. Cause: geometry. Cheapest fix: smooth the horse normals and give the coat a hair sheen; vary one horse's colour.
2. **The barrel is spotless** (tell 3, `840 400 180 230`, `cut b_muzzle_clean.jpg`): the octagon facets are even dark grey all the way down; the muzzle has no bright worn ring, the bore no soot. Cause: material. Cheapest fix: a worn, brighter crown and holster wear along the flat edges.
3. **Faceted pebbles** (tell 6, `300 580 160 80`, `cut b_stone_lowpoly.jpg`): hard polygon faces with sharp light and dark sides, like a placeholder asset. Cause: geometry. Cheapest fix: smooth shading and a rock texture.
4. **Grass cards with stair-stepped edges** (tell 6, `640 200 260 280`, `cut b_grass_cards.jpg`): the same clump repeated, its blades aliased into pixel steps against the boards. Cause: material. Cheapest fix: alpha-to-coverage or anti-aliased grass cards.
5. **The boardwalk behind is evenly lit and new-looking** (tell 3, `0 150 800 100`): planks bright and uniform, little dirt where they meet the ground. Cause: material. Cheapest fix: grime and dust along the planks' ends and the step's foot.

## c
- 1 Flat light: PASS (`0 450 1600 450`: a big shadow across the ground, highlights along the receiver's top)
- 2 No atmosphere: N/A (looking down at the ground)
- 3 Too clean: FAIL (`600 230 360 300`; `cut c_receiver_top.jpg`): brushed streaks, but no wear at the corners, the dust cover's edge or the gate
- 4 Too straight: PASS
- 5 Floating objects: FAIL (`1230 590 160 110`; `cut c_stone_facets.jpg`): the pebbles have no shadow on the ground under them; they look laid on top. A flat yellow bar lies over the ground unshaded (`1370 340 90 130`; `cut c_stray_line.jpg`)
- 6 Repetition: FAIL (`1050 450 500 400`; `cut c_ground_squares.jpg`): the ground is a grid of visible square blocks, the same blotch pattern over and over
- 7 Empty: PASS
- 8 Scale tells: PASS
- 9 Edges of the world: N/A
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The ground is made of squares** (tell 6, `1050 450 500 400`, `cut c_ground_squares.jpg`): up close the dirt breaks into blocky pixel squares on a diagonal grid, a leftover pixel-art look under a realistic rifle. Cause: material. Cheapest fix: a higher-resolution ground texture with smooth filtering at close range.
2. **Faceted pebbles with no contact shadow** (tell 5, `1230 590 160 110`, `cut c_stone_facets.jpg`): bright low-poly lumps that sit on the ground like stickers. Cause: geometry. Cheapest fix: smooth-shade them and let them cast and receive contact shadow (or ambient occlusion).
3. **A stray flat yellow bar** (tell 5, `1370 340 90 130`, `cut c_stray_line.jpg`): a straw or stick with no shading or thickness, reads as a debug line. Cause: geometry. Cheapest fix: give straws a shaded, tapered mesh or remove them near the camera.
4. **The receiver's top is clean and evenly blue** (tell 3, `600 230 360 300`, `cut c_receiver_top.jpg`): the brushing helps, but the corners and the dust cover's rails have no worn silver, no oil, no dust in the grooves. Cause: material. Cheapest fix: edge wear and dirt in the recesses.
5. **The stock and receiver side fall to pure black** (tell 1, `540 330 300 500`): the left flank is a featureless black shape with no reflected ground light, so it reads as a silhouette. Cause: light. Cheapest fix: let bounce light from the sunlit ground fill the shaded steel a little.

## d
- 1 Flat light: PASS (`0 500 900 400`: sun from behind-right, rut and grass shadows)
- 2 No atmosphere: FAIL (`0 0 1600 330`; `cut d_sky_posterised.jpg`): the sky is posterised into flat bands of colour with no depth or glow, and the mesas are as crisp and saturated as the foreground (`230 280 930 170`; `cut d_mesas_sharp.jpg`)
- 3 Too clean: FAIL (`860 620 300 280`; `cut d_hands.jpg`): the rifle has no wear; the hands are waxy with blotchy painted patches
- 4 Too straight: FAIL (`150 480 700 420`; `cut d_ruts_straight.jpg`): the ruts run dead straight and parallel to the horizon
- 5 Floating objects: FAIL (`80 360 600 140`; `cut d_empty_plain.jpg`): the shed and crates sit on smooth sand with no footing or contact darkening; the green shrubs are flat discs on it
- 6 Repetition: FAIL (`850 460 700 180`; `cut d_grass_rows.jpg`): one grass clump stamped in rows
- 7 Empty: FAIL (`80 360 600 140`; `cut d_empty_plain.jpg`): one shed, a few crates and one man on a vast bare plain
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`230 280 930 170`; `cut d_mesas_sharp.jpg`): the mesas stand like a photo cut-out on a dead-flat plain; the horizon is a ruler line
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A posterised, painted sky** (tell 2, `0 0 1600 330`, `cut d_sky_posterised.jpg`): a third of the frame is flat cream, grey and lavender shapes like a vector illustration; it lights nothing and clashes with the realistic rock. Cause: material. Cheapest fix: a smooth sky with a real gradient and soft cloud edges (an HDR sky).
2. **The mesas are a photo stuck on a flat plain** (tell 9, `230 280 930 170`, `cut d_mesas_sharp.jpg`): sharp, saturated, no aerial haze, no foothills joining them to the ground. Cause: geometry. Cheapest fix: blue-grey distance haze that grows with distance, and broken rolling ground between plain and cliffs.
3. **Grass stamped in rows** (tell 6, `850 460 700 180`, `cut d_grass_rows.jpg`): identical clumps in even ranks along the road. Cause: dressing. Cheapest fix: scatter them with random size, colour and clustering, with bare patches.
4. **The plain is empty** (tell 7, `80 360 600 140`, `cut d_empty_plain.jpg`): a lone shed with no fence, path or junk, and smooth sand dunes like untextured terrain. Cause: dressing. Cheapest fix: fences, a trail, scrub and rocks to tie the shed to the land.
5. **Waxy hands with blotches** (tell 3, `860 620 300 280`, `cut d_hands.jpg`): smooth plastic skin with flat dark smears on the fingers; the thumb doesn't press into the wood. Cause: material. Cheapest fix: a skin texture with pores and knuckle creases, and smooth the blotchy paint.

## e
- 1 Flat light: PASS (`0 500 900 400`: sun from behind-right, rut and grass shadows)
- 2 No atmosphere: FAIL (`0 0 1600 330`; `cut e_sky_posterised.jpg`): posterised flat-band sky; mesas crisp and saturated (`230 280 930 170`; `cut e_mesas_sharp.jpg`)
- 3 Too clean: FAIL (`420 700 500 200`; `cut e_sleeve.jpg`): the sleeve is clean, smooth cloth with painted-on folds; the hands and rifle unworn (`940 590 400 310`; `cut e_hands_rifle.jpg`)
- 4 Too straight: FAIL (`150 480 650 420`; `cut e_ruts_straight.jpg`): ruts dead straight to the horizon
- 5 Floating objects: FAIL (`80 360 600 140`; `cut e_empty_plain.jpg`): shed and crates with no contact on the sand
- 6 Repetition: FAIL (`850 460 700 180`; `cut e_grass_rows.jpg`): one grass clump in rows
- 7 Empty: FAIL (`80 360 600 140`; `cut e_empty_plain.jpg`): a vast plain with almost nothing in it
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`230 280 930 170`; `cut e_mesas_sharp.jpg`): mesas like a photo cut-out on a flat plain
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A posterised, painted sky** (tell 2, `0 0 1600 330`, `cut e_sky_posterised.jpg`): flat blobs of colour like a poster, at odds with everything else. Cause: material. Cheapest fix: a smooth sky gradient with soft clouds (an HDR sky).
2. **The sleeve is painted plastic** (tell 3, `420 700 500 200`, `cut e_sleeve.jpg`): a big cream shape in the foreground with hand-painted shadow streaks, no weave, no dirt, a dark outline at its edge. Cause: material. Cheapest fix: a cloth texture with weave and grime at the cuff, lit by the scene rather than painted.
3. **Mesas cut out on a flat plain** (tell 9, `230 280 930 170`, `cut e_mesas_sharp.jpg`): no haze, no foothills, a ruler-flat horizon. Cause: geometry. Cheapest fix: distance haze and rolling ground before the cliffs.
4. **Grass in rows** (tell 6, `850 460 700 180`, `cut e_grass_rows.jpg`): the same clump stamped along the road. Cause: dressing. Cheapest fix: clustered random scatter with varied size and colour.
5. **Empty land, smooth sand** (tell 7, `80 360 600 140`, `cut e_empty_plain.jpg`): a lone shed on blank dunes, nothing tying it to the ground or saying who lives there. Cause: dressing. Cheapest fix: fence, path, scrub and junk around the shed.

## Ranking
From least to most cheap-looking: a, b, c, d, e
