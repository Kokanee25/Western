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
const NEWEL := Vector2(-0.14, 0.13)

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


func build() -> void:
	_rng.seed = seed_value
	_room()
	_flight()
	_landing()
	_strings()
	_flush()
	_balustrade()
	_runner()


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
	var len_z := (RISERS - 1) * GOING
	var a := Vector3(0, 0, -NOSE)
	var b := Vector3(0, landing_y() - STEP_RISE, len_z - NOSE)
	var along := (b - a).normalized()
	var up := along.cross(Vector3(1, 0, 0)).normalized()
	var mid := (a + b) * 0.5
	# The cut string under the open ends of the treads, the wall string against the wall, both
	# 300 mm deep; the soffit board under the flight between them.
	_board(&"oak_strings", mid + Vector3(-0.02, 0, 0) - up * 0.1, along, Vector3(1, 0, 0), a.distance_to(b), 0.3, 0.04, up)
	_board(&"oak_strings", mid + Vector3(WIDTH + 0.018, 0.08, 0), along, Vector3(1, 0, 0), a.distance_to(b) + 0.25, 0.33, 0.036, up)
	_board(&"oak_strings", mid + Vector3(WIDTH * 0.5, 0, 0) - up * 0.24, along, up, a.distance_to(b), WIDTH, 0.02, Vector3(1, 0, 0))


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
	if not boards.has(wood):
		boards[wood] = []
	boards[wood].append({"part": part, "size": mesh.get_aabb().size, "strip": posmod(pick, strips)})
