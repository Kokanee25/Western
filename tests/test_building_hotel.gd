extends TestCase
## The Salt Creek Hotel (#1146 the design, #1220 the build: the building lab's): built from its spec
## (config/buildings/hotel.json) it is destructible through and through, stands (a balloon frame two
## storeys high under a flat roof, its floors on girders carried in the cellar by its walls and posts), is
## built right, fits a man at every door and use point and every room has its people's places; the gallery
## comes down exactly two bays to a blown post (the Balcony Ambush); a man walks from the lobby up the
## grand stair, and from behind the bar down into the beer cellar and along the drift to its far end. It
## writes every member to build/hotel_members.json for the X-ray sheet (tools/buildings/xray.py).

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")
const SPEC := "res://config/buildings/hotel.json"

var lab: Node3D


func before_each() -> void:
	Lab.spec_path = SPEC
	lab = Lab.new()
	add_child(lab)
	Lab.spec_path = ""
	await physics_frames(3)


func after_each() -> void:
	lab.queue_free()
	await physics_frames(2)


func test_the_hotel_is_built_and_destructible() -> void:
	var b: Structure = lab.building
	var r := Checks.destructible(b, b)
	for k: StringName in r.allowed:
		print("  allowed: %d x %s" % [r.allowed[k], k])
	print("  %d members; not things: %d" % [r.members, r.not_things])
	check((r.bad as Array).is_empty(), "nothing but members and fittings: %s" % [(r.bad as Array).slice(0, 8)])
	for k: StringName in r.allowed:
		check(Checks.EXCEPTIONS.has(k), "%s is a listed exception" % k)
	check(int(r.members) > 5000, "the building is members (%d)" % r.members)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var n := Checks.export_members(b, ProjectSettings.globalize_path("res://build/hotel_members.json"))
	print("  exported %d members to build/hotel_members.json" % n)


func test_the_hotel_stands() -> void:
	var r := Checks.stands(lab.building)
	print("  dead load: %s; with a crowd: %s" % [r.dead, r.crowd])
	check(int(r.dead.falling) == 0, "every member has a load path (%d don't): %s" % [r.dead.falling, r.dead.get("falling_first", [])])
	check(int(r.dead.over) == 0, "none over its limit under its own weight: %s" % [r.dead.worst])
	check(int(r.crowd.over) == 0, "nor with a crowd on its floors and the gallery: %s" % [r.crowd.worst])
	var settled: Variant = lab.building.settle()
	check(settled == null or (settled is Array and (settled as Array).is_empty()), "the game's settle drops nothing: %s" % [settled])


func test_the_hotel_is_built_right() -> void:
	var r := Checks.built_right(lab.building, lab.spec)
	print("  %d openings, %d framed" % [r.openings, r.framed])
	for f: String in (r.failures as Array).slice(0, 30):
		print("    ", f)
	check(r.ok, "nothing across an opening, every opening framed and glazed (%d failures)" % (r.failures as Array).size())


func test_people_fit_the_hotel_and_its_rooms_are_used() -> void:
	var b: Structure = lab.building
	var fit := Checks.people_fit(b, lab.spec)
	print("  %d doors, %d stairs, %d use points" % [fit.doors, fit.stairs, fit.use_points])
	for f: String in (fit.failures as Array).slice(0, 30):
		print("    ", f)
	check(fit.ok, "doors, stairs and use points clear a man (%d failures)" % (fit.failures as Array).size())
	var used := Checks.used(b, lab.spec)
	check(used.ok, "every room has its people's places: %s" % [used.failures])


func test_what_the_hotel_costs_to_draw() -> void:
	var r := Checks.draw_calls(lab)
	print("  draws: %s; members %d" % [r, lab.building.member_count()])
	check(lab.building.member_count() < 16000, "under 16,000 members (%d): the valley's bodies" % lab.building.member_count())


## The Balcony Ambush (Sean, #1215; the brief's section 6): the gallery's beams are one a bay, ending on
## its posts. A post blown out drops exactly the two bays it carried, hinging on the ledger; the bays
## either side stand on their own posts.
func test_a_blown_gallery_post_drops_exactly_two_bays() -> void:
	var b = lab.building
	var sid := String(b.structure_id) + "/"
	var spec: Dictionary = lab.spec
	var bal: Dictionary = spec.balconies[0]
	check((bal.beams as Array).size() == 8 and (bal.posts as Array).size() == 9, "nine posts, eight beams")
	var post: StructureMember = b.get_member(StringName(sid + "street/post/4"))
	check(post != null, "the middle post (5 of 9)")
	if post == null:
		return
	# By the rules first: with the post gone its two beams are over their limit (each on one post) or fall.
	var r: Dictionary = Checks.knockouts(b, [post.member_id])[0]
	print("  post 5 gone, by the rules: %d fall, %d over %s" % [r.falls, r.over, r.over_first])
	check(int(r.falls) + int(r.over) > 0, "the post carries its two bays")
	# For real: blown out, the two bays come down to the walk; the others stand.
	b.break_member(post, Vector3(0, 0, -2.0))
	for k in 12:
		b.settle()
		await physics_frames(15)
	await physics_frames(240)
	var down := {}
	var stood := {}
	for m: StructureMember in b.get_members():
		var s := String(m.member_id).trim_prefix(sid)
		if s.begins_with("floor/street_") and s.contains("/joist/"):
			var bay := int(s.get_slice("/", 1).trim_prefix("street_"))
			if m.broken:
				down[bay] = int(down.get(bay, 0)) + 1
			else:
				stood[bay] = int(stood.get(bay, 0)) + 1
	print("  joists down by bay: %s; standing: %s" % [down, stood])
	check(down.keys().size() == 2 and down.has(3) and down.has(4), "the joists of bays 3 and 4 come down, no others: %s" % [down])
	var fell := 0
	var n := 0
	for rb: RigidBody3D in get_tree().get_nodes_in_group(&"rubble"):
		var ids: Array = rb.get_meta(&"members", [])
		if ids.is_empty() or not String(ids[0]).begins_with(sid + "floor/street_"):
			continue
		n += 1
		if b.to_local(rb.global_position).y < float(b._lv.upper) - 1.5:
			fell += 1
	print("  %d pieces of the two bays; %d fell 1.5 m or more" % [n, fell])
	check(n > 10 and fell >= n * 0.6, "and they fall toward the walk (%d of %d)" % [fell, n])


## The cellar's secret B (#1215): the drift leaves the beer cellar's west wall through a door under a
## lintel and runs under the lane to saloon B's cellar, timbered as a mine's. A man comes down the
## trap's stair behind the bar into the beer cellar and walks the drift to its far end, crouched.
func test_a_man_walks_down_behind_the_bar_and_along_the_drift() -> void:
	var b = lab.building
	var spec: Dictionary = lab.spec
	var sid := String(b.structure_id) + "/"
	var d: Dictionary = spec.drift
	var sets := 0
	for m: StructureMember in b.get_members():
		if String(m.member_id).begins_with(sid + "drift/set_") and String(m.member_id).ends_with("/cap"):
			sets += 1
	check(sets >= 14, "the drift is timbered: %d sets" % sets)
	var space: PhysicsDirectSpaceState3D = b.get_world_3d().direct_space_state
	var g := float(spec.levels.ground.top)
	var c := float(spec.levels.cellar.top)
	var zc := (float(d.z[0]) + float(d.z[1])) * 0.5
	var st: Dictionary = spec.cellar.stair
	var sx := float(st.head[0]) + float(st.width) * 0.5
	var foot_z := float(st.head[1]) + float(st.risers) * float(st.going) + 0.2
	var route: Array = [Vector3(sx, g, float(st.head[1]) - 0.35), Vector3(sx, g, float(st.head[1]) + 0.1), Vector3(sx, c, foot_z),
			Vector3(sx, c, zc), Vector3(float(d.x[0]) - 0.3, c, zc), Vector3(float(d.x[1]) - 0.4, c + float(d.fall), zc)]
	var names := ["behind the bar", "the trap's head", "the stair's foot", "the beer cellar", "the drift's door", "the drift's far end"]
	var feet := func(p: Vector3) -> Vector3:
		var at: Vector3 = b.to_global(p)
		var y := Waypoints._foot_height(space, at, at.y + 0.6, at.y - 0.6, [])
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
				bad.append("%s -> %s at %d/%d (%s to %s)" % [names[i], names[i + 1], k, n, b.to_local(prev).snappedf(0.01), b.to_local(here).snappedf(0.01)])
				break
			prev = here
	check(bad.is_empty(), "walked every stretch: %s" % [bad])
	# Head room in the drift for a man crouched (the player's 1.3 m): a crouching man's box fits over the
	# planks all along it, a standing man's (1.78) doesn't.
	var fits := 0
	var stands := 0
	for k in 12:
		var x := lerpf(float(d.x[0]) + 0.5, float(d.x[1]) - 0.5, k / 11.0)
		var foot: float = Drift.floor_at(d, float(spec.levels.cellar.floor), x) + float(d.sill) + float(d.plank)
		for h: float in [1.32, 1.78]:
			var box := BoxShape3D.new()
			box.size = Vector3(0.4, h - 0.06, 0.4)
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = box
			q.transform = Transform3D(b.global_basis, b.to_global(Vector3(x, foot + 0.04 + (h - 0.06) * 0.5, zc)))
			q.collision_mask = Layers.WORLD
			var clear := space.intersect_shape(q, 1).is_empty()
			if clear and h < 1.5:
				fits += 1
			elif clear:
				stands += 1
	print("  in the drift a crouched man fits %d of 12 places, a standing man %d" % [fits, stands])
	check(fits == 12 and stands == 0, "a man walks it crouched, not upright (%d, %d)" % [fits, stands])


## The grand stair (the brief's 4.1): from the lobby up the back wall to the upper hall.
func test_a_man_climbs_the_grand_stair_to_the_upper_hall() -> void:
	var b = lab.building
	var spec: Dictionary = lab.spec
	var space: PhysicsDirectSpaceState3D = b.get_world_3d().direct_space_state
	var st: Dictionary = spec.stairs[0]
	var g := float(spec.levels.ground.top)
	var u := float(spec.levels.upper.top)
	var z := float(st.head[1]) + float(st.width) * 0.5
	var run := (float(st.risers) - 1.0) * float(st.going)
	var foot_x := float(st.head[0]) + run
	var route: Array = [Vector3(13.0, g, 5.5), Vector3(foot_x + 0.7, g, 5.5), Vector3(foot_x + 0.7, g, z), Vector3(foot_x, g, z),
			Vector3(float(st.head[0]) - 0.05, u, z), Vector3(9.6, u, z), Vector3(9.6, u, 6.7), Vector3(20.0, u, 6.7)]
	var feet := func(p: Vector3) -> Vector3:
		var at: Vector3 = b.to_global(p)
		var y := Waypoints._foot_height(space, at, at.y + 0.6, at.y - 0.6, [])
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
	check(bad.is_empty(), "up the grand stair and along the hall: %s" % [bad])
