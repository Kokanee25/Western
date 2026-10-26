extends BridgeLab
## The sight lab (docs/briefs/more-cores.md step 3; README.md beside this file): what SightWorld
## holds and how its answers compare with Jolt's.

const Play := preload("res://experiments/building_lab/play.gd")

const HELP := {
	"sight_census": "sight_census [MASK] -> every body in the tree on MASK (1, the world) by class and shape type: what SightWorld has to hold",
	"sight_cover_at": "sight_cover_at X Y Z EYE_X EYE_Y EYE_Z -> gf_coverwhy (the gunfight lab's) from X Y Z against that eye, both given in the spec saloon's own space: the step's check that the cover search picks the same spots on Sight as on Jolt",
	"sight_bench": "sight_bench [N] -> N (2000) random lines through the spec saloon (built if it isn't) asked of Jolt and of Sight: microseconds a line each way, and how many disagree",
}


func _cmd_sight_cover_at(a: Array) -> Dictionary:
	if a.size() < 6:
		return {"ok": false, "error": HELP.sight_cover_at}
	if street.get_node_or_null(^"SpecSaloon") == null:
		Play.build(street)
		await physics_frames(10)
	await get_tree().physics_frame
	var from := Play.ORIGIN + vec(a, 0)
	var eye := Play.ORIGIN + vec(a, 3)
	var lab: Node = bridge._lab_commands.get("gf_coverwhy")
	if lab == null:
		return {"ok": false, "error": "the gunfight lab's gf_coverwhy isn't loaded"}
	var r: Dictionary = await lab._cmd_gf_coverwhy([from.x, from.y, from.z, eye.x, eye.y, eye.z].map(func(f: float) -> String: return str(f)))
	r.erase("ms_plain")
	r.erase("ms_town")
	r.from = arr(from)
	r.eye = arr(eye)
	return r


func _cmd_sight_bench(a: Array) -> Dictionary:
	var n := int(a[0]) if a.size() > 0 else 2000
	if street.get_node_or_null(^"SpecSaloon") == null:
		Play.build(street)
		await physics_frames(10)
	await get_tree().physics_frame
	var space := World.space(player)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var froms := PackedVector3Array()
	var tos := PackedVector3Array()
	for i in n:
		froms.append(Play.ORIGIN + Vector3(rng.randf_range(1, 14), rng.randf_range(0.5, 6), rng.randf_range(1, 16)))
		tos.append(Play.ORIGIN + Vector3(rng.randf_range(1, 14), rng.randf_range(0.5, 6), rng.randf_range(1, 16)))
	var ex: Array[RID] = []
	Sight.clear(player, froms[0], tos[0], ex)
	var t0 := Time.get_ticks_usec()
	var jolt_clear := []
	for i in n:
		var q := PhysicsRayQueryParameters3D.create(froms[i], tos[i], Layers.WORLD)
		q.exclude = ex
		var hit := space.intersect_ray(q)
		jolt_clear.append(hit.is_empty() or (hit.position as Vector3).distance_to(tos[i]) < 0.15)
	var us_jolt := (Time.get_ticks_usec() - t0) / float(n)
	t0 = Time.get_ticks_usec()
	var off := 0
	for i in n:
		if Sight.clear(player, froms[i], tos[i], ex) != jolt_clear[i]:
			off += 1
	var us_clear := (Time.get_ticks_usec() - t0) / float(n)
	t0 = Time.get_ticks_usec()
	for i in n:
		Sight.cast(player, froms[i], tos[i], Layers.WORLD, ex)
	var us_cast := (Time.get_ticks_usec() - t0) / float(n)
	t0 = Time.get_ticks_usec()
	Sight.lines(player, froms, tos, Layers.WORLD, ex)
	var us_lines := (Time.get_ticks_usec() - t0) / float(n)
	return {"lines": n, "us_jolt": us_jolt, "us_sight_clear": us_clear, "us_sight_cast": us_cast, "us_sight_lines": us_lines,
		"clear_disagree": off, "stats": Sight.stats(player)}


func _cmd_sight_census(a: Array) -> Dictionary:
	var mask := int(a[0]) if a.size() > 0 else Layers.WORLD
	var by := {}
	var examples := {}
	for n in _all(get_tree().root):
		var co := n as CollisionObject3D
		if co == null or co is Area3D or (co.collision_layer & mask) == 0:
			continue
		var rid := co.get_rid()
		var cls := co.get_class()
		if co.get_script():
			cls += ":" + String((co.get_script() as Script).resource_path.get_file())
		var n_shapes := PhysicsServer3D.body_get_shape_count(rid)
		var types := []
		for i in n_shapes:
			types.append(PhysicsServer3D.shape_get_type(PhysicsServer3D.body_get_shape(rid, i)))
		types.sort()
		var key := "%s %s mode=%d" % [cls, str(types), PhysicsServer3D.body_get_mode(rid)]
		by[key] = int(by.get(key, 0)) + 1
		if not examples.has(key):
			examples[key] = String(co.get_path())
	return {"kinds": by, "examples": examples}


func _all(n: Node) -> Array:
	var out := [n]
	for c in n.get_children(true):
		out.append_array(_all(c))
	return out
