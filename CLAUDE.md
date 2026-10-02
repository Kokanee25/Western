# CLAUDE.md — working notes for Salt Creek (the Western)

Read **DESIGN.md** first: it's the source of truth for what the game is. Concept art is in
`docs/concept/`. This file is how we work.

## Who and how

- Sean directs; Claude builds. Sean works shifts and plays/reviews in short sessions, often from his
  phone, and tests builds on PC. Keep each session's work self-contained: leave the game runnable, and
  update **Status** at the bottom of this file before finishing.
- Tone of the game: grounded and gritty, with humour. When in doubt, systems over scripts.
- Decisions already made are in DESIGN.md. Don't reopen them without asking; open questions are
  listed in DESIGN.md §13.

## How we work

- **Exactly two working sessions at a time:**
  - **Art:** shaders, textures and how things are lit and drawn; the people's looks; dressing.
    Its files: `src/render/`, `src/bodies/shaders/`, every `*.gdshader`/`*.gdshaderinc`,
    `src/art/`, `src/props/`, `assets/` (`assets/people/`, `assets/props/`), `tools/blender/`,
    `tools/faces/`, `tools/paint/`, `tools/style/`, `tools/textures/`, `assets/textures/`, the art tools in `tools/` (`paint_bake.gd`,
    `character_lab.gd`, `lab_stage.gd`, `fit_shot.gd`, `side_by_side.py`, `people_envelope.gd`,
    `judge.py`, `prop_views.gd`),
    `src/bodies/body_mesh.gd`, `src/bodies/people_bodies.gd`, `.github/workflows/people.yml`,
    `docs/concept/` and `docs/screenshots/`.
  - **Gameplay:** everything else (people's minds and bodies, weapons, structures, fire, blast,
    the town, saves, controls, CI).
  - Shared by both: `CLAUDE.md`, `DESIGN.md`, `docs/BUILD_NOTES.md`, `project.godot`,
    `src/autoload/settings.gd`, `src/autoload/controls.gd`, `tools/screenshots.gd`. Edit only
    your own lines and entries in them; add status entries at the end, in date order.
- **Each works on its own branch** (`claude/art-…` or `claude/gameplay-…`), never on `main`.
- **Pull `main` before starting and again before merging** (`git fetch origin main && git merge
  origin/main`), run all the tests, and **merge small and often**: one finished, tested piece
  of work per merge, not a day's worth.
- **After merging, confirm the build on `main` is green** (Actions → "Test and build" for that
  commit) and give Sean the build number. A red main is fixed before anything else.
- **Never edit the other session's files without saying so**: in the commit message and in your
  status entry, naming the file and why. If it's more than a line or two, ask Sean first.

## Tech decisions

- **Engine: Godot 4** (latest stable 4.x). Chosen because every script, scene and resource is plain
  text Claude can read and edit, it's free and open source, exports to Windows/Mac/Linux (Steam later),
  and runs headless for automated tests.
- **Language: GDScript** by default. Use C# only for a measured performance hotspot, and ask first.
- **Target: PC / big screen**, keyboard + mouse and controller. First person only.
- **Look:** render the 3D scene into a SubViewport (1280×720 by default since 2026-09-30; was 640×360)
  and scale it to the window with nearest-neighbour filtering; the chunky pixels are the textures'
  squares, each several screen pixels big. Keep the internal resolution a setting (F2).
- **AI characters:** called through a small relay server that holds the API key (OpenRouter, so the
  model can be switched). **The key never goes in this repo or in the game build.** The AI is only
  called for conversation, asynchronously — never inside the frame loop.
- **Asset pipeline: Blender, run headless by script** (`blender -b --python …`) in the cloud workspace.
  Most props and buildings are built in code (see DESIGN.md §4 and `src/structures/`); Blender is for
  what code does poorly. Scripts live in the repo (`tools/blender/`) so every step is repeatable: bodies
  and faces, fitting garments to body types, splitting bodies at joints with finished stumps, rigging
  and retargeting mocap, cleaning up any AI-generated models (decimate, fix normals/UVs/scale), and
  exporting glTF for Godot. Framing and timber numbers: Sean is not a framer (he's framed two
  things); use published references (USDA Wood Handbook, period carpentry manuals), not him.
  Blender MCP (driving a live Blender window) is optional later, once Sean has a PC that can run it,
  for hands-on art-direction sessions.
- **Motion capture:** Sean records on his iPhone (Move One / Rokoko Vision) following
  `docs/MOCAP.md` (shot list, recording rules, naming). Raw FBX goes in `assets/mocap/raw/`; a headless
  Blender script retargets, cleans (foot sliding, jitter, loops) and exports glTF to `assets/animations/`.
  Recoil and deaths are never recorded: recoil is procedural, deaths are ragdoll.
- **External asset APIs** (Meshy for 3D, image models, voice services) are called with keys stored as
  environment secrets — never in the repo.
- **Saving:** only when the player sleeps in a bed. Save files store the difference from the authored
  town (broken members, debris positions, wounds, memories), per person where possible.

## Architecture guidelines

- Systems talk through small, explicit interfaces (signals / an event bus), so fire, structures,
  bodies, sound, witnesses and memory can react to each other without knowing each other's internals.
- Everything that should persist has an ID and a serialisable state.
- Simulation (bodies, fire, structures, schedules) runs on fixed timesteps and is testable without
  rendering.
- Put tunable numbers (bleed rates, burn rates, bone strengths, day length) in data resources, not code.
- Keep the anatomy, fire and structure systems deterministic enough to test: seedable randomness.

## Testing

- Unit/system tests run headless (`godot --headless` with a test runner such as GUT or gdUnit4).
  Every system gets tests for its rules (a femoral hit bleeds out in N minutes untreated; a beam with no
  load path collapses; fire spreads to dry siding but not stone).
- Visual checks: render screenshots from fixed camera views and compare them against the concept art
  in `docs/concept/`. When real-GPU rendering isn't available, say so rather than guessing.
- Sean reviews on PC. Tell him exactly what to try in each build.

## Build plan

Work in this order; each milestone ends playable. The first slice is defined in DESIGN.md §12.

1. **M0 — Project skeleton:** Godot project, low-res pixel pipeline, first-person controller (walk, look,
   crouch, controller support), a test street with one false-front building, day/night lighting.
2. **M1 — The gun:** single-action revolver (cock, fire, gate reload, black-powder smoke), hit traces.
3. **M2 — Bodies:** hidden anatomy, ballistics through tissue, physiology (blood, shock, pain, adrenaline),
   fear and surrender, visible wound decals and clothing layers, one test outlaw. **Prove the gunfight
   feels good here.**
   **M2 follow-ups** (after M3's core, before the people art pass): grazes, glass cuts and embedded
   shards, visible interior anatomy with wound volumes, shotgun pellets (DESIGN.md §7 "Grazes, glass
   cuts and open wounds"); outlaw cover, fleeing and tending himself; active ragdoll balance.
4. **M3 — Structures:** member-based buildings with a support graph, breakage, collapse, persistent
   sleeping rubble; then fire spread; then dynamite.
   **Rope** comes right after M3's core (needs members, ragdolls and physics): lasso and tying people
   up first, then pulling walls down with a horse, hitching, pulleys (DESIGN.md §8 "Rope").
   **Town build-out (runs alongside M4–M5):** once M3's systems exist, build the town from
   `docs/TOWN.md` one building per session — every building, interior, set piece and piece of dressing,
   in the order listed there.
5. **M4 — People** (gameplay session), in this order:
   1. ✅ Senses for everyone. 2. ✅ Deeds, opinions, the escalation ladder. 3. ✅ A day in town for
   the gang, backing down, call-outs, duels. 4. ✅ The gang fights together.
   5. **Money and social acts** (DESIGN.md §10 "Social interactions: a round on me"): a purse of real
      coins at 1882 prices; the barkeep sells drinks, keeps a ledger, runs tabs, throws out men who
      can't pay; "buy him a drink" and "a round on me!" as deeds (the room counts heads, you pay,
      they cheer and toast, opinions warm by context); drunkenness for everyone (sway, speech,
      courage). Keys for now, conversation later.
   6. **Reasons to fight, first two** (DESIGN.md §5 "Reasons to fight"): a shooting match at the
      range with money on it (drop, sway and the guns' feel against other shooters, prize from the
      purse); a bounty from a wanted poster on a man camped outside town (alive pays more: arrest
      and surrender as they are). No animals, ever.
   7. Conversation hooks: talking a man down, bargaining, surrender terms.
   8. Memory records and routines for townsfolk (who saw what, who owes whom, where they are when).
   9. AI conversation through the relay (voice + suggested replies), with the speaker's body state
      fed in (DESIGN.md §11 "Signature features" 1: the body changes how people talk).
6. **M5 — The town slice:** Salt Creek's first dozen people, the outlaw scenario with multiple endings,
   the doctor, the jail, saving in bed and waking at the doctor's. **The sheriff opening** is the
   first piece of the story spine (DESIGN.md §5 "Story flow", §11 signature features 1–3): you find
   him on the road at dawn, treat him, his words follow his blood loss, the ball the doctor digs out
   is evidence. Then forensics (the doctor and undertaker read wounds) and the trial.
7. **M6+ —** the three acts on the railroad clock with faction plans, the drama manager, rumours,
   letters and the telegraph, leading deputies, the mine, the full cast, legends between games.

## Commands and layout

Godot **4.7.2** (pinned in `.github/workflows/build.yml`; bump both together).

```sh
godot --headless --import                                      # after adding class_name scripts
godot --headless --fixed-fps 60 -s res://tests/run_tests.gd     # all tests (exit 1 on failure)
godot --headless --fixed-fps 60 -s res://tests/run_tests.gd -- --only=player   # one file or method
xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd -- --out=/tmp/shots
godot --headless --export-release "Linux" build/linux/SaltCreek.x86_64         # needs export templates
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build.yml'))"  # before pushing CI edits
```

- `src/autoload/` — `Events` (the event bus), `Settings` (user://settings.cfg), `Controls` (the input
  map, built in code: keyboard/mouse and controller).
- `src/render/` — **one per-texel lighting system for the world, people and props:**
  `tiles.gdshaderinc` (mosaic tiles: `tile_centre()`, `tile_light_at()` moves `LIGHT_VERTEX` and
  the normal to the centre of the texel a fragment shows, from screen derivatives of texel coords,
  so light, shadows and fog are flat per texel; ragged tile edges; shader globals
  `tile_light`/`tile_ragged` in project.godot [shader_globals], set by `Settings.tile_look`,
  **P** cycles square / ragged / off, default square). Users: `texel_grid.gdshader(inc)`, the one
  material for everything in the world on the texel grid (`PixelArt.material()`: pixel texture at
  `texels_per_meter`, UV or triplanar mapping; members, blockouts, props; `member_holes.gdshader`
  is the same with bullet holes), `src/world/ground.gdshader`, and the people's
  `body_skin.gdshaderinc`. `MemberMesh` puts each face's size in UV2 so the point stays on thin
  faces. `pixel_screen`: F6. `Settings.NATIVE` (F2's last stop) = render at the window's size.
  Still lit smoothly (StandardMaterial3D): guns, lamps, `PropLibrary` props, effects.
- `src/main/main.gd` + `scenes/main.tscn` — the pixel pipeline: world renders in `GameViewport`
  (SubViewport at `Settings.internal_resolution`, 1280×720 default), drawn to `Screen` with nearest
  filtering.
- `src/player/` — controller, visible body, tuning resource (`config/player_tuning.tres`),
  `PlayerComposure` (flinch, rattled, winded; the guns read `sway_scale()`/`extra_spread()`).
- `src/world/` — `DayCycle` (clock + sky; `config/day_cycle.tres`), sky and ground shaders, oil lamps,
  placeholder scenery.
- `src/structures/` — `Structure` + `StructureMember` (members with IDs, kinds, support tiers and an
  inferred support graph; `settle()` breaks/drops what can't stand, rubble), `StructuralAnalysis`
  (loads down the graph, compression/buckling/bending/joint checks; `config/timber.tres` via
  `TimberTuning`), `FalseFrontBuilding`, `Boardwalk`, `HitchingRail`, `WaterTrough`.
- `src/fire/` — `FireSystem` (member temperatures, heating by contact/radiant/flame plume, ignition,
  char, ash, spilt lamp oil, scorching people; `config/fire.tres` via `FireTuning`), `FireFX` (flames,
  smoke, `char_overlay.gdshader`).
- `src/bodies/` — `Anatomy` (config/anatomy.json, generated by `tools/anatomy/build_anatomy.py` —
  edit the script, not the JSON: segments, bones, arteries, organs, fingers; traces a
  bullet through them), `Physiology` (blood, bleeds, shock, pain, adrenaline, breathing;
  config/physiology.tres), `HumanBody` (segment hitboxes, meshes, clothes, wound decals, ragdoll),
  `OutlawBrain` (fear/nerve; tactics OPEN/MOVING/HIDDEN/PEEKING; flees, tends himself,
  surrenders), `Cover` (finds hiding spots against a threat by rays: ring samples + "shadows"
  behind whatever the threat's sight lines hit; `Cover.search()` spreads it over ticks),
  `Layers` (physics/render layer bits),
  `PeopleBodies` (loads `assets/people/<id>.glb` — the MakeHuman body — and cuts it into
  per-segment pieces like BodyMesh; `HumanBody.body_model`, empty = BodyMesh),
  `BodyInterior` (insides built from the anatomy when a part opens; `shaders/body_skin` and
  `body_inside` cut wound openings, `wounds.gdshaderinc`).
- `src/people/` — `Senses` (per person: sight cone + light + line of sight + movement/crouch;
  hearing via `Events.noise`; `known[who]` last seen/heard), `Relations` (per person towards each
  other: pressure, grudge, fear, stance on the ladder IGNORE…FIGHT; `Relations.WEIGHTS` per deed),
  `DeedWatch` (turns shots/deaths/surrenders/speech into `Events.deed` and `Events.noise`),
  `PlayerDeeds` (your draw/holster/aim_at/crowd/stare/shout/call_out deeds), `Waypoints` (named
  places + links, `route()` / `route_to_point()`; `test_street()` defines the street, store and
  saloon), `CivilianBrain` (unarmed townsfolk at a post: hands up, cower, thanks), `TownLife` (the
  test street's people: storekeeper, barkeep, and the gang with a day's `agenda`; U brings them in).
  `OutlawBrain.agenda` steps: go, wait, drink, harass, call_out, duel, leave. `Crew` (per man:
  his friends in a fight as he knows them, from what he saw and `Events.callout`s he heard:
  reloading, hit, spotted, flank, covering, help, drag, down, dead, quit, fall_back, give_up).
- `src/weapons/` — `WeaponViewmodel` (what every gun in hand shares: tuck, shot line, camera),
  `RevolverViewmodel` + `RevolverState`/`RevolverModel`, `ShotgunViewmodel` + `ShotgunState`/
  `ShotgunModel` (`config/shotgun.tres`). `Player.weapons`/`weapon`/`select_weapon()` switch them.
  `Ballistics.fire_charge()` flies a shotgun charge as separate pellets. `DynamiteViewmodel` is the
  stick in hand.
- `src/blast/` — `Blast` (Kinney-Graham overpressure/impulse by scaled distance; `detonate()` breaks
  members by impulse energy vs bending capacity, glass by pressure, throws splinters through
  Ballistics, ignites, pushes loose bodies, sets off sticks nearby, calls `take_blast(at, kg, held)`
  on people), `BlastTuning` (`config/blast.tres`), `DynamiteStick` (the stick in the world: fuse,
  sparks, shot/fire/sympathetic detonation), `BlastEffects` (flash, fireball, cloud, scorch, sound).
  `src/player/player_wounds.gd` is the player's own anatomy + wound effects.
- `src/art/shot_match.gd` — the painting's shot staged in the saloon (`ShotMatch.stage()`, view
  `shot_match_saloon`); `tools/side_by_side.py render.png` puts a render next to the painting.
  Stage a camera with `ShotMatch.frame_camera()` / `hands_off_camera()`: a gun left in hand drives
  the camera's fov and pitch back to the game's (75°, level). `tools/fit_shot.gd` fits his SEAT,
  TURN and pose offsets to the painting's man (outline, eyes, cup, palm in front of the mug).
  `src/render/outline.gd` (+ `.gdshader`) is a trial of line work (dark lines on silhouettes and
  creases from depth/normals, a full-screen quad on a camera): off everywhere, `--outlines` in
  the lab. `tools/character_lab.gd` judges the man on his own: ShotMatch's table and man in an empty world
  (`tools/lab_stage.gd`), the fitted camera, light tuned to the painting's (not the saloon's),
  rendered with him and with him shadow-only; the pixels that differ are his, pasted over the
  painting (`in_painting.png`). **Painting him from the painting:** `tools/paint_bake.gd guides`
  renders him in grey clay from the painting's view and five round him, only him in the side
  views (`assets/people/paint/<id>_<view>_guide.png` + `_mask.png`); `tools/paint/paint_views.py`
  (Actions: People workflow, inputs `paint_views: all`, `paint_sheet`, `paint_model`; default
  FLUX.2 [max] on OpenRouter, the painting's man + his face as references on every call, even
  light, no pixelating) paints each view (`_painted.png`) and, with `--sheet`, all six in one
  turnaround picture cut back into `_tile.png` (the sheet follows our outline far better);
  `tools/paint/align.py [--source=tile]` fits each painting's outline onto the guide's (scale +
  shift), matches its colours to the painting's man (the whites of his eyes keep theirs), bends
  his face so its landmarks land on the guide's (`face_warp`: MediaPipe's face landmarker, `pip
  install mediapipe` + `apt-get install libegl1`, model fetched into build/; reports `face_fit`
  and `face_mismatch`, a face painted where the guide shows the back of his head) and writes
  `_aligned.png` (alpha = his outline) plus `<id>_shot_painting.png` (the painting itself, masked
  to its man by a hand-traced outline, face bent the same way); `paint_bake.gd bake` projects
  every source into each shape's UV space (depth-tested, needs Forward+; shapes in
  `HumanBody.DOUBLE_SIDED` are taken from either side; writes where the eyes are in the head's
  texture); `tools/paint/finish.py` blends them (the best view wins), fills, then makes the
  **squares**: a set size on him per shape (`SQUARES_PER_M`: cloth 80, face 190, hands 150; the
  face's squares are 3×3 texels so its eyes can be drawn finer, `DETAIL`/`square_texels`), each
  the dominant colour under it, one palette for all of him → `assets/people/<id>_paint_<shape>.png`
  (one texel per square) + `<id>_paint.json`. `body_skin` shows them as painted
  (`HumanBody.paint_look`: the game's ACES grade undone, lit by light brightness only, each light
  eased off at paint_limit, wrapped, a little self-lit) and lights each square as one (the light's
  position and the normal at the texel's centre, `LIGHT_VERTEX`).
- `src/art/street_match.gd` — the street painting's shot (`StreetMatch`, view `shot_match_street`:
  feet, look point, lens and hour fitted to `docs/concept/street-golden-hour.png`, gun out).
  **The reference judge:** `python3 tools/judge.py --note="what changed"` renders
  `shot_match_saloon` and `shot_match_street` into a new round, `docs/screenshots/judge/<date>_r<n>/`
  (each render + `<view>_judge.png`: render | painting with a 3×3 grid of numbers, both 16-colour
  palettes, the biggest differences in words; `report.md`, `report.json`) and adds a line per view
  to `docs/screenshots/judge/history.md`. Measures (Lab, at 1280×720): brightness, warmth, chroma
  and contrast, the mosaic (detail: dE to a 3 px blur), tile size across/down (autocorrelation of
  the high-passed luminance), palette gaps; one score per view (mean severity, lower is closer).
  `--from=DIR` judges renders already made. Every art change is judged with it; keep every round.
- **The texture factory** (`tools/textures/`): `materials.json` lists the world's materials (id =
  the key `PixelArt`/`WoodMaterials` ask for: floor, saloon_wall, dark_trim, shot_table, framing,
  weathered_pine, painted_ochre/rust, sign, road) and lettered signs (sign_saloon, …), each with a
  crop of a painting for colour. `paint_textures.py` paints them on OpenRouter (FLUX.2 [max]; run
  it on Actions: People workflow, input `textures` = all / saloon / street / ids; openrouter.ai is
  blocked from the workspace) into `assets/textures/raw/<id>.jpg`; `reduce.py` (runs anywhere)
  flattens the painting's light, wipes board joints (`boards`), makes it seamless, cuts it to 64
  texels a metre with a pushed mosaic, applies the judge's `lightness`/`chroma`, snaps to a palette
  → `assets/textures/<id>.png` + `textures.json`. `PixelArt.factory(key)` hands them out in place
  of the code-painted texture of that key (`use_factory` off = the old ones); the grid material
  sizes any texture by its own size; the ground shader takes `road`. Change a material's numbers
  and re-run `reduce.py` here: no new painting needed.
- `src/props/prop_models.gd` (`PropModels`): every manifest prop modelled in code (lathe + boxes,
  UVs in metres, on `PixelArt.material()`); `PropLibrary` uses them where there's no .glb;
  `OilLamp` draws `PropModels.lamp()`. `tools/prop_views.gd out.png [--close]` shows them all.
- `src/art/saloon_dressing.gd` (`SaloonDressing.build()`, called by `SaloonBuilding`): plank walls,
  stair and balcony (members), mirrors, piano by the door, stag, pictures, sconces.
  `ShotMatch` turns its whole set (`ROOM_YAW`, `TABLE`) and stages extras (`EXTRAS`) for the shot.
- `src/art/sign_art.gd` (`SignArt`): the factory's painted sign boards, laid on once at their own
  shape; `FalseFrontBuilding` hangs one for its `sign_text` (SALOON, DRY GOODS, …) where there is
  one, else the lettered label. `src/art/street_dressing.gd` (`StreetDressing`, a node in the test
  street): signs on the blockout lots (its `LOTS` copy StreetScenery's), carriage lanterns, barrels,
  crates, hay, a horse at a rail, a covered wagon, telegraph poles and wire, the water tower. The
  sky (`src/world/sky.gdshader`, `disable_fog`) paints its own horizon haze, keeps the warm glow
  near a low sun and the rest blue, and has blocky clouds lit gold from below (dark at night).
  `src/art/mountains.gd` (`Mountains`, added by StreetDressing): red-rock mesas, buttes, spire
  clusters and a low ridge 450–750 m out (`FORMATIONS`; the biggest west, either side of the
  sunset as the painting has them), built from stacked rings with fluted cliffs, banded strata
  at 0.6 texels a metre, convex collision; `mountain.gdshader` is the grid material without the
  scene's fog (it buried them) and with its own haze (`#define HAZE` in `texel_grid.gdshaderinc`:
  `haze_color` follows the fog's colour, darkened violet).
- **Characters by image-to-3D** (`tools/characters/`, step 4 of the art plan; People workflow
  input `characters`): `paint_full_length.py` has the image model paint each man in
  `characters.json` full length in an A-pose (the painting's man as reference) →
  `assets/people/tripo/<id>_full.png`; `tripo.py` uploads it and asks Tripo for a textured model,
  then a rigged one → `<id>.glb` (+ `_mesh.glb`, every answer in `_tripo.json`); the folder is
  `.gdignore`d (pipeline inputs, not game assets). Needs the repo
  secret `TRIPO_API_KEY`; the client is untested against the live API. Fitting the result to our
  skeleton and hitboxes in Blender is still to come; MakeHuman stays the fallback.
- `tools/blender/` — the people pipeline: `fetch_makehuman.py` (CC0 assets, pinned to MakeHuman
  v1.2.0, into build/makehuman/), `make_people.py` (bpy: targets from `assets/people/people.json`,
  warp onto our joints, fit to `assets/people/envelope.json` — written by `tools/people_envelope.gd`
  — cut fingers, skin to our bones, decimate to 7k tris, export `.glb`), `clothes.py` (shirt,
  trousers, vest, coat with skirt draped by cloth sim + lapels + collars, string tie; AO baked with
  Cycles and quantized into `<id>_<garment>.png`; `<id>_head_ao.png` for the face painter; layer
  separation after decimation), `faces.py` (a front "guide" render of each fitted head, and a painted
  portrait projected into the face layout → `<id>_face.png`, RGBA). `tools/faces/paint_face.py`
  asks an image model on OpenRouter (`OPENROUTER_API_KEY`, `FACE_MODEL`) to paint `people.json`'s
  `face` onto the guide in the style of `assets/people/face_style_ref.png`. Runs on GitHub Actions
  (`.github/workflows/people.yml`, manual; commits `assets/people/`) or here:
  `python3.11 -m venv ~/bpyenv && ~/bpyenv/bin/pip install bpy==5.0.1 numpy pillow`, then
  `godot --headless -s res://tools/people_envelope.gd`, `python3 tools/blender/fetch_makehuman.py`,
  `~/bpyenv/bin/python tools/blender/make_people.py --only=outlaw` (~15 s; byte-for-byte repeatable
  except the face guide render). `CLOTH_PASSES=dir` saves each garment's raw bake passes for tuning.
- `tests/` — tiny self-contained runner (no addon): `extends TestCase`, methods `test_*`, may `await`.
  A Logger turns any script error during a test into a failure.
- CI: every push runs tests; pushes to `main` export Windows/Mac/Linux to a Release (notes from
  `docs/BUILD_NOTES.md` — update it each milestone) and the web build to GitHub Pages.

## Status

- 2026-09-27: Design session done; DESIGN.md and concept art committed. No code yet. Next: M0.
- 2026-09-28: **M0 built** on Godot 4.7.2. Pixel pipeline (640×360 default, F2 cycles, integer-scale
  option in settings), first-person controller (walk/run/crouch/jump/look, mouse + controller + touch
  on web, visible body with shadow-only head/hat/arms), test street (dirt road, boardwalk, member-built
  false-front store with open door, counter, shelves and lamps, hitching rail, trough, blockout town,
  hills), 45-minute day with sun/moon/stars/lamps and T to speed up (1×/30×/180×). 38 headless tests
  pass (project, pixel pipeline, controller, day cycle, structure support graph, walk road→store).
  Exports for all four platforms verified locally.
  - Known placeholders: boardwalk edges are invisible ramps (controller has no step climbing yet);
    one full moon every night; blockout buildings and props are plain boxes; no audio.
  - Support graph is "resting on any lower-tier member" — enough for load-path checks, not for spans
    or cantilevers (the porch rafters hang on the ledger alone). M3 needs loads and strengths.
  - Reference renders (software Vulkan via lavapipe, so a real GPU may differ slightly):
    `docs/screenshots/m0/`. Re-render with `tools/screenshots.gd` and compare after lighting changes.
  - Next: Sean's review of the look and feel, then M1 (the revolver).
- 2026-09-28 (later): **Meshy art trial set up.** A member-built `SaloonBuilding` across the street
  is the art test room (bar, back bar, card tables, piano, stag head, sconces; brighter night ambient).
  Loose props come from `assets/props/manifest.json` via `PropLibrary`: `<id>.glb` if present (scaled
  to the manifest's real size, anchored to floor or wall, box collision), else a placeholder box.
  `tools/meshy_fetch.py` generates the GLBs from the manifest prompts (needs `MESHY_API_KEY` and
  meshy.ai allowed in the environment's network settings; untested against the live API so far).
  F5 / D-pad up jumps between places. 43 tests pass.
  - Next: get the 12 models (script or Sean uploads GLBs), render the saloon views, judge against
    `docs/concept/saloon-night.png`. Watch GLB sizes in git (2K textures add up; downscale if needed).
- 2026-09-28 (later): **Art direction clarified by Sean** (DESIGN.md §4 updated): "high-resolution
  Duke Nukem 3D in real 3D" — low-poly models with pixel-art textures, modern lighting, but realistic
  mocap animation + physics/active ragdolls, and people detailed down to finger bones. This makes most
  props and buildings doable from code (pixel textures authored in code); Meshy is optional now.
  - Next: a proof pass on the store (code-made pixel textures, texel density ~32–64/m), and Sean to
    pick the internal resolution (fingers need ~960×540+ to read at table distance).
- 2026-09-28 (later): **Pixel-texture proof done.** `src/art/pixel_art.gd` paints tileable 64×64
  pixel-art textures in code (wood grain along u, knots, checks, peeling paint, dirt), 3–5 shades per
  colour; `src/structures/member_mesh.gd` gives members UVs in metres with the grain along their
  length; all members, blockouts and the ground use 40 texels/m with nearest filtering; sign text is
  chunky pixel lettering. Renders in `docs/screenshots/pixel_textures/`. 47 tests pass.
  - Next: Sean's verdict on the look and resolution, then M1 (the revolver) — the gun can be the
    first detailed code-built model in the new style.
- 2026-09-28 (later): Sean: "still looks very smooth, not really pixel". Added three live look knobs:
  F2 render resolution, **F7 texel size** (`PixelArt.set_density`, presets 40/mip, 24, 16 texels/m;
  every grid material is tracked and updated live), **F6 pixel shading** (`src/render/pixel_screen.gdshader`
  on the Screen: per-channel levels + 4×4 Bayer dither in low-res pixel space; `Settings.pixel_shading`).
  `tools/screenshots.gd` takes `--texels= --nomip --shade --res=WxH --window --suffix=` for comparisons.
  49 tests pass.
  - Next: Sean picks a combination (renders suggested ~480×270 + 24/m + shading); make it the default.
- 2026-09-28 (later): Sean liked the starting look (640×360, 40 texels/m smoothed) before pressing F7.
  F7 texel size is now a saved setting like F2/F6 (`Settings.texels_per_meter`), each change flashes
  the look on screen (`Settings.look_description()`), and F3 lists all three. 50 tests pass.
  - Next: confirm Sean's exact combination (res + shading) and make it the default.
- 2026-09-28 (later): **Look approved.** Sean likes the default (640×360, 40 texels/m smoothed, shading
  off) and wants the graphics options kept switchable on the fly (F2/F6/F7, saved). Recorded in
  DESIGN.md §4. The options go into a settings menu when there is one.
  - Next: M1 — the single-action revolver, built in code in the new style.
- 2026-09-28 (later): **M1 — the revolver — built.** `src/weapons/`: `RevolverState` (pure rules:
  single action, 6 chambers carried 5-up, half-cock + gate + ejector reload one chamber at a time,
  seeded misfires, belt ammo, to/from dict), `RevolverTuning` (`config/revolver.tres`), `RevolverModel`
  (Colt SAA from parts in code: moving hammer/trigger/cylinder/gate/ejector, brass rims show loads),
  `HandModel` (right hand, 3 bones per finger), `RevolverViewmodel` (controls, poses hip/aim/loading/
  holster, recoil, firing). `src/ballistics/`: `Ballistics` flies bullets on the physics tick (travel
  time, drop), penetrates members by thickness × `config/ballistics.tres` J/cm, pushes rigid bodies;
  `StructureMember.add_hole()` records holes (saved in `to_dict`) and draws them with
  `member_holes.gdshader` (through-holes are cut out, so light passes). Effects: `GunSmoke`
  (lit particles + FogVolume), muzzle flash, splinters/dust, spent brass as rigid bodies that stay.
  `SynthSounds`: gunshot with hill echoes, clicks, brass — generated in code. Range at the east end
  (target board + backstop, tin cans), F8 bullet traces, touch buttons for the gun. 70 tests pass.
  Renders in `docs/screenshots/m1/`.
  - Known gaps: hand is blocky (proper hands come with M2 anatomy); no left hand (rounds slide in
    by themselves); no fouling yet; glass takes bullets but doesn't show holes or shatter (M3);
    nobody to shoot yet (M2).
  - Next: Sean's feel review of the gun, then M2 — bodies.
- 2026-09-28 (later): Sean couldn't see/draw the gun. Exported Linux and web builds from main both show
  it (checked by recording the exported binary with `--write-movie` and the web build in headless
  Chromium) — most likely an older download. Fixes anyway: gun keys (Q/R/H) work without a captured
  mouse (only mouse buttons wait for capture); CI stamps `build_info.json` so F1/F3 show "build N (sha)".
- 2026-09-28 (later): Sean: slows down after shooting, smoke sits still, shot windows go opaque.
  Glass members now `shatter()` into rigid shards (group `glass_shards`, persist) with a synth
  "glass" sound; `broken` is saved; the bullet carries on (Events.member_broken). Smoke: tuning in
  `config/smoke.tres` (wind, indoor factor via roof raycast, rise, turbulence, caps: 8 clouds / 4 fog
  volumes); particles ride the drifting node (local coords), no shadow casting. `GunSmoke.warm_up()`
  draws every effect once at load (smoke, fog, flash, splinters, hole shader) to avoid first-shot
  shader-compile hitches. Couldn't reproduce a big slowdown on lavapipe (`tools/perf_probe.gd`
  measures frame time per effect part); asked Sean for F3 fps before/after. 75 tests pass.
- 2026-09-28 (later): Builds 27 and 29 (PRs #7, #8) never ran: the build-number step's one-line
  `run: echo "{\"number\": ...}"` has ": " in a plain YAML scalar, so GitHub rejected the workflow and
  the web/releases stayed on build 26. Fixed with a block scalar + printf; always parse the workflow
  YAML before pushing CI changes (command above).
- 2026-09-28 (later): Build 32 had the glass fix but Sean's browser kept the cached `index.pck`. CI now
  renames it `index-<run>.pck` and points `mainPack` at it, so every build is fetched fresh. F1 help's
  first line is "SALT CREEK BUILD N (sha)" and a small build label sits in the bottom-right corner.
  No FogVolumes on the Compatibility (web) renderer. New test: shooting a store window with the
  player's gun breaks it. 76 tests pass.
- 2026-09-28 (later): Sean confirmed build 35 in the browser: glass shatters, version shows. The cached
  build 32 was the problem; per-build pck names fix it from 35 on.
  - Next: Sean's feel review of the gun (rhythm, recoil, sound, smoke, auto-cock?), then M2 — bodies.
- 2026-09-28 (later): Sean wants the saloon concept painting's look as the target. Look pass planned
  **after M2** (DESIGN.md §4): outline/rim/palette final pass, image-model pixel textures, denser dressing.
  - Next: M2 — bodies.
- 2026-09-28 (later): **M2 — bodies — first playable.** `config/anatomy.json` (17 segments; skull,
  spine, ribs, pelvis, long bones; carotid/subclavian/brachial/radial/femoral/popliteal arteries and the
  aorta; brain, heart, lungs, liver, spleen, kidneys, gut; ten fingers). `Anatomy.trace()` follows the
  ball through flesh (13 J/cm), breaks or stops on bone, cuts arteries, tears organs, takes fingers.
  `Physiology`: bleeds with clotting, pressure and tourniquets; shock and blackout from blood loss;
  pain arriving over seconds and masked by adrenaline; collapsing lungs; broken neck; the gut wound
  that kills over ~30 game hours. `HumanBody`: the test outlaw (hitbox per segment, low-poly pixel
  meshes, hands finger by finger, clothes with holes, entry/exit decals and stains that spread as he
  bleeds, a blood pool, ConeTwist ragdoll when he can't stand, fingers and gun as rigid bodies).
  `OutlawBrain`: calm until shot at, then fights (5 shots, 12 s reload); fear from near misses, hits,
  pain, shock, an empty hand and "Drop it!" (G) while covered; surrenders past his nerve. Player wounds
  (`PlayerWounds`): the same anatomy, red flash, grey edges, crawl on a broken leg, no running with a
  holed lung, gun gone with a broken arm, hold B for pressure then a belt, blackout → come round in
  the store. Sounds: flesh hit, near-miss zip. Subtitles for speech. F9 new outlaw. 108 tests pass.
  Renders in `docs/screenshots/m2/`.
  - Known gaps: no animation beyond poses and spring flinches (no mocap yet, no active ragdoll
    balance, no clutching the wound or crawling for the outlaw); he doesn't move, take cover, flee
    or tend himself; knees are cone joints (can bend the wrong way); player's own body doesn't show
    wounds; no doctor, so blackout just puts you in the store; decals don't draw on web.
  - Next: Sean's verdict on the gunfight, then tune (accuracy, nerve, bleed times) before M3.
- 2026-09-28 (later): Sean ran the Windows build on his mini PC (fine). **More anatomy + blood.**
  `tools/anatomy/build_anatomy.py` writes config/anatomy.json (115 structures): radius/ulna,
  tibia/fibula, patella, scapulae, jaw, sacrum, eyes, windpipe, gullet, spinal cord (kind `nerve`,
  separate from the vertebrae), jugulars, subclavian veins, vena cava, abdominal aorta, iliac, axillary,
  ulnar and tibial arteries, femoral vein, muscles (`group` leg/arm/grip), radial/median/sciatic nerves.
  Chest and abdomen hitboxes are three capsules each (wider than deep); shoulders slope. Physiology:
  bleed kinds (artery/vein/ooze), blood pressure slows bleeding, heart rate, muscle strength → limp and
  aim sway, cord cut → paralysis (vertebra alone doesn't), windpipe/jaw → can't speak, eyes.
  `BloodJet` (pulsing arterial stream / venous pour / drip, per wound) and `Blood` (persistent splats
  on ground and walls, exit-wound spray, coughing blood, player's drip trail). F10 X-ray view.
  A test keeps every structure inside its hitbox. 117 tests pass.
  - Next: Sean's verdict on the blood and detail; then gunfight tuning or the people art pass.
- 2026-09-28 (later): **Gunfight tuning, round 1.** Sean: "he can take too many gunshots". Measured
  with `test_body_hits_to_stop_him` (24 fresh outlaws, random chest/belly hits from 8 m): 2.12 body hits
  on average before; now **1.46** (a mix of 1s and 2s). Changes: adrenaline masks 45% of pain (was 75%);
  knockdown from the hit itself (`knockdown_*` in config/physiology.tres, trunk/hips/thighs/head; up
  to 45%); stagger after every hit (no shooting for ~0.5–1 s); pain past `pain_disabling` doubles him
  over (clutch pose, no shooting); fear per hit 0.25 + 0.14 if severe + energy/2000, plus fear from
  his own bleeding; liver 8, spleen 5, kidney 4, lung 2 ml/s; lungs collapse in 35 s. 118 tests pass.
  - Next: Sean plays it; tune from his feel (aim, nerve, limb hits).
- 2026-09-28 (later): Sean skipped animation for now (repo is **public**: Mixamo files must not be
  committed unless it goes private). **M3 started: loads and collapse.** `StructuralAnalysis` sends
  each member's weight (+ `extra_load`) down the support graph to the ground (conserved: the store is
  5.7 t), checks upright members in compression/buckling (sheathed studs braced) and lying members in
  bending over spans with overhangs as cantilevers; a member hanging off one support, or an overhang
  tipping it off the next, is held only by nails (`joint_moment`, `joint_uplift`); bullet holes weaken
  the section. Contacts are regions (a timber lying along another bears on its whole length); the
  same kind can rest on itself when stacked (backstop). `Structure.settle()` snaps the worst
  overloaded member in two where it's weakest, drops unsupported members as connected clumps that
  break up on hard landings, falling timber breaks what it hits (`impact_toughness`), rubble stays and
  is in `to_dict()`. F11 breaks the member you look at. Crack/crash sounds, dust. 125 tests pass.
  - Guessed numbers, to check against published sources (not Sean): wood strengths, nail joint
    120 N·m / 600 N, rafter pairs as trusses, a porch beam can't carry the awning off one post.
  - Next: Sean's review; then fire (spread along dry timber, not stone), then dynamite.
- 2026-09-28 (later): **M3: fire.** `FireSystem` (one per world, in the test street) ticks every 0.25 s:
  burning members heat what they touch (`contact_heating`), what's straight over them within
  `flame_height` as if touching, and what's near (`radiant_heating`, fading to `reach`); up full,
  sideways 0.45, down 0.12; heat soaks in by thickness, things cool to ambient. Past 290 °C wood
  burns; stone and glass don't (glass cracks at 240 °C). Burning chars from each face (0.25 mm/s,
  ~50× real): `StructureMember` counts only sound wood (cross-section and weight), so settle() every
  second brings burning buildings down; thin stuff burns to ash (`consumed`, removed). Members keep
  their mesh pieces as they fall, so rubble burns on. `FireFX`: flame tongues, dark lit smoke, char
  overlay with chunky embers; up to 6 fire lights with crackle. Oil lamps have hitboxes: a lit one
  shot smashes and spills burning oil. People within 0.5 m of flames are burnt (`Physiology.burn`,
  pain, death past `burns_fatal`); the outlaw's fear rises. F12 ignites what you look at. A store's
  roof comes in ~2 minutes after the back wall's lit. 134 tests pass. Renders in docs/screenshots/m3/.
  - Known: long members (5 m roof boards) heat their whole length at once, so fire jumps along them;
    no water/bucket brigade; smoke doesn't choke people yet; fire never spreads to the ground.
  - Next: Sean's look; then dynamite.
- 2026-09-28 (later): Sean: "fire didn't work, F12 isn't an option". Run 60 (the fire merge) failed
  on main: `test_porch_comes_down_without_its_posts` is physics-flaky on CI (a rubble piece propped
  up), so nothing was exported and Sean still had build 59. The test now wants ≥85% of pieces down.
  Also F11/F12 belong to the browser (full screen / dev tools): debug break and ignite are now **K**
  and **L** as well. Always check the main run went green after a merge.
- 2026-09-28 (later): Sean: "reloading moves the body to the side or back; shooting close to a wall
  the arm goes through". Cause 1: spent cases spawn at the gate, inside the player's 0.3 m capsule,
  and depenetration pushed the player 0.45 m over a reload. New physics layer `Layers.DEBRIS`
  (brass, glass shards, cans, dropped gun; mask `DEBRIS_MASK` = world + debris): the player never
  collides with it, bullets do. Fix 2: `RevolverViewmodel` sweeps a small sphere from the eye to
  where the muzzle is heading each physics tick and blends to a tucked pose (`TUCK_POS/ROT`, `tuck`
  0–1); bullets start on the near side of anything between eye and muzzle (`last_shot_origin`).
  Tests: no drift over a reload, muzzle stays this side of a wall, wall shot hits that wall.
  Screenshot views `gun_at_wall`, `gun_at_wall_aim`. 137 tests pass.
  - Rule: loose small rigid bodies go on `Layers.DEBRIS`, never the default layer.
- 2026-09-29: Sean: the fire "sits between the grain and the board". Two causes: flame particles spawned
  inside the member's box (half of each flame hidden by the wood), and the char overlay's embers were
  bright yellow squares on a grid, reading as fire inside the texture. Flames now spawn in a shell
  round the member and use `src/fire/flame.gdshader` (billboard pulled 0.22 m toward the camera so
  the board it's on can't clip it); embers are the odd dull-red pixel in deep char only.
- 2026-09-29: **M2 follow-ups, part 1: grazes, glass cuts, blunt trauma** (order agreed with Sean:
  this, then visible interior + wound volumes + gore setting, then shotgun, then dynamite).
  `Anatomy.trace()` reports `depth` and `graze` (exits and never deeper than 1.8 cm): grazes bleed
  less, sting (`pain_graze`), draw a furrow decal along the path. `GlassCuts.spray()` (called from
  `StructureMember.shatter`) traces 8–22 low-energy shards (80% onward, 20% back) and calls
  `take_cut` on anyone hit (HumanBody and PlayerWounds): shallow slices, 30% leave a shard in
  (`embedded`). `Physiology.blow(segment, joules, rng)`: bruise always; thresholds in
  `PhysiologyTuning.blunt` for concussion (out cold for a while), skull, ribs, lung, a burst
  spleen/liver (bleeds `internal`: no jet, no clotting, pressure/tourniquet can't reach it; describe
  says "going pale with no wound to show"), pelvis and limb fractures. Rubble hitting a body part, a
  standing man's blocker or the player calls `take_blow` once per piece per person; `segment_at()`
  finds the part by nearest capsule; big blows knock a man down. Wound `kind`: bullet/graze/cut/blow.
  Outlaw fear per kind. 144 tests pass.
  - Next: visible interior anatomy with wound volumes and a reduced-gore setting (DESIGN.md §7).
- 2026-09-29: **M2 follow-ups, part 2: visible interior.** All body meshes use `body_skin.gdshader`
  (their pixel texture, triplanar in mesh space, plus up to 8 wound openings per mesh: discard inside,
  a ragged torn-flesh/soaked rim, blood beyond; reduced gore paints it dark and closed).
  `HumanBody.open_wound(segment, at, joules)` merges hits within 6 cm; radius = 0.0013·√J (capped at
  1.2× the segment radius), shown from 1.8 cm. take_bullet feeds it: 25% of deposited energy at the
  entry (60% if it lodged) plus the muzzle's blast point-blank (+300 J under 0.3 m, tapering to 1.5 m),
  75% at the exit; grazes don't open. On a part's first opening `BodyInterior.build()` adds (layer
  `VIS_INSIDE`, no shadows) a flesh wall seen from inside (`body_inside.gdshader`, opened too where a
  wound goes through), ribs as bars clipped to the skin, skull as an openable bone shell, and the
  other structures as pixel-textured capsules pulled in 1.3 cm from the faceted skin. Openings are
  saved. `Settings.reduced_gore` (F4, saved). J opens a 1500 J wound where you look (debug).
  151 tests pass. Renders `docs/screenshots/m2/outlaw_open*.png`.
  - Next: the shotgun (pellets traced separately; point-blank destroys a region, rib fragments fly).
- 2026-09-29: **M2 follow-ups, part 3: the shotgun.** A 12-bore hammer coach gun (`src/weapons/
  shotgun_*.gd`, `config/shotgun.tres`): two barrels, two hammers, right barrel first; R breaks it
  open, pulls the empties, loads, closes. 1/2 pick the gun, wheel up / Y swaps (Y no longer changes
  time speed). The revolver moved onto a shared `WeaponViewmodel` base. `Ballistics.fire_charge`
  flies 9 pellets of 00 buck (3.5 g, 400 m/s, ~280 J), each off the line by a normal spread
  (`pattern_degrees` 0.5: ~75 cm at 25 m) and sharing one near-miss record. Bullets carry `blast`
  (joules into the first thing they touch; revolver 300, the shotgun's 1600 split between pellets,
  gone by `blast_reach` 2.5 m: the charge arriving as one mass). `take_bullet` takes it; wounds from
  anything under 6 g are kind `pellet` (small decals, bleeding scaled by bore, nearby pellet wounds
  share one blood stream; describe says "buckshot, N pellets"). An opening past
  `HumanBody.DESTROY_ENERGY` (1000 J) destroys the region: bone inside it broken
  (`Physiology.break_bone`; ribs blown out collapse that lung) and thrown as `bone_fragments`
  (DEBRIS layer). A revolver ball never gets there. Renders `docs/screenshots/shotgun/`,
  `tools/gun_views.gd` renders the viewmodel alone. 163 tests pass.
  - Known: the stock and butt are hidden when shouldered (they'd fill the view); no firing both
    barrels at once from the controls yet (`ShotgunState.pull_both()` exists); the outlaw only has
    a revolver.
  - Next: Sean's feel review of the shotgun (spread, how bad point blank looks); then dynamite.
- 2026-09-29 (later): Sean: the shotgun drops men in one shot at long range. Pattern 0.5° → 0.85°
  (σ; ~60% of pellets inside 0.5 m at 25 m); air drag for every projectile (`BallisticsTuning`
  `air_density`/`drag_coefficient`: a pellet keeps ~80% of its energy at 25 m, a .45 ball ~92%);
  pellets roll knockdown at `knockdown_pellet_share` 0.3 and fear at `fear_pellet_share` 0.4 of a
  ball's. `test_at_twenty_metres_a_charge_rarely_drops_him`: 14/16 down before, ~5/16 now. 165 pass.
  - Sean also sees his right monitor (dual setup) blank for a moment when the shotgun fires or K
    breaks timber. Not reproducible here; asked which build, which screen the game is on, whether the
    revolver does it, and how the monitor's connected (HDMI with audio is a suspect).
  - Sean's answers: Windows build on the left screen; only the shotgun and K do it (K very often);
    the right monitor is HDMI and carries the sound (the sound stops when it blanks). Likely the
    monitor's speaker amp dropping out on full-scale deep bass (the shotgun boom swept to 28 Hz, the
    timber crash to 45 Hz). `Settings._protect_speakers()` puts a 40 Hz high-pass and a hard limiter
    (−3 dB in, −1.5 dB ceiling) on the Master bus; the gunshot thump never goes below 40 Hz.
    166 pass. If it still happens with sound sent elsewhere, it's the GPU/HDMI link instead.

- 2026-09-29 (later): **M3: dynamite.** `src/blast/`. One stick = 0.15 kg TNT (`tnt_per_stick`);
  `Blast.overpressure_kpa`/`impulse` are the Kinney-Graham free-air fits (1 m ≈ 240 kPa, 3 m ≈ 23,
  10 m ≈ 5). Timber breaks when (Σ impulse × face area)² / 2m, reflected ×2, beats `absorb_factor`
  × f²/2E × volume (woods from `config/timber.tres`); `Structure.break_members()` snaps a batch and
  settles once. One stick 25 cm from the store's side wall: 5 boards, no framing. Panes by pressure
  (3.5 kPa, ~10 m). Splinters: 2 g projectiles, wound kind `splinter` (treated like pellets).
  Fireball 0.75 m, 12% ignition per member in it. People: `HumanBody.take_blast` (pressure per part
  by distance to its skin, ×0.35 behind a standing wall; `Physiology.blast_injury`: eardrums 35–140
  kPa, blast lung 250/700, concussion 150; opens parts past 800 kPa; `sever_limb()` past
  `sever_kpa` — frees the ragdoll joint, opens both ends, stump bleed; thrown down past 60 kPa).
  `PlayerWounds.take_blast` (`held` = in your hand: the hand goes), ringing + Master low-pass
  (`ringing`, permanent muffle per burst eardrum), view shake. `DynamiteViewmodel` (3): Q lights (0.9 s
  match), hold/release LMB throws 6–15 m/s, RMB places, lit too long goes off in hand. Ballistics:
  a bullet through a `DynamiteStick` sets it off 25%; `Bullet.kind`; `take_bullet(..., projectile)`.
  Outlaw fears blasts by kPa. Events.exploded. Renders `docs/screenshots/dynamite/`. 179 pass.
  - Known: no crater or thrown dirt piles; bodies thrown only a little (true for one stick);
    brick/adobe members don't exist yet (TOWN.md); can't pick sticks back up; no bundles yet; the
    player's own severed hand isn't shown (no visible player arms beyond the gun hand).
  - Next: Sean's review of dynamite; then the M2 follow-ups left (outlaw cover/fleeing/tending,
    active ragdoll balance) or rope.
- 2026-09-29 (later): Sean: dynamite "doesn't destroy the buildings nor damage the bad guy". Causes:
  impulse was sampled at 5 points on a member's centre line (a stick lying on a floorboard read as
  ~0.4 m off it), and the round stick rolled away. `Blast.face_impulse()` now sums impulse over the
  face with samples bunched at the nearest point, plus a local check over `local_span` 0.3 m (the
  member snaps there: meta `blast_t`); the stick has friction/damping; ground blasts throw
  `ejecta_count` 80 gravel projectiles (kind `gravel`, 3 g, 90–220 m/s, under 35°); a stick is
  0.2 kg TNT; blast knockdown from 35 kPa. Blast RNG seeded by position (deterministic). Street
  tests: thrown at the store 11 timber broken; floor blown through; 1.5 m from the outlaw he's down
  with gravel wounds. The shotgun player test turns misfires off (seeded by node path). 182 pass.
- 2026-09-29 (overnight): **M2 follow-ups: the outlaw fights like a man.** `HumanBody`: code-made
  poses crouch/crouch_aim/duck/tend/lie/prone/prone_aim (+X swings a hanging limb forward, leans the
  trunk back; `_place_rig()` lowers the rig so the lower foot stays on the ground, or lays it
  face-down), a gait overlay (walk/run/limp/crawl from `move_speed`), `walk_to()` (sphere-cast
  slide along walls and people, ground snap, step up to the boardwalk), `prone` (legs gone but
  conscious: posed on his belly, not a ragdoll; `_can_crawl()`), blocker follows the pose. Ragdoll
  knees and elbows are `HingeJoint3D`s (limits from the current bend; the hinge's angle runs opposite
  to the poses' X). `Cover`: a spot is hidden if rays from the threat's eye to his head/chest (and
  18 cm either side) are stopped within 1.6 m of him (heights from the poses: duck head 0.97,
  crouch 1.23, lying 0.42); needs a peek (rise, or lean out ±0.6–1.8 m) and a route (straight or
  one waypoint round). `OutlawBrain`: tactics with cover, suppression from near misses, flanking
  after ~10–18 s or 4 peeks, flee (`flee_chance`, needs `can_run`, not within 5 m or covered close),
  tending (`tend_bleed`, `tend_quiet`: pressure, then tourniquet/bandage), prone fighting; a second
  RNG (`_think`) so tactics don't change his aim. `RangeCover` (woodpile, barrels, crates, fence) on
  the range. `tools/pose_views.gd` renders the poses. Renders `docs/screenshots/outlaw_ai/`.
  197 tests pass.
  - Known: no real pathfinding (straight lines and one waypoint); prone men don't seek cover;
    the posed movement is stiff until mocap; he can't get up from a ragdoll fall.
  - Next: Sean plays it; then the people art pass or rope.
- 2026-09-29 (later): **Decided with Sean (DESIGN.md §9 "Nobody is an enemy by default"):** no hostile
  flag; deeds judged the same for everyone; provocation depends on the man; an escalation ladder
  (ignore → notice → wary → warning → threat → fight) that can step back down; hostility per person
  and moment; the gang starts trouble on its own; called-out duels; beaten men bargain.
  - Next (agreed order, start of M4, not started): 1) senses for everyone (sight/hearing,
    last-known position, searching); 2) deeds + per-person opinions + the escalation ladder (first
    test: "a man at the bar" who does nothing until someone does something, then reacts to whoever
    did it); 3) goals and a day in town for the gang; 4) gang teamwork in fights (callouts,
    suppress-and-flank, dragging a wounded friend); 5) conversation hooks (talking down, bargaining).
    Today's `OutlawBrain` targets the player only; that goes in step 2.
- 2026-09-29 (later): **M4 start, steps 1–2: senses, deeds, opinions, the escalation ladder.**
  `src/people/`. Senses tick at ~8 Hz: sight 60 m by day / 14 m at night (`light`, or the DayCycle's
  daylight), 35° sharp / 100° peripheral, awareness builds with visibility (distance, cone, moving
  ×1.4, crouched/lying ×0.55) and must reach 1 to "see"; hearing takes `Events.noise(at, loudness,
  kind, source)` (gunshot 350 m, blast 900, glass 40, timber 60, shout 45, speech 14, footsteps
  2/6/13 crouch/walk/run), halved through a wall, placed with ~12% error. Deeds only count if
  perceived (seen, or loud, or done to him while he's aware). Relations: pressure per deed
  (`WEIGHTS` [to him, to a friend, near him]; petty ones × temper), grudge floor, a rung per 0.8 s up,
  down after 2.5 s below; shot at / hit = straight to FIGHT with a grudge. `OutlawBrain`: `_social()`
  runs the ladder (look, wary pose with hand by the holster, warnings, drawing and covering with aim
  deeds of his own), `_pick_fight()` fights whoever it's FIGHT with (not "the player"), stands down
  when that man is out of it; SEARCHING tactic goes to the last known spot, gives up after 25 s.
  `HumanBody` holsters and draws (`start_holstered`, 0.5 s draw). **The player now starts holstered**
  (H draws); tests that need a drawn gun draw it. The shooter is recorded on hits
  (`last_hit_by`) for kill deeds. Renders `docs/screenshots/outlaw_ai/outlaw_wary.png`,
  `outlaw_covering_you.png`. 211 tests pass.
  - Known: the only NPC is the outlaw (the "someone else" in tests is a second outlaw); no insults
    until conversation; lamps don't light people up for sight yet; no crowd reactions; friends list
    only matters once there's a gang (step 3–4).
  - Next: step 3, goals and a day in town for the gang (with called-out duels and the gang starting
    trouble), then step 4, gang teamwork.
- 2026-09-28 (later): Sean: "the model for the bad guy is pretty horrible". **People art pass, first
  step.** `BodyMesh` (src/bodies/body_mesh.gd) lofts one continuous skin through cross-sections
  (trunk, neck, head, arms running into the palms, legs; tables `TRUNK/NECK/HEAD/ARM/LEG`, right side
  mirrored) fitted round the anatomy hitboxes, plus clothes as looser shells (shirt with cuffs, vest
  open in a V, trousers, boots with shaped feet, cartridge gun belt + trouser belt, holster, bandana,
  hat with a creased crown and curled brim; optional coat). All skinned to a flat `Skeleton3D` in
  `HumanBody` (a bone per segment, weights blended at joints); `_update_skeleton()` copies each part's
  transform every frame, so it follows poses, flinches and the ragdoll. Each shape is **cut into a
  piece per segment** (triangle → the bone that moves it most; `skin_meshes["shape/segment"]`,
  `segment_pieces[sid]`, `body_meshes(sid)` = pieces + whatever's on the visual node) so the other
  session's openings work: pieces use the wound shader with `use_uv` + `use_custom_pos` (CUSTOM0 =
  rest position in the segment's centred space, so openings need no conversion; `_apply_openings`
  feeds them), `body_skin_double.gdshader` for open garments (shared code in
  `body_skin.gdshaderinc`). `sever_limb` swaps every piece to its rigid mesh so nothing stretches
  across a lost joint. The trunk is as wide as the chest/pelvis hitboxes so the ribs stay inside. Fingers stay rigid (tapered
  hex prisms). `PeopleArt` paints cloth (plain/wool/denim/stripe/felt/leather), skin, a cartridge
  belt and **faces** (96×64 wrapped round the head: eyes, lids, brows, nose, mouth, moustache styles,
  stubble/beard, age lines, scar, hair) from a `look` dict on HumanBody. Meshes cached per outfit.
  Tests: 17 bones, every shape built on VIS_BODY, skin within 7 cm of hitboxes, skin follows the
  ragdoll. New screenshot views `outlaw_face`, `outlaw_face_evening`, `outlaw_side`, `outlaw_back`;
  renders in `docs/screenshots/people/` (this container had no Vulkan, so they're from the
  Compatibility renderer: washed out at noon compared with earlier lavapipe renders). 213 tests pass.
  - Next: Sean's verdict; then the player's own body from BodyMesh, more faces/outfits for townsfolk,
    and a moustache/hair mesh pass if the painted ones don't read at distance.

- 2026-09-29 (later): **M4 step 3: a day in town, backing down, call-outs and duels.**
  `TownLife` (in `scenes/test_street.tscn`) puts the storekeeper behind his counter and the barkeep
  behind the bar (`CivilianBrain`, no gun), and 45 s in (or **U**) three riders come in from the west:
  Brody (cool, nerve 0.95, proud), Lyle (hothead 0.9, proud) and the Kid (0.45, nerve 0.3). Their
  `agenda`: walk in (`Waypoints` routes, door-wide checks), drink at the bar, then Lyle and the Kid
  go and lean on the storekeeper (taunts, a shove deed, Lyle draws on him at 14 s), back to the bar,
  and out west (they're freed at the edge of town). They get on with it while nobody's troubling
  them; any rung ≥ WARY with someone (not a man they've backed down from) switches to `_social()`.
  Standoffs: at THREAT, aim_at pressure × 0.25 × lerp(0.5, 1.5, temper); being aimed at scares
  0.045/s. Nerve breaking before it's a fight (CALM, stance ≥ WARY) = **backing down**: holster,
  a line, `Relations.back_down()` (cowed: aim/draw/shout/crowd/stare count 0.1×, stance capped at
  WARY), drop the plan, sulk at the bar, and a proud man then **calls you out**: goes to a street
  spot 12 m from you, shouts, waits up to 60 s ("Coward!"); if he sees you within 30 m it's a
  **duel**: wary pose, draws after 2.5–5 s or the moment you draw, fights with no cover
  (`_stand_and_fight`). Told "Drop it!" with a gun on him instead, he still surrenders. **You can
  call a man out**: G with your gun holstered (a `call_out` deed to the armed man you're facing);
  temper ≥ 0.4, a grudge, or pride accepts ("Suits me."), else "Not today." Friends' deeds to
  others don't provoke. After a fight a gang member leaves town. The storekeeper puts his hands up
  when a gun's on him, cowers at shooting, and thanks whoever ran them off (a back_down or
  surrender to you, or you hitting one). New poses `cower`, `shove`; `hat_color.a == 0` = no hat.
  Renders `docs/screenshots/town_day/`. 221 tests pass (`test_town_day`, 9).
  - Known: routes are a hand-made waypoint graph (no navmesh); no one sits (stools), drinks are
    just standing at the bar; the storekeeper doesn't hand over money (no economy yet); a man
    killed at the far end of town isn't mourned by the others (no memory records yet); agenda isn't
    saved (`to_dict`) — the gang is a test scenario, not yet part of saves.
  - Next: Sean plays the day (see BUILD_NOTES); then step 4, gang teamwork in fights.
- 2026-09-29: Sean's handing the character look to the build sessions: **next art work is DESIGN.md §4
  "Characters: how we get to the painting's men"** — 1) shot-match saloon scene with the man at the
  table, 2) MakeHuman base mesh via a Blender pipeline on GitHub Actions, fitted to the skeleton and
  hitboxes, 3) baked pixel textures and draped clothes, 4) image-model faces, then lighting.
  Compare every round side by side with `docs/concept/saloon-night.png`.
- 2026-09-29 (later): **Characters, steps 1–2: the shot match and a MakeHuman body.**
  `ShotMatch` stages the painting's shot at the saloon's back card table at night: round table
  (0.7 m radius), lamp, bottle, cups, ashtray, a man sat at its left side (new `sit` pose, cup in
  his left hand), camera at seated eye height with a 48° lens. `tools/side_by_side.py` composes
  render vs painting; rounds in `docs/screenshots/shot_match/`. **Blender pipeline:** MakeHuman
  base.obj + targets (caucasian male young/old mix, muscle, thin) → our body space → warp by
  joints (per-bone move/turn/stretch, soft blend 1.2 cm) → cross-sections scaled to BodyMesh's
  TRUNK/NECK/HEAD/ARM/LEG envelope (92nd percentile, clamped, smoothed; head heights remapped so
  eyes/mouth sit at the face painter's 1.655/1.598 m) → fingers cut at the knuckles (ours are
  separate parts) → weights from the same tables BodyMesh uses → decimate (5.6k skin + 1.4k head
  tris) → `assets/people/outlaw.glb` (bones and meshes `body_skin`/`body_head`; a mesh named like
  a bone makes Godot rename the bone). Byte-for-byte repeatable. `PeopleBodies` swaps the
  generated skin/head into BodyMesh's shapes (`BodyMesh.split_pieces()` shared); clothes are still
  BodyMesh's. 225 tests pass (new: `test_shot_match`, generated-body test).
  - Known: painted face features only roughly line up with the sculpted face (step 4 replaces
    them); lofted clothes over the MakeHuman body (step 3 drapes real ones); the MakeHuman eyes
    are painted by the face texture; no teeth/tongue/eyelashes (dropped helpers).
  - Next: step 3, baked pixel textures and draped clothes (coat with lapels, vest, shirt, cravat).
- 2026-09-29 (later): **Characters, step 3: draped clothes, baked pixel textures.** `clothes.py`
  makes garments as shells over the fitted body (shirt 5 mm, trousers 8, vest 13 with an open V,
  coat 24 with an open front to the waist), extrudes a coat skirt from the hem (6 rings, flaring,
  open at the front) and drapes it with Blender cloth (top pinned, heavy wool, body collider),
  raised lapels, collars, a string tie. Each garment: smart-UV, Cycles AO (10 cm reach, 128
  samples, blurred), a little weave, quantized to 5 shades at ~48 texels/m → PNG (lossless,
  nearest in game; not embedded in the glb). After decimation, `separate()` pushes each layer
  out of the ones under it. The head gets `outlaw_head_ao.png` in the face painter's layout;
  `PeopleArt.face(look.ao)` then skips its painted eye-socket/nose/ear shadows and shades skin a
  band at a time. `people.json` `outfit` sets garments and colours; a man whose outfit lacks one
  (no coat) doesn't wear the model's. Bug fixed: the trunk's capsule reached past the chin, so
  face vertices were trunk (a shirt patch over the face). 226 tests pass.
  - Known: garments are made in the standing pose, so the skirt deforms by skinning when he sits
    (thighs can poke through); no buttons/pockets; hat, boots, belts still lofted; the face is
    still the code-painted one (step 4).
  - Next: step 4, image-model faces (needs Sean's key), then the lighting pass.
- 2026-09-29 (later): **Lighting pass, first round (on the shot match).** Lamps: glass chimney
  (faint, lit from inside) with a small bright flame, warmer-golden light (1, 0.74, 0.48), and
  `haze` (light_volumetric_fog_energy 1.2) so they glow in the air. `FalseFrontBuilding.room_haze`
  fills a room with a FogVolume (Forward+ only; denser under the roof): the saloon has 0.012 of
  tobacco smoke; its night ambient is 0.1 (was 0.2), so lamps make pools of light. Render:
  `docs/screenshots/shot_match/round4_lighting_vs_concept.png`.
  - Waiting on Sean: an image-model key for step 4 (faces). openrouter.ai is blocked by this
    workspace's network policy, so the face step is meant to run on GitHub Actions with a repo
    secret `OPENROUTER_API_KEY` (or the workspace needs the key as an env var and openrouter.ai
    allowed).
- 2026-09-29 (later): **Step 4 set up, waiting on the key.** `faces.guide()` renders the fitted head
  front-on (Cycles on CPU: Workbench/EEVEE need a GPU; 512 px, 0.3 m frame centred at 1.665 m) →
  `outlaw_face_guide.png`. `paint_face.py` sends it + the style crop + the prompt to OpenRouter
  (chat completions, `modalities: [image, text]`, default `google/gemini-2.5-flash-image`; the API
  call is untested — no key and openrouter.ai is blocked here) and saves `<id>_face_portrait.png`;
  the next make_people run projects it (per-triangle raster in numpy, weighted by how square each
  triangle faces front, 24-colour palette) into `<id>_face.png`, which `PeopleArt.face(look.portrait)`
  lays over the painted face (dithered edge). Checked with a marker portrait: eyes land within 2
  texels of the painter's eye row/columns. `people.yml` runs paint + a second make when the repo
  secret `OPENROUTER_API_KEY` exists (optional repo variable `FACE_MODEL`); inputs `only`, `repaint`.
  - The workflow only shows in the Actions tab once it's on main.
- 2026-09-29 (later): **Step 4 done: the first image-model face.** Sean added the repo secret; the
  first People run failed with a 400 because an unset repo variable arrives as an empty string
  (`FACE_MODEL=""` sent an empty model); fixed (`or` default) and errors now print OpenRouter's
  reason. Run 2 (dispatched on the branch) painted `outlaw_face_portrait.png` (1024², Gemini 2.5
  Flash Image; matched the guide's outline) and projected it; renders
  `docs/screenshots/shot_match/round5_face_*`.
  - Next: Sean's verdict; then more lighting (the painting's warm key on one cheek, rim light),
    room dressing, and faces for the townsfolk (their own `people.json` entries).
- 2026-09-29 (later): **People fixes from Sean's in-game screenshots.** (1) Long pencil neck and
  egg head: the warp stretched MakeHuman's jaw-hinge "head" joint→crown onto our longer head
  segment (×1.5); trunk/neck/head now move as one at his own proportions (scaled to our height),
  the envelope fit is 0.45/0.4 on trunk/limbs and off for neck and head, and the face remap pins
  only chin/eyes/crown (MakeHuman's mouth joint is above the lips). (2) Streaks round the neck:
  collars are now bands built from the garment's own faces, and every neck height in
  `clothes.py` comes from `person.neck_y`. (3) A red bandana floating off the neck: a generated
  body with a tie drops the lofted bandana. (4) **Coat "bat wings" with hands up**: the skirt was
  extruded from every low boundary edge, including the sleeve cuffs; the hem is now only verts
  with no arm weight, and skirt weights never include arm bones (test
  `test_the_coat_skirt_hangs_from_his_hips_not_his_arms`). Skin tone is measured from the painted
  face (`outlaw.json` `skin_tone`). Face projected at 384×256, 40 colours. Face repainted on the
  corrected head (People run 3). New screenshot views `portrait_day`, `coat_hands_up`. 227 pass.
- 2026-09-29 (later): **Shot match round 7: the painting's face.** Sean asked whether faces can look
  as good as the painting's: yes (DESIGN.md §4 reworded) — at 640×360 the painting's face is ~70×80 px.
  (1) **Every shot-match round before this was rendered at 75°**, not 48°: the screenshot setup hid
  the revolver but left it `selected`, and `WeaponViewmodel._animate_camera` pulls fov to 75 and
  levels the pitch. `ShotMatch.frame_camera()` takes every gun out of hand (portrait views too); test
  `test_the_shot_keeps_its_lens_and_aim`. (2) Camera fitted to the painting (probe the staged
  scene, project, grid-search a seated eye): his eyes land at its eye spot at its size (eye to chin
  106 of 941 px); lamp, bottle, cup and ashtray are where its pixels fall on the table top. The
  painting's lamp is ~2× ours for a seated eye; ours kept. (3) `faces.project()`: depth test against
  the head seen from the front, fade only by angle round the head, hidden texels filled from seen
  ones: the portrait covers 2.7× more (holes round eyes, nose and moustache let the code-painted
  face through). (4) `make_people`: MakeHuman's neck leans forward more than our anatomy's, so the
  generated head sat ~5 cm in front of its hitboxes (and the hat, which let the forehead through):
  the head slides back till its eyes are the anatomy's eyes (neck sheared, `head_back_m` 0.048 in
  `outlaw.json`). The pipeline ran here (bpy 5.0.1 in a venv, 15 s; glb byte-identical to Actions
  before the change). (5) Hat worn lower (brim ~3 cm over the brows), crown roomier for the MakeHuman
  skull. (6) `HumanBody.pose_offsets` (segment → extra degrees on any pose): the seated man turns
  his head to look at you and tips it. (7) Wet eyes: `body_skin` gloss within the eyeballs (head
  piece only) → a 1-px lamp glint like the painting's. Renders `docs/screenshots/shot_match/round7*`
  (`round7_face_steps.png` is the painting's face box at each step). 228 pass.
  - Tried and dropped: sconces at the painting's spots and a lamp over the table — our side wall is
    2.5 m behind him (the painting's is right behind his head), so they can't fill his shadow side.
  - Next for the face: light on his shadow side (comes with rebuilding the room to the painting's
    layout: wall close behind him, many sconces), long hair to the collar (geometry), hatband with
    conchos, a firmer expression (MakeHuman expression targets), skin contrast. Then the room.
- 2026-09-29 (later): **Round 8: the pixelated finish.** Sean: "his face is still too smooth". Two
  causes: the face texture had more texels than screen pixels (384×256), and light fell off in
  smooth ramps. (1) `faces.FACE_W/FACE_H` 96×64 (PeopleArt's painted face size): each texel is 2–3
  screen px at the painting's distance; projected at `SUPERSAMPLE` 4× and alpha-averaged down,
  `FACE_COLOURS` 20, `_despeckle()` clears lone texels. (2) `body_skin` has its own `light()`:
  Lambert stepped in gamma space (`light_steps` 4, 0 = smooth), shadows kept, a hard glint only
  where rough < 0.3 (wet eyes). It applies to every person (skin and clothes); the world is still
  smooth-lit. Renders `docs/screenshots/shot_match/round8*` (`round8_pixel_finish.png`: the face
  box before / 96×64 / + steps). 228 pass.
  - Open with Sean: steps on the world too (walls, table, props) so everything matches; the lit
    side of his face is too hot and the shadow side too dark (the lamp is close and low; the
    room's fill comes with the rebuild).
- 2026-09-29 (later): **Character lab.** Sean wants the man as close to the painting as possible
  before he goes in. `tools/character_lab.gd` (above) pastes him into the painting over its own man,
  so the room stops muddying the comparison. Its light (key 0.3 over the lamp side, rim 0.8 behind
  on your left, warm-grey fill 1.0, table lamp 0.8) was tuned against the painting's face and coat
  brightness. Round 1: `docs/screenshots/character_lab/round1_*`. Biggest differences, in order:
  posture (the painting's man leans in on his forearms, cup down on the table; ours sits upright,
  cup at his chest), build (much broader, heavier shoulders), the coat (dark desaturated brown wool
  in mottled blocks; ours bright orange-tan and flat), his front (white collar, big dark tie,
  patterned vest; ours shows a big white shirt V), long hair behind the ear, then the face (skin
  darker and more even in the painting; ours lighter with hotter highlights).
  - Next (proposed to Sean): posture and build, then texture all of him from the painting's man
    (image model repaints him flat-lit from front/side/back; projected like the face), then hair
    and hat, judged in the lab each round.
- 2026-09-30: **Painting him from the painting, first working round.** Sean: "maybe 10% there".
  (1) His outline: new pose `sit_lean` fitted to the painting by coordinate descent on the joint
  angles (elbow, wrist and cup onto its pixels): right forearm along the table's edge with the cup
  in that hand, left arm down by his side; hat reshaped (lower crown wide at the band, brim rolled
  up hard at the sides and dipping at the front: `HAT_BRIM`, Lofter `dip`); coat cut looser and
  padded (`clothes.COAT_BULK` by bone weight). (2) The paint bake (layout above). Two bugs found on
  the way: the bake wrote its textures upside down (Forward+ clip space runs y down: everything
  landed on the wrong texels), and the game's ACES + contrast brightened and saturated the painted
  colours a second time (the skin shader now inverts Godot 4.7.2's ACES exactly). Painted from the
  painting's own pixels (your seat only) he wears its face, collar, tie and coat; where his outline
  sticks out past the painting's man it picks up the lit floor behind him (pale patches on his
  left shoulder). Lab light tuned: `paint_look` self_lit 0.35, gain 2.4, wrap 0.9 (the same
  brightness as fully self-lit, median). `test_shot_match` checks the cup's in his right hand.
  228 tests pass. Renders `docs/screenshots/character_lab/round2_*`, `round3_*`.
  - Later the same day, **round 3: the image model paints him round.** People run 4 painted all
    six guides (Gemini 2.5 Flash Image: recognisably the painting's man every time, but redrawn
    a little bigger or smaller and off to one side, lighter and cooler). `align.py` fits them back
    (outline overlap 0.56–0.84 → 0.86–0.89) and matches colours; the shot view takes the painting's
    own pixels inside its man's outline (the pale shoulder of round 2 was the lamp, not the floor)
    and the model's view elsewhere; finish.py lets the best view win (weights⁴) at 256 texels/m (no
    downsampling: the painting's own blocks survive). Lighting for painted parts: each light eased
    off towards 1.3× painted (the table lamp at his elbow burnt the colours out), gain 4.0 to the
    median. He now reads as one painted man from every side (`round3_around.png`). 228 pass.
  - Known: our head is turned and shaped differently from the painting's, so its face lands a
    little smeared; his outline still narrower than the painting's man on your left; the brim's
    texture strip is thin (speckles); the Compatibility (web) renderer grades differently, so he's
    hotter there; the model's views are smooth, not blocky (the palette cut is all that blocks
    them); every man with the outlaw body wears this paint.
  - Next: Sean's verdict on round 3; then the head's turn and tilt to the painting's, hair, the
    build, and faces/paint for the other townsfolk.
- 2026-09-30 (evening): **Round 4: squares, and FLUX.2 [max].** Sean: "how do we get this pixel style;
  it's been hard". Diagnosis: the painting's squares are on the surfaces (fixed size in metres, so
  near things have big squares and far ones small), each square one deliberate colour, light
  stepping square by square; we'd been copying one painting's pixels onto a body that doesn't
  match it, which smears. No engine change needed (Godot 4.7.2 has `LIGHT_VERTEX`). Reviewed
  Gemini's pipeline advice with Sean: right about FLUX.2 [max] references and pixelating clean
  images ourselves with a strict palette; wrong for us about 2D sprites/Phaser, img2img at 0.15–0.3
  (returns the painting), Canny from the painting (locks every asset to that one picture) and plain
  nearest downscaling (speckle). Built: (1) the squares in finish.py (dominant colour per square,
  one 40-colour palette), (2) per-square lighting in body_skin, (3) the painter on FLUX.2 [max]
  with a turnaround-sheet mode. People run 5 (FLUX.2 [max], ~$1.50): painted one view at a time
  it drifts (overlap with our outline 0.47–0.90; the back view came back standing), but the
  six-view sheet follows our model almost exactly (0.82–0.94 before fitting; Gemini 0.56–0.84)
  and is the same man all round. With the sheet as master (finish.py `VIEW_WEIGHT` shot_model 6,
  the painting's own pixels 0.5) his face reads clearly for the first time; the coat is FLUX's
  brown check in squares. Renders `docs/screenshots/character_lab/round4_*`
  (`round4_painting_gemini_flux.png`: the painting / Gemini / FLUX side by side). 228 pass.
  - Known: ~64% of the coat is never seen by any view (under his arms, the skirt under his thighs,
    inside) and is filled; his back and left side come out patchy (the check in squares); the
    lab's light from behind is dim for painted parts (no ambient, self_lit only); the walls,
    table and props don't have the square rule yet (world materials are StandardMaterial3D).
  - Next: Sean's verdict; the same rule on the world (a shared pixel-surface shader for members
    and props, squares per material from the painting), then image-model tileable textures per
    material; a second sheet pass that paints only the unseen parts of the coat; more men.
- 2026-09-30 (night): **Round 5: what "super clean" is.** Sean: the FLUX version "loses that style";
  it's the super clean pixel art he wants. Up close the painting's pixels are squares on the
  surfaces, tilted and stretched with the coat's folds and the face, each crisp and several screen
  pixels big (a high-resolution render of low-resolution textures), with light varying across them.
  At our 640×360 each square gets 2–4 screen pixels and smears; rendered at the painting's own
  1672×941 the same textures give crisp tilted squares like its own (`character_lab.gd --size=WxH`;
  `docs/screenshots/character_lab/round5_*`). finish.py now smooths fine noise first (median,
  `SMOOTH`) and gives each shape its own palette (`SHAPE_COLOURS`: coat 12, face 24): a 5-colour
  coat was clean but flat. Still off: what's drawn in the squares (his collar, tie and eyes are
  muddier than the painting's), and the world's code-drawn textures are plain and coarse beside the
  painting's table and walls. 228 pass.
  - Open with Sean: raise the internal resolution (F2 already has 960×540 and 1280×720) so the
    textures' squares are the pixels, as the painting's are.
- 2026-09-30 (late): **Round 6: the painting's pixel style on the whole frame.** Sean: it's not the
  painting he wants reproduced, it's that exact art style. Agreed the style as rules (DESIGN.md §4):
  squares on the surfaces at a set size, several screen pixels each, a mosaic of close shades, clean
  drawing, warm soft lamplight. Done: **default internal resolution 1280×720** (`RESOLUTION_PRESETS`
  first; F2 steps down) and **64 texels/m** (`PixelArt.DENSITY_PRESETS` first; F7 40/24/16); an old
  settings file moves from the old defaults once (`Settings.LOOK_VERSION` 2). `PixelArt.mosaic` 0.6:
  wood, painted boards and dirt get per-square shade clusters (`_mosaic()`), wood six shades with more
  contrast. The man: `finish.py` `SHAPE_TONE` draws the shirt cream and the tie black (painted light
  kept, colour set), `FACE_SHARPEN` bolds the face; painted parts are matt (`SPECULAR` 0: the night
  sky's sheen); ShotMatch's tin is dull (fully metallic it went black). 228 pass. Renders
  `docs/screenshots/character_lab/round6_*` (the painting / this morning / now).
  - Known: the room is still one plank wall behind him (the painting's depth, bar, balcony, lamps
    and people are the room rebuild); props are plain shapes (cups, lamp, bottle); the shirt V is
    bigger than the painting's (vest cut); frame rate at 1280×720 on Sean's PC unknown.
  - Next: Sean's verdict and frame rate; then props as proper models in the style, the room.
- 2026-09-30 (night): **Round 8: the man first (Sean: "not worried about props until our character looks
  perfect").** (1) **Long hair to the collar:** `BodyMesh.HAIR` (+ `HAIR_GAP`, open round the face),
  sized ~1.5 cm clear of the generated head (measured per height), worn when `look.hair_long` (the
  painting's man). (2) **Necktie:** `clothes._string_tie` is now the painting's wide dark tie
  (`TIE`), and it's at his throat: it used to take the most forward point at collar height, which is
  on the chest muscle, so the tie (string tie too) sat ~10 cm low and off to one side. (3) **Close
  head sheet:** six close views of his head (`lab_stage.HEAD_VIEWS`, one from your seat) painted in
  one picture by FLUX.2 [max] with his painted front as the identity (`paint_views.py --head-sheet`,
  People run 6, ~$0.30): crisp eyes, brows, moustache, hair, studded band. FLUX kept the front, back
  and your-seat views in place (0.93–0.94 overlap) but shuffled the three side views (a profile in
  the ¾ slot, a front face in the left-side slot); finish.py now **leaves out any painting that
  doesn't follow his outline** (`MIN_OVERLAP` 0.8, `MIN_OVERLAP_HEAD` 0.88) and lets the head views
  win on head/hair/hat/tie (`HEAD_VIEW_WEIGHT`, your seat ×1.6). Guides/masks/depth draw both sides
  of every face (the hair shell faces inward and was invisible to them). The lab renders 1280×720.
  228 pass. Renders `docs/screenshots/character_lab/round8_*` (the painting / round 7 / round 8).
  - Known: his face is softer and paler than the painting's (no dark outlines round jaw and eyes,
    no eye whites or glints yet; the lamp flattens it); the shirt V is too big and blotchy (the vest's
    V is cut wider than the painting's and the vest isn't patterned); FLUX gives him a goatee in
    some views (the painting's man has none); his sides come from the body sheet only.
  - Next: the face's drawing (outlines, eyes), the vest V and pattern, the head's tilt (the painting's
    man looks up at you from under the brim), repaint the head sheet's side views.
- 2026-09-30 (night): **Round 9: his face where his head is.** Sean: "getting kinda closer but you
  can see it's not the same". Found why the face was mush: the FLUX head sheet's face (crisp in the
  painting: eye whites, irises, a glint) was drawn ~2 cm higher and narrower than our head's, so
  painted eyes sat on the brow ridge and the sockets' shadow on his cheeks; then the square-making
  took each square's commoner colour (a thin eyelid line lost to the skin round it), the colour match
  turned the eye whites the colour of his skin, and the face lit up one cheek. Fixes: (1)
  `align.py` `face_warp` bends each painting's face (and the painting's own, for the shot) so its
  eyes, brows, nose, mouth and jaw land on the clay guide's (FLUX's head_shot moved 71 px, 5 px
  off after), pinned along his outline; `keep_eye_whites` keeps the painted whites. (2)
  `finish.py`: face squares by `dark_kept` (the average, or the dark part when ≥30% of a square is
  darker: brows, lids, moustache stay bold), a median over ~8 mm first and 16 colours (a calmer
  mosaic), `FACE_EVEN` takes 60% of the painted light out of his face (the painting lights it
  evenly), and his eyes are drawn finer than the squares: the head texture has 3×3 texels a square
  (`DETAIL`), one colour a square except within 2 cm of an eye (`paint_bake.gd` writes where they
  are), and `body_skin` lights 3×3 as one square (`square_texels`). Head raw bake 512×344. (3)
  `ShotMatch` head fitted to the painting's eyes: (6, −8.5, 16)°. Tried and left: lighting knobs
  (self_lit/limit/steps barely change it; `paint_look` has `light_steps` now), outline shader (off,
  lab `--outlines`). 228 pass. Renders `docs/screenshots/character_lab/round9_*`.
  - Known: the shirt V is still big and ragged and the tie reads as a bow (vest cut; the painting
    shows a small collar, a hanging tie and a patterned vest); no studded hat band (the band's strip
    is too thin for its squares); his hand and cup are smaller than the painting's; FLUX's
    head_front has a goatee (it still blends in on his chin); his hair is patchy from the side.
  - Next: the vest's V and pattern, the collar and tie, the hat band; then repaint the head sheet
    (no goatee, eyes open to the viewer).
- 2026-10-01: **Round 10: his front, and a cleaner head sheet.** Sean: "Okay" to round 9's plan.
  (1) `clothes.py`: the vest's V is the painting's (12 cm deep, 9 cm across, `VEST_V`) with its
  edge laid on the line (`_clean_opening`: faces kept by their centres left a sawtooth of shirt
  squares); the shirt's top edge is levelled before its collar (`_level_top`: the sawtooth made the
  cream spikes round his neck); turned-down collar points either side of the knot
  (`COLLAR_POINT`); the tie hangs straight down together and lies on his chest (`_front_surface`,
  `TIE_OFF`: it used to run inside his chest and splay like a bow), tucking under the vest.
  (2) **The bake never saw inward-facing shells**: it takes a texel only where its normal faces the
  view, and the lofted hat band and hair shell face inward, so both were filled from their
  neighbours (the dark band, the patchy hair). Shapes in `HumanBody.DOUBLE_SIDED` (now a class
  constant) are taken from either side. The band is 3 cm deep (was 2.2) and stands 5 mm off the
  crown. (3) People run 7 (FLUX.2 [max] head sheet, prompt: no beard or goatee, eyes open and on
  you): the front and right profile came back right (no goatee, eyes open), but the
  three-quarter cell was a front face, the back cell a front face, and your seat's cell lost the
  moustache. `align.py` now reports `face_fit` (how far the face had to be bent, × its size) and
  `face_mismatch` (a face where the guide shows the back of his head, or on a close head view no
  face where the guide has one); `finish.py` leaves those out (`MAX_FACE_FIT` 0.35, the warp's own
  limit: a painting made before his head was turned needs 0.33). The head_shot and head_back tiles
  are run 6's (restored from git): run 7's had no moustache / was a front face. Tried and reverted:
  a deeper brim dip at the front (to show the band from your seat): it covered his eye.
  228 pass. Renders `docs/screenshots/character_lab/round10_*`.
  - Known: the band still barely shows from your seat (our brim is flatter and the hat sits lower
    than the painting's: the hat's shape needs redoing to the painting's, crown dented, brim rolled
    hard on his right); his hand and cup are much smaller than the painting's and he's smaller and
    slimmer in frame; the coat lacks the painting's lapels and fold shading; FLUX's head sheet gets
    one or two cells wrong every run (the checks now catch them).
  - Next: his build and the hand round the cup (the painting's biggest shapes), the coat's lapels,
    then the hat's shape.
- 2026-10-01 (later): **Round 11: his build, place and grip.** Sean: "Okay" to round 10's next steps.
  Measured his outline from your seat against the painting's man (traced, `align.SHOT_OUTLINE`):
  overlap 0.62, ours 78% of its area, shifted right, his right shoulder and arm short of the
  painting's. `tools/fit_shot.gd` (new) fits his seat, turn and pose offsets to the outline, his eyes
  and the cup (coordinate descent; poses snapped with `_apply_pose(0, true)`, else they ease in over
  ~40 frames and the fit scores half-settled poses). Turning him to his left swings his head off the
  painting's (his eyes cost more than the outline gains), so he stays nearly square (`TURN` 6.75°)
  and sits 10 cm nearer you (`SEAT`); the coat is cut fuller (`COAT_BULK` upper arm 4.5 cm, chest 3,
  forearm 2.4, belly 1.5; 7/5 cm looked inflated). The mug sat on his thumb side, so his curled
  fingers closed on nothing and it floated over them: it's in his palm (`CUP_IN_HAND`), the arm and
  wrist fitted so the back of his hand is towards you and his fingers cross it. Overlap 0.70, eyes
  within 3 px, cup on the painting's. People run 8 (FLUX.2 [max] body sheet, ~$0.30) repainted him
  for the new build: all six views in place (0.85–0.98 overlap), no goatee, the coat consistent
  (the old sheet left pale patches on the bulkier coat). 228 pass. Renders
  `docs/screenshots/character_lab/round11_*`.
  - Known: his hand is smaller and thinner than the painting's (hand and finger sizes come from the
    shared anatomy; a per-person hand size would be a body-build feature); the mug draws 98 px tall
    from your seat, the painting's 128 (a bigger mug floated off his grip; bringing the hand nearer
    you fights the back-of-hand rule); FLUX painted the back of him as a vest (no coat); the hat is
    still the old shape (band hidden by the brim from your seat).
  - Next: the hat's shape (crown dented, brim rolled hard on his right, sitting higher), the coat's
    lapels; then his hands.
- 2026-10-01: **Art pipeline, step 1: texel-space lighting** (branch `art/pipeline`; Sean's order:
  1 texel lighting, 2 texture factory, 3 reference judge, 4 street dressing/lighting at golden hour
  matched to `docs/concept/street-golden-hour.png`, added). Every grid material (members,
  blockouts, shot-match props, holes) is now one ShaderMaterial (`PixelArt.material()`,
  `src/render/texel_grid.gdshaderinc`) instead of StandardMaterial3Ds; the ground shader shares the
  include. Godot evaluates lights, shadows and both fogs at `LIGHT_VERTEX` in Forward+ and
  Compatibility (checked in the 4.7.2 sources), so one moved point snaps all three. Off by default
  (the approved look), **P** toggles, saved. Thin faces (plank edges, narrower than a texel) clamp
  the point onto the face via UV2 = face size, else they glint out of their neighbour's shadow.
  New views `texel_rail_shadow`, `texel_porch`, `texel_store_golden`; `screenshots.gd
  --texel-light`. Renders in `docs/screenshots/texel_lighting/` (lavapipe; Compatibility checked
  too). 230 tests pass.
  - At 40 texels/m a texel is ~1 render pixel beyond ~8 m, so the effect shows up close and on
    shadow edges; at 16/m it's strong. People, guns, untextured props are not texel-lit yet.
  - Next: Sean's verdict on the side-by-side, then step 2 (texture factory).
- 2026-10-01: **The painting's pixels are tiles on the surfaces; the man is on tiles.** Studied the
  painting up close (DESIGN.md §4 "What the painting's pixels are"): tiles of a fixed real size,
  each lit as one colour, on a sharp picture, carrying realistic detail. Built: `tiles.gdshaderinc`
  (light per texel via `LIGHT_VERTEX`, ragged option; globals `tile_light`/`tile_ragged`;
  `Settings.tile_look`, saved, **P** cycles off/square/ragged, default square) on people and the
  shot match's props (`Tiles.material`); F2's last stop is **native** (`Settings.NATIVE`); the
  face portrait brought to 96×64 tiles with its holes filled (`PeopleArt.portrait_tiles`);
  `clothes.py` bake rewritten (occlusion near 4 cm / far 30 cm with the layers worn over it left out,
  pointiness wear, dust by height and by facing up, mottle, warm/cool lean, 16 colours, UV islands
  turned upright so tile rows run across the body); the hat fitted to the generated head
  (`PeopleBodies.hat_fit` → `BodyMesh.hat_rows`: MakeHuman's head sits ~6 cm further forward and is
  bigger than the lofted one, so his skull poked out of the crown), band 4.5 cm above the eyes, a
  lower tapered crown, 7-shade felt; the shot match's table lamp is the key on his face (2.6).
  Works on the Compatibility (web) renderer too. Renders `docs/screenshots/shot_match/round7_*`.
  The people pipeline runs in the workspace (commands above). 232 tests pass.
  - OpenRouter: Sean added it to the environment, but this session still got a proxy 403 for
    openrouter.ai (environment changes reach new sessions). Next session: `curl -s
    https://openrouter.ai/api/v1/key` to check; with an API credential the network adds the key
    (`OPENROUTER_API_KEY` stays unset): `python3 tools/faces/paint_face.py --proxy-key --repaint`.
  - Next, the man first: his face lit and turned like the painting's (warm key from the lamp,
    three-quarter to you), repaint it with the image model and fix the projection's holes in
    `faces.py`; hair under the hat, a moustache with volume, real fingers, the shirt front and tie.
    Then the room on tiles (members, walls, props through `Tiles`), dressing, the moonlit doorway.
    Ask Sean: default resolution (640×360 or native) and tile look (square or ragged).
- 2026-10-01: **Style test on a still.** Sean asked whether a realistic image + our filter gets the
  concept's look before buying Character Creator (and a new PC). `tools/style/photo_reference.py`
  (People workflow, `style_test` input) has the image model redo the concept as a smoother,
  realistic frame (`docs/style_test/photo_*.png`); `tools/style/paint_filter.py` grades toward the
  painting, averages into blocks and cuts to the painting's palette (`compare.png`). Result: close
  in mood and detail. What's left: the painting's blocks scale with distance (big on the near man,
  fine on the far bar), so in game they should be texels on surfaces, not a flat screen filter.
  - Next: Sean's PC, then one Character Creator man at the card table through the real pipeline.
  - Proposed to Sean (no new PC needed): image-to-3D by API on GitHub Actions (Tripo, ~$1–1.50 a
    rigged textured man, 2,000 free API credits; Meshy similar): image model paints a full-length
    A-pose man → Tripo model + rig → our Blender fit to skeleton/hitboxes (our own hands) → card
    table under the filter. Waiting on Sean: repo secret `TRIPO_API_KEY`, and optional reference
    stills for tuning the filter (keep them out of the repo: public, not ours).
- 2026-10-01 (later): **Clean-up: the four art branches merged into one** (`cleanup/merge-art`, base
  `claude/nifty-bohr-2uaq2z`). One per-texel lighting system on one key: `src/render/
  tiles.gdshaderinc` (mosaic-tiles') is the core; art/pipeline's `PixelArt.material()` /
  `texel_grid` carries it for the whole world (members, blockouts, holes, ground) and for props
  (the shot match's); `body_skin` uses it for every person (nifty's private `light_whole_square`
  folded in, with its seam guards and the face's 3×3 squares). **P** cycles square (default) /
  ragged / off. Dropped: `texel_lighting.gdshaderinc` and the `texel_lighting` setting
  (art/pipeline's P), `Tiles.material` / `tiled_lit*` (mosaic's prop stand-in). Defaults stay
  nifty's (1280×720, 64 texels/m) with mosaic's native as F2's last stop. Kept nifty's people assets
  (every one of the outlaw's 15 shapes is painted, so mosaic's regenerated garment PNGs never
  showed on him) and nifty's hat; mosaic's `hat_fit` now leaves a crown that already clears the
  head alone (nifty's does) and only moves/widens one that doesn't. Shot-match lamp stays 1.5
  (`paint_look` was tuned under it). The style test is kept as a tool (`tools/style/`, People
  workflow `style_test`), not in the game. Renders `docs/screenshots/merge_art/`.
  - **Next `make_people` run:** `clothes.py` now has mosaic's upright UV islands and richer bake,
    so garment UVs change: re-run the paint bake after it (`tools/paint_bake.gd guides` + `bake`,
    `tools/paint/finish.py`), or the painted textures land on the wrong texels.
  - Known: guns, lamps, `PropLibrary` props and effects are still StandardMaterial3D (smooth light).
  - Merged to `main` as build 147 (green: tests, exports, Pages). The four old branches are fully
    in `main`; this session couldn't delete them (git policy 403), so Sean deletes them on GitHub.
    From here on, two sessions: see **How we work** at the top.
- 2026-10-01 (art session): **The reference judge** (branch `claude/art-salt-creek-9u73vk`; Sean's
  order: 1 judge, 2 texture factory, 3 dressing, 4 characters by image-to-3D). New view
  `shot_match_street` (`StreetMatch`: you stand in the street at 18:05 looking west into the low sun,
  the store's porch on your left, revolver at the hip, 62° lens; the test street runs east-west and
  the sun sets west-south-west, so the store's side is the painting's lit left-hand side) and
  `tools/judge.py` (above). `screenshots.gd --only=` takes a comma list. Round 1
  (`docs/screenshots/judge/2026-10-01_r1/`), biggest differences: saloon (score 0.90): wall tiles
  ~3× taller than the painting's (the wood texture's grain streaks run down the planks; the
  painting's tiles are about square, 5–8 px at 1280), its bottom-right (table top) too bright, the
  walls' mosaic too plain; street (1.45): the sky has no clouds (no mosaic at all), the far right
  too bright and the road grey-violet in shadow where the painting's is lit ochre (L* 18 vs 50).
  OpenRouter is still blocked from this workspace (proxy 403), so image-model work runs on Actions.
  237 tests pass.
  - Next: the texture factory (image-model textures per material on Actions).
- 2026-10-01 (gameplay): **M4 step 4: the gang fights together** (branch
  `claude/gameplay-gang-coordination-0xe2v0`). `Crew` (src/people/crew.gd) is each man's picture of
  his friends; `Events.callout(speaker, kind, about, at)` is what they shout (heard within
  `DeedWatch.SHOUT`, halved through a wall; DeedWatch makes it a shout noise; lines
  `LINES.call_*`). In `OutlawBrain`: "spotted" when he sees the man or the man moves 4 m (friends
  `senses.note` it); "reloading"/"hit"/"flank"/"drag" set friends `covering` (seconds: up from
  cover at once, longer peeks, up to 3 shots, and `_can_shoot_at` fires at the last-known spot up
  to 20 s); flanking: when his flank timer's up with friends in earshot and nobody else going
  round (`Crew.FLANK_LASTS` 8 s), he searches `FLANK_TRAVEL` 16 m with `FLANK_ANGLE` 9 (new
  `Cover.search(..., new_angle)`, 3 before) and calls "flank" when he's found it; rescue
  (`Tactic.RESCUING`): a friend he knows is down (prone or limp, alive), not hidden from the man at
  lying height, within 18 m, nobody else on it, him with nerve to spare: run to his collar (one
  waypoint round things), `HumanBody.drag_toward()` (prone: head follows the hands, the rest
  trails; limp: the chest is hauled) walking backwards at 1.1 m/s in pose `drag` to `Cover.find`
  from where the friend lies, until he's hidden at LIE_HEAD and LIE_CHEST or it stalls; 12 s before
  trying the same friend again. A friend down/dead/quit/fled: fear 0.12/0.15/0.1/0.08 (×1.6 for
  the leader, `OutlawBrain.leads`, Brody), the first to see it shouts it, a friend shot down puts
  them in the fight with whoever shot him (`Relations.side_with`), temper ≥ 0.7 → `rage` 8 s (out
  of cover, at you), proud + quit → scorn, half the gang out → fear +0.15 once. "Fall back!" from a
  runner takes anyone over 0.6 of their nerve (0.3 if the leader), the leader's "give_up" anyone
  over 0.3 (`_pending_break`, after 0.3–1.6 s). Friends' `shoot_at`/`hit` deeds and near misses
  never start a fight (`Relations.perceive`, `_provoked`: "Watch where you're shooting!"), and he
  holds fire with a friend in his line (`_friend_in_the_way`, a BODY_PARTS ray). Tests:
  `test_gang` (14, a test world: tests remove the player's `human_body` meta so rounds stop on him
  without wounding) and `test_town_day::test_in_a_fight_they_work_together` (the street). 252 pass.
  - Known: the rescue's routing is one waypoint (inside the saloon, round the bar, it can fail; he
    gives up and fights); a dragged ragdoll is hauled by the chest only (the rest flops after it);
    covering fire doesn't yet pin the player (no player suppression effect); flankers don't
    coordinate sides (the second flank picks its own); an intermittent "2 ObjectDB instances
    leaked" warning at exit after the street fight test (doesn't fail anything; not chased yet).
  - Next: Sean plays it (BUILD_NOTES); then step 5, conversation hooks (talking a man down,
    bargaining), or gang teamwork tuning from his feel.
- 2026-10-01 (art session, later): **The texture factory, prop models, the saloon dressed.**
  Merged as one piece (judge round `2026-10-01_r2`). Factory above: People runs 10–12 painted 15
  materials and signs on FLUX.2 [max] (~$1.10; the road failed once on an empty answer, so the
  painter retries). Every saloon prop is a code model on the texel grid (`PropModels`), the shot
  match uses them, and `OilLamp` draws the new 0.38 m lamp with a glass chimney (gameplay's
  `src/world/oil_lamp.gd`, Sean asked for lamps on the grid; flame, light and hitbox moved up with
  it; its brass font now casts the dark ring round a lamp's foot the painting has). The saloon
  (`SaloonDressing`, one line in gameplay's `saloon_building.gd`): stained plank walls, a stair up
  the front wall to a balcony over the bar's end, mirrors behind the back bar (glass members:
  shootable), a piano by the door, the stag over the stair, pictures, more sconces and bottles;
  the stair keeps clear of the gang's walk to the bar (`test_town_day`). The shot match's set now
  faces up the room as the painting does (door left, stair ahead, bar right) with six extras.
  Judge: saloon 0.90 → 0.85 (after correcting the factory's woods darker and less orange, the
  table darker), street 1.45 → 1.33. Biggest left: saloon — the bar side's mosaic is plain (the
  painting's bottles, lamps and balcony are busy), the wall tiles small and the left too yellow;
  street — no clouds, the far side too bright and the road violet in shadow (golden-hour light),
  and no dressing yet. 239 tests pass.
  - Known: everyone wears the painted outlaw's body and paint (characters are step 4); the signs
    are painted but not hung yet (street dressing); the extras exist only in the shot.
  - Next: street dressing (signs, lanterns, barrels, crates, hay, wagon, water tower, horse), then
    golden-hour light and haze, then guns onto the grid.
- 2026-10-01 (gameplay, later): **Steady hands and being shot at** (Sean: "player forearm sway so
  shooting isn't super easy; bullets snap past; a reaction that makes shooting harder for a
  second"). `WeaponViewmodel.sway` (degrees, x right / y up): a slow drift (two unrelated waves per
  axis), breathing, a fine shake (+ `extra_spread` from a hurt arm), a flinch `jerk()`; amplitude
  from `PlayerTuning` "Holding a gun" (hip 1.1°, sights 0.28°, ×2 unsettled for `settle_time` 0.9 s
  after raising/firing/moving, crouched ×0.6, +0.3°/(m/s) moving, shotgun `sway_factor` 0.75). The
  gun model turns by it (not while tucked or loading) and `_shot_line` turns the line of sight by
  it, so the ball goes where the barrel points. `PlayerComposure` (child of Player): `winded` from
  running (×2.2 sway, deeper faster breaths), `flinch` from a near miss, a round smacking within
  `rattle_reach` 1.5 m of your head coming your way, or being hit (view jolt 1.2°, gun jerk 1.6°,
  +2.5° spread fading over 0.9 s), `rattled` 0.2 per round (×2.5 sway, steadying over 8 s once
  1.5 s quiet). **Near misses are now reported at the closest approach** (Ballistics waited for the
  first tick within 2.5 m, ~4 m of flight, so distances read long; outlaws' fear and suppression get
  the true distance) and carry `at` and `speed`: `Events.near_miss(person, shooter, distance, at,
  speed)`. ImpactEffects plays it from where it passed: `crack` (new: an N-wave, ground slap, hiss), the
  snap, for every ball (Sean: a near miss is a snap, a whiz is usually a ricochet; `zip`, reworked
  as a tumbling whiz, waits for ricochets).
  F3 shows "Hands". Tests `test_composure` (8; spread set to 0 so what's left is the sway;
  `steady_hands` turns it off). 262 pass (with the art merge).
  - Known: there's no crosshair, so from the hip you only see the gun drift; no visual effect for
    being rattled beyond the gun (no blur or vignette: that's the art session's if wanted); the
    outlaws don't sway (they have spread from fear/pain already).
- 2026-10-01 (art session, later): **The street dressed, painted signs, a golden-hour sky.**
  Judge round `2026-10-01_r3`: street 1.33 → 0.90, saloon 0.87. Painted boards on the false fronts
  (`SignArt`; two lines in gameplay's `false_front_building.gd`: hang the board, skip the label;
  the plain sign member stays for bullets and fire, undrawn) and on the blockout lots; the street's
  dressing (`StreetDressing`; a node added to gameplay's `scenes/test_street.tscn`), placed off the
  road's middle and the gang's routes (`test_town_day` passes). New models in `PropModels`: crate,
  hay bale, carriage lantern, wagon wheel and covered wagon, water tower, telegraph pole, a saddled
  horse (a prop, not alive: shooting it hits a box). Light: the street shot's hour is 17.6 (the
  painting's sun is ~15° up, not on the horizon: our road was in shadow); the sky shader no longer
  takes the scene's fog (it washed the whole sky to the fog's peach; `fog_sky_affect` had no
  effect) and paints its own haze; in the scene's environment (gameplay's file, lighting lines
  only) the fog's `fog_sun_scatter` 0.25 → 0.05 and the sun's `light_volumetric_fog_energy` 0.35
  (looking into a low sun the haze washed the shadowed fronts out). Biggest left: the street's far
  right is still too bright (the sky and the pale blockout fronts; the painting's are dark
  timber), its tiles finer than the painting's at distance; the saloon's bar side still plain.
  - Next: guns onto the texel grid; then the street's far side (real false fronts in place of the
    blockouts would be the town build-out, gameplay's call), the saloon's bar side (more lamps and
    bottles), and characters by image-to-3D once `TRIPO_API_KEY` is set.
- 2026-10-01 (art session, later): **Guns on the texel grid; image-to-3D scaffolding.**
  `GunParts.grid()` (gameplay's `src/weapons/gun_parts.gd`, `revolver_model.gd`,
  `shotgun_model.gd`: Sean asked for the guns on the grid): metals, wood, bores and primers lit tile
  by tile at the guns' own 320 texels a metre (not F7's). Skin and cloth stay StandardMaterial3Ds
  because people's bodies read texture and scale from them (moving those is a people job).
  `tools/characters/` (above): the full-length painting runs now; Tripo waits for
  `TRIPO_API_KEY`, then a Blender fit (Tripo's rig → our 17 segments, the same warp, envelope and
  per-segment cut as MakeHuman's) and the paint bake again.
  - Next: when the key's there, run People with `characters: stranger`, read `_tripo.json`, fix the
    client to the live API, then the Blender fit. Meanwhile: the street's far side and the
    saloon's bar side (the judge's biggest left).
- 2026-10-01 (gameplay, later): **Ricochets** (Sean: a near miss is a snap, a whiz is usually a
  ricochet; "yes" to ricochets). `Ballistics._ricochet()`: a ball striking a surface shallower
  than its `BallisticsTuning.ricochet_angle` (ground 14°, stone 22°, metal 28°, wood 6°) glances
  off with chance 1 − (angle/limit)²; it leaves at `ricochet_exit_share` 0.5 of the angle (+0.5–2°),
  scattered ±6° about the normal, keeping 0.8→0.5 of its speed (graze→limit), diameter ×1.4 once,
  `tumbling`, no blast; at most 3. `Ballistics.surface_of()`: a `surface` meta, else stone/wood
  members by wood (glass never), else level statics are ground and upright ones wood. A glanced
  wood member gets a blind hole (gouge). `bullet_hit` info carries `ricochet` and `surface`; near
  misses are judged leg by leg when a flight bends, and `Events.near_miss` gained `tumbling`.
  ImpactEffects: `ricochet` sound (new: a spang + falling, warbling whine) where it glanced, sparks
  off stone/metal, `zip` for a tumbling ball going past you (`crack` otherwise). Ricochet RNG
  seeded (1873). Tests `test_ricochet` (6). 268 pass.
  - Known: nothing's tagged `metal` yet (no iron in the town); tin cans are thin rigid bodies and
    are shot through, never glanced off; a man hit by a ricochet takes it as a normal ball,
    flattened (no "ricochet" wording in his wounds).
- 2026-10-01 (gameplay, later): **Real bullet drop** (Sean: "bullet drop, but it needs to be real").
  Drop and drag were always simulated; what wasn't real: the shot was aimed at whatever the sights
  were on at any range (perfect point of aim), the revolver's bullet had a round ball's drag, and
  outlaws never allowed for drop. Now: `Ballistics.flight(distance, speed, mass, diameter, cd)`
  flies the same integrator at the physics tick and returns drop/time/speed (cached);
  `holdover()` is the angle to come down onto a point. `WeaponViewmodel.zeroed()`: the ball leaves
  the muzzle toward the point on your line of sight at the gun's zero, raised by the drop there
  (`_load()`: revolver `zero_distance` 22.9 m, shotgun 36.6 m). Revolver vs line of sight: −0.5 cm
  at 5 m, on at 22.9, −10 at 50, −31 at 75, −65 at 100 (0.44 s, 90% of 240 m/s left). `Bullet.drag`
  per projectile (revolver `drag_coefficient` 0.28, a round ball/pellet the tuning's 0.47).
  `OutlawBrain._held_over()`: aims at you held over for the drop at the range he judges
  (`range_judgement` 0.12, own RNG). Test street: boards at 51 m (`target_board_50`, x 64 z 3) and
  100 m (`target_board_100`, x 114 z −1) from the range spot, clear of the near board's backstop.
  Tests `test_drop` (5; `test_composure` now compares against the zeroed line). 273 pass; body hits
  to stop him still 1.46.
  - Open with Sean: our .45 leaves at 240 m/s; a black-powder .45 Colt from a 7½" barrel is nearer
    265–275 m/s (~+25% energy, flatter). Not changed: it would shift the gunfight's balance.
- 2026-10-01 (art session, later): **Mountains on the skyline** (Sean: "those mountains in the
  distance like the concept art"). `Mountains` (above): spires left and right of the sun down the
  street, a low ridge in the gap under it, mesas and buttes round the rest of the town (they show
  at noon, dusk and night too). Judge round `2026-10-01_r5`: street 0.90 → 0.87 (saloon 0.87,
  unchanged). StreetScenery's old sphere hills (gameplay's file) are left as they are, in front.
  - Known: the spires are seen backlit at golden hour (their shadow sides; the painting's have
    lit orange rims); the formations are simpler than the painting's cathedral rock (fewer towers
    per cluster); the far plane is 800 m, so nothing can go further out.
- 2026-10-01 (design, Sean): **story flow decided** (DESIGN.md §5: three acts on the 30-day clock, you
  find the sheriff, the game can end early) and **signature features** (DESIGN.md §11: the body
  changes how people talk, real forensics, a real trial, rumours, letters/telegraph, leading
  people, voice loudness, teaching, legends). 1–3 are the spine; gameplay should keep them in mind
  when building conversation (M4 step 5) and the sheriff opening.
- 2026-10-02 (gameplay): **Full sim: period loads, Mach-dependent drag, air** (Sean: "let's go full
  sim"). Revolver `muzzle_velocity` 240 → 274 m/s (7½" SAA, 40 gr black powder, 255 gr: ~900 ft/s;
  620 J); shotgun 400 → 365 m/s (12-bore black powder, nine 00 balls, ~1,200 ft/s; 233 J a pellet).
  `BallisticsTuning`: `air_density`/`drag_coefficient` replaced by `elevation_m` (0) and
  `air_temperature_c` (15) → `air_density()` (standard atmosphere) and `speed_of_sound()`;
  `drag_cd(speed, form)` from `sphere_drag` (round balls, Cd 0.47 → ~0.94 at Mach 1.1) or
  `g1_drag` × form factor; `Bullet.drag` → `Bullet.form` (0 a round ball; revolver `form_factor`
  1.27, BC ~0.14). Drag is worked out each tick at the ball's own speed; `flight()`/`holdover()`
  take `form`. Revolver vs sights now: −0.7 cm at 5 m, on at 22.9, −7.4 at 50, −24 at 75, −50 at
  100 (0.39 s, 89% kept); a pellet keeps ~63% of its energy at 25 m. Tests that pinned the old
  speeds now follow the tuning; `test_gunfight::test_he_shoots_back_and_hurts` allows for you
  going down to one hit; `test_drop` +1 (the air). 275 pass; body hits to stop him 1.54 (was 1.46,
  same seeds, different flights), charges dropping him at 20 m 3 of 16 (was 5).
  - Open with Sean: where Salt Creek is (elevation, how hot): mesa country is often 1,200–1,800 m.
