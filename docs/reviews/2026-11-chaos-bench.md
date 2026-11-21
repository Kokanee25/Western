# The slowdown after dynamite and fire (#1117, 2026-11-20)

The chaos playtest (`docs/playtests/2026-11-20-chaos.md`, finding 2) saw 2 fps for ~25 s, the
bridge's `read frame` saying physics 537 ms (budget 2), 762 members broken, 78 burning, 25,143
nodes, and E taps lost. That game was the **old town** (the bridge's default, `--world=town`; the
valley has no FireSystem), headless, real time, on this sandbox's 2.1 GHz core.

## The bench

`tools/perf_bench.gd -- --scene=chaos` (town; `--world=valley` for the valley's saloon B and store):
the gang turned on you (the valley: two crews shooting it out), a bundle of three sticks in the
saloon, the store set alight 15 s on, then a line a second for `--chaos-seconds` (200): the second's
mean and worst frame, physics ms and ticks a frame, members broken and burning, the loose bodies and
how many are awake, and the systems' share; `--spikes=MS` prints each frame over MS with its systems.
`--by-ticks --catch-up=40` runs it in real time with the bridge's catch-up limit (no `--fixed-fps`);
`--catch-up-guard` adds `CatchUp` (below).

```sh
godot --headless --fixed-fps 60 -s res://tools/perf_bench.gd -- --scene=chaos [--chaos-seconds=200]
godot --headless -s res://tools/perf_bench.gd -- --scene=chaos --by-ticks --catch-up=40 [--catch-up-guard]
```

## What costs (one tick a frame, `--fixed-fps 60`; ms on this core, x0.65 for Sean's)

| s after the blast | tick ms | awake loose bodies (of ~1,890) | timed systems |
|---|---|---|---|
| 1 | 38 | 1,745 | ~16 |
| 2 | 32 | 1,103 | ~9 |
| 3 | 27 | 862 | ~8 |
| 4 | 19 | 103 | ~7 |
| 6 on | 10-11 | 0-20 | ~8 |

1. **Jolt stepping the blast's pieces** (untimed): ~630 members broken into ~1,890 loose bodies;
   the tick's untimed part follows the awake count, ~15 µs a piece a tick, ~27 ms over the steady
   tick at the start, gone in ~4 s as they sleep. The earlier study (#626,
   `experiments/blast_freeze/results/2026-11-04_collapse_cost/`) already cut contact reports and
   kept the 20/8 solver steps for the ragdolls. **Tried here, not kept:** Jolt's sleep thresholds
   (velocity 0.1 m/s, time 0.3 s, `override.cfg`): awake 309 at 3 s against 862, ~1 s sooner
   asleep, the 3 s tick 21 against 27 ms; it's global (the men's ragdolls settle by it too), so it
   needs the falls lab (`experiments/physics_lab/run.py`) before it could go in.
2. **The people** (people_body, prep, senses, skeleton, brains): ~6-7 ms a tick steady here (~4.3 on
   Sean's, at its 4 ms budget); after the blast they react, ~16 ms timed in the first second.
3. **The blast's own frame**: 120-190 ms once (dynamite 125 ms, 760 members in the blast). In the
   valley the same three sticks in saloon B break ~1,800 members and its first frame is 700 ms
   (`settle_analyse` 540); the valley's gunfight also has `outlaw_brain` frames of 100-200 ms every
   few seconds (not this issue; noted in the lane file).

The fire to 200 s (579 members burning, none fallen yet) never put a tick over ~14 ms here.

## Why 537 ms: the catch-up spiral

The game allows 2 physics ticks a frame (project.godot, #435). The bridge raises it to 40 (so a
drawn run at a frame a second keeps game time). Once a tick costs its own 1/60 s (16.7 ms) a frame
can never catch up: each runs 40 ticks, takes longer, and owes more. Real time, the bridge's 40:

| run | worst frame | s 1-5 after the blast |
|---|---|---|
| 40, 1 | 1,622 ms | 2-5 frames a second, 20-40 ticks each, 420-1,070 ms |
| 40, 2 | 1,778 ms | 2-3 frames a second, 22-40 ticks each, 270-1,350 ms |
| **CatchUp, 1** | **190 ms** | 30-31 frames a second, 2 ticks, 46-79 ms; the clock at half speed for ~3 s |
| **CatchUp, 2** | **186 ms** | 30-34 frames a second, 2 ticks, 32-92 ms |

The playtest's 25 s was that spiral at a later, longer stretch of dear ticks (its fire had brought
members down; this bench's hadn't in 200 s). **`CatchUp`** (`src/main/catch_up.gd`, the bridge
calls it each frame): when a tick costs 0.9 of its own time the limit is 2 (the game's own);
otherwise as many as fit in 400 ms, up to 40. The same ticks run; game time runs slower than the
clock while it can't keep up, as the game does at 2. Nothing is skipped.

## The lost taps

`PlayerCarry` took a tap by polling `is_action_pressed` a tick: E down and up inside one slow frame
(both come in one flush) is never seen down, so the tap was lost; and under the spiral one bridge
`key E 0.1` lasted 40-80 ticks of game time, past `carry_tap_s` (a hold). Now a tick where E is
both just pressed and just released (Godot 4.7 reports both) is a tap, and with `CatchUp` a tap
stays a tap. `PlayerShove` and `PlayerKnock` read `is_action_just_pressed` and already took them.
`tests/test_catch_up.gd`.

## The valley (#1119, 2026-11-20)

`--world=valley --scene=chaos --chaos-seconds=60` (two crews of three by the saloon, three sticks in
saloon B; no fire). Prof timers put round the cover search's parts for the run (taken out after).

**outlaw_brain's 100-200 ms frames were the cover search's town ways.** A cover search
(`Cover.search`, `_best_in_town`) works out a man's ways to every place once (`Waypoints.routes_from`),
asking a straight walk (a ray, then a sweep) to **every** place. The town has 38; the valley ~360,
most out of reach: 16,843 `q_walk` asks in one frame, `routes_from` 90-130 ms in nearly every spike.
A way is only kept if it's no longer than its spot's distance x1.6 + 6 m (12 for `cover_way`), so a
place further than that can't start one: `routes_from` now takes a `reach` (the search's furthest
spot x1.6 + the extra + 10 m for stairs) and asks only the places in it. Second,
`route_to_point` (a hunt's way, an order's, a rescue's) asked every place nearer the spot than the
best so far in the dictionary's order (up to ~360 sweeps, 30-90 ms); now nearest first, the first
it can walk from wins: the same place. `tests/test_places.gd` holds both to the old ways.

| run (60 s, this VM) | brain frames >= 100 ms | >= 50 ms | worst brain frame |
|---|---|---|---|
| before | 25 | 34 | 204 ms |
| `routes_from` with a reach | 0 | 14 | 90 ms |
| and `route_to_point` nearest first | 0 | 3 | 91 ms |

**What's left in the brain** (two fixes, then reported): a search step (40 spots a tick,
`Search.step(40)`) is still 15-45 ms here, now and then 70-90: sight lines 2-8 ms, evaluating the
spots (`evaluate`, far and narrow) 1-40 ms, and routing the best few (`route`'s sweeps round one
thing, then `_town_way`) 17-37 ms, in the chunk that routes. `route_to_point`'s `route` 15-30 ms.
Next: fewer spots a tick when they're dear (a time budget for `step`, not a count), or the routing
moved to its own tick; both spread, neither changes where he goes.

**Saloon B's blast frame is untouched:** 900-1,000 ms its first frame here, `settle_analyse`
~670 ms of it (~1,800 members broken; the valley has no FireSystem to slice a settle). The run's
mean frame is ~24 ms with ~400 frames over 33 ms, ~240 of them in the blast's first 5 s (Jolt
stepping the pieces, as in the town above), most of the rest the search steps above.

### The search step, spread (#1123, 2026-11-21)

**A cover search now spreads its chunks over ticks by a work budget.** `Cover.Search.step` still takes
the spots 40 at a time (each chunk scored, then its best few routed, as before), but a chunk is
worked a piece at a time (`Cover.Pick`: its first lines, then one spot scored, then one routed) and
a step stops once it has spent `Cover.STEP_MS` (4 ms here) of the wall clock, or under
`World.deterministic` `STEP_ASKS` (400) queries (`Cover.asked` + `Waypoints.asked`, counted always),
the `WorkBudget` the settle uses. The next tick carries on from that piece, and a cheap chunk lets the
next one start in the same step. The chunks are the same however it's spread, so **he finds the same
spot**: 599 searches over the test street (five variants, two threats) gave identical spots, scores
and ways before and after; `tests/test_places.gd` holds a spread search to the unspread one.

Same VM, same run, one after the other (the fight goes differently each run: two runs of the old code
gave 78 and 15 brain frames >= 33 ms):

| run (60 s, this VM) | brain frames >= 33 ms | >= 50 ms | worst brain frame | frames > 33 ms | mean frame |
|---|---|---|---|---|---|
| before (main), run 1 | 78 | 29 | 116 ms | 453 | 19.8 ms |
| before, run 2 | 15 | - | 89 ms | 334 | 20.6 ms |
| spread, run 1 | 0 | 0 | 26 ms | 180 | 16.3 ms |
| spread, run 2 | 0 | 0 | 33 ms | 186 | 17.4 ms |

Searches (a print round `_step_search` for the runs, taken out): before 123 started, all finished,
20 found a spot, 4 ticks median, 12 at most; spread 57 and 62 started, all finished, 6 and 19
found, 2 and 4 ticks median, 32 and 79 at most (~1.3 s here, ~0.85 s on Sean's: the dear ones wait
longer for his decision, never a different one).

**Saloon B's blast frame, reported, not fixed:** 550-620 ms its first frame on these runs (the VM
was quicker than #1119's), `settle_analyse` 420-480 ms of it. A settle is sliced over frames only by
a FireSystem's queue (`Structure.settle`, `FireSystem.queue_settle`), and the valley has none, so
the whole settle lands on the frame. Fixing it means a settle queue that isn't the fire's (or a
FireSystem in the valley, which brings fire there: Sean's call), more than a targeted fix: the
next step (its issue).
