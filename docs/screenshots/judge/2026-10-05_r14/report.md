# 2026-10-05_r14: new targets (saloon-blocks, street-blocks): today's default, the baseline

## shot_match_saloon (score 0.331, lower is closer)

![saloon](saloon_judge.png)

- 1.1 midtones too dark (11 vs 23)
- 0.8 too much deep shadow (0.26 vs 0.18)
- 0.8 bright things too dim (51 vs 58)
- 0.6 colour too weak (chroma) (21 vs 26)
- 0.5 the brightest too dim (76 vs 80)
- 0.4 palette: colours the painting lacks (2.4 dE)
- 0.3 too blue/grey (b*) (15 vs 18)
- 0.3 palette: painting colours we lack (1.8 dE)

## shot_match_street (score 0.326, lower is closer)

![street](street_judge.png)

- 1.3 bright things too pale (chroma-L* correlation) (0.31 vs 0.57)
- 0.8 shadows too light (14 vs 6)
- 0.5 too little deep shadow (share under L* 10) (0.04 vs 0.09)
- 0.4 bright things too bright (76 vs 71)
- 0.4 palette: colours the painting lacks (2.6 dE)
- 0.4 near tiles finer than the painting's (5.5 vs 6.4 px)
- 0.3 block edges too hard (0.36 vs 0.33)
- 0.3 palette: painting colours we lack (1.6 dE)
