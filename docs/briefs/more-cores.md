# More cores (gameplay, 2026-10-24)

**Goal:** the game uses the cores Sean's PC has, so a gunfight in the new saloon holds 60 fps.

Sean, 2026-10-24: the trial gunfights (D+) are "kinda fun — but it really slows down", and it's
the frame rate, not the pace. "It may be time for more cores." His PC shows 32, most likely
logical processors (16 cores, two threads each). **The target isn't his PC.** A PS5 is 8 cores
and 16 threads, the Steam Deck 4 and 8, and a typical Steam PC has 6–8 cores. So:

- **The main thread** still fits its own budget on one core. It does what must happen in order:
  input, the player, the scene changes.
- **The rest** goes to a small, fixed set of helper threads, about 3–7: drawing, physics and the
  per-person work. It runs well on 4–8 cores, with spare on his.

## Where it stands

- **The budget** (CLAUDE.md, "Frame budget") is a 60 fps frame on one 3.25 GHz core, and the game
  is built that way. None of Godot's threading settings are set: drawing, physics and every system
  run on the main thread. Jolt already runs its own solver jobs.
- **A gunfight in the new saloon costs more than the budget,** before drawing. Headless on this
  workspace's 2.1 GHz core:
  - the game's D: people 8.8 ms (budget 4.0 at Sean's, about 5.7 ms there);
  - the trial D+, under load: about 15 ms.
  - **The clean A/B** (`experiments/gunfight_lab/results/2026-10-24_perf/`), the same 10 fights
    one at a time with the careful player:
    - D: a frame 19.7 ms on average, its worst 5% at 41.5 ms, people 10.2 ms;
    - D+: 19.9, 42.8 and 10.6 ms.
  - **So the trial isn't what's slow.** Any gunfight in the new saloon is, and D+ fights last
    longer. At Sean's that's roughly a 13 ms frame with spikes to about 27 ms, before drawing.
- **The heaviest systems:** `people_body`, `outlaw_brain`, `people_skeleton`, `senses` and
  `civilian_brain` (the townsfolk's). There are also two surprises in a gunfight: `fire` at
  1.5–2.8 ms with nothing burning, and `floor_marks` at about 1 ms.

## The steps, each measured before and after

1. **Drawing on its own thread.** Set `rendering/driver/threads/thread_model` to "Separate". Render
   CPU is 3–6 ms of the main thread. Godot calls this mode experimental, so it ships behind a
   setting until builds prove it.
2. **Physics on its own thread.** Set `physics/3d/run_on_separate_thread`. Measured 2026-10-24 on
   the same 10 fights (`results/2026-10-24_perf/physics_thread.txt`): the frame went from 19.7 to
   17.0 ms and its worst 5% from 41.5 to 36.1 ms. The same seeds didn't play the same (two fights
   ended with the player dead, not down). Code that reads physics
   state then gets it a frame behind, and we ray-cast every tick (ballistics, senses, cover), so it
   needs the gunfight and body labs re-run: no ball through a man, sight lines the same.
3. **Our per-person work across cores.** Brains, senses and bodies are per man, which suits running
   them side by side. The pure parts go into Godot's `WorkerThreadPool`, or the Rust plugin with
   rayon: wound, pain and bleed updates, aim and sway, senses' visibility scores, the skeleton's
   pose solve. Anything that touches the scene stays on the main thread (moving nodes, emitting
   events, spawning). Each system's move is its own merge, with its test showing the same results
   in the same seeded fight.
4. **The two surprises.**
   - **`fire` (1.5–2.8 ms) with nothing burning.** It's most likely not fire at all.
     `FireSystem._check_loads` re-settles any building a broken member queued
     (`StructuralAnalysis`, a few members a frame), and is timed under "fire". In a gunfight,
     every ball that breaks a board queues the spec saloon, one structure of thousands of members,
     again. Settle only the members near the damage, or move it off the main thread.
   - **`floor_marks` (~1 ms).** Its tick should sleep when nothing's tracked or wet.
   - Both are single-core fixes.
   - **Done 2026-10-25** (`experiments/gunfight_lab/results/2026-10-25_perf/`): a hole re-checks only
     its own member (`StructuralAnalysis.recheck`, `member_alone`), the fire's grid is built only
     while something's hot, and floor marks' drying is redrawn once a second. On the bench's 10
     fights fire 2.02 -> 0.15 ms, floor_marks 1.14 -> 0.10, the frame 28.7 -> 26.2 ms and its worst
     5% 57.0 -> 41.4 (this workspace's slower core; at Sean's ~17.0 and ~27 ms). Found on the way:
     a fight already depends on the core's load (carved members' shapes swap in when the worker
     thread is done), which step 2 has to fix first.

## What done looks like

- A D+ gunfight in the new saloon with three men and the town in holds 60 fps on Sean's PC. His F3
  shows the frame, and he plays it.
- The lab reports the main thread's share and the frame's for the same fights, before and after
  each step.
- The budget table in CLAUDE.md is re-stated for several cores: the main thread's budget, and what
  may run beside it.
- The seeded lab fights still come out the same: threading must not change a fight's outcome, so
  the tests hold every system to its seed.

## How it's judged

- The lab's `perf` numbers. Every fight records each system's time and the frame's.
- `tools/perf_bench.gd` for the town scenes.
- Sean's play on his PC. Lavapipe here can't stand in for his GPU.
