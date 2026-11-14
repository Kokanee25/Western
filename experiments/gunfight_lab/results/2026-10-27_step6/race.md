# The rare race (step 6's first job)

The review's seed 2 (`results/2026-10-25_threading/same_fight.txt`): with physics on its own
thread, the same for 116 events and 48.9 s, then the player blacked out in one run and not the
other. The method was seed 2 ten times with the thread on, then each suspect removed, until ten agree.

## Ten times, today's code (main at a8dacf1 plus this branch's setting)

`python3 experiments/gunfight_lab/run.py --scenarios=spec_hall --hours=golden --weapons=revolver
--styles=careful --bodies=studio --variant=D --seeds=2 --jobs=1 --max=120` ten times, two at a time,
the thread on (`user://engine.cfg`): **10 of 10 the same** (74 events, 23.4 s, you down), zero "inaccessible" or "being stepped" errors in any log. Every suspect was already gone:
step 1 made the wall-clock budgets counts under `deterministic` and left no global dice in `src/`
(none: `grep` for `randf(`, `randi(`, `shuffle()`, `pick_random()`), and the pool runs at its usual
size here (the first suspect, Jolt's jobs beside the pump task, needs no removing: the ten agree
with it in).

## Ten times, the review's own commit

The review's runs were "main as of #372 plus `claude/gameplay-saloon-cover`" with uncommitted
probes; the nearest commit is `claude/perf-threading` at e0131ed. In its own worktree with the
thread on (a `res://override.cfg`), seed 2 ten times, two at a time: **10 of 10 the same**, and
three more with three cores kept busy (`race/stress.py`): the same again. But that code's seed 2
here is a different fight from the review's (24.8 s, 67 events; the review's 49.5 and 58.3 s), so
the review's divergence can't be replayed: not reproduced on either build.

## What can race, from Godot 4.7.2's source

Read in `servers/physics_3d/physics_server_3d_wrap_mt.h/.cpp`, `servers/server_wrap_mt_common.h`,
`modules/jolt_physics/jolt_physics_server_3d.cpp` and `spaces/jolt_physics_direct_space_state_3d.cpp`:

- **In the physics window nothing is queued.** The wrapper queues a call only when
  `!(doing_sync && Thread::is_main_thread())` (`ASYNC_COND_PUSH`): while the window is open, the
  main thread's writes and reads go straight to Jolt, as without the thread (the brief's "the
  window's writes land just before the step" is not so). Hence the fights below: the thread on and
  off play the same fights event for event, because since step 1 every query is in the window.
- **Outside the window**, writes are queued and the getters that return a value (`body_get_state`,
  `shape_get_data`...) are `push_and_ret`: they wait for the queue, the step included, so they read
  the world after the step, every time. Deterministic.
- **Not wrapped:** `space_get_direct_state` and `body_get_direct_state` return null outside the
  window (an error, deterministic: always null there). **`body_test_motion`** (`test_move`,
  `move_and_collide`, `move_and_slide`) and **any call on a space state held from before**
  (`intersect_ray` and the rest) go straight to Jolt, which checks only `space->is_stepping()`, a
  flag the physics thread sets: outside the window they meet a step running or not, by timing,
  and read the world before, during or after it, or fail with "must not be called while the physics
  space is being stepped". **This is the one class of call that races under the thread.** Today's
  code: `Player` calls `test_move`/`move_and_slide` only from `_physics_process`; the one space state
  held (`Cover.Search._space`) is stepped only by the brains' ticks. No log in any run here has the
  "being stepped" error.
- **Wall-clock budgets** (the review's code: `Structure`'s batch rebuild gap and frame budget, the
  settle's and the load check's ms budgets, all by `Time.get_ticks_*`) move work to another frame
  when the frames' timing changes, and the thread changes it. Step 1 made them counts under
  `deterministic` (the lab and the tests).

**So:** the review's divergence came from its code, not from the thread: that build ran the lab
without count budgets and with the player's shot and other queries outside the window, the classes
above. On today's code no suspect is left and ten agree, twice over (seed 2 ten times, and the lab's
ten seeds twice under the thread, `same_fight_*.txt`).

## One crash the thread brings (found by the drawn smoke test)

Not a race in the fight, a crash in the drawn game: **`SoftBody3D` with physics on its own thread**
(Godot 4.7.2). A soft body copies its points into its mesh at `RenderingServer.frame_pre_draw`,
outside the window: `open()` the mesh's write buffer, `soft_body_update_rendering_server` (queued to
the physics thread, since it's outside the window), `close()` (the buffer pointer set to null),
commit. The queued copy then runs on the physics thread and writes through the null pointer:
signal 11 (`build/smoke/thr_1.log` here: "The caller thread can't call `propagate_notification()`
on /root", then the crash). Headless never draws, so the lab and the tests never met it. Fixed with
`SoftBodyDraw` (`src/world/soft_body_draw.gd`): with the thread on and a window that draws, each
physics tick it takes the soft bodies' `frame_pre_draw` connections and calls them inside the
window, where the copy is a direct call. The drawn smoke test then passes and exits five of five
(`smoke.md`).
