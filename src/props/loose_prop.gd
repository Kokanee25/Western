class_name LooseProp
extends GlassProp
## A small rigid prop that doesn't break (docs/briefs/prop-lab.md, the kit's third kind, "loose"):
## a brass spittoon, a tin cup. It stands as a prop that shatters does (GlassProp: its model drawn
## batched over a frozen body, on what's under it, taken down when its table goes over, thrown by
## a blast), but what would shatter glass knocks it about instead:
## - **a ball:** goes through its thin metal (a hole at each side it passes, Ballistics'
##   `ballistic_thickness`), knocks it with the momentum the ball lost doing it, and dents it round
##   the hole;
## - **a kick** (`take_blow`): the boot and it move on together (an inelastic knock), dented where
##   the boot landed;
## - **landing or struck hard** (past `breaks_at`, its "dents_at"): dented where it struck.
## Its body is a cylinder, so knocked over it rolls. Tipped past `spills_below` (its up's height),
## or holed under what it holds, it lets that go on the floor (GlassProp's way). Metal: it doesn't
## burn (no heat rule).

## Holes drawn on it, at most; dents are the model's own vertices pushed in.
const MAX_MARKS := 12

var dents := 0
var holes := 0
var spilt := false

var _marks := 0


func _ready() -> void:
	super._ready()
	# Rolling, the boards and its dents slow it (the physics has no rolling resistance of its own).
	body.angular_damp = float(definition.get("roll_damp", 1.5))
	add_to_group(&"loose_props")
	remove_from_group(&"glass_props")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if loose and not spilt and body.global_basis.y.y < float(definition.get("spills_below", 0.3)):
		_spill()


## Metal doesn't crack in the flames.
func _heat(_dt: float) -> void:
	pass


## A ball through it (or into it): knocked, holed where it went in and out, dented round them.
func _on_bullet_hit(info: Dictionary) -> void:
	if info.get("collider") != body:
		return
	var at: Vector3 = info.get("position", body.global_position)
	var dir: Vector3 = (info.get("direction", Vector3.DOWN) as Vector3).normalized()
	# What it's knocked by is the momentum the ball lost in it (a ball through thin metal keeps most
	# of its own; one that stops in it gives it all).
	var kg := float(info.get("mass", 0.0))
	var lost := sqrt(2.0 * kg * float(info.get("energy_before", 0.0))) - sqrt(2.0 * kg * float(info.get("energy_after", 0.0)))
	if not loose:
		wake()
	body.apply_impulse(dir * maxf(lost, 0.0), at - body.global_position)
	var r := float(definition.get("hole_radius", 0.006))
	if info.get("penetrated", false):
		_hole(at, dir)
		var out := _far_side(at, dir)
		if out != Vector3.INF:
			_hole(out, dir)
		if _below_contents(at) or _below_contents(out):
			_spill()
	dent(at, dir, r * 4.0, float(definition.get("dent", {}).get("shot", 0.006)))


## A boot (or a shove) of `impulse` (N·s) at `at`, from something of `blow_mass` kg: the two move on
## together, and it's dented where the boot landed. &"moved" (it always goes).
func take_blow(at: Vector3, impulse: Vector3, blow_mass := 8.0) -> StringName:
	if broken:
		return &"held"
	var v := impulse / (blow_mass + body.mass)
	if not loose:
		wake(v)
	else:
		body.linear_velocity += v
	# Struck above or below its middle it turns as well: the momentum it took, about its middle,
	# over its inertia as a solid cylinder's across its axis, m(3r² + h²)/12. (Set, not an impulse:
	# one given in the frame it's woken is lost.)
	var cs := body.get_child(0) as CollisionShape3D
	var mid := cs.global_position if cs else body.global_position
	var cyl := cs.shape as CylinderShape3D if cs else null
	var r := cyl.radius if cyl else 0.1
	var h := cyl.height if cyl else 0.2
	var inertia := body.mass * (3.0 * r * r + h * h) / 12.0
	body.angular_velocity += (at - mid).cross(v * body.mass) / maxf(inertia, 1e-5)
	var d: Dictionary = definition.get("dent", {})
	dent(at, impulse.normalized(), float(d.get("radius", 0.04)), float(d.get("kick", 0.008)))
	return &"moved"


## What would shatter glass (a hard landing, something striking it) dents it where it struck.
func shatter(at: Vector3, direction: Vector3, _shot := false) -> void:
	if not loose:
		wake()
	var d: Dictionary = definition.get("dent", {})
	var centre := body.global_position
	var r := maxf(PropKit.vec(definition.get("size", [0.1, 0.1, 0.1])).x * 0.5, 0.02)
	var hit_at := centre + direction.normalized() * r if direction.length() > 0.01 else at
	dent(hit_at, direction, float(d.get("radius", 0.04)), float(d.get("fall", 0.005)))


## The model's surface pushed in `depth` (m) along `dir` round `at` (world), `radius` across.
func dent(at: Vector3, dir: Vector3, radius: float, depth: float) -> void:
	if depth <= 0.0 or dir.length() < 1e-4:
		return
	dents += 1
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.name.begins_with("Mark"):
			continue
		var inv := mi.global_transform.affine_inverse()
		var local := inv * at
		var push := (inv.basis * dir).normalized() * depth / maxf(mi.global_basis.get_scale().x, 1e-4)
		var r := radius / maxf(mi.global_basis.get_scale().x, 1e-4)
		if mi.get_aabb().grow(r).has_point(local):
			mi.mesh = _dented(mi.mesh, local, push, r)


## A copy of `mesh` (the model's meshes are shared between props) with the vertices within `r` of
## `at` moved by `push`, most at the middle, none at the edge (a smooth dish); flat faces' normals
## follow.
static func _dented(mesh: Mesh, at: Vector3, push: Vector3, r: float) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var moved := false
		for i in verts.size():
			var d := verts[i].distance_to(at)
			if d < r:
				var k := 1.0 - (d * d) / (r * r)
				verts[i] += push * k * k
				moved = true
		if moved:
			arrays[Mesh.ARRAY_VERTEX] = verts
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			if idx.is_empty() and arrays[Mesh.ARRAY_NORMAL] != null:
				# Flat-shaded (each face its own three vertices): each face's normal again.
				var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				for f in range(0, verts.size() - 2, 3):
					var fn := (verts[f + 2] - verts[f]).cross(verts[f + 1] - verts[f])
					if fn.length() > 1e-10:
						fn = fn.normalized()
						if fn.dot(n[f]) < 0.0:
							fn = -fn
						n[f] = fn
						n[f + 1] = fn
						n[f + 2] = fn
				arrays[Mesh.ARRAY_NORMAL] = n
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(s, mesh.surface_get_material(s))
	return out


## A hole drawn where a ball went through (a dark spot on its face, going where it goes).
func _hole(at: Vector3, dir: Vector3) -> void:
	holes += 1
	if _marks >= MAX_MARKS:
		return
	_marks += 1
	var mark := MeshInstance3D.new()
	mark.name = "Mark%d" % _marks
	var q := QuadMesh.new()
	var d := float(definition.get("hole_radius", 0.006)) * 2.0
	q.size = Vector2(d, d)
	mark.mesh = q
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.03, 0.02)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mark.material_override = mat
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	model.add_child(mark)
	var face := -dir if dir.length() > 0.01 else Vector3.FORWARD
	mark.global_transform = Transform3D(Basis.looking_at(face, Vector3.UP if absf(face.y) < 0.95 else Vector3.RIGHT), at - dir * 0.001)
	mark.scale = Vector3.ONE / maxf(model.global_basis.get_scale().x, 1e-4)


## Where a line through it going `dir` from `at` comes out of its body's shape (world), or INF.
func _far_side(at: Vector3, dir: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(at + dir, at - dir * 0.001, Layers.DEBRIS)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position if not hit.is_empty() and hit.collider == body else Vector3.INF


## Holed under what it holds (its contents' "level": the share of its height they stand to).
func _below_contents(p: Vector3) -> bool:
	if p == Vector3.INF or spilt:
		return false
	var c: Dictionary = definition.get("contents", {})
	if float(c.get("litres", 0.0)) <= 0.0:
		return false
	var local := body.global_transform.affine_inverse() * p
	var h := PropKit.vec(definition.get("size", [0.1, 0.1, 0.1])).y
	return local.y < h * float(c.get("level", 0.5))


func _spill() -> void:
	if spilt:
		return
	spilt = true
	var host: Node = get_parent() if get_parent() else self
	_let_go(host, body.global_position + Vector3.UP * 0.02)
