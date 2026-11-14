# More cores, step 6: physics on its own thread, behind a setting (2026-10-27)

`docs/briefs/more-cores.md` "Step 6" (issue #398). This workspace's VM (4 vCPUs, ~2.1 GHz; x0.65
for Sean's core), headless, `--fixed-fps 60`, one game at a time and nothing else running for the
timed runs. The lab's ten D fights, the thread off and on, alternating (`off_a`, `thr_a`, `off_b`,
`thr_b`):

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall --hours=golden --weapons=revolver \
    --styles=careful --bodies=studio --variant=D --seeds=1-10 --jobs=1 --physics-thread=on|off --out=build/gf/<run>
python3 experiments/gunfight_lab/same_fight.py build/gf/<a> build/gf/<b>
python3 experiments/gunfight_lab/results/2026-10-27_step6/perf.py off_a=... thr_a=... off_b=... thr_b=...
```

## The setting

`Settings.physics_thread` (off). Godot reads `physics/3d/run_on_separate_thread` only at start, so
the setting is a file Godot reads before any script: project.godot's
`application/config/project_settings_override` points at `user://engine.cfg` (`Settings.ENGINE_PATH`;
`[physics] 3d/run_on_separate_thread=true`). `Settings.set_physics_thread(on)` and
`-- --physics-thread=on|off` write it for the next start; F3's native line says which this run has.
No panel or key. The lab's `run.py --physics-thread=on|off` writes it for its games and puts the file
back; each fight records `physics_thread`. `docs/LAYOUT.md` "src/autoload".

## The gate

- **The rare race:** seed 2 ten times with the thread on, 10 of 10 the same, on today's code and on
  the review's own commit (plus three more there under load). No suspect left to remove: `race.md`
  (what it was, what can race in Godot's threaded server, and a crash the thread brings).
- **The lab twice under it: 10 of 10 the same** (`same_fight_thr_a_vs_thr_b.txt`), and the thread
  off twice 10 of 10 (`same_fight_off_a_vs_off_b.txt`).
- **The thread on and off play the same fights, 10 of 10** (`same_fight_off_a_vs_thr_a.txt`,
  `same_fight_off_b_vs_thr_b.txt`), and this branch with the thread on plays main's fights (main at
  a8dacf1, thread off, its own worktree: `same_fight_main_vs_thr_b.txt`, 10 of 10).
- **Zero "Space state is inaccessible", "Body state is inaccessible", "being stepped" or "a physics
  query outside the physics frame" errors** in the 40 lab logs, the race's logs on today's code,
  the blast runs, every suite run after the fixes, the soak and the smoke test (`gate.md`).
- **The smoke test** under the thread: drawn 5 of 5 and headless 3 of 3, each exited (`gate.md`).
- **The suite under the thread: NOT met. It hung in 2 of 5 full runs** (thread off: 0 of 4, the
  same load): a deadlock inside Godot 4.7.2's threaded physics server and worker pool, with none of
  our code running in it (`hang/README.md`). Otherwise green: every test passes in the runs that
  finish.
- **The soak under the thread: NOT met.** It hung too, 121 game minutes in (~1 h 30), the same
  deadlock; nothing wrong before it (`gate.md`).

**So the setting stays off and isn't ready for Sean's play**: on, the game can freeze. What it
buys is small here (below).

## The re-baseline: nothing moved

The brief expected every brain to see the last step under the thread, so the fights would change
and `baseline/` be re-recorded. They don't change: while the physics window is open, Godot's
threaded server passes the main thread's calls straight through (`ASYNC_COND_PUSH` is
`!(doing_sync && Thread::is_main_thread())`), so in the window a write is immediate and a query
sees it, as without the thread. Since step 1 every query is in the window, so the fights are the
game's own, event for event (above). `baseline/` stays as it is; the brief is corrected
("How Godot threads").

## The numbers (`perf.md`; ms a frame, this core)

| | off_a | thr_a | off_b | thr_b |
|---|---|---|---|---|
| frame (mean / p95) | 13.73 / 16.97 | 13.68 / 16.48 | 12.99 / 16.34 | 12.45 / 15.82 |
| window / step / rest | 8.84 / 1.22 / 3.59 | 9.17 / 0.41 / 4.03 | 8.65 / 1.19 / 3.08 | 8.67 / 0.38 / 3.33 |
| people (mean / p95) | 6.59 / 8.98 | 6.82 / 9.27 | 6.46 / 8.63 | 6.45 / 8.64 |

**Gain in the gunfight: −0.05 and −0.54 ms a frame, p95 −0.49 and −0.52**, against the −2.7
expected. Jolt's step (1.2 ms) leaves the frame; with the thread `step` is only the deferred calls
after the ticks, and a step still running at the next frame's start is waited for in `rest`. Why
less than expected:
- The review's −2.7 was measured on fights that weren't the same fights (the player's shot vanished:
  `results/2026-10-25_threading/`), and part of it was the people's writes turned into queue pushes
  (`people_body` 4.4 -> 3.7). In the window nothing is queued (above), so that part never was the
  thread's; `q_writes` is 64 a frame since step 2 anyway.
- Headless there's no draw: the step has only the idle process (~3 ms) to overlap, and handing it
  over costs a little each frame. In a drawn game the step runs beside the draw: Sean's F3 is the
  measure there.

The counters are the same in all four (`q_cover` 60.4, `q_senses` 19.5, `q_walk` 16.3, `q_writes`
63.9, `q_lamps` 4.3 a frame).

## The stick in the burning saloon (the blast-freeze lab)

Step 5's handover: the stick's frames are physics now. Its hall case, the thread off and on,
alternating (`blast/`: trimmed runs and `summaries.txt`; `bf_blast at=6.0,0.8,6.0 fire=6 burn=20
fuse=1 seconds=8 player=12.0,0.8,2.0`, `XDG_DATA_HOME` pointing each run at its own `engine.cfg`):

| | before the stick, mean / p95 | after its first second, mean / p95, frames > 50 ms | the stick's worst frame |
|---|---|---|---|
| off 1 | 7.3 / 10.8 | 21.8 / 37.9, 5 | 294 |
| on 1 | 6.0 / 9.9 | 20.6 / 38.3, 5 | 199 |
| off 2 | 7.9 / 12.7 | 23.8 / 42.1, 7 | 306 |
| on 2 | 7.7 / 13.6 | 21.7 / 39.4, 4 | 228 |

The same 306 members broken in all four (the same set, by hash). After the stick about −1.6 ms a
frame and its worst frame −80 to −90 ms. Jolt's step with ~200 rubble pieces awake (`step` 7–8 ms
a frame off) mostly moves into `rest` headless: the next frame waits for it. Drawn, it's the draw
it would overlap.

## Also in this step

- **The smoke test's events in the physics frame** (`src/debug/smoke_test.gd`): its stick, fire and
  shot were done from `_process`; under the thread they found no space. From source (a debug build)
  the query guard failed it with the thread off too; CI's release export never ran the guard.
- **A man walking into a hole** went limp `call_deferred`, after the window, where his new parts'
  state can't be read under the thread: now on the next physics tick (`HumanBody._snap_to_ground`).
  `test_ground` passes both ways.
- **Two tests** asked for the space after a process frame (`test_gun_range`,
  `test_props_scale`): each waits for a physics frame first (the checks unchanged).
- **`SoftBodyDraw`**: the crash in `race.md`.
