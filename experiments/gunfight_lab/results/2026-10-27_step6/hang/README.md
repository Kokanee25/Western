# The hang: Godot's threaded physics server deadlocks (4.7.2)

**With physics on its own thread the game deadlocked three times: the full test suite in 2 of
its 5 runs after the fixes, and the soak at 121 of its 240 game minutes** (`../gate.md`): every
thread asleep, never coming back. Nothing of ours is running in any of them; none of the 40 lab
games, 23 seed-2 games, 4 blast runs, 8 smoke tests or the 10 runs of the suite's first stretch
hung. The control: four thread-off suites under the same load,
none hung (`../gate.md`).

## What the threads were doing (gdb; the official build has no symbols, so addresses)

**Hang 1** (suite run 2, after `test_ballistics`; `suite_hang_threads.txt`,
`suite_hang_main_and_pump.txt`):
- the main thread in a condition-variable wait called straight from the main loop (three frames
  from `main()`: the physics sync at a frame's start waits for the physics thread);
- the physics thread (`WorkerThread 0`: the pump task, `_thread_loop`, at 0x1989fe6) running a
  queued command (`CommandQueueMT::flush_all`, 0x41fce24 -> 0x4f7e67; the same frames as the
  soft-body crash's, `smoke_softbody_crash.txt`), which sits in a condition-variable wait on a
  mutex that isn't the pool's (most likely Jolt's step waiting at its job barrier);
- the other three pool workers asleep in their idle wait (0x490545d), the queue apparently empty
  to them; the plugin's three workers idle (one in `recv`, two on its mutex: its normal idle).

**Hang 2** (suite run 5, in `test_dynamite`; `suite_on5_hang_threads.txt`):
- the main thread waiting on the physics queue from a script call (a GDScript call chain into
  `CommandQueueMT`'s wait for a result: a physics getter outside the window, `push_and_ret`);
- the physics thread inside the pool's own wait (0x4907ca0 -> 0x49065c1) from its queue flush
  (0x41fcdfc): a collaborative wait or a yield that was never woken;
- the other three pool workers asleep, idle.

**Hang 3** (the soak, 121 game minutes in; `soak_hang_threads.txt`): the same as hang 2, frame for
frame on the physics thread (0x41fcdfc -> 0x4907ca0 -> 0x49065c1) and the same wait on the main
thread (0x4f7fdf -> 0x4e0fe3b), reached from another caller.

A lost wake-up in `WorkerThreadPool` between the pump task and the tasks around it (Jolt's jobs
are pool tasks too, `JoltJobSystem::Job::queue`, high priority), the same family as the quit hang
of #392 (`_handle_runlevel`). Read so far (`core/object/worker_thread_pool.cpp`:
`_post_tasks`, `_notify_threads`, `_wait_collaboratively`, `yield`, `notify_yield_over`;
`modules/jolt_physics/spaces/jolt_job_system.cpp`) without finding the exact path; finding it
needs a build with symbols and a way to make it happen more than one run in three.

## What it means

- **The setting stays off** (it is the default, and nothing changes with it off: the thread-off
  game plays the same fights as main's). On, the game can freeze in play.
- **No Jolt or project setting avoids it**: Jolt's job thread count is the pool's
  (`JoltJobSystem`'s `thread_count`), with no setting of its own.
- **Ways on**, Sean's call (issue on the PR): report it upstream with these stacks and a build with
  symbols; or leave physics on the main thread, since what it buys here is small (headless
  −0.05 to −0.54 ms in the gunfight, −1.6 ms after the stick; drawn, unmeasured).
