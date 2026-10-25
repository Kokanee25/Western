# The performance phase, step 1: the single-core surprises (2026-10-25)

Brief `docs/briefs/more-cores.md` (its step 4, "the two surprises"); issue #373.

**The bench:** 10 fights in the spec saloon, one game at a time (`--jobs=1`), the careful player,
the game's D, golden hour, revolver, the five setups on seeds 1–2:

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall,spec_stair,spec_gallery,spec_back,spec_front \
    --hours=golden --weapons=revolver --styles=careful --seeds=1-2 --variant=D --jobs=1 --out=build/perf/NAME
python3 experiments/gunfight_lab/perf.py build/perf/M_base build/perf/NAME     # the table (step1.txt)
```

Headless, on this workspace's core (slower than the 2026-10-24 session's: the same game's frame
measured 28.7 ms here against 19.7 there), so only rows in this folder compare with each other.
x0.65 for Sean's.

## What merges (on main as of #375 and #332)

| Run | Frame ms | Worst 5% | fire | of it, the grid | floor_marks |
|---|---|---|---|---|---|
| `M_base`: main + `claude/gameplay-saloon-cover` | 26.1 | 40.2 | 0.34 | 0.22 | 1.21 |
| **`M_step1`: and this branch** | **25.7** | **37.9** | **0.13** | **0.00** | **0.12** |

The same ten endings. The two systems are 1.3 ms a frame lighter (~0.85 at Sean's). The mean
frame moves less (0.4 ms) because the people's systems ran 2–3% high in that run, within the
noise.

- **The fire's grid only when needed.** `FireSystem._rebuild_grid` placed every member in town every
  2 s (0.22 ms a frame) whether or not anything was hot. It's built only while something is heated,
  burning or spilt; the first tick with something to do builds it up to date.
- **Floor marks' drying redrawn once a second.** The day clock ages wet cells every frame
  (`FloorMarks.age`), and each aged cell marked its 4 m chunk to redraw: about one chunk (~1 ms) a
  frame while anything was wet. What the clock dries is redrawn once a second (`AGE_REDRAW`); a cell
  that dries out, or a jump of hours (sleep, tests), at once. The boots (0.01 ms) were never the cost.

## What was found and is now main's

`fire` with nothing burning (2.02 ms on the old base) was the structures' load checks. Every ball
that holed a board (`StructureMember.add_hole`/`carve_hit` -> `damaged`) queued the whole spec
saloon (5,150 members) to settle: ~0.5 s of work a time, 400 members a frame. The first hole in a
never-settled building was ~35 ms on each of 13 frames.

This branch fixed it first with a re-check of the holed member alone (`P_*` rows, the old base:
fire 2.02 -> 0.15). Meanwhile the blast-freeze session's #375 merged an incremental analysis (only
what a change reaches is worked out again; a big building's first analysis a slice a frame as
it's built), which takes the same fights' fire to 0.34 on its own (`M_base`). The re-check was
dropped in the merge as redundant. The `P_*` rows stay as the record of what the holes cost.

| Run (old base) | Frame | Worst 5% | fire | floor_marks |
|---|---|---|---|---|
| `P_base` | 28.7 | 57.0 | 2.02 | 1.14 |
| `P_hole_x`: the hole re-check (timers in) | 27.1 | 45.9 | 0.84 | 1.12 |
| `P_step1_x`: and the grid, floor marks (timers in) | 26.3 | 44.5 | 0.68 | 0.10 |
| `P_step1`: and the first hole from what rests on the member | 26.2 | 41.4 | 0.15 | 0.10 |

How it was found: `Prof` timers round each part (the `_x` runs; taken out after), counts of analyses
begun, chunks drawn and cells aged, and a logged fight's settle requests.

## The seeds

On the old base, nine of ten fights were the same frame for frame with and without the change; one
(`spec_back` seed 1) parted at 28.9 s by a centimetre in your position. **That's older than these
changes: a fight already depends on how busy the core is.** The same code, that fight run twice
side by side (`LOAD1`, `LOAD2`), came out 36.4 s with 12 of the gang's shots and 36.1 s with 13.
The likely cause: carved members' meshes and collision faces come back from the native plugin's
worker threads (`voxels.start_mesh()`; `VoxelWorks._collect` polls each frame), so the frame a
carved board's new shape is swapped in depends on the main thread's load. It bears on step 2
(physics on its own thread), where the seeds parted too: swapping at a fixed frame after the carve
(waiting on the thread if it isn't done) should hold a fight to its seed whatever the load.
