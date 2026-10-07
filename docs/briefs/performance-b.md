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

## Step 1 results (2026-10-07): neither goes in yet

Drawn, lavapipe, 10 s a scene (`--no-render-time`, new: reading the viewport's render time makes
a separate render thread wait every frame), avg ms a frame / main thread's physics ms:

| Scene | safe (today) | separate |
|---|---|---|
| calm, full window | 2228 / 19.6 | 2167 / 8.0 |
| calm, 320x180 | 1914 / 21.1 | 1904 / 8.8 |
| fire, full window | 2320 / 45.9 | killed at the 2 h limit, not measured |

- Lavapipe here is bound by vertex work on ~15k draw calls (a 320x180 window is no faster), so
  the frame can't show the thread's gain; the timed systems' share is the same either way (calm
  people_body 3.5 / 2.6 ms; `player` reads 10.6 ms in safe mode drawn, 0.5 separate, untraced).
- **Separate render thread fails the smoke test** (`--smoke-test`, drawn, separate): two
  `_texture_2d_update` with an empty image at load and one `particles_set_view_axis` on freed
  particles, plus `finalize ... only from the render thread` at exit. They're races: they vanish
  when every node add is followed by `RenderingServer.force_sync()`. The empty images arrive while
  the street's people are built (between the barkeep and the dry grass); no script of ours calls
  `ImageTexture.update`, so it's likely the engine's own (font cache?); 4.7.2 calls the mode
  experimental. Also sync points that cost it a frame each: `Structure._build_batch` reads mesh
  surfaces (`mesh_get_surface`, 154 in the fire scene), `particles_is_inactive`.
- **Jolt on its own thread** (`physics/3d/run_on_separate_thread`): 359 passed, 10 failed, all
  "Space state is inaccessible": the gun's `_shot_line` (fired from input in `_process`),
  `Blast.detonate` (a stick going off in hand), `test_gun_range`'s own wall ray. Chaos tests pass.
  Making it work means moving firing and blasts onto the physics tick (a frame later at most) and
  every `_process` query (gun smoke's roof check, `depth_mosaic`, …) the same way.
- Not run, as nothing changed on the way in: the bug-report replay and the golden check.

## Step 1 notes

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
