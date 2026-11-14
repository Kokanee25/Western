# A burning building drawn in its batch (2026-10-28, issue #434)

Branch `claude/gameplay-burn-batched`. Before: main at 42781ae. This VM: 4 cores at 2.1 GHz,
lavapipe for Vulkan (installed this session: without it `--rendering-driver vulkan` falls back to
OpenGL, and the renders and draw counts are the Compatibility renderer's).

## What changed

- A heated or charred member stays in its structure's batch. The batch draws its char and glow
  (`char_batch.gdshader`: each vertex carries its member's place in the batch in CUSTOM2, and
  `looks[64]` holds each place's char and glow). Heat no longer unbatches: a member is drawn on its
  own only once it breaks, is cut, holed or burns away. It then gets `char_overlay.gdshader`, one
  shared material per step of its look (32 char x 8 glow), carried over when it's unbatched or
  snaps.
- `FireFX` only for the members showing flames (`max_flames`, 40). Its sheets and one smoke stand
  on the member itself while it's at rest in its batch, and on its pieces once it's broken.
- No shape realised for heat: a hot member's collision stays the body's shape owner.
- `FrameBudget.part_of`: timers taken inside another (the fire's tick, loads, grid and neighbours
  inside `fire`; the smoke field's; a settle's, the analysis's and a blast's steps) count in no
  part. Each was counted a second time in "else".

## The numbers

**Sean's case, the spec saloon burning whole** (`../2026-10-27_whole_burn/run_burn_headless.sh`,
headless; main's readings are that folder's `burn_readings.txt`; the branch's `burn_readings.txt`
here):

| game s | main: frame ms, nodes, burning | branch: frame ms, nodes, burning |
|---|---|---|
| 0 | 9.3, 22983, 0 | 15.2, 23155, 0 |
| 60 | 14.9, 23309, 32 | 11.6, 23242, 29 |
| 90 | 22.7, 24785, 313 | 20.8, 23262, 310 |
| 120 | 43.5, 27629, 1179 | 41.7, 23259, 1173 |
| 150 | 43.5, 30089, 2023 | 47.6, 23323, 2020 |
| 180 | 50.0, 32932, 2944 | 66.7, 22942, 2938 |

- Nodes stay flat on the branch; on main a burning saloon added ~10,000.
- The fire spreads the same.
- The headless frame is the simulation alone (the fire's tick, #400), so it doesn't move; the gain
  is in the drawing.

**A building fully alight, drawn** (`tools/fire_cost.gd`: the livery, every member alight and grown,
from livery_fire_dusk's view; `fire_cost.txt`). On Vulkan (lavapipe):

| | draws | render CPU ms |
|---|---|---|
| main | 7,656 | 14.3 |
| branch | 4,720 | 11.1 |
| the view with no fire | 3,753 | 9.5 |

The fire's own draws went from 3,903 to 967, and its render CPU from 4.8 to 1.6 ms. Under the
OpenGL fallback: 11,322 -> 6,587 against 5,182 with no fire.

**`perf_bench --scene=blaze`** (dynamite and fires, 45 s, then measured; `blaze_census.txt`):

| | FireFX | particles | meshes_visible | collision_shapes | nodes |
|---|---|---|---|---|---|
| main (two runs) | 1,605 / 1,582 | 305 / 295 | 4,488 / 4,569 | 3,714 / 3,723 | 25,567 / 26,001 |
| branch (three runs) | 40 / 40 / 40 | 303 / 310 / 295 | 3,263 / 3,334 / 3,333 | 2,451 / 2,514 / 2,475 | 21,380 / 21,723 / 21,813 |
| the calm street | 0 | 2 | 1,427 | 789 | 16,627 |

What's left over the calm street (`blaze_after_by_owner.json`):
- ~1,400 pieces of rubble, each its own body, mesh and shape. These are mostly the dynamite's and
  the collapse's: `main.gd` 937 shapes and 963 meshes (rubble put in the street), plus the
  buildings' own.
- 225 of the particles are `ImpactEffects` bursts.
- ~49 are FireFX smoke, the 40 plus some fading out.
- ~345 glass shards.

None of it is from heat. Draws in the blaze (`--render` under the OpenGL fallback): 14,321 on main
and 12,848 on the branch. The fire's share is small there; the rubble and shards, in every shadow
pass of 75 lights, are most of it.

**The budget line, with nested timers counted once.** "Else" was 14-23 ms at Sean's clock. Nearly
all of it was the fire's own tick counted a second time (`fire_tick`, `fire_near`, `fire_loads`,
...). Recomputed from the same runs: main 2.3 (1.96 of it untimed), the branch 0.4 and 0.3. The
budget for "else" is 1.0.

"Physics" (the engine, server paused against running) is noisy in both builds and follows the
rubble: main 1.9 / 4.8, the branch 7.7 / 3.9. The headless frame swings ±35% run to run on this
VM: main 30.7 / 42.1 ms, the branch 33.1 / 47.2. The fire's tick (`fire_effects` 11-21 ms) is #400's.

**Determinism.** The blast-freeze lab's pair (`bf_blast ... --deterministic`, twice) was the same
twice: 600 frames, 0 differing. The broken set's hash was 1650757771, the lab README's for main.

**Goldens.** `store_fire_night`, `store_fire_close`, `store_fire_later`, `livery_fire_dusk` and
`saloon_fire_inside` all pass on Vulkan (closest: saloon_fire_inside, mean 10.17 of 11.21; its
flames are another frame of their animation). The char's look is unchanged (the same code in
`char.gdshaderinc`), so nothing is re-approved.

## Not done here

- The fire's lights (step 4): whether the one shadowed light of the six stays, and their ranges
  (4-14 m by the fire's size). This needs a real GPU (Sean's F3); lavapipe can't say.
- Rubble at rest drawn in a batch: the next issue.
