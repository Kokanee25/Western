class_name ValleyWorld
extends Node3D
## The new valley's scene (scenes/valley.tscn; docs/briefs/valley-plan.md §12, G1), loaded instead
## of the old town's street when `Settings.world` is `valley` (main.gd makes the swap). For now it's
## empty: the sky, the sun and moon on the town's day (config/day_cycle.tres: the sun sets due west,
## straight down Main Street, heading 270), a flat placeholder ground the size of the playable
## envelope from config/valley.json (ValleyLayout), the shot's systems (ballistics, impacts,
## traces) and the player at the crossroads looking down Main Street. No TownLife, gang, farmhouse
## or labs: they need the old town. G2 puts the baked height-map ground in the placeholder's place.

## The placeholder ground's slab (its top at Y 0, the crossroads' ground).
const SLAB := 2.0
const GROUND_COLOUR := Color(0.62, 0.52, 0.40)

var layout: ValleyLayout


func _ready() -> void:
	if layout == null:
		layout = ValleyLayout.main()
	_make_ground()
	var player := get_node_or_null(^"Player") as Node3D
	if player:
		player.transform = start_transform(layout)


## Where the player starts: on the crossroads' ground, facing down Main Street (west).
static func start_transform(l: ValleyLayout) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw_of(l.main_street_heading())), l.crossroads())


## A compass heading (0 north, -Z; 90 east, +X) as a turn round +Y from facing -Z.
static func yaw_of(heading_deg: float) -> float:
	return -deg_to_rad(heading_deg)


## The flat placeholder: one slab the envelope's size, drawn as a plain sandy plane.
func _make_ground() -> void:
	var env := layout.envelope()
	var centre := env.get_center()
	var body := StaticBody3D.new()
	body.name = "FlatGround"
	body.collision_layer = Layers.WORLD
	body.set_meta(&"surface", &"ground")
	body.position = Vector3(centre.x, 0.0, centre.y)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(env.size.x, SLAB, env.size.y)
	shape.shape = box
	shape.position = Vector3(0.0, -SLAB * 0.5, 0.0)
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var plane := PlaneMesh.new()
	plane.size = env.size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GROUND_COLOUR
	mat.roughness = 1.0
	plane.material = mat
	mesh.mesh = plane
	body.add_child(mesh)
	add_child(body)
