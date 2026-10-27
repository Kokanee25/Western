# More cores (gameplay, 2026-10-24; the threading design, Fable, 2026-10-25)

**Goal:** the game uses the cores Sean's PC has, so a gunfight in the new saloon holds 60 fps.

Sean, 2026-10-24: the trial gunfights (D+) are "kinda fun — but it really slows down", and it's
the frame rate, not the pace. "It may be time for more cores." His PC shows 32, most likely
logical processors (16 cores, two threads each). **The target isn't his PC.** A PS5 is 8 cores
and 16 threads, the Steam Deck 4 and 8, and a typical Steam PC has 6–8 cores. So:

- **The main thread** still fits its own budget on one core. It does what must happen in order:
  input, the player, the scene changes.
- **The rest** goes to a small, fixed set of helper threads, about 3–7: drawing, physics and the
  per-person work. It runs well on 4–8 cores, with spare on his.

The rest of this brief is in two parts: **where it stands** (the saloon session's measurements,
2026-10-24, and what main has gained since) and **the design** (the Fable review of 2026-10-25:
what the first plan got wrong, how Godot actually threads, what each per-person system reads
and writes, and the ordered steps, each written as a next-session prompt). The numbers behind
the design are in `experiments/gunfight_lab/results/2026-10-25_threading/`.

## Where it stands

- **The budget** (CLAUDE.md, "Frame budget") is a 60 fps frame on one 3.25 GHz core, and the game
  is built that way. None of Godot's threading settings are set: drawing, physics and every system
  run on the main thread. Jolt already runs its own solver jobs (on Godot's `WorkerThreadPool`).
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
- **The heaviest systems:** `people_body` 3.85, `outlaw_brain` 2.84, `people_skeleton` 1.47,
  `senses` 1.15 and `civilian_brain` 0.51 (ms a frame, this core). Two surprises: `fire` at
  1.5–2.8 ms with nothing burning, and `floor_marks` at about 1 ms. Both gone since 2026-10-25
  (`experiments/gunfight_lab/results/2026-10-25_perf/`): the holes' settles by #375's incremental
  analysis, the grid's idle rebuild (0.22 ms) and the floor marks' redraws (1.2 ms) by #373.
- **Physics on its own thread** (`physics/3d/run_on_separate_thread`), measured 2026-10-24 on the
  same 10 fights (`results/2026-10-24_perf/physics_thread.txt`): the frame 19.7 -> 17.0 ms, its
  worst 5% 41.5 -> 36.1 ms, and the same seeds didn't play the same (two fights ended with the
  player dead, not down). Why, exactly, is in the design below.
- **Done on main since** (PR #375, build 2448, the blast freeze, #374): the structure's analysis
  is carried over and brought up to date for the members marked changed (`Structure.start_analysis`,
  `mark_dirty`, `StructuralAnalysis.begin_update`), `settle(budget_ms)` runs on a frame budget
  and hands the rest to `FireSystem._check_loads`' slices. So "fire with nothing burning" (the
  spec saloon re-settled whole after every broken board) is fixed; what's left under `fire` is
  the fire's own periodic work (`experiments/blast_freeze/README.md` "What's left": the
  townsfolk's brains in a fire at 30–90 ms a frame, the grid rebuilt every 2 s at ~40 ms, the
  neighbour lists refreshed together at ~45 ms, the smoke field's step at 90–130 ms, the frame
  after a stick at ~125 ms). Those are hitches, single-core, and step 5 of the plan below (Sean,
  2026-10-25: one master plan here, not a hand-off to #376).
- **Main today** (2026-10-25, with #375 merged; `results/2026-10-25_threading/probe.txt`): the
  same D fights are a **20.0 ms frame with the worst 5% at 24.4** (the 42 ms spikes were the
  settles), `fire` 0.3; the named systems ~13.5 ms, ~6.5 untimed (Jolt's step, the transform
  propagation, signals, the engine). At Sean's that's ~13 ms before drawing, so the gunfight is
  near 60 fps already and every step below is headroom and spikes.
- **The lab's determinism check:** `experiments/gunfight_lab/same_fight.py RUN_A RUN_B` (2026-10-25)
  pairs the fights of two runs by name and compares each event for event (the timeline, the
  ending, every man's and your shots and hits; the frame times left out), printing the first
  divergence. Every step below is checked with it: the same seeds run twice on the new build must
  come out the same, and a step that changes what a fight *is* (not only how fast) says so and
  re-baselines on purpose.

## The review (Fable, 2026-10-25)

Read for this: issue #373, the brief above, `results/2026-10-24_perf/`, CLAUDE.md "Frame budget",
`HumanBody._physics_step` and `_apply_pose`, `OutlawBrain._physics_step`/`_combat`/`_fight`/
`_fire_at`, `Senses`, `Cover`, `SightLight`, `Ballistics`, `Physiology.step`, `StructuralAnalysis`,
`FireSystem._check_loads` (before and after #375), `fight.gd`'s timing, Godot 4.7's
`main/main.cpp` (`Main::iteration`), `servers/physics_3d/physics_server_3d_wrap_mt.{h,cpp}`,
`servers/server_wrap_mt_common.h` and `modules/jolt_physics/jolt_physics_server_3d.cpp`.

### What the first plan got right and wrong

1. **Right: the target.** Four to eight cores, a main thread that still fits one, a few helpers.
2. **Wrong: what the per-person cost *is*.** The plan reads the people's 10 ms as arithmetic
   to spread (wound and bleed ticks, aim and sway, visibility scores, the pose solve), and I
   first read it as physics queries. Measured with sub-timers (`results/2026-10-25_threading/probe.md`),
   it is neither, mostly: of the people's ~10 ms, the pure parts a thread could take without
   touching the scene (physiology 0.16, the gun hand 0.25, the pose maths before its writes,
   together ~1.5 ms) are small; the rays are ~106 a frame, 1.2–1.5 ms (cover 48, senses 45,
   walking 13); and the bulk is **GDScript doing per-joint and per-part work on the scene every
   tick**: `_apply_pose`'s 17 pivot sets a man with the maths round them (1.7 ms), the step's
   re-reads of every part's `global_transform` for velocities and the rest (1.7 ms), the
   brains' own logic (1.6 ms), and `_pose_fingers`' 45 bones a man with string tests per bone
   per frame (1.0 of the skeleton's 1.4 ms). Godot's space state is **main-thread only** (the
   wrapper's `space_get_direct_state` fails off the main thread, threaded physics or not), so a
   brain on a worker couldn't cast its rays anyway. **So the first win is single-core and cheap:
   stop re-reading and re-stringing (step 2); then the rays batched and native (step 3); then
   threads for the pose maths and the pure parts (step 4), which are worth a millisecond or so
   at most on this box.**
3. **Wrong: why the seeds diverged with physics on its own thread.** Not "physics read a frame
   behind" as a bug to fix, and not a race. Two definite things, both in Godot's source (next
   section): outside the physics window the space state is *null* (the player's shot, fired from
   `_process`, never happens), and inside it every query sees the world as it stood at the end of
   the last step, whoever moved what this tick. The second is systematic and still deterministic;
   it is in fact the rule the parallel design needs. The first is a bug class we have today in
   latent form (queries from `_process`, deferred calls and signal handlers) that a rule and a
   guard remove.
4. **Right but unmeasurable here: drawing on its own thread.** The RenderingServer's "Multi-Threaded"
   model is the cheapest big win for Sean if it holds (3–6 ms of render CPU off the main thread);
   lavapipe can't judge it and it is marked experimental. Behind a setting; Sean measures with F3.
5. **Missing: the order.** The plan's steps 1–4 were a list, not an order with a reason. The order
   below is by gain per risk, with the determinism ground laid first because every later step's
   test stands on it.
6. **Missing: what already breaks determinism.** Wall-clock budgets (`settle(budget_ms)`,
   `SETTLE_FRAME_MS` in `_check_loads`, both from #375) make a collapse's timing depend on the
   machine; the global RNG is drawn in per-person code (`HumanBody.shoot_off`, `WoundSigns`'
   mouth, spit and drips); the lab's own bot taps keys that the gun reads in `_process`. None of
   these is a threading problem, all of them would be blamed on threading the first time a run
   differed. Step 1 takes them.

### How Godot threads, and what it allows (4.7.2, from its source)

- **The frame** (`Main::iteration`): for each physics step: `_physics_frames++`, 3D `sync()`,
  `flush_queries()` (the rigid bodies' state callbacks), the scene's `_physics_process` (the
  **physics window**), `end_sync()`, `step()`; then `message_queue->flush()` (deferred calls run
  *here*, outside the window); then the scene's `_process`, and the draw. With `--fixed-fps 60`
  (the lab, the tests) that is one physics step a frame.
- **Physics on its own thread** (`PhysicsServer3DWrapMT` with `create_thread`): every write
  (`body_set_state`, `body_apply_impulse`, shapes, spaces: the `FUNC` macros) is **queued** to
  the physics thread; `space_get_direct_state` is a direct call that fails off the main thread
  and, on it, returns null outside the window (`JoltPhysicsServer3D::space_get_direct_state`:
  `(on_separate_thread && !doing_sync) || space->is_stepping()`); the queue's pump thread
  **holds the queue while the window is open** (`_thread_loop`: `if (!doing_sync) flush_all()`).
  **Corrected in step 6** (`results/2026-10-27_step6/race.md`): the wrapper queues a call only when
  `!(doing_sync && Thread::is_main_thread())` (`ASYNC_COND_PUSH`), so in the window the main
  thread's writes and queries go straight to Jolt, as without the thread: a query sees what ticked
  before it in tree order, either way, and the thread on and off play the same fights event for
  event. Outside the window writes are queued and value getters wait for the queue (after the
  step); `body_test_motion` and calls on a space state held from before go straight to Jolt
  against a racy `is_stepping()` flag (the one class that races). The step itself overlaps the
  idle frame and the draw: that is the thread's gain (measured in step 6).
- **`WorkerThreadPool`** runs GDScript callables on worker threads (`add_group_task` for one
  callable over N elements). Nothing of the scene may be touched from them (Node, Node3D, the
  servers' main-thread calls), and no physics query (see above). Pure data in, pure data out.
  Jolt's own solver jobs already run on this pool (`JoltJobSystem`), so on 4 cores a worker phase
  of ours competes with the step only if we run both at once; we don't (ours runs in the window,
  the step after it).
- **Process thread groups** (`Node.process_thread_group`) are the engine's own way to tick a
  subtree on a worker, with the same limits (no scene access outside the group, no physics
  queries, signals into the main group unsafe). Our people emit events and cast rays every tick,
  so this fits none of them whole; it isn't used below.
- **The Rust plugin** (`addons/saltcreek_native`): `pool.rs` is 1–4 long-lived threads taking
  jobs that hold no Godot objects and leave results for the main thread to poll (the voxel work
  uses it). A batch of rays against our own geometry fits it exactly, with rayon if the batch is
  big enough to split.

### Physics on its own thread: exactly why the seeds changed, and the rule

Found by reading, confirmed by the paired runs in `results/2026-10-25_threading/` (the same three
seeds, D, the careful player, `spec_hall`, each configuration run twice):

- **The player's shot vanishes.** `RevolverViewmodel._process` -> `_read_controls` ->
  `pull_trigger` -> `fired` -> `_on_fired` -> `_shot_line`, which casts two rays. Under the
  threaded server `direct_space_state` is null there ("Space state is inaccessible right now",
  then "Cannot call method 'intersect_ray' on a null value"), `_shot_line` returns null,
  `_on_fired` aborts before `ballistics.fire`: no ball, no smoke, no `shot_fired`, no noise. The
  men fight a player who never hits anyone, so two of the ten fights ended "you dead". The same
  path for the coach gun. The lab's bot taps the key and the gun reads it in `_process`, so the
  bot is the player here.
  Measured (`results/2026-10-25_threading/phys_errors.txt`): in three fights the player pulled
  the trigger nine times and fired nothing; every fight diverged at its first "you fired", the
  careful player went down in all three (he'd fled one and won two exchanges in the baseline);
  the frame fell 22.5 -> 18.9 ms, but the fights aren't the same fights, so that number is a
  ceiling, not the gain.
- **`Fittings.collect` at the town's start** asks for the space state before the first physics
  tick (three errors, one a game): under the thread nothing is collected, so the wall props hung
  on nails aren't known to the fittings at all. The same class of bug as the shot, found only
  because the paired runs were looked at.
- **And it is not quite deterministic under the thread.** The same three seeds run twice with
  the thread on (`same_fight.txt`): two fights the same event for event, the third (seed 2) the
  same for 116 events and 48.9 s, then after an identical chest hit the player blacked out in
  one run (the fight over at 49.5 s) and not in the other (on to 58.3 s). The game as it is was
  the same 3 of 3 (and the lab has always been). So besides the systematic shift there is a
  rare race on the player's wound path. Not found this session; the suspects, for step 5, in
  order: the Jolt step's jobs on the same `WorkerThreadPool` as the server's pump task (Jolt
  documents determinism regardless of thread count; whether Godot's job system keeps it with the
  pump task occupying a thread is the first check: `threading/worker_pool/max_threads=1`), the
  one wall-clock read left in gameplay code (`Structure._rebuild_dirty_batches`'
  `BATCH_REBUILD_GAP` by `Time.get_ticks_msec`, if a realised member's body differs from its
  batched one), and the global RNG's remaining users (`Blood.splat`, `ImpactEffects`,
  `GlassProp`) if any draws on a different tick under the thread. The method: seed 2 ten times
  with the thread on, then with each suspect removed, until the ten agree.
- **Part of the thread's gain is the writes, not the step.** With the server threaded every
  `body_set_state` is a queue push instead of Jolt's position-and-broadphase update inline, so
  `people_body` itself fell 4.4 -> 3.7 ms (its 17 part transforms a man a tick are physics
  writes). Which says the writes are worth measuring on their own in step 1 (`q_writes`).
- **Every other query outside the window errors too** and silently changes what follows:
  `GameAudio.gunshot`'s room and wall rays when the player fires; `Senses._on_noise`'s wall ray
  for every listener of a `_process`-time noise (the player's footsteps are emitted from
  `Player._physics_process`, fine; his shot isn't); `GunSmoke._is_indoors` from the player's
  shot; `HumanBody.go_limp.call_deferred` (`_snap_to_ground` finds the ground gone) -> `go_limp`
  -> `_on_ground`'s ray, now deferred to after the step; the dev bridge's commands (a `_process`
  loop: `gf_fight`'s cover search for the men's starting spots, `goto`, `moment`), and tests that
  query from `_ready` or an `await`.
- **Everything inside the window reads the last step** (*not so, step 6: in the window the
  thread changes nothing; see "How Godot threads"*). Men's parts (`AnimatableBody3D`, moved by
  script in `_apply_pose`), the player's capsule, the blocker capsules, rubble: a ray in tick N
  meets them where the step N-1 left them. A ball at 250 m/s moves 4 m a tick; a man at most
  5 cm. This is not a ball through a man: it's the same 60 Hz tolerance the ragdoll, the
  blast and every contact already live with, and it is the *same* for everyone, whereas today a
  brain that ticks after a man sees him moved and one that ticks before doesn't.
- **The rule, from here on (step 1):** physics is queried only in the physics window, and
  whatever a query sees is the world at the end of the last step. Input and the bridge post
  intent; the tick acts on it. A debug guard makes a query outside the window a loud error
  (`World.space()` in place of `get_world_3d().direct_space_state`, asserting
  `Engine.is_in_physics_frame()`), so the next `_process`-time query is caught in the tests, not
  in a fight.
- **Balls never through men:** `Ballistics` stays on Jolt, in the window, flown as now (a ray
  per tick per ball plus one per hit, few of them). What changes is that the men's capsules it
  meets are the last step's, consistently. The check is the body lab's and gunfight lab's: a
  ball's hit on a man is recorded with the segment; `same_fight.py` holds the hits; and a new
  line in the lab's `unfair` watch flags a ball whose path crosses a man's chest capsule (the
  snapshot's) without a hit.

### The per-person work: what each reads and writes

Per physics tick, in tree order today (each `HumanBody` with its `Senses`, brain and face as
children; the player; `Ballistics`; the structures; `FireSystem`). "Pure" = reads and writes
only its own data, no scene, no physics, no signals.

| System (Prof name) | Reads | Writes | Pure part | Physics queries a tick |
|---|---|---|---|---|
| `Physiology.step` (in `people_body`) | own | own (`alive`, bleeds, pain, oxygen, shock) | **all of it**; `roll_rng` is its own | 0 |
| `WoundSigns.step` (in `people_body`) | own physiology, the head's position | decals, particles, a tooth (scene) | the decisions (what to show, when) | 1 ray per smear (`_touching`) |
| `HumanBody._apply_pose` (in `people_body`) | pose, flinches, injuries, clips, breath | **17 pivot rotations** (each a Node3D set -> the part's `body_set_state`) | the goals, blends, springs: all the maths | 0 (the rig's `_place_rig`: 0) |
| `HumanBody.walk_to` / `_slide` / `_snap_to_ground` (called by the brain) | physics | `global_position` (the whole man) | none | 1–3 `cast_motion` + 0–2 `get_rest_info` + 5 ground rays, per walking man |
| `HumanBody` limp (ragdoll) | the parts' `RigidBody3D` state | impulses, tone, braces | the tone maths | `_on_ground`, impacts |
| `_update_skeleton` (`people_skeleton`, in `_process`) | 17 parts' `global_transform` + fingers | `Skeleton3D.set_bone_pose` x ~30 | the matrix products, given the pivot chain | 0 |
| `Senses._look` (`senses`, every 0.12 s a man) | every person's head/chest/pelvis position, the player's camera, `SightLight`, the day | `known` (own) | the cone, range and speed maths | ~3 rays per visible candidate (~20–35 a look) |
| `SightLight` (per man seen, cached) | lamps, the sky | its cache | the lux maths | sky rays + 1 per lamp in range, re-cast when he's moved 0.5 m or 1 s passed |
| `OutlawBrain._physics_step` (`outlaw_brain`) | own senses, target, crew mates' brains (`Crew.brain_of`), relations, the town's ways | own state; `body.face`, `set_pose`, `walk_to`, `draw_gun`, `fire_at`; **events** (`shot_fired`, `callout`, `spoke`, `deed`) | fear, nerve, timers, `relations.tick`, `GunHand.step` | `_clear` 1–3, `_friend_in_the_way` 1, `_aim_point` 2, **cover search 40 candidates x (1 ground + 1 shape + 3–12 rays + a route)**, hunt/flee routes |
| `CivilianBrain` (`civilian_brain`) | fire, people, chores | pose, walks, chores | timers | its looks for fire; chores' rays |
| `GunHand.step` | the wanted direction, stress | own | **all of it** | 0 |
| `Ballistics` (`ballistics`) | the world | men (`take_bullet`), members (carve), events | the flight maths | 1 ray per ball per tick + 1 per hit |
| `FaceLife`, `FaceSpeech`, `FaceGaze` | own, the body | blend shapes | the timing | 0 |

What follows from the table:

- **The pure column is small in time** (physiology 0.16, the gun hand 0.25, the senses' cone
  maths, the pose maths: ~1.5 ms a tick for twelve people here; `probe.md`), **the query
  column is ~1.3 ms** (106 rays a frame; the cover search bursts to ~120 a tick while a man
  searches), and **the scene column is the biggest**: the pivot sets, the part re-reads, the
  bone sets, each a GDScript loop over 17–45 things a man a tick. Threads for the pure column
  save a millisecond at best; a native batch for the queries one more; thinning the scene
  loops two or three, single-core.
- **The writes are the main thread's and stay there:** 17 pivot sets a man a tick, each a scene
  transform change that becomes a physics write. Fewer or cheaper is possible (set the part
  bodies' transforms straight from the computed chain instead of through the pivot nodes, so one
  write a part and no re-reads), but they can't move off the thread.
- **The brains' reads of each other** (`Crew.brain_of(m).mood`, `rescuing`, `relations`) and
  their events make them a sequential system by nature. Run in person order on the main thread,
  they are deterministic; run side by side they'd need every cross-read snapshotted. Not worth
  it: the brains' own arithmetic is cheap once their rays are batched.

### The design

**A. The query rule and the sight service.** One rule (above) and one new part:
`SightWorld` in the Rust plugin, a BVH over the standing members' boxes (every `StructureMember`
is a box; the batches' members, the kit props' members, the ground's slabs and the dug tiles'
height field) plus the people's capsules (the anatomy's, per man, posed from the tick's snapshot
of his parts) and the player's capsule. It answers **a batch of rays in one call**
(`PackedVector3Array` from/to pairs, a mask, an exclude list -> hit distances, hit kinds), split
across its threads for a batch over a few hundred. It is kept up to date by events (a member
broken, cut, burnt away, added; a prop moved) and by the snapshot (the people's parts, each
tick). It is **sight only**: what a man can see, what hides him, which lamp reaches him. Balls,
feet and falling bodies keep asking Jolt, which stays the truth for what touches what.
Determinism: pure geometry over a snapshot, the same answer whatever thread answers it.
Fidelity: Jolt's shapes for members are the same boxes (carved members are voxel meshes: a hole
you can see through is a hole in Jolt and a solid box in SightWorld; `solid_runs` could feed
the holes in later if the perception lab wants it), so a sight line differs only where a carved
hole is on the line. The acceptance test casts the lab's sight lines both ways and counts the
disagreements.

**B. The people's tick, in phases, from one place.** A `PeopleTick` node (in `src/people/`,
ticked once a physics frame before the people, `process_physics_priority`) owns the order; the
people's own `_physics_process` turns off and `PeopleTick` calls them in **person order** (a
fixed index given when a man enters the world, saved with him). Phases:

1. *Snapshot* (main): every person's 17 part transforms, chest velocity, pose, consciousness;
   the player's capsule and camera; the lamps lit; into packed arrays (one allocation a tick,
   reused).
2. *Workers* (`WorkerThreadPool.add_group_task` over the people, or `pool.rs`): per person, pure
   on the snapshot and his own data: `Physiology.step`; `WoundSigns`' decisions; `_apply_pose`'s
   maths (the pose goals, the lerps, the flinch springs, the breath, the injury and favour leans;
   out: 17 Euler triples, or the part transforms themselves through the known pivot chain, and
   the bone poses for the skeleton); `GunHand.step`; `Senses`' pre-pass (which candidates are in
   the cone and in range, the points to test; out: the rays it wants). Each writes only its own
   slot. The per-person RNGs stay per person, drawn in the same order as today (they're drawn by
   the same code, moved whole).
3. *Rays* (main issues, SightWorld answers in its threads): the senses' lines, the lamps' lines,
   the brains' pending cover searches and clears, all in one batch.
4. *Apply* (main, person order): the pivots set (or the parts' transforms), the skeleton's bone
   poses, the signs drawn; then the brains run, in person order, reading the ray answers and the
   senses' results, walking (`walk_to` on Jolt), shooting, emitting their events; then
   `Ballistics` flies.

Phase 2's handoff back is the end of the group task (`wait_for_group_task_completion`): the
main thread blocks there, so a phase that is cheaper than its threads' wake-up is a loss; the
measure is phase 2's wall time against its single-thread sum, per step.

**C. The physics thread, behind a setting,** once A's rule holds (the guard clean through the
tests, the lab, the soak). Expected the measured 2.7 ms here (~1.8 at Sean's). The lab is
re-baselined on purpose when it goes in: the fights are deterministic under it (the paired runs
show it) but different from today's, because every brain now sees the last step.

**D. The render thread model, behind a setting,** for Sean to measure. The screenshot and golden
tools keep the single-threaded model (they read the viewport's texture and await
`frame_post_draw`; the twelve files that call `RenderingServer` directly are checked one by one
for a draw-thread assumption first).

**E. The structures and the fire.** `StructuralAnalysis` is pure over the members' data and
after #375 incremental; it can run on a worker over a snapshot of the dirty set's members
(weight, `extra_load`, `supported_by`, support points, transform, size, kind, wood, holes'
`section_left`) with `apply_round` on the main thread, under the same dirty contract (anything
that changes a member's weight, strength, load or supports calls `mark_dirty`; nothing else may
change between the snapshot and the apply, which is one tick). The fire's member tick (`_visit`:
heat, char, neighbours) is the same shape: pure over the grid and the members' temperatures,
with ignition and consumption applied on the main thread; it's the one that goes native first
(CLAUDE.md's performance part B). The ground tile's mesh and shape (dig-ground step 5) are
already headed native. None of these is the gunfight's problem; they're the fire scene's and
the blast's, and the hitches there (step 5) are single-core work that comes before them.

**F. The determinism rule for every step:** the same seeds run twice on the new build are the
same fight (`same_fight.py`, exit 0); a step that changes the fight on purpose (C) re-baselines
and says why; every RNG is a person's or a system's, seeded from the fight's seed; no wall-clock
budget decides what happens in a tick when `--fixed-fps` or the lab's `deterministic` flag is
set (budgets by count then); worker results are applied in person order; nothing reads
`Time.get_ticks_*` for anything but `Prof`.

### The budget table, re-stated for several cores (to fill in as the steps land)

| Thread | Budget at Sean's | What runs there |
|---|---|---|
| Main | 14 ms, as now | input, the player, the people's apply and brains, ballistics, structures' apply, scene changes, the RenderingServer's submit (until D) |
| Physics (C) | the step overlaps the draw | Jolt's step, its own jobs on the pool |
| Workers (B, E) | phase 2 ≤ 1.5 ms wall | physiology, pose maths, gun hands, senses' pre-pass; the analysis; the fire's tick |
| SightWorld (A) | ≤ 1 ms wall for a tick's batch | every sight line |
| Render (D) | Sean's F3 | the draw |

## The steps, in order, each a next-session prompt

Each step: a `claude/gameplay-perf-…` branch from main; measured before and after with the same
lab command, one game at a time (`python3 experiments/gunfight_lab/run.py --scenarios=spec_hall
--hours=golden --weapons=revolver --styles=careful --bodies=studio --variant=D --seeds=1-10
--jobs=1 --out=build/…`), the `perf` numbers summarised into a results folder; **run twice and
compared with `same_fight.py`**; the tests green; a status entry; the next step's issue. Expected
gains are this core's ms a frame in a D gunfight (x0.65 for Sean's), against main today's 20.0
(`results/2026-10-25_threading/probe.md`). Steps 1–4 are the gunfight's; 4b the finished map's
(people ticked by distance, Sean's ask); 5 the fire scene's; 6–8 the engine's threads and the
structures; 9 the table. **Sean, 2026-10-25 (#378): the order as written.** Step 1 was issue #380 (PR #384); step 2 is
#385. **Every later step has its issue already** (Sean, 2026-10-25: each step must know exactly what
it's to do), each a complete prompt with its gate and handover: step 3 #394, step 4 #395, step 4b
#396, step 5 #397, step 6 #398, step 7 #399, step 8 #400, step 9 #401. A step's session doesn't open
the next issue: it labels the next step's issue `next session` when its PR merges and closes its own.

**Step 1. The determinism ground** (no gain in ms; a small session). *"Read docs/briefs/more-cores.md
'The review' and 'The design' A and F. Make the query rule real: a `World.space(node)` helper
that returns the direct space state and, in debug builds, pushes an error with the caller when
`Engine.is_in_physics_frame()` is false; replace every `get_world_3d().direct_space_state` and
`find_world_3d().direct_space_state` in src/, tools/ and experiments/ with it (a mechanical
change; the tests show the sites that fire). Move the player's shot into the physics window:
`_read_controls` records the trigger pull and `WeaponViewmodel._physics_process` fires it (the
sway and kick read then); the dev bridge's commands that query (goto, moment, the labs' setups)
run inside `await get_tree().physics_frame`; `Fittings.collect` and anything else that
queries at the town's start waits for the first physics frame. Replace the global `randf*` in `HumanBody.shoot_off`
and `WoundSigns` with the man's `_rng`. Give `settle(budget_ms)` and `_check_loads` a
count budget when `Engine.is_in_physics_frame()` and a `deterministic` project setting is on
(the lab and tests set it). Put a counter on every query site under a Prof name
(`q_senses`, `q_cover`, `q_brain`, `q_walk`, `q_balls`, `q_lamps`, `q_signs`) and one on the
people's part transforms set a tick (`q_writes`), so the lab's `per_system_ms` shows rays and
writes a frame as well as ms (`results/2026-10-25_threading/instrument.py` is the temporary
version of this; make it permanent and cheap). Name the untimed share: the named systems sum
to ~13.5 of the frame's ~20 ms here; a `PhysicsWindow` pair of nodes (the first and the last
to tick, by `process_physics_priority`) times the window, so the frame splits into the window
(ours), the step (Jolt's) and the rest (the engine's), and `perf` records all three. Then run
the baseline twice and `same_fight.py` them: 10 of 10 the same is the gate."*
**Done (2026-10-25, `claude/gameplay-perf-step1`; `results/2026-10-25_step1/`):** 10 of 10 the
same (the second run with the tests on the other cores), no ms gained, as expected: 14.6 ms a
frame, the window 10.0 / step 1.1 / rest 3.4; a frame's rays cover 65, senses 46, walking 19,
lamps 4.5, brains 0.4; writes 336. The fights are re-baselined (the shot leaves on the tick after
the trigger's read; 0 of 10 match main's). The chaos flake was two things: #375's clock budgets
and GlassProp's global `randf()`. Under `World.deterministic` the plugin's voxel meshes and the
smoke field land on fixed frames too.

**Step 2. The per-person tick made cheap, single-core** (expected −2.5 to −3 ms:
`people_skeleton` 1.4 -> ~0.5, `people_body` 4.4 -> ~2.5). *"Read `results/2026-10-25_threading/probe.md`.
Three things, each measured on its own with the lab's `perf` and the physics lab's falls held
the same: (a) `_pose_fingers` does `String(e.fid).begins_with/ends_with` and a Dictionary walk
for 45 bones a man every frame: precompute per entry (thumb or not, side sign, the rest and
gain) once in `_add_finger_bones`, and set the finger bones only when a finger node's bend
changed; (b) `_track_carry` reads 17 parts' `global_transform` a man a tick to get velocities
the engine can't give for script-moved parts: keep the transforms `_apply_pose` just set (it
knows the pivot chain) instead of re-reading them, and skip the whole loop for a man standing
still whose pose didn't change; (c) `_apply_pose` sets 17 pivot `rotation_degrees` a man a
tick, each a transform-changed notification down the subtree into the part body's
`body_set_state`: set only the pivots whose rotation moved more than a hundredth of a degree
(a man standing easy moves only his chest), and measure how much of `hb_pose` was the sets
(`q_writes` from step 1). (d) **The per-shot hitch** (Sean's F3, build 2466, on #385: while shooting in the
spec saloon the worst physics step is 190–250 ms with `batches` 3.5 ms a frame on average):
a ball into a batched member calls `Structure.unbatch` -> `_rebuild_dirty_batches` ->
`_build_batch`, which rebuilds that material's whole batch mesh for the building on the physics
frame. Measure one shot into the hall's wall with per-step timers (not the average); if
`_build_batch` is the step, split the batches into cells (as `PropBatch` does, ~20 m) so a hit
rebuilds a few metres, and build the cell's mesh off the frame if it's still long. This is the
hitch Sean feels on every shot, so it comes first in this step. Then `_update_skeleton` runs on the physics tick after the pose, from
the same transforms, and `_process` does nothing. Ten fights twice, `same_fight.py` the same;
the body lab's and physics lab's goldens the same."*
**Done (2026-10-25, `claude/gameplay-perf-step2`; `results/2026-10-25_step2/`):** 10 of 10 the
same; **about -1.3 ms a frame against the before** (16.3 -> 14.95, p95 20.6 -> 18.7; people
9.3 -> 8.2; two runs of one build spread 0.7 here, so the total is soft): `people_skeleton` 1.12 ->
0.48 as expected, `people_body` 3.65 -> ~3.3, not ~2.5. The pivot sets
weren't its cost (336 -> 60 a frame moved nothing): what's left is GDScript a joint (the pose loop
1.1, its tail 0.5) and the transform reads (0.46, the sets' composition lands there). (c) within
0.01 degree turned 19 of the physics lab's 151 falls, so a pivot is skipped only when exactly as
last set (75 sets a frame); the falls are the before's. Finger bones parented in
the skeleton (set only when the finger bends). The gate found the player's packing roll unseeded
(`Physiology.roll_rng`) and the body lab `WoundSigns`' phase taken from his instance id (which
any new object moves): both by seed now, with the viewmodels' dice. **The per-shot hitch**
(`results/2026-10-25_step2/shot.md`, the blast-freeze lab's `bf_shot`): `_build_batch` was 15-23
ms of each shot's frame (a material's mesh for the whole saloon, up to 683 members); batched in
pieces of at most 64 near members it's 1-3 ms, the shot's worst frame 42-58 -> 26-37 ms here (the
saloon 62 -> 115 batches, the street 733 -> 736). Left: the holed member's load check
(`fire_loads` 14-20 ms on the shot's frame) and the townsfolk's `civilian_brain` burst a second
later (~100 ms on one frame), both step 5's.

**Step 3. The sight service** (expected −1 ms on average and the cover search's bursts gone:
`senses` 1.2 -> ~0.6, the brains' `ob_cover_search` 0.5 -> ~0.1, `q_walk`'s ground rays
stay on Jolt). *"Read 'The design' A. In `addons/saltcreek_native`, add `SightWorld`: boxes
with an id, a kind and a layer (members, props, ground slabs, dug tiles), capsules per person
(the anatomy's hitboxes posed from part transforms given each tick), a BVH rebuilt when boxes
change and refitted for the capsules each tick, and `cast(from: PackedVector3Array, to:
PackedVector3Array, mask: int, exclude: PackedInt32Array) -> PackedFloat32Array` (the hit
fraction per ray, 1.0 for none, with the hit id in a second array), split across `pool.rs`
threads above 200 rays. A GDScript face `Sight` (src/people/sight.gd): `Sight.lines(pairs)`
for a batch, `Sight.clear(from, to, exclude)` for one. Feed it: every StructureMember on
enter/exit (and `member_broken`, `member_cut`, burnt away), kit props when they move, the
people from PeopleTick's snapshot (step 4; until then from each HumanBody's own tick). Move
`Cover` first (its `_blocked`, `_sees`, `hidden_at`, `_ground`, `_shadows`; `_room` and
`path_clear` stay on Jolt until the capsules are in), then `Senses._clear`, `SightLight`'s lamp
and sky lines, `OutlawBrain._clear` and `_aim_point`. Test: `tests/test_sight_world.gd` casts
the lab's sight lines through both and counts disagreements (the gate: none on an unbroken
saloon; on a shot-up one, only where a carved hole lies on the line, listed). The lab twice;
the perception lab's score unchanged; the cover spots of `gf_coverwhy` the same on ten seeds."*
**Done (2026-10-26, `claude/gameplay-perf-step3`; `results/2026-10-26_step3/`):** 10 of 10 the
same; **no gain** (frame 19.6 -> 20.0 here, within the noise; `senses` 1.27 -> 1.29,
`outlaw_brain` 2.68 -> 2.65; Sight's upkeep `sight_sync` +0.05). The lines were never the cost: a
D fight asks ~115 sight lines a frame, ~0.4 ms under Jolt (3.6 us a line from GDScript); one at a
time Sight is 2.8-3.0 us, in a batch 0.7 us, so the gain waits for step 4's one batch a tick. SightWorld takes every
body on the world and walk layers from the physics server (boxes, capsules, carved members' and
dug tiles' triangles, a carve's hole exactly, not a box), fed by the tree; on the spec saloon's
31,248 lines it agrees with Jolt but for 15 laid along a face (`tests/test_sight_world.gd`). The
people's capsules are left for step 4 (no line moved here asks `BODY_PARTS`). Against main the
fights re-baseline (0 of 10: hit points round differently in the last bits and Cover snaps spots
to 20 cm); the perception lab 88 -> 88, `gf_coverwhy` 10 of 10 the same.

**Step 4. The people's tick in phases, the pure parts on workers** (expected −0.5 to −1 ms
here, more on 6–8 cores: the pose maths, physiology and the gun hands off the main thread; the
order made explicit). *"Read 'The design' B. Add `PeopleTick` (src/people/people_tick.gd) and
give every person a `tick_index`. Turn the people's `_physics_process` off and call their steps
from PeopleTick in index order; first with no threads at all, the lab twice, `same_fight.py`
the same: that is the order made explicit. Then split `HumanBody._physics_step` into
`prepare(snapshot)` (pure: physiology, the signs' decisions, the pose maths into a `PoseOut`
with the 17 rotations and the bone poses, the gun hand) and `apply(out)` (the pivot sets, the
skeleton, the signs), and run `prepare` over the people with
`WorkerThreadPool.add_group_task`. Measure phase 2's wall time against its single-thread sum
(the lab's `perf`): if the threads don't pay on this 4-core box, say so, keep the phases
single-threaded, and leave the group task behind a setting for Sean's cores. The lab twice;
the physics lab's falls and the body lab's wounds the same."*
**Done (2026-10-26, `claude/gameplay-perf-step4`; `results/2026-10-26_step4/`):** both commits
**10 of 10 the same twice, and every fight's record event for event main's** (threads on or
off too); the street's townsfolk, who now tick after the player and the saloon's props, walk and
look a few lines differently (`q_walk` +2-3 % in the long fights); the physics lab's 151 falls
and the body lab's 216 records the before's. `PeopleTick` is an internal child of the last man in
(a node before the first moved the fight's men ahead of the player, and seed 1 parted at 0.97 s).
The phases: `begin_prepare` (main), `prepare` on the pool (physiology, favouring, `_pose_maths`
into `_rots`), each man's tick applying it (`_pose_writes`, the rig, the skeleton) before his
brain, face and senses. **Phase 2: 1.72 ms of work on one thread, 1.08 ms of the main thread's
time on the pool** (its men's own times sum to 2.1 there: a man's half costs a quarter more on a
worker). Scaled by the untouched systems (this VM drifted ~10% between runs): **the people -0.34
ms against main, the threads ~0.6 against off, the frame -0.1** (the brief expected -0.5 to -1;
the work moved is only ~1.7 ms). Threads stay on (`Settings.people_threads`,
`-- --people-threads=off`). Not moved: the gun hand (it takes the aim the brain picks that tick,
off the gun's muzzle node), the signs' decisions (each followed at once by its decal), the people's
capsules in SightWorld (no line asks `BODY_PARTS` through Sight yet). **Phase 3 measured, not
built:** `Senses`' 46 lines a frame cost 0.47 ms here one at a time (Jolt 0.62), so one batch
could save ~0.4; it means every man looks from the tick's snapshot, a change to the fights, so
it's a step of its own (#396's handover carries it for the review to place).

**Step 4b. People ticked by distance** (Sean, 2026-10-25, for the finished map: no gain in the
saloon fight, where everyone is near; on a full town with 30 townsfolk two streets off at a
quarter rate, roughly half a millisecond a man at Sean's, so ~10 ms). *"Read 'The design' B and
CLAUDE.md's rule that performance never fakes the game. In `PeopleTick`, give every person a
tick band from his distance to the player and to any fight he's in (near: every tick; middle,
past ~25 m: every 2nd; far, past ~60 m and out of any fight: every 4th), with hysteresis of a
few metres so a man on a line doesn't flicker between bands, and the band chosen by distance
only (game state), never by frame time, so a seeded fight stays the same. What the band slows:
`Senses._look`, `_apply_pose` and the skeleton copy, `FaceLife`, `WoundSigns`, a calm brain's
`_physics_step`; each steps with the delta it accumulated, so a far man walks at the right
speed and his wounds bleed at the right rate. What never slows: hearing (`Events.noise` is a
signal, not a tick), a brain that is fighting, fleeing, tending or rescuing, anyone the player
is talking to or aiming at, the ragdoll (physics is the engine's), and anyone the camera can
see within the near band (what the player sees ticks fully, by the rule). Test: a townsman
walking his route two streets off arrives at the same places at the same times with bands on
and off (`test_town_day`); the gunfight lab twice; and `perf_bench`'s calm street with the town
doubled (`--folk=2`, new) shows the people's share flat where it was linear."*
**Done (2026-10-26, `claude/gameplay-perf-step4b`; `results/2026-10-26_step4b/`):** the bands
in `PeopleTick` (`config/people_tick.tres`): 25 / 60 m from the player and from everyone
`in_trouble`, a 3 m margin, staggered by index; in the camera's view one band nearer, near its
middle every tick. A man skipped is skipped in every phase and owed the time (`tick_owed`, his
`tick_dt`). Never slowed: `HumanBody.can_slow` false (down, getting up, stumbling, dragged, a clip,
a brain not calm, a chore in hand) or woken (a noise, a deed to him); no player in the world (the
physics and body labs) means no bands. Two places that took a delta but not a long one: `walk_to`
(a slowed step stops where one-tick steps would and carries the ticks left, `_walk_spare`) and
`Senses`' 0.12 s clock (a far man's look interval times his band). **The lab: 10 of 10 the same
twice; against step 4, 9 of 10 event for event** (seed 5 parts 74 % in, through `SightLight`'s
cache, renewed by whoever asks first: the townsfolk looking less often moves it; left for 4c).
**Gain: the lab's frame -4.5 ms here, the people -3.9** (the brief expected none: the street's
townsfolk outside the saloon are far from you; half the people tick each frame). `perf_bench
--folk=2`: the town doubled adds +5.1 ms of people with the bands off, +1.8 with them on (a far man
~0.11 ms instead of ~0.32 here): a third of the slope, not flat. The gang walking in two streets
off reaches the bar 4-6 frames behind in 33 s (`test_town_day`); wounded far men bleed the same.

**Step 5. The fire scene's hitches, single-core** (the burning saloon: frames of 30–130 ms
become frames under 20; no change to the gunfight's average). *"Read `experiments/blast_freeze/README.md`
'What's left' and 'The design' E. Measure each with `bf_blast at=6.0,0.8,6.0 fire=6 burn=20
fuse=1 seconds=8 out=…` (one game at a time) before and after. (a) `civilian_brain` while the
saloon burns, 30–90 ms a frame with 17 townsfolk: `CivilianBrain._mind_fire`/`_look_for_fire`
and the bucket line read the fire's burning members or route to it every tick for every man;
cache the fire's picture once a tick in FireSystem (the burning members' boxes, the nearest to
each place) and have the men read that, their looks staggered as Senses' are; `test_flee_fire`
and `test_bucket_line` hold them. (b) The fire's periodic work: `_rebuild_grid` (only while something's hot since #373; walks all
5,150 members every 2 s, ~40 ms) becomes incremental (standing members placed once, as `_placed`
already means; only rubble and the changed re-placed), the neighbour lists refreshed a few
members a frame instead of all at 30 s, the smoke field's step and upload sliced or halved in
rate. (c) The frame after a stick (~125 ms: ~110 rubble bodies and 44 members taken in one
frame): add the pieces over two or three frames, or cut fewer, larger pieces; they must still
fly from the hole (the breakage lab's goldens). The blast-freeze lab's frames the same twice;
the fire tests and the soak green."*
Sean's F3 on his PC (build 2466, on #376) puts numbers on these: after a stick out front,
`batches` 20–45 ms a frame, `civilian_brain` 42 ms (five cowering), `fire` 9–11 ms, the worst
physics step 55–316 ms in the burning hall; 26 game minutes later and far down the street still a
57 ms step, because the simulation isn't tied to the camera (the fire's members and the
burning building's settle at full detail wherever the player is: (d) members far from the player
tick coarser, with a bigger step, as step 4b does for people). **And the GPU, art's lane:** 56–75 ms
out front and in the burning hall against 5.6 ms in the hall with no fire, at fewer triangles:
about 3,200 extra draws, most likely shadow passes from the fire's lights (the lamp-shadow trap
of 2026-10-13 with fire lights that flicker or move), plus the flipbook flames' and smoke's
overdraw in a closed room, and 35 ms still far down the street (the embers' and fires' light
ranges not culled). An art session measures `FireFX`'s lights (count, shadows, movement) on a
real GPU or from Sean's F3 before the fight starts. The stopgap `max_physics_steps_per_frame=2`
(#386) was reverted the same day (#393, issue #392): under it the game hangs at quit, in Godot's
worker pool exit handshake (two low-priority pool tasks overlapping at the runlevel switch leave
the idle workers uncounted for good; the engine's own tasks can form the pair), and the cap makes
the whole game crawl on a slow frame so its work is still in flight at quit. A stopgap only comes
back with a quit that can't hang; and every pool task this repo posts is high priority.
**Done (2026-10-27, `claude/gameplay-perf-step5`; `experiments/blast_freeze/results/2026-10-27_step5/`):**
(a) `fire_near` reads the fire's picture (the burning members' boxes, once a frame), not the grid:
`civilian_brain` 9.8 → 0.4 ms a frame. (b) The grid kept up by what changed (members added at a
structure's end, `Events.member_broken`), placed in the full walk's order (the fire the same frame
for frame); the smoke's vents worked out when a member first smokes, its member list kept;
neighbour refreshes spread by id; the load check's slices sized to what a member costs here
(~60-100 µs, not 30: `bf_analyse`; slices 50/40, `MEMBERS_A_MS` 15). (c) Measured: the stick's
frame adds ~660 bodies, ~500 of them glass shards; without the cut pieces or without the shards
the frame barely changes, so neither spreading nor bigger pieces was done (the rest is Jolt's,
step 6's), as is Jolt's ~8 ms a frame with ~200 pieces kept awake through a collapse (a narrower
wake was tried and not kept: it changed where debris rests); a noise out of earshot casts no ray
(985 → 166 rays on the stick's frame). (d) `FireSystem.bands`:
past 30 / 60 m from the player a structure's members tick every 2nd / 4th fire tick, given the
time since. **Gain, the burning hall:** before the stick 18.8 → 7.0 ms a frame (frames over 20 ms
51 → 1 of 119), after its first second 32 → 21 (over 50 ms 80 → 5 of 420); the stick's three
frames ~500 ms here, unchanged. The same 306 members broken in every run; the lab twice under
`--deterministic` frame for frame the same.

**Step 6. Physics on its own thread, behind a setting** (expected −2.7 ms here, measured; the
writes' share of it shrinks as step 2 lands). *"Read 'The review' 'Physics on its own thread'.
With steps 1–4 merged, set `physics/3d/run_on_separate_thread` from a `Settings` entry (default
off; the look panel and F-keys don't touch it): the project setting is read at start, so decide
how a setting reaches it (an `override.cfg` the game writes, or the launcher) and document.
First the rare race: seed 2 of `results/2026-10-25_threading/` ten times with the thread on,
then with each suspect in 'The review' removed, until ten agree; what it was goes in the
results. Then run the whole test suite, the soak for an hour and the lab twice under it: zero
'Space state is inaccessible' errors in any log is the gate, and the paired runs the same, every
fight. Then re-baseline the lab's `baseline/` under it with a note of what moved (every brain
now sees the last step). Ask Sean to play a saloon fight with it on and off and read F3."*
**Done (2026-10-27, `claude/gameplay-perf-step6`; `experiments/gunfight_lab/results/2026-10-27_step6/`):**
`Settings.physics_thread` (off) through `user://engine.cfg` (project.godot's
`project_settings_override`; `-- --physics-thread=on|off` for the next start; the lab's
`run.py --physics-thread`). The race: seed 2 ten times 10 of 10 on today's code and on the review's
commit; no suspect left (step 1 removed the wall clock and the dice); what can race in Godot's
threaded server is in `race.md`. The thread on and off play the same fights (10 of 10, and main's),
so `baseline/` didn't move: no re-baseline. Fixed for the thread: the smoke test's events (done in
`_process`), a man into a hole (deferred `go_limp`), two tests, and a crash drawn: Godot's
`SoftBody3D` copies its mesh outside the window and the queued copy writes a closed buffer
(`SoftBodyDraw` draws soft bodies in the tick). **Gain, the gunfight: −0.05 and −0.54 ms a frame
(p95 −0.5)** headless, not −2.7 (the review's fights weren't the same fights, and in the window
nothing is queued); **the stick in the burning hall: −1.6 ms a frame after it, its worst frame −80
to −90 ms**. Drawn, the step overlaps the draw. **Not ready to turn on:** with the thread the full
suite hung in 2 of 5 runs (off: 0 of 4, the same load) and the soak 121 game minutes in, a deadlock inside Godot 4.7.2's threaded
physics server and its worker pool with none of our code running (`results/2026-10-27_step6/hang/`);
the setting stays off and Sean decides whether it's chased upstream or parked.

**Step 7. The render thread model, behind a setting** (expected −3 to −6 ms at Sean's, unknown
here). *"Set `rendering/driver/threads/thread_model` to Multi-Threaded behind a setting; keep
the screenshot, golden, tour and lab tools on the single-threaded model (they read the viewport
texture and await `frame_post_draw`). Check the twelve files that call `RenderingServer`
directly (`grep -rn 'RenderingServer\.' src`) for a same-frame assumption. Give Sean a build
with it on and off (F3's frame, a gunfight in the new saloon, the burning street); it stays on
only if his numbers say so and nothing draws wrong."*

**Step 8. The structures' analysis and the fire's tick off the main thread** (the fire scene's
and the blast's; expected: the burning town's `fire` 2.4 -> ~1.0 and the collapse's rounds off
the frame). *"Read 'The design' E. Snapshot the dirty set's members
into packed arrays and run `StructuralAnalysis.begin_update` + `advance` on a worker (GDScript
on the pool first; native if it pays), `apply_round` on the main thread next tick; the fire's
`_visit` native over the grid. `tests/test_settle_incremental.gd` holds the analysis exact; the
blast-freeze lab's frames and the fire test scenes the same twice."*

**Step 9. The budget table re-stated** (no gain; one short session with Sean's F3 numbers from
steps 6 and 7): CLAUDE.md's table becomes the per-thread one above with measured columns, and
`config/frame_budget.tres` and `perf_bench` learn the main thread's share and the frame's.

## How a step is reviewed (Sean, 2026-10-25: each step's session reviewed by the Fable session)

When a step's session says "Step done" with its PR, the review reads the diff and the step's
results folder and answers these, each a finding on the PR ("fix before merge" or "the next step
carries it"):

1. **The gate held:** the lab's same seeds run twice on the new build and `same_fight.py` says
   10 of 10 the same (the two runs' folders are in the results, not only the verdict). A step
   that changed the fight on purpose (6) re-baselined and says why.
2. **The numbers are the step's:** `perf` before and after with the same command, one game at
   a time, against the expected gain in "The steps"; the worst 5% as well as the mean; the
   counters (`q_*`, `q_writes`) and the frame's split (window, step, rest) reported. A gain
   smaller than expected is fine when it's explained; a number without a before isn't.
3. **Nothing the rule forbids came in:** no `Time.get_ticks_*` deciding what a tick does (count
   budgets under `deterministic`); no global `randf`/`randi` in per-person or per-system code;
   no `direct_space_state` outside the physics window (the guard would say); no scene or
   physics access from a worker (`WorkerThreadPool`, `pool.rs`); worker results applied in
   person order; every RNG a person's or a system's, seeded from the fight's seed.
4. **The game isn't faked** (CLAUDE.md's rule, #377): what the player can see or do ticks and
   draws as before; what's thinned is out of sight or doesn't change the outcome, and the
   tests that hold the outcome (the lab, the physics and body labs' goldens, `test_town_day`)
   are named in the PR as run.
5. **It stops at its step:** no part of the next step folded in, no widening; the next step's
   issue carries the step's own leftovers and the review's "next step carries it" items.
6. **The handover is whole:** the status entry, the Current state lines, the next-session
   issue with the counts or numbers the next step needs, and the brief's step marked done with
   the measured gain in place of the expected one.

## What done looks like

- A D+ gunfight in the new saloon with three men and the town in holds 60 fps on Sean's PC. His F3
  shows the frame, and he plays it.
- The lab reports the main thread's share and the frame's for the same fights, before and after
  each step.
- The budget table in CLAUDE.md is re-stated for several cores: the main thread's budget, and what
  may run beside it.
- The seeded lab fights still come out the same: threading must not change a fight's outcome, so
  the tests hold every system to its seed (`same_fight.py`, twice on every step).

## How it's judged

- The lab's `perf` numbers. Every fight records each system's time and the frame's.
- `tools/perf_bench.gd` for the town scenes.
- Sean's play on his PC. Lavapipe here can't stand in for his GPU.
