# CLAUDE.md — working notes for Salt Creek (the Western)

Read **DESIGN.md's index** (the top of the file) first, then only the sections the task touches:
DESIGN.md is the source of truth for what the game is. Concept art is in `docs/concept/`. This
file is how we work; the per-system detail is in `docs/LAYOUT.md` (see "Where things are") and
the history in `docs/status/`.

## Who and how

- Sean directs; Claude builds. Sean works shifts and plays/reviews in short sessions, often from his
  phone, and tests builds on PC. Keep each session's work self-contained: leave the game runnable, and
  before finishing add one short entry to the newest `docs/status/` file and update your own lines
  in your lane's file (`docs/lanes/`, see "Current state" and "Working lean").
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
    `requests/` pushed to a `claude/studio-*` branch (its CLAUDE.md, "Keys and paid calls"). **Read the Studio's `docs/PLAYBOOK.md` before any character work** (the chain into the game, `tools/to_game.sh`, and every fault met). The art session judges each new man in the shots and says what's off; the
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
- **CI builds PRs, not branch pushes** (Sean, #504: Actions minutes): run the tests locally
  before every push. A plain push to your branch builds nothing; opening the PR builds it, and
  so does every push to it after. Need CI before the PR? Put `[build]` in the commit message.
  Merge on the PR's own "Test and build" run (the `pull_request` one) being green. Tour, visual
  checks and soak run once a night, only if main changed.
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
  likely to break. It reports before changing anything. This is the only Fable review: PRs are
  not sent to Fable one by one (Sean, 2026-10-31, too many tokens). A session merges its PR once
  "Test and build" is green, and its issues don't add a Fable review step.
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

- **Claim your issue first** (Sean, 2026-11-13: two sessions started on one issue): before anything else,
  read your issue's labels. If it has **`in progress`**, stop and tell Sean another session has it (its
  "Started" comment says which). Otherwise add the `in progress` label and comment "Started: <your session
  link>, branch <branch>, <time>". Remove the label when you stop (merged, handed over, or waiting on Sean).
- **One task per session.** Start a fresh session (or `/clear`) for each piece of work; hand off
  through the status file and your lane's file, not through a long-running session.
- **Stop at the end of your step** (Sean, 2026-10-22: long sessions burn the usage). A step ends
  when its merge is green, or when it can't go on without Sean (a `waiting on Sean` issue is
  open). Then, and never later: write the status entry and your lane file's lines, and do no
  more work. **If the work goes on in a new session, hand it over** (Sean, 2026-11-02): end your
  last message with **"Step done: <what>."**, one plain sentence for Sean saying what the next
  session will do and why (so he knows what he's starting), and then a **handover prompt** in one fenced block (its first line the model line below)
  that Sean pastes, unedited, into a fresh session. It stands alone (the fresh session has seen
  nothing of this one): the lane and the issue it works (#N, read it and its comments first), the
  branch to start (from `main`), the goal and what done looks like, what this session found and
  where (files, results, the dead ends), the traps, how it's measured, and when to stop. **A new
  step gets a new issue** (Sean, 2026-11-02): the next step's issue is never the one this session
  worked. Open it, titled by what the next session will do, with the plain sentence and the
  handover prompt as its body, and close the finished issue with a line pointing at it. (A step
  that only continues unfinished work on an open issue posts the handover there as a comment,
  headed "Handover for the next session".) Pointing at an issue alone isn't a handover. If
  nothing goes on (or it waits on Sean's answer), say so instead.
  **Keep the issues few** (Sean, 2026-10-31:
  too many to keep track of): never open an issue that only points at another issue; one open
  issue a step (the next step's, holding its handover), plus one for a decision only Sean can
  make (`waiting on Sean`); close each issue the moment it's done or answered. Don't start the
  next step in the same session, even if it looks small.
- **The cheapest model that will do it** (Sean, 2026-11-11): every handover prompt and `next session`
  issue starts with one line, `Model: <Sonnet|Opus|Fable> 5.5, effort <low|medium|high>: <why>`, and the
  lane file to read. Pick by the work, not the lane:
  - **Sonnet, medium:** following a recipe or a written brief (a prop batch, a building through the
    building lab, a lab round of renders and judges, sound content, docs, status, GitHub chores, wiring a
    part that exists).
  - **Opus, medium:** a new system or mechanic, a mission step, physics, AI or performance work, a bug
    whose cause isn't known.
  - **Opus, high:** only after a medium session got stuck on the same thing.
  - **Fable:** whole-story or whole-codebase work, or a fault two sessions couldn't fix; never
    render-heavy loops.
- **Waiting isn't free:** while a render or run takes minutes, wait in one long blocking command (a
  generous timeout, or a loop that sleeps until the file appears), not by checking every minute. Each check
  resends the whole context, and after a long gap the cache has lapsed and it's paid in full.
- **Two judge rounds, then Sean** (Sean, 2026-11-11): at most two blind judge or critic rounds on one
  thing in a session; then merge what passed or open a `waiting on Sean` issue with the pick.
- **Read on demand:** DESIGN.md's index then only the sections the task touches; the
  `docs/LAYOUT.md` section for the system you're in; never a whole status file, the judge's
  `history.md`, `docs/BUILD_NOTES.md` or a brief's history unless asked. Grep for the heading,
  read the range.
- **Status, at the end of a session:** ONE short entry (a few lines: what merged, the build
  number, what's next) at the end of the newest `docs/status/` file (start a new file when the
  newest passes ~80 KB, named by its period), and replace your own lines in your lane's file
  (`docs/lanes/`; don't append; don't touch other lanes' files; keep it under ~10 KB). Detailed
  write-ups go in the PR description, a brief, or the status entry, never into CLAUDE.md or a lane file.
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
- **Bug reports** — F12 `.saltbug` recordings and `tools/replay.gd`; crash and freeze reports (the black box, `CrashGuard`, `tools/crash_report.py`).
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
- **src/creatures (the horse)** — `Horse`, built by `tools/blender/horse.py`: tack, idle, collision, tied reins.
- **src/train (the train)** — the 1D train, the track from a curve, cars on trucks (the train lab).
- **src/missions (the farmhouse)** — the farmhouse out east (its spec, its places), the hills.
- **src/moments** — showcase moments from data (the card cheat), the bridge's `moment`; clips of
  motion (`MotionClip`, `play_clip`) are under src/bodies.
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

## Current state (each lane keeps its own file)

**Read your lane's file at the start** (the session prompt names it) and replace your lines in it at the end,
keeping it under ~10 KB: where things stand, what's open, the traps. No history in these files: that goes in
`docs/status/` and the PR. The roadmap (`docs/ROADMAP.md`) decides what each lane does next.

- `docs/lanes/art.md`: the real look, the material library and judges, buildings in mission order (the jail done, #811; next its stone as rubble, #860, then the general store).
- `docs/lanes/gameplay.md`: the slice's missions (next No Law step 4, #796), the valley, weapons, the soak.
- `docs/lanes/characters.md`: the Studio and recipe, Harlan (#692, #693), faces and motion.
- `docs/lanes/props.md`: the kit and factory (next the doctor's D2, #805).
- `docs/lanes/sound.md`: GameAudio, the fiddler (#799), voiced lines (#807).

Latest status entries: `docs/status/2026-11-11_onward.md` (the end of the file). The full Current state as
it stood until 2026-11-11: `docs/status/current-state-2026-11-11.md` (only to trace history).
DESIGN.md's backlog (§11) and the prompt library (`docs/prompts/`) are frozen until Sean names one.
