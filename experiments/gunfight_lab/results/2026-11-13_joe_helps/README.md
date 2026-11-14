# Joe has to help: 80 fights a side (#859, No Justice before step 2)

Sean on PR #853: "look first at why the playtest fixes dropped survival with Joe from 16 of 20 to
10 of 19. A companion has to help, not just stay out of the way." The setup is the same as
`../2026-11-12_joe/` (street, golden hour, revolver, the `cover` player, variant D, studio bodies),
40 seeds a side, then 40 more because the first 40 lied:

```sh
python3 experiments/gunfight_lab/run.py --scenarios=street --hours=golden --weapons=revolver --styles=cover \
    --seeds=1-40 --variant=D [--joe=1] [--game-args=--joe-tune=key:val+key:val] --out=build/X
python3 experiments/gunfight_lab/joe_stats.py build/A build/B ...      # the table
python3 experiments/gunfight_lab/joe_pairs.py build/A build/B [--why]  # seed by seed, why it went another way
```

`--joe-tune` (new, `CompanionBrain._lab_tune`) sets any of Joe's dials for one game.

## What changed (this merge), and why

`config/companion_joe.json` "tuning":
- **`yours_after_shot` 8 -> 0.** A man you only *fire at* is no longer yours for 8 s. That rule (from
  the first playtest: "Joe shot the man I'd been firing at for a minute") had Joe standing by
  through most of a fight: you fire at somebody most of the time, so most men were yours.
  A man you've *hit* is still yours for 3 s (`yours_after_hit`), and so is a hurt man in your sights.
- **`on_you_pick` 2.5 (new).** Joe would rather fight the men whose fight is with you (their brain's
  target is you): covering you, not hunting.
- **`draw_eye` 0.5 -> 1.5, `draw_eye_max` 3 -> 4.** Each shot of Joe's turns his man's eyes on him harder.
  The gang barely shot at him (17 of ~380 shots); they still mostly don't (27 of ~740), but more of them give up.

## The numbers

Seeds 1-40 (A none, B the merged Joe, C-F one suspect each, I1 this merge):

| | A no Joe | B merged | C yours_after_shot 0 | D line_run off | E yours_after_shot 3 | F C + line_grace 0.2 | I1 this merge |
|---|---|---|---|---|---|---|---|
| you alive | 28/40 | 29/40 | 34/40 | 29/40 | 30/40 | 29/40 | 34/40 |
| your hits taken (mean) | 1.27 | 1.35 | 1.02 | 1.32 | 1.07 | 1.12 | 0.97 |
| Joe's hits / on your man | - | 29 / 13 | 39 / 10 | 29 / 13 | 37 / 9 | 33 / 10 | 39 / 8 |
| men put out by you / Joe | - | 60 / 15 | 63 / 22 | 60 / 15 | 57 / 24 | 60 / 15 | 67 / 20 |
| Joe in your line (median s / max) | - | 0.34 / 13.9 | 0.74 / 14.1 | 0.34 / 13.9 | 0.69 / 21.8 | 0.64 / 8.0 | 0.88 / 14.1 |
| your balls in Joe | - | 0 | 0 | 0 | 0 | 0 | 0 |

C looked like the answer (34 against 28), so it went to fresh seeds 41-80 (G none, H C, I2 this merge):

| | G no Joe | H yours_after_shot 0 | I2 this merge |
|---|---|---|---|
| you alive | 30/40 | 26/40 | 28/40 |
| your hits taken (mean) | 1.48 | 0.97 | 0.88 |
| Joe's hits / on your man | - | 34 / 8 | 26 / 6 |
| Joe in your line (median s / max) | - | 0.84 / 14.7 | 0.46 / 14.7 |
| your balls in Joe (fights) | - | 1 | 2 |

All 80 (no Joe = A + G; I = this merge; J = I + `line_grace_firing` 0, out of your line at once while you're firing):

| | no Joe | merged Joe (B, seeds 1-40 only) | I this merge | J |
|---|---|---|---|---|
| you alive | 58/80 | (29/40) | **62/80** | 59/80 |
| your hits taken (mean) | 1.38 | (1.35) | **0.93** | 1.06 |
| surrendered (fights) | 16 | (13/40) | **32** | 29 |
| Joe's hits / on your man | - | - | 65 / 14 | 63 / 15 |
| Joe in your line (median s) | - | (0.34) | 0.69 | 1.04 |
| steps out of your line | - | - | 254 | 667 |
| your balls in Joe (fights) | - | (0) | 2 | 1 |

## What it says

- **Survival can't tell at 40, or at 80.** You live in ~73% of fights; a 5-point gain needs a few hundred
  a side to show. C's 34/40 came back 26/40 on fresh seeds. The first cut's 16/20 and the merged 11/20
  (`../2026-11-12_joe/`) were the same noise: over 40, the merged Joe was 29 against 28. And Joe changes
  every fight from its first second (the gang's dice fall differently), so seed pairs aren't matched:
  `joe_pairs.py` "worse with Joe" lists fights lost at 10 s, before Joe fired.
- **Hits taken can, and they fall by a third** (1.38 -> 0.93), in both halves. The gang surrenders in twice
  as many fights. That's Joe helping. B, the merged Joe, did neither (1.35, 13 surrenders in 40).
- **The price:** he's out of cover more because he shoots more, so he's in your line longer (median 0.69 s a
  fight, one step aside, against 0.34). Twice in 80 fights the lab's scripted player put a ball in him: in
  both, Joe had been in front of your gun 0.4 s and the player fired anyway. (The scripted player doesn't
  know Joe; "Harlan. Not at me." came 3 s before one of them. `joe_stats` counts each twice.)
  Of his 65 hits, 14 are on your man, fewer than the merged Joe's 13 of 29.
- **Not suspects:** `line_run` off (D) changed nothing. A shorter grace (F, 0.2 s) and none while you're
  firing (J, `line_grace_firing`, left in as a dial, off) make him dither in and out of your line (667 steps)
  and stand in it *longer*.

So #859's bar (survival clearly above, nothing worse) isn't met as written: survival isn't measurable at this
size, and the line time doubled. Joe now helps in the way that shows (hits, surrenders); keeping out of your
line while he fights is the next thing to take on (a cover spot off the line between you and your man, not only
off where your gun points now).
