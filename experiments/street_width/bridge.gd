extends BridgeLab
## #1295's street-width look test (art's; a lab: nothing here is in the game). Version C of the
## three looks: Main Street as it is (its width from valley.json), made busier for the picture:
## placeholder fronts in the gaps between buildings, and the street dressed as a busy 1882 street
## (wagons and buckboards, horses at rails, troughs, barrels, crates, a freight pile, people out in
## the street). Kit props where the kit has them, plain boxes for the rails and the gap fill.
##
##   street_dress                 dress the valley's Main Street (once; the valley world only)

const HELP := {
	"street_dress": "street_dress -> #1295 C: placeholder fronts in Main Street's gaps, wagons, horses at rails, troughs, freight, people in the street (valley world; a lab look test)",
}

const WOOD := Color(0.42, 0.34, 0.26)
const WOOD_PALE := Color(0.62, 0.55, 0.45)

var _vw: Node3D
var _ground: Node
var _root: Node3D
var _front := 10.05
var _walk := 2.4
var _made := 0


func _cmd_street_dress(_a: Array) -> Dictionary:
	_vw = get_tree().get_first_node_in_group(&"valley_world") as Node3D
	if _vw == null:
		return {"ok": false, "error": "not the valley world"}
	if _root != null:
		return {"ok": true, "already": true}
	_ground = _vw.get_node_or_null(^"Ground")
	var ms: Dictionary = (ValleyLayout.main().town().get("main_street", {}) as Dictionary)
	_front = float(ms.get("width_between_fronts", 20.1)) * 0.5
	_walk = float(ms.get("boardwalk_depth", 2.4))
	_root = Node3D.new()
	_root.name = "StreetDress1295"
	_vw.add_child(_root)
	_fill_gaps()
	await _dress()
	await seconds(1.0)
	return {"ok": true, "nodes": _made}


func _y(x: float, z: float) -> float:
	return float(_ground.call("height_at", x, z)) if _ground else 0.0


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95
	return m


func _box(size: Vector3, at: Vector3, c: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(c)
	_root.add_child(mi)
	mi.global_position = at
	_made += 1


## A plain false-fronted placeholder across a gap, x0..x1 along the street, on side (-1 north, +1 south).
func _front_box(x0: float, x1: float, side: float, h: float, c: Color) -> void:
	var w := x1 - x0
	var mx := (x0 + x1) * 0.5
	var deep := 12.0
	var zf := side * _front
	var y := _y(mx, zf)
	_box(Vector3(w, h, deep), Vector3(mx, y + h * 0.5, zf + side * deep * 0.5), c)
	_box(Vector3(w, 1.6, 0.15), Vector3(mx, y + h + 0.8, zf + side * 0.08), c.darkened(0.1))  # the false front
	_box(Vector3(w, 0.15, _walk), Vector3(mx, y + 0.38, zf - side * _walk * 0.5), WOOD)  # its walk
	_box(Vector3(w * 0.25, 2.3, 0.1), Vector3(mx, y + 1.5, zf - side * 0.02), Color(0.12, 0.1, 0.08))  # door


func _fill_gaps() -> void:
	# North: the saloon's yard to the lane.
	_front_box(24.4, 34.0, -1, 5.5, Color(0.55, 0.48, 0.40))
	# South: the vacant lot, the gaps by the bank and land office, the house lots' street end.
	_front_box(-43.4, -34.2, 1, 5.0, Color(0.50, 0.44, 0.36))
	_front_box(52.2, 59.8, 1, 5.5, Color(0.60, 0.56, 0.48))
	_front_box(69.2, 71.8, 1, 4.5, Color(0.48, 0.40, 0.33))
	_front_box(72.2, 86.0, 1, 6.0, Color(0.58, 0.50, 0.42))
	_front_box(86.4, 98.0, 1, 5.0, Color(0.46, 0.42, 0.36))
	_front_box(98.4, 112.0, 1, 6.5, Color(0.62, 0.52, 0.40))
	_front_box(112.4, 127.6, 1, 5.0, Color(0.50, 0.45, 0.38))
	_front_box(-101.0, -97.0, 1, 4.0, Color(0.46, 0.40, 0.34))


func _kit(id: StringName, x: float, z: float, yaw_deg := 0.0, y_up := 0.0) -> Node3D:
	var p: Node3D = PropKit.spawn(id)
	_root.add_child(p)
	p.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), Vector3(x, _y(x, z) + y_up, z))
	_made += 1
	return p


func _trough(x: float, z: float) -> void:
	var p: Node3D = PropKit.spawn_fitted(&"trough", StringName("trough1295_%d" % _made), Vector3(2.4, 0.6, 0.7))
	_root.add_child(p)
	p.global_position = Vector3(x - 1.2, _y(x, z), z)
	_made += 1


## A hitching rail along the street at z, x0..x1: two posts and a bar.
func _rail(x0: float, x1: float, z: float) -> void:
	for x in [x0, x1]:
		_box(Vector3(0.14, 1.1, 0.14), Vector3(x, _y(x, z) + 0.55, z), WOOD)
	var mx := (x0 + x1) * 0.5
	_box(Vector3(x1 - x0 + 0.2, 0.1, 0.1), Vector3(mx, _y(mx, z) + 1.0, z), WOOD_PALE)


## A horse standing with his head toward `facing` (a direction on the ground), tied at his nose.
func _horse(x: float, z: float, facing: Vector3) -> void:
	if not Horse.available():
		_box(Vector3(2.2, 1.5, 0.6), Vector3(x, _y(x, z) + 1.1, z), Color(0.3, 0.2, 0.13))
		return
	var h := Horse.new()
	_root.add_child(h)
	var at := Vector3(x, _y(x, z), z)
	h.global_transform = Transform3D(Basis(Vector3.UP, atan2(facing.z, -facing.x)), at)
	var nose := at + facing.normalized() * 1.6
	h.tie_to(Vector3(nose.x, _y(nose.x, nose.z) + 0.02, nose.z))
	_made += 1


func _dress() -> void:
	var edge := _front - _walk  # the walks' street edge (|z|)
	var n := -1.0
	var s := 1.0
	# Rails and horses: the saloon, the hotel, the store, the livery, the bank, the blacksmith.
	for r: Array in [[10.0, 20.0, n], [46.0, 60.0, n], [-52.0, -44.0, n], [-30.0, -14.0, s], [42.5, 51.5, s], [-94.0, -86.0, s], [74.0, 82.0, n]]:
		var z: float = float(r[2]) * (edge - 1.1)
		_rail(float(r[0]), float(r[1]), z)
		var k := 0
		var x: float = float(r[0]) + 1.0
		while x < float(r[1]) - 0.5:
			if (k + int(r[0])) % 3 != 2:
				_horse(x, z - float(r[2]) * 1.8, Vector3(0, 0, float(r[2])))
			x += 1.6
			k += 1
	# Troughs by the rails.
	for t: Array in [[21.5, n], [61.5, n], [-12.5, s], [53.0, s], [-84.0, s]]:
		_trough(float(t[0]), float(t[1]) * (edge - 0.6))
	# Wagons: a freight wagon at the store's dock, buckboards at the hardware and the doctor's, a covered
	# wagon and a freight wagon on the move in the street, a buckboard at the wagonwright's for mending.
	_kit(&"freight_wagon", -47.0, n * (edge - 1.4), 0.0)
	_horse(-52.8, n * (edge - 1.0), Vector3(-1, 0, 0))
	_horse(-52.8, n * (edge - 2.0), Vector3(-1, 0, 0))
	_kit(&"buckboard", -61.0, n * (edge - 1.3), 180.0)
	_horse(-56.2, n * (edge - 1.3), Vector3(1, 0, 0))
	_kit(&"covered_wagon", 30.0, 2.0, 180.0)
	_horse(34.8, 1.6, Vector3(1, 0, 0))
	_horse(34.8, 2.5, Vector3(1, 0, 0))
	_kit(&"freight_wagon", -22.0, -1.8, 0.0)
	_horse(-27.8, -1.4, Vector3(-1, 0, 0))
	_horse(-27.8, -2.3, Vector3(-1, 0, 0))
	_kit(&"buckboard", 92.0, n * (edge - 1.3), 0.0)
	_kit(&"buckboard", -55.0, s * (edge - 1.5), 90.0)
	_kit(&"wagon_wheel", -51.0, s * (edge - 0.6), 0.0)
	_kit(&"broken_wagon_wheel", -50.0, s * (edge - 0.9), 30.0)
	# The freight pile on the store's dock and below it: crates, barrels, sacks.
	var dock := n * (_front - 1.0)
	var wy := 1.1
	for i in 6:
		_kit(&"crate", -53.0 + i * 0.7, dock, 0.0, wy)
	for i in 3:
		_kit(&"crate", -52.6 + i * 0.7, dock, 0.0, wy + 0.6)
	for i in 4:
		_kit(&"barrel", -42.5 + i * 0.5, dock, 0.0, wy)
	for i in 5:
		_kit(&"feed_sack", -40.4 + i * 0.45, dock, 0.0, wy)
	var pile := n * (edge - 0.4)
	for i in 5:
		_kit(&"crate", -44.0 + i * 0.65, pile, float(i * 7))
	for i in 3:
		_kit(&"crate", -43.7 + i * 0.65, pile, float(i * 11), 0.6)
	_kit(&"grain_sacks", -40.5, pile, 0.0)
	_kit(&"barrel", -39.6, pile, 0.0)
	_kit(&"barrel", -39.1, pile + 0.1, 0.0)
	# Before the saloon and hotel: kegs and barrels; the hotel's trunks.
	for i in 4:
		_kit(&"barrel", 22.5 + i * 0.48, n * (_front - 0.6), 0.0, 1.0)
	_kit(&"travelling_trunk", 50.0, n * (_front - 0.8), 0.0, 0.4)
	_kit(&"travelling_trunk", 50.9, n * (_front - 0.8), 10.0, 0.4)
	# The livery: hay and feed; the carpenter's planks; the hardware's kegs.
	for i in 6:
		_kit(&"hay_bale", -32.0 + i * 0.95, s * (edge - 0.5), 0.0)
	for i in 3:
		_kit(&"hay_bale", -31.5 + i * 0.95, s * (edge - 0.5), 0.0, 0.45)
	for i in 4:
		_kit(&"plank_stack", -82.0, n * (edge - 0.6), 0.0, 0.22 * i)
	for i in 4:
		_kit(&"barrel", -66.0 + i * 0.5, n * (_front - 0.6), 0.0, 0.4)
	# Horse droppings and a spittoon's worth of life in the street.
	for p: Array in [[-10.0, 1.5], [14.0, -2.0], [40.0, 3.0], [-35.0, 4.0], [62.0, -1.0], [-70.0, 2.5]]:
		_kit(&"horse_droppings", float(p[0]), float(p[1]))
	# People out in the street and crossing it.
	for p: Array in [[-8.0, 1.0, 90.0], [18.0, -3.0, 160.0], [26.0, 4.0, 340.0], [44.0, -1.0, 200.0], [-30.0, 3.0, 20.0], [-46.0, -4.5, 180.0], [58.0, 2.5, 90.0], [8.0, 5.0, 270.0]]:
		await bridge._cmd_spawn(["townsman", str(p[0]), str(_y(float(p[0]), float(p[1])) + 0.05), str(p[1]), str(p[2])])
