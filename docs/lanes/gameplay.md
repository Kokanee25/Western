# Gameplay lane: current state

Branch `claude/gameplay-…`. Everything that isn't art, characters or props: missions, people, weapons,
structures, blast, the valley, performance, CI. Replace your lines here at the end of a session; no history
(that goes in `docs/status/` and the PR). Keep under ~10 KB. Full history to 2026-11-11:
`docs/status/current-state-2026-11-11.md` "Gameplay", "The masonry lab", "The horse".

## The slice's missions (LAYOUT "src/missions", "src/moments")
- **The sheriff on the road** (#746, build 3698): `-- --world=valley --mission=sheriff`; `StoryState`,
  `HeadGesture`, `Act`. Waiting on Sean: #755.
- **No Law** steps 1-5 done (`ValleyFolk`, `PlayerSeat`, `CardGame`, `NoLawMurder`, `SheriffDies`, `Funeral`;
  `experiments/valley_folk/README.md` "Step 4", "Step 5"). Cody isn't the red shirt (the red shirt, Silas
  Kett, shot the sheriff; nobody names him yet). The morning after: Earl to the undertaker's, day folk's lines
  by the story's facts (`talk`); the sheriff dies on the doctor's cot (`-- --mission=sheriff_dies`); the story's
  Harlan is unarmed till then. **The funeral** (#868, `-- --world=valley --mission=funeral`): the day after, at
  ten, at the cemetery; nolaw.funeral = attended / distance / missed, nolaw.offer_heard, baron.met; mourners
  are the folk's own men (`borrow`/`give_back`: never built in play). No Law's script still isn't OK'd (#835).
  Open at the funeral (playtest `docs/playtests/2026-11-13-funeral.md`): nothing but the townsman's word says
  it's on (a bell is sound's); the grave's filled unseen, never if you stay (no sexton); the mourners don't
  turn to who's speaking; plain blocks for the box, grave and headboards (the prop lab's to make); the widow's
  model reads as a man at 6 m and the preacher has nothing clerical (characters'); the Baron and foreman are
  stand-in models; no children; the townsman walks up at 1.2 m/s (4 min from the hotel).
  Open from step 4: the badge stays drawn on the dying sheriff's chest; the wife's `sit_back` hands float; Earl isn't seen laid out; the wife's "Were you with him?" doesn't
  wait; nobody minds a drawn gun by day. **Next: the whole mission played end to end on the real clock and its
  seams mended (#876).**
- **No Justice** (plan on #843: 1 Joe, 2 the doctor's and the camp, 3 the hideout fight at the valley's
  `hideout` box canyon, 4 the cabin, the knife and the nod). **Steps 1-2 done.** Joe (`CompanionBrain`;
  `-- --joe`, bridge `joe`, the lab's `joe=1`/Shift+Y, `--joe-tune=k:v+k:v`) helps since #859: he may shoot the
  man you fire at, minds the men on you, draws their eyes (`experiments/gunfight_lab/results/2026-11-13_joe_helps/`:
  hits you take -1/3; survival can't be measured under a few hundred fights a side). Open: he's in your line
  ~0.7 s a fight; his cover should keep off the line between you and your man. Step 2: `NoJusticeCamp`
  (`config/moments/no_justice_camp.json`; `-- --world=valley --mission=no_justice`, bridge
  `moment no_justice_camp set_up=1`; valley_bench `ute_camp`). Open: Joe's hat (the stand-in "whole" model drops
  it; characters lane), no survivors shown (till the Studio has them), no line for a shake then following him
  out, the valley's marker posts; playtest `docs/playtests/2026-11-13-camp.md`. Riding waits on #478.
  **Next: step 3, the hideout fight.**
  Joe on the rope later: 3-4 shots or close in (#744); the rope turns `spared` off.
- Story decisions: #744's latest comments and STORY.md; the story bible is #809.
- **Townsfolk behaving realistically** (Sean 2026-11-12, #850; `docs/briefs/townsfolk.md`, 11 steps; #851's
  picks all answered). **Step 2 done (#870):** the day and the book (`ValleyFolk` `day`/`spots`/`book`/`calendar`,
  `TownBook`, `BookLights`; a new person is one entry; nobody in or out at a door in view). **Next: step 3, the
  roster as data** (the 16 people's days, homes, dials; the street's and buildings' spots). Step 1's perception
  leaks still wait. Open: BookLights' panes are greybox (art's fronts); a man the player follows into a real
  interior still goes onto the book at its door; spot-to-spot moves are built but no one has two spots yet.

## Systems the slice leans on
- **The valley** (#467, `config/valley.json`, `tools/valley/`; LAYOUT "src/world/town_layout.gd"): G1-G7 done,
  heights (#736). **Saloon B's frame is on its lot** (art, #848: `experiments/building_lab/saloon_b/` README).
  No Law's set is still in the yard (no switch built): to move it in, `config/valley_folk.json`'s `set` goes to
  the saloon lot's floor (the walk's top, not the ground: `ValleyFolk.ground` gives the pad under the floor), using
  the spec's own `no_law_table` (under the well) and bar instead of spawning a second set, with ways in by the
  corner door. Payday Night: `SpecBuilding.saw_girder()` with the dancers' weight on the dance floor's boards.
- **Falls from height** done (#759, `Falls`, `config/falls.tres`).
- **Winchester 1873 in the game** (#792; key 6, `Rope`, the rope range at F5's last stop). Waiting on Sean's
  play. Parked: men carrying it (#800).
- **The Colt** (#693 step 1 approved). Harlan's arms are characters' (#693).
- **The coach heist** (#794, #815, PR #839; `experiments/coach_heist/` README "After the hit"): `SwingingRam`,
  `Dents`/`DentWatch`, `CoachDrive`, `CoachCut` (`-- --world=valley --mission=coach`), and `CoachFight`: the
  guards dazed, up inside the wreck, one in the door on top, the rest out to the lee; the strongbox hauled out,
  padlock shot, papers taken or the box shouldered; won up the rimrock trail, Enter again; StoryState `coach.*`.
  8 scripted runs (`fight_runs.py`): won 5, lost 2, one standoff; worst frame ~32 ms at Sean's. Open: the throw
  breaks most of the guards' bones (BodyImpacts inside the coach), so most give up without firing; the playtest
  (`docs/playtests/2026-11-12-coach.md`): no horses, the rescue loop. Next: #840.
- **Gunfight D+** (#633 bugs; difficulty #349 is Sean's).
- **The valley's frame bench** (#865, `docs/reviews/2026-11-valley-bench.md`): `perf_bench --world=valley
  --townsfolk=N [--band=] [--bodies] [--spikes=MS]`, `tools/valley/bench_runs.py`. **The cuts are in (#881,
  the review's "After the cuts")**: far men ~0.3 of a near man (`PeopleTickTuning.seen_nearer_far`,
  `aim_needs_sights`), calm men look at calm men every 2nd look (`calm_look_every`, `HumanBody.tick_calm`),
  fingers posed on change; day with 25 ≈ 3.5 on #865's scale (4.9 on the slower workspace that measured it):
  **the brief's 24 fit**. The valley's spec buildings warm their first analysis on a worker
  (`Structure.warm_analysis`; the valley has no FireSystem, so a settle is whole on one frame). `max_bodies`
  65,536. Train past 400 m `Train.distant`. Open: every scene's else is over (~1 ms untimed engine share, the
  train ~0.4 near, RoomLight ~0.2); the outlaws' first cover moves (~120 ms twice at a fight's start, ~21k
  walk casts); the gunfight's people are over (its men at full rate by design).

## Parked until after the slice
train (#542 step 7; waiting #553, #557, #601) · trestle (#638, #658) ·
dynamite (#596; #656 waiting; PR #683 open; bundles #647, #682) · masonry step 3 (#667) · horse (#341,
riding #478) · farmhouse (#565, #573, #651) · men dying on the run (#483) · perf step 9 (#401) · Payday
Night floor lab (#745).

- **Resets and places** (#864, the review's R3): a reload wipes the story (`GameReset`; No Law plays again after
  Backspace); a mission's retry starts from the story at its start (`GameReset.retry`, `StoryState.mark_checkpoint`).
  `WorldPlaces`: knocked out in the valley you wake at its doctor's (`bedside`), else the store's walk; the outlaws'
  street spot is the loaded world's. Open from R3: no shared "player down" rule (the sheriff and No Law don't watch
  for it); the farmhouse's points still carried from the old town (C2); Moment `point()` falls back to coordinates.

## Open problems
- **The card game's chair tests** (#834) fixed: crawling, light rubble is let through and shoved aside
  (`Player._wade`); a man knocked down mid-rise is let through the pieces in him (`HumanBody._spare_ragdoll`).
  Two traps left: the kit chair's pieces keep collision exceptions to freed bodies (`get_collision_exceptions`
  on one errors: test by `body_test_motion`); two test suites at once collide on the bridge port and `user://`.
- **The nightly checks run the valley and the missions** (#863, `nightly.yml`): soaks of the town and the
  valley; smoke legs for the valley, the sheriff, No Law (`sheriff_dies`) and the coach; a red night opens a
  `nightly red` issue. The orphan rule counts only what isn't held on purpose. Not yet in the valley: the
  goldens and the tour (art's views); the bench is by hand (`perf_bench --world=valley`, below). Rubble growth is by design (DESIGN §8).
- White patches (#670): not reproduced, waiting on Sean's F12.

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
- The native plugin builds here (`cargo build --release`, ~3 min; copy the `.so` into `bin/`).
- The valley bench: the drawn runs take ~6 min each (80 s of shader compiles). Workspaces' cores differ (one
  read 38% slower at 25): compare against a baseline from the same workspace; the noise is ±0.35.
- Bridge commands: LAYOUT "The dev bridge"; a lab's own commands in `experiments/<lab>/bridge.gd`.
