# Posts as narrow cover (2026-11-01; issue #531, after the post pose, PR #545; branch `claude/gameplay-cover-moves-3-posts`)

The third step of "men who move with purpose". A porch post or a stair newel is 20 cm wide;
`Cover.hidden_at` wants 36 cm to hide a man square on, so the gang never took one: 24 / 34 stays
at a post in a hundred fights, half a second a man. Since #545 a man can stand side-on behind a
post (`PostPose`, `HumanBody.take_post`). This step gives the brain that cover.

## The fix: `posts` (in `OutlawBrain.D_FIXES`)

- **A narrow cover kind** (`Cover._narrow`, asked only by a brain with `posts`): where neither
  wall nor trough hides him, a spot whose shadow is something solid within 0.7 m, blocked at all
  four heights (0.5-1.55 m) on the line, 14 cm wide or more, seen round at eye and gun height
  from its right-hand edge, and inside the point arc's pitch. The spot is centred on the
  shadow. It carries `narrow`, `post` (the post's foot, middle) and `post_w`. Scored a wall's
  +0.5 less 0.4 (`NARROW_SCORE`): below a wall, just above a trough, above the open.
- **Holding it** (`_hold_post`): at a post he takes the post pose, faced at you (taken again only
  when you've moved round more than 12 degrees), and after 1 s is placed by `PostPose.place_at`
  so the post covers his trunk (the pose's Euler blend has settled by then; at 0.5 s the arm was
  still swinging and the placing missed).
- **Still hidden?** (`Cover.hidden_narrow`): the post stands between your eye and the middle of
  his trunk across the line (`_trunk_at`, the pelvis/abdomen/chest capsules), at least 2 cm
  inside its edge, and one ray to his chest is blocked (a post shot away doesn't count).
- **Shooting from it**: no walk out to a peek spot; the post pose's gun arm comes round the post.
  With the `cross` style he points rather than aims (`_pointing`): the shot only inside
  `PostPose.POINT_ARC` (25 degrees) of where he faces, no hold-over, the eye's spread x2.5 and
  1.5 degrees more in the cone (the point-fired rule PR #545 stated). `Senses.eye()` in the post
  pose is `PostPose.eye_now` (the head part's centre stays behind the post: he never saw you).
- Tests: `test_outlaw_tactics` "a post is cover side-on but not square on", "a pole or a rail is
  no post", "at a post he blades himself and shoots round it", "from a post he points the gun".

## The drop that took four tries

Its first version, measured on seeds 1-4: 111 stays at a post, 54 of them left within 2 s ("you
can see him there now"). The check fired before the placing, then on the post's edge, then with
the line stopped by your own cover. The careful player crouches behind something a pace or two
in front of him, and the old check asked whether *the first thing on the line* was near the man.
Your own cover isn't near him, so it read as seen while the post still stood between you. The
geometric check above asks the real question. Seeds 1-4: dropped within 2 s 54 → 33 → 6 of 67,
median stay at a post 8.2 s.

**The same flaw is in the wide covers**: `Cover._blocked` counts only blockers near the man, so a
careful player behind his own cover makes a wall or trough "seen" too. That's the issue's "last
drops on arrival" step, not changed here.

## The run

`base` is main at the branch point (`--fixes=` as watch_spot's run), `posts` the branch head
(d01eb5d). D+, the careful player, the five `spec_*` setups, golden hour, the revolver, seeds
1-20, both openings: 200 fights a run, `--deterministic`, seed for seed (base 199: spec_hall s6
shoot failed to start). `base` ran beside another run on 2 cores; `posts` had 4 jobs alone.

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall,spec_stair,spec_gallery,spec_back,spec_front \
    --hours=golden --weapons=revolver --styles=careful --bodies=studio --variant=D \
    --fixes=all+pain_fight+floor_fight+odds+flinch --opening=,shoot --seeds=1-20 --jobs=4 --out=build/gf/<run>
python3 experiments/gunfight_lab/moves.py build/gf/base build/gf/posts            # moves.md
python3 experiments/gunfight_lab/quits.py build/gf/<run>                          # quits_*.md
python3 experiments/gunfight_lab/perf.py build/gf/base build/gf/posts             # perf.txt
python3 experiments/gunfight_lab/results/2026-11-01_watch_spot/stays.py build/gf/base build/gf/posts  # stays.txt
python3 experiments/gunfight_lab/results/2026-11-01_posts/pairs.py build/gf/base build/gf/posts
```

## Before and after

| Run | Opening | Runs to a post | Stays at a post | Post s a man | Hits taken / given there | Dropped 2 s, all covers | Stay s (med) | Shooting s (med) | 45-90 s | Hits on you | You down |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 25 | 24 | 0.5 | 2 / 11 | 143 of 658 (22%) | 4.6 | 32.6 | 32% | 2.2 | 63% |
| **posts** | they | **242** | **193** | **8.3** | 14 / **52** | 120 of 756 (16%) | 6.0 | **42.5** | 29% | 2.6 | 68% |
| base | you | 35 | 34 | 0.9 | 10 / 14 | 114 of 661 (17%) | 4.0 | 40.5 | 28% | 2.1 | 53% |
| **posts** | you | **187** | **148** | **5.6** | 20 / **33** | 93 of 647 (14%) | 4.9 | 38.4 | 26% | 2.0 | 50% |

- **They use the posts**: stays at a post 24 → 193 and 34 → 148, 0.5 → 8.3 and 0.9 → 5.6 s a man
  there. They give more than they take there: 52 hits given to 14 taken, 33 to 20.
- **Fewer drops on arrival over all** (22 → 16%, 17 → 14%), and the stays are longer (median
  4.6 → 6.0 s, 4.0 → 4.9 s).
- **Fights as long or longer**: seed for seed the shooting is **6.9 s longer** (standard error
  3.4 s; 90 fights longer, 77 shorter, 32 the same). Shooting median 32.6 → 42.5 s when they draw,
  40.5 → 38.4 when you shoot first. The whole fight's median is 48.8 → 50.3 and 51.8 → 54.0 s.
  45-90 s of shooting is 32 → 29% and 28 → 26%, inside the noise of a hundred fights.
- **As dangerous**: hits on you +0.15 a fight seed for seed (standard error 0.12); you down
  63 → 68% and 53 → 50% (22 fights you went down only on posts, 17 only on base, when they draw;
  10 and 12 when you shoot first).
- Stays ended to go and look (`stays.txt`): 140 → 161 and 96 → 130, from more stays (21 → 21%,
  15 → 20% of stays). Go round on you 94 → 141 and 130 → 121.
- **The frame:** the gang's brains 1.78 → 1.50 ms, the frame 17.5 → 15.3 (`perf.txt`). Base ran
  beside another run, so the drop is the machine. As a share of the frame the brains are the
  same (10.2% / 9.8%): the narrow check costs nothing seen.
- **Determinism:** `same_fight.py`, 20 fights (seeds 1-4, every setup, they draw) run again on the
  branch head against the run's own: DETERMINISM.

## What's left (the next steps, in #531's order)

- **Stepping out and back in** at the post: he stays bladed and points; a lean out to aim, then
  back, is the next part of this cover kind (the issue's last comment).
- The `regular` post style (dials by seed) aims rather than points: only `cross` points now.
- **The galleries**: still no climb (0 in 400 fights).
- **The last drops on arrival**: 120 / 93 within 2 s, and the wide covers' check counts a
  careful player's own cover as nothing (above).
- A blind playtest and a film for Sean once these are in.
