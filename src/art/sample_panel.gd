class_name SamplePanel
extends Node3D
## The material library's sample panel (#701, Sean 2026-11-08: "approve the materials now; build
## later"; docs/briefs/material-library.md): one library entry (a wood at an age) on a 2 x 2 m wall,
## a floor patch before it and a rail on two posts, every piece a board of its real size drawn by
## `scan_wood.gdshader` (scanned CC0 maps, part 1's no-repeats, part 5's shape per board).
##
## Drawn only, like MaterialStand: no members, no load paths. The boards' shape lives in the vertex
## shader from each board's seed (CUSTOM0-2), so the same meshes drop into members later; their
## collision would stay the plain box.
##
## The panel's space: the wall along +X in the plane z = 0 (x 0..2, y 0..2), its face toward -Z;
## the floor patch in front (z 0..-FLOOR_D); the rail along the patch's front edge; ground at y 0.

const WALL := Vector2(2.0, 2.0)
const FLOOR_D := 1.2
const FLOOR_Y := 0.03
const SHADER := preload("res://src/render/scan_wood.gdshader")
const SCANS := "res://assets/textures/scans/"

## The class's numbers (#695's classes; part 5's warp and gaps by class and age; Sean, #718:
## more warp and gaps on old boards, fine and new boards nearly true). Gaps in metres
## at new / a few years / old; size variance as a share of the width; thickness in metres.
const CLASSES := {
	&"rough": {"warp": [0.3, 0.85, 1.6], "gap": [0.002, 0.007, 0.017], "width_var": 0.08, "thick_var": 0.002,
			"ends": 0.04, "floor": {"w": 0.25, "t": 0.04, "gap": [0.006, 0.01, 0.019]},
			"rail": {"post": Vector2(0.1, 0.1), "rail": Vector2(0.1, 0.05), "h": 0.95}},
	&"common": {"warp": [0.12, 0.55, 1.2], "gap": [0.0006, 0.0025, 0.007], "width_var": 0.05, "thick_var": 0.0012,
			"ends": 0.0, "floor": {"w": 0.14, "t": 0.03, "gap": [0.003, 0.006, 0.011]},
			"rail": {"post": Vector2(0.14, 0.14), "rail": Vector2(0.14, 0.045), "h": 0.95}},
	&"fine": {"warp": [0.03, 0.08, 0.22], "gap": [0.0003, 0.0006, 0.0015], "width_var": 0.015, "thick_var": 0.0003,
			"ends": 0.0, "floor": {"w": 0.075, "t": 0.02, "gap": [0.0004, 0.001, 0.002]},
			"rail": {"post": Vector2(0.1, 0.1), "rail": Vector2(0.075, 0.06), "h": 1.07}},
}
const AGES := {&"new": 0.0, &"few": 0.5, &"old": 1.0}

## The entry this panel shows (MaterialLibrary's: config/material_library.json) and its age.
var entry: Dictionary = {}
## The wall's size (a long wall for part 1's sheet).
var wall_size := WALL
var age_name: StringName = &"new"
## Each board's seed starts here: panels side by side differ.
var seed_base := 0
## The panel's boards by part (wall, floor, rail), for masks and counts.
var part_nodes := {}
var boards := 0

var _rng := RandomNumberGenerator.new()
var _mats := {}


func build() -> void:
	_rng.seed = hash([entry.get("id", ""), String(age_name), seed_base])
	var cls: Dictionary = CLASSES[StringName(entry.get("class", "common"))]
	var ai: int = ["new", "few", "old"].find(String(age_name))
	var warp: float = float(cls["warp"][ai]) * float(entry.get("warp_scale", 1.0))
	var gap: float = float(cls["gap"][ai])
	var wall := _part(&"wall")
	var layout := String(entry.get("layout", "lap"))
	var bw: float = float(entry.get("board_w", 0.15))
	var bt: float = float(entry.get("board_t", 0.02))
	var nails := Vector2(float(entry.get("nails", 1)), float(entry.get("nail_at", 0.6)))
	match layout:
		"board_batten":
			_vertical(wall, bw, bt, gap, warp, cls, nails, &"wall")
			# The battens over the joints (2.5 in), nailed down their middle.
			var bx: Array = wall.get_meta("joints", [])
			for jx in bx:
				_board(wall, Transform3D(Basis(Vector3.UP, Vector3.RIGHT, Vector3.BACK * -1.0), Vector3(jx, 0.0, -bt - 0.0095)),
						wall_size.y + _rng.randf_range(-cls["ends"], cls["ends"]) * 0.5, 0.064 * (1.0 + _rng.randf_range(-0.05, 0.05)), 0.019,
						warp, Vector2(1, 0.0), &"wall")
		"vertical":
			_vertical(wall, bw, bt, gap, warp, cls, nails, &"wall")
		"lap":
			_lap(wall, bw, bt, float(entry.get("expose", 0.115)), warp, cls, nails)
		_:
			_horizontal(wall, bw, bt, gap, warp, cls, nails)
	_backing(wall)
	_floor(_part(&"floor"), cls, ai, warp)
	_rail(_part(&"rail"), cls, warp)


func _part(name: StringName) -> Node3D:
	var n := Node3D.new()
	n.name = String(name).capitalize()
	add_child(n)
	part_nodes[name] = n
	return n


## Vertical boards across the wall (board and batten, tongue and groove), each its own width.
func _vertical(wall: Node3D, bw: float, bt: float, gap: float, warp: float, cls: Dictionary, nails: Vector2, role: StringName) -> void:
	var x := 0.0
	var joints := []
	# Up the wall: local X up, local Y along +X, the face toward -Z.
	var basis := Basis(Vector3.UP, Vector3.RIGHT, Vector3.BACK * -1.0)
	while x < wall_size.x - 0.02:
		var w: float = minf(bw * (1.0 + _rng.randf_range(-1.0, 1.0) * cls["width_var"]), wall_size.x - x)
		var t: float = bt + _rng.randf_range(-1.0, 1.0) * cls["thick_var"]
		var l: float = wall_size.y + _rng.randf_range(-1.0, 1.0) * cls["ends"] * 0.5
		_board(wall, Transform3D(basis, Vector3(x + w * 0.5, 0.0, -t * 0.5)), l, w, t, warp, nails, role)
		x += w + gap * _rng.randf_range(0.6, 1.4)
		joints.append(x - gap * 0.5)
	joints.pop_back()
	wall.set_meta("joints", joints)


## Horizontal boards up the wall, flush (rough boards, drop siding).
func _horizontal(wall: Node3D, bw: float, bt: float, gap: float, warp: float, cls: Dictionary, nails: Vector2) -> void:
	var y := 0.0
	# Along +X, local Y down (so +Z, the face, is toward -Z).
	var basis := Basis(Vector3.RIGHT, Vector3.DOWN, Vector3.BACK * -1.0)
	while y < wall_size.y - 0.02:
		var w: float = minf(bw * (1.0 + _rng.randf_range(-1.0, 1.0) * cls["width_var"]), wall_size.y - y)
		var t: float = bt + _rng.randf_range(-1.0, 1.0) * cls["thick_var"]
		var x0: float = -_rng.randf_range(0.0, cls["ends"])
		var l: float = wall_size.x - x0 + _rng.randf_range(0.0, cls["ends"])
		_board(wall, Transform3D(basis, Vector3(x0, y + w * 0.5, -t * 0.5)), l, w, t, warp, nails, &"wall")
		y += w + gap * _rng.randf_range(0.6, 1.4)


## Lap siding: each board's foot standing out over the one below, its top behind it.
func _lap(wall: Node3D, bw: float, bt: float, expose: float, warp: float, cls: Dictionary, nails: Vector2) -> void:
	var y := 0.0
	var tilt := atan2(bt, bw)
	while y < wall_size.y - 0.02:
		var w: float = bw * (1.0 + _rng.randf_range(-1.0, 1.0) * cls["width_var"])
		var t: float = bt + _rng.randf_range(-1.0, 1.0) * cls["thick_var"]
		# Turned about its length so its foot (local -Y side... here, the bottom) leans out.
		var basis := Basis(Vector3.RIGHT, Vector3.DOWN, Vector3.BACK * -1.0).rotated(Vector3.RIGHT, tilt)
		_board(wall, Transform3D(basis, Vector3(0.0, y + w * 0.5, -t * 0.5 - bt * 0.5)), wall_size.x, w, t, warp, nails, &"wall")
		y += expose * (1.0 + _rng.randf_range(-0.03, 0.03))


## Sheathing behind the boards, as a wall has (studs, boards or paper): its joints show dark, not
## the desert through them (the judge, 2026-11-08: "thin light lines between the laps").
func _backing(wall: Node3D) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(wall_size.x, wall_size.y, 0.012)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.09, 0.075, 0.06)
	m.roughness = 0.95
	mi.material_override = m
	mi.position = Vector3(wall_size.x * 0.5, wall_size.y * 0.5, 0.012)
	mi.name = "Backing"
	wall.add_child(mi)


## The floor patch: planks along X, gapped by class and age; nailed two to a joist.
func _floor(fl: Node3D, cls: Dictionary, ai: int, warp: float) -> void:
	var f: Dictionary = cls["floor"]
	# Face-nailed, two to a joist; a fine floor's strips are blind-nailed through the tongue.
	var floor_nails := Vector2(0, 0) if StringName(entry.get("class", "")) == &"fine" else Vector2(2, 0.6)
	var z := -0.01
	var basis := Basis(Vector3.RIGHT, Vector3.BACK * -1.0, Vector3.UP)
	while z > -FLOOR_D:
		var w: float = float(f["w"]) * (1.0 + _rng.randf_range(-1.0, 1.0) * cls["width_var"])
		var t: float = float(f["t"]) + _rng.randf_range(-1.0, 1.0) * cls["thick_var"]
		var x0: float = -_rng.randf_range(0.0, cls["ends"])
		var l: float = wall_size.x - x0 + _rng.randf_range(0.0, cls["ends"])
		_board(fl, Transform3D(basis, Vector3(x0, FLOOR_Y + t * 0.5, z - w * 0.5)), l, w, t, warp, floor_nails, &"floor")
		z -= w + float(f["gap"][ai]) * _rng.randf_range(0.6, 1.4)


## Two posts and a rail along the patch's front edge.
func _rail(r: Node3D, cls: Dictionary, warp: float) -> void:
	var rd: Dictionary = cls["rail"]
	var post: Vector2 = rd["post"]
	var rail: Vector2 = rd["rail"]
	var h: float = rd["h"]
	var up := Basis(Vector3.UP, Vector3.RIGHT, Vector3.BACK * -1.0)
	for px in [0.15, wall_size.x - 0.15]:
		_board(r, Transform3D(up, Vector3(px, 0.0, -FLOOR_D + 0.05)), h - rail.y, post.x, post.y, warp * 0.5, Vector2.ZERO, &"rail")
	# The rail flat on the posts: along X, its face up.
	var flat := Basis(Vector3.RIGHT, Vector3.BACK * -1.0, Vector3.UP)
	# (its role 1: a bar's rail top, where varnished: glass rings and elbows)
	_board(r, Transform3D(flat, Vector3(0.0, h - rail.y * 0.5, -FLOOR_D + 0.05)), wall_size.x, rail.x, rail.y, warp * 0.6, Vector2.ZERO, &"rail", 1.0)


func _board(parent: Node3D, xf: Transform3D, length: float, width: float, thick: float, warp: float, nails: Vector2, role: StringName, kind := 0.0) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = board_mesh(length, width, thick, _rng.randf(), warp, nails, global_position.y if is_inside_tree() else 0.0, kind)
	mi.material_override = _material(role)
	mi.transform = xf
	parent.add_child(mi)
	boards += 1


## The panel's material for a part (the wall, floor and rail share the entry; a part may name its
## own entry fields with a prefix, e.g. "floor_scans").
func _material(role: StringName) -> ShaderMaterial:
	if _mats.has(role):
		return _mats[role]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	MaterialLibrary.apply(m, entry, AGES[age_name], role)
	_mats[role] = m
	return m


## One board's mesh: a box in its own frame (X along 0..length, Y across, Z through, the shown face
## +Z), its long faces cut in a grid fine enough for the vertex shader's warp, every vertex carrying
## the board's seed and where it is on the board (scan_wood.gdshader's CUSTOM0-2).
static func board_mesh(length: float, width: float, thick: float, seed: float, warp: float, nails := Vector2.ZERO, ground_y := 0.0, kind := 0.0) -> ArrayMesh:
	var nx := clampi(ceili(length / 0.1), 4, 40)
	var ny := 4
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var c0 := PackedFloat32Array()
	var c1 := PackedFloat32Array()
	var c2 := PackedFloat32Array()
	var idx := PackedInt32Array()
	var hw := width * 0.5
	var ht := thick * 0.5
	var add_grid := func(nu: int, nv: int, at: Callable, normal: Vector3, face: float) -> void:
		var base := v.size()
		for j in nv + 1:
			for i in nu + 1:
				var s := float(i) / nu
				var t := float(j) / nv
				var p: Vector3 = at.call(s, t)
				v.append(p)
				n.append(normal)
				# metres along and across the face shown (ends: across and through)
				if face == 1.0:
					uv.append(Vector2(p.y, p.z))
				elif face == 2.0:
					uv.append(Vector2(p.x, p.z))
				else:
					uv.append(Vector2(p.x, p.y))
				c0.append_array([seed, clampf(p.x / length, 0.0, 1.0), clampf(p.y / hw, -1.0, 1.0), face])
				c1.append_array([length, width, thick, warp])
				c2.append_array([nails.x, nails.y, ground_y, kind])
		for j in nv:
			for i in nu:
				var a := base + j * (nu + 1) + i
				var b := a + 1
				var c := a + nu + 1
				var d := c + 1
				# du x dv is the normal: wound clockwise seen from outside (Godot's front faces)
				idx.append_array([a, c, b, b, c, d])
	# +Z (shown) and -Z faces
	add_grid.call(nx, ny, func(s, t): return Vector3(s * length, (t * 2.0 - 1.0) * hw, ht), Vector3.BACK, 0.0)
	add_grid.call(nx, ny, func(s, t): return Vector3((1.0 - s) * length, (t * 2.0 - 1.0) * hw, -ht), Vector3.FORWARD, 0.0)
	# edges (+Y, -Y)
	add_grid.call(nx, 1, func(s, t): return Vector3((1.0 - s) * length, hw, (t * 2.0 - 1.0) * ht), Vector3.UP, 2.0)
	add_grid.call(nx, 1, func(s, t): return Vector3(s * length, -hw, (t * 2.0 - 1.0) * ht), Vector3.DOWN, 2.0)
	# ends (-X at 0, +X at length): end grain
	add_grid.call(ny, 1, func(s, t): return Vector3(0.0, (1.0 - s * 2.0) * hw, (t * 2.0 - 1.0) * ht), Vector3.LEFT, 1.0)
	add_grid.call(ny, 1, func(s, t): return Vector3(length, (s * 2.0 - 1.0) * hw, (t * 2.0 - 1.0) * ht), Vector3.RIGHT, 1.0)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_CUSTOM0] = c0
	arrays[Mesh.ARRAY_CUSTOM1] = c1
	arrays[Mesh.ARRAY_CUSTOM2] = c2
	arrays[Mesh.ARRAY_INDEX] = idx
	var fmt := (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) \
			| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT) \
			| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, fmt)
	# The warp moves a few millimetres: room for it in the culling box.
	mesh.custom_aabb = AABB(Vector3(-0.02, -hw - 0.02, -ht - 0.02), Vector3(length + 0.04, width + 0.04, thick + 0.04))
	return mesh
