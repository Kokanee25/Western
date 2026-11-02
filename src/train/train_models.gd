class_name TrainModels
extends RefCounted
## The train's models (train step 3, docs/briefs/train.md): the engine and tender from Blender
## (EngineModel, assets/train/), the five cars built here of boards (MemberMesh boards in the
## game's woods, merged a material a car) with iron where a car has iron, and the trucks under
## them, their wheels turning with the distance (`roll_truck`). Each model sits on step 2's walk
## path (TrainCars: floors at 1.1 m, the coach's and express car's shells and doorways, the
## ore cars' sides, the boxcar's ladders and roof walk), so what you see is what you stand on.
##
##   ore      a drop-end gondola: plank sides on stakes, a low heap of ore (the mine's kind is
##            Sean's call, #552: grey-brown rock for now)
##   box      vertical sheathing painted red, a sliding door each side, ladders up each end, a
##            roof walk, the brake wheel on the roof
##   express  sheathing painted green, a sliding door each side, end platforms; inside the
##            strongbox, a mail case and parcels along the walls (the aisle clear)
##   coach    varnished oak, a row of windows each side, a clerestory roof, end platforms with
##            railings; inside benches both sides of the aisle (`seats`), a stove, two lamps
##
## Every car: sills, a plank deck past its ends, truss rods and queen posts, link-and-pin
## drawheads, corner stirrups. A car's frame is TrainCars': origin on the rail top midway between
## its trucks, -Z toward its front; `u` here is metres behind its front.

const DECK := TrainCars.DECK
const LIP := TrainCars.LIP
## The cars' trucks: wheels 26 in, 1.2 m between axles (arch-bar trucks).
const WHEEL_R := 0.33
const WHEELBASE := 1.2
## The coach's benches: pitch, seat height and depth, the aisle's half width.
const BENCH_PITCH := 0.85
const SEAT_H := 0.45
const AISLE := 0.33

static var _mats := {}


# --- materials -----------------------------------------------------------------------------------

static func _metal(key: String, colour: Color, seed: int, mottle: float, rough: float, metallic: float) -> Material:
	if not _mats.has(key):
		_mats[key] = PixelArt.material(PixelArt.metal("train_" + key, colour, seed, mottle), Color.WHITE,
			PixelArt.Mapping.TRIPLANAR, Vector3.ZERO, rough, metallic, 0.5)
	return _mats[key]


static func iron() -> Material:
	return _metal("iron", Color(0.11, 0.105, 0.1), 301, 0.6, 0.75, 0.35)


static func steel() -> Material:
	return _metal("steel", Color(0.42, 0.41, 0.4), 303, 0.4, 0.45, 0.7)


static func jacket() -> Material:  # Russia iron: the boiler's planished blue-grey sheet
	return _metal("jacket", Color(0.2, 0.24, 0.27), 305, 0.5, 0.4, 0.6)


static func brass() -> Material:
	return _metal("brass", PropModels.BRASS, 307, 0.3, 0.4, 0.6)


static func red() -> Material:  # the pilot, beams and the headlight's case: red lead over wood
	if not _mats.has("red"):
		_mats["red"] = PixelArt.material(PixelArt.painted("train_red", Color(0.44, 0.11, 0.06), Color(0.3, 0.2, 0.12), 309, 0.25),
			Color.WHITE, PixelArt.Mapping.TRIPLANAR)
	return _mats["red"]


static func coal() -> Material:
	if not _mats.has("coal"):
		_mats["coal"] = PixelArt.material(PixelArt.squares("train_coal", Color(0.06, 0.06, 0.065), 311, 0.5),
			Color.WHITE, PixelArt.Mapping.TRIPLANAR, Vector3.ZERO, 0.6)
	return _mats["coal"]


static func ore() -> Material:
	if not _mats.has("ore"):
		_mats["ore"] = PixelArt.material(PixelArt.squares("train_ore", Color(0.42, 0.36, 0.3), 313, 0.45),
			Color.WHITE, PixelArt.Mapping.TRIPLANAR)
	return _mats["ore"]


## A game wood (WoodMaterials) laid on a mesh's own space (no UVs: Blender's parts).
static func wood_tri(wood: StringName) -> Material:
	var key := "tri_" + wood
	if not _mats.has(key):
		var m := (WoodMaterials.get_material(wood, 0) as ShaderMaterial).duplicate() as ShaderMaterial
		m.set_shader_parameter(&"mapping", PixelArt.Mapping.TRIPLANAR)
		_mats[key] = m
	return _mats[key]


static func lamp() -> Material:
	if not _mats.has("lamp"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1.0, 0.85, 0.55)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.75, 0.4)
		m.emission_energy_multiplier = 0.4
		_mats["lamp"] = m
	return _mats["lamp"]


static func glass() -> Material:
	if not _mats.has("glass"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.16, 0.19, 0.19, 0.35)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.metallic = 0.4
		m.roughness = 0.08
		_mats["glass"] = m
	return _mats["glass"]


## The game's look on a Blender part, by its material's name (engine.py's names).
static func dress(mi: MeshInstance3D) -> void:
	var mesh := mi.mesh
	for i in mesh.get_surface_count():
		var src := mesh.surface_get_material(i)
		var name := String(src.resource_name) if src else ""
		var m: Material
		match name:
			"iron": m = iron()
			"jacket": m = jacket()
			"brass": m = brass()
			"red": m = red()
			"wood": m = wood_tri(&"dark_oak")
			"steel": m = steel()
			"coal": m = coal()
			"lamp": m = lamp()
			"glass": m = glass()
			_: m = iron()
		mi.set_surface_override_material(i, m)


# --- building ------------------------------------------------------------------------------------

## Parts gathered a material each, then drawn as one mesh a material.
class Build:
	var mid := 0.0
	var tools := {}  # key -> SurfaceTool
	var mats := {}  # key -> Material
	var rng := RandomNumberGenerator.new()
	var _cyls := {}  # sides -> a unit CylinderMesh
	var _box: BoxMesh

	func z(u: float) -> float:
		return u - mid

	func _tool(key: String, mat: Material) -> SurfaceTool:
		if not tools.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[key] = st
			mats[key] = mat
		return tools[key]

	## A board of a game wood from u0..u1 behind the front, x0..x1 across, y0..y1 up (its grain
	## along its longest side). `v` picks one of the wood's boards (its strips).
	func board(wood: StringName, u0: float, u1: float, x0: float, x1: float, y0: float, y1: float, v := -1) -> void:
		var variant := v if v >= 0 else rng.randi_range(0, 7)
		var n := WoodMaterials.strip_count(wood)
		variant = posmod(variant, n) if n > 0 else posmod(variant, 3)
		var mat := WoodMaterials.get_material(wood, variant)
		var size := Vector3(absf(x1 - x0), absf(y1 - y0), absf(u1 - u0))
		var at := Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, z((u0 + u1) * 0.5))
		_tool("w:%s:%d" % [wood, variant], mat).append_from(MemberMesh.box(size), 0, Transform3D(Basis.IDENTITY, at))

	## A box of a mapped-in-its-own-space material (iron, paint, ore).
	func block(key: String, mat: Material, u0: float, u1: float, x0: float, x1: float, y0: float, y1: float,
			basis := Basis.IDENTITY) -> void:
		if _box == null:
			_box = BoxMesh.new()
		var size := Vector3(absf(x1 - x0), absf(y1 - y0), absf(u1 - u0))
		var at := Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, z((u0 + u1) * 0.5))
		_tool("m:" + key, mat).append_from(_box, 0, Transform3D(basis * Basis.from_scale(size), at))

	## A round bar from a to b (game points in the car's frame), radius r.
	func rod(key: String, mat: Material, a: Vector3, b: Vector3, r: float, sides := 8) -> void:
		if not _cyls.has(sides):
			var c := CylinderMesh.new()
			c.radial_segments = sides
			c.rings = 1
			c.height = 1.0
			c.top_radius = 1.0
			c.bottom_radius = 1.0
			_cyls[sides] = c
		var d := b - a
		var basis := Basis(Quaternion(Vector3.UP, d.normalized())) if d.normalized().cross(Vector3.UP).length() > 0.001 \
			else (Basis.IDENTITY if d.y > 0.0 else Basis(Vector3.RIGHT, PI))
		basis = basis * Basis.from_scale(Vector3(r, d.length(), r))
		_tool("c:" + key, mat).append_from(_cyls[sides], 0, Transform3D(basis, (a + b) * 0.5))

	func done(name: String) -> Node3D:
		var root := Node3D.new()
		root.name = name
		for key: String in tools:
			var st: SurfaceTool = tools[key]
			var mi := MeshInstance3D.new()
			mi.name = key.replace(":", "_")
			mi.mesh = st.commit()
			mi.material_override = mats[key]
			root.add_child(mi)
		return root


## The model of car `car` (TrainSim.cars[i]).
static func car(car: Dictionary, t: TrainTuning) -> Node3D:
	var kind: StringName = car.kind
	if kind == &"engine":
		var e := EngineModel.new()
		e.name = "Model"
		return e
	if kind == &"tender":
		var root: Node3D = (load("res://assets/train/tender.glb") as PackedScene).instantiate()
		root.name = "Model"
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			dress(mi as MeshInstance3D)
		return root
	var b := Build.new()
	var tr: Vector2 = car.trucks
	b.mid = (tr.x + tr.y) * 0.5
	b.rng.seed = hash(String(car.name))
	var l: float = car.length
	var w := t.car_width * 0.5
	_underframe(b, l, w)
	match kind:
		&"ore": _ore(b, l, w)
		&"box": _box_car(b, l, w)
		&"express": _shell(b, l, w, &"painted_green", false)
		&"coach": _shell(b, l, w, &"dark_oak", true)
	var m := b.done("Model")
	if kind == &"coach":
		_coach_lamps(m, b, l)
	return m


static func _underframe(b: Build, l: float, w: float) -> void:
	# The sills: two at the sides, two in the middle; the end sills across.
	for s: float in [-1.0, 1.0]:
		b.board(&"framing", 0.0, l, s * (w - 0.13), s * w, 0.8, DECK - 0.05)
		b.board(&"framing", 0.0, l, s * 0.2, s * 0.33, 0.8, DECK - 0.05)
	for u in [0.0, l - 0.22]:
		b.board(&"framing", u, u + 0.22, -w, w, 0.75, DECK - 0.05)
	# The deck: planks along the car, past each end.
	var n := int(ceil(2.0 * w / 0.16))
	for k in n:
		var x0 := -w + 2.0 * w * k / n
		b.board(&"floor", -LIP, l + LIP, x0, x0 + 2.0 * w / n - 0.004, DECK - 0.05, DECK)
	# Truss rods under, on queen posts; the drawheads; a stirrup at each corner.
	var ir := iron()
	for s: float in [-1.0, 1.0]:
		var x: float = s * 0.55
		var pts := [Vector3(x, 0.9, b.z(0.25)), Vector3(x, 0.42, b.z(l * 0.34)), Vector3(x, 0.42, b.z(l * 0.66)),
			Vector3(x, 0.9, b.z(l - 0.25))]
		for k in 3:
			b.rod("iron", ir, pts[k], pts[k + 1], 0.018, 6)
		for u in [l * 0.34, l * 0.66]:
			b.block("iron", ir, u - 0.05, u + 0.05, x - 0.05, x + 0.05, 0.42, 0.8)
	for end in [[-0.3, 0.0], [l, l + 0.3]]:
		b.block("iron", ir, end[0], end[1], -0.1, 0.1, 0.58, 0.76)
	b.rod("iron", ir, Vector3(0, 0.67, b.z(-0.28)), Vector3(0, 0.67, b.z(-0.5)), 0.03, 6)  # the link
	for u in [0.3, l - 0.3]:
		for s: float in [-1.0, 1.0]:
			b.block("iron", ir, u - 0.17, u + 0.17, s * (w - 0.02), s * (w + 0.03), 0.5, 0.53)
			for du in [-0.16, 0.16]:
				b.block("iron", ir, u + du - 0.015, u + du + 0.015, s * (w - 0.02), s * (w + 0.03), 0.5, 0.82)


static func _ore(b: Build, l: float, w: float) -> void:
	# The sides: three planks on the inside of stakes (TrainCars: x w-0.1..w, 0.6 high).
	for s: float in [-1.0, 1.0]:
		for k in 3:
			b.board(&"weathered_pine", -LIP, l + LIP, s * (w - 0.1), s * (w - 0.04), DECK + 0.2 * k, DECK + 0.2 * k + 0.195)
		var stakes := int(round(l / 1.2))
		for k in stakes + 1:
			var u := -LIP + 0.1 + (l + 2.0 * LIP - 0.2) * k / stakes
			b.board(&"framing", u - 0.05, u + 0.05, s * (w - 0.04), s * (w + 0.04), 0.82, DECK + 0.62)
		b.block("iron", iron(), -LIP, l + LIP, s * (w - 0.1), s * (w + 0.04), DECK + 0.6, DECK + 0.62)
	# The brake staff and wheel at the back.
	b.rod("iron", iron(), Vector3(0.75, 0.6, b.z(l + 0.08)), Vector3(0.75, DECK + 0.95, b.z(l + 0.08)), 0.02, 6)
	b.rod("iron", iron(), Vector3(0.75, DECK + 0.95, b.z(l + 0.08)), Vector3(0.75, DECK + 0.97, b.z(l + 0.08)), 0.2, 12)
	# The ore: a low heap of rock (a walker's feet sink a hand's depth into it).
	var o := ore()
	for k in 70:
		var u := b.rng.randf_range(0.3, l - 0.3)
		var x := b.rng.randf_range(-w + 0.25, w - 0.25)
		var rise := 0.16 * (1.0 - absf(x) / w) * minf(1.0, minf(u, l - u) / 1.2)
		var size := b.rng.randf_range(0.12, 0.26)
		var basis := Basis.from_euler(Vector3(b.rng.randf() * TAU, b.rng.randf() * TAU, b.rng.randf() * TAU))
		b.block("ore", o, u - size * 0.5, u + size * 0.5, x - size * 0.6, x + size * 0.6, DECK - size * 0.3 + rise,
			DECK + size * 0.5 + rise, basis)


## Sheathing: boards on end across `x0..x1` (a side at x, facing out) or along (an end).
static func _sheath_side(b: Build, wood: StringName, s: float, x: float, u0: float, u1: float, y0: float, y1: float,
		width := 0.13) -> void:
	var n := maxi(1, int(round((u1 - u0) / width)))
	for k in n:
		var a := u0 + (u1 - u0) * k / n
		b.board(wood, a, a + (u1 - u0) / n - 0.006, s * (x - 0.03), s * x, y0, y1)


static func _sheath_end(b: Build, wood: StringName, u: float, face: float, x0: float, x1: float, y0: float, y1: float,
		width := 0.13) -> void:
	var n := maxi(1, int(round((x1 - x0) / width)))
	for k in n:
		var a := x0 + (x1 - x0) * k / n
		b.board(wood, u, u + face, a, a + (x1 - x0) / n - 0.006, y0, y1)


static func _box_car(b: Build, l: float, w: float) -> void:
	var roof := DECK + 2.0
	var red_w := &"painted_red"
	for s: float in [-1.0, 1.0]:
		_sheath_side(b, red_w, s, w, 0.0, l, DECK - 0.05, roof - 0.06)
		# The sliding door: boards a little proud, braced, on its iron track.
		var d0 := l * 0.5 - 0.8
		var d1 := l * 0.5 + 0.8
		_sheath_side(b, red_w, s, w + 0.035, d0, d1, DECK + 0.02, DECK + 1.85, 0.16)
		b.board(red_w, d0, d1, s * (w + 0.035), s * (w + 0.06), DECK + 0.02, DECK + 0.14)
		b.board(red_w, d0, d1, s * (w + 0.035), s * (w + 0.06), DECK + 1.73, DECK + 1.85)
		b.block("iron", iron(), d0 - 0.8, d1 + 0.8, s * (w + 0.0), s * (w + 0.07), DECK + 1.88, DECK + 1.93)
		b.block("iron", iron(), d0 - 0.8, d1 + 0.8, s * (w + 0.0), s * (w + 0.05), DECK - 0.04, DECK + 0.0)
		# The corner posts' iron.
		for u in [0.0, l - 0.05]:
			b.block("iron", iron(), u, u + 0.05, s * (w - 0.04), s * (w + 0.01), DECK, roof - 0.05)
	for e in [[0.0, 1.0], [l, -1.0]]:
		_sheath_end(b, red_w, e[0], 0.03 * e[1], -w, w, DECK - 0.05, roof - 0.06)
	# The roof: boards across over an overhang, the roof walk along its top (TrainCars' roof is at
	# `roof`: the walk's top).
	var n := int(round(l / 0.3))
	for k in n:
		var u := -0.06 + (l + 0.12) * k / n
		b.board(&"dark_trim", u, u + (l + 0.12) / n - 0.008, -w - 0.08, w + 0.08, roof - 0.08, roof - 0.04)
	for x in [-0.25, 0.0, 0.25]:
		b.board(&"weathered_pine", -0.05, l + 0.05, x - 0.12, x + 0.12, roof - 0.04, roof)
	for k in 6:  # the walk's saddles
		var u := 0.2 + (l - 0.4) * k / 5.0
		b.board(&"framing", u - 0.04, u + 0.04, -0.4, 0.4, roof - 0.05, roof - 0.035)
	# The ladders: iron rungs on stiles up each end (the walk path's Ladder, TrainCars).
	for e in [[0.0, -1.0], [l, 1.0]]:
		var face: float = e[1]
		var uz: float = e[0] + face * 0.06
		for s: float in [-1.0, 1.0]:
			b.block("iron", iron(), uz - 0.02, uz + 0.02, s * 0.24, s * 0.26, DECK + 0.05, roof + 0.02)
		var y := DECK + 0.3
		while y < roof - 0.05:
			b.rod("iron", iron(), Vector3(-0.25, y, b.z(uz)), Vector3(0.25, y, b.z(uz)), 0.016, 6)
			y += 0.3
		b.rod("iron", iron(), Vector3(-0.25, roof + 0.25, b.z(uz)), Vector3(0.25, roof + 0.25, b.z(uz)), 0.016, 6)
	# The brake: a staff up the back end beside the ladder, its wheel over the roof.
	b.rod("iron", iron(), Vector3(0.75, 0.6, b.z(l + 0.07)), Vector3(0.75, roof + 0.35, b.z(l + 0.07)), 0.02, 6)
	b.rod("iron", iron(), Vector3(0.75, roof + 0.35, b.z(l + 0.07)), Vector3(0.75, roof + 0.37, b.z(l + 0.07)), 0.22, 12)


## The coach and the express car: a shell over end platforms (TrainCars: walls from `plat` to
## `l - plat`, 2.3 m high, a doorway 0.9 wide and 2.0 high in each end, a roof over).
static func _shell(b: Build, l: float, w: float, wood: StringName, coach: bool) -> void:
	var plat := 0.9
	var h := 2.3
	var top := DECK + h
	var u0 := plat
	var u1 := l - plat
	for s: float in [-1.0, 1.0]:
		if coach:
			_coach_side(b, wood, s, w, u0, u1, top)
		else:
			_sheath_side(b, wood, s, w, u0, u1, DECK - 0.05, top)
			var d0 := l * 0.5 - 0.7
			var d1 := l * 0.5 + 0.7
			_sheath_side(b, wood, s, w + 0.035, d0, d1, DECK + 0.02, DECK + 1.9, 0.16)
			b.block("iron", iron(), d0 - 0.7, d1 + 0.7, s * w, s * (w + 0.07), DECK + 1.93, DECK + 1.98)
			# Two small barred windows, high up.
			for u in [u0 + 1.2, u1 - 1.2]:
				b.block("glass", glass(), u - 0.3, u + 0.3, s * (w + 0.002), s * (w + 0.004), DECK + 1.4, DECK + 1.8)
				for k in 4:
					var x: float = u - 0.22 + 0.147 * k
					b.rod("iron", iron(), Vector3(s * (w + 0.02), DECK + 1.4, b.z(x)), Vector3(s * (w + 0.02), DECK + 1.8, b.z(x)), 0.01, 4)
		# Inside: the walls' boards facing in.
		_sheath_side(b, &"int_oak" if coach else &"int_boards", -s, -(w - 0.08), u0, u1, DECK, top - 0.02, 0.16)
	# The end walls, a doorway in each (the walk's), framed; the door stands open inward.
	for e in [[u0, 1.0], [u1 - 0.08, -1.0]]:
		var u: float = e[0]
		_sheath_end(b, wood, u, 0.08, -w, -0.45, DECK, top)
		_sheath_end(b, wood, u, 0.08, 0.45, w, DECK, top)
		b.board(wood, u, u + 0.08, -0.45, 0.45, DECK + 2.0, top)
		for x in [-0.5, 0.45]:
			b.board(&"dark_trim", u - 0.01, u + 0.09, x, x + 0.05, DECK, DECK + 2.0)
		b.board(&"dark_trim", u - 0.01, u + 0.09, -0.5, 0.5, DECK + 1.97, DECK + 2.05)
		var inward: float = e[1]
		var hinge := Vector3(0.45, DECK, b.z(u + (0.08 if inward > 0.0 else 0.0)))
		b.board(wood, u + (0.08 if inward > 0.0 else -0.85), u + (0.88 if inward > 0.0 else 0.0), 0.42, 0.46, DECK + 0.02, DECK + 1.96)
	# The roof: over the platforms, an arch (express) or a clerestory (coach); boards under it inside.
	var r0 := plat - 0.3
	var r1 := l - plat + 0.3
	b.board(&"int_boards", u0, u1, -w + 0.08, w - 0.08, top - 0.02, top)
	if coach:
		for s: float in [-1.0, 1.0]:
			_slope(b, &"dark_trim", r0, r1, Vector2(s * (w + 0.1), top + 0.02), Vector2(s * 0.62, top + 0.14))
			b.board(wood, r0 + 0.4, r1 - 0.4, s * 0.62, s * 0.66, top + 0.1, top + 0.42)
			var k := 0.0
			while r0 + 0.8 + k < r1 - 0.8:
				b.block("glass", glass(), r0 + 0.8 + k, r0 + 1.1 + k, s * 0.665, s * 0.667, top + 0.17, top + 0.36)
				k += 0.6
		b.board(&"dark_trim", r0 + 0.2, r1 - 0.2, -0.72, 0.72, top + 0.42, top + 0.47)
	else:
		for s: float in [-1.0, 1.0]:
			_slope(b, &"dark_trim", r0, r1, Vector2(s * (w + 0.1), top + 0.02), Vector2(s * 0.55, top + 0.16))
		b.board(&"dark_trim", r0, r1, -0.56, 0.56, top + 0.14, top + 0.19)
	# The platforms: a railing across each end (open in the middle to cross, at the sides for the
	# steps), posts at the corners, two steps down at each corner.
	for e in [[-LIP + 0.04, 1.0], [l + LIP - 0.04, -1.0]]:
		var u: float = e[0]
		for s: float in [-1.0, 1.0]:
			b.rod("iron", iron(), Vector3(s * 0.45, DECK, b.z(u)), Vector3(s * 0.45, DECK + 1.0, b.z(u)), 0.02, 6)
			b.rod("iron", iron(), Vector3(s * (w - 0.35), DECK, b.z(u)), Vector3(s * (w - 0.35), DECK + 1.0, b.z(u)), 0.02, 6)
			b.rod("iron", iron(), Vector3(s * 0.45, DECK + 1.0, b.z(u)), Vector3(s * (w - 0.35), DECK + 1.0, b.z(u)), 0.018, 6)
			b.rod("iron", iron(), Vector3(s * 0.45, DECK + 0.55, b.z(u)), Vector3(s * (w - 0.35), DECK + 0.55, b.z(u)), 0.014, 6)
			# Posts holding the roof's overhang at the platform's outer corners.
			var cu := (r0 if e[1] > 0.0 else r1)
			b.rod("iron", iron(), Vector3(s * (w - 0.05), DECK, b.z(cu)), Vector3(s * (w - 0.05), top, b.z(cu)), 0.025, 6)
			var step_u: float = u + e[1] * 0.25
			for k in 2:
				b.board(&"framing", step_u - 0.22, step_u + 0.22, s * (w - 0.3), s * (w + 0.05 + 0.12 * k),
					DECK - 0.35 * (k + 1) - 0.04, DECK - 0.35 * (k + 1))
			b.block("iron", iron(), step_u - 0.23, step_u - 0.2, s * (w - 0.3), s * (w + 0.18), DECK - 0.75, DECK)
			b.block("iron", iron(), step_u + 0.2, step_u + 0.23, s * (w - 0.3), s * (w + 0.18), DECK - 0.75, DECK)
	if coach:
		_coach_inside(b, l, w, u0, u1, top)
	else:
		_express_inside(b, l, w, u0, u1)


## A sloping run of roof boards from a to b (x, y), along u0..u1.
static func _slope(b: Build, wood: StringName, u0: float, u1: float, a: Vector2, c: Vector2) -> void:
	var d := c - a
	var basis := Basis(Vector3.BACK, atan2(d.y, d.x))
	var mid := (a + c) * 0.5
	var size := Vector3(d.length(), 0.04, u1 - u0)
	var mat := WoodMaterials.get_material(wood, 0)
	b._tool("w:%s:slope" % wood, mat).append_from(MemberMesh.box(size), 0,
		Transform3D(basis, Vector3(mid.x, mid.y, b.z((u0 + u1) * 0.5))))


static func _coach_side(b: Build, wood: StringName, s: float, w: float, u0: float, u1: float, top: float) -> void:
	# Below the windows battens (narrow boards upright), a belt rail, the windows in their posts,
	# a letter board over them.
	var sill := DECK + 0.85
	var head := DECK + 1.65
	_sheath_side(b, wood, s, w, u0, u1, DECK - 0.1, sill, 0.07)
	b.board(&"dark_trim", u0, u1, s * w, s * (w + 0.025), sill - 0.06, sill)
	b.board(wood, u0, u1, s * (w - 0.03), s * w, head, top)
	b.board(&"dark_trim", u0, u1, s * w, s * (w + 0.02), head + 0.1, head + 0.36)
	var n := int(round((u1 - u0) / 0.85))
	var pitch := (u1 - u0) / n
	for k in n:
		var a := u0 + pitch * k
		b.board(wood, a, a + 0.24, s * (w - 0.03), s * w, sill, head)
		b.block("glass", glass(), a + 0.24, a + pitch, s * (w - 0.025), s * (w - 0.02), sill, head)
		b.board(&"dark_trim", a + 0.24, a + pitch, s * (w - 0.03), s * (w + 0.005), head - 0.04, head)
	b.board(wood, u1 - 0.02, u1, s * (w - 0.03), s * w, sill, head)


static func _coach_inside(b: Build, l: float, w: float, u0: float, u1: float, top: float) -> void:
	b.board(&"int_floor", u0, u1, -w + 0.08, w - 0.08, DECK, DECK + 0.01)
	# The benches: a double each side of the aisle a row, facing forward (walkover backs set
	# for the front), on iron standards.
	for seat: Transform3D in seat_rows(l, w):
		var u := seat.origin.z  # seat_rows gives u (metres behind the front) as z
		var s := signf(seat.origin.x)
		var x0 := s * AISLE
		var x1 := s * (w - 0.1)
		b.board(&"int_oak_light", u - 0.22, u + 0.22, x0, x1, DECK + SEAT_H - 0.05, DECK + SEAT_H)
		b.board(&"int_oak_light", u + 0.22, u + 0.26, x0, x1, DECK + SEAT_H, DECK + SEAT_H + 0.45)
		b.board(&"int_oak", u - 0.2, u + 0.24, x0, x1, DECK + SEAT_H - 0.12, DECK + SEAT_H - 0.05)
		b.block("iron", iron(), u - 0.2, u + 0.22, x0 - s * 0.01, x0 + s * 0.04, DECK, DECK + SEAT_H - 0.05)
	# The stove at the front, by the left wall, its pipe through the roof.
	var su := u0 + 0.45
	b.rod("stove", iron(), Vector3(-0.7, DECK, b.z(su)), Vector3(-0.7, DECK + 0.8, b.z(su)), 0.22, 12)
	b.rod("stove", iron(), Vector3(-0.7, DECK + 0.8, b.z(su)), Vector3(-0.7, top + 0.6, b.z(su)), 0.07, 8)
	b.block("iron", iron(), su - 0.3, su + 0.3, -1.0, -0.4, DECK, DECK + 0.03)


## The coach's bench seats (each bench's middle on its seat), as Transform3Ds whose z is `u` (m
## behind the car's front; `seats` puts them in the car's frame), two benches a row.
static func seat_rows(l: float, w: float) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var u0 := 0.9 + 0.75  # past the stove
	var u1 := l - 0.9 - 0.35
	var n := int(floor((u1 - u0) / BENCH_PITCH))
	for k in n:
		var u := u0 + BENCH_PITCH * (k + 0.5)
		for s: float in [-1.0, 1.0]:
			out.append(Transform3D(Basis.IDENTITY, Vector3(s * (AISLE + w - 0.1) * 0.5, DECK + SEAT_H, u)))
	return out


## The coach's seats in its frame (`car` as TrainSim.cars[i]), for passengers.
static func seats(car: Dictionary, t: TrainTuning) -> Array[Transform3D]:
	var tr: Vector2 = car.trucks
	var mid := (tr.x + tr.y) * 0.5
	var out: Array[Transform3D] = []
	for s: Transform3D in seat_rows(car.length, t.car_width * 0.5):
		# Two places a bench: the window's, then the aisle's.
		for dx: float in [0.18, -0.18]:
			out.append(Transform3D(Basis.IDENTITY, s.origin + Vector3(signf(s.origin.x) * dx, 0.0, -mid)))
	return out


static func _express_inside(b: Build, l: float, w: float, u0: float, u1: float) -> void:
	b.board(&"int_r1_floor", u0, u1, -w + 0.08, w - 0.08, DECK, DECK + 0.01)
	# The strongbox (iron, brass lock) against the right wall at the front; a mail case of
	# pigeonholes on the left wall; parcels and sacks along the walls; the aisle clear.
	var sb := u0 + 0.5
	b.block("iron", iron(), sb - 0.35, sb + 0.35, 0.55, 1.05, DECK, DECK + 0.6)
	b.block("brass", brass(), sb - 0.06, sb + 0.06, 0.53, 0.55, DECK + 0.35, DECK + 0.47)
	for s: float in [-1.0, 1.0]:
		b.block("iron", iron(), sb - 0.36, sb + 0.36, 0.54, 1.06, DECK + 0.1 + 0.4 * (s + 1.0) * 0.5, DECK + 0.14 + 0.4 * (s + 1.0) * 0.5)
	var mc := u1 - 2.0
	b.board(&"int_oak", mc, mc + 1.4, -1.05, -0.7, DECK + 0.8, DECK + 0.83)
	for k in 6:
		b.board(&"int_oak", mc + 0.28 * k, mc + 0.28 * k + 0.02, -1.05, -0.7, DECK + 0.83, DECK + 1.9)
	for k in 5:
		b.board(&"int_oak", mc, mc + 1.42, -1.05, -0.7, DECK + 0.83 + 0.27 * k, DECK + 0.85 + 0.27 * k)
	b.board(&"int_oak", mc, mc + 1.42, -1.05, -0.55, DECK + 0.78, DECK + 0.82)  # the desk
	for k in 7:
		var u := b.rng.randf_range(u0 + 1.2, u1 - 2.2)
		var s := 1.0 if k % 2 == 0 else -1.0
		var sz := Vector3(b.rng.randf_range(0.3, 0.55), b.rng.randf_range(0.2, 0.45), b.rng.randf_range(0.3, 0.6))
		b.board(&"store_boards", u, u + sz.z, s * (w - 0.1 - sz.x), s * (w - 0.1), DECK, DECK + sz.y)


static func _coach_lamps(m: Node3D, b: Build, l: float) -> void:
	for u in [l * 0.33, l * 0.67]:
		var at := Vector3(0.0, DECK + 1.95, b.z(u))
		var mi := MeshInstance3D.new()
		var lm := SphereMesh.new()
		lm.radius = 0.07
		lm.height = 0.18
		mi.mesh = lm
		mi.material_override = lamp()
		mi.position = at
		m.add_child(mi)
		var cap := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.04
		cm.bottom_radius = 0.12
		cm.height = 0.08
		cap.mesh = cm
		cap.material_override = brass()
		cap.position = at + Vector3.UP * 0.12
		m.add_child(cap)
		var light := OmniLight3D.new()
		light.name = "Lamp"
		light.light_color = Color(1.0, 0.72, 0.4)
		light.omni_range = 4.5
		light.light_energy = 0.0
		light.visible = false
		light.position = at - Vector3.UP * 0.1
		light.add_to_group(&"train_lamps")
		m.add_child(light)


## A truck: two wheelsets (26 in, turning by `roll_truck`) in arch-bar side frames, the bolster.
static func truck(t: TrainTuning) -> Node3D:
	var b := Build.new()
	var gx := t.gauge * 0.5
	var ir := iron()
	for s: float in [-1.0, 1.0]:
		var x: float = s * (gx + 0.17)
		for z in [-WHEELBASE * 0.5, WHEELBASE * 0.5]:
			b.block("iron", ir, z - 0.12, z + 0.12, x - 0.08, x + 0.08, WHEEL_R - 0.09, WHEEL_R + 0.12)  # journal box
		# The arch bars: the top one rising over the bolster, the bottom one straight.
		var top := [Vector3(x, WHEEL_R + 0.12, -0.75), Vector3(x, WHEEL_R + 0.12, -0.45), Vector3(x, WHEEL_R + 0.3, -0.2),
			Vector3(x, WHEEL_R + 0.3, 0.2), Vector3(x, WHEEL_R + 0.12, 0.45), Vector3(x, WHEEL_R + 0.12, 0.75)]
		for k in 5:
			b.rod("iron", ir, top[k], top[k + 1], 0.03, 4)
		b.block("iron", ir, -0.62, 0.62, x - 0.03, x + 0.03, WHEEL_R - 0.12, WHEEL_R - 0.09)
		b.block("iron", ir, -0.2, 0.2, x - 0.06, x + 0.06, WHEEL_R - 0.09, WHEEL_R + 0.3)  # the spring pocket
	b.board(&"framing", -0.13, 0.13, -gx - 0.3, gx + 0.3, WHEEL_R + 0.3, WHEEL_R + 0.48)  # the bolster
	var root := b.done("Truck")
	var wheels: Array[Node3D] = []
	for z in [-WHEELBASE * 0.5, WHEELBASE * 0.5]:
		var ws := _wheelset(t)
		ws.position = Vector3(0.0, WHEEL_R, z)
		root.add_child(ws)
		wheels.append(ws)
	root.set_meta(&"wheels", wheels)
	return root


static var _wheelset_mesh: ArrayMesh


static func _wheelset(t: TrainTuning) -> Node3D:
	if _wheelset_mesh == null:
		var b := Build.new()
		var gx := t.gauge * 0.5
		for s: float in [-1.0, 1.0]:
			b.rod("steel", steel(), Vector3(s * (gx - 0.03), 0, 0), Vector3(s * (gx + 0.07), 0, 0), WHEEL_R, 20)
			b.rod("steel", steel(), Vector3(s * (gx - 0.04), 0, 0), Vector3(s * (gx - 0.02), 0, 0), WHEEL_R + 0.025, 20)
			# The plate's ribs, so it can be seen to turn.
			for k in 4:
				var a := TAU * k / 4.0
				b.block("iron", iron(), -0.03, 0.03, s * (gx + 0.07), s * (gx + 0.085), -WHEEL_R * 0.8, WHEEL_R * 0.8,
					Basis(Vector3.RIGHT, a))
			b.rod("steel", iron(), Vector3(s * (gx + 0.07), 0, 0), Vector3(s * (gx + 0.12), 0, 0), 0.08, 10)
		b.rod("steel", iron(), Vector3(-gx, 0, 0), Vector3(gx, 0, 0), 0.06, 8)
		var n := b.done("Wheelset")
		var am := ArrayMesh.new()
		for mi: MeshInstance3D in n.get_children():
			var src := mi.mesh as ArrayMesh
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, src.surface_get_arrays(0))
			am.surface_set_material(am.get_surface_count() - 1, mi.material_override)
		n.free()
		_wheelset_mesh = am
	var mi := MeshInstance3D.new()
	mi.mesh = _wheelset_mesh
	var root := Node3D.new()
	root.add_child(mi)
	return root


## Turn a car's model's moving parts for its having come `s` m (the engine's rods and wheels).
static func roll(model: Node3D, s: float, sim: TrainSim) -> void:
	if model is EngineModel:
		var e := model as EngineModel
		e.steam = sim.steam
		e.speed = absf(sim.v)
		e.roll(s)


## Turn a truck's wheels for its having come `s` m.
static func roll_truck(truck: Node3D, s: float) -> void:
	for c in truck.get_children():
		if c.has_meta(&"wheels"):
			for w: Node3D in c.get_meta(&"wheels"):
				w.rotation.x = -s / WHEEL_R


## The lamps lit (the coach's, the headlight) by how dark it is (0 day .. 1 night).
static func set_night(view: Node, night: float) -> void:
	for n in view.find_children("Model", "", true, false):
		if n is EngineModel:
			(n as EngineModel).set_night(night)
	for l: Node in view.get_tree().get_nodes_in_group(&"train_lamps"):
		if view.is_ancestor_of(l):
			(l as OmniLight3D).light_energy = 1.4 * night
			(l as OmniLight3D).visible = night > 0.01
	lamp().emission_energy_multiplier = 0.3 + 2.5 * night
