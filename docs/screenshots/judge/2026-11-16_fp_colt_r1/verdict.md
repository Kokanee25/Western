# Judge r1: first-person guns and hands (blind)
Overall: **cheap indie** for the guns and hands in all 20 renders; the street and porch behind them are good indie.
Top problem: both guns' steel renders as **saturated electric/royal blue plastic** by day (a-e, k-o), nothing like the gun lab's dark blued steel, case colours and walnut.
Second: the **aimed views (b, d, g, i, l, n, q, s) hide the gun**: a huge black sleeve block fills the lower right and only a sliver of sight or muzzle shows.
Third: **hands look like smooth orange-tan mittens**, with fingers draped over the cylinder or receiver top instead of wrapped round the grip.
Fourth: at night (f-j, p-t) the gun is **pushed into the bottom-right corner and clipped**, a dark blob; the cuff is the brightest thing on screen.
Fifth: in the reload and lever states (e, j, o, t) the long gun or barrel is **stretched by perspective** across half the screen, and the states c/h and m/r show no visible change (no thumb on the hammer, lever not thrown).
Yes/no: (1) No. (2) No. (3) Partly no. (4) No. (5) Yes.

## Per render (verdict; biggest thing wrong)
- **a** cheap indie: the revolver is glossy royal-blue plastic, and the hand drapes over the cylinder, not round the grip.
- **b** cheap indie: the aim is a black sleeve filling a third of the screen; only the front of the cylinder shows over the knuckles.
- **c** cheap indie: same as a; no thumb on the hammer, so "cocking" doesn't read.
- **d** cheap indie: the same sleeve-block aim as b; no muzzle flash or smoke at 50 ms, so it doesn't read as a shot.
- **e** cheap indie: the gun is tipped up with a long, perspective-stretched barrel, and the wrist bends like rubber; no open gate or cartridge visible.
- **f** cheap indie: the gun is a dark shape clipped at the right edge; you see an orange forearm and a pale cuff.
- **g** cheap indie: the black sleeve fills the right half; the gun is invisible.
- **h** cheap indie: same as f; the cocking can't be seen.
- **i** cheap indie: same as g; no flash lights the porch, so no shot.
- **j** good indie (low end): the only night revolver shot where the steel reads as dark metal, but the hand is a waxy orange glove and the gun is clipped at the edge.
- **k** cheap indie: the Winchester is flat royal blue with a toy-like outline on the receiver; the hands are mittens.
- **l** cheap indie: a sleeve-and-stock tunnel; the receiver and sights are a tiny blue square.
- **m** cheap indie: identical to k; the lever isn't visibly thrown.
- **n** cheap indie: same as l, with no flash or smoke.
- **o** cheap indie: the rifle crosses the whole screen, stretched; the receiver is a flat blue slab with a drawn-on panel line, and the fingers are splayed under it.
- **p** cheap indie: the rifle is a dark slab cut off at the bottom right; the cuff glows brighter than the lamp.
- **q** cheap indie: a black sleeve block again; no rifle.
- **r** cheap indie: same as p; no lever motion.
- **s** cheap indie: same as q, with no flash.
- **t** good indie (low end): the dark steel reads better at night, but the gun is perspective-stretched and the hand is a smooth orange glove.

## The five biggest problems

### 1. The steel is bright blue plastic (a-e, k-o)
- **What a player sees:** in daylight the Colt and the Winchester are a saturated royal or cobalt blue with a glossy, even sheen, like a toy cap gun. There are no case colours on the frame, no wear at the edges and no walnut grip to speak of. The gun lab render is near-black blued steel with mottled case colours and brown walnut.
- **Likely cause:** the material. The "blued" tint is taken literally as an albedo colour (or the in-hand viewmodel uses a placeholder or untextured material). The sky's reflection on a low-roughness surface then pushes it bluer still. At night the same material reads dark, so it is the albedo and specular, not the gun's shape.
- **Cheapest fix:** give the viewmodel the gun lab's material: near-black albedo (about 0.03-0.05), a faint blue only in the specular tint, the case-colour texture on the frame, and roughness of about 0.35-0.5 with edge wear.
- **Crops:** `/home/user/Western/build/judge_r1/a_blue_steel_hold.png`, `/home/user/Western/build/judge_r1/k_rifle_hip_blue_hands.png`

### 2. Aiming hides the gun behind a sleeve block (b, d, g, i, l, n, q, s)
- **What a player sees:** when aiming, a black coat sleeve rises from the bottom right and covers a third to a half of the screen. Of the gun, only the cylinder's front, or a blue front-sight square, peeks over the knuckles. In the Hunt reference and in the game's own target (`hold_game_aim`), the gun's top strap or receiver runs into the centre, and the arms come in low from both corners.
- **Likely cause:** the gun's place in the view. The aim pose puts the camera behind the forearm, and the arm is too high and too close (perhaps too large a FOV on the viewmodel), so the forearm sits between the eye and the gun.
- **Cheapest fix:** lower the forearm and move it outward (toward the bottom-right corner), bring the gun back toward the eye so the frame and hammer show, and drop the elbow so the sleeve exits below the screen.
- **Crop:** `/home/user/Western/build/judge_r1/b_aim_sleeve_block.png`

### 3. The hands are mittens and don't grip (all)
- **What a player sees:** the hands are smooth, waxy orange-tan, with no knuckles, nails, tendons or dirt. On the revolver at rest the fingers lie over the top of the cylinder and frame, and the grip hangs below the hand. On the rifle in o and t the fingers are splayed and floating under the receiver. Nothing shows the trigger finger along the frame.
- **Likely cause:** the hand's grip pose is wrong for this gun's grip position (an offset in the hand's anchor), and the skin material is flat (no subsurface, no normal map, too saturated).
- **Cheapest fix:** move the revolver up and back in the hand so the grip sits in the palm, with three fingers closed round it and the index finger straight along the frame. Desaturate the skin, and add a normal map with knuckle creases and some grime.
- **Crops:** `/home/user/Western/build/judge_r1/a_blue_steel_hold.png`, `/home/user/Western/build/judge_r1/o_rifle_reload_stretch.png`

### 4. At night the gun is clipped off-screen and the cuff glows (f, h, j, p, r, t)
- **What a player sees:** the hip pose puts the revolver or rifle in the far bottom-right corner, half off-screen, as a dark blob. The brightest thing near it is the pale cream cuff, brighter than the skin and the gun. It reads like a lit block of cloth, not a shirt cuff under a coat.
- **Likely cause:** the hip placement is further right and lower than by day (or the camera's aspect cuts it). The cuff is unshaded, a light albedo with no lamp falloff or shadow from the coat sleeve, so it outshines its surroundings.
- **Cheapest fix:** bring the hip pose 10-15% in toward the centre so the cylinder or receiver is fully on screen. Darken the cuff's albedo, add cloth folds, and let the sleeve cast a shadow on it.
- **Crop:** `/home/user/Western/build/judge_r1/f_night_gun_offscreen.png`

### 5. Perspective stretch and states that don't read (e, j, o, t; c, h, m, r; d, i, n, s)
- **What a player sees:**
  - **Reloading:** in e the revolver's barrel stretches up the screen like a rifle, and the wrist bends unnaturally. In o the Winchester spans the whole width of the screen, stretched near the camera. Neither shows an open loading gate or a cartridge.
  - **Cocking and firing:** the cocking and lever states look identical to rest. The firing states have no flash, smoke or lamp-lit bounce.
- **Likely cause:** the viewmodel shares the world's wide FOV (stretching near geometry), and the animation keys for the hammer, lever and gate are missing or too small to see.
- **Cheapest fix:** render the viewmodel with its own narrower FOV (about 50-55°). Exaggerate the hammer and lever travel and turn the gun to show the gate. Add a short muzzle flash with a light pulse and smoke.
- **Crops:** `/home/user/Western/build/judge_r1/o_rifle_reload_stretch.png`, `/home/user/Western/build/judge_r1/e_reload_wrist_bend.png`

## Yes/no
1. **Is the gun big enough and placed where a shooter puts it? No.** At rest by day the revolver is roughly placed (lower right, pointing in), but the hand covers the grip. Aiming hides the gun behind the sleeve, and at night the gun is clipped in the corner.
2. **Does the revolver's hand hold it by its grip? No.** The fingers drape over the cylinder and top of the frame. The grip hangs below the hand, and no trigger finger lies along the frame.
3. **Do the cuff and sleeve read as a sleeve? Partly no.** The coat sleeve is a smooth black tube with no folds, and in the aimed views it is a block. The cream cuff is a flat glowing band.
4. **Does the revolver's steel look like the gun lab's render? No.** The gun lab's is dark blued steel with case colours and walnut; in hand by day it is saturated toy-blue plastic, and only at night (j) does it approach the right darkness.
5. **Anything distorted or clipped by the camera? Yes.** The long guns and the reloading revolver are stretched near the lens (e, o, t), the hip guns at night are clipped at the right and bottom edges, and the aimed sleeve swallows the gun.
