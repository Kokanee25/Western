# PROMPT 03 — Salt Creek: Interactive Object and Furniture Physics

**Repository:** https://github.com/Kokanee25/Western  
**Assignment:** Isolated research into believable weighted furniture and small-object dynamics, interaction, persistence and future character contact.

## Read and boundaries
Read `CLAUDE.md`, `DESIGN.md`, `project.godot`, `src/props/prop_library.gd`, `src/props/prop_models.gd`, `assets/props/manifest.json`, `src/structures/structure.gd`, `src/structures/structure_member.gd`, `src/ballistics/ballistics.gd`, `src/bodies/human_body.gd`, `src/bodies/layers.gd`, existing prop/physics tests and Prompt 01 laboratory conventions. Verify paths if moved. Use pinned Godot 4.7.2/Jolt configuration. Create Gameplay-owned experiment branch/worktree with new files under `experiments/object_physics/`; no production ragdoll, NPC, character-generation, shaders, or structural-system rewrites. Do not merge without review.

## A — Physical furniture
Create physically plausible wooden chair, bar stool, round poker table, barrel, crate, whiskey bottle and tin cup using existing assets where feasible. Investigate masses, centre of mass, moment of inertia, materials/friction/bounce, damping, sleeping, collision groups and **compound collision shapes** that preserve empty spaces between table/chair legs. Do not cover everything with one enclosing box if it produces false contact. Measure resting stability, the force needed to slide/tip, natural stacking and settling. Tall narrow stool easier to tip than heavy low table; nothing should behave weightlessly.

## B — Player object manipulation
Isolated controls/interfaces to push, pull/drag, pick up suitably light objects, carry, place/drop and deliberately tip furniture. Use capped forces or physical constraints rather than direct rigid-body teleporting. Do not permit force buildup causing wall-launching; preserve velocity continuity and avoid unwanted clipping. Respect existing weapon controls without editing production input settings; provide an isolated input mapping/demo.

## C — Saloon collision demos
Build a repeatable test saloon containing tables, chairs, barrels, crates, bottles and cups. Show chair brushed by a character; body staggering into table; heavy contact causing overturn; loose objects falling from a tipping table; bottle breaking; chair hitting chair; barrel rolling into wall; multi-object contact. Use the current passive ragdoll or controlled test proxy unless Prompt 02 already supplies an isolated active character interface. No second ragdoll controller and no arbitrary object launch forces.

## D — Ballistics and destructibility hooks
Prototype material-aware impacts and approximate momentum transfer based on projectile mass/velocity rather than deposited energy as a fake giant impulse. Test superficial marks, penetration and bottle breakage while a heavy table remains mostly stationary. Examine how physical furniture can delegate structural failure to the existing support/member system, rather than duplicating its functionality. Keep this phase's production integration as an interface proposal or isolated fixture.

## E — NPC and IK integration hooks
Define interfaces for ragdoll-to-furniture contact; intentional NPC chair pushing/table overturning; movable obstacles in navigation; dynamic cover queries; character hand attachment/contact via IK. NPC manipulation must serve an actual goal (clearing a path, taking cover, bracing, helping someone), not randomized environmental chaos. Do not modify AI or rigging.

## F — Persistent/sleeping state
Design minimal changed-object serialization (stable ID, transform, damage, contents, intact/broken, physics active/asleep) compatible with the game's delta-save approach. Test restoring an overturned table and scattered items. Keep untouched objects static or sleeping where appropriate; avoid instability at load.

## Testing and benchmarks
Use deterministic scenario manifests, fixed physics settings, several repeat runs and logged transforms/velocities/contacts, sleeping counts and physics timings. Render at gameplay speed front/side/three-quarter for: chair pushed over, table overturned, bottles falling, ragdoll hitting furniture, bullet striking table, and multiple objects settling. Visual inspection is mandatory to call a demo verified. Test scene baseline, 30 dynamic props, 30 props + 3 characters, pile-up and waking props. Measure actual total physics cost against the existing roughly 2 ms system-wide budget at 60 fps; identify solver instability and spikes.

## Deliverables
Working isolated saloon prototype, reusable physical-object architecture, interaction demos, command-line automated tests, six rendered demonstrations, performance measurements, collision and persistence limitations, plus proposed interfaces and an integration plan that preserves production ownership. **The room should contain heavy, believable objects, not weightless projectiles.**
