# Materials judge: R1 (rough-sawn pine, board and batten), sets P and Q

Blind judgment against the yardstick's wood (RDR2 street/saloon, Hunt 1896, KCD2). Crop boxes are
`x y w h` in the named crop's own pixels.

Noted once: the saw-toothed edge of the sun's shadow down the open joints (e.g. `R1_new_P_near`
`95 0 130 780`, `R1_few_P_near` `0 0 150 780`). It is the light's fault and is not counted below.

## R1_new

### Set P: **game**

| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | Near, the raised latewood reads as pine. Weak pass: the figure is very bold and sanded-looking, with no saw marks for "rough-sawn". |
| 2 Age reads | PASS | Clearly new against the other two ages; if anything too clean (no dust, no splash at all). |
| 3 No tile tells | PASS | No repeat, seam or blocks at 1 m. |
| 4 Board to board | FAIL | Every board is the same honey tone and the same contrast; only the figure differs. `R1_new_P_far` `0 15 560 345` |
| 5 Edges and joints | PASS | Open joints read as dark gaps; the tight ones are hairlines (`R1_new_P_near` `740 0 80 780`), acceptable. |
| 6 Holds at distance | FAIL | At 5 m it is a flat, evenly lit card of printed pine (reads as laminate / varnished panelling); no relief, battens barely stand off. `R1_new_P_far` `0 15 560 345` |

### Set Q: **game**

| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | As P; the few dark scuffs and smudges help (`R1_new_Q_near` `480 150 120 50`, `1080 370 90 40`). |
| 2 Age reads | PASS | New, with a first trace of handling. |
| 3 No tile tells | PASS | |
| 4 Board to board | FAIL | Same uniform honey tone on every board. `R1_new_Q_far` `0 15 560 345` |
| 5 Edges and joints | PASS | |
| 6 Holds at distance | FAIL | Same flat laminate card at 5 m; Q's marks are invisible there. `R1_new_Q_far` `0 15 560 345` |

**Better set: Q, only within the grade** (a few scuffs near; identical at 5 m).

## R1_few

### Set P: **game** (low)

| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | The grey checked surface near is convincing weathered softwood. |
| 2 Age reads | FAIL | "A few years" is charcoal-grey, deeply checked and split: it reads decades old and is hardly told apart from R1_old. `R1_few_P_near` `400 0 600 780` (compare `R1_old_P_near` whole) |
| 3 No tile tells | PASS | |
| 4 Board to board | FAIL | Boards and battens share one tone and one continuous checking; only the orange lines separate them. `R1_few_P_near` `760 0 640 780` |
| 5 Edges and joints | FAIL | Bright rust-orange lines run down every board and batten edge: outlines drawn on, not worn arrises. `R1_few_P_near` `610 0 150 780`, `930 0 200 780`; `R1_few_P_far` `215 20 100 340` |
| 6 Holds at distance | PASS | Keeps its checks and the sheltered warm band under the top; the orange edge lines still show (counted under 5). |

### Set Q: **game**

| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | Near crop is the most convincing wood of the set. |
| 2 Age reads | FAIL | Same as P: far too old for a few years, and near-identical to R1_old Q. `R1_few_Q_near` `400 0 600 780` |
| 3 No tile tells | PASS | |
| 4 Board to board | FAIL | Right of the third joint the battens dissolve: one slab of continuous grain with no edges or tone steps. `R1_few_Q_near` `760 0 640 780` |
| 5 Edges and joints | PASS | Joints are dark shadowed gaps, no coloured lines. `R1_few_Q_near` `360 0 60 780` |
| 6 Holds at distance | PASS | Reads as weathered planking at 5 m, joints as thin shadows. |

**Better set: Q, within the grade** (but clearly: it loses P's orange outlines).

## R1_old

### Set P: **game**

| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | |
| 2 Age reads | PASS | Believable old desert wood on its own (grey, checked, rusted nail heads). It is not clearly older than "few"; that fault is charged to R1_few. |
| 3 No tile tells | PASS | |
| 4 Board to board | PASS | Weak: tone varies a little across the wall. |
| 5 Edges and joints | FAIL | Orange lines along edges, one pair wavy and bright. `R1_old_P_near` `900 0 200 780`, `250 0 130 780`; `R1_old_P_far` `45 20 30 340` |
| 6 Holds at distance | PASS | |

### Set Q: **near the yardstick**

| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | |
| 2 Age reads | PASS | As P. At golden hour it goes warm brown rather than silver-grey; a hunt-for-it tell. |
| 3 No tile tells | PASS | |
| 4 Board to board | PASS | The paler tan batten (`R1_old_Q_near` `930 0 120 780`) and the tone drift read as real replaced/odd boards. |
| 5 Edges and joints | PASS | Dark gaps, no outlines. Weak: several battens have no visible edge at all near. |
| 6 Holds at distance | PASS | Planks, knots and checks carry at 5 m; battens are flat but it is not a card. |

**Better set: Q, by a full grade.**

## The one change that would move each up most

- **R1_new:** give the boards different tones and a rough-sawn face (saw marks, a little dust and
  dulling) so it stops reading as one evenly varnished sheet at 5 m. Best set: Q.
- **R1_few:** make it a real halfway age: honey going patchy silver-grey with the grain still
  showing and light checking only, instead of the old wood again. Best set: Q.
- **R1_old:** let each batten show as its own piece (a shadowed edge and a small tone step), and
  silver the sunlit faces more. Best set: Q.

Best age of the swatch: **R1_old (set Q)**.

## Summary

| swatch | set | 1 Real | 2 Age | 3 Tile | 4 Boards | 5 Edges | 6 Distance | grade |
|---|---|---|---|---|---|---|---|---|
| R1_new | P | PASS | PASS | PASS | FAIL | PASS | FAIL | game |
| R1_new | Q | PASS | PASS | PASS | FAIL | PASS | FAIL | game |
| R1_few | P | PASS | FAIL | PASS | FAIL | FAIL | PASS | game (low) |
| R1_few | Q | PASS | FAIL | PASS | FAIL | PASS | PASS | game |
| R1_old | P | PASS | PASS | PASS | PASS | FAIL | PASS | game |
| R1_old | Q | PASS | PASS | PASS | PASS | PASS | PASS | near the yardstick |

| swatch | better set | difference |
|---|---|---|
| R1_new | Q | within a grade |
| R1_few | Q | within a grade |
| R1_old | Q | a full grade |
