# Materials judge: 2026-11-14_wear_r1 (floors FL1, furniture FN1; wear round)

Blind judge, per `docs/concept/judge/MATERIAL.md`. **Yardstick:** the reference stills were not
reachable this run; graded against my own knowledge of the wood in shipped AAA westerns (Red Dead
Redemption 2's plank floors and varnished case furniture, Hunt: Showdown 1896's worn interiors).

Crop boxes are `x y w h` in the named crop's own pixels. Only the floor (FL) or the chest (FN) is
judged; walls, light colour and the floor under the chest are not.

**P vs Q in this round:** in every swatch the two sets are the same render apart from small marks
(dents, scratches, chips): under 1% of pixels differ in any view, and every grade below is the same
for P and Q. The P/Q choice is within a grade everywhere.

The saw-toothed sun-shadow edge along battens was not a factor here (the stepped edge on the top
rail's shadow under the chest top, FN near `150 125 900 30`, is the light, not the material).

---

## FL1: fir and pine floor, oiled, worn where feet go

### FL1_few, set P

| # | check | result | evidence |
|---|---|---|---|
| 1 | Real stuff | PASS | Flat-sawn pine/fir cathedral figure, crisp at 1 m; reads as oiled softwood boards. |
| 2 | Age reads | FAIL | The worn path is a milky, cloud-edged pale haze (reads as a dried film or bloom, not wood worn paler and duller); no darker, dustier band by the wall (`20 325 1120 40` is the same tone as mid-floor). `200 380 460 300` |
| 3 | No tile tells | FAIL | Small round reddish dots peppered evenly through the pale path read as noise, not dirt. `250 400 300 200` |
| 4 | Board to board | FAIL | Every board the same saturated orange-brown and the same figure strength; reads as one stain over one board repeated. `0 440 1300 260` |
| 5 | Edges and joints | PASS | Gaps and butt joints read as thin shadowed slots, no drawn outlines. |
| 6 | Holds at distance | FAIL | At 5 m the grain is gone; the floor is a dark card of even glossy stripes, the path a grey smudge. far `0 100 560 200` |

**Grade: game.**

Caused or decoration: the path itself is caused (door to the left of the room). The dents and
scratches are **decoration**: about a hundred, spread evenly over the whole floor, as many by the
wall and off the path as in it. Worst: a lone straight scratch mid-floor where no one drags
anything, near `770 495 35 20`.

### FL1_few, set Q

Same six results and boxes as P (1 PASS, 2 FAIL, 3 FAIL, 4 FAIL, 5 PASS, 6 FAIL).

**Grade: game.**

Caused or decoration: path caused; the marks are fewer than P's (roughly a quarter as many) but
still scattered evenly, so **decoration**. Worst: the evenly sprinkled round dots inside the pale
path, `250 400 300 200`.

**Better set: Q, within a grade** (fewer marks that don't follow use, so less noise).

### FL1_old, set P

| # | check | result | evidence |
|---|---|---|---|
| 1 | Real stuff | PASS | Same fir/pine figure, slightly darker and duller; still reads as boards. |
| 2 | Age reads | FAIL | Against FL1_few it is only a little darker with wider gaps; the path is the same milky cloud, no deeper groove of wear, no grime by the wall, no greying. Old and a few years would not be told apart in play. `180 380 500 280` |
| 3 | No tile tells | FAIL | Same evenly spread dots in the pale path. `200 400 350 200` |
| 4 | Board to board | FAIL | Uniform tone and figure across all boards. `0 480 1300 240` |
| 5 | Edges and joints | PASS | Gaps wider and shadowed, butt joints read as joints; good. |
| 6 | Holds at distance | FAIL | Far view: near-black brown with even horizontal stripes, grain lost. far `0 100 560 220` |

**Grade: game.**

Caused or decoration: path caused; marks (fewer than Q's here) scattered, **decoration**. Worst: a
small dent group out by the right wall, where feet don't go, `1020 345 60 20`.

### FL1_old, set Q

Same six results and boxes as P.

**Grade: game.**

Caused or decoration: about three times P's marks, spread evenly from wall to wall, **decoration**.
Worst: the row of dents along the board by the wall, `370 335 600 25`.

**Better set: P, within a grade.**

**FL1, the one change that would move it up most:** make the path *wear* rather than a pale film:
duller and lighter only where the grain's soft earlywood has been ground down (the latewood standing
proud and darker), fading out along the boards rather than as a cloud, and add a real dark, dusty
band in the last hand's width by the wall and in the corners. Then give each board its own tone.
**Best age:** few (the old reads as the same floor, darker).

---

## FN1: oak, straight-grained, varnished: chest of drawers

### FN1_few, set P

| # | check | result | evidence |
|---|---|---|---|
| 1 | Real stuff | FAIL | Reads as printed wood-grain foil on flat-pack board: an even orange with a fine flat-sawn "cathedral" print, no oak pores, no ray fleck, no depth under the varnish. `160 140 860 160` |
| 2 | Age reads | FAIL | Little to see of a few years' use: no rubbing round the pulls, no dust on the top; a few dashes along one rail. `190 280 800 40` |
| 3 | No tile tells | PASS | No visible repeat or blocks at 1.5 m. |
| 4 | Board to board | FAIL | All four drawer fronts, rails and top are one tone and one figure; reads as one sheet cut up, not chosen pieces of oak. `150 140 900 600` |
| 5 | Edges and joints | FAIL | Drawer and rail arrises carry thin pale dashed lines (drawn edges); a dark blue-black line under the top. `230 455 710 20`, `150 128 890 14` |
| 6 | Holds at distance | FAIL | At 5 m the top becomes a flat blue-grey card and the fronts a flat orange; the oak is gone. far `60 62 345 22`, far `75 95 310 230` |

**Grade: fake.**

Caused or decoration: the marks are a row of small dents along the top arris of the second rail,
evenly spaced across its whole width, `480 285 480 25`: where a drawer would knock, but laid as an
even dashed line, so **decoration**.

### FN1_few, set Q

Same results as P (1 FAIL, 2 FAIL, 3 PASS, 4 FAIL, 5 FAIL, 6 FAIL).

**Grade: fake.**

Caused or decoration: a diagonal scratch across the second drawer (`515 370 55 16`) and a dent by
its corner (`918 280 20 14`) read as **caused** knocks. A bright white fleck on the top's front edge
(`455 95 30 12`) reads as **decoration** (a speck of paint, not a varnish chip). Worst: that fleck.

**Better set: Q, within a grade** (its few marks read like knocks; P's read like a dashed line).

### FN1_old, set P

| # | check | result | evidence |
|---|---|---|---|
| 1 | Real stuff | FAIL | Same foil-print grain, darker; still laminate, not oak. `160 140 860 160` |
| 2 | Age reads | PASS (just) | Clearly older than FN1_few: darker, blotchy duller varnish on the top, grease halos round every pull, chips on the rail arrises. `100 0 1000 110`, `360 200 70 60` |
| 3 | No tile tells | PASS | No repeat or blocks. |
| 4 | Board to board | FAIL | One tone, one figure across every piece. `150 140 900 600` |
| 5 | Edges and joints | FAIL | Pale dashed arris lines on every drawer edge; a white vertical tick on the top rail reads as a line drawn on. `230 455 710 20`, `298 296 12 28` |
| 6 | Holds at distance | FAIL | Top flat blue-grey card; the rail chips become white specks. far `60 62 345 22`, far `225 230 60 15` |

**Grade: fake** (age carries, but everything else reads as a laminate box).

Caused or decoration: the grease halos round the pulls are **caused**. The pale chips on the rail
arrises sit where drawers knock, but are bright white, flat and evenly spread along the rail, and the
vertical white tick (`298 296 12 28`) is in a place nothing would strike: **decoration**. Worst: that
tick.

### FN1_old, set Q

| # | check | result | evidence |
|---|---|---|---|
| 1 | Real stuff | FAIL | As P. `160 140 860 160` |
| 2 | Age reads | FAIL | Without P's chips, old differs from few only by being darker with a blotchier top and halos at the pulls; edges are not rubbed through. `190 440 760 40` |
| 3 | No tile tells | PASS | |
| 4 | Board to board | FAIL | As P. `150 140 900 600` |
| 5 | Edges and joints | FAIL | Pale dashed arris lines on every drawer edge. `230 455 710 20` |
| 6 | Holds at distance | FAIL | Top a flat blue-grey card. far `60 62 345 22` |

**Grade: fake.**

Caused or decoration: halos at the pulls **caused**; the marks are few and scattered. Worst: the
same pale dashed line along every drawer's arris, the same on each one, `230 455 710 20`
(decoration: edges drawn, not worn).

**Better set: P, within a grade** (its chips are the only thing that makes "old" read).

**FN1, the one change that would move it up most:** replace the grain: quarter-sawn (straight-grained)
oak with open pores and silvery ray fleck under an amber varnish with real depth, a different cut on
each drawer front, so it stops reading as foil-wrapped board. Then wear the arrises through only where
hands go (round the pulls, the top's front edge, the drawer bottoms' corners) instead of a pale dash
down every edge, and fix the top turning sky-blue at distance. **Best age:** old (P).

---

## Summary

| swatch | set | real | age | tile | board | edges | distance | grade |
|---|---|---|---|---|---|---|---|---|
| FL1_few | P | PASS | FAIL | FAIL | FAIL | PASS | FAIL | game |
| FL1_few | Q | PASS | FAIL | FAIL | FAIL | PASS | FAIL | game (better, within grade) |
| FL1_old | P | PASS | FAIL | FAIL | FAIL | PASS | FAIL | game (better, within grade) |
| FL1_old | Q | PASS | FAIL | FAIL | FAIL | PASS | FAIL | game |
| FN1_few | P | FAIL | FAIL | PASS | FAIL | FAIL | FAIL | fake |
| FN1_few | Q | FAIL | FAIL | PASS | FAIL | FAIL | FAIL | fake (better, within grade) |
| FN1_old | P | FAIL | PASS | PASS | FAIL | FAIL | FAIL | fake (better, within grade) |
| FN1_old | Q | FAIL | FAIL | PASS | FAIL | FAIL | FAIL | fake |
