# The trestle lab, round 2: the Bridge on the River Kwai's size (2026-11-04, #623)

Sean, on round 1's 66 m, 300 m viaduct: "toooo big", no town that size would build it. He wants
the Bridge on the River Kwai's bridge: high enough that the train really falls, and not looking like
it cost $10 million. The film's bridge (Kitulgala, 1957) was 425 ft long and ~90 ft over the water.

The same `Trestle` and the same timbers, from a new crossing on the route (`routes/gorge.json`:
560-690 m) and a new gorge (a river valley 26 m deep, a river on its floor). Headless on this
workspace's 4-core VM; "at Sean's" is x0.65. **This round's VM was slower than round 1's** (bare
16-19 ms a frame here, against 11-13), so its frames sit nearer the gate's line.

## The trestle

- **1,467 members** (round 1: 7,692): 560 braces, 288 posts, 217 ties, 136 girts, 56 stringers,
  54 guard timbers, 46 intermediate sills, 30 rails, 28 piers and abutments, 26 caps, 26 mud sills.
  26 four-post bents, 72 stories; 130 m long, 26.1 m from the floor to the rail at the tallest.
- **Nodes:** 1,468. **Build:** 1.0 s, once.
- **Under its own weight:** the hardest-worked member at 2 % (a lower post, buckling). **Under the
  engine anywhere on a sound deck** (the full analysis): 0.18 (a stringer); the bents 0.06.

## Idle cost (`cost/`, headless, 15 s each)

| | ms a frame here |
|---|---|
| bare, before | 15.98 |
| the trestle standing | 15.46 |
| the train crossing at 30 km/h | 15.99 |
| at 40 km/h | 17.96 |
| bare, after (the same game) | 19.26 |

Inside this round's noise. The bridge's loads during a crossing: 0.05 ms a tick, no analysis.

## The cut matrix (`matrix.json`: posts cut outright, then the engine rolled over)

The same as round 1's: one bent cut holds empty and the engine finishes it; **the light charge
(the two inner bottom posts) holds empty and the engine finishes it**; two bents side by side fall
at once; the top story's inner posts hold even under the engine.

## The collapses (`runs/table.md`, 19 runs, each in a fresh headless game)

- **No frame over 100 ms at Sean's** (worst 82).
- **The slow spell fails #492's half second in 17 of 19** (0.5-2.4 s; 2.2-5 s with twelve men in
  the coach). Its causes are round 1's: the 8-24 bundles going off inside 0.1-0.4 s, Jolt stepping
  the falling bents and rubble, the men thrown. Smaller bents didn't shorten it (each bundle's tick,
  its splinters flown as balls, is the same size), and the slower VM lengthens it here.
- **The train goes over:** three bents blown as the engine comes on (60 m short, 40 km/h): cars in
  the river in 3 of 3 (9 of 16, 3 of 14, 5 of 20 bodies); with the coach full 1 of 3. Two bents: 2
  of 4 (4 of 9, 15 of 20). One bent: 0 of 3 (at 27 m the engine bridges the hole or wedges in it).
- The light charge, 15 and 30 km/h: the bent comes down under the engine and the deck with it; the
  engine wedges in the hole (0 of 7, both).

## Sheet and films

`sheet/trestle_sheet.jpg` (golden hour and night; from the floor by the river, the far rim, the
deck). `films/` (the cameras closer than round 1's: the rim 90 m along the gorge, the floor 35 m):

- `crossing.mp4`: the train across whole at 40 km/h; nothing breaks.
- `bent_blown.mp4`: one bent blown with no train; the deck holds empty over the hole.
- `light_then_engine.mp4`: the light charge holds empty, the engine brings the bent down and
  wedges in the hole (as its runs do).
- `over_floor.mp4`: three bents blown as the engine comes on: **the train goes over** (6 bodies in
  the river), from the floor downstream.
- `over_rim.mp4`, `over_platform.mp4`: the same set-up, one run each; in these two it stops on
  what's left (the going-over is chaotic run to run, see the table).
