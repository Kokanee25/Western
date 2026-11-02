# Gunfight lab: 80 fights (build/gf_lib_on)

Source 7705909, 4.7.2.stable.official.ed1daf0bf, fights capped at 180.0 s.

### By bodies

| bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|
| studio | 80 | 32.8 (8.7–50.1) | 28% | 39% | 29% | 4.7 (14%) | 2.2 / 2.2 | 3.0 / 7.9 | 21.7 | 11.1 | you_down 61%, down 19%, surrendered 9%, fled 4%, broke_off 4%, lull 2%, dead 1% |

### By arena, hour and gun (the three styles pooled)

| scenario | hour | weapon | bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| spec_hall | golden | revolver | studio | 10 | 36.8 (34.3–60.8) | 20% | 10% | 0% | 10.5 (30%) | 2.5 / 1.2 | 3.7 / 9.7 | 13.0 | 11.7 | you_down 50%, down 20%, surrendered 20%, fled 10% |
| spec_hall | golden | shotgun | studio | 10 | 44.9 (14.7–71.4) | 40% | 30% | 0% | 5.0 (20%) | 3.0 / 1.7 | 3.5 / 7.7 | 10.5 | 16.3 | you_down 40%, down 40%, lull 10%, fled 10% |
| spec_hall | night | revolver | studio | 10 | 54.4 (36.6–74.5) | 50% | 10% | 0% | 12.8 (20%) | 2.5 / 1.8 | 3.1 / 7.4 | 7.5 | 32.4 | you_down 40%, down 30%, broke_off 20%, lull 10% |
| spec_hall | night | shotgun | studio | 10 | 43.7 (18.3–53.0) | 50% | 30% | 0% | 5.3 (20%) | 2.3 / 1.8 | 2.7 / 6.3 | 15.1 | 18.8 | you_down 70%, broke_off 10%, fled 10%, down 10% |
| spec_stair | golden | revolver | studio | 10 | 14.9 (7.8–28.9) | 10% | 50% | 80% | 3.2 (0%) | 1.1 / 2.8 | 3.2 / 9.4 | 34.3 | 2.8 | you_down 80%, down 10%, surrendered 10% |
| spec_stair | golden | shotgun | studio | 10 | 8.1 (6.9–10.5) | 10% | 80% | 40% | 2.0 (10%) | 2.2 / 2.7 | 2.5 / 5.9 | 36.2 | 2.2 | you_down 70%, surrendered 30% |
| spec_stair | night | revolver | studio | 10 | 25.0 (7.7–62.5) | 20% | 50% | 70% | 2.6 (0%) | 1.4 / 3.3 | 2.7 / 10.8 | 28.8 | 7.6 | you_down 90%, down 10% |
| spec_stair | night | shotgun | studio | 10 | 14.4 (7.3–30.5) | 20% | 50% | 40% | 2.0 (10%) | 2.7 / 2.0 | 2.7 / 6.1 | 27.8 | 6.9 | you_down 50%, down 30%, dead 10%, surrendered 10% |

### By the scripted player's style

| style | bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cover | studio | 80 | 32.8 (8.7–50.1) | 28% | 39% | 29% | 4.7 (14%) | 2.2 / 2.2 | 3.0 / 7.9 | 21.7 | 11.1 | you_down 61%, down 19%, surrendered 9%, fled 4%, broke_off 4%, lull 2%, dead 1% |

### By arena and style

| scenario | style | bodies | fights | length s, median (IQR) | in 45–90 s | under 15 s | gang hit first | your first hit taken, s (never) | hits you / gang | shots you / gang | near misses a min | longest quiet s | how it ended |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| spec_hall | cover | studio | 40 | 43.7 (30.8–65.4) | 40% | 20% | 0% | 5.4 (22%) | 2.6 / 1.6 | 3.2 / 7.8 | 11.6 | 17.9 | you_down 50%, down 25%, fled 8%, broke_off 8%, surrendered 5%, lull 5% |
| spec_stair | cover | studio | 40 | 10.9 (6.8–38.1) | 15% | 58% | 58% | 2.0 (5%) | 1.9 / 2.7 | 2.8 / 8.1 | 31.8 | 2.8 | you_down 72%, down 12%, surrendered 12%, dead 2% |

### Each man (studio bodies)

| man | shots | hits on you | hit | cover changes | peeks | flanks | suppressing shots | pinned | how he ended |
|---|---|---|---|---|---|---|---|---|---|
| brody | 3.6 | 1.0 | 1.9 | 2.4 | 7.5 | 0.39 | 2.6 | 1.1 | standing 60%, down 22%, surrendered 10%, broke_off 4%, dead 4% |
| lyle | 1.5 | 0.4 | 3.5 | 1.8 | 5.0 | 0.25 | 1.1 | 1.6 | standing 35%, down 32%, surrendered 21%, dead 9%, broke_off 2% |
| kid | 2.7 | 0.8 | 1.8 | 1.2 | 2.9 | 0.19 | 1.6 | 1.3 | surrendered 42%, standing 39%, fled 6%, broke_off 6%, down 6% |

(each a mean a fight)

### Situation changes

| scenario | bodies | cover_shot_away | lamps_hit | fires_started | dust_on_line | dust_by_man | surrenders | flights | hats_shot | townsfolk_hit | shaken | rallied | fights with any | balls into the ground |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| spec_hall | studio | 0.23 | 0.05 | 0.00 | 0.15 | 0.00 | 0.97 | 0.10 | 0.00 | 0.00 | 0.35 | 0.17 | 68% | 7.0 |
| spec_stair | studio | 0.60 | 0.10 | 0.00 | 0.10 | 0.00 | 0.72 | 0.20 | 0.12 | 0.00 | 0.03 | 0.03 | 82% | 5.4 |

(each a mean a fight; fights with any: a situation change other than a townsman hit)

### What the three men cost a frame (headless, this workspace's core; x0.65 for Sean's)

| bodies | people ms a frame | the second before they came | the three men | people p95 | whole physics frame |
|---|---|---|---|---|---|
| studio | 5.97 | 4.11 | 1.85 | 10.52 | 11.60 |

### Steadiness: the first half of the seeds against the second

| setup group | fights | median length, seeds first half | second half | gang hit first, first half | second half |
|---|---|---|---|---|---|
| spec_hall studio | 40 | 36.5 | 52.7 | 0% | 0% |
| spec_stair studio | 40 | 10.6 | 12.4 | 65% | 50% |
### Why fights are short: diagnostics (studio bodies)

- the gang's first shot (median s after they turn): 1.98
- fights where the gang's first shot hit you: 20%
- the gang's hits a shot at you: 27% (173 of 633)
- your hits a shot (a charge once): 73% (177 of 241)
- men who quit (gave up or ran), by hits taken first: 0 / 1 / 2 / 3+: 8 / 13 / 10 / 33 of 64
- fights where a hit took your gun arm (you can't hold the revolver; the coach gun needs both): 12% (median 5.8 s in)
- the men's time while fighting: open / moving / hidden / peeking / searching: 15% / 12% / 27% / 20% / 20%
- you went down when the gang hit first / when you hit first: 87% (of 23) / 52% (of 56)
- flank callouts in all: 66
- fights with a quiet stretch of 5 s or more: 62%
- fights lasting 45 s or more: 35%


### Body notes (what the fight's setup found missing on a man)

- none
