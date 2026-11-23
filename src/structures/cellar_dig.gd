extends RefCounted
## A building's cellar dug into the valley's ground (#1174, the undertaker's: the first cellar a man
## walks down into; the store's and saloon B's wait on #695): where a spec's `cellar` has `dig`, the
## ground under its rect (inside its walls' stone, so the cut's edge is hidden in them) and under its
## bulkhead's areaway is lowered to the cellar's floor, in the Ground's own dug tiles (GroundTile:
## 5 cm points, its own height field and mesh, saved as any dug ground is). Each point is set to the
## floor's height outright, so digging again (a load over a save) changes nothing.
##
##   CellarDig.dig(ground, building, spec)   # after the building is placed

## How far inside a wall's outer face the cut is made (m): its edge's 5 cm slope in the stone.
const INSET := 0.1


static func rects(spec: Dictionary) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var c: Dictionary = spec.get("cellar", {})
	if c.is_empty() or not c.get("dig", false):
		return out
	var r: Array = c.rect
	var t := float(spec.frame.foundation.thick)
	# (its front wall stands half on each side of its line: the cut reaches into it)
	out.append(Rect2(float(r[0]) + INSET, float(r[1]) - t * 0.5 + INSET, float(r[2]) - float(r[0]) - INSET * 2.0, float(r[3]) - float(r[1]) + t * 0.5 - INSET * 2.0))
	var bk: Dictionary = spec.get("bulkhead", {})
	if not bk.is_empty():
		# The areaway against the yard wall (x 0, out -x): to the end wall's outer face, between the
		# cheeks' outer faces, the cut inside their stone; into the foundation under the passage.
		var ch := float(bk.get("cheek", 0.3))
		var x0 := -float(bk.out) - ch + INSET
		var z0 := float(bk.z[0]) - ch + INSET
		out.append(Rect2(x0, z0, INSET * 2.0 - x0 + t * 0.5, float(bk.z[1]) + ch - INSET - z0))
	return out


## Lower the ground under `building`'s cellar (its spec's) to its floor. Returns the tiles touched.
static func dig(ground: Ground, building: Node3D, spec: Dictionary) -> int:
	var rs := rects(spec)
	if rs.is_empty() or ground == null:
		return 0
	var floor_y: float = (building.global_transform * Vector3(0.0, float(spec.levels.cellar.floor), 0.0)).y
	var inv := building.global_transform.affine_inverse()
	# The world's tiles over the rects' corners.
	var keys := {}
	for r in rs:
		for corner: Vector2 in [r.position, r.end, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y)]:
			var w: Vector3 = building.global_transform * Vector3(corner.x, 0.0, corner.y)
			keys[ground.key_at(w.x, w.z)] = true
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := Vector2i(-(1 << 30), -(1 << 30))
	for k: Vector2i in keys:
		lo = Vector2i(mini(lo.x, k.x), mini(lo.y, k.y))
		hi = Vector2i(maxi(hi.x, k.x), maxi(hi.y, k.y))
	var touched := 0
	for kz in range(lo.y, hi.y + 1):
		for kx in range(lo.x, hi.x + 1):
			var t: GroundTile = null
			var n := ground.tuning.tile_cells + 1
			var size := ground.tuning.tile_size()
			var changed := false
			for j in n:
				for i in n:
					var wx := kx * size + i * ground.tuning.cell
					var wz := kz * size + j * ground.tuning.cell
					var p: Vector3 = inv * Vector3(wx, 0.0, wz)
					var inside := false
					for r in rs:
						if r.has_point(Vector2(p.x, p.z)):
							inside = true
							break
					if not inside:
						continue
					if t == null:
						t = ground.dug_tile(Vector2i(kx, kz))
					var k := t.index(i, j)
					var base := t.base[k] if not t.base.is_empty() else 0.0
					var want := floor_y - base
					if absf(t.heights[k] - want) > 0.001:
						t.heights[k] = want
						t.loose[k] = 0.0
						changed = true
			if t != null and changed:
				t.rebuild(ground.material)
				touched += 1
	return touched
