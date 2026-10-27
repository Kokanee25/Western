# More cores, step 5: the fire scene's hitches, single-core (2026-10-27)

`docs/briefs/more-cores.md` "Step 5" (issue #397). This workspace's VM (4 vCPUs, ~2.1 GHz; x0.65
for Sean's core), headless, `--fps=60`, one game at a time, nothing else running. Every run is the
blast-freeze lab's scenario: the spec saloon, six floor boards lit and left 20 s (~170 hot members,
20 burning), a stick at (6, 0.8, 6) in the hall, every frame recorded from 1 s before to 8 s after:

```sh
printf 'bf_blast at=6.0,0.8,6.0 fire=6 burn=20 fuse=1 seconds=8 [player=12.0,0.8,2.0] out=RUN.json\nquit\n' > bf.txt
python3 tools/bridge.py run bf.txt --headless --fps=60 [--game-args=--deterministic|--fire-bands=off]
python3 experiments/blast_freeze/summary.py RUN.json [RUN2.json ...]     # mean, p95, worst, timers
python3 experiments/blast_freeze/summary.py --same RUN_A.json RUN_B.json # two runs frame for frame
```

**before** is this branch's first commit (87a34dc: main at b406870 with the timers below and
nothing else), from its own worktree with this lab file; **after** the branch's head. **hall**:
the player in the saloon's hall 7 m from the stick (`player=12.0,0.8,2.0`: Sean's case, every
structure in the near band); **far**: where he starts, 99 m off (the saloon in the far band).
Two runs of each; the trimmed runs here (`before_*_1.json`, `after_*_1.json`: each frame's time,
counts and largest eight timers) and every run's summary (`summaries.txt`). Untrimmed runs in
`build/step5/runs/` while this workspace lasts.

## The numbers (ms a frame, this core)

| | before the stick (the fire burning, 1 s) mean / p95 / worst, frames > 20 ms | after the stick's first second (7 s) mean / p95 / worst, > 20, > 50 | the stick's 3 frames together |
|---|---|---|---|
| hall, before | 18.8 / 45.4 / 90, 51 of 119 | 32.1 / 66.4 / 133, 279, 80 of 420 | 478 |
| hall, before (2nd) | 18.3 / 44.8 / 99, 50 | 32.5 / 73.8 / 131, 278, 74 | 497 |
| **hall, after** | **7.0 / 9.7 / 30, 1** | **21.8 / 40.2 / 56, 222, 5** | 467 |
| hall, after (2nd) | 6.7 / 9.5 / 32, 1 | 21.0 / 39.7 / 66, 213, 4 | 504 |
| far, before | 21.1 / 48.5 / 100, 52 | 34.6 / 72.7 / 140, 290, 84 | 565 |
| far, before (2nd) | 21.5 / 48.0 / 117, 53 | 32.1 / 67.1 / 123, 277, 70 | 594 |
| **far, after** | **10.7 / 14.8 / 38, 1** | **24.3 / 42.8 / 74, 246, 7** | 516 |
| far, after (2nd) | 9.4 / 13.2 / 32, 1 | 23.5 / 43.3 / 62, 230, 7 | 424 |

Every run breaks the same 306 members (`broken_ids_hash` 1650757771, as the lab's eight runs of
2026-10-25), cuts the same 22 boards, leaves 256 pieces of rubble and 21 members burning. Before
the stick the fire is the same frame for frame, before and after this step (every frame's count
of hot members); after it, from 2.2 s on, the collapse comes in a slightly different order (the
smaller slices): 26 of 480 frames' hot counts differ by a few, and 761
`member_broken` events against 746 (pieces of the same members), to the same end.

**By system, hall** (mean / worst a frame; before the stick, then after its first second):

| | before the stick: before → after | after the stick: before → after |
|---|---|---|
| `civilian_brain` | 9.8 / 59 → **0.4 / 1** | 9.5 / 51 → **0.4 / 2** |
| `fire` (all its parts and the smoke) | 2.8 / 82 → 0.9 / 10 | 7.8 / 102 → 6.6 / 27 |
| `fire_grid` | 0.2 / 21 → 0.0 / 0 | 0.2 / 27 → 0.0 / 5 |
| `smoke_raster` (+ vents) | 1.0 / 80 → 0.4 / 3 | 0.9 / 85 → 0.3 / 4 |
| `fire_loads` (the load check) | 0.1 / 6 → 0.1 / 6 | 4.8 / 26 → 5.5 / 25 |
| Jolt's step (`step`, PhysicsWindow) | 1.0 / 1 → 1.0 / 2 | 7.3 / 35 → 7.9 / 34 |
| our physics ticks (`window`) | 16.4 / 88 → 4.9 / 13 | 23.1 / 113 → 12.4 / 38 |

At Sean's clock (x0.65) the burning hall before the stick is ~4.5 ms a frame, worst ~20; after it
~14, worst ~36-43; the stick's three frames ~300-330 ms together, as before.

## What each part was, and what it is now

**(a) The townsfolk's looks at the fire** (`civilian_brain`, 9.8 ms a frame, 59 worst): 98% of it
was `FireSystem.fire_near`. A calm townsman looks 30 m round him for a fire to fight, twice a
second; through the fire's 2 m grid that's every cell of a 60 m cube and every member in it (the
whole saloon, its dedupe dictionary), ~3 ms a look. Now `fire_near` reads **the fire's picture**:
the burning members and their boxes, taken once a physics frame (and again after anything
catches), each look a loop over what's burning (20-200). The men's looks were already staggered
(each man's dice). Same answers: the members it finds are the grid's burning ones (and rubble
wherever it is now, which the grid had where it lay at its last rebuild).

**(b) The fire's periodic work.**
- `_rebuild_grid` (~21-33 ms every 2 s while anything's hot): it walked all 5,150 members of the
  saloon (and the town's) to find the new ones and the broken ones. Now kept up by what changed: a
  structure's members are only ever added at its end (`_walked`: where each structure's walk got
  to), whatever breaks or burns away says so (`Events.member_broken` → `_gone`), rubble that moved
  is placed again as before. What's placed goes in the order the full walk placed it (the
  structures in the group's order, each one's members in its order), so the cells list the same
  members in the same order and the fire spreads exactly as it did (above).
- The smoke field's redraw every 2 s: its `_find_vents` worked out the open cells round all
  ~5,000 members at once (~80 ms on one frame) and its box query was ~10 ms. Now a member's vents
  are worked out when it first smokes after the cells are drawn (the last whole drawing:
  `_solid_next` while drawing), the emit loop runs over the fire's picture (it was over every
  flammable member, 15 times a second), and the members are listed from the grid once and then
  only what the structures gained since.
- The neighbour lists (refreshed at 30 s, rubble 2 s): members that caught together refreshed on
  one tick (~7 ms). Now each a little later by its id (up to 4 s, rubble 0.5 s).
- **The load check** (`fire_loads`, not in the issue's list, now the fire's largest share): its
  slices assumed ~30 µs a member; `bf_analyse` (new) measures ~60 µs a member here on a whole
  analysis (the spec saloon's 5,150 in ~340 ms) and ~100 µs near a blast's damage (the joists and
  their loads), so one slice of 150 was ~15-25 ms and always past its 8 ms budget. The slices are
  now 50 (settling) and 40 (the routine look) and `Structure.MEMBERS_A_MS` 15 (was 30). Most
  frames of a collapse take two slices (~10 ms): the 8 ms budget itself (#374's, how fast a
  building comes down) is unchanged, so the load check's mean is as it was; its worst frames are
  gone.

**(c) The stick's frame and the ones after.** Measured, and mostly not where the brief thought:
- The census of the stick's frame (`stick_added` in the run): **662 new rigid bodies**, of which
  ~110 are the cut boards' pieces, 162 rubble in all, and **~500 glass shards** (344 from the
  saloon's panes, `StructureMember.shatter`, 8-26 a pane; 156 from the bottles and glasses on the
  bar, `GlassProp`). Run once with the cut pieces not made: the stick's frames barely move
  (`step` 50 → 42 ms, the end-of-frame work 110 → 103). Once with no shards at all: `blast_break`
  70 → 44 ms, the engine's share about the same. So neither "pieces over two or three frames" nor
  "fewer, larger pieces" buys much, and both would change how the blast looks (the goldens): not
  done. What's left is the physics engine taking ~660 bodies in at once and stepping them at the
  falls' 20 velocity and 8 position iterations (`project.godot`): **step 6's** (physics on its own
  thread), and the shard counts the prop lab's and art's to weigh.
- **The rubble hardly sleeps through a collapse:** every break wakes every piece within 2-6 m of
  it, twice (`Structure._wake_near` and the deferred `_rewake`), so ~200 pieces stay awake for the
  5 s the collapse takes, Jolt's step ~8 ms a frame (1.3 before the stick). Tried and **not kept**:
  waking only the pieces whose own box reaches into what broke, once a frame. Awake pieces 2-3 s in
  went ~200 → 56-180 but Jolt's step barely moved (the pieces still settling are the expensive
  ones), and it changed where debris comes to rest: the old wide wake keeps nudging a piece that
  dozed off on a ledge until it slides down, and without it 5 of the store porch's 32 pieces stayed
  up in the full suite (`test_loads::test_porch_comes_down_without_its_posts`, 84% down against
  its 85%). The wake is main's again; step 6 (physics on its thread) is where its cost goes.
- **Every noise cast a ray from every person**, in earshot or not (`Senses._on_noise`): the 22
  cuts' "timber" noises were 985 rays on the stick's frame. Out of earshot (`loudness`, which walls
  and deaf ears only shorten) it now returns first: 166 rays (`cut_wake`, the cuts' wakes and
  noises, 17 → 11 ms on the stick's frame).

**(d) Far members coarser** (`FireSystem.bands`, `FireTuning.near_m` 30 / `far_m` 60,
`middle_every` 2 / `far_every` 4; `--fire-bands=off` the before). A member of a structure past
30 m from the player (its box) is visited every 2nd fire tick, past 60 m every 4th, each on its
own phase (its id), and given the time since its last visit (so it heats, burns and chars at the
same rate; a member coming nearer gets what it's owed, never more than four ticks); a far burning
building looks at its loads every 2nd or 4th time (its charring is marked dirty meanwhile). Chosen
by distance only; no player (most tests) or `step()` (the fire tests, tools) runs everything every
tick. In this scenario (one building, the collapse being the cost) bands on and off were within the
noise (far, after the stick's first second, on this branch before the rubble's wake went back to
main's: 23.1 / 23.4 ms with them, 22.7 without); they're for Sean's case of a fire left
burning while he's elsewhere: 26 game minutes on, far down the street, the town's fire now ticks a
quarter as often.

**For art** (the GPU side, not changed here): `FireSystem._place_lights` keeps at most
`max_lights` (6) OmniLights where the fire is biggest, moved and flickered every frame
(`_flicker`); whether they cast shadows and their ranges are FireFX's/art's. Each SmokeField is one
FogVolume with a 3D texture re-uploaded on every smoke step (15 a second, `_upload`). Nothing
here measures the GPU (lavapipe); Sean's F3 (56-75 ms out front against 5.6 with no fire) is the
number to start from.

## Determinism

- **The lab twice under `--deterministic`, frame for frame** (`same_det.txt`): `after_det_1` and
  `_2` (hall), 600 frames, every frame's tick, what's broken and what's hot the same; the broken
  set the same.
- Every timed run (game mode, wall-clock budgets) broke the same 306 members.

## The gunfight (no change expected, none found)

The gunfight lab's ten D fights in the spec saloon (step 4b's command: `run.py --scenarios=spec_hall
--hours=golden --weapons=revolver --styles=careful --bodies=studio --variant=D --seeds=1-10
--jobs=1`), one run at a time: `s5_1`, `before_1` (the before's worktree), `s5_2`; and `s5_3` on
the branch's head (after the rubble's wake went back to main's; `s5_1`/`_2` had the narrower one).

- **10 of 10 the same twice on this build** (`gunfight_same_s5_1_vs_s5_2.txt`) and **10 of 10 the
  same as the before, event for event** (`gunfight_same_before_vs_s5_1.txt`); the head's `s5_3`
  the same as both (`gunfight_same_s5_1_vs_s5_3.txt`, `gunfight_same_before_vs_s5_3.txt`).
- `gunfight_perf.md`: the frame 12.44 (before) against 12.39 / 12.03 / 12.78 ms, p95 15.08
  against 15.01 / 14.82 / 15.34: within this VM's run-to-run noise; `civilian_brain`, `fire`,
  `structures` the same. (These are faster than step
  4b's 19-24 ms on the same command: the VM, not the build; before and after alternate here.)

## The timers (measurement only, the first commit)

`fire_near`, `fire_neigh` (a neighbour list refreshed), `fire_flight`, `fire_route`,
`civ_fire_look`, `bucket_line`, `smoke_raster`, `smoke_query`, `smoke_vents`, `smoke_upload`;
`cut_unbatch`, `cut_ends`, `cut_relink`, `cut_chunks`, `cut_wake` (its rubble's wake and the
noise), `cut_signals` (a board cut).
The lab: `player=`, `PhysicsWindow`'s split (`window`, `step`, `rest`), rubble and rubble awake a
frame, the stick's census (`stick_added`), `bf_analyse`.
