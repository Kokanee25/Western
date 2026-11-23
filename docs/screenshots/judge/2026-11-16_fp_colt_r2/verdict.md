# Judge r2: the guns in hand, blind
Overall: **cheap indie** (all 20). The street and lamplit porch around them are good indie; the guns and hands pull every frame down.
Top 3: (1) the revolver is not held by its grip: a fist clamps the frame and covers the gun (a-j). (2) The rifle's receiver is a flat unlit black box and the hands float beside it, not round it (k-t). (3) The hands and sleeve are smooth, one-tone and blocky: sausage fingers, a green band and a black tube for a cuff.
Firing frames (d, i, n, s) look the same as aim/rest: no flash, smoke or recoil at 50 ms.
Rifle aim (l, q, s) is a pole up the screen's centre with a giant black forearm filling the bottom right.
Revolver steel in hand is near-black and flat; the gun lab's case colours and walnut never show.
Answers: (1) no; (2) no; (3) no; (4) no; (5) yes, the rifle aim's forearm is stretched.
Crops: build/judge_r2/{a_r2_rev_grip, b_r2_rev_aim_cuff, l_r2_rifle_aim_pole, k_r2_rifle_rest_low, o_r2_rifle_lever, d_r2_fire_nothing}.png

## Per render (verdict; biggest thing wrong)
- a: cheap indie; the hand is a fist across the frame behind the cylinder, the grip hangs below it and the trigger guard is lost.
- b: cheap indie; at aim the fist and cuff hide all but the hammer and front sight: the gun is behind the arm.
- c: cheap indie; reads identical to a: no thumb on the hammer, no visible cocking.
- d: cheap indie; identical to b: no muzzle flash, smoke, light or recoil 50 ms after a shot.
- e: cheap indie; the gun tips up-left on the arm's end like a stick; the gate isn't visible and the left hand isn't loading.
- f: cheap indie (scene good indie); the same fist on the frame, the gun near-black against a dark post, lost.
- g: cheap indie; the aim cuff and fist block the porch view, the gun a dark nub.
- h: cheap indie; the hand wraps over the top of the frame, fingers across the cylinder; flat orange skin.
- i: cheap indie; no flash at night, where a shot should light the whole porch.
- j: cheap indie; the best revolver frame (gun shape reads), but it is held at the barrel's end like a torch, with no second hand.
- k: cheap indie; the rifle sits almost below the frame: only a black receiver top, a fist and a stock end show.
- l: cheap indie; the rifle is a brown pole straight up the centre; the forearm is a huge black wedge; no receiver or sights in view.
- m: cheap indie; identical to k: the lever isn't thrown, nothing shows the action.
- n: cheap indie; identical to l: no flash or kick.
- o: cheap indie; the receiver is a featureless black slab, a flat strip juts below the barrel, the hands are open and touch nothing.
- p: cheap indie; as k, and at night the black receiver vanishes into the dark.
- q: cheap indie; as l, the pole and the black arm fill half the frame.
- r: cheap indie; as k, the rest pose at night with no lever shown.
- s: cheap indie; as l, no flash in the dark.
- t: cheap indie; as o; the lamplit wood stock is the one nice material in the rifle set.

## The five biggest problems
1. **The revolver hand doesn't hold the grip** (a, c, f, h; also b, d, g, i). What a player sees: a fist clamped across the frame and cylinder from the side, the walnut grip poking out below or hidden, the thumb wrapped over the top, no trigger finger. At aim the fist and the cuff stand in front of the gun, so you look at your knuckles, not at a Colt. Cause: the hand's grip and the gun's place in the hand, plus a gun turned edge-on to the camera. Cheapest fix: put the gun's grip in the palm (three fingers round it, the thumb free by the hammer, the index finger along the frame) and turn it about 20-30 deg so its left side and the cylinder face the eye, as in hold_game_rev.jpg. At aim, lower the hand and cuff about 5-8 % of the screen height so the gun's top line sits above the knuckles. Crops: `build/judge_r2/a_r2_rev_grip.png`, `build/judge_r2/b_r2_rev_aim_cuff.png`.
2. **The rifle is held wrong and placed badly** (k, m, p, r low; l, n, q, s aim). What a player sees: at rest the gun is almost off the bottom of the screen; at aim it becomes a wooden pole up the screen's centre with no receiver, sights or barrel shape, and the right forearm is a vast black wedge from the corner. Cause: the gun's place and angle in the view (too low at rest; at aim, the camera looks straight down the stock with a forearm far too close: perspective stretch). Cheapest fix: at rest raise the rifle so the receiver and lever sit in the lower right third, muzzle toward the centre (hold_game_hip.jpg). At aim move the eye to the sights, not over the comb, so the receiver top, the barrel and the front sight are seen (hunt_rifle_low.jpg), and pull the right arm back and out of frame. Crops: `build/judge_r2/l_r2_rifle_aim_pole.png`, `build/judge_r2/k_r2_rifle_rest_low.png`.
3. **The rifle's steel is a flat black silhouette and its hands float** (k-t, worst in o and t). What a player sees: the receiver and barrel are pure unlit black with no edges, screws, sideplate or brass, like a cut-out. A long flat strip juts under the barrel like a blade. The left palm is open beside the forend and the right fingers splay under the receiver, touching nothing. Cause: the material (blued steel too dark and too rough, no specular or edge wear) and the hands' fingers not closed on the gun. Cheapest fix: lift the steel's albedo to a dark blue-grey with specular highlights and bevelled edges (as the Colt in colt_gunlab_close.jpg), close the left hand round the forend and the right round the wrist with the fingers in the lever, and check or hide the strip under the barrel. Crop: `build/judge_r2/o_r2_rifle_lever.png`.
4. **The firing frames show nothing** (d, i, n, s), and the cocking and lever frames look like rest (c, h, m, r). What a player sees: pulling the trigger changes no pixel at 50 ms: no flash, no smoke, no light on the hand or the porch, no muzzle rise. Cocking shows no thumb on the hammer; the lever is never thrown. Cause: the effects and the procedural pose don't reach the view at those frames (or they are timed off). Cheapest fix: a muzzle flash sprite plus a short omni light (very visible at night), a puff of smoke, 3-5 deg of muzzle rise at 50 ms, and visible key poses for the hammer thumb and the lever down. Crop: `build/judge_r2/d_r2_fire_nothing.png` (compare b).
5. **The hands and sleeves are toy-like** (all). What a player sees: smooth orange-pink skin of one tone, no knuckles, nails, tendons or dirt; thick sausage fingers with stair-stepped edges; the cuff is a clean olive band on a black tube with a hard ring, which reads as a block, not cloth. At night the skin glows like plastic. Cause: the material (no skin detail or subsurface variation, no cloth folds or weave light) and low-poly geometry. Cheapest fix: a skin texture with knuckle creases, darker nails and grime and less saturation; a sleeve with a few folds, a frayed or rolled cuff and a lighter, warmer cloth tone so it takes light (the white rolled sleeve in hold_game_hip.jpg reads far better). Crops: `build/judge_r2/a_r2_rev_grip.png`, `build/judge_r2/b_r2_rev_aim_cuff.png`.

## Yes / no
1. **Big enough and placed right? No.** The revolver is about the right size and in the lower right, but it is edge-on with the grip and cylinder hidden by the fist. The rifle is too low at rest and a pole up the centre at aim; neither shows its receiver clearly.
2. **Does the revolver hand hold the grip? No.** The hand makes a fist round the frame behind the cylinder with the thumb wrapped over. No three fingers round the grip, no free thumb and no trigger finger along the frame.
3. **Do the cuff and sleeve read as a sleeve? No.** It is a hard olive band on a uniform black cylinder with no folds; at aim it is a block that fills a quarter of the screen.
4. **Does the steel match the gun lab's Colt? No.** In the lab the Colt has blued steel with highlights, case-coloured frame and walnut grips. In hand it is a near-black, flat, faintly blue shape; the grip and the case colours never show.
5. **Anything distorted or clipped? Yes.** The rifle aim's right forearm is stretched huge by its closeness to the camera (l, q, s), the rifle at rest is cut off by the bottom edge (k, p), and the revolver at aim is mostly clipped behind the cuff (b, g).
