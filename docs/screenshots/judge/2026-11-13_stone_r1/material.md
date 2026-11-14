# Materials judge: stone and lime, round 2026-11-13_stone_r1

Blind judge. Rubric: `docs/concept/judge/MATERIAL.md`, "Stone and lime". Yardstick: RDR2 (street noon,
street golden, saloon night), Hunt: Showdown 1896 (street noon, saloon night), KCD2 (street noon). The
relevant stone in the yardstick is Hunt's mill (stone and render under weather, dark crust, streaks,
a soft mass at distance) and KCD2's gate tower (dressed stone, plaster over rubble with the stones
showing through, stains following water). Their standard: the stone has relief in the face and the
silhouette, the joints sit back in shadow, weathering follows water and hands, and no edge is drawn.

Box format: `x y w h` in the named crop's pixels. Near crops are 1400×780, far crops 560×360.
The saw-toothed shadow edge of the sun: not clearly seen in these crops; not counted.

---

## S1: coursed rubble, dressed quoins and coping (new, a few years, old)

| check | result | evidence |
|---|---|---|
| 1. Real stuff | PASS (just) | Reads as a mortared stone wall: the stones vary in hue (grey, olive, brown) like a local field stone. But each face is a flat pad carrying one fine granite-like noise at one scale, with no hammer-dressing, no bulge, no bedding; it is closer to a stone-veneer panel than hammer-squared rubble. |
| 2. Age reads | FAIL | The three ages are the same wall darkened a step at a time (whole-image mean brightness 106 → 98 → 88). No pointing eroded back, no crust, no damp at the foot, no streaks under the coping, no fresh pale pointing on the new. Compare `S1_new_near` with `S1_old_near` at `0 0 1400 780`: only the tone changes. |
| 3. No tile tells | FAIL | Each stone sits in a pale, straight-sided rectangle in the mortar (its footprint), ruled lines in a material that should be trowelled: `S1_new_near` `315 60 650 225` (straight top edge at y≈75, vertical at x≈322), `505 515 30 175`. The bed joints run ruler-level the full width, one stone per course, every course the same height: `S1_new_near` `0 270 1400 40`, `0 495 1400 40`. |
| 4. Stone to stone | PASS | Tone, size and colour vary believably and do not read as noise. Shapes are all the same family (rounded rectangle with a chamfered corner) and could vary more, but this is not a fail. |
| 5. Edges and joints | FAIL | A thin black line is drawn under the lower edge of each stone, uniform in width whatever the light: `S1_new_near` `345 240 600 40`, `530 645 420 30`; at 5 m these become cartoon outlines, `S1_old_far` `140 75 120 70`, `115 270 115 60`. The joints are lit flat and as proud as the stones' margins; they do not read as mortar recessed in shadow. Arrises are crisp cut-out outlines, not knocked edges. Little lentil chips lie loose on the joint ledges: `S1_new_near` `590 260 120 25`. |
| 6. Holds at distance | FAIL | The rubble holds as a wall at 5 m, but the dressed quoins are flat, untooled card panels in ruled outlines: `S1_new_far` `0 0 125 360`. In `S1_old_far` the dark outlines push the whole wall toward a drawing (`120 20 440 320`). |

**Grades:** S1_new **game** · S1_few **game** · S1_old **game** (its far crop is the weakest).
**Best age:** new.
**The one change:** make the joints real: drop the stone-footprint rectangles and the drawn hairline,
and set the mortar back with its own shadow and occlusion (a deep, irregular, trowelled bed that
darkens toward the stone), so each stone sits in a shadowed recess with knocked arrises. After that,
make the ages differ by water (pointing eroded, crust, foot damp, coping streaks), not by a darker tint.

---

## PL1: lime plaster over stone, whitewashed, inside (a few years, old)

| check | result | evidence |
|---|---|---|
| 1. Real stuff | FAIL | Reads as paint on flat drywall with a canvas weave, not lime: no undulation of a hand-floated coat over stone, no softness or chalk in the wash, no stones ghosting through. `PL1_few_near` `0 0 1400 780`. |
| 2. Age reads | FAIL | The two ages have the same flakes in the same places; old only darkens the flake rims and the smudges (mean difference 6/255). No thinning of the wash, no grimy band where men lean, no scuffs low. `PL1_few_near` vs `PL1_old_near` `850 270 360 200`. |
| 3. No tile tells | FAIL | A fine horizontal weave/scanline texture runs over the whole wall: `PL1_few_near` `600 0 700 200` (clearest at night, `PL1_old_saloon_night` `700 0 700 250`). |
| 4. Coat to coat (variation) | FAIL | The variation is a row of evenly spaced, soft vertical smudges hanging from the top, like a brushed gradient, not damp, soot or hand grime: `PL1_old_near` `250 0 1150 560`; at 5 m `PL1_old_far` `30 100 520 260`. |
| 5. Edges and joints | FAIL | The flakes are embossed outlines (a bright and a dark ridge) with the same colour inside as out: no plaster or stone beneath, no lifted film edge. `PL1_old_near` `860 275 340 195`, `585 140 90 150`. |
| 6. Holds at distance | FAIL | At 5 m a flat beige card with blurred stains: `PL1_few_far` `0 0 560 360`. |

**Grades:** PL1_few **fake** · PL1_old **fake**.
**Best age:** few (fewer smudges).
**The one change:** give the coat a body: a gentle hand-floated undulation over the stones beneath
(the stones' shapes ghosting through as soft swells), a chalky, uneven wash, and flakes that open to
a darker, rougher plaster or stone with a thin lifted edge, in place of the weave and the embossed outlines.

---

## PL2: bare rubble, whitewashed, inside (a few years, old)

| check | result | evidence |
|---|---|---|
| 1. Real stuff | PASS (just) | At 1 m it reads as stone under a wash, best at lamplight. But the wash is an even grey-putty colour on stone and joint alike, like a grey render cast over a mould, not white lime thick in the joints and worn thin on the stones' high points. `PL2_few_near` `0 0 1400 780`. |
| 2. Age reads | FAIL | Few and old are nearly the same picture (mean difference 6/255): old adds a few soft blotches on the stones. No flaking of the wash, no grimy lean band, no scuffs. `PL2_few_near` vs `PL2_old_near` `330 70 620 210`. |
| 3. No tile tells | FAIL | The same ruled stone-footprint rectangles in the joints: `PL2_few_near` `505 515 30 175`, `320 60 30 220`. Bed joints ruler-level the full width: `0 495 1400 40`. |
| 4. Stone to stone | PASS | Sizes and shapes vary enough; the wash rightly evens the tone. |
| 5. Edges and joints | FAIL | A drawn black hairline under every stone, `PL2_few_near` `530 640 420 40`; a matching thin bright line along each top edge, `330 65 610 25`; perfect elliptical "pebbles" stuck on the joints like lentils or coins, `PL2_few_near` `455 55 140 30`, `820 490 80 25`, `900 455 50 25`. |
| 6. Holds at distance | FAIL | At 5 m it is a drawing of stones: every stone ringed by a crisp dark ink outline on a flat parchment fill. `PL2_few_far` `60 15 230 70`, `PL2_old_far` `0 0 560 360`. |

**Grades:** PL2_few **game** · PL2_old **game** (at 1 m; seen at 5 m alone, both would be fake).
**Best age:** few.
**The one change:** remove the drawn outlines and pebbles and let the wash pool white and thick in
recessed, shadowed joints while it wears thin and greyer on the stones' proud faces; at 5 m that alone
would turn the ink drawing back into a wall.

---

## Summary

| swatch | real stuff | age reads | no tile tells | stone to stone | edges and joints | holds at distance | grade |
|---|---|---|---|---|---|---|---|
| S1_new | PASS | FAIL | FAIL | PASS | FAIL | FAIL | game |
| S1_few | PASS | FAIL | FAIL | PASS | FAIL | FAIL | game |
| S1_old | PASS | FAIL | FAIL | PASS | FAIL | FAIL | game |
| PL1_few | FAIL | FAIL | FAIL | FAIL | FAIL | FAIL | fake |
| PL1_old | FAIL | FAIL | FAIL | FAIL | FAIL | FAIL | fake |
| PL2_few | PASS | FAIL | FAIL | PASS | FAIL | FAIL | game (fake at 5 m) |
| PL2_old | PASS | FAIL | FAIL | PASS | FAIL | FAIL | game (fake at 5 m) |

Nothing is near or at the yardstick. Worst tells: S1, the drawn black hairline under each stone and
the ruled footprint rectangles in flat, unrecessed joints; PL1, embossed-outline flakes on a weave
over a drywall-flat coat; PL2, ink outlines at 5 m and coin-like pebbles on the joints.
