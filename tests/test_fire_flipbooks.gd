extends TestCase
## The simulated fire's flipbooks (the art session's FireFlipbook, docs/briefs/fire-look.md "The
## next approach"): the baked sheets are whole and loop, and with Settings.fire_flipbooks on a
## burning member's fire sheet is drawn with them (core, tips and haze), and back without.

var world: Node3D
var fire: FireSystem
var building: Structure


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	fire = FireSystem.new()
	world.add_child(fire)
	fire.set_physics_process(false)
	building = Structure.new()
	building.structure_id = &"shed"
	building.collapses = false
	world.add_child(building)
	await physics_frames(1)


func after_each() -> void:
	Settings.set_fire_flipbooks(true, false)  # the default since Sean kept them (2026-10-22)
	world.queue_free()
	await physics_frames(2)


func test_every_type_has_its_sheets_and_they_loop() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FireFlipbook.SHEETS))
	for kind: String in FireFlipbook.KINDS:
		check(meta.types.has(kind), "%s is baked" % kind)
		if not meta.types.has(kind):
			continue
		var t: Dictionary = meta.types[kind]
		var sheet: Texture2D = load("res://assets/textures/fire/fire_%s.png" % kind)
		var mv: Texture2D = load("res://assets/textures/fire/fire_%s_mv.png" % kind)
		check(sheet.get_width() == 8 * int(t.squares[0]) and sheet.get_height() == 8 * int(t.squares[1]),
				"%s: 64 frames of %s squares (%dx%d)" % [kind, t.squares, sheet.get_width(), sheet.get_height()])
		check(mv.get_size() == sheet.get_size(), "%s: its motion sheet matches" % kind)
		check(float(t.mv_range) > 0.0, "%s: it moves" % kind)
		# Frame 63 carried on by its motion misses frame 0 by no more than one step misses the next
		# by, give or take: the loop doesn't jump.
		check(float(t.seam_error) < float(t.step_error) * 2.0,
				"%s: the loop's seam (%.4f) is like a step (%.4f)" % [kind, t.seam_error, t.step_error])


func test_with_the_setting_on_a_burning_members_fire_is_drawn_from_the_flipbooks() -> void:
	var wall := building.add_member("wall", &"board", &"weathered_pine", Vector3(3.0, 2.4, 0.025), Vector3(0, 1.2, 0))
	building.infer_supports()
	fire.ignite(wall)
	Settings.set_fire_flipbooks(true, false)
	check(FireFX.flipbooks, "the setting reaches FireFX")
	var fx := FireFX.new()
	fx.member = wall
	fire.add_child(fx)
	fx.refresh(true, fire.tuning, true)
	var sheet: MeshInstance3D = null
	for e in fx._emitters:
		if e is MeshInstance3D and e.has_meta(&"flame"):
			sheet = e
	check(sheet != null, "it has a fire sheet")
	if sheet == null:
		return
	check(sheet.material_override == FireFlipbook.material(), "drawn from the flipbooks")
	var shaders := FireFlipbook.passes().map(func(m: ShaderMaterial) -> String: return m.shader.resource_path.get_file())
	check(shaders == ["flame_core.gdshader", "flame_tips.gdshader", "flame_haze.gdshader"], "core, tips, haze: %s" % [shaders])
	var prio := FireFlipbook.passes().map(func(m: ShaderMaterial) -> int: return m.render_priority)
	check(prio[2] < prio[0] and prio[0] < prio[1], "the haze drawn first, the tips last: %s" % [prio])
	Settings.set_fire_flipbooks(false, false)
	fx.refresh(true, fire.tuning, true)
	check(sheet.material_override != FireFlipbook.material() and sheet.material_override.shader == FireFX.SHEET,
			"off again, the drawn sheet on the next refresh")
