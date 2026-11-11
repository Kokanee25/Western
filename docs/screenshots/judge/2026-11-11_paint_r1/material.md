# Materials judge: 2026-11-11_paint_r1 (painted wood)

A blind judge's verdict. I read only the rubric (`docs/concept/judge/MATERIAL.md`), the six yardstick
screenshots (RDR2 street noon, street golden, saloon night; Hunt 1896 street noon, saloon night;
KCD2 street noon) and the crops in this folder. Crop boxes are `x y w h` in the named crop's pixels
(near and saloon_night crops are 1400x780, far crops 560x360).

What the yardstick does with its wood: tone changes from board to board and along each board. Dirt and
wear sit where hands, feet and water go. Edges are worn and lit arrises with real depth. Grain and
damage follow the board, and nothing is scattered evenly over the face. Most of these swatches fall
short of it in the same ways:

- Every board in a panel has one tone.
- Wear is scattered evenly over the faces instead of gathering where weather works.
- The new coats read as embossed vinyl or a flat card.
- The old coats carry decals stamped over the boards: a lace crackle pattern, black ink-stroke cracks,
  orange "pin-head" nails with drips in ruler-straight rows.

Known light fault, noted once and not graded: the sun's shadow has a saw-toothed edge under every lap
and batten (P1, P3, P4 near crops; e.g. P1_new_near `0 110 1400 30`).

---

## P1: white lead in linseed oil, on planed pine lap siding

### P1_new (near, far)
1. Real stuff: **FAIL.** An even off-white with a crisp embossed cathedral figure and no brush texture
   or sheen change. It reads as vinyl siding, not oil paint on pine. Box `700 250 600 120` (P1_new_near).
2. Age reads: PASS. A sound, even coat.
3. No tile tells: PASS.
4. Board to board: **FAIL.** Every course is the same tone and value. Box `0 0 1400 780` (P1_new_near).
5. Edges and joints: **FAIL.** Each lap is a hairline dark rule with no lit butt edge or thickness.
   Box `0 360 1400 30` (P1_new_near).
6. Holds at distance: **FAIL.** A flat card ruled with lines. Box `0 0 560 360` (P1_new_far).

Grade: **game**

### P1_few (near, far)
1. Real stuff: PASS, just. Paint with small chips and a faint check pattern.
2. Age reads: **FAIL.** The chips are spread evenly over the faces, not at the lap's lower edge,
   board ends or foot. There is no chalking or fade, and at 5 m it can't be told from new.
   Boxes `0 0 1400 780` (P1_few_near) and `0 0 560 360` (P1_few_far).
3. No tile tells: **FAIL.** The chips are grey smudge-dots stamped evenly over the boards, with no
   lifted film edge. Box `450 80 350 230` (P1_few_near).
4. Board to board: **FAIL.** One tone everywhere. Box `0 0 1400 780`.
5. Edges and joints: **FAIL.** The laps are hairline rules (as P1_new). Box `0 230 1400 30`.
6. Holds at distance: **FAIL.** It reads as the new card. Box `0 0 560 360` (P1_few_far).

Grade: **game**

### P1_old (near, far)
1. Real stuff: **FAIL.** Four decals over a near-white coat:
   - a uniform grey lace "crackle" pattern;
   - peels as dark blotches with smeared edges and no film edge;
   - cracks as black ink squiggles;
   - nails as orange pin-heads with drips.

   Box `950 0 350 230` (P1_old_near).
2. Age reads: **FAIL.** It is clearly older than few, but nothing has failed in strips to primer or
   silver bare wood. The damage is a uniform field, with no extra failure at the foot or board ends
   and no dust low. Box `0 0 1400 780`.
3. No tile tells: **FAIL.** The crackle lace and the evenly spaced blotches are a pattern stamped over
   the boards. Boxes `950 0 350 230`, and the nails in ruler-straight columns at `540 50 40 700`.
4. Board to board: **FAIL.** One tone. Box `0 0 1400 780`.
5. Edges and joints: **FAIL.** The laps are still hairlines. Some blotches gather along them, which
   helps a little. Box `0 480 1400 30`.
6. Holds at distance: **FAIL.** It becomes speckle noise with black squiggle strokes. Box
   `0 30 560 300` (P1_old_far).

Grade: **fake**

**P1 set.** Best age: **new**. The one change that would help most: make the paint fail where water
sits (each lap's lower edge, board ends, the foot), in strips down to silver-grey wood with a sharp,
lifted film edge. Remove the even scatter, the lace crackle and the ink cracks, and give each course
its own tone.

---

## P2: chrome green trim paint, on planed pine boards

### P2_new (near, far)
1. Real stuff: PASS, just. A deep green coat with grain relief and a row of painted-over nail heads.
   It is very nearly black.
2. Age reads: PASS. An even, sound coat.
3. No tile tells: PASS.
4. Board to board: **FAIL.** All boards are identical in tone. Box `0 0 1400 780` (P2_new_near).
5. Edges and joints: PASS. The seams read as dark gaps.
6. Holds at distance: **FAIL.** A flat olive card with faint rules. Box `0 20 560 340` (P2_new_far).

Grade: **game**

### P2_few (near, far)
1. Real stuff: PASS. Green paint chipping to a pale primer.
2. Age reads: **FAIL.** The chips are scattered mid-face, not at the arrises or board ends. There is
   little chalking and no dust low. Box `0 0 1400 780`.
3. No tile tells: **FAIL.**
   - The chips are pale confetti dots, evenly spread. Box `380 60 200 400`.
   - Two ruler-straight rows of rust dots run across every board. Box `0 160 1400 30`.
4. Board to board: **FAIL.** One tone. Box `0 0 1400 780`.
5. Edges and joints: PASS.
6. Holds at distance: PASS. The chips read at 5 m without shimmer.

Grade: **game**

### P2_old (near, far)
1. Real stuff: PASS. Chalked green, grain raised, peels with a lifted light rim, rust streaks under
   the nails.
2. Age reads: **FAIL** (narrowly). It is clearly older than few, but it has failed only in small
   flakes, never in strips to grey wood, and there is no dirt low. Box `0 0 1400 780`.
3. No tile tells: **FAIL.** The cracks are black ink strokes drawn on, not splits in a film. Boxes
   `410 520 100 250` and `720 270 100 300` (P2_old_near).
4. Board to board: **FAIL.** Only slight chalk differences. The boards read as one sheet. Box
   `0 0 1400 780`.
5. Edges and joints: PASS. The seams are deep dark gaps.
6. Holds at distance: **FAIL.** The ink cracks become black streaks on every board. Box
   `0 30 560 200` (P2_old_far).

Grade: **game**

**P2 set.** Best age: **old**. The one change that would help most: replace the ink-line cracks with
splits in the film that show lighter wood or primer, and wear the arrises and board feet first.
Also lift new off near-black.

---

## P3: ox-blood red (iron oxide in linseed oil), on rough-sawn board and batten

### P3_new (near, far)
1. Real stuff: PASS. Oil paint over rough-sawn texture reads convincingly.
2. Age reads: PASS. An even, sound coat.
3. No tile tells: **FAIL.**
   - A pale hairline runs the full height of a board, like a drawn line. Box `640 0 60 780`
     (P3_new_near).
   - An embossed blob outline sits on the left board. Box `0 500 120 280`.
4. Board to board: PASS, just. The texture differs between the left boards and the right.
5. Edges and joints: PASS. The battens stand proud with shadow (the saw-tooth is the known fault).
6. Holds at distance: **FAIL.** A flat orange card, with the battens reduced to lines. Box
   `0 0 560 360` (P3_new_far).

Grade: **game**

### P3_few (near, far)
1. Real stuff: PASS. Faded, chalky barn red over rough-sawn boards, with small chips.
2. Age reads: PASS. Clearly faded from new and believable. The chips are still evenly spread, and
   there is no dust or splash at the foot.
3. No tile tells: PASS. The chips are small and few.
4. Board to board: **FAIL.** The boards share one tone. Only a horizontal wash varies it. Box
   `400 0 600 780` (P3_few_near).
5. Edges and joints: PASS.
6. Holds at distance: PASS.

Grade: **game** (the best swatch of the round; near the yardstick if its boards varied and its wear
sat at the battens and foot)

### P3_old (near, far)
1. Real stuff: PASS, just. Faded to pink, chipping to a blue-grey.
2. Age reads: **FAIL.** Older than few, but by more of the same dots. There are no strips to grey wood
   and no wear at the batten edges or foot. Box `0 0 1400 780`.
3. No tile tells: **FAIL.** Blue-grey blotches with light rims are stamped evenly across every board.
   Box `900 200 450 400` (P3_old_near).
4. Board to board: **FAIL.** One tone. Box `0 0 1400 780`.
5. Edges and joints: PASS.
6. Holds at distance: **FAIL.** Even brown speckle. Box `0 20 560 340` (P3_old_far).

Grade: **game**

**P3 set.** Best age: **few**. The one change that would help most: concentrate wear and dirt on the
batten edges and the foot (splash, dust, fade where the sun works), give each board its own tone, and
remove the pale hairline from new.

---

## P4: buff (ochre and white lead), on planed pine drop siding

### P4_new (near, far)
1. Real stuff: **FAIL.** A crisp embossed figure of the same strength on every board under one flat
   buff. It reads as printed or embossed vinyl, not paint on pine. Box `0 340 1400 160`
   (P4_new_near).
2. Age reads: PASS. An even coat.
3. No tile tells: PASS. The faint nail spots at the studs are plausible.
4. Board to board: **FAIL.** One tone everywhere. Box `0 0 1400 780`.
5. Edges and joints: **FAIL.** The drop-siding joints are hairline rules with no rabbet or cove
   profile. Box `0 320 1400 40`.
6. Holds at distance: **FAIL.** A flat card. Box `0 0 560 360` (P4_new_far).

Grade: **game**

### P4_few (near, far)
1. Real stuff: PASS, just.
2. Age reads: **FAIL.** Scattered blue-grey chips mid-face, no fade or chalk, close to new at 5 m.
   Box `0 0 1400 780`.
3. No tile tells: **FAIL.**
   - The chips are dot-like and evenly spread. Box `850 170 400 120` (P4_few_near).
   - At 5 m the nails read as vertical dotted lines. Box `40 20 300 320` (P4_few_far).
4. Board to board: **FAIL.** One tone. Box `0 0 1400 780`.
5. Edges and joints: PASS. The joints read as shadowed gaps.
6. Holds at distance: **FAIL.** The dotted nail columns. Box `40 20 300 320` (P4_few_far).

Grade: **game**

### P4_old (near, far)
1. Real stuff: **FAIL.** Blue-grey blotches (cold, not silver wood), the same lace crackle, black ink
   cracks, and orange pin-head nails with drips in a grid. Box `950 300 450 280` (P4_old_near).
2. Age reads: **FAIL.** Different from few, but not believable failure: no strips, and the damage is
   uniform. Box `0 0 1400 780`.
3. No tile tells: **FAIL.** Stamped blotches, crackle and nail grid. Boxes `950 300 450 280`
   and `380 140 60 600`.
4. Board to board: **FAIL.** One tone. Box `0 0 1400 780`.
5. Edges and joints: PASS. Deep dark gaps, with peel gathered along them.
6. Holds at distance: **FAIL.** Black squiggles and speckle. Box `0 30 560 300` (P4_old_far).

Grade: **fake**

**P4 set.** Best age: **few**. The one change that would help most: on new, flatten the embossed
figure to the faint raised grain a paint film leaves, and add brush texture and tone per board. On
old, replace the blue-grey blotches, crackle and ink cracks with strips failed to silver wood at the
joints and ends.

---

## P5: pale cream interior paint, on narrow planed pine beadboard

### P5_new (near, far, saloon_night)
1. Real stuff: PASS. Painted beadboard with readable beads.
   - Under lamplight the grain's colour figure shows through the coat as if it were varnish. Box
     `440 0 120 560` (P5_new_saloon_night).
   - Some planed boards carry a lumpy, stucco-like relief. Box `460 0 100 560` (P5_new_near).
2. Age reads: PASS. A clean coat.
3. No tile tells: PASS.
4. Board to board: **FAIL.** The boards share one tone, and the only difference is random noise:
   some boards stucco-rough, others smooth. Box `460 0 100 560` (P5_new_near).
5. Edges and joints: PASS. The beads and grooves read as relief.
6. Holds at distance: PASS. Clean beadboard at 5 m.

Grade: **game**

### P5_few (near, far, saloon_night)
1. Real stuff: PASS. The figure still shows through under lamplight. Box `60 500 150 280`
   (P5_few_saloon_night).
2. Age reads: **FAIL.** Indistinguishable from new: no yellowing, no rubbing where hands go, no
   scuffs low. Compare P5_few_near `0 0 1400 780` with P5_new_near.
3. No tile tells: PASS.
4. Board to board: **FAIL.** As new. Box `1100 0 200 780` (P5_few_near).
5. Edges and joints: PASS.
6. Holds at distance: PASS.

Grade: **game**

### P5_old (near, far, saloon_night)
1. Real stuff: PASS. Grime sits in the bead grooves.
2. Age reads: **FAIL.** Only a few brown specks and slight groove grime separate it from new. It
   is not yellowed, not rubbed and not scuffed low. Box `780 330 100 150` (P5_old_near).
3. No tile tells: **FAIL** (minor). Rust-brown specks along the beads read as dots. At 5 m they show
   as dashes. Box `780 330 100 150` (P5_old_near) and `100 60 320 120` (P5_old_far).
4. Board to board: **FAIL.** The stucco-rough boards against smooth ones again. Box `880 0 120 780`.
5. Edges and joints: PASS.
6. Holds at distance: PASS.

Grade: **game**

**P5 set.** Best age: **new**. The one change that would help most: make the ages read indoors.
Yellow the coat with age, and add a rubbed, darker band where hands and chair-backs go and scuffs and
dirt at the foot. Drop the stucco relief on planed boards.

---

## Summary

| Swatch | new | few | old | Best age |
|---|---|---|---|---|
| P1 white lead, lap siding | game | game | **fake** | new |
| P2 chrome green, boards | game | game | game | old |
| P3 ox-blood, board and batten | game | game | game | few |
| P4 buff, drop siding | game | game | **fake** | few |
| P5 cream interior, beadboard | game | game | game | new |

None reaches "near the yardstick". The closest is P3_few, held back by boards of one tone and wear
spread evenly.
