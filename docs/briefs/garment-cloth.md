# Garment cloth: our own cloth solver for things people wear and take off

Issue #949's end, 2026-11-15. Lane: gameplay (with characters for the garments' models later).

**DECIDED** (Sean, 2026-11-15, on #949's MetaHuman film): "I want the cloth solver because we're going to do
jacket, and leggings"; and "we should only be using the metahuman model". Everything else here is PROPOSED.

## On one screen (for the phone)

- **Why:** Godot's soft body (Jolt) can't take a glove off a hand. The glove's wrist is narrower than his hand
  and the leather can't give, so when it's pulled off it goes *through* his hand (`#949`'s MetaHuman film,
  `experiments/garment_handoff/results/2026-11-14b/`). It also has no bending stiffness, and cloth never meets
  itself. Jackets and leggings would have the same faults, worse.
- **What:** a cloth solver of our own for garments (glove, stocking and leggings, jacket, shirt bandage). It
  works on positions: stretch limits, bending, pins and attachments, friction. It collides with the wearer's
  own skin, posed as drawn, with a thickness, and with itself.
- **Where:** in the native plugin (Rust, `addons/saltcreek_native/`, a `ClothCore` beside `FireCore`), since
  GDScript is ~50x too slow for this. The Jolt `GarmentCloth` stays as the fallback where the plugin isn't
  (web).
- **On whom:** the MetaHuman (`sean_metahuman_s3`), his files copied in for each run and never committed
  (#692). CI's tests use a Studio man, because the MetaHuman's files can't be in this public repository.
- **Judged by:** the film on the MetaHuman (three angles plus the draw at half speed), with **nothing through
  him and nothing through itself** to the eye; counted by the solver's own checks; costing at most 0.5 ms a
  garment while it simulates at Sean's, and 0 worn or at rest.
- **Built in about 6 one-session steps** (below). Step 1 needs crates.io reachable from the cloud workspace;
  it isn't now.

## What exists (#917, #949)

- `WornGarment` makes a garment from his own Skin_whole and wears it, skinned, at no cost. While it's worn his
  skin under it isn't drawn; as it comes off, his skin is shown where the cloth has left it (`cover_skin`,
  `uncover`). Keep all of that.
- `GarmentHandoff` holds the release rule (friction giving way, front by front, by the free cloth's
  stretch), the held points carried by his skinning, and the bake to a plain mesh at rest. It swaps a
  `GarmentCloth` (a Jolt `SoftBody3D`) in at the take. **The solver replaces only that cloth**, behind the
  same few calls (`pin_to`, `hold_on`, `move_held`, `release`, `let_go`, `points_now`, `came_to_rest`).
- `SkinCollider` (his skin as a Jolt concave shape) goes, because the solver meets his skin itself.
- `GloveAct` is the choreography (bridge `glove MAN [toss_to X Y Z]`). The lab's bench and film:
  `experiments/garment_handoff/` (README), now on the MetaHuman by default.

## The solver (PROPOSED)

- **Positions, small steps.** XPBD (Macklin, Müller, Chentanez 2016, "XPBD: position-based simulation of
  compliant constrained dynamics") on the garment's own points: substeps (Macklin et al. 2019, "Small steps
  in physics simulation"), not many iterations.
- **Stretch:** distance constraints on the edges, and a strain limit (Provot 1995) so leather gives a little
  but no more. Long-range attachments (Kim, Chentanez, Müller 2012, "Long range attachments") hold a sleeve
  from its pins without it stretching like rubber.
- **Bending:** isometric bending (Bergou et al. 2006), or dihedral bending, per garment (kid leather stiffer,
  wool softer). This is what the glove lacked: it knotted.
- **His body:** his skin posed as drawn (CPU-skinned, only the triangles near the cloth) in a spatial hash.
  Each point is kept a thickness off the nearest triangle, on the side it came from (tracked, so a fast pull
  can't flip it through), with friction. For the hand, the issue is width: with strain limits and friction
  the glove's wrist must *stretch over* the knuckles or the hand must narrow (GloveAct: fingers together,
  thumb in). The solver must never resolve it by going through.
- **Itself:** point-triangle and edge-edge contacts by a spatial hash (Teschner et al. 2003, "Optimized
  spatial hashing for collision detection of deformable objects"; Bridson, Fedkiw, Anderson 2002, "Robust
  treatment of collisions, contact and friction for cloth animation"), with a thickness, so a bunched glove
  or a jacket's folds lie on each other.
- **The world:** the floor and props by the physics server's ray and shape queries (or the sight service's
  BVH, `SightWorld`), only near the cloth.
- **Determinism:** seeded, fixed step, the same input giving the same output (the fire's rule).
- **Cost:** threads by garment (the plugin's `pool.rs`). At rest the garment is baked, exactly as now.
- **Ideas only, from the papers above:** no code copied from other engines or repos (CLAUDE.md).

## The steps (one session each, PROPOSED)

1. **The core** (`ClothCore` in the plugin): points, edges, XPBD stretch with a strain limit, bending, pins,
   damping, a floor plane. Tests in Rust (`cargo test`) and GDScript (a sheet hangs, a pinned sleeve keeps
   its length, the same seed gives the same result). A sheet dropped on the floor beside the Jolt rag, filmed.
2. **His body:** his posed skin as the collider, with thickness, side tracking and friction. The glove drawn
   off the MetaHuman (GarmentHandoff on the new cloth, the Jolt one the fallback). Judged by the film, the
   hand above all. **Done (#986):** his skin met on its front (`body_front_only`; tracked sides for a
   two-sided body), crossings within a substep put back with their slide along him, pinches between his
   pressed fingers left to the cloth, no bounce. By the count, on the MetaHuman 13-14 points >2 mm under his
   skin at worst (Jolt's 8, but Jolt's went through his hand to the eye), 1-3 deeper than 1 cm; on
   sean_s3_talking chaotic (11-50). **Over budget:** ~1.3 ms a tick at Sean's while it's drawn off; checking
   every 2nd substep or a band under 1 cm made points stick on his fingers. The film and its findings:
   #986.
3. **Itself:** self-contacts; the glove bunched in his hand and dropped, lying on itself. **Done (#997):**
   point-triangle by a hash of its own triangles listed every few substeps (reach: each point's move
   against the cloth's mean), a thickness (the glove 2 mm), the side at the substep's start, no bounce,
   friction, sticking under 2 cm/s; a folded sheet and a squashed tube stay two layers (cargo tests).
   **Off in GarmentHandoff for now:** one MetaHuman start in seven (`--seed=2`) never came to rest
   (4.9 cm/s after 16 s; sean_s3_talking's four all rest). On the MetaHuman it lies
   on itself (6-9 cm high where it lands, 4.4 without), fewer points under his skin at the draw's worst
   (63 to 49-56; most on his upper arm under the cuff). **The cost:** ~7.2 ms a tick at Sean's while drawn
   (skin 1.6 of it, down from 1.7 by cheaper floors), ~6.8 tossed, ~4.2 settling: the lists (a
   bunched glove is dense: 100-200 triangles near each point's cell, ~19 lists a tick). Tried, not
   kept: meeting itself every 4th substep (a pile tangled), a fixed 5-substep list (missed contacts),
   a wider catch for crossings (fast points yanked: the glove flew). Fixed on the way: a pile that
   buzzed forever (sticking), a tossed glove yanked through him (a crossing only if it was near then).
4. **His fingers, the rest and the cost.** **His fingers ON (#1008, part 1b):** his forearm too, the
   pop 1.8 mm (each vertex let be where it was worn, easing in), stretch 1.08, tossed ~0.6 ms; ~2.3 ms a
   tick at Sean's while drawn (the glove ~3.9 there); experiments/garment_handoff/README.md
   "His fingers in the glove, on". **Before it (part 1, off then):** his hand's own
   skin vertices (a 3000-triangle cut, 1091 on the MetaHuman's hand) kept behind the glove's triangles
   (`body_verts`); his fingers no longer show through as it's drawn (crops on #1008), the count 1478 ->
   389-613 at worst; but the take pops 8 mm, stretch 1.10, and it costs ~6-10 ms a tick more at Sean's
   while drawn (25 ms tossed on sean_s3_talking): `GarmentHandoff.FINE_TRIS` 0 until those are fixed.
   Then the rest with itself on and the cost below.
   **The world and the cost:** floor and props; at rest baked; the cost table on the MetaHuman, ≤ 0.5 ms
   while it simulates (with itself, ~+4.5 at Sean's drawn after #1029's lists by how far each point goes, from ~7.2;
   next: a frame per part of the glove, the whole listings over the worker pool, Provot 1997's cones). Merge.
5. **Leggings / a stocking:** `WornGarment` for the leg's bones; rolled or drawn down over the foot.
6. **A jacket:** two sleeves and the shoulders, put on and taken off; layered over a shirt (two garments
   meeting each other).

## Traps

- crates.io isn't reachable from the cloud workspace today, so no native build there: step 1 has to propose
  the environment change (the hosts `index.crates.io` and `static.crates.io`) when its build is blocked. CI
  builds the plugin either way.
- The MetaHuman's files never go in the repo (`.git/info/exclude`); the tests run on `sean_s3_talking`.
- `reach_to` must be renewed every tick (GloveAct does).
- Keep the Jolt `GarmentCloth` working as the fallback; a garment must never need the plugin to exist.
