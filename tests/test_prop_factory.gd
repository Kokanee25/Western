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
			var mesh := m.drawn_node().mesh
			check(mesh != null and mesh.get_faces().size() > 36 * 3, "%s's %s is drawn from its model, not a box" % [id, m.member_id])
		p.queue_free()
		await physics_frames(1)


func test_the_deer_head_is_drawn_from_its_mount() -> void:
	for part in ["plaque", "neck", "head", "nose"]:
		check(PropKit.model_part("deer_head", part) != null, "the mount has its %s" % part)
	# Rodin's model, in its own paint (2026-10-24).
	var paint := PropKit.material("model:deer_head", 0) as ShaderMaterial
	check(paint != null and paint.get_shader_parameter(&"albedo_tex") != null, "the mount wears its own paint")


func test_the_steer_skull_is_bone_on_a_plank() -> void:
	for part in ["plank", "skull", "horn_l", "horn_r"]:
		check(PropKit.model_part("steer_skull", part) != null, "the skull has its %s" % part)
	var woods := {}
	for m: Dictionary in PropKit.definition(&"steer_skull").members:
		woods[m.id] = m.wood
	check(woods.plank == "weathered_pine" and woods.skull == "bone" and woods.horn_l == "bone", "a pine plank, bone skull and horns: %s" % woods)
	check(TimberTuning.new().woods.has(&"bone"), "bone has its strengths")
	check(FireTuning.new().fireproof.has(&"bone"), "bone doesn't burn")


func test_the_top_sack_comes_down_when_one_under_it_goes() -> void:
	var s := await _place(&"grain_sacks")
	var falling := s.members_without_load_path({_m(s, "sack0").member_id: true, _m(s, "sack1").member_id: true})
	check(falling.has(_m(s, "sack2").member_id), "with both under it gone, the top sack falls")
	check(s.members_without_load_path({_m(s, "sack0").member_id: true}).is_empty(), "on one it stays")


# --- The doctor's office, batch D1 (#788; tools/props/doctor.py, tools/blender/props/doctor_d1.py) --

const DOCTOR_D1 := [&"examining_table", &"iron_cot", &"washstand"]
const DOCTOR_D1_GLASS := [&"wash_basin", &"wash_pitcher", &"reflector_lamp"]


func test_doctor_d1_stands_weighs_and_draws_in_a_few_batches() -> void:
	# kg: a solid walnut table ~45-60; an iron cot with its tick ~25-40; a washstand ~15-30.
	var weights := {&"examining_table": [40.0, 70.0], &"iron_cot": [22.0, 45.0], &"washstand": [12.0, 32.0]}
	for id: StringName in DOCTOR_D1:
		var def := PropKit.definition(id)
		check(def.get("factory", "") == "tools/props/doctor.py", "%s is the factory's" % id)
		var p := await _place(id)
		check(p.settle().is_empty() and not p.loose, "%s stands: nothing breaks or falls" % id)
		check(p.members_without_load_path().is_empty(), "%s: every member has its way down" % id)
		var kg := p.mass()
		check(kg >= weights[id][0] and kg <= weights[id][1], "%s weighs %.1f kg" % [id, kg])
		# Library boards batch by the way they face (a table's legs, aprons both ways, top, shelf and
		# drawer fronts: five frames), the baked look and its dress one or two more.
		check(p.batch_count() <= 8, "%s draws untouched in a few batches (%d)" % [id, p.batch_count()])
		p.queue_free()
		await physics_frames(1)


func test_doctor_d1_woods_are_the_libraries_and_its_metal_is_baked() -> void:
	var t := await _place(&"examining_table")
	var leg := _m(t, "leg0").drawn_node()
	var mat := leg.material_override as ShaderMaterial
	check(mat != null and mat.shader.resource_path == "res://src/render/scan_wood.gdshader", "a leg is the library's walnut")
	check(leg.mesh.has_meta(&"board_frame"), "drawn as a library board (batched by the way it faces)")
	check(PropKit.lib_material("lib:fine_walnut_tg/few") == mat, "every walnut prop shares one material")
	var pad := _m(t, "pad").drawn_node()
	var oil := pad.material_override as StandardMaterial3D
	check(oil != null and oil.albedo_texture != null and oil.roughness_texture != null and oil.metallic_texture != null,
			"the pad is baked the gun way: albedo and ORM")
	var c := await _place(&"iron_cot", Vector3(3, 0, 0))
	var post := _m(c, "post0").drawn_node()
	check((post.material_override as StandardMaterial3D) == PropModels.pbr("iron_cot"), "the cot's iron is its baked japanned iron")
	check(post.mesh.get_faces().size() > 36 * 3, "a post is drawn from its model (a tube with its knob), not a box")
	check(FireTuning.new().fireproof.has(_m(c, "post0").wood), "iron doesn't burn")
	check(not FireTuning.new().fireproof.has(_m(c, "tick").wood), "the straw tick does")
	for model in ["examining_table", "iron_cot", "washset", "instrument_tray", "reflector_lamp"]:
		for suffix in ["albedo", "orm"]:
			check(ResourceLoader.exists("res://assets/props/models/%s_%s.png" % [model, suffix]), "%s has its baked %s" % [model, suffix])


func test_a_man_laid_on_the_table_or_the_cot_is_carried() -> void:
	for id: StringName in [&"examining_table", &"iron_cot"]:
		var p := await _place(id)
		var seat: Dictionary = PropKit.definition(id).seat
		_m(p, String(seat.member)).extra_load = 90.0 * 9.81
		check(p.settle().is_empty(), "%s carries a 90 kg man" % id)
		p.queue_free()
		await physics_frames(1)


func test_a_shot_through_a_walnut_leg_is_carved_where_the_leg_is() -> void:
	var t := await _place(&"examining_table")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(1)
	var leg := _m(t, "leg2")
	var from := leg.global_position + Vector3(0, 0, 5)
	var r: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(from, (leg.global_position - from).normalized(), r.muzzle_velocity, r.bullet_mass, r.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	await physics_frames(3)
	check(not leg.holes.is_empty() and not leg.broken, "the ball holes the 65 mm leg and it holds (holes %d, broken %s, section left %.2f)" % [leg.holes.size(), leg.broken, leg.section_left(t.tuning)])
	if not leg.broken:
		var mi := leg.drawn_node()
		if mi.mesh and not mi.mesh.has_meta(&"board_frame"):
			check(mi.transform.is_equal_approx(Transform3D()), "carved, its mesh is drawn in the leg's own space")
	check(not t.loose, "the table stands")


func test_doctor_d1_glass_stands_and_the_china_breaks() -> void:
	var w := await _place(&"washstand")
	var top := PropKit.bounds(PropKit.definition(&"washstand")).end.y
	var basin := PropKit.make(&"wash_basin") as GlassProp
	basin.position = Vector3(0, 0.76, 0.03)
	world.add_child(basin)
	var lamp := PropKit.make(&"reflector_lamp") as GlassProp
	lamp.position = Vector3(2, 0, 0)
	world.add_child(lamp)
	var tray := PropKit.make(&"instrument_tray") as GlassProp
	tray.position = Vector3(-2, 0, 0)
	world.add_child(tray)
	await physics_frames(GlassProp.SETTLE_FRAMES + 4)
	check(top > 0.75, "the washstand's top is at %.2f" % top)
	check(not basin.broken and not basin.loose, "the basin stands on the washstand")
	check(tray is LooseProp and not tray.loose, "the tray lies where it's put, a loose prop")
	for g: GlassProp in [basin, lamp]:
		check(g.model.get_child_count() >= 1, "%s is drawn from its model" % g.kit_id)
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	var r: RevolverTuning = load("res://config/revolver.tres")
	var at := basin.global_position + Vector3.UP * 0.05
	ballistics.fire(at + Vector3(-5, 0, 0), Vector3.RIGHT, r.muzzle_velocity, r.bullet_mass, r.bullet_diameter)
	await physics_frames(3)
	check(basin.broken, "a ball breaks the basin")
	var pitcher := PropKit.make(&"wash_pitcher") as GlassProp
	pitcher.position = Vector3(0, 1.2, 1.5)
	world.add_child(pitcher)
	await wait_until(func() -> bool: return pitcher.broken, 120)
	check(pitcher.broken, "the pitcher dropped from 1.2 m breaks (%.1f m/s against 2.5)" % sqrt(2.0 * 9.81 * 1.2))
	w.queue_free()


func test_the_reflector_lamp_hangs_on_its_nail_and_its_chimney_glows_when_lit() -> void:
	# A wall: two studs and boards across them, its face at z = 0 (the lamp's back toward it).
	var wall := Structure.new()
	wall.structure_id = &"lamp_wall"
	world.add_child(wall)
	for x in [-0.4, 0.4]:
		wall.add_member("stud%d" % int(x * 10), &"post", &"framing", Vector3(0.05, 2.4, 0.1), Vector3(x, 1.2, -0.07))
	for i in 10:
		wall.add_member("board%d" % i, &"board", &"framing", Vector3(1.2, 0.2, 0.02), Vector3(0, 0.3 + 0.2 * i, -0.01))
	wall.infer_supports()
	var lamp := PropKit.make(&"reflector_lamp") as GlassProp
	lamp.position = Vector3(0, 1.3, 0.125)
	world.add_child(lamp)
	var light := OilLamp.new()
	light.name = "Light"
	light.show_mesh = false
	lamp.add_child(light)
	await physics_frames(GlassProp.SETTLE_FRAMES + 6)
	check(not lamp.loose and not lamp.broken, "it hangs on its nail in the wall")
	light.set_lit(true)
	var chimney := lamp._chimney_mesh()
	check(chimney != null, "its model has its glass chimney")
	check(chimney != null and float(chimney.get_instance_shader_parameter(&"glow")) == 1.0, "lit, its chimney glows")
	light.set_lit(false)
	check(chimney != null and float(chimney.get_instance_shader_parameter(&"glow")) == 0.0, "out, it doesn't")
