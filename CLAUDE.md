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
    the rest). Edit only your own lines and entries in them; add status entries at the end, in
    date order.
- **Each works on its own branch** (`claude/art-…`, `claude/characters-…` or `claude/gameplay-…`),
  never on `main`.
- **Pull `main` before starting and again before merging** (`git fetch origin main && git merge
  origin/main`), run all the tests, and **merge small and often**: one finished, tested piece
  of work per merge, not a day's worth.
- **After merging, confirm the build on `main` is green** (Actions → "Test and build" for that
  commit) and give Sean the build number. A red main is fixed before anything else.
- **Never edit the other session's files without saying so**: in the commit message and in your
  status entry, naming the file and why. If it's more than a line or two, ask Sean first.
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
| Render CPU (draw calls) | 4.0 | 3.5 | – | 6.1–6.4 |
| Everything else (day cycle, lamps, engine, untimed) | 1.0 | 0.1 | **1.5** | 0.2 |
| **Total** | **≤ 14** | **6.6** | 6.6 + render | 4.7 + 6.4 |

\* noisy: pausing the server also stops the rubble falling. Over budget now: the fire scene's fire
(the per-member tick at town scale) and its untimed share (rubble landing, FireFX), and the wall
scene's render CPU (lavapipe; carved members and chips draw on their own, smoke).

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
python3 tools/judge.py --note="what changed"                   # judge both shots into a new round
python3 tools/critic.py prepare docs/screenshots/judge/<round>  # the blind critic's prompt (an Agent, fresh)
python3 tools/golden_check.py --render [--only=a,b]            # every fixed view against its golden image
python3 tools/golden_check.py --approve --from=DIR [--noise=A,B] # approve new goldens (same merge as the look)
godot --headless --fixed-fps 60 -s res://tools/scene_probe.gd -- --out=PDIR   # scene data for the visual checks
python3 tools/visual_checks.py --from=DIR [--twin=DIR2] --probe=PDIR # blank, missing, flicker, feet, floating, clothes
```

**The dev bridge** (`src/debug/dev_bridge.gd`, `tools/bridge.py`): drive the running game from a
session or a script. Only in a debug build started with `-- --dev-bridge` (never in an export);
listens on 127.0.0.1:8737; one command a line, one JSON line back, in order (a command that takes
game time answers when it's done). `python3 tools/bridge.py start` runs the game under xvfb with
the Vulkan renderer so screenshots work (`--size=960x540`, `--headless` for no drawing, `--fps=N`
for a fixed step; its log in `build/bridge/godot.log`); `stop` quits it; `run FILE` does start, the
file's commands, stop. `help` lists the commands: `screenshot PATH`, `camera X Y Z TX TY TZ [FOV]`
(a free camera; `camera player` back), `goto X Y Z [YAW]|PLACE`, `look X Y Z|PERSON|PLACE`,
`turn DEG [PITCH]`, `walk X Z|PLACE|PERSON [run]` (routes round buildings to a place), `press
ACTION [S]`, `hold`/`release`, `weapon revolver|shotgun|dynamite|none`, `shoot [N]`, `wait S`,
`time H`, `clock SCALE|off`, `set`/`get ADDRESS` (a look value: `settings.mosaic`,
`global.min_square_px`, `env.glow_intensity`, `day.exposure_night`, `hour`; `LookPreset`), `preset
FILE`, `spawn outlaw|townsman X Y Z`, `gang`, `fight [NAME]`, `dynamite X Y Z [FUSE]`, `ignite [X Y
Z]`, `read frame|player|people|look|places|counts|all`, `events [N]`, `quit`. Facing is degrees
from north (−Z, the livery's side of the street; the saloon's is +Z), east +X. Example:

```sh
python3 tools/bridge.py start --size=960x540
python3 tools/bridge.py "time 17.6" "goto street_east" "look saloon_porch" "screenshot /tmp/a.png" \
    "gang" "wait 20" "fight" "weapon revolver" "look brody" "shoot 2" "wait 3" "events 20" "read people"
python3 tools/bridge.py stop
```

**The playtest** (`tools/playtest.md`, its instructions; `tools/playtest.py start|shot NAME|stop`):
a fresh sub-agent that hasn't read the code plays the game through the bridge (it's told not to
open the code or the design) and writes `docs/playtests/<date>.md` with its screenshots in
`docs/playtests/<date>/`: what broke, what was flat or confusing, what was fun, the top three.
Start it with the Agent tool: "read tools/playtest.md and follow it; don't read the code".

**The tour video** (`tools/tour.gd`, `.github/workflows/tour.yml`, `tools/tour_page.py`): a fixed
30-second camera path (the street at golden hour from the east end, past the store's side of the
street, into the saloon, the card table, the bar while night falls, out of the door at night),
`PATH` in the script. `tour.yml` runs after every green build on main (and by hand): Movie Maker
under xvfb and lavapipe (`--render=854x480 --light`: 3D at 854x480 scaled to 1280x720, no
volumetric haze or SSAO; ~15 minutes of rendering on a 4-core runner), ffmpeg (from frame 3, CRF
30, ~10 MB), the video kept on the `tour` release as `build-<N>.mp4`, and Pages redeployed with
`/tour/` (the phone page: the latest and the seven before it). The build's own Pages deploy
brings the kept videos along, so `/tour/` is never empty. Preview a moment of it here:
`... -s res://tools/tour.gd -- --render=854x480 --light --start=20 --frames=3`.

**Bug reports** (`src/debug/bug_recorder.gd`, `BugRecorder`, in every build; **F12**, controller
Back + Y; debug ignite is L only now): the recorder notes every action's changes and the mouse's
turns by physics tick, everyone's place each second and a snapshot every 30 s; F12 writes
`user://bug_reports/<date-time>.saltbug` (a zip: `report.json` with the build, clock, you, everyone,
settings and the last things that happened; `recording.json`; `godot.log`; `screenshot.png`).
`godot --headless --fixed-fps 60 -s res://tools/replay.gd -- FILE.saltbug [--out=DIR]` plays it back
(from the start for a session under 20 minutes, else from the snapshot 30 s before) and says where
anyone went more than 0.25 m from the recording; exit 1 if anyone did. Drawn (xvfb), `--out` saves
its last frame beside the report's screenshot.

**The soak** (`tools/soak.gd`, `.github/workflows/nightly.yml`, every night at 09:17 UTC and by
hand): `godot --headless --fixed-fps 60 -s res://tools/soak.gd -- --minutes=240 --out=build/soak`
runs the street for hours of game time flat out (~3.4x real time here) with the clock at 30x: the
gang rides in whenever it's gone, one of them picks a fight every 5 minutes, a fire and a stick
twice every 100 minutes. Fails on any error, memory or nodes still climbing, orphan nodes,
anyone stuck a minute on his way somewhere, anything under the ground or off the map, or the frame
time creeping (the last 5-minute window's median over 3x the first's). `soak.md` is the run's
summary and an artifact.

**Feel ranges** (`config/feel_ranges.json`, `tests/feel.gd`): the numbers that make the game feel
right, each measured by a test and held to a range agreed with Sean. `Feel.within(test, key,
value)` fails the test when the number's out of its range, saying the range only moves with
Sean's OK (change min/max and add a line to `history` with the date and his words; a range marked
`proposed` was set from the game as it measured and still waits for his OK). Measured: body hits to
stop a man (`test_gunfight`), the shotgun at 20 m (`test_shotgun`), the store's roof falling in
(`test_fire`), the outlaw's hit rate at 5/15/30 m, the duel's stand-off and the gang's back-down
share (`test_feel`). CI prints every number against its range in the test run's summary.

**The smoke test** (`src/debug/smoke_test.gd`, `SmokeTest`; `-- --smoke-test [--smoke-out=FILE]`
on any build, a release export included): 30 s of the street (the gang in, a stick on the range, a
member alight, a shot), every error counted by a Logger, then `[smoke] ok ...` and exit 0, or
`[smoke] FAILED` with the errors and exit 1. Drawn, its clock starts at the first frame on
screen, and each event waits for a few frames after the last; on the desktop it fails if the native
plugin isn't loaded. In `build.yml` the export job no longer releases:
`smoke` runs each export on its own runner (Linux headless and drawn under lavapipe at 640x360,
Windows, macOS, all headless), and only then `release` (the GitHub Release) and `pages`.

**The visual checks in CI** (`.github/workflows/visual.yml`, every night at 06:43 UTC and by
hand): every fixed view rendered twice under xvfb and lavapipe on two runners at once (~1–2 h
each), then `tools/scene_probe.gd`, `tools/golden_check.py --from=A` and `tools/visual_checks.py
--from=A --twin=B --probe=P` (the art session's tools, layout notes above). Red on any failure;
the run's summary lists what failed and the artifact `visual-report` holds golden | render |
difference for each. Rendered with `--fresh` (`screenshots.gd` loads the scene again before every
view, as `golden_check.py --render` does), so no view carries the one before it and `--only=` of
a few views renders them as the full run does.

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
  faces. **A minimum square on screen** (shader global `min_square_px`, 2 render pixels since §10.4,
  was 4: the painting's far men are still 2–3 px blocks, but distance softens, never chunks; 0 = off;
  `screenshots.gd --min-square=N`): where a texel would be smaller, `tile_square()` gives squares
  of 2, 4, 8... texels, each the colour of the one texel at its centre (not the mip's average: that
  read plain) and lit as one, on the texel grid and the ground, so the far street stays chunky as
  the painting's does; `fixed_squares` keeps a material out of it (SignArt's boards: lettering).
  **The screen mosaic** (`depth_mosaic.gd(shader)`, `DepthMosaic` on the game camera, since
  2026-10-03, `Settings.mosaic` on by default, saved; `screenshots.gd --no-mosaic`, `--mosaic=K
  --steps=N`): the finished lit frame cut into blocks of about `MOSAIC_K` 5 / depth render
  pixels (3–4 px on a man across a table, 2 px far off, at 1280 wide: the saloon painting's
  blocks are nearly one size), each block one colour (the sample at its centre; a block takes
  its colour only from its own distance band, so a near thing keeps its own blocks), the light
  posterised into `MOSAIC_STEPS` 14 tones. Silhouettes go stair-stepped at the block size as the
  painting's are and a model's facets hide under the blocks. Not on the Compatibility renderer
  (no depth texture). The finish's softening is off by default under it (`LOOK_VERSION` 5).
  The first trial of it (`--screen-squares=N`, 2026-10-02) only chunked far surfaces and
  averaged each block, and lost to the old judge that rewarded noise. `pixel_screen`: F6.
  **The quantise-once look** (Pixel-factory's plan A1, 2026-10-03; `Settings.quantise_once`,
  **I** toggles, saved, off by default until Sean's eye on a real GPU; `screenshots.gd
  --quantise-once`): every pre-blocking step off (tile light off, `min_square_px` 0: Settings
  owns that global now, `MIN_SQUARE_PX` 2; `PixelArt.smooth`: the factory's textures from
  `assets/textures/smooth/`, the same paintings cut by `reduce.py --smooth` at four times the
  texels with no palette, the grid density ×4 with them; `PeopleBodies.smooth_paint`: a whole
  man's `<id>_skin_smooth.png` / `_head_smooth.png` from `fit_tripo.py --smooth`, no squares,
  from `head_paint.py bake --smooth`'s unquantised head) and the mosaic refined by
  `DepthMosaic.tuning` (`Settings.QUANTISE_TUNING`; shader knobs `depth_power`, block size as
  `block_k / depth^power`, 0.5 = nearly one size near and far; `soft`, pixels of blend across
  block edges; `average`, a block as the mean of its own band's pixels, with `dark_weight` the
  darker pixels weighing more so shadow edges keep the shadow; `sat_steps`, `hue_steps`, the
  block's colour snapped to a limited palette as well as `steps` of light; and `block_in` /
  `block_out`, the block size under a roof and in the open, 4 and 6 px: the mosaic node casts a
  ray up from the camera every quarter second and eases between them; `--mosaic-tune=k:v,...`,
  `--saloon-tune=` / `--street-tune=` for one shot). The world's materials take their textures
  when built, so the switch reloads the scene. Verdict in the status entries;
  `docs/screenshots/quantise_once/compare.png` (`tools/quantise_compare.py`).
  **Native is the default** (`Settings.NATIVE`, F2's first stop, since §10.10: render at the window's
  size; `LOOK_VERSION` 4 moves a saved 1280×720 to it) and **the finish pass** (off by default
  since the screen mosaic, `Settings.finish`, docs/ART_REVIEW.md §8.7; `screenshots.gd --no-finish`): `pixel_screen`
  softens a render pixel on a hard edge between blocks toward its neighbours (`finish_soften`
  0.5, a jump across the pixel both ways; fine lines and smooth areas untouched) and the tile
  light is worked out part way back from the tile's centre toward the fragment (shader global
  `tile_gradient` 0.3), a faint gradient of the real lighting across each tile.
  **The surface-blocks look** (docs/briefs/renderer.md, 2026-10-05; `Settings.surface_blocks`,
  **M** toggles and reloads the scene, saved, off by default until Sean's eye; `--blocks` on any
  run's command line for that run; `screenshots.gd --global=name:value,...` sets any shader
  global for a render): the blocks are the surfaces' own texels, as the tile look's are, with
  no screen pass. `tiles.gdshaderinc`: `block_soft` (global, render pixels of blend across a
  texel's edge: `tile_soft_point()` is the pixel-art anti-aliasing trick, the texel sampled at
  its centre everywhere but within that of its edge, where the sample slides to the neighbour,
  and `tile_sample_soft()` the bilinear fetch that blends there; the light is worked out at the
  same point, so it slides across the edge too), `light_bands` (each light's share in steps,
  `tile_band()`; 0 = smooth: the judge preferred flat blocks lit smoothly, bands drew rings on
  the table) and each material's `shade_tint` (what the lower light leans toward:
  `PixelArt.SHADE_TINT`, a warm brown, on the world and on skin). `texel_grid_blocks.gdshader`
  / `member_holes_blocks.gdshader` are the grid shaders with that `light()`
  (`PixelArt.blocks`, `grid_shader()`, `hole_shader()`; compare shaders with `is_grid_shader`
  / `is_hole_shader`, since either may be in use); `body_skin` and `ground.gdshader` take the
  globals in place. Under it `min_square_px` is 0 (distance softens into the mip and the haze,
  never chunks), the mosaic and the finish are off (`Settings.mosaic_active()`).
  `tools/pan_frames.gd` pans a view frame by frame and measures how much changes and flips back
  (the flicker probe's measures), for judging a look in motion.
  **The probe mosaic** (a trial, 2026-10-05, the characters session at Sean's request;
  `src/render/probe_mosaic.gd(shader)`, `ProbeMosaic` on the game camera; `Settings.probe_mosaic`,
  **V** toggles, not saved, off by default; `--probe-mosaic[=texels] [--probe-bands=N]` on any
  run's command line, `--probe-param=name:value,...` in `screenshots.gd` and `probe_walk.gd`):
  texel splatting's idea (Ebert 2026, from the paper's description) as one pass over the finished
  frame. Each pixel's point in the world falls in a texel of a cube of `probe_texels` (384, spaced
  by equal angle) a face round an origin snapped to a `probe_cell` (0.5 m) grid, and the whole
  block takes the frame's colour at its centre, so blocks stay put as you turn and, within a cell,
  as you walk, and outlines step at the block size; crossing a cell re-cuts them with a
  block-by-block cross-fade; within `near_screen` (0.7 m, the gun) blocks are cut on the screen,
  past `far` (200 m, sky and backdrop) the frame is left. Under it the game viewport is
  multisampled (`ProbeMosaic.MSAA`, 4x, put back when it goes; `--probe-msaa=N` for a trial) and
  the textures' texel edges are soft (`Settings.PROBE_SOFT`, 1 px of blend; `--probe-soft=`): it
  re-reads the frame at each block's middle, so a texel edge or an outline's stair-step jumping a
  pixel there flips the whole block. Light bands (`probe_bands`), a mean of 3x3 samples
  (`samples`), a dark-weighted mean (`dark_weight`), a blurred read (`prefilter`) and a
  cross-fade that blends the old cube's colours into the new (`fade_blend`) are there, off. It
  brings the quantise-once textures and gives way to the surface blocks
  (`Settings.probe_active()`). **Motion measures:** `tools/probe_walk.gd` renders six camera paths
  through the saloon shot's set at a fixed step (or, `--depth-pass`, every pixel's distance and
  each frame's camera), and `tools/probe_walk.py stability DEPTH RUN...` moves each pixel back to
  where its point of the world was a frame before and counts those whose colour isn't there (the
  camera's own movement taken out; no mosaic scores 0.1-0.2 %); `measure` gives the plain changed
  and flipped-back shares, `video` a side-by-side (`--crop=` for a phone).
  Still lit smoothly (StandardMaterial3D): guns, lamps, `PropLibrary` props, effects.
  **Light with range** (`docs/ART_REVIEW.md` §3.1, §8.1): the night room is dark
  (`ambient_energy_night` 0.7, the saloon's `night_ambient` 0.035, `exposure_night` 0.72) and lit by
  its lamps; only true emitters bloom: the chimney glass is drawn well over display white round
  the flame (`chimney_glass.gdshader` `bloom`), the moon at 2.5, and the environment's glow
  (scene file, lighting lines) is screen-blended at threshold 1.7 with `glow_bloom` 0 (any bloom
  share veils the whole frame), so nothing lit by a lamp blooms. The review's light numbers
  (median L*, deep-shadow and highlight shares, chroma–L* correlation) are the check, not the
  judge's score, until judge v2.
- **The look panel** (`src/debug/look_panel.gd`, `LookPanel`, in every build; **N**, controller
  Back + Start): sliders for every look setting, laid out by `config/look_panel.json` (from the art
  session's list, `docs/briefs/look_settings.md`; add a row there: address, label, range, `what`),
  a time-of-day slider, Save (`user://looks/<name>.json`), Export (the preset to the clipboard),
  Load, Reset. `LookPreset` (`src/debug/look_preset.gd`) sets and reads every value by address
  (`day.`, `env.`, `sun.`/`moon.`, `sky.`/`ground.`/`backdrop.` shader uniforms, `lamps.<all|street|
  saloon>.<energy|light_range|haze>` multipliers, `building.<id>.night_ambient|room_haze`,
  `mosaic.`, `paint.`, `settings.`, `global.`, `hour`); a preset is `{"name", "hour", "values":
  {address: value}}`. **`--look=FILE`** after `--` applies one to any run of the main scene (the
  game, `tools/screenshots.gd`, the dev bridge): `xvfb-run -a godot --path . --rendering-driver
  vulkan -s res://tools/screenshots.gd -- --look=sean.json --only=shot_match`.
- `src/main/main.gd` + `scenes/main.tscn` — the pixel pipeline: world renders in `GameViewport`
  (SubViewport at `Settings.internal_resolution`, 1280×720 default), drawn to `Screen` with nearest
  filtering.
- `src/player/` — controller, visible body, tuning resource (`config/player_tuning.tres`),
  `PlayerComposure` (flinch, rattled, winded; the guns read `sway_scale()`/`extra_spread()`).
- `src/world/` — `DayCycle` (clock + sky; `config/day_cycle.tres`), sky and ground shaders, oil lamps,
  placeholder scenery.
- `src/world/town_layout.gd` + `config/town.json` — **the town's layout** (docs/briefs/main-street.md):
  `TownLayout`, the street's first child, places the nodes the file names (by path: the store,
  saloon, boardwalks, rail, trough, markers) before anything builds; an entry `in` a building is
  in its space and moves with it. `TownLayout.transform_of(path)` / `point(building, local)` give
  the same places to code with no scene (`Waypoints.test_street()` puts the store's and saloon's
  insides through it). Move a building: change its entry. Since Main Street step 2 the file is
  Sean's map (`docs/concept/town-map.png`): Main Street along X, west −X toward the sunset; the
  south side (fronts on z 0) from the east the saloon, the store, the barber, Market Street, the
  hotel; the north side (fronts on z −16.8) the livery, the jail, the water tower's yard, the
  assay office; Freight Street crossing at the east end, the range 30 m beyond. A building's
  boardwalk is up on steps (`Boardwalk.steps`: people and the player come and go by them, the
  edge elsewhere a step too high). `StreetDressing/<name>` entries are the dressing's façades
  (it builds them where the layout says, each with its walk). A building's `was` is where it
  stood on the old street: `TownLayout.carry()` moves what was laid out round it there (the
  dressing's tables are still in old coordinates) to where it stands now, and the dressing leaves
  out whatever would stand on steps and moves people out of doorways
  (`StreetDressing.on_steps`/`out_of_doorway`); `tools/screenshots.gd` moves its store, saloon
  and range views the same way (`_view_move`).
- `src/structures/` — `Structure` + `StructureMember` (members with IDs, kinds, support tiers and an
  inferred support graph; `settle()` breaks/drops what can't stand, rubble), `StructuralAnalysis`
  (loads down the graph, compression/buckling/bending/joint checks; `config/timber.tres` via
  `TimberTuning`), `FalseFrontBuilding` (shape options: two-storey fronts with `sign_from`, a barn's
  `gable_front` + `loft_door` + `gable_sign`, `batwings`, `window_bars`, `porch`, `furnished`),
  `Boardwalk`, `HitchingRail`, `WaterTrough`. A structure draws its untouched members as one mesh
  per material (`batch_meshes`); `unbatch(m)` (a hole, heat, breaking) shows the member's own.
  **Fittings** (`Fittings`, a node at the end of the test street): four physics frames after load
  it finds every prop, lamp and drawn thing in a structure or the street's dressing whose bottom
  is off the ground, and the members its box touches (a shape query on WORLD, 4 cm round it) and
  the fittings it rests on; a quarter second at a time it looks, and when every member is gone
  (broken, consumed, moved) and everything it rests on has fallen, it becomes a RigidBody3D in
  group `fallen` (DEBRIS under 0.6 m, else WORLD) and falls; a lamp in it landing at 1.5 m/s or
  more `smash`es (burning oil). Painted signs are the sign member's children and go with it;
  loose bodies and invisible things (a stair's ramp) aren't fittings. Not saved yet.
  **Voxel damage** (docs/DESTRUCTION_BRIEF.md step 2; `config/voxel_damage.tres` via
  `VoxelDamageTuning`): a member hit for the first time gets `voxels`, the native plugin's
  `VoxelMember` (64 cells a metre, a whole number per side so the uncarved member is its box);
  `Ballistics` walks the solid runs a projectile meets (`solid_runs`) and each is carved
  (`carve_hit`: the channel at the projectile's size, plus spall from the energy spent and the
  muzzle blast, split along the grain, ragged, the wood round it torn: fresh-cut faces), chips
  thrown (DEBRIS, frozen after 2.5 s), meshed on the plugin's workers and swapped in by
  `VoxelWorks` (one per structure: the outside keeps its material, carved and torn faces are
  fresh wood, collision a ConcavePolygonShape3D); `section_left`/`weakest_t`/`weight` read the
  voxels (holes within the member's depth along the grain count together). No plugin (web) or
  `enabled` off: holes drawn by `member_holes.gdshader` as before.
- `src/fire/` — `FireSystem` (member temperatures, heating by contact/radiant/flame plume, ignition,
  char, ash, spilt lamp oil, scorching people, water: `douse()` puts out and wets members, a wet one
  dries before it heats (`StructureMember.wet`); `fire_near()`/`burning_map()` for people getting
  clear; `config/fire.tres` via `FireTuning`), `FireFX` (flames, smoke, steam,
  `char_overlay.gdshader`). `tools/fire_timeline.gd` measures how fast a fire grows.
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
  stick in hand. `BucketViewmodel` (4) is a water bucket: R fills it at a `water_source` (troughs),
  LMB throws it as drops on their own arcs, each handed to `FireSystem.douse()`; `armed` false (a
  held thing people don't take for a weapon: PlayerDeeds, the shout, OutlawBrain).
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
  the lab. **The voxel trial** (`src/art/voxel_trial.gd`, `VoxelTrial`, 2026-10-03; off
  everywhere, `screenshots.gd --voxel=props,hat,eyes|all --cubes=64`): the shot's mug, lamp
  (not its glass), bottle, ashtray and the seated man's hat as cube-built copies
  (`tools/voxel_export.gd` writes the props' parts as OBJ; `tools/blender/voxelise.py` makes a
  shell of cubes along each surface, 1/128 or 1/64 m, every face carrying the smooth surface's
  normal, the hat's faces the texel under them in an atlas → `assets/props/voxel/`,
  `assets/people/voxel/`), on the same grid material mapped triplanar with `cube_faces` (the
  light stays at the fragment: a texel's centre is off a face far smaller than it); and smooth
  eyeballs on his painted irises (`EYES`, measured per model). Verdict in the status entry;
  `docs/screenshots/voxel_trial/compare.png` (`tools/voxel_compare.py`). `tools/character_lab.gd` judges the man on his own: ShotMatch's table and man in an empty world
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
  **squares**: a set size on him per shape (`SQUARES_PER_M`: cloth 160, face 190, hands 150; the
  face's squares are 3×3 texels so its eyes can be drawn finer, `DETAIL`/`square_texels`), each
  the average colour under it, a palette a shape (`SHAPE_COLOURS`, 8–32) → `assets/people/
  <id>_paint_<shape>.png` (one texel per square) + `<id>_paint.json`. **The hybrid finish**
  (`finish.py` `HYBRID`, docs/ART_REVIEW.md §6, since §10.7): the painting's own pixels are left
  out (`VIEW_WEIGHT` shot 0: they were lit and never matched his shape), the squares are plain
  averages (the old dominant-colour rule made noise of the model's shading; the face keeps its
  dark-kept rule and `face_draw.py`), and `body_skin` lights him like everything else
  (`HumanBody.paint_look`: the game's ACES grade undone, self_lit 0, light_steps 0,
  `paint_ambient` 1, paint_gain 2.2 as the model paints him in even mid light, limit 4, wrap 0.3;
  the old look's numbers are in the comment there) and lights each square as one (the light's
  position and the normal at the texel's centre, `LIGHT_VERTEX`). `HumanBody.use_paint` off (the
  townsfolk, the shot's extras) = the same body in code-painted cloth of his own colours and his
  own code-painted face, so the street and the room aren't one man many times.
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
  **Judge v2** (2026-10-02, after `docs/ART_REVIEW.md` §5): the score is whole-frame *style*, not
  composition: L* percentiles and the deep-shadow / blown-highlight shares, chroma, warmth and
  the chroma–L* correlation (symmetric); coherence (fine detail on the mid-scale structure),
  grain in flat areas, near tiles finer or far tiles chunkier than the painting's (one-sided, so
  noise and chunkiness can never buy a better score); edge hardness; palette gaps relative to
  the painting's own quantisation. The old mosaic/tile/region numbers are still printed, not
  scored. `python3 tools/judge.py --probes` is its test: the review's probes (the painting, shifted
  60 px, block and pixel noise, blur, greyscale, a grade toward the painting's light, and round 27
  against round 25) must rank as a viewer would; run it after touching the measures. `--pick="…"`
  records Sean's verdict on a round. Scores before round 28 are v1's and don't compare.
  **The blind critic** (`tools/critic.py`, since 2026-10-04, the rule in How we work): after
  every art merge, `critic.py prepare <round>` lays the two paintings and the round's renders
  (and `--extra=DIR` renders, the tour's frames once they exist) in `<round>/critic/` and prints
  the prompt; a fresh Agent (general-purpose, nothing else in its context) gets that prompt as
  its whole task, looks only at those images, makes a crop per difference with `critic.py crop`
  (the same box from the render and the painting, side by side at 3×) and writes
  `<round>/critic/critic.md`: the five biggest differences a viewer would notice, biggest
  first, with crops; `critic.py top <round>` prints the top three for the status entry. The
  judge measures style; the critic says what a person sees; both choose what's next.
  **Golden images** (`tools/golden_check.py`, the rule in How we work): every view in
  `tools/screenshots.gd` has an approved render in `docs/screenshots/golden/<view>.png`;
  `--render` (or `--from=DIR`) compares each render to its golden on two measures (the mean
  absolute difference per channel and the share of pixels moved by more than 24/255) against
  `tolerances.json` (per view: a still's floor is mean 1.5 / share 1%; scenario views with
  physics, particles or brains have theirs set from two renders of the same build, `--approve
  --noise=A,B`, three times the measured noise) and writes golden | render | difference ×6 for
  each failure; exit 1 on any. Approving a new look re-approves its goldens in the same merge
  (`--approve --from=DIR`). Lavapipe renders only: a real GPU differs everywhere. The gameplay
  session wires the check into CI (needs `mesa-vulkan-drivers` + `xvfb` on the runner).
  **The visual checks** (`tools/visual_checks.py`, since 2026-10-05, Sean via gameplay's
  automated-checks brief): from the renders, `blank` (a frame of one colour, black, or mostly
  exact black: a NaN in the lighting or a player blacked out in a scenario), `missing` (magenta
  pixels), `flicker` (`--twin`: two renders of one build differ by more than the view's measured
  noise, the goldens' `tolerances.json`); from `tools/scene_probe.gd`'s data (headless, ~20 s:
  the street with its people and the gang, then the saloon shot staged; `scene_probe.json` +
  each man's posed vertices in `people/<phase>_<name>.bin`), `missing` (grid materials with no
  texture), `feet` (a standing or seated man's soles in the ground, or a standing man's both
  off it), `floating` (floor-standing props and the street's dressing over or into what's under
  them: five rays across the footprint, the highest surface wins) and `clothes` (the share of
  an inner layer's vertices near a garment that lie outside its surface, worst pair per man,
  by HumanBody's garments and what they cover). Limits in `tools/visual_checks.json`; its
  `known` entries are measured faults tolerated at today's value, each with why.
- **The texture factory** (`tools/textures/`): `materials.json` lists the world's materials (id =
  the key `PixelArt`/`WoodMaterials` ask for: floor, saloon_wall, dark_trim, shot_table, framing,
  weathered_pine, painted_ochre/rust, sign, road) and lettered signs (sign_saloon, …), each with a
  crop of a painting for colour. `paint_textures.py` paints them on OpenRouter (FLUX.2 [max]; run
  it on Actions: People workflow, input `textures` = all / saloon / street / ids; openrouter.ai is
  blocked from the workspace) into `assets/textures/raw/<id>.jpg`; `reduce.py` (runs anywhere)
  flattens the painting's light part way (`FLATTEN` 0.3: its lit side and each board's own colour
  are kept, docs/ART_REVIEW.md §8.3), wipes board joints (`boards`), makes it seamless, cuts it to
  32 texels a metre (`texels_per_metre`) with no pushed mosaic (`MOSAIC` 1.0), applies the judge's
  corrections in Lab (`grade`: `lightness`, `contrast` on L*'s spread, `chroma`, `hue` in degrees),
  snaps to a palette (28 colours a material, the road 32)
  → `assets/textures/<id>.png` + `textures.json`; and for `boards` materials cuts **each board the
  painting drew out as its own strip** (`board_strips`: the bands between its seams, seamless along
  the grain, the tile's palette) → `<id>_b<k>.png`; `WoodMaterials.get_material()` gives every
  member one strip by its ID (`strip_count`), so no two boards on a wall are alike and nothing
  repeats every 2 m (`docs/screenshots/textures/board_strips.png`); woods with no strips keep the
  tinted, shifted tile. `PixelArt.factory(key)` hands them out in place
  of the code-painted texture of that key (`use_factory` off = the old ones); the grid material
  sizes any texture by its own size; the ground shader takes `road`. Change a material's numbers
  and re-run `reduce.py` here: no new painting needed.
- `src/props/prop_models.gd` (`PropModels`): every manifest prop modelled in code (lathe, loft +
  boxes, UVs in metres, on `PixelArt.material()`); `PropLibrary` uses them where there's no .glb;
  `OilLamp` draws `PropModels.lamp()`. `loft(rings)` skins rings of points (flat-shaded quads,
  `_ring` ellipses tilted square to a path, `_arc` a part of one, `_limb` a tapered bar between
  two points): the **horse** (docs/ART_REVIEW.md §3.5: a lofted body, an arched neck and long
  head on tilted rings, a mane, tail, legs with knees and hocks, a blanket and stock saddle on
  arcs over the barrel, a headstall; ~900 faces) and the **hay bale** (a bulging rounded block,
  twine bands, loose straws). `tools/prop_views.gd out.png [--close]` shows the manifest props;
  `--street` the street's code models (horse from three sides, hay, crate).
- `src/art/saloon_dressing.gd` (`SaloonDressing.build()`, called by `SaloonBuilding`): plank walls,
  stair and balcony (members), tall mirrors (a `ReflectionProbe` the room's size gives them
  something to show), piano by the door, stag, pictures, two dozen lamps (sconces, lamps on the
  back bar, lamps hung on rods; no shadows, their chimneys glow), a bottle wall (`_bottle_wall`:
  a few hundred bottles merged into one mesh per material; scenery, not shootable).
  `ShotMatch` turns and places its whole set (`ROOM_YAW`, `TABLE`: beside the bar, the tall front
  door on your left) and stages extras (`EXTRAS`, `CARD_TABLE`) for the shot. The moon has its
  own low arc (`DayCycleConfig.moon_tilt_degrees` 78: it crosses ~12° up over +Z), so from the
  shot (23:40) it stands in the saloon's doorway over the `EatingHouse` across the street.
- `src/art/sign_art.gd` (`SignArt`): the factory's painted sign boards, laid on once at their own
  shape; `FalseFrontBuilding` hangs one for its `sign_text` (SALOON, DRY GOODS, …) where there is
  one, else the lettered label. `src/art/street_dressing.gd` (`StreetDressing`, a node in the test
  street): the false fronts down the street (`BUILDINGS`: saloon, general store, barber, hotel, eating house;
  livery, jail, assay office) and their boardwalks (`WALKS`), carriage lanterns, barrels,
  crates, hay, hitching rails with horses (`_rail`), a covered wagon and a buckboard, boards hung
  under the porches (`_hung_board`: MEALS, BATHS, ROOMS, GUNSMITH, SHERIFF, ASSAYS), telegraph poles
  and wire, the water tower over the roofs on the right, dry
  grass (`src/art/dry_grass.gd`, `DryGrass`: one multimesh of crossed-quad tufts, thick along the
  road's edges, none under floors or down the wheel tracks). **The street is one painted 8 m tile**
  (`road_wide`, kind ground: ruts, hoof marks, stones and grass painted as real things from
  above, docs/ART_REVIEW.md §8.3); `ground.gdshader` lays it along the street with its middle on
  the road's centre line, mirrored end for end every other 8 m and the 2 m `road` tile showing
  through in broad patches (its own drawn ruts and pebbles are left out while it's in use; without
  it they draw as before). The ground has its own `light()`: the sun's direct light scaled
  (`sun_direct` 0.7) plus an unshadowed share of it half way to grey (`sky_fill` 0.15: the ground
  faces the whole sky, and the painting's road is lit ochre in the fronts' shadows too; a flat
  surface under a 15-degree sun drew at L* 20 to the painting's 50); `sun_wrap` is there, 0. The
  sky (`src/world/sky.gdshader`, `disable_fog`) paints its own horizon haze, keeps the warm glow
  near a low sun and the rest a pale grey-blue (the painting's upper sky is L* ~61), and has
  painted clouds (`cloud_shape()`: loose bands of small ragged heaps stretched across the street,
  `cloud_cover`/`_scale`/`_ragged`; soft-edged, shaded smoothly from cream-gold tops through warm
  bodies to grey-violet undersides, `cloud_tones` 0 = smooth; dark at night). The sky is smooth
  (`sky_squares` 0, `sky_mosaic` 0 since §10.4: the painting's sky and far clouds are soft).
  **The painted backdrop** (`src/art/backdrop.gd`, `Backdrop`, added by StreetDressing): the
  country round the town as three painted strips on rings round `CENTRE` (far spires and mesas 650
  m, mid hills 430 m, near foothills with junipers 260 m), lit by the time of day in
  `backdrop.gdshader` (unshaded, its own haze from the fog's colour, colours through the ACES
  inverse: as painted at noon, gold on the sunward side and warm shade with gold skyline rims with
  the sun low, dark at night). Painted by `tools/textures/paint_backdrop.py` (People workflow input
  `backdrop`: all / a layer / panels; FLUX.2 [max], four 90-degree panels a layer on a green
  screen, the street painting's mountains as reference; `tools/textures/backdrop.json` says what
  each panel shows, its bearing and `shift`, the layer's `scale` and `band`) and cut by
  `reduce_backdrop.py` (runs anywhere: green keyed out, the band under the land's foot dropped,
  squares at 0.15 degrees (half the first cut's: the painting's far rock is soft), panels shown
  smaller than 90 degrees tapered at their sides, the near layer kept to a low band under a
  rolling hill line, columns filled solid, a faint mosaic, a palette a layer (40/36/32 colours);
  in the shader each layer's haze is scaled by the scene's fog density (`haze_scale`) → `assets/textures/backdrop_<layer>.png` + `backdrop.json`). Bearings increase to
  the right as you look out (`Backdrop.direction()`: 270 is west, down the street).
- **Characters by image-to-3D** (`tools/characters/`, step 4 of the art plan; People workflow
  input `characters`): `paint_full_length.py` paints each man in `characters.json` full length
  in an A-pose, clean (Tripo wants a smooth picture; the squares are made last). **The fal
  route** (the default with `FAL_KEY` and the style LoRA; `--via=openrouter` is the first route,
  FLUX.2 [max] with the painting's man as reference): FLUX Kontext with the LoRA (`FAL_EDITOR`,
  default `fal-ai/flux-kontext-lora`, `SCALE` 0.25: at 0.5 it painted the coat in blocks) redraws
  him from the full-length painting there (its mosaic smoothed away first, `smoothed()`) or
  the concept painting's man (`--from=painting`, or a new man), then his left side, back and
  right side from that front → `assets/people/tripo/<id>_full.png`, `<id>_left/_back/_right.png`
  and `<id>_turn.png` (the four in a row); `--dry-run` runs it on a stand-in editor. `tripo.py`
  uploads the four as Tripo's multi-view input (`multiview_to_model`, front/left/back/right; the
  front alone is `image_to_model`) and asks for a textured model, then a rigged one → `<id>.glb`
  (+ `_mesh.glb`, every answer in `_tripo.json`, which starts with a hash of each picture: a
  model is made again when its pictures change, or with `--again`); the folder is `.gdignore`d
  (pipeline inputs, not game assets). People workflow: `style: characters` paints only (look
  before Tripo is paid); `characters: <ids>` paints then runs Tripo (`repaint` repaints and
  models again). Needs the repo secrets `FAL_KEY` and `TRIPO_API_KEY`; the client ran against the
  live API on 2026-10-02 (People run 17).
  **His head in the style** (`tools/characters/head_paint.py`, People workflow `style: head`):
  Tripo's face comes out smooth (his pictures had to be), so the head is painted after: `guides`
  cuts the head off the mesh above the collar (`HEAD_FROM`) and renders it from six orthographic
  views in Tripo's own colours, lit (numpy, no Godot or Blender: `<id>_head_<view>_guide.png`);
  `paint` has FLUX dev's image-to-image with the style LoRA at full scale repaint each view
  (`FAL_HEAD_EDITOR` default `fal-ai/flux-lora/image-to-image`, `STRENGTH` 0.68: the head stays
  where and how it is, the LoRA draws the painting's man in his squares; FLUX Kontext with the
  LoRA was tried first and painted a front-facing oil portrait for every view); `bake` projects
  every painted view back through its camera into the mesh's UV space (depth-tested, the view
  facing a texel squarest wins, weights³), fills what no view saw, cuts the head to squares of
  `SQUARE_M` 5 mm on him and `COLOURS` 28 → `<id>_color.png`, Tripo's texture with the head
  repainted; `docs/screenshots/tripo/<id>_head_views.png` is guides over paintings.
  **The fit** (`tools/blender/fit_tripo.py`, bpy; the People workflow's people job runs it after
  `make_people.py`): a person in `people.json` with `"source": "tripo"` is fitted from
  `assets/people/tripo/<id>.glb` instead of MakeHuman: his one mesh into our body space, each
  limb warped joint to joint from Tripo's rig onto ours (`JOINTS`, the same warp as
  `make_people.Person.warp`; the trunk and neck stretched to our joints, the head at his own
  proportions scaled by his hips to ours), no envelope fit (he wears a coat; his widths are his),
  the coat's skirt hung from the hips (`SKIRT_RADIUS`, `BETWEEN_LEGS`: a skirt on the thighs
  stretched into a flap when he sat), fingers cut at the knuckles, BodyMesh's joint blends
  (`Person.weights`), the head (above `HEAD_FROM`) and the body as `body_head` / `body_skin`
  decimated in Blender (`HEAD_TRIS` 2200, `TRI_BUDGET` 5500) → `assets/people/<id>.glb` with
  Tripo's UVs; his texture (the repainted `_color.png` where there is one) in squares of
  `SQUARE_TEXELS` 4 (~5.6 mm), one texel a square → `<id>_skin.png` + `<id>_head.png`
  (`PeopleBodies` lays them on by UV as baked garments); `<id>.json` says `"whole": true`, and
  `PeopleBodies` then puts nothing of BodyMesh's on him (he comes dressed, hat and boots too).
  **Layers** (docs/DESTRUCTION_BRIEF.md part 5, since 2026-10-04): a person's `model` is his
  Tripo body painted bare-headed and coatless (`characters.json`: a `from` entry is redrawn from
  that character's finished front with `change` saying what to take off, `hatless` fixes the
  turnaround's words) and his `pieces` {shape: character id} are garments painted alone as
  ghost-mannequin pictures (`item`: Tripo models them unrigged, `<id>.glb` is the mesh);
  `fit_tripo.py` scales and places each piece by landmarks in his Tripo space (`Piece.place`: the
  coat's shoulder line onto his shoulders at `PIECE_MARGIN`, the hat's brim onto his head's band
  at `HAT_BAND` of the way from jaw to crown), carries it through the body's own warp
  (`warp_points`), skins it by the same tables (the coat's skirt from the hips, the hat all head)
  and exports it as `body_<shape>` in his glb (`PIECE_TRIS`) with `<id>_<shape>.png`;
  `PeopleBodies` wears every piece a whole man came with, so the hat is its own mesh (gameplay's
  hat-shot-off needs that) and the coat can come off. A bare-headed man's head cut is
  `HEAD_FROM_NECK` of the way from his neck joint to his jaw. **State (2026-10-04):** the hat
  works (`stranger_layered`: body + hat); the coat piece does not yet. A Tripo garment is a
  double shell (its lining 1–3 cm in: `_drop_lining`), at an ordinary man's girth on a broad
  man, and no landmark registration put it cleanly over him (inside his skin, or torn by the
  clearance push, `_clear_body`); `Piece.as_shell` (the coat as an offset shell of his own body,
  its look by nearest-point UV from the Tripo coat, cut where that coat has no cloth) fits by
  construction but its UVs smear across the atlas's islands and its coverage test fails where
  the Tripo coat sits inside him. Next for the coat: bake the Tripo coat's colour onto the shell
  (per-vertex colour from the nearest coat point at full resolution, the shell unwrapped in
  Blender and baked to its own texture, then decimated), the way `clothes.py` bakes garments.
  `stranger` stays the whole man meanwhile.
  `ShotMatch.model` picks the seated man's body (`tools/screenshots.gd --model=stranger`,
  `character_lab.gd --model=`; set at run time: naming ShotMatch in a `-s` tool script compiles
  the game's scripts before the autoloads exist).
  `tools/tripo_lab.gd --out=DIR [--id= --yaw= --fill= --height=]` loads a Tripo glb at run time
  (GLTFDocument: the folder is unimported), lays `<id>_color.png` over his material where it
  exists, stands him where the painting's man sits in the character lab's light and writes the
  shot view, four orbit views and a contact sheet (`docs/screenshots/tripo/<id>_lab.png`), and
  his head close beside the painting's man's (`<id>_head.png`): the judge before the Blender fit. `tripo.py --dry-run` runs
  the whole client (upload, both tasks, waiting, downloads, the log) against a stand-in Tripo on
  this machine (`tripo_standin.py`: answers as the v2 API, objects to anything the real one would
  refuse) into a scratch folder: no key, no .env, no network; `--balance` checks a real key and
  spends nothing. The workflow runs both before the real call.
- **Training the image model on our style** (`tools/style/train_style.py`, People workflow input
  `style: train`, repo secret `FAL_KEY`, optional variable `FAL_TRAINER`): crops of every concept
  painting (squares of half its height, three rows across) and every picture in
  `docs/concept/style/` (Sean's; `captions.json` there for words), each captioned with the
  trigger `SLTCRK`, zipped, uploaded to fal's storage and trained as a style LoRA on fal
  (`fal-ai/flux-lora-fast-training`, `is_style`); the result's URLs go in
  `tools/style/style_lora.json` (the weights stay on fal). Trained on the live API 2026-10-02
  (People run 18); `--dry-run` cuts and zips only (`build/style_train/sheet.png` shows the crops).
  `tools/style/sample_style.py` (People workflow `style: sample`, `FAL_SAMPLER` default
  `fal-ai/flux-lora`) paints six set prompts with FLUX + the LoRA (`loras: [{path, scale}]`) into
  `docs/style_test/lora/` and a contact sheet beside the paintings. The old `style_test` input
  is now `style: photo`. Fitting the result to our skeleton and hitboxes in Blender is still to
  come; MakeHuman stays the fallback.
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
- `addons/saltcreek_native/` — the native plugin (Rust, gdext 0.5.5, `api-4-7`; `cargo build
  --release` there, copy `target/release/libsaltcreek_native.so` into its `bin/`; `cargo test
  --release` for its own tests): `volume.rs` (Pixel-factory's brick volume, cells per axis),
  `carve.rs`, `mesh.rs` (greedy, two surfaces + collision), `pool.rs` (worker threads),
  `member.rs` (`VoxelMember`), `lib.rs` (`NativeBench`).
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
- 2026-10-02 (art session; features frozen, the only session): **Look 1: real false fronts down
  the street.** The blockouts are gone (StreetScenery keeps the church); `StreetDressing.BUILDINGS`
  puts member-built `FalseFrontBuilding`s on their lots: the painting's SALOON (two-storey front,
  the big painted board over the porch, batwings), the GENERAL STORE (DRY GOODS board on its side),
  a barber and a hotel on the north side; the LIVERY (a barn: gable front, double doors, loft door,
  the painted board on its boards), the JAIL (barred windows) and an assay office across, the
  south ones 4.4 m further west than the old lots so the livery sits at the frame's right edge as
  in the painting; boardwalks before them. The street shot stands in the middle of the road east
  of the saloon (`StreetMatch.FEET`/`LOOK`). Gameplay files touched (only session, so said here):
  `false_front_building.gd` (the shape options above), `structure.gd` (**member batching**: seven
  more buildings put ~2,500 members on the street, a draw call each in every shadow pass; untouched
  members now draw as one mesh per material per structure and leave it when holed, heated or
  broken), `fire_system.gd` (unbatches what it heats), `street_scenery.gd` (blockouts out),
  `test_dynamite.gd` (the store throw from 7 m, not 9: the stick bounced along the boardwalk and
  where it stopped turned on the contact order of every body in the street, 0–11 timber broken;
  from 7 m it lands at the door, 21–23), `test_loads.gd` (+2: the street buildings stand, batching).
  Sign boards have their own mesh (a tall board's picture came out sideways). Judge round
  `2026-10-02_r1`: street 0.874 → 0.866 (saloon 0.866). 277 tests pass.
  - Known: the church at the end is still a blockout, and StreetScenery's pale hills show at the
    street's end; the livery's loft is empty (no hay); nobody's inside these buildings (no
    furniture); the DRY GOODS board is hidden from the shot by the saloon's front.
- 2026-10-02 (art session, later): **Look 2: surface detail.** The world's squares are the
  painting's size: **32 texels a metre** (was 64; `PixelArt.DENSITY_PRESETS` 32/24/16/64, F7;
  `Settings.LOOK_VERSION` 3 moves a saved 64 to 32 once; shared `settings.gd`, my lines). The
  factory's textures are re-cut at 32 (`materials.json` `texels_per_metre`, same planks and grain,
  chunkier squares) with a harder mosaic (`reduce.py` `MOSAIC` 2.0); signs too. Every member face
  draws a dark line along its edges (`texel_grid.gdshaderinc` `edge_shade` 0.7, ends 0.82): the
  line between boards the painting draws on every plank. The road (`ground.gdshader`): three wagon
  tracks, each groove two that drift apart and back, crisp dark bottoms and lit ridges, pebbles,
  a churned middle. Dry grass (`DryGrass`, ~5,000 tufts in one multimesh, no shadows, no
  collision). Judge rounds `2026-10-02_r2` (32 texels alone: street 0.805, saloon 0.890) and
  `_r3`: street 0.866 → **0.754**, saloon 0.866 → **0.849**. 278 tests pass (+1: the grass).
  - Known: the saloon's biggest gap is now its bar side (plain: the painting's bottles, lamps and
    people), and its left wall's yellow; the street's far right and middle are too bright (item 3,
    the light); the lantern light pools on the fronts are hard-edged discs (item 3).
- 2026-10-02 (art session, later): **Look 3: golden-hour light.** Gold, not purple. The purple had
  three causes: the shadows' ambient came from the blue sky, the fog mixed the sky's top into its
  colour, and the sky shader blended the warm horizon into the blue top (lavender), which ACES
  pushes further violet. Now `DayCycle` (gameplay's `day_cycle.gd`/`_config.gd`/
  `config/day_cycle.tres`, lighting lines only) works out `golden` (1 with the sun low, 0 high or at
  night) and with it: ambient cut to `ambient_low_sun` 0.3, half of it from the sky and half a warm
  colour (`ambient_warm_level` 0.45 of the horizon/sun gold), the haze's colour the low sun's gold
  at `fog_low_sun_level` 0.6, exposure down to `exposure_low_sun` 0.85; noon is unchanged. The
  gradients' late-afternoon top is a muted blue (morning too), the horizon and sun deeper gold.
  The sky (`sky.gdshader`) is in squares like the painting's (`sky_squares` 100 a radian, a shade
  per square), its far side a pale blue haze, the clouds orange-lit and dimmer when the sun's low.
  Wall lanterns cast no shadows (`OilLamp.casts_shadows`, gameplay's file: their own caps cut hard
  wedges out of the light on the fronts). The placeholder church is weathered wood (it was the
  palest thing on the street). Judge rounds `_r5` and `_r6`: street 0.754 → **0.654** (saloon
  0.852, unchanged: it's night). `_r4` is a scratch round from tuning, kept by the rule.
  - Known: dusk after sunset is still violet (that one's real); the painting's posts and roof edges
    have bright gold rims that ours only get where the sun truly hits; the sky's top right is
    still a little bright and yellow.
- 2026-10-02 (art session, later): **Look 4: people on the street and porches.** Eight stand-in
  townsfolk (`StreetDressing.FOLK`): `HumanBody`s with a `CivilianBrain` at a post, where the
  painting has them: a man in a coat on the saloon's porch, two sitting on a new porch bench, one
  at the general store, one on the jail's boardwalk, one walking down the middle of the street
  (stood, back to you) and two further down, all off the gang's way in along z -9. Like the
  storekeeper they put their hands up at a gun and get down at shooting. `CivilianBrain.rest_pose`
  (gameplay's file, one variable and two lines: a calm man at his post takes it, `sit` on the
  bench). Judge round `_r7`: street 0.654 → 0.646. 279 tests pass (+1 in `test_town_day`, gameplay's
  test file: they're at their posts, the bench pair sit, a shot near them and they get down); the
  street tests take ~40 s longer with eight more people.
  - Known: everyone still wears the painted outlaw's body and paint (step 4 of the art plan,
    image-to-3D, waits on `TRIPO_API_KEY`); nobody walks about (the "walker" stands); they don't
    sit on anything but the bench.
- 2026-10-02 (art session, later): **Look 5: the man's face, the lamp, bottle and cups.**
  `tools/paint/face_draw.py` draws his face over the finished head texture as a pixel artist would:
  open eyes texel by texel (a warm white either side of a dark iris looking at you, a glint, a
  heavy two-row upper lid, a lower lid), thick dark brows dropping at their outer ends, a heavy
  walrus moustache drooping past his mouth, firmer contrast (1.2) and the whole head's colour
  pushed from grey (1.25, the painting's lamplit orange). Eyes at `shapes.head.eyes` in
  `<id>_paint.json`; `finish.py` runs it last (by hand only on an undrawn texture: it draws over
  whatever's there). Re-import after (`godot --headless --import`) or the game shows the old PNG.
  The lamp (`PropModels.lamp`) is the painting's: a low wide foot of dark brass, a squat font, burner
  prongs, a tall teardrop chimney (`src/props/chimney_glass.gdshader`, per-lamp `glow`): orange glass
  in squares, near-white over the flame and a teardrop of flame where your line of sight passes
  near it. Two traps: ACES turns any bright orange cream (its channel mixing: pure green came out
  (147,245,82)), so the chimney's colours go through the tonemap's inverse (`src/render/aces.
  gdshaderinc`, moved out of `body_skin.gdshaderinc`, which includes it); and the room's haze lit by
  a flame centimetres away laid cream over the glass (`fog_disabled`). `OilLamp` (gameplay's file):
  nothing of the lamp shadows its own light (the font's shadow was a jagged black ring on the table),
  a teardrop flame, the chimney's glow follows `lit`; the shot's table lamp lights less haze (0.4).
  Pewter mugs with a banded foot, rolled rim, dark inside and a strap handle (manifest `tin_cup`
  0.11 m across now); bottle glass browner, labels aged dark and sized to the world's texels. Judge
  round `_r8`: saloon 0.848 → **0.763** (street 0.649). 279 tests pass.
  - Known: his head is turned and shaped unlike the painting's (the face lands a little off), his
    mouth reads as a smile; the lamp's foot catches too much of its own light; the ashtray's still a
    plain disc; the saloon's bar side is still plain (the judge's biggest left there).
- 2026-10-02 (art session, later): **Look 6: the gun and hand in the chunky style.** What's in your
  hands is on the texel grid at `GunParts.HELD_TEXELS_PER_METER` 160 (was 320: the street
  painting's revolver and hand are in squares ~10 screen pixels across), in `PixelArt.squares`
  (a few close shades, each texel its own, so every square is a shade off the next): worn steel,
  greyer and less metallic (it read black against the low sun), your hand (`GunParts.skin()`, now
  a grid material) and a brown coat sleeve with a cream cuff (`GunParts.held_cloth`; `cloth()`
  stays a StandardMaterial3D for people's bodies). `Layers.VIS_HELD` marks everything a
  `WeaponViewmodel` holds, and its warm `HeldFill` light reaches only that (the painting lights the
  gun's side with the sun behind it), scaled by daylight so it stays dark at night. Gameplay files
  touched (only session): `gun_parts.gd`, `weapon_viewmodel.gd`, `hand_model.gd`,
  `shotgun_viewmodel.gd`, `dynamite_viewmodel.gd`, `layers.gd`. Judge round `_r9`: flat (street
  0.653, saloon 0.765): the gun's a small part of the frame. 279 tests pass.
  - Known: the hip pose shows the gun from behind and above where the painting holds it forward
    and shows its side (a pose change is gameplay feel: not done); the hand is still blocks.
- 2026-10-02 (art session, later): **The painted backdrop** (Sean: replace the 3D mountains with a
  painted 360-degree backdrop in layers, lit to the time of day, the big spires at the end of the
  street). `Backdrop` above. People runs 14 and 15 (FLUX.2 [max], 16 panels, ~$1.20): the street-end
  far panel is the painting's skyline (a cathedral mass of fluted spires right, lower spires and a
  butte left); the model paints its rocks about twice the painting's size and ignores height limits
  (foothill panels came back with mesas to 90% of the picture, twice), so the cutter shows the far
  layer at 0.6 of its span and the mid at 0.8 (gaps the nearer layers fill), and keeps the near
  layer to a low band under a rolling hill line. The cathedral stands at bearings ~277-302, right
  of the sun at 17:36 (277) as the painting has it (`test_props`: the far land down the street
  stands 12-26 degrees). `Mountains` and `mountain.gdshader` are gone, and the texel grid's `HAZE`
  block with them; gameplay's `street_scenery.gd` lost its sphere hills (they stood in front of
  the backdrop; said here as it's their file). `StreetMatch.stage()` stills the townsfolk's brains
  for the picture (the gun at your hip was a gun on a man down the street: hands up, "Don't
  shoot!" in the shot). Judge round `2026-10-02_r10`: street 0.653 → 0.647 (a small share of the
  frame). 279 tests pass. Contact sheet `docs/screenshots/backdrop/cut_final.png`.
  - Known: the near ring is 260 m out and you can walk to it (the ground ends at 300 m); its panels
    meet with a visible change of colour in places; the model's foothill panels hold a road in the
    hidden bottom rows; the rims barely show against a bright sky right by the sun.
- 2026-10-02 (art session; features frozen, the only session): **The saloon room** (Sean's list,
  item 1). The shot's set moved up the room beside the bar (`ShotMatch.TABLE`; the man's fit
  holds), so the front door is on your left, the back bar and its mirror on the right and the
  balcony over the middle. Through the door the moonlit street: the moon on its own low arc
  (`moon_tilt_degrees` 78, so it's ~12° up over +Z around midnight, the shot's hour now 23:40), a
  new low false front across the street (`EatingHouse` in `StreetDressing.BUILDINGS`, furnished
  so its windows glow, porch lantern), the backdrop's 194° panels turned clear of the moon
  (`backdrop.json` shifts, re-cut). In the room: 12 more sconces, three lamps on the back bar,
  four hung on rods (no shadows), the bottle wall, mirrors to 2.95 m with a reflection probe, a
  card game in front of the door, two men at the bar and a barman, one on the balcony and one on
  the stair. Gameplay files touched (only session, so said here): `saloon_building.gd` (door
  1.5×3.2, no porch roof: it hid the sky in the doorway; the bar's front and ends dark trim, as
  the painting's), `day_cycle.gd`/`day_cycle_config.gd`/`config/day_cycle.tres` (the moon's arc;
  the old default, the sun's tilt, gives exactly the old moon), `tests/test_day_cycle.gd` (the
  moon at midnight is above 0.15, not 0.5). Judge rounds `2026-10-02_r11` (first pass, too bright)
  and `_r12`: saloon 0.763 → **0.581**.
  - Known: every night now has a low moon (long moonlit shadows, moonlight a little dimmer before
    and after midnight); the saloon has no porch lantern now; the near things' squares (bar front,
    table top) are about twice the painting's (item 3); the balcony man's head is out of frame.
- 2026-10-02 (art session, later): **His coat in finer squares, a stern mouth** (Sean's list, item
  2). The judge measured his coat's squares at ~15 px against the painting's ~8: cloth is now 160
  squares a metre (`finish.py` `SQUARES_PER_M_CLOTH`, was 80; hat and boots too), the raw bake 512
  texels a metre (`paint_bake.gd` `RAW_TEXELS_PER_M`, so a square is still ~3 raw texels). His
  mouth read as a grin (a bright lip band under the moustache between its dark ends):
  `face_draw.py` draws it shut, a straight dark line with its corners turned down, a muted lip and
  a calmer chin (`MOUTH_ROW` and friends). The pipeline ran here end to end: `align.py
  --source=tile` (mediapipe needs `libegl1` and `libgles2`), `paint_bake.gd bake` (~10 min), then
  `finish.py`. Face shape untouched. Judge round `2026-10-02_r13`: saloon 0.581 → **0.572** (the
  centre's tile-size gap is gone).
- 2026-10-02 (art session, later): **Chunky squares in the distance** (Sean's list, item 3). Three
  ways tried and judged on the street shot (rounds `2026-10-02_r14`-`_r19`, scratch, kept; picture
  `docs/screenshots/far_squares/trials.png`): baseline 0.641; A, a screen-space mosaic by depth
  (`DepthMosaic`, a full-screen quad: 5 px blocks of the finished frame) 0.745: soft blocks,
  smeared letters, edges blurred; B, the texture's mip of 2/4/8-texel squares at 4 and 6 px
  minimum 0.676/0.712: chunky but each square the average, so the mosaic went plain; **C, chosen**:
  the same squares, each the colour of one texel (`tile_square()` in `tiles.gdshaderinc`, used by
  `texel_grid` and `ground.gdshader`; board edge lines and the light follow the squares), at 4 px
  0.629 (6 px 0.644). Signs are left out (`fixed_squares`), so their lettering reads down the
  street. Round `_r20` (both views, the default on): street 0.641 → **0.619**, saloon 0.582 (0.572:
  its far wall goes chunkier). Shared files: `project.godot` (the `min_square_px` global, my
  lines), `tools/screenshots.gd` (`--min-square`, `--screen-squares`). 279 tests pass.
  - Known: squares jump in size in bands (2→4→8 texels) where the distance crosses a threshold
    (a visible step on a long wall seen end-on); people, the backdrop and the sky aren't on it
    (they have their own squares); no key to switch it in game yet (a Settings knob if Sean wants it).
- 2026-10-02 (art session, later): **The street's framing and clutter** (Sean's list, item 4). The
  street shot stands nearer the saloon's porch (`StreetMatch.FEET` (3, 0, -6), was (3, 0, -7.4))
  so its front and big board fill the left third; the placeholder church is gone (gameplay's
  `street_scenery.gd`: `_build_blockouts` removed, said here as it's their file); the street is
  crowded: rails with three horses nosed in before the saloon and the store and one at the jail,
  a buckboard by the jail, seven more barrels and eight crates on both boardwalks, six lettered
  boards hung under the porches end on to the street, the water tower moved to (-34, -24) so it
  stands over the south roofs on the right of the shot. All off the road's middle and the gang's
  way in. Judge rounds `2026-10-02_r21` (first framing, nearer and tilted up: 0.686) and `_r22`:
  street 0.619 → **0.667**: the framing is the painting's but the judge marks the bottom-left
  too dark (L* 16 vs 37): at 17:36 the sun runs along the porches, so the boardwalk under the
  saloon's porch roof is in shadow where the painting's is sunlit, and the top right is the
  bright sky (item 5). 279 tests pass.
  - Open with Sean: a sun a little further south at golden hour (DayCycle's tilt, gameplay's)
    would light the boardwalks as the painting's are.
- 2026-10-02 (art session, later): **The clouds** (Sean's list, item 5). They were big flat orange
  sheets cut in blocks on their own plane (`cloud_blocks`, gone). Now, like the painting's, loose
  bands of small ragged heaps with blue between (the noise stretched across the street, warped,
  its edges eaten by a finer noise; `cloud_scale` 2.6, `cloud_cover` 0.46), each in three painted
  tones: a cream-gold top (the edge toward the zenith), a warm body, a grey-violet underside (the
  edge toward the horizon), golder on the sun's side; drawn in the sky's own squares. Judge rounds
  `2026-10-02_r23` (sheets of small heaps: 0.648), `_r24` (warmer) and `_r25` (both views): street
  0.667 → **0.645**, saloon 0.570 (moonlit clouds round the moon in the doorway). 279 tests pass.
  - Known: the sky's top is still bluer than the painting's (b* +5 vs +16; the day cycle's sky
    gradient, not the clouds); clouds don't drift into new shapes (they slide with TIME).
- 2026-10-02 (art session, later): **Ready for tonight's keys: fal style training, Tripo dry run.**
  `tools/style/train_style.py` (above; 48 crops from the three concept paintings until Sean adds
  pictures to `docs/concept/style/`); the People workflow's 10 inputs are GitHub's limit, so the
  boolean `style_test` became `style` (`photo` = the old style test, `train` = the fal training).
  `tools/characters/tripo.py --dry-run` passes against the stand-in Tripo (upload, image_to_model,
  three polls, download, animate_rig, three polls, download, the log); the characters job runs it,
  then `--balance` when the secret's there, then the real thing. Both untested against the live
  APIs: every answer is printed and saved, so the first runs show what to change.
  - Tonight: add repo secrets `FAL_KEY` and `TRIPO_API_KEY`; run People with `characters:
    stranger` (Tripo), and with `style: train` once `docs/concept/style/` has pictures.
- 2026-10-02 (art session, later): **The art review, and §10.1: the saloon's light and grade.**
  `docs/ART_REVIEW.md` (a fresh session's review, merged as PR #49) found the squares aren't the
  problem any more: the paintings are cinematic pictures with a mosaic over them, and ours were
  flat, noisy and chunky far off. Sean approved reopening DESIGN.md §4 (rewritten to the
  review's reading), the sun change and native resolution; the work now follows the review's
  §10 order. Step 1, the saloon: night ambient 2.5 → 0.7 and the saloon's own fill 0.1 → 0.035,
  night exposure 0.72 (`exposure_night`), bloom only off true emitters (chimney glass drawn to
  4× white round the flame, the moon 2.5; glow screen-blended, threshold 1.7, `glow_bloom` 0: at
  0.15 it veiled the whole frame, median L* 23), saturation 1.12, the bar side's lamps ×1.5 so the
  back bar glows. The review's numbers on the saloon shot: median L* 15 → **12** (painting 12),
  deep-shadow share 28 % → **40 %** (41 %), L95 56 → 48 (43), highlights 0.9 % (0.6 %), chroma 20.3
  (22.7). Gameplay files touched (lighting lines only, the only session): `scenes/test_street.tscn`
  (glow, saturation), `config/day_cycle.tres`, `day_cycle_config.gd`, `day_cycle.gd`
  (`exposure_night`), `saloon_building.gd` (`night_ambient`). Shared: `DESIGN.md` §4. Judge round
  `2026-10-02_r26` kept for the record (the old score punishes this, as the review predicted).
  - Known: the painted man is still self-lit (`paint_look`), so he doesn't sink into the dark the
    way the far room does (§10.7); the halo round the lamp is modest (the flame material is
    emission 5 but mostly hidden by the glass); the street gets the saturation and glow too,
    judged in §10.2.
- 2026-10-02 (art session, later): **§10.2: the street's light and grade.** The sun now sets a little
  south of west (`DayCycleConfig.sun_azimuth_degrees` 20, new: the arc turned round the vertical;
  at 17:36 the sun stands at bearing 257, 7° left of the street shot's look, where the painting
  has it, so the north side's porches and boardwalks are sunlit; the review's tilt experiment went
  the wrong way, and tilt alone can't move a 9.5° sun that far). Haze down the street
  (`fog_density` 0.0035 → 0.008, the scene's `fog_aerial_perspective` 0.25 → 0.7, the haze's gold
  `fog_low_sun_level` 0.8), contrast 1.15, more warm bounce in the shadows (`ambient_low_sun` 0.6),
  exposure 0.85 as it was. The sky was the blown part (the horizon band and the cloud tones, not
  the blue): `sky.gdshader` dims the horizon band 30 % away from a low sun, the near-sun glow a
  little, the clouds to 0.78 at low sun and their gold deeper; `low_sun_dim` 0.65. The road: the
  factory's `road` material gets `lightness` 1.3 (re-cut, no new painting) and the ruts' darkening
  is softened (`ground.gdshader` groove 0.5, churn 0.2: the painting's are lighter). The review's
  numbers on the street shot, sky band / whole frame: sky median L* 47 → **41** (painting 40), sky
  L95 84 → **79** (78), blown share 9.8 % → **2.2 %** (1.6 %), chroma–L* correlation 0.12 → 0.3
  (0.56: the pale lavender sky still drags it; §10.4). The road reads brighter and evener but the
  frame's lower band is still darker than the painting's (its road is a pale dust; §10.6). Gameplay
  files touched, lighting lines only: `scenes/test_street.tscn` (aerial perspective, contrast),
  `config/day_cycle.tres`, `day_cycle_config.gd`, `day_cycle.gd` (`sun_azimuth_degrees`). Judge
  round `2026-10-02_r27`.
  - Known: sunrise is now 20° north of east too (one azimuth for the whole arc); the far street
    greys a little under the haze where the painting's is golden dust (the fog's colour is one
    gold; a painted sky and backdrop haze come in §10.4).
- 2026-10-02 (art session, later): **§10.3: judge v2.** `tools/judge.py` scores style, not
  composition (above): the 3×3 region means and the mosaic/tile measures that rewarded random
  block noise and punished the light pass are gone from the score. `--probes` is the test the
  review asked for (§5): the painting 0.000, shifted 60 px 0.003; round 25 + block noise, pixel
  noise, blur and greyscale all worse than round 25; a grade toward the painting's light better;
  and the engine's own light pass (round 27 vs 25) better: saloon 0.338 → 0.209, street 0.571 →
  0.344. First v2 round `2026-10-02_r28` (round 27's renders rescored); `history.md` starts a
  v2 table there. Not done from the review's list: a repetition measure (needs a known wall
  region) and block size against the depth buffer (bands stand in).
- 2026-10-02 (art session, later): **§10.4: sky and far field.** The sky is smooth (`sky_squares`
  0, `sky_mosaic` 0) with soft-edged clouds shaded smoothly (`cloud_tones` 0), dimmer at low sun
  with a deeper gold; its late-afternoon top is a paler, lighter grey-blue (`day_cycle.tres`
  gradient at 0.7/0.755; `low_sun_dim` 0.45: the painting's upper sky between clouds is L* 61,
  ours was 44, now 55). The backdrop is re-cut at 0.15° a texel (2400×258) with 40/36/32 colours
  and a faint mosaic (`MOSAIC` 0.6), and its haze follows the fog's density (`haze_scale`).
  `min_square_px` 4 → **2** (0 was tried, round `_r29`: the road at 15–30 m went finer than the
  painting's blocks; the review's far men are 2–3 px blocks still). Judge v2 rounds `_r29`–`_r32`:
  street 0.344 → 0.375 (the paler sky lowers the chroma–L* correlation the judge weighs most; by
  eye the sky is the painting's for the first time: `docs/screenshots/light_pass/
  sky_before_after.png`), saloon 0.209 → 0.218. Shared files: `project.godot` (`min_square_px`),
  gameplay's `config/day_cycle.tres` (the sky gradient, lighting lines).
  - Not done: a painted cloud layer on a dome (image model on Actions, or Blockade once its key
    is in: a `backdrop: sky` input is the natural place); the backdrop's panel seams still show.
- 2026-10-02 (art session, later): **§10.5: the factory's reducer v2 and per-board strips**
  (docs/ART_REVIEW.md §8.3). The reducer kept flattening the paintings to one even board and
  pushing a mosaic into them (the review's root cause 3: grain as noise): now `FLATTEN` 0.3 keeps
  the painted light and each board's own colour, `MOSAIC` 1.0 pushes nothing, 28 colours a
  material (the road 32; was 16–20), all 15 materials and the signs re-cut from the same paintings
  (`docs/screenshots/textures/reducer_v2.png`, judge round `_r33`: saloon 0.220, street 0.361).
  Then the boards: the paintings already draw six or seven boards each, so `reduce.py` cuts every
  one out as its own strip (`board_strips`, 40 strips over seven woods) and `WoodMaterials` hands
  each member one by its ID with its own start along the grain (the old tint-and-shift variants
  stay for woods without strips: framing, dark trim, stone). A wall is now a stack of different
  boards, as the paintings' are (`board_strips.png`). Judge round `_r34`: saloon 0.218, street
  0.346 (from 0.361). No new paintings needed (nothing ran on Actions). Gameplay's
  `tests/test_loads.gd` touched (one line): a structure batches one mesh per material, and a wood
  now has up to seven, so the store's limit is 32 meshes (was 20; it draws in 22). 279 tests pass.
  - Known: a strip is one board high at 32 texels/m (6–7 texels), so a wide member (a door, a
    tabletop) shows it repeated in rows; the sign boards' lettering still sits on the old-style
    tile (`SignArt`); the saloon wall's strips are dark on dark (the painting's).
- 2026-10-02 (art session, later): **§10.6: the ground and the table top.** The reducer grades in
  Lab with four knobs now (`grade`: lightness, contrast, chroma, hue). The shot table takes
  contrast 2.6, chroma 1.6, hue −12: the painting's table is bold dark grain on deep warm
  red-brown, ours was dead flat (L* sd 2.4 to its 15); judge round `_r35`: saloon 0.218 → 0.211.
  The street is one painted 8 m tile (`road_wide`, People run 16, ~$0.10: FLUX painted the ruts
  straight down it, a crossing track, stones, hoof marks and grass; the grass tufts go to brown
  blobs at 32 texels/m) laid along the street by `ground.gdshader` (above), and the ground gets
  its own light: with the tile in and the sun at 15°, the road drew at L* 18–27 to the painting's
  50 (rounds `_r37`–`_r39`), lighter tiles couldn't reach it (albedo), a wrapped sun blew the
  sunlit side out (`_r40`–`_r42`), a strong fill too (`_r43`), so it's a share of the sun's light
  unshadowed and half way to grey (`sky_fill`) with the direct part eased (`sun_direct`): rounds
  `_r44`–`_r47`, street 0.346 → **0.318** (road band L* 47, hue 55°, to the painting's 50, 57°). The sunlit right side's
  ground is still twice as bright as the painting's (ours is lit by the sun left of the axis; the
  painting's right side is in shadow: the §10.2 sun stays). Figure
  `docs/screenshots/light_pass/ground_table_before_after.png`. 279 tests pass.
  - Known: the 8 m tile's crossing track repeats as a dark band across the street every 8 m
    (mirroring hides the seam, not the band); a 2 m-wide sheet of the 2 m tile still shows at the
    road's edges where the wide tile's patches end; the table's grain is blotches at 32 texels/m,
    not the painting's lines (a finer table tile is a prop-texture question, §10.8).
- 2026-10-02 (art session, later): **§10.7: the seated man by the hybrid route; the townsfolk
  their own men.** `finish.py` `HYBRID` (above): his textures from the model's flat-lit sheets
  alone, average squares, 8–32 colours a shape; `body_skin` lights painted parts like everything
  else (`paint_ambient`, no self-lit share, no steps). Lit by the scene at paint_gain 1 he went
  near black (round `_r48`: saloon 0.247); at 2.2 (the model paints him in even mid light, the
  lamp has to bring him to the painting's) `_r49`: saloon 0.211 → **0.205**, the face smoother and
  a lit portrait rather than a copy of the painting's blocks, brows and moustache bold
  (`face_draw`). `HumanBody.use_paint` off for `StreetDressing.FOLK` and `ShotMatch.EXTRAS`: the
  generated body in code-painted cloth of each man's own colours (FOLK/EXTRAS had them all along;
  the paint overrode them) with his own code-painted face (`look`), so the porch, the card game
  and the bar are different men (street `_r48` 0.323; a "cravat" cloth added so the tie isn't
  skin). Figure `docs/screenshots/light_pass/man_hybrid.png`. No bake needed (the raw bake's
  views are reused). 279 tests pass.
  - Known: his face is still smoother and more orange than the painting's, and his coat one flat
    brown under one light (the review's "one strong warm key and a dim cool fill" is the shot's
    lighting, not done); the code-painted faces are cruder than his (image-model portraits per
    man would be the People workflow's `only` input, one call each); hats are one shape.
- 2026-10-02 (art session, later): **§10.8: props with form, in code.** No image-to-3D key and no
  Blender in this workspace, so the two big placeholders in the street shot are modelled in code
  on a new `PropModels.loft()` (above): the horse (the painting's horses have form; ours were
  boxes) and the hay bale. Two traps on the way: a ring's tilt must be square to the path (the
  neck's rings leaned the wrong way and drew as a blade), and `_arc` spans are radians (the first
  blanket was a strip). Judge round `_r50`: street 0.323 → 0.319 (the horses are a small share of
  the frame; by eye they read as horses now). Figure `docs/screenshots/props/horse_hay.png`.
  279 tests pass.
  - Known: the mane is a plain dark fin; no reins to the rail; one horse colour (a bay: a
    `variant` for a grey and a chestnut is a few lines); the stag, chairs, barrels and bottles
    were already shaped (hoops, labels, spindles, antlers) and are left; image-to-3D props wait
    on a key (`MESHY_API_KEY` or `TRIPO_API_KEY`).
- 2026-10-02 (art session, later): **§10.10: native by default, the finish pass.** Sean approved
  native: `Settings.RESOLUTION_PRESETS` starts at `NATIVE` (`LOOK_VERSION` 4 moves a saved
  1280×720 there once). The finish (above): block edges softened by about a render pixel in the
  screen pass, and a faint gradient of the real lighting across each tile (`tile_gradient`:
  LIGHT_VERTEX pulled 0.3 of the way back from the tile's centre). Judged at the 1280×720 window
  (`_r51` on, `_r52` off): saloon 0.208 / 0.206, street 0.328 / 0.321, within the review's noise
  band, so the pick is by eye (`docs/screenshots/light_pass/finish_on_off.png`: softer block
  edges on the face, the lamp's falloff across the table's squares); kept on. Shared files:
  `project.godot` (`tile_gradient` global), `settings.gd` (my lines). Gameplay files touched
  (one line each, said here): `src/main/main.gd` (`finish_soften` to the screen shader),
  `tests/test_project.gd` (the default is native: the tests check against the window's size,
  and F2's first stop). 279 tests pass.
  - §10.9 (the first Tripo man) waits on `TRIPO_API_KEY`: the People workflow's `characters`
    input dry-runs the client, then calls the live API when the secret is there.
  - Known: at native the far street's squares follow `min_square_px` 2 as before; the finish's
    soften looks for jumps in the rendered frame, so a lamp's hard-edged halo softens too; no
    key for the finish yet (F3 lists it).
- 2026-10-02 (art session, later): **§10.9, round 1: the first Tripo man, judged in the lab.**
  `TRIPO_API_KEY` is in: People run 17 (`characters: stranger`) painted him full length (FLUX:
  the painting's man in an A-pose, already in blocks) and the live Tripo API answered first time:
  `assets/people/tripo/stranger.glb` (rigged: 41 joints, Hip/Spine/Head/L_R Upperarm/Forearm/
  Hand/Thigh/Calf/Foot with twist bones), `stranger_mesh.glb`, 390k triangles, 2K colour, normal
  and ORM maps (31 MB in git, committed by the workflow). `tools/tripo_lab.gd` (above) stands him
  at the table: `docs/screenshots/tripo/stranger_lab.png`. He reads as the painting's man (hat
  with its studded band, long hair, the moustache, white collar and dark tie, patterned vest,
  frock coat, cartridge belt) and his face is a smooth-shaded portrait rather than blocks; the
  textures carry the model's own baked light (a de-lighting step is needed, as the review said),
  and up close his face is smeared where the one painted view saw it obliquely (the moustache's
  underside, the hat band's studs: a head sheet or Tripo's multi-view input would mend it). No
  bake, no Blender fit yet: he stands in the A-pose through the table.
  - Next (docs/ART_REVIEW.md §6, 2–3 sessions): the Blender fit (his rig onto our 17 segments and
    hitboxes, the same warp/envelope/cut as MakeHuman's), decimate 390k → ~7k, de-light and
    reduce his textures through the factory's reducer, our hands; then the paint bake's squares
    or the hybrid finish on him, and the seat pose. No Blender in this workspace: the fit runs on
    Actions (People workflow) like `make_people.py`.
- 2026-10-02 (art session, later): **The style LoRA, trained and sampled.** Sean: "should we try
  using Tripo to train on the concept art?" Tripo can't train (it reconstructs whatever picture
  it's handed); the style belongs in the image model, and `FAL_KEY` was in: People run 18 trained
  the LoRA on fal first time (48 crops of the three paintings, 1000 steps, five minutes;
  `tools/style/style_lora.json`, the weights on fal). Run 19 sampled it (`sample_style.py`,
  above): `docs/style_test/lora/sheet.png`. It learned the paintings well: the saloon and street
  samples have their lamplight, golden haze, composition and mosaic, and the full-length gunman
  and the portrait come out in the same blocks. Two things to know before using it: it paints the
  blocks too (the review wants Tripo's input clean, with the squares made last by our reducer or
  finish: for Tripo prompt it for the drawing and light, not the mosaic, or sample at a lower
  LoRA scale), and on three paintings it will repeat their compositions (more pictures in
  `docs/concept/style/` would loosen it). fal's `flux-lora` takes no reference image, so the
  guided turnarounds would go through its image-to-image endpoint from our grey guides.
  - Next: route `paint_full_length.py` and the turnaround sheets through fal with the LoRA
    (image-to-image from the guides), give Tripo a multi-view sheet, and the Blender fit.
- 2026-10-02 (gameplay): **Performance pass, part 1: measured, then fire.** Sean: CPU-bound on one
  core (cloud PC, 3.25 GHz). `tools/perf_bench.gd` (main scene, gang in, player at (11,0,−9) looking
  down the street): scene `calm`, and `fire` (two 0.2 kg blasts, 4 members lit in each of three
  buildings, three shots); wall-clock avg/p99/max, a census, and ablation (each system's process or
  physics off for 5 s vs a fresh baseline); `--render` under xvfb adds draw calls/objects;
  `--quick` 8 s, `--no-ablate`, `--out=json`. Godot's TIME_PROCESS/PHYSICS monitors read nonsense
  headless (unpaced loop), so the bench doesn't use them. **Before** (2.1 GHz Xeon, headless): calm
  4.8 ms avg, p99 9.5; fire 17.4 ms, p99 307, max 520. Census: 14 people, 6,131 members, 10.2k meshes
  (3.7k visible), 6.6k static bodies, 58 lights (20 shadowed), ~25k nodes. Draws (opengl3 under
  xvfb, counts only; this container has no Vulkan): **calm 8,212 draw calls**, 9.9k objects in
  frame, 1.27M primitives; hiding the people saves 4.2k draws, props/lamps/dressing 4.0k, the sun's
  shadow 5.6k (its cascades re-draw everything), lamp shadows 0.35k. Ablation, calm: HumanBody
  physics 1.55 ms, Senses 0.51, Player 0.45, debug overlay 0.35, DayCycle 0.32, rest < 0.1. Fire:
  FireSystem ~38 ms of every frame on average. **Top five:** 1) draw calls: the sun's shadow
  cascades over everything; 2) people, ~95 draws each; 3) props/lamps/dressing; 4) FireSystem;
  5) HumanBody physiology/pose. **Fix 1, fire:** a burning member no longer heats neighbours already
  burning or burnt away (their temperature isn't read beyond ≥650 °C or saved; pruned from its
  cached list, since neither goes back): pair visits per tick ~66k → a few thousand; scorching
  measures each burning member's box once a tick (not once per person) with a native AABB reject;
  `StructureMember.world_aabb()` and FireFX check a piece is valid before casting (a burnt-away
  piece spammed "Trying to cast a freed object"). Same result: every live member's state identical
  after 240 ticks on the street, old vs new. **After:** fire 11.5 ms avg, p99 163 (calm unchanged).
  279 tests pass.
  - Next: spread the fire tick over the frames between ticks (the p99 is one 80 ms tick), settle
    (StructuralAnalysis) only on change, then the draws (sun shadow distance/cascades, people
    merged into a few skinned meshes, props batched), the F3 split and a CI budget.
- 2026-10-02 (gameplay, later): **Performance pass, part 2: the fire's hitch.** `FireSystem.step()`
  is now `_begin` (grid, spills) / `_visit(keys, from, to)` / `_finish` (drop, scorch, settle);
  `step()` still runs all three at once (tests, screenshots), but `_physics_process` spreads a
  tick's members over the frames until the next tick in the same order (a long frame finishes the
  tick at once), and burning buildings settle one a frame (`_to_settle`). `_consume` asks
  `Structure.settle_soon()` (new, public: deferred, once a frame however many ask) instead of
  `settle.call_deferred()` per board (20 boards gone in a tick = 20 full analyses). The grid places
  standing members once (`_placed`) and only rubble afresh every 2 s. Bench, fire (2.1 GHz,
  headless): avg 11.5 → 11.6 ms, **p99 163 → 73 ms, max 390 → 100 ms**. What's left of the
  worst frames: `Structure.settle()` (StructuralAnalysis), ~29 ms a call on average, up to 73
  (126 calls in 35 s of fire); `_update_fx` ~11 ms every 0.5 s; grid ~14 ms every 2 s. 279 pass.
  - Next: settle only on change / cheaper analysis.
- 2026-10-02 (art session, later): **§10.9, round 2: the man painted clean on fal, Tripo from four
  views.** Sean: "Alright!" to using the LoRA for the full-length man and the turnarounds.
  `paint_full_length.py`'s fal route (above): FLUX Kontext with the style LoRA redraws him from
  the first full-length painting with its mosaic smoothed away, then paints his left, back and
  right from that front (People runs 20 and 21, four edits each, ~$0.15; `fal-ai/flux-kontext-lora`
  answered first time). At LoRA scale 0.5 (run 20) the coat's front came back in check blocks
  while the back was plain wool; at 0.25 (run 21, kept) he's smooth all round, the same man in
  every view, the hat's studs and the vest's pattern softer than the first painting's
  (`docs/screenshots/tripo/stranger_turn_run20_scale050.png`, `_run21_scale025.png`). Tripo's
  `multiview_to_model` (run 22, model v2.5) took the four and `animate_rig` rigged it: 348k
  triangles, 16 MB (half of run 17's), his back and sides as drawn (hair on the collar, a plain
  coat), no mosaic baked into his clothes, textures lighter and evener; the face a smooth
  portrait (`stranger_lab.png`; run 17's is `stranger_lab_run17.png`). `tripo.py` keeps a hash of
  each picture in `<id>_tripo.json` and models again when they change. People workflow: `style:
  characters` paints only; `characters:` paints then Tripo. 279 tests pass.
  - Known: still the A-pose through the table (no Blender fit yet); his face is a little
    doll-like (round cheeks, small eyes: Kontext's redraw softened the first painting's face;
    a head-sheet pass or `--from=painting` for the face would sharpen it); the LoRA's part at
    0.25 is modest (period detail, palette); the model's textures still carry baked light.
  - Next (docs/ART_REVIEW.md §6): the Blender fit on Actions (Tripo's 41-joint rig onto our 17
    segments and hitboxes, the same warp/envelope/cut as MakeHuman's, decimate to ~7k, our
    hands), de-light and reduce his textures through the factory's reducer, the seat pose.
- 2026-10-02 (gameplay, later): **Performance pass, part 3: the load check.** `StructuralAnalysis`
  costs ~44 µs a member (the street's ~6.1k members: 270 ms a full pass, the saloon 54 ms), and a
  burning building runs one a second. Ablation of its parts: handing each support's reaction back
  down 100 ms (a quadratic search for its group: siding on ten studs has ~20 contact points),
  grouping supports 60, outside `_bend` 60, capacity 35, `beam()` 13. Now: what doesn't change
  while a member stands (axis, length, where along it each support bears, a rafter's partners,
  and its support groups while none is gone) is kept on it (`StructureMember.analysis_cache`, not
  saved; checked against its transform and size, cleared by `infer_supports`); the reaction walks
  the sorted groups once (they're ≥ SAME_SUPPORT apart, so at most one matches); no lambda in
  `beam()`'s inner loop. Street pass 270 → 190 ms; identical results (every load, utilisation,
  mode, critical point and falling list, old vs new, 84 states; test
  `test_loads::test_what_the_analysis_keeps_gives_the_same_answer`). Bench fire (2.1 GHz): avg
  11.6 → 10.8 ms, **p99 73 → 53, max 100 → 70**. 280 pass.
  - Further would need native code (ask first) or spreading the analysis over frames; the draws
    are bigger for Sean now.
- 2026-10-02 (gameplay, later): **Performance pass, part 4: people drawn whole.** Census: 14
  people, ~55 skin/clothes pieces each (a shape per segment, for openings) + 30 finger meshes =
  1,375 visible meshes; hiding the people saved 4,158 of the street's 8,212 draw calls (opengl3
  under xvfb: counts only). `HumanBody._merge_pieces()`: each shape but the head (its wet eyes are
  placed in the head piece's own space) is joined into one skinned mesh (`_joined`: the pieces'
  surfaces concatenated, same format, skin and material), the pieces hidden; `_unmerge()` brings
  them back for good at the first opening (`_apply_openings`) or lost limb
  (`_stop_skinning_across_joints`); X-ray reaches both. `skin_meshes`/`segment_pieces`/
  `body_meshes()` are unchanged (the art tools read and duplicate the pieces; paint_bake does the
  same as before). Pixel check: a coated man standing and hands up, four views, old vs new with
  `--fixed-fps 60`: 2–5 pixels of 640k differ by 1/255, with and without shadows. People meshes
  1,375 → 747; **calm draw calls 8,186 → 6,129**, objects in frame 9,884 → 7,827; headless calm
  4.9 → 4.4 ms. Test `test_openings::test_whole_each_shape_draws_once_and_opening_brings_back_the_
  pieces`. 281 pass.
  - Next: props/lamps/dressing batched (~4k draws), the sun's cascades (~5.6k with everything
    drawn in each), fingers (~420 meshes).
- 2026-10-03 (gameplay): **Performance pass, part 5: the dressing batched.** `StaticBatch`
  (`src/world/static_batch.gd`, a node at the end of `scenes/test_street.tscn`): two frames after
  load it takes every MeshInstance3D under the street that can't change (opaque `texel_grid` or
  opaque StandardMaterial3D, not skinned, no script on the way up but `OWNERS` (StreetDressing,
  StreetScenery, Saloon/FalseFrontBuilding, SaloonDressing, Structure), no physics body but a
  static one, not a building's direct child (its batches and boards) nor inside a member), groups
  them by mesh content (each chair builds its own legs), material, shadow, layers and a 40 m cell,
  and draws each group as a MultiMesh at their own transforms (mesh-space triplanar stays put),
  hiding the parts (collision stays). A part leaving the tree stops drawing (the shot match frees
  the table's props); `release(node)` / `StaticBatch.release_in(tree, node)` gives a subtree back.
  **Art session: dressing (StreetDressing, SaloonDressing, PropLibrary/PropModels props) is drawn by
  the batch after load: anything that moves or hides it at run time calls `release_in` first.**
  Off on the Compatibility renderer (web): it lights each object from a short list of 8, so a batch
  spanning a room got different lamps (the saloon's card table lit where it was dark). Lavapipe is
  installable here now (`apt-get install mesa-vulkan-drivers`): Forward+ renders, old vs new at
  `--fixed-fps 60`: street 0 px differ, saloon night 40 px and the shot match 11k px all under 8/255.
  1,767 meshes into 180 batches, ~55 ms at load. Forward+ (lavapipe) calm: draw calls 4,047 →
  3,695 (Forward+ already merges repeated draws; OpenGL counted 6,129 → 3,723), objects in frame
  7,810 → 5,413, render CPU 5.4 → 4.9 ms. Test `test_static_batch` (2). 283 pass.
  - Can't reproduce Sean's pinned core here: headless sim ~4.4 ms + render CPU ~5 ms a frame at
    2.1 GHz. Next: F3's frame split and draw calls so Sean can report his, then by his numbers.
- 2026-10-03 (gameplay, later): **Performance pass, part 6: F3's frame split, timers, a guard.**
  `Prof` (`src/debug/prof.gd`): each system's frame entry is timed while `Prof.on` (F3 open, or
  the bench): `_process`/`_physics_process` in HumanBody (people_skeleton / people_body),
  OutlawBrain, CivilianBrain, Senses, FireSystem, Ballistics, Structure, DayCycle, OilLamp
  (lamps), Player + PlayerWounds (player), BloodJet, GunSmoke, TownLife, DynamiteStick now call
  `_process_step`/`_physics_step` between `Prof.start()`/`stop()` (one call returning 0 when off).
  F3 (`DebugOverlay.frame_lines()`): frame ms with process / physics (`Performance` TIME_*) /
  render CPU / GPU (every viewport's measured render time, switched on with the readout), draws,
  objects, tris, nodes, awake bodies, and the top eight systems in ms a frame. `perf_bench.gd`
  prints the same "timed" line. Bench now (2.1 GHz, headless): calm 4.9 ms (people_body 1.81,
  player 0.61, senses 0.47, outlaw_brain 0.34, people_skeleton 0.20); fire 8.8 ms, p99 62
  (fire 2.83, people_body 2.13). `tests/test_perf.gd` (2): the calm street's visible meshes ≤
  1,800 (1,291; was 3,686), meshes on one person ≤ 95 (89: an armed man's revolver is 45 parts),
  nodes ≤ 30k, calm ≤ 16 ms a frame; three buildings burning ≤ 30 ms a frame, worst ≤ 250 ms
  (budgets ~3x this machine for CI runners). 285 pass.
  - Next: Sean's F3 readouts decide (this machine can't show his pinned core: ~10 ms a frame
    here with render CPU). Candidates ready: an NPC's holstered revolver as one mesh (45 → 1–3),
    fingers skinned to the body (30 → 0 extra), the sun's shadow cascades, people ticking less
    far off.
- 2026-10-03 (gameplay, later): **Performance pass, part 7: muscles listed once.** With Prof's
  timers inside `HumanBody._physics_step`: pose 0.89 ms, physiology's step 0.07, and the stand
  check (`can_stand()`/`_can_crawl()`) 0.94: `Physiology.muscle_strength()` scanned all 115
  anatomy structures with string building and `ends_with` on every call, twice per stand check,
  and walking, gait, aiming, `can_hold()` and the player's wounds all ask it. Now
  `Physiology._muscles(group, side)` lists each group's muscles once per anatomy (static
  `_muscle_lists`, same order, so the same sums). Bench (2.1 GHz, headless): calm **5.4 → 3.8 ms**
  (people_body 2.0 → 1.2, player 0.68 → 0.18, outlaw_brain 0.38 → 0.21); fire **7.8 → 6.8 ms**,
  p99 54 (fire 2.5, people_body 2.0 → 1.3). Tried and dropped: skipping pivot rotations that
  hadn't changed (no gain: an unchanged set is cheap). 285 pass.
- 2026-10-03 (art session): **His head in the style, on the Tripo man.** Sean, on the LoRA's pixel
  portrait against the smooth Tripo face: "what happened between that awesome pixel face and this
  smoothed out shit?" The smoothing was for Tripo (its input has to be clean, and Kontext at a
  low LoRA scale threw the drawing away with the blocks); the drawing goes back on afterwards.
  `head_paint.py` (above). People run 23 (FLUX Kontext + the LoRA at 1.0 from grey clay views):
  a smooth, bearded, front-facing oil portrait in every cell, the view ignored. Run 24 (FLUX dev
  image-to-image + the LoRA at 1.0, strength 0.68, from the head rendered in Tripo's own
  colours): the pixel-art man in all six views, turned as the render is, brows, moustache, hat
  band and hair in crisp squares (`docs/screenshots/tripo/stranger_head_views.png`; six edits,
  ~$0.20). Baked onto his texture (715 texels a metre on the head, squares of 4 texels) and
  rendered in the lab: `stranger_head.png` (his head beside the painting's man's) and
  `stranger_lab.png`. The lab lays `<id>_color.png` over his material. 279 tests pass.
  - Known: the paintings carry their own lamplight and the game lights him again, so his lit
    cheek runs hot (de-lighting is the Blender-fit session's, as for the body); the LoRA gives
    him a beard in the side views (the painting's man has stubble); the body is still Tripo's
    smooth colour (the body sheets could go through the same image-to-image pass at full scale
    once the fit's done); still the A-pose through the table.
  - Next (docs/ART_REVIEW.md §6): the Blender fit on Actions (Tripo's 41-joint rig onto our 17
    segments and hitboxes, the same warp/envelope/cut as MakeHuman's, decimate to ~7k, our
    hands), de-light and reduce his textures, the seat pose; then the body painted the same way.
- 2026-10-03 (gameplay, later): **Performance pass, part 8: a whole town on fire.** Sean: "very
  jittery" and flickering light everywhere with "multiple fires and destruction". The bench had
  only measured the first half-minute of fire; left to spread, it takes every building in a
  minute (2,600 members burning), and then: deferred `settle()`s ran a building's full analysis
  every frame a board burnt away, a big collapse ran 46–53 rounds (a full analysis each) in one
  frame (1.1–1.6 s), `_update_fx` sorted thousands of members with a script lambda and refreshed
  every FireFX on one frame, each unbatch rebuilt that material's whole batch, scorching measured
  every burning member's box for each person, the grid re-placed all rubble every 2 s, and
  `_consume` hit "assign previously freed instance" (typed loop over freed pieces). Now:
  `StructuralAnalysis.begin()`/`advance(n)`/`left()` (analyse() = begin + advance all; same
  results); `Structure.apply_round(a)` is one settle round (settle() loops it); `FireSystem`
  checks burning buildings a slice a frame (`CHECK_MEMBERS` 120; a request from `settle_soon()` or
  a burnt-away board is urgent, `SETTLE_MEMBERS` 400 a frame) and only if something's overloaded or
  falling applies a round and analyses again; `Structure.settle_soon()` goes through
  `FireSystem.queue_settle()` when the world has one (tests without one keep the deferred full
  settle; `break_member(s)` still settle at once). `Structure.by_stack()` keeps the stack order
  (sorted once; the analysis walks it backwards: ties at the same height may sum loads in a
  different order, last-digit float differences). FireFX: flames chosen every 0.5 s with
  hysteresis (a burning member keeps its flame; free ones go to the burning nearest the camera,
  `PackedVector2Array` native sort) and refreshed a slice a frame (`_refresh_fx`); the six fire
  lights keep to their own fires (nearest new spot within 3.5 m). `Structure.unbatch(m, soon)`:
  the fire's unbatches rebuild a batch at most every 0.5 s (`BATCH_REBUILD_GAP`), the member shown
  then (no double draw); holes and breaks still rebuild at once. Scorch asks the fire grid for
  members near each person; standing members' boxes are kept (`_box`); rubble lying still keeps its
  grid cells (`_lying_still`). `perf_bench.gd --scene=blaze` (45 s of spread, then measured):
  **avg 29.3 → 17.7 ms, p99 114 → 44, max 1,642 → 68** (2.1 GHz, headless). 285 pass.
  - Still to look at: a ~90 ms frame when a big building's rubble lands (untimed: the physics
    engine); the fire's per-member tick (~6 ms a frame at town scale); rendering a town's worth of
    FireFX particles and char overlays (Sean's GPU/CPU, unknown until his F3).
- 2026-10-03 (art session, later): **The Tripo man fitted to our skeleton: he sits at the table.**
  Sean: "go ahead" with the Blender fit. `fit_tripo.py` (above): bpy 5.0.1 runs in this
  workspace (`~/bpyenv`), 16 s a man. The stranger (`people.json`, `"source": "tripo"`) comes out
  as `assets/people/stranger.glb` (5,500 + 2,200 triangles, our 17 bones, 420 KB) with his
  texture in 5.6 mm squares (512², the head's repaint from this morning on it), and
  `ShotMatch.model = stranger` seats him in the painting's pose with the cup in his hand: he
  reads as a man at the table from the front, the side and three-quarters
  (`docs/screenshots/tripo/stranger_seated.png`, `stranger_fit_side.png`,
  `stranger_fit_three_quarter.png`). Judge round `2026-10-03_r1` (the street render is round
  52's): saloon **0.196** (the hybrid MakeHuman man's rounds 0.205–0.208). Two traps: his hips
  to ours set his scale (the trunk's own stretch made him 2.0 m and fat), and a coat skirt
  weighted to the thighs stretched into a flap between his knees when he sat (it hangs from the
  hips now). Gameplay's `tests/test_bodies.gd` gains one test (the Tripo man comes dressed; said
  here as it's their file). 286 tests pass.
  - Known: the right sleeve on the table's edge is a few big triangles seen head on (the
    decimation's budget on the coat; a higher `TRI_BUDGET` or the sleeves kept denser); his lit
    cheek still runs hot (the painted views carry their own lamplight: no de-lighting yet); the
    body is Tripo's smooth colour in squares, not the LoRA's drawing (the body's turnaround
    sheets through `head_paint.py`'s image-to-image pass would give it); the game's finger parts
    meet his cut sleeves at the knuckles without a seam check; his boots and hat are in his skin,
    so the hat can't come off and nothing of BodyMesh's dresses him.
  - Next: the body painted like the head (image-to-image at full LoRA strength from the fitted
    model's own views, baked back by UV), de-lighting, then the townsfolk as Tripo men of their
    own (`characters.json` + `people.json` entries each).
- 2026-10-03 (art session, later): **The screen mosaic: the painting's pixel style on the frame.**
  Sean: "the pixel style isn't even close to the concept art." Looked at his face against the
  painting's at the same scale (`docs/screenshots/light_pass/screen_mosaic_faces.png`): the
  painting's blocks are ~3 mm on his face and nearly one size near and far (3–4 px on the man,
  2 px at the bar, at 1280 wide), each a crisp flat tone of a sharp drawing; ours were 5.6 mm
  blobs (a blend of six views that don't register exactly, averaged), lit smoothly, with
  anti-aliased silhouettes and the decimation's facets showing, and the finish pass softening
  the block edges on top. Three changes: `head_paint.py`'s bake lets the squarest view win
  outright (weights^8) at `SQUARE_M` 2.8 mm and 40 colours; `fit_tripo.py` writes his textures
  at 1024² (`SQUARE_TEXELS` 2); and **the screen mosaic** (above, `DepthMosaic` on the game
  camera, `Settings.mosaic` on by default, the finish's softening off, `LOOK_VERSION` 5): the
  lit frame in 3–4 px blocks on him and 2 px far off, one sampled colour each, the light in 14
  tones. His face is a pixel drawing now, eyes, moustache and hair in crisp blocks, the
  silhouette stepped. The first screen-space trial (2026-10-02) lost to the old judge, which
  rewarded noise; this one is judge v2's best: rounds `2026-10-03_r2` (0.186) and `_r3` (the
  game's defaults, both views): saloon **0.187** (from 0.196), street 0.320 (0.321). The Tripo
  man is the shot's seated man by default now (`ShotMatch.model`). Gameplay's `src/main/main.gd`
  gets one line (the mosaic applied to the game camera with the other settings; said here as
  it's their file). Figures `screen_mosaic_before_after_painting.png`, `screen_mosaic_saloon.png`,
  `screen_mosaic_street.png`. Shared `settings.gd` (my lines), `tools/screenshots.gd`
  (`--mosaic= --steps= --no-mosaic`).
  - Known: the mosaic isn't on the Compatibility (web) renderer (no depth texture there); the
    far room, the lamp's cream glass and the shadows' depth are still the painting's biggest
    gaps (the judge: shadows too light, midtones too bright); his coat is still Tripo's smooth
    colour under the blocks (the body's own paint pass is next); no key cycles the mosaic yet
    (F3 lists it).
  - Next: the body painted like the head (best view wins, 2.8 mm squares), the room's grade
    (deeper shadows, the lamp amber), then the townsfolk as their own Tripo men.
- 2026-10-03 (gameplay, later): **The flicker: the sky re-lit every tick.** Sean: "the whole
  screen is always flickering, usually in sections, like the inside of a building or the mirror
  on the wall in the saloon". `tools/flicker_probe.gd` (new): renders N frames from a still (or
  `--pan`ned) camera under Forward+ and maps the pixels that change and that flip back (A, B, A);
  `--off=` suspects, `--off-script=` a GDScript `off(street, main)`, `--clock` lets the day run
  (without it the probe hid the cause), `--verbose`. Lavapipe works here now (`apt-get install
  mesa-vulkan-drivers`). A five-reader workflow listed 66 hypotheses; measured: the Sky ran
  REALTIME (`sky.gdshader` read TIME) and `DayCycle.apply_visuals()` sent it sun_dir, moon_dir and
  its colours every physics tick; each send flipped the realtime radiance between two states
  frame to frame, so everything taking ambient or reflection from the sky flickered: the street,
  and inside, walls, ceilings, the gable and the mirror at and past the interior probes' edges.
  Holding the sky uniforms alone (clock running) took the saloon 0.284% → 0.001%; the moon,
  environment, probe and same-value writes were each clean. Fix: `DayCycle._send_sky()` sends a
  uniform only when it has moved on (`DayCycleConfig.sky_update_degrees` 0.5, `sky_update_colour`
  0.004; set_time sends at once); the Sky is INCREMENTAL (`scenes/test_street.tscn`); the clouds
  drift by a `cloud_drift` uniform DayCycle sends (`cloud_drift_speed` 0.002/s) instead of TIME.
  **Art's `src/world/sky.gdshader`: two lines** (the uniform; it replaces `TIME * 0.002`).
  Measured, clock running, still camera: inside_store_afternoon 11.5% → 0.003% (flips 6.6% →
  0), saloon_night 0.28% → 0.001%, street_golden_hour 43% → 0.13% (one 2.5% frame: the clouds
  step every ~2 s now). Test `test_day_cycle::test_the_sky_hears_of_changes_not_every_tick`.
  287 pass. Ruled out by measurement: re-aiming the sun/moon every tick (a 0.5° step changed
  nothing; reverted), volumetric fog, probes, SSAO, tiles, min_square, StaticBatch.
  - For the art session: INCREMENTAL radiance is filtered at quality, not REALTIME's fast filter,
    so sky ambient/reflections may look a touch different (judge it); the clouds now move in small
    steps every ~2 s. The new screen mosaic adds shimmer under motion: on a 0.5 px/frame pan of
    the saloon, flip-backs 0.196% → 0.347% with it on (screen-fixed blocks over a moving image).
    Also from the readers (not causes of this flicker, worth doing): interior probes stop at the
    studs and below the roof, so walls, gable and the mirror fall back to the sky (size them past
    the walls and to the ridge); HeldFill lights the volumetric fog (cull masks don't apply to
    fog: give it `light_volumetric_fog_energy` 0); lamps all flicker in phase (seed a phase each).
- 2026-10-03 (art session, later): **Fix: the mosaic was a black screen on Sean's GPU (build 340).**
  His F3 screenshot: "mosaic on", the frame black with the sky showing through and the lamp
  flames over it. The mosaic's quad wrote no ALPHA, so a real GPU drew it in the opaque pass
  over an empty frame; lavapipe here never did. `depth_mosaic.gdshader` writes `ALPHA = 1.0`:
  the transparent pass, after the opaque frame and the sky, where the screen texture exists.
  **O** turns the mosaic off and on (`debug_mosaic`, shared `controls.gd`; two lines in gameplay's
  `src/main/main.gd`, said here). In the transparent pass the judge scores it worse (round
  `2026-10-03_r4`: saloon 0.228, deep-shadow share 27% to the painting's 41%; round 3's opaque-pass
  render scored 0.187 with 47%) though by eye the frame is darker and punchier: the pass changes
  what the screen texture holds (to look at next: the posterise and the glow in that pass).
  - Rule: anything full-screen that reads the screen texture writes ALPHA, and gets a real-GPU
    check from Sean before it's the default.
- 2026-10-03 (art session, later): **The voxel trial: blocky silhouettes and smooth eyes, behind
  flags** (Sean: an experiment without undoing the current work). `VoxelTrial` (above). Rendered
  the saloon shot five ways into `docs/screenshots/voxel_trial/` (`compare.png`: each beside the
  painting with the hat brim, eyes, mug and lamp at 3×), judge v2 rounds `2026-10-03_r5`–`_r11`
  (the street render is the same in all, 0.330): as now 0.228; A, cube props and hat at 128/m
  0.217, at 64/m 0.209; B, smooth eyes 0.232; A+B 0.217. **Edge hardness is unchanged by any of
  it** (0.272–0.276 to the painting's 0.252): the screen mosaic already steps every silhouette
  at its block size, so cubes of 8 mm (3–4 px on the table) vanish under it and 16 mm cubes only
  add lumps. A's gain is the dark cube props raising the deep-shadow share (0.27 → 0.29–0.30;
  painting 0.41), not outlines. By eye: the painting's blocks are a picture cut into squares over
  smooth things (its lamp foot is round, its brim a clean curve in steps); a cube-built foot or
  brim is a lumpy object. Two things learned on the way: Blender's Remesh (Blocks) fills volumes
  and loses anything thinner than a cube (the brim, a mug's wall), so the voxeliser is a surface
  shell; and cubes with their own normals are each square to the lamp or not (a foot under a lamp
  went black down its sides), so every face carries the smooth surface's normal and only the
  outline changes. B: a 12 mm eyeball is 3–4 mosaic blocks; it adds a pale highlight patch and
  the dark iris is lost, where the painted eye already reads (the stranger's irises are at body
  y 1.747, 9 cm above the anatomy's eye line: his head is Tripo's at its own proportions).
  **Recommendation: stop the voxel-engine experiment; keep eyes painted** (finer squares on the
  face, if anything, through `head_paint.py`'s `SQUARE_M`). Flags stay off. Found on the way:
  **the saloon shot rendered black with a white doorway** since the flicker merge: with the Sky
  INCREMENTAL, a cubemap direction exactly opposite the sun's gave `sky.gdshader` a `pow()` base
  a hair below zero at 23:40 (the sun near the nadir), the NaN spread through the radiance to
  every lit surface; the shader clamps its bases now (art's file; gameplay's scene unchanged).
  Build 340, where Sean saw the black screen, was the flicker merge itself (the mosaic had
  shipped in 335), so this was very likely his black screen, not the mosaic's missing ALPHA: it
  strikes with the sun near the nadir, around midnight. Sean checks build 349 or later. Shared `tools/screenshots.gd`: `--voxel=`, `--cubes=`. 287 tests pass.
- 2026-10-03 (art session, later): **The plan agreed with Sean, from Pixel-factory's NOTES.md**
  (copied here as that session asked; the voxel engine stops as a look experiment, its renderer
  kept as the reference for a frame's light; Sean tests on a Shadow cloud PC, so native plugins can
  be desktop-only).
  **A. The look, the style pack (art session). Rule: quantise once.** 1) First, measurable: every
  pre-blocking step off (the factory's squares and mosaic, the character paint's squares), the
  screen mosaic refined to the painting's blocks (soft edges, flat colour inside each, a palette
  per region, block size steady with depth), both shots re-judged; gate: the judge and Sean's eye.
  2) Characters: paint each man smooth, in flat even light, at high resolution; de-light what
  Tripo bakes in; one quantisation at render; the seated man's face first, then the townsfolk.
  3) World surfaces and shapes: the factory's textures re-cut smooth and de-lit at higher
  resolution; the dressing as specific things. 4) Finish the light pass to the painting's numbers.
  **B. Performance, the one core (gameplay session).** 5) The render thread model multi-threaded;
  Sean's F3 before and after on Shadow. 6) A Rust GDExtension foundation (CI builds for Windows,
  Mac, Linux; checked against 4.7.2's extension API). 7) Fire into native threads, then the
  structural analysis, then physiology.
  **C. Destruction (gameplay session).** 8) A `VoxelDamage` node: one wall that takes a shotgun
  blast at any shape (carve, re-mesh on a worker thread, collision rebuilt, the member told how
  much section is gone); hooks for a ball, a charge, dynamite and fire; gate: the frame budget on
  Shadow. 9) Only after 8 works: the anatomy volume with wounds carved in rest space.
  **D. Housekeeping.** 10) Sean: merge Pixel-factory's `claude/new-session-l733p0` or leave it as
  the record. 12) Sean on Shadow: the latest build's F3 frame split, so B is driven by numbers.
  13) Sean's call: drop the web export from CI now that nobody plays in the browser.
- 2026-10-03 (art session, later): **A1, the quantise-once experiment, judged on both shots**
  (the plan above; everything behind `screenshots.gd --quantise-once`, defaults unchanged, Sean's
  eye on `docs/screenshots/quantise_once/compare.png`). Every pre-blocking step off (the layout
  note above: the factory's paintings cut smooth at 128 texels/m with no palette, the man's head
  and skin without squares, tile light and `min_square` off, and two steps found on the way: the
  ground shader's own per-texel dirt noise and its snap to 24 levels), and the mosaic refined
  (block size steady with depth, soft edges, a limited palette, the sky left out of the
  posterise, and `average`: a block as the mean of its pixels). Judge v2 rounds `_r12`–`_r19`
  (as now: saloon 0.228, street 0.330): pre-blocking off with the mosaic as it was, saloon
  **0.270** and the street 0.41 (speckle: a point sample of a fine texture); the refined mosaic
  with point samples and 4 px blocks, saloon **0.207** (its best of the trial: deep-shadow share
  0.37 to the painting's 0.41, edge hardness 0.24–0.29 to 0.25), street 0.44; averaged 6 px
  blocks with the ground's noise off, street **0.344** (level; by eye the road is the painting's
  pale dust in blocks for the first time) but the saloon 0.307 (the averages lift its darks:
  deep shadow 0.24). **What it shows.** 1) A point-sampled mosaic needs an already blocky
  frame; a smooth frame needs averaged blocks, and the average must keep the darks (a
  dark-weighted mean is the next thing to try). 2) The two paintings' blocks are different
  sizes against depth (the saloon's 3–4 px nearly one size; the street's 6 px near, 5–6 far),
  so block size wants to be a property of the scene or the shot, not one depth rule. 3) With the
  blocks right, what the judge still marks on both shots is light, not blocks: the saloon's deep
  shadows and bright things (A4), the street's chroma–L* correlation and light shadows (A4), and
  the man's drawing (A2). The gate: by the judge, quantise once is better on the saloon and level
  on the street; by eye the street is clearly better and the saloon's man is softer and smoother
  than round 2's blocky one. Recommendation: carry on with A2–A4 under the quantise-once flag
  (dark-weighted averaging and a per-scene block size first), make it the default when both
  shots beat as-now, with Sean's eye on the sheet. Tools: `reduce.py --smooth`, `head_paint.py
  bake --smooth`, `fit_tripo.py --smooth`, `tools/quantise_compare.py`; shared
  `tools/screenshots.gd`: `--quantise-once`, `--mosaic-tune=`. 287 tests pass.
- 2026-10-03 (gameplay, destruction step 1): **The native plugin's foundation.** Sean decided the
  game's identity is real destruction (shotgun bites through walls, dynamite tearing chunks and
  craters, bodies that come apart) and that it's built inside Godot as a native plugin first:
  `docs/DESTRUCTION_BRIEF.md` (rules, four steps with gates; the voxel renderer experiment in
  Kokanee25/Pixel-factory is read-only reference, its verdict in that repo's NOTES.md).
  `addons/saltcreek_native/` is a Rust GDExtension on gdext 0.5.5 with the `api-4-7` feature
  (Godot 4.7.2's own API: it initialises as "API v4.7.stable, runtime v4.7.2.stable"); desktop
  only, the web build runs without it. `NativeBench` (a Node) proves the round trip every later
  step lives on: a job on a worker thread with no Godot objects in it (voxelise a sphere, carve a
  bite, mesh its visible faces), polled with `done()`, its result collected on the main thread as
  packed arrays Godot builds an ArrayMesh from. CI: `.github/actions/native-build` (a composite
  action: rust toolchain, cache, `cargo build --release` per target; macOS lipo'd universal), a
  `native` matrix job on ubuntu/windows/macos runners, the test job builds the Linux library
  before importing, the export job collects all three into `bin/` (`.gitignore`d; the
  `.gdextension` file is committed). F3 shows `native plugin: <version>, <threads>` or
  `not loaded`. `tests/test_native.gd` (2). Branch: `claude/new-session-l733p0` (the harness's
  name for this session, not the `claude/gameplay-…` pattern).
  - Next: Sean confirms the F3 line on Shadow (the step 1 gate), then step 2: a wall that takes
    a shotgun blast (brick volumes per member from Pixel-factory's `src/volume.rs`, carve,
    re-mesh on the worker, collision, the remaining section fed to `StructuralAnalysis`).
- 2026-10-03 (art session, later): **A1 finished: the dark-weighted average, a block size per
  scene, and quantise once as a switch in the build (I).** Sean: "go". The mosaic's `dark_weight`
  (above) brings the saloon's deep-shadow share back under averaged blocks (0.24 → 0.36, the
  painting's 0.41) and the far bar loses the red speckle the point samples left; by eye it's the
  best saloon of the trial (`docs/screenshots/quantise_once/compare.png`, rebuilt: the painting,
  as now, the judge's best saloon, and the switch). The block size is a property of the scene
  (`block_in` 4 px under a roof, `block_out` 6 in the open, the node's own ray up from the
  camera), and the look is a saved setting: **I** toggles `Settings.quantise_once` and reloads the
  scene (the world's materials take their textures when built). Judge v2 rounds `_r20`–`_r23`:
  dark weight 2 saloon 0.226 / street 0.346, 4 0.228 / 0.366; the switch as shipped (no palette)
  `_r22` saloon **0.265** / street **0.354**, against as-now 0.228 / 0.330. The judge's saloon
  gap is the limited palette (`sat_steps` 6, `hue_steps` 24): with it `_r23` saloon 0.224 but
  the street 0.391, so it stays a knob, not the switch's default; and its saloon gain is largely
  a threshold effect (the share under L* 10 jumps 0.25 → 0.36 while the share under L* 5 is
  identical: the saloon's median is L* 12 and the snap nudges a band of darks across the line).
  **The gate, honestly:** by the judge the switch is a little worse on both shots; by my eye it
  is better on both (the road as the painting's pale dust, the face a clean drawing, the far bar
  calm). Default stays off; Sean's eye on a real GPU decides (BUILD_NOTES: press I in the saloon
  at night and on the street at golden hour). What's left is the light (A4) and the man (A2),
  either way. Gameplay files touched: `src/main/main.gd` (two lines: the I key),
  `tests/test_pixel_art.gd` (+1 test); shared `controls.gd` (the binding), `settings.gd` (my
  lines), `tools/screenshots.gd` (`--saloon-tune=`, `--street-tune=`). 288 tests pass.
- 2026-10-03 (gameplay, destruction step 2): **A wall that takes a shotgun blast.** Members are
  carved as voxels by the native plugin (layout above: `StructureMember.voxels`, `VoxelWorks`,
  `config/voxel_damage.tres`; `addons/saltcreek_native/` `volume.rs`, `carve.rs`, `mesh.rs`,
  `pool.rs`, `member.rs`). Pixel-factory's brick volume (8³ bricks, packed voxels, its DDA) with
  one change: a cell's size can differ per axis, a whole number of cells per side, so an uncarved
  member meshes to exactly its box and its texture lands where it did. A member is voxelised the
  first time it's hit (64 cells a metre, at most 250k; ~0.2 ms). Each projectile walks the solid
  runs it meets (`solid_runs`: so a later pellet down an earlier one's hole meets nothing) and
  each run is carved on the main thread, in order (deterministic: tested): the channel at its own
  size, then spall = (energy spent there × 0.5 + muzzle blast) ÷ the wood's J/cm³ (weathered pine
  12, framing 20, stone 150), nearest the path first, wider at the exit, ragged (clumpy noise),
  reaching 2.5× as far along the grain; pieces joined to nothing go too; the wood round it marked
  torn. The greedy mesher (worker threads; the volume shared by `Arc`, copied only if a carve
  lands mid-job) gives the outside faces the member's own material and UVs, and carved and torn
  faces fresh wood (`cube_faces`), plus a ConcavePolygonShape3D, so a ball's channel lets a line
  through. `section_left`/`weakest_t` read the weakest place along the member (holes within its
  depth along the grain count together, × `hole_weakening` as drawn holes were), worked out once
  when the structure asks; `weight` the wood left. Chips: the biggest lumps, DEBRIS layer, frozen
  2.5 s after they're thrown, 80 at most. No plugin (web) or `enabled` off: drawn holes as before.
  Gameplay files only. `tests/test_voxel_damage.gd` (5: a charge at contact bites the volume its
  blast and spent energy ask for, its pellets carry on, a ragged hole you see through; the same
  charge the same hole; a ball's channel lets a line through and 4 cm off it doesn't; a 2x6 stud
  with 60 % of its section shot away gives way under 600 kg; without voxel damage the old drawn
  hole); the plugin's own 16 Rust tests (CI runs them on Linux). `test_ballistics`' "the board
  draws its hole" now checks the carved hole when the plugin's there (the drawn one otherwise).
  295 tests pass (289 + 5 + main's new one). **Bench** (`perf_bench.gd --scene=wall`: a charge into the store's
  front every half second for 20 s, 41 charges; 2.1 GHz, headless): drawn holes avg 5.73 ms,
  p99 22.2; voxels **avg 5.98 ms, p99 23.8** (`ballistics` 0.31 → 0.44 ms a frame, `voxels`
  0.13); the fire scene unchanged (11.6 / 11.0 ms). Calm street 4.1 ms (no change: nothing's
  voxelised till it's hit). Rendered (lavapipe Forward+, 12 s, 25 charges): draw calls 4,862 → 5,063 (carved
  members draw on their own, a chip a call), render CPU 9.4 → 9.9 ms. Renders `docs/destruction/step2/` (a new folder:
  `docs/screenshots/` is the art session's): three charges (4 m, 2 m, contact) into the saloon's
  front siding from outside and inside, at 48, 64 and 96 cells a metre, and the old drawn holes.
  `perf_bench.gd` gained `--scene=wall`, `--no-voxels`, `--spikes=MS`.
  - `test_ricochet`'s graze test fired ten rounds down one line: carved, the first's gouge
    turned the rest into square hits. Now twenty rounds a little apart, the same thresholds
    (half glance at 3°, none at 12° into wood, half off stone).
  - Found on the way: a townsman's first wound costs ~70–110 ms on the frame (the shot storekeeper
    behind his counter; pre-existing, not voxels): next performance item. A first carve per wood
    painted a fresh-wood texture in script (~25 ms): now a 16-texel tile.
  - Known: a carved member that snaps in two falls as two plain boxes (single-piece rubble keeps
    its carved mesh, with a box collider); 96 cells a metre reads as specks against the
    texture's 31 mm squares, so 64 (the brief's lowest); chips draw a call each; no splintered
    tint on the weathered face round a hole beyond the torn cells.
  - Next: Sean fires into the store's wall on Shadow and sends F3 while firing and after (the
    gate); then step 3 (dynamite and the ground) or the hat shot off (Part 5).
- 2026-10-04 (gameplay): **No stall at a man's first wound.** Found in step 2's bench: buckshot
  through the store's wall into the storekeeper put ~70–140 ms on one frame. Timed inside
  `take_bullet`: the wound itself ~3 ms, but `open_wound`'s first `BodyInterior.build()` for a
  part type painted the insides' textures in script on the spot (chest ~88 ms, belly ~39; cached
  after, so the next man's chest was 2–4 ms), and the first wound decals ~7 ms.
  `BodyInterior.warm_up()` paints them ahead, one a frame, from when the first person comes into
  the world (the same seeds `build()` and `_paint_wound` use). Worst frame at a first hit 119 →
  13 ms; `perf_bench.gd --scene=wall` max 138 → 32 ms (avg 4.9, p99 19.7). Test
  `test_openings::test_the_insides_are_painted_before_anyone_is_hurt`. 296 pass.
  - Known: the long bones' and the ribs' bone texture were whichever seed came first (93 or 97);
    now always 93's.
- 2026-10-04 (gameplay, destruction Part 5): **A hat shot off.** Every man wearing a hat has it as
  its own thin hitbox on his head part (`HumanBody.hat_body`: a brim disc and a crown cylinder
  fitted to the hat's pieces, new physics layer `Layers.HATS`, meta `hat_of`). A ball through it
  (`Ballistics._impact` → `HumanBody.take_hat_shot`) loses the felt's 6 J and goes on (into his
  head, if it was low enough), and the hat comes off (`knock_hat_off`): a RigidBody3D in group
  `hats` on the DEBRIS layer carrying copies of the hat's own meshes, thrown with a share of the
  ball's momentum (1.5–6 m/s) and spun, the worn pieces hidden for good, the hole's place kept
  (`hole` meta, for picking it up later). It's a `shoot_at` deed and `Events.hat_shot`:
  `OutlawBrain` takes `fear_hat_shot` 0.3 on top of the near miss, heads down (suppressed 3 s,
  ducks back from a peek), says so ("My hat!") and is provoked; `CivilianBrain` gets down for 10 s
  and says so. The Tripo man (`"whole"`) has his hat in his skin, so nothing to shoot off yet
  (that needs his layered pieces, Part 5). Tests `test_hat` (3: through the crown, the hat's off
  and lands, he's unhurt; the outlaw's fear and his line; no hat, nothing to shoot). 299 pass.
  - Known: a hat can't be picked up yet; a man knocked down keeps his hat on; the player's own
    hat isn't a thing (no visible player head).
- 2026-10-04 (art session): **A2 begun: the stranger in layers, the hat first.** Sean: "keep going";
  the gameplay session's brief (docs/DESTRUCTION_BRIEF.md part 5): every character in layers,
  the Tripo route must give layered output. The pipeline above: `characters.json` grew
  `stranger_body` (the same man redrawn from his finished front with the hat and coat taken off:
  People runs 25–26, fal; run 25's push was rejected because the branch had moved under it and
  its paintings were lost, so every commit step in `people.yml` now rebases first),
  `stranger_coat` and `stranger_hat` (each alone as a ghost-mannequin picture, four views; the
  coat's sleeves hang however the painter is asked to hold them out: `pose` is in the prompt and
  ignored), Tripo modelled all three (runs 27 and 29, items unrigged), and `fit_tripo.py` hangs
  pieces on the body. **What works:** `assets/people/stranger_layered.glb`: his bare-headed body
  in shirt, vest and trousers (a clean seated man in the lab) and his hat as its own mesh on his
  head (`Piece.place`: brim onto the band, `HAT_BAND`; test
  `test_bodies::test_the_layered_man_wears_his_own_hat`, gameplay's file, said here). Found on
  the way: pieces must be placed before the body's warp (placed after, they were scaled twice);
  a bare-headed man's head cut from his neck joints, within `HEAD_RADIUS` of the neck's axis (his
  shoulder tops rose above the collar line and went with his head); the skirt rule only on a
  whole man and the coat (it handed a trousered body's legs to his pelvis); Tripo's toe joint sits
  4 cm before the ankle (his boots stretched to 0.6 m: the foot bone is measured from the mesh).
  **What doesn't yet:** the coat (the layout note above has the four tries and the bake route to
  take next). `stranger` stays the whole man, so the saloon shot and its judge rounds are
  unchanged; `"whole": true` is the stopgap the brief names. The diagnostic men rendered on the
  way are scratch, not kept. 291 tests pass.
- 2026-10-04 (Sean's planning chat, docs only): **New working rules and a brief for review tools.**
  After Sean read how another Claude-built engine is run, these rules went into How we work: a
  brief per big job (`docs/briefs/`), no copied code (credits in `CREDITS.md`), a frame budget per
  system (table to be filled in by the performance benchmark), a blind critic after every art
  merge, golden images for the fixed views, playtests by an agent before Sean gets a gameplay
  build, a regular Fable refactor and adversarial review, and motion by mocap with procedural
  breathing/idles/flinches/aim. The jobs for both sessions are in `docs/briefs/review-tools.md`:
  gameplay builds a live look panel, a dev bridge, a camera-tour video on Pages, a playtest agent
  and the budget (after the performance pass); art supplies the panel's settings and takes up the
  blind critic and golden images from its next merge.
- 2026-10-04 (gameplay, review tools 1): **The frame budget filled in.** `config/frame_budget.tres`
  (`FrameBudget`: a budget per part, the Prof timers each part sums, `clock_scale` 0.65 from this
  2.1 GHz core to Sean's 3.25) and `perf_bench.gd` reports each scene against it (`budget` line;
  the physics engine measured by pausing the server 3 s against 3 s running; `--no-budget`).
  The table (top of this file): calm 6.6 ms of 14 with render; the fire scene's fire 2.4 of 2.0
  and its untimed share 1.5 of 1.0 are over; the wall scene's render CPU 6.1–6.4 of 4.0 is over
  (lavapipe). CI's warn-then-fail on the budget comes with the brief's item 5.
- 2026-10-04 (gameplay, review tools 2): **The dev bridge** (docs/briefs/review-tools.md; the
  commands under **Commands and layout**). `DevBridge` (`src/debug/dev_bridge.gd`) is added by
  `main.gd` only with `-- --dev-bridge` in a debug build: a TCP server on 127.0.0.1:8737
  (`--bridge-port=`), `--bridge-script=FILE` run first; one command a line, one JSON line back,
  run in order. Keys are pressed as `InputEventAction`s through `Input.parse_input_event` (an
  `Input.action_press` from a physics callback is never "just pressed" to the guns, which read
  their keys in `_process`); the guns don't wait for a captured mouse; the key help starts hidden.
  `read` reports what a player would want to know (where you are and face, what's under your
  sights, the people round you by distance and bearing with their mood and stance to you, your
  wounds), `events` a log of shots, words, hits, falls, deaths, call-outs and breakage.
  `LookPreset` (`src/debug/look_preset.gd`) sets and reads look values by address and applies a
  JSON preset (the look panel, item 4, builds on it). `tools/bridge.py` starts the game under xvfb
  (lavapipe here: ~1 fps at 960×540, real time) or headless, sends commands, stops it. Found on
  the way: **with the shotgun's right barrel fired, Q cocked the spent right hammer again**, so the
  trigger clicked and the left barrel never fired unless you cocked twice; `ShotgunState.cock()`
  now takes a hammer over a loaded barrel first (test `test_shotgun::
  test_with_the_right_fired_the_next_hammer_is_the_left`). Tests `test_dev_bridge` (4). 305 pass.
- 2026-10-04 (gameplay, review tools 3): **The playtest agent, and its first report**
  (`docs/playtests/2026-10-04.md`: ~70 minutes over two runs, 20 screenshots). It played blind
  through the bridge (`tools/playtest.md`, `tools/playtest.py`); the bridge now lets the game run
  up to 40 physics ticks a drawn frame so game time keeps up with real time at lavapipe's ~1 fps,
  waits for drawn frames after a key (a throw happened after the next command's turn), says
  `clicked` when the hammer fell on nothing and `knocked_out` when a walk ends in a blackout, has
  `release`, and logs your own blackouts. **What it found** (for Sean, not fixed here): fights are
  decided in a second or two (the gang hits first, two or three times, and you're out; three of
  four fights ended with the player out cold, two before he fired), blacking out heals everything
  in seconds with nothing said; Brody and Lyle stood inside the saloon's door frame at one spot for
  the rest of a run, never firing back; a surrendered man floated off the porch; one ignite burnt
  the south side in ~90 s and five townsfolk burnt at their posts (nobody flees fire); shooting a
  surrendered man got no reaction; surrendered men keep their guns and stand forever; two sticks
  barely marked the barber's; the townsfolk say the same lines in the same second; stars at golden
  hour; light through the store's wall corners. The look, the gang's talk and their teamwork were
  the high points.
- 2026-10-04 (Pixel-factory test session, at Sean's request): **four of Sean's new pictures added
  to `docs/concept/style/`** (art's folder, said here) with `captions.json`, for the LoRA's next
  training (`style: train`): the golden-hour standoff, the saloon from its balcony, the street at
  night with the revolver, the dynamite blast on the street; later three close portraits (an old man, a bearded man, a woman) and four full-length figures in scene light (a ranch hand on the street, the old man on a porch at night, the woman in the store doorway, a duster from behind). Judged by eye and by judge v2 against
  the nearest painting (standoff 0.143, balcony 0.208; the night street and the blast score worse
  only because the judge weighs light and they're a night scene and a fireball). Left out: the
  doctor's office (softer, paler, less of the mosaic, weaker drawing).
  - Then **the LoRA retrained on them** (People run 30: 75 crops, 27 of them from the eleven
    pictures; `tools/style/style_lora.json`) and sampled (run 31, the same six prompts;
    `docs/style_test/lora/`, the first LoRA's samples kept in `run19/`, side by side in
    `compare_run19_run31.png`). Better: the street (lettered false fronts, the paintings' ruts and
    boardwalks), the portrait (a drawn three-quarter face, deeper lines) and the horse (fuller
    form, a cleaner saddle). The same: the saloon, the full-length gunman (still a grey backdrop:
    that sample's prompt asks for one). Worse: the boards, smoother and less of the mosaic. Known:
    it spells signs badly ("SALLOONN"), and the street sample is close to the standoff picture's
    composition (more streets seen other ways round would loosen it).
  Then six props pictures (17 in the folder): the revolver on a card table, the revolver in hand
  in a street standoff (first person), the shotgun against the bar, dynamite on a crate, a gun belt
  and hat on a wall, and a lamplit card table (the lamp and table the paintings draw). Three more
  were near-copies of these and left out (the same picture with red modern shotgun shells, four
  dynamite sticks for three, the revolver with a malformed cylinder). Not trained on yet.
  Then eleven more for the light and places the set lacked (28 in the folder): the street at
  dawn, in rain and at noon, a desert wagon road, the general store, the jail at night, the
  livery barn, a camp at night, a vaquero, an alley, and a close study of a plank wall. Left
  out: a close study of the road from above (its ruts stand up as ridges and its hoof prints are
  oversized horseshoe stamps). The dawn, rain and noon streets share one layout. Not trained on yet.
  Then **the LoRA retrained on all 28** (People run 33: 126 crops, 78 from the pictures; run 32
  failed at fal's upload, 413, the PNG zip was 122 MB, so `tools/style/train_style.py` zips the
  crops as JPEG at quality 95 with full colour, 63 MB, art's file, two lines) and sampled (run
  34; run 31's samples kept in `run31/`, all three runs side by side in
  `compare_run19_run31_run33.png`). Better: the portrait (finer squares, lamplight across the
  face, a drawn three-quarter face). The same: the saloon, the boards, the street (signs still
  misspelt). Worse: the horse sample now sits small in the standard street layout (the street
  pictures share it), and the gunman's grey backdrop picked up vertical streaks like the rain.
  Then seven more (35 in the folder): a Chinese railroad worker at the depot, the undertaker at
  his workshop, the barkeep polishing a mug, the mine entrance, and three studies (a blank
  signboard, an adobe wall, the card table from above). Left out: a close study of a plank floor
  (its squares are fine random noise, the grain-as-noise the art review warned against).
  Not trained on yet.
  Sean preferred run 31's portrait to run 33's (bolder, bigger squares), and the squares agree:
  the three close portraits' squares are 11–13 px across at 1280 wide, prop close-ups 9–10, full
  scenes and the concept paintings 5–7; run 33's extra scenes taught it scene-sized squares on a
  close face. **Back on run 30's LoRA**: `tools/style/style_lora.json` is run 30's again (every
  tool reads it: `head_paint.py`, `paint_full_length.py`, `sample_style.py`); run 33's record kept
  in `style_lora_run33.json`. Next training waits on more close portraits in the original
  style, with close-ups weighted up; the scene pictures stay filed.
  Then nine more (44 in the folder): the saloon's props (a hanging lamp, the batwings from inside,
  the piano, the back bar and its mirror, a wall sconce, the stag and a painting, the bar's foot
  rail and spittoon) and boot prints in sand and in red dirt. Left out: boot prints in grass (fine
  streaky noise) and in mud (lumpy cube clumps, a voxel look rather than the paintings' flat
  squares). Not trained on yet; the faces sheet (`docs/style_test/faces_bold_squares.png`) shows
  the bold faces at 14–31 squares across the face, Sean's three portraits at 48–49.
  Then six close portraits (50 in the folder): a farm woman in profile, an old prospector, the
  doctor in spectacles, a gambler, a man in moonlight, a young woman in a red dress. Their light
  is the painting's (median L* 4–11, deep-shadow share 0.57–0.81, the painting's man 11 and 0.69)
  but their faces are ~50–60 squares across, as fine as Sean's first three portraits; those three
  trained run 30's ~30-square face, so fine portraits still teach the bold look when portraits
  aren't outweighed by scenes. Left out: Sean's first in this batch (bright and too orange, median
  L* 20, chroma 30) and a man on a blue-grey ground (the flattest light and softest eyes of the set).
  Then a vaquero in a sombrero (51 in the folder), Sean's retry of the first portrait with the
  darker prompt: median L* 10 and deep-shadow share 0.63 (the painting's man 11 and 0.69),
  chroma 25 (was 30). Left out: its twin with freckled skin (the dark specks are noise, not
  squares). Its squares are still fine, ~60 across the face.
  Then the red-dress woman redrawn with bigger squares (the same woman and pose, so it replaces
  the first in place): ~15–25 squares across the face (the painting's man ~15–19), median L* 8,
  deep-shadow share 0.69, chroma 26. The first portrait at the painting's own square size.
  Then the doctor again in a new drawing (52 in the folder; a different pose and face from the
  first, so both kept): ~25–35 squares across the face, big blocks on the cheeks with the eyes,
  spectacles and moustache drawn finer (as the painting's man's are), median L* 7, deep-shadow
  share 0.68, chroma 26.
  Then a Chinese railroad worker's portrait (53 in the folder): ~15–25 squares across the face,
  the painting's size; warm lamplight on his face and cold moonlight from one side, so cooler and
  less colourful than the rest (median L* 5, deep-shadow share 0.77, chroma 10). Left out: its
  twin in the same pose with finer squares.
  Then a cowboy in full profile under a hat with a studded band (54 in the folder): the first
  side view of a man and the first bold portrait in a cowboy hat, ~25 squares across the face,
  and the painting's light (median L* 11, deep-shadow share 0.63, chroma 22).
  Then the same cowboy seen from directly behind (55 in the folder): the first back of a head
  under a hat, the view the head repaint asks for last; big squares (the crown ~10 across, the
  hair ~20–35), darker than the painting (median L* 5, deep-shadow share 0.83, chroma 15).
  Then the same cowboy in profile facing right (56 in the folder): a new drawing, not the left
  profile flipped (it differs from that one mirrored as much as two different drawings do), ~25
  squares across the face, the painting's light (median L* 9, deep-shadow share 0.65, chroma 21).
  Then a man in a bowler hat looking straight at you (57 in the folder): the first front view
  under a hat, ~27 squares across the face; the frame is darker and greyer than the painting
  (median L* 3, deep-shadow share 0.83, chroma 12: a near-black background), his face lit as the
  set's others are. Sean sent three tries; ChatGPT drifted finer and greyer with each redo in one
  chat (27 → 33 → 39 squares across the face, chroma 12 → 10 → 9), so the second and third are
  left out. The fix: a fresh chat a picture, with a bold one attached as the reference.
  Then the cowboy facing you (58 in the folder): ~16 squares across the face (run 31's portrait,
  the look Sean picked, measures 16; the painting's man ~19), the painting's light (median L* 11,
  deep-shadow share 0.61). ChatGPT painted him hot orange (chroma 28, his face 49; the painting's
  23 and 33), so his colour is eased to 0.8 (Lab a* and b*) before filing: chroma 22.5, face 39.
  Left out: its twin, with smaller squares (~22 across the face) full of dark specks, the
  low-res-texture look Sean called PS1 graphics.
  Then a young ranch hand in soft daylight (59 in the folder): the first close face in even
  light (the game lights faces itself, so the head repaint wants faces painted in even light),
  ~17–18 squares across the face, crisp even squares on the hat and shirt. Frame median L* 54,
  chroma 28 (the street painting's 26.5), so filed as it came. Made with the rewritten prompt:
  run 31's portrait attached for the squares, the grid described, "not a 3D render".
  Then the cowboy at three-quarters (60 in the folder): both eyes showing, the far cheek turning
  away, ~16 squares across the face (~20 with the ear), crisp squares on the hat, coat and
  ground. Frame median L* 9, deep-shadow share 0.70, chroma 25, so filed as it came. Not a
  near-copy of his profile (grey difference 20; near-copies measured 4–12). The cowboy is now in
  five of the head repaint's six views, and the set has the ten bold close-ups agreed for the
  next training.
  Then the training (Sean: "go"): `docs/concept/style/weights.json` puts the ten bold close-ups'
  crops in three times each (`train_style.py` reads it: art's file, a few lines), so they're 90 of
  the 282 crops; the zip's JPEG is at quality 90 (`JPEG_QUALITY`: at 95 the 282 crops came to
  ~117 MB, past fal's single upload, which refused 122 MB; 77 MB at 90, the squares unchanged by
  eye at 3×). Run 30's record is kept in `tools/style/style_lora_run30.json` and run 34's samples in
  `docs/style_test/lora/run34/`, so the new LoRA can be judged against both and undone.
  People run 35 trained it (282 crops, 1000 steps, 12 minutes); its record is
  `tools/style/style_lora.json` (and `style_lora_run35.json`), so the sampler paints with it.
  Run 36, the samples, failed before painting anything: fal answered 403 "User is locked.
  Reason: Exhausted balance". The training spent what was left, so the samples wait on a top-up
  at fal.ai/dashboard/billing (about $0.15 for the six). Until they're judged, the new LoRA is
  untested; going back to run 30's is one copy (`style_lora_run30.json` over `style_lora.json`).
  After Sean topped up, run 37 painted five of the six samples. fal refused the gunman (the
  same lock), so `gunman_full.png` is still run 34's. Side by side:
  `docs/style_test/lora/compare_run31_run34_run37.png`. The new portrait is a front-facing cowboy
  with the set's round-studded band, bold blocks on the chin, coat and hat, and the eyes and brow
  drawn fine. It's ~23 squares across the face by run length (run 31's ~17, run 34's ~22),
  though by texture scale its blocks are the largest of the three (10 px to 8). The horse is big
  in frame again (run 34's was small); the saloon and the street are much the same; signs are
  still misspelt. Its face isn't clearly as bold as run 31's, so by the rule agreed
  `style_lora.json` is run 30's again. Run 35's record stays in `style_lora_run35.json` for
  Sean's eye.
  Sean: "run 31 is the best". So run 30's LoRA stays (`style_lora.json`). A likely reason the
  retrains go finer: the concept paintings are cut at half their height, so their squares reach
  training size at ~22 px, while Sean's pictures are cut at full height, so a scene's squares
  arrive at ~8–10 px. Run 30 was mostly painting crops; every retrain since has added scenes. If
  we train again, cut the scene pictures at half height too.
- 2026-10-05 (art session): **Three sessions; review tools' art items 1 and 2.** Sean: the
  Pixel-factory chat becomes the **characters session** (How we work above: it owns making
  people, from his picture to a fitted man, the LoRA and the layered clothing; art keeps how
  everything is drawn and lit, and judges each new man). The coat layer (A2, the "Layers" note)
  goes to it with the notes as they stand. Its Western branch (`claude/new-session-l733p0`: the
  LoRA runs 30–37, Sean's 60 style pictures) is to be merged by it first. **The look panel's
  settings** (`docs/briefs/look_settings.md`, art item 1, sent to gameplay): every look setting
  in nine groups (sun & sky, night & moon, lamps, fog & haze, glow, grade, ground, people's
  paint, squares) with where it lives, its value, a range and what it does; gameplay's
  `LookPreset` (the dev bridge) sets them by address. **The blind critic** (`tools/critic.py`,
  above), first round `2026-10-05_r1` (the build as on main, no look change; judge v2 saloon
  0.231, street 0.326). Its top three: 1) the room behind the man is brown murk, not a busy,
  lamplit saloon (the painting's stair, balcony, stag, lamps lighting their own patches of
  wall, smoke, piano player, men at the bar); 2) the street's sky is lavender-grey with flat
  orange streaks and a small white sun, where the painting's is gold with heaped clouds, a big
  sun on the horizon, rays and dust; 3) the saloon's front is in dull shade and its SALOON sign
  can't be read. Then his face (an orange smear, no readable eyes) and surfaces breaking into
  streaks rather than clean squares. **Golden images** (`tools/golden_check.py`, above): the
  check is in; the goldens themselves (all 72 views, rendered twice for each view's noise) come
  in the next merge. Also checked for Sean ("the graphics look way worse"): today's main renders
  the saloon and street shots, the street at golden hour and the saloon at night the same as
  build 367 (under 1% of pixels, a man's idle), at 1080p and 1440p as well; nothing merged since
  changed the default look, so the likely cause is a saved look key on his PC (I, O, P, F2, F7;
  F3's look line shows them). 305 tests pass.
- 2026-10-05 (gameplay, review tools 4): **The live look panel** (docs/briefs/review-tools.md;
  layout note above). **N** (controller: Back + Start) opens it in every build; 88 settings in the
  art session's nine groups (`config/look_panel.json` from `docs/briefs/look_settings.md`, the
  art session's list: its numbers, ranges and words), a time-of-day slider, Save / Export (clipboard) /
  Load / Reset; `--look=FILE` applies a preset to any run of the main scene, `tools/screenshots.gd`
  included (no `tools/apply_look.gd` needed). `LookPreset` grew addresses for the sky, ground and
  backdrop shaders (a uniform's default read from the shader's code: the headless renderer keeps
  none), the sun and moon lights, lamp groups as multipliers, a building's night fill and smoke,
  the mosaic's knobs and the people's paint. Not on the panel: the sky/sun colour gradients (a
  stop each would be a colour picker: next if Sean wants them), the chimney glass's bloom and the
  held-gun fill (constants in code), the road tile's grade (`reduce.py`, not live), `edge_shade`
  (a per-material uniform), the texel density (F7). `mosaic.block_k`/`steps` are overwritten by
  Settings' K and steps when the mosaic is re-attached (a settings change); the rest stay. Shared
  `controls.gd`: one line (`look_panel`, N). Tests `test_look_panel` (3: every setting on the list
  is reachable in the street; a slider sets the game and Reset puts it back; a preset saved and
  loaded comes back).
- 2026-10-05 (art session, later): **The characters brief** (`docs/briefs/characters.md`, for
  the characters session; Sean: "they need more details since their clothing will all be
  separate layers"): what a layered man is, layer by layer, with the shape names and garment ids
  the game already keys on (`skin`/`head`, `hair`, `shirt`, `trousers`, `vest`, `coat`,
  `cravat`/`bandana`, `boots`, `gun_belt`/`belt`/`holster`, `hat`; HumanBody's garments with
  their resistances), what every piece must do (fit in every pose, clear the layer under it, cut
  per body part for wounds, its own flat-lit texture, a triangle budget), the two routes (Tripo
  for the principal men, MakeHuman for townsfolk) and a shared wardrobe, the order (the
  stranger in full, then Brody, Lyle and the Kid, then the storekeeper and barkeep), spending,
  how it's judged and three open questions for Sean (long johns or bare skin under the clothes, a
  shared wardrobe, who after the gang). Docs only.
- 2026-10-05 (gameplay, review tools 5): **The tour video on Pages** (layout note under Commands).
  Pages is deployed as one whole site by the build, so the tour can't simply add a folder: the
  videos live on a `tour` release and both workflows put them in `/tour/`. Measured here: 902
  frames at 960x540 in 1,000 s on 4 cores at 2.1 GHz; CI renders at 854x480 to stay near the
  brief's 20 minutes (it runs after the build, so it holds nothing up either way). First frames
  are written before the tour's camera takes over, so the encode starts at frame 3. The first
  tour appears after this merge's build: Actions → "Tour video".
- 2026-10-05 (gameplay, checks 1): **The bug-report key and its replay** (Sean: "add automated
  checks so Sean reviews less, one merge each"; `docs/briefs/automated-checks.md`, which also asks
  the art session for the visual checks: sent to it 2026-10-05). F12 and `tools/replay.gd` (layout
  note under Commands). A short session replays from the start; recorded and replayed at the same
  fixed step the replay matched to the centimetre (test `test_bug_report`, 2: the file has
  everything; a replay in a Godot of its own matches the play). Recorded at a varying frame rate (a
  real player's) the process-frame timers can drift a little: the replay says where. Shared
  `controls.gd`: `bug_report` on F12, `debug_ignite` lost F12 (L stays). `tools/tour.gd` now puts a
  `.gdignore` in `build/tour` (the editor imported 900 frames).
- 2026-10-05 (gameplay, checks 2): **The nightly soak** (layout note under Commands). Tried here:
  12 game minutes caught a real error on its first run (the bug recorder named a class that isn't
  declared, so `main.gd` failed to compile; fixed before it merged); then 15 minutes in real time
  and 10 at a fixed step passed: memory 272 to 279 MB, nodes ~25k, no orphans, 3.4–3.8 ms a frame
  at a fixed step. Nightly: 240 game minutes, ~70 minutes on a runner.
- 2026-10-05 (Pixel-factory test session, at Sean's request): **custom men, starting with the
  Kid.** Sean asked how we get custom models now: the stranger's pipeline (paint four views on
  fal, Tripo, the head repaint, `fit_tripo.py`), with Sean making each man's front picture in
  ChatGPT (full length, A-pose, flat light, plain grey ground, clean, not pixel art). The Kid's
  is `assets/people/tripo/kid_full.png`. `characters.json` has `kid` (`given`: that front is kept
  as it is, only the other three views painted), `kid_body` (from it, hatless) and `kid_hat`
  (the hat alone), so his hat is its own piece and can be shot off. `paint_full_length.py`
  (tools/characters/, the art session's pipeline: said here) gained `given` and `back_of` (what
  his back shows when it isn't a coat and long hair: braces, short hair); the stranger's prompts
  are word for word as before. Next: People `style: characters` with `characters:
  kid_body,kid_hat` to look at before Tripo, then Tripo, the head repaint, the fit.
  Then the turnarounds (People runs 38–42, fal, ~$0.80; kept: run 40's hat and run 42's body,
  `docs/screenshots/tripo/kid_front_hatless_hat.png` beside Sean's picture). Run 38's hat came
  back a clean grey fashion fedora and his hatless hair a combed quiff; the fixes were all in
  `characters.json`'s words. The hat as Sean drew it (tan felt grimy in broad patches, a dark
  band, the brim curled up at both sides) came right at run 40 ("blotchy stains" had drawn
  round dots). The hair took four tries: "flattened where the hat sat" (39) and "lying flat
  where the crown pressed it" (41) each put a red cloth on his head, "shaggy, messy, untidy"
  (40) a huge mop, "grown long to his collar" (41) hair past his shoulders; run 38's words with
  "short, a little tousled" (42) gave Sean's lad bare-headed. For Kontext, a hatless man's
  words never mention where the hat was, and his hair is said plainly. `head_paint.py` takes a
  character's own `head` words (whose head, how he looks, the light, any view's words, and
  `cut` for a bare head; the stranger's asks are word for word as before) and `kid_body` has
  his (young, freckled, no hat, soft even light); `fit_tripo.py` takes a layered man's repaint
  from his model's `<model>_color.png`. Both art files, a few lines each. Waiting on Sean's
  look before Tripo (`characters: kid_body,kid_hat`, ~85 credits as the stranger's took).
  Sean: "keep this one" (the legs and torso looked short to him). Tripo built both (People run
  43); fitting him showed why, and what else was wrong, all fixed in `tools/blender/fit_tripo.py`
  (the art session's pipeline, said here), for bare-headed (layered) men only unless noted, so
  the stranger at the card table is unchanged: **(1) above his shoulders**: Tripo's auto-rig puts
  the neck joint at the shoulder line and the head joint half way up the neck (the Kid's at 0.76
  and 0.81 of his height, his chin 0.86), ours 4 and 13 cm over our shoulders, so joint to joint
  lifted his shoulders to his jaw; now his shoulders go onto ours and all of him above them is
  scaled as one, his crown on our skull's top plus `HAIR_M` 2 cm, which also sizes a big drawn
  head to our skull (on the old rule the stranger's head is half as big again as the hitboxes in
  it); nothing past a bone's ends is stretched as the bone; **(2) hair** above his head joint is
  head however far it sticks out (a strand had stood 11 cm off his head); **(3) Tripo's scraps**
  (every man): small pieces joined to nothing, away from him (two flat patches beside his hands)
  are dropped, a boot's own sole kept; **(4) fingers** touching a thigh go with the hand
  (`FINGER_REACH`); **(5) the hat** is levelled (Tripo built it tipped 15°) and sized by its crown
  (`CROWN_SHARE`; the curled brim had made it a toy hat); **(6) arms fused to his sides**: the
  hatless redraw had pulled his arms in (11° where Sean's front has 40°) and Tripo fused them on,
  so hands up and aiming tore sheets and strings off him (the layered stranger too); a `from`
  piece with `keep_pose` is now a short edit keeping the front's pose (`paint_full_length.py`
  `ASK_EDIT`; run 44: arms out 25°, Tripo again, run 45), and the fit cuts what still joins parts
  that move apart (`cut_bridges`, `BRIDGE_SHOULDER`) and caps each side of the cut on its own part
  (`close_cuts`: his side and the inside of his arm stay whole under raised arms); **(7) cracks**
  (every man): the Blender build split his points along every texture seam and decimated each side
  apart (the Kid's skin ~3,900 open edges, the stranger's ~4,800: the white slits on both); welded
  first now, 192. His head painted in the style and baked (People run 46: the style model ages his
  face in the paintings, but on him he reads young). `assets/people/kid.glb` (1.815 m, 5,500 +
  2,200 + a 700-triangle hat piece); `people.json` `kid`; the gang's Kid wears him in the game
  (`src/people/town_life.gd`, gameplay's file, two lines: a `model` in his GANG entry). New tool
  `tools/people_lineup.gd` (men side by side, orthographic, in poses; `--head` close): the check
  before a fitted man goes in, `docs/screenshots/tripo/kid_lineup.png`, `kid_head.png`. Tests:
  bodies 21, hat 3, town day 11, perf 2 pass. Known: hands up, the caps on his sides are flat and a
  shade off his shirt; the hat's texture is Tripo's (not repainted in the style); the stranger and
  `stranger_layered` aren't re-fitted (the weld would close the stranger's cracks: one command,
  `fit_tripo.py --only=stranger`, the art session's call as his shot is judged).
  Then, as the characters session (the art session's entry above: this chat is it, and this branch
  is to be merged first): the brief's pose check (`people_lineup.gd`, now with a back view): the Kid
  sits, crouches and cowers cleanly. `main` merged in twice (CLAUDE.md's status in date order);
  CI green on the branch (run 37251503618, commit 763cc47; build notes say what to try with the
  Kid). Pushing the merge to `main` was refused by this workspace's permission check, so the
  branch waits on Sean to merge it (GitHub) or allow it. Spent on the Kid: fal paintings (runs
  38–42, 44, 46) and 140 Tripo credits (two bodies and a hat). Sean: "push to main and consider
  this a test that's getting closer" (the Kid is a first test of making our own men, body and
  hat only; the brief's other layers, and the stranger first, come next).
- 2026-10-05 (gameplay, checks 3): **Chaos tests** (`tests/test_chaos.gd`, 2). The street with
  the gang and the townsfolk in it, and every 1.5 s for 14 s, from a seed, a 0.2 kg stick by a
  random member, a random member set alight, or three rounds from a random point at a random spot
  or person. Every half second: no body under the ground (y < -1.5) or off the map, no position
  that isn't a number, nobody back from the dead, no blood below zero, no broken member mended,
  and no script error (the runner fails on any). Seed 1873: 10 events, 64 members broken, 6
  burning, 9 people hurt, nothing broken. The same seed twice gives the same events, the same
  broken members and the same people alive and hurt.
- 2026-10-05 (gameplay, checks 4): **Feel ranges** (layout note under Commands). Measured today:
  body hits to stop a man 1.54 (agreed 1.2–2.3), the shotgun drops a man at 20 m 0.19 of the time
  (0–0.5), the store's roof in at 129 s (60–300), the outlaw's hits at 5 m 9 of 9 = 1.0, at 15 m
  4 of 13 = 0.31, at 30 m 3 of 24 = 0.13, the duel's stand-off 4.9 s (designed 2.5–5), and **none
  of the gang backed down** with a gun held on them 6 m off in the street for 25 s: Brody, Lyle and
  the Kid all drew (the Kid backs down when he's caught leaning on the storekeeper). The new ranges
  are set round today's numbers and marked proposed: Sean to OK or change them, and to say whether
  the gang should back down more in the street.
- 2026-10-05 (gameplay, checks 5): **The exported builds are smoke-tested before they're
  released** (layout note under Commands). Tried here with the editor's binary: headless 3,815
  frames in 30 s, 14 people, no errors; drawn under lavapipe 24 frames (at 1280x720 it was 20, so
  the bar is 10 frames: it asks only that the build runs and draws). The first run on Windows and
  macOS runners is this merge's build.
  - With it, a fix the first nightly soak found on CI (30 game minutes, run by hand): after the
    livery burnt, a piece of rubble fell through the ground for good (y −6 to −388 in ten seconds),
    and a member already burnt away was snapped (`get_child` out of range, `queue_free` on null).
    `Structure._snap` finds its mesh and shape by type and does nothing for a member burnt away; a
    shattered pane falls as nothing; a clump with no working shape isn't kept; rubble more than 5 m
    under the ground is removed with a warning (`LOST_BELOW`). `tests/test_rubble.gd` (3).
- 2026-10-05 (gameplay): **Fix: the desktop builds shipped without the native plugin.** Main went
  red on build 496: the drawn Linux smoke test failed. Its log showed what nothing had checked:
  **every Windows and Linux release since destruction step 1 (2026-10-03) ran without the native
  plugin**, so no voxel damage, only drawn holes. The export put `saltcreek_native.dll` /
  `libsaltcreek_native.so` beside the game, but the Package step zipped the executable alone (macOS
  was fine: the library is inside the app). Now the whole export folder is packed, the export step
  checks each platform's library is there, and the smoke test fails on the desktop without the
  plugin (`ClassDB.class_exists(&"VoxelMember")`; tried here with the library moved away). The
  drawn run: on the runner the first frame took ~50 s of shader compiling, so all four events fired
  on frame 2 at once and the game didn't quit within the 300 s limit (it draws a last frame before
  quitting, and that frame had every new effect's shaders to compile in software). Its clock now
  starts at the first drawn frame, each event waits three drawn frames after the last, the end
  waits three after the last event, and the runner's limit is 900 s. Here, cold shader cache: 33
  frames in 30 s, first frame after 8 s.
- 2026-10-05 (gameplay, checks 6): **Sound checks** (`tests/test_sounds.gd`, 4): every sound
  `SynthSounds` makes is heard (its loudest 50 ms at least 2% of full scale), never reaches full
  scale, and has under 3% of its energy below 40 Hz (measured by a DFT of the sound averaged down to
  ~1.4 kHz; the measure itself is tested on 30 Hz and 200 Hz tones), and the master bus still has its
  40 Hz cut and limiter. **It failed first time, on a real fault:** the gunshot had 14% of its
  energy under 40 Hz, the shotgun 42%, dynamite 22%, though the code said the thump never went
  below 40 Hz. `sin(2π f(t) t)` with a falling f sweeps below f itself (its pitch is f + t·f′),
  which took the shotgun's thump down to 28 Hz; the phase is summed from the pitch now. And every
  sound passes a fourth-order high-pass at 45 Hz (`SynthSounds.LOW_CUT_HZ`, its peak kept). The
  deepest is now the shotgun at 2.8%.
- 2026-10-05 (art session, later): **Golden images and the visual checks** (review tools, art
  item 3; gameplay's `docs/briefs/automated-checks.md` asked for the visual checks). Every fixed
  view in `tools/screenshots.gd` has its golden in `docs/screenshots/golden/` (70: the 67 views
  and main's three Kid views, rendered here twice under lavapipe; `tolerances.json` is three
  times each view's run-to-run noise, floor 1.5 / 1 %: a still is at the floor, a scenario with
  the gang or smoke in it is loose, the town fights and `texel_*` views at a mean of 120–465, the
  saloon shot's extras at 58). **The visual checks** (layout note above: `tools/scene_probe.gd`,
  `tools/visual_checks.py`, limits and known faults in `tools/visual_checks.json`): on the
  goldens' pair of renders and a fresh probe, 367 checks, none failed, one warn (a bottle on a
  shelf with no collision). Found on the way and fixed: two views rendered black
  (`smoke_drift_street`: the range outlaw shot the player; `texel_porch`: the gang did), so
  `screenshots.gd` keeps the gang out of the fixed views (`gang_arrives` far off, `_calm()`
  frees them and heals the player between non-town views); a telegraph pole through the jail's
  boardwalk (`StreetDressing`, z −13.4). Known, recorded in `visual_checks.json` as tolerated at
  today's value: the shirt shows through the coat by about a centimetre on every BodyMesh man in
  a coat (14–16 % of the shirt near it; characters session, `body_mesh.gd`), and the seated
  stranger's left sole is 11 cm under the saloon floor (below the frame in the shot; the seat
  is ShotMatch's, his legs the fit's). For the look panel, `lamp_group` metas on the saloon's
  and street's lamps and the shot's table lamp, `model_name` on the street's folk. Shared
  `tools/screenshots.gd` (my lines). 318 tests pass. Found by this merge's CI: `test_composure`'s
  settle test failed in the suite and passed alone, because the player's revolver seeds its
  misfires from its node path's hash and the test world's node names count up with everything
  made before it, so the shot was a misfire lottery; gameplay's `tests/test_composure.gd` turns
  misfires off (two lines, said here).
  - CI (gameplay's wiring, told to it): `apt-get install mesa-vulkan-drivers xvfb`, render the
    views twice (`golden_check.py --render --out=A`, then `--out=B`), `scene_probe.gd`, then
    `golden_check.py --from=A` and `visual_checks.py --from=A --twin=B --probe=PDIR`.
- 2026-10-05 (gameplay): **The art session's visual checks wired into CI** (layout note under
  Commands; the automated-checks brief's last item). Tried here on the first five views: all match
  their goldens rendered in order, and the visual checks pass but one: **the Kid's head comes
  through his hat** (`clothes`, 39% of the head's vertices near the hat lie outside it, limit 3%),
  on main now, so the first nightly run will be red until the characters session refits his hat
  or the art session records it as known (`tools/visual_checks.json`). `test_chaos`'s same-seed
  test (the art session saw it flake in the full suite: one stool more broken on the second run)
  now asks for the same events exactly, the same people alive and wound counts within one, and
  the broken members within two (or 5%): the seed decides what happens, falling rubble a little
  of what it breaks, and the physics engine isn't bit-repeatable between runs in one process.
- 2026-10-05 (art session, later): **Part B: our own renderer, the mosaic on the surfaces, behind
  the M key** (Sean's brief, `docs/briefs/renderer.md`; its findings section has the numbers).
  The look (layout note above, "The surface-blocks look"): the block is the texel, anchored to
  the surface, lit as one with the tile gradient, its edge blended over half a render pixel from
  screen derivatives (`tile_soft_point`, `tile_sample_soft`: four fetches, the pixel-art
  anti-aliasing trick), distance softened by the mip (`min_square_px` 0), no screen pass, each
  material's shadows in its own warm tint (`shade_tint`); the light bands (`light_bands`) are
  built and off: with them the face and coat went poster-flat and the judge preferred smooth
  light. Rendered on the Part A restore with the current default and the I key beside it
  (judge v2 rounds `2026-10-05_r6`–`_r8`): saloon 0.256 / 0.293 / **0.202**, street 0.565 /
  0.587 / **0.527**; a 40-frame pan half a degree a frame (`tools/pan_frames.gd`), the share of
  pixels that flip back: saloon 6.4 % / 6.8 % / **1.8 %**, street 6.3 % / 6.8 % / **3.7 %**; cost
  (`tools/look_cost.gd`) the same render CPU, 2–5 % less raster. The blind critics on all three
  put the same things first (the restore's pale confetti sky, the man's face, the room's brown
  murk, the saloon's front, the road); only the blocks critic marked the blocks: the sky's
  and the doorway's squares giant beside surfaces that read smooth. Earlier rounds today:
  `_r2`–`_r5` (the blocks' variants: 1 px / 8 bands, 0.5 px / 12 bands, 0.5 px smooth) and the
  I key on the pre-restore build. Review sheet `docs/screenshots/review/2026-10-05_renderer.png`
  (painting | current | quantise once | surface blocks, 3× crops of his face, the back bar and the
  far street, the pan strips). The default path is unchanged (the Part B tree's default render
  against the restore's: within the goldens' run-to-run noise). Off by default; Sean's eye
  decides. Gameplay files touched (said here): `src/main/main.gd` (three lines: the M key, the
  mosaic only when it's active), `src/structures/structure_member.gd` (two: the blocks shaders
  count as grid and hole shaders), `src/world/static_batch.gd` (one: the blocks shader batches),
  `src/bodies/human_body.gd` (one: the shade tint on a man's pieces), `tests/test_pixel_art.gd`
  (+1 test). Shared `settings.gd`, `controls.gd` (M), `project.godot` (two globals),
  `tools/screenshots.gd` (`--blocks`, `--global=`), my lines.
- 2026-10-05 (art session, later): **Goldens that don't depend on the view before.** The goldens
  merged this morning were order-dependent: `tools/screenshots.gd` rendered every view in one game,
  so a view inherited the one before it (the gun smoke still in the air, a pose half eased, the
  clouds' drift, the exposure's lag), and even a full run drifted (`shot_match_street` rendered 25 %
  brighter in one run than another: the smoke from the view before). `--fresh` (now what
  `golden_check.py --render` and gameplay's `visual.yml` pass): the main scene is freed and loaded
  again before every view, so a view renders the same alone as in the full run; two full runs now
  differ by a mean of 0.15 or less on 54 of the 70 views, blasts and smoke included (the rest by
  their physics and fire). All 70 goldens re-approved from the pair (`tolerances.json` from their
  noise: 54 at the floor, the loosest the store fire close up at a mean of 26; this morning's had
  the town fights and `texel_*` views at means of 120–465). The visual checks on them and a fresh
  probe: 376 checks, none failed; the Kid's hat (gameplay's note: his hair under the brim at the
  sides counts as the head outside the hat, 39 %) is recorded as known in `tools/visual_checks.json`
  for the characters session (by eye the hat perches high, nothing through the crown). Gameplay's
  `.github/workflows/visual.yml`: two lines (the flag, the header's note), and its layout note "The
  visual checks in CI" above, three lines, at the gameplay session's request. 323 tests pass.
- 2026-10-05 (gameplay): **The second playtest** (`docs/playtests/2026-10-05.md`, build 511: ~50
  minutes over two games, 26 screenshots; Sean: "have the ai test play"). **Broke:** blacking out
  costs nothing (six times shot down, each time up four seconds later in the store's corner,
  "Unhurt.", full blood, once a few metres from the men who shot him); fire with no one fleeing it
  (one stick and one ignite burnt both sides of the street in ~8 minutes, five townsfolk burnt at
  their posts without a word, the LIVERY sign and its lantern left hanging over the ashes, a horse
  calm through it all). **Flat or confusing:** the gang wins every fight before you can act (the
  Kid three hits from three at 18 m), calling Lyle out with the gun holstered got him shot rather
  than a duel, rescuers stuck (Brody in the saloon's doorway a minute, Lyle behind the door two
  minutes calling "Hold on, I got you!"), the range man talks in every fight from out of sight,
  townsfolk all shout one line in the same tenth of a second; smaller: a blast's wounds not
  counted on you, the surrendered man's "I'm unarmed!" five times at once, the revolver
  holstered cocked, stars at golden hour, a hard edge on the backdrop's mountains, two saloons,
  full night three or four minutes in. **Fun:** the look (the golden-hour street, the saloon
  bar), the gang robbing the store ("Open the drawer. Slow."), their talk under fire, the Kid
  dying slowly of a gut shot with his friends trying to reach him, a stray round dropping a man
  50 m off, a townsman's hat shot off ("He shot my hat clean off!"). Not fixed here: for Sean to
  choose what's first. Many repeat the first playtest's (the blackout, the doorway, fire).
- 2026-10-05 (gameplay): **Going down costs you** (both playtests' top fault; Sean: "Yup"). Out
  cold (or killed), `PlayerWounds._come_round()` now: hours pass (`OUT_HOURS` 6:
  `DayCycle.pass_hours()`, announcing each hour and day; `Events.hours_passed(hours, why)` for
  anything that runs on time), you come round on the store's floor (the doctor's in M5) patched,
  not healed (`_patch_up()`: every bleed tied off and bound, belts off, lungs sealed, the gut
  sewn, shock and pain eased, a killing wound survived; broken bones, lost fingers and limbs,
  eyes, torn muscle and the wound count stay; `WAKE_BLOOD_LOSS` 0.2 of your blood still missing),
  and you're told the hour, who shot you down (the player's `last_hit_by`, then forgotten),
  whether you were as good as dead, and what you still carry, in a line no one's talk writes
  over (`say(..., hold)`). On `hours_passed` an `OutlawBrain` stands down from every fight, and
  a town man with a day's plan who can still walk and hasn't given up is gone (`left_town`);
  `CivilianBrain`s calm down. "Poorer" waits for the purse (M4 step 5). Tests `test_come_round`
  (3); `test_gunfight`'s blackout test now wants you patched, not unhurt.
  - Known: nothing else catches up over the hours (a wounded man lying in the street hasn't bled
    for six hours; fires don't burn on; the dead aren't taken away); `blood_regen` is 0.004 ml/s,
    so a fifth of your blood takes ~70 real hours to come back (Sean: keep healing slow; you heal
    properly by sleeping, later, DESIGN.md §7 Treatment); a broken leg means crawling until there's a doctor and time to heal.
- 2026-10-05 (gameplay): **People get away from fire** (both playtests: townsfolk burnt at their
  posts without a word). `FireSystem.fire_near(at, radius)` (what's burning near a point, from the
  fire's grid) and `burning_map()` (2 m squares where it's burning seen from above, made at most
  every half second of game time and shared). `FireFlight` (`src/people/fire_flight.gd`): the
  way clear of a fire, from the town's street places (`Waypoints.routes_from()`: one search to
  every place) and straight-out points in eight directions, the nearest one 15 m clear of any fire
  reached by a way never within 3 m of it (~10 ms in a burning town; the first version routed to
  each place on its own and took 250 ms). `CivilianBrain`: mood `FLEEING`; fire within 8 m (looked
  for twice a second, scorching looks at once) and he shouts it (a line of `LINES.fire`, after
  0.15–1.6 s so a crowd doesn't shout as one), runs the way out, watches it burn, re-flees if it
  reaches him, and walks back once his post has had no fire within 15 m for 20 s (`places`: the
  TownLife's, which now joins group `town_life`). `OutlawBrain`, calm and going about his day:
  out of it by the same, a line (`LINES.fire`), and what's left of his day is riding out.
  Two fixes on the way: `Waypoints.store_behind_counter` x 5.65 → 5.5 (a man walking there
  caught his shoulder on the wall's studs; nobody had walked it before), and `Waypoints._walkable`
  sweeps at the lower end's height (from a porch a sweep passed over the hitching rail below).
  Tests `test_flee_fire` (4). In the street (bridge, store lit inside, 150 s): everyone out, no one
  burnt; before, two of the bench men died every time.
  - Known: a man in a fight ignores fire; nobody fetches water or fights it; a man whose post
    burnt down walks back to the ashes; the gang's horses (props) don't react.
- 2026-10-05 (characters session, at Sean's request): **The probe mosaic: texel splatting's idea
  in the game, behind V, measured against the surface blocks; command-line looks fixed.** Sean
  asked whether texel splatting (Ebert 2026: pixel art held still by indexing the scene by
  direction from a point snapped to a grid) could make the painting's look workable, then "keep
  working at it". Built as one pass over the finished frame (layout note above, "The probe
  mosaic"; the art session's `src/render/` folder, new files, said here) and measured on six camera
  paths through the saloon shot's set at a fixed step with a new measure (`tools/probe_walk.py
  stability`: each pixel moved back to where its point of the world was a frame before, counting
  the colours that aren't there, so the camera's own movement is taken out). **Found on the way,
  for the art session:** with no settings file (this workspace, CI, the tools), `--blocks`,
  `--quantise-once` and `--probe-mosaic` on the command line set their switch but never their
  shaders and textures (`Settings.load_from_disk` returned before `_apply_quantise`), so a
  `--blocks` render drew the default materials under the look's globals (soft edges, no screen
  mosaic) without the blocks shaders' own `light()`, and `pan_frames.gd`/`look_cost.gd
  --quantise-once` drew the factory's squares, not the smooth set (`screenshots.gd
  --quantise-once` was right: it calls the setter). Fixed (shared `settings.gd`, a few lines; test
  `test_probe_mosaic::test_with_no_settings_file_the_look_reaches_the_materials`). Drawn as the M
  key draws it, the surface blocks' `light()` adds a wide highlight (exponent 8 at roughness 1, a
  quarter of the light) that blows the lamp's pool on the table: the saloon shot scores 0.362
  (`2026-10-05_r13`) where with the game's ordinary light it scored 0.198 (`_r11`, the
  half-switched render): the art session's to look at. Unstable pixels a frame, still / turn /
  walk / strafe / circle / approach: no mosaic 0.03 / 0.22 / 0.22 / 0.22 / 0.18 / 0.10 %; today's
  default (screen mosaic) 0.96 / 3.52 / 2.61 / 2.77 / 2.61 / 2.70; the first probe, with 14 OKLab
  light bands, 0.48 / 2.18 / 2.65 / 2.03 / 2.18 / 1.89 (the bands were most of it: a block near a
  band's edge flips as you move, and they crush the darks); with smooth light 0.05 / 0.54 / 0.70 /
  0.75 / 0.56 / 0.33; **as shipped** (texels by equal angle, one sample a block) 0.12 / 0.75 / 0.96
  / 0.75 / 0.84 / 0.60; **the surface blocks as the key draws them 0.04 / 0.12 / 0.11 / 0.09 /
  0.10 / 0.12**, steadier than no mosaic (their soft texel edges calm the textures' own
  aliasing; with ordinary light 0.04 / 0.23 / 0.22 / 0.23 / 0.19 / 0.12). What flickers in the
  probe is outlines and glints: it re-reads the frame, whose own edges are jagged; the re-cut as
  you cross a cell adds little. The art session's pans (`tools/pan_frames.gd`, flip-backs a
  frame, saloon / street): default 6.42 / 6.28 % (theirs 6.43 / 6.28), surface blocks 1.77 / 3.59,
  probe 3.05 / 4.19. Judge v2, all `--fresh`, saloon / street: default `_r10` 0.225 / 0.329;
  surface blocks `_r13` 0.362 / 0.284; probe with a 3x3 mean `_r9` 0.220 / 0.319; **probe as
  shipped `_r12` 0.195 / 0.281** (corrected below, in "The probe mosaic steadier": these probe
  stills were rendered before the command-line fix, over the game's squared textures; V's own
  look scores 0.181 / 0.341); variants scored with the judge's measures, not kept as rounds:
  14 bands 0.309 / 0.304, a blurred read 0.227 / 0.317, a dark-weighted mean 0.236 / 0.312, 512
  texels 0.203 / 0.320, one sample before equal angle 0.199 / 0.283. The art session's r6–r8 were
  rendered before `--fresh`: their street shots inherited a brighter state (18 % of the sky blown
  to the fresh renders' 1.4 %), so their street scores (0.53–0.59) don't compare. Cost
  (`tools/look_cost.gd`, lavapipe's raster ms a frame, saloon / street; render CPU 8.5–9.3 /
  4.3–4.6 ms under all three): default 1124 / 533, surface blocks 1149 / 516, probe 1077 / 525: a
  wash. Blind critic on r12 (`critic/critic.md`), top three: the street's sky isn't golden hour
  and its sun is a small white glare; the room behind him is dark murk, not a busy lamplit saloon;
  his face is a speckled orange smear with sleepy eyes and his hat has lost its shape. Review sheet
  `docs/screenshots/review/2026-10-05_probe_mosaic.png` (painting | default | surface blocks |
  probe, his face and the far street at 2x, the table). **Verdict:** texel splatting's idea works
  in the game, and both new looks beat today's default in motion; the surface blocks are by far
  the steadiest (six to nine times steadier than the probe), and with ordinary light they tie the
  probe on the judge, but as merged their own light blows the lamp's pool, so in the saloon the
  probe is the closer to the painting today. The probe's gift is blocks on everything, his face
  included, and outlines stepped at the block size; its cost, a little flicker on outlines. Sean's
  eye in motion decides (BUILD_NOTES: V, M and neither). Either way his face loses its eyes under
  any mosaic: the painting's face is drawn for its blocks (eyes two or three squares with whites)
  and ours isn't, so the characters session's next step for the look is his face drawn at the
  block size. Files: shared `settings.gd` (the probe's lines, the no-file fix, and one line in the
  art session's `mosaic_active()`, so it counts the probe and F3's look line is right),
  `controls.gd` (V; the comments on I and M put right: main's M line carried I's),
  `tools/screenshots.gd` (`--probe-*`), `config/look_panel.json` (four rows), gameplay's
  `src/main/main.gd` (three lines: the probe on the camera, the key), `tests/test_probe_mosaic.gd`
  (7), `tools/probe_walk.gd`/`.py`. This workspace's native library was destruction step 1's (no
  VoxelMember), so the four voxel tests failed here till it was rebuilt (`cargo build
  --release`); CI builds its own. Merged as build 535 (green); the fix and these numbers follow.
  337 tests pass.
- 2026-10-05 (gameplay): **Fire four times slower** (Sean: "the fire probably burns too fast, it
  would be cool if you could actually have time to put it out"). `FireTuning`'s
  `contact_heating` 120 → 30, `radiant_heating` 18 → 4.5, `cooling` 0.022 → 0.0055 (scaled with
  the heating, so a member settles at the same temperature beside a fire: slowed alone, boards
  beside one never caught), `growth_seconds` 8 → 32, `char_rate` 0.00025 → 0.0000625: the same
  fire, four times slower. `tools/fire_timeline.gd` (new: two boards lit on a store's back wall,
  a second store 4 m off, `--set=name:value` to try numbers) measures it: 5 burning at 10 → 36 s,
  20 at 20 → 75 s, framing alight at 12 → 50 s, the roof in at 129 → 511 s. The feel range
  `fire_store_roof_seconds` moved to 360–900 with Sean's words. `test_fire`'s limits ×4;
  `test_perf`'s burning street lights 20 members a building (it waited 8 s for 4 to spread);
  `tools/screenshots.gd` (shared, my lines) runs its fire views four times as long, so they show
  the same stage of the fire; the golden `store_fire_night` re-approved (art's file: a townsman
  now runs from the fire across the foreground, the fire as before).
  - Next: putting it out (DESIGN.md §8 fire: water puts it out, bucket lines from the trough).
- 2026-10-05 (gameplay): **A bucket to put fires out** (Sean, with the slower fire: "have time to
  put it out"; DESIGN.md §8: water puts it out). `BucketViewmodel` (4; `Controls` shared, one line:
  `weapon_bucket`): R at a trough (`WaterTrough` joins group `water_source`; within 1.9 m of its
  water) dips it, 1.2 s, 10 litres; LMB swings it (0.3 s) and the water leaves as 24 drops, each on
  its own arc (6.5 m/s, a cone 14° across and 7° up, followed by rays in 0.05 s steps), and where
  each lands `FireSystem.douse(at, 0.4 m, its share)`: shared among the members within reach by
  nearness; a burning one with `quench_litres` 0.25 a square metre of its broadest face goes out
  (steam and a hiss, `FireFX.steam`) and keeps the rest as `wet`, with less its fire is knocked
  back; others are cooled to boiling and soak it up. A wet member's heat goes into drying it
  (`water_per_degree` 0.0007 l a degree-on-a-1-cm-board) and it can't pass 100 °C till it's dry;
  it dries in the air too (`evaporation` 0.002 l/s). Burning lamp oil isn't put out by water.
  `Events.doused(at, litres, put_out)` for whoever cares next (the bucket line). The fire's grid is
  brought up to date once a frame when water's thrown. New sounds `splash`, `fill`, `steam` (in
  `test_sounds`). `WeaponViewmodel.armed` (false for the bucket): townsfolk took it for a drawn gun
  ("Don't shoot!"). Dev bridge: `weapon bucket`, the weapon line says the litres. Tests
  `test_bucket` (5: fills at a trough and nowhere else; a bucket puts out most of a burning wall;
  wet boards hold off a fire beside them, 74 s dry against 89+ wet; oil burns on; nobody takes it
  for a gun). In the street (bridge): the store's front lit, filled at the trough, one throw from
  2.6 m put it out.
  - Known: the player carries a bucket always (no picking one up yet); water barrels and the
    water tower aren't sources; no bucket line yet (next); a burning person isn't put out by it.
- 2026-10-05 (gameplay): **The townsfolk carry water** (DESIGN.md §8 fire: bucket lines from the
  trough). `CivilianBrain`, fled and standing clear with a trough within `WATER_REACH` 40 m of the
  fire: joins group `bucket_runners` (at most `MAX_RUNNERS` 4; the first says `LINES.buckets`),
  walks to the trough's water on the fire's side (`_water_side`), fills only within 1 m of it
  (`_at_water`, crouched, `FILL_SECONDS` 1.5), takes it to `THROW_STAND` 2.2 m off the nearest
  burning and `douse`s it there (10 l), and back, till nothing's burning within 40 m (`LINES.out`);
  scorched, he drops it and flees; more than `PAST_SAVING` 40 members burning near the fire and he
  says it's lost (`LINES.lost`) and stays clear. Walking: a man stuck more than a second sidesteps
  1.2 m, one way then the other, up to three times (`_detours`), and `HumanBody._slide` (gameplay's,
  everyone's walking) no longer stops dead on a corner: if no slide moves him, it tries headings 45°
  and 90° either side and takes the furthest; and it steps out of anything it starts a hair inside.
  Tests `test_flee_fire` (+2: he carries water to it till it's out and stops; past saving he says
  so and carries none). In the street (bridge): the store lit inside, the storekeeper put it out in
  ~15 s and went back to his counter.
  - Known: no bucket drawn in their hands; each man runs his own bucket (not a passing line); only
    troughs are water; the gang doesn't help (they ride out).
- 2026-10-05 (gameplay): **Main Street to Sean's map, step 1: the layout as data** (Sean, with the
  map and the street picture: "we're using the map, so we need to change the layout", buildings
  "up on steps" as in the picture, the sun "right down the Main Street", mountains pushed out, "it's
  gotta match this art"; `docs/briefs/main-street.md`, gameplay's plan beside the art session's
  `docs/briefs/town.md`; Sean's answers passed to the art session). `config/town.json` +
  `TownLayout` (layout note above): nothing moved (every node's transform and every waypoint the
  same, checked old against new). Tests `test_town_layout` (2). Next: step 2, Main Street moved to
  the map (one saloon, the store beside it, the livery and jail across, raised boardwalks with
  steps), with the art session on the dressing and the goldens.
- 2026-10-05 (art session, later): **The bold style everywhere (Sean), its first cut behind M; the
  saloon's lamps; the town map.** Sean picked the street painting's bold squares for the whole
  game (DESIGN.md §4, shared: a paragraph). The street's target stays `street-golden-hour.png`;
  the saloon's is now `docs/concept/saloon-blocks.png` (the saloon painting redrawn in that
  style; `saloon-night.png` kept for the room's mood), in `tools/judge.py` and `tools/critic.py`
  (judge `--probes` keeps its two darkening probes for the street only). **M is now the bold
  look** (layout note above, still off by default, Sean's eye decides): the factory's textures
  cut again by `reduce.py --bold` (16 texels a metre, the grain's contrast doubled, 10–12
  colours a material, neighbours pushed apart; a material's `bold` dict in `materials.json`)
  into `assets/textures/bold/` (`PixelArt.bold`, `BOLD_TEXELS`), hard block edges
  (`BLOCK_SOFT` 0), far blocks kept at 4 px (`BOLD_MIN_SQUARE_PX`), the night's exposure 1.0
  (`src/art/bold_look.json`, applied under M by `LookPreset.apply_from_args`), and the sky
  drawn smooth under M. Judge v2 round `2026-10-05_r27` against the new targets: street 0.326
  → **0.304**, saloon 0.331 → **0.241** (today's default first; `_r19`–`_r26` are the trials:
  a sun at the street's end and warmer fills read pale, brighter nights blew the lamps).
  Blind critic `_r27` top three: the seated man's coat and arm smooth faceted slabs (his
  texture's squares are far finer than the bold style's: characters session, told), the
  street's lavender sky and small high sun (the Part A restore's gold sky is the answer, still
  Sean's call), the room behind him brown murk. Review sheet
  `docs/screenshots/review/2026-10-05_bold.png`. Also today, on the branch: the saloon's wall
  sconces throw pools (`SCONCE_*`, two under the balcony; judge level, `_sconces.png`), the
  M look judged at 960×540 (level), Sean's town map `docs/concept/town-map.png` and
  `docs/briefs/town.md` (one town on this map; four questions for Sean). Found: a look switch
  (M, I) kept the old look's wood materials and textures in caches, so the reloaded scene
  mixed looks; `PixelArt.reset_for_look()` empties them. Gameplay's files touched (said here):
  `src/world/oil_lamp.gd` (an `attenuation` export with a setter, default as before),
  `src/structures/wood_materials.gd` (`reset()`, five lines), `src/debug/look_preset.gd` (the
  bold preset under M, a dozen lines), `tests/test_pixel_art.gd` (the M test's expectations);
  shared `settings.gd` (my lines). 323 tests pass.
- 2026-10-05 (characters session, later): **The probe mosaic steadier: the frame multisampled
  and texel edges soft under V; its judge numbers corrected.** Sean: "keep working at it". Where
  its flicker was (`tools/probe_walk.py stability`, split by kind): about half on surfaces (the
  floor and ceiling boards seen at a slant, the bar front, the bottle wall), 45 % on outlines, a
  twentieth on glints, all from re-reading an aliased frame: a block takes the frame's colour at
  its middle, so a texel edge or an outline's stair-step jumping a pixel there flips the whole
  block. Under V the game viewport is now multisampled (`ProbeMosaic.MSAA`, 4x, put back when V
  goes off) and the textures' texel edges are soft (`Settings.PROBE_SOFT`, 1 px, the surface
  blocks' own trick). Unstable pixels a frame, still / turn / walk / strafe / circle / approach:
  V in build 535 0.12 / 0.75 / 0.96 / 0.75 / 0.84 / 0.60 %, **now 0.08 / 0.43 / 0.61 / 0.61 /
  0.51 / 0.33** (today's default 0.96 / 3.52 / 2.61 / 2.77 / 2.61 / 2.70; the surface blocks
  0.04 / 0.12 / 0.11 / 0.09 / 0.10 / 0.12; no mosaic 0.03 / 0.22 / 0.22 / 0.22 / 0.18 / 0.10).
  Turn / walk / strafe with one of the two: soft edges 0.64 / 0.85 / 0.78, multisampling 0.54 /
  0.72 / 0.74. Tried and dropped (with both on unless said): the block's middle on the surface's
  own plane, its normal from the depth round the pixel (the same flicker, but whole blocks flip
  together: 0.88 / 1.09 / 0.99 alone, 0.50 / 0.68 / 0.79 with both); a 2x2 mean 0.47 / 0.60 /
  0.73; a gentle blur (`prefilter` 0.5) 0.49 / 0.61 / 0.75; soft edges of 2 px 0.44 / 0.63 /
  0.70. A cross-fade that blends the old cube's colours into the new (`fade_blend`) took walking
  to 0.47, but walking you cross cells most of the time and every block goes soft while it
  blends: there, off. Pans (`pan_frames.gd`, flip-backs a frame, saloon / street): 3.05 / 4.19 →
  2.69 / 4.17. Cost: render CPU the same (7.96 / 4.25 ms); lavapipe's raster 1077 / 525 → 1363 /
  825 ms (the multisampling done in software; on a card it's the card's work, Sean's F3 tells).
  **Correction to the probe entry above:** its probe stills (judge rounds `_r9` and `_r12`, the
  variants scored with the judge, the review sheet's V panel) were rendered before the
  command-line fix, when `screenshots.gd --probe-mosaic` still drew the game's squared textures
  under the probe (Settings set the switch before the tool's setter ran, so the setter did
  nothing); renders here repeat to the pixel, and today's render of the same look differs from
  `_r12` on 4-5 % of pixels. The walk and pan numbers were after the fix and stand (re-rendered:
  identical). Judge v2, saloon / street: **V in build 535 0.181 / 0.341, now 0.185 / 0.341**
  (`2026-10-05_r28`); V over the squared textures (`--probe-squares`) 0.198 / 0.281, with the two
  fixes 0.204 / 0.309 and as steady as V now (0.47 / 0.60 / 0.63; without them 0.84 / 0.97 /
  0.84); today's default 0.225 / 0.329; the surface blocks 0.362 / 0.284 (0.198 / 0.279 lit the
  ordinary way). So V is the closest to the saloon painting and the furthest from the street
  one; over the squared textures it nears M on the street, but his face loses its eyes there
  (his squared paint under the probe's blocks; the smooth paint keeps one eye's white and iris),
  so V stays on the smooth set. History lines `_r9`/`_r12` say so; the review sheet
  (`docs/screenshots/review/2026-10-05_probe_mosaic.png`) is redone with V now and the corrected
  table. Blind critic on `_r28` (`critic/critic.md`), top three: the street isn't lit by a
  setting sun (a lavender-grey sky, its sun a small white glare by the roofs); the room behind
  him is dim, half-empty murk; the saloon's front is in dull shade and its sign can't be read
  (then his face, a blotchy orange smear with sleepy eyes, and the glossy, streaked table).
  Also: `--probe-mosaic` on the command line now wins over a saved look, as `--blocks` and
  `--quantise-once` do. Trial flags `--probe-msaa=0|2|4|8`, `--probe-soft=px`,
  `--probe-squares`; `probe_walk.gd` `--global=`, `--msaa=`. Files: the art session's
  `src/render/` (`probe_mosaic.gd(shader)`, mine, said here), shared `settings.gd` (the probe's
  lines, and the command-line rule), `tools/probe_walk.gd`, `tests/test_probe_mosaic.gd`,
  `docs/screenshots/judge/history.md` (my two lines' notes). 346 tests pass.
- 2026-10-05 (gameplay): **Main Street to Sean's map, step 2: the street moved** (Sean: "we're
  using the map", "up on steps" as in the street picture, "it's gotta match this art";
  `docs/briefs/main-street.md`; the art session agreed the dressing is carried mechanically and
  judged after). `config/town.json` (layout note above): the saloon (the real one) and the store
  side by side on the south side (fronts z 0, the street's sunset end to the west), the barber and
  past Market Street the hotel; the livery, the jail, the water tower behind it and the assay
  office across; Freight Street at the east end; the range 30 m further east; the façade saloon,
  the façade store and the eating house are gone (one saloon; the eating house isn't on the
  map). The store is 9 m wide with the façade's GENERAL STORE look (`set`). Floors stay 0.38.
  **Steps:** `Boardwalk.steps` (flights of blocks a riser each, members, an invisible ramp over
  their noses for the player; with steps no ramp along the rest of the edge), each building's
  walk with a flight; `Waypoints` go by the steps (`*_front`, `*_steps`, `*_landing`) and the
  store's and saloon's porches join along the walk; `Waypoints._walkable` also refuses a sudden
  rise in the ground (`STEP_UP` 0.25), so the player is routed by the steps (townsfolk could
  step the edge; they're routed the same). The gang rides in from x −50. A harassing man has
  something to say soon after he arrives (the drink's quiet doesn't carry over: the store is next
  door now). **Art's files, agreed with it** (said here): `src/art/street_dressing.gd` (façades and
  their walks from the layout; its old-coordinate tables carried with each building,
  `TownLayout.carry`; whatever would stand on steps or in a doorway left out, folk moved aside
  against the wall, `on_steps`, `out_of_doorway`, `post_of`), `src/art/shot_match.gd` (the set in
  the saloon's space: `TABLE_IN_SALOON`, `ROOM_YAW_IN_SALOON`); gameplay's `street_scenery.gd`
  lost its M0 props and fence (the fence stood in the saloon). Shared `tools/screenshots.gd` (my
  lines: `_view_move`, the store's, saloon's and range's views move with them). Tests placed
  relative to what they test (town day, gun range, outlaw tactics, dynamite: thrown from the walk
  beside the store's door, it sailed in at the door from in front of it), `test_steps` (4). All
  goldens re-approved. 350 tests pass. For the art session (told): the saloon's door faces north
  now (the moon's arc is on the other side: `moon_tilt_degrees` −78), the dressing to lay out
  again in each building's space, StreetMatch's framing, the backdrop and ground pushed out.
  - Next: step 3, the telegraph, doctor and bank, the well behind the jail (a water source), the
    corral.

- 2026-10-05 (gameplay): **What hangs on a wall comes down with it** (Sean: "have we fixed lamps
  and stuff floating in air after the wall they were attached to burn down?"). `Fittings` (layout
  note above, a node at the end of `scenes/test_street.tscn`): 146 fittings in the street (22
  sconces, the bottles and lamps of the back bar, pictures, the stag, chairs and tables on floors,
  barrels and lanterns on the walks, the porch lanterns), none falling at load; with every member
  of the saloon burnt away, 68 come down, none under the ground. A lit lamp landing hard smashes
  and spills its oil, so a burning building's lamps spread its fire. Tests `test_fittings` (3: a
  lit lamp on a wall falls when the board goes, breaks and spills; a barrel on the ground is left
  alone; the street's lamps and sconces are found). `test_dynamite`'s throw at the store now asks
  that it lands at the front and breaks things there: on the raised walk the siding breaks or not
  by where the stick comes to rest (0 to 23 timber in trials, with or without fittings; the
  siding's own test covers the boards). Merged with step 2 (both moved the same goldens): from
  two full `--fresh` runs, `porch_collapse` re-approved (it lands differently with what was on it
  falling too), `store_fire_later`, `texel_porch` and `outlaw_open_close` (a hair past their
  tolerance on the new street) and `gun_smoke_saloon` (its smoke flapped between the two runs:
  tolerance from that, mean 14.7); every view passes against both runs; visual checks 367, none
  failed. 353 tests pass.
  - Known: fallen fittings aren't saved; painted signs are their sign member's own and go only
    when it does; a fallen lamp's light stays lit unless it breaks.
- 2026-10-06 (art session): **The saloon's front to the street painting, on the branch, not merged**
  (Sean: "it's not just the pixels, it's the buildings' textures and detail"; then "keep working
  the wood", "get the saloon perfect", "ruts and windows"). `FacadeArt` (`src/art/facade_art.gd`,
  called at the end of gameplay's `FalseFrontBuilding.build()`, one line, said here) dresses a
  front that asks for it (`"facade": "saloon"|"store"` in `StreetDressing.BUILDINGS`): corner
  posts, a deep cornice on brackets, the framed sign lettered square by square
  (`tools/textures/letter_sign.py`), a heavy door surround, louvred batwings, two hung lanterns
  that glow, the dark room through the door, windows (casings, sill, pale bars, the panes drawn
  by `tools/textures/draw_glass.py`: dark glass, the sky along the top, lamps in two panes, on a
  quad under the glass member's mesh, so it goes when the glass is shot out), thick porch posts
  with knee braces, a fascia, two wanted posters (`draw_posters.py`) and a spittoon. **Wood
  drawn square by square** (`tools/textures/draw_boards.py`: each board a strip in the
  painting's colours, its squares two to six long along the grain, `assets/textures/drawn/`),
  laid at 32 a metre (`PixelArt.DRAWN_TEXELS`; `timber`, `store_boards`, `saloon_red` in every
  look, the rest under M), and the seam between boards a screen-space line with a lit lip
  (`texel_grid.gdshaderinc` `seam_px`, a global set under M). **The road under M** drawn the
  same way (`draw_road.py`): pale dust, stones, the most used wheel track under the street
  shot's feet; `ground.gdshader` `keep_tracks` keeps a drawn tile's ruts where the 2 m tile
  shows through. **The sky under M** (`sky.gdshader` `gold`, `bold_look.json`): a deeper top,
  more cloud, warm bodies with blue-grey bellies. Pictures `docs/screenshots/review/
  2026-10-06_*.png`. Tests pixel_art, loads, props, ballistics, town_day pass.
  - Not merged: the facade parts and the three drawn woods show in the default look too, so the
    merge waits on Sean's yes, with goldens re-taken. Still off against the painting: its
    windows have more, smaller panes with brighter reflections; its road has more dark squares;
    the other fronts (store, livery, jail) have the parts but not yet the painting's look.
  - Later (Sean: "get the saloon perfect so we have a model for the rest"): a porch railing, a
    beam along the wall and joists under the porch roof, shadow-only panels at the porch's ends
    (the low sun ran in along the porch), the room through the door drawn
    (`draw_doorway.py`), brown window frames with 2×4 slate panes and amber lamplight, a halo
    painted on the wall behind each lit lantern (`StreetDressing.lantern_halo`), timber a
    weathered mid brown and the red boards darker and worn to grey in patches (measured against
    the painting's posts and walls). `tools/facade_lab.gd`'s painting view now stands in the
    street as the painting does. Picture `docs/screenshots/review/2026-10-06_saloon_vs_painting.png`.
  - Later (Sean: "Yes do that", on the gameplay session's Main Street step 2): **the saloon front
    moved onto the real saloon** (main merged in). The street painting's front is now the
    `Saloon` itself (the separate `StreetSaloon` is gone with main's move): `facade` and
    `porch_height` are properties of `FalseFrontBuilding` (gameplay's file, said here: the
    porch's beam, ledger and lantern at `porch_height` + the old offsets, default 3.0 as before);
    `saloon_building.gd` `_init` (gameplay's) takes the painting's red front, 8.4 m front, the
    sign from 4.3 m and a porch at 3.75 m over the tall door (the moonlit doorway still shows from
    inside); `config/town.json` (gameplay's) gives the store `facade` "store" and its drawn
    boards. On a saloon people walk into, FacadeArt draws the batwings with no collision (solid
    leaves kept the gang from the store); the end porch posts are the building's own, resized in
    place before supports are inferred (the F11 test still breaks `store/porch/post0`); nothing
    of a front reaches past its ends (the buildings stand wall to wall now). The street shot's
    feet and look are the saloon's (`StreetMatch.feet()`/`look()`), the porch folk and bench on
    its porch, the lanterns either side of the real door, the grass in clumps. All tests pass:
    `test_chaos`'s same-seed test split two ways here when run after another chaos run (a stick
    at the store/saloon junction took the saloon's west wall or its window trim); the gameplay
    session now runs each seed in a Godot of its own (main 6cfff79, merged in). Still not merged: waits on Sean's yes, with goldens re-taken. Open with Sean:
    the backdrop's near ring is 260 m out and nothing in the new town comes near it; pushing it
    out would shrink the mountains below the painting's, so it stays.
  - Later (Sean: "Raise up the saloon, have stairs down on the board walk to connect down to the
    other store"): **the saloon up its steps.** Its floor and walk are 0.78 m (four steps up from
    the street, as the street painting's; `config/town.json`: the Saloon's `floor_top`, the
    SouthBoardwalk's `top`), the store's stay 0.38, and the saloon's walk steps down two treads to
    the store's at its west end (`Boardwalk.end_steps`: blocks from the ground, the first level
    with the walk below, an invisible ramp, a board closing the walk's end under its planks, no
    old end ramp there). `SaloonBuilding.build()` lifts its walls, porch, sign and front by the
    floor's rise (`BASE_HEIGHTS`), so the room and front keep their proportions. Found on the way:
    a walking man's feet were kept down by one ray, which now and then fell through the gap
    between two planks or floorboards; on the old 0.38 m walk he hopped back up, on a raised one
    he was stuck under it (the gang never reached the bar). `HumanBody._snap_to_ground` casts five
    rays a few centimetres apart and takes the highest. Gameplay's files touched, with Sean's
    ask and told to it: `boardwalk.gd` (`end_steps`, `_ramp`'s `base`), `saloon_building.gd`
    (`build()`), `false_front_building.gd` (window sills above the floor, not the ground: the same
    at 0.38), `town_layout.gd` (one line: `end_steps` read as Vector2s), `waypoints.gd` (the
    saloon's places at its own floor, `store_walk_east`/`saloon_walk_west` over the steps),
    `human_body.gd` (the snap), `config/town.json`, tests `test_steps` (+1: up and down the end
    steps), `test_town_day` and `test_town_layout` (the saloon's floor). Mine: the porch folk,
    bench, lanterns and carried dressing go up with the walk (`StreetDressing.walk_lift`), nothing
    stands on the end steps or a metre of the store's walk before them, FacadeArt's windows above
    the floor, ShotMatch's floor ray, `tools/screenshots.gd`'s saloon views lifted. Picture
    `docs/screenshots/review/2026-10-06_saloon_raised.png`. 355 tests pass. Not merged (with the
    saloon front, on Sean's yes).
