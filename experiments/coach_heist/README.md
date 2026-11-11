# The coach heist lab

Issue #770 (#736's comment: the Baron's iron-plated coach, a log down a bank knocks it over and
dents its plates, the guards inside thrown about). Sean's picks on #784: **1B** (the log: green
ponderosa pine 0.6 x 6 m, 1.25 t), **2C** (a 2.5 m crib step at the bank's foot) and **dents as
planned**. This lab builds them and measures them against #784's numbers.

What it uses (the parts are in the game, `docs/PARTS.md`):
- `RollingLog` (`src/structures/rolling_log.gd`): a rigid cylinder, its mass from its wood
  (TimberTuning `green_pine`, 740 kg/m3), frozen until the last of its holds (deck members) breaks.
- `Dents` + `DentWatch` + `DentTuning` (`src/structures/dents.gd`, `dent_watch.gd`, `config/dents.tres`):
  a member marked to dent (`"plate": true`, or `Dents.mark`) pushed in by the energy of a blow.
- `CoachDrive` (`src/missions/coach_drive.gd`): the coach driven, handed to physics when struck,
  its guards thrown, its traces pulled and broken.
- `Structure.mass_by_members` and `breaks_up` (a loose coach weighs where its members do, and
  stays whole when it lands).
- The coach: `baron_coach` once the prop lab's #782 (PR #786) is on main; until then
  `coach_stand_in.json` (made by `stand_in.py` from that branch's file: the real coach's running
  gear, frame, panels, roof and its 28 plates, without the kit code not yet on main, with 112 kg of
  oak ballast in the benches to its 1,508 kg; centre of weight 1.39 m against the real 1.41).

```sh
# the log down bare 1:1.5 banks 2, 4, 6, 8 m: its speed at the foot against sqrt(4/3 g h)
godot --headless --fixed-fps 60 -s res://experiments/coach_heist/heist.gd -- --mode=roll --out=DIR
# the standing coach struck sideways by logs A/B/C at speeds, at 1.39 m (the low plates' middle) or --hit_y
godot --headless --fixed-fps 60 -s res://experiments/coach_heist/heist.gd -- --mode=tip [--hit_y=2.0] [--speeds=3,4,...] --out=DIR
# the whole heist, 8 times: the coach driven up, the log let go at the mark, every frame timed
godot --headless --fixed-fps 60 -s res://experiments/coach_heist/heist.gd -- --mode=heist --seeds=8 [--ledge=0.6] [--coach_z=0.6] [--log_r=0.3] --out=DIR
#   --debug: the log and the coach every 6 ticks, every blow the dent watch closes; --spikes: frames over 40 ms
```

In a running game (the dev bridge): `ch_build [X Y Z] [ledge=] [coach_z=] [log_r=] [guards=]`,
`ch_release`, `ch_read`, `ch_clear`.

## What was found (2026-11-10, `results/2026-11-10/`)

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
