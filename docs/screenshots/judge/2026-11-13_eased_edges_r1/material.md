# Materials judgment: round 2026-11-13_eased_edges_r1

Blind judge. Rubric: `docs/concept/judge/MATERIAL.md`. Yardstick: RDR2 (street noon, golden, saloon
night), Hunt: Showdown 1896 (street noon, saloon night), KCD2 (street noon), the wood only. Crop
boxes are `x y w h` in the named crop's own pixels.

**Noted once (not counted):** the saw-toothed edge of the sun's shadow is visible along the laps
(C1 near, every lap), along the battens (R1 near, x 90-220 and 450-480) and across the floor in
the F2 noon_rail crops. It does not fail any check below.

**P and Q:** in every swatch the boards' faces are the same; P and Q differ only at the edges
(laps, battens, board joints) and in the rail's section (round or square) in the F2 rail and far
crops.

---

## C1: Planed pine lap siding

### C1 new, set P
1. Real stuff: **FAIL**. The growth rings are embossed and fuzzy, like wire-brushed or
   sandblasted ash, and their contrast is very high. Planed pine is smooth, with a quieter figure.
   The nail heads are flat grey dots that look like stickers. Evidence: C1_new_P_near `0 480 500 120`;
   nails C1_new_P_near `415 185 40 30`.
2. Age reads: PASS. Next to old it is clearly the fresh board: honey colour, no checks, bright nails.
3. No tile tells: PASS. No repeat or seam at 1 m.
4. Board to board: PASS. The figure changes board by board (cathedrals, straight grain). The tone
   barely varies (every board is the same honey), so this passes only just.
5. Edges and joints: PASS. The laps read as shadowed steps, and the eased edges catch a little light.
6. Holds at distance: **FAIL**. At 5 m the laps thin to hairlines while the grain keeps its full
   contrast, so the wall reads as a flat print of wood, a veneer card rather than lapped boards.
   Evidence: C1_new_P_far `0 150 560 120`.

**Grade: game.**

### C1 new, set Q
Same face as P, with checks 1 and 6 failing for the same reasons (C1_new_Q_near `0 480 500 120`,
C1_new_Q_far `0 150 560 120`). Checks 2-5 PASS. The lap's eased edge catches a touch more light
than P's (C1_new_Q_near `300 225 120 25`).
**Grade: game.**

### C1 old, set P
1. Real stuff: **FAIL**. The checks are black ink squiggles of one even width, drawn on rather than
   split into the wood. There are purple-blue blotches in the grey that weathered pine doesn't
   have. Evidence: C1_old_P_near `860 130 170 30` (check), `1020 285 380 30` (check),
   `300 400 220 70` (blotches).
2. Age reads: PASS. It is clearly older than new and believable for the desert in its broad terms:
   sun-greyed, checked, dirty under the laps, rust-streaked nails.
3. No tile tells: PASS.
4. Board to board: PASS. Tone and checking vary per board.
5. Edges and joints: PASS. The laps read as a soft, eased, slightly lighter arris over a shadowed
   step.
6. Holds at distance: PASS. The character holds at 5 m with no shimmer. The drawn checks become
   even louder black squiggles (C1_old_P_far `150 195 330 30`), which is check 1's fault again.

**Grade: game.**

### C1 old, set Q
The face is the same as P, so check 1 fails for the same reason (C1_old_Q_near `860 130 170 30`,
`300 400 220 70`). Checks 2-6 PASS. Under each lap butt Q has a crisper, deeper shadow line than
P (C1_old_Q_near `300 230 120 25`), so the laps read a little more as real gaps.
**Grade: game.**

**C1, P or Q:** Q is better, but only within the grade. Its laps read a hair deeper at both ages,
and nothing else changes.
**Best age:** old. Weathered pine hides the face's faults better than new pine does.
**The one change:** make the face read as planed pine. That means a smooth surface, growth rings
at about half today's contrast, and no embossed or fuzzy relief. The same goes for old: checks
should be shadowed splits that vary in width, not ink lines.

---

## F2: Black walnut, narrow tongue and groove, varnished

### F2 new, set P
1. Real stuff: **FAIL**. The quiet boards read as a figured hardwood, but more red mahogany than
   walnut's chocolate-grey. The coarse boards carry a combed, dragged figure with bright copper
   flecks that no walnut board has. Varnish shows only on the round rail: the wall is matte at
   noon and under the lamp. Evidence: F2_new_P_near `450 250 200 330`, `820 100 180 400`.
2. Age reads: PASS. A sound, even coat. The rail has a clean varnish sheen
   (F2_new_P_noon_rail `300 100 500 60`).
3. No tile tells: PASS.
4. Board to board: PASS. The figure varies strongly from board to board. The tones are close, as
   in matched stock.
5. Edges and joints: PASS. The joints are tight shadowed V lines. The far rail is a moulded profile
   that reads as a real moulding.
6. Holds at distance: PASS. At 5 m the boards keep their figure and joints with no mush.
   Saloon night: it reads as dark lamplit hardwood, with no faults beyond check 1.

**Grade: game.**

### F2 new, set Q
1. Real stuff: **FAIL**, the same boards as P (F2_new_Q_near `450 250 200 330`). Q's rail is a square
   plank, matte and plain, and reads less like varnished walnut than P's turned rail
   (F2_new_Q_noon_rail `0 60 1920 140`).
2. Age reads: PASS.
3. No tile tells: PASS.
4. Board to board: PASS.
5. Edges and joints: **FAIL**. At 5 m the rail's top edge is a thin pale lavender line, a
   coloured outline rather than a lit arris. Evidence: F2_new_Q_far `0 322 560 8`.
6. Holds at distance: PASS.

**Grade: game.**

### F2 old, set P
1. Real stuff: **FAIL**. The craze is a web of fine dark contour-map lines stamped over the boards
   (and over the rail). Old varnish crazes along the grain in short checks and yellows; it doesn't
   do this. Evidence: F2_old_P_near `380 300 180 180`; F2_old_P_noon_rail `0 80 1000 120`.
2. Age reads: **FAIL**. It is clearly different from new: darker, crazed, one paler replaced
   board. But the hand wear on the rail is drawn as pale outlined ellipses, rings rather than a
   rubbed-through patch. Evidence: F2_old_P_noon_rail `580 90 450 60`, `1460 120 420 70`.
3. No tile tells: PASS.
4. Board to board: PASS. The one lighter board (F2_old_P_near `700 0 130 780`) reads as a
   replacement, which is good.
5. Edges and joints: **FAIL**. At 5 m the square rail's top edge is a pale lavender line, the same
   fault as F2 new Q. Evidence: F2_old_P_far `0 320 560 8`.
6. Holds at distance: PASS. Saloon night: the craze web is still faintly visible, but the face
   reads.

**Grade: game.**

### F2 old, set Q
1. Real stuff: **FAIL**. It has the same craze web (F2_old_Q_near `380 300 180 180`), and it shows more
   on the round rail (F2_old_Q_noon_rail `0 90 1920 120`).
2. Age reads: **FAIL**. It has the same outlined wear rings on the rail
   (F2_old_Q_noon_rail `560 100 470 70`).
3. No tile tells: PASS.
4. Board to board: PASS.
5. Edges and joints: PASS. The round rail has a varnish sheen and a shadowed underside, and the
   far rail is a moulding with no coloured line.
6. Holds at distance: PASS.

**Grade: game.**

**F2, P or Q:** whichever set has the turned (round) rail is better: P for new, Q for old. Its
sheen sells the varnish, and the square rail brings a coloured edge line at 5 m. The difference
is within the grade.
**Best age:** new.
**The one change:** give the finish a film. The boards need a low, broken varnish sheen (they are
matte now) that dulls and wears through to the wood where hands go. That should replace the
stamped craze web and the outlined wear rings.

---

## R1: Rough-sawn pine, board and batten

### R1 new, set P
1. Real stuff: **FAIL**. There are no saw marks, torn fibres or fuzz. The surface reads planed and
   wire-brushed, and the big cathedral figure is graphic, like rotary-cut plywood. The nails are
   flat grey dots. Evidence: R1_new_P_near `1080 0 300 500`; nails `575 270 30 25`.
2. Age reads: PASS. Next to old it is clearly the new board.
3. No tile tells: **FAIL**. The grain folds into zigzag chevrons across one board, an artefact of
   the texture warping. Evidence: R1_new_P_near `480 390 200 150`; also `620 280 120 50`.
4. Board to board: PASS. Width and figure vary.
5. Edges and joints: PASS. The battens stand proud with a shadowed edge.
6. Holds at distance: PASS. The battens and boards read at 5 m, though as new planed boards.

**Grade: game.**

### R1 new, set Q
The face is the same as P: check 1 fails (R1_new_Q_near `1080 0 300 500`) and check 3 fails
(R1_new_Q_near `480 390 200 150`). Checks 2, 4, 5 and 6 PASS. The batten edges carry a slightly
darker line (R1_new_Q_near `740 250 40 170`).
**Grade: game.**

### R1 old, set P
1. Real stuff: PASS. This is the best face in the round: grey, sun-checked pine with raised grain,
   open checks, knots and dirt. It reads like the yardstick's old boards (Hunt's hull planks).
   Rust nail heads are flat orange dots (R1_old_P_near `170 355 30 30`), a small tell.
2. Age reads: PASS. It is believable for the desert.
3. No tile tells: **FAIL**. At 5 m there is a horizontal step in one board where the texture's
   tone jumps, a seam. Evidence: R1_old_P_far `400 85 80 25`.
4. Board to board: PASS.
5. Edges and joints: **FAIL**. Several battens' edges dissolve into the boards, so at 1 m the wall
   reads as one surface rather than boards with battens over them. Evidence:
   R1_old_P_near `620 0 140 780`, `940 0 170 780`.
6. Holds at distance: PASS. Golden light warms it, but the character holds with no shimmer.

**Grade: game.**

### R1 old, set Q
1. Real stuff: PASS.
2. Age reads: PASS.
3. No tile tells: **FAIL**. It has the same seam as P (R1_old_Q_far `400 85 80 25`).
4. Board to board: PASS.
5. Edges and joints: PASS. Each batten edge has a shadowed dark line, so the battens read as
   separate members (R1_old_Q_near `690 0 60 780`).
6. Holds at distance: PASS.

**Grade: game**, at the top of it. At 1 m it is near the yardstick; the seam at 5 m holds it back.

**R1, P or Q:** Q, and at old it is nearly a full grade. P's batten edges dissolve; Q's read. At new
the difference is only a hair.
**Best age:** old.
**The one change:** give new a real rough-sawn face: kerf marks across the board, torn fibre and
mill fuzz, with the figure brought down under them. New is the age far behind old. (For old, fix
the seam in the far texture.)

---

## Summary

| Swatch | Set | Real | Age | Tiles | Boards | Edges | Distance | Grade | Better set |
|---|---|---|---|---|---|---|---|---|---|
| C1 new | P | FAIL | PASS | PASS | PASS | PASS | FAIL | game | |
| C1 new | Q | FAIL | PASS | PASS | PASS | PASS | FAIL | game | Q, within grade |
| C1 old | P | FAIL | PASS | PASS | PASS | PASS | PASS | game | |
| C1 old | Q | FAIL | PASS | PASS | PASS | PASS | PASS | game | Q, within grade |
| F2 new | P | FAIL | PASS | PASS | PASS | PASS | PASS | game | P, within grade |
| F2 new | Q | FAIL | PASS | PASS | PASS | FAIL | PASS | game | |
| F2 old | P | FAIL | FAIL | PASS | PASS | FAIL | PASS | game | |
| F2 old | Q | FAIL | FAIL | PASS | PASS | PASS | PASS | game | Q, within grade |
| R1 new | P | FAIL | PASS | FAIL | PASS | PASS | PASS | game | |
| R1 new | Q | FAIL | PASS | FAIL | PASS | PASS | PASS | game | Q, by a hair |
| R1 old | P | PASS | PASS | FAIL | PASS | FAIL | PASS | game | |
| R1 old | Q | PASS | PASS | FAIL | PASS | PASS | PASS | game (top; near at 1 m) | Q, nearly a full grade |

## Unblinded (#873, after the judge wrote the above)
`key_unblinded.json`: Q is after (eased edges, the handrail profile) everywhere but F2 new, where P is. The
judge preferred the after set on all six swatches; Edges passes after on all six (before failed F2 new and
R1 old); R1 old after nearly a full grade better ("game, top; near at 1 m"). Grades otherwise unchanged
(game): the tells left are the scans' own (embossed grain, inked checks, no varnish film), not the edges.
