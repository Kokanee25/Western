class_name PlayingCards
extends RefCounted
## The card table's things (#1294): a playing card's mesh (63 x 88 mm, a board's thickness, square
## corners: the 1880s deck of tools/textures/draw_cards.py, its face on top and its back below:
## a card face down is the same card turned over) with its material (`playing_card.gdshader`), and the
## clay chip's and the silver dollar's meshes. Shared by CardGame (the table's MultiMeshes) and
## PlayerCards (your hand, first person).

const SIZE := Vector3(0.063, 0.0012, 0.088)
const DECK := "res://assets/textures/cards/deck.png"
const CHIPS := "res://assets/textures/cards/chips.png"
const BACK := 52
## A clay chip (39 mm, 3.5 mm thick) and a silver dollar (38.1 mm, 2.4 mm).
const CHIP_R := 0.0195
const CHIP_H := 0.0035
const COIN_R := 0.019
const COIN_H := 0.0024
## Clay: white, red and blue (the period's three; "blue chip" is the 1870s' word for the dearest).
const CHIP_COLOURS := [Color(0.88, 0.85, 0.78), Color(0.66, 0.14, 0.11), Color(0.17, 0.24, 0.5)]

static var _card_mesh: ArrayMesh
static var _card_mat: ShaderMaterial
static var _chip_mesh: ArrayMesh
static var _coin_mesh: ArrayMesh


## A card: top face (+Y) the face, under it the back, UV 0..1 across each (u along x, v along z: the
## card's head toward -z).
static func card_mesh() -> ArrayMesh:
	if _card_mesh:
		return _card_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := SIZE * 0.5
	var quad := func(n: Vector3, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
		for v: Array in [[a, ua], [b, ub], [c, uc], [a, ua], [c, uc], [d, ud]]:
			st.set_normal(n)
			st.set_uv(v[1])
			st.add_vertex(v[0])
	# Top (the face), wound to face up.
	quad.call(Vector3.UP, Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z),
			Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	# Under (the back).
	quad.call(Vector3.DOWN, Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z),
			Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
	# The edges.
	for side: Array in [[Vector3.RIGHT, Vector3(h.x, 0, 0), Vector3(0, 0, h.z)], [Vector3.LEFT, Vector3(-h.x, 0, 0), Vector3(0, 0, -h.z)],
			[Vector3.BACK, Vector3(0, 0, h.z), Vector3(-h.x, 0, 0)], [Vector3.FORWARD, Vector3(0, 0, -h.z), Vector3(h.x, 0, 0)]]:
		var o: Vector3 = side[1]
		var t: Vector3 = side[2]
		var y := Vector3(0, h.y, 0)
		quad.call(side[0], o - t + y, o + t + y, o + t - y, o - t - y, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	st.generate_tangents()
	_card_mesh = st.commit()
	_card_mesh.surface_set_material(0, card_material())
	return _card_mesh


static func card_material() -> ShaderMaterial:
	if _card_mat:
		return _card_mat
	_card_mat = ShaderMaterial.new()
	_card_mat.shader = load("res://src/props/playing_card.gdshader")
	_card_mat.set_shader_parameter(&"deck", load(DECK))
	return _card_mat


## A card turned face down (over on its long axis).
const FACE_DOWN := Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, 1))


## A disc of `r` and `h`: its faces UV'd into the left half of chips.png, its edge round the right.
static func _disc(r: float, h: float, segs: int, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for top in [true, false]:
		var y := h * 0.5 if top else -h * 0.5
		var n := Vector3.UP if top else Vector3.DOWN
		for i in segs:
			var a0 := TAU * i / segs
			var a1 := TAU * (i + 1) / segs
			var pts := [Vector3.ZERO, Vector3(cos(a0), 0, sin(a0)), Vector3(cos(a1), 0, sin(a1))]
			if top:
				pts = [pts[0], pts[2], pts[1]]
			for p: Vector3 in pts:
				st.set_normal(n)
				st.set_uv(Vector2(0.25 + p.x * 0.25, 0.5 + p.z * 0.5))
				st.add_vertex(p * r + Vector3(0, y, 0))
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var n0 := Vector3(cos(a0), 0, sin(a0))
		var n1 := Vector3(cos(a1), 0, sin(a1))
		var u0 := 0.5 + 0.5 * float(i) / segs
		var u1 := 0.5 + 0.5 * float(i + 1) / segs
		for v: Array in [[n0, u0, 1.0], [n1, u1, 1.0], [n1, u1, 0.0], [n0, u0, 1.0], [n1, u1, 0.0], [n0, u0, 0.0]]:
			st.set_normal(v[0])
			st.set_uv(Vector2(v[1], v[2]))
			st.add_vertex((v[0] as Vector3) * r + Vector3(0, h * (float(v[2]) - 0.5), 0))
	var m := st.commit()
	m.surface_set_material(0, mat)
	return m


## A clay chip: the clay's greys times the instance's colour.
static func chip_mesh() -> ArrayMesh:
	if _chip_mesh:
		return _chip_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(CHIPS)
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.7
	_chip_mesh = _disc(CHIP_R, CHIP_H, 14, mat)
	return _chip_mesh


## A silver dollar: worn silver.
static func coin_mesh() -> ArrayMesh:
	if _coin_mesh:
		return _coin_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.71, 0.67)
	mat.metallic = 0.85
	mat.roughness = 0.38
	_coin_mesh = _disc(COIN_R, COIN_H, 14, mat)
	return _coin_mesh
