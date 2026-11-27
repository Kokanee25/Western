extends TestCase
## Main Street's dressing in the valley (#1304, art's: ValleyStreetDressing, config/valley_street.json):
## everything in its data made (nothing left out for want of a kit prop or for standing on a way), out
## in the street and not only at the kerb, every town link still walkable with it in (no wagon, horse or
## crate on a door's flight, a passage's mouth or the street's spine), the same every run, and at rest:
## the props settled and still, the horses nobody sees holding their pose.

var holder: Node
var valley: ValleyWorld


## The valley built once for the file (it's freed with the case, after its last test).
func before_each() -> void:
	if holder != null:
		return
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(3)


func after_each() -> void:
	pass


func _dress() -> ValleyStreetDressing:
	return valley.street_dress


func test_it_is_all_made_and_nothing_left_out() -> void:
	var d := _dress()
	check(d != null, "ValleyWorld made the street's dressing")
	if d == null:
		return
	var s := d.summary()
	check(s.skipped.is_empty(), "nothing in valley_street.json left out (%s)" % [s.skipped])
	var by: Dictionary = s.by
	check(int(by.get("rail", 0)) >= 5, "hitching rails before the lots (%d)" % int(by.get("rail", 0)))
	check(int(by.get("trough", 0)) >= 4, "troughs (%d)" % int(by.get("trough", 0)))
	var wagons := int(by.get("freight_wagon", 0)) + int(by.get("buckboard", 0)) + int(by.get("covered_wagon", 0))
	check(wagons >= 8, "wagons (%d)" % wagons)
	if Horse.available():
		check(int(s.horses) >= 20, "horses at the rails and in the traces (%d)" % int(s.horses))
	check(int(s.made) > 120, "a busy street (%d things)" % int(s.made))


func test_out_in_the_street_not_only_at_the_kerb() -> void:
	var d := _dress()
	if d == null:
		return
	# The walks' street edge is 7.65 m off the middle: wagons stand well inside it.
	var mid := 0
	for m: Dictionary in d.made:
		if String(m.what) in ["freight_wagon", "buckboard", "covered_wagon", "hearse"] and absf((m.at as Vector3).z) < 5.5:
			mid += 1
	check(mid >= 3, "wagons out in the street, not at the kerb (%d)" % mid)


func test_every_town_link_is_still_walkable() -> void:
	var places := valley.places()
	var space := World.space(valley)
	# (You stand at the crossroads, on main@0: you're not the dressing.)
	var you: Array[RID] = []
	var player := valley.get_node_or_null(^"Player") as CollisionObject3D
	if player:
		you.append(player.get_rid())
	var n := 0
	var bad := []
	for a: StringName in places.links:
		var pa := places.at(a)
		for b: StringName in places.links[a]:
			if String(a) > String(b):
				continue
			var pb := places.at(b)
			# Main Street and its walks: where the dressing is.
			if absf(pa.z) > 14.0 or absf(pb.z) > 14.0 or pa.x < -135.0 or pa.x > 140.0:
				continue
			n += 1
			if not Waypoints._walkable(space, pa, pb, you):
				bad.append("%s-%s" % [a, b])
	check(n > 60, "Main Street's links (%d)" % n)
	check(bad.is_empty(), "every link walkable with the dressing in (not: %s)" % [bad])


func test_the_ways_are_kept_clear_by_its_own_rule() -> void:
	var d := _dress()
	if d == null:
		return
	# A crate square on the street's spine is refused; one at the kerb between doors isn't asked to be.
	var on_spine := Transform3D(Basis.IDENTITY, Vector3(-30.0, 0.0, 0.0))
	check(not d.clear_of_ways(Rect2(-0.3, -0.3, 0.6, 0.6), on_spine), "a crate on the street's middle is on a way")


func test_the_same_every_run() -> void:
	var d := _dress()
	if d == null:
		return
	var again := ValleyStreetDressing.new()
	again.layout = d.layout
	again.town = d.town
	again.places = d.places
	again.ride = d.ride
	var keep := Node3D.new()
	add_child(keep)
	keep.add_child(again)
	check_eq(again.made.size(), d.made.size(), "as many things")
	var same := true
	for i in mini(again.made.size(), d.made.size()):
		if (again.made[i].at as Vector3).distance_to(d.made[i].at as Vector3) > 0.001:
			same = false
	check(same, "each where it was")
	keep.queue_free()
	await physics_frames(2)


func test_at_rest_the_props_are_still_and_unseen_horses_hold_their_pose() -> void:
	var d := _dress()
	if d == null:
		return
	await physics_frames(30)
	var loose := 0
	for m: Dictionary in d.made:
		var p := m.node as KitProp
		if p != null and is_instance_valid(p) and p.loose:
			loose += 1
	check_eq(loose, 0, "no prop gone loose as it settled")
	if not Horse.available() or d.horses.is_empty():
		return
	# A camera looking away up the valley, far off: every horse holds still.
	var cam := Camera3D.new()
	valley.add_child(cam)
	cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 40.0, 900.0))
	cam.current = true
	await process_frames(30)
	check_eq(int(d.summary().awake), 0, "no horse posed while none can be seen")
	# Down Main Street from its west end: the near ones go on with their idle.
	cam.look_at_from_position(Vector3(-60.0, 2.0, 0.0), Vector3(40.0, 1.5, 0.0))
	await process_frames(30)
	var awake := int(d.summary().awake)
	check(awake > 0 and awake < d.horses.size(), "the ones in sight and near posed (%d of %d)" % [awake, d.horses.size()])
	cam.queue_free()


func test_its_props_rest_and_wake_when_touched() -> void:
	var d := _dress()
	if d == null:
		return
	await physics_frames(40)
	var props: Array[KitProp] = []
	for m: Dictionary in d.made:
		if m.node is KitProp and is_instance_valid(m.node):
			props.append(m.node as KitProp)
	var resting := props.filter(func(p: KitProp) -> bool: return p.resting and not p.is_physics_processing())
	check(resting.size() > props.size() * 0.9, "at rest, their ticks stopped (%d of %d)" % [resting.size(), props.size()])
	# A crate shot through a board: awake at once, and it breaks as any.
	var crate: KitProp = null
	for p: KitProp in resting:
		if p.kit_id == &"crate":
			crate = p
			break
	if not check(crate != null, "a resting crate"):
		return
	var board := crate.get_members()[0]
	crate.break_member(board)
	check(not crate.resting and crate.is_physics_processing(), "a break wakes it")
	await physics_frames(3)
	check(board.broken, "and the board's broken")
	# A barrel knocked loose: awake, falling as rubble.
	var barrel: KitProp = null
	for p: KitProp in resting:
		if p.kit_id == &"barrel" and p.resting:
			barrel = p
			break
	if barrel:
		var bodies := barrel.go_loose(Vector3(0.0, 0.0, 2.0))
		check(barrel.is_physics_processing() and not bodies.is_empty(), "knocked loose, it ticks again and falls")
