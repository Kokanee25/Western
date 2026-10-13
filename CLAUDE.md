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

- **Exactly three working sessions at a time** (since 2026-10-05; Sean: the characters session):
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
    each man before Tripo is paid. The art session judges each new man in the shots and says
    what's off; the characters session fixes him.
  - **Gameplay:** everything else (people's minds and bodies, weapons, structures, fire, blast,
    the town, saves, controls, CI).
  - Shared by all three: `CLAUDE.md`, `DESIGN.md`, `docs/BUILD_NOTES.md`, `project.godot`,
    `src/autoload/settings.gd`, `src/autoload/controls.gd`, `tools/screenshots.gd`. Shared by art
    and characters: `.github/workflows/people.yml` (art's jobs: textures, backdrop; characters':
    the rest). Edit only your own lines and entries in them (in `docs/status/`, add entries at
    the end, in date order).
- **Each works on its own branch** (`claude/art-…`, `claude/characters-…` or `claude/gameplay-…`),
  never on `main`.
- **Pull `main` before starting and again before merging** (`git fetch origin main && git merge
  origin/main`), run all the tests, and **merge small and often**: one finished, tested piece
  of work per merge, not a day's worth.
- **After merging, confirm the build on `main` is green** (Actions → "Test and build" for that
  commit) and give Sean the build number. A red main is fixed before anything else.
- **Never edit the other session's files without saying so**: in the commit message and in your
  status entry (`docs/status/`), naming the file and why. If it's more than a line or two, ask Sean first.
- **A brief per big job:** before anything larger than a day, write `docs/briefs/<name>.md` (goal,
  references, what done looks like, how it's judged). Open briefs are in `docs/briefs/`; the
  current one for both sessions is `docs/briefs/review-tools.md`.
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
   9. Conversation (DESIGN.md §9: written, voiced lines keyed to the moment; the AI reads what you
      type into a deed), with the speaker's body state
      fed in (DESIGN.md §11 "Signature features" 1: the body changes how people talk).
6. **M5 — The town slice:** Salt Creek's first dozen people, the outlaw scenario with multiple endings,
   the doctor, the jail, saving in bed and waking at the doctor's. **The sheriff opening** is the
   first piece of the story spine (DESIGN.md §5 "Story flow", §11 signature features 1–3): you find
   him on the road at dawn, treat him, his words follow his blood loss, the ball the doctor digs out
   is evidence. Then forensics (the doctor and undertaker read wounds) and the trial.
7. **M6+ —** the three acts on the railroad clock with faction plans, the drama manager, rumours,
   letters and the telegraph, leading deputies, the mine, the full cast, legends between games.

## Working lean

Context is the budget: three sessions share one weekly limit, and everything this file loads is
paid on every turn of every session.

- **One task per session.** Start a fresh session (or `/clear`) for each piece of work; hand off
  through the status file and Current state, not through a long-running session.
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
- **src/weapons** — viewmodels, revolver, shotgun, dynamite, the bucket.
- **src/blast** — overpressure, breaking, the player's wounds.
- **src/art/shot_match.gd** — the saloon painting's shot and its fits.
- **src/art/street_match.gd** — the street painting's shot, the judge's scores.
- **The texture factory (tools/textures)** — materials.json, paint, reduce, flames, backdrop.
- **src/props/prop_models.gd** — props modelled in code, prop views.
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

Latest status entries: `docs/status/2026-10-11_onward.md` (the end of the file). Builds: main is
green at **build 863** (art merge 3h, PR #99); merges 3i (#100) and 3j (#101) and the lamp-shadow
pass are on main after it. DESIGN.md's backlog (§11) and the prompt library (`docs/prompts/`) are
frozen until Sean names one.

**Art** (branch `claude/art-…`; briefs `docs/briefs/fire-look.md`, `docs/briefs/set-direction.md`):
- Done: merges 3a–3j (the fire in the painting's bands, its smoke column and embers, the dusk
  afterglow; the seated man's light and his head turned to the bold painting; the street's
  golden hour; the road re-graded to the painting's pale dust). Judge v2: saloon 0.216, street
  0.279. Critic's top three: the room behind the man is dark murk (the doorway a navy wedge);
  the sky lavender-grey with a small white sun; his face hot, pale and wide-eyed.
- Next: the saloon's doorway (the moonlit street through it); the fire view staged (the bucket
  line, the livery's frame coming apart). After: the saloon room, the other fronts, the
  set-direction cards.
- Known: the fire views' golden tolerances pass any new fire look (`store_fire_close` checks
  nothing).
- Waiting on Sean: the style-sheet review (DESIGN.md §4; Prompt 07 is the test when he starts
  it); the first-pass set-direction cards.

**Characters** (branch `claude/characters-protected-features`, not merged):
- Done on main: `stranger2s` (the stylised Rodin stranger) fitted, painted, seated in the shot;
  the character judge (`tools/characters/judge_man.py`). On the branch: experiments E1–E7
  (moustache, collar and hard-edged head squares as defaults; eyes on their own squares tried,
  not adopted), written up in `docs/screenshots/tripo/experiments/README.md`.
- Next: the branch's merge and the style-sheet character test, both on Sean's yes; then the
  critics' biggest (his eyes, the ear's rim, the collar's points, the brim's streaks). Trap:
  after a fit, `godot --headless --import` before rendering, or the old man draws.
- Waiting on Sean: the merge; the eye's size and opening (bigger read as cartoony, 2026-10-07).

**Gameplay** (branch `claude/gameplay-…`):
- Done: the ragdoll lab (`experiments/physics_lab/`, Prompt 01); a falling man keeps his
  momentum and crumples with muscle tone; dynamite breaks the studs by it; lamp shadows drawn
  once, not every frame (shadow atlas one cell size: street render CPU 8.6 → 4.5 ms lavapipe,
  ~2.9 at Sean's, under budget); the nightly soak's faults (a freed mate, rubble on you, the gang
  flinging rubble as it rode in, shapeless rubble through the ground) and it now logs what it
  finds and its memory as it goes.
- Next: Prompt 09 (fix the falls) when Sean says; watch the next nightly soak (the runner was
  shutting it down; its log now says memory and disk each minute); `test_chaos` is flaky on main
  (thread scheduling: exact on one worker thread; see the status entry); brick wants a brief
  first; M4 step 5 (money) stays frozen with the features.
- Waiting on Sean: Prompt 09's go; performance part B's next step; the sun's cascades (two for
  four saves ~0.2 ms, a look call); whether a wary man should stand still for most of an hour
  after a fight; the `proposed` feel ranges.
