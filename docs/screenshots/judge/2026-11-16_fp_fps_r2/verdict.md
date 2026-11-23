# Judge r4

Overall: **cheap indie** (the revolver at rest in the hand is close to good indie; the aim, shot, reload and every rifle frame pull it down).

## Top 3 problems
1. Aimed and fired states (b, d, g, i, l, n, q, s): the camera looks straight down the gun, so the gun is a sliver seen end-on and a huge flat cream shirt cuff and coat sleeve fill a third of the screen. On the rifle (l, n, q, s) the receiver is hidden and the stock reads as a wooden pole.
2. Reloads show nothing. The rifle reloads (o, t) are the rest frames: t is pixel-identical to p and o almost matches k. The revolver reloads (e, j) just tip the gun up: no gate open, no second hand, no cartridge.
3. The steel reads as saturated royal-blue plastic by day (a, c, e, k, m, o; the rifle receiver is a flat medium blue slab), not the near-black blued steel of colt_lab. At night (f, h, p, r, t) it goes to flat black.

## Per render
- a (revolver rest, day): good indie. The hand wraps the walnut well, but the steel is too bright and cobalt-blue, and there's no sleeve or wrist, so the hand floats.
- b (revolver aim, day): cheap indie. The gun is end-on and almost hidden behind the fist; the cuff is a flat, untextured cream disc that dominates the frame.
- c (revolver cock, day): cheap indie. The thumb lies along the cylinder side, not on the hammer spur. The hammer isn't visible being drawn back, so it reads as "hand touching gun".
- d (revolver shot, day): cheap indie. The flash is a pale, flat cream cluster of square-edged quads with no hot core and no smoke. The roll kick reads, but the gun barely moves.
- e (revolver reload, day): cheap indie. The gun is just held up at an angle, with no open gate, no ejector, no left hand and no round.
- f (revolver rest, night): good indie. Its silhouette reads, but the steel is pure black with no lamp highlights on the cylinder or barrel.
- g (revolver aim, night): cheap indie. Same as b, with the cuff and sleeve filling the frame.
- h (revolver cock, night): cheap indie. Same thumb-on-cylinder pose, and the gun is black with no highlights.
- i (revolver shot, night): good indie. The flash lights the hand and cuff warmly (the best frame), but it's still a flat quad cluster, with no smoke and the gun hidden.
- j (revolver reload, night): cheap indie. It reads as waving the gun; no reload action.
- k (rifle rest, day): cheap indie. The receiver is a flat, uniform blue slab like plastic, and the left forearm rises straight up from the frame bottom like a post.
- l (rifle aim, day): cheap indie. There's no receiver, and the front sight is the only steel. A giant cuff disc covers the right third, and the stock reads as a wooden pole running down the middle.
- m (rifle lever open, day): good indie. The lever is clearly thrown, but the fingers aren't in the lever loop (the hand hangs below it) and the receiver is still flat blue plastic.
- n (rifle shot, day): cheap indie. The flash is a small pale smudge behind the sight, with no smoke, no visible kick and the cuff dominating.
- o (rifle reload, day): cheap indie. It's nearly identical to k: no reload is shown.
- p (rifle rest, night): cheap indie. The steel is black with no highlights. A jagged black shadow cuts the left edge of the frame (beside the forearm), and the sleeve has a hard cut-out edge.
- q (rifle aim, night): cheap indie. Same as l, with the receiver hidden and the sleeve wall.
- r (rifle lever open, night): good indie. The lever reads; the steel is plain black.
- s (rifle shot, night): cheap indie. The small flash does light the hand, but it's flat quads with no smoke, and the cuff wall is still there.
- t (rifle reload, night): cheap indie. It's pixel-identical to p: no reload at all.

## Yes/no
1. Is the revolver held by its grip, the hand round the walnut? **Yes**: the fingers wrap the walnut in a, c and f. The thumb is low and there's no visible wrist or sleeve at rest.
2. Does the shot read (flash, light, smoke, kick)? **Partly / no.** The flash is there but flat and pale, and only lights the scene noticeably at night (i). There's **no smoke** in any frame. The kick is a small camera roll on the revolver and none visible on the rifle.
3. Does the cocking frame show the thumb on the hammer, and the rifle's lever frame the lever thrown? **No / Yes.** The thumb is on the cylinder, not the hammer (c, h). The lever is clearly thrown (m, r).
4. Does the aimed rifle show its receiver and sights, with the arm out of the way? **No.** Only the front sight shows; the receiver is hidden and the right cuff and sleeve block a third of the screen (l, q).
5. Does the steel read as dark blued steel with highlights rather than black or bright blue plastic? **No.** By day it's bright blue plastic (the rifle receiver is the worst), and at night it's flat black.

## The five biggest problems

1. **Down-the-barrel aim with the sleeve wall.**
   - What a player sees: when aiming, the gun almost disappears behind a fist, and a giant cream cuff and coat sleeve take a third of the screen. The rifle's receiver is gone, and its stock looks like a pole.
   - Renders: b, d, g, i, l, n, q, s.
   - Likely cause: the ADS pose puts the gun dead centre on the camera axis, with the right arm coming straight back into the near plane. The cuff is a big, flat-shaded disc very close to the camera.
   - Cheapest fix: offset the ADS pose. Drop the gun slightly, yaw it about 8–12° so its right side shows, and bring the eye to the rear sight rather than the bore line. Pull the right elbow out and down, and narrow the camera's near-arm visibility (clip, shrink or lower the cuff, or hide the sleeve inside 25 cm). On the rifle, put the cheek on the stock so the receiver sits in the lower centre.
2. **Reload is a non-animation.**
   - What a player sees: pressing reload does nothing (rifle) or just tips the revolver up.
   - Renders: e, j, o, t (t = p exactly, o ≈ k).
   - Likely cause: no reload pose or clip wired for the rifle, and the revolver reload pose lacks the gate open and the left hand.
   - Cheapest fix: one held key pose each. Revolver: rolled 30–40° left, gate open, left hand bringing a cartridge to the gate. Rifle: rolled right, left hand at the receiver's side gate with a round.
3. **Steel material wrong.**
   - What a player sees: the revolver and rifle look like blue plastic toys by day and black silhouettes by night. They don't match colt_lab's near-black steel with a blue sheen.
   - Renders: a, c, e, k, m, o (day); f, h, p, r, t (night).
   - Likely cause: the albedo is too saturated and too light blue, roughness too high (broad diffuse blue instead of tight specular), and no reflections or environment specular in the viewmodel pass.
   - Cheapest fix: drop the albedo to near-black with a slight blue tint (around 0.03–0.05), metallic 1 and roughness 0.25–0.35, so the colour comes from specular. Give the viewmodel a reflection probe or sky radiance, plus a small rim light so the lamp at night draws highlights.
4. **Weak shot.**
   - What a player sees: the shot is a pale cream paper cut-out, with no smoke and hardly any kick.
   - Renders: d, i, n, s.
   - Likely cause: the flash is a few additive quads with a low-intensity, desaturated texture. There's no smoke emitter at 50 ms, and the recoil is applied only as a small camera roll.
   - Cheapest fix: make the flash brighter, hotter and smaller-cored (white-yellow core, orange petals, about 1 frame), and add a short-lived OmniLight at the muzzle (it seems to exist at night; raise its energy by day). Spawn 2–3 grey smoke billboards at the muzzle. Add muzzle rise of 6–10° on the gun and hand, plus some camera kick.
5. **The cocking thumb misses the hammer.**
   - What a player sees: on cocking, the thumb lies on the cylinder; you never see the hammer come back.
   - Renders: c, h.
   - Likely cause: the thumb bone target is set to the frame or cylinder, not the hammer spur, and the hammer isn't animated or visible from this angle.
   - Cheapest fix: retarget the thumb IK to the hammer spur and roll the gun 15–20° so the spur and thumb read in silhouette against the sky. Show the hammer at half or full cock.

Minor: in the night rifle frames (p, q, t) there's a jagged black shadow slab at the left frame edge and a hard cut-out on the left sleeve, and in the rifle rest pose the left forearm stands vertical like a post. The hands and skin are passable.

## Crops
- /home/user/Western/build/judge_r4/l_rifle_aim_cuff_hides_receiver.png: aimed rifle, with the cuff wall, no receiver and a wooden pole.
- /home/user/Western/build/judge_r4/d_flash_flat_cream_quads.png: flat cream quad flash, no smoke, gun hidden.
- /home/user/Western/build/judge_r4/c_thumb_on_cylinder_not_hammer.png: cocking thumb on the cylinder, hammer not shown.
- /home/user/Western/build/judge_r4/m_receiver_flat_blue_plastic.png: flat blue plastic receiver; fingers not in the lever.
