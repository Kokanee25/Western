class_name ImpactEffects
extends Node3D
## Listens for bullet hits and throws the right debris: wood splinters (both sides when the board
## was shot through), dust off the ground, a spark off metal. Muzzle flashes live here too.

static var _mats := {}


func _ready() -> void:
	Events.bullet_hit.connect(_on_hit)
	Events.near_miss.connect(_on_near_miss)


## A ball going past your ear, heard from where it went by (only the listener's own near misses
## are worth playing): faster than sound it cracks like a whip (shotgun pellets, rifle balls);
## slower (a revolver's black-powder ball, ~240 m/s) it's a vicious hissing whip of air.
const SPEED_OF_SOUND := 343.0


func _on_near_miss(person: Node, _shooter: Node, distance: float, at: Vector3, speed: float) -> void:
	if person.is_in_group(&"player") and person is Node3D:
		_play_at(sound_for_pass(speed), at, 2.0 - distance * 4.0, 2.0)


static func sound_for_pass(speed: float) -> StringName:
	return &"crack" if speed >= SPEED_OF_SOUND else &"zip"


func _play_at(id: StringName, at: Vector3, db := 0.0, unit_size := 6.0) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = SynthSounds.get_sound(id)
	p.volume_db = db
	p.unit_size = unit_size
	add_child(p)
	p.global_position = at
	p.play()
	p.finished.connect(p.queue_free)


func _on_hit(info: Dictionary) -> void:
	var pos: Vector3 = info.position
	var normal: Vector3 = info.normal
	if info.has("person"):
		_play_at(&"flesh", pos, -2.0)
		# A spray of blood: a little back out of the entry, more out of an exit.
		burst(self, pos, -(info.direction as Vector3), Color(0.42, 0.04, 0.03), 5, 1.2, 0.02)
		if info.penetrated:
			var dir: Vector3 = info.direction
			burst(self, pos + dir * 0.05, dir, Color(0.4, 0.03, 0.03), 12, 2.5, 0.025)
		return
	if info.collider is StructureMember and (info.collider as StructureMember).kind == &"glass":
		return  # the pane's own shards are the debris
	if info.collider is StructureMember:
		burst(self, pos, normal, Color(0.62, 0.5, 0.36), 10, 2.5, 0.045)
		if info.penetrated:
			var dir: Vector3 = info.direction
			burst(self, pos + dir * 0.03, dir, Color(0.66, 0.54, 0.38), 8, 3.0, 0.04)
	elif info.collider is RigidBody3D:
		burst(self, pos, normal, Color(0.75, 0.72, 0.65), 4, 2.0, 0.025)
	else:
		burst(self, pos, normal, Color(0.62, 0.5, 0.37), 14, 1.8, 0.07)


## A one-shot burst of chunky bits flying off `normal`, falling under gravity.
static func burst(parent: Node, at: Vector3, normal: Vector3, color: Color, count: int, speed: float, size: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.one_shot = true
	p.amount = count
	p.lifetime = 1.4
	p.explosiveness = 1.0
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = normal
	pm.spread = 55.0
	pm.initial_velocity_min = speed * 0.4
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, -9.8, 0)
	pm.damping_min = 1.0
	pm.damping_max = 2.0
	pm.color = color
	p.process_material = pm
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * size
	mesh.material = _mat(color)
	p.draw_pass_1 = mesh
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


## The flash at the muzzle: a burst of hot light for a few frames and a bright blob.
static func muzzle_flash(parent: Node, at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.72, 0.4)
	light.light_energy = 7.0
	light.omni_range = 9.0
	light.shadow_enabled = false
	parent.add_child(light)
	light.global_position = at
	var flash := flash_mesh()
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(flash)
	flash.global_position = at
	var tree := parent.get_tree()
	tree.create_timer(0.05).timeout.connect(flash.queue_free)
	tree.create_timer(0.07).timeout.connect(light.queue_free)


static var _flash_material: StandardMaterial3D


static func flash_mesh() -> MeshInstance3D:
	if _flash_material == null:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = PixelArt.puff("flash", 103)
		m.albedo_color = Color(1.0, 0.85, 0.5)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_flash_material = m
	var flash := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	quad.material = _flash_material
	flash.mesh = quad
	return flash


## A spent case dropped out of the gate: real brass that lands and stays (evidence).
## A spent case (a .45's by default; a shotgun's brass shell is bigger) thrown from `at`.
static func spent_case(parent: Node, at: Vector3, push: Vector3, radius := 0.006, length := 0.032, mass := 0.012) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = "SpentCase"
	body.mass = mass
	body.add_to_group(&"spent_cases")
	body.collision_layer = Layers.DEBRIS
	body.collision_mask = Layers.DEBRIS_MASK
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = length
	shape.shape = cyl
	body.add_child(shape)
	GunParts.tube(body, "Brass", radius, length, Vector3.ZERO, GunParts.brass(), 8, Vector3.ZERO)
	parent.add_child(body)
	body.global_position = at
	body.linear_velocity = push
	body.angular_velocity = Vector3(randf_range(-10, 10), randf_range(-10, 10), randf_range(-10, 10))
	return body


## A piece of smashed bone (rib, skull) thrown out of a destroyed wound. It stays where it lands.
static func bone_fragment(parent: Node, at: Vector3, velocity: Vector3, rng: RandomNumberGenerator) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = "BoneFragment"
	body.mass = 0.006
	body.add_to_group(&"bone_fragments")
	body.collision_layer = Layers.DEBRIS
	body.collision_mask = Layers.DEBRIS_MASK
	var size := Vector3(rng.randf_range(0.008, 0.014), rng.randf_range(0.005, 0.009), rng.randf_range(0.014, 0.032))
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var bloody := rng.randf() < 0.45
	GunParts.box(body, "Bone", size, Vector3.ZERO, BodyInterior.material(&"flesh" if bloody else &"bone"))
	if bloody:
		# A bloody one: bone showing at one end.
		GunParts.box(body, "End", Vector3(size.x * 1.05, size.y * 1.05, size.z * 0.4), Vector3(0, 0, size.z * 0.3), BodyInterior.material(&"bone"))
	parent.add_child(body)
	body.global_position = at
	body.global_rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, 0.0)
	body.linear_velocity = velocity
	body.angular_velocity = Vector3(rng.randf_range(-15, 15), rng.randf_range(-15, 15), rng.randf_range(-15, 15))
	return body


static func _mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 1.0
		_mats[key] = m
	return _mats[key]
