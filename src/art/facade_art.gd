class_name FacadeArt
## The parts the street painting draws on a front and a plain false front lacks
## (docs/concept/street-golden-hour.png, its SALOON): heavy square corner posts, a deep cornice on
## brackets, the sign as its own framed board with a stepped crest, lettered square by square
## (tools/textures/letter_sign.py), a heavy surround to the door, windows in thick frames with
## panes, and the porch on thick posts with knee braces up to a deep beam. Everything is a member
## (shot, burnt, broken like the rest), in the painting's own woods (tools/textures/from_painting.py:
## `timber`, the pale weathered grey-tan of its posts and frames; `sign_board`; `saloon_red`).
##
## A FalseFrontBuilding calls dress() at the end of build(); it does nothing unless the building has
## a `facade` meta naming a style (StreetDressing sets it before the building is added).
## Members are laid over the plain ones where they replace them (a casing round a porch post, a
## surround over the door's trim), so the building's frame and its load paths stay as they were.

## The painting's woods.
const TIMBER := &"timber"
const SIGN := &"sign_board"
## Its lettered boards: sign text -> texture (assets/textures/<id>.png, one texel a square).
const DRAWN_SIGNS := {"SALOON": &"sign_saloon_drawn"}

const POST := 0.26  # porch posts and the corner posts, square
const BRACE := 0.09
const BRACE_REACH := 0.62  # along the beam and down the post
const FRAME := 0.2  # the sign's frame, across
const CREST_STEP := 0.17  # the crest's steps, up
const CREST_WIDTHS := [3.2, 2.3, 1.4]


static func dress(b: FalseFrontBuilding) -> void:
	var style: String = b.get_meta(&"facade", "")
	if style.is_empty():
		return
	var bt := FalseFrontBuilding.BOARD_T
	if not b.gable_front:
		_corners(b, bt)
		_cornice(b, bt)
		_sign(b, bt)
	_door(b, bt)
	if b.front_windows:
		_windows(b, bt)
	if b.porch:
		_porch(b)


## A box on the front: x along it, y up, d out from the studs' face toward the street.
static func _front(b: FalseFrontBuilding, path: String, kind: StringName, wood: StringName,
		x0: float, x1: float, y0: float, y1: float, d0: float, d1: float) -> StructureMember:
	return b.add_member(path, kind, wood, Vector3(x1 - x0, y1 - y0, d1 - d0),
			Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, -(d0 + d1) * 0.5))


## Square timber posts up both front corners to the cornice, standing on the ground.
static func _corners(b: FalseFrontBuilding, bt: float) -> void:
	var top := b.front_height - 0.3
	_front(b, "facade/corner0", &"post", TIMBER, -0.1, POST - 0.1, 0.0, top, 0.0, POST - 0.06)
	_front(b, "facade/corner1", &"post", TIMBER, b.width - POST + 0.1, b.width + 0.1, 0.0, top, 0.0, POST - 0.06)


## A deep cornice over the old one, on brackets every 0.8 m.
static func _cornice(b: FalseFrontBuilding, bt: float) -> void:
	var h := b.front_height
	_front(b, "facade/cornice", &"trim", TIMBER, -0.28, b.width + 0.28, h - 0.46, h - 0.06, bt, bt + 0.34)
	var n := maxi(int(b.width / 0.8), 2)
	for i in n + 1:
		var x := lerpf(0.25, b.width - 0.25, float(i) / n)
		_front(b, "facade/bracket%02d" % i, &"trim", TIMBER, x - 0.06, x + 0.06, h - 0.78, h - 0.46, bt, bt + 0.24)


## The sign as its own board: lettered planks in a heavy frame with a stepped crest, filling the
## front between the porch roof and the cornice's brackets.
static func _sign(b: FalseFrontBuilding, bt: float) -> void:
	# The plain sign member and the factory's painted board on it make way.
	var old := b.get_member(StringName("%s/front/sign" % b.structure_id))
	if old:
		for c in old.get_children():
			if c is MeshInstance3D:
				(c as MeshInstance3D).visible = false
			if c.name == "SignBoard":
				c.free()
	var id: StringName = DRAWN_SIGNS.get(b.sign_text.to_upper(), &"")
	var tex := _drawn(id)
	var crest := CREST_STEP * CREST_WIDTHS.size()
	var bottom := b.sign_room_bottom() + 0.15
	var top := b.front_height - 0.86 - crest
	var room := Vector2(b.width - 0.9 - FRAME * 2.0, top - bottom - FRAME * 2.0)
	var aspect := float(tex.get_width()) / tex.get_height() if tex else 3.0
	var size := Vector2(minf(room.x, room.y * aspect), minf(room.y, room.x / aspect))
	var cx := b.width * 0.5
	var y0 := bottom + FRAME + (room.y - size.y) * 0.5
	var x0 := cx - size.x * 0.5
	var panel := _front(b, "facade/sign", &"board", SIGN, x0, x0 + size.x, y0, y0 + size.y, bt, bt + 0.04)
	if tex:
		_letter(panel, tex, size)
	# The frame, proud of the boards.
	var fx0 := x0 - FRAME
	var fx1 := x0 + size.x + FRAME
	var fy1 := y0 + size.y + FRAME
	var d1 := bt + 0.1
	_front(b, "facade/sign_frame/bottom", &"trim", TIMBER, fx0, fx1, y0 - FRAME, y0, bt, d1)
	_front(b, "facade/sign_frame/top", &"trim", TIMBER, fx0, fx1, y0 + size.y, fy1, bt, d1)
	_front(b, "facade/sign_frame/left", &"trim", TIMBER, fx0, x0, y0, y0 + size.y, bt, d1)
	_front(b, "facade/sign_frame/right", &"trim", TIMBER, x0 + size.x, fx1, y0, y0 + size.y, bt, d1)
	# The crest: steps narrowing up from the frame's top, a block on top.
	var y := fy1
	for i in CREST_WIDTHS.size():
		var half: float = minf(CREST_WIDTHS[i], size.x) * 0.5
		_front(b, "facade/crest%d" % i, &"trim", TIMBER, cx - half, cx + half, y, y + CREST_STEP, bt, d1 - 0.02 * i)
		y += CREST_STEP
	_front(b, "facade/crest_cap", &"trim", TIMBER, cx - 0.22, cx + 0.22, y, y + 0.2, bt, d1 + 0.02)


## The lettered board's picture laid once across the panel's front (its texels as big as the
## board needs: the texture's width over the board's).
static func _letter(panel: StructureMember, tex: Texture2D, size: Vector2) -> void:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	# The box's v runs up the board; the picture's rows run down. The front faces -Z, so seen from
	# the street the box's +x runs to your left: the picture is flipped across too.
	img.flip_y()
	img.flip_x()
	var m := ShaderMaterial.new()
	m.shader = PixelArt.grid_shader()
	m.set_shader_parameter(&"albedo_tex", ImageTexture.create_from_image(img))
	m.set_shader_parameter(&"tint", Color.WHITE)
	m.set_shader_parameter(&"shade_tint", PixelArt.SHADE_TINT)
	m.set_shader_parameter(&"roughness", 0.92)
	m.set_shader_parameter(&"texels_per_meter", float(img.get_width()) / size.x)
	m.set_shader_parameter(&"use_mipmaps", false)
	m.set_shader_parameter(&"fixed_squares", true)
	for c in panel.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).material_override = m


static func _drawn(id: StringName) -> Texture2D:
	if id.is_empty():
		return null
	var path := "res://assets/textures/%s.png" % id
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## A heavy surround on the door: wide jambs and a deep head over the old trim.
static func _door(b: FalseFrontBuilding, bt: float) -> void:
	var o := b.door_rect
	var jamb := 0.24
	var d1 := bt + 0.11
	_front(b, "facade/door/jamb0", &"trim", TIMBER, o.position.x - jamb, o.position.x, o.position.y, o.end.y, bt, d1)
	_front(b, "facade/door/jamb1", &"trim", TIMBER, o.end.x, o.end.x + jamb, o.position.y, o.end.y, bt, d1)
	_front(b, "facade/door/head", &"trim", TIMBER, o.position.x - jamb - 0.1, o.end.x + jamb + 0.1, o.end.y, o.end.y + 0.3, bt, d1 + 0.04)


## The two front windows in thick frames, with a cross of glazing bars: two panes across, three up.
static func _windows(b: FalseFrontBuilding, bt: float) -> void:
	var w := b.width
	for k in 2:
		var o := Rect2(0.55, 1.05, 1.1, 1.35) if k == 0 else Rect2(w - 1.65, 1.05, 1.1, 1.35)
		var p := "facade/window%d" % k
		var side := 0.15
		var d1 := bt + 0.08
		_front(b, p + "/jamb0", &"trim", TIMBER, o.position.x - side, o.position.x, o.position.y - 0.1, o.end.y, bt, d1)
		_front(b, p + "/jamb1", &"trim", TIMBER, o.end.x, o.end.x + side, o.position.y - 0.1, o.end.y, bt, d1)
		_front(b, p + "/head", &"trim", TIMBER, o.position.x - side - 0.06, o.end.x + side + 0.06, o.end.y, o.end.y + 0.18, bt, d1 + 0.03)
		_front(b, p + "/stool", &"trim", TIMBER, o.position.x - side - 0.08, o.end.x + side + 0.08, o.position.y - 0.16, o.position.y - 0.04, bt, d1 + 0.05)
		# Glazing bars just outside the glass, from the head to the sill and across between the king studs.
		var bar := 0.04
		var cx := o.get_center().x
		_front(b, p + "/bar_v", &"trim", &"dark_trim", cx - bar * 0.5, cx + bar * 0.5, o.position.y, o.end.y, -0.054, -0.02)
		for r in 2:
			var yy := o.position.y + o.size.y * (r + 1) / 3.0
			_front(b, p + "/bar_h%d" % r, &"trim", &"dark_trim", o.position.x, o.end.x, yy - bar * 0.5, yy + bar * 0.5, -0.054, -0.02)


## The porch on thick posts with knee braces: a casing round each of the old posts, posts between
## them a little over three metres apart, a deep beam over the old one, a brace either side of
## every post up to the beam.
static func _porch(b: FalseFrontBuilding) -> void:
	var w := b.width
	var zb := -b.porch_depth
	var beam_y := 3.0  # the old beam's underside (FalseFrontBuilding._build_porch)
	var xs: Array[float] = [0.12, w - 0.12]
	var between := maxi(int(round(w / 3.2)) - 1, 0)
	for i in between:
		xs.insert(xs.size() - 1, lerpf(0.12, w - 0.12, float(i + 1) / (between + 1)))
	for i in xs.size():
		var x: float = xs[i]
		b.add_member("facade/porch/post%d" % i, &"post", TIMBER, Vector3(POST, beam_y - 0.02, POST),
				Vector3(x, (beam_y - 0.02) * 0.5, zb))
		for s: float in [-1.0, 1.0]:
			if (i == 0 and s < 0.0) or (i == xs.size() - 1 and s > 0.0):
				continue
			var reach := BRACE_REACH
			var length := reach * sqrt(2.0) + BRACE
			var c := Vector3(x + s * (POST * 0.5 + reach * 0.5), beam_y - reach * 0.5, zb)
			var basis := Basis(Vector3.BACK, s * PI * 0.25)
			b.add_member("facade/porch/brace%d_%d" % [i, 0 if s < 0.0 else 1], &"trim", TIMBER,
					Vector3(length, BRACE, BRACE), c, basis)
	b.add_member("facade/porch/beam", &"beam", TIMBER, Vector3(w + 0.36, 0.28, 0.26),
			Vector3(w * 0.5, beam_y + 0.12, zb))
