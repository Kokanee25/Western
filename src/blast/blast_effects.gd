class_name BlastEffects
## What a blast looks like: a white flash that lights the street, a fireball, dirt thrown up, a big
## dirty cloud that hangs and drifts, a scorch on the ground, and the bang rolling off the hills.

static var _scorch_tex: Texture2D


static func spawn(world: Node3D, at: Vector3, kg: float) -> void:
	if world == null or not world.is_inside_tree():
		return
	var size := pow(kg / 0.15, 1.0 / 3.0)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.82, 0.55)
	light.light_energy = 16.0 * size
	light.omni_range = 22.0 * size
	world.add_child(light)
	light.global_position = at + Vector3.UP * 0.4
	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.35)
	tw.tween_callback(light.queue_free)
	# Fireball and dirt.
	ImpactEffects.burst(world, at, Vector3.UP, Color(1.0, 0.62, 0.22), int(30 * size), 7.0 * size, 0.12)
	ImpactEffects.burst(world, at, Vector3.UP, Color(1.0, 0.9, 0.6), int(14 * size), 4.0 * size, 0.16)
	ImpactEffects.burst(world, at, Vector3.UP, Color(0.5, 0.4, 0.3), int(50 * size), 10.0 * size, 0.05)
	GunSmoke.spawn(world, at + Vector3.UP * 0.3, Vector3.UP, 5.0 * size)
	_scorch(world, at, size)
	var p := AudioStreamPlayer3D.new()
	p.stream = SynthSounds.get_sound(&"dynamite")
	p.unit_size = 40.0
	p.max_db = 6.0
	world.add_child(p)
	p.global_position = at
	p.play()
	p.finished.connect(p.queue_free)


## A black scorch on whatever's below (it stays, like blood and bullet holes).
static func _scorch(world: Node3D, at: Vector3, size: float) -> void:
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.2, at + Vector3.DOWN * 1.5, Layers.WORLD)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	if _scorch_tex == null:
		_scorch_tex = PixelArt.blood("scorch", 41, false, 32)
	var d := Decal.new()
	d.name = "Scorch"
	d.texture_albedo = _scorch_tex
	d.modulate = Color(0.1, 0.08, 0.06, 0.8)
	d.size = Vector3(1.2, 0.6, 1.2) * size
	d.cull_mask = 1
	d.add_to_group(&"scorch_marks")
	world.add_child(d)
	d.global_position = hit.position
