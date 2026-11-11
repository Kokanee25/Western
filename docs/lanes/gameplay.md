# Gameplay lane: current state

Branch `claude/gameplay-…`. Everything that isn't art, characters or props: missions, people, weapons,
structures, blast, the valley, performance, CI. Replace your lines here at the end of a session; no history
(that goes in `docs/status/` and the PR). Keep under ~10 KB. Full history to 2026-11-11:
`docs/status/current-state-2026-11-11.md` "Gameplay", "The masonry lab", "The horse".

## The slice's missions (LAYOUT "src/missions", "src/moments")
- **The sheriff on the road** (#746, build 3698): `-- --world=valley --mission=sheriff`; `StoryState`,
  `HeadGesture`, `Act`. Waiting on Sean: #755.
- **No Law** steps 1-3 done (`ValleyFolk`, `PlayerSeat`, `CardGame`, `NoLawMurder`; build 3882;
  `experiments/valley_folk/README.md`). **Next: step 4, the morning after and the sheriff's last day (#796).**
  The No Law card is out of date: the murderer is one of the Baron's men, not the red shirt (#744).
- **No Justice** (#738): week 2. Joe on the rope: 3-4 shots or close in (#744).
- Story decisions: #744's latest comments and STORY.md; the story bible is #809.

## Systems the slice leans on
- **The valley** (#467, `config/valley.json`, `tools/valley/`; LAYOUT "src/world/town_layout.gd"): G1-G7 done,
  heights (#736). The saloon onto its lot waits on art's saloon B.
- **Falls from height** done (#759, `Falls`, `config/falls.tres`).
- **Winchester 1873 in the game** (#792; key 6, `Rope`, the rope range at F5's last stop). Waiting on Sean's
  play. Parked: men carrying it (#800).
- **The Colt** (#693 step 1 approved). Harlan's arms are characters' (#693).
- **The coach heist** (#794, PR #814, build 4002; `experiments/coach_heist/` README): `SwingingRam` (the log
  on two ropes from a gallows frame, held by a trip pin a ball splits), `Dents`/`DentWatch`, `CoachDrive`,
  `CoachCut` (`-- --world=valley --mission=coach`, bridge `ch_cut`) on the prop lab's `baron_coach`. Over
  8/8, dents ~3.7 cm, worst frame ~31 ms at Sean's in the cut. Rough: the guards have no brains or guns.
  Next: #815 (the guards fight back, the strongbox taken). Parked until after the slice unless Sean says.
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
