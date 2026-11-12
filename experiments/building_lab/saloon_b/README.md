# Saloon B, the corner saloon (#772, #848): step 1, the spec and the frame

Art lane, the building lab. Sean picked concept B (PR #772; his nine answers are in
`docs/briefs/saloon-design.md` "Sean's answers (2026-11-10)"). Two steps: **this one, the spec and
the frame on its corner lot, judged for being built right**; step 2 the finishes, light and judges.

| File | What |
| --- | --- |
| `concept.json`, `sheet/` | the target: B's plans and three views (PR #772) |
| `saloon_b.json` | the spec (format 1, `../FORMAT.md` "Saloon B's parts") |
| `results/xray.jpg` | the frame drawn from the built members (`tools/buildings/xray.py`) |
| `results/2026-11-12_frame/` | the lab's renders: the four sides and the well from the gallery |
| `render_frame.gd` | those renders (one lavapipe run, `--game-args=--real`) |

## The building

54 x 72 ft (16.46 x 21.95 m), two storeys, 13 ft floor to floor below and 11 ft above, on the
north-side corner lot: it faces south, so its x runs from its **east** corner (the yard) to the
North-South Street. Walls by what they face: `front`, `side`, `yard`, `back`.

- **Ground:** the bar room 54 x 44 ft, entered at the corner; the bar down the yard wall (three kit
  sections, the back bar four) under the east girder's panel; the card tables under the well by the
  side street's windows (No Law's is `no_law_table`). Behind the bar room's back wall: the stair
  hall with its own door on the side street, the gaming room through a wide arch, the kitchen and
  its lunch hatch, the store room with the trap. The cellar (16 x 46 ft, narrowed from the concept's
  20 so the girder's posts stand on solid ground) under the bar's back half and the store room.
- **Upper:** the dance hall 36 x 44 ft over the bar on open 3x12 joists at 12 in, two lines of 10x12
  girders on 8x8 posts; the owner's office over the corner; the **open well 14 x 22 ft** over the
  card tables, a 36 in rail round it, a 4 ft gallery along the side street's wall; the upper hall
  and four rented rooms behind; a door to the outside stair's landing in the yard.
- **The corner:** cut off 8 ft each way (the walls' `void` openings), the upper floor carried over
  it on a beam each way to one iron column; glazed double doors and a transom in the diagonal wall.
- **The balcony** wraps the corner, 54 ft on Main Street and 44 ft down the side street, 8 ft deep
  on ten 6x6 posts, a beam a bay; under it Main Street's walk and a boardwalk down the side street
  (`lot.side_walk`), past the stair hall's door.
- **The roof:** queen-post trusses across the 54 ft, a low 2/12 behind the street's cornice.

## The girder the Baron's men saw

`sabotage` names it: `beam/east/2`, the east girder's piece between the posts at 22 and 33 ft,
beside the bar. `tests/test_building_saloon_b.gd`:

- **uncut**, with a dancing crowd on the floor (70 lb/ft2, Hatfield), the game's own settle breaks
  nothing;
- **cut** (`SpecBuilding.saw_girder`: a kerf through its middle, `Structure.cut_member`), its two
  halves tip off their posts and its 22 joists hinge down, one bay on the yard wall's ribbon, the
  other on the west girder, with the 72 boards on them and the stretch of the well's rail that
  stood there: a panel 11 ft along the girder and 18 ft each side, over the bar and the men at
  it. Nothing outside the panel gives (the other girder pieces, the trusses, the walls stand).

What made it fall and not hang: see `../RECIPE.md` "A collapse on purpose needs room to fall".
For Payday Night (gameplay's): put the dancers' weight on the dance floor's boards
(`extra_load`), call `saw_girder()` when the floor is to go, and let the structure settle. A girder
only half sawn holds in the game as in the brief (the analysis gives the sound girder 0.15 of its
limit under the crowd): the mission cuts it through at its moment.

## What the checks say (`tests/test_building_saloon_b.gd`, nine tests)

RESULTS

## Not in step 1 (for step 2 or its owner)

- **The hip and the side street's cornice.** The roof is a plain 2/12 on trusses, its gables to the
  yard and the side street behind boards; the bracketed cornice is on Main Street only.
- **The cellar's bulkhead to the yard** (the concept's 5) and the cellar dug in the valley: the
  valley's ground isn't opened under the building yet (#695), so on its lot the cellar's members
  stand in the ground. In the lab the pit is open and the trap's stair reaches it.
- **No Law's set stays in the yard.** See "No Law" below.
- **Finishes, paint, the sign's lettering, the look of the posts and stair**: step 2. The spec
  names passing library entries so the frame draws (oxblood board and batten, buff trim, pale
  boards inside, the worn fir floor).
- **Props**: the bar and back bar are the kit's sections and four card tables with chairs; the
  rest is the prop lab's (`docs/briefs/saloon-design.md` "The props B needs").
- **Working doors**: every leaf stands open (the format's item 13).

## No Law

NOLAW
