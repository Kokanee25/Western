# Judge r6
Overall: **cheap indie** (the hands and the Colt are decent, but the flat untextured rifle receiver, blocky square muzzle flashes, aimed views that bury the gun behind a huge sleeve, and blotchy night shadows on the arms read as a prototype, nowhere near Hunt's dense, worn, close-framed guns)

## Top 3 problems
1. **Aimed views hide the gun.** b/d/g/i (Colt) show the revolver tiny, almost end-on from directly behind, held at full arm's length; the sleeve and forearm fill the lower right third. l/n/q/s (rifle) are seen straight down the tube, with two coat sleeves filling the bottom half. The weapon is the least visible thing in its own aimed shot.
2. **The Winchester's receiver is a flat grey slab.** No bevels, no engraving, no brass (a real '73 has a case-coloured or blued receiver with a shaped side plate), just a drawn outline rectangle and a dark matte box. Next to a wooden forend that has real grain, it looks like a placeholder.
3. **The muzzle flash is a square, pixelated sprite.** In d/i/n/s it's a pale yellow block with stair-stepped edges and a soft square halo, no cone or petals, no smoke plume, and no visible kick (the gun sits where it does in the aimed frame). It reads as a sprite glitch, not a black-powder shot. (Black powder should give a big dirty-white smoke bloom.)

## Per render
- **a** (Colt hip, day): good indie. A bare hand holds the grip low, the gun is seen from rear-quarter, and the steel is dark grey with soft highlights. No cuff or sleeve, so the hand stops at the frame edge, oddly naked next to the coated arm in b.
- **b** (Colt aimed, day): cheap indie. The gun is a thumbnail about 40 px across, seen from directly behind; the sleeve and cuff own the lower right. It reads as "arm stretched out" rather than as a sight picture.
- **c** (cocking, day): good indie. The thumb clearly sits on the hammer, the pose is the same as a, and the action reads.
- **d** (firing, day): cheap indie. Square blocky flash, no smoke and no visible recoil; the gun barely shows inside the flash.
- **e** (reload, day): good indie. Two hands, the gun canted right, a brass round at the gate; it reads as a reload. The arms are very large and fill the lower left, and the near hand looks swollen.
- **f** (hip, night): good indie. The lamp gives warm light, but the steel turns bright silver/nickel instead of blued.
- **g** (aimed, night): cheap indie. Same framing problem as b, and the gun is a small silhouette against the flash ball behind it.
- **h** (cocking, night): good indie. Reads; the steel is again too bright and chromey for bluing.
- **i** (firing, night): cheap indie. The square flash is even more obvious against the dark sky. A red flicker on top looks like a stray particle.
- **j** (reload, night): good indie. Reads well; the barrel picks up a brassy, warm specular that is nice but not blued.
- **k** (rifle low ready, day): cheap indie. The left forearm rises vertically from the bottom edge like a post. The receiver is a flat slab, the right hand is on the wrist, and the lever loop is empty.
- **l** (rifle aimed, day): cheap indie. Straight down the barrel; the receiver top is a grey strip and the two sleeves take half the screen. It reads as aimed, but you can't tell it's a Winchester.
- **m** (lever open, day): good indie. The lever is clearly dropped and the bolt is back. The right hand hangs below the lever instead of being in the loop, so it looks like the lever opened by itself.
- **n** (rifle firing, day): cheap indie. The square flash sits to the left of the muzzle with no smoke and no shoulder kick.
- **o** (rifle reload, day): good indie. The rifle is turned to show its right side, a hand presses a brass round at the gate, and the support hand is on the forend. Clear. But a big dark strap arcs from the muzzle off-screen like a whip, and the receiver is still a slab.
- **p** (rifle low ready, night): cheap indie. The near sleeve has blotchy, stepped shadow patches, and the receiver's lit edge turns gold.
- **q** (rifle aimed, night): cheap indie. Same framing as l; the left sleeve has pixel-stepped dark blotches (shadow aliasing) running down it.
- **r** (lever open, night): good indie. The lever reads. The same sleeve blotches, and the hand is out of the loop.
- **s** (rifle firing, night): cheap indie. Square flash plus blotchy sleeve.
- **t** (rifle reload, night): good indie. The clearest of the night shots; the barrel's warm specular looks nice.

## Yes/no
1. **No.** The aimed views read as aimed, but neither gun's side or top shows meaningfully: the Colt is tiny and end-on, and the rifle is a tube seen down its axis. The sleeve and cuff take roughly a quarter to a third of the screen (b, d, g, i: lower right; l, n, q, s: the bottom half with both arms).
2. **Partly.** Day: yes for the Colt (dark blue-grey, soft highlights, no plastic blue); the rifle receiver is matte grey with no blue and no sheen. Night: not flat black (pass on that), but the Colt goes bright silver/nickel and the rifle's edges go gold, so it no longer reads as blued.
3. **Yes.** e/j show two hands, the gun canted and a brass round at the gate. o/t show a hand at the right-side gate with a round. All four read as reloads (the Colt's open gate itself is hard to see at this size).
4. **No.** The flash is a blocky square sprite with stepped edges. It does light the scene a little (warm halo at night), but there's no smoke and no visible kick.
5. **Yes / partly.** The revolver is held by its grip in every view (a/c/f/h with the hand around it, b/d with the grip showing below the fist). The rifle's lever is clearly thrown in m and r, but the right hand isn't in the loop.

## The five biggest problems
1. **Aimed framing.** What the player sees: a distant thumbnail of a gun and a wall of sleeve. Renders: b d g i l n q s. Likely cause: the ADS pose puts the gun at full arm extension, centred exactly on the camera axis, with a narrow viewmodel FOV and the camera behind the wrist. Cheapest fix: bring the gun 30-40% closer to the camera, lower the arm so the cuff drops off the bottom edge, and roll or offset the gun a few degrees so the top strap and right side show (as Hunt does with its slightly canted, close ADS). For the rifle, lower the eye slightly above the receiver so the top and the rear sight show, and push the left arm down and out.
2. **Untextured rifle receiver.** What the player sees: a grey box where the most recognisable part of the Winchester should be. Renders: k l m o p r t. Likely cause: a placeholder material, or one missing its normal or roughness map, and no bevels on the side plate. Cheapest fix: give it the same blued-steel material as the Colt (which works), add a bevelled side plate and screws, and a little edge wear.
3. **Blocky flash, no smoke, no kick.** What the player sees: a pale square pops up. Renders: d i n s. Likely cause: the flash sprite is drawn at low resolution, or the pixel quantise is hitting an additive billboard, and the smoke and recoil come after 50 ms or are missing. Cheapest fix: a star or cone-shaped flash texture drawn at full resolution (or 2-3 crossed quads), a dense grey-white black-powder smoke puff that starts in the first frame, and 3-6 degrees of muzzle rise plus a small backward step on the firing frame.
4. **Night arms and steel.** What the player sees: blotchy stair-step stains down the coat sleeve, and guns that look chrome or gold under the lamp. Renders: p q r s (sleeves), f h j t (steel). Likely cause: shadow-map resolution and bias on the viewmodel layer (the lamp's shadow is self-shadowing the arm), and specular too strong or metallic albedo too bright for one warm point light. Cheapest fix: turn off shadow casting on the viewmodel arms (or raise the bias), and lower the steel's albedo and specular under point lights.
5. **Hands and props that don't connect.** What the player sees: a sling arcing from the muzzle into nowhere (o, t), the right hand hanging below the open lever rather than working it (m, r), the left forearm sticking vertically up from the bottom edge at low ready (k, p), and the bare hand with no cuff in the Colt hip views next to a coat in the aimed ones (a vs b). Likely cause: pose targets not tied to the lever, an unconstrained sling chain, and arm meshes toggled per pose. Cheapest fix: parent the right hand's IK target to the lever loop, pin both ends of the sling (or hide it in first person), and show the same sleeve in every pose.

## Crops
- crops/a_colt_hip_grip_and_steel.jpg: the Colt in hand at the hip (grip, steel tone).
- crops/b_colt_aimed_gun_small_endon.jpg: the aimed Colt, small and end-on behind a large cuff.
- crops/d_colt_flash_blocky.jpg: the square, stair-stepped muzzle flash.
- crops/k_w73_receiver_flat_slab.jpg: the Winchester receiver as a flat outlined slab, the hand off the lever.
- crops/q_night_sleeve_blotches.jpg: pixel-stepped shadow blotches on the night sleeve.
- crops/o_w73_reload_gate_sling.jpg: the round at the right-side gate (reads), and the stray sling arc.
