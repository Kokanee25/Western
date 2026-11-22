class_name Cemetery
extends Structure
## The cemetery (#1142; config/cemetery.json): a white picket fence round a yard on the hill by the church, a
## plank gate (its two leaves standing open), and the graves: a low mound each with a wooden cross, a headboard
## or a small stone marker at its head (the prop lab's kit: `wood_cross`, `headboard`, `grave_marker`). The
## fence is members of this Structure (a ball breaks a picket); the markers are kit props; the mounds are
## plain ground (a low box each). The funeral's graves (config/moments/funeral.json `old_graves`) are laid
## first, at the same places the scene's stand-ins were; its new grave is the funeral's own.
##
## Its origin is the yard's middle on the ground (the pad is level: `pad_y`); positions are [east, south] of it.

const CONFIG := "res://config/cemetery.json"
const FUNERAL := "res://config/moments/funeral.json"

var cfg: Dictionary = {}
## Every grave laid: {"at": Vector2 world x/z, "kind": StringName, "marker": Node3D}
var graves: Array[Dictionary] = []
var fence_posts := 0
var pickets := 0


static func load_config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return parsed if parsed is Dictionary else {}


func _init() -> void:
	structure_id = &"cemetery"


## Where the yard's middle stands in the world.
static func world_at(c: Dictionary) -> Vector3:
	return Vector3(float((c.at as Array)[0]), float(c.get("pad_y", 0.0)), float((c.at as Array)[1]))


func build() -> void:
	if cfg.is_empty():
		cfg = load_config()
	graves.clear()
	_fence()
	_graves()


func _fence() -> void:
	var half: Array = cfg.half
	var hx := float(half[0])
	var hz := float(half[1])
	var pk: Dictionary = cfg.picket
	var spacing := float(pk.spacing)
	var pw := float(pk.width)
	var ph := float(pk.height)
	var gate: Dictionary = cfg.gate
	var gc := float(gate.centre)
	var gw := float(gate.width)
	var wood := &"painted_white"
	var runs := [
		["n", Vector2(-hx, -hz), Vector2(hx, -hz), []],
		["s", Vector2(-hx, hz), Vector2(hx, hz), [[gc - gw * 0.5, gc + gw * 0.5]]],
		["w", Vector2(-hx, -hz), Vector2(-hx, hz), []],
		["e", Vector2(hx, -hz), Vector2(hx, hz), []]]
	for r: Array in runs:
		var a: Vector2 = r[1]
		var b: Vector2 = r[2]
		var along_x: bool = absf(b.y - a.y) < 0.001
		var length := (b.x - a.x) if along_x else (b.y - a.y)
		var cuts: Array = r[3]
		# Posts at intervals (and either side of the gate), two rails, pickets between.
		var stops: Array[float] = [0.0, length]
		var n := maxi(1, ceili(length / float(pk.post_every)))
		for i in range(1, n):
			stops.append(length * i / n)
		for c: Array in cuts:
			stops.append(float(c[0]) - (a.x if along_x else a.y))
			stops.append(float(c[1]) - (a.x if along_x else a.y))
		stops.sort()
		for i in stops.size():
			var s := stops[i]
			if i > 0 and absf(s - stops[i - 1]) < 0.05:
				continue
			var p := a + (Vector2(s, 0) if along_x else Vector2(0, s))
			_white(add_member("fence/%s/post_%d" % [r[0], i], &"post", &"framing", Vector3(0.1, ph + 0.3, 0.1), Vector3(p.x, (ph + 0.3) * 0.5, p.y)))
			fence_posts += 1
		var s0 := 0.0
		var segs: Array = []
		var cur := 0.0
		for c: Array in cuts:
			var c0 := float(c[0]) - (a.x if along_x else a.y)
			var c1 := float(c[1]) - (a.x if along_x else a.y)
			segs.append([cur, c0])
			cur = c1
		segs.append([cur, length])
		var k := 0
		for sg: Array in segs:
			var l0 := float(sg[0])
			var l1 := float(sg[1])
			if l1 - l0 < 0.2:
				continue
			for rh: float in pk.rail_heights:
				var mid := a + (Vector2((l0 + l1) * 0.5, 0) if along_x else Vector2(0, (l0 + l1) * 0.5))
				var off := 0.07
				var size := Vector3(l1 - l0, 0.07, 0.04) if along_x else Vector3(0.04, 0.07, l1 - l0)
				var c3 := Vector3(mid.x, rh, mid.y + (off if along_x else 0.0) * (1.0 if r[0] == "s" else -1.0)) if along_x else Vector3(mid.x + off * (1.0 if r[0] == "e" else -1.0), rh, mid.y)
				_white(add_member("fence/%s/rail_%d_%d" % [r[0], k, int(rh * 100)], &"beam", &"framing", size, c3))
			var px := l0 + 0.12
			var j := 0
			while px < l1 - 0.08:
				var pp := a + (Vector2(px, 0) if along_x else Vector2(0, px))
				var out := 0.1
				var c4 := Vector3(pp.x, ph * 0.5 + 0.02, pp.y + out * (1.0 if r[0] == "s" else -1.0)) if along_x else Vector3(pp.x + out * (1.0 if r[0] == "e" else -1.0), ph * 0.5 + 0.02, pp.y)
				var psize := Vector3(pw, ph, 0.02) if along_x else Vector3(0.02, ph, pw)
				_white(add_member("fence/%s/picket_%d_%d" % [r[0], k, j], &"board", wood, psize, c4))
				pickets += 1
				px += spacing
				j += 1
			k += 1
	# The gate's two leaves standing open into the yard.
	var lw := gw * 0.5 - 0.04
	for e in 2:
		var hxg := gc - gw * 0.5 + 0.04 if e == 0 else gc + gw * 0.5 - 0.04
		_white(add_member("fence/gate_%d" % e, &"door", wood, Vector3(0.04, ph * 0.9, lw), Vector3(hxg, ph * 0.5 + 0.1, hz - lw * 0.5 - 0.1)))


## The graves, the funeral's first (at their old places, as its scene had them), then the rest by seed in
## the rows' gaps, none on the funeral's own grave or the lane to the gate.
func _graves() -> void:
	var at := Vector2(cfg.at[0], cfg.at[1])
	var kinds: Dictionary = cfg.kinds
	var funeral: Variant = JSON.parse_string(FileAccess.get_file_as_string(FUNERAL))
	var mid := Vector2(-104.0, -197.0)
	var olds: Array = []
	if funeral is Dictionary:
		mid = Vector2(float(funeral.grave[0]), float(funeral.grave[1]))
		olds = funeral.get("old_graves", [])
	var spots: Array[Vector2] = []
	for xz: Array in olds:
		spots.append(mid + Vector2(float(xz[0]), float(xz[1])))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cfg.seed)
	var half: Array = cfg.half
	var tries := 0
	var extra := int(cfg.extra_graves)
	while extra > 0 and tries < 400:
		tries += 1
		var p := at + Vector2(rng.randf_range(-float(half[0]) + 2.5, float(half[0]) - 2.5), rng.randf_range(-float(half[1]) + 2.5, float(half[1]) - 3.5))
		var ok := p.distance_to(mid) > 3.5
		for q in spots:
			if absf(q.x - p.x) < 3.4 and absf(q.y - p.y) < 2.4:
				ok = false
				break
		if ok:
			spots.append(p)
			extra -= 1
	var dirt := Color(0.36, 0.27, 0.19)
	var k := 0
	for p: Vector2 in spots:
		var kind := _kind(rng, kinds)
		var mound := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.9, 0.18, 0.75)
		mound.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = dirt.lightened(0.06 * float(k % 3))
		mat.roughness = 1.0
		mound.material_override = mat
		mound.name = "Mound%d" % k
		add_child(mound)
		mound.position = Vector3(p.x - global_position.x, 0.07, p.y - global_position.z)
		mound.rotation.y = deg_to_rad(rng.randf_range(-4.0, 4.0))
		var marker := PropKit.spawn(kind)
		marker.name = "Marker%d" % k
		add_child(marker)
		marker.position = Vector3(p.x - global_position.x - 1.1, 0.0, p.y - global_position.z)
		marker.rotation.y = deg_to_rad(90.0 + rng.randf_range(-6.0, 6.0))
		graves.append({"at": p, "kind": kind, "marker": marker})
		k += 1


## Drawn in the library's old white lead paint (`painted_white_lap`), as the church's clapboard.
func _white(m: StructureMember) -> void:
	PropKit.dress_member(m, {}, "lib:painted_white_lap/old")


static func _kind(rng: RandomNumberGenerator, kinds: Dictionary) -> StringName:
	var roll := rng.randf()
	var acc := 0.0
	for id: String in kinds:
		acc += float(kinds[id])
		if roll <= acc:
			return StringName(id)
	return &"wood_cross"
