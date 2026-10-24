# People on Uthana's clips, 2026-10-24: a walk, the barkeep's chores, the trough

Sean's ask: five walks for five people, the barkeep's cloth and mop on proper animation, a man
scooping water from a trough, each filmed. Replicate's credit ran out after the chores and two
takes of the old man's walk (issue #347), and Sean said to do the ones we have. Films by
`experiments/motion_films/film.sh` (Godot's Movie Maker under lavapipe, through the dev bridge).

| Film | What | Clip (take) |
|---|---|---|
| `walks.mp4` | the old man's walk across the street at 17:30, Earl (old_rancher) on `walk_old`, `HumanBody.walk_clip`: the clip looped under his walking, its rate his speed | `walk_old` (2 of 2: 1.1 m in 5 s, the steadier; take 1 jittered) |
| `barkeep.mp4` | the barkeep at 11:00: his cloth on the bar (`WipeBar`, the clip under it for his body, his working arm the deed's IK on the real bar top), then his mop (`MopFloor`, the same way, both hands the deed's on the real handle) | `wipe_bar` (3 of 3: stillest feet), `mop_floor` (3 of 3: least travel, least slide) |
| `trough.mp4` | Colter at the store's trough at 17:30: `scoop_water` once, a splash of the trough's water at his hands at the clip's mark (his hands highest, 4.1 s in) | `scoop_water` (2 of 3: bends lowest without walking off; take 3 wandered a metre) |

The other four walks (swagger, nervous, drunk, brisk) are in `config/walks.json` and the line-up
moment (`config/moments/walks_lineup.json`) ready for their clips; the line-up shows only the
walks that exist.
