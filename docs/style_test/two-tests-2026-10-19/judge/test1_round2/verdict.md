# Judge's verdict: test 1, round 2 (the bold cowboy), 2026-10-19

Judged by eye against `docs/concept/judge/RUBRIC.md`, the authority `10_authority_saloon_man.jpg`,
the man outdoors `14_style_man_saloon_front.jpg` and his style portrait
`docs/concept/style/portrait-cowboy-front.png`. Focus is the man; the room and street are judged
only as they bear on him fitting the world. Boxes are `x y w h` in each render's own pixels.

Face brightness (mean luma of the face box, 0-255) for reference: card table close 62, card table
wide 65, across saloon 53, across street 42, plain front 72.

---

## 1_card_table_close.jpg (seated at the card table, close, saloon at night)

| Trait | Result | Deciding region |
|---|---|---|
| 1 Shapes | PASS | head, hat and torso credible and massive; strong silhouette against the room |
| 2 Painted surface | FAIL | his right sleeve (300 480 180 240): flat cream with soft tan blotches that don't follow folds, beside the angular face |
| 3 Light | PASS | warm lamp key on the face, blue moonlit doorway as cool fill, eye sockets dark but readable |
| 4 People | FAIL | the face passes (angular planes, warm skin, painted moustache, the authority's kind of man); the sleeve and the mug hand don't |
| 5 One hand | FAIL | the men behind him (0 270 450 380, 780 60 420 600) are flat, low-detail, plasticky shirts and mitt hands: not the hand that painted his face |

**Verdict: FAIL**

1. **(300 480 180 240) The shirt sleeve.** Against the authority's sleeve (white cuff with a few
   hard-edged fold planes) this is a smooth cream tube with blurred tan blotches: camouflage mottle,
   not folds. Cause: **paint**. Fix: repaint the sleeve with 3-4 angular fold planes (light top,
   warm mid, a hard dark crease at elbow and cuff), no soft blotches.
2. **(675 325 35 30) A hard white highlight on his cheek under the left eye**, the brightest thing
   in the face; reads as a hole or a stray specular. The authority's face has no white spot. Cause:
   **paint** (a light texel in the face texture) or **light** (specular). Fix: clamp the face's
   specular / repaint that texel to the cheek's warm mid tone.
3. **(520 220 320 260) Skin overheated and the ear tangled.** The face runs saturated red-orange
   into deep rust shadows (the authority's skin is tan-warm with cooler, greyer shadow planes), and
   the hair over the ear (530 330 60 60) is a ragged clump of separate strands. Cause: **paint**
   (skin saturation) and **shape** (hair cards). Fix: drop the skin's saturation in the shadow
   planes ~20% toward a cool brown; merge the ear hair into one painted mass.

## 2_card_table_saloon_night.jpg (same, wider)

| Trait | Result | Deciding region |
|---|---|---|
| 1 Shapes | FAIL | the mug hand (500 480 90 100): a fused orange mitt with no fingers, the wrist glowing |
| 2 Painted surface | FAIL | the sleeve (230 490 300 190): cream with tan mottle |
| 3 Light | PASS | lamps warm, moon window cool, the table lamp a nameable source |
| 4 People | FAIL | face good and lit; sleeve and hand fail; the crowd behind is flat |
| 5 One hand | FAIL | background men (0 250 330 330, 600 120 300 380) and his white sleeve look like a different, smoother, rougher-modelled hand than his face and the table |

**Verdict: FAIL**

1. **(230 490 300 190) The sleeve**, biggest bright area on him: smooth cream with blurred tan
   blotches, no folds, the brightest object in the frame. The authority's sleeve is darker,
   mostly hidden by the coat, folds in hard planes. Cause: **paint** (and the shirt's value too
   high under lamplight). Fix: as in render 1, angular fold planes, and bring the shirt's value
   down so it isn't brighter than the lamp glass.
2. **(500 480 90 100) The hand on the mug** reads as a blob: an orange mitten wrapped round the
   handle, fingers and knuckles missing, the wrist and back of the hand lit hotter than the face.
   The authority's hands show knuckles and fingers in a few planes. Cause: **shape** (grip pose /
   hand mesh) and **paint**. Fix: pose the fingers round the handle with the thumb on top; paint
   knuckle planes; match the hand's tone to the face.
3. **(330 250 200 150) Face slightly small and hat high for the crop**, and the skin again very
   red-orange (as render 1). At this distance he still reads as the portrait man (moustache, grey
   sides, furrowed brow). Cause: **paint**. Fix: the same skin desaturation as render 1.

## 3_across_saloon_night.jpg (standing across the saloon at night)

| Trait | Result | Deciding region |
|---|---|---|
| 1 Shapes | FAIL | figure (580 290 120 310): stiff A-pose, square wide shoulders, hands splayed like claws (580 440 125 50) |
| 2 Painted surface | PASS | at this distance vest, shirt and trousers read as painted masses; boards painted |
| 3 Light | FAIL | the "night" room is lit evenly warm with no cool fill anywhere; he is flat-lit, no modelling side to side |
| 4 People | PASS | lit, not a silhouette; face, moustache, vest and tie read at game distance |
| 5 One hand | PASS | his palette sits in the room's; the cream shirt is the brightest note but not out of the hand |

**Verdict: FAIL**

1. **(580 290 120 310) The pose.** Arms hang out from the sides in a mannequin A-pose, shoulders
   square and wide, weight dead even on both legs. The authority's and style 14's men have a
   weight shift, dropped shoulders and hands doing something. Cause: **shape** (the rest pose).
   Fix: give him an idle (weight on one leg, arms closer, a thumb in the belt or hand near the gun).
2. **(580 440 125 50) The hands**: fingers splayed and hooked, reading as claws at game distance.
   Cause: **shape** (finger rest pose). Fix: a relaxed half-curled hand pose.
3. **(0 0 1280 720) No cool fill.** Everything is amber; he has no cool side, so his body reads
   flat. The authority puts blue night on the far side of every lit form. Cause: **light**. Fix: a
   weak blue fill from the windows/doors side so his shadow side goes cool.
   Also: the boots (585 535 100 65) are a saturated cherry red, louder than anything in the
   authority (whose boots and leather are brown); **paint**, pull them toward brown.

## 4_across_street_golden.jpg (across the street, golden hour)

| Trait | Result | Deciding region |
|---|---|---|
| 1 Shapes | FAIL | same stiff A-pose and claw hands (578 490 125 45) |
| 2 Painted surface | PASS | buildings, sky and ground painted; his clothes read as painted masses |
| 3 Light | FAIL | the sun is behind him (shadows fall toward the camera), his front is in brown shade with no warm bounce or cool sky fill; face luma 42, the darkest of the set |
| 4 People | FAIL | face (625 355 40 40) dark and muddy; at game distance he is close to a dark cut-out against the bright ground |
| 5 One hand | PASS | marginal: his dark, saturated red vest and boots are a touch more "rendered" than the painted fronts behind him |

**Verdict: FAIL**

1. **(580 335 130 320) He is near silhouette.** The street is lit gold, he faces the camera in
   shadow; the face, shirt and trousers drop to dark browns. Style 14 has the man in the same light
   with a warm-lit face and a gold rim. Cause: **light**. Fix: a sky fill (cool, from above) and
   ground bounce (warm, from below) strong enough that his shade side reads at ~60-70 luma, or turn
   the shot so the sun rakes across him.
2. **(578 490 125 45) Claw hands and the A-pose**, as render 3; more visible against the bright
   ground. Cause: **shape**. Fix: the idle pose and relaxed hands.
3. **(585 590 90 70) Cherry-red boots and a crimson vest** read as the loudest colour in the
   frame, louder than the red SALOON sign. Style 14's man is browns with a dark waistcoat. Cause:
   **paint**. Fix: shift the boots to tan/brown leather and the vest toward oxblood-brown.

## 5_plain_front.jpg (plain grey studio light, full figure)

| Trait | Result | Deciding region |
|---|---|---|
| 1 Shapes | PASS | proportions credible (about 7.5 heads), clear masses, hat brim and boots solid |
| 2 Painted surface | PASS | vest in squared painted patches that follow the cloth (the authority's coat paint), trousers in angular dark planes |
| 3 Light | N/A | neutral studio light by design |
| 4 People | PASS | face modelled, moustache painted; skin a little darker and muddier than his portrait at this size |
| 5 One hand | PASS | vest, trousers, boots and face all the same hand; boots slightly smoother |

**Verdict: PASS** (the applicable traits)

1. **(40 215 80 30) Stray hair wisps** stick out beside the ears onto the shoulders as thin curly
   strands. Cause: **shape** (hair cards). Fix: trim or merge into the side-hair mass.
2. **(50 140 70 75) The face reads dark brown** under neutral light (luma 72), darker and less tan
   than the portrait's lit face. Cause: **paint**. Fix: lift the face's mid tones a step.
3. **(0 230 160 170) Arms cropped by the frame**: the sleeves can't be judged here, and they are
   the weak part in the saloon shots. Fix: widen the plain front shot to show the arms.

## 6_plain_head_three_quarter.jpg (plain light, head close)

| Trait | Result | Deciding region |
|---|---|---|
| 1 Shapes | FAIL | the hair behind the ear (120 190 140 140): ragged see-through tufts with a straight hard edge where it meets the hat |
| 2 Painted surface | FAIL | the shirt shoulder (0 360 130 140): cream with tan camouflage mottle, beside a face of clean angular planes |
| 3 Light | N/A | neutral studio light by design |
| 4 People | PASS | the best face of the set: planes of brow, cheek and jaw, warm skin, a thick painted moustache, grey sides; reads as the portrait man |
| 5 One hand | PASS | marginal: the hat's broad smooth planes are plainer than the face's paint |

**Verdict: FAIL**

1. **(120 190 140 140) The back hair** breaks up into separate jagged grey cards with gaps, cut by
   a hard line under the brim. The authority and the portrait paint it as one dark mass with a few
   grey strokes. Cause: **shape** (hair cards / hat clipping). Fix: one solid hair shell under the
   hat, painted with grey strokes.
2. **(0 360 130 140) Shirt mottle** on the shoulder: soft tan blobs on cream that ignore the
   form, the same fault as the saloon sleeves. Cause: **paint**. Fix: repaint the shirt in fold
   planes.
3. **(40 0 430 260) The hat** is large smooth planes with little paint in them (the band's gold
   squares are good). The portrait's hat has felt painted in squared tones. Cause: **paint**. Fix:
   add squared tonal patches following the crown and brim curvature.

---

## Overall

Close up he is the authority's kind of man: in renders 1, 2 and 6 the face is modelled in
angular painted planes, with warm skin, a thick painted moustache and grey sides under a
broad-brimmed hat. It is clearly the bold cowboy of his style portrait (the brow, the moustache's
weight and droop, the jaw), and his face is the best-painted thing in every frame. What lets him
down close up is everything below the collar. The shirt is smooth cream with soft camouflage
blotches (the sleeves in 1 and 2, the shoulder in 6), the mug hand is a fused mitt, and the skin
runs hotter and redder than the authority's tan. At game distance (3 and 4) he reads as a
person and not a silhouette in the saloon. But the stiff A-pose and claw hands make him a
mannequin. In the golden street (4) the sun behind him leaves his front in dark brown shade: he
is the darkest he gets (face luma 42) and close to a cut-out against the bright ground, unlike
style 14's warmly lit man. The crimson vest and cherry boots are louder than anything the
authority uses. Nowhere is he pitch black, but render 4 needs fill. The plain front (5) passes;
the vest's squared paint there is exactly the authority's coat paint.

**Top three problems overall:** (1) the shirt: sleeves and shoulders in camouflage mottle, not
fold planes, and too bright under lamplight (paint); (2) the pose and hands: an A-pose and claw
or mitt hands in every shot that shows them (shape); (3) the light on him outdoors: backlit with
no fill at golden hour, near silhouette (light). Close behind: overheated red skin, red boots and
vest, and ragged hair cards.
