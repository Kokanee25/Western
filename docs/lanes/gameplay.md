# Gameplay lane: current state

Branch `claude/gameplay-…`. Everything that isn't art, characters or props: missions, people, weapons,
structures, blast, the valley, performance, CI. Replace your lines here at the end of a session; no history
(that goes in `docs/status/` and the PR). Keep under 10 KB (a test fails the build over it). History: `docs/status/`.

## The slice's missions (LAYOUT "src/missions", "src/moments")
- **The sheriff on the road** (#746): `-- --world=valley --mission=sheriff`; `StoryState`, `HeadGesture`, `Act`.
  #1081: dragged in by the collar, a knock brings the doctor by day; a slow nod answers. Waiting on Sean: #755, #1082
  (the clock: dragging him in takes the morning at the day's rate). The drawn game under lavapipe hung there
  (OOM; headless it doesn't); a 485 m drag lays ~1,900 smear decals (`after slice` if it costs on a GPU).
- **No Law** steps 1-5 done (`ValleyFolk`, `PlayerSeat`, `CardGame`, `NoLawMurder`, `SheriffDies`, `Funeral`;
  `experiments/valley_folk/README.md`). Cody isn't the red shirt (Kett); the stranger shot the sheriff (#905).
  **The night's carry (#1057):** Cody's ball goes through Earl's collarbone (`aim` subclavian_r: down, ~25 ml/s,
  dead ~146 s on); the barkeep sends you to Doc's; `PlayerCarry` (E: by the collar, dragged), `PlayerKnock` (E at
  a door; `ValleyFolk.knocked`), `NoLawCarry` (the doctor out, his lines, Earl laid in the front room under a
  stand-in sheet, `ValleyFolk.lay_out`); in the morning SheriffDies' doctor says morning.body by him, the
  undertaker's after the sheriff's dead. `tests/test_no_law_carry.gd`. Open: the doctor in the doorway can block
  dragging him in yourself (the test lets go on the step); "on the table" in carry.lay but he's on the floor;
  carry.street, morning.coat and the undertaker's lines by the body aren't wired; the coat isn't drawn bloody
  (`blood_on_you` is a number); nobody answers a knock but an act. The funeral (#868) as it was. No Law's script
  isn't OK'd (#1059). **Next: the whole mission played end to end, its seams mended (#876).**
- **No Justice: steps 1-4 done** (#843's plan; each `-- --world=valley --mission=<m>`, bridge `moment <m> set_up=1`).
  Joe is `CompanionBrain` (`--joe`, the lab's `joe=1`, `--joe-tune`); `held`, a scene walks him and he doesn't step out
  of your line. 2: `NoJusticeCamp` (`no_justice`). 3: `NoJusticeHideout` (`no_justice_hideout [--arrive]`), ends
  `nojustice.kett` = holed_up / dead_outside / down_outside / dead_inside, then starts 4: `NoJusticeCabin` (#966,
  `no_justice_cabin [--down]`): kicks add up against the bar; Kett gives up (an OutlawBrain, silent) in the corner;
  Joe's knife and ask; nod / between / gun on either / a shove at Joe / binding Kett = arrest (a card, then Kett bound
  to the jail's door); shake / walking out / silence = revenge (`take_knife`); your ball in him = murder. Facts
  nojustice.ending, answer, joe_trust, camp_trust, joe_saw, bodies, jail. Playtests `docs/playtests/2026-11-1[345]-*.md`.
  **Played whole (#979):** `tests/test_no_justice_whole.gd`, the doctor's to each ending at pace 1, by keys and
  balls; down in the fight, Enter retries it on the slope (`NoJusticeHideout.retry_on_load`, its checkpoint).
  Open (playtest 2026-11-15-nojustice-whole): the hideout fight's hard (#349, Sean's); the clock's held; the jail
  and rides are cards; no line when Kett's jailed (C8 a, Sean's).
  Riding waits on #478.
- Story decisions: #744's latest comments and STORY.md; the story bible is #809.
- **Townsfolk behaving realistically** (#850; `docs/briefs/townsfolk.md`, 11 steps). Done: steps 2 (the day and
  book), 3 (roster as data), 4 (spots, `SpotChore`), 5 reactions in stages (#982, `Reaction`,
  `tests/test_reactions.gd`; LAYOUT "src/people"). **6 the runner (#1040, `FetchHelp`, `tests/test_runner.gd`, bridge `read fetch`)**. **Next: step 7, the town's news.** Open:
  the noon street is too thin for anyone to run (playtest 2026-11-17-runner: three men, low duty); a body found later
  isn't a stimulus; shaken only changes the next start; refuges are door points; chores' props stand-ins; no talk sound.

## Systems the slice leans on
- **The valley** (#467, `config/valley.json`, `tools/valley/`; LAYOUT "src/world/town_layout.gd"): G1-G7 done,
  heights (#736). **Saloon B's frame is on its lot** (art, #848: `experiments/building_lab/saloon_b/` README).
  No Law's set is still in the yard (no switch built): to move it in, `config/valley_folk.json`'s `set` goes to
  the saloon lot's floor (the walk's top, not the ground: `ValleyFolk.ground` gives the pad under the floor), using
  the spec's own `no_law_table` (under the well) and bar instead of spawning a second set, with ways in by the
  corner door. Payday Night: `SpecBuilding.saw_girder()` with the dancers' weight on the dance floor's boards.
- **Scenes that hold their cast** (#1050, `SceneHold`; LAYOUT "src/people"): an act claims its men, marks, chairs and
  a quiet zone; your shot, drawn gun, hit or step onto a mark lets go on that frame. On it: No Law's murder (the
  stranger, Cody), the cabin (Joe, no breaks), a card hand's chairs. Not yet: No Justice's camp and hideout (Joe's
  `held` set by hand), the sheriff's scenes, the funeral (#1050's handover).
- **Winchester 1873 in the game** (#792; key 6, `Rope`, the rope range at F5's last stop). Waiting on Sean's
  play. Parked: men carrying it (#800).
- **The Colt** (#693 step 1 approved). Harlan's arms are characters' (#693).
- **Gunfight D+** (#633 bugs; difficulty #349 is Sean's).
- **The valley's frame bench** (#865, `docs/reviews/2026-11-valley-bench.md`): `perf_bench --world=valley
  --townsfolk=N [--band=] [--bodies] [--spikes=MS]`, `tools/valley/bench_runs.py`. **The cuts are in (#881; the review's "After the cuts"): the brief's 24 townsfolk fit.** The valley's spec buildings warm their first analysis on a worker
  (`Structure.warm_analysis`; the valley has no FireSystem, so a settle is whole on one frame). `max_bodies`
  65,536. Train past 400 m `Train.distant`. Open: every scene's else is over (~1 ms untimed engine share, the
  train ~0.4 near, RoomLight ~0.2); the outlaws' first cover moves (~120 ms twice at a fight's start, ~21k
  walk casts); the gunfight's people are over (its men at full rate by design).

- **The garment handoff** (#917-#1029; LAYOUT "src/bodies"): `GarmentHandoff`, `GloveAct` (bridge `glove MAN`) on our
  cloth (`SolverCloth`, `docs/briefs/garment-cloth.md`); his hand's own skin kept under it (ON); self-meeting off (#1034;
  later #1038, `after slice`). Build the plugin with `NO_PROXY=localhost,127.0.0.1 cargo build --release`, .so to bin/.
  The bridge's real look is OOM-killed in 8 GB: use the bench's stills (`bench.gd -- --shots=... --cam=hands`).
- **CI's tests in six shards** (#1015, PR #1046 merged 2026-11-18; LAYOUT "CI", "tests"): `test (K/6)` by `config/test_times.json`; refresh
  it with `tools/test_times.py` from the shards' logs when one runs long. Each file starts from cleared statics.
  Locally one shard at a time (~4 GB each: two at once are OOM-killed in 8 GB).

## Parked until after the slice
coach heist (#840; `experiments/coach_heist/` README) · train (#542 step 7; waiting #553, #557, #601) · trestle (#638, #658) ·
dynamite (#596; #656 waiting; PR #683 open; bundles #647, #682) · masonry step 3 (#667) · horse (#341,
riding #478) · farmhouse (#565, #573, #651) · men dying on the run (#483) · perf step 9 (#401) · Payday
Night floor lab (#745).

- **Resets and places** (#864): `GameReset` (reload wipes the story; `retry` from the mission's checkpoint);
  `WorldPlaces` (knocked out in the valley you wake at its doctor's).

## Open problems
- **The valley's people tests** (#925, PR #939): three real causes fixed (`HumanBody._spare_rubble`,
  `NoLawMurder._clear_to_head`, `WoundSigns.SMEAR_GAP`), each with a test. Sample a people test's odds by running
  its scene many times in one process, not the suite again.
  Traps: any `intersect_shape(q, N)` on `Layers.WORLD` counts standing members toward N; CI's machine draws
  differently from a workspace's (the same commit fails there and passes here: read the test's own timeline);
  the kit chair's pieces keep collision exceptions to freed bodies (`get_collision_exceptions` on one errors:
  test by `body_test_motion`); two test suites at once collide on the bridge port and `user://`.
  `run_tests.gd -- --only=a,b,c` takes a list; `-- --no-buildings` is the valley without its spec buildings.
- **The nightly checks run the valley and the missions** (#863, `nightly.yml`): soaks of the town and the
  valley; smoke legs for the valley, the sheriff, No Law (`sheriff_dies`) and the coach; a red night opens a
  `nightly red` issue. Each export's smoke runs the town and the valley (#1003). Trap: a `.gdignore`
  drops its folder from the pack (the editor still reads it). The orphan rule counts only what isn't held on purpose. Not yet in the valley: the
  goldens and the tour (art's views); the bench is by hand (`perf_bench --world=valley`, below). Rubble growth is by design (DESIGN §8).

## Traps
- A `-s` script can't build a structure (autoloads); probe through a test or the bridge. A `-s` tool must
  `load()` GameQuit, not name it.
- Never measure two games at once; compare alternately. The lab's `--deterministic` keeps the workers'
  merges off: crashes in threaded paths need runs without it.
- After merging main mid-run: `godot --headless --import` before the next game. Never edit
  `outlaw_brain.gd` while `run.py` runs.
- Tests at night in the valley turn the murder off (`-- --no-murder`); a drawn rifle on Main Street sets the
  gang off (use the rope range).
- lavapipe draws ~1 frame a second: a bridge `wait` under a second misses short poses.
- Sight takes a new structure in at its first look (look once at the build).
- A fresh container has no native plugin (`bin/` is ignored): `cargo build --release` in the plugin (2 min,
  crates.io reachable 2026-11-17), the .so to `bin/`, else most game tests fail to load.
- The valley bench: the drawn runs take ~6 min each (80 s of shader compiles). Workspaces' cores differ (one
  read 38% slower at 25): compare against a baseline from the same workspace; the noise is ±0.35.
- Bridge commands: LAYOUT "The dev bridge"; a lab's own commands in `experiments/<lab>/bridge.gd`.
