class_name WoundSigns
extends Node
## What his wounds show on him and round him as time goes, read from his Physiology each tick (the
## gore lab, docs/briefs/gore-lab.md, part C): blood from burst eardrums, a nosebleed after a blow,
## blood at the mouth from the lungs or the gut (running when he's down), spitting blood and teeth
## with a broken jaw, a chest wound that sucks and bubbles as he breathes, blood from a scalp wound
## running into his eye, a drip trail behind a man who's bleeding, bloody hands (from his wound, his
## pool, anyone's wet blood, a bleeding man he's dragging) and their prints where they touch, and
## smears where he's dragged or slides. HumanBody owns one and steps it.

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
## A hand still on the spot of its last print doesn't print it again (a crawl leaves a trail of
## them, not a carpet).
const PRINT_SPACING := 0.12
## What a print leaves on the floor (ml: a thin film over a palm, so a mop or a rag takes it up).
const PRINT_ML := 0.3
## A hand on fresh blood takes some up, whoever's it is: this much blood under the palm (ml) loads
## it with every print, less with fewer; under PICK_MIN it's only a drop and it prints, not loads.
## Only wet blood comes off (Blood.wetness), and the blood on the hand dries the same way.
const HAND_FULL_ML := 3.0
const PICK_REACH := 0.05  ## m round the palm
const PICK_MIN := 0.3
## Only a hand this near the floor (above his lowest foot) looks for blood on it: standing, his
## hands are nowhere near it (and the rays aren't paid for every man in town).
const PICK_LOW := 0.25
## A hand this near a bleeding hole (his own, or the man he's dragging) is bloody from it; on a
## soaked patch of clothes, by how much it holds (ml) against HAND_FULL_ML.
const ON_WOUND := 0.08
const WOUND_BLEED := 0.2  ## ml/s: less and it's too little to wet a hand
## The blood on his hand, drawn on his skin: as full as the prints left, down to RESIDUE (a hand
## that's printed itself out is still stained).
const HAND_STAIN_SIZE := Vector3(0.12, 0.1, 0.16)
const HAND_STAIN_AT := 0.06  ## m from the wrist toward the fingers
const RESIDUE := 0.35
## Smears: a bleeding man drawn over a floor leaves a swipe, one band along the way he went, about
## as wide as what touched, streaked along its length, heaviest where he lay and feathering out at
## the end as the blood on him runs out (Bevel & Gardner, *Bloodstain Pattern Analysis*, ch. 9;
## James, Kish & Sutton 2005, "swipes"). Laid in pieces, each from where the last one ended (the
## band's texture tiles along its length: tools/textures/smear_band.py).
const SMEAR_SPEED := 0.3  ## m/s along the surface
const SMEAR_SLIDE := 0.6  ## at least this share of the part's speed along the surface (not landing on it)
const SMEAR_EVERY := 0.25  ## a piece at least this long (m)
const SMEAR_BREAK := 0.8  ## a jump further than this between looks (lifted, thrown) starts a new swipe
const SMEAR_STILL := 1.0  ## s not sliding and the swipe has ended
const SMEAR_WIDTH := 1.25  ## of the touching part's width (his back lies flatter and wider than its capsule)
const SMEAR_LOAD_MAX := 30.0  ## ml his clothes hold where they touch
const SMEAR_SOAK := 0.15  ## of the pool he lies in that soaks into them
const SMEAR_FULL := 6.0  ## ml on him that draws a full-strength smear
const SMEAR_FAINT := 0.7  ## the faintest a piece is drawn (thinning shows as a narrower band, not a see-through one)
const SMEAR_EMPTY := 0.8  ## less than this and it has run out
const SMEAR_BANDS := 3  ## the band's variants (smear_band0-2.png), the same where they join
const SMEAR_REACH := 1.5  ## m: what's on him goes onto the floor over about this far (an e-fold)

var _drip_ml := 0.0
## Its own dice, seeded by the man's (his `_rng` decides how he falls; the drips and spits come
## every few ticks and would move that on by however much he bled).
var _rng := RandomNumberGenerator.new()
var _drip_gap := 0.0
var _ears_done := {}
var _eyes_done := {}
var _scalp_done := {}
var _nose_marked := false
var _mouth_marked := false
var _mouth_in := 2.0
var _spit_in := 4.0
var _teeth_out := false
var _bloody := {}  ## "r"/"l" -> prints left in that hand (a fraction for the last, faint one)
var _bloody_age := {}  ## "r"/"l" -> game hours since that hand was last wetted
var _print_gap := {}
var _print_last := {}  ## "r"/"l" -> where that hand's last print is
var _hand_stain := {}  ## "r"/"l" -> the Decal of blood on that hand
var _smear_last := Vector3.INF  ## where the swipe's last piece ended (INF: no swipe)
var _smear_normal := Vector3.UP
var _smear_load := 0.0  ## ml of his blood on what touches
var _smear_tail: Decal  ## the swipe's last piece (drawn as its end when it stops)
var _smear_pieces := 0
var _smear_still := 0.0
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
		# Spread by his seed, not his instance id: ids count every object made before him, so any
		# change that makes a few more (more-cores step 2's finger bones) moved his drips' ticks.
		_ticks = posmod(hash(["signs", body.rng_seed]), EVERY)
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
	_onto_dragger()
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
		_mouth_in = _rng.randf_range(2.0, 4.0)
		var head := body.parts[&"head"] as Node3D
		var side := head.global_basis.x * (0.03 if _rng.randf() < 0.5 else -0.03)
		Blood.throw(world, _head_point(MOUTH) + side, Vector3(0, -0.2, 0) + side * 4.0, 0.15, body._own_rids())
	if p.jaw_broken and not body.limp and p.is_conscious():
		_spit_in -= dt
		if _spit_in <= 0.0:
			_spit_in = _rng.randf_range(5.0, 12.0)
			var head := body.parts[&"head"] as Node3D
			var fwd := -head.global_basis.z
			Blood.burst(world, _head_point(MOUTH), fwd + Vector3.DOWN * 0.3, 8, 1.4)
			Blood.throw(world, _head_point(MOUTH), fwd * 1.4 + Vector3.DOWN * 0.5, 0.3, body._own_rids())
			if not _teeth_out:
				_teeth_out = true
				for i in _rng.randi_range(1, 2):
					_tooth(world, _head_point(MOUTH), fwd * 1.6 + Vector3(_rng.randf_range(-0.3, 0.3), 0.4, 0))


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
	if body.limp or body.prone:
		return  # down, it pools under him (HumanBody._update_pool)
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
	var v := body.velocity_now() * 0.6 + Vector3(_rng.randf_range(-0.05, 0.05), -0.2, _rng.randf_range(-0.05, 0.05))
	Blood.throw(world, from + Vector3.DOWN * 0.03, v, ml, body._own_rids())


## A hand that's held a bleeding wound or tended one, or been pressed into wet blood (his pool, a
## splat or a smear, another man's), or that has hold of a bleeding man, is bloody; where it comes
## near something solid it leaves a print, fainter each time, and the blood shows on it.
func _hands(p: Physiology, world: Node3D, dt: float) -> void:
	var g: Dictionary = body._grab
	var holding := "" if g.is_empty() else String(g.side)
	if holding != "" and float(g.get("w", 0.0)) > 0.8 and body._wound_bleed(g.wound) > WOUND_BLEED:
		wet_hand(holding, PRINTS_PER_HAND)
	# Tending himself (OutlawBrain._tend): pressing it, packing it, both hands in it.
	if body.pose == &"tend" and p.total_bleed_rate() > WOUND_BLEED:
		wet_hand("r", PRINTS_PER_HAND)
		wet_hand("l", PRINTS_PER_HAND)
	var hours := dt / p.tuning.game_hour_seconds
	var floor_y := _lowest_foot()
	for side: String in ["r", "l"]:
		if _bloody.has(side):
			_bloody_age[side] = float(_bloody_age.get(side, 0.0)) + hours
		_print_gap[side] = float(_print_gap.get(side, 0.0)) - dt
		if _hand_gone(side):
			continue
		if holding == side and float(g.get("w", 0.0)) > 0.3:
			_show_hand(side)
			continue  # on the wound, not on the wall
		var at := body.drawn_hand(side)
		wet_hand(side, blood_on_me(at))
		var low := at.y - floor_y < PICK_LOW
		if float(_bloody.get(side, 0.0)) <= 0.25 and not low:
			_show_hand(side)
			continue  # nothing to print, nothing to pick up
		var hit := _touching(world, at, PRINT_REACH)
		if not hit.is_empty():
			var wet := Blood.wet_near(hit.position, PICK_REACH) if low else 0.0
			if wet >= PICK_MIN:
				# In it: it takes up, it doesn't print.
				wet_hand(side, PRINTS_PER_HAND * clampf(wet / HAND_FULL_ML, 0.0, 1.0))
			else:
				_print(world, side, hit)
		_show_hand(side)


## Wets a hand ("r"/"l") with blood worth this many prints, if that's more than it has on it
## still wet (a hand fresh from a wound isn't made fainter by a drop it touches).
func wet_hand(side: String, prints: float) -> void:
	if prints < 0.5:
		return
	var now := float(_bloody.get(side, 0.0)) * Blood.wetness(float(_bloody_age.get(side, 0.0)))
	if prints <= now:
		return
	_bloody[side] = minf(prints, PRINTS_PER_HAND)
	_bloody_age[side] = 0.0


## How bloody a hand at `at` (world) gets off him, in prints: on a bleeding hole, full; on the
## soaked patch round a wound, full while it's wet (a palm on soaked shirting takes up ~5 ml: the
## patch holds HumanBody.STAIN_FILM over its area).
func blood_on_me(at: Vector3) -> float:
	var best := 0.0
	for w: Dictionary in body.wounds:
		var part := body.parts.get(w.segment) as Node3D
		if part == null or w.kind == &"blast":
			continue
		if body._wound_bleed(w) > WOUND_BLEED:
			for hole: Variant in [w.entry, w.exit]:
				if hole != null and (part.global_transform * (hole as Vector3)).distance_to(at) < ON_WOUND:
					return PRINTS_PER_HAND
		var was: Variant = w.get("stain")
		if was == null or not is_instance_valid(was):
			continue
		var stain := was as Decal
		if stain.global_position.distance_to(at) < float(w.get("stain_size", 0.04)) * 0.5 + ON_WOUND * 0.5:
			best = maxf(best, PRINTS_PER_HAND * Blood.wetness(float(stain.get_meta(&"age_h", 0.0))))
	return best


## Being dragged, his blood comes off on the hands that have him by the collar.
func _onto_dragger() -> void:
	if body.dragged_by == null or not is_instance_valid(body.dragged_by):
		return
	var by := body.dragged_by as HumanBody
	if by == null:
		return
	for side: String in ["r", "l"]:
		by.signs_now().wet_hand(side, blood_on_me(by.drawn_hand(side)))


## A bloody hand's print where it touches (`hit`, a ray's): no closer than PRINT_GAP in time or
## PRINT_SPACING to its last, as strong as what's left on it and as wet as it still is.
func _print(world: Node3D, side: String, hit: Dictionary) -> void:
	var left := float(_bloody.get(side, 0.0))
	if left <= 0.25 or float(_print_gap[side]) > 0.0:
		return
	var wet := Blood.wetness(float(_bloody_age.get(side, 0.0)))
	if wet < Blood.WET_MIN:
		return  # dried on him: it doesn't come off
	var pos: Vector3 = hit.position
	var last: Variant = _print_last.get(side)
	if last != null and (last as Vector3).distance_to(pos) < PRINT_SPACING:
		return
	_print_gap[side] = PRINT_GAP
	_print_last[side] = pos
	_bloody[side] = maxf(left - 1.0, 0.0)
	var hand := body.parts[StringName("hand_" + side)] as Node3D
	var d := _mark(world, pos, hit.normal, "handprint", 0.17, hand.global_basis.y)
	var strength := clampf(minf(left, 1.0) * (left / PRINTS_PER_HAND + 0.2), 0.25, 1.0) * wet
	d.modulate.a = strength
	d.set_meta(&"ml", PRINT_ML * strength)
	d.set_meta(&"print", true)


func _hand_gone(side: String) -> bool:
	var sev := body.physiology.severed_segments
	for seg in [&"hand_", &"forearm_", &"upper_arm_"]:
		if sev.has(StringName(String(seg) + side)):
			return true
	return not body.parts.has(StringName("hand_" + side))


## The floor's height near him, near enough: his lowest foot (his pelvis's, without them).
func _lowest_foot() -> float:
	var y := INF
	for sid: StringName in [&"foot_r", &"foot_l"]:
		var foot := body.parts.get(sid) as Node3D
		if foot != null and not body.physiology.severed_segments.has(sid):
			y = minf(y, foot.global_position.y)
	if y == INF:
		y = (body.parts[&"pelvis"] as Node3D).global_position.y - 0.15
	return y


## The blood on a bloody hand, drawn on his skin (a decal on his body's layer, riding the hand's
## bone): as full as the prints left on it, down to RESIDUE, browning as it dries.
func _show_hand(side: String) -> void:
	var left := float(_bloody.get(side, 0.0))
	var d: Decal = _hand_stain.get(side)
	if d == null or not is_instance_valid(d):
		if left <= 0.0 or body.skeleton == null:
			return
		var bone := body.skeleton.find_bone("hand_" + side)
		if bone < 0:
			return
		var on := BoneAttachment3D.new()
		on.name = "BloodyHand_" + side
		on.bone_idx = bone
		body.skeleton.add_child(on)
		d = Decal.new()
		d.name = "HandBlood"
		d.texture_albedo = PixelArt.blood("stain1", 75, false, 32)
		d.cull_mask = Layers.VIS_BODY
		d.upper_fade = 0.0
		d.lower_fade = 0.0
		d.size = HAND_STAIN_SIZE
		# Its box across the hand (palm and back), the long side along it to the fingers.
		d.basis = Basis(Vector3.RIGHT, PI * 0.5)
		d.position = Vector3(0, HAND_STAIN_AT, 0)
		on.add_child(d)
		_hand_stain[side] = d
	var k := 1.0 - exp(-float(_bloody_age.get(side, 0.0)) / Blood.DRY_HOURS)
	var c := Color(lerpf(1.0, Blood.DRIED.r, k), lerpf(1.0, Blood.DRIED.g, k), lerpf(1.0, Blood.DRIED.b, k))
	c.a = lerpf(RESIDUE, 1.0, clampf(left / PRINTS_PER_HAND, 0.0, 1.0))
	d.modulate = c


## A bleeding man down and sliding (dragged, or slumping down a wall) smears his blood along it.
func _smears(world: Node3D, dt: float) -> void:
	var p := body.physiology
	_smear_load = minf(SMEAR_LOAD_MAX, _smear_load + p.total_bleed_rate() * dt)
	if not (body.limp or body.prone) or maxf(_smear_load, body._pool_ml * SMEAR_SOAK) < SMEAR_EMPTY:
		_end_smear()
		return
	var contact := _sliding_contact(world)
	if contact.is_empty():
		# Lying in his own blood, his clothes soak it up.
		_smear_load = clampf(body._pool_ml * SMEAR_SOAK, _smear_load, SMEAR_LOAD_MAX)
		_smear_still += dt
		if _smear_still > SMEAR_STILL:
			_end_smear()
		return
	_smear_still = 0.0
	var at: Vector3 = contact.at
	var n: Vector3 = contact.normal
	if _smear_last != Vector3.INF and (n.dot(_smear_normal) < 0.85 or at.distance_to(_smear_last) > SMEAR_BREAK):
		_end_smear()
	if _smear_last == Vector3.INF:
		_smear_last = at
		_smear_normal = n
		return
	var run := at - _smear_last
	run -= n * run.dot(n)
	var length := run.length()
	if length < SMEAR_EVERY:
		return
	if _smear_load < SMEAR_EMPTY:
		_end_smear()
		_smear_last = at
		return
	var strength := clampf(_smear_load / SMEAR_FULL, 0.3, 1.0)
	var width: float = contact.width * lerpf(0.7, 1.0, strength)
	var mid := _smear_last + run * 0.5
	var key := "smear_start" if _smear_pieces == 0 else "smear_band%d" % posmod(hash([body.rng_seed, _smear_pieces]), SMEAR_BANDS)
	var d := _mark(world, mid, n, key, width, run)
	# A hair longer than the run, so a bend leaves no gap between pieces.
	d.size = Vector3(width, 0.1, length + 0.01)
	d.modulate = Color(1, 1, 1, lerpf(SMEAR_FAINT, 1.0, strength))
	var ml := _smear_load * (1.0 - exp(-length / SMEAR_REACH))
	_smear_load -= ml
	d.set_meta(&"ml", ml)
	_smear_tail = d
	_smear_pieces += 1
	_smear_last = mid + run * 0.5
	_smear_normal = n


## Of his trunk, the part sliding along something solid (a bleeding one first): where it touches,
## the surface's normal and how wide a swipe it draws. Empty if none is.
func _sliding_contact(world: Node3D) -> Dictionary:
	var order: Array[StringName] = []
	for b: Dictionary in body.physiology.bleeds:
		var seg: StringName = b.segment
		if seg in [&"chest", &"abdomen", &"pelvis"] and not order.has(seg):
			order.append(seg)
	for seg: StringName in [&"abdomen", &"chest", &"pelvis"]:
		if not order.has(seg):
			order.append(seg)
	for sid in order:
		var rb := body.parts.get(sid) as RigidBody3D
		if rb == null:
			continue
		var v := rb.linear_velocity
		if v.length() < SMEAR_SPEED:
			continue
		var radius := float(body.anatomy.segments[sid].radius)
		var hit := _touching(world, rb.global_position, radius + 0.08)
		if hit.is_empty():
			continue
		var n: Vector3 = hit.normal
		var along := v - n * v.dot(n)
		if along.length() < SMEAR_SPEED or along.length() < v.length() * SMEAR_SLIDE:
			continue
		return {"at": hit.position, "normal": n, "width": radius * 2.0 * SMEAR_WIDTH}
	return {}


## The swipe stops: its last piece drawn as the feathered end.
func _end_smear() -> void:
	if is_instance_valid(_smear_tail) and _smear_tail.is_inside_tree():
		_smear_tail.texture_albedo = PixelArt.blood("smear_end", 73, false, 32)
	_smear_tail = null
	_smear_last = Vector3.INF
	_smear_pieces = 0
	_smear_still = 0.0


## The nearest solid thing within `reach` of a point, by a few rays (down first).
func _touching(world: Node3D, at: Vector3, reach: float) -> Dictionary:
	var space := World.space(world)
	for dir: Vector3 in [Vector3.DOWN, Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		var q := PhysicsRayQueryParameters3D.create(at, at + dir * reach, Layers.WORLD)
		q.exclude = body._own_rids()
		Prof.count(&"q_signs")
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
