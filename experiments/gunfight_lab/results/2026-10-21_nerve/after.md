# Gunfight lab: 360 fights (build/gunfight_lab/fix3d)

Source ef65876, 4.7.2.stable.official.ed1daf0bf, fights capped at 180.0 s.

### By bodies

| bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|
| studio | 360 | 10.1 (5.7–18.8) | 5% | 66% | 32% | 2.9 (39%) | 2.1 / 1.3 | 2.7 / 3.4 | 14.9 | 4.0 | surrendered 32%, you_down 31%, fled 18%, down 10%, broke_off 7%, dead 2% |

### By arena, hour and gun (the three styles pooled)

| scenario | hour | weapon | bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ambush | golden | revolver | studio | 30 | 9.7 (6.3–21.3) | 0% | 63% | 87% | 2.4 (7%) | 1.6 / 2.3 | 2.5 / 5.0 | 23.5 | 3.1 | you_down 63%, surrendered 20%, down 10%, fled 3%, broke_off 3% |
| ambush | golden | shotgun | studio | 30 | 11.9 (6.2–19.8) | 10% | 60% | 87% | 2.4 (3%) | 1.6 / 2.4 | 2.0 / 5.3 | 23.7 | 3.2 | you_down 63%, surrendered 27%, down 7%, dead 3% |
| ambush | night | revolver | studio | 30 | 11.7 (7.5–17.1) | 0% | 70% | 93% | 3.0 (3%) | 1.7 / 2.6 | 1.9 / 5.0 | 25.5 | 3.0 | you_down 73%, surrendered 10%, fled 7%, down 7%, broke_off 3% |
| ambush | night | shotgun | studio | 30 | 12.0 (7.0–18.4) | 3% | 60% | 93% | 3.0 (7%) | 1.4 / 2.5 | 1.4 / 5.8 | 26.6 | 3.2 | you_down 70%, surrendered 13%, down 10%, fled 7% |
| saloon | golden | revolver | studio | 30 | 6.0 (3.8–12.1) | 3% | 87% | 0% | 2.1 (37%) | 2.5 / 1.1 | 3.3 / 2.7 | 15.2 | 2.8 | surrendered 40%, you_down 23%, fled 13%, down 13%, dead 10% |
| saloon | golden | shotgun | studio | 30 | 5.8 (5.6–6.9) | 0% | 97% | 0% | 2.0 (70%) | 2.4 / 0.4 | 2.4 / 0.6 | 4.4 | 4.0 | fled 53%, surrendered 37%, you_down 7%, down 3% |
| saloon | night | revolver | studio | 30 | 9.7 (4.1–13.3) | 0% | 80% | 0% | 2.8 (40%) | 2.7 / 1.0 | 3.7 / 2.4 | 14.0 | 3.8 | surrendered 63%, you_down 20%, down 13%, fled 3% |
| saloon | night | shotgun | studio | 30 | 5.6 (5.6–5.8) | 0% | 100% | 0% | 1.5 (77%) | 2.3 / 0.3 | 2.2 / 0.5 | 4.7 | 4.0 | fled 53%, surrendered 33%, you_down 7%, down 3%, dead 3% |
| street | golden | revolver | studio | 30 | 16.8 (11.2–34.3) | 7% | 43% | 3% | 6.0 (57%) | 2.0 / 0.7 | 3.0 / 3.6 | 11.2 | 7.4 | surrendered 37%, broke_off 23%, fled 17%, you_down 13%, down 10% |
| street | golden | shotgun | studio | 30 | 17.8 (13.1–35.6) | 23% | 33% | 7% | 5.0 (53%) | 2.5 / 0.7 | 3.1 / 4.2 | 11.1 | 9.4 | surrendered 33%, broke_off 30%, down 13%, you_down 10%, fled 7%, dead 7% |
| street | night | revolver | studio | 30 | 16.3 (6.9–30.5) | 7% | 47% | 3% | 5.0 (60%) | 2.6 / 0.6 | 3.7 / 3.1 | 11.2 | 7.1 | fled 27%, down 27%, surrendered 23%, broke_off 13%, you_down 10% |
| street | night | shotgun | studio | 30 | 15.8 (9.6–31.5) | 3% | 50% | 7% | 6.2 (60%) | 2.5 / 0.5 | 3.0 / 2.8 | 8.0 | 7.4 | surrendered 53%, fled 20%, broke_off 13%, down 7%, you_down 7% |

### By the scripted player's style

| style | bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cover | studio | 120 | 13.0 (6.2–23.4) | 8% | 58% | 29% | 2.9 (43%) | 2.0 / 1.4 | 2.3 / 3.7 | 13.1 | 4.5 | you_down 34%, fled 24%, surrendered 22%, broke_off 10%, down 8%, dead 1% |
| hold | studio | 120 | 12.8 (6.0–20.4) | 2% | 58% | 29% | 3.0 (47%) | 2.7 / 1.1 | 3.3 / 3.3 | 10.2 | 4.6 | surrendered 38%, fled 24%, you_down 18%, down 12%, broke_off 5%, dead 2% |
| push | studio | 120 | 6.6 (5.0–11.5) | 3% | 82% | 37% | 2.7 (28%) | 1.8 / 1.3 | 2.4 / 3.2 | 21.5 | 2.7 | you_down 39%, surrendered 38%, down 10%, broke_off 7%, fled 4%, dead 2% |

### By arena and style

| scenario | style | bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ambush | cover | studio | 40 | 10.8 (6.7–17.0) | 8% | 68% | 88% | 2.8 (2%) | 1.0 / 2.8 | 1.2 / 5.3 | 26.3 | 3.2 | you_down 75%, down 8%, surrendered 8%, fled 5%, dead 2%, broke_off 2% |
| ambush | hold | studio | 40 | 17.8 (11.5–21.4) | 0% | 45% | 88% | 2.7 (12%) | 2.6 / 2.1 | 3.1 / 5.5 | 19.7 | 4.6 | you_down 42%, surrendered 38%, down 12%, fled 8% |
| ambush | push | studio | 40 | 8.1 (6.6–12.3) | 2% | 78% | 95% | 2.8 (0%) | 1.1 / 2.5 | 1.5 / 5.1 | 28.4 | 2.7 | you_down 85%, surrendered 8%, down 5%, broke_off 2% |
| saloon | cover | studio | 40 | 6.6 (5.6–12.7) | 2% | 80% | 0% | 2.3 (68%) | 2.2 / 0.8 | 2.5 / 2.4 | 8.9 | 4.0 | fled 42%, surrendered 30%, you_down 22%, down 5% |
| saloon | hold | studio | 40 | 5.9 (5.6–10.4) | 0% | 92% | 0% | 6.1 (70%) | 2.6 / 0.4 | 3.2 / 1.1 | 5.2 | 4.0 | fled 42%, surrendered 32%, down 12%, you_down 8%, dead 5% |
| saloon | push | studio | 40 | 5.2 (3.2–6.4) | 0% | 100% | 0% | 1.5 (30%) | 2.6 / 0.9 | 3.0 / 1.0 | 14.6 | 2.6 | surrendered 68%, you_down 12%, down 8%, fled 8%, dead 5% |
| street | cover | studio | 40 | 29.4 (15.1–38.7) | 15% | 25% | 0% | 4.4 (60%) | 2.7 / 0.6 | 3.2 / 3.5 | 4.0 | 12.9 | surrendered 30%, broke_off 28%, fled 25%, down 12%, you_down 5% |
| street | hold | studio | 40 | 16.8 (12.7–26.5) | 8% | 38% | 0% | 4.8 (58%) | 2.9 / 0.7 | 3.7 / 3.2 | 5.7 | 7.2 | surrendered 42%, fled 22%, broke_off 15%, down 12%, you_down 5%, dead 2% |
| street | push | studio | 40 | 10.9 (5.4–21.3) | 8% | 68% | 15% | 8.4 (55%) | 1.6 / 0.6 | 2.7 / 3.6 | 21.5 | 4.8 | surrendered 38%, you_down 20%, broke_off 18%, down 18%, fled 5%, dead 2% |

### Each man (studio bodies)

| man | shots | hits on you | hit | cover changes | peeks | flanks | suppressing shots | pinned | how he ended |
|---|---|---|---|---|---|---|---|---|---|
| brody | 0.8 | 0.4 | 3.3 | 0.9 | 1.2 | 0.05 | 0.3 | 1.6 | surrendered 56%, standing 24%, down 9%, broke_off 5%, fled 4%, dead 1% |
| lyle | 1.3 | 0.4 | 2.8 | 1.2 | 0.8 | 0.00 | 1.1 | 1.4 | surrendered 60%, standing 26%, down 8%, broke_off 3%, dead 1%, fled 1% |
| kid | 1.3 | 0.5 | 2.1 | 1.0 | 1.6 | 0.03 | 0.5 | 1.1 | surrendered 51%, standing 20%, fled 16%, dead 8%, down 3%, broke_off 2% |

(each a mean a fight)

### Situation changes

| scenario | bodies | cover_shot_away | lamps_hit | fires_started | dust_on_line | dust_by_man | surrenders | flights | hats_shot | townsfolk_hit | shaken | rallied | fights with any | balls into the ground |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ambush | studio | 0.00 | 0.01 | 0.01 | 2.08 | 1.15 | 0.99 | 0.15 | 0.35 | 0.28 | 0.32 | 0.08 | 64% | 8.0 |
| saloon | studio | 0.06 | 0.21 | 0.00 | 1.36 | 0.46 | 2.25 | 0.62 | 0.13 | 0.04 | 1.23 | 0.63 | 98% | 2.9 |
| street | studio | 0.16 | 0.12 | 0.10 | 3.33 | 0.73 | 2.00 | 0.38 | 0.12 | 1.17 | 0.61 | 0.28 | 100% | 7.8 |

(each a mean a fight; fights with any: a situation change other than a townsman hit)

### What the three men cost a frame (headless, this workspace's core; x0.65 for Sean's)

| bodies | people ms a frame | the second before they came | the three men | people p95 | whole physics frame |
|---|---|---|---|---|---|
| studio | 8.06 | 5.07 | 2.99 | 13.66 | 13.54 |

### Steadiness: the first half of the seeds against the second

| setup group | fights | median length, seeds first half | second half | gang hit first, first half | second half |
|---|---|---|---|---|---|
| ambush studio | 120 | 8.8 | 13.0 | 95% | 85% |
| saloon studio | 120 | 5.6 | 6.0 | 0% | 0% |
| street studio | 120 | 17.9 | 15.8 | 2% | 8% |
### Why fights are short: diagnostics (studio bodies)

- the gang's first shot (median s after they turn): 2.32
- fights where the gang's first shot hit you: 17%
- the gang's hits a shot at you: 37% (452 of 1226)
- your hits a shot (a charge once): 80% (773 of 963)
- men who quit (gave up or ran), by hits taken first: 0 / 1 / 2 / 3+: 122 / 193 / 81 / 287 of 683
- fights where a hit took your gun arm (you can't hold the revolver; the coach gun needs both): 8% (median 5.3 s in)
- the men's time while fighting: open / moving / hidden / peeking / searching: 21% / 10% / 28% / 14% / 25%
- you went down when the gang hit first / when you hit first: 72% (of 114) / 11% (of 245)
- flank callouts in all: 29
- fights with a quiet stretch of 5 s or more: 40%
- fights lasting 45 s or more: 5%


### Body notes (what the fight's setup found missing on a man)

- none
