# The farmhouse collapse after #626: Sean's F12s (2026-11-04, issue #642)

Branch `claude/gameplay-collapse-cost-2`. This VM: 4 cores at 2.1 GHz, headless, `--fixed-fps 60`
(one tick a frame). Main (8eaaab5) in a worktree, the same native build, run alternately.

## What Sean's F12s show (build 3194, the default look, F3 up; `tools/perf_report.py FILE --all`)

Four saves over one play: two sticks inside the house 2.3 s apart (game 102.6 and 104.9 s: 0.35 kg
at 91.34,1.81,-49.14 and 94.48,2.34,-48.47, Sean at ~83.5,2.05,-49.5), then a third (0.20 kg at
96.76,2.41,-49.88, game 129.7) into the wreck.

| stretch (wall s) | frame | ticks | physics | timed systems | GPU | render CPU |
|---|---|---|---|---|---|---|
| before (136-145) | ~15 | 0.9 | ~7 | ~4.5 | ~5 | ~2 |
| after the 2nd stick (115-135) | 50-67 | 2 | 38-52 | ~15 | 7-22 | ~3.5 |
| after the 3rd (147-171, still going) | 60-88 | 2 | 48-70 | ~16 | 5-24 | ~3 |

Physics is two ticks a frame and ~26 ms a tick, of which our timed systems are ~7.5 (people_body
2.3, structures 1.5, people prep 1.1, senses 0.8, ...); **the rest, ~18 ms a tick, is Jolt's step**
(Godot's physics time includes the server's step). The GPU (5-24 ms) runs beside the CPU and isn't
what holds the frame. So the biggest cost is Jolt's step, as in #626, but larger than the one-stick
lab said.

Also in them:
- **The ~500 ms untimed frames (#625's 455 ms kind) are the F12 saves themselves**: each comes the
  frame after a save's last recorded frame (131.16 -> 131.7, 139.31 -> 139.85, 154.42 -> 154.2;
  screenshot and zip). Not the game.
- RubbleRest's join at 11-15 ms on ~8 frames 2-4 s after the second stick (first save only).
- `outlaw_brain` at 10-19 ms a frame in bursts of ~0.3 s (every save; the gang in the wreck).

## The cause: the crater's pieces reporting for good

`bf_blast in=farm mission=1 world="91.34,1.81,-49.14;94.48,2.34,-48.47" gap=2.3
stand=83.5,2.05,-49.53` (Sean's two sticks; `world` takes several now, `collapse_runs.sh`'s
`WORLD`/`STAND`/`GAP`). Per second after the first stick (main): Jolt's step 23 ms at 3 s with 577
awake, then **~42 ms from 6 s to 20 s with ~340 awake, 151 of them reporting contacts the whole
time**, then 2.5 ms when the pile sleeps at 21 s. The 151 lay over the sticks' crater: #626 left a
piece over a dug tile reporting whatever its speed (`Ground.rescue` read its contacts), and a body
that reports loses Jolt's manifold reduction (Godot's JoltBody3D). With no reports at all, the same
run: step 10.0, frame 27.8 (from 40.6 / 56.7).

Probing instead (reports on for the two ticks before the rescue looks) can't work: changing the
count wakes the body (`_contact_reporting_changed` -> `wake_up`), and Jolt's `ActivateBodies`
resets the sleep timer of an awake body too (Godot 4.7.2, Jolt `BodyManager.cpp`), so a piece
probed every 15 ticks would never sleep.

**The change**: a piece reports by its speed only, over dug ground too; `Ground.rescue` finds a slow
(non-reporting) piece through the field by its points: one deeper than `CAUGHT_DEEP` (5 cm) under a
dug tile's surface (lying on it, the physics lets it sink 2 cm). Test
`test_a_quiet_piece_through_a_dug_tile_by_its_end_is_set_back_but_one_lying_there_isn_t`.

## The numbers (three pairs, alternately; 3-12 s after the first stick, median ms)

| run | frame (p90) | Jolt's step | our ticks (window) | late reporting | broken |
|---|---|---|---|---|---|
| main 1 | 57.2 (69.6) | 34.2 | 18.8 | 204 | 367 |
| main 2 | 38.9 (56.8) | 20.9 | 14.7 | 113 | 361 |
| main 3 | 38.4 (45.5) | 20.7 | 14.5 | 148 | 361 |
| branch 1 | 36.4 (45.1) | 13.9 | 19.1 | 9 | 362 |
| branch 2 | 28.7 (36.7) | 9.8 | 15.1 | 4 | 362 |
| branch 3 | 32.1 (42.5) | 11.9 | 15.9 | 4 | 364 |

Jolt's step 20.9 -> 11.9 (-43%), the frame 38.9 -> 32.1; broken within main's (361-367). Our ticks
are a little higher on the branch: in main 2 and 3 the player ended in town (killed and put back,
it seems), so the house's men ticked slowly. At Sean's (his ~18 ms of Jolt a tick, x0.57): ~10.5,
so ~18 ms a tick and still two ticks a frame: **~40-45 ms frames, not yet under 33**.

## RubbleRest's join off the main thread

A joining piece's triangles were placed (de-indexed, tangents made) in GDScript on the main thread
(`MemberMesh.placed` in `_part`); now `_part` keeps the arrays it was made of and where they go, and
the worker that joins the cell places them (`_group_and_concat`). With `holes=16 shots=8` (16
boards by the stick shot through 8 times each first): the join's main-thread time 170-181 ms a run
-> 109-120, its worst frame 2.3-3.6 -> 1.8-1.9, broken 361-362 both. Sean's 11-15 ms joins weren't
reproduced (no readbacks here either: every joining mesh had its arrays kept).

## What's left (at Sean's, a tick)

Jolt's step ~10 with ~300-450 pieces moving for 10-20 s; our ticks ~7.5 (people in the wreck, the
gang's bursts). Next: fewer pieces awake (RubbleSleep sooner on a settling pile, how many pieces a
cut makes) and the people's share during a collapse.
