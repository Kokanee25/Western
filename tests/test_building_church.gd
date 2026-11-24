extends TestCase
## The church (#1142, the building lab): built from its spec (config/buildings/church.json, written by
## tools/buildings/church_spec.py) it is destructible through and through, stands (its tower, belfry and
## spire too), is built right (every opening framed and glazed), fits a man at every door and use point,
## its rooms are used, the pointed heads are there, and the bell is up. Writes build/church_members.json.

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")
const SPEC := "res://config/buildings/church.json"

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


func test_the_church_is_built_and_destructible() -> void:
	var b: Structure = lab.building
	var r := Checks.destructible(b, b)
	for k: StringName in r.allowed:
		print("  allowed: %d x %s" % [r.allowed[k], k])
	print("  %d members; not things: %d" % [r.members, r.not_things])
	check((r.bad as Array).is_empty(), "nothing but members and fittings: %s" % [(r.bad as Array).slice(0, 8)])
	for k: StringName in r.allowed:
		check(Checks.EXCEPTIONS.has(k), "%s is a listed exception" % k)
	check(int(r.members) > 1200, "the building is members (%d)" % r.members)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	Checks.export_members(b, ProjectSettings.globalize_path("res://build/church_members.json"))


func test_the_church_stands() -> void:
	var r := Checks.stands(lab.building)
	print("  dead load: %s; with a crowd: %s" % [r.dead, r.crowd])
	check(int(r.dead.falling) == 0, "every member has a load path (%d don't): %s" % [r.dead.falling, r.dead.get("falling_first", [])])
	check(int(r.dead.over) == 0, "none over its limit under its own weight: %s" % [r.dead.worst])
	check(int(r.crowd.over) == 0, "nor with a crowd on its floors: %s" % [r.crowd.worst])


func test_the_church_is_built_right() -> void:
	var r := Checks.built_right(lab.building, lab.spec)
	print("  %d openings, %d framed" % [r.openings, r.framed])
	for f: String in (r.failures as Array).slice(0, 30):
		print("    ", f)
	check(r.ok, "nothing across an opening, every opening framed and glazed (%d failures)" % (r.failures as Array).size())


func test_people_fit_the_church_and_its_rooms_are_used() -> void:
	var fit := Checks.people_fit(lab.building, lab.spec)
	print("  %d doors, %d stairs, %d use points" % [fit.doors, fit.stairs, fit.use_points])
	for f: String in (fit.failures as Array).slice(0, 20):
		print("    ", f)
	check(fit.ok, "doors, stairs and use points clear a man (%d failures)" % (fit.failures as Array).size())
	var used := Checks.used(lab.building, lab.spec)
	check(used.ok, "every room has its people's places: %s" % [used.failures])


func test_the_tower_the_spire_and_the_pointed_heads_are_there() -> void:
	var b: Structure = lab.building
	var posts := 0
	var shingles := 0
	var heads := 0
	var head_panes := 0
	var top := 0.0
	for m: StructureMember in b.get_members():
		var id := String(m.member_id)
		if id.contains("tower/belfry/post_"):
			posts += 1
		elif id.contains("tower/spire/shingle_"):
			shingles += 1
			top = maxf(top, m.global_position.y - b.global_position.y)
		elif id.contains("/trim_") and id.ends_with("/arch_l"):
			heads += 1
		elif id.contains("/window_") and id.contains("/head/pane_"):
			head_panes += 1
	check(posts == 4, "four belfry posts (%d)" % posts)
	check(shingles > 60, "the spire's shingle courses (%d)" % shingles)
	check(top > 12.0, "the spire stands over 12 m (%.1f)" % top)
	check(heads == 12, "a pointed head over each of the eleven nave windows and the tower's doors (%d)" % heads)
	check(head_panes >= 12 * 6, "each glazed to its point, a pane a step either side of its bar (%d)" % head_panes)


func test_the_nave_is_open_to_its_trusses() -> void:
	# #1203 (Sean on #1202: "see how it looks"): queen-post trusses at the bays, the ties on the side walls'
	# plates, the commons on the purlins; no loft over the nave and no ceiling under it; the nave's lamps
	# hang from the ties.
	var b: Structure = lab.building
	var ties := 0
	var on_plates := 0
	var principals := 0
	var queens := 0
	var purlins := 0
	var commons_on_purlins := 0
	var loft := 0
	var tie_ids := {}
	for m: StructureMember in b.get_members():
		var id := String(m.member_id)
		if id.contains("/truss/") and id.ends_with("/tie"):
			ties += 1
			tie_ids[m.member_id] = true
			var plates := 0
			for s: StringName in m.supported_by:
				if String(s).contains("/plate"):
					plates += 1
			if plates >= 2:
				on_plates += 1
		elif id.contains("/truss/") and id.contains("/principal_"):
			principals += 1
		elif id.contains("/truss/") and id.contains("/queen_"):
			queens += 1
		elif id.contains("/truss/purlin_"):
			purlins += 1
		elif id.contains("/roof/rafter_"):
			for s: StringName in m.supported_by:
				if String(s).contains("/truss/purlin_"):
					commons_on_purlins += 1
					break
		elif id.contains("floor/attic") or id.contains("/ceiling/"):
			loft += 1
	check(ties == 4, "four tie beams (%d)" % ties)
	check(on_plates == ties, "each on both side walls' plates (%d of %d)" % [on_plates, ties])
	check(principals == 8 and queens == 8, "two principals and two queen posts a truss (%d, %d)" % [principals, queens])
	check(purlins == 2 * 2 * 5, "two purlins a side over the five bays (%d)" % purlins)
	check(commons_on_purlins > 30, "the commons rest on the purlins (%d)" % commons_on_purlins)
	check(loft == 0, "no loft and no ceiling over the nave (%d members)" % loft)
	var hung := 0
	for lamp: OilLamp in b.get("lamps"):
		var prop := lamp.get_parent() as Node3D
		while prop and not prop is GlassProp:
			prop = prop.get_parent() as Node3D  # (a hung lamp's light swings on its pivot)
		if prop is GlassProp and (prop as GlassProp).definition.get("hangs", {}).has("hook"):
			hung += 1
			var q := PhysicsRayQueryParameters3D.create(prop.global_position + Vector3.UP * 0.9, prop.global_position + Vector3.UP * 1.1)
			var hit: Dictionary = b.get_world_3d().direct_space_state.intersect_ray(q)
			var over := hit.get("collider") as StructureMember
			check(over != null and tie_ids.has(over.member_id), "a nave lamp hangs under a tie (%s)" % [over.member_id if over else "nothing"])
	check(hung == 3, "three lamps hung down the nave (%d)" % hung)
