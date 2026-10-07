# Performance, part B: use more cores (gameplay session)

**Sean's plan (2026-10-06, verbatim):** "Performance, part B: use more cores. Measure before and
after each step with perf_bench.gd (calm, fire, blaze, wall) and give me the frame split for each.
One merge per step: 1. Turn on the separate render thread (the project's thread model setting), and
Jolt physics on its own thread if it passes the tests. Check the chaos tests, bug-report replay and
goldens still pass, and tell me what to look for on my Shadow PC. 2. Move the fire's per-member tick
into the native plugin's worker pool, with the same results as today (compare member states old
against new, as in the earlier fire work). 3. Then the structural analysis, then physiology for
people far from the player. Stop and report if any step breaks determinism or the tests, rather
than loosening them."

## Baseline (main at 6081685, build 691; 2.1 GHz workspace core, headless)

`godot --headless --fixed-fps 60 -s res://tools/perf_bench.gd -- --scene=<s> --no-ablate`. Run
benches with nothing else rendering on the machine.

| Scene | avg / p99 / max ms | Budget line (scaled to 3.25 GHz) | Timed, top (ms a frame) |
|---|---|---|---|
| calm | 4.60 / 8.07 / 22.0 | total 2.99 of 14; all under | people_body 1.27, senses 0.50, outlaw_brain 0.26 |
| fire | 11.89 / 39.86 / 77.5 | fire_effects **2.70 of 2.0** | fire 4.14, civilian_brain 2.43, people_body 1.37 |
| blaze | 13.25 / 40.63 / 51.7 | fire_effects **4.43 of 2.0** | fire 6.81, civilian_brain 1.39, people_body 1.20 |
| wall | 6.95 / 27.97 / 34.0 | total 4.52; all under | fire 1.54, people_body 1.32, senses 0.53 |

New since the last bench: `civilian_brain` 2.4 ms in the fire scene (the bucket line's routing and
`_stand_by` rays). Worth a look after step 1.

## Step 1 notes (only the baseline is done)

- Render thread: `rendering/driver/threads/thread_model` in project.godot (shared file); try it
  first from the command line, `--render-thread safe|separate`. Measure drawn under xvfb + lavapipe:
  `xvfb-run -a godot --rendering-driver vulkan --render-thread <mode> --fixed-fps 60 -s
  res://tools/perf_bench.gd -- --render --scene=calm|fire --no-ablate --no-budget`. Lavapipe's
  raster dominates, so the gain shown here understates a real GPU's; Sean's F3 on Shadow judges.
- Physics is already Jolt (`3d/physics_engine="Jolt Physics"`). Its own thread is
  `physics/3d/run_on_separate_thread`, which only allows space queries inside the physics step.
  `direct_space_state` is used in 24 files (45 places), some from `_process` (the gun's tuck in
  `weapon_viewmodel.gd`, `gun_smoke.gd`'s roof check, `depth_mosaic.gd`): expect test failures;
  if so, report rather than rewrite them all.
- Then the chaos tests, `tools/replay.gd` on a bug report, and `tools/golden_check.py --render`.
- Don't kill processes with `pkill -f <pattern>` / `pgrep -f` in the same command: the pattern
  matches the shell's own command line and kills it.

## Steps 2 and 3

- Fire tick native: `FireSystem._visit` into Rust on the worker pool (`pool.rs`), f64 to match
  GDScript's floats; prove identical member states after N ticks on the street, old vs new.
- Then `StructuralAnalysis` native, then physiology ticking slower for people far from the player
  (physiology itself is cheap: a person's cost is pose and the stand check).
