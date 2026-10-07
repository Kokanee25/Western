# The character judge's rounds (tools/characters/judge_man.py)

| Round | Note | Score | Light | Colour | Squares | Biggest differences |
|---|---|---|---|---|---|---|
| 2026-10-06_r1 | this morning: squares painted into his 2048 atlas, lit smoothly across them | 0.478 | 0.804 | 0.273 | 0.263 | face: lit parts too bright (65 vs 41); too much deep shadow (0.76 vs 0.53); bright parts too bright (48 vs 37) |
| 2026-10-06_r2 | now: his texture a texel a square, each square lit as one | 0.471 | 0.746 | 0.275 | 0.309 | too much deep shadow (0.76 vs 0.53); face: lit parts too bright (62 vs 41); squares flatter than the painting's (one tone, edge to edge) (0.76 vs 0.65) |
| 2026-10-06_r3 | soft squares: each square calmed toward its near-coloured neighbours, its edge texels leaning toward the next (body and hair three texels a square) | 0.410 | 0.724 | 0.279 | 0.142 | too much deep shadow (0.76 vs 0.53); face: lit parts too bright (62 vs 41); bright parts too bright (46 vs 37) |
| 2026-10-06_r4 | the long hair taken off (Sean: it looked silly); his own short hair from his picture | 0.414 | 0.757 | 0.259 | 0.132 | face: lit parts too bright (68 vs 41); too much deep shadow (0.74 vs 0.53); bright parts too bright (48 vs 37) |

From here the painting is `docs/concept/saloon-blocks.png`, DESIGN.md §4's saloon target since 2026-10-05: the same man, pose and framing, lit brighter and more evenly, in bolder squares. The rounds above were judged against `saloon-night.png`, so their scores don't compare. Round r4's man against `saloon-blocks.png`: 0.666.

| Round | Note | Score | Light | Colour | Squares | Biggest differences |
|---|---|---|---|---|---|---|
| 2026-10-07_r1 | round r4's man (squares calmed and soft, no long hair) under the art session's merge-2 light (its ViewerFill and eye gain, applied for the render only) | 0.631 | 0.831 | 0.663 | 0.358 | face: lit parts too bright (79 vs 55); bright parts too bright (73 vs 53); squares flatter than the painting's (one tone, edge to edge) (0.74 vs 0.59) |
| 2026-10-07_r2 | the weave: a tweed drawn square by square on his coat, vest and trousers (0.2), felt on his hat (0.15), his head's squares 9 mm; the same light as r1 | 0.596 | 0.815 | 0.651 | 0.280 | face: lit parts too bright (79 vs 55); bright parts too bright (73 vs 53); face: too bright (43 vs 29) |
| 2026-10-07_r3 | r2's man without the art session's light (the branch as it stands; r4's man so: 0.666) | 0.644 | 1.202 | 0.469 | 0.117 | too much deep shadow (0.75 vs 0.31); face: lit parts too bright (69 vs 55); coat: too dark (3 vs 17) |
| 2026-10-07_r4 | his face back in the painting's style (Sean: too cartoony): his paint worn on the Rodin man as made (people.json shape), his eyes at their own size in warm whites, no darker-part rule or calm on his head, the painter's light kept in his skin, his face's squares 7 mm; the same light as r1 | 0.570 | 0.794 | 0.671 | 0.206 | face: lit parts too bright (78 vs 55); bright parts too bright (72 vs 53); face: too bright (41 vs 29) |
