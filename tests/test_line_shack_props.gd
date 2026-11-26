extends TestCase
## The line shack's props (#1263; tools/props/line_shack.py): each standing kit prop stands where it's put,
## weighs something and is handed out by name; the hung ones (gun belt, bridle) have their nails; the
## sizes are the shack's (a bunk fits its place, a bench its side of the table), every look is known.

const STANDING := [&"bunk_stacked", &"bunk", &"plank_bench", &"bedroll", &"saddle_rack", &"saddle", &"skillet", &"tin_plate", &"tin_cans"]
const HUNG := [&"gun_belt", &"bridle"]
var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	world.add_child(floor_body)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_each_standing_prop_stands_weighs_and_is_handed_out() -> void:
	for id: StringName in STANDING:
		var p := PropKit.spawn(id)
		world.add_child(p)
		await physics_frames(KitProp.SETTLE_FRAMES + 2)
		var st := p.settle()
		check(st.is_empty(), "%s stands: nothing breaks or falls (%s)" % [id, st.slice(0, 4)])
		check(not p.loose, "%s stands on its feet" % id)
		check(p.mass() > 0.2, "%s weighs something (%.1f kg)" % [id, p.mass()])
		check(PropLibrary.spawn(id) is KitProp, "PropLibrary hands out %s by name" % id)
		p.queue_free()
		await physics_frames(2)


func test_the_hung_props_are_on_nails() -> void:
	for id: StringName in HUNG:
		var def := PropKit.definition(id)
		check(not def.is_empty() and def.members.size() > 0, "%s loads with members" % id)
		check(def.has("hangs") and not (def.hangs.nails as Array).is_empty(), "%s hangs on a nail" % id)


func test_the_bunks_and_benches_are_the_shacks_size() -> void:
	var want := {&"bunk_stacked": Vector2(0.8, 1.95), &"bunk": Vector2(0.78, 1.9), &"plank_bench": Vector2(1.31, 0.27)}
	for id: StringName in want:
		var def := PropKit.definition(id)
		var lo := Vector2(1e9, 1e9)
		var hi := Vector2(-1e9, -1e9)
		for m: Dictionary in def.members:
			var a: Array = m.at
			var s: Array = m.size
			lo = Vector2(minf(lo.x, a[0] - s[0] * 0.5), minf(lo.y, a[2] - s[2] * 0.5))
			hi = Vector2(maxf(hi.x, a[0] + s[0] * 0.5), maxf(hi.y, a[2] + s[2] * 0.5))
		var w: Vector2 = want[id]
		check(hi.x - lo.x <= w.x and hi.y - lo.y <= w.y, "%s fits %s (is %s)" % [id, w, hi - lo])


func test_every_look_is_known() -> void:
	for id: StringName in STANDING + HUNG:
		for m: Dictionary in PropKit.definition(id).members:
			var look := String(m.get("look", ""))
			check(not look.begins_with("prop:") or look.get_slice(":", 1) in [
					"iron", "brass", "tin", "canvas", "leather", "hide_pale", "ebony", "straw", "dark_wood", "dung"],
					"%s.%s: look %s is one the kit knows" % [id, m.id, look])
