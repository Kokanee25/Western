extends TestCase
## The building lab (experiments/building_lab/; docs/briefs/building-pipeline.md): the saloon built
## from its spec (saloon.json) stands, falls right, fits people and, above all (Sean, 2026-10-21),
## is destructible through and through: every thing in it is a member of a structure (it breaks,
## burns, is carved, is thrown by a blast, falls when its support goes), a kit prop, or a fitting
## that comes down with what holds it. The walk fails on anything else; the exceptions it allows,
## each with its owner, are Checks.EXCEPTIONS.

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")

var lab: Node3D


func before_each() -> void:
	lab = Lab.new()
	add_child(lab)
	await physics_frames(3)


func after_each() -> void:
	lab.queue_free()
	await physics_frames(2)


func test_everything_in_the_saloon_is_destructible() -> void:
	var b: Structure = lab.building
	var r := Checks.destructible(b, b)
	for k: StringName in r.allowed:
		print("  allowed: %d x %s: %s" % [r.allowed[k], k, Checks.EXCEPTIONS[k]])
	print("  %d members, %d kit props (%d members), %d lamps; not things: %d (%s)" % [r.members, r.kit_props, r.kit_members, r.lamps, r.not_things, Checks.NOT_THINGS])
	check((r.bad as Array).is_empty(), "nothing but members, kit props and fittings: %s" % [(r.bad as Array).slice(0, 8)])
	check((r.rigs as Array).is_empty(), "no structure that holds still whatever happens: %s" % [r.rigs])
	for k: StringName in r.allowed:
		check(Checks.EXCEPTIONS.has(k), "%s is a listed exception" % k)
	check(int(r.members) > 4000, "the building is members (%d)" % r.members)
	check(int(r.kit_props) >= 20, "the bar, the back bar, the tables and chairs are kit props (%d)" % r.kit_props)
	check(int(r.lamps) >= 30, "every lamp an OilLamp (%d)" % r.lamps)


func test_the_saloon_stands() -> void:
	var r := Checks.stands(lab.building)
	print("  dead load: %s; with a crowd on the floors: %s" % [r.dead, r.crowd])
	check(int(r.dead.falling) == 0, "every member has a load path (%d don't)" % r.dead.falling)
	check(int(r.dead.over) == 0, "none over its limit under its own weight: %s" % [r.dead.worst])
	check(int(r.crowd.over) == 0, "nor with a crowd on every floor (40 lb/ft2; 60 on the balcony and galleries): %s" % [r.crowd.worst])


func test_a_post_knocked_out_brings_down_what_it_carried() -> void:
	var b: Structure = lab.building
	var posts: Array = []
	for m in b.members_of_kind(&"post"):
		if String(m.member_id).begins_with("saloon_spec/post/"):
			posts.append(m.member_id)
	check(posts.size() == 14, "the gallery's posts (%d)" % posts.size())
	for r: Dictionary in Checks.knockouts(b, posts):
		check(int(r.falls) + int(r.over) > 0, "%s gone: what it carried comes down or gives (%d fall, %d over)" % [r.post, r.falls, r.over])


func test_people_fit_and_its_rooms_are_used() -> void:
	var b: Structure = lab.building
	var fit := Checks.people_fit(b, lab.spec)
	print("  %d doors, %d stairs, %d use points" % [fit.doors, fit.stairs, fit.use_points])
	check(fit.ok, "doors, stairs and use points clear a man: %s" % [(fit.failures as Array).slice(0, 10)])
	var used := Checks.used(b, lab.spec)
	check(used.ok, "every room has its people's places: %s" % [used.failures])
	check(int(used.seats) >= 14, "seats at the tables (%d)" % used.seats)
