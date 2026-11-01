extends Node
## The D check's body (d_checks.gd runs it: loaded at run time, after the game's autoloads).

const GAME_TESTS := {
	"test_wall_props": ["test_the_head_and_the_painting_hang_on_the_wall_as_big_as_the_drawn_ones",
			"test_the_board_its_nails_are_in_shot_out_it_falls",
			"test_a_stick_close_by_tears_the_head_off_its_nails_and_one_far_off_leaves_it"],
	"test_prop_factory": ["test_the_deer_head_is_drawn_from_its_mount"],
}

var opts := {}
var root: Window


func run(o: Dictionary) -> void:
	opts = o
	root = get_tree().root
	World.deterministic = true
	var settings := root.get_node_or_null(^"Settings")
	if settings:
		settings.autosave = false
		settings.reset_to_defaults()
	var DV: GDScript = load("res://experiments/prop_lab/deer_fidelity/deer_variants.gd")
	var dv = DV.new(opts.get("dir", ""))
	var out: String = opts.get("out", "build/deer_fidelity/d_checks")
	DirAccess.make_dir_recursive_absolute(out)
	var results := {}
	for version: String in String(opts.get("versions", "game,C7")).split(","):
		DV.restore()
		if version != "game":
			dv.use_in_kit(version)
		var r := {"tests": {}}
		for file: String in GAME_TESTS:
			var script := load("res://tests/%s.gd" % file) as GDScript
			var case: TestCase = script.new()
			root.add_child(case)
			for method: String in GAME_TESTS[file]:
				case.current_test = "%s::%s" % [file, method]
				case.failures.clear()
				await case.before_each()
				await case.call(method)
				await case.after_each()
				r.tests[case.current_test] = "ok" if case.failures.is_empty() else "; ".join(case.failures)
			case.queue_free()
			await get_tree().process_frame
		r["drawn"] = await _drawn()
		r["shot"] = await _shot()
		r["falls"] = await _falls()
		r["burns"] = await _burns()
		results[version] = r
		print(version, " ", JSON.stringify(r))
	DV.restore()
	var f := FileAccess.open(out.path_join("d_checks.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(results, "  "))


## A board wall to hang it on, as tests/test_wall_props.gd's (its face at z = 0), a floor under it.
func _wall() -> Array:
	var world := Node3D.new()
	root.add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	var wall := Structure.new()
	wall.structure_id = &"wall"
	world.add_child(wall)
	for x in [-1.2, -0.6, 0.0, 0.6, 1.2]:
		wall.add_member("stud%d" % int(x * 10), &"stud", &"framing", Vector3(0.05, 3.0, 0.1), Vector3(x, 1.5, -0.07))
	for i in 20:
		wall.add_member("board%d" % i, &"board", &"framing", Vector3(2.6, 0.15, 0.02), Vector3(0, 0.075 + 0.15 * i, -0.01))
	wall.infer_supports()
	var t0 := Time.get_ticks_usec()
	var head := PropKit.make(&"deer_head") as KitProp
	head.position = Vector3(0, 2.0, 0)
	world.add_child(head)
	head.set_meta(&"made_ms", (Time.get_ticks_usec() - t0) / 1000.0)
	for i in KitProp.SETTLE_FRAMES + 3:
		await get_tree().physics_frame
	return [world, wall, head]


func _done(world: Node3D) -> void:
	world.queue_free()
	for i in 2:
		await get_tree().physics_frame


func _member(head: KitProp, part: String) -> StructureMember:
	return head.get_member(StringName("%s/%s" % [head.structure_id, part]))


## How it's drawn once hung: its members' meshes (triangles), the material class, the batches.
func _drawn() -> Dictionary:
	var w: Array = await _wall()
	var head: KitProp = w[2]
	var tris := 0
	var mat := ""
	for m in head.get_members():
		var mi := m.drawn_node()
		if mi and mi.mesh:
			tris += mi.mesh.get_faces().size() / 3
			mat = mi.material_override.get_class() if mi.material_override else "none"
	# Its frame, hung and at rest (headless: the tick, no drawing), 300 physics frames.
	var t0 := Time.get_ticks_usec()
	for i in 300:
		await get_tree().physics_frame
	var frame_ms := (Time.get_ticks_usec() - t0) / 300000.0
	var out := {"hung": head.hung(), "loose": head.loose, "members": head.member_count(), "triangles": tris,
			"material": mat, "batches": head.batch_count(), "kg": snappedf(head.mass(), 0.01), "frame_ms": snappedf(frame_ms, 0.001),
			"made_ms": snappedf(float(head.get_meta(&"made_ms")), 0.1)}
	await _done(w[0])
	return out


## A revolver ball at the head and one at the neck, from 5 m: what it hit and what it did.
func _shot() -> Dictionary:
	var w: Array = await _wall()
	var head: KitProp = w[2]
	var ballistics := Ballistics.new()
	(w[0] as Node3D).add_child(ballistics)
	await get_tree().physics_frame
	var t: RevolverTuning = load("res://config/revolver.tres")
	var out := {}
	for part: String in ["head", "neck", "plaque"]:
		var m := _member(head, part)
		var before := m.section_left(head.tuning)
		var from := m.global_position + Vector3(0.05, 0.0, 5.0)
		var b := ballistics.fire(from, (m.global_position - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
		for i in 60:
			if not b.alive:
				break
			await get_tree().physics_frame
		for i in 3:
			await get_tree().physics_frame
		out[part] = {"section_left": [snappedf(before, 0.01), snappedf(m.section_left(head.tuning), 0.01)], "broken": m.broken}
	out["loose"] = head.loose
	await _done(w[0])
	return out


## The boards its nails are in broken: it falls; two seconds on, where it lies and what split.
func _falls() -> Dictionary:
	var w: Array = await _wall()
	var head: KitProp = w[2]
	var wall: Structure = w[1]
	for m: StructureMember in head._feet:
		for e: Array in head._feet[m]:
			if e[0] != null:
				wall.break_member(e[0])
	for i in 120 + int(KitProp.CHECK_EVERY * 60.0):
		await get_tree().physics_frame
	var broken := 0
	var low := INF
	for m in head.get_members():
		broken += 1 if m.broken else 0
		low = minf(low, m.global_position.y)
	var out := {"loose": head.loose, "broken_members": broken, "lowest_member_y": snappedf(low, 0.01)}
	await _done(w[0])
	return out


## The neck lit (FireSystem): whether it catches, shows its char and burns away, in 4 minutes.
func _burns() -> Dictionary:
	var w: Array = await _wall()
	var head: KitProp = w[2]
	var fire := FireSystem.new()
	(w[0] as Node3D).add_child(fire)
	await get_tree().physics_frame
	var neck := _member(head, "neck")
	fire.ignite(neck)
	var charred := -1.0
	var gone := -1.0
	for i in 60 * 240:
		await get_tree().physics_frame
		if charred < 0.0 and head.has_fire_look(neck) and head.fire_look(neck).x > 0.3:
			charred = i / 60.0
		if neck.consumed or neck.broken:
			gone = i / 60.0
			break
	var out := {"charred_s": snappedf(charred, 0.1), "gone_s": snappedf(gone, 0.1), "loose": head.loose}
	await _done(w[0])
	return out
