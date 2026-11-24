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
		# The areaway against a side wall (the undertaker's yard wall at x 0, out -x; the hotel's lane
		# wall at the building's width, out +x, #1220): to the end wall's outer face, between the cheeks'
		# outer faces, the cut inside their stone; into the foundation under the passage.
		var ch := float(bk.get("cheek", 0.3))
		var z0 := float(bk.z[0]) - ch + INSET
		var zs := float(bk.z[1]) + ch - INSET - z0
		if _wall_x(spec, String(bk.wall)) > 0.01:
			var w := float(spec.lot.width)
			var xa := w - INSET * 2.0 - t * 0.5
			out.append(Rect2(xa, z0, w + float(bk.out) + ch - INSET - xa, zs))
		else:
			var x0 := -float(bk.out) - ch + INSET
			out.append(Rect2(x0, z0, INSET * 2.0 - x0 + t * 0.5, zs))
	return out


## The drift's trench (#1220): its timbers' rect, from the cellar's wall to the far cellar's.
static func drift_rect(spec: Dictionary) -> Rect2:
	var d: Dictionary = spec.get("drift", {})
	if d.is_empty():
		return Rect2()
	return Rect2(float(d.x[0]), float(d.z[0]), float(d.x[1]) - float(d.x[0]), float(d.z[1]) - float(d.z[0]))


static func _wall_x(spec: Dictionary, id: String) -> float:
	for w: Dictionary in spec.get("walls", []):
		if String(w.id) == id:
			return float(w.line[0][0])
	return 0.0


## Lower the ground under `building`'s cellar (its spec's) to its floor. Returns the tiles touched.
static func dig(ground: Ground, building: Node3D, spec: Dictionary) -> int:
	var rs := rects(spec)
	if rs.is_empty() or ground == null:
		return 0
	var floor_y: float = (building.global_transform * Vector3(0.0, float(spec.levels.cellar.floor), 0.0)).y
	var inv := building.global_transform.affine_inverse()
	# The drift (#1220): its trench dug to its floor (falling along it), and covered over again at the
	# ground's height: what the lane's ground was before the dig, sampled first.
	var dr := drift_rect(spec)
	var cover := []
	if dr.has_area():
		rs.append(dr)
		# (dug before, a load over a save: its cover is there, and the ground under it is the trench)
		if not ground.has_node(NodePath("DriftCover_" + String(building.name))):
			cover = _cover_heights(ground, building, spec)
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
					var fy := floor_y
					if dr.has_area() and dr.has_point(Vector2(p.x, p.z)) and p.x > float(spec.lot.width):
						fy = (building.global_transform * Vector3(p.x, Drift.floor_at(spec.drift, float(spec.levels.cellar.floor), p.x), p.z)).y
					var want := fy - base
					if absf(t.heights[k] - want) > 0.001:
						t.heights[k] = want
						t.loose[k] = 0.0
						changed = true
			if t != null and changed:
				t.rebuild(ground.material)
				touched += 1
	if not cover.is_empty():
		_cover(ground, building, spec, cover)
	return touched


## The ground's height over the drift before it's dug: [x, y] (building space) a metre apart, from the
## building's outer wall to the far cellar's (the drift's own walls inside its stone are left out).
static func _cover_heights(ground: Ground, building: Node3D, spec: Dictionary) -> Array:
	var d: Dictionary = spec.drift
	var x0 := float(spec.lot.width)
	var x1 := float(d.x[1]) - float(spec.frame.foundation.thick)
	var zc := (float(d.z[0]) + float(d.z[1])) * 0.5
	var out := []
	var n := maxi(1, ceili((x1 - x0) / 1.0))
	for k in n:
		var a := lerpf(x0, x1, float(k) / n)
		var e := lerpf(x0, x1, float(k + 1) / n)
		var w: Vector3 = building.global_transform * Vector3((a + e) * 0.5, 0.0, zc)
		out.append([a, e, building.to_local(Vector3(w.x, ground.height_at(w.x, w.z), w.z)).y])
	return out


## The drift's cover (#1220): slabs of the ground's own dirt (its material, drawn from the world's
## position) over the trench, their tops where the ground was, their undersides on the drift's lagging,
## a little wider than the cut; one static body each. Children of the Ground (the ground's, not the
## building's: it isn't timber), named DriftCover so a load over a save finds them made already.
static func _cover(ground: Ground, building: Node3D, spec: Dictionary, cover: Array) -> void:
	var name := "DriftCover_" + String(building.name)
	var root := StaticBody3D.new()
	root.name = name
	root.collision_layer = ground.collision_layer
	root.collision_mask = ground.collision_mask
	ground.add_child(root)
	root.global_transform = building.global_transform
	var d: Dictionary = spec.drift
	var z0 := float(d.z[0]) - 0.15
	var z1 := float(d.z[1]) + 0.15
	var cf := float(spec.levels.cellar.floor)
	for c: Array in cover:
		var a := float(c[0])
		var e := float(c[1])
		var top := float(c[2])
		var under: float = Drift.roof_at(d, cf, (a + e) * 0.5) + 0.005
		if top - under < 0.05:
			continue
		var size := Vector3(e - a + 0.02, top - under, z1 - z0)
		var at := Vector3((a + e) * 0.5, (top + under) * 0.5, (z0 + z1) * 0.5)
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		cs.shape = box
		cs.position = at
		root.add_child(cs)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.material_override = ground.material
		mi.position = at
		root.add_child(mi)
