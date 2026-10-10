# PROMPT 08 — Salt Creek: AI Motion Capture, Animation Retargeting and IK Pipeline

**Repository:** https://github.com/Kokanee25/Western  
**Owner:** Characters (with Gameplay integration proposals)  
**Priority:** CRITICAL.

## Objective
Implement a reliable, scriptable workflow converting **user-recorded phone video or lawful motion-capture clips** into clean, reusable character animations that retarget to Salt Creek skeletons, blend in Godot and cooperate with procedural aiming, interaction IK and the future active ragdoll. Don't assume a video-to-3D service solves retargeting and foot contact by itself.

## Read and respect
Review `CLAUDE.md`, `DESIGN.md`, `docs/MOCAP.md`, `assets/mocap/`, `assets/animations/`, relevant `tools/blender/`, PeopleBodies/HumanBody pose logic, existing rigs and imports, and Prompt 02. Audit what is already implemented before proposing changes. Follow Characters-owned file boundaries; avoid production HumanBody, NPC and shared controls without Gameplay consent. External services/tools with changing prices/licences must be verified, and paid calls require authorization. Use isolated worktree and example motion assets or synthetic test fixtures if user recordings are not yet available.

## A — Input pipeline
Compare iPhone self-recording → video-to-mocap (e.g. currently usable alternatives), pre-existing licensed FBX, and procedural Blender actions for different animation classes. Verify export rights for assets in a public repository and disclose data/privacy considerations. Create robust intake naming, body scale calibration, facing-direction convention, rest/A-pose, frame-rate units and source provenance. Use 2–3 takes when available; do not claim capture quality for recordings not supplied.

## B — Retarget and cleanup
Build an automated Blender workflow: import → normalize coordinate/scale/root → map bones and rest poses → retarget → trim → de-jitter → preserve hand trajectory → root-motion extraction → make loops → foot-ground alignment → glTF/GLB export → Godot import checks. Implement test reports for bone rotation violations, hip position, foot sliding, phase, clipping and export regressions. Preserve raw data and allow non-destructive changes. Do not hard-code one actor's proportions into universal assumptions.

## C — Representative motion test
Prove at minimum: idle weight shifting, walk/run, draw/aim/holster, one-knee-grounded cover crouch, kneel→stand, hand bracing against a surface, and an arm reaching toward furniture. Critically, the existing symmetrical squat-style crouch does **not** represent the requested asymmetric kneel: one planted foot, bent knee, the other knee near/on ground where appropriate. Include both knee choices or show how mirroring works. Physically impossible poses should be rejected; distinguish normal crouch from taking-a-knee cover pose. Recoil and death remain procedural/physics as defined by design.

## D — Blending, IK and procedural overlays
Create or specify small, reusable animation state/motion layer for locomotion, upper-body aim, arm gestures and transitions. Hands should meet actual wall/table/doorframe contact coordinates via IK or robust equivalent, with limits, reach failure and fade-out. Feet must not slide or penetrate stairs, slopes and uneven boardwalks. Demonstrate carried prop alignments and future joint target output for active-ragdoll control; do **not** implement the physics solver here. Interactions should work on multiple character proportions.

## E — Automated validation and visuals
Produce front/side/three-quarter gameplay-speed clips with joint debugging and foot contact metrics. Test crossfade transitions, repeated loops, unexpected root jumps and left/right-handed motion, crouch transitions, animation beginning during walking and interrupted by fall. Benchmark bones/rigs and several animated NPCs. Compare user-video capture, procedural fixups and any paid platform using actual measured time/cost when tools are available.

## Deliverables
Source scripts, import/export conventions, retarget mapping data, 5+ functioning clips or controlled test examples, reproducible command line, skeleton and animation test scene, quality metrics, IK contact demo, recorded source/provenance/licence, and list of user footage to record next. Clearly state which clips remain placeholders. **Primary proof: one motion source should drive more than one Salt Creek character cleanly.**
