# PROMPT 09 — Salt Creek: Passive Ragdoll Stabilization and Realistic Hit Reactions

**Repository:** https://github.com/Kokanee25/Western  
**Owner:** Gameplay  
**Priority:** HIGH, strictly **after Prompt 01 baseline**.

## Objective
Improve the existing production-compatible passive ragdoll's realism—weight, joint limits, collision and momentum continuity—using **measured lab evidence**. Separately correct projectile-to-body impulse and physically implausible knockdowns. This is not permission to replace HumanBody with an active controller or rip up physiology.

## Audit first
Read `CLAUDE.md`, `DESIGN.md`, current `src/bodies/human_body.gd`, `src/bodies/physiology.gd`, `src/bodies/layers.gd`, anatomy parameters, `config/physiology.tres`, related ballistic code, Prompt 01's report and its reproducibility manifest. Document existing `go_limp` rigid-body conversion, `HingeJoint3D` knee/elbow constraints, `ConeTwistJoint3D` others, handling of segment mass, collision, angular damping, injected chest random impulse, and any shot-induced `go_limp` push. Verify facts against actual branch; the script may have changed.

## Diagnose and prioritize
Use the laboratory's baseline ranked failure list to choose at most three critical issues first: e.g. unnatural chest launch, joints twisting, interpenetrating limbs, velocity snaps, overbouncing, lack of collision among necessary segments, falling from asymmetric kneel, settling indefinitely, stair/door contacts. Characterize each with reproducible metrics and visible clips; distinguish bad rig mass, constraint axis/limits, collisions, solver settings and scripted impulse.

## Controlled modifications
Work on isolated Gameplay branch. Keep original exact baseline and try **one variable family at a time**: conserve linear/angular velocities when changing node bodies; remove or bound random impulses if evidence warrants; use anatomical joint orientations and robust limits; tune friction/contact and damping without making bodies unnaturally viscous; use correct mass/inertia/centre. Separate bullet **mass×velocity momentum** from deposited energy, injury severity and behavioural loss of stance. A realistic hit can trigger an injury-driven fall, but should not throw an 80-kg person across the room. Nonpenetrating impacts and blast winds have different physical mechanisms; test them separately. Avoid frame-dependent impulses.

## Test matrix
Standing/walking/running, asymmetric kneel, seated and facing different orientations; torso/limb strikes, low and high energy; ground/stair/table collision; drag by clothing/chest; limb removed; repeated contacts; 5 and 10 concurrent ragdolls. Preserve wound visuals, collision layers, drop-gun behaviour, severed segments, body state and gameplay events. If change requires editing production `human_body.gd`, **propose diffs, run in an isolated Gameplay-owned branch, and request approval before merge**. Do not touch Characters-owned mesh/skeleton tools.

## Performance/evidence
Before/after side-by-side at original lab cameras. Report resting jitter, penetration, joint violations, movement discontinuities, impulse inputs, root displacement/rotation, settle time, active body count and Jolt CPU time. Run repository tests and a smoke/soak subset. Check no regression in hit registration, wound and sever logic. Visual judgment at real speed mandatory.

## Deliverables
Defect root-cause report, smallest proposed patch set, reproducible before/after captures, metrics and regression tests, honest pass/fail, performance impact and specific integration request. **Stable realistic passive falls are a deliverable even if an active ragdoll remains research-only.**
