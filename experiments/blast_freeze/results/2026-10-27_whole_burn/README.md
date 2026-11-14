# The whole building burning (2026-10-27, the Fable session)

Sean's F3 on build 2585 in a saloon burning whole after a fight: 3 fps, frame 333 ms (process 33, physics 178, render cpu 18, gpu 45), draws 18,418, tris 11.3 M, nodes 32,535, bodies awake 0.
Reproduced here headless (this VM, `--fixed-fps 60`): the spec saloon built by `gf_ways`, the player in its hall, six timbers lit by `ignite`, read every 15 s of game time (`run_burn_headless.sh`, `burn_readings.txt`).

| game s | avg frame ms | last tick's physics ms | nodes | burning |
|---|---|---|---|---|
| 0 | 9.3 | 16.49 | 22983 | 0 |
| 15 | 11.5 | 21.78 | 23018 | 6 |
| 30 | 15.2 | 29.79 | 23079 | 6 |
| 46 | 13.5 | 116.02 | 23181 | 15 |
| 61 | 14.9 | 130.1 | 23309 | 32 |
| 76 | 19.2 | 115.37 | 23902 | 108 |
| 91 | 22.7 | 39.08 | 24785 | 313 |
| 106 | 34.5 | 56.07 | 26263 | 687 |
| 121 | 43.5 | 106.47 | 27629 | 1179 |
| 136 | 43.5 | 71.31 | 28791 | 1626 |
| 151 | 43.5 | 107.32 | 30089 | 2023 |
| 166 | 55.6 | 73.84 | 30858 | 2450 |
| 181 | 50.0 | 86.14 | 32932 | 2944 |

The average frame is headless (no draw at all): the simulation alone. Single ticks of 70-130 ms from 45 s on. Three townsfolk dead by 165 s (people 21 -> 18).

`perf_bench --scene=blaze --seconds=60 --spikes=40 --no-ablate` (the fire left 45 s, 60 s measured; `bench_blaze_summary.txt`, the first 60 spike frames in `bench_blaze_spikes_first60.txt`): avg 47.8 ms (21 fps), p99 107, max 182; 2,396 of 3,600 frames over 40 ms; `fire_tick` 18.9 ms mean in them, 73 max; census FireFX 2,503, particles 333, meshes_visible 5,169, collision_shapes 4,382, StructureMember 8,023. The budget line (at Sean's clock): people 7.80/4.0, physics 17.56/2.0, fire_effects 15.74/2.0, else 23.50/1.0, total 31.07/14.0.

Issues: #400 (step 8 brought forward: the fire's tick native, `fire_near` at scale, the analysis on a worker), the burning building drawn in its batch, the catch-up cap with a quit that can't hang, #433 (the performance report).
