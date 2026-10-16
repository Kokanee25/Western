extends TestCase
## The talking man (tools/faces/talking_face.py): his expressions are blend shapes on his head
## that survive being cut into pieces per bone (PeopleBodies._load, BodyMesh.split_pieces), and
## what the copy didn't change he wears from the man he was copied from.

const MAN := &"bold_cowboy_talking"


func _head(him: HumanBody) -> MeshInstance3D:
	return him.skin_meshes.get("head/head") as MeshInstance3D


func test_his_head_keeps_his_expressions() -> void:
	check(PeopleBodies.has_model(MAN), "assets/people/%s.glb is there" % MAN)
	var him := HumanBody.new()
	him.body_model = MAN
	him.person_id = &"talking_test"
	add_child(him)
	await physics_frames(2)
	var head := _head(him)
	check(head != null, "his head piece")
	var mesh := head.mesh as ArrayMesh
	var names := []
	for k in mesh.get_blend_shape_count():
		names.append(String(mesh.get_blend_shape_name(k)))
	for e in ["jaw_open", "aa", "ee", "oo", "fv", "mbp", "blink_l", "blink_r", "brows_up", "scowl", "smile", "look_left", "look_down"]:
		check(e in names, "%s among his expressions (%s)" % [e, names])
	var base: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var jaw: PackedVector3Array = mesh.surface_get_blend_shape_arrays(0)[names.find("jaw_open")][Mesh.ARRAY_VERTEX]
	check_eq(jaw.size(), base.size(), "the jaw's shape has every vertex of his head")
	var most := 0.0
	var behind := 0.0
	for i in base.size():
		var d := (jaw[i] - base[i]).length()
		most = maxf(most, d)
		if base[i].z > 0.06:  # the back of his head (he faces -Z; his nose is at -0.11, his crown's back +0.17)
			behind = maxf(behind, d)
	check(most > 0.02 and most < 0.06, "his jaw drops 2-6 cm (%.1f cm)" % (most * 100))
	check(behind < 0.0005, "the back of his head stays put (%.2f mm)" % (behind * 1000))
	head.set_blend_shape_value(names.find("jaw_open"), 1.0)
	check_near(head.get_blend_shape_value(names.find("jaw_open")), 1.0, 1e-6, "a weight can be set on his head")
	him.queue_free()


func test_the_copy_wears_the_original_mans_clothes() -> void:
	var data := PeopleBodies.build(Anatomy.shared(), {}, MAN)
	var tex: Dictionary = data.get("textures", {})
	check(tex.has("skin") and tex.has("coat") and tex.has("head"), "his skin, coat and head textures (%s)" % [tex.keys()])
	if tex.has("coat"):
		check(String((tex.coat as Texture2D).resource_path).contains("bold_cowboy_layered_coat"),
				"his coat's from the layered man (%s)" % (tex.coat as Texture2D).resource_path)
	if tex.has("head"):
		check(String((tex.head as Texture2D).resource_path).contains(String(MAN)), "his head's his own")
