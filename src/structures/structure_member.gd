class_name StructureMember
extends StaticBody3D
## One real piece of a building: a sill, post, stud, plate, rafter, board... The M3 structure
## system breaks, burns and drops these individually, so each has a stable ID, a kind, a wood
## and the IDs of the members it rests on (its supports).

## A member can only rest on members of a lower tier. Grounded kinds (tier <= 1) can also rest
## on the ground itself.
const TIERS := {
	&"sill": 0,
	&"post": 1,
	&"joist": 1,
	&"stud": 2,
	&"floor_board": 2,
	&"plate": 3,
	&"beam": 3,
	&"header": 3,
	&"ledger": 3,
	&"furniture_frame": 3,
	&"rafter": 4,
	&"cripple": 4,
	&"board": 5,
	&"roof_board": 5,
	&"ridge": 5,
	&"furniture_top": 5,
	&"trim": 6,
	&"glass": 6,
	&"door": 6,
}

@export var member_id: StringName
@export var kind: StringName
@export var wood: StringName
@export var size := Vector3.ONE

var supported_by: Array[StringName] = []
var grounded := false
## Bullet holes, in member space: {entry: Vector3, exit: Vector3, through: bool, radius: float}.
## Kept for saving (the difference from the authored town) and drawn by member_holes.gdshader.
var holes: Array[Dictionary] = []
## Broken members are gone from the world (a shattered pane). Saved.
var broken := false

const MAX_DRAWN_HOLES := 16
const HOLE_SHADER := preload("res://src/structures/member_holes.gdshader")


static func tier_of(member_kind: StringName) -> int:
	return TIERS.get(member_kind, 5)


## Bounds in the owning structure's space.
func structure_aabb() -> AABB:
	return transform * AABB(-size * 0.5, size)


## How far a straight line entering this member at `entry` (world) along `direction` travels
## inside it before coming out the other side.
func exit_distance(entry: Vector3, direction: Vector3) -> float:
	var inv := global_transform.affine_inverse()
	var p := inv * entry
	var d := (inv.basis * direction).normalized()
	var h := size * 0.5
	var t_exit := INF
	for a in 3:
		if absf(d[a]) > 1e-6:
			var bound := h[a] if d[a] > 0.0 else -h[a]
			t_exit = minf(t_exit, (bound - p[a]) / d[a])
	return maxf(t_exit, 0.0)


## Record a bullet hole. `exit` is where it came out (world), or null if it stopped inside.
func add_hole(entry: Vector3, exit: Variant, radius: float) -> void:
	var inv := global_transform.affine_inverse()
	var local_entry := inv * entry
	var through := exit != null
	var local_exit: Vector3 = inv * (exit as Vector3) if through else local_entry
	holes.append({"entry": local_entry, "exit": local_exit, "through": through, "radius": radius})
	_draw_holes()


func _draw_holes() -> void:
	var mi := get_child(0) as MeshInstance3D
	if mi == null:
		return
	var mat := mi.material_override as ShaderMaterial
	if mat == null or mat.shader != HOLE_SHADER:
		var base := mi.material_override as StandardMaterial3D
		if base == null or base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			return  # only opaque timber gets drawn holes
		mat = ShaderMaterial.new()
		mat.shader = HOLE_SHADER
		mat.set_shader_parameter(&"albedo_tex", base.albedo_texture)
		mat.set_shader_parameter(&"tint", base.albedo_color)
		mat.set_shader_parameter(&"uv_offset", Vector2(base.uv1_offset.x, base.uv1_offset.y))
		PixelArt.track_hole_material(mat)
		mi.material_override = mat
	var a := PackedVector4Array()
	var b := PackedVector4Array()
	var first := maxi(0, holes.size() - MAX_DRAWN_HOLES)
	for i in range(first, holes.size()):
		var h: Dictionary = holes[i]
		var e: Vector3 = h.entry
		var x: Vector3 = h.exit
		a.append(Vector4(e.x, e.y, e.z, h.radius))
		b.append(Vector4(x.x, x.y, x.z, 1.0 if h.through else 0.0))
	while a.size() < MAX_DRAWN_HOLES:
		a.append(Vector4.ZERO)
		b.append(Vector4.ZERO)
	mat.set_shader_parameter(&"hole_count", mini(holes.size(), MAX_DRAWN_HOLES))
	mat.set_shader_parameter(&"hole_a", a)
	mat.set_shader_parameter(&"hole_b", b)


## Glass: the pane breaks into shards that fall (and stay), with the sound of it. The member is
## then broken: no longer drawn or solid.
func shatter(at: Vector3, direction: Vector3, seed := 0) -> void:
	if broken:
		return
	broken = true
	var mi := get_child(0) as MeshInstance3D
	var cs := get_child(1) as CollisionShape3D
	if mi:
		mi.visible = false
	if cs:
		cs.set_deferred(&"disabled", true)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(member_id) + seed
	var host := get_parent().get_parent() if get_parent() and get_parent().get_parent() else get_parent()
	var local_hit := global_transform.affine_inverse() * at
	var count := clampi(int(size.x * size.y * 30.0), 8, 26)
	for i in count:
		var shard := RigidBody3D.new()
		shard.name = "GlassShard"
		shard.mass = 0.04
		shard.add_to_group(&"glass_shards")
		var w := rng.randf_range(0.03, 0.12)
		var h := rng.randf_range(0.03, 0.14)
		var t := maxf(size.z, 0.004)
		var cshape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(w, h, t)
		cshape.shape = box
		shard.add_child(cshape)
		var smi := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(w, h, t)
		smi.mesh = mesh
		smi.material_override = WoodMaterials.glass()
		smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shard.add_child(smi)
		host.add_child(shard)
		var local := Vector3(rng.randf_range(-0.5, 0.5) * size.x, rng.randf_range(-0.5, 0.5) * size.y, 0.0)
		shard.global_transform = Transform3D(global_transform.basis.rotated(global_transform.basis.z, rng.randf() * TAU), global_transform * local)
		# Pieces near the hit fly with the bullet; the rest mostly drop.
		var near := 1.0 - clampf(local.distance_to(Vector3(local_hit.x, local_hit.y, 0.0)) / maxf(size.x, 0.1), 0.0, 1.0)
		shard.linear_velocity = direction * rng.randf_range(0.5, 3.0) * near + Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.2, 0.6), rng.randf_range(-0.4, 0.4))
		shard.angular_velocity = Vector3(rng.randf_range(-8, 8), rng.randf_range(-8, 8), rng.randf_range(-8, 8))
	var snd := AudioStreamPlayer3D.new()
	snd.stream = SynthSounds.get_sound(&"glass")
	snd.unit_size = 6.0
	host.add_child(snd)
	snd.global_position = at
	snd.play()
	snd.finished.connect(snd.queue_free)
	Events.member_broken.emit(member_id)


func to_dict() -> Dictionary:
	return {
		"broken": broken,
		"holes": holes.map(func(h: Dictionary) -> Dictionary: return {
				"entry": [h.entry.x, h.entry.y, h.entry.z], "exit": [h.exit.x, h.exit.y, h.exit.z],
				"through": h.through, "radius": h.radius}),
		"id": String(member_id),
		"kind": String(kind),
		"wood": String(wood),
		"size": [size.x, size.y, size.z],
		"supported_by": supported_by.map(func(s: StringName) -> String: return String(s)),
	}
