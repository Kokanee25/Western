# Fights that commit (2026-10-23; branch `claude/gameplay-fights-that-fight`)

Sean's first play (issue #257): "the bad guys just kept quitting, wouldn't even really fight." He
shot first. Measured in **the new saloon** (the building lab's, `spec_*` arenas) with the scripted
player, then changed one thing at a time. The result is **variant D**, the game's default now
(`OutlawBrain.default_variant`; it was A).

## The matrix

Five setups in the new saloon (`spec_hall`, `spec_stair`, `spec_gallery`, `spec_back`,
`spec_front`; scenarios.json), golden hour, the revolver, the game's bodies, two openings:
**they** (they turn on you at once, as before) and **you** (`opening=shoot`: your gun away, you
draw on them at their drink and fire the first shot, as Sean did). The baseline and the final
run: styles cover and hold, seeds 1-5 (100 fights a variant). The steps: style cover, seeds 1-5
(50 fights a step), each adding one fix to the last. `quits.py` makes the tables (each `.md` here).

**Shooting** is the time to the last shot. The lab ends a fight after 45 s with no shot (a lull),
so a fight that's over in 2 s and then waited out reads 47 s long; most of the "long" fights in
the first steps were that. The shooting is what was fought.

## Baseline: A as Sean played it, and C (`base_A_both_styles.md`, `base_C_both_styles.md`)

| | opening | shooting s (med) | shooting 20 s+ | anyone quits | first quit s | quits a fight | quits on 0 / 1 / 2+ hits | men who fired |
|---|---|---|---|---|---|---|---|---|
| A | they | 3.6 | 4% | 78% | 1.9 | 1.70 | 25 / 43 / 17 | 75% |
| A | **you** | **3.5** | 12% | **98%** | **1.4** | **2.34** | 28 / 68 / 21 | **33%** |
| C | they | 6.5 | 14% | 92% | 2.0 | 2.12 | 34 / 54 / 18 | 53% |
| C | you | 3.6 | 12% | 98% | 1.4 | 2.22 | 20 / 77 / 14 | 9% |

When you shoot first, someone quits in 98% of fights, the first 1.4 s after your shot, and two in
three men never fire. Where the quitters' fear came from (the brain's own ledger,
`OutlawBrain.fear_from`, new): **a hit ~50%**, a friend down or quit ~25%, near misses ~14%, being
aimed at 2-5%. The reasons:

1. **One ball breaks nearly anyone.** A hit's fear (0.25 + 0.14 severe + the energy it leaves) came
   to 0.78 for Brody, 0.70 for Lyle, 0.61 for the Kid, against nerves of 0.95, 0.7 and 0.3: the
   first man hit quits, the cool one too, and the rest follow.
2. **Knocked down is giving up**: a man knocked off his feet by a ball gives himself up to any man
   against him within 8 m he can see (`_down_but_awake`), and in a saloon that's everyone.
3. **Noise adds up**: near misses and the startle are fear like any other and never fade fast.
4. **Nobody leads**: `leads` was there but no man in `TownLife.GANG` had it.
5. **The room**: behind the new bar is the best cover in the hall, but the way round its open end
   (~14 m from the bar's front) was past the cover search's limit, so Brody stood in the open; and
   a man looking for you walked straight at where he'd last seen you, into the wall or the door
   jamb between (a 15 m room, 25 s of searching, no find).

C is worse when you shoot first: its moment to react and its hand on the gun mean most have quit
before they've drawn (9% fire).

## The steps (variant D, one fix added each; style cover, 25 fights a row)

| step | fix added | opening | shooting 20 s+ | shooting 45-90 s | first quit s | quits a fight | quits on 0 / 1 / 2+ hits | men who fired |
|---|---|---|---|---|---|---|---|---|
| C | (baseline) | they / you | 20% / 12% | 8% / 0% | 2.0 / 1.4 | 2.12 / 2.20 | 17-28-8 / 10-39-6 | 57% / 9% |
| d1 | `cover_way`: the long way round to real cover (`Cover.WAY_EXTRA_FAR`) | they / you | 20% / 8% | 8% / 0% | 2.0 / 1.4 | 2.04 / 2.04 | 17-24-10 / 11-35-5 | 52% / 7% |
| d2 | `aim_fight`: a gun held on him frightens before a fight, not in one | they / you | 24% / 8% | 8% / 0% | 2.2 / 1.4 | 1.92 / 2.04 | 15-24-9 / 11-35-5 | 53% / 5% |
| d3 | `noise`: near misses, the startle, a hat shot are `fright`: they pin him, fade (0.12 a second) and count for at most 0.4 of his nerve; a hothead takes less | they / you | 20% / 8% | 8% / 0% | 2.0 / 1.4 | 1.80 / 2.00 | 15-21-9 / 10-32-8 | 55% / 11% |
| d4 | `hothead`: temper 0.7+ holds his first 30 s on +0.5 x temper nerve | they / you | 32% / 24% | 8% / 0% | 3.1 / 2.2 | 1.56 / 1.72 | 14-13-12 / 10-24-9 | 56% / 20% |
| d5 | `leader`: Brody leads; up and in it within earshot, the rest get +0.25 (since: x their own nerve); a shaken man calls "I'm pinned!", Brody "Hold, damn it!" (-0.15 fear) | they / you | 28% / 24% | 8% / 0% | 2.9 / 2.2 | 1.56 / 1.72 | 12-11-16 / 9-25-9 | 56% / 21% |
| d6 | `green`: a man of little nerve running or quitting frightens the rest by his nerve's share, and his "Fall back!" takes only a man near breaking | they / you | 28% / 24% | 8% / 4% | 2.9 / 2.2 | 1.48 / 1.68 | 12-9-16 / 8-25-9 | 56% / 23% |
| d7 | `steady`: the thump of a ball frightens a man by `lerp(1, 0.45, nerve)` (pain, shock, bleeding still count in full); a gun arm that can't hold the gun frightens as an empty hand | they / you | 24% / 20% | 8% / 0% | 5.6 / 2.3 | 1.36 / 1.32 | 11-9-14 / 8-18-7 | 56% / 25% |
| d8 | `floored`: knocked down with his gun and short of 0.6 of breaking, he gets back up rather than give up | they / you | 24% / 28% | 8% / 0% | 5.8 / 3.8 | 1.32 / 1.16 | 12-8-13 / 9-13-7 | 55% / 28% |
| d9 | `hunt_way`: looking for you, he goes by the town's ways (out of the door, round the bar) | they / you (38 fights, same as d8's) | 35% / 44% (d8: 25% / 28%) | 20% / 6% (5% / 0%) | 9.3 / 12.3 | 1.80 / 1.33 | 13-7-16 / 7-12-5 | 57% / 41% |

Each kept: none made things worse on what it was for. The big ones: `hothead` (Lyle's quits 80% ->
56%), `steady` (Brody stops quitting first on a single ball), `floored` (the Kid's now first to go
in most fights, as he should be), `hunt_way` (lulls become hunting). `d9_same38.md` and
`d8_same38.md` are d9 against d8 on the 38 fights both ran before a later edit (the leader's hold
by a man's own nerve, the arm) reached the runs; the final run has everything.

## Final: D, all nine fixes, the game's default (`final_vs_A_C.md`; 100 fights, as the baseline)

| | opening | shooting s (med) | shooting 20 s+ | shooting 45-90 s | anyone quits | first quit s | quits a fight | quits on 0 / 1 / 2+ hits | first to quit B / L / K | men who fired | you down |
|---|---|---|---|---|---|---|---|---|---|---|---|
| A | they | 3.6 | 4% | 0% | 78% | 1.9 | 1.70 | 25 / 43 / 17 | 24 / 11 / 4 | 75% | 42% |
| **D** | they | **10.8** | **38%** | **12%** | 88% | **5.0** | 1.60 | 23 / 27 / 30 | 16 / 9 / 19 | 55% | 16% |
| A | you | 3.5 | 12% | 2% | 98% | 1.4 | 2.34 | 28 / 68 / 21 | 20 / 20 / 9 | 33% | 10% |
| **D** | you | **15.3** | **38%** | 4% | 88% | **3.8** | **1.42** | **15** / 31 / 25 | 13 / 9 / **22** | 28% | 2% |

Each man, you shooting first, A -> D: **Brody quits 76% -> 38%, Lyle 78% -> 32% (and late: at 16 s
when they start it), the Kid 80% -> 72%**, first to go in half the fights. Quits with no hit
halve (28 -> 15); most quits now come on two or more hits. The quitters' fear: hits 46%, a friend
down 19%, near misses 13% (as fright, capped), a friend quitting 7%: earned.

## What it doesn't do yet

- **45-90 s is still rare** (4-12% of fights): the fights are decided by hits. At 3-10 m indoors
  the scripted player hits three shots in four, and a man hit twice is down. More shooting needs
  more time hidden and less time hit: men peeking less long, staying low, moving between cover
  under covering fire, and **pressing** (going at you when you're reloading or hurt), none of which
  this pass touched.
- **Men who fired, you shooting first: 28%** (A 33%): D's men take a moment to react and draw (B's
  hand), and the first two shots land before most have their gun up. Fair, perhaps; Sean's play
  will say.
- The bot is one player. Whether it's a fight is Sean's call (PLAYTEST.md).
- What I read: `src/bodies/outlaw_brain.gd` (fear, nerve, the gang, cover, the hunt), `cover.gd`
  (the town's ways), `waypoints.gd`, `crew.gd`, `town_life.gd` (GANG), the gunfight lab
  (README, fight.gd, player_bot.gd, play.gd, bridge.gd), the building lab's README, saloon.json,
  play.gd and its batwings; `docs/briefs/three-gunmen.md` (the note and section 2).
