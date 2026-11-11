class_name RollingLog
extends RigidBody3D
## A felled log as a heavy rigid body (the coach heist's, issue #770, Sean's 1B on #784: green
## ponderosa pine, 0.6 m across, 6 m long, ~1.25 t): a cylinder along its own x, its mass from its
## size and its wood (TimberTuning). It lies held (frozen) until the last of its holds breaks: the
## members of a deck that a ball or a charge breaks (wedges, a chain's toggle pin; `hold_by`).
## Then it rolls. What it strikes that dents (Dents, DentWatch) dents in a trough along it.

signal released

@export var radius := 0.3
@export var length := 6.0
@export var wood := &"green_pine"
## Its bark's grip and give.
@export var friction := 0.9
@export var bounce := 0.05

var _holds := {}  ## member id -> true while it stands
var held := false


func _init() -> void:
	name = "RollingLog"


func _ready() -> void:
	build()


## Its shape, mesh and mass from its size and wood.
func build() -> void:
	for c in get_children():
		if c is CollisionShape3D or c is MeshInstance3D:
			c.queue_free()
	collision_layer = Layers.WORLD
	collision_mask = Layers.WORLD | Layers.DEBRIS | Layers.BODY_PARTS | Layers.PEOPLE
	var density := float(StructuralAnalysis.load_tuning().wood(wood).get("density", 740.0))
	mass = PI * radius * radius * length * density
	continuous_cd = true
	var mat := PhysicsMaterial.new()
	mat.friction = friction
	mat.bounce = bounce
	physics_material_override = mat
	# A rolling log on dirt loses little to the air: no damping beyond the bark's grip.
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	angular_damp = 0.02
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = length
	cs.shape = cyl
	cs.transform = Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3.ZERO)
	add_child(cs)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = length
	cm.radial_segments = 14
	mi.mesh = cm
	mi.transform = cs.transform
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.36, 0.27, 0.19)
	bark.roughness = 0.95
	mi.material_override = bark
	add_child(mi)
	set_meta(&"dent_radius", radius * 0.6)
	set_meta(&"dent_length", length)


## Its axis in the world (what its trough in a plate runs along).
func dent_axis() -> Vector3:
	return global_basis.x.normalized()


## Held by these members of `s` (ids within it, or full) until every one has broken.
func hold_by(s: Structure, ids: Array) -> void:
	_holds.clear()
	for id in ids:
		var full := StringName(id) if String(id).contains("/") else StringName("%s/%s" % [s.structure_id, id])
		var m: StructureMember = s.members.get(full)
		if m and not m.broken:
			_holds[full] = true
	held = not _holds.is_empty()
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = held
	if not Events.member_broken.is_connected(_on_member_broken):
		Events.member_broken.connect(_on_member_broken)


func holds_left() -> int:
	return _holds.size()


func _on_member_broken(id: StringName) -> void:
	if not _holds.has(id):
		return
	_holds.erase(id)
	if _holds.is_empty() and held:
		release()


## Let go: it rolls.
func release() -> void:
	held = false
	_holds.clear()
	freeze = false
	sleeping = false
	released.emit()


## The speed it'd have rolling down `drop` metres without losses (a solid cylinder: a third of
## its energy goes into its spin): v = sqrt(4/3 g h).
static func rolling_speed(drop: float) -> float:
	return sqrt(4.0 / 3.0 * 9.81 * maxf(drop, 0.0))
