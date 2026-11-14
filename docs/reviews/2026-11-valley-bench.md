# The valley on the frame bench (#865, the codebase review's R4), 2026-11-13

How much the valley costs a frame with 5, 10, 15 and 25 more townsfolk, where the people's time
goes, what the load spends, how many collision bodies the town holds, and what to cut, in order.
Measured on this workspace's 2.1 GHz core and scaled to Sean's by FrameBudget's `clock_scale`
(× 0.65), as CLAUDE.md's budget table is. Headless, one game at a time, 10 s a scene; the render
CPU comes from one drawn lavapipe run a scene with 15 townsfolk. The bench repeats it:

    python3 tools/valley/bench_runs.py --bands --ablate=15 --render --out=build/valley_bench
    godot --headless --fixed-fps 60 -s res://tools/perf_bench.gd -- --world=valley --scene=day --townsfolk=15 [--band=near|far] [--bodies] [--extra-bodies=N]

The townsfolk (`tools/valley/valley_townsfolk.gd`) are Studio men with a civilian's mind, half on
the walks near you and half 70 m and more down the street, like the town the townsfolk brief plans
(12 near, 12 far). Scenes: **day** (14:00 on Main Street by the saloon), **night** (21:00 in the
saloon's yard, the gang and the card game in), **gunfight** (two crews of three of the gang's
outlaws shooting it out on the street), **blast** (a stick each at the saloon's and the doctor's
fronts, measured 3 s after), **load** (the valley from nothing).

## The frame (Sean's ms; budget in brackets)

| Scene | Townsfolk | Men | People (4.0) | Physics (2.0) | Structures (1.0) | Else (1.0) | Total (14) |
|---|---|---|---|---|---|---|---|
| day | 0 / 5 / 10 / 15 / 25 | 4 → 29 | 1.00 / 1.78 / 2.57 / 3.32 / **5.12** | ≤ 1.1 | 0.14 | **1.3–2.3** | 3.1 / 4.1 / 5.1 / 6.0 / 8.3 |
| night | 0 / 5 / 10 / 15 / 25 | 6 → 31 | 1.54 / 2.40 / 2.72 / 3.50 / **4.89** | ≤ 0.7 | 0.14 | **1.9–2.6** | 3.9 / 5.1 / 5.4 / 6.4 / 8.2 |
| gunfight | 0 / 5 / 10 / 15 / 25 | 10 → 35 | 3.48 / **4.35 / 5.45 / 6.73 / 8.29** | ~0 (noise) | 0.30 | **3.7–4.6** | 7.4 / 8.4 / 10.0 / 11.5 / 13.2 |
| blast | 0 / 5 / 10 / 15 / 25 | 4 → 29 | 0.96 / 1.68 / 2.51 / 3.31 / **6.00** | ≤ 0.8 | 0.25 | **1.6–2.9** | 3.2 / 4.2 / 5.3 / 6.3 / 9.9 |

Render CPU (lavapipe, 15 townsfolk): day **2.60** (3,335 draws), night **1.91** (2,109), blast
**2.65** (3,300), all under 4.0. The gunfight read **15.1** (4,561 draws), but that run drew only
four frames at 0.3 fps, straight after the first shots (new smoke and impact materials): not to
be trusted until it is drawn for longer.

Every scene's **else** is over its 1.0: the train's own timers (train, train_view, train_sound,
train_lookout: ~0.45 by day with the train miles off), RoomLight 0.17, the senses' lines 0.15, the
valley ground, and the engine's untimed share. In the gunfight, a hitch of 700–800 ms (raw) on the
first shots adds ~0.8 to the average on its own.

The blast barely moves the frame: two 0.2 sticks at the fronts broke little, and nothing was left
falling 3 s after (structures 0.25, physics bodies awake ~0).

## Where the people's time goes

Per system at Sean's, day, 0 → 15 → 25 townsfolk: people_body 0.27 → 1.23 → 1.88; skeleton
0.14 → 0.69 → 1.10; prep 0.23 → 0.50 → 0.68; **senses 0.04 → 0.44 → 0.90** (it grows faster than the
men: all pairs); civilian brain 0.02 → 0.18; the player 0.26 flat; bands 0.04 → 0.11; faces ≤ 0.02.
In the gunfight, the six outlaws' brains are ~1.0 flat (0.17 a man) and senses reach 1.59 at 25.

**Per man, by band** (the day, 10 townsfolk all near and then all far, against none):

| | People (Sean's ms) | Per man | The brief planned |
|---|---|---|---|
| none | 1.00 | | |
| 10 near (≤ 25 m) | 3.27 | **0.23** | 0.21 (target 0.15) |
| 10 far (≥ 60 m) | 2.11 | **0.11** | 0.07 |

A far man costs half a near man, not the quarter his every-4th-tick band should give. Body
0.74 vs 1.17 and skeleton 0.41 vs 0.65: the skeleton is posed every frame whatever the band, and
the body's per-frame share (prep, pose, pieces) isn't banded.

Switched off in turn (day, 15 townsfolk; ±0.3 noise): HumanBody's physiology and pose saves 2.50,
ValleyFolk 0.71, the player 0.65, senses 0.52, RoomLight 0.35, DayCycle 0.29, the 41 oil lamps 0.24,
FaceLife 0.22, ballistics 0.21. At night: HumanBody 3.29, senses 1.02, RoomLight 0.40, ValleyFolk 0.34.

## The people the slice can afford

At today's cost the people part takes **~0.165 more ms a townsman** (half near, half far), so the
4.0 holds **about 18 townsfolk** on the day street (1.00 + 18 × 0.165 = 4.0) and **about 18 at night**
(1.54 + 18 × 0.134). A gunfight is over with **3**. With the first three cuts below (far men at a
quarter of a near man, near men at 0.15, senses that don't grow with the square) a townsman costs
~0.10, and the street holds **~28**, the gunfight **~5 more** besides its own men: the brief's 24
fits with ~0.4 to spare by day. Until those cuts land, build the townsfolk at **18**.

## The load (here; Sean's ≈ × 0.65)

The valley takes **~28 s** here (~18 s at Sean's): the scene 15.8 s, of which the **buildings 8.5**
(the saloon's B build and the doctor's spec), railway 1.7, markers 1.5, ground 1.3, farmhouse 0.8,
the folk's places 0.3; terrain bake 0.4; then the **first frames 12.2 s, almost all the folk's men
being built (11.2 s)**. Drawn, the first frames take 80 s under lavapipe (shader compiles).

## Collision bodies

27,705 of Jolt's 32,768 after the load; all but 132 are static members.

| Owner | Bodies |
|---|---|
| Railway (mostly the great trestle) | 10,211 |
| The saloon (+ its kit props) | 7,634 + 572 |
| The doctor's | 3,701 |
| Markers/Town (the stand-in fronts) | 2,551 |
| Farmhouse (+ kit) | 1,402 + 204 |
| Ground | 1,016 |
| Saloon's side walk, folk kit, bridges, people | 113, 108, 112, 73 |

The rest of the slice's buildings (the jail, the store, the livery, …) built as the saloon and the
doctor's are, and furnished, add ~4–8k each: the full town is **~45–55k**, over the limit.

**What raising the limit costs** (the day, one run at a time, `override.cfg` only for the run):

| max_bodies | Extra bodies | Peak RSS | Frame (here) |
|---|---|---|---|
| 32,768 | 0 | 2,462 / 2,465 MB | 4.82 / 5.12 ms |
| 65,536 | 0 | 2,466 / 2,469 MB | 5.01 / 4.61 ms |
| 131,072 | 0 | 2,475 MB | 4.95 ms |
| 65,536 | 20,000 static boxes at rest | 2,611 MB | 4.95 ms |

The limit itself costs ~4 MB per 32k; 20,000 more resting bodies cost **~145 MB (~7 KB each, the
node and its shape mostly) and no step time** we can measure (the frames are within the runs'
noise; static bodies don't step, only the broadphase holds them).

**Recommendation:** raise `max_bodies` to **65,536** now (a line in `project.godot`; ~4 MB); it holds
the full town with ~10k to spare. Putting members at rest doesn't save bodies (they are static
already); what saves them is **merging** a building's or the trestle's members into one compound
body each until something breaks them (`PropBatch` does it for props). That is for memory (~70 MB
for the trestle) and load time, not the frame: do it later, the trestle first, if memory or the load
needs it.

## The cuts, ranked (expected gain at Sean's, the street with 15–25 townsfolk)

1. **Band the far men's body and skeleton** (pose and per-frame prep only on their tick, the skeleton
   not written every frame past 25 m): far 0.11 → ~0.05 a man, **~0.5–0.7 ms** with 9–12 far.
2. **Senses without all pairs** (`senses.gd` ~231–280, 355: who can see whom by band or a grid, far
   men sense on their tick): 0.90 → ~0.4 at 25 by day, 1.59 → ~0.7 in the gunfight: **~0.5–0.9**.
3. **Near men to 0.15**: the body's per-tick allocations (`_track_carry`'s new dictionary,
   `human_body.gd` ~1672; `_tickers.duplicate()` ~1534) and the prep: **~0.6–1.0** with 12 near.
   Targeted edits, no rewrite (Sean, #855).
4. **The gunfight's first-shot hitch** (700–800 ms: smoke and impact materials made on first use,
   OutlawBrain's `load()` a shot): preload them; **~0.8 of the average**, and the hitch is the
   worst frame in the game. Then draw the gunfight for longer to get its true render CPU.
5. **The train when far off** (view, sound and lookout at a lower rate past a few hundred metres):
   **~0.3** of the else.
6. **RoomLight and the oil lamps write only on change** (review B4): **~0.3–0.5**.
7. **ValleyFolk's step** (0.3–0.7 switched off): the clock read at its half-second only: **~0.3**.
8. **max_bodies to 65,536** (above): no frame gain; needed before the next building.
9. **The load:** build the folk's men over several frames or from a pool (11 s of a 28 s load), then
   the buildings' 8.5 s: **~40% of the load**.

Cuts 1–3 make the brief's 24 townsfolk fit; 4–7 bring the else back toward its 1.0.

## After the cuts (#881), 2026-11-13

The same bench (`bench_runs.py --scenes=day,gunfight --counts=0,25 --bands --seconds=10`) before and
after, in another workspace, one game at a time. **This workspace's core ran slower than #865's**:
main's day with 25 townsfolk read people **7.08** here where #865 read 5.12 (day with none: 1.25 for
1.00). So each cut is measured against this workspace's own baseline, and the totals are given here
and scaled to #865's (× 5.12 / 7.08). The runs' noise is about ±0.35 at Sean's (three runs of the same
people code read 5.20, 4.53, 4.94).

| Scene (Sean's ms) | People before → after | Else before → after | Total before → after | Worst frame |
|---|---|---|---|---|
| day, 0 | 1.25 → 1.12 | 2.02 → 1.67 | 3.66 → 3.46 | |
| **day, 25** | **7.08 → 4.9** (≈ **3.5** on #865's scale) | 3.37 → 3.2 | 11.69 → 9.0 | |
| gunfight, 0 | 4.41 → 3.91 | 4.21 → 3.29 | 9.42 → 7.46 | 593 → 78 ms |
| gunfight, 25 | 11.09 → 10.20 | 5.70 → 5.55 | 18.29 → 16.16 | 684 → 97 ms |

**A townsman** (day, 10 all near or all far, against none): near **0.235 → 0.21**, far **0.137 →
0.065** (a far man now ~0.3 of a near one). Senses at 25 by day 1.11 → 0.69; the skeleton 1.65 → 0.75.
On #865's scale the people part with 25 is ~3.5: **the 4.0 holds the brief's 24 by day, with ~0.5 to
spare** (~28-30 at most). The gunfight stays over: its men fight at full rate (by design) and the
outlaws' brains are ~1.1 flat.

What each cut did (each benched on its own, in this order):

1. **Far men** (`PeopleTick`): the far men down the street were in view, so they ticked every 2nd tick
   (`seen_nearer`), and those in the 8-degree aim cone every tick, at any distance. A far man in view
   now keeps the far band (`seen_nearer_far`, off: past 60 m a far tick's step is under a pixel), and
   the cone counts only while you aim down the sights (`aim_needs_sights`). Day 25: 7.08 → 6.46. The
   review's guess (body and skeleton paid every frame whatever the band) was wrong: the bands were.
3. **Near men** (`HumanBody`, targeted): the skinned finger bones (30 a man) were read and compared every
   tick; now only after `curl_hand`, a finger off, or hands up/down. `_track_carry`'s two dictionaries
   swapped, not a new one a tick; the tickers' copy made only when one comes or goes. Day 25: 6.46 →
   5.14 (skeleton 1.46 → 0.74).
2. **Senses** (`Senses`, `PeopleTick`): a calm man (can slow, not woken, not within 25 m of trouble:
   `HumanBody.tick_calm`) looks at another calm man every 2nd look (`calm_look_every`), the time between
   owed to the pair, so awareness builds as fast; the player and anyone in or near trouble every look.
   Day 25: senses 0.92 → 0.72 (10 near: 0.56 → 0.38). Cutting allocations in `_look` (the points, the
   exclusions, the light once a look) measured nothing and was dropped: the time is in the lines (~1/3)
   and the per-pair maths, not allocations.
4. **The gunfight's hitch** was not the smoke's materials (headless draws nothing): it was
   `settle_analyse`, the saloon's first analysis (7,600 members) whole on one frame when a ball broke a
   member; **the valley has no FireSystem** to slice settles. Each spec building's first analysis is now
   begun after the load and run on a worker (`Structure.warm_analysis`), so the first settle is an
   update (47 ms). Worst frame 896 → 129 ms here; the gunfight's frame 9.65 → 7.84. OutlawBrain loads
   the revolver's tuning once (not a `load()` a shot). **Left:** the outlaws' first cover moves, ~120 ms
   (here) twice at a fight's start, ~21,000 walk casts in that frame (not found yet).
5. **The train when distant** (past 400 m): lookout and bridge loads every 10th tick, cars drawn every
   2nd frame; rails, solids and sound every tick. **The bench doesn't show it:** the day's train is
   ~150 m off and coming up the street (moving at 4 m/s), not "miles off"; there its ~0.4 at Sean's is
   real (sim 0.08, view 0.13, sound 0.13, lookout 0.05).
6. **RealLook's hung lamps** write their range only on change (review B4; art's file, two lines). It runs
   only under the real look, so the headless bench can't show it. RoomLight was profiled (~0.2 at Sean's
   by day, spread over its rooms' sun patches, list and fill, nothing written unchanged) and left.
7. **`max_bodies` 65,536** (`project.godot`): 27,705 in use after the load.

**The else is still over (1.7 with none, ~3.2 with 25).** By day: the train ~0.4 (near, moving), RoomLight
~0.2, the valley ground ~0.1, the day cycle ~0.07, and **~1 ms the timers don't cover** (the engine's
own share: moved bodies synced to physics, the scene tree's process, notifications). Next: find the
untimed share (a native profile, e.g. `perf` on a headless run), then the outlaws' first-move hitch.

**The drawn gunfight wasn't measured:** this workspace had no Vulkan driver (lavapipe installed by hand),
and under it the gunfight's 180 setup frames ran at ~0.1 fps (over 35 min before the measure began), so
the run was stopped. Its render CPU is still to take, on a workspace with the Studio's setup or on Sean's F3.
