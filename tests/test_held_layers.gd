extends TestCase
## What's in your hands is off the world's render layer (#669): world decals (a dead man's blood
## pool, floor marks, splats, a blast's scorch) paint layer 1, and the gun and arms were on it too,
## so standing in a pool's box painted them red.

var street: Node3D
var player: Player


func before_each() -> void:
	street = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	player = street.get_node(^"Player")
	await physics_frames(5)


func after_each() -> void:
	street.queue_free()
	await physics_frames(2)


func _held_meshes(n: Node) -> Array[Node]:
	return n.find_children("*", "MeshInstance3D", true, false)


func test_guns_and_arms_take_no_world_decals() -> void:
	for w: WeaponViewmodel in [player.revolver(), player.shotgun()]:
		check(w != null, "the gun")
		var meshes := _held_meshes(w)
		check(meshes.size() > 0, "%s has meshes" % w.name)
		for mi: MeshInstance3D in meshes:
			check(mi.layers & Layers.VIS_HELD != 0, "%s on the held layer" % mi.name)
			check(mi.layers & Layers.WORLD == 0, "%s off the world's (decals) layer" % mi.name)


func test_hold_keeps_other_layers() -> void:
	var mi := MeshInstance3D.new()
	mi.layers = Layers.WORLD | Layers.VIS_WALLS
	Layers.hold(mi)
	check(mi.layers == Layers.VIS_HELD | Layers.VIS_WALLS, "held, its other layers kept (%d)" % mi.layers)
	mi.free()
