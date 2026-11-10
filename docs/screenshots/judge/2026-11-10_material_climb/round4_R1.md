# Materials judge: q4_R1 (R1, rough-sawn pine, board and batten)

Blind. Yardstick: the wood in RDR2 (street noon, saloon night), Hunt 1896 (street noon, saloon
night) and KCD2 (street noon). Crops judged: `near` (1 m, noon) and `far` (5 m, golden hour) for
each age and set. Boxes are `x y w h` in the named crop's own pixels.

Seen once, not counted: the saw-toothed edge of the sun's shadow in the open gaps
(`R1_new_P_near` 95 0 130 780 and 450 0 40 780; `R1_few_P_near` 0 0 150 780). The light's fault.

**P against Q, in short:** the two sets are the same boards, the same grain and the same marks.
Q is ~3% darker and carries extra faint vertical lines and tone steps that split each board into
narrow strips at a regular pitch. The grain, the knots and the checks run straight through those
lines unbroken, so they read as lines laid over the wood, not as battens or separate boards. P is
better at every age, **within a grade** each time (no full grade between them).

---

## R1_new

### Set P

| check | | evidence |
|---|---|---|
| 1 Real stuff | PASS (narrow) | Flat-sawn softwood figure with raised late-wood; believable as pine, but the figure is very large and there are no saw marks, so "rough-sawn" doesn't read; it is closer to wire-brushed. |
| 2 Age reads | PASS | Clearly the newest of the three; clean, no sun or dirt yet. Too spotless for anything but week-old boards. |
| 3 No tile tells | PASS | No repeat, seam, blocks or weave at 1 m. |
| 4 Board to board | PASS | Figure differs board to board (straight, cathedral, a big ring board); tone a little too even. |
| 5 Edges and joints | FAIL | `R1_new_P_near` 770 0 60 780: two boards meet with no gap, shadow or arris, only a tone step. `R1_new_P_near` 0 255 1400 50: nail heads are flat blue-grey dots in a ruled row at an even pitch, no dimple, rust or shadow. |
| 6 Holds at distance | FAIL | `R1_new_P_far` 0 15 560 345: at 5 m it is an even saturated orange with printed-looking figure, a varnished-pine laminate card; no relief survives. |

**Grade: game.**

### Set Q

| check | | evidence |
|---|---|---|
| 1 Real stuff | PASS (narrow) | As P. |
| 2 Age reads | PASS | As P. |
| 3 No tile tells | PASS | |
| 4 Board to board | FAIL | `R1_new_Q_near` 680 0 90 780, 920 0 140 780, 370 0 40 780: faint strips at a regular pitch with the grain running through them unbroken; reads as stripes over the boards. `R1_new_Q_far` 80 15 40 345. |
| 5 Edges and joints | FAIL | P's two tells, plus the strip edges above are lines drawn on, not gaps. |
| 6 Holds at distance | FAIL | `R1_new_Q_far` 0 15 560 345: as P, with the added strip lines. |

**Grade: game** (low in the grade).

**Better set: P, within a grade.**
**The one change that would move R1_new up most:** make it hold at 5 m: break the even orange
(less saturation, some sun-fade and dust, tone varying board to board) and give every board
joint a real shadowed gap; then saw marks for "rough-sawn".

---

## R1_few

### Set P

| check | | evidence |
|---|---|---|
| 1 Real stuff | PASS | At 1 m the checked, lifted grain, the small splits and the pale abraded patches are convincing weathered softwood; the best surface of the run. |
| 2 Age reads | FAIL | `R1_few_P_near` 0 0 1400 780: at 1 m it is as dark, grey and checked as R1_old; nothing says "a few years" rather than decades. `R1_few_P_far` 0 15 560 150: at 5 m the top third of every board is clean, smooth, fresh orange and the weathering starts at one height across the whole wall, a level band, not sun and splash. The near and far crops don't read as the same age. |
| 3 No tile tells | PASS | No repeat or blocks. Some soft, lower-detail patches beside sharp checks (`R1_few_P_near` 1000 100 400 300), only if you hunt. |
| 4 Board to board | PASS | Boards differ in tone, checking and width without noise. |
| 5 Edges and joints | PASS | Gaps are dark and shadowed. They are very even in width and blue-black (`R1_few_P_near` 365 0 50 780), a mild tell. |
| 6 Holds at distance | PASS | Keeps boards, gaps and marks at 5 m without mush. |

**Grade: game** (top of the grade; the 1 m crop alone would be near the yardstick).

### Set Q

| check | | evidence |
|---|---|---|
| 1 Real stuff | PASS | As P. |
| 2 Age reads | FAIL | As P: `R1_few_Q_near` 0 0 1400 780; `R1_few_Q_far` 0 15 560 150. |
| 3 No tile tells | PASS | |
| 4 Board to board | FAIL | `R1_few_Q_near` 270 0 40 780, 550 0 40 780, 1030 0 40 780: straight faint lines down the middle of boards, checks crossing them unbroken. `R1_few_Q_far` 295 15 25 345, 460 15 25 345: doubled lines beside the real gaps. |
| 5 Edges and joints | PASS (narrow) | The real gaps are as P; the added lines are faint enough at this age not to fail it alone. |
| 6 Holds at distance | PASS | |

**Grade: game** (mid).

**Better set: P, within a grade.**
**The one change that would move R1_few up most:** make it a middle age: halve the greying and
checking at 1 m so warm wood still shows between grey streaks, and at 5 m replace the level
fresh-orange top band with uneven fade (greyer where the sun and rain reach, warmer under the
eave), so near and far agree and it sits clearly between new and old.

---

## R1_old

### Set P

| check | | evidence |
|---|---|---|
| 1 Real stuff | PASS | Deep checks, torn knots, rusted nail heads; reads as old softwood. |
| 2 Age reads | PASS | Clearly the oldest at 5 m (weathered top to bottom, pale abrasion, rust). At 1 m barely apart from R1_few. Dark charcoal-brown rather than the silver grey desert sun gives. |
| 3 No tile tells | FAIL | `R1_old_P_far` 270 180 130 180 and 0 60 100 200: pale cloudy blotches that sit on the wood like a noise layer, not following grain or boards. `R1_old_P_near` 400 620 220 160 and 1050 100 350 300: soft smeared patches next to sharp checks (mush at 1 m). |
| 4 Board to board | FAIL | `R1_old_P_near` 0 0 900 780: the boards merge into one sheet; only hairlines mark them and tone and checking carry across. `R1_old_P_far` 48 15 25 345: one clean, bright fresh-pine batten in an old wall, with no weathering at all. |
| 5 Edges and joints | PASS (narrow) | The few joints that show are shadowed (`R1_old_P_far` 215 15 10 345, 390 15 10 345); no bright outlines. Old boards should have opened, uneven gaps and worn edges; these are tighter than R1_few's. |
| 6 Holds at distance | PASS | Keeps its marks and knots at 5 m, no shimmer. |

**Grade: game.**

### Set Q

| check | | evidence |
|---|---|---|
| 1 Real stuff | PASS | As P. |
| 2 Age reads | PASS | As P. |
| 3 No tile tells | FAIL | As P: `R1_old_Q_far` 270 180 130 180; `R1_old_Q_near` 400 620 220 160. |
| 4 Board to board | FAIL | P's two, plus `R1_old_Q_near` 370 0 40 780, 700 0 40 780, 1180 0 60 780 and `R1_old_Q_far` 130 15 25 345, 300 15 25 345: regular strip lines with checks and knots running across them. |
| 5 Edges and joints | FAIL | `R1_old_Q_far` 130 15 25 345, 300 15 25 345: thin straight lines drawn down the wall, no shadow, no gap, crossing a knot. |
| 6 Holds at distance | PASS | |

**Grade: game** (low in the grade).

**Better set: P, within a grade.**
**The one change that would move R1_old up most:** make the boards separate things: opened,
uneven gaps with worn edges, each board its own tone and degree of checking (and the fresh
batten weathered to match); then drop the pale cloudy blotches for grain-following sun-grey.

---

## Which age is best

R1_few (set P), on the strength of its 1 m surface. R1_new is the weakest: it fails at 5 m.

## Summary

| swatch | set | 1 Real | 2 Age | 3 Tile | 4 Board | 5 Edges | 6 Distance | grade |
|---|---|---|---|---|---|---|---|---|
| R1_new | P | PASS | PASS | PASS | PASS | FAIL | FAIL | **game** |
| R1_new | Q | PASS | PASS | PASS | FAIL | FAIL | FAIL | **game** (low) |
| R1_few | P | PASS | FAIL | PASS | PASS | PASS | PASS | **game** (top) |
| R1_few | Q | PASS | FAIL | PASS | FAIL | PASS | PASS | **game** |
| R1_old | P | PASS | PASS | FAIL | FAIL | PASS | PASS | **game** |
| R1_old | Q | PASS | PASS | FAIL | FAIL | FAIL | PASS | **game** (low) |

P is better than Q at every age, within a grade each time. No set reaches near the yardstick.
