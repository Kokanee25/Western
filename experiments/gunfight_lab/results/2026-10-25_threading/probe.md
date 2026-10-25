# The probe: where the per-person milliseconds go (2026-10-25)

Three D fights (seeds 1-3, the careful player, `spec_hall`) on `claude/perf-threading` with
main merged (so PR #375's settle is in: `fire` is 0.3 ms now, the worst 5% of frames 24 ms, not
42), with temporary sub-timers and query counters applied by `instrument.py` (kept here for the
record; applied to a working copy and reverted, never committed). `probe.txt` has the table; a
`q_*` column is physics queries a frame (each counted as 1.0), not ms. Means over the three:

| What | ms a frame (this 2.1 GHz core) | Of |
|---|---|---|
| `people_body` | 4.36 | 12 people's `_physics_step` |
| . `_apply_pose` (the pose maths and the 17 pivot sets a man) | 2.19, of which the tail (rig, reach, grab, sling) 0.47 | |
| . the rest of the step (`_track_carry`'s 17 `global_transform` reads a man, `_favour_step`, stains, cough, velocity) | ~1.7 (by difference) | |
| . `Physiology.step` | 0.16 | pure |
| . `WoundSigns.step` + stains | 0.20 | |
| . `_after_step` (healing, pallor) | 0.06 | |
| . walking: `_slide` 0.12 + `_snap_to_ground` 0.10 | 0.22 | 12.7 queries a frame |
| . limp (the ragdoll's tone, braces) | 0.03 | few men down |
| `people_skeleton` | 1.37 | `_update_skeleton` in `_process` |
| . `_pose_fingers` | 0.97 | 45 bones a man with `String(e.fid).begins_with/ends_with` per bone per frame |
| . the 17 body bones | ~0.4 | |
| `outlaw_brain` | 2.32 | the three men |
| . the cover search (`Search.step(40)`) | 0.50 on average, bursts while searching | 48 rays a frame on average |
| . `GunHand.step` | 0.25 | pure |
| . `_clear`, `_friend_in_the_way`, `_aim_point` | small | 0.4 rays a frame |
| . the rest (`_combat`, `_find_target`, `_pick_fight` over relations, `_gang`, crew, callouts, `_decide` strings) | ~1.6 (by difference) | GDScript logic |
| `senses` | 1.19 | `_look` 1.14: ~2 looks a frame across 12 people |
| . its rays | 45 a frame | ~25 µs a ray with the cone maths round it |
| `SightLight`'s lines | 0.08 | cached well |
| `civilian_brain` | 0.54 | nine townsfolk |
| `ballistics` | 0.26 rays a frame | few |

**Rays in all: ~106 a frame** (cover 48, senses 45, walking 13, brains 0.4, balls 0.3): at
10–25 µs each through GDScript, **1.2–1.5 ms a frame**, not the several the first plan assumed.
The cover search's rays come in bursts (a man searching casts ~120 a tick for a few ticks).

**So the order of the per-person cost is:** the pose maths and pivot writes (1.7), the part
re-reads and the step's remainder (1.7), the brains' logic (1.6), the rays (1.3), the fingers'
strings (1.0), the pose's tail (0.5), the cover search's bursts (0.5 average), the skeleton's
bones (0.4), the signs (0.2), physiology (0.16). The pure arithmetic a thread could take without
touching the scene (physiology, the gun hand, the pose maths before its writes) is ~1.5 ms of
the people's 10; the rest is scene writes, scene reads, GDScript logic and queries.

The frame: 20.0 ms, p95 24.4; the named systems ~13.5; ~6.5 untimed (Jolt's step, the
transform propagation behind the pivot sets, signals, the engine).
