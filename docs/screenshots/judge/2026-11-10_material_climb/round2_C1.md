# Materials judge: C1 (planed pine lap siding), sets P and Q

Blind judgment against the yardstick (RDR2 street/saloon, Hunt 1896, KCD2: their wood only).
Crop boxes are `x y w h` in the named crop. Near crops are 1400x780, far crops 560x360.

Noted once, not counted against anything: the sun's shadow under several laps is saw-toothed
(e.g. `C1_new_P_near` 0 236 1400 24; `C1_few_Q_near` 0 236 1400 20; `C1_old_Q_near` 0 372 1400 20).
That is the light's fault. Where a lap shows *only* as that broken shadow and nothing else, the
missing lap itself is counted (check 5).

P and Q differ almost only in how the laps are drawn. In `few` and `old`, set Q has a clear
shadowed step at every lap and P has nearly none; in `new` it is the other way round (P has the
lap lines, Q has lost most of them).

---

## C1_new

### Set P
1. Real stuff: **FAIL**. The figure is a huge, high-contrast cathedral swirl with growth bands
   2-3 cm wide on a ~15 cm board: it reads as rotary-cut plywood or an ash-print laminate, not
   planed pine siding. No knots, no pitch, no saw or plane marks. `C1_new_P_near` 0 480 800 125;
   at 5 m it is a laminate floor: `C1_new_P_far` 0 150 560 80.
2. Age reads: **PASS**. Clearly new against the other two (clean, yellow, unweathered). Almost
   too clean: not a speck of dust or a dirt line anywhere.
3. No tile tells: **PASS**. No repeat, seam, block or weave seen at 1 m.
4. Board to board: **FAIL**. The figure flows from one board into the next across the lap, as if
   the wall were one printed sheet scored into strips; tone is identical board to board.
   `C1_new_P_near` 0 60 1400 110 (boards 1-2), 0 440 1400 90 (boards 4-5).
5. Edges and joints: **PASS** (weak). Laps are thin dark lines with a little shadow; they read
   as joints, but hairline, with no thickness of board edge or worn arris.
6. Holds at distance: **PASS** (weak). The laps survive at 5 m as fine lines; no shimmer; the
   character it keeps is the wrong one (laminate).

**Grade: game** (low end: two clear tells, both big ones).

### Set Q
1. Real stuff: **FAIL**. As P. `C1_new_Q_near` 0 480 800 125.
2. Age reads: **PASS**. As P.
3. No tile tells: **PASS**.
4. Board to board: **FAIL**. As P, and worse because the joints no longer interrupt the figure.
   `C1_new_Q_near` 0 60 1400 110.
5. Edges and joints: **FAIL**. Most laps have gone: where P has a line, Q has a soft smudge or
   nothing, and the only clear lap is the saw-toothed one. `C1_new_Q_near` 0 85 1400 30,
   0 360 1400 30, 0 590 1400 25.
6. Holds at distance: **FAIL**. At 5 m it is one flat printed card of wood grain with no boards.
   `C1_new_Q_far` 0 0 560 360.

**Grade: fake.**

**Better set: P, by a full grade** (game vs fake): P has laps, Q has a sheet.

**The one change that would move C1_new up most:** replace the figure. Planed pine at this scale
should be fine, quiet, mostly straight grain with tight rings, a few small knots and a different
piece of figure on every board (each board its own offset, so nothing runs across a lap). The
present swirl is what makes it read as a print.

---

## C1_few

### Set P
1. Real stuff: **PASS** (weak). Fine checked, weathered softwood grain with small knots is
   believable. Marked down within the pass by violet/blue blotches no sun-greyed wood has:
   `C1_few_P_near` 540 260 120 60, 1050 480 110 60.
2. Age reads: **FAIL**. At 1 m it is the same dark grey-brown, fully weathered board as `old`
   (the only difference I can find is `old`'s rust nail heads). "A few years" in the desert
   should still show yellow-tan under silvering, not look decades old. At 5 m the lower wall
   is *more* weathered-looking than `old` at 5 m, and the top three boards switch to fresh
   orange pine along a ruler line: `C1_few_P_far` 0 55 560 50.
3. No tile tells: **PASS**. No repeat or seam at 1 m. (The colour blotches are soft mush but
   not a tile tell.)
4. Board to board: **FAIL**. No board differs from its neighbour in tone, figure or width; the
   weathering lies over the wall as one continuous sheet. `C1_few_P_near` 0 380 1400 300.
5. Edges and joints: **FAIL**. The laps have nearly gone: the wall reads as one flat plank
   surface, with the joints showing only as the broken saw-tooth shadow or a faint smear.
   `C1_few_P_near` 0 85 1400 30, 0 470 1400 30, 0 570 1400 30.
6. Holds at distance: **FAIL**. Below the orange band it is a flat brown card with faint
   streaks; no lap siding. `C1_few_P_far` 0 100 560 260.

**Grade: fake.**

### Set Q
1. Real stuff: **PASS** (weak). As P; same violet blotches. `C1_few_Q_near` 540 260 120 60.
2. Age reads: **FAIL**. As P. `C1_few_Q_far` 0 55 560 50 (hard line from fresh to weathered).
3. No tile tells: **PASS**.
4. Board to board: **FAIL**. Every board the same tone and the same wear; the laps cut one
   continuous picture into strips. `C1_few_Q_near` 0 100 1400 480.
5. Edges and joints: **PASS**. Each lap is a dark, soft-edged shadow step that reads as a board
   over a board. Arrises are still dead straight and unworn.
6. Holds at distance: **PASS**. At 5 m it is plainly lap siding; no shimmer. A little even and
   corduroy-like because every board is the same.

**Grade: game.**

**Better set: Q, by a full grade** (game vs fake).

**The one change that would move C1_few up most:** make it its own age. Pull it back to
tan-gold pine that is only starting to silver on the exposed faces (and lose the violet), so it
sits clearly between `new` and `old`; and fade, don't rule, the line where sheltered wood meets
weathered wood.

---

## C1_old

### Set P
1. Real stuff: **PASS** (weak). Raised, eroded grain, checks and a few knots read as old
   softwood. Same violet/blue cast in patches: `C1_old_P_near` 560 140 180 60, 1180 210 120 60.
2. Age reads: **FAIL**. Old in itself is believable at 1 m, but it is not clearly different
   from `few` (same tone, same wear; only the rust nails are new), and at 5 m it is warmer and
   fresher-looking than `few`, the wrong way round. Compare `C1_old_P_far` 0 190 560 170 with
   `C1_few_P_far` 0 100 560 260. No splits, lifted ends, missing paint, dirt splash or sun-silver.
3. No tile tells: **PASS**. No repeat or seam. The rust nail heads sit on a perfectly regular
   grid with identical streaks, which is a placement tell rather than a tile one:
   `C1_old_P_near` 540 40 30 620.
4. Board to board: **FAIL**. One continuous weathered sheet, no board its own.
   `C1_old_P_near` 0 120 1400 250.
5. Edges and joints: **FAIL**. Laps almost absent; where they show it is only as the broken
   shadow. `C1_old_P_near` 0 95 1400 30, 0 235 1400 30, 0 670 1400 30.
6. Holds at distance: **FAIL**. A flat tan card with a few tone bands; no laps.
   `C1_old_P_far` 0 0 560 360.

**Grade: fake.**

### Set Q
1. Real stuff: **PASS** (weak). As P. `C1_old_Q_near` 560 140 180 60.
2. Age reads: **FAIL**. As P: not distinct from `few`, and at 5 m younger-looking than `few`.
   `C1_old_Q_far` 0 0 560 360 against `C1_few_Q_far` 0 100 560 260.
3. No tile tells: **PASS**. Nail grid as P: `C1_old_Q_near` 540 40 30 620.
4. Board to board: **FAIL** (the nearest to a pass of the six). At 5 m a few boards do differ
   slightly in tone, but at 1 m all are the same and the wear runs through the laps.
   `C1_old_Q_near` 0 100 1400 480.
5. Edges and joints: **PASS**. Clear shadowed lap steps. For old siding the edges are too
   straight and whole: no chipped, cupped or split lower edges.
6. Holds at distance: **PASS**. Reads as lap siding at 5 m, steady, with a little tone change.

**Grade: game.**

**Better set: Q, by a full grade** (game vs fake).

**The one change that would move C1_old up most:** let each board be its own board: its own
tone step and grain offset, some silver-grey on the sun side, and broken, cupped or split lower
edges at the laps, so the age shows in the boards and joints and not only in a surface layer.

---

## Across the ages

`new` is clearly a different age from the other two. `few` and `old` are not clearly different
from each other at 1 m, and at 5 m they swap places (`few` looks older than `old`). Best age:
**old, set Q**, narrowly over few Q. None reaches "near the yardstick": the references' siding
and planks differ board to board, have worn and broken edges and dirt that follows the
construction; here the wear is one layer laid over the whole wall.

## Summary

| swatch | set | 1 real | 2 age | 3 tile | 4 board | 5 edges | 6 distance | grade |
|---|---|---|---|---|---|---|---|---|
| C1_new | P | FAIL | PASS | PASS | FAIL | PASS | PASS | **game** (low) |
| C1_new | Q | FAIL | PASS | PASS | FAIL | FAIL | FAIL | **fake** |
| C1_few | P | PASS | FAIL | PASS | FAIL | FAIL | FAIL | **fake** |
| C1_few | Q | PASS | FAIL | PASS | FAIL | PASS | PASS | **game** |
| C1_old | P | PASS | FAIL | PASS | FAIL | FAIL | FAIL | **fake** |
| C1_old | Q | PASS | FAIL | PASS | FAIL | PASS | PASS | **game** |

| swatch | better set | by how much |
|---|---|---|
| C1_new | P | a full grade |
| C1_few | Q | a full grade |
| C1_old | Q | a full grade |
