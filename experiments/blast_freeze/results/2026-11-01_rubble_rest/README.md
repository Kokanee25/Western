# Rubble at rest drawn in its cell; batches on the pool (2026-11-01, issue #459)

Branch `claude/issue-459-9om801`. Before: main at c42069a / 976f112 (the same code). This VM: 4
cores at 2.1 GHz, lavapipe for Vulkan (installed: without it the renders fall back to OpenGL).

## What changed

- **`RubbleRest`** (`src/structures/rubble_rest.gd`, `docs/LAYOUT.md` "src/structures"): rubble
  and shards that haven't moved for 1.5 s are drawn as one mesh a material (and char overlay) per
  20 m cell, as chunks joined on a worker; their own meshes leave the tree once their chunk shows,
  their shapes only while asleep (held on the body as shape owners). Moving, shot, blasted,
  shoved, broken up, or the fire on its member: its own again at once, its stretch zeroed in place.
- **One-shot particles freed**: a new `GPUParticles3D` starts with `emitting` on; setting it on
  again cancelled `finished`, so every burst lived for ever (225 `ImpactEffects` in a blaze). Every
  one-shot sets it off first (impacts, blood, the blast cloud, steam, the bucket's spray).
- **Batches per drawn frame, merged on the pool** (Sean's comment on #459): every structure's
  rebuilds share 3 ms of a drawn frame (was each structure's 6 ms on each physics tick); a piece's
  members are merged on a worker (`Structure._merge_members`, the SurfaceTool's result, held to it
  by `test_batch_rebuild`), only the ArrayMesh made on the main thread.
- **A cut's ends join their material's batch** (were each drawn on their own for good).
- `perf_bench --census-by`: what's on loose bodies by state (`*_on_bodies`), awake bodies by group,
  and the rest's counts (`rubble_rest`).

## The numbers

**`perf_bench --scene=blaze --census-by --no-ablate`** (headless, the census after 45 s of fire and
two sticks; the frame is the simulation alone and swings ±40% run to run here):

| | meshes_visible | collision_shapes | particles | awake bodies | nodes | frame ms |
|---|---|---|---|---|---|---|
| main | 4,247 | 3,185 | 305 | 526 | 24,275 | 29.4 |
| branch, rest off (`--no-rubble-rest`), run a | 4,133 | 3,087 | 4 | 0 | 23,643 | 15.2 |
| branch, rest off, run b | 4,284 | 3,200 | 37 | 537 | 24,033 | 32.8 |
| **branch** | **2,249** | **1,494** | **5** | 471 | **20,196** | 27.8 |
| the calm street | 1,428 | 789 | 1 | – | 16,634 | – |

Over the calm street the branch's blaze has +821 meshes and +705 shapes (main +2,819 / +2,396).
What's left (`blaze_census.json`):
- the cells' own meshes, 209 (that's the drawing: ~1,600 pieces in them);
- people, +121 (the dead and what they dropped);
- standing members holed or carved, drawn on their own, +152 (voxel meshes; not this issue);
- shapes: ~440 on pieces in a cell whose piles Jolt keeps awake. They come off when those sleep.
  Taking them off awake bodies too reset the bodies' contacts and kept their piles awake: the
  physics step was ~1.4x main's for seconds after a stick, so it isn't done.
- ~50 chimney-glass shards (their shader is mapped in object space: not joined), and pieces
  alight or just touched by the fire (they join once it's done with them).

**Awake piles are main's too** (a finding for later, not changed here): in a blaze ~500 rubble
bodies stay awake 45 s on, barely moving (v < 0.02 m/s), in piles; two runs of the same build
gave 0 and 537, and the frame follows them (15 vs 33 ms). Jolt's sleep test is on the speed of
a body's points: a long board rocking a little never sleeps, nor its pile.

**Sean's case, a stick in the spec saloon, no fire** (the lab's `bf_blast at=6.0,0.8,6.0 fire=0
seconds=8`, `--fps=60`; the 8 s after the stick):

| | broken-set hash | batches: max / mean ms | rubble_rest max / mean | frame p50 / p95 |
|---|---|---|---|---|
| main | 74050540 | 6.8 / 0.18 | – | 19.5 / 37.8 |
| branch | 74050540 | 4.5 / 0.16 | 3.9 / 0.36 (+ its meshes 4.2 / 0.07) | 22.7 / 41.2 |

`batches` stays under 5 ms a frame here (3 at Sean's clock) through the blast's tail. The frames
differ mostly in the physics step (8.8 / 9.7 ms mean, within its run-to-run swing) and the rest's
own ~0.4 ms.

**Determinism** (the lab's pair, `bf_blast ... fire=6 burn=20 --deterministic`): the branch the
same twice, 600 frames, 0 differing, broken set 1632629072. Against main: the same broken set;
with `--no-rubble-rest` every frame the same as main's, with the rest on 12 frames near the end
one "hot" member apart (bodies' shapes set aside while asleep).

**Goldens** (Vulkan, lavapipe): `dynamite_lit` passes. `dynamite_store_blast`,
`dynamite_store_after` and `outlaw_blast` fail on main too, by as much or more (main against the
goldens: mean 10.8 / 6.4 / 6.4; the branch 5.9 / 6.4 / 6.3): the mid-blast cloud and the outlaw's
pose drift from run to run. The branch's renders against main's: `dynamite_store_after` (the
rubble lying in the street, all of it in cells) mean 0.17, `outlaw_blast` 1.2, the mid-blast view
7.5 (its cloud). Nothing re-approved.

RENDER_DRAWS
