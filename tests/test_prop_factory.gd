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
	# kg: a solid oak table ~55-75 (oak since #825: 750 kg/m3); an iron cot with its tick ~25-40; a pine washstand ~9-20.
	var weights := {&"examining_table": [40.0, 80.0], &"iron_cot": [22.0, 45.0], &"washstand": [8.0, 32.0]}
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
	check(mat != null and mat.shader.resource_path == "res://src/render/scan_wood.gdshader", "a leg is the library's furniture oak")
	check(leg.mesh.has_meta(&"board_frame"), "drawn as a library board (batched by the way it faces)")
	check(PropKit.lib_material("lib:furniture_oak/few") == mat, "every oak prop shares one material")
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


func test_a_shot_through_an_oak_leg_is_carved_where_the_leg_is() -> void:
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


func test_the_hand_towel_wipes_up_blood_and_reddens() -> void:
	# A table's top of boards, blood spilt on it (a pool's worth), the towel drawn over it.
	var top := Structure.new()
	top.structure_id = &"wipe_top"
	world.add_child(top)
	for x in [-0.5, 0.5]:
		top.add_member("leg%d" % int(x * 10), &"post", &"framing", Vector3(0.05, 0.75, 0.05), Vector3(x, 0.375, 0))
	for i in 4:
		top.add_member("board%d" % i, &"furniture_top", &"framing", Vector3(1.2, 0.03, 0.15), Vector3(0, 0.765, -0.225 + 0.15 * i))
	top.infer_supports()
	var marks := FloorMarks.ensure(world)
	await physics_frames(2)
	marks.add_liquid(Vector3(0.0, 0.78, 0.0), &"blood", 60.0, 0.15)
	var towel := PropKit.make(&"hand_towel") as ClothProp
	towel.position = Vector3(0.0, 0.8, 0.0)
	world.add_child(towel)
	await physics_frames(20)
	var before := float(marks.mess(Vector3(0.0, 0.78, 0.0), 0.3).liquid)
	var took := 0.0
	# Drawn back and forth over it at a wiping pace, a tenth of a second at a time.
	for k in 30:
		var x := sin(k * 0.6) * 0.15
		took += float(towel.wipe_at(Vector3(x, 0.785, 0.0), 0.3, 0.1).blood)
	var after := float(marks.mess(Vector3(0.0, 0.78, 0.0), 0.3).liquid)
	check(took > 20.0, "it takes up the blood (%.0f ml of 60)" % took)
	check(after < before - 20.0, "and the top's left cleaner (%.0f -> %.0f ml)" % [before, after])
	check(towel.blood_ml > 20.0 and towel.bloodiness() > 0.02, "it's red where it took it (%.0f ml, %.2f red)" % [towel.blood_ml, towel.bloodiness()])
	check(towel.wipe_at(Vector3(3.0, 0.5, 3.0), 0.3, 0.1).blood == 0.0, "over nothing it takes nothing")


func test_the_hand_towel_hangs_over_the_washstands_bar() -> void:
	var w := await _place(&"washstand")
	var towel := PropKit.make(&"hand_towel") as ClothProp
	world.add_child(towel)
	var bar := _m(w, "towel_bar")
	towel.hang_over(bar, bar.global_basis.z, bar.global_position + Vector3.UP * (bar.size.y * 0.5 + 0.005))
	await physics_frames(120)
	var r := towel.height_range()
	check(r.y > bar.global_position.y, "its middle stays on the bar (top %.2f, bar %.2f)" % [r.y, bar.global_position.y])
	check(r.x > 0.2 and r.x < bar.global_position.y - 0.2, "and it hangs down either side, clear of the floor (%.2f)" % r.x)


# --- The doctor's batch D2 (#805): the dispensary and his desk ----------------------------------

const DOCTOR_D2_MEMBERS := [&"scales", &"roll_top_desk", &"dispensary_shelves", &"dispensary_counter", &"bentwood_chair"]
const DOCTOR_D2_BOTTLES := [&"medicine_bottle", &"medicine_bottle_round", &"poison_bottle", &"drug_jar"]


func test_doctor_d2_stands_weighs_and_draws_in_a_few_batches() -> void:
	# kg: a cased prescription balance ~6-12; a No. 14 bentwood ~3 (its rods' boxes in oak, a little more); an oak roll-top ~50-130 (its boards solid, 19 mm); walnut shelving and a counter, solid.
	var weights := {&"scales": [5.0, 14.0], &"roll_top_desk": [45.0, 130.0], &"dispensary_shelves": [60.0, 200.0],
			&"dispensary_counter": [40.0, 130.0], &"bentwood_chair": [2.0, 8.0]}
	for id: StringName in DOCTOR_D2_MEMBERS:
		var def := PropKit.definition(id)
		check(def.get("factory", "") == "tools/props/doctor.py", "%s is the factory's" % id)
		var p := await _place(id)
		check(p.settle().is_empty() and not p.loose, "%s stands: nothing breaks or falls" % id)
		check(p.members_without_load_path().is_empty(), "%s: every member has its way down %s" % [id, p.members_without_load_path()])
		var kg := p.mass()
		check(kg >= weights[id][0] and kg <= weights[id][1], "%s weighs %.1f kg" % [id, kg])
		check(p.batch_count() <= 8, "%s draws untouched in a few batches (%d)" % [id, p.batch_count()])
		p.queue_free()
		await physics_frames(1)


func test_the_desks_curved_sides_are_library_boards_cut_to_the_curve() -> void:
	var d := await _place(&"roll_top_desk")
	var side := _m(d, "case_side_l").drawn_node()
	var plain := _m(d, "case_back").drawn_node()
	check(side.material_override == plain.material_override and side.material_override == PropKit.lib_material("lib:furniture_oak/few"),
			"the curved side is the same oak as the rest")
	check(side.mesh.has_meta(&"board_frame"), "drawn as a library board (batched with the others)")
	var box := side.get_aabb()
	var faces := side.mesh.get_faces()
	# Cut to the curve: its front top corner is gone (no corner of the cut near the box's front top).
	var front_top := false
	var xf := side.transform
	for v in faces:
		var p := xf * v
		var m := _m(d, "case_side_l")
		if p.z > m.size.z * 0.5 - 0.02 and p.y > m.size.y * 0.5 - 0.02:
			front_top = true
	check(not front_top and faces.size() > 36, "the side is cut to its S-curve (%d corners, box %s)" % [faces.size(), box.size])


func test_doctor_d2_bottles_stand_wear_their_labels_and_break() -> void:
	var counts := {}
	var made: Array[GlassProp] = []
	var x := -1.0
	for id: StringName in DOCTOR_D2_BOTTLES:
		for k in 5:
			var b := PropKit.make(id) as GlassProp
			b.position = Vector3(x, 0, 0)
			x += 0.11
			world.add_child(b)
			made.append(b)
	await physics_frames(GlassProp.SETTLE_FRAMES + 4)
	for b in made:
		check(not b.loose and not b.broken, "%s stands" % b.kit_id)
		var labels := b.model.find_children("Label*", "MeshInstance3D", false, false)
		check(labels.size() == 1, "%s wears one label (%d)" % [b.kit_id, labels.size()])
		var glass := b.model.find_children("Glass*", "MeshInstance3D", false, false)
		check(glass.size() == 1 and (glass[0] as MeshInstance3D).material_override is ShaderMaterial \
				and ((glass[0] as MeshInstance3D).material_override as ShaderMaterial).shader.resource_path == "res://src/props/bottle_glass.gdshader",
				"%s is see-through tinted glass" % b.kit_id)
		if not labels.is_empty():
			counts.get_or_add(b.kit_id, {})[String(labels[0].name)] = true
	for id: StringName in DOCTOR_D2_BOTTLES:
		check(counts.get(id, {}).size() == 4, "%s's five wear its four labels in turn (%s)" % [id, counts.get(id, {}).keys()])
	# A ball along the row: through the glass of several.
	var spilt := []
	var on_spill := func(at: Vector3, liquid: StringName, litres: float, _s: Node) -> void: spilt.append([liquid, litres])
	Events.liquid_spilled.connect(on_spill)
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	var r: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(Vector3(-2.0, 0.06, 0), Vector3.RIGHT, r.muzzle_velocity, r.bullet_mass, r.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	await physics_frames(3)
	var broken := made.filter(func(g: GlassProp) -> bool: return g.broken).size()
	check(broken >= 3, "a ball along the shelf breaks the bottles in its way (%d)" % broken)
	check(spilt.size() >= 2 and float(spilt[0][1]) > 0.02, "what's in them goes on the floor (%s)" % [spilt.slice(0, 3)])
	Events.liquid_spilled.disconnect(on_spill)
	# One off a shelf's height onto the floor.
	var drop := PropKit.make(&"medicine_bottle") as GlassProp
	drop.position = Vector3(3, 1.2, 0)
	world.add_child(drop)
	await wait_until(func() -> bool: return drop.broken, 120)
	check(drop.broken, "a bottle off the top shelf breaks on the floor")


func test_the_mortar_breaks_shot_and_its_pestle_comes_through() -> void:
	var m := PropKit.make(&"mortar") as GlassProp
	world.add_child(m)
	await physics_frames(GlassProp.SETTLE_FRAMES + 4)
	check(not m.loose and not m.broken, "the mortar stands")
	check(m.model.find_children("Pestle*", "MeshInstance3D", false, false).size() == 2, "its pestle (head and handle) in it")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	var r: RevolverTuning = load("res://config/revolver.tres")
	ballistics.fire(Vector3(-5, 0.05, 0), Vector3.RIGHT, r.muzzle_velocity, r.bullet_mass, r.bullet_diameter)
	await physics_frames(3)
	check(m.broken, "a ball breaks the stoneware")
	check(world.find_children("Piece", "RigidBody3D", false, false).size() >= 1, "the pestle comes through whole")


func test_the_dispensarys_bottles_stand_on_their_shelf_and_come_down_with_it() -> void:
	var s := PropKit.spawn_fitted(&"dispensary_shelves", &"test_shelves", Vector3(0.3, 2.71, 1.2))
	world.add_child(s)
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	var board := _m(s, "shelf2")
	var y := board.global_position.y + board.size.y * 0.5
	var bottles: Array[GlassProp] = []
	for k in 4:
		var b := PropKit.make(&"medicine_bottle_round") as GlassProp
		b.position = Vector3(0.0, y + 0.002, -0.3 + 0.2 * k)
		world.add_child(b)
		bottles.append(b)
	await physics_frames(GlassProp.SETTLE_FRAMES + 4)
	check(bottles.all(func(b: GlassProp) -> bool: return not b.loose), "they stand on the board")
	s.break_member(board)
	await physics_frames(int(GlassProp.CHECK_EVERY * 60) + 4)
	check(bottles.all(func(b: GlassProp) -> bool: return b.loose or b.broken), "the board gone, they come down")


func test_the_scales_drop_their_pans_when_the_pillar_goes() -> void:
	var sc := await _place(&"scales")
	var pillar := _m(sc, "pillar")
	check(_m(sc, "pan_l").drawn_node().mesh.get_faces().size() > 100, "a pan is drawn from its model (dish and wires)")
	check((_m(sc, "beam").drawn_node().material_override as StandardMaterial3D) == PropModels.pbr("scales"), "the brass is baked")
	var gone := sc.break_member(pillar)
	check(gone.has(_m(sc, "beam").member_id) and gone.has(_m(sc, "pan_l").member_id), "the beam and pans come down with the pillar (%s)" % [gone])
	check(not gone.has(_m(sc, "base").member_id) and not gone.has(_m(sc, "pane_front").member_id), "the base and its case stay")
	var pane := _m(sc, "pane_front")
	check(pane.kind == &"glass" and (pane.drawn_node().material_override as ShaderMaterial).shader.resource_path == "res://src/props/bottle_glass.gdshader",
			"its case is glazed with clear glass")


func test_his_bentwood_chair_carries_him() -> void:
	var c := await _place(&"bentwood_chair")
	check(_m(c, "back").drawn_node().mesh.get_faces().size() > 300, "its back is drawn from its model (the hoop and its inner loop)")
	check(PropKit.definition(&"bentwood_chair").has("seat"), "a man sits on it as on the kit's chair")
	_m(c, "seat").extra_load = 90.0 * 0.75 * 9.81
	check(c.settle().is_empty() and not c.loose, "it carries a 90 kg man")


func test_the_counters_drawers_wear_their_knobs() -> void:
	var c := await _place(&"dispensary_counter")
	var drawers := c.get_members().filter(func(m: StructureMember) -> bool: return String(m.member_id).contains("/drawer_"))
	check(drawers.size() == 24, "three rows of eight drawers (%d)" % drawers.size())
	check(c.batch_count() <= 8, "and it still draws in a few batches (%d)" % c.batch_count())


func test_a_pull_on_an_oak_drawer_is_drawn_on_the_drawer() -> void:
	# A dress layer on a library board (a pull, a knob, his papers) sits where its kit file puts it,
	# not off by the board frame's half length (#805), and stays there when the board is carved.
	var d := await _place(&"roll_top_desk")
	var drawer := _m(d, "drawer_l0")
	var layer: MeshInstance3D = null
	for c in drawer.drawn_node().get_children():
		if String(c.name).begins_with("Dress"):
			layer = c
	check(layer != null, "the drawer wears its pull")
	if layer:
		# (in the member's own space: a batched member's nodes are out of the tree)
		var off := (drawer.drawn_node().transform * layer.transform * layer.get_aabb()).get_center()
		check(absf(off.x) < 0.03 and absf(off.y) < 0.03, "the pull is on the drawer's middle (off by %s)" % off)


# --- The doctor's batch D3 (#819): his books, the hall's pegs, the pot and the blankets ---------

const DOCTOR_D3_MEMBERS := [&"book_row_a", &"book_row_b", &"book_row_c", &"book_stack", &"bookcase", &"folded_blankets", &"folded_blanket"]


func test_doctor_d3_stands_weighs_and_draws_in_a_few_batches() -> void:
	# kg: an octavo in sheep ~1.2-2 (nine or ten a row); the army's quarto ~3.5; an oak bookcase
	# ~20-40; a wool blanket ~2 (its member's canvas is lighter).
	var weights := {&"book_row_a": [8.0, 22.0], &"book_row_b": [8.0, 22.0], &"book_row_c": [8.0, 22.0], &"book_stack": [2.5, 9.0], &"bookcase": [15.0, 45.0],
			&"folded_blankets": [1.5, 8.0], &"folded_blanket": [0.5, 3.0]}
	for id: StringName in DOCTOR_D3_MEMBERS:
		var def := PropKit.definition(id)
		check(def.get("factory", "") == "tools/props/doctor.py", "%s is the factory's" % id)
		var p := await _place(id)
		check(p.settle().is_empty() and not p.loose, "%s stands: nothing breaks or falls" % id)
		check(p.members_without_load_path().is_empty(), "%s: every member has its way down %s" % [id, p.members_without_load_path()])
		var kg := p.mass()
		check(kg >= weights[id][0] and kg <= weights[id][1], "%s weighs %.1f kg" % [id, kg])
		check(p.batch_count() <= 8, "%s draws untouched in a few batches (%d)" % [id, p.batch_count()])
		p.queue_free()
		await physics_frames(1)


func test_his_books_are_printed_on_their_sheet_and_burn() -> void:
	var row := await _place(&"book_row_a")
	var book := _m(row, "book0")
	var mi := book.drawn_node()
	check((mi.material_override as StandardMaterial3D) == PropModels.pbr("medical_books"), "a book wears the books' printed sheet")
	check(mi.mesh.get_faces().size() > 20 * 3, "drawn from its model (boards, leaves, a rounded spine), not a box")
	for suffix in ["albedo", "orm"]:
		check(ResourceLoader.exists("res://assets/props/models/medical_books_%s.png" % suffix), "the sheet's %s is there" % suffix)
	check(book.wood == &"paper" and not FireTuning.new().fireproof.has(book.wood), "a book is paper: it burns")
	check(row.batch_count() <= 2, "a row is one draw or two (%d)" % row.batch_count())
	var pile := await _place(&"book_stack", Vector3(2, 0, 0))
	var gone := pile.members_without_load_path({pile.get_members()[0].member_id: true})
	check(gone.size() == 2, "the bottom book out, the two on it come down (%s)" % [gone])


func test_a_ball_goes_into_a_book_and_the_row_stands() -> void:
	var row := await _place(&"book_row_b")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(1)
	var book := row.get_members()[3]
	var from := book.global_position + Vector3(0, 0, 5)
	var r: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(from, (book.global_position - from).normalized(), r.muzzle_velocity, r.bullet_mass, r.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	await physics_frames(3)
	check(not book.holes.is_empty() or book.broken, "a .45 ball marks the book it meets (holes %d, broken %s)" % [book.holes.size(), book.broken])
	check(not row.loose, "the row stands")


func test_a_row_of_books_stands_on_its_shelf_and_comes_down_with_it() -> void:
	var c := await _place(&"bookcase")
	var shelf := _m(c, "shelf2")
	var row := PropKit.spawn(&"book_row_a")
	row.position = Vector3(0, shelf.global_position.y + shelf.size.y * 0.5 + 0.002, 0)
	world.add_child(row)
	await physics_frames(KitProp.SETTLE_FRAMES + 4)
	check(not row.loose, "the row stands on the shelf")
	check(absf(row.global_position.y - (shelf.global_position.y + shelf.size.y * 0.5)) < 0.02, "on its top (%.3f)" % row.global_position.y)
	c.break_member(shelf)
	await wait_until(func() -> bool: return row.loose, 180)
	check(row.loose, "the shelf gone, the row comes down")


func test_the_coat_pegs_hang_on_their_nails_and_a_peg_gone_drops_the_coat() -> void:
	var wall := Structure.new()
	wall.structure_id = &"peg_wall"
	world.add_child(wall)
	for x in [-0.5, 0.5]:
		wall.add_member("stud%d" % int(x * 10), &"post", &"framing", Vector3(0.05, 2.4, 0.1), Vector3(x, 1.2, -0.07))
	for i in 10:
		wall.add_member("board%d" % i, &"board", &"framing", Vector3(1.4, 0.2, 0.02), Vector3(0, 0.3 + 0.2 * i, -0.01))
	wall.infer_supports()
	var p := PropKit.spawn(&"coat_pegs")
	p.position = Vector3(0, 1.65, 0)
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 6)
	check(not p.loose, "the rail hangs on its nails in the wall")
	check(p.members_without_load_path().is_empty(), "everything on it hangs from it %s" % [p.members_without_load_path()])
	check(_m(p, "coat").drawn_node().mesh.get_faces().size() > 1000, "his coat is drawn from its model")
	check((_m(p, "hat").drawn_node().material_override as StandardMaterial3D) == PropModels.pbr("coat_pegs"), "the hat is baked")
	check(not FireTuning.new().fireproof.has(_m(p, "coat").wood), "the coat burns")
	var falling := p.members_without_load_path({_m(p, "peg1").member_id: true})
	check(falling.has(_m(p, "coat").member_id), "its peg gone, the coat comes down")
	check(not falling.has(_m(p, "hat").member_id), "the hat stays on its own")
	check(_m(p, "rail").drawn_node().mesh.has_meta(&"board_frame"), "the rail is a library board")


func test_the_chamber_pot_stands_and_a_ball_breaks_it() -> void:
	var pot := PropKit.make(&"chamber_pot") as GlassProp
	pot.position = Vector3(0, 0, 0)
	world.add_child(pot)
	await physics_frames(GlassProp.SETTLE_FRAMES + 4)
	check(not pot.broken and not pot.loose, "the pot stands on the floor")
	check(pot.model.get_child_count() >= 1, "drawn from its model")
	check(PropKit.definition(&"chamber_pot").size[1] < 0.42, "it goes under the cot's spring (0.42 m)")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	var r: RevolverTuning = load("res://config/revolver.tres")
	ballistics.fire(pot.global_position + Vector3(-5, 0.07, 0), Vector3.RIGHT, r.muzzle_velocity, r.bullet_mass, r.bullet_diameter)
	await physics_frames(3)
	check(pot.broken, "a ball breaks it")
