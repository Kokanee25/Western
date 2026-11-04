# The farmhouse collapsing (2026-11-04, issue #626)

Branch `claude/issue-626-gameplay-lane-gb6s05`. This VM: 4 cores at 2.1 GHz, headless,
`--fixed-fps 60` (one tick a frame: Sean's slow motion was two). Main in a worktree at fb84764, the
same native build, run alternately with the branch. The JSON runs aren't kept (~3 MB each).

```sh
# Sean's one stick inside the house (his F12s, #625), the mission running, 30 s after it:
experiments/blast_freeze/collapse_runs.sh build/cc/x 30 base noccd:--rubble-ccd=off \
    nocontacts:--rubble-contacts=off s10_2@10/2          # NAME[:GAME_ARGS][@VELOCITY/POSITION steps]
DIR=../western-main experiments/blast_freeze/collapse_runs.sh build/cc/m 30 main_1   # main's checkout
python3 experiments/blast_freeze/collapse.py build/cc/x/*.json   # a line a run: the collapse's 0-10 s
```

`bf_blast in=farm world=97.8,2.34,-48.94 stand=96.3,1.1,-33.6 mission=1`: Sean's stick and where he
stood; the gang in the house (`mission=1`). Frames carry `draws`/`prims` (rendered runs) and
`reporting` (awake rubble reporting contacts).

## What it costs (one run each, before the change; the VM ~1.4x slower than in the pairs below)

Over the collapse (0-10 s after the stick), median ms a frame; Jolt's `step` also per 100 awake
pieces (frames with 100+ awake):

| | frame | Jolt's step | step / 100 awake | our ticks (`window`) | settled (s) |
|---|---|---|---|---|---|
| main | 42.3 | 25.7 | 5.6 | 13.2 | 29 |
| no CCD on rubble | 43.5 | 26.6 | 4.2 | 13.8 | 26 |
| **no contact reports on rubble** | **19.6** | **4.6** | 3.5 | 11.2 | **6.5** |
| solver steps 10/2 (velocity/position) | 27.9 | 14.0 | 3.3 | 11.0 | 24 |
| 20/2 | 31.4 | 17.5 | 4.6 | 11.1 | - |
| 10/8 | 27.2 | 14.3 | 3.6 | 10.6 | - |

Before the stick a frame is ~15-20 ms here (the gang's and the town's ticks, `window` ~12).

**Why the contact reports cost so much**: Godot's JoltBody3D turns Jolt's *manifold reduction* off
for any body that reports contacts (`set_max_contacts_reported`: `SetUseManifoldReduction(!reports)`,
Godot 4.7.2 `modules/jolt_physics/objects/jolt_body_3d.cpp`). Every rubble piece reported 4, so
every face against a face was a contact manifold of its own: many more constraints for the 20/8
solver steps, and piles that jostle longer before they sleep. CCD costs nothing measurable.

## The changes

1. **A piece reports its contacts only while it's fast** (`Structure._report`, from
   `_physics_step`): on above 0.5 x the harmless speed (0.75 m/s), off below 0.35 x; over a dug
   tile always (`Ground.rescue` reads its contacts). Changing the count wakes the body, so only
   awake pieces are changed. When it's turned on, the first reports (what it already lay against)
   aren't landings (`reports_from`). Nothing slower than the harmless speed (1.5 m/s) did anything
   in `_on_rubble_hit`, and a piece can't get from 0.75 to 1.5 m/s under gravity within the tick
   it's turned on; one struck that fast in a single tick and hitting something within 1/60 s is
   missed. On the branch ~10-50 pieces report at a time over the collapse (main: every one, ~430).
2. **No GPU read back when rubble joins its cell.** `RubbleRest._part` read each piece's mesh with
   `SurfaceTool.append_from`, i.e. `surface_get_arrays`: on Vulkan three `buffer_get_data` calls,
   each `_flush_and_stall_for_all_frames()` (Godot 4.7.2 `rendering_device.cpp`), so with the GPU
   at 35-50 ms a frame (Sean's) each joined piece cost about a frame: Sean's RubbleRest join at
   ~40 ms a frame against its 1 ms budget. Headless the renderer keeps the data on the CPU, so the
   lab never saw it. Now `MemberMesh.arrays_of` (the arrays the mesh was made of, kept on it by
   `MemberMesh.made`; a primitive's made again; anything else read once and kept) and
   `MemberMesh.placed`. `Structure._member_inputs` (the batches' merge) uses them too.
   `tools/readback_cost.gd` under lavapipe, an empty scene: 0.15 ms a mesh, 0.38 ms an
   `append_from`, with the GPU idle; on Sean's GPU it waits for the frames in flight.

## The numbers (three pairs, alternately: main, the branch, the branch with no reports at all)

Median ms a frame, the frame before the stick, then 0-3 s and 3-10 s after it; Jolt's step:

| run | before | 0-3 s frame / step | 3-10 s frame / step | settled (s) | broken |
|---|---|---|---|---|---|
| main 1 | 19.7 | 64.5 / 40.9 | 43.6 / 22.7 | 11.7 | 468 |
| main 2 | 15.8 | 45.5 / 25.4 | 43.0 / 23.6 | 30.0 | 471 |
| main 3 | 13.5 | 44.1 / 25.2 | 43.4 / 25.9 | 28.6 | 480 |
| branch 1 | 18.1 | 44.1 / 18.9 | 38.3 / 16.0 | 13.5 | 469 |
| branch 2 | 17.1 | 45.0 / 21.7 | 39.6 / 17.4 | 28.0 | 472 |
| branch 3 | 15.5 | 39.1 / 19.1 | 30.7 / 11.6 | 21.5 | 498 |
| no reports 1 | 19.7 | 40.6 / 17.7 | 29.7 / 9.5 | 7.3 | 464 |
| no reports 2 | 17.0 | 38.3 / 19.9 | 37.1 / 17.9 | 11.0 | 464 |
| no reports 3 | 15.7 | 36.6 / 16.6 | 24.4 / 5.5 | 11.6 | 464 |

Over 0-10 s: frame median main 44.0 (43.5-49.3), branch 40.0 (33.4-41.8); Jolt's step main 25.5,
branch 17.0 (13.0-18.2): **a third off the step, ~30% off what the collapse adds to a frame**
(~27 ms here over the frame before it on main, ~19 on the branch). Per 100 awake pieces the step
is ~5 on the branch against ~5-11 on main. "Settled" (fewer than 50 awake from then on) is chancy
on both: the gang moving through the wreck keeps piles stirring (one branch run held 44 still
pieces awake for 20 s in an island with a dead man's ragdoll that kept moving). Broken: the branch
469-498, main 468-480 (an earlier pair: main 469-557, branch 473-480), within main's spread.

Not halved. Turning reports off altogether is only a little better again (frames 24-37 at 3-10 s)
and would lose the landings; what's left of the step is the solver's 20 velocity / 8 position
steps on the moving pile.

## How men fall: unchanged

The ragdoll lab, main against the branch (all 191 scenarios, one process each): 157 bit for bit
the same; the 34 that differ are the ones where a man breaks timber or furniture (O, Q, T, U, X, Y:
chairs, tables, railings, the stair's top), whose rubble now lands a little differently. Their
flags (lingering motion aside) total 1,300 on main and 1,301 on the branch; over all the falls
joint gap sum 2.88 / 2.90, joints pulled apart 5 / 7, launches 690 / 652, swing past limit 2,131 /
1,995, the same endings (face down 68 / 67, back 55 / 57, side 46 / 45).

## Lower solver steps: not kept (the falls lab)

Jolt's steps are global in Godot (no per-body override exposed: Jolt's own
`mNumVelocityStepsOverride` isn't reachable), so rubble can't have fewer than the ragdolls. The
ragdoll lab (`experiments/physics_lab/run.py`, all 177 falls, headless; `override.cfg` per run):

| steps | joints pulled apart | joint gap sum | swing / twist past limit (deg, summed) | launches | up on his knees at the end |
|---|---|---|---|---|---|
| 20/8 (the game) | 7 | 2.90 | 1,995 / 2,754 | 652 | 3 |
| 20/2 | 26 | 4.46 | 2,873 / 4,026 | 752 | 4 |
| 10/8 | 14 | 3.46 | 2,589 / 2,783 | 682 | 8 |

Both worse for the men; the step's saving (~35-40% a moving piece at 10/x, ~20% at 20/2) isn't
worth it.

## Not measured here

- **The GPU** (Sean's 35-50 ms): no real GPU on this VM; lavapipe draws on the CPU. Suspects, in
  order: the join's stalls above (fixed); the blast's cloud (114 lit, proximity-faded dust quads a
  0.35 kg stick, up to ~6 m across, 16 s, and its FogVolume); the pieces not yet in RubbleRest's
  cells drawn each on its own in every shadow pass. Sean's F12 with F3 up on this build tells.
- **The 455 ms untimed frame** at 189.6 s: not reproduced headless (no frame here over ~140 ms).
  A GPU stall is the kind of thing that long and untimed; the join's read backs were timed, so
  it's another (Sean's F12 with F3 up names the system if it comes again).
