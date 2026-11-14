# Materials judge: round 2026-11-11_paint_r2i (P5, P6; sets P and Q)

Blind judge. I saw the rubric (`docs/concept/judge/MATERIAL.md`), the six yardstick screenshots (RDR2 street noon,
street golden and saloon night; Hunt 1896 street noon and saloon night; KCD2 street noon; only their wood was
looked at), and the 36 crops in this folder. Nothing else. Crop boxes are `x y w h` in the named crop's pixels.

The yardstick's painted and bare interior wood (RDR2's saloon: the balustrade, the gallery fascia, the wainscot)
reads by its wear more than by its colour: rubbed arrises, darker where hands go, dirt in the corners, and boards
that differ by a shade. That is the bar for an indoor painted wall at "near" and "at".

Light: no saw-toothed sun-shadow edge was visible in any of these crops (they are wall/ceiling panels in shade,
golden light or lamplight), so there is nothing to note for it.

Reading of the two sets, in a sentence each:
- **P** puts a coarse stucco-like stipple on some boards and not others, draws the pine's figure as thin relief
  contour lines (they read as map cracks on a coat that is meant to be new), and at "old" chips the paint to
  red-brown wood in small spots along the beads, with dark grime in the grooves.
- **Q** is a clean, smooth, even film with the grain telegraphing softly; it is the more believable coat, but its
  three ages are nearly the same picture, and at night the pine's colour figure shows through like a stain.

---

## P5: pale cream interior paint, narrow planed pine boards

### P5, set P

| check | new | few | old |
|---|---|---|---|
| 1. Real stuff | FAIL: some boards read as sand-textured stucco paint, not a film on planed pine; contour lines like crazing on a fresh coat. `P5_new_P_near 450 0 100 560` | FAIL: the stipple is strong on several boards (sandpaper, not paint over grain). `P5_few_P_near 1140 50 150 300` | FAIL: same stipple boards beside smooth ones. `P5_old_P_near 820 250 110 300` |
| 2. Age reads | FAIL: a "new" coat already shows crack-like lines. `P5_new_P_near 450 0 100 560` | FAIL: hardly different from new (a touch yellower; no rub, no scuff low, no chalking). `P5_few_P_near 300 0 600 780` | PASS: chips to bare wood on the beads, grime in the grooves; reads as an old coat (though no hand rub or low scuffs, and the chips are small evenly spaced spots) |
| 3. No tile tells | **FAIL**: stipple/mush patches on single boards. `P5_new_P_near 0 0 120 400` | **FAIL**: stipple patches, the worst of the three. `P5_few_P_near 1140 50 150 300` | **FAIL**: stipple boards. `P5_old_P_near 820 250 110 300` |
| 4. Board to board | PASS | FAIL: rough and smooth boards alternate and read as stripes, not as boards of one batch. `P5_few_P_near 950 0 450 780` | FAIL: same alternation. `P5_old_P_near 200 0 700 780` |
| 5. Edges and joints | PASS: beads and quirks shadowed; the quirk is a very even thin line but reads as a cut | PASS | FAIL: groove lines go hard blue-black, drawn rather than shadowed. `P5_old_P_near 420 0 140 780` |
| 6. Holds at distance | PASS (`P5_new_P_far`: even, no shimmer) | PASS | PASS (chips read as flecks at 5 m, not noise) |
| **grade** | **game** | **game** | **game** |

### P5, set Q

| check | new | few | old |
|---|---|---|---|
| 1. Real stuff | PASS: a smooth oil film with the grain telegraphing through | PASS | FAIL: the pine's colour figure (cathedral arches) shows through the paint like a stain; at lamplight it reads as varnished bare pine, not cream paint. `P5_old_Q_saloon_night 0 100 450 500` |
| 2. Age reads | PASS: sound, even coat, low sheen | FAIL: nearly indistinguishable from new (slightly warmer, slightly darker grooves). `P5_few_Q_near 0 0 1400 780` | FAIL: no failure of the coat at all: no chips, flaking, rub or low scuffs; only deeper grain relief and darker grooves. `P5_old_Q_near 0 0 1400 780` |
| 3. No tile tells | **PASS** | **PASS** | **PASS** |
| 4. Board to board | PASS (subtle, believable) | PASS | PASS |
| 5. Edges and joints | PASS | PASS | FAIL: blue-black hard line in the grooves. `P5_old_Q_near 600 200 60 300` |
| 6. Holds at distance | PASS | PASS | PASS (but at 5 m it is the same wall as few) |
| **grade** | **near the yardstick** | **game** | **game** |

**P vs Q (P5):** Q is better. A full grade at new (near vs game); within a grade at few (both game: Q is cleaner but
ageless, P ages a little but stipples); at old P is the better *age* (it is the only one that reads old) but still
the same grade. Overall Q, by a full grade at its best age, within a grade elsewhere.

**Best age:** Q new.
**The one change that would move it up most:** give Q's clean film P's sense of age, done as paint fails indoors:
yellowing by age, rubbed and darkened where hands and chairs go, scuffs low, and at old a coat that lets go in
strips and flakes at board ends and arrises (with a lifted film edge) instead of evenly spaced pinhead chips; and
drop the stucco stipple and contour "crack" lines entirely.

---

## P6: pale grey-green interior paint (a surgery's), narrow planed pine boards

### P6, set P

| check | new | few | old |
|---|---|---|---|
| 1. Real stuff | FAIL: stucco stipple boards and contour lines like crazing on a new coat. `P6_new_P_near 550 150 130 450` | FAIL: stipple and wandering crack lines across a board. `P6_few_P_near 665 0 90 300` | FAIL: stipple boards beside smooth. `P6_old_P_near 230 250 110 300` |
| 2. Age reads | FAIL: crack-like lines on the new coat. `P6_new_P_near 550 150 130 450` | FAIL: barely different from new. `P6_few_P_near 0 0 1400 780` | PASS: chips to wood along the beads, grime in the grooves, one board paler (reads as touched up); still no hand rub or low scuffs |
| 3. No tile tells | **FAIL**: stipple/mush on single boards. `P6_new_P_near 340 200 110 400` | **FAIL**: stipple patches. `P6_few_P_near 665 0 90 300` | **FAIL**: stipple boards, and the chips sprinkled like dots at a near-even spacing down every bead. `P6_old_P_near 150 250 300 300` |
| 4. Board to board | PASS | FAIL: rough/smooth alternation reads as stripes. `P6_few_P_near 1000 0 400 780` | FAIL: rough/smooth alternation. `P6_old_P_near 0 0 1000 780` |
| 5. Edges and joints | PASS | PASS | FAIL: hard blue-black lines in the grooves, drawn not shadowed. `P6_old_P_near 150 250 60 300` |
| 6. Holds at distance | PASS | PASS | PASS (chips and the bottom rail's brown blotches read as wear at 5 m) |
| **grade** | **game** | **game** | **game** |

### P6, set Q

| check | new | few | old |
|---|---|---|---|
| 1. Real stuff | PASS | PASS | FAIL: colour figure through the paint, reads as stained wood under lamplight. `P6_old_Q_saloon_night 0 0 1400 780` |
| 2. Age reads | PASS | FAIL: hardly different from new (a little grime in the grooves). `P6_few_Q_near 0 0 1400 780` | FAIL: some paler chalky boards, but no chips, flaking, rub or scuffs: not an old coat. `P6_old_Q_near 0 0 1400 780` |
| 3. No tile tells | **PASS** | **PASS** | **PASS** |
| 4. Board to board | PASS | PASS | PASS |
| 5. Edges and joints | PASS | PASS | FAIL: the bead's highlight is a dashed line, stitched along the groove. `P6_old_Q_near 1240 0 60 300` and `P6_old_Q_near 700 0 70 400` |
| 6. Holds at distance | PASS | PASS | PASS (same wall as few at 5 m) |
| **grade** | **near the yardstick** | **game** | **game** |

**P vs Q (P6):** Q is better, a full grade at new, within a grade at few and old (P is the only set whose old
reads old, Q the only one without tile tells).

**Best age:** Q new.
**The one change that would move it up most:** as P5: Q's film, aged the way an indoor coat ages (yellowing,
hand rub, low scuffs, flaking in strips at ends and arrises at old), without P's stipple or Q's dashed bead
highlight; keep the grain as relief only, not as colour through the paint.

---

## Summary

| swatch | set | new | few | old | better set |
|---|---|---|---|---|---|
| P5 | P | game | game | game | |
| P5 | Q | near the yardstick | game | game | Q (a full grade at new; within a grade at few and old) |
| P6 | P | game | game | game | |
| P6 | Q | near the yardstick | game | game | Q (a full grade at new; within a grade at few and old) |

Check 3 (No tile tells), per age:

| swatch | set | new | few | old |
|---|---|---|---|---|
| P5 | P | FAIL | FAIL | FAIL |
| P5 | Q | PASS | PASS | PASS |
| P6 | P | FAIL | FAIL | FAIL |
| P6 | Q | PASS | PASS | PASS |
