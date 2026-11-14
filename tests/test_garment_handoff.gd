extends TestCase
## The garment handoff as a game part (#917; the lab #895, experiments/garment_handoff/): a long glove
## made from a man's own skin, worn as part of his skinned mesh, taken by his other hand's fingers,
## drawn off as real cloth over his skin (SkinCollider), let go, and lying where it lands at no cost.
## On a Studio man in the repo (the lab's MetaHuman can't be in CI, #692). ClothProp's kit field
## `mesh` (its own points and triangles) is tested here too.

## A Studio man (his skin has finger weights, so the glove has fingers).
const MODEL := &"sean_s3_talking"

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	world.add_child(_ground())


func _ground() -> StaticBody3D:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 1, 30)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	return ground


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


## Handoffs as the lab's choreography does them (shorter), one a man at each of `xs` (m along X),
## side by side at once: his left hand out, his right to its fingertips, the take, a draw along his
## fingers, let go. `measure`: the first's cloth under his skin every 4th tick.
func _handoffs(xs: Array, measure: bool) -> Array:
	var men: Array[HumanBody] = []
	for x: float in xs:
		var into := world
		if men.size() > 0:
			# Each after the first in a world of its own (its own physics space), so it starts exactly
			# as the first does: the cloth is chaotic, and a micron apart is a hand apart on the floor.
			var vp := SubViewport.new()
			vp.own_world_3d = true
			vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
			world.add_child(vp)
			into = Node3D.new()
			vp.add_child(into)
			into.add_child(_ground())
		var man := HumanBody.new()
		man.body_model = MODEL
		man.person_id = &"glove_man"  # (the same: his idle's and breath's noise is seeded by it)
		man.rng_seed = 917
		man.has_gun = false
		into.add_child(man)
		man.global_position = Vector3(x, 0, 0)
		man.face(Vector3(x, 1.4, -3.0))
		men.append(man)
	await physics_frames(20)
	var outs: Array = []
	var parts: Array[GarmentHandoff] = []
	var l_at: Array[Vector3] = []
	for man in men:
		var part := GarmentHandoff.glove_on(man, man.get_parent(), "l")
		if part == null:
			return [{"part": null}]
		parts.append(part)
		outs.append({"part": part, "worn_ticking": part.is_physics_processing()})
		var sh := (man.pivots[&"upper_arm_l"] as Node3D).global_position
		l_at.append(sh - man.global_basis.z * 0.40 + man.global_basis.x * 0.16 + Vector3.DOWN * 0.20)
	for f in 60:  # present
		for k in men.size():
			men[k].reach_to("l", l_at[k], Vector3.UP, _ease(f / 54.0))
		await physics_frames(1)
	var r_take: Array[Vector3] = []
	r_take.resize(men.size())
	for f in 60:  # reach: his right hand to the glove's fingertips
		for k in men.size():
			var man := men[k]
			var g := parts[k].garment
			var pts := g.posed()
			var c := Vector3.ZERO
			for i in g.tips:
				c += pts[i]
			c /= maxf(g.tips.size(), 1)
			var sk := man.skeleton
			var wr := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand_l")).origin
			r_take[k] = c + (c - wr).normalized() * 0.025 + Vector3.UP * 0.012
			man.reach_to("l", l_at[k], Vector3.UP, 1.0)
			man.reach_to("r", r_take[k], Vector3.UP, _ease(f / 54.0))
			man.curl_hand("r", 0.2 + 0.35 * _ease(f / 54.0))
		await physics_frames(1)
	var draw_dir: Array[Vector3] = []
	for k in men.size():
		parts[k].take("r")
		outs[k].held_ticking = parts[k].is_physics_processing()
		var sk := men[k].skeleton
		var wr := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand_l")).origin
		var tip := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("finger_middle_l_2")).origin
		draw_dir.append(((tip - wr).normalized() + men[k].global_basis.x * 0.35).normalized())
	for f in 9:  # (the lab's take: held a moment before the draw)
		for k in men.size():
			men[k].reach_to("l", l_at[k], Vector3.UP, 1.0)
			men[k].reach_to("r", r_take[k], Vector3.UP, 1.0)
		await physics_frames(1)
	var under := 0
	var deep := 0
	var stretch := 1.0
	for f in 150:  # the draw (two tugs, then one long pull), the left arm drawing back
		var u := f / 150.0
		var tug := 0.035 * sin(clampf(u, 0.0, 0.5) * TAU * 2.0) * (1.0 - _ease(u * 2.0))
		for k in men.size():
			men[k].reach_to("r", r_take[k] + draw_dir[k] * (0.62 * _ease(u) + tug), Vector3.UP, 1.0)
			men[k].reach_to("l", l_at[k] - draw_dir[k] * 0.12 * _ease(u), Vector3.UP, 1.0)
		await physics_frames(1)
		if measure and f % 4 == 0:
			var n := parts[0].under_skin()
			under = maxi(under, n)
			var d10 := 0
			for d in parts[0].garment.last_depths:
				if d > 0.01:
					d10 += 1
			deep = maxi(deep, d10)
			stretch = maxf(stretch, parts[0].stretch())
	outs[0].under = under
	outs[0].deep = deep
	outs[0].stretch = stretch
	for k in men.size():
		outs[k].pop_mm = parts[k].pop_mm
		outs[k].on_arm = parts[k].on_arm()
		parts[k].let_go(Vector3(0.4, 1.2, -0.6))
		men[k].curl_hand("r", 0.1)
	for f in 900:
		var all_rest := true
		for p in parts:
			if p.state != GarmentHandoff.State.REST:
				all_rest = false
		if all_rest:
			break
		await physics_frames(1)
	for k in men.size():
		var part := parts[k]
		outs[k].rested = part.state == GarmentHandoff.State.REST
		outs[k].final = part.points_now()
		outs[k].rest_ticking = part.is_physics_processing() or part.cloth.is_physics_processing()
		outs[k].collider_on = part.collider.active
		outs[k].soft_gone = part.cloth.soft == null
	return outs


## Made, worn (nothing a tick), taken with no pop, off his arm with few points under his skin, at
## rest at no cost; a second man from the same start (in a world of his own), the same result.
func test_the_glove_comes_off_and_lies_still() -> void:
	var both: Array = await _handoffs([0.0, 0.0], true)
	var a: Dictionary = both[0]
	var part: GarmentHandoff = a.part
	if not check(part != null, "a glove made from his skin"):
		return
	var g := part.garment
	check(g.verts.size() > 200 and g.verts.size() < 500, "a few hundred points (%d)" % g.verts.size())
	check(g.tips.size() >= 4, "the fingertips found (%d)" % g.tips.size())
	check(not a.worn_ticking, "worn, it does nothing a tick (the GPU draws it with his skin)")
	check(a.held_ticking, "taken, it runs")
	check(float(a.pop_mm) >= 0.0 and float(a.pop_mm) < 3.0, "no pop at the take: under 3 mm (%.2f mm)" % a.pop_mm)
	# (The lab's MetaHuman: at most 8 of 371 points more than 2 mm under his bare skin, 1 deeper than
	# 1 cm. A Studio man's sleeves have their folds modelled, so his skin stands above the glove's
	# own points in places: on him it's ~23, 1-2 deeper than 1 cm. Held to those here.)
	check(int(a.under) <= 30, "at most 30 points more than 2 mm under his skin (%d)" % a.under)
	check(int(a.deep) <= 3, "at most 3 deeper than 1 cm (%d)" % a.deep)
	check(float(a.stretch) < 1.12, "the cloth's edges under 1.12 of their worn length (%.3f)" % a.stretch)
	check_eq(int(a.on_arm), 0, "by the draw's end the pull has let all of it go of his arm")
	check(a.rested, "it comes to rest")
	check(not a.rest_ticking, "at rest nothing runs a tick")
	check(not a.collider_on and a.soft_gone, "at rest his skin shape is off and the soft body out")
	var lo := INF
	for p: Vector3 in a.final:
		check(p.is_finite(), "every point where it is")
		lo = minf(lo, p.y)
	check(lo > -0.01, "nothing below the floor (%.3f)" % lo)
	var b: Dictionary = both[1]
	var fa: PackedVector3Array = a.final
	var fb: PackedVector3Array = b.final
	var worst := INF if fa.size() != fb.size() else 0.0
	for i in mini(fa.size(), fb.size()):
		worst = maxf(worst, fa[i].distance_to(fb[i]))
	check(worst < 0.002, "the same start, the same result (worst %.4f m)" % worst)


## ClothProp with a kit `mesh` (its own points and triangles, normals made) drapes as the grid does.
func test_cloth_takes_its_own_mesh() -> void:
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	for j in 5:
		for i in 7:
			verts.append(Vector3(i * 0.05 - 0.15, 0.0, j * 0.05 - 0.1))
	for j in 4:
		for i in 6:
			var a := j * 7 + i
			idx.append_array([a, a + 1, a + 7, a + 1, a + 8, a + 7])
	var cloth := ClothProp.new()
	cloth.definition = PropKit.definition(&"bar_cloth").duplicate()
	cloth.definition["mesh"] = {"vertices": verts, "indices": idx}
	world.add_child(cloth)
	cloth.global_position = Vector3(0, 0.5, 0)
	check_eq(cloth.point_count(), verts.size(), "a point a vertex of its mesh")
	var drawn := cloth.soft.mesh.surface_get_arrays(0)
	check(drawn[Mesh.ARRAY_NORMAL] != null and (drawn[Mesh.ARRAY_NORMAL] as PackedVector3Array).size() == verts.size(),
			"its mesh has normals (a soft body without them is drawn scrambled)")
	await physics_frames(120)
	var lo := cloth.height_range()
	check(lo.x > -0.01 and lo.y < 0.1, "it fell and lies on the floor (%.3f..%.3f)" % [lo.x, lo.y])
	cloth.queue_free()
