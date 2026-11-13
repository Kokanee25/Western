# Joe beside you: 20 fights without him, 20 with (#843, No Justice step 1)

`CompanionBrain` (src/people/companion_brain.gd; LAYOUT "src/people"). The lab's street arena at
golden hour, the revolver, the careful scripted player (`cover`), the gang in variant D (the game's),
seeds 1-20, studio bodies; with `joe=1` Joe stands 2.2 m to your right and a pace back, gun out (a
stand-in body, `miner_s4_talking`). Headless, fixed 60 fps: a seed is the same fight each time
for the same code, whatever the load.

```sh
python3 experiments/gunfight_lab/run.py --scenarios=street --hours=golden --weapons=revolver --styles=cover \
    --seeds=1-20 --variant=D [--joe=1] --out=build/gf_joe
python3 experiments/gunfight_lab/joe_stats.py build/gf_nojoe build/gf_joe
```

"Joe, first cut" is the brain before the blind playtest (`docs/playtests/2026-11-12-joe.md`);
"after the playtest" is what merged. Its fixes:
- a man you've fired at in the last 8 s is yours (the playtest: Joe shot the man you'd been
  firing at for a minute);
- a step aside that leaves him in your line is followed by a move to your side;
- no tending in the open while it's on unless he's bleeding hard (12 s at most);
- your word carries 40 m (it was 15);
- the gang brain's lines at most every 25 s ("Where did he go?" every 5 s, now "I do not see him now.").

| | without Joe | Joe, first cut | Joe, after the playtest (this merge) |
|---|---|---|---|
| fights | 20 | 20 | 20 |
| you alive | 13 of 20 | 16 of 20 | 11 of 20 |
| length median (s) | 41.8 | 71.3 | 43.1 |
| length range (s) | 4-142 | 5-180 | 5-180 |
| your hits taken (mean) | 0.85 | 1.3 | 1.55 |
| your shots (mean) | 7.3 | 8.3 | 6.6 |
| gang shots (mean) | 7.8 | 10.5 | 9.4 |
| endings | down 6, fled 2, lull 2, surrendered 3, you_dead 2, you_down 5 | broke_off 1, down 2, lull 3, surrendered 8, timeout 2, you_dead 1, you_down 3 | down 2, fled 1, lull 2, surrendered 5, timeout 1, you_dead 5, you_down 4 |
| Joe's shots (all) | - | 54 | 48 |
| Joe's hits (all) | - | 14 | 16 |
| of them on your man | - | 2 | 7 |
| men put out by you / Joe / nobody's ball | - | 29 / 7 / 8 | 27 / 7 / 4 |
| Joe in your line (s, median / max) | - | 1.11 / 10.23 | 0.36 / 13.92 |
| Joe in your line (share of the fight) | - | 3.1% | 3.5% |
| steps out of your line (all) | - | 68 | 60 |
| your balls in Joe (all) | - | 1 | 0 |
| gang's shots at Joe / hits on him (all) | - | 11 / 4 | 16 / 4 |
| Joe down (fights) | - | 2 | 0 |
| Joe up at the end (fights) | - | 17 | 20 |
| Joe dead | - | 0 | 0 |
| Joe's calls (median a fight) | - | 4.0 | 3.0 |

How to read it:
- **You alive** swings with the dice. The same 20 seeds gave 13 without Joe, 16 with the first cut
  and 11 with the merged brain.
  - Three of the merged run's losses are in the first 9 s (seeds 1, 7, 8). That's before Joe has a
    shot off: the gang's first rounds, drawn differently once a fourth man is in the street.
  - Twenty fights can't tell these apart. Forty a side would.
- **Joe helps, and not by taking your fights:**
  - The gang gives up more often with two against them (8 and 5 surrenders, against 3 without him).
  - Of the men put out, Joe's ball was the last in 7. Yours was in 27-29.
  - His hits on "your man" (as `yours` reads it at the moment of the hit) went from 2 to 7, because
    the merged `yours` counts more men as yours (anyone you've fired at in 8 s). Those are balls
    already on their way, or men on him.
  - He holds his fire a lot: up to ~28 s of a fight, since the scripted player fires at every man
    in turn.
- **Your line of fire:**
  - The median fight has him in front of your gun 0.36 s in all, against 1.1 s before the fixes.
  - Two fights still had 8-14 s (seeds 16 and 3: up to 18 steps aside, each one put back by the
    scripted player swinging onto him). The scripted player turns faster than a man.
  - Your balls in him: one in the first cut, none in the merged run.
- **They fight him too:** 16 of the gang's shots went at him (of ~190), 4 hit, and he was never
  down. He fights from behind cover more than you do, and a man shoots at what he sees.
- **He didn't die.** In the first cut he went down twice (a ball through the head, and the lone
  outlaw's): out while it was on, up after.

## The frame

Measured one game at a time, this container's core (it reads far slower than the workspace the
budget table was set on: main's own calm street is 7.36 ms of people here against the table's 1.8,
so only the difference Joe makes is read here).

| | people (ms a frame) | outlaw_brain | people_body | senses |
|---|---|---|---|---|
| the lab's fights, 3 long ones (seeds 5, 10, 12), without Joe | 11.8 | 0.91 | 4.03 | 1.93 |
| the same with Joe | 12.1 (+0.3, +2.5%) | 1.16 | 4.11 | 1.98 |
| `perf_bench --scene=calm` (budget-scaled), without Joe | 7.36 | 0.67 | 3.69 | 2.17 |
| the same with `--joe` (Joe walking with you) | 8.16 (+0.8, +11%) | 0.83 | 4.08 | 2.51 |

Joe is one more man ticked every frame beside you (never banded: he's always near you), about what
one of the gang costs near you: ~0.2-0.5 ms at Sean's. Whether the people as a whole fit 4 ms with
the gang in a fight is the perf bench's to say on Sean's machine (F3); nothing here is Joe's alone
past that one man.
