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
## The porch beam's underside above the ground (the saloon raises it over its tall door).
@export var porch_height := 3.0
@export var sign_text := "DRY GOODS"
## Ambient light indoors at night: a dim bounce from the lamps. Busier, better-lit places set more.
@export var night_ambient := 0.04
## Haze in the room (fog density): tobacco smoke in a saloon, so the lamps glow in the air.
@export var room_haze := 0.0

@export_group("Shape")
## The front's boards: lap siding in this wood (painted_ochre, or weathered_pine bare boards).
@export var front_wood: StringName = &"painted_ochre"
## The front door's width and height. Wider than 1.6 m it's a pair of leaves.
@export var door_size := Vector2(1.1, 2.2)
## The two front windows either side of the door.
@export var front_windows := true
## Iron bars across the windows (a jail).
@export var window_bars := false
## Saloon batwings: a pair of short swinging leaves across the doorway (the door stands open).
@export var batwings := false
## The street painting's parts on the front (FacadeArt, art): "saloon", "store" or none.
@export var facade := ""
## A barn: the front is a gable end (no false front), boarded up and down, with a loft door
## under the ridge (`loft_door`: its rect in front-wall space; empty = none).
@export var gable_front := false
@export var loft_door := Rect2()
## Where the painted sign may go on the front: from this height up to the cornice. Negative:
## just over the side walls (the usual). Two-storey fronts set it over the porch roof.
@export var sign_from := -1.0
## A painted board on a gable front: its rect in front-wall space (empty = none).
@export var gable_sign := Rect2()
## A porch awning over the boardwalk, and a lantern hung under it.
@export var porch := true
@export var porch_lantern := true
## Counter, shelves and the counter lamp inside.
@export var furnished := true
## What's inside when furnished: &"store" (counter, shelves), &"telegraph" (a counter, the
## operator's desk with his key and sounder, battery jars), &"doctor" (a desk, an operating
## table, a cot, a cabinet of bottles), &"bank" (a teller's counter with its cage of bars, a
## safe, a desk). Everything's members (it burns, breaks and falls like the walls) with a lamp.
@export var interior: StringName = &"store"

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
	door_rect = Rect2(w * 0.5 - door_size.x * 0.5, floor_top, door_size.x, door_size.y)

	_build_floor()

	var front := _wall("front", Vector3.ZERO, Vector3.RIGHT, Vector3.FORWARD, w, 0.0, w)
	var back := _wall("back", Vector3(0, 0, d), Vector3.RIGHT, Vector3.BACK, w, 0.0, w)
	var left := _wall("left", Vector3.ZERO, Vector3.BACK, Vector3.LEFT, d, STUD_D, d - STUD_D)
	var right := _wall("right", Vector3(w, 0, 0), Vector3.BACK, Vector3.RIGHT, d, STUD_D, d - STUD_D)

	var front_openings: Array[Rect2] = [door_rect]
	if front_windows:
		# Sills at a height above the floor (the saloon's floor stands higher than the rest).
		front_openings.append_array([Rect2(0.55, floor_top + 0.67, 1.1, 1.35), Rect2(w - 1.65, floor_top + 0.67, 1.1, 1.35)])
	if loft_door.has_area():
		front_openings.append(loft_door)
	var right_openings: Array[Rect2] = [Rect2(d * 0.55 - 0.5, floor_top + 0.82, 1.0, 1.0)]
	var back_openings: Array[Rect2] = [Rect2(w * 0.5 - 0.4, floor_top + 0.92, 0.8, 0.8)]
	var no_openings: Array[Rect2] = []

	var side_top := func(_x: float) -> float: return wall_height - PLATE_H
	var front_top := func(_x: float) -> float: return front_height
	# The back wall is a gable end: studs and boards run up to the underside of the roof.
	var gable_top := func(x: float) -> float:
		return wall_height + maxf(minf(x, w - x) - STUD_W * 0.5, 0.0) * tanp
	var gable_board_top := func(x: float) -> float:
		return wall_height + maxf(minf(x, w - x), 0.0) * tanp + RAFTER_D

	_frame_wall(front, gable_top if gable_front else front_top, front_openings)
	_frame_wall(back, gable_top, back_openings)
	_frame_wall(left, side_top, no_openings)
	_frame_wall(right, side_top, right_openings)
	for wall in [left, right]:
		_wall_member("%s/plate" % wall.name, &"plate", &"framing", wall, wall.x_start, wall.x_end,
				wall_height - PLATE_H, wall_height, -STUD_D, 0.0)

	if gable_front:
		_vertical_siding(front, gable_board_top, front_openings, -BOARD_T, w + BOARD_T, front_wood)
	else:
		_lap_siding(front, front_height, front_openings, front_wood)
	_vertical_siding(left, func(_x: float) -> float: return wall_height, no_openings, -BOARD_T, d)
	_vertical_siding(right, func(_x: float) -> float: return wall_height, right_openings, -BOARD_T, d)
	_vertical_siding(back, gable_board_top, back_openings, -BOARD_T, w + BOARD_T)

	for o in front_openings:
		var window := o != door_rect and o != loft_door
		_opening_trim(front, o, window)
		if window:
			_glass(front, o)
			if window_bars:
				_bars(front, o)
	_opening_trim(right, right_openings[0], true)
	_glass(right, right_openings[0])
	_opening_trim(back, back_openings[0], true)
	_glass(back, back_openings[0])

	if gable_front:
		_hang_gable_sign()
	else:
		_build_false_front(front)
	_build_door()
	if batwings:
		_build_batwings()
	_build_roof(tanp)
	if porch:
		_build_porch()
	if furnished:
		_build_furniture()
	_add_interior_ambient()
	FacadeArt.dress(self)  # the painting's parts on a front that asks for them (art)


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
	if room_haze > 0.0 and GunSmoke.supports_fog_volumes():
		var haze := FogVolume.new()
		haze.name = "RoomHaze"
		haze.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
		haze.size = probe.size
		haze.position = probe.position
		var fm := FogMaterial.new()
		fm.density = room_haze
		fm.albedo = Color(0.72, 0.66, 0.6)
		fm.height_falloff = 0.4  # thicker up under the roof, where the smoke collects
		haze.material = fm
		add_child(haze)


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
func _vertical_siding(wall: Dictionary, top_at: Callable, openings: Array[Rect2], x_from: float, x_to: float,
		wood: StringName = &"weathered_pine") -> void:
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
				_wall_member("%s/siding/c%02d_%d" % [n, col, piece], &"board", wood, wall, x, x1, span.x, span.y, 0.0, BOARD_T)
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


## Square iron bars set in the window's frame, a hand apart.
func _bars(wall: Dictionary, o: Rect2) -> void:
	var n := "%s/bars_%d_%d" % [wall.name, int(o.position.x * 100.0), int(o.position.y * 100.0)]
	var count := maxi(int(o.size.x / 0.14), 2)
	for i in count:
		var x := o.position.x + o.size.x * (i + 0.5) / count
		_wall_member("%s/%d" % [n, i], &"trim", &"dark_trim", wall, x - 0.011, x + 0.011, o.position.y, o.end.y, -0.04, -0.018)


## Where the painted sign may go on the false front: the bottom of the room for it.
func sign_room_bottom() -> float:
	return sign_from if sign_from >= 0.0 else wall_height + 0.15


## A gable front's painted board, on its boards (SignArt), for `sign_text`.
func _hang_gable_sign() -> void:
	if not gable_sign.has_area():
		return
	var id: StringName = SignArt.BOARDS.get(sign_text.to_upper(), &"")
	var painted := SignArt.board_size(id)
	if painted == Vector2.ZERO:
		return
	var k := minf(gable_sign.size.x / painted.x, gable_sign.size.y / painted.y)
	var mi := SignArt.board(id, painted * k)
	mi.name = "GableSign"
	add_child(mi)
	var c := gable_sign.get_center()
	mi.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(c.x, c.y, -BOARD_T - 0.015))


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
	# A painted board (art: SignArt, from the texture factory) where there's one for this text.
	if SignArt.hang(self, sign, sign_text):
		return
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


## The door stands open, swung into the store (a wide one is a pair of leaves, both open).
func _build_door() -> void:
	var leaves := 2 if door_rect.size.x > 1.6 else 1
	var leaf := Vector3(door_rect.size.x / leaves - 0.05, door_rect.size.y - 0.05, 0.04)
	for i in leaves:
		var right := i == 1
		var basis := Basis(Vector3.UP, deg_to_rad(92.0 if right else -92.0))
		var hinge := Vector3(door_rect.end.x - 0.03 if right else door_rect.position.x + 0.03, floor_top + 0.01, STUD_D + 0.03)
		var center := hinge + basis * Vector3((-1.0 if right else 1.0) * leaf.x * 0.5, leaf.y * 0.5, 0.0)
		add_member("front/door" if i == 0 else "front/door%d" % i, &"door", &"painted_rust", leaf, center, basis)


## Batwings: two slatted leaves meeting in the middle of the doorway, chest high.
func _build_batwings() -> void:
	# Each hangs on its king stud.
	var half := door_rect.size.x * 0.5 - 0.01
	for i in 2:
		var x0 := door_rect.position.x + 0.005 if i == 0 else door_rect.get_center().x + 0.005
		add_member("front/batwing%d" % i, &"door", &"dark_trim", Vector3(half, 1.15, 0.03),
				Vector3(x0 + half * 0.5, floor_top + 0.4 + 0.575, 0.02))


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
	var beam_y0 := porch_height
	var beam_y1 := porch_height + 0.18
	var ledger_y1 := porch_height + 0.37
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

	if not porch_lantern:
		return
	var lantern_x := door_rect.end.x + 0.55
	add_member("front/lantern_bracket", &"trim", &"dark_trim", Vector3(0.03, 0.03, 0.34), Vector3(lantern_x, porch_height - 0.15, -BOARD_T - 0.17))
	var lantern := OilLamp.new()
	lantern.name = "PorchLantern"
	lantern.hanging = true
	lantern.energy = 1.2
	lantern.light_range = 6.5
	lantern.position = Vector3(lantern_x, porch_height - 0.58, -BOARD_T - 0.3)
	add_child(lantern)


func _build_furniture() -> void:
	match interior:
		&"telegraph":
			_furnish_telegraph()
		&"doctor":
			_furnish_doctor()
		&"bank":
			_furnish_bank()
		_:
			_furnish_store()


func _furnish_store() -> void:
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


## A table of members: its top `h` over the floor across x0..x1, z0..z1, a leg at each corner.
func _table(id: String, x0: float, x1: float, z0: float, z1: float, h: float, top_wood: StringName = &"dark_trim") -> void:
	var f := floor_top
	const LEG := 0.05
	add_member("%s/top" % id, &"furniture_top", top_wood, Vector3(x1 - x0, 0.035, z1 - z0), Vector3((x0 + x1) * 0.5, f + h - 0.0175, (z0 + z1) * 0.5))
	for i in 4:
		var x := x0 + LEG * 0.5 + 0.03 if i % 2 == 0 else x1 - LEG * 0.5 - 0.03
		var z := z0 + LEG * 0.5 + 0.03 if i < 2 else z1 - LEG * 0.5 - 0.03
		add_member("%s/leg%d" % [id, i], &"furniture_frame", &"framing", Vector3(LEG, h - 0.035, LEG), Vector3(x, f + (h - 0.035) * 0.5, z))


## A counter across the room from the left wall to `x1` at depth z0..z1: a front, its ends and a top.
func _counter(id: String, x0: float, x1: float, z0: float, z1: float, top_wood: StringName = &"dark_trim") -> void:
	var f := floor_top
	add_member("%s/front" % id, &"furniture_frame", &"floor", Vector3(x1 - x0, 0.95, 0.03), Vector3((x0 + x1) * 0.5, f + 0.475, z0 + 0.015))
	add_member("%s/end" % id, &"furniture_frame", &"floor", Vector3(0.03, 0.95, z1 - z0 - 0.03), Vector3(x1 - 0.015, f + 0.475, (z0 + z1) * 0.5 + 0.015))
	add_member("%s/top" % id, &"furniture_top", top_wood, Vector3(x1 - x0, 0.04, z1 - z0 + 0.06), Vector3((x0 + x1) * 0.5, f + 0.97, (z0 + z1) * 0.5 - 0.03))


## Shelves on an upright pair against a wall at x0..x1 (deep across x), z0..z1, `n` boards.
func _shelves(id: String, x0: float, x1: float, z0: float, z1: float, n: int, height := 1.9) -> void:
	var f := floor_top
	for i in 2:
		var z := z0 + 0.015 if i == 0 else z1 - 0.015
		add_member("%s/upright%d" % [id, i], &"furniture_frame", &"framing", Vector3(x1 - x0, height, 0.03), Vector3((x0 + x1) * 0.5, f + height * 0.5, z))
	for i in n:
		var y := f + 0.3 + i * (height - 0.4) / maxf(n - 1, 1)
		add_member("%s/shelf%d" % [id, i], &"furniture_top", &"floor", Vector3(x1 - x0, 0.025, z1 - z0), Vector3((x0 + x1) * 0.5, y, (z0 + z1) * 0.5))


func _lamp_on(lamp_name: String, at: Vector3) -> OilLamp:
	var lamp := OilLamp.new()
	lamp.name = lamp_name
	lamp.position = at
	# No shadows: every lamp in town is in view through the walls (lights aren't hidden behind
	# them), and shadowed ones down the street took the saloon's lamps' shadow slots.
	lamp.casts_shadows = false
	add_child(lamp)
	return lamp


func _prop(id: StringName, at: Vector3, yaw_degrees := 0.0) -> Node3D:
	var props := get_node_or_null(^"Props") as Node3D
	if props == null:
		props = Node3D.new()
		props.name = "Props"
		add_child(props)
	var prop := PropLibrary.spawn(id)
	prop.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_degrees)), at)
	props.add_child(prop)
	return prop


## The telegraph office: a counter across the front room (a gap by the right wall to go behind
## it), the operator's desk against the left wall with his key, sounder and lamp, a stool, and the
## battery jars that drive the line on a shelf by the back wall.
func _furnish_telegraph() -> void:
	var w := width
	var f := floor_top
	_counter("counter", STUD_D, w - 1.1, 2.6, 3.2)
	_lamp_on("CounterLamp", Vector3(1.2, f + 0.99, 2.9))
	var dz0 := 4.2
	var dz1 := 5.8
	_table("desk", STUD_D, STUD_D + 0.7, dz0, dz1, 0.76)
	add_member("desk/key", &"furniture_top", &"iron", Vector3(0.1, 0.03, 0.16), Vector3(STUD_D + 0.45, f + 0.775, dz0 + 0.55))
	add_member("desk/sounder", &"furniture_top", &"dark_trim", Vector3(0.16, 0.1, 0.14), Vector3(STUD_D + 0.35, f + 0.81, dz0 + 1.05))
	_lamp_on("DeskLamp", Vector3(STUD_D + 0.3, f + 0.78, dz1 - 0.2))
	_prop(&"bar_stool", Vector3(STUD_D + 1.05, f, dz0 + 0.6))
	var back := depth - STUD_D
	_table("batteries", 1.6, 3.4, back - 0.45, back - 0.05, 0.8, &"floor")
	for i in 7:
		add_member("batteries/jar%d" % i, &"glass", &"glass", Vector3(0.12, 0.18, 0.12), Vector3(1.8 + i * 0.24, f + 0.8 + 0.09, back - 0.25))


## The doctor's: his desk and chair in the front room, and behind, the operating table under its
## lamp, a cot against the left wall and a cabinet of bottles against the right.
func _furnish_doctor() -> void:
	var w := width
	var f := floor_top
	_table("desk", STUD_D + 0.2, STUD_D + 1.6, 1.8, 2.6, 0.76)
	_lamp_on("DeskLamp", Vector3(STUD_D + 0.5, f + 0.78, 2.3))
	_prop(&"chair", Vector3(STUD_D + 0.9, f, 3.1), 180.0)
	var tz0 := depth * 0.55
	var tz1 := tz0 + 1.9
	_table("table", w * 0.5 - 0.35, w * 0.5 + 0.35, tz0, tz1, 0.82, &"floor")
	_lamp_on("SurgeryLamp", Vector3(w * 0.5 + 0.22, f + 0.84, tz1 - 0.2))
	_table("cot", STUD_D + 0.05, STUD_D + 0.85, tz0 - 0.2, tz0 + 1.75, 0.45, &"weathered_pine")
	var cx0 := w - STUD_D - 0.42
	_shelves("cabinet", cx0, w - STUD_D - 0.02, tz0 - 0.1, tz0 + 1.1, 4, 1.8)
	add_member("cabinet/back", &"furniture_frame", &"dark_trim", Vector3(0.02, 1.8, 1.2), Vector3(w - STUD_D - 0.03, f + 0.9, tz0 + 0.5))
	for i in 5:
		_prop(&"whiskey_bottle", Vector3(cx0 + 0.2, f + 0.3 + 0.0125 + (1.4 / 3.0), tz0 + 0.1 + i * 0.2))


## The bank: the teller's counter across the room with its cage of bars to the ceiling's height
## and a window in it, a gap by the right wall; behind, the safe against the back wall (iron
## plate: a ball flattens on it) and the manager's desk.
func _furnish_bank() -> void:
	var w := width
	var f := floor_top
	var cz0 := 3.4
	var cz1 := 4.0
	var cx1 := w - 1.2
	_counter("counter", STUD_D, cx1, cz0, cz1, &"floor")
	_lamp_on("CounterLamp", Vector3(cx1 - 0.6, f + 0.99, cz0 + 0.35))
	# The cage: bars up from the counter's top, a rail across them, a gap in them the teller's window.
	var top := f + 0.99
	var cage_h := 1.25
	var rail_y := top + cage_h
	var window := Vector2(w * 0.5 - 0.45, w * 0.5 + 0.15)
	var n := int((cx1 - STUD_D) / 0.14)
	for i in n:
		var x := STUD_D + 0.07 + i * 0.14
		if x > window.x and x < window.y:
			continue
		add_member("cage/bar%d" % i, &"trim", &"iron", Vector3(0.016, cage_h, 0.016), Vector3(x, top + cage_h * 0.5, cz0 + 0.1))
	add_member("cage/rail", &"trim", &"dark_trim", Vector3(cx1 - STUD_D, 0.05, 0.06), Vector3((STUD_D + cx1) * 0.5, rail_y + 0.025, cz0 + 0.1))
	# The safe: iron plate round an empty box, on the floor by the back wall.
	var sx := w * 0.5
	var sz := depth - STUD_D - 0.5
	var size := Vector3(0.85, 1.25, 0.75)
	const PLATE := 0.012
	var base := f
	add_member("safe/bottom", &"floor_board", &"iron", Vector3(size.x, PLATE, size.z), Vector3(sx, base + PLATE * 0.5, sz))
	add_member("safe/top", &"furniture_top", &"iron", Vector3(size.x, PLATE, size.z), Vector3(sx, base + size.y - PLATE * 0.5, sz))
	for side in 2:
		var x := sx + (size.x - PLATE) * 0.5 * (1.0 if side == 0 else -1.0)
		add_member("safe/side%d" % side, &"furniture_frame", &"iron", Vector3(PLATE, size.y - PLATE * 2.0, size.z), Vector3(x, base + size.y * 0.5, sz))
	add_member("safe/back", &"furniture_frame", &"iron", Vector3(size.x - PLATE * 2.0, size.y - PLATE * 2.0, PLATE), Vector3(sx, base + size.y * 0.5, sz + (size.z - PLATE) * 0.5))
	add_member("safe/door", &"furniture_frame", &"iron", Vector3(size.x - PLATE * 2.0, size.y - PLATE * 2.0, PLATE * 2.0), Vector3(sx, base + size.y * 0.5, sz - (size.z - PLATE * 2.0) * 0.5))
	add_member("safe/dial", &"trim", &"iron", Vector3(0.09, 0.09, 0.03), Vector3(sx + 0.15, base + size.y * 0.62, sz - size.z * 0.5 - 0.02))
	_table("desk", STUD_D + 0.3, STUD_D + 1.7, depth - 3.2, depth - 2.4, 0.76)
	_lamp_on("DeskLamp", Vector3(STUD_D + 0.6, f + 0.78, depth - 2.8))
	_prop(&"chair", Vector3(STUD_D + 1.0, f, depth - 2.0), 180.0)


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
