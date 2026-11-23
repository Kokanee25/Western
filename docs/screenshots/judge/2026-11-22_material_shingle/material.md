# Materials judge: SH1 sawn pine shingles (2026-11-22_material_shingle)

Blind judge, rubric `docs/concept/judge/MATERIAL.md`. Yardstick: RDR2, Hunt: Showdown 1896 and
KCD2 official screenshots (their wood only). Crop boxes are `x y w h` in the named file's pixels.

Light note (not counted): the sun's shadow under each course's butt has a saw-toothed edge
(e.g. SH1_few_near `80 115 1250 20`). That fault is the light's, so it fails no check and lowers no grade.

Common to all three ages: every course's butt is one dead-straight, level line across the whole
wall, and every keyway is a pure-black slot of the same width. Real sawn shingles laid by hand
vary a little in butt line, keyway width and how they sit (lift, cup, a proud corner). Here
the wall reads as ruled.

## SH1_new: sawn pine shingles, new

1. **Real stuff: FAIL.** Bold flat-sawn "cathedral" figure on a smooth, glossy-flat face reads as
   pine veneer or a laminate, not as the fibrous, saw-marked face of a sawn shingle
   (`290 110 280 150`, `1040 520 200 110`). Several shingles are a cool grey-mauve with soft,
   low-contrast figure, like a different texture dropped in (`110 110 175 150`, `690 400 210 120`,
   `230 535 330 105`).
2. **Age reads: PASS.** Clearly fresh, with resin-yellow pine, no greying and no checks. It is
   distinct from the other two ages.
3. **No tile tells: PASS.** No repeat, seam or blocks found at 1 m.
4. **Board to board: FAIL.** Widths vary well, but the tone spread is two clusters (warm tan and
   cold grey-mauve). It does not run as a continuous range, so the grey pieces read as wrong
   material rather than a different board (`690 400 210 120`).
5. **Edges and joints: FAIL.** Keyways are uniform black ruled lines (`560 110 20 290`,
   `1030 390 40 250`). The butts are knife-crisp and dead level (`0 255 1400 20`), with no arris wear
   or thickness change.
6. **Holds at distance: PASS.** At 5 m the figure and tone mix hold, with no shimmer and no mush
   (SH1_new_far). It reads as a tidy, regular grid, but it is still recognisably shingle.

**Grade: game.** The one change that would help most is a sawn-shingle surface in place of the
veneer figure: mostly edge-grain or rift figure, soft fibrous saw marks, and grey pieces brought into the same
tonal family.

## SH1_few: sawn pine shingles, a few years

1. **Real stuff: PASS.** It reads as weathered softwood, with fine streaked grain, grey-brown and a little
   raised (`500 270 450 130`).
2. **Age reads: PASS.** The colour has fully silvered from new, with streaks but no splits. That is
   believable for a desert sun and sits between new and old. Little dirt or splash is visible low.
3. **No tile tells: PASS.** There is no repeat. A stray white fleck (`365 20 25 25`) reads as a speck and
   is acceptable.
4. **Board to board: FAIL.** It is nearly uniform: most shingles are the same grey with the same streaks,
   and the few warm ones (`0 270 90 140`, `1075 260 200 130`) stand out alone. It reads as one
   surface cut into rectangles, not as individual boards.
5. **Edges and joints: FAIL.** The keyways are even-width black lines (`670 120 20 140`,
   `1195 400 25 120`). Butt lines are perfectly straight and level (`0 515 1400 20`), with no worn or rounded
   arrises, cup or lift.
6. **Holds at distance: FAIL.** At 5 m it reads as a flat brick or tile wall: even tone, ruled joints,
   no relief (SH1_few_far `0 90 560 270`). The top two courses are a different, new-looking orange
   (`0 10 560 80`). That reads as an error, not a repair.

**Grade: game.** The one change that would help most is board-to-board variation (tone, streak density and
a little cup or lift per shingle) so it reads as separate pieces of wood. **Best age: few.**

## SH1_old: sawn pine shingles, old

1. **Real stuff: PASS (barely).** It reads as old silvered wood, with streaked latewood, knots and some
   blotch (`370 300 220 110`). The blue-grey mottle is close to the edge of looking like a dirty
   paint texture (`180 280 170 120`).
2. **Age reads: FAIL.** The main cue of age is wrong. The splits run **across** the grain
   (horizontally), while a shingle splits along its grain, down from the butt. They are drawn as
   thin dark wavy hairlines with no open width or depth (`720 185 145 25`, `330 545 200 30`,
   `1170 390 230 80`, `220 545 115 45`). There is no curl, cupping, eroded butt or slipped shingle.
   Apart from the cracks it is only a darker version of the few-years swatch.
3. **No tile tells: PASS** at 1 m. The same knot rings show twice (`340 300 80 60`, `435 400 80 40`) but they
   are faint.
4. **Board to board: FAIL.** Every piece has the same streak density and tone, so it reads as one
   surface cut up (`0 400 1400 130`).
5. **Edges and joints: FAIL.** The keyways are ruled black lines (`680 400 20 240`) and the butts are crisp and
   level. Old shingles should have rounded, eroded butts and opened, irregular keyways.
6. **Holds at distance: FAIL.** At 5 m the cross-grain cracks become a stamped pattern of black
   dashes on nearly every shingle (SH1_old_far `0 90 560 260`). One course is bright new orange
   (`0 50 560 35`), which reads as a bug.

**Grade: game** (close to fake at 5 m). The one change that would help most is splits that run with the grain
from the butt up, open with real width and shadow, plus some curl and an eroded, rounded butt.

## Summary

| Swatch | Age | Real | Age | Tiles | Board | Edges | Distance | Grade |
|---|---|---|---|---|---|---|---|---|
| SH1 | new | FAIL | PASS | PASS | FAIL | FAIL | PASS | game |
| SH1 | few | PASS | PASS | PASS | FAIL | FAIL | FAIL | game |
| SH1 | old | PASS | FAIL | PASS | FAIL | FAIL | FAIL | game |

Best age: few. None reaches "near the yardstick". The yardstick's shingle and board wood shows
irregular set, lift and edge wear. These swatches are flat, ruled and uniform.
