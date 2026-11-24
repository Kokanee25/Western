extends TestCase
## The hotel on its valley lot (#1220): built from its spec in place of the block, its floor at its
## walk's top, on its pad (the lot dug level at the street edge), the gallery over the walk; saloon B
## beside it with the drift's door in its cellar wall. Its cellar and the drift aren't dug in the valley
## yet (hotel.json `cellar._dig`: a dig in this ground chunk re-cuts the collision under the saloon
## yard's card set); they're walked in the lab (tests/test_building_hotel.gd).

var holder: Node
var valley: ValleyWorld


func before_each() -> void:
	ValleyFolk.murder_auto = false
	if holder != null:
		return
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func test_the_hotel_stands_on_its_lot_on_its_pad() -> void:
	var b := valley.buildings.get("hotel") as Node3D
	check(b != null, "the hotel is built on its lot")
	if b == null:
		return
	var spec: Dictionary = b.spec
	var floor_w: float = (b.global_transform * Vector3(0, float(spec.levels.ground.top), 0)).y
	print("  floor at world %.2f; building y %.2f" % [floor_w, b.global_position.y])
	check(absf(b.global_position.y - float(spec.lot.at[1])) < 0.06, "its y the street edge's ground, as its spec says (%.2f)" % b.global_position.y)
	var g := valley.get_node(^"Ground") as Ground
	# The pad: the ground round and under the building at its y (the bake rose 0.5-0.6 m to the back wall).
	for p: Vector2 in [Vector2(6.0, 15.6), Vector2(-0.4, 6.0), Vector2(12.0, 14.0), Vector2(24.6, 12.0)]:
		var w: Vector3 = b.global_transform * Vector3(p.x, 0, p.y)
		check(absf(g.height_at(w.x, w.z) - b.global_position.y) < 0.08, "the pad level with the street edge at %s (%.2f)" % [p, g.height_at(w.x, w.z)])
	# The walk under the gallery: its posts stand at the walk's street edge, its deck 16 ft over the street.
	var sid := String(b.get(&"structure_id")) + "/"
	var post: StructureMember = b.get_member(StringName(sid + "street/post/0"))
	check(post != null and absf(post.global_position.y - (b.global_position.y + post.size.y * 0.5)) < 0.05, "the gallery's posts stand on the street edge's ground")
	check(not bool((spec.cellar as Dictionary).get("dig", false)), "its cellar waits to be dug (cellar._dig)")
	var sb := valley.buildings.get("saloon") as Node3D
	check(sb != null and not (sb.spec as Dictionary).get("foundation_passages", []).is_empty(), "saloon B has the drift's door in its cellar wall")
