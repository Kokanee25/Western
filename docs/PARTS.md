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
| A stair walked by a ramp but fallen down tread by tread (the ramp only stops walkers, `Layers.WALK`) | `src/bodies/layers.gd`, the saloon stair | ragdoll lab, round 4 (`tests/test_stair_ramp.gd`) | in the game |
| A falling man breaks the timber he hits (`BodyImpacts`: his speed past what breaks it carries on; trim gives way at its nails; a freed upright held by its nails in proportion to its section) | `src/structures/body_impacts.gd` | ragdoll lab, round 4 (`tests/test_body_impacts.gd`, groups Q and T) | in the game |
| Breakable railing: balusters on whatever floor is under them (a balcony, a stair's treads), the rail on them in spans of up to 1.2 m, each its own member; a body breaks the span it hits and carries on through | `src/structures/railing.gd` (`Railing.build`), used by the saloon's balcony and stair rails (`src/art/saloon_dressing.gd`) and the ragdoll lab's 1 m railing | ragdoll lab groups Q and T against it (round 4), `tests/test_railing.gd` | in the game |

## Bodies and people (gameplay; characters for the men)

| Part | Where it lives | Proven by | Status |
| --- | --- | --- | --- |
| Anatomy, physiology, wounds, severing | `src/bodies/` (`Anatomy`, `Physiology`, `HumanBody`) | tests | in the game |
| The ragdoll falls (rounds 1 to 3) | `src/bodies/human_body.gd` | ragdoll lab (`experiments/physics_lab/`) | in the game |
| The faint | `src/bodies/human_body.gd` | ragdoll lab | on a branch (`claude/gameplay-faint`) |
| Field first aid: pressure, tourniquet, bandage (the player's tend key; outlaws tend themselves) | `src/bodies/physiology.gd`, `src/player/player_wounds.gd`, `src/people/outlaw_brain.gd` | tests | in the game; the treatment lab widens it |
| Senses, deeds, relations, the escalation ladder, the gang's crew | `src/people/` | tests | in the game |
| A working face (mouth, lips, teeth, lids, jaw, 12-15 shapes, Live Link takes, `FaceGaze`) | `tools/faces/`, `bold_cowboy_talking` | face rig brief (`docs/briefs/face-rig.md`) | in the game on the old layered cowboy only; the face rig lab brings it to the Studio's men |
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

## Fire (art draws it; gameplay's `FireSystem` and `FireFX` spread and place it)

| Part | Where it lives | Proven by | Status |
| --- | --- | --- | --- |
| The drawn fire sheet (one noise field of tongues a burning member, in the painting's bands) | `src/fire/fire_sheet.gdshader`, placed by `FireFX._sheet_on` | the judge's fire view (`livery_fire_dusk`) | in the game (the default) |
| The fire flipbooks: a lick, a tongue and a big column, each 64 looping frames baked from a Mantaflow fire, with motion vectors (R flame, G smoke, B heat) | `assets/textures/fire/`, made by `tools/textures/fire_sim/` (`bake_flames.py`, `make_sheets.py`, `flames.json`) | `tests/test_fire_flipbooks.gd` (whole, loop seam like a step), `tools/flame_views.gd` | in the game behind `Settings.fire_flipbooks` (off; look panel N, `--fire-flipbooks`), waiting on Sean's A/B; the final painted pass after Gate A |
| The flipbook flame shader: motion-vector frame blending, a core in the painting's bands that keeps its hue, alpha-blended tips and smoke, soft edges at walls and floors, heat haze | `src/fire/fire_flipbook.gd` (`FireFlipbook`), `flipbook.gdshaderinc`, `flame_core`/`flame_tips`/`flame_haze.gdshader` | `tools/fire_cost.gd` (a building fully alight), `tools/fire_ab.gd` (the A/B film) | as above; uses FireFX's sheets as they are (same quad, same instance uniforms) |
| The fire painting's colours (its fire's tones, edge to root; its smoke dark and lit) | `assets/textures/fire/fire_ramp.png`, `fire_sheets.json` (from `docs/concept/livery-fire-painted.png`) | `make_sheets.py` | in the game with the flipbooks |

## Props (the prop lab, `docs/briefs/prop-lab.md`)

| Part | Where it lives | Proven by | Status |
| --- | --- | --- | --- |
| The 12 drawn props (card table, chair, bar stool, piano, barrel, spittoon, oil lamp, whiskey bottle, tin cup, deer head, framed painting, wall sconce) | `assets/props/manifest.json`, `src/props/prop_library.gd`, `src/props/prop_models.gd` | the judge's shots | in the game, solid (one collision box, can't break or burn); targets for their kit versions |
| Buildings' hand-built furnishings (store, telegraph, doctor, bank; the saloon's bar) | `FalseFrontBuilding._furnish_*`, `src/art/saloon_dressing.gd` | tests | in the game, as members; to be brought into the kit |
| Water: buckets, the bucket line, dousing, wet members | `src/fire/`, `src/people/bucket_line.gd` | tests | in the game; the water lab adds liquid in containers, spills and the flood |
| A smashed lamp spills burning oil | `src/structures/fittings.gd`, `src/fire/` | tests | in the game |
| The prop kit (one data file per prop: members, shatter or fitting) | — | — | not started: the prop lab's first job |

## The Systems Playground

The test saloon (`docs/briefs/labs.md`, "The Systems Playground"): the game's own saloon and a
stretch of street, built only from parts marked **in the game** above, with every approved system
on. When a part is promoted, the playground takes it in its next merge.
