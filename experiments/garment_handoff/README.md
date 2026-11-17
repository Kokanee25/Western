# The garment handoff's lab (#895)

Sean, 2026-11-13 (toward #874's variety acts): "Could we have her really take off a stocking or long
glove". The reusable core is **the garment handoff**: a worn, skinned garment becoming real cloth as
it's taken off. Here a long glove is drawn off MetaHuman Sean's left arm by his right hand, tossed,
and left lying on a chair. **Promoted (#917, 2026-11-14):** the glove, the cloth, the release rule
and his skin's shape are the game's `GarmentHandoff` (`src/bodies/`; docs/LAYOUT.md "src/bodies");
this lab keeps the choreography (`handoff.gd`), the bench and the bridge, now on the part. Below,
"glove.gd", "glove_cloth.gd" and "arm_colliders.gd" are the lab's first files, now `WornGarment`,
`GarmentCloth` and `SkinCollider` (the fitted rigid shapes weren't promoted).

## Itself's lists by how far they go (#1029, 2026-11-17)

- **Now** (ClothCore `own_candidates`): neighbour lists with a skin per point (Verlet 1967's, as in molecular
  dynamics). Each point may go an allowance against the cloth's mean (half again as far as it went in 3 substeps
  last tick, + 0.5 mm, 1 mm-5 cm) before they're all listed again; a pair is listed if it could come within two
  thicknesses with both at their allowance's end; checked where it meets, every substep. Lists only when needed,
  and every pair that could meet is listed (the speed-based lists could miss one: a point's speed while drawn is
  mostly his skin's pushes). Measures now `self_lookups`, `self_list_us`, `self_meet_us`, `self_met` (bench `self_us`).
- **Cost with itself on** (ms a tick here, solver; old in the same hour): MetaHuman seed 1 drawn/tossed/lying/at rest
  17.2 / 11.7 / 7.3 / 2.8 -> 12.9 / 6.3 / 4.7 / 2.1 (seeds 2-3: 13.1 / 7.6 / 5.5, 12.9 / 6.3 / 3.8), lists 19.6 -> ~10 a
  tick drawn; sean_s3_talking seed 1 15.5 / 11.8 / 6.7 / 1.6 -> 14.4 / 12.2 / 5.8 / 4.0. Without itself drawn is ~6: itself
  is ~+4.5 ms drawn at Sean's on the MetaHuman (was ~+7), ~+5.5 on the talking man. The Rust sheet bench 8.1 -> 4.75.
  **Not there** (~2-3 wanted): still off.
- **Quality:** MetaHuman 1-3 and talking 1 rest, flung 0, pop 1.83/1.78 mm, stretch 1.08/1.05. **sean_s3_talking seed 2
  no longer rests** (still moving after 11 s, 3 lists a tick lying): with every pair listed the run differs from the
  old lists' (bit-for-bit the same meets only if both list all within two thicknesses); the talking man's runs are
  chaotic. A gate for turning it on.
- **Why not further** (results `build/`-only, the numbers above): while drawn, 35-100 points at a time go past their
  allowance, and they aren't jostled (their swing beyond their net travel is ~0) but travel, 5-30 mm a tick against
  the mean: the cuff going with his hand, the rest on his arm. Each whole listing ~0.5 ms, ~10 a tick.
- **Dead ends:** (1) per-point lists by speed (each point relisted when its speed says, its window the fastest
  triangle near it; one hash a tick, boxes swept by speed): 16.5 -> 19 drawn, speeds are noise (his skin's pushes, 5 mm
  a substep this way and that). (2) Allowances of a whole tick's travel: 3 lists a tick but 90 pairs a point (meet
  5 ms). (3) Relisting only the points past their allowance (their own list, their triangles into everyone's: by
  brute force with a sphere first, then by insert-only hashes of triangles and of points): with 35-100 at a time it
  costs a whole listing or more, and allowances widened on the way swell every list (narrowed once a tick: 12.6
  drawn, no better). (4) Each point's swing added to its allowance: no change (they travel).
- **Next, if itself is still wanted:** frames per part of the glove (the cuff in his hand, the rest on his arm, each
  its own mean: only the fold between them slides), or its whole listings over the worker pool (~0.5 ms each, ~10 a
  tick drawn). And the talking seed 2 rest first.

## The cost of the finer skin, and itself again (#1023, 2026-11-17)

- **Cost** (ClothCore `collide_verts`, `vert_candidates`; MetaHuman seeds 1-3, sean_s3_talking 1-2, all rest, flung 0,
  pop 1.83/1.53-1.78 mm, stretch 1.08/1.05, skin out worst 598-739 / 1334-1371 vs 576-634 / 1669-1723, forearm 65-74):
  the finer skin's list+meet while drawn 5.1 -> 2.9-3.2 ms a tick here (list 1.64 -> 1.1-1.5, meet 3.5 -> 1.9-2.1),
  the solver 8.8 -> 5.8-6.6 (talking seed 2 8.9) on today's slower workspace (x0.65 for Sean's: ~3.7-4.3 -> ~2.6-3).
  What did it: a room per candidate pair (most of a vertex's ~19 pairs are far and were retested each substep: meet
  3.5 -> 1.8), a pair's edges before its closest point (small), the listing's workers (list 1.5 -> 1.1; the vertices are
  few and clustered, so chunks of 32 taken in turn). Pairs sideways of the triangle by more than the two can close
  in a tick weren't pruned (a fast glove's reach is cm). Not tried: a coarser forearm cut.
- **Itself, `--solver=self_thickness:0.002`:** every start now rests (7.1-7.6 s, last speed <= 2 mm/s, nothing flung,
  pop 1.8 mm, stretch 1.08/1.05), **MetaHuman seed 2 too** (it never rested before the finer skin; cause not found,
  it just stopped). So the rule for turning it on holds; the cost doesn't: ms a tick here drawn/lying/tossed
  14.7-16.3 / 6.5-7.3 / 10.5-11.1 (without itself ~5.8-6.6 / ~1 / ~1), ~+6 ms drawn at Sean's. Off.
- **Where itself's cost is:** ~19.6 lists a tick, each 0.4 ms (hash build 0.11, the lookup of 371 points 0.3: reach
  up to 3 cm when fast, 6400 cells, ~1000 pairs); the meet each substep is small. Listing every 3rd/6th as long
  (`group` x3, x6): 15.4 -> 14.0 -> 12.9 drawn, still rests, flung 0: not enough alone. Tried and dropped: a bounding-
  sphere test before the closest point (no change), the lookup over workers (slower: 20 spawns a tick for 0.3 ms).
  Next for it: per-point lists (only the fast points relisted often: one fast point sets the interval for all 371),
  a pair room like the skin's, then Provot 1997's cones.

## His fingers in the glove, on (#1008 continued, `results/2026-11-16-fingers-on/`)

On in the game (`GarmentHandoff.FINE_TRIS` 3000), his forearm too (Sean: "some clipping at the forearm").
[`draw_before_after.jpg`](results/2026-11-16-fingers-on/draw_before_after.jpg): seed 1, the hands
camera, 2.6-4.0 s, top main (his fingers through it from 3.0 s, his forearm 3.4-4.0), bottom on.

- **The forearm:** SkinCollider's finer skin takes `forearm*` bones too (`FINE_FOREARM`; 1091 -> 1459
  vertices on the MetaHuman). Its count (`arm_out`, new): 119-121 -> 65-67 at worst.
- **The pop (8.1 -> 1.8 mm):** each vertex is let be as far in front of the cloth as it was worn
  (`sk_slack`), easing to 0 at 15 mm/s. The slack must come from the triangles *beside* it too (2 mm):
  over only, a vertex at a ridge between two triangles had none, and was pushed full depth the moment
  the cloth slid over it (why #1012's attempt failed).
- **The stretch (1.10 -> 1.08):** the 6 mm "still in the glove" reach (was 15) fixed it. Running the
  strain limit again after the pushes fixed the stretch too, but pulled the cloth into his arm (deep
  points 1 -> 15-40) and flung 31 points on sean_s3_talking; capping each push by its edges let his
  skin out. Both dropped.
- **Tossed (+15-25 ms -> +0.2):** `skin_out()` at `let_go`: nothing "still in the glove" once it's left
  his hand.
- **The cost:** listing from a hash of the free triangles only (held ones mark cells), and the 6 mm
  reach. Meeting every 2nd substep saved ~0.4 ms and let more out: not kept.

| bench, `--fine-tris` | pop mm | stretch | skin out worst / summed | forearm out | deep >1 cm | solver ms drawn (here) |
|---|---|---|---|---|---|---|
| MetaHuman s1-3, main (0) | 1.31 | 1.058 | 1473-1596 / 84-97k | 119-121 | 17-18 | 2.35 |
| MetaHuman s1-3, #1012 (3000) | 8.06 | 1.10-1.12 | 389-647 / 14-36k | 134-143 | 18-23 | ~10 |
| MetaHuman s1-3, now (3000) | 1.83 | 1.08 | 576-634 / 15-16k | 65-67 | 10-14 | 6.0-6.4 |
| sean_s3_talking s1-2, main | 1.53 | 1.087 | 1580-2161 / 123-144k | 123-126 | 7-16 | 1.8-1.9 |
| sean_s3_talking s1-2, now | 1.53 | 1.05 | 1669-1723 / 59-67k | 72-74 | 0-1 | 5.1-6.9 |

Flung 0, all rest. The finer skin's own share while drawn: ~3.5 ms here (list ~1.2, meet ~2.3), ~2.3
at Sean's (x0.65): the glove ~3.9 ms there while drawn, over Sean's ~2-3 ms. Tossed ~0.6 ms there, 0
worn and at rest. test_garment_handoff: under 6, deep 1, stretch 1.062, pop 1.92 (main 10, 1, 1.104, 1.35).

## His fingers in the glove (#1008, `results/2026-11-16-fingers/`)

Sean (2026-11-16, #997's film): "the left hand is clipping through the glove as it's pulled off". Our
cloth only kept the glove's POINTS off his skin, and his skin as the collider was the glove's own points
pulled back (~5 round a finger): his finer, rounder fingers poked out between the points through the
~1 cm triangles, and once the glove slid, his uncovered skin showed through it (the worn glove already
cuts his finer skin in 285 hand vertices; hidden while worn).

- **The fix, in ClothCore (`body_verts`):** his hand's own skin vertices (a 3000-triangle cut of his
  Skin_whole, `WornGarment.fine`; 1091 on the MetaHuman's hand) kept 0.5 mm behind the cloth's
  triangles (Bridson et al. 2002's point-triangle the other way), pushed out by their weights, no
  bounce. A vertex still in the glove (it began in it and some of it has stayed near) is pushed back from
  up to 15 mm out; one out of it only from 2 mm (a bare finger over the glove can't be told from one
  through it) or when it crossed in the substep. Its skin is posed by SkinCollider with the rest.
- **Before and after** (`bench.gd --shots`, the hands camera, seed 1; top main, bottom
  `--fine-tris=3000`): [`draw_before_after.jpg`](results/2026-11-16-fingers/draw_before_after.jpg)
  (3.0-4.0 s: his fingers through the glove's back before, none after but two wrist specks at 3.4 s),
  [`late_before_after.jpg`](results/2026-11-16-fingers/late_before_after.jpg) (4.2-5.4 s: it clings to
  his hand ~0.2 s longer, then comes off cleanly).
- **The count** (`skin_out`: his hand's covered skin vertices >1 mm in front of the nearest cloth
  triangle facing his skin's way, within 15 mm; the worn glove's floor 285), worst in the draw / summed:

  | MetaHuman | main | `--fine-tris=3000` |
  |---|---|---|
  | seed 1 | 1478 / 97k | 389 / 13.8k |
  | seed 2 | 1596 / 84k | 581 / 32.8k |
  | seed 3 | 1473 / 86k | 613 / 33.4k |

  All rest, flung 0. **Why it's off in the game (`GarmentHandoff.FINE_TRIS` 0):** the pop at the take
  1.3 -> 8.1 mm (test limit 3: hand vertices out of the worn glove's shape pushed at once), stretch 1.06 ->
  1.10 (the pushes come after the strain limit), and its cost here: listing 3.4-5.3 ms and meeting
  5.6-11 ms a tick while drawn (~6-10 ms at Sean's), on sean_s3_talking 25 ms more as it's tossed (a
  vertex "still in the glove" while the tossed glove passes his hand). An attempt to let each vertex be
  as far out as it was worn (no pop) doubled the pushes and the pop: reverted, cause unknown.

## Itself (#997, `results/2026-11-16-self/`)

Our cloth can meet itself (`self_thickness`; ClothCore, LAYOUT "src/bodies"), and the glove was filmed
with it on (`films_metahuman.txt`: `gh_dress self_thickness:0.002`). **Off in GarmentHandoff for now**
(see below); the lab turns it on with `--solver=self_thickness:0.002` (bench) or `gh_dress NAME:VALUE`.

- **The film, on the MetaHuman** (lavapipe, `--real`, 960x540):
  [`metahuman_hands.mp4`](results/2026-11-16-self/metahuman_hands.mp4),
  [`metahuman_draw_half_speed.mp4`](results/2026-11-16-self/metahuman_draw_half_speed.mp4) (the bunch
  in his hand) and [`metahuman_wide.mp4`](results/2026-11-16-self/metahuman_wide.mp4) (the landing). The
  glove gathers in his right hand as it comes off and lies crumpled by the chair, 8.7 cm high (4.4 without
  itself: flat through itself). Flung 0, stretch 1.09, at rest 8.1 s.
- **Where the under-skin points are** (the bench's count, `through_worst`): at the draw's worst (2.97 s)
  most are on his **upper arm, under the cuff** (25 of 48-63, 2-28 mm deep), then his forearm's twist
  (6-9) and hand (5-8). The worn glove alone counts 11 (the count's floor). With itself on: 63 -> 49-56,
  over 5 mm 43 -> 26-37.
- **The cost** (`bench.gd`, ms a tick, this workspace / Sean's at ×0.65; the solver's own step):

  | Phase | main (#986), skin | now, skin | now, skin + itself |
  |---|---|---|---|
  | drawn off | 2.61 / 1.70 | 2.40 / 1.56 | 11.15 / 7.2 |
  | tossed | 0.61 / 0.40 | 0.72 / 0.47 | 10.46 / 6.8 |
  | settling | 0.58 / 0.38 | 0.61 / 0.39 | 6.53 / 4.2 |

  Skin: cheaper floors (a face's plane, then its sphere; a far point skipped till it could be near) cut
  his skin's exact tests 5× (the sleeve bench: 3.8 -> 2.8 ms). Itself: its lists. A bunched glove is
  dense (100-200 of its triangles near each point's cell), its points move fast against each other while
  it's drawn and tumbling, so it's listed ~19 times a tick (~15-24k pairs). Not tried: a hierarchy with
  normal cones (Provot 1997), threads.
- **Why off:** across starts (`--seed`), sean_s3_talking's four all rest (7.3-7.6 s, nothing flung), the
  MetaHuman's seeds 1 and 3 rest, **seed 2 never does** (4.9 cm/s after 16 s). Fixed on the way: a pile
  buzzing forever (layers slower than 2 cm/s against each other now stick) and a tossed glove yanked
  through him (a point counts as through its own triangle only if it was near its inside a substep
  before). Two fixes for that fault: the third is the next session's.

## On our own cloth (#986, `results/2026-11-15-ours/`)

The part now takes the glove off on our own cloth (`SolverCloth`, the native plugin's `ClothCore`), which
meets his posed skin itself: each point kept 0.7 mm off his skin's front, a pull into him put back where it
met him with its slide along him kept, pinches between his pressed fingers left to the cloth.

- **The film, on the MetaHuman** (made in the workspace under lavapipe, `films_metahuman.txt`):
  [`metahuman_hands.mp4`](results/2026-11-15-ours/metahuman_hands.mp4) (real time) and
  [`metahuman_draw_half_speed.mp4`](results/2026-11-15-ours/metahuman_draw_half_speed.mp4) (the draw).
  His right hand takes the fingertips and the glove slides off over his hand into it; his left hand comes
  out bare. (Wrong, #1008: his left fingers show through the glove's back for ~half a second as it's
  drawn, the same in #997's film; see "His fingers in the glove".) For a few frames as it leaves,
  specks of his forearm's skin aren't drawn yet (`uncover`, a third of the points a tick: the vest shows
  through), gone within 0.2 s. Flung 0, below the floor 0, pop 1.4 mm, worst stretch 1.09, at rest 7.1 s.
- **By the count** (`under_skin`, worst in the draw, six seeds of his idle): on the MetaHuman 13-14 points
  >2 mm under his skin and 1-3 deeper than 1 cm every seed (Jolt's glove counted 8 and 1, yet went
  through his hand to the eye); on sean_s3_talking chaotic, 11-50 and 3-16 (his sleeve's modelled folds;
  his denser real skin as the collider, `under_tris` 3000, no better). Where the 13-14 are is the next
  question (step 3).
- **The cost:** ~2 ms a tick on this workspace while it's drawn off (~1.3 at Sean's), the solver with his
  skin; over the brief's 0.5. Checking his skin every 2nd substep, or a band under 1 cm, made points stick
  on his fingers.

## The clipping fixed (#949, `results/2026-11-14b/`)

Sean, 2026-11-14, on #917's film: "The gloves still need a lot of work, lots of clipping".

- **The film:** [`results/2026-11-14b/glove_clipping.mp4`](results/2026-11-14b/glove_clipping.mp4)
  (hands, wide, chair, then the draw at half speed; `films.txt`, on `sean_s3_talking`), and
  [`before_after.mp4`](results/2026-11-14b/before_after.mp4) (the hands angle, left #917's, right now).
- **His skin through the worn glove** (the white patches): his skin under it isn't drawn while it's
  worn (a copy of his Skin_whole without the 5,132 covered triangles, swapped in at `wear`). Drawn
  off, his covered skin is shown only where the cloth has left it (moved 18 mm off its worn spot,
  and no cloth two edges round it within 18 mm), as a small mesh of its own whose index buffer
  alone is replaced (0.16 ms a reveal; `add_surface_from_arrays` took 0.85).
- **The cloth into his arm while it's drawn:** the held points were carried rigid on one bone
  each, 7.5 mm off his skinned skin at the elbow and wrist (into it: the glove stands 2-4 mm off).
  Carried by his skinning now (every 2nd tick): pop 1.6 -> 0.5 mm, under his skin more than 2 mm
  26 -> 15-20 over three runs (`--seed`), 1-3 deeper than 1 cm. The glove's flat triangles still
  dip between its points into his finer skin: drawn 4 mm proud of its points (`grow`).
- **Tried, not kept:** a denser skin shape (1,400 triangles from a less simplified copy of his skin:
  8-14 under, but +0.25 ms a tick; 2,000-2,500 no better; `--under-tris=N`); the shape rebuilt every
  tick, all of it (no better); precision 24-30 (no better); the worn glove pushed out by `relief`
  (worn under 4 -> 7: the coarse glove's normals push points sideways at his sleeve's folds);
  pressure (the glove is open at the cuff: its volume means nothing, it balloons).
- **The measure:** under the nearest point on his skin's triangles, by his smooth normal there (the
  nearest vertex's normal agreed within a point: it wasn't what rose when the glove was pushed out).
- **Bunched through itself:** Godot's soft body has no bending stiffness (stiffness is already 1.0),
  so once let go it's damped harder (0.5, was 0.06): it keeps a hand's shape instead of a knot of
  fingers through each other. Its inside is drawn, a dark brown lining (a tan one read as holes onto
  the seat's wood).
- **The toss is a flick from the wrist** (GloveAct, now in `src/bodies/`): a wind-up back, out and
  up, let go with a little more than his hand's speed toward the chair; it lands where it lands
  (on the seat, over its back or on the floor).
- **On the MetaHuman, the clipping Sean saw is still there** ([`metahuman_hands.mp4`](results/2026-11-14b/metahuman_hands.mp4),
  `metahuman_draw.jpg`, `films_metahuman.txt`): as it's drawn off, the glove's wrist and forearm go
  straight through his hand. The glove's wrist is narrower than his hand and Jolt's cloth can't stretch
  over it, so the collision gives. Sean, 2026-11-15: "it's still clipping as much as before", "we should
  only be using the metahuman model", and our own cloth solver for this, jackets and leggings:
  `docs/briefs/garment-cloth.md`. The bench and the bridge now default to the MetaHuman.
- **Still seen:** at the draw's end, where the glove has gathered over his hand, his fingers show
  through it in places (the cloth over them came from further up his arm, which the reveal rule
  doesn't look for); a brief patch on the forearm as the cloth first slides.
- **On the MetaHuman** (`measure_metahuman.json`, his files copied in for the run, never committed):
  12 points under his skin more than 2 mm, none deeper than 1 cm, pop 0.6 mm.
- **The cost** (`cost.md`, x0.65; this workspace runs slower than #917's: main measured here
  draw +0.62, take +0.78): take +0.58, draw +0.64, flick +0.34, falling +0.20 (longer: at rest
  ~9.7 s from the cue, damped), worn and at rest 0. GarmentHandoff's own share of a held tick
  ~0.40 (main 0.30).

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

Bench flags: `--seed=N` (his idle's noise: another run of the same handoff), `--under-tris=N` (the
skin shape from a denser copy of his skin), `--by-vertex` (#917's measure), `--cam=seat|toss` (the
chair close, the flick); `--no-take` stops after the reach; `--hide-glove` hides the worn glove; `--all-skin`
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
