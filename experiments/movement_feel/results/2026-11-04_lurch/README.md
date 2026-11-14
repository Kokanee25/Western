# The lurch every few steps (#643), 2026-11-04

Sean, build 3184: "takes like 3–4 steps then it's like it jerks forward for a step and goes further
than a normal step". Build 3184 is the one that asked him to tick N's **Real look** (#641), which is
saved, so it stays on.

**The walk itself is even.** Headless, the game's street, 30 steps down Main Street at 2.8 m/s
(`tests/test_walk_steps.gd`, `walk_steps_headless.csv`): every step 0.980 or 1.027 m (a footfall
lands on one tick or the next), every tick 0.0467 m. No step up, push or surge.

**The frames aren't.** Drawn (lavapipe, 640x360, 600 ticks, x 30 -> 2 m along the street's middle;
`tools/walk_frames.gd`), frames over 1.25x the median and the worst:

| run | file | over 1.25x | worst | spacing of the spikes |
|---|---|---|---|---|
| real look, SDFGI on (as in 3184) | `real_sdfgi_on.csv` | 28 | 1.74x | every 0.84 m |
| real look, SDFGI on (first run) | `first_real_sdfgi_on.csv` | 32 | 1.81x | every ~0.84 m |
| real look, SDFGI off (first run) | `first_real_sdfgi_off.csv` | 8 | 1.47x | none |
| painted look | `first_painted.csv` | 18 | 1.40x | none (clusters) |
| **real look, the fix** (SDFGI off in `real_dials.json`) | `real_fixed.csv` | **1** | **1.27x** | – |

The spikes are GPU time (the viewport's measured render CPU stays ~5 ms). SDFGI's four cascades
(cells 0.2/0.4/0.8/1.6 m, 128 cells) each scroll when the camera passes their drag margin, every
1.6/3.2/6.4/12.8 m; a scroll re-voxelises the slab's geometry and re-runs the distance field's jump
flood and occlusion for the whole cascade on that frame (Godot 4.7.2 `gi.cpp`
`SDFGI::update`/`render_region`). Here every scroll is a spike of about the same size (1.3–1.7x),
evenly every 0.84 m (a step is 0.98 m). At Sean's frame rate a scroll that pushes a frame past the
16.7 ms vsync shows a frame twice, and with no physics interpolation the next one carries two
ticks: the jerk forward. Why he feels it every 3–4 steps rather than every step isn't measured
(no F12 from him yet); likely only the costlier scrolls (a bigger cascade, or two on one frame)
tip his frame over.

The first runs were a WIP test (`tests/test_walk_frames.gd`, not kept) with the same walk and
columns `usec` (wall) and `rcpu`/`rgpu`; `real_*` are the tool's.

Not measured here: Sean's own frame times (no F12 report on the issue yet).
