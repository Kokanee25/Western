# Materials judge: P3, new (ox-blood red, iron oxide in linseed oil, rough-sawn board and batten)

Blind judge, 2026-11-11. Rubric `docs/concept/judge/MATERIAL.md` (painted wood). Yardstick: the RDR2,
Hunt: Showdown 1896 and KCD2 screenshots' wood, bare and painted (RDR2's boardwalk and saloon
woodwork, Hunt's grey boat ribs and sheds, KCD2's plank gables and painted render). Crops: `near` =
1 m at noon (1400 x 780), `far` = 5 m at golden hour (560 x 360). Boxes are `x y w h` in that crop's
pixels.

Light fault (not graded, noted once): the batten's cast shadow has a saw-toothed edge in both near
crops (`P3_new_*_near.png` 75 0 140 780 and 440 0 40 780). Left out of every check below.

The colour shift between near (dark maroon) and far (orange-red) is the light's colour, so it is not
graded either.

## Set P

| # | check | result | evidence / note |
|---|---|---|---|
| 1 | Real stuff | PASS (weakly) | Near: reads as a dense oil coat on boards: fine sawn striation and a knot (`near` 150 30 80 80) show through under it. But the coat is so even and smooth over most of the right half that rough-sawn stock reads as planed or MDF (`near` 700 0 700 780). |
| 2 | Age reads (new) | PASS | A sound, even coat with a low, flat sheen: no chalk, cracks or dirt. Believable as freshly painted. |
| 3 | No tile tells | **FAIL** | Embossed blob outlines on the left board: smooth plateaus with a hard rim, like a stamp, not raised grain (`near` 0 400 140 360). They are faint, so you only find them if you look. No repeat, weave or blocks. |
| 4 | Board to board | PASS (weakly) | The widths differ (batten against board) and one board has a knot. Otherwise the boards are almost identical in tone and texture, and only their joint lines separate them (`near` 470 0 930 780). In the far crop every board is the same flat value. |
| 5 | Edges and joints | **FAIL** | The joints read as lines drawn on: a 1-2 px dark hairline runs the full height with no shadow or arris (`near` 640 0 60 780), and two more joints are crisp, even-width dark stripes (`near` 890 0 150 780, `near` 1140 0 230 780). In the far crop the battens don't stand proud. Each joint is a single dark line (`far` 225 0 30 360). |
| 6 | Holds at distance | **FAIL** | At 5 m the grain is almost gone. Each board is a flat orange card divided by dark lines (`far` 160 20 230 330), as the rubric's "flat card" describes. No shimmer. |

**Grade: game.** It reads as painted boards, with clear tells: flat cards at 5 m and drawn-line
joints.

**The one change:** give the coat back the board's surface. Let the rough-sawn tooth and the grain
relief telegraph through the paint enough to survive at 5 m, as RDR2's boardwalk and Hunt's boards
keep their texture at distance. That fixes the far crop's flat cards and the near crop's planed look
together.

## Set Q

| # | check | result | evidence / note |
|---|---|---|---|
| 1 | Real stuff | PASS | Near: rough-sawn tooth and torn-grain ridges telegraph through a film of paint (`near` 460 0 300 780; knot `near` 150 30 80 80). It reads as paint brushed onto sawn stock. This is the right material. |
| 2 | Age reads (new) | PASS | Even, sound coat with a low sheen. No chalking or failure. Reads as new. |
| 3 | No tile tells | **FAIL** | A pale hairline runs the full height of the board at the joint (`near` 640 0 60 780). It is plainly a drawn line, visible without hunting. A fainter pale hairline marks the next joint (`near` 920 150 110 630). The embossed blob outlines on the left board are stronger than in P (`near` 0 400 140 360). |
| 4 | Board to board | PASS | The boards differ in roughness and figure: the sawn board at 460-760 is coarser than its neighbour, and the far crop's figure changes from board to board. They don't read as noise or as stripes. |
| 5 | Edges and joints | **FAIL** | The same joint is now a bright outline, which the rubric names as a fail (`near` 640 0 60 780). The joint at about 930-1030 has almost vanished, and two boards merge into one surface (`near` 900 0 160 780). In the far crop the joints are single dark lines and the battens show no proud edge (`far` 225 0 30 360). |
| 6 | Holds at distance | PASS | At 5 m the boards keep figure and texture, with no shimmer or mush (`far` 70 20 400 330). The figure is a little too legible and swirly for painted sawn stock and comes close to embossed-woodgrain siding, but it holds. |

**Grade: game** (top of game). The material itself is close to the yardstick. The tells are the
joints.

**The one change:** draw each joint as a gap: a narrow dark groove with a shadowed side and a softly
lit, slightly rounded arris. Remove the pale hairline, and don't let a joint fade out. Then the
joints read like the RDR2 boardwalk's. With that and the blob outlines softened, Q would be near the
yardstick.

## Which is better

**Q is better, but within the same grade (game), not by a full grade.**

- Q's coat reads as paint on rough-sawn wood near and far.
- P is smooth near and a flat card far.

Q's pale full-height hairline is the more visible single tell, though. P's joints are drawn too, but
dark lines look less wrong than a bright one.

## Summary

| set | 1 Real stuff | 2 Age reads | 3 No tile tells | 4 Board to board | 5 Edges and joints | 6 Holds at distance | grade |
|---|---|---|---|---|---|---|---|
| P3 new, P | PASS (weak) | PASS | FAIL | PASS (weak) | FAIL | FAIL | game |
| P3 new, Q | PASS | PASS | FAIL | PASS | FAIL | PASS | game (top), better than P within the grade |
