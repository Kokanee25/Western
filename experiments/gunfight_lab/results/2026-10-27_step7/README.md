# More cores, step 7: the render thread, behind a setting (2026-10-27)

`docs/briefs/more-cores.md` "Step 7" (issue #399). This workspace's VM (4 vCPUs, ~2.1 GHz; x0.65
for Sean's core; lavapipe draws on the CPU). Godot 4.7.2's source read for how its render thread
works (`rendering_server_default.cpp`, `server_wrap_mt_common.h`, `command_queue_mt.h`,
`main.cpp`'s `iteration`).

## The setting

`Settings.render_thread` (off). Godot's "Separate" thread model,
`rendering/driver/threads/thread_model=2`, is read only at start, so it goes in step 6's file
(`user://engine.cfg`, `[rendering] driver/threads/thread_model=2`): `Settings.set_render_thread(on)`
and `-- --render-thread=on|off` write it for the next start; Godot's own `--render-thread
separate|safe` sets it for one run. `Settings.render_thread` is what this run has
(`not RenderingServer.is_on_render_thread()` from the main thread); F3's native line says which.
No panel or key. `docs/LAYOUT.md` "src/autoload".

**The tools stay on the main thread.** With the thread, `frame_post_draw` is deferred from the
render thread to the main thread's next flush, and a texture read waits for the draw in flight: a
tool that sets up a view, awaits the signal and reads the viewport gets the frame after. So:
- **A script run (`-s`) refuses to start when the setting file turns the thread on**
  (`Settings._refuse_render_thread`, exit 1, the file's path and the fix in the error). Godot
  strips `--render-thread` from the arguments a script sees, but a thread asked for on the command
  line leaves the project setting alone: the setting is 2 only when it came from the file. So the
  screenshot, golden, tour, judge and lab tools never take it from the file (no edit to art's tools),
  and a run that wants it asks by name (`--render-thread separate`: the suite, `perf_bench`, the
  soak below).
- `tools/bridge.py start` passes `--render-thread safe` unless `--render-thread=on`; the gunfight
  lab's `run.py --render-thread=on|off` sets its fights, and its `--sheet` is always safe.
- In the game, the bridge's `screenshot` and F12's picture await `frame_post_draw` and read the
  viewport: with the thread a whole drawn frame, one later. Fine for both; documented.

## What the thread changes in our code (`audit.md`)

Every direct `RenderingServer.` call in `src` (16 files) checked: writes are queued in order with
their arguments copied; reads wait for the render thread; `frame_pre_draw` is unchanged; nothing
assumed the frame was drawn by the time a write returned. Three things found and fixed, each only
a cost with the thread:
- **F3 waited for the render thread twice a viewport a frame** (`viewport_get_measured_render_time_*`).
  On main's code with the thread and F3 up, Godot warned "causing RenderingServer synchronizations
  on every frame" 120 times in 20 s: Sean's F3 would have taken away what it measures. Now read
  twice a second with the thread: no warning.
- **The lamps' flicker**: a light write a lamp a frame. Each write takes the render queue's lock and
  wakes the render thread (`CommandQueueMT::_push_internal`): `lamps` 0.21 -> 1.00 ms a frame in
  the lab's fight. With the thread a lamp writes it every third frame (staggered); without it,
  every frame as before (the goldens are drawn without it). Sight reads a lamp's base energy, not
  the flicker.
- **The body's inside**: a wound's first opening copied a shader material a shell with
  `duplicate()`, which asks the RenderingServer for the shader's uniforms (a wait each copy, 0.08
  -> 1.2 ms): the chest's first opening 9 -> 38-47 ms, and `test_openings`' 40 ms failed every run.
  `BodyInterior.copy_material` asks once a shader: 10 ms with the thread, 6.4 without.

## The gate (`gate.md`)

- **The suite: no hang in five runs with the thread on** (step 6's physics thread hung 2 of 5).
  Not green, and it can't be headless: Godot's headless (dummy) renderer keeps its meshes and
  textures in stores that aren't thread-safe, and with the render thread a lookup can come back
  empty. It hit a different test each run (`test_chaos`, `test_prop_factory`, `test_gun_range`...);
  every script error in the five runs is in that renderer's storage or follows from it, none in our
  code, and it doesn't happen drawn. Besides it: `test_perf`'s three budgets (main fails them the
  same here; CI passes) and `test_openings` (fixed above, now green both ways).
- **The lab: 10 of 10 the same** with the thread on twice, on against off, and this branch against
  main's (bc8d5d2, its own worktree), on and off (`same_fight_*.txt`, `runs/`).
- **The drawn smoke test, two cores, the thread on from the setting file: exited 5 of 5**, the whole
  course played each time. Its verdict FAILED each time on two of Godot's errors that only the
  thread brings (the font cache's glyph upload, `particles_set_view_axis` on a freed particles
  system: `gate.md`); thread off, `ok`.
- **The soak, the thread on: 210 game minutes, no freeze** (stopped by this session's 3-hour cap;
  step 6's physics thread froze it at 121). Memory flat, frame 7-8 ms. A first run was cut at 55 by
  a container restart.
- **The goldens: this branch renders what main renders**; main's goldens don't hold on this
  machine (23 of 77 over on the branch, 20 of the same 23 on main itself); branch against main
  within run-to-run noise, view by view. Nothing re-approved.
- **Merged with main at 55a510b1:** `PerfRing` (#433, F12's frame numbers) read the render times
  every frame while F3 was up with the thread: now as F3 does.

## The numbers

**Headless (the lab's ten D fights, `--jobs=1`; `perf.md`, `perf_host2.md`).** Headless there's
no draw for the thread to overlap, so this is its cost alone: the queue's lock and a wake of the
render thread for every write. The container moved to another host mid-step, so the before and
after are each from one host:

| host 2, ms a frame | main | off | on (both fixes) | on again |
|---|---|---|---|---|
| frame (mean / p95) | 14.61 / 18.23 | 14.51 / 17.77 | 16.11 / 20.07 | 16.13 / 19.46 |
| window / step / rest | 9.28 / 1.31 / 3.94 | 9.23 / 1.31 / 3.89 | 9.63 / 1.80 / 4.61 | 9.69 / 1.78 / 4.59 |
| people | 6.90 | 6.87 | 7.04 | 7.10 |
| lamps | 0.12 | 0.14 | 0.40 | 0.40 |

**+1.6 ms a frame headless with the thread**, before the fixes +2.9 (host 1: frame 21.5 -> 24.4,
lamps 0.21 -> 1.00). It is the engine's: the physics step's transforms and the skeletons' bones
(`step`, `rest`), each a queued write. The counters are the same in all (`q_cover` 60.4, `q_writes`
63.9, `q_lamps` 4.3 a frame), and the fights 10 of 10.

**Drawn (lavapipe, `perf_bench --render --no-render-time --scene=calm --seconds=4`, `drawn/`):**
the frame is the CPU-drawn draw, ~1.2 s, so this can't show the gain; it shows the main thread's
work coming out from under the draw and nothing stalling:

| | off 1 | on 1 | off 2 | on 2 |
|---|---|---|---|---|
| frame mean / p99, ms | 1204 / 1426 | 1187 / 1353 | 1244 / 1597 | 1184 / 1520 |

**At Sean's** the draw is the GPU's and the render CPU 2.9 ms in the calm street (CLAUDE.md's
table), more in a saloon fight: with the thread that CPU side runs beside the next frame's ticks,
against ~1 ms of the thread's own cost (1.6 here x 0.65). The brief expected -3 to -6 ms; whether
it's that is his F3's to say.
