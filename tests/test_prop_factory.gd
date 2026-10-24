extends TestCase
## The prop factory (docs/briefs/prop-factory.md): every prop it makes is a kit prop that stands
## where it's put, weighs what the real thing does and comes apart the way it's built. Batch 1, the
## wagons and wheels (tools/props/wagons.py): a wagon stands on its four wheels on the street's
## ground; its wheels come apart by their spokes; the canvas comes down with the side under it.
## Batch 2, the street's soft stuff (hay, straw, sacks, dung): drawn from Blender's models.

const BATCH_1 := [&"wagon_wheel", &"broken_wagon_wheel", &"buckboard", &"freight_wagon", &"covered_wagon"]
## Batch 2, drawn by Blender models (tools/blender/props/, assets/props/models/); the deer head
## hangs (tests/test_wall_props.gd).
const BATCH_2 := [&"hay_bale", &"straw_pile", &"feed_sack", &"grain_sacks", &"horse_droppings"]

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _place(id: StringName, at := Vector3.ZERO) -> KitProp:
	var p := PropKit.spawn(id)
	p.position = at
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	return p


func _m(p: KitProp, id: String) -> StructureMember:
	return p.get_member(StringName("%s/%s" % [p.structure_id, id]))


func test_batch_one_stands_on_the_ground_and_weighs_what_it_should() -> void:
	# kg, from the makers' catalogues (a 4 ft wheel ~45 kg; a buckboard ~300, a freight wagon ~650).
	var weights := {&"wagon_wheel": [30.0, 70.0], &"broken_wagon_wheel": [20.0, 60.0], &"buckboard": [200.0, 450.0],
			&"freight_wagon": [450.0, 900.0], &"covered_wagon": [300.0, 650.0]}
	for id: StringName in BATCH_1:
		var def := PropKit.definition(id)
		check(def.get("in_game", false) and def.has("factory"), "%s is the factory's and in the game" % id)
		var p := await _place(id)
		check(p.settle().is_empty(), "%s stands: nothing breaks or falls" % id)
		check(not p.loose, "%s stands on its feet" % id)
		var kg := p.mass()
		check(kg >= weights[id][0] and kg <= weights[id][1], "%s weighs %.0f kg" % [id, kg])
		# Every look a batch, no more (wood, iron, the bed's pine, canvas).
		check(p.batch_count() <= 6, "%s draws untouched in a few batches (%d)" % [id, p.batch_count()])
		check(PropLibrary.spawn(id) is KitProp, "PropLibrary hands out %s by name" % id)
		p.queue_free()
		await physics_frames(1)


func test_a_wagon_stands_on_the_felloes_under_its_hubs_and_its_tongue() -> void:
	var w := await _place(&"buckboard")
	var feet := w.get_members().filter(func(m: StructureMember) -> bool: return m.grounded)
	check(feet.size() == 5, "five feet: the felloe under each hub and the tongue's tip (%d)" % feet.size())
	check(w.members_without_load_path().is_empty(), "every member has its way down to the ground")


func test_two_spokes_out_under_a_hub_and_that_wheel_comes_apart() -> void:
	var w := await _place(&"freight_wagon")
	var broken := {StringName("%s/front_l_spoke8" % w.structure_id): true, StringName("%s/front_l_spoke9" % w.structure_id): true}
	var falling := w.members_without_load_path(broken)
	check(falling.has(_m(w, "front_l_hub").member_id), "the hub drops")
	check(falling.has(_m(w, "front_l_felloe3").member_id), "and the rim over it with its spokes")
	check(not falling.has(_m(w, "floor0").member_id), "the bed's still carried by the other hubs")
	check(not falling.has(_m(w, "front_r_hub").member_id), "the other wheels stand")


func test_the_canvas_comes_down_with_the_side_under_it() -> void:
	var w := await _place(&"covered_wagon")
	var falling := w.members_without_load_path({_m(w, "side_l1").member_id: true})
	for id in ["canvas_wall_l", "canvas_l0", "canvas_l1"]:
		check(falling.has(_m(w, id).member_id), "%s comes down" % id)
	check(not falling.has(_m(w, "canvas_r1").member_id), "the other side's canvas stays up on its side")


func test_a_ball_through_a_spoke_splits_it() -> void:
	var w := await _place(&"buckboard")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(1)
	# A spoke square across the shot (the one standing straight up from the hub).
	var spoke := _m(w, "front_r_spoke3")
	var from := spoke.global_position + Vector3(0, 0, 5)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(from, (spoke.global_position - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	await physics_frames(3)
	check(spoke.broken, "a .45 ball through a 55 mm oak spoke splits it (section left %.2f)" % spoke.section_left(w.tuning))
	check(not w.loose, "the wagon stands on its other spokes")


func test_a_stick_beside_a_loose_wheel_throws_it() -> void:
	var wheel := await _place(&"wagon_wheel")
	Events.exploded.emit(wheel.global_position + Vector3(-1.5, 0.1, 0), Blast.t().tnt_per_stick)
	await physics_frames(3)
	check(wheel.loose, "a stick 1.5 m off throws it")


func test_batch_two_stands_weighs_and_is_drawn_from_its_blender_model() -> void:
	var weights := {&"hay_bale": [20.0, 35.0], &"straw_pile": [3.0, 12.0], &"feed_sack": [30.0, 50.0], &"grain_sacks": [110.0, 160.0],
			&"horse_droppings": [0.5, 3.0]}
	for id: StringName in BATCH_2:
		var p := await _place(id)
		check(p.settle().is_empty() and not p.loose, "%s stands" % id)
		var kg := p.mass()
		check(kg >= weights[id][0] and kg <= weights[id][1], "%s weighs %.1f kg" % [id, kg])
		for m in p.get_members():
			var mesh := (m.get_child(0) as MeshInstance3D).mesh
			check(mesh != null and mesh.get_faces().size() > 36 * 3, "%s's %s is drawn from its model, not a box" % [id, m.member_id])
		p.queue_free()
		await physics_frames(1)


func test_the_deer_head_is_drawn_from_its_mount() -> void:
	for part in ["plaque", "neck", "head", "pale", "nose", "eyes", "antlers"]:
		check(PropKit.model_part("deer_head", part) != null, "the mount has its %s" % part)


func test_the_top_sack_comes_down_when_one_under_it_goes() -> void:
	var s := await _place(&"grain_sacks")
	var falling := s.members_without_load_path({_m(s, "sack0").member_id: true, _m(s, "sack1").member_id: true})
	check(falling.has(_m(s, "sack2").member_id), "with both under it gone, the top sack falls")
	check(s.members_without_load_path({_m(s, "sack0").member_id: true}).is_empty(), "on one it stays")
