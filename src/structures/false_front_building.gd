class_name FalseFrontBuilding
extends Structure
## A false-front frontier store, framed member by member the way a carpenter would: mud sills,
## floor joists and boards, balloon-framed stud walls with king studs, headers and cripples around
## the openings, top plates, rafters, ridge and roof boards, lap siding on the false front and
## rough vertical boards (with the odd gap the light gets through) on the sides and back, plus a
## porch awning on posts, a counter and shelves.
##
## Local space: the front-left corner is the origin, the front faces -Z (the street) and the
## building runs back along +Z.

@export var width := 6.0
@export var depth := 9.0
## Top of the side-wall plates above the ground.
@export var wall_height := 3.2
## Top of the false front.
@export var front_height := 6.0
@export var roof_pitch_degrees := 28.0
@export var stud_spacing := 0.6
@export var floor_top := 0.38
@export var eave_overhang := 0.3
## How far the porch awning reaches out over the boardwalk.
@export var porch_depth := 2.2
@export var sign_text := "DRY GOODS"
## Ambient light indoors at night: a dim bounce from the lamps. Busier, better-lit places set more.
@export var night_ambient := 0.04

const SILL := 0.2
const STUD_W := 0.05
const STUD_D := 0.1
const BOARD_T := 0.025
const PLATE_H := 0.1
const HEADER_H := 0.15
const RAFTER_W := 0.05
const RAFTER_D := 0.15
const TRIM_T := 0.02
const TRIM_W := 0.1
const LAP_BOARD_H := 0.2
const VERTICAL_BOARD_W := 0.24
const JOIST_W := 0.06

## The front door opening, in front-wall space (x along the wall, y above the ground).
var door_rect := Rect2()


func build() -> void:
	var w := width
	var d := depth
	var tanp := tan(deg_to_rad(roof_pitch_degrees))
	door_rect = Rect2(w * 0.5 - 0.55, floor_top, 1.1, 2.2)

	_build_floor()

	var front := _wall("front", Vector3.ZERO, Vector3.RIGHT, Vector3.FORWARD, w, 0.0, w)
	var back := _wall("back", Vector3(0, 0, d), Vector3.RIGHT, Vector3.BACK, w, 0.0, w)
	var left := _wall("left", Vector3.ZERO, Vector3.BACK, Vector3.LEFT, d, STUD_D, d - STUD_D)
	var right := _wall("right", Vector3(w, 0, 0), Vector3.BACK, Vector3.RIGHT, d, STUD_D, d - STUD_D)

	var front_openings: Array[Rect2] = [door_rect, Rect2(0.55, 1.05, 1.1, 1.35), Rect2(w - 1.65, 1.05, 1.1, 1.35)]
	var right_openings: Array[Rect2] = [Rect2(d * 0.55 - 0.5, 1.2, 1.0, 1.0)]
	var back_openings: Array[Rect2] = [Rect2(w * 0.5 - 0.4, 1.3, 0.8, 0.8)]
	var no_openings: Array[Rect2] = []

	var side_top := func(_x: float) -> float: return wall_height - PLATE_H
	var front_top := func(_x: float) -> float: return front_height
	# The back wall is a gable end: studs and boards run up to the underside of the roof.
	var gable_top := func(x: float) -> float:
		return wall_height + maxf(minf(x, w - x) - STUD_W * 0.5, 0.0) * tanp
	var gable_board_top := func(x: float) -> float:
		return wall_height + maxf(minf(x, w - x), 0.0) * tanp + RAFTER_D

	_frame_wall(front, front_top, front_openings)
	_frame_wall(back, gable_top, back_openings)
	_frame_wall(left, side_top, no_openings)
	_frame_wall(right, side_top, right_openings)
	for wall in [left, right]:
		_wall_member("%s/plate" % wall.name, &"plate", &"framing", wall, wall.x_start, wall.x_end,
				wall_height - PLATE_H, wall_height, -STUD_D, 0.0)

	_lap_siding(front, front_height, front_openings, &"painted_ochre")
	_vertical_siding(left, func(_x: float) -> float: return wall_height, no_openings, -BOARD_T, d)
	_vertical_siding(right, func(_x: float) -> float: return wall_height, right_openings, -BOARD_T, d)
	_vertical_siding(back, gable_board_top, back_openings, -BOARD_T, w + BOARD_T)

	for o in front_openings:
		_opening_trim(front, o, o != door_rect)
		if o != door_rect:
			_glass(front, o)
	_opening_trim(right, right_openings[0], true)
	_glass(right, right_openings[0])
	_opening_trim(back, back_openings[0], true)
	_glass(back, back_openings[0])

	_build_false_front(front)
	_build_door()
	_build_roof(tanp)
	_build_porch()
	_build_furniture()
	_add_interior_ambient()


## The sky's ambient light shouldn't fill the inside of a closed building. This probe replaces it
## indoors with a dim warm bounce that DayCycle scales with daylight.
func _add_interior_ambient() -> void:
	var probe := ReflectionProbe.new()
	probe.name = "InteriorAmbient"
	var ridge := wall_height + width * 0.5 * tan(deg_to_rad(roof_pitch_degrees))
	probe.size = Vector3(width - STUD_D * 2.0, ridge, depth - STUD_D * 2.0)
	probe.position = Vector3(width * 0.5, ridge * 0.5, depth * 0.5)
	probe.interior = true
	probe.box_projection = true
	probe.intensity = 0.4
	probe.blend_distance = 0.3
	probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	probe.ambient_color = Color(1.0, 0.82, 0.62)
	probe.ambient_color_energy = 0.45
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.set_meta(&"night_ambient", night_ambient)
	probe.add_to_group(&"interior_ambient")
	add_child(probe)


## A wall is a line of framing. Positions on it are (x along, y up, d outward from the stud face).
func _wall(n: String, origin: Vector3, along: Vector3, outward: Vector3, length: float, x_start: float, x_end: float) -> Dictionary:
	return {"name": n, "origin": origin, "along": along, "out": outward, "length": length,
			"x_start": x_start, "x_end": x_end}


func _wall_member(id_path: String, kind: StringName, wood: StringName, wall: Dictionary,
		x0: float, x1: float, y0: float, y1: float, d0: float, d1: float) -> StructureMember:
	var along: Vector3 = wall.along
	var out: Vector3 = wall.out
	var center: Vector3 = wall.origin + along * ((x0 + x1) * 0.5) + Vector3.UP * ((y0 + y1) * 0.5) + out * ((d0 + d1) * 0.5)
	var size := along.abs() * (x1 - x0) + Vector3(0.0, y1 - y0, 0.0) + out.abs() * (d1 - d0)
	return add_member(id_path, kind, wood, size, center)


func _build_floor() -> void:
	var w := width
	var d := depth
	# Mud sills straight on the ground around the perimeter.
	add_member("sill/front", &"sill", &"framing", Vector3(w, SILL, SILL), Vector3(w * 0.5, SILL * 0.5, SILL * 0.5))
	add_member("sill/back", &"sill", &"framing", Vector3(w, SILL, SILL), Vector3(w * 0.5, SILL * 0.5, d - SILL * 0.5))
	add_member("sill/left", &"sill", &"framing", Vector3(SILL, SILL, d - SILL * 2.0), Vector3(SILL * 0.5, SILL * 0.5, d * 0.5))
	add_member("sill/right", &"sill", &"framing", Vector3(SILL, SILL, d - SILL * 2.0), Vector3(w - SILL * 0.5, SILL * 0.5, d * 0.5))
	# Joists run front to back, resting on the front and back sills.
	var joist_top := floor_top - BOARD_T
	var i := 0
	var x := 0.35
	while x < w - 0.3:
		add_member("floor/joist/%02d" % i, &"joist", &"framing", Vector3(JOIST_W, joist_top - SILL, d - STUD_D * 2.0),
				Vector3(x, (SILL + joist_top) * 0.5, d * 0.5))
		x += stud_spacing
		i += 1
	# Floor boards across the joists.
	i = 0
	var z := STUD_D + 0.02
	while z < d - STUD_D - 0.02:
		var bw := minf(0.145, d - STUD_D - 0.02 - z)
		add_member("floor/board/%02d" % i, &"floor_board", &"floor", Vector3(w - STUD_D * 2.0, BOARD_T, bw),
				Vector3(w * 0.5, joist_top + BOARD_T * 0.5, z + bw * 0.5))
		z += 0.15
		i += 1
	# A heavy threshold in the doorway, bridging the front sill and the porch.
	add_member("floor/threshold", &"floor_board", &"dark_trim", Vector3(door_rect.size.x, floor_top - SILL, STUD_D + 0.05),
			Vector3(door_rect.get_center().x, (SILL + floor_top) * 0.5, STUD_D * 0.5 - 0.025))


## Studs at regular spacing, with king studs beside each opening, headers over them, rough sills
## under windows and cripples above and below.
func _frame_wall(wall: Dictionary, top_at: Callable, openings: Array[Rect2]) -> void:
	var n: String = wall.name
	var x_start: float = wall.x_start
	var x_end: float = wall.x_end
	var xs: Array[float] = []
	var x := x_start + STUD_W * 0.5
	while x <= x_end - STUD_W * 0.5 + 0.001:
		xs.append(x)
		x += stud_spacing
	if x_end - STUD_W * 0.5 - xs.back() > 0.1:
		xs.append(x_end - STUD_W * 0.5)

	var count := 0
	for sx in xs:
		var inside := -1
		var blocked := false
		for j in openings.size():
			var o := openings[j]
			if sx > o.position.x and sx < o.end.x:
				inside = j
			elif sx + STUD_W * 0.5 > o.position.x - STUD_W - 0.01 and sx - STUD_W * 0.5 < o.end.x + STUD_W + 0.01:
				blocked = true  # a king stud goes here instead
		if blocked and inside < 0:
			continue
		var top: float = top_at.call(sx)
		if inside < 0:
			_wall_member("%s/stud/%02d" % [n, count], &"stud", &"framing", wall, sx - STUD_W * 0.5, sx + STUD_W * 0.5, SILL, top, -STUD_D, 0.0)
		else:
			var o := openings[inside]
			if o.position.y > floor_top + 0.05:
				_wall_member("%s/stud/%02d" % [n, count], &"stud", &"framing", wall, sx - STUD_W * 0.5, sx + STUD_W * 0.5,
						SILL, o.position.y - PLATE_H, -STUD_D, 0.0)
			var above := o.end.y + HEADER_H
			if top - above > 0.05:
				_wall_member("%s/cripple/%02d" % [n, count], &"cripple", &"framing", wall, sx - STUD_W * 0.5, sx + STUD_W * 0.5,
						above, top, -STUD_D, 0.0)
		count += 1

	for j in openings.size():
		var o := openings[j]
		for side in 2:
			var kx := o.position.x - STUD_W * 0.5 if side == 0 else o.end.x + STUD_W * 0.5
			_wall_member("%s/opening%d/king%d" % [n, j, side], &"stud", &"framing", wall, kx - STUD_W * 0.5, kx + STUD_W * 0.5,
					SILL, top_at.call(kx), -STUD_D, 0.0)
		_wall_member("%s/opening%d/header" % [n, j], &"header", &"framing", wall, o.position.x, o.end.x,
				o.end.y, o.end.y + HEADER_H, -STUD_D, 0.0)
		if o.position.y > floor_top + 0.05:
			_wall_member("%s/opening%d/sill" % [n, j], &"header", &"framing", wall, o.position.x, o.end.x,
					o.position.y - PLATE_H, o.position.y, -STUD_D, 0.0)


## Horizontal lap boards, cut around the openings.
func _lap_siding(wall: Dictionary, top: float, openings: Array[Rect2], wood: StringName) -> void:
	var n: String = wall.name
	var length: float = wall.length
	var row := 0
	var y := 0.05
	while y < top - 0.01:
		var y1 := minf(y + LAP_BOARD_H - 0.005, top)
		var cuts: Array[Vector2] = []
		for o in openings:
			if o.position.y < y1 and o.end.y > y:
				cuts.append(Vector2(o.position.x, o.end.x))
		var segment := 0
		for span in _subtract_spans(Vector2(0.0, length), cuts):
			if span.y - span.x > 0.04:
				_wall_member("%s/siding/r%02d_%d" % [n, row, segment], &"board", wood, wall, span.x, span.y, y, y1, 0.0, BOARD_T)
				segment += 1
		y += LAP_BOARD_H
		row += 1


## Rough vertical boards with narrow gaps (and the occasional wide one), cut around openings.
func _vertical_siding(wall: Dictionary, top_at: Callable, openings: Array[Rect2], x_from: float, x_to: float) -> void:
	var n: String = wall.name
	var col := 0
	var x := x_from
	while x < x_to - 0.02:
		var x1 := minf(x + VERTICAL_BOARD_W, x_to)
		var top := minf(top_at.call(x), top_at.call(x1))
		var cuts: Array[Vector2] = []
		for o in openings:
			if o.position.x < x1 and o.end.x > x:
				cuts.append(Vector2(o.position.y, o.end.y))
		var piece := 0
		for span in _subtract_spans(Vector2(0.05, top), cuts):
			if span.y - span.x > 0.04:
				_wall_member("%s/siding/c%02d_%d" % [n, col, piece], &"board", &"weathered_pine", wall, x, x1, span.x, span.y, 0.0, BOARD_T)
				piece += 1
		var gap := 0.035 if chance(0.12) else 0.012
		x = x1 + gap
		col += 1


func _opening_trim(wall: Dictionary, o: Rect2, is_window: bool) -> void:
	var n := "%s/trim_%d_%d" % [wall.name, int(o.position.x * 100.0), int(o.position.y * 100.0)]
	var d0 := BOARD_T
	var d1 := BOARD_T + TRIM_T
	var bottom := o.position.y - (TRIM_W if is_window else 0.0)
	_wall_member(n + "/jamb0", &"trim", &"dark_trim", wall, o.position.x - TRIM_W, o.position.x, bottom, o.end.y, d0, d1)
	_wall_member(n + "/jamb1", &"trim", &"dark_trim", wall, o.end.x, o.end.x + TRIM_W, bottom, o.end.y, d0, d1)
	_wall_member(n + "/head", &"trim", &"dark_trim", wall, o.position.x - TRIM_W, o.end.x + TRIM_W, o.end.y, o.end.y + TRIM_W, d0, d1)
	if is_window:
		_wall_member(n + "/stool", &"trim", &"dark_trim", wall, o.position.x - TRIM_W * 1.5, o.end.x + TRIM_W * 1.5,
				o.position.y - 0.04, o.position.y, d0, d0 + 0.06)


func _glass(wall: Dictionary, o: Rect2) -> void:
	var n := "%s/glass_%d_%d" % [wall.name, int(o.position.x * 100.0), int(o.position.y * 100.0)]
	var m := _wall_member(n, &"glass", &"glass", wall, o.position.x, o.end.x, o.position.y, o.end.y, -0.06, -0.054)
	m.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_false_front(front: Dictionary) -> void:
	var w := width
	var d0 := BOARD_T
	# Corner boards, cornice and cap.
	_wall_member("front/corner_left", &"trim", &"dark_trim", front, -BOARD_T, 0.12, 0.05, front_height, d0, d0 + TRIM_T)
	_wall_member("front/corner_right", &"trim", &"dark_trim", front, w - 0.12, w + BOARD_T, 0.05, front_height, d0, d0 + TRIM_T)
	_wall_member("front/cornice", &"trim", &"dark_trim", front, -0.15, w + 0.15, front_height - 0.3, front_height - 0.05, d0, d0 + 0.18)
	_wall_member("front/cornice_band", &"trim", &"dark_trim", front, -0.05, w + 0.05, front_height - 0.55, front_height - 0.45, d0, d0 + 0.05)
	_wall_member("front/cap", &"trim", &"dark_trim", front, -0.2, w + 0.2, front_height, front_height + 0.04, -STUD_D - 0.02, d0 + 0.22)
	# The sign board.
	var sign := _wall_member("front/sign", &"trim", &"sign", front, 0.7, w - 0.7, 4.15, 5.1, d0, d0 + 0.03)
	var label := Label3D.new()
	label.name = "SignText"
	label.text = sign_text
	# Low font size, big pixels, no smoothing: chunky painted-on pixel lettering.
	label.font_size = 20
	label.pixel_size = 0.028
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	label.outline_size = 0
	label.modulate = Color(0.18, 0.12, 0.09)
	label.shaded = true
	label.double_sided = false
	label.position = Vector3(0.0, 0.0, -0.017)
	label.rotation.y = PI
	sign.add_child(label)


## The door stands open, swung into the store.
func _build_door() -> void:
	var leaf := Vector3(door_rect.size.x - 0.05, door_rect.size.y - 0.05, 0.04)
	var basis := Basis(Vector3.UP, deg_to_rad(-92.0))
	var hinge := Vector3(door_rect.position.x + 0.03, floor_top + 0.01, STUD_D + 0.03)
	var center := hinge + basis * Vector3(leaf.x * 0.5, leaf.y * 0.5, 0.0)
	add_member("front/door", &"door", &"painted_rust", leaf, center, basis)


func _build_roof(tanp: float) -> void:
	var w := width
	var d := depth
	var p := deg_to_rad(roof_pitch_degrees)
	var run := w * 0.5 + eave_overhang
	var slope_length := run / cos(p)
	var ridge_y := wall_height + w * 0.5 * tanp

	var zs: Array[float] = []
	var z := STUD_D + 0.05
	while z + RAFTER_W <= d - STUD_D - RAFTER_W:
		zs.append(z)
		z += stud_spacing
	zs.append(d - STUD_D - RAFTER_W)

	for side in 2:
		var s := 1.0 if side == 0 else -1.0  # left slope rises toward +X, right toward -X
		var basis := Basis(Vector3.BACK, p * s)
		var along := basis.x if side == 0 else -basis.x  # up the slope
		var normal := basis.y
		var eave := Vector3(-eave_overhang if side == 0 else w + eave_overhang, wall_height - eave_overhang * tanp, 0.0)
		var tag := "left" if side == 0 else "right"
		for i in zs.size():
			var bottom_mid := eave + along * (slope_length * 0.5)
			var c := bottom_mid + normal * (RAFTER_D * 0.5)
			c.z = zs[i] + RAFTER_W * 0.5
			add_member("roof/%s/rafter/%02d" % [tag, i], &"rafter", &"framing", Vector3(slope_length, RAFTER_D, RAFTER_W), c, basis)
		var row := 0
		var sl := 0.0
		while sl < slope_length - 0.02:
			var bw := minf(0.195, slope_length - sl)
			var c := eave + along * (sl + bw * 0.5) + normal * (RAFTER_D + BOARD_T * 0.5)
			var split := d * 0.5 + (0.6 if row % 2 == 0 else -0.6)
			var spans := [Vector2(STUD_D, split - 0.003), Vector2(split + 0.003, d + 0.25)]
			for k in spans.size():
				var span: Vector2 = spans[k]
				var cz := c
				cz.z = (span.x + span.y) * 0.5
				add_member("roof/%s/board/%02d_%d" % [tag, row, k], &"roof_board", &"weathered_pine",
						Vector3(bw, BOARD_T, span.y - span.x), cz, basis)
			sl += 0.2
			row += 1

	var cap_y := ridge_y + (RAFTER_D + BOARD_T) / cos(p)
	add_member("roof/ridge", &"ridge", &"framing", Vector3(0.03, cap_y - 0.005 - (ridge_y - 0.02), d - STUD_D),
			Vector3(w * 0.5, (cap_y - 0.005 + ridge_y - 0.02) * 0.5, (STUD_D + d) * 0.5))
	add_member("roof/ridge_cap", &"trim", &"dark_trim", Vector3(0.34, BOARD_T, d + 0.15 - STUD_D),
			Vector3(w * 0.5, cap_y + BOARD_T * 0.5 - 0.005, (STUD_D + d + 0.25) * 0.5))


## Porch awning over the boardwalk: two posts, a beam, a ledger on the facade, rafters, boards.
## The lantern bracket is here too.
func _build_porch() -> void:
	var w := width
	var post := 0.14
	var beam_y0 := 3.0
	var beam_y1 := 3.18
	var ledger_y1 := 3.37
	var zb := -porch_depth
	for i in 2:
		var px := post * 0.5 + 0.05 if i == 0 else w - post * 0.5 - 0.05
		add_member("porch/post%d" % i, &"post", &"framing", Vector3(post, beam_y0, post), Vector3(px, beam_y0 * 0.5, zb))
	add_member("porch/beam", &"beam", &"framing", Vector3(w + 0.2, beam_y1 - beam_y0, 0.16), Vector3(w * 0.5, (beam_y0 + beam_y1) * 0.5, zb))
	add_member("porch/ledger", &"ledger", &"framing", Vector3(w, 0.15, 0.05), Vector3(w * 0.5, ledger_y1 - 0.075, -0.025))

	var a := atan2(ledger_y1 - beam_y1, -0.05 - zb)
	var basis := Basis(Vector3.RIGHT, -a)
	var up_slope := basis.z  # toward the building, rising
	var z_start := zb - 0.3
	var start := Vector3(0.0, beam_y1 - (zb - z_start) * tan(a), z_start)
	var length := (-0.05 - z_start) / cos(a)
	var i := 0
	var x := 0.2
	while x < w - 0.1:
		var c := start + up_slope * (length * 0.5) + basis.y * 0.06
		c.x = x
		add_member("porch/rafter/%02d" % i, &"rafter", &"framing", Vector3(0.05, 0.12, length), c, basis)
		x += 0.75
		i += 1
	i = 0
	var sl := 0.0
	while sl < length - 0.02:
		var bw := minf(0.195, length - sl)
		var c := start + up_slope * (sl + bw * 0.5) + basis.y * (0.12 + BOARD_T * 0.5)
		c.x = w * 0.5
		add_member("porch/board/%02d" % i, &"roof_board", &"weathered_pine", Vector3(w + 0.3, BOARD_T, bw), c, basis)
		sl += 0.2
		i += 1

	var lantern_x := door_rect.end.x + 0.55
	add_member("front/lantern_bracket", &"trim", &"dark_trim", Vector3(0.03, 0.03, 0.34), Vector3(lantern_x, 2.85, -BOARD_T - 0.17))
	var lantern := OilLamp.new()
	lantern.name = "PorchLantern"
	lantern.hanging = true
	lantern.energy = 1.2
	lantern.light_range = 6.5
	lantern.position = Vector3(lantern_x, 2.42, -BOARD_T - 0.3)
	add_child(lantern)


func _build_furniture() -> void:
	var w := width
	var f := floor_top
	# Counter along the right-hand wall.
	var cx0 := w - 1.35
	var cx1 := w - 0.75
	var cz0 := 2.2
	var cz1 := 5.2
	add_member("counter/front", &"furniture_frame", &"floor", Vector3(0.03, 0.95, cz1 - cz0), Vector3(cx0 + 0.015, f + 0.475, (cz0 + cz1) * 0.5))
	add_member("counter/end0", &"furniture_frame", &"floor", Vector3(cx1 - cx0, 0.95, 0.03), Vector3((cx0 + cx1) * 0.5, f + 0.475, cz0 + 0.015))
	add_member("counter/end1", &"furniture_frame", &"floor", Vector3(cx1 - cx0, 0.95, 0.03), Vector3((cx0 + cx1) * 0.5, f + 0.475, cz1 - 0.015))
	add_member("counter/top", &"furniture_top", &"dark_trim", Vector3(cx1 - cx0 + 0.08, 0.04, cz1 - cz0 + 0.06),
			Vector3((cx0 + cx1) * 0.5 - 0.02, f + 0.97, (cz0 + cz1) * 0.5))
	var lamp := OilLamp.new()
	lamp.name = "CounterLamp"
	lamp.position = Vector3((cx0 + cx1) * 0.5, f + 0.99, cz0 + 0.8)
	add_child(lamp)

	# Shelves along the left-hand wall.
	var sx0 := STUD_D
	var sx1 := STUD_D + 0.38
	for i in 3:
		var z := 3.0 + i * 2.0
		add_member("shelves/upright%d" % i, &"furniture_frame", &"framing", Vector3(sx1 - sx0, 2.1, 0.03), Vector3((sx0 + sx1) * 0.5, f + 1.05, z))
	for i in 4:
		var y := f + 0.35 + i * 0.55
		add_member("shelves/shelf%d" % i, &"furniture_top", &"floor", Vector3(sx1 - sx0, 0.025, 4.06), Vector3((sx0 + sx1) * 0.5, y, 5.0))


## Remove `cuts` (each Vector2(from, to)) from `span`, returning what is left.
static func _subtract_spans(span: Vector2, cuts: Array[Vector2]) -> Array[Vector2]:
	var result: Array[Vector2] = [span]
	for cut in cuts:
		var next: Array[Vector2] = []
		for s in result:
			if cut.y <= s.x or cut.x >= s.y:
				next.append(s)
				continue
			if cut.x > s.x:
				next.append(Vector2(s.x, cut.x))
			if cut.y < s.y:
				next.append(Vector2(cut.y, s.y))
		result = next
	return result
