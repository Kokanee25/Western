# More cores (gameplay, 2026-10-24)

**Goal:** the game uses the cores Sean's PC has, so a gunfight in the new saloon holds 60 fps.

Sean, 2026-10-24: the trial gunfights (D+) are "kinda fun — but it really slows down", and it's
the frame rate, not the pace. "It may be time for more cores." His PC has 32 (logical) cores.

## Where it stands

- **The budget** (CLAUDE.md, "Frame budget") is a 60 fps frame on one 3.25 GHz core, and the game
  is built that way. None of Godot's threading settings are set: drawing, physics and every system
  run on the main thread. Jolt already runs its own solver jobs.
- **A gunfight in the new saloon costs more than the budget,** before drawing. Headless on this
  workspace's 2.1 GHz core:
  - the game's D: people 8.8 ms (budget 4.0 at Sean's, about 5.7 ms there);
  - the trial D+, under load: about 15 ms.
  - The clean A/B, the same 10 fights one at a time, is in `experiments/gunfight_lab/results/2026-10-24_perf/`.
- **The heaviest systems:** `people_body`, `outlaw_brain`, `people_skeleton`, `senses` and
  `civilian_brain` (the townsfolk's). There are also two surprises in a gunfight: `fire` at
  1.5–2.8 ms with nothing burning, and `floor_marks` at about 1 ms.

## The steps, each measured before and after

1. **Drawing on its own thread.** Set `rendering/driver/threads/thread_model` to "Separate". Render
   CPU is 3–6 ms of the main thread. Godot calls this mode experimental, so it ships behind a
   setting until builds prove it.
2. **Physics on its own thread.** Set `physics/3d/run_on_separate_thread`. Code that reads physics
   state then gets it a frame behind, and we ray-cast every tick (ballistics, senses, cover), so it
   needs the gunfight and body labs re-run: no ball through a man, sight lines the same.
3. **Our per-person work across cores.** Brains, senses and bodies are per man, which suits running
   them side by side. The pure parts go into Godot's `WorkerThreadPool`, or the Rust plugin with
   rayon: wound, pain and bleed updates, aim and sway, senses' visibility scores, the skeleton's
   pose solve. Anything that touches the scene stays on the main thread (moving nodes, emitting
   events, spawning). Each system's move is its own merge, with its test showing the same results
   in the same seeded fight.
4. **The two surprises.** Why `fire` costs 1.5–2.8 ms with nothing burning, and why `floor_marks`
   costs 1 ms. These are likely ticks that should sleep, and they're single-core fixes.

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
