# Gameplay lane: current state

Branch `claude/gameplay-…`. Everything that isn't art, characters or props: missions, people, weapons,
structures, blast, the valley, performance, CI. Replace your lines here at the end of a session; no history
(that goes in `docs/status/` and the PR). Keep under 10 KB (a test fails the build over it). History: `docs/status/`.

## The slice's missions (LAYOUT "src/missions", "src/moments")
- **The sheriff on the road** (#746): `-- --world=valley --mission=sheriff`; `StoryState`, `HeadGesture`, `Act`.
  #1081: carried in over the shoulder (not dragged: Sean), a knock brings the doctor by day; a slow nod answers.
  The clock runs at a quarter of the day's rate till it's over (#1082: in by about 08:00). Waiting on Sean: #755. The carry's pose is unjudged on a real screen.
- **No Law** steps 1-5 done (`ValleyFolk`, `PlayerSeat`, `CardGame`, `NoLawMurder`, `SheriffDies`, `Funeral`;
  `experiments/valley_folk/README.md`). Cody isn't the red shirt (Kett); the stranger shot the sheriff (#905).
  **The night's carry (#1057):** Cody's ball goes through Earl's collarbone (`aim` subclavian_r: down, ~25 ml/s,
  dead ~146 s on); the barkeep sends you to Doc's; `PlayerCarry` (E: over the shoulder, no trail), `PlayerKnock` (E at
  a door; `ValleyFolk.knocked`), `NoLawCarry` (the doctor out, his lines, Earl laid in the front room under a
  stand-in sheet, `ValleyFolk.lay_out`); in the morning SheriffDies' doctor says morning.body by him, the
  undertaker's after the sheriff's dead. `tests/test_no_law_carry.gd`. Open: the doctor in the doorway can block
  dragging him in yourself (the test lets go on the step); "on the table" in carry.lay but he's on the floor;
  carry.street, morning.coat and the undertaker's lines by the body aren't wired; the coat isn't drawn bloody
  (`blood_on_you` is a number). The funeral (#868) as it was. No Law's script
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
  Open: the hideout fight's hard (#349, Sean's); the jail and rides are cards; no line when Kett's jailed (C8 a);
  Joe out cold in the cabin it waits for him. A limp man goes through the player (`HumanBody._through_the_player`, #1092); so the carry lays him with all of him clear of you (`PlayerCarry.LAY_CLEAR_M`).
- **Playtest faults (#1095, #1106, #1111, #1116):** one doctor (`ValleyFolk.seize`, `lends`); a knock brings a hurt
  man's doctor (`FetchHelp.at_door`). The shack door: a set count of kicks (`kick_share`, `takes_kicks`). Joe down: held
  E by his wound binds and splints him (`NoJusticeCabin._aid_step`, `Physiology.bind_up`/`splinted`), he limps in, the
  knife waits. The office is a `SceneHold` your shot breaks; Joe ducks, "Stop", turns on you after 3 (`CompanionBrain.turned`).
  Hurt townsfolk go, get up or call (`CivilianBrain.hurt`, `_lying`). `OutlawBrain.careful` (Joe, armed townsmen) holds
  fire for anyone in the line; outlaws only for mates (DESIGN §7). Tests `test_chaos_faults`, `test_hurt_townsfolk`.
  Open (chaos round): the slowdown after dynamite and fire (its own issue); two townsmen on one spot; the rifle's
  `shoot 2`; walks stopping at posts.
- Story decisions: #744's latest comments and STORY.md; the story bible is #809.
- **Townsfolk behaving realistically** (#850; `docs/briefs/townsfolk.md`, 11 steps). Done: steps 2 (the day and
  book), 3 (roster as data), 4 (spots, `SpotChore`), 5 reactions in stages (#982, `Reaction`,
  `tests/test_reactions.gd`; LAYOUT "src/people"). **6 the runner (#1040, `FetchHelp`, `tests/test_runner.gd`, bridge `read fetch`)**. **Next: step 7, the town's news.** Open:
  the noon street is too thin for anyone to run (playtest 2026-11-17-runner: three men, low duty); a body found later
  isn't a stimulus; shaken only changes the next start; refuges are door points; chores' props stand-ins; no talk sound.

## Systems the slice leans on
- **The valley** (#467, `config/valley.json`, `tools/valley/`; LAYOUT "src/world/town_layout.gd"): G1-G7 done;
  G8 step 1 (#1098): a plain start is the valley (`Settings.world_for`); script runs and the bridge keep the town.
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
- **The Colt** (#693 step 1 approved). **Gunfight D+** (#633; difficulty #349 is Sean's).
- **The chaos bench** (#1117, #1119, #1123, `docs/reviews/2026-11-chaos-bench.md`): `perf_bench --scene=chaos
  [--world=valley] [--spikes=MS]`. Valley brain frames now under 33 ms: town ways bounded (#1119); a cover search step
  spread by a `WorkBudget` (`Cover.Pick`, `STEP_MS`/`STEP_ASKS`, same spots; #1123). Open: saloon B's blast frame
  (~600 ms, `settle_analyse`: no FireSystem in the valley to slice a settle, #1123's next issue); Jolt's awake pieces.
- **The valley's frame bench** (#865, `docs/reviews/2026-11-valley-bench.md`): `perf_bench --world=valley
  --townsfolk=N`, `tools/valley/bench_runs.py`; 24 townsfolk fit (#881). Open: every scene's else is over (~1 ms
  untimed), the outlaws' first cover moves (~120 ms twice at a fight's start), the gunfight's people.

- **The garment handoff** (#917-#1029; LAYOUT "src/bodies"): `GarmentHandoff`, `GloveAct` on `SolverCloth`.
- **CI's tests in six shards** (#1015; LAYOUT "CI", "tests"): `test (K/6)` by `config/test_times.json`; refresh
  it with `tools/test_times.py` from the shards' logs when one runs long. Each file starts from cleared statics.
  Locally one shard at a time (~4 GB each: two at once are OOM-killed in 8 GB).
- **Flaky in shard order:** `test_town_day`'s fight tests (physics luck; one fails now and then on shard 3). Locally
  `test_no_law_carry` (shard 2) has failed in shard order but passes on CI.
- **Resets and places** (#864): `GameReset` (reload wipes the story; `retry` from the mission's checkpoint);
  `WorldPlaces` (knocked out in the valley you wake at its doctor's).

## Open problems
- **The valley's people tests** (#925): sample a people test's odds by running its scene many times in one
  process, not the suite again. Traps: any `intersect_shape(q, N)` on `Layers.WORLD` counts standing members toward N; CI's machine draws
  differently from a workspace's (the same commit fails there and passes here): nudge the test's setup a few cm
  in a scratch test (5 variants) to find CI's path, then print the men's state each second (#1094);
  the kit chair's pieces keep collision exceptions to freed bodies (`get_collision_exceptions` on one errors:
  test by `body_test_motion`); two test suites at once collide on the bridge port and `user://`.
  `run_tests.gd -- --only=a,b,c` takes a list; `-- --no-buildings` is the valley without its spec buildings.
- **The nightly checks run the valley and the missions** (#863, `nightly.yml`): soaks, smoke legs (valley, sheriff,
  `sheriff_dies`, coach); a red night opens a `nightly red` issue. Trap: a `.gdignore` drops its folder from the pack.
  Not yet in the valley: the goldens and the tour (art's views).

## Traps
- A `-s` script can't build a structure (autoloads); probe through a test or the bridge. A `-s` tool must
  `load()` GameQuit, not name it.
- Never measure two games at once; compare alternately. The lab's `--deterministic` keeps the workers'
  merges off: crashes in threaded paths need runs without it.
- After merging main mid-run: `godot --headless --import` before the next game. Never edit
  `outlaw_brain.gd` while `run.py` runs.
- Tests at night in the valley turn the murder off (`-- --no-murder`); a drawn rifle on Main Street sets the
  gang off (use the rope range).
- Sight takes a new structure in at its first look (look once at the build).
- A fresh container has no native plugin (`bin/` is ignored): `cargo build --release` in the plugin (2 min,
  crates.io reachable 2026-11-17), the .so to `bin/`, else most game tests fail to load.
- The benches: compare against a baseline run in the same workspace; the valley's chaos fight differs run to run.
- test_town_day's gang fights (#1094): two men wedged shoulder to shoulder in the saloon. A man who gives up a
  cover now fights from where he stands `GAVE_UP_COVER_FIGHT` s; the friend check covers eye to muzzle too;
  the break-off hides you behind the livery (the range is in the saloon door's sight).
- Bridge commands: LAYOUT "The dev bridge"; a lab's own commands in `experiments/<lab>/bridge.gd`.
