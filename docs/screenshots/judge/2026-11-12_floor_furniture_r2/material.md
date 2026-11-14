# Materials judge: 2026-11-12_floor_furniture_r2 (floors and furniture, sets P and Q)

Key (added after judging, from build/<round>.key.json): set P is round 1 (`2026-11-12_floor_furniture_r1`), set Q is round 2, at every swatch.

Blind judge. I read the rubric (`docs/concept/judge/MATERIAL.md`) and looked at the six yardstick screenshots
(RDR2 street noon, street golden and saloon night; Hunt street noon and saloon night; KCD2 street noon). Then I viewed
all 72 crops at full size, plus 2x nearest-neighbour zooms of a few joint, pull and arris regions. Crop boxes are
`x y w h` in the named crop: near and night crops are 1400x780, far crops are 560x360.

Yardstick, for wood only: RDR2's saloon floor and stair rails are worn, low-contrast boards. Grain is barely
visible at a distance, tone varies a little from board to board, the gaps are dark and soft, and the varnish has a
broken, uneven sheen. Hunt's planks are grey and dry, with soft, dirty arrises.

Note, given once: the sun's shadow under each chest's top overhang has a saw-toothed edge (e.g. FN1_new_P_near
`150 125 880 30`). It is the light's known fault and did not count against any check.

Note: in the saloon_night crops every chest front lit from above goes almost black. That is the light's doing. I
judged only the tops and what the lamplight does show.

---

## FL1: fir and pine floor boards, oiled, worn where feet go

### FL1, set P

| check | new | few | old |
|---|---|---|---|
| 1 Real stuff | **FAIL**: every board has a bold, high-contrast flat-sawn cathedral figure, like printed laminate or a deck. FL1_new_P_near `270 560 1060 60` | PASS: stained pine with knots and a softer figure | PASS |
| 2 Age reads | PASS: clean and pale, believable as new | **FAIL**: the foot path is a milky, cloudy haze laid over the boards, a smear rather than abraded, duller wood. FL1_few_P_near `150 380 550 300` | **FAIL**: same milky smear. FL1_old_P_near `150 400 500 280` |
| 3 No tile tells | PASS | PASS | PASS |
| 4 Board to board | PASS: the figure changes from board to board (tone varies little) | PASS | PASS |
| 5 Edges and joints | **FAIL**: nail heads are blue-grey dots in ruled rows. FL1_new_P_near `160 560 480 180` | **FAIL**: pale nail dots in rows, and joints with a beaded, rope-like edge. FL1_few_P_near `0 520 800 120` | **FAIL**: rope-textured, dashed joints and pale dot rows. FL1_old_P_near `0 570 800 120` |
| 6 Holds at distance | **FAIL**: a joint turns into a bright orange dashed line at 5 m. FL1_new_P_far `0 305 560 15` | **FAIL**: several bright dashed joint lines. FL1_few_P_far `0 285 560 30` | **FAIL**: three bright dashed joint lines. FL1_old_P_far `0 225 560 80` |
| **grade** | **game** | **game** | **game** |

### FL1, set Q

| check | new | few | old |
|---|---|---|---|
| 1 Real stuff | **FAIL**: the same bold laminate cathedral figure as P. FL1_new_Q_near `270 560 1060 60` | PASS | PASS |
| 2 Age reads | PASS | **FAIL**: the path is a milky haze or smear. FL1_few_Q_near `150 380 550 300` | **FAIL**: milky smear on the path. FL1_old_Q_near `150 400 500 280` |
| 3 No tile tells | PASS | PASS | PASS |
| 4 Board to board | PASS | PASS | **FAIL**: at 5 m the boards turn into evenly ruled dark-and-light stripes of one width. FL1_old_Q_far `0 95 560 200` |
| 5 Edges and joints | PASS: clean, dark, shadowed gaps with no drawn lines (face nails are gone altogether) | PASS | PASS: wider dark gaps, which suit the age |
| 6 Holds at distance | PASS | PASS | PASS: no shimmer (the stripes are under check 4) |
| **grade** | **game** | **game** (the strongest of the six) | **game** |

**FL1, P against Q:** Q is better. Q's joints are clean, shadowed gaps. P's are dashed and beaded, with nail dots,
and they flare into bright orange dashes at 5 m. Both grade game, so the difference is within a grade, but it is
the one a player sees first. Best age: Q few.
**The one change for FL1:** make the foot path real wear. It should be a duller, slightly paler band that follows
the grain, with grime packed darker at its edges and along the wall, not a milky haze laid over the boards. On new,
also turn the cathedral figure's contrast well down.

---

## FN1: oak, straight-grained stock, varnished (office furniture)

### FN1, set P

| check | new | few | old |
|---|---|---|---|
| 1 Real stuff | **FAIL**: there is no oak in it: no open pores, no ray fleck, a soft pine-like flat-sawn figure. It reads as a laminate chest. FN1_new_P_near `240 460 700 150` | **FAIL**: same. FN1_few_P_near `240 460 700 150` | **FAIL**: same. FN1_old_P_near `240 460 700 150` |
| 2 Age reads | PASS | **FAIL**: only darker than new, with no rubbing through at the edges or pulls and no dust on the top. FN1_few_P_near `150 130 890 170` | **FAIL**: a network of dark crackle lines like a map, stamped over the drawer faces and the rail. It reads as an overlay, not crazed varnish. FN1_old_P_near `150 130 890 170` |
| 3 No tile tells | PASS | PASS | **FAIL**: the crackle network is a pattern. FN1_old_P_near `150 130 890 300` |
| 4 Board to board | **FAIL**: the third drawer has a much coarser, busier figure than the rest, so it jumps out. FN1_new_P_far `75 240 310 85` | **FAIL**: same. FN1_few_P_far `75 240 310 85` | **FAIL**: same. FN1_old_P_far `75 160 310 160` |
| 5 Edges and joints | **FAIL**: pale, purple-tinged dashed highlight lines along the drawer and rail arrises. FN1_new_P_near `190 290 800 20` | **FAIL**: same. FN1_few_P_near `190 290 800 20` | **FAIL**: same. FN1_old_P_near `190 290 800 20` |
| 6 Holds at distance | **FAIL**: a dashed line under the top, and the busy drawer shimmers. FN1_new_P_far `60 85 340 10` | **FAIL**: same. FN1_few_P_far `60 85 340 10` | **FAIL**: same. FN1_old_P_far `60 85 340 10` |
| **grade** | **game** | **game** | **fake** |

### FN1, set Q

| check | new | few | old |
|---|---|---|---|
| 1 Real stuff | **FAIL**: a finer, softer figure, but still no oak pores or fleck. It reads as wood-grain melamine. FN1_new_Q_near `240 460 700 150` | **FAIL**: same. FN1_few_Q_near `240 460 700 150` | **FAIL**: same. FN1_old_Q_near `240 460 700 150` |
| 2 Age reads | PASS | **FAIL**: hardly changed from new apart from a deeper tone. FN1_few_Q_near `150 130 890 170` | PASS: grease darkens round each pull, the top is paler and duller, and the wear follows use |
| 3 No tile tells | PASS | PASS | PASS |
| 4 Board to board | PASS: the drawer fronts differ quietly | PASS | PASS |
| 5 Edges and joints | **FAIL**: pale dashed arris highlights. FN1_new_Q_near `190 290 800 20` | **FAIL**: same. FN1_few_Q_near `190 290 800 20` | **FAIL**: same. FN1_old_Q_near `190 290 800 20` |
| 6 Holds at distance | **FAIL**: the fronts go to a flat orange card with no grain left at 5 m, and the dashed line under the top shows. FN1_new_Q_far `640 95 320 230` | **FAIL**: same. FN1_few_Q_far `640 95 320 230` | **FAIL**: same, though the dark rings at the pulls do hold. FN1_old_Q_far `640 95 320 230` |
| **grade** | **game** | **game** | **game** |

**FN1, P against Q:** Q is better. At new and few the difference is within a grade: Q's fronts are calmer and
consistent, P's have more figure but one drawer jumps out. At old it is a full grade, because P's crackle map is a
stamped pattern and Q's grease at the pulls follows use. Best age: Q old.
**The one change for FN1:** make it oak. It needs a straight, quartered or rift figure with open pores and a ray
fleck that catches the light, and enough of it to survive 5 m. As it stands it reads as generic melamine.

---

## FN2: painted pine (slate grey-green oil paint): shelving, counters, plain pieces

### FN2, set P

| check | new | few | old |
|---|---|---|---|
| 1 Real stuff | PASS: a paint film over boards whose grain shows through. The hue reads more teal-blue than slate grey-green at noon, and the grain relief is a little deep and even, like embossed vinyl | PASS | PASS |
| 2 Age reads | **FAIL**: the coat is already chipped to bare wood at the arrises and below a pull when new. FN2_new_P_near `700 430 140 40` | PASS: chips at the edges and pulls | PASS: chipping round the pulls and along the arrises follows use; the chips show bare wood |
| 3 No tile tells | PASS | PASS | **FAIL**: the top is mottled with soft blue-grey clouds, a smear rather than dust or wear. FN2_old_P_near `120 0 950 90` |
| 4 Board to board | PASS | PASS | PASS |
| 5 Edges and joints | **FAIL**: a pale grey highlight line is drawn along each drawer's top arris. FN2_new_P_near `240 455 700 15` | **FAIL**: same. FN2_few_P_near `240 455 700 15` | **FAIL**: same. FN2_old_P_near `240 455 700 15` |
| 6 Holds at distance | PASS: holds as an olive painted chest; the chips at the pulls show | PASS | PASS |
| **grade** | **game** | **game** | **game** |

### FN2, set Q

| check | new | few | old |
|---|---|---|---|
| 1 Real stuff | PASS (the same note on hue and grain depth) | PASS | PASS |
| 2 Age reads | PASS: a sound, even coat with a low sheen | PASS | PASS: chips along the arrises, and grease darkening round the pulls instead of chips |
| 3 No tile tells | PASS | PASS | **FAIL**: the same cloudy mottle on the top. FN2_old_Q_near `120 0 950 90` |
| 4 Board to board | PASS | PASS | PASS |
| 5 Edges and joints | **FAIL**: a faint pale arris line. FN2_new_Q_near `240 455 700 15` | **FAIL**: same. FN2_few_Q_near `240 455 700 15` | **FAIL**: same. FN2_old_Q_near `240 455 700 15` |
| 6 Holds at distance | PASS | PASS: the dark rings round the pulls read a little as smudges | PASS |
| **grade** | **near the yardstick** | **game** | **game** |

**FN2, P against Q:** Q is better overall. At new it is a full grade, because P is chipped before it has been used.
At few the two sets are the same. At old it is within a grade, and P's chipping under the pulls is slightly the
more convincing. Best age: Q new.
**The one change for FN2:** take the drawn highlight off the arrises and let the edge wear show as the film rubbed
thin to a lighter, slightly yellowed undercoat. On old, swap the cloudy top mottle for dust and ring marks. Also
pull the hue toward grey-green and soften the grain relief.

---

## FN3: black walnut, varnished: one good piece a room

### FN3, set P

| check | new | few | old |
|---|---|---|---|
| 1 Real stuff | **FAIL**: thin, evenly spaced wavy stripes, a procedural "wood" noise with no walnut figure (cathedrals, sapwood, pores). It turns reddish mahogany or cherry at 5 m. FN3_new_P_near `240 470 700 140` | **FAIL**: same. FN3_few_P_near `240 470 700 140` | **FAIL**: same. FN3_old_P_near `240 470 700 140` |
| 2 Age reads | PASS | **FAIL**: almost the same as new, with no rubbed edges, dust or dull patches. FN3_few_P_near `150 130 890 170` | **FAIL**: only faint crackle hairlines and a slight darkening at the pulls; it hardly reads older. FN3_old_P_near `150 130 890 170` |
| 3 No tile tells | **FAIL**: the varnished top shows purple-grey cloud blotches, a smear rather than sheen. FN3_new_P_near `100 0 1000 100` | **FAIL**: same. FN3_few_P_near `100 0 1000 100` | **FAIL**: same. FN3_old_P_near `100 0 1000 100` |
| 4 Board to board | PASS: the fronts differ, and the third drawer's darker figure is believable | PASS | PASS |
| 5 Edges and joints | **FAIL**: pale dashed arris lines on the drawer tops. FN3_new_P_near `240 455 700 15` | **FAIL**: same. FN3_few_P_near `240 455 700 15` | **FAIL**: same. FN3_old_P_near `240 455 700 15` |
| 6 Holds at distance | PASS: keeps its grain at 5 m, if as a redder wood | PASS | PASS |
| **grade** | **game** | **game** | **game** |

### FN3, set Q

Q is almost pixel-identical to P. The only difference is at old, where Q has no crackle hairlines and a soft dark
halo at each pull. The checks are the same as for P, with the same boxes in the FN3_*_Q crops: 1 FAIL, 2 FAIL at few
and old, 3 FAIL, 4 PASS, 5 FAIL, 6 PASS.
**Grades:** new **game**, few **game**, old **game**.

**FN3, P against Q:** the sets are effectively the same. Q's old is marginally cleaner (no hairline crackle), but
the difference is within a grade. Best age: new.
**The one change for FN3:** give it a real walnut figure. It needs broad, irregular cathedrals and streaks, a pale
sapwood edge on a board, pores under the varnish and a deep cool brown that stays brown in warm light. Then let the
ages differ: the varnish rubbed dull on the top edge and round the pulls, and dust on the top.

---

## Summary

| swatch | set | new | few | old | better set |
|---|---|---|---|---|---|
| FL1 floor (fir/pine, oiled) | P | game | game | game | |
| FL1 floor (fir/pine, oiled) | Q | game | game | game | **Q**, within a grade (P's joints dash and glow at 5 m) |
| FN1 chest (oak, varnished) | P | game | game | fake | |
| FN1 chest (oak, varnished) | Q | game | game | game | **Q**, within a grade at new and few; a full grade at old |
| FN2 chest (painted pine) | P | game | game | game | |
| FN2 chest (painted pine) | Q | near the yardstick | game | game | **Q**, a full grade at new; the same at few; within a grade at old (P slightly better there) |
| FN3 chest (walnut, varnished) | P | game | game | game | |
| FN3 chest (walnut, varnished) | Q | game | game | game | about the same; Q marginally, within a grade |

The worst remaining tell for each swatch:
- **FL1:** the foot path is a milky haze smeared over the boards rather than abraded, duller wood. In P the joints
  also flare into bright orange dashes at 5 m.
- **FN1:** there is no oak in it. With no pores and no ray fleck it reads as wood-grain melamine, and P's old adds a
  stamped crackle map.
- **FN2:** a pale highlight line is drawn along every drawer arris, and old has a cloudy mottle on the top. P's new
  is also chipped before it has been used.
- **FN3:** evenly spaced procedural wavy stripes instead of a walnut figure, and the three ages are nearly identical.
