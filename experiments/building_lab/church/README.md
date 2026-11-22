# The church and cemetery (#1142)

Step 1 (the target sheet): `sheet/` (11 views, $1.54; Sean's calls 2026-11-21: tower over the door, late light from the west, weathered white; the
sheet's faults: the side view invents a wing, the tower is slimmer than the plan's porch).
Step 2 (the spec): `config/buildings/church.json`, written by `tools/buildings/church_spec.py` (a 28 x 44 ft nave, a 10 ft tower, 9/12 roof;
pews, a chancel platform, the stove and its chimney, lamps). Step 3 (the build): `src/structures/church_tower.gd`, `tests/test_building_church.gd`.
The props: `tools/props/church.py`. The cemetery: `src/world/cemetery.gd`. The lot: valley.json `church` (pad moved to [-62, -141]).
Simplifications to judge: pointed heads over rectangular sashes; the spire flush with the belfry (no eave); no skirt roof between the clapboard and the belfry.
