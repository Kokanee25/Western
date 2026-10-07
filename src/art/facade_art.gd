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
## a `facade` meta naming a style (StreetDressing sets it before the building is added): `saloon`
## (the sign its own framed board with a crest), `store` (the lettering painted on the front's
## boards, as the painting's GENERAL STORE) or `jail` (the painting's JAIL: whitewashed boards on
## the front and sides, dark battens down the wall below the porch, big dark letters on the false
## front, the windows barred in an iron grid, wanted posters by the door).
## Members are laid over the plain ones where they replace them (a casing round a porch post, a
## surround over the door's trim), so the building's frame and its load paths stay as they were.

## The painting's woods.
const TIMBER := &"timber"
const SIGN := &"sign_board"
## Its lettered boards: sign text -> texture (assets/textures/<id>.png, one texel a square).
const DRAWN_SIGNS := {
	"SALOON": &"sign_saloon_drawn", "GENERAL STORE": &"sign_general_store_drawn", "BARBER": &"sign_barber_drawn",
	"HOTEL": &"sign_hotel_drawn", "JAIL": &"sign_jail_drawn", "ASSAY OFFICE": &"sign_assay_office_drawn",
	"TELEGRAPH": &"sign_telegraph_drawn", "DOCTOR": &"sign_doctor_drawn", "BANK": &"sign_bank_drawn",
}
## The boards a plain front's lettering is painted on.
const BOARDS := &"store_boards"
## The windows' casings and bars: warm brown boards.
const SASH := &"floor"
## The jail's whitewash (tools/textures/draw_boards.py) and its window bars.
const WHITEWASH := &"jail_boards"
const IRON := &"iron"
## Panes up a window (draw_glass.py draws the same).
const PANE_ROWS := 4

const POST := 0.26  # porch posts and the corner posts, square
const BRACE := 0.09
const RAIL_Y := 1.0  # the porch railing's top rail, its middle, above the porch floor's top
const BRACE_REACH := 0.62  # along the beam and down the post
const FRAME := 0.2  # the sign's frame, across
const CREST_STEP := 0.17  # the crest's steps, up
const CREST_WIDTHS := [3.2, 2.3, 1.4]


static func dress(b: FalseFrontBuilding) -> void:
	var style: String = b.facade if not b.facade.is_empty() else b.get_meta(&"facade", "")
	if style.is_empty():
		return
	var bt := FalseFrontBuilding.BOARD_T
	if not b.gable_front:
		_corners(b, bt)
		_cornice(b, bt, style != "jail")
		_sign(b, bt, style == "saloon", style == "jail" or style == "store")
	_door(b, bt, style)
	if b.front_windows:
		_windows(b, bt, style)
	if b.porch:
		_porch(b, style == "jail")
	if style == "saloon":
		_saloon_dressing(b, bt)
	elif style == "jail":
		_jail_dressing(b, bt)


## A box on the front: x along it, y up, d out from the studs' face toward the street.
static func _front(b: FalseFrontBuilding, path: String, kind: StringName, wood: StringName,
		x0: float, x1: float, y0: float, y1: float, d0: float, d1: float) -> StructureMember:
	return b.add_member(path, kind, wood, Vector3(x1 - x0, y1 - y0, d1 - d0),
			Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, -(d0 + d1) * 0.5))


## Square timber posts up both front corners to the cornice, standing on the ground. Nothing of the
## front reaches past its ends: on the street the buildings stand wall to wall, and a part inside
## the neighbour's timbers threw its rubble about.
static func _corners(b: FalseFrontBuilding, bt: float) -> void:
	var top := b.front_height - 0.3
	_front(b, "facade/corner0", &"post", TIMBER, 0.0, POST, 0.0, top, 0.0, POST - 0.06)
	_front(b, "facade/corner1", &"post", TIMBER, b.width - POST, b.width, 0.0, top, 0.0, POST - 0.06)


## True when a flight of steps up to this building's walk (config/town.json: a walk laid out in
## its space, or its own entry's `steps`) comes up between x0 and x1 along its front.
static func _steps_between(b: FalseFrontBuilding, x0: float, x1: float) -> bool:
	var nodes := TownLayout.nodes()
	var flights: Array = []
	for path: String in nodes:
		var e: Dictionary = nodes[path]
		if path == String(b.name) or path == "StreetDressing/%s" % b.name:
			flights.append_array(e.get("steps", []))
		elif e.get("in", "") == String(b.name):
			var sets: Dictionary = e.get("set", {})
			var at: Array = e.get("at", [0, 0, 0])
			for st: Array in sets.get("steps", []):
				flights.append([float(st[0]) + float(at[0]), st[1]])
	for st: Array in flights:
		var half := float(st[1]) * 0.5 + 0.1
		if float(st[0]) + half > x0 and float(st[0]) - half < x1:
			return true
	return false


## A member of the building made over before its supports are worked out: a new size and place, in
## another wood.
static func _resize(b: FalseFrontBuilding, m: StructureMember, size: Vector3, at: Vector3, wood: StringName) -> void:
	m.size = size
	m.position = at
	m.wood = wood
	for c in m.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).mesh = b._box_mesh(size)
			(c as MeshInstance3D).material_override = WoodMaterials.get_material(wood, hash(m.member_id))
		elif c is CollisionShape3D:
			(c as CollisionShape3D).shape = b._box_shape(size)


## A deep cornice over the old one, on brackets every 0.8 m (`brackets` false: a plain cap, as the
## painting's JAIL has).
static func _cornice(b: FalseFrontBuilding, bt: float, brackets := true) -> void:
	var h := b.front_height
	if not brackets:
		_front(b, "facade/cornice", &"trim", TIMBER, 0.0, b.width, h - 0.26, h - 0.06, bt, bt + 0.2)
		return
	_front(b, "facade/cornice", &"trim", TIMBER, 0.0, b.width, h - 0.46, h - 0.06, bt, bt + 0.34)
	var n := maxi(int(b.width / 0.8), 2)
	for i in n + 1:
		var x := lerpf(0.25, b.width - 0.25, float(i) / n)
		_front(b, "facade/bracket%02d" % i, &"trim", TIMBER, x - 0.06, x + 0.06, h - 0.78, h - 0.46, bt, bt + 0.24)


## The sign as its own board: lettered planks in a heavy frame with a stepped crest, filling the
## front between the porch roof and the cornice's brackets.
static func _sign(b: FalseFrontBuilding, bt: float, framed: bool, painted := false) -> void:
	# The plain sign member and the factory's painted board on it make way.
	var old := b.get_member(StringName("%s/front/sign" % b.structure_id))
	if old:
		for c in old.get_children():
			if c is MeshInstance3D:
				(c as MeshInstance3D).visible = false
			if c.name == "SignBoard" or c.name == "SignText":  # the factory's board, or the plain label
				c.free()
	var id: StringName = DRAWN_SIGNS.get(b.sign_text.to_upper(), &"")
	var tex := _drawn(id)
	var crest := CREST_STEP * CREST_WIDTHS.size() if framed else 0.0
	var frame := FRAME if framed else 0.0
	var bottom := b.sign_room_bottom() + (0.15 if framed else 0.05)
	var top := b.front_height - (0.86 if framed else 0.8) - crest
	var room := Vector2(b.width - (0.9 if framed else 0.5) - frame * 2.0, top - bottom - frame * 2.0)
	var aspect := float(tex.get_width()) / tex.get_height() if tex else 3.0
	var size := Vector2(minf(room.x, room.y * aspect), minf(room.y, room.x / aspect))
	var cx := b.width * 0.5
	var y0 := bottom + frame + (room.y - size.y) * 0.5
	var x0 := cx - size.x * 0.5
	# Painted straight on the front's boards (the jail's): the ink alone, no board of its own.
	var ink := _drawn(StringName("%s_ink" % id)) if painted else null
	if ink:
		_paint_letters(b, old, ink, Rect2(x0, y0, size.x, size.y), bt)
		return
	var panel := _front(b, "facade/sign", &"trim", SIGN if framed else BOARDS, x0, x0 + size.x, y0, y0 + size.y, bt,
			bt + (0.04 if framed else 0.012))
	if tex:
		_letter(panel, tex, size)
	if not framed:
		return
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


## Letters painted on the front's own boards: the ink (alpha where there's none) on a quad a few
## millimetres proud of them over `r` (the building's space), its squares as big as the picture's
## texels over the rect, lit as the wall is. A child of the false front's sign member, so it goes
## when that does (burnt, broken).
static func _paint_letters(b: FalseFrontBuilding, sign: StructureMember, ink: Texture2D, r: Rect2, bt: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_texture = ink
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.roughness = 0.95
	m.metallic_specular = 0.2
	var q := QuadMesh.new()
	q.size = r.size
	var letters := MeshInstance3D.new()
	letters.name = "PaintedLetters"
	letters.mesh = q
	letters.material_override = m
	letters.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var at := Transform3D(Basis(Vector3.UP, PI), Vector3(r.get_center().x, r.get_center().y, -(bt + 0.004)))
	var parent: Node3D = sign if sign else b
	var to_parent := Transform3D.IDENTITY
	var n: Node = parent
	while n != b and n is Node3D:
		to_parent = (n as Node3D).transform * to_parent
		n = n.get_parent()
	letters.transform = to_parent.affine_inverse() * at
	parent.add_child(letters)


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


## Two wanted posters pinned beside the door and a spittoon on the boards by it (scenery: the
## posters are paper, the spittoon a prop).
static func _saloon_dressing(b: FalseFrontBuilding, bt: float) -> void:
	var o := b.door_rect
	var root := _posters(b, bt, [[Vector3(o.position.x - 1.15, 1.78, 0.0), 0.0], [Vector3(o.position.x - 0.62, 1.62, 0.0), -3.5]])
	var spittoon := PropLibrary.spawn(&"spittoon")
	spittoon.position = Vector3(o.position.x - 0.32, b.floor_top, -0.32)
	root.add_child(spittoon)


## Wanted posters pinned on the front at `places` ([where, tilt degrees]; heights over the
## building's floor), in a PorchDressing node it returns.
static func _posters(b: FalseFrontBuilding, bt: float, places: Array) -> Node3D:
	var root := Node3D.new()
	root.name = "PorchDressing"
	b.add_child(root)
	for k in places.size():
		var tex := _drawn(StringName("drawn/poster_%d" % k))
		if tex == null:
			continue
		var size := Vector2(0.42, 0.42 * tex.get_height() / tex.get_width())
		var mi := MeshInstance3D.new()
		mi.name = "Poster%d" % k
		mi.mesh = SignArt._box(Vector3(size.x, size.y, 0.004))
		mi.material_override = _paper(tex, size)
		var at: Vector3 = places[k][0]
		at.y += b.floor_top - 0.38
		at.z = -(bt + 0.004)
		mi.transform = Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.BACK, deg_to_rad(places[k][1])), at)
		root.add_child(mi)
	return root


## Iron bars across a front opening `o`: `cols` upright and `rows` flat bars, heavy enough to read
## from the street (the painting's are dark lines a hand apart), just proud of the glass.
static func _iron_grid(b: FalseFrontBuilding, p: String, o: Rect2, cols: int, rows: int) -> void:
	for c in cols:
		var x := o.position.x + o.size.x * (c + 1) / (cols + 1.0)
		_front(b, p + "/iron_v%d" % c, &"trim", IRON, x - 0.02, x + 0.02, o.position.y, o.end.y, 0.012, 0.05)
	for r in rows:
		var y := o.position.y + o.size.y * (r + 1) / (rows + 1.0)
		# Set into the uprights and the casing's jambs either side (so the frame holds them up).
		_front(b, p + "/iron_h%d" % r, &"trim", IRON, o.position.x - 0.06, o.end.x + 0.06, y - 0.018, y + 0.018, 0.012, 0.05)


static var _cell_glass: StandardMaterial3D


## A cell's window: near black, a faint sheen, no lamplight behind it.
static func cell_glass() -> StandardMaterial3D:
	if _cell_glass == null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.03, 0.028, 0.027)
		m.roughness = 0.25
		m.metallic_specular = 0.5
		_cell_glass = m
	return _cell_glass


## The barred window on a jail's side wall, the one the painting sees (its right, x = width: the
## building's own window there, FalseFrontBuilding's right opening): its glass made a dark cell
## window, a heavy timber casing round it and an iron grid over it.
static func _side_cell_window(b: FalseFrontBuilding, bt: float) -> void:
	var o := Rect2(b.depth * 0.55 - 0.5, b.floor_top + 0.82, 1.0, 1.0)  # its opening, along the wall
	var glass := b.get_member(StringName("%s/right/glass_%d_%d" % [b.structure_id, int(o.position.x * 100.0), int(o.position.y * 100.0)]))
	if glass:
		(glass.get_child(0) as MeshInstance3D).material_override = cell_glass()
	var z0 := o.position.x
	var z1 := o.end.x
	var y0 := o.position.y
	var y1 := o.end.y
	var face := b.width + bt  # the right wall's boards' outer face (its out is +X)
	var side := 0.16
	var p := "facade/cell_window"
	_side_box(b, p + "/jamb0", TIMBER, face, 0.08, z0 - side, z0, y0 - 0.1, y1)
	_side_box(b, p + "/jamb1", TIMBER, face, 0.08, z1, z1 + side, y0 - 0.1, y1)
	_side_box(b, p + "/head", TIMBER, face, 0.11, z0 - side - 0.06, z1 + side + 0.06, y1, y1 + 0.18)
	_side_box(b, p + "/stool", TIMBER, face, 0.13, z0 - side - 0.08, z1 + side + 0.08, y0 - 0.16, y0 - 0.04)
	for c in 4:
		var z := lerpf(z0, z1, (c + 1) / 5.0)
		_side_box(b, p + "/iron_v%d" % c, IRON, face - 0.01, 0.05, z - 0.02, z + 0.02, y0, y1)
	for r in 3:
		var y := lerpf(y0, y1, (r + 1) / 4.0)
		_side_box(b, p + "/iron_h%d" % r, IRON, face - 0.01, 0.05, z0 - 0.16, z1 + 0.16, y - 0.018, y + 0.018)  # under the jambs, into the boards


## A box on the right wall's outside: `out` metres proud of `face` (toward +X), z and y as given.
static func _side_box(b: FalseFrontBuilding, path: String, wood: StringName, face: float, out: float,
		za: float, zb: float, ya: float, yb: float) -> StructureMember:
	return b.add_member(path, &"trim", wood, Vector3(out, yb - ya, zb - za), Vector3(face + out * 0.5, (ya + yb) * 0.5, (za + zb) * 0.5))


## The painting's JAIL: its side walls whitewashed as its front is, dark battens down the front
## below the porch roof (board and batten, between the door and windows), and wanted posters
## either side of the door.
static func _jail_dressing(b: FalseFrontBuilding, bt: float) -> void:
	for m in b.get_members():
		var id := String(m.member_id)
		if id.contains("/left/siding/") or id.contains("/right/siding/"):
			m.wood = WHITEWASH
			for c in m.get_children():
				if c is MeshInstance3D:
					(c as MeshInstance3D).material_override = WoodMaterials.get_material(WHITEWASH, hash(m.member_id))
	var keep_clear: Array[Rect2] = [b.door_rect.grow(0.3)]
	for k in 2:
		var sy := b.floor_top + 0.67
		keep_clear.append((Rect2(0.55, sy, 1.1, 1.35) if k == 0 else Rect2(b.width - 1.65, sy, 1.1, 1.35)).grow(0.22))
	var top := b.porch_height if b.porch else b.wall_height
	var n := 0
	var x := POST + 0.2
	while x < b.width - POST - 0.2:
		var y0 := b.floor_top
		var clear := true
		for r in keep_clear:
			if x > r.position.x and x < r.end.x:
				clear = false
		if clear:
			_front(b, "facade/batten%02d" % n, &"trim", TIMBER, x - 0.03, x + 0.03, y0, top, bt, bt + 0.025)
			n += 1
		x += 0.36
	var o := b.door_rect
	_posters(b, bt, [[Vector3(o.end.x + 0.55, 1.75, 0.0), 2.5], [Vector3(o.position.x - 0.5, 1.68, 0.0), -3.0]])
	_side_cell_window(b, bt)
	# The front lit warm at golden hour from across the street, as the painting lights it.
	var fill := GoldenFill.new()
	fill.name = "GoldenFill"
	fill.spot_range = 16.0
	fill.spot_angle = 38.0
	b.add_child(fill)
	fill.transform = Transform3D(Basis.IDENTITY, Vector3(b.width * 0.5, 4.5, -9.0)).looking_at(Vector3(b.width * 0.5, 3.0, 0.0), Vector3.UP)


## Paper laid once across a board of `size` (its picture's texels as big as the board needs).
static func _paper(tex: Texture2D, size: Vector2) -> ShaderMaterial:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.flip_y()
	var m := ShaderMaterial.new()
	m.shader = PixelArt.grid_shader()
	m.set_shader_parameter(&"albedo_tex", ImageTexture.create_from_image(img))
	m.set_shader_parameter(&"tint", Color.WHITE)
	m.set_shader_parameter(&"shade_tint", PixelArt.SHADE_TINT)
	m.set_shader_parameter(&"roughness", 0.95)
	m.set_shader_parameter(&"texels_per_meter", float(img.get_width()) / size.x)
	m.set_shader_parameter(&"use_mipmaps", false)
	m.set_shader_parameter(&"fixed_squares", true)
	return m


static var _window_glass: StandardMaterial3D


## A front window's glass: dark, a little warm and glossy, faintly lit from the room behind.
static func window_glass() -> StandardMaterial3D:
	if _window_glass == null:
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.06, 0.045, 0.035, 0.95)
		m.roughness = 0.12
		m.metallic_specular = 0.7
		m.emission_enabled = true
		m.emission = Color(0.55, 0.3, 0.12)
		m.emission_energy_multiplier = 0.12
		_window_glass = m
	return _window_glass


## The painting's panes drawn on the glass (tools/textures/draw_glass.py): a quad over the opening
## just behind the bars, a child of the glass member's mesh so it goes when the glass is shot out.
static func _pane(glass_mesh: MeshInstance3D, b: FalseFrontBuilding, o: Rect2) -> void:
	var tex := _drawn(&"drawn/window_glass")
	if tex == null:
		return
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 0.45
	m.metallic_specular = 0.3
	var glow := _drawn(&"drawn/window_glass_glow")
	if glow:
		m.emission_enabled = true
		m.emission_texture = glow
		m.emission_energy_multiplier = 1.6
	var q := QuadMesh.new()
	q.size = o.size
	var pane := MeshInstance3D.new()
	pane.name = "Pane"
	pane.mesh = q
	pane.material_override = m
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Facing the street (-Z), placed in the building's space through the member and its mesh.
	var to_mesh := Transform3D.IDENTITY
	var n: Node = glass_mesh
	while n != b and n is Node3D:
		to_mesh = (n as Node3D).transform * to_mesh
		n = n.get_parent()
	pane.transform = to_mesh.affine_inverse() * Transform3D(Basis(Vector3.UP, PI), Vector3(o.get_center().x, o.get_center().y, -0.004))
	glass_mesh.add_child(pane)


static func _drawn(id: StringName) -> Texture2D:
	if id.is_empty():
		return null
	var path := "res://assets/textures/%s.png" % id
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## A heavy surround on the door: wide jambs and a deep head over the old trim.
static func _door(b: FalseFrontBuilding, bt: float, style: String) -> void:
	var o := b.door_rect
	var jamb := 0.24
	var d1 := bt + 0.11
	_front(b, "facade/door/jamb0", &"trim", TIMBER, o.position.x - jamb, o.position.x, o.position.y, o.end.y, bt, d1)
	_front(b, "facade/door/jamb1", &"trim", TIMBER, o.end.x, o.end.x + jamb, o.position.y, o.end.y, bt, d1)
	_front(b, "facade/door/head", &"trim", TIMBER, o.position.x - jamb - 0.1, o.end.x + jamb + 0.1, o.end.y, o.end.y + 0.3, bt, d1 + 0.04)
	# A saloon's front has batwings: the building's own (members) on a street front nobody goes into,
	# or drawn ones a man walks through on a saloon people come and go by (the gang couldn't get
	# past solid leaves).
	if not b.batwings and style == "saloon":
		_open_batwings(b)
	# Through the door, a lamp hung in the room, as the painting shows one past the batwings; the
	# open door leaf in dark wood so the doorway reads dark behind the batwings.
	if b.batwings or style == "saloon":
		for i in 2:
			var door := b.get_member(StringName("%s/front/door%s" % [b.structure_id, "" if i == 0 else str(i)]))
			if door:
				(door.get_child(0) as MeshInstance3D).material_override = WoodMaterials.get_material(&"dark_trim", 0)
		if b.furnished:
			return  # its own room's lamps are inside
		var lamp := OilLamp.new()
		lamp.name = "DoorwayLamp"
		lamp.hanging = true
		lamp.energy = 0.8
		lamp.light_range = 4.0
		lamp.lit_from_hour = 17
		lamp.lit_until_hour = 6
		lamp.set_meta(&"lamp_group", &"saloon")
		lamp.position = Vector3(o.get_center().x + 0.3, o.end.y + 0.1, 1.6)
		b.add_child(lamp)
		# The room past the doorway in lamplit gloom, as the painting's is (a street front's room isn't
		# built inside: its sunlit back wall showed through the door as a pale panel). Scenery, not a
		# member.
		if not b.furnished:
			var dark := MeshInstance3D.new()
			dark.name = "DoorwayDark"
			var q := QuadMesh.new()
			q.size = Vector2(o.size.x + 1.2, o.size.y + 0.8)
			dark.mesh = q
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.035, 0.024, 0.018)
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # the lamp before it mustn't light it up
			# The room drawn as the painting shows it: boards, lit beams, a lamp, a man by the bar
			# (tools/textures/draw_doorway.py).
			var room := _drawn(&"drawn/doorway_room")
			if room:
				m.albedo_color = Color.WHITE
				m.albedo_texture = room
				m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			dark.material_override = m
			dark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			dark.position = Vector3(o.get_center().x, o.position.y + q.size.y * 0.5 - 0.1, 2.4)
			dark.rotation.y = PI  # faces the street (-Z)
			b.add_child(dark)
	# The batwings louvred: slats across each leaf, dark between (the leaves are as they were).
	if b.batwings:
		var slats := WoodMaterials.get_material(&"batwing_slats", 0)
		for i in 2:
			var leaf := b.get_member(StringName("%s/front/batwing%d" % [b.structure_id, i]))
			if leaf:
				(leaf.get_child(0) as MeshInstance3D).material_override = slats


## Batwings drawn in the doorway with nothing to bump into: two slatted leaves meeting in the middle,
## chest high, where FalseFrontBuilding._build_batwings hangs its own.
static func _open_batwings(b: FalseFrontBuilding) -> void:
	var o := b.door_rect
	var half := o.size.x * 0.5 - 0.01
	var slats := WoodMaterials.get_material(&"batwing_slats", 0)
	for i in 2:
		var x0 := o.position.x + 0.005 if i == 0 else o.get_center().x + 0.005
		var leaf := MeshInstance3D.new()
		leaf.name = "Batwing%d" % i
		leaf.mesh = MemberMesh.box(Vector3(half, 1.15, 0.03))
		leaf.material_override = slats
		leaf.position = Vector3(x0 + half * 0.5, b.floor_top + 0.4 + 0.575, 0.02)
		b.add_child(leaf)


## The two front windows in thick frames of warm brown wood (the painting's are brown, not the posts'
## pale timber), with glazing bars: two panes across, four up.
static func _windows(b: FalseFrontBuilding, bt: float, style := "") -> void:
	var w := b.width
	# The jail's casings are its grey timber and its bars an iron grid (the building's own upright
	# bars, window_bars, crossed by flat ones), not glazing bars.
	var jail := style == "jail"
	var sash := TIMBER if jail else SASH
	for k in 2:
		# The building's own front windows (FalseFrontBuilding: their sills 0.67 m above its floor).
		var sy := b.floor_top + 0.67
		var o := Rect2(0.55, sy, 1.1, 1.35) if k == 0 else Rect2(w - 1.65, sy, 1.1, 1.35)
		var p := "facade/window%d" % k
		var side := 0.15
		var d1 := bt + 0.08
		_front(b, p + "/jamb0", &"trim", sash, o.position.x - side, o.position.x, o.position.y - 0.1, o.end.y, bt, d1)
		_front(b, p + "/jamb1", &"trim", sash, o.end.x, o.end.x + side, o.position.y - 0.1, o.end.y, bt, d1)
		_front(b, p + "/head", &"trim", sash, o.position.x - side - 0.06, o.end.x + side + 0.06, o.end.y, o.end.y + 0.18, bt, d1 + 0.03)
		_front(b, p + "/stool", &"trim", sash, o.position.x - side - 0.08, o.end.x + side + 0.08, o.position.y - 0.16, o.position.y - 0.04, bt, d1 + 0.05)
		# The glass dark and warm, the room's lamplight behind it (the painting's windows), not the
		# sky's grey sheen.
		var glass := b.get_member(StringName("%s/front/glass_%d_%d" % [b.structure_id, int(o.position.x * 100.0), int(o.position.y * 100.0)]))
		if glass:
			var mi := glass.get_child(0) as MeshInstance3D
			mi.material_override = cell_glass() if jail else window_glass()
			if not jail:
				_pane(mi, b, o)  # a jail's windows are dark: no lamplit room behind them
		# Glazing bars just outside the glass (and the pane drawn on it), from the head to the sill and across between the king studs.
		var bar := 0.05
		var cx := o.get_center().x
		if jail:
			_iron_grid(b, p, o, 4, 4)
			continue
		_front(b, p + "/bar_v", &"trim", sash, cx - bar * 0.5, cx + bar * 0.5, o.position.y, o.end.y, 0.01, 0.045)
		for r in PANE_ROWS - 1:
			var yy := o.position.y + o.size.y * (r + 1) / float(PANE_ROWS)
			_front(b, p + "/bar_h%d" % r, &"trim", sash, o.position.x, o.end.x, yy - bar * 0.5, yy + bar * 0.5, 0.01, 0.045)


## The porch on thick posts with knee braces: a casing round each of the old posts, posts between
## them a little over three metres apart, a deep beam over the old one, a brace either side of
## every post up to the beam.
## `plain`: the painting's JAIL porch, thin square posts with no braces and no railing.
static func _porch(b: FalseFrontBuilding, plain := false) -> void:
	var w := b.width
	var zb := -b.porch_depth
	var beam_y := b.porch_height  # the old beam's underside (FalseFrontBuilding._build_porch)
	var post := 0.16 if plain else POST
	var xs: Array[float] = [post * 0.5, w - post * 0.5]  # inside the front's ends: the next building stands flush
	var between := maxi(int(round(w / 3.2)) - 1, 0)
	for i in between:
		xs.insert(xs.size() - 1, lerpf(post * 0.5, w - post * 0.5, float(i + 1) / (between + 1)))
	for i in xs.size():
		var x: float = xs[i]
		var size := Vector3(post, beam_y - 0.02, post)
		var at := Vector3(x, (beam_y - 0.02) * 0.5, zb)
		# The building's own posts at the ends are made thick in place (one post, the one a bullet or
		# F11 finds); the ones between are the façade's.
		var own := b.get_member(StringName("%s/porch/post%d" % [b.structure_id, 0 if i == 0 else 1])) \
				if i == 0 or i == xs.size() - 1 else null
		if own:
			# Up to the beam's underside, as the post it was: the porch's beam stands on it.
			_resize(b, own, Vector3(post, beam_y, post), Vector3(x, beam_y * 0.5, zb), TIMBER)
		else:
			b.add_member("facade/porch/post%d" % i, &"post", TIMBER, size, at)
		for s: float in [-1.0, 1.0]:
			if plain:
				break
			if (i == 0 and s < 0.0) or (i == xs.size() - 1 and s > 0.0):
				continue
			var reach := BRACE_REACH
			var length := reach * sqrt(2.0) + BRACE
			var c := Vector3(x + s * (post * 0.5 + reach * 0.5), beam_y - reach * 0.5, zb)
			var basis := Basis(Vector3.BACK, s * PI * 0.25)
			b.add_member("facade/porch/brace%d_%d" % [i, 0 if s < 0.0 else 1], &"trim", TIMBER,
					Vector3(length, BRACE, BRACE), c, basis)
	b.add_member("facade/porch/beam", &"beam", TIMBER, Vector3(w, 0.28, 0.26),
			Vector3(w * 0.5, beam_y + 0.12, zb))
	# Under the roof, as the painting's porch shows it lit by the lanterns: a heavy beam along the
	# wall and joists from it out to the porch beam over every post and half way between.
	var bt := FalseFrontBuilding.BOARD_T
	b.add_member("facade/porch/wall_beam", &"beam", TIMBER, Vector3(w, 0.2, 0.14),
			Vector3(w * 0.5, beam_y + 0.1, -bt - 0.07))
	var joists: Array[float] = []
	for i in xs.size():
		joists.append(xs[i])
		if i + 1 < xs.size():
			joists.append((xs[i] + xs[i + 1]) * 0.5)
	var reach := -zb - bt - 0.14 - 0.13  # from the wall beam's face to the porch beam's back
	for i in joists.size():
		b.add_member("facade/porch/joist%02d" % i, &"trim", TIMBER, Vector3(0.11, 0.16, reach),
				Vector3(joists[i], beam_y + 0.12, -bt - 0.14 - reach * 0.5))
	# A railing between the posts at hip height, top rail and bottom rail on short balusters,
	# left open before the door (the painting's porch has one along its front).
	var door := b.door_rect
	for i in (0 if plain else xs.size() - 1):
		var x0: float = xs[i] + post * 0.5
		var x1: float = xs[i + 1] - post * 0.5
		if x1 > door.position.x - 0.3 and x0 < door.end.x + 0.3:
			continue
		if _steps_between(b, x0, x1):
			continue  # the way up from the street
		var z := zb + 0.02
		b.add_member("facade/porch/rail%d_top" % i, &"trim", TIMBER, Vector3(x1 - x0, 0.08, 0.1),
				Vector3((x0 + x1) * 0.5, b.floor_top + RAIL_Y, z))
		b.add_member("facade/porch/rail%d_low" % i, &"trim", TIMBER, Vector3(x1 - x0, 0.07, 0.07),
				Vector3((x0 + x1) * 0.5, b.floor_top + 0.2, z))
		var n := maxi(int((x1 - x0) / 0.55), 1)
		for k in n:
			var x := lerpf(x0, x1, (k + 0.5) / n)
			var y0 := b.floor_top + 0.235
			var y1 := b.floor_top + RAIL_Y - 0.04
			b.add_member("facade/porch/rail%d_bal%d" % [i, k], &"trim", TIMBER, Vector3(0.07, y1 - y0, 0.07),
					Vector3(x, (y0 + y1) * 0.5, z))
	# The porch's ends closed to the sun only: a panel at each end that casts shadow and is never
	# drawn. The painting's porches are deep warm shade lit by their lanterns; ours let the low sun
	# run in along the porch from its open ends and lit the whole wall (an art direction choice,
	# as a game sets where its light falls).
	for side in 2:
		var shade := MeshInstance3D.new()
		shade.name = "PorchShade%d" % side
		var box := BoxMesh.new()
		box.size = Vector3(0.05, beam_y + 0.4, -zb + 0.3)
		shade.mesh = box
		shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		shade.position = Vector3(-0.3 if side == 0 else w + 0.3, (beam_y + 0.4) * 0.5, zb * 0.5)
		b.add_child(shade)
	# A deep fascia along the porch roof's front edge, against the rafters' ends (the roof's
	# boards start 0.3 m out past the beam).
	var edge := zb - 0.3
	b.add_member("facade/porch/fascia", &"board", TIMBER, Vector3(w, 0.3, 0.05),
			Vector3(w * 0.5, beam_y + 0.2, edge - 0.025))
