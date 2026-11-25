extends TestCase
## The hideout's line shack (#1091, #1250): Kett's cabin in No Justice, built from its spec
## (config/buildings/line_shack.json, written by experiments/building_lab/line_shack/gen_spec.py), is
## destructible through and through, stands, is built right and fits a man at every door and use point.

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")
const SHACK := "res://config/buildings/line_shack.json"

var lab: Node3D


func _open(path: String) -> void:
	Lab.spec_path = path
	lab = Lab.new()
	add_child(lab)
	Lab.spec_path = ""
	await physics_frames(3)


func after_each() -> void:
	if lab:
		lab.queue_free()
		lab = null
	await physics_frames(2)


func test_the_shack_is_built_stands_and_fits() -> void:
	await _open(SHACK)
	var b: Structure = lab.building
	var r := Checks.destructible(b, b)
	print("  line_shack: %d members; not things: %d" % [r.members, r.not_things])
	check((r.bad as Array).is_empty(), "nothing but members and fittings: %s" % [(r.bad as Array).slice(0, 8)])
	var st := Checks.stands(b)
	print("  dead load: %s; with a crowd: %s" % [st.dead, st.crowd])
	check(int(st.dead.falling) == 0, "every member has a load path (%d don't): %s" % [st.dead.falling, st.dead.get("falling_first", [])])
	check(int(st.dead.over) == 0, "none over its limit under its own weight: %s" % [st.dead.worst])
	check(int(st.crowd.over) == 0, "nor with a crowd on its floor: %s" % [st.crowd.worst])
	var br := Checks.built_right(b, lab.spec)
	for f: String in (br.failures as Array).slice(0, 20):
		print("    ", f)
	check(br.ok, "built right (%d failures)" % (br.failures as Array).size())
	var fit := Checks.people_fit(b, lab.spec)
	for f: String in (fit.failures as Array).slice(0, 20):
		print("    ", f)
	check(fit.ok, "doors and use points clear a man (%d failures)" % (fit.failures as Array).size())
	var settled: Variant = b.call(&"settle")
	check(settled == null or (settled is Array and (settled as Array).is_empty()) or (settled is Dictionary and (settled as Dictionary).is_empty()),
			"the game's own settle finds nothing to fall: %s" % [settled])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	Checks.export_members(b, ProjectSettings.globalize_path("res://build/line_shack_members.json"))



func _count(b: Structure, part: String) -> int:
	var n := 0
	for m in b.get_members():
		if String(m.member_id).contains(part):
			n += 1
	return n


func test_its_parts_are_there() -> void:
	await _open(SHACK)
	var b: Structure = lab.building
	var battens := _count(b, "/batten/")
	print("  battens %d, open lean-to's rafters %d, posts %d, stovepipe %d" % [battens, _count(b, "lean_to/rafter/"), _count(b, "lean_to/post/"), _count(b, "chimney/stovepipe/")])
	check(battens > 60, "battens over the boards' joints on every wall (%d)" % battens)
	check(_count(b, "lean_to/post/") == 2 and _count(b, "lean_to/rafter/") >= 4 and _count(b, "lean_to/beam") == 1, "the open lean-to: two posts, a beam, its rafters")
	check(_count(b, "floor/lean_to/") == 0 and _count(b, "lean_to/sill/") == 0, "the open lean-to has a dirt floor: no sills, no boards")
	check(_count(b, "floor/store/") > 0 and _count(b, "store_back/siding/") > 0, "the storeroom is closed and floored")
	check(_count(b, "chimney/stovepipe/cap") == 2, "the stovepipe has its cap")
	check(b.get_member(StringName("%s/doorstep" % b.structure_id)) != null, "the doorstep is a stone member")
	check(_count(b, "front/bar_bracket_") == 2, "two iron brackets for the bar")
	var dr: Rect2 = b.get(&"door_rect")
	check(absf(dr.get_center().x - 2.1) < 0.01, "the barred door is the building's door (%s)" % dr)
	# In the storeroom, the corner where Kett hides is a man's room under the roof.
	var spec: Dictionary = lab.spec
	check(float(spec.lot.footprint[1][3]) == 6.5, "the shack is 6.5 m deep with its storeroom")


## #1091's must, the building's half: the barred door kicked in falls as flat planks, and none of them
## stands up in Joe's lane (the west side, x < 1.8: a man's walk sweeps 0.5 m up and over), wherever
## they land. Ten kicks, each a fresh shack. (Off the lane a plank may land with its end on a bunk.)
func test_the_kicked_door_falls_as_flat_planks() -> void:
	var worst := 0.0
	var worst_any := 0.0
	var pieces := 0
	for run in 10:
		await _open(SHACK)
		var b: Structure = lab.building
		(b.get(&"_rng") as RandomNumberGenerator).seed = 1000 + run
		b.call(&"shut_door", true)
		await physics_frames(2)
		var leaf := b.get_member(StringName("%s/front/door_shut" % b.structure_id))
		var bar := b.get_member(StringName("%s/front/door_bar" % b.structure_id))
		check(leaf != null and bar != null, "run %d: shut and barred" % run)
		if leaf == null or bar == null:
			return
		var inward := b.global_basis.z * 0.8
		b.break_member(bar, inward)
		b.break_member(leaf, inward)
		await physics_frames(240)
		var n := 0
		var inv := b.global_transform.affine_inverse()
		var floor_y := float(b.get(&"floor_top"))
		for rb: Node in get_tree().get_nodes_in_group(&"rubble"):
			var ids: Array = rb.get_meta(&"members", [])
			if not (ids.has(leaf.member_id) or ids.has(bar.member_id)):
				continue
			n += 1
			var top := -INF
			var west := INF
			for c: Node in rb.get_children():
				if c is CollisionShape3D:
					var box := (c as CollisionShape3D).shape as BoxShape3D
					var t := inv * (c as CollisionShape3D).global_transform
					for k in 8:
						var p := t * Vector3(box.size.x * (0.5 if k & 1 else -0.5), box.size.y * (0.5 if k & 2 else -0.5), box.size.z * (0.5 if k & 4 else -0.5))
						top = maxf(top, p.y - floor_y)
						west = minf(west, p.x)
			worst_any = maxf(worst_any, top)
			if west < 1.8:
				worst = maxf(worst, top)
		pieces = n
		after_each()
		await physics_frames(2)
	print("  pieces %d; highest in the lane %.3f m, anywhere %.3f m above the floor" % [pieces, worst, worst_any])
	check(pieces >= 5, "four planks and the bar's halves (%d)" % pieces)
	check(worst < 0.45, "every piece in the lane lies under a man's knee: nothing he must climb (%.2f m)" % worst)
	check(worst_any < 1.0, "none stands up anywhere (%.2f m)" % worst_any)

