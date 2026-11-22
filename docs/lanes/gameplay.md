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
  carry.street, morning.coat, the undertaker's lines aren't wired; the coat isn't drawn bloody. The funeral (#868) as it was. No Law's script
  isn't OK'd (#1059). **Next: the whole mission played end to end, its seams mended (#876).**
- **No Justice: steps 1-4 done** (#843's plan; each `-- --world=valley --mission=<m>`, bridge `moment <m> set_up=1`).
  Joe is `CompanionBrain` (`--joe`, the lab's `joe=1`, `--joe-tune`); `held`, a scene walks him and he doesn't step out
  of your line. 2: `NoJusticeCamp` (`no_justice`). 3: `NoJusticeHideout` (`no_justice_hideout [--arrive]`), ends
  `nojustice.kett` = holed_up / dead_outside / down_outside / dead_inside, then starts 4: `NoJusticeCabin` (#966,
  `no_justice_cabin [--down]`): kicks add up against the bar; Kett gives up (an OutlawBrain, silent) in the corner;
  Joe's knife and ask; nod / between / gun on either / a shove at Joe / binding Kett = arrest (a card, then Kett bound
  to the jail's door); shake / walking out / silence = revenge (`take_knife`); your ball in him = murder. Facts
  nojustice.ending, answer, joe_trust, camp_trust, joe_saw, bodies, jail.
  **Played whole (#979):** `tests/test_no_justice_whole.gd`, the doctor's to each ending at pace 1, by keys and
  balls; down in the fight, Enter retries it on the slope (`NoJusticeHideout.retry_on_load`, its checkpoint).
  Open: the hideout fight's hard (#349, Sean's); the jail and rides are cards; no line when Kett's jailed (C8 a);
  Joe out cold in the cabin it waits for him. A limp man goes through the player (`HumanBody._through_the_player`, #1092); so the carry lays him with all of him clear of you (`PlayerCarry.LAY_CLEAR_M`).
- **Playtest faults (#1095, #1106, #1111, #1116, #1125):** one doctor (`ValleyFolk.seize`, `lends`); a knock brings a
  hurt man's doctor (`FetchHelp.at_door`); the shack's `kick_share`; Joe down: held E binds and splints him
  (`NoJusticeCabin._aid_step`); the office a `SceneHold` your shot breaks, Joe turns on you after 3 (`CompanionBrain.turned`);
  hurt townsfolk go, get up or call (`CivilianBrain.hurt`); `OutlawBrain.careful` (DESIGN §7). #1125: `--mission=no_law`
  (`ValleyFolk.set_up_no_law`; a story `--mission=` picks the valley, the bridge too); the black-out moves the world on
  (`Events.person_left`, `Physiology.pass_time`, `CivilianBrain._hurt_spent`); you mend in a day (`PlayerWounds.mend_hours`,
  `Physiology.mend`/`heal_all`, Sean's #1093); `JoeLost` (Joe turned and gone or dead: a card, Enter again); `slow_why`;
  blast lines (`hurt_blast`); `SEARCH_NEAR_M`.
  Open: one stick at 1.2-1.7 m takes a foot, a hand, 15-19 wounds; the bridge's `tend` on an unhurt man kicks,
  `goto PLACE YAW` ignores the yaw carrying; the slowdown after dynamite and fire; two townsmen on one spot.
- Story: #744, STORY.md; the bible #809.
- **Townsfolk** (#850; `docs/briefs/townsfolk.md`, 11 steps; LAYOUT "src/people"). Done 2-10: day and book, roster,
  spots, `Reaction`, `FetchHelp`, `TownNews`, the script (`TownScript`; Script OK waiting on Sean, #1150), regard and
  the barks (`TownRegard`, `TownBarks`), **the saloon as a room** (#1157: `SaloonRoom` on No Law's yard set, bridge
  `read room`; mood, the director's bits, the hush, the band's shaky restart; 11-12 in at 20:30).
  **Next: step 11, the gate.** Open: the room's laugh, cough and glass sounds are synth stand-ins (#807's takes), no
  walla bed; the second "table" stands (no sat talk); no argument, round bought, song called for, porch smoker;
  the glass can't be drunk; mood numbers unfelt; not in saloon B (No Law's set unmoved); the store's blind, doors
  shutting; react.fight*, body_child, freight, kett.meal, uneasy.heeled untriggered; Senses names a shooter on a
  glimpse; nobody carries the body; the noon street is thin.

## Systems the slice leans on
- **Ride there** (#1120, `RideThere`; LAYOUT "src/creatures"): E at a tied horse, a fade, the clock on, you at the place's
  rail; bridge `ride [PLACE]`. Open: unjudged on screen; SaveGame doesn't keep where your horse is tied.
- **Saving by sleeping** (#1138, #1148 steps 1-2 done; `docs/briefs/saving.md`, LAYOUT "src/save"): `SaveGame`;
  E at a bed (group `beds`: spec `use: sleep` points) sleeps to 06:00 and saves (`PlayerSleep`); `ContinueCard` at a
  plain start; `load_slot` reloads with it. Open: the town mends overnight (a man gone indoors comes out unhurt), the
  brief's "Not yet"; no start in play for No Justice; Harlan's bed once #1126's spec has a `sleep` point.
- **The valley** (#467, `config/valley.json`, `tools/valley/`; LAYOUT "src/world/town_layout.gd"): G1-G7 done;
  G8 step 1 (#1098): a plain start is the valley (`Settings.world_for`); script runs and the bridge keep the town.
  **Saloon B's frame is on its lot** (art, #848: `experiments/building_lab/saloon_b/` README).
  No Law's set is still in the yard: to move it in, `valley_folk.json`'s `set` to saloon B's floor
  (`ValleyFolk.ground`), its own `no_law_table` and bar, ways in by the corner door. Payday Night: `SpecBuilding.saw_girder()` with the dancers' weight on the dance floor's boards.
- **Scenes that hold their cast** (#1050, `SceneHold`; LAYOUT "src/people"): an act claims its men, marks, chairs and
  a quiet zone; your shot, drawn gun, hit or step onto a mark lets go on that frame. On it: No Law's murder (the
  stranger, Cody), the cabin (Joe, no breaks), a card hand's chairs. Not yet: No Justice's camp and hideout (Joe's
  `held` set by hand), the sheriff's scenes, the funeral (#1050's handover).
- **Winchester 1873 in the game** (#792; key 6, `Rope`, the rope range at F5's last stop). Waiting on Sean's
  play. Parked: men carrying it (#800).
- **The Colt** (#693 step 1 approved). **Gunfight D+** (#633; difficulty #349 is Sean's).
- **The chaos bench** (`docs/reviews/2026-11-chaos-bench.md`): `perf_bench --scene=chaos [--world=valley]
  [--spikes=MS]`. Valley: brain frames < 33 ms (#1119, #1123: `Cover.Pick`); a blast's settle sliced by its own
  `SettleQueue` (#1128). Open: `kit_blast` ~130 ms the tick after saloon B's sticks, the blast's own frame ~110 ms; Jolt.
- **The valley's frame bench** (#865, `docs/reviews/2026-11-valley-bench.md`): `perf_bench --world=valley
  --townsfolk=N`; 24 townsfolk fit (#881). Open: else ~1 ms untimed, the outlaws' first cover moves (~120 ms).
- **The garment handoff** (#917-#1029; LAYOUT "src/bodies"): `GarmentHandoff`, `GloveAct` on `SolverCloth`.
- **CI's tests in six shards** (#1015): `config/test_times.json` (`tools/test_times.py`); locally one shard at a time.
- **Flaky in shard order:** `test_town_day`'s fight tests (physics luck; one fails now and then on shard 3).
- **Resets and places** (#864): `GameReset` (reload wipes the story; `retry` from the mission's checkpoint);
  `WorldPlaces` (knocked out in the valley you wake at its doctor's).

## Open problems
- **The valley's people tests** (#925): sample a people test's odds by running its scene many times in one
  process, not the suite again.
  Traps: `intersect_shape(q, N)` on `Layers.WORLD` counts standing members toward N; CI draws differently from a
  workspace (nudge the test's setup a few cm in a scratch test to find CI's path, #1094);
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
- A fresh container has no native plugin (`bin/` is ignored): `NO_PROXY=localhost,127.0.0.1 cargo build --release`
  in the plugin (2.5 min), the .so to `bin/`, then `godot --headless --import` (~5 min).
- Bridge commands: LAYOUT "The dev bridge". `bridge.py start` is the old town (the gang, the store, the widow) unless
  `--game-args=--world=valley` or a story `--mission=`; the clock's held (`clock on`).
