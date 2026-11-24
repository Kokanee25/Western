# A building's members as bodies: what they cost (#1227, 2026-11-24)

#1227 was to merge each building's members into compound bodies, so the hotel (#1220, PR #1224;
12.4k members) could go on its lot without slowing every valley test. Step 1 measured first.
**The members' physics bodies are about 1% of the cost.** Merging them would save ~0.4 s of a
valley's load and ~45 MB, with a resolver needed in ~30 files that read a hit's `collider`.

All runs are on this workspace's 4 cores at 2.1 GHz, headless. "Main" is 6df1d0ef. "Hotel" is
PR #1224 before it came off its lot (ce3f6590^, the hotel placed, `max_bodies` 131,072).

## The valley

| | Main | Hotel placed |
|---|---|---|
| Collision bodies after load | 50,865 (50,262 static) | 63,386 (hotel 12,454 + 160 kit) |
| Valley scene load | 28.2 s (buildings 20.5) | 34.5–35.8 s (buildings 27.5–28.1) |
| Peak RSS, load only | 5,579 MB | 6,635 MB |
| Day street, frame avg / p99 | 9.55 / 27.8 ms | 8.93 / 19.8 ms (noise: no slower) |
| `test_town_barks_valley` (two run side by side) | 1,100 s, 5,611 MB | 1,083 s, 6,786 MB |

The hotel makes no frame or test step slower here. What it adds is **~7 s of load** and **~1.1 GB**
per valley. The suite loads a valley ~167 times (33 test files load one in `before_each`), so
~7 s × 167 ≈ 20 min of CI here, more on CI's runners. That is the shards' slowdown.

## Where a building's load and memory go

The hotel alone (`SpecBuilding`, the spec on its own, 120 ticks after): 12,419 members, **6.5–7 s**,
**846 MB** of Godot's static memory (~70 KB a member).

Load, the whole valley (`Structure.rebuild`'s phases summed, 586 structures, 61,397 members):

| Phase | Valley | Hotel |
|---|---|---|
| `build()`: members, their nodes and meshes | 20.1 s | 3.3 s |
| `infer_supports()`: the support graph | 7.3 s | 1.9 s |
| `_batch_all()`: the drawn batches | 6.1 s | 1.4 s |
| `BuildingAge` | 0.1 s | 0.0 s |
| Bodies entering the world (micro-test: 12k StaticBody3D into the tree) | ~0.4 s | 0.07 s |

Memory a member (micro-tests, `OS.get_static_memory_usage`):

| Thing | KB |
|---|---|
| A library board's mesh (`PropKit.board_mesh`; 12,062 of the hotel's 12,419 are unique) | **26.5** |
| A `StructureMember` (its script's vars, arrays and dictionaries) | 6.2 |
| A `StaticBody3D` + `CollisionShape3D` node pair | 5.0 |
| Its Jolt body in the space | 0.7 |
| A shape in a compound body instead | 0.2 |

Taking every hotel member's body out of the space freed ~1 MB (Jolt keeps bodies in a pool sized by
`max_bodies`: ~4 MB a 32k, the valley review's figure).

## A compound's own costs (for whoever builds one later)

- Adding shapes to a body one at a time in the space rebuilds Jolt's compound each time: 12,000
  shapes took ~15 s (quadratic). Build it whole.
- Disabling one shape of a 12,000-shape compound took ~6 ms (the compound rebuilt): keep each to a
  few hundred.
- Rays through 12,000 separate bodies 1.6 µs, through one compound 0.2 µs: queries would gain, but
  the day's frame shows no query cost from the hotel.

## What would cut the load and the memory

1. **The support graph** (`infer_supports`, 7.3 s a valley): the same graph every load. Made faster
   (a sweep over sorted boxes, or the native plugin), or kept from the last load by the spec's hash.
   It's gameplay's code and it's checkable: the graph must come out identical.
2. **The board meshes** (26 KB each, ~60% of a member): one mesh per board, its warp, nails and
   grain in its vertices. Shared meshes by size, with the variation in the shader, would cut most of
   it. That's art's look (`PropKit.board_mesh`, `scan_wood.gdshader`).
3. **The tests' valleys:** 167 loads a full run. A file whose tests can share one valley loading
   it once (`before_all`) would save more CI than either of the above. That's a change to what each
   test is sure of, file by file.
