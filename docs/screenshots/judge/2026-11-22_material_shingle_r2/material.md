# Materials judge: SH1 sawn pine shingles, round r2 (2026-11-22)

I looked at: the rubric (`docs/concept/judge/MATERIAL.md`), the six yardstick screenshots (the wood
in them only; KCD2's shingled roofs and RDR2's boardwalk and wall boards were the closest), and the six crops.
Crop boxes are `x y w h` in that crop's own pixels (near crops are 1400x780, far crops are 560x360).

Known fault of the light: there is a faint saw-toothed shadow along each course line, under the butts
(e.g. new near `0 100 1400 30`, few near `0 112 1400 25`). I noted it here once and did not count it
against any check.

## SH1_new: sawn pine shingles, new

| check | result | evidence |
|---|---|---|
| 1. Real stuff | PASS (only just) | The flat-sawn pine figure (cathedral arches, latewood lines) reads as pine. But the face is as smooth as sanded veneer. A sawn shingle shows saw marks and fuzzed fibres, and this shows none. |
| 2. Age reads | FAIL | A new roof should have almost no splits. Here every shingle has two or three dark open checks, more than the "old" swatch has: `560 110 340 160`, `1040 120 300 140`. |
| 3. No tile tells | FAIL | The splits look stamped on. Each one is the same dark, wavy "lightning" squiggle, the same width and length, rising from the butt, and they are spaced evenly across the roof: `540 100 400 200`, `0 400 1400 140`. |
| 4. Board to board | PASS | Tone (honey to grey-brown), width and figure vary well from shingle to shingle, without reading as noise. Every shingle lies dead flat and the courses are ruled straight, but that comes up again below. |
| 5. Edges and joints | FAIL | The splits read as brown lines drawn on, not as openings: no lit lip and no depth, and they wander across the grain instead of running along it (`590 120 120 150`). The butts have no visible thickness: the shingles end in a hairline with a soft smudge below (`0 255 1400 20`). |
| 6. Holds at distance | FAIL | At 5 m it turns into an even brick-bond grid of ruled courses with the big cathedral figure on top. It looks like a printed veneer card with no butt shadow or relief (`0 0 560 360`; figure `0 150 200 120`). |

**Grade: game.** It reads as wood, but the stamped splits and the flat, veneer face give it away
straight away.
**The one change:** take nearly all the splits off the new age. Keep any that stay short and straight
along the grain, with a thin lit edge, so they read as cuts in the wood and not as drawn lines.

## SH1_few: sawn pine shingles, a few years

| check | result | evidence |
|---|---|---|
| 1. Real stuff | FAIL | The grain has nearly gone and the colour is an even mauve-taupe, so it reads more like a painted board or composite than pine going grey. Very little fibre or figure is left: `100 120 400 140`, `680 400 360 120`. |
| 2. Age reads | FAIL | It doesn't sit between new and old. It has lost the grain before the silvering and raised grain of the old age begin, and its splits are the same set as the new age's, unchanged: `300 100 400 200`. |
| 3. No tile tells | FAIL | The same stamped squiggle splits, two or three to a shingle (`0 270 1400 140`). There is also a lone white dot (`365 15 30 25`). |
| 4. Board to board | FAIL | Almost every shingle has the same tone and the same smooth face, so the roof reads as one surface cut by lines (`0 400 1400 380`). |
| 5. Edges and joints | FAIL | The keyways are solid black bars of the same width everywhere (`490 270 20 130`, `660 400 25 130`), so they look drawn, not like shaded gaps with lit edges. |
| 6. Holds at distance | FAIL | A flat grid. The top two courses are a warmer orange than the rest, which reads as a seam in the material (`0 10 560 80`). It has no butt relief. |

**Grade: game** (close to fake: it has the most tells of the three).
**The one change:** give it a real middle age. Keep the pine grain and lift it a little, grey it
in patches from the weather end, and stop sharing the new age's stamped splits.

## SH1_old: sawn pine shingles, old

| check | result | evidence |
|---|---|---|
| 1. Real stuff | PASS | Grey weathered wood with raised, scratchy fibre and real knots (`960 300 120 100`) reads as old pine. |
| 2. Age reads | PASS (only next to few) | The grey, the raised grain, the dirt and the knots read as old desert wood. Two things undercut it: it has fewer and thinner splits than the new age (the wrong way round), and a desert roof this old would show butts worn thin, cupping and a few lifted or missing shingles. It has none of these (`0 520 1400 260`). |
| 3. No tile tells | PASS | No repeat that I could see. The bluish speckle in the grain is close to dots (`380 420 160 100`) but it reads as staining. |
| 4. Board to board | FAIL | The tone varies only a little, and every shingle is equally flat, square-cut and aligned. Real old shingles curl, cup and sit at slightly different heights: `0 260 1400 280`. |
| 5. Edges and joints | PASS | The keyways read as shaded gaps and the laps carry a shadow. The arrises could be more worn. |
| 6. Holds at distance | FAIL | At 5 m it reads as a brick or tile pattern on a flat card: ruled courses, no relief. One bright orange shingle sticks out like a texture error rather than a repair (`172 50 50 35`). |

**Grade: game** (the best of the three: at 1 m it is near the yardstick).
**The one change:** break the flatness. Give each shingle a little cup and tilt, and vary its butt
height and thickness, so the courses cast uneven shadows at 1 m and read as a roof at 5 m.

## The set (comparing ages)

- **Age reads: FAIL for the set.** Going new, few, old, the splits get fewer instead of more. The
  few-years age is the odd one out (smooth taupe, not a step towards the old age's grey).
- **Best age: old.**
- **Against the yardstick:** KCD2's shingles show uneven butts, curl and relief at a distance. Here
  every course is perfectly level and coplanar, and that is the biggest gap at 5 m.

## Summary

| swatch | age | grade |
|---|---|---|
| SH1 | new | game |
| SH1 | few | game |
| SH1 | old | game (best; at 1 m near the yardstick) |
| SH1 | set (ages together) | game: age order of the splits is reversed |
