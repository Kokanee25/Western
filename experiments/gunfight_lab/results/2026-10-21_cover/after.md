# Gunfight lab: 360 fights (build/gunfight_lab/fix2)

Source ec2133a, 4.7.2.stable.official.ed1daf0bf, fights capped at 180.0 s.

### By bodies

| bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|
| studio | 360 | 8.5 (5.0–17.8) | 4% | 70% | 32% | 2.9 (44%) | 1.9 / 1.2 | 2.3 / 3.3 | 15.8 | 3.8 | surrendered 33%, you_down 25%, fled 18%, down 15%, broke_off 7%, dead 1%, lull 1% |

### By arena, hour and gun (the three styles pooled)

| scenario | hour | weapon | bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ambush | golden | revolver | studio | 30 | 10.2 (6.2–20.0) | 7% | 67% | 87% | 2.4 (10%) | 1.4 / 2.2 | 2.3 / 5.1 | 21.9 | 3.3 | you_down 63%, surrendered 27%, fled 7%, lull 3% |
| ambush | golden | shotgun | studio | 30 | 11.2 (6.6–21.7) | 7% | 60% | 87% | 2.4 (3%) | 1.2 / 2.5 | 1.9 / 5.8 | 24.6 | 3.2 | you_down 60%, surrendered 20%, down 10%, dead 7%, broke_off 3% |
| ambush | night | revolver | studio | 30 | 12.4 (7.3–18.7) | 0% | 60% | 93% | 3.0 (3%) | 1.6 / 2.5 | 1.5 / 5.2 | 23.7 | 3.2 | you_down 63%, down 13%, surrendered 10%, fled 10%, broke_off 3% |
| ambush | night | shotgun | studio | 30 | 13.0 (7.4–19.7) | 10% | 53% | 93% | 3.0 (7%) | 1.3 / 2.5 | 1.5 / 5.9 | 24.7 | 3.2 | you_down 63%, surrendered 27%, broke_off 10% |
| saloon | golden | revolver | studio | 30 | 3.1 (1.7–8.2) | 0% | 80% | 0% | 2.1 (43%) | 2.2 / 0.8 | 2.7 / 2.2 | 16.6 | 1.2 | surrendered 60%, down 23%, fled 10%, broke_off 3%, you_down 3% |
| saloon | golden | shotgun | studio | 30 | 5.6 (1.8–5.6) | 3% | 97% | 0% | 1.4 (80%) | 2.2 / 0.3 | 2.1 / 0.6 | 5.4 | 4.0 | fled 50%, surrendered 27%, down 23% |
| saloon | night | revolver | studio | 30 | 3.1 (1.7–7.4) | 3% | 83% | 0% | 2.5 (50%) | 2.1 / 0.8 | 2.6 / 2.1 | 16.7 | 1.1 | surrendered 63%, down 17%, you_down 7%, fled 7%, broke_off 3%, lull 3% |
| saloon | night | shotgun | studio | 30 | 4.0 (1.6–5.6) | 0% | 97% | 0% | 1.4 (80%) | 2.1 / 0.3 | 2.0 / 0.5 | 7.9 | 2.4 | fled 47%, surrendered 33%, down 17%, you_down 3% |
| street | golden | revolver | studio | 30 | 15.3 (8.9–31.8) | 10% | 47% | 7% | 4.0 (50%) | 1.8 / 0.6 | 2.9 / 3.7 | 14.6 | 6.9 | surrendered 30%, fled 20%, down 20%, broke_off 17%, you_down 10%, lull 3% |
| street | golden | shotgun | studio | 30 | 12.7 (8.2–21.7) | 0% | 63% | 10% | 5.1 (60%) | 2.2 / 0.6 | 2.5 / 3.4 | 13.6 | 6.1 | down 30%, broke_off 20%, surrendered 13%, fled 13%, you_down 13%, dead 10% |
| street | night | revolver | studio | 30 | 13.8 (7.2–22.6) | 7% | 57% | 7% | 5.1 (57%) | 2.2 / 0.6 | 3.4 / 3.1 | 13.4 | 4.9 | surrendered 43%, fled 23%, broke_off 17%, down 10%, you_down 7% |
| street | night | shotgun | studio | 30 | 9.9 (7.0–14.0) | 0% | 80% | 7% | 4.0 (83%) | 2.2 / 0.3 | 2.8 / 2.3 | 6.2 | 4.3 | surrendered 47%, fled 23%, down 13%, broke_off 10%, you_down 7% |

### By the scripted player's style

| style | bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cover | studio | 120 | 10.2 (5.6–22.6) | 9% | 62% | 29% | 2.9 (48%) | 1.9 / 1.3 | 2.2 / 3.9 | 13.5 | 4.0 | surrendered 33%, you_down 27%, fled 18%, down 11%, broke_off 8%, lull 2%, dead 1% |
| hold | studio | 120 | 10.1 (4.9–18.1) | 0% | 68% | 29% | 2.9 (52%) | 2.2 / 0.9 | 2.7 / 2.9 | 11.2 | 4.0 | surrendered 42%, fled 22%, down 17%, you_down 13%, broke_off 4%, dead 2% |
| push | studio | 120 | 6.3 (3.0–12.2) | 2% | 82% | 39% | 2.7 (32%) | 1.5 / 1.4 | 2.0 / 3.2 | 22.6 | 2.6 | you_down 35%, surrendered 25%, down 17%, fled 12%, broke_off 9%, dead 2%, lull 1% |

### By arena and style

| scenario | style | bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ambush | cover | studio | 40 | 11.9 (6.3–30.9) | 12% | 55% | 88% | 2.8 (8%) | 1.0 / 2.7 | 1.4 / 6.5 | 24.3 | 3.2 | you_down 68%, surrendered 18%, broke_off 10%, fled 5% |
| ambush | hold | studio | 40 | 17.4 (10.5–20.0) | 0% | 48% | 88% | 2.8 (10%) | 2.1 / 2.0 | 2.5 / 4.9 | 19.4 | 5.4 | surrendered 40%, you_down 38%, down 12%, fled 8%, dead 2% |
| ambush | push | studio | 40 | 8.9 (6.8–14.1) | 5% | 78% | 95% | 2.8 (0%) | 1.0 / 2.6 | 1.4 / 5.1 | 27.5 | 2.8 | you_down 82%, surrendered 5%, down 5%, lull 2%, dead 2%, broke_off 2% |
| saloon | cover | studio | 40 | 5.6 (1.9–17.8) | 5% | 72% | 0% | 2.3 (70%) | 2.2 / 0.7 | 2.3 / 2.3 | 8.8 | 4.0 | surrendered 42%, fled 32%, down 12%, broke_off 5%, you_down 5%, lull 2% |
| saloon | hold | studio | 40 | 3.6 (1.9–5.7) | 0% | 95% | 0% | 4.0 (80%) | 2.2 / 0.2 | 2.5 / 0.9 | 7.2 | 1.5 | surrendered 48%, fled 35%, down 18% |
| saloon | push | studio | 40 | 1.8 (1.6–3.9) | 0% | 100% | 0% | 1.4 (40%) | 2.0 / 0.8 | 2.1 / 0.8 | 18.9 | 0.9 | surrendered 48%, down 30%, fled 18%, you_down 5% |
| street | cover | studio | 40 | 13.3 (9.3–23.8) | 10% | 58% | 0% | 4.6 (65%) | 2.4 / 0.4 | 3.0 / 3.0 | 7.4 | 5.8 | surrendered 40%, down 20%, fled 18%, broke_off 10%, you_down 8%, lull 2%, dead 2% |
| street | hold | studio | 40 | 12.9 (9.7–17.6) | 0% | 60% | 0% | 4.3 (68%) | 2.4 / 0.4 | 3.1 / 2.8 | 7.0 | 5.0 | surrendered 38%, fled 25%, down 20%, broke_off 12%, dead 2%, you_down 2% |
| street | push | studio | 40 | 10.1 (5.5–33.5) | 2% | 68% | 22% | 5.1 (55%) | 1.5 / 0.8 | 2.6 / 3.6 | 21.3 | 4.0 | broke_off 25%, surrendered 22%, you_down 18%, fled 18%, down 15%, dead 2% |

### Each man (studio bodies)

| man | shots | hits on you | hit | cover changes | peeks | flanks | suppressing shots | pinned | how he ended |
|---|---|---|---|---|---|---|---|---|---|
| brody | 0.8 | 0.4 | 3.1 | 0.9 | 1.3 | 0.04 | 0.3 | 1.5 | surrendered 58%, standing 23%, down 8%, fled 5%, broke_off 5%, dead 1% |
| lyle | 1.3 | 0.3 | 2.6 | 1.2 | 0.9 | 0.03 | 1.0 | 1.4 | surrendered 55%, standing 23%, down 14%, broke_off 3%, dead 2%, fled 2% |
| kid | 1.2 | 0.5 | 1.5 | 0.8 | 1.4 | 0.01 | 0.5 | 0.9 | surrendered 59%, fled 17%, standing 16%, dead 5%, broke_off 3%, down 1% |

(each a mean a fight)

### Situation changes

| scenario | bodies | cover_shot_away | lamps_hit | fires_started | dust_on_line | dust_by_man | surrenders | flights | hats_shot | townsfolk_hit | fights with any | balls into the ground |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ambush | studio | 0.01 | 0.00 | 0.00 | 2.10 | 1.32 | 1.03 | 0.18 | 0.36 | 0.19 | 64% | 7.8 |
| saloon | studio | 0.06 | 0.22 | 0.01 | 1.00 | 0.36 | 2.43 | 0.62 | 0.03 | 0.10 | 98% | 2.3 |
| street | studio | 0.18 | 0.13 | 0.07 | 3.17 | 0.50 | 1.99 | 0.47 | 0.05 | 1.10 | 100% | 6.4 |

(each a mean a fight; fights with any: a situation change other than a townsman hit)

### What the three men cost a frame (headless, this workspace's core; x0.65 for Sean's)

| bodies | people ms a frame | the second before they came | the three men | people p95 | whole physics frame |
|---|---|---|---|---|---|
| studio | 7.92 | 4.92 | 3.01 | 13.83 | 13.64 |

### Steadiness: the first half of the seeds against the second

| setup group | fights | median length, seeds first half | second half | gang hit first, first half | second half |
|---|---|---|---|---|---|
| ambush studio | 120 | 9.7 | 12.7 | 95% | 85% |
| saloon studio | 120 | 5.6 | 2.5 | 0% | 0% |
| street studio | 120 | 11.9 | 12.7 | 8% | 7% |
### Why fights are short: diagnostics (studio bodies)

- the gang's first shot (median s after they turn): 2.32
- fights where the gang's first shot hit you: 17%
- the gang's hits a shot at you: 35% (422 of 1196)
- your hits a shot (a charge once): 80% (673 of 840)
- men who quit (gave up or ran), by hits taken first: 0 / 1 / 2 / 3+: 180 / 215 / 67 / 244 of 706
- fights where a hit took your gun arm (you can't hold the revolver; the coach gun needs both): 8% (median 5.2 s in)
- the men's time while fighting: open / moving / hidden / peeking / searching: 22% / 11% / 26% / 16% / 24%
- you went down when the gang hit first / when you hit first: 68% (of 117) / 5% (of 240)
- flank callouts in all: 29
- fights with a quiet stretch of 5 s or more: 32%
- fights lasting 45 s or more: 4%


### Body notes (what the fight's setup found missing on a man)

- none
