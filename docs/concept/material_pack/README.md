# Salt Creek — Material Lab Reference Pack

**Purpose:** Feed Claude both the pictures and the prompt, so the next iteration fixes timber posts, deck-board mass, board end-grain, floor texture repetition and siding, without art-direction drift.

## How to use

1. Attach the **entire ZIP** to Claude, or unzip and attach its images and `CLAUDE_PROMPT.md` if Claude cannot browse ZIP attachments.
2. Say: "Read `CLAUDE_PROMPT.md`, inspect all provided photos and screenshots at their actual sizes, and follow the reference priority. Continue our existing Salt Creek Material Lab experiment."
3. Make Claude explicitly distinguish the APPROVED art target (folder `01_APPROVED_STYLE`) from EXISTING/FLAWED renders (folders `03_EXISTING_MATERIAL_LAB` and `04_DEFECT_CLOSEUPS`).
4. Ask for matched geometry/material A-B-C comparison images before allowing production integration.

## Reference hierarchy

- `01_APPROVED_STYLE/approved_saloon_exterior.png`: approved modernized 3D environment style and material quality. Style target, not a construction blueprint.
- `01_APPROVED_STYLE/current_character_*.jpg`: actual character style target; cropped from user-provided Godot screenshots.
- `02_WOOD_REFERENCE_SHEET`: original wood-sheet samples extracted from Material Lab's existing sheet-to-lab comparison (not untouched separate physical photographs). Use their *wood language* (grain, edge wear, coherent colours), not necessarily their exact painted resolution.
- `03_EXISTING_MATERIAL_LAB`: before/current tests and scale chart. Evidence / calibration only.
- `04_DEFECT_CLOSEUPS`: cropped existing and new material tests, with `existing_left` meaning older wood and `lab_right` meaning the experimental wood; both have issues to correct. It also contains target saloon crops.
- `REAL_WORLD_PHOTO_LINKS_AND_CREDITS.md`: physically realistic lumber-reference links for end-grain, posts, boardwalk and joints (linked only; image bytes not bundled).

**Avoid copying undesirable examples:** old Minecraft/voxel/watercolor Saloon concepts are intentionally excluded. The approved 3D exterior is the anchor.
