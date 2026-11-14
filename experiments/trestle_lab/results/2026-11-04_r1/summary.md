# The trestle lab, round 1 (2026-11-04, #623)

Headless on this workspace's 4-core VM (2.1 GHz); "at Sean's" is x0.65 (CLAUDE.md's clock
scale). Measured CPU-side only. Every number is a proposed dial (`config/trestle.tres`).

## The viaduct

- **7,692 members**: 3,400 braces (sway and longitudinal), 2,088 posts, 840 girts, 500 ties, 370
  intermediate sills, 124 stringers, 122 guard timbers, 66 rails, 62 piers and abutments, 60 caps,
  60 mud sills. 60 bents, 430 stories; 300 m long, 66.1 m from the gorge floor to the rail at the
  tallest bent, on a 900 m curve.
- **Nodes:** 7,693 (each member its body alone at rest, the structure itself one); the whole lab line
  (13 track chunks, the viaduct, the gorge, the train) added 10,270 to the game's 17,767.
- **Build:** 1.7-2.5 s, once, when the lab builds it (the game's buildings build at load).
- **Under its own weight:** nothing overloaded; the hardest-worked member a lower post at 6 % of its
  buckling load.

## Idle cost (`cost/`, `trestle_cost 15`, headless)

| | ms a frame here |
|---|---|
| bare, before the lab was built | 10.83 |
| the viaduct standing, no train moving | 10.92 (12.47 on a second take) |
| the train crossing it at 30 km/h | 11.61 |
| the train crossing it at 40 km/h | 13.17 |
| bare again, after (the same game) | 12.15 |

All inside this VM's noise band (10.8-13.2 ms). The bridge's own loads while a train crosses a
sound deck: **0.02 ms a tick** and no analysis at all (nothing on a sound deck is worked out: the
full analysis with the engine anywhere on it leaves the hardest-worked member at 0.19 and the
bents' posts and sills at 0.09, `test_a_sound_deck_carries_the_train_anywhere`). Before that rule
the crossing cost 18 ms a tick (every bent under the train worked out again every 3 ticks), then
2.4 with the bents left out.

## What a cut does (`matrix.json`, `trestle_matrix`: posts cut outright, then the engine rolled over; measured before the fold and the smaller falling boxes below, so its "under the engine" column is that build's)

| Cut | Empty | Under the engine |
|---|---|---|
| A one bent, its bottom story's eight posts (142 members fall) | holds | fails (the stringers spanning it reach 0.86-0.90, then go) |
| B one bent, its top story | holds | fails |
| C two bents side by side | falls at once | - |
| **D the two inner posts of the bottom story (two members)** | **holds** | **fails: the engine's weight brings the bent down, then the deck** |
| E/F half the posts / the outer pair (the bent above falls) | holds | fails |
| G the top story's inner posts | holds | holds |
| H two bents' top stories | falls at once | - |

One bent lost doesn't drop the deck: the two-panel stringers either span it (twice as far) or
cantilever off the next bent, as continuous stringers do (period practice let a bent be taken out
for repair). One stick (0.2 kg) doesn't cut a 12 x 12 in post; a bundle of two does.

## The collapses (`runs/`, `runs/table.md`; `collapse_runs.py`, each in a fresh headless game)

19 runs; the train runs (anything "under") had the charges go off as the engine came on, 40 m
(60 m for three bents) short, at 40 km/h, nobody braking (the hold driver: it's the trap).

- **No frame over 100 ms at Sean's in any run** (worst 77 ms).
- **The slow spell fails #492's half-second gate in 12 of 19:** 0.55-1.1 s for most collapses with
  or without the train, 1.6-3.8 s with twelve men in the coach. It passes for one bent blown (with
  or without the train) and the light charge at 15 km/h. What it is: 8-24 bundles going off inside
  0.1-0.4 s (each charge's tick 25-30 ms: its splinters flown as balls, the breaking, the settle),
  then Jolt stepping the falling towers (400-odd members each, one body) and 100-250 awake rubble
  pieces (physics 25-85 ms a frame), and the men in the coach thrown. Tried and left: the braces'
  shapes off while a tower falls whole (no change).
- **The train goes over in 5 of 15 runs:** one bent blown under it 2 of 3 (15 of 20 bodies in the
  gorge each time), three bents with the coach full 2 of 3 (15 of 20), two bents 1 of 4 (one
  body), three bents alone 0 of 3. When it doesn't: the engine carried across a 14 m gap at 40 km/h
  onto the far side's stringers with the tender hung between it and the ore car on two coupler pins
  (two bents, r2); the engine sat on a two-bent tower (422 members) that never went over (three
  bents, r3). The light charge, 15 and 30 km/h: the bent comes down under the engine and the deck
  with it, but the engine wedges in the ~10 m hole (0 of 7, both).
- Found on the way, and fixed: falling deck pieces, framed face to face with what stood beside
  them, wedged at deck height and were held still (RubbleSleep), and the engine rested on them over
  a 19 m hole; they fall 2 cm smaller now. The couplers held the engine out over a hole like a beam
  (step 5's 15 degrees of pitch); off a bridge they swing free in pitch.

## Models, called out

- **The fold** (`fold`, `fold_after`): a bent's tower above a cut, left to the physics, drops a
  story onto its own stubs and stands there (a rigid body with a 20 m base), a 60 m stack with the
  deck on it. So 0.6 s after it starts to fall it's tipped over across the line, a seeded side,
  with 1.3 times the turn it needs to go past the edge of its foot, and breaks into sections where it
  lands. Along the line (the way a real bent would go, a frame on its edge once its girts tear) it
  leaned on the next bent, which stands (a falling tower pushing its neighbours over is for
  later), and held the deck up. A model of its joints giving unevenly.
- **Rails over a hole** (`rail_span`): a rail never snaps and isn't strength-checked, so with its
  ties gone it hung as a solid and the engine rode across it. Now a wheel on 1.8 m of rail with
  no tie under it tears it off its spikes.
- **The train's weight** goes onto the stringers at each axle (the rails and ties spread it over a
  tie or two in fact; they aren't checked themselves).
