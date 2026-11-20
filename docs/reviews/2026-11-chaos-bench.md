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
