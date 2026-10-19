# Judge: test1 (2026-10-19), the bold cowboy in six views

Judged by eye against `docs/concept/judge/RUBRIC.md`, the authority `10_authority_saloon_man.jpg`,
the man outdoors `14_style_man_saloon_front.jpg`, and his style portrait
`docs/concept/style/portrait-cowboy-front.png`. Focused on the man; the room and street only as they
bear on him fitting the world. Boxes are `x y w h` in each render's own pixels.

Luminance spot-checks (0-255, grey): render 4: his face 57, vest 44, trousers 28, against the store
wall 86 and the street 81. Render 3: face 66, floor 103. Render 1: face 74, shirt 118.

## 1_card_table_close.jpg (1280x720)

| Trait | Result | Region that decides it |
|---|---|---|
| 1 Shapes | FAIL | the hand on the mug is four square blocks; the neck breaks under the chin |
| 2 Painted surface | PASS | the face is cut into angular planes that follow the brow, cheek and nose, like the authority's man; the vest's paint follows its folds |
| 3 Light | PASS | warm lamp key from the room, cool moonlit doorway behind him, darks under the brim readable |
| 4 People | FAIL | the face and moustache are right, but the hand and neck aren't painted flesh, and the skin is pushed to one saturated orange |
| 5 One hand | FAIL | the extras behind him are smooth, nearly featureless mannequins beside his squared, painted face |

**Verdict: FAIL**

1. **(740 620 120 100) The hand on the mug** is a stack of four flat beige boxes for fingers with
   an orange lump of a palm, not gripping the handle. The authority's hand round the mug is a
   modelled, warm painted hand. Cause: **shape** (a low-poly or placeholder hand) and **paint**
   (no skin texture on it). Fix: give him a skinned, textured hand with the fingers closed round
   the mug, painted with the face's skin.
2. **(560 430 140 60) The neck** shows a grey, ragged band between the chin and the collar, as
   if the head is a separate piece floating over the shirt. The authority's man has a continuous
   throat into his collar. Cause: **shape** (a head/body seam or the collar cut too low). Fix:
   close the seam and seat the collar up against the neck.
3. **(560 260 170 170) The face** is one saturated orange-red from brow to chin, with a pure
   white specular chip on the cheek at (675 325 30 25). The authority's skin is warm but has
   tan, ruddy and cool-shadow shades in it, and no hot glint. Cause: **light** (specular too high,
   lamp colour too saturated on skin). Fix: cut the skin's specular to near zero and pull the
   lamp's saturation on skin down so the painted shades show through.

## 2_card_table_saloon_night.jpg (1280x720)

| Trait | Result | Region that decides it |
|---|---|---|
| 1 Shapes | FAIL | the neck gap and the lump of a hand at the mug |
| 2 Painted surface | FAIL | the shirt sleeve is cream and tan camouflage mottle that ignores the arm's folds |
| 3 Light | PASS | table lamp as a named warm key, moonlit door as cool fill, darks readable |
| 4 People | FAIL | the sleeve isn't painted in folds; the hand and neck aren't modelled |
| 5 One hand | FAIL | his blotchy sleeve beside the smooth table and the bottles' clean, crisp shading; smooth extras |

**Verdict: FAIL**

1. **(240 470 300 210) The right shirt sleeve** is covered in large cream, tan and white blotches
   that read as camouflage, not cloth. The authority's sleeves and coat are painted in patches
   that run along the folds. Cause: **paint** (the shirt texture's patches don't follow the
   form). Fix: repaint the sleeve with fold-following strokes (darker in the creases at the
   elbow and the inside of the arm), fewer and larger patches.
2. **(435 355 90 45) The neck under the chin** is again a grey, broken ring between head and
   collar. Cause: **shape**. Fix: as render 1.
3. **(500 470 90 85) The hand at the mug** is an orange lump against the mug's side, not a hand
   holding it, with a pink cuff blurring into it. Cause: **shape** (hand pose/model). Fix: close
   the fingers round the handle and give the hand its painted skin.

## 3_across_saloon_night.jpg (1280x720)

| Trait | Result | Region that decides it |
|---|---|---|
| 1 Shapes | FAIL | stiff A-pose, a chair through his legs, splayed claw fingers |
| 2 Painted surface | PASS | at this distance his vest, shirt and trousers read as painted; the floor has a photographic grain and red spots but that's the room |
| 3 Light | FAIL | one warm orange everywhere, no cool fill on him or in the room; he's lit flat from the front |
| 4 People | PASS | lit, not a silhouette; hat, moustache, vest and tie all read at game distance |
| 5 One hand | PASS | his paint sits with the room's at this distance |

**Verdict: FAIL**

1. **(610 445 110 150) The chair** stands through his legs: its back post runs up his crotch.
   Cause: **shape** (placement, not the model). Fix: stand him clear of the chair or seat him.
2. **(585 340 115 140) The arms** hang straight in an A-pose with the fingers spread like claws
   (pale points at 585 455 and 680 455). The authority's men stand with weight and bent arms.
   Cause: **shape** (rest pose, no idle). Fix: put an idle on him (hands relaxed, curled
   fingers, slight bend at the elbow, weight on one leg).
3. **(605 535 70 55) The boots** are a bright red-orange that reads as rubber; the authority's
   boots are dark, worn brown leather. Cause: **paint** (boot texture too saturated) with
   **light** (warm lamps pushing it). Fix: darken and desaturate the boots toward a scuffed brown.

## 4_across_street_golden.jpg (1280x720)

| Trait | Result | Region that decides it |
|---|---|---|
| 1 Shapes | FAIL | the same stiff A-pose and claw hands; legs look long for the body |
| 2 Painted surface | PASS | on him: vest and shirt read as painted at this distance |
| 3 Light | FAIL | the facades and street are in warm low sun, he is in murky shade (face 57, trousers 28 against the wall 86) |
| 4 People | FAIL | not a silhouette, but his face under the brim is muddy and he isn't lit by the sun that lights the street, unlike the man in picture 14 |
| 5 One hand | FAIL | the buildings and their lettering are clean, crisp 3D; the man is squared paint; the ground is semi-photographic |

**Verdict: FAIL**

1. **(600 345 100 310) He's darker than the world behind him.** The sun warms the store and the
   street, but he reads as if standing in shade: sleeves grey, trousers almost black, face dim
   under the hat. In picture 14 the sun rakes across the man's face and coat and he's the
   brightest, warmest thing in the frame. Cause: **light** (no sun on him, or the sun behind
   him with no bounce from the ground). Fix: check he receives the sun (shadow casting/receiving
   and the angle), and add warm ground bounce to the fill so his front isn't dead.
2. **(585 400 115 140) Arms and hands**: the A-pose and splayed fingers as in render 3; at this
   distance it reads as a mannequin placed in the street. Cause: **shape** (rest pose). Fix: an
   idle stance (thumbs at the belt, as in picture 14, would suit him).
3. **(0 0 1280 480) The street around him** is a different hand: crisp clean lettering and
   boards against his squared paint. This is the world's problem more than his, but it stops him
   sitting in the frame. Cause: **paint**. Fix: none for the character; flag to the world pass.

## 5_plain_front.jpg (160x900, plain grey light)

| Trait | Result | Region that decides it |
|---|---|---|
| 1 Shapes | FAIL | a straight cut across the neck under the chin; oversized boots; legs long |
| 2 Painted surface | FAIL | coarse checker squares on the hat crown beside the finely painted face |
| 3 Light | N/A | studio light |
| 4 People | PASS | the face is modelled in painted planes, warm skin, a heavy painted moustache; vest painted in folds |
| 5 One hand | FAIL | the hat's coarse squares and the boots' smooth orange leather against the face's fine paint |

**Verdict: FAIL**

1. **(40 225 80 20) The neck** ends in a hard horizontal line under the jaw, with grey showing
   at both sides between the jaw and the collar. Cause: **shape**. Fix: as render 1.
2. **(35 125 80 50) The hat crown** is painted in big flat checker squares, far coarser than the
   squares in his face. The rubric calls coarse squares beside smooth work wrong; the authority's
   hat is broad smooth patches with the light across it. Cause: **paint**. Fix: repaint the hat
   at the face's density, with the patches following the crown's dents and the brim's curve.
3. **(5 740 150 115) The boots** are large, smooth and a bright tan-orange, the least worn thing on
   him. Cause: **paint** (and a little **shape**: they look a size big). Fix: darker, scuffed brown
   with painted creases at the ankle; check their scale.

## 6_plain_head_three_quarter.jpg (500x500, plain grey light)

| Trait | Result | Region that decides it |
|---|---|---|
| 1 Shapes | FAIL | the neck cut; a flat plane under the brim behind the head |
| 2 Painted surface | FAIL | the hat's checkerboard squares against the face's fine planes; shirt shoulder mottle |
| 3 Light | N/A | studio light |
| 4 People | FAIL | the face itself is the best of the set (planes, eyes, moustache, grey temples), but the hair at the back is stringy grey strands, not painted masses |
| 5 One hand | FAIL | hat, face, hair and shirt each look painted at a different square size |

**Verdict: FAIL**

1. **(130 320 230 30) The neck** is cut off in a ruler-straight horizontal line, stepped at the
   back, with the collar pasted under it. Cause: **shape**. Fix: as render 1.
2. **(115 10 260 140) The hat crown and brim** are a checkerboard of squares several times the
   size of the face's planes. Cause: **paint**. Fix: as render 5.
3. **(120 160 170 170) Behind the ear**: a flat grey-brown plane under the brim reads as a gap
   between hat and head, and the hair below it is ragged, see-through grey strands. The
   authority's hair is a few painted locks under the brim. Cause: **shape** (hair cards, the
   hat's inside) and **paint**. Fix: close the hat onto the head and paint the hair as solid
   locks with a few darker strokes, not separate strands.

## Overall

**Close up, the face is the authority's kind of painted man.** In renders 1, 2, 5 and 6 his face is
cut into warm planes that follow the brow, cheekbone and nose, with a heavy painted moustache and
grey at the temples, and it holds up beside the man at the authority's card table. **Everything
around the face lets him down:** the neck is cut or gapped in four of six views, the hands are
blocks (at the table) or splayed claws (standing), the hat is painted in squares far coarser than
the face, and the shirt sleeve is camouflage mottle rather than cloth in folds. At game distance
(renders 3 and 4) the costume reads (hat, moustache, red vest, black tie) but the stiff A-pose and
red-orange boots make him a mannequin. **He is not a silhouette anywhere.** He is darkest in the
golden street (render 4: face 57, trousers 28 against a wall at 86), where the sun lights the
buildings but not him, the opposite of picture 14. In the saloon at night he is, if anything, too
orange: the lamps push his skin to one saturated shade, with a white specular chip on his cheek.
**Likeness to his style portrait is good:** the thick dark moustache, heavy brows, deep-set eyes,
grey at the temples and studded hatband are all there. His face is a little narrower than the
portrait's broad, heavy one, and his hair hangs in long stringy locks over the collar where the
portrait has short grey tufts.

**Top three problems overall**
1. **The neck seam** (renders 1, 2, 5, 6): a hard cut or grey gap between jaw and collar. Shape.
2. **The hands and pose**: block fingers at the mug (1, 2); A-pose with claw fingers standing (3, 4). Shape.
3. **Paint at mixed densities**: the hat in coarse checker squares and the sleeve in camouflage
   mottle beside the finely painted face; the boots smooth bright orange. Paint.
   (Next after these: no sun on him in the golden street, render 4. Light.)
