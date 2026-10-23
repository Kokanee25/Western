# CLAUDE.md — working notes for Salt Creek (the Western)

Read **DESIGN.md's index** (the top of the file) first, then only the sections the task touches:
DESIGN.md is the source of truth for what the game is. Concept art is in `docs/concept/`. This
file is how we work; the per-system detail is in `docs/LAYOUT.md` (see "Where things are") and
the history in `docs/status/`.

## Who and how

- Sean directs; Claude builds. Sean works shifts and plays/reviews in short sessions, often from his
  phone, and tests builds on PC. Keep each session's work self-contained: leave the game runnable, and
  before finishing add one short entry to the newest `docs/status/` file and update your own lines
  in **Current state** below (see "Working lean").
- Tone of the game: grounded and gritty, with humour. When in doubt, systems over scripts.
- Decisions already made are in DESIGN.md. Don't reopen them without asking; open questions are
  listed in DESIGN.md §13.

## How we work

- **Sessions follow `docs/ROADMAP.md`:** at most two at a time (up to four in Phases 2 and 3, Sean 2026-10-21), each on its lane's current step; the phase says which lanes are active (the three lanes, since 2026-10-05):
  - **Art:** shaders, textures and how things are lit and drawn (people included: how skin and
    cloth take light); the world's look, dressing, props; the judge, the critic and the golden
    images. Its files: `src/render/`, `src/bodies/shaders/`, every `*.gdshader`/`*.gdshaderinc`,
    `src/art/`, `src/props/`, `assets/props/`, `assets/textures/`, `tools/textures/`,
    `tools/blender/voxelise.py`, the art tools in `tools/` (`judge.py`, `critic.py`,
    `golden_check.py`, `side_by_side.py`, `prop_views.gd`, `quantise_compare.py`,
    `voxel_compare.py`, `voxel_export.gd`), `docs/concept/` (but `docs/concept/style/`) and
    `docs/screenshots/`.
  - **Characters:** making people, from Sean's picture to a fitted man in the game: the image
    model and its LoRA, Tripo, head repaints, the Blender fit, layered clothing (hats, coats),
    MakeHuman bodies and their garments, painted faces. Its files: `tools/characters/`,
    `tools/style/`, `docs/concept/style/`, `docs/style_test/`, `tools/blender/` (but
    `voxelise.py`), `tools/faces/`, `tools/paint/`, `tools/paint_bake.gd`,
    `tools/character_lab.gd`, `tools/lab_stage.gd`, `tools/fit_shot.gd`,
    `tools/people_envelope.gd`, `tools/tripo_lab.gd`, `assets/people/`, `src/bodies/body_mesh.gd`,
    `src/bodies/people_bodies.gd`. It asks Sean before any training run and gives the cost of
    each man before Tripo is paid. **New men are made by `tools/characters/RECIPE.md`** (the
    Rodin portrait route Sean approved 2026-10-14; skill `new-portrait-man`); another route only
    with Sean's OK. Since 2026-10-20 men are made in the Character Studio (`Kokanee25/saltcreek-characters`,
    attach it); its paid calls run on GitHub, not with keys in the session: a request file in its
    `requests/` pushed to a `claude/studio-*` branch (its CLAUDE.md, "Keys and paid calls"). The art session judges each new man in the shots and says what's off; the
    characters session fixes him.
  - **Gameplay:** everything else (people's minds and bodies, weapons, structures, fire, blast,
    the town, saves, controls, CI).
  - **The prop lab** (Sean, 2026-10-21; `docs/briefs/prop-lab.md`): makes each prop end to end,
    so it may edit art's `src/props/` and `assets/props/` as well as the prop kit's structure code,
    saying so in each commit. Changes to the members, fire or blast code go to gameplay.
  - Shared by all three: `CLAUDE.md`, `DESIGN.md`, `docs/BUILD_NOTES.md`, `project.godot`,
    `src/autoload/settings.gd`, `src/autoload/controls.gd`, `tools/screenshots.gd`. Shared by art
    and characters: `.github/workflows/people.yml` (art's jobs: textures, backdrop; characters':
    the rest). Edit only your own lines and entries in them (in `docs/status/`, add entries at
    the end, in date order).
- **Each works on its own branch** (`claude/art-…`, `claude/characters-…` or `claude/gameplay-…`),
  never on `main`.
- **Pull `main` before starting and again before merging** (`git fetch origin main && git merge
  origin/main`), run all the tests, and **merge small and often**: one finished, tested piece
  of work per merge, not a day's worth. **Don't pile on:** if main's "Test and build" is still
  running, wait for it to finish before you merge (Sean, 2026-10-21: many labs at once). The
  status logs merge by union (`.gitattributes`), so two sessions' entries both land.
- **After merging, confirm the build on `main` is green** (Actions → "Test and build" for that
  commit) and give Sean the build number. A red main is fixed before anything else.
- **Never edit the other session's files without saying so**: in the commit message and in your
  status entry (`docs/status/`), naming the file and why. If it's more than a line or two, ask Sean first.
- **A brief per big job:** before anything larger than a day, write `docs/briefs/<name>.md` (goal,
  references, what done looks like, how it's judged). Open briefs are in `docs/briefs/`; the
  current one for both sessions is `docs/briefs/review-tools.md`.
- **Labs measure; parts live in the game** (Sean, 2026-10-21): a lab may build anything to test
  with, but what it makes is only done once **promoted** into the game's shared code or assets,
  where every lab, building and scene can use it (a lab's railing becomes a railing part in
  `src/structures/`; an approved wood goes into the texture factory). **`docs/PARTS.md`** lists
  every part: read it before building something new (use or extend what's there, never make a
  second one), and update your rows in the merge that promotes one. The test saloon (the Systems
  Playground) is built only from parts marked "in the game".
- **Sean's checklist is GitHub Issues** (Sean, 2026-10-21): when you need a decision only Sean
  can make, open an issue labelled **`waiting on Sean`** whose first line is **"Answer in:"** and your
  session's link (`https://claude.ai/code/session_…`, as in your commit trailer) and branch, so he
  knows where to reply; then what to look at, with the sheet, video or PR linked, and the exact
  choice instead of only writing it in a status
  entry. When he answers (a comment or closing it), act on it and close it with a line saying what
  you did. His own notes for later are issues labelled **`idea`**. **At the start of every session
  and before each new step, read the open `waiting on Sean` issues and their comments:** Sean
  answers there, often from his phone, and any session in the lane acts on an answer to its
  lane's issue even if another session asked. Before asking him something, check the open issues
  so it isn't asked twice.
- **No copied code:** never copy code from other engines, games or repos into this one. Ideas from
  papers, talks and docs are fine; say where they came from in a comment. Anything used under a
  licence (code, sounds, fonts, models) is credited in `CREDITS.md`, and nothing whose licence
  forbids redistribution goes in this repo while it's public.
- **Frame budget:** every system has a budget in milliseconds (table below, filled in by the
  gameplay session's performance benchmark); the frame must fit 60 fps on one 3.25 GHz core with
  headroom. A merge that pushes a system over its budget isn't done until it's back under.
- **Art merges get a blind critic:** after every art merge, a fresh sub-agent that hasn't seen the
  work or its reasoning gets only the concept paintings and the new renders, and lists the five
  biggest differences a viewer would notice, with crops. Saved as
  `docs/screenshots/judge/<round>/critic.md`; its top three go in the status entry.
- **Golden images:** every fixed screenshot view has an approved render; a change beyond a small
  tolerance fails the check. Approving a new look updates the golden image in the same merge.
- **Playtests before Sean:** once the dev bridge exists, a build with new gameplay is played first
  by a playtest agent that hasn't read the code (`tools/playtest.md`), and its report
  (`docs/playtests/<date>.md`) goes with the build.
- **Refactor and adversarial review:** every few weeks or at each milestone, a Fable session
  restructures what has grown messy and reviews the codebase for what's fragile, slow, untested or
  likely to break. It reports before changing anything.
- **Motion:** people move by mocap; breathing, idles, flinches, aim and recoil are procedural,
  driven by dials (tunable numbers), not keyframes.

### Frame budget (ms at 60 fps on one 3.25 GHz core)

Budgets live in `config/frame_budget.tres` (`FrameBudget`); `tools/perf_bench.gd` prints every
scene against them (its `budget` line). Measured 2026-10-04 on this workspace's 2.1 GHz core and
scaled by 0.65 to Sean's (`clock_scale`): **calm** = the street with everyone in; **fire** = two
sticks and three buildings alight; **wall** = a shotgun charge into the store's front every half
second. Render CPU from a rendered run under lavapipe (counts the CPU side only; Sean's F3 gives
his own).

| System (Prof timers summed) | Budget | Calm | Fire | Wall |
|---|---|---|---|---|
| People (people_body, people_skeleton, senses, brains, player, town_life, blood) | 4.0 | 1.8 | 2.2 | 2.1 |
| Physics (the engine: server paused vs running) | 2.0 | 1.1 | 0.3* | 1.5 |
| Structures (structures, voxels, ballistics) | 1.0 | 0.0 | 0.1 | 0.4 |
| Fire and effects (fire, incl. burning buildings' settle; smoke; dynamite) | 2.0 | 0.1 | **2.4** | 0.6 |
| Render CPU (draw calls) | 4.0 | 2.9 | – | 6.1–6.4 |
| Everything else (day cycle, lamps, engine, untimed) | 1.0 | 0.1 | **1.5** | 0.2 |
| **Total** | **≤ 14** | **6.0** | 6.6 + render | 4.7 + 6.4 |

\* noisy: pausing the server also stops the rubble falling. Over budget now: the fire scene's fire
(the per-member tick at town scale) and its untimed share (rubble landing, FireFX), and the wall
scene's render CPU (lavapipe; carved members and chips draw on their own, smoke). The calm
street's render CPU went over with Main Street's new buildings (2026-10-06: 12.5 at Sean's,
lavapipe 19.2 ms, 15,400 draws) and is back under since 2026-10-13: **~2.9 at Sean's** (lavapipe
4.5 ms, 2,700 draws). The saloon's 14 lamps were taking each other's shadow-atlas slots and so
redrawing every frame (~4 ms); with every atlas quadrant one cell size (`GameViewport`) a lamp's
shadow is drawn only when something in it moves. The sun's shadow is ~0.7 of what's left.

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
  called for conversation, asynchronously — never inside the frame loop. Since 2026-10-06 (DESIGN.md
  §9 "Conversation") it only *reads* what the player types or says into a deed; people answer with
  written, recorded lines (ElevenLabs, voiced by a script), and the game works fully without it.
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

**The plan is `docs/ROADMAP.md`: phases, steps, gates and the ▶ Now marker. Work only on your
lane's current step there.** Done before it (history in `docs/status/`): M0 skeleton, M1 the
revolver, M2 bodies and its follow-ups, M3 structures, fire and dynamite, M4 steps 1–4 (senses,
deeds and the ladder, a day in town, the gang together). M4's steps 5–9 and M5 are in the
roadmap's Phases 3 and 5; rope, the town build-out beyond the block, and M6+ wait until after the
demo. The first slice's definition (DESIGN.md §12) is the roadmap's Gate D.

## Working lean

Context is the budget: three sessions share one weekly limit, and everything this file loads is
paid on every turn of every session.

- **One task per session.** Start a fresh session (or `/clear`) for each piece of work; hand off
  through the status file and Current state, not through a long-running session.
- **Stop at the end of your step** (Sean, 2026-10-22: long sessions burn the usage). A step ends
  when its merge is green, or when it can't go on without Sean (a `waiting on Sean` issue is
  open). Then, and never later: write the status entry and your Current state lines; open an
  issue labelled **`next session`**, titled with the lane and the next step, whose body is the
  ready-to-paste prompt for it (the branch, what's done, what to read, what to do next; written
  for a fresh session that knows nothing of this one); then tell Sean, as your last message,
  **"Step done: <what>. Start a fresh session with issue #N."** and do no more work. Don't
  start the next step in the same session, even if it looks small. A session that picks up a
  `next session` issue closes it at the start, with a line saying so.
- **Read on demand:** DESIGN.md's index then only the sections the task touches; the
  `docs/LAYOUT.md` section for the system you're in; never a whole status file, the judge's
  `history.md`, `docs/BUILD_NOTES.md` or a brief's history unless asked. Grep for the heading,
  read the range.
- **Status, at the end of a session:** ONE short entry (a few lines: what merged, the build
  number, what's next) at the end of the newest `docs/status/` file (start a new file when the
  newest passes ~80 KB, named by its period), and replace your own session's lines in **Current
  state** below (don't append; don't touch the other sessions' lines). Detailed write-ups go in
  the PR description, a brief, or the status entry, never into this file.
- **Layout changes** go in the system's section of `docs/LAYOUT.md`, kept short; this file only
  gets a new index line when a subsystem is new.
- **Images are expensive:** downscale a render before viewing it (~800 px wide), view crops
  rather than full frames, compare a few images a session, not dozens; let the judge and the
  blind critic (sub-agents) look at the many.
- **Long output goes to a file** under `build/` (tests, Blender, renders, judge runs, soaks) with
  only a summary printed (`... > build/x.log 2>&1; tail -3 build/x.log`); read the file only when
  something failed, and then only the failing part.
- **Broad searches go to a sub-agent** so only the conclusions come back; the blind critic and
  the playtest are already sub-agents.
- **Say what you read:** when a task needs more than the usual files, say which sections in the
  PR, so the next session can skip them.

## Commands and layout

Godot **4.7.2** (pinned in `.github/workflows/build.yml`; bump both together).


```sh
godot --headless --import                                      # after adding class_name scripts
godot --headless --fixed-fps 60 -s res://tests/run_tests.gd     # all tests (exit 1 on failure)
godot --headless --fixed-fps 60 -s res://tests/run_tests.gd -- --only=player   # one file or method
xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd -- --out=/tmp/shots
godot --headless --export-release "Linux" build/linux/SaltCreek.x86_64         # needs export templates
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build.yml'))"  # before pushing CI edits
python3 tools/judge.py --note="what changed"                   # judge both shots into a new round
python3 tools/critic.py prepare docs/screenshots/judge/<round>  # the blind critic's prompt (an Agent, fresh)
python3 tools/golden_check.py --render [--only=a,b]            # every fixed view against its golden image
python3 tools/golden_check.py --approve --from=DIR [--noise=A,B] # approve new goldens (same merge as the look)
godot --headless --fixed-fps 60 -s res://tools/scene_probe.gd -- --out=PDIR   # scene data for the visual checks
python3 tools/visual_checks.py --from=DIR [--twin=DIR2] --probe=PDIR # blank, missing, flicker, feet, floating, clothes
```

**The dev bridge** (`src/debug/dev_bridge.gd`, `tools/bridge.py`; the full command list is in
`docs/LAYOUT.md` "The dev bridge"): drive the running game from a session or a script, debug builds
only (`-- --dev-bridge`, 127.0.0.1:8737, one command a line, one JSON line back).
`python3 tools/bridge.py start [--size=960x540] [--headless] [--fps=N]` runs the game under xvfb;
`stop` quits it; `run FILE` does both round a file of commands; `help` lists them. Example:

```sh
python3 tools/bridge.py start --size=960x540
python3 tools/bridge.py "time 17.6" "goto street_east" "look saloon_porch" "screenshot /tmp/a.png" \
    "gang" "wait 20" "fight" "weapon revolver" "look brody" "shoot 2" "wait 3" "events 20" "read people"
python3 tools/bridge.py stop
```

### Where things are (each a `##` section of `docs/LAYOUT.md`; read the one you need)

- **The dev bridge** — every bridge command, facing and places.
- **The playtest** — the fresh sub-agent that plays a build (`tools/playtest.md`).
- **The tour video** — `tools/tour.gd`, `tour.yml`, the `/tour/` page.
- **Bug reports** — F12 `.saltbug` recordings and `tools/replay.gd`.
- **The soak** — `tools/soak.gd`, the nightly hours-long run and what fails it.
- **Feel ranges** — `config/feel_ranges.json`, `tests/feel.gd`, numbers held to Sean's ranges.
- **The smoke test** — `--smoke-test` on every export, the CI jobs around it.
- **The visual checks in CI** — `visual.yml`: goldens, twins, the probe, nightly.
- **src/autoload** — Events, Settings, Controls.
- **src/render (the per-texel look)** — tiles, texel grid, min square, quantise, mosaic, haze,
  sun rays, the look presets, the judge; the look panel (N) has its own section.
- **src/main (the pixel pipeline)** — the SubViewport and its scaling.
- **src/player** — controller, visible body, composure.
- **src/world** — DayCycle, sky, ground, lamps.
- **src/world/town_layout.gd + config/town.json** — Main Street as data, places, views.
- **src/structures** — members, the support graph, breakage, voxels, carving, holes.
- **src/fire** — FireSystem, FireFX (sheets, tongues), smoke, settle, buckets.
- **src/bodies** — Anatomy, HumanBody, ragdoll, wounds, skin shaders, BodyMesh.
- **src/people** — Senses, brains, deeds, opinions, the gang, town life, the bucket line.
- **src/audio** — SynthSounds, GameAudio (sound placed: delay, air, rooms, walls, slaps).
- **src/weapons** — viewmodels, revolver, shotgun, dynamite, the bucket.
- **src/blast** — overpressure, breaking, the player's wounds.
- **src/art/shot_match.gd** — the saloon painting's shot and its fits.
- **src/art/street_match.gd** — the street painting's shot, the judge's scores.
- **The texture factory (tools/textures)** — materials.json, paint, reduce, flames, backdrop.
- **src/props/prop_models.gd** — props modelled in code, prop views.
- **The prop kit (src/props/prop_kit.gd, kit_prop.gd)** — props as data, built of members; the bench.
- **src/art/saloon_dressing.gd** — the saloon's walls, bar, dressing.
- **src/art/sign_art.gd and the backdrop** — lettering, the painted backdrop, FacadeArt.
- **Characters by image-to-3D (tools/characters)** — the People workflow, Tripo/Rodin, head
  repaints, stylise, the fit, the character judge.
- **Training the image model on our style (tools/style)** — the LoRA and its runs.
- **tools/blender (the people pipeline)** — MakeHuman, garments, fit_tripo, voxelise.
- **addons/saltcreek_native (the native plugin)** — Rust, gdext, voxel members.
- **tests** — the runner, how a test is written.
- **CI** — build.yml, releases, Pages, notes from `docs/BUILD_NOTES.md`.

## Current state (2026-10-12 evening; each session replaces its own lines)

**The roadmap (`docs/ROADMAP.md`) decides what each lane does next;** the Next lines below are
what each lane had open when it was adopted (2026-10-14).

Latest status entries: `docs/status/2026-10-11_onward.md` (the end of the file). Builds: main is
green at **build 863** (art merge 3h, PR #99); merges 3i (#100) and 3j (#101) and the lamp-shadow
pass are on main after it. DESIGN.md's backlog (§11) and the prompt library (`docs/prompts/`) are
frozen until Sean names one.

**Art** (branch `claude/art-…`; the roadmap's steps; targets in `docs/concept/targets/`):
- Done before: the woods are C (2026-10-15); 1.1 the targets; 1.4 the road (#130); the painted sky,
  haze, smooth wood, 1.2's street light; the world and the close props painted in the layered
  cowboy's hand (target 8; `docs/briefs/match-the-man.md`); the judge and critic against the painted
  references. Sean, 2026-10-17: a bit of square is fine (DESIGN.md §4; `docs/screenshots/sky/how_square.jpg`
  unpicked). World art otherwise paused until 1.3 (how square, the back bar, the table's top, the
  street's one orange and canyon end); ~$2.36 of that $5 unspent.
- **1.4a, the material lab** (2026-10-21, branch `claude/art-material-lab`, brief
  `docs/briefs/material-lab.md`): `MaterialStand` + `tools/material_lab.gd` (one wood at a time, three
  lights, the Studio's three men in every view; `--repeats` for Main Street) and
  `tools/material_measure.py`; the men's sheet `9_studio_men.png` is now `--style=man`'s reference;
  candidate sets `tools/textures/material_lab.json` -> `assets/textures/mlab_*`. Round 1: no wood
  passes; the critic finds the Studio repaint (512 a metre) photographic. Round 2 (studio5: broad,
  darker, warmer, 384) painted; Sean: "too clean". **Round 3** (branch `claude/art-weathering`):
  the weathering layer (texel_grid `weathered`: a stain sheet of four masks laid in the structure's
  space where a mesh carries CUSTOM0/1; `stain_sheet.py`), the boards graded to one palette in the
  cut (`board_grade`), the seam dashes fixed (`seams`, `edge_aa`: lab sets only); sets studio6 (free
  sheet) and studio6p (painted mud and bleach); the critic: 2 and 1 SAME of 8 (round 2: none), the
  stains read as light, not dirt. **Round 4** (studio7: stains multiply the board down, bleach on sky faces only) and
  **round 5** (studio8: the low siding matched to its wall, mud capped, darks lifted, chroma down;
  the critic 2 SAME / 4 CLOSE / 2 DIFFERENT, timber and the deck SAME). **Round 6** (2026-10-22,
  free; studio9/10): banded light on the woods (`light_bands`), pine's knots soft (`knots`), flat
  tone steps (`poster`): knots gone, otherwise the critic unmoved. **Sean picked 6b** (#217): the
  game's exterior woods since 2026-10-22 (studio10 by `promote_woods.py`; seams a pixel wide, sheen
  0.08, light in 4 steps; floor/framing/dark trim keep 7/3/2 strips; 25.7 MB of texture), with
  round 6b's stain sheet waiting on gameplay's frame (`docs/SESSION_PROMPTS.md`). **Round 7**: the
  flat-colour probe says the paint rolls, not the light; next studio11 (broader flat shapes), then
  the memory test (`build/run_mem.sh BASE`: 384 lossless vs 384/256/192 BC7) for Sean's pick. **The interior woodwork** (Sean's saloon picture, target 10;
  brief `docs/briefs/interior-woodwork.md`, branch `claude/art-interior-woodwork`): `Profiles`, the
  interior stand, the interior stain `studio_int`; the critic: the stain 6 CLOSE as the picture's
  woodwork, the game's woods all DIFFERENT. Sean picked C: the interior woods `int_*` in the game
  (#208). **The bar and back bar as kit parts** (`assets/props/kit/bar.json`, `back_bar.json`, the
  kit's woodwork draw shapes, `int_bar_top` with rings; the critic: top CLOSE, front and back bar
  DIFFERENT, too dark against the walls). The mirrors painted (`mirror.gdshader`, 2026-10-22: the
  critic DIFFERENT -> CLOSE). The fixtures in a lighter oak, `int_oak_light` (Sean, #218); the
  saloon session spawns them. Worn treads on both stairs (#176). The hotel's oak
  stair (`OakStair`): Sean picked the painted oak; `dark_oak` and `stair_runner` in the game's
  textures, `solid` for the ragdoll session. Paint ~$7.18 of his $9 (round 3 $0.60 of the $0.90 he
  approved); OpenRouter's monthly guardrail ($40) was hit once (Sean raised it).
  Wear-down planned in the brief (after Gate A).
- **Fire flipbooks** (2026-10-21, branch `claude/art-fire-flipbooks`, `docs/briefs/fire-look.md` "The
  next approach"): a lick, a tongue and a column baked in Mantaflow (`tools/textures/fire_sim/`; the pip
  bpy needs `manta_relink.py`), drawn by `FireFlipbook` (haze, core, tips) on FireFX's sheets behind
  `Settings.fire_flipbooks`: the default since 2026-10-22 (Sean: "keep flames for now", #216; look
  panel N turns them off; saved as `flipbook_fire`). Then (2026-10-22, Sean's OK to edit FireFX) the
  fire placed through the roof and openings (`WALL_FOOT`, `FLAME_FIRST`). Next: firelight's look
  (step 5), flames less alike, then the painted pass after Gate A. Tools: `flame_views.gd`, `fire_ab.gd`/`.py`, `fire_cost.gd`; view `saloon_fire_inside`.
- Known: a full golden render is ~2.5 h on lavapipe (batches of 24-25, `golden_check.py --render
  --only=`); `pgrep -f`/`pkill -f` match their own command (and `pkill -x godot` stops every render);
  a data texture with an alpha channel needs `process/fix_alpha_border=false`; after a local import,
  the Studio men's `.import` stubs fill in (characters' files: keep them out of commits, but leave
  them filled locally or the men draw white); a material lab view takes ~1 min under lavapipe.
- For characters (Sean, 2026-10-16: the look is painted illustration, DESIGN.md §4): the painterly
  cowboy's clothes painted smooth like his face, as part of 1.3. From the lab: under the saloon's
  lamps the Studio men measure far darker than the wood beside them (their painted light).

**Characters** (branch `claude/characters-…`; briefs `docs/briefs/layered-people.md`,
`painted-light.md`, `skinned-hands.md`):
- On main: the three Rodin portrait men (`tools/characters/RECIPE.md`; bookmark
  `look/portrait-men-2026-10-14`); the painterly bold cowboy drawn painted (#124); **the layered
  cowboy** (roadmap 1.3; recipe `tools/characters/LAYERED.md`, the exact chain in its §3):
  shirt+tie, vest and trousers cut from the coatless twin, painted from his four pictures, the
  coat over them; outfits `bold_cowboy_layered` (coat) and `bold_cowboy_vest_layered`; chest,
  collar and paint fixed (#142), then the fix-up session's good parts (clothes at 2048, sleeve
  flecks, the coat's vent, sides and collar) with its collar lift and armhole stripes taken back
  (2026-10-17, sheet `d17_take2.png`). ~$10.06 of $15 spent. Not merged: his own hat
  (`look/bold-cowboy-own-hat-2026-10-14`).
- **The two tests** (2026-10-19, `claude/characters-two-tests`, PR not merged, $0): the fit's
  stretch fixed for hatless whole men (`"bare": true`); Test 1 `bold_cowboy_whole` (the arms-out
  Rodin man kept whole, the approved head, his own hat) passes the works check
  (`works_check.gd`); Test 2 blocked (asset sites outside the network policy). Report and sheets
  `docs/style_test/two-tests-2026-10-19/`. Waiting on Sean: which route becomes the recipe.
- Next (Sean, 2026-10-18): **proper garments** in place of clothes cut from Rodin's dressed
  twin: a shirt with a real collar and separate sleeves, waistcoat and trousers as their own
  meshes, fitted to his body and painted from his pictures, reusable for every man (the cut
  twin fuses sleeve to side and collar to neck: the white smear and the collar, retuned for every
  new twin). Brief first. The arms-out coatless pictures and their Rodin model
  (`bold_cowboy_armsout_dressed`, run 89, $1.60, ~$11.66 of $15) are on main for painting;
  through the cut-twin recipe that model leaves the shirt and skin out past the waistcoat.
  Judge every change against Sean's pictures and his words (he turned down a flat collar band
  twice). Trap: after a build, `godot --headless --import` first; lab renders via
  `tools/characters/lab_run.sh`.
- **The talking face** (brief `docs/briefs/face-rig.md`, `tools/faces/`): every Studio man has
  MakeHuman's face grafted on (20 expressions as blend shapes), bandanas (`bandana.py`) and skinned
  hands (`hands.py`; not the rancher). `FaceLife` alive (2026-10-22: looks, blinks, starts, grimace,
  lids dead; `config/face_life.tres`). **Talking** (2026-10-22, brief `docs/briefs/talking.md`,
  branch `claude/talking-mouth-shapes-3yhmv2`): `FaceSpeech` says every `Events.spoke` line with
  his mouth shapes (letter rules → mouth classes, a dominance blend, a nod; 95% agreement with
  espeak-ng; ~10 µs a man), takes a recording's loudness or phoneme track when lines are recorded;
  the subtitle stays as long as he talks; the masks carry the mouth (`mask_jaw.py`: a puff, it
  hangs clear of the chin). Films `docs/style_test/talking/`. Next: Sean's look at the films; on
  four men (widow, bold_cowboy_s3, young_drifter, doctor) the jaw goes back more than down
  (`talking_face.py`'s spline extrapolation: carry the units by the warp's derivative, rebuild
  them); Sean's three takes (`docs/FACE_TAKES.md`) to tune it; issue #247.
- For art: the vest and trousers render darker and flatter than their textures (the vest keeps
  0.88 of his picture's edge strength in the texture, 0.59 in the lab's render); faces' chroma in
  the saloon once he's painted; `test_street.tscn`'s `volumetric_adjustment_enabled` typo.

**Gameplay** (branch `claude/gameplay-…`; roadmap 0.1, and 3.2 moved up by Sean 2026-10-16):
- Done: the soak's freeze (Senses' walk over freed people) and a frozen soak reports itself
  (`frozen.md`); flakes fixed (`test_chaos`, `test_drop`); after a fight the gang rides out, a man
  down gives himself up, the shout key arrests (#128, build 1259); the falls' first round (#132,
  build 1320): weights, solver steps, tone about the joint; lab flags 90 -> 10
  (`experiments/physics_lab/results/2026-10-16_weight/`, brief `docs/briefs/fix-the-falls.md`).
- Then the falls' second round (#144, build 1405): shot dead running he goes over his legs; a ball
  that drops him curls him round it (`_hunch`); on the move he stumbles a step first (`_knocked`),
  folding over the wound with no backward jerk (#146, build 1418). A ball that doesn't drop him
  gives no flinch or wince at all (Sean, 2026-10-18).
- **The falls' third round** (2026-10-21, PR #170, Sean: "I like them"; results
  `experiments/physics_lab/results/2026-10-21_round3/`): light links' inertia, resting parts
  collide, no push past physics, his hat off when it meets the ground, hip and spine cones centred
  anatomically, and a hit short of a fall shows as the wound's consequence (`_favour_step`). Lab
  69 falls 90 -> 17 flags; the Studio's men fall as the outlaw (shared capsules); 8 goldens
  re-approved (art's, Sean's OK). The faint's stance (3 deg forward, a stiff knee) tried three ways
  and not kept (blind judges 8/8, 2/4/2, 3/5; `results/2026-10-21_faint/`: the fault is the even
  squat as his tone lets go). **Round 4: stairs, railings, props** (#184, build 1792;
  `results/2026-10-21_round4/`): the saloon stair's ramp on `Layers.WALK` (falling men meet the
  treads); `BodyImpacts` (a man thrown into timber breaks it and carries on through); the lab's
  game saloon (group T). Then **`Railing`** (#198, build 1851): the railing part, the saloon's
  balcony and stair rails built of it (`docs/PARTS.md`). **The chair** (#204,
  `results/2026-10-21_chair/`): a man in the kit chair, legs shot or kicked out (group U); the
  `sit_back` pose (Sean: back legs out, he goes over backwards and ends on his back) and a `kick`
  pose (Sean OK'd both); Sean's scene (`scenes/chair_kick_shot.gd`); eight contacts a part near
  timber (#211, build 1903: the railing throw no longer holds 1 time in 5). The night of
  2026-10-22 (Sean's five): a body into the kit's furniture (#243, merged: KitProp.take_blow
  decides); the brace (#238) and getting up (#250), merged (Sean: "merge"); men sitting in the kit
  chairs (#270: Seating, Brody at a card table), merging; the collapse's tone
  experiments (branch `claude/gameplay-collapse`, `results/2026-10-22_collapse/`: trunk-first
  helps the oak stair, nothing gets him down the saloon's). Next: the `next session` issue.
- **The building spec** (2026-10-22, `claude/gameplay-building-spec`, `experiments/building_lab/`): the
  format, the saloon's spec from the sheet (Sean's calls in its README), built and checked in an
  experiment (#262). Lived in (`docs/briefs/lived-in.md`): the spec's `use` and
  `past` marked on members, drawn in the lab (a `WEAR` hook in texel_grid, inert in the game); for
  art: marks along each member's grain. On main to walk in a build: F5's eighth stop builds it in
  the desert. Next: the README's "What the format needs"
  (bands and a broadphase in Structure, the Stair, wall and floor parts, a ground with a hole), then 4.3.
- **The barkeep's rag and mopping** (2026-10-22, with the prop lab's leave; briefs
  `docs/briefs/barkeep-rag.md`, `mopping.md`; labs `experiments/barkeep_rag/`, `mopping/`): the rag
  (#260, build 2128): `ClothProp` (a Jolt soft body; Jolt doesn't hold pinned points, the prop moves
  them), `WipeBar`, `HumanBody.reach_to`, `FireSystem.small_fire`, `FaceLife.attend_to`; its cloth
  painted (#258; factory `bar_cloth`, reduce.py `whole`). Mopping (#282, build 2165): `FloorMarks`
  (tracked mud, wet patches, stains), `MopProp`, `MopBucket`, `MopFloor` (`CivilianBrain.chores`).
  Waiting on Sean: both films (in the PRs). Next: issue #293.
- The nightly visual check made repeatable (the pain throb on game time, gun smoke seeded); the
  fire-smoke test steps synchronously.
- Experiment (off): walking and running by CMU motion capture (`experiments/mocap_walk/`,
  `HumanBody.mocap_gait`, the lab's `--mocap`).
- Gunplay (3.2, Sean 2026-10-18): the audit and five changes ranked (the kick, the shot's sound,
  hearing the hit, a hit man's behaviour after, seeing through the smoke); the kick merged (#153,
  `GunKick`); the smoke next (`claude/gameplay-smoke`: simulated puffs, `GunSmoke.transmittance()`,
  six proposed ranges), then a hit man's behaviour. Feel ranges marked proposed wait on Sean's play.
- Also open: 0.1 the nightlies green three nights; performance part B (the fire tick native first);
  Sean's calls on a key for the CMU walk and the mocap clean-up.
- Waiting on Sean: the sun's cascades (two for four saves ~0.2 ms, a look call).
- The perception lab (2026-10-22, `experiments/perception_lab/`, branch `claude/gameplay-perception-lab`):
  bench and baseline (117 judged; top five in its `baseline/baseline.md`); fix 1 merged (#263, #240: a
  heard sound doesn't name its maker; 74 -> 88 as expected, false 23 -> 9; `results/`). Next: fix 2,
  lamplight at night (its "next session" issue); smoke waits for the smoke branch's `transmittance()`.
- The labs (2026-10-21, brief `docs/briefs/labs.md`; roadmap 3.0, 3.1b, 3.3a): a lab's bridge
  commands go in its own `experiments/<lab>/bridge.gd` (`BridgeLab`; LAYOUT.md "The dev bridge").
- The gunfight lab (3.0; `experiments/gunfight_lab/README.md`): bench, baseline and three fixes,
  now the gang's variants (`OutlawBrain.Variant`; the game plays A): B aims by the hand (`GunHand`,
  `Sway`), reacts and finds the town's cover; C also shaken first. Playable: Y/X/Z, nine blind runs
  in the saloon (`play.gd`, `PLAYTEST.md`; issue #257 for Sean), each man's decision and why on F3.
  The bot's A/B/C (`results/2026-10-22_abc/`): the saloon is a quick draw in every variant. With the
  perception lab's fix 1 (`results/2026-10-22_perception/`): no leak, but cover dropped on arrival
  doubles. Next: cover against the same guess he chose it by, and cover in the saloon. Traps: wounds
  bleed on the day clock's time scale; `pkill`/`ps|grep` kill loops match their own command line; a
  `.gd` copy under `build/` with a `class_name` shadows the real class.
- The sound lab (`experiments/sound_lab/`, brief `docs/briefs/sound-lab.md`; what the player hears):
  bench and baseline (#246, the ten worst in `baseline/baseline.md`), then five changes measured each
  against it (`results/2026-10-22_*`): `GameAudio` places every sound (late by distance, the air, the
  Room bus, muffled through walls, slaps off the fronts; `config/sound.tres`); black-powder gunshots
  (#256, build 2058); passes by speed and strikes by surface (#261, build 2067); dynamite near and far,
  breaking placed and a voice limit (#269); fire by size and footsteps. `--old-sound` is the before.
  Waiting on Sean: his ears and snap-or-whirr for a .45 ball (#264). Next: people's steps, the
  `GlassProp` shatter placed (prop lab's), an ambience bed, recorded sounds only if synthesis falls short.
- The gun lab (2026-10-22, `experiments/gun_lab/`, #248): bench and baseline (`baseline/baseline.md`:
  19 things wrong, the handling numbers; quick views `views.gd`). Next: the hands (WIP on
  `claude/gameplay-gun-hands`: `HeldHand`, the grip's rake fixed), then the reloads, a man's gun
  (use the gunfight lab's `GunHand`). Waiting on Sean: #249 (paint the gun metals).
- The body lab (3.1b, `experiments/body_lab/`): the body and gore labs (#167, build 1919); an
  ear, the nose or the jaw shot off (#215, build 1980). On `claude/body-lab-baseline-6fb8py`: the
  painted face wounds, readable face blood, the sling's cloth, singed hair, the wound signs every
  fourth tick, and bullet holes as real ones are (Sean: "way too big": the ball's width, no torn
  skin from a single ball). Ten wounded men are 2.9 ms at Sean's (was 1.65). Paint $4.40 left of Sean's $7.
  Sean's calls: issue #220 (dynamite up close, the gut's time). Results:
  `results/2026-10-21_gore_lab/`.
- The breakage lab (3.3a, 2026-10-21, `experiments/breakage_lab/`, PR #200, build 1835): bench and baseline (`baseline/`): props never
  break; a shot lamp doesn't smash; saloon floors fall in whole 5–10 m lengths; side panes shatter
  into 1 m slabs; a blast is 0.2–0.65 s of hitch at Sean's; no crater. Brief
  `docs/briefs/blast-surfaces.md` (Sean: his order; the ground made ready for the shovel). Step 1
  made: `Blast.gather` (the near field queried on its own; `results/2026-10-21_near_field/`): the
  street breaks where the stick is, more far panes go. Step 2 made: boards cut over the stretch the
  blast overcomes (`Blast.torn_stretch`, `Structure.cut_member`; `results/2026-10-21_board_cut/`):
  holes, not missing boards; one stick a crawl hole in a wall, three a doorway (Sean's feel call);
  glass-only buildings not re-settled. **The blast's look** (Sean: "try doing the art", art's
  ground; brief `docs/briefs/blast-look.md`, `BlastCloud`, the lab's `--look` runs): no fireball, a
  dust jet out of the open side, a tan cloud dark at the root, a ground surge, chunks; wood it lights
  catches 1–4 s later; three blast goldens re-approved; a young fire has no smoke column over the
  roof yet (`SmokeColumn`, the blot in the blast views). **The dig-able ground** (blast-surfaces
  step 3; brief `docs/briefs/dig-ground.md`, Sean's decisions in): `Ground` (flat slabs, 5 cm height
  field tiles where dug, `take`/`put`, loose earth slides, saves the heights; #235, #237), the
  crater (`Blast.crater`, 0.8 x cbrt(kg), clods lie down as earth; #245, build 2020), what stands
  and walks round a hole (step 4, #255). Crater papers' hosts blocked (issue #227). Next: step 5,
  a tile's mesh and shape built natively (an edit is ~15–24 ms in GDScript); art's ground look
  (the brief's "What art needs"). Then 3.3.

**Prop lab** (branch `claude/prop-lab-…`; brief `docs/briefs/prop-lab.md`, may edit `src/props/`,
`assets/props/`):
- The inventory of every prop is in `docs/PARTS.md` "Props". The kit (`assets/props/kit/`,
  `PropKit`/`KitProp`/`GlassProp`): in the game the chair, card table, bottle and oil lamp (#232,
  build 2011); on the branch, in_game: the barrel, crate and bar stool; the wall props hung on nails
  (deer head, painting, sconce: `"hangs"`); the fixtures fitted to their place (`PropKit.fit`:
  counter, shelves, table, trough; the buildings' furnishings and `WaterTrough` built of them); the
  upright piano. The ragdoll lab tests men in the kit chair (how he falls is theirs). Next: issue
  #281 (what the props hold: full barrels that leak; the spittoon and tin cup).
