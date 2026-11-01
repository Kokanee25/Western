# Watching the spot (2026-11-01; issue #477, after #465 / PR #476; branch `claude/gameplay-cover-moves-2-hold`)

The second step of "men who move with purpose". After `hold_cover`, the first reason a stay
behind cover ended was **"look for you"**: `_combat` sent a man to hunt once he'd neither seen nor
heard you for 4 s. The careful player pops up every few seconds, so he walked out of good cover
at where you'd been, into your gun.

## The fix: `watch_spot` (in `OutlawBrain.D_FIXES`)

Behind cover (`Tactic.HIDDEN`) he goes to look only once he's **lost you** (`_lost_you`): no idea
where you are, or his idea of you more than `WATCH_NEAR` (15 m) off, or nothing seen or heard
for `WATCH_QUIET` (14 s), or `WATCH_ALONE` (8 s) with no friend standing in earshot to keep you
busy. Till then he holds and watches that spot. He still moves for a reason: an angle (his flank,
`_flank_after`, 10-18 s in a cover or 4 peeks), cover seen round or shot away (`_hide`), a friend
down (`_wounded_mate`), you reloading or just hit (`_press_why`). In the open he still goes to
look at 4 s, as before. Tests: `test_outlaw_tactics` "watches where you were", "stays behind his
cover".

## The run

Both on main at 976f112 (`keep_stride` on in the game, so the D+ baseline taken afresh): `base` is
main, `watch` adds the fix. D+, the careful player, the five `spec_*` setups, golden hour, the
revolver, seeds 1-20, both openings: 200 fights a run, `--deterministic`, seed for seed. Two runs
at once on 2 jobs each (~113 min each here).

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall,spec_stair,spec_gallery,spec_back,spec_front \
    --hours=golden --weapons=revolver --styles=careful --bodies=studio --variant=D \
    --fixes=all+pain_fight+floor_fight+odds+flinch --opening=,shoot --seeds=1-20 --jobs=2 --out=build/gf/<run>
python3 experiments/gunfight_lab/moves.py build/gf/base build/gf/watch            # moves.md
python3 experiments/gunfight_lab/quits.py build/gf/<run>                          # quits_*.md
python3 experiments/gunfight_lab/perf.py build/gf/base build/gf/watch             # perf.txt
python3 experiments/gunfight_lab/results/2026-11-01_watch_spot/stays.py build/gf/base build/gf/watch  # stays.txt
```

## Before and after

| Run | Opening | Stays ended "look for you" | Stays a man | Stay s (med) | Hunts a man | Go round on you | Runs a man | Running s a man | In the open s a man | Shooting s (med) | 45-90 s | Hits on you | You down |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 303 of 731 (41%) | 2.4 | 3.3 | 1.56 | 39 | 2.7 | 4.6 | 10.4 | 32.5 | 31% | 2.4 | 69% |
| **watch** | they | **152** of 638 (**24%**) | 2.1 | **4.9** | 1.09 | **74** | 2.4 | 3.7 | 8.9 | 32.8 | 34% | 2.2 | 64% |
| base | you | 239 of 641 (37%) | 2.2 | 3.4 | 1.29 | 49 | 2.5 | 3.8 | 13.1 | 38.0 | 23% | 2.1 | 53% |
| **watch** | you | **98** of 569 (**17%**) | 1.9 | **4.4** | 0.92 | **73** | 2.3 | 3.9 | 13.4 | 38.2 | 28% | 2.0 | 51% |

- **Stays ended to go and look halve, and better** (303 → 152, 239 → 98). "You can see him there
  now" (`leave his cover`) is the first reason a stay ends now, as it should be: you came round it.
- **He stays longer** (median 3.3 → 4.9 s, 3.4 → 4.4 s), makes fewer runs and **goes round on you
  nearly twice as often** (39 → 74, 49 → 73): with the hunt out of the way, the flank at 10-18 s in
  a cover is reached. Hunts a man a fight 1.56 → 1.09 and 1.29 → 0.92.
- **Time running and in the open**: running 4.6 → 3.7 s a man when they draw (3.8 → 3.9 when you
  shoot first); in the open 10.4 → 8.9 (13.1 → 13.4).
- **The fights are as long, and as dangerous within the noise:** seed for seed the shooting is
  1.1 s longer, standard error 2.5 s (79 fights longer, 54 shorter, 67 the same); 45-90 s of
  shooting 31 → 34% and 23 → 28%. Hits on you 0.10 fewer a fight (standard error 0.10); you down
  69 → 64% and 53 → 51%: 26 fights you went down only on base, 19 only on watch (a sign test
  gives p ≈ 0.4, so no sure change). Hits on you from up on the galleries 25 → 24, 29 → 39.
- **The frame:** the gang's brains 1.12 → 1.04 ms a frame here, the frame 9.7 → 9.6, p95 17.8 →
  17.7 (`perf.txt`; 4 games at once, noisy).
- **Determinism:** `same_fight.py`, 20 fights (seeds 1-4, every setup) run twice on the fix: 20 of
  20 the same.

## What's left (the next steps, in #477's order)

- **Posts as narrow cover**: still 18-35 stays at a post a hundred fights (the post is 20 cm,
  `Cover.hidden_at` asks for 36 cm; the body can't stand side-on yet).
- **The galleries**: still no climb in 400 fights (candidates within `Cover.LEVELS` of his floor).
- **The last drops on arrival**: 145 / 117 within 2 s of arriving (some against an eye still 3 m
  up: `Senses._on_noise` places a sound by a half-seen man at the gun).
- A blind playtest and a film for Sean once the posts or the stairs are in.
