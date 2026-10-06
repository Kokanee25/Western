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
## (the sign its own framed board with a crest) or `store` (the lettering painted on the front's
## boards, as the painting's GENERAL STORE).
## Members are laid over the plain ones where they replace them (a casing round a porch post, a
## surround over the door's trim), so the building's frame and its load paths stay as they were.

## The painting's woods.
const TIMBER := &"timber"
const SIGN := &"sign_board"
## Its lettered boards: sign text -> texture (assets/textures/<id>.png, one texel a square).
const DRAWN_SIGNS := {
	"SALOON": &"sign_saloon_drawn", "GENERAL STORE": &"sign_general_store_drawn", "BARBER": &"sign_barber_drawn",
	"HOTEL": &"sign_hotel_drawn", "JAIL": &"sign_jail_drawn", "ASSAY OFFICE": &"sign_assay_office_drawn",
}
## The boards a plain front's lettering is painted on.
const BOARDS := &"store_boards"
## The windows' casings and bars: warm brown boards.
const SASH := &"floor"
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
	var style: String = b.get_meta(&"facade", "")
	if style.is_empty():
		return
	var bt := FalseFrontBuilding.BOARD_T
	if not b.gable_front:
		_corners(b, bt)
		_cornice(b, bt)
		_sign(b, bt, style == "saloon")
	_door(b, bt)
	if b.front_windows:
		_windows(b, bt)
	if b.porch:
		_porch(b)
	if style == "saloon":
		_saloon_dressing(b, bt)


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
static func _sign(b: FalseFrontBuilding, bt: float, framed: bool) -> void:
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
	var panel := _front(b, "facade/sign", &"board", SIGN if framed else BOARDS, x0, x0 + size.x, y0, y0 + size.y, bt,
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
	var root := Node3D.new()
	root.name = "PorchDressing"
	b.add_child(root)
	var o := b.door_rect
	var places := [[Vector3(o.position.x - 1.15, 1.78, 0.0), 0.0], [Vector3(o.position.x - 0.62, 1.62, 0.0), -3.5]]
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
		at.z = -(bt + 0.004)
		mi.transform = Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.BACK, deg_to_rad(places[k][1])), at)
		root.add_child(mi)
	var spittoon := PropLibrary.spawn(&"spittoon")
	spittoon.position = Vector3(o.position.x - 0.32, b.floor_top, -0.32)
	root.add_child(spittoon)


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
static func _door(b: FalseFrontBuilding, bt: float) -> void:
	var o := b.door_rect
	var jamb := 0.24
	var d1 := bt + 0.11
	_front(b, "facade/door/jamb0", &"trim", TIMBER, o.position.x - jamb, o.position.x, o.position.y, o.end.y, bt, d1)
	_front(b, "facade/door/jamb1", &"trim", TIMBER, o.end.x, o.end.x + jamb, o.position.y, o.end.y, bt, d1)
	_front(b, "facade/door/head", &"trim", TIMBER, o.position.x - jamb - 0.1, o.end.x + jamb + 0.1, o.end.y, o.end.y + 0.3, bt, d1 + 0.04)
	# Through the door, a lamp hung in the room, as the painting shows one past the batwings; the
	# open door leaf in dark wood so the doorway reads dark behind the batwings.
	if b.batwings:
		for i in 2:
			var door := b.get_member(StringName("%s/front/door%s" % [b.structure_id, "" if i == 0 else str(i)]))
			if door:
				(door.get_child(0) as MeshInstance3D).material_override = WoodMaterials.get_material(&"dark_trim", 0)
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


## The two front windows in thick frames of warm brown wood (the painting's are brown, not the posts'
## pale timber), with glazing bars: two panes across, four up.
static func _windows(b: FalseFrontBuilding, bt: float) -> void:
	var w := b.width
	for k in 2:
		var o := Rect2(0.55, 1.05, 1.1, 1.35) if k == 0 else Rect2(w - 1.65, 1.05, 1.1, 1.35)
		var p := "facade/window%d" % k
		var side := 0.15
		var d1 := bt + 0.08
		_front(b, p + "/jamb0", &"trim", SASH, o.position.x - side, o.position.x, o.position.y - 0.1, o.end.y, bt, d1)
		_front(b, p + "/jamb1", &"trim", SASH, o.end.x, o.end.x + side, o.position.y - 0.1, o.end.y, bt, d1)
		_front(b, p + "/head", &"trim", SASH, o.position.x - side - 0.06, o.end.x + side + 0.06, o.end.y, o.end.y + 0.18, bt, d1 + 0.03)
		_front(b, p + "/stool", &"trim", SASH, o.position.x - side - 0.08, o.end.x + side + 0.08, o.position.y - 0.16, o.position.y - 0.04, bt, d1 + 0.05)
		# The glass dark and warm, the room's lamplight behind it (the painting's windows), not the
		# sky's grey sheen.
		var glass := b.get_member(StringName("%s/front/glass_%d_%d" % [b.structure_id, int(o.position.x * 100.0), int(o.position.y * 100.0)]))
		if glass:
			var mi := glass.get_child(0) as MeshInstance3D
			mi.material_override = window_glass()
			_pane(mi, b, o)
		# Glazing bars just outside the glass (and the pane drawn on it), from the head to the sill and across between the king studs.
		var bar := 0.05
		var cx := o.get_center().x
		_front(b, p + "/bar_v", &"trim", SASH, cx - bar * 0.5, cx + bar * 0.5, o.position.y, o.end.y, 0.01, 0.045)
		for r in PANE_ROWS - 1:
			var yy := o.position.y + o.size.y * (r + 1) / float(PANE_ROWS)
			_front(b, p + "/bar_h%d" % r, &"trim", SASH, o.position.x, o.end.x, yy - bar * 0.5, yy + bar * 0.5, 0.01, 0.045)


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
		b.add_member("facade/porch/joist%02d" % i, &"beam", TIMBER, Vector3(0.11, 0.16, reach),
				Vector3(joists[i], beam_y + 0.12, -bt - 0.14 - reach * 0.5))
	# A railing between the posts at hip height, top rail and bottom rail on short balusters,
	# left open before the door (the painting's porch has one along its front).
	var door := b.door_rect
	for i in xs.size() - 1:
		var x0: float = xs[i] + POST * 0.5
		var x1: float = xs[i + 1] - POST * 0.5
		if x1 > door.position.x - 0.3 and x0 < door.end.x + 0.3:
			continue
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
	b.add_member("facade/porch/fascia", &"board", TIMBER, Vector3(w + 0.4, 0.3, 0.05),
			Vector3(w * 0.5, beam_y + 0.2, edge - 0.025))
