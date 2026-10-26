# More cores, step 3: the sight service (2026-10-26)

`docs/briefs/more-cores.md` "Step 3" (issue #394). This workspace's 2.1 GHz core (x0.65 for
Sean's), headless, `--fixed-fps 60`, one game at a time, nothing else running. Every run is the
lab's ten D fights:

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall --hours=golden --weapons=revolver \
    --styles=careful --bodies=studio --variant=D --seeds=1-10 --jobs=1 --out=build/gf/<run>
python3 experiments/gunfight_lab/same_fight.py build/gf/step3_1 build/gf/step3_2
python3 experiments/gunfight_lab/results/2026-10-26_step3/perf.py before_1=... before_2=... step3_1=... step3_2=...
```

**before** is main at 8f35775c (step 2 merged), run from a worktree; **step3** is 83246c7a. The
four runs alternated (before, step 3, before, step 3), so the machine's drift lands on both.
`runs/<name>/` has every fight. This machine read slower today than on step 2's day (step 2's
final build: 15.0 ms a frame then; main reads 19.6 today), so compare these four with each other.

## What it is

`SightWorld` (`addons/saltcreek_native/src/sight.rs`, `sight_geo.rs`) holds every body on the
world and walk layers as the physics server holds it: the boxes (13,763 bodies, 16,094 shapes in
the street with the spec saloon), the capsules (the player, the horses), the cylinder, and the
triangles of a carved member or a dug tile. A surface-area BVH (binned, 12 bins) covers what
stands; what moves or has changed is kept beside it. Rays follow Jolt's rules as Godot asks
them:
- a convex shape a line starts inside isn't hit;
- a line laid along a face touches it (Jolt's RayAABox);
- a box's normal is its nearest face, ties as Jolt breaks them;
- a carved member's mesh is one-sided (`backface_collision` off), a height field two-sided.

`Sight` (`src/people/sight.gd`) feeds it from the tree (`node_added` / `node_removed` of bodies
and their shape nodes), places the physics' movers once a physics frame, and is told by
`Sight.changed` / `shapes_moved` / `moved` where a script changes a body the tree doesn't see:
- a kit prop set down;
- the horse's shapes on his bones;
- a pane gone;
- a carve, its hole taken exactly (the brief allowed a solid box; the mesh is cheap enough);
- the player's step.

Moved onto it: Cover's lines (the shadow search in two batches; each spot's floor, ground and
lying-chest lines in three batches a search step; the rest one at a time), `Senses._clear`,
`SightLight`'s lamp lines and sky ring (the ring a batch), `OutlawBrain._clear` (so
`_aim_point`). `_room`, `path_clear`, the town's ways, balls, feet and hearing stay on Jolt.

**What this step didn't do: the people's capsules.** No line moved here can meet a man: the
hitboxes are on `BODY_PARTS`, every sight line asks `WORLD`. Feeding 17 parts a man a tick would
cost and change no answer. The capsules come with step 4's snapshot, when a line that should meet
a man (a friend in the way, `_friend_in_the_way`) moves over.

## The gate

- **`tests/test_sight_world.gd`** (`sight_world_test.txt`): 31,248 lines in the building lab's
  spec saloon, cast both ways. They are each place's eye on every other place at the six heights
  Cover and Senses use, the cover search's ground, floor and chest lines round each place, and
  the sky ring. As built: **every line agrees but 15, all of them along a face**: a line laid
  exactly in the front wall's face plane (the places on the balcony door's line are at z 0 to
  the float), where whether it touches the board is a float coin-flip for either engine, or
  where it meets the board's top edge (the same point, a different face named). Shot up (30
  balls, 49 members carved): 14 disagree, 13 along a face and 1 at a carved member. The test
  holds everything else to zero and lists these.
- **Ten fights twice: 10 of 10 the same** (`same_fight.txt`; main's own two runs also 10 of 10,
  `same_fight_before.txt`).
- **Against main: 0 of 10 event for event** (`same_fight_before_vs_step3.txt`; the first fight
  parts at 3.7 s). SightWorld's hit points agree with Jolt's to within float rounding, not to the
  last bit, and the cover search snaps candidate spots to a 20 cm grid (`Cover._dedupe`), so a
  rounding difference can move a spot to the next cell. The 2-seed run of an earlier build of this
  step matched main event for event in both fights; the final one doesn't. The fights' numbers
  (`q_cover` 65.3 -> 60.6, `q_walk` 18.5 -> 16.6) are these fights', not a change in what a man
  can see.
- **The perception lab** (`perception.md`): **88 of 117 as expected, before and after, every
  verdict the same**. Three search cases' times move (`lost_round_corner_*` 8.00 -> 8.25 s,
  `lost_at_night` 11.1 -> 9.2 s), for the same rounding as the fights.
- **`gf_coverwhy`, ten searches** (`coverwhy.md`): **10 of 10 the same**: every candidate count,
  reason a spot was turned down, pick and way.
- **The whole suite: 739 passed, 0 failed.**

## The numbers (ms a frame; a `q_*` row is a count a frame) — `perf.md`

| | before_1 | before_2 | **step3_1** | **step3_2** |
|---|---|---|---|---|
| frame (mean / p95) | 19.74 / 23.53 | 19.54 / 23.39 | **19.95 / 22.85** | **20.11 / 23.47** |
| window / step / rest | 12.87 / 2.06 / 4.74 | 12.73 / 2.07 / 4.69 | 13.03 / 2.09 / 4.74 | 13.12 / 2.13 / 4.78 |
| people | 10.22 | 10.08 | 10.36 | 10.42 |
| `senses` | 1.28 | 1.26 | 1.29 | 1.29 |
| `outlaw_brain` | 2.70 | 2.66 | 2.64 | 2.66 |
| `lamps` | 0.17 | 0.17 | 0.17 | 0.17 |
| `sight_sync` (new: its upkeep) | – | – | 0.04 | 0.05 |
| `player` | 0.46 | 0.46 | 0.49 | 0.49 |
| `people_body` | 4.42 | 4.37 | 4.56 | 4.57 |
| `q_cover` / `q_senses` / `q_lamps` / `q_walk` | 65.3 / 46.4 / 4.5 / 18.5 | the same | 60.6 / 45.7 / 4.4 / 16.6 | the same |

**No gain: the frame is the same within this machine's noise (19.6 -> 20.0, about +0.4, and the
two runs of one build differ by up to 0.2).** The systems that ask the lines didn't move:
`senses` 1.27 -> 1.29, `outlaw_brain` 2.68 -> 2.65, `lamps` 0.17. The upkeep is +0.05
(`sight_sync`) and +0.03 in `player` (his step placed). `people_body` +0.17 asks no lines; its
fights are different ones. The brief expected about -1 ms (`senses` 1.2 -> ~0.6, the brains'
cover search 0.5 -> ~0.1).

**Why not: the lines were never the cost.** From the sight lab's bench in the street with the spec
saloon (`sight_bench 2000`, random lines through the saloon):
- Jolt `intersect_ray` from GDScript, a query made each time as the game did: **3.6 us a line**;
- `Sight.clear` 2.8 us, `Sight.cast` 3.0 us;
- `Sight.lines` **0.7-0.8 us a line** in a batch of 2,000 (across the plugin's 4 threads).

The plugin's own ray is about 1.3 us (on the saloon's 5,803 boxes); the rest of a single
question is the GDScript call. A D fight asks about 115 sight lines a frame (`q_cover` 61,
`q_senses` 46, `q_lamps` 4.5, `q_brain` 0.4), about **0.4 ms of the frame under Jolt**, and
`senses`' 46 lines are ~0.17 of its 1.28 ms (the rest is its GDScript: the light on each man, the
people list, the points on him). One at a time, Sight saves under a microsecond a line. Senses'
lines in batches (tried: a man's lines in one call) cost more than they saved, because a man asks
only a handful and the batch's bookkeeping in GDScript is dearer than the calls. The cover
search's batches (floor, ground and chest for each step's candidates) save little because most of
`outlaw_brain` isn't its lines.

**What pays is one batch for the tick**: every man's lines gathered into one call, as step 4's
phase 3 does ("Rays (main issues, SightWorld answers in its threads)"). At 0.7 us a line, the
frame's 115 lines are ~0.1 ms in one call against ~0.4 ms now, and the per-line GDScript goes
too. Step 4 carries it (#395).

## The shot (`shot/`; the handover's ask)

`bf_shot` (blast-freeze lab), main and this step: the townsfolk's burst 47 ticks after the shot is
**110 ms before, 118 ms after**, with `q_cover` 85 on that frame both times. 85 lines are ~0.3 ms
of it, so the burst is `civilian_brain`'s own work (step 5 (a), as `shot.md` in step 2's results
says), not its cover lines. The shot's worst frame 120 -> 131 ms is that burst.

## Files

`perf.md`, `perf.py` (step 2's with the sight systems first), `same_fight*.txt`,
`sight_world_test.txt`, `perception.md`, `coverwhy.md`, `coverwhy_commands.txt`, `runs/`,
`shot/`. What was read for this step: CLAUDE.md, the brief's "The design" A/F, "The steps" 1-4 and
"How a step is reviewed"; the gunfight lab's README and `same_fight.py`; step 2's README and
`shot.md`; Cover, Senses, SightLight, OutlawBrain's lines, StructureMember, Structure's breaking,
KitProp, GroundTile, Horse; gdext's PhysicsServer3D bindings; Jolt's RayAABox and BoxShape's
normal (from memory of its source, not copied).
