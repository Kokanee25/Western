# 2026-10-11: he keeps his momentum; a shot pushes with the ball's

Sean: "as real as possible so just drops if dead esp running". Fault 2 of the baseline, and the
scripted pushes.

**The change** (`src/bodies/human_body.gd`, `src/structures/structure.gd`):
- While he stands, each part's velocity is tracked from its script-driven movement
  (`_track_carry`; a jump faster than 12 m/s is a teleport and counts as still).
- `go_limp()` hands each part its own velocity, plus `push`, which is now only a blast's wind.
- Gone: the chest's `push × 4` shove and the random level kick.
- A bullet knockdown calls `go_limp()` and gives the part it hit the ball's own momentum. That's
  m(v_in − v_out): 4.5 N·s for a stopped .45, where it used to be 1.2 m/s on all of him, 96 N·s.
- A ball into a man already down gives its momentum too (it used to be twice that).
- Rubble knocks a man down with its own momentum on the part it struck. It used to be up to 3 m/s
  on all of him.

**Before → after** (`compare.py diff build/physics_lab/base build/physics_lab/carry`; base is
`baseline/`):

| | momentum into the fall | on along his way by hip height | in all | settled |
|---|---|---|---|---|
| running 3.5 m/s, blacks out | 279 → **2** N·s, now **279** | 0.04 → **1.03 m** | 0.46 → **1.68 m** | 1.85 → 2.35 s |
| walking 1.4 m/s, blacks out | 112 → **2**, now **112** | 0.04 → **0.50 m** | 0.21 → **0.84 m** | 3.68 → 2.63 s |
| running, shot in the chest (the game as it was / now) | old: thrown back at 1.2 m/s against his run; now: the ball's 4.5 N·s | 0.36 m backwards → **1.01 m on** | | |
| standing, shot (the ball now) | | 0.01 m | 0.55 m | 2.53 s |

- `C_run_blackout_before_after.png`, `B_walk_blackout_before_after.png`: top is before, bottom
  after, at matched times. He pitches forward along his run and ends face down, where before he
  folded onto his knees on the spot. The fixed cameras were set for the old fall, so he slides
  partly out of frame.
- `C_run_shot_ball_before_after.png`: the old shot while running (thrown onto his back, back the
  way he came) above, the new one (on along his run) below.
- Also: his resting place no longer depends on which way he faces. At five headings it now varies
  3 cm sideways; it was 14 cm. A fall from the crouch now settles (3.4 s; it never did).
- Falls against the wall and the table take ~7.4 s to settle now, a slow slide (`--seconds=20`).

Not changed: fault 1 (the fold straight down from standing), 3 (limbs through his body),
4 (joint overruns), and blasts' throw. Tests: 369 pass; body hits to stop a man still average 1.54.
