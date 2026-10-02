class_name SignArt
## Painted sign boards (the texture factory's sign_* textures: an image model's lettering on
## weathered boards, cut to tiles; assets/textures/textures.json gives each board's size). A board
## is laid on once, not tiled, on the texel grid (lit tile by tile), at the size it was painted or
## scaled to fit.

## Which board a false front's sign text gets.
const BOARDS := {
	"SALOON": &"sign_saloon",
	"DRY GOODS": &"sign_dry_goods",
	"GENERAL STORE": &"sign_general_store",
	"JAIL": &"sign_jail",
	"LIVERY": &"sign_livery",
}
const INDEX_PATH := "res://assets/textures/textures.json"

static var _index := {}
static var _textures := {}


## The painted board's size in metres (as painted), or zero if there's no such board.
static func board_size(id: StringName) -> Vector2:
	if _index.is_empty() and FileAccess.file_exists(INDEX_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
		_index = parsed if parsed is Dictionary else {}
	var e: Dictionary = _index.get(String(id), {})
	if e.is_empty() or not ResourceLoader.exists(PixelArt.FACTORY_PATH % id):
		return Vector2.ZERO
	return Vector2(e.metres[0], e.metres[1])


## A board of `size` (metres) facing +Z with the painting laid on its front once (a box with
## UVs in metres: MemberMesh). Null if there's no such board.
static func board(id: StringName, size: Vector2, thick := 0.025) -> MeshInstance3D:
	if board_size(id) == Vector2.ZERO:
		return null
	var mi := MeshInstance3D.new()
	mi.name = "SignBoard"
	mi.mesh = _box(Vector3(size.x, size.y, thick))
	mi.material_override = _material(id, size)
	return mi


## A box with the picture laid across x and up y on every face, in metres (MemberMesh runs u
## along the longest side, which turns a tall board's picture on its side).
static func _box(size: Vector3) -> ArrayMesh:
	var src := BoxMesh.new()
	src.size = size
	var arrays := src.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs := PackedVector2Array()
	var face := PackedVector2Array()
	for v in verts:
		uvs.append(Vector2(v.x + size.x * 0.5, v.y + size.y * 0.5))
		face.append(Vector2(size.x, size.y))
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = face
	arrays[Mesh.ARRAY_TANGENT] = null
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## The board's material: its picture once across `size` metres, one texel a tile (not tracked by
## PixelArt: F7's texel size mustn't stretch it).
static func _material(id: StringName, size: Vector2) -> ShaderMaterial:
	var key := "%s:%s" % [id, size]
	if _textures.has(key):
		return _textures[key]
	var img := (load(PixelArt.FACTORY_PATH % id) as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	# The box's v runs up the board; the picture's rows run down.
	img.flip_y()
	img.generate_mipmaps()
	var m := ShaderMaterial.new()
	m.shader = PixelArt.GRID_SHADER
	m.set_shader_parameter(&"albedo_tex", ImageTexture.create_from_image(img))
	m.set_shader_parameter(&"tint", Color.WHITE)
	m.set_shader_parameter(&"roughness", 0.9)
	m.set_shader_parameter(&"texels_per_meter", float(img.get_width()) / size.x)
	m.set_shader_parameter(&"use_mipmaps", true)
	_textures[key] = m
	return m


## Hang the painted board for `text` on a false front's sign member (FalseFrontBuilding calls it):
## as big as fits the front above the porch roof, kept to the board's shape, a hand's width
## proud of the boards. False if there's no painted board for that text (the lettered label stays).
static func hang(building: FalseFrontBuilding, sign: Node3D, text: String) -> bool:
	var id: StringName = BOARDS.get(text.to_upper(), &"")
	var painted := board_size(id)
	if painted == Vector2.ZERO:
		return false
	# The room on the false front: its width less a margin, from the porch roof to the cornice.
	var room := Vector2(building.width - 0.6, building.front_height - 0.75 - building.sign_room_bottom())
	var k := minf(room.x / painted.x, room.y / painted.y)
	var size := painted * k
	var mi := board(id, size)
	# The plain board behind stays a member (bullets, fire) but isn't drawn: the painted one shows.
	for c in sign.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).visible = false
	sign.add_child(mi)
	# The sign member is centred on the front at its own height; the board goes centred in the room.
	var centre_y := building.sign_room_bottom() + room.y * 0.5
	mi.global_transform = Transform3D(building.global_basis.rotated(building.global_basis.y.normalized(), PI),
			building.to_global(Vector3(building.width * 0.5, centre_y, -0.075)))
	return true
