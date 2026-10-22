class_name Clod
extends RigidBody3D
## A clod of earth a crater threw (Blast.crater): it flies and tumbles as a small lump, and when it
## comes to rest on the dirt it lies down as loose earth there (Ground.put), so the street keeps the
## earth, saved and diggable, not a scatter of sleeping bodies. On anything else (a boardwalk, a
## roof) it stays, a lump held still.

## How long it may lie still before it settles, and how slow is still (m/s).
const REST_TIME := 0.5
const REST_SPEED := 0.15
## A clod that hasn't settled in this long (s) settles where it is.
const LIFE := 8.0

var bank := 0.0  # m³ of packed earth in it
var ground: Ground
var _still := 0.0
var _age := 0.0


static func throw(world: Node3D, g: Ground, at: Vector3, velocity: Vector3, m3: float, density: float) -> Clod:
	var c := Clod.new()
	c.name = "Clod"
	c.bank = m3
	c.ground = g
	var side := pow(maxf(m3, 1e-7), 1.0 / 3.0)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * side
	cs.shape = box
	c.add_child(cs)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	mi.mesh = mesh
	mi.material_override = g.material
	c.add_child(mi)
	c.mass = maxf(m3 * density, 0.01)
	c.collision_layer = Layers.DEBRIS
	c.collision_mask = Layers.WORLD | Layers.DEBRIS
	c.continuous_cd = true
	var pm := PhysicsMaterial.new()
	pm.friction = 0.9
	pm.bounce = 0.05
	pm.rough = true
	c.physics_material_override = pm
	c.add_to_group(&"clods")
	world.add_child(c)
	c.global_position = at
	c.linear_velocity = velocity
	c.angular_velocity = Vector3(velocity.z, 0.0, -velocity.x) * 2.0
	return c


func _physics_process(delta: float) -> void:
	_age += delta
	_still = _still + delta if linear_velocity.length() < REST_SPEED else 0.0
	if _still < REST_TIME and _age < LIFE:
		return
	if freeze:
		return
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.1, global_position + Vector3.DOWN * 0.4, Layers.WORLD, [get_rid()])
	var hit := space.intersect_ray(q)
	if is_instance_valid(ground) and not hit.is_empty() and Ground.is_ground(hit.collider):
		ground.put(hit.position, bank, maxf(pow(bank, 1.0 / 3.0) * 1.5, ground.tuning.cell * 2.5))
		queue_free()
	else:
		freeze = true
