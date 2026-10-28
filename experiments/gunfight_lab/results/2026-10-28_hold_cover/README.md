# Holding cover (2026-10-28; issue #465, #294; branch `claude/gameplay-cover-moves`)

Sean (2026-10-28): the saloon fight (D+) is fun; now the gang should move more, with purpose: up
the stairs, to real cover, behind the timber posts, never erratically. This is the first step: the
measures, the baseline, and the fault behind the erratic moves (#294, cover dropped on arrival).

## The run

D+ (the lab's Y: `--variant=D --fixes=all+pain_fight+floor_fight+odds+flinch`), the careful
player, the five `spec_*` setups, golden hour, the revolver, seeds 1-20, both openings: 200
fights a run (`--deterministic`, so seed for seed). `base` is main at 78b32f1 with the new
measures; `hold` adds `hold_cover`. ~80 min a run on 4 jobs here.

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall,spec_stair,spec_gallery,spec_back,spec_front \
    --hours=golden --weapons=revolver --styles=careful --bodies=studio --variant=D \
    --fixes=all+pain_fight+floor_fight+odds+flinch --opening=,shoot --seeds=1-20 --jobs=4 --out=build/gf/<run>
python3 experiments/gunfight_lab/moves.py build/gf/base build/gf/hold     # moves.md
python3 experiments/gunfight_lab/quits.py build/gf/<run>                   # quits_*.md
```

## The new measures (`fight.gd` `_watch_moves`, `moves.py`)

Each man's **runs** for cover (`moves`: from, to, the straight line and the way, metres run,
seconds, how it ended, to a post, up on the galleries, a climb) and **stays** behind it (`stays`:
how long, how long up shooting, hits taken and given there, why he left; and for a drop, `drop`:
whether he saw you, the eye he chose it by and the one he dropped it against). A **post** is a spot
within 0.6 m of one of the spec saloon's posts (the galleries' in the hall, the hall stair's, the
street balcony's); **up** is 2 m over the hall floor. Hits on you from up there: `hits_from_up`.

## What was wrong

Of 1,580 arrivals in cover, **531 were left within 2 s** ("you can see him there now"), 211 within
half a second, and the man shuffled 1-2 m to the next spot and often dropped that too. Traced
(`drop`, in a few fights first): in three drops of four **he couldn't see you**. His cover was
checked every half second against his latest guess of where you were, and that guess moved with
every sound he took for yours; and a shot he heard was placed where it was made, at your gun, so
he took your eyes to be 1.6 m over that, 3 m off the floor, where the bar and the tables hide
nobody. Every one of those spots still hid him from the idea of you he'd chosen it by.

## The fix: `hold_cover` (in `OutlawBrain.D_FIXES`)

- Behind cover he holds it against your eyes when he sees you; else against the idea of you he
  chose it by (`cover.eye`, `_held_eye`), moved only by what he's sure of: a ball into him or past
  him, a friend calling where you are (`_sure`). A guess at a sound doesn't move him.
- A man's sound he takes for yours puts you where you'd stand: a shot 1.4 m under where it was
  made, a voice 1.6 m (`SOUND_HEIGHT`).

## Before and after (`moves.md`, `quits_*.md`)

| Run | Opening | Runs a man | Run m (med) | Stays a man | Stay s (med) | Left within 2 s / 0.5 s of getting there | Shooting s (med) | 45-90 s | Hits on you | You down | Anyone quits |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 3.1 | 2.3 | 2.8 | 1.6 | 337 / 133 of 854 (39%) | 32.0 | 28% | 2.5 | 62% | 37% |
| **hold** | they | 2.6 | 2.7 | 2.3 | **3.3** | **160** / 85 of 703 (**23%**) | 30.9 | 30% | 2.5 | 67% | 29% |
| base | you | 2.7 | 2.4 | 2.4 | 2.6 | 194 / 78 of 726 (27%) | 37.5 | 27% | 2.0 | 51% | 50% |
| **hold** | you | 2.5 | 2.5 | 2.1 | **3.6** | **120** / 73 of 636 (**19%**) | 35.9 | 21% | 2.1 | 49% | 53% |

- **Drops on arrival halve** when they draw first (39% → 23% of arrivals), down a third when you
  shoot first; he stays in his cover about twice as long (median 1.6 → 3.3 s, 2.6 → 3.6 s), and
  makes fewer, longer runs.
- **The fights are as long and as dangerous:** seed for seed the shooting is 0.4 s shorter, with a
  standard error of 2.4 s (68 fights longer, 61 shorter); the player down 62% → 67% and 51% → 49%;
  hits on you the same.
- **The frame:** the gang's brains 3.05 → 2.89 ms a frame here (fewer cover searches: one is
  ~85 ms of rays spread over its ticks, `gf_coverwhy`), the whole frame 16.7 → 16.0 (`perf.py`;
  4 jobs at once, so noisy).
- **Determinism:** `same_fight.py`, 20 fights run twice on the fix: 20 of 20 the same.

## What's left (the next steps, issue in `next session`)

- **Leaving cover to look for you** is now the first reason a stay ends (555 of 1,339 stays):
  4 s without seeing or hearing you and he walks out at where you were, though you're behind the
  table 6 m off. The careful player pops up every few seconds, so this is most stays.
- Of the drops left (280 within 2 s): 64 he sees you (as he should), 179 after a ball past him
  moved his idea of you (sure, so a fair reason), 37 against an eye still 3 m up: Senses places a
  sound by a man it can half see (`_in_view`) where it was made, without the brain (`_on_noise`).
- **Posts:** 27-38 stays at a post a hundred fights, a few seconds each (0.4-0.7 s a man a fight). A gallery post is 20 cm
  (8x8 in), and `Cover.hidden_at` asks for a crouched man's width either side (`SHOULDERS` 0.18,
  36 cm): from right behind the post by the bar, `gf_coverwhy` turns down every spot by a post as
  "too low to hide him" and picks the bar's back, a 13 m run round its end.
- **The galleries:** no climb in 400 fights. The gallery floor is 3.66 m over the hall's and a
  candidate spot is dropped to a floor within `Cover.LEVELS` (1 m) of his own, so no spot up
  there is ever looked at from the hall.
