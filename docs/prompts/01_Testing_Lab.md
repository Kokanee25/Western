# PROMPT 01 — Salt Creek: Automated Ragdoll Testing Laboratory

**Repository:** https://github.com/Kokanee25/Western  
**Assignment:** Isolated reproducible ragdoll evaluation tools. **Do not fix production ragdoll physics in this assignment.**

## Read and verify
Read `CLAUDE.md`, `DESIGN.md`, `project.godot`, `src/bodies/human_body.gd`, `src/bodies/layers.gd`, `src/bodies/physiology.gd`, `config/anatomy.json`, `tests/run_tests.gd`, `tools/screenshots.gd`, `tools/scene_probe.gd`, `tools/visual_checks.py`, plus the current ragdoll/physics tests. Verify current paths, branches and the pinned Godot version; the documented baseline uses Godot 4.7.2/Jolt at 60 physics ticks/sec. Reuse current test, replay, capture and reporting conventions rather than making a second framework.

## Objective
Build a Godot laboratory where the **current passive ragdoll** and future controllers can run identical fall/collision scenarios, produce machine-readable measurements and synchronized multi-angle footage, and be compared against an untouched baseline. Another AI agent must be able to operate it by CLI without editor clicks.

## Boundaries
Work on an isolated Gameplay-owned experimental branch/worktree, e.g. `experiment/ragdoll-lab`. Keep added files under `experiments/physics_lab/` except unavoidable documented adapters. Preserve the original commit SHA and baseline captures. Do not change production `human_body.gd`, physics settings, character assets, generated files, NPC AI, ballistics, or unrelated systems; ask the relevant owner about missing public interfaces. Do not merge to `main`.

## Scene requirements
Create repeatable test fixtures for level ground, a slope, short stairs, wall/doorway, a solid table, a movable chair and the **actual Salt Creek body**. Set fixed cameras and neutral lighting. Optional overlays: joint axes, collision volumes, velocity and contact markers.

## Automated scenarios
A. Ragdoll from standing.  
B. Ragdoll while walking.  
C. Ragdoll while running.  
D. Ragdoll from the existing crouch.  
E. Front/back/left/right impulses at named body points.  
F. Falls against wall, doorway, slope, stair, table and chair.  
G. Different initial orientations, identical conditions.  
H. Long-duration settling and sleeping.  
I. Multi-contact collisions (e.g. arm hits table as feet hit floor).

Specifically inspect `HumanBody.go_limp()` and bullet knockdown behaviour: production presently includes scripted push and randomized chest impulse components. Measure and annotate these separately from physically caused collisions. Do **not** correct them in this laboratory assignment.

## Measurement and determinism
Log per physics tick as obtainable: position/orientation per segment; root/limb linear and angular velocities; joint-relative angles and limit violations; ground penetration; large per-frame jumps; observed contacts; **applied** impulses; settling time; active/sleeping rigid-body counts; physics and overall frame time. Export structured CSV/JSON and a scenario manifest recording seed, starting pose, transform, velocities, impulses, timestep, Godot/Jolt version, physics settings, hardware and source SHA. Do not invent solver-internal contact impulses or constraint forces if unavailable: use labelled proxies or declare the gap. Re-run representative tests, define empirical tolerances, and acknowledge that cross-platform floating-point rigid-body determinism cannot be assumed.

## Visual evaluation
Capture synchronized front, side and three-quarter views, optionally overhead, at gameplay speed with slow-motion diagnostic playback. Render using an actual GPU or appropriate Xvfb/Vulkan/software renderer; **headless physics-only results do not constitute visual verification**. Build a tool for matched-timestamp side-by-side comparisons. Flag unrealistic bounce, twisting, launches, floor penetration, limb inversion, lingering jitter and discontinuities. Calibrate numerical thresholds against the existing baseline and keep human visual judgment separate from automated fail criteria.

## Performance
Test 1, 5 and 10 simultaneous passive ragdolls, including simultaneous collapse and subsequent sleeping. Record CPU physics/frame-time costs, spikes, joint and shape counts and hardware. Compare against the existing **overall** roughly 2 ms physics budget at 60 fps; it is not a ragdoll-only allowance.

## Deliverables and acceptance
Provide: (1) isolated executable scene; (2) scenario CLI; (3) baseline CSV/JSON; (4) rendered images/video; (5) side-by-side comparator; (6) usage commands; (7) measured performance; (8) five most obvious baseline visual failures with supporting frame references and evidence; (9) limitations. Demonstrate that a fresh agent can repeat the procedure without manual editing. **Do not claim that ragdoll physics has been improved: the product of this assignment is trustworthy measurement.**
