# Cheap judge, 2026-11-09_cheap_saa_r1

## a
- 1 Flat light: PASS (`0 300 1600 600`: low sun, long post and rut shadows across the road, a clear direction)
- 2 No atmosphere: PASS (`600 0 700 200`: the far street and wagon soften into warm haze)
- 3 Too clean: FAIL (`700 230 900 320`; `a_gun_plain_metal.jpg`): the revolver, half the frame, is uniform beige frame and glossy blue-black cylinder with no wear, bluing loss, tooling marks or grime; the grip `470 520 300 380` (`a_grip_flat.jpg`) is one flat brown with no grain
- 4 Too straight: PASS (`0 0 760 300`: posts and awnings lean and vary; the road is rutted)
- 5 Floating objects: PASS (gun floats on purpose; crate `170 280 230 120` and horse hooves sit with contact shade)
- 6 Repetition: FAIL (`0 360 1600 540`; `a_pebbles_same.jpg`): the same grey faceted pebble sprinkled evenly over the whole road
- 7 Empty: PASS (horses, townsfolk, a wagon, crates)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (`950 0 300 130`: the canyon closes the street believably)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The revolver reads as an untextured placeholder** (tell 3, `700 230 900 320`): a player sees a smooth CG model with flat beige and plastic-black surfaces, blue dots for screws, no edge wear or grain, the cylinder oversized against the frame. Cause: material. Cheapest fix: a real blued-steel/case-hardened material with edge wear and roughness variation (and walnut with grain on the grip).
2. **A blown specular streak along the barrel** (tell 3, `1150 240 450 120`; `a_barrel_streak.jpg`): a hot white glare bleeds off the top of the barrel like a bloom bug, not a sheen on steel. Cause: material. Cheapest fix: raise the barrel's roughness so the highlight is a soft band, not a glow.
3. **The grip is one flat brown slab** (tell 3, `470 520 300 380`; `a_grip_flat.jpg`): no wood grain, checkering, or worn finish; it looks like painted plastic. Cause: material. Cheapest fix: a walnut texture with a darkened, worn heel.
4. **Copy-pasted pebbles** (tell 6, `0 360 1600 540`; `a_pebbles_same.jpg`): the same low-poly grey rock, evenly spaced, the most visible tell in the frame around the gun. Cause: dressing. Cheapest fix: fewer, varied rocks clustered in the ruts and edges, half sunk into the dirt.
5. **The proportions are a beginner's revolver** (tell 8-like, `660 200 540 450`): the hammer spur is a big horn, the trigger guard a thin wire, the frame a slab; it doesn't read as a period Colt or Remington. Cause: geometry. Cheapest fix: model to a reference photo's proportions (hammer, guard, grip angle).

## b
- 1 Flat light: PASS (`0 400 1600 500`: sun from behind, rut shadows, a direction)
- 2 No atmosphere: PASS (`780 80 400 140`: the far canyon is paler and bluer)
- 3 Too clean: FAIL (`400 250 500 300`; `b_gun_plastic.jpg`): the gun's frame is a single matte beige, the cylinder glossy plastic black; `760 280 400 620` (`b_grip_orange.jpg`) the grip a saturated orange with a black outline band, toy-like
- 4 Too straight: PASS
- 5 Floating objects: PASS (gun on a stand on purpose; crates at `240 200 200 70` sit on the ground)
- 6 Repetition: FAIL (`0 560 1600 340`; `b_white_pebbles.jpg`): identical white faceted pebbles strewn evenly across the ground; identical round shrubs dotted on the plain
- 7 Empty: FAIL (`0 180 900 120`; `b_empty_plain.jpg`): a bare flat plain with two crates, an untextured block and one figure
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`300 60 1300 170`; `b_backdrop_squares.jpg`): the canyon backdrop is visibly pixelated in big squares, with stair-stepped cut-out ridges standing in front of it; an untextured beige box `585 175 105 75` sits mid-frame
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Pixelated cut-out backdrop** (tell 9, `300 60 1300 170`; `b_backdrop_squares.jpg`): the mesas are low-res squares and the near ridges are stair-stepped cardboard flats; the eye goes straight to it. Cause: material. Cheapest fix: a higher-resolution, filtered backdrop and soft-edged ridges sunk in haze.
2. **Toy grip and plastic metals** (tell 3, `760 280 400 620`; `b_grip_orange.jpg`): bright orange wood with a black rim and a uniform beige frame read as a plastic cap gun. Cause: material. Cheapest fix: darker walnut with grain and an aged steel material on the frame.
3. **Identical white pebbles everywhere** (tell 6, `0 560 1600 340`; `b_white_pebbles.jpg`): the same faceted rock, evenly sprinkled, bright white against the dirt. Cause: dressing. Cheapest fix: tint them to the ground, vary size, cluster them, cut the count by half.
4. **An empty plain with greybox props** (tell 7, `0 180 900 120`; `b_empty_plain.jpg`): a flat beige ground, two crates and a blank untextured block; nothing says anyone lives here. Cause: dressing. Cheapest fix: texture or remove the blank block and break the plain with a fence line or wagon track.
5. **Revolver proportions** (tell 3, `400 200 560 450`): a huge cylinder, horn-shaped hammer and wire trigger guard; screws as blue dots. Cause: geometry. Cheapest fix: model to a reference's proportions with flush steel screws.

## c
- 1 Flat light: PASS (`0 600 1600 300`: low raking sun, long shadows of horses and grass)
- 2 No atmosphere: PASS (`1200 0 400 300`: lamps glowing warm in shade behind the horses; little distance to show)
- 3 Too clean: FAIL (`500 260 560 440`; `c_muzzle_plain.jpg`): the gun's barrel and frame are flat, clean, single-colour surfaces, the muzzle a smooth CG tube
- 4 Too straight: PASS (posts and boards vary; the boardwalk is worn)
- 5 Floating objects: PASS (gun on purpose; hooves and rocks shadowed)
- 6 Repetition: FAIL (`820 90 780 560`; `c_twin_horses.jpg`): two identical horses with identical saddles side by side; the same saddle again in a
- 7 Empty: PASS (men, horses, crates, a wanted poster)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Plain CG revolver** (tell 3, `500 260 560 440`; `c_muzzle_plain.jpg`): viewed from the muzzle it is a smooth cylinder with a plastic-black finish and no wear at the crown; nothing reads as steel. Cause: material. Cheapest fix: a worn bluing material with bright edges where hands and holster rub.
2. **Twin horses** (tell 6, `820 90 780 560`; `c_twin_horses.jpg`): the same horse and saddle twice, faceted low-poly legs and blocky saddle shapes. Cause: dressing. Cheapest fix: vary coat colour and tack on the second horse.
3. **Squares in the grass** (tell 3, `0 430 330 260`; `c_grass_squares.jpg`): the near grass blades show stair-stepped pixel edges, a leftover-squares look. Cause: material. Cheapest fix: filtered/mipmapped grass cards with soft alpha.
4. **A blurred grid where a window should be** (tell 3, `590 40 250 220`; `c_window_grid.jpg`): a dark rectangle of soft repeated tiles behind the horses, unreadable. Cause: material. Cheapest fix: a real window texture or panes.
5. **Faceted horses** (tell 8-like, `1200 100 400 520`): the horses' legs and flanks are visibly low-poly next to the smooth gun. Cause: geometry. Cheapest fix: smooth normals / a higher LOD at this distance.

## d
- 1 Flat light: PASS (`0 500 1600 400`: sun from the left, crisp shadows of posts and the man)
- 2 No atmosphere: PASS (`0 300 400 150`: the far end of the street and wagon soften in haze)
- 3 Too clean: FAIL (`400 260 1200 400`; `d_gun_frame.jpg`): the frame is one uniform beige, the cylinder and barrel uniform blue-black, no wear or tooling; the grip `380 330 260 570` (`d_grip_plain.jpg`) plain brown
- 4 Too straight: PASS (signs hang crooked, posts lean, the boards vary)
- 5 Floating objects: PASS (gun on purpose; people and the barrel grounded)
- 6 Repetition: PASS
- 7 Empty: PASS (people, horse, wagon, signs, grass)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 0 720 320`; `d_mesa_squares.jpg`): the mesas behind the town are visibly pixelated in squares, a flat cut-out against the sky
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The revolver is a clean placeholder** (tell 3, `400 260 1200 400`; `d_gun_frame.jpg`): smooth slabs of beige and black with a hard glint, dot screws; the open loading gate and the brass cartridge are a nice touch but the material says "unfinished". Cause: material. Cheapest fix: case-hardened colour on the frame and worn bluing on the cylinder and barrel.
2. **Pixelated mesas** (tell 9, `0 0 720 320`; `d_mesa_squares.jpg`): the backdrop breaks into big squares, the leftover-squares look. Cause: material. Cheapest fix: a filtered, higher-resolution backdrop with more haze over it.
3. **A plain grip** (tell 3, `380 330 260 570`; `d_grip_plain.jpg`): a flat brown stick with a black edge band. Cause: material. Cheapest fix: walnut grain and a worn heel.
4. **Revolver proportions** (tell 3, `400 260 1100 560`): the hammer spur is huge, the trigger guard a thin wire loop, the ejector rod a bare tube. Cause: geometry. Cheapest fix: model to a period reference.
5. **Clumpy grass at the right** (tell 3, `1150 520 450 300`): the grass is dark low-poly cards that look pasted on the dirt. Cause: dressing. Cheapest fix: blend the clumps' bases into the ground with a darker root and a few dry blades around them.

## e
- 1 Flat light: PASS (`0 550 1600 350`: shadows of grass and the fence fall across the dirt)
- 2 No atmosphere: PASS (`560 0 1040 180`: the hill is pale and soft)
- 3 Too clean: FAIL (`780 330 280 570`; `e_grip_panel.jpg`): the grip is a flat orange-brown with a matte black panel; the frame a uniform grey
- 4 Too straight: PASS
- 5 Floating objects: PASS (gun on purpose; man's boots and grass shadowed)
- 6 Repetition: FAIL (`600 100 1000 260`; `e_grass_clones.jpg`): the same dark grass clump repeated in rows; identical round shrubs dotted evenly on the hill
- 7 Empty: PASS (a man and a fence; the outskirts)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`560 0 1040 180`; `e_dune_bare.jpg`): a smooth bare dune with no texture detail and evenly spaced blobs, like untextured terrain
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A glowing hot spot on the cylinder** (tell 3, `540 340 300 300`; `e_hot_spot.jpg`): a blown white ball of light sits on the cylinder like a torch; a player reads it as a rendering bug. Cause: material. Cheapest fix: clamp the specular / raise roughness so the highlight is a soft streak.
2. **Plastic grip and frame** (tell 3, `780 330 280 570`; `e_grip_panel.jpg`): two flat colours, no grain, no wear; a toy gun. Cause: material. Cheapest fix: wood grain and worn steel textures.
3. **Cloned grass** (tell 6, `600 100 1000 260`; `e_grass_clones.jpg`): the same clump stamped across the field in even spacing. Cause: dressing. Cheapest fix: vary the clumps' scale, rotation and colour and let them thin out irregularly.
4. **A bare, blobby dune** (tell 9, `560 0 1040 180`; `e_dune_bare.jpg`): a smooth beige hill with evenly scattered round shrubs, no texture or erosion. Cause: material. Cheapest fix: a terrain texture with wind ripples and rock outcrops.
5. **Low-poly pebbles** (tell 6, `0 540 1600 360`): the same faceted pale rock dotted across the dirt. Cause: dressing. Cheapest fix: fewer, varied, half-buried rocks.

## Ranking
From least to most cheap-looking: d, a, c, e, b
