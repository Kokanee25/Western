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
  **The night's carry (#1057):** Cody's ball through Earl's collarbone; the barkeep sends you to Doc's; `PlayerCarry`,
  `PlayerKnock`, `NoLawCarry` (Earl laid in the front room), `tests/test_no_law_carry.gd`. Open: the doctor in the
  doorway can block dragging him in; he's laid on the floor, not "on the table"; carry.street, morning.coat and the
  undertaker's lines aren't wired; the coat isn't drawn bloody. The funeral (#868) as it was. No Law's script
  isn't OK'd (#1059). **Next: the whole mission played end to end, its seams mended (#876).**
- **No Justice: steps 1-4 done** (#843's plan; each `-- --world=valley --mission=<m>`, bridge `moment <m> set_up=1`).
  Joe is `CompanionBrain` (`--joe`, the lab's `joe=1`, `--joe-tune`); `held`, a scene walks him and he doesn't step out
  of your line. 2: `NoJusticeCamp` (`no_justice`). 3: `NoJusticeHideout` (`no_justice_hideout [--arrive]`), ends
  `nojustice.kett` = holed_up / dead_outside / down_outside / dead_inside, then starts 4: `NoJusticeCabin` (#966,
  `no_justice_cabin [--down]`): kicks add up against the bar; Kett gives up (an OutlawBrain, silent) in the corner;
  Joe's knife and ask; nod / between / gun on either / a shove at Joe / binding Kett = arrest (a card, then Kett bound
  to the jail's door); shake / walking out / silence = revenge (`take_knife`); your ball in him = murder. Facts
  nojustice.ending, answer, joe_trust, camp_trust, joe_saw, bodies, jail.
  **Played whole (#979):** `tests/test_no_justice_whole.gd`; down in the fight, Enter retries it (`retry_on_load`).
  Open: the hideout fight's hard (#349, Sean's); the jail and rides are cards; no line when Kett's jailed (C8 a);
  Joe out cold in the cabin it waits for him. A limp man goes through the player (`HumanBody._through_the_player`, #1092); so the carry lays him with all of him clear of you (`PlayerCarry.LAY_CLEAR_M`).
- **Playtest faults (#1095-#1125)** built. Open: one stick at 1.2-1.7 m takes a foot, a hand, 15-19 wounds; the
  bridge's `tend` on an unhurt man kicks; the slowdown after dynamite and fire.
- Story: #744, STORY.md; the bible #809.
- **Townsfolk** (#850; `docs/briefs/townsfolk.md`, 11 steps; LAYOUT "src/people"). Done 2-10: day and book, roster,
  spots, `Reaction`, `FetchHelp`, `TownNews`, the script (`TownScript`; Script OK waiting on Sean, #1150), regard and
  the barks (`TownRegard`, `TownBarks`), the saloon as a room (#1157: `SaloonRoom`, bridge `read room`).
  **Step 11, the gate** (#1162; `docs/playtests/2026-11-23-town-4.md`): not passed blind; #1213 fixed its last
  faults, then Sean plays it himself (#1208). **#1230: the evening is in saloon B** (Sean on #755): the set is the
  building's own (`set.hall`, `_bind_hall_set`: its bar, `no_law_table` and chairs by compass, the piano corner; the
  band's ordinary nights there), the barkeep behind its bar day and night, the spots its use points, ways
  `saloonb_*` (each swept straight: a test); No Law in by the corner door, out down the front steps; twelve fit.
  Facts still say "yard" (`nolaw.seen_from`, `nolaw.earl_died`). Unjudged on screen: the walks, the room. Open: the
  room's sounds are synth stand-ins (#807); no argument, round bought or song called for; react.fight*, body_child,
  kett.meal untriggered; nobody carries the body.
  A spot's `hall` is its building for the barks (`bark_ctx`, #1240: hall spots had lost the saloon's lines).
- **Every verb gets an answer** (DESIGN §2 pillar 6; #1272 step 1 the shove and the shot, #1279 step 2 the card
  table): the bench `experiments/answers/` (README: the table a verb, before and after). The table (LAYOUT CardGame
  "The table answers you"): fire raises, G sat calls a cheat; each verb a line at once, `you_did` -> regard and
  TownNews `table` (a pot, a bluff shown up, a cheat called told later). Still flat: standing close (nothing), the
  barkeep's "Don't shoot!" over and over; the bench's "said" column counts the table's own game talk too.

- **The drink** (#1292; LAYOUT "src/player" PlayerPurse/PlayerDrink, "src/people" the bar; `config/drink.json`):
  a purse (saved; the card stake from it), E at saloon B's bar (tap whiskey, hold beer/the bottle, G a round), the
  barkeep pours a kit bottle into a kit glass, the glass in your hand, the dial (sway, settle, nerve, the walk
  weaves). Answers: round, deputy, drunk, alone; news `bar`. Unjudged on screen: the hand round the glass, the pour.
  12 + 6 lines for Sean's script OK (#1150). Open: only the valley's bar has a BarService (no old town, no hotel).
- **The town drunk** (#1312; LAYOUT "src/people" The town drunk; `TownDrunk`, `DrunkNotes`, `config/drunk_notes.json`):
  Sarge in the valley (`town_drunk`), a jibe a meeting from 124 (TownBarks `you`/`sober`), answers (nod, shake, shove, a
  glass given, G walks him to the jail; nerves of steel, `steady`), the street's word, regard, news; eleven notes by data. Read blind twice; Sean's
  script OK (#1150). Open: no privy in the valley (the picture's on the livery); no mud or water on Harlan (no tags).

## Systems the slice leans on
- **Ride there** (#1120, `RideThere`; LAYOUT "src/creatures"): E at a tied horse, a fade, the clock on, you at the place's
  rail; bridge `ride [PLACE]`; saved where he's tied (#1154). Open: unjudged on screen.
- **Saving by sleeping** (#1138, #1148, #1154 steps 1-3 done; `docs/briefs/saving.md`, LAYOUT "src/save"): `SaveGame`;
  E at a bed (group `beds`: spec `use: sleep` points) sleeps to 06:00 and saves (`PlayerSleep`); `ContinueCard` at a
  plain start; `load_slot` reloads with it. A hurt man indoors stays hurt (`ValleyFolk.kept`, run on by the clock;
  can't stand: laid up; dead in there: `died_indoors`). A kit prop's contents are kept (`contents`: level, let go;
  a barrel knocked over whole loads shut, #1315). Open: the doctor doesn't tend a laid-up man; the brief's
  "Not yet"; no start in play for No Justice; Harlan's bed once #1126's spec has a `sleep` point.
- **The valley** (#467, `config/valley.json`, `tools/valley/`; LAYOUT "src/world/town_layout.gd"): G1-G7 done;
  G8 step 1 (#1098): a plain start is the valley (`Settings.world_for`); script runs and the bridge keep the town.
  **Saloon B's frame is on its lot** (art, #848: `experiments/building_lab/saloon_b/` README).
  No Law's night is in saloon B's bar room (#1230; `ValleyFolk.floor_under` for its floor). Payday Night: `SpecBuilding.saw_girder()` with the dancers' weight on the dance floor's boards.
- **Scenes that hold their cast** (#1050, `SceneHold`; LAYOUT "src/people"): an act claims its men, marks, chairs and
  a quiet zone; your shot, drawn gun, hit or step onto a mark lets go on that frame. On it: No Law's murder (the
  stranger, Cody), the cabin (Joe, no breaks), a card hand's chairs. Not yet: No Justice's camp and hideout (Joe's
  `held` set by hand), the sheriff's scenes, the funeral (#1050's handover).
- **Winchester** (#792, key 6; waiting on Sean's play, #801). **The Colt** (#693). **Gunfight D+** (#633; #349 is Sean's).
- **Benches:** chaos (`docs/reviews/2026-11-chaos-bench.md`, `perf_bench --scene=chaos [--world=valley]`; open:
  `kit_blast` ~130 ms after saloon B's sticks); the valley (`docs/reviews/2026-11-valley-bench.md`, `--townsfolk=N`:
  24 fit; open: ~1 ms untimed, the outlaws' first cover moves ~120 ms).
- **Building memory** (#1259, #1262, #1270; `docs/reviews/2026-11-member-memory.md`, `tools/member_memory.gd`): hotel
  18.6 KB a member (held to 20); resting members' nodes are rows (ask `drawn_node()`, not `pieces`). 15 KB: #1275.
- **CI runs what a PR needs** (#1234, LAYOUT "CI"): `config/test_map.json` + `tools/test_select.py` (core set + mapped
  tests, up to 8 shards); main runs all 8. A test moving into the valley joins the map's `valley`/`missions` group.
- **Flaky in shard order:** `test_town_day`'s fights. **Two collapses** (#1214): compare with impacts off.
- **Resets and places** (#864): `GameReset` (reload wipes the story; `retry` from the mission's checkpoint);
  `WorldPlaces` (knocked out in the valley you wake at its doctor's).

## Open problems
- **The valley's people tests** (#925): sample a people test's odds by running its scene many times in one
  process, each start shifted a few frames (#1248: a run here is deterministic; CI's shard order isn't).
  Traps: `intersect_shape(q, N)` on `Layers.WORLD` counts standing members toward N; CI draws differently from a
  workspace (#1094); a kit chair's pieces keep exceptions to freed bodies (test by `body_test_motion`).
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
- A fresh container has no Godot (the 4.7.2 zip from GitHub to ~/.local/bin) nor native plugin: `cargo build --release`
  in it (2.5 min), the .so to `bin/`, then `godot --headless --import` (~10 min).
- Bridge commands: LAYOUT "The dev bridge". `bridge.py start` is the old town (the gang, the store, the widow) unless
  `--game-args=--world=valley` or a story `--mission=`; the clock's held (`clock on`).
