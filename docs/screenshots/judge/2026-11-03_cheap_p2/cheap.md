# Cheap judge, 2026-11-03_cheap_p2

## a
- 1 Flat light: PASS (`0 0 1280 720`: low sun at the street's end, warm rim on the fronts, porches in shade, the ruts throw shadow)
- 2 No atmosphere: PASS (`600 190 300 230`: the far end of the street goes soft and warm into haze)
- 3 Too clean: PASS (`0 440 700 280`: ruts, scuffed dirt, weathered and stained boards on the jail and saloon)
- 4 Too straight: PASS (`0 0 520 450`: the fronts and posts are a little uneven; not ruler-perfect)
- 5 Floating objects: FAIL (`740 440 400 280`; `cut a_a_gun.png`: the revolver sits on top of the hand instead of in it, and the hand's and grip's textures are stretched into streaks)
- 6 Repetition: FAIL (`0 440 700 280`; `cut a_a_ground.png`, `50 440 300 110`; `cut a_grass.png`: one tan pebble blob and one grass clump copied all down the street)
- 7 Empty: PASS (`330 360 600 120`: people, horses at the rail, barrels, crates, lamps)
- 8 Scale tells: PASS (`330 360 600 120`: people, horses, doors and porches read as the right size for each other)
- 9 Edges of the world: FAIL (`700 310 160 90`; `cut a_seam.png`: the street ends in stacked painted cards with bright cut-out outlines round them)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The gun hand** (tell 5, `740 440 400 280`): the biggest thing on screen is a smooth, peach-coloured hand that doesn't hold the gun; the gun floats on top of the fingers, and the grip and forearm are smeared with stretched texture. Cause: geometry. Cheapest fix: pose the fingers round the grip and fix the stretched UVs on the hand and grip.
2. **Copy-pasted pebbles** (tell 6, `0 440 700 280`): dozens of identical smooth tan lozenges sit on the road like confetti. They have no texture and no contact shadow, and they don't match the painted dirt. Cause: material. Cheapest fix: give the pebbles the ground's paint and a dark contact edge, vary their size, and use a third as many.
3. **Cloned grass clumps** (tell 6, `50 440 300 110`, `1030 440 250 140`): the same yellow tuft, at the same size, is repeated along both porch lines. Cause: dressing. Cheapest fix: vary scale and tint, mix in a sparser second kind, and leave gaps.
4. **The backdrop's cut-out edges** (tell 9, `700 310 160 90`): the canyon at the end is layered flat cards, and their light outlines give them away. Nothing solid stands at the vanishing point. Cause: geometry. Cheapest fix: feather or darken the cards' edges and put a building or wagon across the end of the street.
5. **Same-dressed townsfolk** (tell 6, `480 360 200 140`): almost everyone is a dark figure in a maroon shirt with the same build, so up close the crowd reads as clones. Cause: people. Cheapest fix: vary the shirt and coat colours and the hats across the crowd.

## b
- 1 Flat light: FAIL (`0 520 1280 200`; `cut b_ground.png`: noon top light bleaches the sand nearly white and the fronts are an even grey; only thin shadows)
- 2 No atmosphere: N/A (the frame is facades with sky behind; there's no distance to judge)
- 3 Too clean: FAIL (`480 300 520 240`; `cut b_porch.png`: porch skirts meet clean sand, and each wall's planks are the same from end to end)
- 4 Too straight: FAIL (`40 0 960 300`; `cut b_fronts.png`: three fronts square to the camera, rooflines dead level, cornice brackets evenly spaced)
- 5 Floating objects: FAIL (`480 300 520 240`; `cut b_porch.png`: the trough sits on bright sand with almost no contact darkening)
- 6 Repetition: FAIL (`0 330 500 230`; `cut b_horse.png`: the same white grass card with black fringes is repeated along the whole porch line)
- 7 Empty: PASS (`300 330 700 120`: a horse, a man on the porch, lit windows, a trough)
- 8 Scale tells: PASS (`0 330 700 220`: horse, porch and doors roughly agree)
- 9 Edges of the world: FAIL (`0 0 640 200`; `cut b_sky.png`: the sky is a smeared, stretched streak texture, white with blue slashes, not a sky)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A broken sky** (tell 9, `0 0 640 200`): the sky is stretched, diagonal blue-and-white smears, like a texture pulled over the wrong shape. It's the first thing a player would notice. Cause: material. Cheapest fix: map the sky texture properly, or replace it with a calm painted gradient and clouds.
2. **Bleached noon light** (tell 1, `0 520 1280 200`): the ground is nearly white and the wood is an even grey, so you can't tell the time of day or where the light comes from. Cause: light. Cheapest fix: drop the exposure and lower the sun so the fronts take a lit side and a shadow side.
3. **Grass cards with black fringes** (tell 6, `0 330 500 230`): the same white tuft sits along the boardwalk, each with dark cut-out edges, like a sorting bug. Cause: material. Cheapest fix: fix the grass's alpha edges and vary the tufts' size and colour.
4. **A blocky horse** (tell 8, `0 330 500 230`): low-poly, its legs flat slabs with a stray light band on one; it reads as a placeholder. Cause: geometry. Cheapest fix: use the better horse model, or keep the horse further from the camera.
5. **Soft, smudged image with a stray mark** (tell 3, `1100 640 180 80`; `cut b_corner.png`): the whole frame looks upscaled and JPEG-blurred, and there's an illegible smudge like a watermark in the corner, which reads as generated. Cause: camera. Cheapest fix: capture at native resolution with no compression, and find and remove whatever draws the corner mark.

## c
- 1 Flat light: PASS (`0 0 1280 720`: low sun at the end, rays in the haze, porches shaded, rim light on the figures)
- 2 No atmosphere: PASS (`600 190 300 230`; `cut c_c_end.png`: sun shafts and dust fill the end of the street)
- 3 Too clean: PASS (`0 440 700 280`: ruts, dirt and weathered boards)
- 4 Too straight: PASS (`0 0 520 450`: the fronts and posts vary a little)
- 5 Floating objects: FAIL (`740 440 400 280`; `cut c_c_gun.png`: the gun rests on the hand rather than in it, with stretched texture on the grip and hand)
- 6 Repetition: FAIL (`0 440 700 280`; `cut c_c_ground.png`: the same tan pebble blob and the same grass clump over and over)
- 7 Empty: PASS (`330 360 600 120`: people, horses, barrels, lamps)
- 8 Scale tells: PASS (`330 360 600 120`)
- 9 Edges of the world: FAIL (`700 310 160 90`; `cut c_seam.png`: the backdrop cards' bright outlines still show, though the rays hide some of them)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The gun hand** (tell 5, `740 440 400 280`): a smooth peach hand under a gun it doesn't grip, with streaked UVs; it takes up a quarter of the screen. Cause: geometry. Cheapest fix: wrap the fingers round the grip and fix the stretched texture.
2. **Copy-pasted pebbles** (tell 6, `0 440 700 280`): identical untextured tan blobs scattered over the painted road. Cause: material. Cheapest fix: paint them like the ground, add contact shadows and use fewer.
3. **Cloned grass clumps** (tell 6, `50 440 300 110`): the same tuft at the same size along both sides. Cause: dressing. Cheapest fix: vary scale and tint, and break up the rows.
4. **Backdrop cards** (tell 9, `700 310 160 90`): outlined flat layers at the vanishing point; the rays soften them but don't hide them. Cause: geometry. Cheapest fix: feather the cards' edges and close the street's end with a solid building.
5. **Same-dressed townsfolk** (tell 6, `480 360 200 140`; `cut c_people.png`): the crowd is the same maroon shirt and dark trousers. Cause: people. Cheapest fix: vary clothing colours and silhouettes.

## d
- 1 Flat light: PASS (`0 0 1280 720`: low sun ahead, long raking shadows across the road, a warm lamp pool under the porch)
- 2 No atmosphere: PASS (`580 220 200 220`: heavy warm haze swallows the far end)
- 3 Too clean: FAIL (`640 400 640 320`; `cut d_street.png`: the street is a smooth untextured plane with no ruts, tracks or litter)
- 4 Too straight: FAIL (`960 230 320 250`; `cut d_right.png`: buildings are perfect flat slabs with level tops and punched rectangle windows)
- 5 Floating objects: PASS (`660 440 120 90`: the crate casts a shadow on the road; posts meet the boardwalk)
- 6 Repetition: FAIL (`960 230 320 250`; `cut d_right.png`: one mottled-stain texture on every wall and post, the same blotches everywhere)
- 7 Empty: FAIL (`580 220 200 220`; `cut d_end.png`: an empty street, no people, no signs, no horses, one crate)
- 8 Scale tells: PASS (`160 270 260 270`: the doors and windows by the porch read as human-sized)
- 9 Edges of the world: FAIL (`580 220 200 220`; `cut d_end.png`: false fronts are single walls with nothing behind them, standing on a bare plain that runs to a flat horizon)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Cardboard buildings** (tell 9, `960 230 320 250`): the buildings across the street are flat slabs standing on the ground, with no roofs, porches or depth, and dark blobs for windows. They read as a greybox. Cause: geometry. Cheapest fix: give each front a porch, a sign and a box behind it.
2. **Nobody lives here** (tell 7, `580 220 200 220`): a whole street at sunset with not one person, horse or sign. Cause: dressing. Cheapest fix: put a few townsfolk, a hitched horse and signboards on the fronts.
3. **A blank road** (tell 3, `640 400 640 320`): the street is a smooth lilac plane, with no ruts, hoof marks, stones or grass at the edges. Cause: material. Cheapest fix: a dirt texture with wheel ruts and tufts along the boardwalk.
4. **One stain texture on everything** (tell 6, `0 0 600 720`; `cut d_porch.png`): posts, beams and walls all carry the same brown camouflage blotches, so wood and paint don't read as different materials. Cause: material. Cheapest fix: separate textures for posts, siding and the painted fronts.
5. **A hand made of cubes** (tell 8, `740 450 300 270`; `cut d_gun.png`): the hand is orange boxes with no fingers, under a crisp revolver. The mismatch looks unfinished. Cause: geometry. Cheapest fix: replace the hand with a modelled one at the gun's level of detail.

## e
- 1 Flat light: FAIL (`0 380 420 200`; `cut e_left.png`: even, hazy fill; the fronts are lit the same all over and shadows under the porches are soft grey)
- 2 No atmosphere: N/A (the frame is facades with sky behind; there's little distance)
- 3 Too clean: PASS (`0 80 1280 240`: weathered siding, a worn sign, dirt and stones on the ground)
- 4 Too straight: FAIL (`0 80 1280 240`; `cut e_fronts.png`: fronts square to the camera, level rooflines, evenly spaced brackets)
- 5 Floating objects: FAIL (`760 540 360 180`; `cut e_hand.png`: the gun isn't held; it hangs above a long open hand)
- 6 Repetition: FAIL (`0 380 420 200`; `cut e_left.png`: identical white grass cards with dark fringes along the porch line)
- 7 Empty: PASS (`700 400 200 160`: a rider and a horse, people on the porches, lit windows)
- 8 Scale tells: FAIL (`760 540 360 180`; `cut e_hand.png`: the fingers are impossibly long and the hand is huge next to the gun)
- 9 Edges of the world: PASS (`860 240 420 80`: trees and more buildings behind)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Melted gun and hand** (tell 5, `700 400 200 200`; `cut e_gun.png`): the revolver blurs into the rider and horse behind it, and the hand under it has stretched fingers and no grip. It looks like generated mush. Cause: geometry. Cheapest fix: pose the hand on the grip and keep the gun clear of the scene (its own render layer or a clean depth cut).
2. **Even, lifeless light** (tell 1, `0 380 420 200`): a flat overcast fill; nothing says where the sun is or what time of day it is. Cause: light. Cheapest fix: a low, warm key from one side and deeper porch shadow.
3. **Soft, upscaled image** (tell 3, `0 0 1280 720`): the whole frame looks blurred and compressed, so the wood and sign detail turns to mud. Cause: camera. Cheapest fix: capture at native resolution with no compression.
4. **Cloned grass cards** (tell 6, `0 380 420 200`): the same pale tuft with black edges is repeated along the porches. Cause: material. Cheapest fix: fix the alpha edges and vary the clumps.
5. **Front-on, ruler-straight fronts** (tell 4, `0 80 1280 240`): three facades flat to the camera with level lines read like a set. Cause: geometry. Cheapest fix: let the rooflines sag and lean a little, and angle the camera down the street.

## Ranking
From least to most cheap-looking: c, a, e, b, d
