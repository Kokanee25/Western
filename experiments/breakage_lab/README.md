# The breakage lab

Roadmap 3.3a, the bench for 3.3 (furniture); `docs/briefs/labs.md` "Breakage lab". It measures what
breaks today, how, and what it costs a frame, with furniture, a bottle, a lamp, a door, a window and
the store's front wall against the revolver, the shotgun and dynamite, and a man dropped onto a
table. Since 2026-10-21 also the surfaces a blast should hole or crater (the saloon floor, the
store's roof, the boardwalk, the street's dirt, a stick against the wall), for
`docs/briefs/blast-surfaces.md`. **It changes nothing in the game and claims no improvement.** It exists so 3.3's furniture
(Prompts 03 and 06 as one job) is built against numbers, one change at a time, each measured
against this baseline.

Everything is in this folder. Outputs go under `build/breakage_lab/` (git-ignored). The baseline's
table, findings and sheets are in `baseline/`.

## Commands

```sh
# everything: 11 targets and their weapons (44 scenarios), + the man on the table; a run with a man
# once per body (138 games, 4 at a time: ~16 min on this workspace's 4 threads; --repeat=2 doubles it)
python3 experiments/breakage_lab/run.py --out=build/breakage_lab/base
python3 experiments/breakage_lab/run.py --scenario=list
python3 experiments/breakage_lab/run.py --scenario=target:lamp,man_on_table --bodies=outlaw --out=...
python3 experiments/breakage_lab/run.py --scenario=weapon:dynamite_3m --out=...
python3 experiments/breakage_lab/run.py --repeat=2 --out=...          # same seed, same result?
python3 experiments/breakage_lab/run.py --serial --bodies=bold_cowboy_s0 --out=...   # frame times, one game at a time
python3 experiments/breakage_lab/run.py --render --bodies=bold_cowboy_s0 --jobs=2 --out=...  # frames (xvfb, lavapipe; ~1.5 min a game)
python3 experiments/breakage_lab/run.py --table=ROOT [--frames=SERIAL_ROOT]   # the table again, no Godot
python3 experiments/breakage_lab/run.py --look=0,0.05,0.12,0.25,0.5,1,2,4,8 --bodies=bold_cowboy_s0 --scenario=ground_dynamite_0m --out=...  # how it looks over time: every frame drawn, a shot at each moment (t00.25.png ...)
python3 experiments/breakage_lab/sheets.py look ROOT OUT.jpg [ROOT2 ...]   # those as a sheet: a row a run, a column a moment
python3 experiments/breakage_lab/sheets.py RENDER_ROOT OUT_DIR [--only=lamp] [--bodies=man_on_table]
# one scenario in a game you're driving (it clears the town first; one scenario a game)
python3 tools/bridge.py start --headless
python3 tools/bridge.py "breakage wall_dynamite_1m body=old_rancher_s1 seed=1" "quit"
python3 tools/bridge.py "breakage_aim door"        # what a shooter's line meets from 16 headings
```

`run.py` takes `--seed=N` (default scenarios.json's), `--seconds=S` (8), `--bodies=ID,...|all`,
`--jobs=N`. Rendering needs xvfb and lavapipe (`apt-get install mesa-vulkan-drivers xvfb`).

## Files

- `bridge.gd`: the lab's bridge commands (`BridgeLab`, docs/LAYOUT.md "The dev bridge"):
  `breakage`, `breakage_list`, `breakage_aim`. The bridge finds it when the game starts; nothing in
  `src/debug/dev_bridge.gd` changed.
- `runner.gd`: one scenario in the running street, measured, written out.
- `scenarios.json`: the targets, weapons, bodies, the extra (the man on the table) and the flag
  thresholds. Positions are in the building's own space (FalseFrontBuilding: front-left corner,
  the front facing −Z). Edit it to add a target.
- `run.py`: the runs (one fresh game each, through the bridge's `--bridge-script`), the table and
  the same-seed comparison. `sheets.py`: before-and-after sheets from a rendered run.
- `baseline/`: `baseline.md` (the table and what it shows), `baseline.json` (every summary),
  `manifest.json`, `sheets/`.

### Outputs per scenario (`ROOT/<scenario>[__<body>]/`)

- `summary.json`: the setup (what the lab did to the street, the target found, the aim point), the
  shooter's line (clear, or what it meets first), every bullet hit (what, energy in and out,
  through or glanced), the target's result, every member broken (by building, kind and wood, how far
  from the event, its utilisation before), the pieces, the fire, the men, the frame, the flags and a
  fingerprint for the same-seed check.
- `pieces.csv`: a row a piece (rubble, a wood chip, a glass shard, a fallen fitting): mass, longest
  side, where it started and ended, how far it flew, peak speed, how deep it sank, asleep or not.
- `frames.csv`: a row a frame from a second before the event to the end: wall-clock ms, the lab's
  own share, the game's, awake bodies, pieces, the four biggest systems (Prof).
- `godot.log`, `cmds.txt`; with `--render`, `before.png`, `mid.png` (~0.15 s after), `after.png`.

## How a run goes

1. A fresh game (`main.tscn`, the test street) starts headless with `--dev-bridge` and a one-line
   bridge script: `breakage SCENARIO seed=.. body=.. out=..`, then `quit`.
2. **The lab's own setup**, logged in `setup`: TownLife and the outlaw spawner stopped and everyone
   in town freed (they'd walk into the shots); the player put 80 m south, out of every blast's reach
   (14.6 m for a stick); the clock set (21:00 in the saloon, so its lamps are lit; 16:00 at the
   store) and stopped; Prof's timers on; Ballistics' ricochet draws seeded.
3. Half a second, then the target is found as the game built it: a saloon prop by its id nearest
   a point (the card table at 2.6, 4.2, its lamp, the chair at its east side, the bottle on the
   bar), or a store member (`store/front/door`, the left window's glass, the lap board left of the
   door). A man of the lab's own is placed if the scenario has one, and it waits a second.
4. A second of the street as it is (the frame's baseline), then the event:
   - **revolver 5 m / shotgun 5 m**: the production loads (`config/revolver.tres`: 16.5 g at 274
     m/s; `config/shotgun.tres`: 9 pellets in its pattern, the muzzle blast) fired by `Ballistics`
     from 5 m along the scenario's level line, from eye height (1.5 m over the floor the shooter
     stands on) at the aim point. A fixed line: no aim wobble, no spread but the shotgun's pattern
     (seeded).
   - **dynamite 1, 3, 6 m**: a real `DynamiteStick` (0.2 kg TNT) lying on the floor along the same
     line, that far from the target (level distance), lit with a 0.02 s fuse, so the production
     `Blast.detonate` does the rest. A bystander stands at the scenario's spot (2–6 m off).
   - **dynamite 0 m** (the surfaces, the wall and the door only: a target's `weapons` list): the
     stick against the target (on the floor at a wall's foot) or, with `charge_on`, lying on it (a
     floor, a roof, the boardwalk, the dirt).
   - **man on the table**: a man lying on his back, his middle a metre over the card table's top,
     goes limp (`HumanBody.go_limp()`, untouched).
5. Eight seconds measured, every physics tick.

### Bodies

The man for the table and the bystander at every blast are the **lab's** choice (`body=`), never
the game's default: the Studio's `bold_cowboy_s0`, `old_rancher_s1` and `young_drifter_s1`
(`assets/people/`), and `outlaw` (the old MakeHuman man) so the ragdoll lab's results still compare.
A scenario with a man runs once per body.

## Measures and their limits

- **Breaks or holds, and where.** For a member target: broken, holed (`holes`) or carved (voxels),
  `section_left`, and its utilisation (demand / capacity) from a `StructuralAnalysis` before and
  after, against `config/timber.tres` (the USDA Wood Handbook's strengths, cut down for rough stock:
  `bending_MPa` in the summary). For a blast, also **Blast's own rule** worked for that member
  (`blast`: the kick, impulse² / 2m, against fb² / 2E × volume × `absorb_factor`; over 1 breaks),
  the same sums as `Blast._member_response`, without its side effects. For a prop: still there,
  moved, fell (Fittings), smashed (a lamp). A kit prop (`KitProp`, the chair since #202: its legs,
  seat and rails are members) is read as members: which broke while it stood, were cut or holed,
  whether it went loose and how far what's left of it was thrown, and the member Blast's rule works
  hardest (`target_result.members_broken`, `loose`, `moved_m`, `blast`). Every member broken anywhere: by building, kind and
  wood, its distance from the event, its utilisation before.
- **What the blast looked at** (`setup.blast_query`): `Blast.gather` from the charge (what
  `Blast.detonate` acts on), against everything in its reach (one uncapped query): how many it took,
  whether the target was among them, and how many members within 1 m, 2 m and where timber can
  break (`break_reach_m`) it left out. Until 2026-10-21 Blast took one query capped at 1024
  colliders in the physics engine's order; the baseline's numbers are from then (`cap`,
  `left_out_within_1_2_5m`).
- **The surface** (`surface`, for targets with `surface: true` and the ground): the target's plane
  scanned in 10 cm cells, 3 m either way, before and after. For boards, a cell is closed if a ray
  through the plane meets a standing member of the target's kind (rubble, a joist behind, looked
  past): `opened_m2`, `opened_within_1m_m2`, `farthest_opening_m` (from the aim point). For the
  ground, the ground's height in each cell (a ray down; only the ground counts): `crater_depth_m`,
  `crater_radius_m`, `rim_m`, and the scorch decals within 3 m. With a stick on or against a
  surface, `setup.by_rule` is what Blast's own rule would break of it if the query found everything
  (members of the target's kind within 4 m over 1, the face they'd open, how far it reaches): the
  frame breaks whole members, so that's the hole the rule implies today.
- **Pieces**: every RigidBody3D that appears after the event, but the men's parts and the stick:
  rubble (Structure), wood chips (voxel carving), glass shards, fallen fittings. Count, mass, the
  largest (by mass), how far each flew (level distance from where it appeared), peak speed.
- **What catches fire**: members that start burning (and when), FireSystem's spills (lamp oil),
  lamps smashed.
- **Physics faults**: a piece's box sunk into the world (`collide_shape` against WORLD, deepest
  pair) past 3 cm for 3 checks; below the ground; flung (over 20 m/s and 0.5 kg); flown over 12 m;
  awake at the end; woken and slept 4+ times. For a man: parts sunk, a part over 12 m/s, never at
  rest. Small chips (under 50 g) aren't checked for sinking: they freeze where they land, by
  design. Jolt's own slop is 2 cm.
- **Same seed, same result**: `--repeat=2` runs every game twice and compares the fingerprints:
  what broke, how many pieces, where each ended (to the millimetre), what caught, the men's pelvis.
- **Frame time per event**: wall clock per frame, headless, this workspace's 2.1 GHz core (×0.65
  for Sean's, CLAUDE.md "Frame budget"), with the lab's own measuring taken out; the event's frame,
  the first second, 1–3 s, and the systems (Prof) in them. **FireSystem rebuilds its grid every 2 s
  whether anything burns or not (12–25 ms here)**: a frame that's only that, with nothing hot, is
  taken out and listed apart (`fire_grid_ms`). Use a `--serial` run for frame numbers: games run
  side by side share the cores. Render CPU isn't measured headless; a rendered run records the
  draw calls before, just after and at the end (lavapipe, the scenario's camera).
- Errors and warnings Godot logs during the scenario (a Logger) are in `errors`/`warnings`.

Not measured: sound, how it looks beyond the sheets (the look runs are judged by eye, `docs/briefs/blast-look.md`), the player's own wounds, anything after 8 s.

## Thresholds

In `scenarios.json` (`thresholds`), set from the first baseline. They flag; they don't judge.

## Determinism

One process a scenario (the ragdoll lab found a second run in the same process differs). The
baseline's same-seed comparison is in `baseline/baseline.md`: guns, street blasts and the drop
repeat to the millimetre; blasts on the saloon floor don't.

**A man's settle time is jumpy.** Where he comes to rest repeats to the centimetre, but the "at
rest" moment (every part under 5 cm/s and 0.3 rad/s for 30 ticks) sometimes catches a last slow
wobble: the man on the table read 2.8 s in most runs and 3.1 or 4.2 s in a few, same seed. Compare
rest positions; take settle times over several runs.

**Re-run the baseline when the street changes** (`run.py --repeat=2`): the lab clears the town, but
what the street made before that could change the physics engine's body order. When main cast the
Studio's men in town (#160), only the saloon blasts (already unrepeatable) and one piece of glass
changed.

## Baseline (2026-10-21, main at #159)

`baseline/baseline.md` has the table by target, the sheets, the frame times and what they show. In
short:

- **Blast's query misses what's near a stick on Main Street**: capped at 1024 colliders of the
  1,600–2,500 in its 14.6 m reach, it found none of the 14 members within 1 m of the store's front;
  the store's wall, door and window hold at 1 m while windows 5–12 m off shatter.
- **Props never break**: the chair, the card table, the bottle and the lamp stop every ball and
  pellet in their one box and stand through every blast; a lit lamp shot never smashes.
- **A stick on the saloon floor drops 24–30 floor boards and 2–3 joists in whole lengths** (rubble
  median 4.7 m long), thrown at the 25 m/s cap; side windows shatter into 1 m-deep slabs that hang in
  the frame.
- **The man on the table** lands on it and comes to rest in 2.8–4.2 s, every body; the Studio's three
  men are physically the outlaw (the same capsules) and nothing goes wrong on them that doesn't on
  him.
- **A blast is two big frames**, 0.3–1 s here (0.2–0.65 s at Sean's): `Blast.detonate`, then the
  building settling.
- **Same seed, same result** for every gun scenario, street blast and the drop; blasts on the
  saloon floor differ run to run (cause not traced).
- First fix: Blast's near field queried on its own, made 2026-10-21 (`results/2026-10-21_near_field/`):
  the street now breaks where the stick is.
