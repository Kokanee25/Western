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

## Emitted when something damages the member (a bullet hole): the structure re-checks its loads.
signal damaged

## Weight resting on this member that isn't a member (goods on a shelf, a man on the porch), N.
@export var extra_load := 0.0

var supported_by: Array[StringName] = []
## Where it rests on each support (structure space), for how the load comes down.
var support_points := {}
## The contact region with each support (structure space AABB): a member lying along another
## bears on the whole length of it.
var support_boxes := {}
## Every member it touches, above or below (for what falls together, and rafter pairs).
var touching: Array[StringName] = []
var grounded := false
## Order supports come in: tier, then height (set by Structure.infer_supports).
var stack_key := 0.0
## What's drawn and solid for this member: [MeshInstance3D, CollisionShape3D] pairs. One while it
## stands; when it snaps, one per piece (they move into rubble but stay this member's).
var pieces: Array = []
## StructuralAnalysis's note of what doesn't change while it stands (axis, where it bears on its
## supports); not saved.
var analysis_cache := {}

# Fire (FireSystem runs it): degrees C, alight or not, how deep the char has gone from each face
# (m), how long it's been alight, and whether it's burnt away to nothing.
var temperature := 20.0
var burning := false
var char_depth := 0.0
var burn_time := 0.0
var consumed := false
## Litres of water soaked into it (a bucket thrown on it): while it's wet, heat goes into drying it
## and it gets no hotter than boiling (FireSystem._heat). Dries in the air and the heat.
var wet := 0.0
## Bullet holes, in member space: {entry: Vector3, exit: Vector3, through: bool, radius: float}.
## Kept for saving (the difference from the authored town) and drawn by member_holes.gdshader.
var holes: Array[Dictionary] = []
## Broken members are gone from the world (a shattered pane). Saved.
var broken := false

const MAX_DRAWN_HOLES := 16
const HOLE_SHADER := preload("res://src/structures/member_holes.gdshader")

## Its voxels (the native plugin's VoxelMember), made the first time it's hit when the plugin is
## here and voxel damage is on (config/voxel_damage.tres): holes are carved out of it, the carved
## mesh and collision built on the plugin's worker threads, and what's left of the section read
## from it. Null until then, and always where there's no plugin (holes are drawn by the shader).
var voxels: Object = null
## From the voxels: Vector2(share of the section left at its weakest place, where that is along
## its length); and the share of its wood still there.
var voxel_section := Vector2(1.0, 0.0):
	get:
		if _section_stale:
			_section_stale = false
			var depth := maxf(cross_section().x, cross_section().y)
			voxel_section = voxels.section(axis_index(), depth * voxel_damage_tuning().window_of_depth)
		return voxel_section
var solid_share := 1.0
## Carved since the section was last worked out (a charge's nine pellets: worked out once, when
## the structure next asks).
var _section_stale := false

static var voxel_tuning: VoxelDamageTuning
static var _fresh := {}
## Chips lying about, oldest first (untyped: a chip may be freed with its world).
static var _chips: Array = []


static func tier_of(member_kind: StringName) -> int:
	return TIERS.get(member_kind, 5)


# --- Geometry for the structural checks (structure space) --------------------------------------

func axis_index() -> int:
	var a := 0
	for i in 3:
		if size[i] > size[a]:
			a = i
	return a


## Unit vector along the member's length.
func axis() -> Vector3:
	return transform.basis[axis_index()].normalized()


func length() -> float:
	return size[axis_index()]


## Stands up (post, stud, upright board) rather than lies (beam, joist, rafter).
func is_upright() -> bool:
	return absf(axis().y) > 0.7


## Vector2(breadth, depth) of the cross-section, depth being the side nearest vertical (what
## resists bending under gravity).
func cross_section() -> Vector2:
	var ai := axis_index()
	var others: Array[int] = []
	for i in 3:
		if i != ai:
			others.append(i)
	var d0 := absf(transform.basis[others[0]].normalized().y)
	var d1 := absf(transform.basis[others[1]].normalized().y)
	var deep := others[0] if d0 >= d1 else others[1]
	var broad := others[1] if deep == others[0] else others[0]
	# Char has no strength: what's left is the sound wood inside it.
	var burnt := char_depth * 2.0
	return Vector2(maxf(size[broad] - burnt, 0.001), maxf(size[deep] - burnt, 0.001))


## Thinnest side of the sound wood left (m).
func thickness() -> float:
	var t := INF
	for i in 3:
		t = minf(t, size[i] - char_depth * 2.0)
	return maxf(t, 0.0)


func volume() -> float:
	return size.x * size.y * size.z


func weight(tuning: TimberTuning) -> float:
	if consumed:
		return 0.0
	var c := char_depth * 2.0
	var sound := maxf(size.x - c, 0.0) * maxf(size.y - c, 0.0) * maxf(size.z - c, 0.0) * solid_share
	# Char weighs about a fifth of the wood it was.
	return (sound + (volume() - sound) * 0.2) * float(tuning.wood(wood).density) * 9.81


## Where it is in the world now (it may be lying in the street as rubble).
func world_aabb() -> AABB:
	var box := AABB()
	var first := true
	for p: Array in pieces:
		# A piece that's burnt away is a freed object: check before casting (casting a freed
		# object is a script error, and fires asked this of every burning member, every tick).
		if not is_instance_valid(p[0]):
			continue
		var mi := p[0] as MeshInstance3D
		if mi == null or not mi.is_inside_tree():
			continue
		var b := mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first and is_inside_tree():
		box = get_parent_node_3d().global_transform * structure_aabb() if get_parent_node_3d() else AABB(global_position, Vector3.ZERO)
	return box


## Share of the section still there after bullet holes (1 = sound). Voxelised: the weakest
## place's solid share, what's gone counting `hole_weakening` times over as drawn holes do (the
## stress gathers round a notch).
func section_left(tuning: TimberTuning) -> float:
	if voxels != null:
		return clampf(1.0 - (1.0 - voxel_section.x) * tuning.hole_weakening, 0.02, 1.0)
	var ai := axis_index()
	var lost := 0.0
	for h in holes:
		var e: Vector3 = h.entry
		var x: Vector3 = h.exit
		var through := x - e
		# The hole's width comes out of the side it didn't go through. A blind hole went in
		# through the thin side.
		var others: Array[int] = []
		for i in 3:
			if i != ai:
				others.append(i)
		var across := others[0] if size[others[0]] <= size[others[1]] else others[1]
		if through.length() > 1e-5:
			across = others[0] if absf(through[others[0]]) >= absf(through[others[1]]) else others[1]
		var side := -1
		for i in 3:
			if i != ai and i != across:
				side = i
		var fraction: float = float(h.radius) * 2.0 * tuning.hole_weakening / maxf(size[side], 0.001)
		lost += fraction * (1.0 if h.through else 0.5)
	return clampf(1.0 - lost, 0.02, 1.0)


## Where along the member (t from its middle) it's weakest: its worst hole, else `default`.
func weakest_t(default := 0.0) -> float:
	if voxels != null:
		return voxel_section.y if voxel_section.x < 1.0 else default
	if holes.is_empty():
		return default
	var ai := axis_index()
	return float((holes[holes.size() - 1].entry as Vector3)[ai])


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
## Voxelised, it's carved: a channel of `radius` (a blind one is a pit at `entry`).
func add_hole(entry: Vector3, exit: Variant, radius: float) -> void:
	if _use_voxels():
		var to: Vector3 = exit if exit != null else entry
		carve_hit(entry, to, exit != null, (to - entry).normalized(), radius, 0.0, 0.0)
		return
	var inv := global_transform.affine_inverse()
	var local_entry := inv * entry
	var through := exit != null
	var local_exit: Vector3 = inv * (exit as Vector3) if through else local_entry
	holes.append({"entry": local_entry, "exit": local_exit, "through": through, "radius": radius})
	_draw_holes()
	damaged.emit()


func _draw_holes() -> void:
	if voxels != null:
		return  # carved for real
	var mi := get_child(0) as MeshInstance3D
	if mi == null:
		return
	var mat := mi.material_override as ShaderMaterial
	if mat == null:
		return  # only timber on the texel grid gets drawn holes (not glass)
	if not PixelArt.is_hole_shader(mat.shader):
		if not PixelArt.is_grid_shader(mat.shader):
			return
		mat = PixelArt.hole_material(mat)
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
	Events.noise.emit(at, 40.0, &"glass", null)
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
		shard.collision_layer = Layers.DEBRIS
		shard.collision_mask = Layers.DEBRIS_MASK
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
	# The shards cut whoever's close.
	var excl: Array[RID] = [get_rid()]
	GlassCuts.spray(host as Node3D if host is Node3D else null, at, direction, size.x * size.y, hash(member_id) + seed, excl)
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
				"through": h.through, "radius": h.radius, "spall": h.get("spall", 0.0)}),
		"id": String(member_id),
		"char": char_depth,
		"burning": burning,
		"consumed": consumed,
		"kind": String(kind),
		"wood": String(wood),
		"size": [size.x, size.y, size.z],
		"supported_by": supported_by.map(func(s: StringName) -> String: return String(s)),
	}


# --- Voxel damage (docs/DESTRUCTION_BRIEF.md step 2) -------------------------------------------

static func voxel_damage_tuning() -> VoxelDamageTuning:
	if voxel_tuning == null:
		voxel_tuning = load("res://config/voxel_damage.tres")
	return voxel_tuning


## The plugin's here and voxel damage is on.
static func voxels_available() -> bool:
	return voxel_damage_tuning().enabled and ClassDB.class_exists(&"VoxelMember")


## Carved rather than drawn: anything but glass, still standing where it was built (a broken
## member's pieces have gone their own way).
func _use_voxels() -> bool:
	if voxels != null:
		return not broken
	return kind != &"glass" and not broken and voxels_available()


func _make_voxels() -> bool:
	if voxels != null:
		return true
	if not _use_voxels():
		return false
	var t := voxel_damage_tuning()
	voxels = ClassDB.instantiate(&"VoxelMember")
	voxels.setup(size, t.cells_per_metre, t.max_voxels, wood == &"stone")
	return true


## The stretches of solid a line meets going through it from `from` (world) along `direction`:
## [enter, exit, ...] distances from `from`. Not voxelised, the box: [0, its exit].
func solid_runs(from: Vector3, direction: Vector3) -> PackedFloat32Array:
	var through := exit_distance(from, direction)
	if voxels == null:
		return PackedFloat32Array([0.0, through])
	var inv := global_transform.affine_inverse()
	return voxels.runs(inv * from, (inv.basis * direction).normalized(), through + 0.01)


## A projectile's hit (world): it went in at `entry` and came out (`through`) or stopped at `to`,
## `radius` its own, `joules` what it spent in the wood, `blast` the muzzle blast it brought.
## Voxelised: the channel, and the spall that energy tears out round it, carved now (in the order
## hits come, so a charge's pellets meet each other's holes); the mesh and collision follow from
## the worker threads; chips thrown. Not: a drawn hole, as before.
func carve_hit(entry: Vector3, to: Vector3, through: bool, direction: Vector3, radius: float, joules: float, blast: float) -> void:
	if not _make_voxels():
		add_hole(entry, to if through else null, radius)
		return
	var t := voxel_damage_tuning()
	var inv := global_transform.affine_inverse()
	var local_entry := inv * entry
	var local_to := inv * to
	var spall := (joules * t.spall_share + blast * t.blast_share) / t.spall_cost(wood) * 1e-6
	var seed := hash(member_id) + holes.size() * 7919
	holes.append({"entry": local_entry, "exit": local_to, "through": through, "radius": radius, "spall": spall})
	var removed: int = voxels.carve(local_entry, local_to, radius * t.channel_scale, spall, seed, t.ragged, t.flare,
			-1 if wood == &"stone" else axis_index(), t.grain_split, t.island_max, t.chips_per_hit)
	if removed > 0:
		_section_stale = true
		solid_share = float(voxels.solid()) / maxf(float(voxels.total()), 1.0)
		voxels.start_mesh()
		VoxelWorks.watch(self)
		_throw_chips(direction, seed)
	damaged.emit()


## The worker's mesh: drawn and solid as carved. The outside keeps the member's own material; the
## carved faces are fresh-cut wood.
func apply_voxel_mesh(m: Array) -> void:
	if m.size() < 3 or has_meta(&"snapped") or consumed or pieces.is_empty() or not is_instance_valid(pieces[0][0]):
		return
	var mi := pieces[0][0] as MeshInstance3D
	var mesh := ArrayMesh.new()
	if not (m[0] as Array).is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, m[0])
	mi.mesh = mesh
	var inner := mi.get_node_or_null(^"Carved") as MeshInstance3D
	if inner == null:
		inner = MeshInstance3D.new()
		inner.name = "Carved"
		inner.material_override = _fresh_material()
		mi.add_child(inner)
	var carved := ArrayMesh.new()
	if not (m[1] as Array).is_empty():
		carved.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, m[1])
	inner.mesh = carved
	# Standing, it's solid as carved (a channel lets a ball through); as rubble it keeps its box
	# (a moving body can't be a concave shape).
	if not broken and is_instance_valid(pieces[0][1]):
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(m[2])
		(pieces[0][1] as CollisionShape3D).shape = shape


func _fresh_material() -> Material:
	var key := wood
	if not _fresh.has(key):
		var t := voxel_damage_tuning()
		var stone := wood == &"stone"
		var base := t.fresh_stone if stone else t.fresh_wood
		if wood == &"dark_trim":
			base = base.darkened(0.25)
		var mat := PixelArt.material(_fresh_texture(base, not stone, hash(wood)))
		# Cube faces far smaller than a texel: light each where it is (texel_grid.gdshaderinc).
		mat.set_shader_parameter(&"cube_faces", true)
		_fresh[key] = mat
	return _fresh[key]


## Fresh-cut wood (or stone): a small tile of close shades, grain running along u for wood. Made
## here, small, at the first carve (PixelArt.wood paints a big one in script: ~25 ms, a hitch).
static func _fresh_texture(base: Color, grain: bool, seed: int) -> ImageTexture:
	var n := 16
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var rows := PackedFloat32Array()
	for y in n:
		rows.append(rng.randf_range(-1.0, 1.0))
	for y in n:
		for x in n:
			var v := rng.randf_range(-1.0, 1.0) * 0.35 + (rows[y] * 0.65 if grain else rng.randf_range(-1.0, 1.0) * 0.65)
			img.set_pixel(x, y, base.lightened(v * 0.12) if v > 0.0 else base.darkened(-v * 0.18))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## (Untyped: the chip may be gone by then, the oldest freed or the world cleared.)
static func _settle_chip(chip: Variant) -> void:
	if is_instance_valid(chip):
		(chip as RigidBody3D).freeze = true


## Chips of what went: the biggest lumps, thrown out of the exit along the shot (some back out of
## the entry), lying about afterwards (the oldest go once there are too many).
func _throw_chips(direction: Vector3, seed: int) -> void:
	var t := voxel_damage_tuning()
	var host := get_parent().get_parent() if get_parent() and get_parent().get_parent() else get_parent()
	if host == null or not host.is_inside_tree():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var cell: float = voxels.cell_volume()
	var ai := axis_index()
	var density := 2300.0 if wood == &"stone" else 480.0
	for c: Vector4 in voxels.chunks():
		if c.w < t.chip_min_voxels:
			continue
		var side := pow(c.w * cell, 1.0 / 3.0)
		var dims := Vector3.ONE * side * 0.7
		if wood != &"stone":
			dims[ai] = side * 2.2  # splinters run along the grain
		dims = dims.clampf(0.004, 0.12)
		var chip := RigidBody3D.new()
		chip.name = "Chip"
		chip.add_to_group(&"wood_chips")
		chip.collision_layer = Layers.DEBRIS
		chip.collision_mask = Layers.DEBRIS_MASK
		chip.mass = maxf(dims.x * dims.y * dims.z * density, 0.002)
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = dims
		cs.shape = box
		chip.add_child(cs)
		var mi := MeshInstance3D.new()
		mi.mesh = MemberMesh.box(dims)
		mi.material_override = _fresh_material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		chip.add_child(mi)
		host.add_child(chip)
		chip.global_transform = Transform3D(global_basis, global_transform * Vector3(c.x, c.y, c.z))
		var back := rng.randf() < 0.25
		var speed := rng.randf_range(t.chip_speed.x, t.chip_speed.y)
		var scatter := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 1), rng.randf_range(-1, 1)) * 0.45
		chip.linear_velocity = ((-direction if back else direction) + scatter).normalized() * speed * (0.5 if back else 1.0)
		chip.angular_velocity = Vector3(rng.randf_range(-20, 20), rng.randf_range(-20, 20), rng.randf_range(-20, 20))
		chip.angular_damp = 1.5
		# Landed, it lies where it fell and costs the physics nothing.
		chip.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		chip.get_tree().create_timer(t.chip_settle, true, true).timeout.connect(_settle_chip.bind(chip))
		_chips.append(chip)
	_chips = _chips.filter(func(c: Variant) -> bool: return is_instance_valid(c))
	while _chips.size() > t.max_chips:
		var old: Variant = _chips.pop_front()
		if is_instance_valid(old):
			(old as Node).queue_free()
