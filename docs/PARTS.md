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
| The ground, made ready to be dug: flat slabs and one mesh where it's never been dug, a 5 cm height field in 3.2 m tiles where it has (`docs/briefs/dig-ground.md`) | `src/world/ground.gd` (`Ground`), `ground_tile.gd`, `config/ground.tres` | `tests/test_ground.gd`, the breakage lab's ground scenarios | in the game (flat; digging comes in step 2) |

## Bodies and people (gameplay; characters for the men)

| Part | Where it lives | Proven by | Status |
| --- | --- | --- | --- |
| Anatomy, physiology, wounds, severing | `src/bodies/` (`Anatomy`, `Physiology`, `HumanBody`) | tests | in the game |
| The ragdoll falls (rounds 1 to 3) | `src/bodies/human_body.gd` | ragdoll lab (`experiments/physics_lab/`) | in the game |
| The faint | `src/bodies/human_body.gd` | ragdoll lab | on a branch (`claude/gameplay-faint`) |
| Field first aid: pressure, tourniquet, bandage (the player's tend key; outlaws tend themselves) | `src/bodies/physiology.gd`, `src/player/player_wounds.gd`, `src/people/outlaw_brain.gd` | tests | in the game; the treatment lab widens it |
| What a ball does on bone: it flattens, splits or skips off; cloth carried in; powder burns close up | `src/bodies/anatomy.gd` (`trace`), `human_body.gd` (`take_bullet`) | the body lab, `tests/test_injuries.gd` | on a branch (PR #167) |
| What wounds show over time: blood from the ears, nose and mouth, teeth, a sucking chest, drip trails, handprints, smears, festering, flies | `src/bodies/wound_signs.gd` (`WoundSigns`) | the body lab's `gore` sheet, `tests/test_wound_signs.gd` | on a branch (PR #167) |
| Blood drying brown over game hours | `src/effects/blood.gd` (`Blood.dry`, from the day cycle) | `tests/test_wound_signs.gd` | on a branch (PR #167) |
| The knife: a stab and a slash | `HumanBody.take_knife` | `tests/test_injuries.gd` | on a branch (PR #167); no knife in the game yet |
| Glass and splinters left standing in a wound, buckshot lumps, burns and scorched cloth | `HumanBody._stuck_in`, `burn_marks` | `tests/test_injuries.gd` | on a branch (PR #167) |
| Dressings drawn: a bandage red through, a tourniquet, a sling, a splint | `HumanBody._bind_wound` (on `Physiology.treated`) | `tests/test_wound_signs.gd` | on a branch (PR #167); the treatment lab decides who applies them |
| Infection to gangrene over game days, amputation with a sewn stump, healing to scars | `Physiology` (`contaminate`, `infection`, `fever`), `HumanBody.amputate`, `_heal` | `tests/test_wound_signs.gd` | on a branch (PR #167); the treatment lab's doctor (part 2) calls them |
| Pallor in shock and death, a dying man's gasps, wrist drop, a stiff knee, the gut hunch, breathing rate | `human_body.gd`, the skin shader's `pallor` (art's) | `tests/test_wound_signs.gd`, `test_bodies.gd` | on a branch (PR #167) |
| The painted blood and gore (wounds, splats, stains, pools, stump sections, torn edges, prints, burns, dressings' cloth) | `assets/textures/blood/`, `tools/textures/paint_blood.py`, `cut_blood.py` | the body lab's sheets | on a branch (PR #167) |
| Senses, deeds, relations, the escalation ladder, the gang's crew | `src/people/` | tests | in the game |
| A working face (mouth, lips, teeth, lids, jaw, 12-15 shapes, Live Link takes, `FaceGaze`) | `tools/faces/`, `bold_cowboy_talking` | face rig brief (`docs/briefs/face-rig.md`) | in the game on the old layered cowboy only; the face rig lab brings it to the Studio's men |
| The Studio's men: `bold_cowboy_s0`, `old_rancher_s1`, `young_drifter_s1`, `sean_s2` | `assets/people/` | `works_check.gd`, `test_bodies.gd` | in the game (cast as the gang, the storekeeper and the sheriff) |

## Guns (the gun lab)

| Part | Where it lives | Proven by | Status |
| --- | --- | --- | --- |
| The revolver (Colt Single Action Army, moving parts) and the coach gun | `src/weapons/revolver_model.gd`, `shotgun_model.gd` | `test_gun_feel.gd`, `tools/gun_views.gd` | in the game; the gun lab reworks the look and the moves |
| The player's hand on the revolver, finger by finger | `src/weapons/hand_model.gd` | — | in the game |
| A man's gun at his hand and in his holster | `HumanBody` (fixed offset at the right hand, the right hip) | tests | in the game; the Studio's men can't close a hand round it yet (no finger bones) |
| The kick | `src/weapons/gun_kick.gd` | `test_gun_feel.gd`, feel ranges | in the game |

## Materials and look (art)

| Part | Where it lives | Proven by | Status |
| --- | --- | --- | --- |
| The game's woods (the timber pass's C) | `assets/textures/`, `src/structures/wood_materials.gd` | material lab, 2026-10-15 | in the game |
| The weathering layer (stain sheet: mud and bleach laid in the structure's space) | `src/render/texel_grid*`, `tools/textures/stain_sheet.py` | material lab, rounds 3 and 4 | in the game (used by lab sets so far) |
| The Studio woods (round 4, set `studio7`) | `assets/textures/mlab_*`, `tools/textures/material_lab.json` | material lab, round 4 (critic: 1 same, 7 close, 0 different) | waiting on Sean (his picks on `round4_sheets/`), then promoted into the texture factory's game set |
| Worn treads (nosings worn by feet) | the oak stair and the stand's steps | material lab | in the game |
| The hotel's oak stair, painted oak and runner (`dark_oak`, `stair_runner`) | `src/art/oak_stair.gd` (drawn only) | material lab | in the game as a drawing; waiting to be promoted as members when the hotel is built |
| **The interior woods** (Sean picked the interior stain, C, 2026-10-21): `int_floor`, `int_timber` (posts, beams, brackets), `int_boards` (wall boards), `int_oak` (wainscot, casings, the bar, rails, balusters); one warm umber family; their own names, so the outside keeps its woods | `assets/textures/woods/int_*` (+ `lab.json`), from the lab's `studio_int` by `tools/textures/promote_woods.py`; `PixelArt` draws them with seams a pixel wide | interior stand, blind critic against his saloon picture (`docs/screenshots/material_lab/2026-10-21/interior/`) | in the game (for the saloon's interior: `wood:int_oak` in a kit file, or a member's wood) |
| **The bar top** (`int_bar_top`): `int_oak` glued up across the top's 0.84 m depth, polished (`roughness` 0.35), drink rings (dark wet rings and pale heat blooms, where men stand) and the front edge worn by elbows; procedural, free, seeded | `assets/textures/woods/int_bar_top_*`, made by `tools/textures/bar_top.py` | the bar's `bar_top` view, `tests/test_material_stand.gd` | in the game (the kit bar's top: `wood:int_bar_top`) |
| **Profiles** (the woodwork's cross-sections as data: chamfer, rounded, bar top, handrail, ogee, bead) | `src/art/profiles.gd` | interior stand, `tests/test_material_stand.gd` | in the game (code); a kit member draws with them by its `draw` (shape `profile`, `panel` or `cut`: `PropKit.woodwork_mesh`), and any building's member by `PropKit.dress_member` (still a member: breaks, burns, falls) |
| The test stand, the interior stand | `src/art/material_stand.gd`, `src/art/interior_stand.gd`, `tools/material_lab.gd` | — | lab fixtures (stay in the lab) |

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
| The 12 drawn props (card table, chair, bar stool, piano, barrel, spittoon, oil lamp, whiskey bottle, tin cup, deer head, framed painting, wall sconce) | `assets/props/manifest.json`, `src/props/prop_library.gd`, `src/props/prop_models.gd` | the judge's shots, `tests/test_props.gd` | in the game, solid (one collision box, can't break or burn); targets for their kit versions. The chair and card table now spawn as the kit's (below); PropModels' two stay in the code as the kit's comparison |
| Buildings' hand-built furnishings (store, telegraph, doctor, bank; the saloon's bar and back bar) | `FalseFrontBuilding._furnish_*`, `SaloonBuilding._build_furniture` | `tests/test_town_buildings.gd` | in the game, as members; to be brought into the kit |
| Water: buckets, the bucket line, dousing, wet members | `src/fire/`, `src/people/bucket_line.gd` | tests | in the game; the water lab adds liquid in containers, spills and the flood |
| A smashed lamp spills burning oil | `src/world/oil_lamp.gd` (`smash`), `src/structures/fittings.gd`, `FireSystem.spill` | `tests/test_fittings.gd`, `tests/test_fire.gd` | in the game; the kit lamp is its own hitbox now (GlassProp) |
| **The prop kit**: one data file per prop (`assets/props/kit/<id>.json`: members, their draw and dress, wood, look, seat), one builder | `src/props/prop_kit.gd` (`PropKit`: load, expand, draw shapes, spawn), `src/props/kit_prop.gd` (`KitProp`, a `Structure`) | `tests/test_prop_kit.gd`; the prop lab's bench (`experiments/prop_lab/`) | in the game (merged from `claude/prop-lab-inventory-kit-buch2n`): `PropLibrary.spawn` hands out the kit's version of any prop whose file says `in_game` |
| `KitProp`'s rules: stands on what's under its feet (falls when its floor goes); tips when its weight and a seated man's aren't over its feet (less his sway); a member left hanging at one joint tears out as it goes over (`BodyImpacts.nailed_moment`); a holed slender member splits (`splits_below`); a blow (kick) breaks the member it lands on (over its `blow_span`) or moves the prop (inelastic knock, the wood's `toughness`); a blast it survives throws it, each member pushed by `Blast.face_impulse` at that member (a stick 1 m off throws the table over and it comes apart where it lands); what stood only on it (Fittings' items: the lamp) comes down with it at once | `src/props/kit_prop.gd` | `tests/test_prop_kit.gd` (11); the ragdoll lab's group U (a man in the kit chair) | in the game |
| A seated man on a kit seat: his weight on the seat member (`sit`/`leave`), down with the chair when it goes or is knocked from under him | `KitProp.sit`, `seat` in the kit file | bench: `seated_*` (a leg shot or kicked out puts him on the floor) | in the game; nobody sits yet (gameplay: brains to call `sit`); how he falls is the ragdoll lab's |
| The kit's **chair** (`chair.json`: PropModels' spindle-back chair in 13 oak members, the back legs running up as the back posts) | `assets/props/kit/chair.json` | bench (`results/2026-10-21_baseline/`); the look sheet against PropModels' | in the game (`in_game`): the drawn `chair` everywhere `PropLibrary` spawns it (saloon 8, doctor, bank); waiting on Sean's look to retire PropModels' |
| The kit's **card table** (`card_table.json`: four feet, a turned pedestal, two cleats, five top boards cut round with the baize on them, an eight-piece rim; 19 oak members) | `assets/props/kit/card_table.json` | as the chair | in the game (`in_game`, Sean 2026-10-21): the drawn `card_table` wherever `PropLibrary` spawns it (saloon 2); blind critic: better than PropModels' in 3 of 4 views |
| The kit's **bar** (`bar.json`, a fixture: 3 m section, lined up as long as the room needs; a raised-panel front between chamfered pilasters on a plinth, a frieze, corbels under the top's overhang, the top glued up in `int_bar_top` with a bullnose front, a brass foot rail on brackets, the bartender's side boarded; 30 oak members, 3 batches) | `assets/props/kit/bar.json` | `tests/test_prop_kit.gd` (stands, batches), `tests/test_material_stand.gd`; interior stand views `bar`, `bar_top`; blind critic against Sean's saloon picture (`docs/screenshots/material_lab/2026-10-21/bar/`) | in the kit, for the saloon session to put in place of `SaloonBuilding`'s hand-built bar (`PropKit.spawn(&"bar")`, turned to face the room) |
| The kit's **back bar** (`back_bar.json`, a fixture: 2.5 m; a panelled base and counter, three columns with bases and capitals, two arched frames with their mirrors (`prop:mirror`), two shelves a bay on brackets, an ogee cornice on dentils, a carved crest; 43 oak members, 2 batches) | `assets/props/kit/back_bar.json` | as the bar; views `back_bar`, `interior` | in the kit, as the bar |
| Clear white oak (`oak`: Wood Handbook clear figures, `toughness` 101 kJ/m³) | `src/structures/timber_tuning.gd` (gameplay's file, one entry added by the prop lab) | the bench's kicks | in the game |
| **Props that shatter** (`GlassProp`, kit kind `shatters`): standing as their model (batched by StaticBatch) over a frozen body a ball goes through; broken shot, dropped or struck past `breaks_at`, by a blast's overpressure (`shatters_kpa`; short of it thrown), or in flames (`heat_seconds`); taken by their table going over (`KitProp.went_loose`); breaking throws shards, drops the parts that come through whole, cuts (GlassCuts), and lets go what they held: a lit lamp's oil burns (`OilLamp.smash`), else `Events.liquid_spilled` for the water lab's spills | `src/props/glass_prop.gd`, `PropKit.make` | `tests/test_glass_props.gd` (5); the bench's glass scenarios | on a branch (`claude/prop-lab-inventory-kit-buch2n`) |
| The kit's **whiskey bottle** (`whiskey_bottle.json`: PropModels' bottle, 0.6 l of whiskey; breaks at 4.5 m/s, 60 kPa; neck and cork whole) and **oil lamp** (`oil_lamp.json`: PropModels' lamp; the chimney breaks at 1.5 m/s, 15 kPa; the brass foot whole; 0.25 l of lamp oil) | `assets/props/kit/` | the bench (shot, shotgun, dynamite 1/3/6 m, the table shoved over, the table burning) | on a branch; `in_game`: PropLibrary hands them out for the drawn ones (the saloon's ~45 bottles and 4 lamps, the doctor's 5) |
| The prop lab's bench: the breakage lab's set, kicks, fire, the seated man; the look sheet; the budget | `experiments/prop_lab/` | — | a lab fixture (stays in the lab) |

### What exists today (the prop lab's inventory, 2026-10-21)

Lanes by file (CLAUDE.md): `src/props/`, `assets/props/`, `src/art/` are art's (the prop lab may
edit `src/props/` and `assets/props/`); `src/structures/`, `src/world/`, `src/fire/`, `src/blast/`
are gameplay's. "Members" means `Structure.add_member` boxes: each burns on its own (not iron,
stone or glass), is carved by balls (voxels; not iron or glass), is broken and thrown by `Blast`,
and drops when its support goes. What differs is in the row.

**Drawn props** (art). `PropLibrary.spawn(id)`: no `.glb` exists for any of the 12 (the manifest
was for Meshy trials), so every one is its `PropModels` code model, scaled to the manifest's
height, on `PixelArt.material()`, as one `StaticBody3D` with one box collision (layer WORLD, no
mass, no group), merged by `StaticBatch`. A ball stops dead in the box or glances (Ballistics has
no prop branch); fire and Blast never touch them; things rest on them. Each can fall as a fitting
(below) if it stands off the ground on members.

| Prop | How it's built (`prop_models.gd`) | Where it's used | Can't do |
| --- | --- | --- | --- |
| `card_table` 1.2 x 0.76 | `_card_table` :337: baize disc in a lathed rim, 8-sided turned pedestal, four box feet (dark wood, felt) | saloon 2 (`saloon_building.gd:85`); `ShotMatch` builds its own (`shot_match.gd:403`, a cylinder collision) | break, tip, burn, be carved |
| `chair` 0.45 x 0.9 | `_chair` :350: boxes: seat, 4 legs, 2 uprights, 2 stretchers, a rail, 5 spindles (mid wood) | saloon 8 (4 a table); the doctor's and bank's; `ShotMatch._chair` :446 its own, no collision | lose a leg, be sat in as a seat that fails, burn |
| `bar_stool` 0.38 x 0.76 | `_bar_stool` :363: lathed seat, 4 splayed box legs, brass foot ring | saloon 6, telegraph 1 | as the chair |
| `upright_piano` 1.5 x 1.3 | `_piano` :378: box case, keys, black keys, burl panel, brass candle holders | saloon 2 | break, burn, be carved; its keys don't play |
| `barrel` 0.6 x 0.9 | `_barrel` :405: a 14-sided lathe of bulged staves, head, four iron hoops | saloon 3 (one stacked), the street 11 (`street_dressing.gd:375`-`399`) | lose staves, burn, leak |
| `spittoon` | `_spittoon` :418: brass lathe, inside lathe | saloon 2, the saloon porch (`facade_art.gd:243`) | dent, tip, spill |
| `oil_lamp` | `PropModels.lamp()` :427 (shared with `OilLamp`) + an `OilLamp` child "Light" (`saloon_building.gd:115`) | saloon bar and tables, piano, ShotMatch | the prop's model stays whole when its `OilLamp` smashes (only the lamp's own meshes hide); the breakage lab: a shot never reaches its 14 x 38 cm hitbox inside the prop's box |
| `whiskey_bottle` | `PropModels.bottle(variant)` :438: 16-sided glass lathe, cork, painted label (3 glass colours) | saloon ~45, the doctor's 5, ShotMatch; ~hundreds more merged into the bottle wall (`saloon_dressing.gd:288`, scenery, not shootable) | shatter, spill whiskey (no shatter code); the breakage lab: it stops 9 pellets |
| `tin_cup` | `PropModels.cup()` :447: pewter lathes, a box handle | saloon 5; ShotMatch; the cup in hand | dent, be knocked off by a ball |
| `deer_head` (wall) | `_deer_head` :459: boxes and stick antlers | saloon 2 | fall when shot loose, burn |
| `framed_painting` (wall) | `_painting` :493: gilt box frame, canvas on the texel grid (2 landscapes) | saloon 3 | burn, tear, fall when its nail goes (only as a fitting, when the wall goes) |
| `wall_sconce` (wall) | `_sconce` :516: brass plate and arm, `lamp()` at 0.85, reflector | saloon 24 (14 with their own `OilLamp`, `saloon_dressing.gd:376`) | as the oil lamp |

**The street's code models** (art; `StreetDressing._model` `street_dressing.gd:551`: a
`StaticBody3D` with one box, not through PropLibrary): `crate` (`prop_models.gd:621`, boxes; 12),
`hay_bale` (:635, lofted; 4), the porch `bench` (`street_dressing.gd:531`), `horse` (:805; 5),
`wagon` (:717), `telegraph_pole`, `water_tower`, the `lantern` with its `OilLamp` (:677,
`street_dressing.gd:290`), rails and hung boards. Same as the drawn props: solid, unbreakable,
unburnable. On the ground (box bottom under 8 cm) they aren't fittings either.
**`VoxelTrial`** (art, `src/art/voxel_trial.gd`): voxelised cup, lamp, bottle and ashtray `.glb`s
in `assets/props/voxel/`, swapped into ShotMatch's set behind a flag; drawn only.

**Furniture built as members** (gameplay unless said). Two kinds matter: `furniture_frame`
(tier 3: legs, ends, fronts, uprights) **is never load-checked, so it can't fail by overload**,
only by a ball's carving, Blast, fire or losing its support; `furniture_top` (tier 5: tops,
shelves, treads) is checked in bending. Furniture tiers are never `grounded`, so furniture must
stand on floor boards (a lone table on bare ground has no load path). `extra_load` is unused: what
stands on a shelf or top (bottles, lamps) adds no weight. Members are static: nothing tips, slides
or is carried until it breaks into rubble.

| Furnishing | How it's built | Can / can't |
| --- | --- | --- |
| Store counter and shelves (`_furnish_store` `false_front_building.gd:549`) | counter: a front, two ends (`furniture_frame`, floor), a `furniture_top` (dark trim); shelves: 3 uprights, 4 boards; a `CounterLamp` | the shelves' boards and the top can fail in bending; the frame only by damage |
| `_table` (:579), `_counter` (:590), `_shelves` (:598): the shared helpers | `_table`: a 35 mm top + four 50 mm legs (5 members); `_counter`: front, end, top (3); `_shelves`: 2 uprights + n boards | the nearest thing to a kit: but built inside the building, the legs never snap under load, the top never tips |
| Telegraph (`_furnish_telegraph` :634) | counter; a `_table` desk with an **iron** key and a sounder (`furniture_top` members); a battery shelf with 7 glass jars (`glass` members: they shatter); a `bar_stool` prop | the jars are the only furniture glass |
| Doctor (`_furnish_doctor` :654) | `_table`s as desk, operating table and cot; a 4-shelf cabinet with a back; a `chair` prop; 5 bottles | |
| Bank (`_furnish_bank` :675) | counter, an iron-barred cage (`trim`, iron), a desk; **the safe**: 7 iron plates (~560 kg) on the floor boards | the safe doesn't burn, isn't carved, balls glance; its door doesn't open |
| The saloon's bar (`SaloonBuilding._build_furniture` `saloon_building.gd:41`) | front, two ends, a top (all dark trim), a `trim` foot rail; back bar: 3 uprights, 3 shelves; then every saloon prop above through `_place` | |
| The saloon's balcony, stair and rails (art, `saloon_dressing.gd:138`-`231`) | posts, beam, ledger, joists (kind `rafter`), floor (`furniture_top`); stringers, 11 treads, newel, balusters, hand rail (`trim`); the walking ramp (`Layers.WALK` on `claude/gameplay-falls-props`) | `trim` rails break only by damage, or by a falling man through `BodyImpacts` (on the branch) |
| `WaterTrough` (`water_trough.gd:12`) | 2 skids (`sill`, grounded), a bottom, 4 cleats, 6 boards; a water plane | only its bottom is load-checked |
| `HitchingRail` (`hitching_rail.gd:9`) | 2 grounded posts, a rail (`beam`, bending-checked) | |
| `Well` (`well.gd:18`) | 30 ring stones (`stone`: fireproof, carved as stone), posts, roller, an iron crank, a roof | |
| `Corral`, `Windpump` | posts and rails; the windpump's wheel is drawn, brought down by Fittings | |
| The range's barrels and crates (`src/world/range_cover.gd:18`, gameplay) | each one solid `furniture_frame` box on the ground | by reading (not run): tier 3 on the ground has no load path, so the first settle after damage there drops them as rubble |

**Fittings and the lamp** (gameplay; `src/structures/fittings.gd`, `src/world/oil_lamp.gd`).
Four physics frames after load Fittings collects every prop, lamp and drawn thing in a structure
or the street's dressing whose bottom is 8 cm or more off the ground and which touches members or
other fittings; every 0.25 s it checks them, and once every member under one is broken, burnt or
moved and all it rests on has fallen, it becomes a `RigidBody3D` (WORLD if 0.6 m or bigger, else
DEBRIS; mass volume x 250 kg/m³, 0.3-150 kg; group `fallen`). A lamp in one landing at 1.5 m/s
or more `smash`es: unlit, shards, and if it was lit a ray down and `FireSystem.spill(at)`
(`fire_system.gd:93`: 0.9 m, 25 s, heating members in it; scorching people). A ball meeting a
lamp's hitbox (meta `oil_lamp`) smashes it too. What Fittings can't do: a prop falls whole, never
breaks; a prop knocked by a ball or a body doesn't fall (only losing its support does).

**What the labs have built or measured**
- **The breakage lab** (gameplay, `claude/gameplay-breakage-lab-ksr17d`, not merged;
  `experiments/breakage_lab/`, `scenarios.json`): 11 targets x revolver and shotgun at 5 m,
  dynamite at 1, 3, 6 m (0 m for some), each with a bystander for each of the four men, plus
  `man_on_table` (a limp man dropped on his back from 1 m over the card table): 45 scenarios, 138
  games. Targets are found in the street (`prop`, `member`, `kind`, `ground`); the props it tests
  are the saloon's chair, card table, bottle and lamp. Its baseline: **every prop holds**: a ball
  or a charge stops dead in the box, a stick 1 m off leaves them standing on a broken floor, a shot
  never smashes the lamp, the man on the table lies on it at rest in ~2.8 s with no physics faults
  (but the lamp's chimney and the cups show through his chest). It measures pieces (count, mass,
  how far), fire, faults, same seed same result and frame time. To take a kit prop: the prop must
  be in the street (no spawning in the lab), `_target_result` knows only static props (holds, moved,
  fell, smashed), and `_man()` hard-codes the card table's height (`runner.gd:379`): all
  gameplay's to change. It also changes `Blast` (`gather`, boards cut over a stretch: `cut_member`),
  `Fittings` (an item kept on a cut board's end) and the fire (`ignite_after`).
- **The ragdoll lab's railing** (gameplay, `claude/gameplay-falls-props`, not merged;
  `experiments/physics_lab/lab_railing.gd`): a `Structure` of the game's own members: 4 newels
  (`furniture_frame`), 27 balusters and 3 caps (`trim`, dark trim), on a deck 2.47 m up. Measured
  (round 4): a faint or a backward shove breaks nothing; a face-first shove, a charge or a man dead
  at a run takes the cap and 5-7 balusters and he goes through. It's broken by **`BodyImpacts`**
  (`src/structures/body_impacts.gd` on that branch): a limp man near timber tallies the work of his
  level contacts on each member against `impact_toughness` x volume (trim: what its nails hold),
  breaks it and is given back what the break didn't take. Hits from above are ignored by design, so
  a man dropped onto a table or chair breaks nothing through it: the prop kit's "a seated man
  drops when his chair goes" needs the chair to fail by load (gameplay's to extend). The lab also
  has its own `_table` (boxes) and a loose 6 kg box `_chair` (RigidBody), and `seat`/`seat_table`
  fixtures; not members.
- **The material lab** (art, `tools/material_lab.gd --material=props`): a card table, chairs and a
  barrel on the stand's deck with the Studio's three men, judging their textures: the stand to
  judge the kit's versions on.

## The Systems Playground

The test saloon (`docs/briefs/labs.md`, "The Systems Playground"): the game's own saloon and a
stretch of street, built only from parts marked **in the game** above, with every approved system
on. When a part is promoted, the playground takes it in its next merge.
