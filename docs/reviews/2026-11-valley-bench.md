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
