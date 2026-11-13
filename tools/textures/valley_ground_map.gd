extends SceneTree
## The valley ground's map (#891; ValleyGroundArt reads it): what the ground is at each of the bake's
## points (ValleyTerrain's 2 m grid), for the ground's shader and the scatter's rules. Baked from
## config/valley.json (the roads, the town's streets and lots, the water, the pads, the rail), never
## by hand; re-bake when valley.json changes (tests/test_valley_ground_art.gd fails until it is):
##
##   godot --headless -s res://tools/textures/valley_ground_map.gd
##
## Two images, saved as compressed resources beside each other in assets/textures/valley/:
## - ground_map_a.res (RGBAH, filtered in the shader): R the signed metres across the nearest road's
##   middle (+ left of its direction), G that road's half width (m), B its class (ROAD_CLASS: 1 Main
##   Street, 2 the town's other streets, 3 wagon road, 4 lane, 5 track, 6 path; 0 none), A the metres
##   to the nearest water's bed edge (0 in it, CAP_WATER far). R, G and B are written out to `MARGIN`
##   past a road's edge, so the shader finds the edge from R and G with no hard step in between.
## - ground_map_b.res (RGBA8): R a place's pad (1 on it), G the town's lots and yards (1), B the rail
##   bed (1 within RAIL_HALF of the line), A a ford (1 within its patch).
## The images carry `valley_json_sha256` (heights.json's, the bake they were made over) and the grid.
##
## Untyped where it names game classes: -s scripts compile before autoloads exist.

const OUT := "res://assets/textures/valley/"
const MARGIN := 6.0
const CAP_WATER := 60.0
const RAIL_HALF := 6.0
const ROAD_CLASS := {"street": 2, "wagon": 3, "lane": 4, "track": 5, "path": 6}
## Narrow roads at least this wide each side (ValleyMarks.MIN_HALF's spirit: a 1 m path still reads).
const MIN_HALF := 0.75

var w := 0
var d := 0
var sp := 2.0
var x0 := 0.0
var z0 := 0.0
var across := PackedFloat32Array()
var half := PackedFloat32Array()
var klass := PackedFloat32Array()
var score := PackedFloat32Array()
var water := PackedFloat32Array()
var b_img := PackedByteArray()


var _done := false


## On the first frame, once the autoloads are in (the railway's scripts name Events).
func _process(_delta: float) -> bool:
	if not _done:
		_done = true
		_bake()
	return false


func _bake() -> void:
	var u := Time.get_ticks_msec()
	var terrain = load("res://src/world/valley_terrain.gd").main()
	var layout = load("res://src/world/valley_layout.gd").main()
	w = terrain.width
	d = terrain.depth
	sp = terrain.spacing
	x0 = terrain.x0
	z0 = terrain.z0
	var n := w * d
	across.resize(n)
	half.resize(n)
	klass.resize(n)
	score.resize(n)
	score.fill(1e9)
	water.resize(n)
	water.fill(CAP_WATER)
	b_img.resize(n * 4)
	# The roads: the town's streets first (Main Street its own class), then valley.json's.
	var marks_script = load("res://src/world/valley_marks.gd")
	for r: Dictionary in marks_script.town_streets(layout):
		var c := 1 if String(r.id) == "main_street" else 2
		_road(_line(r.line), float(r.width) * 0.5, c)
	for r: Dictionary in layout.roads():
		var c: int = ROAD_CLASS.get(String(r.get("class", "")), 0)
		if c == 0:
			continue
		_road(_line(r.line), maxf(float(r.get("width", 2.0)) * 0.5, MIN_HALF), c)
	print("roads %d ms" % (Time.get_ticks_msec() - u))
	# The water's beds (creek, arroyo): the distance to the flat floor's edge.
	for key in ["creek", "arroyo"]:
		var rows: Array = layout.water_rows(key)
		for i in range(1, rows.size()):
			var a: Array = rows[i - 1]
			var b: Array = rows[i]
			_water(Vector2(a[0], a[1]), Vector2(b[0], b[1]), float(a[4]), float(b[4]))
	print("water %d ms" % (Time.get_ticks_msec() - u))
	# The places' pads.
	for p: Dictionary in layout.places():
		var pad: Dictionary = p.get("pad", {})
		if not pad.is_empty():
			_rect(layout.xz(p.at), float(pad.w), float(pad.d), float(pad.get("heading", 90.0)), 0)
	# The town's lots and yards: between Main Street's fronts and Back Street / the rear lane, and the
	# residential rows to the creek (valley.json's town).
	var t: Dictionary = layout.town()
	var ms: Dictionary = t.get("main_street", {})
	var front := float(ms.get("width_between_fronts", 20.1)) * 0.5
	var mx: Vector2 = layout.main_street_x()
	var back_z := float((t.get("back_street", {}) as Dictionary).get("z", [-54.25, -48.15])[1])
	var rear_z := float((t.get("rear_lane", {}) as Dictionary).get("z", [48.15, 54.25])[0])
	_box(mx.x, mx.y, back_z, -front, 1)
	_box(mx.x, mx.y, front, rear_z, 1)
	for ex: Dictionary in t.get("extras", []):
		for row: Dictionary in ex.get("rows", []):
			if not row.get("street", false):
				_box(mx.x, mx.y, float(row.z[0]), float(row.z[1]), 1)
		if ex.has("at") and ex.has("w"):
			var c: Vector2 = layout.xz(ex.at)
			_box(c.x - float(ex.w) * 0.5, c.x + float(ex.w) * 0.5, c.y - float(ex.d) * 0.5, c.y + float(ex.d) * 0.5, 1)
	# The rail's bed.
	var tuning = load("res://config/train.tres")
	var tl = load("res://src/world/valley_railway.gd").make_line(layout, tuning, terrain)
	tl.lay_out()
	var xf: Transform3D = tl.transform
	var s := 0.0
	var prev := Vector2.INF
	while s <= tl.length:
		var p: Vector3 = xf * tl.point_at(s)
		var q := Vector2(p.x, p.z)
		if prev != Vector2.INF:
			_flag_segment(prev, q, RAIL_HALF, 2)
		prev = q
		s += 4.0
	tl.free()
	# The fords.
	for f: Dictionary in marks_script.fords(layout):
		_flag_segment(f.at, f.at, 6.0, 3)
	print("flags %d ms" % (Time.get_ticks_msec() - u))
	_save(terrain)
	print("ground map %dx%d in %d ms" % [w, d, Time.get_ticks_msec() - u])
	quit(0)


func _line(a: Variant) -> PackedVector2Array:
	return load("res://src/world/valley_layout.gd").xz_line(a)


## A road's points out to MARGIN past its edge: each takes this road where it's more inside it than
## the road it had (score: metres past the edge, negative inside).
func _road(line: PackedVector2Array, h: float, c: int) -> void:
	for i in range(1, line.size()):
		var a := line[i - 1]
		var b := line[i]
		var ab := b - a
		var len := ab.length()
		if len < 1e-6:
			continue
		var dir := ab / len
		var nrm := Vector2(-dir.y, dir.x)
		var reach := h + MARGIN
		var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(reach, reach)
		var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(reach, reach)
		for j in range(maxi(0, floori((lo.y - z0) / sp)), mini(d - 1, ceili((hi.y - z0) / sp)) + 1):
			var z := z0 + j * sp
			var row := j * w
			for ii in range(maxi(0, floori((lo.x - x0) / sp)), mini(w - 1, ceili((hi.x - x0) / sp)) + 1):
				var p := Vector2(x0 + ii * sp, z) - a
				var t := p.dot(dir)
				var off := p.dot(nrm)
				var dist: float
				if t < 0.0:
					dist = p.length()
				elif t > len:
					dist = (p - ab).length()
				else:
					dist = absf(off)
				if dist > reach:
					continue
				var sc := dist - h
				var k := row + ii
				if sc < score[k]:
					score[k] = sc
					across[k] = signf(off) * dist if off != 0.0 else dist
					half[k] = h
					klass[k] = c


func _water(a: Vector2, b: Vector2, ha: float, hb: float) -> void:
	var ab := b - a
	var ll := maxf(ab.length_squared(), 1e-9)
	var reach := maxf(ha, hb) + CAP_WATER
	var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(reach, reach)
	var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(reach, reach)
	for j in range(maxi(0, floori((lo.y - z0) / sp)), mini(d - 1, ceili((hi.y - z0) / sp)) + 1):
		var z := z0 + j * sp
		var row := j * w
		for ii in range(maxi(0, floori((lo.x - x0) / sp)), mini(w - 1, ceili((hi.x - x0) / sp)) + 1):
			var p := Vector2(x0 + ii * sp, z)
			var t := clampf((p - a).dot(ab) / ll, 0.0, 1.0)
			var e := maxf(0.0, p.distance_to(a + ab * t) - lerpf(ha, hb, t))
			var k := row + ii
			if e < water[k]:
				water[k] = e


func _rect(c: Vector2, rw: float, rd: float, heading: float, ch: int) -> void:
	var hd := deg_to_rad(heading)
	var uu := Vector2(sin(hd), -cos(hd))
	var vv := Vector2(-uu.y, uu.x)
	var r := Vector2(rw, rd).length() * 0.5
	for j in range(maxi(0, floori((c.y - r - z0) / sp)), mini(d - 1, ceili((c.y + r - z0) / sp)) + 1):
		for ii in range(maxi(0, floori((c.x - r - x0) / sp)), mini(w - 1, ceili((c.x + r - x0) / sp)) + 1):
			var p := Vector2(x0 + ii * sp, z0 + j * sp) - c
			if absf(p.dot(uu)) <= rw * 0.5 and absf(p.dot(vv)) <= rd * 0.5:
				b_img[(j * w + ii) * 4 + ch] = 255


func _box(xa: float, xb: float, za: float, zb: float, ch: int) -> void:
	for j in range(maxi(0, ceili((minf(za, zb) - z0) / sp)), mini(d - 1, floori((maxf(za, zb) - z0) / sp)) + 1):
		for ii in range(maxi(0, ceili((minf(xa, xb) - x0) / sp)), mini(w - 1, floori((maxf(xa, xb) - x0) / sp)) + 1):
			b_img[(j * w + ii) * 4 + ch] = 255


func _flag_segment(a: Vector2, b: Vector2, r: float, ch: int) -> void:
	var ab := b - a
	var ll := maxf(ab.length_squared(), 1e-9)
	var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(r, r)
	var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(r, r)
	for j in range(maxi(0, floori((lo.y - z0) / sp)), mini(d - 1, ceili((hi.y - z0) / sp)) + 1):
		for ii in range(maxi(0, floori((lo.x - x0) / sp)), mini(w - 1, ceili((hi.x - x0) / sp)) + 1):
			var p := Vector2(x0 + ii * sp, z0 + j * sp)
			var t := clampf((p - a).dot(ab) / ll, 0.0, 1.0)
			if p.distance_to(a + ab * t) <= r:
				b_img[(j * w + ii) * 4 + ch] = 255


func _save(terrain) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var n := w * d
	var a_data := PackedByteArray()
	a_data.resize(n * 8)
	for k in n:
		a_data.encode_half(k * 8, across[k])
		a_data.encode_half(k * 8 + 2, half[k])
		a_data.encode_half(k * 8 + 4, klass[k])
		a_data.encode_half(k * 8 + 6, water[k])
	var meta := {"valley_json_sha256": String(terrain.meta.get("valley_json_sha256", "")), "width": w, "depth": d,
		"spacing": sp, "x0": x0, "z0": z0}
	var ia := Image.create_from_data(w, d, false, Image.FORMAT_RGBAH, a_data)
	var ib := Image.create_from_data(w, d, false, Image.FORMAT_RGBA8, b_img)
	for img: Image in [ia, ib]:
		for key: String in meta:
			img.set_meta(key, meta[key])
	var e1 := ResourceSaver.save(ia, OUT + "ground_map_a.res", ResourceSaver.FLAG_COMPRESS)
	var e2 := ResourceSaver.save(ib, OUT + "ground_map_b.res", ResourceSaver.FLAG_COMPRESS)
	print("saved ", e1, " ", e2)
