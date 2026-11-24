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
Round 6 (2026-11-23, #1170, the second form pass): **the belfry** a pointed bell opening on each face between jamb posts (stepped
boards to the slant, a slanted casing; the jambs carry the ring's mid-span where the commons land), a louvred panel either side,
a **flared skirt** (45 then 15 degrees, the lower pitch on a ledger laid on the walls' plates: hung off the upper one it failed
"joint" at 3.7), the spire 7 m and **bell-cast** (a kick on the seat beams), a 1.8 m finial; **the front** pointed double doors
(a door's `pointed`/`rise`: SashWindow's head glazed over the leaves), a shingled **hood** on two brackets, iron **handrails**;
**the shape** 45 degree roof, the plate 5.3 m, the windows 0.85 m off the floor with 0.8 m pointed heads, the chimney taller;
**the side wall** boxed eaves (fascia, soffit, frieze), wide casings (0.14 m) with a drip cap on each arch and thick stools,
the lap course over each apex filled (the dark strip); **inside** a period pew (scrolled ends, two-board seat, panelled back,
book rail; painted), a white box pulpit, a plain rail, the hymn board's cards, the stove pipe to the ceiling; **the cemetery**
in close rows (34 graves in the old rows at the back; the rest of the sites left free for the game's dead, `Cemetery.free_plots`, `claim_plot`), heavy crosses with name boards, arched headstones, round-topped headboards, 1.3 m
pickets at 0.15 m (square-topped: cut points made each its own mesh and the view ran past 30 min), the mounds low and dry. Renders `results/2026-11-23_r6/`, judged in `docs/screenshots/judge/2026-11-23_church_r3/`.
Not done (the judge's wall notes 2, 3, 5): patchy paint, lapped clapboards' shadow lines and wavy old glass are the shared siding
(`LAP_BOARD_H`, every lap-sided building) and the shared glass shader: a material-library job of their own.

Round 7 (2026-11-23, #1203, Sean on #1202: "an open ceiling with trusses, see how it looks"): **the nave open to its roof**.
The loft and its 3x15 in ceiling joists are gone (their ends poked through the 45 degree roof at the eaves: the wall judge's
orange row). Four **queen-post trusses** at 2.68 m bays (`frame.trusses`, `SpecBuilding._queen_trusses`): a 6x8 tie on the
side walls' plates (its ends under the boards), 6x8 principals, 6x6 queen posts at the thirds and a straining beam; two 4x6
purlins a side carry the commons (none where a truss stands, no collars). The gables boarded on up to the roof inside
(`inside_finish.gables`); the roof's boards butted (`roof_tight`: the 5 mm rows showed the sky). **Lamps**: the nave's four
wall brackets replaced by three `hanging_lamp`s on chains from the ties over the aisle (`lamps.kit` `hang`; 17-23 h, they
fall with their tie). The stove pipe now turns at an elbow into the chimney (no ceiling to go through). Renders
`results/2026-11-23_r7/` (with `nave_lit`, the nave at 20:30), judged in `docs/screenshots/judge/2026-11-23_church_r4/`:
critic 0 SAME, 3 CLOSE (nave, pulpit, side); the wall judge 6/10, the joist ends gone. The critic reads the target's nave
as a flat white board ceiling with white tie beams under it: the open dark roof is a difference too (Sean's call, see the
status entry's issue).

