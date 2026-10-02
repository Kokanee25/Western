# 2026-10-02_r51: ART_REVIEW §10.10: native by default (the window is 1280x720 here), the finish pass on (edges softened 0.5, tile light gradient 0.3)

## shot_match_saloon (score 0.208, lower is closer)

![saloon](saloon_judge.png)

- 0.6 too much deep shadow (0.47 vs 0.41)
- 0.5 far tiles chunkier than the painting's (7.6 vs 6.2 px)
- 0.4 block edges too hard (0.29 vs 0.25)
- 0.3 colour too weak (chroma) (20 vs 23)
- 0.3 too blue/grey (b*) (14 vs 17)
- 0.3 bright things too pale (chroma-L* correlation) (0.79 vs 0.85)
- 0.3 bright things too bright (46 vs 44)
- 0.2 midtones too dark (11 vs 12)

## shot_match_street (score 0.328, lower is closer)

![street](street_judge.png)

- 1.5 bright things too pale (chroma-L* correlation) (0.27 vs 0.57)
- 0.5 block edges too hard (0.37 vs 0.33)
- 0.4 bright things too bright (76 vs 71)
- 0.4 shadows too light (10 vs 6)
- 0.4 too little deep shadow (share under L* 10) (0.05 vs 0.09)
- 0.4 midtones too bright (41 vs 37)
- 0.4 palette: colours the painting lacks (2.3 dE)
- 0.3 near tiles finer than the painting's (5.7 vs 6.4 px)
