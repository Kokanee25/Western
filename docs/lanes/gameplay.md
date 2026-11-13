# Gameplay lane: current state

Branch `claude/gameplay-…`. Everything that isn't art, characters or props: missions, people, weapons,
structures, blast, the valley, performance, CI. Replace your lines here at the end of a session; no history
(that goes in `docs/status/` and the PR). Keep under ~10 KB. Full history to 2026-11-11:
`docs/status/current-state-2026-11-11.md` "Gameplay", "The masonry lab", "The horse".

## The slice's missions (LAYOUT "src/missions", "src/moments")
- **The sheriff on the road** (#746, build 3698): `-- --world=valley --mission=sheriff`; `StoryState`,
  `HeadGesture`, `Act`. Waiting on Sean: #755.
- **No Law** steps 1-4 done (`ValleyFolk`, `PlayerSeat`, `CardGame`, `NoLawMurder`, `SheriffDies`;
  `experiments/valley_folk/README.md` "Step 4"). Cody isn't the red shirt (the red shirt, Silas Kett, shot the
  sheriff; nobody names him yet); he shouts at Earl as he walks in. The morning after: Earl to the
  undertaker's (`death.earl`), day folk's lines by the story's facts (`talk`); the sheriff dies on the
  doctor's cot (`-- --world=valley --mission=sheriff_dies --care=good|poor|left`); the story's Harlan is
  unarmed till then (`Player.lacks`). **Next: step 5, Beat 6, the funeral.**
  Open: the badge stays drawn on the dying sheriff's chest; the wife's `sit_back` hands float (her model);
  Earl isn't seen laid out (the undertaker's a block); from the
  playtest (`docs/playtests/2026-11-12-sheriff-dies.md`): the wife's "Were you with him?" doesn't wait, the
  bridge's walk out of the doctor's sticks, the boots through the cot's rail, nobody minds a drawn gun by day.
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
- **Townsfolk behaving realistically** (Sean 2026-11-12, #850): designed, not built: `docs/briefs/townsfolk.md`
  (days and the book, spots, staged reactions, news, regard and barks, the saloon as a room; an 11-step plan,
  step 1 measures and shuts the perception leaks). Waiting on Sean's five picks: #851. Starts when he places it.

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
  (`docs/playtests/2026-11-12-coach.md`): no horses, the rescue loop, the "store floor" wake line. Next: #840.
- **Gunfight D+** (#633 bugs; difficulty #349 is Sean's).
- **The valley's frame bench** (#865, `docs/reviews/2026-11-valley-bench.md`): `perf_bench --world=valley
  --townsfolk=N [--band=] [--bodies] [--extra-bodies=N]`, `tools/valley/bench_runs.py` (all scenes and counts,
  ~1.5 h). A townsman costs 0.165 ms (near 0.23, far 0.11): the 4.0 holds ~18 till the cuts; every scene's
  else is over. Bodies 27.7k of 32.8k; the full town ~45-55k: raise `max_bodies` to 65,536 (~4 MB).
  **Next: the cuts (the review's ranked list), #881.**

## Parked until after the slice
train (#542 step 7; waiting #553, #557, #601) · trestle (#638, #658) ·
dynamite (#596; #656 waiting; PR #683 open; bundles #647, #682) · masonry step 3 (#667) · horse (#341,
riding #478) · farmhouse (#565, #573, #651) · men dying on the run (#483) · perf step 9 (#401) · Payday
Night floor lab (#745).

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
- The valley bench: the drawn runs take ~6 min each (80 s of shader compiles); the gunfight's drawn
  1 s is four frames after the first shots (its render CPU isn't real yet).
- Bridge commands: LAYOUT "The dev bridge"; a lab's own commands in `experiments/<lab>/bridge.gd`.
