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
  `BodyInterior` (insides built from the anatomy when a part opens; `shaders/body_skin` and
  `body_inside` cut wound openings, `wounds.gdshaderinc`).
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
