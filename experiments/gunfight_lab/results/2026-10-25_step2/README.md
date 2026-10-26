# More cores, step 2: the per-person tick made cheap, single-core (2026-10-25)

`docs/briefs/more-cores.md` "Step 2". This workspace's 2.1 GHz core (x0.65 for Sean's), headless,
`--fixed-fps 60`, one game at a time, nothing else running. Every run is the lab's ten D fights:

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall --hours=golden --weapons=revolver \
    --styles=careful --bodies=studio --variant=D --seeds=1-10 --jobs=1 --out=build/gf/<run>
python3 experiments/gunfight_lab/same_fight.py build/gf/step2_a build/gf/step2_b
python3 experiments/gunfight_lab/results/2026-10-25_step2/perf.py before=... step2_a=... step2_b=...
```

Each change was measured on its own, one on top of the other, from a worktree at its commit
(`runs/<name>/`: `fights/*.json`, `manifest.json`). **before** is step 1's head with main merged
(8cbfa2c2: the base this branch starts from; its fights are step 1's own, 10 of 10).

## The per-shot hitch (Sean's F3, added to this step by #390; `shot.md`)

One revolver ball each way into the spec saloon's walls (`bf_shot`, the blast-freeze lab): the
ball's member left its batch, and `_build_batch` rebuilt that material's mesh for the whole saloon
(up to 683 members), **15-23 ms of the shot's frame**. Now a material's members are batched in
pieces of at most 64 near members (`Structure.BATCH_PIECE`, 2 m cells on a Morton curve): **1-3
ms**, and the shot's worst frame 42-58 -> 26-37 ms here. The saloon draws in 115 batches (was 62),
the street's 92 structures in 736 (was 733). What's left of a shot is the holed member's load
check (`fire_loads`, 14-20 ms) and, a second later, the townsfolk's `civilian_brain` burst (~100
ms on one frame): step 5's, both named there.

## The gate

**10 of 10 fights the same** (`same_fight.txt`; `runs/step2_a/`, `runs/step2_b/`), on the final
build (1f20f8f6), and its fights are the 4a858272 build's to the event (the batch pieces move nothing).

It first failed: 8 of 10 on the (a2) build (`a2_runs.md`), one fight by the player's blood at the
end alone (4694 vs 4699 ml), one from 91% in. A per-tick log of the player's bleeds over three
runs of one seed found it: the player's `Physiology.roll_rng` (does packing hold a fast bleed,
rolled when it's first pressed) was never seeded, and a new `RandomNumberGenerator`'s own seed is
random. HumanBody seeded his; PlayerWounds didn't. Step 1's three runs had happened to agree. Now
Physiology starts at a fixed seed and PlayerWounds seeds the player's; `WeaponViewmodel._rng`
(the dynamite's and the bucket's dice) starts fixed in `_init`. A sweep of src/ for generators
used before a seed found no others.

The body lab found a second hidden die (below): `WoundSigns` took its every-fourth-tick phase from
`body.get_instance_id() % 4`, and instance ids count every object made before him. Now
`hash(["signs", rng_seed])`. The gate was run again after it and after the batch pieces.

## The numbers (ms a frame; a `q_*` row is a count a frame)

| | before | (a) | (ab) | (abc)* | (abcd)* | **step 2 (a)** | **step 2 (b)** |
|---|---|---|---|---|---|---|---|
| frame (mean / p95) | 16.26 / 20.55 | 15.51 / 20.02 | 15.75 / 20.11 | 15.49 / 20.12 | 15.05 / 19.01 | **15.03 / 18.78** | **14.86 / 18.61** |
| people (mean / p95) | 9.26 / 12.11 | 8.78 / 11.54 | 8.57 / 11.41 | 8.56 / 11.19 | 8.31 / 10.79 | **8.22 / 10.63** | **8.17 / 10.63** |
| window / step / rest | 10.18 / 1.51 / 4.49 | 9.96 / 1.49 / 3.99 | 9.79 / 1.53 / 4.36 | 9.83 / 1.50 / 4.09 | 10.35 / 1.61 / 3.02 | 10.23 / 1.61 / 3.13 | 10.16 / 1.59 / 3.05 |
| `people_body` | 3.65 | 3.57 | 3.21 | 3.24 | 3.21 | 3.33 | 3.30 |
| `people_skeleton` | 1.12 | 0.82 | 0.84 | 0.81 | 0.64 | 0.48 | 0.48 |
| `q_writes` | 336 | 336 | 336 | 60 | 60 | 75 | 75 |

All of it in `perf.md`, with the builds between: `exact` (43f9ef3c, before the WoundSigns fix) 14.27
/ 18.15, `signs` (4a858272, before the batch pieces) 15.00 / 19.32 and 14.31 / 18.23. Step 2 (a)/(b)
is the final build (1f20f8f6: the changes, (c) exact, the seeds, the batch pieces), run twice. \* (abc) and (abcd) had (c) within 0.01 degree, which changed the fights (`q_cover` 71
against 65); the final build's are the before's again (every count the same; 9 of 10 event for
event, `same_fight_before_vs_step2.txt`: the tenth is s4's packing roll, random before).

**Against before: about -1.3 ms a frame (16.3 -> 14.95, the two runs' mean; p95 20.6 -> 18.7),
people 9.3 -> 8.2.** The last six runs of these builds read 14.3 to 15.0, two runs of one build up
to 0.7 apart here, and untouched
systems (`outlaw_brain`, `senses`) read up to 5% lower in the later runs, so the frame's total is
soft; the systems' own are steady across the runs: `people_skeleton` 1.12 -> 0.48, `people_body`
3.65 -> ~3.3, and the skeleton out of `rest` (it was `_process`). At Sean's (x0.65): about -1 ms.

| Change | What it did | Measured (this core) |
|---|---|---|
| (a) fingers | a `FingerBone` per skinned finger bone: side, thumb, relaxed bend and gain worked out once (no `String(fid).begins_with` a bone a frame) | `people_skeleton` 1.12 -> 0.82 |
| (b) the carry | `_track_carry` keeps the parts' global transforms for two ticks; the velocities are made only in `go_limp`, the one reader | `people_body` 3.57 -> 3.21 |
| (c) pivot sets | a pivot set only when the pose moved it | `q_writes` 336 -> 60 (within 0.01 degree), 75 exact; `people_body` and the window unmoved (below) |
| (d) the skeleton | bones set on his physics tick after the pose, from (b)'s transforms; `_process` only while he's limp | `people_skeleton` 0.81 -> 0.64, `rest` 4.09 -> 3.02 |
| (a2) finger bones parented | each finger bone hangs from the one before it (the knuckle from the hand) in the skeleton, set only when its finger bends | `people_skeleton` 0.64 -> 0.48 |

The brief expected -2.5 to -3 ms (`people_skeleton` 1.4 -> ~0.5, `people_body` 4.4 -> ~2.5). The
skeleton came where it was meant to (0.47). `people_body` came down less, because **the pivot sets
weren't its cost**: (c) took them from 336 a frame to 60 (the within-0.01 degree version) with
`people_body` 3.21 -> 3.24 and the window 9.79 -> 9.83, both inside the noise. The transform work a
set causes is paid where the transforms are next read. A probe of the final tick (`instrument.py`,
temporary sub-timers, three fights, `probe.md`) shows where the ~3.1 ms goes:

| `people_body`'s part | ms | what it is |
|---|---|---|
| `_apply_pose`'s loop | 1.10 | GDScript a pivot: the pose's Dictionaries, the flinch spring, the blend |
| `_apply_pose`'s tail | 0.50 | the rig (two feet's global reads), reach, grab, sling, `curl_hand`'s 15 finger sets a tick for an armed man |
| `_apply_pose`'s head | 0.16 | clips, the gait overlay, the injury targets |
| `_track_carry` | 0.46 | 17 global transform reads a man: the transform composition the sets leave dirty lands here (and serves the skeleton) |
| wound signs and stains | 0.16 | |
| physiology | 0.12 | |
| the rest (after, cough, favour) | 0.10 | |

What's left is GDScript a joint, not engine writes: the step 4 phases (the pose maths pure, on
workers) or a native pose are where it goes, not more skipping.

## (c) made exact

Skipping a pivot within 0.01 degree of its last set sent **19 of the physics lab's 151 falls**
another way (bisected: `before` = (ab) on all 19 and (abc) = the final (abcd) build on all 19, so
(c) alone; the lab's own noise on those 20 is one scenario, `P_table_blackout`). A standing man's
pose blends to its goal over a couple of seconds and the tail of that blend is below a hundredth
of a degree: left unset, he went limp from a pose a few micro-radians off, and a chaotic fall
went elsewhere (a chair's sit-back with one leg out ended 0.2 m less deep in the floor, the oak
stair's run never settled). Now a pivot is skipped only when the rotation is exactly the one last
set and its transform is the one that set left, so setting it again would change nothing. A
settled pose holds still exactly, so most sets still go: `q_writes` 75 a frame, against 60 within
the hundredth and 336 before.

The physics lab (`physics_lab.md`): **150 of 151 falls identical to the before's**; the 151st,
`Q_rail_charge_front`, isn't steady on main itself (step 1's README). On the final build 148:
`P_table_blackout`, which settles at 4.58 or 3.88 s on the before build itself, and two railing
charges, of which `Q_rail_charge_back` flips between two outcomes that the before gives as well
(one without `deterministic`, the other with it).

## The body lab

`python3 experiments/body_lab/run.py --out=...` (every scenario on the four Studio men, 216
records; its `report.py gather` stops on a `KeyError: 'check'` on both builds, so the records were
compared directly, `body_lab.md`). Two runs of the before: 216 of 216 the same. Before against step
2: 40 differ, a blood splat's ml by 0.1 in the hand, neck, grab and shotgun scenarios, under
`deterministic` too. Bisected to (a): its `FingerBone` objects moved the instance ids of what came
after, and with them `WoundSigns`' phase. With the phase from his seed in both builds (the before
patched by hand): **216 of 216 the same.** The fix moves every wounded man's sign ticks once, so the
body lab's records are re-based on it; the fights weren't moved by it (still 9 of 10 the before's,
the tenth the packing roll).

## What else was checked

- Every test file, each in its own Godot, three at a time, on the final build: **99 of 99 green**.
  On the builds before it, `test_perf`'s burning street failed its worst frame (272 and 273 ms
  against 250) in two sweeps that ran beside the physics lab. Alone it passes (four runs). Both builds side by side under the same load (two
  busy loops), twice: worst 165 / 172 ms before, 178 / 169 after; mean 23.9 / 23.1 before,
  21.7 / 23.3 after. The same range: the fire's settle, not the people.
- `test_studio_hands`, `test_bodies`, `test_body_lab`, `test_injuries`, the four weapon tests on
  each change as it went.
- `tools/scene_probe.gd` reads each bone's global pose and rest now (a finger bone's own pose is
  on its parent's).
