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
  long lines run off the subtitle's width; Earl isn't seen laid out (the undertaker's a block); from the
  playtest (`docs/playtests/2026-11-12-sheriff-dies.md`): the wife's "Were you with him?" doesn't wait, the
  bridge's walk out of the doctor's sticks, the boots through the cot's rail, nobody minds a drawn gun by day.
- **No Justice** (plan on #843: 1 Joe, 2 the doctor's and the camp, 3 the hideout fight at the valley's
  `hideout` box canyon, 4 the cabin, the knife and the nod). **Step 1 done: Joe, the companion**
  (`CompanionBrain`, `Physiology.spared`; `-- --joe`, bridge `joe`, the lab's `joe=1`/Shift+Y;
  `experiments/gunfight_lab/results/2026-11-12_joe/`). Open: he holds fire a lot and they seldom shoot at
  him; you alive 13/20 without him, 16 and 11 of 20 with (noise at n=20); riding waits on #478; his real
  look is the Studio's (stand-in `miner_s4_talking`). **Next: step 2, the doctor's and the camp; first (Sean,
  PR #853) why the playtest fixes dropped survival with Joe (16 -> 11 of 20): he has to help.**
  Joe on the rope later: 3-4 shots or close in (#744); the rope turns `spared` off.
- Story decisions: #744's latest comments and STORY.md; the story bible is #809.
- **Townsfolk behaving realistically** (Sean 2026-11-12, #850): designed, not built: `docs/briefs/townsfolk.md`
  (days and the book, spots, staged reactions, news, regard and barks, the saloon as a room; an 11-step plan,
  step 1 measures and shuts the perception leaks). Waiting on Sean's five picks: #851. Starts when he places it.

## Systems the slice leans on
- **The valley** (#467, `config/valley.json`, `tools/valley/`; LAYOUT "src/world/town_layout.gd"): G1-G7 done,
  heights (#736). The saloon onto its lot waits on art's saloon B.
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

## Parked until after the slice
train (#542 step 7; waiting #553, #557, #601) · trestle (#638, #658) ·
dynamite (#596; #656 waiting; PR #683 open; bundles #647, #682) · masonry step 3 (#667) · horse (#341,
riding #478) · farmhouse (#565, #573, #651) · men dying on the run (#483) · perf step 9 (#401) · Payday
Night floor lab (#745).

## Open problems
- **The nightly soak is red since Oct 29**: 8,448 orphaned nodes after four hours. Find which objects pile
  up and free them (`tools/soak.gd`, LAYOUT "The soak").
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
- The native plugin builds here (`cargo build --release`, ~3 min).
- Bridge commands: LAYOUT "The dev bridge"; a lab's own commands in `experiments/<lab>/bridge.gd`.
