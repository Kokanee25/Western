# PROMPT 04 — Salt Creek: AI-Directed 3D Asset Authoring Pipeline

**Repository:** https://github.com/Kokanee25/Western  
**Engine:** Godot 4.7.2 (verify repo pin) + Jolt Physics  
**Priority:** Independent R&D. Do **not** interfere with existing development.

## Objective
Investigate and prototype an AI-directed 3D modelling pipeline capable of constructing **editable, production-quality game assets from reference photographs using an actual modelling application**, preferably Blender. Instead of a text-to-3D model generating a finished mesh, an AI agent should examine photographs, estimate component shapes and proportions, operate Blender/Maya-like modelling tools deliberately, create separated editable geometry, selectively revise pieces, add UV/materials/physics pivots, render under varied lighting, export optimized GLB assets, and reliably repeat construction for variations. The main measure is **controllability, editability and game-readiness**, not polished still renders.

## Isolation and permissions
Read current `CLAUDE.md`, `DESIGN.md`, relevant Blender/prop pipelines and the state of all development branches. Create `experiment/ai-asset-authoring` in a separate Git worktree. Keep code, outputs, Blender files, models, logs, renders, comparisons and scripts isolated. No production shaders, character generation, physics, props or outputs may be overwritten. Do not merge or push experimental changes without authorization. Obtain authorization before external paid services. Coordinate any shared asset ownership with existing Art/Characters sessions; a topical experiment is not a new unrestricted workstream.

## Phase A — Technology research
Investigate current Blender MCP and similar integrations, `bpy`, Claude Code plus structured modelling commands, procedural/parametric geometry, multi-view reference interpretation, automated UV/material assignment, and geometric validators/repair. Compare an existing integration against a small custom Blender-command tool layer. Evaluate geometry quality, revision control, reliability, reproducibility, speed, inspectability and glTF/Godot compatibility. **Do not build another entire modelling engine** if existing Blender APIs are sufficient. Recommend a minimum practical path and explain why.

## Phase B — First asset: traditional 1880s wooden saloon chair
Use user-provided photos if available; otherwise identify a provisional source or annotated dimensioned design, marking assumptions separately from verified measurements. Before construction, create a reference-analysis sheet, estimated dimensions and a component construction plan. Model in Blender using actual operations, not generic text-to-3D replacement. Include four legs, seat, backrest, joinery/rails/supports and restrained period-authentic construction detail. Keep parts named, independently editable, hierarchically organized and reusable. Require clean topology, sensible triangle count, proper units/axes/origins/pivots, no redundant overlap, usable UVs and replaceable materials. Save `.blend` and deterministic construction scripts or operation history.

## Phase C — Selective-edit benchmark
Starting from a preserved initial version, command the AI to: (1) shorten **only** the front legs; (2) alter only the backrest; (3) add support between rear legs; (4) change seat dimensions while preserving unaffected construction; (5) restore a prior version and make a second chair variation. Measure incorrect target selection, unintended geometry changes, retained identities/UVs, whether revisions rebuild everything, and time per edit. Preserve snapshots, diffs and a readable component hierarchy. This is the primary proof of genuine AI-directed modelling.

## Phase D — Salt Creek art direction
Compare under the **currently approved** style; if Prompt 07 has revised the art direction, follow that decision rather than assuming legacy painted-square is final. The earlier target was bold, countable painted texture squares on chunky but credible 3D, controlled resolution, modern believable lighting and a painterly rather than generic low-poly result. No post-process pixelation substitute. Render neutral daylight, warm saloon and outdoor evening conditions, ideally also as imported Godot views. Judge against art references, not Blender glamour lighting.

## Phase E — Godot and physics readiness
Export glTF/GLB and import in a fully isolated Godot test scene. Validate scale/orientation, names/component split, triangle/material/texture counts, UVs, normal/tangent correctness, import logs, pivots and collision-shape usability. Demonstrate at least one simple Jolt rigid-body fall/overturn. Assess future breakable chair legs, moving seats and object picking without modifying the existing furniture physics research or the destruction system.

## Phase F — Production scalability
Prototype reusable patterns, parameterized dimensions and shared woodworking components for families: chairs, tables/stools, barrels/crates, windows/doors/shutters, storefronts/porches, wagons/wheels, fences/gates and interior props. Describe the ideal loop: user photographs item from several angles → AI infers approximate dimensions → plans parts → builds Blender file → exports preview → receives targeted revisions → validates automatically → delivers GLB and source. Identify which steps are genuinely automatable and where photographs alone cannot resolve hidden dimensions or material detail.

## Phase G — Character geometry feasibility (research only)
Investigate, without touching the current Rodin/Tripo character pipeline, whether localized Blender geometry authoring could improve ear helix/hollow, moustache volume, lips/nostrils/eyelids, or particular features while retaining rig/UV correspondence. Do **not** assume procedural authoring is superior for organic heads or promise a complete replacement.

## Phase H — Evaluation
Record actual reference fidelity, geometric validity, selective-edit success, visual consistency, GLB readiness, reproducibility, build/edit times, required cleanup and scalability. Show initial/edited models, wireframes, object tree, viewport diagnostics and Godot renders. Prefer quick viewport renders during iteration over repeated slow CPU finals; distinguish visually verified from untested results. Repeat initial build when possible to evaluate reproducibility.

## Deliverables and stop condition
Provide working isolated AI→Blender command workflow; `.blend`; construction scripts/config; initial and five revised chair variants; GLBs; Godot import/physics test; comparison images; timing/results table; failure report; and integrate/do-not-integrate recommendation. Stop after a convincing chair and targeted-edit evaluation. **Do not expand into a factory for every prop before the selective-edit and Godot tests succeed.**
