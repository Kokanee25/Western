class_name OakStair
extends MaterialStand
## A hotel's lobby stair in dark oak (Sean, 2026-10-21: "a beautiful oak staircase that would maybe
## be in the hotel - dark wood"), on the material lab's bench (tools/material_lab.gd --material=stair)
## for judging beside the men; the hotel's interior, when the building lab makes it, takes it from
## here. Drawn only, like the stand.
##
## Sizes from period stairbuilding practice (rise and going by the old rule, twice the rise and the
## going near 64 cm: 2 x 190 + 270 = 650 mm; a 30 mm nosing; rail 900 mm over the nosings on the
## flight, 1 m on the landing; two balusters a tread): 13 risers to a landing at 2.47 m, the flight
## 1.15 m wide between an open cut string (its balusters, the rail and the newels on it) and a
## wall string. The first step a bullnose round the foot of the newel. A runner held by brass rods.
##
## The stair's space: the flight rising along +Z from the floor at z = 0, its open side at x = 0
## facing -X, the wall string at x = WIDTH.

const RISERS := 13
const STEP_RISE := 0.19
const GOING := 0.27
const NOSE := 0.03
const TREAD_T := 0.035
const RISER_T := 0.022
const WIDTH := 1.15
const RAIL_H := 0.9
const LANDING_RAIL_H := 1.0
const LANDING_DEPTH := 1.3
const RUNNER_W := 0.8
## The bullnose: the first step runs past the open side round the newel.
const BULL := 0.32
## The newel on the bullnose, on the cut string's line (the string dies into it).
const NEWEL := Vector2(-0.02, 0.13)

const PARTS := [&"oak_treads", &"oak_risers", &"oak_strings", &"oak_newels", &"oak_balusters", &"oak_rail", &"oak_landing", &"oak_runner", &"oak_rods"]


func _init() -> void:
	for p in PARTS:
		roles[p] = &"dark_oak"
	roles[&"oak_landing"] = &"dark_oak"
	# The lobby round it: a painted board wall (the store's pale boards) over an oak skirting, the
	# game's floor (an all-dark wall swallowed the stair in the first render).
	roles[&"oak_wall"] = &"store_boards"
	roles[&"oak_skirt"] = &"dark_oak"
	roles[&"oak_floor"] = &"floor"


func focus_parts() -> Array:
	return [&"oak_treads", &"oak_risers", &"oak_strings", &"oak_newels", &"oak_balusters", &"oak_rail", &"oak_landing"]


## The top of the flight's treads (y) at z: on the line through the nosings.
func pitch_y(z: float) -> float:
	return STEP_RISE + (z + NOSE) * STEP_RISE / GOING


func landing_y() -> float:
	return RISERS * STEP_RISE


## The lobby round it (a wall and a floor); off, the stair stands alone on whatever ground it's
## put on (the ragdoll lab).
var room := true


func build() -> void:
	_rng.seed = seed_value
	# Solid, the stair's own boards and turnings take a box each; the lobby a box for its wall and
	# one for its floor; the runner and rods none.
	solid_parts = [&"oak_treads", &"oak_risers", &"oak_strings", &"oak_newels", &"oak_balusters", &"oak_rail", &"oak_landing"]
	if room:
		_room()
	_flight()
	_landing()
	_strings()
	_flush()
	_balustrade()
	_runner()
	_flush_solid()


func _flight() -> void:
	for i in RISERS - 1:
		var top := (i + 1) * STEP_RISE
		var x0 := -BULL if i == 0 else 0.0
		var z0 := i * GOING - NOSE
		var z1 := (i + 1) * GOING
		# The tread, its nosing over the riser.
		_board(&"oak_treads", Vector3((x0 + WIDTH) * 0.5, top - TREAD_T * 0.5, (z0 + z1) * 0.5), Vector3(1, 0, 0), Vector3(0, 1, 0),
				WIDTH - x0, z1 - z0, TREAD_T, Vector3(0, 0, 1))
		# The riser under its front.
		var ry0 := i * STEP_RISE
		var ry1 := top - TREAD_T
		_board(&"oak_risers", Vector3((x0 + WIDTH) * 0.5, (ry0 + ry1) * 0.5, i * GOING + RISER_T * 0.5), Vector3(1, 0, 0), Vector3(0, 0, 1),
				WIDTH - x0, ry1 - ry0, RISER_T)
	# The bullnose's round end: a turned drum under the first tread's open end.
	var drum := PropModels.lathe(PackedVector2Array([Vector2(0, 0), Vector2(GOING * 0.5, 0), Vector2(GOING * 0.5, STEP_RISE), Vector2(0, STEP_RISE)]), 24, true)
	_turned(&"oak_risers", drum, Transform3D(Basis(), Vector3(-BULL, 0.0, GOING * 0.5 - NOSE * 0.5)), 3)


## The lobby: a wall of upright boards behind the wall string (to the landing's ceiling height),
## and a floor of boards running out from it, so the stair reads as indoors.
func _room() -> void:
	var z0 := -5.5
	var z1 := (RISERS - 1) * GOING + LANDING_DEPTH + 0.3
	var wx := WIDTH + 0.06
	var h := landing_y() + 2.4
	var z := z0
	while z < z1:
		_board(&"oak_wall", Vector3(wx + 0.011, h * 0.5, z + 0.075), Vector3(0, 1, 0), Vector3(1, 0, 0), h, 0.148, 0.022)
		z += 0.15
	_board(&"oak_skirt", Vector3(wx - 0.01, 0.11, (z0 + z1) * 0.5), Vector3(0, 0, 1), Vector3(1, 0, 0), z1 - z0, 0.2, 0.022, Vector3(0, 1, 0))
	if solid:
		_shapes.append([Transform3D(Basis(), Vector3(wx + 0.011, h * 0.5, (z0 + z1) * 0.5)), Vector3(0.022, h, z1 - z0)])
		_shapes.append([Transform3D(Basis(), Vector3((wx - 5.5) * 0.5, -0.015, (z0 + z1) * 0.5)), Vector3(wx + 5.5, 0.03, z1 - z0)])
	var x := wx
	while x > -5.5:
		_board(&"oak_floor", Vector3(x - 0.075, 0.0, (z0 + z1) * 0.5), Vector3(0, 0, 1), Vector3(0, 1, 0), z1 - z0, 0.146, 0.03,
				Vector3(1, 0, 0))
		x -= 0.15


func _landing() -> void:
	var y := landing_y()
	var z0 := (RISERS - 1) * GOING - NOSE
	var z1 := z0 + LANDING_DEPTH
	# Its boards across the flight, its front a riser and a deep fascia.
	var w := 0.14
	var z := z0
	while z < z1 - 0.01:
		var d := minf(w, z1 - z)
		_board(&"oak_landing", Vector3(WIDTH * 0.5, y - TREAD_T * 0.5, z + d * 0.5), Vector3(1, 0, 0), Vector3(0, 1, 0), WIDTH, d - 0.003, TREAD_T,
				Vector3(0, 0, 1))
		z += d
	_board(&"oak_risers", Vector3(WIDTH * 0.5, y - STEP_RISE * 0.5 - TREAD_T * 0.5, (RISERS - 1) * GOING + RISER_T * 0.5), Vector3(1, 0, 0),
			Vector3(0, 0, 1), WIDTH, STEP_RISE - TREAD_T, RISER_T)
	# The landing's open side and front, faced; posts under its far corners.
	_board(&"oak_strings", Vector3(-0.02, y - 0.16, (z0 + z1) * 0.5), Vector3(0, 0, 1), Vector3(1, 0, 0), z1 - z0, 0.28, 0.04)
	_board(&"oak_strings", Vector3(WIDTH * 0.5, y - 0.16, z1 + 0.02), Vector3(1, 0, 0), Vector3(0, 0, 1), WIDTH + 0.04, 0.28, 0.04)
	for px in [-0.02, WIDTH]:
		_board(&"oak_newels", Vector3(px, (y - 0.3) * 0.5, z1 - 0.06), Vector3(0, 1, 0), Vector3(0, 0, 1), y - 0.3, 0.12, 0.12)


func _strings() -> void:
	var top_z := (RISERS - 1) * GOING - NOSE
	var slope := STEP_RISE / GOING
	# How far the strings stand below the nosing line, measured plumb (300 mm square to it).
	var depth := 0.3 * sqrt(1.0 + slope * slope)
	# The cut string on the open side: its top 50 mm over the nosings, dying into the newel at its
	# foot (a level cut where it sits on the first step) and into the landing's newel at its head
	# (a plumb cut). A straight box ran down through the bullnose to the floor (Sean, 2026-10-21).
	_string(-0.04, 0.0, NEWEL.y + 0.08, top_z - 0.02, 0.05, depth, STEP_RISE + 0.004)
	# The wall string, 330 deep against the wall, from the floor (level cut on it) to the landing.
	_string(WIDTH, WIDTH + 0.036, -NOSE - 0.1, top_z + 0.1, 0.11, depth + 0.03, 0.016)
	# The soffit under the flight, from where it clears the floor to the landing.
	var a := Vector3(WIDTH * 0.5, pitch_y(0.45) - depth - 0.03, 0.45)
	var b := Vector3(WIDTH * 0.5, pitch_y(top_z) - depth - 0.03, top_z)
	var along := (b - a).normalized()
	var up := along.cross(Vector3(1, 0, 0)).normalized()
	if up.y < 0.0:
		up = -up
	_board(&"oak_strings", (a + b) * 0.5, along, up, a.distance_to(b), WIDTH, 0.02, Vector3(1, 0, 0))


## A string between x0 and x1: its top `over` above the nosing line from z0 to z1, `depth` deep
## (plumb), its foot cut level at y_min where it would go lower. Long faces flagged with a place on
## the strip, its plumb and level cuts drawn as end grain.
func _string(x0: float, x1: float, z0: float, z1: float, over: float, depth: float, y_min: float) -> void:
	var top := func(z: float) -> float: return pitch_y(z) + over
	# The outline in (z, y), round the board: top edge up the slope, plumb cut at the head, bottom
	# edge down, then a level cut and a plumb cut at the foot if the bottom would pass y_min.
	var pts: Array[Vector2] = [Vector2(z0, top.call(z0)), Vector2(z1, top.call(z1)), Vector2(z1, top.call(z1) - depth)]
	var zl: float = z0 + (y_min - (top.call(z0) - depth)) / (STEP_RISE / GOING)
	if zl > z0 and zl < z1:
		pts.append(Vector2(zl, y_min))
		pts.append(Vector2(z0, y_min))
	else:
		pts.append(Vector2(z0, top.call(z0) - depth))
	var wood := wood_for(&"oak_strings")
	var strips := maxi(WoodMaterials.strip_count(wood), 1)
	var pick := _rng.randi_range(0, strips - 1)
	var u0 := _rng.randf_range(0.0, 1.9)
	if not _tools.has(&"oak_strings"):
		_tools[&"oak_strings"] = {}
	if not _tools[&"oak_strings"].has(pick):
		var st0 := SurfaceTool.new()
		st0.begin(Mesh.PRIMITIVE_TRIANGLES)
		_tools[&"oak_strings"][pick] = st0
	var st: SurfaceTool = _tools[&"oak_strings"][pick]
	var dir := Vector3(0, STEP_RISE, GOING).normalized()
	var long := Vector3(0, top.call(z1) - top.call(z0), z1 - z0).length()
	var flag := Color(0.0, 0.0, u0 * 0.5, 1.0)
	# The two broad sides: fans over the (convex) outline, u along the slope, v down from the top.
	for x in [x0, x1]:
		var n := Vector3(-1, 0, 0) if x == x0 else Vector3(1, 0, 0)
		var v3: Array[Vector3] = []
		var uv: Array[Vector2] = []
		for p in pts:
			var q := Vector3(x, p.y, p.x)
			v3.append(q)
			var rel := q - Vector3(x, top.call(z0), z0)
			uv.append(Vector2(u0 + rel.dot(dir), -rel.dot(dir.cross(Vector3(1, 0, 0)).normalized())))
		for i in range(1, v3.size() - 1):
			var tri := [0, i, i + 1]
			if (v3[i] - v3[0]).cross(v3[i + 1] - v3[0]).dot(n) > 0.0:
				tri = [0, i + 1, i]
			for k in tri:
				st.set_color(flag)
				st.set_normal(n)
				st.set_uv(uv[k])
				st.set_uv2(Vector2(long, depth))
				st.add_vertex(v3[k])
	# Round the edge: the top and bottom along the grain, the cuts as end grain.
	var c := Vector2(0.0, 0.0)
	for p in pts:
		c += p / pts.size()
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var e := b - a
		var along_grain := absf(e.normalized().dot(Vector2(GOING, STEP_RISE).normalized())) > 0.95
		var n2 := Vector2(e.y, -e.x).normalized()
		if n2.dot((a + b) * 0.5 - c) < 0.0:
			n2 = -n2
		var n := Vector3(0, n2.y, n2.x)
		var size := Vector2(e.length(), x1 - x0)
		_quad(st, Vector3((x0 + x1) * 0.5, (a.y + b.y) * 0.5, (a.x + b.x) * 0.5), Vector3(0, e.y, e.x), Vector3(x1 - x0, 0, 0), n,
				size, u0 if along_grain else 0.0, flag if along_grain else Color(1.0, 0.0, 0.0, 1.0))
	if not boards.has(wood):
		boards[wood] = []
	boards[wood].append({"part": &"oak_strings", "size": Vector3(long, depth, x1 - x0), "strip": pick})
	# Its collision: one box along the slope through the outline's middle, 300 deep.
	var perp := dir.cross(Vector3(1, 0, 0)).normalized()
	_solid_box(&"oak_strings", Vector3((x0 + x1) * 0.5, c.y, c.x), dir, perp, Vector3(1, 0, 0),
			Vector3(long, depth / sqrt(1.0 + pow(STEP_RISE / GOING, 2.0)), x1 - x0))


## The newels, balusters and rail: turned oak.
func _balustrade() -> void:
	var nz := NEWEL.y
	var foot := STEP_RISE
	var rail_at_newel := pitch_y(nz) + RAIL_H
	_newel(Vector3(NEWEL.x, foot, nz), rail_at_newel + 0.16 - foot)
	var top_z := (RISERS - 1) * GOING - NOSE + 0.04
	var ly := landing_y()
	_newel(Vector3(-0.02, ly - 0.35, top_z), LANDING_RAIL_H + 0.35 + 0.16)
	var end_z := top_z + LANDING_DEPTH - 0.1
	_newel(Vector3(-0.02, ly - 0.35, end_z), LANDING_RAIL_H + 0.35 + 0.16)
	# Two balusters a tread on the cut string's line, from the tread to under the rail.
	for i in range(1, RISERS - 1):
		for k in 2:
			var z := i * GOING + 0.06 + k * GOING * 0.5
			var y0 := (i + 1) * STEP_RISE
			_baluster(Vector3(0.035, y0, z), pitch_y(z) + RAIL_H - 0.035 - y0)
	var z := top_z + 0.14
	while z < end_z - 0.08:
		_baluster(Vector3(-0.02, ly, z), LANDING_RAIL_H - 0.035)
		z += 0.13
	# The rail: up the flight from newel to newel, then along the landing.
	_rail(Vector3(NEWEL.x, rail_at_newel, nz), Vector3(0.0, pitch_y(top_z) + RAIL_H, top_z))
	_rail(Vector3(-0.02, ly + LANDING_RAIL_H, top_z), Vector3(-0.02, ly + LANDING_RAIL_H, end_z))


## A newel: a square panelled foot, a turned shaft with rings, a square cap and a ball.
func _newel(at: Vector3, h: float) -> void:
	var base := minf(0.42, h * 0.35)
	_board(&"oak_newels", at + Vector3(0, base * 0.5, 0), Vector3(0, 1, 0), Vector3(0, 0, 1), base, 0.16, 0.16)
	var s := h - base - 0.2
	var shaft := PropModels.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.07, 0), Vector2(0.07, 0.04), Vector2(0.055, 0.07),
			Vector2(0.06, s * 0.3), Vector2(0.075, s * 0.34), Vector2(0.06, s * 0.38), Vector2(0.05, s * 0.8), Vector2(0.065, s * 0.9),
			Vector2(0.07, s), Vector2(0, s)]), 20, true)
	_turned(&"oak_newels", shaft, Transform3D(Basis(), at + Vector3(0, base, 0)), 1)
	_board(&"oak_newels", at + Vector3(0, base + s + 0.03, 0), Vector3(1, 0, 0), Vector3(0, 1, 0), 0.19, 0.19, 0.06, Vector3(0, 0, 1))
	var ball := PropModels.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.03, 0), Vector2(0.03, 0.025), Vector2(0.055, 0.05),
			Vector2(0.06, 0.08), Vector2(0.05, 0.115), Vector2(0.025, 0.135), Vector2(0, 0.14)]), 20, true)
	_turned(&"oak_newels", ball, Transform3D(Basis(), at + Vector3(0, base + s + 0.06, 0)), 2)


## A turned baluster of height h: square-ish feet turned round, a vase, rings, a slender neck.
func _baluster(at: Vector3, h: float) -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(0.02, 0), Vector2(0.02, 0.1), Vector2(0.013, 0.12), Vector2(0.019, 0.17),
			Vector2(0.021, 0.26), Vector2(0.012, h * 0.55), Vector2(0.017, h * 0.58), Vector2(0.012, h * 0.61),
			Vector2(0.01, h - 0.14), Vector2(0.018, h - 0.12), Vector2(0.018, h), Vector2(0, h)])
	_turned(&"oak_balusters", PropModels.lathe(p, 10, true), Transform3D(Basis(), at), int(at.z * 37.0))


## The handrail between two points (its top line): a 70 x 60 rail on a narrower 45 x 25 sub-rail
## the balusters meet, each a board with end grain at its cut ends. (A turned round rail wrapped its
## strip round and read as rope, the first render.)
func _rail(a: Vector3, b: Vector3) -> void:
	var along := (b - a).normalized()
	var side := Vector3(1, 0, 0) if absf(along.x) < 0.9 else Vector3(0, 0, 1)
	side = (side - along * side.dot(along)).normalized()
	var up := side.cross(along).normalized()
	if up.y < 0.0:
		up = -up
	var l := a.distance_to(b)
	_board(&"oak_rail", (a + b) * 0.5 - up * 0.03, along, up, l, 0.07, 0.06, side)
	_board(&"oak_rail", (a + b) * 0.5 - up * 0.072, along, up, l, 0.045, 0.025, side)


## The runner up the middle of the flight (over each tread and down each riser), a brass rod at the
## back of each tread.
func _runner() -> void:
	var holder := _holder(&"oak_runner")
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0 := (WIDTH - RUNNER_W) * 0.5
	var x1 := x0 + RUNNER_W
	var rods := _holder(&"oak_rods")
	var brass := PixelArt.material(PixelArt.factory("prop_brass"), Color.WHITE, PixelArt.Mapping.UV, Vector3.ZERO, 0.45, 0.6, 0.6)
	for i in RISERS - 1:
		var top := (i + 1) * STEP_RISE + 0.004
		var zf := i * GOING - NOSE - 0.004
		var zb := (i + 1) * GOING
		# Over the tread, down the nosing's face, down the riser.
		_flat(st, Vector3(x0, top, zb), Vector3(x1, top, zf), i * 0.3)
		_flat(st, Vector3(x0, top, zf), Vector3(x1, top - TREAD_T - 0.004, zf), i * 0.3 + 0.27)
		_flat(st, Vector3(x0, top - TREAD_T - 0.004, i * GOING - 0.004), Vector3(x1, i * STEP_RISE, i * GOING - 0.004), i * 0.3 + 0.3)
		var rod := PropModels.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.006, 0), Vector2(0.006, RUNNER_W + 0.08), Vector2(0, RUNNER_W + 0.08)]), 8, true)
		var mi := MeshInstance3D.new()
		mi.mesh = rod
		mi.material_override = brass
		rods.add_child(mi)
		mi.transform = Transform3D(Basis(Vector3(0, 0, 1), -PI * 0.5), Vector3(x0 - 0.04, top + 0.006, zb - 0.008))
	var mi := MeshInstance3D.new()
	mi.name = "runner"
	mi.mesh = st.commit()
	var tex := PixelArt.factory("stair_runner")
	mi.material_override = PixelArt.material(tex if tex else PixelArt.factory("prop_felt"), Color.WHITE if tex else Color(0.75, 0.25, 0.2),
			PixelArt.Mapping.UV, Vector3.ZERO, 1.0, 0.0, 0.05)
	holder.add_child(mi)


## A flat quad from corner a to corner c (the other two corners share a's x with c's y/z and so on),
## UVs in metres: u across the runner, v down its length from v0.
func _flat(st: SurfaceTool, a: Vector3, c: Vector3, v0: float) -> void:
	var b := Vector3(c.x, a.y, a.z)
	var d := Vector3(a.x, c.y, c.z)
	var n := (b - a).cross(d - a).normalized()
	if n.y < -0.1 or n.z > 0.1:
		n = -n
	var len := a.distance_to(d)
	var pts := [a, b, c, a, c, d]
	var uvs := [Vector2(0, v0), Vector2(RUNNER_W, v0), Vector2(RUNNER_W, v0 + len), Vector2(0, v0), Vector2(RUNNER_W, v0 + len), Vector2(0, v0 + len)]
	var order := [0, 1, 2, 3, 4, 5]
	if (b - a).cross(c - a).dot(n) > 0.0:
		order = [0, 2, 1, 3, 5, 4]
	for k in order:
		st.set_normal(n)
		st.set_uv(uvs[k])
		st.add_vertex(pts[k])


## A turned piece (PropModels.lathe, grain along it) in the part's wood, strip `pick`.
func _turned(part: StringName, mesh: Mesh, xf: Transform3D, pick: int) -> void:
	var wood := wood_for(part)
	var strips := maxi(WoodMaterials.strip_count(wood), 1)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = WoodMaterials.get_material(wood, posmod(pick, strips))
	_holder(part).add_child(mi)
	mi.transform = xf
	var bb := mesh.get_aabb()
	_solid_box(part, xf * bb.get_center(), xf.basis.x, xf.basis.y, xf.basis.z, bb.size)
	if not boards.has(wood):
		boards[wood] = []
	boards[wood].append({"part": part, "size": mesh.get_aabb().size, "strip": posmod(pick, strips)})
