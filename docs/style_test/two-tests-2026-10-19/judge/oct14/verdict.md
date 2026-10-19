# Judge's verdict: oct14 (the bold cowboy, six renders)

Judged by eye against `docs/concept/judge/RUBRIC.md`. The authority is `10_authority_saloon_man.jpg`,
with style pictures 05, 08, 09, 11, 12, 13 and 14 (the man outdoors). His likeness is checked against
`docs/concept/style/portrait-cowboy-front.png`. The judging is about **the man**. The room and street
count only where they affect how he fits the world. Boxes are `x y w h` in each image's own pixels.

| Render | Shapes | Painted surface | Light | People | One hand | Verdict |
|---|---|---|---|---|---|---|
| 1 card table, close | FAIL | FAIL | PASS (borderline) | FAIL | FAIL | **FAIL** |
| 2 card table, wider | PASS | FAIL | PASS (borderline) | FAIL | FAIL | **FAIL** |
| 3 across the saloon, night | FAIL | FAIL | FAIL | FAIL | FAIL | **FAIL** |
| 4 across the street, golden | FAIL | FAIL | FAIL | FAIL | FAIL | **FAIL** |
| 5 plain front, full figure | FAIL | FAIL | N/A (studio grey) | FAIL | FAIL | **FAIL** |
| 6 plain head, three-quarter | FAIL | FAIL | N/A (studio grey) | FAIL | FAIL | **FAIL** |

**The good part, said up front:** in every close view the **face** is the authority's kind of face.
It is built of warm, angular painted planes on the brow, cheekbone and nose, the moustache is thick,
dark and painted, and the temples are grey. It is clearly the man in the style portrait. What fails
him is everything around the face: the coat and vest paint, the neck and collar, the hair edges,
the hat, the pose and how the clothes take light.

---

## 1. 1_card_table_close.jpg: FAIL

- **Shapes FAIL:** the coat reads as a lumpy heap with no shoulders, lapels or arm under it. The
  neck breaks into loose orange fragments. The hand on the mug is a few blocky low-poly fingers.
- **Painted surface FAIL:** the coat is covered in random brown squares (camouflage mottle) that
  don't follow any fold, and they sit beside a face painted in far finer, form-following planes.
- **Light PASS (borderline):** a warm lamp key from the left and behind, and his darks can be read.
  A white specular hot spot sits on his cheek, and his skin has no cool fill (the authority's face
  has a cooler shadow side).
- **People FAIL**, **One hand FAIL**: the coat and face look like two hands. The background men's
  faces are smooth and unpainted.

Three biggest problems:
1. **Coat mottle.** Box `230 400 730 320`. The authority's coat also has a bit of square to it, but
   its squares run along the folds, the lapel and the sleeve creases. Here they are random noise at a
   much coarser size than the face, so the coat looks like camouflage and not like cloth. Cause:
   **paint** (and **shape**: there are no fold forms for the paint to follow). Fix: repaint the coat so
   its squares follow its folds at the face's square size, with clear lapels and a sleeve seam.
2. **Torn neck and collar.** Box `545 400 140 110`. Ragged orange skin shards hang between the jaw and
   the coat, and there is no white shirt collar or black tie. The authority's white collar and dark tie
   are the brightest shape under his face. Cause: **shape**. Fix: give him a closed neck going into a
   real shirt collar band and tie, and make the white collar visible inside the lapels.
3. **Specular hot spot on the cheek.** Box `670 325 35 35`. A pure-white glint sits on the cheekbone
   under the eye and reads as wet plastic. The authority's skin is matte paint. Cause: **light** (the
   skin's specular). Fix: cut the skin's specular or roughness so lamps give only a warm painted
   highlight, never white.

Also: the hair beside the left cheek (box `520 240 70 200`) hangs as flat dark sheets, and the hand
(box `700 620 120 100`) is too low-poly for this distance.

## 2. 2_card_table_saloon_night.jpg: FAIL

- **Shapes PASS:** at this distance the seated man in his coat has a strong, credible silhouette, and
  the mug arm reads well. The neck and hand flaws remain but are small.
- **Painted surface FAIL:** the coat's squares are the coarsest paint in the frame and don't follow
  the form.
- **Light PASS (borderline):** warm lamps and blue night through the door. But the table lamp, a hand's
  breadth from him, puts no warm light on his face's near side or under his jaw. His face is one even
  orange.
- **People FAIL**, **One hand FAIL**: the coat doesn't match the face, the room or the authority's
  coat. The background men are smooth, plastic and unpainted next to him.

Three biggest problems:
1. **Coat mottle at game distance.** Box `205 330 495 390`. This is the composition of the authority,
   and the coat is its biggest shape. The authority's coat is soft brown cloth with squared folds and
   a warm rim. This one is a chequerboard of brown squares bigger than any other paint in the frame.
   Cause: **paint**. Fix: use the face's square size on the coat and paint its folds, lapel edge and
   cuff as lighter and darker runs, not as random tiles.
2. **No white shirt and tie under the face.** Box `440 380 80 120`. The authority reads at a glance
   through the white collar, shirt V and black tie. Here the V is dark, and the neck shows orange
   shards (box `405 320 110 100`). Cause: **shape** (collar and neck) and **paint**. Fix: open the coat's
   lapels to show a lit white shirt front and a black tie, and close the neck.
3. **The lamp doesn't light him.** Box `420 240 160 140` (face) and the lamp at `870 330 100 270`. In
   the authority the lantern warms his hand, mug and face, and the shadow side stays cool. Here his
   face is one even orange, there is a white glint on the cheek (box `518 424 25 25`), and he has no
   cool side. Cause: **light**. Fix: let the table lamp light him as a near key with falloff, add a cool
   fill from the night door, and cut the skin's specular.

## 3. 3_across_saloon_night.jpg: FAIL

- **Shapes FAIL:** he stands in a stiff A-pose with straight arms held out from the body, and a chair
  is pushed into his legs.
- **Painted surface FAIL:** his shirt sleeves are flat pale tubes and his vest is a flat dark slab.
  Neither has painted folds.
- **Light FAIL:** the only light is warm, with no cool fill anywhere, and on him it is flat and has no
  direction.
- **People FAIL**, **One hand FAIL**: the face reads, and the moustache carries, but the clothes look
  unpainted next to the painted face.

Three biggest problems:
1. **Mannequin pose.** Box `588 365 110 100`. His arms hang straight and splayed like a rig's rest pose.
   The authority's men stand weighted, with bent elbows and hands at the belt or the gun. Cause:
   **shape** (the pose). Fix: give him a relaxed standing idle with arms against his sides, elbows
   bent, and weight on one leg.
2. **Flat, unpainted sleeves and vest.** Box `588 360 110 140`. The sleeves are near-white and smooth,
   and the vest is one dark brown. In picture 14 the waistcoat has buttons, edges and squared shading,
   and the shirt sleeve has folds at the elbow. Cause: **paint**. Fix: paint the sleeves' folds and the
   vest's edges, buttons and pockets, and take the sleeve white down to a warm cream that has
   shadows.
3. **Chair through the legs.** Box `640 450 80 160`. The chair stands where his shins are, so he reads
   as a cut-out pasted into the room. Cause: **shape** (placement). Fix: place him clear of the
   furniture or seat him.

## 4. 4_across_street_golden.jpg: FAIL

- **Shapes FAIL:** he has the same A-pose, and there are ragged spikes at the vest's armholes.
- **Painted surface FAIL:** the sleeves are flat, and the vest and trousers are one dark mass.
- **Light FAIL:** the low sun lights the store front behind him full on, so it also falls on his
  front, yet he is dark, nearly a silhouette.
- **People FAIL**, **One hand FAIL**: picture 14's man in the same light is warm and lit on his face,
  coat and waistcoat.

Three biggest problems:
1. **Near-silhouette in sunlight.** Box `590 345 110 315`. The street and facades are lit warm and
   bright, while his vest, trousers and boots are near-black and his face is a dim red. In picture 14
   the sun models his face and coat with warm light and gives readable shadow. Cause: **light** and
   **paint** (the clothes' albedo is too dark, or he isn't taking the sun). Fix: check that he receives
   the sun, raise the clothes' value to picture 14's level, and add a warm sun edge on the face and
   shoulders.
2. **Mannequin pose.** Box `590 395 105 140`. His arms are straight and held off the body, which reads
   as a test dummy at street distance. Cause: **shape**. Fix: the same relaxed idle as in render 3,
   with one hand near the gun belt as in picture 14.
3. **Ragged armholes and flat sleeves.** Box `600 385 95 30` and `590 400 105 120`. Jagged pale spikes
   show where the vest meets the sleeve, and the sleeves are flat grey-white. Cause: **shape** (the
   vest's edge) and **paint**. Fix: give the vest a clean armhole edge, and shade and paint the sleeves
   warm.

Also: at this distance his face is a dark red smudge (box `615 355 45 45`), and the moustache barely
separates from the skin.

## 5. 5_plain_front.jpg: FAIL

- **Shapes FAIL:** the vest is a long boxy tube down past the hips and hides the belt. The torso is
  long against the legs. The hat's brim is narrow and its crown low, unlike the wide studded hat in
  his portrait.
- **Painted surface FAIL:** the vest and trousers are random square noise with no buttons, edges or
  folds. The face is well painted.
- **Light N/A:** plain studio grey.
- **People FAIL**, **One hand FAIL**: the face is finely painted, and the clothes are coarse and
  unformed.

Three biggest problems:
1. **The vest is a featureless tube.** Box `0 240 160 240`. Picture 14's waistcoat is cut short above
   the belt, with buttons, a lapel edge and pockets, and the gun belt shows below it. Here it is a
   brown sack to the hip with mottled squares. Cause: **shape** and **paint**. Fix: cut the vest to end
   at the waist with a pointed front, add a button line and pocket welts, and show the belt and
   buckle.
2. **Ragged neck and shoulders.** Box `40 238 80 40` and the shoulder spikes at `0 250 30 40` and
   `135 250 25 40`. Orange shards ring the neck above the collar, and white shards stick out at the
   shoulders. Cause: **shape**. Fix: give him a closed neck and a clean collar band, and smooth the
   armhole edges.
3. **Hat unlike his portrait's.** Box `10 128 150 70`. It is a small, narrow-brimmed, low hat, almost a
   bowler. The portrait and the authority both have a broad brim with a dented crown (the portrait's
   has a studded band). Cause: **shape**. Fix: widen the brim, raise and pinch the crown, and paint
   the studded band.

## 6. 6_plain_head_three_quarter.jpg: FAIL

- **Shapes FAIL:** the hat brim has saw-tooth tips, the hair is a pasted plate, and the vest's
  neckline is jagged.
- **Painted surface FAIL:** the face passes (warm angular planes that follow the form, close to the
  authority), but the hair, the hat crown's square mottle and the sleeves' flat triangles do not.
- **Light N/A:** plain studio grey.
- **People FAIL**, **One hand FAIL**: the face and the rest of him look made by different hands.

Three biggest problems:
1. **Hair is a flat beige plate.** Box `115 140 150 90`, with jagged hair ends at `125 245 80 100`. Under
   the brim the side hair is a flat tan sheet with a hard edge, and below it the hair breaks into
   spikes. The authority's hair is dark, painted locks with soft edges, and the portrait's temples are
   grey. Cause: **shape** and **paint**. Fix: model the side hair as a mass that sits on the skull, and
   paint it grey-brown with lock strokes and no beige.
2. **Saw-tooth neckline and no collar.** Box `100 330 330 70`. The vest's top edge and the skin at the
   neck are zig-zag, and there is no shirt collar between neck and vest. Cause: **shape**. Fix: give the
   shirt a real collar band and the vest a clean V edge.
3. **Hat brim and crown.** Box `50 110 390 65` and the crown `125 10 240 110`. The brim's edge ends in
   spikes and is paper-thin, and the crown is random squares where the authority's hat is soft felt
   with painted light along the dent. Cause: **shape** and **paint**. Fix: give the brim a thick, rolled
   edge, and paint the crown with light along the pinch and shade under the band.

Also: the shirt shoulders (box `0 380 160 120`) are big flat low-poly facets with no painted folds.

---

## Overall

**Close up, his face is the authority's kind of painted face, and his clothes are not.** In renders 1, 2, 5 and
6 the head is the strongest thing in the frame. It has warm skin modelled in angular planes, a thick
dark painted moustache, grey at the temples and a heavy brow. It **does look like his style
portrait**. But the coat and vest are random squares coarser than the face, with no folds, so he looks
painted by two hands. The neck and collar are torn every time, with orange shards and no white
collar or tie, and the hair edges are pasted plates. A white specular glint on the cheek makes the
skin look plastic. The hat is narrower and lower than the portrait's.

**At game distance (renders 3 and 4) he does not read as the authority's man.** He reads as a
mannequin: A-pose, flat white sleeves, and a dark vest and trousers that merge. **He is too dark in
render 4**: in full golden-hour sun, with the facades behind him lit, he is close to a silhouette,
where picture 14's man in the same light is warm and modelled. He is also too dark and flat in render
3, and his face goes too uniformly orange-red at night in renders 1 and 2, with no cool side.

**Fix first:**
1. Repaint the coat, vest and trousers so the squares follow folds, at the face's square size, with
   the garment's details (lapels, buttons, edges).
2. Close the neck and give him a real white collar and tie.
3. Make sure his clothes take the key light (the sun and the table lamp) at picture 14's value, and
   put him in a natural standing pose.
