# Judge r5
Overall: **cheap indie** (the wood, hands and night steel are good-indie, but the aimed poses don't aim, the shot is a blocky sprite with no smoke, the rifle's receiver is a flat untextured plate and the rifle reload shows no round; next to Hunt's guns it reads as a placeholder animation set)

## Top 3 problems
1. **Aimed poses don't look like aiming.** Revolver b/g/d/i: one hand, arm out to the right, gun canted almost upright with the barrel poking up-left, seen from behind; the barrel isn't on the target line and no sight picture forms. Rifle l/n/q/s: the rifle stands nearly vertical in the middle of the screen, seen edge-on from above as a thin strip, with the left arm crossing the frame diagonally; nothing about it says "shouldered, eye down the barrel".
2. **The shot reads as a sprite, not a gunshot.** d/i/n/s: a square, mosaic-edged yellow-white blob beside the muzzle and the revolver barrel turns into a glowing white tube (looks like a fluorescent rod); no cone or petals, no smoke at all (black powder should make a big grey-white cloud), little visible kick. The ground light flash is the only thing that sells it.
3. **Rifle receiver and rifle reload.** The 1873's receiver is a flat dark slab with one thin drawn outline of the side plate, no bevels, no roughness, no screws or wear; it looks like cardboard next to the nicely figured stock. The reload (o/t) shows the right hand's fingers near the receiver but no cartridge and no gate action: it reads as "fiddling with the gun", not loading.

## Per render
- **a** (revolver rest, day): good indie. Held by the grip, wood grips and steel decent; small and low, fine for rest. Odd floating speck under the centre post.
- **b** (revolver aimed, day): cheap indie. Hand/grip OK but the gun is canted upright, barrel pointing up-left off target; mostly the rear of the frame and cylinder show. Sleeve takes ~1/4 of the screen bottom-right.
- **c** (cocking, day): cheap indie. Off hand comes over the top-right of the gun; thumb-on-hammer is not legible, reads like a second grab at the cylinder. Nearly identical to a otherwise.
- **d** (firing, day): cheap indie. Blocky square flash cloud swallowing the gun, barrel glows like a tube, cuff band glows bright yellow; no smoke.
- **e** (reload, day): good indie in intent, cheap in framing. A brass round going into the cylinder with the second hand reads; but the left forearm/sleeve fills ~40% of the frame bottom-left and the loading gate is not clearly seen open.
- **f** (rest, night): good indie. Lamp catches the steel with warm highlights; steel reads dark metal, not black. Ground is a lit disc in pure black.
- **g** (aimed, night): cheap indie. Same canted pose as b.
- **h** (cocking, night): cheap indie. Same as c.
- **i** (firing, night): cheap indie. Same mosaic blob; it does light the ground warmly, which helps.
- **j** (reload, night): good indie / cheap. Round and second hand visible, brass catches light; sleeve again dominates.
- **k** (rifle low ready, day): good indie. Strong silhouette, lovely figured walnut, lever loop visible; receiver is a flat dark plate.
- **l** (rifle aimed, day): cheap indie. Rifle near vertical, seen from above as a strip; left arm diagonal across the frame; arms ~40% of screen.
- **m** (lever open, day): good indie / cheap. Lever is clearly thrown down, but the right hand hangs below it, palm up, not in the loop.
- **n** (rifle firing, day): cheap indie. Same strip pose, blocky flash to one side, no smoke.
- **o** (rifle reload, day): cheap indie. Rifle swung left so its right side shows (good idea), fingers near the receiver, but no round and no gate visible.
- **p** (rifle rest, night): good indie for the gun; the left sleeve shows harsh two-tone shading blotches; black jagged shadow shapes at the left edge.
- **q** (aimed, night): cheap indie. Same as l plus sleeve banding.
- **r** (lever open, night): good indie. Warm rim on the receiver edge and stock reads well; hand still not in the lever.
- **s** (firing, night): cheap indie. Blob flash; at least it lights the arms.
- **t** (reload, night): cheap indie. Same as o; nothing in the hand.

## Yes/no
1. Aimed views: **No.** The top of the guns shows but the side barely does (revolver from behind, rifle edge-on as a strip). Cuff/forearm: revolver about a quarter of the screen (borderline OK); rifle arms close to 40% with the left forearm crossing the frame (no).
2. Steel: **Yes, mostly.** By day a neutral dark grey/gunmetal with soft highlights, not saturated blue plastic (if anything too grey: the lab render's deep blue-black and case colours are lost). By night it is not flat black; warm lamp highlights read. The rifle receiver, though, is flat and featureless in both.
3. Reloads: **Revolver yes (weakly), rifle no.** e/j show a round and a second hand at the cylinder (gate not clearly open). o/t show a hand near the receiver with no round visible.
4. Shot reads: **Partly / no.** Light on the ground: yes. Flash shape: a square mosaic blob, not a muzzle flash. Smoke: none. Kick: barely visible at 50 ms.
5. **Revolver by the grip: yes** (a, b, d, f, g, i). **Rifle lever thrown in m and r: yes**, though the hand isn't in the lever.

## The five biggest problems
1. **Aim poses canted/vertical.** Player sees: gun pointing up and across, not at the target; no sight line. Renders b, d, g, i, l, n, q, s. Likely cause: the aim offset/rotation of the viewmodel (or IK target) is wrong, roll/pitch about 45-60 degrees off, or the camera-relative ADS position was tuned for a different FOV. Cheapest fix: re-key the ADS transform so the bore lies along the screen centre line (rear sight at ~centre, slight right offset), barrel pointing into the screen, roll near zero; revolver two-handed or at least wrist straight.
2. **Muzzle flash is a mosaic square; no smoke.** Player sees: a pixel-edged yellow blob and a glowing barrel tube. Renders d, i, n, s. Likely cause: billboard sprite run through the per-texel mosaic/quantise pass at low res, plus an emissive applied to the barrel mesh. Cheapest fix: exempt the flash from the mosaic or give it a star/petal alpha texture; drop the barrel emission; spawn a grey-white black-powder smoke puff that lingers 1-2 s; add 3-5 degrees muzzle rise at 50 ms.
3. **Rifle receiver flat.** Player sees: a black cardboard plate with one line. Renders k-t. Likely cause: receiver uses a plain material with no normal/roughness detail, side plate only drawn as an outline. Cheapest fix: give it the Colt's steel material (roughness variation, edge wear on bevels), bevel edges, add the screws and loading gate as geometry.
4. **Rifle reload empty.** Player sees: hand hovering at the receiver. Renders o, t. Likely cause: the cartridge isn't attached to the hand at that frame (or hidden behind the receiver), gate not modelled/animated. Cheapest fix: parent a brass round to the right hand's fingers, pose it with its nose in the gate, rotate the gun a bit more so the gate faces the camera.
5. **Sleeves dominate and shade badly.** Player sees: big khaki forearms (e, j, l, q) and, at night, blotchy two-tone shading and jagged black shapes at the left edge (p, q, s). Likely cause: forearm too close to the camera, and the toon/quantised lighting on cloth banding under a point light; shadow acne/clip from the lamp. Cheapest fix: pull the off-hand arm back/down 10-15 cm in reload and aim poses; soften the cloth's light ramp or raise its ambient; check the lamp's shadow bias.
Also: a small floating dark speck below the centre post in most day/night revolver shots (a, b, c, f, h): stray object or debug marker.

## Crops
- /home/user/Western/build/judge_r5/crops/b_aimed_revolver.jpg (canted revolver, grip held)
- /home/user/Western/build/judge_r5/crops/d_flash.jpg (mosaic flash and glowing barrel)
- /home/user/Western/build/judge_r5/crops/e_reload_gate.jpg (round going into the cylinder, sleeve)
- /home/user/Western/build/judge_r5/crops/l_aimed_rifle.jpg (rifle seen edge-on)
- /home/user/Western/build/judge_r5/crops/m_lever_open.jpg (lever thrown, hand below it, flat receiver)
- /home/user/Western/build/judge_r5/crops/o_reload_rifle.jpg (hand at receiver, no round)
