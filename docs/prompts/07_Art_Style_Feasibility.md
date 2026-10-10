# PROMPT 07 — Salt Creek: Art Style Feasibility and AI Consistency Laboratory

**Repository:** https://github.com/Kokanee25/Western  
**Owner:** Art, with Characters coordination  
**Priority:** CRITICAL — art-direction decision gate, not automatic permission to replace existing visuals.

## Why this experiment exists
The previous painterly-square style remains a valuable research baseline, but creating consistent AI-generated faces, props and environments has proven costly. Investigate a production-feasible visual direction that keeps Salt Creek's grounded frontier identity and has a repeatable AI→model→Godot pipeline. The decision should use **in-engine footage and cross-asset consistency**, not a collection of unrelated beautiful stills.

## Read/permissions
Review `CLAUDE.md`, `DESIGN.md` §4, master painting references in `docs/concept/` and `docs/concept/style/`, art judges and golden images, live character/prop pipelines and latest Art/Characters branches. Describe which aesthetic decisions are currently fixed vs being reconsidered; ask for approval before adopting a new one. Use an Art-owned experiment branch/worktree. Do not overwrite shaders, generated faces, assets or golden images. Character-owned modifications require coordination. No new paid AI/image/3D generations without a price and authorization.

## Controlled comparison
Define **three** visual candidates (one must be the existing painterly-square reference; the other two should be justified, reproducible options such as stylized hand-painted low-poly/PBR or restrained illustrative realism). Do not conflate screen resolution/pixel filters with material style. Produce each candidate for the **same** scope: (1) one full character including face, outfit and headgear, (2) wooden chair, barrel and table, (3) one saloon interior corner with wall/floor, lamp and doorway, (4) one exterior façade section. Reuse existing meshes/source assets when possible; prefer style translation/authoring, not unfairly generating wholly different model quality for each style.

## Art direction constraints
Strong silhouettes and believable anatomy; small detailed world in 1880s; readable faces/eyes and clothing; period-consistent natural materials; shadows, firelight, dusk and sun; first-person play. Rendering must support motion, damage, blood/wounds, breakable components and variations across many NPCs. No one-off camera tricks that only work in a still image; no indiscriminate global post-process to conceal poor UVs/meshes. Show the same assets from several distances, directions and camera positions under neutral daylight, warm saloon light and golden hour.

## Production feasibility
For each style measure: repeatability across five assets; variation across two different characters; UV/texture requirements; complexity of authoring; dependency on paid model generations and revisions; AI instruction ambiguity; material editability; triangle/draw cost; animation and rig compatibility; time to re-create a second example; ability to automate validation; current baseline regressions. Run blind art critique with anonymous candidates and separate measurable workflow scores from subjective style assessment. Track the exact procedure and cost per candidate, including failures.

## Deliverables
Comparison boards and short identical in-engine camera paths, authored files/scripts, reproducible settings, cost/time estimates, an honest rubric, top visual failures, and a recommendation: retain current style, adopt a specific alternative **subject to approval**, or continue limited research. Include a proposed compact **style bible**: face density/form language, surface materials, palette, highlights/shadows, texel rules, geometry detail budgets, and prohibited effects. Do not migrate the live project in this experiment.

## Success criterion
We must be able to explain how Claude or another AI produces the **hundredth asset in the same world**, not just a convincing first screenshot. Until this decision is approved, leave Prompt 05's painted-square work as research, not an unquestioned production mandate.
