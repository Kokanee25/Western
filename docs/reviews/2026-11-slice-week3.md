# The whole codebase two weeks into the slice (#1320)

A review, 2026-11-27. Report only: no game code, test, tool or workflow was changed. The last one was
`docs/reviews/2026-11-codebase.md` (#849, 2026-11-12); what became of its findings is at the end.

## In short (for the phone)

The last review's worst faults are mended: there is a save, the builder lives in the game, a reset wipes
the story, the nightly runs the valley. Since then 164 merges went in, in 15 days. What hurts now is
different: **the parts of the slice exist but are not joined, and the things that would tell us so are
either red and unread or still looking at the old town.**

The ten that matter, worst first:

1. **The slice can't be played from a plain start.** The road and No Justice start only from a
   command-line flag, a loaded save starts no mission, and nothing plays the slice end to end.
2. **Sixty people don't fit.** Measured today: 61 men on the valley's street cost 15.9 ms a frame before
   anything is drawn (the whole frame's budget is 14). Twenty-five are already over the people budget.
3. **A green PR doesn't mean a green main.** About twelve red mains in fifteen days, most from tests whose
   result depends on which other tests ran before them or on what else stands in the valley.
4. **Saves break when content changes.** A prop's id is its place in the build order; add one prop to the
   street and every later id shifts. There is no version step and no guard: a bad load can leave the
   screen black with the controls off.
5. **The valley takes 37 s to load here** (12 s at the last review). Every building and every man is built
   at once, before the first frame.
6. **The physics engine's body limit is close.** 54,129 bodies of 65,536 today, with the hotel and the
   Railroad Saloon not placed. The opera house doesn't fit.
7. **The nightly check was red six nights of fourteen and nobody answered.** Its issue (#924) holds five
   robot comments and no reply. Nothing holds the valley to the frame budget either.
8. **Two files are where every session collides.** `spec_building.gd` (4,909 lines) and `valley_folk.gd`
   (2,966) were each touched by a quarter of the last week's merges. The three files the last review said
   to split all grew.
9. **The notes sessions read have doubled.** LAYOUT is 315 KB (+74 KB in 15 days), PARTS 150 KB, the lane
   files went from 19 KB to 45 KB, and CLAUDE.md and the roadmap say things that are no longer true.
10. **The cloth solver is 5 to 14 times over its own cost target** and steps one garment at a time on the
    main thread. It is fine for Harlan's glove; it will not dress a crowd as built.

The picks (fix now / after the slice / leave) are in the `waiting on Sean` issue that goes with this report.

## How this was checked

- **Read:** #1320, #849, CLAUDE.md, DESIGN's index, the roadmap's Now, #953 and its 2026-11-26 comment,
  the gameplay lane file, the newest status entries. Six read-only sweeps by sub-agents (saves; fragile
  tests and CI's map; duplication; scaling; session cost; the last review's findings and what's untested).
  Their main claims were then checked by hand in the code: the fire flag, the prop ids, the load's cover,
  the bar's pour, the mission starts, the export filter, the test map's check, the save's version.
- **Measured** (this workspace: a 2.3 GHz Xeon, 4 cores; headless; one game at a time; scaled to Sean's by
  FrameBudget's 0.65 as the budget table is; logs in `build/rev/`, not committed):
  - `tools/perf_bench.gd -- --world=valley --scene=day|night --townsfolk=0|25|56 --no-ablate --seconds=10`,
    five runs. Each prints the load, the census and the budget line.
  - `tests/run_tests.gd -- --only=save_game` six times running (the test #1315 fixed).
  - `python3 tools/test_select.py --check`.
  - The nightly workflow's last 16 runs and #924, read from Actions.
- **Not measured:** anything drawn (no lavapipe run: render CPU, draw calls and video memory are from the
  earlier benches or from reading). No gunfight, blast or falling floor was timed. The whole suite was
  not run (about 2.5 hours of CPU here; main's own run is the record). Peak memory was not re-measured.
- **Every finding says how it is known:** *measured* (here, today), *traced* (the code path followed),
  *logged* (a CI run, a status entry or an earlier bench), *inferred* (reading only; could be wrong).

## The ten findings

### 1. The slice is not joined in play

- **Evidence (traced).** `src/world/valley_world.gd:161-187` starts the sheriff, No Justice's camp, its
  hideout and its cabin only when their `--mission=` flag is on the command line. Only No Law's beats come
  from the clock and the story's facts (`valley_folk.gd:1717-1838`). On a load, `valley_world.gd:150-154`
  returns before any of it: "no mission starts from the command line or a retry's flag".
  `docs/briefs/saving.md:81` says the same: "there's no start in play after the funeral yet, so a load
  between No Law and No Justice brings nothing". The only whole-mission test is
  `tests/test_no_justice_whole.gd`, started by flag. The nightly smoke starts four things (`nightly.yml:185`:
  the valley, `sheriff`, `sheriff_dies`, `coach`); No Law's night, the funeral and every No Justice act
  are started by no automatic check with threads and the cast on (unit tests run with
  `World.deterministic` and the private cast off, `run_tests.gd:41,45`).
- **Why it matters.** The slice is defined as the road, No Law and No Justice, plus an evening of free
  roam, with sleeping to save between. Today a player who starts the game gets No Law's town and nothing
  else, and a player who sleeps and continues gets no mission at all. Every seam between acts (who is
  where, what the facts say, what the save kept) is untested because it has never been crossed in one run.
  This is where the Fable playthrough (#900) will spend its week if it isn't done first.
- **Fix.** One `Missions` table: each act names the facts that start it and the facts it sets; the valley
  asks it at a plain start, at dawn and after a load; the `--mission=` flags and the three retry statics
  (`NoJusticeHideout.retry_on_load`, `JoeLost.restart`, `CoachCut.start_on_load`) become calls to it; a
  mistyped mission name fails loudly. Then one headless test from a plain start: road, murder, funeral,
  sleep, load, camp, hideout, cabin, asserting the facts at each seam; and five more legs on the nightly
  smoke line. **Size: a day (two sessions, Opus).**

### 2. Sixty people cost more than the whole frame

- **Evidence (measured today, Sean's ms, no drawing).**

  | Scene | Men | People (4.0) | Physics (2.0) | Else (1.0) | Total (14) |
  |---|---|---|---|---|---|
  | day, no townsfolk added | 11 | 2.23 | 0.01 | 4.61 | 7.55 |
  | day +25 | 34 | **5.14** | **3.43** | **3.15** | 12.43 |
  | day +56 | 61 | **8.24** | **3.13** | **3.83** | **15.88** |
  | night +25 | 37 | **5.26** | **2.28** | **4.06** | 12.28 |
  | night +56 | 69 | **7.94** | **5.68** | **1.38** | **15.66** |

  Render CPU (2 to 2.7 ms by the earlier bench with 15 townsfolk) comes on top. The valley bench's
  "24 townsfolk fit" (4.9 ms on 2026-11-13) no longer holds at 25. "Else" is over its 1.0 in every run,
  with nobody added.
- **Why it's so (traced by the sweep).** Men are slowed by distance only (`people_tick.gd:195-216`), so a
  crowd in one room is all "near". A man at a chore can't slow (`civilian_brain.gd:878`); a limp or dead
  man ticks for good (`human_body.gd:504`). Only the pose maths runs on the pool; senses, brains and the
  skeleton writes are on the main thread. Senses is every man against every man (`senses.gd:247-275`),
  building its lists afresh for each look (`senses.gd:375-380`). Physics rises from 0.01 to 3-5 ms as men
  are added: each man's bodies moving among 53,660 static ones.
- **Why it matters.** The 60 real people and the Railroad Saloon's crowd night are both this. The
  Railroad Saloon's own README records 55 standing men at 9-10 ms. Sixty different MetaHumans are also
  about 150 MB of video memory each by `docs/reviews/2026-11-metahumans-town.md` (logged), so about 9 GB.
- **Fix.** Needs Sean's word first, because "performance never fakes the game": a man the player can't
  see (through a wall, behind him, in another building) may think less often; a body at rest stops
  ticking until touched; senses share one list a tick and use a grid; the men's physics is looked at
  on its own (why 3-5 ms). **Size: a brief and three or four sessions (Opus).** Without it, the honest
  number for the slice is about 20 townsfolk plus a mission's cast.

### 3. A green PR is not a green main

- **Evidence (logged, traced).** The status logs record about twelve red mains from 2026-11-13 to 11-27
  (the list is in the appendix). Most were not faults in the merged change: a test failed "in shard order
  only", or because a new building's 1,500 members moved another mission's door debris (#1286), or
  because a stick sometimes shoved a barrel (#1315). The causes in the code:
  - `tests/run_tests.gd:106-122` resets statics and settings between files, but not the scene tree or
    the physics space; nothing checks a file left the world as it found it.
  - A PR runs a subset of files in its own shard order (`tools/test_select.py:211-217`), so its
    neighbours never match main's.
  - `config/test_map.json` sends a building, structure, blast, fire, weapon or body change to that
    system's unit tests, not to the mission tests that break: `config/buildings/railroad_saloon.json`
    maps to 12 tests, none of them `test_no_justice_shack_walk`, `test_no_justice_whole`,
    `test_no_law_carry` or `test_card_game`.
  - `addons/**` doesn't run the tests of its own classes (`test_cloth_core`, `test_sight_world`,
    `test_fire_core`, `test_crash_reports`): the map can't see a Rust class's name.
  - `test_select.py --check` lists four tests no rule reaches and exits 0 (measured).
  - After a green run, merging main in runs only tests both sides map to (`test_select.py:226-247`).
  - Eight tests assert wall-clock times (`test_save_game.gd:367` < 1500 ms, `test_openings.gd:152`
    < 40 ms, `test_movement.gd:174` < 30 µs and five more), on shared runners eight at a time.
- **Measured.** `test_save_game` after #1315's fix: 6 runs, 6 green, 103-108 s each. That one is mended.
  Why the stick shoved the barrel in 8 runs of 12 on the same code, with the seed fixed and
  `World.deterministic` on, was never found: something still differs between two runs.
- **Why it matters.** Each red main costs the next session its first hour (the rule: fix it first), and
  twice in these two weeks the first diagnosis was wrong (#1077, #1251). With "merge on your own green",
  main's run is the only real gate.
- **Fix.** (a) After each test file, the runner compares the root's children and the physics body count
  with the start, fails the file that leaked, and frees the rest. (b) A "valley canary" group (shack walk,
  card game, the carry, No Justice whole: about 18 minutes) added to the building, structure, blast,
  bodies and prop rules, and to every merge-in. (c) `addons/**` runs everything. (d) `--check` fails on
  an unreachable test. (e) Timings become prints. **Size: a session (Opus) for (a), half (Sonnet) for
  the rest.** Finding what differs between two runs is a further session, worth it only if (a) doesn't.

### 4. A save is tied to the exact build that wrote it

- **Evidence (traced).**
  - Prop ids are counters: `street_<kit>_<n>` where n counts the props placed so far
    (`src/art/valley_street_dressing.gd:301-302`); `<building>_<kit>_<count>`
    (`src/structures/spec_building.gd:3054`); `<kit>_<n>` from a static counter for everything else,
    mission props included (`src/props/prop_kit.gd:100-103`). Add one line to `config/valley_street.json`
    and every later street prop has a new id. An old save then breaks the wrong barrel, or reports
    "missed" in a warning nobody sees (`valley_world.gd:214`).
  - `SaveGame.VERSION` is 1 and `MIGRATIONS` is empty (`src/save/save_game.gd:15,24`), though the horse,
    the news, regard, the purse and prop contents were all added since. Some loaders read with a default;
    others index straight in (`valley_folk.gd:2839-2841`: `d.gone_for_good`, `d.kept_out`, `d.hands`).
  - `_load_pending` blacks the screen and turns the controls off, then calls `SaveGame.apply`
    (`valley_world.gd:197-211`). A script error inside leaves both as they are.
  - A member alight is saved and never re-lit: `to_dict` writes `[char, wet, consumed, burning]`
    (`structure.gd:2760`), `from_dict` reads the first three; sleep isn't refused near a fire
    (`player_sleep.gd:111-131`). `docs/briefs/saving.md:119` says "alight" is kept.
  - A planted charge and dug ground are kept by node path, not id (`dynamite_stick.gd:349-350`,
    `save_game.gd:76`). The stage curtain and door hinges have a `to_dict` nothing calls.
- **Why it matters.** Nobody has an old save yet. The day a friends-and-family build goes out and a
  second build follows, every tester's save is from an older build with different props, and the street
  is still being dressed weekly (161 things on 11-27, #1307 open).
- **Fix.** Ids from the config entry (its own id, or lot plus rounded position); a hash of the id-bearing
  configs in the save's head, with a plain refusal ("this save is from an older build") on mismatch; the
  load's cover lifted in every case; a checked-in save file loaded by a test; fire burnt out or sleep
  refused near it; the #1315 path tested through `SaveGame.apply` in the valley. **Size: a session and a
  half (Opus). Before the first build that leaves Sean's hands, not before.**

### 5. The valley takes 37 s to load

- **Evidence (measured, five runs within 5%).** Scene 19.9 s (buildings 12.0, railway 1.5, ground 1.2,
  street dressing 1.1, markers 0.9), then the first three frames 16.8 s, of which building the men is
  14.2 s. Raw seconds on this workspace; Sean's PC will be faster, by perhaps a third. The last review
  measured 12 s (2026-11-12), the valley bench 28 s (11-13). The private cast is on in debug runs, so
  these men are the MetaHuman stand-ins (0.5-3.5 s a man by the MetaHuman review).
- **Why it matters.** Every death, retry and Continue reloads the valley. It is also every session's
  cost: each valley test file pays it (38 files load `valley.tscn`), which is most of the suite's 148
  CPU-minutes. And it grows with each building: the hotel adds about 7 s, an opera house about 13 (logged).
- **Fix.** Men built a few a frame behind the cover, nearest first, sharing one built body per model;
  buildings far from the start built after the first frame, or their member tables read from a baked
  file instead of rebuilt from the spec. **Size: a day (Opus); measure after each half.**

### 6. The body limit, and what the next buildings cost

- **Evidence (measured).** The census in every run: 53,660 static bodies and 469 rigid, 54,129 against
  `project.godot:44` `max_bodies=65536`; 51,118 structure members. That is without the hotel (no spec
  placed) and with the Railroad Saloon off its lot (`spec_waits`, #1298). Logged: 63,386 with the hotel
  (`docs/reviews/2026-11-building-bodies.md`); a man adds 17 bodies when he goes limp; one blast adds
  about 1,890 pieces of rubble.
- **Why it matters.** The hotel, the Railroad Saloon and sixty men are about 66,000 before anything
  breaks. Past the limit Jolt refuses new bodies: rubble that doesn't appear, men who can't fall. Memory
  goes the same way: the budget is 15 KB a member, the hotel is at 18.6, and the route to 12 ("rows",
  `docs/reviews/2026-11-member-memory.md` step 3) has no brief yet. An opera house three times saloon B is
  about 430 MB more against a 4,096 MB ceiling that stood at 3,470 with less in.
- **Fix.** Raise the limit to 131,072 now (a line, about 12 MB; check the bench doesn't move). A test
  that fails when the valley passes 80% of it. The rows brief written before the opera house's spec is.
  **Size: half a session (Sonnet) for the first two; the rows are days and belong after the slice.**

### 7. The nightly is red and unread; nothing holds the valley to its budget

- **Evidence (logged).** The nightly's runs from 2026-11-13 to 11-26: failed on the 13th, 14th, 15th,
  19th, 22nd and 25th, six of fourteen. Its issue #924 has five "Red again" comments from the robot and
  none from a session or Sean. No status entry names a nightly verdict since the 13th.
  Besides (traced): no workflow runs `perf_bench`; `tests/test_perf.gd:23` times the old street;
  `perf_bench.gd:629` only prints the peak memory; none of the 85 golden images shows the valley;
  `tools/tour.gd:80` and `screenshots.gd:362` still look up the old street. CLAUDE.md's budget table is
  the old town's from 2026-10-04. Six timers (`saloon_room`, `card_game`, `band`, `garment`,
  `glove_handoff`, `hostage_brain`) are in no budget row, so they land in "else".
- **Why it matters.** The nightly is the only thing that runs the game for hours with threads on. A red
  nobody reads is the state the last review found (A7), back within a week. And finding 2 was there to be
  seen any night since the townsfolk went in.
- **Fix.** A rule in CLAUDE.md: the first gameplay session of a day reads #924 and either fixes the red
  or says why not, in a line there. A nightly bench leg (day and night, +24 men) that fails over budget
  and over the memory ceiling, writing its table to the run's summary. The six timers given rows.
  **Size: half a session (Sonnet) for the rule and the timers, a session (Opus) for the bench leg.**

### 8. Where every session collides

- **Evidence (measured by the sweep over the 71 merges of 11-21 to 11-27).**

  | File | 11-12 | Now | Merges touching it |
  |---|---|---|---|
  | `src/structures/spec_building.gd` | 2,726 lines | 4,909 (238 KB) | 17 |
  | `src/people/valley_folk.gd` | 20 KB | 2,966 (125 KB) | 18 |
  | `src/debug/dev_bridge.gd` | 60 KB | 1,882 lines | 13 |
  | `src/structures/structure.gd` | 2,251 | 2,968 | 8 |
  | `src/bodies/human_body.gd` | 6,704 | 7,135 | 4 |
  | `docs/lanes/gameplay.md` | 5.5 KB | 10.4 KB | 29 |

  `valley_folk.gd` holds the roster, the day's book, the indoors record, the murder's check, the lines
  and its own save. `spec_building.gd` holds the spec's reading, framing, openings, stairs, furniture,
  dressing and use points. A session must read 60,000 tokens of `spec_building.gd` to change a stair.
- **Why it matters.** With up to four sessions at once, these are the files two of them edit the same
  day. The last review said "split after the slice, not during" of `human_body.gd`; that still holds for
  it. These two are different: they are new, still growing by a hundred lines a day, and split along
  seams that already exist.
- **Fix.** `spec_building.gd` into the builder and four helpers (openings, stairs, furnishing, use
  points), `valley_folk.gd` into roster, day book, indoors and save: moves only, no behaviour change, the
  tests as the proof. **Size: a session each (Opus), on a quiet day for that lane, merged the same day.**

### 9. What sessions read has doubled

- **Evidence (measured by the sweep; sizes in bytes).**

  | File | 2026-11-12 | Now | Limit |
  |---|---|---|---|
  | `docs/LAYOUT.md` | 241,028 | 315,226 | none |
  | `docs/PARTS.md` | 97,474 | 149,768 | none |
  | the five lane files | 18,621 | 44,518 | 10 KB each (three are over) |
  | `CLAUDE.md` | 27,882 | 30,337 | 30 KB (over) |

  LAYOUT's biggest sections are 32, 25, 24 and 24 KB each; PARTS's "Props" section is 68 KB, with rows
  up to 2.6 KB on one line. CLAUDE.md tells every session to read PARTS before building anything.
  Stale lines every session pays for and may act on: CLAUDE.md "the current [brief] for both sessions is
  `docs/briefs/review-tools.md`" (last changed 10-11); "once the dev bridge exists" (it is 1,882 lines);
  the budget table; "three lanes" (there are five files); the Current-state lines for art and props
  (both behind their lane files). `docs/ROADMAP.md`'s "▶ Now" still opens with 2026-11-04's plan, and
  CLAUDE.md says "work only on your lane's current step there", while the real list is #953.
  The same environment traps are written in four lane files (no Godot or plugin in a fresh container;
  lavapipe out of memory; the silent OpenGL fallback). Measured here: the plugin's build and the import
  took 10.5 minutes before the first test could run, in every fresh session that needs one.
  The repo's tip is 4.9 GB with no LFS: `docs/screenshots` 2.4 GB, of which 168 judge rounds are of the
  retired painted look; about 390 MB of pictures are added a week. There are 24 open `waiting on Sean`
  issues, thirteen of them untouched since before 2026-11-14.
- **Why it matters.** This is the weekly limit. A session that reads its lane file, one LAYOUT section
  and PARTS's props has spent about 30,000 tokens before it starts.
- **Fix.** LAYOUT and PARTS split into a file a section with a size test, PARTS rows cut to a line and a
  link; lane files hold only what's open and the traps; CLAUDE.md loses the budget table, the build
  plan's history and the stale lines (about 4 KB), and points at #953; the roadmap's Now rewritten or
  retired. A setup script for a fresh container (Godot, the plugin, the import cache, swap) run by the
  environment, so the trap lines can go. Old judge rounds moved out of the tree (Sean's OK needed for
  any history rewrite). The old `waiting on Sean` issues closed or re-asked in one sitting with Sean.
  **Size: a session (Sonnet) for the docs, a session (Sonnet) for the setup script, half for the judge
  rounds.**

### 10. The cloth solver as built won't dress a crowd

- **Evidence (logged, traced by the sweep).** The solver exists (`addons/saltcreek_native/src/cloth.rs`,
  2,894 lines). `docs/briefs/garment-cloth.md` sets "at most 0.5 ms a tick" (line 23) and records
  1.3, 7.2 and 6-10 ms a tick at Sean's in its steps (lines 77, 87, 99). Each garment is its own node
  stepping on the main thread (`cloth_core.rs:3`; `solver_cloth.gd:256-274`), outside the people's
  bands; its mesh is rebuilt every tick; the wearer's skin is skinned vertex by vertex in GDScript
  (`worn_garment.gd:694-719`). The `cloth` timer sits inside People's 4.0 ms with no row of its own.
- **Why it matters.** The slice's list has the solver's remaining steps going to clothes, flags and the
  stage curtain. One glove on Harlan is affordable. A vest on each of twenty townsfolk is not, and
  finding 2 already has no room.
- **Fix.** Decide the scope first: for the slice, the solver runs on Harlan's hands, flags and the
  curtain (a handful at once, capped), and townsfolk's clothes stay skinned. Then: its own budget row,
  the step moved to the pool a tick behind, the skinning into Rust. **Size: Sean's call, then about two
  sessions (Opus) inside the brief's remaining six.**

## Smaller ones

- **Mission lines live twice.** The scripts in `docs/scripts/` "lead"; the game says `config/moments/`.
  `docs/scripts/CHANGES.md` lists about fifty lines that differ, waiting on Script OK (#1059). Only the
  town's script has a test holding the two together (`tests/test_town_script.gd:36`). After the OK: a
  generator, as the town has. Half a session.
- **Town lines: five stores, eight pickers**, each with its own no-repeat rule (`CivilianBrain.LINES`,
  `town_script.json`, `valley_folk.json` `talk.sets`, `FetchHelp.LINES`, `town_news.gd:806-863`).
  "Gun out" has two wordings. Fold the constants into the town's script before #1293 writes each man's
  overheard lines into yet another place. A session.
- **The old town is still a second world**, and the default for every `-s` run and `bridge.py start`
  (`settings.gd:245-254`): 25 test files, the soak's second leg, the goldens, the tour, about 3,660
  lines only it uses. The last review's C2; not started. First step: script runs default to the valley.
- **`experiments/` ships in the build (inferred).** `export_presets.cfg:11` excludes only `tests/*` and
  `tools/*`. The one real tie is two walk clips (`human_body.gd:2704`). Move them, exclude the folder.
- **Making a man is written about thirteen times** (`HumanBody.new()` plus id, seed and model in seven
  mission files, the folk, the old town, the bridge). One `People.make`. Half a session.
- **The coach and farmhouse are still off `Act`**: their lines skip `Events.spoke`, so no mouth moves.
  After the slice (neither is in it).
- **The barkeep shot mid-pour still pours** and keeps the coin (`bar_service.gd:309-316`: the pour
  finishes on a timer with no check that he can). A ten-line test and a check.
- **The card table has no side pot**: a short stack that calls can win the whole pot
  (`card_game.gd:797-799`, inferred), and chips in the pot when you stand ride to the next hand.
- **A freed townsman can reach a typed variable** at fourteen places in `valley_folk.gd`
  (`var man: HumanBody = people.get(id)`); one place already guards for it (`:1520`). Inferred.
- **Player down outside the hideout** has no handler in the camp, the cabin, the funeral or the murder
  (the last review's A8, left open by #864).
- **Sleep refused during a Moment** (`player_sleep.gd:128-129`) has no test, and the save's "nobody
  sleeps in an act" rests on it.
- **Flags:** 89 `--flags` read at 76 places in 40 files, no helper; six have no caller. Dead:
  `src/render/outline.gd`, `Settings.probe_soft`.
- **`test_town_streets` is 974 s**, a tenth of the suite in one file; it sets every shard's floor.
- **`visual.yml` still hides failures** with `|| true` at lines 92, 101, 146 (the last review's B7).
- **`GameReset.clear_world` still leaves `OutlawBrain.d_fixes` and `Structure.runaways`**
  (`game_reset.gd:73`).

## What became of the last review (2026-11-12)

| Finding | Now |
|---|---|
| A1 nothing runs the valley | Partly: nightly soak and four smoke legs run it (#877). Goldens, tour, bench: no. |
| A2 lab code builds the game | Fixed (#975): the builder and specs are in `src/` and `config/`. |
| A3 people over budget | Measured and cut once (#865, #904); over again (finding 2). |
| A4 valley load 12 s | Worse: 37 s here (finding 5). |
| A5 a reset keeps the story | Fixed (#864). |
| A6 no save | Fixed (#1138, #1148, #1154); see finding 4. |
| A7 soak red for the wrong reason | Fixed (#877); red again for other reasons and unread (finding 7). |
| A8 knocked out, you wake nowhere | Partly: `WorldPlaces`; no shared player-down rule. |
| B1 four mission scaffolds | Partly: seven acts extend `Act`; starts are still a ladder (finding 1). |
| C1 three giant files | Open, all bigger; two new ones (finding 8). |
| C2 retire the old town | Not started. |

## Appendix: main red, 2026-11-13 to 11-27 (from the status logs)

11-13 `test_seated_falls` (#904) · 11-17 to 19 `test_card_game`, `test_no_law_carry`, shard order (#1077) ·
11-20 `test_town_day`, men wedged (#1094) · 11-20 `test_sheriff`, order · 11-21 `test_town_day` after the
shards reshuffled · 11-23 a settle flake (build 5335) · 11-24 the carry at saloon B's door, CI only, first
diagnosis wrong (#1251) · 11-24 the card game, Earl's chair (#1257) · 11-25 the street at noon said eight
lines (#1240, a real fault) · 11-26 `test_no_justice_whole`, the lean-to in the air (#1271) · 11-26 the
shack walk, run 8 (#1291) · 11-27 the save test's barrel (#1315).
