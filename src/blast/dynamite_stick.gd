class_name DynamiteStick
extends RigidBody3D
## A stick of dynamite loose in the world: thrown, dropped or set against a wall. Lit, its fuse
## burns down (you can see it shorten, spitting sparks) and then it goes off (Blast.detonate).
## A bundle (#647) is one of these with `sticks` tied together: their kg, one fuse, drawn as the
## sticks tied with two wraps of cord; planted, it waits unlit to be lit (DynamiteViewmodel).
## A bullet through it may set it off; a blast close by will; so will a fire it's lying in (the
## fuse catches). Small loose thing: on the debris layer.

const LENGTH := 0.2
const RADIUS := 0.0145
const FUSE_LENGTH := 0.07

signal went_off

var lit := false
var fuse_left := 5.0
## Kilograms of TNT it's worth (one stick; a bundle is more: `sticks` x tnt_per_stick).
var kg := 0.15
## Sticks tied together in it (1: a lone stick).
var sticks := 1
## Who threw or dropped it (for the record).
var owner_node: Node
## Set at a wall's foot by hand (DynamiteViewmodel.plant, #506), not thrown or dropped. Lit, its
## fuse's hiss is a noise men near enough hear (Events.noise `fuse`); a thrown one's isn't (as before).
## Fixed where it was set (`stick_to`: tied or wedged on, frozen) until the piece it's on breaks,
## is cut or goes, or a ball hits it; then it falls as any loose stick.
var planted := false
var stuck_to: Node

var _fuse: Node3D
var _sparks: GPUParticles3D
var _hiss: AudioStreamPlayer3D
var _done := false
var _fire_check := 0.0
var _hiss_heard := 0.0
var _rng := RandomNumberGenerator.new()


static func make(parent: Node, at: Vector3, velocity := Vector3.ZERO, fuse := -1.0, n := 1) -> DynamiteStick:
	var s := DynamiteStick.new()
	var bt := Blast.t()
	s.sticks = maxi(1, n)
	s.kg = bt.tnt_per_stick * s.sticks
	s.fuse_left = bt.fuse_seconds if fuse < 0.0 else fuse
	parent.add_child(s)
	s.global_position = at
	s.linear_velocity = velocity
	return s


func _ready() -> void:
	name = "Dynamite"
	add_to_group(&"dynamite")
	mass = 0.23 * sticks
	collision_layer = Layers.DEBRIS
	collision_mask = Layers.DEBRIS_MASK
	continuous_cd = true
	# Paper on dirt: it skids and rolls a little, then stops (a round stick would roll on for
	# ever otherwise).
	var pm := PhysicsMaterial.new()
	pm.friction = 1.0
	pm.rough = true
	pm.bounce = 0.1
	physics_material_override = pm
	linear_damp = 0.4
	angular_damp = 4.0
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius_of(sticks)
	cyl.height = LENGTH
	shape.shape = cyl
	shape.rotation_degrees.x = 90.0
	add_child(shape)
	var parts := build_model(self, 1.0, sticks)
	_fuse = parts.fuse
	_sparks = parts.sparks
	_hiss = AudioStreamPlayer3D.new()
	_hiss.stream = SynthSounds.get_sound(&"fuse")
	_hiss.unit_size = 3.0
	_hiss.volume_db = -8.0
	add_child(_hiss)
	_rng.seed = hash(get_path())
	if lit:
		light()


## Where each of `n` sticks lies across a bundle (x, y off its axis): one alone in the middle; up to
## six in a ring touching; seven or eight round one in the middle.
static func layout(n: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if n <= 1:
		out.append(Vector2.ZERO)
		return out
	var ring := n if n <= 6 else n - 1
	if n > 6:
		out.append(Vector2.ZERO)
	var r := RADIUS / sin(PI / ring) if ring > 2 else RADIUS
	if n > 6:
		r = maxf(r, RADIUS * 2.0)
	for i in ring:
		var a := TAU * float(i) / float(ring)
		out.append(Vector2(cos(a), sin(a)) * r)
	return out


## A bundle's radius across (m): round all its sticks.
static func radius_of(n: int) -> float:
	var r := 0.0
	for p in layout(n):
		r = maxf(r, p.length())
	return r + RADIUS


## The stick (red paper, lying along Z) with its fuse out of one end and the sparks at its tip; `n`
## sticks tied in a bundle (two wraps of cord), the fuse out of one stick's end (the middle one's
## when there's one in the middle).
static func build_model(parent: Node3D, spark_scale := 1.0, n := 1) -> Dictionary:
	var paper := GunParts.material("dynamite_paper", PixelArt.skin("dynamite_paper", Color(0.62, 0.12, 0.08), 131), 0.0, 0.8)
	var ends := GunParts.material("dynamite_ends", PixelArt.skin("dynamite_ends", Color(0.78, 0.68, 0.5), 133), 0.0, 0.9)
	var spots := layout(n)
	for i in spots.size():
		var o := Vector3(spots[i].x, spots[i].y, 0.0)
		var tag := "" if i == 0 else str(i)
		GunParts.tube(parent, "Paper" + tag, RADIUS, LENGTH - 0.01, o, paper, 10)
		GunParts.tube(parent, "EndA" + tag, RADIUS * 0.96, 0.005, o + Vector3(0, 0, LENGTH * 0.5 - 0.0025), ends, 10)
		GunParts.tube(parent, "EndB" + tag, RADIUS * 0.96, 0.005, o + Vector3(0, 0, -LENGTH * 0.5 + 0.0025), ends, 10)
	var cord := GunParts.material("fuse_cord", PixelArt.skin("fuse_cord", Color(0.2, 0.17, 0.12), 135), 0.0, 1.0)
	if n > 1:
		var wrap := radius_of(n) + 0.002
		for z in [-LENGTH * 0.25, LENGTH * 0.25]:
			GunParts.tube(parent, "Wrap%d" % int(signf(z)), wrap, 0.008, Vector3(0, 0, z), cord, 12)
	var mid := Vector3(spots[0].x, spots[0].y, 0.0) if n <= 6 else Vector3.ZERO
	var fuse := GunParts.pivot(parent, "Fuse", mid + Vector3(0, 0, -LENGTH * 0.5))
	GunParts.tube(fuse, "Cord", 0.0025, FUSE_LENGTH, Vector3(0, 0, -FUSE_LENGTH * 0.5), cord, 5)
	var sparks := GPUParticles3D.new()
	sparks.name = "Sparks"
	sparks.amount = 24
	sparks.lifetime = 0.35
	sparks.emitting = false
	sparks.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 70.0
	pm.initial_velocity_min = 0.6 * spark_scale
	pm.initial_velocity_max = 1.6 * spark_scale
	pm.gravity = Vector3(0, -3.0, 0) * spark_scale
	pm.color = Color(1.0, 0.75, 0.3)
	sparks.process_material = pm
	var dot := BoxMesh.new()
	dot.size = Vector3.ONE * 0.006 * maxf(spark_scale, 0.4)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1.0, 0.8, 0.35)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.6, 0.2)
	glow.emission_energy_multiplier = 3.0
	dot.material = glow
	sparks.draw_pass_1 = dot
	fuse.add_child(sparks)
	sparks.position = Vector3(0, 0, -FUSE_LENGTH)
	return {"fuse": fuse, "sparks": sparks}


## How much of the fuse is left to see (1 full .. 0 burnt to the paper), for a fuse of `full` s.
static func show_fuse(fuse: Node3D, sparks: GPUParticles3D, left: float, full: float, burning: bool) -> void:
	var k := clampf(left / maxf(full, 0.01), 0.02, 1.0)
	fuse.scale = Vector3(1.0, 1.0, k)
	sparks.emitting = burning
	# The sparks sit at the burning end (the fuse is scaled, so undo it for them).
	sparks.scale = Vector3(1.0, 1.0, 1.0 / k)


func light() -> void:
	lit = true
	if _sparks:
		_sparks.emitting = true
	if _hiss and not _hiss.playing and is_inside_tree():
		_hiss.play()


## Set by hand on `what` (a StructureMember, the ground, any static piece): held there.
func stick_to(what: Object) -> void:
	planted = true
	stuck_to = what as Node
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = true
	if not Events.member_broken.is_connected(_on_member_broken):
		Events.member_broken.connect(_on_member_broken)
		Events.member_cut.connect(_on_member_cut)


func _on_member_broken(_id: StringName) -> void:
	# (Ids repeat from building to building: ask the piece itself.)
	if is_instance_valid(stuck_to) and stuck_to is StructureMember and (stuck_to as StructureMember).broken:
		loosen()


func _on_member_cut(old: Node, _pieces: Array) -> void:
	if old == stuck_to:
		loosen()


## No longer held: it drops where it is.
func loosen() -> void:
	stuck_to = null
	freeze = false
	if Events.member_broken.is_connected(_on_member_broken):
		Events.member_broken.disconnect(_on_member_broken)
		Events.member_cut.disconnect(_on_member_cut)


## A bullet through it: usually it just tears the paper; sometimes it goes.
func shot(impulse_vec: Vector3) -> void:
	if freeze:
		loosen()
	apply_central_impulse(impulse_vec * 0.3)
	if _rng.randf() < Blast.t().bullet_detonation_chance:
		detonate.call_deferred()


func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"dynamite", t)


func _physics_step(delta: float) -> void:
	if _done:
		return
	if freeze and not is_instance_valid(stuck_to):
		loosen()  # what it was on is gone
	if lit:
		fuse_left -= delta
		show_fuse(_fuse, _sparks, fuse_left, Blast.t().fuse_seconds, true)
		if fuse_left <= 0.0:
			detonate()
			return
		if fuse_left <= delta:
			# Off on the next tick: the fire's load checks sit it out (FireSystem.sit_out).
			var fire := FireSystem.find(get_tree())
			if fire:
				fire.sit_out(Engine.get_physics_frames() + 1)
		if planted:
			_hiss_heard -= delta
			if _hiss_heard <= 0.0:
				_hiss_heard = 0.5
				# Made a hand off the face it's on (its basis.x as planted, DynamiteViewmodel.plant), so a
				# man the other side of the wall has the wall between him and it (Senses: none of a
				# fuse's hiss gets through), however thin the wall.
				var off := global_basis.x.normalized() * 0.3 if is_instance_valid(stuck_to) else Vector3.ZERO
				Events.noise.emit(global_position + off, Blast.t().fuse_heard, &"fuse", self)
	else:
		_fire_check -= delta
		if _fire_check <= 0.0:
			_fire_check = 0.5
			_catch_from_fire()


## Lying in a fire, the fuse catches.
func _catch_from_fire() -> void:
	var fire := FireSystem.find(get_tree())
	if fire == null:
		return
	for m in fire.burning_members():
		if is_instance_valid(m) and Blast._nearest_on(m, global_position).distance_to(global_position) < 0.3:
			light()
			return


func detonate() -> void:
	if _done or not is_inside_tree():
		return
	_done = true
	var world := get_parent() as Node3D
	var at := global_position
	went_off.emit()
	queue_free()
	Blast.detonate(world, at, kg, null)


## A bundle, not a lone stick.
func is_bundle() -> bool:
	return sticks > 1


## Planted bundles not yet gone off (lit or waiting): what `max_bundles` counts.
static func bundles_set(tree: SceneTree) -> Array[DynamiteStick]:
	var out: Array[DynamiteStick] = []
	for n in tree.get_nodes_in_group(&"dynamite"):
		var s := n as DynamiteStick
		if s and s.planted and s.is_bundle() and not s._done and not s.is_queued_for_deletion():
			out.append(s)
	return out


# --- Saving -------------------------------------------------------------------------------------------

## What a save keeps of it: where it lies, how many sticks, lit and how much fuse, and what it's
## planted on (by its node path; it's dropped loose if that's gone when it's loaded).
func to_dict() -> Dictionary:
	var b := global_basis
	var d := {"sticks": sticks, "at": [global_position.x, global_position.y, global_position.z],
		"basis": [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z],
		"lit": lit, "fuse_left": fuse_left, "planted": planted}
	if planted and is_instance_valid(stuck_to) and stuck_to.is_inside_tree():
		d["on"] = String(stuck_to.get_path())
	return d


## One back from `to_dict()` under `parent`.
static func from_dict(parent: Node, d: Dictionary) -> DynamiteStick:
	var a: Array = d.get("at", [0, 0, 0])
	var s := make(parent, Vector3(a[0], a[1], a[2]), Vector3.ZERO, float(d.get("fuse_left", Blast.t().fuse_seconds)), int(d.get("sticks", 1)))
	var m: Array = d.get("basis", [])
	if m.size() == 9:
		s.global_basis = Basis(Vector3(m[0], m[1], m[2]), Vector3(m[3], m[4], m[5]), Vector3(m[6], m[7], m[8]))
	if bool(d.get("planted", false)):
		var on: Node = parent.get_node_or_null(NodePath(str(d.get("on", "")))) if d.has("on") else null
		s.stick_to(on)
		if on == null:
			s.loosen()
	if bool(d.get("lit", false)):
		s.light()
	return s


## Every stick and bundle lying in the world (not gone off), for a save.
static func save_all(tree: SceneTree) -> Array:
	var out := []
	for n in tree.get_nodes_in_group(&"dynamite"):
		var s := n as DynamiteStick
		if s and not s._done and not s.is_queued_for_deletion() and s.is_inside_tree():
			out.append(s.to_dict())
	return out


## Them back, under `parent` (the world).
static func restore_all(parent: Node, list: Array) -> Array[DynamiteStick]:
	var out: Array[DynamiteStick] = []
	for d: Dictionary in list:
		out.append(from_dict(parent, d))
	return out
