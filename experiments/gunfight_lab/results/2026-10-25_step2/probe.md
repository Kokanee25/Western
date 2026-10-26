# The probe of HumanBody's tick (2026-10-25, the (abcd)+(a2)+seeds build 4f8c8986)

`instrument.py` applied to a worktree (sub-timers inside `_physics_step` and `_apply_pose`, never committed), seeds 1-3, the lab's command otherwise. The sub-timers add their own cost (~0.15 ms: `people_body` 3.25 here, 3.09 without).

| | probe (3 fights) |
|---|---|
| frame_ms | 14.71 |
| people_body | 3.25 |
| people_skeleton | 0.47 |
| hb_after | 0.05 |
| hb_carry | 0.46 |
| hb_cough | 0.03 |
| hb_favour | 0.02 |
| hb_physiology | 0.12 |
| hb_pose | 1.86 |
| hb_pose_head | 0.16 |
| hb_pose_loop | 1.10 |
| hb_pose_tail | 0.50 |
| hb_signs | 0.16 |
