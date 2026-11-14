# docs/destruction: masonry destruction, the engine-neutral part

What carries from Salt Creek to Normandy 1944 (and Unreal): the rules and the numbers, apart from
Godot's code. The documents are here; the data the game reads is in `config/destruction/` (`docs/`
is left out of Godot's import and export by its `.gdignore`, so an exported game can't read it). Sean's brief for the lab is `Salt_Creek_Masonry_Destruction_Lab.pdf`; the Salt Creek
side (how the lab sits on the game's structures, its steps, lanes and traps) is
`docs/briefs/masonry-lab.md`.

| File | What |
| --- | --- |
| `destruction-spec.md` | the rules in plain English, kept current |
| `config/destruction/materials.json` | the numbers per material (adobe, rubble stone, cut stone, fired brick, timber in masonry) and mortar |
| `config/destruction/structures/` (`FORMAT.md`, `*.json`) | each test building as elements and what rests on what |
| `benchmarks.md` | each test scene, its target and every result |
| `references/` | where the photos and video of real failures live (and their index) |

Copy this folder (but `step2/`) and `config/destruction/` into the Normandy repo when that starts. `step2/` is older:
the voxel destruction brief's step 2 renders (`docs/DESTRUCTION_BRIEF.md`), not the masonry lab's.
