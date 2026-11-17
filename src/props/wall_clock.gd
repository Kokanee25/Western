class_name WallClock
extends Node3D
## A real clock on the wall (#1030, #789; Sean 2026-11-16: "the clock needs to be a real clock"): a case of
## members (its kit file's `case`: breaks, burns, falls as any hung prop) with a dial, two hands and a
## pendulum that show the town's local time (DayCycle's `time_of_day`: no standard time zones until
## Nov 1883) and swing, and a tick, a placed GameAudio sound.
##
## A reusable part (docs/PARTS.md "Props"): the bank, depot, store and homes' shelf clocks are another kit
## file of `kind: "clock"` with their own `case`, `size`, `dial`, `hands` and `pendulum`.
##
## Cheap by design: the hands and the pendulum are set by maths (no physics, no tree of bodies) and only
## while it's on screen and within `tick.reach` of the camera; a minute-hand step is written only when the
## minute changes; off screen and far it does nothing at all but a distance check every quarter second.
## The tick runs while the camera is within `tick.reach` (a clock behind you is heard).
## Hands: a minute hand is `fract(hour) * 360` degrees clockwise from twelve, an hour hand `(hour % 12) * 30`.

const NEAR_CHECK := 0.25  # seconds between distance checks

var kit_id := &"wall_clock"
var definition := {}
var case_prop: KitProp
var stopped := false  # smashed or fallen: the works are gone

var _hour_pivot: Node3D
var _minute_pivot: Node3D
var _pendulum: Node3D
var _works: Node3D
var _notifier: VisibleOnScreenNotifier3D
var _on_screen := false
var _near := false
var _check_in := 0.0
var _phase := 0.0   # seconds into the pendulum's swing
var _beat := 0      # the half-swings counted (tick, tock)
var _last_minute := -1
var _day: DayCycle


func _ready() -> void:
	var case_id := StringName(definition.get("case", "wall_clock_case"))
	case_prop = PropKit.spawn(case_id, StringName("%s_case" % name))
	add_child(case_prop)
	case_prop.went_loose.connect(_on_case_loose)
	_build_works()
	var size: Array = definition.get("size", [0.4, 1.16, 0.18])
	_notifier = VisibleOnScreenNotifier3D.new()
	_notifier.aabb = AABB(Vector3(-float(size[0]) * 0.5, 0.0, 0.0), Vector3(size[0], size[1], size[2]))
	_notifier.screen_entered.connect(func() -> void: _on_screen = true)
	_notifier.screen_exited.connect(func() -> void: _on_screen = false)
	add_child(_notifier)
	_phase = float(hash(String(name)) % 1000) / 1000.0 * float(_pend().get("period", 1.4))
	_day = get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	if _day:
		show_time(_day.time_of_day)


## The hands' angles in degrees clockwise from twelve for the time `hour` (0-24, fractional):
## x the hour hand's, y the minute hand's.
static func hand_angles(hour: float) -> Vector2:
	return Vector2(fposmod(hour, 12.0) * 30.0, fposmod(hour, 1.0) * 360.0)


## Set the hands to `hour` now.
func show_time(hour: float) -> void:
	var a := hand_angles(hour)
	_hour_pivot.rotation.z = -deg_to_rad(a.x)
	_minute_pivot.rotation.z = -deg_to_rad(a.y)
	_last_minute = int(floor(hour * 60.0))


## The pendulum's angle in degrees at `t` seconds into its swing.
func pendulum_angle(t: float) -> float:
	var p := _pend()
	return float(p.get("swing_deg", 4.5)) * sin(TAU * t / float(p.get("period", 1.4)))


func _process(delta: float) -> void:
	if stopped:
		return
	_check_in -= delta
	if _check_in <= 0.0:
		_check_in = NEAR_CHECK
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		_near = cam != null and cam.global_position.distance_to(global_position) <= float(_tick().get("reach", 16.0))
	if not _near:
		return
	var half := float(_pend().get("period", 1.4)) * 0.5
	var before := _phase
	_phase += delta
	if int(floor(_phase / half)) != int(floor(before / half)):
		_tick_now()
	if not _on_screen:
		return
	_pendulum.rotation.z = deg_to_rad(pendulum_angle(_phase))
	if _day:
		var minute := int(floor(_day.time_of_day * 60.0))
		if minute != _last_minute:
			show_time(_day.time_of_day)


## The escapement's tick (alternating tick and tock), quieter for the din round it: each person within
## `din_reach` takes `din_db` off, so a busy night loses it and an empty room keeps it.
func _tick_now() -> void:
	_beat += 1
	if not GameAudio.enabled():
		return
	var t := _tick()
	var din := 0
	var reach2 := float(t.get("din_reach", 9.0)) ** 2
	for p: Node in get_tree().get_nodes_in_group(&"people"):
		if p is Node3D and (p as Node3D).global_position.distance_squared_to(global_position) < reach2:
			din += 1
	var db := float(t.get("volume_db", -15.0)) - float(t.get("din_db", 2.0)) * din
	if db < -45.0:
		return
	GameAudio.play(self, &"clock_tick" if _beat % 2 == 0 else &"clock_tock",
			global_position + global_basis * Vector3(0, float(_dial().at[1]), 0.1),
			{"unit_size": float(t.get("unit_size", 1.2)), "volume_db": db, "max_db": -6.0, "delay": false, "limit": 2})


func _on_case_loose() -> void:
	# Fallen off its nail: the works go with it (the dial and hands aren't bodies; they're lost).
	stopped = true
	if _works:
		_works.queue_free()


func _pend() -> Dictionary:
	return definition.get("pendulum", {})


func _tick() -> Dictionary:
	return definition.get("tick", {})


func _dial() -> Dictionary:
	var d: Dictionary = definition.get("dial", {})
	if not d.has("at"):
		d["at"] = [0.0, 0.9, 0.11]
	return d


func _build_works() -> void:
	_works = Node3D.new()
	_works.name = "Works"
	add_child(_works)
	var d := _dial()
	var at := Vector3(d.at[0], d.at[1], d.at[2])
	var r := float(d.get("radius", 0.135))
	# The dial: enamel white, a minute track, Roman numerals (drawn into a texture in code).
	var face := MeshInstance3D.new()
	face.name = "Dial"
	face.mesh = _disc(r, 40)
	face.material_override = PixelArt.material(ImageTexture.create_from_image(dial_image(256)), Color.WHITE,
			PixelArt.Mapping.UV, Vector3.ZERO, 0.35, 0.0, 0.5)
	face.position = at
	_works.add_child(face)
	var hands: Dictionary = definition.get("hands", {})
	_hour_pivot = _hand(float(hands.get("hour", 0.075)), 0.016, at + Vector3(0, 0, 0.004), true)
	_minute_pivot = _hand(float(hands.get("minute", 0.11)), 0.009, at + Vector3(0, 0, 0.008), false)
	var cap := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.006
	cm.bottom_radius = 0.006
	cm.height = 0.004
	cap.mesh = cm
	cap.rotation.x = PI * 0.5
	cap.material_override = PropModels.brass()
	cap.position = at + Vector3(0, 0, 0.011)
	_works.add_child(cap)
	# The pendulum: a rod from its pivot and a brass bob (a lens).
	var p := _pend()
	var pat := Vector3(p.at[0], p.at[1], p.at[2])
	_pendulum = Node3D.new()
	_pendulum.name = "Pendulum"
	_pendulum.position = pat
	_works.add_child(_pendulum)
	var len := float(p.get("length", 0.46))
	var rod := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(0.004, len, 0.003)
	rod.mesh = rm
	rod.material_override = PropModels.brass()
	rod.position = Vector3(0, -len * 0.5, 0)
	_pendulum.add_child(rod)
	var bob := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = float(p.get("bob", 0.042))
	bm.bottom_radius = bm.top_radius
	bm.height = 0.012
	bob.mesh = bm
	bob.rotation.x = PI * 0.5
	bob.material_override = PropModels.brass()
	bob.position = Vector3(0, -len, 0)
	_pendulum.add_child(bob)


## A hand: a flat shape pointing at twelve (+Y) on a pivot at `at`, its tail behind the pivot.
func _hand(length: float, width: float, at: Vector3, spade: bool) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at
	_works.add_child(pivot)
	var pts := PackedVector2Array()
	var w := width * 0.5
	var s := 0.0015  # the shaft's half width
	if spade:  # the hour hand: a spade at two thirds
		pts = PackedVector2Array([Vector2(-s, -length * 0.2), Vector2(-s, length * 0.42), Vector2(-w, length * 0.58),
				Vector2(0, length), Vector2(w, length * 0.58), Vector2(s, length * 0.42), Vector2(s, -length * 0.2)])
	else:  # the minute hand: a long spear with a small diamond near the tip
		pts = PackedVector2Array([Vector2(-s, -length * 0.18), Vector2(-s, length * 0.72), Vector2(-w, length * 0.82),
				Vector2(0, length), Vector2(w, length * 0.82), Vector2(s, length * 0.72), Vector2(s, -length * 0.18)])
	var mi := MeshInstance3D.new()
	mi.mesh = _prism(pts, 0.002)
	mi.material_override = PropModels.iron()
	pivot.add_child(mi)
	return pivot


## A polygon (counter-clockwise, in x, y) pushed out `thick` in z: front, back and sides.
static func _prism(poly: PackedVector2Array, thick: float) -> ArrayMesh:
	var tri := Geometry2D.triangulate_polygon(poly)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hz := thick * 0.5
	for i in range(0, tri.size(), 3):
		var t := [poly[tri[i]], poly[tri[i + 1]], poly[tri[i + 2]]]
		# triangulate_polygon winds either way: face the front (+z) whichever it is.
		if (t[1] - t[0]).cross(t[2] - t[0]) < 0.0:
			t = [t[0], t[2], t[1]]
		for v: Vector2 in t:
			st.set_normal(Vector3.BACK)
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(Vector3(v.x, v.y, hz))
		for k in [0, 2, 1]:
			st.set_normal(Vector3.FORWARD)
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(Vector3(t[k].x, t[k].y, -hz))
	var n := poly.size()
	var ccw := 1.0 if Geometry2D.is_polygon_clockwise(poly) == false else -1.0
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var out := Vector3((b - a).y, -(b - a).x, 0.0).normalized() * ccw
		var quad := [Vector3(a.x, a.y, hz), Vector3(b.x, b.y, hz), Vector3(b.x, b.y, -hz), Vector3(a.x, a.y, -hz)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(out)
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(quad[k])
	return st.commit()


## A round dial facing +Z, uv across it.
static func _disc(r: float, segments: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments:
		var a0 := TAU * i / segments
		var a1 := TAU * (i + 1) / segments
		for p: Vector2 in [Vector2.ZERO, Vector2(cos(a0), sin(a0)), Vector2(cos(a1), sin(a1))]:
			st.set_normal(Vector3.BACK)
			st.set_uv(Vector2(0.5 + p.x * 0.5, 0.5 - p.y * 0.5))
			st.add_vertex(Vector3(p.x * r, p.y * r, 0.0))
	return st.commit()


## The dial painted: enamel, a minute track, hour bars and Roman numerals (strokes), facing out round
## the ring. `size` pixels across.
static func dial_image(size: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var enamel := Color(0.88, 0.85, 0.74)
	var ink := Color(0.07, 0.06, 0.05)
	img.fill(enamel)
	var c := Vector2(size, size) * 0.5
	var R := size * 0.5
	for i in 60:
		var a := TAU * i / 60.0
		var d := Vector2(sin(a), -cos(a))
		var hour := i % 5 == 0
		_stroke(img, c + d * R * (0.78 if hour else 0.86), c + d * R * 0.93, 2.2 if hour else 1.2, ink)
	_ring(img, c, R * 0.93, 1.3, ink)
	_ring(img, c, R * 0.76, 1.0, ink)
	var numerals := ["XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
	for h in 12:
		_numeral(img, c, R, h, numerals[h], ink)
	return img


static func _numeral(img: Image, c: Vector2, R: float, h: int, text: String, ink: Color) -> void:
	var a := TAU * h / 12.0
	var out := Vector2(sin(a), -cos(a))
	var side := Vector2(cos(a), sin(a))  # along the numeral's line of letters
	var mid := c + out * R * 0.60
	var hgt := R * 0.17
	var wch := R * 0.075
	var n := text.length()
	for k in n:
		var cx := (float(k) - (n - 1) * 0.5) * wch * 1.1
		var base := mid + side * cx
		var up := out
		match text[k]:
			"I":
				_stroke(img, base - up * hgt, base + up * hgt, 1.8, ink)
			"V":
				_stroke(img, base - side * wch * 0.5 + up * hgt, base - up * hgt, 1.6, ink)
				_stroke(img, base + side * wch * 0.5 + up * hgt, base - up * hgt, 1.6, ink)
			"X":
				_stroke(img, base - side * wch * 0.5 + up * hgt, base + side * wch * 0.5 - up * hgt, 1.6, ink)
				_stroke(img, base + side * wch * 0.5 + up * hgt, base - side * wch * 0.5 - up * hgt, 1.6, ink)


static func _stroke(img: Image, a: Vector2, b: Vector2, width: float, col: Color) -> void:
	var steps := int(maxf(a.distance_to(b) * 2.0, 1.0))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / steps)
		var r := width * 0.5
		for y in range(int(floor(p.y - r)), int(ceil(p.y + r)) + 1):
			for x in range(int(floor(p.x - r)), int(ceil(p.x + r)) + 1):
				if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and Vector2(x + 0.5, y + 0.5).distance_to(p) <= r:
					img.set_pixel(x, y, col)


static func _ring(img: Image, c: Vector2, radius: float, width: float, col: Color) -> void:
	var steps := int(radius * TAU * 2.0)
	for i in steps:
		var a := TAU * i / steps
		var p := c + Vector2(sin(a), -cos(a)) * radius
		_stroke(img, p, p, width, col)
