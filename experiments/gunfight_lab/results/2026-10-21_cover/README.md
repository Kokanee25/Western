# Fix 2: cover first, by finding the cover that's there (2026-10-21)

Sean: "Yeah let's start cover". The baseline's reason 4: they fight standing in the open.

## What the lab found first

They do look for cover; they don't find it. The lab now logs why a man is in the open
(`open_searching`, `open_waiting`, `searches_empty` in a fight's record) and runs the gang's own
search from any spot (`gf_coverwhy`: every candidate and why it was turned down; `gf_cover` now
says why a spot isn't cover, ray by ray). In the street, of 24 fights: 130 s standing in the open
after a search had come back empty, against 15 s searching; 72 empty searches against 26 runs to
cover. From all six starting spots (street and saloon) the search found **no** spot, for three
reasons in `Cover`:

1. **One level only.** A candidate was looked for within half a metre of his own height, so a man
   on the porch (0.78 m) never considered the street, nor a man in the street the porch.
2. **Straight there or round one thing.** A spot inside the saloon's door, or behind the bar,
   needs a way in at the door or round the bar's end.
3. **Only cover within 1.6 m of him counted** (so a far-off hill doesn't). The saloon's front wall
   two to four metres off, a building's corner, a doorway: none counted.

## What changed in the game (`src/bodies/cover.gd`, `OutlawBrain`)

A man who knows the town (the gang's brains pass their `places`, the town's waypoints) searches
with three more things; everyone else's search is exactly as before (the scripted player's, a
friend dragged to cover, the tests):

- **Spots up or down a step**: each candidate is dropped onto the floor under it, up to a metre
  either way (`Cover._floor_under`, `LEVELS`).
- **The town's ways**: a spot he can't walk to straight or round one thing is reached by the
  town's places (in at the door, down the steps, round the bar), if the way's at most 1.6 times
  the straight line plus 6 m (`_town_way`). His ways to every place are worked out once a search,
  and only the best spots are routed, best first (`_best_in_town`).
- **Wide cover a few metres off**: something blocking within 35% of the way to you counts as his
  cover if it still hides him from a pace (0.8 m) either side of where you stand: a wall, a
  doorway, a building's corner; not a crate across the street, nor the trough at your knees
  (`HUGGING_SHARE`, `PACE`, `evaluate(..., far)`, `hidden_at(..., far)`; his check that his spot
  still hides him uses the same rule).

From the starting spots the search now finds: in the street, Brody steps inside the saloon's door,
Lyle goes in at the door, the Kid gets behind the tied horse; in the saloon, Brody goes round the
bar's end to behind it, Lyle and the Kid get down behind tables.

Cost: one town search is 16–45 ms of work spread over its 10–17 ticks (a first version that
routed every candidate took 170–480 ms and is gone). The gang's frame cost, measured on the same
12 fights before and after under the same load: brains 1.19 against 1.21 ms, the three men 2.75
against 2.79 ms; the people's worst frames (p95) 13.6 against 12.2 ms here (~0.9 ms more at
Sean's). 424 tests pass.

## Measured (`compare.md`: the same 360 studio fights, before and after)

"Before" is this branch just before the change (fix 1 on today's main), run again so the only
difference is this change. Since merged: main at 4b4b603 (the falls' faint, a body thrown into
timber, the saloon's lot and cellar, the stair's walking layer). Single fights now play out
differently, but the street's 120 run again keep the result: 12.5 s median (12.7), the gang's hits
a shot 17% (17%), their time in the open 27% (25%), the longest quiet 5.0 s (5.1).

| | before | after |
|---|---|---|
| fight length, median s | 6.5 | 8.5 |
| the street | 7.1 | 12.7 |
| the saloon | 1.9 | 3.3 |
| the ambush | 10.2 | 11.9 |
| the men's fighting time in the open | 42% | 22% |
| (time hidden / peeking / moving / searching for you) | 21 / 11 / 3 / 22% | 26 / 16 / 11 / 24% |
| cover changes, a man a fight | 0.42 | 0.97 |
| peeks, a man a fight | 0.64 | 1.21 |
| flank calls in all | 6 | 29 |
| fights with a quiet stretch of 5 s or more | 20% | 32% |
| longest quiet, median s (street) | 2.2 (2.8) | 3.8 (5.1) |
| the gang's hits a shot (street) | 34% (8%) | 35% (17%) |
| you down | 34% | 25% |
| in 45–90 s | 2% | 4% |

The contact sheet of a typical street fight (golden hour, revolver, holding the trough, seed 3;
15.5 s, the median of its 30): `sheet_street_golden_revolver_hold_studio_s3.jpg`. Within a second
all three run for cover (Brody and Lyle the saloon's doorway, the Kid the horse) and peek; nobody
fires for five seconds. Your first shot takes Brody in the chest and he gives up; the Kid calls
"fall back" and runs. Lyle shoots on from the doorway; one of his misses smashes a lamp (7.1 s)
and by 13 s the saloon's front is burning round him; at 15.5 s he goes down out cold with no
ball in him, likely the fire (not looked into).

## What it means

The fight moves now. They break for the doorway, the horse and the bar, peek and duck, go round
on you, and you lose them for a while: the street's longest lull doubled. From steadier cover
their shots in the street are twice as good. In the saloon they run for cover across the room
while your gun's already up, so you rarely go down there (3%) and they still quit.

Still only 4% of fights reach 45–90 s. What ends them now is reason 2: men quit on no hit (180) or
one (215) of 706 quits, a friend's fall frightens the rest, and you hit first in the standoffs.
That's the next fix. The flanking (reason 5) has started to happen (29 calls) but still waits
10–18 s in cover first.
