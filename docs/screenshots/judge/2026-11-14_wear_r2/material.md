# Materials judge: round 2026-11-14_wear_r2 (floors FL1, furniture FN1; ages few / old; sets P and Q)

**Yardstick:** the reference stills could not be reached this run. Graded against my own knowledge of
the wood in shipped AAA westerns (Red Dead Redemption 2's saloon, store and homestead floors and
furniture; Hunt: Showdown 1896's interiors): floors greyed, dull and dusty in the joints, nail rows
across the joists, wear that kills the figure and raises the grain; furniture with real oak pores and
ray fleck, varnish that is amber and uneven, rubbed through on arrises.

**Method:** every crop viewed full size (near, far, saloon_night for each set). P and Q differ in under
0.5% of pixels in every view; the differences are small marks (dents, chips, a scratch), so P against Q
is decided on those marks and is **within a grade** in every swatch.

**Light fault noted once (not graded):** the saw-toothed shadow edge shows under the chest's top
overhang (FN1 near, `150 125 880 25`) and along the floor's board laps.

Crop boxes are `x y w h` in the crop named in each line (near crops 1400x780, far 560x360).

---

## FL1 few (fir/pine floor, oiled, a few years)

### Set P

| check | | evidence |
|---|---|---|
| Real stuff | FAIL | `FL1_few_P_near 460 620 900 80`: saturated orange-brown with crisp bright-yellow cathedral figure; reads as a stained deck or a stock plank texture, not a working building's oiled floor (too clean, too red, no grey). |
| Age reads | FAIL | `FL1_few_P_near 0 420 700 260`: the path is a milky pale bloom with cloudy edges over grain that stays crisp; nothing darker or dustier by the wall (`120 325 1000 40` is the same tone as mid-floor). Few and old differ too little (see FL1 old). |
| No tile tells | PASS | No repeat or seam found; the boards' figures differ. |
| Board to board | PASS | Tone and figure vary a little board to board, butts staggered; uniform widths are acceptable for a floor. |
| Edges and joints | FAIL | `FL1_few_P_near 455 625 10 55`: butt joints are one-pixel black lines drawn on, no gap, no worn arris; long joints are even black rules. No nail rows anywhere. |
| Holds at distance | PASS | `FL1_few_P_far`: still boards at 5 m, the path a faint purple-grey haze; dark but no shimmer. |

**Grade: game.** Caused vs decoration: the path runs from the doorway, so its *place* is caused, but
the round dark dents are **decoration**, scattered in and out of the path as perfect dots
(worst: `FL1_few_P_near 440 705 20 20`, and a lone scratch `370 588 30 30`).

### Set Q

Same six results as P (Real stuff FAIL `460 620 900 80`; Age FAIL `0 420 700 260`; Edges FAIL
`455 625 10 55`; others PASS). Without P's dots the path is the only wear. **Grade: game.**
Caused vs decoration: the path is placed by use; worst is its blotchy cloud edge, which reads as a
smear rather than feet (`FL1_few_Q_near 420 480 140 100`).

**P vs Q:** Q is better, within a grade: P's scattered round dents read stamped on.

**One change:** make the path real wear, not a bloom: kill the oil and figure where feet go (duller,
greyer, raised grain), add dirt packed by the wall and in the joints, and put nail rows across the
joists. Then lower the red saturation of the whole floor.

---

## FL1 old (fir/pine floor, oiled, old)

### Set P

| check | | evidence |
|---|---|---|
| Real stuff | FAIL | `FL1_old_P_near 380 700 1000 60`: still the same saturated stained-deck read with bright latewood; an old floor would be grey-brown and dull. |
| Age reads | FAIL | `FL1_old_P_near 0 380 800 380` vs the few crop: only a little darker, slightly wider gaps and more dents; the path is the same milky bloom, and it stops in a hard edge mid-board (`300 690 100 60`). No dust by the wall. |
| No tile tells | PASS | No repeat found. |
| Board to board | PASS | Some tone variation, staggered butts. |
| Edges and joints | FAIL | `FL1_old_P_near 600 545 10 45`: butts are drawn lines; long gaps read better than in few (some depth), but arrises are not worn. |
| Holds at distance | PASS | `FL1_old_P_far`: boards hold, no shimmer; darker and flatter than few. |

**Grade: game.** Caused vs decoration: worst is the round dents, evenly spread round pocks with no
relation to the path or the door (`FL1_old_P_near 180 715 20 20`, `68 650 18 18`): **decoration**.

### Set Q

Same six results (Real stuff FAIL `380 700 1000 60`; Age FAIL `0 380 800 380` and the hard path edge
`300 690 100 60`; Edges FAIL `600 545 10 45`; others PASS). **Grade: game.** Caused vs decoration:
the path is placed by use, but its hard straight-ish end mid-board reads painted on
(`FL1_old_Q_near 300 690 100 60`).

**P vs Q:** Q is better, within a grade (fewer stamped dots); P's dents do add age, but not as dents
would lie.

**Best age of FL1:** few (the clean stain suits it better; old does not read old enough).

---

## FN1 few (oak, straight-grained, varnished: chest of drawers, a few years)

### Set P

| check | | evidence |
|---|---|---|
| Real stuff | FAIL | `FN1_few_P_near 200 150 800 140`: fine wavy flame figure with no pores or ray fleck; reads as a laminate or a stock "wood" decal (cherry/maple-like), not straight-grained oak. Even orange colour, plastic sheen; the top (`100 0 1000 110`) is a flat pinkish slab. |
| Age reads | FAIL | `FN1_few_P_near 150 130 900 620` vs old: almost no difference besides pull halos; no dust on the top, no dulled varnish patches. |
| No tile tells | PASS | No obvious repeat, though the figure is uniform. |
| Board to board | FAIL | `FN1_few_P_near 150 130 880 600`: all four drawer fronts, carcass and top are one tone with one figure, as if cut from one sheet; real oak fronts differ. |
| Edges and joints | FAIL | `FN1_few_P_near 230 475 700 15`: a pale dashed, jagged strip along each drawer's top edge reads as a line drawn along the edge, not a worn arris or a shadowed gap. |
| Holds at distance | FAIL | `FN1_few_P_far 60 62 345 25` and `75 95 310 235`: a flat orange box with a flat blue-grey top; the figure vanishes, it reads as a card. |

**Grade: fake.** Caused vs decoration: little wear at all; worst is the dashed chipped strip on the
drawer edges, same on every drawer: **decoration** (`230 475 700 15`).

### Set Q

Same six results (Real stuff FAIL `200 150 800 140`; Age FAIL; Board to board FAIL; Edges FAIL
`230 475 700 15`; Distance FAIL `FN1_few_Q_far 60 62 345 25`; tiles PASS). **Grade: fake.**
Caused vs decoration: Q adds dark notches on drawer bottom edges (`784 578 43 14`, `229 465 53 14`),
which sit where knocks go (caused), but also a lone diagonal scratch across a drawer front
(`FN1_few_Q_near 510 365 70 20`) and a white fleck on the top's front edge (`450 95 30 12`):
**decoration**, worst the scratch.

**P vs Q:** P is better, within a grade: Q's stray scratch and fleck read scattered on.

**One change:** replace the laminate figure with real straight-grained oak (open pores, ray fleck,
amber varnish with depth), varying board to board across the fronts, top and sides.

---

## FN1 old (oak, varnished: chest of drawers, old)

### Set P

| check | | evidence |
|---|---|---|
| Real stuff | FAIL | `FN1_old_P_near 200 150 800 140`: same laminate figure, slightly browner. |
| Age reads | FAIL | `FN1_old_P_near 360 200 90 60`: the pull halos are right in place but are soft identical blobs under every knob; the top has a pale bloom but no dust, no rubbed-through arrises, no grease darkening. Few to old is only a small step. |
| No tile tells | PASS | No repeat found. |
| Board to board | FAIL | `FN1_old_P_near 150 130 880 600`: one tone, one figure for every part. |
| Edges and joints | FAIL | `FN1_old_P_near 230 475 700 15`: the same dashed pale strip on every drawer edge. |
| Holds at distance | FAIL | `FN1_old_P_far 60 62 345 25`: flat blue-grey top, flat orange box. |

**Grade: fake.** Caused vs decoration: the pull halos are **caused** in place; worst is the round
dark pocks on the top, scattered at random (`FN1_old_P_near 570 35 20 15`, `435 85 20 15`), and the
square dark notches on drawer edges (`279 458 24 18`) read stamped: **decoration**.

### Set Q

Same six results (Real stuff FAIL `200 150 800 140`; Age FAIL `360 200 90 60`; Board to board FAIL;
Edges FAIL `230 475 700 15`; Distance FAIL `FN1_old_Q_far 60 62 345 25`; tiles PASS). **Grade: fake.**
Caused vs decoration: without P's pocks and notches the only wear is the pull halos, caused in place
but stamped the same under every knob (`FN1_old_Q_near 370 215 50 45`).

**P vs Q:** Q is slightly better, within a grade: cleaner, and its one wear (round the pulls) is the
caused kind; P's extra marks read as scattered decoration.

**One change:** the same as few (real oak), then make the old age real: varnish rubbed through on the
top's front arris and drawer edges, grease darkening round the pulls (varying knob to knob), dust on
the top. **Best age of FN1:** old (the pull wear at least follows use).

---

## Summary

| swatch | set | real | age | tiles | board | edges | distance | grade |
|---|---|---|---|---|---|---|---|---|
| FL1 few | P | FAIL | FAIL | PASS | PASS | FAIL | PASS | game |
| FL1 few | Q | FAIL | FAIL | PASS | PASS | FAIL | PASS | game (better, within grade) |
| FL1 old | P | FAIL | FAIL | PASS | PASS | FAIL | PASS | game |
| FL1 old | Q | FAIL | FAIL | PASS | PASS | FAIL | PASS | game (better, within grade) |
| FN1 few | P | FAIL | FAIL | PASS | FAIL | FAIL | FAIL | fake (better, within grade) |
| FN1 few | Q | FAIL | FAIL | PASS | FAIL | FAIL | FAIL | fake |
| FN1 old | P | FAIL | FAIL | PASS | FAIL | FAIL | FAIL | fake |
| FN1 old | Q | FAIL | FAIL | PASS | FAIL | FAIL | FAIL | fake (better, within grade) |
