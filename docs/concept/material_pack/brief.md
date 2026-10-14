# Salt Creek — Material Lab: Reference-Driven Timber and Deck Construction Pass

Repository: Kokanee25/Western
Engine: Godot 4.7.2
Branch/workstream: continue the existing isolated Material Lab experiment (reported as `claude/art-material-lab`). Do not modify production assets or approved baselines.

## Essential: inspect the attached images first

All images are provided in this reference pack. The filenames below are relative to the pack's root. Open the actual image files at full resolution; do not substitute assumptions based on their names.

### Reference priority (important)

1. **ART DIRECTION / APPROVED TARGET:** `01_APPROVED_STYLE/approved_saloon_exterior.png`. This is the APPROVED newer Salt Creek environment direction: grounded, believable 3D construction; distinct timber/planks; selectively simplified, stylized surfaces; controlled cinematic lighting. Do not revert to the older highly pixelated saloon illustration or treat this as a requirement to reproduce every feature geometrically.
2. **CHARACTER COMPATIBILITY:** `01_APPROVED_STYLE/current_character_neutral.jpg` and `current_character_saloon.jpg`. These are actual Godot character render crops. Environment material treatment must sit naturally beside this level of stylization, not a voxel/Minecraft or watercolor treatment.
3. **WOOD CHARACTER REFERENCE:** `02_WOOD_REFERENCE_SHEET/{structural_timber,boardwalk_floor,red_painted_siding,pale_store_boards}.png` and the source comparison `original_sheet_vs_lab_swatches.jpg`. These demonstrate desirable wood grain direction, subdued material variation, painted wear, knots and plank separation. They are VISUAL references, not instructions to bake lighting into albedo or to copy a photograph unaltered.
4. **DEFECT EVIDENCE / NOT A TARGET:** `03_EXISTING_MATERIAL_LAB/{lights_noon,lights_golden,lights_night,closeups,fig_scale,abc_near}.*` and `04_DEFECT_CLOSEUPS/*`. These show what the existing and experimental woods currently look like and what must be corrected. The current lab texture is not the style target.
5. **PHYSICAL CONSTRUCTION REFERENCE:** actual solid lumber construction takes priority over pixel patterns: board thickness, longitudinal grain, end-grain cut faces, natural seams, posts, board geometry, joints. Real-world visual references are listed in `REAL_WORLD_PHOTO_LINKS_AND_CREDITS.md`; use these for construction details rather than adopting their specific colours or photographic resolution.

## Key observed defects

- Structural posts look like large unrelated vertical/rectangular brown-grey patches rather than coherent lumber. Longitudinal grain, actual weathering and knots must be materially legible but not noisy.
- Deck/porch boards read too thin at their open edges. Their exposed ends do not display convincing end grain. A floor texture with painted seams cannot stand in for real board thickness and end geometry.
- Experimental boardwalk texture contains excessive stripe repetition and plank-to-plank colour jumps.
- Some red siding is overly dark in noon light; other lighting states oversaturate existing materials. Separate albedo colour from environmental light.
- Art direction drift: stop evaluating only against the older coarse 6-block-per-board master paintings; measure against the newly approved grounded-3D exterior too.

## Immediate task: targeted diagnostic and three-material experiment

1. Inspect the actual mesh/board geometry, UVs, current render/shader settings, and existing `tools/textures/paint_woods.py` and `woods_lab.json` (locate them if relocated). State which issues are geometry versus texture versus shader/lighting.
2. **Deck boards FIRST.** For representative front porch/boardwalk boards, check cross section and thickness from top, side and oblique views, especially where boards terminate at an exposed edge. Keep actual board geometry if feasible for interaction, damage, burning and breakage. Distinguish TOP, LONG SIDE and END grain in UV/material assignment. Test physically believable board dimensions, for example ~40–50 mm thickness as an adjustable starting trial, not a fixed mandate; width/spacing should follow plausible rough-sawn period construction. Add subtle end-growth bands/fibre marks, appropriate cut colour and rare checks. Do not paint artificial high-contrast concentric rings on every tiny end.
3. **Structural posts SECOND.** Keep solid timber proportions and legible cross-sectional shape. Set grain along the beam axis, reduce random rectangular patchwork, localize knots, saw marks, splits and wear where plausible; avoid bleaching in sunlight. Test material-only vs material+small geometry improvements.
4. **Floor/siding THIRD.** Calm the repetitive light/dark stripes on planks. Make painted siding coherent with wear clustered around exposed edges, seams, lower splash zones and fasteners, not evenly distributed noise. Preserve species/use differences between boards, trim, post timber, furniture and siding.
5. Produce side-by-side A/B/C renders (A=existing baseline, B=new materials on original geometry, C=new materials plus justified geometry changes) for posts and deck ends. Match camera, lights, exposure, tonemap and scale EXACTLY. Include noon, golden-hour and night plus **end-on, side-on, 3/4, normal gameplay-distance and close-up** board views. Include character near material for scale/style compatibility.
6. Quantify board thickness, density/scale of colour patches, view-distance readability, repetition/UV artifacts, material/shader cost, triangle/draw-call changes and any performance tradeoff.
7. Report findings first. Keep everything reversible and isolated; do not propagate changes throughout the town, overwrite production assets, or request paid generation without explicit approval.

## Success criteria

I should be able to look at the deck and say 'these are individual thick planks with actual cut wood at the ends, gaps, real long-grain and weight.' A post should read as one timber rather than a surface of camouflage squares. The wood, painted siding and facades must look at home in the approved saloon exterior and alongside the existing Godot characters. Avoid Minecraft-style voxels, watercolor, deliberately noisy pixels, photorealistic texture overload or generic game-material sheen.

Begin with a concise image-referenced diagnosis, proposed tests, and the minimal set of code/asset changes necessary. Generate controlled comparison sheets; stop for approval before integrating the winner.
