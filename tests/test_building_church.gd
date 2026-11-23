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
	check(heads == 11, "a pointed head over each of the eleven nave windows (%d)" % heads)
	check(head_panes >= 11 * 6, "each glazed to its point, a pane a step either side of its bar (%d)" % head_panes)
