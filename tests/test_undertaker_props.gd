extends TestCase
## The undertaker's props (#1181; tools/props/undertaker.py): each standing kit prop stands where it's put,
## weighs something and is handed out by name; the hung ones (tool rack, wreath, lantern, harness) are
## files with their nails; the whole batch's bodies are counted (the valley is near Jolt's limit).

const STANDING := [&"coffin_hex", &"coffin_hex_open", &"coffin_lid", &"coffin_rect", &"coffin_child", &"trestles", &"bier",
		&"workbench", &"glue_pot", &"plank_stack", &"embalming_table", &"zinc_pail", &"cooling_board", &"sheeted_board",
		&"embalming_pump", &"carboy", &"fluids_shelf", &"shroud_shelf", &"ice_bin", &"corpse_cooler", &"coffin_rack",
		&"safety_coffin", &"posing_stand", &"posing_chair", &"hearse"]
const HUNG := [&"tool_rack", &"hair_wreath", &"iron_lantern", &"harness_rack"]
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
		check(not p.loose, "%s stands on its feet (footed %s, feet %d, members %d, c %s, hull %s)" % [id, p._footed, p._feet.size(), p.get_members().size(), p.centre_of_weight(), p.footprint()])
		check(p.mass() > 0.3, "%s weighs something (%.1f kg)" % [id, p.mass()])
		check(PropLibrary.spawn(id) is KitProp, "PropLibrary hands out %s by name" % id)
		p.queue_free()
		await physics_frames(2)


func test_the_hung_props_are_on_nails_and_their_files_load() -> void:
	for id: StringName in HUNG:
		var def := PropKit.definition(id)
		check(not def.is_empty() and def.members.size() > 0, "%s loads with members" % id)
		check(def.has("hangs") and not (def.hangs.nails as Array).is_empty(), "%s hangs on a nail" % id)


func test_the_batch_is_few_bodies_and_every_look_is_known() -> void:
	var bodies := 0
	for id: StringName in STANDING + HUNG:
		var def := PropKit.definition(id)
		bodies += (def.members as Array).size()
		for m: Dictionary in def.members:
			var look := String(m.get("look", def.get("look", "")))
			check(not look.begins_with("prop:") or look.get_slice(":", 1) in [
					"iron", "plate_iron", "brass", "tin", "canvas", "leather", "hide_dark", "ebony", "straw", "burl", "ivory", "dark_wood", "mid_wood"],
					"%s.%s: look %s is one the kit knows" % [id, m.id, look])
	check(bodies < 520, "the batch is %d members, under 520 (the valley's room)" % bodies)
