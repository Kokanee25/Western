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

Step 1 defined the format; step 2 wrote the expander (`src/structures/masonry_expander.gd`, run by
`tools/masonry_expand.gd`; its rules are under "The expander" below). Until a file is expanded its
`elements` is empty.

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

## The expander (format 1, masonry lab step 2)

`godot --headless -s res://tools/masonry_expand.gd -- res://config/destruction/structures/<file>.json`
writes the expanded form back into the file (`--check`: says whether it's current; a test holds
the committed panel to it). The rules, so another engine can lay the same kind of wall (it can't
reproduce Godot's random numbers, so it reads the committed `elements` instead):

- **One random stream per file**, seeded by `seed`, drawn in this order: each wall in file order:
  its footing's stones along it, then course by course: the course's height, its first leaf's
  stones, which of them are through-stones, then each other leaf's stones.
- **Element size** from `materials.json`: `unit.size` × `element.units_along`/`units_high`
  (`a` along, `h` high); `size_jitter` `j`.
- **The footing** (`footing`): one course under the wall from `bottom - deep` to `bottom`, from
  `-wider` to `thick + wider` through it, of stones about `2a` long; resting on the ground; head
  joints between them. Course 0.
- **Courses**: from `bottom` up, each `h × U(1 - j/2, 1 + j/2)` high; a course that would leave less
  than `0.6 h` to the top is stretched to the top. Courses 1, 2, ...
- **Leaves** (wythes): `wall.wythes` of them, each `thick / wythes` deep, wythe 0 at the outer face.
- **Stones along a course** (each leaf): from x = 0, each `a × U(1 - j, 1 + j)` long; an end within
  `0.25 a` of a head joint in the course below (in that leaf) is moved `0.25 a` off it (up to three
  times); never shorter than `0.5 a`; a remainder under `0.5 a` goes into the stone before it. Openings
  this course crosses, and through-stones, cut a course into stretches laid the same way.
- **Through-stones**: each of the first leaf's stones becomes one (the wall's full depth) with
  probability `through_stones_per_m2 × its face area`; the other leaves are laid between them.
- **`rests_on`** and **bed joints**: every element of the course below whose box overlaps it in plan
  by more than 1 mm both ways; the bed joint's `area` is that overlap. The first course rests on the
  footing (or the ground, `["ground"]`).
- **Head joints**: two elements of a course whose ends meet (within 1 mm) and whose depths overlap;
  area = the course's height × the depth overlap. **Collar joints**: two elements of a course in
  touching leaves whose lengths overlap; area = the height × the length overlap.
- **Boxes tile the wall**: an element's box includes half the mortar joint all round (the joint is
  drawn as a groove, `joint_thickness`); `at` and `size` in the file's space, `turn` the wall's angle.
- `shape`: `<unit.shape>/<0..3>` (`footing/<0..3>`): the variant the engine draws.
- Numbers rounded to 4 decimals. Not yet: timbers (lintels are test piece 2's, step 3), quoins,
  `swap_materials` (step 4).
