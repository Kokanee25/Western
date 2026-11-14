extends TestCase
## The nightly soak's rules and what it watches (#863): nodes held out of the tree on purpose
## (members at rest, rubble drawn by its cell) aren't a leak, only what climbs past them is; the
## members' mesh cache keeps to its limit.

const Soak := preload("res://tools/soak.gd")


func _windows(orphans: Array, held: Array) -> Array:
	var out := []
	for i in orphans.size():
		out.append({"orphans": orphans[i], "held": held[i], "unheld": int(orphans[i]) - int(held[i])})
	return out


func test_held_orphans_falling_pass() -> void:
	# The nightly of Nov 11: 19,181 at load down to 5,909, nearly all of them members at rest.
	var w := _windows([19181, 15000, 12000, 9000, 7000, 5909], [18900, 14800, 11800, 8800, 6800, 5700])
	check_eq(Soak.orphans_problem(w), "", "a falling count held on purpose isn't a fault")


func test_a_big_held_count_flat_passes() -> void:
	var w := _windows([19174, 19174, 19174, 19174, 19174, 19174], [18877, 18877, 18877, 18877, 18877, 18877])
	check_eq(Soak.orphans_problem(w), "", "19,000 held, flat: passes (the old rule failed past 1,000)")


func test_unheld_orphans_climbing_fail() -> void:
	var w := _windows([300, 300, 900, 1500, 2100, 2700], [0, 0, 0, 0, 0, 0])
	check(Soak.orphans_problem(w) != "", "nodes lost out of the tree, climbing: a fault")


func test_held_growth_isnt_a_leak() -> void:
	# More of the town standing at rest as the night goes on: orphans and held climb together.
	var w := _windows([300, 300, 900, 1500, 2100, 2700], [0, 0, 600, 1200, 1800, 2400])
	check_eq(Soak.orphans_problem(w), "", "orphans climbing with what's held: no fault")


func test_member_mesh_cache_keeps_to_its_limit() -> void:
	var before := MemberMesh.cached()
	var keep := Vector3(0.123, 0.045, 2.345)
	var kept := MemberMesh.box(keep)
	for i in MemberMesh.CACHE_LIMIT + 50:
		MemberMesh.box(Vector3(0.05 + 0.001 * (i % 97), 0.1 + 0.001 * (i / 97), 3.0))
		if i % 500 == 0:
			MemberMesh.box(keep)  # asked for now and then: kept
	check(MemberMesh.cached() <= MemberMesh.CACHE_LIMIT, "at most its limit (%d, was %d)" % [MemberMesh.cached(), before])
	check(is_same(MemberMesh.box(keep), kept), "a size asked for lately is still the same mesh")
	var a := MemberMesh.box(Vector3(0.2, 0.3, 0.4))
	check(is_same(MemberMesh.box(Vector3(0.2, 0.3, 0.4)), a), "the same size twice: one mesh")
	check_eq(MemberMesh.box(Vector3(0.2, 0.3, 0.4)).get_aabb().size.snappedf(0.001), Vector3(0.2, 0.3, 0.4), "its size")
