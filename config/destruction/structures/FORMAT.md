# structures/*.json: the masonry structure format (format 1)

Each test building is one file: its walls and timbers as **elements** and **what rests on what**,
in engine-neutral data (the portability rule, `docs/destruction/destruction-spec.md` section 1). Any engine reads
the same file and gets the same wall.

A file has two forms of the same thing:

- **Authored** (`walls`, `timbers`): the short form a person writes. A wall is a line, a height, a
  thickness, a material and its openings; the expander lays it in courses.
- **Expanded** (`elements`, `joints`): every element and joint, written out by the expander and
  committed with the file. **The expanded form is the one that carries** to another engine: it
  doesn't depend on any engine's random numbers. An engine reads `elements`; it needs the expander
  only to change a wall.

Step 1 defines the format; the expander is step 2's (a script in this repo, its rules written here
as it's built). Until a file is expanded its `elements` is empty.

## Space

Metres. `x` along the wall's line from its start, `y` up from the ground, `z` through the wall from
its outer face (0) inward (+). A building's walls are given in the building's own space (as Salt
Creek's building specs: `x` along the front from the west corner, `z` back from the front, the
front facing −Z); a lab piece's single wall runs from `[0, 0]` along +x.

## The top level

| Key | Means |
| --- | --- |
| `format` | 1 |
| `id`, `piece`, `_doc` | its name, its number in the lab's list of test pieces, what it proves |
| `seed` | the expander's seed (the stones' sizes and joints); same seed, same wall |
| `ground` | `{"y": 0}`: the height the lowest course and footings stand on |
| `walls` | the authored walls (below) |
| `timbers` | authored timbers: lintels, joists, beams, plates (below) |
| `loads` | weights set on elements that aren't elements themselves: a roof's dead load on a plate, `{"on": id or wall, "n": newtons, "at": [x, y, z]}` |
| `elements`, `joints` | the expanded form (below) |
| `swap_materials` | a lab piece made in every material: the materials it's run in (the thickness comes from each material's `wall.thick_typical` unless the wall gives one) |

## A wall (authored)

```json
{"id": "west", "material": "rubble_stone", "from": [0, 0], "to": [4, 0], "bottom": 0, "top": 3,
 "thick": 0.55, "footing": {"material": "rubble_stone", "deep": 0.3, "wider": 0.1},
 "openings": [{"id": "door", "x": [1.5, 2.5], "y": [0, 2.1], "lintel": "door_lintel"}],
 "quoins": "cut_stone"}
```

`from`/`to` are `[x, z]` of the wall's outer face line; `thick` inward from it. `openings` are
`x` and `y` ranges in the wall's own `x`; an opening names the timber (or a cut-stone lintel)
spanning it. `quoins`: the corners laid in another material (a bank's dressed corners).

## A timber (authored)

```json
{"id": "door_lintel", "kind": "lintel", "material": "timber_in_masonry", "wall": "west",
 "x": [1.25, 2.75], "y": 2.1, "section": [0.2, 0.2], "pieces": 3}
```

A lintel lies along its wall over `x`, its underside at `y`, `section` `[high, deep]`, laid as
`pieces` timbers side by side through the wall's thickness. A joist or beam gives its two ends
`[x, y, z]` in the building's space instead; each end bears on the wall it lands in.

## An element (expanded)

```json
{"id": "west/c03/w0/07", "material": "rubble_stone", "kind": "unit",
 "at": [2.31, 0.84, 0.14], "size": [0.38, 0.21, 0.27], "turn": 0.0,
 "course": 3, "wythe": 0, "shape": "rough/2", "rests_on": ["west/c02/w0/06", "west/c02/w0/07"]}
```

- `id`: `<wall>/c<course>/w<wythe>/<index along the course>`; a timber's own id.
- `kind`: `unit` (a stone, block, adobe or brick clump), `through` (a through-stone across the
  wythes), `lintel`, `joist`, `beam`, `plate`, `footing`.
- `at` is the box's centre and `size` its `[along, high, deep]` in the wall's space; `turn` degrees
  about the vertical (a building's walls).
- `shape`: which pre-cut set and variant draws it (the engine's meshes).
- `rests_on`: the elements under it across its bed joints, or `["ground"]`.

## A joint (expanded)

```json
{"a": "west/c03/w0/07", "b": "west/c02/w0/07", "type": "bed", "area": 0.061, "mortar": "lime"}
```

`type`: `bed` (a on b), `head` (side by side), `collar` (wythe to wythe). `area` in m². A file's
saved state (broken joints, fallen elements) is never written here: a save holds the difference.
