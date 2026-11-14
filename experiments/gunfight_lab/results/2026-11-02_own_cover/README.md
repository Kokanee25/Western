# Your own cover isn't his (2026-11-02; issue #583, after the galleries, #572; branch `claude/gameplay-drops-on-arrival-8bm2c4`)

The last of the drops on arrival. A man who got to a wall or a trough often left it inside 2 s,
"you can see him there now", while you were crouched behind your own cover. `Cover._blocked` cast
the line from your eye to him and counted the first thing it met only if that was within 1.6 m of
him (`HUGGING`; a share of the distance for men who know the town): so with your own crate or wall
first on the line, his cover behind it never counted and he read himself as seen.

## The fix: `own_cover` (in `OutlawBrain.D_FIXES`)

- `Cover._blocked`, when the first thing on the line is far from him, asks one more ray from his end
  back toward you, as long as the hugging reach (`_near_him`): if it meets something within reach,
  that's his cover and the line counts as stopped. The side checks the same. Only for lines already
  stopped by something (a clear line is still clear), one short ray each.
- The same for a post (`_narrow`'s arm's-length check) and the balustrade's screen (`screen_share`,
  one batch of reverse lines).
- Used by the hold check in `_hide` and by the search (`_seek_cover`, `_climb_choose`: the search's
  `evaluate`). Without the fix every check is the one before.
- Tests (`tests/test_outlaw_tactics.gd`): "your own cover doesn't make his seen" (a crate he's behind,
  your board in front of you: hidden ducked, his standing head not, the open still open; the search
  finds the low spot only with the fix), "behind his cover your own doesn't drive him out" (`_hide`
  keeps him hidden with the fix, sends him off without it).

## Two bugs the playtest found (in both runs below)

The blind playtest of D+ (`docs/playtests/2026-11-02-gunfight-d-plus.md`) found men frozen for a
minute shouting "Reloading! Cover me!" every frame, and a cornered hothead shouting "You'll have to
kill me!" forty times in half a second. Both were on main:

- `floor_fight` asks for a reload every tick from the floor, and `_start_reload` started it afresh
  each time: it never ended. A reload once started now runs to its end (test "a reload once started
  runs to its end").
- `_break_odds`, far past his nerve and cornered, said "cornered" and logged the decision every tick.
  Now once while he stays cornered.

Both change the fights (`say` draws from his dice, as his shots do), so base and own were both run
with them.

## The runs

400 fights: the five `spec_*` setups, golden hour, the revolver, the careful player, Studio bodies,
D+ (`all+pain_fight+floor_fight+odds+flinch`), seeds 1-20, both openings. Base is the same branch
with `own_cover` left out of an explicit `--fixes` list. Each run from its own copy of the tree,
side by side, two jobs each.

| Measure (`moves.py`, `moves.md`) | Base, they draw | Own, they draw | Base, you first | Own, you first |
|---|---|---|---|---|
| **Dropped within 2 s / 0.5 s of arriving** | **168 / 77 of 880** | **87 / 37 of 879** | **84 / 38 of 461** | **30 / 18 of 506** |
| Stay behind cover (median) | 5.0 s | 7.6 s | 5.0 s | 7.0 s |
| Stays ended "leave his cover" (`stays.txt`) | 360 | 153 | 158 | 61 |
| ... "look for you" / "go round on you" | 196 / 117 | 304 / 172 | 95 / 58 | 150 / 98 |
| Shooting (median) | 43.5 s | 46.8 s | 26.9 s | 24.1 s |
| Fights shooting 45-90 s | 31% | 32% | 21% | 25% |
| Hits on you | 2.3 | 2.2 | 1.7 | 1.7 |
| You down (down or dead) | 72% | 61% | 53% | 45% |
| Stays at a post | 193 | 94 | 76 | 41 |
| Climbs (`climbs.txt`) | 17 | 30 | 7 | 31 |
| Stays up | 264 | 234 | 124 | 130 |
| Hits on you from up | 29 | 20 | 29 | 26 |

- **The drops on arrival halved**: 168 -> 87 and 84 -> 30 within 2 s. The stays ended by being seen
  fell by 60%, and men left their cover instead to look for you or go round on you: by choice.
- **Seed for seed** (`pairs.txt`): shooting 3.5 s longer (SE 3.5; 89 longer, 87 shorter, 24 the
  same), hits on you 0.07 fewer (SE 0.12): inside the noise. You go down less (72 -> 61% and 53 ->
  45%; about 1.7 SE each) with the hits the same: more fights end in a lull or with them breaking
  off (lulls 4 -> 12 and 27 -> 31, broke off 15 -> 17 and 9 -> 16).
- **Fewer stays at a post** (193 -> 94): with a wall or a trough now reading as cover where your own
  cover stood between, a post (the narrow cover, `posts`) is chosen less; steps out from one fewer
  with it (`steps.txt`). **More climbs** (17 -> 30, 7 -> 31): the gallery's rail is chosen more.
  A climber at the rail gives little (hits on you from up 29 -> 20, 29 -> 26): noted, not tuned.
- **Quits** (`quits.md`, both runs together) as #572's.
- **The frame** (`perf.txt`): the gang's brains 1.08 -> 1.21 ms here (~0.08 at Sean's), frame
  11.6 -> 11.7, people 5.8 -> 5.9. Both runs side by side.
- **Determinism**: `same_fight.py`, 20 fights (seeds 1-4, every setup, they draw) run twice on the
  branch with main merged: 20 of 20 the same.
