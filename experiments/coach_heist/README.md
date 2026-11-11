# The coach heist lab

Issue #770 (#736's comment: the Baron's iron-plated coach, a log down a bank knocks it over and
dents its plates, the guards inside thrown about). Sean's picks on #784: **1B** (the log: green
ponderosa pine 0.6 x 6 m, 1.25 t), **2C** (a 2.5 m crib step at the bank's foot) and **dents as
planned**. Then (#791, 2026-11-11) **no rolling log: a battering ram**, log B on two ropes, hitting
sideways at the bottom of its swing ~2 m up on the upper plates (#794): the lab's default since.

What it uses (the parts are in the game, `docs/PARTS.md`):
- `RollingLog` (`src/structures/rolling_log.gd`): a rigid cylinder, its mass from its wood
  (TimberTuning `green_pine`, 740 kg/m3), frozen until the last of its holds (deck members) breaks.
- `Dents` + `DentWatch` + `DentTuning` (`src/structures/dents.gd`, `dent_watch.gd`, `config/dents.tres`):
  a member marked to dent (`"plate": true`, or `Dents.mark`) pushed in by the energy of a blow.
- `CoachDrive` (`src/missions/coach_drive.gd`): the coach driven, handed to physics when struck,
  its guards thrown, its traces pulled and broken.
- `Structure.mass_by_members` and `breaks_up` (a loose coach weighs where its members do, and
  stays whole when it lands).
- `SwingingRam` (`src/structures/swinging_ram.gd`, #794): the log on two fixed-length ropes from a
  gallows frame over the road (kit members), held back up the bank by its trip pin.
- `CoachCut` (`src/missions/coach_cut.gd`): the ram and the coach in the valley's coach cut.
- The coach: the prop lab's `baron_coach` (#782, PR #786), its strongbox carried under the rear
  bench, four guards inside and the driver and messenger on the box. (Until #786 the lab ran a
  stand-in made from its branch; gone since.)

```sh
# the ram let go from --drops (its middle that high over the bottom of its swing): its speed at the
# bottom against sqrt(2 g h), the ropes' pull; and the standing coach struck at the bottom
godot --headless --fixed-fps 60 -s res://experiments/coach_heist/heist.gd -- --mode=swing [--drops=2,2.5,3,3.3,3.6,4] --out=DIR
# the heist (the ram by default; --striker=roll the log off the step), 8 seeds, the pin let go a swing
# short of the ram (--swing_s=1.28) plus each seed's shift (--spread=0.06 s); --only=N one seed
godot --headless --fixed-fps 60 -s res://experiments/coach_heist/heist.gd -- --mode=heist [--seeds=8] [--pull_up=3.3] [--spread=S] --out=DIR
# the valley's coach cut: CoachCut on the bake's own ground round it (a 1 m height field), 8 seeds
godot --headless --fixed-fps 60 -s res://experiments/coach_heist/heist.gd -- --mode=cut [--seeds=8] --out=DIR
# the log down bare 1:1.5 banks 2, 4, 6, 8 m: its speed at the foot against sqrt(4/3 g h)
godot --headless --fixed-fps 60 -s res://experiments/coach_heist/heist.gd -- --mode=roll --out=DIR
# the standing coach struck sideways by logs A/B/C at speeds, at 1.39 m (the low plates' middle) or --hit_y
godot --headless --fixed-fps 60 -s res://experiments/coach_heist/heist.gd -- --mode=tip [--hit_y=2.0] [--speeds=3,4,...] --out=DIR
# the whole heist, 8 times: the coach driven up, the log let go at the mark, every frame timed
godot --headless --fixed-fps 60 -s res://experiments/coach_heist/heist.gd -- --mode=heist --striker=roll --seeds=8 [--ledge=0.6] [--coach_z=0.6] [--log_r=0.3] --out=DIR
#   --debug: the log and the coach every 6 ticks, every blow the dent watch closes; --spikes: frames over 40 ms
```

In a running game (the dev bridge): `ch_build [X Y Z] [striker=ram|roll] [pull_up=] [coach_z=] [log_r=] [guards=]`,
`ch_release`, `ch_read`, `ch_clear`; in the valley (`--world=valley`) `ch_cut [auto] [back=M] [here]`,
`ch_cut_go`, `ch_cut_read`. The game: `-- --world=valley --mission=coach` (you at the high spot over
the cut, the coach coming up the grade: shoot the pin).

## The ram (2026-11-11, #794, `results/2026-11-11_ram/`)

**The swing** (`swing.md`): from 2.0, 2.5, 3.0, 3.3, 3.6, 4.0 m its speed at the bottom is 6.26, 7.00,
7.67, 8.04, 8.40, 8.85 m/s against sqrt(2 g h)'s 6.26, 7.00, 7.67, 8.05, 8.40, 8.86, in 1.23-1.32 s;
each rope pulls 10.8-15.5 kN at the bottom (m (g + v^2/L) / 2; 1-inch manila holds ~40 kN).
**The standing coach struck at the bottom** (2.0 m up, the upper plates): over from every drop of
2.0 m and more (lean 100-108), the deepest dent 2.8 (2.0 m), 3.6 (3.3), 4.0 cm (4.0); from 1.6 m (5.6
m/s) and 1.2 m it stands (lean 14-17), dents 2.1-2.5 cm.

**The heist** (`heist.md`: the coach driven at 1.4 m/s, the pin let go 1.28 s short, 8 seeds 0.06 s
apart): **over 8 of 8** (lean 100-105), 9-14 plates dented, **the deepest 3.6-3.7 cm in all 8**, the
four traces broken, the strongbox loose inside the coach 8/8, the driver and messenger off the box on
the road 8/8, head blows 0-2 (none over 60 J). The worst frame 20-35 ms here, **13-23 at Sean's**.
Let go up to 0.9 s early or late (`heist_wide.md`, `--spread=0.25`) it meets the coach up to 1.3 m
either side of its middle: over 8/8, deepest 3.4-3.6 cm, worst frame 21 ms at Sean's.

**The coach cut** (`cut.md`: CoachCut on the bake's ground, the coach 40 m down the grade): the South
Road is level through the cut (12.3 m, +-0.1 over +-10 m along), its bed ~6.5 m between banks, the
south-west one rising ~1:1.5 (the held log clears it by ~3 m). **Over 8 of 8**, the swing 1.18 s, the hit
7.99 m/s 2.02 m up, 9-14 plates dented, the deepest 3.7 cm in all 8, the ropes 18-28 kN over 0.1 s,
the worst frame 15-31 ms at Sean's. In the game (`-- --world=valley --mission=coach`, the bridge's
`ch_cut auto`): over, 10 dented, 3.7 cm, ropes 21 kN; from the high spot an aimed revolver shot
(`hold aim`) let the pin go 5 times of 6 at ~10 m.

**Found on the way** (each fixed, each with a test or a lab check):
- A seated man's `Blocker` (the upright capsule that keeps the player out of him, a fixed body standing
  through the bench and roof) shoved the loose coach ~2,000 N.s a contact at the hand-off: the coach shot
  off at up to 19 m/s before the log arrived. The rolling log's heists ran with it (their `tip` runs, with
  no guards, didn't). `CoachDrive._ride` excepts it now.
- The coach's contact report (128) fills with its six riders' parts and its wheels: the log's blow was
  dropped and nothing dented. `DentWatch` reads a striker's blows from the striker's side.
- Jolt's cast (CCD) collision for the log resolves the blow outside the reported contacts: the ram's log
  runs discrete (at ~8 m/s a tick is 13 cm into a 1.4 m body).
- Nine plates dented on one tick rebuilt nine dense meshes (~100 ms here): now `MESH_BUDGET_MS` a tick.
- The carried strongbox fell loose in the first quarter second of the drive (KitProp's floor check saw
  the coach's floor move); `KitProp._floor_place` reads a carrier's floor in the carrier's space.
- The ropes run from the bents beyond the log's ends to slings 0.3 m in: each rope's length is its 3D
  length with the log at the bottom (taken as the arc's radius, the log fell free for its first 0.3 s).
- After the blow the ropes go slack and snatch taut: a fixed rope takes that in one tick (75-118 kN);
  `most_tension` is over 0.1 s, as a manila rope's stretch spreads it (17-28 kN).
- On the valley's ground (Jolt height fields: surfaces, not solids) a kit prop's foot a few mm under
  the surface finds nothing and it goes loose: the driven coach and the trip's stake now `keep_footed`.
- CoachDrive met the striker in the world's axes: a coach turned 33 degrees to the road has a box half
  again as wide, and it was handed off with the ram half a swing away (a rope at 100 kN): the coach's space now.
- The pin on the stake's road side was hidden from the high spot by the stake: across its top now, 7 cm.

## The rolling log (2026-11-10, `results/2026-11-10/`; before the ram)

(Its heists ran with the riders' blockers shoving the coach at the hand-off: see the ram's "found".)

**The log's speed** (`roll.md`): at the foot of 2, 4, 6, 8 m banks 4.94, 7.06, 8.69, 10.09 m/s
against the lossless 5.11, 7.23, 8.86, 10.23: 97-99%. Off the cut's 5.5 m bank 8.4 (lossless 8.48).

**The tip-over** (`tip_1.39.md`, `tip_2.0.md`). #784's 4,100 N.s assumed the far wheels hold
where they are while the coach pivots on them. On a road they slide:
- Struck sideways at 1.39 m (the low plates' middle, which is the coach's centre of weight's
  height) it is **shoved across the road and never goes over**, whatever the log, up to 12 m/s.
  The blow has no lever about its centre, and the wheels slide.
- Struck at 2.0 m (the upper plates) it goes over from **A 8, B 7, C 6 m/s** (~7,000-10,000 N.s
  carried by the log).
- Shoved sideways with nothing else, sliding trips it from ~4-5 m/s (rubble friction 0.8).

**The heist as Sean picked it (1B 2C).** With the bank running straight to the step's edge, the
log leaves the edge along the slope. It meets the coach falling 41 deg (9 m/s, 7 across, 6 down)
on its upper side. That pushes the near wheels into the road: **it stood 3 of 3** (lean 3-7 deg).
A crib's top course is flat: **with a 0.6 m flat top on the 2.5 m step**, the log leaves it nearly level
(7.5 m/s across, 2 down) and meets the coach's top edge. With the coach 0.6 m to the far side of the road's
middle (the driver keeping off the bank), **it goes over 8 of 8** (the lab's default now). Where the
coach drives decides it: 0.6 m over 4/4, 0.8 over 4/4, 1.0 over 2/4, 1.2 over 0/4.

**The dents.** The plan's ~4 cm needs the log square on the side plates. There it shoves the coach rather than
tipping it. Hitting high enough to tip it, the log meets the roof's edge and the top of the plates:
- in the default heist the deepest dent is 0-4.5 cm, mostly under 1 cm;
- the coach landing on its side dents nothing: its hubs stand 0.27 m proud of the plates;
- log C (1.7 t, Sean's 1C) with the coach 1.0 m over: over 4/4 and dents of 0.5-5.4 cm (#791 asks Sean).

A blow's energy into a plate is the work its contacts' impulses do against the speed they closed at
(1/2 J v). Resting and sliding contacts do none. A plastic knock in one tick is exactly 1/2 m v^2 of the
pair's reduced mass.

**The traces** break on all four hooks at the hit (10-24 kN against their 9 kN); the team walks on.
**The guards** go limp one a tick and are thrown about inside. None took a head blow over 60 J
(`OutlawBrain.head_stun_seconds`): a coach going over is ~1 m of fall for them.

**Frames** (#492's gate: none over 100 ms at Sean's): the worst of the 8 heists **33 ms here, ~21 at
Sean's**. The lab's own site build at each run's start is ~130 ms (not counted).

## Traps

- The coach's rubble used to break up into its 177 members on landing (`_break_up` at 2.5 m/s):
  `CoachDrive` sets `breaks_up = false`.
- Jolt spreads a body's mass evenly through its shapes: without `mass_by_members` the coach's
  centre of weight is its boxes' middle, not its plates'.
- The dent watch needs `max_contacts_reported` high (128): at 32 the guards' parts and the wheels
  fill it and the log's contacts are dropped.
- `StructuralAnalysis.load_tuning()` reloads the dial resource fresh (RollingLog reads the density once).
