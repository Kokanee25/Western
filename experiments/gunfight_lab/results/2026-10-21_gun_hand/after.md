# Gunfight lab: 360 fights (build/gunfight_lab/fix1)

Source d49fc3b, 4.7.2.stable.official.ed1daf0bf, fights capped at 180.0 s.

### By bodies

| bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|
| studio | 360 | 6.5 (3.7–10.8) | 3% | 81% | 33% | 2.0 (34%) | 1.7 / 1.5 | 2.1 / 4.3 | 26.4 | 2.2 | you_down 34%, surrendered 30%, fled 17%, down 12%, broke_off 5%, dead 2%, lull 1% |

### By arena, hour and gun (the three styles pooled)

| scenario | hour | weapon | bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ambush | golden | revolver | studio | 30 | 11.7 (7.1–22.5) | 0% | 63% | 77% | 2.8 (10%) | 1.5 / 2.4 | 2.6 / 6.1 | 27.2 | 3.5 | you_down 63%, surrendered 17%, down 13%, fled 3%, broke_off 3% |
| ambush | golden | shotgun | studio | 30 | 13.6 (6.6–24.7) | 0% | 53% | 90% | 2.8 (7%) | 1.2 / 2.7 | 1.4 / 6.9 | 29.9 | 4.8 | you_down 67%, surrendered 17%, broke_off 7%, fled 3%, dead 3%, down 3% |
| ambush | night | revolver | studio | 30 | 10.1 (6.6–23.5) | 10% | 63% | 100% | 2.7 (0%) | 1.4 / 2.7 | 1.7 / 6.4 | 29.7 | 2.8 | you_down 67%, fled 10%, surrendered 10%, broke_off 3%, lull 3%, dead 3%, down 3% |
| ambush | night | shotgun | studio | 30 | 9.1 (6.7–21.7) | 7% | 70% | 100% | 2.7 (0%) | 1.0 / 2.8 | 1.2 / 6.5 | 31.9 | 2.6 | you_down 73%, broke_off 13%, surrendered 10%, fled 3% |
| saloon | golden | revolver | studio | 30 | 1.8 (1.6–4.2) | 0% | 93% | 0% | 1.4 (23%) | 1.8 / 1.5 | 1.9 / 2.4 | 35.2 | 1.0 | surrendered 50%, you_down 30%, down 13%, broke_off 3%, fled 3% |
| saloon | golden | shotgun | studio | 30 | 2.0 (1.6–5.8) | 0% | 97% | 0% | 1.4 (23%) | 1.7 / 1.5 | 1.7 / 2.4 | 33.5 | 1.2 | surrendered 37%, you_down 33%, down 17%, fled 13% |
| saloon | night | revolver | studio | 30 | 1.8 (1.6–4.7) | 0% | 97% | 0% | 1.4 (23%) | 1.9 / 1.4 | 1.9 / 2.1 | 34.1 | 1.0 | surrendered 50%, you_down 20%, down 17%, fled 10%, broke_off 3% |
| saloon | night | shotgun | studio | 30 | 1.9 (1.6–5.2) | 3% | 97% | 0% | 1.4 (23%) | 1.7 / 1.4 | 1.7 / 2.2 | 33.9 | 1.1 | surrendered 47%, you_down 27%, down 13%, fled 10%, lull 3% |
| street | golden | revolver | studio | 30 | 7.3 (5.0–17.3) | 7% | 73% | 13% | 1.9 (67%) | 2.0 / 0.4 | 3.4 / 4.6 | 17.0 | 3.2 | surrendered 30%, fled 27%, down 23%, you_down 10%, broke_off 7%, lull 3% |
| street | golden | shotgun | studio | 30 | 7.4 (5.9–10.6) | 3% | 90% | 13% | 4.7 (67%) | 2.1 / 0.4 | 2.8 / 5.0 | 16.7 | 2.9 | fled 50%, down 17%, surrendered 17%, dead 10%, you_down 7% |
| street | night | revolver | studio | 30 | 7.2 (6.1–11.4) | 7% | 77% | 7% | 3.5 (83%) | 2.0 / 0.3 | 2.6 / 4.0 | 16.7 | 3.9 | fled 30%, surrendered 27%, broke_off 17%, down 17%, you_down 7%, lull 3% |
| street | night | shotgun | studio | 30 | 6.5 (5.5–7.8) | 0% | 97% | 0% | 5.5 (87%) | 2.4 / 0.1 | 2.8 / 3.5 | 11.1 | 2.0 | surrendered 47%, fled 37%, down 10%, dead 7% |

### By the scripted player's style

| style | bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cover | studio | 120 | 7.5 (5.3–13.4) | 6% | 77% | 35% | 2.0 (38%) | 1.5 / 1.8 | 2.0 / 5.1 | 26.2 | 2.7 | you_down 44%, fled 18%, surrendered 16%, broke_off 9%, down 8%, lull 2%, dead 2% |
| hold | studio | 120 | 6.7 (3.0–10.8) | 1% | 81% | 32% | 1.6 (43%) | 2.0 / 1.1 | 2.4 / 4.0 | 20.9 | 2.5 | surrendered 44%, you_down 22%, fled 22%, down 8%, dead 3%, lull 1% |
| push | studio | 120 | 5.4 (1.9–8.4) | 2% | 85% | 33% | 2.2 (22%) | 1.7 / 1.5 | 2.0 / 4.0 | 32.1 | 1.8 | you_down 34%, surrendered 29%, down 21%, fled 10%, broke_off 5%, dead 1% |

### By arena and style

| scenario | style | bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ambush | cover | studio | 40 | 9.9 (6.3–33.0) | 8% | 68% | 95% | 2.7 (0%) | 0.8 / 3.0 | 1.7 / 7.2 | 35.2 | 2.8 | you_down 75%, broke_off 10%, fled 8%, down 2%, surrendered 2%, lull 2% |
| ambush | hold | studio | 40 | 15.1 (8.0–23.8) | 0% | 50% | 90% | 2.9 (8%) | 1.8 / 2.2 | 2.1 / 6.5 | 24.1 | 5.0 | you_down 52%, surrendered 28%, down 10%, dead 5%, fled 5% |
| ambush | push | studio | 40 | 8.5 (6.4–18.5) | 5% | 70% | 90% | 2.7 (5%) | 1.1 / 2.6 | 1.3 / 5.8 | 29.7 | 2.8 | you_down 75%, surrendered 10%, broke_off 10%, down 2%, fled 2% |
| saloon | cover | studio | 40 | 4.8 (2.0–7.9) | 2% | 88% | 0% | 1.4 (30%) | 1.4 / 2.0 | 1.4 / 3.9 | 36.9 | 1.2 | you_down 52%, surrendered 22%, down 10%, fled 8%, broke_off 5%, lull 2% |
| saloon | hold | studio | 40 | 1.8 (1.6–4.3) | 0% | 100% | 0% | 1.4 (30%) | 1.9 / 1.1 | 1.9 / 1.6 | 31.2 | 1.0 | surrendered 68%, you_down 15%, fled 12%, down 5% |
| saloon | push | studio | 40 | 1.7 (1.6–2.2) | 0% | 100% | 0% | 1.4 (10%) | 2.0 / 1.2 | 2.0 / 1.4 | 34.3 | 0.9 | surrendered 48%, down 30%, you_down 15%, fled 8% |
| street | cover | studio | 40 | 7.9 (6.2–19.9) | 8% | 75% | 10% | 2.2 (85%) | 2.1 / 0.2 | 2.8 / 4.1 | 6.4 | 3.9 | fled 40%, surrendered 22%, broke_off 12%, down 12%, you_down 5%, dead 5%, lull 2% |
| street | hold | studio | 40 | 7.2 (6.4–9.0) | 2% | 92% | 5% | 1.4 (92%) | 2.3 / 0.1 | 3.1 / 4.0 | 7.5 | 2.8 | fled 48%, surrendered 38%, down 8%, dead 5%, lull 2% |
| street | push | studio | 40 | 5.9 (5.0–8.2) | 2% | 85% | 10% | 5.1 (50%) | 2.0 / 0.7 | 2.8 / 4.7 | 32.2 | 1.7 | down 30%, surrendered 30%, fled 20%, you_down 12%, broke_off 5%, dead 2% |

### Each man (studio bodies)

| man | shots | hits on you | hit | cover changes | peeks | flanks | suppressing shots | pinned | how he ended |
|---|---|---|---|---|---|---|---|---|---|
| brody | 0.8 | 0.3 | 3.0 | 0.4 | 1.0 | 0.02 | 0.4 | 1.0 | surrendered 66%, standing 23%, down 5%, broke_off 3%, fled 2%, dead 1% |
| lyle | 2.4 | 0.9 | 2.4 | 0.4 | 0.2 | 0.00 | 1.4 | 1.1 | surrendered 49%, standing 31%, down 12%, fled 3%, broke_off 2%, dead 2% |
| kid | 1.1 | 0.3 | 0.6 | 0.5 | 0.6 | 0.00 | 0.7 | 1.5 | surrendered 53%, standing 25%, fled 18%, broke_off 2%, dead 2%, down 1% |

(each a mean a fight)

### Situation changes

| scenario | bodies | cover_shot_away | lamps_hit | fires_started | dust_on_line | dust_by_man | surrenders | flights | hats_shot | townsfolk_hit | fights with any | balls into the ground |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ambush | studio | 0.03 | 0.00 | 0.00 | 1.58 | 1.02 | 0.97 | 0.23 | 0.30 | 0.11 | 68% | 7.2 |
| saloon | studio | 0.05 | 0.25 | 0.00 | 1.03 | 1.02 | 2.31 | 0.12 | 0.00 | 0.02 | 99% | 2.4 |
| street | studio | 0.00 | 0.00 | 0.00 | 5.46 | 0.41 | 2.09 | 0.73 | 0.10 | 0.40 | 97% | 7.4 |

(each a mean a fight; fights with any: a situation change other than a townsman hit)

### What the three men cost a frame (headless, this workspace's core; x0.65 for Sean's)

| bodies | people ms a frame | the second before they came | the three men | people p95 | whole physics frame |
|---|---|---|---|---|---|
| studio | 3.93 | 2.54 | 1.39 | 6.29 | 6.88 |

### Steadiness: the first half of the seeds against the second

| setup group | fights | median length, seeds first half | second half | gang hit first, first half | second half |
|---|---|---|---|---|---|
| ambush studio | 120 | 12.0 | 8.8 | 83% | 100% |
| saloon studio | 120 | 1.8 | 2.0 | 0% | 0% |
| street studio | 120 | 7.8 | 7.0 | 13% | 3% |
### Why fights are short: diagnostics (studio bodies)

- the gang's first shot (median s after they turn): 2.08
- fights where the gang's first shot hit you: 12%
- the gang's hits a shot at you: 34% (526 of 1565)
- your hits a shot (a charge once): 81% (620 of 770)
- men who quit (gave up or ran), by hits taken first: 0 / 1 / 2 / 3+: 201 / 203 / 74 / 211 of 689
- fights where a hit took your gun arm (you can't hold the revolver; the coach gun needs both): 14% (median 2.9 s in)
- the men's time while fighting: open / moving / hidden / peeking / searching: 42% / 3% / 21% / 12% / 22%
- you went down when the gang hit first / when you hit first: 68% (of 120) / 16% (of 240)
- flank callouts in all: 6
- fights with a quiet stretch of 5 s or more: 20%
- fights lasting 45 s or more: 3%


### Body notes (what the fight's setup found missing on a man)

- none
