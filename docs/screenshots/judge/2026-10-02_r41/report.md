# 2026-10-02_r41: ART_REVIEW §10.6 part 2e: the ground's wrapped sun done right (Godot's light() takes LIGHT_COLOR as energy/PI and applies the albedo after; 2d doubled both); saloon as 2d

## shot_match_saloon (score 0.212, lower is closer)

![saloon](saloon_judge.png)

- 0.6 bright things too bright (50 vs 44)
- 0.5 block edges too hard (0.30 vs 0.25)
- 0.5 bright things too pale (chroma-L* correlation) (0.76 vs 0.85)
- 0.5 far tiles chunkier than the painting's (7.5 vs 6.2 px)
- 0.2 too little deep shadow (share under L* 10) (0.39 vs 0.41)
- 0.2 colour too weak (chroma) (21 vs 23)
- 0.2 palette: painting colours we lack (1.2 dE)
- 0.2 too blue/grey (b*) (15 vs 17)

## shot_match_street (score 0.418, lower is closer)

![street](street_judge.png)

- 1.3 too much blown highlight (share over L* 80) (0.057 vs 0.017)
- 1.1 bright things too pale (chroma-L* correlation) (0.34 vs 0.57)
- 0.9 bright things too bright (81 vs 71)
- 0.4 palette: painting colours we lack (2.5 dE)
- 0.4 shadows too light (10 vs 6)
- 0.4 too little deep shadow (share under L* 10) (0.05 vs 0.09)
- 0.4 palette: colours the painting lacks (2.4 dE)
- 0.4 midtones too dark (33 vs 37)
