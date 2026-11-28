extends TestCase
## The undertaker's on his valley lot (#1174): built from his spec in place of the block, his floor at
## his walk's top, his cellar and the bulkhead's areaway dug into the valley's ground (CellarDig), the
## spec's yard plane true to the bake, and a man walks from the yard down the bulkhead, through the
## cellar and up the stair into the workroom on the valley's own ground.

## No Law's murder as the file found it (#1326: put back once its tests are done).
var _murder_was := ValleyFolk.murder_auto


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


func _b() -> Node3D:
	return valley.buildings.get("undertaker") as Node3D


func test_he_stands_on_his_lot_with_his_cellar_dug() -> void:
	var b := _b()
	check(b != null, "the undertaker's is built on its lot")
	if b == null:
		return
	var spec: Dictionary = b.spec
	var floor_w: float = (b.global_transform * Vector3(0, float(spec.levels.ground.top), 0)).y
	print("  floor at world %.2f; building y %.2f" % [floor_w, b.global_position.y])
	var g := valley.get_node(^"Ground") as Ground
	var cel: float = (b.global_transform * Vector3(0, float(spec.levels.cellar.floor), 0)).y
	for p: Vector2 in [Vector2(2.0, 9.0), Vector2(7.5, 13.5), Vector2(-1.2, 8.6)]:
		var w: Vector3 = b.global_transform * Vector3(p.x, 0, p.y)
		check(absf(g.height_at(w.x, w.z) - cel) < 0.02, "dug to the cellar's floor at %s (%.2f, want %.2f)" % [p, g.height_at(w.x, w.z), cel])
	# Outside the cut the ground is the bake's (the yard beside the areaway, the crawl space in front).
	for p: Vector2 in [Vector2(-4.0, 8.6), Vector2(4.0, 4.0)]:
		var w: Vector3 = b.global_transform * Vector3(p.x, 0, p.y)
		check(absf(g.height_at(w.x, w.z) - ValleyTerrain.main().height(w.x, w.z)) < 0.01, "the ground undug at %s" % p)
	# The spec's yard plane (its fence, ramp, bulkhead and shed stand on it) against the bake.
	var worst := 0.0
	for p: Vector2 in [Vector2(-1.2, 8.6), Vector2(-3.0, 10.9), Vector2(-8.4, 12.0), Vector2(-8.4, 17.6), Vector2(-12.1, 2.0), Vector2(-12.1, 17.0), Vector2(1.6, 16.1)]:
		var w: Vector3 = b.global_transform * Vector3(p.x, 0, p.y)
		var gy: float = b.ground_y(p.x, p.y)
		var real: float = b.to_local(Vector3(w.x, ValleyTerrain.main().height(w.x, w.z), w.z)).y
		worst = maxf(worst, absf(gy - real))
		print("  yard %s: plane %.2f, bake %.2f" % [p, gy, real])
	check(worst < 0.15, "the yard's plane within 0.15 m of the bake (%.2f)" % worst)
	print("  Jolt bodies in the valley: %d" % PhysicsServer3D.get_process_info(PhysicsServer3D.INFO_ACTIVE_OBJECTS))


func test_a_man_walks_from_the_yard_down_into_the_cellar_and_up_into_the_workroom() -> void:
	var b := _b()
	if b == null:
		check(false, "built")
		return
	var spec: Dictionary = b.spec
	var space: PhysicsDirectSpaceState3D = b.get_world_3d().direct_space_state
	var gtop := float(spec.levels.ground.top)
	var c := float(spec.levels.cellar.top)
	var bk: Dictionary = spec.bulkhead
	var bz := (float(bk.z[0]) + float(bk.z[1])) * 0.5
	var out := float(bk.out)
	var yard: float = b.ground_y(-out - 1.0, bz)
	var route: Array = [Vector3(-out - 1.2, yard, bz), Vector3(-0.5, c, bz), Vector3(1.2, c, bz), Vector3(1.2, c, 8.4), Vector3(6.9, c, 8.4),
			Vector3(6.9, c, 9.8), Vector3(6.3, c, 9.8), Vector3(3.2, gtop, 9.8), Vector3(1.5, gtop, 9.8)]
	var feet := func(p: Vector3) -> Vector3:
		var at: Vector3 = b.to_global(p)
		var y := Waypoints._foot_height(space, at, at.y + 0.9, at.y - 0.6, [])
		return Vector3(at.x, y, at.z)
	var bad := []
	for i in route.size() - 1:
		var a: Vector3 = route[i]
		var e: Vector3 = route[i + 1]
		var n := maxi(1, ceili(Vector2(a.x, a.z).distance_to(Vector2(e.x, e.z)) / 0.2))
		var prev: Vector3 = feet.call(a)
		for k in range(1, n + 1):
			var here: Vector3 = feet.call(a.lerp(e, float(k) / n))
			if prev.y == -INF or here.y == -INF or not Waypoints._walkable(space, prev, here, []):
				bad.append("%d -> %d at %d/%d (%s to %s)" % [i, i + 1, k, n, b.to_local(prev).snappedf(0.01), b.to_local(here).snappedf(0.01)])
				break
			prev = here
	var down: Vector3 = b.to_local(feet.call(route[2]))
	check(absf(down.y - c) < 0.05, "down on the cellar's flags (%.2f)" % down.y)
	check(bad.is_empty(), "walked every stretch: %s" % [bad])


func after_all() -> void:
	ValleyFolk.murder_auto = _murder_was
