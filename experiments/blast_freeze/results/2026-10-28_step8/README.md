# More cores, step 8: the fire's tick native, the analysis on a worker (2026-10-28)

`docs/briefs/more-cores.md` "Step 8" (issue #400, brought forward by Sean's 3 fps in a burning
saloon, build 2585). This workspace's VM (4 vCPUs, ~2.1 GHz; x0.65 for Sean's core), headless,
`--fixed-fps 60`, one game at a time, nothing else running. **before** is main at 635efcf in its
own worktree with only the new timers (`fire_begin`, `fire_visit`, `fire_finish`) and the bench's
fix below; **after** is the branch's head.

## What changed

1. **The fire's member tick native** (`FireCore`, `addons/saltcreek_native/src/fire.rs`; the same
   rules in GDScript as `FireCoreScript`, `src/fire/fire_core.gd`, for the web and
   `-- --fire-core=script`). Every member the fire meets has a slot: its temperature, water, char
   and burn time live there (StructureMember's properties read and write them through), with its
   size, flags, box, what it heats and how hard. `FireSystem._visit` maps a slice of `active` to
   slots and the core runs the rules; what the scene must do (burn away, catch, crack, done with,
   newly hot) comes back as events, done on the main thread in order. The core keeps its own grid
   of the members' boxes (2 m cells, placed in FireSystem's order by the same f32 sums), and a
   burning member's list of what it heats is made in the visit when it's due, as the old `_visit`
   did. `tests/test_fire_core.gd`: the two cores fed the same 600 ticks of a jumble of 300 members
   (banded, wet, glass, freed, moved) give the same events and numbers to the bit, and a wall
   burnt through FireSystem ends the same on either.
2. **`fire_near` asks the core** (`burning_near`: each burning member's box, one native pass).
   Rubble's box is where it lay at the grid's last rebuild (≤ 2 s), as the grid's own already was.
3. **The smoke fields' sources natively** (`SmokeGrid.emit_burning`): a field gives the grid its
   drawn members' slots once a drawing and the grid reads the core's burning flags each step (six
   fields over the burning saloon each looped its buildings' burning members in GDScript, 15 times
   a second, and called the grid once a vent: the ~6 ms of the blaze's `fire` no timer showed).
4. **The analysis on a worker.** `StructuralAnalysis.advance` reads `LoadRecord`s, not members:
   what it read (weight, the compression and bending capacities, the weakest point, supports,
   geometry), worked out on the main thread by the members' own methods, so the numbers are the
   same to the bit. A structure keeps one a member, taken again when it's marked dirty or for an
   analysis from the top. FireSystem's checks: begun on the main thread, the records copied a slice
   a frame, the rest worked out on the pool (high priority, #392), applied on a tick fixed by its
   size (1 + members / 200), so the same with and without the worker (`--analysis-worker=off`).
   Anything that touches the analysis waits for the job first; another analysis begun meanwhile
   (`Structure.analysis_epoch`) or a `queue_settle` throws the worker's results away (#454's rule).
   #454's gap in the tick closed: a board burnt away from the building being checked queues it
   again.
5. **`tools/perf_bench.gd`'s `systems_ms` is the whole run's mean.** It was the last second's
   (Prof rolled every wall-clock second while it measured), which is why the issue's sub-timers
   didn't add up. The frame times were always the whole run's.

## The blaze (`perf_bench --scene=blaze --seconds=60 --spikes=40 --no-ablate`; `blaze.json`)

The fire left 45 s, then 60 s measured (~2,500 burning). ms a frame, this core:

| | main | native tick + fire_near (b1) | + worker + smoke (b4) | **all (b5)** |
|---|---|---|---|---|
| frame avg / p99 / max | 56.6 / 127 / 223 | 43.0 / 94 / 128 | 36.3 / 81 / 239 | **29.8 / 67 / 155** |
| `fire` (its tick, loads, effects, the smoke fields) | 23.9 | 15.5 | 6.9 | **4.5** |
| `fire_tick` (`fire_visit`) | 12.9 (12.1) | 3.2 (2.7) | 3.2 (2.7) | **1.1 (0.6)** |
| `fire_loads` (`fire_analyse`) | 3.8 (3.3) | 4.5 (4.0) | 1.1 (0.6) | **1.1 (0.6)** |
| `fire_wait` (the main thread waiting on the worker) | – | – | 0.04 | 0.07 |
| `smoke_emit` (untimed before) | ~6 | ~6 | 0.5 | **0.5** |
| `fire_near` + `civ_fire_look` | 5.3 + 2.5 | 0.07 + 0.24 | 0.07 + 0.87 | **0.08 + 0.32** |
| budget line `fire_effects` at Sean's | 15.6 | 10.1 | 4.5 | **3.0** |

The issue's targets: `fire_tick` under 3 ms with ~3,000 burning: **1.1**; `fire_near` under
0.5: **0.08**. The brief's ~1.0 for the fire at Sean's isn't met in the blaze (~2.9 there): what's
left is FireFX (`fire_fx` 1.1, the 40 flames' looks), the smoke raster (0.7) and the load checks'
main-thread share (1.1: beginning each analysis, the records, the rounds). The frame's "people"
(~10 at Sean's) is the next biggest thing in a burning town and isn't this step's.

## The blast-freeze lab (`bf_blast at=6.0,0.8,6.0 fire=6 burn=20 fuse=1 seconds=8 player=12.0,0.8,2.0`)

The spec saloon, six boards lit and left 20 s, a stick in the hall, the player 7 m off. ms a frame:

| | before the stick (1 s): mean / p95 / worst | the stick and after (8 s): mean / p95 / worst, > 50 ms | after its first second: mean / p95 / worst, > 20, > 50 | `fire_loads` after its first second (ms a frame) |
|---|---|---|---|---|
| main | 14.9 / 21.2 / 88 | 45.4 / 70.3 / 432, 154 | 42.3 / 66.9 / 113, 353, 121 | 9.9 |
| main (2nd) | 15.1 / 22.9 / 51 | 44.1 / 67.7 / 498, 147 | 41.4 / 64.8 / 96, 343, 122 | 9.8 |
| **after** | 14.0 / 23.1 / 65 | **29.3 / 56.2 / 444, 39** | **25.7 / 53.6 / 90, 211, 24** | **1.5** |
| after (2nd) | 13.0 / 19.3 / 70 | 30.5 / 57.3 / 436, 52 | 27.3 / 54.4 / 83, 236, 35 | 1.5 |

(`summaries.txt`; trimmed runs `before_hall_1.json`, `after_hall_1.json`, `after_hall_det_1.json`.)

**The same** (`same.txt`): every run breaks the same 306 members (`broken_ids_hash` 1650757771,
main's), cuts 22 boards, leaves 256 pieces. Under `--deterministic`, twice: **600 of 600 frames the
same**; with the worker and without (`--analysis-worker=off`): **600 of 600**. Against main the
fire is the same frame for frame until 16 frames after the stick; then the hot count parts by a
few (170 against 173: rubble heats from where it lay at the last rebuild), to the same end. The
two wall-clock runs differ in 8 frames by a member's timing, as main's two always have.

## The gunfight lab (10 D fights in the spec hall, `--jobs=1`; `gunfight_same_*.txt`, `gunfight_perf.txt`)

The branch twice (`s8_a`, `s8_b`): **10 of 10 the same**. Main at 635efcf in its worktree against
each: **10 of 10** and **10 of 10**; step 7's `main3` against `s8_a`: **10 of 10**. A saloon fight
has no fire unless a lamp breaks, so its frame is as it was: 24.0 / p95 29.5 ms (main) against
22.9 / 27.6 and 23.5 / 28.5; `fire` 0.14 → 0.09.

## The whole saloon burning (`burn.sh`, the Fable session's `run_burn_headless.sh`; `burn_*.txt`)

The spec saloon (`gf_ways`), six timbers lit, read every 15 s of game time (headless; `frame_ms`
is the bridge's frame, one game at a time):

| s after lighting | 61 | 91 | 121 | 151 | 181 |
|---|---|---|---|---|---|
| burning, main / after | 32 / 32 | 319 / 322 | 1,179 / 1,187 | 2,027 / 2,030 | 2,951 / 2,961 |
| frame ms, main | 26.3 | 29.4 | 62.5 | 76.9 | **100.0** |
| frame ms, after | 18.9 | 20.4 | 30.3 | 22.2 | **28.6** |

The fire spreads as it did (the counts a few apart from 90 s: rubble's boxes); three townsfolk are
dead by 165 s on both.

## The suite, the soak

(filled in below as they finish)
