class_name WoundSigns
extends Node
## What his wounds show on him and round him as time goes, read from his Physiology each tick (the
## gore lab, docs/briefs/gore-lab.md, part C): blood from burst eardrums, a nosebleed after a blow,
## blood at the mouth from the lungs or the gut (running when he's down), spitting blood and teeth
## with a broken jaw, a chest wound that sucks and bubbles as he breathes, blood from a scalp wound
## running into his eye, a drip trail behind a man who's bleeding, bloody handprints where his
## hands touch, and smears where he's dragged or slides. HumanBody owns one and steps it.

var body: HumanBody

## Where on the head (the anatomy's rest space).
const EAR := Vector3(0.085, 1.63, 0.0)  ## x mirrored for the left
const NOSE := Vector3(0.0, 1.62, -0.098)
const MOUTH := Vector3(0.0, 1.575, -0.092)
const EYE := Vector3(0.033, 1.66, -0.08)

## A drip trail: the share of what bleeds out of him that drips rather than soaking his clothes,
## and the most drops a second (Bevel & Gardner: a dripping wound leaves passive drops every few
## steps when walking).
const DRIP_SHARE := 0.25
const DRIP_ML := 0.06
const DRIP_MIN_GAP := 0.25
## Handprints: a bloody hand within this of something solid leaves one, no more than one each this
## many seconds a hand, fading over this many prints (the blood comes off on them).
const PRINT_REACH := 0.06
const PRINT_GAP := 0.6
const PRINTS_PER_HAND := 6
## Smears: a bleeding part sliding over something solid this fast leaves one every this far.
const SMEAR_SPEED := 0.3
const SMEAR_EVERY := 0.18

var _drip_ml := 0.0
var _drip_gap := 0.0
var _ears_done := {}
var _eyes_done := {}
var _scalp_done := {}
var _nose_marked := false
var _mouth_marked := false
var _mouth_in := 2.0
var _spit_in := 4.0
var _teeth_out := false
var _bloody := {}  ## "r"/"l" -> prints left in that hand
var _print_gap := {}
var _smear_from := {}  ## segment -> where the last smear was
var _bubble_in := 0.0
var _festered := {}
var _dead_for := 0.0
var _flies: GPUParticles3D

## Flies find the dead within a couple of hours in the heat (forensic entomology: blowflies
## arrive within minutes to hours).
const FLIES_AFTER_HOURS := 2.0


## They're only looks, so each man's are worked out every few ticks with the time between added
## up, the men spread over the ticks (ten wounded men's signs were 0.38 ms a tick, every tick).
const EVERY := 4
var _ticks := -1
var _dt_sum := 0.0


func step(dt: float) -> void:
	if body == null or not body.is_inside_tree():
		return
	if _ticks < 0:
		_ticks = body.get_instance_id() % EVERY
	_ticks += 1
	_dt_sum += dt
	if _ticks % EVERY != 0:
		return
	dt = _dt_sum
	_dt_sum = 0.0
	var p := body.physiology
	var world := body.get_parent() as Node3D
	if world == null:
		return
	_ears(p)
	_eyes(p)
	_festering(p)
	if not p.alive:
		_smears(world, dt)
		_dead_for += dt
		if _flies == null and _dead_for > FLIES_AFTER_HOURS * p.tuning.game_hour_seconds:
			_flies = _swarm(world)
		return
	_nose(p, world, dt)
	_mouth(p, world, dt)
	_sucking(p, world, dt)
	_drips(p, world, dt)
	_hands(p, world, dt)
	_smears(world, dt)


func _head_point(rest: Vector3) -> Vector3:
	var head := body.parts[&"head"] as Node3D
	return head.global_transform * (rest - body.anatomy.segment_center(&"head"))


## A mark on his head that runs down from `rest` (the anatomy's rest space): turned so its painted
## trickles go down him, and set below where it starts.
func _run_down(rest: Vector3, size: float, key: String) -> Decal:
	var local := rest - body.anatomy.segment_center(&"head")
	var d := body._decal(body.visuals[&"head"], &"head", local, size, PixelArt.blood(key, 71, false, 32))
	var n := d.basis.y.normalized()
	var head := body.parts[&"head"] as Node3D
	var down := head.global_basis.inverse() * Vector3.DOWN
	var z := down - n * down.dot(n)
	if z.length() > 0.2:
		z = z.normalized()
		d.basis = Basis(n.cross(z), n, z)
		d.position = local + z * size * 0.4
	# (Deep: the anatomy's points sit a few centimetres off a Studio man's own face.)
	d.size = Vector3(size * 0.8, 0.2, size)
	return d


## Burst eardrums (Physiology.blast_injury): blood run from that ear down his neck (DePalma 2005).
func _ears(p: Physiology) -> void:
	for side: StringName in p.eardrums_burst:
		if _ears_done.has(side):
			continue
		_ears_done[side] = true
		var at := EAR * Vector3(1.0 if side == &"r" else -1.0, 1.0, 1.0)
		_run_down(at, 0.24, "ear_run")


## A blind eye (the ball through it) and a scalp wound's blood in an eye: blood down his cheek.
func _eyes(p: Physiology) -> void:
	for eye: StringName in p.blind:
		if _eyes_done.has(eye):
			continue
		_eyes_done[eye] = true
		var at := EYE * Vector3(1.0 if String(eye).ends_with("_r") else -1.0, 1.0, 1.0)
		_run_down(at, 0.06, "ear_run")
	for side: StringName in p.blood_in_eye:
		if _scalp_done.has(side):
			continue
		_scalp_done[side] = true
		var at := EYE * Vector3(1.0 if side == &"r" else -1.0, 1.0, 1.0) + Vector3(0, 0.05, 0.02)
		_run_down(at, 0.09, "ear_run")


## A wound gone bad (Physiology.infection): red, swollen, pus round it.
func _festering(p: Physiology) -> void:
	for seg: StringName in p.infections:
		if p.severed_segments.has(seg):
			continue
		var level := p.infection(seg)
		var d: Decal = _festered.get(seg)
		if d != null and is_instance_valid(d):
			# Gone to gangrene: black and green, dead.
			if level >= 1.0 and p.gangrene_hours > 0.0 and d.name != "Gangrene":
				d.texture_albedo = PixelArt.blood("gangrene", 79, false, 32)
				d.name = "Gangrene"
				d.size = d.size * 1.4
			continue
		if level < 0.3:
			continue
		for w: Dictionary in body.wounds:
			if w.segment == seg and w.entry != null and not w.get("healed", false):
				d = body._decal(body.visuals[seg], seg, w.entry, 0.06, PixelArt.blood("infected", 77, false, 32))
				d.name = "Festering"
				_festered[seg] = d
				break


## A few flies over him: black specks wandering over the body.
func _swarm(world: Node3D) -> GPUParticles3D:
	var flies := GPUParticles3D.new()
	flies.name = "Flies"
	flies.amount = 10
	flies.lifetime = 3.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.3
	pm.gravity = Vector3.ZERO
	pm.direction = Vector3.UP
	pm.spread = 180.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.6
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 4.0
	pm.turbulence_noise_scale = 1.5
	flies.process_material = pm
	var speck := QuadMesh.new()
	speck.size = Vector2(0.008, 0.008)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.05, 0.05, 0.05)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	speck.material = m
	flies.draw_pass_1 = speck
	world.add_child(flies)
	flies.global_position = (body.parts[&"chest"] as Node3D).global_position + Vector3.UP * 0.25
	return flies


## A nosebleed after a blow to the face: drops from his nose, a run down his lip.
func _nose(p: Physiology, world: Node3D, dt: float) -> void:
	if p.nose_bleed <= 0.0:
		return
	if not _nose_marked:
		_nose_marked = true
		# (Long enough to come out under his moustache, over his lip.)
		_run_down(NOSE + Vector3(0, -0.015, 0), 0.13, "ear_run")
	_drip_gap -= dt
	if _drip_gap <= 0.0:
		_drip_gap = 0.9
		Blood.throw(world, _head_point(NOSE), Vector3(0, -0.3, 0), 0.08, body._own_rids())


## Blood at the mouth: from the lungs (coughed up, HumanBody._cough), the windpipe, the stomach
## and gut (it comes up), or a broken jaw. Down, it runs out of the side of his mouth; a broken
## jaw has him spit blood, and a tooth or two.
func _mouth(p: Physiology, world: Node3D, dt: float) -> void:
	var inside := p.airway_blood or not p.lung_damage.is_empty() or p.jaw_broken \
			or p.torn.has(&"stomach") or p.torn.has(&"small_intestine") or p.torn.has(&"large_intestine")
	if not inside:
		return
	if not _mouth_marked:
		_mouth_marked = true
		# A run of it from the corner of his mouth down his chin.
		_run_down(MOUTH + Vector3(0.022, -0.005, 0.005), 0.15, "ear_run")
		_run_down(MOUTH + Vector3(-0.012, -0.008, 0.004), 0.11, "ear_run")
	_mouth_in -= dt
	if (body.limp or body.prone) and _mouth_in <= 0.0:
		_mouth_in = randf_range(2.0, 4.0)
		var head := body.parts[&"head"] as Node3D
		var side := head.global_basis.x * (0.03 if randf() < 0.5 else -0.03)
		Blood.throw(world, _head_point(MOUTH) + side, Vector3(0, -0.2, 0) + side * 4.0, 0.15, body._own_rids())
	if p.jaw_broken and not body.limp and p.is_conscious():
		_spit_in -= dt
		if _spit_in <= 0.0:
			_spit_in = randf_range(5.0, 12.0)
			var head := body.parts[&"head"] as Node3D
			var fwd := -head.global_basis.z
			Blood.burst(world, _head_point(MOUTH), fwd + Vector3.DOWN * 0.3, 8, 1.4)
			Blood.throw(world, _head_point(MOUTH), fwd * 1.4 + Vector3.DOWN * 0.5, 0.3, body._own_rids())
			if not _teeth_out:
				_teeth_out = true
				for i in randi_range(1, 2):
					_tooth(world, _head_point(MOUTH), fwd * 1.6 + Vector3(randf_range(-0.3, 0.3), 0.4, 0))


func _tooth(world: Node3D, at: Vector3, v: Vector3) -> void:
	var rb := RigidBody3D.new()
	rb.name = "Tooth"
	rb.mass = 0.003
	rb.collision_layer = 0
	rb.collision_mask = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.007, 0.01, 0.007)
	shape.shape = box
	rb.add_child(shape)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.92, 0.88, 0.78)
	mi.material_override = m
	rb.add_child(mi)
	rb.add_to_group(&"severed_parts")
	world.add_child(rb)
	rb.global_position = at
	rb.linear_velocity = v


## A hole through the chest wall into a lung (an open pneumothorax, ATLS's "sucking chest wound"):
## each breath draws air in through it and blows froth out, pink and bubbled.
func _sucking(p: Physiology, world: Node3D, dt: float) -> void:
	if p.lung_damage.is_empty():
		return
	_bubble_in -= dt
	if _bubble_in > 0.0:
		return
	_bubble_in = body.breath_period()
	for w: Dictionary in body.wounds:
		if w.segment != &"chest" or not w.hits.any(func(h: Dictionary) -> bool: return String(h.id).begins_with("lung")):
			continue
		var part := body.parts[&"chest"] as Node3D
		for hole: Variant in [w.entry, w.exit]:
			if hole == null:
				continue
			var at: Vector3 = part.global_transform * (hole as Vector3)
			var out := (at - part.global_position).normalized()
			Blood.burst(world, at, out, 5, 0.5, FROTH)


const FROTH := Color(0.86, 0.36, 0.38)


## A man bleeding on his feet leaves drops behind him, a trail that can be followed.
func _drips(p: Physiology, world: Node3D, dt: float) -> void:
	if body.limp:
		return
	var rate := 0.0
	for b: Dictionary in p.bleeds:
		if b.kind != &"internal":
			rate += p.bleed_rate(b)
	_drip_ml += rate * dt * DRIP_SHARE
	_drip_gap -= dt
	if _drip_ml < DRIP_ML or _drip_gap > 0.0:
		return
	# From the lowest bleeding wound: it runs down him and drops off there.
	var from := Vector3.INF
	for w: Dictionary in body.wounds:
		var part := body.parts.get(w.segment) as Node3D
		if part == null or w.kind == &"blast":
			continue
		var at: Vector3 = part.global_transform * (w.entry as Vector3)
		if from == Vector3.INF or at.y < from.y:
			from = at
	if from == Vector3.INF:
		return
	var ml := minf(_drip_ml, 0.4)
	_drip_ml -= ml
	_drip_gap = DRIP_MIN_GAP
	var v := body.velocity_now() * 0.6 + Vector3(randf_range(-0.05, 0.05), -0.2, randf_range(-0.05, 0.05))
	Blood.throw(world, from + Vector3.DOWN * 0.03, v, ml, body._own_rids())


## A hand that's held a bleeding wound, or pressed into the blood under him, is bloody; where it
## comes near something solid it leaves a print, fainter each time.
func _hands(_p: Physiology, world: Node3D, dt: float) -> void:
	var g: Dictionary = body._grab
	if not g.is_empty() and float(g.get("w", 0.0)) > 0.8 and body._wound_bleed(g.wound) > 0.2:
		_bloody[g.side] = PRINTS_PER_HAND
	for side: String in _bloody.keys():
		if int(_bloody[side]) <= 0:
			continue
		_print_gap[side] = float(_print_gap.get(side, 0.0)) - dt
		if float(_print_gap[side]) > 0.0:
			continue
		var hand := body.parts.get(StringName("hand_" + side)) as Node3D
		if hand == null or (not g.is_empty() and g.side == side and float(g.get("w", 0.0)) > 0.3):
			continue  # on the wound, not on the wall
		var hit := _touching(world, body.drawn_hand(side), PRINT_REACH)
		if hit.is_empty():
			continue
		_print_gap[side] = PRINT_GAP
		var left: int = int(_bloody[side])
		_bloody[side] = left - 1
		var d := _mark(world, hit.position, hit.normal, "handprint", 0.17, hand.global_basis.y)
		d.modulate.a = clampf(float(left) / PRINTS_PER_HAND + 0.2, 0.25, 1.0)


## A bleeding man down and sliding (dragged, or slumping down a wall) smears his blood along it.
func _smears(world: Node3D, _dt: float) -> void:
	if not (body.limp or body.prone):
		return
	var bleeding := body.physiology.total_bleed_rate() > 0.3 or not body.physiology.alive and body.physiology.blood_loss() > 0.2
	if not bleeding:
		return
	for sid: StringName in [&"chest", &"abdomen", &"pelvis"]:
		var rb := body.parts.get(sid) as RigidBody3D
		if rb == null:
			continue
		var v := rb.linear_velocity
		if v.length() < SMEAR_SPEED:
			continue
		var at := rb.global_position
		var last: Vector3 = _smear_from.get(sid, Vector3.INF)
		if last != Vector3.INF and last.distance_to(at) < SMEAR_EVERY:
			continue
		var hit := _touching(world, at, float(body.anatomy.segments[sid].radius) + 0.08)
		if hit.is_empty():
			continue
		_smear_from[sid] = at
		var n: Vector3 = hit.normal
		var along := v - n * v.dot(n)
		if along.length() < 0.05:
			continue
		var d := _mark(world, hit.position, n, "smear", 0.35, along)
		d.size = Vector3(0.16, 0.1, 0.4)


## The nearest solid thing within `reach` of a point, by a few rays (down first).
func _touching(world: Node3D, at: Vector3, reach: float) -> Dictionary:
	var space := World.space(world)
	for dir: Vector3 in [Vector3.DOWN, Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		var q := PhysicsRayQueryParameters3D.create(at, at + dir * reach, Layers.WORLD)
		q.exclude = body._own_rids()
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			return hit
	return {}


## A painted blood mark on the world, its long side along `along`.
func _mark(world: Node3D, at: Vector3, normal: Vector3, key: String, size: float, along: Vector3) -> Decal:
	var d := Decal.new()
	d.name = "BloodMark"
	d.texture_albedo = PixelArt.blood(key, 73, false, 32)
	d.cull_mask = Layers.WORLD
	d.upper_fade = 0.0
	d.lower_fade = 0.0
	d.size = Vector3(size, 0.1, size)
	d.add_to_group(&"blood_marks")
	d.add_to_group(&"blood_drying")
	world.add_child(d)
	d.global_position = at
	var n := normal.normalized()
	var z := along - n * along.dot(n)
	if z.length() < 0.01:
		z = HumanBody._along(n).z
	z = z.normalized()
	d.global_basis = Basis(n.cross(z), n, z)
	return d
