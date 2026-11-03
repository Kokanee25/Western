extends BridgeLab
## The light lab's dev bridge commands (issue #608 part 1, RoomLight): a camera, a lamp carried and
## knocked over, a stick against a wall, all in the street saloon's own space (x along its front,
## y up from the ground, z back from the street), and what RoomLight has made.

const HELP := {
	"rl_where": "rl_where LX LY LZ -> the world point of a point in the saloon's own space",
	"rl_cam": "rl_cam LX LY LZ TX TY TZ [FOV] -> the free camera at a saloon point looking at another",
	"rl_lamps": "rl_lamps -> the saloon's lamps: index, where (saloon space), group, lit",
	"rl_carry": "rl_carry INDEX LX LY LZ SECONDS -> lamp INDEX carried to the saloon point over SECONDS (as if in a hand)",
	"rl_knock": "rl_knock INDEX [SECONDS] -> lamp INDEX knocked over: it tips onto its side to the floor, then breaks",
	"rl_blast": "rl_blast LX LY LZ [FUSE] -> a lit stick at the saloon point",
	"rl_state": "rl_state -> RoomLight in the saloon: on, its bounces, openings (kind, wall, area), the haze",
	"rl_record": "rl_record DIR [EVERY] | rl_record stop -> save every EVERYth drawn frame (default 1) to DIR/NNNN.png while the next commands run (start the bridge with --fps=N: a frame is 1/N s of game time)",
}

var _record_dir := ""
var _record_every := 1
var _record_n := 0
var _record_frame := 0


func _process(_delta: float) -> void:
	if _record_dir == "":
		return
	_record_frame += 1
	if _record_frame % _record_every != 0:
		return
	get_viewport().get_texture().get_image().save_png("%s/%04d.png" % [_record_dir, _record_n])
	_record_n += 1


func _cmd_rl_record(a: Array) -> Dictionary:
	if a.is_empty() or a[0] == "stop":
		var n := _record_n
		_record_dir = ""
		return {"frames": n}
	_record_dir = String(a[0])
	DirAccess.make_dir_recursive_absolute(_record_dir)
	_record_every = maxi(1, int(a[1])) if a.size() > 1 else 1
	_record_n = 0
	_record_frame = 0
	return {"recording": _record_dir}


## A lamp by its index in rl_lamps, or the first whose prop's name holds the text.
func _lamp(key: String) -> OilLamp:
	var lamps := _lamps()
	if key.is_valid_int():
		return lamps[int(key)] as OilLamp
	for l in lamps:
		if String(_holder(l as OilLamp).name).to_lower().contains(key.to_lower()):
			return l as OilLamp
	return null


func _saloon() -> FalseFrontBuilding:
	for s in get_tree().get_nodes_in_group(&"structures"):
		if s is SaloonBuilding:
			return s
	return null


func _at(a: Array, i: int) -> Vector3:
	return _saloon().to_global(vec(a, i))


func _lamps() -> Array:
	var s := _saloon()
	var out := s.find_children("*", "OilLamp", true, false)
	out.sort_custom(func(x: Node, y: Node) -> bool: return String(x.get_path()) < String(y.get_path()))
	return out


## What to move for a lamp: its prop (the lamp's parent under Props), or the lamp.
func _holder(lamp: OilLamp) -> Node3D:
	var p := lamp.get_parent() as Node3D
	return p if p and p.get_parent() and p.get_parent().name == &"Props" else lamp


func _cmd_rl_where(a: Array) -> Dictionary:
	return {"world": arr(_at(a, 0))}


func _cmd_rl_cam(a: Array) -> Dictionary:
	var at := _at(a, 0)
	var to := _at(a, 3)
	var args := [at.x, at.y, at.z, to.x, to.y, to.z]
	if a.size() > 6:
		args.append(a[6])
	return bridge._cmd_camera(args.map(func(v: Variant) -> String: return str(v)))


func _cmd_rl_lamps(_a: Array) -> Dictionary:
	var s := _saloon()
	var out := []
	var lamps := _lamps()
	for i in lamps.size():
		var lamp := lamps[i] as OilLamp
		out.append({"i": i, "at": arr(s.to_local(lamp.light_position()).snappedf(0.01)), "group": String(lamp.get_meta(&"lamp_group", "")),
				"holder": String(_holder(lamp).name), "lit": lamp.lit})
	return {"lamps": out}


func _cmd_rl_carry(a: Array) -> Dictionary:
	if a.size() < 5:
		return {"ok": false, "error": HELP.rl_carry}
	var lamp := _lamp(String(a[0]))
	if lamp == null:
		return {"ok": false, "error": "no lamp " + String(a[0])}
	var h := _holder(lamp)
	var from := h.global_position
	var offset := lamp.light_position() - from
	var to := _at(a, 1) - offset
	var t := 0.0
	var dur := maxf(float(a[4]), 0.1)
	while t < dur:
		await physics_frames(1)
		t += get_physics_process_delta_time()
		var k := smoothstep(0.0, 1.0, minf(t / dur, 1.0))
		# A little sway in the hand.
		h.global_position = from.lerp(to, k) + Vector3.UP * sin(k * PI * 6.0) * 0.015
	return {"at": arr(_saloon().to_local(lamp.light_position()).snappedf(0.01))}


func _cmd_rl_knock(a: Array) -> Dictionary:
	var lamp := _lamp(String(a[0]))
	if lamp == null:
		return {"ok": false, "error": "no lamp " + String(a[0])}
	var h := _holder(lamp)
	var dur := float(a[1]) if a.size() > 1 else 0.45
	var start := h.global_transform
	var floor_y := _saloon().to_global(Vector3(0, _saloon().floor_top, 0)).y
	var drop := maxf(start.origin.y - floor_y - 0.06, 0.0)
	var axis := start.basis.x.normalized()
	var t := 0.0
	while t < dur:
		await physics_frames(1)
		t += get_physics_process_delta_time()
		var k := minf(t / dur, 1.0)
		var b := Basis(axis, deg_to_rad(88.0) * k * k) * start.basis
		h.global_transform = Transform3D(b, start.origin + Vector3.DOWN * drop * k * k)
	await seconds(0.25)
	lamp.smash(Vector3.DOWN)
	return {"broken": lamp.broken}


func _cmd_rl_blast(a: Array) -> Dictionary:
	var at := _at(a, 0)
	var args := [str(at.x), str(at.y), str(at.z)]
	if a.size() > 3:
		args.append(str(a[3]))
	return bridge._cmd_dynamite(args)


func _cmd_rl_state(_a: Array) -> Dictionary:
	var rl := RoomLight.find(get_tree())
	var s := _saloon()
	if rl == null or s == null:
		return {"ok": false, "error": "no RoomLight or saloon"}
	var openings := []
	for o: Dictionary in rl.openings_of(s):
		openings.append({"kind": String(o.kind), "wall": String(o.wall), "area": snappedf(float(o.get("area", (o.rect as Rect2).get_area())), 0.01),
				"energy": snappedf((o.spot as SpotLight3D).light_energy, 0.001) if is_instance_valid(o.spot) else 0.0})
	var bounces := []
	for b in rl.bounces_of(s):
		bounces.append({"at": arr(s.to_local(b.global_position).snappedf(0.01)), "energy": snappedf(b.light_energy, 0.001)})
	return {"on": RoomLight.active, "bounces": bounces, "openings": openings, "haze_extra": snappedf(rl.haze_extra_of(s), 0.0001)}
