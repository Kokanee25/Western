class_name BlastEffects
## What a blast looks like: the flash, the dust jet, cloud and surge and the chunks it throws
## (BlastCloud, after the blasting footage in docs/briefs/blast-look.md: dust and debris, next to no
## fire), a scorch on the ground, and the bang rolling off the hills.

static var _scorch_tex: Texture2D


static func spawn(world: Node3D, at: Vector3, kg: float) -> void:
	if world == null or not world.is_inside_tree():
		return
	var size := pow(kg / 0.15, 1.0 / 3.0)
	BlastCloud.spawn(world, at, kg)
	_scorch(world, at, size)
	if GameAudio.enabled():
		GameAudio.blast(world, at, kg)
		return
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
	var hit := World.space(world).intersect_ray(q)
	if hit.is_empty():
		return
	if _scorch_tex == null:
		_scorch_tex = PixelArt.blood("scorch", 41, false, 32)
	var d := Decal.new()
	d.name = "Scorch"
	d.texture_albedo = _scorch_tex
	d.modulate = Color(0.09, 0.075, 0.06, 0.85)
	d.size = Vector3(1.5, 0.6, 1.5) * size
	d.cull_mask = 1
	d.add_to_group(&"scorch_marks")
	world.add_child(d)
	d.global_position = hit.position
