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
