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

## Tech decisions

- **Engine: Godot 4** (latest stable 4.x). Chosen because every script, scene and resource is plain
  text Claude can read and edit, it's free and open source, exports to Windows/Mac/Linux (Steam later),
  and runs headless for automated tests.
- **Language: GDScript** by default. Use C# only for a measured performance hotspot, and ask first.
- **Target: PC / big screen**, keyboard + mouse and controller. First person only.
- **Look:** render the 3D scene into a low-resolution SubViewport (start at 640×360) and scale it to the
  window with nearest-neighbour filtering; modern lighting (shadows, fog, volumetric light, glow) happens
  at the low resolution. Keep the internal resolution a setting.
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
5. **M4 — People:** routines, needs, memory records and opinions, witnesses and sound, then AI
   conversation (voice + suggested replies) through the relay.
6. **M5 — The town slice:** Salt Creek's first dozen people, the outlaw scenario with multiple endings,
   the doctor, the jail, saving in bed and waking at the doctor's.
7. **M6+ —** the sheriff opening, the railroad clock, the drama manager, the mine, the full cast.

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
- `src/main/main.gd` + `scenes/main.tscn` — the pixel pipeline: world renders in `GameViewport`
  (SubViewport at `Settings.internal_resolution`), drawn to `Screen` with nearest filtering.
- `src/player/` — controller, visible body, tuning resource (`config/player_tuning.tres`).
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
  `OutlawBrain.agenda` steps: go, wait, drink, harass, call_out, duel, leave.
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
  the camera's fov and pitch back to the game's (75°, level).
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
  (`.github/workflows/people.yml`, manual; commits `assets/people/`) or here with
  `pip install bpy==5.0.1` in a venv (PyPI is reachable from the workspace now).
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
