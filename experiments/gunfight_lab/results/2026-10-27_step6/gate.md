# The gate, run by run (this workspace, 2026-10-27)

"Thread errors" below: "Space state is inaccessible", "Body state is inaccessible", "must not be
called while the physics space is being stepped", and the debug guard's "a physics query outside
the physics frame", counted in every log.

## The lab (headless, `--deterministic`, one game at a time)

| runs | games | thread errors | hung |
|---|---|---|---|
| the ten D fights, thread on, twice (`thr_a`, `thr_b`) | 20 | 0 | 0 |
| the ten D fights, thread off, twice (`off_a`, `off_b`) | 20 | 0 | 0 |
| seed 2, thread on, ten times, today's code (`race/thr_*`) | 10 | 0 | 0 |
| seed 2, thread on, the review's commit, ten + three under load (`race/review_*`) | 13 | 1 a game (its `Fittings.collect`, fixed by step 1) | 0 |
| the blast-freeze hall case, off and on twice (`blast/`) | 4 | 0 | 0 |

`same_fight.py`: `thr_a`/`thr_b` 10 of 10, `off_a`/`off_b` 10 of 10, `off_a`/`thr_a` and
`off_b`/`thr_b` 10 of 10, main (thread off) / `thr_b` 10 of 10; seed 2 ten of ten on each build.

## The smoke test (`smoke.txt`)

- **Drawn** (xvfb, lavapipe, `taskset -c 0,1`, from source), thread on: **5 of 5 ok and exited**
  (`final_1..5`, ~100 s each), after the fixes. Before them: `thr_1` crashed (the soft-body
  crash, `hang/smoke_softbody_crash.txt`); `off_drawn_1` and `on_headless_1` failed on the smoke
  test's own events done from `_process` (from source the debug guard counts them; under the
  thread they found no space).
- **Headless**, thread on: 3 of 3 ok and exited (`final_headless_1..3`).

## The suite (`tests/run_tests.gd`, all 104 files)

| run | thread | result |
|---|---|---|
| 1 (before the fixes) | on | 2 failures, both test code asking for the space after a process frame (fixed: `test_gun_range`, `test_props_scale`) |
| 2 | on | **hung** after `test_ballistics` (`hang/`) |
| on3 | on | green but `test_dev_bridge` (three suites at once share its port; alone: 6 of 6) |
| on4 | on | **green, 756 passed** |
| on5 | on | **hung** in `test_dynamite` (`hang/`) |
| on6 | on | green but `test_dev_bridge` (the port again; alone: 6 of 6) |
| off1 | off | green but `test_dev_bridge` (the port; alone: 6 of 6) |
| off2, off3 | off | **green, 756 passed** |
| off4 | off | green but `test_dev_bridge` (the port) |

**With the thread on, 2 of the 5 runs after the fixes hung; with it off, 0 of 4** (run three at a
time beside the soak, the same load).

No thread errors in any suite log. The first ten-run slice around hang 1's place
(`--only=test_ba`, the thread on, under load): 10 of 10 green.

## The soak (`tools/soak.gd -- --minutes=240`, thread on, alongside the suites)

**Hung at 121 of its 240 game minutes**, about 1 h 30 in (`hang/soak_hang_threads.txt`: the same
shape as the suite's second hang). Up to then no soak problem printed and no thread errors; its
5-minute windows: the frame 7.5–8.8 ms (30.8 at 85:00, the fire), memory flat at ~1,240–1,340 MB
(resident ~1,500–1,530), people 17–20; orphan nodes 15,957 at 5:00 falling to 3,676 (the soak
fails a run that *ends* over 1,000; it never ended, so that check wasn't reached: compare main's
nightly). No thread-off soak was run here: main's nightly is the thread off (it passed on step 5's
branch, run 31).
