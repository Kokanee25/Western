# Going up for height (2026-11-02; issue #572, after stepping out, #566; branch `claude/gameplay-galleries-t1qhce`)

The fifth step of "men who move with purpose". In 400+ lab fights no man had climbed to the spec
saloon's galleries: the cover search samples spots round him on his own floor (`Cover.LEVELS`, a
metre up or down), so the floor 3.66 m up was never a candidate. And up there the rail is a
balustrade (3.5 cm balusters every 15 cm, `Railing`): three lines in four pass between them, so a
spot at the rail was "in plain view" to the cover check even for the men who start up there.

## The fix: `climb` (in `OutlawBrain.D_FIXES`; dials in `config/climb.tres`, `ClimbTuning`)

- **Whether** (`_climb_choose`, when his cover's gone stale: 10-18 s in it or four peeks, the same
  moment he'd otherwise move for an angle or go round): `ClimbTuning.chance_now`, 0.35, +0.25 with a
  friend in earshot still in it, his temper, less by his dread over his nerve, your fire lately
  (`rattled`) and his pain. Only while he's seen or heard you within 6 s (`known_within`: without it
  two of three climbers had lost you before they chose, and went straight back down to look), not
  while your fire keeps his head down, not shaken, not with a leg weaker than 0.75, not holding a
  house (`hold`: the farmhouse's men have their own tactics), not again for 25 s.
- **Where** (`Cover.climb_search`): spots along the upper floor's walks, the places (Waypoints) 2 m
  or more above both him and your feet within 14 m of him, every metre along the links between them
  and 0.6 / 1.0 m either side (out to the rail, back to the wall). Each evaluated as any spot is,
  with posts (`narrow`) and the screen below; `_best_up` routes the best eight by the town's places,
  up the stair (never straight: a level sweep from below passes under the gallery), at most 32 m,
  each metre costing 0.05 of the score; not by a way that passes within 3 m of you on your floor, not
  within 1.2 m of where a friend is or is going, and not up a stair a friend's standing on.
- **The screen** (`Cover._screen_spot`, `screen_share`; with `climb`, for spots 2 m or more above
  your feet): no balustrade hides a man, but ducked behind one, up over you, he's in slices and the
  floor's edge takes his hip. A spot is a screen when 0.4 of 27 lines to him ducked (9 across his
  shoulders at his hip, chest and the top of his head) are stopped within 1.6 m of him. He ducks
  there and shoots standing over the top rail; the hold check (`_hide`) asks the same share.
  Your eyes and your balls still go between the balusters: the screen is his judgement, not armour.
- **The run**: given the way at his run plus 4 s before he gives it up (was 7 s for any run), and
  up there he watches the floor below 12 s before he'll go and look for you (`watch_up`, in
  `_lost_you`; a 25 m run takes 6-8 s, and without it he came back down at once).
- Tests (`tests/test_outlaw_climb.gd`, a gallery of boxes with a ramp for a stair):
  - "the gallery over you is cover reached by the stair";
  - "behind a balustrade up over you he is screened";
  - "no way up no climb", "not past your gun on the way";
  - "his cover stale he goes up and fights from the rail";
  - "without the fix he stays on his floor", "the climb chance by nerve friends and hurt".

## The run

`base`: main at the branch point (cd98194), run from a copy of the tree. The branch with `climb`
left out of the fix list plays it event for event (10 of 10 fights, seeds 1-2, every setup).
`climb`: the branch head with `--fixes=all+pain_fight+floor_fight+odds+flinch`. D+, the careful
player, the five `spec_*` setups, golden hour, the revolver, seeds 1-20, both openings: 200 fights a
run, seed for seed, none failed.

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall,spec_stair,spec_gallery,spec_back,spec_front \
    --hours=golden --weapons=revolver --styles=careful --bodies=studio --variant=D \
    --fixes=all+pain_fight+floor_fight+odds+flinch --opening=,shoot --seeds=1-20 --jobs=3 --port_base=8900 --out=build/gf/climb
#  base: --fixes=aim_fight+noise+hothead+leader+green+cover_way+steady+floored+hunt_way+rescue_way+stay_in+go_low+press+hold_cover+watch_spot+posts+step_out+pain_fight+floor_fight+odds+flinch
python3 experiments/gunfight_lab/moves.py build/gf/base build/gf/climb --out=moves.md
python3 experiments/gunfight_lab/quits.py build/gf/<run> --out=quits_<run>.md
python3 experiments/gunfight_lab/perf.py build/gf/base build/gf/climb                   # perf.txt
python3 experiments/gunfight_lab/results/2026-11-01_watch_spot/stays.py build/gf/base build/gf/climb    # stays.txt
python3 experiments/gunfight_lab/results/2026-11-01_posts/pairs.py build/gf/base build/gf/climb        # pairs.txt
python3 experiments/gunfight_lab/results/2026-11-02_step_out/steps.py build/gf/base build/gf/climb     # steps.txt
python3 experiments/gunfight_lab/results/2026-11-02_step_out/shots.py build/gf/climb                  # shots.md
python3 experiments/gunfight_lab/results/2026-11-02_climb/climbs.py build/gf/base build/gf/climb      # climbs.txt
```

This machine's base isn't #566's: the same code (main at cd98194) gives stays at a post 189 / 120
against #566's 206 / 150, shooting median 46.9 / 32.5 s against 45.6 / 38.0. So compare these runs
with each other, not with #566's table.

## Before and after

| Run | Opening | Climbs (fights with one) | Stays up | Up s a man | Hits on you from up | Stays at a post | Shooting s (med) | 45-90 s | Hits on you | You down | Dropped 2 s |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 0 | 167 | 4.2 | 28 | 189 | 46.9 | 35% | 2.5 | 71% | 154 of 855 |
| **climb** | they | **20** (16) | **255** | **6.9** | 28 | 163 | 41.4 | 27% | 2.3 | 68% | 143 of 840 |
| base | you | 0 | 101 | 3.4 | 22 | 120 | 32.5 | 29% | 1.7 | 46% | 96 of 612 |
| **climb** | you | **14** (12) | **160** | **4.3** | 24 | 117 | 30.2 | 25% | 1.7 | 47% | 93 of 612 |

The climbs (`climbs.txt`):

| Opening | Climbs | How they ended | Way (m, med) | Run (s, med) | Stays at the spot climbed to | s a stay | Hits on you / on him there | Stays up behind a screen |
|---|---|---|---|---|---|---|---|---|
| they | 20 | got there 15, went to drag Brody 3, chose again 2 | 25.0 | 6.8 | 15 | 9.9 | 1 / 4 | 101 of 255 |
| you | 14 | got there 11, went to drag Brody 1, chose again 1, got away 1 | 23.5 | 5.9 | 11 | 6.5 | 1 / 1 | 56 of 160 |

- **They climb**: 34 climbs in 200 fights (none before): 21 in the hall, 7 out front once the fight
  has come in at the batwings, 4 at the back, 2 on the stair setup (its Kid stands on the stair);
  all to the back gallery, the stair's head. 26 got there, the way 24-25 m and 6-7 s at a run.
  Nobody climbs while you're outside: the floor above can't see you.
- **Height is used**: stays up 167 -> 255 and 101 -> 160, 4.2 -> 6.9 and 3.4 -> 4.3 s a man up
  there, most of it the men who start up (spec_gallery, spec_back's Kid) now holding the rail's
  screen instead of leaving it as "seen" (157 of 415 stays up behind a screen).
- **Not more dangerous from up**: hits on you from up 28 -> 28 and 22 -> 24. A climber at his rail
  gives 1 hit and takes 4 (they draw), 1 and 1 (you shoot first): shooting down 10-12 m through the
  balusters at a careful player behind cover, he's no better than he was below.
- **The fights**: seed for seed the shooting is 2.1 s shorter (standard error 2.5; 59 fights longer,
  67 shorter, 74 the same) and hits on you 0.15 fewer (SE 0.10; 42 more, 54 fewer, 104 the same):
  inside the noise, but the medians went down (46.9 -> 41.4 and 32.5 -> 30.2 s; 45-90 s 35 -> 27%
  and 29 -> 25%); you down 71 -> 68% and 46 -> 47%. Fewer stays at a post (189 -> 163): some of the
  men who'd have gone to a post went up.
- **The drops on arrival** about the same: 154 -> 143 and 96 -> 93 within 2 s.
- **The frame** (`perf.txt`): the gang's brains 1.96 -> 2.05 ms here, people 9.4 -> 9.8, frame 19.3
  -> 20.0. Neither ran alone (base beside a trial and a film; climb beside a film and the tests).
- **Determinism**: `same_fight.py`, 20 fights (seeds 1-4, every setup, they draw) run twice on the
  branch: 20 of 20 the same.

## The film

`films/spec_hall_s3_kid.mp4` (32 s, from 13 s; the hall, they draw, seed 3): the Kid, four peeks
from behind the far table, goes for the stair, climbs it and gets to the back gallery's rail at 20 s,
ducks behind the balustrade and shoots down from it until you hit him at 38 s. The camera
(`gf_climbcam`) follows him from behind on the way and holds behind his shoulder at the rail.

`film_posts.sh SETUP SEED OPENING OUT [SIZE] [MAX] climb` draws it. **The drawn fight is the
headless one when the script is the same**: run headless at `--fixed-fps 30` with the film's exact
commands (`gf_climbcam` first: one more command starts the fight a frame later, and that alone
makes another fight) and it plays event for event as drawn (checked on two films). Scan seeds that
way, minutes each, and draw only the one you want (~1 h under lavapipe beside a 3-job run).

## What's left

- **A climb that pays**: up there the climbers give little (1 hit in 26 stays at the rail). Worth
  measuring before it's tuned: the screen threshold (0.4), whether he should rise to aim only where
  the balusters part, and whether the scripted player's eyes, the gang's own, see a man through the
  gaps more than a player would.
- **The last drops on arrival**: 143 / 93 within 2 s; the wide covers' check counts a careful
  player's own cover as nothing (`Cover._blocked`), the flaw `hidden_narrow` fixed for posts.
- A blind playtest of D+ once that's in.
- Main changed under these runs: #575 put the library clips on in the game, and the lab's fights
  change with them (its commit: the gang surrenders less, the scripted player is down more). The
  numbers here are from before it; the next run's base is today's main.
