extends TestCase
## The sight service (docs/briefs/more-cores.md step 3): SightWorld's answers against Jolt's for the
## sight lines the gunfight lab casts in the spec saloon (eyes at each of its places on every other
## place's man at the heights Cover and Senses look at, the cover search's ground and floor lines
## round them, the sky over each), first as built, then shot up. The gate: no disagreement on the
## saloon as built; shot up, only lines through a carved member (the one place SightWorld keeps a
## box where Jolt has a hole), each listed.

const Lab := preload("res://experiments/building_lab/lab.gd")
const SpecSaloon := preload("res://experiments/gunfight_lab/spec_saloon.gd")
const Play := preload("res://experiments/building_lab/play.gd")

## Two answers agree when both miss, or both hit within this of each other (m).
const SAME_M := 0.005
## A hit this close to two faces of a box is on its edge, where which face's normal is given is
## Jolt's float tie (a line laid exactly in a face plane, down onto the board's top edge): the
## same point, counted apart and listed. So is a line laid in a face plane (`_grazing`).
const EDGE_M := 0.001

var lab: Node3D


func before_each() -> void:
	Sight.reset()
	lab = Lab.new()
	add_child(lab)
	await physics_frames(10)


func after_each() -> void:
	lab.queue_free()
	await physics_frames(2)
	Sight.reset()


## The places of the spec saloon (the gunfight lab's), in the lab's space (the building at the origin).
func _places() -> Array[Vector3]:
	var w := Waypoints.new()
	SpecSaloon.add_places(w)
	var out: Array[Vector3] = []
	var names: Array = w.points.keys()
	names.sort()
	for n: StringName in names:
		out.append((w.points[n] as Vector3) - Play.ORIGIN)
	return out


## [from, to, mask] for every line, in a fixed order.
func _lines() -> Array:
	var places := _places()
	var out: Array = []
	var heights := [Cover.LIE_CHEST, Cover.CHEST, Cover.HIDE_HEAD, Cover.CROUCH_HEAD, Cover.GUN_HEIGHT, Cover.STAND_HEAD]
	for a in places:
		var eye := a + Vector3.UP * 1.62
		# A man at every other place, at each height that matters to who sees whom.
		for b in places:
			if a == b:
				continue
			for h: float in heights:
				out.append([eye, b + Vector3.UP * h, Layers.WORLD])
		# The cover search round him: a ring of spots, the ground under each and the floor a level up
		# or down, his chest lying down from the first place's eye.
		for r: float in Cover.RADII:
			for i in Cover.DIRECTIONS:
				var ang := TAU * i / Cover.DIRECTIONS
				var p := a + Vector3(cos(ang), 0.0, sin(ang)) * r
				out.append([p + Vector3.UP * 0.6, p + Vector3.DOWN * 0.6, Layers.WORLD])
				out.append([p + Vector3.UP * Cover.LEVELS, p + Vector3.DOWN * Cover.LEVELS, Layers.STAND])
				out.append([places[0] + Vector3.UP * 1.62, p + Vector3.UP * Cover.LIE_CHEST, Layers.WORLD])
		# The sky over him (SightLight's ring).
		out.append([a + Vector3.UP * 1.2, a + Vector3.UP * 31.2, Layers.WORLD])
		for i in 8:
			var az := TAU * i / 8.0
			var el := deg_to_rad(35.0)
			out.append([a + Vector3.UP * 1.2, a + Vector3.UP * 1.2 + Vector3(cos(el) * cos(az), sin(el), cos(el) * sin(az)) * 30.0, Layers.WORLD])
	return out


## Every line both ways: the ones they disagree on, [line index, what Jolt says, what Sight says].
func _compare(lines: Array) -> Array:
	var space := World.space(lab)
	var q := PhysicsRayQueryParameters3D.new()
	var by_mask := {}
	for i in lines.size():
		var m: int = lines[i][2]
		if not by_mask.has(m):
			by_mask[m] = []
		(by_mask[m] as Array).append(i)
	var sight := {}
	for m: int in by_mask:
		var from := PackedVector3Array()
		var to := PackedVector3Array()
		for i: int in by_mask[m]:
			from.append(lines[i][0])
			to.append(lines[i][1])
		var t := Sight.lines(lab, from, to, m)
		var normals := Sight.normals()
		for k in t.size():
			sight[by_mask[m][k]] = [t[k], Sight.hit_rid(k), normals[k]]
	var out: Array = []
	for i in lines.size():
		var from: Vector3 = lines[i][0]
		var to: Vector3 = lines[i][1]
		q.from = from
		q.to = to
		q.collision_mask = lines[i][2]
		var hit := space.intersect_ray(q)
		var s: Array = sight[i]
		var s_hit: bool = s[0] < 1.0
		var s_at: Vector3 = from + (to - from) * float(s[0])
		var same: bool = hit.is_empty() == (not s_hit)
		if same and s_hit:
			same = (hit.position as Vector3).distance_to(s_at) <= SAME_M
			# A ground line's normal decides whether it's floor (Cover._ground: y over 0.7).
			if same and absf(from.x - to.x) < 0.001 and absf(from.z - to.z) < 0.001:
				same = ((hit.normal as Vector3).y >= 0.7) == ((s[2] as Vector3).y >= 0.7)
		if not same:
			out.append([i, hit, s, _edge_tie(hit, s_at) or _grazing(from, to, hit.get("rid", RID()), hit.get("shape", -1)) \
					or (s_hit and _grazing(from, to, s[1], -1))])
	return out


## The line lies in a face plane of the box it met (on Jolt's side or Sight's): whether it touches
## a face it runs along is a float's coin-flip for either (the spec saloon's front wall is at z 0
## exactly, and so are the places on it).
func _grazing(from: Vector3, to: Vector3, rid: RID, shape_idx: int) -> bool:
	if not rid.is_valid():
		return false
	var o := instance_from_id(PhysicsServer3D.body_get_object_instance_id(rid))
	if not o is CollisionObject3D:
		return false
	var co := o as CollisionObject3D
	for i in PhysicsServer3D.body_get_shape_count(co.get_rid()):
		if shape_idx >= 0 and i != shape_idx:
			continue
		var shape := PhysicsServer3D.body_get_shape(co.get_rid(), i)
		if PhysicsServer3D.shape_get_type(shape) != PhysicsServer3D.SHAPE_BOX:
			continue
		var h: Vector3 = PhysicsServer3D.shape_get_data(shape)
		var inv := (co.global_transform * PhysicsServer3D.body_get_shape_transform(co.get_rid(), i)).affine_inverse()
		var a := inv * from
		var b := inv * to
		for k in 3:
			if absf(absf(a[k]) - h[k]) < EDGE_M and absf(absf(b[k]) - h[k]) < EDGE_M and signf(a[k]) == signf(b[k]):
				return true
	return false


## Both hit the same point, and it's on an edge of the box Jolt met.
func _edge_tie(hit: Dictionary, s_at: Vector3) -> bool:
	if hit.is_empty() or (hit.position as Vector3).distance_to(s_at) > SAME_M:
		return false
	var o := instance_from_id(PhysicsServer3D.body_get_object_instance_id(hit.rid))
	if not o is CollisionObject3D:
		return false
	var co := o as CollisionObject3D
	var shape := PhysicsServer3D.body_get_shape(co.get_rid(), hit.shape)
	if PhysicsServer3D.shape_get_type(shape) != PhysicsServer3D.SHAPE_BOX:
		return false
	var h: Vector3 = PhysicsServer3D.shape_get_data(shape)
	var xf := co.global_transform * PhysicsServer3D.body_get_shape_transform(co.get_rid(), hit.shape)
	var p := xf.affine_inverse() * (hit.position as Vector3)
	var faces := 0
	for a in 3:
		if absf(absf(p[a]) - h[a]) < EDGE_M:
			faces += 1
	return faces >= 2


func _describe(lines: Array, d: Array) -> String:
	var hit: Dictionary = d[1]
	var s: Array = d[2]
	var from: Vector3 = lines[d[0]][0]
	var to: Vector3 = lines[d[0]][1]
	var jolt := "nothing" if hit.is_empty() else "%s at %.3f m (normal %s)" % [_name(hit.rid), from.distance_to(hit.position), hit.normal]
	var mine := "nothing" if float(s[0]) >= 1.0 else "%s at %.3f m (normal %s)" % [_name(s[1]), from.distance_to(to) * float(s[0]), s[2]]
	return "%s -> %s: Jolt %s, Sight %s" % [from, to, jolt, mine]


func _name(rid: RID) -> String:
	var o := instance_from_id(PhysicsServer3D.body_get_object_instance_id(rid))
	return String((o as Node).name) if o is Node else "?"


## A member that carries a carved hole (its voxels made), or the rubble it went to.
func _carved(rid: RID) -> bool:
	var o := instance_from_id(PhysicsServer3D.body_get_object_instance_id(rid))
	return o is StructureMember and (o as StructureMember).voxels != null


func test_sight_agrees_with_jolt_on_the_saloon_as_built() -> void:
	if not check(Sight.enabled, "the native plugin is here (SightWorld)"):
		return
	var lines := _lines()
	await get_tree().physics_frame
	var stats := Sight.stats(lab)
	var t0 := Time.get_ticks_usec()
	var off := _compare(lines)
	var ties := off.filter(func(d: Array) -> bool: return d[3])
	var other := off.filter(func(d: Array) -> bool: return not d[3])
	print("  %d lines, %d bodies (%d shapes, %d not taken), %d disagree, %d of them along a face (an edge tie, or laid in a face plane) (%.0f ms both ways)" % [lines.size(),
			stats.bodies, stats.prims, stats.unsupported, off.size(), ties.size(), (Time.get_ticks_usec() - t0) / 1000.0])
	for d in ties:
		print("    along a face: " + _describe(lines, d))
	for d in other.slice(0, 12):
		print("    " + _describe(lines, d))
	check(lines.size() > 10000, "the lab's lines (%d)" % lines.size())
	check_eq(int(stats.unsupported), 0, "every shape on the sight layers taken")
	check_eq(other.size(), 0, "Sight and Jolt agree on every line in the saloon as built, edge ties aside")
	check(ties.size() <= 24, "lines along a face are few: the places on the front wall's plane (%d)" % ties.size())


func test_shot_up_only_carved_holes_differ() -> void:
	if not check(Sight.enabled, "the native plugin is here (SightWorld)"):
		return
	var lines := _lines()
	# Thirty balls from the hall into its walls, the bar, the stair and the gallery fronts.
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var ballistics: Ballistics = lab.ballistics
	var t_rev: RevolverTuning = load("res://config/revolver.tres")
	for k in 30:
		var from := Vector3(rng.randf_range(4.0, 12.0), 2.3, rng.randf_range(3.0, 9.0))
		var ang := rng.randf() * TAU
		var dir := Vector3(cos(ang), rng.randf_range(-0.25, 0.4), sin(ang)).normalized()
		ballistics.fire(from, dir, t_rev.muzzle_velocity, t_rev.bullet_mass, t_rev.bullet_diameter)
		await physics_frames(2)
	await physics_frames(60)
	var carved := 0
	for m in (lab.building as Structure).get_members():
		if m.voxels != null:
			carved += 1
	await get_tree().physics_frame
	var off := _compare(lines)
	var through_holes := 0
	var ties := 0
	var other: Array = []
	for d in off:
		var hit: Dictionary = d[1]
		var s: Array = d[2]
		if (not hit.is_empty() and _carved(hit.rid)) or (float(s[0]) < 1.0 and _carved(s[1])):
			through_holes += 1
		elif d[3]:
			ties += 1
		else:
			other.append(d)
	print("  %d members carved; %d of %d lines disagree: %d at a carved member, %d along a face" % [carved, off.size(), lines.size(), through_holes, ties])
	for d in off:
		if not d[3] and d not in other:
			print("    at a carved member: " + _describe(lines, d))
	for d in other.slice(0, 20):
		print("    " + _describe(lines, d))
	check(carved > 5, "the balls carve holes (%d members)" % carved)
	check_eq(other.size(), 0, "every line Sight and Jolt disagree on meets a carved member")
