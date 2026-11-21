class_name Homestead
extends Node3D
## A homestead on its pad (#1126, Harlan's; the line shack and later homesteads take the same site file):
## its spec buildings (SpecBuilding: Harlan's log cabin and board barn), a pole corral (Corral), a
## trough (WaterTrough), and the yard's loose things of members on the ground (YardStructure: the
## woodpile, the chopping block with its axe, the boards and shakes stacked for the repairs, a stall,
## the spring's box up the slope and the bored-log pipe from it down to the trough). Everything is
## a member, a kit prop or a fitting, as a spec building's is.
##
## The site file (config/buildings/harlan_homestead.json) is in the pad's own space: x east from its
## west edge, z south from its north edge, y over the pad (the valley's pad y). The node stands at the
## pad's north-west corner. `ground` (world x, z -> y, e.g. ValleyTerrain.main().height) lays what's off
## the pad (the spring, the pipe) on the real slope; without it the ground is the pad's level.
##
## `repair_jobs` gathers every building's and the yard's jobs (id -> {what, kind, members}): what a
## later repair action fixes (the stock for it is the pile in the barn).

const SITE := "res://config/buildings/harlan_homestead.json"

var site_path := SITE
var site: Dictionary
## World x, z -> ground y (the valley's terrain). Unset: the pad's level everywhere.
var ground: Callable
## By id: the spec buildings (SpecBuilding).
var buildings := {}
var corral: Corral
var trough: WaterTrough
var yard: YardStructure
var repair_jobs := {}


static func load_site(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _ready() -> void:
	if site.is_empty():
		site = load_site(site_path)
	if site.is_empty():
		push_error("Homestead: %s didn't load" % site_path)
		return
	for bd: Dictionary in site.get("buildings", []):
		_building(bd)
	_corral()
	_trough()
	yard = YardStructure.new()
	yard.name = "Yard"
	yard.structure_id = StringName("%s_yard" % site.get("id", "homestead"))
	var pieces: Array = []
	_woodpile(pieces)
	_chopping_block(pieces)
	_stock(pieces)
	_stall(pieces)
	_spring_and_pipe(pieces)
	yard.pieces = pieces
	add_child(yard)
	_gather_jobs()


## The ground's height at a point of the pad's space, over the pad (0 on the pad).
func ground_at(x: float, z: float) -> float:
	if not ground.is_valid():
		return 0.0
	var w := global_transform * Vector3(x, 0.0, z) if is_inside_tree() else transform * Vector3(x, 0.0, z)
	return float(ground.call(w.x, w.z)) - (global_position.y if is_inside_tree() else position.y)


## A spec building with its centre at `center` [x, z], turned `facing` (degrees: 0 its front to -Z).
func _building(bd: Dictionary) -> void:
	var b: Node3D = load("res://src/structures/spec_building.gd").new()
	var sp: Dictionary = b.load_spec(String(bd.spec))
	if not sp.has("lot"):
		push_error("Homestead: %s's spec %s didn't load" % [bd.id, bd.spec])
		b.free()
		return
	b.set(&"spec_path", String(bd.spec))
	b.set(&"structure_id", StringName("%s_%s" % [site.get("id", "homestead"), bd.id]))
	b.name = "Building_" + String(bd.id)
	var half := Vector3(float(sp.lot.width) * 0.5, 0.0, float(sp.lot.depth) * 0.5)
	var basis := Basis(Vector3.UP, deg_to_rad(float(bd.get("facing", 0.0))))
	var c := Vector3(float(bd.center[0]), float(bd.get("y", 0.0)), float(bd.center[1]))
	b.transform = Transform3D(basis, c - basis * half)
	add_child(b)
	buildings[String(bd.id)] = b


func _corral() -> void:
	var cd: Dictionary = site.get("corral", {})
	if cd.is_empty():
		return
	corral = Corral.new()
	corral.name = "Corral"
	corral.structure_id = StringName("%s_corral" % site.get("id", "homestead"))
	corral.size = Vector2(cd.size[0], cd.size[1])
	corral.post_spacing = float(cd.get("post_spacing", 2.4))
	corral.height = float(cd.get("height", 1.5))
	corral.gate_at = float(cd.get("gate_at", 1.0))
	corral.gate_width = float(cd.get("gate_width", 2.4))
	var rs: Array = cd.get("rail_section", [0.1, 0.05])
	corral.rail_section = Vector2(rs[0], rs[1])
	var bl: Array[String] = []
	for k: Variant in cd.get("broken", []):
		bl.append(String(k))
	corral.broken = bl
	corral.position = Vector3(cd.at[0], 0.0, cd.at[1])
	add_child(corral)


func _trough() -> void:
	var td: Dictionary = site.get("trough", {})
	if td.is_empty():
		return
	trough = WaterTrough.new()
	trough.name = "Trough"
	trough.length = float(td.get("length", 2.4))
	trough.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(td.get("yaw", 0.0)))), Vector3(td.at[0], 0.0, td.at[1]))
	add_child(trough)


## A piece for the yard: `at` its centre, its foot's ground under it (`gy`).
static func _piece(pieces: Array, id: String, kind: StringName, wood: StringName, size: Vector3, at: Vector3, gy := 0.0, basis := Basis(), meta := {}) -> void:
	pieces.append({"id": id, "kind": kind, "wood": wood, "size": size, "at": at, "basis": basis, "ground_y": gy, "meta": meta})


## Split cordwood stacked against a wall: `at` [x, z] its near end's middle, `along` the axis it runs
## (x or z), `length`, `height`, `depth` (a billet's length, across), billets of about `billet` each,
## each row laid a half billet over, the top row ragged.
func _woodpile(pieces: Array) -> void:
	var wd: Dictionary = site.get("woodpile", {})
	if wd.is_empty():
		return
	var along_x := String(wd.get("along", "z")) == "x"
	var length := float(wd.length)
	var height := float(wd.height)
	var deep := float(wd.get("depth", 0.4))
	var bil := float(wd.get("billet", 0.14))
	var rows := int(height / bil)
	var n := int(length / bil)
	for r in rows:
		var off := bil * 0.5 if r % 2 == 1 else 0.0
		var count := n - (1 if r % 2 == 1 else 0)
		if r == rows - 1:
			count = int(count * 0.7)  # the top row half used
		for i in count:
			var s := off + bil * (i + 0.5)
			var jitter := float(hash("billet%d_%d" % [r, i]) % 100) / 100.0
			var b := bil * (0.82 + 0.14 * jitter)
			# (each row exactly a billet high, so a row lies on the one under it; the widths vary)
			var dp := deep * (0.9 + 0.2 * jitter)
			var at := Vector3(wd.at[0], bil * 0.5 + r * bil, wd.at[1])
			var size := Vector3(b, bil, dp) if along_x else Vector3(dp, bil, b)
			if along_x:
				at.x += s
			else:
				at.z += s
			_piece(pieces, "woodpile/%02d_%02d" % [r, i], &"sill", &"framing", size, at)


## The chopping block (a round of pine stood on end), an axe stuck in its top, chips round it.
func _chopping_block(pieces: Array) -> void:
	var cb: Dictionary = site.get("chopping_block", {})
	if cb.is_empty():
		return
	var h := float(cb.get("height", 0.5))
	var d := float(cb.get("diameter", 0.45))
	var at := Vector3(cb.at[0], 0.0, cb.at[1])
	_piece(pieces, "block/round", &"post", &"framing", Vector3(d, h, d), at + Vector3.UP * (h * 0.5))
	# The axe: its head bitten 3 cm into the block's top, the handle up and over at 35 degrees.
	var yaw := deg_to_rad(float(cb.get("axe_yaw", 30.0)))
	var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
	var head_c := at + Vector3.UP * (h + 0.05) + fwd * 0.04
	_piece(pieces, "block/axe_head", &"post", &"iron", Vector3(0.17, 0.1, 0.035), head_c, 0.0, Basis(Vector3.UP, yaw + PI * 0.5))
	var tilt := deg_to_rad(55.0)
	var hdir := (fwd * cos(tilt) + Vector3.UP * sin(tilt)).normalized()
	var hl := 0.78
	var xa := hdir
	var ya := Vector3.UP.slide(xa).normalized() if absf(xa.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	_piece(pieces, "block/axe_handle", &"trim", &"oak", Vector3(hl, 0.035, 0.028), head_c + hdir * (hl * 0.5 + 0.03), 0.0, Basis(xa, ya, xa.cross(ya)))
	# A scatter of chips and two split billets on the ground round it.
	for i in int(cb.get("chips", 10)):
		var a := float(hash("chip%d" % i) % 628) / 100.0
		var r := 0.35 + float(hash("chipr%d" % i) % 50) / 100.0
		var p := at + Vector3(cos(a) * r, 0.006, sin(a) * r)
		_piece(pieces, "block/chip_%02d" % i, &"sill", &"framing", Vector3(0.07, 0.012, 0.035), p, 0.0, Basis(Vector3.UP, a * 1.7))
	for i in 2:
		var p := at + Vector3(0.55 - i * 1.0, 0.05, 0.3 + i * 0.25)
		_piece(pieces, "block/billet_%d" % i, &"sill", &"framing", Vector3(0.4, 0.1, 0.13), p, 0.0, Basis(Vector3.UP, 0.6 + i))


## The stock for the repairs in the barn: new sawn boards stacked on two bearers, bundles of shakes.
func _stock(pieces: Array) -> void:
	var st: Dictionary = site.get("stock", {})
	if st.is_empty():
		return
	var at := Vector3(st.at[0], 0.0, st.at[1])
	var bl := float(st.get("board_length", 3.05))
	# The boards along x, or (`along` "z") turned a quarter about the stack's middle.
	var turn := Basis(Vector3.UP, PI * 0.5) if String(st.get("along", "x")) == "z" else Basis()
	for e in 2:
		_piece(pieces, "stock/bearer_%d" % e, &"sill", &"framing", Vector3(0.09, 0.09, 0.9), at + turn * Vector3((e - 0.5) * bl * 0.7, 0.045, 0.0), 0.0, turn, {"repair_stock": true})
	var layers := int(st.get("layers", 3))
	var per := int(st.get("per_layer", 5))
	for l in layers:
		for i in per:
			var z := (i - (per - 1) * 0.5) * 0.16
			_piece(pieces, "stock/board_%d_%d_new" % [l, i], &"board", &"framing", Vector3(bl, 0.022, 0.15), at + turn * Vector3(0.0, 0.09 + 0.011 + l * 0.023, z), 0.0, turn, {"repair_stock": true})
	var sb: Array = st.get("shakes_at", [])
	for i in sb.size():
		var p: Array = sb[i]
		_piece(pieces, "stock/shakes_%d_new" % i, &"sill", &"framing", Vector3(0.62, 0.3, 0.4), Vector3(p[0], 0.15 + 0.3 * float(p[2] if p.size() > 2 else 0.0), p[1]), 0.0,
				Basis(Vector3.UP, float(hash("shk%d" % i) % 30) / 100.0), {"repair_stock": true, "bundle": "shakes"})


## A horse's stall: a side of three boards on two posts, a manger box at its head.
func _stall(pieces: Array) -> void:
	var sd: Dictionary = site.get("stall", {})
	if sd.is_empty():
		return
	var a := Vector3(sd.from[0], 0.0, sd.from[1])
	var b := Vector3(sd.to[0], 0.0, sd.to[1])
	for e in 2:
		var p := a if e == 0 else b
		_piece(pieces, "stall/post_%d" % e, &"post", &"framing", Vector3(0.1, 1.35, 0.1), p + Vector3.UP * 0.675)
	var len := a.distance_to(b)
	var dir := (b - a).normalized()
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	for k in 3:
		_piece(pieces, "stall/board_%d" % k, &"board", &"weathered_pine", Vector3(len + 0.1, 0.2, 0.03), (a + b) * 0.5 + Vector3.UP * (0.45 + k * 0.3) + basis.z * 0.065, 0.0, basis)
	if sd.has("manger"):
		var m: Array = sd.manger
		_piece(pieces, "stall/manger", &"post", &"weathered_pine", Vector3(m[2], 0.75, m[3]), Vector3(m[0], 0.375, m[1]))


## The spring up the slope: a box of planks round its pool, stones on its rim; and the pipe of bored
## logs from it down the ground to the trough, each length on the ground under it (tilted with it),
## the last on a crotch post over the trough's end.
func _spring_and_pipe(pieces: Array) -> void:
	var sp: Dictionary = site.get("spring", {})
	if sp.is_empty():
		return
	var sc := Vector3(sp.at[0], 0.0, sp.at[1])
	var gy := ground_at(sc.x, sc.z)
	var bw := float(sp.get("size", 1.1))
	var bh := 0.4
	for e in 4:
		var along_x := e < 2
		var off := (bw * 0.5) * (1.0 if e % 2 == 0 else -1.0)
		var c := sc + (Vector3(0, 0, off) if along_x else Vector3(off, 0, 0))
		var g := ground_at(c.x, c.z)
		var size := Vector3(bw + 0.05, bh, 0.05) if along_x else Vector3(0.05, bh, bw - 0.05)
		_piece(pieces, "spring/box_%d" % e, &"sill", &"framing", size, Vector3(c.x, g - 0.15 + bh * 0.5, c.z), g - 0.15)
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		var c := sc + Vector3(cos(a), 0, sin(a)) * (bw * 0.5 + 0.28)
		var g := ground_at(c.x, c.z)
		var s := 0.25 + float(hash("sst%d" % i) % 20) / 100.0
		_piece(pieces, "spring/stone_%d" % i, &"sill", &"stone", Vector3(s, s * 0.7, s * 0.9), Vector3(c.x, g + s * 0.3, c.z), g - s * 0.05, Basis(Vector3.UP, a))
	var water := MeshInstance3D.new()
	water.name = "SpringWater"
	var pm := PlaneMesh.new()
	pm.size = Vector2(bw - 0.1, bw - 0.1)
	water.mesh = pm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.16, 0.2, 0.18, 0.85)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.roughness = 0.05
	wm.metallic_specular = 0.8
	water.material_override = wm
	water.position = Vector3(sc.x, gy + 0.12, sc.z)
	add_child(water)
	# The pipe: from the box's downhill side to over the trough's end, lengths of `piece`.
	var td: Dictionary = site.get("trough", {})
	if td.is_empty():
		return
	var end := Vector3(float(sp.pipe_to[0]), 0.0, float(sp.pipe_to[1]))
	var start := sc + (end - sc).normalized() * (bw * 0.5 + 0.05)
	var run := Vector2(start.x, start.z).distance_to(Vector2(end.x, end.z))
	var piece := float(sp.get("piece", 3.0))
	var n := maxi(1, ceili(run / piece))
	var d := float(sp.get("pipe", 0.18))
	var spout_y := float(sp.get("spout_y", 0.85))
	for i in n:
		var a := start.lerp(end, float(i) / n)
		var b := start.lerp(end, float(i + 1) / n)
		var ya := ground_at(a.x, a.z) + d * 0.5
		var yb := (spout_y if i == n - 1 else ground_at(b.x, b.z) + d * 0.5)
		if i == 0:
			ya = gy + 0.12
		var pa := Vector3(a.x, ya, a.z)
		var pb := Vector3(b.x, yb, b.z)
		var xa := (pb - pa).normalized()
		var yv := Vector3.UP.slide(xa).normalized()
		var foot := minf(ya, yb) - d * 0.5
		var m := {"pipe": i}
		if i == n - 1:
			m["spout"] = true
		_piece(pieces, "pipe/%02d" % i, &"sill" if i < n - 1 else &"beam", &"framing", Vector3(pa.distance_to(pb) + 0.04, d, d), (pa + pb) * 0.5,
				foot, Basis(xa, yv, xa.cross(yv)), m)
	# A crotch post under the last length's end, by the trough.
	var g := ground_at(end.x, end.z)
	_piece(pieces, "pipe/post", &"post", &"framing", Vector3(0.1, spout_y - d * 0.5 - g, 0.1), Vector3(end.x - (end - start).normalized().x * 0.3, (spout_y - d * 0.5 + g) * 0.5, end.z - (end - start).normalized().z * 0.3), g)


func _gather_jobs() -> void:
	repair_jobs.clear()
	for id: String in buildings:
		var b: Node = buildings[id]
		var jobs: Variant = b.get(&"repair_jobs")
		if jobs is Dictionary:
			for k: String in jobs:
				repair_jobs[k] = jobs[k]
	if corral and not corral.broken.is_empty():
		var ms: Array = []
		for m: StructureMember in corral.get_members():
			if m.get_meta(&"repair", &"") == &"broken_rail":
				ms.append(m.member_id)
		repair_jobs["corral_rail"] = {"what": "a corral rail snapped, hanging off its post", "kind": "broken", "members": ms}
