extends TestCase
## A man's lighter levels (#889, MetaHumans at town scale): PeopleBodies cuts them from his own GLB
## when it loads him: one groom card in N kept (thin_cards), each mesh's triangles simplified by
## Godot's own simplifier (simplified), his vertices untouched so his weights, UVs and blend shapes
## carry over. (The MetaHuman himself is private, never in this repo: these test the cuts alone.)


## Quads standing apart, each two triangles over four vertices of its own: a groom's cards.
func _cards(n: int) -> PackedInt32Array:
	var tris := PackedInt32Array()
	for c in n:
		var v := c * 4
		tris.append_array([v, v + 1, v + 2, v, v + 2, v + 3])
	return tris


func test_one_card_in_n_is_kept_whole() -> void:
	var tris := _cards(7)
	var kept := PeopleBodies.thin_cards(tris, 28, 3)
	check_eq(kept.size(), 3 * 6, "cards 0, 3 and 6 of seven kept, both triangles of each")
	check_eq(Array(kept.slice(0, 6)), [0, 1, 2, 0, 2, 3], "the first card is the first kept")
	check_eq(int(kept[6]), 12, "the next kept is the fourth card (vertices 12-15)")
	check_eq(PeopleBodies.thin_cards(tris, 28, 1), tris, "every card kept at one in one")


func test_a_card_split_by_its_own_vertices_stays_one_card() -> void:
	# A strip of two quads sharing an edge is one card, not two.
	var tris := PackedInt32Array([0, 1, 2, 0, 2, 3, 3, 2, 4, 3, 4, 5, 6, 7, 8, 6, 8, 9])
	var kept := PeopleBodies.thin_cards(tris, 10, 2)
	check_eq(kept.size(), 12, "the strip (four triangles) kept, the lone quad after it dropped")


func test_simplified_keeps_about_the_share_asked_on_the_same_vertices() -> void:
	var s := SphereMesh.new()
	s.radial_segments = 64
	s.rings = 32
	var arr := s.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var tris: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var cut := PeopleBodies.simplified(verts, arr[Mesh.ARRAY_NORMAL], arr[Mesh.ARRAY_TEX_UV], tris, 0.25)
	var share := float(cut.size()) / tris.size()
	check(share > 0.12 and share < 0.5, "about a quarter of the triangles kept (%.2f)" % share)
	var top := 0
	for i in cut:
		top = maxi(top, i)
	check(top < verts.size(), "every index one of his own vertices")
	check_eq(PeopleBodies.simplified(verts, arr[Mesh.ARRAY_NORMAL], arr[Mesh.ARRAY_TEX_UV], tris, 1.0), tris,
			"keep 1: as he is")


func test_a_man_without_levels_is_drawn_from_his_own_glb() -> void:
	check_eq(PeopleBodies.glb_of(&"doctor_s2_talking"), &"doctor_s2_talking", "no lod in his report: his own")
	check(PeopleBodies.has_model(&"doctor_s2_talking"), "the doctor still found")
	check(not PeopleBodies.has_model(&"private/nobody"), "a private man not laid in: none (the game falls back)")


func test_a_cast_man_is_the_private_level_only_when_laid_in() -> void:
	# config/private_cast.json (#933, #1282): every man is played by the private man's lod1 once
	# it's laid in (tools/characters/fetch_private.sh) and the cast is on; without his files, or
	# with the cast off, his own Studio man. The women (and the player) always keep their own.
	var c := PeopleBodies._cast_data()
	check(c.get("people", {}).has("townsman"), "the townsman is cast")
	check(bool(c.get("everyone", false)), "everyone else is cast too")
	check(not bool(c.get("release", true)), "off in release builds until the encryption (#1176)")
	var was_on: bool = c.get("on", true)
	PeopleBodies.cast_suspended = false
	c["on"] = false
	check_eq(PeopleBodies.cast_model(&"townsman", &"storekeeper_s1_talking"), &"storekeeper_s1_talking",
			"the cast off: his own man, laid in or not")
	c["on"] = true
	var level := StringName("private/%s_%s" % [c.build, c.near])
	var laid := PeopleBodies.has_model(level)
	var want := level if laid else &"storekeeper_s1_talking"
	check_eq(PeopleBodies.cast_model(&"townsman", &"storekeeper_s1_talking"), want,
			"laid in: his level; not: his own man")
	check_eq(PeopleBodies.cast_model(&"kett_man_1", &"outlaw"), level if laid else &"outlaw",
			"a mission's man is cast by `everyone`")
	check_eq(PeopleBodies.cast_model(&"landlady", &"widow_s6_talking"), &"widow_s6_talking", "the women keep theirs")
	check_eq(PeopleBodies.cast_model(&"player", &"outlaw"), &"outlaw", "the player keeps his")
	check_eq(PeopleBodies.cast_model(&"x", level), level, "a private man stays himself")
	# The same man the same look every time; the looks differ between men.
	check_eq(PeopleBodies.cast_of(&"doctor", &"doctor_s2_talking"), PeopleBodies.cast_of(&"doctor", &"doctor_s2_talking"),
			"a man's look is stable")
	var seen := {}
	for id: String in ["barkeep", "miner", "earl", "doctor", "smith", "cody", "joe", "drifter", "rancher", "fiddler"]:
		seen[str(PeopleBodies.cast_of(StringName(id), &"outlaw"))] = true
	check(seen.size() >= 4, "ten men wear at least four looks (%d)" % seen.size())
	var man := HumanBody.new()
	man.body_model = &"storekeeper_s1_talking"
	man.hat_color = Color(0, 0, 0, 0)
	PeopleBodies.cast_dress(man, &"townsman")
	check_eq(man.hat_color.a, 0.0, "a man playing his own model isn't re-dressed")
	man.body_model = level
	PeopleBodies.cast_dress(man, &"townsman")
	check(man.hat_color.a > 0.0, "a private man gets his cast hat")
	PeopleBodies.cast_dress(man, &"loudmouth")
	check_eq(man.hat_color.a, 0.0, "the loudmouth goes bareheaded")
	man.free()
	c["on"] = was_on
	PeopleBodies.cast_suspended = true


