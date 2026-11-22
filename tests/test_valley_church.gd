extends TestCase
## The church and its cemetery in the valley (#1142): the building lab's church built on valley.json's
## `church` place (its pad, facing the lane), its tower standing at the height the bell_tower view says,
## and the cemetery's fence and graves on the hill by it.

var holder: Node
var valley: ValleyWorld


func before_each() -> void:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func after_each() -> void:
	holder.queue_free()
	await physics_frames(3)


func test_the_church_stands_on_its_pad_facing_the_lane() -> void:
	var b: Structure = valley.buildings.get("church")
	check(b != null, "the church is built")
	if b == null:
		return
	var place := ValleyLayout.main().place("church")
	var pad: Dictionary = place.pad
	var mid := Vector2(float(place.at[0]), float(place.at[1]))
	var door: Vector3 = b.to_global(Vector3(4.265, 1.0, -3.0))
	check(absf(door.x - mid.x) < float(pad.w) * 0.5 and absf(door.z - mid.y) < float(pad.d) * 0.5, "the tower's door is on the pad (%s)" % door)
	check(door.z > b.global_position.z, "the front faces the lane, south of the back (%s)" % door)
	check(absf(b.global_position.y - float(pad.y)) < 0.3, "its ground is the pad's (%.2f of %.2f)" % [b.global_position.y, float(pad.y)])
	var tower := ValleyLayout.main().place("bell_tower") if ValleyLayout.main().place_ids().has("bell_tower") else {}
	if not tower.is_empty():
		check(Vector2(float(tower.at[0]), float(tower.at[1])).distance_to(Vector2(door.x, door.z)) < 4.0, "the bell tower view is at the real tower")


func test_the_cemetery_is_on_its_hill() -> void:
	var yard := valley.find_child("Cemetery", true, false) as Cemetery
	check(yard != null, "the cemetery is built")
	if yard == null:
		return
	var place := ValleyLayout.main().place("cemetery")
	var pad: Dictionary = place.pad
	check(absf(yard.global_position.x - float(place.at[0])) < float(pad.w) * 0.5, "its yard is on the cemetery's pad")
	check(yard.graves.size() >= 20, "graves laid (%d)" % yard.graves.size())
