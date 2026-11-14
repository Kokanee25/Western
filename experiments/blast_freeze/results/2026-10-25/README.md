# 2026-10-25: the stick in the burning spec saloon, before and after

`bf_blast at=6.0,0.8,6.0 fire=6 burn=20 fuse=1 seconds=8`, headless, `--fixed-fps 60`, this
workspace's 2.1 GHz core (x0.65 for Sean's). The town's 17 people in. `r1_fire.json` is main at
c543efd (before); `r9_fire_inc.json` the fix (eight runs r2-r9 along the way gave the same broken
set, hash 1650757771). Each file: the headline, the setup, the frames from 5 before the stick to
10 after (the full trace was ~1 MB a run; rerun the command for it).

| | Stick's frame | In it | Cuts | Pieces at 8 s | Frames after: mean / worst |
|---|---|---|---|---|---|
| before | 11,599 ms | settle_analyse 10,195, settle_apply 982 | 22 | 255 | 37.9 / 365 ms |
| after | 241 ms | blast_break 102, blast_fx 21, blast_response 21, blast_gather 14 | 22 | 255 | 45.5 / 262 ms |

The collapse's rounds now run in the frames after (done 3.6 s on); the frames over 77 ms after the
stick (67 of 480) are mostly `civilian_brain` (townsfolk and the fire) and the fire's own periodic
work, which were there before too (29 of 480 then, with less fire left after the one long frame).
