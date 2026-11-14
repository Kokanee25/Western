extends TestCase
## Saloon B's stage and dressing room props (#903; tools/props/saloon_stage.py, tools/blender/props/
## saloon_stage.py): the dressing mirror, the costume pegs, the travelling trunk, the dressing screen
## and the footlight stand where they're put, weigh what the real things do, stay within the bodies
## their README rows give (the valley is near Jolt's limit, #865), and come apart as they're built.

const STANDING := [&"dressing_mirror", &"travelling_trunk", &"dressing_screen"]

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


## A boarded wall, its face at z = 0: what the pegs are nailed to.
func _wall(id: StringName, width := 1.8) -> Structure:
	var wall := Structure.new()
	wall.structure_id = id
	world.add_child(wall)
	for x in [-width * 0.4, width * 0.4]:
		wall.add_member("stud%d" % int(x * 10), &"post", &"framing", Vector3(0.05, 2.6, 0.1), Vector3(x, 1.3, -0.07))
	for i in 12:
		wall.add_member("board%d" % i, &"board", &"framing", Vector3(width, 0.2, 0.02), Vector3(0, 0.3 + 0.2 * i, -0.01))
	wall.infer_supports()
	return wall


func test_the_stage_props_stand_weigh_and_draw_in_a_few_batches() -> void:
	var weights := {&"dressing_mirror": [20.0, 60.0], &"travelling_trunk": [12.0, 40.0], &"dressing_screen": [6.0, 25.0]}
	var bodies := {&"dressing_mirror": 13, &"travelling_trunk": 7, &"dressing_screen": 15}
	for id: StringName in STANDING:
		var def := PropKit.definition(id)
		check(def.get("factory", "") == "tools/props/saloon_stage.py", "%s is the factory's" % id)
		var p := await _place(id)
		check(p.settle().is_empty() and not p.loose, "%s stands: nothing breaks or falls" % id)
		check(p.members_without_load_path().is_empty(), "%s: every member has its way down %s" % [id, p.members_without_load_path()])
		var kg := p.mass()
		check(kg >= weights[id][0] and kg <= weights[id][1], "%s weighs %.2f kg" % [id, kg])
		check(p.member_count() <= bodies[id], "%s stands as %d bodies (at most %d)" % [id, p.member_count(), bodies[id]])
		check(p.batch_count() <= 9, "%s draws untouched in a few batches (%d)" % [id, p.batch_count()])
		p.queue_free()
		await physics_frames(1)


func test_the_woods_are_the_librarys_furniture_never_the_floors() -> void:
	for id: StringName in STANDING + [&"costume_pegs"]:
		for spec: Dictionary in PropKit.expand(PropKit.definition(id)):
			var look := String(spec.get("look", PropKit.definition(id).get("look", "")))
			check(not look.begins_with("lib:floor_"), "%s/%s isn't the floor's wood" % [id, spec.id])
			check(not look.begins_with("wood:"), "%s/%s is the library's or baked (%s)" % [id, spec.id, look])


func test_the_mirrors_glass_is_the_back_bars_and_a_ball_breaks_it() -> void:
	var p := await _place(&"dressing_mirror")
	var glass := _m(p, "glass")
	check(glass.kind == &"glass" and glass.wood == &"glass", "its glass is a glass member")
	var look := ""
	for spec: Dictionary in PropKit.expand(p.definition):
		if spec.id == "glass":
			look = String(spec.get("look", ""))
	check(look == "prop:mirror", "drawn as the back bar's painted mirror (%s)" % look)
	check(glass.drawn_node() != null and glass.drawn_node().material_override is ShaderMaterial, "its glass paints the room")
	# Held in its frame: on the shelf at its foot and under the head rail.
	check(not p.members_without_load_path({_m(p, "shelf").member_id: true}).has(glass.member_id), "its shelf gone, the head holds it")
	var falling := p.members_without_load_path({_m(p, "standard_l").member_id: true, _m(p, "standard_r").member_id: true})
	check(falling.has(glass.member_id) and falling.has(_m(p, "head").member_id), "its standards gone, the glass and head come down")
	check(not falling.has(_m(p, "top").member_id), "the table stands on its own legs")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	var r: RevolverTuning = load("res://config/revolver.tres")
	var at := glass.global_position
	ballistics.fire(at + Vector3(0, 0, 5), Vector3.FORWARD, r.muzzle_velocity, r.bullet_mass, r.bullet_diameter)
	await physics_frames(4)
	check(glass.broken or not is_instance_valid(glass) or glass.is_queued_for_deletion(), "a ball breaks the glass")


func test_the_costume_pegs_hang_and_a_peg_gone_drops_the_dress() -> void:
	_wall(&"peg_wall")
	var p := PropKit.spawn(&"costume_pegs")
	p.position = Vector3(0, 1.7, 0)
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 6)
	check(not p.loose, "the rail hangs on its nails")
	check(p.members_without_load_path().is_empty(), "everything on it hangs from it %s" % [p.members_without_load_path()])
	check(p.member_count() <= 10, "%d bodies (at most 10)" % p.member_count())
	for id in ["dress", "coat", "hat"]:
		check(_m(p, id).drawn_node().mesh.get_faces().size() > 300, "the %s is drawn from its model" % id)
		check(not FireTuning.new().fireproof.has(_m(p, id).wood), "the %s burns" % id)
	var falling := p.members_without_load_path({_m(p, "peg1").member_id: true})
	check(falling.has(_m(p, "dress").member_id), "its peg gone, the dress comes down")
	check(not falling.has(_m(p, "coat").member_id), "the coat stays on its own")
	check(_m(p, "rail").drawn_node().mesh.has_meta(&"board_frame"), "the rail is a library board")


func test_the_trunks_lid_stands_open_and_shuts() -> void:
	var p := await _place(&"travelling_trunk")
	check(p.hinge_names().has("lid"), "its lid is hinged")
	var lid := _m(p, "lid")
	var shut_y := lid.global_position.y
	check(p.open_hinge("lid"), "the lid opens")
	await physics_frames(KitProp.SETTLE_FRAMES)
	check(not p.loose and not lid.broken, "open, it stands")
	check(p.members_without_load_path().is_empty(), "open, the lid hangs on its hinges %s" % [p.members_without_load_path()])
	check(lid.global_position.z < -0.2 and lid.global_position.y > shut_y, "the lid stands up behind it (%s)" % lid.global_position)
	check(p.open_hinge("lid", 0.0), "and shuts")
	check(absf(lid.global_position.y - shut_y) < 0.01, "shut where it was")
	check(not FireTuning.new().fireproof.has(_m(p, "costumes").wood), "the costumes in it burn")
	var falling := p.members_without_load_path({_m(p, "bottom").member_id: true})
	check(falling.has(_m(p, "costumes").member_id), "its bottom gone, what's in it falls")


func test_the_screens_panels_are_printed_cloth_that_burns() -> void:
	var p := await _place(&"dressing_screen")
	for leaf in ["m", "l", "r"]:
		var panel := _m(p, "panel_" + leaf)
		check(not FireTuning.new().fireproof.has(panel.wood), "its %s panel burns" % leaf)
		check(panel.drawn_node().material_override == PropModels.pbr("screen_cloth"), "its %s panel is the printed cretonne" % leaf)
	var wing := _m(p, "panel_r")
	check(wing.global_position.z > 0.05, "the wings fold forward (%s)" % wing.global_position)
	# The cloth is tacked all round its frame; a wing hangs on its hinges from the middle leaf: its own
	# stiles and the middle's stile at its hinges gone, its rails and cloth come down.
	var gone := {_m(p, "stile_la").member_id: true, _m(p, "stile_lb").member_id: true, _m(p, "stile_ma").member_id: true}
	var falling := p.members_without_load_path(gone)
	check(falling.has(_m(p, "panel_l").member_id) and falling.has(_m(p, "head_l").member_id), "a wing's stiles and hinges gone, its cloth comes down")
	check(not falling.has(_m(p, "panel_m").member_id), "the other leaves stand")


func test_the_footlight_stands_its_chimney_glows_and_a_ball_breaks_it() -> void:
	var lamp := PropKit.make(&"footlight") as GlassProp
	world.add_child(lamp)
	var light := OilLamp.new()
	light.name = "Light"
	light.show_mesh = false
	lamp.add_child(light)
	await physics_frames(GlassProp.SETTLE_FRAMES + 4)
	check(not lamp.loose and not lamp.broken, "it stands")
	check(float(lamp.definition.get("light_height", 0.0)) > 0.05, "its flame's height for its light")
	light.set_lit(true)
	var chimney := lamp._chimney_mesh()
	check(chimney != null and float(chimney.get_instance_shader_parameter(&"glow")) == 1.0, "lit, its chimney glows")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	var r: RevolverTuning = load("res://config/revolver.tres")
	var at := lamp.global_position + Vector3.UP * 0.1
	ballistics.fire(at + Vector3(0, 0, -5), Vector3.BACK, r.muzzle_velocity, r.bullet_mass, r.bullet_diameter)
	await physics_frames(3)
	check(lamp.broken, "a ball breaks it")
