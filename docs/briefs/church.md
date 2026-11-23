# The church and cemetery (#1142; the building lab)

Goal: a white frame church with a three-stage bell tower and spire over its door, pews, pulpit, stove, lamps, hymn
board, and the cemetery beside it (picket fence and gate, crosses, headboards, a few stone markers, the funeral's
fresh grave). Sean 2026-11-21 and 2026-11-22: sheet approved ("good to go"). Form: gable front facing south-east onto
Church Lane, plain rectangle nave 28 x 44 ft, tower 10 ft square over the porch, weathered white, west afternoon light.

Step 1 done: `experiments/building_lab/church/sheet/` (11 views, $1.54). Sheet faults the spec settles: the side view
invents a wing (the plan has none); the tower is slimmer than the plan's porch.

## What the builder and kit lack (found 2026-11-22, grep of `spec_building.gd` and `docs/PARTS.md`)
- **No tower, belfry or spire.** `levels.roof_pitch` gives one gabled roof of common rafters; there is no hip or pyramidal
  roof, no louvred opening, no bell. The spire is the new kind of structure (hence Opus). Build it as parts in
  `src/structures/` (a hip roof from four rafters to a finial, a belfry with louvres, a `Bell` that rings and falls with its yoke).
- **No pointed (Gothic) window.** Windows are rectangles with `lights`; only partitions take an `arch`. Add a pointed head
  to a window opening (sash and lined reveal follow its curve) or draw it as a rectangle sash plus a pointed trim piece.
- **No kit props** for pews, pulpit and altar rail, hymn board, wooden crosses, headboards, stone markers, a bell; `stove`
  and `reflector_lamp` exist. Order them from the prop lab's recipe (`docs/lanes/props.md`).
- `config/valley.json`'s church (at [-62,-135], pad 12 x 20 y 7.5) and cemetery (at [-95,-195], pad 40 x 30) are plain
  pads and a `bell_tower` view place with blocks (4 x 4 x 10 tower, 1.6 m steeple to 15 m: set the tower to 15.2 m, ladder inside).
  `src/missions/funeral.gd` builds the graveside from stand-in blocks (`old_graves`, `OpenGrave`, `GraveEarth`, `GraveBoard`): replace
  them with the cemetery's real props, keeping `tests/test_funeral.gd` green. Re-bake with `valley_plan.py --bake`.
- Harlan's homestead (#1126) edits `src/structures` for log walls: merge main in first and keep tower code in its own file.
