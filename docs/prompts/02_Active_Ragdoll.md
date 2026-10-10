# PROMPT 02 — Salt Creek: Active Ragdoll Research Prototype

**Repository:** https://github.com/Kokanee25/Western  
**Assignment:** Research and prove an anatomically credible physically controlled human, without replacing the production character architecture.

## Inspect first
Read `CLAUDE.md`, `DESIGN.md`, `project.godot`, `src/bodies/human_body.gd`, `src/bodies/physiology.gd`, `src/bodies/layers.gd`, `config/anatomy.json`, character meshes, pose/gait definitions, existing ragdoll joints and **Prompt 01's laboratory**. Verify current Godot/Jolt capabilities on the pinned engine (4.7.2 when written); do not assume every joint or soft-limit property is supported.

## Isolation
Use a Gameplay-owned experimental worktree/branch, e.g. `experiment/active-ragdoll`, based on the validated lab commit as appropriate. Keep prototype code, rigs, tuning, output and documentation in `experiments/active_ragdoll/`. Do not touch production HumanBody, Physiology, NPC logic, skeletons, generated characters, shaders, shared settings or the laboratory baseline. Do not merge without review.

## Objective and physics architecture
Investigate physically simulated skeleton segments driven by virtual muscular control following animation poses, rather than teleporting body parts. Compare joint motors/springs, PD torque tracking and constraint-driven control (including `Generic6DOFJoint3D` where its motors behave correctly with Jolt). Model anatomically sensible segment mass, centres of mass, inertia, foot-ground support, joint limits, torque limits, stiffness/damping, injury-dependent strength and passive release. Use tunable resources and record assumptions. Prefer built-in Godot/Jolt; justify any GDExtension/C++ or external dependency **before** major native implementation. Keep fingers/face out of expensive full-body dynamics unless proven necessary.

## Stage-gated experiments
**A — passive foundation:** Physical skeleton that collapses under gravity without exploding, tunnelling or unstable constraints.  
**B — muscular pose tracking:** Follow stable target poses and measure angular error/overshoot.  
**C — unsupported balance:** Stand on feet with genuine physical support, not hidden root anchoring.  
**D — modest shoulder push:** Absorb and recover when feasible.  
**E — strong disturbance:** Attempt recovery, step if implemented, or fall naturally.  
**F — injured leg:** Reduce supporting torque; compensate, buckle or fall.  
**G — injured arm:** Shoulder/elbow loses strength without globally destabilizing body.  
**H — consciousness lost:** Motors go off; preserve momentum, collapse smoothly.  
**I — environment contact:** Fall against chair, table, wall and floor with believable contact.  
**J — pose changes:** Stand-to-crouch and basic animation tracking; full locomotion is stretch, not a disguised success criterion.

Prove basic posture and modest-push recovery before committing significant effort to walking, stepping, or elaborate injury control. Record failed gains and solver configurations methodically, varying one principal parameter at a time.

## Realism rules
**Never multiply gunshot forces until a human flies backwards.** Separate projectile momentum/deposited energy from physiological injury; collapse may result from lost support or consciousness. Do not use random canned knockbacks or invisible root corrections to claim physical balance. Distinguish normal dynamic sway from statue-like rigidity and uncontrolled limpness. Do not introduce unverified medical precision; use existing Physiology strength/shock states for future integration.

## Measurement and footage
Use Prompt 01's identical configurations, timelines and front/side/three-quarter camera captures; compare with original passive baseline. Capture gameplay speed and slow-motion diagnostics. Measure pose tracking error, feet slipping, centre-of-mass support, joint-limit violations, maximum velocities, penetration, settled states, instability and controller/physics timing. A still screenshot of an upright body is **not** proof of balance. Test alternative lighting and orientation only as diagnostic extras, not confounds.

## Performance and scalability
Benchmark 1, 5 and 10 active characters, plus simultaneous active-to-passive collapse. Report Godot physics cost, controller script/native cost, solver iterations and joint counts, frame spikes, and whether a saloon gunfight with physical props can plausibly meet the existing approximately 2 ms **total** physics budget. If not, measure options for selective activation, simplified distant bodies, sleep, and fidelity scaling.

## Integration study only
Describe eventual interfaces to HumanBody, anatomy/physiology, procedural pose definitions, mocap, bullet damage, severed joints/dismemberment, NPC movement, first-person body and meshes, furniture physics and LOD. Do not integrate experimentally tuned behaviour into the live game.

## Deliverables
An isolated running controller, reproducible tunable parameters, source and stage logs, all A–J results with explicit pass/partial/fail, comparative clips and images, actual performance measurements, and a realistic architectural feasibility report. If unsupported balance cannot be achieved, preserve the best controlled experiment and state the technical blocker. **A successful active ragdoll is a convincing self-supporting physical person, not just a jointed body with motors.**
