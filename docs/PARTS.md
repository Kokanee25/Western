# Salt Creek: the parts list

Sean, 2026-10-21: **labs measure; parts live in the game.** A lab may build anything to test with,
but nothing it makes counts as done until it's **promoted**: written into the game's shared code
or assets, where every lab, building and scene can use it. This list is every part that has been
promoted, or is waiting to be.

- **Read it before building anything new.** If a part exists, use it; never make a second one.
  If it nearly fits, extend it (and say so here).
- **The test saloon (the Systems Playground) uses only parts marked "in the game"**, never a
  lab's fixtures.
- **A lab's merge updates its rows here:** what it promoted, where it lives, and what proved it.
  A part still inside a lab is listed as "waiting to be promoted", with what promoting it needs.
- Owners are the lane whose files it lives in (CLAUDE.md "How we work").

Status words: **in the game** (on main, used by the game) · **on a branch** (built, not merged) ·
**waiting to be promoted** (a lab fixture or lab set) · **waiting on Sean** (needs his pick).

## Structures (gameplay)

| Part | Where it lives | Proven by | Status |
| --- | --- | --- | --- |
| Members and the support graph: load paths, breaking, settling, rubble | `src/structures/structure.gd`, `structure_member.gd`, `structural_analysis.gd`, `config/timber.tres` | tests, the timber numbers (USDA Wood Handbook) | in the game |
| Voxel carving: bullet holes, spall, torn faces | `src/structures/voxel_works.gd`, the native plugin, `config/voxel_damage.tres` | tests | in the game |
| Fittings: props and lamps fall when what holds them goes | `src/structures/fittings.gd` | tests | in the game |
| False-front buildings (store, telegraph, doctor, bank, livery shapes) | `src/structures/false_front_building.gd` | tests | in the game |
| The saloon building | `src/structures/saloon_building.gd` | tests | in the game |
| The saloon's stair and corner balcony, as members (posts, beam, ledger, joists) | `src/art/saloon_dressing.gd` (art builds it, as members) | tests | in the game |
| Boardwalks with steps and walking ramps | `src/structures/boardwalk.gd` | tests | in the game |
| Hitching rail, water trough, well, windpump, corral | `src/structures/` | tests | in the game |
| A stair walked by a ramp but fallen down tread by tread (the ramp only stops walkers, `Layers.WALK`) | `src/bodies/layers.gd`, the saloon stair | ragdoll lab, round 4 (`tests/test_stair_ramp.gd`) | on a branch (`claude/gameplay-falls-props`) |
| A falling man breaks the timber he hits (`BodyImpacts`; a freed upright held by its nails in proportion to its section) | `src/structures/body_impacts.gd` | ragdoll lab, round 4 (`tests/test_body_impacts.gd`) | on a branch (`claude/gameplay-falls-props`) |
| Breakable railing (posts, rails, balusters that a body breaks through) | the ragdoll lab's 1 m fixture (group Q) | ragdoll lab, round 4 | waiting to be promoted: a railing part in `src/structures/` built from members, used by the saloon's balcony and stair, and any building's |

## Bodies and people (gameplay; characters for the men)

| Part | Where it lives | Proven by | Status |
| --- | --- | --- | --- |
| Anatomy, physiology, wounds, severing | `src/bodies/` (`Anatomy`, `Physiology`, `HumanBody`) | tests | in the game |
| The ragdoll falls (rounds 1 to 3) | `src/bodies/human_body.gd` | ragdoll lab (`experiments/physics_lab/`) | in the game |
| The faint | `src/bodies/human_body.gd` | ragdoll lab | on a branch (`claude/gameplay-faint`) |
| Field first aid: pressure, tourniquet, bandage (the player's tend key; outlaws tend themselves) | `src/bodies/physiology.gd`, `src/player/player_wounds.gd`, `src/people/outlaw_brain.gd` | tests | in the game; the treatment lab widens it |
| Senses, deeds, relations, the escalation ladder, the gang's crew | `src/people/` | tests | in the game |
| The Studio's men: `bold_cowboy_s0`, `old_rancher_s1`, `young_drifter_s1`, `sean_s2` | `assets/people/` | `works_check.gd`, `test_bodies.gd` | in the game (cast as the gang, the storekeeper and the sheriff) |

## Materials and look (art)

| Part | Where it lives | Proven by | Status |
| --- | --- | --- | --- |
| The game's woods (the timber pass's C) | `assets/textures/`, `src/structures/wood_materials.gd` | material lab, 2026-10-15 | in the game |
| The weathering layer (stain sheet: mud and bleach laid in the structure's space) | `src/render/texel_grid*`, `tools/textures/stain_sheet.py` | material lab, rounds 3 and 4 | in the game (used by lab sets so far) |
| The Studio woods (round 4, set `studio7`) | `assets/textures/mlab_*`, `tools/textures/material_lab.json` | material lab, round 4 (critic: 1 same, 7 close, 0 different) | waiting on Sean (his picks on `round4_sheets/`), then promoted into the texture factory's game set |
| Worn treads (nosings worn by feet) | the oak stair and the stand's steps | material lab | in the game |
| The hotel's oak stair, painted oak and runner (`dark_oak`, `stair_runner`) | `src/art/oak_stair.gd` (drawn only) | material lab | in the game as a drawing; waiting to be promoted as members when the hotel is built |
| The test stand | `src/art/material_stand.gd`, `tools/material_lab.gd` | — | a lab fixture (stays in the lab) |

## The Systems Playground

The test saloon (`docs/briefs/labs.md`, "The Systems Playground"): the game's own saloon and a
stretch of street, built only from parts marked **in the game** above, with every approved system
on. When a part is promoted, the playground takes it in its next merge.
