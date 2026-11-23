# The church and cemetery (#1142)

Step 1 (the target sheet): `sheet/` (11 views, $1.54; Sean's calls 2026-11-21: tower over the door, late light from the west, weathered white; the
sheet's faults: the side view invents a wing, the tower is slimmer than the plan's porch).
Step 2 (the spec): `config/buildings/church.json`, written by `tools/buildings/church_spec.py` (a 28 x 44 ft nave, a 10 ft tower, 9/12 roof;
pews, a chancel platform, the stove and its chimney, lamps). Step 3 (the build): `src/structures/church_tower.gd`, `tests/test_building_church.gd`.
The props: `tools/props/church.py`. The cemetery: `src/world/cemetery.gd`. The lot: valley.json `church` (pad moved to [-62, -141]).
Round 4 (2026-11-22, #1142's second session): **pointed heads are the window's own** (`SashWindow.pointed_head`, a window's `rise`): the opening
cut to the apex, the two sashes under a transom at the springing, a fixed head sash over it (slanted stiles, a bar, a pane a step each side),
the reveal lined with slanted boards, the wall's corners each side filled with stepped siding and finish boards, a slanted casing outside
(`results/2026-11-22_r4/window.jpg`). **Shingles:** library entry `shingle_pine` (SH1; scan_wood's `shingle_w`: a course a board, each shingle
its own place in the scan), judged on the material lab's panel before it goes on the roof and spire. Views `window`, `graveyard`, `grave` added.
