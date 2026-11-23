# The undertaker's props, batch U1 (#1181)

`tools/props/undertaker.py` writes the kit files (29 props, members only: library woods, the kit's bare iron,
brass, tin and cloth looks, `glass:` tints; **no Blender**, no `bpy` in the session that made them).
`experiments/building_lab/undertaker/make_spec.py` places them (batch `U1` of his spec's `dressing`; re-run it,
never the JSON by hand). The period notes and what the building holds: `experiments/building_lab/undertaker/README.md`.
`tests/test_undertaker_props.gd` (each stands, weighs, is handed out; the hung ones have their nails; the batch's
member count and every look known).

## What each is, and against what

| Prop | What | Reference |
| --- | --- | --- |
| `coffin_hex`, `coffin_hex_open`, `coffin_lid` | the six-sided toe-pincher (1.95 m, shoulders 0.58), closed / open with a lined bottom and pillow / its lid alone; walnut, a moulded lid with a brass plate, brass bar handles | Habenstein and Lamers, *American Funeral Directing* (1955); the Smithsonian's and Bowers Museum's toe-pinchers |
| `coffin_rect` | the rectangular casket (2.0 m), raised lid moulding, handles | as above (coming in, 1880s) |
| `coffin_child` | a child's coffin, white-painted pine, 1.05 m | the undertaker's notes (README): a child's often white |
| `trestles`, `bier` | sawhorse pair 0.56 m; the parlour's bier: two trestles, two boards, a black cloth hung over with weighted hems | period bier cloths were black wool or crepe |
| `workbench`, `tool_rack`, `glue_pot`, `plank_stack` | the cabinetmaker's bench (oak top, quick-screw vise, dogs, a jack plane, saw and mallet on it), a peg board of saws, planes and a square, a hide-glue pot, seasoning boards on stickers | Roubo and the joiner's bench of the Peterborough museum; the 1880s Sears catalogue |
| `embalming_table`, `zinc_pail` | planed pine, a zinc-lined top sloping a degree to a drain at its foot; a pail under it | Renouard, *Undertakers' Manual* (1878); README: wood tables, porcelain is 1890s on |
| `cooling_board`, `sheeted_board` | the slatted board on splayed legs; the same with a sheet over it (lumps, nothing under) | Renouard 1878 |
| `embalming_pump` | a stand with a hand force-pump, red rubber tubes, an aqua jar and an amber bottle | arterial embalming by hand pump after the Civil War |
| `carboy`, `fluids_shelf`, `shroud_shelf` | a green glass carboy in a slat cradle; a shelf of jars and bottles; a shelf of folded muslin shrouds | the undertaker's stock |
| `ice_bin`, `corpse_cooler` | a plank box of ice blocks in sawdust; the zinc-lined cooler on legs with an ice pan and two blocks | corpse coolers sold from the 1870s |
| `coffin_rack` | two-tier racking for coffins, 1.55 m | |
| `safety_coffin` | a casket with a frame of two posts and a beam at its head, a brass bell and a cord from the lid | Vester's patent 81,437 (1868); a sample, plausible not common |
| `posing_stand`, `posing_chair` | the photographer's iron head-rest stand; a walnut chair with a dark cloth over its back. Never a body in it | README: the stand held the *living* sitter still |
| `hair_wreath` | a hair wreath in a deep walnut shadow box under glass | Victorian mourning work |
| `iron_lantern` | a sheet-iron lantern hung by its ring on a hook | |
| `hearse` | the box hearse: the buckboard's running gear stretched, pine deck, black body with glass sides, a roof with plumes in a cup at each corner, the driver's box | Habenstein and Lamers; Sayers & Scovill and Concord hearse catalogues |
| `harness_rack` | a leather horse collar with hames and a bridle with bit on a peg board | Montgomery Ward 1880s |

Nothing is made up beyond that: no photograph's "dead man posed on the stand", no porcelain table, no rubber hose
before the 1840s (it was there). What I could not source in this session (the archives are blocked here) is a
photographed reference for each: the prose above is from the period notes, not from a looked-at picture.

## Where each goes (building space: x west from the east corner, z back, y over the floor; cellar flags at -2.67)

Parlour: bier at (1.6, 2.9) facing 90 with `coffin_hex_open` on it (y 0.59); the wreath on the wall (3.19, 1.5, 2.0).
Showroom: three trestles at (4.3, 2.2), (6.0, 1.5), (8.9, 2.0) carrying casket, toe-pincher and the child's.
Workroom: bench (7.8, 5.92), its tool rack on the front wall (7.8, 1.6, 5.5), lid on trestles (1.0, 7.6), planks (9.3, 8.2),
glue pot on the stove (8.9, 11.3). Cellar, embalming room: table (7.6, 13.4) facing 270 (drain to the back wall, pail at
14.42), pump stand (8.6, 11.95), carboys at the west wall (9.05, 12.8 and 13.4), the fluids shelf on the cross wall (8.6, 11.32),
shrouds on the back wall (6.3, 14.55), the sheeted board (4.6, 14.35). Ice room: the bin on the back wall (2.25, 14.3), the
cooler along the east wall (0.85, 13.2) (the thick door's way in stays clear). Coffin store: the rack on the cross wall
(1.9, 10.4) with a toe-pincher below and a casket above, the safety coffin along the west wall (8.85, 8.7) facing 90, the
posing stand (7.75, 10.7) behind its chair (8.35, 10.7), the lantern on a hook in the east girder (6.47, 7.95). Yard: the
hearse in the shed (-9.4, 15.85) facing 270 (driver's box to the doors), the harness on the stall's back wall.
The first placement of the safety coffin stood across the walk from the bulkhead to the stair's foot: the test
(`test_a_man_walks_down_into_the_cellar_and_up_the_bulkhead`) caught it; it lies along the west wall now.

## What stands in, and what's open (written without seeing them: no render of the whole batch was judged)

- **Rendered once, not judged** (two valley views, `results/parlour.jpg`, `results/embalming.jpg`, 2026-11-23; ~40 min
  each under lavapipe): the parlour shows the open toe-pincher on the bier, its drape and the hair wreath, the wreath
  reading as a flat brown plaque (its hair ring and glass are too dark to read from the room: a lighter wreath, a
  visible glass sheen); the embalming room shows the table with its zinc top near-black green-grey and the shelves, the
  cellar dark and lamplit. **No stand sheet, no cheap judge, no blind critic** for this batch: the other four valley
  views the issue lists (workroom, coffins, ice, yard: the hearse) were not rendered. That is the next session's.
- The lantern and the hair wreath hang on nails like the doctor's pegs: the lantern doesn't swing (a GlassProp needs
  a baked model: no Blender here), the real `hanging_lamp` is the model for a swinging one.
- Glass (jars, carboys, hearse panes, the lantern's) is a kit member of kind `glass` drawn by a lathe or a cut, not a
  `GlassProp`: it breaks as a member, doesn't spill what it holds.
- The sheeted board is a sheet shape over slats: a body is gameplay's (the bier and the board are where one lies).
- No upholstery on the bier's coffin lining, no ice melt, no drip from the drain.

## Used and grim (Sean's add-on, 2026-11-23)

Wet sawdust heaps (`sawdust_wet`, dark) at the embalming table's feet and under its drain, pale ones (`sawdust_pale`)
swept into two corners, `rags` by the pail, `mop_pail` (a mop in pinkish water) by the table; the pail stained inside
(tide-line, dregs), the sheeted board stained through in patches (the shroud shelf stays clean), the table's zinc dulled
with dark and pale streaks. Heaps are small and few, the floor between left clear: **no blood splats or floor stains**,
those come from the building's history (#1187). Looks only (no new texture): the stains are the kit's dark and pale
hide looks drawn as thin boxes, so how they read is for the judge.
