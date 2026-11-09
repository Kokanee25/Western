# The trestle lab on the valley's canyon (valley G3, 2026-11-08, #716)

The same `Trestle` and timbers as round 2 (`2026-11-04_r2_kwai/`), now the valley's main line's
crossing `great_trestle` (config/valley.json, 1229-1359 m along the route, a 900 m right-hand bend),
its bents footed on the **bake's canyon** (`ValleyTerrain`, valley_plan.py's terrain), not a gorge
cut to fit. Each run a fresh headless game in the valley world
(`collapse_runs.py --world=valley`; the lab's `ensure_built` takes the valley's line and train).
Headless on this workspace's 4-core VM; "at Sean's" is x0.65.

## The trestle

- **1,542 members** (the gorge's 1,467): 600 braces, 308 posts, 217 ties, 146 girts, 56 stringers,
  54 guards, 51 intermediate sills, 30 rails, 28 piers and abutments, 26 caps, 26 mud sills. 26
  bents, 77 stories; 130 m long, the tallest 26.6 m from the creek's floor to the rail (the plan's
  27.2 is rail to the creek's bed; the bent stands a little off the bed's lowest line).
- The canyon is not the gorge: its floor is narrower and its walls not alike, so more of the bents
  are tall (more stories: 77 to 72).
- Every bent's ground is the bake's to the centimetre (`test_the_great_trestle_stands_in_the_canyon`).

## The collapses (`runs/table.md`, 24 runs, each a fresh headless game)

- **The worst frame at Sean's: 104 ms** (one run of 24, `two_under_40_coach`; the next worst 86).
  Round 2 on the gorge: none over 100 (worst 82), on a VM that ran the bare game at 16-19 ms a
  frame; the valley's game here is ~2-3 ms a frame (no town), so the charges' own frames are most
  of what's measured.
- **The slow spell passes #492's half second in 15 of 24** (round 2: 2 of 19): every one-bent run,
  the bundles and the light charge pass; two and three bents with the train mostly fail, at 0.5-0.9 s (the
  falling bents and the cars in Jolt), as before.
- **What falls is the gorge's:** one bent blown holds empty (62 broken, the deck intact); the light
  charge holds empty and the engine finishes it; two bents side by side fall; the train goes over
  with three bents blown 60 m short at 40 km/h (cars in the canyon in 5 of 6 runs, 1-15 bodies),
  two bents 40 m short 3 of 4, one bent 0 of 3 (the engine bridges or wedges in the hole).
- The fall's own worst frames (the train going over): 19-39 ms at Sean's, all pass.

## Films

`experiments/valley/films/` (`trestle_crossing.txt`, `trestle_over.txt`): from the trestle
overlook (vp_trestle_overlook, 267 m, the finale's vantage point). Drawn under lavapipe; the films
themselves are too big for the repo (round 2's were committed small; see the valley README).
