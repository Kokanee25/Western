# Stepping out from a post (2026-11-02; issue #566, after posts, #531; branch `claude/gameplay-post-step-out`)

The fourth step of "men who move with purpose". Since #531 a man at a post stays bladed behind it
and shoots round its edge: `cross` points (fast, wild), `regular` aims from the post pose. Now he
can also step out past the post's gun-side edge, square up, take the normal aimed shot and step
back in.

## The fix: `step_out` (in `OutlawBrain.D_FIXES`)

- **Choosing** (`_step_choose`, at each peek from a post): `PostStepTuning.chance` (dials in
  `config/post_step.tres`, all in one place):
  - by range: 0.15 inside 6 m, 0.85 past 12 m, straight between (point shooting holds a chest to
    about 7 m and falls off past 10-15 m: PostPose's header);
  - 0.9 when you're outside his point arc;
  - a hothead more, a cool man less (`temper_weight`), and his own `eager` drawn from his seed;
  - his nerve: less by 0.8 of dread over nerve;
  - your fire: less by 0.5 of `rattled`, never while `suppressed`;
  - his pain: less by his felt pain;
  - times 0.4 when he can't see you.

  Only once he's set against the post, with room to step there (`Sight.cast` at three heights to
  the spot and 20 cm beyond it), a floor within 20 cm and a line from his eye there to you
  (`_step_spot`). Not on his last round while covering a friend (that rule ducks him straight back).
- **The step** (`_step_move`): a pose blend, not keyframes. His feet slide across to the spot and
  he turns from bladed to square on you over `out_time` (0.3-0.55 s, his own); the aim pose's
  joints blend in from the post's. He holds there facing you, shooting by the usual rules
  (`GunHand`: the hand settles, the hold-over, the spread; not the point-fired rule), at most
  `hold` (1.2-2.6 s, his own). Then he goes back the same way in 0.8 of the time and the post pose
  blends back in. How far out (`clear`, 0-25 cm of his trunk's middle past the edge) is his own as
  well.
- **Back in** when shot at (a near miss or a hit ducks him: `_duck_back`), after his hold, after
  his peek's shots, or when he leaves the post's cover (`_step_lost`). While out, `hidden_narrow`
  doesn't hide him: the trunk check uses where he stood behind the post, and he's past it.
- Tests (`test_outlaw_tactics`):
  - "from a post he steps out to aim and back in";
  - "near he points round the post instead";
  - "shot at out there he steps back in";
  - "no room by the post no step";
  - "the step chance by range nerve and fire";
  - "covering on his last round he doesn't step out".

## The fix after the first run

The first 200 fights had 356 steps out, 80 of them back in within a tick or two. A man covering
a friend on his last round comes up and ducks back on the same tick (`_peek`'s covering rule: that
loop is main's, unseen until now because a peek from a post doesn't move him). Now he doesn't step
out for it: 356 -> 201 steps out over every stay, 80 -> 11 of them over in a tick or two, 0.65 ->
1.0 s out a step (the table's steps are those at a post's stays, 291 -> 170).

The lab's count of hits from out had the same tick: he ducks back as he fires, so his ball lands
a tick after he's "in". `fight.gd` now counts a ball within 0.25 s of his last tick out as from
out (`OUT_LATE`), and tags every shot `out`, `pointed`, `post` (aimed from the post pose) or other
(`shot_errors`' sixth field; `shots.py`).

## The run

`base`: this branch with `step_out` left out of the fix list (every new path is a no-op without
it, so this is main's fight; it plays main's numbers: stays at a post 197 / 159 against #531's
193 / 148). `step2`: the branch head with `--fixes=all+pain_fight+floor_fight+odds+flinch`. D+, the
careful player, the five `spec_*` setups, golden hour, the revolver, seeds 1-20, both openings:
200 fights a run, seed for seed, none failed.

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall,spec_stair,spec_gallery,spec_back,spec_front \
    --hours=golden --weapons=revolver --styles=careful --bodies=studio --variant=D \
    --fixes=all+pain_fight+floor_fight+odds+flinch --opening=,shoot --seeds=1-20 --jobs=4 --out=build/gf/step2
#  base: --fixes=aim_fight+noise+hothead+leader+green+cover_way+steady+floored+hunt_way+rescue_way+stay_in+go_low+press+hold_cover+watch_spot+posts+pain_fight+floor_fight+odds+flinch
python3 experiments/gunfight_lab/moves.py build/gf/base build/gf/step2       # moves.md
python3 experiments/gunfight_lab/quits.py build/gf/<run>                     # quits_*.md
python3 experiments/gunfight_lab/perf.py build/gf/base build/gf/step2        # perf.txt
python3 experiments/gunfight_lab/results/2026-11-01_watch_spot/stays.py build/gf/base build/gf/step2
python3 experiments/gunfight_lab/results/2026-11-01_posts/pairs.py build/gf/base build/gf/step2   # pairs.txt
python3 experiments/gunfight_lab/results/2026-11-02_step_out/steps.py build/gf/base build/gf/step2  # steps.txt
python3 experiments/gunfight_lab/results/2026-11-02_step_out/shots.py build/gf/step2              # shots.md
```

## Before and after

| Run | Opening | Stays at a post | Post s a man | Steps out | s out a step | Hits given / taken there | Hits on you from out | Dropped 2 s | Shooting s (med) | 45-90 s | Hits on you | You down |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 197 | 8.3 | 0 | - | 52 / 14 | - | 123 of 760 | 42.5 | 29% | 2.6 | 68% |
| **step2** | they | 206 | 8.1 | **96** | 1.0 | 56 / 21 | **19** of 68 shots | 126 of 786 | 45.6 | 32% | 2.7 | 68% |
| base | you | 159 | 6.0 | 0 | - | 35 / 22 | - | 93 of 672 | 39.2 | 26% | 2.0 | 49% |
| **step2** | you | 150 | 5.2 | **74** | 1.0 | 47 / 17 | **17** of 51 shots | 85 of 625 | 38.0 | 30% | 2.0 | 52% |

The gang's shots by kind (`shots.md`, step2, both openings):

| Kind | Shots | Barrel off (deg, med) | Range (m, med) | Hits on you | Shots a hit |
|---|---|---|---|---|---|
| stepped out | 143 | 2.34 | 10.7 | 44 | **3.2** |
| aimed from the post (`regular`) | 238 | 3.00 | 8.6 | 55 | 4.3 |
| pointed round it (`cross`) | 294 | 5.50 | 11.0 | 26 | **11.3** |
| every other shot | 1,650 | 2.46 | 9.9 | 345 | 4.8 |

- **They step out and it's the aimed shot**: 96 and 74 steps out in a hundred fights, a second
  out a step. From out the barrel is off by 2.3 degrees at 11 m, the gang's best: one hit on you in
  3.2 shots, against one in 11 for a pointed shot at the same range.
- **They're hit out there rarely**: 1 hit on a man stepped out in 200 fights. He's out a second at
  a time and ducks at the first ball past him.
- **More given at the posts, a few more taken**: 52 -> 56 and 35 -> 47 hits given there, 14 -> 21
  and 22 -> 17 taken.
- **As long, as dangerous**: shooting median 42.5 -> 45.6 s and 39.2 -> 38.0 s; 45-90 s of
  shooting 29 -> 32% and 26 -> 30%. Seed for seed the shooting is 2.7 s shorter (standard error
  2.1: noise; 45 fights longer, 56 shorter, 99 the same). Hits on you 2.6 -> 2.7 and 2.0 -> 2.0
  (seed for seed +0.03, SE 0.09); you down 68 -> 68% and 49 -> 52%.
- **The drops on arrival** unchanged: 123 -> 126 and 93 -> 85 within 2 s.
- **The frame** (`perf.txt`): the gang's brains 1.28 -> 1.34 ms here, people 5.7 -> 6.0. The two
  runs didn't run alone: base ran beside the first step run, step2 alone at 4 jobs.
- **Determinism**: `same_fight.py`, 20 fights (seeds 1-4, every setup, they draw) run twice on the
  branch: 20 of 20 the same.

## The films

`film_posts.sh SETUP SEED OPENING OUT [SIZE] [MAX]`: one lab fight drawn under xvfb (lavapipe) by
Godot's Movie Maker at 30 fps. The camera (`gf_postcam` in the lab's bridge) holds behind the
shoulder of a man at a post, on the side he steps out to, and is your eyes otherwise. The cuts are
in the `.cuts` beside each film. A drawn fight isn't the headless one with that seed (the hall's
seed 17 drawn never took a post), so the films are chosen from what the drawn run did. Each
takes ~20 min under lavapipe for ~45 s of fight; both are cut to the man at the post.

- `films/spec_front_s20_lyle.mp4` (14 s; the setup's front, they draw, seed 20): Lyle takes the
  porch post, points once round it, then steps out three times and shoots from out each time,
  back in between. The camera sits down the porch (it's pulled in short of the wall), so he's small.
- `films/spec_front_s16_lyle.mp4` (22 s; seed 16): Lyle at the next post along, closer, two stays,
  stepping out to shoot; you're hit at the end.

## What's left (#531's order)

- **The galleries**: still no climb (0 in 400 fights).
- **The last drops on arrival**: 126 / 85 within 2 s; the wide covers' check counts a careful
  player's own cover as nothing (`Cover._blocked`).
- A blind playtest once these are in.
