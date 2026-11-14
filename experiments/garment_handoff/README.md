# The garment handoff's lab (#895)

Sean, 2026-11-13 (toward #874's variety acts): "Could we have her really take off a stocking or long
glove". The reusable core is **the garment handoff**: a worn, skinned garment becoming real cloth as
it's taken off. Here a long glove is drawn off MetaHuman Sean's left arm by his right hand, tossed,
and left lying on a chair. **Promoted (#917, 2026-11-14):** the glove, the cloth, the release rule
and his skin's shape are the game's `GarmentHandoff` (`src/bodies/`; docs/LAYOUT.md "src/bodies");
this lab keeps the choreography (`handoff.gd`), the bench and the bridge, now on the part. Below,
"glove.gd", "glove_cloth.gd" and "arm_colliders.gd" are the lab's first files, now `WornGarment`,
`GarmentCloth` and `SkinCollider` (the fitted rigid shapes weren't promoted).

## On the game's part (#917, `results/2026-11-14/`)

- **The film:** [`results/2026-11-14/garment_handoff_part.mp4`](results/2026-11-14/garment_handoff_part.mp4)
  (the same three angles and the draw at half speed, on Sean's Studio man `sean_s3_talking`: the
  MetaHuman's files weren't to hand), and **beside the lab's**:
  [`results/2026-11-14/beside_the_lab.mp4`](results/2026-11-14/beside_the_lab.mp4) (left the lab,
  right the part). Each run's numbers: `film_runs.jsonl`.
- **Measured on `sean_s3_talking`** (bench, 700 triangles, 372 points): no pop (1.5-1.6 mm), the
  whole glove off his arm 1.1 s after the take, at rest on the chair 7.1-7.5 s after the cue, stretch
  at most 1.06, nothing below the floor, flung or lost (`measure.json`); under his skin more than
  2 mm at most 26 (10 deeper than 5 mm, 1 deeper than 1 cm; 23-29 over runs while tuning). The worn glove itself counts 4 (his modelled sleeve
  folds stand above its points: they show through it worn in places, white patches on the forearm in
  the film's first seconds). The lab's MetaHuman (bare skin) counted 8; the ≤ 8 bar wants a run on him.
- **The cost** (`cost.md`, 3 runs each way, x0.65 to Sean's): worn 0; while it simulates, take
  +0.53 ms (9 ticks; the take's own tick builds the soft body), draw **+0.43**, toss +0.19 (0.40 over
  the 188 ticks it simulates); falling +0.14; at rest 0. (The lab: +1.0 while it simulated.) The skin
  shape's cost was Jolt rebuilding the concave shape in the world (~1.5 µs a triangle, ~0.4 ms a
  tick for 700), not the skinning (0.07 ms for 372 points through only the binds used): it's rebuilt
  every 2nd tick (the arm moves ~1 mm a tick) from the triangles near the free cloth, and Jolt's own
  soft-body cost halves with it (its contacts aren't thrown away every tick).
- **Not native:** crates.io isn't reachable from this workspace, so the Rust route wasn't built;
  the GDScript route met the target.
- **Rest:** the cloth's speed is compared a quarter second apart (a glove on a floor shivers a mm for
  ever, cm/s tick to tick; on the floor it never came to rest by the tick measure).

**The film:** [`results/2026-11-13/garment_handoff.mp4`](results/2026-11-13/garment_handoff.mp4)
(33 s, in the game's real look on the street at 16:12: the hands, wide, the chair, then the draw at
half speed). The stills are in `results/2026-11-13/sheet.jpg`.

## What it is

- **The man:** `sean_metahuman_s3`, the Studio's frozen build of Sean's MetaHuman. It's s2 (#692/#696)
  on main's fuller skeleton with the Studio's fixes, approved by Sean 2026-11-09. Under #692's licence rules
  his files never go in this public repo: copy them in for a run and they stay out of git (below).
  #889's route hadn't merged, so this uses the frozen build directly. He's drawn with his GLB's own
  materials, as the skeleton lab and the Studio draw him.
- **The glove** (`glove.gd`) is made by script from his own skin, not modelled:
  - his `Skin_whole` triangles on his left arm below the cuff (by bone weight; the cuff is 0.42 of
    the way down his upper arm, an opera glove's length);
  - welded at the mesh's seams, simplified with meshoptimizer (`SurfaceTool.generate_lod`) from
    6,293 points to 371 (699 triangles, every finger kept);
  - pushed out along the normals, 2 mm on the hand and 4 mm up the arm.
  
  Each point keeps the bones and weights of the skin under it, so while worn it's part of his skinned
  mesh: a `MeshInstance3D` under his `Skeleton3D` with his skin's binds and his `custom_aabb`.
  Its look is black kid: a PBR `StandardMaterial3D` (roughness 0.48, a cloth rim, a fine grain
  normal), drawn by the real look like any other.
- **The handoff** (`handoff.gd`), phases from the cue:
  1. **present**: his left hand goes out in front, palm down (`HumanBody.reach_to`).
  2. **reach**: his right hand goes to its fingertips, pinching (`curl_hand`).
  3. **take**: the worn glove is hidden and a `ClothProp` takes its place (`glove_cloth.gd`, the
     rag's class with the glove's points and triangles). Every point starts where the GPU drew the
     worn glove that tick: his skin skinned on the CPU, as the GPU does it. The four fingers' tips
     (not the thumb's) are pinned to his right hand where they are. Every other point is pinned to
     its own bone as worn: friction holds a glove on until the pull reaches it.
  4. **draw**: the right hand draws it along the left hand's line, with two tugs, while the left
     arm draws back. **Friction gives way:** while the cloth already pulled free is stretched past
     5%, the points still on the arm nearest the fingertips let go, the front moving up the arm at
     most 1 cm a tick. The free cloth slides down the fingers and forearm and gathers at the hand.
  5. **toss**: a swing toward the chair; let go with what's still wanted to land on its seat in
     0.45 s.
  6. **lie**: it falls and drapes. Once its points' mean speed has stayed under 1 cm/s for 0.75 s,
     the soft body is freed and its shape is kept as a plain mesh, so a resting glove costs nothing.
- **What the cloth meets** (`arm_colliders.gd`): from the take until it's clear of him, **his skin
  itself**. The glove's own points pulled back to just over his skin are skinned on the CPU each tick
  and handed to a `ConcavePolygonShape3D`, on a physics bit only the glove looks for (1<<12). The
  floor and the chair are the world's. The fitted rigid shapes it started with (capsules a slice
  along the limbs, a box for the palm, a capsule a finger bone) are still there as `--shapes`.

## Runs

```sh
cp ../saltcreek-characters/frozen/sean_metahuman_s3/* assets/people/      # the Studio, attached (private)
printf '/assets/people/sean_metahuman_s3*\n' >> .git/info/exclude         # never committed
godot --headless --import
godot --headless --fixed-fps 60 -s res://experiments/garment_handoff/bench.gd -- --out=DIR [--seconds=14]   # measured: DIR/summary.json
xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://experiments/garment_handoff/bench.gd -- \
    --out=DIR --shots=2.7,3.3,4.2 --cam=hands|left|close|front|side|floor   # stills, plain lights
# (--model=NAME: the man, barkeep_s2_talking by default; --tris=N; --precision=, --skin_every=, --give=: the part's tune)
# The cost, runs each way (--bare: the same hands, no glove), then the table:
godot --headless --fixed-fps 60 -s res://experiments/garment_handoff/bench.gd -- --out=build/gh/perf_glove_1 --perf --seconds=14
godot --headless --fixed-fps 60 -s res://experiments/garment_handoff/bench.gd -- --out=build/gh/perf_bare_1 --perf --bare --seconds=14
python3 experiments/garment_handoff/cost.py build/gh/perf_glove_* -- build/gh/perf_bare_* > cost.md
# The film (the dev bridge in the real look; one bridge.py call a line, ~8 min an angle under lavapipe):
python3 tools/bridge.py start --size=960x540 --fps=30 --game-args=--real
while IFS= read -r l; do python3 tools/bridge.py "$l"; done < experiments/garment_handoff/results/2026-11-13/films.txt
python3 tools/bridge.py stop
```

Bench flags: `--no-take` stops after the reach; `--hide-glove` hides the worn glove; `--all-skin`
rebuilds all of his skin shape (not only near the cloth). (The lab's `--shapes`, `--debug` and
`GH_DEBUG` went with its first files.) The bridge's commands: `gh_man X Y Z [YAW] [MODEL]`,
`gh_dress`, `gh_cam`, `gh_film`, `gh_clear` (`bridge.gd`).

## Results (2026-11-13, `results/2026-11-13/`)

`measure.json` is the bench's measured run; `cost.md` the cost; `films.txt` the film's commands.

- **Frames of the handoff** (60 a second, from the cue):
  - present 59, reach 67, take 9 (2.12 s), draw 156 (2.27-4.87 s), toss 23, lie 247;
  - the whole glove is off the arm 0.82 s after the take;
  - at rest on the chair 9.37 s after the cue (7.4-8.3 s in the films' runs).
- **No pop:** the cloth's points in its first three ticks are at most **1.4 mm** from where the
  worn glove would be drawn (his arm is still easing).
- **Cloth through the arm**, counted each tick against his skin as drawn: points more than 2 mm
  behind the nearest skin vertex, along its normal. It's **0 at the take**. **At most 8 of 371
  points** while it slides down the forearm and over the wrist (3 deeper than 5 mm, 1 deeper than
  10 mm), in 27 of the 188 ticks it's on him. Nothing after it's off.
- **Stretch:** the cloth's edges at most 1.066 of their worn length together. Nothing went below
  the floor, was flung (over 20 m/s) or was lost. It lands on the chair's seat and drapes over its
  front edge, every run (same seed, same result).
- **The cost at Sean's** (`cost.md`; the whole tick's median, glove against bare, x0.65):

  | | worn | reach | while it simulates (take, draw, toss) | falling, draping | at rest |
  |---|---|---|---|---|---|
  | the glove's extra | 0.00 ms | +0.20 | **+1.0 ms** | +0.23 | **0.00** (-0.04) |

  While it simulates, the skin shape takes 0.6 ms a tick (GDScript skinning 371 points, then
  `set_faces`), the handoff script 0.2 (its stretch rule) and ClothProp's script 0.03. Jolt's soft
  body and its contacts take the rest, ~0.2. At the reach, the handoff script skins all 371 points
  a tick to find the fingertips (0.14). His own body (`people_body`) is the same either way (~0.15).
  One man taking off one glove fits the People budget (4 ms) for the 3 s it takes. Ten at once
  wouldn't.

## What worked, what didn't

- **Worked:**
  - the glove made from his own skin (it fits as his skin does, fingers and all);
  - starting the cloth from the CPU-skinned points (no pop);
  - pinning the worn part to its bones until the pull reaches it, then letting it go by the free
    cloth's stretch (friction giving way);
  - his skin as the collision shape;
  - baking it at rest.
- **Didn't, and why:**
  - **Rigid shapes inside the skin** (capsules and a palm box) let up to 62 points sink under the
    skin as it slid: a skinned arm bends at the elbow and wrist, and its section isn't round.
    Grown to fit, they overlapped the skin at the bent joints (57 points "inside" before anything
    moved).
  - **A release schedule by distance drawn** stretched the finger stalls to 1.9x: the solver's
    few iterations gather the stretch in the middle of the free cloth, not at the edges by the
    pins. Pinching the thumb's tip with the fingers dragged its stall across the hand.
  - **The glove's sliver triangles from the simplifier** stretch far relatively (sub-millimetre
    edges). Harmless to look at, but a cleaner remesh would help.
- **Traps met:**
  - A `SoftBody3D`'s mesh needs normals: it writes position and normal into the drawn buffer by
    that layout, and without them it's drawn as a scrambled bar a metre long while its physics
    points are right.
  - A skinned mesh added to a man needs his `custom_aabb`, or it's culled once the arm moves.
  - A packed array in a dictionary is a copy (`dict[k].append` does nothing).
  - Jolt still doesn't hold pinned points; the prop moves them, as the rag does.
- **Still rough:**
  - 8 points briefly under the skin as it passes the wrist;
  - the cloth is a single sheet with no thickness;
  - its look is close only in the hands angle (no inside of the glove is drawn: it's black);
  - the throw is aimed (it lands on the seat every time because it's thrown there).

## What the coat, the hat and the torn-shirt bandage would need next

- **The coat:**
  - the same handoff, on his own clothes mesh (the waistcoat's or a coat's skinned triangles) instead
    of an offset of his skin;
  - both arms out of the sleeves in turn: one sleeve pinned to the hand drawing it, the other arm's
    sleeve held on its bones until pulled;
  - the body of the coat held at the shoulders and collar until it's off;
  - more points (a coat is ~2 m² against a glove's ~0.07), so the skin shape's rebuild must go
    native, or be skinned on the GPU and read back, or cover only the part of him it's near;
  - hung up: `ClothProp.hang_over` on a peg (the doctor's coat pegs) is already in the kit.
- **The hat:** not cloth. The hat is already a rigid body (`HumanBody.hat_body`); "taking it off" is a
  hand to the brim (`reach_to`), the hat parented to the hand, then placed on a peg or table, or tossed
  as a LooseProp. Only a soft hat (a slouch hat's brim) would want cloth.
- **The torn-shirt bandage:**
  - the garment's triangles cut along a line (the tear: a strip of the shirt's mesh split off by
    weight and position, its edge frayed in the texture);
  - the strip becomes a `ClothProp` held in both hands;
  - the shirt keeps a hole there (the wound shader's holes, or the cut triangles hidden);
  - then the bandage is wrapped: pinned round the wounded part (a ring of pins on the part) and
    soaking blood as the rag does (`ClothProp.soak`), the dressing the body lab already paints.
- **For the game** (gameplay's, after Sean's word): `GarmentHandoff` as a part in `src/props/` (the
  worn mesh from a garment, the handoff, the stretch rule, the bake at rest); his skin's collision
  shape posed natively (the Rust plugin) or on fewer points near the cloth; `glove_cloth.gd`'s mesh
  path and normals folded into `ClothProp` (a `mesh` kit field beside `points`).
