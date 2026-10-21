# Salt Creek — layout reference (read the section you need)

Moved here verbatim from CLAUDE.md's "Commands and layout" on 2026-10-11 so sessions don't load
it on every turn. CLAUDE.md keeps the command block and a one-line index per subsystem; the detail
lives here. **Read only the section a task touches** (grep for its heading). When a system
changes, update its section here (not CLAUDE.md). "Layout note" in a commit or status entry
means a section of this file.

## Contents

- [The dev bridge](#the-dev-bridge)
- [The playtest](#the-playtest)
- [The tour video](#the-tour-video)
- [Bug reports](#bug-reports)
- [The soak](#the-soak)
- [Feel ranges](#feel-ranges)
- [The smoke test](#the-smoke-test)
- [The visual checks in CI](#the-visual-checks-in-ci)
- [src/autoload](#srcautoload)
- [src/render (the per-texel look)](#srcrender-the-per-texel-look)
- [The look panel](#the-look-panel)
- [src/main (the pixel pipeline)](#srcmain-the-pixel-pipeline)
- [src/player](#srcplayer)
- [src/world](#srcworld)
- [src/world/town_layout.gd + config/town.json (the town's layout)](#srcworldtown_layoutgd--configtownjson-the-towns-layout)
- [src/structures](#srcstructures)
- [src/fire](#srcfire)
- [src/bodies](#srcbodies)
- [src/people](#srcpeople)
- [src/weapons](#srcweapons)
- [src/blast](#srcblast)
- [src/art/shot_match.gd (the saloon painting's shot)](#srcartshot_matchgd-the-saloon-paintings-shot)
- [src/art/street_match.gd (the street painting's shot)](#srcartstreet_matchgd-the-street-paintings-shot)
- [The texture factory (tools/textures)](#the-texture-factory-toolstextures)
- [src/props/prop_models.gd](#srcpropsprop_modelsgd)
- [src/art/saloon_dressing.gd](#srcartsaloon_dressinggd)
- [src/art/sign_art.gd and the backdrop](#srcartsign_artgd-and-the-backdrop)
- [Characters by image-to-3D (tools/characters)](#characters-by-image-to-3d-toolscharacters)
- [Training the image model on our style (tools/style)](#training-the-image-model-on-our-style-toolsstyle)
- [tools/blender (the people pipeline)](#toolsblender-the-people-pipeline)
- [addons/saltcreek_native (the native plugin)](#addonssaltcreek_native-the-native-plugin)
- [tests](#tests)
- [CI](#ci)

## The dev bridge

**The dev bridge** (`src/debug/dev_bridge.gd`, `tools/bridge.py`): drive the running game from a
session or a script. Only in a debug build started with `-- --dev-bridge` (never in an export);
listens on 127.0.0.1:8737; one command a line, one JSON line back, in order (a command that takes
game time answers when it's done). `python3 tools/bridge.py start` runs the game under xvfb with
the Vulkan renderer so screenshots work (`--size=960x540`, `--headless` for no drawing, `--fps=N`
for a fixed step, `--movie=OUT.avi` records it all with sound through Godot's Movie Maker, 30 fps on game
time; its log in `build/bridge/godot.log`); `stop` quits it; `run FILE` does start, the
file's commands, stop. `help` lists the commands: `screenshot PATH`, `camera X Y Z TX TY TZ [FOV]`
(a free camera; `camera player` back), `goto X Y Z [YAW]|PLACE`, `look X Y Z|PERSON|PLACE`,
`turn DEG [PITCH]`, `walk X Z|PLACE|PERSON [run]` (routes round buildings to a place), `press
ACTION [S]`, `hold`/`release`, `weapon revolver|shotgun|dynamite|none`, `shoot [N]`, `wait S`,
`time H`, `clock SCALE|off`, `smoke [X Y Z]` (each burning building's smoke field, or how thick
it is at a point), `set`/`get ADDRESS` (a look value: `settings.mosaic`,
`global.min_square_px`, `env.glow_intensity`, `day.exposure_night`, `hour`; `LookPreset`), `preset
FILE`, `spawn outlaw|townsman X Y Z`, `gang`, `fight [NAME]`, `dynamite X Y Z [FUSE]`, `ignite [X Y
Z]`, `read frame|player|people|look|places|counts|all` (people: `arrested` following|waiting), `events [N]`, `quit`. Facing is degrees
from north (−Z, the livery's side of the street; the saloon's is +Z), east +X. Example:

```sh
python3 tools/bridge.py start --size=960x540
python3 tools/bridge.py "time 17.6" "goto street_east" "look saloon_porch" "screenshot /tmp/a.png" \
    "gang" "wait 20" "fight" "weapon revolver" "look brody" "shoot 2" "wait 3" "events 20" "read people"
python3 tools/bridge.py stop
```

**A lab's own commands** (`src/debug/bridge_lab.gd`, `docs/briefs/labs.md`): a lab folder
`experiments/<lab>/` may hold a `bridge.gd` extending `BridgeLab`, with its commands in a `HELP`
constant (name -> help line) and a `_cmd_<name>(a: Array) -> Dictionary` for each (it may await
`seconds(S)`; `player`, `street`, `person(ID)`, `log_event`, `vec`, `arr` come from the bridge).
The bridge loads every lab's file at start (folders in name order), lists them in `help` (with
`labs`: each lab's commands, or what was refused) and refuses a name the bridge or an earlier lab
already has. Labs never edit `dev_bridge.gd`. Test fixtures: `tests/labs/`. Labs with commands:
`breakage_lab` (`breakage`, `breakage_list`, `breakage_aim`; its README).

## The playtest

**The playtest** (`tools/playtest.md`, its instructions; `tools/playtest.py start|shot NAME|stop`):
a fresh sub-agent that hasn't read the code plays the game through the bridge (it's told not to
open the code or the design) and writes `docs/playtests/<date>.md` with its screenshots in
`docs/playtests/<date>/`: what broke, what was flat or confusing, what was fun, the top three.
Start it with the Agent tool: "read tools/playtest.md and follow it; don't read the code".

## The tour video

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

## Bug reports

**Bug reports** (`src/debug/bug_recorder.gd`, `BugRecorder`, in every build; **F12**, controller
Back + Y; debug ignite is L only now): the recorder notes every action's changes and the mouse's
turns by physics tick, everyone's place each second and a snapshot every 30 s; F12 writes
`user://bug_reports/<date-time>.saltbug` (a zip: `report.json` with the build, clock, you, everyone,
settings and the last things that happened; `recording.json`; `godot.log`; `screenshot.png`).
`godot --headless --fixed-fps 60 -s res://tools/replay.gd -- FILE.saltbug [--out=DIR]` plays it back
(from the start for a session under 20 minutes, else from the snapshot 30 s before) and says where
anyone went more than 0.25 m from the recording; exit 1 if anyone did. Drawn (xvfb), `--out` saves
its last frame beside the report's screenshot.

## The soak

**The soak** (`tools/soak.gd`, `.github/workflows/nightly.yml`, every night at 09:17 UTC and by
hand): `godot --headless --fixed-fps 60 -s res://tools/soak.gd -- --minutes=240 --out=build/soak`
runs the street for hours of game time flat out (~3.4x real time here) with the clock at 30x: the
gang rides in whenever it's gone, one of them picks a fight every 5 minutes, a fire and a stick
twice every 100 minutes. Fails on any error, memory or nodes still climbing, orphan nodes,
anyone stuck a minute on his way somewhere, anything under the ground or off the map, or the frame
time creeping (the last 5-minute window's median over 3x the first's). `soak.md` is the run's
summary and an artifact. Each problem is also printed as it's found (`soak problem, <kind>: ...`,
lost bodies with their path, script, rubble members and speed; stuck men with where they are and
where they're going) and each window prints the process's resident memory, so a run the runner
kills still leaves its log; past 6 GB resident it stops early and reports. A frozen game prints
nothing, so it writes the game clock to `build/soak/clock.txt` every 600 frames; the workflow runs
it in the background into `build/soak/soak.log`, and with that log quiet 10 minutes writes
`frozen.md` (the clock a minute apart, every thread's state, wait channel and gdb backtrace, five
samples of the main thread) to the log and the summary, sends SIGSEGV for the GDScript backtrace
and fails. `--hang-at=S` hangs it on purpose to try that. (An in-process watchdog thread was tried
and never started on the CI runner: the workflow does it.)

## Feel ranges

**Feel ranges** (`config/feel_ranges.json`, `tests/feel.gd`): the numbers that make the game feel
right, each measured by a test and held to a range agreed with Sean. `Feel.within(test, key,
value)` fails the test when the number's out of its range, saying the range only moves with
Sean's OK (change min/max and add a line to `history` with the date and his words; a range marked
`proposed` was set from the game as it measured and still waits for his OK). Measured: body hits to
stop a man (`test_gunfight`), the shotgun at 20 m (`test_shotgun`), the store's roof falling in
(`test_fire`), the outlaw's hit rate at 5/15/30 m, the duel's stand-off and the gang's back-down
share (`test_feel`), the guns' kick: rise, top, settle, the climb that stays, shot-to-shot
spread (`test_gun_feel`). CI prints every number against its range in the test run's summary.

## The smoke test

**The smoke test** (`src/debug/smoke_test.gd`, `SmokeTest`; `-- --smoke-test [--smoke-out=FILE]`
on any build, a release export included): 30 s of the street (the gang in, a stick on the range, a
member alight, a shot), every error counted by a Logger, then `[smoke] ok ...` and exit 0, or
`[smoke] FAILED` with the errors and exit 1. Drawn, its clock starts at the first frame on
screen, and each event waits for a few frames after the last; on the desktop it fails if the native
plugin isn't loaded. In `build.yml` the export job no longer releases:
`smoke` runs each export on its own runner (Linux headless and drawn under lavapipe at 640x360,
Windows, macOS, all headless), and only then `release` (the GitHub Release) and `pages`.

## The visual checks in CI

**The visual checks in CI** (`.github/workflows/visual.yml`, every night at 06:43 UTC and by
hand): every fixed view rendered twice under xvfb and lavapipe on two runners at once (~1–2 h
each), then `tools/scene_probe.gd`, `tools/golden_check.py --from=A` and `tools/visual_checks.py
--from=A --twin=B --probe=P` (the art session's tools, layout notes above). Red on any failure;
the run's summary lists what failed and the artifact `visual-report` holds golden | render |
difference for each. Rendered with `--fresh` (`screenshots.gd` loads the scene again before every
view, as `golden_check.py --render` does), so no view carries the one before it and `--only=` of
a few views renders them as the full run does.

## src/autoload

- `src/autoload/` — `Events` (the event bus), `Settings` (user://settings.cfg), `Controls` (the input
  map, built in code: keyboard/mouse and controller).

## src/render (the per-texel look)

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
  **Surfaces to the man** (roadmap 1.4, 2026-10-15): the world's near surfaces in the portrait
  man's squares (his face and coat, 36-48 a metre). The game's woods are drawn in squares of 4 of
  C's 128 texels, 32 a metre (`grain_woods.py` `squared`, `woods_grain.json` `squares`: a square's
  dark-weighted mean, specks under a square left out, snapped to the board's tones; ends in squares
  of 2), and `texel_grid` `square_texels` / `end_square_texels` (`PixelArt.WOODS_SQUARE`;
  not the table's drawn top, finer in the painting) reads each whole (`tile_block_sample`: the mip of
  its size) and lights it as one. `tools/surface_squares.py` measures square size and finish crop by
  crop (`surface_squares.json`) and makes target | before | now sheets.
  **The main street** (`docs/briefs/road.md`, Sean's road target, 2026-10-16): smooth painted earth
  to the boardwalks, no squares. `tools/textures/draw_street.py` draws its map from `config/town.json`
  (`assets/textures/street/street_map.png` + `.json`: R churned vs packed, G the wagon ruts' height
  the street's length at a wagon's gauge, depth and wear varying, A where stones lie; imported as
  data, no alpha-border fix) and the old prints' list and decal pictures. `ground.gdshader`'s street
  path (`use_street`, `PixelArt._street`): two painted earths (`road_compact`, `road_loose`, the
  texture factory's, each with `_height`) blended by the map, the earths' relief and the ruts lit
  pixel by pixel, rut troughs dark and lips lit, a short shadow trace toward the sun; the squared
  ground past the map (the drawn road at 32 a metre, squares square on screen, `tile_square_screen`).
  `RoadStones` (`src/art/road_stones.gd`): faceted rocks along the ruts' lips, one MultiMesh;
  `RoadPrints`: old horseshoe and boot prints as Decals, `press()` for gameplay's fresh ones.
  Fixed views `road_low_golden` / `road_low_noon` look down the ruts as the target does.
  Still lit smoothly (StandardMaterial3D): guns, lamps, `PropLibrary` props, effects.
  **Light with range** (`docs/ART_REVIEW.md` §3.1, §8.1): the night room is dark
  (`ambient_energy_night` 0.7, the saloon's `night_ambient` 0.035, `exposure_night` 0.72) and lit by
  its lamps; only true emitters bloom: the chimney glass is drawn well over display white round
  the flame (`chimney_glass.gdshader` `bloom`), the moon at 2.5, and the environment's glow
  (scene file, lighting lines) is screen-blended at threshold 1.7 with `glow_bloom` 0 (any bloom
  share veils the whole frame), so nothing lit by a lamp blooms. The review's light numbers
  (median L*, deep-shadow and highlight shares, chroma–L* correlation) are the check, not the
  judge's score, until judge v2.

## The look panel

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

## src/main (the pixel pipeline)

- `src/main/main.gd` + `scenes/main.tscn` — the pixel pipeline: world renders in `GameViewport`
  (SubViewport at `Settings.internal_resolution`, 1280×720 default), drawn to `Screen` with nearest
  filtering.

## src/player

- `src/player/` — controller, visible body, tuning resource (`config/player_tuning.tres`),
  `PlayerComposure` (flinch, rattled, winded; the guns read `sway_scale()`/`extra_spread()`).

## src/world

- `src/world/` — `DayCycle` (clock + sky; `config/day_cycle.tres`), sky and ground shaders, oil lamps,
  placeholder scenery.

## src/world/town_layout.gd + config/town.json (the town's layout)

- `src/world/town_layout.gd` + `config/town.json` — **the town's layout** (docs/briefs/main-street.md):
  `TownLayout`, the street's first child, places the nodes the file names (by path: the store,
  saloon, boardwalks, rail, trough, markers) before anything builds; an entry `in` a building is
  in its space and moves with it. `TownLayout.transform_of(path)` / `point(building, local)` give
  the same places to code with no scene (`Waypoints.test_street()` puts the store's and saloon's
  insides through it). Move a building: change its entry. Since Main Street step 2 the file is
  Sean's map (`docs/concept/town-map.png`): Main Street along X, west −X toward the sunset; the
  south side (fronts on z 0) from the east the saloon, the store, the barber, Market Street, the
  hotel; the north side (fronts on z −16.8) the livery, the jail, the water tower's yard, the
  assay office; Freight Street crossing at the east end, the range 30 m beyond. Since step 3 also
  the telegraph (between the store and the barber), the doctor's (past the barber), the bank
  (across Market Street from the hotel), the well and windpump with its stock tank behind the jail
  and the corral behind the livery. A building's
  boardwalk is up on steps (`Boardwalk.steps`: people and the player come and go by them, the
  edge elsewhere a step too high). `StreetDressing/<name>` entries are the dressing's façades
  (it builds them where the layout says, each with its walk). A building's `was` is where it
  stood on the old street: `TownLayout.carry()` moves what was laid out round it there (the
  dressing's tables are still in old coordinates) to where it stands now, and the dressing leaves
  out whatever would stand on steps and moves people out of doorways
  (`StreetDressing.on_steps`/`out_of_doorway`); `tools/screenshots.gd` moves its store, saloon
  and range views the same way (`_view_move`).

## src/structures

- `src/structures/` — `Structure` + `StructureMember` (members with IDs, kinds, support tiers and an
  inferred support graph; `settle()` breaks/drops what can't stand, rubble), `StructuralAnalysis`
  (loads down the graph, compression/buckling/bending/joint checks; `config/timber.tres` via
  `TimberTuning`), `FalseFrontBuilding` (shape options: two-storey fronts with `sign_from`, a barn's
  `gable_front` + `loft_door` + `gable_sign`, `batwings`, `window_bars`, `porch`, `furnished`,
  `interior`: store, telegraph, doctor, bank: each furnished in members, with its lamps),
  `Boardwalk`, `HitchingRail`, `WaterTrough`, `Well` and the windpump's tank (group
  `water_source`, as the trough: a bucket fills there), `Windpump` (its wheel turns; drawn, not
  members), `Corral`. Wood `iron` (the bank's safe, the windpump's rod and pump): a ball stops on
  it and glances off as metal, it doesn't burn, it isn't carved. A structure draws its untouched members as one mesh
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

## src/fire

- `src/fire/` — `FireSystem` (member temperatures, heating by contact/radiant/flame plume, ignition,
  char, ash, spilt lamp oil, scorching people, water: `douse()` puts out and wets members, a wet one
  dries before it heats (`StructureMember.wet`); `fire_near()`/`burning_map()` for people getting
  clear; `config/fire.tres` via `FireTuning`), `FireFX` (flames, smoke, steam,
  `char_overlay.gdshader`). `tools/fire_timeline.gd` measures how fast a fire grows.
  **Smoke that knows the buildings** (`SmokeField`, docs/briefs/smoke.md): FireSystem puts a box
  of half-metre cells round each burning building (up to `smoke_fields`), from the ground to 9 m
  over its top and 3 m past it, square to the world and offset 0.13 m off round numbers (a wall on
  a round coordinate falls inside one layer of cells, not two); its members are drawn into the
  cells (a member blocks smoke; burnt away, broken or shattered, it doesn't) a slice a frame, again
  every 2 s; each burning member puts `smoke_per_m2` of its broadest face a second into the open
  cells round it (both faces of a wall). The native `SmokeGrid` (`smoke.rs`) steps it 15 times a
  second on a worker thread (`step_async`): hot smoke rises into the cell above while there's
  room (a cell holds 1), so a room fills from the ceiling down; smoke that can't rise runs toward
  the nearest way up (each cell's distance to open sky or the box's edge, a search made when the
  solids are set: the ceiling jet), so it runs along under a porch roof to its edge and climbs, and
  in a room gathers by the wall with the door till it's down to the lintel and spills out; it
  spreads faster under a ceiling; cells open to the sky drift with the wind (`SmokeTuning.wind`,
  the gun smoke's); it thins, faster in the open. Drawn as one `FogVolume` per field with the
  smoke as a 3D density texture (`smoke_draw_density` at a full cell, `smoke_colour`), so the
  volumetric fog lights it (the art session's to judge). `FireSystem.smoke_at(p)`, `smoked(m)`;
  members in a field have no particle smoke (`FireFX.refresh(..., smoke)`). No plugin (web) or
  the Compatibility renderer: the old particles.

## src/bodies

- `src/bodies/` — `Anatomy` (config/anatomy.json, generated by `tools/anatomy/build_anatomy.py` —
  edit the script, not the JSON: segments, bones, arteries, organs, fingers; traces a
  bullet through them), `Physiology` (blood, bleeds, shock, pain, adrenaline, breathing;
  config/physiology.tres), `HumanBody` (segment hitboxes, meshes, clothes, wound decals, ragdoll:
  parts weighed by `MASS_SHARE` (Winter/Dempster), self-colliding hands included, wrists and
  ankles damped; muscle tone as he goes, capped by each pair's inertia about the joint, `TONE`;
  killed outright, an instant of it; dead or on one foot, the stance leg held `TONE_STANCE`
  harder; a ball that drops him alive curls him round it, `_hunch`, and on the move he stumbles
  on a step first (`_knocked`, `stumbling`: brains stand back); his legs go
  on at his hips' speed, the stance leg turning about its planted foot (the gait's skate left
  out); the neck, hands and feet turn with `INERTIA_SCALE` times their inertia; parts only resting
  on each other as he goes collide (`_keep_apart`, `_rejoin_apart`); a blow puts him down only by
  its push (`take_blow`, `knockdown_speed`), a blast throws along its line, a torn limb takes its
  own push (`_limb_throw`); hit and still up, he favours the wound as it comes on (`_favour_step`:
  a leg, an arm, the body; `favour_pace()` slows `walk_to`); Jolt at 20 velocity / 8 position
  steps in project.godot; the lab is `experiments/physics_lab/`, `tally.py` sums a run),
  `OutlawBrain` (fear/nerve; tactics OPEN/MOVING/HIDDEN/PEEKING; flees, tends himself,
  surrenders), `Cover` (finds hiding spots against a threat by rays: ring samples + "shadows"
  behind whatever the threat's sight lines hit; `Cover.search()` spreads it over ticks),
  `Layers` (physics/render layer bits),
  `PeopleBodies` (loads `assets/people/<id>.glb` — the MakeHuman body — and cuts it into
  per-segment pieces like BodyMesh; `HumanBody.body_model`, empty = BodyMesh),
  `BodyInterior` (insides built from the anatomy when a part opens; `shaders/body_skin` and
  `body_inside` cut wound openings, `wounds.gdshaderinc`). `body_skin`'s light pass holds the sum
  of a person's lights under `light_cap` × his own colour (top channel; `light_knee` where it
  starts easing), painted or not; `tools/face_light.py` (with `screenshots.gd --face-probe`)
  measures a face's light ÷ its paint.

## src/people

- `src/people/` — `Senses` (per person: sight cone + light + line of sight + movement/crouch;
  hearing via `Events.noise`; `known[who]` last seen/heard), `Relations` (per person towards each
  other: pressure, grudge, fear, stance on the ladder IGNORE…FIGHT; `Relations.WEIGHTS` per deed),
  `DeedWatch` (turns shots/deaths/surrenders/speech into `Events.deed` and `Events.noise`),
  `PlayerDeeds` (your draw/holster/aim_at/crowd/stare/shout/call_out deeds), `Waypoints` (named
  places + links, `route()` / `route_to_point()`; `test_street()` defines the street, store and
  saloon), `CivilianBrain` (unarmed townsfolk at a post: hands up, cower, thanks), `TownLife` (the
  test street's people: storekeeper, barkeep, and the gang with a day's `agenda`; U brings them in).
  `OutlawBrain.agenda` steps: go, wait, drink, harass, call_out, duel, leave. `BucketLine`
  (a bucket brigade, one a water source, `bucket_lines`): the townsfolk fighting a fire stand along
  the way from the water to a spot a couple of paces off the nearest burning (`_stand_by`: of eight
  round it, one a man can stand on, nearest the water), re-laid every 3 s; buckets are drawn things
  (a pile by the water, one for every two men), filled by the man at the water, handed up full and
  back empty (`PASS_REACH` 1.4 m arm to arm, walked across wider gaps; a full and an empty meeting
  swap), thrown by the man at the end (`FireSystem.douse`, 10 l); a man only takes one at his
  place, and one who can't reach it in `GIVE_UP` 30 s drops out. Townsfolk who see a fire within
  `CivilianBrain.FIRE_SEEN` 30 m come to fight it. `Crew` (per man:
  his friends in a fight as he knows them, from what he saw and `Events.callout`s he heard:
  reloading, hit, spotted, flank, covering, help, drag, down, dead, quit, fall_back, give_up).
  After a fight: a man who's lost you gives up looking `OutlawBrain.HUNT_GIVE_UP` (30 s) after he
  last saw or heard you, goes for a friend down only while you're about (`RESCUE_WHILE_KNOWN`),
  and rides out (a `leave` step isn't held up by being wary, only by a warning or worse). A man
  down with his legs gone gives himself up to a man he's against within `GIVE_UP_HEARD` 4 m (or 8
  seen). The shout key in arm's reach (3 m) of a man who's given up arrests him
  (`PlayerWounds._arrest`, `OutlawBrain.arrest`, `Events.person_arrested`): `hands_bound`, he
  follows a few steps behind; shouted again, he waits (again, follows). No jail yet.

## src/weapons

- `src/weapons/` — `WeaponViewmodel` (what every gun in hand shares: tuck, shot line, camera),
  `RevolverViewmodel` + `RevolverState`/`RevolverModel`, `ShotgunViewmodel` + `ShotgunState`/
  `ShotgunModel` (`config/shotgun.tres`). `Player.weapons`/`weapon`/`select_weapon()` switch them.
  `GunKick` is the kick: a damped spring shoved by each shot (it rises over `kick_rise`, comes back,
  dips and settles), one on the gun and one on your view (`WeaponViewmodel._kick_shot`), its dials
  in each gun's tuning; what's left of it when you fire again turns the shot. `tests/test_gun_feel.gd`
  measures it (and the rhythm, reload, sway) frame by frame against the feel ranges.
  `Ballistics.fire_charge()` flies a shotgun charge as separate pellets. `DynamiteViewmodel` is the
  stick in hand. `BucketViewmodel` (4) is a water bucket: R fills it at a `water_source` (troughs),
  LMB throws it as drops on their own arcs, each handed to `FireSystem.douse()`; `armed` false (a
  held thing people don't take for a weapon: PlayerDeeds, the shout, OutlawBrain).

## src/blast

- `src/blast/` — `Blast` (Kinney-Graham overpressure/impulse by scaled distance, reflected off a
  face by the shock's strength, `reflection()`: x2 weak to x8 strong, less as it strikes the face
  more glancingly; a timber bedded on the ground, a sill, is cut but stays, `_bedded()`; `detonate()` breaks
  members by impulse energy vs bending capacity, glass by pressure, throws splinters through
  Ballistics, ignites, pushes loose bodies, sets off sticks nearby, calls `take_blast(at, kg, held)`
  on people), `BlastTuning` (`config/blast.tres`), `DynamiteStick` (the stick in the world: fuse,
  sparks, shot/fire/sympathetic detonation), `BlastEffects` (flash, fireball, cloud, scorch, sound).
  `src/player/player_wounds.gd` is the player's own anatomy + wound effects.

## src/art/shot_match.gd (the saloon painting's shot)

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

## src/art/street_match.gd (the street painting's shot)

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

## The texture factory (tools/textures)

- **The material lab** (roadmap 1.4a, brief `docs/briefs/material-lab.md`): `tools/material_lab.gd`
  puts `MaterialStand` (`src/art/material_stand.gd`: wall, post and beam, deck, steps, boards at
  their real sizes, every cut end in end grain, no neighbour repeats) out west of town with the
  Studio's three men in front, under noon, golden hour and the saloon's lamps; `--material=` one
  wood on its parts, `--set=mlab_NAME` a candidate set, masks once a view, `numbers.json`;
  `--repeats` counts Main Street's side-by-side boards sharing a strip. `tools/material_measure.py`
  measures colour and detail against the men (`measure`), makes A/B sheets (`sheet`) and the blind
  critic's crops (`crops`). Candidate sets: `tools/textures/material_lab.json` ->
  `paint_woods.py --set=NAME` -> `assets/textures/mlab_NAME/` (`raw` re-cuts kept paintings with no
  calls, `boards` paints more boards, `grade` fits a wood into the men's range when cut,
  `inherit`, `length` (longer boards), `props` (materials.json materials cut by `reduce.py --set`,
  as props or, painted as boards, as a wood of the set), `from_painting` (a wood cut from a kept
  painting), `budget` (paint_textures adds up a run's cost and stops short of it); the People
  workflow's `textures = mlab:NAME`); `OakStair` (`src/art/oak_stair.gd`, `--material=stair`) is
  the hotel's oak stair on the same bench;
  `PixelArt` lays an `mlab_` set as it lays the game's woods. The men's style sheet
  `docs/concept/targets/9_studio_men.png` (`men_reference.py`) is what `paint_woods.py` and
  `paint_textures.py --style=man` send since 2026-10-21 (target 8 before).
- **In the man's hand** (2026-10-16, `docs/briefs/match-the-man.md`; target 8, the layered cowboy's
  model sheet): `paint_woods.py` repaints each wood's strips (stacked, with his sheet as the style
  reference and each wood's `WEAR`: dirt, stains, splits) and cuts them back along the painted seams
  into the same `woods/<wood>_b<k>.png`, seamless along the length (`--cut` re-cuts the kept
  `raw/woods_<wood>.jpg` with no calls; People workflow `textures = woods[:ids]`).
  `paint_textures.py --style=man` paints materials in his hand (`textures = man:<ids>`); those
  are `smooth` at 128 a metre with their own colours. Match views `man_store_golden`,
  `man_saloon_night`. `paint_reference.py` paints the judge's references (`references.json`).
  The close props (2026-10-17): `prop_wood`, `prop_felt`, `prop_pewter`, `shot_tin`, `prop_brass`,
  `prop_iron`, `prop_glass`, `prop_staves`, `prop_barrel_head`, `walnut` (the gun stock) are factory
  materials under the keys PropModels/ShotMatch already ask for, finer the closer they're seen (512
  a metre over 25 cm for the metals, glass and walnut); `PixelArt.factory_density()` lays a factory
  tile at its own texels a metre (textures.json), a multiple of the world's; `turn` in a material
  turns its painting a quarter round before it's cut. `PropModels.lathe` shares ring normals
  under `SMOOTH_CREASE` (turned props shade round, not in rings).
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
  Since 2026-10-15 (the road): a material's `height` has the model paint its relief from its own
  picture (`raw/<id>_height.jpg`, cut the same way into `<id>_height.png`, `height_blur` metres of
  its fine grain off); `smooth` cuts it with no palette or pushed mosaic; its own
  `texels_per_metre`; `median` false keeps small things (stones); the reference may be Sean's road
  picture (`PAINTINGS["road"]`); every call prints OpenRouter's cost.

## src/props/prop_models.gd

- `src/props/prop_models.gd` (`PropModels`): every manifest prop modelled in code (lathe, loft +
  boxes, UVs in metres, on `PixelArt.material()`); `PropLibrary` uses them where there's no .glb;
  `OilLamp` draws `PropModels.lamp()`. `loft(rings)` skins rings of points (flat-shaded quads,
  `_ring` ellipses tilted square to a path, `_arc` a part of one, `_limb` a tapered bar between
  two points): the **horse** (docs/ART_REVIEW.md §3.5: a lofted body, an arched neck and long
  head on tilted rings, a mane, tail, legs with knees and hocks, a blanket and stock saddle on
  arcs over the barrel, a headstall; ~900 faces) and the **hay bale** (a bulging rounded block,
  twine bands, loose straws). `tools/prop_views.gd out.png [--close]` shows the manifest props;
  `--street` the street's code models (horse from three sides, hay, crate).

## src/art/saloon_dressing.gd

- `src/art/saloon_dressing.gd` (`SaloonDressing.build()`, called by `SaloonBuilding`): plank walls,
  stair and balcony (members), tall mirrors (a `ReflectionProbe` the room's size gives them
  something to show), piano by the door, stag, pictures, two dozen lamps (sconces, lamps on the
  back bar, lamps hung on rods; no shadows, their chimneys glow), a bottle wall (`_bottle_wall`:
  a few hundred bottles merged into one mesh per material; scenery, not shootable).
  `ShotMatch` turns and places its whole set (`ROOM_YAW`, `TABLE`: beside the bar, the tall front
  door on your left) and stages extras (`EXTRAS`, `CARD_TABLE`) for the shot. The moon has its
  own low arc (`DayCycleConfig.moon_tilt_degrees` -79.3, `moon_azimuth_degrees` 15.5: it crosses
  ~11° up over -Z, since Main Street the saloon's door faces -Z), so from the shot (23:40) it
  stands in the saloon's doorway over the livery across the street; the backdrop's mid ring's
  north panel is turned (`shift` 14) clear of it, `ShotMatch._doorway` swings the batwings open
  for the shot (`BATWINGS_OPEN`), and the livery's west lantern shows lit between them. The sky
  draws the moon in squares with grey-blue seas and a blue glow round it (`moon_radius`,
  `moon_bright`, `moon_glow` in `sky.gdshader`).

## src/art/sign_art.gd and the backdrop

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
  **The painted sky** (2026-10-16, Sean's `targets/7_sky_target.jpg`): while the sun is low
  (`painted`, under ~26 degrees) two painted panels replace it, 180 degrees each toward and away
  from the sun (`tools/textures/paint_sky.py` paints them, `reduce_sky.py` cuts them to
  `assets/textures/sky/` with `sky.json`, Backdrop hands them over), turned and lifted so the
  painted sun lies on DayCycle's; `paint_gain`, `paint_saturation`. Only what's seen: the radiance
  pass (`AT_CUBEMAP_PASS`) keeps the coded sky, so the town's light doesn't move with it. The haze
  at golden hour is DayCycle's (`volumetric_low_sun` 0.3: at 1, with `fog_low_sun` 0.85, it took
  the street's darks from 7.6% of the frame to 1%); the saloon's smoke is its `room_haze` (0.02).
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
  squares at 0.15 degrees (half the first cut's: the painting's far rock is soft; since 2026-10-17
  `smooth`: 0.1 degrees, its own colours, read filtered, no mosaic or palette), panels shown
  smaller than 90 degrees tapered at their sides, the near layer kept to a low band under a
  rolling hill line, columns filled solid, a faint mosaic, a palette a layer (40/36/32 colours);
  in the shader each layer's haze is scaled by the scene's fog density (`haze_scale`) → `assets/textures/backdrop_<layer>.png` + `backdrop.json`). Bearings increase to
  the right as you look out (`Backdrop.direction()`: 270 is west, down the street).

## Characters by image-to-3D (tools/characters)

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
  **The Rodin route** (since 2026-10-06: `stranger2`, `stranger2s`): `tools/characters/rodin.py`
  (Rodin Gen-2.5 on fal, `fal-ai/hyper3d/rodin/v2.5`, $1.60 a man; `--dry-run` against
  `rodin_standin.py`) builds a man from his four pictures, no rig, into
  `tripo/test/<id>_rodin.glb` (the model test's folder; one who goes in the game moves to
  `tripo/`). `people.json` `"source": "rodin"`, `"rodin": <glb>`: `fit_tripo.py` finds his
  joints from his shape (`find_joints`) and fits him as a Tripo man; with his face found
  (`<rodin>_face.json`) his shoulders go onto ours and all of him above them is scaled so his
  drawn eyes land on the anatomy's (`EYES_RULE`, the report's `eyes`; `people.json` `tris` gives
  him his own triangle budget). `tools/characters/stylise.py` makes a stylised copy (`"stylise":
  {"from": ...}`: brow, jaw, moustache, eyes and hands pushed, his skin's fine detail smoothed).
  `head_paint.py` paints a man with `body` words in `characters.json` whole (six head views, six
  body views; `head.frame` and `bust` set his face's square count), and its bake can keep the
  painter's squares (`bake.squares` false, `flatten`, `view_power`), cut them into cells in his
  body's space (`bake.cells`: 8 mm on his head, 9 below, 2.7 round his eyes), take the painted
  light out of his skin (`bake.skin`) and draw his eyes over the painter's from MediaPipe's
  landmarks (`bake.eyes`). `people.json` `eye_gain` goes into his report (the art session's
  `body_skin` gives his drawn whites that much more light).
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

- **The Rodin portrait route (the approved look, 2026-10-14): `tools/characters/RECIPE.md`**, the
  whole recipe for a new man (Sean's pictures and the ChatGPT prompt, his `portrait.json` entry
  and `fidelity` settings, the commands, what good looks like, traps, going back to the bookmark branch
  `look/portrait-men-2026-10-14`). `rodin_portrait.py` (paint, build), `style_shape.py` (the
  shape fitted to the portraits, relief), `style_probe.py` / `style_compare.py` (measured against
  the portraits, framed as each), `render_man.sh` (build, renders, sheet).
- **The portrait factory** (`tools/characters/portrait.py`, `docs/briefs/portrait-factory.md`;
  men in `assets/people/portrait.json`): a man's face from four plain pictures projected onto the
  character factory's shared base head (`tools/blender/factory.py`, one UV layout cached as
  `build/portrait/layout.json`). `fit`: MediaPipe's landmarks found once on a render of the plain
  head (`landmark_map`, so each is a point on the mesh) and on his front; his profiles' outlines
  (skin rows only) and ears; MakeHuman's face and ear targets (90-odd signed parameters, the kink
  at 0 smoothed; three build targets, `BUILD`) and each picture's camera (scale, offset, a small
  turn) solved together by scipy least squares (soft L1, `ROBUST_M`: plain squares stalled on stray
  outline rows; restarted while it helps) → `build/portrait/<id>_fit.json` and `_fit.jpg` (the head over each picture).
  `paint`: every texel takes the squarest picture that sees it (depth-tested, `SEAM` feathering
  only; a picture only paints what lands inside its outline), ears only from their own side, each picture's shading fitted to normals and divided
  out, highlights clipped, pores smoothed (`SMOOTH_M`), collar colours under the jaw made skin;
  iris (colour from MediaPipe's iris points), whites, pupil, glint, lid lines and nostrils
  stamped; then squares once, last (`SQUARE_M` 4 mm, `FINE_M` 2 mm round the eyes and mouth,
  medians, a palette per region, each square the nearest of all their colours) → `<id>_head.png`. His hair is a shell (`hull_depth`: the
  visual hull of the four outlines along the normals, scalp/sides/back and moustache only,
  `UNDER_HAT_M` above the hat band) with its own projected texture `<id>_hair.png` on the same
  layout. `build` (`portrait_build.py`, bpy): factory_build's man with these →
  `assets/people/<id>_portrait.glb`. `portrait_sheet.py` makes Sean's sheet (style | plain | game,
  saloon, crops) from `people_lineup.gd --head [--hatless]` and `screenshots.gd --model=`.

### The talking face (tools/faces; brief `docs/briefs/face-rig.md`)

A Rodin man's head given lips that part, a mouth, teeth, tongue, eyelids and 15 expressions as
blend shapes (19: speech, blinks, brows, smiles, eye turns), all from MakeHuman's CC0 data. `mh_units.py`: MakeHuman's 59 face pose units
(`face-poseunits.bvh` on its `default` skeleton, `default_weights.mhw`) posed by plain skinning
about the base mesh's own joints → `build/faces/mh_units.npz`. `talking_face.py --man= --out=`:
MediaPipe's landmarks on both faces, a thin-plate warp, the skin pulled onto his (moustache and
brows come along; not near the eyes, `EYE_FADE`), his face cut out and MakeHuman's stitched in,
his paint copied texel by texel (lids from outside his painted eye), teeth set back behind his
lips; `EXPRESSIONS` (units and amounts) → `assets/people/<out>.glb` (one head mesh, sparse
morph targets), `<out>_head.png` (his + the face's), `<out>.json` (`facerig`, `textures_from`).
In the game the shapes ride `PeopleBodies._load` → `BodyMesh.split_pieces` onto `Head_head`.
`face_lab.gd` (via `lab_run.sh`): him as the game builds him; `--mode=sheet` each expression,
`--mode=take` a take frame by frame; `face_sheet.py` the sheet. `arkit_take.py`: a Live Link
Face CSV (+ .mov's sound, lined up by its timecode), his resting face taken off (`neutral`: the
quiet before he speaks) → `take.json` by `MAP` (52 → 20).
`take_video.sh`: close and game-size side by side, with sound (and the performer's .mov if given). `synth_take.py`: a stand-in take
spoken by espeak-ng (for testing without one). What Sean records: `docs/FACE_TAKES.md`. `readability.py`: how much of his face each
expression changes at 1080p, 2 m (the lab holds him still for the sheet; `rest2` checks it).
Gaze: `src/bodies/face_gaze.gd` (`FaceGaze`, a child of his HumanBody: a target node or point;
his look shapes carry the first `eye_range` degrees measured in his head's frame as it is, so the
eyes lead and hold while `pose_offsets[&"head"]` (x up, y to his left) catches up; blinks, small
flicks) with its numbers in `config/gaze.tres` (`GazeTuning`). Proved by `face_lab.gd --mode=gaze`
(a marker on `GAZE_PATH`; `--check` prints the head's turn) and `gaze_video.sh`. Not yet on anyone
in the game: who a man looks at is gameplay's.

A whole dressed man (the two tests, 2026-10-19): `fit_tripo.py` with people.json `"bare": true`
fits a hatless whole man at his true height (`bare_shares`, hips `HIP_OVER_CROTCH` over his
crotch, arms and legs by his shape `limb_sides`, weights smoothed across the limb seams
`smooth_seams`); `whole_man.py` puts the approved game head (`heads/<head>_mesh.npz`) on him at his
collar and his own hat as three pieces (`heads/<head>_hat.npz`). `works_check.gd`: the pose check,
a ragdoll fall, the hat shot off, a wound, and every triangle's stretch (`--ref=` another man's
`works.json`, judged by sheet area). `men_bench.gd`: perf_bench's calm street with N copies of
one man. `two_tests_renders.sh` / `two_tests_sheet.py`: the sheet's renders and layout.

## Training the image model on our style (tools/style)

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

## tools/blender (the people pipeline)

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

## addons/saltcreek_native (the native plugin)

- `addons/saltcreek_native/` — the native plugin (Rust, gdext 0.5.5, `api-4-7`; `cargo build
  --release` there, copy `target/release/libsaltcreek_native.so` into its `bin/`; `cargo test
  --release` for its own tests): `volume.rs` (Pixel-factory's brick volume, cells per axis),
  `carve.rs`, `mesh.rs` (greedy, two surfaces + collision), `pool.rs` (worker threads),
  `member.rs` (`VoxelMember`), `lib.rs` (`NativeBench`).

## tests

- `tests/` — tiny self-contained runner (no addon): `extends TestCase`, methods `test_*`, may `await`.
  A Logger turns any script error during a test into a failure.

## CI

- CI: every push runs tests; pushes to `main` export Windows/Mac/Linux to a Release (notes from
  `docs/BUILD_NOTES.md` — update it each milestone) and the web build to GitHub Pages.
  The test job fails if Godot's import writes any `.import` file that isn't committed as it
  writes them ("Import files committed"): run `godot --headless --import` and commit them.
