# Bodies disappearing (issue #562)

Every way a man (a `HumanBody`) leaves the tree or stops being drawn in play, found by reading every
free and hide path and by watching games. Lab only: `bridge.gd` changes nothing in the game.

## Commands

```sh
# a batch of headless games, each with the watcher on: the gunfight lab (flee forced to 1, half the
# runs a poor shot so men get away), the farmhouse's scripted runs, the street gang, men round a stick
python3 experiments/bodies_vanish/runs.py --out=build/bodies_vanish/r1 [--jobs=3] [--only=gf,farm,street,blast]
python3 experiments/bodies_vanish/runs.py --sum build/bodies_vanish/r1      # events grouped by cause
```

Bridge commands: `bv_watch [out=FILE.jsonl]` (every man leaving the tree, with what his brain was
doing on his last tick, and every second whether each man is drawn: hidden, off the camera's layers,
a part through the ground or at a non-number, parts outside his skin's culling box); `bv_report`;
`bv_flee [chance]` (every OutlawBrain's `flee_chance`, men who come later too); `bv_throw NAME X Y Z`
(he goes limp with that push, as a blast throws a man); `bv_parts NAME` (his root, his pelvis, why
he isn't drawn).

A run is ~5 min here (27 on main: `main_fights.txt`, `main_summary.txt`) (the fight, then 150 s of game time watched); 25 runs ~1 h at 3 jobs.

## What was found (2026-11-05, results `results/2026-11-05/`)

**Bugs (fixed, each with a test that fails on main):**

1. **The body is there but isn't drawn.** A man's skin is drawn through meshes under a `Skeleton3D`
   on his root, each with a fixed culling box `custom_aabb` (-3,-2,-3)+(6,5,6) about the root.
   Limp, the root stays where he went limp and the ragdoll carries the skin elsewhere: past ~3 m
   (a throw, his stride carried on, a slope or stair, dragged off) he's drawn only while that old
   box is on screen. `before_after.png`: a townsman thrown 14 m, looked at from 5 m with where he
   fell behind the camera: only his hat (left); fixed (right). In play: of the 15 games that had this check (it was added part way through the batch), one
   (`gf_spec_front_2`, a saloon-front fight, `keep_stride`): Brody down 5.5 m from you, in view,
   2.2 m outside his box.
   Blasts at `blast_lift` 0.8 threw men 1.4-4.1 m: inside it, mostly. Fix: `HumanBody._keep_in_cull_box`
   (every part each frame while limp, his pelvis each tick standing); `test_a_thrown_body_keeps_its_skin_drawn`.
2. **A man leaving town with no way out, or stuck short of it, was freed where he stood.**
   `OutlawBrain`'s `leave` step frees him when his route runs out; an empty route (no road out from
   where he is) runs out on the step's first tick, and a man stuck 2 s at a point skips it, so a
   stuck man went at the last one, wherever he was. Now he's gone only within 3 m of `west_edge`;
   short of it he stands and works the way out again 5 s on. Found by reading; not met in the runs.
   `test_with_no_way_out_he_stays`.
3. **The track crew's dead went with the crew** (`TrackRepair`: a limp man counted as walked off,
   then every man freed). `test_the_crews_dead_stay_when_it_leaves`.
4. **The farmhouse mission's start freed the range's outlaw dead or alive** (his body by the east
   road gone). `test_the_range_mans_body_stays_when_it_starts`.
5. The dev bridge's `read people` gave a limp man's root as `at` (where he went limp): the lead in
   #562's handover (a dead man "at his spawn point", not in the screenshot). `at` and `walk PERSON`
   are his pelvis now.

**By design today (Sean's calls, one issue):** a man leaving walks to `west_edge` (Main Street,
x -50, in sight down the street) and is freed there; after you come round from out cold (the only
thing that fires `Events.hours_passed`), a standing town man who hasn't given up is freed where he
stands (you're at the doctor's then: 4 men in the runs); the farmhouse mission takes away the
town's rancher (in front of the livery) and a standing range outlaw as it starts (12 in the farm
runs, both); the track crew's living are freed 60 m up the line or after 600 s wherever they are.

**Ruled out:** no visibility range, LOD distance or `visible = false` on people bar a shot-off hat,
a lost limb and the hidden pieces of a merged skin; cameras see every layer; nothing caps or pools
the dead; rubble lost below the ground is rubble only; no man is parented to a structure, a prop or a
train car (thrown riders are reparented to the track's host). No part under the ground in any run.
Debug only: F9 (a new range outlaw), the moments, the labs' own setups.
