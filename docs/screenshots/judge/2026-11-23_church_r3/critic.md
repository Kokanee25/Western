# The church: the blind critic, round 3, 2026-11-23

Each pair image puts the target (reference photo or painting) on the left (x 0-900) and the game render on the right (x 910-1810). Crops are "x y w h" in pair-image pixels.

## Grades

| View | Grade | Why |
|---|---|---|
| front | CLOSE | It is the right building type: a white gable-front frame church with a centre tower, a spire, lancet windows either side and peeling paint. But the render has no projecting gabled entry porch, no double doors, no steps, no hand railings and no stone foundation. Its tower and spire are also much taller and thinner. |
| side | CLOSE | The nave matches well: a long gable, four pointed-arch windows, worn white clapboard and the tower at the end. The render has no rear wing or transept, no chimney and no raised stone-pier foundation, and its roof is warm brown where the target's is grey weathered shingle. |
| tower | CLOSE | Both towers have a belfry with a pointed opening, a visible bell, a pyramid spire and a cross or finial. The render's belfry has only the one opening, with no louvred openings beside it. It also lacks the flared, shingled skirt roof between the base and the belfry (a thin dark cornice band stands in for it), and its spire is darker and steeper. |
| nave | CLOSE | The layout is right: two banks of pews, a centre aisle, pointed windows down both sides, a pulpit and rail at the end, and a plank floor. But the render's pews are painted sage green, not natural wood. Its walls are vertical boards, not horizontal. Its ceiling is a flat board ceiling with a dark band instead of exposed tie beams with hanging lanterns. The stove that stands in the room is missing. |
| pulpit | CLOSE | Both have a box pulpit on a raised platform behind a rail, with a stove in the corner, a hymn board and wall lamps. In the render the pulpit and rail are painted green. The hymn board is a blank orange board on an easel, not a wall-mounted board with numbers. The stove is a dark column hidden in the corner, and the platform has an odd gap cut into its front. |
| graveyard | CLOSE | Both show a picket-fenced yard of crosses and headstones with the church beyond. The render's markers are laid out in a sparse, tidy grid of clean pale wood, each on a round dirt disc, on bare flat ground. The target is crowded, weathered and grown over with sagebrush. |
| grave | CLOSE | Ignoring the open grave, the setting is the same kind of place: crosses with nameboards, rounded headstones, a fence and the church behind. The render's crosses are clean grey-white instead of dark sun-worn wood, there is no brush, and the church sits much farther off and smaller. |

**Totals: 0 SAME, 7 CLOSE, 0 DIFFERENT.**

## The five biggest differences

1. **The interior is painted green.** In the render the pews, communion rail and pulpit are all sage-green paint. In the target they are honey-coloured natural wood, and this changes the whole mood of the room.
   Target: nave `45 250 820 250`, pulpit `0 300 620 160`. Render: nave `910 280 900 220`, pulpit `1020 200 680 230`.
2. **The front has no entry porch.** The target's facade is dominated by a projecting gabled vestibule with arched double doors, wooden steps, iron hand railings and a stone foundation. The render shows a plain open doorway set in the flat gable wall, with the interior visible through it.
   Target: front `255 255 150 180`. Render: front `1325 280 90 100`.
3. **The steeple has a different shape.** The target's tower is short and stocky, with a louvred belfry, a flared shingled skirt roof under it and a short grey spire. The render's tower is tall and narrow, with a single-opening belfry, a thin dark band where the skirt roof should be and a tall dark spire.
   Target: tower `150 140 640 800`, front `290 10 115 180`. Render: tower `1220 30 280 320`, front `1310 35 100 180`.
4. **The walls, ceiling and windows inside are different.** The target has horizontal clapboard walls, exposed tie beams with hanging lanterns, and slim round-pointed arched sash windows. The render has vertical board walls and a flat board ceiling with a dark band across it. Its windows are flat-topped sashes under a separate pointed hood, and their frames look shredded.
   Target: nave `100 0 700 140`, window `740 55 70 225`. Render: nave `990 0 720 140`, window `1640 40 90 270`.
5. **The graveyard looks clean and sparse.** In the render the markers are pale, evenly spaced on bare graded dirt, and each sits on a round dark disc. The target's markers are dark, sun-worn crosses with nameboards and grey headstones, crowded among sagebrush on cracked ground.
   Target: graveyard `0 130 560 200`, grave `40 60 560 160`. Render: graveyard `920 260 880 240`, grave `910 250 600 120`.
