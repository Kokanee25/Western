# PROMPT 06 — Salt Creek: Structural Destruction and Breakable Furniture

**Repository:** https://github.com/Kokanee25/Western  
**Engine:** Godot 4.7.2 + Jolt (verify current pin)  
**Owner:** Gameplay / Environmental Physics — Destruction  
**Priority:** High; isolated R&D.

## Objective
Prototype reusable structural damage for furniture and similar small environmental assemblies. Bullets, impacts and body contact damage **components and their physical connections**, with failure driven by loads/support geometry rather than canned destruction animations or oversized impulses. Preserve persistent physical debris within affordable simulation cost.

## First: review and plan
Read `CLAUDE.md`, `DESIGN.md`, `src/structures/structure.gd`, `src/structures/structure_member.gd`, `src/ballistics/ballistics.gd`, `src/bodies/human_body.gd`, `src/bodies/layers.gd`, relevant prop code, and experimental results of Prompts 01, 03 and, when available, 02/04. Inspect the **existing building support graph and damage calculations** before designing furniture connections: reuse interfaces/principles rather than duplicating a competing structural system. Document proposed architecture before implementing. Use isolated Gameplay worktree and dedicated `experiments/destruction_furniture/`; no production rewrites or merging without approval.

## Core design
Represent individually damageable legs, rails, seat, backrest, barrel staves, fasteners/joints and pivots as component parts or other well-justified abstractions. Accept hit component ID, location/direction, penetration/material and residual momentum from actual ballistics. Separate paint splinters/holes from structural strength changes and thresholded joint failure. Track connections, support paths, current gravity loads and constraints; released parts become Jolt rigid bodies retaining reasonable mass and collision. Let unsupported parts tilt, shift and collapse naturally. Support resting/sleeping debris and changed-object save serialization; cap fragments sensibly.

## Primary demonstration — leg shot beneath seated person
Build an isolated saloon chair and a seated NPC/test body with weight applied to chair. Shoot one leg at a controlled position. Depending on actual support, occupant mass and contact geometry, chair shifts, tips or collapses; broken leg separates as real debris. Seated body loses support and falls physically. Avoid deterministic pre-animated collapse, teleportation, launch forces, unrealistic bullet momentum and ignoring chair construction. Document when a single bullet is **insufficient** to sever a leg: model damage realistically and use multiple shots or weaker joint conditions if required, without falsifying projectile force.

## Other demonstrations
- Four-legged table loses a support and tips; objects slide/fall.
- Barrel accumulates localized damage and can split into coherent pieces.
- Fixed heavy saloon bar receives bullet damage but remains stable absent true support failure.
- Door surface can be damaged; hinge failures can detach door.
- Ragdoll/body collision can break or destabilize already weak furniture without inventing explosive impulses.

## Architectural comparison
Contrast pre-authored breakable components and hinges vs runtime mesh-fracture; prefer predictable shared component families unless procedural fracture delivers proven value. Explain reuse with the AI-authored chair and existing furniture physics. Use light decals/chips for superficial impacts and promote to dynamic rigid fragments only for meaningful failure. Track support-graph changes, resolved contacts, debris reactivation/sleep and game save state.

## Validation
Automated repeatable fixed-seed scenarios and calibrated thresholds, plus actual footage at gameplay speed and side/front views. Record per-event ballistics inputs, connection strength/state, rigid-body transforms, failure timing, occupant response, fragment count, penetration and physics time. Test no-bullet baseline, cosmetic shot, multiple strikes, true structural failure, loaded/unloaded chair and different seated body positions. Benchmark several destructible assemblies simultaneously against the total physics budget. Explicitly log fake or unavailable metrics rather than inventing them.

## Deliverables
Isolated working leg-failure prototype, component/connection design, controlled chair/test body, clips/measurements, four supporting demonstrations where feasible, comparison of fracture approaches, tests, performance results, known limitations and recommendation for integration with existing structures, ballistics, object physics and eventual ragdoll. **Smallest credible leg-loss-under-occupant proof first; no full destruction-system rewrite.**
