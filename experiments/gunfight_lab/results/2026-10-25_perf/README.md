# The performance phase, step 1: the single-core surprises (2026-10-25)

Brief `docs/briefs/more-cores.md` (its step 4, "the two surprises"); issue #373.

**The bench:** 10 fights in the spec saloon, one game at a time (`--jobs=1`), the careful player,
the game's D, golden hour, revolver, the five setups on seeds 1–2:

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall,spec_stair,spec_gallery,spec_back,spec_front \
    --hours=golden --weapons=revolver --styles=careful --seeds=1-2 --variant=D --jobs=1 --out=build/perf/NAME
python3 experiments/gunfight_lab/perf.py build/perf/P_base build/perf/NAME     # the table (step1.txt)
```

Headless, this workspace's core (slower than the 2026-10-24 session's: the same game's frame
measured 28.7 ms here against 19.7 there), so only rows in this folder compare with each other.
x0.65 for Sean's.

| Run | Frame ms | Worst 5% | fire | floor_marks | What changed |
|---|---|---|---|---|---|
| `P_base` | 28.7 | 57.0 | 2.02 | 1.14 | main + `claude/gameplay-saloon-cover` |
| `P_hole_x` | 27.1 | 45.9 | 0.84 | 1.12 | a hole re-checks only its member (`recheck`), with measuring timers |
| `P_step1_x` | 26.3 | 44.5 | 0.68 | 0.10 | and the fire's grid only when needed, floor marks' drying redrawn once a second, timers |
| **`P_step1`** | **26.2** | **41.4** | **0.15** | **0.10** | and a never-analysed building's hole worked out from what rests on it (`member_alone`) |

At Sean's: a frame ~18.7 -> ~17.0 ms, its worst 5% ~37 -> ~27 ms (before drawing). The other
systems are within the runs' noise (±3%).

## What it was

- **`fire` with nothing burning (2.02 ms) was the structures' load checks.** Every ball that holed a
  board (`StructureMember.add_hole`/`carve_hit` -> `damaged`) queued the whole spec saloon (5,150
  members) to settle: ~0.5 s of work, spread at 400 members a frame. Now:
  - A hole weakens only its own member's section, so while the building stands as last worked out
    (`Structure._as_analysed`: its last settle broke and dropped nothing, and nothing's asked it to
    settle since), `StructuralAnalysis.recheck(m)` works out that member again on what came down onto
    it then. Only a member that's now over settles the building.
  - A building nothing has asked to settle (as built: the first hole) has no analysis to re-check.
    `member_alone(structure, m)` works out `m` from the members resting on it, directly or through
    others: loads only come down, so that's its whole load. A board is a handful of members.
    Before, the first hole in any building was the whole analysis: in a short fight
    (spec_front, seed 1, 4.5 s) 2.2 ms a frame, about 35 ms on each of 13 frames.
  - `FireSystem._rebuild_grid` placed every member in town every 2 s (0.22 ms a frame) whether or not
    anything was hot. It's built only while something is heated, burning or spilt.
  - `test_loads::test_a_hole_checks_its_own_member`: both give exactly what the whole building's
    analysis gives the member, and a hole doesn't settle the building.
- **`floor_marks` (1.14 ms) was redrawing decals.** The day clock ages wet cells every frame
  (`FloorMarks.age`), and each aged cell marked its chunk to redraw: about one chunk (~1 ms) a frame
  while anything was wet. The clock's drying is redrawn once a second (`AGE_REDRAW`); a cell that
  dries, or a jump of hours (sleep, tests), at once. The boots (0.01 ms) were never the cost.

How it was found: `Prof` timers round each part (`x_*`, in the `_x` runs; taken out after),
counts of analyses begun, chunks drawn and cells aged.

## The seeds

Nine of ten fights are the same frame for frame. One (`spec_back` seed 1) parts at 28.9 s by a
centimetre in your position, then ends 0.25 s later with the same shots and hits. **It's older
than this change: a fight already depends on how busy the core is.** The same code, that fight run
twice side by side (`LOAD1`, `LOAD2`), came out 36.4 s with 12 of the gang's shots and 36.1 s with 13.
The likely cause: carved members' meshes and collision faces come back from the native plugin's
worker threads (`voxels.start_mesh()`; `VoxelWorks._collect` polls each frame), so the frame a
carved board's new shape is swapped in depends on the main thread's load. It bears on step 2
(physics on its own thread), where the seeds parted too: swapping at a fixed frame after the
carve (waiting on the thread if it isn't done) should hold a fight to its seed whatever the load.
