# PROMPT 05 — Salt Creek: Character Face Geometry, Normal Maps and Painted-Square Refinement

**Repository:** https://github.com/Kokanee25/Western  
**Engine:** Godot 4.7.2 (verify pinned version) + Jolt  
**Owner:** Characters workstream  
**Priority:** High **only if the painted-square art style remains approved after Prompt 07**. If art direction changes, preserve the geometry/normal research and request an updated visual target.

## 1 — Goal and known failures
Improve the **existing** Rodin-based character system, not regenerate people at random. Preserve broad facial structure and prior successful paint/fitting/rendering. Correct recessed-looking moustache, flat ears, features disappearing during coarse painted-square conversion, under-defined eyelids/eyes, slanted or irregular squares on curved surfaces/collars, and insufficient 3D depth. Style match to the master character painting matters more than exact identity of its subject. We want three-dimensional faces within Salt Creek's coherent artistic language, not photorealistic fine detail or a post-filter.

## 2 — Read first
Read current `CLAUDE.md`, `DESIGN.md`, active Characters branch/status, `tools/characters/head_paint.py`, `tools/blender/fit_tripo.py`, `stylise.py` (locate exact path), `tools/paint/`, `tools/faces/`, painted-square cell layout, source normal maps/UV/bake/export handling, `assets/people/tripo/`, screenshots in `docs/screenshots/tripo/`, master references under `docs/concept/style/`, visual critics and comparison scripts. Verify the actual pipeline (approximately reference painting → stylise → Rodin → head paint/bake → Blender fit/cell layout → Godot). Do not accept an inferred architecture without file inspection.

## 3 — Preserve controlled baselines
Reproduce and snapshot **r10**, currently stronger for eye/brow clarity, facial depth and general appearance, and **D2r**, stronger for consistent square grid and some hat-band/clothing treatment. Original D2 was not fully reproducible: do **not** treat it as the controlled baseline. Earlier experiments found rigid fitting matches original Rodin head closely; Rodin's broad skull/brow/cheek/jaw/nose forms are geometry but small ear cavities, nostril openings, lip lines and eyelids largely live in normals. Averaging normal maps across roughly 7–9 mm cells keeps some eyelid relief but loses smaller forms. One representative normal per square sometimes helps. Coat square slant also results from projection/grid orientation. Keep all r10 and D2r scripts, values, images and source assets immutable for comparison.

## 4 — Phase A: normal-map convention diagnostic
Before sculpting, verify tangent-space normal encoding, red/green channel orientation and possible Y inversion, tangent/bitangent handedness, mirrored UV islands, Blender→glTF→Godot conventions, normal strength and correct normal-data import (not sRGB colour treatment). Render matched same-camera/same-light views with original vs flipped green channel, and separately use known convex/concave calibration geometry. Examine moustache, philtrum, ears, nostrils, eyelids and cheek contours. **Do not claim flipping green fixes it unless calibration and face renders prove that convention.** Isolate geometry vs normal vs texture bake vs lighting failures.

## 5 — Phase B: moustache/upper lip
Determine whether there is physical moustache projection in source Rodin geometry or only colour/normal detail. Diagnose muddy averaged cells, reversed shading and lack of silhouette. Prototype reversible (a) minimal raised two-part moustache geometry and (b) geometry plus normal maps. Preserve dark readable broad form, restrained lip-centre/philtrum gap and believable seating on face; avoid floating strips, oversized caricature or hair strands too fine to survive the style. Compare against untouched baseline and across lighting directions.

## 6 — Phase C: ears
Test three approaches: existing-vertex localized deformation; procedural ear insert/overlay; hybrid geometry plus residual normals. Produce visible outer rim/helix, inner depression, tragus, lobe and projection off head, while maintaining profile/front/three-quarter silhouette. Prefer simplified convincing large forms over high-poly ear anatomy. Protect rig/UVs, neck seams and downstream fit. An ear that reads only front-on fails.

## 7 — Phase D/E: eyes and other features
Protect r10's strongest area: expressive eyes, lid separation, brows, visible highlights, natural socket depth and consistent style. Test limited local geometry or selective normal preservation around eyes, without raising the entire face texture resolution or painting smooth photographic eyes. Assess upper/lower lips, philtrum, nostril underside, nose-to-cheek fold, brow volume, jaw/chin and local creases. Spend geometry only where silhouette or mid-range readability improves. Keep facial proportions and expression stable.

## 8 — Phase F: normal/cell treatment experiment matrix
Same geometry/camera/lighting for: **A** current r10; **B** one representative normal per painted square; **C** preserve controlled source normal detail inside existing square layout; **D** feature-aware hybrid (coarse broad surfaces, protected eyelid/nostril/etc. regions); **E** geometry-first hybrid with coarse normals. Evaluate face depth, visual noise, style fidelity, performance and loss of detail. Choose the simplest approach that actually reads better, not the sharpest texture.

## 9 — Phase G: square-grid consistency
Maintain target of roughly **18–22 prominent squares across the face**, avoiding prior too-fine **50–60 squares**. Diagnose projection axes, UV seams, slanted fragments, pixel cell alignment across curved surfaces, square size variation, shadow fragmentation, collar/hat transitions and existing six-direction projection. Compare local projection improvements while retaining coarse square size and meaningful colour/lighting. **No screen-space mosaic/post-process pixelation.** Do not mislabel coat projection faults as normal-map faults.

## 10 — Phase H: hat, collar and lighting
Test neutral directional light and actual game saloon/daylight. Diagnose brim height/shadows, over-bright face highlights, too-dark hat/coat, washed-out colour, collar fragments and feature flattening. Preserve the painting's dramatic shadows but readable eyes. Art-owned shader changes require explicit coordination per `CLAUDE.md`; propose patches, do not silently edit other workstream's materials.

## 11 — Phase I: automated comparison and blind criticism
Every meaningful variant must have controlled geometry (except tested part), focal length, camera distance, face image size, exposure, lights, render settings, texture resolution and cell tuning. Render front, left/right three-quarter, left/right profile, rear/ear silhouette when relevant and close-ups of moustache, eyes and ears; include native gameplay-scale shots and enlarged diagnostic crops. Re-render at least one changed light direction to test real depth. Retain r10 and D2r with all sheets. Run an independent blind critic shown only style painting, baseline and anonymous candidates. Score style, depth, eyes, ears, moustache, squares and coherence; reconcile with geometric diagnostics instead of trusting the critic alone.

## 12 — Phase J: technical validation
Check `.blend` source, GLB import, normal/tangent convention, neck/head fit, UV integrity, no new intersections, rig/skinning, head rotation, painted bake reproducibility and consistent Godot appearance. A prettier still does not count if animation breaks the head. Make localized, reversible edits only.

## 13 — Phase K: repeatability across people
Assess automatic normal-map validation, anatomical feature classification, moustache/ear geometry adjustment, eyelid normal preservation, projection fitting and UV repair. Test on **existing additional** characters of different face/hair shapes, not newly paid assets. Do not impose identical moustaches/ears everywhere or launch broad auto-deformation before proof on the test case.

## 14 — Experiment management and paid work
Keep all work in Characters branch, preserve source SHA, baselines and variant names, and maintain an experiment matrix with one principal variable changed at a time. No overwriting shared outputs, unauthorized merges, new paid Rodin/Tripo calls, LoRA training or external image model calls without explicit authorization and cost estimate.

## 15 — Final deliverables
Provide: root-cause diagnosis; normal convention verification; matched moustache and ear before/after views; eyes/lips/nostrils and square-normal experiment results; matched grid studies; comparison sheets; a usable corrected 3D head; scripts/parameters to reproduce it; unsuccessful attempts; reuse feasibility on multiple characters; clear recommendation for a production pipeline candidate. State if a remaining defect comes from geometry, normal maps, projected cells or lighting.

## Execution order and success
Reproduce r10/D2r → normal convention → moustache geometry → ear geometry → protect eyes and smaller features → feature-aware normals → square/hat/collar/lighting → multi-angle and head-rotation tests → repeatability across existing characters → recommendation. The outcome must be convincing painted-square three-dimensional form **if that art style remains the project's decision**. No regressions in fitting, rigging, import or gameplay rendering. Stop treating new character generation as a substitute for diagnosing the existing pipeline.
