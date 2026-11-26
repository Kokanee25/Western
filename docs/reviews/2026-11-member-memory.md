# What a building's member costs in memory (#1259, 2026-11-25)

Sean: "the buildings are taking too much memory." Every board stays a member that breaks, and every
building stays enterable (Sean on #1259). Only how members are stored and drawn may change.
`tools/member_memory.gd` builds one spec on its own and measures it in two ways:

- by phase, as `Structure.rebuild` adds each part;
- by part, taking the finished building apart one part at a time, so the parts add up to the whole.

The numbers are Godot's static memory, headless, on this workspace's cores. One caveat matters: headless,
the rendering server is the dummy one, and it keeps each mesh's arrays in RAM. A real GPU keeps them
in video memory instead. So the "batch + shadow meshes" row would be VRAM on Sean's PC, not RAM.

## The hotel alone (15,669 members), KB a member by part

Before is main e156850a. After is this branch. In the before column, "member meshes" includes the
`Structure._mesh_arrays` cache, which held each mesh and its arrays.

| Part | Before MB | KB a member | After MB | KB a member |
|---|---|---|---|---|
| batch arrays, the CPU copy the shadow is remade from | 61.6 | 4.02 | 1.6 | 0.10 |
| batch + shadow meshes (rendering server; VRAM on a GPU) | 179.6 | 11.74 | 179.6 | 11.74 |
| batch nodes and lists | 1.8 | 0.12 | 1.8 | 0.12 |
| support graph (supported_by, dependents, points, boxes, touching, caches) | 39.7 | 2.59 | 39.7 | 2.59 |
| member meshes and their kept arrays | 174.4 | 11.40 | 44.5 | 2.91 |
| member shapes | 11.5 | 0.75 | 11.5 | 0.75 |
| MeshInstance3D nodes (kept aside at rest) | 40.5 | 2.65 | 43.2 | 2.82 |
| CollisionShape3D nodes (kept aside at rest) | 24.7 | 1.62 | 24.7 | 1.62 |
| bodies in the space (Jolt) | 2.1 | 0.14 | 2.1 | 0.14 |
| StructureMember nodes (StaticBody3D 2.2 KB, the script ~4 KB, names, metas, signals) | 138.7 | 9.07 | 138.7 | 9.07 |
| other children (lamps, kit props, dressing) | 10.7 | 0.70 | 10.8 | 0.70 |
| the structure node itself (freed with it, engine side: not its script's data) | 52.3 | 3.42 | 52.3 | 3.42 |
| mesh caches (MemberMesh, PropKit) | 7.4 | 0.49 | 7.4 | 0.49 |
| rest (statics, materials) | 20.5 | 1.34 | 20.8 | 1.36 |
| **whole** | **766** | **50.0** | **579** | **37.8** |

The hotel's peak RSS alone went from 1,316 to 1,122 MB.

By phase, before → after:

- `build()`: 465 → 347 MB.
- `infer_supports()`: 43 → 43 MB.
- `_batch_all()`: 255 → 186 MB.

There are 279 batches with 1,645,282 vertices, before and after: the drawn geometry is unchanged.

There were 5,365 distinct member meshes, and 4,131 of them were strips, one each. A strip member is a
wall's or ceiling's member drawn as several 9 cm boards (#826). Each held about 150 vertices and their
arrays, ~30 KB a mesh. After sharing, 1,472 distinct meshes remain.

## Saloon B alone (7,778 members)

103.3 → 93.9 KB a member.

Its members' own parts come to ~37 KB a member, the same as the hotel's. Most of the rest is not members:

- its dressing and kit props: 149 MB;
- what it loads once that the warm-up building doesn't: 277 MB (the piano, signs, backdrop textures).

## The valley with the hotel on its lot

To measure this, I put the hotel back on its lot (ce3f6590^'s `valley.json` line) and set
`max_bodies` to 131,072 in `override.cfg`, for these runs only. Then:
`perf_bench -- --world=valley --scene=load`, 64,514 members.

| | Before | After |
|---|---|---|
| Peak RSS on load | 5,090 MB | 4,571 MB |
| Static memory after load | 4,544 MB | 4,029 MB |
| Buildings' load | 23.7 s | 20.3 s |

## The cuts (each measured; what breaks and how is unchanged)

1. **Strips share a mesh a shape** (`PropKit.shared_strips`, as #1246 did for plain boards). Each
   member's strip seeds, warp, nails and ground are kept on its node. They are written into the batch
   float for float (`tests/test_shared_strips.gd`). Drawn on its own, a member gets its own mesh back
   (`own_board`).
2. **`Structure._mesh_arrays` removed.** The arrays are kept on each mesh from its making
   (`MemberMesh.arrays_of`). The static cache only kept up to 20,000 meshes alive after their members
   were gone.
3. **A board batch's shadow is merged from its members' arrays and places**
   (`Structure._shadow_source`), not from a kept copy of the batch's vertices.
   `tests/test_member_memory.gd` checks the vertices against the old way (worst 0.5 mm, counts equal).

## What's left to reach 15 KB a member and 4 GB (the next step)

1. **The batches' meshes (11.7 KB a member).** These are vertices copied once per member, from shapes
   that are now shared. The fix is to draw them instanced: a MultiMesh per (shape, material), or
   RenderingServer instances, with each member's seed, warp and nails as instance data. This is art's
   look, `scan_wood.gdshader`. On a GPU this memory is VRAM; headless it is RAM.
2. **A member as a node (StructureMember 9.1, its MeshInstance3D 2.8, CollisionShape3D 1.6 KB).**
   Members become packed data, with a node made only when one is hit, carved, burning or moved; the
   queries resolve a compound's shape to a member. This is gameplay's job, about 30 files that read a
   hit's `collider`.
3. **The structure node's 3.4 KB a member, freed with the node** (not script data). Not traced yet.
4. **The support graph (2.6 KB a member).** Packed arrays of indices instead of
   `Array[StringName]` and dictionaries. `tests/test_support_graph.gd` pins the graph.

## Step 2 (#1262), cut 1: boards drawn as instances

A building's boards and strips shared by shape are drawn as MultiMesh instances of one board a metre
each way per (segments, role) (`PropKit.unit_board`): each board's transform, (warp, nails, ground) as
its colour and (L, W, T, seed) as its custom data; `scan_wood.gdshader` scales the board and works
out its UV from them (a unit board's CUSTOM1.x is -1). A strips member is an instance a strip. Pieces
hold up to 512 members, near ones together. The far lamps' shadow of them is one MultiMesh of unit
boxes. Members drawn on their own (hit, cut, burning, moving) and the few boards with meshes of their
own batch as before. Kit props keep mesh batches (PropBatch joins them).

The hotel alone, this workspace, main 68e447f9 → this cut:

| Part | Before KB a member | After KB a member |
|---|---|---|
| batch + shadow meshes (VRAM on a GPU) | 11.74 | 0.29 |
| batch arrays, nodes and lists | 0.22 | 0.12 |
| every other part | unchanged | unchanged |
| **whole** | **37.8** | **26.1** |

- Batches: 280 → 117 (draw calls of its intact members); 15,130 members drawn as 17,520 instances.
- The hotel alone: peak RSS 1,122 → 890 MB.
- The valley with the hotel placed (this workspace, main as of #1265, so higher than step 1's
  numbers): peak RSS 5,685 → 5,173 MB, static 4,812 → 4,277 MB, the buildings' load 17.6 → 14.5 s.
- On a GPU the batches' meshes were video memory: ~180 MB for the hotel, ~0.5 GB for the valley's
  buildings, now ~2 MB and ~10 MB of instance data.
- The look: the hotel lobby rendered before and after under lavapipe. Side by side it's the same
  picture; 1.5% of pixels differ by more than 24/255, single pixels at board edges and at the paint
  chips' thresholds (each board now drawn on its own exact axes; the batch snapped them to 0.001).
- `tests/test_board_instances.gd`: every vertex, UV and channel the shader makes of the instances is
  the boards' own merge (worst under 0.02 mm), and a hit board leaves its instances and draws itself.

## Step 2, cut 2a: a resting member's nodes freed, kept as a row

At rest in its batch, a member whose mesh and shape nodes are plain (as built, its only piece, no
children or overlays, no other node wired to them) keeps what they were as data
(`StructureMember._rest_data`); its body keeps its shape, so it's hit and stood on as before.
`drawn_node`, `realise` and `take_parts` make the nodes again; the board instances read the row.
Kit props keep their nodes. `--keep-rest-nodes` turns it off.

| | After cut 1 | After cut 2a |
|---|---|---|
| Hotel: MeshInstance3D + CollisionShape3D nodes, KB a member | 4.44 | 0.03 |
| Hotel: the rows that stand for them | – | 0.74 |
| Hotel: member meshes and shapes (the nodes' share) | 3.53 | 2.31 |
| **Hotel, whole** | **26.1** | **21.3** |
| Valley + hotel, peak RSS | 5,173 MB | 4,820 MB |
| Valley + hotel, static | 4,277 MB | 3,961 MB |
| Valley: the buildings' load | 14.5 s | 16.2 s |

15,532 of the hotel's 15,669 members rest as rows. `tests/test_member_rest_rows.gd`: a row comes
back as the nodes it was (mesh, material, place, metas, shape, piece), is found by a ray, and goes loose.

## What's left (the hotel, 21.3 KB a member; the aim 15)

- **StructureMember nodes (9.1 KB):** the StaticBody3D (~2.2 KB) and its script's vars (~4 KB:
  ~60 vars, each a Variant slot, plus dictionaries and arrays made per member). Making a member a row
  in packed arrays with a node only when hit, carved, burning or moved is the next cut; ~30 files read
  a hit's collider as a StructureMember (`docs/reviews/2026-11-building-bodies.md`).
- **The structure node (3.4 KB a member, engine side):** untraced; it's freed with the node.
- **The support graph (2.6 KB):** packed indices instead of `Array[StringName]` and dictionaries.
- **Member meshes (1.9 KB):** the few own meshes (non-board members' boxes and warped beams).

## Step 3 (#1270), cut 1: what a member's script makes, cut

Measured on micro-tests (`OS.get_static_memory_usage`, 10,000 nodes in a tree): a StaticBody3D is ~2.5 KB;
**every declared script var is ~80 B a member, whatever its type** (10 vars 3.4 KB, 45 vars 6.2, 90 vars 9.8:
untyped, int and float the same); an empty Dictionary 0.15 KB, an empty Array 0.09; a meta on a node 0.6 KB
(its maps); two `connect(callable.bind(m))` 1.24 KB. On the hotel every member carried a `band` meta and two
bound `damaged` connections to its structure, and `analysis_cache`, `holes` and (at rest) `pieces` empty but
its own.

- `damaged`: the structure is called directly (`StructureMember._report_damage` → `Structure.member_damaged`:
  unbatch, mark dirty, settle), then the signal for whoever else listens (kit props, contents), in the same order.
- `band` a var (`StructureMember.band`, -1 outside a spec building), not a meta.
- Shared read-only empties for `analysis_cache` (`forget_analysis()`), `holes` and `pieces` at rest; what fills
  one gives the member its own first.
- The fire's four backing vars folded into `temperature`, `char_depth`, `burn_time`, `wet`'s own storage.

The hotel alone, main 4086f3d3 → cut 1 (this workspace, headless):

| Part | Before KB a member | After KB a member |
|---|---|---|
| StructureMember nodes (body, script) | 9.12 | 6.39 |
| finish textures (shared, loaded once; was "the structure", 3.42) | 3.42 | 3.42 |
| every other part | unchanged | unchanged |
| **whole** | **21.3** | **18.6** |

The hotel's peak RSS alone 892 → 840 MB. `kb_per_member_held` 23 → 20.

The valley with the hotel placed (as above), this session's workspace, which reads lower than step 2's (main
measured here: 3,681 MB peak, where step 2's workspace read 4,820):

| | Main 4086f3d3 | Cut 1 |
|---|---|---|
| Peak RSS on load | 3,681 MB | 3,470 MB |
| Static memory after load | 3,178 MB | 3,015 MB |

Under 4 GB here; on step 2's workspace it wasn't. Sean's PC (F3) is the measure that counts.

**"The structure node" was the hotel's finish textures.** Its seven library materials (`SpecBuilding._lib_mats`)
hold 2048² albedo, normal and roughness maps: 50 MB, loaded once and shared by every building with the same
finishes (the warm-up building uses other ones), and video memory on a GPU. They're not a member's; the tool
now names them.

## Step 3, a member as a row: measured, not built

What a resting member would cost as a row (micro-tests, 15,000):

| | KB a member |
|---|---|
| now: its node (6.39) + its Jolt body (0.14) + its kept nodes' row (0.74) | 7.27 |
| a row: id, transform, size, kind, wood, flags, band in packed arrays | 0.32 |
| its shape in a compound body of 300 (a StaticBody3D of its own: 3.26 with Jolt) | 0.44 |

That takes the hotel from 18.6 to about **12 KB a member**: the budget's 15 is reachable this way, and only
this way (every other part together is under 5 KB). What it needs (an audit of `src/`):

- **~26 files, ~55 sites take a hit's collider as a member**: ballistics, blast, bodies, brains, dents, rubble,
  feet. They need `Structure.member_at(collider, shape_index)` making the node on demand; `body_entered` gives no
  shape (`body_shape_entered` instead).
- **~10 sites look past a hit by excluding its RID** (ballistics through glass, the outlaw's, past stains, room
  light, Sight): excluding a compound would skip its whole cell. They need a per-shape skip.
- **Sight** registers a body at a time, one kind each, with a 64-bit mask of disabled shapes: a cell of glass
  and boards needs a kind a shape. A redesign, and it runs every frame.
- **~33 files, ~75 loops over all members**: the analysis (`get_member`, fields only, every analysis), the fire's
  grid (keyed by node), smoke, kit props; the rest at load or save. Fields only for most; a row API serves them.
- **Long-held references** (fire, smoke, kit props' feet, glass, fittings, dynamite, floor marks): a stable handle.
- **Metas on members** (`use_role`, `cut`, `dents`, `snapped`, ... ~60 sites): a sparse side table.
- Joining a compound: build each cell whole (adding one shape at a time rebuilds it: quadratic); taking a
  member out rebuilds its cell's compound (keep cells to a few hundred). Rays through the micro's compounds
  were 2× slower than through separate bodies (9.0 vs 4.2 ms a thousand), against the earlier review's 8× faster:
  measure on the real buildings first.

It's more than a day's work across ~60 files, with the shot and Sight paths changing, so it starts with a
brief (`docs/briefs/member-rows.md`, the next step) and is built in stages, each merged on green.

Not done this step: the support graph packed (2.6 KB a member; `support_points` and `support_boxes` are
dictionaries of ~8 entries each, most of it).
