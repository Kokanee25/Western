# The whole codebase before the slice's polish (#849)

A review, 2026-11-12. Report only: no game code, test, tool or workflow was changed.

## In short (for the phone)

The code is in better shape than its size suggests: the threading is mostly sound, the randomness
is seeded, nothing leaks render or physics handles, and the soak's "orphans" are not a leak. What
will hurt the slice is that **the valley grew beside the checks, not under them**. Everything that
guards the game (CI, the soak, the smoke test, the frame bench, the goldens, the tour) still runs
the old town. The slice lives in the valley.

The ten things that matter, worst first:

1. **Nothing automatic runs the valley or a mission.** Only unit tests reach them. (A1)
2. **The valley's buildings are built by lab code** in `experiments/`, and it has already hurt: a
   lab switch leaks into the game's buildings, and one lab line made 24,528 errors in a soak. (A2)
3. **People cost four times what the budget table says.** The calm old street measures 7.1 ms for
   people against a 4.0 budget (the table says 1.8). Five men in the valley cost 1.5 ms. The
   townsfolk plan (#850) cannot go in on that. (A3)
4. **The valley takes 12 s to load here** (2.8 s when first measured), before any shader work. (A4)
5. **A reset keeps the story**, so after Backspace or a retry No Law's murder never happens again. (A5)
6. **There is no save.** Nothing is written when you sleep; the story lives in memory only. Gate
   6.6 asks for "saves and loads included". Sean's call: build it now or ship one sitting. (A6)
7. **The soak has been red for two weeks for the wrong reason** and so hides real faults. The
   orphans are members held on purpose; the real growth is a mesh cache and rubble. (A7)
8. **Knocked out in the valley, you wake nowhere**: the doctor and store markers exist only in the
   old town. Outlaws also pick street spots by the old town's coordinates. (A8)
9. **Four missions, four scaffolds, three ways to retry, three ways to start.** Polish will be
   done four times unless they share one base. (B1)
10. **Three files hold a third of the people code** (`human_body.gd` 6,704 lines, `outlaw_brain.gd`
    3,961, `structure.gd` 2,251) and outside code reaches into their private parts. Split after
    the slice, not during. (C1)

The top five to decide are in the `waiting on Sean` issue that goes with this report.

## How this was checked

- **Read:** CLAUDE.md, every lane file, the roadmap's Now, LAYOUT's and DESIGN's indexes, #849.
  Then six read-only sweeps by sub-agents (missions and tests; valley against town; threads, leaks
  and quit; frame cost; coupling and drift; CI and tools), and the hot spots by hand: `main.gd`,
  `game_reset.gd`, `story_state.gd`, `valley_folk.gd`'s murder check, `no_law_murder.gd`'s start,
  `real_look.gd`'s hung lamps, `human_body.gd`'s limp path, `soak.gd`'s verdict,
  `spec_building.gd`'s ramps, `member_mesh.gd`, `outlaw_brain.gd`'s street spot.
- **Measured** (this workspace: a 2.1 GHz Xeon, the same class the budget's 0.65 scale assumes;
  headless, one game at a time, logs in `build/`):
  - `tools/valley/valley_bench.gd -- --world=valley` at four spots, 120 frames each.
  - `tools/perf_bench.gd -- --no-ablate --seconds=20 --scene=calm` (the old street).
  - The whole test suite once, with the native plugin built (results under "The tests, run").
  - The valley's load five more times, each with one part left out, to split it (A4).
  - The nightly soak's logs for Oct 27 to Nov 11 (read from Actions, not run).
- **Not measured:** anything drawn. No lavapipe run was made (a real-look view is ~10 min and a
  golden round ~2.5 h here), so **render CPU, draw calls and shadow cost are from reading only**.
  No gunfight, blast or night-saloon frame was timed either: no bench runs them in the valley,
  which is finding A3 itself.
- **Every finding says how it is known:** *measured*, *traced* (read line by line and the path
  followed), *logged* (from a CI or soak log), or *inferred* (reading only; could be wrong).

## The ranked list

### A. Before the slice ships

#### A1. Nothing automatic runs the valley or a mission

- **What:** every guard runs the old town. No workflow passes `--world=valley` or `--mission=`.
- **Where:** `.github/workflows/*` (no hit for either flag); `src/debug/smoke_test.gd:125` (the
  people count is checked only in the town); `nightly.yml:82-84` (the soak has a valley mode,
  `tools/soak.gd:21-25`, and never uses it); `tools/perf_bench.gd:329-332`, `tools/tour.gd:80`,
  `tools/screenshots.gd:362` and `tools/scene_probe.gd:48` all look up `TestStreet` by name; all
  78 screenshot views and 85 goldens are town views.
- **Also:** PRs get no export and no smoke test (`build.yml:130-136`: only a push to main or
  `[smoke]`), so a shader or export fault is found after the merge.
- **Evidence:** traced. Nine test files load the valley; that is all.
- **Cost of leaving it:** every valley fault is found by Sean, on his PC, in a short session.
- **Fix (small, one session):** a valley leg in the soak; a smoke leg for the valley and one for
  each of `--mission=sheriff` and `--mission=coach`; the smoke test on PRs (about 10 min a PR).

#### A2. The game is built by lab code

- **What:** the valley's buildings and the farmhouse in both worlds are made by
  `experiments/building_lab/spec_building.gd` (2,726 lines, with the lab's `stair.gd` and
  `marks.gd`), from specs kept in the lab's folders.
- **Where:** `src/world/valley_world.gd:150`, `src/missions/farmhouse.gd:18-19`,
  `src/missions/farmhouse_mission.gd:266`; `config/valley.json` points the doctor's lot at
  `res://experiments/building_lab/doctor/doctor.json`. `docs/PARTS.md:39-42` still says the
  builder is "waiting to be promoted". The build ships it only because `export_presets.cfg:11`
  leaves out just `tests/*, tools/*`. Also `human_body.gd:2532` reads `experiments/mocap_walk/clips`
  and `main.gd:54-63` loads two labs' `play.gd`.
- **It has already cost three faults:**
  1. **A lab switch leaks into the game.** `static var extra_furniture`
     (`spec_building.gd:30`) is added to every spec at `:180-181` and never cleared. The gunfight
     lab sets it (`experiments/gunfight_lab/fight.gd:157`, `bridge.gd:390`); every building built
     after that in the same run gets the lab's furniture. Traced.
  2. **One lab line flooded a soak.** `spec_building.gd:1878` (`var ramp: StaticBody3D = r[0]`)
     assigns a freed ramp to a typed variable, which errors before the `is_instance_valid` on the
     next line can run; the freed ramp is never taken out of `ramps`, so it errors every half
     second for good. The Nov 11 soak logged 24,528 errors from it. Logged and traced.
  3. **The lab places what the game doesn't** (#844, still open). The doctor's furniture is in
     `experiments/prop_lab/doctor/dress.json`, read only by the lab's `dress.gd:67`; the game's
     `doctor.json:1820` has `"furniture": []`. Furniture is now placed three ways: in code
     (`saloon_dressing.gd`), in a spec's `furniture`, and in `dress.json`. Traced.
- **Fix (one session, mostly moving):** the builder, stair and marks to `src/structures/`, the
  specs to `config/buildings/`; `extra_furniture` becomes an option on the one building; the ramp
  loop untyped and pruned; PARTS.md's rows updated. #844 then puts the doctor's dressing into his
  spec and deletes the lab's own placer.

#### A3. People are far over budget, and the valley is not on the bench at all

- **Measured, the old calm street** (`perf_bench`, scaled to Sean's by 0.65):

  | System | Budget | CLAUDE.md's table (Oct 4) | Now |
  |---|---|---|---|
  | People | 4.0 | 1.8 | **7.1 OVER** |
  | Physics | 2.0 | 1.1 | 1.8 |
  | Structures | 1.0 | 0.0 | 0.4 |
  | Everything else | 1.0 | 0.1 | **1.1 OVER** |
  | Total, no render | 10 of 14 | 3.1 | **10.4** |

  The raw frame here is 16.0 ms (p99 38.7, worst 51.1). Render CPU's 4 ms is not in that total,
  so the calm street is at the 14 ms line before anything happens. `tests/test_perf.gd`'s guard
  is 16.0 ms raw, about three times loose, so it has not caught this.
- **Measured, the valley** (`valley_bench`): with nobody near, the frame is 1.9 ms here. At the
  saloon yard with five of the valley's folk it is 4.9 ms (p99 11.2), people 2.3 ms: **about
  0.3 ms a man at Sean's**. Thirteen men near you fill the people budget; a town of them, with a
  gunfight on top, does not fit.
- **Why it wasn't seen:** `perf_bench` loads only the town; `valley_bench` has no gunfight,
  blast or night-saloon scene; no bench is in any workflow (`perf_bench`'s "for the CI guard"
  comment is stale); nothing keeps results over time. Eight timers (card_game, room_light, lamps,
  sight_sync, horses, train, valley_ground, hostage_brain) are in no budget row, so they land in
  "else" (`src/debug/frame_budget.gd:18-24`). About 63 of 104 per-frame entry points have no
  timer at all.
- **Where the people cost likely is (inferred, to be measured first):** the fuller skeleton and
  faces since October (`people_body` 3.5 and `people_skeleton` 2.3 ms raw of the frame);
  `FaceLife`/`FaceGaze` writing blend shapes every tick, untimed (`face_gaze.gd:145-150`,
  `face_life.gd:170-175`); a new dictionary of ~16 transforms a man a tick
  (`human_body.gd:1672-1678`) and `_tickers.duplicate()` (`:1534`); Senses building
  `people + player` and testing every pair (`senses.gd:355`, `:231-280`).
- **Fix (two sessions):** first the bench (valley scenes: saloon at night, a gunfight, a blast
  on Main Street, the load; the missing timers mapped; a nightly run that fails on OVER and keeps
  a history). Then the people cost, by what the bench says, until the calm street is back under
  4.0 and a man near you costs under 0.15 ms. **Before the townsfolk are built (#850).**
- **CLAUDE.md's frame table is two months stale** and should be restated from the new bench
  (#401 already asks for this).

#### A4. The valley's load: 12 s here

- **Measured:** `load: bake 401 ms, scene 12042 ms` headless. `experiments/valley/README.md:29`
  recorded 2.8 s when the ground went in. At Sean's that is about 8 s before the real look's
  shaders compile and anything draws.
- **Where it goes (measured: the same load with one part left out each time):**

  | Part | Seconds of the 12.0 |
  |---|---|
  | The markers and the grey-box town (`--no-markers`) | 5.7 |
  | The railway and its train (`--no-railway`) | 3.7 |
  | The farmhouse and its mission (`--no-farmhouse`) | 1.8 |
  | The folk (`--no-folk`) | 1.2 |
  | What is left with all four out (ground, sky, the doctor's office, the player) | 3.4 |

  (The parts overlap a little, so they sum to more than 12.) The markers and the railway are
  two thirds of it: start there.
- **Likely causes inside those (inferred):**
  - the valley's marks painted each launch (`valley_marks.gd:85-120`) and the markers' own
    building (`valley_markers.gd`, `valley_town.gd`);
  - the terrain: 4.16 M height samples decoded one at a time (`valley_terrain.gd:62-64`), about
    1,015 chunk bodies each with a height field and 64 column boxes
    (`valley_ground.gd:85-145, 204-256`); LOD blocks near the camera built with no budget
    (`:346-356`);
  - every spec building rebuilt from JSON with its supports worked out each launch
    (`valley_world.gd:140-160`); the saloon's spec is about 6,000 members, still to come;
  - RealLook swapping nine shader sources at runtime and walking the whole tree
    (`real_look.gd:38-44`), though it has been the default since #641 (not in the 12 s: headless).
- **Nothing generated is cached** anywhere: no `ResourceSaver`, no `user://` cache.
- **Fix (one session for the markers and the railway, one for the building cache):** time
  each step inside the two big parts; bake the marks as bytes and the heights as float32; fewer
  column boxes; the real look's shaders as files. A building cache keyed by the spec's hash only if the saloon needs it.

#### A5. A reset keeps the story

- **What:** `GameReset.clear_statics()` (`src/main/game_reset.gd:29-39`) clears props, sight
  lamps, blood, smoke, chips and shards. It does not clear `StoryState.facts`
  (`src/missions/story_state.gd:8-10`).
- **So:** `no_law_murder.gd:87` sets `nolaw.murder` to "begun" as the murder starts, and
  `valley_folk.gd:489` skips the murder whenever that fact exists. After Backspace, a coach
  retry or a farmhouse retry (all go through `GameReset`), **No Law never plays again in that
  run**. The fact is also set before the scene can abort (`no_cody`, a stall), and an early abort
  leaves the Moment in `folk.murder`, blocking a new one that night.
- **Evidence:** traced; no test covers a reset after a fact (the test would be three lines).
- **The same reset also keeps** `SpecBuilding.extra_furniture`, `OutlawBrain.d_fixes` and
  `default_variant`, `Structure.runaways` and `HumanBody`'s static switches. There are 307
  `static var`s in `src/`; most are caches, about fifteen hold game state.
- **Fix (hours):** each class with game state registers its own reset with `GameReset`;
  `nolaw.murder` written when the scene has played, the Moment freed on abort; a test.
  Sean's rule is needed for one thing only: does Backspace wipe the story? (Assumed yes.)

#### A6. There is no save

- **What:** DESIGN and CLAUDE.md say the game saves when you sleep in a bed. Nothing does.
  `story_state.gd:4-5` says so itself; it has `to_dict()` and no `from_dict`. `Ground`,
  `Structure`, `HumanBody`, the weapons and `StoryState` each have a `to_dict`, and nothing
  collects them or reads them back. A grep for save, load or sleep in `src/` finds only settings,
  bug reports and the look panel.
- **So:** no mission resumes mid-act; a crash or quit in the third mission starts the slice over;
  the roadmap's 6.6 ("a full soak of the demo, saves and loads included") has nothing to soak.
- **Evidence:** traced.
- **Fix (one session for a first cut):** a `SaveGame` that gathers the `to_dict`s with
  `StoryState.from_dict`, written on sleep, with a round-trip test in the valley. What a save
  must hold about ValleyFolk's dead, the farmhouse and a mission mid-act is the design work.
- **Sean's call:** the slice saves between missions, or the slice is one sitting.

#### A7. The soak is red for the wrong reason (#813 answered)

- **Verdict on #813's lead: proven, held on purpose.** The soak fails on
  `int(last.orphans) > 1000` (`tools/soak.gd:366`): an absolute count at the end, though its
  header says "climbing". From the nightly logs the count is highest at load and only falls:

  | Night | Orphans at load | At four hours | Verdict |
  |---|---|---|---|
  | Oct 27 | 15,957 | 173 | passed |
  | Oct 28 | 15,957 | 1,862 | failed |
  | Oct 30 | 15,957 | 2,966 | failed |
  | Nov 11 | 19,181 | 5,909 | failed |

  They are the mesh and shape that `StructureMember.rest()` takes off every batched member
  (`structure_member.gd:207-224`; two a member, freed with the member at `:266-273`), plus
  RubbleRest's set-aside meshes and shapes (`rubble_rest.gd:199, 312, 371`). Oct 27 passed only
  because the town burned down. Since fire went out of play (Oct 31) more of the town stands at
  the end, so more is at rest (that last step is inferred).
- **What does grow** (logged, cause inferred):
  - `MemberMesh._cache` (`src/structures/member_mesh.gd:6-17`) keeps a mesh for every size to the
    millimetre and never drops one; every chip, cut and snapped piece is a new size. Memory went
    1,819 to 1,963 MB over the Nov 11 run.
  - Rubble is never removed: tree nodes went 18,657 to 22,273 in four hours.
- **And the Nov 11 run also failed on A2's 24,528 errors**, which the orphan line hid.
- **Fix (one short session, #813's own):** fail on orphans climbing, or take off the held count;
  log members at rest, `RubbleRest.state()` and the cache's size each window; cache only the
  template sizes. A red nightly should open an issue by itself: it blocked nothing for two weeks.

#### A8. The old town's places are still under the valley's feet

- **Knocked out, you wake nowhere.** `player_wounds.gd:935` looks for `DoctorInside` and
  `StoreInside`; they exist only in `scenes/test_street.tscn:264-266`. In the valley the clock
  jumps and you stay where you fell. The coach playtest already met this ("the 'store floor'
  wake line", `docs/playtests/2026-11-12-coach.md`). The sheriff mission and No Law do not watch
  for the player going down at all; the coach and farmhouse do. Traced.
- **Outlaws pick street spots by Main Street's numbers.** `outlaw_brain.gd:1559-1562` clamps x
  to -34..16 through `TownLayout.street_point` and `:1604` faces `"Saloon"`. In a valley fight
  that is a point near the crossroads at the old town's ground height. Inferred: not seen in a
  run.
- **The valley farmhouse is placed through the old town's layout** (`farmhouse.gd:84`,
  `:191-192`), so `config/town.json` cannot retire until its points are baked into `valley.json`.
- **Moments fall back to the town's waypoints** (`moment.gd:101-102`); only the sheriff overrides.
- **A misspelt place is the map's origin.** `valley_layout.gd:44-47, 106` returns
  `Vector2.ZERO` for an unknown id without a word; No Law's `_points` drops unknown names
  silently (`no_law_murder.gd:95-99`).
- **Fix (one session):** the world answers "where is the doctor, the street, this place" through
  one small interface (`World.places()`), the valley's own; an unknown place is an error; a test
  that every place named in `config/moments/*.json` resolves; a shared "player down" rule.

### B. During polish

#### B1. Four missions, four scaffolds

- **What:** the sheriff and No Law build on `Act`. `CoachFight` (881 lines) and
  `FarmhouseMission` (1,168) are plain nodes with their own copies of the same parts.
- **Where:** finding the player (`act.gd:23`, `coach_fight.gd:108`, `farmhouse_mission.gd:183`);
  showing a line (`act.gd:83`, `coach_fight.gd:828`, `farmhouse_mission.gd:1134`); the timeline
  (`act.gd:132`, `coach_fight.gd:834`, `farmhouse_mission.gd:1140`; `card_cheat.gd:259` writes
  to a different key); making a man (`sheriff_on_road.gd:142`, `card_cheat.gd:106`).
- **Three retries:** held 1.5 s and restarted in place (`sheriff_on_road.gd:573-590`); a scene
  reload only if the scene is `main.tscn` (`coach_fight.gd:808-822`); a key after a loss
  (`farmhouse_mission.gd:875`). The sheriff's restart adds his horse's place again each time
  (inferred).
- **Three starts:** `SHERIFF_ARG` in `valley_world.gd:40`; `CoachCut.START_ARG` with a static
  `start_on_load` (`coach_cut.gd:17-19`); the same pair in `farmhouse_mission.gd:30, 35`. A
  mistyped `--mission=` is ignored without a word.
- **Guesses at "is it ready":** fixed waits of 5, 10, 20 and 30 physics frames
  (`valley_world.gd:76, 105`, `farmhouse_mission.gd:151, 505`, `coach_fight.gd:160`).
- **Behaviour that differs under test:** `farmhouse_mission.gd:136` skips holding the gang when
  the scene isn't `main.tscn` or the bridge is on, so a bridge playtest isn't the game's path.
- **Reaching into private parts:** `sheriff._paint_wound` (`sheriff_on_road.gd:506`),
  `game._clear_table` and `folk._person` (`no_law_murder.gd:284, 288`), `fight._say`
  (`coach_cut.gd:138`), Physiology's bleed dictionaries written field by field
  (`sheriff_on_road.gd:209-232`).
- **Story facts are loose strings.** Written in three files, read in one place
  (`valley_folk.gd:489`). Nothing reads `sheriff.care`. The farmhouse records nothing. Coach
  facts skip the clock. The docs the code cites (`docs/missions/DECISIONS.md`, `BUILD_ORDER.md`)
  do not exist.
- **Evidence:** traced.
- **Fix (one session, before No Justice is built on a fifth copy, #843):** a `Mission` on `Act`
  with the player, lines, timeline, facts with the clock, one retry, one start registry
  (`Missions.start(name)`, unknown names an error) and a `ready_for_story` signal from the
  valley. Then the coach and the farmhouse moved onto it (a second session).

#### B2. Untested paths in the slice

From reading `tests/` (155 files, 1,247 tests) against the missions:

| Path | Has | Lacks |
|---|---|---|
| The sheriff on the road | care rule, bleed, bands, nod, the three endings | he dies on the road, restart, retry, the card, no-horse (without the horse model he cannot be taken in at all, `sheriff_on_road.gd:155, 366`) |
| StoryState | set, get, prefix clear, when | clear all, a reset, any save |
| No Law | sat at the table, heard from away, cries, a gun drawn | Cody down, no Cody, no Earl, a stalled beat, seen from the yard, the barkeep shot, no free chair, the `after_hands` trigger |
| The coach | ram, dents, drive, daze and nerve, door, strongbox, trail, the won facts | the three losses, retry, the climb and hatch, `CoachCut.place_player` |
| The companion (`HostageBrain`, 267 lines, no test file) | he follows once cut loose; out cold | his route, keeping the safe side, his warnings, slowing you |
| No Justice | nothing is built (`docs/scripts/no_justice.json:2`) | all of it |
| Saves of the valley | nothing exists (A6) | all of it |
| The music system | nothing in `src/`; the fiddler is a lab scenario and offline Python | all of it |

Add a test for each row as its code is next touched; the first three rows before polish starts.

#### B3. The test runner lets tests lean on each other

- **One process, one fixed order, statics never reset** (`tests/run_tests.gd:46-50`).
  `test_card_game.gd:13` turns the murder off and never back on;
  `test_farmhouse_mission.gd:331` clears `start_on_load`; `test_commit.gd:219-357` appends to
  `OutlawBrain.d_fixes`. Six files already carry a comment working round a neighbour ("a test
  above may pin it off").
- **Errors are charged to the wrong test:** the catcher is read before the file's tree is freed
  (`run_tests.gd:77, 86-87`), so a teardown error lands on the next file's first test.
- **No time limit:** no `timeout-minutes` on `test`, `native` or `export`; awaits of up to 120
  game-seconds with no watchdog. A hung await burns six hours of Actions.
- **The threaded paths are never tested:** `run_tests.gd:34` sets `World.deterministic`, which
  runs batch merges, rubble cells, voxel swaps and smoke on the main thread. The red soak was
  their only regular run.
- **Silent passes:** four smoke tests pass with no assertion when the plugin is missing; about
  thirty test files reach into parked labs, so parking a lab can break the game's CI.
- **Evidence:** traced; the suite's own run is below.
- **Fix (one session):** a per-file reset (A5's registry), errors charged to `<file>::teardown`,
  a per-test frame cap and a job timeout, `--shuffle=SEED`, lab tests in their own folder, and a
  short threaded pass.

#### B4. Cheap frame costs (each a few lines; all inferred until the bench in A3 times them)

| What | Where | Fix |
|---|---|---|
| Hung lamps: a group walk and `omni_range` written every frame, changed or not; a range write likely redraws the shadow (the 14-lamp trap of 2026-10-13 again) | `src/render/real_look.gd:321-346` | write on change |
| A dead man poses his skeleton every frame for ever | `human_body.gd:4877` turns `_process` on; only getting up turns it off (`:1975`) | stop when the ragdoll sleeps |
| Each shot makes a new particle material, curves, gradients, quad, fog volume; each flash a new light | `src/effects/gun_smoke.gd:67-134`, `impact_effects.gd:152` | share them, as `burst` does |
| About 48 rays on the main thread a gunshot (inside 5, walled 1, slaps 24, retries) | `src/audio/game_audio.gd:252-404` | cache inside and walled per cell; fewer slap rays |
| `PlayerSeat` walks every structure, kit props included, each tick | `src/people/player_seat.gd:85`, `seating.gd:20` | a chairs group, 5 times a second |
| OutlawBrain: a 17-handle array built at 28 call sites, a group lookup a tick, a `load()` a shot | `outlaw_brain.gd:2082, 543, 2681` | cache |
| RealLook's queue copied whole each frame after a blast | `real_look.gd:126-131` | an index |
| The card game resizes its multimesh each dirty frame | `card_game.gd:848-851` | set count once |
| Terrain LOD blocks cast shadows; moon and sun both four splits | `scenes/valley.tscn:62-75` | off from level 2 |
| RoomLight rebuilds its rooms and flicker for rooms out of sight | `room_light.gd:147-157, 504-517` | skip unseen rooms |

**The valley has no StaticBatch** (only `test_street.tscn:295` has one; its owner list names the
town's classes). The spec saloon is about 6,000 members and its glass, sconces and bottles draw
part by part. This becomes urgent the day the saloon goes onto its lot: it belongs with that step.

**Music:** nothing is synthesised per frame today (sounds are made once on a worker). The bowed
string model is offline Python at 96 kHz. Porting it to per-sample GDScript would break the
budget: keep it pre-rendered to WAV, a note or a phrase at a time.

#### B5. Threads, quit and crash risks

The threading design holds up: shadow, batch and analysis tasks work on copied arrays and come
back by `call_deferred`; the sound caches are mutex-guarded; no raw server handles are made, so
none leak. What is left:

- **About twenty tools load the game and quit without GameQuit**, so with no watchdog
  (`tools/screenshots.gd:659`, `scene_probe.gd:76`, `tour.gd:118`, `perf_bench.gd:390`,
  `replay.gd:47, 169`, and more); the visual and tour jobs run them. `tests/run_tests.gd:93` quits
  with its logger still on, which `crash_reports.gd:198` says aborts an exit. Inferred risk: the
  #392/#435 hang at exit.
- **The native pool's workers can die silently** (`addons/saltcreek_native/src/pool.rs:25-34`: no
  `catch_unwind`); `SightWorld.cast_all` then waits for ever (`sight.rs:236-252`). Inferred.
- **`Blast.native` is held in a static and never let go** (`blast.gd:22`), the pattern that
  crashed at exit for `CrashReports.guard`. Inferred.
- **The rubble job's dictionary is written by the worker and the main thread**
  (`rubble_rest.gd:493, 518, 618-620`). Inferred, rare.
- **The railway's timetable worker calls a Node3D's methods** and is not in GameQuit's list
  (`valley_railway.gd:246-250`). Low.
- **The farmhouse's loss line awaits a timer forty times**; a retry frees it mid-wait
  (`farmhouse_mission.gd:1073-1078`).
- **No version check between plugin and engine** beyond `compatibility_minimum = 4.7`.

Fix: one session (GameQuit in the tools, `catch_unwind`, the three small ones).

#### B6. The same fact in two places

- **Mission numbers twice:** 380 `.get("key", <number>)` calls in `src/`. In
  `sheriff_on_road.gd` every default equals `config/moments/the_sheriff.json` (lines 138, 162,
  219, 223-224, 228, 292). A misspelt key reads the code's number without a word.
- **The gang twice:** Brody, Lyle and the Kid in `town_life.gd:36-42` and
  `config/farmhouse.tres:27`; loose defaults differ again (`farmhouse_mission.gd:309-310`,
  `coach_fight.gd:117-118`).
- **A man is assembled by hand in 15 files**, each adding a child named "Brain" found by name in
  17 files, each picking its seed from a hand-kept range (500+, 520+, 540+, 201+, 716, 9400+).
  The bridge's range runs into the farmhouse's after 20 spawns (inferred).
- **Lamp hours in six places, three values** (18-7, 17-4, 17-6: `oil_lamp.gd:6-7`,
  `saloon_building.gd:128`, `saloon_dressing.gd:436`, `street_dressing.gd:319`,
  `facade_art.gd:493`, `dress.gd:140-145`). The valley's lamps light an hour after the town's
  (inferred).
- **Unseeded:** `card_game.gd:35`'s deck; the guns' spread is seeded from the node path, so it
  differs between town and valley.
- **Bone tables** in `tools/blender/retarget_motion.py:93-104` repeat `config/anatomy.json`.
- **Fix:** `People.make(spec)` with `config/people.json` (one session); a loader for mission
  data that fails on a missing or unknown key (one session); lamp kinds as one resource (hours).

#### B7. CI hygiene (one session, small edits)

- Failures swallowed: `golden_check.py --render ... || true` (`visual.yml:100-102`, and its log
  prints only `if: failure()`, which that stops); `--import || true` in every Godot job;
  `python3 ... | tee` without pipefail (`scans.yml:32, 37`, `scans4k.yml:73`, `sounds.yml:111`).
- Effects goldens allow a third of the picture to change (`gun_smoke_saloon` share 0.43,
  `saloon_fire_inside` 0.31).
- Dispatch inputs pasted into shell in jobs that hold the paid keys (`people.yml:652-688`);
  dispatch is owner-only, so low, but `env:` is free.
- The Linux plugin is built twice a PR and three times in `visual.yml`; no job caches
  `.godot/imported`. Actions pinned by tag, not commit.
- Seven feel ranges are still "proposed" with no measured value (`config/feel_ranges.json`).

### C. After the slice

#### C1. The three giant files

Splitting them during polish would collide with every session; do it after, one seam a session.

- **`human_body.gd`: 6,704 lines, 235 functions, 192 fields**, named by 85 files in `src/`.
  Private members used from outside: `_lib` 36 times, `_apply_pose` 18, `_grab` 17,
  `_pivot_rest` 9, `_update_skeleton` 8, `_own_rids` 5, `_step_fall` 4. Its seams: build and
  dress (560-1120), skeleton and hands (1122-1530), posture and locomotion (1705-2280), pose and
  clips (2278-2800), wound care (2873-3720), damage intake (3722-4370), wound paint (4371-4735),
  dismemberment (4735-4870, 6116-6510), limp and dying (4873-5720), blast and falls (5724-6116).
- **`outlaw_brain.gd`: 3,961 lines, three brains in one** (town routine 1158-1900, combat
  1896-2975, morale 3337-3950), 745 float literals, 184 inline thresholds. Labs reach into
  `_step`, `_reloading`, `_search`, `_tactic_time`.
- **`structure.gd`: 2,251 lines**: building, batching (513-1270), analysis, breaking, rubble
  (1788-2177) and lab switches read from the command line (1971-1974).
- **One thing worth doing now:** make the private members that other files use public, by name,
  with no other change. It is mechanical, it shows the real interface, and it makes polish safer.

#### C2. Retiring the old town (at G8)

- **What it costs to keep:** every guard points at it (A1), so the valley goes unguarded; two of
  everything (two doctors, two saloons, two dressing paths, two rosters, town paths inside
  `ground.gd`); branches on the world in `main.gd:18-63`, `smoke_test.gd:125`,
  `dev_bridge.gd:245-260, 1383`, `world.gd:18-20`.
- **What can go, about 5,600 lines of runtime code:** `street_dressing.gd` 750, `facade_art.gd`
  678, `shot_match.gd` 569, `saloon_dressing.gd` 542 and `saloon_building.gd` 135 (once saloon B
  is the saloon), `town_life.gd` 297, `voxel_trial.gd` 258, `town_layout.gd` 240, the road and
  grass dressing 608, the range and debug spawners 238, `street_match.gd` 145, town paths in
  `ground.gd` about 300, `scenes/test_street.tscn`, `config/town.json`. Plus about 9,000 lines of
  town-bound tests and 1,200 in tools.
- **What must stay:** `false_front_building.gd` (the spec builder extends it and calls its
  private helpers), `static_batch.gd`, `bucket_line.gd`.
- **What must move first:** A8's places; the farmhouse's points; the gang's roster (B6); the
  bridge's `gang` and `fight`; the gunfight and train labs' keys and F5's stops
  (`main.gd:54-63`, `test_street.tscn:278-284`); `tests/test_valley.gd:132-133`, which asserts
  the town is the default; 78 views and 85 goldens re-shot in the valley (art, about a week of
  renders here).
- **Order:** A1, A2 and A8 make G8 a flip, not a rewrite. Until then each town-bound tool
  should say `--world=town` out loud, so the flip breaks nothing by surprise.

#### C3. Leftovers

- **The painted look is retired but still wired:** five debug keys (`main.gd:130-143`),
  `depth_mosaic.gd` 102 and `probe_mosaic.gd` 136, the blocks shaders, the `#ifndef REAL_LOOK`
  branches, settings nobody reads (`probe_soft`; `pixel_shading` and `finish` dead under the
  real look). `PixelArt` stays: it is still the material factory for about 40 files.
  `real_look.gd:5`'s "the painted look stays the default" is stale. Art's, with goldens.
- **About 70 command-line flags parsed in 25 places**, many captured into statics at class load
  (so a bridge reload cannot change them). One `Args` helper and one list.
- **Dead or unlisted:** `Outline` (`src/render/outline.gd`, no reference anywhere); ten labs no
  brief or lane names (`bodies_vanish`, `hands_up`, `light_pass`, `motion_films`,
  `old_buildings`, `people_after_blast`, `plant_dynamite`, `post_pose`, `sight_lab`,
  `street_shape`); about 3,200 lines of tools nothing references (`tools/buildings/concept_plans.py`
  414, `tools/faces/apron.py` 291, and 25 more).
- **The event bus:** `person_arrested` has no listener; `day_started` and `ground_uncovered`
  only tests. Helpers that add themselves to `current_scene` land outside the game's viewport
  (`spawn_queue.gd:42`, `dent_watch.gd:35`). Physics order is numbers scattered in nine files.
- **LAYOUT.md has no valley section**, though it names the valley 89 times.
- **Open issues: 131**, about fifty labelled `next session`, many for parked work. CLAUDE.md
  says keep them few; a pass to close or park-label the stale ones would make Sean's list
  readable again.

## What is sound (so nobody "fixes" it)

- No call to the global random functions anywhere in `src/`; 77 seeded generators.
- No render or physics handle is created raw, so none leaks.
- GameQuit's drain and watchdog; the black box; the structural analysis worker's copied records.
- Chips, blood, gun smoke and impact caches are all bounded.
- The dev bridge's help table matches its commands.
- No workflow runs untrusted code with secrets (no `pull_request_target`, no comment triggers).
- **Fire is out of play on purpose** (Sean, 2026-10-31, #458). The valley has no `FireSystem`
  node, so every burn path finds none and does nothing. That is right today; it is one line in
  `valley.tscn`, and a frame-cost check, the day fire comes back.

## The tests, run

`godot --headless --fixed-fps 60 -s res://tests/run_tests.gd`, native plugin built, on this
commit of `main` (be704e9b): **1,247 passed, 0 failed, in 3,155 s (53 minutes).**

- **Green, so the findings above are not failing tests: they are paths with no test.**
- **53 minutes is itself a finding.** CLAUDE.md asks every session to run the suite before every
  push. On this workspace that is most of an hour with nothing else allowed to run beside it.
  The runner prints nothing until the end, so a hang looks the same as progress. R9 should also
  print a line a file with its seconds, and name the ten slowest: some are waits of up to 120
  game-seconds that a faster clock or a smaller scene would cut.
- At exit the engine reports 621 resources still in use and leaked dummy-renderer handles
  (537 materials, 46 shaders). Harmless headless, and the reason is B5's first point: the runner
  quits without GameQuit.

## The refactors, as steps

Each is one session. In order; the first five are the ones in the `waiting on Sean` issue.

| # | Step | Model | Done when |
|---|---|---|---|
| R1 | **The building builder into the game** (A2): `spec_building.gd`, `stair.gd`, `marks.gd` to `src/structures/`, specs to `config/buildings/`; `extra_furniture` an option; the ramp loop fixed; PARTS.md. Then #844 lands on it. | Sonnet 5.5, medium: moving files by a written list | no `res://experiments/` in `src/` or `config/`; suite green; a soak hour with no ramp error |
| R2 | **CI runs the valley** (A1, A7): a valley soak leg; valley, sheriff and coach smoke legs; smoke on PRs; the soak's orphan rule and its three counters (closes #813); job timeouts; a red nightly opens an issue. | Sonnet 5.5, medium: workflow edits to a brief | a PR shows the valley smoke; a nightly soak is green or red for a real fault |
| R3 | **The story survives nothing it shouldn't** (A5, A8): the reset registry; No Law's fact at the end; places through the world, unknown ones an error; the player-down rule in the valley; tests for each. | Opus 5.5, medium: a bug with several causes | Backspace then No Law plays again; knocked out in the valley you wake at the doctor's |
| R4 | **The valley on the bench** (A3): valley scenes in `perf_bench` (night saloon, gunfight, blast, load), missing timers mapped, nightly with history; then the people cost found and cut. Two sessions. | Opus 5.5, medium: performance work | the calm street's people under 4.0; a near man under 0.15 ms; CLAUDE.md's table restated |
| R5 | **Does the slice save?** (A6): if yes, `SaveGame` first cut with a round-trip test in the valley. | Opus 5.5, medium: a new system | sleep, quit, load: the story's facts, the dead and the broken are back |
| R6 | **One mission base** (B1): `Mission` on `Act`, one retry, one start registry, a ready signal; then the coach and farmhouse onto it. Two sessions. Before No Justice (#843). | Opus 5.5, medium: a new shared mechanic | four missions, one scaffold; a mistyped `--mission=` is an error |
| R7 | **The valley's load** (A4): the markers and the railway first (9 of the 12 s), each step timed; marks and heights baked; fewer column boxes; real-look shaders as files. | Opus 5.5, medium: performance work | the scene under 5 s here, split printed by `valley_bench` |
| R8 | **The cheap frame fixes** (B4), each timed before and after on R4's bench. | Sonnet 5.5, medium: a written list of small edits | each row measured; none slower |
| R9 | **The test runner** (B3): per-file reset, teardown errors, caps, shuffle, lab tests apart, a threaded pass. | Sonnet 5.5, medium: a written list | the suite passes under two different shuffles |
| R10 | **People from one place** (B6): `People.make`, `config/people.json`, seeds from ids; mission data through a strict loader. | Opus 5.5, medium: touches every mission | no `HumanBody.new()` outside the factory and tests |
| R11 | **Quit and the pool** (B5): GameQuit in the tools, `catch_unwind`, the three small ones. | Sonnet 5.5, medium: a written list | the visual and tour jobs exit through GameQuit |
| R12 | **CI hygiene** (B7). | Sonnet 5.5, medium | no swallowed failure left |
| R13 | **Public names for what's used outside** (C1's one thing now). | Sonnet 5.5, medium: mechanical | no `._name` reach into HumanBody, OutlawBrain or Structure from another file |
| R14 | **After the slice:** the three files split one seam a session (C1); the old town retired at G8 (C2); the painted look's leftovers (C3, art); one flag parser; the attic and the issue list. | Opus 5.5, medium for the splits; Sonnet for the rest | — |

R1 and R2 can run side by side (different files). R3 before any more mission work. R4 before the
townsfolk are built (#850).
