class_name PropKit
## The prop kit (docs/briefs/prop-lab.md; docs/PARTS.md "Props"): every prop defined once, as data,
## one file per prop in assets/props/kit/<id>.json, built by one builder (KitProp). A kit file:
##
##   {"id", "kind": "members", "replaces": the PropLibrary prop it stands in for, "in_game": true
##    once PropLibrary hands it out in that prop's place (its look passed),
##    "fixture": true for one new to the game (the bar) that replaces no drawn prop,
##    "wood": the timber (TimberTuning), "look": the drawn material (below),
##    "splits_below": the share of a member's section left below which a holed member splits,
##    "blow_wood_share": how much of a blow's lost energy goes into the wood,
##    "seat": {"member", "at" (where his weight comes down), "share" (of his weight), "hold" (m)},
##    "members": [{"id", "kind", "size", "at", "rot" (degrees, XYZ), "wood", "look",
##                 "splits_below", "blow_span" (the length of it a blow bends), "draw", "repeat"}]}
##
## Positions in the prop's own space: origin at the bottom centre, facing +Z (as PropLibrary's).
## "repeat": {"count", "step": [x, y, z]} lays copies along a line; {"count", "radius", "start"}
## round the Y axis (each turned with its place); "%d" in the id takes the copy's number.
## "look": "prop:<name>" (PropModels' materials: dark_wood, mid_wood, felt, staves, brass, iron, mirror), or
## "wood:<name>" (the texture factory's woods, WoodMaterials). Without it, the member's wood's.
## "draw": how the member is drawn when it isn't a plain box (its collision is always its box):
##   {"shape": "lathe", "profile": [[r, y], ...], "segments", "grain_up"}: turned about the prop's Y;
##   {"shape": "sweep", "profile": [[r, y], ...], "from", "to" (degrees), "segments"}: part of one;
##   {"shape": "disc", "radius", "segments", "above"}: the member's box cut round to the circle about
##   Y ("above": instead a layer that thick laid on its top: a table's baize);
##   {"shape": "profile" | "panel" | "cut", ...}: interior woodwork (art's Profiles; woodwork_mesh).
## "dress": [{"look", "draw"}]: layers drawn on the member (glued, painted: not members of their
## own), going wherever the member goes; untouched, batched with it (KitProp).
## Profiles and radii are in the prop's space; the mesh is laid into the member's own.

const DIR := "res://assets/props/kit/"

static var _defs := {}
static var _made := {}


static func path_of(id: StringName) -> String:
	return DIR + String(id) + ".json"


static func has(id: StringName) -> bool:
	return _defs.has(id) or FileAccess.file_exists(path_of(id))


static func definition(id: StringName) -> Dictionary:
	if not _defs.has(id):
		var f := FileAccess.open(path_of(id), FileAccess.READ)
		assert(f != null, "No kit file for %s" % id)
		var parsed: Variant = JSON.parse_string(f.get_as_text()) if f else null
		_defs[id] = parsed if parsed is Dictionary else {}
	return _defs[id]


## Every prop in the kit.
static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".json"):
			out.append(StringName(f.get_basename()))
	return out


## A kit prop, not yet in the tree: put it where it goes (its origin on the floor) and add it.
## Each gets its own structure id (its members' ids start with it) unless given one.
static func spawn(id: StringName, structure_id := &"") -> KitProp:
	var p := KitProp.new()
	p.kit_id = id
	p.definition = definition(id)
	var n: int = _made.get(id, 0)
	_made[id] = n + 1
	p.structure_id = structure_id if structure_id != &"" else StringName("%s_%d" % [id, n])
	p.name = String(p.structure_id).to_pascal_case()
	p.build_seed = hash(p.structure_id)
	return p


## The member specs with every "repeat" laid out.
static func expand(def: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for spec: Dictionary in def.get("members", []):
		var rep: Dictionary = spec.get("repeat", {})
		if rep.is_empty():
			out.append(spec)
			continue
		for i in int(rep.count):
			var s := spec.duplicate(true)
			s.erase("repeat")
			s.id = String(spec.id) % i if String(spec.id).contains("%d") else "%s%d" % [spec.id, i]
			var at := vec(spec.at)
			if rep.has("radius"):
				var a := deg_to_rad(float(rep.get("start", 0.0)) + 360.0 * i / float(rep.count))
				var b := Basis(Vector3.UP, a)
				s.at = _arr(b * (at + Vector3(0, 0, float(rep.radius))))
				var rot := vec(spec.get("rot", [0, 0, 0]))
				s.rot = [rot.x, rot.y + rad_to_deg(a), rot.z]
				if s.has("draw") and s.draw.get("shape") == "sweep":
					# A sweep's angles run from +X toward +Z; turning about Y by `a` runs the other way.
					s.draw.from = float(s.draw.from) - rad_to_deg(a)
					s.draw.to = float(s.draw.to) - rad_to_deg(a)
			else:
				s.at = _arr(at + vec(rep.get("step", [0, 0, 0])) * i)
			out.append(s)
	return out


## Its members' boxes together, in its own space.
static func bounds(def: Dictionary) -> AABB:
	var box := AABB()
	var first := true
	for spec in expand(def):
		var b := Transform3D(basis_of(spec), vec(spec.at)) * AABB(-vec(spec.size) * 0.5, vec(spec.size))
		box = b if first else box.merge(b)
		first = false
	return box


static func vec(a: Variant) -> Vector3:
	if a is Vector3:
		return a
	var arr: Array = a
	return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))


static func _arr(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func basis_of(spec: Dictionary) -> Basis:
	var r := vec(spec.get("rot", [0, 0, 0]))
	return Basis.from_euler(Vector3(deg_to_rad(r.x), deg_to_rad(r.y), deg_to_rad(r.z)))


## The drawn material a look names (see the top).
static func material(look: String, variant: int) -> Material:
	var parts := look.split(":")
	if parts.size() == 2 and parts[0] == "wood":
		return WoodMaterials.get_material(StringName(parts[1]), variant)
	match parts[parts.size() - 1]:
		"dark_wood":
			return PropModels.dark_wood()
		"mid_wood":
			return PropModels.mid_wood()
		"felt":
			return PropModels.felt()
		"staves":
			return PropModels.staves()
		"brass":
			return PropModels.brass()
		"iron":
			return PropModels.iron()
		"mirror":
			return PropModels.mirror()
	push_warning("PropKit: unknown look %s" % look)
	return PropModels.mid_wood()


## A member's drawn mesh from its "draw" (in the prop's space), laid into the member's own space.
static func draw_mesh(draw: Dictionary, m: StructureMember) -> Mesh:
	var src: Mesh
	match String(draw.get("shape", "box")):
		"lathe":
			src = PropModels.lathe(_profile(draw.profile), int(draw.get("segments", 12)), bool(draw.get("grain_up", false)))
		"sweep":
			src = sweep(_profile(draw.profile), deg_to_rad(float(draw.from)), deg_to_rad(float(draw.to)), int(draw.get("segments", 6)))
		"disc":
			src = disc_cut(float(draw.radius), int(draw.get("segments", 32)), m, float(draw.get("above", 0.0)))
		"profile", "panel", "cut":
			# The woodwork's shapes (art's Profiles), made in the member's own space.
			return woodwork_mesh(draw, m)
		_:
			return MemberMesh.box(m.size)
	# Indexed, as MemberMesh's boxes are: a structure's batch (SurfaceTool.append_from) keeps the
	# first mesh's indices, and a mesh without any merged after an indexed one draws nothing.
	var st := SurfaceTool.new()
	st.append_from(src, 0, Transform3D.IDENTITY if draw.get("shape") == "disc" else m.transform.affine_inverse())
	st.index()
	return st.commit()


## The member's own axes by name ("x", "-z"...).
static func _axis(name: String) -> Vector3:
	var v := {"x": Vector3.RIGHT, "y": Vector3.UP, "z": Vector3.BACK}[name.trim_prefix("-")] as Vector3
	return -v if name.begins_with("-") else v


## The size of the member's box along an axis.
static func _extent(m: StructureMember, name: String) -> float:
	var a := _axis(name).abs()
	return m.size.x * a.x + m.size.y * a.y + m.size.z * a.z


## A member drawn as interior woodwork (docs/briefs/interior-woodwork.md; Profiles), in its own
## space, its box filled:
##   {"shape": "profile", "profile": "bar_top" | "chamfered" | "rounded" | "handrail" | "ogee" |
##    "beaded" | "rect", "along": its length's axis, "up": the section's y, "across": its x (signed:
##    "-z" turns the section's front to -Z), "args": the profile's numbers past its width and
##    thickness (a chamfer, a radius, rounded corners)}: a moulding run along the member;
##   {"shape": "panel", "out": the axis the field stands proud along, "bevel"}: a raised panel, its
##    other two axes in the member's order (x then y, or x then z...);
##   {"shape": "cut", "outline": [[a, b], ...], "plane": two axes ("zy": a along z, b along y)}: a
##    board cut to the outline (brackets, a crest), as thick as the member across the plane.
## Its strip's place from the member's id, so a batch of them doesn't repeat.
static func woodwork_mesh(draw: Dictionary, m: StructureMember) -> Mesh:
	var u0 := float(posmod(hash(String(m.member_id)), 199)) / 100.0
	match String(draw.shape):
		"profile":
			var along := String(draw.get("along", "x"))
			var up := String(draw.get("up", "y"))
			var across := String(draw.get("across", ""))
			if across == "":
				for n in ["x", "y", "z"]:
					if n != along.trim_prefix("-") and n != up.trim_prefix("-"):
						across = n
			var args: Array = [_extent(m, across), _extent(m, up)]
			args.append_array(draw.get("args", []))
			var runs: Array = Profiles.by_name(String(draw.profile), args)
			return Profiles.to_mesh(Profiles.extrude_tris(runs, _extent(m, along), u0),
					Transform3D(Basis(_axis(along), _axis(across), _axis(up)), Vector3.ZERO))
		"panel":
			var out := String(draw.get("out", "z"))
			var axes := ["x", "y", "z"].filter(func(n: String) -> bool: return n != out.trim_prefix("-"))
			var t := _extent(m, out)
			return Profiles.to_mesh(Profiles.panel_tris(_extent(m, axes[0]), _extent(m, axes[1]), t, float(draw.get("bevel", 0.05)), u0),
					Transform3D(Basis(_axis(axes[0]), _axis(axes[1]), _axis(out)), -_axis(out) * t * 0.5))
		"cut":
			var plane := String(draw.get("plane", "xy"))
			var a := String(plane[0])
			var b := String(plane[1])
			var n := ["x", "y", "z"].filter(func(k: String) -> bool: return k != a and k != b)[0] as String
			var shape := _profile(draw.outline)
			return Profiles.to_mesh(Profiles.cut_tris(shape, _extent(m, n), u0), Transform3D(Basis(_axis(a), _axis(b), _axis(n)), Vector3.ZERO))
	return MemberMesh.box(m.size)


static func _profile(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(Vector2(float(p[0]), float(p[1])))
	return out


## Part of a turned shape: the profile ([r, y]) swept about Y from angle `a0` to `a1` (radians,
## from +X toward +Z, as PropModels.lathe), smooth round it, UVs in metres (u round, v down the
## profile), its cut ends left open (the rim's neighbours meet them).
static func sweep(profile: PackedVector2Array, a0: float, a1: float, segments: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var along := [0.0]
	for i in range(1, profile.size()):
		along.append(along[i - 1] + profile[i].distance_to(profile[i - 1]))
	var r_mean := 0.0
	for p in profile:
		r_mean += p.x
	r_mean /= profile.size()
	# Outward is to the right of the way the profile runs when it runs anticlockwise round its
	# cross-section (r right, y up); a profile run clockwise (the rim's) has it on the left.
	var area := 0.0
	for i in profile.size():
		area += profile[i].cross(profile[(i + 1) % profile.size()])
	var side := 1.0 if area >= 0.0 else -1.0
	for i in profile.size() - 1:
		var p0 := profile[i]
		var p1 := profile[i + 1]
		var d := p1 - p0
		var n2 := Vector2(d.y, -d.x).normalized() * side  # the band's outward normal in (r, y)
		for s in segments:
			var t0 := lerpf(a0, a1, float(s) / segments)
			var t1 := lerpf(a0, a1, float(s + 1) / segments)
			var verts: Array[Vector3] = []
			var norms: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for c in [[t0, p0, along[i]], [t1, p0, along[i]], [t1, p1, along[i + 1]], [t0, p1, along[i + 1]]]:
				var t: float = c[0]
				var p: Vector2 = c[1]
				verts.append(Vector3(cos(t) * p.x, p.y, sin(t) * p.x))
				norms.append(Vector3(cos(t) * n2.x, n2.y, sin(t) * n2.x).normalized())
				uvs.append(Vector2(t * r_mean, float(c[2])))
			_quad(st, verts, norms, uvs)
	return st.commit()


## A quad (four corners in order round it) as two triangles, wound as Godot's front faces are
## (clockwise as seen: the right-hand normal points away from the outward one), as PropModels'.
static func _quad(st: SurfaceTool, verts: Array[Vector3], norms: Array[Vector3], uvs: Array[Vector2]) -> void:
	var order := [0, 1, 2, 0, 2, 3]
	var face := (verts[1] - verts[0]).cross(verts[2] - verts[0])
	if face.length_squared() < 1e-14:
		face = (verts[2] - verts[0]).cross(verts[3] - verts[0])
	if face.dot(norms[0] + norms[2]) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for k in order:
		st.set_normal(norms[k])
		st.set_uv(uvs[k])
		st.add_vertex(verts[k])


## The member's box cut round to a circle of `radius` about the prop's Y axis (a round top's
## boards, its baize): its top and bottom faces clipped to the circle, its sides the circle's arc
## and whatever of the box's own sides is left. In the member's own space, UVs in metres.
static func disc_cut(radius: float, segments: int, m: StructureMember, above := 0.0) -> ArrayMesh:
	var h := m.size * 0.5
	# A layer on its top (`above` thick) rather than the member itself: drawn about its own middle,
	# lifted onto the top by the caller's transform.
	var lift := 0.0
	if above > 0.0:
		lift = h.y + above * 0.5
		h.y = above * 0.5
	var inv := m.transform.affine_inverse()
	var poly := PackedVector2Array()
	for s in segments:
		var a := TAU * s / segments
		var p := inv * Vector3(cos(a) * radius, 0.0, sin(a) * radius)
		poly.append(Vector2(p.x, p.z))
	var rect := PackedVector2Array([Vector2(-h.x, -h.z), Vector2(h.x, -h.z), Vector2(h.x, h.z), Vector2(-h.x, h.z)])
	var cut := Geometry2D.intersect_polygons(poly, rect)
	var outline: PackedVector2Array = cut[0] if not cut.is_empty() else rect
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := Geometry2D.triangulate_polygon(outline)
	for face in [1.0, -1.0]:
		var n := Vector3(0, face, 0)
		for i in range(0, tris.size(), 3):
			var v: Array[Vector3] = []
			for k in 3:
				var p := outline[tris[i + k]]
				v.append(Vector3(p.x, h.y * face + lift, p.y))
			if (v[1] - v[0]).cross(v[2] - v[0]).dot(n) > 0.0:
				v = [v[0], v[2], v[1]]
			for q in v:
				st.set_normal(n)
				st.set_uv(Vector2(q.x, q.z))
				st.add_vertex(q)
	# Sides: each edge of the outline, facing out from its middle.
	var mid := Vector2.ZERO
	for p in outline:
		mid += p
	mid /= maxf(outline.size(), 1)
	var run := 0.0
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var e := b - a
		var n2 := Vector2(e.y, -e.x).normalized()
		if n2.dot((a + b) * 0.5 - mid) < 0.0:
			n2 = -n2
		var n := Vector3(n2.x, 0.0, n2.y)
		var span := e.length()
		_quad(st, [Vector3(a.x, lift - h.y, a.y), Vector3(b.x, lift - h.y, b.y), Vector3(b.x, lift + h.y, b.y), Vector3(a.x, lift + h.y, a.y)],
				[n, n, n, n], [Vector2(run, 0), Vector2(run + span, 0), Vector2(run + span, h.y * 2.0), Vector2(run, h.y * 2.0)])
		run += span
	return st.commit()


## Convex hull (Andrew's monotone chain), anticlockwise in x/y.
static func hull(points: Array[Vector2]) -> PackedVector2Array:
	var pts := points.duplicate()
	pts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	if pts.size() < 3:
		return PackedVector2Array(pts)
	var lower: Array[Vector2] = []
	for p: Vector2 in pts:
		while lower.size() >= 2 and (lower[-1] - lower[-2]).cross(p - lower[-2]) <= 0.0:
			lower.pop_back()
		lower.append(p)
	var upper: Array[Vector2] = []
	for i in range(pts.size() - 1, -1, -1):
		var p: Vector2 = pts[i]
		while upper.size() >= 2 and (upper[-1] - upper[-2]).cross(p - upper[-2]) <= 0.0:
			upper.pop_back()
		upper.append(p)
	lower.pop_back()
	upper.pop_back()
	return PackedVector2Array(lower + upper)


## Inside an anticlockwise convex polygon by at least `margin` (on the edge counts, with none).
static func inside(poly: PackedVector2Array, p: Vector2, margin := 0.0) -> bool:
	if poly.size() < 3:
		return false
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if (b - a).normalized().cross(p - a) < margin - 1e-6:
			return false
	return true
