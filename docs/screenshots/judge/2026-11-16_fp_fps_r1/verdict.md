# Judge r3
Overall: cheap indie. The revolver model is decent and the hand is at least near it, but the poses (aim, cock, reload, the whole rifle) are wrong or unreadable, the shot is a blocky paper flash with no smoke, and the rifle's steel is flat royal-blue plastic.

Top 3 problems:
1. The aimed views hide the guns: b/d/g/i show the revolver end-on, almost entirely behind the fist and a huge sleeve cuff; l/n/q/s have the rifle stock running straight down the centre of the screen (not shouldered), the receiver invisible under a hand, and the right sleeve filling the right third.
2. The rifle's hands and steel: k/m/o (and p/r/t) show a disembodied right hand with no arm, a loose thumb-like blob stuck on the receiver side, the left hand lost behind the barrel, and a receiver of flat saturated blue that reads as plastic, nothing like the approved gun's near-black blued steel.
3. The actions don't read: c/h cocking is an open splayed palm against the frame (no thumb on the hammer), e/j reload is just the gun tilted with no gate open, no cartridge and no left hand, and o/t (rifle reload) is the same frame as the rest pose k/p.

## Per render
- a (revolver rest, day): cheap indie. The hand clutches the frame/cylinder with the walnut hanging out below it; the thumb is a detached-looking blob at the bottom; the muzzle points up and away, not a hip carry.
- b (revolver aimed, day): cheap indie. The gun is a sliver end-on behind the fist; the sleeve cuff and forearm cover a quarter of the screen; no sight picture.
- c (revolver cocking, day): cheap indie. An open, splayed hand pressed on the side of the frame; the thumb isn't on the hammer, and nothing tells you the hammer is moving.
- d (revolver shot, day): cheap indie. The flash is a flat cluster of pale-yellow squares behind the gun, no smoke, barely any kick against b; the cuff picks up a bright rim, which is the only sign of light.
- e (revolver reload, day): cheap indie. The gun is just rolled to the left; no loading gate open, no cartridge, no second hand; the steel goes bright blue on the barrel.
- f (revolver rest, night): cheap indie. Same grip problem as a; the gun goes to a black silhouette and the hand is lit warmer than anything else.
- g (revolver aimed, night): cheap indie. As b; gun invisible behind the fist.
- h (revolver cocking, night): cheap indie. As c; open palm, no thumb on hammer.
- i (revolver shot, night): cheap indie. Big blocky flash, some warmth on the cuff and ground, but no smoke, no strong pool of light thrown on the scene, no visible recoil.
- j (revolver reload, night): cheap indie. As e; gun a dark blob, no reload action.
- k (rifle rest, day): cheap indie. Floating right hand with no arm, a thumb blob stuck to the receiver, the left arm a big sleeve column with no hand; the receiver is flat bright blue.
- l (rifle aimed, day): cheap indie. Stock runs vertically down the screen centre (held at the waist, not the shoulder); the receiver is hidden under a hand; the right cuff and sleeve fill the right side.
- m (rifle lever open, day): cheap indie. The lever loop is visibly thrown (good), but the fingers point up beside it rather than through it, and the hand has no arm.
- n (rifle shot, day): cheap indie. Small white starburst at the muzzle, no smoke, no light on the scene beyond the cuff rim, no kick visible against l.
- o (rifle reload, day): cheap indie. Identical to k: no loading gate, no cartridge, no hand moving.
- p (rifle rest, night): cheap indie. As k, with the receiver going to black.
- q (rifle aimed, night): cheap indie. As l; front sight barely visible, receiver hidden.
- r (rifle lever open, night): cheap indie. As m; lever reads, hand still floating.
- s (rifle shot, night): cheap indie. Tiny flash, ground lit only by the existing lamp pool; no smoke.
- t (rifle reload, night): cheap indie. Identical to p.

## Yes/no
1. Is the revolver held by its grip, the hand round the walnut? No. The hand sits over the frame and cylinder with the walnut sticking out below (a, c, f, h); in the aimed views you can't tell.
2. Does the shot read (flash, light, smoke, kick)? Partly. Revolver flash is big but blocky; some light on the cuff; no smoke and no visible kick in any shot (d, i, n, s). The rifle's flash is small.
3. Does the cocking frame show the thumb on the hammer, and the rifle's lever frame the lever thrown? Thumb: no (c, h: open palm). Lever: yes (m, r: the loop is down and clear).
4. Does the aimed rifle show its receiver and sights, with the arm out of the way? No. Only the front/rear sight tips show; the receiver is under a hand, the stock runs down the middle, and the right sleeve covers the right third (l, n, q, s).
5. Does the steel read as dark blued steel with highlights? Revolver: mostly yes by day, blue-black with sheen, though the barrel goes bright blue in e. Rifle: no, flat saturated royal blue that reads as plastic (k, m, o); at night both go to black silhouettes.

## The five biggest problems
1. **Aimed views bury the gun.** Player sees: a fist, a giant cuff and a sliver of steel; no sight picture, no gun side. Renders: b, d, g, i (revolver); l, n, q, s (rifle). Likely cause: the ADS pose aligns the bore exactly to the camera axis with the hand/forearm on the same line and the camera too close; the rifle isn't placed at the shoulder (stock pointing at the bottom-centre of the screen). Cheapest fix: for the revolver, offset the ADS pose a few cm right and down, roll the gun ~10-15 deg to show its left flank and drop the forearm out of frame; for the rifle, put the butt at the shoulder (out of frame bottom right), raise the receiver so its side shows just below the sight line, and push the right arm down/right so only the hand is in view.
2. **Rifle hands are broken.** Player sees: a disembodied right hand, a stray thumb-like blob on the receiver, and the left hand missing behind the barrel. Renders: k, m, o, p, r, t. Likely cause: the right arm mesh is culled or posed off-camera while the hand stays; a finger/thumb bone is mis-targeted onto the receiver; the left hand IK target is behind the forend. Cheapest fix: show the right forearm/sleeve, re-target the right thumb to wrap the wrist of the stock, and move the left-hand target under the forend so its fingers wrap visibly.
3. **Rifle steel is plastic blue.** Player sees: a toy-blue receiver and barrel, unlike the near-black blued revolver. Renders: k, m, o (day). Likely cause: the rifle's steel albedo is far too saturated/bright (or it lacks the revolver's metallic/roughness setup, so the blue base colour shows as diffuse). Cheapest fix: reuse the revolver's blued-steel material on the rifle (dark, low-saturation albedo, metallic ~1, roughness ~0.3) and check it against colt_lab.jpg.
4. **The shot is weak and blocky.** Player sees: a flat stack of pale-yellow squares (revolver) or a small star (rifle), no smoke, no recoil, little light on the scene. Renders: d, i, n, s. Likely cause: the flash is a single quad of pixel-snapped cards with no smoke emitter at 33 ms and a short/weak light; the recoil offset isn't applied or is tiny. Cheapest fix: add a short-lived bright omni light at the muzzle (strong at night), a grey-white smoke puff emitter that starts on the shot, a 5-8 deg muzzle-up kick for the revolver and a shove back for the rifle at the 33 ms mark, and soften the flash's squares into a hotter core.
5. **Cocking and reloading don't happen.** Player sees: an open palm on the revolver instead of a thumb on the hammer; a reload that is the gun tilted with nothing loaded; a rifle reload identical to its rest pose. Renders: c, h, e, j, o, t. Likely cause: the hand poses for these states are placeholders (fingers opened, no thumb target), the side gate and cartridge aren't animated, and the rifle reload state isn't wired. Cheapest fix: a thumb IK target on the hammer spur with the other fingers staying on the grip; for reloads, open the gate, bring the left hand in with a cartridge at the gate (revolver) or the receiver's loading gate (rifle).

## Crops (in /home/user/Western/build/judge_r3/)
- k_rifle_rest_floating_hand_plastic_blue_receiver.png
- l_rifle_aimed_stock_down_centre_no_receiver.png
- d_revolver_shot_blocky_flash_no_smoke_gun_hidden.png
- c_revolver_cock_open_palm_not_thumb_on_hammer.png
